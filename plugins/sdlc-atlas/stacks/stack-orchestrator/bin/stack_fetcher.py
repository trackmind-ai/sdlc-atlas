#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
"""
stack_fetcher.py — parallel full-stack installer for the stack-orchestrator.

Modes:
  stack_fetcher.py <stack> [<stack2> ...]   Fetch raw sources for one or more stacks.
                                             Sources are written to:
                                               PLATFORM_HOME/stacks/<stack>/raw-sources.md
                                             All stacks are fetched in parallel.
                                             Claude then reads the raw file and authors
                                             the complete stack directory (agents, skills,
                                             commands, settings.json, STACK.md).

  stack_fetcher.py --detect                 Hook mode (SessionStart / InstructionsLoaded).
                                             Reads ./CLAUDE.md (or .claude/CLAUDE.md) for
                                             `stack: "<name>"`. If stack is missing from
                                             PLATFORM_HOME/stacks/, prints a prompt to run
                                             /fetch-stack. Always exits 0.

Output location (install mode):
  PLATFORM_HOME/stacks/<stack>/raw-sources.md       <- written by this script
  PLATFORM_HOME/stacks/<stack>/STACK.md             <- authored by Claude via /fetch-stack
  PLATFORM_HOME/stacks/<stack>/settings.json        <- authored by Claude via /fetch-stack
  PLATFORM_HOME/stacks/<stack>/agents/<name>/AGENT.md  <- one subfolder per agent
  PLATFORM_HOME/stacks/<stack>/skills/<name>/SKILL.md  <- one subfolder per skill
  PLATFORM_HOME/stacks/<stack>/commands/<cmd>.md    <- flat .md files

PLATFORM_HOME = $AGENTICAI_SDLC_HOME env var, or $HOME/.claude if not set.
After install.sh --platform, all stacks live inside PLATFORM_HOME/stacks/.
The AgenticAI-SDLC repo folder is NOT needed at runtime.
"""

from __future__ import annotations

import json
import os
import re
import sys
import threading
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Optional

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

# PLATFORM_HOME: where install.sh --platform installed everything.
# All stacks live at PLATFORM_HOME/stacks/ after installation.
# The AgenticAI-SDLC repo folder is NOT needed at runtime.
_platform_home_env = os.environ.get("AGENTICAI_SDLC_HOME", "")
PLATFORM_HOME = Path(_platform_home_env) if _platform_home_env else Path.home() / ".claude"
STACKS_ROOT   = PLATFORM_HOME / "stacks"

USER_AGENT       = "stack-orchestrator/1.0 (+claude-code-plugin)"
FETCH_TIMEOUT    = 15
MAX_SOURCE_CHARS = 12_000
MAX_TOTAL_CHARS  = 40_000
MAX_WORKERS      = 20

GITHUB_REPOS = [
    "spencerpauly/awesome-cursor-skills",
    "PatrickJS/awesome-cursorrules",
    "sanjeed5/awesome-cursor-rules-mdc",
    "tugkanboz/awesome-cursorrules",
    "JhonMA82/awesome-clinerules",
]

OFFICIAL_DOCS: dict[str, list[str]] = {
    "nodejs":   ["https://nodejs.org/en/learn/getting-started/security-best-practices",
                 "https://github.com/goldbergyoni/nodebestpractices/blob/master/README.md"],
    "fastapi":  ["https://fastapi.tiangolo.com/tutorial/bigger-applications/",
                 "https://github.com/zhanymkanov/fastapi-best-practices/blob/master/README.md"],
    "angular":  ["https://angular.dev/style-guide"],
    "react":    ["https://react.dev/learn/thinking-in-react"],
    "nextjs":   ["https://nextjs.org/docs/app/guides/production-checklist"],
    "django":   ["https://docs.djangoproject.com/en/stable/misc/design-philosophies/"],
    "flask":    ["https://flask.palletsprojects.com/en/stable/patterns/packages/"],
    "vue":      ["https://vuejs.org/style-guide/"],
    "svelte":   ["https://svelte.dev/docs/svelte/overview"],
    "go":       ["https://go.dev/doc/effective_go"],
    "rust":     ["https://doc.rust-lang.org/book/ch00-00-introduction.html"],
    "spring":   ["https://docs.spring.io/spring-boot/reference/using/structuring-your-code.html"],
    "laravel":  ["https://github.com/alexeymezenin/laravel-best-practices/blob/master/README.md"],
    "nestjs":   ["https://docs.nestjs.com/"],
    "express":  ["https://expressjs.com/en/advanced/best-practice-security.html"],
    "postgres": ["https://www.postgresql.org/docs/current/performance-tips.html"],
    "redis":    ["https://redis.io/docs/manual/patterns/"],
}

