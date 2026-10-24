#!/usr/bin/env python3
"""
pull_supabase.py — Sincronización Supabase → SQLite (espejo).

Supabase es la fuente de verdad; SQLite (lingo_nouns.db) se refleja desde Supabase.

Llave natural de `palabras`: (palabra_es, palabra_de, id_tematica) — normalizada.
Las oraciones se reconcilian por (id_palabra, oracion_ejemplo). Ambos usan
reconciliación por MULTISET (cuenta ocurrencias), de modo que los duplicados de
Supabase se reflejan fielmente y el pull es idempotente.

Uso:
    python3 pull_supabase.py              # dry-run: reporta sin escribir
    python3 pull_supabase.py --apply      # aplica los cambios a SQLite
"""
import os, sys, json, argparse, urllib.request
from collections import defaultdict, Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

SUPABASE_URL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
SUPABASE_KEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'


def _get(path):
    req = urllib.request.Request(
        SUPABASE_URL + path,
        headers={'apikey': SUPABASE_KEY, 'Authorization': 'Bearer ' + SUPABASE_KEY})
    return json.loads(urllib.request.urlopen(req, timeout=60).read())


def fetch_all(table, select='*'):
    """Descarga paginada de una tabla de Supabase (limit/offset)."""
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


def norm(s):
    return str(s or '').strip().lower()


def pkey(es, de, tema):
    return (norm(es), norm(de), int(tema or 0))


# Mapeo de columnas verbos: Supabase -> SQLite (inverso del push)
VERBO_MAP = {
    'conjuga_ich': 'conjuga_ich',
    'conjuga_du': 'conjuga_du',
    'conjuga_er': 'conjuga_er',
    'conjuga_ella': 'conjuga_sie',
    'conjuga_es': 'conjuga_es',
    'conjuga_wir': 'conjuga_wir',
    'conjuga_ihr': 'conjuga_ihr',
    'conjuga_usted': 'conjuga_Sie_formal',
    'conjuga_ellos': 'conjuga_sie_plural',
}


def _apply_palabra_fields(p, sp):
    """Vuelca campos de Supabase en un Palabra de SQLite. Devuelve True si cambió."""
    changed = False
    mapping = {
        'id_categoria': sp.get('id_categoria') or 1,
        'id_tipo': sp.get('id_tipo') or 1,
        'id_nivel': sp.get('id_nivel') or 1,
        'id_tematica': sp.get('id_tematica') or 99,
        'definicion': sp.get('definicion') or '',
        'oracion_ejemplo': sp.get('oracion_ejemplo') or '',
        'texto_emoji': sp.get('texto_emoji') or '📦',
        'activo': bool(sp.get('activo', True)),
    }
    for field, val in mapping.items():
        cur = getattr(p, field)
        if field == 'activo':
            cur = bool(cur)
        if cur != val:
            setattr(p, field, val)
            changed = True
    return changed


