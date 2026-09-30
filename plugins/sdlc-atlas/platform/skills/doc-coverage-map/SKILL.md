---
name: doc-coverage-map
description: >-
  Diataxis documentation coverage matrix: for every changed public-surface item,
  check tutorial/how-to/reference/explanation coverage (✅/❌). Flag zero-coverage
  gaps and stale architecture diagrams. Used by docs-agent.
scope: platform
requirement: DOC_COVERAGE_AUDIT
---

# Doc Coverage Card (Quadrant Documentation Standard)

**Documentation completeness and staleness detection** — pre-req for docs-agent.

## Quadrant Documentation Standard

Four documentation types, each serving a distinct need (the Quadrants):

| Quadrant Type | Purpose | Example | Audience |
|---|---|---|---|
| **Tutorial** | "Learn by doing" — hands-on from zero to first meaningful result | "Deploy your first function to Lambda" | Beginners |
| **How-to** | "Get this specific job done" — assumes familiarity, focuses on steps | "Configure auto-scaling for your function" | Practitioners |
| **Reference** | "Find what you need" — complete, organized by concept, lookup-friendly | "Lambda API reference: Invoke, CreateFunction, ..." | Developers in flow |
| **Explanation** | "Understand this topic" — context, history, alternatives, philosophy | "Why Lambda uses event-driven architecture" | Learners wanting depth |

A feature that adds a new API endpoint ideally has (at minimum) a reference entry + a how-to guide for the common use case. A feature that changes onboarding should add/update the tutorial.

## Coverage audit

1. **Identify changed public-surface items** from the diff:
   - New/changed **functions** (public API): `def get_user(id): ...`
   - New/changed **endpoints** (REST): `POST /api/users`
   - New/changed **CLI commands**: `deploy --region`
   - New/changed **config keys**: `max_retries=N`
   - New/changed **skills** (platform): `/new-command`
   - Anything documented in an API reference or user manual

2. **For each item, check coverage:**
   ```
   Item: POST /api/users (create new user)
   
   ✅ Reference: docs/api/users.md → "POST /api/users — Create a new user" ✓
   ✅ How-to: docs/guides/manage-users.md → "Create a user via API" ✓
   ❌ Tutorial: (none — not mentioned in getting-started)
   ❌ Explanation: (none — no rationale for user model design)
   
   Coverage: 2/4 (acceptable for API, tutorial may be out of scope)
   ```

3. **Flag zero-coverage items** — anything with ❌/❌/❌/❌:
   ```
   new_feature() function
   ❌❌❌❌
   → CRITICAL GAP: no docs at all. Add reference + how-to.
   ```

4. **Flag stale diagrams** — architecture docs with named entities:
   - Example: `docs/architecture.md` mentions "User Service" and "Auth Service" with a diagram.
   - Check: do those services still exist in the code (`app/services/user.py`, `app/services/auth.py`)?
   - If a service was renamed/removed, mark diagram STALE.

For each item listed in the coverage card, you must verify its existence on disk.
- Query the file structure to find the exact definition line of the public function, API route, config key, or CLI flag.
- Do not list any placeholder, speculative, or planned item in the coverage card unless it has been merged and exists in the current codebase state.
- Ensure that the action recommendation cites the specific code source (file:line) where documentation updates should target.

## Output format

In addition to generating the markdown list below, you MUST serialize and save this data to `PROJECT_ROOT/.claude/memory/doc_coverage_card.json` in this format:
```json
{
  "items": [
    { "name": "POST /api/users", "type": "Endpoint", "reference": true, "howto": true, "tutorial": false, "explanation": false, "action": "Add how-to if missing" }
  ]
}
```

```
## Documentation Coverage Card

| Item | Type | Reference | How-to | Tutorial | Explanation | Action |
|---|---|---|---|---|---|---|
| POST /api/users | Endpoint | ✅ | ✅ | ❌ | ❌ | Add how-to if missing |
| get_user(id) | Function | ✅ | ❌ | ❌ | ❌ | Add reference + how-to |
| /qa command | Skill | ❌ | ❌ | ❌ | ❌ | **CRITICAL: all four types missing** |

**Stale diagrams:**
- `docs/architecture.md` (line 10): mentions "PaymentService" (no longer in codebase) → update or remove

**Zero-coverage gaps (action required):**
1. `/qa` skill — add reference + how-to before release
2. `delete_user` function — add reference
```

## Priority for docs-agent

Use this coverage card to **prioritize which stale docs to update**:
- Zero-coverage items = highest priority (document them now)
- 1-coverage items = medium priority (add missing types)
- 2–3 coverage = low priority (nice-to-have depth)
- Stale diagrams = audit and fix

This prevents the "ship a feature with 0 docs" scenario by surfacing coverage gaps before the feature is released.
