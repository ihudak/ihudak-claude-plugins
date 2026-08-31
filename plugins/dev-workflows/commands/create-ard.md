---
name: create-ard
description: Architecture-authoring workflow (Product Architect phase, sub-project 3 of the PRD-creation flow). Grounds on the mounted implementation repos (architect-driven discovery — no PRs) and authors an ARD for a PRD (/create-ard <PRD-KEY>) or an Epic (/create-ard <PRD-KEY> <Epic-KEY>, inheriting the PRD-level ARD), against references/ard-format.md, gated by the Opus ard-reviewer, written to $SPECS_PATH/specifications/<KEY>-<slug>/. Optional; scoped; product-architecture level (no code writing). Introduces the pa role. --from-brd seeds the run from a reconciled BRD instead of a PRD: it resolves the BRD folder at either level, reads that folder's architecture-altitude ard-seed.md, the architecture decisions in decisions.md and the verified [CG#n]/[DG#n] findings, seeds the ARD's grounding-findings section and its AD#N from them, freezes every [VD#n]/[CD#n] against the grill, runs no jira-reader and gates no PRD, and marks each consumed item consumed_by: ARD.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Author an Architecture Requirements/Decision Document for the Jira item: $ARGUMENTS

`/create-ard` is **sub-project 3 of the PRD-creation flow** — the **Product Architect (PA)** phase. It
grounds on the mounted implementation repos and authors an **ARD** that establishes the architecture
invariants the downstream (`/specify`, `/design`, `/implement`) will later inherit. The ARD is
**optional** (a simple PRD may not need one) and **scoped** via the two-key grammar:

- `/create-ard <PRD-KEY>` → a **PRD-level** ARD.
- `/create-ard <PRD-KEY> <Epic-KEY>` → an **Epic-level** ARD (inherits the PRD-level ARD read-only).
- `/create-ard <BRD-KEY> --from-brd` → a **BRD-level** ARD, seeded from a reconciled BRD instead of a
  PRD. One key only: `--from-brd` takes no second positional key (Phase 0 step 1b).

Usage: `/create-ard <PRD-KEY|BRD-KEY> [<Epic-KEY>] [--from-brd [<dir>]] [--no-docs]`.

It authors architecture only — no code writing; grounding is **architect-driven** (there are no PRs at
this stage). Zero Jira API.

---

## Phase 0 — Resolve input
1. **Scan the argument list for `--from-brd` before resolving anything.** The flag decides *which*
   resolution runs, and the scan is pure argument parsing — it touches no filesystem, no Jira export
   and no tracker, so it is safe this early.

   **Without `--from-brd` — unchanged.** Resolve the Jira input via
   `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against `$ARGUMENTS` → `jira_key` (the
   PRD), `focus_key` (the Epic, or `null`), `jira_export_root`, `source`. Define `<PRD>` = `jira_key`,
   `<EPIC>` = `focus_key`.

   **With `--from-brd` — the positional token is a BRD key**, and it is validated by `key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1) instead. A slice's key carries a third
   numeric segment (`EPIC-008-01`) and a slice is the level this route most often reaches an ARD at,
   so validating it against a two-segment form would refuse the ordinary case. A key that fails the
   grammar stops with
   `CREATE_ARD_NEEDS_KEY: /create-ard --from-brd needs a BRD key (^[A-Z][A-Z0-9_]*(-\d+)+$, e.g. EPIC-008 or the slice EPIC-008-01) — re-run '/dev-workflows:create-ard <BRD-KEY> --from-brd'.`
   Shape only, and never checked against a tracker (§1) — a BRD is a markdown file in `$SPECS_PATH`,
   not a ticket. Define `<BRD-KEY>` = that key; `focus_key` stays `null`, `jira_export_root` is unset,
   and `source: none`.

   **The shared front-end is not run at all on this route, and that is the point.**
   `jira-input-resolution.md` resolves `$VAULT_PATH/jira-products/<KEY>` and fails its Fallback B when
   that directory is missing; a BRD key names a folder under `$SPECS_PATH/specifications/` and was
   never a tracker key, so handing it one would stop the run on a key that no tracker was ever asked
   for. **No `jira-reader` dispatch happens anywhere in this command under `--from-brd`** — Phase 2
   substitutes the BRD's own seed for the export read, and there is no other call site.

