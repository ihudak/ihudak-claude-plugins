#!/usr/bin/env bash
# Fires on every message submission. Matches the two commands this plugin ships
# that inject context, /document and /release-notes, and routes them:
#   • /document                         → specs context iff the argument is an
#                                         address (e.g. /document PRODUCT-1234);
#                                         free-text / @file → silent (direct-edit
#                                         mode owns its own git hygiene and never
#                                         invokes Opus)
#   • /release-notes                    → $SPECS_PATH + $REPOS_PATH default
#                                         + git branch only if cwd is inside
#                                         a git repo (no model-routing, no full
#                                         status/log, no directory listing). It
#                                         accepts an address or a specs directory.
#   • /docs-profile                     → not matched (no context injected)
#
# emit_specs_context surfaces $SPECS_PATH alongside $REPOS_PATH.
#
# The companion dev-workflows plugin ships a hook of the same name covering the
# four commands it still owns (/implement, /epics, /vuln, /upgrade). A
# UserPromptSubmit hook fires whichever plugin ships it, so both run on every
# prompt; the two regexes are disjoint, so at most one of them ever emits.
#
# Exits immediately (near-zero overhead) if the message doesn't match.
# Always exits 0 — must never block Claude.

# Guard: if python3 is not available, skip silently
command -v python3 &>/dev/null || exit 0

# Read prompt from stdin JSON. Claude Code's UserPromptSubmit payload uses the
# key "prompt"; hookify's rule engine also accepts "user_prompt". Try all three
# known names for robustness across versions.
prompt=$(python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('prompt') or d.get('user_prompt') or d.get('message') or '')
except Exception:
    print('')
" 2>/dev/null) || true

# Require at least one non-whitespace, non-flag argument so bare `/document` or
# `/release-notes --help` doesn't inject noise on every misfire. The first
# capture group holds the command token (e.g. "document", "release-notes").
if [[ ! "$prompt" =~ ^/(document|release-notes)[[:space:]]+[^[:space:]-] ]]; then
    exit 0
fi
cmd="${BASH_REMATCH[1]}"

# --- helpers -------------------------------------------------------------
emit_git_branch_if_repo() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    fi
}

emit_specs_context() {
    echo "=== Auto-injected project context (specs workflow) ==="
    echo "repos_path: ${REPOS_PATH:-/workspace} (default — the command will confirm or ask)"
    if [[ -n "${SPECS_PATH:-}" ]]; then
        echo "SPECS_PATH: $SPECS_PATH"
    else
        echo "SPECS_PATH: (not set — the command will ask)"
    fi
    emit_git_branch_if_repo
}

# --- per-command routing -------------------------------------------------
case "$cmd" in
    document)
        # Mode-aware: an address argument → specs context; free-text / @file → silent
        # (direct-edit mode owns its own git hygiene and never invokes Opus).
        if [[ "$prompt" =~ ^/document[[:space:]]+[A-Z][A-Z0-9]+-[0-9]+ ]]; then
            emit_specs_context
        fi
        ;;
    release-notes)
        # Keyed, specs + repos context.
        emit_specs_context
        ;;
    *)
        # Unreachable given the regex; exit silently if the regex is ever widened.
        exit 0
        ;;
esac

exit 0
