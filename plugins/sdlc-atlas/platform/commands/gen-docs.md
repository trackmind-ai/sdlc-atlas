# /gen-docs
Invoke docs-agent on the current feature: derive the staleness list from the
approved spec + diff, update only stale documentation (README, API reference,
runbooks, architecture doc), flag ADR contradictions. Runs automatically in the
enterprise pipeline after gates, before release; manual in other profiles.
