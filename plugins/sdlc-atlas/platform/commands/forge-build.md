---
name: forge-build
description: >-
  Iterative build controller for greenfield projects. Takes the forge plan from
  .claude/memory/forge_plan.md and runs Phase 7 (iterative batch build) and Phase 8
  (integration summary). Run this after /start Branch A is complete.
---

# /forge-build

**For greenfield projects only.** Run this after the planning phase (Phases 1-6) of `/start` is completed and `forge_plan.md` has been verified.

---

## Step 0 — Verify workspace status

```bash
pwd
echo "$HOME/.claude"
```

- PROJECT_ROOT = first output
- PLATFORM_HOME = second output

Verify required planning artifacts exist:
```bash
ls "PROJECT_ROOT/.claude/memory/forge_plan.md" 2>/dev/null && echo "PLAN_EXISTS" || echo "PLAN_MISSING"
ls "PROJECT_ROOT/.claude/memory/context_bundle.md" 2>/dev/null && echo "BUNDLE_EXISTS" || echo "BUNDLE_MISSING"
```

If any are missing, print:
```
⛔ Missing planning files. Please run /start first to generate your forge plan,
then run /forge-build.
```
and STOP.

---

## Step 1 — Check for in-flight build

Read the current pipeline state:
```bash
cat "PROJECT_ROOT/.claude/memory/orchestrator_state.md" 2>/dev/null || echo "NOT_FOUND"
```

If state exists and phase is `forge-phase7-build-complete` or `forge-complete`:
Print:
```
[forge-build] Build is already complete.
Run /quality-check to run all test gates, or /raise-pr to raise a pull request.
```
and STOP.

---

## Step 2 — Launch forge-agent in Build-Only Mode

Print `→ forge-agent (build-only)` then dispatch `forge-agent` via Task:

```
Agent: forge-agent
Inputs:
  project_root: PROJECT_ROOT
  platform_home: PLATFORM_HOME
  context_bundle: PROJECT_ROOT/.claude/memory/context_bundle.md
  build_only: true

Task:
  Read context_bundle.md and forge_plan.md.
  Resume directly into Phase 7 (Iterative Build).
  Process each batch in forge_plan.md in sequence:
    - Dispatch batch features in parallel to orchestrator passing their specific ux_slice
    - Wait for all features in the batch to complete before starting the next batch
    - Prompt for approval per spec as required
  Run Phase 8 (Integration Summary) once all batches are resolved.
  Return a summary of all features built when complete.
```
