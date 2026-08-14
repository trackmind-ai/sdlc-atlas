# Profile: standard
For product teams. The default when CLAUDE.md declares no profile.

## Active phases
intake → requirements → spec → develop → test → security → quality → review → pr

## Gates (fixed order)
1. Spec approval (/approve-spec)
2. test-agent — coverage threshold from org policy, else 70%
3. security-agent — zero HIGH/CRITICAL findings
4. sonar-agent — quality gate green (if Sonar configured, else lint pass)
5. review-agent — checklist pass

## Issue tracker
If `tracker:` in project CLAUDE.md is set to `ado`, `jira`, or `github`, fetch
the work item and add traceability links to spec and PR.
If `tracker: none` (or not declared), skip tracker fetch — proceed without it.
Traceability links are optional when no tracker is configured.

## Disabled
Release management, incident/retro loop, compliance evidence bundles.
