# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
# shellcheck shell=bash
# platform/converters/cursor.sh
# Sourced by install.sh when TARGET=cursor. Transforms the same platform/
# and stacks/ source-of-truth files into Cursor's native project shape, per
# Cursor's documented spec (cursor.com/docs/context/{rules,skills,subagents,mcp}
# — verified against the live docs, not just inferred):
#   agents/<name>.md            (flat; frontmatter: name, description, model,
#                                 readonly, is_background — matches Cursor's
#                                 Subagents spec field-for-field)
#   skills/<name>/SKILL.md      (frontmatter: name [MUST equal parent folder
#                                 name — Cursor requires this], description,
#                                 paths [glob(s), string or list],
#                                 disable-model-invocation [bool])
#   rules/<name>.mdc            (frontmatter: description, globs, alwaysApply)
#   mcp.json                    ({"mcpServers": {...}})
#
# COMMANDS ARE NOT A SEPARATE CURSOR-NATIVE OUTPUT. Cursor's own docs
# (cursor.com/docs/skills.md, the /migrate-to-skills reference) describe
# custom slash commands as LEGACY: "Slash commands: Both user-level and
# workspace-level commands are converted to skills with
# disable-model-invocation: true, preserving their explicit invocation
# behavior." This converter follows that same guidance — every platform/stack
# command becomes a Skill with disable-model-invocation: true (explicit
# /name invocation only, never auto-triggered), not a file under a
# .cursor/commands/ directory that Cursor's current docs no longer document
# as the primary mechanism. See cursor_write_command_as_skill() below.
#
# Never call cp() directly for these categories under target=cursor — always
# go through the cursor_write_* functions below so frontmatter stays valid.

_cursor_read_field() {
  # $1=file $2=field -> prints the value of a top-level "field: ..." frontmatter
  # line, folded to a single line. Handles plain scalars ("field: value") and
  # YAML block scalars ("field: >-" or "field: |-" followed by indented lines)
  # by collecting the indented continuation and joining it with spaces.
  #
  # BUG FIX (found via a real install.sh --platform cursor dry-run test):
  # the closing "---" frontmatter delimiter was matched by the FIRST awk rule
  # before the "still collecting a block scalar" rule got a chance to flush
  # its buffer — so any command/skill file whose description used a `>-`/`|-`
  # block scalar (e.g. platform/commands/start.md) silently lost its
  # description on conversion. Fixed: the "---" rule now flushes a pending
  # block-scalar buffer before incrementing d.
  local file="$1" field="$2"
  awk -v f="$field" '
    /^---$/ {
      if (collecting) { print buf; collecting=0 }
      d++; next
    }
    d==1 && $0 ~ "^"f":[[:space:]]*[>|]" { collecting=1; buf=""; next }
    d==1 && collecting {
      if ($0 ~ "^[[:space:]]") { sub(/^[[:space:]]+/, ""); buf = buf (buf == "" ? "" : " ") $0; next }
      else { print buf; collecting=0 }
    }
    d==1 && !collecting && $0 ~ "^"f":" { sub("^"f":[[:space:]]*", ""); print; exit }
  ' "$file"
}

_cursor_read_body() {
  # $1=file -> prints everything after the second "---" frontmatter delimiter
  awk 'BEGIN{d=0} /^---$/{d++; next} d>=2{print}' "$1"
}

