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

# ---------------------------------------------------------------- edition config
# THE ONLY PART OF THIS FILE THAT DIFFERS BETWEEN EDITIONS. Never copy it across.
# Everything below is byte-identical in ihudak-claude-plugins, mgd-claude-plugins
# and ihudak-copilot-plugins, so a fix to the gate ports by plain `cp` of the body.
PLUGIN_REL="plugins/dev-workflows"   # copilot: dev-workflows
CMD_DIR="commands"                   # copilot: skills
CMD_SUFFIX=".md"                     # copilot: /SKILL.md
CMD_EXCLUDE=""                       # copilot: _shared
REF_DIR="references"                 # copilot: skills/_shared
REF_FLAT_EXTRA="model-routing"       # canonical: references/model-routing/*.md is a
                                     # subtree of reference FILES; copilot: "" (its
                                     # model-routing.md is a flat file in _shared)
DOC_CMD_DIR="commands"               # copilot: skills
CLI="claude"                         # copilot: copilot
CLI_VERBS="marketplace add|marketplace update|install|reinstall"   # copilot: marketplace add|install|update
CLI_REQUIRED="marketplace add|marketplace update"   # copilot: marketplace add|update -- the verb
                                     # phrases getting-started.md must carry inline. A subset
                                     # of CLI_VERBS; differs per edition because Copilot
                                     # updates with `plugin update --all`, not a marketplace verb.
HAS_COST=1                           # copilot: 0 -- no cost subsystem exists there

FAILURES=0

fail() { printf 'FAIL check %s: %s\n' "$1" "$2" >&2; FAILURES=$((FAILURES + 1)); }
note() { printf '  %s\n' "$1" >&2; }

