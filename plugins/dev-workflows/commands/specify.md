---
name: specify
description: Specification-authoring workflow (PE phase). Reads the resolved PRD or Epic folder, lightly grounds in code, and authors an org-standard specification.md through a relentless one-question-at-a-time grill; gates on the Opus spec-reviewer and lands the spec on the specs repo's main branch via branch + PR for the /design dev take-over. the BRD route seeds the run from a reconciled BRD instead of a resolved folder: it resolves the BRD-route PRD- slice folder (the folder carrying brd-link.md) and refuses a BRD- container outright, since a BRD is a container and holds no specification; it reads that slice folder's implementation-altitude spec-seed.md, the implementation decisions in decisions.md, the verified [CG#n]/[DG#n] findings and the derivation matrix /brd-ground appended to code-grounding.md, runs the same PRD gate and the same folder read as the idea route, freezes every [VD#n]/[CD#n] against the grill, and marks each consumed item consumed_by: specification.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Author a product specification for the resolved item: $ARGUMENTS

`/specify` is the **PE-phase specification-authoring** workflow — the specification step of the PM→PA→PE→Dev pipeline
(`/specify` → `specification.md`; then `/design` → `design.md`). Given an Epic or PRD address,
it reads the item from the specs tree, lightly scans code to
ground feasibility, and authors an org-standard `specification.md` through a relentless
one-question-at-a-time grill — resolving open questions live instead of stopping. It gates on the
Opus `spec-reviewer` and offers to land the spec on the specs repo's main branch (via branch + PR) as
`Published: no`.

Key distinction from `/epics`: `/epics` *splits* a PRD into Epic drafts; `/specify` *authors one
specification* for a single item (typically an Epic). Run `/epics` first, then `/specify` per Epic.

Usage: `/specify <ADDRESS> [--no-docs]`, where `<ADDRESS>` is a key or an `@<path>`. On the BRD
route the run is seeded from a reconciled BRD and the address is the **`PRD-` slice key**
`/brd-split` carved; a `BRD-` container is refused (Phase 0 step 0). One address on every route: a
second positional token is refused (Phase 0 step 1, `SPECIFY_ONE_ADDRESS`).

---

## Phase 0 — Resolve input

0. **The route is a property of the resolved folder, not of a flag.**

   **One resolution serves both routes now.** A BRD key and a PRD key both name a folder under
   `$SPECS_PATH/specifications/`, and `resolve-address` resolves either — so this step no longer
   skips a front-end, it reads a different `kind` from the same resolution. What distinguishes the
   routes is what the resolved folder holds, not how it was addressed. **The BRD route is a `PRD-`
   folder carrying a `brd-link.md`** — the slice `/brd-split` carved — and nothing else.

   **A `BRD-` container is refused, on either route.** Take this on the folder **step 1 resolves**,
   the moment that resolution returns `status: found` and ahead of every read this command makes —
   and **not** as part of the BRD-route branch. The BRD route is detected from a `brd-link.md`, and a
   root BRD folder need not carry one: `/brd-intake` writes none, and only `/brd-ground`,
   `/brd-split` and `/brd-package` ever do. A refusal conditioned on the detected route would let
   `/specify <ROOT-BRD-KEY>` fall through to the keyed route and author a specification into the
   container. A BRD is a container: its requirements are built by the `PRD-`
   slices under it, one specification each, and a `specification.md` written into the container
   would sit beside `brd/`, `grounding/`, `coverage-ledger.md` and `slices.md` in a folder the
   design's §4.1 tree gives no specification. **The test is the directory prefix, and never the
   folder's asserted `kind:`** — `/brd-split` writes `kind: brd` into the `brd-link.md` inside a
   `PRD-` slice folder, so a slice asserts `brd` while being exactly the folder a specification
   belongs in, and a gate on the asserted kind would refuse every slice.

   **Where the folder resolved through `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §5's legacy
   fallback and carries no prefix, the question is answered by positive evidence that it is a BRD,
   never by the absence of a file** — `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md`
   §5.1, the shared authority `/create-prd` and `/create-ard` take this same test from. In short: a
   legacy folder carrying `coverage-ledger.md` or `brd/brd-inventory.md`, and no `brd-link.md`
   naming a `parent:`, is a root container; a legacy folder carrying **neither** of those two files
   is a legacy **idea-route PRD folder**, which holds `prd.md` and no `brd-link.md` either — this
   refusal does not fire on it, and refusing it would offer `/dev-workflows:brd-split` on a folder
   with no coverage ledger to walk. Stop gracefully:
   `SPECIFY_BRD_NOT_SLICED: <BRD-KEY> resolves to a BRD- container at <path>, and a BRD is never the folder a specification is authored in — its requirements are specified in the PRD- slices under it, one specification each (coverage-ledger-format.md §5). <the remedy, per the branch below>`

   **The remedy is the same two branches `/dev-workflows:create-prd`'s own container refusal takes,
   and it is a directory listing rather than a ledger read** — this command reads no coverage ledger
   and does not start now. Enumerate slices by `/brd-split` Phase 0 step 9's **positive test**: an
   immediate subdirectory carrying a `brd-link.md` whose `parent:` names this BRD.
   - **One or more slices** — the ordinary shape, since a split always confirms at least one. Name
     every slice and offer `/dev-workflows:specify <SLICE-KEY>` once per slice. Do **not** name
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

1. **Resolve the address.** Parse the **single positional address** from `$ARGUMENTS` — a `<KEY>`,
   or an `@<path>` naming a folder or a file inside one — and resolve it with `resolve-address`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3). Carry forward:
   - `<PRD>` — the resolved **PRD folder's** `key`: the folder itself when the address named a
     `PRD-` folder, its parent when it named an `EPIC-` folder.
   - `<EPIC>` — the `EPIC-` folder's `key`, or `null` when the address named a `PRD-` folder.

   **A second positional token is refused, on every route** (D4). There is no `<PRD> <Epic>` form to
   fall back to: an Epic key encodes its own ancestry, so a second argument would be derivable from
   the first and able to disagree with it, which is the failure class D4 exists to remove. This
   refusal is **not** conditioned on the route — the earlier BRD-route-only version of it argued
   that "a BRD has no Epics yet — they are minted from the PRD", a premise `/epics` has since
   changed: Epics are minted by `/epics` under a PRD folder, a slice **is** a PRD folder, so a
   reconciled slice can hold `EPIC-` folders and the old sentence was false there as well as
   redundant everywhere else. Stop gracefully:
   `SPECIFY_ONE_ADDRESS: /specify takes one address; <second-token> was given as a second. The kind of the folder the address resolves to is what sets the altitude — an EPIC- folder specifies that Epic, with its PRD read from the folder above it; a PRD- folder authors a PRD-level specification; on the BRD route the address is the PRD- slice folder /brd-split carved. To specify one Epic, address the Epic: '/dev-workflows:specify <EPIC-KEY>'.`

   **The kind decides the altitude**, which is what replaces the two-key grammar: the second key was
   always derivable from the first, and `addressing.md` §4's `key` is what supplies both.

   With no positional address, stop with
   `SPECIFY_NEEDS_KEY: /specify needs a PRD or Epic address — a key, or an @<path> to its folder.` — `/specify` has no
   direct-prompt behavior.

2. **Resolve `$SPECS_PATH`.** `/specify` writes specifications under `$SPECS_PATH/specifications/`
   (exact layout resolved in step 3) — the specs repo. If `$SPECS_PATH` is unset, stop
   with a clear error naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`) —
   there is no fallback for this write target the way there is for reads.

