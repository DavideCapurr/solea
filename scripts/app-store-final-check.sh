#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE_PATH=""

usage() {
  cat <<'USAGE'
Usage: scripts/app-store-final-check.sh [--archive <path-to-signed-xcarchive>]

Runs the strict pre-submission gate:
  - App Store metadata limits and review-risk wording
  - external App Store Connect fields finalized
  - screenshots present and valid
  - AppIcon present, 1024x1024, no alpha
  - Release device build and unsigned archive metadata
  - optional signed archive validation when --archive is provided

This command is expected to fail until AppIcon, external fields, Apple portal
approvals, and signing are complete.
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

scripts/validate-app-store-metadata.sh
scripts/validate-game-center-config.sh
scripts/validate-app-store-external-fields.sh --strict
scripts/app-store-preflight.sh

if [[ -n "$ARCHIVE_PATH" ]]; then
  scripts/validate-signed-archive.sh "$ARCHIVE_PATH"
else
  echo "warning: no signed archive provided; run scripts/validate-signed-archive.sh <path>.xcarchive after Xcode archive"
fi

echo "Final App Store submission check passed."
