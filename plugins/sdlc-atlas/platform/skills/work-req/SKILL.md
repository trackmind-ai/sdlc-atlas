---
name: work-req
description: >-
  Targeted requirement-level build flow. Given only a REQ-ID, looks up the
  spec in one grep via req-index.md, detects the spec's format, reads only
  the relevant sections, builds only the delta, and updates all tracking.
  Handles all three known spec formats. Never reads multiple spec files.
---

# Work-Req Skill

Implements a single requirement from an existing approved spec.
Token cost is kept minimal: one grep on the index → one spec file opened →
only relevant sections read (~15-40 lines regardless of spec size).

---

## Phase 0 — Resolve spec from index (one grep)

```bash
grep "^| <REQ-ID> " "PROJECT_ROOT/.claude/specs/req-index.md"
```

Index row format:
```
| REQ-ID | feature/change | component-file | format | status |
```

Extract: `spec_path`, `component`, `format` (see Phase 1), `status`.

**If index missing:** "req-index.md not found. Run `/index-reqs` first." Stop.
**If REQ-ID not found:** "REQ-NNN not in index. Run `/index-reqs` to rebuild." Stop.

---

## Phase 1 — Detect spec format and read only relevant sections

Three spec formats exist. The index stores which format each spec uses.
Read only what's needed per format — never the full file.

---

### Format A — Requirements table + AC table
*Identified by*: has `## 2. Requirements Coverage` table with `| REQ-ID |` rows
AND `## 8. Acceptance Criteria` with `AC-NNN.N` rows and ✅/⚠️/❌ symbols.

*Example spec*: `landing-page/premium-landing`

**What to read:**
1. Header block (first 10 lines) — confirm `Status: APPROVED`
2. Grep `^| REQ-NNN |` in file → get component/file + description (1 line)
3. Grep `AC-NNN\.` in file → get all AC rows for this REQ (3-10 lines)

**Done signal per AC row:** ✅ = done, ⚠️ = pending, ❌ = missing

**How to update after build:**
- Edit AC rows: ⚠️/❌ → ✅
- Update footer counts (`Verified in Spec`, `To Verify Post-Build`)
- Append to Change History table

---

### Format B — Functional requirements table + manual checklist
*Identified by*: has `| ID | Requirement |` table with `**FN**` / `**NFN**` IDs
AND `## 8. Testing Strategy` with a Manual Testing Checklist (`- [ ]` items).
No AC-NNN rows exist.

*Example spec*: `ui-foundation/navigation-auth-onboarding`

**REQ-ID mapping for this format:** the index stores the ID as-is (e.g. `F7`, `NF2`).

**What to read:**
1. Header block (first 15 lines) — confirm `Status: APPROVED`
2. Grep `\*\*<ID>\*\*` in file → get the requirement row (1 line)
3. Read Section 3 subsection for the mapped component (grep heading, read ~20 lines)
4. Read Manual Testing Checklist (grep `Manual Testing`, read until next `---`)
   — filter checklist items relevant to this requirement's component/feature

**Done signal:** checklist item is `- [x]` (checked) = done, `- [ ]` = not done.
If no checklist item maps to this req, treat as MISSING.

**How to update after build:**
- Change relevant checklist items `- [ ]` → `- [x]`
- Append note to Change History if section exists, otherwise append to end of file:
  `<!-- work-req: <ID> implemented <date> -->`

---

### Format C — Prose-cited requirements, no table, no AC section
*Identified by*: REQ-IDs appear only inline in prose `[source: REQ-NNN]` citations.
No standalone requirements table. No AC section. Has `## 3. Changes` with subsections.

*Example spec*: `onboarding/enhanced-post-auth-journey`

**What to read:**
1. Header block (first 15 lines) — confirm `Status: APPROVED`
2. Grep `REQ-NNN` in file → get all lines that cite this REQ (usually 3-8 lines
   across Section 3 subsections) — reveals which subsection owns this req
3. Read only that subsection (grep heading, read ~30 lines)

**Done signal:** no explicit status tracking exists in this format.
Do a codebase check instead:
- Does the file described in the subsection exist?
- Does it contain the key functions/endpoints/types described?
- DONE = all present, PARTIAL = some present, MISSING = none present

**How to update after build:**
- This format has no built-in tracking section. Append a tracking block at the
  end of the file under `## Implementation Tracking` (create if absent):

```markdown
## Implementation Tracking
<!-- Added by work-req skill. Do not edit manually. -->

| REQ-ID | Subsection | Status | Date |
|--------|-----------|--------|------|
| REQ-NNN | 3.4 Backend — Onboarding Endpoints | DONE | <date> |
```

