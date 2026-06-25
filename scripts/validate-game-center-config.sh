#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT_DIR" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
game_center = (root / "App/Services/GameCenterService.swift").read_text(encoding="utf-8")
badges = (root / "SoleaCore/Sources/SoleaCore/Badge.swift").read_text(encoding="utf-8")
setup = (root / "docs/GAME_CENTER_SETUP.md").read_text(encoding="utf-8")
submission = (root / "docs/APP_STORE_SUBMISSION.md").read_text(encoding="utf-8")
privacy_answers = (root / "docs/APP_STORE_CONNECT_ANSWERS.md").read_text(encoding="utf-8")
privacy_metadata = (root / "docs/APP_STORE_METADATA.md").read_text(encoding="utf-8")


def fail(message):
    raise SystemExit(f"error: {message}")


def markdown_section(text, title):
    heading = re.search(rf"^##\s+{re.escape(title)}\s*$", text, flags=re.MULTILINE)
    if not heading:
        fail(f"Missing docs/GAME_CENTER_SETUP.md section: {title}")
    start = text.find("\n", heading.end())
    if start == -1:
        return ""
    next_heading = re.search(r"\n##\s+", text[start + 1:])
    end = len(text) if not next_heading else start + 1 + next_heading.start()
    return text[start:end]


leaderboard_ids = sorted(set(re.findall(r'static\s+let\s+\w+Leaderboard\s*=\s*"([^"]+)"', game_center)))
if not leaderboard_ids:
    fail("No Game Center leaderboard IDs found in GameCenterService.swift")

badge_ids = []
for line in badges.splitlines():
    match = re.match(r"\s*case\s+([A-Za-z_]\w*)(?:\s*=\s*\"([^\"]+)\")?\s*$", line)
    if match:
        badge_ids.append(match.group(2) or match.group(1))
badge_ids = sorted(set(badge_ids))
if not badge_ids:
    fail("No Badge raw values found for Game Center achievements")

documented_leaderboards = sorted(set(re.findall(r"`([^`]+)`", markdown_section(setup, "Leaderboards"))))
documented_achievements = sorted(set(re.findall(r"`([^`]+)`", markdown_section(setup, "Achievements"))))

if documented_leaderboards != leaderboard_ids:
    fail(
        "Game Center leaderboard IDs in docs/GAME_CENTER_SETUP.md do not match code: "
        f"docs={documented_leaderboards}, code={leaderboard_ids}"
    )
if documented_achievements != badge_ids:
    fail(
        "Game Center achievement IDs in docs/GAME_CENTER_SETUP.md do not match Badge raw values: "
        f"docs={documented_achievements}, code={badge_ids}"
    )

for identifier in leaderboard_ids + badge_ids:
    if f"`{identifier}`" not in submission:
        fail(f"docs/APP_STORE_SUBMISSION.md is missing Game Center ID `{identifier}`")

required_privacy_phrase = "Gameplay Content / Game Center"
if required_privacy_phrase not in privacy_answers or required_privacy_phrase not in privacy_metadata:
    fail("App Store privacy drafts must mention Gameplay Content / Game Center while GameKit is enabled")

print("Game Center configuration passed.")
PY
