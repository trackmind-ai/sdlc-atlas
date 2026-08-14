# The Capability Matrix — what each of the 6 types does at each of the 4 layers

| Capability | L0 Platform (process) | L1 Stack (technology) | L2 Org (policy) | L3 Project (codebase) |
|---|---|---|---|---|
| **Agents** (who works) | Process roles: orchestrator, spec-agent, gate agents (test/security/sonar/review/acceptance), requirements, architecture, bootstrap, docs, adr, release, incident, retro | Technology roles: api-agent, migration-agent, celery-agent, orm-agent — know the framework, not the company | Rarely any — but may override a gate org-wide (e.g. SOC2 security-agent for all projects) | Domain roles: ai-services-agent, integration-agent, report-agent — plus overrides (e.g. a HIPAA-specific security-agent) |
| **Skills** (how work is done) | Process procedures: citation-discipline, brownfield-reading, greenfield-grounding, project-bootstrap, knowledge-md, proposal-evaluation, spec-writing | Technology procedures: drf-endpoint, safe-migration, fastapi-bootstrap, express-endpoint, node-bootstrap | Compliance procedures shared by all projects | Domain procedures: hipaa-phi, webhook-verification |
| **Commands** (entry points) | The lifecycle: /feature /approve-spec /change-feature /quality-check /raise-pr /propose /approve-proposal /release /retro /architecture /bootstrap /gen-docs /new-adr | Stack shortcuts: /new-endpoint /migrate | Rare; maybe /compliance-report | Project shortcuts: /new-integration |
| **Knowledge** (what is true) | The constitution — universal process truths | STACK.md — framework defaults (test/lint/security commands) | ORG.md + policies — tracker, thresholds, authority, branch rules | Project CLAUDE.md (routing, conventions) + knowledge.md (uninferable facts) |
| **Policy** (what is allowed) | Universal denies: force-push, capability-file edits (hook), secrets | Tool permissions: pytest/manage.py allowed; flush / migrate --fake denied | The teeth: protected branches, credentials, coverage_min, security_fail_on | Local sharpening: e.g. function_executor.py deny |
| **State** (what happened) | Defines FORMATS only: state template, proposal lifecycle stages | None — stacks are stateless | Aggregates: promotion-harvest records, evidence retention | Where state LIVES: orchestrator_state.md, specs/, proposals/, evidence/ |

## The gaps are the insight
- Agents/Skills are rich at L0/L1/L3 and deliberately thin at L2 — the org layer
  constrains work, it rarely does work. When it ships an agent it is almost always
  a gate override tightening something for every project at once.
- Policy's centre of gravity is L2, and each layer may only TIGHTEN what came
  above (platform: never force-push → org: never touch main → project: never
  touch function_executor.py). Loosening downward is forbidden by the constitution.
- State lives at L3 but its SHAPE is defined at L0 — that separation is why the
  orchestrator can resume any project's pipeline.
- Knowledge is the only type present at all four layers; the orchestrator's
  startup ritual reads it top-down, universal → specific.

## One-line mnemonic
**L0 owns the verbs of process, L1 the verbs of technology, L2 the constraints,
L3 the facts and the state.** Unsure where a new capability belongs? Ask which of
those four it is.