GENERIC_SUFFIXES = (
    "", "pro", "expert", "developer", "development", "patterns",
    "best-practices", "practices", "templates", "guidelines", "rules",
    "style-guide", "conventions",
)

JUNK_MARKERS = (
    "Vercel Security Checkpoint", "Warning: Target URL returned error",
    "Just a moment...", "Access denied", "Page not found", "404",
)

EXCLUDED_PATH_WORDS = ("readme", "deprecated", "changelog", "contributing", "license")
OTHER_TECH = ("mongodb", "jwt", "react", "express", "mongoose", "firebase",
              "supabase", "graphql", "docker", "aws", "tutorial")

AITMPL_REPO          = "davila7/claude-code-templates"
AITMPL_SKILLS_PREFIX = "cli-tool/components/skills/"

# --------------------------------------------------------------------------- #
# Shared aitmpl tree cache
# --------------------------------------------------------------------------- #

_aitmpl_tree_cache: Optional[list] = None
_aitmpl_tree_lock  = threading.Lock()


def _get_aitmpl_tree() -> list:
    global _aitmpl_tree_cache
    with _aitmpl_tree_lock:
        if _aitmpl_tree_cache is not None:
            return _aitmpl_tree_cache
        raw = http_get(
            f"https://api.github.com/repos/{AITMPL_REPO}/git/trees/main?recursive=1"
        )
        if raw:
            try:
                _aitmpl_tree_cache = json.loads(raw).get("tree", [])
                return _aitmpl_tree_cache
            except json.JSONDecodeError:
                pass
        _aitmpl_tree_cache = []
        return _aitmpl_tree_cache


# --------------------------------------------------------------------------- #
# Thread-safe printer
# --------------------------------------------------------------------------- #

_print_lock = threading.Lock()


def tprint(*args, **kwargs) -> None:
    with _print_lock:
        print(*args, **kwargs)


# --------------------------------------------------------------------------- #
# HTTP helpers
# --------------------------------------------------------------------------- #

def http_get(url: str) -> Optional[str]:
    try:
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=FETCH_TIMEOUT) as resp:
            if resp.status != 200:
                return None
            return resp.read().decode("utf-8", errors="replace")
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError,
            ValueError, OSError):
        return None


def jina(url: str) -> Optional[str]:
    return http_get(f"https://r.jina.ai/{url}")


# --------------------------------------------------------------------------- #
# Quality filters
# --------------------------------------------------------------------------- #

def looks_junk(text: str) -> bool:
    return any(m in text[:400] for m in JUNK_MARKERS)


def mostly_english(text: str) -> bool:
    sample = text[:3000]
    if not sample:
        return False
    return sum(1 for c in sample if ord(c) < 128) / len(sample) > 0.85


def is_general_skill_name(name: str, stack: str) -> bool:
    name = name.lower().strip()
    for suffix in GENERIC_SUFFIXES:
        if name == (f"{stack}-{suffix}" if suffix else stack):
            return True
        if name == (f"{stack}_{suffix.replace('-', '_')}" if suffix else stack):
            return True
    return False


