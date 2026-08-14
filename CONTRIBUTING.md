# Contributing to sdlc-atlas

Thanks for considering a contribution. This document explains **how** to contribute and —
more importantly — **why the contribution model has tiers**, because that shape is deliberate
rather than bureaucracy. Read the "why this lane is maintainer-gated" notes once; they will
save you being surprised later that an agent PR gets more scrutiny than a docs PR.

The short version: **the capability definitions are the product.** An agent file is not
documentation *about* how the pipeline behaves — it *is* the behavior, read verbatim into a
model's context on every run, with permission to execute commands and write files in a user's
repository. That makes agent and skill text both the most valuable thing you can contribute and
the most sensitive, and it is why the lanes below are not equally open.

## Local setup

*(This is the developer setup, for working on sdlc-atlas itself. Just want to use it? See the
[README](README.md) Install section, which needs none of this.)*

```bash
git clone https://github.com/trackmind-ai/sdlc-atlas.git
cd sdlc-atlas
make check          # or: .\tasks.ps1 check   (Windows)
```

`make check` runs manifest validation, agent/skill reference validation, shellcheck, and the
package self-test. It should be clean before you open a PR — CI runs the same checks.

To try your changes in a real Claude Code session, register this checkout as a local plugin:

```text
/plugin marketplace add /absolute/path/to/sdlc-atlas
/plugin install sdlc-atlas@trackmind-sdlc-atlas-dev
```

The dev marketplace is deliberately named `trackmind-sdlc-atlas-dev`, never `trackmind` —
Claude Code registers one marketplace per name per user, so a clashing name would silently
replace the published Trackmind catalog.

## The four lanes

### Lane A — Agents and skills (`platform/agents/`, `platform/skills/`) — maintainer-reviewed

**Why gated:** these files are executable instructions. An agent's frontmatter grants tools
(`Bash`, `Write`, `Edit`) and a `permissionMode`; its prose decides when code gets written to
someone's repository. A subtle wording change can make an agent skip a gate, widen its own
permissions, or act on untrusted input. Review here is about blast radius, not gatekeeping.

Checklist for an agent or skill PR:

1. **Frontmatter is complete and minimal.** `name`, `description`, `tools`. The `name` must
   match the filename — Claude Code resolves skills by frontmatter `name`, and these drifting
   apart already made one skill silently unloadable for two agents.
2. **Tools are the narrowest set that works.** Adding `Bash` or `Write` to an agent that
   previously only read files needs a sentence in the PR explaining why.
3. **Every skill you reference exists.** `make check` verifies this.
4. **Fetched content stays data.** If your agent reads work items, attachments, pages, or
   source files, it must surface embedded instructions rather than obey them. This is a hard
   platform rule, not a style preference.
5. **No new gate bypass.** If your change lets the pipeline reach code-writing without an
   approval marker, it will be rejected regardless of how convenient it is.

### Lane B — Stacks (`platform/../stacks/<name>/`) — lighter review

**Why lighter:** a stack is scoped. It describes one technology's conventions and commands, and
a mistake affects only projects that opted into it.

1. Follow the existing shape: `STACK.md`, `agents/<name>/AGENT.md`, `skills/<name>/SKILL.md`,
   `settings.json`. The self-test enforces this layout.
2. `STACK.md` must carry the defaults line — `test`, `security`, `lint` commands in backticks.
   `init-project-layer.sh` reads it to generate a project's gate commands, so a stack without
   it produces a project with no test command.
3. Prefer widely-used tooling over your personal preference; a stack is a default for strangers.

**Note on scope:** v0.1.0 ships 10 supported stacks. New stacks are welcome, but adding one is
a maintenance commitment across that ecosystem's churn — expect a conversation about who keeps
it current before it merges.

### Lane C — Scripts and CI (`install.sh`, `tools/`, `scripts/`, `.github/`) — maintainer-reviewed

**Why gated:** `install.sh` is the first thing a new user runs, and it writes to their
`~/.claude/`. CI changes affect what gets to skip review.

1. `shellcheck --severity=warning` must be clean. Two checks are suppressed repo-wide in
   `.shellcheckrc`, with reasons; don't add more without one.
2. Shell scripts must be POSIX-portable across Linux, macOS, and Git Bash on Windows. In
   particular **do not call `python3`** — on Windows it is often a stub that exits 0 without
   running, which has already caused one silent hook failure and one bogus validation pass.
   Resolve an interpreter, or avoid needing one.
3. New scripts get LF endings (enforced by `.gitattributes`) and an SPDX header.

### Lane D — Documentation, issue templates, examples — open

Typos, unclear explanations, better examples, corrected docs: open a PR directly. No design
discussion needed. This is the best first contribution, and reporting where the docs misled you
is genuinely valuable.

## Reporting bugs

Open an issue with: what you ran (command and agent), what happened, what you expected, and
your OS plus Claude Code version. For pipeline problems, `.claude/memory/orchestrator_state.md`
and `gate_results.md` are the two most useful files to attach.

**Security issues do not go in the issue tracker** — see [SECURITY.md](SECURITY.md).

## Pull requests

- **One logical change per PR.** A restructure plus a behavior change in one diff is hard to
  review and harder to revert.
- **Explain the why, not just the what.** The diff shows what changed.
- **Say what you verified.** "Ran `make check`, and confirmed the hook blocks an unapproved
  edit" carries far more weight than "should work".
- **Keep `make check` green.** CI runs the same commands, so a red PR is a round trip.
- Commits should be readable; we don't enforce a commit-message format.

## Code of Conduct

Participation is covered by the [Code of Conduct](CODE_OF_CONDUCT.md). Reports go to
`oss@trackmind.com`.

## Licensing

sdlc-atlas is MIT licensed. By contributing, you agree your contribution is licensed under the
same terms, and that you have the right to submit it — if you wrote it for an employer, make
sure you are permitted to contribute it.
