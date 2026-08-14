# /new-endpoint <resource>
Invoke api-agent with fastapi-endpoint skill for the specced resource only.
Produces: Pydantic schemas, service function, APIRouter route with typed response_model, pytest tests.
Spec-only — refuses fields or endpoints not in approved spec.
Unspecced scope → /change-feature first.
