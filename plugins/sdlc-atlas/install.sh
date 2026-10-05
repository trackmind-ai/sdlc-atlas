#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
# sdlc-atlas installer. Always overwrites — platform is source of truth.
#
#   bash install.sh --platform
#       Copies ALL platform files AND all built-in stacks to $HOME/.claude/
#       Always overwrites existing files. After this, the repo folder is not needed.
#
#   bash install.sh --stack <name> --project <path>
#       Copies stack files to BOTH $HOME/.claude/stacks/<name>/ AND project/.claude/
#       Always overwrites. Works for built-in and dynamically fetched stacks.
#
#   bash install.sh --org /path/to/org-policy --project <path>
#   bash install.sh --new-project <path>          (scaffold from template)
#   bash install.sh --sync-project <path>
#       Re-copies CURRENT platform agents/commands/skills + declared stack(s)
#       + settings.json into an EXISTING project's .claude/. Always overwrites
#       capability files. Never touches CLAUDE.md, knowledge.md, memory/, specs/,
#       proposals/. Run this any time platform/ changes and an existing project
#       must pick up the update — --platform alone only refreshes ~/.claude/.
#   bash install.sh --doctor <path>               (validate a project layer; also flags out-of-sync files)
#   bash install.sh --audit-stacks                (frontmatter conformance check, all installed stacks)
#
#   Target selection (default: claude — 100% unchanged behavior):
#     bash install.sh --platform cursor            (builds $HOME/.cursor/ with Cursor-native
#                                                    agents/*.md, skills/<n>/SKILL.md,
#                                                    rules/*.mdc, mcp.json — converted from the
#                                                    same platform/ + stacks/ source of truth.
#                                                    Platform/stack COMMANDS become Skills with
#                                                    disable-model-invocation: true, per Cursor's
#                                                    documented commands-to-skills migration —
#                                                    there is no separate commands/ output for
#                                                    Cursor, see platform/converters/cursor.sh)
#     bash install.sh --new-project <path> --target cursor
#     bash install.sh --sync-project <path> --target cursor
#     bash install.sh --doctor <path> --target cursor
#   Any command also accepts a trailing `--target cursor` flag. See
#   platform/converters/cursor.sh for the conversion rules.
#
# Supported stacks: angular, docker, fastapi, nestjs, nextjs, node, postgresql, python,
#   react, vue  (plus stack-orchestrator, which generates any other stack on demand
#   via /fetch-stack)
#   (run `ls stacks/` for the current list — this comment can drift)
#
# File structure:
#
#   Stack source / platform home — grouped per stack:
#     stacks/<stack>/agents/<agent-name>/AGENT.md
#     stacks/<stack>/skills/<skill-name>/SKILL.md
#     stacks/<stack>/commands/<cmd>.md              (flat)
#
#   Project layer — agents/skills grouped by STACK NAME:
#     .claude/agents/<stack>/<agent-name>/AGENT.md
#     .claude/skills/<stack>/<skill-name>/SKILL.md
#     .claude/commands/<cmd>.md                     (flat)
#
#   Platform built-in agents/skills (platform/) remain flat in ~/.claude/agents/
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '  \033[32m✔\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '  \033[31m✘\033[0m %s\n' "$1" >&2; exit 1; }
# proj_root: callers append /.claude (or /.cursor) themselves, so a path that already ends
# in a layer dir would nest it (.claude/.claude). Use the parent instead.
proj_root() {
  local bs p; bs=$(printf '\134'); p="${1//"$bs"//}"; p="${p%/}"
  case "$p" in
    .claude|.cursor) p=".." ;;
    */.claude|*/.cursor) warn "project path ends in a layer dir - using its parent" >&2; p="${p%/*}" ;;
  esac
  printf '%s' "$p"
}

