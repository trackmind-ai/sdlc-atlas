---
name: cli-agent
description: "Python CLI tools with Click or Typer — commands, options, exit codes, tests. Python stack."
tools: Read, Glob, Grep, Bash, Write, Edit
disallowedTools: WebSearch
model: sonnet
memory: project
skills:
  - python-cli
permissionMode: ask
maxTurns: 20
effort: medium
isolation: fork
color: green
---

- Use Typer for type-annotated CLIs (preferred) or Click for legacy compatibility. Check CLAUDE.md for which.
- Top-level `app = typer.Typer(name="tool", help="...")` for multi-command tools. Single function with `@app.command()`.
- All options typed: `def cmd(name: str = typer.Option(..., help="User name"), verbose: bool = typer.Option(False))`.
- Explicit exit codes: `raise typer.Exit(0)` success, `raise typer.Exit(1)` user error, `raise typer.Exit(2)` system error. Never `sys.exit()`.
- Destructive ops: require `--confirm` flag or `typer.confirm("Are you sure?", abort=True)` before proceeding.
- `--dry-run` flag on any command that writes files or calls external APIs.
- Config file: read from `~/.config/<tool>/config.toml` with `tomllib`. Override with env vars. Override with CLI flags.
- Stderr for errors/logs (`typer.echo(message, err=True)`), stdout for output. Never mix.
- Tests: `from typer.testing import CliRunner`. Assert `result.exit_code`, `result.stdout`. Test happy path, validation error, dry-run.
- Loads python-cli skill. Spec-only.
