# Stack: Vue (L1)
Vue 3 + Composition API + TypeScript + Vite. Installs into a project's `.claude/` via `install.sh --stack vue --project <path>`.
Project files win any filename collision. Declare `stack: vue` in project CLAUDE.md.
Provides: component-agent, composable-agent, pinia-store-agent, router-agent + skills.
Defaults: test `npx vitest run --coverage`, security `npm audit --audit-level=high`, lint `npx eslint . && npx vue-tsc --noEmit`.
