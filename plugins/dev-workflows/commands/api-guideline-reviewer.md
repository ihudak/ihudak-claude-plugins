---
name: api-guideline-reviewer
description: Review OpenAPI specification files against REST API and IAM permission-naming guidelines. Runs a deterministic Spectral lint first where a Spectral CLI is available, then reviews what a linter cannot express. Checks version consistency, naming conventions, IAM scope format, HTTP status codes, and schema composition.
allowed-tools: Read Bash Glob Grep WebFetch
---

Review OpenAPI specification files for compliance with REST API and IAM permission-naming guidelines: $ARGUMENTS

**`--rules <path>`** (optional) — an organization's own API rule directory, layered over the bundled baseline. Set it aside from `$ARGUMENTS` before resolving the spec files, and pass it to the agent as `rules_path`. Absent, the agent resolves an overlay itself from `<repo-root>/.dev-workflows/api-guidelines/` then `$API_GUIDELINES_PATH`, falling back silently to the bundled baseline. The executable half has its own precedence: a repo's own `.spectral.yaml` wins over the bundled Spectral ruleset, which organizations are expected to `extend` rather than edit.

If `$ARGUMENTS` is empty, ask the user which OpenAPI spec file(s) to review.

Dispatch the review to the `api-guideline-reviewer` subagent:

→ Agent (subagent_type: "dev-workflows:api-guideline-reviewer"):
  > "Review the following OpenAPI spec file(s) against the guidelines: $ARGUMENTS"

Surface the subagent's verdict to the user.

## Deterministic lint

Before its LLM review passes, the subagent runs a **Spectral** lint of each spec file against the ruleset bundled with this plugin at `references/api-guidelines/spectral/ruleset.yaml` — forty rules that make the machine-checkable half of the guidelines executable, on top of `spectral:oas` (recommended). Where the spec's own repository carries a `.spectral.yaml` at its root, that file is used instead, on the assumption that an organization extends the bundled ruleset rather than editing it in place.

Two things follow, and both belong to the subagent — this command neither runs the linter nor post-processes its output:

- **A missing Spectral CLI is not a failure.** The subagent probes `spectral` on PATH, then `npx --no-install @stoplight/spectral-cli`. If neither answers, the lint is skipped silently, the review proceeds exactly as it does without it, and the skip is recorded as `lint_source: none` in the verdict. Nothing is installed, nothing is prompted, and the run never fails on the linter's absence.
- **Findings are merged, not duplicated.** Spectral's findings are authoritative for the rules it covers; the LLM passes cover what Spectral cannot express — cross-field version *agreement*, `allOf` property redefinition, error-envelope conformance, semantic naming quality, resource modelling and documentation adequacy, and whether an IAM scope is *correct* rather than merely well-formed.

Surface the `lint_source` line with the rest of the verdict, so the reader can tell which half of the review was machine-checked.
