---
name: image-size-audit
description: "Scan a built image for CVEs and audit layer/size bloat, recommending minimal-base or layer-consolidation fixes."
when_to_use: "Before merging a Dockerfile/compose change, or on-demand security/size review of an existing image."
disable-model-invocation: false
user-invocable: false
allowed-tools:
  - Read
  - Bash
model: sonnet
effort: medium
context: []
---

# Image Size & CVE Audit

1. Build (or use existing) image; run `docker scout cves <image>` and/or `trivy image <image>` (read-only scan).
2. Flag CRITICAL/HIGH CVEs with no documented mitigation — block on these.
3. Run `docker history --no-trunc <image>` — identify layers with unexpected size jumps (uncleaned caches, unnecessary copied files).
4. Check base image: alpine/distroless/scratch used where feasible; flag generic/large bases (`ubuntu:latest`, full `debian`) lacking justification.
5. Check for leftover build tools, package manager caches, or `.git`/test files copied into the final stage.
6. Recommend fix: swap base image, add cache-clean to same `RUN` layer, extend `.dockerignore`, or split stage further.
7. Report as: `image | size | CVEs (crit/high/med) | recommendation`.

---

## Hard rules

- Never silently pass a CRITICAL CVE — surface it even if fix is deferred.
- Read-only — never modify Dockerfile/compose directly; hand findings back to dockerfile-agent/build-optimization-agent.
- Always name the specific layer/instruction causing bloat, not just "image is large."