# ---------------------------------------------------------------------------
# _cursor_rewrite_start_for_cursor: text-substitution pass applied ONLY to
# the converted /start skill body (see cursor_write_command_as_skill above).
# Three sections in the Claude Code source are Claude-Code-CLI-specific and
# must be REPLACED, not path-swapped, because this converted copy only ever
# exists inside a .cursor/ tree (TARGET=cursor is a build-time fact here,
# never something to runtime-detect — a real bug was found in production
# where an LLM running this skill under Cursor mis-detected and searched
# .claude/ paths instead, because the source prose mentions "Claude Code"
# and ".claude" repeatedly before the ambiguous self-detection ever resolves):
#   1. "## Step 0 — Caveman check" — a Claude Code plugin concept
#      ($HOME/.claude/.caveman-active, "restart Claude Code") with no Cursor
#      equivalent. Removed entirely, replaced by one combined roots step.
#   2. "## Step 0b — Establish roots" — replaced with the same roots step
#      but TARGET/LAYER_DIR hardcoded to cursor/.cursor instead of the
#      runtime self-detection block.
#   3. "## Step 0c — QA tooling check" — entirely built around the `claude
#      mcp` CLI subcommand, which does not exist under Cursor. Replaced with
#      a short note pointing at Cursor's own .cursor/mcp.json mechanism.
# $1=body text.
# ---------------------------------------------------------------------------
_cursor_rewrite_start_for_cursor() {
  local body="$1"
  awk '
    BEGIN { mode="pass" }
    /^## Step 0 — Caveman check/ {
      mode="skip"
      print "## Step 0 — Establish roots"
      print ""
      print "Run:"
      print ""
      print "```bash"
      print "pwd"
      print "echo \"$HOME/.cursor\""
      print "```"
      print ""
      print "- **PROJECT_ROOT** = first output (overridden by developer'\''s Q1 answer)"
      print "- **PLATFORM_HOME** = second output"
      print ""
      print "**TARGET = `cursor` (fixed fact — this skill only exists inside a `.cursor/` tree, never runtime-detected).**"
      print "**LAYER_DIR = `.cursor` (fixed fact, same reason).**"
      print "Every `.claude/` path referenced anywhere below in this document means `PROJECT_ROOT/.cursor/...`."
      print ""
      print "---"
      next
    }
    mode=="skip" && /^## Step 0c — QA tooling check/ {
      mode="skip_qa"
      print "## Step 0c — QA tooling check"
      print ""
      print "This platform requires live browser/mobile QA tooling before building a"
      print "frontend (qa-agent'\''s E2E Journey + per-screen audit, Phase 5a). Under"
      print "Cursor, QA tooling is configured via `.cursor/mcp.json` directly (see"
      print "Cursor'\''s MCP docs), not via the `claude mcp` CLI subcommand this check"
      print "uses on Claude Code. Print once: `[start] QA tooling (Chrome DevTools /"
      print "Maestro) must be configured via .cursor/mcp.json for this host — the"
      print "automated claude-mcp-based install/check this platform uses on Claude"
      print "Code does not apply under Cursor. See your project'\''s .cursor/mcp.json"
      print "and add the required MCP servers manually, then continue.` Then proceed"
      print "to Step 1 — this is advisory, not a blocking gate, under Cursor."
      print ""
      print "---"
      next
    }
    mode=="skip" { next }
    mode=="skip_qa" && /^## Step 1/ { mode="pass"; print; next }
    mode=="skip_qa" { next }
    { print }
  ' <<< "$body"
}

_cursor_yaml_quote() {
  # $1=value -> double-quoted YAML scalar, safe for values containing ':', '"', etc.
  local v="$1"
  v="${v//\\/\\\\}"
  v="${v//\"/\\\"}"
  printf '"%s"' "$v"
}

# ---------------------------------------------------------------------------
# cursor_agent_readonly: heuristic — review/security/test/QA/sonar/audit
# agents never write production code, so mark them readonly in Cursor.
# ---------------------------------------------------------------------------
_cursor_agent_readonly() {
  case "$1" in
    review-agent|security-agent|test-agent|sonar-agent|qa-agent|acceptance-agent|intake-assessment-agent) echo "true" ;;
    *) echo "false" ;;
  esac
}

# ---------------------------------------------------------------------------
# cursor_write_agent: src AGENT.md/agent .md -> dest agents/<flat-name>.md
# $1=src file  $2=dest dir  $3=flat name (e.g. "django-api-agent" or "orchestrator")
# ---------------------------------------------------------------------------
cursor_write_agent() {
  local src="$1" dest_dir="$2" flat_name="$3"
  # `readonly` is a shell builtin, so `local ... readonly` (SC2316) declared a variable
  # that shadows it. Renamed to ro_flag; it IS used below, so it must stay function-local.
  local name desc skills_list body ro_flag
  name="$(_cursor_read_field "$src" name)"
  [ -n "$name" ] || name="$flat_name"
  desc="$(_cursor_read_field "$src" description)"
  skills_list="$(awk '/^skills:/{f=1;next} f && /^  - /{sub(/^  - /,""); print} f && !/^  - /{exit}' "$src")"
  ro_flag="$(_cursor_agent_readonly "$flat_name")"
  body="$(_cursor_read_body "$src")"

  mkdir -p "$dest_dir"
  {
    echo "---"
    echo "name: $flat_name"
    echo "description: $(_cursor_yaml_quote "$desc")"
    echo "model: inherit"
    echo "readonly: $ro_flag"
    echo "is_background: false"
    echo "---"
    echo ""
    echo "$body"
    if [ -n "$skills_list" ]; then
      echo ""
      echo "## Referenced skills (Claude platform concept — read for context, not auto-loaded)"
      while IFS= read -r s; do
        [ -n "$s" ] && echo "- $s"
      done <<< "$skills_list"
    fi
  } > "$dest_dir/$flat_name.md"
  log "cursor: agents/$flat_name.md"
}

