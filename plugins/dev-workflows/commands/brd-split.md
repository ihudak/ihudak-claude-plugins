---
name: brd-split
description: BRD-splitting workflow (PM phase, third command of the BRD-to-PRD route). Gates on every grounding finding carrying a verifier verdict, proposes candidate slices from the grounded picture (buildable now, blocked, or dependent), keys and nests a child BRD folder per confirmed slice with its own brd-link.md, inherited brd/brd-inventory.md, and unallocated coverage-ledger.md, then walks every unallocated coverage-ledger row one at a time through five resolutions (build here, assign to a named child, defer to this BRD, reject citing a defect, or mark superseded) until none remain unallocated, and writes slices.md with the rationale for each slice and each deferral. Run on a slice it allocates but does not slice: nesting is capped at one level, so no child is created and the walk offers four resolutions instead of five - covered-by is not among them because on a slice it records a provisional claim this command's own walk on the parent withdrew, and the parent writes it. Re-running is a no-op that prints the ledger only where the ledger is fully allocated AND no child is left standing while claiming nothing; a standing empty child keeps the run alive, because this is the only command that can remove it or keep it against a recorded reason. Offers /brd-interview on the BRD just allocated, and /brd-ground on each non-empty child, as the next steps.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Split the grounded BRD into child BRDs and allocate every requirement: $ARGUMENTS

`/brd-split` is the **third command of the BRD-to-PRD flow** (PM phase) — it
takes the findings `/brd-ground` verified and forces every `[BR#n]` in this BRD's coverage ledger
to a recorded fate: built here, built by a named child, deferred, rejected, or superseded. This is
the only place that fate is ever decided (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md`
§1) — without this command's gate, a long BRD split across several children could have every child
quietly wave a requirement past, and nothing would notice.

Usage: `/brd-split <BRD-KEY>`

Runs at either of the two levels `<BRD-KEY>` can name, in one of **two modes** Phase 0 step 5
resolves from the folder itself:

- **`split_mode: full`** — a BRD that owns its source document. Everything below runs: slices are
  proposed, children are keyed and nested, and the ledger walk offers all five terminal
  resolutions.
- **`split_mode: allocate-only`** — a slice. Nesting is capped at one level
  (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §3), so **no child may be created below a
  slice**: Phases 2 and 3 are skipped entirely and the walk offers **four** resolutions, without
  `covered-by`. That last part is about **who writes** the disposition, not about whether a slice
  may carry it: a slice's `covered-by` names a sibling or the parent and records a provisional
  claim the *parent's* walk withdrew, so it is already terminal before this walk reads the ledger
  (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §2, §3). The cap is on nesting, not
  on allocation — a slice whose rows could never leave `unallocated` could never become PRD-eligible
  (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5), which would make slicing
  pointless. The run announces the mode rather than quietly behaving differently.

---

## Phase 0 — Resolve inputs and gate on verification

1. **`<BRD-KEY>` (mandatory).** Parse the first non-flag token; validate with `brd-key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §1). If absent or invalid, stop:
   `BRD_SPLIT_NEEDS_KEY: /brd-split needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$) — re-run '/dev-workflows:brd-split <KEY>'.`
2. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH`, per the
   `Required path environment variable unset` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Set SPECS_PATH (enter the path)", "Cancel"]
   ```
3. **Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute
   its `specs-preflight` entry point (§3) inline. Prompt-free and silent when the specs repo is
   clean and on its default branch. If a guard fires, emit its §5 notice; if it returns
   `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal
   `commit-artifacts` step skips on it.
4. **Resolve the BRD folder.** `resolve-brd <BRD-KEY>` (`brd-addressing.md` §2), which searches
   `specifications/` and exactly one level below it (§2 step 2) — the two levels a BRD folder can
   occupy. Absent → stop, without asserting which command would create it, because nothing on disk
   says whether this key names a BRD with a source document or a slice of one:
   `BRD_SPLIT_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /dev-workflows:brd-split on its parent.`
5. **Resolve the run mode.** Read the resolved folder's `brd-link.md` and branch on its `parent:`
   field — the same signal `/brd-ground` Phase 0 uses to tell a slice from a root, and the only
   reliable one: a key's segment count is a naming convention, never a depth declaration
   (`brd-addressing.md` §1).
   - **No `brd-link.md`, or one with no `parent:`** → this BRD owns its source document. Set
     `split_mode: full`; carry it for the whole run. Nothing is announced — this is the ordinary
     case.
   - **`parent: <PARENT-KEY>` present** → this is a slice. Set `split_mode: allocate-only`, carry
     it for the whole run, and **emit this notice now, and again in the final report** — a run that
     silently skips two phases and drops a resolution from its own picker is worse than one that
     says so:
     `BRD_SPLIT_ON_SLICE (notice, not a stop): <BRD-KEY> is a slice of <PARENT-KEY>. This run allocates <BRD-KEY>'s ledger but creates no children: nesting is capped at one level, so Phases 2-3 are skipped and no child BRD can exist below a slice. The Phase 4 walk offers four resolutions instead of five: covered-by is not one this walk can choose — on a slice it names a sibling or the parent, records a provisional claim the parent's own walk withdrew, and is written by that walk, so every row carrying it is already terminal here.`
   **This is a cap on nesting, not on allocation.** A grandchild would inherit `brd/source/` and a
   defect log from a parent that holds neither, so its inventory header would name a path that does
   not exist (`brd-addressing.md` §3, `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §2.1) — that
   is what child creation is refused for. A slice's own ledger has no such problem: its rows are
   this BRD's to allocate, and refusing to walk them would leave every one of them `unallocated`
   forever, which is the allocation deadlock this command exists to prevent
   (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §1, §4). The one inheritance the
   walk itself needs — the defect log a `rejected: [DEF#n]` cites — resolves in the parent's log in
   `allocate-only` mode, and that lookup is exactly one hop because the cap makes a slice's parent
   always the source-owning root (`brd-format.md` §4). Phase 4 states it where it is used.
