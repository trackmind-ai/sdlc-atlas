---
name: python-cli
description: "Python CLI implementation checklist — Click/Typer, options, exit codes, tests."
---

1. `app = typer.Typer(name="tool", help="One-sentence description.", add_completion=False)`.
2. Every command has a docstring: Typer uses it as `--help` text.
3. Typed options: `name: str = typer.Option(..., "--name", "-n", help="...")`. `...` = required.
4. Boolean flags: `verbose: bool = typer.Option(False, "--verbose", "-v", help="Enable debug output")`.
5. Enum options: `format: OutputFormat = typer.Option(OutputFormat.json)` where `OutputFormat` is `StrEnum`.
6. Destructive ops: `typer.confirm(f"Delete {path}?", abort=True)` or `--confirm` flag.
7. `--dry-run`: log what would happen, return exit 0 without side effects.
8. Config: `tomllib.loads(Path("~/.config/tool/config.toml").expanduser().read_text())` if exists, overridden by env vars, overridden by CLI args.
9. Stderr for progress/errors: `typer.echo(message, err=True)`. Stdout for machine-readable output only.
10. Exit codes: `raise typer.Exit(0)` success, `raise typer.Exit(1)` user/input error, `raise typer.Exit(2)` runtime error.
11. Tests: `runner = CliRunner(); result = runner.invoke(app, ["--name", "test"])`. Assert `result.exit_code == 0`.
12. Test error paths: missing required arg, invalid enum, dry-run output.
13. Rich output (optional): `from rich.console import Console; console = Console()`. Use `console.print(table)` for structured output.
14. Sub-commands: `@app.command("create")`, `@app.command("delete")`. Group under `app.add_typer(sub_app, name="user")`.
15. Version: `@app.callback(invoke_without_command=True)` + `typer.Option(None, "--version", callback=version_callback)`.
