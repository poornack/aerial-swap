#!/bin/zsh
# Installs reapply.sh + LaunchAgent so the swap is re-applied at login and hourly.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
STORE="$HOME/Library/Application Support/AerialSwap"
mkdir -p "$STORE" ~/Library/LaunchAgents
cp "$HERE/reapply.sh" "$STORE/reapply.sh"; chmod +x "$STORE/reapply.sh"
sed "s|~/Library|$HOME/Library|" "$HERE/com.poorna.aerialswap.plist" > ~/Library/LaunchAgents/com.poorna.aerialswap.plist
launchctl bootout gui/$(id -u)/com.poorna.aerialswap 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.poorna.aerialswap.plist
echo "LaunchAgent installed"
