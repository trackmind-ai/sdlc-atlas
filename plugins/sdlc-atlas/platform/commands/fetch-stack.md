---
name: fetch-stack
description: >-
  Generates a full L1 stack definition (agents, skills, commands, STACK.md,
  settings.json) from raw sources already fetched by stack-orchestrator.
  Run after stack_fetcher.py prints [OK] for a missing stack.
---

# /fetch-stack <SLUG>

**You are the stack author.** Your job is to read the raw sources and generate
a complete, production-quality L1 stack at `PLATFORM_HOME/stacks/SLUG/`.

---

## Step 1 — Locate files

Run in parallel:
```bash
echo "$HOME/.claude"
```

- PLATFORM_HOME = output above
- SLUG = the argument passed to /fetch-stack (e.g. `go`, `node`, `laravel`)
- RAW_SOURCES = `PLATFORM_HOME/stacks/SLUG/raw-sources.md`
- REFERENCE_STACK = `PLATFORM_HOME/stacks/django/` (structural reference — read STACK.md and one AGENT.md and one SKILL.md to understand the format)

Read RAW_SOURCES in full. Read the django reference files for format only.

---

## Step 2 — Plan the stack

From the raw sources, identify:
- **Primary framework** (e.g. Gin, Fiber, Echo for Go)
- **Agents needed** — one per distinct concern (API/routes, testing, DB/ORM, auth, etc.) — 2-4 agents typical
- **Skills needed** — one per reusable pattern (routing, middleware, testing, bootstrap) — 3-5 skills typical
- **Commands** — short invokers for common tasks (new-endpoint, new-handler, run-tests) — 2-4 commands

---

## Step 3 — Write all files in parallel

Fire ALL writes simultaneously (do not write one file then the next).

### Files to write:

**`PLATFORM_HOME/stacks/SLUG/STACK.md`**
```
# Stack: <NAME> (L1)
Installs into a project's `.claude/` via `install.sh --stack SLUG --project <path>`.
Project files win any filename collision. Declare `stack: SLUG` in project CLAUDE.md.
Provides: <agent list> + skills.
Defaults: test `<test cmd>`, security `<sec cmd>`, lint `<lint cmd>`.
```

**`PLATFORM_HOME/stacks/SLUG/settings.json`**
Framework bash permissions only — allow safe CLI commands, deny destructive ones.

**`PLATFORM_HOME/stacks/SLUG/agents/<agent-name>/AGENT.md`** (one per agent, each in own subfolder)
Frontmatter: name, description, tools, disallowedTools, model, memory, skills, permissionMode, maxTurns, effort, isolation, color.
Body: concise role — what it builds, what it refuses, what skill it loads. Max 12 lines.

**`PLATFORM_HOME/stacks/SLUG/skills/<skill-name>/SKILL.md`** (one per skill, each in own subfolder)
Frontmatter: name, description, when_to_use, disable-model-invocation, user-invocable, allowed-tools, model, effort, context.
Body: numbered/bulleted procedure covering the real patterns from raw sources. Max 15 lines.

**`PLATFORM_HOME/stacks/SLUG/commands/<cmd>.md`** (flat, no frontmatter)
One paragraph: what agent it invokes, what it refuses, what skill it uses. Max 5 lines.

---

## Step 4 — Run setup-stacks.sh to copy into project

After writing all platform stack files, run:
```bash
bash "PLATFORM_HOME/scripts/setup-stacks.sh" "PLATFORM_HOME" "PROJECT_ROOT" SLUG
```

If PROJECT_ROOT is not known (standalone /fetch-stack run), print:
```
[fetch-stack] Stack 'SLUG' written to PLATFORM_HOME/stacks/SLUG/
To install into a project run:
  bash "PLATFORM_HOME/scripts/setup-stacks.sh" "PLATFORM_HOME" "<your-project-path>" SLUG
```

---

## Step 5 — Print summary

```
[fetch-stack] ✔ Stack 'SLUG' generated

  PLATFORM_HOME/stacks/SLUG/
    STACK.md
    settings.json
    agents/  — <N> agents
    skills/  — <N> skills
    commands/ — <N> commands

  Agents: <list>
  Skills: <list>
```

---

## Hard rules

1. Read raw-sources.md fully before writing anything.
2. All writes fire in parallel — never sequentially.
3. Output goes to `PLATFORM_HOME/stacks/SLUG/` only — never inside a project folder, never inside sdlc-atlas repo.
4. Match django stack file structure exactly (subfolder per agent, subfolder per skill, flat commands).
5. Skills contain real patterns from raw sources — not generic placeholders.
6. After writing, always run setup-stacks.sh if PROJECT_ROOT is known.
