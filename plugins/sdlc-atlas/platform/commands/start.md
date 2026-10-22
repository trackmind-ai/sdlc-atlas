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

## Step 0 — Caveman check (optional — ask, never block)

Caveman is an optional third-party plugin that enforces terse output. `/start` works
without it, so this step asks once and continues whatever the answer is.

```bash
cat "$HOME/.claude/.caveman-active" 2>/dev/null || echo "NOT_INSTALLED"
```

If active → proceed to Step 0b silently.

If NOT_INSTALLED or empty:

1. Ask the developer (AskUserQuestion), printing exactly:
   ```
   [start] Caveman plugin not detected.
   It is an optional third-party plugin that cuts token usage by enforcing terse
   output. Install it now? (yes / no)
   ```
2. Wait for the reply.
   - If **no** → print `Continuing without caveman — terse-output enforcement is off.
     You can install it later.` and proceed to Step 0b. Do not ask again this session.
   - If **yes** → detect OS and run the correct installer:

```bash
uname -s 2>/dev/null || echo "Windows"
```

- If output contains `Windows`, `MINGW`, or `CYGWIN` → run PowerShell:
  ```powershell
  irm https://raw.githubusercontent.com/JuliusBrussee/caveman/bad48a0e1df55e05e3f52249afa35ecc1909ee76/install.ps1 | iex
  ```
- Otherwise (macOS / Linux / WSL) → run:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/bad48a0e1df55e05e3f52249afa35ecc1909ee76/install.sh | bash
  ```

After the installer completes, re-check:

```bash
cat "$HOME/.claude/.caveman-active" 2>/dev/null || echo "NOT_INSTALLED"
```

- If now active → print `✔ Caveman installed — continuing.` and proceed to Step 0b.
- If still NOT_INSTALLED → print `Caveman did not activate (some installs only take effect
  after a restart). Continuing without it — restart Claude Code later to enable it.`
  and proceed to Step 0b. Do not stop.

---

## Step 0b — Establish roots

Run both in parallel:

```bash
pwd
echo "$HOME/.claude"
```

- **PROJECT_ROOT** = first output (overridden by developer's Q1 answer)
- **PLATFORM_HOME** = second output
- **PROJECT_ROOT is never a layer dir.** If PROJECT_ROOT (here, or from the Q1/B0
  answer later) ends in `/.claude` (either slash style, trailing
  slash ignored), drop that last segment: the parent is the project. Once
  PROJECT_ROOT is final, run `cd "PROJECT_ROOT"` so the session cwd is the
  project root. Claude Code creates `memory: project` agent memory at
  `<cwd>/.claude/agent-memory/`, so a cwd inside `.claude/` leaves a stray
  `.claude/.claude/`.

---

## Step 0c — QA tooling check (ask once, before anything else — never blocks)

Live browser/mobile QA (qa-agent's E2E Journey + per-screen audit, Phase 5a) needs
Chrome DevTools MCP (web) and/or Maestro MCP (mobile). Checking only at Phase 5a —
after the whole app is built — is too late to be useful, so this step asks up front.
It is the developer's choice: **installing is optional, and declining never stops
`/start`.** Declining is recorded, and the QA gate is later recorded as
`SKIPPED (declined)`; the final report then says the UI was not verified.

**Host assumption:** this step assumes Claude Code CLI (the `claude mcp` subcommand).

1. Check what's already connected:
   ```bash
   claude mcp list 2>&1 | grep -Ei 'chrome-devtools|maestro'
   ```

2. If the `claude` command itself is not found (non-Claude-Code host, or CLI not on
   PATH), do not ask anything and do not stop. Print:
   ```
   [start] Could not run `claude mcp list`, so QA tooling setup is not automated on
   this host. Continuing without it. Install Chrome DevTools MCP / Maestro MCP
   manually if you want live QA later.
   ```
   Record `qa_tooling: web=unavailable, mobile=unavailable` in `context_bundle.md`
   and proceed to Step 1.

3. For each tool (check both — the project's stack is not known yet at this point):

   - **Chrome DevTools MCP listed as `✔ Connected`** → note `web_qa: ready`.
   - **Maestro MCP listed as `✔ Connected`** → note `mobile_qa: ready`.
   - **Either missing** → do NOT silently skip it. Ask the developer
     (AskUserQuestion), printing:
     ```
     [start] QA tooling check:
       Chrome DevTools MCP (web QA):   <✔ ready | ✘ missing>
       Maestro MCP (mobile QA):        <✔ ready | ✘ missing>

     Live QA needs this tooling; qa-agent cannot audit or fix UI without it.
     Install the missing tooling now? (yes / no)
     No is fine: setup continues, the QA gate is recorded as SKIPPED (declined),
     and the final report will say the UI was not verified.
     ```
   - **yes** → install each missing tool, same commands qa-agent Step -1 uses:
     ```bash
     # Chrome DevTools MCP (web) — only if missing
     claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp@1.11.0
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
     - **Still missing after install attempt** → print the exact failing command's
       output, then: `⚠ Automated install did not complete. Continuing without it;
       see qa-agent.md Step -1 for the manual commands.` Record
       `qa_tooling: <tool>=unavailable` and proceed to Step 1. Do not stop.
     - **Newly connected** → MCP servers only attach at session start, so the tool is
       configured but not callable yet. Print:
       ```
       ✔ <tool> MCP installed and configured. It connects after a restart of Claude
       Code (or /mcp). Continuing setup now; QA will re-check it live at Phase 5a and
       offer a restart or skip then.
       ```
       Record `qa_tooling: <tool>=installed_needs_restart` and proceed to Step 1 in
       the same session. Do not end the turn.
   - **no** (developer declines install) → print:
     ```
     Continuing without <missing tool(s)>. Phase 5a QA will be recorded as SKIPPED
     (declined) and the UI will not be verified. You can install the tooling and run
     /qa at any time.
     ```
     Record `qa_tooling: web=<ready|declined>, mobile=<ready|declined>` in
     `context_bundle.md` so forge-agent/qa-agent don't re-ask, and proceed to Step 1.
   - **Both already `✔ Connected`** → print `✔ QA tooling ready (Chrome DevTools MCP +
     Maestro MCP).` and proceed to Step 1 silently otherwise (no need to re-ask).

