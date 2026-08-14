---
name: background-task-notify
description: >-
  Notification rule for agents that launch background processes (dev servers,
  test runners, subagent QA passes). Load in agents that start long-running or
  async work the developer needs visibility into (orchestrator, setup-agent,
  qa-agent).
scope: platform
---

# Background process notifications

---

## Rule

Whenever a command or agent is launched in the background (e.g. uvicorn, npm run dev, test runners, or subagents executing async tasks):

1. Immediately print a clear, user-facing notification indicating the background task has started, specifying task name and target — e.g. `[start] ⏳ Starting Next.js dev server in background...` or `[orchestrator] ⏳ Running Chrome DevTools MCP QA pass in background...`.
2. Keep the user updated on background-task status — e.g. print a success checkmark once the server port is reachable.

---

## Hard rules

- Never launch a background process silently — the notification is not optional.
- Report completion or failure, not just start — a background task the user never hears the outcome of is a broken handoff.
