---
name: express-endpoint
description: "Express/Fastify endpoint implementation checklist."
---
1. Define Zod schema for request body, params, and query before writing handler. `z.object({...}).strict()`.
2. Validate at boundary: `const data = schema.safeParse(req.body); if (!data.success) return res.status(422).json(data.error.errors)`.
3. Handler extracts validated data only: `const { name, email } = data.data`. No `req.body.anything` in handler.
4. Service function: `async function createUser(data: CreateUserInput): Promise<User>` — typed in, typed out.
5. Auth middleware before route: `router.use('/admin', authenticate, authorize(['admin']))`.
6. Error middleware at app level: `app.use((err, req, res, next) => { if (err instanceof AppError) res.status(err.statusCode).json(...); else res.status(500)... })`.
7. Request ID: `req.id = req.headers['x-request-id'] || uuid()` in first middleware. Pass to logger.
8. Pino logger: `const log = logger.child({ requestId: req.id, route: req.path })`. Never `console.log`.
9. Status codes: 200 GET/PUT, 201 POST with `Location` header, 204 DELETE, 400 business rule, 422 schema, 404 not found, 409 conflict.
10. Never return raw DB errors to client — map to safe error messages in error middleware.
11. Tests: `supertest(app).post('/route').send(body).expect(201)`. Assert shape with `expect(res.body).toMatchObject({...})`.
12. Rate limiting: `express-rate-limit` on auth endpoints — configure in CLAUDE.md.
13. CORS: `cors()` configured per environment — never `origin: '*'` in production.
14. Compression: `compression()` middleware for all GET responses > 1KB.
15. OpenAPI: add JSDoc `@swagger` annotation per route handler for schema generation.
