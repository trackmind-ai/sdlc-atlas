# sdlc-atlas Architecture

This document explains the design of sdlc-atlas: how its four layers work, what each layer owns, and how precedence is resolved when files overlap.

---

## The Four-Layer Model

sdlc-atlas is organized as four layers of customization and governance, each with clear ownership and change velocity:

### Layer 0 (L0) — Platform

**Location:** `platform/` in this repository

**Installs to:** `~/.claude/` (or `~/.cursor/` if targeting Cursor)

**Owned by:** sdlc-atlas maintainers

**Change velocity:** Quarterly (stable, well-tested)

**What it is:** The baseline agent set, skills, commands, and rules that every project starts with. This is the open-source core.

**Examples:**
- `platform/agents/orchestrator.md` — the main pipeline controller
- `platform/agents/spec-agent.md` — turns requirements into versioned specs
- `platform/agents/qa-agent.md` — live browser-based QA
- `platform/commands/feature.md` — full-lifecycle feature entry point
- `platform/CLAUDE.md` — the constitution (hard rules, tool list)

**Responsibility:** The platform defines what a capable agent-driven SDLC *looks like*. It does not know about your specific codebase, framework, or policies.

---

### Layer 1 (L1) — Stack

**Location:** `stacks/<name>/` in this repository (e.g. `stacks/react/`, `stacks/fastapi/`)

**Installs to:** Merged into a project's `.claude/` on first setup

**Owned by:** Stack maintainers (can be third-party)

**Change velocity:** Per framework release (new React version, new Django version)

**What it is:** Framework-specific customizations — agents that know how to test React apps, skills for Django migrations, commands for Next.js deployment, etc.

**Examples:**
- Stack-specific lint configs and test runners
- Framework-aware QA flows (browser tests for web stacks, Maestro flows for mobile)
- Stack-specific deployment commands
- Stack-specific knowledge (file structure, conventions, gotchas)

**Responsibility:** The stack teaches the platform how to work with a specific framework or language. It extends the platform's agents/skills/commands, never replacing them wholesale.

---

### Layer 2 (L2) — Organization

**Location:** `org-template/` in this repository (template for orgs to fork)

**Installs to:** A shared `<org-repo>/.claude-org/` that projects reference

**Owned by:** Organization platform team

**Change velocity:** Per policy change (compliance, security review processes, deployment approval flow)

**What it is:** Organization-wide rules, additional agents/skills/commands, and configuration that all projects in the org inherit.

**Examples:**
- Approval workflows (e.g. legal/security review gates before release)
- Naming conventions
- Deployment policies
- Org-wide skipped/required gates
- Vendor-specific tools (internal Slack bot, in-house Figma workspace, etc.)

**Responsibility:** The org layer ensures every project follows company policy without requiring every team to redefine it. It does not know about individual projects.

---

### Layer 3 (L3) — Project

**Location:** `<repo>/.claude/` in each project

**Installs to:** Same location

**Owned by:** Dev team

**Change velocity:** Constantly (specs, proposals, memory, state)

**What it is:** Project-specific decisions, work in progress, and runtime state. This is the only layer that changes during normal development.

**Examples:**
- `.claude/CLAUDE.md` — project-specific rules (overrides platform rules)
- `.claude/knowledge.md` — facts about *this* project (API endpoints, deploy targets, team names)
- `.claude/specs/` — approved feature specs (versioned, immutable)
- `.claude/proposals/` — in-flight capability proposals
- `.claude/memory/` — pipeline state, approval markers, gate results

**Responsibility:** The project layer is where work happens — specs are written, gates run, agents execute. It knows about *this* codebase and *this* team.

---

## Composition and Precedence

At runtime, all four layers merge into a single flat directory (`~/.claude/`). On a filename collision, the **most specific layer wins:**

```
project > org > stack > platform
```

Examples:

- **Project override:** Project has a `CLAUDE.md` that says "gates must run in this order instead." Its rules take precedence over platform/stack/org rules.
- **Org policy:** Org has a `skills/compliance-check.md` that runs during the release gate. It loads for every project that declares that org.
- **Stack customization:** Stack has `agents/qa-agent.md` with React-specific browser automation. It replaces the platform's generic qa-agent.

There is **no configuration or registration** — the system discovers files and merges them automatically.

---

## The Six Capability Types

Every layer can contribute any of these:

### 1. **Agents** (`agents/*.md`)

Named roles with judgment — they decide what to do, reason about tradeoffs, and ask clarifying questions. Examples: orchestrator, spec-agent, security-agent, qa-agent.

**File format:** Markdown with YAML frontmatter defining model, tools, reasoning effort, and permission mode.

**Governance:** Agents only change via `/approve-proposal` at any layer.

### 2. **Skills** (`skills/*.md`)

Reusable procedures that agents load — often deterministic, sometimes with decision points. Examples: "intake-validation" (check requirements completeness).

**File format:** Markdown with frontmatter listing when to load, what to teach, and any parameters.