3. **Resolve the feature folder.** Derive provisional kebab-case slugs from the relevant
   item title(s) (finalized once the folder read runs in Phase 2, but a
   provisional slug is enough to check for existing folders now): `<vslug>` for the `<PRD>` title, and
   `<eslug>` for the `<EPIC>` title when `focus_key` is set.

   - **Resolve/derive the PRD (top-level) dir:** call `resolve-address <PRD>`
     (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), which searches every level §3 bounds and
     carries §5's legacy fallback — including a slug a human has adjusted. No matching rule is
     written here; §5 owns it. Create `PRD-<PRD>-<vslug>/` per §2's convention only on
     `status: absent`. Every later
     `specifications/<PRD>-<vslug>/` in this command — the PRD gate's `ls-tree` path and Phase 2's
     per-Epic paths included — names the dir resolved here.
   - **Resolve the feature folder itself**, by case. **There are two cases, not three**: an Epic
     always has a PRD above it, because `/dev-workflows:epics` is the only command that creates an
     `EPIC-` folder and it writes every one of them under a PRD folder (D6). A top-level `EPIC-`
     folder with no PRD above it — the third case this step used to carry — is retired: `/dev-workflows:epics`
     refuses one rather than partitioning it, and this command refuses one rather than authoring a
     specification flat inside it.
     - `focus_key` set (an Epic nested under a PRD) →
       `specifications/<PRD>-<vslug>/EPIC-<EPIC>-<eslug>/` — a per-Epic subfolder under the PRD dir
       (`<eslug>` = kebab of the Epic title). Apply the same honor-an-existing-dir tolerance to the
       `EPIC-<EPIC>-<eslug>` segment. **This folder is never created here.** An `EPIC-` folder is
       minted by `/dev-workflows:epics` and by nothing else, so one that does not exist is a stop,
       not a directory to make:
       `SPECIFY_EPIC_NOT_FOUND: no Epic folder for <EPIC> under <the resolved PRD dir> — an EPIC- folder is created by /dev-workflows:epics and by no other command. Run '/dev-workflows:epics <PRD>' to draft this PRD's Epics, then re-run '/dev-workflows:specify <EPIC>'.`
       That remedy runs in the state this stop reports: `/dev-workflows:epics` takes the PRD address
       this step already resolved, and gates only `<PRD-dir>/specification.md` — a file this run has
       not written.
     - `focus_key` null → the item is a **PRD** for which the broad-PRD-spec choice is made
       (Phase 2, Step A) → `specifications/<PRD>-<vslug>/specification.md` — flat at the PRD-dir level, no
       per-Epic subfolder; the feature folder is the PRD dir itself. **This is now the only
       null-`focus_key` case**, so `<PRD>` is always a PRD's own key and never an Epic's.
   - All delimiters this step writes are hyphens; matching an existing dir tolerates a stray `-`/`_`.
     The PRD dir is not created here — the first phase that writes to it (Phase 2's `idea.md` write,
     in a fresh run) creates it. The per-Epic feature folder is never created here at all, by the
     stop above.

   **On the BRD route the feature folder is the resolved `PRD-` slice folder**, and it is never
   created here. There is no second resolution for that route and no `<BRD-dir>` argument to read:
   the single positional address was resolved once with `resolve-address`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), step 0 refused the container the upper
   level holds, and the folder that survives both **is** the slice.
   **The write location then follows `focus_key`, by the same two cases as above and not by a rule of its
   own.** A slice is a `PRD-` folder, so `focus_key` is null when the run starts and `specification.md`
   is written flat inside the slice folder, beside the BRD artifacts it was derived from — the ordinary
   shape, and the identical `focus_key`-null PRD case listed above. It is not flat *because* this is the
   BRD route: where `/dev-workflows:epics` has minted `EPIC-` folders under the slice, Phase 2 Step A's
   picker can set `focus_key` to one of them here exactly as it does under any other PRD folder, and the
   feature folder is then re-pointed to that Epic's subfolder (Step A's *Re-pointing*). Addressing such an
   Epic directly — `/dev-workflows:specify <EPIC-KEY>` — resolves an `EPIC-` folder, which carries no
   `brd-link.md`, so it is not the BRD route at all and takes the `focus_key`-set case above with nothing
   route-specific about it.
   `absent` is a graceful stop, not a folder to create — and the remedy it names is the one that
   produces a folder this command accepts, since step 0 refuses the `BRD-` container a
   `/dev-workflows:brd-intake` run would leave behind:
   `SPECIFY_BRD_NOT_FOUND: no folder found for <ADDRESS> under $SPECS_PATH/specifications/ (every level addressing.md §3 bounds, plus §5's legacy fallback) — check the address. /specify writes into a PRD- folder, never the BRD- container above it: a slice is created by /dev-workflows:brd-split on its parent BRD, and a parent BRD is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file> and then grounded and split before any slice exists.`
   Where the address was an **`@<path>`** the same stop substitutes that path for the search clause —
   `no folder at <path> (given as a path)` — because "every level addressing.md §3 bounds" would
   describe a search a verbatim path never performs.

4. **Detect a prior run.** If a `_session.md` exists in the resolved feature folder, record that a
   resume is available — Phase 1 asks the user resume-vs-fresh. If no `_session.md` exists, this is a
   fresh run.

`/specify` is **cwd-agnostic**, like `/epics` — it reads the specs tree and writes specs to
an absolute `$SPECS_PATH`-rooted directory, so it does not require cwd to be inside either.

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier
run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent
when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if
it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal
`commit-artifacts` step skips on it.

**Gate the PRD — on every route, with no branch.** The folder gated is **the PRD folder this run resolved**: the resolved folder itself when the address named a `PRD-` folder, its parent when the address named an `EPIC-` folder, and — on the BRD route — the resolved `PRD-` slice folder, which *is* that route's PRD folder (§4.1). One rule, one path expression, no route test. Execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against the PRD file in that folder (written below as `specifications/<PRD>-<vslug>/` for brevity; the folder on disk carries its kind prefix — `PRD-<PRD>-<vslug>/` on a current tree, the unprefixed form only through §5's legacy fallback — and it is always the folder Phase 0 resolved, never a path re-derived here) — **resolve its actual name on the ref first**: `git -C "$SPECS_PATH" ls-tree --name-only "origin/<default>" "specifications/<PRD>-<vslug>/"` and take `prd.md` when the listing carries it, falling back to a `<PRD>_*.md` entry only when it does not — the keyless `prd.md` is what `/create-prd` and `/update-prd` write, and the `<KEY>_<slug>.md` form is the pre-rename shape a specs repo written before increment A still holds (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §5). **Gating the legacy glob alone was a defect**: it matches nothing in a current repo, so the gate returned `absent` for every PRD that was present and the rows D/E stop could never fire. A human-adjusted slug is a supported state — `/create-prd` and this command's own Phase 2 reader both locate the PRD by glob plus frontmatter, and the feature folder is matched by key-number for the same reason — so gating an exact derived filename would report `absent` for a PRD that is present, and would let a slug-drifted file on a plugin branch escape the rows D/E stop entirely. Map its §3.7 return value by `stopped` first, never by `on_main` alone. Any stopping state → stop per §4.4. Otherwise (`stopped: false`): on `pass`/`pass_amending`, proceed — Phase 2 still reads the resolved folder exactly as today; the merged PRD is a grounding confirmation, not a new content source; on `absent`, `/specify`'s existing specs-tree behaviour is unaffected — but report it: *"No authored PRD on `<default>` for `<PRD>` — specifying from the resolved folder at `<path>`. If a PRD exists on a branch, this run would have stopped; it does not, so none does."*; on `unmanaged`, behave exactly as before this feature — reachable here even after step 2's own `$SPECS_PATH` check, since that check only rejects an unset value, never an invalid path or a non-git directory.

