---
jira_key: PRODUCT-1234
---

# Placeholder-form negative control — this file MUST fail the gate

Every violation below is a *placeholder* dash form, never a numeric one. That is
the whole point of the file: `vi-bad.md` fails on numeric IDs, so it keeps
failing even if the gate's number class is narrowed back to `[N0-9]`. This one
fails ONLY on the placeholder letters, so narrowing the class makes it PASS —
and a negative control that passes is a broken gate, which `--selftest` catches.

The regression this locks in: `[SM-Cx]` shipped green in `vi-reviewer.md` during
the 2026-08-18 conversion and had to be found by hand (2c56b57).

## User Stories

### [US-n]: Lowercase placeholder, bracketed

## Acceptance Criteria

- [AC-x] Lowercase x placeholder, bracketed.
- [AC-X] Uppercase X placeholder, bracketed.

## Success Metrics

- [SM-Cx] Legacy counter-metric with a letter placeholder, bracketed.
- A bare SM-Cx mention in prose.
