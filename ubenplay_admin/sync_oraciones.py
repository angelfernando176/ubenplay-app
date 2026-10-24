"""Sync de oraciones y palabra_oracion de SQLite a Supabase.

Llave natural de palabras: (palabra_es, palabra_de, id_tematica) — igual que
pull_supabase.py. NO usar solo (es, de): hay homónimos en distintas temáticas.
Llave de oraciones: (id_palabra, oracion_ejemplo) — una palabra puede tener
varias oraciones, así que jamás colapsar por id_palabra.
"""
import json, urllib.request, time

SURL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
SKEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'
H = {'apikey': SKEY, 'Authorization': f'Bearer {SKEY}',
     'Content-Type': 'application/json', 'Prefer': 'resolution=merge-duplicates'}


def _get(path):
    req = urllib.request.Request(
        f'{SURL}{path}',
        headers={'apikey': SKEY, 'Authorization': f'Bearer {SKEY}'})
    return json.loads(urllib.request.urlopen(req, timeout=60).read())


def _fetch_all(table, select='*'):
    """Descarga paginada (PostgREST limita a 1000 filas por defecto)."""
    rows = []
    offset, limit = 0, 1000
    while True:
        batch = _get(f'/rest/v1/{table}?select={select}&limit={limit}&offset={offset}')
        if not batch:
            break
        rows.extend(batch)
        if len(batch) < limit:
            break
        offset += limit
    return rows


def _norm(s):
    return str(s or '').strip().lower()


def _pkey(es, de, tema):
    return (_norm(es), _norm(de), int(tema or 0))


def sync_oraciones_to_supabase(dry_run=False):
    """Sincroniza oraciones de SQLite a Supabase.

    dry_run=True solo calcula pendientes sin escribir en Supabase.
    Devuelve (oraciones_sincronizadas, tokens_sincronizados, pendientes_totales).
    """
    from app import app
    from models import Oracion, Palabra, PalabraOracion

    with app.app_context():
        # 1. Mapa de palabras en Supabase: (es,de,tema) -> id_palabra
        supa_words = _fetch_all('palabras', 'id_palabra,palabra_es,palabra_de,id_tematica')
        supa_pid_map = {}
        for w in supa_words:
            supa_pid_map[_pkey(w['palabra_es'], w['palabra_de'], w.get('id_tematica'))] = w['id_palabra']
        print(f'Palabras en Supabase: {len(supa_pid_map)}')

        # 2. Oraciones ya en Supabase: (id_palabra, texto) -> id_oracion
        supa_o_map = {}
        for x in _fetch_all('oraciones', 'id_oracion,id_palabra,oracion_ejemplo'):
            supa_o_map[(x['id_palabra'], _norm(x['oracion_ejemplo']))] = x['id_oracion']
        print(f'Oraciones en Supabase (llaves únicas): {len(supa_o_map)}')

        # 3. Oraciones pendientes (llave natural: palabra por es+de+tema, oración por texto)
        to_sync = []
        for o in Oracion.query.all():
            p = Palabra.query.get(o.id_palabra)
            if not p:
                continue
            supa_pid = supa_pid_map.get(_pkey(p.palabra_es, p.palabra_de, p.id_tematica))
            if not supa_pid:
                continue
            okey = (supa_pid, _norm(o.oracion_ejemplo))
            if okey not in supa_o_map:
                to_sync.append((o, supa_pid, okey))

        print(f'Oraciones pendientes: {len(to_sync)}')
        if not to_sync or dry_run:
            return 0, 0, len(to_sync)

        # 4. Sync oraciones en lotes
        synced = 0
        for i in range(0, len(to_sync), 20):
            batch = to_sync[i:i + 20]
            payload = [{
                'id_palabra': pid,
                'oracion_ejemplo': (o.oracion_ejemplo or '')[:500],
                'oracion_traduccion': (o.oracion_traduccion or '')[:500],
                'nivel_dificultad': o.nivel_dificultad or 1,
            } for o, pid, _ in batch]
            try:
                data = json.dumps(payload).encode()
                req = urllib.request.Request(f'{SURL}/rest/v1/oraciones', data=data, method='POST', headers=H)
                urllib.request.urlopen(req)
                synced += len(batch)
                time.sleep(0.5)
            except Exception as e:
                err = e.read().decode() if hasattr(e, 'read') else str(e)
                print(f'Error oraciones lote {i // 20}: {err[:120]}')
                break

        print(f'Oraciones sync: {synced}')

        # 5. Releer oraciones de Supabase para obtener el id_oracion ESPECÍFICO de cada una
        supa_o_map = {}
        for x in _fetch_all('oraciones', 'id_oracion,id_palabra,oracion_ejemplo'):
            supa_o_map[(x['id_palabra'], _norm(x['oracion_ejemplo']))] = x['id_oracion']

        # 6. Sync palabra_oracion (un id_oracion correcto por oración, no por palabra)
        spo = 0
        for o, supa_pid, okey in to_sync[:synced]:
            supa_oid = supa_o_map.get(okey)
            if not supa_oid:
                continue
            pos = PalabraOracion.query.filter_by(id_oracion=o.id_oracion).order_by(PalabraOracion.orden).all()
            if not pos:
                continue
            payload = [{
                'id_oracion': supa_oid,
                'orden': po.orden,
                'palabra': po.palabra or '',
                'significado': '',
            } for po in pos]
            try:
                data = json.dumps(payload).encode()
                req = urllib.request.Request(f'{SURL}/rest/v1/palabra_oracion', data=data, method='POST', headers=H)
                urllib.request.urlopen(req)
                spo += len(pos)
            except Exception as e:
                if spo == 0:
                    err = e.read().decode() if hasattr(e, 'read') else str(e)
                    print(f'Error PO: {err[:120]}')
            time.sleep(0.1)

        print(f'PalabraOracion sync: {spo}')

        return synced, spo, len(to_sync)


if __name__ == '__main__':
    import sys
    dry = '--dry-run' in sys.argv
    r = sync_oraciones_to_supabase(dry_run=dry)
    print('RESULT:', r)
