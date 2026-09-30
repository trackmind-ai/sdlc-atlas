---
name: spec-writing
description: >-
  Section-by-section quality bar for spec_N.md files. Use alongside the
  spec_template when drafting any spec.
---
# Spec Writing
- Technical Story Interpretation: the business ask restated as a concrete technical
  change naming components and behaviour deltas. If your restatement could fit two
  different implementations, it isn't done.
- Changes (brownfield): one bullet per file — path, what changes, why, citation.
  A coding agent should never wonder "which file did they mean".
- API Design: full contracts — method, path, request/response shapes, error cases,
  authz. "Standard CRUD" is not a contract.
- Key Implementation Decisions: include the REJECTED alternative and why; future
  readers need the why more than the what.
- Subsection 9.1 Engineering Edge-Case Analysis: The agent must self-audit the design for concurrency issues (race conditions), database locks or connection leaks, resource load limitations (large datasets/OOM prevention), and API/network failure fallbacks (timeouts and retries). Complete this in the same turn without spawning a separate subagent.
- Clarifications: every question asked, the answer or the recorded assumption.
  Empty Clarifications on a non-trivial feature is a red flag, not a virtue.
Profile awareness: sections tagged (enterprise) in the template are skipped in
small; never skip Clarifications in any profile.

## Length budgets (review burden is a failure mode)
- Changes section: ONE line per file. No code in specs.
- Never restate what a citation already shows — link, don't narrate.
- A spec longer than ~2 screens for a 1-day change is a defect: cut or split.
- The spec's job is recording DECISIONS, not describing everything.
