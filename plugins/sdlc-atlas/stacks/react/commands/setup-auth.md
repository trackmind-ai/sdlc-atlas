# /setup-auth
Invoke auth-agent with react-auth skill to scaffold the full authentication flow.
Produces: AuthContext, PrivateRoute, login/logout pages, axios interceptor for token refresh.
Requires: backend auth endpoints declared in spec (`/auth/login`, `/auth/logout`, `/auth/refresh`).
Spec-only — refuses auth patterns not specified.
