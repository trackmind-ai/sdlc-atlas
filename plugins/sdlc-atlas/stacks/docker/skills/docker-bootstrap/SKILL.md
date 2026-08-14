---
name: docker-bootstrap
description: "First-time Docker setup for a project: Dockerfile, .dockerignore, base compose skeleton, build/lint commands."
when_to_use: "Adding Docker support to a project with no existing Dockerfile/compose files."
disable-model-invocation: false
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Bash
model: sonnet
effort: medium
context: []
---

# Docker Bootstrap

1. Detect app stack from project manifest (package.json/requirements.txt/*.csproj/go.mod/Cargo.toml).
2. Write multi-stage `Dockerfile` per multi-stage-dockerfile skill, matched to detected framework's build/run commands.
3. Write `.dockerignore`: `.git`, dependency dirs (node_modules/venv/bin/obj), `.env*`, `*.md`, test/log files.
4. If the app has dependencies (DB/cache), write minimal `docker-compose.yml` per compose-service-pattern skill.
5. Wire build/lint commands: `docker build --check .`, `hadolint Dockerfile`.
6. Smoke test: `docker build -t <project>:bootstrap .` must succeed; `docker compose config` must parse if compose file added.
7. Report layout written + commands verified green.

---

## Hard rules

- Never bootstrap without a `.dockerignore` — always paired with the Dockerfile.
- Never commit `.env` or secret files into build context — verify `.dockerignore` excludes them.
- Bootstrap is complete only when `docker build --check` and (if present) `docker compose config` both pass.
