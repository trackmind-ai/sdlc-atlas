# /quality-check

## Step 1 — Establish project root
```bash
pwd
```
PROJECT_ROOT = output above.

## Step 2 — Run the gate script
```bash
GATES_SCRIPT="PROJECT_ROOT/.claude/scripts/run-gates.sh"
[ -f "$GATES_SCRIPT" ] || GATES_SCRIPT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude}/platform/scripts/run-gates.sh"
[ -f "$GATES_SCRIPT" ] || GATES_SCRIPT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude}/scripts/run-gates.sh"
[ -f "$GATES_SCRIPT" ] || GATES_SCRIPT="$HOME/.claude/scripts/run-gates.sh"
```
The script must be run from PROJECT_ROOT so relative paths inside it resolve
correctly:
```bash
cd "PROJECT_ROOT" && bash "$GATES_SCRIPT"
```

THE GATE ORDER LIVES IN THAT SCRIPT — code, not prose: onboarding → test → security → lint → build → browser QA,
fail-stops with exit 2, results written to `PROJECT_ROOT/.claude/memory/gate_results.md`.

## Step 2b — Browser QA gate (frontend stacks — MANDATORY, not optional)

Read `gate_results.md`. If row `| 4 | qa (browser) |` is **PENDING** (or stale):
dispatch `qa-agent` NOW (full mode) against the running dev server — start the
server first if needed. When qa-agent returns, flip row 4 to PASS or **FAIL**
based on the `verdict:` line in `.claude/memory/qa_report.md`. FAIL → stop here,
report findings; do not proceed to Step 3.

Row 4 SKIPPED (no frontend stack) → proceed directly to Step 3.

## Step 3 — LLM gates (after script passes)
Run review-agent (gate 5) and flip row 5 in `gate_results.md` with its verdict.
In enterprise profile, also run acceptance-agent (gate 6) and archive evidence
to `PROJECT_ROOT/.claude/memory/evidence/<spec_id>/`.

## Completion criterion
/quality-check reports success ONLY when `gate_results.md` contains no PENDING
and no FAIL rows. The script's "GATES INCOMPLETE" line means exactly that.

## Re-runs
The script is idempotent — just run it again after fixing failures.
