---
name: threat-scan
description: >-
  Deep threat-model security scan. OWASP Top 10 + STRIDE, confidence-scored findings,
  pre-emit verification gate, independent re-scorer. Pre-release cadence, pre-release
  mandatory for enterprise profiles. Manual invocation.
---

# /threat-scan

**Deep threat-model security audit** — pre-release or on-demand, not run on every `/feature` (distinct from the fast gate-2 `security-agent` scan).

## Invocation

```
/threat-scan [--fast|--comprehensive]
```

- `--fast` (default): report findings ≥8/10 confidence
- `--comprehensive`: report findings ≥2/10 confidence, labeled TENTATIVE

Requires standard or enterprise profile; skipped for small profiles (use config flag in CLAUDE.md §8).

## Process

Dispatch `security-agent` in deep mode. Agent loads skills: `threat-modeling`, `finding-verification-gate`. Runs full attack-surface census (code surface, infrastructure surface, data surface), OWASP Top 10 + STRIDE threat checklist, confidence-scored findings with pre-emit verification gate (finding must quote its exact source line before being promoted), independent re-scorer pattern (second security-agent instance blind-verifies findings).

## Output

Threat-model report: structured findings table (finding / severity / confidence / category / source / mitigation), trend tracking vs. prior reports, incident-response playbook template for leaked secrets.

## Examples

```bash
# Pre-release deep scan (comprehensive mode)
/threat-scan --comprehensive

# Quick threat check before demo
/threat-scan --fast
```

## Configuration

`CLAUDE.md` §8 — `threat_scan: on-release|off` (default `off` for small, `on-release` for standard/enterprise).
