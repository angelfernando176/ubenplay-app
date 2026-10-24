"""Monitor de carga: rastrea conteos de SQLite y Supabase y registra cambios."""
import os, sqlite3, json, urllib.request, time

DB = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lingo_nouns.db')
SURL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co'
SKEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS'

SQL_TABLES = ['palabras', 'sustantivos', 'verbos', 'oraciones', 'palabra_oracion']
SUPA_TABLES = ['palabras', 'sustantivos', 'verbos', 'oraciones', 'palabra_oracion']


def sql_counts():
    con = sqlite3.connect(DB)
    cur = con.cursor()
    out = {}
    for t in SQL_TABLES:
        try:
            cur.execute(f'SELECT COUNT(*) FROM "{t}"')
            out[t] = cur.fetchone()[0]
        except Exception:
            out[t] = -1
    con.close()
    return out


def supa_counts():
    out = {}
    for t in SUPA_TABLES:
        try:
            req = urllib.request.Request(
                f'{SURL}/rest/v1/{t}?select=count',
                headers={'apikey': SKEY, 'Authorization': f'Bearer {SKEY}', 'Prefer': 'count=exact'})
            r = urllib.request.urlopen(req, timeout=30)
            out[t] = int(r.headers.get('content-range', '0/0').split('/')[-1])
        except Exception:
            out[t] = -1
    return out


def fmt(d):
    return ' '.join(f'{k}={v}' for k, v in d.items())


prev = None
print('Monitor iniciado. Registrando cambios cada 15s...', flush=True)
while True:
    try:
        s = sql_counts()
        p = supa_counts()
        cur = (tuple(sorted(s.items())), tuple(sorted(p.items())))
        if cur != prev:
            ts = time.strftime('%H:%M:%S')
            print(f'[{ts}] SQLite  : {fmt(s)}', flush=True)
            print(f'[{ts}] Supabase: {fmt(p)}', flush=True)
            prev = cur
    except Exception as e:
        print(f'[{time.strftime("%H:%M:%S")}] ERROR: {e}', flush=True)
    time.sleep(15)
