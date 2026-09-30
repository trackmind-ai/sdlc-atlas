---
name: finding-verification-gate
description: >-
  Audits security findings to compute a threat-confidence-score and suppress false positives.
scope: platform
requirement: SECURITY_VERIFICATION
---

# Threat Verification Gate

**Audits and scores reported vulnerabilities to filter out low-confidence findings and noise.**

## Verification Process

For each reported security vulnerability or threat vector:

1. **Mitigation Check:** Search the codebase for existing safety guards:
   - Does input validation or type casting happen before value evaluation?
   - Is output escaping or templating handled by standard libraries?
   - Are API endpoints protected by authorization decorators or route middleware?
2. **Calculate Threat Confidence Score:** Rate the severity and certainty on a scale of 1 to 10:
   - **9–10 (Certain/Exploitable):** No mitigation exists, a clear exploit payload can execute, and values map to sensitive memory or DB scopes.
   - **7–8 (High risk, potential bypass):** A guard exists but might be bypassed under complex race conditions or edge cases.
   - **4–6 (Medium/Low risk):** Standard libraries prevent execution (e.g. Django templates auto-escaping), or routes are only local-developer bound.
   - **1–3 (False Positive):** Scopes are completely local, mock/test bound, or fully protected by strict type structures.

## Suppression Gate

*   Findings with a **`threat-confidence-score` < 7** are marked as **False Positives** and suppressed.
*   Only findings with a score of **7 or above** are reported to the developer and blocked on.
*   Log the verification results and scores to `.claude/memory/security_verification.json`.