1a. **`--from-brd [<dir>]` — a switch, not a path.** The positional key already identifies the BRD and
    `resolve-address` (step 3) finds it at either level, so `/create-ard EPIC-008-01 --from-brd` needs no
    path. A directory may be given for a BRD folder outside the normal layout; it is never required,
    and a token following `--from-brd` is consumed as that path only when it is not itself a flag. A
    given path that is not an existing directory stops with `CREATE_ARD_BRD_NOT_FOUND` (step 3) naming
    the path as supplied, rather than being silently re-read as a key.

1b. **A second positional key is refused under `--from-brd`.** Stop gracefully:
    `CREATE_ARD_BRD_NO_EPIC: /create-ard --from-brd is BRD-level and takes one key; <second-token> was given as a second. A BRD has no Epics yet — they are minted from the PRD's Jira workitem after /dev-workflows:create-prd <BRD-KEY> --from-brd completes its round-trip — and ard-seed.md, decisions.md and grounding/ exist only at a BRD's own level. Re-run '/dev-workflows:create-ard <BRD-KEY> --from-brd'.`
    The nesting a second key would express is served instead by `brd-link.md`'s `parent:`: a slice
    inherits its parent BRD's ARD read-only exactly as an Epic-level run inherits its PRD-level one
    (Phase 2), and the caller supplies no parent key for it — `resolve-address` and `brd-link.md` between
    them already know it.
2. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
3. **Feature folder.** PRD-level → `specifications/<PRD>-<vslug>/`; Epic-level → `specifications/<PRD>-<vslug>/<EPIC>-<eslug>/`. Honor an existing dir matched by key-number (tolerate `-`/`_` drift). No match there → apply `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §7's one-level-deep fallback before concluding none exists; it is reached only on a flat miss, so a flat key resolves exactly as it did before. Every later `specifications/<PRD>-<vslug>/` in this command — the PRD gate's `ls-tree` path and Phase 2's PRD read included — names the dir resolved here. Auto-created on first write at the flat path — the fallback honors a nested folder that already exists, it never proposes one.

   **Under `--from-brd` this is the resolved BRD folder**, and it is never created here: resolve it
   with `resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), which already
   searches both levels, or read the `--from-brd <dir>` path when one was given. The ARD this run
   authors is written **into that folder**, beside the BRD artifacts it was derived from. `absent` is
   a graceful stop, not a folder to create — and it names **both** ways a BRD folder comes into being
   rather than picking one, because nothing on disk says whether this key names a BRD with a source
   document or a slice of one, and a key's segment count is a naming convention, never a depth
   declaration (§1):
   `CREATE_ARD_BRD_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /dev-workflows:brd-split on its parent.`
   Where a `--from-brd <dir>` path was supplied and is not an existing directory, the same stop
   substitutes that path for the search clause — `no BRD folder at <path> (supplied with --from-brd)` —
   because "both levels searched" would describe a search this run did not perform.
4. **Prior ARD.** If the target `*_ARD.md` exists → Phase 1 offers refine-vs-fresh. **Under `--from-brd` the target is `<BRD-dir>/<BRD-KEY>_ARD.md`** — the same glob in the same folder, keyed by the BRD key this run resolved.
5. **Optionality advisory.** Gauge size — the PRD's user-story count / scope breadth / number of candidate repos. For a small, single-repo PRD, note "an ARD may be optional here" and offer `choices: ["Author the ARD anyway", "Stop — no ARD needed", "Other… (describe)"]`. **Under `--from-brd` gauge the same question off the seed instead**, since there is no PRD to count user stories in: the number of architecture-altitude `decided` records in `decisions.md`, the number of `[CG#n]`/`[DG#n]` findings at architecture altitude, and the number of repositories `grounding/baselines.md` pinned. A BRD whose whole architecture altitude is one decision against one repository is exactly the case the advisory exists for.

`/create-ard` is **cwd-agnostic**; it reads the PRD/Epic — or, under `--from-brd`, the BRD folder's seed, register and findings — and scans repos under `$REPOS_PATH`.

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.

