#!/usr/bin/env bash
# Guards the plugin's docs/ tree against the drift that splitting prose invites.
#
# Splitting one README into a multi-page tree multiplies the places drift can hide. Every
# check below exists because a specific failure was observed -- in this plugin, or
# in the two restructures this one follows (a sibling managed-plugins repo,
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

# RUNTIME_VARS is a SILENCER: every name in it kills both directions of check 5 (env-var doc
# agreement) for that variable, permanently -- no mutation of the fixture tree can reveal a
# missing entry, so changing this list is a deliberate, reviewed act. Each edition's host and
# hooks inject differently-named runtime variables, so this pair is edition identity, not
# shared body. Each current entry here is justified:
#   CLAUDE_PLUGIN_ROOT ARGUMENTS OSTYPE BASH_SOURCE BASH_REMATCH -- runtime/shell, not user-settable
#   ROOT       -- hook-local shell variable (hooks/changelog-owners-reminder.sh)
#   OWNER_REPO -- template placeholder in $REF_DIR/phase-handoff.md
RUNTIME_VARS="CLAUDE_PLUGIN_ROOT ARGUMENTS OSTYPE BASH_SOURCE BASH_REMATCH ROOT OWNER_REPO"
                                     # copilot: BASH_REMATCH BASH_SOURCE MODEL_ROUTING OSTYPE
                                     # OWNER_REPO PLUGIN_ROOT ROOT -- reads no ARGUMENTS; adds
                                     # MODEL_ROUTING (hook-local, hooks/preload-context.sh:52)
                                     # and PLUGIN_ROOT (host-injected plugin-root path)
# NOTE: this tripwire is self-referential -- it guards a constant in THIS file, and --selftest
# only ever mutates a copy of the fixture tree, never the script. It is therefore verified
# out-of-band (mutate a copy of this script, run it against any tree, see check 5 fail).
# Frozen (sorted) copy -- check_env_vars() asserts RUNTIME_VARS still sorts to exactly this,
# so a silent edit to the list above fails check 5 instead of passing quietly.
RUNTIME_VARS_FROZEN="ARGUMENTS BASH_REMATCH BASH_SOURCE CLAUDE_PLUGIN_ROOT OSTYPE OWNER_REPO ROOT"

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
# markdown -- in the edition this was found in, the reference dir ($REF_DIR) held 98
# files of which 5 were not markdown, and one of those (cost-prices.yaml) is
# user-overridable and therefore user-facing.
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
  # `rm -rf $REF_DIR/upgrade/` passes while the page still advertises `upgrade/` (3).
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

  # skills <-> docs/reference/references.md -- the FORWARD direction (every skills/
  # directory must be documented as a skill) is inert where $CMD_DIR IS "skills": there,
  # skills/ holds this edition's COMMANDS (already covered by the command inventory
  # above) plus $CMD_EXCLUDE (a reference directory, not a skill), so demanding each be
  # documented as a skill would be false. The REVERSE direction (a documented skill must
  # be real) stays active in every edition -- it catches a stale/phantom claim in
  # references.md regardless of what skills/ holds, and the command inventory does not
  # cover that direction.
  if [ "$CMD_DIR" = "skills" ]; then
    note "check 4 skills forward-check not applicable: skills/ is this edition's \$CMD_DIR, already covered by the command inventory above"
  else
    while IFS= read -r n; do
      grep -q "\`$n\`" "$d/reference/references.md" 2>/dev/null || fail 4 "skill '$n' is absent from reference/references.md"
    done < <(ls -d "$p/skills"/*/ 2>/dev/null | sed 's|/*$||; s|.*/||')
  fi
  while IFS= read -r n; do
    [ -d "$p/skills/$n" ] || fail 4 "reference/references.md names skill '$n', which is not a skill"
  done < <(grep -oE '^\| `[a-z-]+`' "$d/reference/references.md" 2>/dev/null | tr -d '|` ')
}

