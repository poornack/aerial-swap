#!/bin/zsh
# Print id, name and download state of every Aerial in Apple's manifest.
A="$HOME/Library/Application Support/com.apple.wallpaper/aerials"
python3 - "$A" <<'PY'
import json, os, subprocess, sys
A = sys.argv[1]
d = json.load(open(f"{A}/manifest/entries.json"))
loc = f"{A}/manifest/TVIdleScreenStrings.bundle/Contents/Resources/Localizable.nocache.loctable"
names = json.loads(subprocess.check_output(["plutil", "-convert", "json", "-o", "-", loc]))
en = names.get("en") or next(iter(names.values()))
for a in sorted(d["assets"], key=lambda a: a["accessibilityLabel"]):
    have = os.path.exists(f"{A}/videos/{a['id']}.mov")
    print(f"{'*' if have else ' '} {a['id']}  {a['accessibilityLabel']:<14} {en.get(a['localizedNameKey'], '')}")
print("\n* = downloaded (usable as a swap target)")
PY
