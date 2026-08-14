---
name: security-scans
description: >-
  Catalogue of security scan types offered at setup and how each maps to a gate
  command per stack. Lets a project pick multiple scans instead of one. Loaded by
  setup-agent and security-agent.
---
# Security scans (multi-select)

A project may enable several scan types. The combined `security:` gate runs each
enabled scan in order; first failure stops (per gate-runner rules).

## Scan types and commands

| Type | What it finds | Python (django/fastapi) | Node/Angular/Next |
|---|---|---|---|
| Dependency / SCA | Known CVEs in deps | `pip-audit --exit-code 1` | `npm audit --audit-level=high` |
| Secret scan | Committed secrets/keys | `detect-secrets scan` or `gitleaks detect` | `gitleaks detect` |
| SAST | Code-level vulns | `bandit -r . -ll` | `npx eslint . --plugin security` / `semgrep --error` |
| Container scan | Image CVEs (if Docker) | `trivy image <img>` | `trivy image <img>` |
| License scan | Disallowed licenses | `pip-licenses --fail-on=GPL` | `npx license-checker --failOn GPL` |

## Composing the gate command

Join enabled scans with `&&` so any failure stops the gate:

```
security: pip-audit --exit-code 1 && bandit -r . -ll
```

Write the composed command to CLAUDE.md `security:`. Record the chosen scan list in
knowledge.md (`security_scans:`) and the context bundle.

## Defaults

If the developer picks **Decide Later**, enable **Dependency + SAST** for the stack
(the two highest-value, lowest-friction scans) and mark the rest `deferred`.

## Profile interaction

- small: security gate is warn-only — scans run but do not block.
- standard / enterprise: scans block on HIGH/CRITICAL (enterprise may tighten to MEDIUM).
