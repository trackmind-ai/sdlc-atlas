---
name: capabilities
description: >-
  Show the tools, skills, and permissions available to each agent (and what the
  project settings.json allows/denies). Read-only inventory — no changes made.
---
# /capabilities

Print a clear inventory of what every agent and skill can do. Make NO changes.

## Step 0 — Roots

```bash
pwd
echo "$HOME/.claude"
```
- **PROJECT_ROOT** = first  ·  **PLATFORM_HOME** = second

## Step 1 — Collect agents

List agent files from project first, then platform (project overrides platform):

```bash
ls "PROJECT_ROOT/.claude/agents/" 2>/dev/null
ls "PLATFORM_HOME/agents/" 2>/dev/null
```

For each agent, read its YAML frontmatter and extract:
`name`, `tools`, `disallowedTools`, `permissionMode`, `model`, `skills`.

## Step 2 — Collect skills

```bash
ls "PROJECT_ROOT/.claude/skills/" 2>/dev/null
ls "PLATFORM_HOME/skills/" 2>/dev/null
```
For each skill read `name` + `description` (first line).

## Step 3 — Collect effective permissions

Read `PROJECT_ROOT/.claude/settings.json` `permissions.allow` and `permissions.deny`.
These apply to ALL agents on top of each agent's `tools` list.

## Step 4 — Render

Print three tables. Tools NOT listed in an agent's `tools` are unavailable to it.

### Agents
```
| Agent | Tools | Disallowed | Permission mode | Skills |
|-------|-------|-----------|-----------------|--------|
| orchestrator | Read, Grep, Glob, Task, Bash | Write, Edit | ask | spec-paths, agent-handoff, … |
| spec-agent   | Read, Grep, Glob, Write, Edit | Bash | ask | spec-writing, … |
| …            |       |           |                 |        |
```

### Skills
```
| Skill | Purpose |
|-------|---------|
| interaction-style | numbered + attributed questions, Decide Later, progress |
| agent-handoff     | context bundle so nothing is re-asked |
| …                 |         |
```

### Project permissions (settings.json — applies to every agent)
```
Allow: Read(*), Grep(*), Glob(*), Bash(git status), Bash(npm test*), …
Deny:  Bash(git push --force*), Bash(rm -rf /*), Edit(.env*), …
```

## Step 5 — Summary line

```
Legend: an agent can use a tool only if it is in its `tools` list AND not blocked
by settings.json deny. permissionMode=ask → prompts before acting; the project
permission profile (knowledge.md: permissions_profile) controls how often.
Run /setup or edit .claude/settings.json to change permissions.
```

Do not modify any file. This command is purely informational.
