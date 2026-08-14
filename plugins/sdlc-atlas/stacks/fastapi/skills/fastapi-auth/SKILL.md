---
name: fastapi-auth
description: FastAPI JWT auth setup — token issuance, verification, refresh, revocation.
---
# FastAPI Auth Procedure

1. Settings: `SECRET_KEY`, `ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES`, `REFRESH_TOKEN_EXPIRE_DAYS` from `pydantic-settings`.
2. Password hashing: `passlib.context.CryptContext(schemes=["bcrypt"], deprecated="auto")` — `verify_password` and `get_password_hash` helpers.
3. Token creation: `python-jose` `jwt.encode({"sub": str(user_id), "exp": ...}, SECRET_KEY, algorithm=ALGORITHM)`.
4. `get_current_user` dependency: decode JWT, look up user in DB, raise `HTTPException(401)` on any failure.
5. OAuth2PasswordBearer scheme on `/auth/login` returning `{access_token, token_type, refresh_token}`.
6. Refresh endpoint `POST /auth/refresh`: validate refresh token from DB deny-list, issue new pair, revoke old.
7. Deny-list: store revoked refresh token JTIs in Redis with TTL = remaining expiry; check on every use.
8. Logout endpoint `POST /auth/logout`: add current refresh token JTI to deny-list; return 204.
9. Tests: valid login 200, wrong password 401, expired access token 401, revoked refresh token 401, logout then refresh 401.
