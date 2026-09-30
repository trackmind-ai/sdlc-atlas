---
name: audit-snapshot
description: >
  Incremental audit snapshot management for Claude Code.
  Maintains repository audit snapshots, detects changed and deleted files,
  supports full versus incremental audits, and tracks token savings by
  skipping previously audited files.
version: 1.0.0
category: platform
---

# Audit Snapshot Skill

## Purpose

Provide snapshot-based incremental auditing for repository analysis.

This skill enables Claude Code to:

- Persist repository audit state
- Detect changed files
- Detect deleted files
- Skip unchanged files
- Reduce token consumption
- Automatically select full or incremental audit modes

This skill is the single source of truth for audit snapshots.

---

# Responsibilities

This skill owns:

- Snapshot schema
- Snapshot file I/O
- Snapshot parsing
- Snapshot generation
- Change detection
- Deleted file detection
- Incremental audit orchestration
- Token savings accounting
- Audit summaries

This skill DOES NOT own:

- Deep file analysis
- CLAUDE.md generation
- knowledge.md generation
- Feature implementation
- Git operations

---

# Snapshot Location

Default path:

```text
.claude/memory/audit_snapshot.md
```

Only one active snapshot exists per repository.

---

# Snapshot Schema

Snapshots are Markdown documents containing:

1. YAML frontmatter
2. File inventory table

---

## YAML Frontmatter

Required fields:

```yaml
---
generated_at: 2026-06-22T14:30:12Z
audit_mode: full
repository_root: .
version: 1
---
```

Definitions:

| Field | Description |
|---------|-------------|
| generated_at | Snapshot creation timestamp (UTC) |
| audit_mode | full or incremental |
| repository_root | Repository root |
| version | Snapshot schema version |

---

# File Inventory Table

Format:

```markdown
| Path | MTime | Git Hash |
|--------|--------|-----------|
| src/app.py | 2026-06-22T13:10:00Z | a1b2c3d4 |
| README.md | 2026-06-22T12:00:00Z | e5f6g7h8 |
```

Definitions:

| Column | Description |
|----------|-------------|
| Path | Relative repository path |
| MTime | File modification timestamp (UTC) |
| Git Hash | Git blob hash for file contents |

---

# Example Snapshot

```markdown
---
generated_at: 2026-06-22T14:30:12Z
audit_mode: full
repository_root: .
version: 1
---

| Path | MTime | Git Hash |
|--------|--------|-----------|
| src/auth.py | 2026-06-22T14:00:00Z | 82a1d93 |
| src/user.py | 2026-06-22T13:40:00Z | 77ab21f |
| README.md | 2026-06-22T13:10:00Z | 93ef120 |
```

---

# Snapshot Read Procedure

## Purpose

Load previously audited repository state.

---

## Steps

### Step 1

Verify snapshot exists.

Example:

```text
.claude/memory/audit_snapshot.md
```

---

### Step 2

Read file contents.

---

### Step 3

Parse frontmatter.

Extract:

```yaml
generated_at
audit_mode
repository_root
version
```

---

### Step 4

Validate schema.

Required:

```yaml
generated_at
version
```

Required columns:

```text
Path
MTime
Git Hash
```

Invalid schema:

```yaml
status: error
reason: invalid_snapshot_schema
```

---

### Step 5

Build lookup map.

Example:

```yaml
snapshot:
    src/auth.py:
        mtime: 2026-06-22T14:00:00Z
        git_hash: 82a1d93

    README.md:
        mtime: 2026-06-22T13:10:00Z
        git_hash: 93ef120
```

---

# Snapshot Write Procedure

## Purpose

Persist audit state after completion.

---

## Steps

### Step 1

Generate frontmatter.

Example:

```yaml
generated_at: <UTC_NOW>
audit_mode: full|incremental
repository_root: .
version: 1
```

---

### Step 2

Generate inventory table.

Include:

```text
Path
MTime
Git Hash
```

---

### Step 3

Sort rows alphabetically by path.

Example:

```text
README.md
src/auth.py
src/user.py
```

---

### Step 4

Write atomically.

Procedure:

```text
snapshot.tmp
↓
validate
↓
rename → snapshot.md
```

