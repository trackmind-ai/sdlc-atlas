# /scan-image <image>

Invoke image-security-agent with image-size-audit skill to run a read-only CVE and size audit on the built image.
Runs `docker scout cves` / `trivy image` and `docker history`; blocks on undocumented CRITICAL/HIGH CVEs. Never edits files — reports findings back to dockerfile-agent/compose-agent for remediation.