def pull(dry_run=True):
    from app import app
    from database import db
    from models import (Palabra, Sustantivo, Verbo, Oracion,
                        PalabraOracion, CatTematica)

    # ── 1. Descargar Supabase ──────────────────────────────
    supa = {
        'palabras': fetch_all('palabras'),
        'sustantivos': fetch_all('sustantivos'),
        'verbos': fetch_all('verbos'),
        'oraciones': fetch_all('oraciones'),
        'palabra_oracion': fetch_all('palabra_oracion'),
        'cat_tematica': fetch_all('cat_tematica'),
    }

    with app.app_context():
        report = {t: {'added': 0, 'updated': 0, 'deleted': 0} for t in supa}

        # ── 2. cat_tematica (por id_tematica, PK compartida) ─
        sql_tema_by_id = {t.id_tematica: t for t in CatTematica.query.all()}
        supa_tema_ids = set()
        for st in supa['cat_tematica']:
            tid = int(st['id_tematica'])
            supa_tema_ids.add(tid)
            nombre = st.get('nombre_tematica') or ''
            existing = sql_tema_by_id.get(tid)
            if existing is None:
                report['cat_tematica']['added'] += 1
                if not dry_run:
                    db.session.add(CatTematica(id_tematica=tid, nombre_tematica=nombre))
            elif existing.nombre_tematica != nombre:
                report['cat_tematica']['updated'] += 1
                if not dry_run:
                    existing.nombre_tematica = nombre
        for tid, t in sql_tema_by_id.items():
            if tid not in supa_tema_ids:
                report['cat_tematica']['deleted'] += 1
                if not dry_run:
                    db.session.delete(t)

        # ── 3. palabras (multiset por llave es+de+tema) ─────
        sql_pal = Palabra.query.all()
        sql_pal_by_key = defaultdict(list)
        for p in sql_pal:
            sql_pal_by_key[pkey(p.palabra_es, p.palabra_de, p.id_tematica)].append(p)

        id_map = {}  # supabase id_palabra -> sqlite id_palabra
        for sp in supa['palabras']:
            key = pkey(sp.get('palabra_es'), sp.get('palabra_de'), sp.get('id_tematica'))
            lst = sql_pal_by_key.get(key, [])
            if lst:
                existing = lst.pop(0)
                id_map[sp['id_palabra']] = existing.id_palabra
                if _apply_palabra_fields(existing, sp):
                    report['palabras']['updated'] += 1
            else:
                report['palabras']['added'] += 1
                if not dry_run:
                    np = Palabra(
                        id_categoria=sp.get('id_categoria') or 1,
                        id_tipo=sp.get('id_tipo') or 1,
                        id_nivel=sp.get('id_nivel') or 1,
                        id_tematica=sp.get('id_tematica') or 99,
                        palabra_es=sp.get('palabra_es') or '',
                        palabra_de=sp.get('palabra_de') or '',
                        definicion=sp.get('definicion') or '',
                        oracion_ejemplo=sp.get('oracion_ejemplo') or '',
                        texto_emoji=sp.get('texto_emoji') or '📦',
                        activo=bool(sp.get('activo', True)),
                    )
                    db.session.add(np)
                    db.session.flush()
                    id_map[sp['id_palabra']] = np.id_palabra

        # palabras SQLite sobrantes (más copias en SQLite que en Supabase) → borrar
        leftover_pal = [p for lst in sql_pal_by_key.values() for p in lst]
        report['palabras']['deleted'] = len(leftover_pal)
        if not dry_run:
            for p in leftover_pal:
                db.session.delete(p)

        # ── 4. sustantivos (1:1 por id_palabra mapeado) ─────
        sql_sust_by_pid = {s.id_palabra: s for s in Sustantivo.query.all()}
        supa_sust_pids = set()
        for ss in supa['sustantivos']:
            pid = id_map.get(ss['id_palabra'])
            if pid is None:
                continue
            supa_sust_pids.add(pid)
            existing = sql_sust_by_pid.get(pid)
            if existing is None:
                report['sustantivos']['added'] += 1
                if not dry_run:
                    db.session.add(Sustantivo(
                        id_palabra=pid, plural=ss.get('plural') or '',
                        femenino=ss.get('femenino') or '',
                        verbo_relacionado=ss.get('verbo_relacionado') or ''))
            elif ((existing.plural or '') != (ss.get('plural') or '') or
                    (existing.femenino or '') != (ss.get('femenino') or '') or
                    (existing.verbo_relacionado or '') != (ss.get('verbo_relacionado') or '')):
                report['sustantivos']['updated'] += 1
                if not dry_run:
                    existing.plural = ss.get('plural') or ''
                    existing.femenino = ss.get('femenino') or ''
                    existing.verbo_relacionado = ss.get('verbo_relacionado') or ''
        for pid, s in sql_sust_by_pid.items():
            if pid not in supa_sust_pids:
                report['sustantivos']['deleted'] += 1
                if not dry_run:
                    db.session.delete(s)

        # ── 5. verbos (1:1 por id_palabra mapeado) ──────────
        sql_verb_by_pid = {v.id_palabra: v for v in Verbo.query.all()}
        supa_verb_pids = set()
        for sv in supa['verbos']:
            pid = id_map.get(sv['id_palabra'])
            if pid is None:
                continue
            supa_verb_pids.add(pid)
            existing = sql_verb_by_pid.get(pid)
            vals = {sql_col: (sv.get(supa_col) or '') for supa_col, sql_col in VERBO_MAP.items()}
            if existing is None:
                report['verbos']['added'] += 1
                if not dry_run:
                    db.session.add(Verbo(id_palabra=pid, **vals))
            elif any((getattr(existing, c) or '') != v for c, v in vals.items()):
                report['verbos']['updated'] += 1
                if not dry_run:
                    for c, v in vals.items():
                        setattr(existing, c, v)
        for pid, v in sql_verb_by_pid.items():
            if pid not in supa_verb_pids:
                report['verbos']['deleted'] += 1
                if not dry_run:
                    db.session.delete(v)

        # ── 6. oraciones (multiset por id_palabra+texto) ────
        sql_orac = Oracion.query.all()
        sql_orac_by_key = defaultdict(list)
        for o in sql_orac:
            sql_orac_by_key[(o.id_palabra, norm(o.oracion_ejemplo))].append(o)

        id_orac_map = {}  # supabase id_oracion -> sqlite id_oracion
        for so in supa['oraciones']:
            pid = id_map.get(so['id_palabra'])
            if pid is None:
                continue
            key = (pid, norm(so.get('oracion_ejemplo')))
            lst = sql_orac_by_key.get(key, [])
            if lst:
                existing = lst.pop(0)
                id_orac_map[so['id_oracion']] = existing.id_oracion
                if ((existing.oracion_traduccion or '') != (so.get('oracion_traduccion') or '') or
                        (existing.nivel_dificultad or 1) != (so.get('nivel_dificultad') or 1)):
                    report['oraciones']['updated'] += 1
                    if not dry_run:
                        existing.oracion_traduccion = so.get('oracion_traduccion') or ''
                        existing.nivel_dificultad = so.get('nivel_dificultad') or 1
            else:
                report['oraciones']['added'] += 1
                if not dry_run:
                    no = Oracion(
                        id_palabra=pid,
                        oracion_ejemplo=so.get('oracion_ejemplo') or '',
                        oracion_traduccion=so.get('oracion_traduccion') or '',
                        nivel_dificultad=so.get('nivel_dificultad') or 1)
                    db.session.add(no)
                    db.session.flush()
                    id_orac_map[so['id_oracion']] = no.id_oracion

        leftover_orac = [o for lst in sql_orac_by_key.values() for o in lst]
        report['oraciones']['deleted'] = len(leftover_orac)
        if not dry_run:
            for o in leftover_orac:
                db.session.delete(o)

        # ── 7. palabra_oracion (tokens por oración) ─────────
        sql_po_by_orac = defaultdict(list)
        for po in PalabraOracion.query.all():
            sql_po_by_orac[po.id_oracion].append(po)
        valid_orac_ids = set(id_orac_map.values())
        for so in supa['oraciones']:
            oid = id_orac_map.get(so['id_oracion'])
            if oid is None:
                continue
            supa_tokens = [p for p in supa['palabra_oracion']
                           if p['id_oracion'] == so['id_oracion']]
            supa_tokens.sort(key=lambda t: t.get('orden', 0))
            existing_tokens = sql_po_by_orac.get(oid, [])
            new_sig = sorted([(t.get('orden'), (t.get('palabra') or '')) for t in supa_tokens])
            old_sig = sorted([(t.orden, t.palabra or '') for t in existing_tokens])
            if old_sig != new_sig:
                report['palabra_oracion']['updated'] += 1
                if not dry_run:
                    for t in existing_tokens:
                        db.session.delete(t)
                    for t in supa_tokens:
                        db.session.add(PalabraOracion(
                            id_oracion=oid, orden=t.get('orden'),
                            palabra=t.get('palabra') or ''))
        # tokens de oraciones borradas
        for oid, toks in sql_po_by_orac.items():
            if oid not in valid_orac_ids:
                report['palabra_oracion']['deleted'] += len(toks)
                if not dry_run:
                    for t in toks:
                        db.session.delete(t)

        # ── 8. Commit / rollback ────────────────────────────
        if dry_run:
            db.session.rollback()
        else:
            db.session.commit()

        return report


def main():
    ap = argparse.ArgumentParser(description='Sync Supabase -> SQLite (espejo)')
    ap.add_argument('--apply', action='store_true', help='Aplica los cambios (por defecto dry-run)')
    args = ap.parse_args()

    report = pull(dry_run=not args.apply)
    print('============================================================')
    print('  Supabase → SQLite  |  ' + ('APLICADO' if args.apply else 'DRY-RUN (sin cambios)'))
    print('============================================================')
    for table, r in report.items():
        print(f'  {table:18} +{r["added"]:4} añadidas  ~{r["updated"]:4} actualizadas  -{r["deleted"]:4} borradas')
    print('============================================================')


if __name__ == '__main__':
    main()
