---
name: schema-normalization-check
description: "Checklist for PostgreSQL type/constraint/normalization choices before DDL is finalized."
when_to_use: schema-design-agent drafting or reviewing table DDL
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

# Schema Normalization Check

1. Entities/access patterns/scale captured before typing DDL (rows, QPS, retention).
2. Normalize to 3NF by default; denormalize only with a cited measurement (slow join, proven read bottleneck).
3. PK: `BIGINT GENERATED ALWAYS AS IDENTITY` default; `UUID` (`uuidv7()`/`gen_random_uuid()`) only for federation/opacity.
4. Types: `TIMESTAMPTZ` (never `TIMESTAMP`), `NUMERIC` for money (never `money`/float), `TEXT` + `CHECK(LENGTH...)` (never `VARCHAR(n)`/`CHAR(n)`), `BIGINT` over `INTEGER` unless space-constrained.
5. `NOT NULL` everywhere semantically required; `DEFAULT` for common values.
6. Every FK: explicit `ON DELETE/UPDATE` action + manual index (Postgres does not auto-index FK columns).
7. `UNIQUE (...) NULLS NOT DISTINCT` (PG15+) unless duplicate NULLs intentionally allowed.
8. Enums: `CREATE TYPE ... AS ENUM` only for small/stable sets; evolving business values → TEXT/INT + CHECK or lookup table.
9. JSONB only for optional/semi-structured attributes, GIN-indexed if queried.
10. RLS (`ENABLE ROW LEVEL SECURITY` + `CREATE POLICY`) when spec requires row-level isolation.

## Hard rules

- Reject `serial`, `varchar(n)`, `char(n)`, `money`, `timestamp` (no tz), `timetz` in any reviewed DDL.
- Reject missing FK index.
- Reject denormalization without a cited measurement.
