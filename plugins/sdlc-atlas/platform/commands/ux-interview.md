---
name: ux-interview
description: >-
  Run the UX interview standalone — outside the forge pipeline.
  Conducts the UX requirements interview and then immediately runs
  ux-research-agent to update ux_brief.md. Useful when you want to define
  or redo the UX layer independently of the full forge pipeline.
---

# /ux-interview

Runs the full UX pipeline: interview → design artifacts.
Writes `.claude/memory/ux_brief.md` (and appends design addendum).

Prerequisite: `business_brief.md` must exist (run `/business-interview` first
if it does not).

---

## Step 0 — Establish roots

```bash
pwd
echo "$HOME/.claude"
```

PROJECT_ROOT = first output
PLATFORM_HOME = second output

---

## Step 1 — Check prerequisite: business brief

```bash
ls "PROJECT_ROOT/.claude/memory/business_brief.md" 2>/dev/null && echo "EXISTS" || echo "MISSING"
```

If MISSING → print:
```
⛔ business_brief.md not found.

The UX interview needs the business brief to avoid re-asking what is
already known about the project. Run /business-interview first, then
re-run /ux-interview.
```
STOP.

If EXISTS → continue to Step 2.

---

## Step 2 — Check for existing UX brief and artifacts

```bash
ls "PROJECT_ROOT/.claude/memory/ux_brief.md" 2>/dev/null && echo "BRIEF_EXISTS" || echo "BRIEF_MISSING"
ls "PROJECT_ROOT/.claude/memory/ux_brief.md" 2>/dev/null && grep -q "UX Design Spec Addendum" "PROJECT_ROOT/.claude/memory/ux_brief.md" && echo "ARTIFACTS_EXISTS" || echo "ARTIFACTS_MISSING"
```

If BOTH exist → print:
```
A UX brief and UX artifacts already exist for this project.

  a) View the existing brief and design specs
  b) Redo the full UX pipeline (interview + design)
  c) Redo only the UX design (keep existing brief, regenerate specs)
  d) Cancel

Choose (a / b / c / d):
```

Wait for reply:
- `a` → run `cat "PROJECT_ROOT/.claude/memory/ux_brief.md"` and print contents. STOP.
- `b` → continue to Step 3 (full redo)
- `c` → skip Step 3, go directly to Step 4 (ux-research-agent only)
- `d` → print `Cancelled.` and STOP.

If BRIEF_MISSING → continue to Step 3.
If BRIEF_EXISTS but ARTIFACTS_MISSING → ask:
```
A UX brief exists but no design specs. Run ux-research-agent to generate design specs from the existing brief? (yes / redo-interview)
```
- `yes` → skip to Step 4
- `redo-interview` → continue to Step 3

---

## Step 3 — Run UX interview

Print `→ ux-research-agent` then dispatch via Task:

```
Agent: ux-research-agent
Inputs:
  project_root: PROJECT_ROOT
  platform_home: PLATFORM_HOME

Task:
  Read business_brief.md and context_bundle.md first.
  Extract known context — do not re-ask anything already there.
  Determine information gaps (GOAL-1 through GOAL-8).
  Run the dynamic interview — one question at a time, formulated from context.
  Write ux_brief.md to PROJECT_ROOT/.claude/memory/ux_brief.md.
  Return: questions asked + path taken (A or B).
```

Wait for ux-research-agent to return.
Print: `✔ UX brief complete — generating design artifacts...`

---

## Step 4 — Run UX agent

Print `→ ux-research-agent` then dispatch via Task:

```
Agent: ux-research-agent
Inputs:
  project_root: PROJECT_ROOT
  platform_home: PLATFORM_HOME

Task:
  Read business_brief.md, ux_brief.md, and the platform default template.
  Resolve design tokens (Path A: apply customisations to default template;
  Path B: parse custom design system + handle gaps).
  Derive: screen inventory, user flows, component map, navigation structure.
  Present one validation summary to the user and apply adjustments.
  Append design addendum to PROJECT_ROOT/.claude/memory/ux_brief.md.
  Return: screen count, flow count, custom component count.
```

Wait for ux-research-agent to return.

---

## Step 5 — Confirm and advise

After ux-research-agent returns, print:

```
✔ UX pipeline complete

  Brief:     PROJECT_ROOT/.claude/memory/ux_brief.md (including Design Addendum)

These files will be used automatically by:
  • forge-agent Phase 4  (architecture — reads frontend complexity + compliance)
  • forge-agent Phase 5  (bootstrap — installs component library + CSS variables)
  • forge-agent Phase 6  (decomposition — maps screens to feature batches)
  • spec-agent           (knows which screens + components each feature owns)

Next steps:
  /forge         — start or continue the full build pipeline
  /architecture  — run architecture design using the UX brief design specs
```