# ---------------------------------------------------------------------------
# Target resolution: which tool's native folder shape to build.
#   claude  (default) → $HOME/.claude, .claude/ project layer (unchanged)
#   cursor             → $HOME/.cursor, .cursor/ project layer (native shape,
#                        converted from platform/stacks source via
#                        platform/converters/cursor.sh)
# Resolved once, up front, from either a trailing bare word after --platform
# (e.g. `--platform cursor`) or an explicit `--target <name>` flag anywhere
# in argv. Everything else in this script is unchanged for target=claude.
# ---------------------------------------------------------------------------
TARGET="claude"
_args=("$@")
for ((i = 0; i < ${#_args[@]}; i++)); do
  if [ "${_args[$i]}" = "--target" ] && [ -n "${_args[$((i + 1))]:-}" ]; then
    TARGET="${_args[$((i + 1))]}"
  fi
done
if [ "${1:-}" = "--platform" ] && [ -n "${2:-}" ] && [[ "${2:-}" != --* ]]; then
  TARGET="$2"
fi
case "$TARGET" in
  claude|cursor) ;;
  *) die "Unknown target '$TARGET'. Supported: claude, cursor" ;;
esac

if [ "$TARGET" = "cursor" ]; then
  PLATFORM_DEST="${AGENTICAI_SDLC_HOME:-$HOME/.cursor}"
  PROJECT_LAYER_DIR=".cursor"
  # shellcheck source=platform/converters/cursor.sh
  source "$SRC_DIR/platform/converters/cursor.sh"
else
  PLATFORM_DEST="${AGENTICAI_SDLC_HOME:-$HOME/.claude}"
  PROJECT_LAYER_DIR=".claude"
fi

# ---------------------------------------------------------------------------
# copy_subfolder_tree: copies agents/ or skills/ subfolder tree. Always overwrites.
#   src: agents/<name>/AGENT.md  →  dest: agents/<name>/AGENT.md
#   src: skills/<name>/SKILL.md  →  dest: skills/<name>/SKILL.md
# ---------------------------------------------------------------------------
copy_subfolder_tree() {
  local src_sub="$1" dest_sub="$2" label="$3"
  [ -d "$src_sub" ] || return 0
  for entry in "$src_sub"/*/; do
    [ -d "$entry" ] || continue
    local folder_name; folder_name="$(basename "$entry")"
    local file=""
    for f in "$entry"*.md; do [ -f "$f" ] && file="$f" && break; done
    [ -n "$file" ] || continue
    local fname; fname="$(basename "$file")"
    mkdir -p "$dest_sub/$folder_name"
    cp "$file" "$dest_sub/$folder_name/$fname"
    log "$label → $(basename "$dest_sub")/$folder_name/$fname"
  done
}

# ---------------------------------------------------------------------------
# overwrite_layer: PLATFORM ONLY — always overwrites.
# Platform built-in agents/ and skills/ are flat .md files (not subfolder trees).
# ---------------------------------------------------------------------------
overwrite_layer() {
  local src="$1" dest="$2"
  # NOTE: converters/ is deliberately NOT in this list — install_platform()
  # copies it unconditionally for BOTH targets (see its own comment) since
  # setup-stacks.sh needs it under PLATFORM_HOME regardless of which target
  # this platform install itself used.
  for sub in agents skills commands templates profiles scripts bin; do
    [ -d "$src/$sub" ] || continue
    mkdir -p "$dest/$sub"
    # Prune first: delete any flat file at dest/$sub with no matching source
    # file in src/$sub — renamed/deleted platform files (e.g. this repo's
    # ui-default/landing/dashboard-template.md → ui-base-template.md rename)
    # otherwise linger at PLATFORM_DEST forever, since this function only
    # ever added/overwrote and never deleted.
    for f in "$dest/$sub"/*.md "$dest/$sub"/*.sh "$dest/$sub"/*.json "$dest/$sub"/*.py "$dest/$sub"/*.html; do
      [ -f "$f" ] || continue
      local base; base="$(basename "$f")"
      [ -f "$src/$sub/$base" ] || [ -d "$src/$sub/${base%.md}" ] || { rm -f "$f"; log "platform: pruned stale $sub/$base"; }
    done
    # For skills (or any folder containing subfolders like <skill-name>/SKILL.md), copy subfolders recursively
    for dir in "$src/$sub"/*/; do
      [ -d "$dir" ] || continue
      local dirname; dirname="$(basename "$dir")"
      mkdir -p "$dest/$sub/$dirname"
      cp -r "$dir"* "$dest/$sub/$dirname/" 2>/dev/null || cp "$dir"* "$dest/$sub/$dirname/" 2>/dev/null || true
      log "platform → $sub/$dirname/"
    done
    for f in "$src/$sub"/*.md "$src/$sub"/*.sh "$src/$sub"/*.json "$src/$sub"/*.py "$src/$sub"/*.html; do
      [ -f "$f" ] || continue
      local base; base="$(basename "$f")"
      cp "$f" "$dest/$sub/$base"
      log "platform → $sub/$base"
    done
  done
}

# ---------------------------------------------------------------------------
# install_stack_to_platform: copies a stack into PLATFORM_DEST/stacks/<name>/
# Preserves the exact stack source structure:
#   agents/<agent-name>/AGENT.md
#   skills/<skill-name>/SKILL.md
#   commands/<cmd>.md  (flat)
# ---------------------------------------------------------------------------
install_stack_to_platform() {
  local stack="$1"
  [ -d "$SRC_DIR/stacks/$stack" ] || return 0
  local src="$SRC_DIR/stacks/$stack"
  local dest="$PLATFORM_DEST/stacks/$stack"
  mkdir -p "$dest"

  for root_file in STACK.md settings.json raw-sources.md; do
    [ -f "$src/$root_file" ] && cp "$src/$root_file" "$dest/$root_file" && log "stacks/$stack → $root_file"
  done

  # agents/ and skills/ — preserve subfolder structure only (overwrite=1 for platform)
  # Remove any stale flat .md files left by older install versions before copying
  for dir in agents skills; do
    if [ -d "$dest/$dir" ]; then
      find "$dest/$dir" -maxdepth 1 -name "*.md" -not -name "AGENT.md" -not -name "SKILL.md" -delete 2>/dev/null || true
    fi
  done
  copy_subfolder_tree "$src/agents" "$dest/agents" "stacks/$stack"
  copy_subfolder_tree "$src/skills" "$dest/skills" "stacks/$stack"

  # commands/ and bin/ — flat
  for sub in commands bin; do
    [ -d "$src/$sub" ] || continue
    mkdir -p "$dest/$sub"
    for f in "$src/$sub"/*; do
      [ -f "$f" ] || continue
      local base; base="$(basename "$f")"
      cp "$f" "$dest/$sub/$base"
      log "stacks/$stack → $sub/$base"
    done
  done
}

# ---------------------------------------------------------------------------
# merge_layer: copies a stack into a project .claude/ directory. Always overwrites.
#
# Stack agents/skills are grouped by STACK NAME in the project layer:
#   stacks/fastapi/agents/api-agent/AGENT.md  →  .claude/agents/fastapi/api-agent/AGENT.md
#   stacks/fastapi/skills/fastapi-endpoint/SKILL.md  →  .claude/skills/fastapi/fastapi-endpoint/SKILL.md
#
# commands/ and bin/ are flat in the project layer. Always overwrites existing files.
# $4 = stack name (used as the grouping folder inside agents/ and skills/)
# ---------------------------------------------------------------------------
merge_layer() {
  local src="$1" dest="$2" label="$3" stack="$4"

  # agents/ — grouped under agents/<stack>/
  if [ -d "$src/agents" ]; then
    mkdir -p "$dest/agents/$stack"
    # remove stale flat .md files under agents/<stack>/ before copy
    find "$dest/agents/$stack" -maxdepth 1 -name "*.md" -delete 2>/dev/null || true
    for entry in "$src/agents"/*/; do
      [ -d "$entry" ] || continue
      local agent_name; agent_name="$(basename "$entry")"
      local agent_file="$entry/AGENT.md"
      [ -f "$agent_file" ] || continue
      local dest_dir="$dest/agents/$stack/$agent_name"
      mkdir -p "$dest_dir"
      cp "$agent_file" "$dest_dir/AGENT.md"
      log "$label → agents/$stack/$agent_name/AGENT.md"
    done
  fi

  # skills/ — grouped under skills/<stack>/
  if [ -d "$src/skills" ]; then
    mkdir -p "$dest/skills/$stack"
    # remove stale flat .md files under skills/<stack>/ before copy
    find "$dest/skills/$stack" -maxdepth 1 -name "*.md" -delete 2>/dev/null || true
    for entry in "$src/skills"/*/; do
      [ -d "$entry" ] || continue
      local skill_name; skill_name="$(basename "$entry")"
      local skill_file="$entry/SKILL.md"
      [ -f "$skill_file" ] || continue
      local dest_dir="$dest/skills/$stack/$skill_name"
      mkdir -p "$dest_dir"
      cp "$skill_file" "$dest_dir/SKILL.md"
      log "$label → skills/$stack/$skill_name/SKILL.md"
    done
  fi

  # commands/ and bin/ — flat in project layer, always overwrite
  for sub in commands bin; do
    [ -d "$src/$sub" ] || continue
    mkdir -p "$dest/$sub"
    for f in "$src/$sub"/*; do
      [ -f "$f" ] || continue
      local base; base="$(basename "$f")"
      cp "$f" "$dest/$sub/$base"
      log "$label → $sub/$base"
    done
  done
}

merge_settings() {
  # $1=src settings.json  $2=dest settings.json
  # First write (no dest yet): straight copy. Subsequent writes (e.g. a second
  # stack merged into the same project): union permissions.allow/deny instead of
  # overwriting, so stack N+1 never silently discards stack N's permissions.
  # env/hooks are only ever present on platform/settings.json, which is always
  # installed before any stack — merge preserves whichever side already has them.
  [ -f "$1" ] || return 0
  if [ ! -f "$2" ]; then
    cp "$1" "$2"
    log "settings.json installed"
    return 0
  fi
  local pybin=""
  for cand in py python3 python; do
    command -v "$cand" >/dev/null 2>&1 && { pybin="$cand"; break; }
  done
  if [ -z "$pybin" ]; then
    warn "no python found — settings.json left as-is, could not merge $1 (install python to enable permission merging across stacks)"
    return 0
  fi
  "$pybin" - "$1" "$2" <<'PYEOF'
import json, sys

src_path, dest_path = sys.argv[1], sys.argv[2]
with open(src_path, encoding="utf-8") as f:
    src = json.load(f)
with open(dest_path, encoding="utf-8") as f:
    dest = json.load(f)

def union(a, b):
    seen, out = set(), []
    for item in (a or []) + (b or []):
        if item not in seen:
            seen.add(item)
            out.append(item)
    return out

dest.setdefault("permissions", {})
src_perms = src.get("permissions", {})
dest["permissions"]["allow"] = union(dest["permissions"].get("allow"), src_perms.get("allow"))
dest["permissions"]["deny"] = union(dest["permissions"].get("deny"), src_perms.get("deny"))

# env/hooks: keep dest's if present, else take src's (never overwrite an existing one).
for key in ("env", "hooks"):
    if key not in dest and key in src:
        dest[key] = src[key]

with open(dest_path, "w", encoding="utf-8") as f:
    json.dump(dest, f, indent=2)
    f.write("\n")
PYEOF
  log "settings.json merged (permissions unioned)"
}

install_platform() {
  mkdir -p "$PLATFORM_DEST"

  if [ "$TARGET" = "cursor" ]; then
    cursor_install_platform_tree "$SRC_DIR/platform" "$PLATFORM_DEST"
    cursor_write_mcp "$PLATFORM_DEST/mcp.json"
  else
    overwrite_layer "$SRC_DIR/platform" "$PLATFORM_DEST"
    merge_settings "$SRC_DIR/platform/settings.json" "$PLATFORM_DEST/settings.json"
    cp "$SRC_DIR/platform/CLAUDE.md" "$PLATFORM_DEST/CLAUDE.md"
    log "platform → CLAUDE.md"
  fi

  # converters/ is ALWAYS copied to PLATFORM_DEST regardless of TARGET —
  # platform/scripts/setup-stacks.sh sources
  # "$PLATFORM_HOME/converters/cursor.sh" at runtime whenever a developer
  # runs /start with --target cursor for a NEW project, even from a
  # Claude-Code-installed PLATFORM_HOME (a developer can install the
  # platform once as --platform claude and still scaffold individual
  # Cursor-targeted projects with it — the converter must be reachable
  # either way). Missing this caused a real production failure: a Cursor
  # agent running /start hit "cursor.sh converter is missing" because an
  # earlier version of this script assumed .cursor/-installed platforms
  # never needed their own copy of the converter that built them — wrong,
  # since setup-stacks.sh (itself copied to BOTH targets) always looks for
  # it under PLATFORM_HOME/converters/, not under the repo checkout.
  if [ -d "$SRC_DIR/platform/converters" ]; then
    mkdir -p "$PLATFORM_DEST/converters"
    for f in "$SRC_DIR/platform/converters"/*.sh; do
      [ -f "$f" ] || continue
      cp "$f" "$PLATFORM_DEST/converters/$(basename "$f")"
      log "platform → converters/$(basename "$f")"
    done
  fi

  mkdir -p "$PLATFORM_DEST/stacks"
  for stack_dir in "$SRC_DIR/stacks"/*/; do
    [ -d "$stack_dir" ] || continue
    local stack_name; stack_name="$(basename "$stack_dir")"
    install_stack_to_platform "$stack_name"
  done
  log "All stacks installed to $PLATFORM_DEST/stacks/"
  log "Platform layer installed at $PLATFORM_DEST (target: $TARGET)"
  log "The sdlc-atlas repo folder is no longer needed at runtime."
}

install_stack() {
  local stack="$1" proj="$2" dest stack_src=""

  # Resolve stack source:
  #   1. Repo stacks/ (built-in: react, node, python, fastapi, etc.)
  #   2. PLATFORM_DEST/stacks/ (dynamically fetched via /fetch-stack)
  if [ -d "$SRC_DIR/stacks/$stack" ]; then
    stack_src="$SRC_DIR/stacks/$stack"
    # Also sync to platform home so it stays up to date
    install_stack_to_platform "$stack"
    log "Stack '$stack' installed to $PLATFORM_DEST/stacks/$stack"
  elif [ -d "$PLATFORM_DEST/stacks/$stack" ]; then
    stack_src="$PLATFORM_DEST/stacks/$stack"
    log "Stack '$stack' found in platform home (dynamically fetched) — merging into project"
  else
    die "Unknown stack '$stack'. Built-in stacks: $(ls "$SRC_DIR/stacks" | tr '\n' ' ')
  Dynamically fetched stacks live in $PLATFORM_DEST/stacks/ — run: /fetch-stack $stack"
  fi

  [ -d "$proj" ] || die "Project path not found: $proj"
  dest="$proj/$PROJECT_LAYER_DIR"; mkdir -p "$dest"

  if [ "$TARGET" = "cursor" ]; then
    cursor_install_stack_tree "$stack" "$stack_src" "$dest"
    cursor_write_mcp "$dest/mcp.json"
    log "Stack '$stack' merged into $dest/agents/, $dest/skills/, $dest/rules/ (cursor-native)"
    return 0
  fi

  # Merge stack into project layer, grouped by stack name:
  #   agents/<stack>/<agent-name>/AGENT.md
  #   skills/<stack>/<skill-name>/SKILL.md
  merge_layer "$stack_src" "$dest" "stack:$stack" "$stack"
  merge_settings "$stack_src/settings.json" "$dest/settings.json"

  grep -q "^stack:" "$dest/CLAUDE.md" 2>/dev/null || warn "Remember to declare 'stack: $stack' in $dest/CLAUDE.md"
  log "Stack '$stack' merged into $dest/agents/$stack/ and $dest/skills/$stack/"
}

install_stacks() {
  local stacks="$1" proj="$2"
  local s IFS_BAK="$IFS"
  IFS=',' read -ra STACK_ARR <<< "${stacks// /}"
  IFS="$IFS_BAK"
  for s in "${STACK_ARR[@]}"; do
    [ -n "$s" ] || continue
    install_stack "$s" "$proj"
  done
  grep -q "^stack:" "$proj/.claude/CLAUDE.md" 2>/dev/null || warn "Remember to declare 'stack: $stacks' in $proj/.claude/CLAUDE.md"
}

install_org() {
  local org="$1" proj="$2" dest
  [ -d "$org" ] || die "Org policy path not found: $org"
  dest="$proj/.claude"; mkdir -p "$dest"
  # org layer has no stack name — merge agents/skills flat (no grouping)
  merge_layer "$org" "$dest" "org" "org"
  merge_settings "$org/settings.json" "$dest/settings.json"
  log "Org policy merged into $dest. Also set 'org_policy: $org' in $dest/CLAUDE.md for traceability."
}

new_project() {
  local proj="$1" dest="$1/$PROJECT_LAYER_DIR"
  [ -e "$dest" ] && die "$dest already exists — refusing to scaffold over it"
  mkdir -p "$proj"
  if [ "$TARGET" = "cursor" ]; then
    cp -r "$SRC_DIR/projects/project-template-cursor" "$dest"
    log "Project layer scaffolded at $dest — open $dest/rules/00-platform.mdc and fill every [FILL IN]"
  else
    cp -r "$SRC_DIR/projects/project-template" "$dest"
    log "Project layer scaffolded at $dest — open $dest/CLAUDE.md and fill every [FILL IN]"
  fi
}

init_layer() {
  local layer_name="" stacks="python" profile="standard"
  while [ $# -gt 0 ]; do case "$1" in
    --stack|--stacks) stacks="$2"; shift 2;;
    --profile) profile="$2"; shift 2;;
    -*) die "unknown init-layer flag: $1";;
    *) layer_name="$1"; shift;;
  esac; done
  [ -n "$layer_name" ] || die "usage: --init-layer <name> [--stack name | --stacks fastapi,react] [--profile small|standard|enterprise]"
  bash "$SRC_DIR/tools/init-project-layer.sh" --name "$layer_name" --stacks "$stacks" --profile "$profile"
}

