---
name: react-bootstrap
description: Greenfield scaffold procedure for a new React 18 + TypeScript + Vite project.
---
# React Bootstrap Procedure

1. Scaffold: `npm create vite@latest frontend -- --template react-ts`.
2. Install core deps: `npm install axios @tanstack/react-query zustand react-router-dom`.
3. Install dev deps: `npm install -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom`.
4. Pin exact versions; commit `package-lock.json`.
5. Layout: `src/components/`, `src/pages/`, `src/hooks/`, `src/services/`, `src/stores/`, `src/types/`, `src/lib/`.
6. Configure Vitest: add `test` config block in `vite.config.ts` with `environment: 'jsdom'` and `setupFiles: './src/test/setup.ts'`.
7. Add `.env.example` with `VITE_API_URL=http://localhost:8000`; add `.env.local` to `.gitignore`.
8. ESLint: extend `eslint:recommended` + `plugin:@typescript-eslint/recommended`; add `react-hooks` plugin.
9. Add `Makefile` targets: `make test`, `make lint`, `make build`, `make dev`.
10. Smoke test: one render test for `<App />` must pass before handing to spec-agent.
11. Run `npx tsc --noEmit` and `npm run build` — zero errors required.
