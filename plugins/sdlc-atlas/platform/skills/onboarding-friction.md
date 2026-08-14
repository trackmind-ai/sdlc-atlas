---
name: onboarding-friction
description: >-
  Audits workspace onboarding files, setup guides, and dependency configurations
  to measure setup friction and Time-To-Hello-World (TTHW) factors.
scope: platform
requirement: ONBOARDING_FRICTION_AUDIT
---

# Onboarding Friction Audit Guidelines

**Reducing onboarding friction and verifying setup completeness.**

## 1. Setup Auditing Steps
During a Quality Gate check or when `/onboarding-audit` is run:

1. **Verify README structure**:
   Ensure `README.md` includes sections detailing:
   - System Prerequisites (e.g. Node version, Python version, DB requirements).
   - Basic Installation steps (e.g. `npm install`, `pip install -r requirements.txt`).
   - Development Run commands (e.g. `npm run dev`, `python manage.py runserver`).
   - Environment configurations.

2. **Verify Configuration Templates**:
   - Verify that configuration templates contain placeholders (`YOUR_API_KEY`, `CHANGEME`, etc.) for every environment key required in the codebase.
   - Flag any missing config variable template placeholders.

3. **Measure Friction Score**:
   Assign points for friction issues:
   - Missing README: +5 points
   - Missing setup instructions: +3 points
   - Missing environment configuration template: +3 points
   - Stale commands (e.g. references `npm install` but project uses `pnpm`): +2 points
   - Score $\le 2$: **PASS** (Low Friction)
   - Score $> 2$: **WARNING** (Friction detected - needs remediation)

## 2. Token-Saving Implementation
- Perform checks sequentially using local file reads.
- Do not request LLM assistance during evaluation unless the score exceeds 5 (High Friction), in which case write a brief summary report listing the missing components.
