# <Organization Name> — Org Policy Layer (L2)
Owned by the platform team. Applies to ALL projects in this organization.
Projects reference this via `org_policy: <path-or-repo>` in their CLAUDE.md.
Install into a project: `install.sh --org <this-dir> --project <repo>`.
Projects may TIGHTEN these rules in their own layer; they may never loosen them.

## Authority (used by /approve-proposal)
platform_team: [FILL IN — names/handles who may approve stack/org-layer proposals]
escalation: [FILL IN — channel for platform-layer feature requests to the vendor]

## Issue tracker
tracker: [FILL IN — ado / jira / github]
org_url: [FILL IN]

## Quality thresholds (gates read these; project CLAUDE.md may only raise them)
coverage_min: 80
security_fail_on: HIGH
sonar_required: true

## Branch & PR rules
protected_branches: [main, develop, release/*]
branch_pattern: feature/<work-item-id>-<slug>
pr_requires: [approved spec link, gate evidence, two reviewers]

## Compliance
frameworks: [FILL IN — e.g. HIPAA, SOC2, PCI, none]
evidence_retention: .claude/memory/evidence/ archived per release
