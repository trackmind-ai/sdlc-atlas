#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
# Write a doctor-ready CLAUDE.md into an existing project .claude/
#   bash tools/write-project-claude.sh --project /path/to/todo --name todo --stacks fastapi,react --profile standard
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Default stack is `python`: the previous default (`django`) is not one of the stacks this
# package ships, so it produced a CLAUDE.md naming a stack the user does not have.
PROJ="" NAME="" STACKS="python" PROFILE="standard"
while [ $# -gt 0 ]; do case "$1" in
  --project) PROJ="$2"; shift 2;;
  --name)    NAME="$2"; shift 2;;
  --stack|--stacks) STACKS="$2"; shift 2;;
  --profile) PROFILE="$2"; shift 2;;
  *) echo "unknown arg $1"; exit 1;;
esac; done
[ -n "$PROJ" ] || { echo "usage: --project <path> [--name slug] [--stacks fastapi,react] [--profile standard]"; exit 1; }
[ -d "$PROJ/.claude" ] || { echo "no .claude at $PROJ"; exit 1; }

# --name was parsed and then ignored: the scratch dir name was passed through to
# init-project-layer.sh, so the generated CLAUDE.md identified the project as
# `_write_<pid>`. Default to the target directory's own name when --name is omitted.
[ -n "$NAME" ] || NAME="$(basename "$(cd "$PROJ" && pwd)")"

# init-project-layer.sh always generates into projects/<--name>, and reuses that directory
# if it already exists. Generating under $NAME directly would therefore either collide with
# a real project layer of the same name or silently reuse its stale CLAUDE.md. So generate
# under a scratch name, then rewrite the project identity in the copied output.
# Must satisfy init-project-layer.sh's slug rule ^[a-z][a-z0-9-]*$ — no underscores.
GEN_NAME="tmp-write-$$"
GEN="$SRC/projects/$GEN_NAME"
trap 'rm -rf "$GEN"' EXIT

bash "$SRC/tools/init-project-layer.sh" --name "$GEN_NAME" --stacks "$STACKS" --profile "$PROFILE"
[ -f "$GEN/CLAUDE.md" ] || { echo "generation failed: no CLAUDE.md at $GEN"; exit 1; }

# Substitute the scratch identity for the real one. Two forms appear in the generated file:
# the raw slug (`tmp-write-123`) and the title-cased heading init-project-layer.sh derives
# from it (`Tmp Write 123`) — replacing only the slug left the H1 reading "Tmp Write 123".
GEN_TITLE="$(echo "$GEN_NAME" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print}')"
REAL_TITLE="$(echo "$NAME"     | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print}')"
sed -e "s/${GEN_TITLE}/${REAL_TITLE}/g" -e "s/${GEN_NAME}/${NAME}/g" \
  "$GEN/CLAUDE.md" > "$PROJ/.claude/CLAUDE.md"
printf '  \033[32m✔\033[0m CLAUDE.md written (name=%s profile=%s stacks=%s)\n' "$NAME" "$PROFILE" "$STACKS"
