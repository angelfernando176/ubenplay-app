"""API pública para la APK: registro, verificación de código y estado.

Estos endpoints NO requieren login (los consume la app móvil sin sesión).
El registro crea el usuario en Supabase (id canónico) y en SQLite (espejo para
el admin) con el MISMO id_usuario, para que el link LOPDP (Edge Function) valide.
"""
import json
import random
import string
import urllib.request
from datetime import datetime
from urllib.parse import quote

from flask import request
from werkzeug.security import generate_password_hash

from app import app
from database import db
from models import Usuario, RegistroUsuario, EventoUsuario
from email_service import enviar_correo_codigo, generar_token

SUPABASE_URL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
SUPABASE_KEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'

_ALFABETO = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'


def _generar_codigo():
    """Código alfanumérico de 6 caracteres (sin 0/O ni 1/I)."""
    return ''.join(random.choice(_ALFABETO) for _ in range(6))


def _normalizar_correo(v):
    return (v or '').strip().lower()


# ── Supabase (REST) ────────────────────────────────────────────

def _supabase_insert_usuario(payload):
    """POST a public.usuarios y devuelve el id_usuario generado por Supabase."""
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        f'{SUPABASE_URL}/rest/v1/usuarios',
        data=data, method='POST',
        headers={'apikey': SUPABASE_KEY, 'Authorization': 'Bearer ' + SUPABASE_KEY,
                 'Content-Type': 'application/json', 'Prefer': 'return=representation'})
    r = urllib.request.urlopen(req, timeout=30)
    return json.loads(r.read().decode())[0]['id_usuario']


def _supabase_update_usuario(id_usuario, fields):
    """PATCH public.usuarios por id_usuario."""
    data = json.dumps(fields).encode()
    req = urllib.request.Request(
        f'{SUPABASE_URL}/rest/v1/usuarios?id_usuario=eq.{id_usuario}',
        data=data, method='PATCH',
        headers={'apikey': SUPABASE_KEY, 'Authorization': 'Bearer ' + SUPABASE_KEY,
                 'Content-Type': 'application/json'})
    urllib.request.urlopen(req, timeout=30)


def _supabase_get_usuario(correo):
    """Devuelve el dict del usuario desde Supabase, o None si no existe."""
    req = urllib.request.Request(
        f'{SUPABASE_URL}/rest/v1/usuarios?select=*&correo=eq.{quote(correo)}',
        headers={'apikey': SUPABASE_KEY, 'Authorization': 'Bearer ' + SUPABASE_KEY})
    rows = json.loads(urllib.request.urlopen(req, timeout=15).read())
    return rows[0] if rows else None


def _payload_usuario(u):
    """Dict con el estado completo de un Usuario para Supabase."""
    return {
        'nombre': u.nombre, 'apellido': u.apellido, 'correo': u.correo,
        'rango_edad': u.rango_edad or 2, 'pais': u.pais,
        'correo_representante': u.correo_representante,
        'nivel_acceso': u.nivel_acceso or 1, 'estado': u.estado or 0,
        'lopdp': u.lopdp or 0, 'insistencias': u.insistencias or 0,
        'codigo_hash': u.codigo_hash, 'token_autorizacion': u.token_autorizacion,
    }


# ── Endpoints ─────────────────────────────────────────────────

