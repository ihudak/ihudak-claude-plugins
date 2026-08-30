# /guideline-reviewer

Reviews app code and UI against the bundled UI design-system and accessibility guidelines, distilled from public standards (Apple HIG, Material Design 3, Microsoft Fluent 2, W3C WCAG 2.2 and the ARIA Authoring Practices Guide).

Accessibility findings are reported in a machine-checkable vocabulary: each rule in the bundled accessibility guideline that has one cites an axe-core `ruleId` and the W3C ACT rule id it maps to, alongside the WCAG success criterion. Before its review passes, the subagent also detects and wraps whatever accessibility tooling the target repo already configures — see [Deterministic accessibility check](#deterministic-accessibility-check).

## Who runs it

`/guideline-reviewer` is **standalone**: outside the role pipeline, no role, no cost-attribution phase, and exempt from the [model-routing](../reference/model-routing.md) classification the pipeline commands apply — the command file carries no classification step, no `model_routing` block, and no Opus/Sonnet chain reference. [Workflow overview](../workflow.md#cross-cutting-commands) groups it under Setup and review utilities, alongside [`/api-guideline-reviewer`](api-guideline-reviewer.md), its sibling reviewer for OpenAPI specs rather than app code and UI.

## Synopsis

```
/guideline-reviewer <files-or-components> [--rules <path>]
```

`$ARGUMENTS` names the files or components to review. Leave it empty and the command asks which ones before dispatching anything.

## What it needs

- One or more file or component paths (or a description of what to review).
- Nothing else — no `$SPECS_PATH`, no `$VAULT_PATH`, no branch, no specs-repo preflight.

The accessibility tooling below is **optional**. Nothing is installed, and a repo that configures none of it is reviewed exactly as it was before the step existed.

## What it produces

The `guideline-reviewer` subagent's verdict against the mandatory design-system and accessibility standards: app header, data table, filter field, connections, permissions, settings, dashboards, accessibility/WCAG, terminology, and data-naming findings, each pointing at the offending file or element. The report opens with the deterministic check's `a11y_check` value (and the exact command it ran, or `null` when nothing did); accessibility findings additionally cite their axe `ruleId` and W3C ACT id where one exists, and are tagged `source: linter` or `source: review`. Its frontmatter grants `Bash` alongside `Read`, `Glob`, and `Grep` — but the command itself still writes nothing and applies no fix.

## Deterministic accessibility check

Runs **before** the subagent's review passes, and wraps the target repo's own configuration rather than re-encoding a rule set — the same reasoning the [`docs-style-checker`](../reference/agents.md) agent applies to a docs repo's Vale. Detection is read-only and follows a fixed order; the first match sets the reported `a11y_check` value.

| Order | Detected | What happens | `a11y_check` |
|---|---|---|---|
| 1 | `eslint-plugin-jsx-a11y` in `package.json` or an ESLint config | The repo's own lint runs, scoped to the files under review; `jsx-a11y/*` messages become findings | `eslint-jsx-a11y` |
| 2 | `jest-axe`, `cypress-axe`, `@axe-core/playwright`, or `@axe-core/cli` in `package.json` | Recorded only — **not run**. The report names the axe rule ids the repo's own suite could confirm | `harness-detected:<name>` |
| 3 | Neither | Silent skip; the review proceeds unchanged | `none` |

**What does not run, and why.** axe-core needs a rendered DOM, so it cannot be pointed at source files, and a review has no rendered app to hand a runtime harness. Only branch 1 executes anything: `eslint-plugin-jsx-a11y` is the one accessibility rule set that checks source. Branch 2 records the harness and says plainly that it did not run it — the axe and ACT ids elsewhere in the report are a **vocabulary for naming findings**, never evidence that axe executed.

**Merged, not duplicated.** A finding branch 1's linter reported deterministically is not re-raised by the review pass as a second finding; same file, same line, same underlying rule keeps the linter's version, with its rule id and the repo's own configured severity. Findings carry a `source: linter | review` tag so the two are distinguishable.

**Never blocking.** Missing tooling, a missing binary, unparseable lint output, or a timeout all degrade to a recorded value and a review that continues. The step never installs a package, never starts a server or a test run, never prompts, and never fails the command.

## Rule overlay

The bundled rules are a **vendor-neutral baseline** distilled from public standards. Rules specific to your organization — a proprietary design system's component contract, internal terminology — have no public equivalent and deliberately do not ship in a public plugin. Supply them as an **overlay**, resolved in this order, first hit winning (two overlays are never merged):

| Order | Source |
|---|---|
| 1 | `--rules <path>` |
| 2 | `<repo-root>/.dev-workflows/ui-guidelines/` |
| 3 | `$$UI_GUIDELINES_PATH` |
| 4 | the bundled baseline alone |

An overlay file whose name matches a bundled one layers over it and wins on conflict; a file matching none is an additional rule source; an `## Allowed` section suppresses matching baseline rules; and a file whose first line is `<!-- ui-guidelines: replace -->` supersedes its baseline counterpart outright. Every miss falls through **silently** — a missing overlay is the normal case, not a problem. The report's `rules_source:` line records what actually resolved (`baseline`, or `overlay:<path>`).

This is the same mechanism the sibling `prose-style` plugin uses for its own rules, deliberately — one convention, not two.

## Gates

There is no review gate here in the pipeline sense — **this command is the review.** No triage, no fixer, no BLOCK/re-review cycle; the subagent's verdict is the final output.

## Example

```
/dev-workflows:guideline-reviewer app/src/pages/SettingsPage.tsx
```

Dispatches `guideline-reviewer` against the named file and prints its verdict against the guideline checklist.

## See also

- [`/api-guideline-reviewer`](api-guideline-reviewer.md) — the sibling standalone reviewer for OpenAPI specs instead of app code and UI.
- [Model routing](../reference/model-routing.md) — the classification policy this command is exempt from.
- [Workflow overview](../workflow.md#cross-cutting-commands) — where the two standalone reviewers sit relative to the role pipeline.
