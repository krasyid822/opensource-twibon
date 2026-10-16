#!/usr/bin/env bash
#
# run.sh — menjalankan Twibon (web statis) di komputer sendiri.
#
# Pemakaian:
#   ./run.sh                  # http://127.0.0.1:8080
#   PORT=3000 ./run.sh        # ganti port
#   HOST=0.0.0.0 ./run.sh     # bisa dibuka dari ponsel di jaringan yang sama
#   NO_OPEN=1 ./run.sh        # jangan buka peramban otomatis
#
set -euo pipefail

cd "$(dirname "$0")"

PORT="${PORT:-8080}"
HOST="${HOST:-127.0.0.1}"
OPEN_HOST="$HOST"
if [ "$HOST" = "0.0.0.0" ]; then OPEN_HOST="127.0.0.1"; fi
URL="http://${OPEN_HOST}:${PORT}/index.html"

if [ ! -f index.html ]; then
  echo "index.html tidak ditemukan di $(pwd)" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  cat >&2 <<'MSG'
python3 tidak ditemukan.

Twibon hanyalah berkas statis, jadi server statis apa pun bisa dipakai, misalnya:
  npx --yes serve -l 8080 .
  php -S 127.0.0.1:8080
Atau cukup buka index.html langsung di peramban.
(Mode luring/PWA memerlukan server http, bukan file://)
MSG
  exit 1
fi

echo "Twibon berjalan di: ${URL}"
echo "Tekan Ctrl+C untuk berhenti."
if [ "$HOST" = "0.0.0.0" ]; then
  echo "Dari ponsel di jaringan yang sama, buka: http://<IP-komputer>:${PORT}/index.html"
fi

if [ "${NO_OPEN:-0}" != "1" ]; then
  (
    sleep 1
    if command -v xdg-open >/dev/null 2>&1; then
      xdg-open "${URL}" >/dev/null 2>&1 || true
    elif command -v open >/dev/null 2>&1; then
      open "${URL}" >/dev/null 2>&1 || true
    fi
  ) &
fi

exec python3 -m http.server "${PORT}" --bind "${HOST}"
