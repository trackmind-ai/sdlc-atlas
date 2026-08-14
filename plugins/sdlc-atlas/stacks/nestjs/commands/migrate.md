# /migrate <description>
Invoke orm-migration-agent with safe-migration skill.
Produces: TypeORM or Prisma migration file, reviewed and flagged for destructive operations (drop, narrowing alter, rename).
Requires spec approval for any DROP, RENAME, or narrowing ALTER before the migration is generated.
Never auto-applies to shared or production databases.
