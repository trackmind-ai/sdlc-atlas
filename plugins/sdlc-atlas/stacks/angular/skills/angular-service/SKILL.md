---
name: angular-service
<<<<<<< HEAD
description: "Angular service implementation checklist."
---
1. `@Injectable({ providedIn: 'root' })` for singletons. Use `'any'` for request-scoped only when CLAUDE.md says so.
2. `private readonly http = inject(HttpClient)` — field injection, no constructor params.
3. Typed HTTP: `this.http.get<User>('/api/users/1')`. Never `any`. Add `HttpContext` for custom tokens.
4. All public methods return `Observable<T>` — never subscribe inside service methods.
5. Error handling: `catchError(err => { throw new AppError(err.message, err.status) })` — let consumer decide recovery.
6. Long-lived subscriptions: `private destroyRef = inject(DestroyRef)`. Use `takeUntilDestroyed(this.destroyRef)`.
7. No nested subscribes: compose with `switchMap`, `forkJoin`, `combineLatest`, `withLatestFrom`.
8. Shared observable state: `private _items = signal<Item[]>([])`. Public: `items = this._items.asReadonly()`.
9. BehaviorSubject: `private _subject$ = new BehaviorSubject<T>(init)`. Public: `readonly state$ = this._subject$.asObservable()`. Update via `this._subject$.next(value)`.
10. API URL: `private apiUrl = inject(APP_CONFIG).apiUrl + '/resource'`. Never hardcode base URL.
11. Caching: `shareReplay(1)` to cache observable result. Reset cache by recreating subject.
12. Tests: `TestBed` with `HttpClientTestingModule`. `httpMock.expectOne('/api/...')`, `req.flush(mockData)`, `httpMock.verify()`.
13. Never expose `BehaviorSubject` directly — only expose `.asObservable()`.
14. JSDoc on every public method: `/** Loads users by team. Returns Observable<User[]>. Throws AppError on 4xx/5xx. */`.
15. Environment URLs: `environment.apiUrl` from `src/environments/environment.ts` — not from `assets/config.json` unless CLAUDE.md specifies runtime config.
=======
description: Procedure for Angular HttpClient services integrating with a backend API.
---
# Angular Service Procedure
1. DTO interfaces mirror backend contract (spec-cited). 2. Service methods return
Observable; map errors to typed app errors. 3. HttpClientTestingModule in unit
tests; one test per method (success + error). 4. Base URL from `environment.apiUrl`.
>>>>>>> 4d034766b1b3d728e300657a1f8f3ef49e3f6ddd
