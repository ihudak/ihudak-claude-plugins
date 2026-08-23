# /epics

Reads a Value Increment from exported markdown, optionally scans code repos, and drafts reviewed child Epic definitions.

## Who runs it

`/epics` runs in the [pe](../roles-and-phases.md#pe--product-engineering) role, cost-attribution phase [epic-refinement](../roles-and-phases.md#epic-refinement) — being in this phase means a VI is being broken down into child Epic drafts.

## Synopsis

```
/epics <VI-KEY | dir> [<Epic-KEY>] [--no-docs]
```

The positional input resolves through the shared Jira-input front-end: a **VI JiraID** (requires `$VAULT_PATH`), or a **jira-export directory** (works without it). An optional trailing **Epic key** narrows the run to refining that one Epic. `/epics` is **jira-driven only** — a plain prompt with no Jira input stops with `EPICS_NEEDS_JIRA`. `--no-docs` turns off the optional Phase 2 documentation-grounding pass.

## How it runs

`/epics` has 20 `## Phase` headings — the second-most in the plugin, after `/document`'s 37. The diagram below collapses adjacent phases that form one user-visible step, and shows the one real fork that changes which phases run at all: whether code examination is on.

```mermaid
flowchart TD
    p0["Phase 0 — Load"] --> p1["Phase 1 — Clarification"]
    p1 --> p15["Phase 1.5 — Classify"]
    p15 --> p2["Phase 2 — Plan + approval"]
    p2 --> p2526["Phase 2.5 — Resolve applicable ARD (optional) / Phase 2.6 — VI-level spec enrichment (optional)"]
    p2526 --> p3["Phase 3 — Read Jira hierarchy"]
    p3 --> p3536["Phase 3.5 — Refinement-mode gate (conditional) / Phase 3.6 — Documentation grounding dispatch"]
    p3536 --> d1{"Code examination on/off? (Phase 1)"}
    d1 -- "on" --> p45["Phase 4 — Resolve repos (conditional) / Phase 5 — Parallel code scanning (conditional)"]
    d1 -- "off" --> p6["Phase 6 — Write Epics"]
    p45 --> p6
    p6 --> p616263["Phase 6.1 — Resolve clarifications / 6.2 — Dynatrace style check / 6.3 — Structural pre-lint"]
    p616263 --> p7["Phase 7 — Epic review gate"]
    p7 --> p8["Phase 8 — Post-write maintenance"]
    p8 --> p91011["Phase 9 — Final Report / 10 — Emit follow-up tasks / 11 — Session cost"]
```

Seven `dev-workflows` subagents are dispatched: `docs-grounder` (Phase 3.6, read-only grounding on the shipped product docs — default ON when `$DOCS_PATH` resolves, advisory, never a gate), `jira-reader` (Phase 3, `depth: vi-plus-epics`), `code-scanner` (Phase 5, one instance per confirmed repo, up to 4 concurrent, only when code scan is ON), `epic-writer` (Phase 6, the sole author of the Epic drafts), `doc-fixer` (Phases 6.2 and 7, fixing style violations and surviving BLOCKER/MAJOR review findings), `epic-reviewer` (Phase 7, Opus-pinned), and `impl-maintenance` (Phase 8, session lessons-learned). The detection-tier agents (and `epic-writer` when the run is `MODERATE`) run at `detection_model`; `epic-reviewer` keeps its frontmatter Opus pin.

## What it needs

- **A Jira VI or Epic** via the shared front-end — a `mode: direct` prompt is rejected outright (`EPICS_NEEDS_JIRA`); `/epics` has no non-Jira behavior.
- **An optional VI-level `specification.md`** — this is `/epics`' `require-on-main`-gated input (Phase 2.6, `commands/epics.md:180`); the VI-level ARD below is gated too, via `../../references/ard-resolution.md`, which resolves `status: unmerged` through `require-on-main` as well. **Absent** is a silent skip (`vi_spec_present: false`) — the common case, since `/specify` usually runs per-Epic *after* `/epics` — with no prompt and no extra output. **Unmerged** is a hard stop, naming the branch and any open pull request: a spec that exists but hasn't landed on the default branch is weaker grounding than the one about to arrive, and Epics drafted against it would need redoing.
- **An optional VI-level ARD** (Phase 2.5), resolved via `../../references/ard-resolution.md` with `epic: null` (Epics don't exist yet). `status: none` skips silently and proceeds exactly as before; `status: unmerged` stops, naming the branch and any pull request; `status: found` carries its `[AD#N]` invariants into both `epic-writer` and `epic-reviewer`.
- **`$DOCS_PATH`** (optional, default `/workspace/docs`) — resolved in Phase 2, **before** the Phase 2.5/2.6 ARD and spec gates, a deliberate ordering exception to the usual gate-first sequencing: it is the run's only consent-bearing step (an index build or a capped refresh), so it must resolve before any of the run's real work, rather than risk a later phase stopping after that consent work already happened. Missing, unreadable, or empty is a silent, non-blocking skip. Turned off with `--no-docs`.
- **Mounted repos under `$REPOS_PATH`** — only consulted when code examination is ON (default). The repo list is auto-derived from sibling/parent Epics' `## Pull Requests` sections, or entered manually. A repo that resolves to zero matches is escalated, never silently dropped; an entirely empty resolved list still lets the run proceed without a code scan if the user chooses.

## What it produces

One `.md` file per new or refined Epic, under the resolved output directory: `$VAULT_PATH/jira-drafts/<VI-KEY>/` when `$VAULT_PATH` is set, or a derived `epic-drafts/<VI-KEY>/` beside the imported hierarchy otherwise — deliberately outside `jira-products/`, which is wiped on every Jira re-import. `epic-writer` also writes `_coverage.md` (VI-holistic requirement coverage; never pasted to Jira). Refined team-Epic files are keyed by their real Jira id (`<EPIC-KEY>.md`); net-new drafts are slug-named.

**`/epics` never creates a branch.** Its git writes are confined to `$SPECS_PATH`, and only to its bounded session-artifact paths — the Epic drafts themselves are never committed by this command at all; git hygiene of the write target (the vault or the derived output directory) is the user's own responsibility. This is unlike the eight commands that do offer a branch + commit + push + pull-request handoff for their own deliverable — [`/idea`](idea.md), [`/create-vi`](create-vi.md), [`/update-vi`](update-vi.md), [`/create-ard`](create-ard.md), [`/specify`](specify.md), [`/design`](design.md), [`/implement`](implement.md), and [`/ready`](ready.md).

## Gates

Phase 7 dispatches `epic-reviewer`, Opus-pinned, checking goal clarity, acceptance-criteria testability, scope boundaries, and non-duplication with existing Epics under the parent VI. Findings are triaged by the orchestrator (`../../references/finding-triage.md`) before `doc-fixer` ever sees them — each finding verified at the location it names, every dismissal recorded with a reason, survivors only handed to the fixer. `BLOCK` invokes `doc-fixer` for BLOCKER/MAJOR findings and re-reviews once, passing the fixer's own report back as `claims_file` so the re-review falsifies the fixer's account rather than assuming it; an unresolved BLOCKER after that cycle is escalated individually. `PASS WITH RECOMMENDATIONS` fixes MAJOR findings only; `PASS` proceeds. Cap: one fix cycle plus one re-review.

Ahead of the review, Phase 6.2 runs `dt-style-checker` as the **primary** style checker — not a fallback, since Epic drafts are vault-internal with no repo-side prose linter to fall back from. It is skipped gracefully, with a note in the final report, when the separate `dt-style-guide` plugin is not installed. Phase 6.3 then runs a structural pre-lint (`../../references/pre-lint.md`) — advisory only, checking required headings, Given/When/Then acceptance criteria, and the `[NEEDS CLARIFICATION]` cap.

## Example

Split a VI with two existing Epics not yet covering all its scope:

```
/dev-workflows:epics PRODUCT-1234
```

The run resolves the VI, asks for the output directory and whether to scan code (default on, repos auto-derived from sibling Epics' PR links), resolves any VI-level ARD and specification, reads the Jira hierarchy at `vi-plus-epics` depth, scans the confirmed repos in batches of up to 4, delegates the drafting to `epic-writer`, runs the Dynatrace style check and structural pre-lint, then `epic-reviewer`. On a passing verdict it reports the Epics written and `_coverage.md`'s gap list, and recommends `/dev-workflows:specify <VI> <Epic>` per drafted Epic as the next step — Epic drafting itself was never committed, so publishing the Epics to Jira remains a manual step.

## See also

- [Roles and phases](../roles-and-phases.md) — what the `pe` role owns, including `/epics`' Phase 2.6 gate, which always targets the VI dir's `specification.md` rather than a nested per-Epic one, since Epics don't exist yet when `/epics` runs.
- [`/create-vi`](create-vi.md) and [`/create-ard`](create-ard.md) — the upstream commands whose VI and (optional) ARD `/epics` reads.
- [`/specify`](specify.md) — the downstream command normally run once per drafted Epic; a VI with 0 Epics that reaches `/specify` first is itself offered a link back to `/epics`, but nothing gates the order.
- [Model routing](../reference/model-routing.md) — the classification rules and the `epic-reviewer` Opus pin.
- [Session cost](../reference/session-cost.md), [Session feedback](../reference/session-feedback.md), and [Follow-ups](../reference/follow-ups.md) — the terminal Phase 9–11 bookkeeping every run emits.
- [`ard-resolution.md`](../../references/ard-resolution.md) — how the optional VI-level ARD is resolved and inherited.
- [`finding-triage.md`](../../references/finding-triage.md) — the triage step run between `epic-reviewer` and `doc-fixer`.
