---
name: safe-migration-review
description: "Safe PostgreSQL migration checklist — lock-aware, additive-first, no destructive ops without approval."
when_to_use: migration-safety-agent reviewing or generating a migration
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

# Safe Migration Review

1. Never edit an applied/existing migration file — always generate a new one.
2. Dry-run/plan first (`--plan`/`--sql`/`--dry-run` or read generated SQL) before any apply.
3. Additive-first: add nullable column → backfill (batched, resumable, row count logged) → add `NOT NULL`/constraint next migration.
4. `DROP COLUMN`/`DROP TABLE`: only after all code reads/writes to it are removed (two-release pattern) + backup/restore note.
5. `RENAME COLUMN`/`RENAME TABLE`: two-phase — add new + copy-data migration, drop old in a later migration. Never single-step rename on a shared DB.
6. `ALTER COLUMN TYPE` narrowing (text→int, nullable→NOT NULL on populated column): flag in PR, requires sign-off for large tables.
7. Any raw destructive SQL needs a reverse statement or comment `-- irreversible: acknowledged in spec §N`.
8. Index creation on a live table: `CREATE INDEX CONCURRENTLY` only — never blocking `CREATE INDEX` on >1M rows.
9. Long-running `ALTER TABLE` (rewrites table): note lock type (`ACCESS EXCLUSIVE` etc.) in PR, schedule for low-traffic window.
10. Data backfills: batched (`LIMIT`/chunk), resumable via a `WHERE NOT migrated` predicate, row count logged.
11. Plan/generated SQL output pasted verbatim into PR description.
12. Never apply directly to shared/production DB — output is reviewed, human/CI applies.

## Hard rules

- No `DROP DATABASE`, `DROP TABLE` w/o backup note, `TRUNCATE`, unqualified `DELETE`/`UPDATE`.
- No plain `CREATE INDEX` on a live table >1M rows.
- Every destructive op has a reverse path or cited spec acknowledgment.
