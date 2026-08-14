---
name: react-developer
description: >
  Activate for React web application development tasks.
  Trigger phrases: "react component", "react hook", "useState", "useEffect",
  "react context", "JSX", "react state", "react props", "react router",
  "tanstack query", "react query", "react memo", "react performance",
  "react form", "react error boundary", "react testing library".
  Do NOT activate for React Native/mobile, Vue, Angular, Svelte, or generic
  TypeScript tasks unrelated to React.
user-invocable: false
---

# React Development Rules

## Code Style & Organization

- USE functional components with TypeScript (`.tsx`) exclusively — class components are obsolete and incompatible with hooks
- USE PascalCase for component filenames and component names; `usePrefix` for custom hooks — consistent naming enables fast discovery
- PREFER feature-based directory structure (`src/features/<name>/{components,hooks,api}`) over layer-based (`components/`, `hooks/`) — co-locates related code and scales without cross-cutting pollution
- USE one component per file; allow small, stateless, closely related components as exceptions — large files hide unrelated concerns
- ALWAYS write named exports for components, not default exports — enables better refactoring and barrel exports
- NEVER use array indices as list `key` props — index keys break reconciliation when items are reordered or removed

## Component Design

- USE pure functional components: same inputs must always produce the same output — impure renders are non-deterministic and break concurrent mode
- NEVER mutate props or state directly; always derive new objects/arrays (`[...arr]`, `{ ...obj }`) — React relies on reference equality for change detection
- NEVER call component functions directly; always render via JSX (`<MyComponent />`) — direct calls bypass React's reconciliation lifecycle
- PREFER separating "smart" (data/logic) from "dumb" (presentational) components — presentational components are pure, trivially testable
- USE composition over prop drilling: pass children or components as props before reaching for context — keeps coupling explicit
- AVOID prop drilling beyond two levels; lift state or use context/store instead — deep drilling makes refactoring brittle

## Hooks

- ALWAYS call hooks at the top level of a function, never inside conditionals, loops, or callbacks — React tracks hook order by call position
- USE custom hooks to extract reusable stateful logic out of components — hooks shared across two or more components belong in their own file
- ALWAYS specify correct `useEffect` dependency arrays; include every reactive value the effect reads — stale closures produce subtle, hard-to-diagnose bugs
- ALWAYS return a cleanup function from `useEffect` for subscriptions, timers, and event listeners — prevents memory leaks on unmount
- NEVER use `useEffect` to fetch data in new code; use TanStack Query or a route loader instead — effects for data fetching create race conditions and waterfall requests
- USE `useReducer` when state transitions involve multiple sub-values or when next state depends on previous state — reducer logic is easier to test in isolation

## State Management

- USE `useState` for local, ephemeral UI state; use a dedicated library (Zustand, Jotai) for shared cross-feature state — Context re-renders all consumers on every change
- USE Context API only for low-frequency global values (theme, locale, auth identity) — high-frequency updates through context cause cascading re-renders
- KEEP state as close as possible to where it is consumed — distant state ownership makes data flow harder to trace
- NEVER store derived data in state; compute it from existing state with `useMemo` or inline — duplicate state goes stale and diverges

## Data Fetching (TanStack Query)

- USE TanStack Query for all server state; distinguish server state from UI state — they have different lifecycles and caching needs
- ALWAYS define query keys as structured arrays using a key-factory object (`userKeys.detail(id)`) — enables precise invalidation without guessing key shape
- ALWAYS wrap `useQuery`/`useMutation` calls in custom hooks — centralizes caching config and prevents per-component duplication
- USE the `enabled` option to gate queries on required data (`enabled: !!userId`) — prevents fetching with incomplete params
- USE `select` inside `useQuery` to transform or filter data — transformation at the hook level avoids re-computation in every consumer
- USE `queryClient.setQueryData` + `invalidateQueries` after mutations — provides instant UI feedback before the refetch settles
- DEFINE `queryFn` as a named function reference, not an inline arrow — improves debuggability in DevTools and simplifies testing

## Performance

- APPLY `React.memo`, `useCallback`, and `useMemo` only after profiling confirms a bottleneck — premature memoization adds cognitive overhead without benefit
- USE `useCallback` with functional state updater (`setCount(prev => prev + 1)`) to avoid `count` in dependencies — removes the need for the state variable as a dependency
- USE `React.lazy` + `Suspense` for route-level code splitting — reduces initial bundle size without manual chunking
- ALWAYS pass a stable `key` to list items; prefer entity IDs — unstable keys cause unnecessary unmount/remount cycles
- AVOID creating objects or arrays inline in JSX props passed to memoized children — inline literals break `React.memo` by failing reference equality

## Routing (React Router v7 / TanStack Router)

- USE loaders to prefetch route data before render — eliminates post-render waterfall fetches
- KEEP loaders deterministic and side-effect free; validate params at the loader boundary — predictable loaders are cacheable and testable
- USE actions for mutations triggered by route forms; prefer `<Form>` and `useFetcher` for progressive enhancement
- STORE shareable filter/pagination state in URL search params, not component state — links and back-button navigation work correctly
- EXPORT a route-specific `ErrorBoundary` from each route module — scopes errors to the affected route rather than crashing the whole app
- NEVER duplicate loader fetches in `useEffect` — the loader has already populated the cache

## Error Handling

- USE `ErrorBoundary` components at page and feature level, not just app root — granular boundaries let other parts of the UI stay functional
- HANDLE async errors in query/mutation `onError` callbacks and render appropriate fallback UI
- SHOW user-friendly messages for expected failure states (network errors, 404s); log unexpected errors with context
- NEVER swallow errors silently — silent failures make debugging production issues nearly impossible

## Testing

- USE React Testing Library; query elements by role, label, or accessible text — tests that match user behavior survive implementation refactors
- TEST user interactions and visible output, not internal state or component instance — implementation-detail tests break on benign refactors
- PROVIDE cleanup-safe renders: RTL's `render` auto-cleans between tests when using Jest globals
- MOCK network at the service boundary (MSW or inline fetch mock), not at the component level — keeps tests environment-independent
- ADD integration tests for critical form submissions and navigation flows — unit tests alone miss interaction bugs between components

## Accessibility

- USE native semantic HTML elements (`<button>`, `<a>`, `<input>`, `<nav>`) before adding ARIA — native elements carry implicit roles and keyboard behavior for free
- NEVER use `<div onClick>` as an interactive control — divs are not keyboard accessible and are invisible to screen readers
- ENSURE all form inputs have associated `<label>` elements — required for screen reader announcement and clickable label UX
- MANAGE focus explicitly after modal open/close and route transitions — prevents focus from vanishing into the document root
