---
name: raise-pr
description: "Final readiness check, commit feature files, push branch, and raise PR in Azure DevOps."
---

# /raise-pr

## Step 1 — Establish roots

```bash
pwd
echo "$HOME/.claude"
```

- First output  → **PROJECT_ROOT**
- Second output → **PLATFORM_HOME**

---

## Step 2 — Readiness checks

Run all checks before touching git. If any check fails, print the failure and stop.

**2a. Approved spec exists:**
```bash
cat "PROJECT_ROOT/.claude/memory/approvals/ACTIVE" 2>/dev/null || echo "NO_APPROVAL"
```
If `NO_APPROVAL` → stop:
```
⛔ No approved spec found. Run `/approve-spec <feature>/<change>` first.
```

Read the ACTIVE file to extract `<spec_id>` (format: `<feature_slug>/<change_slug>`).

**2b. Spec file exists:**
```bash
ls "PROJECT_ROOT/.claude/specs/<feature_slug>/<change_slug>.md" 2>/dev/null && echo "EXISTS" || echo "MISSING"
```
If `MISSING` → stop with: `⛔ Spec file not found at .claude/specs/<spec_id>.md`

**2c. knowledge.md updated (Built features entry present for this spec_id):**
```bash
grep -q "<feature_slug>/<change_slug>" "PROJECT_ROOT/.claude/knowledge.md" && echo "FOUND" || echo "MISSING"
```
If `MISSING` → stop with: `⛔ knowledge.md has no entry for <spec_id>. Run /feature to completion first.`

**2d. Read the spec to extract the feature title for the commit message:**
```bash
head -5 "PROJECT_ROOT/.claude/specs/<feature_slug>/<change_slug>.md"
```
Extract the title line (first `# ` heading) → **FEATURE_TITLE**

**2e. Run knowledge harvesting (MANDATORY Agentic Learning):**
Run the `/harvest-knowledge` routine (using `platform/skills/knowledge-harvesting/SKILL.md` or the `knowledge-harvesting` skill) to automatically scan recent logs, debug loops, and commits, and append new patterns and conventions to `PROJECT_ROOT/.claude/knowledge.md`. This must complete before staging so the updated knowledge base is committed together with the feature changes.

---

## Step 3 — Identify files changed by this feature

Get only files that are currently modified, staged, or untracked (these are exactly the files written during Phase 4 of the pipeline):

```bash
git -C "PROJECT_ROOT" status --porcelain
```

Parse the output:
- Include lines starting with `M`, `A`, `??`, ` M`, ` A` (modified, added, untracked)
- Exclude `.claude/memory/approvals/ACTIVE` — this is the marker file, not a feature file
- Extract the file paths into **CHANGED_FILES** list

If **CHANGED_FILES** is empty → stop:
```
⛔ No changed files found. Nothing to commit.
   Ensure the /feature pipeline ran to completion on this branch.
```

Print the list so the developer can verify:
```
Files to be committed:
  <file1>
  <file2>
  ...

Proceed with commit and push? (yes/no)
```

Wait for confirmation. If `no` → abort.

---

## Step 4 — Stage feature files only

Stage each file in **CHANGED_FILES** individually — never use `git add .` or `git add -A`:

```bash
git -C "PROJECT_ROOT" add <file1> <file2> ... <fileN>
```

Verify staged files match what was shown:
```bash
git -C "PROJECT_ROOT" diff --cached --name-only
```

---

## Step 5 — Commit

Get current branch name:
```bash
git -C "PROJECT_ROOT" branch --show-current
```
→ **CURRENT_BRANCH**

Compose commit message:
```
feat(<feature_slug>): <FEATURE_TITLE>

Spec: .claude/specs/<feature_slug>/<change_slug>.md
```

Run the commit:
```bash
git -C "PROJECT_ROOT" commit -m "feat(<feature_slug>): <FEATURE_TITLE>

Spec: .claude/specs/<feature_slug>/<change_slug>.md"
```

If commit fails → print the error output and stop.

---

## Step 6 — Push

```bash
git -C "PROJECT_ROOT" push origin <CURRENT_BRANCH>
```

Timeout: 60s.

If push fails with "no upstream" → retry with:
```bash
git -C "PROJECT_ROOT" push --set-upstream origin <CURRENT_BRANCH>
```

If push still fails → print the error and stop:
```
⛔ Push failed. Resolve the error above, then re-run /raise-pr.
```

---

## Step 7 — Archive approval marker

Move the ACTIVE marker to the audit trail so the repo re-locks:
```bash
mv "PROJECT_ROOT/.claude/memory/approvals/ACTIVE" \
   "PROJECT_ROOT/.claude/memory/approvals/<feature_slug>-<change_slug>.approved"
```

---

## Step 8 — Select PR target branch

