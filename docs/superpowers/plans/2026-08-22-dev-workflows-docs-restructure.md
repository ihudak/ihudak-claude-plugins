# dev-workflows Documentation Restructure — Implementation Plan (canonical, PR 1 of 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 379-line / 74,620-byte `plugins/dev-workflows/README.md` with a ~50-line README plus 34 task-oriented pages under `plugins/dev-workflows/docs/`, every claim re-derived from what actually runs, defended by a new `scripts/check-docs.sh` gate wired into CI.

**Architecture:** The gate is built **first** and left failing, so every page is authored against a live checker rather than a described one. Pages are then built spine-outward — index and navigation, then reference pages, then the 21 command pages in role-grouped batches — and the README is rewritten last, once everything it links to exists. Five documentation defects found during spec-writing are fixed along the way; a sixth is reported rather than resolved.

**Tech Stack:** Bash 4+ (the gate), Python 3.11 (existing `validate-catalog.py`), GitHub Actions, Markdown, Mermaid.

**Spec:** `docs/superpowers/specs/2026-08-22-dev-workflows-docs-restructure-design.md`

**Scope:** This plan covers **PR 1 (canonical) only**. The mgd port (PR 2) and the copilot port (PR 3) get their own plans, written after PR 1 merges, per spec §11.

## Global Constraints

Every task's requirements implicitly include this section. Values are copied verbatim from the spec.

- **Requirement IDs use the bracketed form only.** `scripts/check-id-grammar.sh` scans the whole repository root and fails on `US-1`, `AC-1`, `SM-1`, `SMC-1`, `UC-1`, `FR-1`, `AD-1`, `SM-C1` in both bracketed and bare forms. A docs page illustrating an ID writes `[US#1]`, `[AC#1]`, `[AD#1]`. The gate's exclusion list is anchored to the scan root (`^\./(docs|\.remember|\.superpowers|scripts/fixtures)/`), so `plugins/dev-workflows/docs/` **is** in scope — a new page is scanned.
- **No spec-ID literals in any new page under `plugins/`.** `scripts/spec-id-baseline.txt` freezes the counts of `[U0N]`, `[AC0N]`, `[TC0N]`, `[Uxx]`, `[ACxx]`, `[TCxx]` across `plugins/` and `CLAUDE.md`. A page using one changes the census and trips the tripwire.
- **Prose is never hard-wrapped.** Per `references/prose-formatting.md`, each paragraph is one unbroken line. Tables and fenced code blocks are exempt.
- **No table cell exceeds 200 characters.** Enforced by check 6. This is the invariant the whole change exists to establish.
- **No page under `docs/` names a marketplace or a container repository**, with exactly one sanctioned exception: `docs/getting-started.md`, whose install block is pinned to the repo-root README by check 7.
- **The old README is a source of topics, never of facts.** No sentence moves to a new page without being re-derived from `commands/`, `agents/`, `references/`, or `hooks/`.
- **Plugin `description` blurbs are untouched** and stay under the 1024-character budget `scripts/validate-catalog.py` enforces.
- **Every commit ends with:** `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- **Branch:** all work lands on `iv-gu/docs-restructure`, which already exists and already carries the spec.

---

## File Structure

**Created — the gate and its fixtures**

| File | Responsibility |
|---|---|
| `scripts/check-docs.sh` | All 8 checks plus `--selftest`. Single entry point; no helper scripts. |
| `scripts/fixtures/docs/pass/` | One minimal plugin tree that passes every check. The selftest mutates copies of it to prove each check can fail. |

**Created — the docs tree** (34 pages under `plugins/dev-workflows/docs/`)

| File | Responsibility |
|---|---|
| `docs/README.md` | The index: an "I want to…" task table, then the full page list. Every page must be reachable from here. |
| `docs/getting-started.md` | Install, update, all six environment variables and what each is *for*, statusline, one worked first run. |
| `docs/workflow.md` | The pipeline Mermaid, the role table, artifact homes, sources of truth, cross-cutting commands. |
| `docs/roles-and-phases.md` | Prose companion to the diagram: what each role owns and hands over; what each cost-attribution phase means. |
| `docs/commands/<name>.md` × 21 | One page per command, fixed seven-section anatomy. |
| `docs/reference/agents.md` | The 34 agents grouped by role, with the 9 real Opus pins. |
| `docs/reference/references.md` | The reference inventory: 36 top-level + `cost-prices.yaml` + `model-routing/classification.md`, plus six subtrees by count. |
| `docs/reference/environment.md` | What each variable *is*: default, resolution order, unset behaviour, expected directory layout. |
| `docs/reference/hooks.md` | The 4 hooks and their triggers. |
| `docs/reference/model-routing.md` | Classification, the fallback chain, the fan-out policy. |
| `docs/reference/session-cost.md` | How cost is computed and attributed; how to read a cost file, with a worked sample. |
| `docs/reference/session-feedback.md` | What gets logged, the entry format, where it lands. |
| `docs/reference/follow-ups.md` | Task-line format, target-file resolution, the end-of-run batch preview. |
| `docs/reference/resume-and-checkpoints.md` | The prepare-checkpoint, `resume.md`, the role-aware suggestion, the session-name aid. |

**Modified**

| File | Change |
|---|---|
| `plugins/dev-workflows/README.md` | 379 lines → ~50: pitch, marketplace pointer, container recommendation, install pointer, compact capability table, link table. |
| `README.md` (repo root) | Add a link to the new docs index in the plugin table row. |
| `.github/workflows/validate-catalog.yml` | Two new steps: `check-docs.sh --selftest`, then `check-docs.sh --root .`. |
| `plugins/dev-workflows/references/cost-emission.md` | Defect D2: add the missing `/update-vi` row to the §7 attribution table. |
| `plugins/dev-workflows/CHANGELOG.md` | New version entry. |
| `plugins/dev-workflows/.claude-plugin/plugin.json` | Version bump. |
| `.claude-plugin/marketplace.json` | Version bump. |

**Deliberately not modified:** any file under `commands/`, `agents/`, or `hooks/`. The only plugin-content change in this plan is D2 in `references/cost-emission.md`, which has its own task and its own commit.

---

## Task 1: The gate, built failing

**Files:**
- Create: `scripts/check-docs.sh`
- Create: `scripts/fixtures/docs/pass/` (a minimal plugin tree, 18 files, listed in Step 2)
- Modify: `.github/workflows/validate-catalog.yml`

**Interfaces:**
- Produces: `scripts/check-docs.sh --root <dir>` exits `0` on pass, `1` on any check failure, `2` on usage error, and prints `FAIL check <N>: <reason>` for each failure. `--selftest` exits `0` when every check has been demonstrated both passing and failing. Later tasks run `./scripts/check-docs.sh --root .` as their acceptance test.

- [ ] **Step 1: Write the gate**

Create `scripts/check-docs.sh` with exactly this content. **This script was executed against the fixture tree and against the real repository while this plan was written** — all eight selftest cases pass, `--root .` returns the expected check-4 failure, and both usage errors return exit 2. Two bugs were found and fixed during that run, and their fixes are load-bearing rather than cosmetic:

- `slugify` originally used `printf '%s'` with no trailing newline, so every heading slug concatenated into one line and **no anchor ever matched** — check 2 rejected its own valid fixture. The comment on the function records this; do not "simplify" it back.
- `check_table_cells` originally ran two awk passes, one printing and one counting, and the counting pass never incremented `FAILURES` — so check 6 could not fail at all. It is now a single pass whose output feeds `fail 6` directly.

Both were invisible to `bash -n`, which passed on the broken version. Copy the script as written:

```bash
#!/usr/bin/env bash
# Guards plugins/dev-workflows/docs/ against the drift that splitting prose invites.
#
# Splitting one README into 34 pages multiplies the places drift can hide. Every
# check below exists because a specific failure was observed -- in this plugin, or
# in the two restructures this one follows (dynatrace-managed-mcp#214,
# ai-containers#78).
#
# --selftest mutates a copy of the passing fixture once per check and asserts the
# gate rejects it. Without that, the fixtures are decorative: a gate that cannot
# be shown to fail proves nothing when it passes. ai-containers' equivalent gate
# passed vacuously on its first run, examining nothing, because its file list came
# from `git ls-files` while the new pages were still untracked.
set -uo pipefail

PLUGIN_REL="plugins/dev-workflows"
FAILURES=0

fail() { printf 'FAIL check %s: %s\n' "$1" "$2" >&2; FAILURES=$((FAILURES + 1)); }
note() { printf '  %s\n' "$1" >&2; }

