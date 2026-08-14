---
name: intake-validation
description: Work intake validation criteria and manifest format
model: haiku
---

# Intake Validation Skill

**When:** Before Phase 1 (requirements) starts.  
**Who:** intake-assessment-agent.  
**Goal:** Surface missing materials early, prevent blind processing.

---

## Intake types (categorized)

| Category    | Examples                                           | Required? |
| ----------- | -------------------------------------------------- | --------- |
| **Primary** | Feature description, user ask, acceptance criteria | ✓ Always  |
| **Visual**  | Wireframes, mockups, diagrams (PNG, SVG, Figma)    | Optional  |
| **Doc**     | PRD, design doc, API spec, architecture diagram    | Optional  |
| **Data**    | Sample data, schema, config examples               | Optional  |
| **Code**    | Existing code references, code snippets            | Optional  |

---

## Manifest template

```
INTAKE MANIFEST
===============
Feature: <slug>
Time: <ISO timestamp>

✓ Primary: <description — one line>
✓ Attached: <type: filename> ... or "none"
✗ Missing: <expected but absent — or "none">

Status: READY | BLOCKED
Reason: <one-line if blocked>

---
Notes: <user observations or conflicts>
```

---

## Scan order (read-only, no writes)

1. **Feature description** — required, must be non-empty
2. **Attached materials** — scan work item, file system, inline pasted content
3. **Type categorization** — label by type (visual, doc, data, code)
4. **Conflict detection** — if materials contradict each other, flag
5. **Gap analysis** — if visual is given but no architecture doc, note it

---

## Go signal criteria

**READY:** Primary description exists + materials (if any) are self-consistent.

**BLOCKED:** One or more:

- Empty or vague primary description
- Materials conflict (spec says X, diagram shows Y)
- Critical type mismatch (e.g., data requirements but no schema provided + not brownfield)

---

## Action after intake

- **READY:** Pass manifest to Phase 1 (requirements or spec).
- **BLOCKED:** Return one clarifying question. User reply → re-scan. Max 2 cycles.
