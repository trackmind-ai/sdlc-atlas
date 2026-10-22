# Changelog

All notable changes to sdlc-atlas are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Pre-1.0, minor versions
may contain breaking changes; they will always be called out under **Changed**.

## [Unreleased]

### Changed
- Plugin README: added three example prompts and a troubleshooting section.
- The stack fetcher asks before every download. `stack_fetcher.py <stack>` now only prints the sources it would contact and a `NEEDS_CONFIRM` line, with no network request; the download needs `--confirm`, which `/start`, the orchestrator and `/fetch-stack` pass only after the developer says yes. Declining continues without that stack, and a failed fetch no longer stops the orchestrator.
- External tools and plugins are now optional everywhere. `/start`, `/setup`, the orchestrator, setup-agent, qa-agent, test-agent, sonar-agent and security-agent ask before installing caveman, Chrome DevTools MCP, Maestro MCP or a missing test/lint/security tool. If the developer says no, nothing is installed and the run continues. Previously `/start` and `/setup` stopped without caveman, `/start` stopped when QA tooling was declined or failed to install, and qa-agent stopped on a failed MCP check.
- A declined tool or declined QA tooling is recorded as `SKIPPED (declined)` in `gate_results.md` (QA via `qa_report.md` with `verdict: SKIPPED` and `declined_by: developer`; other tools via `.claude/memory/declined_tools.md`). `run-gates.sh` treats it as resolved, and the completion summary must say the check did not run. It is never recorded as a pass, and a static review is never presented as QA.
- Narrowed the project allow list: `npx` is limited to named tools instead of `npx *`, `claude mcp add` to the two QA servers, `pip install` to requirements files and bandit. The `project-permissions` Standard profile matches.
- A CAPTCHA, MFA or login wall during live QA no longer waits indefinitely: qa-agent asks the developer to complete it by hand and resume, or skip live QA (recorded as `SKIPPED (declined)`, UI not verified). The agent still never solves or bypasses the prompt itself.
- Before live QA starts (orchestrator Gate 4 and `/quality-check`), the developer is asked whether to run it or skip it. Skipping is recorded as `SKIPPED (declined)` with the UI marked not verified.

### Removed
- The second-editor target: its converter script under `platform/converters/`, the non-Claude `--target` / `--platform` values in `install.sh` and `setup-stacks.sh`, its generated project template, and the TARGET/LAYER_DIR indirection in `/start` and the platform agents. Only the Claude Code target remains; `--target X` / `--platform X` for anything but `claude` now fails with a clear message. The stack fetcher no longer pulls from that editor's rule collections.

### Added
- `tools/test-gates.sh`, a behaviour test for the declined-tool and declined-QA paths of `run-gates.sh`, run in CI.

## [0.1.1] — 2026-10-16

Directory-submission readiness.

### Added
- `plugins/sdlc-atlas/README.md` with a full disclosure of hooks, permission settings, installs and network access.
- `tools/test-approval-hook.sh`, a behaviour test for the edit-gate hooks, run in CI.

### Changed
- The plugin-level edit-gate hooks no longer block edits in projects that have not been set up with `/start`. They now switch on once a project has `.claude/memory/orchestrator_state.md` or the governance settings in `.claude/settings.json`. Previously an installed plugin blocked every code edit in every project.
- The orchestrator, setup agent and QA agent ask before installing caveman, Chrome DevTools MCP or Maestro MCP instead of installing silently.
- Pinned `chrome-devtools-mcp` (1.11.0), `create-next-app` (16.4.2), `create vite` (9.2.1) and the caveman installer (fixed commit) instead of `@latest` / `main`.

### Fixed
- `tools/verify-package.sh` (and so `make test`) failed 15 checks because it looked for the old flat `skills/<name>.md` layout.

## [0.1.0] — 2026-08-13

First public release, published under `trackmind-ai` as a Claude Code plugin.

### Added

- Four-layer capability model — platform, stack, organization, project — merging flat at
  runtime, with the more specific layer winning on a filename collision.
- 23 platform agents covering requirements, architecture, spec, bootstrap, test, security,
  review, QA, docs, release, incident, and retro.
- 43 commands and 42 shared skills.
- 10 supported stacks: `react`, `nextjs`, `angular`, `vue`, `node`, `nestjs`, `python`,
  `fastapi`, `postgresql`, `docker` — plus the stack-orchestrator, which generates a definition
  for any other stack on demand via `/fetch-stack`.
- Three service profiles (small, standard, enterprise) scaling pipeline ceremony to the work.
- Governance enforced mechanically rather than by convention: production-code edits require an
  approval marker, and capability files change only through `/approve-proposal`. Both are
  `PreToolUse` hooks.
- Quality gates in fixed order, with gates 1–3 (test, security, lint) running in parallel and
  the pipeline stopping on the first failure.

### Fixed

Found while preparing the release, all pre-existing:

- **Both governance hooks failed open.** The capability-file hook shelled out to `python3`,
  which on Windows is commonly a stub that exits 0 without running — so the hook silently
  permitted the edits it exists to block. The approval-marker hook read
  `$CLAUDE_TOOL_INPUT_FILE`, a variable Claude Code does not set, so its allowlist never matched.
  Both now parse the stdin payload and fail **closed** when they cannot.
- `finding-verification-gate.md` declared `name: threat-verification`, so the skill that
  `review-agent` and `security-agent` both load could never resolve — Claude Code matches
  skills by frontmatter name, not filename.
- Three commands dispatched agents that do not exist (`ux-agent`,
  `business-interviewer-agent`, `ux-interviewer-agent`), breaking `/ux-interview` and
  `/business-interview`.
- `init-project-layer.sh` recognised only `django`, `angular`, and `node`, and aborted on
  anything else — so 8 of the 10 shipped stacks could not produce a project layer. It now
  derives gate commands from each stack's own `STACK.md` and the routing table from its
  `agents/` directory, which also works for stacks added later.
- `write-project-claude.sh` accepted `--name` and ignored it, producing a `CLAUDE.md` titled
  after an internal scratch directory.
- `verify-package.sh` reported ~30 phantom failures (a regex that truncated hyphenated agent
  names) that masked real ones, called all 14 `settings.json` files invalid on Windows, and
  referenced a hardcoded internal project path.
- The editor converter script used `local … readonly`, shadowing the shell builtin.
- `setup-all.sh` never produced a project `CLAUDE.md`. The template ships without one (it is
  `/audit-project`'s job to generate the full version), and the stamping step was guarded by
  `[ -f ]`, so it silently did nothing and step 6 failed every run with "missing CLAUDE.md".
  It now seeds a minimal valid file whose gate commands come from the stack's own `STACK.md`.
- 21 stack agents across `react`, `nextjs`, `vue`, `node`, and `fastapi` were missing
  `tools`, `model`, `skills`, `permissionMode`, `maxTurns`, `effort`, and `isolation` in
  their frontmatter — an agent with no `tools` line gets no explicit tool grant. All 10
  supported stacks now pass `install.sh --doctor` with zero drift (91 files checked).
- `install.sh` advertised all 34 original stacks and defaulted `--init-layer` to `django`,
  which this package no longer ships, so a bare `--init-layer <name>` aborted.

### Security

- `SECURITY.md` now documents the real threat model: the two trust boundaries (fetched content
  is untrusted data; capability files are trusted input), what counts as a vulnerability, and
  what is expected behavior for a platform whose agents run commands by design.

[Unreleased]: https://github.com/trackmind-ai/sdlc-atlas/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/trackmind-ai/sdlc-atlas/releases/tag/v0.1.0
