---
name: fetch-stack
description: "Fetches raw sources and generates a complete L1 stack directory (agents, skills, commands, settings.json, STACK.md) into PLATFORM_HOME/stacks/<name>/. Use when a stack is missing from PLATFORM_HOME, when the SessionStart hook reports a missing stack, or when the orchestrator needs a new stack at runtime."
---

# /fetch-stack <stack-name(s)>

Generate a complete L1 stack for: **$ARGUMENTS**

## Step 0 — Establish PLATFORM_HOME

```bash
echo "$HOME/.claude"
```

This is PLATFORM_HOME. All stack files go to `PLATFORM_HOME/stacks/<name>/`.
Never write to the project folder. Never write to the sdlc-atlas repo folder.

---

## Step 1 — Parse stack names

`$ARGUMENTS` may be one or multiple stack names separated by spaces or commas.

1. Split on whitespace and commas, strip, lowercase, discard empty tokens
2. You now have a list, e.g. `["nextjs", "nestjs"]`

If `$ARGUMENTS` is empty:
- Look for `stack:` or `stacks:` in `PROJECT_ROOT/.claude/CLAUDE.md`
- If still nothing, ask the user which stack to install — do not guess

---

## Step 2 — Check what's already installed

```bash
ls "PLATFORM_HOME/stacks/STACK_NAME/STACK.md" 2>/dev/null && echo "EXISTS" || echo "MISSING"
```

If EXISTS → mark as `[SKIP]` (already installed), no need to regenerate.

---

## Step 3 — Fetch raw sources for missing stacks

Pass ALL missing stack names in ONE bash call:

```bash
"PLATFORM_HOME/stacks/stack-orchestrator/bin/stack_fetcher.py" STACK1 STACK2 ...
```

For each stack in the output:
- `[SKIP]` → already installed
- `[OK] RAW FETCHED` → note the `raw-sources.md` path — proceed to Step 4
- `[FAIL]` → note the error, skip that stack, continue with remaining

Do NOT retry more than once on failure.

---

## Step 4 — Generate the complete stack directory

For every stack that returned `[OK] RAW FETCHED`:

**4a. Read the raw-sources.md** at the path shown in the script output.
Merge patterns, conventions, CLI commands from ALL sources with your own knowledge.

**4b. Generate ALL files** at `PLATFORM_HOME/stacks/STACK_NAME/` using the Write tool.
Match the generic template structure below exactly — do not model content on any one existing stack:

#### `PLATFORM_HOME/stacks/STACK_NAME/STACK.md`
```
# Stack: <Name> (L1)
Installs into a project's `.claude/` via `install.sh --stack <name> --project <path>`.
Project files win any filename collision. Declare `stack: <name>` in project CLAUDE.md.
Provides: <agent1>, <agent2>, ... + skills.
Defaults (project may override): test `<test-cmd>`, security `<sec-cmd>`, lint `<lint-cmd>`.
```

#### `PLATFORM_HOME/stacks/STACK_NAME/settings.json`
Framework-specific bash allow/deny ONLY. No hooks.
```json
{
  "permissions": {
    "allow": ["Bash(<framework-test-runner> *)", "Bash(<linter> *)", "Bash(<package-manager> *)"],
    "deny":  ["Bash(<destructive-command> *)"]
  }
}
```

#### `PLATFORM_HOME/stacks/STACK_NAME/agents/<agent-name>/AGENT.md` — one subfolder per agent
Each agent lives in its own named subfolder. The file is always named `AGENT.md`.

**Start from `PLATFORM_HOME/platform/templates/agent_template.md`** — fill in the frontmatter fields, adapt the role description and task list to this stack's domain. Do not compose frontmatter from scratch; use the template as the canonical scaffold for all stack agents.

#### `PLATFORM_HOME/stacks/STACK_NAME/skills/<skill-name>/SKILL.md` — one subfolder per skill
Each skill lives in its own named subfolder. The file is always named `SKILL.md`.

**Start from `PLATFORM_HOME/platform/templates/skill_template.md`** — fill in the frontmatter fields, adapt the procedure steps to this stack's domain. Do not compose frontmatter from scratch; use the template as the canonical scaffold for all stack skills.

#### `PLATFORM_HOME/stacks/STACK_NAME/commands/<command>.md` — flat, one per command, no frontmatter
```markdown
# /<command> <args>
One paragraph: what it invokes, what it refuses. Max 5 lines.
```

---

## Step 5 — Copy new stack into any open project that declared it

If a project is currently open (`PROJECT_ROOT/.claude/CLAUDE.md` exists and declares this stack),
use `install.sh` to merge the stack into the project layer (preserves subfolder + stack-grouping structure):

```bash
bash "AGENTICAI_SDLC_REPO/install.sh" --stack STACK_NAME --project PROJECT_ROOT
```

If `install.sh` is not available, copy manually — agents and skills are grouped under their stack name
in the project layer: `agents/STACK_NAME/<name>/AGENT.md`, `skills/STACK_NAME/<name>/SKILL.md`:
```bash
# agents — grouped under agents/STACK_NAME/ in the project layer
for agent_dir in "PLATFORM_HOME/stacks/STACK_NAME/agents"/*/; do
  mkdir -p "PROJECT_ROOT/.claude/agents/STACK_NAME/$(basename "$agent_dir")"
  cp "$agent_dir/AGENT.md" "PROJECT_ROOT/.claude/agents/STACK_NAME/$(basename "$agent_dir")/AGENT.md"
done
# skills — grouped under skills/STACK_NAME/ in the project layer
for skill_dir in "PLATFORM_HOME/stacks/STACK_NAME/skills"/*/; do
  mkdir -p "PROJECT_ROOT/.claude/skills/STACK_NAME/$(basename "$skill_dir")"
  cp "$skill_dir/SKILL.md" "PROJECT_ROOT/.claude/skills/STACK_NAME/$(basename "$skill_dir")/SKILL.md"
done
# commands — flat copy
cp "PLATFORM_HOME/stacks/STACK_NAME/commands/"*.md "PROJECT_ROOT/.claude/commands/" 2>/dev/null
echo "Stack STACK_NAME copied into project layer"
```

---

## Step 6 — Final summary

```
svelte  → PLATFORM_HOME/stacks/svelte/  (STACK.md, settings.json, 2 agents, 2 skills, 2 commands)  ✓
nestjs  → PLATFORM_HOME/stacks/nestjs/  (STACK.md, settings.json, 3 agents, 3 skills, 3 commands)  ✓
django  → SKIPPED (already installed)
xyz     → FAILED (no sources found)
```

---

## Hard rules

- The Python script is the ONLY component that fetches from the web — never fetch yourself
- Run the fetcher script ONCE with all stack names — never separately per stack
- ALL output goes to `PLATFORM_HOME/stacks/<name>/` — never to project folder, never to sdlc-atlas repo
- agents/ uses subfolder structure: `agents/<name>/AGENT.md` — never flat `.md` files directly in agents/
- skills/ uses subfolder structure: `skills/<name>/SKILL.md` — never flat `.md` files directly in skills/
- In the project layer agents/skills are ALWAYS grouped by stack: `agents/<stack>/<name>/AGENT.md`
- Do not retry the script more than once on failure
- Do not modify existing stacks when generating new ones