def junk_path(path: str) -> bool:
    return any(w in path.lower() for w in EXCLUDED_PATH_WORDS)


def generality_key(path: str, needle: str) -> tuple:
    low = path.lower()
    mixins = sum(1 for t in OTHER_TECH if t in low and t != needle)
    return (mixins, len(low))


# --------------------------------------------------------------------------- #
# Source fetchers
# --------------------------------------------------------------------------- #

def fetch_skillsmp(stack: str) -> list[tuple[str, str]]:
    api = f"https://skillsmp.com/api/v1/skills/search?q={stack}&limit=20&sortBy=stars"
    raw = http_get(api)
    if not raw:
        return []
    try:
        skills = json.loads(raw)["data"]["skills"]
    except (json.JSONDecodeError, KeyError, TypeError):
        return []

    candidates = [s for s in skills if is_general_skill_name(s.get("name", ""), stack)]
    if not candidates:
        token = re.compile(rf"(^|[-_]){re.escape(stack)}([-_]|$)")
        candidates = [s for s in skills if token.search(s.get("name", "").lower())]

    urls: list[tuple[str, str]] = []
    for skill in candidates:
        gh = skill.get("githubUrl", "")
        m = re.match(r"https://github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+)", gh)
        if not m:
            continue
        owner, repo, branch, path = m.groups()
        raw_url = f"https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}/SKILL.md"
        label   = f"skillsmp:{owner}/{repo}/{skill.get('name', '?')}"
        urls.append((label, raw_url))

    results: list[tuple[str, str]] = []
    with ThreadPoolExecutor(max_workers=min(len(urls) or 1, MAX_WORKERS)) as ex:
        futures = {ex.submit(http_get, url): label for label, url in urls}
        for fut in as_completed(futures):
            label = futures[fut]
            text  = fut.result()
            if text and len(text) > 200 and not looks_junk(text) and mostly_english(text):
                results.append((label, text[:MAX_SOURCE_CHARS]))
            if len(results) >= 3:
                for f in futures:
                    f.cancel()
                break
    return results


def fetch_aitmpl(stack: str) -> list[tuple[str, str]]:
    tree   = _get_aitmpl_tree()
    needle = stack.lower()
    skill_blobs = [
        node["path"] for node in tree
        if node.get("type") == "blob"
        and node.get("path", "").startswith(AITMPL_SKILLS_PREFIX)
        and node["path"].endswith("/SKILL.md")
    ]
    hits = [p for p in skill_blobs if is_general_skill_name(p.split("/")[-2], needle)]
    if not hits:
        token = re.compile(rf"(^|[-_]){re.escape(needle)}([-_]|$)")
        hits  = [p for p in skill_blobs if token.search(p.split("/")[-2].lower())]
    hits = hits[:3]

    def _fetch(path: str) -> tuple[str, Optional[str]]:
        url   = f"https://raw.githubusercontent.com/{AITMPL_REPO}/main/{path}"
        label = f"aitmpl:{path[len(AITMPL_SKILLS_PREFIX):]}"
        return label, http_get(url)

    results: list[tuple[str, str]] = []
    with ThreadPoolExecutor(max_workers=len(hits) or 1) as ex:
        for label, text in ex.map(lambda p: _fetch(p), hits):
            if text and len(text) > 200:
                results.append((label, text[:MAX_SOURCE_CHARS]))
    return results


def fetch_official_docs(stack: str) -> list[tuple[str, str]]:
    urls = OFFICIAL_DOCS.get(stack, [])
    if not urls:
        return []

    def _fetch(url: str) -> tuple[str, Optional[str]]:
        return url, jina(url)

    results: list[tuple[str, str]] = []
    with ThreadPoolExecutor(max_workers=len(urls)) as ex:
        for url, text in ex.map(_fetch, urls):
            if text and len(text) > 400 and not looks_junk(text):
                results.append((url, text[:MAX_SOURCE_CHARS]))
    return results


