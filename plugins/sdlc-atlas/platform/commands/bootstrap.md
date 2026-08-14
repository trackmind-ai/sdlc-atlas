# /bootstrap
Greenfield only. Invoke bootstrap-agent: scaffold manifest, layout, test harness,
lint, CI, doc stubs per the project-bootstrap skill + the stack's bootstrap skill;
verify the scaffold passes its own pipeline. Refuses on repos that already have a
real dependency manifest. Run AFTER /architecture (if used) and BEFORE the first
/feature.
The developer's go-ahead to scaffold IS the approval: write the marker
(`.claude/memory/approvals/ACTIVE` containing `bootstrap <timestamp>`) before
creating files, and archive it to `bootstrap.approved` when the scaffold passes
its own pipeline.
