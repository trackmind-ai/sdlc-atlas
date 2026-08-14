---
name: alembic-safe-migration
description: Safe Alembic migration checklist for FastAPI + SQLAlchemy 2.
---
# Alembic Safe Migration Checklist

1. Run `alembic check` first — abort if pending migrations exist.
2. `alembic revision --autogenerate -m "<verb>_<resource>_<description>"` — read generated file before proceeding.
3. Flag operations needing spec approval: `op.drop_table`, `op.drop_column`, `op.alter_column` (narrowing type/nullability), `op.rename_table`.
4. Additive-first: new column → add as `nullable=True` this release; add `NOT NULL` constraint next release after backfill.
5. Every `op.execute()` SQL must have matching `downgrade()` reversal or comment: `# irreversible — acknowledged in spec §N`.
6. Large table indexes: use `postgresql_concurrently=True`; wrap in `op.execute("SET lock_timeout = '5s'")`.
7. Data migration: separate revision; use chunked updates (`LIMIT 1000`) with a `WHERE migrated_at IS NULL` guard.
8. Naming conventions: `BatchOperations` context for SQLite-compatible alter; explicit constraint names matching `MetaData(naming_convention={...})`.
9. Verify `alembic heads` shows a single head before merging.
10. `alembic downgrade -1` must succeed in a dev environment before merging the migration.
