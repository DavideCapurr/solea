#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE_PATH=""
INCLUDE_PREFLIGHT=0
FAILURES=0
WARNINGS=0

usage() {
  cat <<'USAGE'
Usage: scripts/app-store-readiness-report.sh [--archive <path-to-signed-xcarchive>] [--include-preflight]

Prints a compact App Store submission readiness report without stopping at the
first blocker. By default it runs fast local checks only. Use --include-preflight
to also run the Release build/archive preflight with the icon check skipped,
because AppIcon is reported separately.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive)
      ARCHIVE_PATH="${2:-}"
      [[ -n "$ARCHIVE_PATH" ]] || {
        echo "error: --archive requires a path" >&2
        exit 2
      }
      shift 2
      ;;
    --include-preflight)
      INCLUDE_PREFLIGHT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$ROOT_DIR"

ok() {
  printf 'OK     %s\n' "$*"
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  printf 'WARN   %s\n' "$*"
}

block() {
  FAILURES=$((FAILURES + 1))
  printf 'BLOCK  %s\n' "$*"
}

capture_check() {
  local label="$1"
  shift
  local output
  if output="$("$@" 2>&1)"; then
    ok "$label"
  else
    block "$label"
    if [[ -n "$output" ]]; then
      while IFS= read -r line; do
        [[ -n "$line" ]] && printf '       %s\n' "$line"
      done <<<"$output"
    fi
  fi
}

check_app_icon() {
  python3 - <<'PY'
import json
from pathlib import Path
import subprocess
import sys

path = Path("App/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json")
if not path.exists():
    raise SystemExit("missing AppIcon Contents.json")
contents = json.loads(path.read_text(encoding="utf-8"))
filenames = [item.get("filename") for item in contents.get("images", []) if item.get("filename")]
if not filenames:
    raise SystemExit("AppIcon has no image filename; run scripts/install-app-icon.sh <1024-png>")

for filename in filenames:
    icon = path.parent / filename
    if not icon.exists():
        raise SystemExit(f"AppIcon file is missing: {icon}")
    if icon.suffix.lower() != ".png":
        raise SystemExit(f"AppIcon must be PNG: {icon}")
    width = subprocess.check_output(["sips", "-g", "pixelWidth", str(icon)], stderr=subprocess.DEVNULL, text=True)
    height = subprocess.check_output(["sips", "-g", "pixelHeight", str(icon)], stderr=subprocess.DEVNULL, text=True)
    alpha = subprocess.check_output(["sips", "-g", "hasAlpha", str(icon)], stderr=subprocess.DEVNULL, text=True)
    width_value = next((line.split()[-1] for line in width.splitlines() if "pixelWidth" in line), "")
    height_value = next((line.split()[-1] for line in height.splitlines() if "pixelHeight" in line), "")
    alpha_value = next((line.split()[-1] for line in alpha.splitlines() if "hasAlpha" in line), "")
    if (width_value, height_value) != ("1024", "1024"):
        raise SystemExit(f"{icon} must be 1024x1024, found {width_value}x{height_value}")
    if alpha_value != "no":
        raise SystemExit(f"{icon} must not contain alpha")
PY
}

printf 'Solea App Store readiness report\n'
printf '================================\n'

capture_check "App Store metadata limits and review-risk wording" scripts/validate-app-store-metadata.sh
capture_check "Game Center IDs match code and App Store setup docs" scripts/validate-game-center-config.sh
capture_check "App Store screenshots are present and valid" scripts/validate-app-store-screenshots.sh --required
capture_check "AppIcon is installed and valid" check_app_icon
capture_check "External App Store Connect fields are finalized" scripts/validate-app-store-external-fields.sh --strict

if [[ "$INCLUDE_PREFLIGHT" -eq 1 ]]; then
  capture_check "Release build, bundle metadata, privacy manifests, and unsigned archive preflight" scripts/app-store-preflight.sh --skip-icon-check
else
  warn "Release preflight not run in this report; use --include-preflight or scripts/app-store-preflight.sh"
fi

if [[ -n "$ARCHIVE_PATH" ]]; then
  capture_check "Signed archive is valid for App Store upload" scripts/validate-signed-archive.sh "$ARCHIVE_PATH"
else
  warn "No signed archive provided; validate the final Xcode archive with scripts/validate-signed-archive.sh <path>.xcarchive"
fi

printf '\nSummary: %d blocker(s), %d warning(s)\n' "$FAILURES" "$WARNINGS"
if [[ "$FAILURES" -gt 0 ]]; then
  exit 1
fi
