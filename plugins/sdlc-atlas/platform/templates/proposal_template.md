# P-<NNN> — <short title>
| | |
|---|---|
| Type | skill-update / skill-new / agent-update / agent-new |
| Target layer | project / stack:<name> / org / platform |
| Status | draft / draft-needs-evidence / in-review / approved-experimental / stable / rejected |
| Filed by | <agent or developer> on <date> |
| Authority required | <from GOVERNANCE.md for this layer> |

## Gap
What work has no adequate capability today. One paragraph, concrete.

## Evidence (mandatory)
| Feature/incident | Date | Manual workaround cost |
|---|---|---|
One occurrence = draft-needs-evidence unless severity justifies otherwise.

## Skill-first ladder
Why each cheaper option was insufficient: existing-skill update → new skill →
agent update → (only then) new agent. agent-new requires demonstrated DISJOINT
responsibility, not just a new topic.

## Closest existing capability
<name + why extending it is wrong>

## Draft
The proposed prompt/skill text. Minimal tool permissions, justified individually.

**For agent proposals:** start from `platform/templates/agent_template.md` and fill in — do not compose frontmatter from scratch.  
**For skill proposals:** start from `platform/templates/skill_template.md` and fill in — do not compose frontmatter from scratch.

## Security Review (security-agent fills)
Permission escalation / injection risk / scope creep — verdict: PASS / FAIL.

## Decision
<approver, date, rationale> — on approval rename file to .approved.md
