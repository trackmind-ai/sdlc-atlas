# Stack: React (L1)
React 18 + TypeScript + Vite. Installs into a project's `.claude/` via `install.sh --stack react --project <path>`.
Project files win any filename collision. Declare `stack: react` in project CLAUDE.md.
Provides: component-agent, state-agent, api-agent, auth-agent + skills.
Defaults: test `npx vitest run --coverage`, security `npm audit --audit-level=high`, lint `npx eslint . && npx tsc --noEmit`.
