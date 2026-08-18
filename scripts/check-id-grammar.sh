#!/usr/bin/env bash
# Fails when a tracked plugin doc teaches the dash-form requirement-ID grammar.
# Spec: docs/superpowers/specs/2026-08-18-jira-safe-requirement-ids-design.md
set -uo pipefail

ROOT="."
[ "${1:-}" = "--root" ] && ROOT="$2"

# Requirement-ID prefixes the plugin mints. NOT a general Jira-key check:
# a real key like PRODUCT-123 is legitimate and must never be flagged.
PATTERN='\[(US|AC|SM|SMC|UC|FR|AD)-[N0-9]+\]|(^|[^[:alnum:]_[])(US|AC|SM|SMC|UC|FR|AD)-[Nn0-9]+([^[:alnum:]_]|$)'

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
