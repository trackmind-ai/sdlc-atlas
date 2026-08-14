---
name: python-pipeline
description: "Python data pipeline implementation checklist — Pydantic, chunking, idempotency."
---

1. Pydantic v2 input schema: `class InputRow(BaseModel): id: int; name: str; value: float | None = None`. `model_config = ConfigDict(strict=True)`.
2. Pydantic v2 output schema: separate model from input — transformations make them different.
3. Validate full input at entry: `[InputRow.model_validate(row) for row in load_data()]`. Collect `ValidationError`s, fail fast.
4. Chunked processing: `for chunk in pd.read_csv(path, chunksize=10_000):` or `itertools.batched(data, 1000)` (Python 3.12+).
5. Stage logging: `logger.info("Extract: %d rows", len(rows))`. `logger.info("Transform: %d valid, %d skipped", n_valid, n_skip)`. `logger.info("Load: %d written", n_written)`.
6. Null handling: check `Optional` fields before use. Log skipped rows: `logger.warning("Row %d: missing %s, skipped", i, field)`.
7. Atomic write: `tmp = output_path.with_suffix('.tmp'); write(tmp); tmp.rename(output_path)`.
8. Checkpoint: `json.dump({'last_id': last_id}, open('checkpoint.json', 'w'))`. On restart: `last_id = json.load(open('checkpoint.json')).get('last_id', 0)`.
9. Idempotency: filter already-processed: `rows = [r for r in rows if r.id > last_checkpoint_id]`.
10. Error recovery per record: wrap in `try/except ValidationError as e: skipped.append((row, str(e)))`. Summarise skipped at end.
11. Schema evolution: `alias_generator` or `model_validator` for backward-compatible field renames.
12. Large output: stream to file with `json.JSONEncoder` or `csv.DictWriter` — never accumulate in memory.
13. Metrics: emit `{"stage": "transform", "in": N, "out": M, "skipped": K, "duration_s": T}` as structured log for monitoring.
14. Tests: `tmp_path` fixture. Small fixture CSV/JSON. Assert output shape, row count, checkpoint created.
15. `--dry-run`: validate and report what would be written without writing.
