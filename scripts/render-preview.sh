#!/usr/bin/env bash
# Render scripts/preview.html to repo-root preview.png (1280x720).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HTML="$ROOT/scripts/preview.html"
OUT="$ROOT/preview.png"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

chromium --headless=new --disable-gpu --hide-scrollbars --no-first-run \
  --force-device-scale-factor=1 --window-size=1280,720 \
  --screenshot="$TMP/shot.png" "file://$HTML"

python3 - <<PY
from PIL import Image
im = Image.open("$TMP/shot.png").convert("RGB")
im = im.crop((0, 0, 1280, 720))
im.save("$OUT", "PNG", optimize=True)
print(im.size, "$OUT")
PY