Read the protected branches from `PROJECT_ROOT/.claude/CLAUDE.md`:
```bash
grep -A3 "protected_branches:" "PROJECT_ROOT/.claude/CLAUDE.md"
```

List all remote branches:
```bash
git -C "PROJECT_ROOT" branch -r --format="%(refname:short)" | sed 's/origin\///'
```

Present the list to the developer, with the first protected branch pre-selected as default:

```
Select the target branch for this PR:

  1. main  ← default
  2. develop
  3. release/v2
  ...

Enter a number or branch name [default: main]:
```

Wait for input. If the developer presses Enter with no input → use the default.
Store the chosen branch as **TARGET_BRANCH**.

---

## Step 8b — Select reviewers

Ask:
```
Who should review this PR?
Enter name(s) or email(s), comma-separated. Press Enter to skip:
```

If the developer presses Enter with no input → **REVIEWERS = []**, skip to Step 9.

Otherwise, for each entry the developer provides, resolve the identity via ADO API.
**Prefer email over name** — an email lookup only needs Graph read access and is
unambiguous; a name search needs the broader Identity search API and can return
multiple matches. Branch on whether the entry contains `@`:

Derive the identity search base URL from ORG_URL:
- `https://dev.azure.com/<org>` → `https://vssps.dev.azure.com/<org>`
- `https://<org>.visualstudio.com` → `https://vssps.visualstudio.com/<org>`

**Entry contains "@" (email) — try Graph user lookup first:**
```bash
curl -s -w "\nHTTP:%{http_code}" \
  -H "Authorization: Basic $B64" \
  "<VSSPS_URL>/_apis/graph/users?api-version=7.0-preview.1"
```
Filter the response `value` array client-side for `mailAddress` (or `principalName`)
matching `<input>` case-insensitively. A Graph user has `descriptor` (not a GUID `id`) —
use `descriptor` as the reviewer identifier in the PR payload (ADO accepts either
`id` or `descriptor` in the `reviewers` array).

If the Graph call itself returns HTTP 401/403 → treat as **auth failure** (see below),
do not fall back to the identities search for this entry.

**Entry has no "@" (plain name), or Graph lookup found zero matches for an email
entry** — use the identities search:
```bash
curl -s -w "\nHTTP:%{http_code}" \
  -H "Authorization: Basic $B64" \
  "<VSSPS_URL>/_apis/identities?searchFilter=General&filterValue=<name-or-email>&queryMembership=None&api-version=7.0"
```
From the response `value` array:
- Filter to entries where `isActive == true` and `isContainer == false`
- Each entry has `id` (GUID) and `providerDisplayName`

**Distinguish HTTP failure from zero-match — do not conflate them:**

- **HTTP status is 401 or 403** → this is an **auth/scope failure**, not "user not
  found." Print, and continue resolving the remaining entries (do not abort PR
  creation):
  ```
  ⚠ Reviewer lookup failed for "<input>" (HTTP <status>) — PAT missing Identity/Graph read scope.
    Reviewer NOT resolved. Add manually in ADO after the PR is created, or regenerate
    AZURE_DEVOPS_EXT_PAT with Identity (Read) / Graph (Read) scope and re-run /raise-pr.
  ```
  Record `{ input: "<input>", reason: "auth-failure" }` in **UNRESOLVED_REVIEWERS**.

- **HTTP status is 2xx and exactly one match** → store `{ id or descriptor, providerDisplayName }`
  in REVIEWERS list.

- **HTTP status is 2xx and multiple matches** → print a numbered list and ask the
  developer to pick:
  ```
  Multiple users matched "<input>":
    1. Jane Smith (jane.smith@example.com)
    2. Jane Doe (jane.doe@example.com)

  Enter a number:
  ```

- **HTTP status is 2xx and zero matches** → this is a genuine **no such user**. Print
  a warning and skip that entry:
  ```
  ⚠ No ADO user found for "<input>" — skipping. Check the name/email and add manually in ADO after the PR is created.
  ```
  Record `{ input: "<input>", reason: "no-match" }` in **UNRESOLVED_REVIEWERS**.

After resolving all entries → **REVIEWERS** = list of `{ id or descriptor, providerDisplayName }`
objects. **UNRESOLVED_REVIEWERS** = list of entries that need manual follow-up, each
tagged with why (`auth-failure` vs `no-match`) so the final summary (Step 9e) can
tell the developer exactly what to fix.

---

## Step 9 — Create PR in Azure DevOps

### 9a — Check prerequisites

**Check PAT:**
```bash
echo "${AZURE_DEVOPS_EXT_PAT:-NOT_SET}"
```
If `NOT_SET` or empty → skip to **Fallback** below.

**Read ADO config from CLAUDE.md:**
- `tracker.base_url` → **ORG_URL**
- `tracker.project`  → **ADO_PROJECT**

If either is `none` or missing → skip to **Fallback** below.

### 9b — Resolve repository name from git remote

