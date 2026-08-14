---
name: fastapi-bootstrap
description: FastAPI project scaffold checklist — deps, layout, async DB, CI.
---
# FastAPI Bootstrap Procedure

1. `pip install fastapi uvicorn[standard] sqlalchemy[asyncio] asyncpg alembic pydantic-settings python-jose[cryptography] passlib[bcrypt] httpx pytest pytest-asyncio pytest-cov ruff bandit pip-audit` — pin ALL versions in `requirements.txt` and `requirements-dev.txt`.
2. Layout:
   ```
   app/
     main.py          # FastAPI() app, router includes, lifespan
     config.py        # pydantic-settings Settings class
     database.py      # AsyncEngine, AsyncSession, get_db dependency
     models/          # SQLAlchemy ORM models
     schemas/         # Pydantic request/response schemas
     routers/         # APIRouter per resource
     services/        # business logic
     dependencies/    # shared Depends (auth, pagination)
   alembic/
   tests/
   ```
3. `app/config.py`: `class Settings(BaseSettings)` — all secrets from env. Singleton via `lru_cache`.
4. `app/database.py`: `create_async_engine(DATABASE_URL)`, `AsyncSession`, `get_db` async generator.
5. `alembic init alembic`; set `sqlalchemy.url` from env in `alembic/env.py`; configure `target_metadata`.
6. `pytest.ini` or `pyproject.toml`: `asyncio_mode = auto`, `addopts = --cov --cov-report=xml`.
7. `ruff.toml`: `select = ["E","W","F","I","UP","ASYNC"]`, `line-length = 120`.
8. One smoke test: `GET /health` returns `{"status": "ok"}` with 200 — must pass before handing to spec-agent.
9. CI: install → ruff → pytest --cov → bandit → pip-audit on every PR.
10. `Makefile` targets: `make test`, `make lint`, `make migrate`, `make run`, `make dev`.
