---
name: create-prd
description: PRD-creation workflow (PM phase, sub-project 2 of the PRD-creation flow). Turns a refined idea.md + a user-supplied JIRA-KEY into a high-quality Product Requirements Document document (spine + adapt-in profiles --lean|--hybrid|--full), authored via a relentless grill against references/prd-format.md, gated by the Opus prd-reviewer, written to $SPECS_PATH/specifications/<KEY>-<slug>/. Product-level (no code scan). --from-brd seeds the run from a reconciled BRD instead of an idea: it reads that BRD folder's product-altitude prd-seed.md and decisions.md, defaults the profile to --full, refuses a BRD whose coverage-ledger rows are not all allocated and one whose ledger holds no covered-here row (the rows read are the BRD's own ledger rows, narrowed by brd-link.md claims: only on a slice), freezes every [VD#n]/[CD#n] against the grill, and writes brd_key/brd_parent/depends_on into the PRD frontmatter. Offers /release-notes and /create-ard as next steps.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Author a Product Requirements Document for the Jira item: $ARGUMENTS

`/create-prd` is **sub-project 2 of the PRD-creation flow** (PM phase) — it consumes the `idea.md` from
`/idea` and a **user-supplied `JIRA-KEY`** (an empty Jira workitem the user created to get the ID) and
authors a high-quality **Product Requirements Document** that feeds the downstream pipeline. The PRD is **product-level**
(a PRD): what / why / for-whom, not how. Zero Jira API — the PRD is authored as markdown in the specs
repo, which is where every downstream command reads it from.

Usage: `/create-prd <JIRA-KEY|BRD-KEY> [@idea.md] [--from-prd <PRD-KEY|path>] [--from-brd [<dir>]] [--lean|--hybrid|--full] [--no-docs] [--no-prior-art]` (default `--hybrid`, or `--full` under `--from-brd` — Phase 0 step 2; the two `--no-*` switches each turn off one grounding source — see Phase 1).

---

## Phase 0 — Resolve inputs

1. **`JIRA-KEY` (mandatory).** Parse the first non-flag token; validate `^[A-Z][A-Z0-9_]*-\d+$`. If absent or malformed, **stop gracefully**: `CREATE_PRD_NEEDS_KEY: /create-prd needs a Jira key — create an empty Jira workitem first to get the ID, then re-run '/dev-workflows:create-prd <KEY> @<idea.md>'.` (Format only — zero Jira API, so existence is not verified.)

   **Under `--from-brd` — scan the argument list for the flag before validating, since steps 2–2b are pure argument parsing and touch no filesystem — the positional token is a BRD key, and it is validated by `key-valid` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1) instead.** A slice's key carries a third numeric segment (`EPIC-008-01`) and a slice is the level this route most often reaches a PRD at, so validating it against the two-segment form above would refuse the ordinary case. The BRD grammar is a **superset** of it — every key the two-segment form accepts, `key-valid` accepts — so no key that resolved before resolves differently now, and a key that fails it stops with `CREATE_PRD_NEEDS_KEY` naming the BRD form: `CREATE_PRD_NEEDS_KEY: /create-prd --from-brd needs a BRD key (^[A-Z][A-Z0-9_]*(-\d+)+$, e.g. EPIC-008 or the slice EPIC-008-01) — re-run '/dev-workflows:create-prd <BRD-KEY> --from-brd'.` Shape only, and never checked against a tracker (§1) — a BRD is a markdown file in `$SPECS_PATH`, not a ticket.
