---
name: gap-analysis
description: >-
  Skill inventory check run by spec-agent after the developer interview and
  before spec writing. Derives the task list from interview answers, checks
  each task against the skill registry in CLAUDE.md §6.1–6.2 and knowledge.md
  §Project skills, then verifies each matched skill exists on disk. If any task
  has no matching or verifiable skill, presents a gap report to the user and WAITS.
  When all tasks are verified, ALWAYS prints a verification table to the terminal
  and appends a ## Gap Analysis section to the spec file.
scope: platform
---

# Gap Analysis

## When to load
Load this skill during spec writing, immediately after the developer interview
and before drafting any spec section. Do not load during code review or gate runs.

---

## Step 1 — Derive the task list

From the interview answers, extract every concrete implementation task.
Tasks are actions a coding agent will perform — not acceptance criteria, not
business requirements, not UI copy decisions.

Each task is one sentence with an active verb:
- "Add `payment_intent_id` column to the `orders` table"
- "Implement Stripe webhook signature verification in `billing/webhooks.py`"
- "Write a Celery task that emails the invoice PDF on charge success"

Write the task list to scratch (not to any file) — it is ephemeral input for
the analysis below.

---

## Step 2 — Registry check

Read from two files:
- `PROJECT_ROOT/.claude/CLAUDE.md` sections 6.1 (platform built-ins) and 6.2 (stack skills)
- `PROJECT_ROOT/.claude/knowledge.md` § Project skills (scope: project)

Build an in-memory registry: `{ skill-name → what it codifies }` for all three layers.

For each task, search the registry for a skill whose description covers this
task's domain. A match exists when the skill codifies the SAME domain procedure
— not just a vaguely related one.

Record the outcome per task:
- **MATCHED** — task maps to `skill-name` in registry
- **GAP** — no skill in the registry covers this task's domain

If any task is GAP → skip to Step 4. Otherwise continue to Step 3.

---

## Step 3 — On-disk verification

For every task that passed the registry check, check all three canonical paths
in a single bash call. A skill is VERIFIED when at least one path returns a real file:

```bash
bash -c 'P1="PROJECT_ROOT/.claude/skills/<stack>/<skill-name>/SKILL.md"; P2="${CLAUDE_PLUGIN_ROOT:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}}/stacks/<stack>/skills/<skill-name>/SKILL.md"; P3="${CLAUDE_PLUGIN_ROOT}/platform/skills/<skill-name>/SKILL.md"; P4="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/<skill-name>/SKILL.md"; P5="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/<skill-name>.md"; if [ -f "$P1" ]; then echo "FOUND:path1:$P1"; elif [ -f "$P2" ]; then echo "FOUND:path2:$P2"; elif [ -f "$P3" ]; then echo "FOUND:path3:$P3"; elif [ -f "$P4" ]; then echo "FOUND:path4:$P4"; elif [ -f "$P5" ]; then echo "FOUND:path5:$P5"; else echo "MISSING"; fi'
```

Replace `<stack>` with the stack name from CLAUDE.md §2 `stack.primary`; if
`additions` are declared, also probe each addition. Replace `<skill-name>` with
the skill slug. Run one probe per skill. Collect results.

If any skill is MISSING → it is a gap; go to Step 4.
If all skills are FOUND → skip Step 4, go directly to Step 5.

---

## Step 4 — Hard block on gap — present gap report to user and WAIT

**⛔ CRITICAL — read before proceeding:**

- **Filing a proposal does NOT resolve a gap.** A proposal is a governance artefact that records an intent to create a skill later. The skill file does not exist yet. The gap is still open.
- **Platform Rule 7 ("capability gap → file proposal, continue manually") does NOT apply here.** Rule 7 covers missing AGENTS and COMMANDS in the pipeline. It does not override the spec-agent's gap analysis hard block. Skill gaps in gap analysis are a separate category that BLOCK spec writing.
- **A spec cannot be written with unresolved skill gaps.** Tasks annotated `[skill: missing-skill]` reference a skill that no coding agent can load. The spec is structurally incomplete.
- The ONLY resolution is: the user creates the skill file on disk (or installs it via `install.sh`), then types `GAPS RESOLVED`.

**The agent does NOT create, extend, or modify skill files.**
Skill files are capability files — only the user or an approved proposal may change them.

For every GAP task (either registry-missing or disk-missing), present this report in ONE message:

