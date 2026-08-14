---
name: angular-guard
description: "Angular guard and HTTP interceptor implementation checklist."
---
1. Functional guard: `export const authGuard: CanActivateFn = (route, state) => { ... }`. Never class-based.
2. Inject with `inject()` inside function body — not via constructor (functions have no constructor).
3. Unauthenticated redirect: `return inject(Router).createUrlTree(['/login'], { queryParams: { returnUrl: state.url } })`.
4. Role guard: `const user = inject(AuthStore).user(); return user?.roles.includes(route.data['role']) ?? false`.
5. `CanDeactivate`: `export const unsavedChangesGuard: CanDeactivateFn<HasUnsavedChanges> = (component) => component.hasUnsavedChanges() ? inject(DialogService).confirm('Leave?') : true`.
6. HTTP interceptor function: `export function tokenInterceptor(): HttpInterceptorFn { return (req, next) => { ... } }`.
7. Register interceptor: `provideHttpClient(withInterceptors([tokenInterceptor()]))` in `app.config.ts`.
8. Clone request before modifying: `req.clone({ setHeaders: { Authorization: ... } })`.
9. Token refresh: on 401 response, refresh token, then `next(req.clone(...))`. Queue concurrent requests with `BehaviorSubject<boolean>`.
10. Retry on 5xx: `return next(req).pipe(retry({ count: 2, delay: (err, count) => timer(1000 * count), resetOnSuccess: true }))`.
11. Error interceptor: catch and log errors, rethrow as typed `AppError` — never swallow.
12. Never store JWT in localStorage — read from NgRx store or inject `CookieService`.
13. Guard tests: mock `AuthService`, `Router`. Assert `UrlTree` for unauthorized, `true` for authorized.
14. Interceptor tests: `HttpClientTestingModule`, mock `AuthService.token()`, assert header added.
15. `canActivateChild` and `canMatch` for route group protection — apply at parent route level.
