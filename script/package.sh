#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Siliang"
DIST="dist"

echo "==> Building release (Apple Silicon)..."
swift build -c release --disable-sandbox

BIN=".build/arm64-apple-macosx/release/${APP_NAME}"
if [ ! -f "$BIN" ]; then
  BIN=".build/release/${APP_NAME}"
fi
echo "==> Binary: $BIN"

APP="${DIST}/${APP_NAME}.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/${APP_NAME}"
if [ -f "design/AppIcon.icns" ]; then
  cp "design/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Siliang</string>
    <key>CFBundleIdentifier</key>
    <string>com.siliang.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>Siliang</string>
    <key>CFBundleDisplayName</key>
    <string>司量</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.finance</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Ad-hoc codesigning (required on Apple Silicon)..."
codesign --force --deep --sign - "$APP"

echo "==> Creating DMG..."
DMG="${DIST}/${APP_NAME}.dmg"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP" -ov -format UDZO "$DMG" >/dev/null

echo "==> Done:"
ls -lh "$DMG"