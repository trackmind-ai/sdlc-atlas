---
name: interaction-budget
description: >-
  Sets the questioning sensitivity and turn budget for interactive requirements and specification stages.
---

# /interaction-budget

**Sets the questioning sensitivity and turn budget for interactive requirements and specification stages.**

## Invocation

```bash
/interaction-budget [high|medium|low]
```

## Process

1. If no budget level is provided, read the current setting from `.claude/memory/interaction_budget.json`. If that file does not exist, default to `high`.
2. Save the chosen budget setting to `.claude/memory/interaction_budget.json`:
   - `high`: Deep interactive mode (agent prompts for clarifications for any minor ambiguity; max 5 questions).
   - `medium`: Balanced mode (agent prompts only for critical gaps; max 2 questions).
   - `low`: Autonomous mode (agent makes logical, documented assumptions instead of stopping to ask; max 0 questions).
3. Update the memory reference so all downstream agents fetch and respect this setting.

## Output

```
✔ Interactive question budget set to: <high|medium|low>
```
