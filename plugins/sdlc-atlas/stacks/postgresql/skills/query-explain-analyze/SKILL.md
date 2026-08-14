---
name: query-explain-analyze
description: "Read and act on PostgreSQL EXPLAIN (ANALYZE, BUFFERS) plans to fix slow queries."
when_to_use: query-performance-agent diagnosing a slow query or reviewing ORM-generated SQL
disable-model-invocation: false
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Bash
model: sonnet
effort: medium
context: []
---

# Query EXPLAIN ANALYZE Procedure

1. Run `EXPLAIN (ANALYZE, BUFFERS) <query>`. For writes, wrap in `BEGIN; ... ROLLBACK;` — never commit a diagnostic run.
2. Seq Scan on a large table with a selective predicate/join → missing or unusable index; check column type/collation match too.
3. Nested Loop with high actual row counts → check join column indexes and `work_mem`; compare against Hash/Merge Join cost.
4. Compare `rows=` estimate vs actual — large mismatch means stale planner stats → recommend `ANALYZE <table>`.
5. Repeated single-row queries in app logs/traces → N+1 pattern → recommend batching (`IN`, `ANY(array)`, join) at the app layer.
6. High `Buffers: shared read` vs `shared hit` → cold cache / data larger than `shared_buffers` → consider index-only scan (covering index) or partitioning.
7. Propose the minimal fix: index (hand to index-agent), rewrite, or `ANALYZE` — re-run `EXPLAIN ANALYZE` to confirm before reporting.
8. Cite the specific plan line (node type, cost, rows) backing every recommendation.

## Hard rules

- Bare `EXPLAIN` (no ANALYZE) only when the query cannot safely be executed (e.g. destructive, prod-only side effects).
- Never run a diagnostic `EXPLAIN ANALYZE` on a write query against shared DB without a rollback wrapper.
- Never hand-edit schema from this skill — route index/DDL changes to index-agent/schema-design-agent.
