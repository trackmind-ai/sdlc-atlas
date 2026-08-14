# /spec-status

List every spec under `.claude/specs/` (recursive), grouped by **feature_slug**.

For each `<feature_slug>/<change_slug>.md` show:
- status (DRAFT / APPROVED / SUPERSEDED)
- work item link
- supersedes (if any)
- pipeline phase from `orchestrator_state.md` when spec_id matches

```bash
find "PROJECT_ROOT/.claude/specs" -mindepth 2 -name '*.md' | sort
```

Legacy flat `specs/spec_N.md` files are listed under `(legacy)`.
