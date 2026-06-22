#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCREENSHOT_DIR="$ROOT_DIR/AppStore/Screenshots"
REQUIRED=0

for arg in "$@"; do
  case "$arg" in
    --required)
      REQUIRED=1
      ;;
    -h|--help)
      cat <<'USAGE'
Usage: scripts/validate-app-store-screenshots.sh [--required]

Validates App Store screenshot folders and dimensions under AppStore/Screenshots.
Without --required, missing screenshot sets are warnings. With --required, missing
iPhone 6.9" and Apple Watch screenshot sets fail the command.

Expected folders:
  AppStore/Screenshots/iPhone-6.9
  AppStore/Screenshots/Apple-Watch
  AppStore/Screenshots/iPhone-6.3    optional
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

python3 - "$SCREENSHOT_DIR" "$REQUIRED" <<'PY'
from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1])
required = sys.argv[2] == "1"

sets = {
    "iPhone-6.9": {
        "required": True,
        "dimensions": {
            (1320, 2868), (2868, 1320),
            (1290, 2796), (2796, 1290),
            (1260, 2736), (2736, 1260),
        },
    },
    "iPhone-6.3": {
        "required": False,
        "dimensions": {
            (1179, 2556), (2556, 1179),
            (1206, 2622), (2622, 1206),
        },
    },
    "Apple-Watch": {
        "required": True,
        "dimensions": {
            (422, 514),
            (410, 502),
            (416, 496),
            (396, 484),
            (368, 448),
            (312, 390),
        },
    },
}

extensions = {".png", ".jpg", ".jpeg"}

def warn(message):
    print(f"warning: {message}", file=sys.stderr)

def fail(message):
    raise SystemExit(message)

def image_size(path):
    try:
        output = subprocess.check_output(
            ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except Exception as error:
        fail(f"Could not inspect screenshot {path}: {error}")

    width = height = None
    for line in output.splitlines():
        parts = line.strip().split()
        if len(parts) == 2 and parts[0].rstrip(":") == "pixelWidth":
            width = int(parts[1])
        if len(parts) == 2 and parts[0].rstrip(":") == "pixelHeight":
            height = int(parts[1])
    if width is None or height is None:
        fail(f"Could not read dimensions for screenshot {path}")
    return width, height

def images_in(folder):
    if not folder.exists():
        return []
    return sorted(
        item for item in folder.iterdir()
        if item.is_file() and not item.name.startswith(".")
    )

if not root.exists():
    if required:
        fail(f"Missing screenshot directory: {root}")
    warn(f"missing screenshot directory: {root}")
    raise SystemExit(0)

errors = []
for name, spec in sets.items():
    folder = root / name
    files = images_in(folder)
    if not files:
        message = f"missing App Store screenshots in {folder}"
        if required and spec["required"]:
            errors.append(message)
        elif spec["required"]:
            warn(message)
        continue

    if len(files) > 10:
        errors.append(f"{folder} has {len(files)} screenshots; App Store Connect accepts 1 to 10")

    for file in files:
        if file.suffix.lower() not in extensions:
            errors.append(f"{file} must be .png, .jpg, or .jpeg")
            continue
        size = image_size(file)
        if size not in spec["dimensions"]:
            allowed = ", ".join(f"{w}x{h}" for w, h in sorted(spec["dimensions"]))
            errors.append(f"{file} is {size[0]}x{size[1]}, expected one of: {allowed}")

known = set(sets)
for child in sorted(item for item in root.iterdir() if item.is_dir() and not item.name.startswith(".")):
    if child.name not in known:
        warn(f"unknown screenshot folder ignored: {child}")

if errors:
    fail("\n".join(errors))
PY
