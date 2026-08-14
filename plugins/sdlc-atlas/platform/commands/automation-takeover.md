---
name: automation-takeover
description: >-
  Pauses the automated QA agent and yields browser control to the developer.
---

# /automation-takeover

**Suspends QA automation to allow manual developer interaction (takeover mode).**

## Invocation

```bash
/automation-takeover [reason]
```

## Process

0. **Verify there is an active session to take over** (this command is meant to interrupt
   a running `/qa`, not stand alone):

   ```bash
   curl -s --max-time 3 http://localhost:9222/json > /dev/null 2>&1
   ```

   Not reachable → there is no Chrome session for this command to attach to. Print:

   ```text
   ⚠ No active QA session found (nothing listening on port 9222).
   /automation-takeover only interrupts a QA run already in progress.
   Run /qa first, then use /automation-takeover if it hits a blocker mid-run.
   ```

   and stop — do not write `qa_state.json` or claim control of a browser that doesn't exist.

1. Set the QA state in `.claude/memory/qa_state.json` to `{ "suspended": true, "reason": "<reason>" }`.
2. The existing Chrome session (already running on port 9222 from the active `/qa` run) stays alive — this command does not launch a new one, it only pauses the agent driving it.
3. Print instructions telling the developer how to connect to the Chrome DevTools interface locally (e.g. `http://127.0.0.1:9222`) or perform manual overrides in the browser.

## Output

```
⚠ QA AUTOMATION SUSPENDED (Takeover Active)
Reason: <reason>
Please perform the manual action or solve the challenge in the browser.
Run /automation-resume once finished to hand control back to the agent.
```