# ------------------------------------------------------------------- check 5
# Environment variables agree in both directions. The scan covers the command
# dir ($CMD_DIR), agents/, the reference dir ($REF_DIR), hooks/, and the literal
# skills/ -- narrowing it to the first three would let a variable only a hook
# reads look documented-but-unread. The
# runtime-exclusion list is written in, so an EIGHTH user-settable variable fails
# this check rather than passing silently. That silent pass is exactly how
# GIT_USER_INITIALS and DEV_WORKFLOWS_COST_PRICES came to be missing from the
# section named after them (defect D4).
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
# that plugin actually needs. (dev-workflows references `prose-style` 32 times;
# `acli` zero, and `$REF_DIR/followup-emission.md` states outright that it has no
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
# fixed phase/role pair has a row in $REF_DIR/cost-emission.md section 7 carrying
# those same two values, and every section-7 row names a real command. Defect D2 --
# /update-prd emitting `phase: prd-update, role: pm` with no section-7 row -- was found
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
# `$PLUGIN_REL/README.md` still says "twenty-one slash commands" -- and a reader
# meets the sentence before the table. Same for the agent, reference-file, hook, skill and
# environment-variable totals.
_word2num() {
  case "$1" in
    one) echo 1 ;; two) echo 2 ;; three) echo 3 ;; four) echo 4 ;; five) echo 5 ;;
    six) echo 6 ;; seven) echo 7 ;; eight) echo 8 ;; nine) echo 9 ;; ten) echo 10 ;;
    eleven) echo 11 ;; twelve) echo 12 ;; thirteen) echo 13 ;; fourteen) echo 14 ;;
    fifteen) echo 15 ;; sixteen) echo 16 ;; seventeen) echo 17 ;; eighteen) echo 18 ;;
    nineteen) echo 19 ;;
    twenty-one) echo 21 ;; twenty-two) echo 22 ;; twenty-three) echo 23 ;; twenty-four) echo 24 ;;
    twenty-five) echo 25 ;; twenty-six) echo 26 ;; twenty-seven) echo 27 ;;
    thirty-four) echo 34 ;; ninety-eight) echo 98 ;;
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

  # Left-anchored, on EVERY alternation below without exception: without a boundary, an
  # unenumerated compound like "twenty-five" would let the bare alternative "five" match its own
  # tail and silently compare the wrong numeral instead of failing loudly. The argument does not
  # depend on which count a sentence carries, so neither does the anchor -- an assertion left
  # unanchored is the one an unenumerated compound slips past, and it passes on a coincidentally
  # correct numeral rather than failing. (^|[^[:alnum:]_-]) keeps the match from starting mid-word
  # or mid-compound; a captured boundary character is whitespace in every real sentence, so it
  # disappears when `awk '{print $1}'` splits the extracted match.
  _one "commands"        "$p/README.md"                  '(^|[^[:alnum:]_-])(one|two|three|four|five|six|seven|eight|nine|ten|fifteen|sixteen|seventeen|eighteen|nineteen|twenty-one|twenty-two|twenty-three|twenty-four|twenty-five|twenty-six|twenty-seven|thirty-four|ninety-eight|[0-9]+) slash commands'    "$(cmd_names "$p" | wc -l | tr -d ' ')"
  _one "agents"          "$d/reference/agents.md"        '(^|[^[:alnum:]_-])(one|two|three|four|five|six|seven|eight|nine|ten|twenty-one|thirty-four|ninety-eight|[0-9]+) agents'           "$(ls "$p/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')"
  _one "reference files" "$d/reference/references.md"    '(^|[^[:alnum:]_-])(one|two|three|four|five|six|seven|eight|nine|ten|twenty-one|thirty-four|ninety-eight|[0-9]+) files'           "$(find "$p/$REF_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')"
  _one "hooks"           "$d/reference/hooks.md"         '(^|[^[:alnum:]_-])(one|two|three|four|five|six|seven|eight|nine|ten|twenty-one|thirty-four|ninety-eight|[0-9]+) hooks'                   "$(ls "$p/hooks"/*.sh 2>/dev/null | wc -l | tr -d ' ')"
  # Inert where $CMD_DIR IS "skills" (see check 4's skills forward-check, same reason):
  # ls -d "$p/skills"/*/ would count this edition's commands plus $CMD_EXCLUDE, not
  # bundled skills -- there is no separate "N bundled skills" sentence to state there.
  if [ "$CMD_DIR" = "skills" ]; then
    note "check 9 skills-count assertion not applicable: skills/ is this edition's \$CMD_DIR, already counted by the commands assertion above"
  else
    _one "skills"          "$d/README.md"                  '(^|[^[:alnum:]_-])(one|two|three|four|five|six|seven|eight|nine|ten|twenty-one|thirty-four|ninety-eight|[0-9]+) bundled skills'           "$(ls -d "$p/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')"
  fi

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
  _one "environment variables" "$d/reference/environment.md" '(^|[^[:alnum:]_-])(one|two|three|four|five|six|seven|eight|nine|ten|twenty-one|thirty-four|ninety-eight|[0-9]+) user-settable' "$n_settable"

  # The size of the cost-emitting set is prose too, and it is the count that went stale the
  # moment /prompt and /feedback started emitting. Derived from the same extractor check 8 uses.
  if [ "$HAS_COST" = 1 ]; then
    local n_emit
    n_emit=$(emit_cost_calls "$p" | cut -d'|' -f1 | sort -u | grep -c . || true)
    _one "cost-emitting commands" "$d/reference/session-cost.md" \
         '(^|[^[:alnum:]_-])(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty-one|twenty-two|twenty-three|twenty-four|twenty-five|twenty-six|twenty-seven|thirty-four|ninety-eight|[0-9]+) commands emit a cost entry' "$n_emit"
  else
    note "check 9 cost-emitting-commands assertion not applicable: this edition has no cost subsystem"
  fi
}