# ---------------------------------------------------------------- check 1 + 2
# Every relative link resolves, and every #anchor resolves to a real heading in
# whichever file it names. A bare `#anchor` names no file, so a file-existence
# check cannot see it -- that is why check 2 is separate. ai-containers' split
# broke 24 anchors this way.
slugify() { # GitHub heading -> anchor. NEWLINE-TERMINATED: without it every
            # slug concatenates into one line and no anchor ever matches.
  printf '%s\n' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/`//g; s/[^a-z0-9 _-]//g; s/ /-/g'
}

check_links_and_anchors() {
  local root="$1" f target anchor path abs heading_file
  while IFS= read -r f; do
    while IFS= read -r link; do
      target="${link%%#*}"
      anchor="${link#*#}"
      [ "$anchor" = "$link" ] && anchor=""
      if [ -n "$target" ]; then
        path="$(dirname "$f")/$target"
        abs="$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")"
        if [ ! -e "$abs" ]; then
          fail 1 "$f -> $target (no such file)"
          continue
        fi
        heading_file="$abs"
      else
        heading_file="$f"
      fi
      if [ -n "$anchor" ] && [ -f "$heading_file" ]; then
        # Collect first, match second. `... | grep -qx` would exit on the first
        # match, SIGPIPE the producer, and `pipefail` would report that as a
        # failure -- turning a VALID anchor into a check-2 error. Same defect
        # ai-containers#78 caught in its own new gate.
        local slugs
        slugs=$(grep -E '^#{1,6} ' "$heading_file" 2>/dev/null \
                | sed -E 's/^#{1,6} //' \
                | while IFS= read -r h; do slugify "$h"; done)
        if ! grep -qx -- "$anchor" <<<"$slugs"; then
          fail 2 "$f -> ${target:-(this file)}#$anchor (no such heading)"
        fi
      fi
    done < <(grep -oE '\]\([^)#][^)]*\)|\]\(#[^)]*\)' "$f" \
             | sed -E 's/^\]\(//; s/\)$//' \
             | grep -vE '^(https?|mailto):')
  done < <(find "$root/$PLUGIN_REL/docs" -name '*.md' 2>/dev/null)
}

# ------------------------------------------------------------------- check 3
# No orphan pages. Reachability is transitive from docs/README.md, so a page
# linked only from another orphan is still an orphan.
check_orphans() {
  local root="$1" docs="$1/$PLUGIN_REL/docs" seen frontier next f target abs
  [ -f "$docs/README.md" ] || { fail 3 "docs/README.md is missing -- nothing to reach from"; return; }
  seen="$(cd "$docs" && pwd)/README.md"
  frontier="$seen"
  while [ -n "$frontier" ]; do
    next=""
    while IFS= read -r f; do
      [ -f "$f" ] || continue
      while IFS= read -r target; do
        abs="$(cd "$(dirname "$f")" && cd "$(dirname "$target")" 2>/dev/null && pwd)/$(basename "$target")"
        [ -f "$abs" ] || continue
        case "$seen" in *"$abs"*) continue ;; esac
        seen="$seen
$abs"
        next="$next
$abs"
      done < <(grep -oE '\]\([^)#][^):]*\.md[^)]*\)' "$f" | sed -E 's/^\]\(//; s/\)$//; s/#.*$//')
    done < <(printf '%s\n' "$frontier")
    frontier="$next"
  done
  while IFS= read -r f; do
    case "$seen" in *"$f"*) ;; *) fail 3 "orphan page (unreachable from docs/README.md): ${f#$root/}" ;; esac
  done < <(cd "$docs" && find . -name '*.md' -exec sh -c 'cd "$(dirname "$1")" && printf "%s/%s\n" "$(pwd)" "$(basename "$1")"' _ {} \;)
}

# ------------------------------------------------------------------- check 4
# Inventory agrees in BOTH directions, over reference FILES not reference
# markdown -- references/ holds 98 files of which 5 are not markdown, and one of
# those (cost-prices.yaml) is user-overridable and therefore user-facing.
# Every inventory is derived from the edition being checked, never from a number
# written into a page.
check_inventory() {
  local root="$1" p="$1/$PLUGIN_REL" d="$1/$PLUGIN_REL/docs" n

  # commands <-> docs/commands/
  while IFS= read -r n; do
    [ -f "$d/commands/$n.md" ] || fail 4 "command '$n' has no page at docs/commands/$n.md"
  done < <(ls "$p/commands"/*.md 2>/dev/null | sed 's|.*/||; s|\.md$||')
  while IFS= read -r n; do
    [ -f "$p/commands/$n.md" ] || fail 4 "docs/commands/$n.md names no real command"
  done < <(ls "$d/commands"/*.md 2>/dev/null | sed 's|.*/||; s|\.md$||')

  # agents <-> docs/reference/agents.md
  while IFS= read -r n; do
    grep -q "\`$n\`" "$d/reference/agents.md" 2>/dev/null || fail 4 "agent '$n' is absent from reference/agents.md"
  done < <(ls "$p/agents"/*.md 2>/dev/null | sed 's|.*/||; s|\.md$||')
  while IFS= read -r n; do
    [ -f "$p/agents/$n.md" ] || fail 4 "reference/agents.md names '$n', which is not an agent"
  done < <(grep -oE '^\| `[a-z-]+`' "$d/reference/agents.md" 2>/dev/null | tr -d '|` ')

  # reference FILES <-> docs/reference/references.md
  while IFS= read -r n; do
    grep -q "$n" "$d/reference/references.md" 2>/dev/null || fail 4 "reference file '$n' is absent from reference/references.md"
  done < <({ ls "$p/references"/*.md 2>/dev/null; ls "$p/references"/*.yaml 2>/dev/null; \
             ls "$p/references/model-routing"/*.md 2>/dev/null; } | sed 's|.*/||')
  while IFS= read -r n; do
    [ -f "$p/references/$n" ] || [ -f "$p/references/model-routing/$n" ] \
      || fail 4 "reference/references.md names '$n', which is not a reference file"
  done < <(grep -oE '`[A-Za-z0-9_.-]+\.(md|yaml)`' "$d/reference/references.md" 2>/dev/null | tr -d '`')

  # reference subtree counts -- *.md only: these subtrees also carry vendored
  # non-markdown data/templates that are not user-facing reference pages, so
  # counting everything would fail this check on files docs/ never claims.
  local dir count claimed
  for dir in api-guidelines guidelines handoff dynatrace-docs upgrade fix-vuln; do
    [ -d "$p/references/$dir" ] || continue
    count=$(find "$p/references/$dir" -name '*.md' | wc -l | tr -d ' ')
    claimed=$(grep -oE "\`$dir/\` \(([0-9]+)\)" "$d/reference/references.md" 2>/dev/null | grep -oE '[0-9]+' | head -1)
    [ "$claimed" = "$count" ] || fail 4 "reference/references.md says $dir/ has '${claimed:-nothing}', tree has $count"
  done

  # hooks <-> docs/reference/hooks.md
  while IFS= read -r n; do
    grep -q "\`$n\`" "$d/reference/hooks.md" 2>/dev/null || fail 4 "hook '$n' is absent from reference/hooks.md"
  done < <(ls "$p/hooks"/*.sh 2>/dev/null | sed 's|.*/||; s|\.sh$||')
  while IFS= read -r n; do
    [ -f "$p/hooks/$n.sh" ] || fail 4 "reference/hooks.md names '$n', which is not a hook"
  done < <(grep -oE '^\| `[a-z-]+`' "$d/reference/hooks.md" 2>/dev/null | tr -d '|` ')
}

# ------------------------------------------------------------------- check 5
# Environment variables agree in both directions. The scan covers commands/,
# agents/, references/, hooks/ and skills/ -- narrowing it to the first three
# would let a variable only a hook reads look documented-but-unread. The
# runtime-exclusion list is written in, so a SEVENTH user-settable variable fails
# this check rather than passing silently. That silent pass is exactly how
# GIT_USER_INITIALS and DEV_WORKFLOWS_COST_PRICES came to be missing from the
# section named after them (defect D4).
RUNTIME_VARS="CLAUDE_PLUGIN_ROOT ARGUMENTS OSTYPE BASH_SOURCE BASH_REMATCH ROOT OWNER_REPO"

check_env_vars() {
  local root="$1" p="$1/$PLUGIN_REL" d="$1/$PLUGIN_REL/docs" v
  local read_vars documented
  read_vars=$(grep -rhoE '\$\{?[A-Z][A-Z0-9_]{2,}\}?' \
                "$p/commands" "$p/agents" "$p/references" "$p/hooks" "$p/skills" 2>/dev/null \
              | tr -d '${}' | sort -u)
  for v in $read_vars; do
    case " $RUNTIME_VARS " in *" $v "*) continue ;; esac
    grep -q "$v" "$d/reference/environment.md" 2>/dev/null \
      || fail 5 "\$$v is read by the plugin but absent from reference/environment.md"
    grep -q "$v" "$d/getting-started.md" 2>/dev/null \
      || fail 5 "\$$v is read by the plugin but absent from getting-started.md"
  done
  documented=$(grep -oE '\*\*`\$?[A-Z][A-Z0-9_]{2,}`\*\*' "$d/reference/environment.md" 2>/dev/null | tr -d '*`$')
  for v in $documented; do
    grep -qx -- "$v" <<<"$read_vars" \
      || fail 5 "reference/environment.md documents \$$v, which the plugin never reads"
  done
}

# ------------------------------------------------------------------- check 6
# No table cell over 200 characters. This is the readability invariant the whole
# restructure exists to establish, and the one a future edit will silently
# violate: today's README carries a single cell of 2,177 characters.
check_table_cells() {
  local root="$1" files hits h
  files=$( { find "$root/$PLUGIN_REL/docs" -name '*.md' 2>/dev/null
             [ -f "$root/$PLUGIN_REL/README.md" ] && printf '%s\n' "$root/$PLUGIN_REL/README.md"; } )
  [ -n "$files" ] || return 0
  hits=$(while IFS= read -r f; do
           [ -n "$f" ] || continue
           awk -v FILE="${f#$root/}" '
             /^```/    { infence = !infence; next }
             infence   { next }
             /^\|/ {
               n = split($0, cells, "|")
               for (i = 2; i < n; i++) {
                 c = cells[i]; gsub(/^ +| +$/, "", c)
                 if (length(c) > 200)
                   printf "%s:%d cell is %d chars (max 200)\n", FILE, NR, length(c)
               }
             }' "$f"
         done <<<"$files")
  [ -n "$hits" ] || return 0
  while IFS= read -r h; do [ -n "$h" ] && fail 6 "$h"; done <<<"$hits"
}

# ------------------------------------------------------------------- check 7
# getting-started.md carries the install and update commands INLINE rather than
# linking out, because a getting-started page whose first step is a link has
# failed at its one job. That makes it the only page under docs/ carrying edition
# identity, so it is pinned: its command lines must match the repo-root README's
# Installation section exactly, in both directions.
check_install_block() {
  local root="$1" a b
  a=$(grep -oE '^claude plugin (marketplace (add|update)|install) .*' "$root/README.md" 2>/dev/null | sort)
  b=$(grep -oE '^claude plugin (marketplace (add|update)|install) .*' "$root/$PLUGIN_REL/docs/getting-started.md" 2>/dev/null | sort)
  if [ -z "$a" ]; then fail 7 "repo-root README.md has no 'claude plugin ...' command lines to pin against"; return; fi
  if [ "$a" != "$b" ]; then
    fail 7 "getting-started.md install commands differ from the repo-root README"
    note "only in root README: $(comm -23 <(printf '%s\n' "$a") <(printf '%s\n' "$b") | tr '\n' ' ')"
    note "only in getting-started: $(comm -13 <(printf '%s\n' "$a") <(printf '%s\n' "$b") | tr '\n' ' ')"
  fi
}

# ------------------------------------------------------------------ selftest
# One passing fixture tree; each check gets a mutation of a fresh copy. Asserting
# the exit code alone would let a mutation that trips a DIFFERENT check register
# as success, so each case also asserts which check fired.
selftest() {
  local here fixture tmp rc=0
  here=$(cd "$(dirname "$0")" && pwd)
  fixture="$here/fixtures/docs/pass"
  [ -d "$fixture" ] || { echo "SELFTEST FAIL: fixture tree missing at $fixture" >&2; exit 2; }

  expect_pass() {
    tmp=$(mktemp -d); cp -R "$fixture/." "$tmp/"
    if "$0" --root "$tmp" >/dev/null 2>&1; then printf 'ok    %s\n' "$1"
    else printf 'FAIL  %s: expected exit 0\n' "$1"; rc=1; fi
    rm -rf "$tmp"
  }
  expect_fail() { # <description> <check-number> <mutation-shell>
    tmp=$(mktemp -d); cp -R "$fixture/." "$tmp/"
    ( cd "$tmp" && eval "$3" )
    local out; out=$("$0" --root "$tmp" 2>&1); local got=$?
    if [ "$got" -eq 1 ] && grep -q "FAIL check $2" <<<"$out"; then
      printf 'ok    %s (check %s fired)\n' "$1" "$2"
    else
      printf 'FAIL  %s: expected exit 1 with "FAIL check %s", got exit %s\n' "$1" "$2" "$got"; rc=1
    fi
    rm -rf "$tmp"
  }

  expect_pass "the unmutated fixture passes every check"
  expect_fail "a broken relative link is rejected"  1 "sed -i.bak 's|(reference/hooks.md)|(reference/nope.md)|' plugins/dev-workflows/docs/README.md"
  expect_fail "a broken anchor is rejected"         2 "sed -i.bak 's|(getting-started.md#install)|(getting-started.md#no-such-heading)|' plugins/dev-workflows/docs/README.md"
  expect_fail "an orphan page is rejected"          3 "printf '# Orphan\n\nUnreachable.\n' > plugins/dev-workflows/docs/orphan.md"
  expect_fail "an undocumented command is rejected" 4 "printf -- '---\nname: delta\n---\n' > plugins/dev-workflows/commands/delta.md"
  expect_fail "a drifted subtree count is rejected" 4 "sed -i.bak 's|\`handoff/\` (2)|\`handoff/\` (3)|' plugins/dev-workflows/docs/reference/references.md"
  expect_fail "an undocumented env var is rejected" 5 "printf 'Reads \$NEW_SETTABLE_VAR here.\n' >> plugins/dev-workflows/commands/alpha.md"
  expect_fail "an over-long table cell is rejected" 6 "awk 'BEGIN{s=\"\"; while(length(s)<260) s=s \"x\"; printf \"\\n| a | %s |\\n|---|---|\\n| b | c |\\n\", s}' >> plugins/dev-workflows/docs/reference/hooks.md"
  expect_fail "a drifted install block is rejected" 7 "sed -i.bak 's|claude plugin install dev-workflows@fixture-plugins|claude plugin install dev-workflows@drifted|' plugins/dev-workflows/docs/getting-started.md"

  if [ "$rc" -eq 0 ]; then echo "SELFTEST PASS"; else echo "SELFTEST FAIL"; fi
  exit "$rc"
}

# ---------------------------------------------------------------------- main
[ "${1:-}" = "--selftest" ] && selftest

ROOT="."
if [ "${1:-}" = "--root" ]; then
  [ $# -lt 2 ] && { echo "Usage: $0 [--root <dir>] | --selftest" >&2; exit 2; }
  ROOT="$2"
fi
[ -d "$ROOT" ] || { echo "Usage: $0 [--root <dir>] | --selftest" >&2; exit 2; }
ROOT="$(cd "$ROOT" && pwd)"
[ -d "$ROOT/$PLUGIN_REL/docs" ] || { fail 4 "$PLUGIN_REL/docs does not exist"; echo "FAIL: $FAILURES problem(s)" >&2; exit 1; }

check_links_and_anchors "$ROOT"
check_orphans           "$ROOT"
check_inventory         "$ROOT"
check_env_vars          "$ROOT"
check_table_cells       "$ROOT"
check_install_block     "$ROOT"

if [ "$FAILURES" -gt 0 ]; then
  echo "FAIL: $FAILURES problem(s) under $PLUGIN_REL" >&2
  exit 1
fi
echo "PASS: docs are consistent with the plugin under $PLUGIN_REL"
```

Then: `chmod +x scripts/check-docs.sh`

- [ ] **Step 2: Build the passing fixture tree**

Create `scripts/fixtures/docs/pass/` — a minimal plugin that satisfies every check. Exactly these 18 files:

```bash
mkdir -p scripts/fixtures/docs/pass/plugins/dev-workflows/{commands,agents,references/model-routing,references/handoff,hooks,skills,docs/{commands,reference}}
cd scripts/fixtures/docs/pass

cat > README.md <<'EOF'
# fixture-marketplace

## Installation

```bash
claude plugin marketplace add example/fixture-plugins
claude plugin install dev-workflows@fixture-plugins
claude plugin marketplace update fixture-plugins
```
EOF

printf -- '---\nname: alpha\ndescription: A fixture command reading $SPECS_PATH.\n---\n' > plugins/dev-workflows/commands/alpha.md
printf -- '---\nname: beta\ndescription: A fixture agent.\n---\n' > plugins/dev-workflows/agents/beta.md
printf '# Gamma\n\nA fixture reference.\n' > plugins/dev-workflows/references/gamma.md
printf 'prices: {}\n' > plugins/dev-workflows/references/cost-prices.yaml
printf '# Classification\n\nA fixture routing reference.\n' > plugins/dev-workflows/references/model-routing/classification.md
printf '#!/usr/bin/env bash\nexit 0\n' > plugins/dev-workflows/hooks/notify-fixture.sh
printf '{"hooks":{}}\n' > plugins/dev-workflows/hooks/hooks.json
printf '# dev-workflows\n\nSee [the docs](docs/README.md).\n' > plugins/dev-workflows/README.md

cat > plugins/dev-workflows/docs/README.md <<'EOF'
# Documentation

- [Getting started](getting-started.md) and how to [install](getting-started.md#install)
- [alpha](commands/alpha.md)
- [Agents](reference/agents.md)
- [References](reference/references.md)
- [Environment](reference/environment.md)
- [Hooks](reference/hooks.md)
EOF

cat > plugins/dev-workflows/docs/getting-started.md <<'EOF'
# Getting started

## Install

```bash
claude plugin marketplace add example/fixture-plugins
claude plugin install dev-workflows@fixture-plugins
claude plugin marketplace update fixture-plugins
```

Set `$SPECS_PATH` before your first run. See [Hooks](reference/hooks.md) for the fixture hook.
EOF

printf '# /alpha\n\nA fixture command page.\n' > plugins/dev-workflows/docs/commands/alpha.md
printf '# Agents\n\n| Agent | Role |\n|---|---|\n| `beta` | fixture |\n' > plugins/dev-workflows/docs/reference/agents.md
printf '# References\n\n- `gamma.md`\n- `cost-prices.yaml`\n- `classification.md`\n- `handoff/` (2) — fixture subtree.\n' > plugins/dev-workflows/docs/reference/references.md
printf '# One\n\nA fixture handoff doc.\n' > plugins/dev-workflows/references/handoff/one.md
printf '# Two\n\nAnother fixture handoff doc.\n' > plugins/dev-workflows/references/handoff/two.md
printf '# Environment\n\n- **`SPECS_PATH`** — the fixture variable.\n' > plugins/dev-workflows/docs/reference/environment.md
printf '# Hooks\n\n| Hook | Trigger |\n|---|---|\n| `notify-fixture` | Stop |\n' > plugins/dev-workflows/docs/reference/hooks.md
```

- [ ] **Step 3: Run the selftest and watch every check fail on demand**

Run: `./scripts/check-docs.sh --selftest`

Expected: nine `ok` lines then `SELFTEST PASS` —

```
ok    the unmutated fixture passes every check
ok    a broken relative link is rejected (check 1 fired)
ok    a broken anchor is rejected (check 2 fired)
ok    an orphan page is rejected (check 3 fired)
ok    an undocumented command is rejected (check 4 fired)
ok    an undocumented env var is rejected (check 5 fired)
ok    an over-long table cell is rejected (check 6 fired)
ok    a drifted install block is rejected (check 7 fired)
ok    a drifted subtree count is rejected (check 4 fired)
SELFTEST PASS
```

If any case prints `FAIL`, fix the gate — **not** the assertion. A check that cannot be shown to fire is the exact defect `--selftest` exists to catch, and weakening the assertion reintroduces it.

- [ ] **Step 4: Run the gate against the real tree and confirm it is RED**

Run: `./scripts/check-docs.sh --root .`

Expected: exit 1, with `FAIL check 4: plugins/dev-workflows/docs does not exist`. This is the failing test the rest of the plan turns green. Record the exact output in the task report.

- [ ] **Step 5: Wire both into CI**

In `.github/workflows/validate-catalog.yml`, after the existing `Check requirement-ID grammar` step, append:

```yaml
      - name: Self-test the docs gate
        run: ./scripts/check-docs.sh --selftest

      - name: Check docs
        run: ./scripts/check-docs.sh --root .
```

Note that CI will now be red until Task 14 completes. That is intended and is stated in the PR description.

- [ ] **Step 6: Verify the other three gates still pass**

Run:
```bash
python3 scripts/validate-catalog.py && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root .
```
Expected: `0 error(s), 0 warning(s)`, `SELFTEST PASS`, `PASS: no dash-form requirement IDs under .`

- [ ] **Step 7: Commit**

```bash
git add scripts/check-docs.sh scripts/fixtures/docs .github/workflows/validate-catalog.yml
git commit -m "$(cat <<'EOF'
feat(gate): add scripts/check-docs.sh with seven checks and a selftest

Built before the docs so every page is authored against a live checker
rather than a described one. Currently RED against the real tree --
docs/ does not exist yet -- which is the failing test the restructure
turns green.

The selftest mutates a copy of one passing fixture tree once per check
and asserts both the exit code AND which check fired, so a mutation
that happens to trip a different check cannot register as success.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: The navigational spine — index, workflow, roles-and-phases

**Files:**
- Create: `plugins/dev-workflows/docs/README.md`
- Create: `plugins/dev-workflows/docs/workflow.md`
- Create: `plugins/dev-workflows/docs/roles-and-phases.md`

**Interfaces:**
- Consumes: `scripts/check-docs.sh` from Task 1.
- Produces: the link targets every later page uses — `../workflow.md`, `../roles-and-phases.md`, and the index every page must be reachable from. Command pages link **up** to these; these link **down** to command pages. Anchor names created here (`#pm`, `#pa`, `#pe`, `#dev`, `#team`, and one per phase) are referenced by Tasks 8–13, so they are fixed now and not renamed later.

- [ ] **Step 1: Write `docs/README.md`**

The index opens with the question a reader arrives with, not the catalog. Use exactly this table, then a full page list grouped as `Commands`, `Reference`:

```markdown
# dev-workflows documentation

| I want to… | Go to |
|---|---|
| install this and set it up | [Getting started](getting-started.md) |
| understand the whole pipeline first | [Workflow overview](workflow.md) |
| know what my role is responsible for | [Roles and phases](roles-and-phases.md) |
| turn a raw idea into something actionable | [`/idea`](commands/idea.md) |
| write or refresh a Value Increment | [`/create-vi`](commands/create-vi.md), [`/update-vi`](commands/update-vi.md) |
| record an architecture decision | [`/create-ard`](commands/create-ard.md) |
| break a VI into Epics | [`/epics`](commands/epics.md) |
| write a specification, then a design | [`/specify`](commands/specify.md), [`/design`](commands/design.md) |
| build the thing | [`/implement`](commands/implement.md) |
| document it, then announce it | [`/document`](commands/document.md), [`/release-notes`](commands/release-notes.md) |
| check whether a ticket is really ready | [`/ready`](commands/ready.md) |
| fix a CVE or upgrade a dependency | [`/vuln`](commands/vuln.md), [`/upgrade`](commands/upgrade.md) |
| tell the plugin it got something wrong | [`/feedback`](commands/feedback.md), [`/prompt`](commands/prompt.md) |
| review an API spec or a UI against guidelines | [`/api-guideline-reviewer`](commands/api-guideline-reviewer.md), [`/guideline-reviewer`](commands/guideline-reviewer.md) |
| understand what a run cost | [Session cost](reference/session-cost.md) |
```

Every one of the 34 pages must appear somewhere on this page or be linked from a page that is — check 3 enforces transitive reachability, so a page linked only from another orphan is still an orphan.

- [ ] **Step 2: Write `docs/workflow.md`**

Move the pipeline Mermaid from `plugins/dev-workflows/README.md:56-89` **verbatim** — it is correct and the user has called it out as valuable. Then carry the role table, the artifact homes, the sources-of-truth list, and the cross-cutting-commands list from `README.md:91-118`, each **re-derived** rather than copied:

```bash
# derive the role table's command lists rather than trusting the README's
sed -n '/^## 7\. Attribution/,/^## 8\./p' plugins/dev-workflows/references/cost-emission.md
```

Add, immediately under the diagram, one sentence linking to `roles-and-phases.md`: the diagram shows where each command sits; the companion page says what each role is accountable for.

- [ ] **Step 3: Write `docs/roles-and-phases.md`**

Two halves, both derived.

**Half one — one section per role**, with these exact headings so Tasks 8–13 can anchor to them: `## PM — product management`, `## PA — product architecture`, `## PE — product engineering`, `## Dev — build and deliver`, `## Team — verification`. For each: what the role owns, which commands it runs, what it consumes, what it produces, and **what it hands over at the seam**. Derive the seam behaviour from:

```bash
sed -n '/^## 2\./,/^## 4\./p' plugins/dev-workflows/references/phase-handoff.md
```

The handover model stated once, in plain terms: a producer lands its artifact on the specs repo's default branch via `handoff-to-main` (§2); the next command runs `require-on-main` (§3) and refuses to start expensive work until it finds it there. Name the two states a reader will actually hit — the artifact is on a branch but not merged (§3.3 rows D/E), and the artifact is absent entirely (row F) — and what each does.

**Half two — one entry per cost-attribution phase**, with these exact headings: `### vi-creation`, `### vi-update`, `### architecture`, `### specification`, `### epic-refinement`, `### planning`, `### implementation`, `### documenting`, `### readiness`. Each names the command that emits it and what being in that phase means. Source:

```bash
sed -n '265,300p' plugins/dev-workflows/references/cost-emission.md
```

Close half two with a short warning that a second, unrelated `phase:` vocabulary exists — the model-routing resume phases `full`, `verify-resume`, `regression-resume` that `/vuln` and `/upgrade` pass — and that the two share a field name and nothing else.

- [ ] **Step 4: Verify the three pages**

Run:
```bash
# every link in the three spine pages resolves to a file that exists or will exist
grep -ohE '\]\([^)#][^)]*\.md[^)]*\)' plugins/dev-workflows/docs/*.md | sed -E 's/^\]\(//; s/\)$//; s/#.*$//' | sort -u
# the Mermaid block moved intact
diff <(sed -n '/^```mermaid/,/^```$/p' plugins/dev-workflows/README.md | head -35) \
     <(sed -n '/^```mermaid/,/^```$/p' plugins/dev-workflows/docs/workflow.md | head -35)
# every phase heading required by check-free consumers exists
for h in vi-creation vi-update architecture specification epic-refinement planning implementation documenting readiness; do
  grep -q "^### $h\$" plugins/dev-workflows/docs/roles-and-phases.md || echo "MISSING phase heading: $h"
done
```
Expected: the link list contains only paths under `docs/`; the `diff` is empty; no `MISSING` lines.

- [ ] **Step 5: Verify no table cell regressed**

Run:

```bash
# A. Checks 2, 3 and 6 must be clean for the pages this task wrote. The `grep -v` is the
# task boundary, not a workaround: the pre-existing plugins/dev-workflows/README.md carries
# 45 over-long table cells, and check 6 first becomes able to see them the moment docs/
# exists, because before that the gate short-circuits. Those 45 belong to Task 14.
./scripts/check-docs.sh --root . 2>&1 | grep -E 'check (2|3|6)' | grep -v 'dev-workflows/README.md' \
  || echo "checks 2, 3, 6 clean"

# B. Check 1 is red BY DESIGN until Task 13: docs/README.md links forward to pages later
# tasks create. Asserting "check 1 is clean" would be unachievable, and ignoring check 1
# entirely would let a genuine typo hide among the expected failures. So assert the real
# invariant instead — every unresolved target is a PLANNED page:
PLANNED='^(getting-started\.md|workflow\.md|roles-and-phases\.md|commands/(api-guideline-reviewer|create-ard|create-vi|design|docs-profile|document|epics|feedback|guideline-reviewer|idea|implement|prompt|prompt-brainstorm|prompt-grill-me|ready|release-notes|specify|statusline|update-vi|upgrade|vuln)\.md|reference/(agents|references|environment|hooks|model-routing|session-cost|session-feedback|follow-ups|resume-and-checkpoints)\.md)$'
./scripts/check-docs.sh --root . 2>&1 | grep 'check 1' | sed -E 's/.*-> ([^ ]+) .*/\1/' | sort -u \
  | grep -vE "$PLANNED" || echo "every unresolved link targets a planned page — no typos"
```
Expected: `checks 2, 3, 6 clean` and `every unresolved link targets a planned page — no typos`.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/docs/README.md plugins/dev-workflows/docs/workflow.md plugins/dev-workflows/docs/roles-and-phases.md
git commit -m "$(cat <<'EOF'
docs: add the navigational spine -- index, workflow, roles-and-phases

The pipeline Mermaid moves verbatim; everything around it is
re-derived. roles-and-phases.md is the prose companion the diagram
cannot be: a flowchart shows that /specify sits between /epics and
/design, but not what a PE is accountable for or what they hand over.

Roles and phases derive from cost-emission.md section 7, the seam
behaviour from phase-handoff.md sections 2 and 3.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: `getting-started.md`

**Files:**
- Create: `plugins/dev-workflows/docs/getting-started.md`

**Interfaces:**
- Consumes: check 7 from Task 1, which pins this page's install commands to the repo-root README.
- Produces: the `#install` anchor that `docs/README.md` links to, and the second of the two files check 5 requires every environment variable to appear in.

- [ ] **Step 1: Derive the install and update commands**

Run:
```bash
grep -oE '^claude plugin (marketplace (add|update)|install) .*' README.md
```
Expected output — copy these four lines **verbatim** into the page; check 7 compares them character for character:
```
claude plugin marketplace add ihudak/ihudak-claude-plugins
claude plugin install dev-workflows@ihudak-plugins
claude plugin install dt-style-guide@ihudak-plugins
claude plugin install obsidian-llm-wiki@ihudak-plugins
claude plugin install acli@ihudak-plugins
claude plugin marketplace update ihudak-plugins
```

- [ ] **Step 2: Derive the complete variable set**

Run:
```bash
grep -rhoE '\$\{?[A-Z][A-Z0-9_]{2,}\}?' plugins/dev-workflows/{commands,agents,references,hooks,skills} 2>/dev/null \
  | tr -d '${}' | sort | uniq -c | sort -rn
```
Expected: `CLAUDE_PLUGIN_ROOT` 700 and `ARGUMENTS` 52 (both runtime — excluded), then the six user-settable ones: `SPECS_PATH` 248, `VAULT_PATH` 99, `REPOS_PATH` 59, `DOCS_PATH` 16, `GIT_USER_INITIALS` 12, `DEV_WORKFLOWS_COST_PRICES` 3. If a seventh user-settable variable appears, stop and report it — the plan's variable list is then incomplete and check 5 will reject the page.

- [ ] **Step 3: Write the page**

Sections in this order: `## Install` (the six lines from Step 1, inline — never a link), `## Update`, `## What you set on your machine`, `## Install the status line`, `## Your first run`.

`## What you set on your machine` explains each variable by **what it is**, not by where it points. A reader told `VAULT_PATH="$HOME/obsidian"` has been told a syntax, not a concept. Write one subsection each:

- **`VAULT_PATH`** — your **personal** knowledge store. Obsidian is the common case but nothing requires it: the plugin reads and writes plain markdown, so any markdown-backed store works. Holds the `jira-products/<KEY>/` tree the importer produces, your `Projects/<area>/<slug>/` idea and working files, Epic drafts, and release-notes drafts. Nothing here is expected to be team-visible.
- **`SPECS_PATH`** — the **shared, team-visible repository for the AI-authored documents**, and the reason a second store exists. Holds the VI, the ARD, `specification.md`, and `design.md` under `specifications/<KEY>-<slug>/`. It is the medium through which one role hands work to the next: a producer lands its artifact on the default branch, and the next command refuses to start expensive work until it finds it there. Link to `roles-and-phases.md` for the per-seam detail.
- **`REPOS_PATH`** — where your code clones live; one directory or a colon-separated list, defaulting to `/workspace`. Repos are matched by their `git remote get-url origin` slug, **never** by directory name — state this explicitly, it is the part that surprises people.
- **`DOCS_PATH`** — a **read-only** clone of the shipped product documentation. Matters most to `/document`, which prefers it as a docs-repo discovery hint; also grounds seven authoring commands against what is already published. Never written to; every miss is a silent, non-blocking skip.
- **`GIT_USER_INITIALS`** — your branch identifier. Branch naming is repo-rule-first: this fills the identity segment where a repo's documented convention has one, and is ignored where it does not.
- **`DEV_WORKFLOWS_COST_PRICES`** — optional path to your own price table, overriding the bundled `references/cost-prices.yaml`. The only one of the six a user may reasonably never set.

`## Your first run` walks one real invocation end to end. Use `/idea` — it is the pipeline's entry point and the only command needing no Jira key.

- [ ] **Step 4: Verify check 7 passes**

Run: `./scripts/check-docs.sh --root . 2>&1 | grep 'check 7' || echo "check 7 passes"`
Expected: `check 7 passes`

- [ ] **Step 5: Verify all six variables are present**

Run:
```bash
for v in SPECS_PATH VAULT_PATH REPOS_PATH DOCS_PATH GIT_USER_INITIALS DEV_WORKFLOWS_COST_PRICES; do
  grep -q "$v" plugins/dev-workflows/docs/getting-started.md || echo "MISSING: $v"
done
```
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/docs/getting-started.md
git commit -m "$(cat <<'EOF'
docs: getting-started owns install, update, and what each variable is FOR

Install and update are inline, not linked out to -- a getting-started
page whose first step is a link has failed at its one job. That makes
this the only docs/ page carrying edition identity, so check 7 pins its
command lines to the repo-root README.

All six user-settable variables are documented, including
DEV_WORKFLOWS_COST_PRICES, which was previously documented as a
settable variable nowhere (defect D4).

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `reference/environment.md` and `reference/hooks.md`

**Files:**
- Create: `plugins/dev-workflows/docs/reference/environment.md`
- Create: `plugins/dev-workflows/docs/reference/hooks.md`

**Interfaces:**
- Consumes: the variable set derived in Task 3 Step 2.
- Produces: the file check 5 scans in both directions. Variable entries **must** use the form `- **`$VAR`** — …`, because check 5's reverse direction extracts documented names with `grep -oE '\*\*`\$?[A-Z][A-Z0-9_]{2,}`\*\*'`. A different bullet shape makes the reverse check pass vacuously.

- [ ] **Step 1: Write `reference/environment.md`**

This page answers what each variable **is**, where `getting-started.md` answered what it is **for**. One subsection per variable, each stating: default value, resolution order, what happens when unset, what happens when it points somewhere unreadable, and the directory layout it expects. Derive the defaults:

```bash
grep -rhoE '\$\{[A-Z_]+:-[^}]+\}' plugins/dev-workflows/{commands,agents,references} | sort -u
```

Close with the directory-layout block from `README.md:80-96` (repo root), re-derived against the write paths the commands actually use:

```bash
grep -rhoE '\$(SPECS_PATH|VAULT_PATH)/[a-zA-Z0-9<>/_.-]+' plugins/dev-workflows/commands | sort -u | head -20
```

- [ ] **Step 2: Write `reference/hooks.md`**

Derive all four rows from `hooks.json`, not from the old README table:

```bash
python3 -c "
import json
d = json.load(open('plugins/dev-workflows/hooks/hooks.json'))
for evt, entries in d.get('hooks', {}).items():
    for e in entries:
        for h in e.get('hooks', []):
            print(evt, '|', e.get('matcher', '-'), '|', h.get('command', '').split('/')[-1])
"
```
Expected: four rows — `Stop | - | notify-done.sh`, `UserPromptSubmit | - | preload-context.sh`, `PostToolUse | Bash | test-notify.sh`, `PostToolUse | Edit|Write|MultiEdit | changelog-owners-reminder.sh`.

For each, read the script itself to state what it actually does, and say plainly that a hook never blocks Claude — all four exit 0 by contract.

- [ ] **Step 3: Verify check 5's reverse direction is not vacuous**

Run:
```bash
grep -oE '\*\*`\$?[A-Z][A-Z0-9_]{2,}`\*\*' plugins/dev-workflows/docs/reference/environment.md | tr -d '*`$' | sort
```
Expected: exactly the six names `DEV_WORKFLOWS_COST_PRICES DOCS_PATH GIT_USER_INITIALS REPOS_PATH SPECS_PATH VAULT_PATH`. If this prints nothing, the bullet shape is wrong and check 5's reverse direction is passing on an empty set — fix the page, not the check.

- [ ] **Step 4: Verify check 5 passes**

Run: `./scripts/check-docs.sh --root . 2>&1 | grep 'check 5' || echo "check 5 passes"`
Expected: `check 5 passes`

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/docs/reference/environment.md plugins/dev-workflows/docs/reference/hooks.md
git commit -m "$(cat <<'EOF'
docs: add reference/environment.md and reference/hooks.md

environment.md says what each variable IS -- default, resolution,
unset behaviour, expected layout -- where getting-started.md said what
it is FOR. hooks.json is the source for all four hook rows, not the
old README table.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: `reference/agents.md` and `reference/references.md`

**Files:**
- Create: `plugins/dev-workflows/docs/reference/agents.md`
- Create: `plugins/dev-workflows/docs/reference/references.md`

**Interfaces:**
- Produces: the two inventory files check 4 scans in both directions. Agent rows **must** start `| `<name>` |` — check 4's reverse direction extracts names with `grep -oE '^\| `[a-z-]+`'`. Reference-subtree counts **must** be written as `` `<dir>/` (<count>) `` — check 4 parses that exact shape.

- [ ] **Step 1: Derive the agent inventory**

```bash
for f in plugins/dev-workflows/agents/*.md; do
  n=$(basename "$f" .md)
  m=$(awk '/^---$/{c++; next} c==1 && /^model:/{print $2; exit}' "$f")
  t=$(awk '/^---$/{c++; next} c==1 && /^tools:/{print; exit}' "$f")
  printf '%s|%s|%s\n' "$n" "${m:-per routing}" "$t"
done
```
Expected: 34 rows, of which exactly 9 show `opus` — `ard-reviewer`, `code-review`, `design-reviewer`, `doc-reviewer`, `epic-reviewer`, `readiness-reviewer`, `risk-planner`, `spec-reviewer`, `vi-reviewer`. If the count is not 9, stop and report: the README's "nine Opus-backed" claim and this page would disagree.

- [ ] **Step 2: Write `reference/agents.md`**

Group by role — reviewers and planners, readers and scanners, writers, fixers, maintenance — with one table per group. Columns: `Agent`, `Model`, `Tools`, `What it does`, `Used by`. Take `What it does` from each agent's frontmatter `description`, rewritten for a human; take `Tools` from frontmatter `tools`; take `Used by` by deriving:

```bash
grep -rl 'dev-workflows:<agent-name>' plugins/dev-workflows/commands | sed 's|.*/||; s|\.md$||' | sort | tr '\n' ' '
```

Keep every cell under 200 characters — check 6 covers this page. A description that will not fit becomes prose below the table, not a longer cell.

- [ ] **Step 3: Derive the reference inventory**

```bash
echo "top-level:  $(ls plugins/dev-workflows/references/*.md | wc -l)"
echo "yaml:       $(ls plugins/dev-workflows/references/*.yaml | wc -l)"
echo "routing:    $(ls plugins/dev-workflows/references/model-routing/*.md | wc -l)"
for d in api-guidelines guidelines handoff dynatrace-docs upgrade fix-vuln; do
  echo "$d: $(find plugins/dev-workflows/references/$d -name '*.md' | wc -l)"
done
echo "grand total: $(find plugins/dev-workflows/references -type f | wc -l)"
```
Expected: top-level 36, yaml 1, routing 1, `api-guidelines` 24, `guidelines` 11, `handoff` 10, `dynatrace-docs` 6, `upgrade` 3, `fix-vuln` 2, grand total 98.

- [ ] **Step 4: Write `reference/references.md`**

Enumerate the 36 top-level references plus `cost-prices.yaml` plus `model-routing/classification.md`, grouped by concern — authoring formats, git and handoff, review and triage, grounding, session artifacts, environment. Then a `## Bundled reference sets` section naming the six subtrees with their counts in the exact shape check 4 parses:

```markdown
- `api-guidelines/` (24) — vendored Dynatrace REST API and IAM permission guidance, consulted by `/api-guideline-reviewer`.
- `guidelines/` (11) — vendored Dynatrace Experience Standards, consulted by `/guideline-reviewer`.
- `handoff/` (10) — agent output contracts, read by the agents themselves.
- `dynatrace-docs/` (6) — docs-repo profile defaults and owner data.
- `upgrade/` (3) — component-specific upgrade guidance.
- `fix-vuln/` (2) — CVE-remediation guidance.
```

State the arithmetic on the page so a reader can check it: 36 top-level markdown + `cost-prices.yaml` + `model-routing/classification.md` enumerated by name, plus 56 markdown pages counted across the six groups. Say explicitly that the group figures are **markdown-page counts**, and that four further files — `api-guidelines/template/openapi-template.yaml`, `dynatrace-docs/docs-profile.default.yml`, `dynatrace-docs/managed-owners.txt`, `guidelines/check_guidelines.py` — sit inside those groups and are deliberately not listed, being vendored data and templates rather than reference documents a reader would open.

- [ ] **Step 5: Verify both inventories, both directions**

Run:
```bash
diff <(ls plugins/dev-workflows/agents/*.md | sed 's|.*/||; s|\.md$||' | sort) \
     <(grep -oE '^\| `[a-z-]+`' plugins/dev-workflows/docs/reference/agents.md | tr -d '|` ' | sort) \
  && echo "agents match both ways"
./scripts/check-docs.sh --root . 2>&1 | grep 'check 4' | grep -v 'has no page at docs/commands' || echo "check 4 clean apart from command pages"
```
Expected: `agents match both ways`, then `check 4 clean apart from command pages` (command pages arrive in Tasks 8–13).

- [ ] **Step 6: Verify the subtree-count parse is not vacuous**

Run:
```bash
grep -oE '`[a-z-]+/` \([0-9]+\)' plugins/dev-workflows/docs/reference/references.md
```
Expected: exactly six lines. Empty output means the shape is wrong and check 4's subtree comparison is passing against `nothing` on both sides — fix the page, not the check.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/docs/reference/agents.md plugins/dev-workflows/docs/reference/references.md
git commit -m "$(cat <<'EOF'
docs: add reference/agents.md and reference/references.md

Both inventories derived from the tree, both checked in both
directions. The reference inventory is over FILES, not markdown:
references/ holds 98 files of which five are not markdown, and
cost-prices.yaml among them is user-overridable and therefore
user-facing (defect D5).

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: `reference/model-routing.md`

**Files:**
- Create: `plugins/dev-workflows/docs/reference/model-routing.md`

**Interfaces:**
- Consumes: nothing from earlier tasks beyond the gate.
- Produces: the `Gates` link target every command page's `## Gates` section uses for model-tier questions.

- [ ] **Step 1: Derive the content**

The single source of truth is `plugins/dev-workflows/references/model-routing/classification.md` (25,146 bytes). This page is a **user-facing summary of it**, not a second copy — the reference stays authoritative and the page links to it.

```bash
grep -n '^## ' plugins/dev-workflows/references/model-routing/classification.md
```

- [ ] **Step 2: Write the page**

Four sections only, because these are the four things a user can observe or influence:

1. `## What gets classified` — the four levels (`SIMPLE`, `MODERATE`, `SIGNIFICANT`, `HIGH-RISK`), what each means in practice, and which commands classify at all.
2. `## What classification changes` — an Opus planner and an Opus review gate on `SIGNIFICANT`/`HIGH-RISK`; nothing on the lower two.
3. `## What floors a classification` — the multi-source rule: more than one repo, or any directory input, floors `/implement` at `SIGNIFICANT`, overridable at plan approval.
4. `## The fallback chain` — Opus 5 → 4.8 → 4.7 → 4.6 → Sonnet 5 → Sonnet 4.6 → Sonnet 4.5, and that a user never picks a model directly.

Close with a link to `../../references/model-routing/classification.md` as the authority, stated as such.

- [ ] **Step 3: Verify no cell over 200 characters and no broken links**

Run: `./scripts/check-docs.sh --root . 2>&1 | grep -E 'check (1|2|6)' || echo "checks 1, 2, 6 clean"`
Expected: `checks 1, 2, 6 clean`

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/docs/reference/model-routing.md
git commit -m "$(cat <<'EOF'
docs: add reference/model-routing.md

A user-facing summary of the four things a user can observe or
influence, not a second copy of classification.md -- the reference
stays authoritative and the page links to it.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: The four session-artifact pages

**Files:**
- Create: `plugins/dev-workflows/docs/reference/session-cost.md`
- Create: `plugins/dev-workflows/docs/reference/session-feedback.md`
- Create: `plugins/dev-workflows/docs/reference/follow-ups.md`
- Create: `plugins/dev-workflows/docs/reference/resume-and-checkpoints.md`

**Interfaces:**
- Consumes: the phase and role vocabulary defined in Task 2's `roles-and-phases.md`; `session-cost.md` links to it rather than redefining it.
- Produces: `reference/session-cost.md`, which `docs/README.md` links to directly from the "understand what a run cost" row.

- [ ] **Step 1: Write `reference/session-cost.md`**

Four sections: `## Where cost files land`, `## How cost is computed`, `## How a run is attributed`, `## Reading a cost file`.

`## Reading a cost file` carries a **worked sample**, taken verbatim from `references/cost-emission.md:211-230` so it is real rather than invented:

```bash
sed -n '211,230p' plugins/dev-workflows/references/cost-emission.md
```

Walk the sample field by field: what `duration_s` measures, why `cost_computed_usd` and `cost_statusline_usd` can differ and which to trust, why `models:` has one row per model rather than one per agent, and what `cache_read_tokens` being far larger than `input_tokens` tells you about a run.

`## How a run is attributed` links to `roles-and-phases.md` for the phase and role vocabulary rather than restating it, and covers `$DEV_WORKFLOWS_COST_PRICES` as the way to override the bundled price table.

- [ ] **Step 2: Write `reference/session-feedback.md`**

Derive the entry format from `references/feedback-emission.md:37-92`, including the worked entry at line 58. Cover: what the four commands log, the `origin: manual` versus automatic distinction, where files land (`<VI-dir>/dev-workflows/<KEY>-feedback.md`), and the point the plugin README makes and this page should keep — committing these alongside the specs is expected and encouraged, because team-visible feedback is the purpose rather than clutter.

- [ ] **Step 3: Write `reference/follow-ups.md`**

Derive from `references/followup-emission.md`: the task-line format (§1), target-file resolution (§2), the vault-availability fallback ladder (§4), the dedupe rule (§5), what qualifies as a follow-up (§6), and the end-of-run batch preview (§7).

- [ ] **Step 4: Write `reference/resume-and-checkpoints.md`**

Derive from `references/session-hygiene.md`: the prepare-checkpoint that runs first and unconditionally for VI-scoped runs (§1), the role-aware suggestion (§2), mid-phase checkpoints (§3), the session-name aid (§4), and the five-rule contract (§5). Explain plainly what `resume.md` is for: picking a run back up in a fresh session without re-deriving what the last one already established.

- [ ] **Step 5: Verify the sample is verbatim**

Run:
```bash
diff <(sed -n '211,230p' plugins/dev-workflows/references/cost-emission.md) \
     <(sed -n '/^## 2026-07-09T14:22:33Z/,/^```$/p' plugins/dev-workflows/docs/reference/session-cost.md | head -20)
```
Expected: empty. A non-empty diff means the sample was retyped rather than copied, which is how a "worked example" starts documenting a format that does not exist.

- [ ] **Step 6: Verify the four pages are reachable and clean**

Run: `# A. Checks 2, 3 and 6 must be clean for the pages this task wrote. The `grep -v` is the
# task boundary, not a workaround: the pre-existing plugins/dev-workflows/README.md carries
# 45 over-long table cells, and check 6 first becomes able to see them the moment docs/
# exists, because before that the gate short-circuits. Those 45 belong to Task 14.
./scripts/check-docs.sh --root . 2>&1 | grep -E 'check (2|3|6)' | grep -v 'dev-workflows/README.md' \
  || echo "checks 2, 3, 6 clean"

# B. Check 1 is red BY DESIGN until Task 13: docs/README.md links forward to pages later
# tasks create. Asserting "check 1 is clean" would be unachievable, and ignoring check 1
# entirely would let a genuine typo hide among the expected failures. So assert the real
# invariant instead — every unresolved target is a PLANNED page:
PLANNED='^(getting-started\.md|workflow\.md|roles-and-phases\.md|commands/(api-guideline-reviewer|create-ard|create-vi|design|docs-profile|document|epics|feedback|guideline-reviewer|idea|implement|prompt|prompt-brainstorm|prompt-grill-me|ready|release-notes|specify|statusline|update-vi|upgrade|vuln)\.md|reference/(agents|references|environment|hooks|model-routing|session-cost|session-feedback|follow-ups|resume-and-checkpoints)\.md)$'
./scripts/check-docs.sh --root . 2>&1 | grep 'check 1' | sed -E 's/.*-> ([^ ]+) .*/\1/' | sort -u \
  | grep -vE "$PLANNED" || echo "every unresolved link targets a planned page — no typos"`
Expected: `checks 2, 3, 6 clean` and `every unresolved link targets a planned page — no typos`

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/docs/reference/session-cost.md plugins/dev-workflows/docs/reference/session-feedback.md plugins/dev-workflows/docs/reference/follow-ups.md plugins/dev-workflows/docs/reference/resume-and-checkpoints.md
git commit -m "$(cat <<'EOF'
docs: split session artifacts into four pages

One page per artifact family, so cost gets room for a worked sample
entry and a field-by-field walkthrough rather than a paragraph. The
sample is copied verbatim from cost-emission.md, not retyped -- a
worked example that drifts documents a format that does not exist.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Command pages — PM (`/idea`, `/create-vi`, `/update-vi`)

**Files:**
- Create: `plugins/dev-workflows/docs/commands/idea.md`
- Create: `plugins/dev-workflows/docs/commands/create-vi.md`
- Create: `plugins/dev-workflows/docs/commands/update-vi.md`

**Interfaces:**
- Consumes: the role anchors from `docs/roles-and-phases.md` (`#pm--product-management`) and the phase anchors (`#vi-creation`, `#vi-update`), both created in Task 2.
- Produces: `docs/commands/<name>.md` for three of the 21 files check 4 requires.

### The command page contract (applies to all three pages)

Seven sections, in this order, every page identical:

```markdown
# /<name>

<One sentence: what this is for.>

## Who runs it
## Synopsis
## How it runs        (only when the command dispatches >=2 subagents — see Step 2)
## What it needs
## What it produces
## Gates
## Example
## See also
```

**Derivation is mandatory. The old README is a source of topics, never of facts.** For each page run these against `plugins/dev-workflows/commands/<name>.md` and write only what they return:

```bash
C=plugins/dev-workflows/commands/<name>.md
awk '/^---$/{n++; if(n==2) exit} n>=1' "$C"                    # purpose sentence source
grep -nE '^## (Phase|Step) ' "$C"                              # phase flow + node budget
grep -oE 'dev-workflows:[a-z-]+' "$C" | sed 's/dev-workflows://' | sort -u \
  | while read -r a; do [ -f "plugins/dev-workflows/agents/$a.md" ] && echo "$a"; done   # subagents
grep -noE '\$\{?[A-Z][A-Z0-9_]{2,}\}?' "$C" | sort -u -t: -k2  # what it needs
grep -nE 'require-on-main|handoff-to-main|commit-artifacts|specs-preflight' "$C"  # gated inputs + handoff
grep -nE '\-reviewer|code-review|style-checker' "$C"           # review gates
grep -noE '(specification|design|idea)\.md|<KEY>[a-zA-Z_-]*\.md' "$C" | sort -u -t: -k2  # artifacts
```

**`## Who runs it`** states the role from `references/cost-emission.md` §7, never from README prose. For this batch: `/idea` and `/create-vi` are `phase: vi-creation, role: pm`; `/update-vi` is `phase: vi-update, role: pm`. Link the role word to `../roles-and-phases.md#pm--product-management` and the phase word to the matching `###` anchor.

**`## What it needs`** states each prerequisite **together with its absent-case behaviour**. This is the section today's README has nowhere: a reader currently learns `/create-vi` gates on `idea.md` only by running it and hitting `require-on-main`.

**`## Gates`** names the reviewer, whether it is Opus-pinned, and what a `BLOCK` verdict does. `/idea` has no reviewer — its bounded grill is the gate — and the page says so rather than omitting the section.

**Rules that apply to every cell and line:** no table cell over 200 characters (check 6); prose paragraphs unbroken on one line; requirement IDs in `[US#1]` form only; no `[U01]`/`[ACxx]`-style spec-ID literals anywhere.

- [ ] **Step 1: Write `docs/commands/idea.md`**

Derive with the block above. Expected findings, to check your derivation against: 9 phase headings (`Phase 0` validate environment + model routing, `1` classify the source, `2` ingest via `idea-reader`, `2.5` docs + vault prior-art grounding, `2.6` code grounding, `3` refine via grill, `4` write `idea.md`, `5` handoff, `6` session maintenance); 3 subagents (`idea-reader`, `code-scanner`, `impl-maintenance`).

`## Synopsis` covers the four input forms and the four flags, derived from Phase 1: `/idea <prompt | @file | JIRA-KEY> [--deep] [--ground-code [<repo>,…]] [--no-docs] [--no-prior-art]`. Explain each form separately — an inline prompt, a markdown file with wikilinks and images, a community post, and an exported Jira ticket (which is typed from the export's `issue_type`, not from the project prefix).

`## What it produces`: `idea.md`, written under `$VAULT_PATH` while keyless, then relocated by Phase 5 into `$SPECS_PATH/specifications/<KEY>-<slug>/` once a Jira key resolves. Say plainly that relocation is `/idea`'s alone — `/create-vi <KEY>` finds it there and never moves it.

- [ ] **Step 2: Add the `## How it runs` diagram**

All three commands in this batch dispatch ≥2 subagents (`/idea` 3, `/create-vi` 2, `/update-vi` 2), so all three get a diagram. Labels come from the `## Phase N` headings verbatim; a diagram may collapse consecutive phases into one node where they form a single user-visible step, but **may never introduce a node no heading backs**. Node budgets: `/idea` ≤9, `/create-vi` ≤12, `/update-vi` ≤11.

Verify the counting rule yourself rather than trusting the numbers above:
```bash
for n in idea create-vi update-vi; do
  C=plugins/dev-workflows/commands/$n.md
  printf '%s: phases=%s agents=%s\n' "$n" \
    "$(grep -cE '^## (Phase|Step) ' $C)" \
    "$(grep -oE 'dev-workflows:[a-z-]+' $C | sed 's/dev-workflows://' | sort -u | while read -r a; do [ -f plugins/dev-workflows/agents/$a.md ] && echo x; done | wc -l)"
done
```
Expected: `idea: phases=9 agents=3`, `create-vi: phases=12 agents=2`, `update-vi: phases=11 agents=2`.

- [ ] **Step 3: Write `docs/commands/create-vi.md`**

Derive with the block above. `## What it needs` must cover the two argument shapes and their different gating, because they behave differently and the difference is invisible today: `/create-vi <KEY>` derives `idea.md` in-contract from the resolved feature folder and gates it via `require-on-main`; an explicit `@<path>` argument is out-of-contract — read where it sits, never relocated, never gated.

`## Gates`: `vi-reviewer`, Opus-pinned. Also state what `/create-vi` deliberately does **not** capture — `release_versions`, `change_type`, `release_notes_category` are Jira-mirror fields set as Jira dropdowns and returned by the importer, and `vi-reviewer` neither requires nor validates them.

- [ ] **Step 4: Write `docs/commands/update-vi.md`**

Derive with the block above. The one thing this page must make unmissable: `/update-vi` is the single authoring command **deliberately excluded** from `require-on-main`, because its base is the Jira import rather than a gated specs artifact. Confirm before writing:
```bash
grep -c 'require-on-main' plugins/dev-workflows/commands/update-vi.md
```
Expected: `0`. A non-zero result means the exclusion no longer holds and the page must describe what actually happens — report it rather than writing the exclusion from this plan.

- [ ] **Step 5: Verify the three pages**

Run:
```bash
for n in idea create-vi update-vi; do
  P=plugins/dev-workflows/docs/commands/$n.md
  for s in "## Who runs it" "## Synopsis" "## How it runs" "## What it needs" "## What it produces" "## Gates" "## Example" "## See also"; do
    grep -qF "$s" "$P" || echo "$n MISSING $s"
  done
done
# A. Checks 2, 3 and 6 must be clean for the pages this task wrote. The `grep -v` is the
# task boundary, not a workaround: the pre-existing plugins/dev-workflows/README.md carries
# 45 over-long table cells, and check 6 first becomes able to see them the moment docs/
# exists, because before that the gate short-circuits. Those 45 belong to Task 14.
./scripts/check-docs.sh --root . 2>&1 | grep -E 'check (2|3|6)' | grep -v 'dev-workflows/README.md' \
  || echo "checks 2, 3, 6 clean"

# B. Check 1 is red BY DESIGN until Task 13: docs/README.md links forward to pages later
# tasks create. Asserting "check 1 is clean" would be unachievable, and ignoring check 1
# entirely would let a genuine typo hide among the expected failures. So assert the real
# invariant instead — every unresolved target is a PLANNED page:
PLANNED='^(getting-started\.md|workflow\.md|roles-and-phases\.md|commands/(api-guideline-reviewer|create-ard|create-vi|design|docs-profile|document|epics|feedback|guideline-reviewer|idea|implement|prompt|prompt-brainstorm|prompt-grill-me|ready|release-notes|specify|statusline|update-vi|upgrade|vuln)\.md|reference/(agents|references|environment|hooks|model-routing|session-cost|session-feedback|follow-ups|resume-and-checkpoints)\.md)$'
./scripts/check-docs.sh --root . 2>&1 | grep 'check 1' | sed -E 's/.*-> ([^ ]+) .*/\1/' | sort -u \
  | grep -vE "$PLANNED" || echo "every unresolved link targets a planned page — no typos"
```
Expected: no `MISSING` lines; `checks 2, 3, 6 clean` and `every unresolved link targets a planned page — no typos`.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/docs/commands/idea.md plugins/dev-workflows/docs/commands/create-vi.md plugins/dev-workflows/docs/commands/update-vi.md
git commit -m "$(cat <<'EOF'
docs: add PM command pages -- /idea, /create-vi, /update-vi

Every claim re-derived from the command files. Roles come from
cost-emission.md section 7, not README prose.

"What it needs" states each prerequisite with its absent-case
behaviour -- the section the old README had nowhere. /create-vi's two
argument shapes gate differently and the difference was invisible: a
KEY derives idea.md in-contract and gates it, an explicit @path is
out-of-contract and is never gated or relocated.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Command pages — PA and PE (`/create-ard`, `/epics`, `/specify`)

**Files:**
- Create: `plugins/dev-workflows/docs/commands/create-ard.md`
- Create: `plugins/dev-workflows/docs/commands/epics.md`
- Create: `plugins/dev-workflows/docs/commands/specify.md`

**Interfaces:**
- Consumes: role anchors `#pa--product-architecture` and `#pe--product-engineering`, phase anchors `#architecture`, `#epic-refinement`, `#specification`, all from Task 2.
- Produces: three more of the 21 files check 4 requires.

### The command page contract (applies to all three pages)

Seven sections, in this order, every page identical:

```markdown
# /<name>

<One sentence: what this is for.>

## Who runs it
## Synopsis
## How it runs        (all three qualify — each dispatches >=2 subagents)
## What it needs
## What it produces
## Gates
## Example
## See also
```

**Derivation is mandatory. The old README is a source of topics, never of facts.** For each page run these against `plugins/dev-workflows/commands/<name>.md` and write only what they return:

```bash
C=plugins/dev-workflows/commands/<name>.md
awk '/^---$/{n++; if(n==2) exit} n>=1' "$C"
grep -nE '^## (Phase|Step) ' "$C"
grep -oE 'dev-workflows:[a-z-]+' "$C" | sed 's/dev-workflows://' | sort -u \
  | while read -r a; do [ -f "plugins/dev-workflows/agents/$a.md" ] && echo "$a"; done
grep -noE '\$\{?[A-Z][A-Z0-9_]{2,}\}?' "$C" | sort -u -t: -k2
grep -nE 'require-on-main|handoff-to-main|commit-artifacts|specs-preflight' "$C"
grep -nE '\-reviewer|code-review|style-checker' "$C"
grep -noE '(specification|design|idea)\.md|<KEY>[a-zA-Z_-]*\.md' "$C" | sort -u -t: -k2
```

**`## Who runs it`** states the role from `references/cost-emission.md` §7: `/create-ard` is `phase: architecture, role: pa`; `/epics` is `phase: epic-refinement, role: pe`; `/specify` is `phase: specification, role: pe`.

**`## What it needs`** states each prerequisite together with its absent-case behaviour.

**Rules that apply to every cell and line:** no table cell over 200 characters (check 6); prose paragraphs unbroken on one line; requirement IDs in `[US#1]` / `[AD#1]` form only; no spec-ID literals.

- [ ] **Step 1: Confirm the diagram trigger and node budgets**

```bash
for n in create-ard epics specify; do
  C=plugins/dev-workflows/commands/$n.md
  printf '%s: phases=%s agents=%s\n' "$n" \
    "$(grep -cE '^## (Phase|Step) ' $C)" \
    "$(grep -oE 'dev-workflows:[a-z-]+' $C | sed 's/dev-workflows://' | sort -u | while read -r a; do [ -f plugins/dev-workflows/agents/$a.md ] && echo x; done | wc -l)"
done
```
Expected: `create-ard: phases=11 agents=4`, `epics: phases=20 agents=6`, `specify: phases=13 agents=4`. All three exceed the threshold, so all three get a diagram; node budgets are the phase counts.

- [ ] **Step 2: Write `docs/commands/create-ard.md`**

Two things this page must get right, both derived rather than assumed. First, `/create-ard` grounds on **mounted repos it discovers** — a `$REPOS_PATH` listing, a theme-to-repo proposal, then confirm-or-descope — and it **never reads PRs**. Second, its `[AD#N]` decisions bind six downstream commands, and an `AD#N` Rule violated without a recorded "ARD deviation" is a reviewer BLOCKER; name the six from `references/ard-resolution.md` rather than from memory:

```bash
grep -rln 'ard-resolution' plugins/dev-workflows/commands | sed 's|.*/||; s|\.md$||' | sort | tr '\n' ' '
```

`## Gates`: `ard-reviewer`, Opus-pinned.

- [ ] **Step 3: Write `docs/commands/epics.md`**

`/epics` is the one authoring command that **never branches** — state it explicitly with the reason, since every neighbouring command does. Its style checker is `dt-style-checker` as primary, skipped gracefully when `dt-style-guide` is not installed. `## Gates`: `epic-reviewer`, Opus-pinned, with orchestrator-run finding triage between the reviewer and `doc-fixer`.

`## What it produces`: Epic drafts under `$VAULT_PATH/jira-drafts/<VI-KEY>/`. Note that `/epics` also runs `resolve-docs-grounding` before `require-on-main`, which is a deliberate ordering exception — say so, because a reader comparing it to the other PE command will notice.

- [ ] **Step 4: Write `docs/commands/specify.md`**

Derive from the 13 phase headings: `Phase 0` resolve input, `1` configure, `1.5` classify, `2` read Jira, `2.5` resolve applicable ARD, `3` derive repos + soft gate, `4` light code scan, `5` author via grill, `5.5` structural pre-lint, `6` finalize + review gate, `7` handoff, `8` session maintenance & feedback, `9` session cost.

`## Synopsis` must cover the VI-level path, because it is genuinely optional and the README buries it: `/specify <VI>` with no focus Epic is valid and stays in the PE lane. For a VI with ≥2 Epics, Phase 2 renders the Epic picker and offers three paths — pick one Epic, author one broad VI-level spec, or split into Epics first with `/epics`. For a single-Epic VI it auto-resolves to that Epic.

`## Gates`: `spec-reviewer`, Opus-pinned. `## What it produces`: `specification.md` landed on the specs repo's default branch via branch + PR, plus `idea.md`, `_session.md`, `_glossary.md` and a rendered `.html` in the feature folder.

- [ ] **Step 5: Verify the three pages**

```bash
for n in create-ard epics specify; do
  P=plugins/dev-workflows/docs/commands/$n.md
  for s in "## Who runs it" "## Synopsis" "## How it runs" "## What it needs" "## What it produces" "## Gates" "## Example" "## See also"; do
    grep -qF "$s" "$P" || echo "$n MISSING $s"
  done
done
# A. Checks 2, 3 and 6 must be clean for the pages this task wrote. The `grep -v` is the
# task boundary, not a workaround: the pre-existing plugins/dev-workflows/README.md carries
# 45 over-long table cells, and check 6 first becomes able to see them the moment docs/
# exists, because before that the gate short-circuits. Those 45 belong to Task 14.
./scripts/check-docs.sh --root . 2>&1 | grep -E 'check (2|3|6)' | grep -v 'dev-workflows/README.md' \
  || echo "checks 2, 3, 6 clean"

# B. Check 1 is red BY DESIGN until Task 13: docs/README.md links forward to pages later
# tasks create. Asserting "check 1 is clean" would be unachievable, and ignoring check 1
# entirely would let a genuine typo hide among the expected failures. So assert the real
# invariant instead — every unresolved target is a PLANNED page:
PLANNED='^(getting-started\.md|workflow\.md|roles-and-phases\.md|commands/(api-guideline-reviewer|create-ard|create-vi|design|docs-profile|document|epics|feedback|guideline-reviewer|idea|implement|prompt|prompt-brainstorm|prompt-grill-me|ready|release-notes|specify|statusline|update-vi|upgrade|vuln)\.md|reference/(agents|references|environment|hooks|model-routing|session-cost|session-feedback|follow-ups|resume-and-checkpoints)\.md)$'
./scripts/check-docs.sh --root . 2>&1 | grep 'check 1' | sed -E 's/.*-> ([^ ]+) .*/\1/' | sort -u \
  | grep -vE "$PLANNED" || echo "every unresolved link targets a planned page — no typos"
```
Expected: no `MISSING` lines; `checks 2, 3, 6 clean` and `every unresolved link targets a planned page — no typos`.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/docs/commands/create-ard.md plugins/dev-workflows/docs/commands/epics.md plugins/dev-workflows/docs/commands/specify.md
git commit -m "$(cat <<'EOF'
docs: add PA and PE command pages -- /create-ard, /epics, /specify

Every claim re-derived. Three things the old README buried and these
pages state plainly: /create-ard grounds on mounted repos and never
reads PRs; /epics is the one authoring command that never branches;
and /specify's VI-level path is genuinely valid, with a three-way
offer when the VI has two or more Epics.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Command pages — Dev build (`/design`, `/implement`)

**Files:**
- Create: `plugins/dev-workflows/docs/commands/design.md`
- Create: `plugins/dev-workflows/docs/commands/implement.md`

**Interfaces:**
- Consumes: role anchor `#dev--build-and-deliver` and phase anchors `#planning`, `#implementation`, from Task 2. Also `../reference/model-routing.md` from Task 6, which both `## Gates` sections link to.
- Produces: two more of the 21 files check 4 requires. `docs/commands/implement.md` receives the `/implement` Mermaid moved out of `plugins/dev-workflows/README.md:202-215`.

### The command page contract (applies to both pages)

Seven sections, in this order, both pages identical:

```markdown
# /<name>

<One sentence: what this is for.>

## Who runs it
## Synopsis
## How it runs        (both qualify — each dispatches >=2 subagents)
## What it needs
## What it produces
## Gates
## Example
## See also
```

**Derivation is mandatory. The old README is a source of topics, never of facts.** For each page:

```bash
C=plugins/dev-workflows/commands/<name>.md
awk '/^---$/{n++; if(n==2) exit} n>=1' "$C"
grep -nE '^## (Phase|Step) ' "$C"
grep -oE 'dev-workflows:[a-z-]+' "$C" | sed 's/dev-workflows://' | sort -u \
  | while read -r a; do [ -f "plugins/dev-workflows/agents/$a.md" ] && echo "$a"; done
grep -noE '\$\{?[A-Z][A-Z0-9_]{2,}\}?' "$C" | sort -u -t: -k2
grep -nE 'require-on-main|handoff-to-main|commit-artifacts|specs-preflight' "$C"
grep -nE '\-reviewer|code-review|style-checker|test-baseliner|test-writer' "$C"
```

**`## Who runs it`**: both are `role: dev` per `references/cost-emission.md` §7 — `/design` is `phase: planning`, `/implement` is `phase: implementation`.

**Rules:** no table cell over 200 characters; prose paragraphs unbroken on one line; requirement IDs in `[US#1]` / `[AC#1]` form only; no `[U01]`/`[ACxx]`-style spec-ID literals.

- [ ] **Step 1: Confirm the trigger and node budgets**

```bash
for n in design implement; do
  C=plugins/dev-workflows/commands/$n.md
  printf '%s: phases=%s agents=%s\n' "$n" \
    "$(grep -cE '^## (Phase|Step) ' $C)" \
    "$(grep -oE 'dev-workflows:[a-z-]+' $C | sed 's/dev-workflows://' | sort -u | while read -r a; do [ -f plugins/dev-workflows/agents/$a.md ] && echo x; done | wc -l)"
done
```
Expected: `design: phases=13 agents=4`, `implement: phases=17 agents=8`.

- [ ] **Step 2: Write `docs/commands/design.md`**

Three things this page owes a reader, all derived. First, `/design`'s code-scan gate is **STRICT**, where `/specify`'s is soft — the difference is real and the README does not draw it. Second, Phase 5 offers a three-take `interface-designer` fan-out on a contested interface, one take per constraint (minimise the interface, maximise flexibility, optimise for the most common caller); `--design-twice` forces the fan-out and skips the offer, because a user who typed the flag has already answered what the offer would ask. Third, declining the offer costs nothing — the interview continues and `design.md`'s unconditional `### Alternatives considered` requirement is satisfied by hand as it would have been anyway.

Confirm the contested-interface signals rather than listing them from memory:
```bash
sed -n '/^## Seams/,/^## /p' plugins/dev-workflows/references/design-format.md | grep -nE '^\s*[0-9]+\.|^\s*[-*] '
```

`## Gates`: `design-reviewer`, Opus-pinned, and it treats **any unresolved open question in `design.md` as a BLOCKER** — state that, it is the gate people hit.

- [ ] **Step 3: Write `docs/commands/implement.md`, moving the Mermaid**

Move the `/implement` flowchart from `plugins/dev-workflows/README.md:202-215` **verbatim** into `## How it runs`. Verify it moved intact:
```bash
diff <(sed -n '202,215p' plugins/dev-workflows/README.md) \
     <(sed -n '/^```mermaid/,/^```$/p' plugins/dev-workflows/docs/commands/implement.md)
```
Expected: empty, or differing only in surrounding blank lines.

`## Synopsis` covers the shared Jira-input grammar — a JiraID (VI or Epic), an imported-Jira directory, or a direct prompt / `@file` (also `@spec` / `@repo`) — optionally with a focus Epic. For a multi-Epic VI it renders the progress-aware Epic picker and implements **one Epic per run**.

`## What it needs` must state the multi-source rule and what it costs: more than one repo, or any directory input, floors classification at `SIGNIFICANT` (overridable at plan approval) and triggers the Phase 1.7 fan-out scan. Also state the invariant a reader will care about most — a referenced directory that is missing or unrecognized is surfaced, never silently skipped.

`## Gates` covers the full chain in order: test baseline captured **before** any source edits; Opus `code-review` **before** tests on `SIGNIFICANT`/`HIGH-RISK`; orchestrator-run finding triage between the review and `review-fixer`, with the fixer handed survivors only; `test-writer` mandatory for code changes, and surfaced explicitly rather than skipped when no framework is detected.

- [ ] **Step 4: Verify both pages**

```bash
for n in design implement; do
  P=plugins/dev-workflows/docs/commands/$n.md
  for s in "## Who runs it" "## Synopsis" "## How it runs" "## What it needs" "## What it produces" "## Gates" "## Example" "## See also"; do
    grep -qF "$s" "$P" || echo "$n MISSING $s"
  done
done
# A. Checks 2, 3 and 6 must be clean for the pages this task wrote. The `grep -v` is the
# task boundary, not a workaround: the pre-existing plugins/dev-workflows/README.md carries
# 45 over-long table cells, and check 6 first becomes able to see them the moment docs/
# exists, because before that the gate short-circuits. Those 45 belong to Task 14.
./scripts/check-docs.sh --root . 2>&1 | grep -E 'check (2|3|6)' | grep -v 'dev-workflows/README.md' \
  || echo "checks 2, 3, 6 clean"

# B. Check 1 is red BY DESIGN until Task 13: docs/README.md links forward to pages later
# tasks create. Asserting "check 1 is clean" would be unachievable, and ignoring check 1
# entirely would let a genuine typo hide among the expected failures. So assert the real
# invariant instead — every unresolved target is a PLANNED page:
PLANNED='^(getting-started\.md|workflow\.md|roles-and-phases\.md|commands/(api-guideline-reviewer|create-ard|create-vi|design|docs-profile|document|epics|feedback|guideline-reviewer|idea|implement|prompt|prompt-brainstorm|prompt-grill-me|ready|release-notes|specify|statusline|update-vi|upgrade|vuln)\.md|reference/(agents|references|environment|hooks|model-routing|session-cost|session-feedback|follow-ups|resume-and-checkpoints)\.md)$'
./scripts/check-docs.sh --root . 2>&1 | grep 'check 1' | sed -E 's/.*-> ([^ ]+) .*/\1/' | sort -u \
  | grep -vE "$PLANNED" || echo "every unresolved link targets a planned page — no typos"
```
Expected: no `MISSING` lines; `checks 2, 3, 6 clean` and `every unresolved link targets a planned page — no typos`.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/docs/commands/design.md plugins/dev-workflows/docs/commands/implement.md
git commit -m "$(cat <<'EOF'
docs: add Dev build command pages -- /design, /implement

The /implement Mermaid moves verbatim out of the README. Two
distinctions the README never drew, both now stated: /design's code
scan is a STRICT gate where /specify's is soft, and design-reviewer
treats any unresolved open question as a BLOCKER.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Command pages — Dev delivery (`/document`, `/release-notes`)

**Files:**
- Create: `plugins/dev-workflows/docs/commands/document.md`
- Create: `plugins/dev-workflows/docs/commands/release-notes.md`

**Interfaces:**
- Consumes: role anchors `#pm--product-management` and `#dev--build-and-deliver`, phase anchors `#vi-creation` and `#documenting`, from Task 2. `/release-notes` links to **both** roles — it is the dual-role case.
- Produces: two more of the 21 files check 4 requires.

### The command page contract (applies to both pages)

Seven sections, in this order, both pages identical:

```markdown
# /<name>

<One sentence: what this is for.>

## Who runs it
## Synopsis
## How it runs        (both qualify — each dispatches >=2 subagents)
## What it needs
## What it produces
## Gates
## Example
## See also
```

**Derivation is mandatory. The old README is a source of topics, never of facts.** For each page:

```bash
C=plugins/dev-workflows/commands/<name>.md
awk '/^---$/{n++; if(n==2) exit} n>=1' "$C"
grep -nE '^## (Phase|Step) ' "$C"
grep -oE 'dev-workflows:[a-z-]+' "$C" | sed 's/dev-workflows://' | sort -u \
  | while read -r a; do [ -f "plugins/dev-workflows/agents/$a.md" ] && echo "$a"; done
grep -noE '\$\{?[A-Z][A-Z0-9_]{2,}\}?' "$C" | sort -u -t: -k2
grep -nE 'require-on-main|handoff-to-main|commit-artifacts|specs-preflight' "$C"
grep -nE '\-reviewer|style-checker|gate-ledger' "$C"
```

**Rules:** no table cell over 200 characters; prose paragraphs unbroken on one line; requirement IDs bracketed; no spec-ID literals.

- [ ] **Step 1: Confirm the trigger and node budgets**

```bash
for n in document release-notes; do
  C=plugins/dev-workflows/commands/$n.md
  printf '%s: phases=%s agents=%s\n' "$n" \
    "$(grep -cE '^## (Phase|Step) ' $C)" \
    "$(grep -oE 'dev-workflows:[a-z-]+' $C | sed 's/dev-workflows://' | sort -u | while read -r a; do [ -f plugins/dev-workflows/agents/$a.md ] && echo x; done | wc -l)"
done
```
Expected: `document: phases=37 agents=10`, `release-notes: phases=14 agents=3`. `/document` has the most phases of any command; its diagram **must** collapse consecutive phases into user-visible steps rather than drawing 37 nodes — a 37-node flowchart is not a diagram, it is the file. Collapse to the mode structure a reader navigates by, and say in prose that the page shows the shape rather than every phase.

- [ ] **Step 2: Write `docs/commands/document.md`**

This is the largest page. Its organising fact is that `/document` has **two modes** with materially different behaviour, and a reader must know which one they are in before anything else on the page applies. Structure `## Synopsis` and `## How it runs` around that split.

Direct mode invariants to state: no branch by default; no `test-baseliner`, no `test-writer`, no `code-review`; a mandatory style check and `doc-fixer`, but **no** `doc-reviewer` gate — and therefore no BLOCKER fix cycle, no re-review, and no finding triage, because a linter violation is a deterministic match with nothing to trace. Mixed code + docs changes use `/implement` instead.

Jira mode invariants to state: zero direct API calls, with PR URLs treated as identifiers only — GitHub resolution may use the `gh` CLI, Bitbucket is pure local `git`, and all resolution runs against clones under `$REPOS_PATH` matched by `git remote get-url origin` slug. Branch policy classifies the **resolved `docs_repo_path`**, not the current working directory. Jira-vs-source discrepancies are escalated in Phase 5.8, never auto-resolved.

`## Gates` covers the gate ledger: every gate in the registry appends its row when the gate completes, and a missing row, an unconverted `UNAVAILABLE`, or an unattributed skip is a `doc-reviewer` BLOCKER. Link to `../reference/session-cost.md` only for cost; the ledger itself is `/document`-specific and stays on this page.

- [ ] **Step 3: Write `docs/commands/release-notes.md` with both role variants**

This is the page the whole "Who runs it" design exists for. `## Who runs it` explains **both** variants separately and states the discriminator, derived rather than paraphrased:

```bash
sed -n '/^\*\*`\/release-notes` inference/,/^\*\*Epic presence/p' plugins/dev-workflows/references/cost-emission.md
```

Expected: the discriminator is the presence of downstream engineering artifacts — no `specification.md` or `design.md` under the VI's specs dir means `phase: vi-creation, role: pm` (the PM's early bare-VI run); either present means `phase: documenting, role: dev` (the dev's documenting re-run). Epic presence is deliberately **not** part of the signal, because a VI can have drafted Epics while still in PM hands. State that reasoning — it is the part that stops a reader assuming the tool got it wrong.

Then say what actually differs between the two runs for the person doing them, not just how the cost file is labelled.

`## What it produces`: the **authored body only** — for a titled destination a `{{#context}}` label, an `### title`, and customer-facing prose; for `fixes`, one bare past-tense sentence. Never a Jira ID, a PR link, a `Change type:` line, or a `{{#internal-note}}` block, because the docs automation adds the metadata wrapper. Exactly one Summary per run, and no title or prose names the release version.

`## What it needs`: the run is gated on the imported `relevant_for_release_notes` — an explicit `false` stops with `RELEASE_NOTES_NOT_RELEVANT` (overridable); absent proceeds silently. A deprecation requires an end-of-life date; a missing one becomes a `deprecation_eol` gap the command asks about and never invents.

- [ ] **Step 4: Verify both pages**

```bash
for n in document release-notes; do
  P=plugins/dev-workflows/docs/commands/$n.md
  for s in "## Who runs it" "## Synopsis" "## How it runs" "## What it needs" "## What it produces" "## Gates" "## Example" "## See also"; do
    grep -qF "$s" "$P" || echo "$n MISSING $s"
  done
done
# the dual-role page must name both roles and the discriminator
grep -qi 'specification.md' plugins/dev-workflows/docs/commands/release-notes.md || echo "release-notes: discriminator not stated"
# A. Checks 2, 3 and 6 must be clean for the pages this task wrote. The `grep -v` is the
# task boundary, not a workaround: the pre-existing plugins/dev-workflows/README.md carries
# 45 over-long table cells, and check 6 first becomes able to see them the moment docs/
# exists, because before that the gate short-circuits. Those 45 belong to Task 14.
./scripts/check-docs.sh --root . 2>&1 | grep -E 'check (2|3|6)' | grep -v 'dev-workflows/README.md' \
  || echo "checks 2, 3, 6 clean"

# B. Check 1 is red BY DESIGN until Task 13: docs/README.md links forward to pages later
# tasks create. Asserting "check 1 is clean" would be unachievable, and ignoring check 1
# entirely would let a genuine typo hide among the expected failures. So assert the real
# invariant instead — every unresolved target is a PLANNED page:
PLANNED='^(getting-started\.md|workflow\.md|roles-and-phases\.md|commands/(api-guideline-reviewer|create-ard|create-vi|design|docs-profile|document|epics|feedback|guideline-reviewer|idea|implement|prompt|prompt-brainstorm|prompt-grill-me|ready|release-notes|specify|statusline|update-vi|upgrade|vuln)\.md|reference/(agents|references|environment|hooks|model-routing|session-cost|session-feedback|follow-ups|resume-and-checkpoints)\.md)$'
./scripts/check-docs.sh --root . 2>&1 | grep 'check 1' | sed -E 's/.*-> ([^ ]+) .*/\1/' | sort -u \
  | grep -vE "$PLANNED" || echo "every unresolved link targets a planned page — no typos"
```
Expected: no `MISSING` lines, no discriminator warning, `checks 2, 3, 6 clean` and `every unresolved link targets a planned page — no typos`.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/docs/commands/document.md plugins/dev-workflows/docs/commands/release-notes.md
git commit -m "$(cat <<'EOF'
docs: add Dev delivery command pages -- /document, /release-notes

/document is organised around its two modes, because a reader must
know which one they are in before anything else applies. Its diagram
collapses 37 phases into the shape a reader navigates by -- a 37-node
flowchart is not a diagram, it is the file.

/release-notes is the dual-role case the "Who runs it" design exists
for: both the PM's early bare-VI run and the dev's documenting re-run,
with the discriminator stated (no specification.md or design.md means
PM) and the reason Epic presence is deliberately not part of it.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: Command pages — verification and maintenance (`/ready`, `/vuln`, `/upgrade`)

**Files:**
- Create: `plugins/dev-workflows/docs/commands/ready.md`
- Create: `plugins/dev-workflows/docs/commands/vuln.md`
- Create: `plugins/dev-workflows/docs/commands/upgrade.md`

**Interfaces:**
- Consumes: role anchor `#team--verification` and phase anchor `#readiness` from Task 2.
- Produces: three more of the 21 files check 4 requires.

### The command page contract (applies to all three pages)

Seven sections, in this order, every page identical:

```markdown
# /<name>

<One sentence: what this is for.>

## Who runs it
## Synopsis
## How it runs        (all three qualify — each dispatches >=2 subagents)
## What it needs
## What it produces
## Gates
## Example
## See also
```

**Derivation is mandatory. The old README is a source of topics, never of facts.** For each page:

```bash
C=plugins/dev-workflows/commands/<name>.md
awk '/^---$/{n++; if(n==2) exit} n>=1' "$C"
grep -nE '^## (Phase|Step) ' "$C"
grep -oE 'dev-workflows:[a-z-]+' "$C" | sed 's/dev-workflows://' | sort -u \
  | while read -r a; do [ -f "plugins/dev-workflows/agents/$a.md" ] && echo "$a"; done
grep -noE '\$\{?[A-Z][A-Z0-9_]{2,}\}?' "$C" | sort -u -t: -k2
grep -nE 'require-on-main|handoff-to-main|commit-artifacts|specs-preflight' "$C"
grep -nE '\-reviewer|code-review|test-baseliner' "$C"
```

**Rules:** no table cell over 200 characters; prose paragraphs unbroken on one line; requirement IDs bracketed; no spec-ID literals.

- [ ] **Step 1: Confirm the trigger, node budgets, and the heading dialect**

```bash
for n in ready vuln upgrade; do
  C=plugins/dev-workflows/commands/$n.md
  printf '%s: Phase=%s Step=%s agents=%s\n' "$n" \
    "$(grep -cE '^## Phase ' $C)" "$(grep -cE '^## Step ' $C)" \
    "$(grep -oE 'dev-workflows:[a-z-]+' $C | sed 's/dev-workflows://' | sort -u | while read -r a; do [ -f plugins/dev-workflows/agents/$a.md ] && echo x; done | wc -l)"
done
```
Expected: `ready: Phase=11 Step=0 agents=3`, `vuln: Phase=0 Step=5 agents=2`, `upgrade: Phase=3 Step=0 agents=4`. **`/vuln` is the plugin's only `## Step N` command** — its diagram labels come from its Step headings, verbatim, exactly as the others come from Phase headings.

- [ ] **Step 2: Write `docs/commands/ready.md`**

The defining property, stated first: `/ready` is **read-only for Jira status**. It verifies status against the ARD, spec, and design; it never sets status. It also never stops — an unmerged artifact becomes a readiness finding capping the verdict at `PARTIAL`, and a missing one is recorded as a coverage gap. `## What it produces`: a `SUPPORTED` / `PARTIAL` / `NOT-SUPPORTED` verdict, plus a `_readiness.md` snapshot committed only through the consent choice, never automatically.

`## Who runs it`: `phase: readiness, role: team` per §7. **Note for the implementer:** the old README files `/ready` under a `QA` role while §7 attributes it `team`. This is recorded defect D3. Write `team`, because that is what the artifact records, and do **not** silently reconcile the two — Task 15 reports it for a human decision.

- [ ] **Step 3: Write `docs/commands/vuln.md`**

`## Who runs it` must say something the other pages do not: `/vuln` emits **no cost attribution at all**, because it has no VI to attribute to, and `references/cost-emission.md` never mentions it. Confirm before writing:
```bash
grep -c 'vuln' plugins/dev-workflows/references/cost-emission.md
```
Expected: `0`. Say plainly that `/vuln` and `/upgrade` run outside the VI pipeline, and that the `phase:` values they do pass — `full`, `verify-resume`, `regression-resume` — belong to the model-routing resume protocol and are unrelated to cost-attribution phases despite sharing a field name.

`## How it runs`: five steps from the Step headings — classify and route, prepare, research in parallel, fix sequentially, summarise. `## Gates`: Opus `code-review` on `SIGNIFICANT`/`HIGH-RISK`, orchestrator-run triage, then `review-fixer` on survivors only, then tests.

- [ ] **Step 4: Write `docs/commands/upgrade.md`**

Three phases only — compatibility planning (no files changed), execution after user confirmation, then the review and comparison chain. State the two-agent split explicitly, since it is what makes the command safe to run: `upgrade-planner` detects the component, resolves the requested version (exact, minor, latest, lts, or bare), and verifies compatibility with every other component in the repo **before anything is written**; `upgrade-executor` applies the plan for one component at a time. Carry the same "no cost attribution, different `phase:` vocabulary" note as `/vuln`.

- [ ] **Step 5: Verify the three pages**

```bash
for n in ready vuln upgrade; do
  P=plugins/dev-workflows/docs/commands/$n.md
  for s in "## Who runs it" "## Synopsis" "## How it runs" "## What it needs" "## What it produces" "## Gates" "## Example" "## See also"; do
    grep -qF "$s" "$P" || echo "$n MISSING $s"
  done
done
grep -q 'team' plugins/dev-workflows/docs/commands/ready.md || echo "ready: role should be 'team' per cost-emission section 7"
# A. Checks 2, 3 and 6 must be clean for the pages this task wrote. The `grep -v` is the
# task boundary, not a workaround: the pre-existing plugins/dev-workflows/README.md carries
# 45 over-long table cells, and check 6 first becomes able to see them the moment docs/
# exists, because before that the gate short-circuits. Those 45 belong to Task 14.
./scripts/check-docs.sh --root . 2>&1 | grep -E 'check (2|3|6)' | grep -v 'dev-workflows/README.md' \
  || echo "checks 2, 3, 6 clean"

# B. Check 1 is red BY DESIGN until Task 13: docs/README.md links forward to pages later
# tasks create. Asserting "check 1 is clean" would be unachievable, and ignoring check 1
# entirely would let a genuine typo hide among the expected failures. So assert the real
# invariant instead — every unresolved target is a PLANNED page:
PLANNED='^(getting-started\.md|workflow\.md|roles-and-phases\.md|commands/(api-guideline-reviewer|create-ard|create-vi|design|docs-profile|document|epics|feedback|guideline-reviewer|idea|implement|prompt|prompt-brainstorm|prompt-grill-me|ready|release-notes|specify|statusline|update-vi|upgrade|vuln)\.md|reference/(agents|references|environment|hooks|model-routing|session-cost|session-feedback|follow-ups|resume-and-checkpoints)\.md)$'
./scripts/check-docs.sh --root . 2>&1 | grep 'check 1' | sed -E 's/.*-> ([^ ]+) .*/\1/' | sort -u \
  | grep -vE "$PLANNED" || echo "every unresolved link targets a planned page — no typos"
```
Expected: no `MISSING` lines, no role warning, `checks 2, 3, 6 clean` and `every unresolved link targets a planned page — no typos`.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/docs/commands/ready.md plugins/dev-workflows/docs/commands/vuln.md plugins/dev-workflows/docs/commands/upgrade.md
git commit -m "$(cat <<'EOF'
docs: add verification and maintenance pages -- /ready, /vuln, /upgrade

/ready leads with the property that defines it: read-only for Jira
status, and it never stops -- an unmerged artifact caps the verdict at
PARTIAL rather than blocking.

/vuln and /upgrade state what no other page has to: they emit no cost
attribution, having no VI to attribute to, and the phase: values they
DO pass belong to the model-routing resume protocol, which shares a
field name with cost attribution and nothing else.

/vuln is the plugin's only "## Step N" command; its diagram labels come
from Step headings exactly as the others come from Phase headings.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: Command pages — utilities (eight pages)

**Files:**
- Create: `plugins/dev-workflows/docs/commands/feedback.md`
- Create: `plugins/dev-workflows/docs/commands/prompt.md`
- Create: `plugins/dev-workflows/docs/commands/prompt-brainstorm.md`
- Create: `plugins/dev-workflows/docs/commands/prompt-grill-me.md`
- Create: `plugins/dev-workflows/docs/commands/statusline.md`
- Create: `plugins/dev-workflows/docs/commands/docs-profile.md`
- Create: `plugins/dev-workflows/docs/commands/api-guideline-reviewer.md`
- Create: `plugins/dev-workflows/docs/commands/guideline-reviewer.md`

**Interfaces:**
- Consumes: `../reference/session-feedback.md` and `../reference/session-cost.md` from Task 7, which the four feedback and statusline pages link to instead of restating the artifact formats.
- Produces: the final eight of the 21 files check 4 requires. After this task, check 4's command comparison passes in both directions.

### The command page contract (applies to all eight pages)

Seven sections, in this order — **except `## How it runs`, which none of these eight pages carries**:

```markdown
# /<name>

<One sentence: what this is for.>

## Who runs it
## Synopsis
## What it needs
## What it produces
## Gates
## Example
## See also
```

**No diagrams in this task.** All eight dispatch fewer than two subagents, so none qualifies under the rule. A linear sequence with no fan-out is a numbered list; drawing it as a flowchart is decoration. Confirm rather than trusting this plan:

```bash
for n in feedback prompt prompt-brainstorm prompt-grill-me statusline docs-profile api-guideline-reviewer guideline-reviewer; do
  C=plugins/dev-workflows/commands/$n.md
  printf '%s: agents=%s\n' "$n" \
    "$(grep -oE 'dev-workflows:[a-z-]+' $C | sed 's/dev-workflows://' | sort -u | while read -r a; do [ -f plugins/dev-workflows/agents/$a.md ] && echo x; done | wc -l)"
done
```
Expected: `guideline-reviewer: agents=1`, `api-guideline-reviewer: agents=1`, and `0` for the other six. If any returns 2 or more, that page gets a diagram — the rule decides, not this list.

**Derivation is mandatory. The old README is a source of topics, never of facts.** For each page:

```bash
C=plugins/dev-workflows/commands/<name>.md
awk '/^---$/{n++; if(n==2) exit} n>=1' "$C"
grep -nE '^## ' "$C"
grep -noE '\$\{?[A-Z][A-Z0-9_]{2,}\}?' "$C" | sort -u -t: -k2
grep -nE 'commit-artifacts|specs-preflight' "$C"
```

**Rules:** no table cell over 200 characters; prose paragraphs unbroken on one line; requirement IDs bracketed; no spec-ID literals. These are short pages — 15 to 40 lines each is correct, not a defect. A short file that answers one question beats a paragraph buried in a 74 KB table.

- [ ] **Step 1: Write the four feedback pages**

`/feedback` logs a manual note about the plugin itself (`origin: manual`). `/prompt` captures a corrective interaction — a command produced something wrong and you fixed it. `/prompt-brainstorm` captures the same, then hands off to `superpowers:brainstorming`. `/prompt-grill-me` captures the same, then grills the fix inline.

Each of the four links to `../reference/session-feedback.md` for the entry format rather than restating it. Each states the one operational fact that differs: `/prompt-brainstorm` and `/prompt-grill-me` run `commit-artifacts` **before** their final phase rather than after, because that phase cedes the session and a commit placed after it would never execute. Verify:
```bash
grep -n 'commit-artifacts' plugins/dev-workflows/commands/prompt-brainstorm.md plugins/dev-workflows/commands/prompt-grill-me.md
```

Every page in this group should encourage use. These commands are how the plugin improves; say so.

- [ ] **Step 2: Write `docs/commands/statusline.md`**

Two things a user must know. First, run it once, first, after installing — it installs the multi-line status line and enables the snapshot session-cost reporting uses. Second, and unmissably: Claude Code ships its own built-in `/statusline`, so the bare form reaches Claude Code's command instead. **Always use `/dev-workflows:statusline`.** Name the other two colliding commands too — `/release-notes` and `/upgrade` — and link to `../workflow.md` where the collision list lives.

The page also states that the command is idempotent, backs up anything it would overwrite, and changes no workflow-command behaviour.

- [ ] **Step 3: Write `docs/commands/docs-profile.md`**

Scans a docs repo and writes or refreshes `.dev-workflows/docs-profile.yml` plus CLAUDE.md guidance, then opens a PR. `## What it needs`: a docs repository. `## See also`: `document.md`, which consumes the profile.

- [ ] **Step 4: Write the two standalone reviewer pages**

`/api-guideline-reviewer` reviews OpenAPI specification files against the vendored Dynatrace REST API and IAM permission guidance — version consistency, required elements, naming, IAM scope format, HTTP status codes, schema composition. `/guideline-reviewer` reviews app code and UI against Dynatrace Experience Standards — AppHeader, DataTable, FilterField, Connections, Permissions, Settings, Dashboards, accessibility, terminology, Grail naming.

Both pages state that these commands are **standalone**: outside the VI pipeline, exempt from model routing, and they emit no cost attribution. Both `## Gates` sections say there is no review gate — the command *is* the review.

- [ ] **Step 5: Verify all eight pages and close check 4's command comparison**

```bash
for n in feedback prompt prompt-brainstorm prompt-grill-me statusline docs-profile api-guideline-reviewer guideline-reviewer; do
  P=plugins/dev-workflows/docs/commands/$n.md
  for s in "## Who runs it" "## Synopsis" "## What it needs" "## What it produces" "## Gates" "## Example" "## See also"; do
    grep -qF "$s" "$P" || echo "$n MISSING $s"
  done
  grep -q '^```mermaid' "$P" && echo "$n has a diagram but does not qualify"
done
diff <(ls plugins/dev-workflows/commands/*.md | sed 's|.*/||; s|\.md$||' | sort) \
     <(ls plugins/dev-workflows/docs/commands/*.md | sed 's|.*/||; s|\.md$||' | sort) \
  && echo "all 21 commands have a page, and no page names a non-command"
./scripts/check-docs.sh --root . 2>&1 | grep 'check 4' || echo "check 4 passes"
```
Expected: no `MISSING` lines, no diagram warnings, `all 21 commands have a page…`, `check 4 passes`.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/docs/commands/feedback.md plugins/dev-workflows/docs/commands/prompt.md plugins/dev-workflows/docs/commands/prompt-brainstorm.md plugins/dev-workflows/docs/commands/prompt-grill-me.md plugins/dev-workflows/docs/commands/statusline.md plugins/dev-workflows/docs/commands/docs-profile.md plugins/dev-workflows/docs/commands/api-guideline-reviewer.md plugins/dev-workflows/docs/commands/guideline-reviewer.md
git commit -m "$(cat <<'EOF'
docs: add the eight utility command pages

None carries a diagram: all eight dispatch fewer than two subagents,
so none qualifies under the rule. Short pages -- 15 to 40 lines -- are
correct here, not a defect.

This closes check 4's command comparison in both directions: all 21
commands have a page and no page names a non-command.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 14: Rewrite the README — the gate turns green

**Files:**
- Modify: `plugins/dev-workflows/README.md` (379 lines → ~50)
- Modify: `README.md` (repo root) — add a docs link to the `dev-workflows` row

**Interfaces:**
- Consumes: all 34 pages from Tasks 2–13. This task cannot start before Task 13 completes, because the README's link table points at every top-level page and check 1 will reject a link to a file that does not exist.
- Produces: a green `./scripts/check-docs.sh --root .` — the first time the gate passes since Task 1.

- [ ] **Step 1: Record the before state**

```bash
wc -lc plugins/dev-workflows/README.md
awk '{print length}' plugins/dev-workflows/README.md | sort -rn | head -1
```
Expected: `379 74620` and `2177`. Put these in the task report; the PR body cites them.

- [ ] **Step 2: Write the new README**

Six sections, roughly 50 lines total:

1. `# dev-workflows` and a two-sentence pitch. Keep the existing opening blurb's substance but not its length — the current one is a single 600-character sentence.
2. The marketplace pointer: `> Part of the `ihudak-plugins` marketplace — see the [repo-root setup guide](../../README.md) for marketplace install + prerequisites.` **This line carries edition identity and stays here** — it is one of the two strings that make this file an identity file.
3. `## What it does` — a compact capability table, one row per role, linking into `docs/`. Every cell under 200 characters; check 6 covers this file.
4. `## Documentation` — the link table into `docs/`, pointing at `docs/README.md`, `docs/getting-started.md`, `docs/workflow.md`, `docs/roles-and-phases.md`, and the `docs/reference/` index entries.
5. `## Recommended environment` — the `ihudak/ai-containers` recommendation. **This is the second identity-bearing line and stays here**, which is why `docs/reference/environment.md` links to the README for it rather than naming a container itself.
6. `## License` — MIT.

Everything else moves out. Nothing is summarised twice: if a fact is on a `docs/` page, the README links to it rather than restating it.

- [ ] **Step 3: Confirm both identity strings are still present and still only here**

```bash
grep -c 'ihudak-plugins' plugins/dev-workflows/README.md
grep -c 'ai-containers' plugins/dev-workflows/README.md
grep -rn 'ihudak-plugins\|mgd-plugins\|ai-containers' plugins/dev-workflows/docs/ | grep -v 'getting-started.md'
```
Expected: `1`, `1`, and **no output** from the third command. Output from the third means the identity-quarantine rule has been broken by a `docs/` page other than the sanctioned `getting-started.md`, and mgd's parity count will read seven instead of six.

- [ ] **Step 4: Add the docs link to the repo-root README**

In the `dev-workflows` row of the plugin table in the repo-root `README.md`, append a link to `plugins/dev-workflows/docs/README.md`. Keep the row under 200 characters — the existing cell is long, so shorten the description rather than appending to it.

- [ ] **Step 5: Run the gate — expect PASS**

Run: `./scripts/check-docs.sh --root .`
Expected: `PASS: docs are consistent with the plugin under plugins/dev-workflows`

This is the moment the failing test from Task 1 Step 4 turns green. If it does not pass, do **not** relax a check — every check exists because a specific failure was observed, and the page is what is wrong.

- [ ] **Step 6: Run the selftest and the other three gates**

```bash
./scripts/check-docs.sh --selftest
python3 scripts/validate-catalog.py
./scripts/check-id-grammar.sh --selftest
./scripts/check-id-grammar.sh --root .
```
Expected: `SELFTEST PASS`; `0 error(s), 0 warning(s)`; `SELFTEST PASS`; `PASS: no dash-form requirement IDs under .`

- [ ] **Step 7: Confirm the spec-ID census did not shift**

```bash
grep -rhoE '\[U0[0-9]+\]|\[AC0[0-9]+\]|\[TC0[0-9]+\]|\[Uxx\]|\[ACxx\]|\[TCxx\]' \
  --include='*.md' --exclude='CHANGELOG.md' plugins/ CLAUDE.md 2>/dev/null | sort | uniq -c \
  | diff <(grep -v '^#' scripts/spec-id-baseline.txt) -
```
Expected: **no output**. Any output means a new `docs/` page used a spec-ID literal, tripping the census tripwire — remove the literal rather than regenerating the baseline.

- [ ] **Step 8: Record the after state**

```bash
wc -lc plugins/dev-workflows/README.md
find plugins/dev-workflows/docs -name '*.md' | wc -l
find plugins/dev-workflows/docs -name '*.md' -print0 | xargs -0 awk -v m=0 '
  /^```/{f=!f;next} f{next}
  /^\|/{n=split($0,c,"|"); for(i=2;i<n;i++){gsub(/^ +| +$/,"",c[i]); if(length(c[i])>m) m=length(c[i])}}
  END{print "longest table cell:", m}' plugins/dev-workflows/README.md -
```
Expected: README under 60 lines; `34` pages; longest table cell at most 200.

- [ ] **Step 9: Commit**

```bash
git add plugins/dev-workflows/README.md README.md
git commit -m "$(cat <<'EOF'
docs: rewrite the README to ~50 lines and turn the gate green

379 lines and 74,620 bytes become roughly 50: pitch, marketplace
pointer, capability table, link table into docs/, container
recommendation, license. Everything else now has an owner page.

Both edition-identity strings stay in this file by design -- the
marketplace name and the container repo -- which is what keeps every
docs/ page except getting-started.md copyable to mgd unchanged.

check-docs.sh passes for the first time since it was written. Defect
D1 is closed on the way: the Commands table documented 19 of 21
commands, with /vuln and /upgrade orphaned in an unlabeled
"Additionally:" table under the /implement workflow section. Both now
have pages of their own.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 15: Fix defect D2 and prepare the defect report

**Files:**
- Modify: `plugins/dev-workflows/references/cost-emission.md` (the §7 attribution table)
- Create: `docs/superpowers/verification/2026-08-22-docs-restructure-defects.md`

**Interfaces:**
- Consumes: the role and phase facts established in Tasks 2, 8, and 12.
- Produces: the defect table the PR body quotes.

This is the plan's **only** change to plugin content outside `docs/` and the README. It gets its own commit so a reader of the history can see a behaviour-adjacent change separately from a documentation move.

- [ ] **Step 1: Confirm D2 still holds before fixing it**

```bash
grep -n 'update-vi\|vi-update' plugins/dev-workflows/references/cost-emission.md
grep -n 'phase: vi-update' plugins/dev-workflows/commands/update-vi.md
sed -n '/^| Command | phase | role |/,/^$/p' plugins/dev-workflows/references/cost-emission.md
```
Expected: `cost-emission.md` mentions `/update-vi` only at line 4 (the list of cost-emitting commands) and never in the §7 table; `update-vi.md` passes `phase: vi-update, role: pm`; the table has ten rows and no `/update-vi` row. If any of that has changed, stop and report — the defect may already be fixed or may have moved.

- [ ] **Step 2: Add the missing row**

Insert into the §7 table, keeping the existing row order (which groups by lifecycle stage, not alphabetically) — `/update-vi` belongs immediately after `/create-vi`:

```markdown
| `/update-vi` | vi-update | pm |
```

- [ ] **Step 3: Verify the table is now complete in both directions**

```bash
# every command that passes a fixed phase/role has a row
for f in plugins/dev-workflows/commands/*.md; do
  n=$(basename "$f" .md)
  grep -qE 'phase: (vi-creation|vi-update|architecture|specification|epic-refinement|planning|implementation|documenting|readiness|inferred)' "$f" || continue
  grep -q "\`/$n\`" plugins/dev-workflows/references/cost-emission.md || echo "STILL MISSING from section 7: /$n"
done
# every row names a real command
grep -oE '^\| `/[a-z-]+`' plugins/dev-workflows/references/cost-emission.md | tr -d '|` /' | while read -r n; do
  [ -f "plugins/dev-workflows/commands/$n.md" ] || echo "section 7 names a non-command: /$n"
done
```
Expected: no output from either. The first loop is the check that would have caught D2 when the row was first omitted.

- [ ] **Step 4: Write the defect report**

Create `docs/superpowers/verification/2026-08-22-docs-restructure-defects.md` with one section per defect: what was claimed, what is true, how it was found, and its disposition. Five entries, matching spec §1:

- **D1** — the Commands table documented 19 of 21 commands. **Fixed** in Task 14.
- **D2** — `cost-emission.md` §7 omitted `/update-vi`, so `vi-update` was a phase value emitted by a shipped command and enumerated in no authority. **Fixed** in this task.
- **D3** — `/ready`'s role is `team` in §7 and `QA` in the README's role table. **Reported, not resolved.** The docs state `team` because that is what the artifact records. Both may be intentional; this needs a human decision, and the PR body asks for one.
- **D4** — the `## Environment prerequisites` section gave a proper entry to one of six variables, and `DEV_WORKFLOWS_COST_PRICES` was documented as a settable variable nowhere. **Fixed** by Tasks 3 and 4, and defended by check 5's exclusion list, which now fails on a seventh user-settable variable rather than passing silently.
- **D5** — `references/` holds 98 files against 93 markdown, and `cost-prices.yaml` among them is user-overridable and therefore user-facing. **Fixed** by Task 5 and defended by check 4, which inventories reference files rather than reference markdown.

- [ ] **Step 5: Verify all four gates still pass**

```bash
./scripts/check-docs.sh --root . && ./scripts/check-docs.sh --selftest \
  && python3 scripts/validate-catalog.py \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root .
```
Expected: all pass. `cost-emission.md` is under `plugins/`, so the ID-grammar gate and the spec-ID census both cover the edit.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/references/cost-emission.md docs/superpowers/verification/2026-08-22-docs-restructure-defects.md
git commit -m "$(cat <<'EOF'
fix(cost-emission): add the missing /update-vi row to the section 7 table

Defect D2, found by grounding the role model rather than reading it.
The table is introduced as "Fixed per-command labels" and listed ten
commands. /update-vi passes phase: vi-update, role: pm to emit-cost,
and line 4 of the same file names it among the commands that run the
Session cost phase -- so vi-update was a phase value emitted by a
shipped command and enumerated in no authority.

This is the dead-gate shape from the other side: not a rule with no
consumer, but a consumer emitting a value its own reference does not
enumerate.

Also records the five-defect report the PR body quotes. D3 -- /ready's
role being "team" in section 7 and "QA" in the README's role table --
is reported rather than resolved: both may be intentional, so the docs
state what the artifact records and a human settles it.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 16: Version, changelog, and the pull request

**Files:**
- Modify: `plugins/dev-workflows/CHANGELOG.md`
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

**Interfaces:**
- Consumes: everything. This task runs last.
- Produces: the merged PR 1 of 3. PR 2 (mgd) and PR 3 (copilot) get their own plans, written after this merges.

- [ ] **Step 1: Determine the next version**

```bash
grep -m1 '"version"' plugins/dev-workflows/.claude-plugin/plugin.json
head -20 plugins/dev-workflows/CHANGELOG.md
```
This is a minor bump — new user-facing documentation surface and a new CI gate, no behaviour change beyond D2's one-row table fix.

- [ ] **Step 2: Bump both manifests to the same version**

Edit `plugins/dev-workflows/.claude-plugin/plugin.json` and the `dev-workflows` entry in `.claude-plugin/marketplace.json`. **Do not touch either `description` field** — they are capability blurbs bounded at 1024 characters, not changelogs, and a docs restructure is not a new capability.

- [ ] **Step 3: Write the changelog entry**

Cover: the README reduction with both numbers; the 34-page docs tree; `scripts/check-docs.sh` and its seven checks plus selftest, now in CI; and the five defects with D3's disposition. Release detail belongs here, which is exactly why the `description` fields do not change.

- [ ] **Step 4: Verify the description budget is untouched**

```bash
python3 scripts/validate-catalog.py
git diff --stat plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git diff plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json | grep -c 'description'
```
Expected: `0 error(s), 0 warning(s)`; both files changed by one line each; the `description` grep returns `0`. A non-zero count means a blurb was edited — revert it. The 1024-character limit is Copilot's, and it rejects the **whole catalog**, so one over-long blurb makes every plugin in the marketplace fail to install.

- [ ] **Step 5: Full verification sweep**

```bash
./scripts/check-docs.sh --selftest
./scripts/check-docs.sh --root .
python3 scripts/validate-catalog.py
./scripts/check-id-grammar.sh --selftest
./scripts/check-id-grammar.sh --root .
grep -rhoE '\[U0[0-9]+\]|\[AC0[0-9]+\]|\[TC0[0-9]+\]|\[Uxx\]|\[ACxx\]|\[TCxx\]' \
  --include='*.md' --exclude='CHANGELOG.md' plugins/ CLAUDE.md 2>/dev/null | sort | uniq -c \
  | diff <(grep -v '^#' scripts/spec-id-baseline.txt) - && echo "spec-ID census unchanged"
diff <(ls plugins/dev-workflows/commands/*.md | sed 's|.*/||; s|\.md$||' | sort) \
     <(ls plugins/dev-workflows/docs/commands/*.md | sed 's|.*/||; s|\.md$||' | sort) \
  && echo "21/21 commands documented"
find plugins/dev-workflows/docs -name '*.md' | wc -l
grep -rn 'ihudak-plugins\|mgd-plugins\|ai-containers' plugins/dev-workflows/docs/ | grep -v 'getting-started.md' \
  || echo "identity quarantine holds"
```
Expected: every gate passes; `spec-ID census unchanged`; `21/21 commands documented`; `34`; `identity quarantine holds`.

- [ ] **Step 6: Commit and open the PR**

```bash
git add plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "$(cat <<'EOF'
chore(release): dev-workflows docs restructure

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
git push -u origin iv-gu/docs-restructure
```

The PR body carries, in this order: the before and after numbers (379 lines / 74,620 bytes / a 2,177-character table cell → ~50 lines and 34 pages, no cell over 200 characters); what the gate checks and the fact that each check was demonstrated failing; the five-defect table from Task 15 with D3 flagged as **needing a decision**; and a note that PRs 2 and 3 port this to mgd and copilot, with mgd's expected parity count moving from five differing files to six.

- [ ] **Step 7: Merge**

Merge to `main` once CI is green. Ivan has standing authorization to merge and push on this repository. Confirm CI ran all five steps — the three pre-existing ones plus the two new docs-gate steps — before merging.

---

## Self-review

Run against the spec after the plan is written; recorded here so an executor can see what was checked.

**1. Spec coverage.** Every spec section maps to a task: §4 page set → Tasks 2–13; §5 anatomy → the contract block repeated in Tasks 8–13; §5's getting-started contract → Task 3; §5's roles-and-phases contract → Task 2 Step 3; §6 Mermaid policy → Task 2 Step 2, Task 8 Step 2, and the confirm-the-trigger step in each of Tasks 9–13; §7 grounding contract → the derivation block repeated in Tasks 8–13; §8 gate → Task 1; §9 editions → out of scope by design, deferred to PRs 2 and 3, stated in the header; §10 global constraints → the Global Constraints section; §11 sequencing → Task 16 Step 6; §12 success criteria → Task 16 Step 5. No gaps.

**2. Placeholder scan.** No "TBD", "TODO", "add appropriate error handling", or "similar to Task N". The gate script is written in full rather than described. The command page contract and derivation block are **repeated verbatim** in each of Tasks 8–13 rather than cross-referenced, because `scripts/task-brief` extracts one task's text in isolation and a cross-reference would not survive the extraction.

**3. Type consistency.** The names later tasks depend on are fixed once and reused unchanged: `scripts/check-docs.sh` with `--root` / `--selftest` and the `FAIL check <N>:` output shape (Task 1, consumed by every later task); the seven-section page anatomy with `## How it runs` conditional (Tasks 8–13); the role anchors `#pm--product-management`, `#pa--product-architecture`, `#pe--product-engineering`, `#dev--build-and-deliver`, `#team--verification` and the nine `### <phase>` anchors (created in Task 2, linked from Tasks 8–13); the agent-row shape `` | `<name>` | `` and the subtree-count shape `` `<dir>/` (<count>) `` (created in Task 5, parsed by check 4); and the variable-bullet shape `` - **`$VAR`** — `` (created in Task 4, parsed by check 5). Each of the three parsed shapes has an explicit non-vacuity check in its own task, because a shape mismatch would make the corresponding check pass against an empty set rather than fail.
