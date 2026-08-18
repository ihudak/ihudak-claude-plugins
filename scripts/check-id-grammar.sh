#!/usr/bin/env bash
# Fails when a tracked plugin doc teaches the dash-form requirement-ID grammar.
# Spec: docs/superpowers/specs/2026-08-18-jira-safe-requirement-ids-design.md
set -uo pipefail

ROOT="."
if [ "${1:-}" = "--root" ]; then
  if [ $# -lt 2 ]; then
    echo "Usage: $0 [--root <dir>]" >&2
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
# SM-C<N> (e.g. SM-C1) is the legacy counter-metric form; SMC#<N> is its
# hash-form target and is already covered by the shared prefix alternation
# below — SM-C needs its own alternative because it doesn't fit the
# \[(PREFIX)-[N0-9]+\] shape (the dash sits before the C, not after it).
PATTERN='\[(US|AC|SM|SMC|UC|FR|AD)-[N0-9]+\]|\[SM-C[N0-9]+\]|(^|[^[:alnum:]_[])(US|AC|SM|SMC|UC|FR|AD)-[Nn0-9]+([^[:alnum:]_]|$)|(^|[^[:alnum:]_[])SM-C[Nn0-9]+([^[:alnum:]_]|$)'

# CHANGELOG.md is history and keeps the dash form (spec Global Constraints).
# A line carrying the marker `id-grammar-ok:` is documenting the legacy form on
# purpose (jira-reader's reader tolerance). Task 8 is the only sanctioned user;
# Task 8 Step 6 audits the total count so it cannot become a general escape hatch.
hits=$(grep -rnE "$PATTERN" \
        --include='*.md' \
        --exclude='CHANGELOG.md' \
        --exclude-dir='.git' \
        --exclude-dir='docs' \
        --exclude-dir='fixtures' \
        "$ROOT" 2>/dev/null \
       | grep -v 'id-grammar-ok:' || true)

if [ -n "$hits" ]; then
  echo "FAIL: dash-form requirement IDs found (expected [PREFIX#N]):"
  echo "$hits"
  echo
  echo "Count: $(echo "$hits" | wc -l)"
  exit 1
fi

echo "PASS: no dash-form requirement IDs under $ROOT"
exit 0
