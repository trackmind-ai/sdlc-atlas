# /setup-auth
Invoke guard-interceptor-agent with guard-interceptor-pattern skill to scaffold JWT auth and RBAC.
Produces: `JwtStrategy`, `JwtAuthGuard`, `RolesGuard` + `@Roles()` decorator, global exception filter, token deny-list for revocation.
Requires: User entity/service already in place.
Spec-only — refuses auth/authorization patterns not specified.
