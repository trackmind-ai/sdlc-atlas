---
name: vue-composable
description: Procedure for authoring reusable Composition API composables in Vue 3.
---
# Vue Composable Procedure

1. Name every composable with a `use` prefix (`useDebounce`, `useAuth`, `useCart`).
2. Place in `src/composables/<useName>.ts`, one composable per file.
3. Accept flexible inputs via `MaybeRef<T>`; unwrap with `toValue()` so callers can pass a ref, getter, or plain value.
4. Return reactive values only — `ref`, `computed`, or `reactive` — never plain primitives; callers rely on reactivity.
5. Async composables: return the `{ data, error, loading }` pattern.
6. Register watchers with `watch`/`watchEffect`; clean up via `onWatcherCleanup()` (Vue 3.5+) or `onUnmounted()` — abort in-flight requests with `AbortController`.
7. No module-scope side effects (no top-level `fetch`, no top-level DOM access) — everything lives inside the composable function body.
8. Composables replace mixins entirely — never introduce a mixin as an alternative.
9. Tests: call the composable inside a throwaway component via `mount()`, or use `@vue/test-utils` app context if no template is needed; assert reactive output changes.
10. Run `npx vue-tsc --noEmit` before considering done.
