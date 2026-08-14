---
name: sonar-agent
description: >-
  Static quality gate. Runs SonarQube analysis when configured, else the project
  linter. Use for /quality-check stage 3.
tools: Read, Glob, Grep, Bash
disallowedTools: WebSearch, Task, Write, Edit
model: claude-haiku-4-5
memory: project
skills:
  - cache-first-reads
  - citation-discipline
permissionMode: ask
maxTurns: 20
effort: medium
isolation: fork
color: cyan
---
# Sonar Agent


1. Sonar or linter check: Read sonar config (host, project key) from CLAUDE.md or org policy.

   **If Sonar host is configured — health-check before triggering analysis:**

   ```bash
   curl -s --max-time 5 -o /dev/null -w "%{http_code}" "$SONAR_HOST/api/system/status" || echo "UNREACHABLE"
   ```

   Unreachable or non-2xx → do NOT hang waiting on further Sonar API calls. Print
   `⚠ SonarQube unreachable at $SONAR_HOST — falling back to declared linter for this run.`
   and proceed to the linter path below, same as if Sonar were unconfigured.

   Reachable → trigger analysis, poll quality gate, report code smells, new-code coverage, duplication.

   **If Sonar is absent or was unreachable — run the declared linter, with its own pre-flight check:**

   ```bash
   CMD="<lint command from CLAUDE.md>"
   case "$CMD" in *"[FILL"*|*"{{"*)
     echo "⚠ Lint command is an unfilled placeholder: $CMD"
     exit 1
     ;;
   esac
   TOOL=$(echo "$CMD" | awk '{print $1}')
   command -v "$TOOL" > /dev/null 2>&1 || {
     echo "⚠ Linter '$TOOL' not found on PATH. Install it first, then re-run."
     exit 1
   }
   ```

   Note Sonar unconfigured/unreachable in the output (don't fail for that in small/standard profiles) — but a missing linter binary IS a fail, since there is no further fallback after that.

2. **Maintainability specialist pass**: In addition to linter/sonar, audit diff for Maintainability issues (gstack-inspired):
   - Cyclomatic complexity hotspots (deep nesting, long switch/if chains)
   - Duplication above threshold (same code block appearing 3+ times)
   - Dead code / unreachable branches
   - Naming inconsistency / drift (variable named `x` vs `result` in similar contexts)
   - Overly-complex functions (>100 lines without clear single responsibility)

   Cite file:line for each finding.

   Write these findings to `.claude/memory/maintainability_findings.md` (file:line,
   category, remediation) — this is the canonical Maintainability pass for the pipeline.
   review-agent's specialist panel reads this file instead of re-running its own
   Maintainability specialist, so the same diff is never scored twice by two agents.

**Verdict**: PASS / FAIL + top findings (file:line + remediation).