def fetch_directories(stack: str) -> list[tuple[str, str]]:
    candidates = [
        f"https://cursor.directory/{stack}",
        f"https://cursor.directory/rules/{stack}",
        f"https://agentdepot.dev/search?q={stack}",
    ]

    def _fetch(url: str) -> tuple[str, Optional[str]]:
        return url, jina(url)

    results: list[tuple[str, str]] = []
    with ThreadPoolExecutor(max_workers=len(candidates)) as ex:
        for url, text in ex.map(_fetch, candidates):
            if text and len(text) > 400 and not looks_junk(text):
                results.append((url, text[:MAX_SOURCE_CHARS]))
    return results


def _github_tree(repo: str) -> list:
    for ref in ("HEAD", "main", "master"):
        raw = http_get(f"https://api.github.com/repos/{repo}/git/trees/{ref}?recursive=1")
        if raw:
            try:
                return json.loads(raw).get("tree", [])
            except json.JSONDecodeError:
                pass
    return []


def fetch_github(stack: str) -> list[tuple[str, str]]:
    needle = stack.lower()
    with ThreadPoolExecutor(max_workers=len(GITHUB_REPOS)) as ex:
        trees = list(ex.map(_github_tree, GITHUB_REPOS))

    candidates: list[tuple[str, str]] = []
    for repo, tree in zip(GITHUB_REPOS, trees):
        hits = sorted(
            (node["path"] for node in tree
             if node.get("type") == "blob"
             and needle in node.get("path", "").lower()
             and node["path"].lower().endswith((".md", ".mdc", ".cursorrules", ".txt"))
             and not junk_path(node["path"])),
            key=lambda p: generality_key(p, needle),
        )
        for path in hits[:3]:
            candidates.append((repo, path))

    if not candidates:
        return []

    def _fetch_file(repo_path: tuple[str, str]) -> tuple[str, Optional[str]]:
        repo, path = repo_path
        for branch in ("HEAD", "main", "master"):
            url  = f"https://raw.githubusercontent.com/{repo}/{branch}/{path}"
            text = http_get(url)
            if text and len(text) > 300 and mostly_english(text):
                return f"{repo}/{path}", text[:MAX_SOURCE_CHARS]
        return f"{repo}/{path}", None

    results: list[tuple[str, str]] = []
    with ThreadPoolExecutor(max_workers=min(len(candidates), MAX_WORKERS)) as ex:
        for label, text in ex.map(_fetch_file, candidates):
            if text:
                results.append((label, text))
    return results


# --------------------------------------------------------------------------- #
# Gather all sources for one stack
# --------------------------------------------------------------------------- #

def gather_sources(stack: str) -> list[tuple[str, str]]:
    tprint(f"[{stack}] Fetching sources ...")

    fetchers = [fetch_skillsmp, fetch_aitmpl, fetch_github, fetch_official_docs, fetch_directories]
    all_sources: list[tuple[str, str]] = []
    with ThreadPoolExecutor(max_workers=len(fetchers)) as ex:
        futures = {ex.submit(fn, stack): fn.__name__ for fn in fetchers}
        for fut in as_completed(futures):
            try:
                all_sources.extend(fut.result())
            except Exception:
                pass

    seen_names, seen_texts, unique = set(), set(), []
    for name, text in all_sources:
        key = text[:500]
        if name in seen_names or key in seen_texts:
            continue
        seen_names.add(name)
        seen_texts.add(key)
        unique.append((name, text))

    budget, kept = MAX_TOTAL_CHARS, []
    for name, text in unique:
        if budget <= 0:
            break
        kept.append((name, text[:budget]))
        budget -= len(text)

    for name, _ in kept:
        tprint(f"[{stack}]   source: {name}")
    return kept


# --------------------------------------------------------------------------- #
# Path helpers
# --------------------------------------------------------------------------- #

def stack_dir(stack: str) -> Path:
    """PLATFORM_HOME/stacks/<stack>/"""
    return STACKS_ROOT / stack


