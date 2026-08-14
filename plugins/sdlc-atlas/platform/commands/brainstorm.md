---
name: brainstorm
description: >-
  Starts a token-optimized conceptual brainstorming and ideation session with the developer.
---

# /brainstorm

**Starts a token-optimized conceptual brainstorming and ideation session with the developer.**

## Invocation

```bash
/brainstorm
```

## Process

1. **Ask User (Max 2 turns - MANDATORY):**
   - **Question 1:** Ask the developer to summarize the core feature idea, the business goal, and any immediate ideas they have on user interaction.
   - **Question 2:** Ask for key non-functional constraints (e.g. performance boundaries, database requirements, or dependency integrations).
2. **Halt & Document:**
   - After the second response, do **NOT** ask any more questions.
   - Compile all conceptual details, alternative approaches, and user decisions.
   - Save the notes in a token-efficient bulleted format to `PROJECT_ROOT/.claude/memory/brainstorm_notes.md`.

## Output File Format

```markdown
# Brainstorming Notes — <date>

## Core Goal
- <Business purpose and user flow>

## Constraints
- <Integrations/performance/DB decisions>

## Alternative Approaches
- <Alternative X (chosen/rejected with reason)>
```

## Output

```
✔ Brainstorming session complete (saved to .claude/memory/brainstorm_notes.md)
```
