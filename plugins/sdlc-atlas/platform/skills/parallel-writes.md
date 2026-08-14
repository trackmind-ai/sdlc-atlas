---
name: parallel-writes
description: >-
  Speed rule for agents that write, create, or update multiple independent
  files. Fire all Write/Edit calls in one turn instead of sequentially. Load
  in any agent whose `tools:` frontmatter includes Write or Edit.
scope: platform
---

# Parallel writing of independent files

---

## Rule

When multiple files (`N` files) are being written, created, or updated, and their contents are independent of each other (the output of one file does not change or affect the input of another), the write operations MUST be executed in parallel — fire all `Write` or `Edit` tool calls simultaneously in a single turn.

Sequential writing of independent files is a bug. Firing all writes simultaneously ensures the fastest completion time.

---

## Hard rules

- If file B's content depends on having already read/generated file A's content, that's a dependency — write sequentially, don't force parallelism where there's a genuine data dependency.
- Independent means independent: no dependency = always parallel, no exceptions for "simpler to write one at a time."
