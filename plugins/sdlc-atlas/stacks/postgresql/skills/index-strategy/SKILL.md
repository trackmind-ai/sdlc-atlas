---
name: index-strategy
description: "Select and safely create the right PostgreSQL index type for an access pattern."
when_to_use: index-agent proposing or reviewing an index
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

# Index Strategy

1. B-tree (default): equality/range/`ORDER BY`/`BETWEEN`. Use for FK columns, frequent filters/sorts.
2. Composite: order by selectivity/most-frequent-filter first; index on `(a,b)` serves `WHERE a=? AND b>?` but not `WHERE b=?` alone.
3. Covering (`INCLUDE (...)`): add non-key columns to enable index-only scans, skip heap visits.
4. Partial (`WHERE status='active'`): index only the hot subset instead of the full table.
5. Expression (`ON tbl (LOWER(email))`): for computed search keys — query predicate must match the expression exactly.
6. GIN: JSONB containment/existence (`@>`, `?`), array containment/overlap (`@>`, `&&`), full-text `tsvector` (`@@`).
7. GiST: range types, geometry, exclusion constraints (`EXCLUDE USING gist`).
8. BRIN: very large, naturally-ordered tables (time-series, insertion-order correlated) — minimal storage overhead.
9. Every FK column gets a manual index — Postgres never creates this automatically.
10. Verify with `EXPLAIN ANALYZE` (query-explain-analyze skill) after creation that the planner actually uses the new index.

## Hard rules

- `CREATE INDEX CONCURRENTLY` only for any table that may see concurrent writes — never a plain blocking `CREATE INDEX` on a live table.
- No index without a real query/join/sort backing it — every index costs write amplification.
- GIN/GiST/BRIN choice must be justified by the operator class actually used in queries.
- Route creation through migration-safety-agent — never apply directly to shared/production DB.
