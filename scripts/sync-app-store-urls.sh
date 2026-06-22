#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIELDS="$ROOT_DIR/docs/APP_STORE_EXTERNAL_FIELDS.md"
PROJECT_YML="$ROOT_DIR/project.yml"
SELF_TEST=0

usage() {
  cat <<'USAGE'
Usage: scripts/sync-app-store-urls.sh [--fields <path>] [--project <path>] [--self-test]

Reads Privacy Policy URL and Support URL from docs/APP_STORE_EXTERNAL_FIELDS.md
and writes them to project.yml as SoleaPrivacyPolicyURL and SoleaSupportURL.
The command refuses placeholder/example URLs.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fields)
      FIELDS="${2:-}"
      shift 2
      ;;
    --project)
      PROJECT_YML="${2:-}"
      shift 2
      ;;
    --self-test)
      SELF_TEST=1
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

if [[ "$SELF_TEST" -eq 1 ]]; then
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/solea-url-sync.XXXXXX")"
  trap 'rm -rf "$tmp_dir"' EXIT
  FIELDS="$tmp_dir/fields.md"
  PROJECT_YML="$tmp_dir/project.yml"
  cat >"$FIELDS" <<'EOF'
# Fields

- Privacy Policy URL: <https://solea.app/privacy>
- Support URL: https://solea.app/support
EOF
  cat >"$PROJECT_YML" <<'EOF'
targets:
  Solea:
    info:
      properties:
        SoleaPrivacyPolicyURL: ""
        SoleaSupportURL: ""
EOF
fi

python3 - "$FIELDS" "$PROJECT_YML" "$SELF_TEST" <<'PY'
from pathlib import Path
import re
import sys

fields_path = Path(sys.argv[1])
project_path = Path(sys.argv[2])
self_test = sys.argv[3] == "1"

placeholder = re.compile(r"example\.com|TODO|TBD|PLACEHOLDER|Da completare|Inserire qui|pending", re.IGNORECASE)
url_pattern = re.compile(r"^https://[^\s]+$")

def fail(message):
    raise SystemExit(f"error: {message}")

def normalize(value):
    value = value.strip()
    if value.startswith("<") and value.endswith(">"):
        value = value[1:-1].strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        value = value[1:-1].strip()
    return value

def field(text, label):
    match = re.search(rf"^- {re.escape(label)}:\s*(.+)$", text, flags=re.MULTILINE)
    if not match:
        fail(f"missing field: {label}")
    value = normalize(match.group(1))
    if placeholder.search(value):
        fail(f"{label} contains a placeholder")
    if not url_pattern.match(value):
        fail(f"{label} must be a full https URL")
    return value

def replace_yaml_value(text, key, value):
    pattern = re.compile(rf"^(\s*{re.escape(key)}:\s*).*$", flags=re.MULTILINE)
    replacement = rf'\1"{value}"'
    updated, count = pattern.subn(replacement, text, count=1)
    if count != 1:
        fail(f"missing project.yml key: {key}")
    return updated

fields = fields_path.read_text(encoding="utf-8")
project = project_path.read_text(encoding="utf-8")
privacy_url = field(fields, "Privacy Policy URL")
support_url = field(fields, "Support URL")

project = replace_yaml_value(project, "SoleaPrivacyPolicyURL", privacy_url)
project = replace_yaml_value(project, "SoleaSupportURL", support_url)
project_path.write_text(project, encoding="utf-8")

if self_test:
    result = project_path.read_text(encoding="utf-8")
    if 'SoleaPrivacyPolicyURL: "https://solea.app/privacy"' not in result:
        fail("self-test failed for Privacy Policy URL")
    if 'SoleaSupportURL: "https://solea.app/support"' not in result:
        fail("self-test failed for Support URL")
    print("App Store URL sync self-test passed.")
else:
    print(f"Synced Privacy/Support URLs into {project_path}")
PY
