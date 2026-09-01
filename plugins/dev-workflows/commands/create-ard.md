---
name: create-ard
description: Architecture-authoring workflow (Product Architect phase, sub-project 3 of the PRD-creation flow). Grounds on the mounted implementation repos (architect-driven discovery — no PRs) and authors an ARD for a PRD (/create-ard <PRD-KEY>) or an Epic (/create-ard <PRD-KEY> <Epic-KEY>, inheriting the PRD-level ARD), against references/ard-format.md, gated by the Opus ard-reviewer, written to $SPECS_PATH/specifications/<KEY>-<slug>/. Optional; scoped; product-architecture level (no code writing). Introduces the pa role. the BRD route seeds the run from a reconciled BRD instead of a PRD: it resolves the BRD-route PRD- slice folder (the folder carrying brd-link.md) and refuses a BRD- container outright, since §4.1's tree places ard.md only inside a PRD folder; it reads that slice folder's architecture-altitude ard-seed.md, the architecture decisions in decisions.md and the verified [CG#n]/[DG#n] findings, seeds the ARD's grounding-findings section and its AD#N from them, freezes every [VD#n]/[CD#n] against the grill, runs no PRD read and gates no PRD, and marks each consumed item consumed_by: ARD.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Author an Architecture Requirements/Decision Document for the resolved item: $ARGUMENTS

`/create-ard` is **sub-project 3 of the PRD-creation flow** — the **Product Architect (PA)** phase. It
grounds on the mounted implementation repos and authors an **ARD** that establishes the architecture
invariants the downstream (`/specify`, `/design`, `/implement`) will later inherit. The ARD is
**optional** (a simple PRD may not need one) and **scoped by the kind of the address it is given**:

- `/create-ard <PRD-KEY>` → a **PRD-level** ARD.
- `/create-ard <EPIC-KEY>` → an **Epic-level** ARD (inherits the PRD-level ARD read-only). The Epic's
  own key is the whole address: it encodes its ancestry, so the PRD is the folder above it and is
  never typed beside it (D4).
- `/create-ard <SLICE-KEY>` → an ARD on the **BRD route**, authored in the `PRD-` slice folder
  `/brd-split` carved and seeded from the reconciled BRD instead of from a PRD. A `BRD-` container is
  refused (Phase 0 step 1a). One address on every route: a second positional token is refused
  (Phase 0 step 1, `CREATE_ARD_ONE_ADDRESS`).

Usage: `/create-ard <ADDRESS> [--no-docs]`, where `<ADDRESS>` is a key or an `@<path>`.

It authors architecture only — no code writing; grounding is **architect-driven** (there are no PRs at
this stage). Zero external calls.

---

## Phase 0 — Resolve input
1. **Resolve the address.**

   **One resolution, both routes.** Parse the **single positional address** from `$ARGUMENTS` — a
   `<KEY>`, or an `@<path>` naming a folder — and resolve it with `resolve-address`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3). A key that fails §1's grammar stops with
   `CREATE_ARD_NEEDS_KEY: /create-ard needs an address (^[A-Z][A-Z0-9_]*(-\d+)+$, e.g. EPIC-008 or the slice EPIC-008-01) — re-run '/dev-workflows:create-ard <ADDRESS>'.`
   Shape only, and never checked against anything (§1) — a key names a folder in `$SPECS_PATH`.

   **A second positional token is refused, on every route** (D4). There is no `<PRD> <Epic>` form to
   fall back to: an Epic key encodes its own ancestry, so a second argument would be derivable from
   the first and able to disagree with it, which is the failure class D4 exists to remove. Stop
   gracefully:
   `CREATE_ARD_ONE_ADDRESS: /create-ard takes one address; <second-token> was given as a second. The kind of the folder the address resolves to is what sets the altitude — an EPIC- folder gives an Epic-level ARD, with its PRD read from the folder above it; a PRD- folder gives a PRD-level one. Re-run '/dev-workflows:create-ard <ADDRESS>' with the single address you meant.`

   **The resolved kind decides the altitude**, which is what replaces the old two-key grammar:
   - a `PRD-` folder → `<PRD>` is its `key`, `<EPIC>` is `null`;
   - an `EPIC-` folder → `<EPIC>` is its `key` and `<PRD>` is its parent's;
   - a `PRD-` folder holding a `brd-link.md` → the BRD route. Define `<SLICE-KEY>` = the resolved
     folder's `key`.

   **The BRD route is detected, not declared.** A folder carrying `brd-link.md` was produced by
   `/brd-split` and holds the seed this command reads; nothing about that needs restating on the
   command line, and a flag that could disagree with the folder it names is one more disagreement to
   have. Print which route the run entered before doing anything else.