**The BRD route runs this gate too, and the `absent` branch is what makes that safe.** It did not, and
the rationale it carried was coherent while the route could resolve a `BRD-` container: the PRD "may not
exist at all", and gating an artifact the run does not read would promote an input the route never had
into a prerequisite, which `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §5 rule 3 forbids. Phase 0
step 0 removed the premise. The BRD route now resolves **a `PRD-` slice folder in every case** — the same
kind of folder the keyed route resolves — so there is one folder to gate, and the gate's own `absent`
branch already handles the state the rationale was protecting: a slice in which no `prd.md` has been
authored yet returns `absent`, is **reported**, and this run specifies from the resolved folder exactly as
§3.4's `/specify` row says it may. Nothing is promoted into a prerequisite, because `absent` is not a stop
— `/dev-workflows:create-prd` is still not a prerequisite for this command, on either route. What the gate
adds on both routes is the state it was built for: a `prd.md` that **exists and was never handed off**,
sitting on a branch (rows D/E). That state is as reachable on a slice as it is on a keyed PRD folder —
`/dev-workflows:create-prd` opens `prd/<SLICE-KEY>-<slug>` there and its handoff can be declined — and
specifying against an unmerged PRD is the failure the gate exists to prevent, whichever route wrote it.
§3.4's `/specify` row therefore describes every run of this command, not one route's.

**What the seed does not need the gate for is still true, and is not a reason to skip it.** The `/brd-*`
family's own handoff discipline puts `spec-seed.md`, `decisions.md`, the grounding files and the
derivation matrix on the specs default branch before this route reads them — each of those commands lands
its deliverable there and the next refuses to start until it is. That is why this command gates no BRD
artifact. It says nothing about the PRD, which is authored by `/dev-workflows:create-prd` under the `prd/`
prefix like any other and carries no such discipline.

---

## Phase 1 — Configure

**Rule: Ask, don't guess. This rule is absolute.**

Use `choices` arrays; 2–4 options, and never author an "Other" option — the harness supplies the free-text escape itself (`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` §0).

1. **Feature folder.** Confirm the path resolved in Phase 0:
   ```
   choices: ["Use <feature_folder> (Recommended)", "Use a different path (you'll be prompted)", "Cancel"]
   ```
   - Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).

2. **Resume vs fresh** (only if Phase 0 found a `_session.md`). Read it back and summarise which
   stages/questions are already settled:
   ```
   choices: ["Resume — skip settled stages/questions (Recommended)", "Start fresh — discard the prior session", "Cancel"]
   ```
   On resume, Phase 5 begins at the first unsettled stage instead of the header.

3. **Repo refresh policy** (governs Phase 4's `code-scanner` dispatches):
   ```
   choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh"]
   ```
   `fetch + pull default branch` matches `code-scanner`'s own default
   (`refresh.switch_to_default_branch: true, refresh.pull: true`) — grounding wants present-day code,
   the same rationale `/epics` uses.

4. **Repos search base (`$REPOS_PATH`)**. Read `${REPOS_PATH:-/workspace}`. `$REPOS_PATH` may be a
   single directory or a colon-separated list:
   ```
   choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel"]
   ```
   If "different path", validate that at least one directory exists under the given value before
   recording it.

Also display (for user context): resolved feature folder; resolved `prd_dir`; resolved
`key` (PRD); resolved `focus_key` (Epic, or 'none — PRD-level'); resolved `$REPOS_PATH`; resolved
`$SPECS_PATH`.

**On the BRD route, display in addition** a `from BRD:` line naming `<SLICE-KEY>` and its resolved folder,
its `parent:` if `brd-link.md` records one, its `depends-on:` if any, and which of `spec-seed.md`,
`decisions.md`, `grounding/code-grounding.md` and `grounding/design-grounding.md` are present — a
stat, not a read; the read is Phase 2. **Display the `prd_dir`, `key` and `focus_key` lines as well**,
which resolve on this route exactly as on the keyed one: `prd_dir` is the slice folder itself (a slice
*is* the PRD folder), `key` is the slice's own asserted `key`, and `focus_key` is `none — PRD-level`
until Phase 2 Step A settles it. They were once shown as `none — seeded from a BRD`; that described a
route that resolved a container and had no PRD folder to name, which Phase 0 step 0 has retired.

---

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then classify as `SIMPLE` / `MODERATE` / `SIGNIFICANT` / `HIGH-RISK`. Specification authoring is typically **MODERATE**. Resolve per-step routing per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT possible for large/cross-cutting PRDs
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # the folder read, code-scanner
  review_model:    <§2 Opus chain>     # spec-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + specification.md authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

The grill + authoring run inline on `current_model` (interactive judgment — not a delegated subagent), consistent with the model-routing SSOT. If no Opus is available, `spec-reviewer` falls to the Sonnet floor — record the degradation in `notes` and the final report.

---

## Phase 2 — Read the resolved folder

**Steps A and B run on every route.** Phase 0 step 0 means the BRD route resolves a `PRD-` slice
folder — a PRD folder, which can hold a `prd.md` and can hold `EPIC-` folders that `/dev-workflows:epics`
minted under it — so there is nothing for a route test to decide here. The *BRD route — read the
implementation-altitude seed* section at the end of this phase is an **addition** to Steps A and B, not a
replacement for them: it reads the seed, the register, the verified findings and the derivation matrix a
slice carries and a keyed-route PRD folder does not.

**One divergence stays, and it is a real one: no `idea.md` is written on the BRD route.** Step B's
`idea.md` write records pre-spec provenance for an item whose provenance is otherwise unrecorded. A slice
folder already carries its provenance in the tree — `brd-link.md`, the register, the grounding findings,
and the customer's own document under the parent's `brd/source/` — and writing a fourth, derived account
of it beside those would put an unreviewed restatement of a signed-off document in the folder. So the
`idea.md` bullet in Step B is skipped on the BRD route and the run says so; every other part of Steps A
and B runs unchanged.

Phase 2 reads the folder in **two steps, cheap before expensive**. Step A settles *granularity* — the
input's type and, for a multi-Epic PRD, *which* Epic — with a cheap `prd-plus-epics` read (and, when
needed, the progress-aware picker), resolving `focus_key`. Only then does Step B spend the full-depth
read, now scoped to the resolved Epic. This ordering resolves a null `focus_key` by a cheap
enumeration **before** any expensive full read, so the full read never pulls a whole multi-Epic PRD
subtree the grill would only discard. When `focus_key` is already set on entry, Step A is skipped and
Phase 2 is just the full read (Step B).

### Step A — Resolve granularity + focus Epic (cheap enumeration + picker)

**Skip this step entirely when `focus_key` is already set on entry** — that is, when step 1's single
address resolved to an `EPIC-` folder (or to an `@<path>` naming one), and the PRD was read from the
folder above it. The Epic is already chosen, so go straight to Step B. There is no two-token form
that could set it: `/specify` takes one address (step 1, `SPECIFY_ONE_ADDRESS`).

Otherwise (`focus_key` is null), perform the **cheap** `prd-plus-epics` read — the folder's own `prd.md`
plus a listing of its `EPIC-` subfolders — to determine the item's type and enumerate its child Epics
*without* opening every Epic folder's contents:

**Read the PRD folder directly.** Read its `prd.md`, and list the `EPIC-` subfolders under it —
that listing is the Epic set this phase branches on, and each folder's `key` and title come from its
own frontmatter (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §4).

**A missing folder and a folder holding no `prd.md` are two different states, and only the first is a
stop.** If the folder is missing, surface the `key dir not found` rule in
`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`) — reachable only
through a folder deleted between Phase 0 and here, since Phase 0 step 3 already stopped on `absent`. If
the folder is there but holds **no `prd.md`**, do not stop and do not re-report: the Phase 0 gate has
already returned `absent` and printed the line naming the folder this run specifies from instead. That is
the ordinary state on the BRD route, where `/dev-workflows:create-prd` is not a prerequisite for this
command, and a supported one on the keyed route; escalating it here would contradict the gate's own
`absent` branch two steps earlier and offer a "Re-enter key" for a key that resolved correctly. Enumerate
the `EPIC-` subfolders exactly as below and carry on with whatever the folder holds.

Otherwise take the type from the resolved folder's own `prd.md` (`kind: prd`) and enumerate its **child
Epics** as the `EPIC-` subfolders listed above, each one's `key` and title read from its own
frontmatter. `value_increment` and `linked_items` were fields of a tracker export that no command
produces any more; the folder listing is the enumeration now, and it is the same one the paragraph
above performs. Then branch — this is the reusable **progress-aware
Epic-picker pattern** documented in `${CLAUDE_PLUGIN_ROOT}/references/epic-picker.md`, applied here with `/specify`'s own done-predicate:

**The item here is always a PRD.** This step runs only when `focus_key` is null on entry, and step 1
sets `focus_key` from an `EPIC-` address — so an Epic never reaches the branch below. The
top-level Epic with no PRD above it, which used to have a branch of its own here, is retired with
the case itself (Phase 0 step 3): `/dev-workflows:epics` writes every `EPIC-` folder under a PRD folder, and
is the only command that writes one at all.

- **PRD with exactly 1 Epic** → no picker; auto-select it. Set `focus_key` = that Epic and emit a
  one-line notice (e.g. `Single child Epic <EPIC> '<title>' — authoring its spec.`). Re-point the
  feature folder to that Epic's per-Epic subfolder (see *Re-pointing* below). Proceed to Step B.
- **PRD with ≥2 Epics** → render the **progress-aware picker**, one row per child Epic. For each Epic,
  first resolve its **actual** feature folder the same way Phase 0 step 3 does: look under
  `specifications/<PRD>-<vslug>/` for an existing dir matched by that Epic's key-number (tolerate a
  stray `-`/`_` after the key, and a pre-existing slug that doesn't exactly match a freshly-derived
  one), falling back to the freshly-derived `specifications/<PRD>-<vslug>/EPIC-<EPIC>-<eslug>/` only when no
  such dir exists — this keeps a human-adjusted Epic dir slug from mis-displaying as ○ not-started.
  Compute each Epic's status from `/specify`'s **done-predicate** against that resolved folder:
  - **○ not started** — no `specification.md` and no `_session.md` there → selectable.
  - **◐ in progress** (resume) — a `_session.md` exists there but no `specification.md` → selectable
    as a resume; the per-Epic stage-level resume then runs in Phase 5 from that `_session.md`
    (resume *stacks* on the picker, per the shared pattern).
  - **● done** — `specification.md` exists there → shown greyed, **not** default-selectable;
    selecting it offers *revise*.
  Default cursor = the first actionable row (in-progress before not-started). Render per
  `${CLAUDE_PLUGIN_ROOT}/references/epic-picker.md`: every Epic listed as prose above the prompt, and
  the array carrying **at most two** Epic rows (marker + key + title), the explicit
  **"Author one broad PRD-level spec instead"** choice, and *"Another Epic from the list above — name
  its key"*. That file's *The cap* section is why the Epic rows are the ones that give way: the
  broad-spec choice is the alternative to picking any Epic at all, so hiding it would force a choice
  this command means to leave open.
  - On selecting an Epic → set `focus_key` = that Epic; re-point the feature folder to its per-Epic
    subfolder (see *Re-pointing* below).
  - On **"Author one broad PRD-level spec instead"** → leave `focus_key` = null; the feature folder
    stays the flat PRD-dir path `specifications/<PRD>-<vslug>/` (Phase 0 step 3's `focus_key`-null PRD
    case). Step B then reads the whole PRD subtree.
- **PRD with 0 Epics** → this PRD hasn't been split yet. Offer the without-Epics choices:
  `choices: ["Split into Epics first with /dev-workflows:epics (Recommended)", "Author one broad PRD-level spec now", "Cancel"]`
  `/specify` does not write Epic folders itself — on "Split…", stop and point at
  `/dev-workflows:epics`, which writes them into this PRD folder where this command will see them. On
  "Author one broad PRD-level spec now", leave `focus_key` = null and proceed to Step B.
  - **`/dev-workflows:epics` is only offered where the resolved folder holds an authored `prd.md`.**
    That command accepts a folder holding a `prd.md` asserting `kind: prd` and refuses one that does not
    (`commands/epics.md` Phase 0 step 1b, `EPICS_NO_PRD`), so offering it on a folder with no PRD would
    name a run that stops on arrival. Where the folder holds none — the ordinary BRD-route state, and the
    one the Phase 0 gate reported as `absent` — the first choice becomes
    `"Author the PRD first — /dev-workflows:create-prd <ADDRESS> (Recommended)"`, which is the run that
    writes the PRD `/epics` then reads, takes the single address this run already resolved, and passes
    that command's own container refusal for the same reason this run did. The second and third choices
    are unchanged: a broad spec authored from the folder as it stands is still reachable.

**Re-pointing the feature folder after the picker.** When Step A sets `focus_key` to an Epic (the
single-Epic and ≥2-Epic-selection cases), the feature folder becomes that Epic's per-Epic subfolder
`specifications/<PRD>-<vslug>/EPIC-<EPIC>-<eslug>/` (Phase 0 step 3's `focus_key`-set case), superseding the
provisional PRD-level folder confirmed in Phase 1 — Phase 0 already marks that folder provisional until
the folder read runs. Re-detect a prior run there (a `_session.md` → a resume is available for that
Epic). The broad-PRD-spec case — the only other one left — leaves the Phase 0 folder unchanged.

### Step B — Full Epic-scoped read

With granularity settled and `focus_key` resolved, perform the `full` read.
**Read the Epic folder itself, and everything under the PRD folder that bears on it.** The raw
material for user stories, acceptance criteria and test cases is the PRD's own text plus whatever the
Epic folder already holds — its `epic.md` where one exists, and any earlier `specification.md` or
`design.md`. A linked subtree of Stories and Sub-tasks is not something the tree carries, so where the
PRD is thin the grill has less to work from and must ask more; that is a real change in where the
detail comes from, and it belongs to the operator's answers rather than to an import.

The same two states apply here as in Step A: a **missing** folder surfaces the `key dir not found` rule
in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`); a folder holding
**no `prd.md`** is not a stop — the Phase 0 gate reported it already, and the grill works from what the
folder does hold. Then:

