---
name: brd-split
description: BRD-splitting workflow (PM phase, third command of the BRD-to-PRD route). Gates on every grounding finding carrying a verifier verdict, proposes candidate slices from the grounded picture (buildable now, blocked, or dependent) - optionally seeded by a verbal <instruction> the operator types after the key, which is resolved against this BRD's own rows and grilled (bounded, <=5, and only where one answer places more than one row) before any slice is proposed. A BRD is a container and is never implementable itself, so this command always produces at least one slice; where nothing clusters, the whole BRD becomes one. Each confirmed slice is keyed and nested as a PRD- folder inside this BRD - the folder its PRD will be authored in - carrying its own brd-link.md, inherited brd/brd-inventory.md, and unallocated coverage-ledger.md. It then walks every unallocated coverage-ledger row one at a time through four resolutions (assign to a named slice, defer to this BRD, reject citing a defect, or mark superseded) until none remain unallocated, and writes slices.md with the rationale for each slice and each deferral. Where one answer is uniform by construction and there is more than one row to save - exactly one slice standing on a parent, or any run on a slice, and two or more rows still unallocated - Phase 4 first offers to write that single disposition across every remaining row in one confirmation, stating each row it would write and letting any of them be held back to the one-at-a-time walk, which stays the default and is what a declined or unparsed answer falls back to. covered-here is not among them on a parent: a parent builds nothing itself. Run on a slice it allocates but does not slice: nesting is capped at one level, so no child is created and the walk offers a different four - covered-here replaces covered-by, which on a slice records a provisional claim this command's own walk on the parent withdrew, and the parent writes it. Existing children are enumerated by a positive test - a subdirectory carrying a brd-link.md whose parent: names this BRD - never by a name match. Re-running is a no-op that prints the ledger only where the ledger is fully allocated AND no child is left standing while claiming nothing; a standing empty child keeps the run alive, because this is the only command that can remove it or keep it against a recorded reason. Offers /brd-interview on the BRD just allocated, and /brd-ground on each non-empty slice, as the next steps.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Split the grounded BRD into slices and allocate every requirement: $ARGUMENTS

`/brd-split` is the **third command of the BRD-to-PRD flow** (PM phase) — it
takes the findings `/brd-ground` verified and forces every `[BR#n]` in this BRD's coverage ledger
to a recorded fate: built here, built by a named child, deferred, rejected, or superseded. This is
the only place that fate is ever decided (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md`
§1) — without this command's gate, a long BRD split across several children could have every child
quietly wave a requirement past, and nothing would notice.

Usage: `/brd-split <BRD-KEY> [<instruction>]`

Runs at either of the two levels `<BRD-KEY>` can name, in one of **two modes** Phase 0 step 5
resolves from the folder itself:

- **`split_mode: full`** — a BRD that owns its source document. Everything below runs: slices are
  proposed, children are keyed and nested, and the ledger walk offers **four** terminal
  resolutions — `covered-by`, `deferred-to`, `rejected`, `superseded-by`. `covered-here` is not one
  of them: a parent BRD is a container and builds nothing itself.
An `<instruction>` is honoured in **both** modes, and what it seeds differs: in `full` mode it seeds
the Phase 2 grouping *and* the Phase 4 walk's per-row recommendation; in `allocate-only`, where
Phase 2 never runs, it seeds the walk alone. That is why a slicing instruction on a slice is a real
invocation rather than an ignored one — `/dev-workflows:brd-split <SLICE-KEY> build the order rows,
defer the rest` is a sentence this command can act on, and the picker it acts on is still the
four-resolution one.

- **`split_mode: allocate-only`** — a slice. Nesting is capped at one level
  (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §6), so **no child may be created below a
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

1. **`<BRD-KEY>` (mandatory).** Parse the first non-flag token; validate with `key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1). If absent or invalid, stop:
   `BRD_SPLIT_NEEDS_KEY: /brd-split needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$) — re-run '/dev-workflows:brd-split <KEY>'.`