2. **Profile.** `--lean | --hybrid | --full`; default `--hybrid` — **or `--full` when `--from-brd` is present** and no profile flag was given, per the design's *Profile default* section (§7.4): that profile is the one carrying `## Functional requirements` (`[FR#N]`), `## API specification`, `## UX prototype / UI mockups` and the full `## Assumptions & open questions` Contradictions Log, so considerably more BRD-derived content has a legitimate **product-altitude** home than `--hybrid` allows. An explicit `--lean`/`--hybrid` still wins: the default is a default, not an override.
2a. **`--from-prd <PRD-KEY|path>` (optional seed).** When present, this run authors a **new** PRD (the
    positional `<JIRA-KEY>`) seeded read-only by another PRD. Resolve the seed via
    `resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3) and read that folder's
    `prd.md` for a key, or read the given path directly. The seed is **grounding, not content**
    (Phase 3 adapts it; it is never copied wholesale).
2b. **`--from-brd [<dir>]` (optional seed — the BRD route).** A **switch, not a path**: the
    positional key already identifies the BRD and the design's *Keys and addressing* section (§4.3)
    resolves it, so `/create-prd EPIC-008-01 --from-brd` needs no path. A directory may be given
    for a BRD folder outside the normal layout; it is never required, and a following token is
    consumed as that path only when it is not itself a flag. This run then authors the PRD from
    that BRD folder's **product-altitude** seed — `prd-seed.md` — and its decision register,
    `decisions.md`. `ard-seed.md` and `spec-seed.md` are **not this command's**: they are the
    architecture and implementation altitudes of the same router, read by `/create-ard` and
    `/specify`, and reading either here would put sub-product-altitude content into a PRD.
    **`--from-brd` and `--from-prd` are mutually exclusive** — they are two different seeds for one
    PRD, and folding both in would leave no answer to which one a contested section came from. If
    both are present, stop gracefully: `CREATE_PRD_TWO_SEEDS: --from-prd and --from-brd are two
    different seeds for one PRD — re-run '/dev-workflows:create-prd <KEY>' with exactly one of
    them.`

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline. **Under `--from-brd`, pass the resolved BRD key as this run's key set** (§3.2 — the route is what decides keyless here, not the command): steps 1–2b above already validated it, this run's branch is `prd/<BRD-KEY>-<slug>`, and an empty set would send a resumed run to §3.5 B4 and duplicate that branch at `-2`. On the `/idea` route the set stays empty, for the reason §3.2 gives. The preflight then: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.

*(The preflight runs here, before the gate below, because `require-on-main` performs **no** `fetch` of its own — §3.2 — and relies on this step's best-effort one. Gating first would test never-fetched refs: a just-merged artifact would be missed on `origin/<default>` while the stale remote-tracking ref for its deleted branch still carries it, producing a false row D/E stop. `specs-preflight` self-gates on `$SPECS_PATH`, so it is safe this early.)*

3. **Resolve `idea.md` (ladder — stop at first hit). Skipped entirely under `--from-brd`**, where
   `prd-seed.md` is the seed and there is no `idea.md` to find: rung 1 would return `absent` on a
   BRD folder that never held one, and rungs 3 and 4 would then offer an idea from some other
   initiative — a picker over every `idea.md` in the vault is exactly the offer that names something
   this run has no business reading. An explicit `@<path>` supplied alongside `--from-brd` is still
   honoured, on rung 2's terms only (read where it sits, never relocated, never gated, reported once
   as out-of-contract) and as **additional grounding**, never as the seed. Without `--from-brd` the
   ladder runs exactly as it always has:
   1. **in-contract** — `specifications/<KEY>-<slug>/idea.md`, resolved from `<KEY>`. Execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against it, mapping its §3.7 return value by `stopped` first, never by `on_main` alone. Any stopping state → stop per §4.4. Otherwise (`stopped: false`): on `pass`/`pass_amending`, use it — **do not relocate**, `/idea` already did; on `absent`, fall through to rung 2 — likewise on `unmanaged`: this ladder runs before step 4 validates `$SPECS_PATH`, so `unmanaged` (the §3.1 gate could not run) is reachable here, and it behaves as `absent` because there is nothing to verify; step 4 still stops immediately afterward on an unset `$SPECS_PATH`, so nothing is lost by not stopping here;
   2. **out-of-contract `@path`** — explicit `@path` argument; read the idea where it sits, **never move it**, and do not gate it. Report once: *"out-of-contract: reading `<path>` in place; it will not be relocated or gated."*;
   3. **same-session** — if `/idea` ran earlier in this session, use its recorded output path (confirm with the user) — out-of-contract, as rung 2;
   4. **discover** — `find "$VAULT_PATH/Projects" -type f -name idea.md` (recent first); if any, present a picker — out-of-contract, as rung 2;
   5. prompt for a path, or — last resort — proceed with **no idea** and grill the PRD from scratch. **`/idea` is not a prerequisite for `/create-prd`** — an `absent` in-contract idea must reach this rung, never a stop.
4. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
5. **Feature folder. Under `--from-brd` this is the resolved BRD folder**, and it is never created
   here: resolve it with `resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3),
   which already searches both levels, or read the `--from-brd <dir>` path when one was given. The
   PRD this run authors is written **into that folder** as `prd.md`, beside the BRD
   artifacts it was derived from. `absent` is a graceful stop, not a folder to
   create — and it names **both** ways a BRD folder comes into being rather than picking one,
   because nothing on disk says whether this key names a BRD with a source document or a slice of
   one and a key's segment count is a naming convention, never a depth declaration (§1). This is the
   same stop `/brd-split` takes on the same resolution, worded the same way for the same reason:
   `CREATE_PRD_BRD_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /dev-workflows:brd-split on its parent.`
   Without `--from-brd`, unchanged in substance: resolve the folder with `resolve-address <KEY>` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), which searches every level §3 bounds and carries §5's legacy fallback; no matching rule is written here, because a second copy of §5's is the drift §1 warns about. This is the resolution every mention of the feature folder in this command means, step 3's rung-1 `idea.md` included. On `status: absent` the folder is auto-created by the first write (Phase 5) as `PRD-<KEY>-<slug>/` per §2's convention, `<slug>` from the idea title (else a kebab of the PRD summary) — resolution honors a folder that already exists wherever it sits, and never proposes one.
