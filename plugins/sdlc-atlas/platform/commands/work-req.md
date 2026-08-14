# /work-req <REQ-ID>

Targeted requirement-level build. Looks up the REQ-ID in the index (one grep),
reads only the relevant sections of that one spec, builds only the delta, and
updates all tracking. Never reads multiple spec files.

**Example:**
```
/work-req REQ-028
/work-req REQ-005
```

Use this instead of `/feature` when:
- The spec already exists and is APPROVED
- You want to implement or fix one specific requirement
- You don't want to re-run the full pipeline

**Prerequisite:** `req-index.md` must exist. Run `/index-reqs` once after
specs are approved to build it. It is also auto-rebuilt by `/approve-spec`.

---

## Step 1 — Establish project root

```bash
pwd
```

PROJECT_ROOT = output above.

---

## Step 2 — Validate index exists

```bash
test -f "PROJECT_ROOT/.claude/specs/req-index.md" && echo "EXISTS" || echo "MISSING"
```

If MISSING: print "Run `/index-reqs` first to build the requirement index." and stop.

---

## Step 3 — Run work-req skill

```
[skill: work-req]
```

Pass: PROJECT_ROOT, REQ-ID.

The skill handles all phases using the index for zero-scan lookup:
- Phase 0: Single grep on req-index.md → resolves spec path instantly
- Phase 1: Read only the 3 relevant sections of that one spec (~15-30 lines)
- Phase 2: Scan only the component files for this REQ → delta report
- Phase 3: Show delta → wait for developer approval
- Phase 4: Targeted build (scoped to this REQ's files only)
- Phase 5: Gate run (`run-gates.sh`) — never skipped
- Phase 6: Update spec ACs + req-index.md row + knowledge.md + orchestrator_state.md

---

## Step 4 — Done

Report:
- Which AC rows changed from ⚠️/❌ → ✅
- Which files were changed
- Gate results
- How many REQs remain PENDING/MISSING in this spec (from index)

No PR is raised automatically. When ready to ship: `/raise-pr`.

---

## Escalation rule

If the REQ-ID maps to more than ~5 files, or touches security behaviour,
authentication, database schemas, or API contracts — the skill will warn
and recommend `/change-feature` instead.
