# Stack: Nextjs (L1)
Next.js 14+ App Router + TypeScript. Installs into a project's `.claude/` via `install.sh --stack nextjs --project <path>`.
Project files win any filename collision. Declare `stack: nextjs` in project CLAUDE.md.
Provides: component-agent, api-agent, state-agent + skills.
Defaults: test `npx jest --coverage`, security `npm audit --audit-level=high`, lint `npx eslint . && npx tsc --noEmit`.
