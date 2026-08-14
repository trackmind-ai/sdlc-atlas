#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
# Create projects/<name>/ from project-template if it does not already exist.
#   bash tools/init-project-layer.sh --name todo --stack node
#   bash tools/init-project-layer.sh --name todo --stacks fastapi,react
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Default stack is `python`: `django` is not shipped in this package, so the old default
# made a bare `--name foo` invocation die with "Unknown stack".
NAME="" STACKS="python" PROFILE="standard"

log()  { printf '  \033[32m✔\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '  \033[31m✘\033[0m %s\n' "$1" >&2; exit 1; }

while [ $# -gt 0 ]; do case "$1" in
  --name)    NAME="$2"; shift 2;;
  --stack)   STACKS="$2"; shift 2;;
  --stacks)  STACKS="$2"; shift 2;;
  --profile) PROFILE="$2"; shift 2;;
  *) die "unknown arg: $1";;
esac; done

[ -n "$NAME" ] || die "usage: --name <layer-slug> [--stack name | --stacks fastapi,react]| --stacks fastapi,react] [--profile standard]"
[[ "$NAME" =~ ^[a-z][a-z0-9-]*$ ]] || die "layer name must be lowercase slug (e.g. todo, todo-api)"
[ "$NAME" != "project-template" ] || die "reserved name: project-template"

DEST="$SRC/projects/$NAME"
if [ -d "$DEST" ]; then
  log "Project layer already exists: projects/$NAME (reusing)"
  exit 0
fi

case "$PROFILE" in minimal|standard|enterprise) ;; *) die "profile must be minimal, standard, or enterprise";; esac

# Validate all stacks exist
IFS=',' read -ra STACK_ARR <<< "${STACKS// /}"
for s in "${STACK_ARR[@]}"; do
  [ -d "$SRC/stacks/$s" ] || die "Unknown stack '$s'. Available: $(ls "$SRC/stacks" | tr '\n' ' ')"
done

layer_title() {
  echo "$1" | tr '-' ' ' | awk '{for (i = 1; i <= NF; i++) $i = toupper(substr($i, 1, 1)) tolower(substr($i, 2)); print}'
}

TITLE="$(layer_title "$NAME")"
STACKS_DISPLAY="${STACKS// /}"
TEST_CMD="" SECURITY_CMD="" LINT_CMD=""
APP_MAP=""
REPO_LAYOUT=""
CONVENTIONS_EXTRA=""

is_multi=0
[ "${#STACK_ARR[@]}" -gt 1 ] && is_multi=1

# Commands and the app map are derived from each stack's own STACK.md and agents/ directory
# rather than hardcoded per stack name. The previous version recognised exactly three names
# (django, angular, node) and called `die "unsupported stack combination"` on anything else,
# so every other shipped stack — react, nextjs, vue, nestjs, python, fastapi, postgresql,
# docker — could not produce a project layer at all. Reading the stack's declared defaults
# keeps this working for any stack, including ones added later.
#
# Each STACK.md carries a line of the form:
#   Defaults (project may override): test `CMD`, security `CMD`, lint `CMD`.
# Must always exit 0: a support stack (postgresql, docker) declares no test command, and
# under `set -e` a non-zero grep inside $(...) aborts the whole script before the caller
# can react. The trailing `|| true` is what makes "no such default" a normal outcome.
stack_default() {   # $1 = stack slug, $2 = field (test|security|lint)
  local md="$SRC/stacks/$1/STACK.md"
  [ -f "$md" ] || return 0
  grep -m1 -oE "$2 \`[^\`]+\`" "$md" 2>/dev/null | head -1 | sed -E "s/^$2 \`//; s/\`$//" || true
}

# Support stacks (a database, a container runtime) legitimately declare no test command.
# Their absence must not blank out a sibling application stack's commands.
for s in "${STACK_ARR[@]}"; do
  [ -d "$SRC/stacks/$s" ] || die "unknown stack: $s (not present in stacks/)"
  for field in test security lint; do
    val="$(stack_default "$s" "$field")"
    [ -n "$val" ] || continue
    case "$field" in
      test)     [ -n "$TEST_CMD" ]     && TEST_CMD="$TEST_CMD && $val"         || TEST_CMD="$val" ;;
      security) [ -n "$SECURITY_CMD" ] && SECURITY_CMD="$SECURITY_CMD && $val" || SECURITY_CMD="$val" ;;
      lint)     [ -n "$LINT_CMD" ]     && LINT_CMD="$LINT_CMD && $val"         || LINT_CMD="$val" ;;
    esac
  done
done

# App map: one row per agent the stack actually ships, read from its agents/ directory.
APP_MAP=""
for s in "${STACK_ARR[@]}"; do
  for ad in "$SRC/stacks/$s"/agents/*/; do
    [ -d "$ad" ] || continue
    ag="$(basename "$ad")"
    # `|| true` for the same set -e reason as stack_default above.
    role="$(grep -m1 -oE '^description: *.*' "$ad/AGENT.md" 2>/dev/null | sed -E 's/^description: *//; s/^>-? *//' | cut -c1-60 || true)"
    [ -n "$role" ] || role="see stacks/$s/agents/$ag/AGENT.md"
    APP_MAP="${APP_MAP}| ${role} | ${ag} (${s}) |
