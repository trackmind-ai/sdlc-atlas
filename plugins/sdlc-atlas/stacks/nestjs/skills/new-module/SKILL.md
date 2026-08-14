---
name: new-module
description: "Feature module + service scaffolding checklist for NestJS."
when_to_use: module-agent or provider-service-agent creating or extending a feature module against an approved spec
disable-model-invocation: false
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
model: sonnet
effort: medium
context: []
---

# New Module Procedure

1. One module per business domain: `<resource>.module.ts` with `@Module({ imports, controllers, providers, exports })`.
2. `exports: [<Resource>Service]` — never export the module or the repository.
3. `@Injectable()` service, constructor-injected dependencies only — never `new Service()`.
4. `@InjectRepository(<Entity>)` (TypeORM) or injected `PrismaService` — never `getRepository()`/`getConnection()` (removed APIs).
5. Async provider config (DB, cache, queue): `forRootAsync({ imports: [ConfigModule], inject: [ConfigService], useFactory: async (config) => ({...}) })`.
6. Circular dependency between two modules → `forwardRef()` on both sides, only after confirming a shared third module can't resolve it instead.
7. Register the feature module in `AppModule.imports` — never wire its controllers/providers directly into `AppModule`.
8. Typed domain events for cross-module communication (`OrderCreatedEvent` class) — never untyped `emit('x', {...})`.
9. `catch (error: unknown)`, narrow with `instanceof` — never `catch (error: any)`.
10. Verify `nest info` / `npm run build` shows no unresolved-provider or circular-dependency errors.
11. Unit test per public service method with mocked repository/dependencies.

## Hard rules

- Never export a module — export the service.
- Never field-style manual instantiation of a provider.
- Never leave a circular dependency unresolved without `forwardRef()` on both sides.
- Refuse domain/module boundaries not present in the approved spec — escalate via /change-feature instead.