**Gate the PRD.** Execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against the PRD file in `specifications/<PRD>-<vslug>/` — **resolve its actual name on the ref first**: `git -C "$SPECS_PATH" ls-tree --name-only "origin/<default>" "specifications/<PRD>-<vslug>/"` filtered to `<PRD>_*.md`, falling back to the derived `<PRD>_<vslug>.md` only when that listing is empty. A human-adjusted slug is a supported state — `/create-prd` and this command's own Phase 2 reader both locate the PRD by glob plus frontmatter, and the feature folder is matched by key-number for the same reason — so gating an exact derived filename would report `absent` for a PRD that is present, and would let a slug-drifted file on a plugin branch escape the rows D/E stop entirely. Map its §3.7 return value by `stopped` first, never by `on_main` alone. Any stopping state → stop per §4.4. Otherwise (`stopped: false`): on `pass`/`pass_amending`, read the authored PRD in Phase 2 as today; on `absent`, the existing `jira-reader` fallback applies — but report it: *"No authored PRD on `<default>` for `<PRD>` — architecting from the Jira export at `<path>`. If a PRD exists on a branch, this run would have stopped; it does not, so none does."*; on `unmanaged`, behave exactly as before this feature — reachable here even after step 2's own `$SPECS_PATH` check, since that check only rejects an unset value, never an invalid path or a non-git directory.

**Under `--from-brd` the PRD gate does not run, because the PRD is not this route's content source.**
The gate exists so this command never architects from a PRD that is unmerged or stale; here the
content source is the BRD folder's `ard-seed.md`, its architecture-altitude decisions, and its
verified findings, and the PRD — which may not exist at all, since `/create-prd --from-brd` is not a
prerequisite for this one — is read by nothing in this run. Gating an artifact the run does not read
would promote an input this route never had into a prerequisite, which is exactly what
`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §5 rule 3 forbids; and its `absent` branch above
falls back to `jira-reader` against the Jira export, which on this route would mean handing a folder
key to a tracker lookup. So the gate is skipped, not re-pointed, and §3.4's `/create-ard` row keeps
describing the route that runs it. What puts the seed on the default branch instead is the
`/brd-*` family's own handoff discipline: each of those commands lands its deliverable on the specs
default branch and the next refuses to start until it is there, so a reconciled BRD folder is already
merged by the time this route reads it. This mirrors `/dev-workflows:create-prd --from-brd`, which
likewise skips the gate on the input its own seed replaces.

---

## Phase 1 — Configure
Use `choices` arrays; the last choice is always `"Other… (describe)"`.
1. **Confirm** the scope (PRD-level vs Epic-level) and the feature folder. **Under `--from-brd`**, confirm instead the BRD folder and a `from BRD:` line naming `<BRD-KEY>`, its `parent:` if `brd-link.md` records one (and therefore whether this run is BRD-level or slice-level), its `depends-on:` if any, and which of `ard-seed.md`, `decisions.md`, `grounding/code-grounding.md` and `grounding/design-grounding.md` are present — a stat, not a read; the read is Phase 2.
   - Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).
2. **Refine vs fresh** (only if a prior `*_ARD.md` exists): `choices: ["Refine the existing ARD (Recommended)", "Start fresh — overwrite", "Cancel", "Other… (describe)"]`.
3. **Repos search base (`$REPOS_PATH`).** Read `${REPOS_PATH:-/workspace}` (may be colon-separated): `choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]`.
4. **Repo refresh policy** (governs Phase 3's `code-scanner`): `choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh", "Other… (describe)"]`.

---

## Phase 1.5 — Classify + model routing
Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE | SIGNIFICANT | HIGH-RISK   # architecture; SIGNIFICANT common for cross-repo PRDs
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # jira-reader, code-scanner, impl-maintenance
  review_model:    <§2 Opus chain>     # ard-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + ARD authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

**Tiered HARD model gate (like `/design`):** for `SIGNIFICANT` / `HIGH-RISK`, require an Opus session — if `opus_available` is false, stop: `choices: ["I'll relaunch /dev-workflows:create-ard on Opus (Recommended)", "Override — proceed on the current model (logged in the final report)", "Cancel", "Other… (describe)"]`. For `SIMPLE`/`MODERATE`, degradation is advisory (record in `notes`).

---

## Phase 2 — Read the PRD (+ Epic, + inherited ARD)

