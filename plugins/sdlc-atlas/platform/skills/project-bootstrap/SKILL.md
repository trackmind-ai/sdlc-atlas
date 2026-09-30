---
name: project-bootstrap
description: >-
  Stack-agnostic procedure for scaffolding a new project. Used by
  bootstrap-agent, which pairs it with the stack-specific bootstrap skill
  (django-bootstrap, node-bootstrap) that owns the exact commands.
---
# Project Bootstrap Procedure

## Definition of done — the scaffold must:
1. Have a dependency manifest with PINNED versions (the future source of truth)
2. Follow the stack's conventional layout (from the stack bootstrap skill)
3. Contain a test harness with ONE passing smoke test
4. Contain linter + formatter config matching stack defaults
5. Contain a CI pipeline file that runs test + lint + the org's security scan
   on PR, honouring org branch rules
6. Contain .gitignore, README stub (name, run, test instructions), and an
   empty-heading knowledge.md
7. PASS ITS OWN PIPELINE locally: deps install, smoke test green, lint clean

## Order of operations
manifest → layout → test harness → lint → CI → docs stubs → verify run.
Verify is not optional: a scaffold that cannot run its own smoke test is a
liability the first feature will trip over.

## Boundaries
No features, no domain models, no endpoints — structure only. No version chosen
silently: pin what the stack skill defaults, record anything else as a
developer answer. Refuse on a repo that already has a real manifest
(that is brownfield).
