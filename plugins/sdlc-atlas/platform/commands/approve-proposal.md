# /approve-proposal <P-NNN>
Authority-gated. Steps the orchestrator MUST enforce, in order:
1. Confirm the invoker holds authority for the proposal's target layer
   (project → tech lead listed in project CLAUDE.md `tech_leads:`;
   stack/org → org policy `platform_team:`; platform → reject, route to vendor).
2. Require a completed Security Review section with verdict PASS (run
   security-agent on the draft if missing).
3. On approval: apply the change to the TARGET layer's files, rename the proposal
   to `P-NNN-slug.approved.md` (settings deny-list makes it immutable), set
   lifecycle `experimental`, log to .claude/memory/proposal_log.md.
4. Experimental capabilities run in THIS project only. Promotion to stable and to
   higher layers follows docs/PROMOTION.md — never automatic.
Rejections: rename to `.rejected.md` with a reason; agents must not re-file the
same gap without new evidence.
