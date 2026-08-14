# Spec: <Feature Title> — <Change Title>

**Feature**: <feature-slug>
**Change**: <change-slug>
**Version**: 1.0
**Date**: <YYYY-MM-DD>
**Status**: DRAFT
**Approved by**: —
**Approved at**: —

<!--
  SPEC-AGENT INSTRUCTIONS (remove this block before saving):
  - Fill every section. Never remove a section heading.
  - Every factual claim ends with [source: ...].
  - Unsourceable claims → move to Section 10 as an explicit assumption.
  - Greenfield: fill Sections 3-6. Brownfield: fill Section 3b only, skip 4-6.
  - Do not change section numbers — /work-req and /index-reqs parse by heading.
-->

---

## 0. Decision Summary
<!--
  Shown at /approve-spec. Max 7 bullets. Cover:
  (a) contracts/schemas chosen + rejected alternative
  (b) security or migration impact
  (c) every assumption in Section 10
  (d) superseding changes: deltas + drift findings
-->

- <decision or assumption 1>
- <decision or assumption 2>

---

## 1. Summary

<One paragraph: business ask restated as a concrete technical change — what
components change, what behaviour changes, what does not change.>

[source: <requirements file or work item>]

---

## 2. Requirements Coverage

<!--
  MANDATORY. One row per requirement. REQ-IDs must be REQ-NNN (zero-padded to 3 digits).
  Component/Section = the exact filename or component name that implements this req.
  This table is parsed by /index-reqs and /work-req — do not reformat or rename columns.
-->

| REQ-ID  | Component/Section | Description |
|---------|-------------------|-------------|
| REQ-001 | <File.tsx or endpoint path> | <one-line description> |
| REQ-002 | <File.tsx or endpoint path> | <one-line description> |

[source: <requirements file path and line range>]

---

## 3. Tech Stack

<!--
  Only the slice relevant to this feature. Source every version from manifests.
-->

| Technology | Version | Source |
|------------|---------|--------|
| <framework> | <x.y.z> | [source: <package.json or pyproject.toml line N>] |

---

## 4. Changes  *(brownfield — one bullet per file)*

<!--
  Brownfield only. Remove this section for greenfield specs.
  Format: **`path/to/file.ts`** — what changes — why — [source: file:line]
  A coding agent must never wonder "which file did they mean".
-->

- **`<path/to/file>`** — <what changes> — <why> [source: <file:line>]

---

## 5. Architecture  *(greenfield only)*

<!--
  Greenfield only. Remove this section for brownfield specs.
  Components, interactions, data flows. Include a hierarchy or diagram if helpful.
-->

---

## 6. Data Model  *(greenfield only)*

<!--
  Greenfield only. Field names, types, constraints. Source from schema files if they exist.
-->

---

## 7. API Design  *(greenfield only)*

<!--
  Greenfield only. Full contracts: method, path, request/response shapes, error cases, authz.
  "Standard CRUD" is not a contract.
-->

---

## 8. Acceptance Criteria

<!--
  MANDATORY. One row per acceptance criterion, grouped by REQ-ID.
  AC-NNN.M where NNN matches the REQ-ID number and M is the criterion index.
  Status symbols: ✅ done · ⚠️ pending/needs verification · ❌ not implemented · N/A not applicable
  This table is parsed by /work-req — do not reformat or rename columns.
-->

### 8.1 <Component/Section name> (REQ-001 to REQ-00N)

- **AC-001.1**: ❌ <acceptance criterion — specific, testable>
- **AC-001.2**: ❌ <acceptance criterion>
- **AC-002.1**: ❌ <acceptance criterion>

### 8.2 <Next Component/Section> (REQ-00N to REQ-00M)

- **AC-00N.1**: ❌ <acceptance criterion>

**Total Criteria**: <N>
**Verified in Spec**: 0
**To Verify Post-Build**: <N>

[source: <requirements file path and line range>]

---

## 9. Key Implementation Decisions

<!--
  Each decision must include the REJECTED alternative and why.
  Future readers need the why more than the what.
-->

**Decision 1: <title>**
Chosen: <approach>
Rejected: <alternative> — because <reason>
[source: <developer answer or ADR reference>]

---

## 10. Out of Scope

<!--
  Explicit list of what is NOT included. Prevents scope creep during implementation.
-->

1. <thing explicitly excluded> [source: <requirements or developer answer>]

---

## 11. Open Questions & Assumptions

<!--
  Every question asked during interview → answer or recorded assumption.
  Empty Clarifications on a non-trivial feature is a red flag.
-->

**A1. <Assumption title>**
Assumption: <what was assumed>
Rationale: <why this assumption was made>
[source: <developer answer or requirement reference>]

---

## 12. Change History

| Date | Version | Change | Author |
|------|---------|--------|--------|
| <YYYY-MM-DD> | 1.0 | Initial specification | spec-agent |

---

## 13. Approval

**Status**: DRAFT
**Approver**: (Pending `/approve-spec <feature>/<change>`)
**Approved Date**: (Pending)

Once approved, this spec becomes immutable. Changes require a new spec file
under `<feature>/` with `Supersedes: <feature>/<change>` header.

---

**END OF SPECIFICATION**
