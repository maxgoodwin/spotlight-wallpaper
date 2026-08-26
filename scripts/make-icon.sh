#!/bin/bash
# Generates Assets/AppIcon.icns from the SF Symbol used by the menu bar icon.
# Regenerate after changing the glyph/colors in scripts/render-icon.swift.
set -euo pipefail

cd "$(dirname "$0")/.."

mkdir -p Assets
swift scripts/render-icon.swift Assets/icon-1024.png

iconset=$(mktemp -d)/AppIcon.iconset
mkdir -p "$iconset"

for size in 16 32 128 256 512; do
    sips -z "$size" "$size" Assets/icon-1024.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" Assets/icon-1024.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$iconset" -o Assets/AppIcon.icns
rm -rf "$(dirname "$iconset")"

echo "Wrote Assets/AppIcon.icns"