def raw_file(stack: str) -> Path:
    return stack_dir(stack) / "raw-sources.md"


# --------------------------------------------------------------------------- #
# Raw dump writer
# --------------------------------------------------------------------------- #

def write_raw_dump(stack: str, sources: list[tuple[str, str]]) -> Path:
    """
    Write fetched sources to PLATFORM_HOME/stacks/<stack>/raw-sources.md.

    The NOTE FOR CLAUDE section tells Claude exactly what to generate:
    a full L1 stack directory matching the structure of the django stack.
    """
    target = raw_file(stack)
    target.parent.mkdir(parents=True, exist_ok=True)

    stack_out = str(STACKS_ROOT / stack)

    lines = [
        f"# Raw fetched sources for stack: {stack}",
        f"# Sources: {len(sources)} | Total chars: {sum(len(t) for _, t in sources)}",
        "#",
        "# =========================================================================",
        "# NOTE FOR CLAUDE -- FULL STACK GENERATION REQUIRED",
        "# =========================================================================",
        "#",
        "# Read ALL sources below carefully. Then generate the complete L1 stack",
        f"# directory at:  {stack_out}/",
        "#",
        "# This directory must match the generic L1 stack template below exactly —",
        "# do not model content on any one existing stack (e.g. django, node).",
        "# Output goes to PLATFORM_HOME/stacks/ — NOT inside any project folder",
        "# and NOT inside the AgenticAI-SDLC repo folder.",
        "#",
        "# REQUIRED FILES:",
        "#",
        f"#   {stack_out}/STACK.md",
        f"#     Format (5-6 lines):",
        f"#       # Stack: {stack.title()} (L1)",
        f"#       Installs into a project's `.claude/` via `install.sh --stack {stack} --project <path>`.",
        f"#       Project files win any filename collision. Declare `stack: {stack}` in project CLAUDE.md.",
        f"#       Provides: <list agents> + skills.",
        f"#       Defaults: test `<test cmd>`, security `<sec cmd>`, lint `<lint cmd>`.",
        "#",
        f"#   {stack_out}/settings.json",
        "#     Framework-specific bash allow/deny ONLY. No hooks. Format:",
        "#       { \"permissions\": {",
        "#           \"allow\": [\"Bash(<framework-cli> *)\", ...],",
        "#           \"deny\":  [\"Bash(<destructive-cmd> *)\", ...]",
        "#         }",
        "#       }",
        "#",
        f"#   {stack_out}/agents/<agent-name>/AGENT.md  (one SUBFOLDER per agent)",
        "#     Each agent lives in its own named subfolder. File is always AGENT.md.",
        "#     Example: agents/api-agent/AGENT.md",
        "#     Format:",
        "#       ---",
        "#       name: <agent-name>",
        f"#       description: One sentence role. {stack.title()} stack.",
        "#       tools: Read, Glob, Grep, Bash, Write, Edit",
        "#       disallowedTools: WebSearch",
        "#       model: sonnet",
        "#       memory: project",
        "#       skills:",
        "#         - <primary-skill-name>",
        "#       permissionMode: ask",
        "#       maxTurns: 20",
        "#       effort: medium",
        "#       isolation: fork",
        "#       color: blue",
        "#       ---",
        f"#       # <Agent Title> ({stack.title()})",
        "#       Concise role: what it does, what it refuses, what skill it loads.",
        "#       Max 12 lines.",
        "#",
        f"#   {stack_out}/skills/<skill-name>/SKILL.md  (one SUBFOLDER per skill)",
        "#     Each skill lives in its own named subfolder. File is always SKILL.md.",
        "#     Example: skills/drf-endpoint/SKILL.md",
        "#     Format:",
        "#       ---",
        "#       name: <skill-name>",
        "#       description: One sentence -- when to use this skill.",
        "#       when_to_use: <trigger condition>",
        "#       disable-model-invocation: false",
        "#       user-invocable: false",
        "#       allowed-tools:",
        "#         - Read",
        "#         - Write",
        "#         - Bash",
        "#       model: sonnet",
        "#       effort: medium",
        "#       context: []",
        "#       ---",
        "#       # <Skill Title>",
        "#       Numbered/bulleted procedure. Max 15 lines.",
        "#",
        f"#   {stack_out}/commands/<command>.md  (FLAT — no subfolders, no frontmatter)",
        "#     Format:",
        "#       # /<command> <args>",
        "#       One paragraph: what it invokes, what it refuses. Max 5 lines.",
        "#",
        "# AGENT DESIGN RULES:",
        "#   - Identify the specialist roles the framework needs (e.g. api, migration,",
        "#     queue/worker, ORM/query review, cache, auth). One agent per distinct role.",
        "#   - Each agent loads one or more skills from the skills/ folder.",
        "#   - Agents must honour project knowledge.md constraints -- reference by name.",
        "#   - EACH AGENT GETS ITS OWN SUBFOLDER: agents/<name>/AGENT.md",
        "#   - Never put AGENT.md directly in agents/ — always in a named subfolder.",
        "#",
        "# SKILL DESIGN RULES:",
        "#   - One skill per recurring procedure (endpoint, migration, bootstrap, etc.).",
        "#   - Skills are checklists/numbered steps, not prose.",
        "#   - EACH SKILL GETS ITS OWN SUBFOLDER: skills/<name>/SKILL.md",
        "#   - Never put SKILL.md directly in skills/ — always in a named subfolder.",
        "#   - A bootstrap skill covers: dependency pinning, project layout, smoke test,",
        "#     lint/test commands.",
        "#",
        "# COMMAND DESIGN RULES:",
        "#   - One command per agent action that a developer types directly.",
        "#   - Commands are FLAT .md files directly in commands/ (no subfolders).",
        "#   - Commands must reference an approved spec -- refuse work outside the spec.",
        "#",
        "# SETTINGS DESIGN RULES:",
        "#   - Allow: framework CLI tools for dev/test (test runner, linter, security",
        "#     scanner, package manager, safe DB operations).",
        "#   - Deny: anything destructive or irreversible.",
        "#",
        "",
    ]

    for name, text in sources:
        lines += ["", "", "=" * 80, f"=== SOURCE: {name} ({len(text)} chars)", "=" * 80, "", text]

    target.write_text("\n".join(lines), encoding="utf-8")
    return target


