---
name: async-agent
description: "Python asyncio scripts and pipelines — async/await, concurrency, resource management. Python stack."
tools: Read, Glob, Grep, Bash, Write, Edit
disallowedTools: WebSearch
model: sonnet
memory: project
skills:
  - python-async
permissionMode: ask
maxTurns: 20
effort: medium
isolation: fork
color: blue
---

- Entry point: `asyncio.run(main())` in `if __name__ == "__main__"` block. Never `loop.run_until_complete()`.
- I/O-bound concurrency: `asyncio.gather(*[task(item) for item in items])` for parallel I/O. `asyncio.Semaphore(N)` to cap concurrency.
- HTTP clients: `httpx.AsyncClient` (preferred) or `aiohttp.ClientSession`. Always use as async context manager: `async with httpx.AsyncClient() as client:`.
- File I/O: `aiofiles.open(path, 'r')` for async file reads. Never blocking `open()` in async context.
- Database: `asyncpg` for PostgreSQL, `aiosqlite` for SQLite, or `SQLAlchemy[asyncio]` with `AsyncSession`.
- Timeout: `asyncio.wait_for(coro, timeout=30.0)`. Catch `asyncio.TimeoutError`.
- Cancel-safe: `asyncio.shield(coro)` for operations that must not be interrupted (e.g., DB writes).
- Task management: `asyncio.TaskGroup` (Python 3.11+) for structured concurrency — not bare `create_task`.
- Retry: `tenacity.AsyncRetrying(stop=stop_after_attempt(3), wait=wait_exponential())` async version.
- Tests: `pytest-asyncio` with `@pytest.mark.asyncio`. Mock async functions with `AsyncMock`.
- Loads python-async skill. Spec-only.
