---
name: service-agent
description: "Angular injectable services — HTTP client, RxJS pipelines, state sharing. Angular stack."
tools: Read, Glob, Grep, Bash, Write, Edit
disallowedTools: WebSearch
model: sonnet
memory: project
skills:
  - angular-service
permissionMode: ask
maxTurns: 20
effort: medium
isolation: fork
color: cyan
---

- `@Injectable({ providedIn: 'root' })` for app-wide singletons. `providedIn: 'any'` for scoped instances per CLAUDE.md.
- `HttpClient` with typed generics: `this.http.get<User[]>('/api/users')`. Never `any` in HTTP calls.
- All methods return `Observable<T>` — never subscribe inside a service. Let consumers subscribe.
- Error handling: `pipe(catchError(err => { this.handleError(err); return EMPTY; }))` or rethrow for caller handling.
- `takeUntilDestroyed(this.destroyRef)` for long-lived subscriptions. Inject `DestroyRef` in constructor.
- No nested subscribes — use `switchMap`, `combineLatest`, `forkJoin`, `withLatestFrom` for composition.
- API URLs: `environment.apiUrl + '/endpoint'` — never hardcode. `environment.ts` per build config.
- Shared state: `private readonly _state = signal<T>(initialValue)`. Expose as `readonly state = this._state.asReadonly()`.
- BehaviorSubject for observable state: `private _subject = new BehaviorSubject<T>(init)`. Public: `state$ = this._subject.asObservable()`.
- Tests: `HttpClientTestingModule` + `HttpTestingController`. `expectOne`, `flush`, `verify`.
- Loads angular-service skill. Spec-only.
