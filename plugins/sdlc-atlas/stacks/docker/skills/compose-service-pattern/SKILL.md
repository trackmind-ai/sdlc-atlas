---
name: compose-service-pattern
description: "Author a production-shaped docker-compose.yml: health-gated dependencies, isolated networks, named volumes, secrets."
when_to_use: "Defining or reviewing docker-compose.yml / docker-compose.override.yml for a multi-service application."
disable-model-invocation: false
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
model: sonnet
effort: medium
context: []
---

# Compose Service Pattern

1. One service per spec-approved component (app, db, cache, etc.) — no extra services.
2. `depends_on` uses `condition: service_healthy`, paired with a `healthcheck:` block on the depended-on service.
3. Split networks: `frontend` (public-facing) and `backend` (`internal: true`) — reference services by name, never hardcoded IPs.
4. Persistence via named `volumes:` — bind mounts (`.:/app`) allowed only in `docker-compose.override.yml` for dev hot-reload.
5. Credentials via `secrets:` block (file-based or external) — never plaintext in `environment:`.
6. Set `deploy.resources.limits` (cpus/memory) on every service for production compose files.
7. Set `restart_policy` (`on-failure`, capped `max_attempts`) for resilience.
8. Keep dev overrides (`target: development`, debug ports, `NODE_ENV=development`) out of the base file — override file only.
9. Validate: `docker compose config` must parse clean before handoff.

---

## Hard rules

- Never hardcode secrets/passwords in `environment:` — use `secrets:`.
- Never use `network_mode: host` — always custom bridge networks.
- Never add a service, port, or volume not present in the approved spec.
- Bind mounts never in production/base compose file.
