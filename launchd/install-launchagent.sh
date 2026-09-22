#!/bin/zsh
# Builds Aerial Swap.app and installs the LaunchAgent so the swap is re-applied at login and hourly.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p ~/Library/LaunchAgents ~/Applications
"$HERE/../app/build-app.sh" ~/Applications
sed "s|~/Applications|$HOME/Applications|" "$HERE/com.poorna.aerialswap.plist" > ~/Library/LaunchAgents/com.poorna.aerialswap.plist
launchctl bootout gui/$(id -u)/com.poorna.aerialswap 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.poorna.aerialswap.plist
echo "LaunchAgent installed (shows as 'Aerial Swap' in Login Items)"
