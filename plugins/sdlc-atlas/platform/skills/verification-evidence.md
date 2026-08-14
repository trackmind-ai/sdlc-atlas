---
name: verification-evidence
description: >-
  The IRON LAW from gstack: no PASS verdict stands on stale evidence. If code changed
  after tests ran, re-run before reporting. Also adds diff-coverage audit: confirm
  every changed file is tested. Used by test-agent.
scope: platform
requirement: TEST_FRESHNESS
---

# Verification Evidence

**IRON LAW**: `No completion claims without fresh verification evidence.`

## Rule 1: Test freshness

When test-agent reports PASS, the verdict is valid **only if all tests ran after the most recent code change**.

### Detection

Before running tests:
1. Check when tests last ran: read timestamp from `.claude/memory/gate_results.md` (field: `tests_last_run_at` or similar).
2. Check when code last changed:
   ```bash
   git log -1 --format=%aI -- ':(exclude).claude/'  # exclude .claude/ folder
   ```
   This gives the timestamp of the most recent code change (excluding spec/pipeline artifacts).

3. **If `code_last_changed_at` > `tests_last_run_at`**:
   - Code has changed since tests last ran.
   - **HALT — do not report PASS on stale evidence.**
   - **RE-RUN the full test suite NOW.**
   - Record new `tests_last_run_at` timestamp.
   - Report PASS only after this fresh run.

4. **If `code_last_changed_at` ≤ `tests_last_run_at`**:
   - Tests are fresh.
   - Proceed to report verdict.

### Example

```
Code last changed: 2026-01-15T10:30:00Z (app/api.py modified)
Tests last run:    2026-01-15T10:15:00Z (from prior /feature run)

Verdict: STALE. Re-run tests.
Result: tests pass after re-run at 2026-01-15T10:45:00Z
Report PASS ✓
```

## Rule 2: Diff-coverage audit

For every changed file in the diff, confirm it has **test changes**:

1. **List all changed files:**
   ```bash
   git diff main...HEAD --name-only
   ```
   Filter to source files only (exclude docs, configs, `.claude/` metadata).

2. **For each changed file**, check if any test file imports or tests it:
   ```bash
   # e.g., if app/api.py changed, look for:
   grep -r "from app.api import\|from app import api\|import app\.api" tests/
   ```

3. **Classify each changed file:**
   - ✅ **Covered**: test changes reference this file via import/test
   - ⚠️ **Indirect**: file is tested indirectly (integration test covers the flow)
   - ❌ **Uncovered**: no test references this file

4. **Report:**
   ```
   ## Diff coverage audit
   
   | File | Status | Test |
   |---|---|---|
   | app/api.py | ✅ Covered | tests/test_api.py (2 new tests) |
   | app/models.py | ❌ Uncovered | — |
   | app/utils.py | ⚠️ Indirect | tested via app/api.py integration tests |
   
   **Uncovered files**: 1 (app/models.py) — add tests before merge.
   ```

5. **Verdict impact:**
   - Uncovered new **public** functions → FAIL (must test public API)
   - Uncovered new **private/internal** functions → WARN (may be acceptable if tested indirectly)
   - Uncovered **existing** functions (prior code) → INFO (not part of this change)

## Integration with gate 1

test-agent Step 0: check staleness (re-run if needed)
test-agent Step 3a: diff-coverage audit (after tests pass)

Both checks must pass for PASS verdict. If either fails, report FAIL with remediation (re-run / add tests).

## Why this matters

- **Staleness rule** prevents "tests passed, but only on yesterday's code" false confidence.
- **Diff-coverage rule** prevents "the suite passes, but the new code isn't tested" hidden failures.

Together they enforce: tests are both fresh and complete.
