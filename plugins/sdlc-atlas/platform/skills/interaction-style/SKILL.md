---
name: interaction-style
description: >-
  Shared rules for how agents talk to the developer: batch questions, progress
  bar format, parallel writes, agent attribution, and Decide Later. Loaded by
  all pipeline agents.
---
# Interaction style (shared)

Every agent that asks the developer anything follows these rules.

---

## 1. Attribute every message

Prefix every message with the agent name in brackets:

```
[setup-agent] ...
[architecture-agent] ...
[spec-agent] ...
```

When one agent relays another's: `[orchestrator → spec-agent]`.

---

## 2. Batch questions — never one at a time

- Load the relevant batch from `setup-interview-questions` skill verbatim.
- Send the ENTIRE batch in ONE message.
- Wait for ONE reply.
- Never drip-feed questions. Never ask a follow-up inside a batch.
- If a question is already answered in `context_bundle.md`, remove it from the batch.

---

## 3. Short answers only

Tell the developer at the top of every batch:
> "Short answers — pick a letter, type a word, or one sentence. Skip anything to decide later."

Never ask for essays. Never ask for explanations unless a choice is ambiguous.

---

## 4. Progress bar — show before every batch and every handoff

Format (fill in real numbers and names):

```
▸ Step N of 5 — <Stage name>
```

Full pipeline steps for reference:

| Step | Stage |
|---|---|
| 1 | Project basics |
| 2 | Stack & profile |
| 3 | Quality gates & team |
| 4 | Architecture |
| 5 | Feature spec |

Show the bar at the TOP of every batch message and every handoff banner.
Keep it on one line. Make it encouraging but not verbose.

---

## 5. Handoff — print before every agent transition

Print exactly one line:
```
→ <next-agent-name>
```

Always print this before invoking the next agent via Task. Never silently hand off.

---

## 6. Parallel writes — never write files sequentially

After receiving a batch reply, write ALL files simultaneously:
- Use multiple Write tool calls in the same response turn (not one after another).
- Do not wait for one file to finish before starting the next.
- This applies to: CLAUDE.md + knowledge.md + orchestrator_state.md + context_bundle.md + ADRs.

Agents that write sequentially make the developer wait unnecessarily. Parallel writes
are not optional — they are required.

---

## 7. Decide Later — for genuinely deferrable choices

Any choice not needed for immediate progress MUST offer "skip":
- Record skipped items as `none` in the relevant field.
- Append to `knowledge.md § Deferred decisions` with date.
- Never silently assume a default for a skipped item.
- A later phase re-asks only when it becomes blocking.

---

## 8. Context bundle — never re-ask

Before composing any question batch:
1. Read `PROJECT_ROOT/.claude/memory/context_bundle.md`.
2. Remove any questions already answered there.
3. If everything is answered, skip the batch entirely and continue.

After each batch reply, append the new answers to `context_bundle.md` immediately.

---

## 9. Interactive Question Budget (MANDATORY)

Every agent must respect the questioning sensitivity budget saved in `PROJECT_ROOT/.claude/memory/interaction_budget.json` (if absent, default to `high`):

*   **`low` (Autonomous)**: Maximum **0 interactive questions** allowed. If requirements or spec details are ambiguous, the agent must make logical, standard assumptions based on codebase conventions. Write the assumptions explicitly into the specs/notes as `[assumption: ...]`.
*   **`medium` (Balanced)**: Maximum **1 interactive question** allowed (restricted only to critical blocker gaps). Batch other minor items as assumptions.
*   **`high` (Interactive)**: Standard interactive prompts allowed (maximum 5 turns).

Always print the current budget setting at the start of any interactive sequence: `[budget: <level>]`.
