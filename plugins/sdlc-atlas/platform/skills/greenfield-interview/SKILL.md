---
name: greenfield-interview
description: >-
  Routing guide for greenfield interview batches. Points agents to the canonical
  question bank in setup-interview-questions. Do not store questions here —
  they live in setup-interview-questions only.
---
# Greenfield interview (routing guide)

All greenfield questions are defined in `setup-interview-questions`.
This skill tells agents WHICH batch to use and WHEN.

---

## Who sends which batch

| Batch | Sent by | When |
|---|---|---|
| BATCH 1 — Project basics | `/start` | After main menu → greenfield chosen |
| BATCH 2 — Stack & profile | `/start` | After Batch 1 reply received |
| BATCH 3 — Gates & team | `/start` | After Batch 2 reply received |
| BATCH 4 — Architecture | `architecture-agent` | After /start hands off |
| BATCH 5 — Feature spec | `spec-agent` | At spec interview start |

---

## Rules

- Each agent loads `setup-interview-questions` and sends the relevant batch verbatim.
- Read `context_bundle.md` before sending — remove already-answered questions.
- Send ONE message per batch. Wait for ONE reply. Then write in parallel.
- Never ask questions outside the bank — file `/propose` if new questions are needed.

## Output destinations

| Batch | Writes to |
|---|---|
| 1–3 | `.claude/CLAUDE.md` + `knowledge.md` + `orchestrator_state.md` + `context_bundle.md` |
| 4 | `docs/architecture/system-architecture.md` + `docs/adr/*.md` + `context_bundle.md` |
| 5 | Informs spec content — no separate file |
