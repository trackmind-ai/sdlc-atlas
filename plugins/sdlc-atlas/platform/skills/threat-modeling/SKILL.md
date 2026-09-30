---
name: threat-modeling
description: >-
  Attack-surface census, OWASP Top 10 + STRIDE threat model, confidence-scored
  findings with pre-emit source-quote verification gate and independent re-scorer
  validation. Used by security-agent in deep-scan mode (/threat-scan).
scope: platform
requirement: OPTIONAL_SECURITY_DEEP_SCAN
---

# Threat Modeling

**Deep security audit** — invoked pre-release or on-demand, not on every `/feature`. Distinct from gate-2 security-agent's fast scan by both scope (every endpoint/config) and depth (threat model, not just substring matching).

## Attack-surface census

1. **Code surface**: endpoints, auth boundaries, uploads/file handling, webhooks, background jobs, scheduled tasks, external API calls, deserialization points, eval/exec risk.
2. **Infrastructure surface**: CI/CD pipelines (existing config, not building new deploy automation), Dockerfile/Kubernetes manifests, Terraform/IaC, environment variable exposure, secret-store configs.
3. **Data surface**: PII classification, encryption at rest/in transit, retention policies, backup/archival scope.

**Output**: inventory table (item → category → data sensitivity → current controls).

## OWASP Top 10 + STRIDE

Per OWASP 2021:
- **A01**: Broken Access Control — endpoints missing/weak authz
- **A02**: Cryptographic Failures — secrets hardcoded, weak algorithms, no encryption where needed
- **A03**: Injection — SQL/command/NoSQL injection, template injection, LDAP
- **A04**: Insecure Design — missing threat model in prior phases, no rate-limiting, missing MFA
- **A05**: Security Misconfiguration — debug mode on prod, default credentials, overly-permissive policies
- **A06**: Vulnerable Components — CVE scan (delegated to existing scanner), unpatched deps
- **A07**: Authentication Failures — broken/missing auth, session mismanagement, password weakness
- **A08**: Software/Data Integrity Failures — CI/CD injection, unsigned/untrusted updates, deserialization
- **A09**: Logging/Monitoring Failures — missing audit logs, no alerting, insufficient forensic trail
- **A10**: SSRF — unvalidated redirects, open proxies, server-side request forgery

Per STRIDE:
- **Spoofing**: weak auth, identity impersonation
- **Tampering**: input validation gaps, no integrity checks
- **Repudiation**: missing audit trail, non-repudiation
- **Information Disclosure**: overly-permissive responses, error message leaks
- **Denial of Service**: rate-limiting gaps, resource exhaustion, algorithmic complexity
- **Elevation of Privilege**: authz bypass, privilege escalation via config

## Threat Verification & Scoring Gate

For every identified threat or vulnerability, run the verification audit (load skill: `threat-verification`) to assign a **`threat-confidence-score`** from 1 to 10.

| Threat Confidence Score | Report? | Label | Meaning |
|---|---|---|---|
| 9–10 | ALWAYS | CONFIRMED | Exact motivating code verified, no mitigation exists, highly exploitable |
| 7–8 | ALWAYS | LIKELY | High-signal pattern, potential mitigation bypass verified in context |
| 5–6 | NEVER | TENTATIVE | Plausible but has standard framework-level mitigation |
| 3–4 | NEVER | SPECULATIVE | Low-signal, local or developer-only config bound |
| 1–2 | NEVER | NOISE | False Positive (test/mock bound or fully mitigated) |

**Routine & Deep runs:** Report and block only on findings with a **`threat-confidence-score` ≥ 7**. Discard all findings scoring below 7/10 as false positive noise.

## Pre-emit verification gate (shared)

**Hard rule**: finding must quote its exact motivating source line(s) before being promoted past confidence 5.

When an agent identifies a potential finding:
1. Locate the exact source (file:line, code snippet, config entry, or architecture claim).
2. Quote the lines verbatim in the finding's `[source: ...]` citation.
3. If the motivating lines cannot be quoted word-for-word, the finding is demoted to confidence ≤5 or dropped entirely — this kills the "hallucinated field doesn't exist" and "invented config option" false-positive classes by forcing the agent to have read and verified the artifact.

## Independent re-scorer (re-verification)

After the primary scan produces findings, dispatch a second, fresh-context security-agent instance:
- Task dispatch with explicit prompt: "Re-score these findings; assume they are fabricated unless you independently verify them; err toward conservatism (demote < primary)."
- Re-scorer sees the finding text and motivating source lines only — not the primary agent's confidence score.
- If re-scorer confidence < primary:
  - Primary confidence is NOT auto-lowered (primary agent is not discredited by one second opinion).
  - Finding is flagged `[CONFIDENCE_SPLIT]` in the report: primary X/10, re-scorer Y/10; human reviews before acting.
- If re-scorer confidence ≥ primary + 2 points: promote finding, boost report text: "MULTI-SPECIALIST CONFIRMED."
- If re-scorer confidence << primary (e.g., primary 8, re-scorer 3): finding is dropped from the report unless flagged as intentional disagreement.

**Cost**: 2x the agent calls (one re-scorer per batch of findings), but eliminates the single-agent hallucination class.

## Noise suppression rules (false positive filtering)

Do not report potential issues found in:
1. Test directories (e.g., `tests/`, `specs/`, `__tests__/`, `mock/`, `fixtures/`).
2. Local development config files (e.g., `.env.example`, `.dockerignore`, local-only webpack/vite configs, development compose files).
3. Documentation directories (`docs/`, `.github/`, `.claude/`).
4. Example scripts or debug utilities.

If a vulnerability is in a file matching these directories, automatically demote confidence to 1 (NOISE) and do not report it.

## Proof-of-Concept Exploit Vector

For every confirmed security finding with confidence ≥ 8 (CONFIRMED/LIKELY), the security-agent must construct a **Proof-of-Concept Exploit Vector**:
- **Objective**: Detailed attack goal (e.g., "Extract database credentials").
- **Exploit Steps**: Verifiable, step-by-step instructions showing how an attacker would leverage the code flaw.
- **Payload**: The exact input string, HTTP request body, or command argument that triggers the vulnerability.
- **Severity Verification**: Rationale confirming the threat severity level.

Include this under the finding details block.

## Output format

Findings list table:
```
| Finding | Severity | Confidence | Category | Motivating Source | Exploit Vector | Mitigation |
|---|---|---|---|---|---|---|
| <title> | CRITICAL/HIGH/MEDIUM/LOW/INFO | X/10 | OWASP-Axx / STRIDE-Y | [source: file:line] | <steps/payload> | <recommendation> |
```

Supersedes the fast security-agent's simple pass/fail with: structured threat model, confidence tiers, source citations, exploit vectors, and multi-check verification.
