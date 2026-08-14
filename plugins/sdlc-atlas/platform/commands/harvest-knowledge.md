---
name: harvest-knowledge
description: >-
  Consolidates recent debugging mistakes and coding conventions into knowledge.md.
---

# /harvest-knowledge

**Triggers post-task or weekly learning consolidation to persist codebase rules, patterns, and decisions.**

## Invocation

```bash
/harvest-knowledge [--force]
```

## Process

1. Scan recent session logs, git commit history, and command outputs since the last run.
2. Identify:
   - Repeated debugging errors or failed repair attempts (lessons learned).
   - Code conventions or folder structures that were frequently used or queried.
   - Core technical decisions (e.g. choice of libraries, routing patterns).
3. Draft proposed additions to `PROJECT_ROOT/.claude/knowledge.md` under `## Uninferable facts` or `## Codebase conventions`.
4. Run a verification check to ensure proposed facts are true of the current codebase.
5. Append new rules/facts to the project's `knowledge.md` file, avoiding duplicates.

## Output

```
✔ Knowledge harvesting complete
2 new conventions appended to .claude/knowledge.md
```
