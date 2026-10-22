# sdlc-atlas

An agent-driven SDLC platform for Claude Code. It takes a requirement to production-ready
code through a **governed** pipeline: versioned specifications, human approval gates, and
quality gates that run in a fixed order and stop at the first failure. Agents cannot write
production code in a project until a human has approved a spec, and that rule is enforced by
a hook rather than by an instruction an agent might ignore.

## Install

```text
/plugin marketplace add trackmind-ai/marketplace
/plugin install sdlc-atlas@trackmind
```

Then, in the project you want to govern, run `/start`.

## What is included

| Part | Count | What it does |
|---|---|---|
| Agents | 23 | Orchestrator plus specialists for requirements, specs, architecture, bootstrap, security, review, QA, tests, docs, release, incidents and retros |
| Commands | 43 | `/start`, `/feature`, `/fix`, `/approve-spec`, `/quality-check`, `/qa`, `/raise-pr`, `/release` and more |
| Skills | 42 | Reusable procedures such as spec writing, citation discipline, retry policy and live QA |
| Stacks | 10 | Per-stack agents and settings for React, Next.js, Vue, Angular, Node, NestJS, Python, FastAPI, PostgreSQL, Docker, plus a stack fetcher for others |

The four capability layers (platform, stack, organization, project) are described in the
repository's `ARCHITECTURE.md`. A lower layer may only tighten the rules of the layer above.

## What this plugin runs, installs, sends and fetches

Nothing here is hidden. This is the complete list.

**Hooks (installed with the plugin).** Two `PreToolUse` hooks on `Edit` and `Write`, plus one
`Stop` hook. Both edit hooks do nothing in a project until you have run `/start` there. They
switch on once the project has pipeline state (`.claude/memory/orchestrator_state.md`) or
governance settings in its `.claude/settings.json`. In a set-up project:

- Edits to production code are **blocked** until an approval marker exists at
  `.claude/memory/approvals/ACTIVE`. The marker is written by `/approve-spec`, an approved
  `/fix`, or a `/bootstrap` go-ahead. Creating `.claude/gate-off` switches the gate off for
  non-pipeline work, and it shows up in `git status`.
- Edits to *existing* files under `.claude/agents`, `.claude/skills` and `.claude/commands`
  are blocked; change them with `/approve-proposal`.
- The `Stop` hook only prints a reminder when pipeline state looks unfinished.

The hooks read the tool call and local files only. They make no network requests.

**Permission settings.** The plugin ships `platform/settings.json`, which `/start` copies
into a governed project's `.claude/settings.json`. It adds a project-level allow list (80 rules)
and a deny list (force push, `rm -rf /` and `rm -rf ~`, editing `.env` files and secrets,
editing approved proposals). The allow list names specific commands rather than wildcards:
`npx` is limited to eslint, tsc, vue-tsc, prettier, vitest, jest, vite, next, prisma, typeorm and
license-checker, `claude mcp add` to the two QA servers below, and `pip install` to
`-r requirements` files and bandit. Anything else (for example `npx some-other-package`)
prompts you as usual. The plugin does not edit your user-level Claude settings.

**Software it can install, only after asking you.** Every item below is optional: you are
asked, and if you say no, nothing is installed and setup continues. Nothing in `/start`,
`/setup` or the agents stops because you declined.

- Chrome DevTools MCP (`claude mcp add chrome-devtools -- npx -y chrome-devtools-mcp@1.11.0`)
  for browser QA of web frontends, and Maestro (`claude mcp add maestro -- maestro mcp`,
  with the official installer from `get.maestro.mobile.dev` if the CLI is absent) for mobile.
  The browser and device QA gate runs for frontend stacks. If you decline the tooling, the
  gate is recorded as `SKIPPED (declined)` and the final report states that the UI was not
  verified. It is never recorded as a pass, and a static source review is never presented
  as QA.
- The third-party `caveman` terse-output plugin, via its install script pinned to a fixed
  commit of `github.com/JuliusBrussee/caveman`. Declining skips terse-output enforcement;
  `/start`, `/setup` and the agents all continue without it.
- Project scaffolders pinned to exact versions: `create-next-app@16.4.2` and `create vite@9.2.1`.
- Tools a stack needs, such as `pip install -r requirements.txt` and `npm install`, in your
  project. If a declared test, lint or security tool is missing, you are asked whether to
  install it. If you decline, the tool is listed in `.claude/memory/declined_tools.md` and
  its gate is recorded as `SKIPPED (declined)`.

**Network access.**

- `stack_fetcher.py` downloads public documentation pages (for example nodejs.org,
  react.dev, fastapi.tiangolo.com) to author a new stack with `/fetch-stack`. It runs only
  when you ask for a stack that is not bundled.
- Azure DevOps commands (`/feature` from a work item, `/raise-pr`) call
  `dev.azure.com` with the `AZURE_DEVOPS_EXT_PAT` token you provide in your environment.
  Without that variable they do nothing. Agents never push to protected branches; a human
  reviews and merges.
- The SonarQube gate calls the `SONAR_HOST` you configure, and the QA gate checks local dev
  servers on `127.0.0.1`.
- No telemetry. Content fetched from work items or pages is treated as data, not as
  instructions.

**Files it writes.** Inside your project only: `.claude/` (agents, skills, commands,
settings), `.claude/memory/` (pipeline state, gate results, approvals), `.claude/specs/`,
and documents such as ADRs and designs in the repository. It never writes outside your
project except the optional `install.sh --platform` route described in the repository
README.

## Try it

Three prompts to start with:

1. `/start`. Interviews you one question at a time about the project, then sets up the
   governed layer in that folder.
2. `/feature add a due date to todo items`, then `/approve-spec todo/add-due-date` once you
   have read the spec. Agents cannot write production code until you approve.
3. `/quality-check`. Runs the quality gates in order and writes the results to
   `.claude/memory/gate_results.md`.

## Troubleshooting

- **An edit is blocked before any code exists.** The approval hook is doing its job: run
  `/approve-spec <feature>/<change>` after reviewing the spec. Approval is recorded in
  `.claude/memory/approvals/`.
- **"capability files already exist".** Those files change only through
  `/approve-proposal`, not by direct edits.
- **A tool is not installed** (the caveman plugin, browser or device QA tooling, a linter).
  The plugin asks whether to install it. If you say no it continues, and the matching gate
  is recorded as `SKIPPED (declined)` in `gate_results.md`. Nothing is shown as passed.
- **Live QA hits a CAPTCHA or login wall.** It asks you to finish the step by hand and
  resume, or to skip live QA.
- **Hooks do nothing in another project.** They only act in projects where `/start` has set
  up the governed layer.

## Requirements

Claude Code, `bash`, and `git`. Python 3 for stack fetching and some gates. Node.js for
Node and frontend stacks.

## Documentation, support and license

Architecture, governance, walkthrough and capability matrix are in the
[repository](https://github.com/trackmind-ai/sdlc-atlas).
Report problems at <https://github.com/trackmind-ai/sdlc-atlas/issues>.
Licensed under the MIT License (see the repository `LICENSE`).