---

## Phase 2 — Codebase delta check

Using only the component file(s) identified in Phase 1:

1. Check file exists
2. Grep for key identifiers (function names, class names, endpoint paths, CSS
   classes, config keys) from the spec subsection
3. Classify as DONE / PENDING / MISSING

Delta report:
```
<REQ-ID> — <description>
  Format detected: A / B / C
  Files: <file1>, <file2>

  Status:
    <item>  ✅  [already done — skip]
    <item>  ⚠️  [exists but incomplete: <detail>]
    <item>  ❌  [not implemented]

  Work needed: <one sentence>
```

If all items DONE: "REQ-NNN is fully implemented — nothing to do." Stop.

---

## Phase 3 — Show delta & wait for approval

Display delta report. Ask: **"Proceed? (yes / no)"**

- `no` → stop
- `yes` → write approval marker:

```bash
echo "<feature/change> <REQ-ID> approved $(date -u +%Y-%m-%dT%H:%MZ)" \
  > "PROJECT_ROOT/.claude/memory/approvals/ACTIVE"
```

---

## Phase 4 — Targeted build

Route by file type:

| File pattern | Agent |
|---|---|
| `*.tsx`, `*.ts`, `*.css`, Next.js/React | stack frontend agent |
| `*.py`, FastAPI routes, Pydantic models | `api-agent` |
| `tailwind.config.*`, `globals.css` | stack frontend agent |
| `*.test.*`, `*.spec.*` | `test-agent` |
| Mixed / uncertain | `orchestrator` decides |

Pass: relevant spec subsection (~30 lines), PENDING/MISSING items only,
design tokens if styling involved. Instruction: implement only what satisfies
these items, do not touch other components.

---

## Phase 5 — Gate run

Project-local copy first, platform-home fallback — most projects only have the
platform-home copy since install.sh --platform never writes a project-local one:
```bash
cd "PROJECT_ROOT" && GATES_SCRIPT=".claude/scripts/run-gates.sh"; [ -f "$GATES_SCRIPT" ] || GATES_SCRIPT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude}/platform/scripts/run-gates.sh"; [ -f "$GATES_SCRIPT" ] || GATES_SCRIPT="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude}/scripts/run-gates.sh"; [ -f "$GATES_SCRIPT" ] || GATES_SCRIPT="$HOME/.claude/scripts/run-gates.sh"; bash "$GATES_SCRIPT"
```

Never skipped. On failure: report, do not update tracking, stop.

---

## Phase 6 — Update all tracking

**Only runs after Phase 5 gates pass. Every sub-step is mandatory — none are skipped.**

Run all six sub-steps in order. Report each one to the developer as it completes.

---

### 6.1 — Update spec AC statuses (format-specific)

**Format A specs** (Section 2 REQ table + Section 8 AC rows):
- For every AC row that was ⚠️ or ❌ and is now implemented → change to ✅
- Update the Section 8 footer:
  - `**Verified in Spec**: N` → increment by count of newly ✅ ACs
  - `**To Verify Post-Build**: N` → decrement by same count
- Append to Section 12 Change History:
  ```
  | <YYYY-MM-DD> | patch | REQ-NNN implemented — AC-NNN.1, AC-NNN.2 done | work-req |
  ```

**Format B specs** (FN/NFN table + manual checklist):
- Change relevant checklist items from `- [ ]` to `- [x]`
- If a Change History section exists, append a row. Otherwise append at end of file:
  ```html
  <!-- work-req: <ID> implemented <YYYY-MM-DD> -->
  ```

**Format C specs** (prose-cited REQ-IDs, no AC section):
- Find or create `## Implementation Tracking` at end of file:
  ```markdown
  ## Implementation Tracking
  <!-- Added by work-req skill. Do not edit manually. -->

  | REQ-ID  | Subsection           | Status | Date       |
  |---------|----------------------|--------|------------|
  | REQ-NNN | 3.N <subsection name>| DONE   | YYYY-MM-DD |
  ```
- If the table already exists, append a new row for this REQ-ID.

---

### 6.2 — Update req-index.md (one row)

Flip the status column for this REQ-ID row from PENDING or MISSING to DONE:

```bash
sed -i "s/^| <REQ-ID> \(.*\)| PENDING \(.*\)|/| <REQ-ID> \1| DONE    \2|/" \
  "PROJECT_ROOT/.claude/specs/req-index.md"
sed -i "s/^| <REQ-ID> \(.*\)| MISSING \(.*\)|/| <REQ-ID> \1| DONE    \2|/" \
  "PROJECT_ROOT/.claude/specs/req-index.md"
```