# ---------------------------------------------------------------------------
# cursor_write_skill: src SKILL.md -> dest skills/<name>/SKILL.md
# $1=src file  $2=dest skills root  $3=name  $4=optional glob (stack scoping)
# $5=disable-model-invocation (true/false, default false)
#
# Cursor REQUIRES `name` in frontmatter to exactly match the parent folder
# name (skills/<name>/SKILL.md — name: <name>, not the src file's own `name`
# field, which may differ from the flattened/prefixed folder name we choose
# here, e.g. "${stack}-${skill_name}"). Always write the $3 argument as both
# the folder name AND the frontmatter `name` — never the src file's own name.
# ---------------------------------------------------------------------------
cursor_write_skill() {
  local src="$1" dest_root="$2" name="$3" globs="${4:-}" disable_invoke="${5:-false}"
  local desc body
  desc="$(_cursor_read_field "$src" description)"
  body="$(_cursor_read_body "$src")"

  mkdir -p "$dest_root/$name"
  {
    echo "---"
    echo "name: $name"
    echo "description: $(_cursor_yaml_quote "$desc")"
    [ -n "$globs" ] && echo "paths: [\"$globs\"]"
    [ "$disable_invoke" = "true" ] && echo "disable-model-invocation: true"
    echo "---"
    echo ""
    echo "$body"
  } > "$dest_root/$name/SKILL.md"
  log "cursor: skills/$name/SKILL.md"
}

# ---------------------------------------------------------------------------
# cursor_write_command_as_skill: src command .md -> dest skills/<name>/SKILL.md
# with disable-model-invocation: true.
#
# Per Cursor's documented migration path (cursor.com/docs/skills.md):
# "Slash commands: Both user-level and workspace-level commands are
# converted to skills with disable-model-invocation: true, preserving their
# explicit invocation behavior." A platform/stack command (e.g. /start,
# /qa, /feature) is functionally identical to that legacy-commands
# description — explicit-invocation-only, never auto-triggered by the
# agent's own judgment — so it converts the same way. Never write to a
# `commands/` directory; Cursor's current docs do not document that as the
# primary path for custom invocable prompts.
# $1=src command file  $2=dest skills root  $3=name (folder name = frontmatter name)
# ---------------------------------------------------------------------------
cursor_write_command_as_skill() {
  local src="$1" dest_root="$2" name="$3"
  local desc body
  desc="$(_cursor_read_field "$src" description)"
  [ -n "$desc" ] || desc="Converted from sdlc-atlas platform command /$name"
  body="$(_cursor_read_body "$src")"
  # Commands are plain prompt markdown with no "---"-delimited frontmatter
  # body split the way agents/skills have — if _cursor_read_body found
  # nothing (no second "---"), the whole file IS the body.
  [ -n "$body" ] || body="$(cat "$src")"

  # /start is a SPECIAL CASE: its source prose asks the running agent to
  # self-detect "am I Claude Code or Cursor?" at runtime and branch on a
  # TARGET/LAYER_DIR variable — a real production bug found via manual
  # testing: an LLM running as this converted Cursor skill mis-detected and
  # searched/read .claude/ paths instead of .cursor/ paths, because the
  # source prose has "Claude Code" and ".claude" mentioned repeatedly before
  # the ambiguous self-detection instruction ever resolves. Since this
  # converted file is a SEPARATE physical copy that only ever exists inside
  # a .cursor/ tree, TARGET=cursor is a build-time FACT here, not something
  # to runtime-detect — bake it in, no ambiguity possible.
  if [ "$name" = "start" ]; then
    body="$(_cursor_rewrite_start_for_cursor "$body")"
  fi

  mkdir -p "$dest_root/$name"
  {
    echo "---"
    echo "name: $name"
    echo "description: $(_cursor_yaml_quote "$desc")"
    echo "disable-model-invocation: true"
    echo "---"
    echo ""
    echo "$body"
  } > "$dest_root/$name/SKILL.md"
  log "cursor: skills/$name/SKILL.md (from command, explicit-invoke only)"
}

