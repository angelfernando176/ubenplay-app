"""Gestión de usuarios (estudiantes registrados desde la APK).

CRUD con búsqueda, orden, paginación, edición e inactivación.
El cambio de nivel de acceso (ascendente) genera un código de 6 dígitos.
"""
import random
import string

from flask import render_template, request, redirect, url_for, flash
from flask_login import login_required, current_user
from app import app
from database import db
from models import Usuario, RegistroUsuario
from email_service import enviar_correo_codigo, enviar_correo_autorizacion

import json
import urllib.request

SUPABASE_URL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
SUPABASE_KEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'

NIVELES = {1: 'Registrado', 2: 'Funcional', 3: 'Licenciamiento1', 4: 'Licenciamiento2'}
ESTADOS = {0: 'Inactivo', 1: 'Activo'}
LOPDP_ESTADOS = {0: 'No autorizado', 1: 'Autorizado'}
RANGO_EDAD = {1: 'Menor a 18', 2: '18 a 35', 3: '36 a 50', 4: 'Mayores de 50'}

_SEARCH_FIELDS = {'nombre': 'Nombre', 'apellido': 'Apellido', 'correo': 'Correo'}
_SORT_COLS = {
    'nombre': Usuario.nombre,
    'apellido': Usuario.apellido,
    'correo': Usuario.correo,
    'nivel_acceso': Usuario.nivel_acceso,
    'estado': Usuario.estado,
    'insistencias': Usuario.insistencias,
    'lopdp': Usuario.lopdp,
    'fecha_registro': Usuario.fecha_registro,
}


def _solo_root():
    if not current_user.is_root:
        flash('Solo el administrador root puede gestionar usuarios', 'error')
        return True
    return False


def _generar_codigo():
    """Código alfanumérico de 6 caracteres (sin 0/O ni 1/I para evitar confusión)."""
    alfabeto = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    return ''.join(random.choice(alfabeto) for _ in range(6))


def _sync_usuarios_supabase():
    """Sincroniza lopdp/estado/nivel_acceso desde Supabase (fuente de verdad) a SQLite.

    La Edge Function LOPDP escribe lopdp=1 solo en Supabase; este espejo mantiene
    el panel admin al día sin pasos manuales.
    """
    try:
        req = urllib.request.Request(
            f'{SUPABASE_URL}/rest/v1/usuarios?select=id_usuario,estado,lopdp,nivel_acceso',
            headers={'apikey': SUPABASE_KEY, 'Authorization': 'Bearer ' + SUPABASE_KEY})
        filas = json.loads(urllib.request.urlopen(req, timeout=15).read())
    except Exception:
        return  # Supabase caído → mantener SQLite tal cual
    for r in filas:
        u = Usuario.query.get(r.get('id_usuario'))
        if u is not None:
            u.lopdp = r.get('lopdp') or 0
            u.estado = r.get('estado') or 0
            u.nivel_acceso = r.get('nivel_acceso') or 1
    db.session.commit()


def _supabase_update_usuario(id_usuario, fields):
    """PATCH public.usuarios por id_usuario (espejo inverso: admin → Supabase)."""
    data = json.dumps(fields).encode()
    req = urllib.request.Request(
        f'{SUPABASE_URL}/rest/v1/usuarios?id_usuario=eq.{id_usuario}',
        data=data, method='PATCH',
        headers={'apikey': SUPABASE_KEY, 'Authorization': 'Bearer ' + SUPABASE_KEY,
                 'Content-Type': 'application/json'})
    urllib.request.urlopen(req, timeout=30)


def _registrar_cambio_nivel(usuario, nivel_anterior, nivel_nuevo, codigo):
    """Guarda el cambio de nivel en registro_usuarios con el código encriptado."""
    reg = RegistroUsuario(
        id_usuario=usuario.id_usuario,
        codigo_enviado=usuario.codigo_hash,  # hash (encriptado)
        tipo_cambio=f'{nivel_anterior}->{nivel_nuevo}',
    )
    db.session.add(reg)