**Under `--from-brd` everything in this phase down to the `--from-brd` section below is replaced, not
adapted**: no PRD read, no `jira-reader` dispatch of either kind, and the inherited-ARD resolution
uses the `(prd, epic)` pair that section derives. "Epic-level run" in the paragraphs immediately below
means a run invoked with a second positional key, which `--from-brd` refuses (Phase 0 step 1b) — a
slice's `scope: epic` frontmatter (Phase 4) is a statement about altitude and inheritance, not about
this phase's run mode.

Read the PRD from `$SPECS_PATH/specifications/<PRD>-<vslug>/` — glob `<PRD>_*.md` and use the file whose frontmatter is `issue_type: ValueIncrement` (canonical `<PRD>_<slug>.md`) when present (authored source); else dispatch `jira-reader` to read it from the export:

→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Return the structured handoff for this brief:
  >
  > jira_export_root: [resolved jira_export_root]
  > jira_key:         [<PRD> for a PRD-level run, <EPIC> for an Epic-level run]
  > depth:      prd-only (PRD-level) | full (Epic-level, scoped to focus_key)"

For an **Epic-level** run always dispatch `jira-reader` this way (`depth: full`, scoped to `focus_key`) for the Epic's scope — the authored-PRD-file check above only applies PRD-level. Resolve any PRD-level ARD via `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` (`prd: <PRD>`, `epic: null`, `$SPECS_PATH`). On `status: found`, load its `AD#N` invariants to **inherit read-only**. On `status: unmerged`, **stop**, naming the returned `branch` and any `pr`. On `status: none`, proceed unchanged — there is no PRD-level ARD to inherit.

Extract the problem/goal/scope frame + capability themes — the raw material for grounding + the grill.

### `--from-brd` — read the architecture-altitude seed, the register, and the verified findings

Under `--from-brd` this phase reads the BRD folder Phase 0 step 3 resolved and dispatches
`jira-reader` **not at all**. Read exactly these, and no other seed:

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
  decision, not an omission — `/dev-workflows:create-prd --from-brd` is where that gate lives, and
  this command is reachable without it.

**Absence is reported, never a stop, and the seed's absence is the ordinary case.** Nothing on the
normal route writes a seed file at all (above), so a reconciled BRD routinely holds none; and a BRD
ground with `--no-design` holds no `design-grounding.md` at all. Say which of the four were absent — a reader cannot tell an unwritten
file from an unread one — and carry what is there.

**Partition the register before the grill starts, because the partition is what freezes it.** The
five states and their treatment are `decision-register-format.md` §3's, applied here exactly as
`/dev-workflows:create-prd --from-brd` applies them one altitude up: a `decided` record is an
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

**Inheritance under `--from-brd` uses `brd-link.md`'s `parent:`, never a segment count.** Resolve any
inherited ARD via `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with:

- **no `parent:`** (this BRD owns its source document) → `prd: <BRD-KEY>`, `epic: null`;
- **a `parent:`** (this BRD is a slice) → `prd: <parent-key>`, `epic: <BRD-KEY>`.

The second mapping needs no change to that reference: a slice folder sits inside its parent's exactly
as an Epic subfolder sits inside a PRD dir, which is the layout its Epic-level branch already
collects — the slice's own `<BRD-KEY>_ARD.md` plus the parent's `<parent-key>_ARD.md` for inherited
invariants. Act on the returned `status` exactly as above: `found` → inherit those `AD#N` read-only;
`unmerged` → **stop**, naming the returned `branch` and any `pr`; `none` → proceed unchanged.

---

