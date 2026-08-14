---
name: compile-ui-test
description: >-
  Serializes successful CDP browser journeys into a local JSON test cache.
---

# /compile-ui-test

**Compiles and caches successful QA automation actions to run fast subsequent tests.**

## Invocation

```bash
/compile-ui-test <test_name_slug>
```

## Process

0. **Verify there is an action trace to compile.** This command serializes the trace from
   a QA run that already happened — it does not run one itself. If no `/qa` run occurred
   this session (no in-memory action history, and no partial trace on disk), print:

   ```text
   ⚠ No QA action trace found to compile.
   /compile-ui-test serializes the browser actions from a run that already completed.
   Run /qa first, then /compile-ui-test <slug> to cache that journey.
   ```

   and stop — do not write an empty or placeholder JSON file.

1. Read the raw history of browser clicks, navigations, and text entries executed during the current active QA run.
2. Serialize these steps into a structured JSON array format.
3. Save the serialized steps to `PROJECT_ROOT/.claude/memory/ui_test_cache/<test_name_slug>.json`.
4. If the same scenario is run again, the QA agent can read this file and fast-replay it.

## Output

```
✔ QA journey compiled successfully!
Saved cached test script to: .claude/memory/ui_test_cache/<test_name_slug>.json
```
