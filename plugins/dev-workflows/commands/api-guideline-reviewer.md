---
name: api-guideline-reviewer
description: Review OpenAPI specification files against Dynatrace REST API and IAM permission naming guidelines. Checks version consistency, naming conventions, IAM scope format, HTTP status codes, and schema composition.
allowed-tools: Read Bash Glob Grep WebFetch
---

Review OpenAPI specification files for compliance with Dynatrace REST API and IAM permission naming guidelines: $ARGUMENTS

If `$ARGUMENTS` is empty, ask the user which OpenAPI spec file(s) to review.

Dispatch the review to the `api-guideline-reviewer` subagent:

→ Agent (subagent_type: "dev-workflows:api-guideline-reviewer"):
  > "Review the following OpenAPI spec file(s) against the guidelines: $ARGUMENTS"

Surface the subagent's verdict to the user.
