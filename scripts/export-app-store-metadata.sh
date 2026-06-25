#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METADATA="$ROOT_DIR/docs/APP_STORE_METADATA.md"
ANSWERS="$ROOT_DIR/docs/APP_STORE_CONNECT_ANSWERS.md"
OUTPUT_DIR="$ROOT_DIR/AppStore/Metadata/it"

mkdir -p "$OUTPUT_DIR"

python3 - "$METADATA" "$ANSWERS" "$OUTPUT_DIR" <<'PY'
from pathlib import Path
import re
import sys

metadata_path = Path(sys.argv[1])
answers_path = Path(sys.argv[2])
output_dir = Path(sys.argv[3])
metadata = metadata_path.read_text(encoding="utf-8")
answers = answers_path.read_text(encoding="utf-8")

def fail(message):
    raise SystemExit(f"error: {message}")

def field(label):
    match = re.search(rf"^- {re.escape(label)}:\s*(.+)$", metadata, flags=re.MULTILINE)
    if not match:
        fail(f"Missing metadata field: {label}")
    return match.group(1).strip()

def section(text, title):
    heading = re.search(rf"^##+\s+{re.escape(title)}\s*$", text, flags=re.MULTILINE)
    if not heading:
        fail(f"Missing section: {title}")
    start = text.find("\n", heading.start())
    if start == -1:
        return ""
    next_heading = re.search(r"\n#{2,3} ", text[start + 1:])
    end = len(text) if not next_heading else start + 1 + next_heading.start()
    return text[start:end].strip()

exports = {
    "name.txt": field("Nome app"),
    "subtitle.txt": field("Sottotitolo"),
    "promotional_text.txt": section(metadata, "Promotional text"),
    "description.txt": section(metadata, "Description"),
    "keywords.txt": section(metadata, "Keywords").replace("\n", "").strip(),
    "review_notes.txt": section(metadata, "Review notes").replace("`", ""),
    "export_compliance.md": section(answers, "Export Compliance"),
    "app_privacy.md": section(answers, "App Privacy"),
    "age_rating.md": section(answers, "Age Rating"),
    "critical_alerts.md": section(answers, "Critical Alerts"),
}

for filename, value in exports.items():
    (output_dir / filename).write_text(value.rstrip() + "\n", encoding="utf-8")

print(f"Exported App Store metadata to {output_dir}")
PY
