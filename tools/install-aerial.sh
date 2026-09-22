#!/bin/zsh
# Install a generated .mov over one of Apple's downloaded Aerial assets and restart the engine.
# usage: install-aerial.sh <custom.mov> [asset-id]
# The asset must already be downloaded in System Settings > Screen Saver (any Aerial).
# Default asset id is "San Francisco Skyline". Use list-aerials.sh to find others.
set -euo pipefail
CUSTOM="$1"; ID="${2:-85CE77BF-3413-4A7B-9B0F-732E96229A73}"
DIR="$HOME/Library/Application Support/com.apple.wallpaper/aerials/videos"
TARGET="$DIR/$ID.mov"
BACKUP_DIR="$HOME/Library/Application Support/AerialBackup"
STORE="$HOME/Library/Application Support/AerialSwap"
[ -f "$TARGET" ] || { echo "Aerial $ID is not downloaded yet: $TARGET" >&2; exit 1; }
mkdir -p "$BACKUP_DIR" "$STORE"
[ -f "$BACKUP_DIR/$ID.mov" ] || cp "$TARGET" "$BACKUP_DIR/$ID.mov"
cp "$CUSTOM" "$STORE/$ID.mov"          # kept so reapply.sh can restore it after an OS update
cp "$STORE/$ID.mov" "$TARGET"; chmod 600 "$TARGET"
pkill -x WallpaperAerialsExtension 2>/dev/null || true
pkill -x WallpaperAgent 2>/dev/null || true
echo "installed over $ID; original backed up to $BACKUP_DIR"
