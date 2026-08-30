# /brd-ground

Pins every mounted repository to a verified commit, grounds every `[BR#n]` claim against code
(`code-grounder`) and an exported design frame set (`design-grounder`), independently re-derives
every finding (`grounding-verifier`, Opus), and assigns each finding a `current` / `will-change`
horizon against declared prerequisite BRDs.

## Who runs it

`/brd-ground` runs in the [pa](../roles-and-phases.md#pa--product-architecture) role,
cost-attribution phase `brd-to-prd` — the phase shared by all three commands of the BRD-to-PRD
route (`/brd-intake`, `/brd-ground`, `/brd-split`). All three ship together;
`/brd-intake` and `/brd-split` run as
[pm](../roles-and-phases.md#pm--product-management).

## Synopsis

```
/brd-ground <BRD-KEY> [--depends-on <BRD-KEY>…] [--derivation-matrix|--no-derivation-matrix] [--no-design] [--rebaseline]
```

- **`<BRD-KEY>`** (mandatory) — the BRD (or slice) to ground. Resolved via `resolve-brd`, so a
  parent or a slice key both work; format-validated only, never checked against a tracker.
- **`--depends-on <BRD-KEY>`** (optional, repeatable) — declares a prerequisite BRD. Persisted to
  `brd-link.md` additively across runs; the file may also be edited by hand.
- **`--derivation-matrix` / `--no-derivation-matrix`** (optional, mutually exclusive) — force the
  implementation-altitude data-source matrix on or off. Left unset, the command defaults it on for
  a BRD whose requirements read as reporting- or data-centric, and off otherwise.
- **`--no-design`** (optional) — skip the `design-grounder` pass even when an exported frame set
  is present.
- **`--rebaseline`** (optional) — re-run grounding against code that has moved since the last
  pass. Supersedes the affected findings by id rather than renumbering them, so a citation into an
  already-sent package still resolves.

## How it runs

```mermaid
flowchart TD
    p0["Phase 0 — Resolve inputs and gate on main"] --> p1["Phase 1 — Resolve repositories"]
    p1 --> p2["Phase 2 — Classify + model routing"]
    p2 --> p3["Phase 3 — Baseline integrity gate"]
    p3 --> p4["Phase 4 — Prerequisites"]
    p4 --> p5["Phase 5 — Fan out grounding"]
    p5 --> p6["Phase 6 — Horizons"]
    p6 --> p7["Phase 7 — Verify"]
    p7 --> p8["Phase 8 — Write findings"]
    p8 --> p9["Phase 9 — Handoff"]
    p9 --> p10["Phase 10 — Next steps"]
    p10 --> p11["Phase 11 — Session maintenance, feedback & cost"]
```

Three `dev-workflows` subagents are dispatched, all read-only against every repository they touch:
`code-grounder` (Phase 5, one per repository, ≤4 concurrent), `design-grounder` (Phase 5, one per
exported frame set, after every `code-grounder` instance has returned — its fourth reconciliation
class cites a `[CG#n]`), and `grounding-verifier` (Phase 7, one per finding, pinned to Opus).
`impl-maintenance` also runs, in Phase 11, for session lessons-learned.

## What it needs

- **`<BRD-KEY>`** — mandatory; absent or malformed stops the run with `BRD_GROUND_NEEDS_KEY`.
- **This BRD's own inventory and ledger already on the specs repo's main branch.** `/brd-ground`
  gates `coverage-ledger.md` on `origin/<default>` via `require-on-main` before reading anything
  else; an unmerged pull request stops the run naming the branch/PR state. When nothing for the BRD
  is on any ref, the stop names the fix by level: a BRD with a source document of its own stops
  with `BRD_GROUND_NEEDS_INTAKE`, naming `/brd-intake`; a **slice** — a child BRD, recognised by
  the `parent:` field in its `brd-link.md` — stops with `BRD_GROUND_NEEDS_SPLIT`, naming
  `/brd-split` on the parent, because a slice has no source document of its own to intake and its
  ledger and inventory are written by the parent's split
  ([`brd-format.md`](../../references/brd-format.md) §2.1,
  [`coverage-ledger-format.md`](../../references/coverage-ledger-format.md) §3).
- **`$REPOS_PATH`** — required; resolved as one directory or a colon-separated list. No resolvable
  entry stops the run naming `REPOS_PATH`.
- **A clean working tree per resolved repository.** The Phase 3 baseline-integrity gate runs
  `rev-parse HEAD`, a `diff --ignore-cr-at-eol --stat`, and a line-count check on anything
  `status --porcelain` reports, **before any finding is written**. Any non-empty content diff stops
  the run with `BRD_GROUND_DIRTY_TREE` — grounding a dirty tree would cite an unidentifiable
  snapshot.
- **`--rebaseline` when code has moved.** If a repository's `HEAD` has moved since the last
  recorded pin and `--rebaseline` was not given, the run stops with `BRD_GROUND_NEEDS_REBASELINE`
  rather than silently grounding against a snapshot the last package never saw.

## What it produces

Under the resolved `<BRD-KEY>-<slug>/` folder:

- `grounding/baselines.md` — one dated entry per repository: the pinned commit and how it was
  verified. `--rebaseline` appends rather than overwrites.
- `grounding/code-grounding.md` — every `[CG#n]` finding, plus the optional derivation matrix.
- `grounding/design-grounding.md` — every `[DG#n]` finding, or a note explaining why design
  grounding did not run.
- `brd-link.md` — the `depends-on:` list, merged additively across runs.

Behind Phase 9's consent choice, these are committed, pushed, and a pull request opened against
the specs repo's default branch under the shared `brd/<BRD-KEY>-<slug>` branch prefix.

## Gates

- **Phase 0 — `require-on-main` on this BRD's inventory and ledger.** No grounding starts until
  whichever command wrote them has merged its output — `/brd-intake` for a BRD with a source
  document of its own, `/brd-split` on the parent for a slice; see "What it needs" above for the
  exact stop conditions.
- **Phase 3 — baseline integrity, run by the orchestrator itself, not delegated to an agent.**
  Every repository is pinned and proven clean in content — not merely in `git status` — before
  Phase 5 dispatches a single agent. `code-grounder` and `grounding-verifier` each separately
  re-verify their own pinned commit against `HEAD`, but that check alone cannot see a dirty
  working tree sitting around an otherwise-matching `HEAD`; this phase is what closes that gap.
- **Phase 7 — `grounding-verifier` over every finding, pinned to Opus.** A finding without a
  verifier outcome is never treated as evidence. A `contradict` outcome rewrites the finding
  in place — same id, replaced verdict and evidence — so an existing citation keeps resolving; an
  `agree`/`extend`/`unprovable` outcome is recorded alongside the finding unchanged (`extend` also
  appends the additional evidence the verifier's own search turned up). Which anchor each finding
  is verified against depends on what it rests on: a `[CG#n]` and a class-4 `[DG#n]` are re-derived
  against the pinned repository, a class-1/2/3 `[DG#n]` against the frame set it was reconciled
  from — see [`grounding-format.md`](../../references/grounding-format.md) §8. A verifier that
  refuses rather than verifying (a moved `HEAD`, a repository or frame set no longer resolvable)
  stops the run before Phase 8 writes anything, so no finding is ever written without an outcome —
  which is what keeps `/brd-split`'s own verification gate reachable.

## Example

Ground a synthetic customer BRD once its intake pull request has merged:

```
/dev-workflows:brd-ground EPIC-008
```

The run resolves the BRD, gates its intake artifacts on main, resolves the repositories in scope,
pins and proves each one clean, grounds every `[BR#n]` claim against code and any exported design
frames, independently re-derives every finding on Opus, assigns horizons against any declared
prerequisites, writes the findings, and offers to branch, commit, push, and open a pull request.

## See also

- [Roles and phases](../roles-and-phases.md) — what the `pa` role owns and hands off.
- [`brd-addressing.md`](../../references/brd-addressing.md) — the `<BRD-KEY>` grammar and folder
  resolution this command uses by name (`brd-key-valid`, `resolve-brd`), including how a slice
  nests inside its parent.
- [`grounding-format.md`](../../references/grounding-format.md) — the authority for the finding
  record, the six verdicts, the two horizons, the `baseline-integrity` procedure this command's
  Phase 3 runs, and the four verification outcomes this command's Phase 7 acts on.
- [`coverage-ledger-format.md`](../../references/coverage-ledger-format.md) — the ledger line every
  `/brd-*` command's final report ends with.
- [`read-only-repos.md`](../../references/read-only-repos.md) — the read-only posture this command
  holds toward every repository it resolves.
- [Agents](../reference/agents.md) — the full contracts for `code-grounder`, `design-grounder`, and
  `grounding-verifier`.
- [Session cost](../reference/session-cost.md), [Session feedback](../reference/session-feedback.md),
  and [Resume and checkpoints](../reference/resume-and-checkpoints.md) — the terminal Phase 11
  bookkeeping every run emits.
