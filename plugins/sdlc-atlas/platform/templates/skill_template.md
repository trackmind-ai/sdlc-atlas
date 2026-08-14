---
name: rollback-readiness
# Slug for this skill. Lowercase, kebab-case. Agents load this by name: `skills: [rollback-readiness]`
# Used in routing, gap-analysis, proposal filing. Must be globally unique within scope.

description: >-
  Pre-merge readiness gate. Verifies every database migration can be reversed,
  every feature flag can be toggled off, every config change has a safe default,
  and rollback procedures are documented. Answers: "If this feature breaks prod
  in 2 hours, can we roll back in <5 min without data loss?" Loaded by review-agent
  and acceptance-agent before merge approval.
# Exactly one sentence describing what this skill codifies (the procedure/pattern it teaches agents).
# Include: what problem it solves, when to load it, what agents use it.

scope: platform
# Visibility layer: "platform" (available to all projects), "stack" (stack-specific), or "project" (this project only)
# Determine scope by reusability: if many codebases need this pattern, it's "platform";
# if only one stack uses it, it's "stack"; if one project invented it, it's "project"

---

# Rollback Readiness Skill

Procedure for verifying a feature can be safely rolled back from production within
5 minutes and without data loss.

---

## When to load

- Pre-merge approval gates (review-agent reviewing a feature before /raise-pr)
- Acceptance-agent validating deployment readiness
- Incident response (post-incident checklist)

Load only once per feature; output is cached in orchestrator_state.md as `rollback_verified: yes|no`.

---

## Step 1 — Verify database migrations are reversible

For every migration file in `.claude/specs/<feature>/migrations/`:

1. Check that every migration has a matching `down()` function or `REVERT` comment
2. If the migration includes a `DROP COLUMN`, `DROP TABLE`, or `DELETE` without a backup procedure → **FAIL**
3. If the migration is a `CREATE TABLE` with data — check for a documented restore procedure (e.g., "restore from backup table `old_<table>`")

Red flags:
- `ALTER TABLE ... DROP COLUMN` without a backup
- Destructive `UPDATE` without a WHERE clause on the revert
- Irreversible data transformation (hash, aggregate, delete)

Output per migration:
```
migration: <filename>
reversible: [yes|no]
notes: <any caveats — e.g., "requires backup table old_users to exist">
```

If ANY migration is `reversible: no` → **FAIL** and recommend action (backup procedure, conditional revert, etc.)

---

## Step 2 — Verify feature flags can be toggled

If the feature uses feature flags (check CLAUDE.md § project or spec §6 Configuration):

For each flag `FLAG_X`:
1. Is the default value safe (i.e., does it run without the feature)? → must be `False` or equivalent
2. Is there a documented toggle procedure in the spec or RUNBOOK.md?
3. Can the flag be toggled without a redeploy? (check: in-memory config, env var, or database table)

Red flags:
- Feature flag defaults to `True` → code path will always run, can't be disabled
- No toggle procedure documented
- Flag is baked into compiled code (can only toggle on rebuild)

Output:
```
flag: <FLAG_X>
toggleable_without_redeploy: [yes|no]
documented_toggle_procedure: [yes|no]
```

If ANY flag cannot be toggled without a redeploy → **FAIL**.

---

## Step 3 — Verify config changes have safe defaults

For every config change in the spec:

1. What is the default value?
2. Can the system run with this default if the feature is disabled?
3. Is the default documented?

Red flags:
- Config change has no default (hard-required)
- Default assumes the feature is enabled
- Default is not environment-safe (e.g., hardcoded API keys)

Output:
```
config_key: <KEY>
default_value: <value or "undefined">
system_runnable_with_default: [yes|no]
```

If ANY config cannot be safely defaulted → **FAIL**.

---

## Step 4 — Verify rollback documentation

Check for a `## Rollback Procedure` section in the spec or a dedicated `RUNBOOK.md`:

Must include:
1. Exact steps (command line or API calls) to toggle the feature off
2. Steps to revert the database migration (if any)
3. How to verify rollback succeeded (health check, test query, etc.)
4. Estimated time to complete (must be < 5 min)

Output:
```
rollback_procedure_exists: [yes|no]
estimated_rollback_time: <minutes or "not documented">
includes_db_revert: [yes|no]
includes_verification_steps: [yes|no]
```

If rollback time is NOT documented or exceeds 5 min → **FAIL**.

---

## Step 5 — Synthesize readiness verdict

Print a readiness summary:

```
ROLLBACK READINESS CHECK
feature: <slug>

Migrations:
  ✓ All reversible   (or) ✗ <N> migrations not reversible

Feature flags:
  ✓ All toggleable   (or) ✗ <N> flags not toggleable

Config changes:
  ✓ All have safe defaults (or) ✗ <N> configs lack defaults

Rollback procedure:
  ✓ Documented, < 5 min  (or) ✗ Missing or > 5 min

VERDICT: READY ✓  (or)  BLOCKED — recommend remediation
```

If all checks pass → READY.
If any check fails → BLOCKED with specific recommendations (backup procedure, config doc, etc.).

---

## Hard rules

- **Reversible migrations only** — if a migration cannot be reverted, reject the feature at review gate
- **Toggleable features only** — if a feature can't be disabled without a redeploy, reject it
- **Default-safe configs only** — every config change must specify a safe default in documentation
- **Rollback < 5 min** — if rollback would take longer, reject or request architecture change (e.g., feature flag instead of code change)

