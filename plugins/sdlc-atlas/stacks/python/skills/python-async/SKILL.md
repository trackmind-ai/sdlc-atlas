---
name: python-async
description: "Python asyncio implementation checklist — async/await, concurrency limits, resource cleanup."
---

1. Entry: `asyncio.run(main())` in `if __name__ == "__main__":`. Never `get_event_loop().run_until_complete()`.
2. Concurrent I/O: `results = await asyncio.gather(*[fetch(url) for url in urls], return_exceptions=True)`. Filter `isinstance(r, Exception)`.
3. Concurrency limit: `sem = asyncio.Semaphore(10)`. `async with sem: result = await fetch(url)`.
4. HTTP: `async with httpx.AsyncClient(timeout=30.0) as client: resp = await client.get(url); resp.raise_for_status()`.
5. File I/O: `async with aiofiles.open(path, 'r') as f: content = await f.read()`.
6. TaskGroup (3.11+): `async with asyncio.TaskGroup() as tg: t1 = tg.create_task(coro1()); t2 = tg.create_task(coro2())`. Auto-cancels on error.
7. Timeout: `try: result = await asyncio.wait_for(coro, timeout=30.0) except asyncio.TimeoutError: logger.warning("Timed out")`.
8. Retry: `from tenacity import AsyncRetrying, stop_after_attempt, wait_exponential; async for attempt in AsyncRetrying(...): with attempt: result = await risky()`.
9. Cancel-safe writes: `await asyncio.shield(db_write(data))` — prevents cancellation mid-write.
10. Cleanup: `async with asyncio.TaskGroup()` or `try/finally` with `await client.aclose()`. Never leave unclosed sessions.
11. Avoid blocking in async: use `asyncio.to_thread(blocking_fn, *args)` for CPU-bound or blocking I/O operations.
12. Queue for producer/consumer: `q = asyncio.Queue(maxsize=100)`. Producer: `await q.put(item)`. Consumer: `item = await q.get(); q.task_done()`.
13. Tests: `@pytest.mark.asyncio` with `pytest-asyncio`. `AsyncMock` for async dependencies. `anyio` for framework-agnostic tests.
14. Structured logging: `logger.info("Fetched %s items", len(results), extra={"url": url, "duration_ms": elapsed})`.
15. `asyncio.run(main(), debug=True)` in development to catch coroutine leaks and slow callbacks.
