---
name: agent-handoff
description: >-
  Seamless handoff protocol between agents. Defines the Context Bundle that is
  passed forward so the developer never re-enters information, and the single
  handoff banner shown at each transition. Loaded by orchestrator and every
  phase agent.
---

# Agent handoff (shared)

Goal: a transition like orchestrator → architecture-agent → bootstrap-agent →
spec-agent feels like one continuous conversation. The developer never repeats
anything they already said.

## Context Bundle (carry forward, never re-ask)

Maintain a running bundle in
`PROJECT_ROOT/.claude/memory/context_bundle.md`. Every agent **reads it first**
and **appends** what it learned before handing off. Never ask for a field that is
already present in the bundle — read it instead.

Fields (always present):

```
project_name:
description:
stacks:
profile:
permissions_profile:      # from setup (see project-permissions skill)
security_scans:           # selected scan types
test_cmd: / security_cmd: / lint_cmd:
architecture_decisions:   # key choices + rejected alternatives (from architecture-agent)
deferred_decisions:       # items the developer chose Decide Later
open_questions:           # anything still unanswered
last_agent: / next_agent:
feature_in_progress:      # feature/change slug if any
```

Fields (added at orchestrator Step 3 — cached CLAUDE.md/knowledge.md summary):

```
gate_commands:            # { test, security, lint } commands from CLAUDE.md §8
routing_table:            # condensed routing: agent name → one-liner role
built_features:           # { slug, one-liner } — NOT full detail, just inventory
project_skills_registry:  # { skill name → scope } from CLAUDE.md §6 + knowledge.md (for gap-analysis)
uninferable_facts_digest: # short bullet list from knowledge.md
tech_leads:               # { name, role } from knowledge.md (if present)
config_summary_timestamp: # ISO timestamp — bundle was generated at this time
config_summary_hash:      # hash of CLAUDE.md+knowledge.md content — invalidate bundle if files changed
```

**Cache invalidation:** Downstream agents read the bundle first. If `config_summary_hash` doesn't match the current file hash (or the bundle is missing), agents fall back to reading CLAUDE.md/knowledge.md directly.

## Handoff

Print exactly one line:

```
→ <next-agent-name>
```

Nothing else. No From/To/Doing/You block.

## Rules

1. **Read `context_bundle.md` BEFORE composing any question batch.** Remove questions
   already answered from the batch. If everything is answered, skip the batch entirely.
2. If a needed fact is in the bundle, use it silently; do not re-confirm unless it
   conflicts with new input.
3. Append new facts to the bundle immediately after receiving a batch reply — before
   doing any writes or handoffs.
4. The receiving agent opens by acknowledging carried context
   (e.g. "Continuing with the Django+Angular monorepo you set up…"), not from zero.
5. The bundle is session state — it lives in `memory/` and is git-ignored.
6. **Parallel writes after each batch** — after appending to the bundle, fire all file
   writes simultaneously. Never write CLAUDE.md, then knowledge.md, then state sequentially.
