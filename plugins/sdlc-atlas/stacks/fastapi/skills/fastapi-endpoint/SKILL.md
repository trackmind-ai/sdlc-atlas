---
name: fastapi-endpoint
description: FastAPI Pydantic schema → service → router → test checklist.
---
# FastAPI Endpoint Procedure

1. Schemas: `<Resource>Create(BaseModel)`, `<Resource>Update(BaseModel)`, `<Resource>Response(BaseModel)` — never share across operations.
2. All fields typed explicitly; use `Annotated[str, Field(min_length=1, max_length=255)]` style constraints.
3. `model_config = ConfigDict(from_attributes=True)` on response schemas for ORM → Pydantic coercion.
4. Service function: `async def create_<resource>(db: AsyncSession, payload: <Resource>Create) -> <Resource>` in `app/services/<resource>.py`.
5. Route handler: thin — call service, return response schema. No business logic in handler.
6. `response_model=<Resource>Response` declared on every route — no naked dict returns.
7. Status codes: `201` for POST, `200` for GET/PUT, `204` for DELETE. Use `status_code=` explicitly.
8. `HTTPException(status_code=404, detail="<Resource> not found")` — not custom dicts.
9. Dependency injection: `db: AsyncSession = Depends(get_db)`, `current_user: User = Depends(get_current_user)`.
10. Query params: declare as typed function params with `Query(...)` for validation/docs.
11. Pagination: use `skip: int = Query(0, ge=0)` + `limit: int = Query(20, ge=1, le=100)` — never unbounded queries.
12. Test 201/200 with response shape, 401 unauthenticated, 403 forbidden, 404 not-found, 422 invalid payload.
13. `pytest.mark.asyncio` + `httpx.AsyncClient(app=app, base_url="http://test")` for all route tests.
