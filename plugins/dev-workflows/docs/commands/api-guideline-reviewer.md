# /api-guideline-reviewer

Reviews OpenAPI specification files against the bundled REST API and IAM permission-naming guidelines, distilled from public sources (Google AIP, the Zalando and Microsoft REST API guidelines, OpenAPI 3.1, and the relevant RFCs). The review runs in two halves: a **deterministic Spectral lint** against a bundled ruleset, then the LLM passes, scoped to what a linter cannot express.

## Who runs it

`/api-guideline-reviewer` is **standalone**: outside the role pipeline, no role, no cost-attribution phase, and exempt from the [model-routing](../reference/model-routing.md) classification the pipeline commands apply — the command file carries no classification step, no `model_routing` block, and no Opus/Sonnet chain reference. [Workflow overview](../workflow.md#cross-cutting-commands) groups it under Setup and review utilities, alongside [`/guideline-reviewer`](guideline-reviewer.md), its sibling reviewer for app code and UI rather than API specs.

## Synopsis

```
/api-guideline-reviewer <spec-file(s)> [--rules <path>]
```

`$ARGUMENTS` names one or more OpenAPI spec files. Leave it empty and the command asks which file(s) to review before dispatching anything.

## What it needs

- One or more OpenAPI spec file paths.
- Optionally, a Spectral CLI — see [Deterministic lint](#deterministic-lint) below. Without one the review still runs.
- Nothing else — no `$SPECS_PATH`, no `$VAULT_PATH`, no branch, no specs-repo preflight. The command reads the named files and the vendored guideline references, and writes nothing.

## Deterministic lint

Before any LLM pass, the subagent lints each spec file with [Spectral](https://github.com/stoplightio/spectral) against the ruleset bundled at `references/api-guidelines/spectral/ruleset.yaml`. That ruleset extends `spectral:oas` (recommended) and adds forty rules of its own, covering the six areas the guidelines state mechanically: version-field shape, required document elements, naming conventions, IAM scope grammar, HTTP status codes, schema composition, and header hygiene — including the single org-wide tenant-header spelling and the org-wide security-scheme name, which are pinned as literals rather than described in prose.

**Resolution.** The subagent probes `spectral` on `PATH` first, then `npx --no-install @stoplight/spectral-cli`. The first that answers is used. If the spec's own repository carries a `.spectral.yaml`, `.spectral.yml`, or `.spectral.json` at its root, that ruleset is used instead of the bundled one — an organization is expected to *extend* the bundled ruleset in its own file rather than edit the bundled file in place.

**Degradation.** No Spectral CLI is not a failure. The lint is skipped, no prompt is raised, nothing is installed, the run does not fail, and the review proceeds exactly as it did before the ruleset existed — every check the linter would have made reverts to the LLM passes. The same applies when Spectral resolves but errors: an unparseable ruleset, or a run that exceeds roughly two minutes. The verdict records the outcome as `lint_source: none` with a one-clause reason. A non-zero exit code is *not* a failure signal here — Spectral exits non-zero whenever it reports findings, so the subagent judges success by whether it got parseable JSON.

**Merge, not duplication.** Spectral's findings are authoritative for the rules it covers, and the LLM passes do not restate them. Each finding in the verdict is attributed — `spectral:<rule-id>` for a machine-checked one, `review` for a reasoned one.

**What stays with the LLM passes**, whether or not Spectral ran:

| Check | Why a linter cannot make it |
|---|---|
| Version **agreement** | Spectral checks each version field's shape alone; that `info.version`, `servers[].url` and `x-gateway-url` name the *same* major is a cross-field comparison it cannot express. |
| `allOf` property redefinition | Needs the `$ref` resolved and two property sets intersected. |
| Error-envelope conformance | Needs the organization's envelope schema identity. |
| Semantic naming quality | Noun vs verb, singular vs plural, American English, "overly generic" — all judgements. |
| Conditional requirements | Whether `x-gateway-url` or the `deprecated` field is required at all depends on facts outside the document. |
| Resource modelling, documentation adequacy | Decomposition, method choice, whether a description actually informs. |
| IAM scope **correctness** | Spectral checks a scope's grammar; whether its service, resource and action match the URL and HTTP method is a reading of the API. |

## What it produces

The `api-guideline-reviewer` subagent's verdict, printed as-is: a summary carrying the `lint_source` line, then Mistakes (MUST violations), Potential Improvements (SHOULD violations), and what the spec does well — each finding pointing at the offending element and naming whether it came from the linter or the review. A Spectral finding at severity `error` lands under Mistakes; `warn`, `info` and `hint` land under Potential Improvements, which is how the ruleset's own RFC 2119 severity mapping reaches the verdict.

The agent's frontmatter grants `Read`, `Glob`, `Grep`, and `Bash` — `Bash` solely so it can invoke the Spectral CLI. Nothing it finds is auto-fixed by this command.

## Rule overlay

The bundled rules are a **vendor-neutral baseline** distilled from public standards. Rules specific to your organization — an internal scope grammar, a required header spelling, an error-envelope contract — have no public equivalent and deliberately do not ship in a public plugin. Supply them as an **overlay**, resolved in this order, first hit winning (two overlays are never merged):

| Order | Source |
|---|---|
| 1 | `--rules <path>` |
| 2 | `<repo-root>/.dev-workflows/api-guidelines/` |
| 3 | `$$API_GUIDELINES_PATH` |
| 4 | the bundled baseline alone |

An overlay file whose name matches a bundled one layers over it and wins on conflict; a file matching none is an additional rule source; an `## Allowed` section suppresses matching baseline rules; and a file whose first line is `<!-- api-guidelines: replace -->` supersedes its baseline counterpart outright. Every miss falls through **silently** — a missing overlay is the normal case, not a problem. The report's `rules_source:` line records what actually resolved (`baseline`, or `overlay:<path>`).

This is the same mechanism the sibling `prose-style` plugin uses for its own rules, deliberately — one convention, not two.

## Gates

There is no review gate here in the pipeline sense — **this command is the review.** No triage, no fixer, no BLOCK/re-review cycle; the subagent's verdict is the final output. The Spectral lint is a pre-pass, not a gate: it never stops the review, and its absence never does either.

## Example

```
/dev-workflows:api-guideline-reviewer specs/openapi.yaml
```

Lints `specs/openapi.yaml` with the bundled ruleset where a Spectral CLI is available, then dispatches `api-guideline-reviewer` for the passes the linter cannot make, and prints the merged verdict.

## See also

- [`/guideline-reviewer`](guideline-reviewer.md) — the sibling standalone reviewer for app code and UI instead of OpenAPI specs.
- [Model routing](../reference/model-routing.md) — the classification policy this command is exempt from.
- [Workflow overview](../workflow.md#cross-cutting-commands) — where the two standalone reviewers sit relative to the role pipeline.
