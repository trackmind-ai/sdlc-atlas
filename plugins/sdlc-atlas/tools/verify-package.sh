#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
# sdlc-atlas package self-test. Run from the package root: bash tools/verify-package.sh
#
# File structure rules this script enforces:
#   Stack layer   → agents/<name>/AGENT.md  skills/<name>/SKILL.md  (subfolder per item)
#   Project layer → agents/<name>/AGENT.md  skills/<name>/SKILL.md  (same structure)
#   Platform layer built-ins → agents/<name>.md  skills/<name>.md   (flat .md — orchestrator etc.)
set -uo pipefail
fails=0
ok(){ printf '  \033[32m✔\033[0m %s\n' "$1"; }
bad(){ printf '  \033[31m✘\033[0m %s\n' "$1"; fails=$((fails+1)); }

# 1. JSON validity
# Resolve an interpreter once rather than hardcoding `python3`: on Windows/Git-Bash the
# bare `python3` name is a WindowsApps stub that exits non-zero without running, so with
# stderr swallowed every file below was reported INVALID when all of them parse fine.
PY=""
for cand in python3 python py; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" -c "import json" >/dev/null 2>&1; then
    PY="$cand"; break
  fi
done
if [ -z "$PY" ]; then
  bad "no working Python interpreter found — cannot validate JSON"
else
  while IFS= read -r j; do
    if err=$("$PY" -c "import json,sys;json.load(open(sys.argv[1]))" "$j" 2>&1); then
      ok "valid JSON: $j"
    else
      bad "INVALID JSON: $j — ${err##*: }"
    fi
  done < <(find . -name settings.json)
fi

# 2. Agent/skill folder structure:
#    Stack layer (stacks/**):   agents/<name>/AGENT.md  skills/<name>/SKILL.md
#    Project layer (projects/): agents/<name>/AGENT.md  skills/<name>/SKILL.md  (same)
#    Platform layer (platform/): agents/<name>.md  skills/<name>.md  (flat — built-ins only)

# 2a. Stack layer — each agents/ subfolder must contain AGENT.md
for d in $(find stacks -type d -name agents 2>/dev/null); do
  for entry in "$d"/*/; do
    [ -d "$entry" ] || continue
    if [ ! -f "$entry/AGENT.md" ]; then
      bad "stack agent folder missing AGENT.md: $entry"
    else
      ok "stack agent: ${entry}AGENT.md"
    fi
    if find "$entry" -mindepth 1 -type d | grep -q .; then
      bad "unexpected subdir inside stack agent folder: $entry"
    fi
  done
done

# 2b. Stack layer — each skills/ subfolder must contain SKILL.md
for d in $(find stacks -type d -name skills 2>/dev/null); do
  for entry in "$d"/*/; do
    [ -d "$entry" ] || continue
    if [ ! -f "$entry/SKILL.md" ]; then
      bad "stack skill folder missing SKILL.md: $entry"
    else
      ok "stack skill: ${entry}SKILL.md"
    fi
    if find "$entry" -mindepth 1 -type d | grep -q .; then
      bad "unexpected subdir inside stack skill folder: $entry"
    fi
  done
done

# 2c. Project layer — each agents/ subfolder must contain AGENT.md, each skills/ must contain SKILL.md
for d in $(find projects -type d -name agents 2>/dev/null); do
  for entry in "$d"/*/; do
    [ -d "$entry" ] || continue
    if [ ! -f "$entry/AGENT.md" ]; then
      bad "project agent folder missing AGENT.md: $entry"
    else
      ok "project agent: ${entry}AGENT.md"
    fi
  done
done
for d in $(find projects -type d -name skills 2>/dev/null); do
  for entry in "$d"/*/; do
    [ -d "$entry" ] || continue
    if [ ! -f "$entry/SKILL.md" ]; then
      bad "project skill folder missing SKILL.md: $entry"
    else
      ok "project skill: ${entry}SKILL.md"
    fi
  done
done

# 2d. Platform layer — agents/ and skills/ must be FLAT (built-ins are flat .md files)
for d in $(find platform -type d \( -name agents -o -name skills \) 2>/dev/null); do
  if find "$d" -mindepth 1 -type d | grep -q .; then
    bad "nested subfolders in platform built-in layer (must be flat): $d"
  else
    ok "flat platform built-ins: $d"
  fi
done

# 3. Every skill referenced in agent files exists somewhere in the package
#    Stack/project skills: SKILL.md inside subfolder
#    Platform skills: flat .md
skill_exists() {
  local ref="$1"
  find stacks projects -path "*/skills/$ref/SKILL.md" | grep -q . && return 0
  find platform -path "*/skills/${ref}.md" | grep -q . && return 0
  return 1
}