# ---------------------------------------------------------------------------
# cursor_write_rule: wraps a plain markdown file (e.g. CLAUDE.md, STACK.md)
# as a Cursor rule. $1=src file  $2=dest rules dir  $3=rule filename (no ext)
# $4=alwaysApply (true/false)  $5=optional globs
# ---------------------------------------------------------------------------
cursor_write_rule() {
  local src="$1" dest_dir="$2" rule_name="$3" always="$4" globs="${5:-}"
  mkdir -p "$dest_dir"
  {
    echo "---"
    echo "description: ${rule_name} (converted from sdlc-atlas platform source)"
    [ -n "$globs" ] && echo "globs: [\"$globs\"]"
    echo "alwaysApply: $always"
    echo "---"
    echo ""
    cat "$src"
  } > "$dest_dir/$rule_name.mdc"
  log "cursor: rules/$rule_name.mdc"
}

# ---------------------------------------------------------------------------
# cursor_stack_glob: rough file-extension glob per stack, used to scope
# stack rules/skills so Cursor only auto-attaches them in relevant files.
# ---------------------------------------------------------------------------
cursor_stack_glob() {
  case "$1" in
    django|fastapi|python) echo "**/*.py" ;;
    angular|react|react-native|nextjs|vue|sveltekit|node|nestjs) echo "**/*.{ts,tsx,js,jsx}" ;;
    dotnet) echo "**/*.cs" ;;
    android-kotlin) echo "**/*.kt" ;;
    ios-swift) echo "**/*.swift" ;;
    go) echo "**/*.go" ;;
    spring-boot) echo "**/*.java" ;;
    terraform) echo "**/*.tf" ;;
    docker|kubernetes) echo "**/{Dockerfile,*.yaml,*.yml}" ;;
    *) echo "" ;;
  esac
}

# ---------------------------------------------------------------------------
# _cursor_copy_passthrough_dirs: copies directories that have NO Cursor-native
# frontmatter conversion concept at all — templates/, profiles/, scripts/,
# bin/ are plain internal platform files (markdown templates, shell scripts,
# Python tooling) referenced by path from other scripts (setup-stacks.sh,
# run-gates.sh, etc.), not agent/skill/command definitions. These copy
# byte-identically regardless of TARGET — there is nothing Cursor-specific
# to convert here, only agents/skills/commands/CLAUDE.md have Cursor-native
# frontmatter shapes. Mirrors the same sub-directory list overwrite_layer()
# uses for TARGET=claude, minus agents/skills/commands/converters (converters/
# is platform-internal to this converter itself, not a project asset — it's
# copied separately, once, by overwrite_layer's own claude-target pass; a
# .cursor/ install has no runtime need for a *second* copy of the converter
# script that produced it).
# $1=src platform dir  $2=dest root
# ---------------------------------------------------------------------------
_cursor_copy_passthrough_dirs() {
  local src="$1" dest="$2"
  for sub in templates profiles scripts bin; do
    [ -d "$src/$sub" ] || continue
    mkdir -p "$dest/$sub"
    # Prune stale files first (same reasoning as overwrite_layer's prune —
    # a renamed/deleted platform source file must not linger at $dest forever).
    for f in "$dest/$sub"/*.md "$dest/$sub"/*.sh "$dest/$sub"/*.json "$dest/$sub"/*.py "$dest/$sub"/*.html; do
      [ -f "$f" ] || continue
      local base; base="$(basename "$f")"
      [ -f "$src/$sub/$base" ] || { rm -f "$f"; log "cursor: pruned stale $sub/$base"; }
    done
    for f in "$src/$sub"/*.md "$src/$sub"/*.sh "$src/$sub"/*.json "$src/$sub"/*.py "$src/$sub"/*.html; do
      [ -f "$f" ] || continue
      local base; base="$(basename "$f")"
      cp "$f" "$dest/$sub/$base"
      log "cursor: $sub/$base (passthrough, no conversion needed)"
    done
  done
}

# ---------------------------------------------------------------------------
# _cursor_prune_converted: deletes converted agent/skill outputs at $dest
# whose source no longer exists — same staleness problem as
# _cursor_copy_passthrough_dirs' prune, but for the frontmatter-converted
# categories (agents/*.md flat files, skills/<name>/ directories). Commands
# and platform-agent skills share the skills/ namespace, so this prunes by
# comparing the FULL expected set (agents ∪ commands-as-skills) against
# what's actually on disk, rather than pruning per-source-category, to avoid
# a command-derived skill being wrongly deleted by the agents pass or
# vice versa. $1=src platform dir  $2=dest root
# ---------------------------------------------------------------------------
_cursor_prune_converted_platform() {
  local src="$1" dest="$2"
  local expected_agent expected_skill f base

  if [ -d "$dest/agents" ]; then
    for f in "$dest/agents"/*.md; do
      [ -f "$f" ] || continue
      base="$(basename "$f" .md)"
      [ -f "$src/agents/$base.md" ] || { rm -f "$f"; log "cursor: pruned stale agents/$base.md"; }
    done
  fi

  if [ -d "$dest/skills" ]; then
    for f in "$dest/skills"/*/; do
      [ -d "$f" ] || continue
      base="$(basename "$f")"
      # A platform skill's source is skills/<name>.md; a command-derived
      # skill's source is commands/<name>.md. Either satisfies "not stale".
      if [ ! -f "$src/skills/$base.md" ] && [ ! -f "$src/commands/$base.md" ]; then
        rm -rf "$f"; log "cursor: pruned stale skills/$base/"
      fi
    done
  fi
}

