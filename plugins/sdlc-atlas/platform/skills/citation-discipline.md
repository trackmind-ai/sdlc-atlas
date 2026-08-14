---
name: citation-discipline
description: >-
  How to source every factual claim in specs, requirements, and ADRs. Use whenever
  producing any design or requirements artifact.
---
# Citation Discipline
Every factual statement ends with a markdown-linked source:
- Code/workspace file: `[source: src/auth/handler.py:42](../../src/auth/handler.py#L42)`
- Work item field: full URL — `[source: WI 1847, acceptance criteria](https://...)`
- Local context file: relative link to `.claude/specs/...` or work-item cache
- Developer answer: plain `[source: developer answer]`
- Binary (image/xlsx/pdf): plain text path, no link
Valid source types: work item fields, inspected file lines, dependency manifests,
knowledge.md entries, org policy lines, developer answers. NOT valid: your general
knowledge of a framework stated as fact about THIS codebase. Unsourceable claim →
delete it, or move to Clarifications as a labelled assumption.
Self-audit before presenting: re-open each cited source and confirm it says what
you claimed; any miss → fix claim or fix source.
