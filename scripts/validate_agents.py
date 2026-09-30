#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
"""
Validates the plugin's capability definitions before they reach users.

`claude plugin validate .` checks manifest *shape*. This script checks the things shape
alone cannot catch, and that only surface once a user has the plugin installed:

  - required frontmatter fields are present on every agent
  - every skill an agent names actually exists in platform/skills/, matched by the skill's
    declared frontmatter `name` (Claude Code resolves by name, not filename — these two
    drifted apart once already and made a skill unloadable for two agents)
  - plugin.json's `agents` list matches platform/agents/ on disk. The schema requires
    explicit file paths there rather than a directory, so a newly added agent that nobody
    remembers to list is simply never shipped — silently, with CI green.

Exit code is 0 when clean, 1 when any error is found. Warnings never fail.
"""

import json
import sys
import re
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml required. Run: pip install pyyaml")
    sys.exit(1)

ROOT = Path(__file__).parent.parent
PLUGIN = ROOT / "plugins" / "sdlc-atlas"
AGENTS_DIR = PLUGIN / "platform" / "agents"
SKILLS_DIR = PLUGIN / "platform" / "skills"

REQUIRED_FIELDS = {"name", "description", "tools"}

errors = []
warnings = []


def extract_frontmatter(path):
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---", text, re.DOTALL)
    if not match:
        return None
    try:
        return yaml.safe_load(match.group(1))
    except yaml.YAMLError as e:
        errors.append(f"{path.name}: invalid YAML — {e}")
        return None


def get_skill_names():
    names = set()
    # Support both skills/<name>/SKILL.md (Claude Code plugin format) and legacy flat *.md
    skill_files = list(SKILLS_DIR.glob("*/SKILL.md")) + list(SKILLS_DIR.glob("*.md"))
    for f in skill_files:
        fm = extract_frontmatter(f)
        names.add(fm["name"] if fm and "name" in fm else (f.parent.name if f.name == "SKILL.md" else f.stem))
    return names


def validate_agent(path, known_skills):
    fm = extract_frontmatter(path)
    if fm is None:
        errors.append(f"{path.name}: missing frontmatter")
        return
    for field in REQUIRED_FIELDS:
        if field not in fm:
            errors.append(f"{path.name}: missing required field '{field}'")
    for skill in fm.get("skills", []) or []:
        if skill not in known_skills:
            errors.append(f"{path.name}: skill '{skill}' not found in platform/skills/")


def validate_manifest_agent_list():
    """plugin.json's `agents` array must list exactly the files in platform/agents/."""
    manifest = PLUGIN / ".claude-plugin" / "plugin.json"
    if not manifest.exists():
        errors.append(f"plugin manifest not found: {manifest}")
        return

    try:
        declared_raw = json.loads(manifest.read_text(encoding="utf-8")).get("agents", [])
    except json.JSONDecodeError as exc:
        errors.append(f"plugin.json is not valid JSON: {exc}")
        return

    # The schema also permits a plain string; normalise before comparing.
    if isinstance(declared_raw, str):
        declared_raw = [declared_raw]

    declared = {Path(p).name for p in declared_raw}
    on_disk = {f.name for f in AGENTS_DIR.glob("*.md")}

    for missing in sorted(on_disk - declared):
        errors.append(
            f"platform/agents/{missing} exists but is not listed in plugin.json "
            f"'agents' — it will not ship"
        )
    for stale in sorted(declared - on_disk):
        errors.append(
            f"plugin.json 'agents' lists {stale}, which does not exist in platform/agents/"
        )


def main():
    # Hard failure, not a warning. This used to print a warning and exit 0, which meant
    # a moved or renamed directory made the whole check silently vacuous — green CI
    # proving nothing. If the layout changes, this script must be updated with it.
    if not AGENTS_DIR.exists():
        print(f"  FAIL  agents directory not found: {AGENTS_DIR}")
        print("\nThe repo layout changed without updating this script. Fix the paths.")
        sys.exit(1)

    known_skills = get_skill_names()
    agent_files = sorted(AGENTS_DIR.glob("*.md"))

    # Same reasoning: zero agents means the glob is wrong, not that everything passed.
    if not agent_files:
        print(f"  FAIL  no agent definitions found in {AGENTS_DIR}")
        sys.exit(1)

    for f in agent_files:
        validate_agent(f, known_skills)

    validate_manifest_agent_list()

    if warnings:
        for w in warnings:
            print(f"  WARN  {w}")
    if errors:
        for e in errors:
            print(f"  FAIL  {e}")
        print(f"\n{len(errors)} error(s). Fix before merging.")
        sys.exit(1)

    print(f"OK  {len(agent_files)} agent(s) valid.")


if __name__ == "__main__":
    main()
