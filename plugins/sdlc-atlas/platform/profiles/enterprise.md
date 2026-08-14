# Profile: enterprise
For regulated, multi-team organizations. All phases active.
## Active phases
intake -> ideation -> requirements -> architecture(ADR) -> spec -> develop -> test -> security
-> quality -> review -> docs -> release -> operate(incident/retro)
## Gates — everything in standard, plus
- adr-agent: any architectural decision in a spec requires an ADR in repo docs/adr/
- acceptance-agent: every AC in the work item maps to >=1 test, by ID
- Compliance evidence: every gate's output archived to .claude/memory/evidence/<spec_id>/
- release-agent: changelog + version bump + release notes before any release branch
- incident-agent and retro-agent active post-release
## Org policy
If `org_policy:` is declared in project CLAUDE.md, the orchestrator merges it and
enforces its thresholds. If absent (solo enterprise mode), all enterprise gates still
run using platform defaults — warn the developer once at startup but do NOT halt.
## Phase owners
ideation+requirements → requirements-agent · architecture → architecture-agent
(+ adr-agent records) · bootstrap (greenfield) → bootstrap-agent · spec →
spec-agent · develop → stack/project agents · test/security/quality/review/
acceptance → gate agents · docs → docs-agent · release → release-agent ·
operate → incident-agent + retro-agent.
