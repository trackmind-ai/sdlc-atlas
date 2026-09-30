---
name: spec-paths
description: >-
  Dynamic spec layout: .claude/specs/<feature>/<change>.md — e.g. todo/add-due-date.md.
  Used by spec-agent, orchestrator, /approve-spec, /change-feature, /spec-status.
---
# Spec paths (dynamic)

## Layout

```
.claude/specs/
  <feature>/
    <change>.md
```

- **feature** — product/domain folder, **short noun** (e.g. `todo`, `auth`, `billing`)
  - Use the feature or app name — **not** a compound capability slug like `todo-crud`
- **change** — this delivery or iteration (e.g. `add-due-date`, `crud-api`, `fix-pagination`)
- **spec_id** = `<feature>/<change>` (no `.md`) — used by `/approve-spec`, state, evidence

**Examples:**

| Path | spec_id | Approve command |
|------|---------|-----------------|
| `specs/todo/add-due-date.md` | `todo/add-due-date` | `/approve-spec todo/add-due-date` |
| `specs/todo/crud-api.md` | `todo/crud-api` | `/approve-spec todo/crud-api` |
| `specs/auth/login-flow.md` | `auth/login-flow` | `/approve-spec auth/login-flow` |

## Slug rules

- Lowercase ASCII, words separated by `-`
- Pattern: `^[a-z][a-z0-9-]*$`
- **feature:** prefer one word when possible (`todo`, not `todo-app` or `todo-crud`)
- **change:** verb or scope describing this change (`add-due-date`, `initial-api`)
- Confirm both names with the developer if ambiguous

## Resolving paths (orchestrator + spec-agent)

1. **Interview:**
   - **Feature** → folder name (e.g. `todo`) — reuse if folder already exists
   - **Change** → file stem for this work (e.g. `add-due-date`)
2. **List existing changes:**
   ```bash
   ls "PROJECT_ROOT/.claude/specs/<feature>/" 2>/dev/null
   ```
3. **Choose:**
   - New product area → `mkdir specs/<feature>/` + new `<change>.md`
   - Same feature, new delivery → new `<change>.md` alongside prior specs
   - Pre-approval edit → same file in place
4. **Write:**
   ```bash
   mkdir -p "PROJECT_ROOT/.claude/specs/<feature>"
   ```

## Versioning / supersede

- **Before approval:** edit `specs/<feature>/<change>.md` in place.
- **After approval:** immutable. Next work = new file, e.g. `specs/todo/add-due-date.md`.
- Header: `Supersedes: todo/crud-api` + delta section; mark old file SUPERSEDED.
- Get drift report from review-agent before superseding.

## Evidence archive (enterprise)

`.claude/memory/evidence/<feature>/<change>/`

## Legacy

Flat `specs/spec_1.md` still works. **New specs:** `specs/<feature>/<change>.md` only.

## Discovery

```bash
find "PROJECT_ROOT/.claude/specs" -mindepth 2 -name '*.md' | sort
```

`/spec-status` groups by **feature** folder.
