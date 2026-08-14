---
name: pinia-store-pattern
description: Procedure for Pinia setup stores, SSR-safe usage, and persistence in Vue 3.
---
# Pinia Store Pattern Procedure

1. Use setup stores: `defineStore('name', () => { ... })` — never the Options-store syntax.
2. One store file per domain under `src/stores/<domain>.ts` (e.g. `stores/cart.ts`, `stores/auth.ts`).
3. Return every state property, computed getter, and action from the setup function so devtools/SSR/plugins can track it.
4. Keep getters (`computed`) pure and side-effect free; put writes, I/O, and orchestration in actions.
5. Async actions: expose explicit `isLoading`/`error` state; reset stale errors before retrying.
6. Components: call the store at the top of `<script setup>`; use `storeToRefs()` when destructuring state/getters; destructure actions directly (they stay bound).
7. Do not copy server-cache data into a store unless it is an intentional editable draft or offline snapshot — use a data-fetching composable for server state instead.
8. Persistence: allowlist only the fields that must survive reload; never persist tokens, secrets, or raw PII; version and validate persisted schemas.
9. SSR: use the store only inside setup/getters/actions so Pinia resolves the active instance; never read browser-only storage during server rendering.
10. Tests: `setActivePinia(createPinia())` in `beforeEach`; test actions directly for domain behavior; use `@pinia/testing` for component tests needing stores.
