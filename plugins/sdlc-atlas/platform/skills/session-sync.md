---
name: session-sync
description: >-
  Synchronizes active browser cookies from the developer profile to the headless QA session
  to bypass SSO, MFA, or auth gates during QA runs.
scope: platform
requirement: QA_SESSION_SYNC
---

# Browser Session Synchronization

**Automates cookie injection into headless Chrome QA runs.**

## 1. Importing session cookies

When the `/session-sync` command is invoked, the orchestrator/agent executes:

1. **Ask User:** Prompt the user to paste cookies exported from their active browser session.
2. **Accept Formats:** Support JSON arrays (standard export format from browser extensions like EditThisCookie).
3. **Parse and Validate:** Parse the input into a standard list of cookie objects. Ensure each object has `name`, `value`, `domain`, and `path`.
4. **Write to Disk:** Save the cookies array to `PROJECT_ROOT/.claude/memory/browser_cookies.json`.

## 2. Browser injection (CDP protocol)

During Phase 5a (Live QA), the `qa-agent` must inject these cookies before navigating to target URLs:

1. **Read file:** Read `PROJECT_ROOT/.claude/memory/browser_cookies.json` if it exists.
2. **Inject via CDP:** Send the `Network.setCookies` command over the WebSocket debugger connection.

### CDP Command Structure

```json
{
  "id": 1,
  "method": "Network.setCookies",
  "params": {
    "cookies": [
      {
        "name": "session_id",
        "value": "xyz123",
        "domain": ".example.com",
        "path": "/"
      }
    ]
  }
}
```

Verify that Chrome logs `{"id":1,"result":{}}` or equivalent confirmation.

## 3. Fallback

If no cookie file exists, proceed with the QA run unauthenticated, or warn once if the spec mentions authenticated routes.
