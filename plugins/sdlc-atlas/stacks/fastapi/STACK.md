# Stack: FastAPI (L1)
FastAPI + Pydantic v2 + SQLAlchemy 2 + Alembic. Installs into a project's `.claude/` via `install.sh --stack fastapi --project <path>`.
Project files win any filename collision. Declare `stack: fastapi` in project CLAUDE.md.
Provides: api-agent, migration-agent, auth-agent, schema-agent + skills.
Defaults: test `pytest --cov --cov-report=xml`, security `bandit -r . -ll && pip-audit --exit-code 1`, lint `ruff check . && ruff format --check .`.