1a. **`<instruction>` (optional).** Every **non-flag** token after the key, joined verbatim, is a
   slicing instruction in the operator's own words — `cover orders and measurements in the first
   iteration`, `slice everything EPIC-008 still holds that no child covers`. Absent → this command
   behaves exactly as it did before the switch existed, on every path below; nothing in it is
   conditional on an instruction being given except where a phase says so. This command parses no
   flags today, so "non-flag tokens after the key" and "everything after the key" currently pick out
   the same string — it is written the first way because the second stops being true the moment a
   flag is added, and `commands/design.md` Phase 0 already strips its own flag before classifying
   for exactly that reason. The instruction is **never validated against anything**: it is prose, and
   what it means is settled in Phase 1.5 against this BRD's own rows, never by pattern.
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
4. **Resolve the BRD folder.** `resolve-address <BRD-KEY>` (`addressing.md` §3), which searches
   `specifications/` and the levels below it that `resolve-address` searches (three, per `addressing.md` §3) (§2 step 2) — either level a `<BRD-KEY>` can name — a BRD folder directly under `specifications/`, or the `PRD-` folder of a slice inside it. Absent → stop, without asserting which command would create it, because nothing on disk
   says whether this key names a BRD with a source document or a slice of one:
   `BRD_SPLIT_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /dev-workflows:brd-split on its parent.`
5. **Resolve the run mode.** Read the resolved folder's `brd-link.md` and branch on its `parent:`
   field — the same signal `/brd-ground` Phase 0 uses to tell a slice from a root, and the only
   reliable one: a key's segment count is a naming convention, never a depth declaration
   (`addressing.md` §1).
   - **No `brd-link.md`, or one with no `parent:`** → this BRD owns its source document. Set
     `split_mode: full`; carry it for the whole run. Nothing is announced — this is the ordinary
     case.
   - **`parent: <PARENT-KEY>` present** → this is a slice. Set `split_mode: allocate-only`, carry
     it for the whole run, and **emit this notice now, and again in the final report** — a run that
     silently skips two phases and drops a resolution from its own picker is worse than one that
     says so:
     `BRD_SPLIT_ON_SLICE (notice, not a stop): <BRD-KEY> is a slice of <PARENT-KEY>. This run allocates <BRD-KEY>'s ledger but creates no children: nesting is capped at one level, so Phases 2-3 are skipped and no child BRD can exist below a slice. The Phase 4 walk offers its own four resolutions — the same count as full mode, a different set: covered-by is not one this walk can choose — on a slice it names a sibling or the parent, records a provisional claim the parent's own walk withdrew, and is written by that walk, so every row carrying it is already terminal here.`
   **This is a cap on nesting, not on allocation.** A grandchild would inherit `brd/source/` and a
   defect log from a parent that holds neither, so its inventory header would name a path that does
   not exist (`addressing.md` §6, `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §2.1) — that
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
   is no `covered-by` target for Phase 4 to offer, which is the mechanical reason that picker's four
   choices are a different four from the parent's, with `covered-here` where `covered-by` stands. A slice's own `covered-by` rows name a sibling or the parent and
   are written by the parent's walk, never chosen here
   (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3); this step never looks for
   them and never needs to, because they are terminal already. In `full` mode: list every immediate subdirectory of `<BRD-dir>` that
   **contains a `brd-link.md` carrying a `parent:` field naming this BRD**. Each match is a child a
   previous `/brd-split` run already created, nested per `addressing.md` §6, and remains a valid
   `covered-by` target in Phase 4 even when this run proposes no new slice of its own.

   **A positive test, not a name match.** Matching a subdirectory by name and then reading an
   absent `brd-link.md` as an empty `claims:` list is what let a folder that is not a child be
   counted as one: it reads as a standing empty child, Phase 4.5 offers to **remove** it, and
   `epic.md`, `specification.md` and `design.md` go with the folder. Requiring the file to exist and
   to name this BRD makes the inference impossible rather than merely unlikely. It also needs no
   exclusion list — `brd/`, `grounding/` and `dev-workflows/` carry no `brd-link.md`, so the test
   excludes them by construction rather than by an enumeration that a new sibling directory would
   silently fall out of. **Read each one's `brd-link.md`
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
      commit, and the Final Report's ledger line. **A slicing instruction does not make this run
      not-a-no-op**, and it is not a reason to walk a row that already carries a fate: Phase 1.5
      skips on an empty unallocated set and reports the instruction unused, naming this path. This is the path a fully-allocated slice takes, and
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
  authoring_model: <= current_model>   # Phase 1.5's reading and bounded grill, and Phase 4's walk — session model, not a delegated subagent
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

`/brd-split` dispatches no grounding or review agent of its own — every finding it reads was
already independently verified by `/brd-ground`'s `grounding-verifier` pass (`brd-ground.md` Phase 7) — so
`detection_model` here exists only for the terminal `impl-maintenance` dispatch. **The grilling
technique's fetch-a-fact clause does not change that here**, and the reason is what the clause is
bounded to: it fires where a fact needs *more than a read*, and every fact Phase 1.5 needs — a row's
`text`, its `source_anchor`, its disposition — is a local read of files this run already has open.
Nothing in the instruction-reading step reaches for something a sweep would have to find, so no
dispatch arises and the comment above stays literally true. **`authoring_model`
is recorded and is not a dispatch**: Phase 1.5 reads a slicing instruction against this BRD's rows and
may grill the residue, and Phase 4 walks the ledger — all in the session, the same way
`/brd-intake` records its own interactive defect walk. Recording it matters because the reading is a
judgement about the operator's words, so a run that made it on a degraded model should say which
model made it. If no Opus
resolves for `current_model`, degrade to best-available + record in `notes` and the final report —
never hard-block.

---

## Phase 1.5 — Read the slicing instruction

**Skipped entirely when Phase 0 step 1a found no instruction**: a run without one reaches Phase 2
exactly as it always has, and nothing below fires. **Runs in both modes**, unlike Phase 2 — a
slice has no children to propose, but its walk takes recommendations from an instruction just as a
parent's does (Phase 4), which is what makes `/dev-workflows:brd-split <SLICE-KEY> <instruction>` a
real invocation rather than an ignored one.

**Also skipped where no row is `unallocated`**, whatever Phase 0 step 10 decided — the no-op path and
the Phase 4.5-only path both reach here with nothing to place, since this phase places unallocated
rows and only those. Report the instruction as **unused, naming which path swallowed it**, rather
than running a grill over an empty residue: an instruction typed and then silently discarded is
indistinguishable from one the command failed to parse, and on the Phase 4.5-only path the operator
has every reason to expect it did something. Neither path is an error, and neither becomes one for
having been given an instruction.

This phase produces one thing: a **placement** — for each `[BR#n]` still `unallocated`, either what
the instruction puts it in (a **group** in `full` mode, where groups become slices; a **disposition**
in `allocate-only`, where there is nothing to group into) or nothing. Everything downstream reads
that placement and never re-reads the instruction, so an instruction is interpreted exactly once.

### Step A — resolve what the instruction determines, asking nothing

Read each unallocated row's `text` and `source_anchor` from `brd/brd-inventory.md` and place every
row the instruction plainly determines. **This step raises no prompt of any kind.** It is
`${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md`'s fact-vs-decision split applied before the
grill rather than inside it: a question answerable from the artifact is not a question, and a row
whose text names what the instruction names is placed, not asked about.