```bash
git -C "PROJECT_ROOT" remote get-url origin
```

Parse **REPO_NAME** from the remote URL:
- `https://dev.azure.com/<org>/<project>/_git/<repo>` → last segment after `_git/`
- `https://<org>.visualstudio.com/<project>/_git/<repo>` → last segment after `_git/`
- `git@ssh.dev.azure.com:v3/<org>/<project>/<repo>` → last path segment

### 9c — Check for linked work item

Read `PROJECT_ROOT/.claude/memory/orchestrator_state.md` and look for an `ado_work_item.id`
field. If found → store as **WORK_ITEM_ID**. Otherwise → **WORK_ITEM_ID** = null.

### 9d — Build PR description

Compose the PR description from the spec:

```
## Summary
<2–3 sentence summary from the spec's ## Overview section>

## Changes
<bullet list of committed files with one-line description of each>

## Spec
.claude/specs/<feature_slug>/<change_slug>.md

## Quality gates
- [ ] Tests passed
- [ ] Security scan passed
- [ ] Lint passed
- [ ] Review gate passed

## Documentation Coverage (Quadrant Standard)
<If .claude/memory/doc_coverage_card.json exists, read and render the coverage matrix table here; otherwise print: "No doc coverage card generated">

## How to test
<acceptance criteria from the spec's ## Acceptance Criteria section, as checkboxes>
```

Store as **PR_DESCRIPTION**.

### 9e — Call the ADO REST API

Build the Basic auth header and POST the PR:

```bash
PAT="${AZURE_DEVOPS_EXT_PAT}"
B64=$(printf ":%s" "$PAT" | base64 | tr -d '\n')

curl -s -X POST \
  -H "Authorization: Basic $B64" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "feat(<feature_slug>): <FEATURE_TITLE>",
    "description": "<PR_DESCRIPTION — JSON-escaped>",
    "sourceRefName": "refs/heads/<CURRENT_BRANCH>",
    "targetRefName": "refs/heads/<TARGET_BRANCH>",
    "isDraft": false,
    "reviewers": [<for each reviewer: { "id": "<reviewer.id>" }>],
    "workItemRefs": [<for each linked item: { "id": "<id>" }>],
    "completionOptions": {
      "transitionWorkItems": true
    }
  }' \
  "${ORG_URL}/${ADO_PROJECT}/_apis/git/repositories/${REPO_NAME}/pullrequests?api-version=7.0"
```

`transitionWorkItems: true` instructs ADO to automatically move all linked work items to their
"Resolved" (done) state when a human completes (merges) this PR in ADO.

If **REVIEWERS** is empty, omit the `"reviewers"` field from the body entirely.
If **WORK_ITEM_ID** is null, omit `"workItemRefs"` from the body entirely.

Timeout: 30s.

**On success** (response contains `pullRequestId`):

Extract `pullRequestId` from the response JSON → **PR_ID**.

Print:
```
✔ Pull request created in Azure DevOps.

  Title:        feat(<feature_slug>): <FEATURE_TITLE>
  From:         <CURRENT_BRANCH>
  Into:         <TARGET_BRANCH>
  Reviewers:    <reviewer1.providerDisplayName>, ...  (or "none assigned")
  Linked items: #<WORK_ITEM_ID>  (or "none")
  PR URL:       <ORG_URL>/<ADO_PROJECT>/_git/<REPO_NAME>/pullrequest/<PR_ID>

  Work items are Active. They will be marked Resolved automatically
  when this PR is completed (merged) in ADO.
```

If **UNRESOLVED_REVIEWERS** is non-empty, append a follow-up block naming each entry
and its reason, so an auth failure is never mistaken for "no such user":
```
  ⚠ Reviewers not assigned — add manually in ADO:
    - "<input>" (<auth-failure: PAT missing Identity/Graph read scope | no-match: no ADO user found>)
```

**On failure** (non-2xx response or missing `pullRequestId`):

If the HTTP status is `401` or `403`, print specifically:
```
⚠ PR creation failed (HTTP <status>) — insufficient PAT scope.
  The token needs: Code (Read & Write)
  Current token may only have: Work Items (Read)

  Regenerate your PAT at: <ORG_URL>/_usersSettings/tokens
  Required scopes:
    - Work Items  → Read
    - Code        → Read & Write

  Update AZURE_DEVOPS_EXT_PAT (User environment variable), restart Claude Code,
  then re-run /raise-pr.
```

For any other failure, print the raw error. Then fall through to the **Fallback** below.

---

### Fallback — ADO PR creation unavailable

If AZURE_DEVOPS_EXT_PAT is not set, ADO config is missing, or the API call failed,
print the PR description for the developer to raise manually:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PR DESCRIPTION — paste this when opening the PR manually
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

<PR_DESCRIPTION>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Branch `<CURRENT_BRANCH>` has been pushed.
Target branch: <TARGET_BRANCH>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
