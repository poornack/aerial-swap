#!/bin/zsh
# Re-installs the custom video over the Aerial asset if macOS has restored Apple's original
# (after an OS update or an asset re-download). Run at login by the LaunchAgent.
STORE="$HOME/Library/Application Support/AerialSwap"
DIR="$HOME/Library/Application Support/com.apple.wallpaper/aerials/videos"
BACKUP_DIR="$HOME/Library/Application Support/AerialBackup"
mkdir -p "$BACKUP_DIR"
for CUSTOM in "$STORE"/*.mov(N); do
  ID="${CUSTOM:t:r}"; TARGET="$DIR/$ID.mov"
  [ -f "$TARGET" ] && cmp -s "$TARGET" "$CUSTOM" && continue
  [ -f "$TARGET" ] && [ ! -f "$BACKUP_DIR/$ID.mov" ] && cp "$TARGET" "$BACKUP_DIR/$ID.mov"
  cp "$CUSTOM" "$TARGET" && chmod 600 "$TARGET"
  pkill -x WallpaperAerialsExtension 2>/dev/null
  echo "$(date '+%F %T') reapplied $ID" >> "$STORE/reapply.log"
done