An instruction that is a **set operation over the ledger** — *everything no child covers*, *the rest*,
*what is left* — resolves entirely here, against `coverage-ledger.md`'s `disposition` column, and
Step B then asks nothing at all. Say so in the report rather than leaving a silent grill looking like
a skipped one.

### Step B — grill only the residue, and only where an answer places more than one row

The residue is every unallocated row Step A could not place. Put questions to the operator from it
one at a time, each with a recommended answer, per that reference's mechanics — which are cited, not
restated here. This command's **depth is bounded**, and the bound has two parts:

1. **The value test, which is the real gate: ask only where one answer places more than one row.**
   A question that disambiguates a single row is worse than useless here. Phase 4 resolves every
   unallocated row regardless — one at a time in its Step 2 walk, or inside the Step 1 offer where
   that fires — so the row is already going to be settled, at a cost of one prompt or of none;
   spending a turn now to save at most that is a pure cost, and it is paid before the operator has
   seen any output at all. What earns a question is a **terminology decision that moves several rows at
   once**: *the BRD uses "form" for an order record and for a compliance artifact — which is meant
   in these six rows?* That is the reference's *force terminology precision* rule, and it is the
   whole reason this grill exists.
2. **A hard cap of five questions**, after which the phase stops whatever remains. The cap is
   stated because `grilling-technique.md` defines bounded depth as "a capped set … then stop", so a
   caller declaring bounded owes a number; and it is **five** rather than ten because the residue
   here has a free fallback that `/idea`'s does not.

**That difference is worth stating, because it is what sizes the cap.** In `/idea` an unanswered
bounded question becomes a `[NEEDS CLARIFICATION]` marker that ships inside the artifact, so the cap
buys a hole in the deliverable and ≤10 earns its length. Here an unplaced row simply reaches Phase 4
without a recommendation, in a phase that was going to settle it anyway — and it can still be moved
by hand in Phase 2's own edit/merge/move picker. Two downstream channels catch the same row for free,
so past the first few questions the grill is the most expensive of the three ways to place a row and
the only one that runs before anything is visible.

