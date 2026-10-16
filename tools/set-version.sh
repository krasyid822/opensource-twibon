#!/usr/bin/env bash
# Satu sumber versi aplikasi: menulis nomor versi ke sw.js (nama cache) dan
# index.html (meta app-version). Dipakai otomatis oleh push.sh, atau manual:
#
#   tools/set-version.sh              -> versi dari waktu sekarang (v2026.10.16.0920)
#   tools/set-version.sh v1.2.3       -> versi tertentu ("v1.2.3" ditambah bila perlu)
#
set -euo pipefail
cd "$(dirname "$0")/.."

raw="${1:-}"
if [ -z "$raw" ]; then
  raw="v$(date +%Y.%m.%d).$(date +%H%M)"
fi
# pastikan berawalan "v"
case "$raw" in v*) V="$raw";; *) V="v$raw";; esac

sed -i -E "s/^const VERSION = '[^']*';/const VERSION = '${V}';/" sw.js
sed -i -E "s/(<meta name=\"app-version\" content=\")[^\"]*(\")/\1${V}\2/" index.html

# verifikasi kedua berkas benar-benar berubah
if ! grep -q "^const VERSION = '${V}';" sw.js; then
  echo "GAGAL: sw.js tidak memuat const VERSION = '${V}';" >&2
  exit 1
fi
if ! grep -q "name=\"app-version\" content=\"${V}\"" index.html; then
  echo "GAGAL: index.html tidak memuat meta app-version ${V}" >&2
  exit 1
fi
echo "versi -> ${V}"
