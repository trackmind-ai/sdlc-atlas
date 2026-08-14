---
name: specialist-review-panel
description: >-
  Multi-specialist diff review: Security, Performance, Data-Migration, API-Contract,
  Testing, Maintainability. Conditional gating by diff signals + line-count thresholds.
  Dedup by fingerprint, confidence boost on agreement. Feeds into review-agent gate 4.
scope: platform
requirement: CODE_REVIEW_DEPTH
---

# Specialist Review Panel

**Deep diff review** via independent specialist agent dispatches, folded into review-agent at gate 4. Each specialist has a distinct lens; together they catch issues one reviewer might miss.

## Specialist roster

| Role | Trigger | What it audits | Auto-dispatch threshold |
|---|---|---|---|
| **Security** | diff touches `auth/`, `crypto/`, `password`, `secret`, `token` | Input validation, auth/authz logic, cryptographic correctness, secret handling | Always when triggered |
| **Performance** | diff touches `database/`, `cache/`, `api/`, `frontend/` | N+1 queries, cache misses, expensive loops, bundle size impact, render cycles | Always when triggered |
| **Data-Migration/Schema** | diff touches `migrations/`, `schema`, `models.py`, `models.ts` | Migration reversibility, data loss risk, backward compatibility, rollback plan | Always when triggered |
| **API-Contract** | diff touches `routes/`, `endpoints/`, `api/`, `server.py` | Request/response shape consistency, versioning, error contracts, backward compatibility | Always when triggered |
| **Testing** | diff changes ≥50 lines OR touches `test/`, `spec/` | Coverage of new code, regression test for bug fixes, test quality | Auto-run if diff ≥50 lines; manual for smaller |
| **Maintainability** | diff changes any code | Naming consistency, complexity hotspots, duplication, dead code, clarity | **Not re-run here** — sourced from sonar-agent (gate 3), see below |

## Gating logic

**Always dispatch if diff touches the specialist's keyword set** — e.g. touching `auth/` = Security specialist always runs, regardless of diff size.

**Testing auto-runs if diff ≥50 lines** (configurable threshold in CLAUDE.md §8 under `specialist_threshold`). Below threshold, manual opt-in only.

