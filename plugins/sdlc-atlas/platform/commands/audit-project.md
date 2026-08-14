---
name: audit-project
description: "Deep-read EVERY file in an existing brownfield project, understand what is already built, then write or regenerate .claude/CLAUDE.md and knowledge.md with full accuracy. Use on any existing project before running /feature for the first time."
---

# /audit-project

## Mode detection

Before invoking setup-agent, check if a snapshot exists:

```bash
test -f .claude/memory/audit_snapshot.md && echo "incremental" || echo "full"
```

Store the result as `audit_mode` (either "incremental" or "full").

Use the Task tool to dispatch `setup-agent` as a subagent in brownfield deep-read mode:

```
Agent: setup-agent
Mode: /audit-project
Inputs:
- project_root: <output of pwd>
- trigger: audit-project
- audit_mode: <audit_mode from mode detection step>

Task: Deep-read source files in this brownfield project to update knowledge.md.

If audit_mode is "incremental":
  - Read .claude/memory/audit_snapshot.md
  - Enumerate all files
  - Detect changed files via mtime + git hash comparison
  - Detect deleted files (in snapshot, absent now)
  - Skip unchanged files
  - Audit only changed files and new files
  - Mark deleted files as [REMOVED] in knowledge.md § Built features

If audit_mode is "full":
  - Enumerate all files
  - Audit every file

For both modes:
  - Exclude CLAUDE.md and knowledge.md from change detection
  - Treat timestamp regression (snapshot mtime > current mtime) as CHANGED
  - Ask ONE confirmation message
  - Update .claude/CLAUDE.md and knowledge.md with full accuracy
  - Write snapshot to .claude/memory/audit_snapshot.md after completion

Return summary:
  - Total files enumerated
  - Files audited (changed + new)
  - Files skipped (unchanged)
  - Files deleted
  - Estimated token savings (skipped_files × 800)
```

**What setup-agent does — in order:**

1. **Scans the entire project tree** — every folder, every file, nothing skipped except
   `node_modules/`, `.git/`, `__pycache__/`, `dist/`, `build/`, `.next/`
2. **Reads EVERY source file** — routes, models, views, serializers, components, hooks,
   workers, tasks, schemas, tests, config files, CI pipeline, Dockerfile, README.
   Not just manifests — every `.py`, `.ts`, `.tsx`, `.js`, `.go`, `.rs` etc.
3. **Builds a complete picture** of:
   - What the project is and what it does
   - Every feature already built (from source code, not just specs)
   - Every framework and library in use
   - Every convention followed in the codebase
   - Exact test/lint/security commands from CI or package scripts
4. **Asks ONE confirmation message** — shows everything it found, asks only about gaps
5. **Writes `.claude/CLAUDE.md`** — lean platform/stack config file containing:
   - Project identity, stack declaration, tracker config
   - Platform, stack, and enterprise built-in commands (4.1–4.3)
   - Platform + stack agents and skills (5.1, 5.2, 6.1, 6.2)
   - Platform + stack routing table (5.4)
   - Quality gates, spec settings, PR policy, orchestrator state pointer
   - References to `knowledge.md` for all project-specific additions
6. **Writes `knowledge.md`** — full Built features registry from actual source code:
   - Project commands (L3), domain agents (L3), project routing, project skills (L3)
   - Tech leads and org policy (standard/enterprise)
   - Uninferable facts (architecture decisions, integrations, conventions, brownfield constraints)
   - **Full detailed Built features registry** — one rich section per feature, populated from
     actual source code with files, endpoints, data models, decisions, and test coverage
7. **Copies agents/skills/commands** for all detected stacks from PLATFORM_HOME
8. **Creates missing `.claude/` skeleton folders** (idempotent — safe to re-run)


**The key difference from /setup:**
- `/setup` asks questions first → for empty new projects with no code
- `/audit-project` reads everything first → for existing brownfield projects

**Safe to re-run:** shows what would change, confirms before overwriting.
Existing Built features history in knowledge.md is always preserved and merged.

**After /audit-project:** run `/feature "<what to build next>"` — the orchestrator now
knows the full codebase and will not duplicate or conflict with existing work.

## Snapshot persistence

After setup-agent completes, it writes or updates `.claude/memory/audit_snapshot.md` with:

- YAML frontmatter: `generated_at`, `audit_mode`, `repository_root`, `version`
- File inventory table: `Path | MTime | Git Hash`

Snapshot write is atomic: write to `.claude/memory/audit_snapshot.tmp`, validate, then rename to `audit_snapshot.md`.

## Coverage report (full audit only)

After snapshot is written, if audit_mode = "full":

1. **Greenfield check:** Read `knowledge.md § Built features`. If empty (no shipped features), print:
   ```
   Coverage report skipped: no built features detected (greenfield project).
   ```
   Stop here — do NOT write `.claude/memory/coverage_report.md`.

2. **Test file discovery:** Scan project tree (same exclusions as audit: node_modules/, .git/, __pycache__/, dist/, build/, .next/, venv/, .venv/) for test files matching language patterns:
   - Python: `test_*.py`, `*_test.py`, `tests/**/*.py`
   - Java: `*Test.java`, `*Tests.java`
   - JS/TS: `*.test.js`, `*.spec.ts`, `__tests__/**/*`
   - Go: `*_test.go`
   - Ruby: `*_spec.rb`
   - C#: `*Test.cs`
   - PHP: `*Test.php`

3. **Feature-to-test mapping:** For each feature in knowledge.md § Built features:
   - Extract key file paths from the "Key files" section
   - For each test file, search content for references to those key files (import paths, relative imports, package references, or literal string references)
   - A key file is "covered" if at least one test file references it
   - Estimated coverage = (covered key files / total key files) × 100

4. **Classification:** coverage < 80% → UNDER-TESTED | coverage ≥ 80% → OK

5. **Terminal output:** Print table sorted by coverage % ascending (lowest first):
   ```
   Feature              | Coverage | Status
   ------------------------------------------------
   <feature name>       | XX.X%    | UNDER-TESTED
   <feature name>       | XX.X%    | OK
   ```

6. **Write `.claude/memory/coverage_report.md`** (overwrite if exists):
   - YAML-style header: generated_at timestamp, total features, under-tested count, average coverage
   - Summary table
   - Per-feature section: coverage %, status, test files list, key files list

7. **On failure:** Log warning, do NOT halt audit-project. Continue to final summary.

8. **Include coverage stats in final audit-project summary:**
   ```
   Coverage:        N features analyzed · N under-tested · avg XX.X%
   Report:          .claude/memory/coverage_report.md
   ```

If audit_mode = "incremental": skip this entire section silently.
