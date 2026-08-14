# /compose-up <services>

Invoke compose-agent with compose-service-pattern skill to author or review docker-compose.yml for the specced services.
Produces: health-gated depends_on, isolated networks, named volumes, secrets-based credentials, validated via `docker compose config`. Refuses services/ports outside the approved spec.
