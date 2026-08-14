# /new-endpoint <resource>
Invoke controller-agent with new-endpoint skill for the specced resource only.
Produces: Create/Update DTOs (class-validator), controller route methods delegating to the service, Supertest tests.
Spec-only — refuses fields or endpoints not in the approved spec.
Unspecced scope → /change-feature first.
