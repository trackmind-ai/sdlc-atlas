# /optimize-build <service>

Invoke build-optimization-agent with docker-bootstrap skill to tune build context, layer caching, and image size for the specced service.
Reviews `.dockerignore` completeness, instruction ordering, cache mounts, multi-arch buildx setup; reports layer-by-layer size deltas via `docker history --no-trunc`. Never adds a stage or cache mount outside the current spec.
