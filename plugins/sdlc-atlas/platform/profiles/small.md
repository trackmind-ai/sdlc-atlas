# Profile: small
For solo developers and prototypes. Value in 10 minutes, no ceremony.
## Active phases
intake -> requirements -> spec -> develop -> test
## Gates
- Spec approval (still mandatory — the one non-negotiable)
- test-agent must pass (if test command configured)
- Live Browser/Mobile QA E2E verification (mandatory if frontend/mobile stack present)
## Disabled
Issue-tracker integration, security-agent (downgraded to warn-only), sonar-agent,
review-agent, release/incident/retro phases, ADRs, traceability reports.
## Orchestrator behaviour
Single-question interviews where possible; spec template sections tagged (enterprise)
skipped; PR checklist reduced to tests-pass + spec-link.
