---
name: safe-migration
description: "Safe TypeORM/Prisma migration checklist for NestJS."
when_to_use: orm-migration-agent generating, reviewing, or reasoning about a schema migration
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

# Safe Migration Checklist

1. Run `npx typeorm migration:show` or `npx prisma migrate diff` first — abort if unapplied migrations exist.
2. `npx typeorm migration:generate -n <Verb><Resource><Description>` or `npx prisma migrate dev --create-only` — read the generated file before proceeding.
3. Flag operations needing explicit spec approval: `dropColumn`, `dropTable`, narrowing `changeColumn`/`alterColumn`, `renameColumn`/`renameTable`.
4. Additive-first: new column as `nullable: true` this release; add `NOT NULL` constraint next release after backfill.
5. Every raw `queryRunner.query()` must have a matching `down()` reversal, or comment `-- irreversible — acknowledged in spec §N`.
6. `synchronize: false` always, all environments — flag any config with `synchronize: true` as blocking.
7. Large-table index creation: note lock behavior in the PR; recommend `CREATE INDEX CONCURRENTLY` equivalent where the DB supports it.
8. Data migrations: separate migration file, chunked updates with a `WHERE migrated_at IS NULL` guard, row-count logged.
9. Verify a single migration head/history line before merging — no diverging migration branches.
10. Dry-run the down migration in a dev environment before merging where the ORM supports it.

## Hard rules

- Never auto-apply a migration to a shared or production database.
- Never run `migration:revert`, `schema:drop`, `prisma migrate reset`, or `prisma migrate deploy` from this skill.
- Any destructive operation (`dropColumn`, `dropTable`, narrowing alter, rename) requires explicit spec approval before generation proceeds.
