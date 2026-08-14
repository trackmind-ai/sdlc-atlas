---
name: git-operations
description: >
  Standardized Git operations for Claude Code agents.
  Handles branch discovery, checkout workflows, stash management,
  validation, retries, timeout protection, and conflict surfacing.
version: 1.0.0
category: platform
---

# Git Operations Skill

## Purpose

Provide a safe and repeatable mechanism for Claude Code agents to perform Git operations.

This skill prevents accidental repository corruption by enforcing validation,
recovery procedures, timeout handling, and explicit conflict reporting.

Use this skill whenever an agent needs to interact with Git.

---

# Responsibilities

This skill owns:

- Branch listing
- Branch validation
- Branch checkout
- Remote branch checkout
- New branch creation
- Stash creation
- Stash restoration
- Timestamped stash naming
- Validation after operations
- Retry on transient failures
- Timeout protection
- Conflict detection
- Error surfacing

This skill DOES NOT own:

- Code generation
- Pull request creation
- Merge approval decisions
- Conflict resolution decisions
- Release management

Those responsibilities belong to other skills.

---

# Safety Rules

Before performing any Git operation:

1. Verify repository exists.

2. Verify `.git` directory exists.

3. Verify Git is installed.

4. Capture current branch.

5. Capture working tree status.

6. Never discard user changes automatically.

7. Never force checkout.

8. Never force push.

9. Never resolve merge conflicts automatically.

10. Surface all conflicts to the calling agent.

---

# Standard Timeout Policy

Use these timeouts:

| Operation | Timeout |
|-----------|----------|
| git status | 10 seconds |
| git branch | 10 seconds |
| git checkout | 30 seconds |
| git fetch | 60 seconds |
| git stash | 30 seconds |
| git stash pop | 30 seconds |
| git pull | 60 seconds |

If timeout occurs:

- Abort operation.
- Preserve repository state.
- Return failure details.
- Suggest retry.

---

# Workflow

## Step 1: Validate Repository

Execute:

```bash
git rev-parse --is-inside-work-tree
```

Expected result:

```text
true
```

If validation fails:

Return:

```text
ERROR:
Not a Git repository.
```

Stop execution.

---

## Step 2: Capture State

Execute:

```bash
git branch --show-current
git status --short
```

Store:

- current_branch
- working_tree_state

Example:

```yaml
current_branch: develop

working_tree:
  - M src/app.py
  - ?? new_file.ts
```

---

# Branch Listing

## Local Branches

Execute:

```bash
git branch
```

Return:

```yaml
local_branches:
  - main
  - develop
  - feature/auth
```

---

## Remote Branches

Execute:

```bash
git branch -r
```

Return:

```yaml
remote_branches:
  - origin/main
  - origin/develop
  - origin/release
```

---

## All Branches

Execute:

```bash
git branch -a
```

---

# Checkout Operations

## Checkout Existing Local Branch

Execute:

```bash
git checkout <branch>
```

Validate:

```bash
git branch --show-current
```

Expected:

```text
<branch>
```

---

## Checkout Remote Branch

Execute:

```bash
git fetch origin

git checkout -b <branch> origin/<branch>
```

Validate branch switch.

If branch already exists locally:

Fallback to:

```bash
git checkout <branch>
```

---

## Create New Branch

Execute:

```bash
git checkout -b <new_branch>
```

Validate:

```bash
git branch --show-current
```

Expected:

```text
<new_branch>
```

---

# Stash Operations

## Create Timestamped Stash

Generate timestamp:

```text
YYYY-MM-DD_HH-MM-SS
```

Execute:

```bash
git stash push -u -m "claude:<source-branch>:<timestamp>"
```

Example:

```bash
git stash push -u -m "claude:develop:2026-06-22_14-30-12"
```

Validate:

```bash
git stash list
```

Return created stash identifier.

Example:

```yaml
stash_created:
  id: stash@{0}
  label: claude:develop:2026-06-22_14-30-12
```

---

## List Stashes

Execute:

```bash
git stash list
```

Return:

```yaml
stashes:
  - stash@{0}: claude:develop:2026-06-22_14-30-12
  - stash@{1}: WIP on develop
```

---

## Restore Latest Stash

Execute:

```bash
git stash pop
```

Validate:

```bash
git status --short
```

---

## Restore Specific Stash

Execute:

```bash
git stash pop stash@{n}
```

Validate working tree.

---

# Conflict Handling

If Git returns:

```text
CONFLICT
```

Immediately stop execution.

Return:

```yaml
status: conflict

conflicts:
  - src/service.py
  - package-lock.json

message: >
  Manual conflict resolution required.
```

Do NOT:

- run git add
- run git commit
- rerun stash pop
- attempt auto-resolution

---

# Retry Policy

Retry only transient failures.

Eligible failures:

- fetch interrupted
- checkout lock contention
- temporary file lock

Retry limits:

```yaml
max_attempts: 3
backoff:
  - 2 seconds
  - 5 seconds
  - 10 seconds
```

Do NOT retry:

- merge conflicts
- invalid branch names
- repository corruption
- detached HEAD ambiguity

---

# Error Recovery

If checkout fails after stash:

Attempt:

```bash
git checkout <original_branch>
```

If stash was created and not restored:

Return stash details.

Example:

```yaml
recovery:
  original_branch: develop

  stash_preserved:
    id: stash@{0}
    label: claude:2026-06-22_14-30-12
```

Never drop stashes automatically.

---

# Output Contract

Successful operation:

```yaml
status: success

operation: checkout

branch: feature/auth

previous_branch: develop

working_tree_clean: true
```

Conflict:

```yaml
status: conflict

files:
  - src/app.ts
```

Failure:

```yaml
status: error

operation: checkout

error: Branch not found

attempts: 1
```

Recovery:

```yaml
status: recovered

restored_branch: develop

stash_preserved: stash@{0}
```

---

# Examples

## Example: Checkout Existing Branch

Input:

```text
Checkout branch feature/payments
```

Output:

```yaml
status: success
operation: checkout
branch: feature/payments
```

---

## Example: Checkout Remote Branch

Input:

```text
Checkout origin/release/v2
```

Output:

```yaml
status: success
operation: checkout_remote
branch: release/v2
```

---

## Example: Stash Before Switching

Input:

```text
Switch to develop preserving changes
```

Output:

```yaml
status: success
stash_created: stash@{0}
branch: develop
```

---

# Agent Usage

Invoke this skill whenever a task requires:

- determining repository branches,
- changing branches,
- preserving uncommitted work,
- restoring previous work,
- validating Git state,
- surfacing conflicts,
- recovering safely from Git failures.

This skill is the single source of truth for Git behavior across the platform.