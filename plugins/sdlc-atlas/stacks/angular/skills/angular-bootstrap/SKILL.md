---
name: angular-bootstrap
description: Exact scaffold procedure for a new Angular frontend. Used by bootstrap-agent with project-bootstrap skill.
---
# Angular Bootstrap
1. In `frontend/`: `ng new` with routing, SCSS, standalone defaults (or per
   architecture doc). Pin dependencies; use `package-lock.json`.
2. Layout: `src/app/core/`, `src/app/shared/`, `src/app/features/`; environments
   for API base URL pointing at `backend/` dev server.
3. ESLint + Prettier per Angular style guide; `npm run lint` script.
4. One smoke test: AppComponent renders + health route or shell loads.
5. CI step: `npm ci` → `npm run lint` → `npm test -- --coverage --watch=false`
   → `npm audit --audit-level=<org level>`.
Verify: `npm ci`, `npm test` green, `npm run lint` clean.
