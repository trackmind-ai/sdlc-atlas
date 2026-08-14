---
name: react-state
description: Procedure for React 18 state management with React Query and Zustand.
---
# React State Management Procedure

1. Server state (fetched/mutated via API): use TanStack Query (`useQuery`, `useMutation`). Never useState for this.
2. UI/client state (modals, tabs, form drafts): use Zustand store or React Context — pick one per domain.
3. Zustand store: one file per domain (`src/stores/<domain>.ts`); use `immer` middleware for nested updates.
4. Query keys: define as constants in `src/lib/queryKeys.ts` — never inline string arrays.
5. `useQuery`: set `staleTime` explicitly; default to `staleTime: 5 * 60 * 1000` unless spec says otherwise.
6. `useMutation`: call `queryClient.invalidateQueries` in `onSuccess` to keep cache fresh.
7. Optimistic updates: use `onMutate` + `onError` rollback — document the rollback path in a comment.
8. Error handling: surface React Query errors via an `ErrorBoundary` or a toast notification — never swallow.
9. Context: use only for truly global, rarely-changing data (auth user, theme). Colocate provider near its consumers.
10. Custom hooks: extract any `useQuery`/`useMutation` combo into a `use<Resource>` hook in `src/hooks/`.