Verify with a grep that the row now shows DONE. If sed failed (Windows path issue),
edit the row directly using the Edit tool.

---

### 6.3 — Update knowledge.md § Built features

File: `PROJECT_ROOT/.claude/knowledge.md` (or `PROJECT_ROOT/knowledge.md` — check
which exists).

**If the feature already has an entry** under `## Built features`:
- Find the entry by feature name (e.g. `### Landing Page`)
- Add or update a `#### REQ-NNN — <description>` subsection with:
  - **Implemented**: <YYYY-MM-DD>
  - **Files changed**: list of files touched in Phase 4
  - **Behaviour added**: 1–2 sentences describing what now works, written for
    someone new to the codebase
  - **AC covered**: list of AC-NNN.M rows now ✅
  - **Tests**: path(s) of any new/updated test files from Phase 4

**If no entry exists yet for this feature**, create a full subsection:

```markdown
### <Feature title>  [spec: <feature/change>]

**What it does**: <2–4 sentences describing the feature for someone new to the codebase>

**REQ-NNN — <description>**
- Implemented: <YYYY-MM-DD>
- Files changed: <file1>, <file2>
- Behaviour added: <1–2 sentences>
- AC covered: AC-NNN.1 ✅, AC-NNN.2 ✅
- Tests: <test file path, N tests covering X>

**Key files**
- `<path/to/file>` — <role of this file in the feature>

**Data models**: <model name, file:line, key fields> (write "none" if not applicable)
**API endpoints**: <method path — auth — description> (write "none" if not applicable)
**Key decisions**: <what was chosen and why the alternative was rejected>
**Dependencies**: <external services or sibling features relied on>
```

A one-line entry is a documentation failure. Do not write "REQ-NNN done." —
write what a developer needs to know to work on or extend this feature.

---

### 6.4 — Update CLAUDE.md § 14 Built features pointer

File: `PROJECT_ROOT/.claude/CLAUDE.md`

Section 14 reads:
```
> **→** `knowledge.md § Built features` — full detail per feature
```

This section is a pointer, not content — **do not add feature detail here**.
But do confirm the pointer line exists. If CLAUDE.md has no Section 14, append:

```markdown
## 14 · Built features

> **→** `knowledge.md § Built features` — full detail per feature: key files,
> data models, API endpoints, background tasks, key decisions, test coverage,
> and dependencies.
```

---

### 6.5 — Update orchestrator_state.md

Overwrite `PROJECT_ROOT/.claude/memory/orchestrator_state.md` completely:

```markdown
# Orchestrator State

last_action:   work-req <feature/change> REQ-NNN
last_updated:  <YYYY-MM-DD>
status:        req-implemented
feature:       <feature/change>
req_done:      REQ-NNN

open_reqs:
  # grep req-index.md for remaining PENDING/MISSING rows in this spec
  - REQ-XXX  PENDING   <component>
  - REQ-YYY  MISSING   <component>

next_action:
  - Run /work-req REQ-XXX to continue, OR
  - Run /raise-pr when all REQs in this spec are DONE
```

---

### 6.6 — Check for new uninferable facts

After updating the files above, briefly consider: did implementing this REQ
surface any fact that a developer reading every file could NOT infer?

Examples of things that qualify:
- An external service dependency with a non-obvious constraint
- A deliberate deviation from the spec (recorded assumption)
- A runtime behaviour that isn't visible in the code

If yes: add a `[nav]`, `[constraint]`, or `[correction]` bullet to
`knowledge.md § Uninferable facts`. If no new facts surfaced, skip this step.

---

### Phase 6 completion report

After all six sub-steps, print:

```
✔ Phase 6 complete — all tracking updated

  Spec:               <feature/change>  →  AC-NNN.1 ✅  AC-NNN.2 ✅
  req-index.md:       REQ-NNN  PENDING → DONE
  knowledge.md:       § Built features updated (REQ-NNN subsection)
  CLAUDE.md:          § 14 pointer confirmed
  orchestrator_state: req-implemented
  Open REQs left:     <N> PENDING / <M> MISSING in this spec

  Next: /work-req REQ-XXX  or  /raise-pr
```

---

## Invariants

- Never read more than one spec file per invocation
- Never scan all specs — index is the only lookup
- Never touch AC rows or checklist items for other REQ-IDs
- Never create a new spec file
- Never skip gates
- Never skip Phase 6 — partial updates leave the project in inconsistent state
- If REQ maps to >5 files or touches auth/schema/contracts → warn and recommend
  `/change-feature` instead