This check runs ONCE per `/start` invocation (fresh session) — do not re-run it
mid-session if `/start` is resumed via Branch C without a fresh session start.

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
- Set PROJECT_ROOT = validated path (apply the layer-dir rule from Step 0b, then `cd "PROJECT_ROOT"`).
- Run all mkdir in parallel (fire simultaneously, do not wait):

```bash
mkdir -p "PROJECT_ROOT/.claude/memory/approvals"
mkdir -p "PROJECT_ROOT/.claude/specs"
mkdir -p "PROJECT_ROOT/.claude/proposals"
mkdir -p "PROJECT_ROOT/.claude/agents"
mkdir -p "PROJECT_ROOT/.claude/skills"
mkdir -p "PROJECT_ROOT/.claude/commands"
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
Immediately compile the brainstorming answers into a bulleted format and write to `PROJECT_ROOT/.claude/memory/brainstorm_notes.md`.

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
on, and it does NOT weaken the browser-QA gate (gate 4 in
`run-gates.sh` applies to any frontend stack regardless of this
answer — "Light" only relaxes the coverage number; the QA gate is only ever
skipped when the developer declined live QA or its tooling).

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

Run the setup script (substitute real values):

```bash
bash "PLATFORM_HOME/scripts/setup-stacks.sh" "PLATFORM_HOME" "PROJECT_ROOT" STACK_SLUG1 STACK_SLUG2 ...
```

Read every output line:

- `NEEDS_CONFIRM: SLUG` → the stack is not bundled and nothing has been downloaded.
  Ask the developer once (AskUserQuestion), showing the sources the script printed:
  `Stack 'SLUG' isn't bundled. Download these public pages to generate it?`
  - **yes** → run `python3 "PLATFORM_HOME/stacks/stack-orchestrator/bin/stack_fetcher.py" --confirm SLUG`,
    then `/fetch-stack SLUG`, then re-run setup-stacks.sh.
  - **no** → do not fetch. Continue without that stack (platform defaults apply) and
    note `stack SLUG not installed (declined by developer)` in the context bundle.
- `NEEDS_FETCH: SLUG` → invoke `/fetch-stack SLUG`, then re-run setup-stacks.sh.
- `FETCH_FAILED: SLUG` → print warning, continue without that stack.
- Wait until every slug shows `stack-done: SLUG`.

Then **write all config files in parallel** (all Write tool calls simultaneously):

