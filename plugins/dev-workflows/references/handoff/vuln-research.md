# vuln-research Handoff Format

## Input (orchestrator → vuln-research)

```markdown
## Vuln Research Request
repo: /absolute/path/to/repo
cves:
  - id: CVE-2023-46604
    jira: MGD-2423        # omit if no Jira ticket
  - id: CVE-2024-12345    # bare CVE, no Jira
ecosystem_hint: java      # optional; helps when auto-detection is ambiguous
model_routing:            # optional; if present, echo back in output.
  classification: SIGNIFICANT      # See `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md` for the full model-routing schema.
  # The orchestrator MUST re-invoke this agent under Opus for HIGH-RISK
  # CVEs, and SHOULD re-invoke for SIGNIFICANT CVEs involving a major bump
  # or non-trivial breaking-change surface (per the `/vuln` command Step 0).
  # That re-invocation is the orchestrator's responsibility, not this
  # agent's.
```

## Output (vuln-research → vuln-fixer)

```markdown
## Vuln Research Report

### CVE-2023-46604
status: READY             # READY | NOT_IN_REPO | LOOKUP_FAILED | SKIP_NON_CVE
jira: MGD-2423
description: "Apache ActiveMQ RCE via ClassInfo deserialization"
library: activemq-broker
ecosystem: Maven
vulnerable_range: "<5.15.16"
current_version: "5.15.5"
safe_version: "5.15.16"
files:
  - path: pom.xml
    change: "bump activemq-broker.version from 5.15.5 to 5.15.16"
error: null               # error message if status != READY

### CVE-2024-99999
status: NOT_IN_REPO
library: some-other-lib
error: "Library 'some-other-lib' not detected in repo"
```

**status values:**
- `READY` — research complete, safe to hand off to vuln-fixer
- `NOT_IN_REPO` — library not used in this repo; skip fix
- `LOOKUP_FAILED` — NVD API unavailable or CVE not found
- `SKIP_NON_CVE` — ID was CWE or OWASP, not a CVE
