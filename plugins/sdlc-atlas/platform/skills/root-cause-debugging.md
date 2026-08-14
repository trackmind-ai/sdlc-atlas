---
name: root-cause-debugging
description: >-
  Root-cause debugging discipline: Iron Law "no fix without investigation first",
  pattern-match table (race/nil/corruption/integration/config/cache), 3-strike
  hypothesis rule, mandatory regression test. Used by debug-agent via /investigate.
scope: platform
requirement: DEBUG_FIRST_FIX_LATER
---

# Root-Cause Debugging

**Structured bug investigation before any fix** — invoked via `/investigate <bug description>`, parallel lane to `/fix`.

## The Iron Law

**NO FIX WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

A superficial patch (e.g., "add a try-catch around the error") masks the true problem and guarantees the bug resurfaces later or mutates into a harder-to-diagnose form. Debugging discipline forces investigation → diagnosis → targeted fix, even if it takes longer upfront.

## Phase 1: Reproduce & symptom collect

1. **Reproduce the bug** — follow the exact steps provided:
   ```bash
   # Example from user: "clicking button sometimes freezes the form"
   # Agent reproduces: click button 5x rapidly, observe freeze on 2nd/3rd click
   ```

2. **Collect observable symptoms**:
   - Exact user action that triggers it
   - Output/behavior observed
   - Consistency (always? sometimes? specific conditions?)
   - Error messages, stack traces, console logs
   - Timing/lag/hang duration if applicable

3. **Check prior investigations**:
   - Grep codebase for TODOs/FIXMEs/BUGs related to this symptom
   - Check git log for any prior fixes to nearby code (hint at recurring issue)
   - Search issue tracker / knowledge.md for patterns

## Phase 2: Scope lock & hypotheses

**Scope Lock**: based on symptoms, identify the narrowest containing directory/subsystem where the bug must live. Write this to a scope-lock file (used by the `/freeze` skill to restrict edits to only this scope during investigation — prevents accidental scope creep).

Example: "Button freeze → likely React state issue OR race condition in event handler → scope: `app/ui/hooks/useForm.ts`"

**Hypothesis table** (3 strike rule — max 3 hypotheses before asking for help):

| # | Hypothesis | Evidence to test | Prediction |
|---|---|---|---|
| 1 | Race condition: form submit called twice | Add logging on submit start/end | Log shows `submitStart submitStart submitEnd submitEnd` (concurrent) |
| 2 | State update during unmount (memory leak) | Check if component unmounts during async call | Form never unmounts; hypothesis rejected |
| 3 | Event handler not debounced | Check handler signature in diff | Handler not debounced; but this is not the root cause, form works fine on first click |

## Phase 3: Pattern matching

Match observed behavior against known bug patterns:

| Pattern | Symptom | Common causes | Fix approach |
|---|---|---|---|
| **Race condition** | Intermittent, depends on timing, "sometimes" behavior | Concurrent async operations, missing locks/mutexes, event listener registered twice | Add debounce/throttle, serialize async operations, cleanup listeners on unmount |
| **Nil propagation** | `Cannot read property 'x' of undefined`, crash after optional operation | Missing null checks, unsafe chaining, response shape changed | Add defensive checks, validate API responses, use optional chaining consistently |
| **State corruption** | Wrong data displayed, ghost state persists | Stale closures, missing dependency arrays (React), shared mutable state | Fix closure scope, add deps, use immutable state updates |
| **Integration failure** | Works locally, fails in staging/prod | Environment differences, config mismatches, service dependency down | Check logs from real environment, validate service health, compare configs |
| **Config drift** | Behavior changes unexpectedly, "used to work" | Stale environment variables, schema migration incomplete, feature flag state | Verify current config matches expected, check migration status |
| **Stale cache** | New code deployed but old behavior persists | Browser cache, Redis cache, CDN cache not invalidated | Clear caches, restart services, verify deployment succeeded |

Once a pattern is identified, the fix path is often obvious.

## Phase 4: Hypothesis testing & verification

For each hypothesis:
1. **Design a test** to confirm/reject it
2. **Run the test** — add logging, breakpoints, reproduce with the suspected cause isolated
3. **Record result** — hypothesis CONFIRMED or REJECTED
4. **Next hypothesis** if rejected (up to 3 total)

After 3 rejections without confirmation, STOP and ask the user to provide more context or logs.

## Phase 5: Implementation

Once root cause is confirmed:

1. **Minimal fix** — change only what is necessary to address the root cause, not "while I'm here" refactors
2. **Repair Circuit Breaker** — Limit code modifications to a maximum of **3 failed repair attempts**. For each attempt:
   - Apply the fix.
   - Run the test suite.
   - If tests fail, **roll back all changes** (e.g. `git checkout -- .`) before trying a different fix approach.
   - Increment the failed repair counter.
   - If the counter reaches 3, **halt execution immediately**, revert all changes, and ask the user for guidance. Do not attempt a 4th fix.
3. **Regression test** — write a test that:
   - **Fails WITHOUT the fix** (proves the test catches the bug)
   - **Passes WITH the fix** (proves the fix solves it)
   - Directly exercises the code path that was broken

Example:
```python
def test_form_submit_no_double_click(self):
    # Reproduces: rapid click on submit button
    # Before fix: submits twice
    # After fix: submits once
    form = UserForm()
    submit_count = 0
    
    def track_submit():
        nonlocal submit_count
        submit_count += 1
    
    form.on_submit(track_submit)
    form.click_submit()
    form.click_submit()  # rapid double-click
    
    assert submit_count == 1, f"Expected 1 submit, got {submit_count}"
```

## Phase 6: Verification & final report

After the fix:

1. **Re-test** the original symptom — does it still occur? RESOLVED or STILL BROKEN?
2. **Run regression test** — passes?
3. **Run full test suite** — any new failures introduced by the fix?
4. **Document findings** in a structured `DEBUG REPORT`:

```
## DEBUG REPORT

### Symptom
Form submit button freezes after 1-2 rapid clicks; form becomes unresponsive.

### Root Cause
Race condition in `app/ui/hooks/useForm.ts:28`. 
`onSubmit` handler does not debounce, so rapid clicks trigger multiple concurrent POST requests.
Server returns 200 for first, 409 Conflict for second (duplicate submission).
Second response triggers error state, but error handler doesn't re-enable the button.

[source: app/ui/hooks/useForm.ts:28-35, commit log 3 months ago had a "remove debounce" change that introduced this]

### Fix
Add 500ms debounce to `onSubmit`:
```typescript
const debouncedSubmit = debounce(async () => { ... }, 500);
```

[commit abc123: Add debounce to prevent double-submit race condition]

### Evidence
- Regression test `test_form_submit_no_double_click` fails before fix, passes after
- Manual re-test: rapid clicks no longer freeze form ✓
- Full suite: all 42 tests pass ✓

### Status
✅ DONE — Bug is resolved and covered by regression test.
```

## Output format (for spec compliance)

Appended to a mini-spec file (`.claude/specs/<feature>/fix-<slug>.md`) so debugging work is tracked in the same spec system as features, maintaining full audit trail and spec versioning discipline.

```markdown
# Mini-Spec: Fix form double-submit race condition

## Acceptance Criteria
- [ ] AC-001: Rapid clicks on submit button do not trigger multiple submissions
- [ ] AC-002: Form re-enables submit button after error response
- [ ] AC-003: Regression test added covering double-click scenario

## Root-Cause Investigation
[DEBUG REPORT from Phase 6 above]

## Implementation
[Minimal fix code + regression test]

## Verification
[Test results + manual re-test evidence]

**Status:** DONE

[source: /investigate user report]
```
