# Stack: stack-orchestrator (L1 — dynamic stack generator)

Installs into a project's `.claude/` via `install.sh --stack stack-orchestrator --project <path>`.
Project files win any filename collision. This stack has no `stack:` declaration of its own —
it is the mechanism that generates other L1 stacks on demand.

## What this stack does

Unlike `django` or `node` (which provide pre-authored agents/skills/commands for one technology),
`stack-orchestrator` is a **full-stack generator**: given any framework name, it fetches live
rules from the web and generates a complete L1 stack directory at `stacks/<name>/` — the same
structure as `stacks/django/`, with STACK.md, settings.json, agents/, skills/, and commands/.

The generated stack is then usable identically to a hand-authored stack:
  `bash install.sh --stack <name> --project <path>`

## What gets installed into a project

| Component | Location after `--stack stack-orchestrator` | Purpose |
|---|---|---|
| `bin/stack_fetcher.py` | `.claude/bin/stack_fetcher.py` | Fetcher engine — parallel HTTP, 5 source types |
| `commands/fetch-stack.md` | `.claude/commands/fetch-stack.md` | `/fetch-stack` command |
| `settings.json` (merged) | `.claude/settings.json` | SessionStart + InstructionsLoaded hooks |

## What `/fetch-stack <name>` generates at `stacks/<name>/`

```
stacks/<name>/
├── STACK.md                          # one-paragraph description
├── settings.json                     # framework-specific allow/deny bash permissions
├── agents/
│   ├── api-agent/
│   │   └── AGENT.md                  # one subfolder per agent, file always AGENT.md
│   ├── migration-agent/
│   │   └── AGENT.md
│   └── ...
├── skills/
│   ├── <stack>-bootstrap/
│   │   └── SKILL.md                  # one subfolder per skill, file always SKILL.md
│   ├── <endpoint-skill>/
│   │   └── SKILL.md
│   └── ...
└── commands/
    ├── new-endpoint.md               # flat .md files (no subfolders)
    └── ...
```

Output path is always `stacks/<name>/` — a sibling of `stack-orchestrator/`, never inside it.

## Hooks (automatic detection)

Two hooks run `bin/stack_fetcher.py --detect` on every session:
- **SessionStart** — fires when any Claude Code session opens
- **InstructionsLoaded (CLAUDE.md)** — fires when project CLAUDE.md is loaded

The detector reads `stack: "<name>"` from CLAUDE.md. If `stacks/<name>/` is missing,
it prints: `Run: /fetch-stack <name>`. Always exits 0 — never blocks a session.

## Defaults

This stack adds no test/security/lint defaults — those are set by the generated stack or the project.
