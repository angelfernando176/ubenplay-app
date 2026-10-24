"""Lógica de activación/inactivación/borrado de cargas batch (Fase 3)."""
import json
import urllib.request
from database import db
from models import DatosBatch, Palabra, EncabezadoLeccion, LeccionDetalle, LeccionPalabra
from game_config import GAMES, juegos_aplicables

PALABRAS_POR_LECCION = 10
SUPABASE_URL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
SUPABASE_KEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'


def _post_supabase(table, rows):
    if not rows:
        return
    data = json.dumps(rows).encode()
    req = urllib.request.Request(
        f'{SUPABASE_URL}/rest/v1/{table}', data=data, method='POST',
        headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}',
                 'Content-Type': 'application/json', 'Prefer': 'resolution=merge-duplicates'})
    urllib.request.urlopen(req, timeout=20)


def _iso(dt):
    return dt.isoformat() if dt else None


def sync_datos_batch_to_supabase(batch_id):
    """Espeja una fila de datos_batch a Supabase."""
    batch = DatosBatch.query.get(batch_id)
    if not batch:
        return
    try:
        _post_supabase('datos_batch', [{
            'id_datos_batch': batch.id_datos_batch, 'fecha_carga': _iso(batch.fecha_carga),
            'numero_palabras': batch.numero_palabras, 'id_tematica': batch.id_tematica,
            'id_categoria': batch.id_categoria, 'id_usuario': batch.id_usuario,
            'observaciones': batch.observaciones, 'nombre_archivo': batch.nombre_archivo,
            'estado': batch.estado,
        }])
    except Exception as e:
        print(f'[activacion] Sync datos_batch falló: {e}')


def sync_usuario_to_supabase(id_usuario):
    """Espeja un registro de usuarios a Supabase (espejo del profesor)."""
    from models import Usuario
    u = Usuario.query.get(id_usuario)
    if not u:
        return
    try:
        _post_supabase('usuarios', [{
            'id_usuario': u.id_usuario, 'nombre': u.nombre or '', 'apellido': u.apellido or '',
            'correo': u.correo, 'rango_edad': u.rango_edad, 'pais': u.pais,
            'correo_representante': u.correo_representante, 'nivel_acceso': u.nivel_acceso,
            'estado': u.estado, 'lopdp': u.lopdp, 'id_suscripcion': u.id_suscripcion or '0',
            'tipo_usuario': u.tipo_usuario,
        }])
    except Exception as e:
        print(f'[activacion] Sync usuario falló: {e}')


def sync_activacion_to_supabase(batch_id):
    """Espeja datos_batch + encabezado_leccion + leccion_detalle + leccion_palabras a Supabase."""
    try:
        sync_datos_batch_to_supabase(batch_id)
        lecciones = EncabezadoLeccion.query.filter_by(id_datos_batch=batch_id).all()
        if not lecciones:
            return
        _post_supabase('encabezado_leccion', [{
            'id_leccion': l.id_leccion, 'id_usuario': l.id_usuario,
            'fecha_inicio': _iso(l.fecha_inicio), 'cantidad_palabras': l.cantidad_palabras,
            'porcentaje_aciertos': l.porcentaje_aciertos, 'estado': l.estado,
            'tipo_leccion': l.tipo_leccion, 'id_suscripcion': l.id_suscripcion or '0',
            'icono': l.icono, 'id_datos_batch': l.id_datos_batch,
        } for l in lecciones])

        ids = [l.id_leccion for l in lecciones]
        detalles = LeccionDetalle.query.filter(LeccionDetalle.id_leccion.in_(ids)).all()
        _post_supabase('leccion_detalle', [{
            'id_detalle': d.id_detalle, 'id_leccion': d.id_leccion, 'id_palabra': d.id_palabra,
            'id_juego': d.id_juego, 'estado': d.estado,
            'fecha_registro': _iso(d.fecha_registro), 'id_datos_batch': d.id_datos_batch,
        } for d in detalles])

        lps = LeccionPalabra.query.filter(LeccionPalabra.id_leccion.in_(ids)).all()
        _post_supabase('leccion_palabras', [{
            'id_leccion_palabra': p.id_leccion_palabra, 'id_leccion': p.id_leccion,
            'id_palabra': p.id_palabra, 'veces_revisada': p.veces_revisada or 0,
            'aprendida': bool(p.aprendida), 'id_detalle': p.id_detalle, 'id_juego': p.id_juego,
            'respuesta': p.respuesta, 'id_usuario': p.id_usuario,
            'fecha_registro': _iso(p.fecha_registro), 'estado': p.estado,
            'id_datos_batch': p.id_datos_batch,
        } for p in lps])
    except Exception as e:
        print(f'[activacion] Sync Supabase falló: {e}')



