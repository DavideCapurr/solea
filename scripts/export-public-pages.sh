#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/AppStore/Public"
CONTACT_EMAIL=""
PRIVACY_URL=""
SUPPORT_URL=""

usage() {
  cat <<'USAGE'
Usage: scripts/export-public-pages.sh --contact-email <email> --privacy-url <url> --support-url <url> [--output-dir <dir>]

Exports static HTML pages for the public Privacy Policy and Support URLs used
by App Store Connect. The command requires real contact/URL values and refuses
to emit pages with known placeholders.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --contact-email)
      CONTACT_EMAIL="${2:-}"
      shift 2
      ;;
    --privacy-url)
      PRIVACY_URL="${2:-}"
      shift 2
      ;;
    --support-url)
      SUPPORT_URL="${2:-}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:-}"
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

[[ -n "$CONTACT_EMAIL" && -n "$PRIVACY_URL" && -n "$SUPPORT_URL" ]] || {
  usage >&2
  exit 2
}

python3 - "$ROOT_DIR/docs/PRIVACY_POLICY_DRAFT.md" "$ROOT_DIR/docs/SUPPORT_PAGE_DRAFT.md" "$OUTPUT_DIR" "$CONTACT_EMAIL" "$PRIVACY_URL" "$SUPPORT_URL" <<'PY'
from html import escape
from pathlib import Path
import re
import sys

privacy_path = Path(sys.argv[1])
support_path = Path(sys.argv[2])
output_dir = Path(sys.argv[3])
contact_email = sys.argv[4].strip()
privacy_url = sys.argv[5].strip()
support_url = sys.argv[6].strip()

email_pattern = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
url_pattern = re.compile(r"^https://[^\s]+$")
placeholder_pattern = re.compile(r"example\.com|TODO|TBD|PLACEHOLDER|Da completare|Inserire qui|pending", re.IGNORECASE)

def fail(message):
    raise SystemExit(f"error: {message}")

if not email_pattern.match(contact_email):
    fail("--contact-email must be a valid email address")
for label, value in {"--privacy-url": privacy_url, "--support-url": support_url}.items():
    if not url_pattern.match(value):
        fail(f"{label} must be a full https URL")
    if placeholder_pattern.search(value):
        fail(f"{label} contains a placeholder")

def prepare_privacy(markdown):
    return markdown.replace(
        "Da completare prima della pubblicazione: inserisci email o pagina di contatto del titolare dell'app.",
        f"Per domande sulla privacy o sulla gestione dei dati, scrivi a {contact_email}."
    )

def prepare_support(markdown):
    markdown = markdown.replace(
        "Da completare prima della pubblicazione: inserisci email o modulo di contatto\ndel titolare dell'app.",
        f"Per assistenza, scrivi a {contact_email}."
    )
    return markdown.replace(
        "Pubblica e collega qui anche la Privacy Policy definitiva di Solea.",
        f"Privacy Policy: {privacy_url}"
    )

def inline_links(text):
    text = escape(text)
    text = re.sub(r"(https://[^\s<]+)", r'<a href="\1">\1</a>', text)
    text = re.sub(
        re.escape(contact_email),
        f'<a href="mailto:{escape(contact_email)}">{escape(contact_email)}</a>',
        text,
    )
    return text

def markdown_to_html(markdown, page_title, canonical_url):
    body = []
    in_list = False
    for raw_line in markdown.splitlines():
        line = raw_line.rstrip()
        if not line:
            if in_list:
                body.append("</ul>")
                in_list = False
            continue
        if line.startswith("# "):
            if in_list:
                body.append("</ul>")
                in_list = False
            body.append(f"<h1>{inline_links(line[2:].strip())}</h1>")
        elif line.startswith("## "):
            if in_list:
                body.append("</ul>")
                in_list = False
            body.append(f"<h2>{inline_links(line[3:].strip())}</h2>")
        elif line.startswith("### "):
            if in_list:
                body.append("</ul>")
                in_list = False
            body.append(f"<h3>{inline_links(line[4:].strip())}</h3>")
        elif line.startswith("- "):
            if not in_list:
                body.append("<ul>")
                in_list = True
            body.append(f"<li>{inline_links(line[2:].strip())}</li>")
        else:
            if in_list:
                body.append("</ul>")
                in_list = False
            body.append(f"<p>{inline_links(line)}</p>")
    if in_list:
        body.append("</ul>")

    return f"""<!doctype html>
<html lang="it">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{escape(page_title)}</title>
  <link rel="canonical" href="{escape(canonical_url)}">
  <style>
    :root {{ color-scheme: light dark; }}
    body {{
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      line-height: 1.55;
      color: CanvasText;
      background: Canvas;
    }}
    main {{
      max-width: 760px;
      margin: 0 auto;
      padding: 48px 20px 72px;
    }}
    h1, h2, h3 {{ line-height: 1.2; }}
    h1 {{ font-size: 2rem; margin: 0 0 1.25rem; }}
    h2 {{ font-size: 1.25rem; margin-top: 2rem; }}
    h3 {{ font-size: 1.05rem; margin-top: 1.5rem; }}
    a {{ color: LinkText; }}
    li {{ margin: 0.35rem 0; }}
  </style>
</head>
<body>
<main>
{chr(10).join(body)}
</main>
</body>
</html>
"""

privacy_markdown = prepare_privacy(privacy_path.read_text(encoding="utf-8"))
support_markdown = prepare_support(support_path.read_text(encoding="utf-8"))

for label, markdown in {"privacy": privacy_markdown, "support": support_markdown}.items():
    if placeholder_pattern.search(markdown):
        fail(f"{label} page still contains a placeholder")

output_dir.mkdir(parents=True, exist_ok=True)
(output_dir / "privacy.html").write_text(markdown_to_html(privacy_markdown, "Solea Privacy Policy", privacy_url), encoding="utf-8")
(output_dir / "support.html").write_text(markdown_to_html(support_markdown, "Solea Support", support_url), encoding="utf-8")
print(f"Exported public pages to {output_dir}")
PY
