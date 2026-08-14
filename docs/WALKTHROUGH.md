# Walkthrough — one feature, end to end, with layer annotations

A realistic run on an example project, Acme API (profile: enterprise, stack: fastapi).
ADO story **#2104: "Patients can download their lab results as a PDF and get
notified when it's ready."** Each step is tagged with the layer doing the work.
Use this to onboard developers and as the live-demo script.

## 1 · Intake — `/feature #2104`
The orchestrator's startup ritual IS the four layers loading, in order:
```
[L0] platform constitution: precedence, approval-is-literal, spec discipline
[L2] ORG.md: coverage_min=80, security_fail_on=HIGH, protected: main/develop, HIPAA
[L3] project CLAUDE.md: profile=enterprise, stack=fastapi, routing table (7 agents)
[L3] knowledge.md validated: camelCase-via-middleware · PHI-never-in-logs/args · ai_services nav
[L0] state file: nothing in flight → fresh start
[L0] fetch ADO #2104 + linked items + comments + attachments
```
`profile: enterprise` just decided everything downstream: all gates on,
evidence archiving on, org policy mandatory.

## 2 · Spec — spec-agent
```
[L0] mode detection: src/ exists → BROWNFIELD
[L0] brownfield-reading: scope DECLARED before any file opens —
     primary: reports/ (routing table maps "export" there)
     secondary read-only: patients/models.py, notifications/, S3 conventions
[L0] grep "LabResult" → patients/models.py:114 → read lines 100–160 only
[L0] one existing exporter inspected → pattern confirmed → STOP reading others
```
Interview — only questions where different answers produce different code:
sync vs async (story implies both?), one result vs full panel, reuse vs new
Knock template. Developer answers; cosmetic ambiguity (filename format) is
ASSUMED from the CSV-exporter precedent and recorded in Clarifications.

`spec_1.md` written; every claim cited; PHI section forced by the L2 compliance
declaration. The developer is never shown the wall of text:
```
─ DECISION SUMMARY — spec_1 (#2104) ─
• Async Celery task → endpoint returns 202 + status URL
  (rejected: sync — panel history can exceed request timeout)
• New LabExport model field (additive migration)
• S3 presigned URL, 24h expiry [org policy]; no patient name in object key [PHI]
• New Knock template "lab-results-ready"
• PHI fields named in §7a: result values, collection dates
• Assumption: filename {patient_id}_{date}.pdf per CSV precedent
─ Awaiting /approve-spec spec_1 ─
```

## 3 · The hard stop
```
dev> looks good, python ahead
[L0] That is not approval. Use /approve-spec spec_1.
dev> /approve-spec spec_1
[L0] APPROVED recorded — pipeline unlocked.
```
Conversational drift never triggers irreversible work (the AutoGPT/Devin lesson).

## 4 · Build — layers trading off
```
[L0] task plan in dependency order, agent per task, python-ahead requested:
 T1 model+migration → migration-agent [L1] · T2 Celery task → celery-agent [L1]
 T3 endpoint → api-agent [L1] · T4 S3 export → report-agent [L3]
 T5 Knock notify → integration-agent [L3]
[L1] migration-agent: additive nullable → safe-migration checklist; --plan saved;
     never applies to shared DB [L0 rule]
[L1] celery-agent: task args = IDs not objects — [L3] knowledge.md PHI rule
     OVERRIDES the generic stack pattern
[L1] api-agent: snake_case serializers [L3: middleware does casing]; 202 contract
     exactly per spec §5a
[L3] report-agent: object key = export UUID [spec PHI rule]; expiry 24h [L2]
[L3] integration-agent: GAP — no skill covers Knock template versioning →
     proposal-evaluation skill → ladder stops at rung 2 (skill-new) →
     files P-002, status draft-needs-evidence (single occurrence) →
     CONTINUES the task manually. Developer sees ONE line:
     "Filed P-002 (Knock template versioning) — review with /proposals."
```
That last block is the governance model in action: no "shall I create an agent?",
no pipeline stall, decision deferred to the tech lead's weekly review.

## 5 · Gates — fixed order, one fails
```
[L1] test-agent: 47 passed; new-code coverage 84% ≥ 80 [L2] ✓
[L3] security-agent (HIPAA override): bandit clean, BUT PHI audit →
     tasks/lab_export.py:58 logs patient.email — MEDIUM, and the override
     tightens org policy: MEDIUM PHI also FAILS.
[L0] PIPELINE STOPPED at gate 2 with the fix. After fix: security re-runs PASS;
     code changed → tests re-run PASS; sonar ✓; review-agent: diff matches
     spec §3b, nothing unspecified added ✓;
[L0] acceptance-agent: AC-1/2/3 each mapped to a named test ✓
[L0] evidence archived → .claude/memory/evidence/spec_1/
```
Note WHO failed the build: not the generic L0 gate — the L3 HIPAA override,
stricter than L2, stricter than L0. Tightening-only, all the way down.

## 6 · PR — `/raise-pr`
Checklist: approved spec ✓ · ADO link ✓ · 5 gates green ✓ · knowledge.md updated
(+1 [nav] exporters entry) ✓ · migration plan attached ✓ · branch matches L2
pattern ✓. PR body generated; **the developer pushes and raises it — agents never do.**

## Net result
One interview (3 questions) · one literal approval · one gate failure caught
before any human reviewer saw the PR · one governed proposal parked for Friday ·
and a state file that resumes all of this mid-step after any interruption.
