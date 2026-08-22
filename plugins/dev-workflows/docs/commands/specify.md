# /specify

Reads a Jira Epic or VI from exported markdown, lightly grounds in code, and authors an org-standard `specification.md` through a relentless grill.

## Who runs it

`/specify` runs in the [pe](../roles-and-phases.md#pe--product-engineering) role, cost-attribution phase [specification](../roles-and-phases.md#specification) — being in this phase means an org-standard `specification.md` is being authored for one item, lightly grounded in code.

## Synopsis

```
/specify <VI-Key | Epic-Key | dir> [<Epic-Key>] [--no-docs]
```

Key distinction from [`/epics`](epics.md): `/epics` *splits* a VI into Epic drafts; `/specify` *authors one specification* for a single item. **The VI-level path is genuinely valid, not a fallback of last resort**: `/specify <VI>` with no focus Epic stays in the PE lane and produces one broad `specification.md` at the VI dir. What Phase 2 does with a bare VI key depends on how many child Epics it has:

- **A stand-alone top-level Epic** (no parent VI) — no picker; the item is itself the focus.
- **A VI with exactly 1 Epic** — no picker; that Epic auto-resolves as the focus, with a one-line notice.
- **A VI with ≥2 Epics** — Phase 2 renders a progress-aware picker: one row per child Epic (marked ○ not started / ◐ in progress / ● done), plus an explicit **"Author one broad VI-level spec instead"** choice.
- **A VI with 0 Epics** — offered `choices: ["Split into Epics first with /dev-workflows:epics, then create them in Jira and re-import (Recommended)", "Author one broad VI-level spec now", "Cancel", "Other… (describe)"]`; `/specify` never creates Jira Epics itself.

An explicit `<VI-Key> <Epic-Key>` (or `<dir> <Epic-Key>`) skips the picker entirely — the Epic is already chosen. `--no-docs` turns off the optional Phase 4 documentation-grounding pass.

## How it runs

```mermaid
flowchart TD
    p0["Phase 0 — Resolve input"] --> p1["Phase 1 — Configure"]
    p1 --> p15["Phase 1.5 — Classify"]
    p15 --> p2["Phase 2 — Read Jira"]
    p2 --> d1{"Epic count for this VI? (Phase 2 Step A)"}
    d1 -- "stand-alone Epic, or exactly 1 child Epic → auto-resolved" --> p25["Phase 2.5 — Resolve applicable ARD (optional)"]
    d1 -- "≥2 child Epics → pick one, or author one broad VI-level spec" --> p25
    d1 -- "0 child Epics → split via /epics, or author one broad VI-level spec" --> p25
    p25 --> p3["Phase 3 — Derive repos + soft gate"]
    p3 --> p4["Phase 4 — Light code scan"]
    p4 --> p5["Phase 5 — Author via grill"]
    p5 --> p55["Phase 5.5 — Structural pre-lint"]
    p55 --> p6["Phase 6 — Finalize + review gate"]
    p6 --> p7["Phase 7 — Handoff"]
    p7 --> p8["Phase 8 — Session maintenance & feedback"]
    p8 --> p9["Phase 9 — Session cost"]
```

Five `dev-workflows` subagents are dispatched: `docs-grounder` (Phase 4, read-only grounding on the shipped product docs — default ON when `$DOCS_PATH` resolves, advisory, never a gate), `jira-reader` (Phase 2, twice on a multi-Epic VI — a cheap `vi-plus-epics` read for Step A's picker, then a `depth: full` read scoped to the resolved Epic), `code-scanner` (Phase 4, one instance per mounted candidate repo, up to 4 concurrent per batch — deliberately **light** relative to `/epics`' scan, grounding for feasibility rather than a full reuse audit), `spec-reviewer` (Phase 6, Opus-pinned), and `impl-maintenance` (Phase 8, session lessons-learned). The grill and the `specification.md` authoring itself run inline on `current_model` rather than through a delegated subagent.

## What it needs

- **A Jira Epic or VI** via the shared front-end — a `mode: direct` prompt is rejected outright (`SPECIFY_NEEDS_JIRA`); `/specify` has no non-Jira behavior.
- **The VI on the specs repo's default branch** — gated via `require-on-main` against `specifications/<VI>-<vslug>/`. An unmerged VI is a hard stop, naming the branch and any open pull request. An **absent** VI is not a stop: `/specify`'s existing Jira-export behaviour is unaffected, and the run reports that it is specifying from the export directly — the same fallback `/create-ard` uses.
- **`$SPECS_PATH`** (required) — `/specify` writes under `$SPECS_PATH/specifications/`, the specs repo, never the vault; unset stops the run naming `SPECS_PATH`, with no vault-relative fallback.
- **An optional ARD** for this item (Phase 2.5), resolved via `../../references/ard-resolution.md` with the VI and the resolved focus Epic. `status: none` skips silently; `status: unmerged` stops, naming the branch and any pull request; `status: found` keeps the spec's user stories and scope consistent with its `[AD#N]` invariants during the grill, passed to `spec-reviewer` as `applicable_ard`.
- **Mounted repos under `$REPOS_PATH`** — candidates are auto-derived from Jira capability themes and linked PR URLs. An *unresolved* repo slug (zero or ambiguous matches) hard-escalates before Phase 4 runs at all. A resolved-but-unmounted repo, by contrast, only **soft-gates**: it becomes an open question in `_session.md` and the run proceeds with the remaining mounted repos — the specification just can't cite the ungrounded one until it's mounted and the run is re-invoked.
- **`$DOCS_PATH`** (optional, default `/workspace/docs`) — consumed with grill-rank ranking in Phase 4. Missing, unreadable, or empty is a silent, non-blocking skip. Turned off with `--no-docs`.
- **A prior `_session.md`** (optional) — if one exists in the resolved feature folder, Phase 1 offers resume-vs-fresh; on resume, Phase 5 begins at the first unsettled stage instead of the header.

## What it produces

`specification.md` (`Published: no`), `idea.md` (pre-spec brainstorming provenance derived from the scoped Jira text), `_session.md`, `_glossary.md`, and a rendered `.html` mirror — written into the feature folder: the Epic subfolder for a per-Epic or stand-alone-Epic spec, or the VI dir itself for a broad VI-level spec. `specification.md` is authored against `../../references/specification-format.md` through five ordered stages: Problem statement, Scope, User stories, Acceptance criteria (EARS phrasing), and Test cases — each stage's own numbered-ID scheme is the spec/design namespace `specification-format.md` defines, deliberately separate from a VI's `[US#N]`-style grammar. Behind Phase 7's consent choice, the whole feature folder is committed, pushed, and a pull request opened against the specs repo's default branch — **merged-to-main is what makes the spec visible to Devs and to [`/design`](design.md)**, which reads it from `main` only, never from a branch. `Published: yes` is a separate, human-only freeze step outside this command's scope.

## Gates

Phase 6 dispatches `spec-reviewer`, Opus-pinned by frontmatter (`model: opus`, no override), checking per-stage quality, cross-stage consistency, coverage, and identifier integrity. `BLOCK` fixes the BLOCKER findings inline — the orchestrator/grill edits `specification.md` directly; there is no delegated writer to re-dispatch — and re-reviews once; an unresolved BLOCKER after that cycle is escalated individually, with "Defer" appending a `## Refinement notes` section to the spec itself. `MAJOR`/`MINOR`/`NIT` under `PASS WITH RECOMMENDATIONS` are deferred to the final report with no mandatory fix cycle. Cap: one fix cycle plus one re-review.

Ahead of the review, Phase 5.5 runs a structural pre-lint (`../../references/pre-lint.md`) — advisory only — checking the Universal checks and the spec block, including that the header's `Open questions` count matches the actual `- [ ]` count.

## Example

Author a specification for a single Epic already selected:

```
/dev-workflows:specify PROD-1234 PROD-1250
```

The run resolves the VI and the named focus Epic (skipping the picker, since it was given explicitly), reads the full Epic subtree, resolves any applicable ARD, derives and lightly scans mounted repos, grills you relentlessly through Problem statement → Scope → User stories → Acceptance criteria → Test cases, runs the structural pre-lint, then `spec-reviewer`. On a passing verdict it offers to branch, commit, push, and open a pull request; if this Epic came from a multi-Epic VI's picker, it then offers to loop straight into the next sibling Epic.

## See also

- [Roles and phases](../roles-and-phases.md) — what the `pe` role owns, including the two "absent falls back, unmerged stops" gates it shares with [`/create-ard`](create-ard.md).
- [`/epics`](epics.md) — the upstream command that splits a VI into the child Epics `/specify` is typically run once per; a VI with 0 Epics is offered a link back here.
- [`/create-ard`](create-ard.md) — the optional upstream command whose `[AD#N]` invariants `/specify` inherits when present.
- [`/design`](design.md) — the downstream command that refuses to start until this command's `specification.md` is merged to the specs repo's default branch.
- [Model routing](../reference/model-routing.md) — the classification rules and the `spec-reviewer` Opus pin.
- [Session cost](../reference/session-cost.md), [Session feedback](../reference/session-feedback.md), and [Resume and checkpoints](../reference/resume-and-checkpoints.md) — the terminal Phase 8–9 bookkeeping every run emits.
- [`specification-format.md`](../../references/specification-format.md) — the canonical structure `specification.md` is authored and reviewed against.
- [`ard-resolution.md`](../../references/ard-resolution.md) — how the optional ARD is resolved and inherited.
