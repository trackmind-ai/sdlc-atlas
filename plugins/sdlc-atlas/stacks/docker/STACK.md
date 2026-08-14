# Stack: Docker (L1 — containerization)
Installs into a project's `.claude/` via `install.sh --stack docker --project <path>`.
Project files win any filename collision. Declare `stack: docker` in project CLAUDE.md (used alongside any app stack — Django, FastAPI, Node, .NET, etc.).
Provides: dockerfile-agent, compose-agent, image-security-agent, build-optimization-agent + skills (multi-stage-dockerfile, compose-service-pattern, image-size-audit, docker-bootstrap).
Defaults (project may override): build check `docker build --check` / `hadolint Dockerfile`, security `docker scout cves` / `trivy image`, lint `hadolint Dockerfile`.