def activar_batch(batch_id, juego_ids):
    """Crea lecciones (chunks de 10) y registros en las 3 tablas. Retorna (ok, msg)."""
    batch = DatosBatch.query.get(batch_id)
    if not batch:
        return False, "Carga no encontrada"
    if batch.estado != 0:
        return False, "La carga ya no está en estado 'cargada' (no se puede activar)"

    palabras = (Palabra.query
                .filter_by(id_tematica=batch.id_tematica, id_categoria=batch.id_categoria)
                .order_by(Palabra.id_palabra)
                .all())
    if not palabras:
        return False, "No hay palabras para esta carga"

    aplicables = set(juegos_aplicables(batch.id_categoria))
    juego_ids = [int(j) for j in juego_ids if int(j) in aplicables]
    if not juego_ids:
        return False, "No se seleccionó ningún juego válido para este tipo de palabra"

    n = len(palabras)
    full_lessons = n // PALABRAS_POR_LECCION
    if full_lessons == 0:
        return False, f"La carga tiene {n} palabras (menos de {PALABRAS_POR_LECCION}); no alcanza para una lección"

    lecciones = detalles = seguimiento = 0
    for li in range(full_lessons):
        chunk = palabras[li * PALABRAS_POR_LECCION:(li + 1) * PALABRAS_POR_LECCION]
        enc = EncabezadoLeccion(
            id_usuario=batch.id_usuario,
            cantidad_palabras=PALABRAS_POR_LECCION,
            porcentaje_aciertos=PALABRAS_POR_LECCION,
            estado=1, tipo_leccion=1, id_suscripcion='0',
            id_datos_batch=batch.id_datos_batch,
        )
        db.session.add(enc)
        db.session.flush()

        for gid in juego_ids:
            for s in GAMES[gid]['slots']:
                if s < 1 or s > len(chunk):
                    continue
                palabra = chunk[s - 1]
                det = LeccionDetalle(
                    id_leccion=enc.id_leccion, id_palabra=palabra.id_palabra,
                    id_juego=gid, estado=1, id_datos_batch=batch.id_datos_batch,
                )
                db.session.add(det)
                db.session.flush()
                detalles += 1
                db.session.add(LeccionPalabra(
                    id_leccion=enc.id_leccion, id_palabra=palabra.id_palabra,
                    id_detalle=det.id_detalle, id_juego=gid,
                    veces_revisada=0, aprendida=0, estado=1,
                    id_datos_batch=batch.id_datos_batch,
                ))
                seguimiento += 1
        lecciones += 1

    batch.estado = 1  # disponible
    db.session.commit()
    sync_activacion_to_supabase(batch_id)

    pendientes = n % PALABRAS_POR_LECCION
    return True, (f"Activadas {lecciones} lecciones · {detalles} detalles · "
                  f"{seguimiento} seguimientos · {pendientes} palabras pendientes")


def inactivar_batch(batch_id):
    """Desactiva la carga y sus lecciones dependientes. Retorna (ok, msg)."""
    batch = DatosBatch.query.get(batch_id)
    if not batch:
        return False, "Carga no encontrada"
    if batch.estado != 1:
        return False, "La carga no está 'disponible' (no se puede inactivar)"

    lecciones = EncabezadoLeccion.query.filter_by(id_datos_batch=batch_id).all()
    for lec in lecciones:
        lec.estado = 0
        LeccionDetalle.query.filter_by(id_leccion=lec.id_leccion).update({'estado': 0})
        LeccionPalabra.query.filter_by(id_leccion=lec.id_leccion).update({'estado': 0})
    batch.estado = 2  # inactivado
    db.session.commit()
    return True, f"Carga inactivada · {len(lecciones)} lecciones desactivadas"


def borrar_batch(batch_id):
    """Borra la carga solo si nunca fue activada (sin lecciones). Retorna (ok, msg)."""
    batch = DatosBatch.query.get(batch_id)
    if not batch:
        return False, "Carga no encontrada"
    if batch.estado != 0:
        return False, "La carga ya no está 'cargada' (no se puede borrar)"
    if EncabezadoLeccion.query.filter_by(id_datos_batch=batch_id).first():
        return False, "La carga ya fue activada (tiene lecciones); no se puede borrar"
    db.session.delete(batch)
    db.session.commit()
    return True, "Carga borrada"


def registrar_avance(id_usuario, id_leccion, resultados):
    """Registra el avance del estudiante por juego en leccion_palabras + sync Supabase."""
    from models import LeccionDetalle, LeccionPalabra
    try:
        n = 0
        for r in resultados:
            pid = r.get('id_palabra')
            jid = r.get('id_juego')
            if not pid or not jid:
                continue
            resp = 1 if r.get('respuesta') in (1, True, '1') else 0
            lp = LeccionPalabra.query.filter_by(
                id_leccion=id_leccion, id_palabra=pid, id_juego=jid, id_usuario=id_usuario
            ).first()
            if lp:
                lp.veces_revisada = (lp.veces_revisada or 0) + 1
                lp.respuesta = resp
                if resp == 1:
                    lp.aprendida = 1
            else:
                det = LeccionDetalle.query.filter_by(
                    id_leccion=id_leccion, id_palabra=pid, id_juego=jid).first()
                lp = LeccionPalabra(
                    id_leccion=id_leccion, id_palabra=pid, id_juego=jid,
                    id_detalle=det.id_detalle if det else None,
                    id_usuario=id_usuario,
                    id_datos_batch=det.id_datos_batch if det else None,
                    veces_revisada=1, respuesta=resp,
                    aprendida=1 if resp == 1 else 0, estado=1,
                )
                db.session.add(lp)
            n += 1
        db.session.commit()
        _sync_avance_to_supabase(id_usuario, id_leccion)
        return True, f"{n} avances registrados"
    except Exception as e:
        db.session.rollback()
        return False, str(e)


def _sync_avance_to_supabase(id_usuario, id_leccion):
    from models import LeccionPalabra
    try:
        lps = LeccionPalabra.query.filter_by(id_leccion=id_leccion, id_usuario=id_usuario).all()
        if not lps:
            return
        _post_supabase('leccion_palabras', [{
            'id_leccion_palabra': p.id_leccion_palabra, 'id_leccion': p.id_leccion,
            'id_palabra': p.id_palabra, 'veces_revisada': p.veces_revisada or 0,
            'aprendida': bool(p.aprendida), 'id_detalle': p.id_detalle, 'id_juego': p.id_juego,
            'respuesta': p.respuesta, 'id_usuario': p.id_usuario,
            'fecha_registro': _iso(p.fecha_registro), 'estado': p.estado,
            'id_datos_batch': p.id_datos_batch,
        } for p in lps])
    except Exception as e:
        print(f'[avance] Sync Supabase falló: {e}')
