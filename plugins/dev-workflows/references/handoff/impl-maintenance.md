# impl-maintenance Handoff Format

## Input (impl orchestrator → impl-maintenance)

```markdown
## Implementation Summary
repo: /absolute/path/to/repo
change_type: feature       # feature | bugfix | security | refactor | test-only | docs
description: >
  Added OAuth2 login support with Google and GitHub providers.
  Users can now log in via /auth/oauth/google and /auth/oauth/github.
  Config requires OAUTH_CLIENT_ID and OAUTH_CLIENT_SECRET env vars.
files_changed:
  - path: src/auth/oauth.py
    summary: "New OAuth2 flow; handles token exchange and user profile fetch"
  - path: src/auth/routes.py
    summary: "Added /auth/oauth/<provider> route"
  - path: config/settings.py
    summary: "Added OAUTH_CLIENT_ID, OAUTH_CLIENT_SECRET config keys"
  - path: tests/test_oauth.py
    summary: "New test file covering happy path and token expiry"
kb_context: >
  Used httpx-oauth library. Encountered redirect_uri mismatch issues on localhost;
  resolved by normalising the URI before hashing for state param verification.
model_routing:             # optional; echo in output if present.
  classification: SIGNIFICANT  # See `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` for the full model-routing schema.
```

**change_type guide:**
- `feature` — new user-visible capability → always evaluate docs
- `bugfix` — fixes broken behaviour → skip docs unless the fix changes usage
- `security` / `vulnerability` — CVE or security patch → skip docs
- `refactor` — internal restructuring, same external behaviour → skip docs
- `test-only` — tests added/changed, no prod code change → skip docs
- `docs` — documentation-only change → skip docs (work IS the docs)

## Output (impl-maintenance → impl orchestrator)

Return this exact shape (no preamble, no chatter):

```markdown
## Session Learnings

### Session summary
[1–2 sentences on what was done and the overall outcome]

### Key observations
- [What happened / what was unexpected — one bullet per event]
- ...
- _or_ "No notable events — session followed standard workflow"

### Suggested improvements

#### CLAUDE.md rules
- **Rule**: [proposed rule text, ready to paste]
  **Rationale**: [why this would have helped]
  **Scope**: [project-level CLAUDE.md | global ~/.claude/CLAUDE.md]
- ...
- _or_ "No new rules suggested"

#### Hooks
- **Hook**: [name and trigger (e.g. UserPromptSubmit, PostToolUse:Bash)]
  **Purpose**: [what it would do]
  **Rationale**: [why this would help]
- ...
- _or_ "No new hooks suggested"

#### Reference docs
- **File**: [path, e.g. ${CLAUDE_PLUGIN_ROOT}/references/upgrade/compatibility.md]
  **Change**: [what to add or update]
  **Rationale**: [what was missing that caused the workaround or ambiguity]
- ...
- _or_ "No reference doc gaps found"

#### New agents / skills
- **Agent**: [proposed name and one-line description]
  **Purpose**: [what task it would handle; why it should be reusable]
  **Suggested tools**: [list]
- ...
- _or_ "No new agents suggested"

#### Command workflow improvements
- **Command**: [/implement | /document (direct mode) | /document (Jira mode) | /epics | /vuln | /upgrade | /design | /specify | /release-notes]
  **Section**: [Phase / step reference]
  **Change**: [what to change and why]
- ...
- _or_ "No command improvements suggested"

### Priority
[HIGH — multiple observations point to the same gap | MEDIUM — single clear gap | LOW — minor polish only]
```

This agent is suggest-only — it never writes, edits, or creates a file. The caller (the invoking command) is responsible for acting on any of the suggestions above.