**Maintainability is never dispatched as a specialist here.** sonar-agent (quality gate 3, runs before review-agent in the fixed gate order) already owns this lens and writes its findings to `.claude/memory/maintainability_findings.md`. review-agent reads that file and folds its findings into the aggregated output at Step 3, attributed as `[sonar-agent]` instead of `[Maintainability specialist]`. If the file is missing (sonar-agent gate was skipped or hasn't run), note "Maintainability: not available, sonar-agent gate did not run" rather than re-deriving it — this avoids the same diff being scored for the same concern by two independent agents.

**Auto-gate off after N consecutive runs with zero findings** — e.g., if Security specialist has reviewed 10 diffs and found nothing in 8 of them, provisionally skip the 9th unless keywords are present. This is a heuristic to avoid redundant specialist checks; must be explicitly documented with a per-specialist skip-count in the review output so humans can override if they disagree with the heuristic.

**Persisting the rolling window**: after every review-agent run, update
`.claude/memory/specialist_history.json`:
```json
{
  "Security":       { "runs": 10, "zero_findings": 8 },
  "Performance":    { "runs": 4,  "zero_findings": 1 },
  "Data-Migration": { "runs": 0,  "zero_findings": 0 },
  "API-Contract":   { "runs": 6,  "zero_findings": 5 },
  "Testing":        { "runs": 6,  "zero_findings": 3 }
}
```
Read this file before dispatch to compute each specialist's zero-findings rate
(`zero_findings / runs`, only meaningful once `runs >= 5`). A rate ≥ 0.8 makes that
specialist eligible for auto-skip on the next run — but the keyword trigger in the
roster table above always overrides the skip (e.g. Security still runs if the diff
touches `auth/`, regardless of its history). On every dispatch decision — run or
skip — increment `runs`, and increment `zero_findings` only if that specialist
reported zero findings this round. Never delete or reset this file; it is a
project-level artifact like `context_bundle.md`, not a log.

## Dispatch pattern

For each triggered specialist:
```
Agent: review-agent (in specialist mode for <Role>)
Inputs:
  - diff: <git diff content>
  - spec: <approved spec text>
  - specialist_role: <Role>
  - file_context: <relevant files touched>
Task: Review the diff ONLY through the lens of <Role>. Find issues specific to <Role>. Cite file:line for every finding. Output: findings list or "PASS: no <Role>-specific issues found."
```

Dispatch **all triggered specialists in parallel** (multiple Task calls in one message) — no barrier, each runs concurrently. Aggregate results after all return.

## Findings aggregation & dedup

After all specialist results return:
1. **Collect all findings**: `{ file, line, category, title, severity, specialist_role }` from each specialist.
2. **Dedup by fingerprint**: `{ file + line + category }` — if two specialists flag the same issue, merge into one entry, mark `[MULTI-SPECIALIST CONFIRMED]`, boost confidence by +1 point (e.g., 7 from one, 8 from another → report as 9).
3. **Sort by**: severity DESC, confidence DESC.
4. **Output**: deduplicated findings list with specialist attribution per line.

## Confidence calibration display tiers

(See `finding-verification-gate.md` for the shared pre-emit gate.)

| Confidence | Action | Display |
|---|---|---|
| 9–10 | ALWAYS SHOW | Emphasized, blocks unless overridden |
| 7–8 | ALWAYS SHOW | Standard priority |
| 5–6 | SHOW WITH CAVEAT | "Requires manual verification" |
| 3–4 | SUPPRESS TO APPENDIX | Mention in "Low-signal findings" section only |
| 1–2 | DROP | Never shown |

## PR Quality Score (informational)

Parallel metric, never blocks the PASS/FAIL verdict:
```
PR Quality Score = max(0, 10 − (critical×2 + high×1.5 + medium×1 + low×0.5))
```

Rounded to nearest integer. Printed alongside PASS/FAIL, helps the developer calibrate the review's harshness vs. completeness — a score of 6 + many findings suggests the diff has real issues; a score of 6 + few findings suggests the specialist panel is being stricter-than-necessary (encouraging override/discussion).

## Adversarial pass

After all specialists complete and findings are aggregated, dispatch a second, fresh-context review-agent instance:
```
Agent: review-agent (in adversarial mode)
Inputs:
  - diff: <git diff>
  - spec: <spec>
  - prior_findings: <findings from specialists>
Task: Assume the primary review missed issues. Hunt for what it overlooked. Challenge each prior finding (is it real? too mild?). Output: new findings, refined findings, or "VERIFIED: primary review is comprehensive."
```

This is **same-model independent context** (not cross-model like gstack's Codex option), but sufficient to catch single-agent hallucinations and blindspots. Fresh context = different call path = different behavior, without introducing a new vendor dependency.

## Output format

```
## Specialist Review Panel

**Specialists dispatched:** Security, Testing, Maintainability (3 of 6)
**Findings:** 7 total (2 CRITICAL, 1 HIGH, 4 MEDIUM)
**PR Quality Score:** 6/10

| Finding | Specialist | Severity | Confidence | File | Mitigation |
|---|---|---|---|---|---|
| SQL injection in query builder | Security | CRITICAL | 9/10 | app/db/query.py:42 | Parameterize all inputs |
| Uncovered error case | Testing | MEDIUM | 7/10 | app/api/users.py:103 | Add test for 500 status path |
| Duplicate logic in validator | Maintainability | MEDIUM | 8/10 | app/lib/validate.py:20,30 | Extract shared function |

**Adversarial pass:** Confirmed above findings; additionally flagged: Performance issue (N+1 on line 88) → added to findings.

**Verdict:** FAIL — CRITICAL issues must be addressed before merge.
```
