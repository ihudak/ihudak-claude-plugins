---
name: create-prd
description: PRD-creation workflow (PM phase, sub-project 2 of the PRD-creation flow). Turns a refined idea.md + a user-supplied address into a high-quality Product Requirements Document document (spine + adapt-in profiles --lean|--hybrid|--full), authored via a relentless grill against references/prd-format.md, gated by the Opus prd-reviewer, written as prd.md into $SPECS_PATH/specifications/PRD-<KEY>-<slug>/. Product-level (no code scan). the BRD route seeds the run from a reconciled BRD instead of an idea: it reads that BRD folder's product-altitude prd-seed.md and decisions.md, defaults the profile to --full, refuses a BRD- container outright, before any ledger row is read, because a BRD is never the folder a PRD is authored in, and on the PRD- slice folder a split produces refuses one whose coverage-ledger rows are not all allocated and one whose ledger holds no covered-here row (the rows read are that slice's own ledger rows, narrowed by its brd-link.md claims:), freezes every [VD#n]/[CD#n] against the grill, and writes brd_key, brd_parent (always present on this route, since the route now resolves a slice) and depends_on into the PRD frontmatter. Offers /release-notes and /create-ard as next steps.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Author a Product Requirements Document: $ARGUMENTS

`/create-prd` is **sub-project 2 of the PRD-creation flow** (PM phase) — it consumes the `idea.md` from
`/idea` and a **user-supplied address** and
authors a high-quality **Product Requirements Document** that feeds the downstream pipeline. The PRD is **product-level**
(a PRD): what / why / for-whom, not how. Zero external calls — the PRD is authored as markdown in the specs
repo, which is where every downstream command reads it from.

Usage: `/create-prd <ADDRESS> [@idea.md] [--from-prd <PRD-KEY|path>] [--lean|--hybrid|--full] [--no-docs]` (default `--hybrid`, or `--full` on the BRD route — Phase 0 step 2; the two `--no-*` switches each turn off one grounding source — see Phase 1).

---

## Phase 0 — Resolve inputs

1. **The address (mandatory).** Parse the first non-flag token and validate it with `key-valid` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1). If absent or malformed, **stop gracefully** with the one `CREATE_PRD_NEEDS_KEY` text below — there is one stop for this code, not two. (Shape only, and never checked against anything: the key is the operator's own and names a folder in `$SPECS_PATH`; nothing mints it and nothing verifies it.)

   **The BRD route is detected, not declared.** A folder carrying `brd-link.md` was produced by
   `/brd-split` and holds the seeds this command reads; the operator restates nothing on the command
   line, and there is no flag that could disagree with the folder it names. Print which route the run
   entered before doing anything else. A key that fails §1's grammar stops with
   `CREATE_PRD_NEEDS_KEY: /create-prd needs an address (^[A-Z][A-Z0-9_]*(-\d+)+$, e.g. EPIC-008 or the slice EPIC-008-01) — re-run '/dev-workflows:create-prd <ADDRESS>'.`

2. **Profile.** `--lean | --hybrid | --full`; default `--hybrid` — **or `--full` when the BRD route is present** and no profile flag was given, per the design's *Profile default* section (§7.4): that profile is the one carrying `## Functional requirements` (`[FR#N]`), `## API specification`, `## UX prototype / UI mockups` and the full `## Assumptions & open questions` Contradictions Log, so considerably more BRD-derived content has a legitimate **product-altitude** home than `--hybrid` allows. An explicit `--lean`/`--hybrid` still wins: the default is a default, not an override.
2a. **`--from-prd <PRD-KEY|path>` (optional seed).** When present, this run authors a **new** PRD (the
    positional `<KEY>`) seeded read-only by another PRD. Resolve the seed via
    `resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3) and read that folder's
    `prd.md` for a key, or read the given path directly. The seed is **grounding, not content**
    (Phase 3 adapts it; it is never copied wholesale).

2b. **`$SPECS_PATH`, then the specs-repo preflight — both before step 3's gate.** If `$SPECS_PATH` is
    unset, stop naming it (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`). Then cite
    `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point
    (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit
    that failed to push, and settle the branch. Prompt-free and silent when the specs repo is clean and
    on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked`
    (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.

    **The ordering is the point, not the tidiness.** Step 3's `require-on-main` performs no fetch of
    its own (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3), so without the preflight's
    best-effort fetch ahead of it a merged `idea.md` reads as "on a branch and never handed off" and
    the run hard-stops on work that is already on the default branch. This command was for a time the
    only one of the twenty-three `commit-artifacts` callers running no preflight — deleted as
    collateral with an adjacent paragraph — which also left `specs_git: blocked` unset, so the G0
    guard in both `commit-artifacts` and `handoff-to-main` was inert here and a detached-HEAD specs
    repo would take this command's commits to an unreachable place and report success.

3. **Resolve `idea.md` (ladder — stop at first hit). Skipped entirely on the BRD route**, where
   `prd-seed.md` is the seed and there is no `idea.md` to find: rung 1 would return `absent` on a
   BRD folder that never held one, and rungs 3 and 4 would then offer an idea from some other
   initiative — a picker over stray `idea.md` files is exactly the offer that names something
   this run has no business reading. An explicit `@<path>` supplied alongside the BRD route is still
   honoured, on rung 2's terms only (read where it sits, never relocated, never gated, reported once
   as out-of-contract) and as **additional grounding**, never as the seed. Without the BRD route the
   ladder runs exactly as it always has:
   1. **in-contract** — `idea.md` in the folder `<KEY>` resolves to (`PRD-<KEY>-<slug>/` on a current tree; §5's unprefixed form on a legacy one). Execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against it, mapping its §3.7 return value by `stopped` first, never by `on_main` alone. Any stopping state → stop per §4.4. Otherwise (`stopped: false`): on `pass`/`pass_amending`, use it — **do not relocate**, `/idea` already did; on `absent`, fall through to rung 2 — **and report the file first where it is in fact there.** Row F means *on no ref*, not *not on disk*: an `idea.md` that `/idea` wrote and never handed off — which is every `status: draft` run, by that command's own design — sits in the folder this step has just resolved, and would otherwise be passed over in silence all the way to rung 5's grill-from-scratch, in the folder it resolved. Where the in-contract path exists in the worktree, say so once — *"`<path>` exists but is on no ref, so it is not read in-contract. Re-run `/dev-workflows:create-prd <KEY> @<path>` to read it in place (rung 2), or hand it off first."* — and then fall through exactly as before. **The fall-through itself does not change**: `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3.4 gives row F to this caller's pre-existing behaviour, `/idea` is not a prerequisite, and reporting a file is not gating on one. Likewise on `unmanaged`: this ladder runs before step 4 validates `$SPECS_PATH`, so `unmanaged` (the §3.1 gate could not run) is reachable here, and it behaves as `absent` because there is nothing to verify; step 4 still stops immediately afterward on an unset `$SPECS_PATH`, so nothing is lost by not stopping here;
   2. **out-of-contract `@path`** — explicit `@path` argument; read the idea where it sits, **never move it**, and do not gate it. Report once: *"out-of-contract: reading `<path>` in place; it will not be relocated or gated."*;
   3. **same-session** — if `/idea` ran earlier in this session, use its recorded output path (confirm with the user) — out-of-contract, as rung 2;
   4. *(retired — the discover rung searched a personal store for a stray `idea.md`. `/idea` writes into the resolved folder now, so rung 1 finds it.)* — out-of-contract, as rung 2;
   5. prompt for a path, or — last resort — proceed with **no idea** and grill the PRD from scratch. **`/idea` is not a prerequisite for `/create-prd`** — an `absent` in-contract idea must reach this rung, never a stop.
4. **`$SPECS_PATH` (required).** Already established in step 2b, which had to run before step 3's gate; nothing re-checks it here.
5. **Feature folder. On the BRD route this is the resolved `PRD-` slice folder** — the one
   `/brd-split` carved, which is what step 5a's container refusal leaves standing — and it is never
   created here. There is no second resolution for that route and no `<BRD-dir>` argument to read:
   the single positional address was resolved once with `resolve-address`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3). The
   PRD this run authors is written **into that folder** as `prd.md`, beside the BRD
   artifacts it was derived from. `absent` is a graceful stop, not a folder to
   create — and the remedy it names is the one that produces a folder this command accepts, since
   step 5a refuses the `BRD-` container a `/dev-workflows:brd-intake` run would leave behind:
   `CREATE_PRD_BRD_NOT_FOUND: no folder found for <ADDRESS> under $SPECS_PATH/specifications/ (every level addressing.md §3 bounds, plus §5's legacy fallback) — check the address. /create-prd authors into a PRD- folder, never the BRD- container above it: a slice is created by /dev-workflows:brd-split on its parent BRD, and a parent BRD is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file> and then grounded and split before any slice exists.`
   Without the BRD route, unchanged in substance: resolve the folder with `resolve-address <KEY>` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), which searches every level §3 bounds and carries §5's legacy fallback; no matching rule is written here, because a second copy of §5's is the drift §1 warns about. This is the resolution every mention of the feature folder in this command means, step 3's rung-1 `idea.md` included. On `status: absent` the folder is auto-created by the first write (Phase 5) as `PRD-<KEY>-<slug>/` per §2's convention, `<slug>` from the idea title (else a kebab of the PRD summary) — resolution honors a folder that already exists wherever it sits, and never proposes one.
