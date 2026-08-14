---
name: retry-policy
description: >-
  Loop-breaker for agents. After two identical failed attempts at the same action,
  stop, reassess, and switch strategy or ask the developer. Prevents infinite retry
  loops. Loaded by every agent that runs commands or edits files.
---
# Retry policy (shared)

## The two-strike rule

Track attempts per distinct action (same command, same file edit, same goal).

- **Attempt 1 fails** → read the error, fix the obvious cause, retry once.
- **Attempt 2 fails** → **STOP. Do not try the same thing a third time.**

On the second failure you MUST break the loop and do ONE of:

1. **Reassess** — restate what you were trying to do, what the error actually says,
   and why the current approach is not working (3–4 lines, shown to the developer).
2. **Switch strategy** — choose a genuinely different approach (different command,
   different tool, smaller step), and say why it should work where the last did not.
3. **Escalate** — if no alternative is safe, ask the developer ONE numbered,
   attributed question (see interaction-style) with the options you see.

## What counts as "the same"

Same action = same intent even if you tweak quotes/whitespace. Re-running an
identical failing `npm install`, re-writing the same file the same way, or
re-issuing a command that errors identically all count.

## Record it

Append to `PROJECT_ROOT/.claude/memory/orchestrator_state.md`:
```
retry_break: <action> — 2 failures — switched to <new approach | asked developer>
```

## Never

- Never silently retry more than twice.
- Never escalate `effort`/spawn more agents to brute-force the same failing step.
- Never hide the failure — surface the real error text, not a paraphrase.

## Spec-agent carve-out — Write failure on spec files

When the **spec-agent** fails to write or validate a spec file, the two-strike rule applies
with the following constraint on "switch strategy":

- **Switching strategy NEVER means deleting the spec file and starting over.**
- The only valid strategy switch after a failed `Write` or failed validation is to use
  the `Edit` tool to fix specific sections of the existing file in place.
- If two `Edit` attempts on the same section also fail, escalate to the developer
  (option 3 above) and return `spec_write_success: false` to the orchestrator.
- The orchestrator must preserve the partial spec and surface options to the developer;
  it must not delete the file or re-dispatch spec-agent in full-write mode.
