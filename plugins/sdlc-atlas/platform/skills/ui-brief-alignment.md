---
name: ui-brief-alignment
description: >-
  Design-fidelity rule for any agent that writes or edits UI components, pages,
  or layout code. Read ux_brief.md before touching UI files, never invent
  visual elements that conflict with it. Load in frontend developer agents,
  component builders, page builders — platform or stack layer.
scope: platform
---

# Frontend UI/UX alignment

---

## Rule

Before writing or modifying any UI files, read the design customisations, colors, fonts, access environment, content density, and layout/nav preferences from `PROJECT_ROOT/.claude/memory/ux_brief.md`.

Strictly implement and match the brief's details (primary/brand colors, layout choices, density guidelines). Never invent visual elements, colors, or layouts that conflict with it.

Applies to all code changes during `/feature` or iterative build pipelines.

---

## Hard rules

- No UI file write/edit without first reading ux_brief.md (or confirming it doesn't exist / doesn't apply for this project).
- A visual choice not in the brief is not license to invent one — flag the gap, don't guess.