6. **Prior PRD (frontmatter-based).** Read `<feature-folder>/prd.md` and confirm frontmatter `issue_type: ValueIncrement`. A specs repo written before the rename holds `<KEY>_<slug>.md` instead; `addressing.md` §5 resolves the folder either way, and the frontmatter check is what identifies the draft inside it. If a PRD is found, this is an **existing PRD** — `/create-prd` is greenfield-only, so **redirect** (see Phase 1) to `/update-prd <KEY>` unless `--from-prd` **or `--from-brd`** is present.
7. **The BRD gate (`--from-brd` only).** Read `<BRD-dir>/brd-link.md` for its `parent:` (absent on a
   BRD that owns its source document) and any `depends-on:`; then read
   `<BRD-dir>/coverage-ledger.md` and take the **`disposition` written on each row of the gate set
   defined immediately below**. Both refusals below are
   `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5's rule, applied — that file is the
   authority for each and neither is restated here.

   **The gate set is this BRD's own ledger rows, and `claims:` narrows it only on a slice.** §5
   states eligibility over *its ledger rows*, and §3's creator table says what those rows are at each
   of the two levels a `<BRD-KEY>` can name — so the **level** picks the set, read off `brd-link.md`'s
   `parent:` exactly as `/brd-split` Phase 0 and `/brd-ground` Phase 0 step 6 read it:
   - **No `brd-link.md`, or one with no `parent:` — a BRD that owns its source document.** The gate
     set is **every row of its `coverage-ledger.md`**, which `/brd-intake` wrote one per `[BR#n]` in
     the inventory it extracted (§3). **`claims:` is not read at this level, and its absence is not a
     finding.** Only `/brd-split` writes that field, and only into a **child's** `brd-link.md`
     (`commands/brd-split.md` Phase 3 step 3, and the `covered-by` resolution in its Phase 4);
     `/brd-ground` and `/brd-package` only preserve a `claims:` another command wrote. On a BRD that
     owns its source document the field therefore does not exist — so a gate defined over it would read an
     **empty** set, find no `covered-here` row in it, and refuse the ordinary never-split BRD that is
     this route's primary case.
   - **`parent: <PARENT-KEY>` present — a slice.** The gate set is the rows its `coverage-ledger.md`
     holds for the `[BR#n]` its `brd-link.md` `claims:`. `/brd-split` wrote the claims list and the
     ledger together (§3), so the two normally coincide; where they do not, `claims:` is what this
     slice is answerable for and the narrower set is the right one. **They diverge in exactly one
     way, and it is benign in both directions**: a slice's ledger may hold an **orphan row** — a
     provisional claim `/brd-split`'s walk on the parent withdrew, whose ledger row stays and takes
     a terminal disposition (`coverage-ledger-format.md` §2, §3). `claims:` names none of them, so
     none is in this gate set; and were one read anyway it could change no verdict, because an
     orphan row is never `covered-here` (so it cannot manufacture eligibility) and never
     `unallocated` (so it cannot manufacture refusal 1). A slice claiming nothing has an
     empty gate set — the standing-empty-child state `/brd-split` Phase 4.5 keeps against a recorded
     reason — and reaches refusal 2 by the empty-set row of the table below, never refusal 1.

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
   CREATE_PRD_BRD_UNALLOCATED: <BRD-KEY>'s coverage-ledger.md still writes `unallocated` on <n> of the <total> requirement rows this BRD is answerable for <on a slice: — the rows its brd-link.md claims> — <[BR#n] list>. coverage-ledger-format.md §5 makes that a hard refusal: the allocation gate was never satisfied, and an unallocated row is neither an implicit `covered-here` nor an implicit `deferred-to` in either direction. Run '/dev-workflows:brd-split <BRD-KEY>' to walk each one to a terminal disposition, then re-run '/dev-workflows:create-prd <BRD-KEY> --from-brd'.
   ```
   `/dev-workflows:brd-split` is safe to name here **because there is something for it to do**: it is
   the command whose walk exists to move exactly these rows off `unallocated`, and it runs on a
   slice as readily as on a parent — allocate-only, one fewer resolution, and no child created. It
   is not, however, unconditionally *startable*: its own Phase 0 gates on this BRD's grounding
   findings each carrying a verifier verdict, and stops naming `/dev-workflows:brd-ground <BRD-KEY>`
   when they do not. Say so beside the offer, so an operator whose BRD has only been intaken is not
   sent into a second stop to learn the same thing.

   **Refusal 2 — no row of the gate set is `covered-here`.** The BRD holds no PRD of its own.
   Refuse, and say **where the requirements went** — which per §5 is *not always a list of children*,
   so branch on how the state was reached rather than assuming the first case. **Which rows are
   reachable depends on the level, so read the gate set's level first**: no row of a **slice's**
   gate set can be `covered-by` — a slice's `covered-by` rows are its orphan rows, which `claims:`
   does not name — so rows 1 and 2 are reachable only on a BRD that owns its source document and row
   3 only on a slice, while row 4 is a gate set with nothing in it at all and is reachable at
   either:

   | How every row of the gate set left `covered-here` | What this stop says |
   |---|---|
   | Some rows are `covered-by: <SLICE-KEY>` — the ordinary shape on a parent | Name those slices — and, per §6.1, resolve each delegated row one hop through the named child's own ledger and say which of them is **not** building the row delegated to it. A child that deferred, rejected or has not allocated it is not somewhere to send the reader |
   | No row is `covered-by` — and the only shape a **slice** reaches, for the reason §5 gives | Name **no** slice, because none holds one of these rows — and say what the gate-set rows *did* resolve to rather than calling them all obligations. §5 separates the three remaining dispositions: a `deferred-to` row is a live obligation of this BRD, a `rejected` one is an obligation of nobody and cites the `[DEF#n]` justifying it, and a `superseded-by` one was absorbed into the `[BR#n]` that replaced it. Then say a PRD needs one row resolved `covered-here` first |
   | The gate set is **empty** — a ledger holding no row at all, or a slice whose `brd-link.md` claims nothing | Report the emptiness and enumerate nothing, because there is nothing to enumerate: no requirement **this BRD is answerable for** reached any disposition, and naming one would invent it. A standing empty child may still hold orphan rows its parent's walk settled (§2); those are not this BRD's requirements and are not reported here as though they were. Say which emptiness it is, and name the one run that can change it — an inventory that yielded no `[BR#n]`, fixed by re-running `/dev-workflows:brd-intake <BRD-KEY> @<brd-file>` over this same folder (an existing folder is a re-run, not a refusal — `/dev-workflows:brd-ground` stops on this same state and says so); or a standing empty child, whose keep-or-remove `/dev-workflows:brd-split <PARENT-KEY>` alone resolves. Unlike the second and third rows, this one has a next command that exists in the state being reported |

   In the second and third cases **there is nothing to name and a child must not be invented**; the
   honest report is what each row actually resolved to, and — for the deferred ones — by whom.
   "The requirements are deferred" is the common shape of those two cases, not the whole of them: a
   BRD whose every gate-set row is `rejected` reaches this same refusal owing nobody anything, and
   saying it deferred them would be false. In the fourth there is not even that to report, and
   saying "the requirements were deferred" of a set holding no requirement would be false twice
   over. Stop as:
   ```
   CREATE_PRD_BRD_NOT_ELIGIBLE: no row of <BRD-KEY>'s coverage-ledger.md <on a slice: that its brd-link.md claims> is `covered-here`, so this folder holds no PRD of its own (coverage-ledger-format.md §5). <where the requirements went, per the row above that matches> <when <BRD-KEY> resolved to a BRD- folder: a BRD is a container and is never PRD-eligible itself — name the slices under it and re-run against the one that claims these requirements>
   ```

   **What this stop may offer, and what it may not.** Two of the four cases have a next command that
   exists in the state being reported, and they are the first and the last. The **first** offers
   `/dev-workflows:create-prd <CHILD-KEY> --from-brd`, once per named child **that the one-hop
   resolution showed is actually building its row** — the children resolving to `deferred`,
   `rejected`, `unallocated` or `unresolved` are named as facts and offered as nothing. That child
   run applies this same gate to its **own** ledger, which is the point: the offer is that a PRD is
   possible there, not a promise that every other row the child claims is already allocated. The
   **fourth** offers the one run that can put a row into an empty gate set — `/dev-workflows:brd-intake
   <BRD-KEY> @<brd-file>` on a BRD that owns its source document, `/dev-workflows:brd-split
   <PARENT-KEY>` on a standing empty child — and neither is a no-op in the state this stop reports.
   In the second and third cases **no command is offered at all, and the stop
   says why rather than going quiet**: re-running `/dev-workflows:brd-split <BRD-KEY>` on a ledger
   with no `unallocated` row is a no-op that changes nothing (§4), `/dev-workflows:brd-reconcile`
   never allocates, and no row is ever moved back to `unallocated` (§3) — so nothing in this plugin
   turns a `deferred-to` row into a `covered-here` one. Un-deferring a requirement is a decision the
   operator takes with the customer, not a command; naming one here would send the reader into a
   run that does nothing. Per the *When no option is safe to recommend* guidance in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`, nothing on that stop is marked
   `(Recommended)`.

   **Neither refusal carries a merge clause, and that is a fact about where they sit rather than an
   omission.** Both are Phase 0 stops, taken before this run has a deliverable, a branch or a
   handoff — so there is no `Phase handoff:` outcome line
   (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1) for a clause to resolve from, and every
   command they name either runs no `require-on-main` gate at all (`/dev-workflows:brd-intake`
   consumes nothing — §5's caller table) or gates on artifacts **another** run wrote and already
   merged. Phase 6 holds this
   command's only two placeholder sites — its choice array and the bullet that resolves it — and
   nothing on this route adds a third.

   Both refusals are read **as this run finds the tree**. Neither is a defect in the BRD: slicing a
   BRD entirely and slicing it partially are both ordinary outcomes (§5), and refusal 2 is what a
   fully-sliced parent is *supposed* to reach. **Neither is what an unsliced BRD reaches.** A BRD
   that owns its source document, was ground, and had `/brd-split` walk every inventory row to
   `covered-here` without carving out a single slice is the route's ordinary shape (§4 — the walk's
   escape valve exists precisely so an unsplit BRD can complete), it has no `claims:` field and never
   will, and it passes both refusals here on its ledger's own rows.

`/create-prd` is **cwd-agnostic** and needs **no repos mounted** (product-level; no code scan).

---

## Phase 1 — Configure

Use `choices` arrays; the last choice is always `"Other… (describe)"`.

1. **Confirm** the feature folder, the profile, and the resolved `idea.md` (or "none — grill from scratch"); under `--from-brd`, the BRD folder, the profile (`--full` unless a flag overrode it), and — instead of an idea — a `from BRD:` line naming `<BRD-KEY>`, its `parent:` if it has one, its `depends-on:` if any, how many of its gate-set rows (Phase 0 step 7) are `covered-here` out of how many, and whether `prd-seed.md` and `decisions.md` were found.
   - Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).
   - Show the `prior art:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md` resolved — `ON <vault-root>` or `OFF (<reason>)` — verbatim (off switch: --no-prior-art). Run `resolve-prior-art create-prd` per that reference to obtain it; it runs exactly once per run.
2. **Existing-PRD handling** (only if Phase 0 step 6 found a PRD for `<KEY>`):
   - **`--from-brd` present** → "author this BRD's PRD" conflicts with "a PRD for this BRD already
     exists here". `/update-prd` takes no `--from-brd`, so the redirect is honest about what it
     drops: it refreshes the PRD already on disk, it does not re-read the seed.
     ```
     choices: ["Refresh the existing <BRD-KEY> PRD — /dev-workflows:update-prd <BRD-KEY> (the BRD seed is not re-read) (Recommended)", "Overwrite <BRD-KEY> as a fresh PRD authored from the BRD seed (archives the current one)", "Cancel", "Other… (describe)"]
     ```
   - **No `--from-prd`** → `/create-prd` is greenfield-only; **redirect**:
     ```
     choices: ["Switch to /dev-workflows:update-prd <KEY> to refresh it (Recommended)", "Overwrite as a fresh PRD (archives the current one)", "Cancel", "Other… (describe)"]
     ```
   - **`--from-prd` present** → "create new (seeded)" conflicts with "a PRD already exists here":
     ```
     choices: ["Update the existing <KEY> instead — /dev-workflows:update-prd <KEY> (seed ignored) (Recommended)", "Overwrite <KEY> as a new seeded PRD (archives the current one)", "Cancel", "Other… (describe)"]
     ```
3. **Draft idea → warn-and-fold** (no-op under `--from-brd`, which resolves no idea; the equivalent there is the open `[VD#n]`/`[CD#n]`/`[AS#n]` set Phase 2 carries in). If `idea.md` is `status: draft` (open `[NEEDS CLARIFICATION]`), note that the grill resolves those items — do **not** hard-block.

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

Offer `choices: ["Switch to --full", "Keep <profile>", "Other… (describe)"]`. On
"Keep", proceed unchanged. For a SIMPLE / MODERATE classification, or when the
profile is already `--full`, this nudge does **not** fire.

---

## Phase 2 — Read the seed

Read the resolved `idea.md` **directly** (it is the plugin's own format — `idea-reader` is for arbitrary external sources and is not used here). Extract Problem / Who / desired outcome & value / rough scope / signals & evidence / candidate success signal, plus any open `[NEEDS CLARIFICATION]`. Carry the idea's `sources[]` forward to **propagate** into the PRD frontmatter (the real provenance — RFE key / an existing PRD's key / community-post URL / prompt), and record `derived_from` = the idea's own resolved path — read here from `idea.md`'s own frontmatter, never from a relocation, since `/create-prd` no longer moves it.

Optionally ground in the idea's cited sources and any strategy/vision docs the user points to. **No code scan; no repos.**

If `--from-prd` was resolved (Phase 0 step 2a), also read the **seed PRD** (body + comments) as read-only
grounding — structure, personas, scope shape, and metrics to *adapt* (never copy) to the new PRD.

If there is no idea (Phase 0 ladder exhausted), grill the PRD from scratch.

### `--from-brd` — read the product-altitude seed and the decision register

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

A `--from-brd` run with **no `prd-seed.md`** is not a stop, and is the **ordinary** shape: nothing on
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
`--from-brd` default (Phase 0 step 2) gives this PRD a spine and nothing else — and every `open`,
`reopened` and open `[AS#n]` the partition just produced would have no product-altitude section to
land in. Where the register holds at least one such record and the profile is `--lean`, surface a
**non-blocking** choice before Phase 2.5, naming the count:

```
choices: ["Switch to --full so the open register items have a home (Recommended)", "Switch to --hybrid (light open-questions list)", "Keep --lean — the open items are reported by id, never written into the PRD", "Other… (describe)"]
```

On "Keep `--lean`", the final report names every one of them by id. A gap this command silently drops
is one no later reader can find, which is the failure the register's own `[AS#n]` surfacing rule
exists to prevent.

---

## Phase 2.5 — Grounding: documentation + vault prior art (optional)

Dispatch both grounding agents **in a single response** so they run in parallel. Each is independent; either being OFF never suppresses the other.

**Docs.** Run `resolve-docs-grounding create-prd` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the idea's problem/goal + PRD themes, `jira_key` = `<KEY>`, and `themes` from the idea. When OFF, skip silently.

**Prior art.** Using the `resolve-prior-art create-prd` result from Phase 1: when `prior_art: ON`, `dispatch-prior-art-finder` per `${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md` with `feature_summary` = the idea's problem/goal, `themes` from the idea, and `known_refs` = every filesystem path in the idea's `sources[]` as `{path, …}`, every Jira key in `sources[]` as `{jira_key, …}`, and the Jira key of each `## Prior art` bullet as `{jira_key, …}` — all with `has_summary: false`, since this command reads `idea.md` directly and holds no summaries of its own. Take the **key**, not the wikilink, from a `## Prior art` bullet: a wikilink resolves by file name and dangles the moment a vault item is renamed, which is exactly why the bullet carries both. Recorded `sources[]` paths may dangle for the same reason; the finder drops what it cannot resolve. When OFF, skip silently.

**Under `--from-brd` both agents run unchanged; only their inputs are substituted**, because there is
no `idea.md` to take them from. `feature_summary` and `themes` come from `prd-seed.md` (falling back
to the `statement` of each product-altitude `decided` record when the seed is absent), and
`known_refs` is every `[BR#n]` source path and prerequisite `<BRD-KEY>` the run already holds from
`brd-link.md` — again with `has_summary: false`, for the same reason: this command reads those files
directly and holds no summaries of its own. Neither agent is given `ard-seed.md` or `spec-seed.md`.

Carry both digests into Phase 3 with **grill-rank** consumption. When both are OFF the PRD is authored exactly as today.

---

## Phase 3 — Author via grill

**Interview technique (grilling — embedded; no runtime dependency).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split (look up facts from the idea/sources; put only decisions to the user), walk the design tree in dependency order, continue to shared understanding then write each section. Rank every `docs_challenges` and `prior_art_challenges` entry from Phase 2.5 into the grill's question order; a challenge competes for attention, it never suspends the spine below.

Author `prd.md` live against `${CLAUDE_PLUGIN_ROOT}/references/prd-format.md` for the selected profile, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`. Walk the **spine** in dependency order:

1. Frontmatter — `relevant_for_release_notes` (defaults to `yes`; ask only to confirm a `no`); `sources` (propagated), `derived_from`, `seeded_from_prd` (only when `--from-prd` was used), and `jira_key` — **written here only on the `/idea` route**, where the positional token is a key the user minted on the tracker before the run, so it is a tracker identity the moment it is written. **Under `--from-brd` `jira_key` is omitted here**, and the round-trip's step 1 is what writes it, because that step is where a tracker identity is minted for the first time; writing `<BRD-KEY>` into it now would put a `$SPECS_PATH` folder name in the one field every downstream consumer reads as a tracker key, and nothing later could tell a minted key from an un-minted address. Its absence is therefore load-bearing and is read as "no tracker identity yet" by nothing in the plugin — no offer is withheld for it any more. **Under `--from-brd`, additionally `brd_key`, `brd_parent` and `depends_on`**, per `${CLAUDE_PLUGIN_ROOT}/references/prd-format.md`'s frontmatter block, each read from what Phase 0 step 7 already holds and none of them asked of the user: `brd_key` is the resolved BRD key, `brd_parent` is `brd-link.md`'s `parent:` (**omitted** on a BRD that owns its source document, where there is none), and `depends_on` is its `depends-on:` list (**omitted** when empty). Writing them here records the BRD identity and the customer-committed prerequisites on the PRD itself. **No command consumes the three fields yet** — neither `/dev-workflows:epics` nor `/dev-workflows:ready` reads any of them, and wiring a consumer is separate work with its own review. They are written anyway because provenance captured at authoring time is the precondition for any future consumer: re-deriving it later would mean re-reading a BRD tree that may have moved on. `derived_from` is **omitted** on this route — there is no `idea.md` this PRD was built from, and pointing it at a BRD artifact would misname the field; `brd_key` carries that provenance instead. `sources` still carries real provenance: the BRD's own source document, as `provenance: markdown` with `ref:` resolved **by level, and never from `brd-link.md`** — no writer of that file emits a `source:` field at either level, so a ref read from there would resolve to nothing. On a BRD that owns its source document, `ref:` is the single file under `<BRD-dir>/brd/source/`, which `/brd-intake` copied in verbatim and which nothing afterwards edits or moves. On a **slice**, `ref:` is the path the `source:` line at the top of `<BRD-dir>/brd/brd-inventory.md` names — the `parent:`/`source:` header `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §2.1 fixes and `/brd-split` writes — which resolves against the **parent's** folder, because a slice holds no `brd/source/` of its own and that header exists precisely so an anchor can be followed out of it. Name the file the ref was read from in the final report, so a reader can tell the two resolutions apart. Do NOT ask for `release_versions`, `change_type`, or `release_notes_category` — they are Jira dropdowns the PM sets on the ticket and the importer returns on the round-trip (`${CLAUDE_PLUGIN_ROOT}/references/prd-format.md`); `/release-notes` reads them from the import. Dates and deprecation details also stay out of frontmatter — they belong in the release-notes Summary.
2. **Problem**
3. **Goal** (crisp 2–3 sentences)
4. **Target audience** (personas)
5. **User Stories** (`[US#N]`)
6. **Acceptance Criteria** (`[AC#N]` per story)
7. **Scope** (In / Out)
8. **Success Metrics** (`[SM#N]`)

Then author the profile's **adapt-in clusters**, each **pulled only when the idea warrants it** (never an empty section). **For a complex PRD (`classification` SIGNIFICANT), actively author the `[FR#N]` (full) and `[UC#N]` (hybrid/full) clusters** within the chosen profile — lower the bar for pulling them in, because ID'd functional requirements and use cases feed a finer downstream `/epics` `_coverage.md` (traceability to `[FR#N]`/`[UC#N]`, not only `US`/`AC`/`SM`); still never an empty section. Fold the idea's open `[NEEDS CLARIFICATION]` into the grill; resolve to zero where possible, leaving genuinely-unresolvable ones under `## Assumptions & open questions` (hybrid/full). Keep the PRD **product-level** — no implementation detail. **Self-consistency check:** before writing each section, check it against the already-settled sections — a new `[AC#N]` must not deliver an Out-of-scope behaviour, the `## Goal` must not assert a scope the `## Scope` contradicts, and `[US#N]`s must not conflict. Resolve any contradiction inline with the user, or record it under `## Assumptions & open questions` — never leave it implicit (the Opus `prd-reviewer` flags a silently-baked contradiction).

### `--from-brd` — the grill is restricted to gaps

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
**Universal checks**, the **Jira-key collision** check (run on the PRD body below the frontmatter),
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
- **`BLOCK`** — fix the BLOCKER findings inline (the orchestrator/grill edits the PRD — no delegated writer) and re-review **once**. If still `BLOCK`, escalate per the `Review verdict BLOCK` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` for each unresolved BLOCKER (`choices: ["Provide manual fix notes", "Defer to a follow-up issue", "Override and accept", "Cancel", "Other… (describe)"]`).
- **`PASS` / `PASS WITH RECOMMENDATIONS`** — proceed. Cap: one fix cycle + one re-review.

---

## Phase 5 — Handoff

Write the feature folder: `prd.md`. The in-contract `idea.md` is already there, committed by `/idea`; an out-of-contract idea stays where it is.

**Under `--from-brd`, also close the consumption loop before the offer.** The design's *Consumption
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

On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: prd`, `feature_folder` as resolved in Phase 0, `deliverable_paths` = the PRD file — **plus, under `--from-brd`, `decisions.md`**, because the `consumed_by` write above lands there and an uncommitted consumption record is one no later run can read; `prd-seed.md` is not staged, because this run does not write to it — `title: <KEY> Add Product Requirements Document — <summary>`, and `body_facts` = the resolved profile (`--lean`/`--hybrid`/`--full`), the adapt-in clusters pulled, the user-story and acceptance-criteria counts, any `[NEEDS CLARIFICATION]` markers carried in, the `prd-reviewer` verdict, and — under `--from-brd` — the `<BRD-KEY>` this PRD was seeded from and how many items were marked `consumed_by: PRD`; emit its §4.1 outcome line in the Final report.

---

## Phase 6 — Next steps

Offer these — clearly labeling the role handoff:

```
choices: ["Draft the release note now — /dev-workflows:release-notes <ADDRESS> (PM) (Recommended)", "Hand to a Product Architect — /dev-workflows:create-ard <KEY> (PA, optional) <merge-clause>", "Hand to a Product Engineer — /dev-workflows:epics <ADDRESS> (PE)", "Stop here", "Other… (describe)"]
```

**Two keys appear in that array and they are not interchangeable.** `<KEY>` is the address this run
was invoked with — on the `/idea` route it is the tracker key the PM minted before the run, which is
why `/dev-workflows:create-ard` can be handed it bare; under `--from-brd` it is a `<BRD-KEY>` naming a
`$SPECS_PATH` folder, and the PA option takes `--from-brd` with it (see the PA paragraph below).
There is one key now, and every option below takes it — the address this run was invoked with, which names the folder this run wrote into.

- **`/dev-workflows:release-notes <ADDRESS>`** (PM) — draft the customer-facing release note now (the cost model's `pm`/`prd-creation` inferred case: no spec/design yet).
- **`/dev-workflows:create-ard <KEY>`** (PA, **optional**) — hand to a Product Architect to author the grounded architecture document. **On the `/idea` route** (under `--from-brd`, see the PA paragraph below) it gates this PRD on the specs repo's default branch (its own Phase 0), so it stops where this PRD reached a branch and falls back to the Jira export — reported, never silently — where it reached none. `<merge-clause>` is the placeholder `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` owns, resolved from this run's own `Phase handoff:` outcome line (§4.1) and never written as the unconditional "once the pull request above is merged": a declined handoff, a failed push and a nothing-to-commit run each leave a different wait, and two of them open no pull request to wait on. It is a placeholder, not an instruction to reword an option, so the array is still presented verbatim per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
- **`/dev-workflows:epics <ADDRESS>`** (PE) — hand to a Product Engineer to split the PRD into Epics (or author a PRD-level spec → `/dev-workflows:specify <ADDRESS>`, which resolves the same folder through the same entry point).

The other two options carry no clause, and that is checked, not assumed: `/dev-workflows:release-notes` runs no `require-on-main` at all, and `/dev-workflows:epics` gates only `<PRD-dir>/specification.md` — a file this run does not write.

**Every option is presented unconditionally now, and the reason the two used to be withheld is
gone.** `/dev-workflows:epics` and `/dev-workflows:release-notes` were held back until a tracker key
had been minted *and* an export produced against it, because both resolved that export and found
nothing without it. Neither reads an export any more: both resolve a folder in the specs tree, which
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

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked), `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment / user halt (missing key, unset `$SPECS_PATH`, cancellation) or a work-quality review BLOCK. **The two `--from-brd` refusals are of that second class, not the first**: `CREATE_PRD_BRD_UNALLOCATED` and `CREATE_PRD_BRD_NOT_ELIGIBLE` report the state of the operator's own BRD tree, not a capability this plugin lacks, so neither `emit-block`s. `CREATE_PRD_BRD_NOT_FOUND` and `CREATE_PRD_TWO_SEEDS` are the same.

**Session-hygiene invariant.** End Phase 6 with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the
`resume.md` write runs later, in the terminal cost phase, per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the
guidance only),
then a span suggestion (PM continue → `/compact`; PA/PE handoff → `/clear`). No `/rename`
label yet (no PRD-Key). Guidance only, never auto-run.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/create-prd`; what was authored (PRD + profile); key events (source-ladder friction, unresolved clarifications, BLOCK reviews — or 'none'); workarounds; the `prd-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6) with the Lessons Learned report, `command: /create-prd`, the run's `jira_key` — or, where `--from-brd` left it unwritten until the round-trip, the run's `brd_key`, which is the key that matches this PRD's own `$SPECS_PATH` folder and so keeps the write on that reference's primary tier instead of dropping it to the unfiled one — `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its `emit-cost` entry point with `command: /create-prd`, `phase: prd-creation`, `role: pm`, the run's `jira_key` (or `brd_key`, on the `--from-brd` route, for the reason step 2 gives), `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite `<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the pointer reflects the completed run, and before the commit step below, so it is included in it. Redact per §1. Silent; the printed `### Context hygiene` guidance already appeared in the report.
5. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/create-prd)` — or `NOISSUE …` when the run resolved no key at all — with no `Co-Authored-By` trailer. **Under `--from-brd` that `<KEY>` is the BRD key, not `NOISSUE`**: this is a specs-repo commit-message prefix, not a tracker lookup, and the BRD key is the key this run resolved and the name of the folder the staged artifacts sit in. A key the Jira round-trip has not yet minted is missing from `jira_key`, which is a different field for a different purpose, and pushes to the branch this run's handoff phase created (§4.1). It NEVER touches a code repo, a docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is offered only in Phase 5; the terminal step above commits only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the PRD path + profile; US/AC/SM counts + which adapt-in clusters were included; open-question count; the `prd-reviewer` verdict; the prose style-check outcome (`OK` | `N fixed, M remaining` | `SKIPPED`); the `Phase handoff:` outcome line from `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1); the Jira round-trip reminder; resolved model routing (+ any Opus degradation); the feedback + cost paths; the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; and the next-step recommendations.

**Under `--from-brd`, additionally:** the `<BRD-KEY>` seeded from and its resolved folder; which of
`prd-seed.md` and `decisions.md` were present; the frontmatter `brd_key` / `brd_parent` /
`depends_on` as written (naming any omitted, and why); how many of the gate-set ledger rows
(Phase 0 step 7) are `covered-here`, read from `coverage-ledger.md` — **not** as a `ledger:` line, which this command
neither parses nor prints (Phase 0 step 7); every `[VD#n]`/`[CD#n]`/`[AS#n]` carried in as a gap
rather than an input, by id and status; every contradiction Phase 3 recorded rather than decided,
with the reopening route named for each; every product-altitude item still `consumed_by: none`, by
id, per the design's *Consumption tracking* section (§7.3); and any sub-product-altitude content the
grill surfaced and left for `/dev-workflows:create-ard` or `/dev-workflows:specify` instead of the
PRD (D4) — naming the command, never a seed file, since the register those runs will read that
content out of is the one this run already read.
Both `--from-brd` refusals are Phase 0 stops and never reach this report.
