#!/usr/bin/env bash
#
# push.sh — dorong proyek ini ke GitHub lalu aktifkan GitHub Pages.
#
# Urutan kerja:
#   1. git init bila belum ada repositori
#   2. commit semua perubahan
#   3. gh repo create bila repo GitHub belum ada (dengan deskripsi yang jelas)
#   4. push ke branch utama
#   5. aktifkan GitHub Pages (Source: GitHub Actions) lewat gh api
#   6. jalankan workflow deploy dan tampilkan URL situs
#
# Pemakaian:
#   ./push.sh                      # publik, nama repo dari nama folder
#   REPO_NAME=twibon ./push.sh     # tentukan nama repo
#   VISIBILITY=private ./push.sh   # repo privat
#   DRY_RUN=1 ./push.sh            # hanya menampilkan rencana, tanpa efek samping
#
# Catatan: jalankan dari mana saja — skrip ini pindah ke direktorinya sendiri.
#
set -euo pipefail
cd "$(dirname "$0")"

REPO_NAME="${REPO_NAME:-$(basename "$PWD")}"
VISIBILITY="${VISIBILITY:-public}"
BRANCH="${BRANCH:-main}"
COMMIT_MSG="${COMMIT_MSG:-Update Twibon: pembuat twibbon statis (GPL-3.0, PWA luring)}"
DESCRIPTION="${DESCRIPTION:-Twibon - pembuat twibbon statis. Isi bagian kosong template twibbon dengan foto lalu unduh tanpa watermark. Gratis, tanpa server, bekerja penuh luring (PWA). Lisensi GPL-3.0.}"
DRY_RUN="${DRY_RUN:-0}"

log()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
info() { printf '  %s\n' "$*"; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
run()  { if [ "$DRY_RUN" = "1" ]; then printf '  [dry-run] %s\n' "$*"; else "$@"; fi; }

command -v git >/dev/null 2>&1 || die "git tidak ditemukan."
command -v gh  >/dev/null 2>&1 || die "gh (GitHub CLI) tidak ditemukan — pasang dari https://cli.github.com"
gh auth status >/dev/null 2>&1 || die "Belum login ke GitHub. Jalankan dulu: gh auth login"

LOGIN="$(gh api user --jq .login 2>/dev/null || true)"
[ -n "$LOGIN" ] || die "Tidak bisa membaca akun GitHub (periksa: gh auth status)."

# Tentukan slug owner/repo: hormati remote 'origin' bila sudah ada.
ORIGIN_URL=""
if [ -d .git ]; then ORIGIN_URL="$(git remote get-url origin 2>/dev/null || true)"; fi
case "$ORIGIN_URL" in
  git@github.com:*)     SLUG="${ORIGIN_URL#git@github.com:}"; SLUG="${SLUG%.git}" ;;
  https://github.com/*) SLUG="${ORIGIN_URL#https://github.com/}"; SLUG="${SLUG%.git}" ;;
  *)                    SLUG="$LOGIN/$REPO_NAME" ;;
esac
OWNER="${SLUG%%/*}"

info "Akun GitHub : $LOGIN"
info "Repo tujuan : $SLUG ($VISIBILITY)"
if [ "$DRY_RUN" = "1" ]; then info "Mode        : DRY RUN (tanpa efek samping)"; fi

# ── 1) git init ──
log "1/6  Menyiapkan repositori git"
if [ -d .git ]; then
  info "repositori git sudah ada"
else
  run git init -q
  info "git init selesai"
fi

if [ "$DRY_RUN" != "1" ]; then
  git config user.email >/dev/null 2>&1 || git config user.email "${LOGIN}@users.noreply.github.com"
  git config user.name  >/dev/null 2>&1 || git config user.name  "${LOGIN}"
fi