# --------------------------------------------------------------------------- #
# Stack existence check
# --------------------------------------------------------------------------- #

def stack_exists(stack: str) -> bool:
    """True if PLATFORM_HOME/stacks/<stack>/ already has STACK.md and settings.json."""
    d = stack_dir(stack)
    return (d / "STACK.md").is_file() and (d / "settings.json").is_file()


# --------------------------------------------------------------------------- #
# Install one stack
# --------------------------------------------------------------------------- #

def install_one(stack: str) -> tuple[str, bool, str]:
    """Fetch raw sources for one stack. Returns (stack, ok, message)."""
    stack_out = str(STACKS_ROOT / stack)

    if stack_exists(stack):
        return stack, True, (
            f"[SKIP] {stack_out}/ already installed "
            f"(STACK.md + settings.json present)."
        )

    sources = gather_sources(stack)
    if not sources:
        return stack, False, (
            f"[FAIL] No sources found for '{stack}'. "
            f"Check network or try a different stack name."
        )

    target = write_raw_dump(stack, sources)
    msg = (
        f"[OK] RAW FETCHED -- {len(sources)} sources for '{stack}' written to:\n"
        f"     {target}\n"
        f"\n"
        f"NEXT STEP FOR CLAUDE:\n"
        f"  1. Read {target}\n"
        f"  2. Generate the complete stack at: {stack_out}/\n"
        f"     Required files (match the generic L1 template structure exactly):\n"
        f"       {stack_out}/STACK.md\n"
        f"       {stack_out}/settings.json\n"
        f"       {stack_out}/agents/<agent-name>/AGENT.md   (one subfolder per agent)\n"
        f"       {stack_out}/skills/<skill-name>/SKILL.md   (one subfolder per skill)\n"
        f"       {stack_out}/commands/<cmd>.md              (flat .md files)\n"
        f"  3. Output path MUST be {stack_out}/ -- never inside stack-orchestrator/\n"
        f"\n"
        f"  Run: /fetch-stack {stack}"
    )
    return stack, True, msg


