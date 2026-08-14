---
name: jwt-auth
description: "JWT authentication implementation checklist."
---
1. Algorithm: RS256 with `fs.readFileSync` for key pair. HS256 only if CLAUDE.md explicitly specifies.
2. Sign: `jwt.sign(payload, privateKey, { algorithm: 'RS256', expiresIn: '15m', issuer: APP_URL })`.
3. Verify: `jwt.verify(token, publicKey, { algorithms: ['RS256'], issuer: APP_URL })` in middleware.
4. Access token payload: `{ sub: userId, role, iat, exp }` only. No sensitive data in payload.
5. Refresh token: opaque random string (`crypto.randomBytes(64).toString('hex')`), stored hashed in DB with expiry.
6. Storage: HttpOnly + Secure + SameSite=Strict cookie. Never localStorage or sessionStorage.
7. `authenticate` middleware: extract from `Authorization: Bearer <token>` or cookie → verify → `req.user = decoded`.
8. `authorize(roles: string[])` middleware: `if (!roles.includes(req.user.role)) throw new AppError('Forbidden', 403)`.
9. Refresh endpoint: validate refresh token hash in DB → check expiry → issue new access token → rotate refresh token.
10. Revocation: `SET revoked:<jti> EX <ttl>` in Redis. Check in `authenticate` middleware before returning user.
11. Password: `await bcrypt.hash(password, 12)` on register. `await bcrypt.compare(password, hash)` on login. Never sync.
12. Rate limit login endpoint: 5 attempts per 15 minutes per IP with `express-rate-limit`.
13. Tests: valid token 200, expired token 401, tampered token 401, wrong role 403, revoked token 401.
14. Never log tokens or passwords — log `userId` only.
15. Token rotation on every refresh — old refresh token immediately invalidated.