install_project_layer() {
  local layer_name="$1" proj="$2"
  local src="$SRC_DIR/projects/$layer_name"
  local dest="$proj/.claude"
  [ -d "$src" ] || die "Project layer 'projects/$layer_name' not found. Create it: bash install.sh --init-layer $layer_name --stack <stack>"
  [ -e "$dest" ] && die "$dest already exists — refusing to overwrite. Remove it first or merge manually."
  mkdir -p "$proj"
  cp -r "$src" "$dest"
  log "Installed projects/$layer_name → $dest"
}

list_layers() {
  printf 'Available project layers (projects/):\n'
  for d in "$SRC_DIR/projects"/*; do
    [ -d "$d" ] || continue
    local base; base="$(basename "$d")"
    [ "$base" = "project-template" ] && continue
    [ -f "$d/CLAUDE.md" ] && printf '  - %s\n' "$base" || warn "skip (no CLAUDE.md): $base"
  done
}

# ---------------------------------------------------------------------------
# audit_stacks: frontmatter conformance check for every installed stack's
# AGENT.md/SKILL.md against the canonical field set in
# platform/templates/agent_template.md and skill_template.md.
#
# Stacks generated via /fetch-stack (nextjs, react, fastapi as of this writing)
# were produced against an earlier, thinner generation template and can drift
# from the fuller frontmatter (tools, model, skills, permissionMode, maxTurns,
# effort, isolation, color) that hand-authored stacks (angular, node, python,
# angular) carry. This does not fail the install — it is a visibility report.
# ---------------------------------------------------------------------------
REQUIRED_AGENT_FIELDS="name description tools model skills permissionMode maxTurns effort isolation"
REQUIRED_SKILL_FIELDS="name description"

audit_stacks() {
  local stacks_dir="$PLATFORM_DEST/stacks"
  [ -d "$stacks_dir" ] || die "No stacks installed at $stacks_dir — run: bash install.sh --platform"

  local total=0 drifted=0
  for stack_dir in "$stacks_dir"/*/; do
    [ -d "$stack_dir" ] || continue
    local stack; stack="$(basename "$stack_dir")"
    [ "$stack" = "stack-orchestrator" ] && continue
    local stack_missing=""

    for entry in "$stack_dir/agents"/*/; do
      [ -d "$entry" ] || continue
      local f="$entry/AGENT.md"
      [ -f "$f" ] || continue
      total=$((total + 1))
      local missing=""
      for field in $REQUIRED_AGENT_FIELDS; do
        grep -qE "^${field}:" "$f" || missing="$missing $field"
      done
      [ -n "$missing" ] && stack_missing="$stack_missing\n    agents/$(basename "$entry")/AGENT.md — missing:$missing"
    done

    for entry in "$stack_dir/skills"/*/; do
      [ -d "$entry" ] || continue
      local f="$entry/SKILL.md"
      [ -f "$f" ] || continue
      total=$((total + 1))
      local missing=""
      for field in $REQUIRED_SKILL_FIELDS; do
        grep -qE "^${field}:" "$f" || missing="$missing $field"
      done
      [ -n "$missing" ] && stack_missing="$stack_missing\n    skills/$(basename "$entry")/SKILL.md — missing:$missing"
    done

    if [ -n "$stack_missing" ]; then
      drifted=$((drifted + 1))
      warn "stack '$stack' has frontmatter drift:"
      printf "%b\n" "$stack_missing"
    else
      log "stack '$stack' conforms to the current agent/skill template"
    fi
  done

  printf '\n'
  if [ "$drifted" -gt 0 ]; then
    warn "$drifted stack(s) drifted from the current template ($total files checked)."
    warn "Regenerate a drifted stack with: /fetch-stack <name>  (overwrites that stack only)"
  else
    log "All installed stacks conform ($total files checked)."
  fi
}

