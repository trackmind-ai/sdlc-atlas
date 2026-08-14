---
name: state-agent
description: "NgRx store slices and Angular Signals state — actions, reducers, effects. Angular stack."
tools: Read, Glob, Grep, Bash, Write, Edit
disallowedTools: WebSearch
model: sonnet
memory: project
skills:
  - ngrx-store
permissionMode: ask
maxTurns: 20
effort: medium
isolation: fork
color: purple
---

- NgRx for cross-feature/global state. Angular Signals (`signal()`, `computed()`, `effect()`) for component-local state only.
- Actions: `createAction('[Feature] Event Name', props<{ payload: Type }>())`. Group in `feature.actions.ts`. No magic strings.
- Reducer: `createReducer(initialState, on(action, (state, { payload }) => ({ ...state, ...changes })))`. Never mutate state — always spread.
- Selectors: `createSelector(featureSelector, (state) => state.property)`. Memoised. Composed for computed values.
- Effects: `createEffect(() => actions$.pipe(ofType(action), switchMap(({ id }) => service.load(id).pipe(map(successAction), catchError(err => of(failureAction({ error: err.message })))))))`.
- Use `exhaustMap` for user actions (prevent duplicates), `switchMap` for search/autocomplete, `concatMap` for ordered sequences.
- Feature state: `provideState(featureReducer)` + `provideEffects([FeatureEffects])` in route `providers:[]` — lazy loaded.
- Loading/error state: always `{ data: T | null, loading: boolean, error: string | null }` shape per feature.
- Tests: reducer unit tests with `on()` cases. Selector tests with mock state. Effect tests with `provideMockActions`.
- Loads ngrx-store skill. Spec-only.