@app.route('/api/usuarios/registro', methods=['POST'])
def api_usuarios_registro():
    data = request.get_json(force=True, silent=True) or {}
    nombre = (data.get('nombre') or '').strip()
    apellido = (data.get('apellido') or '').strip()
    correo = _normalizar_correo(data.get('correo'))
    rango_edad = int(data.get('rango_edad') or 2)
    pais = (data.get('pais') or '').strip()
    correo_rep = (data.get('correo_representante') or '').strip() or None

    if not nombre or not apellido or not correo:
        return {'success': False, 'error': 'Nombre, apellido y correo son obligatorios.'}, 400
    if '@' not in correo or '.' not in correo:
        return {'success': False, 'error': 'Correo electrónico no válido.'}, 400
    if rango_edad not in (1, 2, 3, 4):
        rango_edad = 2
    if rango_edad == 1 and not correo_rep:
        return {'success': False, 'error': 'Para menores de 18, el correo del representante es obligatorio.'}, 400

    # Evitar duplicados (correo único)
    if Usuario.query.filter_by(correo=correo).first():
        return {'success': False, 'error': 'Ya existe un usuario con ese correo.'}, 409

    codigo = _generar_codigo()
    token = generar_token()

    # 1) Supabase (fuente de verdad) → id canónico
    supa_payload = {
        'nombre': nombre, 'apellido': apellido, 'correo': correo,
        'rango_edad': rango_edad, 'pais': pais,
        'correo_representante': correo_rep,
        'nivel_acceso': 1, 'estado': 0, 'lopdp': 0, 'insistencias': 0,
        'codigo_hash': generate_password_hash(codigo),
        'token_autorizacion': token,
    }
    try:
        supa_id = _supabase_insert_usuario(supa_payload)
    except Exception as e:
        return {'success': False, 'error': f'No se pudo registrar en Supabase: {e}'}, 500

    # 2) SQLite (espejo) con el MISMO id_usuario
    u = Usuario(
        id_usuario=supa_id,
        nombre=nombre, apellido=apellido, correo=correo,
        rango_edad=rango_edad, pais=pais, correo_representante=correo_rep,
        nivel_acceso=1, estado=0, lopdp=0, insistencias=0,
        token_autorizacion=token,
    )
    u.codigo_hash = generate_password_hash(codigo)
    db.session.add(u)
    db.session.commit()

    # 3) Enviar correo con el código (mismo token → link válido)
    error_correo = None
    try:
        enviar_correo_codigo(u, codigo, token=token)
        db.session.commit()
    except Exception as e:
        error_correo = str(e)

    return {
        'success': True,
        'id_usuario': supa_id,
        'mensaje': 'Pronto recibirás un correo con un código de 6 dígitos.',
        'correo_enviado': error_correo is None,
        'aviso_correo': error_correo,
    }


@app.route('/api/usuarios/verificar', methods=['POST'])
def api_usuarios_verificar():
    data = request.get_json(force=True, silent=True) or {}
    correo = _normalizar_correo(data.get('correo'))
    codigo = (data.get('codigo') or '').strip().upper()

    u = Usuario.query.filter_by(correo=correo).first()
    if not u:
        return {'success': False, 'error': 'Usuario no encontrado.'}, 404
    if u.estado == 1:
        return {'success': True, 'ya_activo': True, 'nombre': u.nombre,
                'nivel_acceso': u.nivel_acceso, 'lopdp': u.lopdp or 0}
    if not codigo or not u.check_codigo(codigo):
        return {'success': False, 'error': 'Código incorrecto.'}, 400

    u.estado = 1
    u.nivel_acceso = max(u.nivel_acceso or 1, 2)  # mínimo "Funcional" al activar
    db.session.commit()
    try:
        _supabase_update_usuario(u.id_usuario, {'estado': 1, 'nivel_acceso': u.nivel_acceso})
    except Exception:
        pass  # SQLite ya está activo; Supabase se sincroniza en el próximo pull

    return {'success': True, 'nombre': u.nombre, 'apellido': u.apellido,
            'nivel_acceso': u.nivel_acceso, 'lopdp': u.lopdp or 0}


@app.route('/api/usuarios/reenviar-codigo', methods=['POST'])
def api_usuarios_reenviar_codigo():
    data = request.get_json(force=True, silent=True) or {}
    correo = _normalizar_correo(data.get('correo'))

    u = Usuario.query.filter_by(correo=correo).first()
    if not u:
        return {'success': False, 'error': 'Usuario no encontrado.'}, 404

    codigo = _generar_codigo()
    token = generar_token()
    u.codigo_hash = generate_password_hash(codigo)
    u.token_autorizacion = token
    u.insistencias = (u.insistencias or 0) + 1
    db.session.commit()

    try:
        _supabase_update_usuario(u.id_usuario, {
            'codigo_hash': u.codigo_hash,
            'token_autorizacion': token,
            'insistencias': u.insistencias,
        })
    except Exception:
        pass

    try:
        enviar_correo_codigo(u, codigo, token=token)
        db.session.commit()
    except Exception as e:
        return {'success': False, 'error': f'No se pudo reenviar el correo: {e}'}, 500

    return {'success': True, 'mensaje': 'Se reenvió el código a tu correo.'}


