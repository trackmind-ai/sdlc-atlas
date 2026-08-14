# /setup-auth
Invoke auth-agent with fastapi-auth skill to scaffold the full JWT authentication system.
Produces: `/auth/login`, `/auth/refresh`, `/auth/logout` routes, `get_current_user` dependency, password hashing helpers, refresh token deny-list.
Requires: User model and DB session already in place.
Spec-only — refuses auth patterns not specified.
