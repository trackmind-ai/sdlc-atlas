---
name: nextjs-endpoint
description: Procedure for creating Next.js Route Handlers and Node.js/Express API endpoints.
---
# Next.js Endpoint Procedure

1. Create route handler at `app/api/<resource>/route.ts` exporting named HTTP methods (GET, POST, PUT, DELETE).
2. Parse and validate request body/params with Zod before any processing.
3. Return typed `NextResponse.json(data, { status: NNN })` — always explicit status codes.
4. Handle errors: catch, log, return `{ error: string }` with appropriate 4xx/5xx status.
5. For Node.js/Express: register route in `server/routes/<resource>.ts`; use express-validator or Zod.
6. Never access DB directly from client components — only from route handlers or server actions.
7. Add JSDoc comment describing the endpoint purpose and expected request/response shape.
8. Write at least one happy-path test and one error-path test per endpoint.
9. Run `npm audit --audit-level=high` — fix any high/critical findings before PR.
10. Run `npx eslint .` and `npx tsc --noEmit` — zero errors required.
