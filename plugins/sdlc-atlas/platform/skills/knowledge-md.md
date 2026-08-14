---
name: knowledge-md
description: >-
  How to read, validate, update, and write knowledge.md — the committed per-repo
  living document that owns all project-specific additions to the SDLC. Covers
  uninferable facts AND the project registry (agents, skills, routing, tech leads,
  built features). CLAUDE.md references this file for sections 4.4, 5.3, 5.4
  (project routing), 6.3, 7, 11, 12, and 14. Use at the start of every pipeline
  run and whenever new project-specific facts surface mid-conversation.
---
# knowledge.md

Location: `<repo>/knowledge.md` (committed with the code — not gitignored).

The orchestrator reads this file at startup alongside CLAUDE.md. It owns two
distinct types of content:

## Type 1 — Uninferable facts (§ Uninferable facts)

Facts a developer could NOT infer by reading every file.

**Inclusion test**: "Would a developer who read every file but never saw the work
item make a wrong assumption about this?" No → don't write it.

Format — terse bullets, categorised:
- `[nav]` where things live, when non-obvious
- `[constraint]` external rules invisible in code (e.g. "DBA team owns DDL — this
  service never runs migrations")
- `[correction]` fixes to plausible-but-wrong inferences

**On read, validate**: `[nav]` path gone → delete; `[constraint]` referent gone →
delete; `[correction]` now obvious from code → delete. Report prunings.

**Write during the conversation**, not at the end. Never store: feature scope
(belongs in spec), facts about other repos, anything readable from an import,
config, or schema, secrets of any kind.

## Type 2 — Project registry sections

These sections are owned here so CLAUDE.md stays lean:

| Section | What it holds | Updated by |
|---|---|---|
| § Project commands | L3 commands from `.claude/commands/` | /approve-proposal |
| § Project domain agents | L3 agents not in stack or platform | orchestrator Phase 6 |
| § Project routing | YAML routing for project domain agents | orchestrator Phase 6 |
| § Project skills | L3 skills from gap analysis or proposals | spec-agent / Phase 6 |
| § Tech leads | List of handles with /approve-proposal authority | /onboard or manual |
| § Org policy | Org policy repo/branch/file (enterprise) | /onboard or manual |
| § Built features | Rich entry per shipped feature | orchestrator Phase 6 |

## Built features — minimum required per entry

A one-line built features entry is a documentation failure. The orchestrator reads
this section to know what already exists — a thin entry causes it to treat that
domain as unbuilt, leading to duplicate implementation.

Every entry must include:
- **What it does** — 2–4 sentences for someone new to the codebase
- **Key files** — file path with line anchor + role
- **Data models** — model name, file:line, key fields
- **API endpoints** — method, path, auth, description
- **Background tasks** — if any: name, file:line, purpose, retry policy
- **Key decisions** — what was chosen + why the alternative was rejected
- **Tests** — file path, count, what is covered
- **Dependencies / integrations** — external services or sibling features relied on

## Read order at pipeline startup

1. Read `CLAUDE.md` for project identity, stack, quality gates, platform/stack agents and skills
2. Read `knowledge.md` for project-specific agents, skills, routing, facts, and built features
3. Validate: check for stale `[nav]` paths and `[constraint]` referents
4. Report any prunings before proceeding
