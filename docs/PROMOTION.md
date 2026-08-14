# Promotion — How Capability Moves Up Layers

Evolution is bottom-up (need is real in projects); consolidation is top-down
(judgment sits with the platform team).

## Signal
The same skill/agent independently created or proposed in 2–3 projects on the same
stack → it belongs at stack layer. Independently needed across stacks and about
POLICY → org layer. About PROCESS itself → platform feature request.

## Cadence — quarterly harvest by the platform team
1. Collect every project's proposal_log.md + stable project-layer capabilities.
2. Cluster duplicates; pick the best implementation; generalize (strip
   project-specific names into parameters read from project CLAUDE.md).
3. Promote into stacks/<name>/ or org policy; release-note it; projects pick it up
   on next `install.sh --stack ... --project ...` (their local copy, now redundant,
   is deleted by the project team — precedence means no breakage either way).
4. Demote/deprecate: stack capabilities unused by all projects for 2 quarters get
   a deprecation note one quarter before removal.

## Rules
- Promotion never happens automatically and never mid-sprint.
- A promoted capability resets to `experimental` AT THE NEW LAYER for one adopter
  project before being marked stable there.
- Provenance header (origin project, proposal id, dates) travels with the file.
