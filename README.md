# aerial-swap

Use any video as a native macOS Aerial screen saver, by replacing one of Apple's
downloaded Aerial assets with a file encoded the way the Aerials engine expects.

Tested on macOS 26 (Tahoe), Apple Silicon. No sudo, no third-party screen saver.

## Why a plain re-encode is not enough

Apple's Aerials engine (`WallpaperAerialsExtension`) does not use `AVPlayer`. It
reads samples itself and, when you unlock the Mac, *ramps* playback down to a still
frame by stepping through the video's **HEVC temporal sub-layers** (`tscl` / `tsas`
sample groups, plus the `sdtp` dependency table). A normal ffmpeg HEVC encode has
none of that, so the ramp fails with the engine's internal `noTemporalInfo` error
and the player is left stuck. Symptom: the video plays on the first lock, pauses on
unlock, and never resumes on the next lock.

Apple's own assets are 4K, 10-bit HEVC, 240 fps, with 5 temporal layers. The
Apple Silicon hardware encoder can produce temporal layers when you set both
`NumberOfTemporalLayers` and `kVTCompressionPropertyKey_BaseLayerFrameRate`; at 4K it
yields 3 layers, which is enough for the ramp to work. `AVAssetWriter` then writes
the `tscl`/`tsas` groups from the encoder's per-sample attachments.

## Usage

```bash
# 1. In System Settings > Screen Saver, pick an Aerial (e.g. "San Francisco Skyline")
#    and let it download. Find its id:
tools/list-aerials.sh

# 2. Build the replacement (trim to 3s..118.8s, loop to Apple's 576.58 s length):
tools/make-aerial.sh ~/Downloads/video.webm /tmp/out.mov --start 3 --end 118.791

# 3. Install it over the chosen asset and restart the engine:
tools/install-aerial.sh /tmp/out.mov 85CE77BF-3413-4A7B-9B0F-732E96229A73

# 4. Optional: re-apply automatically after macOS updates restore the original:
launchd/install-launchagent.sh
```

The original asset is backed up to `~/Library/Application Support/AerialBackup/`.
Copy it back over the file in `~/Library/Application Support/com.apple.wallpaper/aerials/videos/`
to undo.

## Files

| Path | Purpose |
| --- | --- |
| `tools/tlenc.swift` | Hardware HEVC encoder with temporal sub-layers, 240 fps, frame duplication and looping |
| `tools/make-aerial.sh` | ffmpeg prep (trim, 4K crop, 24 fps) then `tlenc` |
| `tools/install-aerial.sh` | Backs up and replaces the Aerial asset, restarts the engine |
| `tools/list-aerials.sh` | Lists Aerial ids and names from Apple's manifest |
| `launchd/reapply.sh` | Restores the swap if Apple's original comes back |
| `app/build-app.sh`, `app/main.swift`, `app/make-icon.swift` | Wrap `reapply.sh` in a background-only `Aerial Swap.app` with a generated icon, so Login Items shows a real name instead of `zsh` |
| `launchd/com.poorna.aerialswap.plist` | LaunchAgent, embedded in the app and registered via `SMAppService` (runs at login and hourly) |

## Notes

- The thumbnail and name in System Settings stay Apple's; they come from the signed manifest.
- Encoding runs at roughly 60 fps at 4K, so a 576 s file takes about 40 minutes.
- Output is 16:9. Sources with other aspect ratios are cropped to fill.
