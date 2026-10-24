#!/bin/bash
# Keepalive del servidor Flask de Ubenplay (admin web, puerto 9999).
# Silencioso si el servidor está vivo; reinicia y avisa si está caído.
DIR="$(dirname "$0")"
LOG="$DIR/ubenplay_server.log"
URL="http://127.0.0.1:9999/login"
CODE=$(curl -s -m 4 -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null)
if [ "$CODE" = "200" ]; then
  exit 0
fi
cd "$DIR" || exit 1
nohup python run_supabase.py > "$LOG" 2>&1 < /dev/null &
sleep 3
CODE2=$(curl -s -m 4 -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null)
if [ "$CODE2" = "200" ]; then
  echo "✅ Servidor Ubenplay reiniciado automáticamente (estaba caído)."
else
  echo "⚠️ Servidor Ubenplay caído y no pudo reiniciarse. Ver $LOG"
fi
