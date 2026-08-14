---
name: business-interview
description: >-
  Run the business interview standalone — outside the forge pipeline.
  Useful when you want to define project scope and context before running
  /start, or to redo the interview on an existing project.
  Writes .claude/memory/business_brief.md in the project folder.
---

# /business-interview

Conduct a structured business interview for this project and produce a
validated `business_brief.md`. Can be run before `/start`, after `/start`,
or to refresh an existing brief.

---

## Step 0 — Establish roots

```bash
pwd
echo "$HOME/.claude"
```

- PROJECT_ROOT = first output
- PLATFORM_HOME = second output

---

## Step 1 — Check for project setup

```bash
ls "PROJECT_ROOT/.claude/CLAUDE.md" 2>/dev/null && echo "EXISTS" || echo "MISSING"
```

**If MISSING:**

Print:
```
⚠ No .claude/CLAUDE.md found — project is not set up yet.

You can still run the business interview now. When you later run /start,
the brief will be picked up automatically and the discovery interview
in forge-agent will be skipped.

Proceeding without project context — answers from context_bundle.md
will not be available.
```

Set: KNOWN_NAME = "", KNOWN_DESC = "", KNOWN_TYPE = "", KNOWN_STACK = ""
Skip to Step 3.

**If EXISTS:** continue to Step 2.

---

## Step 2 — Read known context

```bash
cat "PROJECT_ROOT/.claude/memory/context_bundle.md" 2>/dev/null || echo "EMPTY"
```

Extract from context_bundle.md:
- KNOWN_NAME, KNOWN_DESC, KNOWN_TYPE, KNOWN_STACK

If EMPTY → set all to empty string.

---

## Step 3 — Check for existing brief

```bash
ls "PROJECT_ROOT/.claude/memory/business_brief.md" 2>/dev/null && echo "EXISTS" || echo "MISSING"
```

If EXISTS → print:
```
A business_brief.md already exists for this project.

  a) View the existing brief
  b) Redo the interview (overwrites existing brief)
  c) Cancel

Choose (a / b / c):
```

Wait for reply:
- `a` → run: `cat "PROJECT_ROOT/.claude/memory/business_brief.md"` and print contents, then STOP.
- `b` → continue to Step 4.
- `c` → print `Cancelled.` and STOP.

If MISSING → continue to Step 4.

---

## Step 4 — Launch product-strategy-agent

Print `→ product-strategy-agent` then dispatch via Task:

```
Agent: product-strategy-agent
Inputs:
  project_root: PROJECT_ROOT
  platform_home: PLATFORM_HOME
  known_name: KNOWN_NAME
  known_desc: KNOWN_DESC
  known_type: KNOWN_TYPE
  known_stack: KNOWN_STACK

Task:
  Run the full business interview pipeline:
    Step 0: Establish roots + read context_bundle
    Step 1: Derive domain and stack probes from known context
    Step 2: Check for existing brief (redo already confirmed — skip the keep/redo prompt)
    Step 3: Run all 6 interview categories one question at a time
    Step 4: Synthesis and validation with user
    Step 5: Write business_brief.md
    Step 6: Return summary
  Return: path to written brief + number of questions asked.
```

---

## Step 5 — Confirm and advise

After product-strategy-agent returns, print:

```
✔ Business brief written: PROJECT_ROOT/.claude/memory/business_brief.md

This brief will be used automatically by:
  • forge-agent Phase 1  (skips the discovery interview)
  • architecture-agent   (reads constraints and compliance requirements)
  • spec-agent           (reads MVP scope for each feature)

Next steps:
  /forge              — start building the project (if setup is done)
  /start              — set up and build (if project is not set up yet)
```
