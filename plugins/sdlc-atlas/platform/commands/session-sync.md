---
name: session-sync
description: >-
  Synchronizes browser session cookies to bypass login gates during QA runs.
---

# /session-sync

**Synchronizes active browser session cookies for authenticated QA testing.**

## Invocation

```bash
/session-sync
```

## Process

1. Prompt the developer to paste cookie data in JSON format (e.g., exported via standard browser extensions).
2. Validate and format the session cookies.
3. Save the active cookies to `PROJECT_ROOT/.claude/memory/browser_cookies.json` to make them available to the QA agent.

## Output

```
✔ Session cookies imported successfully (saved to .claude/memory/browser_cookies.json)
```
