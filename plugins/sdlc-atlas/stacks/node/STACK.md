# Stack: Node (L1)
Installs into a project's `.claude/` via `install.sh --stack node --project <path>`.
Project files win any filename collision. Declare `stack: node` in project CLAUDE.md.
Provides: api-agent, prisma-agent, queue-agent, query-agent, auth-agent + skills.
Defaults (project may override): test `npm test -- --coverage`, security `npm audit --audit-level=high`, lint `npx eslint . && npx tsc --noEmit`.