**Governance:** Skills are lighter-weight than agents; a skill change may not require a full proposal, but policy and review still apply (per the layer's `CLAUDE.md`).

### 3. **Commands** (`commands/*.md`)

Entry points — the `/start`, `/feature`, `/raise-pr`, etc. that users invoke. Each command describes the workflow it orchestrates (what agents it spawns, in what order, with what gates).

**File format:** Markdown spec (no strict frontmatter; treated as prose documentation of the command's behavior).

**Governance:** Commands change via `/approve-proposal` (or platform release for L0).

### 4. **Knowledge** (`CLAUDE.md`, `knowledge.md`)

Uninferable facts and rules:
- `CLAUDE.md` — governance rules, permissions, hooks, tool lists
- `knowledge.md` — project-specific facts (this codebase uses Next.js, deploy targets are AWS, team members are X/Y/Z)

**File format:** Markdown (structured with sections and lists).

**Governance:** These are configuration files, not logic. Change them directly (with review) — no proposal needed.

### 5. **Policy** (`settings.json`, hooks)

Machine-readable configuration:
- `settings.json` — tool permissions, environment variables, MCP server configs
- Hooks in `settings.json` — pre/post-tool scripts that enforce rules (the approval-marker gate is a hook)

**File format:** JSON for `settings.json`, bash for hook scripts.

**Governance:** Policy changes may enforce new rules org-wide, so approval is required (platform and org layers).

### 6. **State** (`memory/`, `specs/`, `proposals/`)

What has happened — never committed to the platform/stack/org repos, only in projects:
- `memory/` — agent decisions, gate results, approval markers
- `specs/` — approved feature specs (immutable once approved)
- `proposals/` — draft proposals under review

**File format:** Markdown (specs and proposals), JSON (state).

**Governance:** State is generated and modified by agents/humans during pipeline runs. It's project-specific and never shipped upstream.

---

## How Layers Interact During a Feature Build

1. **User runs `/feature`** in their project.
2. **Platform orchestrator** (L0) loads and launches agents.
3. **Stack customizations** (L1) override platform agents if the stack provides them — e.g., `stacks/react/agents/qa-agent.md` replaces the platform's generic one for this React project.
4. **Org policies** (L2) inject additional gates or approval steps.
5. **Project rules** (L3) finalize behavior — e.g., if the project's `CLAUDE.md` says "skip the QA gate," that overrides everything.
6. **Spec is written, approved, and gated** — state goes into `.claude/specs/`.
7. **Code is written and gates run** (`scripts/run-gates.sh`) — results python into `.claude/memory/`.

---

## Key Design Decisions

### Why Four Layers?

- **L0 (Platform):** Stable, tested, shared across all projects using this SDLC.
- **L1 (Stack):** Domain-specific expertise (React, Django, etc.) without bloating the platform.
- **L2 (Org):** Policy and governance scale across teams without requiring per-project configuration.
- **L3 (Project):** The actual work happens here; this is the only layer that changes during development.

Fewer layers would force projects to repeat platform logic or bake org policy into every project. More layers would be needless complexity.

### Why Flat Merging, Not Composition?

The alternative would be a chain of responsibility (platform calls stack, which calls org, which calls project) or a module/import system. Instead, sdlc-atlas flattens everything and uses precedence rules. This avoids:
- Hidden dependencies (agent A calls skill B, which calls command C — hard to debug)
- Registration overhead (every new stack must register itself)
- Callback chains (when does org override platform? When does platform call org?)

By making collision explicit (most specific layer wins), we keep the system transparent and easy to reason about.

### Why Immutable Specs?

Once a spec is approved (`/approve-spec`), it becomes a decision record — it's not edited, only changed via new `<change>.md` files in the same feature folder. This ensures:
- **Auditability:** Every version of every decision is in git history.
- **Safety:** You can't accidentally lose a spec's original context if someone edits it later.
- **Clarity:** If a decision changed, that change is explicit (a new dated spec), not a silent edit.

### Why a Proposal Workflow for Capabilities?

Agents that could self-generate agents, skills, or commands would quickly lead to:
- Capability bloat (agents creating agents for every edge case)
- Unreviewed code (who tests the auto-generated agent?)
- Unpredictable behavior (two agents might create competing commands)

Instead, agents detect gaps, file proposals (`/propose`), and humans (or a designated approval process) decide whether a capability is worth adding. This keeps the platform intentional and well-maintained.

---

## Installation and Synchronization

### First-Time Setup

```bash
bash install.sh --platform                    # Install L0 + built-in stacks to ~/.claude/
bash install.sh --new-project <path> <stack> # Create a project, merging L0 + L1 + L2 (if org exists) into .claude/
```

### Keeping Projects Up to Date

```bash
bash install.sh --sync-project <path>  # Re-sync L0 + L1 + L2 into <path>/.claude/
bash install.sh --doctor <path>        # Report which files are stale (different from platform source)
```

The platform layer installs *once*, not auto-refreshed. To pull updates into an existing project, you must explicitly run `--sync-project`. This prevents surprise breakage while still allowing opt-in updates.

---

## Learn More

- `platform/CLAUDE.md` — the constitution (hard rules, tool lists, approval gates)
- `docs/ONBOARDING.md` — 15-minute setup walkthrough
- `docs/GOVERNANCE.md` — proposal rules and authority
- `docs/CAPABILITY-MATRIX.md` — the 6 types × 4 layers in one table
- `docs/PROMOTION.md` — how capabilities move between layers (platform to org to project)
- Individual agent specs in `platform/agents/` — how each agent works

---

**Architecture locked as of:** 2026-07-22

Changes to this architecture require RFC (request-for-comment) and `/approve-proposal` at the platform level.
