#!/bin/zsh
# Builds Wallpaper Aerials Sync.app and registers its LaunchAgent through ServiceManagement, so the
# swap is re-applied at login and hourly, and Login Items shows the app's name and icon.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p ~/Applications
# remove any old-style agent installed in ~/Library/LaunchAgents
launchctl bootout gui/$(id -u)/com.poorna.wallpaperaerialssync 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.poorna.wallpaperaerialssync.plist
APP="$("$HERE/../app/build-app.sh" ~/Applications)"
# unregister first: BTM otherwise keeps a stale "legacy agent" record with the generic icon
"$APP/Contents/MacOS/Wallpaper Aerials Sync" --unregister 2>/dev/null || true
sleep 2
"$APP/Contents/MacOS/Wallpaper Aerials Sync" --register
echo "Wallpaper Aerials Sync registered as a login item"
