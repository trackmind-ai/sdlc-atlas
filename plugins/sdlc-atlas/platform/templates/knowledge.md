<!--
  knowledge.md — project-specific living document (L3)
  ─────────────────────────────────────────────────────────────────────
  OWNERSHIP & LIFECYCLE
    - Written by /audit-project on first setup → PROJECT_ROOT/.claude/knowledge.md
    - Updated by orchestrator after every /feature pipeline completes
    - Not overwritten by /audit-project re-runs (safe to edit manually)
    - Lives for the lifetime of the project

  WHY THIS FILE EXISTS
    CLAUDE.md is a lean, stable platform/stack config file (regenerable).
    This file owns everything project-specific:
      - Custom agents, skills, commands (L3 layer)
      - Routing rules for domain-specific tasks
      - Team config (tech leads, org policy links)
      - Built-features registry (exhaustive knowledge of what exists)
    
    The orchestrator reads both files at startup to compose the full capability stack.

  BUILT FEATURES SECTION
    Every entry § Built features must be exhaustive, not summary.
    A one-liner is a documentation failure — causes next /feature to
    re-implement what already exists. Minimum required per entry:
      - What it does (2–4 sentences for someone new to the codebase)
      - Key files with line anchors and roles
      - Data models (name, file:line, fields, relationships)
      - API endpoints (method, path, auth, description)
      - Background tasks / workers (if any)
      - Key decisions (what was chosen + why alternative rejected)
      - Tests (file, count, coverage)
      - Dependencies & integrations

  MAINTENANCE RULE
    Remove/update facts as they become obvious from code.
    Add facts when they would remain hidden even after reading every file.
-->

# knowledge.md — {{PROJECT_NAME}}

> Written by /audit-project on {{GENERATED_DATE}}
> Updated by the orchestrator after every /feature pipeline.
> CLAUDE.md § 4.4, 5.3, 5.4 (project routing), 6.3, 7, 11, 12, 14 are owned here.

---

## Uninferable facts

<!-- Inclusion test: would a developer who read every file still get this wrong?
     [nav]        where things live, when non-obvious
     [constraint] external rules invisible in code
     [correction] fixes to plausible-but-wrong inferences
     Keep each item terse. Remove items when they become obvious from the code. -->

{{KNOWLEDGE_FACTS}}

---

## Project commands (L3)

<!-- Commands specific to this project, discovered in .claude/commands/.
     Added when /approve-proposal approves a new command. -->

{{PROJECT_COMMANDS_TABLE}}

---

## Project domain agents (L3)

<!-- Agents specific to this project — not stack or platform agents.
     Skill-first rule: extend an existing skill before creating a new agent.
     Added by the orchestrator when a feature introduces a new domain agent. -->

{{PROJECT_AGENTS_TABLE}}

---

## Project routing

<!-- YAML routing entries for project domain agents only.
     Platform + stack routing lives in CLAUDE.md § 5.4. -->

```yaml
project_routing:
{{PROJECT_ROUTING_YAML}}
```

---

## Project skills (L3)

<!-- Skills specific to this codebase — domain procedures, business rules,
     integration patterns not covered by stack-layer skills.
     Added by spec-agent gap analysis or /approve-proposal. -->

{{PROJECT_SKILLS_TABLE}}

---

## Tech leads  <!-- [standard][enterprise] -->

```yaml
tech_leads:
{{TECH_LEADS_LIST}}
```

---

## Org policy  <!-- [enterprise] -->

```yaml
org_policy:
  repo:   {{ORG_POLICY_REPO}}
  branch: {{ORG_POLICY_BRANCH}}
  file:   {{ORG_POLICY_FILE}}
```

---

## Built features

<!-- One subsection per shipped feature. /onboard pre-fills from source code.
     The orchestrator appends a new subsection after each /feature pipeline.

     REQUIRED FIELDS PER ENTRY (one-liners are rejected):
       - What it does        2–4 sentences for someone new to the codebase
       - Key files           file path + line anchor + role
       - Data models         model name, file:line, key fields and relationships
       - API endpoints       method, path, auth, description
       - Background tasks    name, file:line, purpose, retry policy (omit if none)
       - Key decisions       what was chosen + why the alternative was rejected
       - Tests               file path, count, what is covered
       - Dependencies        external services, libraries, or sibling features

     SPEC ID RULE:
       Use the actual spec_N id if a spec file exists.
       Use "inferred" for features found in source code with no spec file.
-->

{{BUILT_FEATURES_ENTRIES}}
