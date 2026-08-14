# /build-dockerfile <service>

Invoke dockerfile-agent with multi-stage-dockerfile skill to author or review the Dockerfile for the specced service.
Produces: pinned-base, multi-stage, non-root, HEALTHCHECK-equipped Dockerfile validated via `docker build --check` and `hadolint`. Refuses secrets in layers or unspecced packages/stages.
