#!/bin/bash
# Builds a release binary and assembles it into "Spotlight Wallpaper.app".
#
# Usage:
#   scripts/build-app.sh          # produces .build/Spotlight Wallpaper.app
#   scripts/build-app.sh --zip    # also produces .build/Spotlight Wallpaper.zip
set -euo pipefail

cd "$(dirname "$0")/.."

app_name="Spotlight Wallpaper"
bundle_id="com.maxgoodwin.SpotlightWallpaper"
executable_name="spotlight-wallpaper"

version=$(grep -m1 '^let version' Sources/spotlight-wallpaper/main.swift | sed -E 's/.*"([^"]+)".*/\1/')
if [[ -z "$version" ]]; then
    echo "error: could not read version from main.swift" >&2
    exit 1
fi

if [[ ! -f "Assets/AppIcon.icns" ]]; then
    echo "error: Assets/AppIcon.icns not found — run scripts/make-icon.sh first" >&2
    exit 1
fi

echo "Building release binary (version $version)…"
swift build -c release

app_bundle=".build/${app_name}.app"
rm -rf "$app_bundle"
mkdir -p "$app_bundle/Contents/MacOS" "$app_bundle/Contents/Resources"

cp ".build/release/${executable_name}" "$app_bundle/Contents/MacOS/${executable_name}"
cp "Assets/AppIcon.icns" "$app_bundle/Contents/Resources/AppIcon.icns"

cat > "$app_bundle/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${app_name}</string>
    <key>CFBundleDisplayName</key>
    <string>${app_name}</string>
    <key>CFBundleIdentifier</key>
    <string>${bundle_id}</string>
    <key>CFBundleExecutable</key>
    <string>${executable_name}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${version}</string>
    <key>CFBundleVersion</key>
    <string>${version}</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "Built $app_bundle"

# Ad-hoc sign: unsigned bundles can fail SMAppService.mainApp.register() (used by the
# "Launch at login" toggle) and trigger Gatekeeper "app is damaged" prompts. This isn't
# a substitute for a real Developer ID signature + notarization for wide distribution,
# but it's sufficient for local builds and direct downloads.
codesign --force --deep --sign - "$app_bundle"

if [[ "${1:-}" == "--zip" ]]; then
    zip_path=".build/${app_name}.zip"
    rm -f "$zip_path"
    (cd .build && zip -rq "${app_name}.zip" "${app_name}.app")
    echo "Wrote $zip_path"
fi