5a. **The container refusal — a `BRD-` folder is never a `/create-prd` target, on either route.**
   Take this the moment step 5 returns `status: found`, **before `coverage-ledger.md` is opened at
   all** and before step 6 reads a prior PRD. **It is not part of the BRD gate below and must not be
   folded into it**: the BRD route is detected from a `brd-link.md`, and a root BRD folder need not
   carry one — `/brd-intake` writes none, and only `/brd-ground`, `/brd-split` and `/brd-package`
   ever do. A container refusal that ran only on the detected BRD route would therefore let
   `/create-prd <ROOT-BRD-KEY>` fall through to the **idea** route, find no `idea.md`, grill a PRD
   from scratch and write it into the container — the exact state this refusal exists to prevent.
   A BRD is a container and is never the folder a PRD is authored in (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5;
   `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §2 invariant 2). The folder a PRD is authored in
   is a `PRD-` folder — the slice `/brd-split` carved, carrying `brd-link.md`, or the one `/idea`
   wrote into — and that is the only shape this command accepts, on either route. This is a refusal
   on **kind**, not a sixth disposition and not a rule about rows: no row of a container's ledger can
   change it. `status: absent` reaches nothing here — there is no folder to test, and step 5 already
   says the first write creates a `PRD-` one.

   **The test is the directory prefix, and never the folder's asserted `kind:`.** `/brd-split` writes
   `kind: brd` into the `brd-link.md` it places inside a `PRD-` slice folder (`commands/brd-split.md`
   Phase 3), so a slice **asserts `brd` while being exactly the folder a PRD belongs in** — a gate on
   the asserted kind would refuse every slice and accept nothing. Nor can this command gate on
   `prd.md`'s own `kind: prd`, the way a reader of an authored PRD does: this run is greenfield and
   `prd.md` is the file it is about to write. So the test is the `BRD-` prefix
   `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §2 fixes, read off the resolved folder's own
   name. A `PRD-` prefix passes; a `BRD-` prefix refuses.

   **Where the folder resolved through that file's §5 legacy fallback and carries no prefix at all,
   the question is answered by positive evidence that it is a BRD, never by the absence of a file**
   — `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5.1, which is the authority and
   is not restated here. In short: a legacy folder carrying `coverage-ledger.md` or
   `brd/brd-inventory.md`, and no `brd-link.md` naming a `parent:`, is a root container; a legacy
   folder carrying **neither** of those two files is a legacy **idea-route PRD folder** and this
   refusal does not fire on it.

   **This is the branch a test written as an absence gets wrong, and it is reachable by design.** A
   legacy idea-route PRD folder — `specifications/<KEY>-<slug>/` holding `prd.md`, authored before
   the kind prefixes shipped — carries no `brd-link.md` either, misses §3's `*-<KEY>-*` prefixed
   glob by construction, and lands in §5's fallback every time. Refusing it as a container would
   offer `/dev-workflows:brd-split` on a folder with no coverage ledger to walk: a stop naming a
   remedy that cannot run. The two files §5.1 tests for are written by `/brd-intake` and
   `/brd-split` alone and by nothing on the idea route, which is what makes the test positive.

   Stop gracefully:
   ```
   CREATE_PRD_BRD_NOT_SLICED: <BRD-KEY> resolves to a BRD- container at <path>, and a BRD is never the folder a PRD is authored in (coverage-ledger-format.md §5) — its requirements are built by the PRD- slices under it, one PRD each. <the remedy, per the branch below>
   ```

   **The remedy branches on what the folder holds, and that branch is a directory listing rather
   than a ledger read** — the refusal is already taken by the time it is chosen, and re-deciding it
   on rows would put back the data gate this replaces. Enumerate slices by `/brd-split` Phase 0
   step 9's **positive test**: an immediate subdirectory carrying a `brd-link.md` whose `parent:`
   names this BRD. A name match is not the test, for the reason that step gives.

   | What this BRD folder holds | What the stop says |
   |---|---|
   | **One or more slices** — the ordinary shape, since a split always confirms at least one | Name every slice, and offer `/dev-workflows:create-prd <SLICE-KEY>` once per slice. That run resolves a `PRD-` folder, passes this refusal, and applies refusals 1 and 2 to the slice's **own** ledger — the offer is that a PRD belongs there, not a promise that the slice is already eligible. Do **not** name `/dev-workflows:brd-split <BRD-KEY>` here: the slices it would carve exist, and on a parent whose ledger is fully allocated that run is a no-op (`commands/brd-split.md` Phase 0 step 10) |
   | **No slice at all** | `/dev-workflows:brd-split <BRD-KEY>` is the run that carves one — it walks every row still `unallocated` and always confirms at least one slice (its Phase 2), so it produces the folder the PRD is then authored in — after which `/dev-workflows:create-prd <SLICE-KEY>`. **Two conditions travel with that offer** rather than being left for the operator to discover. First, its own Phase 0 gates on this BRD's grounding findings each carrying a verifier verdict, and stops naming `/dev-workflows:brd-ground <BRD-KEY>` when they do not. Second, **where this BRD's ledger leaves no row `unallocated` that run is a no-op** (Phase 0 step 10) and carves nothing, because the walk already settled every row and nothing in this plugin moves a terminal row back to `unallocated` (§3) — so say what the operator does *then*, or the offer is a dead end. There are two ways to reach it, and **both are leaveable** — one by a decision, one by a repair; neither is a state with no exit. Either the one slice the walk confirmed was later removed as a standing empty child (`commands/brd-split.md` Phase 4.5), in which case every requirement is `deferred-to`, `rejected` or `superseded-by`, every row is legal and terminal, and no PRD is owed by anybody: that is an **ending rather than a failure**, and no command decides otherwise, because un-deferring a requirement is a decision taken with the customer. Name no command for the decision — and say, rather than implying the state is sealed, that once it is taken it is carried out by the same two repairs the other way below names, in the same order: hand-edit the one row that is now to be built back to `unallocated`, after which `/dev-workflows:brd-split <BRD-KEY>` has a row to walk and carves the slice; or re-run `/dev-workflows:brd-intake <BRD-KEY> @<brd-file>`, which reopens **every** row and discards every deferral and rejection recorded here. Or the ledger records a fate a container can no longer hold, a **root** row `covered-here`, which no parent's walk has offered since a BRD became a container and which only a tree written before that change, or a hand edit, can have produced (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5). **The narrower repair is offered first, because the illegal state is one row wide and every other row is already legal and terminal:** hand-edit that one row's `disposition:` in `coverage-ledger.md`, leaving every other row untouched — to `deferred-to: <this BRD>`, `rejected: [DEF#n]` or `superseded-by: [BR#n]` where the requirement is not to be built here, which makes the ledger legal and lands on the ending above; or back to `unallocated` where it is, after which `/dev-workflows:brd-split <BRD-KEY>` has a row to walk, confirms a slice (its Phase 2), and that slice's own walk takes the row to `covered-here`, the one level at which `covered-here` is legal. §3's *no command ever moves a row back to `unallocated`* binds the commands; this is a hand repair of a value no command wrote, and §5 already names hand editing as how this state arises. **Second, and only where the whole inventory is to be re-taken:** re-running `/dev-workflows:brd-intake <BRD-KEY> @<brd-file>` over this same folder is a re-run rather than a refusal (its Phase 0 step 7, which now warns and confirms before the first write) and rewrites the ledger with **every** row `unallocated` (its Phase 5), after which `/dev-workflows:brd-split <BRD-KEY>` has rows to walk and carves the slice. That re-run re-extracts the inventory and **discards every disposition this ledger records**: each `deferred-to`, `rejected` and `superseded-by` the walk decided is replaced by `unallocated` and must be re-taken, and a `rejected` row must be re-cited against its `[DEF#n]`. Naming which decisions die is the disclosure — "the dispositions are replaced" is not — and it is why this option is second rather than only |

6. **Prior PRD (frontmatter-based).** Read `<feature-folder>/prd.md`. A specs repo written before the rename holds `<KEY>_<slug>.md` instead; `addressing.md` §5 resolves the folder either way, and `kind: prd` is what identifies the draft inside it. If a PRD is found, this is an **existing PRD** — `/create-prd` is greenfield-only, so **redirect** (see Phase 1) to `/update-prd <KEY>` unless `--from-prd` **or the BRD route** is present.
7. **The BRD gate (the BRD route only).** Its structural test already ran: step 5a refused a
   `BRD-` container on every route, so anything reaching this step is a `PRD-` folder.

   **Refusals 1 and 2 are slice-only, and that is what step 5a's container refusal bought.** Both are
   `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5's rule, applied — that file is the
   authority for each and neither is restated here — and both now run against exactly one shape: a
   `PRD-` folder whose `brd-link.md` carries a `parent:` — step 5a guarantees it. Read that file for its `parent:` and any
   `depends-on:`; then read `<slice-dir>/coverage-ledger.md` and take the **`disposition` written on
   each row of the gate set defined immediately below**.

   **The gate set is this slice's own ledger rows, narrowed by its `brd-link.md` `claims:`.** §5
   states eligibility over *its ledger rows*, and on a slice the narrowing does real work rather
   than coinciding with the ledger: the set is the rows its `coverage-ledger.md` holds for the
   `[BR#n]` its `brd-link.md` `claims:`. `/brd-split` wrote the claims list and the ledger together
   (§3), so the two normally coincide; where they do not, `claims:` is what this slice is answerable
   for and the narrower set is the right one. **They diverge in exactly one way, and it is benign in
   both directions**: a slice's ledger may hold an **orphan row** — a provisional claim
   `/brd-split`'s walk on the parent withdrew, whose ledger row stays and takes a terminal
   disposition (`coverage-ledger-format.md` §2, §3). `claims:` names none of them, so none is in this
   gate set; and were one read anyway it could change no verdict, because an orphan row is never
   `covered-here` (so it cannot manufacture eligibility) and never `unallocated` (so it cannot
   manufacture refusal 1). A slice claiming nothing has an empty gate set — the
   standing-empty-child state `/brd-split` Phase 4.5 keeps against a recorded reason — and reaches
   refusal 2 by the empty-set row of the table below, never refusal 1.

   **There is no root branch of this gate any more, and the argument that used to carry one is the
   behaviour step 5a forbids.** It ran: a BRD that owns its source document carries no
   `claims:` field, so a gate defined over `claims:` would read an empty set and "refuse the ordinary
   never-split BRD that is this route's primary case". Refusing it is now the **correct** outcome —
   taken two steps earlier, on the folder's kind, and without a row being read. A root never
   reaches refusals 1 and 2 at all.

   Every count and list this step and the rest of this command take — `<n>`, each `[BR#n]` list,
   Phase 1's and the final report's "how many rows are `covered-here`" — is taken over this gate set
   and over nothing else.

   **Read every disposition from the ledger file, never from any `ledger:` line.** §5 says so
   outright and §6.1 says why: that line's `unallocated` term is a *resolved* count that also holds
   rows carrying `covered-by` whose named BRD has not walked them yet, so it does not track the
   allocation gate, and a refusal keyed off it would hard-refuse a BRD whose own gate is fully
   satisfied. This command therefore never parses a `ledger:` line and never prints one — that line
   is the `/brd-*` family's final-report convention (§6), and this command is not one of them.

   **Refusal 1 — a row of the gate set is still `unallocated`.** Stop gracefully:
   ```
   CREATE_PRD_BRD_UNALLOCATED: <SLICE-KEY>'s coverage-ledger.md still writes `unallocated` on <n> of the <total> requirement rows this slice claims — <[BR#n] list>. coverage-ledger-format.md §5 makes that a hard refusal: the allocation gate was never satisfied, and an unallocated row is neither an implicit `covered-here` nor an implicit `deferred-to` in either direction. Run '/dev-workflows:brd-split <SLICE-KEY>' to walk each one to a terminal disposition, then re-run '/dev-workflows:create-prd <SLICE-KEY>'.
   ```
   `/dev-workflows:brd-split` is safe to name here **because there is something for it to do**: it is
   the command whose walk exists to move exactly these rows off `unallocated`, and on a slice it runs
   allocate-only — one fewer resolution, and no child created. It
   is not, however, unconditionally *startable*: its own Phase 0 gates on this slice's grounding
   findings each carrying a verifier verdict, and stops naming `/dev-workflows:brd-ground <SLICE-KEY>`
   when they do not. Say so beside the offer, so an operator whose slice has only been carved is not
   sent into a second stop to learn the same thing.

   **Refusal 2 — no row of the gate set is `covered-here`.** This slice holds no PRD of its own.
   Refuse, and say **where the requirements went**. **The root-reachable cases are gone from this
   table**: a delegated row — `covered-by: <SLICE-KEY>`, the shape a parent's walk writes — is the
   state step 5a's container refusal now reports, in its own branch and two steps earlier, so this table is the two
   cases a **slice** can actually reach. No row of a slice's gate set can be `covered-by`: a slice's
   `covered-by` rows are its orphan rows, which `claims:` does not name.

   | How every row of the gate set left `covered-here` | What this stop says |
   |---|---|
   | The gate set is non-empty and no row is `covered-here` — the ordinary shape a slice reaches | Name **no** sibling slice, because none holds one of these rows — and say what the gate-set rows *did* resolve to rather than calling them all obligations. §5 separates the three remaining dispositions: a `deferred-to` row is a live obligation of this slice, a `rejected` one is an obligation of nobody and cites the `[DEF#n]` justifying it, and a `superseded-by` one was absorbed into the `[BR#n]` that replaced it. Then say a PRD needs one row resolved `covered-here` first |
   | The gate set is **empty** — a slice whose `brd-link.md` claims nothing | Report the emptiness and enumerate nothing, because there is nothing to enumerate: no requirement **this slice is answerable for** reached any disposition, and naming one would invent it. A standing empty child may still hold orphan rows its parent's walk settled (§2); those are not this slice's requirements and are not reported here as though they were. Name the one run that can change it: the keep-or-remove `/dev-workflows:brd-split <PARENT-KEY>` alone resolves a standing empty child, and it is not a no-op in the state this stop reports — a standing empty child is precisely the second half of that command's own no-op test (its Phase 0 step 10). Unlike the row above, this one has a next command that exists in the state being reported |

   In the first case **there is nothing to name and a sibling must not be invented**; the
   honest report is what each row actually resolved to, and — for the deferred ones — by whom.
   "The requirements are deferred" is the common shape of that case, not the whole of it: a
   slice whose every gate-set row is `rejected` reaches this same refusal owing nobody anything, and
   saying it deferred them would be false. In the second there is not even that to report, and
   saying "the requirements were deferred" of a set holding no requirement would be false twice
   over. Stop as:
   ```
   CREATE_PRD_BRD_NOT_ELIGIBLE: no row of <SLICE-KEY>'s coverage-ledger.md that its brd-link.md claims is `covered-here`, so this slice holds no PRD of its own (coverage-ledger-format.md §5). <where the requirements went, per the row above that matches>
   ```

   **What this stop may offer, and what it may not.** Only the **second** case has a next command
   that exists in the state being reported: `/dev-workflows:brd-split <PARENT-KEY>`, the one run that
   resolves a standing empty child, and not a no-op there. In the **first** case **no command is
   offered at all, and the stop says why rather than going quiet**: re-running
   `/dev-workflows:brd-split <SLICE-KEY>` on a ledger with no `unallocated` row is a no-op that
   changes nothing (§4), `/dev-workflows:brd-reconcile` never allocates, and no row is ever moved
   back to `unallocated` (§3) — so nothing in this plugin turns a `deferred-to` row into a
   `covered-here` one. Un-deferring a requirement is a decision the operator takes with the customer,
   not a command; naming one here would send the reader into a run that does nothing. Per the
   *When no option is safe to recommend* guidance in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`, nothing on that stop is marked
   `(Recommended)`.

   **None of the three refusals carries a merge clause — step 5a's container refusal included — and
   that is a fact about where they sit rather than an omission.** All three are Phase 0 stops, taken before this run has a deliverable, a
   branch or a handoff — so there is no `Phase handoff:` outcome line
   (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1) for a clause to resolve from, and every
   command they name either runs no `require-on-main` gate at all (`/dev-workflows:brd-intake`
   consumes nothing — §5's caller table) or gates on artifacts **another** run wrote and already
   merged. Phase 6 holds this
   command's only two placeholder sites — its choice array and the bullet that resolves it — and
   nothing on this route adds a third.

   All three refusals are read **as this run finds the tree**. Refusals 1 and 2 are not defects in
   the slice: a slice that claims rows and has not yet allocated them, and one that claims rows and
   builds none of them, are both ordinary outcomes (§5). What a root BRD reaches is step 5a —
   two steps earlier, on the folder's kind, on either route, and without a row being read.

`/create-prd` is **cwd-agnostic** and needs **no repos mounted** (product-level; no code scan).

---

## Phase 1 — Configure

Use `choices` arrays; 2–4 options, and never author an "Other" option — the harness supplies the free-text escape itself (`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` §0).

1. **Confirm** the feature folder, the profile, and the resolved `idea.md` (or "none — grill from scratch"); on the BRD route, the resolved `PRD-` slice folder, the profile (`--full` unless a flag overrode it), and — instead of an idea — a `from BRD:` line naming `<SLICE-KEY>` and the `parent:` its `brd-link.md` records (always present — step 5a refuses the container), its `depends-on:` if any, how many of its gate-set rows (Phase 0 step 7) are `covered-here` out of how many, and whether `prd-seed.md` and `decisions.md` were found.
   - Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).
2. **Existing-PRD handling** (only if Phase 0 step 6 found a PRD for `<KEY>`):
   - **the BRD route present** → "author this slice's PRD" conflicts with "a PRD for this slice
     already exists here". **`/update-prd` has no BRD route** — it takes one address and refreshes
     the `prd.md` it finds there — so the redirect is honest about what it drops: it refreshes the
     PRD already on disk, it does not re-read the seed. It resolves the **same folder** this run did,
     which is why one address serves both.
     ```
     choices: ["Refresh the existing <SLICE-KEY> PRD — /dev-workflows:update-prd <SLICE-KEY> (the BRD seed is not re-read) (Recommended)", "Overwrite <SLICE-KEY> as a fresh PRD authored from the BRD seed (archives the current one)", "Cancel"]
     ```
   - **No `--from-prd`** → `/create-prd` is greenfield-only; **redirect**:
     ```
     choices: ["Switch to /dev-workflows:update-prd <KEY> to refresh it (Recommended)", "Overwrite as a fresh PRD (archives the current one)", "Cancel"]
     ```
   - **`--from-prd` present** → "create new (seeded)" conflicts with "a PRD already exists here":
     ```
     choices: ["Update the existing <KEY> instead — /dev-workflows:update-prd <KEY> (seed ignored) (Recommended)", "Overwrite <KEY> as a new seeded PRD (archives the current one)", "Cancel"]
     ```
3. **Draft idea → warn-and-fold** (no-op on the BRD route, which resolves no idea; the equivalent there is the open `[VD#n]`/`[CD#n]`/`[AS#n]` set Phase 2 carries in). If `idea.md` is `status: draft` (open `[NEEDS CLARIFICATION]`), note that the grill resolves those items — do **not** hard-block.

---

## Phase 1.5 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT for large/cross-cutting PRDs
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # impl-maintenance
  review_model:    <§2 Opus chain>     # prd-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + PRD authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

The grill + authoring run inline on `current_model` (the §2 Opus chain — interactive judgment, not a delegated subagent). If no Opus resolves, **degrade to best-available + record** in `notes` and the final report — do not hard-block.

**Profile nudge (complex PRDs).** If `classification` is **SIGNIFICANT** (a
complex / cross-cutting PRD) and the chosen profile is `--lean` or `--hybrid`
(so `[FR#N]` is unavailable — it is full-only), surface a one-line **non-blocking**
recommendation before Phase 2:
> "This PRD classifies SIGNIFICANT — consider `--full` so Functional Requirements
> (`[FR#N]`) and richer Use Cases (`[UC#N]`) are available for stronger, more
> traceable downstream Epic coverage."

Offer `choices: ["Switch to --full", "Keep <profile>"]`. On
"Keep", proceed unchanged. For a SIMPLE / MODERATE classification, or when the
profile is already `--full`, this nudge does **not** fire.

---

## Phase 2 — Read the seed

Read the resolved `idea.md` **directly** (it is the plugin's own format — `idea-reader` is for arbitrary external sources and is not used here). Extract Problem / Who / desired outcome & value / rough scope / signals & evidence / candidate success signal, plus any open `[NEEDS CLARIFICATION]`. Carry the idea's `sources[]` forward to **propagate** into the PRD frontmatter (the real provenance — RFE key / an existing PRD's key / community-post URL / prompt), and record `derived_from` = the idea's own resolved path — read here from `idea.md`'s own frontmatter, never from a relocation, since `/create-prd` no longer moves it.

Optionally ground in the idea's cited sources and any strategy/vision docs the user points to. **No code scan; no repos.**

If `--from-prd` was resolved (Phase 0 step 2a), also read the **seed PRD** (body + comments) as read-only
grounding — structure, personas, scope shape, and metrics to *adapt* (never copy) to the new PRD.

If there is no idea (Phase 0 ladder exhausted), grill the PRD from scratch.

### the BRD route — read the product-altitude seed and the decision register

Read exactly two files from the BRD folder Phase 0 step 5 resolved, and no other seed:

- **`prd-seed.md`** — product-altitude content, when the folder holds any. **No `/brd-*` command writes this file on the normal route** — the one writer is
  `/dev-workflows:brd-intake --sort-existing`, a one-time migration path for a package authored
  by hand before this route existed. Its absence is therefore the **ordinary** case, not a
  degraded one, and is reported rather than treated as a gap; what the route actually carries at
  every altitude is `decisions.md`, filtered by `altitude`, plus the grounding files.
  **`ard-seed.md` and `spec-seed.md` are not read**, at all: they are the architecture and
  implementation altitudes of the same router, belonging to `/create-ard` and `/specify`, and
  pulling either in is how a PRD acquires the implementation detail
  `${CLAUDE_PLUGIN_ROOT}/references/prd-format.md`'s quality rules forbid.
- **`decisions.md`** — the register, per
  `${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §1.

A BRD-route run with **no `prd-seed.md`** is not a stop, and is the **ordinary** shape: nothing on
the normal route writes a seed file at all (above), so a reconciled BRD routinely holds none. Say so
plainly, carry `decisions.md` alone, and let the grill fill the spine from it — a silent fall-through to "grill from scratch" would lose the
register too. A run with **no `decisions.md`** is likewise not a stop; report which of the two was
absent, since a reader cannot tell an unwritten register from an unread one.

**Partition the register before the grill starts, because the partition is what freezes it.**

| Register state (§3) | What this run does with it |
|---|---|
| `decided` | An **input**. It is settled content the PRD is authored *from* — never a question, never re-argued, and never re-answered because this run would have chosen differently |
| `superseded` / `withdrawn` | Terminal (§3). Read for context; never revived, and a `withdrawn` request is never re-asked |
| `open` | **May not be consumed downstream while it is open** (§3). It is a gap, not a decision: it reaches the PRD under `## Assumptions & open questions`, named by its id, and the grill may settle the *PRD's* wording around it without settling the decision itself |
| `reopened` | Was reopened upstream under §4 and is not yet re-decided — handled exactly as `open` |
| `[AS#n]` (open) | An assumption, not a choice (§7). Same treatment as `open`, and it keeps its `[AS#n]` id in the PRD so the reader can find the record that admits its own groundlessness |

Carry each `decided` record's `altitude` with it: only `product` ones have a product-altitude home
here. An `architecture` or `implementation` decision is read for context and **left for the command
that authors at its altitude** — `/dev-workflows:create-ard` and `/dev-workflows:specify` — and it is
not discarded by being skipped. **The channel that carries it is `decisions.md` itself, not a seed
file.** Both of those commands read this same register and filter it by `altitude` exactly as this
phase does, so a decision skipped here is picked up there from the file it was already in. Say so
rather than naming a seed: `ard-seed.md` and `spec-seed.md` are written by nothing on this route
(only `/dev-workflows:brd-intake --sort-existing` writes one, migrating a package authored before
the route existed), so an operator told a decision was "routed to its seed" would go looking for a
file that is not there and conclude the content was lost.

**One profile leaves the gaps homeless, and the run must not discover that silently.**
`## Assumptions & open questions` is an adapt-in cluster, so an explicit `--lean` overriding the
the BRD route default (Phase 0 step 2) gives this PRD a spine and nothing else — and every `open`,
`reopened` and open `[AS#n]` the partition just produced would have no product-altitude section to
land in. Where the register holds at least one such record and the profile is `--lean`, surface a
**non-blocking** choice before Phase 2.5, naming the count:

```
choices: ["Switch to --full so the open register items have a home (Recommended)", "Switch to --hybrid (light open-questions list)", "Keep --lean — the open items are reported by id, never written into the PRD"]
```

On "Keep `--lean`", the final report names every one of them by id. A gap this command silently drops
is one no later reader can find, which is the failure the register's own `[AS#n]` surfacing rule
exists to prevent.

---

## Phase 2.5 — Grounding: documentation (optional)

Dispatch both grounding agents **in a single response** so they run in parallel. Each is independent; either being OFF never suppresses the other.

**Docs.** Run `resolve-docs-grounding create-prd` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the idea's problem/goal + PRD themes, `key` = `<KEY>`, and `themes` from the idea. When OFF, skip silently.

**On the BRD route both agents run unchanged; only their inputs are substituted**, because there is
no `idea.md` to take them from. `feature_summary` and `themes` come from `prd-seed.md` (falling back
to the `statement` of each product-altitude `decided` record when the seed is absent), and
`known_refs` is every `[BR#n]` source path and prerequisite `<BRD-KEY>` the run already holds from
`brd-link.md` — again with `has_summary: false`, for the same reason: this command reads those files
directly and holds no summaries of its own. Neither agent is given `ard-seed.md` or `spec-seed.md`.

Carry both digests into Phase 3 with **grill-rank** consumption. When both are OFF the PRD is authored exactly as today.

---

## Phase 3 — Author via grill

**Interview technique (grilling — embedded; no runtime dependency).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split (look up facts from the idea/sources; put only decisions to the user), walk the design tree in dependency order, continue to shared understanding then write each section. Rank every `docs_challenges` entry from Phase 2.5 into the grill's question order; a challenge competes for attention, it never suspends the spine below.

Author `prd.md` live against `${CLAUDE_PLUGIN_ROOT}/references/prd-format.md` for the selected profile, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`. Walk the **spine** in dependency order:

1. Frontmatter — `relevant_for_release_notes` (defaults to `yes`; ask only to confirm a `no`); `sources` (propagated), `derived_from`, `seeded_from_prd` (only when `--from-prd` was used), and `key` — **written on every route**, set to the address this run resolved. On either route it is the `key:` the resolved folder asserts (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §4) — the positional key the operator chose on the `/idea` route, and the slice's own key on the BRD route, which is also the name of the folder this PRD is written into.

   **Do NOT ask for `release_versions`, `change_type` or `release_notes_category` here.** They are
   authored fields now rather than tracker dropdowns returned by an import
   (`${CLAUDE_PLUGIN_ROOT}/references/prd-format.md`), but the place each is *known* is
   `/release-notes` — it infers and confirms `change_type` and `release_notes_category` in its own
   grill, and takes `release_versions` from its `--version` flag or that same grill. Write whichever
   the operator volunteers; never invent one, and never spend a question here on an answer that
   command asks for anyway. An unanswered field is omitted, not filled.

   **`key` was for a time omitted on the BRD route**, deferred to a tracker step — long retired — that once minted a separate identity and wrote it back. Once that step was gone nothing wrote the field at all, so it stayed permanently unset — which is the defect the spine item above closes by writing `key` on every route. Left unset, a folder whose only `kind:`+`key:` carrier is `brd-link.md` (`kind: brd`) resolves as a BRD rather than a PRD (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §4), while `/document` and `/release-notes` build their commit scan from a `key` that is empty and silently match nothing. There is no second identity to keep straight any more: one namespace, one grammar, and the folder's key is the key.
2. **Problem**
3. **Goal** (crisp 2–3 sentences)
4. **Target audience** (personas)
5. **User Stories** (`[US#N]`)
6. **Acceptance Criteria** (`[AC#N]` per story)
7. **Scope** (In / Out)
8. **Success Metrics** (`[SM#N]`)

Then author the profile's **adapt-in clusters**, each **pulled only when the idea warrants it** (never an empty section). **For a complex PRD (`classification` SIGNIFICANT), actively author the `[FR#N]` (full) and `[UC#N]` (hybrid/full) clusters** within the chosen profile — lower the bar for pulling them in, because ID'd functional requirements and use cases feed a finer downstream `/epics` `_coverage.md` (traceability to `[FR#N]`/`[UC#N]`, not only `US`/`AC`/`SM`); still never an empty section. Fold the idea's open `[NEEDS CLARIFICATION]` into the grill; resolve to zero where possible, leaving genuinely-unresolvable ones under `## Assumptions & open questions` (hybrid/full). Keep the PRD **product-level** — no implementation detail. **Self-consistency check:** before writing each section, check it against the already-settled sections — a new `[AC#N]` must not deliver an Out-of-scope behaviour, the `## Goal` must not assert a scope the `## Scope` contradicts, and `[US#N]`s must not conflict. Resolve any contradiction inline with the user, or record it under `## Assumptions & open questions` — never leave it implicit (the Opus `prd-reviewer` flags a silently-baked contradiction).

### the BRD route — the grill is restricted to gaps

**The grill may fill anything the seed does not settle. It may not reopen a `[VD#n]` or a `[CD#n]`**
(D3). Those decisions arrive carrying customer sign-off in writing, and a grill that re-litigates one
manufactures a contradiction between this PRD and a document the customer has already agreed to.

**Three things make that a guarantee rather than an instruction, and the third is the one that holds
when the first two are forgotten:**

1. **The question set is a subtraction, not a sweep.** Phase 2's partition already sorted the register
   into inputs (`decided`), terminal records (`superseded`, `withdrawn`) and gaps (`open`,
   `reopened`, open `[AS#n]`). The grill's questions are derived from the gaps and from what
   `prd-seed.md` leaves unstated — a settled `chosen` is never a question, so there is nothing for
   the interview to walk it back through.
2. **This run cannot satisfy either cause that would license a reopening.**
   `${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §4 admits exactly two, and
   `/create-prd` produces neither: it runs no grounding at all — it is cwd-agnostic and mounts no
   repos, so it can mint no new finding — and it receives no customer review, which reaches the
   register only through `/dev-workflows:brd-reconcile`. A grill answer is neither of the two, whatever
   it says.
3. **The only field of a decision record this command may write is `consumed_by`** (Phase 5).
   `statement`, `options_considered`, `chosen`, `argumentation`, `evidence`, `altitude`,
   `conditional_on`, `status` and `round` are never written here, on any record, in any status. So a
   grill answer that contradicted a `decided` record could not become that record's new `chosen`
   even if the first two failed: there is no write that would record it.

**What happens when the grill surfaces a genuine contradiction with a settled decision** — which is
useful information, not something to suppress. Do not decide it and do not soften the decision into
the PRD's prose. Record it under `## Assumptions & open questions` — or, on a kept `--lean` where that
cluster does not exist, in the final report alone — naming the `[VD#n]` or `[CD#n]` it contradicts and
what the run believes contradicts it, and say which of the two routes may act on it. **Neither route
is this command**, and both are exactly `decision-register-format.md` §4's two causes rather than a
third one invented here: a `[VD#n]` needs a **new grounding finding** first, which only
`/dev-workflows:brd-ground <BRD-KEY> --rebaseline` mints and `/dev-workflows:brd-interview <BRD-KEY>`
then re-decides against; a `[CD#n]` needs the **customer**, through
`/dev-workflows:brd-package <BRD-KEY>` and then `/dev-workflows:brd-reconcile <BRD-KEY> @<review-file>`.
Naming the route is what keeps the contradiction actionable without this command taking the decision.

**`prd-format.md`'s no-implementation-detail rule is not relaxed** (D4). A gap the grill can only
fill with implementation detail is not a gap this PRD closes: the detail belongs to `ard-seed.md` or
`spec-seed.md` and their consumers, which is what the design's *Altitude routing* router exists for
(D5). Say where it went; never discard it, and never widen the PRD to hold it.

---

## Phase 3.5 — Prose style check

Run a prose style check on the authored PRD **before** the review gate. This
is a **quality enhancement, not a gate** — it never blocks the handoff.
`prd-reviewer` (Phase 4) judges content; style / terminology is checked here
(mirrors `/epics` Phase 6.2).

→ Agent (subagent_type: "prose-style:prose-style-checker", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Run the style check for this brief:
  >
  > files:    [absolute path to prd.md]
  > doc_type: prd
  > emphasis: terminology and customer-facing captions, labels, messages, and text"

Act on the return:
- **`OK`** — proceed to Phase 4.
- **`VIOLATIONS_FOUND`** — the orchestrator/grill applies the **MAJOR** fixes
  **inline** (no delegated writer — consistent with Phase 4's inline-fix model),
  then re-runs `prose-style-checker` **once**. Remaining MINOR/NIT are recorded in
  the final report.
- **`ERROR`** — surface the reason and proceed to Phase 4 (non-gating).

If `prose-style-checker` is unavailable (agent not found — the `prose-style`
plugin is not installed), **skip this phase gracefully** and note
`SKIPPED (prose-style-checker unavailable)` in the final report.

---

## Phase 3.6 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against the drafted `prd.md`: the
**Universal checks**, the **key-collision** check (run on the PRD body below the frontmatter),
and the **PRD** block. Surface every finding; inline-fix the mechanical ones
(renumber a duplicate `[US#N]`/`[AC#N]`/`[SM#N]`, delete a stray placeholder token); leave content gaps
(missing section, unresolved `[NEEDS CLARIFICATION]`) for the grill/author. **Advisory** — never blocks;
proceed to Phase 4 once findings are surfaced. `prd-reviewer` remains the gate.

## Phase 4 — Review gate

Dispatch `prd-reviewer` (Opus, frontmatter-pinned; recorded as `review_model`, no override):

→ Agent (subagent_type: "dev-workflows:prd-reviewer", model: `<review_model — §2 Opus chain>`):
  > "Review the Product Requirements Document:
  >
  > PRD path: [absolute path to prd.md]
  > Profile: [lean | hybrid | full]"

Act on the verdict (mirrors `/specify`):
- **`BLOCK`** — fix the BLOCKER findings inline (the orchestrator/grill edits the PRD — no delegated writer) and re-review **once**. If still `BLOCK`, escalate per the `Review verdict BLOCK` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` for each unresolved BLOCKER (`choices: ["Provide manual fix notes", "Defer to a follow-up issue", "Override and accept", "Cancel"]`).
- **`PASS` / `PASS WITH RECOMMENDATIONS`** — proceed. Cap: one fix cycle + one re-review.

---

## Phase 5 — Handoff

Write the feature folder: `prd.md`. The in-contract `idea.md` is already there, committed by `/idea`; an out-of-contract idea stays where it is.

**On the BRD route, also close the consumption loop before the offer.** The design's *Consumption
tracking* section (§7.3) has every finding and decision record a `consumed_by`, so that "nothing was
lost" is checkable rather than hoped for. Set `consumed_by: PRD` on each product-altitude
`decided` record in `decisions.md` this PRD actually took content from — and on nothing else: a
record this run read for context and did not use is still `none`, and marking it consumed would
report a routing that never happened. This is the **only** write this command makes into
`decisions.md` (Phase 3), and it is not a `status` change. Everything at product altitude still
`none` afterwards goes in the final report by id, per §7.3.

**`prd-seed.md` is reported, not stamped, and the difference is a fact about the authorities rather
than an inconsistency.** `consumed_by` is a field of a *record*: it is defined on a decision by
`${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §1 and on a grounding finding by
`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §2. The seed carries neither — it is
altitude-sorted content, and no reference in this plugin fixes an item shape inside it — so there is
no per-item field to write, and inventing one here would mint a format this command alone
understood. The seed's consumption is therefore reported at **file** granularity in the final report
(consumed, or consumed in part with what was left over), and `decisions.md` is the only BRD file
this run writes to.

Then **offer** (commit-when-asked — never automatic), presenting `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: prd`, `feature_folder` as resolved in Phase 0, `deliverable_paths` = the PRD file — **plus, on the BRD route, `decisions.md`**, because the `consumed_by` write above lands there and an uncommitted consumption record is one no later run can read; `prd-seed.md` is not staged, because this run does not write to it — `title: <KEY> Add Product Requirements Document — <summary>`, and `body_facts` = the resolved profile (`--lean`/`--hybrid`/`--full`), the adapt-in clusters pulled, the user-story and acceptance-criteria counts, any `[NEEDS CLARIFICATION]` markers carried in, the `prd-reviewer` verdict, and — on the BRD route — the `<BRD-KEY>` this PRD was seeded from and how many items were marked `consumed_by: PRD`; emit its §4.1 outcome line in the Final report.

---

## Phase 6 — Next steps

Offer these — clearly labeling the role handoff:

```
choices: ["Draft the release note now — /dev-workflows:release-notes <ADDRESS> (PM) (Recommended)", "Hand to a Product Architect — /dev-workflows:create-ard <ADDRESS> (PA, optional) <merge-clause>", "Hand to a Product Engineer — /dev-workflows:epics <ADDRESS> (PE)", "Stop here"]
```

**One address appears in that array, and every option takes the same one** — `<ADDRESS>`, this run's
own resolved address, which is the `key:` the folder asserts and names the folder this run wrote
into. There is no second key to keep straight and no flag to carry: `/dev-workflows:create-ard` and
`/dev-workflows:epics` each resolve that folder through the same entry point, and on the BRD route
the address is the `PRD-` slice's own key, which is what `/brd-split` carved and what step 5a's
refusal leaves standing. (This paragraph once distinguished `<KEY>` from a second positional key and
carried `--from-brd` into the PA option; D4 retired the pair and D18 retired the flag.)

- **`/dev-workflows:release-notes <ADDRESS>`** (PM) — draft the customer-facing release note now (the cost model's `pm`/`prd-creation` inferred case: no spec/design yet).
- **`/dev-workflows:create-ard <ADDRESS>`** (PA, **optional**) — hand to a Product Architect to author the grounded architecture document. **On the `/idea` route** (on the BRD route, see the PA paragraph below) it gates this PRD on the specs repo's default branch (its own Phase 0), so it stops where this PRD reached a branch and falls back to the resolved folder — reported, never silently — where it reached none. `<merge-clause>` is the placeholder `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` owns, resolved from this run's own `Phase handoff:` outcome line (§4.1) and never written as the unconditional "once the pull request above is merged": a declined handoff, a failed push and a nothing-to-commit run each leave a different wait, and two of them open no pull request to wait on. It is a placeholder, not an instruction to reword an option, so the array is still presented verbatim per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
- **`/dev-workflows:epics <ADDRESS>`** (PE) — hand to a Product Engineer to split the PRD into Epics (or author a PRD-level spec → `/dev-workflows:specify <ADDRESS>`, which resolves the same folder through the same entry point).

The other two options carry no clause, and that is checked, not assumed: `/dev-workflows:release-notes` runs no `require-on-main` at all, and `/dev-workflows:epics` gates only `<PRD-dir>/specification.md` — a file this run does not write.

**Every option is presented unconditionally now, and the reason the two used to be withheld is
gone.** `/dev-workflows:epics` and `/dev-workflows:release-notes` were held back until a key had been minted outside the plugin *and* an export produced against it, because both resolved that export and found nothing without it. Neither reads an export any more: both resolve a folder in the specs tree, which
this run has just written. So there is no half-done state to report and no `(Recommended)` marker to
withhold — the offer says what it always meant to say, one phase earlier.

**The PA option reads `/dev-workflows:create-ard <ADDRESS>` on both routes.** It resolves the folder
with `resolve-address` and reads what that folder holds — an `ard-seed.md` where the BRD route left
one, the PRD otherwise. It carries **no** merge clause where the run it offers gates nothing this run
wrote, per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`'s resolution table.

Guidance only — never auto-invokes another command. Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`.

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 7), per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — the PRD-Key is minted by the
handoff, so it **omits the session-name line**; name the session manually if
useful. Then:

- **Continuing as PM (`/dev-workflows:release-notes <ADDRESS>`)?** → run **`/compact`**.
- **Handing to PA (`/dev-workflows:create-ard <PRD>`) or PE (`/dev-workflows:epics <PRD>`), even yourself?** → run **`/clear`** for a clean slate.

Guidance only — nothing is auto-run. See `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.

---

## Phase 7 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 6, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked), `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment / user halt (missing key, unset `$SPECS_PATH`, cancellation) or a work-quality review BLOCK. **The three BRD-route refusals are of that second class, not the first**: `CREATE_PRD_BRD_NOT_SLICED` (structural, step 5a), `CREATE_PRD_BRD_UNALLOCATED` and `CREATE_PRD_BRD_NOT_ELIGIBLE` (slice-only, step 7) each report the state of the operator's own BRD tree, not a capability this plugin lacks, so none of them `emit-block`s. `CREATE_PRD_NEEDS_KEY`, `CREATE_PRD_BRD_NOT_FOUND` and `CREATE_PRD_TWO_SEEDS` are the same.

**Session-hygiene invariant.** End Phase 6 with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the
`resume.md` write runs later, in the terminal cost phase, per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the
guidance only),
then a span suggestion (PM continue → `/compact`; PA/PE handoff → `/clear`). No `/rename`
label yet (no PRD-Key). Guidance only, never auto-run.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/create-prd`; what was authored (PRD + profile); key events (source-ladder friction, unresolved clarifications, BLOCK reviews — or 'none'); workarounds; the `prd-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6) with the Lessons Learned report, `command: /create-prd`, the run's `key` — which on the BRD route is the `<BRD-KEY>`, matching this PRD's own `$SPECS_PATH` folder, so the write stays on that reference's primary tier instead of dropping to the unfiled one — `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its `emit-cost` entry point with `command: /create-prd`, `phase: prd-creation`, `role: pm`, the run's `key` (or `brd_key`, on the BRD route, for the reason step 2 gives), `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite `<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the pointer reflects the completed run, and before the commit step below, so it is included in it. Redact per §1. Silent; the printed `### Context hygiene` guidance already appeared in the report.
5. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/create-prd)` — or `NOISSUE …` when the run resolved no key at all — with no `Co-Authored-By` trailer. **On the BRD route that `<KEY>` is the BRD key, not `NOISSUE`**: this is a specs-repo commit-message prefix, not a tracker lookup, and the BRD key is the key this run resolved and the name of the folder the staged artifacts sit in. A key the handoff has not yet minted is missing from `key`, which is a different field for a different purpose, and pushes to the branch this run's handoff phase created (§4.1). It NEVER touches anything outside `$SPECS_PATH`; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is offered only in Phase 5; the terminal step above commits only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the PRD path + profile; US/AC/SM counts + which adapt-in clusters were included; open-question count; the `prd-reviewer` verdict; the prose style-check outcome (`OK` | `N fixed, M remaining` | `SKIPPED`); the `Phase handoff:` outcome line from `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1); the handoff reminder; resolved model routing (+ any Opus degradation); the feedback + cost paths; the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; and the next-step recommendations.

**On the BRD route, additionally:** the `<BRD-KEY>` seeded from and its resolved folder; which of
`prd-seed.md` and `decisions.md` were present; the frontmatter `brd_key` / `brd_parent` /
`depends_on` as written — `brd_parent` is present on every run of this route, since the route
resolves a slice and a slice always has a `parent:` (naming `depends_on` if omitted, and why); how many of the gate-set ledger rows
(Phase 0 step 7) are `covered-here`, read from `coverage-ledger.md` — **not** as a `ledger:` line, which this command
neither parses nor prints (Phase 0 step 7); every `[VD#n]`/`[CD#n]`/`[AS#n]` carried in as a gap
rather than an input, by id and status; every contradiction Phase 3 recorded rather than decided,
with the reopening route named for each; every product-altitude item still `consumed_by: none`, by
id, per the design's *Consumption tracking* section (§7.3); and any sub-product-altitude content the
grill surfaced and left for `/dev-workflows:create-ard` or `/dev-workflows:specify` instead of the
PRD (D4) — naming the command, never a seed file, since the register those runs will read that
content out of is the one this run already read.
All three the BRD route refusals are Phase 0 stops and never reach this report.
