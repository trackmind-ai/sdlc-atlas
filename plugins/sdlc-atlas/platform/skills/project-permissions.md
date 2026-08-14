---
name: project-permissions
description: >-
  Configure project tool permissions ONCE during setup instead of prompting
  repeatedly. Maps a chosen permission profile to .claude/settings.json allow/deny
  so Read/Write/Edit/Bash for normal pipeline work do not re-prompt. Loaded by
  setup-agent.
---
# Project permissions (set once)

Ask the developer ONE question at setup, then write the result into
`PROJECT_ROOT/.claude/settings.json` so routine actions stop re-prompting.

## Setup question

```
N. How much autonomy should agents have for THIS project?
   Na) Guided    — ask before any write/edit/command (most prompts) 
   Nb) Standard  — auto-allow safe reads, tests, lint, git status/add/commit,
                   stack build commands; ask for installs, pushes, deletes (Recommended)
   Nc) Autonomous — auto-allow all build/test/lint/install/git except destructive
                   (force-push, rm -rf, prod deploy); ask only for those
   Nd) Decide Later → defaults to Standard; change anytime in settings.json
```

## Mapping to settings.json

Merge (union) these into the project `permissions` block. NEVER loosen the platform
deny-list; only add allows up to the chosen level.

### Guided
```
allow:  ["Read(*)", "Grep(*)", "Glob(*)", "Bash(git status)", "Bash(git diff*)"]
```

### Standard (recommended)
```
allow: [
  "Read(*)", "Grep(*)", "Glob(*)",
  "Bash(git status)", "Bash(git diff*)", "Bash(git log*)", "Bash(git add*)", "Bash(git commit*)",
  "Bash(git branch*)", "Bash(git checkout -b*)",
  "Bash(mkdir*)", "Bash(cp *)",
  "<test_cmd prefix>*", "<lint_cmd prefix>*",
  "Bash(npm test*)", "Bash(npm run*)", "Bash(pytest*)", "Bash(ruff*)", "Bash(ng *)", "Bash(npx *)"
]
```

### Autonomous
```
allow: Standard + ["Bash(npm install*)", "Bash(pip install*)", "Bash(npm ci*)", "Bash(poetry *)", "Bash(docker build*)"]
```

## Always-deny (all levels — never override)
```
deny: ["Bash(git push --force*)", "Bash(rm -rf /*)", "Bash(rm -rf ~*)",
       "Edit(.env*)", "Edit(**/secrets*)", "Edit(.claude/proposals/*.approved.md)"]
```

## Rules

- Write the chosen level to `knowledge.md` (`permissions_profile:`) and the bundle.
- Replace `<test_cmd prefix>` / `<lint_cmd prefix>` with the real commands the
  developer gave (e.g. `Bash(pytest*)`), so gate runs never re-prompt.
- This is set once. The developer can re-run `/setup`-style edits or hand-edit
  `settings.json` later. Do not ask per-action when an allow rule already covers it.