"
  done
done
APP_MAP="${APP_MAP%$'\n'}"
[ -n "$APP_MAP" ] || APP_MAP="| (no stack agents — platform agents handle all work) | orchestrator |"

# A monorepo layout note only makes sense when a backend and a frontend stack are combined.
if [ "$is_multi" = 1 ]; then
  fe="" be=""
  for s in "${STACK_ARR[@]}"; do
    case "$s" in
      react|nextjs|angular|vue) fe="$s" ;;
      node|nestjs|python|fastapi|django|spring-boot) be="$s" ;;
    esac
  done
  if [ -n "$fe" ] && [ -n "$be" ]; then
    REPO_LAYOUT="## Repo layout (monorepo)
backend/   <- $be API ($be stack)
frontend/  <- $fe app ($fe stack)"
    CONVENTIONS_EXTRA="- Backend API is the source of truth; frontend DTOs mirror spec API section.
- CORS and API base URL configured in backend + frontend environments."
  fi
fi

TRACKER="github"
ORG_POLICY_LINE="org_policy: [FILL IN path/repo, or remove for solo projects]"
case "$PROFILE" in
  enterprise)
    TRACKER="ado"
    ORG_POLICY_LINE="org_policy: [FILL IN — path/repo of your org policy layer]"
    ;;
  minimal) TRACKER="none"; ORG_POLICY_LINE="";;
esac

cp -r "$SRC/projects/project-template" "$DEST"

cat > "$DEST/CLAUDE.md" <<EOF
# ${TITLE} — Project Layer (L3)
profile: ${PROFILE}
stack: ${STACKS_DISPLAY}
${ORG_POLICY_LINE}
tech_leads: [FILL IN — who may /approve-proposal at project layer]

${REPO_LAYOUT}

## Issue tracker
tracker: ${TRACKER}
github_repo: [FILL IN owner/repo — or remove if tracker is none/ado/jira]

## Commands the gates run
test: ${TEST_CMD}
security: ${SECURITY_CMD}
lint: ${LINT_CMD}

## App map (orchestrator routing table)
| Work type | Agent |
|---|---|
${APP_MAP}

## Conventions (hard rules a coding agent must never violate)
- [FILL IN domain-specific rules for ${TITLE}]
${CONVENTIONS_EXTRA}

## Greenfield reference material (optional, read-only, never committed as product code)
.claude/reference/codebases/      <- repos to copy patterns from
.claude/reference/architecture/   <- standards, prior RFCs, constraints

## Version control policy for .claude/
Commit: agents/ skills/ commands/ CLAUDE.md settings.json specs/ proposals/ (+ memory/evidence/ in enterprise).
Ignore: memory/orchestrator_state.md (personal pipeline position), reference/.
Rename gitignore-template -> .gitignore inside .claude/ after setup.
EOF

if [ "$PROFILE" = "minimal" ]; then
  sed -i.bak '/^org_policy:/d' "$DEST/CLAUDE.md" && rm -f "$DEST/CLAUDE.md.bak"
fi

# Merge settings from every stack
DEST_SETTINGS="$DEST/settings.json"
for s in "${STACK_ARR[@]}"; do
  STACK_SETTINGS="$SRC/stacks/$s/settings.json"
  [ -f "$STACK_SETTINGS" ] || continue
  if command -v jq >/dev/null 2>&1; then
    jq -s '
      def uniqarr: (.[0] // []) + (.[1] // []) | unique;
      { env: ((.[0].env // {}) * (.[1].env // {})),
        permissions: { allow: [.[0].permissions.allow, .[1].permissions.allow] | uniqarr,
                       deny:  [.[0].permissions.deny,  .[1].permissions.deny ] | uniqarr },
        hooks: ((.[0].hooks // {}) * (.[1].hooks // {})) }' "$DEST_SETTINGS" "$STACK_SETTINGS" > "$DEST_SETTINGS.tmp" \
      && mv "$DEST_SETTINGS.tmp" "$DEST_SETTINGS"
  elif command -v node >/dev/null 2>&1; then
    node -e '
      const fs=require("fs");
      const [a,b]=[process.argv[1],process.argv[2]].map(p=>JSON.parse(fs.readFileSync(p,"utf8")));
      const u=(x,y)=>[...new Set([...(x||[]),...(y||[])])];
      const out={env:Object.assign({},a.env||{},b.env||{}),
                 permissions:{allow:u(a.permissions&&a.permissions.allow,b.permissions&&b.permissions.allow),
                              deny:u(a.permissions&&a.permissions.deny,b.permissions&&b.permissions.deny)},
                 hooks:Object.assign({},a.hooks||{},b.hooks||{})};
      fs.writeFileSync(process.argv[1],JSON.stringify(out,null,2));' "$DEST_SETTINGS" "$STACK_SETTINGS"
  else
    warn "no jq/node — merge stacks/$s/settings.json into projects/$NAME/settings.json manually"
  fi
done

log "Created project layer: projects/$NAME (stacks=$STACKS_DISPLAY profile=$PROFILE)"
warn "Edit projects/$NAME/CLAUDE.md — replace remaining [FILL IN] placeholders"
