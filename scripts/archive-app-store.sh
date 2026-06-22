#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/Solea.xcodeproj"
EXPORT_OPTIONS="$ROOT_DIR/AppStore/ExportOptions-AppStoreConnect.plist"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE_PATH="$ROOT_DIR/AppStore/Archives/Solea-$TIMESTAMP.xcarchive"
EXPORT_PATH=""
TEAM_ID=""
ALLOW_PROVISIONING_UPDATES=0
SKIP_PREPARE=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage: scripts/archive-app-store.sh [options]

Builds a signed Release archive for App Store Connect and validates it with the
local final gate.

Options:
  --archive-path <path>          Override the .xcarchive destination.
  --export-path <path>           Run xcodebuild -exportArchive after validation.
  --team-id <team-id>            Pass DEVELOPMENT_TEAM to xcodebuild.
  --allow-provisioning-updates   Let xcodebuild update/download signing assets.
  --skip-prepare                 Skip prepare-app-store-package.sh.
  --dry-run                      Print commands without executing signing/build.

The default archive path is AppStore/Archives/Solea-<timestamp>.xcarchive.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive-path)
      ARCHIVE_PATH="${2:-}"
      [[ -n "$ARCHIVE_PATH" ]] || {
        echo "error: --archive-path requires a path" >&2
        exit 2
      }
      shift 2
      ;;
    --export-path)
      EXPORT_PATH="${2:-}"
      [[ -n "$EXPORT_PATH" ]] || {
        echo "error: --export-path requires a path" >&2
        exit 2
      }
      shift 2
      ;;
    --team-id)
      TEAM_ID="${2:-}"
      [[ -n "$TEAM_ID" ]] || {
        echo "error: --team-id requires a value" >&2
        exit 2
      }
      shift 2
      ;;
    --allow-provisioning-updates)
      ALLOW_PROVISIONING_UPDATES=1
      shift
      ;;
    --skip-prepare)
      SKIP_PREPARE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
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

case "$ARCHIVE_PATH" in
  /*) ;;
  *) ARCHIVE_PATH="$ROOT_DIR/$ARCHIVE_PATH" ;;
esac
if [[ -n "$EXPORT_PATH" ]]; then
  case "$EXPORT_PATH" in
    /*) ;;
    *) EXPORT_PATH="$ROOT_DIR/$EXPORT_PATH" ;;
  esac
fi

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

archive_dir="$(dirname "$ARCHIVE_PATH")"
export_dir=""
if [[ -n "$EXPORT_PATH" ]]; then
  export_dir="$(dirname "$EXPORT_PATH")"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "$archive_dir"
  [[ -z "$export_dir" ]] || mkdir -p "$export_dir"
fi

if [[ "$SKIP_PREPARE" -eq 0 ]]; then
  run scripts/prepare-app-store-package.sh --include-preflight
fi

archive_cmd=(
  xcodebuild
  -project "$PROJECT_PATH"
  -scheme Solea
  -configuration Release
  -destination "generic/platform=iOS"
  -archivePath "$ARCHIVE_PATH"
)
if [[ "$ALLOW_PROVISIONING_UPDATES" -eq 1 ]]; then
  archive_cmd+=(-allowProvisioningUpdates)
fi
if [[ -n "$TEAM_ID" ]]; then
  archive_cmd+=("DEVELOPMENT_TEAM=$TEAM_ID")
fi
archive_cmd+=(archive)

run "${archive_cmd[@]}"
run scripts/app-store-final-check.sh --archive "$ARCHIVE_PATH"

if [[ -n "$EXPORT_PATH" ]]; then
  export_cmd=(
    xcodebuild
    -exportArchive
    -archivePath "$ARCHIVE_PATH"
    -exportPath "$EXPORT_PATH"
    -exportOptionsPlist "$EXPORT_OPTIONS"
  )
  if [[ "$ALLOW_PROVISIONING_UPDATES" -eq 1 ]]; then
    export_cmd+=(-allowProvisioningUpdates)
  fi
  run "${export_cmd[@]}"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  echo "App Store archive ready: $ARCHIVE_PATH"
fi
