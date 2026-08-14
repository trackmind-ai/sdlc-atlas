#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
# sdlc-atlas gate runner. THE GATE ORDER LIVES HERE, IN CODE — not in prose.
# Reads gate commands from .claude/CLAUDE.md (test: / security: / lint:),
# runs them in fixed order, stops on first failure, writes results to
# .claude/memory/gate_results.md. The LLM review gate runs AFTER this script.
#
# MUST be run from the project root (the folder containing .claude/).
# Example: cd /path/to/my-project && bash .claude/scripts/run-gates.sh
set -uo pipefail

# Verify we're in the right place
CFG=".claude/CLAUDE.md"
OUT=".claude/memory/gate_results.md"

if [ ! -f "$CFG" ]; then
  echo "run-gates: no $CFG found."
  echo "  Run this script from the project root (the folder containing .claude/)."
  echo "  Current directory: $(pwd)"
  exit 1
fi

mkdir -p .claude/memory

getcmd(){ sed -n "s/^$1:[[:space:]]*//p" "$CFG" | head -1; }
TEST_CMD="$(getcmd test)"
SEC_CMD="$(getcmd security)"
LINT_CMD="$(getcmd lint)"

{
  echo "# Gate results — $(date -u +%Y-%m-%dT%H:%MZ)"
  echo "| # | gate | command | result |"
  echo "|---|---|---|---|"
} > "$OUT"

run_gate(){ # $1=num $2=name $3=cmd  -- writes its own row line to $4 (a per-gate temp file), never touches $OUT directly.
  local n="$1" name="$2" cmd="$3" rowfile="$4" log_prefix="$5"
  # Detect unfilled template placeholders — both [FILL...] and {{VAR}} mustache formats
  case "$cmd" in *"[FILL"*|*"{{"*)
    echo "| $n | $name | unfilled placeholder | **FAIL** |" > "$rowfile"
    echo "${log_prefix}GATE $n $name: FAIL — '$name:' in .claude/CLAUDE.md is an unfilled template placeholder — set a real command."
    return 2
    ;;
  esac
  # Skip if not declared
  if [ -z "$cmd" ]; then
    echo "| $n | $name | (not declared in CLAUDE.md) | SKIPPED |" > "$rowfile"
    echo "${log_prefix}GATE $n $name: SKIPPED (declare '$name:' in .claude/CLAUDE.md to enable)"
    return 0
  fi
  # Verify the underlying tool is actually installed before running — a missing binary
  # is a setup problem, not a test/scan failure, and should be reported as such.
  local tool; tool="$(echo "$cmd" | awk '{print $1}')"
  if ! command -v "$tool" > /dev/null 2>&1; then
    echo "| $n | $name | tool not installed: $tool | **FAIL** |" > "$rowfile"
    echo "${log_prefix}GATE $n $name: FAIL — '$tool' not found on PATH. Install it, then re-run this script."
    return 2
  fi
  echo "${log_prefix}GATE $n $name: running -> $cmd"
  if bash -c "$cmd" > "${rowfile}.log" 2>&1; then
    echo "| $n | $name | \`$cmd\` | PASS |" > "$rowfile"
    echo "${log_prefix}GATE $n $name: PASS"
    return 0
  else
    echo "| $n | $name | \`$cmd\` | **FAIL** |" > "$rowfile"
    cat "${rowfile}.log"
    echo "${log_prefix}GATE $n $name: FAIL"
    return 2
  fi
}

# Gate 0 — Onboarding & Setup check
echo "GATE 0 onboarding: verifying workspace requirements..."
if [ ! -f "README.md" ]; then
  echo "| 0 | onboarding | Missing README.md | **FAIL** |" >> "$OUT"
  echo "GATE 0 onboarding: FAIL — Missing README.md in project root."
  exit 2
fi
if [ -z "$(find . -maxdepth 1 -name "*.env.example" -o -name "*config.example" -o -name "*template.json" -o -name ".env.sample")" ]; then
  echo "GATE 0 onboarding: WARNING — Missing environment configuration template (.env.example / .env.sample)."
fi
echo "| 0 | onboarding | Static workspace check | PASS |" >> "$OUT"
echo "GATE 0 onboarding: PASS"

