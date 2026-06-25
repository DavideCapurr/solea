#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPICON_DIR="${APPICON_DIR:-$ROOT_DIR/App/Resources/Assets.xcassets/AppIcon.appiconset}"
DEST_FILENAME="${DEST_FILENAME:-AppIcon-1024.png}"

usage() {
  cat <<'USAGE'
Usage: scripts/install-app-icon.sh <path-to-1024-png>

Validates and installs the final App Store icon into:
  App/Resources/Assets.xcassets/AppIcon.appiconset

Requirements:
  - PNG file
  - 1024x1024 pixels
  - no alpha channel

Set APPICON_DIR for tests or nonstandard asset catalogs.
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ "${1:-}" != "-h" && "${1:-}" != "--help" ]] || {
  usage
  exit 0
}

source_icon="${1:-}"
[[ -n "$source_icon" ]] || {
  usage >&2
  exit 2
}

[[ -f "$source_icon" ]] || fail "Icon file not found: $source_icon"
[[ "${source_icon##*.}" == "png" || "${source_icon##*.}" == "PNG" ]] || fail "AppIcon must be a PNG file"
[[ -d "$APPICON_DIR" ]] || fail "AppIcon asset catalog not found: $APPICON_DIR"
[[ -f "$APPICON_DIR/Contents.json" ]] || fail "Missing Contents.json in $APPICON_DIR"

width="$(sips -g pixelWidth "$source_icon" 2>/dev/null | awk '/pixelWidth/ { print $2 }')"
height="$(sips -g pixelHeight "$source_icon" 2>/dev/null | awk '/pixelHeight/ { print $2 }')"
alpha="$(sips -g hasAlpha "$source_icon" 2>/dev/null | awk '/hasAlpha/ { print $2 }')"

[[ "$width" == "1024" && "$height" == "1024" ]] || fail "AppIcon must be 1024x1024, found ${width:-?}x${height:-?}"
[[ "$alpha" == "no" ]] || fail "AppIcon must not contain alpha"

destination="$APPICON_DIR/$DEST_FILENAME"
cp "$source_icon" "$destination"

python3 - "$APPICON_DIR/Contents.json" "$DEST_FILENAME" <<'PY'
import json
from pathlib import Path
import sys

path = Path(sys.argv[1])
filename = sys.argv[2]
contents = json.loads(path.read_text(encoding="utf-8"))
images = contents.setdefault("images", [])
if not images:
    images.append({"idiom": "universal", "platform": "ios", "size": "1024x1024"})

primary = images[0]
primary["idiom"] = "universal"
primary["platform"] = "ios"
primary["size"] = "1024x1024"
primary["filename"] = filename

contents.setdefault("info", {"author": "xcode", "version": 1})
path.write_text(json.dumps(contents, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY

echo "Installed AppIcon: $destination"
