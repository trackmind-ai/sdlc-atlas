---
name: start
description: >-
  Single entry point for sdlc-atlas. One question at a time interview,
  parallel writes, automatic agent handoffs. Use /start instead of memorizing
  setup-all.sh flags.
---

# /start

**You are the session lead.** Never ask the developer to run shell setup commands.
You and sub-agents do all work via PLATFORM_HOME + Write/Bash inside PROJECT_ROOT.

**ONE QUESTION PER MESSAGE — always. Never combine multiple questions into one message.
Wait for the reply before asking the next question.**

**Dispatched agents (forge-agent, product-strategy-agent, ux-research-agent, etc.)
are NEVER "non-interactive" or "background" — they are part of this live conversation.
Never instruct a dispatched agent to assume answers, skip questions, or run without
the user. Any question a sub-agent needs answered must be relayed to the user via
AskUserQuestion and the answer relayed back. This applies regardless of how the
dispatch is framed (Task call, "background run", etc.).**

---

## Step 0 — Caveman check (MANDATORY — before anything else)

```bash
cat "$HOME/.claude/.caveman-active" 2>/dev/null || echo "NOT_INSTALLED"
```

If NOT_INSTALLED or empty:
If NOT_INSTALLED or empty:

1. Print exactly:
   ```
   [start] Caveman plugin not detected.
   Caveman cuts token usage ~75% and makes every agent faster. Install it now? (yes / no)
   ```
2. Wait for reply.
   - If **no** → print `Cannot proceed without caveman. Run /start again after installing.` and STOP.
   - If **yes** → detect OS and run the correct installer:

```bash
uname -s 2>/dev/null || echo "Windows"
```

- If output contains `Windows`, `MINGW`, or `CYGWIN` → run PowerShell:
  ```powershell
  irm https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.ps1 | iex
  ```
- Otherwise (macOS / Linux / WSL) → run:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
  ```

After installer completes, re-check:

```bash
cat "$HOME/.claude/.caveman-active" 2>/dev/null || echo "NOT_INSTALLED"
```

- If now active → print `✔ Caveman installed — continuing.` and proceed to Step 0b.
- If still NOT_INSTALLED → print `Install did not complete. Please restart Claude Code and run /start again.` and STOP.

---

## Step 0b — Establish roots

Run both in parallel:

```bash
pwd
echo "$HOME/.claude"
```

- **PROJECT_ROOT** = first output (overridden by developer's Q1 answer)
- **PLATFORM_HOME** = second output

**Determine TARGET (no question asked — this is a fact about the running
session, not something to ask the developer or infer from disk):**
- `TARGET` = `cursor` if this `/start` invocation is executing inside a
  Cursor agent session, else `TARGET` = `claude` (the default — this covers
  Claude Code CLI and is the only behavior that existed before this check).
- `LAYER_DIR` = `.cursor` if `TARGET=cursor`, else `.claude`.
- These are session-local values, not persisted to any project file. Every
  `PROJECT_ROOT/.claude/...` path referenced anywhere below in this command
  means `PROJECT_ROOT/$LAYER_DIR/...` — read `.claude/` in this document as
  shorthand for "the LAYER_DIR established here," not a literal-always path.
- **Known scope limit**: this affects `/start`'s OWN scaffolding only. Other
  platform agents dispatched later in the pipeline (ux-research-agent,
  design-concept-agent, bootstrap-agent, forge-agent, qa-agent) currently
  hardcode `PROJECT_ROOT/.claude/memory/...` literally. If `TARGET=cursor`,
  pass `layer_dir: LAYER_DIR` explicitly in every Task dispatch to those
  agents' Inputs (see A-Forge below) so they can be told which memory path
  to use — until those agent files are themselves updated to read
  `layer_dir` from their inputs, treat this as a known limitation, not a
  silent success; note it to the developer once if `TARGET=cursor`:
  `[start] Note: Cursor-targeted memory-path support is partial — some
  downstream pipeline agents may still expect .claude/. If you hit a
  "file not found" error referencing .claude/memory/, that's this gap.`

---

## Step 0c — QA tooling check (MANDATORY — before anything else, including Step 1's menu)

