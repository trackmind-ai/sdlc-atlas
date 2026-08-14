---
name: ngrx-store
description: "NgRx feature store implementation checklist."
---
1. File layout: `feature.actions.ts`, `feature.reducer.ts`, `feature.selectors.ts`, `feature.effects.ts`, `feature.state.ts`.
2. State shape: `{ data: T | null; items: T[]; loading: boolean; error: string | null }` per feature.
3. Actions: `createAction('[Feature] Load', props<{ id: string }>())`. Past-tense for events, imperative for commands.
4. Reducer: `createReducer(initialState, on(load, state => ({ ...state, loading: true, error: null })), on(loadSuccess, (state, { data }) => ({ ...state, data, loading: false })), on(loadFailure, (state, { error }) => ({ ...state, error, loading: false })))`.
5. Never mutate state. Use spread (`{ ...state }`) or Immer (`produce`) — never `state.field = value`.
6. Feature selector: `createFeatureSelector<FeatureState>('featureName')`. All other selectors derived from it.
7. Selectors: `createSelector(featureSelector, state => state.items)`. Compose for computed: `createSelector(itemsSelector, ids => items.filter(...))`.
8. Effects: import `Actions`, `inject(FeatureService)`. Always handle errors with `catchError(err => of(loadFailure({ error: err.message })))`.
9. `switchMap` for latest-value (search), `exhaustMap` for user clicks (prevent double-submit), `concatMap` for ordered writes.
10. Lazy register: `provideState(featureReducer)` + `provideEffects([FeatureEffects])` in route-level `providers`.
11. Signal Store (`@ngrx/signals`): for simpler local feature state — `signalStore({ withState(), withComputed(), withMethods() })`.
12. `ngrxOnInitStore` for side effects on store init (e.g., initial data load).
13. Reducer tests: `expect(reducer(undefined, action)).toEqual(expectedState)` for each action.
14. Selector tests: `expect(selector.projector(mockState)).toEqual(expected)`.
15. Effect tests: `TestBed` with `provideMockActions(actions$)` and mock service. Assert dispatched actions.
