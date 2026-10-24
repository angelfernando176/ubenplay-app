#!/bin/bash
# Ubenplay Admin Web - arranque determinista (SQLite local, sin reloader de debug)
# Usa run_supabase.py: hace pop de DATABASE_URL (ignora .env) y corre debug=False,
# evitando el fallo del reloader de Werkzeug que tomaba la URL de Supabase del .env.
cd "$(dirname "$0")"
exec python run_supabase.py
