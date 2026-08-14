---
name: react-auth
description: Procedure for JWT auth context, protected routes, and token refresh in React.
---
# React Auth Procedure

1. `AuthContext`: provides `user`, `isAuthenticated`, `login()`, `logout()`, `refreshToken()`.
2. Token storage: access token in memory (module-level variable or Zustand); refresh token in an httpOnly cookie set by the server.
3. `PrivateRoute`: wrapper that reads `isAuthenticated`; redirects to `/login` with `state={{ from: location }}` if false.
4. On app load: call `/auth/me` (or decode stored access token) to rehydrate auth state; show a loading screen until resolved.
5. Axios interceptor handles 401: calls `refreshToken()` → retries original request once → calls `logout()` on second 401.
6. `login()`: POST credentials, store access token in memory, store refresh token via cookie (server sets it).
7. `logout()`: clear memory token, POST `/auth/logout` to revoke refresh token, redirect to `/login`.
8. Tests: verify redirect for unauthenticated, verify no redirect for authenticated, verify token refresh called on 401.
9. Never log or expose token values in error messages or console statements.
