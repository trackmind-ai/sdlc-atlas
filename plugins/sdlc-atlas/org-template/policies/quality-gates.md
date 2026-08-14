# Org Policy: Quality Gates
Gate order is platform-fixed: tests -> security -> static quality -> review.
This org's thresholds (from ORG.md): coverage >= coverage_min on NEW code;
security_fail_on and above blocks; Sonar quality gate must be green when
sonar_required. Waivers: only the platform team, in writing, logged in the PR,
expiring in 30 days.
