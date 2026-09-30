---
name: ado-work-item
description: >-
  Fetch a work item from Azure DevOps by ID. Handles three shapes:
  (A) Task — also fetches parent Story for AC context;
  (B) User Story with no child tasks — returns story fields directly;
  (C) User Story with child Tasks — fetches and returns the full task list
  so /feature can present a selection prompt.
  Requires AZURE_DEVOPS_EXT_PAT set as a User environment variable.
---

# Skill: ado-work-item

Fetch a work item by ID and enrich it with parent/child context so the
pipeline always has the right description and acceptance criteria regardless
of whether a Task or a Story ID was passed.

---

## Step 1 — Read ADO config from CLAUDE.md

Read `PROJECT_ROOT/.claude/CLAUDE.md` and extract from the `tracker:` block:
- `tracker.base_url` → **ORG_URL**
- `tracker.project`  → **ADO_PROJECT**

If either value is `none` or missing → stop:
```
⛔ Azure DevOps is not configured in .claude/CLAUDE.md.
   Run /start to complete ADO setup.
```

---

## Step 2 — Read PAT from environment

```bash
echo "${AZURE_DEVOPS_EXT_PAT:-NOT_SET}"
```

If set and non-empty → continue.

If NOT_SET or empty → stop:
```
⛔ AZURE_DEVOPS_EXT_PAT is not set — cannot fetch ADO work item #<WORK_ITEM_ID>.

Run /start to complete one-time ADO setup. The agent will ask for your token
and register it as a User environment variable automatically.
```

Do NOT attempt any other authentication strategy (no az CLI, no Bearer token, no fallback).

---

## Step 3 — Fetch the work item

Build the Base64 auth header. Use `$expand=all` to get both fields and relations
in one call:

```bash
PAT="${AZURE_DEVOPS_EXT_PAT}"
B64=$(printf ":%s" "$PAT" | base64 | tr -d '\n')

curl -s \
  -H "Authorization: Basic $B64" \
  -H "Content-Type: application/json" \
  "${ORG_URL}/${ADO_PROJECT}/_apis/wit/workitems/${WORK_ITEM_ID}?\$expand=all&api-version=7.0"
```

Timeout: 30s.

If curl exits non-zero or the response has a top-level `"message":` field → stop:
```
⛔ Failed to fetch work item #<WORK_ITEM_ID>.
   Check: ORG_URL correct, PAT scopes include Work Items (Read) + Code (Read & Write), item exists.
```

Store the response as **RAW_JSON**.

---

## Step 4 — Parse primary fields

Parse **RAW_JSON** directly in Claude context (no shell out to python/node).

Extract from `RAW_JSON.fields`:

| JSON path | Variable | Notes |
|---|---|---|
| `fields["System.Title"]` | **title** | Plain string |
| `fields["System.Description"]` | **description** | Strip HTML; null → `""` |
| `fields["Microsoft.VSTS.Common.AcceptanceCriteria"]` | **acceptance_criteria** | Strip HTML; null → `""` |
| `fields["System.WorkItemType"]` | **type** | `User Story`, `Task`, `Bug`, `Feature`, etc. |
| `fields["System.State"]` | **state** | `Active`, `New`, `Resolved`, etc. |
| `fields["System.AssignedTo"].displayName` | **assigned_to** | null → `"unassigned"` |
| `fields["Microsoft.VSTS.Scheduling.StoryPoints"]` | **story_points** | null → `"—"` |

Extract from `RAW_JSON.relations` (may be null or empty array):
- Entries where `rel == "System.LinkTypes.Hierarchy-Reverse"` → **PARENT_URLS** (there is at most one)
- Entries where `rel == "System.LinkTypes.Hierarchy-Forward"` → **CHILD_URLS** (zero or more)

For each URL, extract the work item ID as the last path segment (e.g. `.../workItems/9401` → `9401`).

**HTML stripping rule** — apply to `description` and `acceptance_criteria`:
- Remove all `<...>` tags
- `&nbsp;` → space · `&lt;` → `<` · `&gt;` → `>` · `&amp;` → `&`
- Collapse multiple blank lines into one

---

## Step 5 — If type is "Task": fetch parent Story for AC

**Only run this step if `type == "Task"` AND PARENT_URLS is non-empty.**

Extract **PARENT_ID** from the first PARENT_URL.

```bash
curl -s \
  -H "Authorization: Basic $B64" \
  "${ORG_URL}/${ADO_PROJECT}/_apis/wit/workitems/${PARENT_ID}?\$expand=fields&api-version=7.0"
```

Parse from response:
- `fields["System.Title"]` → **parent_title**
- `fields["Microsoft.VSTS.Common.AcceptanceCriteria"]` → **parent_ac** (strip HTML; null → `""`)
- `fields["System.WorkItemType"]` → **parent_type**

Store as **parent_story**:
```yaml
parent_story:
  id:                  <PARENT_ID>
  title:               <parent_title>
  type:                <parent_type>
  acceptance_criteria: <parent_ac>
  url:                 <ORG_URL>/<ADO_PROJECT>/_workitems/edit/<PARENT_ID>
```

If this step does not run (not a Task, or no parent) → **parent_story = null**.

---

## Step 6 — If type is "User Story" or "Feature": fetch child Tasks

**Only run this step if `type` is `"User Story"` or `"Feature"` AND CHILD_URLS is non-empty.**

Extract all child IDs from CHILD_URLS → **CHILD_IDS** (comma-separated).

Batch-fetch child items:
```bash
curl -s \
  -H "Authorization: Basic $B64" \
  "${ORG_URL}/${ADO_PROJECT}/_apis/wit/workitems?ids=${CHILD_IDS}&fields=System.Id,System.Title,System.WorkItemType,System.State,System.Description&api-version=7.0"
```

From the `value` array in the response, for each item:
- Parse: `id`, `fields["System.Title"]`, `fields["System.WorkItemType"]`, `fields["System.State"]`, `fields["System.Description"]` (strip HTML)
- **Keep only items where type == `"Task"`** — skip Bugs, Sub-Stories, etc.

Store as **child_tasks** list:
```yaml
child_tasks:
  - id:          <id>
    title:       <title>
    description: <description>
    state:       <state>
    url:         <ORG_URL>/<ADO_PROJECT>/_workitems/edit/<id>
```

If this step does not run → **child_tasks = []**.

---

## Step 7 — Return structured object

Return the following enriched object to the caller:

```yaml
work_item:
  id:                   <WORK_ITEM_ID>
  title:                <title>
  description:          <description>
  acceptance_criteria:  <acceptance_criteria>
  type:                 <type>
  state:                <state>
  assigned_to:          <assigned_to>
  story_points:         <story_points>
  url:                  <ORG_URL>/<ADO_PROJECT>/_workitems/edit/<WORK_ITEM_ID>
  parent_story:         <parent_story object or null>
  child_tasks:          <child_tasks list or []>
```

**Effective AC rule** (for the caller to apply):
- If `type == "Task"` and `parent_story.acceptance_criteria` is non-empty
  → the effective AC is `parent_story.acceptance_criteria`
- Otherwise → the effective AC is `work_item.acceptance_criteria`
