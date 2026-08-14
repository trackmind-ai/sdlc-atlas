---
name: nextjs-bootstrap
description: Greenfield scaffold procedure for a new Next.js 14+ App Router project with Node.js backend.
---
# Next.js Bootstrap Procedure

1. Scaffold frontend: `npx create-next-app@latest frontend --typescript --tailwind --eslint --app --src-dir=no --import-alias "@/*"`.
2. Scaffold backend: `mkdir backend && cd backend && npm init -y && npm install express zod cors dotenv && npm install -D typescript @types/express @types/node ts-node-dev`.
3. Pin exact versions in both `package.json` files; commit lock files.
4. Frontend layout: `app/layout.tsx`, `app/page.tsx`, `app/globals.css`, `components/`, `lib/`.
5. Backend layout: `src/index.ts`, `src/routes/`, `src/middleware/`, `src/db/`.
6. Add `.env.local` (frontend) and `.env` (backend) to `.gitignore`; provide `.env.example` for each.
7. Configure Jest: `npm install -D jest @testing-library/react @testing-library/jest-dom jest-environment-jsdom ts-jest`.
8. Add `jest.config.js` pointing at `src/**/*.test.tsx?`; add `"test": "jest --coverage"` script.
9. Run `npm run build` (frontend) and `npx tsc --noEmit` (backend) — zero errors required.
10. Run `npm test` — smoke test must pass before handing to spec-agent.
