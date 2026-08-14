---
name: multi-stage-dockerfile
description: "Write or review a multi-stage Dockerfile with pinned base images, cache-friendly layer order, and a non-root runtime user."
when_to_use: "Creating a new Dockerfile, or reviewing/hardening an existing one for a service being containerized."
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

# Multi-Stage Dockerfile

1. Detect runtime/framework from project manifest (package.json, requirements.txt, *.csproj, go.mod).
2. Pin base image with explicit tag + variant (`node:20.11-alpine3.19`) — never `:latest`.
3. Stage `deps`: copy only dependency manifests, install deps (`npm ci`, `pip install --no-cache-dir`, `dotnet restore`).
4. Stage `build`: copy source after deps layer, run build/compile step.
5. Stage `runtime`: start fresh from minimal base (alpine/distroless/scratch); `COPY --from=build --chown=<user>:<group>` only the built artifacts + prod deps.
6. Create dedicated non-root user/group with explicit UID/GID; `USER <uid>` before `CMD`.
7. Use exec-form `CMD ["binary", "arg"]` / `ENTRYPOINT` — never shell form.
8. Add `HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD ...`.
9. `EXPOSE` only the ports the app actually listens on.
10. No secrets in `ENV`/`ARG`/layers — use `--mount=type=secret` for build-time secrets only.
11. Validate: `docker build --check .` then `hadolint Dockerfile`.

---

## Hard rules

- Never `FROM <image>:latest` in a committed Dockerfile.
- Never `COPY . .` before dependency install — breaks layer caching.
- Never ship the final stage running as root.
- Never bake secrets into any layer, including deleted-in-later-layer tricks (they persist in image history).
