---
name: setup
description: "One-time project onboarding. Asks where the project lives, interviews the developer, reads existing code if any, and writes .claude/CLAUDE.md + knowledge.md. Run this in a fresh folder OR an existing project that has no .claude/CLAUDE.md yet."
---

# /setup

## Step 0 — Caveman plugin check (optional — ask, never block)

Caveman is an optional third-party plugin that enforces terse output. `/setup` works
without it.

```bash
cat "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active" 2>/dev/null || echo "NOT_INSTALLED"
```

If active → continue to Step 1.

If `NOT_INSTALLED` or empty → ask the developer (AskUserQuestion), printing:
```
[Setup] Caveman plugin not detected.
It is an optional third-party plugin that cuts token usage by enforcing terse output.
Install it now? (yes / no)
```
- **no** → print `Continuing without caveman — terse-output enforcement is off. You can
  install it later.` and continue to Step 1. Do not ask again this session.
- **yes** → run the installer for the developer's OS (pinned to a fixed commit):
  ```
  Windows:   irm https://raw.githubusercontent.com/JuliusBrussee/caveman/bad48a0e1df55e05e3f52249afa35ecc1909ee76/install.ps1 | iex
  Mac/Linux: curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/bad48a0e1df55e05e3f52249afa35ecc1909ee76/install.sh | bash
  ```
  Then re-check. If it is active, continue. If it is not (some installs only take effect
  after a restart), print `Caveman did not activate. Continuing without it — restart
  Claude Code later to enable it.` and continue to Step 1.

Never stop `/setup` because of caveman.

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