## Phase 3 — Architect-driven grounding (no PRs)
There are no PRs at ARD time, so repos are **architect-driven**, not PR-derived:
1. **Cheap discovery.** List the top-level directories under each `$REPOS_PATH` entry (`ls`). Optionally attach each dir's one-line identity — `timeout 5 git -C <dir> remote get-url origin 2>/dev/null` (slug) or its README first heading. Do **not** deep-scan to guess relevance.
2. **Propose + ask.** From the PRD/Epic themes, propose a `theme → repo` mapping against those dirs, and **ask the architect to confirm / correct / add**. For any requirement that maps to no obvious repo, **ask outright**: "which repo covers `<X>`?"

   **Under `--from-brd` the proposal starts from `<BRD-dir>/grounding/baselines.md`**, which already
   records repository → pinned commit for every repo `/dev-workflows:brd-ground` read, rather than
   from PRD themes this route does not have. That is a better starting set than a theme guess and it
   is still only a proposal: the architect confirms, corrects and adds exactly as above, and a repo
   `baselines.md` names but `$REPOS_PATH` does not hold reaches step 3's mount-or-descope gate like
   any other. A finding's evidence is cited at the commit that finding is pinned to
   (`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §2), which is not necessarily the commit a
   fresh scan reads; where the two differ, say so beside the claim rather than silently re-dating it.
3. **Missing repo → consolidated mount-or-descope gate:** `choices: ["Mount now & re-scan", "Ground only the confirmed-mounted set (record the rest as open questions)", "Specify an absolute path for this repo", "Cancel", "Other… (describe)"]`.
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
5. **Documentation grounding (optional).** Run `resolve-docs-grounding create-ard` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the PRD/Epic goal + capability themes, `jira_key` = `<PRD>` (PRD-level) or `<EPIC>` (Epic-level), `themes` = the confirmed themes. Carry the digest into the Phase 4 grill with **grill-rank** consumption (documented analogs and building-block altitude/permissions are strong ARD grounding). When OFF, skip silently.

---

## Phase 4 — Author via grill
**Interview technique (grilling — embedded; no runtime dependency).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, explore the Phase 3 grounding findings / the PRD to self-answer (fact-vs-decision), walk the design tree in dependency order, continue to shared understanding then write each section.

Author the ARD live against `${CLAUDE_PLUGIN_ROOT}/references/ard-format.md`, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`, at the resolved altitude: Context → Grounding findings (cite `file:line`) → Architecture decisions (`AD#N`: Binds/Prevents/Rule) → Cross-repo/component approach → Stack & invariants → Edge cases & risks → Open questions → Deferred. At Epic level, list inherited PRD-level ADs read-only and never contradict them; PRD level stays at invariants/frame (no per-repo detailed solutions).

### `--from-brd` — the seed fills the sections, and the grill is restricted to gaps

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

**Frontmatter under `--from-brd`**, per `ard-format.md`'s block, each field read from what Phase 2
already holds and none of them asked of the user:

- `scope: prd` when this BRD owns its source document; `scope: epic` when it is a slice. Not because
  a slice is an Epic, but because `scope` selects the altitude rule `ard-reviewer` applies and the
  inheritance shape `ard-resolution.md` reads, and a slice sits in both exactly where an Epic does —
  one level down, inheriting its parent's `AD#N` read-only.
- `prd:` and `epic:` are the same pair Phase 2 passed to `resolve-ard`: `<BRD-KEY>` and `null` for a
  source-owning BRD, the `parent:` key and `<BRD-KEY>` for a slice. Frontmatter and resolver agree
  because they are written from one resolution, not two.
- `inherits:` the parent BRD's `<parent-key>_ARD.md` when `resolve-ard` returned one, else `null`.
- `derived_from:` the PRD file in this BRD folder when one is there — the ordinary case, since this
  route is normally reached from `/dev-workflows:create-prd --from-brd`'s own next-step offer — else
  `<BRD-dir>/ard-seed.md`, the artifact this ARD was actually authored from. The field records
  provenance, and naming a PRD path in a folder that holds no PRD would name a file that does not
  exist.
- `grounded_repos:` unchanged — the repos Phase 3 confirmed, which is what every `file:line` in the
  ARD must cite into.

**Per-area split.** If (Epic level) the confirmed grounding spans separable areas in one repo (e.g. `server/` backend + `ui/` frontend), grill: `choices: ["One combined ARD (Recommended)", "One ARD per area (backend / frontend / …)", "Other… (describe)"]`. On per-area, author one `<EPIC>-<area>_ARD.md` per area (each with its own `area:` frontmatter).

---

## Phase 4.5 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against the drafted `*_ARD.md`: the **Universal checks**,
the **Jira-key collision** check (run on the ARD body below the frontmatter), and the **ARD** block
(incl. that every `### [AD#N]` carries `**Binds:**` / `**Prevents:**` / `**Rule:**`). Surface every
finding; inline-fix the mechanical ones (renumber a duplicate `[AD#N]`, delete a stray placeholder
token); leave content gaps for the grill/author. **Advisory** — never blocks;
proceed to Phase 5 once findings are surfaced. `ard-reviewer` remains the gate.

**Under `--from-brd`, a `<BRD-KEY>` in the ARD body is the Jira-key check's third branch, not its
second.** The body legitimately names prerequisite BRDs — a `will-change` finding's prerequisite, a
`conditional_on` decision's — and the collision grep matches the leading two segments of any of them.
A BRD key is not a requirement ID and it is **not a real Jira ticket**: it is a folder name under
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
  > ARD path: [absolute path to the *_ARD.md]
  > Scope: [prd | epic]"

On `BLOCK`, fix the BLOCKER findings inline (the orchestrator/grill edits the ARD — no delegated writer) and re-review **once**; if still `BLOCK`, escalate per the `Review verdict BLOCK` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. `PASS` / `PASS WITH RECOMMENDATIONS` → proceed. Cap: one fix cycle + one re-review. (For a per-area split, review each area ARD.)

---

## Phase 6 — Handoff
Write the ARD file(s) into the feature folder.

**Under `--from-brd`, also close the consumption loop before the offer.** The design's *Consumption
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

Then **offer** (commit-when-asked — never automatic), presenting `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim: `choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]`. On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: ard`; `feature_folder` as resolved in Phase 0 (the PRD dir for a PRD-level ARD, the Epic subfolder for an Epic-level ARD — §2.2 derives `ard/<PRD>-<vslug>` or `ard/<EPIC>-<eslug>` from it, matching today's branch names); `deliverable_paths` = the ARD file(s) — **plus, under `--from-brd`, `decisions.md`, `grounding/code-grounding.md` and `grounding/design-grounding.md`**, because the `consumed_by` writes above land in those three and an uncommitted consumption record is one no later run can read; `ard-seed.md` is not staged, because this run does not write to it; `title: <PRD|EPIC> Add architecture requirements document`; and `body_facts` = the ARD scope (PRD/Epic, any per-area split), the grounded/descoped repos, the `AD#N` count, the open-question count, and the `ard-reviewer` verdict — and, under `--from-brd`, the `<BRD-KEY>` this ARD was seeded from and how many items were marked `consumed_by: ARD`. Emit its §4.1 outcome line in the Final report.

**Under `--from-brd` the feature folder is the BRD folder**, so §2.2 derives the branch
`ard/<BRD-KEY>-<slug>` from it — a slice's is `ard/<SLICE-KEY>-<slug>`, from the folder basename, not
from a re-derived title. That name collides with neither `/dev-workflows:create-prd --from-brd`'s
`prd/` branch on the same key, nor `/dev-workflows:specify --from-brd`'s `spec/` one, nor the
`/brd-*` family's shared `brd/` one, because §2.2's prefix is the caller's own. The commit message's key is the run's key, resolved as Phase 8 resolves it.

---

## Phase 7 — Next-step offer (adaptive)
- **PRD-level ARD:** if the PRD has 0 Epics → `choices: ["Hand to a Product Engineer — /dev-workflows:epics <PRD> (then create them in Jira + re-import) (PE) (Recommended) <merge-clause>", "Author a PRD-level spec — /dev-workflows:specify <PRD> (PE) <merge-clause>", "Stop here", "Other… (describe)"]`; else offer `/dev-workflows:specify <PRD>` (PE) carrying the same `<merge-clause>`. *(No `/design` — no Epics yet.)*
- **Epic-level ARD:** `choices: ["Author the spec — /dev-workflows:specify <PRD> <Epic> (PE) (Recommended) <merge-clause>", "Hand to Dev — /dev-workflows:design <PRD> <Epic> (Dev) <merge-clause>", "Stop here", "Other… (describe)"]`. **Epic fan-out** — repeat this ARD for a sibling Epic: `/dev-workflows:create-ard <PRD> <another-Epic>`; that run inherits the PRD-level ARD, not this Epic-level one, so it waits on nothing this run produced and carries no clause.
- **`--from-brd` (BRD-level ARD):** a different array, because **the key this run holds is a BRD key
  and only one of the three usual options can be reached with one**:
  `choices: ["Author this BRD's specification — /dev-workflows:specify <BRD-KEY> --from-brd (PE) (Recommended) <merge-clause>", "Hand to a Product Engineer — /dev-workflows:epics <BRD-KEY> (PE) <merge-clause>", "Stop here", "Other… (describe)"]`
  — with the second option **present only when the test below passes, and dropped from the array
  entirely when it does not**.
  - **`/dev-workflows:specify <BRD-KEY> --from-brd` is always reachable from this state.** It takes
    the same BRD key this run resolved, finds the same folder through `resolve-address`
    (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), and needs no tracker key and no Jira
    export. It resolves this ARD through `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` and
    stops on `status: unmerged`, so the wait is real and the clause is required.
  - **`/dev-workflows:epics` is offered only when `$VAULT_PATH/jira-products/<BRD-KEY>/<BRD-KEY>-index.md`
    exists.** That one test settles both halves of reachability, and it is deliberately stricter than
    "some `jira_key` was minted". It settles the **key** half directly — it is exactly what
    `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`'s JiraID resolution requires and what
    its Fallback B fires on when it is missing — and it settles the **ARD** half, because
    `/dev-workflows:epics` resolves this ARD through
    `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` under the *same* key, reaching this folder at
    either level via `addressing.md` §7's fallback. Passing that test means the BRD was keyed with
    the tracker's own key, so `jira_key` and `<BRD-KEY>` are the same string and the option hands
    `jira-reader` a real tracker key rather than a folder name (§1). **The option is written in
    `<BRD-KEY>`, matching `/dev-workflows:specify`'s sibling site**, because that is the only key this
    run resolves: no `jira_key` is in hand here — one exists only where the BRD folder happens to hold
    a PRD carrying one, and this route requires no PRD — and the gate above is written entirely in
    `<BRD-KEY>` too. Naming `<jira_key>` would name a placeholder nothing on this route binds. This is
    not a two-keys violation: the gate is what establishes that the BRD key is the key the tracker
    export is filed under, so the string handed over is a tracker key that happens to be spelled the
    same as the folder key, and it is offered only where that has been shown.
    **A minted `jira_key` that differs from `<BRD-KEY>` does not qualify**: under it `ard-resolution.md` resolves a different
    `specifications/` folder, returns `status: none` for this ARD, and `/dev-workflows:epics` proceeds
    with no ARD at all — which is not a wait the merge clause could describe but a permanent blind
    spot, and naming the command there would promise an inheritance that never happens. Where the test
    fails, **offer no command** and say what would make one reachable: the Jira round-trip in
    `/dev-workflows:create-prd <BRD-KEY> --from-brd`'s handoff phase — create the workitem, paste the
    PRD body in, re-import it to `$VAULT_PATH/jira-products/<KEY>` — is what mints a key and an export
    at all, and `/dev-workflows:brd-split` is where an operator chooses to key a slice with the
    tracker's key so the two coincide. Per the *When no option is safe to recommend* guidance in
    `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`, nothing said in that state is marked
    `(Recommended)` beyond the first option, which remains reachable regardless.
  - **`/dev-workflows:design` is offered on this route by neither branch.** It takes over a merged
    `specification.md` — a file this run did not write — and resolves its own key through the Jira
    export. The path to it runs through the first option: `/dev-workflows:specify <BRD-KEY>
    --from-brd` writes that specification, and its own next-step offer is where `/dev-workflows:design`
    is named under the conditions that make it resolvable.
  - **There is no Epic fan-out on this route.** `--from-brd` is BRD-level and takes no second
    positional key (Phase 0 step 1b), so there is no sibling Epic to repeat this ARD for. A sibling
    *slice* is a separate BRD with its own folder and its own seed: `/dev-workflows:create-ard
    <SIBLING-SLICE-KEY> --from-brd` waits on nothing this run produced and would carry no clause.

**Every merge clause above is the `<merge-clause>` placeholder**, resolved from this run's own `Phase handoff:` outcome line per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`, and never the unconditional "once the pull request above is merged": a declined handoff, a failed push and a nothing-to-commit run each leave a different wait, and two of them open no pull request to wait on. It is a placeholder, not an instruction to reword an option, so the arrays are still presented verbatim per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. **The wait it names is real for every command named above**, and it is a stop, not a silent degradation: `/dev-workflows:epics`, `/dev-workflows:specify` and `/dev-workflows:design` each read this ARD through `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` and each stops on `status: unmerged`, naming the branch and any open pull request. Only a handoff that reached no branch at all resolves `status: none`, where that reference's no-regression rule has the run proceed exactly as it would with no ARD.

Guidance only — never auto-invokes another command. Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`.

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 8), per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. The next step hands off from PA
to PE/Dev, so:

- **Handing to PE (`/dev-workflows:epics <PRD>` / `/dev-workflows:specify <PRD> <Epic>`) or Dev (`/dev-workflows:design <PRD> <Epic>`), even yourself?** → run **`/clear`** for a clean slate; the ARD is on disk.
- **Under `--from-brd`, the handoff is `/dev-workflows:specify <BRD-KEY> --from-brd`** (Phase 7) — same answer, **`/clear`**; the ARD is on disk and that run reads it from the specs repo, not from this session.
- Continuing to draft more ARD areas yourself right now? → **`/compact`** is fine.
- Consider **`/rename <PRD-ID>-<slug>-pa`** so you can find this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.

---

## Phase 8 — Session maintenance, feedback & cost
Terminal phase — runs after Phase 7, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference gap**, `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment / user halt (unset `$SPECS_PATH`, missing key, no-ARD-needed, unmounted-repo descope, cancellation) or a review BLOCK. **The three `--from-brd` stops are of that second class**: `CREATE_ARD_NEEDS_KEY`, `CREATE_ARD_BRD_NOT_FOUND` and `CREATE_ARD_BRD_NO_EPIC` report the operator's own argument list or BRD tree, not a capability this plugin lacks, so none of them `emit-block`s.

**Session-hygiene invariant.** End Phase 7 with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the
`resume.md` write runs later, in the terminal cost phase, per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the
guidance only), then a
PA→PE/Dev handoff suggestion (`/clear`) + `/rename <PRD-ID>-<slug>-pa`. Guidance only, never auto-run.

