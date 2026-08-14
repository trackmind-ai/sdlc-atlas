---
name: proposal-evaluation
description: >-
  MANDATORY procedure whenever any agent detects a missing or inadequate capability
  (no agent/skill/command covers the work, or an existing one repeatedly falls
  short). Use this skill instead of ever creating capability or asking the
  developer "shall I create an agent?".
---
# Proposal Evaluation

## Step 0 — Never block, never create
Note the gap, file the proposal (below), tell the developer ONE sentence
("Filed proposal P-NNN about X — review with /proposals"), and complete the
current task manually. The pipeline does not stop for proposals.

## Step 1 — Skill-first ladder (answer in order, stop at first yes)
1. Can an EXISTING skill be updated to cover this? → propose `skill-update`.
2. Can a NEW skill attached to an existing agent cover it? → propose `skill-new`.
3. Does an existing agent's prompt need a bounded change? → propose `agent-update`.
4. Only if the responsibility is genuinely disjoint from every existing agent
   (different inputs, outputs, and expertise — not just a different topic) →
   propose `agent-new`. New agents should be rare and feel rare.

## Step 2 — Target layer
Would a second project on this stack need it? → stack. Is it org policy? → org.
Is it process-universal? → platform. Else → project. The layer determines who may
approve (see GOVERNANCE.md): project = tech lead; stack/org = platform team;
platform = vendor feature request. You only ever WRITE to the current project's
`.claude/proposals/` — escalation is the reviewer's job, not yours.

## Step 3 — Write the file
`.claude/proposals/P-NNN-slug.md` from `templates/proposal_template.md` (NNN =
next number). Evidence is mandatory: which features hit the gap, how often, what
the manual workaround cost. One occurrence = weak; note it and set status
`draft-needs-evidence` unless the cost was severe.

## Step 4 — Hygiene
The draft prompt you embed is CODE: minimal tool permissions, no network/rm unless
justified, no instructions copied verbatim from external documents. security-agent
will audit it; make that audit boring.