# ---------------------------------------------------------------------------
# sync_project: re-copies the CURRENT platform + declared stack(s) into an
# EXISTING project's .claude/ layer. Always overwrites capability files
# (agents/skills/commands/settings.json). Never touches project-owned state:
# CLAUDE.md, knowledge.md, memory/, specs/, proposals/.
#
# This is the fix for "platform updated, project still running old copies" —
# install_stack()/install_platform() only ever ran once per project at setup
# time; nothing re-synced them after. Run this any time platform/ changes.
# ---------------------------------------------------------------------------
sync_project() {
  local proj="$1" dest
  [ -d "$proj" ] || die "Project path not found: $proj"
  dest="$proj/$PROJECT_LAYER_DIR"

  if [ "$TARGET" = "cursor" ]; then
    [ -f "$dest/rules/00-platform.mdc" ] || die "No $dest/rules/00-platform.mdc — this is not an initialized cursor project. Run --new-project --target cursor first."
    printf '\n-- syncing cursor platform tree (agents/skills/commands/rules) --\n'
    cursor_install_platform_tree "$SRC_DIR/platform" "$dest"
    cursor_write_mcp "$dest/mcp.json"

    printf '\n-- syncing declared stack(s) --\n'
    local raw_stacks; raw_stacks="$( { grep -E "^- primary:|^stack:" "$dest/rules/00-platform.mdc" 2>/dev/null || true; } | sed -E 's/.*(primary|stack):[[:space:]]*//' | tr -s ' \n' ' ')"
    if [ -z "$raw_stacks" ]; then
      warn "No stack declared in $dest/rules/00-platform.mdc — skipping stack sync."
    else
      for s in $raw_stacks; do
        s="$(echo "$s" | xargs)"
        [ -n "$s" ] && [ "$s" != "none" ] || continue
        if [ -d "$SRC_DIR/stacks/$s" ] || [ -d "$PLATFORM_DEST/stacks/$s" ]; then
          install_stack "$s" "$proj"
        else
          warn "stack '$s' declared but not found in repo stacks/ or $PLATFORM_DEST/stacks/ — skipped"
        fi
      done
    fi

    log "Project synced with current platform (cursor target): $dest"
    log "Untouched (project-owned): rules/00-platform.mdc, knowledge.md, memory/, proposals/"
    return 0
  fi

  dest="$proj/.claude"
  [ -f "$dest/CLAUDE.md" ] || die "No $dest/CLAUDE.md — this is not an initialized project. Run --new-project or /start first."

  printf '\n-- syncing platform agents (flat) --\n'
  mkdir -p "$dest/agents"
  local n=0
  for f in "$SRC_DIR/platform/agents"/*.md; do
    [ -f "$f" ] || continue
    local base; base="$(basename "$f")"
    cp "$f" "$dest/agents/$base"
    n=$((n + 1))
  done
  log "$n platform agent(s) synced → $dest/agents/"

  printf '\n-- syncing platform commands + skills --\n'
  mkdir -p "$dest/commands" "$dest/skills/platform"
  local cn=0 sn=0
  for f in "$SRC_DIR/platform/commands"/*.md; do
    [ -f "$f" ] || continue
    cp "$f" "$dest/commands/$(basename "$f")"
    cn=$((cn + 1))
  done
  for f in "$SRC_DIR/platform/skills"/*.md; do
    [ -f "$f" ] || continue
    cp "$f" "$dest/skills/platform/$(basename "$f")"
    sn=$((sn + 1))
  done
  for dir in "$SRC_DIR/platform/skills"/*/; do
    [ -d "$dir" ] || continue
    local sname; sname="$(basename "$dir")"
    [ -f "$dir/SKILL.md" ] || continue
    mkdir -p "$dest/skills/platform/$sname"
    cp "$dir/SKILL.md" "$dest/skills/platform/$sname/SKILL.md"
    cp "$dir/SKILL.md" "$dest/skills/platform/${sname}.md" 2>/dev/null || true
    sn=$((sn + 1))
  done
  log "$cn platform command(s) synced → $dest/commands/"
  log "$sn platform skill(s) synced → $dest/skills/platform/"

  printf '\n-- syncing declared stack(s) --\n'
  local raw_stacks; raw_stacks="$( { grep -E "^\s+(primary|additions):" "$dest/CLAUDE.md" 2>/dev/null || true; } | sed -E 's/.*(primary|additions):[[:space:]]*//; s/[][,]/ /g; s/#.*//' | tr -s ' \n' ' ')"
  # Older CLAUDE.md format: "stacks: [react]" or "stack: react" (no nested block)
  if [ -z "$raw_stacks" ]; then
    raw_stacks="$( { grep -E "^stacks?:" "$dest/CLAUDE.md" 2>/dev/null || true; } | sed -E 's/^stacks?:[[:space:]]*//; s/[][,]/ /g; s/#.*//' | tr -s ' \n' ' ')"
  fi
  if [ -z "$raw_stacks" ]; then
    warn "No stack declared in $dest/CLAUDE.md § Stack declaration — skipping stack sync."
  else
    for s in $raw_stacks; do
      s="$(echo "$s" | tr -d '{}' | xargs)"
      [ -n "$s" ] && [ "$s" != "none" ] || continue
      if [ -d "$SRC_DIR/stacks/$s" ] || [ -d "$PLATFORM_DEST/stacks/$s" ]; then
        install_stack "$s" "$proj"
      else
        warn "stack '$s' declared but not found in repo stacks/ or $PLATFORM_DEST/stacks/ — skipped"
      fi
    done
  fi

  printf '\n-- syncing settings.json (platform base) --\n'
  merge_settings "$SRC_DIR/platform/settings.json" "$dest/settings.json"

  log "Project synced with current platform: $dest"
  log "Untouched (project-owned): CLAUDE.md, knowledge.md, memory/, specs/, proposals/"
  log "Run: bash install.sh --doctor \"$proj\"  to verify."
}

