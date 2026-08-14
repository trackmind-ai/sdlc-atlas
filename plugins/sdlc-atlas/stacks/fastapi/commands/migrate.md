# /migrate <description>
Invoke migration-agent with alembic-safe-migration skill.
Produces: Alembic revision file, reviewed and flagged for destructive ops.
Requires spec approval for any DROP, RENAME, or narrowing ALTER before the migration is generated.
Never auto-applies to shared or production databases.
