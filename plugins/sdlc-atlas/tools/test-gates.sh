#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
# Behaviour test for platform/scripts/run-gates.sh: a missing tool or missing QA tooling
# stays a visible failure until the developer declines it, and a declined one is recorded
# honestly as "SKIPPED (declined)" instead of stopping the pipeline.
# Run from the plugin root: bash tools/test-gates.sh
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
GATES="$(pwd)/platform/scripts/run-gates.sh"
fails=0
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
expect() { if [ "$2" = "$3" ]; then echo "  ok   $1"; else echo "  FAIL $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi; }

# mk <declared test cmd> <stack line>  -> prints a fresh project dir
mk() {
  local d; d="$(mktemp -d -p "$WORK")"
  mkdir -p "$d/.claude/memory"
  printf 'test: %s\nstacks: %s\n' "$1" "$2" > "$d/.claude/CLAUDE.md"
  echo "# readme" > "$d/README.md"
  echo "$d"
}
# run <dir> -> exit code; the gate table is left in <dir>/.claude/memory/gate_results.md
run() { (cd "$1" && bash "$GATES" > "$1/out.txt" 2>&1; echo $?); }
row() { grep -F "$2" "$1/.claude/memory/gate_results.md" | head -1; }

# 1. A missing test runner is a FAIL while the developer has not answered.
d=$(mk "no-such-tool-xyz run" "node")
expect "missing tool, not declined: pipeline stops" "$(run "$d")" 2
row "$d" "| 1 |" | grep -q "FAIL" && r=FAIL || r=other
expect "missing tool, not declined: row 1 is FAIL" "$r" FAIL

# 2. Once declined, the same gate is SKIPPED (declined) and the pipeline continues.
echo "no-such-tool-xyz" > "$d/.claude/memory/declined_tools.md"
expect "missing tool, declined: pipeline continues" "$(run "$d")" 0
row "$d" "| 1 |" | grep -q "SKIPPED (declined)" && r=skipped || r=other
expect "missing tool, declined: row 1 is SKIPPED (declined)" "$r" skipped
grep -q "skipped at the developer's request" "$d/out.txt" && r=noted || r=silent
expect "declined skip is called out in the output" "$r" noted

# 3. Frontend stack with no QA report: gate 4 stays PENDING.
d=$(mk "true" "react")
run "$d" > /dev/null
row "$d" "| 4 |" | grep -q "PENDING" && r=PENDING || r=other
expect "frontend, no qa_report: row 4 is PENDING" "$r" PENDING

# 4. Developer-declined QA: row 4 is SKIPPED (declined), never PASS.
printf 'verdict: SKIPPED\ndeclined_by: developer\nui_verified: false\n' > "$d/.claude/memory/qa_report.md"
run "$d" > /dev/null
row "$d" "| 4 |" | grep -q "SKIPPED (declined)" && r=skipped || r=other
expect "frontend, declined QA: row 4 is SKIPPED (declined)" "$r" skipped
row "$d" "| 4 |" | grep -q "PASS" && r=PASS || r=notpass
expect "frontend, declined QA: never recorded as PASS" "$r" notpass

# 5. An agent cannot dodge QA by writing SKIPPED without the developer marker.
printf 'verdict: SKIPPED\nreason: agent felt like it\n' > "$d/.claude/memory/qa_report.md"
run "$d" > /dev/null
row "$d" "| 4 |" | grep -q "PENDING" && r=PENDING || r=other
expect "SKIPPED without declined_by: developer stays PENDING" "$r" PENDING

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
