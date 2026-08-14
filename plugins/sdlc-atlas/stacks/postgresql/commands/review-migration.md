# /review-migration <migration-file-or-diff>
Invoke migration-safety-agent: dry-run/plan, flag destructive ops, verify additive-first + rollback path, attach plan output to PR.
Refuses migrations outside the approved spec. Never auto-applies to a shared/production DB.