**The run's key under `--from-brd`.** Phase 0 resolved a BRD key, which is a folder name and never a
tracker key (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1). The tracker key for this work,
if one exists at all, is the `jira_key` in the PRD this BRD folder holds — the same one Phase 7's
`/dev-workflows:epics` condition reads. So the `jira_key` passed to `emit-auto` and `emit-cost` below
is that minted key when the folder holds a PRD carrying one, and `null` otherwise (`source: none`
either way); `commit-artifacts` resolves its own key the same way and commits under `NOISSUE` when
there is none, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4 step 4. The `<BRD-KEY>` is
never passed as a `jira_key` — a folder key in a tracker-key field is the confusion the two fields
exist to keep apart.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/create-ard`; what was authored (ARD scope + grounded repos); key events (grounding gaps/descopes, BLOCK reviews — or 'none'); workarounds; the `ard-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6) with the report, `command: /create-ard`, the run's `jira_key`, `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its `emit-cost` entry point with `command: /create-ard`, `phase: architecture`, `role: pa`, the run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite `<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the pointer reflects the completed run, and before the commit step below, so it is included in it. Redact per §1. Silent; the printed `### Context hygiene` guidance already appeared in the report.
5. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/create-ard)` with no `Co-Authored-By` trailer, and pushes to the branch this run's handoff phase created (§4.1). It NEVER touches a code repo, a docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is offered only in Phase 6; the terminal step above commits only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report
Report: the ARD path(s) + scope (PRD/Epic, any per-area split); the grounded repos + any descoped/ungrounded ones; `AD#N` count; open-question count; the `ard-reviewer` verdict; the `Phase handoff:` outcome line from `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1); resolved model routing (+ any Opus gate/degradation); the feedback + cost paths; the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; and the adaptive next-step recommendation.

**Under `--from-brd`, additionally:** the `<BRD-KEY>` seeded from and its resolved folder; whether
this run was BRD-level or slice-level and, for a slice, the `parent:` key and whether its ARD was
inherited (`found`) or absent (`none`); which of `ard-seed.md`, `decisions.md`,
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
Jira export resolved under `<BRD-KEY>` itself — naming the minted `jira_key` where one exists but
differs, since that is the case a reader is most likely to mistake for reachable (Phase 7).
