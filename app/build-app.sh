#!/bin/zsh
# Builds "Wallpaper Aerials Sync.app": a background-only app bundle whose executable is reapply.sh.
# Login Items then shows a proper name and icon instead of "zsh".
# usage: build-app.sh [destination dir]   (default ~/Applications)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="${1:-$HOME/Applications}"
APP="$DEST/Wallpaper Aerials Sync.app"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# icon
swiftc -O -framework AppKit -o "$TMP/make-icon" "$HERE/make-icon.swift"
mkdir -p "$TMP/AppIcon.iconset"
for s in 16 32 128 256 512; do
  "$TMP/make-icon" $s "$TMP/AppIcon.iconset/icon_${s}x${s}.png"
  "$TMP/make-icon" $((s*2)) "$TMP/AppIcon.iconset/icon_${s}x${s}@2x.png"
done
iconutil -c icns "$TMP/AppIcon.iconset" -o "$TMP/AppIcon.icns"

# bundle
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -framework ServiceManagement -o "$APP/Contents/MacOS/Wallpaper Aerials Sync" "$HERE/main.swift"
mkdir -p "$APP/Contents/Library/LaunchAgents"
cp "$HERE/../launchd/com.poorna.aerialswap.plist" "$APP/Contents/Library/LaunchAgents/"
cp "$HERE/../launchd/reapply.sh" "$APP/Contents/Resources/reapply.sh"; chmod +x "$APP/Contents/Resources/reapply.sh"
cp "$TMP/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Wallpaper Aerials Sync</string>
  <key>CFBundleDisplayName</key><string>Wallpaper Aerials Sync</string>
  <key>CFBundleIdentifier</key><string>com.poorna.aerialswap</string>
  <key>CFBundleExecutable</key><string>Wallpaper Aerials Sync</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" >/dev/null 2>&1 || true
touch "$APP"
echo "$APP"