- **Epic-scope the read, against the tree.** The material is the PRD folder and what sits under it.
  When `focus_key` is set, read **that `EPIC-` folder** — its `epic.md`, and any `specification.md` or
  `design.md` already in it — plus the PRD folder's own `prd.md` for the frame, and read no sibling
  `EPIC-` folder at all. When `focus_key` is null (broad PRD-level spec), read the PRD folder and every
  `EPIC-` folder under it. There is no `linked_items` list and no Story/Sub-task subtree to filter: those
  were fields of a tracker export that no command produces any more (Step A), and the `EPIC-` folders on
  disk are the hierarchy now. Everything below — themes, `idea.md`, the Phase 5 raw material — derives
  from the folders this bullet named.
- Extract **capability themes** and component/product mentions from the folders just read — feeds
  Phase 3's repo derivation and Phase 4's `code-scanner` dispatches.
- Write **`idea.md`** in the feature folder from the text of the folders just read — **except on the
  BRD route**, where the provenance is already in the tree and this write is skipped and reported (the
  divergence named at the head of this phase) — pre-spec brainstorming provenance, in the same spirit
  as the `idea.md` convention `source-truth.md` already treats as non-authoritative once
  `specification.md` exists.
- Carry what those folders hold forward into Phase 5 — the raw material the grill mines for user
  stories, acceptance criteria, and test cases.

### the BRD route — read the implementation-altitude seed, the register, and the verified findings

**Additionally** read the `PRD-` slice folder Phase 0 step 3 resolved — additionally, because Steps A and B have already read that same folder's `prd.md` and its `EPIC-` subfolders, or reported the PRD's absence. What follows is what a slice carries and a keyed-route PRD folder does not, and it is the whole of the divergence this route is entitled to. Read exactly these, and no other seed:

