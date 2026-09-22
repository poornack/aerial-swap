#!/bin/zsh
# Turn any video into a macOS Aerial screen saver file that survives lock/unlock ramps.
#
# usage: make-aerial.sh <input video> <output.mov> [--start SEC] [--end SEC] [--duration SEC]
#   --start/--end   trim points in the source (seconds)
#   --duration      target length of the output; the clip is looped to fill it (default 576.58,
#                   the length of Apple's "San Francisco Skyline" asset)
#
# Requires: ffmpeg (brew install ffmpeg), Xcode command line tools (swiftc), Apple Silicon.
set -euo pipefail
IN="$1"; OUT="$2"; shift 2
START=0; END=""; DURATION=576.58
while [ $# -gt 0 ]; do
  case "$1" in
    --start) START="$2"; shift 2;;
    --end) END="$2"; shift 2;;
    --duration) DURATION="$2"; shift 2;;
    *) echo "unknown option $1" >&2; exit 2;;
  esac
done
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ ! -x "$HERE/tlenc" ] || [ "$HERE/tlenc.swift" -nt "$HERE/tlenc" ]; then
  echo "building tlenc..."
  swiftc -O -framework AVFoundation -framework VideoToolbox -o "$HERE/tlenc" "$HERE/tlenc.swift"
fi

# 1. Trim, scale/crop to 4K 16:9, 10-bit HEVC intermediate at the source frame rate.
#    Frame rate is normalised to 24 fps so that x10 duplication gives 240 fps.
TRIM=(-ss "$START"); [ -n "$END" ] && TRIM+=(-to "$END")
echo "preparing 4K intermediate..."
ffmpeg -y -v error -stats "${TRIM[@]}" -i "$IN" -an \
  -vf "fps=24,scale=3840:2160:force_original_aspect_ratio=increase,crop=3840:2160,format=p010le" \
  -c:v hevc_videotoolbox -profile:v main10 -b:v 40M -tag:v hvc1 \
  -color_primaries bt709 -color_trc iec61966-2-1 -colorspace bt709 "$WORK/clip.mov"

# 2. Re-encode at 240 fps with HEVC temporal sub-layers, looped to the target duration.
CLIP_LEN=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$WORK/clip.mov")
LOOPS=$(python3 -c "import math; print(math.ceil($DURATION / $CLIP_LEN))")
echo "encoding $LOOPS loop(s) to ${DURATION}s with temporal layers (this runs at ~60 fps, be patient)..."
"$HERE/tlenc" "$WORK/clip.mov" "$OUT" 5 "$LOOPS" "$DURATION" 10 15
echo "done: $OUT"
