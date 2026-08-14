# PostgreSQL (L1 — data layer)
Installs into a project's `.claude/` via `install.sh --stack postgresql --project <path>`.
Declare `stack: postgresql` in project CLAUDE.md — used alongside a backend stack (Django/FastAPI/Node/NestJS/etc), not standalone.
Provides: schema-design-agent, migration-safety-agent, query-performance-agent, index-agent + skills.
Defaults (project may override): migration check `psql -c '\d+ <table>' && migration-tool plan/dry-run`, query lint `EXPLAIN (ANALYZE, BUFFERS) <query>` review, security `psql -c '\du+'` role/permission audit.
