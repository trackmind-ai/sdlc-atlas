# Changelog

All notable changes to sdlc-atlas are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Pre-1.0, minor versions
may contain breaking changes; they will always be called out under **Changed**.

## [Unreleased]

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
- `cursor.sh` used `local … readonly`, shadowing the shell builtin.
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