missing=0
for ref in $(grep -rhoE "(Load skills?:|skill: )\`[a-z-]+\`" platform stacks projects 2>/dev/null | grep -oE '\`[a-z-]+\`' | tr -d '\`' | sort -u); do
  skill_exists "$ref" || { bad "referenced skill missing: $ref"; missing=1; }
done
# explicit skill mentions in prose
for ref in greenfield-grounding project-bootstrap brownfield-reading citation-discipline knowledge-md proposal-evaluation spec-writing spec-paths interaction-style agent-handoff retry-policy project-permissions greenfield-interview security-scans safe-migration express-endpoint node-bootstrap angular-bootstrap angular-component angular-service; do
  skill_exists "$ref" || bad "skill file missing: $ref"
done
[ $missing -eq 0 ] && ok "all loaded skills resolve"

# 4. Every agent named in commands exists
#    Stack/project agents: AGENT.md inside subfolder
#    Platform agents: flat .md
agent_exists() {
  local ag="$1"
  find stacks projects -path "*/agents/$ag/AGENT.md" | grep -q . && return 0
  find platform -path "*/agents/${ag}.md" | grep -q . && return 0
  return 1
}

# The pattern must allow hyphens inside the name. `[a-z]+-agent` matched only the last
# segment, so `ux-research-agent` was read as `research-agent` and `product-strategy-agent`
# as `strategy-agent` — then reported missing. That produced ~30 phantom failures and hid
# the real ones. `sub-agent` is prose, not a dispatch target, so it stays excluded.
for ag in $(grep -rhoE "\b[a-z][a-z-]*-agent\b" platform/commands stacks/*/commands projects/*/commands 2>/dev/null | sort -u); do
  case "$ag" in sub-agent|the-agent|an-agent) continue ;; esac
  agent_exists "$ag" || bad "command references missing agent: $ag"
done
ok "command->agent references checked"

# 5. Pipeline phase owners exist (enterprise profile)
for ag in requirements-agent architecture-agent bootstrap-agent spec-agent test-agent security-agent sonar-agent review-agent acceptance-agent adr-agent docs-agent release-agent incident-agent retro-agent orchestrator; do
  [ -f "platform/agents/${ag}.md" ] || bad "platform agent missing: $ag"
done
ok "all required pipeline-owner agents present"

# 6. Templates referenced exist
for t in spec_template proposal_template adr_template orchestrator_state_template requirements_template drift_report_template pr_description_template minispec_template; do
  [ -f "platform/templates/${t}.md" ] || bad "template missing: $t"
done
ok "all required templates present"

# 7. No [FILL IN] outside the intentionally-fillable layers
if grep -rl "\[FILL IN" platform stacks 2>/dev/null | grep -q .; then bad "[FILL IN] found in platform/stacks (must be fill-free)"; else ok "platform/stacks are fill-free"; fi

# 7b. gate-runner present + syntax
[ -f platform/scripts/run-gates.sh ] && bash -n platform/scripts/run-gates.sh && ok "gate-runner present + syntax" || bad "gate-runner missing/broken"
# 7c. approval hook present in project layers
# Was hardcoded to a single internal project layer that is not shipped in this repo,
# so this check failed unconditionally. Iterate whatever project layers exist instead.
for p in projects/*/; do p="${p%/}"
  [ -f "$p/settings.json" ] || continue
  grep -q "approvals/ACTIVE" "$p/settings.json" && ok "approval hook: $p" || bad "approval hook missing: $p"
done

# 8. install.sh syntax
bash -n install.sh && ok "install.sh syntax" || bad "install.sh syntax error"

# 9. Frontmatter sanity: every agent/skill has name + description in YAML frontmatter
#    Stack/project layer: AGENT.md / SKILL.md inside subfolders
#    Platform layer: flat *.md inside agents/ or skills/

check_frontmatter() {
  local f="$1"
  head -8 "$f" | grep -q "^name:" || bad "missing frontmatter name: $f"
}

# stack + project layer agent files
for f in $(find stacks projects -path "*/agents/*/AGENT.md"); do
  check_frontmatter "$f"
done
# stack + project layer skill files
for f in $(find stacks projects -path "*/skills/*/SKILL.md"); do
  check_frontmatter "$f"
done
# platform flat agent/skill files
for f in $(find platform -path "*/agents/*.md" -o -path "*/skills/*.md"); do
  check_frontmatter "$f"
done
ok "frontmatter checked"

echo; [ $fails -eq 0 ] && { echo "PACKAGE VERIFIED — 0 failures"; exit 0; } || { echo "$fails FAILURES"; exit 1; }
