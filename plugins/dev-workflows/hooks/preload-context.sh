#!/usr/bin/env bash
# Fires on every message submission. Matches /impl, /impl:code, /impl:docs,
# /impl:jira:docs, /impl:jira:epics, /vuln, /upgrade and routes per spec §3:
#   • /impl:code, /vuln, /upgrade       → full (model-routing + git status +
#                                         recent commits + small-repo directory listing)
#   • /impl:jira:docs, /impl:jira:epics → $VAULT_PATH + <repos_base> default
#                                         + git branch only if cwd is inside
#                                         a git repo (no model-routing,
#                                         no full status/log, no directory listing)
#   • /impl                             → silent (dispatcher / help-only; as of 1.1.0
#                                         /impl does not execute any workflow)
#   • /impl:docs                        → silent (user manages git manually;
#                                         model-routing not triggered)
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

# Require at least one non-whitespace, non-flag argument so bare `/impl` or
# `/impl --help` doesn't inject noise on every misfire. The first capture group
# holds the full command token (e.g. "impl", "impl:code", "impl:jira:docs") —
# see spec §3 "Hook scope" for the normative regex.
if [[ ! "$prompt" =~ ^/(impl(:(code|docs|jira(:(docs|epics))?))?|vuln|upgrade)[[:space:]]+[^[:space:]-] ]]; then
    exit 0
fi
cmd="${BASH_REMATCH[1]}"

# --- helpers -------------------------------------------------------------
emit_model_routing() {
    echo "Model routing: classify task as SIMPLE / MODERATE / SIGNIFICANT / HIGH-RISK before planning."
    echo "  SIGNIFICANT / HIGH-RISK -> plan with risk-planner (Opus), code-review (Opus)"
    echo "  BEFORE running tests. Invoke via Agent(subagent_type: general-purpose,"
    echo "  model: opus) + prompt to read the plugin-installed agents/<name>.md."
    echo "  Full rules: ~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md"
}

emit_git_full() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
        echo "Status:"
        git status --short 2>/dev/null | head -20
        echo "Recent commits:"
        git log --oneline -5 2>/dev/null
    else
        echo "(not a git repository)"
    fi
}

emit_git_branch_if_repo() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    fi
}

emit_dir_listing_if_small() {
    local entry_count
    entry_count=$(ls -1 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$entry_count" -le 30 ]]; then
        echo "Directory:"
        ls -1 2>/dev/null | head -20
    fi
}

# --- per-command routing (spec §3 table) ---------------------------------
case "$cmd" in
    impl|impl:docs)
        # Silent:
        #   • /impl      — dispatcher (help-only); injected context would be noise.
        #   • /impl:docs — owns its own git hygiene and never invokes Opus.
        exit 0
        ;;
    impl:jira*)
        # /impl:jira:docs and /impl:jira:epics. Catches bare /impl:jira too
        # (the regex allows it as a spec-intentional over-match) — handled
        # identically since any path into the :jira branch needs the same
        # vault/repos_base context.
        echo "=== Auto-injected project context (Jira workflow) ==="
        if [[ -n "${VAULT_PATH:-}" ]]; then
            echo "VAULT_PATH: $VAULT_PATH"
        else
            echo "VAULT_PATH: (not set — the command will ask in Phase 1)"
        fi
        echo "repos_base: ${REPOS_BASE:-/repos} (default — the command will confirm or ask)"
        emit_git_branch_if_repo
        ;;
    impl:code|vuln|upgrade)
        # Full — code / security / upgrade commands benefit from the full
        # git context plus the model-routing reminder.
        echo "=== Auto-injected project context ==="
        emit_model_routing
        emit_git_full
        emit_dir_listing_if_small
        ;;
    *)
        # Unreachable given the regex above; exit silently if the regex
        # is ever widened without updating this switch.
        exit 0
        ;;
esac

exit 0
