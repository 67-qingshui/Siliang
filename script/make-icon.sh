#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../design"

# Source image (jpg/png) -> 1024 PNG -> AppIcon.icns
SRC="${1:-AppIcon.jpg}"
BASE="$(basename "$SRC" .jpg)"
BASE="$(basename "$BASE" .png)"

echo "==> Preparing 1024px base..."
sips -s format png -z 1024 1024 "$SRC" --out "${BASE}_1024.png" >/dev/null

echo "==> Building iconset..."
ICONSET="${BASE}.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

while read -r size name; do
  sips -z "$size" "$size" "${BASE}_1024.png" --out "${ICONSET}/${name}.png" >/dev/null
done <<'SIZES'
16 icon_16x16
32 icon_16x16@2x
32 icon_32x32
64 icon_32x32@2x
128 icon_128x128
256 icon_128x128@2x
256 icon_256x256
512 icon_256x256@2x
512 icon_512x512
1024 icon_512x512@2x
SIZES

echo "==> Creating ${BASE}.icns..."
iconutil -c icns "$ICONSET" -o "${BASE}.icns"
rm -rf "$ICONSET" "${BASE}_1024.png"
echo "==> Done: design/${BASE}.icns"