---
name: ado-setup
description: >-
  One-time Azure DevOps integration setup. Reads or asks for org URL and
  project name (writes them to CLAUDE.md), checks that AZURE_DEVOPS_EXT_PAT
  is set as a User environment variable (never asks for the value), installs
  the ado-work-item skill, and verifies the connection. Called by /start.
---

# Skill: ado-setup

One-time setup. After this skill completes, `/feature <id>` works automatically.
The PAT must be set by the user as a Windows User environment variable before
running this skill — the agent checks for it but never asks for its value.

---

## Step 1 — Read or collect ADO org URL and project name

Read `PROJECT_ROOT/.claude/CLAUDE.md` and extract from the `tracker:` block:
- `tracker.base_url` → **ORG_URL**
- `tracker.project`  → **ADO_PROJECT**

**For any value that is `none`, empty, or missing — ask ONE question per missing value:**

If ORG_URL is missing:
```
[ado-setup] What is your Azure DevOps organization URL?
e.g. https://dev.azure.com/myorg  or  https://myorg.visualstudio.com
```

If ADO_PROJECT is missing:
```
[ado-setup] What is your Azure DevOps project name?
e.g. Acme
```

After collecting each value, **write it into CLAUDE.md immediately** using the Edit tool:
```yaml
tracker:
  type:     azure-devops
  project:  <ADO_PROJECT>
  base_url: <ORG_URL>
```

Both values are now permanently in the project config — no further prompt on any
future run.

---

## Step 2 — Check that AZURE_DEVOPS_EXT_PAT is set

```bash
echo "${AZURE_DEVOPS_EXT_PAT:-NOT_SET}"
```

**If set and non-empty** → continue to Step 3.

**If NOT_SET or empty** → print exactly:
```
⛔ AZURE_DEVOPS_EXT_PAT is not set.

Set it as a User environment variable on your machine:

  Windows:
    1. Press Win+S and search "Edit the system environment variables"
    2. Click "Environment Variables…"
    3. Under "User variables" click New
    4. Variable name:  AZURE_DEVOPS_EXT_PAT
       Variable value: <your Personal Access Token>
    5. Click OK on all dialogs

  To create a PAT (if you don't have one):
    1. Open <ORG_URL> → top-right avatar → Personal Access Tokens
    2. New Token → scopes: Work Items (Read), Code (Read & Write) → copy the token

After setting the variable, restart Claude Code and run /start again.
```

**Stop.** Do NOT ask the user to provide or paste the token value. Do NOT attempt
any other authentication strategy.

---

## Step 3 — Install ado-work-item skill into the project

Copy the skill so `/feature` can invoke it via the Skill tool:

```bash
mkdir -p "PROJECT_ROOT/.claude/skills"
cp "PLATFORM_HOME/skills/ado-work-item.md" "PROJECT_ROOT/.claude/skills/ado-work-item.md"
echo "✔ ado-work-item skill installed"
```

If the copy fails → print a warning and continue (skill will fall back to inline execution).

---

## Step 4 — Verify the connection

Test via REST API directly — no az CLI needed:

```bash
PAT="<PAT from Step 2>"
B64=$(printf ":%s" "$PAT" | base64 | tr -d '\n')

curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Basic $B64" \
  "${ORG_URL}/${ADO_PROJECT}/_apis/wit/workitems/1?api-version=7.0"
```

| HTTP status | Meaning | Action |
|---|---|---|
| `200` or `404` | Auth succeeded (404 = item 1 doesn't exist, that's fine) | Print success, continue |
| `401` or `403` | PAT incorrect or expired | Print error below, stop |
| anything else | Network / URL problem | Print error below, stop |

**On success (200 or 404):**
```
✔ Azure DevOps connected successfully.
  Org:     <ORG_URL>
  Project: <ADO_PROJECT>
  PAT:     AZURE_DEVOPS_EXT_PAT (User environment variable) ✔

You can now run: /feature <work-item-id>
```

**On 401 / 403:**
```
⚠ Authentication failed (HTTP <status>).
  - PAT may be incorrect or expired — regenerate it at <ORG_URL>
  - PAT scopes must include: Work Items (Read), Code (Read & Write)
  Update the AZURE_DEVOPS_EXT_PAT User environment variable, restart Claude Code,
  then run /start again.
```
Stop.

**On any other status:**
```
⚠ Connection test returned HTTP <status>.
  - Check that ORG_URL is correct: <ORG_URL>
  - Check your internet connection
  Update CLAUDE.md tracker.base_url if needed, then run /start again.
```
Stop.
