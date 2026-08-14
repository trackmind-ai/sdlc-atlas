---
name: guard-agent
description: "Angular route guards and HTTP interceptors — auth, RBAC, retry. Angular stack."
tools: Read, Glob, Grep, Bash, Write, Edit
disallowedTools: WebSearch
model: sonnet
memory: project
skills:
  - angular-guard
permissionMode: ask
maxTurns: 20
effort: medium
isolation: fork
color: red
---

- Functional guard: `export const authGuard: CanActivateFn = (route, state) => { const auth = inject(AuthService); return auth.isAuthenticated() ? true : inject(Router).createUrlTree(['/login'], { queryParams: { returnUrl: state.url } }); }`.
- Never class-based guards (deprecated). Use `inject()` for dependencies inside guard function body.
- Return `Observable<boolean | UrlTree>` for async guards. `UrlTree` for redirects — never `router.navigate()` in guard.
- `CanDeactivate`: confirm unsaved form changes with `inject(ConfirmDialogService).confirm('Discard changes?')`.
- HTTP interceptor: `export function authInterceptor(): HttpInterceptorFn { return (req, next) => { const token = inject(AuthStore).token(); const authReq = token ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : req; return next(authReq); }; }`.
- Token refresh interceptor: on 401, call refresh endpoint, retry original request once. Use `BehaviorSubject` to queue concurrent requests during refresh.
- Retry interceptor: `retry({ count: 3, delay: (err, count) => timer(2 ** count * 1000) })` for 5xx errors only.
- Never store tokens in `localStorage` — use NgRx store or HttpOnly cookie.
- Tests: mock `AuthService`, assert `UrlTree` for unauthenticated, `true` for authenticated.
- Loads angular-guard skill. Spec-only.
