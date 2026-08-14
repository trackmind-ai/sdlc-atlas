---
name: feature
description: "Start the full sdlc-atlas pipeline for a new feature."
---

# /feature <work-item-id | description>

## Step 0a — Resolve work item from Azure DevOps (if ID provided)

**Detect whether the argument is an ADO work item ID:**

- If `$ARGUMENTS` matches `^#?[0-9]+$` (bare number or `#NNN`) → **ADO_MODE = true**
- Otherwise → **ADO_MODE = false** — skip this step entirely and use `$ARGUMENTS` as the feature description

**If ADO_MODE = true:**

1. Strip the leading `#` if present → **WORK_ITEM_ID**

2. **Guard: check PAT is set before anything else:**
   ```bash
   echo "${AZURE_DEVOPS_EXT_PAT:-NOT_SET}"
   ```
   If the output is `NOT_SET` or empty → **stop immediately** with:
   ```
   ⛔ AZURE_DEVOPS_EXT_PAT is not set — cannot fetch ADO work item #<WORK_ITEM_ID>.

   Run /start to complete one-time ADO setup. The agent will ask for your token
   and register it as a User environment variable automatically.
   Then restart Claude Code and retry /feature <id>.
   ```
   Do NOT attempt any other fetch strategy — no az CLI, no Bearer token, no fallback.

3. **Guard: check ado-work-item skill is registered.**
   The `ado-work-item` skill must be available via the Skill tool. If the skill is not registered:
   ```
   ⛔ ado-work-item skill is not installed in this project.
   Run /start and choose to connect Azure DevOps — it installs the skill automatically.
   ```
   Do NOT attempt any inline fetch. Stop.

4. Apply the `ado-work-item` skill with **WORK_ITEM_ID** and **PROJECT_ROOT**

5. On success, branch on the returned `work_item.type` and `work_item.child_tasks`:

---

### Case A — type is "Task"

Print:
```
✔ Fetched Task #<id> · <state>
  Title:       <title>
  Assigned to: <assigned_to>
  Part of:     Story #<parent_story.id>: <parent_story.title>  (or "no parent story found")
  <url>
```

