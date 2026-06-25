#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METADATA="$ROOT_DIR/docs/APP_STORE_METADATA.md"

python3 - "$METADATA" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

def fail(message):
    raise SystemExit(f"error: {message}")

def field(label):
    pattern = re.compile(rf"^- {re.escape(label)}:\s*(.+)$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        fail(f"Missing metadata field: {label}")
    return match.group(1).strip()

def section(title):
    heading = re.search(rf"^##+\s+{re.escape(title)}\s*$", text, flags=re.MULTILINE)
    if not heading:
        fail(f"Missing metadata section: {title}")
    start = text.find("\n", heading.start())
    if start == -1:
        return ""
    next_heading = re.search(r"\n#{2,3} ", text[start + 1:])
    end = len(text) if not next_heading else start + 1 + next_heading.start()
    return text[start:end].strip()

def require_chars(label, value, minimum=None, maximum=None):
    count = len(value)
    if minimum is not None and count < minimum:
        fail(f"{label} is {count} characters, minimum is {minimum}")
    if maximum is not None and count > maximum:
        fail(f"{label} is {count} characters, maximum is {maximum}")

def require_bytes(label, value, maximum):
    count = len(value.encode("utf-8"))
    if count > maximum:
        fail(f"{label} is {count} bytes, maximum is {maximum}")

name = field("Nome app")
subtitle = field("Sottotitolo")
keywords = section("Keywords").replace("\n", "").strip()
promotional = section("Promotional text")
description = section("Description")
review_notes = section("Review notes")

require_chars("Nome app", name, minimum=2, maximum=30)
require_chars("Sottotitolo", subtitle, maximum=30)
require_chars("Promotional text", promotional, maximum=170)
require_chars("Description", description, maximum=4000)
require_bytes("Keywords", keywords, maximum=100)
require_bytes("Review notes", review_notes, maximum=4000)

if re.search(r"<[^>]+>", description):
    fail("Description must be plain text, not HTML")

keyword_items = [item.strip() for item in keywords.split(",") if item.strip()]
if not keyword_items:
    fail("Keywords section is empty")
if any(item != item.strip() for item in keywords.split(",")):
    fail("Keywords must not contain leading or trailing spaces around commas")

seen = set()
for keyword in keyword_items:
    normalized = keyword.casefold()
    if len(keyword) <= 2:
        fail(f"Keyword '{keyword}' must be longer than two characters")
    if normalized in seen:
        fail(f"Duplicate keyword: {keyword}")
    seen.add(normalized)
    if normalized == name.casefold():
        fail(f"Keyword duplicates app name: {keyword}")

combined_public_copy = "\n".join([subtitle, promotional, description, review_notes])
risky_patterns = [
    r"\bsenza scott",
    r"\bwithout burning\b",
    r"\btempo sicuro\b",
    r"\bsafe time\b",
    r"\bgarant",
    r"\bpreven",
]
for pattern in risky_patterns:
    if re.search(pattern, combined_public_copy, flags=re.IGNORECASE):
        fail(f"Review-risk wording found in metadata: {pattern}")

print("App Store metadata draft passed.")
PY