# ---------------------------------------------------------------------------
# cursor_install_platform_tree: mirrors overwrite_layer() for target=cursor.
# Reads platform/{agents,skills,commands,templates,profiles,scripts,bin} and
# platform/CLAUDE.md, writes the Cursor-native equivalents under $dest
# (PLATFORM_DEST for --platform cursor, or a project's .cursor/ for
# project-layer syncs).
# ---------------------------------------------------------------------------
cursor_install_platform_tree() {
  local src="$1" dest="$2"

  _cursor_prune_converted_platform "$src" "$dest"

  for f in "$src/agents"/*.md; do
    [ -f "$f" ] || continue
    local base; base="$(basename "$f" .md)"
    cursor_write_agent "$f" "$dest/agents" "$base"
  done

  for f in "$src/skills"/*.md; do
    [ -f "$f" ] || continue
    local base; base="$(basename "$f" .md)"
    cursor_write_skill "$f" "$dest/skills" "$base"
  done

  for f in "$src/commands"/*.md; do
    [ -f "$f" ] || continue
    local cmd_name; cmd_name="$(basename "$f" .md)"
    cursor_write_command_as_skill "$f" "$dest/skills" "$cmd_name"
  done

  if [ -f "$src/CLAUDE.md" ]; then
    cursor_write_rule "$src/CLAUDE.md" "$dest/rules" "00-platform" "true"
  fi

  _cursor_copy_passthrough_dirs "$src" "$dest"
}

# ---------------------------------------------------------------------------
# cursor_install_stack_tree: mirrors install_stack_to_platform()/merge_layer()
# for target=cursor. $1=stack name  $2=stack src dir  $3=dest root
# Agent/skill names are prefixed with the stack to avoid collisions once
# flattened (Cursor agents/skills are not grouped by stack the way our
# .claude/ project layer is).
# ---------------------------------------------------------------------------
cursor_install_stack_tree() {
  local stack="$1" src="$2" dest="$3"
  local glob; glob="$(cursor_stack_glob "$stack")"

  for entry in "$src/agents"/*/; do
    [ -d "$entry" ] || continue
    local agent_name; agent_name="$(basename "$entry")"
    local f="$entry/AGENT.md"
    [ -f "$f" ] || continue
    cursor_write_agent "$f" "$dest/agents" "${stack}-${agent_name}"
  done

  for entry in "$src/skills"/*/; do
    [ -d "$entry" ] || continue
    local skill_name; skill_name="$(basename "$entry")"
    local f="$entry/SKILL.md"
    [ -f "$f" ] || continue
    cursor_write_skill "$f" "$dest/skills" "${stack}-${skill_name}" "$glob"
  done

  for f in "$src/commands"/*; do
    [ -f "$f" ] || continue
    local cmd_name; cmd_name="${stack}-$(basename "$f" .md)"
    cursor_write_command_as_skill "$f" "$dest/skills" "$cmd_name"
  done

  if [ -f "$src/STACK.md" ]; then
    cursor_write_rule "$src/STACK.md" "$dest/rules" "$stack" "false" "$glob"
  fi
}

# ---------------------------------------------------------------------------
# cursor_write_mcp: writes (or merges) mcp.json at $2 from a settings.json-
# style permissions file at $1 — currently only emits an empty mcpServers
# skeleton since no MCP servers are declared in platform/stacks settings.json
# today. Left as an explicit extension point for when stacks start declaring
# MCP servers (e.g. a "mcpServers" key in settings.json).
# ---------------------------------------------------------------------------
cursor_write_mcp() {
  local dest="$1"
  [ -f "$dest" ] && return 0
  mkdir -p "$(dirname "$dest")"
  printf '{\n  "mcpServers": {}\n}\n' > "$dest"
  log "cursor: mcp.json (skeleton)"
}
