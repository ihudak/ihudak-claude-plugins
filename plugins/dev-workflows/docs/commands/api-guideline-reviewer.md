# /api-guideline-reviewer

Reviews OpenAPI specification files against the vendored REST API and IAM permission naming guidelines.

## Who runs it

`/api-guideline-reviewer` is **standalone**: outside the role pipeline, no role, no cost-attribution phase, and exempt from the [model-routing](../reference/model-routing.md) classification the pipeline commands apply — the command file carries no classification step, no `model_routing` block, and no Opus/Sonnet chain reference. [Workflow overview](../workflow.md#cross-cutting-commands) groups it under Setup and review utilities, alongside [`/guideline-reviewer`](guideline-reviewer.md), its sibling reviewer for app code and UI rather than API specs.

## Synopsis

```
/api-guideline-reviewer <spec-file(s)>
```

`$ARGUMENTS` names one or more OpenAPI spec files. Leave it empty and the command asks which file(s) to review before dispatching anything.

## What it needs

- One or more OpenAPI spec file paths.
- Nothing else — no `$SPECS_PATH`, no `$VAULT_PATH`, no branch, no specs-repo preflight. The command reads the named files and the vendored guideline references, and writes nothing.

## What it produces

The `api-guideline-reviewer` subagent's verdict, printed as-is: version consistency, required-element and naming-convention checks, IAM scope format, HTTP status codes, and schema-composition findings against the file(s) given, each pointing at the offending element. The agent itself is read-only — its frontmatter grants `Read`, `Glob`, and `Grep`, with no `Bash` — so nothing it finds is auto-fixed by this command.

## Gates

There is no review gate here in the pipeline sense — **this command is the review.** No triage, no fixer, no BLOCK/re-review cycle; the subagent's verdict is the final output.

## Example

```
/dev-workflows:api-guideline-reviewer specs/openapi.yaml
```

Dispatches `api-guideline-reviewer` against `specs/openapi.yaml` and prints its verdict — naming, versioning, IAM-scope, status-code, and schema-composition findings.

## See also

- [`/guideline-reviewer`](guideline-reviewer.md) — the sibling standalone reviewer for app code and UI instead of OpenAPI specs; unlike this command's agent, its agent's frontmatter also grants `Bash`.
- [Model routing](../reference/model-routing.md) — the classification policy this command is exempt from.
- [Workflow overview](../workflow.md#cross-cutting-commands) — where the two standalone reviewers sit relative to the role pipeline.