# ------------------------------------------------------------------ check 10
# Identity quarantine. No page under $PLUGIN_REL/docs/ may name the marketplace this
# plugin ships from, or the repository that contains it. getting-started.md is the single
# sanctioned exception: it is the one page whose job is to say where the plugin comes
# from, which is why check 7 pins its install block to the repo-root README verbatim.
#
# The binding reason is FORKS. A marketplace name or container-repo URL written into a
# page is wrong in anyone's fork -- the fork ships from a different marketplace, and its
# pages would keep sending readers to the upstream it was forked from. Two per-command
# pages linked a sibling plugin by full container URL and survived several releases;
# nothing in the build could see them, because check 7 pins getting-started.md alone.
#
# The tokens are DERIVED from the repo-root README's own install block -- the same lines
# check 7 already extracts -- and are never written in here. A fork renames its
# marketplace and its container repo in that block, and this check follows without an
# edit. Deriving NOTHING is a failure, not a pass: a token set that came up empty would
# make this check examine nothing and pass every tree.
#
# What it deliberately does NOT cover: any OTHER repository a page might name -- the
# container-image / dev-environment repo the repo-root README recommends, a sibling
# project, a third-party plugin. Nothing in the tree marks which third-party slug is
# "an environment", so a check that guessed would be guessing. It also leaves the
# repo-root README and $PLUGIN_REL/README.md alone: neither is a page under docs/, and
# the root README is where this identity is supposed to be stated.
check_identity_quarantine() {
  local root="$1" d="$1/$PLUGIN_REL/docs" tokens t f hit pat
  # `sed 'p; s|.*/||'` emits the slug AND its bare repo name: a page can name either.
  tokens=$( { grep -oE "^$CLI plugin marketplace add [^[:space:]]+" "$root/README.md" 2>/dev/null \
                | sed -E "s|^$CLI plugin marketplace add ||; s|/+$||" | sed 'p; s|.*/||'
              grep -oE "^$CLI plugin install [^[:space:]]+@[^[:space:]]+" "$root/README.md" 2>/dev/null \
                | sed -E 's/.*@//'
              grep -oE "^$CLI plugin marketplace update [^[:space:]]+" "$root/README.md" 2>/dev/null \
                | sed -E "s|^$CLI plugin marketplace update ||"; } \
            | grep -vE '^[[:space:]]*$' | sort -u)
  if [ -z "$tokens" ]; then
    fail 10 "no marketplace or container-repo token could be derived from the repo-root README's '$CLI plugin ...' lines -- this check would examine nothing"
    return
  fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ "$f" = "$d/getting-started.md" ] && continue   # the single sanctioned exception
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      # Word-boundary match, NOT substring. A fork is free to pick a short marketplace name --
      # `workflows` is a plausible one -- and an unanchored grep then reports every page that
      # says `dev-workflows`. That was measured: renaming this marketplace to `workflows`
      # produced 38 check-10 failures on unmodified, correct pages. A gate that fires 38 times
      # on correct content in a fork is a gate that fork deletes in its first week, and forks
      # are this check's entire rationale.
      #
      # The boundary class is [A-Za-z0-9_-]: a hyphen HAS to be in it (that is what separates
      # `workflows` from `dev-workflows`), and `@`, `/` and `.` have to be OUT of it -- the
      # marketplace is named as `<plugin>@<marketplace>` and the container repo as
      # `github.com/<owner>/<repo>/tree/...`, so a boundary class containing them would miss
      # the two forms this check exists to catch.
      pat=$(printf '%s' "$t" | sed 's/[][\\.^$*+?(){}|]/\\&/g')
      hit=$(grep -nE "(^|[^A-Za-z0-9_-])$pat([^A-Za-z0-9_-]|$)" "$f" 2>/dev/null | head -1)
      [ -n "$hit" ] && fail 10 "${f#$root/}:${hit%%:*} names '$t' -- no page under $PLUGIN_REL/docs/ may name the marketplace this plugin ships from or the repository that contains it (getting-started.md is the only exception); a fork of this repo inherits the wrong one"
    done <<<"$tokens"
  done < <(find "$d" -name '*.md' 2>/dev/null | sort)
}

