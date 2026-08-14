---
name: version-bump-policy
description: >-
  Semantic version bump state machine: FRESH/ALREADY_BUMPED/DRIFT_STALE/DRIFT_UNEXPECTED.
  Diff-size-driven bump class (MICRO auto-patch, PATCH auto, MINOR/MAJOR always ask).
  Used by release-agent.
scope: platform
requirement: VERSION_SEMVER_DISCIPLINE
---

# Version Bump Policy

**Semantic versioning state machine** — decides whether a version bump is needed, what kind, and automatically vs. ask-developer.

## Semver refresher

Format: `MAJOR.MINOR.PATCH[-prerelease][+build]`

- **MAJOR** (breaking): incompatible API changes, breaking schema changes, removed features
- **MINOR** (feature): new functionality, backward-compatible
- **PATCH** (bugfix): bug fixes, no API/schema changes
- **PRE-RELEASE** (alpha, beta, rc): interim versions for testing before release

## State machine

### State 0: Detect current version

Read from manifest (stack-aware):
- Node/npm: `package.json` → `version` field
- Python: `pyproject.toml` → `version` field, or `__version__` in `__init__.py`
- Go: `go.mod` → no standard field, check `VERSION` const in main package
- Ruby: `Gemfile.lock` or `lib/*/version.rb`

Record: **current_version**, **release_date** (from package metadata if available).

### State 1: Classify changes by scope

| Diff scope | Bump class | Decision |
|---|---|---|
| **SCOPE_DOCS** (only README, docs/) | NONE | No version bump. (Exception: if this is the first release ever, use 0.1.0 or 1.0.0 per org policy.) |
| **SCOPE_CONFIG** (only config, env, .github/) | PATCH | Bump patch, no ask — config is a detail. |
| **SCOPE_BACKEND** (app/, src/ — no schema) | MINOR | Bump minor (new feature / enhancement). |
| **SCOPE_FRONTEND** (ui/, client/, components/) | MINOR | Bump minor. |
| **SCOPE_SCHEMA** (migrations/, schema/, models — changes persist) | **MAJOR or MINOR?** | Ask developer: "Schema changes are breaking for downstream. Is this a breaking change (MAJOR) or backward-compatible (MINOR)?" |
| **SCOPE_API** (endpoints added/changed) | **MAJOR, MINOR, or PATCH?** | Ask developer: "API changes — is this breaking (MAJOR), additive (MINOR), or patch?" |
| **SCOPE_BACKEND + SCHEMA** | **MAJOR** | Always ask: schema changes are serious. Confirm the bump level and rollback plan. |

### State 2: Size-based automation (for clear cases)

| Diff size | Action |
|---|---|
| **<50 lines** (MICRO) | Auto-bump PATCH (low risk, routine fixes) |
| **50–500 lines** (PATCH range) | Auto-bump PATCH or MINOR per scope above |
| **>500 lines** (MINOR/MAJOR range) | Ask developer + confirm bump class |

### State 3: Check for drift

**Before bumping**, verify version state is clean:

```bash
# Check: is the current version already tagged in git?
git describe --tags --exact-match HEAD 2>/dev/null
```

| Case | State | Action |
|---|---|---|
| **HEAD is tagged v1.2.3** | ALREADY_BUMPED | STOP. Abort release process. Developer has already bumped. (Likely a manual bump between feature-complete and release; inform developer.) |
| **v1.2.3 tag exists but HEAD is 5 commits ahead** | DRIFT_STALE | Version in manifest doesn't match the last tag. Warn developer: "Last release was v1.2.3 (5 commits ago). Did you forget to update the version?" Ask: bump now, or revert to the tagged version? |
| **No tags; version in manifest is X.Y.Z** | FRESH | Safe to bump. Proceed. |
| **Manifest version is 2.0.0 but package.json shows 1.9.0** | DRIFT_UNEXPECTED | Mismatch between declared version and manifest. Halt and ask: "Versions disagree. Fix the manifest before releasing." |

### State 4: Apply bump

If auto-bumping (PATCH on <50 line diff):
```
current: 1.2.3
lines changed: 35
→ bump to 1.2.4
```

If asking developer (MINOR/MAJOR decision):
```
Recommended: MINOR (new endpoint added)
Or: MAJOR if the endpoint replaces and removes the old one?

Enter: MAJOR | MINOR | PATCH (or "skip")
```

Write new version to manifest(s):
- Update `package.json` version
- Update `pyproject.toml` version
- Update `VERSION` const in main package
- etc. (stack-specific)

### State 5: Prepare commit

Create a clean commit:
```bash
git add package.json pyproject.toml # (or manifest files)
git commit -m "chore(release): v${new_version}

Release notes:
- Feature: new POST /users endpoint
- Bugfix: fixed auth token expiry bug

[source: spec <feature>/<change>]"
```

No code changes in this commit — purely version + changelog.

## Output format

```
## Version Bump Report

Current version: 1.2.3
Diff scope: backend + config
Diff size: 127 lines
Classification: MINOR (new features)

Decision: Auto-bump to 1.3.0 (MINOR)
Rationale: >50 lines + scope is feature-only (no breaking changes)

Manifest updates:
- package.json: 1.2.3 → 1.3.0 ✓
- pyproject.toml: 1.2.3 → 1.3.0 ✓

Commit ready: `chore(release): v1.3.0`
Status: READY TO TAG (human runs: git tag v1.3.0 && git push origin v1.3.0)
```

Release agent stops here — tagging and deploying are human-driven per rule 8 (agents never push protected branches).