@app.route('/api/usuarios/estado', methods=['GET'])
def api_usuarios_estado():
    correo = _normalizar_correo(request.args.get('correo'))
    if not correo:
        return {'success': False, 'error': 'Falta el parámetro correo.'}, 400

    # Supabase es la fuente de verdad (lopdp lo escribe la Edge Function).
    try:
        supa = _supabase_get_usuario(correo)
    except Exception:
        supa = None
    if supa:
        return {
            'existe': True,
            'id_usuario': supa.get('id_usuario'),
            'nombre': supa.get('nombre'), 'apellido': supa.get('apellido'),
            'correo': supa.get('correo'),
            'estado': supa.get('estado') or 0, 'lopdp': supa.get('lopdp') or 0,
            'nivel_acceso': supa.get('nivel_acceso') or 1,
            'rango_edad': supa.get('rango_edad') or 2,
            'correo_representante': supa.get('correo_representante'),
        }

    # Fallback a SQLite si Supabase no responde
    u = Usuario.query.filter_by(correo=correo).first()
    if not u:
        return {'existe': False}
    return {
        'existe': True,
        'id_usuario': u.id_usuario,
        'nombre': u.nombre, 'apellido': u.apellido, 'correo': u.correo,
        'estado': u.estado or 0, 'lopdp': u.lopdp or 0,
        'nivel_acceso': u.nivel_acceso or 1, 'rango_edad': u.rango_edad or 2,
        'correo_representante': u.correo_representante,
    }


# ── Eventos de ingreso/salida (Fase 4) ─────────────────────────

_TIPOS_EVENTO = ('login', 'logout', 'apertura')


def _parse_fecha(s):
    """Parsea una fecha ISO 8601 (acepta sufijo Z). Devuelve datetime o None."""
    if not s:
        return None
    s = str(s).strip()
    if s.endswith('Z'):
        s = s[:-1] + '+00:00'
    try:
        return datetime.fromisoformat(s)
    except (ValueError, TypeError):
        return None


def _supabase_insert_evento(payload):
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        f'{SUPABASE_URL}/rest/v1/eventos_usuario',
        data=data, method='POST',
        headers={'apikey': SUPABASE_KEY, 'Authorization': 'Bearer ' + SUPABASE_KEY,
                 'Content-Type': 'application/json'})
    urllib.request.urlopen(req, timeout=30)


@app.route('/api/usuarios/eventos', methods=['POST'])
def api_usuarios_eventos():
    data = request.get_json(force=True, silent=True) or {}
    # Acepta {"eventos": [...]} o una lista directa o un evento único
    if isinstance(data, list):
        eventos = data
    elif isinstance(data.get('eventos'), list):
        eventos = data['eventos']
    elif data.get('tipo_evento'):
        eventos = [data]
    else:
        return {'success': False, 'error': 'No se recibieron eventos.'}, 400

    recibidos = 0
    errores = 0
    for ev in eventos[:200]:  # tope de seguridad
        try:
            id_usuario = int(ev.get('id_usuario') or 0)
            tipo = (ev.get('tipo_evento') or '').strip().lower()
            if id_usuario <= 0 or tipo not in _TIPOS_EVENTO:
                errores += 1
                continue
            fecha = _parse_fecha(ev.get('fecha_hora')) or datetime.utcnow()
            dispositivo = (ev.get('dispositivo') or '').strip()[:100]

            # SQLite (espejo local)
            db.session.add(EventoUsuario(
                id_usuario=id_usuario, tipo_evento=tipo,
                fecha_hora=fecha, dispositivo=dispositivo, sincronizado=1))
            # Supabase (fuente de verdad)
            try:
                _supabase_insert_evento({
                    'id_usuario': id_usuario, 'tipo_evento': tipo,
                    'fecha_hora': fecha.isoformat(), 'dispositivo': dispositivo,
                    'sincronizado': 0,
                })
            except Exception:
                pass  # SQLite ya guarda; Supabase se sincroniza después
            recibidos += 1
        except Exception:
            errores += 1
    db.session.commit()

    return {'success': True, 'recibidos': recibidos, 'errores': errores}



