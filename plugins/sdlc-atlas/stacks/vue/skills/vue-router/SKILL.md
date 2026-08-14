---
name: vue-router
description: Procedure for Vue Router route tables, guards, and lazy-loaded views.
---
# Vue Router Procedure

1. Define routes in `src/router/index.ts`: `{ path, name, component: () => import('...'), meta }` — always lazy-load via dynamic import.
2. Pass route params as props: `props: true` on the route record; components receive params typed, not via `$route.params` directly.
3. Protect routes with `meta: { requiresAuth: true }`, enforced in a single `router.beforeEach` guard that checks the Pinia auth store.
4. Unauthenticated redirect: `return { name: 'login', query: { redirect: to.fullPath } }` — never a bare `next(false)`.
5. Reactive params: if a component stays mounted across param changes (e.g. `/users/:id` → `/users/:id2`), wrap `route.params.id` in a `computed` and `watch` it — do not rely on remount.
6. Nested/child routes: declare under a parent route's `children` array; use `<router-view>` in the parent template.
7. Route names are unique strings; navigate with `router.push({ name, params })`, never hardcoded path strings.
8. 404/catch-all route: last entry, `path: '/:pathMatch(.*)*'`.
9. Tests: mount with a test router instance (`createRouter` + memory history); assert guard redirects and rendered route component.
