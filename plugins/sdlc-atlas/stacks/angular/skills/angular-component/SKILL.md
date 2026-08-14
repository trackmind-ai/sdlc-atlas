---
name: angular-component
description: Angular standalone component implementation checklist.
when_to_use: Activate whenever building or reviewing an Angular component, page, or lazy route on the Angular stack.
disable-model-invocation: false
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
effort: medium
context: fork
---

1. `@Component({ standalone: true, imports: [...], changeDetection: ChangeDetectionStrategy.OnPush })`.
2. Inputs: `name = input<string>()` (signal) or `@Input({ required: true }) name!: string`. Never untyped.
3. Outputs: `clicked = output<ClickEvent>()` or `@Output() clicked = new EventEmitter<ClickEvent>()`.
4. Local state: `count = signal(0)`. Derived: `doubled = computed(() => this.count() * 2)`. Never mutable class properties for reactive state.
5. Template: `@if`, `@for`, `@switch` (Angular 17+ control flow). No `*ngIf` / `*ngFor` unless legacy project.
6. `@for (item of items(); track item.id)` — always `track` by unique ID, never by index for mutable lists.
7. No method calls in template binding that recompute per cycle — use `computed()` or `@let` instead.
8. Lazy route: `{ path: 'feature', loadComponent: () => import('./feature.component').then(m => m.FeatureComponent) }`.
9. Loading state: `@if (loading()) { <app-spinner/> } @else if (error()) { <app-error [message]="error()"/> } @else { ... }`.
10. Styling: Tailwind classes or Angular Material components. No `[style.color]="..."` inline bindings.
11. Accessibility: `role`, `aria-label`, `aria-describedby` on interactive elements. Keyboard-navigable.
12. Images: `NgOptimizedImage` (`ngSrc`) — never `<img src>` for app images.
13. Tests: `TestBed.configureTestingModule({ imports: [ComponentUnderTest, ...deps] })`. Test: renders correctly, responds to input changes, emits output on interaction.
14. `inject()` for dependencies in constructor or field initialiser — no constructor parameter injection in standalone.
15. Defer non-critical content: `@defer (on viewport) { <heavy-component/> } @placeholder { <skeleton/> }`.
