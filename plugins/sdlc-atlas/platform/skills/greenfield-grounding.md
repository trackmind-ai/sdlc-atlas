---
name: greenfield-grounding
description: >-
  How to ground greenfield design work — what counts as a source when there is
  no codebase to cite. MANDATORY for spec-agent greenfield mode and for
  architecture-agent. The greenfield counterpart of brownfield-reading.
---
# Greenfield Grounding

Brownfield grounds claims in code that exists. Greenfield has no code — so its
risk is different: not misdescribing reality, but UNSTATED ASSUMPTIONS dressed
as decisions. This skill defines what grounds a greenfield claim.

## The bootstrap gate (run FIRST, before any design)
Check the repo for a dependency manifest with declared dependencies
(pyproject.toml / package.json / go.mod / Cargo.toml — not an empty stub).
- Found → it is the source of truth for the Tech Stack section. Cite it.
- Missing → STOP and ask one question: "This project has not been bootstrapped —
  run /bootstrap first (recommended, so the design cites real scaffold
  artifacts), or proceed with the Tech Stack flagged as assumption-based?"
  Honour the answer; if proceeding, every stack claim is labelled an assumption.

## Valid greenfield sources (in strength order)
1. The dependency manifest + CI files (after bootstrap)
2. **Reference codebases** — existing repos to copy patterns from, placed under
   `.claude/reference/codebases/<name>/`. Cite as
   `[source: .claude/reference/codebases/billing-svc/src/auth.py:30]`.
   Apply brownfield-reading rules when mining them (search before read, stop at
   one confirmed pattern) — reference repos deserve the same discipline.
3. **Architecture inputs** — org/team standards, prior architecture docs, RFCs,
   placed under `.claude/reference/architecture/`. Treat as constraints.
4. The approved requirements (REQ ids) and the architecture doc + its ADRs
5. Org policy lines and project knowledge.md
6. Developer answers — `[source: developer answer]`
NOT valid: "best practice" or framework lore stated as bare fact. Either tie it
to a reference artifact ("as in [source: reference repo X]") or present it as a
recommendation with the alternative, and let the decision be recorded.

## Decision honesty
Every consequential choice in a greenfield artifact names the REJECTED
alternative and why. A greenfield doc with no rejected alternatives did not
make decisions — it made assumptions.

## Reference directory hygiene
`.claude/reference/` is transient context — never committed product code, never
edited, read-only input. Empty/absent is fine: then sources 1, 4–6 carry the
design, and the Clarifications section carries more weight.
