---
name: new-endpoint
description: "DTO -> controller -> service -> test checklist for NestJS REST endpoints."
when_to_use: controller-agent building or reviewing a REST endpoint against an approved spec
disable-model-invocation: false
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
model: sonnet
effort: medium
context: []
---

# New Endpoint Procedure

1. `Create<Resource>Dto` / `Update<Resource>Dto` classes with `class-validator` decorators (`@IsString()`, `@IsEmail()`, `@Min()`) — never a shared or untyped DTO for input.
2. Response type/DTO exposes only spec-listed fields — never return the ORM entity directly.
3. `@Controller('<resource>')`, constructor-injected service — one method per verb (GET list/one, POST create, PATCH update, DELETE).
4. `@Body() dto: Create<Resource>Dto`, `@Param('id') id: string`, `@Query() query: Find<Resource>Dto` — never `@Body() body: any`.
5. Global `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })` must be active in `main.ts` — flag if missing.
6. Explicit status per route: `@HttpCode(HttpStatus.CREATED)` for POST, default 200 for GET/PATCH, 204 for DELETE.
7. Errors via built-in exceptions (`NotFoundException`, `ForbiddenException`) or `HttpException` — never custom `{ error }` objects.
8. Delegate all logic to the service — zero business logic in the controller body.
9. Only use `@Res()` for streaming/SSE, always with `{ passthrough: true }`.
10. Pagination: `@Query('skip') skip = 0`, `@Query('limit') limit = 20` validated via DTO — never unbounded queries.
11. Tests (`Test.createTestingModule` + Supertest): 200/201 happy path with shape assertion, 400 validation error, 401/403 if guarded, 404 not-found.

## Hard rules

- Never reuse the same class for request input and response output.
- Never put business logic in a controller method.
- Never skip the global `ValidationPipe` — treat its absence as a blocking finding.
- Refuse endpoints/fields not present in the approved spec — escalate via /change-feature instead.