```
⛔ Gap analysis FAILED — spec writing is BLOCKED.

N gap(s) found. The spec will NOT be written until all gaps are resolved on disk.
Filing a proposal does not unblock this gate.

─────────────────────────────────────────
Task:           <task description>
Required skill: <skill-name>
Registry:       FOUND in CLAUDE.md §6.2  ← or MISSING if not listed
Disk:
  path1  PROJECT_ROOT/.claude/skills/<stack>/<skill-name>/SKILL.md               → MISSING
  path2  ${CLAUDE_PLUGIN_ROOT}/platform/skills/<skill-name>/SKILL.md             → MISSING
  path3  $HOME/.claude/stacks/<stack>/skills/<skill-name>/SKILL.md               → MISSING
  path4  $HOME/.claude/skills/<skill-name>/SKILL.md (or .md)                     → MISSING

Closest existing skill: <skill-name> — <what it codifies>
  (covers ~X% — does not cover: <what is missing>)
  OR: no close match found

Suggested action:
  • Create a new skill file at one of the paths above and fill it in
  OR
  • Extend <skill-name> — add a section covering <missing procedure>
  OR
  • Run: bash install.sh --stack <stack> --project <PROJECT_ROOT>
    to install a missing built-in stack skill.
─────────────────────────────────────────

(repeat for each gap)

Create or install the skill file(s) above, then type GAPS RESOLVED.
The spec will not be written until all on-disk probes return FOUND.
```

**What to include in the gap report per task:**

| Field | What to write |
|---|---|
| Task | The exact task sentence from Step 1 |
| Gap | One sentence — what domain or procedure is missing from the registry or disk |
| Registry | FOUND in §6.x if it appears in the registry; MISSING if not listed at all |
| Disk | All three path results from Step 3 probes |
| Closest existing skill | Name + what it already codifies; estimate % overlap; describe what it does NOT cover |
| Suggested action | Extend (if ≥ 70% domain overlap), create new (if genuinely separate domain), or install — this is a SUGGESTION only, the user decides |

**Wait for the user's reply. Do not proceed on a timeout, assumption, or because a proposal was filed.**

When the user replies `GAPS RESOLVED` (case-insensitive):
1. Re-read `PROJECT_ROOT/.claude/knowledge.md` § Project skills to pick up any new or updated skill files
2. Re-run the single-call on-disk probe from Step 3 for every previously-failing skill — proposals and registry entries DO NOT count; only a FOUND on-disk result unblocks a gap
3. If all tasks now return FOUND → proceed to Step 5
4. If any task still returns MISSING → print a fresh gap report for the remaining gaps and wait again — do NOT proceed to Step 5

---

## Step 5 — Print verification table and write spec section

**Precondition: Step 5 is only reachable when every skill in the task list returned FOUND on at least one on-disk probe.**
**If any skill is still MISSING, you are in Step 4, not Step 5. Do not advance here early.**

### 5a — Print verification table to terminal

Print this block to the terminal (the chat) before writing any spec section.
Every row must have a real verified path — no row may show MISSING or "proposal filed":

```
✔ Gap analysis PASSED — <N> task(s), <N> skill(s) verified, 0 gap(s)

Task                                    Required skill        Verified path
────────────────────────────────────────────────────────────────────────────────
<task description (truncated to 40ch)>  <skill-name>          <path where FOUND>
...
```

Use the path where the skill was first found (path1 → path2 → path3 priority).
Truncate task descriptions to 40 characters with `…` if longer.

### 5b — Append Gap Analysis section to the spec file

After `## Tasks` in the spec file, append this section:

```markdown
## Gap Analysis

**Result:** PASSED · <N> task(s) · <N> skill(s) verified · 0 gap(s) · <YYYY-MM-DD>

| Task | Required skill | Verified path |
|---|---|---|
| <task description> | <skill-name> | `<path where FOUND>` |
```

Every task in `## Tasks` must have a corresponding row in this table with a real on-disk path.
A row showing MISSING, "proposal filed", or a proposal ID is evidence of a Step 4 violation — the spec must not be presented for approval in that state.

---

## Step 6 — Return the annotated task list

Produce the final annotated task list. Each task carries exactly one skill citation:

| Outcome | Citation format |
|---|---|
| Clean match | `[skill: skill-name]` |
| Matched after user filled gap | `[skill: skill-name]` |

This annotated list becomes the `## Tasks` section of the spec verbatim.
There are no `— extended` or `— newly created` tags — the agent did not touch skill files.
