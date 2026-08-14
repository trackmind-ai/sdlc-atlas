---
name: investigate
description: >-
  Root-cause debugging. Iron Law: no fix without investigation first. Reproduce,
  pattern-match, hypothesis-test, minimal fix, regression test.
---

# /investigate

**Root-cause bug debugging** — parallel lane to `/fix`, focused on investigation and diagnosis before any fix is attempted.

## Invocation

```
/investigate <bug description>
```

Describe the bug in a few sentences: what the user observes, when it happens, expected behavior.

## Process

Dispatch `debug-agent`. Agent loads skill: `root-cause-debugging`, follows the investigation protocol: Phase 1 (reproduce + symptom collect), Phase 2 (scope lock + hypotheses), Phase 3 (pattern match), Phase 4 (hypothesis testing, max 3), Phase 5 (minimal fix), Phase 6 (verification + report).

## Output

Mini-spec file `.claude/specs/<feature>/fix-<slug>.md` containing:
- Structured DEBUG REPORT (Symptom / Root Cause / Fix / Evidence / Regression Test / Status)
- The minimal fix code
- Regression test covering the broken code path
- Full audit trail of the investigation

This keeps debugging work inside the spec-versioning discipline for future reference.

## Verdict

- `DONE` — bug diagnosed, fixed, tested, regression test added
- `DONE_WITH_CONCERNS` — fixed but with caveats (e.g., workaround instead of full root cause)
- `BLOCKED` — unable to diagnose; ask user for more info/logs

## Auto-handoff into /fix

On `DONE` or `DONE_WITH_CONCERNS`, the mini-spec at `.claude/specs/<feature>/fix-<slug>.md`
already satisfies `/fix` Step 2 (mini-spec produced). Do not require the user to re-paste
anything — print:

```
[debug-agent → /fix] Investigation complete. Mini-spec ready at <path>.
Run `/fix <spec_id>` to review and approve — build/gate/PR proceed as normal.
```

`/fix`, when invoked with a spec_id that already exists at that path, skips its own
Step 2 (mini-spec generation) and goes straight to Step 3 (one-line approval) using the
DEBUG REPORT already on disk. On `BLOCKED`, there is nothing to hand off — surface the
question to the user instead.

## Example

```bash
/investigate "Form submit button freezes after rapid clicks; page becomes unresponsive"
```

Debug agent reproduces the freeze, identifies race condition in form submission handler, adds debounce, writes regression test, confirms fix resolves the issue.