6. **Gate the grounding deliverable on main.** `/brd-split` **consumes** a `$SPECS_PATH`
   deliverable it did not write (`/brd-ground`'s findings, and — transitively — `/brd-intake`'s
   ledger), so per `phase-handoff.md` §5 rule 2 it executes `require-on-main` (§3) here in Phase 0,
   before anything else reads a file. Execute it against the resolved BRD folder's
   `grounding/code-grounding.md` — every deliverable a `handoff-to-main` run stages lands in one
   commit (§2.3), so this file's presence on `origin/<default>` implies `grounding/design-grounding.md`
   and `brd-link.md` merged with it; and since `/brd-ground` Phase 0 step 6 already required
   `coverage-ledger.md` on `origin/<default>` before grounding itself would run, it also implies
   `/brd-intake`'s ledger was on main before this BRD was ever grounded. Map the §3.7 return by
   `stopped` first: any stopping row → stop, naming the concrete branch/PR state it reports;
   `pass` → proceed; `pass_amending` → proceed, printing the §3.3 row-B message; `absent` (row F —
   grounding findings are on no ref at all) → **split it before stopping, on a test row F cannot
   make**, the way `/brd-reconcile` splits its own row F. Row F covers two states here, and the
   message for the second one must not name a command that stops on the same emptiness. Read
   `<BRD-dir>/brd/brd-inventory.md` from the worktree and count its `[BR#n]` rows:
   - **One or more rows** — grounding simply has not run yet, and running it is the fix:
     `BRD_SPLIT_NEEDS_GROUNDING: no grounding findings on file for <BRD-KEY> — run /dev-workflows:brd-ground <BRD-KEY> first.`
   - **Zero rows** — there is nothing to ground, so `/brd-ground` stops with
     `BRD_GROUND_EMPTY_INVENTORY` rather than producing the findings this gate wants. Naming it here
     would be the loop, so name the upstream fix instead, by the `split_mode` step 5 already
     resolved — `full` means this BRD owns its source document, `allocate-only` means it is a slice:
     `BRD_SPLIT_EMPTY_INVENTORY (split_mode: full): <BRD-KEY>'s inventory holds no [BR#n] row, so there is nothing to ground and nothing to allocate — do not run /dev-workflows:brd-ground, which stops on the same emptiness. Re-run '/dev-workflows:brd-intake <BRD-KEY> @<brd-file>' over this same folder with a source whose requirements brd-reader can identify, and merge that pull request; if the source genuinely states no requirement, this BRD has nothing for the route to carry.`
     `BRD_SPLIT_EMPTY_INVENTORY (split_mode: allocate-only): <BRD-KEY> is a slice of <PARENT-KEY> and its inventory holds no [BR#n] row — it claims nothing, so there is nothing to ground and nothing to allocate. Do not run /dev-workflows:brd-ground, and do not run /dev-workflows:brd-intake on a slice; it has no source document of its own. Re-run '/dev-workflows:brd-split <PARENT-KEY>': it resolves every standing empty child, so it will offer to remove this slice or to keep it against its recorded reason, and it will offer covered-by against it for any row on the parent's ledger that is still unallocated. If the parent's ledger has no unallocated row left, removal is the only thing that can change this slice's state — /brd-split never re-allocates a row that already carries a fate.`
   `unmanaged` → proceed as before this feature.
