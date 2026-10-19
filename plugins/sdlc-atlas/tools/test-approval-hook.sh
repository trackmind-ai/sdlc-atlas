#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
# Behaviour test for the plugin's PreToolUse edit-gate hooks (hooks/hooks.json).
# Run from the plugin root: bash tools/test-approval-hook.sh
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
PY=$(command -v python3 || command -v python) || { echo "no python"; exit 1; }
fails=0
hook() { "$PY" -c "import json,sys;print(json.load(open('hooks/hooks.json'))['hooks']['PreToolUse'][0]['hooks'][$1]['command'])"; }
run() { # <hook-index> <project-dir> <file>  -> exit code
  printf '{"tool_input":{"file_path":"%s"}}' "$3" | CLAUDE_PROJECT_DIR="$2" bash -c "$(hook "$1")" >/dev/null 2>&1; echo $?
}
expect() { [ "$2" = "$3" ] && echo "  ok   $1" || { echo "  FAIL $1 (exit $2, want $3)"; fails=$((fails+1)); }; }

plain=$(mktemp -d); setup=$(mktemp -d); approved=$(mktemp -d); started=$(mktemp -d)
mkdir -p "$setup/.claude/agents" "$approved/.claude/memory/approvals"
cp projects/project-template/settings.json "$setup/.claude/settings.json"
cp projects/project-template/settings.json "$approved/.claude/settings.json"
echo "x" > "$approved/.claude/memory/approvals/ACTIVE"
echo "existing" > "$setup/.claude/agents/a.md"
mkdir -p "$started/.claude/memory"; echo "phase: spec" > "$started/.claude/memory/orchestrator_state.md"

expect "plain project: code edit allowed"               "$(run 1 "$plain" "$plain/src/app.py")" 0
expect "plain project: own .claude/agents edit allowed" "$(run 0 "$plain" "$plain/.claude/agents/a.md")" 0
expect "set-up project, no approval: code edit blocked" "$(run 1 "$setup" "$setup/src/app.py")" 2
expect "set-up project: capability file edit blocked"   "$(run 0 "$setup" "$setup/.claude/agents/a.md")" 2
expect "set-up project, approved: code edit allowed"    "$(run 1 "$approved" "$approved/src/app.py")" 0
expect "pipeline started (state file only): code edit blocked" "$(run 1 "$started" "$started/src/app.py")" 2
rm -rf "$started" "$plain" "$setup" "$approved"
[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