@app.route('/usuarios')
@login_required
def usuarios_estudiantes_page():
    if _solo_root():
        return redirect(url_for('dashboard'))

    _sync_usuarios_supabase()

    campo = request.args.get('campo', 'nombre')
    q = request.args.get('q', '').strip()
    sort = request.args.get('sort', 'fecha_registro')
    order = request.args.get('order', 'desc')
    page = request.args.get('page', 1, type=int)

    query = Usuario.query
    if q:
        col = {'nombre': Usuario.nombre, 'apellido': Usuario.apellido,
               'correo': Usuario.correo}.get(campo, Usuario.nombre)
        query = query.filter(col.ilike(f'%{q}%'))

    col = _SORT_COLS.get(sort, Usuario.fecha_registro)
    query = query.order_by(col.asc() if order == 'asc' else col.desc())

    pag = query.paginate(page=page, per_page=15, error_out=False)

    return render_template(
        'usuarios_estudiantes.html',
        usuarios=pag.items,
        pag=pag,
        niveles=NIVELES, estados=ESTADOS, lopdp_estados=LOPDP_ESTADOS, rango_edad=RANGO_EDAD,
        campo=campo, q=q, sort=sort, order=order,
        search_fields=_SEARCH_FIELDS,
    )


@app.route('/usuarios/<int:uid>/editar', methods=['GET', 'POST'])
@login_required
def usuario_editar(uid):
    if _solo_root():
        return redirect(url_for('dashboard'))

    _sync_usuarios_supabase()

    u = Usuario.query.get_or_404(uid)

    if request.method == 'POST':
        nivel_nuevo = int(request.form.get('nivel_acceso', u.nivel_acceso))
        nivel_anterior = u.nivel_acceso

        if nivel_nuevo > nivel_anterior and nivel_nuevo <= 4:
            # Cambio ascendente → generar código de 6 dígitos y enviar por correo
            codigo = _generar_codigo()
            u.set_codigo(codigo)
            u.nivel_acceso = nivel_nuevo
            _registrar_cambio_nivel(u, nivel_anterior, nivel_nuevo, codigo)
            try:
                enviar_correo_codigo(u, codigo)
                flash(f'Usuario actualizado. Código enviado a {u.correo}.', 'success')
            except Exception as e:
                flash(f'Usuario actualizado pero falló el envío del correo: {e}', 'warning')
        elif nivel_nuevo != nivel_anterior:
            # Descenso o fuera de rango: no genera código
            u.nivel_acceso = max(1, min(4, nivel_nuevo))
            flash('Nivel actualizado (sin código, cambio no ascendente)', 'success')
        else:
            flash('Usuario actualizado', 'success')

        u.estado = int(request.form.get('estado', u.estado))
        u.lopdp = int(request.form.get('lopdp', u.lopdp))
        db.session.commit()
        try:
            _supabase_update_usuario(u.id_usuario, {
                'estado': u.estado, 'lopdp': u.lopdp, 'nivel_acceso': u.nivel_acceso,
                'codigo_hash': u.codigo_hash, 'token_autorizacion': u.token_autorizacion,
            })
        except Exception:
            pass  # SQLite ya quedó actualizado; Supabase se sincroniza en el próximo pull
        return redirect(url_for('usuarios_estudiantes_page'))

    return render_template('usuario_editar.html', u=u, niveles=NIVELES, estados=ESTADOS,
                           lopdp_estados=LOPDP_ESTADOS, rango_edad=RANGO_EDAD)


@app.route('/usuarios/<int:uid>/inactivar', methods=['POST'])
@login_required
def usuario_inactivar(uid):
    if _solo_root():
        return redirect(url_for('dashboard'))
    u = Usuario.query.get_or_404(uid)
    u.estado = 0
    db.session.commit()
    flash(f'Usuario {u.nombre} {u.apellido} inactivado', 'success')
    return redirect(url_for('usuarios_estudiantes_page'))


@app.route('/usuarios/<int:uid>/insistir', methods=['POST'])
@login_required
def usuario_insistir(uid):
    if _solo_root():
        return redirect(url_for('dashboard'))
    u = Usuario.query.get_or_404(uid)
    u.insistencias = (u.insistencias or 0) + 1
    db.session.commit()
    try:
        enviar_correo_autorizacion(u)
        flash(f'Correo de autorización LOPDP reenviado a {u.correo}.', 'success')
    except Exception as e:
        flash(f'Insistencia registrada pero falló el envío: {e}', 'warning')
    return redirect(url_for('usuarios_estudiantes_page'))