**A row still unplaced when this phase ends is left unclustered**, and that is a resolution rather
than a failure: it is exactly the fate Phase 2 already gives a row nothing clusters with, and Phase 4
settles it with no recommendation of its own — walked on a blank picker, or carried in the Step 1
offer's set like any other row this reading did not place elsewhere — which is this command's
behaviour on every run that was given no instruction at all. **No new marker, no new record, and nothing carried forward** — inventing a
`[NEEDS CLARIFICATION]`-style marker for it would put a token into a ledger and an inventory whose
field sets are fixed elsewhere (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §2,
`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §2).

**Nothing in this phase writes.** It settles a reading; Phase 2 proposes from it, Phase 4 recommends
from it, and Phase 5 records it. A `Cancel` here stops the run with nothing written, exactly as a
`Cancel` in Phase 2 does.

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

**With a Phase 1.5 placement, the instruction proposes and the grounded picture constrains.** The
placement decides which rows group together — it is a *business* grouping and it legitimately cuts
across the buildable / blocked / depends-on axis above, which is the point of typing one. What the
grounded picture keeps is a veto the operator has to overrule **explicitly**: where a placement puts
a row carrying `NOT-PROVABLE`, `REWRITTEN`, `FALSE-FRIEND`, or `horizon: will-change` into a group
whose other rows are buildable now, name **those rows** — each with the verdict or the prerequisite
decision that makes it not buildable — and settle it before the slice is confirmed:

```
choices: ["Include them anyway — this slice carries rows that are not buildable yet", "Hold them back — they return to the ledger walk unclustered", "Decide row by row", "Cancel"]
```

No option carries a `(Recommended)` marker, per the *When no option is safe to recommend* guidance
in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`: whether a slice should carry a blocked row
is a delivery judgement about this iteration, and the run has just been told in the operator's own
words that they want these rows together. **The operator's grouping wins where they confirm it, and
never wins silently** — a slice that quietly mixed a `NOT-PROVABLE` row in with buildable ones would
discard the one signal that makes a slice worth carving, and would do it at the moment the operator
was least able to notice. Rows held back are unclustered, not rejected: Phase 4 walks them like any
other. Where a placement raises no such conflict, this list is not shown.

**A row Phase 1.5 left unplaced clusters exactly as it always did** — by the grounded lines above.
An instruction narrows what the run has to guess at; it never turns the rest of the BRD into a
residue nothing groups.

Present the candidate slices (each: a short working name, its `[BR#n]` rows, and the one-line
rationale that put them together — the buildable/blocked/depends-on reading, or, for a group the
instruction placed, what in the instruction placed it) and confirm before anything is created:

```
choices: ["Accept these slices as proposed (Recommended)", "Edit one or more slices (rename, merge, move a row)", "Replace with a different slice list entirely", "Make this whole BRD one slice"]
```

**Zero confirmed slices is not an outcome this phase can reach.** A BRD is a container, never
something implementable in its own right, so **this command always produces at least one slice** —
and the degenerate case has an honest answer rather than an escape valve: where nothing clusters,
the whole BRD becomes one slice, which is what *"Make this whole BRD one slice"* selects. Editing
the list down to nothing re-asks this question rather than proceeding.

**One exception, and Phase 0 step 9 already states it: a parent that already has children.** There the
run's job may be to allocate rows to slices that exist rather than to carve new ones — step 9 says an
existing child "remains a valid `covered-by` target in Phase 4 even when this run proposes no new slice
of its own". Where at least one child already stands, **"propose no new slice — allocate to the
existing children" is an available answer** and the walk proceeds to Phase 4 on the children already
there. Without it the operator must confirm a slice they do not want, watch the walk assign it nothing,
and then accept Phase 4.5's offer to remove the folder Phase 3 just created — cancelling mid-key-taking
to get the slice dropped is a workaround, not a stated behaviour. The rule that a BRD always yields at
least one slice is unchanged: on a **first** split there are no children, so the degenerate case still
resolves to *"Make this whole BRD one slice"*.

**Why a container, rather than letting a BRD hold its own PRD** — the namespace argument now lives
in `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5, the authority every PRD-eligibility
refusal cites, and is not restated here: a BRD that could be split *and* be PRD-eligible itself would
hold PRD folders and its own Epic folders as siblings, which `addressing.md` §2's second invariant
forbids and which Phase 0 step 9 would then have to tell apart. What this phase contributes to it is
the guarantee: one slice always existing means the requirements always land somewhere a PRD can be
written, and that somewhere is always one level down.

---

## Phase 3 — Key and nest each confirmed slice

**Skipped entirely in `split_mode: allocate-only`** — this phase is the child creation the one-level
cap forbids, and it is the only phase that is forbidden rather than merely empty.

For every slice Phase 2 confirmed:

1. **Take a key.** Propose a default of the parent's key plus the next unused two-digit segment
   (e.g. `<PARENT-KEY>-01`, `<PARENT-KEY>-02`, …, skipping any segment an existing child from
   Phase 0 step 9 already uses) and let the operator accept it or supply their own. Validate
   whatever is used with `key-valid` (`addressing.md` §1); an invalid key is re-prompted,
   never silently coerced.
2. **Create the folder inside the folder this run resolved**, per `addressing.md` §6 — the folder a
   slice gets **is** the folder its PRD will be authored in, and it is never a sibling of its BRD.
   On a current tree that is
   `specifications/BRD-<PARENT-KEY>-<parent-slug>/PRD-<CHILD-KEY>-<child-slug>/`, the parent
   carrying the `BRD-` prefix `/brd-intake` writes (`commands/brd-intake.md` Phase 0 step 7,
   `addressing.md` §2). `<child-slug>` is a kebab of the slice's working name from Phase 2.

   **The parent half of that path is the resolved folder's actual name, never a path re-derived
   from `<PARENT-KEY>`.** A parent that resolved through `addressing.md` §5's legacy fallback is
   unprefixed on disk, and writing the prefixed form for it would create a second, empty `BRD-`
   folder beside it and orphan the slice inside it — the parent's inventory, ledger and defect log
   would all be one directory away. The child is created with the `PRD-` prefix either way: §5's
   fallback honors a legacy folder that already exists and never proposes one, and a command that
   creates the folder it did not find still creates it with the §2 prefix (`addressing.md` §7,
   *Adoption is additive*).

   **It is a `PRD-` folder from the moment it is created, before any PRD exists in it.** A slice
   exists precisely to become a PRD; giving it a `BRD-` directory of its own with a `PRD-` directory
   nested inside holding one file bought a level of tree for nothing. The prefix declares what the
   folder is for, which is the same act `/idea` performs when it takes its key up front. What
   distinguishes this folder from an idea-route PRD folder is its `brd-link.md` — the positive test
   Phase 0 step 9 applies, not the prefix.
3. **Write the child's `brd-link.md`**: `kind: brd`, `key: <CHILD-KEY>`, `parent: <BRD-KEY>` and
   `claims:` — the first two are how the new folder asserts its own identity from the moment it
   exists (`addressing.md` §4), and `brd-link.md` is the folder's only artifact until Phase 3 step 4
   writes its inventory. Then the slice's `[BR#n]`
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
   That resolution is always one hop, never a chase: the cap in `addressing.md` §6 makes this
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
what it is. It buys the child no resolution depth and needs none: `resolve-address` searches
`specifications/` and the levels below it that `resolve-address` searches (three, per `addressing.md` §3), which is where this folder sits regardless of how
many segments its key carries (`addressing.md` §1, §3). So an operator-supplied key with no
additional segment resolves exactly as the default does, and nothing about either choice makes the
child sliceable — no key shape lifts the one-level cap (§3).

---

## Phase 4 — Walk the ledger

**This phase runs in both modes** — it is the allocation walk, and allocation is not what the
one-level cap restricts. What differs is the size of the picker.

**Three steps, in this order:** the uniform-answer offer (Step 1 — conditional, and skipped on most
runs), the walk itself (Step 2 — the default, and the reason this phase exists), and the reconcile
that follows it (Step 3 — `split_mode: full` only).

### Step 1 — the uniform-answer offer, taken once before the first row

**Skipped unless the firing condition below holds. Where it is skipped, nothing in Step 2 changes,
and where it is declined, nothing is written by it.**

**Why it exists.** A BRD is a container, so this command always produces at least one slice
(Phase 2) — and the whole of a BRD becoming *one* slice is the ordinary shape of this route rather
than a corner of it. In that shape every row on the parent takes `covered-by: <the one slice>`, and
every row on that slice then takes `covered-here`: two walks whose answer the shape of the split
settled before either opened a ledger. Asking once per row for an answer the run can already state
is the defect `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` names under *When a choice list
fires* — a list written for a question whose answer is already determined spends a user turn on a
formality. A forty-row BRD resolved to a single slice costs **eighty** prompts across the two runs
without this step and **two** with it.

**It fires only where the answer is uniform by construction — never merely where it would be
convenient.** Both conditions in its row must hold:

| Mode | Fires when |
|---|---|
| `full` | **exactly one** slice stands as a `covered-by` target — the union of the children Phase 3 keyed this run and the children Phase 0 step 9 enumerated is a single folder — **and** two or more rows are still `unallocated` |
| `allocate-only` | **two or more rows are in the set this step would actually offer** — every row still `unallocated`, *minus* any row Phase 1.5's reading already placed on a different disposition. Counting the raw `unallocated` set instead fires the offer on a set of one or zero: an instruction like *"defer everything except the login flow"* leaves five rows `unallocated` while Phase 1.5 places four of them on `deferred-to`, so the condition saw five and the step rendered *"Write `covered-here` on all 1 rows now"* — the degenerate prompt the rule below says is skipped |

**Why each condition is the condition.** With one standing slice, `covered-by` has exactly one legal
argument, so the offer picks no target on the operator's behalf: what is uniform by construction is
the **key**, not the disposition — which is exactly why this offer is refusable per row rather than
a completion. **With two or more slices standing it does not fire at all**, and that is not a
limitation for a later edit to generalise away: which slice owns a row is the per-row judgement this
walk exists to take, and no single confirmation could name a target without taking it for the
operator. In `allocate-only` mode every row this walk stands on is a row the parent allocated
**here** — which is why that picker already carries a standing
`(Recommended — this slice was carved out to build these rows)` on `covered-here` for every row it
shows; the offer is that same recommendation made once instead of N times, not a new claim. And
below two rows there is nothing to save — one offer replacing one prompt — so the step is skipped
rather than shown, by the same *When a choice list fires* rule.

**Its vocabulary is two dispositions, and that is structural rather than a preference.** The offer
writes `covered-by: <CHILD-KEY>` (`full`) or `covered-here` (`allocate-only`) and nothing else. The
other three each need a per-row fact it cannot supply and must not invent: `deferred-to` needs the
one-line rationale Phase 5 writes into `slices.md`, `rejected` needs the `[DEF#n]` that justifies
it, and `superseded-by` needs the `[BR#n]` that replaced it. A bulk form of any of the three would
either skip a prompt that carries content or copy one row's reason onto rows that do not share it.

**The set it offers to write.** Every row still `unallocated`, **minus** any row Phase 1.5's reading
placed on a *different* disposition. Those keep the recommendation the instruction earned them (the
`<recommended>` table in Step 2) and are walked one at a time. An instruction the operator typed is
not something a shortcut may quietly overrule, so the offer **names** those rows and what the
instruction placed each on, rather than absorbing them.

**What the offer states before anything is written**, in the prose beside the list:

1. the disposition it will write, spelled out — `covered-by: <CHILD-KEY>` with the key filled in, or
   `covered-here`;
2. the count, and every `[BR#n]` in the set with the first line of its `text`, so a row that does
   not belong is visible without opening the ledger;
3. in `full` mode, that it also adds each of those `[BR#n]` to `<CHILD-KEY>`'s `brd-link.md`
   `claims:` list — the same second write Step 2's **Assign to a named slice** bullet performs, not
   an extra one;
4. every row it will **not** write, and why — each row Phase 1.5 placed elsewhere, named with its
   placement;
5. that Step 3's reconcile, Phase 4.5 and Phase 6 all run exactly as they would after a
   one-at-a-time walk, over the same files;
6. that it settles nothing beyond those N rows: a bulk write is Step 2's per-row write taken N times
   behind one confirmation — the same disposition vocabulary
   (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3) and the same gate (§4), with no
   row reaching a terminal disposition by a route that file does not already own.

**The list.** `<N>`, `<CHILD-KEY>` and the disposition are substituted exactly as `<BRD-KEY>` and
`<recommended>` are substituted elsewhere in this phase; the array is otherwise presented verbatim
(`escalation-rules.md`, *Choice lists are presented verbatim*), and it is three options, inside §0's
two-to-four cap, with the free-text answer the harness supplies handled below.

**`split_mode: full`:**

```
choices: ["Write covered-by: <CHILD-KEY> on all <N> rows now", "Write it on all but the rows I name — I'll walk those one at a time", "Walk every remaining row one at a time — decide each row"]
```

**`split_mode: allocate-only`:**

```
choices: ["Write covered-here on all <N> rows now (Recommended — every row this walk stands on is a row the parent allocated here, which is the marker the per-row picker carries on each of them, made once)", "Write it on all but the rows I name — I'll walk those one at a time", "Walk every remaining row one at a time — decide each row"]
```

**Why one list carries a marker and the other does not** — the same rule both times, applied to what
each picker already says. The `allocate-only` picker recommends `covered-here` on every row it
shows, unconditionally and for a reason no instruction changes, so recommending it once here is that
marker printed once: a reason annotation, honoured verbatim, of the kind `escalation-rules.md`
admits explicitly. The `full` picker carries **no** marker unless an instruction placed the row,
because which resolution is right is a fact about the row in front of the operator — and there being
one slice does not change that. So the `full` offer carries none either, and says so beside the
list: *no option here is recommended — this run knows which slice a delegated row would go to, not
whether this row is one to delegate.* That is `escalation-rules.md`'s *When no option is safe to
recommend*, not an omission.

**Answering.**

- **Option 1** — write the whole set (below), then continue into Step 2 with only the excluded rows
  left to walk, if there are any.
- **Option 2** — **one** further prompt, free text, not one per row: ask which `[BR#n]` ids to hold
  back, restating in that prompt the disposition every row *not* named will receive. Validate each
  id against the set: one that is not in it — unknown, already terminal, or already excluded — is
  named back and the prompt repeated **once**, never silently dropped and never written. **Every
  answer this prompt cannot use falls the same way — to option 3, the walk.** An **empty** answer
  falls there, and so does a **second** unusable answer after that one re-prompt: an operator who
  opened option 2 to name exceptions and then named none this step could read has given the least
  determinate answer there is, which is the furthest thing from a mandate to write every row. A
  stray Enter is the input nearest to unparseable, and it must not be the one input that takes the
  maximal write. Otherwise write the reduced set and walk the named rows in Step 2. **This is what
  keeps a partial answer cheap**: three exceptions out of forty cost one offer, one naming prompt
  and three row prompts, not forty.
- **Option 3** — write nothing here. Step 2 runs over every row exactly as it does on a run where
  this step never fired.
- **A free-text answer** naming `[BR#n]` ids is read as option 2's answer and validated the same
  way; anything else falls through to option 3. **The fall-through direction is the walk, uniformly
  and at both prompts** — this one and option 2's naming prompt — which is what stops an answer this
  step could not read from writing a row nobody answered for. No answer to any prompt of this step
  resolves to option 1 except option 1 itself.

**Writing the set.** For each row in it, write exactly what Step 2's bullet for that disposition
writes — `disposition: covered-by: <CHILD-KEY>` plus the `claims:` entry, or
`disposition: covered-here` — row by row in the file, so an interrupted run leaves every row either
`unallocated` or terminal and none half-written. Ids are the parent's throughout, and nothing else
about a row changes. Then report the rows written, under the one disposition, and the rows held back
with why each was held back — named by the operator, or placed elsewhere by the instruction.

**A row held back is walked, not dropped.** It is still `unallocated`, and §4's gate still blocks
this command until Step 2 gives it a terminal disposition. A `Cancel` during that walk stops the run
naming how many rows remain, and every row this step already wrote stays written — exactly as a row
resolved early in a one-at-a-time walk does.

### Step 2 — the walk

For every row in `coverage-ledger.md` still `disposition: unallocated` when this step opens — every
row on a run where Step 1 did not fire or was declined, and only the rows Step 1 held back on a run
where it wrote — present it **one at a time, never batched**, via `AskUserQuestion` — quoting its
`id`, `text`, `defects`, and `evidence` so the operator has everything needed without opening the
file. **This is the default, and Step 1 does not displace it**: per-row judgement is what this walk
is for, and no row is ever written in bulk without an offer that named it being shown and answered.

**`split_mode: full` — four resolutions:**

```
choices: ["Assign to a named slice — covered-by<recommended>", "Defer to this BRD — deferred-to (a real allocation, not a shortcut)<recommended>", "Reject — citing a [DEF#n]<recommended>", "Mark superseded by another [BR#n]<recommended>"]
```

**No option on that picker carries a `(Recommended)` marker, and the omission is required rather
than stylistic.** Which resolution is right is a fact about the row in front of the operator — a row
that clusters into a slice takes `covered-by`, one this BRD still owes takes `deferred-to`, one the
customer has withdrawn takes `rejected` — and the list is shown once per row, so no marker could be
true across the runs that reach it. `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` covers
exactly this under *When no option is safe to recommend*: omit the marker and say so in prose beside
the list. **A conditional marker is not the alternative.** `(Recommended when nothing clusters)`
reads as guidance and is malformed by that file's *The `(Recommended)` marker is unconditional*
rule — it hands the operator the gate this phase was supposed to evaluate, and an orchestrator that
must present the list verbatim cannot honour it either way. The condition belongs in the option's own
text, which is where it now sits. Say beside the list that **`covered-here` is not among these four**
and why — a parent BRD is a container and builds nothing itself (Phase 2), so a row that must be
built goes to a slice — and that `deferred-to` is a real allocation rather than a way of deferring
the choice itself.

**`split_mode: allocate-only` — four as well**, but **a different four**: `covered-by` is absent and
`covered-here` is present, which is the exact mirror of the `full` picker. State the reason beside
the list, so an operator who sees a different set than the last run is told why rather than left to
notice it.
This picker *does* recommend an option, and the asymmetry is the rule working rather than an
inconsistency: on a slice every row the walk stands on is a row the parent allocated **here**, so
`covered-here` is unconditionally the expected answer and the marker is a plain reason annotation
(`(Recommended — <why>)`), not a condition. It reaches the option through the same `<recommended>`
placeholder the `full` picker uses, for the reason given below the table:

```
choices: ["Build here — covered-here<recommended>", "Defer to this slice — deferred-to (a real allocation, not a shortcut)<recommended>", "Reject — citing a [DEF#n] in the parent's defect log<recommended>", "Mark superseded by another [BR#n]<recommended>"]
```

State once, before the first row of an `allocate-only` walk: *"`covered-by` is not offered here.
On this slice it would name a sibling under the same parent, or that parent — never a child, since
nesting is capped at one level and no child can exist below a slice — only its Epics
(`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §6). It is written by the **parent's** walk,
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

**`<recommended>` is a placeholder this run resolves per row, and resolving it is not a rewording.**
It is substituted in the option strings exactly as `<BRD-KEY>` and `<merge-clause>` are, so the array
is still presented verbatim per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`'s *Choice
lists are presented verbatim* — a command that instead told the orchestrator to *adjust the wording*
of an option would be contradicting that convention, which is why the variation lives in a
placeholder (`${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` states the same for its own).
It resolves, for each row:

| This row's state | `<recommended>` resolves to |
|---|---|
| Phase 1.5 placed it, and Phase 2 keyed that group into a child | ` (Recommended — <what in the instruction placed it>)` on **`covered-by`**, and the empty string on every other option |
| Phase 1.5 placed it into a group that produced no child — the operator declined the slice, or the instruction named a disposition rather than a grouping | ` (Recommended — <what in the instruction placed it>)` on the option that disposition names, and the empty string on the others |
| Phase 1.5 left it unplaced, or this run was given no instruction | the **empty string on every option** in the `full` picker — exactly the picker this command has always shown. In the `allocate-only` picker it resolves to ` (Recommended — this slice was carved out to build these rows)` on **`covered-here`** and the empty string on the rest, which is that picker's standing default (below) |

**The `allocate-only` picker's standing marker is carried by the same placeholder, and that is why
there is one placeholder and not two.** That picker has always recommended `covered-here`, for a
reason that does not depend on any instruction: on a slice every row the walk stands on is a row the
parent allocated **here**. Writing that marker literally into the option *and* adding a placeholder
beside it would put two `(Recommended — …)` annotations in one list the moment an instruction placed
the row — or, worse, one on `covered-here` and another on `deferred-to`, each contradicting the
other. Folding the default into the placeholder's own resolution avoids that without the
orchestrator suppressing anything: a marker is never removed from a written option, because the
option never carries a written marker. **The no-instruction run is unchanged** — the placeholder
resolves to the same sentence that used to be typed there.

**The reason is carried, not just the marker.** `(Recommended — <why>)` is a reason annotation, which
`escalation-rules.md` admits explicitly; a bare `(Recommended)` here would assert a recommendation
whose only basis is a sentence the operator typed several phases ago and can no longer see. Naming
what in the instruction placed the row is what lets them disagree with it on this row without
abandoning the instruction.

**This is not a reversal of the markerless picker.** A `(Recommended when …)` marker was removed from
the `full` picker precisely because it printed its own condition for the operator to evaluate, which
that file calls malformed. A marker **this command computes per row and prints bare** is the fix that
same rule prescribes — and it becomes available only because there is now an instruction to compute
it from. On a run with no instruction there is still no basis for one, and the third row above is
what keeps that run's picker byte-for-byte what it was.

**A recommendation is not batching, and Step 1 is not a recommendation.** Resolving `<recommended>`
changes what a prompt says, never how many rows it carries: rows in this step are presented **one at
a time**, unchanged; `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` asks for a recommended
answer on every question for the same reason this phase carries one — an operator reacting to a
proposal is doing something different from an operator facing a blank picker, and neither is the
same as being handed five rows at once. Step 1 *does* hand the operator many rows at once, which is
why it is a separate, conditional offer that names every row it would write and can be refused row
by row, rather than a wording change inside this picker.

Both pickers offer nothing but **terminal** dispositions from
`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3 — four in each mode, though **a
different four** (`full` offers `covered-by`, `allocate-only` offers `covered-here`), and
`unallocated` in neither: it is the one disposition no choice above ever
writes back. §4 states the gate those resolutions open, which this command
**cannot complete while any row stays `unallocated`** — a `Cancel` mid-walk stops the run naming
how many rows remain, but every row already resolved this pass stays written, including any Step 1
wrote; nothing already decided is rolled back.

- **Build here** → `disposition: covered-here`. **`split_mode: allocate-only` only** — it is what
  makes a slice PRD-eligible (`coverage-ledger-format.md` §5), and it is the ordinary landing for
  every row a slice's walk stands on, because the parent allocated those rows *here*.

  **It is not offered in `full` mode, and the escape valve it used to be is gone with it.** A parent
  BRD is a container and holds no PRD of its own, so there is no "build it here" for a parent to
  choose; a row that must be built goes to a slice, and this command always produces at least one
  (Phase 2). What that removes is the old completion path for a BRD nobody split — which is no
  longer a state this command can leave behind. Every other resolution is unchanged, in both modes.
- **Assign to a named slice** (`split_mode: full` only) → prompt for the slice's key: any
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

### Step 3 — reconcile each surviving child

**Once every row is resolved — by Step 1, by Step 2, or by both — bring each surviving child's three
files back into agreement (`split_mode: full` only — an `allocate-only` run has no child to
reconcile and finishes at the last row).** The
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
choices: ["Remove the empty child folder — it claims nothing (Recommended)", "Keep it, and record why (e.g. reserved for related future scope)"]
```

**A `reason:` already recorded** — an earlier run asked this question and the operator answered it.
Do not re-ask it as though it were open, and do not recommend undoing a decision on the strength of
a state that decision deliberately created. Print the recorded reason verbatim beside the list:

```
choices: ["Keep it — the recorded reason still stands (Recommended)", "Remove it now — it claims nothing, and nothing on the route can act on it", "Update the recorded reason"]
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

- **One block for the bulk resolution, when Phase 4's Step 1 offer fired and was taken** — the
  disposition it wrote, the `[BR#n]` rows it wrote it on, and the rows held back with why each was
  held back (named by the operator, or placed elsewhere by the instruction). A later reader needs to
  know whether forty rows were judged one at a time or confirmed once, and the ledger cannot say:
  the rows read identically either way. Where the offer fired and was declined, record that in one
  line too — a decision to walk is a decision.

- **One block for the instruction, when this run was given one** — the instruction **verbatim**, and
  how it was read: which `[BR#n]` rows Step A placed directly, which the Step B grill settled and by
  what terminology decision, and which it could not place and left unclustered. Record it whether or
  not it produced a slice: a reading that produced nothing is the one a later reader most needs, and
  the verbatim text is what lets them see whether the instruction or the reading was wrong. Where the
  Phase 2 conflict list fired, record which rows it named and which way it went.

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
still standing after Phase 4.5, the three files this run wrote into it — `brd-link.md`,
`brd/brd-inventory.md`, and its own `coverage-ledger.md`, the two that `/brd-ground` will gate and
read when the child re-enters the route; and, for a child Phase 4.5 removed as empty, **those same
three paths again, named individually** —

**Name files, never the folder.** §2.9 requires one literal repo-relative path each and §2.3 classifies
a directory as OTHER, silently. On a removal that failure is invisible and total: `git status
--porcelain` reports three ` D` lines, a folder-shaped declaration matches none of them, so `slices.md`
and the parent ledger land on the default branch while the removal does not — and the next run's
Phase 0 step 9 re-enumerates the child as still standing. —
§2.3's `-A` staging is what stages a removal, exactly as it does for `/idea`'s or `/update-prd`'s
own deletions — and it stages a Phase 4.5 removal on the Phase 4.5-only path the same way), `title:` — `<BRD-KEY> Split into slices and allocate coverage` in `full` mode,
`<BRD-KEY> Allocate slice coverage` in `allocate-only`, because a pull request titled "split" that
created nothing would misdescribe itself — and `body_facts` = the run mode,
the slice count and keys (`full` only), the walk's resolution tally by disposition, whether Phase 4's
Step 1 offer fired and — where it was taken — how many rows it wrote in one confirmation and how many
were held back to the walk, every standing
empty child Phase 4.5 resolved and how, whether this run was given a slicing instruction and — when
it was — how many rows its reading placed, settled by grill, and left unplaced, and whether this run
was the no-op; emit its §4.1 outcome
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
`/dev-workflows:create-prd <SLICE-KEY>` applies in its own Phase 0 — the other being the level
test that refuses the `BRD-` container this slice sits inside. It is still not offered here, and the reason is the register rather than the ledger: that run
seeds its PRD from this slice's `decisions.md`, which `/dev-workflows:brd-interview` has not written
yet, so starting it from here would author a PRD off an allocation and no decisions at all. The route
crosses into the PRD pipeline from `/dev-workflows:brd-reconcile`'s own next-step offer, once the
customer answers are frozen — three commands further on, which is why only the next one is named
here:

```
choices: ["Decide this slice's open questions — /dev-workflows:brd-interview <BRD-KEY> (Recommended) <merge-clause>", "Stop here — this slice's allocation is complete"]
```

**`split_mode: full`** — everything below. Every child folder Phase 3 created, still claiming at
least one `[BR#n]` after Phase 4.5, **re-enters the route at grounding** — a slice is graded on its own claimed
requirements exactly as any BRD is, and nothing about being a slice exempts it from that. It can:
Phase 3 gave it the two files `/brd-ground` Phase 0 needs — a `coverage-ledger.md` to gate on and a
`brd/brd-inventory.md` to read — and Phase 6 staged both, so they reach `origin/<default>` with
this run's pull request. Grounding a child is possible only once that pull request has merged, and
`/brd-intake` is never the answer for a child at any point:

```
choices: ["Ground each non-empty child created above, one run per child — /dev-workflows:brd-ground <CHILD-KEY> (Recommended) <merge-clause>", "Decide this BRD's open questions — /dev-workflows:brd-interview <BRD-KEY> <merge-clause>", "Stop here — this BRD's own allocation is complete"]
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
ledger through its own four resolutions — the same count as `full`, a different set — and creates nothing below it. `/brd-ground`'s own
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
an operator who created children has both to do. The BRD route on `/create-prd`, `/create-ard` and
`/specify` all **ships**, and none of the three is offered on either path — for the same reason
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
continues through it. Neither is anything in Phase 1.5 — an instruction that placed no row, a grill
that reached its cap, and a `Cancel` mid-grill are all readings of a sentence the operator typed,
never a capability this plugin lacks.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model:
   `<detection_model>`) with a compact handoff: command `/brd-split`; what was produced (slices
   confirmed and keyed, the ledger walk's tally, `slices.md`); key events (the run mode, the no-op
   path, a cancelled walk with N rows left, a rejected `covered-by` key — or "none"); workarounds; test
   result N/A; project root = the BRD folder.
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /brd-split`, the run's `key` (the `<BRD-KEY>`),
   `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`).
   Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call
   its `emit-cost` entry point with `command: /brd-split`, `phase: brd-to-prd`, `role: pm`, the
   run's `key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only
   notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and
   write/overwrite `<BRD-dir>/dev-workflows/resume.md` now — after the cost entry above, and before
   the commit step below. Redact per §1. Silent.
5. **Commit session artifacts (terminal).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry
   point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths
   inside `$SPECS_PATH`, commits `<BRD-KEY> Add dev-workflows session artifacts (/brd-split)` with
   no `Co-Authored-By` trailer, and pushes to the branch Phase 6's handoff created. It NEVER touches
   a code repo, a docs repo, or the current working directory; NEVER force-pushes; NEVER
   fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0),
   re-emitting that notice. Hold its §6 outcome line for the final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable
is offered only in Phase 6), and NEVER writes into a code/docs repo or the current working
directory; no user name is ever written.

---

## Final report

Report: the BRD folder; **the slicing instruction verbatim when one was given, and how it was read**
— the counts of rows Step A placed, the Step B grill settled, and neither could place — or that none
was given; where an instruction was given but nothing consumed it, say which path swallowed it (the
no-op, or an `allocate-only` run whose walk found every row already terminal), because an instruction
that changed nothing and is not reported reads as one the command ignored; **the run mode from Phase
0 step 5, and in `allocate-only` the
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
`resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3). In `full` mode those are
the children this run created in Phase 3 and reconciled in Phase 4, and any it found already nested
in Phase 0 step 9; in `allocate-only` they are the siblings and the parent this slice's orphan rows
name (`coverage-ledger-format.md` §3), each of which `resolve-address` finds at its own level.
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
