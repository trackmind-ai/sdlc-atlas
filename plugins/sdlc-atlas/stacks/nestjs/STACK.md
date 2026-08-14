# Stack: NestJS (L1)
NestJS + TypeScript + TypeORM/Prisma + class-validator. Installs into a project's `.claude/` via `install.sh --stack nestjs --project <path>`.
Project files win any filename collision. Declare `stack: nestjs` in project CLAUDE.md.
Provides: module-agent, controller-agent, provider-service-agent, orm-migration-agent, guard-interceptor-agent + skills.
Defaults (project may override): test `jest --coverage`, security `npm audit`, lint `eslint . && prettier --check .`.
