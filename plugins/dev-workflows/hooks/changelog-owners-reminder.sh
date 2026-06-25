#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): warn-only reminder for dynatrace-docs
# frontmatter conventions (changelog entry on change; managed-docs owners).
# Delegates to the Python logic, passing the payload through on stdin.
# Always exits 0 — must never block Claude.

command -v python3 &>/dev/null || exit 0

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CLAUDE_PLUGIN_ROOT="$ROOT" python3 "$ROOT/hooks/changelog-owners-reminder.py" || true

exit 0
