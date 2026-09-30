---
name: live-qa
description: >-
  Live UI quality assurance: health-score rubric (Console/Links/Visual/Functional/UX/Perf/Content/A11y),
  WTF-likelihood self-stop, fix-count hard cap, diff-aware/full/quick modes. Chrome DevTools MCP
  (web) and Maestro MCP (mobile) are the only automation backends — no Playwright, no raw CDP-over-Bash.
scope: platform
requirement: FRONTEND_QA
---

# Live QA

**Browser-based UI testing and bug-fixing** — Phase 5a gate for projects with a frontend stack.

## Health-score rubric

| Category | Weight | Scoring | Examples of findings |
|---|---|---|---|
| **E2E Journey** | 20% | Per broken step in the driven Primary User Journey | Signup form never redirects to onboarding, "Create Order" CTA on the dashboard doesn't reach the confirmation screen, a step in the stated journey has no reachable UI path at all |
| **Console** | 12% | Per Critical/High/Medium/Low/Info message in the log | Uncaught exceptions, 404 fetches, deprecation warnings |
| **Links** | 8% | Per broken/redirect link | 404 endpoints, redirects to wrong page |
| **Visual** | 8% | Per visual glitch — INCLUDES template adherence (see below) | Overlapping text, misaligned buttons, missing images, missing/reordered template section |
| **Functional** | 15% | Per broken interaction (isolated, single-widget — distinct from E2E Journey's multi-step outcome check) | Button doesn't submit form, dropdown doesn't open |
| **UX** | 12% | Per UX friction | Confusing error message, missing loading indicator |
| **Performance** | 8% | Per timing violation | Page load >3s, interaction latency >500ms |
| **Content** | 5% | Per stale/wrong text | Typos, outdated numbers, wrong account name in greeting |
| **Accessibility** | 12% | Per a11y violation | Missing alt text, keyboard-unreachable buttons, low contrast |

**Deductions** (per finding severity):
- CRITICAL: −25 points
- HIGH: −15 points
- MEDIUM: −8 points
- LOW: −3 points
- INFO: −1 point

**Score** = `max(0, 100 − sum(deductions))` = 0–100 grade.

## E2E Journey dimension (runs FIRST, before per-screen checks — see below)

This is the "does the actual product work end-to-end" check — distinct from
Functional (isolated widget interactions) and Visual/template-adherence
(per-screen structure in isolation). It answers: does a real user's stated
journey through this product actually complete, start to finish, in the
running app?

**Source of the journey (read before driving anything):**
1. `PROJECT_ROOT/.claude/memory/ux_brief.md § 1 User Personas & Workflows —
   Primary User Journey (as stated by developer)` — the verbatim journey
   captured by ux-research-agent's GOAL-12. This is the PRIMARY source.
2. `ux_brief.md`'s Design Spec Addendum § "Primary User Flows" (written by
   design-concept-agent Step 4, seeded from #1) — use this to map the
   stated journey's phases onto concrete screens/routes from the Screen
   Inventory when the raw journey text doesn't name exact routes.
3. If neither exists (older/malformed project, or `--quick` mode where a
   full drive-through isn't in scope) — fall back to a single smoke check:
   homepage loads → primary nav CTA is clickable → no immediate console
   error. Note in the report: "No Primary User Journey found in ux_brief.md
   — ran smoke fallback only, full E2E Journey coverage not possible."

**Driving the journey:**
- Break the stated journey into ordered steps (e.g. "visitor lands on
  homepage → signs up → completes onboarding → reaches their first
  dashboard view" = 4 steps).
- Drive each step for real via the MCP tools (`chrome-devtools/navigate_page`,
  `/click`, `/fill`, `/take_screenshot`) or Maestro for mobile — actually
  submit the signup form with real test data, actually click through
  onboarding, actually land on the resulting screen. Do not infer success
  from markup alone; confirm the resulting page/state via a real navigation
  or a rendered element specific to that outcome (e.g. the dashboard's
  Page Header title, not just "no error was thrown").
- If a secondary persona flow exists in ux_brief.md's Primary User Flows
  (Flow 2+), drive that too if `--full` mode; `--diff-aware`/`--quick` drive
  only Flow 1 (the developer-stated journey) unless the diff touches a
  screen exclusive to Flow 2+.
- A step that cannot be completed (form rejects valid input, CTA is a dead
  link, the resulting screen never renders, an expected redirect never
  fires) is a CRITICAL E2E Journey finding — this dimension has no MEDIUM/LOW
  tier for a broken step; the journey either completes or it doesn't.
- A step that completes but with friction (extra unexpected clicks, a
  confusing intermediate state not implied by the stated journey) is a
  HIGH E2E Journey finding, not CRITICAL.
- Record the full driven trace (screenshots per step, console state at each
  transition) the same way as the Test Cache mechanism below — this trace
  IS the primary evidence for this dimension's score, not a spot-check.

## Template adherence (part of the Visual dimension, checked on EVERY frontend QA run)

Every project-wide platform template (`ui-base-template.md` §§ 1-3 —
landing, login, dashboard) has a fixed set of mandatory sections. This check
is not optional and does not depend on `--diff-aware` vs `--full` — even a
diff-aware run checks template adherence on every screen its scope touches,
because the whole point of a shared template is that it holds "till the end
no matter what," not just at initial scaffold.

Before scoring Visual, read `ux_brief.md § 3 UI Design Concepts & Interactive
Screen Inventory` to get each in-scope screen's assigned template
(`landing` / `login` / `dashboard`). Then, for each screen actually rendered
during this QA run:

```
Template = landing:
  ☐ Navbar present, sticky, contains logo/brand-name + at least one CTA
  ☐ Hero present, contains an h1 headline + a primary CTA button
  ☐ Features section present (unless the inventory/ux_brief explicitly
    scoped this screen without one — check § 6 Landing Page Content)
  ☐ Final CTA band present
  ☐ Footer present, contains at least brand + one link column
  ☐ Section order matches the template exactly: Navbar → Hero → Features →
    [conditional sections in the order ux_brief.md § 6 lists them] →
    Final CTA → Footer
  ☐ No unresolved [PLACEHOLDER] or [TODO: ...] text visible in rendered output
    that ux_brief.md § 6 did NOT explicitly leave as an intentional TODO
  ☐ Page's H1 is unique (Hero headline only — no competing h1 elsewhere)

Template = login:
  ☐ Navbar present (minimal variant — logo + brand-name only, no nav-links
    or secondary CTA)
  ☐ Auth Card present, centered, contains the fields appropriate to this
    screen's purpose (Login: email+password; Sign Up: name+email+password;
    Forgot Password: email only; Reset Password: new+confirm password)
  ☐ No Hero/Features/Social-Proof/Pricing sections present — their ABSENCE
    is correct here per ui-base-template.md § 2, not a defect
  ☐ Footer present (simplified — copyright + legal links only)
  ☐ No unresolved [PLACEHOLDER] text visible in rendered output

Template = dashboard:
  ☐ Nav pattern present matches ux_brief.md's chosen pattern (top nav /
    sidebar / bottom nav) — not a different pattern than what was assigned
  ☐ Page header present (eyebrow + title, per ui-base-template.md § 3)
  ☐ No unresolved [PLACEHOLDER] text visible in rendered output

All templates — layout dimensions (checked once per distinct viewport
tested, not per screen):
  ☐ Breakpoint behaviour matches ui-base-template.md § 0 (sm 640 / md 768 /
    lg 1024 / xl 1280 / 2xl 1536px) — resize/emulate at least one width
    below and one above `lg` and confirm the layout responds at those
    boundaries, not at arbitrary different widths
  ☐ Interactive elements (nav items, buttons, footer links) measure
    ≥44×44px at viewport widths below `lg` (1024px) — the accessibility
    floor from § 0, not a suggestion
  ☐ Sidebar (dashboard) renders at 240px expanded / collapses to ~64px
    icon-only on narrow viewports, matching § 0's `sidebar-width` values —
    a different fixed width is a Visual finding, not a style choice
```

A missing mandatory section, wrong section order, or a leftover unresolved
placeholder is a **CRITICAL** Visual finding — same severity tier as a
broken layout, because a template violation is exactly that: the page is
structurally broken relative to its contract, even if every individual
element renders without a visual bug. Do not downgrade this to MEDIUM/LOW
just because the page "still looks fine" — consistency across every screen
this platform builds is the property being protected, and one silently
skipped section is how that erodes.

If `ux_brief.md` has no Screen Inventory / template assignment at all (an
older or malformed project), note this once in the QA report as a finding
against the project's setup — the template's Placeholder Replacement
Checklist can't be verified without knowing which template applies — but do
not treat every screen as a blanket CRITICAL failure; downgrade to a single
MEDIUM "template contract missing, cannot verify adherence" finding.

## Modes

- **Diff-aware** (default on feature branches): auto-detect the changed frontend files from git, focus QA on the feature's scope, skip unrelated pages
- **Full** (comprehensive): explore every page/flow, thorough coverage, drives ALL Primary User Flows (Flow 1 and any Flow 2+)
- **Quick** (smoke test): 30s baseline test — homepage + login + main CTA, shallow coverage

**Greenfield auto-full rule (MANDATORY, checked before mode selection):**
before honoring `--diff-aware`'s "default on feature branches" behavior,
check whether `PROJECT_ROOT/.claude/memory/qa_report.md` exists. If it does
NOT exist, this is the first-ever QA run on this project — there is no prior
report for "diff-aware" to be relative TO, and diff-aware's whole premise
(skip what a previous audit already covered) doesn't apply yet. Force `--full`
regardless of what flag was passed or what branch this is, and print:
`[qa] No prior qa_report.md found — this is a greenfield first run. Forcing
--full scope (E2E Journey + every screen), ignoring --diff-aware default.`
An explicit `--quick` flag from the caller is still honored (a human asking
for a smoke test knows they're getting a smoke test) — this rule only
overrides the *default*, not an explicit opposite request.

## Fix loop (audit → fix → re-audit → repeat until clean or capped)

After health-score audit, optionally fix issues (default behavior; `--report-only` skips):

1. **Classify findings** by severity and fixability
2. **Prioritize** — CRITICAL first, then HIGH
3. **Fix** — minimal code change, atomic commit per fix
4. **Re-test** — before/after screenshots, confirm the fix works
5. **Regression test** — write a test that fails without the fix, passes with it
6. **Self-regulate** — WTF-likelihood check: do NOT auto-fix if confidence is low

**Round loop (MANDATORY — a fix pass is not the end of the session):**
After applying a round of fixes (step 3-5 above, for every CRITICAL/HIGH
finding from the current audit), re-run the FULL audit again from the top —
E2E Journey drive-through first, then per-screen checks — rather than
trusting the fix in isolation. A fix can regress a different screen, break
the journey it didn't touch, or only partially resolve the finding; only a
fresh audit proves it actually worked end-to-end. Repeat:
`audit → fix round → re-audit → fix round → re-audit → ...`
until either:
- **Clean**: the re-audit finds zero CRITICAL/HIGH remaining → done, report PASS.
- **Round cap hit**: 3 re-audit rounds completed and CRITICAL/HIGH findings
  still remain → STOP, report FAIL with the remaining findings and note
  `rounds_run: 3/3, capped — not fully clean`. Do not silently continue past
  the cap hoping round 4 succeeds where 1-3 didn't; a persistent finding
  after 3 rounds is a signal for a human, not more auto-fixing.
- **WTF cap hit** (50 fixes total, or WTF-likelihood > 20% at any point,
  across ALL rounds combined, not per-round): STOP immediately regardless of
  round count, per the existing WTF formula below.
Each round's findings, fixes, and re-audit result are recorded in the final
report (see Output format) as separate round entries — never collapse
multiple rounds into a single "fixes applied" list that hides how many
re-audit cycles it took to get clean.

**WTF-likelihood formula** (conservative defaults, tracked across the whole
session — all rounds share one running total, not reset per round):
```
start 0%
each revert (fix made it worse) +15%
each fix touching >3 files +5%
after 10 fixes, +1% per fix
hard cap: 50 fixes total per QA run (all rounds combined)
if WTF > 20% → STOP and ask user
```

This ensures the fix loop stays safe and doesn't spiral into blindly "fixing" things.

## Browser/device backend: Chrome DevTools MCP (web) + Maestro MCP (mobile)

QA agent drives the browser/device **only through these two MCP servers** —
never Playwright, never raw CDP-over-Bash. Both are activated once at the
start of every QA session (qa-agent Step -1): checked via `claude mcp list`,
auto-installed via `claude mcp add` if missing, and — since a server only
attaches at session start — the run pauses with a restart request if either
was just installed. See `platform/agents/qa-agent.md` Step -1 for the exact
install commands.

### Tool contract (Chrome DevTools MCP)

QA agent drives the web browser exclusively via these MCP tools:
- **`chrome-devtools/navigate_page(url)`** — goto page
- **`chrome-devtools/take_screenshot()`** — screenshot current state
- **`chrome-devtools/evaluate_script(js)`** — run JS, get result (console state, `performance.timing`)
- **`chrome-devtools/click(selector)`** / **`chrome-devtools/fill(selector, value)`** — interact with elements
- **`chrome-devtools/get_console_message()`** — monitor console errors

Session cookies (see skill: `session-sync`) are injected by calling the MCP
tool's script-evaluation entry point with a `document.cookie` / storage write,
not by opening a separate raw WebSocket.

### Cooperative Takeover Protocol (MANDATORY Human-in-the-Loop)

If the agent is blocked by a CAPTCHA, Multi-Factor Authentication (MFA) gate, complex login wall, or a persistent selector timeout:
1. Write the state `{ "suspended": true, "reason": "blocked by captcha/MFA/selector" }` to `PROJECT_ROOT/.claude/memory/qa_state.json`.
2. Output a clear alert: `⚠ QA AUTOMATION BLOCKED. Please run /automation-takeover to take control of Chrome, complete the step manually, and then run /automation-resume to hand control back to the agent.`
3. Halt processing. Periodically inspect `PROJECT_ROOT/.claude/memory/qa_state.json`. Do not continue until `"suspended": false` is written.
4. Once resumed, continue the health-score audit from the active browser tab's current state.

### UI Test Caching & Journey Preservation (Test Cache)

When the QA session completes a successful testing run (navigation → clicks → entries → verification):
1. Compile the executed sequence of MCP tool calls (URLs visited, selectors, inputs used) into a structured JSON array.
2. Save it to `PROJECT_ROOT/.claude/memory/ui_test_cache/<test_slug>.json` (equivalent to running `/compile-ui-test`).
3. If a cached file already exists for the test scenario, subsequent QA runs must read and fast-replay the cached JSON actions first (taking ~200ms per action) before doing speculative re-exploration.

### Mobile Stack Integration (Maestro MCP)

For React Native, Flutter, or native iOS/Android packages: use
`maestro/list_devices` to locate emulator/simulator targets, then
`maestro/run` (or `maestro/inspect_screen` / `maestro/take_screenshot`) to
execute flows, trigger taps, and capture screenshot evidence. If the project
has a `.maestro/` flow suite, pass it to `maestro/run` via `dir` rather than
shelling out to the `maestro` CLI directly — same backend, one execution path.

## Output format

```
## QA Report

**Date:** 2026-01-15
**Scope:** Full (greenfield first run — no prior qa_report.md, --full auto-forced)
**Primary User Journey:** "visitor lands on homepage → signs up → completes
  onboarding → reaches their first dashboard view" (from ux_brief.md § 1)
**Execution:** 14m 10s across 2 rounds

### Round 1

**Health Score: 61/100**

| Category | Score | Issues |
|---|---|---|
| E2E Journey | 25 | 1 CRITICAL: signup form never redirects to onboarding — journey blocked at step 2/4 |
| Console | 85 | 1 MEDIUM warning (unhandled promise) |
| Links | 100 | ✓ all links working |
| Visual | 60 | 2 CRITICAL: form input misaligned, button cut off |
| Functional | 90 | 1 HIGH: submit button has race condition (double-submit) |
| UX | 100 | ✓ clear error messages |
| Performance | 75 | 1 MEDIUM: form load 1.8s (okay for first load) |
| Content | 100 | ✓ all text correct |
| A11y | 65 | 3 MEDIUM: missing alt text (2 icons), low contrast (1 button) |

**Findings (by severity):**

**CRITICAL** (must fix):
1. Signup form submits but never redirects to `/onboarding` — journey step 2/4 blocked (app/ui/pages/signup.tsx:88)
2. Form input field misaligned (app/ui/components/UserForm.tsx:42) — margin-top calculation off by 10px
3. Submit button cut off on mobile (responsive breakpoint issue)

**HIGH** (should fix):
4. Race condition on form submit — double-click submits twice (app/ui/hooks/useForm.ts:28)

**MEDIUM** (nice to fix):
5. Unhandled promise rejection on form error (app/api/users.ts:105)
6. Icon alt text missing (×2 icons in UserForm)
7. Button contrast ratio 3.5:1 (WCAG AA requires 4.5:1)

**Fixes applied this round:**
✓ #1 Signup redirect wired to /onboarding (app/ui/pages/signup.tsx:90) — commit abc111a
✓ #2 Form input alignment (app/ui/components/UserForm.tsx:43) — commit abc123d
✓ #3 Button mobile cutoff (app/ui/styles/form.css:18) — commit def456e
✓ #4 Double-submit race condition (app/ui/hooks/useForm.ts:29) — commit ghi789f

Remaining after round 1: #5, #6, #7 (deferred, MEDIUM only)

### Round 2 (re-audit after round 1 fixes)

**Health Score: 91/100**

| Category | Score | Issues |
|---|---|---|
| E2E Journey | 100 | ✓ all 4 steps of the Primary User Journey completed end-to-end |
| Console | 92 | 1 MEDIUM warning (unhandled promise, unchanged from round 1) |
| Visual | 100 | ✓ no remaining CRITICAL/HIGH |
| Functional | 100 | ✓ no remaining CRITICAL/HIGH |
| ... | ... | (unchanged categories omitted for brevity in this example) |

No new CRITICAL/HIGH introduced by round 1's fixes. Remaining: 3 MEDIUM
(deferred, acceptable for ship). **Clean — stopping the round loop here.**

### Before/after

[Screenshots: journey step 2 before (stuck on signup) | after (reaches onboarding) |
form misalignment before/after | console warnings before/after]

**Regression tests added:**
- `test_signup_redirects_to_onboarding()` — verifies journey step 2 completes
- `test_form_submit_no_double_click()` — verifies single-click behavior
- `test_form_alignment_responsive()` — verifies alignment at all breakpoints

### Verdict: PASS (after 2 rounds)

**Final score: 91/100** (round 1: 61 → round 2: 91)
**Rounds run:** 2 (clean before hitting the 3-round cap)
**Issues remaining:** 3 MEDIUM (acceptable for ship)
**No CRITICAL or HIGH** (✓ safe to merge)
```
