#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
# Behaviour test: the stack fetcher must not download anything without --confirm, and
# setup-stacks.sh must surface NEEDS_CONFIRM instead of fetching.
# Run from the plugin root: bash tools/test-stack-fetch-consent.sh
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
FETCHER="$(pwd)/stacks/stack-orchestrator/bin/stack_fetcher.py"
fails=0
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
expect() { if [ "$2" = "$3" ]; then echo "  ok   $1"; else echo "  FAIL $1 (got '$2', want '$3')"; fails=$((fails + 1)); fi; }
py() { if command -v python3 > /dev/null 2>&1; then python3 "$@"; else python "$@"; fi; }

# 1. No --confirm: exit 0, NEEDS_CONFIRM printed, nothing written under the stacks root.
out="$(AGENTICAI_SDLC_HOME="$WORK/home" py "$FETCHER" nodejs 2>&1)"; rc=$?
expect "consent check exits 0" "$rc" 0
printf '%s' "$out" | grep -q "NEEDS_CONFIRM" && r=yes || r=no
expect "consent check prints NEEDS_CONFIRM" "$r" yes
[ -e "$WORK/home/stacks/nodejs" ] && r=written || r=clean
expect "consent check writes nothing" "$r" clean

# 2. An installed stack is skipped, not offered for download.
mkdir -p "$WORK/home/stacks/react" && touch "$WORK/home/stacks/react/STACK.md" "$WORK/home/stacks/react/settings.json"
out="$(AGENTICAI_SDLC_HOME="$WORK/home" py "$FETCHER" react 2>&1)"
printf '%s' "$out" | grep -q "SKIP" && r=skip || r=other
expect "installed stack is skipped" "$r" skip

# 3. setup-stacks.sh reports NEEDS_CONFIRM for a missing stack and fetches nothing.
P="$WORK/plat"; mkdir -p "$P/agents" "$P/stacks/stack-orchestrator/bin" "$WORK/proj"
cp "$FETCHER" "$P/stacks/stack-orchestrator/bin/"
out="$(AGENTICAI_SDLC_HOME="$P" bash platform/scripts/setup-stacks.sh "$P" "$WORK/proj" nodejs 2>&1)"
printf '%s' "$out" | grep -q "NEEDS_CONFIRM: nodejs" && r=yes || r=no
expect "setup-stacks surfaces NEEDS_CONFIRM" "$r" yes
[ -e "$P/stacks/nodejs" ] && r=written || r=clean
expect "setup-stacks fetches nothing" "$r" clean

[ "$fails" -eq 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
