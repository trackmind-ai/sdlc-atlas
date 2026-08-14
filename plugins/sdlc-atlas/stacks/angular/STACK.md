# Stack: Angular (L1)
Installs into a project's `.claude/` via `install.sh --stack angular --project <path>`.
Project files win any filename collision. Declare `stack: angular` in project CLAUDE.md.
Provides: component-agent, state-agent, guard-agent, service-agent, form-agent + skills.
Defaults (project may override): test `ng test --watch=false --code-coverage`, security `npm audit --audit-level=high`, lint `ng lint && npx tsc --noEmit`.