# ---------------------------------------------------------- shared: command enumeration
# A "command" is $CMD_DIR/<name>$CMD_SUFFIX. When $CMD_SUFFIX names a path (it contains a
# slash -- e.g. copilot's "/SKILL.md"), each command is a DIRECTORY holding that file, so
# enumeration walks directories and excludes $CMD_EXCLUDE (a directory that is not a
# command, e.g. copilot's "_shared"). Otherwise $CMD_SUFFIX is a flat filename suffix and
# enumeration globs files directly -- $CMD_EXCLUDE plays no role there, since a bare
# directory never matches the glob.
cmd_names() { # <plugin-dir> -> one command name per line
  local p="$1" b
  case "$CMD_SUFFIX" in
    */*) ls -d "$p/$CMD_DIR"/*/ 2>/dev/null | sed 's|/*$||; s|.*/||' | grep -vxF "${CMD_EXCLUDE:-__none__}" ;;
    *)   ls "$p/$CMD_DIR"/*"$CMD_SUFFIX" 2>/dev/null | while IFS= read -r b; do
           b="$(basename "$b")"; printf '%s\n' "${b%$CMD_SUFFIX}"
         done ;;
  esac
}
cmd_file() { printf '%s/%s/%s%s\n' "$1" "$CMD_DIR" "$2" "$CMD_SUFFIX"; } # <plugin-dir> <name> -> its file path

# ---------------------------------------------------------------- check 1 + 2
# Every relative link resolves, and every #anchor resolves to a real heading in
# whichever file it names. A bare `#anchor` names no file, so a file-existence
# check cannot see it -- that is why check 2 is separate. ai-containers' split
# broke 24 anchors this way.
# GitHub KEEPS non-ASCII letters in an anchor and lowercases them, and disambiguates a
# repeated heading as name, name-1, name-2. Neither is expressible in `tr`/`sed` without a
# UTF-8 locale -- in a C/ASCII locale those letters are deleted outright, so a CORRECT link
# fails check 2. python3 casefolds and classifies Unicode regardless of locale, and it is
# already a hard requirement of this repo's CI (scripts/validate-catalog.py runs in the same
# job), so this adds no dependency. The shell path is kept only for a bare environment with
# no python3, and it announces its own limitation instead of mis-resolving in silence.
strip_fences() { # drop fenced code blocks: an illustrative link inside a ```markdown
                 # block is not a real link, and a `#` line inside one is not a heading.
                 # check 6 has always stripped fences; checks 1 and 2 did not, which made
                 # them fail on correct content AND accept anchors that do not exist.
  awk '/^[ \t]*(```|~~~)/ { infence = !infence; next } !infence' "$1"
}

HAVE_PY=0; command -v python3 >/dev/null 2>&1 && HAVE_PY=1

slug_list() { # <markdown file> -> one GitHub anchor per heading, in document order
  if [ "$HAVE_PY" = 1 ]; then
    strip_fences "$1" | grep -E '^#{1,6} ' | sed -E 's/^#{1,6} //' | python3 -c '
import sys
seen = {}
for line in sys.stdin:
    h = line.rstrip("\n").replace("`", "").lower()
    s = "".join(c for c in h if c.isalnum() or c in " _-").replace(" ", "-")
    n = seen.get(s, 0); seen[s] = n + 1
    print(s if n == 0 else "%s-%d" % (s, n))
'
  else
    strip_fences "$1" | grep -E '^#{1,6} ' | sed -E 's/^#{1,6} //' \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/`//g; s/[^a-z0-9 _-]//g; s/ /-/g' \
      | awk '{ c = seen[$0]++; if (c == 0) print; else print $0 "-" c }'
  fi
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
        slugs=$(slug_list "$heading_file" 2>/dev/null)
        if ! grep -qx -- "$anchor" <<<"$slugs"; then
          fail 2 "$f -> ${target:-(this file)}#$anchor (no such heading)"
        fi
      fi
    done < <(strip_fences "$f" | grep -oE '\]\([^)#][^)]*\)|\]\(#[^)]*\)' \
             | sed -E 's/^\]\(//; s/\)$//; s/[[:space:]]+"[^"]*"$//; s/^<//; s/>$//' \
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
  [ -f "$1/$PLUGIN_REL/README.md" ] && seen="$seen
$(cd "$1/$PLUGIN_REL" && pwd)/README.md"
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

  # commands <-> docs/$DOC_CMD_DIR/
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    [ -f "$d/$DOC_CMD_DIR/$n.md" ] || fail 4 "command '$n' has no page at docs/$DOC_CMD_DIR/$n.md"
  done < <(cmd_names "$p")
  while IFS= read -r n; do
    [ -f "$(cmd_file "$p" "$n")" ] || fail 4 "docs/$DOC_CMD_DIR/$n.md names no real command"
  done < <(ls "$d/$DOC_CMD_DIR"/*.md 2>/dev/null | sed 's|.*/||; s|\.md$||')

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
  done < <({ ls "$p/$REF_DIR"/*.md 2>/dev/null; ls "$p/$REF_DIR"/*.yaml 2>/dev/null; \
             [ -n "$REF_FLAT_EXTRA" ] && ls "$p/$REF_DIR/$REF_FLAT_EXTRA"/*.md 2>/dev/null; } | sed 's|.*/||')
  while IFS= read -r n; do
    [ -f "$p/$REF_DIR/$n" ] || { [ -n "$REF_FLAT_EXTRA" ] && [ -f "$p/$REF_DIR/$REF_FLAT_EXTRA/$n" ]; } \
      || fail 4 "reference/references.md names '$n', which is not a reference file"
  done < <(grep -oE '`[A-Za-z0-9_.-]+\.(md|yaml)`' "$d/reference/references.md" 2>/dev/null | tr -d '`')

  # reference subtree counts -- *.md only: these subtrees also carry vendored
  # non-markdown data/templates that are not user-facing reference pages, so
  # counting everything would fail this check on files docs/ never claims.
  # Derived from the tree, never hardcoded: a hardcoded list cannot see a NEW subtree,
  # which is how a whole directory of reference docs would ship undocumented.
  # model-routing/ is excluded deliberately -- its *.md are inventoried file-by-file above.
  local dir count claimed
  for dir in $(ls -d "$p/$REF_DIR"/*/ 2>/dev/null | sed 's|/*$||; s|.*/||'); do
    [ -n "$REF_FLAT_EXTRA" ] && [ "$dir" = "$REF_FLAT_EXTRA" ] && continue
    count=$(find "$p/$REF_DIR/$dir" -name '*.md' | wc -l | tr -d ' ')
    claimed=$(grep -oE "\`$dir/\` \(([0-9]+)\)" "$d/reference/references.md" 2>/dev/null | grep -oE '[0-9]+' | head -1)
    [ "$claimed" = "$count" ] || fail 4 "reference/references.md says $dir/ has '${claimed:-nothing}', tree has $count"
  done
  # ...and the reverse: a subtree the page claims but the tree no longer has. Without this,
  # `rm -rf references/upgrade/` passes while the page still advertises `upgrade/` (3).
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    [ -d "$p/$REF_DIR/$dir" ] || fail 4 "reference/references.md claims subtree $dir/, which does not exist"
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
# Environment variables agree in both directions. The scan covers the command
# dir ($CMD_DIR), agents/, the reference dir ($REF_DIR), hooks/, and the literal
# skills/ -- narrowing it to the first three would let a variable only a hook
# reads look documented-but-unread. The
# runtime-exclusion list is written in, so a SEVENTH user-settable variable fails
# this check rather than passing silently. That silent pass is exactly how
# GIT_USER_INITIALS and DEV_WORKFLOWS_COST_PRICES came to be missing from the
# section named after them (defect D4).
RUNTIME_VARS="CLAUDE_PLUGIN_ROOT ARGUMENTS OSTYPE BASH_SOURCE BASH_REMATCH ROOT OWNER_REPO"

# NOTE: this tripwire is self-referential -- it guards a constant in THIS file, and --selftest
# only ever mutates a copy of the fixture tree, never the script. It is therefore verified
# out-of-band (mutate a copy of this script, run it against any tree, see check 5 fail).
# Frozen copy. RUNTIME_VARS is a SILENCER: every name in it kills both directions of
# check 5 for that variable, permanently, and no mutation of the fixture can reveal it.
# Changing the list must therefore be a deliberate, reviewed act -- so it trips this
# tripwire and the editor has to update both. Each current entry is justified:
#   CLAUDE_PLUGIN_ROOT ARGUMENTS OSTYPE BASH_SOURCE BASH_REMATCH -- runtime/shell, not user-settable
#   ROOT       -- hook-local shell variable (hooks/changelog-owners-reminder.sh)
#   OWNER_REPO -- template placeholder in references/phase-handoff.md
RUNTIME_VARS_FROZEN="ARGUMENTS BASH_REMATCH BASH_SOURCE CLAUDE_PLUGIN_ROOT OSTYPE OWNER_REPO ROOT"

check_env_vars() {
  local root="$1" p="$1/$PLUGIN_REL" d="$1/$PLUGIN_REL/docs" v
  local now; now=$(printf '%s\n' $RUNTIME_VARS | sort | tr '\n' ' ' | sed 's/ $//')
  [ "$now" = "$RUNTIME_VARS_FROZEN" ] \
    || fail 5 "RUNTIME_VARS changed -- every entry silences check 5 for that variable; justify it in the comment above and update RUNTIME_VARS_FROZEN in the same edit"
  local read_vars documented
  # `skills` stays a literal fifth root: in editions where CMD_DIR is not "skills"
  # there is still a skills/ tree to scan, and in editions where it is, sort -u
  # dedupes. Dropping it is invisible until someone adds a $VAR only under skills/.
  read_vars=$(grep -rhoE '\$\{?[A-Z][A-Z0-9_]{2,}\}?' \
                "$p/$CMD_DIR" "$p/agents" "$p/$REF_DIR" "$p/hooks" "$p/skills" 2>/dev/null \
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
             /^[ \t]*(```|~~~)/ { infence = !infence; next }
             infence   { next }
             /^[[:space:]]*\|/ {
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
# identity, so it is pinned to the repo-root README.
#
# It is a SUBSET pin, not equality: the root README documents the whole
# marketplace, while this page documents ONE plugin and should install only what
# that plugin actually needs. (dev-workflows references `dt-style-guide` 32 times;
# `acli` zero, and `references/followup-emission.md` states outright that it has no
# runtime dependency on `obsidian-llm-wiki`.) So every line HERE must appear verbatim
# in the root README -- which is what catches a drifted marketplace name or command
# form -- but the root README may list more.
check_install_block() {
  local root="$1" a b extra line
  a=$(grep -oE "^$CLI plugin ($CLI_VERBS) .*" "$root/README.md" 2>/dev/null | sort -u)
  b=$(grep -oE "^$CLI plugin ($CLI_VERBS) .*" "$root/$PLUGIN_REL/docs/getting-started.md" 2>/dev/null | sort -u)
  if [ -z "$a" ]; then fail 7 "repo-root README.md has no '$CLI plugin ...' command lines to pin against"; return; fi
  if [ -z "$b" ]; then fail 7 "getting-started.md has no '$CLI plugin ...' command lines -- it must carry them inline"; return; fi

  extra=$(comm -13 <(printf '%s\n' "$a") <(printf '%s\n' "$b"))
  if [ -n "$extra" ]; then
    fail 7 "getting-started.md carries install commands the repo-root README does not"
    while IFS= read -r line; do [ -n "$line" ] && note "only in getting-started: $line"; done <<<"$extra"
  fi

  # The required verbs are the edition identity itself -- a reader who follows this
  # page must be able to perform them from it alone. CLI_REQUIRED is pipe-separated;
  # split on it without leaking the IFS change past this loop.
  local _saved_ifs="$IFS"
  IFS='|'
  for line in $CLI_REQUIRED; do
    IFS="$_saved_ifs"
    [ -n "$line" ] || continue   # guards a doubled '|' in a hand-edited CLI_REQUIRED,
                                  # which would otherwise yield one empty-string split
                                  # field and grep for a malformed pattern
    grep -q "^$CLI plugin $line " <<<"$b" \
      || fail 7 "getting-started.md is missing its '$CLI plugin $line' line"
  done
  IFS="$_saved_ifs"
  grep -q "^$CLI plugin install ${PLUGIN_REL##*/}@" <<<"$b" \
    || fail 7 "getting-started.md does not install ${PLUGIN_REL##*/} itself"
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
  local p="$1" f n
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    f=$(cmd_file "$p" "$n")
    [ -f "$f" ] || continue
    tr '\n' ' ' < "$f" | tr -s ' ' \
      | grep -oE '`command: /[a-z-]+( \([A-Za-z]+ mode\))?`, `phase: [a-z-]+`, `role: [a-z]+`' \
      | sed -E 's/`command: //; s/ \([A-Za-z]+ mode\)//; s/`, `phase: /|/; s/`, `role: /|/; s/`$//'
  done < <(cmd_names "$p") | sort -u
}

check_cost_attribution() {
  [ "$HAS_COST" = 1 ] || { note "check 8 not applicable: this edition has no cost subsystem"; return; }
  local root="$1" p="$1/$PLUGIN_REL" table calls line cmd phase role want
  table=$(sed -n '/^## 7\./,/^## 8\./p' "$p/$REF_DIR/cost-emission.md" 2>/dev/null \
          | grep -oE '^\| `/[a-z-]+` \| [^|]+ \| [^|]+ \|' \
          | sed -E 's/^\| `//; s/` \| /|/; s/ \| /|/; s/ *\|$//; s/\*//g; s/ *\| */|/g')
  [ -n "$table" ] || { fail 8 "$REF_DIR/cost-emission.md has no section-7 attribution table"; return; }
  calls=$(emit_cost_calls "$p")
  [ -n "$calls" ] || { fail 8 "no emit-cost call site found in $CMD_DIR/ -- the extractor has stopped matching"; return; }

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
  local f n cn
  while IFS= read -r cn; do
    [ -n "$cn" ] || continue
    f=$(cmd_file "$p" "$cn")
    [ -f "$f" ] || continue
    grep -q 'emit-cost' "$f" || continue
    n="/$cn"
    grep -qF "$n|" <<<"$calls" \
      || fail 8 "$CMD_DIR/$cn$CMD_SUFFIX calls emit-cost but no phase/role triple matched -- the EXTRACTOR has drifted, not the table; fix the regex, never the row"
  done < <(cmd_names "$p")
}

# ------------------------------------------------------------------- check 9
# Prose counts. check 4 gates the INVENTORIES in both directions, but not the sentences
# that state their size. A 22nd command with a page and an index link passes check 4 while
# `plugins/dev-workflows/README.md` still says "twenty-one slash commands" -- and a reader
# meets the sentence before the table. Same for the agent, reference-file, hook, skill and
# environment-variable totals.
_word2num() {
  case "$1" in
    one) echo 1 ;; two) echo 2 ;; three) echo 3 ;; four) echo 4 ;; five) echo 5 ;;
    six) echo 6 ;; seven) echo 7 ;; eight) echo 8 ;; nine) echo 9 ;; ten) echo 10 ;;
    eleven) echo 11 ;; twelve) echo 12 ;; thirteen) echo 13 ;; fourteen) echo 14 ;;
    twenty-one) echo 21 ;; thirty-four) echo 34 ;; ninety-eight) echo 98 ;;
    *) echo "$1" ;;
  esac
}

