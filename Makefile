# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT

.PHONY: help install load check validate lint test clean

PLUGIN := plugins/sdlc-atlas

help:
	@echo "sdlc-atlas — development commands"
	@echo ""
	@echo "  make install     Install the platform into ~/.claude/ (no plugin manager)"
	@echo "  make load        Register this checkout as a local plugin marketplace"
	@echo ""
	@echo "  make check       validate + lint + package self-test (run before a PR)"
	@echo "  make validate    Plugin manifests + agent frontmatter and skill references"
	@echo "  make lint        shellcheck every shell script"
	@echo "  make test        Package self-test (tools/verify-package.sh)"
	@echo ""
	@echo "  make clean       Remove caches and converter output"
	@echo ""
	@echo "Windows: use .\\tasks.ps1 <target> instead."

install:
	@bash $(PLUGIN)/install.sh --platform

# Installs from the LOCAL checkout via the dev marketplace in .claude-plugin/, which is
# deliberately named `trackmind-sdlc-atlas-dev` — never `trackmind` — so registering it
# cannot replace the published trackmind-ai/marketplace catalog.
load:
	@echo "Run these inside Claude Code:"
	@echo "  /plugin marketplace add $(CURDIR)"
	@echo "  /plugin install sdlc-atlas@trackmind-sdlc-atlas-dev"

check: validate lint test
	@echo "✓ all checks passed"

validate:
	@command -v claude >/dev/null 2>&1 && claude plugin validate . \
		|| echo "! claude CLI not found — skipping manifest validation (CI runs it)"
	@python scripts/validate_agents.py

lint:
	@command -v shellcheck >/dev/null 2>&1 \
		|| { echo "! shellcheck not found — install it or rely on CI"; exit 0; }
	@find . -name '*.sh' -not -path './.git/*' -print0 | xargs -0 shellcheck --severity=warning
	@echo "✓ shellcheck clean"

test:
	@cd $(PLUGIN) && bash tools/verify-package.sh

clean:
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name '*.pyc' -delete 2>/dev/null || true
	@rm -rf $(PLUGIN)/projects/project-template-cursor $(PLUGIN)/projects/tmp-write-* 2>/dev/null || true
	@echo "✓ clean"

.DEFAULT_GOAL := help
