# Onboarding

## Developer path (recommended — no shell flags to memorize)

1. **Once per machine:** install platform layer (or use `setup.ps1` once).
2. **Open Claude Code** in your project folder (can be empty).
3. Run:

```
/start
```

`/start` shows a menu (new project / brownfield / resume / feature), asks **one question at a time**, runs setup internally, and hands off: **setup → architecture → bootstrap → feature** — you never run `setup-all.sh` flags yourself.

---

## Operator path (shell setup — optional)
One command does platform + project + stack (+ org) + .gitignore + doctor:

Windows (PowerShell, from the extracted package folder):
    .\setup.ps1 -Project "C:\dev\<repo>" -Stack fastapi
    .\setup.ps1 -Project "C:\dev\todo-api" -Stack node -Layer todo
    .\setup.ps1 -Project "C:\dev\acme-api" -Stack fastapi -Layer acme
    # add:  -Org "C:\dev\org-policy"   for enterprise
    # if blocked: powershell -ExecutionPolicy Bypass -File .\setup.ps1 ...

macOS/Linux/Git Bash:
    bash setup-all.sh --project /path/to/repo --stack fastapi [--org /path/to/org-policy]
    bash setup-all.sh --project /path/to/todo-api --stack node --layer todo

## Project layer only (no target repo yet)
Creates `projects/<name>/` from template if missing; reuses if it already exists:
    bash install.sh --init-layer todo --stack node [--profile standard]
    bash install.sh --list-layers

Then the ONLY manual step: open <repo>/.claude/CLAUDE.md, replace every [FILL IN],
and re-run the doctor line the script prints. Done.

## Manual path (what the script automates)

## Per machine (once)
    bash install.sh --platform
Installs the process layer to ~/.claude/.

## Per project
A) Existing repo on a known stack:
    bash install.sh --stack fastapi --project /path/to/repo
    bash install.sh --new-project /path/to/repo   # if no .claude/ yet — do this FIRST
    # then open .claude/CLAUDE.md and replace every [FILL IN]
B) Org-governed (enterprise): also
    bash install.sh --org /path/to/org-policy --project /path/to/repo
    # and set org_policy: in .claude/CLAUDE.md

## Version control
Inside .claude/, rename gitignore-template -> .gitignore. Commit specs/, proposals/,
and all capability files; orchestrator_state.md and reference/ stay local.
Specs are committed on purpose: they carry the WHY and the rejected alternatives
that git history cannot, and /change-feature's drift report needs them.

## Validate
    bash install.sh --doctor /path/to/repo
Fix every warning (unfilled placeholders, missing profile, nested agent folders).

## Brand-new (greenfield) project?
In Claude Code, run `/start` and choose **A**. It will guide architecture → bootstrap → first feature.

Or manually: `/architecture` → `/bootstrap` → `/feature`

## Package self-test (any time)
    bash tools/verify-package.sh   # 0 failures = package integrity verified

## First feature
Open Claude Code in the repo:
    /start                  → menu + guided handoffs (recommended)
    /feature #<work-item>   → interview → spec_1.md
    /approve-spec spec_1      → pipeline runs → gates
    /raise-pr                 → checklist; you raise the PR

## Troubleshooting
- "agent not found": check the file is FLAT in .claude/agents/ (no subfolders).
- Gate using wrong command: declare test/security/lint in project CLAUDE.md.
- Capability edit blocked: that's governance working — use /propose.