Never partially overwrite snapshots.

---

# Change Detection

## Purpose

Determine whether files require re-audit.

---

# Exclusion Filters

Always exclude:

```text
CLAUDE.md
knowledge.md
.claude/memory/audit_snapshot.md
```

These files never participate in change detection.

---

# MTime Comparison

Compare:

```text
Current File MTime
vs
Snapshot MTime
```

---

## Unchanged

Condition:

```text
current == snapshot
```

Result:

```yaml
status: unchanged
```

---

## Changed

Condition:

```text
current > snapshot
```

Result:

```yaml
status: changed
```

---

## Timestamp Regression

Condition:

```text
snapshot > current
```

Meaning:

System clock changed,
checkout altered timestamps,
or metadata became unreliable.

Treat conservatively.

Result:

```yaml
status: changed
reason: timestamp_regression
```

Rule:

```text
snapshot > current → CHANGED
```

Never skip.

---

# Deleted File Detection

## Purpose

Detect files present in snapshot but absent now.

---

Condition:

```text
snapshot contains file
AND
current inventory does not
```

Result:

```yaml
status: deleted
path: src/legacy.py
```

Deleted files must be surfaced.

Update `knowledge.md` § Built features: prepend `[REMOVED]` to the entry header and preserve the rest of the entry as historical record.

Example:

```markdown
### [REMOVED] [spec_3] · Payment webhook handler
```

---

# Incremental Audit Orchestration

## Purpose

Determine audit strategy.

---

# Mode Detection

Snapshot exists:

```text
Incremental Audit
```

Snapshot missing:

```text
Full Audit
```

---

## Full Audit Workflow

```text
Enumerate Files
↓
Deep Audit All Files
↓
Generate Knowledge Artifacts
↓
Write Snapshot
```

---

## Incremental Audit Workflow

```text
Read Snapshot
↓
Enumerate Files
↓
Detect Changes
↓
Skip Unchanged Files
↓
Audit Changed Files
↓
Report Deleted Files
↓
Generate Knowledge Artifacts
↓
Write Snapshot
```

---

# File Skipping Workflow

For each file:

```text
Excluded?
    ↓ Yes
Skip

No
    ↓
Snapshot Entry Exists?
    ↓ No
Audit

Yes
    ↓
Changed?
    ↓ Yes
Audit

No
    ↓
Skip
```

---

# Token Savings Accounting

Estimated savings:

```text
≈ 800 tokens
per skipped file
```

---

## Accumulation

Example:

```yaml
skipped_files: 42

estimated_tokens_saved:
    33600
```

Calculation:

```text
skipped_files × 800
```

---

# Summary Output Format

Return:

```yaml
status: success

audit_mode: incremental

files:
    total: 150
    audited: 18
    skipped: 127
    deleted: 5

token_savings:
    estimated: 101600

snapshot:
    path: .claude/memory/audit_snapshot.md
    updated: true
```

---

# Full Audit Summary Example

```yaml
status: success

audit_mode: full

files:
    total: 150
    audited: 150
    skipped: 0
    deleted: 0

token_savings:
    estimated: 0
```

---

# Incremental Audit Example

Previous Snapshot:

```text
src/auth.py
src/user.py
README.md
```

Current Repository:

```text
src/auth.py      unchanged
src/user.py      modified
README.md        unchanged
src/payment.py   new
```

Result:

```yaml
audited:
    - src/user.py
    - src/payment.py

skipped:
    - src/auth.py
    - README.md
```

Estimated savings:

```yaml
skipped_files: 2
estimated_tokens_saved: 1600
```

---

# Failure Handling

Missing snapshot:

```yaml
status: fallback
reason: snapshot_missing
audit_mode: full
```

Invalid snapshot:

```yaml
status: fallback
reason: invalid_snapshot_schema
audit_mode: full
```

Atomic write failure:

```yaml
status: error
reason: snapshot_write_failed
```

Do not update the existing snapshot.

---

# Agent Usage

Invoke this skill whenever `/audit-project`
or any repository analysis capability needs to determine whether
a full or incremental audit should be executed.

This skill is the single source of truth for audit state management,
change detection, and token-efficient auditing across the platform.