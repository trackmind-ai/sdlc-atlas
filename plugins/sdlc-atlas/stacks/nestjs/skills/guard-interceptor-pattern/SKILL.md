---
name: guard-interceptor-pattern
description: "Auth guard, RBAC, interceptor, and exception filter checklist for NestJS."
when_to_use: guard-interceptor-agent implementing or reviewing auth, authorization, caching, or error-handling cross-cutting concerns
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

# Guard / Interceptor Pattern Procedure

1. Confirm execution order for any new cross-cutting concern: Middleware → Guards → Interceptors (before) → Pipes → Handler → Interceptors (after) → Exception Filters.
2. Authentication: `AuthGuard('jwt')` from `@nestjs/passport`; `JwtStrategy extends PassportStrategy(Strategy)` from `passport-jwt`, secret via `ConfigService.getOrThrow`.
3. Authorization/RBAC: custom guard `implements CanActivate`, reads `@Roles(...)` metadata via `Reflector.getAllAndOverride` — never inline role checks in a controller.
4. Register guards with `@UseGuards(JwtAuthGuard, RolesGuard)` at controller or route level per spec.
5. Exception handling: one global `@Catch(HttpException) implements ExceptionFilter`, registered with `app.useGlobalFilters()` — never per-route try/catch producing custom error shapes.
6. Caching: `CacheInterceptor` + `@CacheKey()` + `@CacheTTL()` only on read (GET) endpoints the spec marks cacheable — never on mutating routes.
7. Token issuance: `JwtService.sign()` with TTL from config; refresh tokens tracked in a deny-list (Redis/DB) with TTL matching expiry.
8. Logout/revocation: add token JTI to deny-list; every guard checks the deny-list before accepting a token as valid.
9. Tests: guard unit test (mocked `ExecutionContext`) for allow/deny paths; e2e test for 401 unauthenticated and 403 wrong-role.

## Hard rules

- Never implement authorization checks inline inside a controller method — always via a guard.
- Never hand-roll JWT parsing — use `passport-jwt` strategy + `@nestjs/jwt`.
- Never hardcode secrets (`JWT_SECRET`, algorithm) — `ConfigService.getOrThrow` only.
- Never cache a mutating (POST/PATCH/DELETE) route.
- Refuse auth/authorization patterns not specified in the approved spec.
