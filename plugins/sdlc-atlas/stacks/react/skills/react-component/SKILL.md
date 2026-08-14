---
name: react-component
description: Procedure for building React 18 functional components with TypeScript.
---
# React Component Procedure

1. Use functional components only — no class components.
2. Define a TypeScript interface for props: `interface <Name>Props { ... }`. No `any`, no implicit `{}`.
3. File naming: PascalCase for components (`UserCard.tsx`); kebab-case for pages (`user-profile.tsx` if routing convention requires).
4. Folder layout: `src/components/<Name>/index.tsx` + `<Name>.test.tsx`; pages under `src/pages/` or `src/routes/`.
5. Styling: CSS Modules (`<Name>.module.css`) or Tailwind classes — no inline styles.
6. Images: use `<img alt="...">` with descriptive alt text — never empty alt on content images.
7. Async state: show a loading skeleton and an error message state; never leave the UI blank during fetch.
8. Memo: `React.memo` only when a profiler proves re-render cost — not by default.
9. Tests: render with `@testing-library/react`; assert visible text, not implementation details. One test file per component.
10. Run `npx tsc --noEmit` and `npx eslint .` before considering done.
