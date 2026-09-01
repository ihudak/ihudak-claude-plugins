#!/usr/bin/env bash
# Fails when a tracked plugin doc teaches the dash-form requirement-ID grammar.
# Spec: docs/superpowers/specs/2026-08-18-jira-safe-requirement-ids-design.md
set -uo pipefail

# --selftest runs the gate against its own fixtures and asserts, per fixture, the
# exit code AND every form the gate must have named. Without it the fixtures are
# decorative: CI only ever ran `--root .`, so nothing proved the gate could still
# FAIL. A check that cannot be shown to fail proves nothing when it passes.
#
# THE EXIT CODE ALONE IS NOT ENOUGH, and this was proven, not assumed. Each negative
# fixture carries several violating lines, so ANY surviving alternation of PATTERN
# holds the exit code at 1: a review deleted both `SM-C` alternations and watched
# `--selftest` print SELFTEST PASS, then watched the degraded gate accept a live
# `[SM-C1]` in a shipped reference file. The sibling gate's selftest had asserted
# WHICH check fired since the day it was written, for exactly this reason. So every
# negative case here also asserts the forms in the gate's own output, one grep per
# form, which is what makes an alternation impossible to delete quietly.
if [ "${1:-}" = "--selftest" ]; then
  here=$(cd "$(dirname "$0")" && pwd)
  rc=0
  expect() { # <description> <expected-exit> <root> [<form-that-must-be-reported>...]
    local desc="$1" want="$2" root="$3"; shift 3
    local out got form missing=""
    out=$("$0" --root "$root" 2>&1); got=$?
    for form in "$@"; do
      grep -qF -- "$form" <<<"$out" || missing="$missing $form"
    done
    if [ "$got" -eq "$want" ] && [ -z "$missing" ]; then
      printf 'ok    %s (exit %s%s)\n' "$desc" "$got" "$([ $# -gt 0 ] && printf ', %s forms named' "$#")"
    elif [ "$got" -ne "$want" ]; then
      printf 'FAIL  %s: expected exit %s, got %s\n' "$desc" "$want" "$got"; rc=1
    else
      printf 'FAIL  %s: exit %s was right, but the gate never named:%s -- an alternation of PATTERN has stopped matching\n' "$desc" "$got" "$missing"; rc=1
    fi
  }
  # The form lists are the whole point: each one pins one alternation of PATTERN.
  # Bracketed and bare are separate branches of the regex and are asserted separately.
  expect "numeric dash forms are rejected"      1 "$here/fixtures/prd-bad.md" \
         "[US-1]" "[AC-1]" "[AC-2]" "[SM-1]"
  expect "placeholder dash forms are rejected"  1 "$here/fixtures/prd-bad-placeholders.md" \
         "[US-n]" "[AC-x]" "[AC-X]" "[SM-Cx]" "bare SM-Cx"
  expect "hash forms and real keys are accepted" 0 "$here/fixtures/prd-good.md"
  expect "a nonexistent root is an error"       2 "$here/fixtures/no-such-file.md"
  if [ "$rc" -eq 0 ]; then
    echo "SELFTEST PASS"
  else
    echo "SELFTEST FAIL"
  fi
  exit "$rc"
fi

ROOT="."
if [ "${1:-}" = "--root" ]; then
  if [ $# -lt 2 ]; then
    echo "Usage: $0 [--root <dir>] | --selftest" >&2
    exit 2
  fi
  ROOT="$2"
fi

if [ ! -e "$ROOT" ] || [ ! -r "$ROOT" ]; then
  echo "ERROR: --root '$ROOT' does not exist or is not readable" >&2
  exit 2
fi

# Requirement-ID prefixes the plugin mints. NOT a general Jira-key check:
# a real key like PRODUCT-123 is legitimate and must never be flagged.
#
# The number class is [NnXx0-9] everywhere, and identical on all four
# alternations. It covers literal numbers plus every placeholder letter these
# docs actually use -- N, n, x and X. Narrowing it has already cost us once:
# the class was [N0-9] when the conversion ran, so `[SM-Cx]` in prd-reviewer.md
# passed the gate green and had to be found and fixed by hand (2c56b57).
# A bracketed `[US-n]` slipped through the same way while the bare `US-n` was
# caught, because the two branches disagreed about lowercase n.
#
# SM-C<N> (e.g. SM-C1) is the legacy counter-metric form; SMC#<N> is its
# hash-form target and is already covered by the shared prefix alternation
# below -- SM-C needs its own alternative because it doesn't fit the
# \[(PREFIX)-[N0-9]+\] shape (the dash sits before the C, not after it).
NUM='[NnXx0-9]'
PATTERN="\[(US|AC|SM|SMC|UC|FR|AD)-${NUM}+\]|\[SM-C${NUM}+\]|(^|[^[:alnum:]_[])(US|AC|SM|SMC|UC|FR|AD)-${NUM}+([^[:alnum:]_]|\$)|(^|[^[:alnum:]_[])SM-C${NUM}+([^[:alnum:]_]|\$)"

# Subtrees that legitimately carry the legacy form, anchored to the SCAN ROOT
# rather than matched by bare directory name. `--exclude-dir=docs` would skip
# any directory called `docs` at any depth -- including a future
# plugins/<name>/docs/ -- which is a silent hole in a gate whose whole job is
# to have no silent holes. `.git` stays a name-match: it is never in scope at
# any depth.
#   docs/            -- this repo's plans and specs, which quote the old form
#   .remember/       -- session history, untracked
#   .superpowers/    -- SDD workspace, untracked
#   scripts/fixtures -- this gate's own negative-control fixtures
EXCLUDED_SUBTREES='^\./(docs|\.remember|\.superpowers|scripts/fixtures)/'

# CHANGELOG.md is history and keeps the dash form (spec Global Constraints).
# A line carrying the marker `id-grammar-ok:` is documenting the legacy form on
# purpose. Sanctioned users -- 5 marked lines across 5 files, in three kinds.
# It was 10 across 6 until the tracker-reading agent holding five reader-tolerance
# lines was deleted; re-derive with grep rather than adjusting the number:
#   * reader tolerance (1): ard-resolution's
#     parse of `## Architecture decisions` -- this ACCEPTS the legacy form;
#   * authoring BLOCKER rules (3): prd-reviewer, ard-reviewer, epic-reviewer --
#     these FORBID it in a file their own command just wrote;
#   * readiness-reviewer's MINOR rule (1) -- it REPORTS the legacy form in an
#     artifact the run did not author, without gating the verdict.
# Each has to quote the legacy form in order to accept, forbid, or report it.
# The per-file breakdown is audited so the marker cannot become a general
# escape hatch.
if [ -d "$ROOT" ]; then
  raw=$( cd "$ROOT" && grep -rnE "$PATTERN" \
          --include='*.md' \
          --exclude='CHANGELOG.md' \
          --exclude-dir='.git' \
          . 2>/dev/null || true )
  raw=$( printf '%s\n' "$raw" | grep -vE "$EXCLUDED_SUBTREES" || true )
else
  raw=$( grep -nE "$PATTERN" "$ROOT" 2>/dev/null || true )
fi

hits=$( printf '%s\n' "$raw" | grep -v 'id-grammar-ok:' | sed '/^$/d' || true )

if [ -n "$hits" ]; then
  echo "FAIL: dash-form requirement IDs found (expected [PREFIX#N]):"
  echo "$hits"
  echo
  echo "Count: $(echo "$hits" | wc -l)"
  exit 1
fi

echo "PASS: no dash-form requirement IDs under $ROOT"
exit 0
