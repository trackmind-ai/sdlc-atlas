# sdlc-atlas

[![CI](https://github.com/trackmind-ai/sdlc-atlas/actions/workflows/ci.yml/badge.svg)](https://github.com/trackmind-ai/sdlc-atlas/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An agent-driven SDLC platform for Claude Code. It takes a requirement to production-ready code
through a **governed** pipeline: versioned specifications, human approval gates, and quality
gates that run in a fixed order and stop at the first failure.

The governance is the point. Agents here cannot write production code until a human has
approved a spec — enforced by a hook, not by an instruction an agent might ignore.

## Install

Register Trackmind's marketplace once per machine, then install:

```text
/plugin marketplace add trackmind-ai/marketplace
/plugin install sdlc-atlas@trackmind
```

The first command is a **one-time step**; installing other Trackmind plugins later needs only
the second. Re-running the first is harmless — it is idempotent.

> **If `marketplace add` fails with a host-key error:** the `owner/repo` shorthand clones over
> SSH, which fails on a machine that has never trusted GitHub's SSH host key. Set
> `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`, or pass the full HTTPS URL.

<details>
<summary>Alternative: install without the plugin manager</summary>

Useful if you want the installer's project scaffolding and `--doctor` checks, which the plugin
manager does not provide.

```bash
git clone https://github.com/trackmind-ai/sdlc-atlas.git
cd sdlc-atlas/plugins/sdlc-atlas

# Platform only — installs 23 agents, 43 commands, 42 skills and 11 stacks into ~/.claude/
bash install.sh --platform

# Or platform + a project in one shot, with stacks merged and a CLAUDE.md seeded:
bash setup-all.sh --project /path/to/my-repo --stacks react,node --profile standard
```

`setup-all.sh` runs six steps and ends with a health check. A clean run finishes with `DONE`;
anything else prints exactly what to fix.

Useful follow-ups:

```bash
bash install.sh --doctor /path/to/my-repo        # what is stale or missing (changes nothing)
bash install.sh --sync-project /path/to/my-repo  # pull current platform into that project
bash install.sh --platform --target cursor       # same layers into ~/.cursor/ instead
```

Windows: use Git Bash for these, or `.\setup.ps1 -Project C:\path\to\repo -Stack python`.
</details>

### What lands where

| Location | Contents |
|---|---|
| `~/.claude/` | 23 agents, 43 commands, 42 skills, 11 stacks, `settings.json` |
| `<repo>/.claude/` | `CLAUDE.md`, `settings.json` with the approval hook, stack agents/skills, `memory/`, `proposals/` |

Installing the platform refreshes only `~/.claude/`. Projects keep their own copy — see
[Keeping projects current](#the-four-layers) below.

## Start here

```text
/start
```

One entry point. It interviews you one question at a time, then routes to the right pipeline —
greenfield build or brownfield feature work — and hands off between agents automatically.

For an existing codebase, run `/audit-project` first: it reads the repository and writes an
accurate `CLAUDE.md` and `knowledge.md` before any pipeline runs.

## How a feature flows

```text
/feature → requirements → spec → [ YOUR APPROVAL ] → build → gates → PR
                                        │
                      /approve-spec ────┘

gates:  ┌ test ─────┐
        ├ security ─┤ in parallel → build → browser QA → LLM review
        └ lint ─────┘
```

Nothing reaches your production code before the approval marker exists. Gates 1–3 run in
parallel and the pipeline stops if any fails; the later gates are sequential because each
depends on the previous one's output. A phase counts as complete only when no gate row is left
`PENDING` or `FAIL` — including the browser-QA row, which is mandatory for frontend stacks.

## The four layers

| Layer | Folder | Installs to | Owned by |
|---|---|---|---|
| **L0 Platform** | `platform/` | `~/.claude/` | Trackmind |
| **L1 Stack** | `stacks/<name>/` | merged into project `.claude/` | Stack maintainers |
| **L2 Organization** | `org-template/` | referenced by projects | Your platform team |
| **L3 Project** | `projects/<name>/` | `<repo>/.claude/` | Your dev team |

Everything merges flat at runtime. On a filename collision the more specific layer wins:
**project > org > stack > platform.** Lower layers may only tighten a rule, never loosen it.
No registration, no config.

Each layer can contribute any of six capability types: **agents** (roles with judgment),
**skills** (procedures agents load), **commands** (entry points like `/feature`), **knowledge**
(`CLAUDE.md`), **policy** (`settings.json` and hooks), and **state** (`memory/`, `specs/`).

> ⚠ `install.sh --platform` refreshes only `~/.claude/`. It does **not** update projects you
> already set up — each keeps its own copy. Use `install.sh --doctor <path>` to see what is
> stale and `--sync-project <path>` to update it. Forgetting this is the most common way a
> project silently runs old agent logic.

## What's included

**23 agents** across the lifecycle — requirements, architecture, spec, bootstrap, test,
security, review, docs, release, QA, retro, and more. **43 commands**, **42 skills**, and
**10 supported stacks**:

| Category | Stacks |
|---|---|
| Frontend | `react` · `nextjs` · `angular` · `vue` |
| Backend | `node` · `nestjs` · `python` · `fastapi` |
| Data / Infra | `postgresql` · `docker` |

Need something else? `/fetch-stack <name>` generates a stack definition on demand via the
bundled stack-orchestrator.

Three service profiles scale the ceremony to the work: **small** (spec + build + tests),
**standard** (adds security, review, docs), **enterprise** (adds architecture, ADRs,
acceptance-criteria traceability, post-mortems).

## Documentation

| Document | What it covers |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layer model, composition, design rationale |
| [docs/WALKTHROUGH.md](docs/WALKTHROUGH.md) | A feature end to end |
| [docs/ONBOARDING.md](docs/ONBOARDING.md) | Getting a team started |
| [docs/CAPABILITY-MATRIX.md](docs/CAPABILITY-MATRIX.md) | Every agent, skill, and command |
| [docs/GOVERNANCE.md](docs/GOVERNANCE.md) | Capability governance inside the pipeline |
| [GOVERNANCE.md](GOVERNANCE.md) | How this project is run |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution lanes and local setup |
| [SECURITY.md](SECURITY.md) | Threat model and reporting |

## Requirements

- [Claude Code](https://claude.com/claude-code)
- `bash` (Git Bash on Windows), `git`
- Python 3.9+ *(only to develop this repo, not to use it)*

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). It describes four lanes with
different review depth, and why agent and skill files get the most scrutiny: they are executable
instructions, not documentation.

Docs fixes are the easiest place to start, and telling us where the docs misled you is genuinely
useful.

## Security

Agents in this platform read code, run commands, and write files. [SECURITY.md](SECURITY.md)
states the threat model plainly — what counts as a vulnerability, what is expected behavior, and
how to reduce your own exposure. Please report vulnerabilities privately, never in a public issue.

## License

MIT — see [LICENSE](LICENSE). Copyright © 2026 Trackmind.