1a. **Refuse a `BRD-` container — on either route, and the moment step 1 returns `status: found`.**
   A `BRD-` folder is **not** a fourth altitude, and this command used to route one onto the BRD
   route. **This test is not part of the BRD-route branch and must not be folded into it**: that
   route is detected from a `brd-link.md`, and a root BRD folder need not carry one — `/brd-intake`
   writes none, and only `/brd-ground`, `/brd-split` and `/brd-package` ever do — so a
   route-conditioned refusal would let `/create-ard <ROOT-BRD-KEY>` fall through and author an ARD
   into the container. It is a container: the design's §4.1 tree places `ard.md`
   only inside a PRD folder, while a `BRD-` folder holds `brd/`, `grounding/`, `interview/`,
   `coverage-ledger.md`, `decisions.md` and `slices.md` — and no ARD. Authoring one there writes an
   artifact the tree has no place for and that
   `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` would then look for one level away.

   **The test is the directory prefix, and never the folder's asserted `kind:`** — `/brd-split`
   writes `kind: brd` into the `brd-link.md` inside a `PRD-` slice folder, so a slice asserts `brd`
   while being exactly the folder an ARD belongs in, and a gate on the asserted kind would refuse
   every slice.

   **Where the folder resolved through `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §5's legacy
   fallback and carries no prefix, the question is answered by positive evidence that it is a BRD,
   never by the absence of a file** — `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md`
   §5.1, the shared authority `/create-prd` and `/specify` take this same test from. In short: a
   legacy folder carrying `coverage-ledger.md` or `brd/brd-inventory.md`, and no `brd-link.md`
   naming a `parent:`, is a root container; a legacy folder carrying **neither** of those two files
   is a legacy **idea-route PRD folder**, which holds `prd.md` and no `brd-link.md` either — this
   refusal does not fire on it, and refusing it would offer `/dev-workflows:brd-split` on a folder
   with no coverage ledger to walk. Stop gracefully:
   ```
   CREATE_ARD_BRD_NOT_SLICED: <BRD-KEY> resolves to a BRD- container at <path>, and a BRD is never the folder an ARD is authored in — its architecture is authored in the PRD- slices under it, one ARD each (coverage-ledger-format.md §5). <the remedy, per the branch below>
   ```

   **The remedy is the same two branches `/dev-workflows:create-prd`'s own container refusal takes,
   and it is a directory listing rather than a ledger read** — this command reads no coverage ledger
   and does not start now. Enumerate slices by `/brd-split` Phase 0 step 9's **positive test**: an
   immediate subdirectory carrying a `brd-link.md` whose `parent:` names this BRD.
   - **One or more slices** — the ordinary shape, since a split always confirms at least one. Name
     every slice and offer `/dev-workflows:create-ard <SLICE-KEY>` once per slice. Do **not** name
     `/dev-workflows:brd-split <BRD-KEY>`: the slices exist, and on a parent whose ledger is fully
     allocated that run is a no-op (`commands/brd-split.md` Phase 0 step 10).
   - **No slice at all** — `/dev-workflows:brd-split <BRD-KEY>` is the run that carves one, walking
     every row still `unallocated` and always confirming at least one slice (its Phase 2). **Two
     conditions travel with that offer**, in its own text, because this command holds neither
     answer: its Phase 0 gates on this BRD's grounding findings each carrying a verifier verdict and
     stops naming `/dev-workflows:brd-ground <BRD-KEY>` when they do not; and **where this BRD's
     ledger leaves no row `unallocated` that run is a no-op** (its Phase 0 step 10) and carves
     nothing, since nothing in this plugin moves a terminal row back to `unallocated`
     (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3). Say what the operator does
     then rather than leaving the offer to fail silently: either the one slice the walk confirmed was
     removed as a standing empty child, in which case every requirement is `deferred-to`, `rejected`
     or `superseded-by` and un-deferring one is a decision taken with the customer rather than a
     command; or the ledger records a fate a container can no longer hold — a **root** row
     `covered-here` — where re-running `/dev-workflows:brd-intake <BRD-KEY> @<brd-file>` over this
     same folder is a re-run rather than a refusal and rewrites the ledger with every row
     `unallocated`, after which `/dev-workflows:brd-split` has rows to walk.


2. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
3. **Feature folder.** Resolve it with `resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3) — `<PRD>` for a PRD-level run, `<EPIC>` for an Epic-level one, the kind it returns confirming which. That entry point searches every level §3 bounds and carries §5's legacy fallback, so no matching rule is written here: a second copy of §5's is the drift §1 warns about. Every later mention of the feature folder in this command — the PRD gate's `ls-tree` path and Phase 2's PRD read included — names the folder resolved here. **`status: absent` is a stop, not a folder to create.** This command creates no folder in the specs tree. It cannot even choose a §2 prefix for one: `resolve-address` returns no `kind` for a folder that does not exist, and the two kinds it would have to choose between are minted by different commands. **An `EPIC-` folder is created by `/dev-workflows:epics` and by nothing else** (D6) — auto-creating one here would put an Epic in the tree that no `/epics` run ever drafted, holding an `ard.md` and no `epic.md`, invisible to the `EPIC-` enumeration every other command reads. Stop gracefully:
   ```
   CREATE_ARD_NOT_FOUND: no folder found for <KEY> under $SPECS_PATH/specifications/ (every level addressing.md §3 bounds, plus §5's legacy fallback) — /create-ard architects an existing PRD or Epic folder and creates neither. A PRD folder is created by /dev-workflows:idea <KEY> or /dev-workflows:create-prd <KEY> on the idea route, and by /dev-workflows:brd-split on its parent on the BRD route; an EPIC- folder is created by /dev-workflows:epics <PRD-ADDRESS> and by no other command.
   ```
   Every command that stop names creates the folder it claims to: `/idea` and `/create-prd` both write `PRD-<KEY>-<slug>/` on their first write, `/brd-split` carves the slice folder, and `/epics` writes `EPIC-<PRD-KEY>-NN-<eslug>/` under the PRD folder it resolved. Resolution honors a folder that already exists wherever it sits, and never proposes one.

   **On the BRD route this is the resolved `PRD-` slice folder**, and it is never created here:
   resolve it with `resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), which
   already searches both levels — step 1a is what refuses the container the upper level holds — or
   read an explicit BRD-directory path when one was given. The ARD this run
   authors is written **into that folder**, beside the BRD artifacts it was derived from. `absent` is
   a graceful stop, not a folder to create — and it names **both** ways a BRD folder comes into being
   rather than picking one, because nothing on disk says whether this key names a BRD with a source
   document or a slice of one, and a key's segment count is a naming convention, never a depth
   declaration (§1):
   `CREATE_ARD_BRD_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /dev-workflows:brd-split on its parent.`
   Where an explicit BRD-directory path was supplied and is not an existing directory, the same stop
   substitutes that path for the search clause — `no BRD folder at <path> (supplied with the BRD route)` —
   because "both levels searched" would describe a search this run did not perform.
4. **Prior ARD.** If the target `ard.md` exists → Phase 1 offers refine-vs-fresh. **On the BRD route the target is `<BRD-dir>/ard.md`** — the same glob in the same folder, keyed by the BRD key this run resolved.
5. **Optionality advisory.** Gauge size — the PRD's user-story count / scope breadth / number of candidate repos. For a small, single-repo PRD, note "an ARD may be optional here" and offer `choices: ["Author the ARD anyway", "Stop — no ARD needed"]`. **On the BRD route gauge the same question off the seed instead**, since there is no PRD to count user stories in: the number of architecture-altitude `decided` records in `decisions.md`, the number of `[CG#n]`/`[DG#n]` findings at architecture altitude, and the number of repositories `grounding/baselines.md` pinned. A BRD whose whole architecture altitude is one decision against one repository is exactly the case the advisory exists for.

`/create-ard` is **cwd-agnostic**; it reads the PRD/Epic — or, on the BRD route, the BRD folder's seed, register and findings — and scans repos under `$REPOS_PATH`.

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.

**Gate the PRD.** Execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against the PRD file in `specifications/<PRD>-<vslug>/` — **resolve its actual name on the ref first**: `git -C "$SPECS_PATH" ls-tree --name-only "origin/<default>" "specifications/<PRD>-<vslug>/"` and take `prd.md` when the listing carries it, falling back to a `<PRD>_*.md` entry only when it does not — the keyless `prd.md` is what `/create-prd` and `/update-prd` write, and the `<KEY>_<slug>.md` form is the pre-rename shape a specs repo written before increment A still holds (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §5). **Gating the legacy glob alone was a defect**: it matches nothing in a current repo, so the gate returned `absent` for every PRD that was present and the rows D/E stop could never fire. A human-adjusted slug is a supported state — `/create-prd` and this command's own Phase 2 reader both locate the PRD by glob plus frontmatter, and the feature folder is matched by key-number for the same reason — so gating an exact derived filename would report `absent` for a PRD that is present, and would let a slug-drifted file on a plugin branch escape the rows D/E stop entirely. Map its §3.7 return value by `stopped` first, never by `on_main` alone. Any stopping state → stop per §4.4. Otherwise (`stopped: false`): on `pass`/`pass_amending`, read the authored PRD in Phase 2 as today; on `absent`, the existing the folder read fallback applies — but report it: *"No authored PRD on `<default>` for `<PRD>` — architecting from the resolved folder at `<path>`. If a PRD exists on a branch, this run would have stopped; it does not, so none does."*; on `unmanaged`, behave exactly as before this feature — reachable here even after step 2's own `$SPECS_PATH` check, since that check only rejects an unset value, never an invalid path or a non-git directory.

**On the BRD route the PRD gate does not run, because the PRD is not this route's content source.**
The gate exists so this command never architects from a PRD that is unmerged or stale; here the
content source is the BRD folder's `ard-seed.md`, its architecture-altitude decisions, and its
verified findings, and the PRD — which may not exist at all, since `/create-prd` on the BRD route is not a
prerequisite for this one — is read by nothing in this run. Gating an artifact the run does not read
would promote an input this route never had into a prerequisite, which is exactly what
`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §5 rule 3 forbids; and its `absent` branch above
falls back to reading the folder itself, which on this route means reading a folder
key to a tracker lookup. So the gate is skipped, not re-pointed, and §3.4's `/create-ard` row keeps
describing the route that runs it. What puts the seed on the default branch instead is the
`/brd-*` family's own handoff discipline: each of those commands lands its deliverable on the specs
default branch and the next refuses to start until it is there, so a reconciled BRD folder is already
merged by the time this route reads it. This mirrors `/dev-workflows:create-prd` on the BRD route, which
likewise skips the gate on the input its own seed replaces.

---

## Phase 1 — Configure
Use `choices` arrays; 2–4 options, and never author an "Other" option — the harness supplies the free-text escape itself (`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` §0).
1. **Confirm** the scope (PRD-level vs Epic-level) and the feature folder. **On the BRD route**, confirm instead the resolved `PRD-` slice folder and a `from BRD:` line naming `<SLICE-KEY>` and the `parent:` its `brd-link.md` records — a run on this route is always slice-level, since step 1a refuses the container — its `depends-on:` if any, and which of `ard-seed.md`, `decisions.md`, `grounding/code-grounding.md` and `grounding/design-grounding.md` are present — a stat, not a read; the read is Phase 2.
   - Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).
2. **Refine vs fresh** (only if a prior `ard.md` exists): `choices: ["Refine the existing ARD (Recommended)", "Start fresh — overwrite", "Cancel"]`.
3. **Repos search base (`$REPOS_PATH`).** Read `${REPOS_PATH:-/workspace}` (may be colon-separated): `choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel"]`.
4. **Repo refresh policy** (governs Phase 3's `code-scanner`): `choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh"]`.

---

## Phase 1.5 — Classify + model routing
Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE | SIGNIFICANT | HIGH-RISK   # architecture; SIGNIFICANT common for cross-repo PRDs
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # the folder read, code-scanner, impl-maintenance
  review_model:    <§2 Opus chain>     # ard-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + ARD authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

**Tiered HARD model gate (like `/design`):** for `SIGNIFICANT` / `HIGH-RISK`, require an Opus session — if `opus_available` is false, stop: `choices: ["I'll relaunch /dev-workflows:create-ard on Opus (Recommended)", "Override — proceed on the current model (logged in the final report)", "Cancel"]`. For `SIMPLE`/`MODERATE`, degradation is advisory (record in `notes`).

---

## Phase 2 — Read the PRD (+ Epic, + inherited ARD)

**On the BRD route everything in this phase down to the BRD-route section below is replaced, not
adapted**: no PRD read of either kind, and the inherited-ARD resolution
uses the `(prd, epic)` pair that section derives. "Epic-level run" in the paragraphs immediately below
means a run whose single address resolved to an `EPIC-` folder, which the BRD route never does — that
route resolves a `PRD-` slice folder — so a slice's `scope: epic` frontmatter (Phase 4) is a
statement about altitude and inheritance, not about this phase's run mode.

Read the PRD from the folder `resolve-address <PRD>` returned (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3) — its `prd.md`, whose frontmatter is `kind: prd`, when present (authored source); else dispatch the folder read to read it from the export:

**Read the resolved folder directly.** PRD-level → its `prd.md`. Epic-level → the Epic folder's own
`specification.md` and `design.md` where present, plus the parent PRD folder's `prd.md` for the
product frame this Epic sits in.

For an **Epic-level** run always dispatch the folder read this way (`depth: full`, scoped to `focus_key`) for the Epic's scope — the authored-PRD-file check above only applies PRD-level. Resolve any PRD-level ARD via `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` (`prd: <PRD>`, `epic: null`, `$SPECS_PATH`). On `status: found`, load its `AD#N` invariants to **inherit read-only**. On `status: unmerged`, **stop**, naming the returned `branch` and any `pr`. On `status: none`, proceed unchanged — there is no PRD-level ARD to inherit.

Extract the problem/goal/scope frame + capability themes — the raw material for grounding + the grill.

### the BRD route — read the architecture-altitude seed, the register, and the verified findings

On the BRD route this phase reads the BRD folder Phase 0 step 3 resolved and dispatches
the folder read **not at all**. Read exactly these, and no other seed:

- **`ard-seed.md`** — architecture-altitude content, when the folder holds any. **No `/brd-*` command writes this file on the normal route** — the one writer is
  `/dev-workflows:brd-intake --sort-existing`, a one-time migration path for a package authored
  by hand before this route existed. Its absence is therefore the **ordinary** case, not a
  degraded one, and is reported rather than treated as a gap; what the route actually carries at
  every altitude is `decisions.md`, filtered by `altitude`, plus the grounding files.
  **`prd-seed.md` and `spec-seed.md` are not read**, at all: they are the product and
  implementation altitudes of the same router, belonging to `/dev-workflows:create-prd` and
  `/dev-workflows:specify`, and pulling the first in would put product requirements into an ARD while
  pulling the second in would put a per-repo implementation plan into one — the two things
  `${CLAUDE_PLUGIN_ROOT}/references/ard-format.md`'s quality rules forbid from opposite directions.
- **`decisions.md`** — the register, per
  `${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §1.
- **`grounding/code-grounding.md`** and **`grounding/design-grounding.md`** — the `[CG#n]` and
  `[DG#n]` finding records, per `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §2.
- **`brd-link.md`** — for `parent:` and `depends-on:` only. This run reads no `claims:` list and no
  coverage ledger: PRD eligibility and the allocation gate are
  `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5's rule about authoring a **PRD**,
  applied "when eligibility is checked", and an ARD is not that artifact. Not checking it here is a
  decision, not an omission — `/dev-workflows:create-prd` on the BRD route is where that gate lives, and
  this command is reachable without it.

**Absence is reported, never a stop, and the seed's absence is the ordinary case.** Nothing on the
normal route writes a seed file at all (above), so a reconciled BRD routinely holds none; and a BRD
ground with `--no-design` holds no `design-grounding.md` at all. Say which of the four were absent — a reader cannot tell an unwritten
file from an unread one — and carry what is there.

**Partition the register before the grill starts, because the partition is what freezes it.** The
five states and their treatment are `decision-register-format.md` §3's, applied here exactly as
`/dev-workflows:create-prd` on the BRD route applies them one altitude up: a `decided` record is an
**input** the ARD is authored from and never a question; `superseded` and `withdrawn` are terminal
and read for context only; `open`, `reopened` and an open `[AS#n]` are **gaps**, which may not be
consumed downstream while open (§3) and reach the ARD's `## Open questions` by id rather than being
quietly settled. Carry each `decided` record's `altitude` with it: only `architecture` ones have a
home here, and a `product` or `implementation` decision is read for context and **left for the
command that authors at its altitude** — `/dev-workflows:create-prd` and `/dev-workflows:specify` —
and it is not discarded by being skipped. **The channel that carries it is `decisions.md` itself, not
a seed file.** Both of those commands read this same register and filter it by `altitude` exactly as
this phase does, so a decision skipped here is picked up there from the file it was already in.
`prd-seed.md` and `spec-seed.md` are written by nothing on this route — only
`/dev-workflows:brd-intake --sort-existing` writes one, migrating a package authored before the route
existed — so naming a seed as the thing that carries it would send a reader after a file that is not
there.

**A finding with no verifier outcome is not evidence** (`grounding-format.md` §8) and may neither
seed `## Grounding findings (architecture as-is)` nor be marked `consumed_by` anything. Carry only
findings that hold one, keep each one's `[CG#n]`/`[DG#n]` id and its pinned `commit` where it is
cited, and name any finding the seed offered that was dropped for want of an outcome.

**A `will-change` finding names a prerequisite decision that overturns it** (`grounding-format.md`
§5), and a `decided` record may carry a `conditional_on: <BRD-KEY>/<decision-id>`
(`decision-register-format.md` §5). Both are architecture the ARD must not state as settled: record
each under `## Open questions` — or `## Deferred` where the prerequisite is what defers it — naming
the prerequisite BRD and the specific decision, alongside the `depends-on:` list `brd-link.md`
carries.

**Inheritance on the BRD route uses `brd-link.md`'s `parent:`, never a segment count.** Resolve any
inherited ARD via `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with:

- **a `parent:`** (this folder is a slice — the only shape this route resolves, since step 1a
  refuses the container) → `prd: <parent-key>`, `epic: <SLICE-KEY>`.

The second mapping needs no change to that reference: a slice folder sits inside its parent's exactly
as an Epic subfolder sits inside a PRD dir, which is the layout its Epic-level branch already
collects — the slice's own `ard.md` plus the parent BRD folder's `ard.md` for inherited
invariants. Act on the returned `status` exactly as above: `found` → inherit those `AD#N` read-only;
`unmerged` → **stop**, naming the returned `branch` and any `pr`; `none` → proceed unchanged.

---

## Phase 3 — Architect-driven grounding (no PRs)
There are no PRs at ARD time, so repos are **architect-driven**, not PR-derived:
1. **Cheap discovery.** List the top-level directories under each `$REPOS_PATH` entry (`ls`). Optionally attach each dir's one-line identity — `timeout 5 git -C <dir> remote get-url origin 2>/dev/null` (slug) or its README first heading. Do **not** deep-scan to guess relevance.
2. **Propose + ask.** From the PRD/Epic themes, propose a `theme → repo` mapping against those dirs, and **ask the architect to confirm / correct / add**. For any requirement that maps to no obvious repo, **ask outright**: "which repo covers `<X>`?"

   **On the BRD route the proposal starts from `<BRD-dir>/grounding/baselines.md`**, which already
   records repository → pinned commit for every repo `/dev-workflows:brd-ground` read, rather than
   from PRD themes this route does not have. That is a better starting set than a theme guess and it
   is still only a proposal: the architect confirms, corrects and adds exactly as above, and a repo
   `baselines.md` names but `$REPOS_PATH` does not hold reaches step 3's mount-or-descope gate like
   any other. A finding's evidence is cited at the commit that finding is pinned to
   (`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §2), which is not necessarily the commit a
   fresh scan reads; where the two differ, say so beside the claim rather than silently re-dating it.
3. **Missing repo → consolidated mount-or-descope gate:** `choices: ["Mount now & re-scan", "Ground only the confirmed-mounted set (record the rest as open questions)", "Specify an absolute path for this repo", "Cancel"]`.
4. **Ground the confirmed set.** Spawn `code-scanner` in batches of up to 4 concurrent agents per Agent message on the confirmed repos (wait for each batch), scoped by the themes:

   → Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §2.1 Sonnet chain>`):
     > "repo_path: <resolved absolute path>
     >  repo_url_slug: <slug>
     >  capability_themes: [themes]
     >  context: |
     >    [3–5 sentences: the PRD/Epic goal, what the ARD must ground]
     >  search_hints: { symbols: […], paths: […], keywords: […] }
     >  refresh: { switch_to_default_branch: [per Phase 1], pull: [per Phase 1] }"

   Store the per-repo as-is findings (`file:line`). Descoped/unmounted repos become Open questions.

   **Per-repo scanner status.** Wait for each batch. Handle each returned status before continuing:

   - `OK` / `PARTIAL` / `EMPTY` — use the result. `PARTIAL` and `EMPTY` are data, not failures.
   - `REPO_MISSING` — escalate per the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
   - `DIRTY_TREE` — escalate per the `Dirty working tree` rule in the same file.
   - `REFRESH_BLOCKED` — escalate per the `Refresh blocked` rule in the same file.
   - `prep.read_only: true` — not a failure. The scan ran at `prep.scanned_ref`. Escalate per the `Read-only mount — ref stale or diverged` rule **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`; otherwise proceed silently and cite evidence at `prep.scanned_ref`.

   A repo the user skips is dropped from the confirmed set and named in the Phase 6 handoff; it never silently disappears.
5. **Documentation grounding (optional).** Run `resolve-docs-grounding create-ard` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the PRD/Epic goal + capability themes, `key` = `<PRD>` (PRD-level) or `<EPIC>` (Epic-level), `themes` = the confirmed themes. Carry the digest into the Phase 4 grill with **grill-rank** consumption (documented analogs and building-block altitude/permissions are strong ARD grounding). When OFF, skip silently.

---

## Phase 4 — Author via grill
**Interview technique (grilling — embedded; no runtime dependency).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, explore the Phase 3 grounding findings / the PRD to self-answer (fact-vs-decision), walk the design tree in dependency order, continue to shared understanding then write each section.

Author the ARD live against `${CLAUDE_PLUGIN_ROOT}/references/ard-format.md`, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`, at the resolved altitude: Context → Grounding findings (cite `file:line`) → Architecture decisions (`AD#N`: Binds/Prevents/Rule) → Cross-repo/component approach → Stack & invariants → Edge cases & risks → Open questions → Deferred. At Epic level, list inherited PRD-level ADs read-only and never contradict them; PRD level stays at invariants/frame (no per-repo detailed solutions).

### the BRD route — the seed fills the sections, and the grill is restricted to gaps

**Where the seed's content lands.** `[CG#n]`/`[DG#n]` findings seed
`## Grounding findings (architecture as-is)`, each keeping its own id and citing the `file:line`
evidence at the commit it is pinned to. Architecture-altitude `decided` records seed
`## Architecture decisions`: the record's `statement` and `argumentation` become the `[AD#N]`'s
substance, and the grill supplies the **Binds** / **Prevents** / **Rule** triple
`${CLAUDE_PLUGIN_ROOT}/references/ard-format.md` requires and the register does not carry. Naming the
`[VD#n]` or `[CD#n]` beside the `[AD#N]` it became is what keeps the two records findable from each
other. **A decision does not automatically earn an `[AD#N]`**: `ard-format.md`'s three-part test —
hard to reverse, surprising without context, the result of a real trade-off — still applies, and a
`decided` record failing it belongs in the ARD's prose or is left to `/dev-workflows:design`. Saying
which of the two happened is part of the consumption report (Phase 6).

**The grill may fill anything the seed does not settle. It may not reopen a `[VD#n]` or a `[CD#n]`**
(D3). Those decisions arrive carrying customer sign-off in writing, and a grill that re-litigates one
manufactures a contradiction between this ARD and a document the customer has already agreed to.
Three things make that a guarantee rather than an instruction:

1. **The question set is a subtraction, not a sweep.** Phase 2's partition already sorted the register
   into inputs, terminal records and gaps; the grill's questions come from the gaps and from what
   `ard-seed.md` leaves unstated. A settled `chosen` is never a question, so there is nothing for the
   interview to walk it back through.
2. **This run cannot satisfy either cause that would license a reopening.**
   `${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §4 admits exactly two — a new
   grounding finding, or an incoming customer decision — and this command produces neither: the
   architect-driven scan in Phase 3 is `code-scanner` output, which
   `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §1 says is a capability inventory and
   explicitly **not** a finding, and no customer review reaches the register except through
   `/dev-workflows:brd-reconcile`.
3. **The only field of a decision record this command may write is `consumed_by`** (Phase 6).
   `statement`, `options_considered`, `chosen`, `argumentation`, `evidence`, `altitude`,
   `conditional_on`, `status` and `round` are never written here, on any record, in any status — so a
   grill answer contradicting a `decided` record could not become that record's new `chosen` even if
   the first two failed.

**What happens when the grill surfaces a genuine contradiction with a settled decision** — which is
useful information, not something to suppress. Do not decide it and do not soften it into the ARD's
prose. Record it under `## Open questions`, naming the `[VD#n]` or `[CD#n]` it contradicts and what
this run believes contradicts it, and name the route that may act on it. **Neither route is this
command**, and both are exactly §4's two causes rather than a third invented here: a `[VD#n]` needs a
new grounding finding, which only `/dev-workflows:brd-ground <BRD-KEY> --rebaseline` mints and
`/dev-workflows:brd-interview <BRD-KEY>` then re-decides against; a `[CD#n]` needs the customer,
through `/dev-workflows:brd-package <BRD-KEY>` and then
`/dev-workflows:brd-reconcile <BRD-KEY> @<review-file>`. This is not the `## ARD deviations`
convention — that one is for a *consumer* departing from an `AD#N`
(`${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md`), and this run is the ARD's author.

**Frontmatter on the BRD route**, per `ard-format.md`'s block, each field read from what Phase 2
already holds and none of them asked of the user:

- `scope: epic` — the route resolves a slice and nothing else (Phase 0 step 1a), and every slice
  takes this scope. Not because a slice is an Epic, but because `scope` selects the altitude rule
  `ard-reviewer` applies and the inheritance shape `ard-resolution.md` reads, and a slice sits in
  both exactly where an Epic does — one level down, inheriting its parent's `AD#N` read-only.
- `prd:` and `epic:` are the same pair Phase 2 passed to `resolve-ard`: the `parent:` key and
  `<SLICE-KEY>`. Frontmatter and resolver agree
  because they are written from one resolution, not two.
- `inherits:` the parent BRD folder's `ard.md` when `resolve-ard` returned one, else `null`.
- `derived_from:` the PRD file in this BRD folder when one is there — the ordinary case, since this
  route is normally reached from `/dev-workflows:create-prd`'s own next-step offer on the BRD route — else
  `<BRD-dir>/ard-seed.md`, the artifact this ARD was actually authored from. The field records
  provenance, and naming a PRD path in a folder that holds no PRD would name a file that does not
  exist.
- `grounded_repos:` unchanged — the repos Phase 3 confirmed, which is what every `file:line` in the
  ARD must cite into.

**Per-area split.** If (Epic level) the confirmed grounding spans separable areas in one repo (e.g. `server/` backend + `ui/` frontend), grill: `choices: ["One combined ARD (Recommended)", "One ARD per area (backend / frontend / …)"]`. On per-area, author one `ard-<area>.md` per area (each with its own `area:` frontmatter).

---

## Phase 4.5 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against the drafted `ard.md`: the **Universal checks**,
the **key-collision** check (run on the ARD body below the frontmatter), and the **ARD** block
(incl. that every `### [AD#N]` carries `**Binds:**` / `**Prevents:**` / `**Rule:**`). Surface every
finding; inline-fix the mechanical ones (renumber a duplicate `[AD#N]`, delete a stray placeholder
token); leave content gaps for the grill/author. **Advisory** — never blocks;
proceed to Phase 5 once findings are surfaced. `ard-reviewer` remains the gate.

**On the BRD route, a `<BRD-KEY>` in the ARD body is the auto-link check's third branch, not its
second.** The body legitimately names prerequisite BRDs — a `will-change` finding's prerequisite, a
`conditional_on` decision's — and the collision grep matches the leading two segments of any of them.
A BRD key is not a requirement ID and it is **not a real tracker ticket**: it is a folder name under
`$SPECS_PATH`, validated for shape and never checked against a tracker
(`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1). So it falls to the "neither" branch —
**MINOR, left exactly as written, reported**. Never wrap it as `[[KEY-123]]`: that branch is for a key
in a project that actually exists, and wrapping a BRD key would mint a dangling link to a ticket
nobody created.

## Phase 5 — Review gate
Dispatch `ard-reviewer` (Opus, frontmatter-pinned; recorded as `review_model`, no override):

→ Agent (subagent_type: "dev-workflows:ard-reviewer", model: `<review_model — §2 Opus chain>`):
  > "Review the ARD:
  >
  > ARD path: [absolute path to the ard.md]
  > Scope: [prd | epic]"

On `BLOCK`, fix the BLOCKER findings inline (the orchestrator/grill edits the ARD — no delegated writer) and re-review **once**; if still `BLOCK`, escalate per the `Review verdict BLOCK` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. `PASS` / `PASS WITH RECOMMENDATIONS` → proceed. Cap: one fix cycle + one re-review. (For a per-area split, review each area ARD.)

---

## Phase 6 — Handoff
Write the ARD file(s) into the feature folder.

**On the BRD route, also close the consumption loop before the offer.** The design's *Consumption
tracking* section (§7.3) has every finding and decision record a `consumed_by`, so that "nothing was
lost" is checkable rather than hoped for. Set `consumed_by: ARD` on each architecture-altitude
`decided` record in `decisions.md` and on each `[CG#n]`/`[DG#n]` finding in
`grounding/code-grounding.md` / `grounding/design-grounding.md` **this ARD actually drew on** — and on
nothing else: a record read for context and not used is still `none`, and marking it consumed would
report a routing that never happened. A finding with no verifier outcome is never marked, whatever the
ARD did with the claim, because it was never evidence (`grounding-format.md` §8). These are the
**only** writes this command makes into any BRD file, and none of them is a `status` change or any
other field (Phase 4). Everything at architecture altitude still `none` afterwards goes in the final
report by id, per §7.3.

**`ard-seed.md` is reported, not stamped**, for the reason the field's own authorities give:
`consumed_by` is a field of a *record* — defined on a decision by
`${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §1 and on a finding by
`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §2 — and the seed carries neither, so there is
no per-item field to write and inventing one would mint a format this command alone understood. The
seed's consumption is reported at **file** granularity in the final report (consumed, or consumed in
part with what was left over).

Then **offer** (commit-when-asked — never automatic), presenting `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim: `choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]`. On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: ard`; `feature_folder` as resolved in Phase 0 (the PRD dir for a PRD-level ARD, the Epic subfolder for an Epic-level ARD — §2.2 derives `ard/<PRD>-<vslug>` or `ard/<EPIC>-<eslug>` from it, matching today's branch names); `deliverable_paths` = the ARD file(s) — **plus, on the BRD route, `decisions.md`, `grounding/code-grounding.md` and `grounding/design-grounding.md`**, because the `consumed_by` writes above land in those three and an uncommitted consumption record is one no later run can read; `ard-seed.md` is not staged, because this run does not write to it; `title: <PRD|EPIC> Add architecture requirements document`; and `body_facts` = the ARD scope (PRD/Epic, any per-area split), the grounded/descoped repos, the `AD#N` count, the open-question count, and the `ard-reviewer` verdict — and, on the BRD route, the `<SLICE-KEY>` this ARD was seeded from and how many items were marked `consumed_by: ARD`. Emit its §4.1 outcome line in the Final report.

**On the BRD route the feature folder is the resolved `PRD-` slice folder**, so §2.2 derives the
branch `ard/<SLICE-KEY>-<slug>` from its own basename, not from a re-derived title. That name collides with neither the `prd/` branch `/dev-workflows:create-prd` derives on the BRD route for the same key, nor the `spec/` one `/dev-workflows:specify` derives on the BRD route, nor the
`/brd-*` family's shared `brd/` one, because §2.2's prefix is the caller's own. The commit message's key is the run's key, resolved as Phase 8 resolves it.

---

## Phase 7 — Next-step offer (adaptive)
**One precondition governs every `/dev-workflows:epics` option below, on both routes.** `/epics`
accepts a folder holding a `prd.md` that asserts `kind: prd` and refuses one that does not
(`commands/epics.md` Phase 0 step 1b, `EPICS_NO_PRD`). This run does **not** require a PRD — its
`require-on-main` gate has an `absent` branch that architects from the resolved folder, and on the
BRD route `/dev-workflows:create-prd` is not a prerequisite at all — so the folder it just wrote an
ARD into may legitimately hold no PRD. **Test the resolved folder for an authored `prd.md`** before
rendering the array: where there is one, offer `/dev-workflows:epics`; where there is not, **replace
that option with `/dev-workflows:create-prd <ADDRESS>`**, which authors the PRD `/epics` then reads.
Offering `/epics` there would name a run that stops on arrival.

- **PRD-level ARD:** if the PRD has 0 Epics → `choices: ["Hand to a Product Engineer — /dev-workflows:epics <ADDRESS> (PE) (Recommended) <merge-clause>", "Author a PRD-level spec — /dev-workflows:specify <PRD> (PE) <merge-clause>", "Stop here"]` — with the first option becoming `"Author the PRD — /dev-workflows:create-prd <ADDRESS> (PM) (Recommended)"` where the precondition above fails; else offer `/dev-workflows:specify <PRD>` (PE) carrying the same `<merge-clause>`. *(No `/design` — no Epics yet.)*
- **Epic-level ARD:** `choices: ["Author the spec — /dev-workflows:specify <EPIC> (PE) (Recommended) <merge-clause>", "Hand to Dev — /dev-workflows:design <EPIC> (Dev) <merge-clause>", "Stop here"]` — one address each, the Epic's own, because that is the only form either command accepts (D4). **Epic fan-out** — repeat this ARD for a sibling Epic: `/dev-workflows:create-ard <SIBLING-EPIC>`; that run inherits the PRD-level ARD, not this Epic-level one, so it waits on nothing this run produced and carries no clause.
- **the BRD route (an ARD in a `PRD-` slice folder):** a different array, because **the key this run
  holds is a slice key and only one of the three usual options can be reached with one**:
  `choices: ["Author this slice's specification — /dev-workflows:specify <SLICE-KEY> (PE) (Recommended) <merge-clause>", "Hand to a Product Engineer — /dev-workflows:epics <SLICE-KEY> (PE) <merge-clause>", "Stop here"]`
  — with the second option **resolved by the test below**: `/dev-workflows:epics <SLICE-KEY>` where
  the slice holds an authored `prd.md`, `/dev-workflows:create-prd <SLICE-KEY>` where it does not.
  - **`/dev-workflows:specify <SLICE-KEY>` is always reachable from this state.** It takes
    the same slice key this run resolved — and passes that command's own container refusal for the
    same reason this run did, finds the same folder through `resolve-address`
    (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), and needs no key minted anywhere else. It
    resolves this ARD through `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` and
    stops on `status: unmerged`, so the wait is real and the clause is required.
  - **`/dev-workflows:epics <SLICE-KEY>` is offered where the slice holds an authored `prd.md`, and
    replaced by `/dev-workflows:create-prd <SLICE-KEY>` where it does not.** It resolves the same
    folder this run resolved, through the same `resolve-address`, and reads the PRD there — a slice
    is a `PRD-` folder, so it passes that command's container refusal exactly as this run did. But
    **this route does not require a PRD**: `/dev-workflows:create-prd` is not a prerequisite for it,
    so a slice carrying an ARD and no `prd.md` is an ordinary state, and `/epics` refuses one
    (`EPICS_NO_PRD`). The test is the precondition stated above this list, and it is a real test
    again — unlike the one it replaces, which looked for an export directory under the key and
    guarded a lookup that no longer happens. Neither option gates anything this run produced, so
    neither carries a merge clause.
  - **`/dev-workflows:design` is offered on this route by neither branch.** It takes over a merged
    `specification.md` — a file this run did not write — and resolves its own key through the specs tree. The path to it runs through the first option: `/dev-workflows:specify <SLICE-KEY>` writes
    that specification, and its own next-step offer is where `/dev-workflows:design`
    is named under the conditions that make it resolvable.
  - **There is no Epic fan-out on this route.** The address resolved a `PRD-` slice folder, not an
    `EPIC-` one, so there is no sibling Epic to repeat this ARD for — and no second positional key to
    name one with (Phase 0 step 1, `CREATE_ARD_ONE_ADDRESS`). A sibling
    *slice* is a separate BRD with its own folder and its own seed: `/dev-workflows:create-ard
    <SIBLING-SLICE-KEY>` waits on nothing this run produced and would carry no clause.

**Every merge clause above is the `<merge-clause>` placeholder**, resolved from this run's own `Phase handoff:` outcome line per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`, and never the unconditional "once the pull request above is merged": a declined handoff, a failed push and a nothing-to-commit run each leave a different wait, and two of them open no pull request to wait on. It is a placeholder, not an instruction to reword an option, so the arrays are still presented verbatim per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. **The wait it names is real for every command named above**, and it is a stop, not a silent degradation: `/dev-workflows:epics`, `/dev-workflows:specify` and `/dev-workflows:design` each read this ARD through `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` and each stops on `status: unmerged`, naming the branch and any open pull request. Only a handoff that reached no branch at all resolves `status: none`, where that reference's no-regression rule has the run proceed exactly as it would with no ARD.

Guidance only — never auto-invokes another command. Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`.

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 8), per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. The next step hands off from PA
to PE/Dev, so:

- **Handing to PE (`/dev-workflows:epics <PRD>` / `/dev-workflows:specify <EPIC>`) or Dev (`/dev-workflows:design <EPIC>`), even yourself?** → run **`/clear`** for a clean slate; the ARD is on disk.
- **On the BRD route, the handoff is `/dev-workflows:specify <SLICE-KEY>`** (Phase 7) — same answer, **`/clear`**; the ARD is on disk and that run reads it from the specs repo, not from this session.
- Continuing to draft more ARD areas yourself right now? → **`/compact`** is fine.
- Consider **`/rename <PRD-ID>-<slug>-pa`** so you can find this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.

---

## Phase 8 — Session maintenance, feedback & cost
Terminal phase — runs after Phase 7, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference gap**, `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment / user halt (unset `$SPECS_PATH`, missing key, no-ARD-needed, unmounted-repo descope, cancellation) or a review BLOCK. **The four argument- and tree-shaped stops are of that second class**: `CREATE_ARD_NEEDS_KEY`, `CREATE_ARD_ONE_ADDRESS`, `CREATE_ARD_BRD_NOT_FOUND` and `CREATE_ARD_BRD_NOT_SLICED` report the operator's own argument list or BRD tree, not a capability this plugin lacks, so none of them `emit-block`s.

**Session-hygiene invariant.** End Phase 7 with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the
`resume.md` write runs later, in the terminal cost phase, per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the
guidance only), then a
PA→PE/Dev handoff suggestion (`/clear`) + `/rename <PRD-ID>-<slug>-pa`. Guidance only, never auto-run.

**The run's key on the BRD route.** Phase 0 resolved a BRD key, which is a folder name and never a
second identity (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1). Any tracker identity for this work,
if one exists at all, is the `key` in the PRD this BRD folder holds — the same one Phase 7's
`/dev-workflows:epics` condition reads. So the `key` passed to `emit-auto` and `emit-cost` below
is that minted key when the folder holds a PRD carrying one, and `null` otherwise (`source: none`
either way); `commit-artifacts` resolves its own key the same way and commits under `NOISSUE` when
there is none, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4 step 4. The `<BRD-KEY>` is
never passed as a `key` — a folder key in a tracker-key field is the confusion the two fields
exist to keep apart.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/create-ard`; what was authored (ARD scope + grounded repos); key events (grounding gaps/descopes, BLOCK reviews — or 'none'); workarounds; the `ard-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6) with the report, `command: /create-ard`, the run's `key`, `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its `emit-cost` entry point with `command: /create-ard`, `phase: architecture`, `role: pa`, the run's `key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite `<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the pointer reflects the completed run, and before the commit step below, so it is included in it. Redact per §1. Silent; the printed `### Context hygiene` guidance already appeared in the report.
5. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/create-ard)` with no `Co-Authored-By` trailer, and pushes to the branch this run's handoff phase created (§4.1). It NEVER touches anything outside `$SPECS_PATH`; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is offered only in Phase 6; the terminal step above commits only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report
Report: the ARD path(s) + scope (PRD/Epic, any per-area split); the grounded repos + any descoped/ungrounded ones; `AD#N` count; open-question count; the `ard-reviewer` verdict; the `Phase handoff:` outcome line from `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1); resolved model routing (+ any Opus gate/degradation); the feedback + cost paths; the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; and the adaptive next-step recommendation.

**On the BRD route, additionally:** the `<SLICE-KEY>` seeded from and its resolved folder; the
`parent:` key its `brd-link.md` records — every run of this route is slice-level — and whether the
parent's ARD was inherited (`found`) or absent (`none`); which of `ard-seed.md`, `decisions.md`,
`grounding/code-grounding.md` and `grounding/design-grounding.md` were present; the frontmatter
`scope` / `prd` / `epic` / `inherits` / `derived_from` as written, naming which of the two
`derived_from` sources was used and why; every `[CG#n]`/`[DG#n]` dropped for want of a verifier
outcome, by id; every `[VD#n]`/`[CD#n]`/`[AS#n]` carried in as a gap rather than an input, by id and
status; every architecture-altitude `decided` record that did **not** become an `[AD#N]` and where its
content went instead; every `will-change` finding and `conditional_on` decision recorded as a
prerequisite rather than as settled architecture, with the prerequisite decision named; every
architecture-altitude item still `consumed_by: none`, by id, per the design's *Consumption tracking*
section (§7.3) — **excluding the baseline `[CG#n]` findings**, which are never `consumed_by` anything
and whose `none` therefore reports no gap
(`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §4.1); say that they are excluded, so a
reader can tell an empty list from an unrun check; `ard-seed.md`'s consumption at file granularity; and any product- or
implementation-altitude content the grill surfaced and left for the command that authors at that
altitude instead of the ARD (D5) — naming the command, never a seed file, since the register it will
read that content out of is the one this run already read. Say plainly whether `/dev-workflows:epics` was offered and, when it was not, that no
folder resolved under `<BRD-KEY>` itself — naming the `key` it asserts but
differs, since that is the case a reader is most likely to mistake for reachable (Phase 7).
