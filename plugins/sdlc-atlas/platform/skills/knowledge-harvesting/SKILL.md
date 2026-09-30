---
name: knowledge-harvesting
description: >-
  Extracts and consolidates codebase rules, conventions, and recurring debugging
  lessons from session histories and commit logs.
scope: platform
requirement: KNOWLEDGE_HARVESTING
---

# Knowledge Harvesting Guidelines

**Compounding project memory across development sessions.**

## 1. Learning Triggers
The knowledge-harvesting process runs at the end of the sprint lifecycle (post `/retro` or manually via `/harvest-knowledge`). It scans:
- **`git log -n 10`** — to understand what was changed and why.
- **`.claude/memory/orchestrator_state.md`** — to review task completion statuses and failure notes.
- **Terminal output logs** — to scan for command warnings, type checker errors, or dependency errors that required manual resolution.

## 2. Fact Extraction Rubric
Extract and format lessons as concise rules under one of these categories:

### A. Codebase Conventions
- Format: `- [nav] <Rule description> [source: file:line]`
- Example: `- [nav] Route definitions must use snake_case paths [source: server.py:L14]`

### B. Hard Constraints / Guardrails
- Format: `- [constraint] <Rule description> [source: developer answer / config]`
- Example: `- [constraint] Never store PII in raw logs [source: config.py:L55]`

### C. Recurring Debugging Lessons
- Format: `- [correction] <Rule description> [source: debug report]`
- Example: `- [correction] Always close SQLite connection in hooks to avoid file lock [source: db.py:L40]`

## 3. De-duplication & Pruning
Before writing to `.claude/knowledge.md`:
1. Read the existing file in full.
2. If a similar rule exists, skip the update or refine the existing line range/sources.
3. Keep the file concise (prune old or stale facts that have been superseded by stack upgrades).
