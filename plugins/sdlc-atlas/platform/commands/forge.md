---
name: forge
description: >-
  Launch forge-agent directly for a greenfield project that is already set up
  (CLAUDE.md exists). Use /forge when /start Branch A was already completed
  but you want to re-enter or continue the forge pipeline.
  For a fresh project with no setup, use /start instead.
---

# /forge

**For greenfield projects only.** If this is a brownfield project (existing code),
use `/feature` instead.

---

## Step 0 — Verify greenfield

```bash
pwd
echo "$HOME/.claude"
```

- PROJECT_ROOT = first output
- PLATFORM_HOME = second output

```bash
ls "PROJECT_ROOT/.claude/CLAUDE.md" 2>/dev/null && echo "EXISTS" || echo "MISSING"
```

If MISSING → print:
```
⛔ No .claude/CLAUDE.md found. Run /start first to set up the project,
then re-run /forge.
```
and STOP.

---

## Step 1 — Check for in-flight forge

```bash
cat "PROJECT_ROOT/.claude/memory/forge_plan.md" 2>/dev/null || echo "NOT_FOUND"
cat "PROJECT_ROOT/.claude/memory/orchestrator_state.md" 2>/dev/null || echo "NOT_FOUND"
```

If forge_plan.md exists and orchestrator_state.md shows a `forge-phase` that is NOT
`forge-complete`:

Print:
```
[forge] An in-flight forge session was found at phase: <phase>.

Resume from where it left off? (yes / restart)
```

- `yes` → dispatch forge-agent with `resume: true` and the current phase
- `restart` → proceed to Step 2 (fresh dispatch)

If forge_plan.md is NOT_FOUND → proceed to Step 2.

---

## Step 2 — Launch forge-agent

Print `→ forge-agent` then dispatch via Task:

```
Agent: forge-agent
Inputs:
  project_root: PROJECT_ROOT
  platform_home: PLATFORM_HOME
  context_bundle: PROJECT_ROOT/.claude/memory/context_bundle.md

Task:
  Read context_bundle.md first — do not re-ask anything already answered there.
  Run the full forge pipeline:
    Phase 1: Discovery interview (4 questions)
    Phase 2: Architecture (architecture-agent)
    Phase 3: Bootstrap (bootstrap-agent)
    Phase 4: Feature decomposition + user confirmation
    Phase 5: Iterative batch build (orchestrator per feature, parallel within batch)
    Phase 6: Integration summary
  Return a summary of all features built when complete.
```
