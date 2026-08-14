---
name: prisma-safe-migration
description: "Safe Prisma migration checklist — additive-first, reviewed SQL."
---
1. Never edit an existing migration file in `prisma/migrations/` — always generate a new one.
2. `prisma validate` before generating — fix schema errors before creating migration.
3. `npx prisma migrate dev --name <description> --create-only` — generates SQL without applying.
4. Read the generated SQL in `prisma/migrations/<timestamp>_<name>/migration.sql` before applying.
5. Flag destructive SQL: `DROP COLUMN`, `ALTER COLUMN ... TYPE`, `DROP TABLE`, `DROP INDEX` — require spec approval.
6. Additive-first: add `String?` (nullable) first release → data migration to fill → add `@default` or NOT NULL constraint next release.
7. Enum: only `AddValue` is safe. Renaming or removing enum values requires two-release pattern.
8. Index on large table: use `CREATE INDEX CONCURRENTLY` via raw SQL migration with `-- CreateIndex CONCURRENTLY` comment.
9. Data migration: separate TypeScript script using `prisma.$transaction`, `take: 1000` batches, log progress.
10. `npx prisma migrate deploy` for production — never `migrate dev` in production environment.
11. `npx prisma migrate diff` to verify expected changes before applying in staging.
12. Rollback plan: document in PR for each destructive step. Prisma has no automatic rollback.
13. `npx prisma db seed` for test fixtures only — never in production migration.
14. Never `migrate reset` on shared environments — wipes all data.
15. Zero-downtime: for large table operations, schedule during maintenance window or use shadow table approach.
