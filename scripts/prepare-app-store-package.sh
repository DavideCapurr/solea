#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIELDS="$ROOT_DIR/docs/APP_STORE_EXTERNAL_FIELDS.md"
INCLUDE_PREFLIGHT=0
ARCHIVE_PATH=""

usage() {
  cat <<'USAGE'
Usage: scripts/prepare-app-store-package.sh [--include-preflight] [--archive <path-to-signed-xcarchive>]

Runs the final repository-side preparation steps after external App Store
Connect fields are filled:
  - sync Privacy/Support URLs into project.yml
  - regenerate the Xcode project and plists
  - export App Store metadata text files
  - export public Privacy/Support HTML pages
  - run strict metadata/external-field/screenshot checks
  - print the readiness report

This command still requires the final AppIcon and any Apple portal approvals.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include-preflight)
      INCLUDE_PREFLIGHT=1
      shift
      ;;
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

step() {
  echo "==> $*"
}

step "Syncing Privacy/Support URLs into project.yml"
scripts/sync-app-store-urls.sh

step "Regenerating Xcode project"
xcodegen generate >/dev/null

step "Exporting App Store metadata"
scripts/export-app-store-metadata.sh

step "Exporting public Privacy/Support pages"
public_fields_output="$(python3 - "$FIELDS" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
placeholder = re.compile(r"example\.com|TODO|TBD|PLACEHOLDER|Da completare|Inserire qui|pending", re.IGNORECASE)
url_pattern = re.compile(r"^https://[^\s]+$")
email_pattern = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

def fail(message):
    raise SystemExit(f"error: {message}")

def normalize(value):
    value = value.strip()
    if value.startswith("<") and value.endswith(">"):
        value = value[1:-1].strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        value = value[1:-1].strip()
    return value

def field(label):
    match = re.search(rf"^- {re.escape(label)}:\s*(.+)$", text, flags=re.MULTILINE)
    if not match:
        fail(f"missing field: {label}")
    value = normalize(match.group(1))
    if placeholder.search(value):
        fail(f"{label} contains a placeholder")
    return value

privacy_url = field("Privacy Policy URL")
support_url = field("Support URL")
contact_email = field("Contact email")

for label, value in {"Privacy Policy URL": privacy_url, "Support URL": support_url}.items():
    if not url_pattern.match(value):
        fail(f"{label} must be a full https URL")
if not email_pattern.match(contact_email):
    fail("Contact email must look like an email address")

print(contact_email)
print(privacy_url)
print(support_url)
PY
)"
contact_email="$(printf '%s\n' "$public_fields_output" | sed -n '1p')"
privacy_url="$(printf '%s\n' "$public_fields_output" | sed -n '2p')"
support_url="$(printf '%s\n' "$public_fields_output" | sed -n '3p')"

[[ -n "$contact_email" && -n "$privacy_url" && -n "$support_url" ]] || {
  echo "error: could not read contact email, privacy URL, and support URL from $FIELDS" >&2
  exit 1
}

scripts/export-public-pages.sh \
  --contact-email "$contact_email" \
  --privacy-url "$privacy_url" \
  --support-url "$support_url"

step "Running strict validators"
scripts/validate-app-store-metadata.sh
scripts/validate-game-center-config.sh
scripts/validate-app-store-external-fields.sh --strict
scripts/validate-app-store-screenshots.sh --required

step "Running readiness report"
readiness_args=()
if [[ "$INCLUDE_PREFLIGHT" -eq 1 ]]; then
  readiness_args+=(--include-preflight)
fi
if [[ -n "$ARCHIVE_PATH" ]]; then
  readiness_args+=(--archive "$ARCHIVE_PATH")
fi
scripts/app-store-readiness-report.sh "${readiness_args[@]}"
