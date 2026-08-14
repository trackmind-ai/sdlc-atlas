---
name: qa
description: >-
  Live UI quality assurance. Drives the Primary User Journey end-to-end first,
  then runs the per-screen health-score audit, then optionally fixes findings
  in a round loop (audit → fix → re-audit, up to 3 rounds). Modes: diff-aware
  (default once a prior report exists), full (auto-forced on greenfield first
  runs), quick. Flag: --report-only to audit without fixes.
---

# /qa

**Live UI quality assurance** — manual invocation for on-demand testing, or Phase 5a gate during feature pipeline for frontend-stack projects.

## Invocation

```
/qa [<url>] [--report-only] [--diff-aware|--full|--quick]
```

- `<url>` (optional): target URL to test. If omitted, uses the project's dev server URL from context.
- `--report-only`: audit only, no fix loop (equivalent to gstack's `/qa-only`)
- `--diff-aware` (default on feature branches, once a prior `qa_report.md` exists): focus on changed frontend files
- `--full`: comprehensive coverage of all pages and every Primary User Flow — auto-forced regardless of flag when no prior `qa_report.md` exists (greenfield first run)
- `--quick`: 30s smoke test (baseline health check) — still honored explicitly even on a greenfield first run

## Process

Dispatch `qa-agent` with the given parameters. Agent activates Chrome DevTools MCP (web) / Maestro MCP (mobile) at session start (auto-installing either if missing — see qa-agent Step -1), loads skill: `live-qa`. First drives `ux_brief.md`'s Primary User Journey end-to-end (the E2E Journey dimension) through the running app, then runs the per-screen health-score audit through whichever MCP tool matches the stack, computes health score (0–100 scale), classifies findings by severity. Unless `--report-only`, runs a round loop: fix this round's CRITICAL/HIGH findings → re-run the full audit (journey + screens) → repeat until clean or a 3-round/50-fix cap is hit. No Playwright.

## Output

`.claude/memory/qa_report.md` — health score breakdown per round, findings list per round, fixes applied (if any), before/after screenshots, regression tests, rounds run. Verdict: PASS (clean before the round cap) or FAIL (round/fix cap hit with CRITICAL/HIGH remaining — a broken Primary User Journey is always CRITICAL).

## Examples

```bash
# Standalone smoke test against dev server
/qa --quick

# Full audit, no fixes (report-only mode)
/qa https://staging.example.com --full --report-only

# Diff-aware audit with fixes (auto on feature branch)
/qa
```
