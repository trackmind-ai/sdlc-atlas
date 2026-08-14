---
name: automation-resume
description: >-
  Resumes the automated QA agent after manual takeover.
---

# /automation-resume

**Resumes QA automation after a manual takeover session.**

## Invocation

```bash
/automation-resume
```

## Process

0. **Verify there is a suspended session to resume:**

   ```bash
   [ -f .claude/memory/qa_state.json ] && grep -q '"suspended"[[:space:]]*:[[:space:]]*true' .claude/memory/qa_state.json
   ```

   Not found or not suspended → nothing to resume. Print:

   ```text
   ⚠ No suspended QA session found.
   /automation-resume only has effect after /automation-takeover paused an active /qa run.
   Run /qa to start a new session instead.
   ```

   and stop.

1. Set the QA state in `.claude/memory/qa_state.json` to `{ "suspended": false }`.
2. Signal the QA agent to reload the active page status and resume testing from the last checkpoint.

## Output

```
✔ QA AUTOMATION RESUMED
Re-establishing browser session connection on port 9222...
Continuing verification journey.
```