1. `PROJECT_ROOT/.claude/CLAUDE.md` — fill from all answers (resolve `{{DATABASE}}` to the selected `DATABASE_SLUG` e.g. `sqlite`, `postgres`, etc.; resolve `{{COVERAGE_THRESHOLD}}` to the value derived from Q9's TEST_STRICTNESS — 70/85/0, never a hardcoded 0 regardless of what the user actually chose)
2. `PROJECT_ROOT/.claude/knowledge.md` — fill from all answers
3. `PROJECT_ROOT/.claude/memory/orchestrator_state.md` — initial state
4. `PROJECT_ROOT/.claude/memory/context_bundle.md` — all answers recorded here

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
`PLATFORM_HOME/skills/ado-setup/SKILL.md` or `${CLAUDE_PLUGIN_ROOT}/platform/skills/ado-setup/SKILL.md`). Do not conclude the skill is missing based
on the project layer alone — check the platform skills folder before filing any gap
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
  context_bundle: PROJECT_ROOT/.claude/memory/context_bundle.md
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
- Set PROJECT_ROOT = confirmed path (apply the layer-dir rule from Step 0b, then `cd "PROJECT_ROOT"`)

**After PROJECT_ROOT is confirmed: run B1 → B2 → B3 → B4 with NO further user interaction.**
Do not ask for confirmation between steps. Do not ask about stacks. Run everything automatically.

---

### B1 — Create project layer skeleton _(replaces `install.sh --new-project`)_

Run this single command (idempotent — safe whether the layer dir exists or not):

```bash
mkdir -p "PROJECT_ROOT/.claude/memory/approvals" && \
mkdir -p "PROJECT_ROOT/.claude/specs" && \
mkdir -p "PROJECT_ROOT/.claude/proposals" && \
mkdir -p "PROJECT_ROOT/.claude/agents" && \
mkdir -p "PROJECT_ROOT/.claude/skills" && \
mkdir -p "PROJECT_ROOT/.claude/commands" && \
echo "SKELETON_DONE"
```

Print: `✔ Step 1/3 — .claude skeleton ready`

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
same script instead of hand-rolling per-branch `cp` logic:

```bash
bash "PLATFORM_HOME/scripts/setup-stacks.sh" "PLATFORM_HOME" "PROJECT_ROOT" DETECTED_STACK1 DETECTED_STACK2 ...
```

Read output the same way as Branch A: `NEEDS_CONFIRM:`/`NEEDS_FETCH:`/`FETCH_FAILED:`/
`stack-done:` per slug.

After the script completes, copy remaining platform-level settings (the
script already copies platform core agents in step 1; this only handles the
one file it doesn't own):

```bash
ls "PROJECT_ROOT/.claude/settings.json" 2>/dev/null || cp "$HOME/.claude/settings.json" "PROJECT_ROOT/.claude/settings.json" 2>/dev/null && echo "settings.json installed"
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
  detected_stacks: DETECTED_STACKS

Task:
  This is an EXISTING project with code already present.
  The .claude skeleton and stack agents/skills/commands have already been copied
  into PROJECT_ROOT/.claude — do NOT re-copy or overwrite them.
  Deep-read EVERY file in PROJECT_ROOT before writing anything.
  Understand what is already built, what stack is in use, what patterns exist.
  Write or regenerate PROJECT_ROOT/.claude/CLAUDE.md and
  PROJECT_ROOT/.claude/knowledge.md with full accuracy and
  preserve any existing knowledge.md § Built features (append, do not wipe).
  Return a one-paragraph summary of what was found and what was written.
```

---

### B5 — After audit

After setup-agent returns, print:

```
── Done ─────────────────────────────────
✔ .claude skeleton created
✔ Stack(s) [DETECTED_STACKS] installed
✔ CLAUDE.md + knowledge.md written
─────────────────────────────────────────
```

Then go to **B-ADO** before asking about features.

---

### B-ADO — Azure DevOps integration (optional, one-time)

Check if ADO is already configured by reading the tracker section of CLAUDE.md:

```bash
grep "type:.*azure-devops" "PROJECT_ROOT/.claude/CLAUDE.md" 2>/dev/null && echo "CONFIGURED" || echo "NOT_CONFIGURED"
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
`PLATFORM_HOME/skills/ado-setup/SKILL.md` or `${CLAUDE_PLUGIN_ROOT}/platform/skills/ado-setup/SKILL.md`). Do not conclude the skill is missing based
on the project layer alone — check the platform skills folder before filing any gap
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

A resumed project already exists on disk; read its orchestrator state:

```bash
cat "PROJECT_ROOT/.claude/memory/orchestrator_state.md" 2>/dev/null || echo "NOT_FOUND"
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
