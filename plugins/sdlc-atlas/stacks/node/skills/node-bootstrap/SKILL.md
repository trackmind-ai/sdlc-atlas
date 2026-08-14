---
name: node-bootstrap
description: "Node.js project scaffold checklist."
---
1. `npm init -y` → set `engines.node` to LTS version. `"type": "module"` for ESM or omit for CJS — match CLAUDE.md.
2. Core deps: `express`/`fastify`, `zod`, `@prisma/client`, `pino`, `pino-http`, `jsonwebtoken`, `bcryptjs` — all pinned with `--save-exact`.
3. Dev deps: `typescript`, `ts-node`, `@types/node`, `vitest`/`jest`, `supertest`, `@types/supertest`, `eslint`, `prettier` — pinned.
4. `tsconfig.json`: `strict: true`, `target: ES2022`, `moduleResolution: node16`, `outDir: dist`, `rootDir: src`.
5. Layout: `src/routes/`, `src/services/`, `src/middleware/`, `src/lib/`, `src/types/`, `tests/` mirrors `src/`.
6. `src/app.ts`: export `app` without `.listen()`. `src/server.ts`: import app + `.listen()`. Enables supertest testing.
7. Env: `dotenv` + `zod` schema for env validation at startup. Fail fast if required env vars missing.
8. Pino logger: `pino({ level: process.env.LOG_LEVEL || 'info' })`. `pino-http` for request logging.
9. Error classes: `class AppError extends Error { constructor(message, statusCode) {...} }`. Operational vs programmer errors.
10. `npm` scripts: `test`, `test:coverage`, `lint`, `build`, `dev` (ts-node-dev), `start` (node dist/).
11. One smoke test: `GET /health` returns `{ status: 'ok' }` with 200.
12. ESLint: `@typescript-eslint/recommended` + `no-console` rule (use pino instead).
13. Prisma: `npx prisma init`. Add `DATABASE_URL` to .env. Initial `prisma migrate dev --name init`.
14. CI: install → lint → `tsc --noEmit` → test --coverage → npm audit on every PR.
15. `Makefile`: `make test`, `make lint`, `make migrate`, `make build`.
