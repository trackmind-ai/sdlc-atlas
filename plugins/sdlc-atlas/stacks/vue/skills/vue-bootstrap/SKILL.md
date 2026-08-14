---
name: vue-bootstrap
description: Greenfield scaffold procedure for a new Vue 3 + TypeScript + Vite project.
---
# Vue Bootstrap Procedure

1. Scaffold: `npm create vite@latest frontend -- --template vue-ts`.
2. Install core deps: `npm install vue-router pinia axios`.
3. Install dev deps: `npm install -D vitest @vue/test-utils @pinia/testing jsdom eslint prettier vue-tsc`.
4. Pin exact versions; commit `package-lock.json`.
5. Layout: `src/components/`, `src/composables/`, `src/views/` (or `pages/`), `src/router/`, `src/stores/`, `src/types/`, `src/lib/`.
6. Configure Vitest: `test` block in `vite.config.ts` with `environment: 'jsdom'`, `setupFiles: './src/test/setup.ts'`.
7. Add `.env.example` with `VITE_API_URL=http://localhost:8000`; add `.env.local` to `.gitignore`.
8. ESLint: `eslint-plugin-vue` recommended config + `@vue/eslint-config-typescript`; Prettier for formatting.
9. Add `package.json` scripts: `test`, `lint`, `build`, `dev`.
10. Smoke test: one render test for `<App />` (via `@vue/test-utils` `mount()`) must pass before handing to spec-agent.
11. Run `npx vue-tsc --noEmit` and `npm run build` — zero errors required.
