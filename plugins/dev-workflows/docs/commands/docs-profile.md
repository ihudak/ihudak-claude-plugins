# /docs-profile

Scans a documentation repository and writes or refreshes its machine-readable `.dev-workflows/docs-profile.yml` plus complementary CLAUDE.md guidance, as a reviewable PR.

## Who runs it

`/docs-profile` runs outside the role pipeline — no role, no cost-attribution phase (`references/cost-emission.md` never mentions it). [Workflow overview](../workflow.md#cross-cutting-commands) groups it under Setup and review utilities, alongside [`/statusline`](statusline.md), [`/api-guideline-reviewer`](api-guideline-reviewer.md), and [`/guideline-reviewer`](guideline-reviewer.md). Unlike those three siblings, `/docs-profile` does invoke the [model-routing](../reference/model-routing.md) skill — it classifies itself `SIGNIFICANT`, since a wrong profile steers every later [`/document`](document.md) run.

## Synopsis

```
/docs-profile [<repo-path>] [--inline]
```

The first token of `$ARGUMENTS` is the target repo path (default: the current working directory). `--inline` is the flag `/document` (Jira mode) passes when it invokes this flow itself, from its own Phase 0 — it skips the branch-name prompt in favour of a deterministic branch name, and hands the PR draft back to `/document` instead of reporting one itself.

## What it needs

- **A docs repository** — a writeable git work tree carrying at least one docs-repo signal (a doc `package.json` script, `.docstack/`, `.vale.ini`, a `*/_content/` directory, or `_snippets/`). Zero signals asks before continuing rather than refusing outright; not a work tree, or not writeable, stops with a named error.
- Nothing from `$SPECS_PATH` or `$VAULT_PATH` — the scan and the write both happen inside the target repo itself, and this command runs no specs-preflight and no `commit-artifacts` step.
- **`$GIT_USER_INITIALS`** (optional) — used only in standalone mode's branch-naming ladder, when the repo documents no branch convention of its own.

## What it produces

A two-stage read: a Sonnet-tier detection pass (mechanical repo scanning — package scripts, cross-space override manifests, shared registries, templating tokens, content/snippet roots, branch-naming and image conventions, prerequisites, announcement pages), then an Opus-tier synthesis that turns the detection report into a draft `docs-profile.yml` conforming to `dynatrace-docs/docs-profile-schema.md`. After you fill any gap the synthesis flagged, it writes `<repo-root>/.dev-workflows/docs-profile.yml` plus minimal CLAUDE.md additions on a new branch, as one commit, then drafts a copy-paste-ready PR title and body. **It never pushes, and never opens the PR itself** — you push the branch and open the PR yourself. An existing profile is refreshed, never silently overwritten: a field-level diff is shown and confirmed before any change is applied.

## Gates

No reviewer agent, and no Opus review gate in the code-review sense — the field-level confirmation (and, on a refresh, the diff-approval prompt) is the only checkpoint before anything is written, and nothing downstream re-reviews the profile.

## Example

```
/dev-workflows:docs-profile ~/repos/dynatrace-docs
```

Detects it as a multi-space docstack repo, drafts `spaces[]`, `dev_servers`, `cross_space_override`, and `shared_registries` from the Sonnet-tier scan, synthesises the full profile on Opus, asks about any field the synthesis flagged as unconfirmed, writes `.dev-workflows/docs-profile.yml` plus CLAUDE.md additions on a new branch, commits, and prints the branch name and a drafted PR title/body for you to push.

## See also

- [`/document`](document.md) — Jira mode's Phase 0 consumes this profile, and can invoke this command inline (`--inline`) when none exists yet.
- [Model routing](../reference/model-routing.md) — the `SIGNIFICANT` classification and the Sonnet-detection / Opus-synthesis model split this command applies.
- [Workflow overview](../workflow.md#cross-cutting-commands) — where this command sits among the setup utilities.
