---
name: cache-first-reads
description: >-
  Token-reduction rule for agents that read project config/specs/knowledge.md
  repeatedly across a pipeline run. Check context_bundle.md before re-reading
  raw files from disk. Load in any agent whose tools include Read and that
  consumes CLAUDE.md, knowledge.md, business_brief.md, or spec files.
scope: platform
---

# Cache-first reads

Reduces redundant disk reads and re-tokenization of the same config/spec content
across agents in one pipeline run.

---

## Rule

1. BEFORE reading any raw configuration files, codebase files, specs, or documents from disk (`CLAUDE.md`, `knowledge.md`, `business_brief.md`, spec files, etc.), check if the required information already exists in `PROJECT_ROOT/.claude/memory/context_bundle.md`.
2. If present in context_bundle.md, use it directly — do NOT re-read the source file.
3. Fall back to reading raw files from disk only when the information is missing from context_bundle.md, or when checking for cache invalidation (timestamp/hash change).

---

## Hard rules

- Never trust context_bundle.md for content that could have changed since it was written without a documented invalidation check (timestamp/hash).
- Never skip reading a file that context_bundle.md doesn't cover — this rule reduces redundant reads, it never causes a required read to be skipped.