# ------------------------------------------------------------------ check 11
# Merge-clause adoption. An offer that names a downstream command whose Phase 0 gate
# targets an artifact THIS run writes must carry the `<merge-clause>` placeholder, because
# that command stops while this phase's pull request is open. The placeholder and its
# resolution table live in $REF_DIR/next-phase-offer.md, which binds the rule to EVERY offer
# this plugin prints; the family glob below is this GATE's scope, not the rule's, and that
# same file records why it is not widened. This check only enforces adoption.
#
# The failure it exists for is PARTIAL adoption, which is worse than none: a reference
# claiming family-wide ownership while seven offers still carried a hardcoded clause, or
# no clause, each naming a command whose gate the offering run itself feeds. That set was
# found once, by enumerating every option by hand. Nothing re-enumerated it afterwards.
#
# Three relations, every one DERIVED, none written in here:
#   family  -- the `<plugin>:<family>*` glob next-phase-offer.md names, which is this gate's
#              scope. Only offers made BY a command of that family are checked. Widening it
#              was measured, not assumed: with the filter removed the check fires on four
#              sites -- a command that runs no handoff at all, two mid-run refusals, and a
#              report sentence trailing an array on the same line -- every one correct
#              content, and catches none of the five offers outside the family that DID
#              carry an unconditional clause. A `choices:` array here is a refusal or a
#              branch point as often as it is an offer, and nothing marks which. Do not
#              widen without new evidence; next-phase-offer.md holds the full record.
#   targets -- what each command runs `require-on-main` against, read out of
#              phase-handoff.md's row-F table (column 2's backticked *.md, by basename).
#   writers -- what a command declares it hands off, read out of its own
#              `deliverable_paths` = ... `title:` span (same basename form).
# An offer is REQUIRED to carry the clause when writers(offerer) and targets(offered)
# intersect. It is never required to DROP one: an offer may carry the clause for a reason
# this check cannot see, and a check that forbade that would be asserting more than it knows.
#
# What it deliberately does NOT catch. It reads the option's TEXT for the placeholder, not
# the clause the run resolves it to -- whether the resolution table is applied correctly at
# runtime is not in the file. It cannot see an offer outside a `choices:` array (a prose
# `### Next step` line is not checked). And its writer relation is the paths the command
# DECLARES; a file a run writes but never declares is invisible to it, which under-fires
# rather than over-fires. That last one limits WHICH paths are seen; it is not a licence for a
# whole command to drop out. Any relation coming up empty is a FAILURE -- per family command
# for `writers`, run-wide for the family glob and the target table -- so a reworded handoff
# turns the build red instead of quietly narrowing this check's surface.
check_merge_clause() {
  local root="$1" p="$1/$PLUGIN_REL"
  local ref="$p/$REF_DIR/next-phase-offer.md" ph="$p/$REF_DIR/phase-handoff.md"
  local qual="/${PLUGIN_REL##*/}:" glob targets writers offers route_n=0 req_n=0
  local y f x ln has t need needt

  [ -f "$ref" ] || { fail 11 "$REF_DIR/next-phase-offer.md is missing -- it owns the <merge-clause> placeholder, its resolution table, and the command family the rule binds"; return; }
  [ -f "$ph" ]  || { fail 11 "$REF_DIR/phase-handoff.md is missing -- its row-F table is where each command's require-on-main target is declared"; return; }

  glob=$(grep -oE "$qual[a-z][a-z0-9-]*\*" "$ref" 2>/dev/null | head -1 | sed "s|^$qual||")
  [ -n "$glob" ] || { fail 11 "next-phase-offer.md no longer names the command family the <merge-clause> rule binds (expected a \`$qual<family>*\` phrase) -- with no family, this check would examine no offer at all"; return; }

  # targets: one `<command>|<artifact-basename>` line per row-F table cell. Column 2 only --
  # column 3 routinely cites reference FILES that are not gate targets.
  targets=$(awk -F'|' '
    /^\| `?\/[a-z]/ {
      c1 = $2; c2 = $3; n = 0
      while (match(c2, /`[^`]*\.md`/)) {
        t = substr(c2, RSTART + 1, RLENGTH - 2); sub(/.*\//, "", t); tg[++n] = t
        c2 = substr(c2, RSTART + RLENGTH)
      }
      if (n == 0) next
      while (match(c1, /\/[a-z][a-z0-9-]*/)) {
        cmd = substr(c1, RSTART + 1, RLENGTH - 1); c1 = substr(c1, RSTART + RLENGTH)
        for (i = 1; i <= n; i++) print cmd "|" tg[i]
      }
    }' "$ph" | sort -u)
  [ -n "$targets" ] || { fail 11 "$REF_DIR/phase-handoff.md's row-F table yielded no require-on-main target -- the EXTRACTOR has drifted, not the table; fix the parser, never the rows"; return; }

  while IFS= read -r y; do
    [ -n "$y" ] || continue
    case "$y" in $glob) ;; *) continue ;; esac
    f=$(cmd_file "$p" "$y"); [ -f "$f" ] || continue
    route_n=$((route_n + 1))

    # offers: one `<line>|<offered-command>|<0|1 carries the placeholder>` per option.
    offers=$(awk -v Y="$y" -v Q="$qual" '
      index($0, "choices: [") {
        body = substr($0, index($0, "choices: [") + 9)
        while (match(body, /"[^"]*"/)) {
          opt = substr(body, RSTART + 1, RLENGTH - 2); body = substr(body, RSTART + RLENGTH)
          tmp = opt
          while ((i = index(tmp, Q)) > 0) {
            rest = substr(tmp, i + length(Q))
            match(rest, /^[a-z][a-z0-9-]*/)
            x = substr(rest, 1, RLENGTH); tmp = substr(rest, RLENGTH + 1)
            if (x != Y) print FNR "|" x "|" (index(opt, "<merge-clause>") ? "1" : "0")
          }
        }
      }' "$f" | sort -u)
    # A family command that makes no offer has no surface for this check to cover, so it needs
    # no writer set and is not asserted about.
    [ -n "$offers" ] || continue

    # writers: the backticked *.md paths inside this command's `deliverable_paths` = ...
    # `title:` span. The `=` is required: the same word appears in prose that lists nothing.
    writers=$(awk '
      /`deliverable_paths`[[:space:]]*=/ { span = 1; k = 0 }
      span {
        line = $0
        while (match(line, /`[^`]*\.md`/)) {
          t = substr(line, RSTART + 1, RLENGTH - 2); sub(/.*\//, "", t); print t
          line = substr(line, RSTART + RLENGTH)
        }
        if ($0 ~ /`title:/ || ++k > 20) span = 0
      }' "$f" | sort -u)
    # PER-COMMAND coverage assertion, and it has to be per command. Rewording one command's
    # `deliverable_paths` = to `deliverable_paths` lists empties ITS writer set alone: every
    # offer that command makes silently stops being checked while the whole-run assertions
    # below still pass, because the other family commands keep req_n above zero. That is a
    # gate quietly ceasing to cover part of its surface -- the failure this file's check-8
    # extractor-coverage assertion exists to prevent, and the reason no stop-routing check was
    # shipped. A family command that offers something must declare what it writes.
    if [ -z "$writers" ]; then
      fail 11 "$CMD_DIR/$y$CMD_SUFFIX makes a choices: offer but its \`deliverable_paths\` = ... \`title:\` span yields no path -- the EXTRACTOR has drifted or the handoff sentence was reworded, and every offer this command makes has stopped being checked; fix the parser or restore the declaration, never the offers"
      continue
    fi

    while IFS='|' read -r ln x has; do
      [ -n "$ln" ] || continue
      need=0; needt=""
      while IFS= read -r t; do
        [ -n "$t" ] || continue
        grep -qxF -- "$t" <<<"$writers" && { need=1; needt="$t"; break; }
      done < <(grep -F "$x|" <<<"$targets" | sed 's/^[^|]*|//')
      [ "$need" = 1 ] || continue
      req_n=$((req_n + 1))
      [ "$has" = 1 ] || fail 11 "$CMD_DIR/$y$CMD_SUFFIX:$ln offers $qual$x with no <merge-clause>, and this run writes '$needt' -- the artifact $qual$x's require-on-main gate targets, so that command stops while this phase's pull request is open ($REF_DIR/next-phase-offer.md owns the placeholder and its resolution table)"
    done <<<"$offers"
  done < <(cmd_names "$p")

  # Coverage assertions. Both states mean the check has gone quiet rather than clean, and a
  # gate that has stopped being able to fail must turn the build red, not green.
  [ "$route_n" -gt 0 ] || fail 11 "next-phase-offer.md binds the <merge-clause> rule to '$qual$glob', which matches no command in $CMD_DIR/ -- the family was renamed or retired and this check now examines nothing"
  [ "$req_n" -gt 0 ] || fail 11 "no offer in the '$glob' family names a command whose require-on-main target that offer's own run writes -- either the route stopped handing off to itself or the EXTRACTOR drifted; fix the parser, never the offers"
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
  expect_pass_after() { # <description> <mutation-shell> -- like expect_fail, but the
    # mutation must still leave every check passing. expect_fail alone cannot prove a
    # new number word maps to the right value: an unrecognized word already fails check
    # 9 (no count sentence found), so a mutation that merely stays red proves nothing
    # about which word landed. This proves the word is both matched AND converted correctly.
    tmp=$(mktemp -d); cp -R "$fixture/." "$tmp/"
    ( cd "$tmp" && eval "$2" )
    if "$0" --root "$tmp" >/dev/null 2>&1; then printf 'ok    %s\n' "$1"
    else printf 'FAIL  %s: expected exit 0\n' "$1"; rc=1; fi
    rm -rf "$tmp"
  }
  expect_fail() { # <description> <check-number> <mutation-shell>
    tmp=$(mktemp -d); cp -R "$fixture/." "$tmp/"
    ( cd "$tmp" && eval "$3" )
    local out; out=$("$0" --root "$tmp" 2>&1); local got=$?
    # The colon is load-bearing: fail() prints "FAIL check <n>: <message>", and without it
    # "FAIL check 1" would also match a "FAIL check 10" line, letting a check-10 failure
    # satisfy a check-1 case. Every check number past 9 makes that collision reachable.
    if [ "$got" -eq 1 ] && grep -q "FAIL check $2:" <<<"$out"; then
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
  # ${CLI_VERBS##*|} is the LAST verb in the alternation -- every edition has one by
  # construction (canonical "reinstall", copilot "update") -- so this is extracted by
  # check 7 in every edition, regardless of which verbs exist there. The target names
  # a line absent from the root README, so it is extracted AND counts as extra.
  expect_fail "an install line absent from the root README is rejected" 7 "printf '\n$CLI plugin ${CLI_VERBS##*|} ${PLUGIN_REL##*/}@extra-fixture-target\n' >> $PLUGIN_REL/docs/getting-started.md"
  expect_fail "a drifted prose count is rejected"              9 "mkdir -p $(dirname $(cmd_file $PLUGIN_REL gamma)) 2>/dev/null; printf -- '---\nname: gamma\n---\n' > $(cmd_file $PLUGIN_REL gamma) && printf -- '# /gamma\n\nPage.\n' > $PLUGIN_REL/docs/$DOC_CMD_DIR/gamma.md && sed -i.bak 's|($DOC_CMD_DIR/alpha.md)|($DOC_CMD_DIR/alpha.md), [\`/gamma\`]($DOC_CMD_DIR/gamma.md)|' $PLUGIN_REL/docs/README.md"
  # The five cases below read the fixture's COMMAND count, and that count moved 1 -> 2 when
  # check 11's per-command coverage assertion needed a second command in the offer family to be
  # provable against (with one family member, emptying its writer set also empties the run-wide
  # one, so the fixture could not tell the two assertions apart). Every assertion is unchanged;
  # only the numerals and the how-many-to-add loops track the new base: the compound-count case
  # still claims a compound whose tail is a mapped word equal to the real total (twenty-six over
  # 2+4, where it was twenty-five over 1+4), and the two fixture-growing cases still land on
  # exactly seventeen and eighteen commands by adding one fewer each.
  expect_fail "a count sentence reworded away is rejected"     9 "sed -i.bak 's|two slash commands|a handful of slash commands|' $PLUGIN_REL/README.md"
  expect_fail "a compound count whose tail matches a shorter number word is rejected" 9 \
    "mkdir -p $(dirname $(cmd_file $PLUGIN_REL delta)) 2>/dev/null && printf -- '---\nname: delta\n---\n' > $(cmd_file $PLUGIN_REL delta) && printf -- '# /delta\n\nPage.\n' > $PLUGIN_REL/docs/$DOC_CMD_DIR/delta.md && sed -i.bak 's|($DOC_CMD_DIR/alpha.md)|($DOC_CMD_DIR/alpha.md), [\`/delta\`]($DOC_CMD_DIR/delta.md)|' $PLUGIN_REL/docs/README.md && mkdir -p $(dirname $(cmd_file $PLUGIN_REL epsilon)) 2>/dev/null && printf -- '---\nname: epsilon\n---\n' > $(cmd_file $PLUGIN_REL epsilon) && printf -- '# /epsilon\n\nPage.\n' > $PLUGIN_REL/docs/$DOC_CMD_DIR/epsilon.md && sed -i.bak 's|($DOC_CMD_DIR/alpha.md)|($DOC_CMD_DIR/alpha.md), [\`/epsilon\`]($DOC_CMD_DIR/epsilon.md)|' $PLUGIN_REL/docs/README.md && mkdir -p $(dirname $(cmd_file $PLUGIN_REL zeta)) 2>/dev/null && printf -- '---\nname: zeta\n---\n' > $(cmd_file $PLUGIN_REL zeta) && printf -- '# /zeta\n\nPage.\n' > $PLUGIN_REL/docs/$DOC_CMD_DIR/zeta.md && sed -i.bak 's|($DOC_CMD_DIR/alpha.md)|($DOC_CMD_DIR/alpha.md), [\`/zeta\`]($DOC_CMD_DIR/zeta.md)|' $PLUGIN_REL/docs/README.md && mkdir -p $(dirname $(cmd_file $PLUGIN_REL eta)) 2>/dev/null && printf -- '---\nname: eta\n---\n' > $(cmd_file $PLUGIN_REL eta) && printf -- '# /eta\n\nPage.\n' > $PLUGIN_REL/docs/$DOC_CMD_DIR/eta.md && sed -i.bak 's|($DOC_CMD_DIR/alpha.md)|($DOC_CMD_DIR/alpha.md), [\`/eta\`]($DOC_CMD_DIR/eta.md)|' $PLUGIN_REL/docs/README.md && sed -i.bak2 's|two slash commands|twenty-six slash commands|' $PLUGIN_REL/README.md"
  # Discriminates the word-boundary anchor on the reference-files alternation specifically: the
  # fixture ships 8 reference files, so an unanchored "eight" matches the tail of "twenty-eight"
  # and compares 8 against 8 -- a wrong claim passing on a coincidentally-correct numeral.
  # Anchored, nothing matches at a boundary and the count sentence reads as drifted away. Verified
  # red (this case FAILs) with the anchor stashed, green with it applied. The numerals track the
  # fixture: it shipped 6 reference files (and this case read "twenty-six") until check 11's
  # route fixture added next-phase-offer.md and phase-handoff.md. The assertion is unchanged --
  # a compound whose tail is a mapped word equal to the real count -- and "twenty-eight" is
  # unmapped by _word2num for the same reason "twenty-six" was.
  expect_fail "a compound reference-file count whose tail matches a shorter number word is rejected" 9 \
    "sed -i.bak 's|ships 8 files|ships twenty-eight files|' $PLUGIN_REL/docs/reference/references.md"
  # Proves _word2num and the commands alternation actually learned "seventeen" -- not merely
  # that an unrecognized word is rejected (every unmapped word already fails check 9 via "no
  # count sentence found", which would make a same-shaped expect_fail case pass whether or not
  # "seventeen" was ever added). Grows the fixture to 17 real, fully-inventoried commands and
  # re-words the count sentence to match, so the WHOLE gate -- not just check 9 -- must pass.
  # Verified red (this case FAILs: "no count sentence found") with the word2num/alternation
  # additions stashed, green with them applied.
  expect_pass_after "a correctly-worded seventeen-command count is accepted" \
    "for n in cmd01 cmd02 cmd03 cmd04 cmd05 cmd06 cmd07 cmd08 cmd09 cmd10 cmd11 cmd12 cmd13 cmd14 cmd15; do mkdir -p \$(dirname \$(cmd_file $PLUGIN_REL \$n)) 2>/dev/null; printf -- '---\nname: %s\n---\n' \$n > \$(cmd_file $PLUGIN_REL \$n); printf -- '# /%s\n\nPage.\n' \$n > $PLUGIN_REL/docs/$DOC_CMD_DIR/\$n.md; printf -- '\n- [%s](%s/%s.md)\n' \$n $DOC_CMD_DIR \$n >> $PLUGIN_REL/docs/README.md; done && sed -i.bak 's|two slash commands|seventeen slash commands|' $PLUGIN_REL/README.md"
  # The same proof for the OTHER gated alternation. The case above exercises the commands
  # alternation only; the cost-emitting-commands alternation in check 9 has its own word list,
  # and until this case existed nothing exercised it -- a word missing from it would have failed
  # only on a real release, which is the failure mode the whole selftest exists to move forward
  # in time. Grows the fixture to eighteen real, fully-inventoried commands, seventeen of which
  # emit a cost entry with a matching section-7 row, and re-words BOTH count sentences. The two
  # numbers deliberately differ: "eighteen" is read out of the commands alternation and
  # "seventeen" out of the cost-emitting one, so a word missing from either is attributable.
  # Verified red (this case FAILs: check 9 "cost-emitting commands: no count sentence found")
  # with the six words stashed out of the cost-emitting alternation alone, green with them
  # applied -- and the seventeen-command case above stays green throughout, which is what shows
  # the two cases cover different alternations.
  expect_pass_after "a correctly-worded seventeen cost-emitting-command count is accepted" \
    "for n in bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec; do mkdir -p \$(dirname \$(cmd_file $PLUGIN_REL \$n)) 2>/dev/null; printf -- '---\nname: %s\n---\n' \$n > \$(cmd_file $PLUGIN_REL \$n); printf -- '# /%s\n\nPage.\n' \$n > $PLUGIN_REL/docs/$DOC_CMD_DIR/\$n.md; printf -- '\n- [%s](%s/%s.md)\n' \$n $DOC_CMD_DIR \$n >> $PLUGIN_REL/docs/README.md; done && for n in bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec; do printf -- '\nCall \`emit-cost\` with \`command: /%s\`, \`phase: fixture-phase\`, \`role: pm\`, done.\n' \$n >> \$(cmd_file $PLUGIN_REL \$n); done && { printf -- '# Cost emission (fixture)\n\n## 7. Attribution (phase / role)\n\n| Command | phase | role |\n|---------|-------|------|\n| \`/alpha\` | fixture-phase | pm |\n'; for n in bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec; do printf -- '| \`/%s\` | fixture-phase | pm |\n' \$n; done; printf -- '\n## 8. Persistence\n\nNot modelled in the fixture.\n'; } > $PLUGIN_REL/$REF_DIR/cost-emission.md && sed -i.bak 's|two slash commands|eighteen slash commands|' $PLUGIN_REL/README.md && sed -i.bak 's|One commands emit a cost entry|Seventeen commands emit a cost entry|' $PLUGIN_REL/docs/reference/session-cost.md"
  expect_fail "a wrong non-ASCII anchor is rejected"           2 "printf '\n[bad](#uber-config)\n' >> $PLUGIN_REL/docs/$DOC_CMD_DIR/alpha.md"
  expect_fail "a wrong duplicate-heading index is rejected"    2 "printf '\n[bad](#notes-2)\n' >> $PLUGIN_REL/docs/$DOC_CMD_DIR/alpha.md"
  expect_fail "a titled link to a missing file is rejected"    1 "printf '\n[bad](nope.md \"T\")\n' >> $PLUGIN_REL/docs/$DOC_CMD_DIR/alpha.md"
  expect_fail "an angle-bracket link to a missing file is rejected" 1 "printf '\n[bad](<nope.md>)\n' >> $PLUGIN_REL/docs/$DOC_CMD_DIR/alpha.md"
  expect_fail "an over-long INDENTED table cell is rejected"   6 "awk 'BEGIN{s=\"\"; while(length(s)<260) s=s \"q\"; printf \"\n  | a | %s |\n  |---|---|\n\", s}' >> $PLUGIN_REL/docs/reference/agents.md"
  expect_fail "a missing marketplace-add line is rejected"     7 "sed -i.bak '/$CLI plugin marketplace add/d' $PLUGIN_REL/docs/getting-started.md"
  expect_fail "a missing second required-verb line is rejected" 7 "sed -i.bak '/$CLI plugin ${CLI_REQUIRED##*|}/d' $PLUGIN_REL/docs/getting-started.md"
  expect_fail "getting-started not installing the plugin itself is rejected" 7 "sed -i.bak '/$CLI plugin install ${PLUGIN_REL##*/}@/d' $PLUGIN_REL/docs/getting-started.md"
  # Check 10 -- identity quarantine. Both mutations derive the offending token from the
  # fixture's own repo-root README, so the cases port to a fixture with a different
  # marketplace name rather than pinning this one.
  expect_fail "a container-repo URL on a docs page is rejected" 10 \
    "slug=\$(grep -oE '^$CLI plugin marketplace add [^ ]+' README.md | awk '{print \$NF}' | head -1); printf -- '\n[sibling plugin](https://github.com/%s/tree/main/plugins/extra-plugin)\n' \"\$slug\" >> $PLUGIN_REL/docs/reference/hooks.md"
  expect_fail "a marketplace name on a docs page is rejected" 10 \
    "mkt=\$(grep -oE '^$CLI plugin install [^ ]+@[^ ]+' README.md | sed 's/.*@//' | head -1); printf -- '\nInstall the sibling with \`$CLI plugin install extra-plugin@%s\`.\n' \"\$mkt\" >> $PLUGIN_REL/docs/reference/agents.md"
  # ...and the boundary itself, which is the half an expect_fail case cannot prove: a LONGER
  # identifier that merely contains the marketplace name is not naming it, and must stay green.
  # Under the substring match this replaced, this case goes red -- which is what a fork that
  # names its marketplace `workflows` met on every page saying `dev-workflows` (38 failures on
  # unmodified, correct pages, measured). Verified red before / green after by stashing the
  # boundary anchors.
  expect_pass_after "a longer identifier merely containing the marketplace name is accepted" \
    "mkt=\$(grep -oE '^$CLI plugin install [^ ]+@[^ ]+' README.md | sed 's/.*@//' | head -1); printf -- '\nThe mirror repository is called sub-%s-mirror and is not this marketplace.\n' \"\$mkt\" >> $PLUGIN_REL/docs/reference/agents.md"

  # ...and the vacuity guard: with no install block to derive from, check 10 has no token
  # set and must go RED rather than pass every page. (Check 7 fires on this mutation too;
  # the case asserts check 10 specifically.)
  expect_fail "an underivable identity token set is rejected" 10 \
    "sed -i.bak '/^$CLI plugin /d' README.md"

  # Check 11 -- merge-clause adoption. The fixture's route is one command (`alpha`, matched by
  # the `alpha*` family glob next-phase-offer.md declares) offering `/dev-workflows:omega`,
  # whose row-F entry gates `alpha-deliverable.md` -- which alpha's own `deliverable_paths`
  # declares. That is one clause-requiring offer; the live tree has eight.
  expect_fail "an offer that drops <merge-clause> is rejected" 11 \
    "sed -i.bak 's| <merge-clause>||' $(cmd_file $PLUGIN_REL alpha)"
  # The PER-COMMAND coverage guard. Rewording one family command's handoff sentence empties its
  # writer set alone, and every offer that command makes stops being checked while the run-wide
  # assertions stay satisfied by the other family commands -- green, and quietly covering less.
  # This mutation is the one a review demonstrated against the live tree on brd-ground.md.
  expect_fail "a family command whose handoff declares no path is rejected" 11 \
    "sed -i.bak 's|\`deliverable_paths\` = |\`deliverable_paths\` lists |' $(cmd_file $PLUGIN_REL alpha)"
  # The three vacuity guards rewrite through a temp file OUTSIDE the reference dir rather than
  # with `sed -i.bak`: a stray `.bak` there is a file `find $REF_DIR -type f` counts, so the
  # mutation would trip check 9's reference-file count too and blur what the case proves.
  # The three vacuity guards. Each leaves the tree otherwise valid and makes the check examine
  # nothing, which must be RED: a gate that has stopped being able to fail proves nothing green.
  expect_fail "a reworded family-scope sentence is rejected" 11 \
    "sed 's|/${PLUGIN_REL##*/}:alpha\*|the family|' $PLUGIN_REL/$REF_DIR/next-phase-offer.md > np.tmp && mv np.tmp $PLUGIN_REL/$REF_DIR/next-phase-offer.md"
  expect_fail "a family glob matching no command is rejected" 11 \
    "sed 's|alpha\*|zulu*|' $PLUGIN_REL/$REF_DIR/next-phase-offer.md > np.tmp && mv np.tmp $PLUGIN_REL/$REF_DIR/next-phase-offer.md"
  expect_fail "a row-F table with no gated artifact is rejected" 11 \
    "sed '/alpha-deliverable.md/d; /alpha-two-out.md/d; /elsewhere.md/d' $PLUGIN_REL/$REF_DIR/phase-handoff.md > ph.tmp && mv ph.tmp $PLUGIN_REL/$REF_DIR/phase-handoff.md"
  # ...and the other half of the assertion: the clause is required only where the offering run
  # writes what the offered command gates. `/dev-workflows:sigma` gates `elsewhere.md`, which no
  # fixture command declares, so a clause-free offer of it is CORRECT and must stay green. Without
  # the writer test -- a check that simply demanded the placeholder on every offer -- this case
  # goes red. Verified red before / green after by stashing the writer test.
  expect_pass_after "a clause-free offer of a command this run does not feed is accepted" \
    "printf -- '\nchoices: [\"Hand to the ungated consumer — /${PLUGIN_REL##*/}:sigma <KEY>\", \"Stop here\"]\n' >> $(cmd_file $PLUGIN_REL alpha)"

  # Check 12 -- one case per failure mode, plus the bracket-matching case that is the whole
  # reason this check parses rather than regexes. A naive non-greedy `\[(.*?)\]` stops at the
  # `]` inside the option text and skips the array entirely, so an over-long array hidden
  # behind one would pass. That is not hypothetical: the census that motivated check 12 used
  # the naive form and missed three live arrays, two of them six-option.
  expect_fail "a five-option choices array is rejected" 12 \
    "printf -- '\nchoices: [\"One\", \"Two\", \"Three\", \"Four\", \"Five\"]\n' >> $(cmd_file $PLUGIN_REL alpha)"
  expect_fail "a one-option choices array is rejected" 12 \
    "printf -- '\nchoices: [\"Only one\"]\n' >> $(cmd_file $PLUGIN_REL alpha)"
  expect_fail "an authored Other option is rejected" 12 \
    "printf -- '\nchoices: [\"One\", \"Two\", \"Other… (describe)\"]\n' >> $(cmd_file $PLUGIN_REL alpha)"
  expect_fail "an over-long array whose option text contains brackets is rejected" 12 \
    "printf -- '\nchoices: [\"Use <dir> [+ <sub>]\", \"Two\", \"Three\", \"Four\", \"Five\"]\n' >> $(cmd_file $PLUGIN_REL alpha)"
  # ...and the matching green case: a LEGAL array whose option text contains brackets must not
  # be flagged. Together with the case above this proves the parser reads such arrays rather
  # than skipping them -- a skipping parser passes this one and the one above for the same
  # wrong reason.
  expect_pass_after "a four-option array whose option text contains brackets is accepted" \
    "printf -- '\nchoices: [\"Use <dir> [+ <sub>]\", \"Two\", \"Three\", \"Four\"]\n' >> $(cmd_file $PLUGIN_REL alpha)"

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

# ------------------------------------------------------------------ check 12
# Every `choices:` array the plugin writes is an AskUserQuestion call, and that
# tool's schema is `minItems: 2, maxItems: 4` with "There should be no 'Other'
# option, that will be provided automatically". A five-option array is not a long
# prompt -- it is a tool call rejected at validation, so the run cannot present it
# at all, while `escalation-rules.md` simultaneously requires the array be shown
# verbatim. That contradiction shipped: a convention stated in nine command files
# ("last choice is always \"Other... (describe)\"") authored 136 duplicate options
# across 30 files and pushed 42 arrays past the cap.
#
# The parser is bracket-matched and quote-aware, NOT a non-greedy regex. A naive
# `choices:\s*\[(.*?)\]` stops at the first `]` -- including one inside an option
# string ("Use <PRD dir> [+ <Epic subdir>]") -- and silently skips that array.
# The census that motivated this check used the naive form and missed three
# arrays, two of them six-option ones. A checker that cannot see the worst
# offenders is worse than none, so this one matches brackets.
#
# CHANGELOG.md is excluded: it quotes retired arrays as history.
#
# What this CANNOT see, stated so nobody mistakes green for safe: an array built
# at runtime from a directory listing -- the Epic picker `/specify`, `/design`
# and `/implement` share -- has no literal options to count. Its cap lives in
# `references/epic-picker.md` (*The cap*) and is held by review, not by this gate.
check_choices_arity() {
  local root="$1" hits
  hits=$(python3 - "$root/$PLUGIN_REL" <<'PYEOF'
import re, sys, io, glob, os
root = sys.argv[1]
START = re.compile(r'choices:\s*\[')
def arrays(text):
    for m in START.finditer(text):
        i = m.end() - 1
        depth = 0; j = i; inq = False; esc = False; opts = []; cur = None
        while j < len(text):
            c = text[j]
            if inq:
                if esc: esc = False; cur.append(c)
                elif c == '\\': esc = True
                elif c == '"': inq = False; opts.append(''.join(cur)); cur = None
                else: cur.append(c)
            else:
                if c == '"': inq = True; cur = []
                elif c == '[': depth += 1
                elif c == ']':
                    depth -= 1
                    if depth == 0:
                        yield (m.start(), opts); break
                elif text[j:j+2] == '\n\n': break
            j += 1
for f in sorted(glob.glob(os.path.join(root, '**', '*.md'), recursive=True)):
    if os.path.basename(f) == 'CHANGELOG.md': continue
    s = io.open(f, encoding='utf-8').read()
    rel = os.path.relpath(f, os.path.dirname(root.rstrip('/')))
    for start, opts in arrays(s):
        if not opts: continue
        n = s[:start].count('\n') + 1
        if len(opts) > 4:
            print("%s:%d has %d options (AskUserQuestion renders at most 4)" % (rel, n, len(opts)))
        if len(opts) < 2:
            print("%s:%d has %d option(s) (AskUserQuestion needs at least 2)" % (rel, n, len(opts)))
        for o in opts:
            if o.strip().lower().startswith('other'):
                print("%s:%d authors its own \"%s\" option (the harness supplies it)" % (rel, n, o[:40]))
PYEOF
)
  [ -n "$hits" ] || return 0
  local h; while IFS= read -r h; do [ -n "$h" ] && fail 12 "$h"; done <<<"$hits"
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
check_identity_quarantine "$ROOT"
check_merge_clause      "$ROOT"
check_choices_arity     "$ROOT"

if [ "$FAILURES" -gt 0 ]; then
  echo "FAIL: $FAILURES problem(s) under $PLUGIN_REL" >&2
  exit 1
fi
echo "PASS: docs are consistent with the plugin under $PLUGIN_REL"