# Gates 1-3 (test/security/lint) are independent tools with no data dependency
# between them — run concurrently, then report in fixed order 1/2/3 exactly as
# if they'd run sequentially. Any of the three failing stops the pipeline before
# gate 3b, same as before; the only change is wall-clock, not order or outcome.
ROWDIR="$(mktemp -d)"
trap 'rm -rf "$ROWDIR"' EXIT

run_gate 1 test     "$TEST_CMD" "$ROWDIR/1" "[parallel] " & PID1=$!
run_gate 2 security "$SEC_CMD"  "$ROWDIR/2" "[parallel] " & PID2=$!
run_gate 3 lint     "$LINT_CMD" "$ROWDIR/3" "[parallel] " & PID3=$!

RC1=0; RC2=0; RC3=0
wait "$PID1" || RC1=$?
wait "$PID2" || RC2=$?
wait "$PID3" || RC3=$?

cat "$ROWDIR/1" >> "$OUT"
cat "$ROWDIR/2" >> "$OUT"
cat "$ROWDIR/3" >> "$OUT"

if [ "$RC1" -ne 0 ] || [ "$RC2" -ne 0 ] || [ "$RC3" -ne 0 ]; then
  echo
  echo "PIPELINE STOPPED — one or more of gates 1-3 (test/security/lint) failed."
  echo "Fix the failures above, then re-run."
  echo "Results written to: $OUT"
  exit 2
fi

# Gate 3b — build (frontend/compiled stacks): shipped code must compile, not just lint.
BUILD_CMD="$(getcmd build)"
if [ -z "$BUILD_CMD" ] && [ -f "package.json" ] && grep -q '"build"' package.json; then
  BUILD_CMD="npm run build"
fi
if [ -n "$BUILD_CMD" ]; then
  run_gate "3b" build "$BUILD_CMD" || exit 2
else
  echo "| 3b | build | (no build step detected) | SKIPPED |" >> "$OUT"
fi

# Gate 4 — live browser QA. MANDATORY for frontend stacks. This script cannot drive a
# browser itself — qa-agent does — but it REFUSES to call the gates green without QA
# evidence, so the gate can never be silently forgotten.
FRONTEND=0
grep -Eiq '^(stacks?|frontend):.*\b(react|nextjs|next\.js|angular|vue|svelte|react-native|flutter)\b' "$CFG" && FRONTEND=1
QA_REPORT=".claude/memory/qa_report.md"
if [ "$FRONTEND" -eq 1 ]; then
  if [ -f "$QA_REPORT" ] && grep -Eiq '^(verdict|## verdict).*(PASS)' "$QA_REPORT"; then
    # Freshness: QA evidence older than the newest source file is stale.
    NEWEST_SRC="$(find src app frontend -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.vue' -o -name '*.svelte' -o -name '*.css' -o -name '*.html' \) -newer "$QA_REPORT" 2>/dev/null | head -1)"
    if [ -n "$NEWEST_SRC" ]; then
      echo "| 4 | qa (browser) | qa_report.md STALE — source changed since: $NEWEST_SRC | **PENDING** |" >> "$OUT"
      echo "GATE 4 qa: PENDING — qa_report.md is older than $NEWEST_SRC. Re-run qa-agent (/qa)."
    else
      echo "| 4 | qa (browser) | qa_report.md verdict PASS | PASS |" >> "$OUT"
      echo "GATE 4 qa: PASS (fresh qa_report.md)"
    fi
  else
    echo "| 4 | qa (browser) | qa-agent — dispatch via /qa | **PENDING** |" >> "$OUT"
    echo "GATE 4 qa: PENDING — frontend stack detected, no passing qa_report.md. Dispatch qa-agent (/qa). MANDATORY."
  fi
else
  echo "| 4 | qa (browser) | (no frontend stack declared) | SKIPPED |" >> "$OUT"
fi

echo "| 5 | review (LLM) | review-agent | PENDING |" >> "$OUT"
echo

# Final verdict line — agents and humans key off this exact string. Gates are complete
# ONLY when no PENDING/FAIL rows remain in gate_results.md.
if grep -q 'PENDING' "$OUT"; then
  echo "GATES INCOMPLETE: PENDING gates remain (see $OUT). Script gates green, but the"
  echo "pipeline is NOT done — resolve every PENDING row (qa-agent, review-agent) and"
  echo "flip it to PASS/FAIL in $OUT before declaring the feature or forge complete."
else
  echo "GATES COMPLETE: all rows resolved."
fi
echo "Results written to: $OUT"