Every project this platform builds eventually needs live browser/mobile QA
(qa-agent's E2E Journey + per-screen audit, Phase 5a). Checking for that
tooling only at Phase 5a — after the whole app is scaffolded and built — is
too late to be useful; if it's missing then, the discovery interrupts a
finished pipeline instead of preventing wasted work. This gate makes sure
the tooling is confirmed present (or the developer has explicitly accepted
the tradeoff of proceeding without it) before a single interview question
is asked.

**Host assumption:** this gate assumes Claude Code CLI (the `claude mcp`
subcommand). Cursor and other hosts are not yet supported by this check —
see the open host-detection proposal (P-001) for that separate gap. If the
`claude` CLI itself is not present (see step 2 below), do not guess at a
host-specific install path; ask the developer to confirm their host and
tooling manually instead.

1. Check what's already connected:
   ```bash
   claude mcp list 2>&1 | grep -Ei 'chrome-devtools|maestro'
   ```

2. If the `claude` command itself is not found (non-Claude-Code host, or
   CLI not on PATH):
   ```
   [start] Could not run `claude mcp list` — this check assumes the Claude
   Code CLI. If you're on a different host (e.g. Cursor), QA tooling setup
   isn't automated here yet.
   Please confirm: are you running this inside Claude Code CLI? (yes / no)
   ```
   - **no** → print `This platform's automated QA tooling setup currently
     only supports Claude Code CLI. Please set up Chrome DevTools MCP /
     Maestro MCP manually for your host, or switch to Claude Code CLI, then
     run /start again.` and STOP.
   - **yes** (claude CLI should be present but the command still failed) →
     print `⚠ 'claude' command not found on PATH despite confirming Claude
     Code CLI — please verify your Claude Code installation, then run
     /start again.` and STOP.

3. For each tool relevant to a general-purpose greenfield build (default:
   check both — a project's actual stack, web vs mobile vs both, isn't known
   yet at this point in `/start`, so check both up front rather than guessing):

   - **Chrome DevTools MCP listed as `✔ Connected`** → note `web_qa: ready`.
   - **Maestro MCP listed as `✔ Connected`** → note `mobile_qa: ready`.
   - **Either missing entirely** → do NOT silently skip it. Print:
     ```
     [start] QA tooling check:
       Chrome DevTools MCP (web QA):   <✔ ready | ✘ missing>
       Maestro MCP (mobile QA):        <✔ ready | ✘ missing>

     This platform requires live browser/mobile QA tooling before building a
     frontend — qa-agent cannot audit or fix UI issues without it, and per
     platform policy Phase 5a QA is mandatory and cannot be skipped for
     frontend-stack projects. Install missing tooling now? (yes / no)
     ```
   - **yes** → install each missing tool, same commands qa-agent Step -1 uses:
     ```bash
     # Chrome DevTools MCP (web) — only if missing
     claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp@latest
     ```
     ```bash
     # Maestro MCP (mobile) — only if missing; installs the Maestro CLI first if absent
     command -v maestro > /dev/null 2>&1 || curl -fsSL "https://get.maestro.mobile.dev" | bash
     claude mcp add maestro -- maestro mcp
     ```
     After installing, re-check:
     ```bash
     claude mcp list 2>&1 | grep -Ei 'chrome-devtools|maestro'
     ```
     - **Still missing after install attempt** → print the exact failing
       command's output, then: `⚠ Automated install did not complete. Please
       install manually (see qa-agent.md Step -1 for the exact commands),
       then run /start again.` and STOP. Do not proceed to Step 1 with QA
       tooling still absent and unacknowledged.
     - **Newly connected** → **MCP servers only attach at session start**, same
       constraint as qa-agent Step -1. Print exactly:
       ```
       ✔ <tool> MCP installed and configured, but needs a session restart to
       activate — MCP servers only connect at startup.
       Please restart Claude Code (or run /mcp to reconnect), then run
       /start again to continue.
       ```
       End the turn. Do not proceed to Step 1 in the same session as a
       fresh MCP install — it will not actually be connected yet regardless
       of what `claude mcp add` reported.
   - **no** (developer declines install) → this is an explicit, informed
     choice to proceed without QA tooling, not a silent gap. Print:
     ```
     ⚠ Proceeding without <missing tool(s)> — qa-agent's Phase 5a gate will
     fail or be unable to run its E2E Journey/per-screen audit later. You'll
     need to install this before that gate can pass. Continuing at your
     request.
     ```
     Record this acknowledgement in `context_bundle.md` (`qa_tooling:
     web=<ready|declined>, mobile=<ready|declined>`) so forge-agent/qa-agent
     don't re-litigate it, and proceed to Step 1.
   - **Both already `✔ Connected`** → print `✔ QA tooling ready (Chrome
     DevTools MCP + Maestro MCP).` and proceed to Step 1 silently otherwise
     (no need to re-ask anything).

This check runs ONCE per `/start` invocation (fresh session), same rule as
qa-agent Step -1's own session-start check — do not re-run it mid-session
if `/start` is resumed via Branch C without a fresh session start.

---

## Step 1 — Main menu

Print exactly, then wait for ONE reply:

```
[start] Welcome to sdlc-atlas.

What do you want to do?
  a) New project (greenfield)
  b) Existing project (brownfield — already has code)
  c) Resume last session
  d) Build a feature (project already set up)
