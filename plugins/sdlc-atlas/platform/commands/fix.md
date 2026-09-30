# /fix <short description of the bug/small change>

The quick lane for bug-sized work (≲ 2 hours). Same guarantees, fraction of the ceremony.

## Step 0 — Establish roots
```bash
pwd
echo "$HOME/.claude"
```
PROJECT_ROOT = first output. PLATFORM_HOME = second output. All paths below are absolute.

## Step 1 — Establish project root
```bash
pwd
```
PROJECT_ROOT = output above. All paths below are PROJECT_ROOT-absolute.

## Step 2 — Mini-spec
If `/fix` was invoked with a spec_id that already exists on disk (e.g. handed off from
`/investigate`, at `.claude/specs/<feature>/fix-<slug>.md`), skip generation — use that
file as the mini-spec and go straight to Step 3.

Otherwise, spec-agent produces a MINI-SPEC from `PLATFORM_HOME/templates/minispec_template.md` —
one paragraph + file list, brownfield-reading rules still apply (declare scope,
cite file:line), saved as `PROJECT_ROOT/.claude/specs/fix/fix_N.md`.

## Step 3 — Approval
Display the mini-spec in full (it's one paragraph + file list — this is the "fraction
of the ceremony", not a lighter approval bar). Wait for the developer to type the
literal keyword **APPROVED** — same bar as `/approve-spec`. A conversational "yes" or
"looks good" is NOT sufficient. On APPROVED: write marker to
`PROJECT_ROOT/.claude/memory/approvals/ACTIVE` with content
`fix/fix_N approved <timestamp>` (same mechanism and format as /approve-spec).

## Step 4 — Build and gate
Single agent build, then run (project-local copy first, platform-home fallback —
most projects only have the platform-home copy since install.sh --platform never
writes a project-local one):
```bash
cd "PROJECT_ROOT" && GATES_SCRIPT=".claude/scripts/run-gates.sh"; [ -f "$GATES_SCRIPT" ] || GATES_SCRIPT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude}/platform/scripts/run-gates.sh"; [ -f "$GATES_SCRIPT" ] || GATES_SCRIPT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude}/scripts/run-gates.sh"; [ -f "$GATES_SCRIPT" ] || GATES_SCRIPT="$HOME/.claude/scripts/run-gates.sh"; bash "$GATES_SCRIPT"
```
GATES ARE NEVER SKIPPED — only the spec shrinks.

## Step 5 — Raise PR
/raise-pr as normal.

## Escalation rule
If the mini-spec needs more than ~5 file changes or touches contracts / schemas /
security behaviour, spec-agent must say so and route to /feature instead.
