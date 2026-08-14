# /approve-spec <feature_slug>/<change_slug>

**The ONLY way to approve a spec. The orchestrator never self-approves.**

`<spec_id>` = path under `.claude/specs/` without `.md`  
Example: `/approve-spec todo/add-due-date`  
(Legacy flat files: `/approve-spec spec_1` still works if `specs/spec_1.md` exists.)

The ACTIVE marker is written here and nowhere else. Steps, in order:

## Step 1 — Establish project root
```bash
pwd
```
This is PROJECT_ROOT. Every file path below is PROJECT_ROOT-absolute.

## Step 2 — Display Decision Summary
Read `PROJECT_ROOT/.claude/specs/<spec_id>.md` and display ONLY the Decision
Summary section (≤7 bullets) — never the full document.

## Step 3 — Wait for APPROVED
Wait for the developer to type the literal keyword **APPROVED**.
A conversational "yes" or "looks good" is NOT sufficient.

## Step 4 — Record approval in spec
Update the spec header: `status: APPROVED`, `approved_by`, `approved_at`.

## Step 5 — Update orchestrator state
Write to `PROJECT_ROOT/.claude/memory/orchestrator_state.md`:
- `spec: <spec_id> — APPROVED`
- `phase: phase-3-approved`
- `next_action: Proceed to Phase 4 — Plan & build`

## Step 6 — Write the approval marker (CRITICAL)
```bash
echo "<spec_id> approved $(date -u +%Y-%m-%dT%H:%MZ)" > "PROJECT_ROOT/.claude/memory/approvals/ACTIVE"
```

## Step 7 — Rebuild requirement index

Run `/index-reqs` (inline, no user prompt needed) to add this spec's REQ rows
to `PROJECT_ROOT/.claude/specs/req-index.md`. This keeps `/work-req` lookups
instant without any manual step.

If req-index.md does not exist yet, this creates it. If it exists, it appends
or updates only the rows for this spec (does not re-scan other specs).

## Step 8 — Confirm and resume orchestrator
```
✔ <spec_id> approved
✔ ACTIVE marker written
✔ req-index.md updated (<N> REQs added)
✔ Pipeline unlocked — resuming orchestrator at Phase 4
```

Resume orchestrator at **Phase 4** with the approved spec_id.