```

---

## Branch A — New project <!-- reply: a -->

Ask questions ONE AT A TIME. Each question = one message → wait for reply → next question.
Never combine. Never skip ahead. Questions are written below verbatim.

---

### Q1 — Project folder path

```
[start] Q1 / 12 — Where should the project live?
Full path (e.g. C:\Users\you\projects\my-app  or  /home/you/projects/my-app):
```

On reply:

- Must be absolute path. Must NOT contain "sdlc-atlas" or "AgenticAI-SDLC" (the platform checkout, not a project). If invalid → re-ask Q1.
- Set PROJECT_ROOT = validated path.
- Run all mkdir in parallel (fire simultaneously, do not wait). Structure
  depends on `TARGET` from Step 0b:

**If TARGET = claude** (default — unchanged from before):
```bash
mkdir -p "PROJECT_ROOT/.claude/memory/approvals"
mkdir -p "PROJECT_ROOT/.claude/specs"
mkdir -p "PROJECT_ROOT/.claude/proposals"
mkdir -p "PROJECT_ROOT/.claude/agents"
mkdir -p "PROJECT_ROOT/.claude/skills"
mkdir -p "PROJECT_ROOT/.claude/commands"
```

**If TARGET = cursor** (mirrors `platform/converters/cursor.sh`'s layout —
flat agents, `skills/<name>/SKILL.md`, `rules/*.mdc` instead of `CLAUDE.md`,
`mcp.json` instead of `settings.json`; `memory/`, `specs/`, `proposals/` are
project-owned state, not part of the tool-specific layer, so they keep the
same names/shape either way):
```bash
mkdir -p "PROJECT_ROOT/.cursor/memory/approvals"
mkdir -p "PROJECT_ROOT/.cursor/specs"
mkdir -p "PROJECT_ROOT/.cursor/proposals"
mkdir -p "PROJECT_ROOT/.cursor/agents"
mkdir -p "PROJECT_ROOT/.cursor/skills"
mkdir -p "PROJECT_ROOT/.cursor/commands"
mkdir -p "PROJECT_ROOT/.cursor/rules"
```

---

### Q2 — Project name

```
[start] Q2 / 12 — Project name?
```

Wait for reply, store as PROJECT_NAME.

---

### Q3 (Brainstorm 1) — App Concept & Ideation

```
[start] Q3 / 12 [Brainstorm] — Summarize your core app idea, business goal, and any immediate thoughts on user interaction:
```

Wait for reply, store as BRAIN_GOAL.

---

### Q4 (Brainstorm 2) — Technical Constraints

```
[start] Q4 / 12 [Brainstorm] — Any key non-functional constraints? (e.g. database choice, integrations, performance requirements, or "skip"):
```

Wait for reply, store as BRAIN_CONSTRAINTS.
Immediately compile the brainstorming answers into a bulleted format and write to `PROJECT_ROOT/LAYER_DIR/memory/brainstorm_notes.md`.

---

### Q5 — What it does

```
[start] Q5 / 12 — What does it do? (one sentence, or press Enter to use brainstorm summary)
```

Wait for reply, store as PROJECT_DESCRIPTION. If skipped, build a one-sentence summary from BRAIN_GOAL.

---

### Q6 — Project type

```
[start] Q6 / 12 — Project type?
  a) Web app (frontend + backend + DB)
  b) API only
  c) Frontend only
  d) CLI / script
  e) Mobile app
  f) Other
```

Wait for reply, store as PROJECT_TYPE.

---

### Q7 — Stack

```
[start] Q7 / 12 — Tech stack?
  Backend:   FastAPI · Django · Express · NestJS · Go/Gin · none
  Frontend:  React · Next.js · Angular · Vue · Svelte · none
  Database:  Postgres · MySQL · MongoDB · SQLite · Redis · none
  Extras:    Celery · Docker · S3 · Clerk · Stripe · none

Type each on a separate line, or type "skip" to decide later.
```

Wait for reply. Parse into STACK_NAMES list (slugs). Extract the database selection from the answer (e.g. Postgres -> postgres, MySQL -> mysql, MongoDB -> mongodb, SQLite -> sqlite, Redis -> redis, None -> none) and assign to DATABASE_SLUG (default to "none"). PRIMARY_STACK = first backend slug.

---

### Q8 — Pipeline profile

```
[start] Q8 / 12 — Pipeline profile?
  a) small      — spec + build + 3 gates  (solo / prototype)
  b) standard   — + requirements + code review  (recommended)
  c) enterprise — all phases + ADRs + compliance
```

Wait for reply, store as PROFILE.

---

### Q9 — Test strategy

```
[start] Q9 / 12 — Test strategy?
  a) pytest --cov=app --cov-report=term-missing
  b) npm test -- --watchAll=false
  c) go test ./...
  d) skip

  Also — how strict should the test gate be?
  1) Standard — 70% coverage, tests must pass, browser QA required for any frontend screen (recommended default)
  2) Strict — 85%+ coverage, tests must pass, zero tolerance on skipped browser QA
  3) Light — tests must pass, no coverage floor (fastest iteration, less safety)
```

Wait for reply. Parse into TEST_CMD (a/b/c/d) and TEST_STRICTNESS (1/2/3).
Derive COVERAGE_THRESHOLD from TEST_STRICTNESS: 1→70, 2→85, 3→0.
If TEST_CMD = skip → COVERAGE_THRESHOLD is still recorded (it activates the
moment a test command is added later) but print a one-line note: "No test
command yet — the coverage/strictness choice is saved and will apply once you
add one."

This choice is not cosmetic — it sets `## Quality gates § tests.coverage_threshold`
in `CLAUDE.md`, which `test-agent` enforces on every `/feature` build from now
on, and it does NOT weaken the mandatory browser-QA gate (gate 4 in
`run-gates.sh` is mandatory for any frontend stack regardless of this
answer — "Light" only relaxes the coverage number, never the QA requirement).

---

### Q10 — Security scan

```
[start] Q10 / 12 — Security scan?
  a) npm audit / pip-audit  (dependency)
  b) bandit / semgrep  (SAST)
  c) gitleaks  (secrets)
  d) trivy  (container)
  e) skip
```

Wait for reply, store as SECURITY_CMD.

---

### Q11 — Lint command

```
[start] Q11 / 12 — Lint command?
  a) ruff check .
  b) npx eslint . && npx tsc --noEmit
  c) golangci-lint run
  d) skip
```

Wait for reply, store as LINT_CMD.

---

### Q12 — Tech leads

```
[start] Q12 / 12 — Tech leads? (GitHub/Slack handles, or "solo")
```

Wait for reply, store as TECH_LEADS.

### After Q12 — Setup stacks & write config

Run the setup script (substitute real values, always pass `--target`):

```bash
bash "PLATFORM_HOME/scripts/setup-stacks.sh" "PLATFORM_HOME" "PROJECT_ROOT" STACK_SLUG1 STACK_SLUG2 ... --target TARGET
```

If `TARGET=cursor` and the script exits with `TARGET_UNSUPPORTED: ...`
(the `platform/converters/cursor.sh` converter isn't present at
`PLATFORM_HOME/converters/cursor.sh` — it only lands there via
`install.sh --platform` run from the sdlc-atlas repo checkout), print
that exact message to the developer, then STOP this branch and ask: `Would
you like to proceed with TARGET=claude instead for this project? (yes /
no)` — **yes** falls back to `TARGET=claude`/`LAYER_DIR=.claude` and
continues; **no** ends the `/start` run here.

Read every output line:

- `NEEDS_FETCH: SLUG` → invoke `/fetch-stack SLUG`, then re-run setup-stacks.sh.
- `FETCH_FAILED: SLUG` → print warning, continue without that stack.
- Wait until every slug shows `stack-done: SLUG`.

Then **write all config files in parallel** (all Write tool calls simultaneously).
Shape depends on `TARGET`:

**If TARGET = claude** (unchanged from before):
1. `PROJECT_ROOT/.claude/CLAUDE.md` — fill from all answers (resolve `{{DATABASE}}` to the selected `DATABASE_SLUG` e.g. `sqlite`, `postgres`, etc.; resolve `{{COVERAGE_THRESHOLD}}` to the value derived from Q9's TEST_STRICTNESS — 70/85/0, never a hardcoded 0 regardless of what the user actually chose)
2. `PROJECT_ROOT/.claude/knowledge.md` — fill from all answers
3. `PROJECT_ROOT/.claude/memory/orchestrator_state.md` — initial state
4. `PROJECT_ROOT/.claude/memory/context_bundle.md` — all answers recorded here

**If TARGET = cursor** (mirrors `cursor_write_rule`'s output shape — same
content, `.mdc` frontmatter wrapper instead of a bare markdown file):
1. `PROJECT_ROOT/.cursor/rules/00-platform.mdc` — same fill as CLAUDE.md
   above, wrapped with `---\ndescription: 00-platform (converted from
   sdlc-atlas platform source)\nalwaysApply: true\n---` frontmatter
   per `cursor_write_rule`'s convention
2. `PROJECT_ROOT/.cursor/knowledge.md` — fill from all answers (plain
   markdown, not a rule — knowledge.md is project-owned state, read by
   agents directly, not a Cursor auto-apply rule)
3. `PROJECT_ROOT/.cursor/memory/orchestrator_state.md` — initial state
4. `PROJECT_ROOT/.cursor/memory/context_bundle.md` — all answers recorded
   here, plus record `target: cursor` explicitly in this file so any
   later-dispatched agent reading context_bundle.md knows to use
   `.cursor/` paths for its own reads/writes until those agents are
   themselves updated to take `layer_dir` as an explicit input
5. `PROJECT_ROOT/.cursor/mcp.json` — only if it doesn't already exist:
   `{"mcpServers": {}}` (empty skeleton, per `cursor_write_mcp` — this repo
   has no MCP servers declared per-stack yet; Step 0c's Chrome DevTools/
   Maestro MCP install still goes through `claude mcp add` regardless of
   TARGET, since that's a Claude Code CLI session-level concept, not a
   per-project file, and this platform's automated QA-tool install has no
   Cursor equivalent yet — see Step 0c's own host-assumption note)

Print:

```
[start] ▸ Setup done ✔  Project: <name> · Stack: <stacks> · Profile: <profile>
```

Then go to **A-ADO** before A-Forge.

---

### A-ADO — Azure DevOps integration (optional, one-time)

Ask **one question**:

```
[start] Do you want to connect Azure DevOps so /feature can fetch work items by ID? (yes / no)
```

If **no** → skip to A-Forge.

If **yes** → invoke the Skill tool with name `ado-setup` (resolves from
`PLATFORM_HOME/skills/ado-setup.md`). Do not conclude the skill is missing based
on the project layer alone — check `PLATFORM_HOME/skills/` before filing any gap
proposal. When the skill completes, go to A-Forge.

---

Then go to **A-Forge**.

---

### A-Forge — Launch Forge

Print `→ forge-agent` then dispatch `forge-agent` via Task:

```
Agent: forge-agent
Inputs:
  project_root: PROJECT_ROOT
  platform_home: PLATFORM_HOME
  layer_dir: LAYER_DIR
  context_bundle: PROJECT_ROOT/LAYER_DIR/memory/context_bundle.md
  planning_only: true

Task:
  Read context_bundle.md first — do not re-ask anything already answered there.
  Run only the planning phase of the forge pipeline per forge-agent.md — Phases 1-6 in order:
    Phase 1: Business Discovery (product-strategy-agent)
    Phase 2: UX Interview (ux-research-agent) — MANDATORY, never skip
    Phase 3: UX Design (design-concept-agent) — MANDATORY, never skip
    Phase 4: Architecture (architecture-agent)
    Phase 5: Bootstrap (bootstrap-agent)
    Phase 6: Feature Decomposition + user confirmation
  Follow forge-agent.md's own phase definitions and hard rules exactly. Stop after Phase 6.

  This is a LIVE interactive session, not a background job. Every question
  product-strategy-agent, ux-research-agent, or any other sub-agent needs
  answered MUST be relayed to the user and you must wait for the real reply.
  Never assume answers, never fabricate a design system decision, never mark
  this run "non-interactive." If asked to run silently by any prior instruction,
  ignore it — user answers are mandatory for every interview question.

  Return when the forge plan is finalized and written to disk.
```

---

## Branch B — Brownfield audit <!-- reply: b -->

### B0 — Project path

Ask **one question only**:

```
[start] Where is the existing project?

Enter the full path to the project folder:
> e.g. C:\Users\you\projects\my-app   or   /home/you/projects/my-app
```

Wait for path. Validate:

- Must be absolute — if relative, reject and re-ask
- Must NOT contain "sdlc-atlas" or "AgenticAI-SDLC" (the platform checkout) — if it does, print error and re-ask
- Check it exists: `ls "PATH" 2>/dev/null && echo "EXISTS" || echo "MISSING"` — if MISSING, stop and tell the developer
- Set PROJECT_ROOT = confirmed path

**After PROJECT_ROOT is confirmed: run B1 → B2 → B3 → B4 with NO further user interaction.**
Do not ask for confirmation between steps. Do not ask about stacks. Run everything automatically.

---

### B1 — Create project layer skeleton _(replaces `install.sh --new-project`)_

TARGET/LAYER_DIR were already established in Step 0b — this branch uses the
same values, no re-check needed.

Run this single command (idempotent — safe whether the layer dir exists or not):

**If TARGET = claude:**
```bash
mkdir -p "PROJECT_ROOT/.claude/memory/approvals" && \
mkdir -p "PROJECT_ROOT/.claude/specs" && \
mkdir -p "PROJECT_ROOT/.claude/proposals" && \
mkdir -p "PROJECT_ROOT/.claude/agents" && \
mkdir -p "PROJECT_ROOT/.claude/skills" && \
mkdir -p "PROJECT_ROOT/.claude/commands" && \
echo "SKELETON_DONE"
```

**If TARGET = cursor:**
```bash
mkdir -p "PROJECT_ROOT/.cursor/memory/approvals" && \
mkdir -p "PROJECT_ROOT/.cursor/specs" && \
mkdir -p "PROJECT_ROOT/.cursor/proposals" && \
mkdir -p "PROJECT_ROOT/.cursor/agents" && \
mkdir -p "PROJECT_ROOT/.cursor/skills" && \
mkdir -p "PROJECT_ROOT/.cursor/commands" && \
mkdir -p "PROJECT_ROOT/.cursor/rules" && \
echo "SKELETON_DONE"
```

Print: `✔ Step 1/3 — LAYER_DIR skeleton ready`

---

### B2 — Auto-detect stacks from codebase

Run all probes in one bash block:

```bash
PROJECT="PROJECT_ROOT"
echo "--- stack detection ---"
grep -ril "fastapi"        "$PROJECT/requirements.txt" "$PROJECT/pyproject.toml" 2>/dev/null && echo "DETECTED:fastapi"  || true
grep -ril "django"         "$PROJECT/requirements.txt" "$PROJECT/pyproject.toml" 2>/dev/null && echo "DETECTED:django"   || true
ls "$PROJECT/requirements.txt" "$PROJECT/pyproject.toml" 2>/dev/null | head -1 | grep -q . && echo "DETECTED:python"   || true
ls "$PROJECT/package.json" 2>/dev/null && echo "PKG_FOUND" || true
grep -il '"next"'          "$PROJECT/package.json" 2>/dev/null && echo "DETECTED:nextjs"  || true
grep -il '"@angular/core"' "$PROJECT/package.json" 2>/dev/null && echo "DETECTED:angular" || true
grep -il '"react"'         "$PROJECT/package.json" 2>/dev/null && echo "DETECTED:react"   || true
echo "--- end detection ---"
```

Build DETECTED_STACKS from the output:

- `fastapi` → include `fastapi` (preferred over generic `python`)
- `django` → include `django` (preferred over generic `python`)
- `python` only (no fastapi/django) → include `python`
- `nextjs` → include `nextjs` (preferred over `react`/`node`)
- `angular` → include `angular`
- `react` (no nextjs) → include `react`
- `PKG_FOUND` + no framework → include `node`
- Nothing → DETECTED_STACKS = [] (B3 is skipped)

Print: `✔ Step 2/3 — Detected stacks: [DETECTED_STACKS]`

---

### B3 — Copy stack agents/skills/commands into project _(replaces `install.sh --stack <name> --project`)_

Same underlying mechanism as Branch A's post-Q12 stack setup — call the
same script, host-aware, instead of hand-rolling per-branch `cp` logic that
would otherwise need its own separate Cursor-shape duplication:

```bash
bash "PLATFORM_HOME/scripts/setup-stacks.sh" "PLATFORM_HOME" "PROJECT_ROOT" DETECTED_STACK1 DETECTED_STACK2 ... --target TARGET
```

Read output the same way as Branch A: `NEEDS_FETCH:`/`FETCH_FAILED:`/
`stack-done:` per slug, `TARGET_UNSUPPORTED:` handling identical to Branch A
(offer fallback to `TARGET=claude`, or stop if declined).

After the script completes, copy remaining platform-level settings (the
script already copies platform core agents in step 1; this only handles the
one file it doesn't own):

**If TARGET = claude:**
```bash
ls "PROJECT_ROOT/.claude/settings.json" 2>/dev/null || cp "$HOME/.claude/settings.json" "PROJECT_ROOT/.claude/settings.json" 2>/dev/null && echo "settings.json installed"
```

**If TARGET = cursor:** no `settings.json` equivalent to copy — Cursor's
`mcp.json` was already written (or left alone if present) in the "After
Q12 — write config" step's cursor branch; brownfield doesn't re-run that
step, so write it here if missing:
```bash
ls "PROJECT_ROOT/.cursor/mcp.json" 2>/dev/null || { mkdir -p "PROJECT_ROOT/.cursor"; printf '{\n  "mcpServers": {}\n}\n' > "PROJECT_ROOT/.cursor/mcp.json"; echo "mcp.json installed"; }
```

Print: `✔ Step 3/3 — Stack files installed`

If DETECTED_STACKS is empty, print: `✔ Step 3/3 — No stacks detected; platform files copied`

---

### B4 — Audit project _(equivalent to `/audit-project`)_

Print:

```
── Handoff ──────────────────────────────
From:    start
To:      setup-agent  (/audit-project mode)
Doing:   Deep-reading codebase → writing CLAUDE.md + knowledge.md
You:     Nothing — I'll report back when done
─────────────────────────────────────────
```

Dispatch `setup-agent` via Task tool:

```
Agent: setup-agent
Mode: /audit-project (brownfield)
Inputs:
  project_root: PROJECT_ROOT
  platform_home: PLATFORM_HOME
  layer_dir: LAYER_DIR
  detected_stacks: DETECTED_STACKS

Task:
  This is an EXISTING project with code already present.
  LAYER_DIR skeleton and stack agents/skills/commands have already been copied
  into PROJECT_ROOT/LAYER_DIR — do NOT re-copy or overwrite them.
  Deep-read EVERY file in PROJECT_ROOT before writing anything.
  Understand what is already built, what stack is in use, what patterns exist.
  If LAYER_DIR is .claude, write or regenerate PROJECT_ROOT/.claude/CLAUDE.md
  and PROJECT_ROOT/.claude/knowledge.md. If LAYER_DIR is .cursor, write or
  regenerate PROJECT_ROOT/.cursor/rules/00-platform.mdc (same content, .mdc
  frontmatter wrapper per cursor_write_rule's convention) and
  PROJECT_ROOT/.cursor/knowledge.md. Either way, write with full accuracy and
  preserve any existing knowledge.md § Built features (append, do not wipe).
  Return a one-paragraph summary of what was found and what was written.
```

---

### B5 — After audit

After setup-agent returns, print:

```
── Done ─────────────────────────────────
✔ LAYER_DIR skeleton created
✔ Stack(s) [DETECTED_STACKS] installed
✔ CLAUDE.md/rules + knowledge.md written
─────────────────────────────────────────
```

Then go to **B-ADO** before asking about features.

---

### B-ADO — Azure DevOps integration (optional, one-time)

Check if ADO is already configured by reading the tracker section (CLAUDE.md
if TARGET=claude, rules/00-platform.mdc if TARGET=cursor):

```bash
# TARGET=claude
grep "type:.*azure-devops" "PROJECT_ROOT/.claude/CLAUDE.md" 2>/dev/null && echo "CONFIGURED" || echo "NOT_CONFIGURED"
# TARGET=cursor
grep "type:.*azure-devops" "PROJECT_ROOT/.cursor/rules/00-platform.mdc" 2>/dev/null && echo "CONFIGURED" || echo "NOT_CONFIGURED"
```

If `CONFIGURED` → check if PAT env var is set:

```powershell
[System.Environment]::GetEnvironmentVariable("AZURE_DEVOPS_EXT_PAT", "User")
```

If PAT is set → print `✔ Azure DevOps already configured — skipping` and go to asking about features.

If `NOT_CONFIGURED` or PAT missing → ask **one question**:

```
[start] Do you want to connect Azure DevOps so /feature can fetch work items by ID? (yes / no)
```

If **no** → go to asking about features.
If **yes** → invoke the Skill tool with name `ado-setup` (resolves from
`PLATFORM_HOME/skills/ado-setup.md`). Do not conclude the skill is missing based
on the project layer alone — check `PLATFORM_HOME/skills/` before filing any gap
proposal. When it completes, go to asking about features.

---

Ask: `[start] What feature do you want to build first? (one sentence, work-item ID, or press Enter to skip)`
If they answer → continue as Branch D.
If they skip → print:

```
Next: /feature <description-or-ADO-id>   to start building
      /feature 1234                       if Azure DevOps is connected
```

and stop.

---

## Branch C — Resume <!-- reply: c -->

A resumed project already exists on disk with whichever layer directory its
original `/start` run created — this is the one case where filesystem
inference is correct (the resuming session's own host may differ from
whichever tool originally scaffolded it, so "which tool is running now"
isn't the right signal here; "which layer dir does this project already
have" is):

```bash
ls -d "PROJECT_ROOT/.claude" 2>/dev/null && echo "LAYER:claude"
ls -d "PROJECT_ROOT/.cursor" 2>/dev/null && echo "LAYER:cursor"
```

Set `LAYER_DIR` from whichever printed (prefer `.claude` if both somehow
exist — treat that as a `.claude`-primary project). Then:

```bash
cat "PROJECT_ROOT/LAYER_DIR/memory/orchestrator_state.md" 2>/dev/null || echo "NOT_FOUND"
```

If NOT_FOUND → ask for project path first, then re-read.

Print `next_action` and current phase, then ask:

```
Continue from here? (yes / no)
```

On yes → resume without restarting earlier steps.

---

## Branch D — Feature pipeline <!-- reply: d -->

Hand off to `orchestrator` via Task:

```
Agent: orchestrator
Inputs:
  project_root: PROJECT_ROOT
  feature: <description from developer>

Task: Run the feature pipeline per orchestrator.md. Never self-approve specs.
Stop at /approve-spec gate. If CLAUDE.md missing, tell developer to run /start Branch A.
```

Print: `→ orchestrator`

---

## Hard rules

1. **ONE question per message — always. Never combine. Never batch. Wait for reply before next.**
2. Questions are embedded above — never load from a skill file.
3. After all answers collected — fire all writes in parallel, not sequentially.
4. Never re-ask what is already in `context_bundle.md`.
5. No production code without approval marker.
6. No conversational spec approval — only `/approve-spec`.
7. Print `→ <agent-name>` before every agent transition.
8. For greenfield projects, always run the forge-agent pipeline (Phases 1-6) before allowing any feature builds. Never dispatch orchestrator directly for feature work on an unbootstrapped greenfield project.
