---
name: brownfield-reading
description: >-
  Anti-speculative reading discipline for existing codebases. MANDATORY for
  spec-agent brownfield mode and recommended for any agent inspecting code it
  did not write.
---
# Brownfield Reading
1. **Declare scope before any file access.** Primary scope(s): smallest unit
   expected to contain the change, with a one-sentence justification mapping work
   item language to that scope. Allowed secondary scopes: contracts/schemas you may
   READ but not change, each with a reason. No inferable scope → that is an open
   question, not a licence to browse.
2. **Search before reading.** Locate the exact symbol via grep/glob first.
3. **Read by range.** Only the lines around the located symbol; whole file only if <80 lines.
4. **Listings are not reading queues.** A filename appearing in a listing is not a
   reason to open it. Don't list directories outside declared scopes.
5. **Stop at one confirmed pattern.** Seen how a field is added once? Don't read
   three more examples of the same thing.
6. **Defer tests** until the production code is understood; read only the most
   relevant test class.
**Gate sentence** — before every read: "I am reading <file> because I need
<specific symbol/behaviour> which I confirmed lives here via <search>." Can't
complete it → don't open the file. Never propose changes to uninspected files.