# --------------------------------------------------------------------------- #
# Detect mode (hook)
# --------------------------------------------------------------------------- #

STACK_RE = re.compile(
    r'^\s*stack\s*[=:]\s*["\']?([A-Za-z0-9_.+-]+)["\']?\s*$',
    re.MULTILINE | re.IGNORECASE,
)


def detect() -> int:
    """Hook mode: never fail the session. Print guidance only when stack dir is missing."""
    for candidate in [Path.cwd() / "CLAUDE.md", Path.cwd() / ".claude" / "CLAUDE.md"]:
        if not candidate.is_file():
            continue
        try:
            match = STACK_RE.search(candidate.read_text(encoding="utf-8", errors="replace"))
        except OSError:
            continue
        if not match:
            continue
        stack = match.group(1).lower()
        if stack == "stack-orchestrator":
            return 0
        if stack_exists(stack):
            return 0
        print(
            f"[stack-orchestrator] This project declares stack = \"{stack}\" but "
            f"{STACKS_ROOT / stack}/ is missing. "
            f"Run: /fetch-stack {stack}"
        )
        return 0
    return 0


# --------------------------------------------------------------------------- #
# Entry point
# --------------------------------------------------------------------------- #

def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    sys.exit(1)


def sanitize_stack(raw: str) -> str:
    stack = raw.strip().lower()
    if not re.fullmatch(r"[a-z0-9_.+-]{1,64}", stack):
        fail(f"Invalid stack name: {raw!r}. Use names like 'nodejs', 'fastapi'.")
    return stack


def main() -> int:
    args = sys.argv[1:]
    if not args:
        fail("Usage: stack_fetcher.py <stack> [<stack2> ...] | --detect")

    if args[0] == "--detect":
        return detect()

    stacks = [sanitize_stack(a) for a in args]

    if len(stacks) == 1:
        _, ok, msg = install_one(stacks[0])
        print(msg)
        return 0 if ok else 1

    print(f"[..] Fetching {len(stacks)} stacks in parallel: {', '.join(stacks)}")
    print()

    results: list[tuple[str, bool, str]] = []
    with ThreadPoolExecutor(max_workers=min(len(stacks), 8)) as ex:
        futures = {ex.submit(install_one, s): s for s in stacks}
        for fut in as_completed(futures):
            stack, ok, msg = fut.result()
            results.append((stack, ok, msg))
            with _print_lock:
                print("-" * 60)
                print(msg)
                print()

    ok_stacks   = [s for s, ok, _ in results if ok]
    fail_stacks = [s for s, ok, _ in results if not ok]
    print("=" * 60)
    print(f"SUMMARY: {len(ok_stacks)} succeeded, {len(fail_stacks)} failed")
    if ok_stacks:
        print(f"  OK   {', '.join(sorted(ok_stacks))}")
    if fail_stacks:
        print(f"  FAIL {', '.join(sorted(fail_stacks))}")
    print()
    if ok_stacks:
        print("NEXT STEP FOR CLAUDE:")
        print("  For each stack, read raw-sources.md then run /fetch-stack <name>")
        for s in sorted(ok_stacks):
            if not stack_exists(s):
                print(f"  /fetch-stack {s}")

    return 0 if not fail_stacks else 1


if __name__ == "__main__":
    sys.exit(main())
