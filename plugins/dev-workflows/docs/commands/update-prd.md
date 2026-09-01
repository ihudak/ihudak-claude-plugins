# /update-prd

Refreshes an existing Product Requirements Document — routine updates and the rarer obstacle-driven re-do alike — gated by the same Opus review as [`/create-prd`](create-prd.md).

## Who runs it

`/update-prd` runs in the [pm](../roles-and-phases.md#pm--product-management) role, cost-attribution phase [prd-update](../roles-and-phases.md#prd-update) — distinct from `prd-creation` because this command refreshes an existing PRD rather than authoring one from scratch.

## Synopsis

```
/update-prd <KEY> [@transcript-or-notes ...] [--no-docs]
```

- **`<KEY>`** (mandatory) — the existing PRD's key. Format-validated only (`^[A-Z][A-Z0-9_]*(-\d+)+$`). The grammar fixes no depth, and that is what lets [`/create-prd`](create-prd.md) redirect here with a three-segment key — a PRD it authored inside a BRD slice on the BRD route. A two-segment key validates exactly as it always did.
- **`[@transcript-or-notes ...]`** (optional) — one or more paths to a transcript or notes file, read as secondary, read-only grounding for the grill.
- **`[--no-docs]`** — turns off documentation grounding for the run (see [What it needs](#what-it-needs)).

## How it runs

```mermaid
flowchart TD
    p0["Phase 0 — Resolve inputs"] --> p1["Phase 1 — Configure"]
    p1 --> p15["Phase 1.5 — Classify + model routing"]
    p15 --> p2["Phase 2 — Read the base + grounding"]
    p2 --> p3["Phase 3 — Update via grill"]
    p3 --> p35["Phase 3.5 — Prose style check"]
    p35 --> p36["Phase 3.6 — Structural pre-lint"]
    p36 --> p4["Phase 4 — Review gate"]
    p4 --> p5["Phase 5 — Handoff (canonical + archive) + handoff"]
    p5 --> p6["Phase 6 — Next steps"]
    p6 --> p7["Phase 7 — Session maintenance, feedback & cost"]
```

Three `dev-workflows` subagents are dispatched: `docs-grounder` (Phase 2, read-only grounding on the shipped product docs — default ON when `$DOCS_PATH` resolves, advisory, never a gate), `prd-reviewer` (Phase 4, Opus-pinned), and `impl-maintenance` (Phase 7, session lessons-learned), each against the model recorded in `model_routing`. A fourth agent, `prose-style:prose-style-checker`, runs in Phase 3.5 exactly as it does in [`/create-prd`](create-prd.md) — a non-gating quality pass from a separate plugin, not counted in the dispatch total above.

## What it needs

- **`<KEY>`** — mandatory; absent or malformed stops the run with `UPDATE_VI_NEEDS_KEY`.
- **`$SPECS_PATH`** (required) — if unset, the run stops naming `SPECS_PATH` and offers to enter a path or cancel.
- **The PRD**, at the resolved folder's `prd.md` — the only copy there is, and therefore the base without a freshness test.
- **Secondary grounding** (all optional and read-only): a frozen specs-repo draft (**prd.md**), any **ard.md**, **specification.md**, and the `@transcript`/notes path(s) passed on the command line. None of these gate the run. Where a discovered **ard.md** or **specification.md** is not on the specs repo's default branch, the Phase 1 confirmation flags it as unapproved — advisory only, never a reason to stop.
- **Documentation grounding** (optional, on by default) — turned off with `--no-docs`; a miss is a silent skip, never a gate.
- **No repos.** `/update-prd` is cwd-agnostic and product-level — it never mounts or scans code.

**`/update-prd` is the one authoring command deliberately excluded from `require-on-main`.** It never executes that consumer entry point at all, on any input. Its authoritative base is the resolved folder (above), not a gated specs artifact, so subjecting the secondary grounding to `require-on-main` would block a legitimate refresh purely because an unrelated ARD happened to sit on an unmerged branch — the command reports that state instead of stopping on it.

## What it produces

- The **canonical** PRD, overwritten in place at the feature folder's **prd.md**, with `revision_of` (the archived snapshot's path) and `built_from_date` (the date the update was built from) added to its frontmatter. Everything already there that records where the PRD came from is carried through unchanged — `sources`, `derived_from`, `seeded_from_prd`, and, on a PRD [`/create-prd`](create-prd.md) authored on the BRD route, `brd_key`, `brd_parent` and `depends_on`. Those three are preserved, never authored: this command reads no BRD tree, so it mints none of them and adds none to a PRD that arrived without them — and **no command consumes them yet** — neither [`/epics`](epics.md) nor [`/ready`](ready.md) reads any of the three. They are preserved because provenance that survives an update is the precondition for any future consumer: this command reads no BRD tree, so dropping them at the first refresh would leave a slice's PRD indistinguishable from an ordinary one with nothing left to restore it from.
- An **archived snapshot** of the prior canonical PRD, written first, before the overwrite, to `<feature-folder>/revisions/<KEY>_<slug>_<YYYYMMDD>.md` (a same-day second revision is suffixed `-2`, `-3`, …).
- Behind Phase 5's consent choice, both files are committed, pushed, and a pull request opened against the specs repo's default branch.
- *(The run used to end with a manual reminder to copy the updated body back into a tracker and refresh the export it read from. Neither step exists: the PRD is where every downstream command reads it.)*

## Gates

- **Phase 3.5 — Prose style check**, mirroring [`/create-prd`](create-prd.md) exactly: `prose-style:prose-style-checker` applies MAJOR fixes inline and re-runs once; a non-gating quality pass, skipped gracefully when the `prose-style` plugin is not installed.
- **Phase 3.6 — Structural pre-lint** (`../../references/pre-lint.md`), advisory only — mechanical findings fixed inline, content gaps left for the grill.
- **Phase 4 — `prd-reviewer`**, Opus-pinned by frontmatter (`model: opus`, no override), reviewing the whole updated PRD against `../../references/prd-format.md`. `PASS` / `PASS WITH RECOMMENDATIONS` proceeds. `BLOCK` triggers one inline fix cycle and one re-review; a persistent `BLOCK` is escalated per `../../references/escalation-rules.md`'s "Review verdict BLOCK" choices, exactly as in [`/create-prd`](create-prd.md).

## Example

Refresh a PRD with new call notes, after the specs draft has already been reviewed once:

```
/dev-workflows:update-prd PRODUCT-1234 @call-notes.md
```

The run resolves the feature folder, reads its `prd.md` as the base, grills the changes against it, and rewrites the canonical file while archiving the prior revision.

## See also

- [Roles and phases](../roles-and-phases.md) — what the `pm` role owns and hands off at the `prd-update` seam.
- [`/create-prd`](create-prd.md) — the greenfield sibling that authors a PRD from scratch. `/create-prd` redirects **here** when it finds a PRD already authored; going the other way, a resolved folder holding no `prd.md` stops this run with `UPDATE_PRD_NO_PRD`, and that stop names `/create-prd` only where that command can itself run — it refuses three shapes, not one, so on a BRD-route slice the stop resolves to [`/brd-split`](brd-split.md) against the slice or its parent, or to no command at all, where a data refusal would fire.
- [`/create-ard`](create-ard.md), [`/specify`](specify.md), [`/epics`](epics.md), and [`/release-notes`](release-notes.md) — the role re-runs `/update-prd`'s Phase 6 offers when an ARD, spec, or release note already exists.
- [Model routing](../reference/model-routing.md) — the classification and Opus fallback chain `prd-reviewer` runs under.
- [Session cost](../reference/session-cost.md), [Session feedback](../reference/session-feedback.md), and [Resume and checkpoints](../reference/resume-and-checkpoints.md) — the terminal Phase 7 bookkeeping every run emits.
- [`prd-format.md`](../../references/prd-format.md) — the canonical structure the PRD is updated and reviewed against.