Set:
- **FEATURE_DESCRIPTION** = `<title>: <description>` (task's own description)
- **EFFECTIVE_AC** = `parent_story.acceptance_criteria` if non-empty, else `work_item.acceptance_criteria`
- **LINKED_ITEM_ID** = `work_item.id`

Store in runtime context:
```yaml
runtime_context:
  ado_work_item:
    id:                  <task id>
    title:               <task title>
    description:         <task description>
    acceptance_criteria: <EFFECTIVE_AC>
    type:                Task
    state:               <state>
    url:                 <url>
    parent_story:        <parent_story object or null>
    selected_tasks:      []
```

---

### Case B — type is "User Story" or "Feature", child_tasks is empty

Print:
```
✔ Fetched Story #<id> · <state>
  Title:        <title>
  Assigned to:  <assigned_to> · Story Points: <story_points>
  No child tasks found — building the full story.
  <url>
```

Set:
- **FEATURE_DESCRIPTION** = `<title>: <description>`
- **EFFECTIVE_AC** = `work_item.acceptance_criteria`
- **LINKED_ITEM_ID** = `work_item.id`

Store in runtime context:
```yaml
runtime_context:
  ado_work_item:
    id:                  <story id>
    title:               <story title>
    description:         <story description>
    acceptance_criteria: <EFFECTIVE_AC>
    type:                <type>
    state:               <state>
    url:                 <url>
    parent_story:        null
    selected_tasks:      []
```

---

### Case C — type is "User Story" or "Feature", child_tasks is non-empty

Print:
```
✔ Fetched Story #<id> · <state>
  Title:        <title>
  Assigned to:  <assigned_to> · Story Points: <story_points>
  <url>

  This story has <N> tasks:
    1. #<id> · <state>  — <title>
    2. #<id> · <state>  — <title>
    3. #<id> · <state>  — <title>

Build all tasks or select one? (all / 1 / 2 / 3 ...):
```

Wait for developer input.

**If developer answers `all`:**
- **FEATURE_DESCRIPTION** = `<story title>: <story description>` + each task title as a bullet
- **EFFECTIVE_AC** = `work_item.acceptance_criteria`
- **LINKED_ITEM_ID** = `work_item.id`
- Store all tasks in `selected_tasks`

**If developer answers a number N:**
- Resolve the Nth task from the list → **SELECTED_TASK**
- **FEATURE_DESCRIPTION** = `<selected_task.title>: <selected_task.description>`
- **EFFECTIVE_AC** = `work_item.acceptance_criteria` (AC always comes from the story)
- **LINKED_ITEM_ID** = `selected_task.id`
- Store only the selected task in `selected_tasks`

Store in runtime context (for both sub-cases):
```yaml
runtime_context:
  ado_work_item:
    id:                  <story id>
    title:               <story title>
    description:         <story description>
    acceptance_criteria: <EFFECTIVE_AC>
    type:                <type>
    state:               <state>
    url:                 <url>
    parent_story:        null
    selected_tasks:      <all child_tasks | [selected_task]>
```

---

6. Use **FEATURE_DESCRIPTION** as the effective description for the rest of the pipeline.

**Note:** The `ado_work_item` block (including `acceptance_criteria` and `selected_tasks`) is
passed to the orchestrator in Step 3. Spec-agent pre-populates `## Acceptance Criteria` directly
from `acceptance_criteria` and uses `selected_tasks` to scope implementation to the chosen task(s).

---

## Step 0b — Mark work items Active in ADO

**Only run if ADO_MODE = true.**

Determine which work items to update based on the case resolved in Step 0a:

| Case | Items to mark Active |
|---|---|
| A — Task | The Task + its parent Story (if `parent_story` is not null) |
| B — Story, no tasks | The Story only |
| C — all tasks | The Story + every task in `child_tasks` |
| C — one task selected | The Story + the selected task only |

Skip any item whose current `state` is already `Active`, `In Progress`, or `Resolved` — do not downgrade.

For each item to update, run:

```bash
PAT="${AZURE_DEVOPS_EXT_PAT}"
B64=$(printf ":%s" "$PAT" | base64 | tr -d '\n')

curl -s -X PATCH \
  -H "Authorization: Basic $B64" \
  -H "Content-Type: application/json-patch+json" \
  -d '[{"op":"add","path":"/fields/System.State","value":"Active"}]' \
  "${ORG_URL}/${ADO_PROJECT}/_apis/wit/workitems/<ITEM_ID>?api-version=7.0"
```

On success for each item → print: `✔ #<id> <title> → Active`

On failure for any item → print a warning and continue — state update failure must NOT stop the pipeline:
```
⚠ Could not mark #<id> Active — pipeline continues. Update manually in ADO if needed.
```

---

## Step 0 — Select target branch

**Purpose:** Allow the developer to select or create a Git branch before the pipeline begins reading project files.

Execute the following steps:

1. **List all branches** (local + remote):
   ```bash
   git branch -a
   ```

2. **Parse and deduplicate the branch list:**
   - Extract local branches (no prefix)
   - Extract remote branches from `remotes/origin/*` that are NOT already tracked locally
   - Build a combined numbered list

3. **Display the numbered list to the developer:**
   ```
   Select a branch to work on:

   1. main
   2. develop
   3. feature/auth
   4. origin/release/v2
   5. (Create a new branch)

   Enter a number or type a branch name (or type 'cancel'):
   ```

4. **Validate input:**
   - If number: verify it is within range `[1, N]`
   - If typed branch name: validate against Git naming rules `^[a-zA-Z0-9._/-]+$`
   - If `cancel`, `quit`, `exit`, or `q`: **abort the /feature command entirely**
   - If invalid: re-prompt (max 3 attempts)
   - After 3 failed attempts: abort with error message

5. **If developer selects option N (Create a new branch):**
   - Prompt for new branch name: `Enter new branch name:`
   - Validate name against regex `^[a-zA-Z0-9._/-]+$`
   - **Display the same numbered branch list** (excluding the "Create a new branch" option) and ask:
     ```
     Select a base branch to branch from:

     1. main
     2. develop
     3. feature/auth
     4. origin/release/v2

     Enter a number or type a branch name:
     ```
   - Validate base branch input (same rules as step 4; re-prompt up to 3 times on invalid input)
   - Confirm creation: `Create branch '<name>' from '<base>'? (yes/no)`
   - On `yes`: execute `git checkout -b <name> <base>` with 30s timeout
   - On `no`: return to step 3

6. **If typed branch name does not exist locally or remotely:**
   - Offer to create it: `Branch '<name>' not found. Create it? (yes/no)`
   - On `yes`:
     - **Display the same numbered branch list** and ask:
       ```
       Select a base branch to branch from:

       1. main
       2. develop
       3. feature/auth
       4. origin/release/v2

       Enter a number or type a branch name:
       ```
     - Validate base branch input (re-prompt up to 3 times on invalid input)
     - Execute `git checkout -b <name> <base>` with 30s timeout
   - On `no`: return to step 3

7. **Before switching branches, check for uncommitted changes:**
   ```bash
   git status --porcelain
   ```
   (10s timeout)

8. **If uncommitted changes exist:**
   - Get current branch: `git branch --show-current`
   - Auto-stash with timestamped label:
     ```bash
     git stash push -u -m "claude:<source-branch>:<YYYY-MM-DD_HH-MM-SS>"
     ```
   - Example: `git stash push -u -m "claude:develop:2026-06-22_14-30-12"`
   - Timeout: 30s

9. **Execute branch checkout:**
   - **Local branch:** `git checkout <branch>` with 30s timeout
   - **Remote branch:** `git fetch origin && git checkout -b <branch> origin/<branch>` with 60s fetch + 30s checkout timeout

10. **On checkout failure:**
    - If error mentions "Your local changes" or "would be overwritten":
      - Offer: `Stash and retry? (yes/no)`
      - On `yes`: attempt stash (step 8) + retry checkout
      - On `no`: abort with message: `Branch switch cancelled. Run /feature again when ready.`
    - If other error: display error message and abort

11. **On successful switch, auto-pop the stash if one was created in step 8:**
    ```bash
    git stash pop
    ```
    (30s timeout)

12. **If stash pop encounters conflicts:**
    - Surface as warning, do NOT block pipeline:
      ```
      Warning: Stash restored with conflicts in <files>. Resolve manually.
      ```

13. **Store selected branch in runtime context:**
    ```yaml
    runtime_context:
      selected_branch: <branch>
    ```
    **Note:** This is NOT written to `orchestrator_state.md` — it is passed only to the orchestrator invocation in Step 3.

14. **Proceed to Step 1.**

---

## Step 1 — Establish roots

Run immediately:
```bash
pwd
echo "$HOME/.claude"
```

- First output  → **PROJECT_ROOT** — every file written goes here
- Second output → **PLATFORM_HOME** — all agents, skills, stacks live here

Never search for the sdlc-atlas repo folder. It is not needed at runtime.

## Step 2 — Check for project setup

```bash
ls "PROJECT_ROOT/.claude/CLAUDE.md" 2>/dev/null && echo "EXISTS" || echo "MISSING"
```

**If MISSING** — the orchestrator runs the full setup sequence (Step 2 in orchestrator.md):
ask 8 questions, check stacks exist in PLATFORM_HOME, copy files to project layer, write CLAUDE.md.

**If EXISTS** — skip to Step 3.

## Step 3 — Run the pipeline

Hand off to the orchestrator agent with:
- Feature description: **FEATURE_DESCRIPTION** (resolved in Step 0a — either the ADO title+description or the raw `$ARGUMENTS`)
- ado_work_item: the full `ado_work_item` object from runtime context (or `null` if ADO_MODE = false)
- PROJECT_ROOT: exact path from Step 1
- PLATFORM_HOME: exact path from Step 1
- All file writes go to PROJECT_ROOT/.claude/
