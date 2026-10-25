#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Update dibatalkan: ada perubahan lokal yang belum disimpan."
  echo "Commit atau simpan perubahan lokal terlebih dahulu."
  exit 1
fi
echo "Mengambil source AERIS terbaru..."
git pull --ff-only origin main
APP="$ROOT/build/AERIS.app"
BACKUP="$ROOT/build/AERIS.app.backup"
mkdir -p "$ROOT/build"
if [[ -d "$APP" ]]; then
  rm -rf "$BACKUP"
  ditto "$APP" "$BACKUP"
fi
if ! ./build.sh; then
  if [[ -d "$BACKUP" ]]; then
    rm -rf "$APP"
    mv "$BACKUP" "$APP"
  fi
  echo "Build gagal. Source lama tetap tersedia."
  exit 1
fi
rm -rf "$BACKUP"
pkill -x AERIS 2>/dev/null || true
open "$APP"
echo "AERIS berhasil diperbarui."
