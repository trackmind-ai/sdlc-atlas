# /new-schema <resource>
Invoke schema-agent for the named resource.
Produces: SQLAlchemy ORM model in `app/models/<resource>.py`, Pydantic schemas (Create/Update/Response) in `app/schemas/<resource>.py`.
Spec-only — refuses fields not in approved spec.
Unspecced scope → /change-feature first.
