# /dockerize <service>

Invoke build-optimization-agent with docker-bootstrap skill to add first-time Docker support for the specced service.
Produces: multi-stage Dockerfile, `.dockerignore`, base `docker-compose.yml` if dependencies exist. Spec-only — refuses services not in the approved spec. Unspecced service → /change-feature first.
