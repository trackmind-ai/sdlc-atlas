---
name: onboarding-audit
description: >-
  Runs a 1-turn static audit of the workspace to check onboarding and setup friction.
---

# /onboarding-audit

**Runs a fast, 1-turn static audit of the workspace to check onboarding and setup friction.**

## Invocation

```bash
/onboarding-audit
```

## Process

1. **Check Documentation Files (Static Check):**
   - Check if `README.md` exists in the repository root.
   - Verify that `README.md` contains basic setup instructions (e.g. "Install", "Run", or "Setup").
2. **Check Environment Setup Files (Static Check):**
   - Check if an environment file template (e.g. `.env.example`, `config.example`, `settings.template.json`) exists in the workspace.
3. **Verify Dependencies Declarations:**
   - Scan for dependency definition files (e.g. `package.json`, `requirements.txt`, `Pipfile`, `pyproject.toml`, `gemfile`, `go.mod`).
   - If present, check if setup commands (like `npm install` or `pip install`) are referenced in setup instructions.
4. **LLM Execution Rule (Zero Overhead):**
   - Perform all checks using fast, local file checks (glob/grep). Do **NOT** invoke LLM reasoning or prompt loops.
   - If any file is missing or lacks basic setup commands, print a clear error description and warn.

## Output

```
✔ Onboarding audit complete:
  - README.md exists and contains installation guides.
  - .env.example template file is present.
  - package.json configuration file is present.
  - Setup friction score: 0 (No issues found)
```
