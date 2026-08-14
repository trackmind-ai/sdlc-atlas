# Security Policy

sdlc-atlas is a platform whose agents **read your codebase, run shell commands, and write
files** — and whose pipeline is designed to gate exactly that. So this document is more than a
reporting address. Read **Scope** below before filing a report or relying on a passing pipeline
as a security guarantee; it states plainly what the platform does and does not protect against.

There are two trust boundaries here, and they run in opposite directions. Content the platform
*fetches* — work-item descriptions, attachments, linked pages, existing source files — is
**untrusted input** that agents must survive and surface, never obey. The platform's own
capability files — agent and skill definitions, `CLAUDE.md`, org policy — are **trusted input**
that agents are instructed to follow. Confusing the two is the fastest way to misread what a
finding means, and the boundary between them is where the interesting vulnerabilities live.

## Reporting a Vulnerability

**Please do not open a public GitHub issue for a security vulnerability.**

Report privately through either channel:

1. **GitHub Security Advisories** (preferred): open a draft advisory at
   `https://github.com/trackmind-ai/sdlc-atlas/security/advisories/new`. This keeps the report
   private until a fix is ready and gives us a structured place to coordinate disclosure.
2. **Email**: `oss@trackmind.com` — include enough detail to reproduce: the command or agent
   invoked, the repository state or work-item content that triggered it, and what you observed
   versus what you expected.

**What to expect:** an acknowledgment within 5 business days, and an initial assessment
(confirmed / not applicable / needs more information) within 10 business days. sdlc-atlas is a
young project without a dedicated security team — response times will tighten as it matures,
but we will not go silent on a real report.

Please give us a reasonable window to ship a fix before disclosing publicly. We will credit you
in the advisory unless you ask us not to.

## Scope

### What is a vulnerability here

- **An approval gate that can be bypassed.** Production-code edits require an approval marker
  at `.claude/memory/approvals/ACTIVE`, enforced by a `PreToolUse` hook. A way to make the
  platform write production code without that marker is a vulnerability.
- **A capability file modified without `/approve-proposal`.** Agent, skill, and command
  definitions are trusted input. A path that edits them outside the proposal flow escalates
  privilege for every subsequent pipeline run.
- **Injection that crosses the data/instruction boundary.** If text inside a work item,
  attachment, PR comment, or source file causes an agent to *act* on embedded instructions
  rather than report them, that is a vulnerability. Agents are required to treat fetched
  content as data.
- **Secret leakage.** A tracker token (`AZURE_DEVOPS_EXT_PAT`), API key, or credential written
  into a spec, log, state file, generated document, or PR body.
- **Sandbox escape via generated configuration.** A `settings.json` produced by the platform
  that grants permissions the profile did not intend — for example a `Bash(*)` allow rule
  reaching a project that asked for a restricted profile.
- **A quality gate reporting success without running.** Gates are evidence-bearing: a gate that
  writes PASS into `gate_results.md` without executing conveys a safety property that does not
  hold.

### What is expected behavior, not a vulnerability

- **Agents execute commands and modify files.** That is the product. Running a pipeline on a
  repository grants the platform the permissions in your `settings.json` and whatever the
  approving human authorizes. Wide permissions producing wide effects is configuration, not a
  defect.
- **A hostile repository or work item causing noisy or wrong output.** Untrusted input that
  produces a bad spec, an inaccurate review, or a failed gate is the input this platform is
  built to survive and report on. It becomes a vulnerability only when it crosses into the
  platform *acting* on embedded instructions (see above).
- **An LLM being wrong.** A missed bug, a false-positive security finding, or a hallucinated
  citation is a quality issue — file it as a normal bug. It is not a security report.
- **A passing pipeline is not a security audit.** The `security-agent` gate runs scanners and
  reviews a diff. It is a useful filter, not an assurance that the code is secure. Nothing here
  replaces a real security review of your own product.

## For users: reducing your own exposure

- **Review `settings.json` before running a pipeline** on a repository that matters. It is the
  actual permission boundary; the profiles are defaults, not guarantees.
- **Never commit real credentials to `.claude/`.** Tracker tokens belong in environment
  variables. `memory/` and `specs/` are committed by design and will be read by agents.
- **Keep the approval hook enabled.** `/approve-spec` and `/approve-proposal` exist so that a
  human decides when code and capabilities change. Disabling the hook removes the only
  mechanical check that they do.
- **Treat generated PRs as PRs.** Agents never push to protected branches; a human reviews,
  approves, and merges. Keep it that way.

## Supported versions

sdlc-atlas is pre-1.0. Security fixes land on `main` and in the next tagged release. There are
no backported patch branches yet; when the project adopts a release-support policy, it will be
documented here.

| Version | Supported |
|---------|-----------|
| `main`  | Yes |
| `0.1.x` | Yes |
| < 0.1   | No — pre-release, no fixes |
