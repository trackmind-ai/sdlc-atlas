---
name: setup
description: "One-time project onboarding. Asks where the project lives, interviews the developer, reads existing code if any, and writes .claude/CLAUDE.md + knowledge.md. Run this in a fresh folder OR an existing project that has no .claude/CLAUDE.md yet."
---

# /setup

## Step 0 — Caveman plugin check (run first)

```bash
cat "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active" 2>/dev/null || echo "NOT_INSTALLED"
```

If `NOT_INSTALLED` or empty → stop and print:
```
[Setup] Caveman plugin not detected.

Install it first:
  Windows:  irm https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.ps1 | iex
  Mac/Linux: curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash

Restart Claude Code, then re-run /setup.
```

Do not proceed until caveman check passes.

## Step 1 — Confirm project directory

Ask the developer where the project lives **before doing anything else**:

```
[Agent: setup] Where should this project be created?

Enter the full path to your project folder (existing or new):
> e.g. C:\Users\you\projects\my-app   or   /home/you/projects/my-app

Do NOT use the sdlc-atlas folder itself as a project.
```

Validate:
- Must be absolute path
- Must NOT contain "sdlc-atlas" or "AgenticAI-SDLC" (the platform checkout) — reject if it does

Create if missing: `mkdir -p "<path>"`
Set PROJECT_ROOT = confirmed path.

## Step 2 — Dispatch setup-agent

```
Agent: setup-agent
Mode: /setup
Inputs:
- project_root: <confirmed path from Step 1>
- platform_home: <output of echo "$HOME/.claude">
- trigger: setup

Task: PROJECT_ROOT is already confirmed — skip directory question.
Load skill setup-interview-questions. Detect fresh vs brownfield automatically.
For FRESH: send BATCH 1 → wait → BATCH 2 → wait → BATCH 3 → wait (3 short batches,
not one giant message). After all replies, write CLAUDE.md + knowledge.md +
context_bundle.md + settings.json in PARALLEL (simultaneously, not sequentially).
Copy agents/skills/commands from PLATFORM_HOME. Create .claude/ skeleton.
Return a summary of what was written when done.
```

## What setup-agent does

1. Confirms project directory (already done — skips re-asking)
2. Detects fresh vs existing codebase
3. For brownfield: deep-reads every source file first, then sends brownfield confirmation batch
4. For fresh: sends 3 short batches (basics → stack → gates) — waits for each reply
5. Writes CLAUDE.md + knowledge.md + state + settings in parallel after final batch
6. Creates the `.claude/` folder structure
7. Copies platform + stack agents/skills/commands

## Profile options

```
a) small      → spec + build + test only. Solo / prototype.
b) standard   → + requirements + code review. Product teams. (recommended)
c) enterprise → all phases + ADRs + compliance. Multi-team.
```

## After setup

Run `/start` → choose c) to build a feature.
Or run `/feature "<what you want to build>"` directly.

**Already set up?** Run `/audit-project` to deep-read and regenerate from actual codebase.
