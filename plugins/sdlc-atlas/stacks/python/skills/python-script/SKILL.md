---
name: python-script
description: "Python script implementation checklist — pathlib, logging, typed, idempotent."
---

1. `def main() -> None:` entry point. `if __name__ == "__main__": main()`. No module-level side effects.
2. Args: Typer or argparse. Never `sys.argv[1]` directly. `argparse.ArgumentParser(description=__doc__)`.
3. Logging setup in `main()`: `logging.basicConfig(level=logging.DEBUG if verbose else logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")`.
4. Module logger: `logger = logging.getLogger(__name__)`. Use `logger.info/warning/error` — never `print()`.
5. All paths as `pathlib.Path`. `path.exists()`, `path.read_text()`, `path.write_text()`, `path.mkdir(parents=True, exist_ok=True)`.
6. Specific exceptions: `except FileNotFoundError:`, `except PermissionError:`, `except ValueError:`. No bare `except:`.
7. Type hints on all functions: `def process(src: Path, dest: Path, limit: int = 100) -> list[str]:`.
8. Docstrings: `"""Read source file, apply limit, write results to dest. Returns list of processed items."""`.
9. Idempotency: `if dest.exists(): logger.info("Already processed, skipping %s", dest); return`.
10. Retry external calls: `@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=10))` from `tenacity`.
11. SIGTERM handler: `signal.signal(signal.SIGTERM, lambda sig, frame: (logger.info("SIGTERM received"), sys.exit(0)))`.
12. Temp files: `with tempfile.NamedTemporaryFile(dir=dest.parent, delete=False, suffix='.tmp') as f: ...; Path(f.name).rename(dest)`.
13. Tests: `pytest` with `tmp_path`. Mock external calls: `mock.patch('module.external_call', return_value=...)`.
14. Config file: `tomllib.loads(config_path.read_text())` for `pyproject.toml` or dedicated config. Validate with Pydantic.
15. Graceful errors: top-level `try/except` in `main()` with `logger.error("Fatal: %s", err, exc_info=True); sys.exit(2)`.
