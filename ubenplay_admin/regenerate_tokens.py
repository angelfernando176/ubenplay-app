#!/usr/bin/env python3
"""Regenera los tokens (palabra_oracion) faltantes en SQLite y Supabase.

Parte cada oracion_ejemplo en palabras (misma lógica que la importación) y publica
los tokens que faltan. Idempotente: solo agrega, nunca borra. Publica en LOTES.

Uso:
    python3 regenerate_tokens.py            # SQLite + Supabase
    python3 regenerate_tokens.py --supabase # solo Supabase
    python3 regenerate_tokens.py --sqlite   # solo SQLite
"""
import os, sqlite3, json, argparse, urllib.request, urllib.error

SUPABASE_URL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
SUPABASE_KEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'
PUNCT = '.,;:!?¿¡()[]""'
BATCH = 500


def split_words(txt):
    words = []
    for i, part in enumerate(str(txt or '').split()):
        w = part.strip(PUNCT)[:50]
        if w:
            words.append((i + 1, w))
    return words


def fetch_all(table, select='*'):
    rows, offset, limit = [], 0, 1000
    while True:
        req = urllib.request.Request(
            f'{SUPABASE_URL}/rest/v1/{table}?select={select}&limit={limit}&offset={offset}',
            headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}'})
        batch = json.loads(urllib.request.urlopen(req, timeout=60).read())
        if not batch:
            break
        rows.extend(batch)
        if len(batch) < limit:
            break
        offset += limit
    return rows


def post_batch(tokens):
    req = urllib.request.Request(f'{SUPABASE_URL}/rest/v1/palabra_oracion',
                                 data=json.dumps(tokens).encode(), method='POST',
                                 headers={'apikey': SUPABASE_KEY, 'Authorization': f'Bearer {SUPABASE_KEY}',
                                          'Content-Type': 'application/json', 'Prefer': 'return=minimal'})
    urllib.request.urlopen(req, timeout=60)


def do_sqlite():
    db = sqlite3.connect(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lingo_nouns.db'))
    cur = db.cursor()
    sin = cur.execute('''SELECT id_oracion, oracion_ejemplo FROM oraciones o
                         WHERE NOT EXISTS (SELECT 1 FROM palabra_oracion po WHERE po.id_oracion = o.id_oracion)
                           AND o.oracion_ejemplo IS NOT NULL AND trim(o.oracion_ejemplo) != '' ''').fetchall()
    n = 0
    for oid, texto in sin:
        for orden, palabra in split_words(texto):
            cur.execute('INSERT INTO palabra_oracion (id_oracion, orden, palabra) VALUES (?,?,?)',
                        (oid, orden, palabra))
            n += 1
    db.commit()
    db.close()
    print(f'SQLITE: {len(sin)} oraciones sin tokens -> {n} tokens insertados')


def do_supabase():
    orac = fetch_all('oraciones')
    po = fetch_all('palabra_oracion')
    po_ids = set(r['id_oracion'] for r in po)
    faltantes = [o for o in orac if o['id_oracion'] not in po_ids and str(o.get('oracion_ejemplo') or '').strip()]
    buffer, n_pub, n_orac = [], 0, 0
    for o in faltantes:
        tokens = [{'id_oracion': o['id_oracion'], 'orden': orden, 'palabra': palabra}
                  for orden, palabra in split_words(o.get('oracion_ejemplo'))]
        if not tokens:
            continue
        buffer.extend(tokens)
        n_orac += 1
        while len(buffer) >= BATCH:
            post_batch(buffer[:BATCH]); n_pub += BATCH; buffer = buffer[BATCH:]
            print(f'  publicados {n_pub} tokens...', flush=True)
    if buffer:
        post_batch(buffer); n_pub += len(buffer)
    print(f'SUPABASE: {n_orac} oraciones procesadas, {n_pub} tokens publicados')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--supabase', action='store_true')
    ap.add_argument('--sqlite', action='store_true')
    args = ap.parse_args()
    both = not args.supabase and not args.sqlite
    if both or args.sqlite:
        do_sqlite()
    if both or args.supabase:
        do_supabase()


if __name__ == '__main__':
    main()
