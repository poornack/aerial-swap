#!/bin/zsh
# Builds Aerial Swap.app and registers its LaunchAgent through ServiceManagement, so the
# swap is re-applied at login and hourly, and Login Items shows the app's name and icon.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p ~/Applications
# remove any old-style agent installed in ~/Library/LaunchAgents
launchctl bootout gui/$(id -u)/com.poorna.aerialswap 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.poorna.aerialswap.plist
APP="$("$HERE/../app/build-app.sh" ~/Applications)"
"$APP/Contents/MacOS/Aerial Swap" --register
echo "Aerial Swap registered as a login item"