check_prose_counts() {
  local root="$1" p="$1/$PLUGIN_REL" d="$1/$PLUGIN_REL/docs"
  local raw claimed actual label file pat

  _one() { # <label> <file> <extended-regex whose match STARTS with the numeral> <actual>
    label="$1"; file="$2"; pat="$3"; actual="$4"
    [ -f "$file" ] || return 0
    # -i, and lowercase the captured numeral: a count sentence may open a sentence
    # ("Thirteen commands emit ...") or sit mid-sentence ("twenty-one slash commands").
    raw=$(grep -ohEi "$pat" "$file" 2>/dev/null | head -1 | awk '{print tolower($1)}')
    if [ -z "$raw" ]; then
      fail 9 "$label: no count sentence found in ${file#$root/} -- the wording drifted, so nothing is being checked"
      return 0
    fi
    claimed=$(_word2num "$raw")
    [ "$claimed" = "$actual" ] \
      || fail 9 "$label: ${file#$root/} says $raw ($claimed), tree has $actual"
  }

  _one "commands"        "$p/README.md"                  '(one|two|three|four|five|six|seven|eight|nine|ten|twenty-one|thirty-four|ninety-eight|[0-9]+) slash commands'    "$(cmd_names "$p" | wc -l | tr -d ' ')"
  _one "agents"          "$d/reference/agents.md"        '(one|two|three|four|five|six|seven|eight|nine|ten|twenty-one|thirty-four|ninety-eight|[0-9]+) agents'           "$(ls "$p/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')"
  _one "reference files" "$d/reference/references.md"    '(one|two|three|four|five|six|seven|eight|nine|ten|twenty-one|thirty-four|ninety-eight|[0-9]+) files'           "$(find "$p/$REF_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')"
  _one "hooks"           "$d/reference/hooks.md"         '(one|two|three|four|five|six|seven|eight|nine|ten|twenty-one|thirty-four|ninety-eight|[0-9]+) hooks'                   "$(ls "$p/hooks"/*.sh 2>/dev/null | wc -l | tr -d ' ')"
  _one "skills"          "$d/README.md"                  '(one|two|three|four|five|six|seven|eight|nine|ten|twenty-one|thirty-four|ninety-eight|[0-9]+) bundled skills'           "$(ls -d "$p/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')"

  # The user-settable total is derived the same way check 5 derives its scan, so the two
  # can never disagree about what "user-settable" means.
  local read_vars n_settable v
  read_vars=$(grep -rhoE '\$\{?[A-Z][A-Z0-9_]{2,}\}?' \
                "$p/$CMD_DIR" "$p/agents" "$p/$REF_DIR" "$p/hooks" "$p/skills" 2>/dev/null \
              | tr -d '${}' | sort -u)
  n_settable=0
  for v in $read_vars; do
    case " $RUNTIME_VARS " in *" $v "*) continue ;; esac
    n_settable=$((n_settable + 1))
  done
  _one "environment variables" "$d/reference/environment.md" '(one|two|three|four|five|six|seven|eight|nine|ten|twenty-one|thirty-four|ninety-eight|[0-9]+) user-settable' "$n_settable"

  # The size of the cost-emitting set is prose too, and it is the count that went stale the
  # moment /prompt and /feedback started emitting. Derived from the same extractor check 8 uses.
  if [ "$HAS_COST" = 1 ]; then
    local n_emit
    n_emit=$(emit_cost_calls "$p" | cut -d'|' -f1 | sort -u | grep -c . || true)
    _one "cost-emitting commands" "$d/reference/session-cost.md" \
         '(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|twenty-one|thirty-four|ninety-eight|[0-9]+) commands emit a cost entry' "$n_emit"
  else
    note "check 9 cost-emitting-commands assertion not applicable: this edition has no cost subsystem"
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
  expect_fail "a broken relative link is rejected"  1 "sed -i.bak 's|(reference/hooks.md)|(reference/nope.md)|' $PLUGIN_REL/docs/README.md"
  expect_fail "a broken link in the plugin README is rejected" 1 "sed -i.bak 's|(docs/README.md)|(docs/NOPE.md)|' $PLUGIN_REL/README.md"
  expect_fail "a broken anchor is rejected"         2 "sed -i.bak 's|(getting-started.md#install)|(getting-started.md#no-such-heading)|' $PLUGIN_REL/docs/README.md"
  expect_fail "an orphan page is rejected"          3 "printf '# Orphan\n\nUnreachable.\n' > $PLUGIN_REL/docs/orphan.md"
  expect_fail "an undocumented command is rejected" 4 "mkdir -p $(dirname $(cmd_file $PLUGIN_REL delta)) 2>/dev/null; printf -- '---\nname: delta\n---\n' > $(cmd_file $PLUGIN_REL delta)"
  expect_fail "a drifted subtree count is rejected" 4 "sed -i.bak 's|\`handoff/\` (2)|\`handoff/\` (3)|' $PLUGIN_REL/docs/reference/references.md"
  expect_fail "an undocumented skill is rejected"    4 "mkdir -p $PLUGIN_REL/skills/epsilon && printf -- '---\nname: epsilon\n---\n' > $PLUGIN_REL/skills/epsilon/SKILL.md"
  expect_fail "an undocumented env var is rejected" 5 "printf 'Reads \$NEW_SETTABLE_VAR here.\n' >> $(cmd_file $PLUGIN_REL alpha)"
  expect_fail "an over-long table cell is rejected" 6 "awk 'BEGIN{s=\"\"; while(length(s)<260) s=s \"x\"; printf \"\\n| a | %s |\\n|---|---|\\n| b | c |\\n\", s}' >> $PLUGIN_REL/docs/reference/hooks.md"
  expect_fail "a drifted install block is rejected" 7 "sed -i.bak 's|$CLI plugin install ${PLUGIN_REL##*/}@fixture-plugins|$CLI plugin install ${PLUGIN_REL##*/}@drifted|' $PLUGIN_REL/docs/getting-started.md"
  expect_fail "a documented nonexistent skill is rejected" 4 "printf '\n| \`ghost-skill\` | Yes | fixture mutation |\n' >> $PLUGIN_REL/docs/reference/references.md"
  expect_fail "a broken link in the ROOT README is rejected" 1 "sed -i.bak 's|($PLUGIN_REL/README.md)|($PLUGIN_REL/NOPE.md)|' README.md"
  expect_fail "a broken bare #anchor is rejected"   2 "printf '\n[self](#no-such-heading-here)\n' >> $PLUGIN_REL/docs/README.md"
  expect_fail "a documented nonexistent agent is rejected"     4 "printf '\n| \`ghost-agent\` | fixture |\n' >> $PLUGIN_REL/docs/reference/agents.md"
  expect_fail "a documented nonexistent hook is rejected"      4 "printf '\n| \`ghost-hook\` | fixture |\n' >> $PLUGIN_REL/docs/reference/hooks.md"
  expect_fail "a documented nonexistent reference file is rejected" 4 "printf '\n- \`ghost-ref.md\`\n' >> $PLUGIN_REL/docs/reference/references.md"
  expect_fail "a claimed-but-absent subtree is rejected"       4 "rm -rf $PLUGIN_REL/$REF_DIR/handoff"
  expect_fail "an undocumented NEW subtree is rejected"        4 "mkdir -p $PLUGIN_REL/$REF_DIR/brandnew && printf '# x\n' > $PLUGIN_REL/$REF_DIR/brandnew/x.md"
  expect_fail "a documented-but-unread env var is rejected"    5 "printf '\n**\`\$PHANTOM_VAR\`** — never read anywhere.\n' >> $PLUGIN_REL/docs/reference/environment.md"
  expect_fail "an over-long cell in the ROOT README is rejected" 6 "awk 'BEGIN{s=\"\"; while(length(s)<260) s=s \"x\"; printf \"\n| a | %s |\n|---|---|\n| b | c |\n\", s}' >> README.md"
  expect_fail "a drifted reinstall command is rejected"        7 "printf '\n$CLI plugin reinstall ${PLUGIN_REL##*/}@fixture-plugins\n' >> $PLUGIN_REL/docs/getting-started.md"
  expect_fail "a drifted prose count is rejected"              9 "mkdir -p $(dirname $(cmd_file $PLUGIN_REL gamma)) 2>/dev/null; printf -- '---\nname: gamma\n---\n' > $(cmd_file $PLUGIN_REL gamma) && printf -- '# /gamma\n\nPage.\n' > $PLUGIN_REL/docs/$DOC_CMD_DIR/gamma.md && sed -i.bak 's|($DOC_CMD_DIR/alpha.md)|($DOC_CMD_DIR/alpha.md), [\`/gamma\`]($DOC_CMD_DIR/gamma.md)|' $PLUGIN_REL/docs/README.md"
  expect_fail "a count sentence reworded away is rejected"     9 "sed -i.bak 's|one slash commands|a handful of slash commands|' $PLUGIN_REL/README.md"
  expect_fail "a wrong non-ASCII anchor is rejected"           2 "printf '\n[bad](#uber-config)\n' >> $PLUGIN_REL/docs/$DOC_CMD_DIR/alpha.md"
  expect_fail "a wrong duplicate-heading index is rejected"    2 "printf '\n[bad](#notes-2)\n' >> $PLUGIN_REL/docs/$DOC_CMD_DIR/alpha.md"
  expect_fail "a titled link to a missing file is rejected"    1 "printf '\n[bad](nope.md \"T\")\n' >> $PLUGIN_REL/docs/$DOC_CMD_DIR/alpha.md"
  expect_fail "an angle-bracket link to a missing file is rejected" 1 "printf '\n[bad](<nope.md>)\n' >> $PLUGIN_REL/docs/$DOC_CMD_DIR/alpha.md"
  expect_fail "an over-long INDENTED table cell is rejected"   6 "awk 'BEGIN{s=\"\"; while(length(s)<260) s=s \"q\"; printf \"\n  | a | %s |\n  |---|---|\n\", s}' >> $PLUGIN_REL/docs/reference/agents.md"
  expect_fail "a missing marketplace-add line is rejected"     7 "sed -i.bak '/$CLI plugin marketplace add/d' $PLUGIN_REL/docs/getting-started.md"
  expect_fail "a missing second required-verb line is rejected" 7 "sed -i.bak '/$CLI plugin ${CLI_REQUIRED##*|}/d' $PLUGIN_REL/docs/getting-started.md"
  expect_fail "getting-started not installing the plugin itself is rejected" 7 "sed -i.bak '/$CLI plugin install ${PLUGIN_REL##*/}@/d' $PLUGIN_REL/docs/getting-started.md"
  # The cost subsystem (check 8, and check 9's cost-emitting-commands sentence) does not
  # exist in every edition -- check_cost_attribution and that half of check_prose_counts
  # both return immediately when HAS_COST=0, so a mutation that only a cost check can see
  # would never trip a failure there and would falsely report this selftest case itself as
  # broken. Skip the five cases that depend on the cost subsystem being active -- ALL FOUR
  # check-8 cases (including the emit-cost-call-site field-reorder, which check 8's
  # extractor-coverage assertion alone can see) plus the one check-9 cost-emitting-count case.
  if [ "$HAS_COST" = 1 ]; then
    expect_fail "a drifted emit-cost call site is rejected" 8 "sed -i.bak 's|\`command: /alpha\`, \`phase: fixture-phase\`, \`role: pm\`|\`command: /alpha\`, \`role: pm\`, \`phase: fixture-phase\`|' $(cmd_file $PLUGIN_REL alpha)"
    expect_fail "an unattributed emit-cost call is rejected" 8 "mkdir -p $(dirname $(cmd_file $PLUGIN_REL zeta)) 2>/dev/null; printf -- '---\nname: zeta\n---\n\nCall \`emit-cost\` with \`command: /zeta\`, \`phase: fixture-phase\`, \`role: pm\`, done.\n' > $(cmd_file $PLUGIN_REL zeta) && printf -- '# /zeta\n\nFixture page.\n' > $PLUGIN_REL/docs/$DOC_CMD_DIR/zeta.md && sed -i.bak 's|($DOC_CMD_DIR/alpha.md)|($DOC_CMD_DIR/alpha.md), [\`/zeta\`]($DOC_CMD_DIR/zeta.md)|' $PLUGIN_REL/docs/README.md"
    expect_fail "a drifted attributed role is rejected"      8 "sed -i.bak 's;| \`/alpha\` | fixture-phase | pm |;| \`/alpha\` | fixture-phase | pe |;' $PLUGIN_REL/$REF_DIR/cost-emission.md"
    expect_fail "a section-7 row for a non-emitting command is rejected" 8 "sed -i.bak 's;| \`/alpha\` | fixture-phase | pm |;| \`/alpha\` | fixture-phase | pm |\n| \`/omega\` | fixture-phase | pm |;' $PLUGIN_REL/$REF_DIR/cost-emission.md"
    expect_fail "a drifted cost-emitting count is rejected"  9 "sed -i.bak 's|One commands emit a cost entry|Five commands emit a cost entry|' $PLUGIN_REL/docs/reference/session-cost.md"
  else
    printf 'skip  5 cost cases (this edition has no cost subsystem)\n'
  fi

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

[ "$HAVE_PY" = 1 ] || note "python3 not found; falling back to ASCII slugs -- anchors whose heading contains a non-ASCII letter cannot be verified here"
check_links_and_anchors "$ROOT"
check_orphans           "$ROOT"
check_inventory         "$ROOT"
check_env_vars          "$ROOT"
check_table_cells       "$ROOT"
check_install_block     "$ROOT"
check_cost_attribution  "$ROOT"
check_prose_counts      "$ROOT"

if [ "$FAILURES" -gt 0 ]; then
  echo "FAIL: $FAILURES problem(s) under $PLUGIN_REL" >&2
  exit 1
fi
echo "PASS: docs are consistent with the plugin under $PLUGIN_REL"
