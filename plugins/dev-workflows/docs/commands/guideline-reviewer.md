# /guideline-reviewer

Reviews app code and UI against the bundled UI design-system and accessibility guidelines, distilled from public standards (Apple HIG, Material Design 3, Microsoft Fluent 2, W3C WCAG 2.2 and the ARIA Authoring Practices Guide).

## Who runs it

`/guideline-reviewer` is **standalone**: outside the role pipeline, no role, no cost-attribution phase, and exempt from the [model-routing](../reference/model-routing.md) classification the pipeline commands apply — the command file carries no classification step, no `model_routing` block, and no Opus/Sonnet chain reference. [Workflow overview](../workflow.md#cross-cutting-commands) groups it under Setup and review utilities, alongside [`/api-guideline-reviewer`](api-guideline-reviewer.md), its sibling reviewer for OpenAPI specs rather than app code and UI.

## Synopsis

```
/guideline-reviewer <files-or-components>
```

`$ARGUMENTS` names the files or components to review. Leave it empty and the command asks which ones before dispatching anything.

## What it needs

- One or more file or component paths (or a description of what to review).
- Nothing else — no `$SPECS_PATH`, no `$VAULT_PATH`, no branch, no specs-repo preflight.

## What it produces

The `guideline-reviewer` subagent's verdict against the mandatory design-system and accessibility standards: app header, data table, filter field, connections, permissions, settings, dashboards, accessibility/WCAG, terminology, and data-naming findings, each pointing at the offending file or element. Unlike [`/api-guideline-reviewer`](api-guideline-reviewer.md)'s agent, this one's frontmatter also grants `Bash` alongside `Read`, `Glob`, and `Grep` — but the command itself still writes nothing and applies no fix.

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
