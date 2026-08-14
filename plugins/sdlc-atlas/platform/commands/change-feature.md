# /change-feature <work-item-id-or-description>

Change an already-specced/built feature. Order is mandatory. Load skill: `spec-paths`.

## Step 1 — Establish project root
```bash
pwd
```
PROJECT_ROOT = output above.

## Step 2 — Identify feature scope
Ask which **feature_slug** (folder under `.claude/specs/`) this change belongs to.
List existing:
```bash
find "PROJECT_ROOT/.claude/specs" -mindepth 2 -name '*.md' | sort
```

## Step 3 — Drift report
review-agent compares the **latest APPROVED** spec in that feature folder vs current
code (still true / drifted / removed). Old specs are dated records, not reality.

## Step 4 — New change spec
spec-agent drafts `PROJECT_ROOT/.claude/specs/<feature_slug>/<new_change_slug>.md`
with header `Supersedes: <feature_slug>/<prior_change_slug>` and delta section.
Mark the prior file `status: SUPERSEDED`.

## Step 5 — Approval gate
Display Decision Summary. Wait for **APPROVED** → write ACTIVE marker with spec_id
`<feature_slug>/<new_change_slug>`.

## Step 6 — Build and gate
Pipeline runs for the delta only (changed files, not full rebuild).
