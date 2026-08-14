<!-- SPDX-FileCopyrightText: 2026 Trackmind -->
<!-- SPDX-License-Identifier: MIT -->

## What and why

<!-- The diff shows what changed. Explain why, and what problem this solves. -->

## Lane

<!-- See CONTRIBUTING.md. Lanes A and C get deeper review; this is not a hurdle, just routing. -->

- [ ] **A** — agents / skills / commands (executable instructions with tool grants)
- [ ] **B** — a stack
- [ ] **C** — installers, tooling, or CI
- [ ] **D** — documentation

## How you verified this

<!-- "Ran make check" plus what you actually exercised. Be specific: "confirmed the hook
     blocks an unapproved edit to src/" carries far more weight than "should work". -->

- [ ] `make check` is clean (or `.\tasks.ps1 check` on Windows)

## Checklist

- [ ] One logical change — no restructure bundled with a behavior change
- [ ] Docs updated if behavior changed
- [ ] `CHANGELOG.md` updated under `## [Unreleased]` for anything user-visible

<!-- Delete the section below if it does not apply. -->

## Governance impact (Lane A and C)

- [ ] Does **not** let the pipeline write production code without an approval marker
- [ ] Does **not** modify capability files outside `/approve-proposal`
- [ ] Any widened `tools` list or `permissionMode` is justified above
- [ ] Fetched content (work items, attachments, source files) is still treated as data, never
      as instructions to follow
- [ ] No new `python3` dependency in a shell script or hook — it resolves to a non-functional
      stub on many Windows machines, which has already caused a hook to fail open
