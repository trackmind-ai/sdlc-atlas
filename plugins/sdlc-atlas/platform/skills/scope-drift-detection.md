---
name: scope-drift-detection
description: >-
  Informational scope-drift check: compare spec intent against actual diff file
  list. Flags CLEAN, DRIFT DETECTED, or REQUIREMENTS MISSING. Never blocks;
  surfaces for review-agent output.
scope: platform
requirement: REVIEW_SCOPE_AUDIT
---

# Scope-Drift Detection

**Informational check during gate 4 (review-agent)**, not a blocking gate.

Before reviewing the diff for spec compliance, check whether the diff scope matches the spec's stated scope.

## Check

1. **Spec intent** — read spec's `## 1. Summary` and `## 10. Out of Scope`:
   - What the feature is supposed to do
   - What is explicitly excluded

2. **Diff scope** — list all changed files:
   ```bash
   git diff main...HEAD --name-only
   ```

3. **Compare**:
   - Does every changed file belong to the spec? (Spec mentions the domain/subsystem)
   - Are there changed files the spec doesn't mention?
   - Are there spec deliverables NOT represented in the changed files?

## Output format

```
## Scope Drift

Status: CLEAN | DRIFT DETECTED | REQUIREMENTS MISSING

### CLEAN
Diff matches spec intent:
- Spec claims: "Add POST /api/users endpoint"
- Diff files: app/routes/users.py, tests/test_users.py, docs/api/users.md
→ No surprises

### DRIFT DETECTED (example)
Spec says: "Add email auth, no social auth"
But diff includes: app/routes/oauth_google.py, app/lib/google_client.py
→ Scope expanded beyond spec (out-of-scope additions)

Recommendation: review these additions — are they intentional (requirements clarification) or scope creep (should be a separate feature)?

### REQUIREMENTS MISSING (example)
Spec promises: "Migrate 50 existing user records to new schema"
But diff has NO `migrations/` changes
→ Promised work not in diff

Recommendation: review-agent halts and asks developer where the migration code is.
```

**Blocking rule**: REQUIREMENTS MISSING always halts review with a question; DRIFT DETECTED is informational (may be intentional scope expansion per in-flight decisions); CLEAN proceeds.

Prevents silent feature-scope creep and catches forgotten deliverables early.