- **`spec-seed.md`** — implementation-altitude content, when the folder holds any. **No `/brd-*` command writes this file on the normal route** — the one writer is
  `/dev-workflows:brd-intake --sort-existing`, a one-time migration path for a package authored
  by hand before this route existed. Its absence is therefore the **ordinary** case, not a
  degraded one, and is reported rather than treated as a gap; what the route actually carries at
  every altitude is `decisions.md`, filtered by `altitude`, plus the grounding files.
  **`prd-seed.md` and `ard-seed.md` are not read**, at all: they are the product and
  architecture altitudes of the same router, belonging to `/dev-workflows:create-prd` and
  `/dev-workflows:create-ard`. Reading the first would let product requirements be restated as spec
  content rather than derived from it; reading the second would let this spec re-decide architecture
  the ARD owns, which `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md`'s deviation convention
  exists precisely to keep it from doing.
- **`decisions.md`** — the register, per
  `${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §1.
- **`grounding/code-grounding.md`** and **`grounding/design-grounding.md`** — the `[CG#n]` and
  `[DG#n]` finding records, per `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §2 — **and, in
  the first of the two, the derivation matrix.** The matrix is not a file of its own and is not inside
  `spec-seed.md`: `/dev-workflows:brd-ground` appends its rows to the slice folder's `grounding/code-grounding.md`
  (that command's Phase 8), classed per `grounding-format.md` §7
  (`EXISTS | DERIVED | NEW-CAPTURE | NEW-CONFIG | PARTNER | DEFERRED | DEPENDENCY`). It is
  implementation-altitude by construction, which is why this command is the one that reads it — and
  an absent matrix is ordinary, since `/dev-workflows:brd-ground` runs it only on a reporting- or
  data-centric BRD or under an explicit `--derivation-matrix`.
- **`brd-link.md`** — for `parent:` and `depends-on:` only. This run reads no `claims:` list and no
  coverage ledger: PRD eligibility and the allocation gate are
  `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5's rule about authoring a **PRD**,
  applied "when eligibility is checked", and a specification is not that artifact. Not checking it
  here is a decision, not an omission — `/dev-workflows:create-prd` on the BRD route is where that gate
  lives, and this command is reachable without it.

**Absence is reported, never a stop, and the seed's absence is the ordinary case.** Nothing on the
normal route writes a seed file at all (above), so a reconciled BRD routinely holds none; and a BRD
ground with `--no-design` holds no `design-grounding.md`. Say which of the four were absent — a reader cannot tell an unwritten file from
an unread one — and carry what is there.

**No `idea.md` is written on this route.** Step B writes one as pre-spec provenance derived from the
PRD text; there is none here, and the BRD folder already holds the provenance this spec was
built from — the register and the findings, each committed by the `/brd-*` run that wrote it, plus a
`spec-seed.md` where a `--sort-existing` migration left one. Minting an `idea.md` from any of them
would add a second, weaker record of the same thing in a folder whose whole point is that the first
one is auditable.

**Partition the register before the grill starts, because the partition is what freezes it.** The
five states and their treatment are `decision-register-format.md` §3's: a `decided` record is an
**input** the specification is authored from and never a question; `superseded` and `withdrawn` are
terminal and read for context only; `open`, `reopened` and an open `[AS#n]` are **gaps**, which may not
be consumed downstream while open (§3) and reach the spec as `- [ ]` items under the relevant stage's
`### Open questions` by id — which is also what keeps the header's `- **Open questions**: N` count
honest (`${CLAUDE_PLUGIN_ROOT}/references/specification-format.md`). Carry each `decided` record's
`altitude` with it: only `implementation` ones have a home here, and a `product` or `architecture`
decision is read for context and **left for the command that authors at its altitude** —
`/dev-workflows:create-prd` and `/dev-workflows:create-ard`, both of which read this same register and
filter it by `altitude` exactly as this phase does, so the channel that carries it is `decisions.md`
itself and never a seed file (`prd-seed.md` and `ard-seed.md` are written by nothing on this route).
That is what the altitude partition exists
for (D5), and it is not discarded by being skipped.

**A finding with no verifier outcome is not evidence** (`grounding-format.md` §8) and may neither
ground a spec statement nor be marked `consumed_by` anything. Carry only findings that hold one, and
name any the seed offered that was dropped for want of an outcome.

**A `will-change` finding names a prerequisite decision that overturns it** (`grounding-format.md`
§5), and a `decided` record may carry a `conditional_on: <BRD-KEY>/<decision-id>`
(`decision-register-format.md` §5). Neither may be written into this spec as settled behaviour:
record each as a `- [ ]` open question naming the prerequisite BRD and the specific decision, beside
the `depends-on:` list `brd-link.md` carries. A `DEPENDENCY`-classed derivation-matrix row is the same
situation for a data element and is recorded the same way.

**Extract capability themes** from `spec-seed.md`, the implementation-altitude `decided` statements
and the matrix rows — these feed Phase 3's repo derivation and Phase 4's `code-scanner` dispatches in
place of the PRD-derived themes.

---

## Phase 2.5 — Resolve applicable ARD (optional)

Resolve any ARD for this item by citing `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with `<PRD>`, `<EPIC>` (`focus_key`), and `$SPECS_PATH`. **On the BRD route the pair comes from `brd-link.md`'s `parent:`, never from a segment count**: the route resolves a slice and nothing else (Phase 0 step 0), so the `parent:` is always there — pass `prd: <parent-key>`, `epic: <SLICE-KEY>`. The second mapping needs no change to that reference — a slice folder sits inside its parent's exactly as an Epic subfolder sits inside a PRD dir, the layout its Epic-level branch already collects — and it is the same pair `/dev-workflows:create-ard <SLICE-KEY>` writes into the ARD's own `prd:`/`epic:` frontmatter, so the two agree by construction rather than by coincidence. On `status: none`, **skip and proceed exactly as before**. On `status: unmerged`, **stop**, naming the returned `branch` and any `pr`. On `status: found`, keep the spec's user stories + scope consistent with the returned `invariants` + `guidance_summary` during the Phase 5 grill; record a necessary deviation under the spec's `### Open questions` (never edit the ARD). Pass the `invariants` to `spec-reviewer` in Phase 6 as `applicable_ard`.

---

## Phase 3 — Derive repos + soft gate

1. **Auto-derive candidate repos.** From the Phase 2 capability themes and any repositories the
   resolved folder's `implementation.md` records (`${CLAUDE_PLUGIN_ROOT}/references/implementation-format.md`
   §1 — its `repo` entries), build a candidate repo-slug list. There is no PR list to read: nothing here
   reads a tracker or a pull-request API. **Under
   the BRD route there is no implementation record either; derive the list from the resolved slice
   folder's `grounding/baselines.md` instead**, which already records repository → pinned commit for
   every repo `/dev-workflows:brd-ground` read, plus the Phase 2 themes. That is a stronger starting
   set than a theme guess, and the rest of this phase treats it identically — step 3 resolves each
   entry against the slug map and step 4's soft gate handles one that is not mounted. A finding's
   evidence stays cited at the commit that finding is pinned to
   (`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §2), which is not necessarily the commit
   Phase 4's scan reads; where the two differ, say so rather than silently re-dating the claim. If the
   list is
   empty, escalate per the `No repos derivable — /epics` rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["List repos to scan manually", "Proceed without code scan", "Cancel"]
   ```

2. **Build the slug→clone map** (`/epics`-style). For each top-level directory under each entry of
   `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing
   `.git`, and take the URL's last path segment as that clone's slug. Skip directories with no `.git`
   or whose `git remote` call fails/times out.

3. **Resolve each candidate against the map.** One match → use it. An ambiguous slug (multiple
   matches) or zero matches both escalate per the `Repo unresolved (zero matches) — /epics` rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo"]
   ```

4. **Cross-check mounted status — soft gate.** A resolved repo slug that is not actually mounted under
   `$REPOS_PATH` does NOT hard-block `/specify` the way an unresolved slug does above. Instead: record
   a feasibility `- [ ]` open question in `_session.md` (e.g. "Cannot ground <theme> — `<repo-slug>` is
   not mounted; feasibility unverified"), report the gap to the user now, and **PROCEED** to Phase 4
   with the remaining mounted repos. Describe the missing capability and why it matters — the
   specification cannot name or link an unmounted repo's code, so any claim resting on it stays an
   open question until the repo is mounted and `/specify` is re-invoked (Phase 5 keeps `_session.md`
   current, so the run is resumable).

---

## Phase 4 — Light code scan

Spawn `code-scanner` instances in **batches of up to 4 concurrent agents** per Agent message, on the
mounted candidates resolved in Phase 3. Wait for each batch before spawning the next. This is
deliberately a **light** scan relative to `/epics`' — grounding for feasibility and to avoid
contradicting existing behaviour, not a full reuse audit.

For each repo in the batch:

→ Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Scan this repo for the brief:
  >
  > repo_path:     <resolved absolute path for this repo from Phase 3>
  > repo_url_slug: <repo slug, e.g. "cluster">
  > capability_themes:
  >   [paste the themes array from the folder read]
  > context: |
  >   [3–5 sentences: the item's goal, what the specification must ground]
  > search_hints:
  >   symbols:  [class/function names inferred from the item text, or []]
  >   paths:    [directory globs inferred from themes, or []]
  >   keywords: [grep keywords extracted from themes]
  > refresh:
  >   switch_to_default_branch: [true if Phase 1 chose 'fetch + pull default branch' (default) or 'fetch only'; false if 'no refresh']
  >   pull: [true if 'fetch + pull default branch'; false otherwise]"

**Documentation grounding (optional).** Run `resolve-docs-grounding specify` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the scoped Epic/PRD goal, `key` = the focus key, `themes` = the Phase 2 capability themes. Carry the digest into the Phase 5 grill with **grill-rank** consumption. When OFF, skip silently.

Handle per-repo status after the batch returns:

- `OK` / `PARTIAL` / `EMPTY` — store the "does this exist / where / gaps" output; this grounds Phase 5's
  grill (e.g. answering a question from the scan instead of asking the user).
- `REPO_MISSING` — should not happen at this stage (Phase 3 already checked). If it does, escalate per
  the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
- `DIRTY_TREE` — escalate:
  ```
  choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel"]
  ```
- `REFRESH_BLOCKED` — escalate:
  ```
  choices: ["Continue with current local state", "Skip this repo", "Cancel"]
  ```
- `prep.read_only: true` — not a failure. The scan ran at `prep.scanned_ref`. Escalate per the `Read-only mount — ref stale or diverged` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`; otherwise proceed silently and cite evidence at `prep.scanned_ref`.

---

## Phase 5 — Author via grill

**Interview technique (grilling — embedded; no runtime dependency).** Conduct each stage as a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, explore the Phase 4 code scan / PRD content to self-answer (fact-vs-decision), walk the design tree in dependency order, continue to shared understanding then write that stage's section.

Walk the stages in order, authoring `specification.md` live against `${CLAUDE_PLUGIN_ROOT}/references/specification-format.md`, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`:

1. Header + **Problem statement**
2. **Scope** (In/Out)
3. **User stories** (`[Uxx]`)
4. **Acceptance criteria** (`[ACxx]`, EARS)
5. **Test cases** (`[TCxx]`)

As each decision settles, append it to `_session.md`; capture a genuinely-ambiguous term in `_glossary.md`. Resolve open questions to zero where possible; leave genuinely unresolvable ones as `- [ ]` and keep the header **Open questions** count in sync. A repo gap surfacing here → escalate (describe the missing capability + why) and STOP; the run is resumable from `_session.md` after the user remounts and re-invokes.

### the BRD route — where the seed lands, and the grill is restricted to gaps

**Where the seed's content lands.** `spec-seed.md` and the implementation-altitude `decided` records
supply the raw material the PRD supplies on the other route: the problem frame and scope
boundary, the behaviours that become `[U01]…` user stories, and the settled choices those stories must
honour. **Derivation-matrix rows are behaviour, not prose to paste**: an `EXISTS` or `DERIVED` row is
a fact the acceptance criteria can rely on; a `NEW-CAPTURE` or `NEW-CONFIG` row is work this spec must
actually deliver, so it belongs in `## Scope`'s In-scope list and in an `[AC01]`-level EARS statement
rather than a footnote; a `PARTNER` row is a boundary and usually an Out-of-scope entry; a `DEFERRED`
or `DEPENDENCY` row is an open question with its prerequisite named. Naming the `[VD#n]`, `[CD#n]`,
`[CG#n]` or `[DG#n]` beside the statement it grounds keeps the two records findable from each other.
`${CLAUDE_PLUGIN_ROOT}/references/specification-format.md`'s stage rules are not relaxed: a matrix row
naming a physical column is not licence to write a table name into a user story.

**The grill may fill anything the seed does not settle. It may not reopen a `[VD#n]` or a `[CD#n]`**
(D3). Those decisions arrive carrying customer sign-off in writing, and a grill that re-litigates one
manufactures a contradiction between this specification and a document the customer has already agreed
to. Three things make that a guarantee rather than an instruction:

1. **The question set is a subtraction, not a sweep.** Phase 2's partition already sorted the register
   into inputs, terminal records and gaps; the grill's questions come from the gaps and from what
   `spec-seed.md` leaves unstated. A settled `chosen` is never a question, so there is nothing for the
   interview to walk it back through.
2. **This run cannot satisfy either cause that would license a reopening.**
   `${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §4 admits exactly two — a new
   grounding finding, or an incoming customer decision — and this command produces neither: Phase 4 is
   a `code-scanner` pass, which `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §1 says is a
   capability inventory and explicitly **not** a finding, and no customer review reaches the register
   except through `/dev-workflows:brd-reconcile`.
3. **The only field of a decision record this command may write is `consumed_by`** (Phase 7).
   `statement`, `options_considered`, `chosen`, `argumentation`, `evidence`, `altitude`,
   `conditional_on`, `status` and `round` are never written here, on any record, in any status — so a
   grill answer contradicting a `decided` record could not become that record's new `chosen` even if
   the first two failed.

**What happens when the grill surfaces a genuine contradiction with a settled decision.** Do not
decide it and do not soften it into the spec's prose. Record it as a `- [ ]` open question naming the
`[VD#n]` or `[CD#n]` it contradicts and what this run believes contradicts it, and name the route that
may act on it. **Neither route is this command**, and both are exactly §4's two causes rather than a
third invented here: a `[VD#n]` needs a new grounding finding, which only
`/dev-workflows:brd-ground <BRD-KEY> --rebaseline` mints and `/dev-workflows:brd-interview <BRD-KEY>`
then re-decides against; a `[CD#n]` needs the customer, through
`/dev-workflows:brd-package <BRD-KEY>` and then
`/dev-workflows:brd-reconcile <BRD-KEY> @<review-file>`. A contradiction with an `AD#N` is a different
thing and keeps its existing home: the `### Open questions` deviation record `ard-resolution.md`
prescribes.

---

## Phase 5.5 — Structural pre-lint

Before finalizing, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against the drafted `specification.md`: the **Universal
checks** plus the **spec** block (incl. the `- **Open questions**: N` header equalling the `- [ ]`
count). Surface every finding; inline-fix the mechanical ones (renumber a duplicate `[Uxx]`/`[ACxx]`/
`[TCxx]`, correct the open-questions count, delete a stray placeholder token); leave content gaps for
the grill/author. **Advisory** — never blocks; proceed to Phase 6 once findings are surfaced.
`spec-reviewer` remains the gate.

## Phase 6 — Finalize + review gate

1. **Render HTML.** `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/specification-to-html.py" <spec path>`
   against the `specification.md` written in Phase 5. On failure, report the error and proceed — the
   HTML mirror is a review convenience, secondary to the markdown source of record.

2. **Dispatch `spec-reviewer`.**

→ Agent (subagent_type: "dev-workflows:spec-reviewer", model: `<review_model — §2 Opus chain; frontmatter-pinned, recorded, no override>`):
  > "Review the specification for this brief:
  >
  > Specification path: [absolute path to specification.md]
  > Detected maturity: test
  > applicable_ard: [the ARD invariants resolved in Phase 2.5, or omit if none]"

3. **Act on the verdict** (mirrors `/epics` Phase 7):
   - **`BLOCK`** — fix the BLOCKER findings (the orchestrator/grill edits `specification.md` inline —
     there is no delegated writer to re-dispatch) and re-review once. If still `BLOCK`, escalate per
     the `Review verdict BLOCK (unresolved after one fix cycle) — /epics` rule in
     `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` for each unresolved BLOCKER individually:
     ```
     choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in the final report)", "Override and accept the finding", "Cancel the whole run"]
     ```
     "Defer" means appending a `## Refinement notes` section to `specification.md` with a `- [ ]` item
     per deferred finding (mirrors `/epics`' Epic-refinement note), in addition to the final report.
   - **`MAJOR` / `MINOR` / `NIT`** (surfaced under `PASS WITH RECOMMENDATIONS`) — defer to the final
     report; no mandatory fix cycle.
   - **`PASS`** / **`PASS WITH RECOMMENDATIONS`** — proceed to Phase 7.

Cap: one fix cycle + one re-review maximum.

---

## Phase 7 — Handoff

Write the feature folder: `specification.md` (`Published: no`), `idea.md`, `_session.md`, `_glossary.md`, and the rendered `.html`. **On the BRD route there is no `idea.md`** (Phase 2, the one divergence that phase keeps) — the other four are written exactly as above, into the feature folder Phase 2 resolved: the slice folder itself when `focus_key` is null, or the `EPIC-` subfolder Step A selected when it is set.

**On the BRD route, also close the consumption loop before the offer.** The design's *Consumption
tracking* section (§7.3) has every finding and decision record a `consumed_by`, so that "nothing was
lost" is checkable rather than hoped for. Set `consumed_by: specification` on each
implementation-altitude `decided` record in `decisions.md` and on each `[CG#n]`/`[DG#n]` finding in
`grounding/code-grounding.md` / `grounding/design-grounding.md` **this specification actually drew
on** — and on nothing else: a record read for context and not used is still `none`, and marking it
consumed would report a routing that never happened. A finding with no verifier outcome is never
marked, whatever the spec did with the claim, because it was never evidence
(`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §8). These are the **only** writes this command
makes into any BRD file, and none of them is a `status` change or any other field (Phase 5).
Everything at implementation altitude still `none` afterwards goes in the final report by id.

**`spec-seed.md` is reported, not stamped**, for the reason the field's own authorities give:
`consumed_by` is a field of a *record* — defined on a decision by
`${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §1 and on a finding by
`grounding-format.md` §2 — and the seed carries neither, so there is no per-item field to write and
inventing one would mint a format this command alone understood. Its consumption is reported at
**file** granularity in the final report. The derivation matrix is the one part of the seed material
that *is* stamped, and only because it lives inside `code-grounding.md`: a matrix row is not a finding
record either, so it too is reported at file granularity rather than given a `consumed_by` of its own.

Then **offer** (commit-when-asked — never automatic), presenting `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim:
```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: spec`; `feature_folder` = the Epic subfolder for a **per-Epic** spec (a PRD + focus Epic — the only Epic-level shape there is, since every `EPIC-` folder sits under a PRD folder), or the PRD dir for a **broad PRD-level** spec (`focus_key` null), a `PRD-` slice folder on the BRD route being that same PRD-dir case rather than a third one, since a slice *is* a PRD folder — Epic keys are globally unique, so the per-Epic form needs no PRD prefix, and both forms use hyphens; §2.2 derives `spec/<EPIC>-<eslug>` or `spec/<PRD>-<vslug>` from that folder, matching today's branch names, and `spec/<SLICE-KEY>-<slug>` from a slice folder's own basename — which collides with neither `/dev-workflows:create-prd` on the BRD route's `prd/` branch on the same key, nor `/dev-workflows:create-ard` on the BRD route's `ard/` one, nor the `/brd-*` family's shared `brd/` one, because §2.2's prefix is the caller's own; `deliverable_paths` = `specification.md`, `_session.md`, `_glossary.md`, and the rendered `.html` — **plus, on the BRD route, `decisions.md`, `grounding/code-grounding.md` and `grounding/design-grounding.md`**, because the `consumed_by` writes above land in those three and an uncommitted consumption record is one no later run can read; `spec-seed.md` is not staged, because this run does not write to it; `title: <EPIC|PRD> Add specification`; and `body_facts` = the stage/user-story/AC/TC counts, the open-question count, and the `spec-reviewer` verdict — and, on the BRD route, the `<BRD-KEY>` this specification was seeded from and how many items were marked `consumed_by: specification`. **Merged-to-main = ready for the dev-team handover** — Devs and `/design` read the spec from `main`, never from the branch, and `require-on-main` now enforces that rather than merely stating it. Emit its §4.1 outcome line in the Final report.

### Next Epic (after a per-Epic spec from a multi-Epic PRD)

When this run authored a **per-Epic** spec that was selected from Step A's ≥2-Epics picker, offer — once Phase 7's write/commit completes — to continue with a sibling Epic under the same PRD:
```
choices: ["Next Epic — re-open the picker (Recommended)", "Stop here"]
```
On **"Next Epic"**, **re-render the Phase 2 Step A progress-aware picker minus the just-completed Epic** — recompute each remaining Epic's ○/◐/● state from its feature folder, so the freshly-authored spec now shows **● done** and drops out of the actionable set — then, on selection, set `focus_key` to the new Epic and loop back through Phase 2 Step B → Phases 3–7 for it. This offer does **not** apply to a single-Epic PRD or a broad PRD-level spec — there is no sibling to advance to. **On the BRD route it applies on exactly the same terms**: Step A runs there too, so a slice holding two or more `EPIC-` folders re-renders the picker like any other PRD folder, and a slice holding none or one does not — the same two exclusions as above, reached by the same test rather than by a route branch. What is *not* a sibling Epic is another **slice**: that is a separate folder with its own seed, reached by re-running `/dev-workflows:specify <SIBLING-SLICE-KEY>`, which waits on nothing this run produced.

### The Epic flow (document to the user)

1. `/dev-workflows:epics <ADDRESS>` writes one `EPIC-` folder per child Epic under the PRD folder.
2. `/dev-workflows:specify <EPIC-ADDRESS>` authors that Epic's `specification.md`.

**There is no step between them.** `/epics` writes into the tree this command reads, so an Epic is
visible to `/specify` the moment it is written — no creating it anywhere else, and nothing to import.
That gap used to be a manual export-and-re-import through a tracker, and removing it is most of what
this increment is for.


## Phase 8 — Session maintenance & feedback

Terminal phase — runs after Phase 7 and before the Final report is presented;
NEVER interrupts an earlier phase. `/specify` has no built-in maintenance agent,
so this phase invokes `impl-maintenance` on the Sonnet detection chain and then
persists the plugin-facing slice of its report as session feedback.

**Capture-at-block invariant.** This terminal phase captures gaps for a *completed* run. Separately, if an EARLIER phase **halts on a plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked), `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating — so a run abandoned at the block still records the gap. NEVER `emit-block` for a work-quality review BLOCK or an environment / user halt (repo/spec gate, key-not-found, cancellation). **The four argument- and tree-shaped stops are of that second class**: `SPECIFY_NEEDS_KEY`, `SPECIFY_ONE_ADDRESS`, `SPECIFY_BRD_NOT_FOUND` and `SPECIFY_BRD_NOT_SLICED` report the operator's own argument list or BRD tree, not a capability this plugin lacks, so none of them `emit-block`s.

**Session-hygiene invariant.** End the report with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the
`resume.md` write runs later, in the terminal cost phase, per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the
guidance only), then a
span suggestion (PRD-level→`/dev-workflows:epics` `/compact`; Epic-level→`/dev-workflows:design` `/clear`) +
`/rename <PRD-ID>-<slug>-pe`. Guidance only, never auto-run.

**The run's key on the BRD route.** Phase 0 resolved a BRD key, which is a folder name and never a
second identity (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1). Any tracker identity for this work,
if one exists at all, is the `key` in the PRD this BRD folder holds — glob
the BRD folder's `prd.md`, `kind: prd`. So the address passed to
`emit-auto` (below) and `emit-cost` (Phase 9) is that minted key when the folder holds a PRD carrying
one, and `null` otherwise (`source: none` either way); `commit-artifacts` resolves its own key the
same way and commits under `NOISSUE` when there is none, per
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4 step 4. The `<BRD-KEY>` is never passed as a
`key` — a folder key in a tracker-key field is the confusion the two fields exist to keep apart.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /specify
   > - What was done: [one-paragraph summary of the specification authored]
   > - Key events: [BLOCK reviews and their reason, unmounted-repo soft-gate advisories, unresolved open questions, picker or handoff friction — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: [the spec-reviewer verdict — PASS | PASS WITH RECOMMENDATIONS | BLOCK]
   > - Test result: N/A (no tests in /specify)
   > - Project root: [the resolved feature folder under $SPECS_PATH]"
2. **Persist plugin feedback (automatic).** Project the report's plugin-facing
   slice into the specs repo by citing
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
   `emit-auto` entry point (§6). Pass the Lessons Learned report,
   `command: /specify`, the run's `key` and `source`, and `plugin_version`
   (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto`
   renders only the report's **Command workflow improvements**, **New agents /
   skills**, and plugin **Reference docs** sections plus the **Key observations**
   that triggered them (§4) — never target-project `CLAUDE.md`/hook advice — as
   `origin: auto` entries, dedupes by stable `id` (§3), resolves the target via
   the §2 specs-first ladder, and writes silently.
3. **Surface** the persisted path (or "no plugin-facing signal — nothing
   persisted") as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits (still true — git for
the deliverable is offered only in Phase 7, and this phase itself runs no git;
those writes are committed by the terminal `commit-artifacts` step in Phase 9,
per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and NEVER writes
into the current working directory. The specs-first ladder writes the feedback
file inside `$SPECS_PATH`, alongside the feature folder — the intended home.

## Phase 9 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 8 (feedback)
and NEVER interrupts an earlier phase. Records this command's token-cost
contribution to the PRD by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /specify`, `phase: specification`, `role: pe`,
the run's `key` (or `null`) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<PRD-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no PRD key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

**Write the resume pointer.** Cite
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite
`<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the
pointer reflects the completed run, and before the commit step below, so it is
included in it. Redact per §1. Silent; the printed `### Context hygiene`
guidance already appeared in the report.

**Commit session artifacts (terminal).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`commit-artifacts` entry point (§4) inline — the LAST action of the run. It
stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits
`<KEY> Add dev-workflows session artifacts (/specify)` with no `Co-Authored-By`
trailer, and pushes to the branch this run's handoff phase created (§4.1). It
NEVER touches a code repo, a docs repo, or the current working
directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the
run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its
§6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git
for the deliverable is offered only in Phase 7; the terminal step above commits
only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes
into a docs/code repo or the current working directory; no user name is ever
written (§10 privacy).

## Final report

Report: feature-folder path; stage/user-story/AC/TC counts; open-question count; unmounted-repo advisories; **the PRD gate's return value and whether an authored `prd.md` was read from the resolved folder** — the same two lines on every route, so a reader can tell an `absent` PRD from an unrun gate; the `spec-reviewer` verdict; the `Phase handoff:` outcome line from `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1); the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; and a reminder of the Epic flow described above + that `Published: yes` is a human-only freeze step.

**On the BRD route, additionally:** the `<SLICE-KEY>` seeded from and its resolved folder; this run's
`parent:` key — every run of this route is slice-level — and the `(prd, epic)` pair Phase
2.5 passed to `ard-resolution.md` with the `status` it returned; which of `spec-seed.md`,
`decisions.md`, `grounding/code-grounding.md` and `grounding/design-grounding.md` were present, and
whether `code-grounding.md` carried a derivation matrix; that no `idea.md` was written and why; every
`[CG#n]`/`[DG#n]` dropped for want of a verifier outcome, by id; every `[VD#n]`/`[CD#n]`/`[AS#n]`
carried in as a gap rather than an input, by id and status; every contradiction Phase 5 recorded
rather than decided, with the reopening route named for each; every implementation-altitude item still
`consumed_by: none`, by id, per the design's *Consumption tracking* section (§7.3) — **excluding
the baseline `[CG#n]` findings**, which are never `consumed_by` anything and whose `none` therefore
reports no gap (`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §4.1); say that they are
excluded, so a reader can tell an empty list from an unrun check; `spec-seed.md`'s
consumption at file granularity, and the derivation matrix's the same way; and any product- or
architecture-altitude content the grill surfaced and left for the command that authors at that
altitude instead of the spec (D5) — naming the command, never a seed file, since the register it will
read that content out of is the one this run already read. Say plainly whether `/dev-workflows:design` was named in the `### Next step` and, when it
was not.

### Next step

End the report with a `### Next step` recommendation per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` (guidance only — never auto-invoked): **Epic-level spec** (the address resolved an `EPIC-` folder) → hand to Dev → `/dev-workflows:design <EPIC>` `<merge-clause>`, which will not start until this spec is on the default branch — on every path, since `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3.4's `/design` row is a stop even for a spec that reached no branch — and the **Epic fan-out** `/dev-workflows:specify <SIBLING-EPIC>` for a sibling Epic (breadth), which waits on nothing this run produced and carries no clause; **PRD-level spec** (the address resolved a `PRD-` folder) → `/dev-workflows:epics <PRD>` (PE) `<merge-clause>`, which stops rather than skipping wherever this spec reached a branch (§3.3 rows D/E) and skips exactly as it did before wherever it reached none (§3.4's `/epics` row). If the run BLOCKED or left open `- [ ]` items, recommend resolving those first.

**One precondition governs every `/dev-workflows:epics` option above, on both routes.** `/epics` accepts
a folder holding a `prd.md` that asserts `kind: prd` and refuses one that does not
(`commands/epics.md` Phase 0 step 1b, `EPICS_NO_PRD`). This run does **not** require a PRD — its Phase 0
gate has an `absent` branch that specifies from the resolved folder, and on the BRD route
`/dev-workflows:create-prd` is not a prerequisite at all — so the folder it just wrote a specification
into may legitimately hold no PRD. **Test the resolved PRD folder for an authored `prd.md`** before
rendering the recommendation: where there is one, name `/dev-workflows:epics <ADDRESS>`; where there is
not, name **`/dev-workflows:create-prd <ADDRESS>`** instead, which authors the PRD `/epics` then reads and
takes the same single address. Offering `/epics` there would name a run that stops on arrival.

**On the BRD route the same offers apply, on the same terms.**
`/dev-workflows:design` and `/dev-workflows:epics` both resolve a folder in the specs tree with
`resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3) — the same tree, and often
the same folder, this run has just written into:

- **`/dev-workflows:design <ADDRESS>` `<merge-clause>`** — it gates the `specification.md` this run
  wrote, so the clause is required.
- **`/dev-workflows:epics <ADDRESS>`** — it reads the PRD folder and gates nothing this run
  produced, so it carries no clause; it is subject to the `prd.md` precondition above, which is the
  same test on both routes and not a BRD-route qualification.

**What this replaces is worth naming, because a reader who remembers it will look for it.** Both
offers used to be withheld unless an export directory existed under the key, a test that existed
only because both commands resolved that export and found nothing without it. Neither reads an
export any more. The test is not relaxed — its subject no longer exists.

- Consider **`/rename <PRD-ID>-<slug>-pe`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
