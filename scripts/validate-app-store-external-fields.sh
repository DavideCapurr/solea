#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIELDS="$ROOT_DIR/docs/APP_STORE_EXTERNAL_FIELDS.md"
PROJECT_YML="$ROOT_DIR/project.yml"
STRICT=0
SELF_TEST=0

for arg in "$@"; do
  case "$arg" in
    --strict)
      STRICT=1
      ;;
    --self-test)
      SELF_TEST=1
      ;;
    -h|--help)
      cat <<'USAGE'
Usage: scripts/validate-app-store-external-fields.sh [--strict] [--self-test]

Checks App Store Connect fields that are external to the codebase, such as
privacy/support URLs, App Review contact details, and Apple portal approvals.
Without --strict, missing values are warnings. With --strict, they fail.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

python3 - "$FIELDS" "$PROJECT_YML" "$STRICT" "$SELF_TEST" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
project_yml = Path(sys.argv[2])
strict = sys.argv[3] == "1"
testing = sys.argv[4] == "1"
text = path.read_text(encoding="utf-8")

placeholder = re.compile(
    r"example\.com|TODO|TBD|PLACEHOLDER|Da completare|Inserire qui|pending",
    re.IGNORECASE,
)

checks = []
url_pattern = re.compile(r"^https?://[^\s]+$")
email_pattern = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

def field(label):
    match = re.search(rf"^- {re.escape(label)}:\s*(.+)$", text, flags=re.MULTILINE)
    if not match:
        checks.append(f"missing field: {label}")
        return ""
    return match.group(1).strip()

def normalize_value(value):
    value = value.strip()
    if value.startswith("<") and value.endswith(">"):
        return value[1:-1].strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1].strip()
    return value

def has_placeholder(value):
    normalized = normalize_value(value)
    if placeholder.search(normalized):
        return True
    if value.startswith("<") and value.endswith(">") and not re.match(r"^https?://", normalized, re.IGNORECASE):
        return True
    return False

def require_filled(label):
    value = field(label)
    if not value or has_placeholder(value):
        checks.append(f"{label} is not finalized")
    return value

def require_url(label):
    value = require_filled(label)
    normalized = normalize_value(value)
    if value and not has_placeholder(value) and not url_pattern.match(normalized):
        checks.append(f"{label} must be a full http(s) URL")
    if value and not has_placeholder(value) and url_pattern.match(normalized):
        return normalized
    return ""

def require_email(label):
    value = require_filled(label)
    normalized = normalize_value(value)
    if value and not has_placeholder(value) and not email_pattern.match(normalized):
        checks.append(f"{label} must look like an email address")

def require_phone(label):
    value = require_filled(label)
    normalized = normalize_value(value)
    digits = re.sub(r"\D", "", normalized)
    if value and not has_placeholder(value) and len(digits) < 6:
        checks.append(f"{label} must include a reachable phone number")

def project_value(key):
    if not project_yml.exists():
        return ""
    match = re.search(rf"^\s*{re.escape(key)}:\s*(.*)$", project_yml.read_text(encoding="utf-8"), flags=re.MULTILINE)
    if not match:
        return ""
    return normalize_value(match.group(1).strip())

def require_project_url(key, label, expected):
    if not expected:
        return
    actual = project_value(key)
    if not actual or has_placeholder(actual):
        checks.append(f"{key} in project.yml must be finalized for the in-app {label} link")
        return
    if not url_pattern.match(actual):
        checks.append(f"{key} in project.yml must be a full http(s) URL")
        return
    if actual != expected:
        checks.append(f"{key} in project.yml must match {label} ({expected})")

if testing:
    cases = {
        "<https://privacy.example.org/solea>": (False, "https://privacy.example.org/solea"),
        "https://privacy.example.org/solea": (False, "https://privacy.example.org/solea"),
        '"https://privacy.example.org/solea"': (False, "https://privacy.example.org/solea"),
        "<email>": (True, "email"),
        "<nome e cognome>": (True, "nome e cognome"),
        "pending": (True, "pending"),
        "https://example.com/solea/privacy": (True, "https://example.com/solea/privacy"),
    }
    for raw, (expected_placeholder, expected_normalized) in cases.items():
        actual_placeholder = has_placeholder(raw)
        actual_normalized = normalize_value(raw)
        if actual_placeholder != expected_placeholder:
            raise SystemExit(f"self-test failed for placeholder detection: {raw}")
        if actual_normalized != expected_normalized:
            raise SystemExit(f"self-test failed for normalization: {raw}")
    if not url_pattern.match(normalize_value("<https://privacy.example.org/solea>")):
        raise SystemExit("self-test failed for Markdown autolink URL validation")
    if not email_pattern.match("support@privacy.example.org"):
        raise SystemExit("self-test failed for email validation")
    if len(re.sub(r"\D", "", "+39 010 1234567")) < 6:
        raise SystemExit("self-test failed for phone validation")
    print("External fields validator self-test passed.")
    raise SystemExit(0)

privacy_policy_url = require_url("Privacy Policy URL")
support_url = require_url("Support URL")
require_filled("Contact name")
require_email("Contact email")
require_phone("Contact phone")
require_filled("Copyright")
require_project_url("SoleaPrivacyPolicyURL", "Privacy Policy URL", privacy_policy_url)
require_project_url("SoleaSupportURL", "Support URL", support_url)

sku = require_filled("SKU")
sku_normalized = normalize_value(sku)
if sku and not has_placeholder(sku) and not re.match(r"^[A-Za-z0-9][A-Za-z0-9._-]*$", sku_normalized):
    checks.append("SKU can contain letters, numbers, periods, hyphens, and underscores, and must not start with punctuation")

sign_in = require_filled("Sign-in required")
if sign_in and normalize_value(sign_in).lower() not in {"yes", "no"}:
    checks.append("Sign-in required must be Yes or No")

critical_alerts = field("Critical Alerts approval")
if critical_alerts.lower() != "approved":
    checks.append("Critical Alerts approval is not marked approved")

game_center = field("Game Center components")
if game_center.lower() != "created":
    checks.append("Game Center components are not marked created")

if checks:
    prefix = "error" if strict else "warning"
    for item in checks:
        print(f"{prefix}: App Store external field: {item}", file=sys.stderr)
    if strict:
        raise SystemExit(1)
else:
    print("App Store external fields passed.")
PY