7. **Gate on verification.** Every `[CG#n]`/`[DG#n]` finding carries a verifier `outcome` (one of
   the four in `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §8 — `agree`, `extend`,
   `contradict`, `unprovable`) once `/brd-ground` Phase 7 has run over it; a finding without one
   "is not evidence and cannot be recorded as `consumed_by` anything" (§8), and this command must
   never propose a slice or offer `covered-here` against a claim nobody has actually verified.
   Count every finding on file carrying no recorded `outcome`. Any count `N` greater than zero →
   stop: `BRD_SPLIT_UNVERIFIED: N findings have no verifier verdict — run /dev-workflows:brd-ground first.`
8. **Read the ledger; check for the no-op case.** Read `<BRD-dir>/coverage-ledger.md` and compute
   its disposition counts (`coverage-ledger-format.md` §3) — **this BRD's own rows, as written, with
   no child ledger consulted.** The no-op test and the §4 gate are both about `unallocated` on
   *this* ledger; what a child did with a row this BRD already delegated cannot make that row
   `unallocated` again, and the remedy for a child that is not building it lives in the child's own
   walk, not here. Child ledgers are read once, in the Final Report, and only to count the line
   (`coverage-ledger-format.md` §6.1). **Zero rows are `unallocated`** → set `unallocated_zero: true`.

   **That is only half the no-op test, and the missing half was a dead end.** A run is a no-op only
   when there is nothing left for *any* phase to do, and Phase 4.5 has work of its own that the
   ledger cannot see: a child left standing while claiming nothing. Deciding the no-op on the ledger
   alone made that child unreachable — the ledger of a parent whose walk completed has zero
   `unallocated` rows **by construction**, so every later run no-op'd, Phase 4.5 never ran, and the
   only command that can remove an empty child never offered to. Three stops elsewhere on this route
   name this command as the fix for exactly that child, so the no-op has to account for it. The
   second half needs step 9's enumeration, so **the no-op decision is taken in step 10**, never
   here.

   **Step 10 and not step 9, because step 9 does not run in every mode.** Step 9 is `full` only, so
   a decision taken inside it is never taken at all on a fully-allocated slice — the run would fall
   through into Phase 5 and open a pull request for a run that changed nothing, and this command's
   own Phase 7 promises a slice the opposite. Step 10 runs in both modes, which is what keeps the
   no-op **mode-independent**: it is decided by the ledger and the tree, not by the level, so a
   fully-allocated slice reaches it exactly as a fully-allocated parent does. `allocate-only` simply
   satisfies the second half by construction — no child exists or can be created below a slice — and
   it had two fewer phases to skip. The step 5 notice is still emitted and still reported.
9. **Enumerate existing children — `split_mode: full` only.** In `allocate-only` mode there are no
   children and none can be created, so this step is skipped — and with no child to enumerate there
   is no `covered-by` target for Phase 4 to offer, which is the mechanical reason that picker is
   four choices rather than five. A slice's own `covered-by` rows name a sibling or the parent and
   are written by the parent's walk, never chosen here
   (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3); this step never looks for
   them and never needs to, because they are terminal already. In `full` mode: list every immediate subdirectory of `<BRD-dir>` whose name
   matches `<KEY>{-|_}<slug>` (`brd-addressing.md` §2 step 1), excluding `brd/`, `grounding/`, and
   `dev-workflows/` — none of those is ever a BRD folder. Each match is a child a previous
   `/brd-split` run already created, nested per §3, and remains a valid `covered-by` target in
   Phase 4 even when this run proposes no new slice of its own. **Read each one's `brd-link.md`
   `claims:` list**, and mark every match whose list is empty as a **standing empty child**, noting
   whether it carries a `reason:` field — Phase 4.5 resolves exactly this set, and it is the set the
   no-op test in step 10 needs. **Carry the marked set forward even when it is empty** — step 10
   reads it in both modes, and in `allocate-only`, where this step never ran, it is empty by
   construction because no child exists or can be created below a slice.
10. **Take the no-op decision — both modes, always.** This step runs whether or not step 9 did, which
    is the whole reason it is its own step: the decision must be reached on a slice exactly as on a
    parent.
    - `unallocated_zero` (step 8) **and** no standing empty child (step 9, empty by construction in
      `allocate-only`) → this run is a **no-op** (§4): nothing in Phases 2–5 and nothing in Phase 4.5
      has anything left to do, so skip straight to Phase 6 (Handoff), which will report nothing to
      commit, and the Final Report's ledger line. This is the path a fully-allocated slice takes, and
      the one Phase 7 tells a slice to expect.
    - `unallocated_zero` **but at least one standing empty child** (`full` only — a slice can have
      none) → **not a no-op**: skip Phases 2, 3 and 4, which have no row to walk and no slice to
      propose, and run **Phase 4.5 alone**, then Phase 5 and Phase 6 as usual. This is the one path on
      which Phase 4.5 runs without a walk in front of it, and it exists so that a child kept empty by
      a deliberate decision is still reachable by the command every other stop on this route names.
    - Otherwise → the ordinary run: Phases 2–6 as written, in whichever mode step 5 resolved.

---

## Phase 1 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT for an unusually large requirement count or slice fan-out
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # impl-maintenance only — no other agent runs in this command
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

`/brd-split` dispatches no grounding or review agent of its own — every finding it reads was
already independently verified by `/brd-ground`'s `grounding-verifier` pass (`brd-ground.md` Phase 7) — so
`detection_model` here exists only for the terminal `impl-maintenance` dispatch. If no Opus
resolves for `current_model`, degrade to best-available + record in `notes` and the final report —
never hard-block.

---

## Phase 2 — Propose slices

**Skipped entirely in `split_mode: allocate-only`** (Phase 0 step 5). A slice can hold no child, so
there is nothing to propose and nothing a proposal could be keyed into; go straight to Phase 4,
whose walk is the whole of an `allocate-only` run. Everything below is `full`-mode only.

Read `<BRD-dir>/brd/brd-inventory.md`, `coverage-ledger.md`, `grounding/code-grounding.md`, and
`grounding/design-grounding.md`. For every `[BR#n]` still `unallocated`, read its findings'
`verdict` and `horizon` (`grounding-format.md` §2–§3, §5): a requirement whose findings are all
`CONFIRMED`/`AMENDED` at `horizon: current` is **buildable now**; one carrying `REWRITTEN` or
`FALSE-FRIEND` needs reconsidering before it is buildable at all; one carrying `NOT-PROVABLE` or a
`will-change` horizon is **blocked** or **dependent** on the named prerequisite decision. Cluster
requirements along these buildable / blocked / depends-on lines into candidate slices — a
coherent, independently buildable group of `[BR#n]` rows, never a single row on its own unless
nothing else clusters with it.

Present the candidate slices (each: a short working name, its `[BR#n]` rows, and the one-line
buildable/blocked/depends-on rationale that put them together) and confirm before anything is
created:

```
choices: ["Accept these slices as proposed (Recommended)", "Edit one or more slices (rename, merge, move a row)", "Replace with a different slice list entirely", "Propose no slices — walk the ledger directly", "Cancel", "Other… (describe)"]
```

**Zero confirmed slices is a legitimate outcome.** A BRD nobody splits still needs every row walked
in Phase 4 — most naturally landing on `covered-here`, per `coverage-ledger-format.md` §5's
PRD-eligibility rule — so choosing
"walk the ledger directly" or editing the list down to nothing skips Phase 3 entirely and proceeds
straight to Phase 4 with whatever children Phase 0 step 9 already found (if any).

---

## Phase 3 — Key and nest each confirmed slice

**Skipped entirely in `split_mode: allocate-only`** — this phase is the child creation the one-level
cap forbids, and it is the only phase that is forbidden rather than merely empty.

For every slice Phase 2 confirmed:

1. **Take a key.** Propose a default of the parent's key plus the next unused two-digit segment
   (e.g. `<PARENT-KEY>-01`, `<PARENT-KEY>-02`, …, skipping any segment an existing child from
   Phase 0 step 9 already uses) and let the operator accept it or supply their own. Validate
   whatever is used with `brd-key-valid` (`brd-addressing.md` §1); an invalid key is re-prompted,
   never silently coerced.
2. **Create the folder inside this one.** `specifications/<PARENT-KEY>-<parent-slug>/<CHILD-KEY>-<child-slug>/`,
   per `brd-addressing.md` §3 — a child BRD is never a sibling of its parent. `<child-slug>` is a
   kebab of the slice's working name from Phase 2.
3. **Write the child's `brd-link.md`**: `parent: <BRD-KEY>` and `claims:` — the slice's `[BR#n]`
   rows as currently proposed. This is provisional: Phase 4's walk is the step that actually moves
   a row's disposition, and a row proposed here for this child but resolved differently there (for
   example rejected instead) is removed **from this list** at that point, never left to disagree
   with the ledger. **Only the `claims:` entry and the inventory row step 4 copies for it are
   withdrawn — the ledger row step 5 seeds is not.** A ledger row is never deleted
   (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §2), so the child keeps an
   **orphan row** for that `[BR#n]`, and Phase 4's reconcile step writes it the terminal
   disposition the walk settled — including `covered-by: <SIBLING-KEY>` where the walk gave the
   requirement to another child of this BRD. Deleting it instead would erase the only record that a
   claim was made and withdrawn; leaving it `unallocated` would block that slice's own §4 gate
   forever, and with it every command that gates on the slice being fully allocated.
4. **Write the child's `brd/brd-inventory.md`** — the subset of *this* BRD's inventory rows the
   `claims:` list above names, copied row-for-row (`id`, `text`, `source_anchor`, `defects`
   verbatim), under the `parent:`/`source:` header
   `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §2.1 fixes. **Copy; never re-extract.** Ids are
   the parent's and stay the parent's, and every `source_anchor` copied here keeps resolving
   against the parent's `brd/source/` — the child holds no source of its own and never will, which
   is why §2.1 makes the header carry that path. The child likewise gets no
   `brd/brd-defect-log.md`: a `[DEF#n]` on a copied row is the parent's, and any reader who has to
   resolve one while standing on the child looks it up in the parent's log (`brd-format.md` §4).
   That resolution is always one hop, never a chase: the cap in `brd-addressing.md` §3 makes this
   child's parent — this BRD — the source-owning root.
5. **Write the child's `coverage-ledger.md`** — one row per `[BR#n]` in the inventory just written,
   `disposition: unallocated` on every one, per
   `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3, whose creator table names this
   phase as the writer of a slice's ledger. `defects` mirrors the copied inventory row; `evidence`
   is empty — the child has not been ground yet, and this BRD's `[CG#n]`/`[DG#n]` findings were
   derived against this BRD's claim list, not the child's.

Steps 4 and 5 are what let the child **re-enter the route** at Phase 7's recommendation:
`/brd-ground`'s own Phase 0 gates on the child's `coverage-ledger.md` and reads the child's
`brd/brd-inventory.md`, and `/brd-intake` — the only other command that writes either file — is
never run on a slice, because a slice has no document to intake. This command is the only place
those two files can come from, so it writes them at the same moment it writes `brd-link.md`, not
later.

A slice confirmed in Phase 2 but never given a folder here (the operator cancelled mid-key-taking)
is dropped — it never becomes a `covered-by` target, and its rows return to the ledger walk
unclustered.

**About the child's key.** The default proposed in step 1 — the parent's key plus the next unused
two-digit segment — is a naming convention that keeps sibling slices distinguishable and reads as
what it is. It buys the child no resolution depth and needs none: `resolve-brd` searches
`specifications/` and exactly one level below it, which is where this folder sits regardless of how
many segments its key carries (`brd-addressing.md` §1, §2). So an operator-supplied key with no
additional segment resolves exactly as the default does, and nothing about either choice makes the
child sliceable — no key shape lifts the one-level cap (§3).

---

## Phase 4 — Walk the ledger

**This phase runs in both modes** — it is the allocation walk, and allocation is not what the
one-level cap restricts. What differs is the size of the picker.

For every row in `coverage-ledger.md` still `disposition: unallocated`, present it **exactly one
at a time, never batched**, via `AskUserQuestion` — quoting its `id`, `text`, `defects`, and
`evidence` so the operator has everything needed without opening the file.

**`split_mode: full` — five resolutions:**

```
choices: ["Build here — covered-here, where this row clusters with nothing and fits no slice", "Assign to a named child BRD — covered-by", "Defer to this BRD — deferred-to (a real allocation, not a shortcut)", "Reject — citing a [DEF#n]", "Mark superseded by another [BR#n]", "Cancel", "Other… (describe)"]
```

**No option on that picker carries a `(Recommended)` marker, and the omission is required rather
than stylistic.** Which resolution is right is a fact about the row in front of the operator — a row
that clusters into a slice takes `covered-by`, one that does not takes `covered-here`, one the
customer has withdrawn takes `rejected` — and the list is shown once per row, so no marker could be
true across the runs that reach it. `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` covers
exactly this under *When no option is safe to recommend*: omit the marker and say so in prose beside
the list. **A conditional marker is not the alternative.** `(Recommended when nothing clusters)`
reads as guidance and is malformed by that file's *The `(Recommended)` marker is unconditional*
rule — it hands the operator the gate this phase was supposed to evaluate, and an orchestrator that
must present the list verbatim cannot honour it either way. The condition belongs in the option's own
text, which is where it now sits. Say beside the list that `covered-here` is the ordinary landing for
a row nothing clusters with, and that `deferred-to` is a real allocation rather than a way of
deferring the choice itself.

**`split_mode: allocate-only` — four**, with `covered-by` absent and **the reason stated in the
picker itself**, so an operator who expected five is told why rather than left to notice a missing
option. This picker *does* carry a marker, and the asymmetry is the rule working rather than an
inconsistency: on a slice every row the walk stands on is a row the parent allocated **here**, so
`covered-here` is unconditionally the expected answer and the marker is a plain reason annotation
(`(Recommended — <why>)`), not a condition:

```
choices: ["Build here — covered-here (Recommended — this slice was carved out to build these rows)", "Defer to this slice — deferred-to (a real allocation, not a shortcut)", "Reject — citing a [DEF#n] in the parent's defect log", "Mark superseded by another [BR#n]", "Cancel", "Other… (describe)"]
```

State once, before the first row of an `allocate-only` walk: *"`covered-by` is not offered here.
On this slice it would name a sibling under the same parent, or that parent — never a child, since
nesting is capped at one level and none can exist below a slice
(`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §3). It is written by the **parent's** walk,
on a provisional claim that walk withdrew, and every row carrying it is terminal before this run
opens the file (`coverage-ledger-format.md` §2, §3). Every row this walk stands on is a row this
slice claims — a row the parent allocated **here** — so there is nothing for this picker to
delegate. The other four are unchanged, and `covered-here` is what makes this slice PRD-eligible
(§5)."* The remaining four are a strict subset: nothing about them is redefined for a slice.

**Why this walk may not offer it, stated once so no later edit re-adds it.** Delegating a claimed
row to a sibling from inside the slice would leave the parent's ledger saying this slice owns the
row while this slice says the sibling does — the two authorities disagreeing about which BRD owns a
requirement, which is the failure the ledger exists to make impossible
(`coverage-ledger-format.md` §1). It would also point at a sibling whose own inventory holds no row
for that `[BR#n]` at all, and it would put a second hop under the parent's roll-up, which
`coverage-ledger-format.md` §6.1 requires to terminate in one. **No command is named as the way to
re-allocate instead, because none exists**: allocation is this walk and nothing else
(`coverage-ledger-format.md` §3), the walk visits only rows still `unallocated`, and no command
moves a row off a terminal disposition — so re-running `/brd-split` on the parent would find that
row already allocated and report the no-op. The honest answer for an operator who wants the sibling
to own a claimed row is that the allocation stands as the parent's walk recorded it, and the slice
records what it decides to do with it.

Both pickers offer nothing but **terminal** dispositions from
`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3 — five in `full` mode, four in
`allocate-only`, and `unallocated` in neither: it is the one disposition no choice above ever
writes back. §4 states the gate those resolutions open, which this command
**cannot complete while any row stays `unallocated`** — a `Cancel` mid-walk stops the run naming
how many rows remain, but every row already resolved this pass stays written; nothing already
decided is rolled back.

- **Build here** → `disposition: covered-here`. **This is the resolution that makes the whole BRD
  PRD-eligible** (`coverage-ledger-format.md` §5) — it is not an afterthought among the five, it is
  the escape valve that keeps this command able to complete on a BRD nobody actually splits.
  Without it, an unsplit BRD would have no row that could ever leave `unallocated` except by
  deferring, rejecting, or superseding every one of them, and no BRD could ever become eligible for
  a PRD of its own — allocation would deadlock at the very case this command must handle most
  routinely.
- **Assign to a named child BRD** (`split_mode: full` only) → prompt for the child's key: any
  created in Phase 3 this run, or any found already nested under this BRD in Phase 0 step 9. Reject a key that resolves to neither
  and re-prompt — `covered-by` never names a folder that does not exist. Write
  `disposition: covered-by: <CHILD-KEY>`, and add this row's `[BR#n]` to that child's `brd-link.md`
  `claims:` list if it is not already there. **Say what this resolution does and does not settle**:
  it records that `<CHILD-KEY>` owns the row, not that anything is built. The child's own
  `/brd-split` walk decides that, and this run's ledger line reports whichever way it went
  (`coverage-ledger-format.md` §6.1) — a row this walk delegates today can be counted `deferred`,
  `rejected` or `unallocated` on this BRD's next report.
- **Defer to this BRD** → `disposition: deferred-to: <this BRD>` — `<this BRD>` is the slice's own
  key in `allocate-only` mode, exactly as it is the parent's key in `full` mode; the disposition
  always names the BRD the walk is standing on. Prompt for a one-line rationale —
  held for Phase 5's `slices.md`. Deferring is itself an allocation
  (`coverage-ledger-format.md` §3): the point is that the requirement's fate is recorded, not that
  everything must be built now.
- **Reject** → prompt for the `[DEF#n]` that justifies it; it must already exist in the defect log
  that governs this BRD, which is the one place the two modes differ on inheritance: in
  `split_mode: full` that is this BRD's own `brd/brd-defect-log.md`; in `allocate-only` it is the
  **parent's**, because a slice holds no defect log of its own and inherits it
  (`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §2.1, §4). Resolve it there via the `parent:`
  key Phase 0 step 5 already read — **one hop, never a chase**, because the one-level cap makes a
  slice's parent always the BRD that owns the source document. A row with no qualifying defect is
  not rejected this way; resolve or raise the defect first. Write
  `disposition: rejected: [DEF#n]`.
- **Mark superseded** → prompt for the replacing `[BR#n]`; it must already exist in
  `brd/brd-inventory.md`. Write `disposition: superseded-by: [BR#n]`.

**Once every row is resolved, bring each surviving child's three files back into agreement
(`split_mode: full` only — an `allocate-only` run has no child to reconcile and finishes at the
last row).** The
walk is what actually allocates, so a child's `claims:` list, its `brd/brd-inventory.md`, and its
`coverage-ledger.md` are all provisional until this point. For every child still standing — created
this run in Phase 3, or found already nested in Phase 0 step 9 and given a row by this walk —
re-derive all three from the rows this walk ended up resolving `covered-by: <that child>`: the
`claims:` list, the copied inventory rows (`brd-format.md` §2.1), and one `unallocated` ledger row
per claim. **"Re-derive" means reconcile, not rebuild from scratch.** This walk visits only rows
that were `unallocated` when Phase 0 step 8 read the ledger, so the rows a pre-existing child was
already given by an earlier run are not revisited here and must not be dropped: the set each child
ends with is the union of the rows it already claimed and the rows this walk newly resolved to it,
minus only the rows this walk moved off `covered-by: <that child>` to something else. A rebuild
from this walk's resolutions alone would silently strip every earlier claim. A row added to a child
here gains its inventory and ledger rows here.

**A row proposed for a child in Phase 3 but resolved elsewhere loses two of the three, never all
three.** Its `claims:` entry and its copied inventory row are withdrawn together — a slice's
inventory is the subset `claims:` names
(`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §2.1) — and **its ledger row stays**, because a
ledger row is never deleted (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §2). It
stays as an **orphan row**, and this step writes it the terminal disposition this walk settled, so
it never blocks that slice's own §4 gate:

| This walk resolved the row | Write on the withdrawn child's ledger row |
|---|---|
| `covered-by: <another child of this BRD>` | `covered-by: <that child's key>` — a **sibling** of the withdrawn one |
| `covered-here` — this BRD builds it | `covered-by: <this BRD's key>` — the **parent** |
| `deferred-to: <this BRD>` | `covered-by: <this BRD's key>` — the **parent** |
| `rejected: [DEF#n]` | `rejected: [DEF#n]`, verbatim |
| `superseded-by: [BR#n]` | `superseded-by: [BR#n]`, verbatim |

`coverage-ledger-format.md` §3 owns that mapping and says why each row of it is the only honest
record available: the first three all say *another BRD owns this*, which is what `covered-by`
means, while `deferred-to: <this BRD>` written on the slice would falsely book the requirement as
that slice's own live obligation. The last two cite an id of **this** BRD's — the `[DEF#n]` in this
BRD's defect log, the `[BR#n]` in its inventory — which the withdrawn child resolves one hop up like
any other inherited id (`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §2.1, §4), so neither names
something it cannot follow even though it no longer claims the row. **No key written here is ever a
child of the slice** — it is a sibling under this BRD, or this BRD itself — so nothing about this
widens the one-level cap.

Nothing is renumbered — ids are the parent's throughout — and a ledger row an earlier run already
moved off `unallocated` in a pre-existing child is left exactly as it stands: this step adds and
removes `claims:` entries and inventory rows, it **never removes a ledger row**, and it never
rewrites a disposition another run recorded. The orphan rows it writes are only ever rows this run
seeded `unallocated` in Phase 3 step 5 moments earlier, so the two rules never collide.

---

## Phase 4.5 — Resolve every standing empty child

`split_mode: full` only — `allocate-only` has no children and can create none.

**A child claiming nothing is a folder nothing on this route can act on.** It has an empty
`brd-link.md` `claims:` list and, beside it, an empty `brd/brd-inventory.md`. **Its
`coverage-ledger.md` is not necessarily empty**: a child Phase 3 created this run whose every
proposed row the walk then resolved elsewhere keeps one orphan row per withdrawn claim
(`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §2), each already terminal. Those
rows change nothing here — the emptiness this phase acts on is the **claims** list, which is what
`/brd-ground`, `/brd-split` and `/brd-interview` each stop on, and all three of those stops name
**this phase** as the fix, so this phase has to be reachable whenever such a child exists.

**The set is every child standing now, not only the ones this run created.** Two things put a child
in it: a slice keyed and folder-created in Phase 3 whose every proposed `[BR#n]` row ended this walk
resolved to something other than `covered-by: <that child>` — rejected, deferred, superseded, or
reassigned — and a child an *earlier* run left standing, which Phase 0 step 9 marked. **Scoping this
to children created this run was a dead end**: an earlier run's kept-empty child was never in any
later run's set, so the removal option existed only in the single run that created it and never
again. (The Phase 3 cancelled-mid-keying case is distinct and is not in this set — that slice never
got a folder at all.)

**Two pickers, because a child kept by a decision is not the same as one nobody has looked at.**
Read the child's `brd-link.md` for a `reason:` field:

**No `reason:` recorded** — nobody has yet decided this folder should exist while claiming nothing:

```
choices: ["Remove the empty child folder — it claims nothing (Recommended)", "Keep it, and record why (e.g. reserved for related future scope)", "Other… (describe)"]
```

**A `reason:` already recorded** — an earlier run asked this question and the operator answered it.
Do not re-ask it as though it were open, and do not recommend undoing a decision on the strength of
a state that decision deliberately created. Print the recorded reason verbatim beside the list:

```
choices: ["Keep it — the recorded reason still stands (Recommended)", "Remove it now — it claims nothing, and nothing on the route can act on it", "Update the recorded reason", "Other… (describe)"]
```

Removing deletes the child's folder — `brd-link.md`, `brd/brd-inventory.md`, and
`coverage-ledger.md` with it — and drops it from any later run's Phase 0 step 9 enumeration.
**Removing one can never leave a `covered-by` key pointing at nothing**, at either level: a child
this walk gave a row to claims that row and is therefore not in this phase's set, so no ledger
anywhere names a child this phase can remove. Removal is the one place a ledger goes away, and it
takes the whole BRD with it rather than deleting a row from a ledger that survives — which is why
it does not contradict `coverage-ledger-format.md` §2. Keeping it, meanwhile, writes or leaves a
one-line `reason:` field in its `brd-link.md` beside the empty
`claims:` list, and leaves the empty inventory and the ledger — orphan rows and all — in place, so
the folder is still a well-formed BRD rather than a half-built one. Either way, Phase 7's next-step recommendation never
offers to ground a child still claiming nothing.

**What this phase cannot do, said plainly so no stop promises it.** It does not give a child rows.
`covered-by: <child>` is assigned in Phase 4's walk and only against a row that is `unallocated` on
this BRD's ledger, and this command never re-allocates a row that already carries a fate. So on a
parent whose ledger has no `unallocated` row left, removal — or keeping it, knowingly — is the whole
of what this phase offers, and the three stops that name it say exactly that.

---

## Phase 5 — Write `slices.md`

Write `<BRD-dir>/slices.md`:

- **One block per slice** confirmed and keyed in Phases 2–3: its key, its folder, and the
  buildable / blocked / depends-on rationale that put its `[BR#n]` rows together rather than
  elsewhere or left on this BRD.
- **One block per row** Phase 4 resolved `deferred-to: <this BRD>`: its `[BR#n]` and the one-line
  rationale collected for it in Phase 4 — why it is a live obligation of this BRD rather than built
  now.

A run that proposed zero slices still writes `slices.md`, with an explicit note that no slice was
proposed and why, plus every deferral this run recorded — the file is never skipped just because
nothing was carved off this BRD. **An `allocate-only` run reaches that same path from a different
cause** and needs no separate rule: Phase 2 never ran, so it has no slice block to write, and its
`slices.md` carries the Phase 0 step 5 notice as its "why" — this BRD is a slice, no child may be
created below it — followed by its deferral blocks.

Skipped entirely on the no-op path step 10 decides — nothing was walked, so there is nothing new to
rationalize. **Not skipped on the Phase 4.5-only path**, where the ledger had no `unallocated` row
but a standing empty child was resolved: a removal there takes a slice out of the tree, and a
`slices.md` still listing it would be the stale-record failure this route fixes everywhere else. On
that path this phase rewrites only what the removal changed — the removed slice's block goes, with a
one-line note naming the run that removed it — and touches no other block.

---

## Phase 6 — Handoff

Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`phase-handoff.md` §2) with `prefix: brd` (§2.9's
table already lists `brd` as shared by every `/brd-*` command), `feature_folder` as resolved
in Phase 0, `deliverable_paths` = every file this run wrote, updated, or removed under `<BRD-dir>`
— **in `allocate-only` mode that is exactly two, this slice's own `coverage-ledger.md` and
`slices.md`, because Phase 3 never ran** —
(this BRD's own `coverage-ledger.md`, `slices.md`; in `full` mode additionally, for every slice
still standing after Phase 4.5, its folder and all three of the files this run wrote into it — `brd-link.md`,
`brd/brd-inventory.md`, and its own `coverage-ledger.md`, the two that `/brd-ground` will gate and
read when the child re-enters the route; and, for a child Phase 4.5 removed as empty, that folder's
deletion —
§2.3's `-A` staging is what stages a removal, exactly as it does for `/idea`'s or `/update-prd`'s
own deletions — and it stages a Phase 4.5 removal on the Phase 4.5-only path the same way), `title:` — `<BRD-KEY> Split into child BRDs and allocate coverage` in `full` mode,
`<BRD-KEY> Allocate slice coverage` in `allocate-only`, because a pull request titled "split" that
created nothing would misdescribe itself — and `body_facts` = the run mode,
the slice count and keys (`full` only), the walk's resolution tally by disposition, every standing
empty child Phase 4.5 resolved and how, and whether this run was the no-op; emit its §4.1 outcome
line in the final report. The no-op path reaches this phase with nothing staged, so it reports the
`nothing to commit` line rather than opening a pull request. **The Phase 4.5-only path is not that
path**: a removal there stages a folder deletion and the rewritten `slices.md`, and a "keep" that
wrote or updated a `reason:` stages that child's `brd-link.md`, so it opens a pull request like any
other run. A "keep" that changed nothing stages nothing and reports the same `nothing to commit`
line.

---

## Phase 7 — Next steps

**`split_mode: allocate-only` — no child of this slice is reachable, so no grounding of one is
offered.** Phase 3 never ran, so there is no child to ground. This slice's ledger may still hold a
`covered-by` key — an **orphan row** naming a sibling or the parent
(`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §2, §3), which the ledger line below
follows one hop — but neither is a child of this slice and neither is this run's to ground: each is
a BRD standing at its own level, on its own route. And this slice cannot be split further, so
re-running this command on it would only find a
fully-allocated ledger and report the no-op. **The route does not end here.** Its ledger now records
a fate for every requirement it claims, which is exactly the precondition
`/dev-workflows:brd-interview <BRD-KEY>` — the route's fourth command — refuses to start without, so
that is the real next step for this slice and it is offered by name. A slice reaches its own
decisions exactly as its parent does, and the register it writes is its own. If any row reached
`covered-here` the slice is also PRD-eligible
(`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5), which is one of the two tests
`/dev-workflows:create-prd <BRD-KEY> --from-brd` — a switch that **ships** — applies in its own Phase
0. It is still not offered here, and the reason is the register rather than the ledger: that run
seeds its PRD from this slice's `decisions.md`, which `/dev-workflows:brd-interview` has not written
yet, so starting it from here would author a PRD off an allocation and no decisions at all. The route
crosses into the PRD pipeline from `/dev-workflows:brd-reconcile`'s own next-step offer, once the
customer answers are frozen — three commands further on, which is why only the next one is named
here:

```
choices: ["Decide this slice's open questions — /dev-workflows:brd-interview <BRD-KEY> (Recommended) <merge-clause>", "Stop here — this slice's allocation is complete", "Other… (describe)"]
```

**`split_mode: full`** — everything below. Every child folder Phase 3 created, still claiming at
least one `[BR#n]` after Phase 4.5, **re-enters the route at grounding** — a child BRD is graded on its own claimed
requirements exactly as any BRD is, and nothing about being a slice exempts it from that. It can:
Phase 3 gave it the two files `/brd-ground` Phase 0 needs — a `coverage-ledger.md` to gate on and a
`brd/brd-inventory.md` to read — and Phase 6 staged both, so they reach `origin/<default>` with
this run's pull request. Grounding a child is possible only once that pull request has merged, and
`/brd-intake` is never the answer for a child at any point:

```
choices: ["Ground each non-empty child created above, one run per child — /dev-workflows:brd-ground <CHILD-KEY> (Recommended) <merge-clause>", "Decide this BRD's open questions — /dev-workflows:brd-interview <BRD-KEY> <merge-clause>", "Stop here — this BRD's own allocation is complete", "Other… (describe)"]
```

**Every merge clause in this phase is the `<merge-clause>` placeholder**, resolved per
`${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`'s *A next-step offer that names a downstream
command must also name the merge* rule, which owns the §4.1 outcome map and is not restated here.
The rule governs **every** mention of the merge in this phase — both choice arrays and the prose
below — because this command reaches three outcomes that open no pull request: the no-op, the
Phase 4.5-only path where a standing empty child was kept unchanged, and a declined handoff. It is a
placeholder and not an instruction to reword an option, so the arrays are still presented verbatim
per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.

**Say what the child's own route looks like when offering it**: after `/brd-ground <CHILD-KEY>`,
`/brd-split <CHILD-KEY>` runs in `allocate-only` mode (Phase 0 step 5) — it allocates that child's
ledger through four resolutions instead of five, and creates nothing below it. `/brd-ground`'s own
Phase 10 offers exactly that. A child removed, or kept empty with a recorded reason,
for claiming nothing (Phase 4.5) is never offered here — grounding a BRD with no requirement to
ground would have nothing to check a claim against. No children remain at all this run (none were created, or every one created was removed
as empty) → the child-grounding choice is the one that does not apply, stated plainly rather than
omitted. Guidance only — never auto-invokes another command.

**This BRD's own next step is `/dev-workflows:brd-interview <BRD-KEY>`, and it is offered on both
paths.** `/brd-split` is **not** the last command of this route: the walk above just left this
BRD's ledger with no row `unallocated`, which is the one precondition `/brd-interview` refuses to
start without, so a fully-allocated BRD — split or not — goes on to have its open questions decided
rather than stopping. It will not start until this BRD's artifacts are on the specs repo's default
branch, and **exactly which words say so are `<merge-clause>`'s to supply** — this sentence is one of
the mentions that rule governs, not an exception to it. Recording
decisions is `/dev-workflows:brd-interview`, preparing the customer package is
`/dev-workflows:brd-package`, and freezing the returned review is `/dev-workflows:brd-reconcile`;
only the first of those three is the step *after this one*, so only it is offered here. Naming a
child's grounding and this BRD's interview in one list is deliberate — they are different keys, and
an operator who created children has both to do. `--from-brd` on `/create-prd`, `/create-ard` and
`/specify` all **ship**, and none of the three is offered on either path — for the same reason
`/dev-workflows:brd-package` and `/dev-workflows:brd-reconcile` are not, that they sit further down
the route than the step after this one. All three read an altitude seed and this BRD's decision
register out of its folder, `/dev-workflows:brd-interview` is the command that writes that register,
and an `open` or `reopened` record may not be consumed downstream while it is open
(`${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §3) — which is what the interview and
then the customer loop exist to close. `/dev-workflows:brd-reconcile`'s next-step phase is where the
three are offered, each under the precondition its own Phase 0 enforces.

### Context hygiene

Per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`, the resume pointer is written in the
terminal cost phase (Phase 8), after the cost entry and before the commit step. **The offer above
spans both roles, so both branches are printed** (§2's *Next options span both* bullet): grounding a
child created above is a hand to PA, even when the same person does it → run **`/clear`**;
continuing as PM into `/dev-workflows:brd-interview <BRD-KEY>` on this same BRD keeps the context
relevant → run **`/compact`**. An `allocate-only` run created no child, so only the second branch
applies to it. Guidance only — nothing is auto-run.

---

## Phase 8 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 7, NEVER interrupts an earlier phase, and runs on the Phase 0
no-op path step 10 decides exactly as on any other, in either run mode, and on the Phase 4.5-only path too.

**Capture-at-block invariant.** If an EARLIER phase halts on a plugin / skill / command / reference
gap, `emit-block` (`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) fires at that halt
before escalating. None of Phase 0's stops qualify — a missing key, an unresolved BRD, an ungated
or missing grounding deliverable, an inventory carrying no claim at all
(`BRD_SPLIT_EMPTY_INVENTORY`, in either mode — a fact about the customer's document or about what
the parent allocated, never about this plugin), unverified findings, and an unset `$SPECS_PATH` are
environment / sequencing halts, never a plugin capability gap. `BRD_SPLIT_ON_SLICE` is not in that list because it
is **not a stop**: it is the Phase 0 step 5 notice that this run is `allocate-only`, and the run
continues through it.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model:
   `<detection_model>`) with a compact handoff: command `/brd-split`; what was produced (slices
   confirmed and keyed, the ledger walk's tally, `slices.md`); key events (the run mode, the no-op
   path, a cancelled walk with N rows left, a rejected `covered-by` key — or "none"); workarounds; test
   result N/A; project root = the BRD folder.
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /brd-split`, the run's `jira_key` (the `<BRD-KEY>`),
   `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`).
   Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call
   its `emit-cost` entry point with `command: /brd-split`, `phase: brd-to-prd`, `role: pm`, the
   run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only
   notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and
   write/overwrite `<BRD-dir>/dev-workflows/resume.md` now — after the cost entry above, and before
   the commit step below. Redact per §1. Silent.
5. **Commit session artifacts (terminal).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry
   point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths
   inside `$SPECS_PATH`, commits `<BRD-KEY> Add dev-workflows session artifacts (/brd-split)` with
   no `Co-Authored-By` trailer, and pushes to the branch Phase 6's handoff created. It NEVER touches
   a code repo, a docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER
   fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0),
   re-emitting that notice. Hold its §6 outcome line for the final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable
is offered only in Phase 6), and NEVER writes into a code/docs repo or the current working
directory; no user name is ever written.

---

## Final report

Report: the BRD folder; **the run mode from Phase 0 step 5, and in `allocate-only` the
`BRD_SPLIT_ON_SLICE` notice repeated in full** — a notice shown once at Phase 0 of a long
interactive walk is one the operator has scrolled past by the end; whether Phase 0 found this
run a no-op (fully allocated already) or
whether it actually split and/or walked the ledger; the classification and model routing (+ any
Opus degradation); every slice proposed, keyed, and its folder (or that none were proposed and
why — in `allocate-only` that reason is the cap, not an operator choice); any child removed or
kept-with-reason for claiming nothing (Phase 4.5) — including any an earlier run left standing and this run resolved — and which; the ledger
walk's resolution tally by disposition, with every new `covered-by` key and every
`rejected`/`superseded-by` citation named; **every provisional claim this run withdrew** — the
`[BR#n]`, the child it was withdrawn from, and the terminal disposition its orphan row now carries
(Phase 4's reconcile step), so a withdrawal is reported rather than only visible by re-reading two
files; the `slices.md` path (or that it was skipped on the
no-op path); the feedback + cost paths; the `Phase handoff:` outcome line from `handoff-to-main`
(`phase-handoff.md` §4.1); the `Specs repo:` outcome line from `commit-artifacts`
(`specs-repo-git.md` §6); the next-step recommendation; and end with the ledger line, exactly per
`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated, <unresolved> unresolved (<delegated> delegated, <not-built> not built)
```

**Computing it reads one ledger per `covered-by` row**, one hop, from the working tree via
`resolve-brd` (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §2). In `full` mode those are
the children this run created in Phase 3 and reconciled in Phase 4, and any it found already nested
in Phase 0 step 9; in `allocate-only` they are the siblings and the parent this slice's orphan rows
name (`coverage-ledger-format.md` §3), each of which `resolve-brd` finds at its own level.
A ledger that cannot be read there contributes `unresolved`, never `covered`
(`coverage-ledger-format.md` §6.2). **This changes no gate and no precondition of this command**:
Phase 0's stops, the two-part no-op test step 10 decides, and §4's allocation gate are all decided on this
BRD's own rows, before any of this. **In `allocate-only` mode there may still be rows to resolve,
and the hop lands elsewhere.** This walk offers no `covered-by`, so it adds none — but a slice can
already hold **orphan rows** its parent's walk wrote (`coverage-ledger-format.md` §2), each naming
a sibling under the same parent or that parent, and §6.1 resolves those exactly as it resolves a
parent's delegated rows. So a slice's line reports zero delegated only when its parent withdrew
none of its provisional claims — never as a property of being a slice.

`/brd-split` is the only `/brd-*` command that can ever change this line's `unallocated` term as
written on this ledger — a completed run always leaves **its own** rows with none
(`coverage-ledger-format.md` §4: "cannot complete while any row in this BRD's ledger is
`unallocated`"), whether that took an actual walk this run or was already true before it — step 8
reads the ledger and records that, and step 10 is where it becomes the no-op decision. **The reported term can still be non-zero**, and that is the point: a row
this BRD delegated to a child the child has not yet allocated is counted `unallocated` in the line
(`coverage-ledger-format.md` §6.1) while this BRD's own gate stands satisfied. Report it as what it
is — a child with work left, named by the `<CHILD-KEY>` the row delegates to — never as this run
having failed to complete, and never by re-opening the walk over a row that already carries a
terminal disposition.
