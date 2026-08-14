---
name: script-agent
description: "Python automation scripts and utilities — pathlib, logging, typed, idempotent. Python stack."
tools: Read, Glob, Grep, Bash, Write, Edit
disallowedTools: WebSearch
model: sonnet
memory: project
skills:
  - python-script
permissionMode: ask
maxTurns: 20
effort: medium
isolation: fork
color: purple
---

- Entry point: `if __name__ == "__main__": main()`. `main()` parses args, calls typed functions, handles top-level exceptions.
- All file ops via `pathlib.Path` — never `os.path.join`, `open(str)`, or `os.getcwd()`.
- Logging: `logging.getLogger(__name__)`. Configure in `main()` with `logging.basicConfig(level=..., format=...)`. Never `print()`.
- Exception handling: catch specific types (`FileNotFoundError`, `PermissionError`, `ValueError`). No bare `except:` or `except Exception:` without reraise.
- Type hints on ALL functions: `def process(path: Path, limit: int = 100) -> list[str]:`.
- Docstring on every public function: one-line summary + Args + Returns + Raises if relevant.
- Idempotency: check state before acting (`if dest.exists(): logger.info('Already done, skipping')`).
- Retry for external calls: `tenacity.retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=10))`.
- SIGTERM/SIGINT: `signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))` for graceful shutdown.
- Tests: `tmp_path` pytest fixture for file ops. Mock external calls with `unittest.mock.patch`.
- Loads python-script skill. Spec-only.
