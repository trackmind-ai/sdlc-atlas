---
name: nextjs-component
description: Procedure for building Next.js App Router pages and React components.
---
# Next.js Component Procedure

1. Determine rendering type: Server Component (default) or Client Component (`'use client'` at leaf boundary only).
2. Create file under `app/` following route segment conventions: `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`.
3. Use `next/image` for all content images — never plain `<img>`.
4. Use Tailwind CSS classes only — no inline styles, no CSS modules unless required.
5. Wrap async route segments in `<Suspense>` with a fallback; add `loading.tsx` alongside.
6. Add `error.tsx` boundary at every segment that fetches data.
7. Export `generateMetadata` (or static `metadata`) for SEO on every page.
8. Validate prop types with TypeScript interfaces — no `any`.
9. Place shared components in `components/`; route-specific in `app/(group)/`.
10. Run `npx tsc --noEmit` and `npx eslint .` before considering done.
