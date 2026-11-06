#!/usr/bin/env bash
# Siteyi statik HTML olarak dışa aktarır (GitHub Pages için).
# Kullanım: bash scripts/export-static.sh [çıktı_klasörü]
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-_site}"
PORT="${EXPORT_PORT:-5099}"
BASE="http://127.0.0.1:${PORT}"

rm -rf "$OUT" .export-publish
dotnet publish Portfolio.csproj -c Release -o .export-publish -p:UseAppHost=false

ASPNETCORE_ENVIRONMENT=Production ASPNETCORE_URLS="$BASE" \
  dotnet .export-publish/Portfolio.dll > .export-server.log 2>&1 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null || true' EXIT

for _ in $(seq 1 60); do
  curl -fsS -o /dev/null "$BASE/" && break
  sleep 1
done

mkdir -p "$OUT/en"
cp -r .export-publish/wwwroot/. "$OUT/"
curl -fsS "$BASE/"   -o "$OUT/index.html"
curl -fsS "$BASE/en" -o "$OUT/en/index.html"
curl -sS  "$BASE/Error?code=404" -o "$OUT/404.html"

echo "halilmertdeveli.com.tr" > "$OUT/CNAME"
touch "$OUT/.nojekyll"
rm -rf .export-publish .export-server.log
echo "Statik site hazır: $OUT"
