# Stack: Python (L1)
Installs into a project's `.claude/` via `install.sh --stack python --project <path>`.
Project files win any filename collision. Declare `stack: python` in project CLAUDE.md.
Provides: cli-agent, pipeline-agent, script-agent, async-agent + skills.
Defaults (project may override): test `pytest --cov --cov-report=xml`, security `bandit -r . -ll && pip-audit --exit-code 1`, lint `ruff check . && ruff format --check . && mypy .`.
