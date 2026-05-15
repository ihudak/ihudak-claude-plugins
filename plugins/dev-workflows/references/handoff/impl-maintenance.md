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
  classification: SIGNIFICANT  # See `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md` for the full model-routing schema.
```

**change_type guide:**
- `feature` — new user-visible capability → always evaluate docs
- `bugfix` — fixes broken behaviour → skip docs unless the fix changes usage
- `security` / `vulnerability` — CVE or security patch → skip docs
- `refactor` — internal restructuring, same external behaviour → skip docs
- `test-only` — tests added/changed, no prod code change → skip docs
- `docs` — documentation-only change → skip docs (work IS the docs)

## Output (impl-maintenance → impl orchestrator)

```markdown
## Maintenance Report

### Knowledge Base
updated: ~/.claude/memory/oauth-patterns.md
summary: "Added entry on redirect_uri normalisation gotcha with httpx-oauth"

### Instructions
no update required

### Documentation
updated: README.md
summary: "Added OAuth2 Setup section with env var table and login URL examples"
```

OR when nothing needed:

```markdown
## Maintenance Report
### Knowledge Base
no update required
### Instructions
no update required
### Documentation
no update required (bugfix / internal / non-visible change)
```