# ── 2) commit ──
log "2/6  Menyimpan perubahan (commit)"
# Naikkan nomor versi cache secara otomatis (satu sumber: sw.js + index.html)
# hanya bila memang ada yang akan di-commit, agar tidak membuat commit kosong.
NEED_BUMP=0
if [ ! -d .git ] || ! git rev-parse -q --verify HEAD >/dev/null 2>&1; then NEED_BUMP=1; fi
if [ -n "$(git status --porcelain 2>/dev/null || true)" ]; then NEED_BUMP=1; fi
if [ "$DRY_RUN" = "1" ]; then
  info "[dry-run] tools/set-version.sh  (naikkan versi cache)"
elif [ "$NEED_BUMP" = "1" ]; then
  ./tools/set-version.sh
else
  info "tidak ada perubahan — versi cache dibiarkan"
fi
run git add -A
if [ "$DRY_RUN" = "1" ]; then
  info "[dry-run] git commit -m \"$COMMIT_MSG\" (bila ada perubahan)"
elif git diff --cached --quiet; then
  info "tidak ada perubahan baru untuk di-commit"
else
  git commit -q -m "$COMMIT_MSG"
  info "commit dibuat"
fi
run git branch -M "$BRANCH"

# ── 3) repo GitHub ──
log "3/6  Memastikan repo GitHub ada"
if [ -n "$ORIGIN_URL" ]; then
  info "remote origin sudah ada: $ORIGIN_URL"
elif [ "$DRY_RUN" = "1" ]; then
  info "[dry-run] gh repo create $REPO_NAME --$VISIBILITY --source=. --remote=origin --description \"$DESCRIPTION\""
else
  if gh repo view "$SLUG" >/dev/null 2>&1; then
    info "repo $SLUG sudah ada di GitHub"
  else
    gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin --description "$DESCRIPTION"
    info "repo $SLUG dibuat"
  fi
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$SLUG.git"
fi

# ── 4) push ──
log "4/6  Push ke GitHub"
if [ "$DRY_RUN" = "1" ]; then
  info "[dry-run] git push -u origin $BRANCH"
elif git push -u origin "$BRANCH"; then
  info "push selesai"
else
  die "push gagal — periksa kredensial/remote lalu jalankan ulang."
fi

# ── 5) aktifkan Pages ──
log "5/6  Mengaktifkan GitHub Pages (Source: GitHub Actions)"
if [ "$DRY_RUN" = "1" ]; then
  info "[dry-run] gh api -X POST repos/$SLUG/pages -f build_type=workflow  (atau PUT bila sudah ada)"
else
  if gh api "repos/$SLUG/pages" >/dev/null 2>&1; then
    gh api -X PUT "repos/$SLUG/pages" -f build_type=workflow >/dev/null
    info "Pages sudah ada — diatur ke build_type=workflow"
  elif gh api -X POST "repos/$SLUG/pages" -f build_type=workflow >/dev/null 2>&1; then
    info "Pages diaktifkan (build_type=workflow)"
  else
    gh api -X PUT "repos/$SLUG/pages" -f build_type=workflow >/dev/null
    info "Pages diperbarui ke build_type=workflow"
  fi
fi

# ── 6) jalankan deploy ──
log "6/6  Menjalankan deploy"
if [ "$DRY_RUN" = "1" ]; then
  info "[dry-run] gh workflow run pages.yml --ref $BRANCH"
  info "[dry-run] gh api repos/$SLUG/pages --jq .html_url"
else
  # Push tadi sudah memicu workflow, tetapi Pages baru aktif setelah langkah 5,
  # jadi jalankan sekali lagi agar deploy pertama pasti berhasil.
  sleep 2
  if gh workflow run pages.yml --ref "$BRANCH" >/dev/null 2>&1; then
    info "workflow deploy dipicu"
  else
    info "workflow mungkin sudah berjalan otomatis dari push"
  fi
  sleep 3
  URL="$(gh api "repos/$SLUG/pages" --jq .html_url 2>/dev/null || true)"
  printf '\n\033[1mSelesai.\033[0m Situs: %s\n' "${URL:-https://${OWNER}.github.io/${REPO_NAME}/}"
  echo
  echo "  Pantau status : gh run list --workflow=pages.yml"
  echo "  Buka di web   : gh browse"
  echo
  echo "  Catatan: deploy pertama butuh sekitar 1 menit sebelum URL aktif."
fi