doctor_cursor() {
  local d="$1/.cursor" ok=1
  [ -d "$d" ] || die "No .cursor/ at $1"
  [ -f "$d/rules/00-platform.mdc" ] || { warn "missing rules/00-platform.mdc"; ok=0; }
  grep -qE "^> Profile: (small|standard|enterprise)" "$d/rules/00-platform.mdc" 2>/dev/null || { warn "rules/00-platform.mdc missing 'Profile:' (small|standard|enterprise)"; ok=0; }
  [ -d "$d/agents" ] && [ -n "$(ls -A "$d/agents" 2>/dev/null)" ] || warn "no agents/ files — run --sync-project --target cursor"
  [ -d "$d/skills" ] || warn "no skills/ dir"
  [ -d "$d/commands" ] || warn "no commands/ dir"
  [ -d "$d/rules" ] || warn "no rules/ dir"
  [ -f "$d/mcp.json" ] || warn "no mcp.json"
  local fills; fills="$(grep -rl '\[FILL IN\]' "$d" 2>/dev/null || true)"
  if [ -n "$fills" ]; then
    while IFS= read -r f; do warn "unfilled placeholder in $f"; done <<< "$fills"
    ok=0
  fi
  [ -d "$d/proposals" ] || warn "no proposals/ dir — /propose will create it on first use"
  [ "$ok" = 1 ] && log "Cursor project layer looks healthy" || die "Fix the warnings above"
}

