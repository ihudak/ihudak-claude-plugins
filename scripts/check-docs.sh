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

strip_fences() { # drop fenced code blocks: an illustrative link inside a ```markdown
                 # block is not a real link, and a `#` line inside one is not a heading.
                 # check 6 has always stripped fences; checks 1 and 2 did not, which made
                 # them fail on correct content AND accept anchors that do not exist.
  awk '/^[ \t]*(```|~~~)/ { infence = !infence; next } !infence' "$1"
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
        case "$heading_file" in *.md) ;; *) continue ;; esac  # only markdown has headings;
                                                             # a .sh file's `# comment` is not one
        slugs=$(strip_fences "$heading_file" 2>/dev/null | grep -E '^#{1,6} ' \
                | sed -E 's/^#{1,6} //' \
                | while IFS= read -r h; do slugify "$h"; done)
        if ! grep -qx -- "$anchor" <<<"$slugs"; then
          fail 2 "$f -> ${target:-(this file)}#$anchor (no such heading)"
        fi
      fi
    done < <(strip_fences "$f" | grep -oE '\]\([^)#][^)]*\)|\]\(#[^)]*\)' \
             | sed -E 's/^\]\(//; s/\)$//' \
             | grep -vE '^(https?|mailto):')
  done < <({ find "$root/$PLUGIN_REL/docs" -name '*.md' 2>/dev/null
             [ -f "$root/$PLUGIN_REL/README.md" ] && printf '%s\n' "$root/$PLUGIN_REL/README.md"
             [ -f "$root/README.md" ] && printf '%s\n' "$root/README.md"; })
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
    grep -qF "\`$n\`" "$d/reference/references.md" 2>/dev/null || fail 4 "reference file '$n' is absent from reference/references.md"
  done < <({ ls "$p/references"/*.md 2>/dev/null; ls "$p/references"/*.yaml 2>/dev/null; \
             ls "$p/references/model-routing"/*.md 2>/dev/null; } | sed 's|.*/||')
  while IFS= read -r n; do
    [ -f "$p/references/$n" ] || [ -f "$p/references/model-routing/$n" ] \
      || fail 4 "reference/references.md names '$n', which is not a reference file"
  done < <(grep -oE '`[A-Za-z0-9_.-]+\.(md|yaml)`' "$d/reference/references.md" 2>/dev/null | tr -d '`')

  # reference subtree counts -- *.md only: these subtrees also carry vendored
  # non-markdown data/templates that are not user-facing reference pages, so
  # counting everything would fail this check on files docs/ never claims.
  # Derived from the tree, never hardcoded: a hardcoded list cannot see a NEW subtree,
  # which is how a whole directory of reference docs would ship undocumented.
  # model-routing/ is excluded deliberately -- its *.md are inventoried file-by-file above.
  local dir count claimed
  for dir in $(ls -d "$p/references"/*/ 2>/dev/null | sed 's|/*$||; s|.*/||'); do
    [ "$dir" = "model-routing" ] && continue
    count=$(find "$p/references/$dir" -name '*.md' | wc -l | tr -d ' ')
    claimed=$(grep -oE "\`$dir/\` \(([0-9]+)\)" "$d/reference/references.md" 2>/dev/null | grep -oE '[0-9]+' | head -1)
    [ "$claimed" = "$count" ] || fail 4 "reference/references.md says $dir/ has '${claimed:-nothing}', tree has $count"
  done
  # ...and the reverse: a subtree the page claims but the tree no longer has. Without this,
  # `rm -rf references/upgrade/` passes while the page still advertises `upgrade/` (3).
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    [ -d "$p/references/$dir" ] || fail 4 "reference/references.md claims subtree $dir/, which does not exist"
  done < <(grep -oE '`[a-z][a-z0-9-]*/` \([0-9]+\)' "$d/reference/references.md" 2>/dev/null | sed 's|`||g; s|/.*||')

  # hooks <-> docs/reference/hooks.md
  while IFS= read -r n; do
    grep -q "\`$n\`" "$d/reference/hooks.md" 2>/dev/null || fail 4 "hook '$n' is absent from reference/hooks.md"
  done < <(ls "$p/hooks"/*.sh 2>/dev/null | sed 's|.*/||; s|\.sh$||')
  while IFS= read -r n; do
    [ -f "$p/hooks/$n.sh" ] || fail 4 "reference/hooks.md names '$n', which is not a hook"
  done < <(grep -oE '^\| `[a-z-]+`' "$d/reference/hooks.md" 2>/dev/null | tr -d '|` ')

  # skills <-> docs/reference/references.md
  while IFS= read -r n; do
    grep -q "\`$n\`" "$d/reference/references.md" 2>/dev/null || fail 4 "skill '$n' is absent from reference/references.md"
  done < <(ls -d "$p/skills"/*/ 2>/dev/null | sed 's|/*$||; s|.*/||')
  while IFS= read -r n; do
    [ -d "$p/skills/$n" ] || fail 4 "reference/references.md names skill '$n', which is not a skill"
  done < <(grep -oE '^\| `[a-z-]+`' "$d/reference/references.md" 2>/dev/null | tr -d '|` ')
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
    grep -qw "$v" "$d/reference/environment.md" 2>/dev/null \
      || fail 5 "\$$v is read by the plugin but absent from reference/environment.md"
    grep -qw "$v" "$d/getting-started.md" 2>/dev/null \
      || fail 5 "\$$v is read by the plugin but absent from getting-started.md"
  done
  documented=$(grep -oE '^#+ `\$?[A-Z][A-Z0-9_]{2,}`|\*\*`\$?[A-Z][A-Z0-9_]{2,}`\*\*' \
                 "$d/reference/environment.md" 2>/dev/null | sed 's/^#* //' | tr -d '*`$')
  for v in $documented; do
    grep -qx -- "$v" <<<"$read_vars" \
      || fail 5 "reference/environment.md documents \$$v, which the plugin never reads"
  done
}

# ------------------------------------------------------------------- check 6
# No table cell over 200 characters. This is the readability invariant the whole
# restructure exists to establish, and the one a future edit will silently
# violate: the README this replaced carried a single cell of 2,066 characters.
check_table_cells() {
  local root="$1" files hits h
  files=$( { find "$root/$PLUGIN_REL/docs" -name '*.md' 2>/dev/null
             [ -f "$root/$PLUGIN_REL/README.md" ] && printf '%s\n' "$root/$PLUGIN_REL/README.md"
             [ -f "$root/README.md" ] && printf '%s\n' "$root/README.md"; } )
  [ -n "$files" ] || return 0
  hits=$(while IFS= read -r f; do
           [ -n "$f" ] || continue
           awk -v FILE="${f#$root/}" '
             /^```/    { infence = !infence; next }
             infence   { next }
             /^\|/ {
               n = split($0, cells, "|")
               last = ($0 ~ /\|[[:space:]]*$/) ? n - 1 : n   # no trailing pipe => the final field IS a cell
               for (i = 2; i <= last; i++) {
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
  a=$(grep -oE '^claude plugin (marketplace (add|update)|install|reinstall) .*' "$root/README.md" 2>/dev/null | sort)
  b=$(grep -oE '^claude plugin (marketplace (add|update)|install|reinstall) .*' "$root/$PLUGIN_REL/docs/getting-started.md" 2>/dev/null | sort)
  if [ -z "$a" ]; then fail 7 "repo-root README.md has no 'claude plugin ...' command lines to pin against"; return; fi
  if [ "$a" != "$b" ]; then
    fail 7 "getting-started.md install commands differ from the repo-root README"
    note "only in root README: $(comm -23 <(printf '%s\n' "$a") <(printf '%s\n' "$b") | tr '\n' ' ')"
    note "only in getting-started: $(comm -13 <(printf '%s\n' "$a") <(printf '%s\n' "$b") | tr '\n' ' ')"
  fi
}

# ------------------------------------------------------------------- check 8
# Cost attribution agrees in BOTH directions: every command that hands emit-cost a
# fixed phase/role pair has a row in references/cost-emission.md section 7 carrying
# those same two values, and every section-7 row names a real command. Defect D2 --
# /update-vi emitting `phase: vi-update, role: pm` with no section-7 row -- was found
# by a one-off inline grep and defended by nothing afterwards, which is how it had
# survived since the command shipped. `/document` is the shape that defeats a naive
# grep: it calls emit-cost twice, as `/document (Jira mode)` and `/document (direct
# mode)`, against a single `/document` row.
emit_cost_calls() { # <plugin-dir>  ->  lines of  <command>|<phase>|<role>
  local p="$1" f
  for f in "$p/commands"/*.md; do
    [ -f "$f" ] || continue
    tr '\n' ' ' < "$f" | tr -s ' ' \
      | grep -oE '`command: /[a-z-]+( \([A-Za-z]+ mode\))?`, `phase: [a-z-]+`, `role: [a-z]+`' \
      | sed -E 's/`command: //; s/ \([A-Za-z]+ mode\)//; s/`, `phase: /|/; s/`, `role: /|/; s/`$//'
  done | sort -u
}

check_cost_attribution() {
  local root="$1" p="$1/$PLUGIN_REL" table calls line cmd phase role want
  table=$(sed -n '/^## 7\./,/^## 8\./p' "$p/references/cost-emission.md" 2>/dev/null \
          | grep -oE '^\| `/[a-z-]+` \| [^|]+ \| [^|]+ \|' \
          | sed -E 's/^\| `//; s/` \| /|/; s/ \| /|/; s/ *\|$//; s/\*//g; s/ *\| */|/g')
  [ -n "$table" ] || { fail 8 "references/cost-emission.md has no section-7 attribution table"; return; }
  calls=$(emit_cost_calls "$p")
  [ -n "$calls" ] || { fail 8 "no emit-cost call site found in commands/ -- the extractor has stopped matching"; return; }

  while IFS='|' read -r cmd phase role; do
    [ -n "$cmd" ] || continue
    want=$(grep -F "$cmd|" <<<"$table" | head -1)
    if [ -z "$want" ]; then
      fail 8 "$cmd emits phase/role '$phase'/'$role' but has no row in cost-emission.md section 7"
    elif [ "$want" != "$cmd|$phase|$role" ]; then
      fail 8 "$cmd emits '$phase'/'$role'; cost-emission.md section 7 says '${want#*|}'"
    fi
  done <<<"$calls"

  while IFS='|' read -r cmd phase role; do
    [ -n "$cmd" ] || continue
    grep -qF "$cmd|" <<<"$calls" \
      || fail 8 "cost-emission.md section 7 attributes $cmd, which passes emit-cost no fixed phase/role"
  done <<<"$table"

  # Extractor-coverage assertion. Every command file that mentions emit-cost must yield a
  # triple; otherwise a reworded call site makes this check go QUIET, and the message above
  # would blame the table for what is really an extractor miss. `/document` is the live
  # example -- it calls emit-cost twice under parenthesised names.
  local f n
  for f in "$p/commands"/*.md; do
    [ -f "$f" ] || continue
    grep -q 'emit-cost' "$f" || continue
    n="/$(basename "$f" .md)"
    grep -qF "$n|" <<<"$calls" \
      || fail 8 "commands$(basename "$f" .md | sed 's|^|/|').md calls emit-cost but no phase/role triple matched -- the EXTRACTOR has drifted, not the table; fix the regex, never the row"
  done
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
  expect_fail "a broken link in the plugin README is rejected" 1 "sed -i.bak 's|(docs/README.md)|(docs/NOPE.md)|' plugins/dev-workflows/README.md"
  expect_fail "a broken anchor is rejected"         2 "sed -i.bak 's|(getting-started.md#install)|(getting-started.md#no-such-heading)|' plugins/dev-workflows/docs/README.md"
  expect_fail "an orphan page is rejected"          3 "printf '# Orphan\n\nUnreachable.\n' > plugins/dev-workflows/docs/orphan.md"
  expect_fail "an undocumented command is rejected" 4 "printf -- '---\nname: delta\n---\n' > plugins/dev-workflows/commands/delta.md"
  expect_fail "a drifted subtree count is rejected" 4 "sed -i.bak 's|\`handoff/\` (2)|\`handoff/\` (3)|' plugins/dev-workflows/docs/reference/references.md"
  expect_fail "an undocumented skill is rejected"    4 "mkdir -p plugins/dev-workflows/skills/epsilon && printf -- '---\nname: epsilon\n---\n' > plugins/dev-workflows/skills/epsilon/SKILL.md"
  expect_fail "an undocumented env var is rejected" 5 "printf 'Reads \$NEW_SETTABLE_VAR here.\n' >> plugins/dev-workflows/commands/alpha.md"
  expect_fail "an over-long table cell is rejected" 6 "awk 'BEGIN{s=\"\"; while(length(s)<260) s=s \"x\"; printf \"\\n| a | %s |\\n|---|---|\\n| b | c |\\n\", s}' >> plugins/dev-workflows/docs/reference/hooks.md"
  expect_fail "a drifted install block is rejected" 7 "sed -i.bak 's|claude plugin install dev-workflows@fixture-plugins|claude plugin install dev-workflows@drifted|' plugins/dev-workflows/docs/getting-started.md"
  expect_fail "a documented nonexistent skill is rejected" 4 "printf '\n| \`ghost-skill\` | Yes | fixture mutation |\n' >> plugins/dev-workflows/docs/reference/references.md"
  expect_fail "an unattributed emit-cost call is rejected" 8 "printf -- '---\nname: zeta\n---\n\nCall \`emit-cost\` with \`command: /zeta\`, \`phase: fixture-phase\`, \`role: pm\`, done.\n' > plugins/dev-workflows/commands/zeta.md && printf -- '# /zeta\n\nFixture page.\n' > plugins/dev-workflows/docs/commands/zeta.md && sed -i.bak 's|(commands/alpha.md)|(commands/alpha.md), [\`/zeta\`](commands/zeta.md)|' plugins/dev-workflows/docs/README.md"
  expect_fail "a drifted attributed role is rejected"      8 "sed -i.bak 's;| \`/alpha\` | fixture-phase | pm |;| \`/alpha\` | fixture-phase | pe |;' plugins/dev-workflows/references/cost-emission.md"
  expect_fail "a broken link in the ROOT README is rejected" 1 "sed -i.bak 's|(plugins/dev-workflows/README.md)|(plugins/dev-workflows/NOPE.md)|' README.md"
  expect_fail "a broken bare #anchor is rejected"   2 "printf '\n[self](#no-such-heading-here)\n' >> plugins/dev-workflows/docs/README.md"
  expect_fail "a documented nonexistent agent is rejected"     4 "printf '\n| \`ghost-agent\` | fixture |\n' >> plugins/dev-workflows/docs/reference/agents.md"
  expect_fail "a documented nonexistent hook is rejected"      4 "printf '\n| \`ghost-hook\` | fixture |\n' >> plugins/dev-workflows/docs/reference/hooks.md"
  expect_fail "a documented nonexistent reference file is rejected" 4 "printf '\n- \`ghost-ref.md\`\n' >> plugins/dev-workflows/docs/reference/references.md"
  expect_fail "a claimed-but-absent subtree is rejected"       4 "rm -rf plugins/dev-workflows/references/handoff"
  expect_fail "an undocumented NEW subtree is rejected"        4 "mkdir -p plugins/dev-workflows/references/brandnew && printf '# x\n' > plugins/dev-workflows/references/brandnew/x.md"
  expect_fail "a documented-but-unread env var is rejected"    5 "printf '\n**\`\$PHANTOM_VAR\`** — never read anywhere.\n' >> plugins/dev-workflows/docs/reference/environment.md"
  expect_fail "an over-long cell in the ROOT README is rejected" 6 "awk 'BEGIN{s=\"\"; while(length(s)<260) s=s \"x\"; printf \"\n| a | %s |\n|---|---|\n| b | c |\n\", s}' >> README.md"
  expect_fail "a drifted reinstall command is rejected"        7 "printf '\nclaude plugin reinstall dev-workflows@fixture-plugins\n' >> plugins/dev-workflows/docs/getting-started.md"
  expect_fail "a drifted emit-cost call site is rejected"      8 "sed -i.bak 's|\`command: /alpha\`, \`phase: fixture-phase\`, \`role: pm\`|\`command: /alpha\`, \`role: pm\`, \`phase: fixture-phase\`|' plugins/dev-workflows/commands/alpha.md"
  expect_fail "a section-7 row for a non-emitting command is rejected" 8 "sed -i.bak 's;| \`/alpha\` | fixture-phase | pm |;| \`/alpha\` | fixture-phase | pm |\n| \`/omega\` | fixture-phase | pm |;' plugins/dev-workflows/references/cost-emission.md"

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
check_cost_attribution  "$ROOT"

if [ "$FAILURES" -gt 0 ]; then
  echo "FAIL: $FAILURES problem(s) under $PLUGIN_REL" >&2
  exit 1
fi
echo "PASS: docs are consistent with the plugin under $PLUGIN_REL"
