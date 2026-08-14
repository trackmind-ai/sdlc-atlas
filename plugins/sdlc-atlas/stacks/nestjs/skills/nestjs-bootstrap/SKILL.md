---
name: nestjs-bootstrap
description: "NestJS project scaffold checklist -- deps, layout, DI wiring, CI."
when_to_use: bootstrap-agent or setup-agent scaffolding a new NestJS project with no existing structure
disable-model-invocation: false
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Bash
model: sonnet
effort: medium
context: []
---

# NestJS Bootstrap Procedure

1. `nest new <project> --package-manager npm` or scaffold manually; pin versions in `package.json` for `@nestjs/core`, `@nestjs/common`, `@nestjs/platform-express` (or `-fastify`), `@nestjs/config`, `@nestjs/typeorm` or `@prisma/client`, `class-validator`, `class-transformer`, `jest`, `eslint`, `prettier`.
2. Layout: `src/modules/<domain>/{<domain>.module.ts, controllers/, services/, dto/, entities/}`, `src/core/{filters/, guards/, interceptors/}`, `src/shared/`, `src/config/`, `src/main.ts`, `src/app.module.ts`.
3. `src/main.ts`: `NestFactory.create(AppModule)`, `app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))`, global exception filter.
4. `src/app.module.ts`: `ConfigModule.forRoot({ isGlobal: true, envFilePath: '.env.${NODE_ENV}' })` once; DB module via `forRootAsync` + `ConfigService`.
5. `tsconfig.json`: `strict: true`, `noImplicitAny: true` — never relax.
6. `.eslintrc`: `@typescript-eslint/recommended` + `no-explicit-any: error`; `prettier` config committed.
7. `jest.config.js`: `coverageThreshold` set; separate `test/jest-e2e.json` for Supertest e2e.
8. One smoke test: `GET /health` returns `{ status: 'ok' }` 200 — must pass before handing to spec-agent.
9. CI: install → build → eslint → jest --coverage → npm audit on every PR.
10. `package.json` scripts: `build`, `test`, `test:e2e`, `test:cov`, `lint`, `start:dev`.

## Hard rules

- `synchronize: false` on every ORM config, all environments — never rely on auto-sync.
- No `any` types anywhere in scaffolded code.
- Global `ValidationPipe` must be present in `main.ts` before handing off — missing pipe is a blocking finding.