doctor() {
  if [ "$TARGET" = "cursor" ]; then
    doctor_cursor "$1"
    return 0
  fi
  local d="$1/.claude" ok=1
  [ -d "$d" ] || die "No .claude/ at $1"
  [ -f "$d/CLAUDE.md" ] || { warn "missing CLAUDE.md"; ok=0; }
  grep -qE "profile:[[:space:]]*(small|standard|enterprise)" "$d/CLAUDE.md" 2>/dev/null || { warn "CLAUDE.md missing 'profile:' (small|standard|enterprise)"; ok=0; }
  # Project layer: stack agents/skills are grouped by stack name
  #   agents/<stack>/<agent-name>/AGENT.md — every leaf subfolder must contain AGENT.md
  #   skills/<stack>/<skill-name>/SKILL.md — every leaf subfolder must contain SKILL.md
  if [ -d "$d/agents" ]; then
    for stack_dir in "$d/agents"/*/; do
      [ -d "$stack_dir" ] || continue
      # check if this is a stack group (contains subfolders) or a flat project agent
      if find "$stack_dir" -mindepth 1 -type d | grep -q .; then
        # stack group — each subfolder must have AGENT.md
        for agent_dir in "$stack_dir"/*/; do
          [ -d "$agent_dir" ] || continue
          [ -f "$agent_dir/AGENT.md" ] || { warn "agents/$(basename "$stack_dir")/$(basename "$agent_dir")/ missing AGENT.md"; ok=0; }
        done
      else
        # flat project agent — must have AGENT.md directly (or be a .md file — handled below)
        [ -f "$stack_dir/AGENT.md" ] || { warn "agents/$(basename "$stack_dir")/ missing AGENT.md"; ok=0; }
      fi
    done
  fi
  if [ -d "$d/skills" ]; then
    for stack_dir in "$d/skills"/*/; do
      [ -d "$stack_dir" ] || continue
      # skills/platform/ is a flat bag of platform-skill .md files (synced by
      # --sync-project), not a stack group or a single SKILL.md-named skill.
      [ "$(basename "$stack_dir")" = "platform" ] && continue
      if find "$stack_dir" -mindepth 1 -type d | grep -q .; then
        for skill_dir in "$stack_dir"/*/; do
          [ -d "$skill_dir" ] || continue
          [ -f "$skill_dir/SKILL.md" ] || { warn "skills/$(basename "$stack_dir")/$(basename "$skill_dir")/ missing SKILL.md"; ok=0; }
        done
      else
        [ -f "$stack_dir/SKILL.md" ] || { warn "skills/$(basename "$stack_dir")/ missing SKILL.md"; ok=0; }
      fi
    done
  fi
  local fills; fills="$(grep -rl '\[FILL IN\]' "$d" 2>/dev/null || true)"
  if [ -n "$fills" ]; then
    while IFS= read -r f; do warn "unfilled placeholder in $f"; done <<< "$fills"
    ok=0
  fi
  [ -d "$d/proposals" ] || warn "no proposals/ dir — /propose will create it on first use"
  local raw_stack; raw_stack="$( { grep -E "^\s+primary:" "$d/CLAUDE.md" 2>/dev/null || true; } | head -1 | sed 's/.*primary:[[:space:]]*//' | sed 's/[[:space:]]*#.*//' | tr -d '{}' | xargs)"
  if [ -n "$raw_stack" ] && [[ "$raw_stack" != \{\{* ]]; then
    [ -f "$PLATFORM_DEST/stacks/${raw_stack}/STACK.md" ] || \
      warn "stack '$raw_stack' declared but $PLATFORM_DEST/stacks/${raw_stack}/ is missing — run: bash install.sh --stack $raw_stack --project $1"
  fi
  [ "$ok" = 1 ] && log "Project layer looks healthy" || die "Fix the warnings above"

  printf '\n  -- missing platform agents (informational) --\n'
  local missing_agents=0
  for src in "$SRC_DIR/platform/agents"/*.md; do
    [ -f "$src" ] || continue
    local base; base="$(basename "$src")"
    [ -f "$d/agents/$base" ] || { warn "agents/$base is MISSING from this project (present in platform source, never synced) — run: bash install.sh --sync-project $1"; missing_agents=$((missing_agents + 1)); }
  done
  if [ "$missing_agents" -eq 0 ]; then
    log "No missing platform agents — every platform/agents/*.md is present in this project."
  else
    warn "$missing_agents platform agent(s) missing entirely from this project (a gate like qa-agent may silently not run/route correctly without it)."
  fi

  printf '\n  -- staleness vs current platform source (informational) --\n'
  local stale=0 checked=0
  if [ -d "$d/agents" ]; then
    for f in "$d/agents"/*.md; do
      [ -f "$f" ] || continue
      local base; base="$(basename "$f")"
      local src="$SRC_DIR/platform/agents/$base"
      [ -f "$src" ] || continue
      checked=$((checked + 1))
      cmp -s "$f" "$src" || { warn "agents/$base differs from platform source (stale)"; stale=$((stale + 1)); }
    done
  fi
  if [ -d "$d/commands" ]; then
    for f in "$d/commands"/*.md; do
      [ -f "$f" ] || continue
      local base; base="$(basename "$f")"
      local src="$SRC_DIR/platform/commands/$base"
      [ -f "$src" ] || continue
      checked=$((checked + 1))
      cmp -s "$f" "$src" || { warn "commands/$base differs from platform source (stale)"; stale=$((stale + 1)); }
    done
  fi
  if [ -d "$d/skills/platform" ]; then
    for f in "$d/skills/platform"/*.md; do
      [ -f "$f" ] || continue
      local base; base="$(basename "$f")"
      local sname="${base%.md}"
      local src="$SRC_DIR/platform/skills/$sname/SKILL.md"
      [ -f "$src" ] || src="$SRC_DIR/platform/skills/$base"
      [ -f "$src" ] || continue
      checked=$((checked + 1))
      cmp -s "$f" "$src" || { warn "skills/platform/$base differs from platform source (stale)"; stale=$((stale + 1)); }
    done
  fi
  if [ "$stale" -gt 0 ]; then
    warn "$stale of $checked platform-sourced file(s) are stale. Run: bash install.sh --sync-project $1"
  else
    log "All $checked platform-sourced file(s) match current platform source."
  fi

  printf '\n  -- stack conformance (informational, does not affect health above) --\n'
  audit_stacks || true
}

case "${1:-}" in
  --platform)      install_platform ;;
  --stack)         [ $# -ge 4 ] && [ "$3" = "--project" ] || die "usage: --stack <name> --project <path>"; install_stack "$2" "$(proj_root "$4")" ;;
  --stacks)        [ $# -ge 4 ] && [ "$3" = "--project" ] || die "usage: --stacks <fastapi,react> --project <path>"; install_stacks "$2" "$(proj_root "$4")" ;;
  --org)           [ $# -ge 4 ] && [ "$3" = "--project" ] || die "usage: --org <path> --project <path>"; install_org "$2" "$(proj_root "$4")" ;;
  --new-project)   [ $# -ge 2 ] || die "usage: --new-project <path>"; new_project "$(proj_root "$2")" ;;
  --init-layer)    shift; init_layer "$@" ;;
  --project-layer) [ $# -ge 4 ] && [ "$3" = "--project" ] || die "usage: --project-layer <name> --project <path>"; install_project_layer "$2" "$(proj_root "$4")" ;;
  --list-layers)   list_layers ;;
  --doctor)        [ $# -ge 2 ] || die "usage: --doctor <path>"; doctor "$(proj_root "$2")" ;;
  --sync-project)  [ $# -ge 2 ] || die "usage: --sync-project <path>"; sync_project "$(proj_root "$2")" ;;
  --audit-stacks)  audit_stacks ;;
  *)               sed -n '2,12p' "$0"; exit 1 ;;
esac
