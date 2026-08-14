# Governance — How Capability Changes Happen

## The invariant
**Agents detect; humans with layer authority decide; nothing mutates mid-conversation.**
A developer's conversational "yes" never creates or changes capability. The settings
PreToolUse hook enforces this mechanically; this document defines who decides.

## Why
The failure mode: spec-agent asks "shall I create a caching-agent?", the developer —
focused on shipping a feature — says yes. Repeat for six months: 40 overlapping
agents, prompts no human reviewed, permissions nobody audited. The proposal system
separates the MOMENT OF NEED (mid-feature, agent notices a gap, files a proposal,
continues manually) from the MOMENT OF DECISION (review, with evidence, by the
right owner, on their own time).

## Approval authority by target layer
| Layer | Who approves | Via |
|---|---|---|
| L3 project | tech_leads in project CLAUDE.md | /approve-proposal, weekly review |
| L1 stack / L2 org | platform_team in ORG.md | escalated review |
| L0 platform | vendor (feature request) | never auto-applied |
The invoker check in /approve-proposal is mandatory; agents must refuse otherwise.

## Skill-first bias (enforced by the proposal-evaluation skill)
skill-update > skill-new > agent-update > agent-new, with written justification for
each rejected cheaper rung. Most "we need an agent" moments are skill moments:
an agent is a ROLE, a skill is a PROCEDURE. Roles stay few and stable.

## Evidence bar
≥2 independent occurrences, or 1 with severe cost (incident-grade). Single-hit
proposals park as draft-needs-evidence. retro-agent and incident-agent are the
main evidence generators.

## Security
A generated prompt is code. security-agent audits every draft for permission
escalation, injected instructions from source documents, and scope creep —
PASS verdict required before approval.

## Lifecycle
draft → in-review → approved-experimental (THIS project only) → stable
(after N successful uses, default 5, no gate regressions) → eligible for promotion
(see PROMOTION.md). Rejected proposals can't be re-filed without new evidence.
Approved files are renamed *.approved.md and become immutable via deny-list.

## Subtraction review (the governance of what we pre-built)
The proposal pipeline governs additions; this governs the existing inventory.
After the pilot, and quarterly thereafter, the tech lead reviews capability
usage: any agent/skill/command not invoked since the last review is a deletion
candidate (move to an attic/ folder one quarter, delete the next). Frameworks
die of accumulation — BMAD's documented scar is users touching 20% of it. Bias
to subtract; precedence means deletions can't break other layers.
