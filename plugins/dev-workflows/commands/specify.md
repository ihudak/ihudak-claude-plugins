---
name: specify
description: Jira-driven specification-authoring workflow (PE phase). Reads a Jira Epic/PRD from exported markdown, lightly grounds in code, and authors an org-standard specification.md through a relentless one-question-at-a-time grill; gates on the Opus spec-reviewer and lands the spec on the specs repo's main branch via branch + PR for the /design dev take-over. --from-brd seeds the run from a reconciled BRD instead of a Jira export: it resolves the BRD folder at either level, reads that folder's implementation-altitude spec-seed.md, the implementation decisions in decisions.md, the verified [CG#n]/[DG#n] findings and the derivation matrix /brd-ground appended to code-grounding.md, runs no jira-reader and gates no PRD, freezes every [VD#n]/[CD#n] against the grill, and marks each consumed item consumed_by: specification.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Author a product specification for the Jira item: $ARGUMENTS

`/specify` is the **PE-phase specification-authoring** workflow — the specification step of the PM→PA→PE→Dev pipeline
(`/specify` → `specification.md`; then `/design` → `design.md`). Given a Jira Epic (or PRD)
key or an imported-Jira directory, it reads the item from pre-exported markdown, lightly scans code to
ground feasibility, and authors an org-standard `specification.md` through a relentless
one-question-at-a-time grill — resolving open questions live instead of stopping. It gates on the
Opus `spec-reviewer` and offers to land the spec on the specs repo's main branch (via branch + PR) as
`Published: no`.

Key distinction from `/epics`: `/epics` *splits* a PRD into Epic drafts; `/specify` *authors one
specification* for a single item (typically an Epic). Run `/epics` first, then `/specify` per Epic.

Usage: `/specify <PRD-KEY|dir|BRD-KEY> [<Epic-KEY>] [--from-brd [<dir>]] [--no-docs]`. With
`--from-brd` the run is seeded from a reconciled BRD instead of a Jira export, the positional token is
a **BRD key**, and there is no second positional key (Phase 0 step 0).

---

## Phase 0 — Resolve input

0. **Scan the argument list for `--from-brd` before resolving anything.** The flag decides *which* of
   two resolutions runs, and the scan is pure argument parsing — it touches no filesystem, no Jira
   export and no tracker, so it is safe this early.

   **With `--from-brd`, step 1's shared front-end is not run at all**, and the positional token is a
   **BRD key** validated by `key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1) instead. A slice's key carries a third
   numeric segment (`EPIC-008-01`) and a slice is the level this route most often reaches a
   specification at, so validating it against a two-segment form would refuse the ordinary case. A key
   that fails the grammar stops with
   `SPECIFY_NEEDS_KEY: /specify --from-brd needs a BRD key (^[A-Z][A-Z0-9_]*(-\d+)+$, e.g. EPIC-008 or the slice EPIC-008-01) — re-run '/dev-workflows:specify <BRD-KEY> --from-brd'.`
   Shape only, and never checked against a tracker (§1) — a BRD is a markdown file in `$SPECS_PATH`,
   not a ticket. Define `<BRD-KEY>` = that key; `focus_key` stays `null`, `jira_export_root` is unset,
   `specs` is empty, and `source: none`.

   **Skipping the front-end is the point, not a shortcut.** `jira-input-resolution.md` resolves
   `$VAULT_PATH/jira-products/<KEY>` and fires its Fallback B when that directory is missing; a BRD key
   names a folder under `$SPECS_PATH/specifications/` and was never a tracker key, so handing it one
   would stop the run on a key no tracker was ever asked for. It follows that `SPECIFY_NEEDS_JIRA`
   below is **unreachable under `--from-brd`**: that stop reports the front-end returning
   `mode: direct`, and the front-end does not run.

   **A second positional key is refused under `--from-brd`.** Stop gracefully:
   `SPECIFY_BRD_NO_EPIC: /specify --from-brd is BRD-level and takes one key; <second-token> was given as a second. A BRD has no Epics yet — they are minted from the PRD's Jira workitem after /dev-workflows:create-prd <BRD-KEY> --from-brd completes its round-trip — and spec-seed.md, decisions.md and grounding/ exist only at a BRD's own level. Re-run '/dev-workflows:specify <BRD-KEY> --from-brd'.`

   **`--from-brd [<dir>]` is a switch, not a path.** The positional key already identifies the BRD and
   `resolve-address` (step 3) finds it at either level. A directory may be given for a BRD folder outside
   the normal layout; it is never required, and a token following `--from-brd` is consumed as that
   path only when it is not itself a flag. A given path that is not an existing directory stops with
   `SPECIFY_BRD_NOT_FOUND` (step 3) naming the path as supplied, rather than being silently re-read as
   a key.

1. **Resolve the Jira input via the shared front-end** (skipped entirely under `--from-brd`, per step
   0). Execute
   `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against `$ARGUMENTS`. `/specify` is
   **jira-driven only**: expect `mode: jira-driven`. The front-end owns the `$VAULT_PATH` /
   `jira-products` validation, Fallbacks A/B **and D/E**, and the PRD-selector (key-or-directory) +
   focus-Epic grammar. Carry forward:
   - `jira_key` — the resolved **top-level** key: the **PRD** when a focus Epic is present, or the
     stand-alone top-level item's own key otherwise.
   - `focus_key` — the **Epic** to center on within `jira_export_root`, or `null` for a bare PRD /
     stand-alone item / directory.
   - `jira_export_root`, `source`.

   Define `<PRD>` = `jira_key` and `<EPIC>` = `focus_key` (may be `null`). Downstream steps use these
   two symbols in place of the old single `<KEY>`.

   If the front-end returns `mode: direct` (no Jira input), stop with
   `SPECIFY_NEEDS_JIRA: /specify needs a Jira key or an imported-Jira directory.` — `/specify` has no
   direct-prompt behavior.

2. **Resolve `$SPECS_PATH`.** `/specify` writes specifications under `$SPECS_PATH/specifications/`
   (exact layout resolved in step 3) — the specs repo, not the vault. If `$SPECS_PATH` is unset, stop
   with a clear error naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`) —
   there is no vault-relative fallback for this write target the way there is for reads.

3. **Resolve the feature folder.** Derive provisional kebab-case slugs from the relevant
   Jira item title(s) (from the index/summary — finalized once `jira-reader` runs in Phase 2, but a
   provisional slug is enough to check for existing folders now): `<vslug>` for the `<PRD>` title, and
   `<eslug>` for the `<EPIC>` title when `focus_key` is set.

   - **Resolve/derive the PRD (top-level) dir:** call `resolve-address <PRD>`
     (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), which searches every level §3 bounds and
     carries §5's legacy fallback — including a slug a human has adjusted. No matching rule is
     written here; §5 owns it. Create `PRD-<PRD>-<vslug>/` per §2's convention only on
     `status: absent`. Every later
     `specifications/<PRD>-<vslug>/` in this command — the PRD gate's `ls-tree` path and Phase 2's
     per-Epic paths included — names the dir resolved here.
   - **Resolve the feature folder itself**, by case:
     - `focus_key` set (an Epic nested under a PRD) →
       `specifications/<PRD>-<vslug>/<EPIC>-<eslug>/` — a per-Epic subfolder under the PRD dir
       (`<eslug>` = kebab of the Epic title). Apply the same honor-an-existing-dir tolerance to the
       `<EPIC>-<eslug>` segment.
     - `focus_key` null **and** the item is a **PRD** for which the broad-PRD-spec choice is made
       (Phase 2, Step A) → `specifications/<PRD>-<vslug>/specification.md` — flat at the PRD-dir level, no
       per-Epic subfolder; the feature folder is the PRD dir itself.
     - `focus_key` null **and** the item is a **stand-alone top-level Epic** (no parent PRD) →
       `specifications/<EPIC>-<eslug>/`, where `<EPIC>` here is this item's own key (== `jira_key`,
       since `focus_key` is null) — top-level, keyed by the Epic, no PRD wrapper. Physically this is
       the same dir the PRD-dir step above already resolved (`specifications/<PRD>-<vslug>/` with
       `<PRD>` = `<EPIC>` = `jira_key`), so no separate resolution step is needed: the two null-`focus_key`
       cases share one physical target, `specifications/<jira_key>-<slug>/`, with `specification.md`
       written flat inside it either way.
   - All delimiters this step writes are hyphens; matching an existing dir tolerates a stray `-`/`_`.
     Neither the PRD dir nor the feature folder is created here — the first phase that writes to it
     (Phase 2's `idea.md` write, in a fresh run) creates it.

   **Under `--from-brd` the feature folder is the resolved BRD folder**, and it is never created here:
   resolve it with `resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), which
   already searches both levels, or read the `--from-brd <dir>` path when one was given.
   `specification.md` is written **flat inside that folder**, beside the BRD artifacts it was derived
   from — there is no per-Epic subfolder on this route, because `--from-brd` resolves no Epic (step 0).
   `absent` is a graceful stop, not a folder to create — and it names **both** ways a BRD folder comes
   into being rather than picking one, because nothing on disk says whether this key names a BRD with
   a source document or a slice of one, and a key's segment count is a naming convention, never a
   depth declaration (§1):
   `SPECIFY_BRD_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /dev-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /dev-workflows:brd-split on its parent.`
   Where a `--from-brd <dir>` path was supplied and is not an existing directory, the same stop
   substitutes that path for the search clause — `no BRD folder at <path> (supplied with --from-brd)` —
   because "both levels searched" would describe a search this run did not perform.

4. **Detect a prior run.** If a `_session.md` exists in the resolved feature folder, record that a
   resume is available — Phase 1 asks the user resume-vs-fresh. If no `_session.md` exists, this is a
   fresh run.

`/specify` is **cwd-agnostic**, like `/epics` — it reads Jira from the vault/export and writes specs to
an absolute `$SPECS_PATH`-rooted directory, so it does not require cwd to be inside either.

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier
run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent
when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if
it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal
`commit-artifacts` step skips on it.

**Gate the PRD.** Execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against the PRD file in `specifications/<PRD>-<vslug>/` — **resolve its actual name on the ref first**: `git -C "$SPECS_PATH" ls-tree --name-only "origin/<default>" "specifications/<PRD>-<vslug>/"` filtered to `<PRD>_*.md`, falling back to the derived `<PRD>_<vslug>.md` only when that listing is empty. A human-adjusted slug is a supported state — `/create-prd` and this command's own Phase 2 reader both locate the PRD by glob plus frontmatter, and the feature folder is matched by key-number for the same reason — so gating an exact derived filename would report `absent` for a PRD that is present, and would let a slug-drifted file on a plugin branch escape the rows D/E stop entirely. Map its §3.7 return value by `stopped` first, never by `on_main` alone. Any stopping state → stop per §4.4. Otherwise (`stopped: false`): on `pass`/`pass_amending`, proceed — Phase 2 still reads the item from Jira via `jira-reader` exactly as today; the merged PRD is a grounding confirmation, not a new content source; on `absent`, `/specify`'s existing Jira-export behaviour is unaffected — but report it: *"No authored PRD on `<default>` for `<PRD>` — specifying from the Jira export at `<path>`. If a PRD exists on a branch, this run would have stopped; it does not, so none does."*; on `unmanaged`, behave exactly as before this feature — reachable here even after step 2's own `$SPECS_PATH` check, since that check only rejects an unset value, never an invalid path or a non-git directory.

**Under `--from-brd` the PRD gate does not run, because the PRD is not this route's content source.**
Its purpose here is a *grounding confirmation* on a route whose content comes from the Jira export;
this route's content comes from the BRD folder's `spec-seed.md`, its implementation-altitude
decisions and its verified findings, and the PRD — which may not exist at all, since
`/dev-workflows:create-prd --from-brd` is not a prerequisite for this command — is read by nothing in
this run. Gating an artifact the run does not read would promote an input this route never had into a
prerequisite, which `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §5 rule 3 forbids; and its
`absent` branch reports falling back to a Jira export this route has none of. So the gate is skipped,
not re-pointed, and §3.4's `/specify` row keeps describing the route that runs it. What puts the seed
on the default branch instead is the `/brd-*` family's own handoff discipline: each of those commands
lands its deliverable on the specs default branch and the next refuses to start until it is there, so
a reconciled BRD folder is already merged by the time this route reads it. This mirrors
`/dev-workflows:create-prd --from-brd`, which likewise skips the gate on the input its own seed
replaces.

---

## Phase 1 — Configure

**Rule: Ask, don't guess. This rule is absolute.**

Use `choices` arrays; the last choice in every array MUST be `"Other… (describe)"`.

1. **Feature folder.** Confirm the path resolved in Phase 0:
   ```
   choices: ["Use <feature_folder> (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
   ```
   - Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).

2. **Resume vs fresh** (only if Phase 0 found a `_session.md`). Read it back and summarise which
   stages/questions are already settled:
   ```
   choices: ["Resume — skip settled stages/questions (Recommended)", "Start fresh — discard the prior session", "Cancel", "Other… (describe)"]
   ```
   On resume, Phase 5 begins at the first unsettled stage instead of the header.

3. **Repo refresh policy** (governs Phase 4's `code-scanner` dispatches):
   ```
   choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh", "Other… (describe)"]
   ```
   `fetch + pull default branch` matches `code-scanner`'s own default
   (`refresh.switch_to_default_branch: true, refresh.pull: true`) — grounding wants present-day code,
   the same rationale `/epics` uses.

4. **Repos search base (`$REPOS_PATH`)**. Read `${REPOS_PATH:-/workspace}`. `$REPOS_PATH` may be a
   single directory or a colon-separated list:
   ```
   choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
   ```
   If "different path", validate that at least one directory exists under the given value before
   recording it.

Also display (for user context): resolved feature folder; resolved `jira_export_root`; resolved
`jira_key` (PRD); resolved `focus_key` (Epic, or 'none — PRD-level'); resolved `$REPOS_PATH`; resolved
`$SPECS_PATH`.

**Under `--from-brd`, display instead** a `from BRD:` line naming `<BRD-KEY>` and its resolved folder,
its `parent:` if `brd-link.md` records one, its `depends-on:` if any, and which of `spec-seed.md`,
`decisions.md`, `grounding/code-grounding.md` and `grounding/design-grounding.md` are present — a
stat, not a read; the read is Phase 2. `jira_export_root`, `jira_key` and `focus_key` are all
unresolved on this route and are shown as `none — seeded from a BRD` rather than left blank, so a
reader is not left wondering which resolution ran.

---

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then classify as `SIMPLE` / `MODERATE` / `SIGNIFICANT` / `HIGH-RISK`. Specification authoring is typically **MODERATE**. Resolve per-step routing per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT possible for large/cross-cutting PRDs
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # jira-reader, code-scanner
  review_model:    <§2 Opus chain>     # spec-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + specification.md authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

The grill + authoring run inline on `current_model` (interactive judgment — not a delegated subagent), consistent with the model-routing SSOT. If no Opus is available, `spec-reviewer` falls to the Sonnet floor — record the degradation in `notes` and the final report.

---

## Phase 2 — Read Jira

**Under `--from-brd` this phase reads no Jira at all.** Steps A and B are skipped in their entirety —
no `jira-reader` dispatch, no granularity picker, no `idea.md` write — and the *`--from-brd` — read
the implementation-altitude seed* section at the end of this phase runs in their place. Everything
below Step B that says "the scoped subtree" means, on that route, the seed material that section
carries forward.

Phase 2 reads Jira in **two steps, cheap before expensive**. Step A settles *granularity* — the
input's type and, for a multi-Epic PRD, *which* Epic — with a cheap `prd-plus-epics` read (and, when
needed, the progress-aware picker), resolving `focus_key`. Only then does Step B spend the full-depth
read, now scoped to the resolved Epic. This ordering resolves a null `focus_key` by a cheap
enumeration **before** any expensive full read, so the full read never pulls a whole multi-Epic PRD
subtree the grill would only discard. When `focus_key` is already set on entry, Step A is skipped and
Phase 2 is just the full read (Step B).

### Step A — Resolve granularity + focus Epic (cheap enumeration + picker)

**Skip this step entirely when `focus_key` is already set on entry** — any two-token form
(`<PRD-Key> <Epic-Key>`, `<dir> <Epic-Key>`) or a bare `<Epic-Key>` auto-resolved to its parent PRD in
Phase 0. The Epic is already chosen, so go straight to Step B.

Otherwise (`focus_key` is null), dispatch `jira-reader` at the **cheap** `depth: prd-plus-epics` to
determine the item's type and enumerate its child Epics *without* reading the full Story/Sub-task
subtree:

→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Return the structured handoff for this brief:
  >
  > jira_export_root: [resolved jira_export_root]
  > jira_key:         [resolved jira_key]
  > depth:      prd-plus-epics"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `Jira key dir not found`
rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`). On
`OK`, read the item's type from `value_increment` / `linked_items` and enumerate its **child Epics**
(filter `linked_items` to `type == Epic`). Then branch — this is the reusable **progress-aware
Epic-picker pattern** documented in `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`
(§ Progress-aware Epic picker), applied here with `/specify`'s own done-predicate:

- **Stand-alone top-level Epic** (the item is itself an Epic, no parent PRD) → no picker; the item
  *is* the focus. Set `focus_key` = the item (== `jira_key`). The feature folder stays the flat
  `specifications/<jira_key>-<slug>/` resolved in Phase 0 — a stand-alone Epic has no distinct parent
  PRD, so `<PRD>` == `<EPIC>` and there is no self-nested subfolder (Phase 0 step 3's
  shared-physical-target note). Proceed to Step B.
- **PRD with exactly 1 Epic** → no picker; auto-select it. Set `focus_key` = that Epic and emit a
  one-line notice (e.g. `Single child Epic <EPIC> '<title>' — authoring its spec.`). Re-point the
  feature folder to that Epic's per-Epic subfolder (see *Re-pointing* below). Proceed to Step B.
- **PRD with ≥2 Epics** → render the **progress-aware picker**, one row per child Epic. For each Epic,
  first resolve its **actual** feature folder the same way Phase 0 step 3 does: look under
  `specifications/<PRD>-<vslug>/` for an existing dir matched by that Epic's key-number (tolerate a
  stray `-`/`_` after the key, and a pre-existing slug that doesn't exactly match a freshly-derived
  one), falling back to the freshly-derived `specifications/<PRD>-<vslug>/<EPIC>-<eslug>/` only when no
  such dir exists — this keeps a human-adjusted Epic dir slug from mis-displaying as ○ not-started.
  Compute each Epic's status from `/specify`'s **done-predicate** against that resolved folder:
  - **○ not started** — no `specification.md` and no `_session.md` there → selectable.
  - **◐ in progress** (resume) — a `_session.md` exists there but no `specification.md` → selectable
    as a resume; the per-Epic stage-level resume then runs in Phase 5 from that `_session.md`
    (resume *stacks* on the picker, per the shared pattern).
  - **● done** — `specification.md` exists there → shown greyed, **not** default-selectable;
    selecting it offers *revise*.
  Default cursor = the first actionable row (in-progress before not-started). Render as a `choices`
  array: one entry per Epic (its ○/◐/● marker + key + title), then an explicit
  **"Author one broad PRD-level spec instead"** choice, then `"Other… (describe)"`.
  - On selecting an Epic → set `focus_key` = that Epic; re-point the feature folder to its per-Epic
    subfolder (see *Re-pointing* below).
  - On **"Author one broad PRD-level spec instead"** → leave `focus_key` = null; the feature folder
    stays the flat PRD-dir path `specifications/<PRD>-<vslug>/` (Phase 0 step 3's `focus_key`-null PRD
    case). Step B then reads the whole PRD subtree.
- **PRD with 0 Epics** → this PRD hasn't been split yet. Offer the existing without-Epics choices:
  `choices: ["Split into Epics first with /dev-workflows:epics, then create them in Jira and re-import (Recommended)", "Author one broad PRD-level spec now", "Cancel", "Other… (describe)"]`
  `/specify` does NOT create Jira Epics itself (zero external API) — on "Split…", stop and guide the
  user through the manual round-trip (see the Phase 7 round-trip note). On "Author one broad PRD-level
  spec now", leave `focus_key` = null and proceed to Step B.

**Re-pointing the feature folder after the picker.** When Step A sets `focus_key` to an Epic (the
single-Epic and ≥2-Epic-selection cases), the feature folder becomes that Epic's per-Epic subfolder
`specifications/<PRD>-<vslug>/<EPIC>-<eslug>/` (Phase 0 step 3's `focus_key`-set case), superseding the
provisional PRD-level folder confirmed in Phase 1 — Phase 0 already marks that folder provisional until
`jira-reader` runs. Re-detect a prior run there (a `_session.md` → a resume is available for that
Epic). The stand-alone-Epic and broad-PRD-spec cases leave the Phase 0 folder unchanged.

### Step B — Full Epic-scoped read

With granularity settled and `focus_key` resolved, dispatch `jira-reader` at `depth: full` — richer
than Step A's `prd-plus-epics`, because `/specify` needs the full linked subtree (Stories/Sub-tasks) as
the raw material for user stories, acceptance criteria, and test cases; `prd-plus-epics` would starve
the grill of exactly the detail it needs.

→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Return the structured handoff for this brief:
  >
  > jira_export_root: [resolved jira_export_root]
  > jira_key:         [resolved jira_key]
  > depth:      full"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `Jira key dir not found`
rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`). On
`OK`:

- **Epic-scope the read.** `jira-reader` is dispatched with `jira_key` = the PRD and returns the
  **whole PRD** linked-item hierarchy (`jira-reader` itself is unchanged). When `focus_key` is set,
  **scope the returned hierarchy to `focus_key`'s subtree** — the Epic itself plus its linked
  Stories/Sub-tasks (`linked_items` whose `parent` chain leads to `focus_key`) — filtering
  in-orchestrator and discarding sibling Epics' subtrees before feeding the downstream phases. When
  `focus_key` is null (broad PRD-level spec), use the whole PRD subtree as today. Everything below —
  themes, `idea.md`, the Phase 5 raw material — derives from this scoped `focus_key` subtree.
- Extract **capability themes** and component/product mentions from the scoped subtree — feeds
  Phase 3's repo derivation and Phase 4's `code-scanner` dispatches.
- Write **`idea.md`** in the feature folder from the scoped Jira text (the focus item's summary,
  description, and its linked-item summaries) — pre-spec brainstorming provenance, in the same spirit
  as the `idea.md` convention `source-truth.md` already treats as non-authoritative once
  `specification.md` exists.
- Carry the scoped linked-item tree (the Epic's Stories/Sub-tasks) forward into Phase 5 — the raw
  material the grill mines for user stories, acceptance criteria, and test cases.

### `--from-brd` — read the implementation-altitude seed, the register, and the verified findings

Read the BRD folder Phase 0 step 3 resolved. Read exactly these, and no other seed:

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
  `spec-seed.md`: `/dev-workflows:brd-ground` appends its rows to `<BRD-dir>/grounding/code-grounding.md`
  (that command's Phase 8), classed per `grounding-format.md` §7
  (`EXISTS | DERIVED | NEW-CAPTURE | NEW-CONFIG | PARTNER | DEFERRED | DEPENDENCY`). It is
  implementation-altitude by construction, which is why this command is the one that reads it — and
  an absent matrix is ordinary, since `/dev-workflows:brd-ground` runs it only on a reporting- or
  data-centric BRD or under an explicit `--derivation-matrix`.
- **`brd-link.md`** — for `parent:` and `depends-on:` only. This run reads no `claims:` list and no
  coverage ledger: PRD eligibility and the allocation gate are
  `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5's rule about authoring a **PRD**,
  applied "when eligibility is checked", and a specification is not that artifact. Not checking it
  here is a decision, not an omission — `/dev-workflows:create-prd --from-brd` is where that gate
  lives, and this command is reachable without it.

**Absence is reported, never a stop, and the seed's absence is the ordinary case.** Nothing on the
normal route writes a seed file at all (above), so a reconciled BRD routinely holds none; and a BRD
ground with `--no-design` holds no `design-grounding.md`. Say which of the four were absent — a reader cannot tell an unwritten file from
an unread one — and carry what is there.

**No `idea.md` is written on this route.** Step B writes one as pre-spec provenance derived from the
Jira text; there is no Jira text here, and the BRD folder already holds the provenance this spec was
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
place of the Jira-derived themes.

---

## Phase 2.5 — Resolve applicable ARD (optional)

Resolve any ARD for this item by citing `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with `<PRD>`, `<EPIC>` (`focus_key`), and `$SPECS_PATH`. **Under `--from-brd` the pair comes from `brd-link.md`'s `parent:`, never from a segment count**: with no `parent:` (this BRD owns its source document) pass `prd: <BRD-KEY>`, `epic: null`; with a `parent:` (this BRD is a slice) pass `prd: <parent-key>`, `epic: <BRD-KEY>`. The second mapping needs no change to that reference — a slice folder sits inside its parent's exactly as an Epic subfolder sits inside a PRD dir, the layout its Epic-level branch already collects — and it is the same pair `/dev-workflows:create-ard <BRD-KEY> --from-brd` writes into the ARD's own `prd:`/`epic:` frontmatter, so the two agree by construction rather than by coincidence. On `status: none`, **skip and proceed exactly as before**. On `status: unmerged`, **stop**, naming the returned `branch` and any `pr`. On `status: found`, keep the spec's user stories + scope consistent with the returned `invariants` + `guidance_summary` during the Phase 5 grill; record a necessary deviation under the spec's `### Open questions` (never edit the ARD). Pass the `invariants` to `spec-reviewer` in Phase 6 as `applicable_ard`.

---

## Phase 3 — Derive repos + soft gate

1. **Auto-derive candidate repos.** From the Phase 2 capability themes and any linked PR URLs in the
   `jira-reader` handoff (`pull_requests[].repo`), build a candidate repo-slug list. **Under
   `--from-brd` there is no `jira-reader` handoff and therefore no PR URL; derive the list from
   `<BRD-dir>/grounding/baselines.md` instead**, which already records repository → pinned commit for
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
   choices: ["List repos to scan manually", "Proceed without code scan", "Cancel", "Other… (describe)"]
   ```

2. **Build the slug→clone map** (`/epics`-style). For each top-level directory under each entry of
   `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing
   `.git`, and take the URL's last path segment as that clone's slug. Skip directories with no `.git`
   or whose `git remote` call fails/times out.

3. **Resolve each candidate against the map.** One match → use it. An ambiguous slug (multiple
   matches) or zero matches both escalate per the `Repo unresolved (zero matches) — /epics` rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]
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
  >   [paste the themes array from jira-reader]
  > context: |
  >   [3–5 sentences: the Jira item's goal, what the specification must ground]
  > search_hints:
  >   symbols:  [class/function names inferred from the Jira text, or []]
  >   paths:    [directory globs inferred from themes, or []]
  >   keywords: [grep keywords extracted from themes]
  > refresh:
  >   switch_to_default_branch: [true if Phase 1 chose 'fetch + pull default branch' (default) or 'fetch only'; false if 'no refresh']
  >   pull: [true if 'fetch + pull default branch'; false otherwise]"

**Documentation grounding (optional).** Run `resolve-docs-grounding specify` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the scoped Epic/PRD goal, `jira_key` = the focus key, `themes` = the Phase 2 capability themes. Carry the digest into the Phase 5 grill with **grill-rank** consumption. When OFF, skip silently.

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

**Interview technique (grilling — embedded; no runtime dependency).** Conduct each stage as a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, explore the Phase 4 code scan / Jira content to self-answer (fact-vs-decision), walk the design tree in dependency order, continue to shared understanding then write that stage's section.

Walk the stages in order, authoring `specification.md` live against `${CLAUDE_PLUGIN_ROOT}/references/specification-format.md`, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`:

1. Header + **Problem statement**
2. **Scope** (In/Out)
3. **User stories** (`[Uxx]`)
4. **Acceptance criteria** (`[ACxx]`, EARS)
5. **Test cases** (`[TCxx]`)

As each decision settles, append it to `_session.md`; capture a genuinely-ambiguous term in `_glossary.md`. Resolve open questions to zero where possible; leave genuinely unresolvable ones as `- [ ]` and keep the header **Open questions** count in sync. A repo gap surfacing here → escalate (describe the missing capability + why) and STOP; the run is resumable from `_session.md` after the user remounts and re-invokes.

### `--from-brd` — where the seed lands, and the grill is restricted to gaps

**Where the seed's content lands.** `spec-seed.md` and the implementation-altitude `decided` records
supply the raw material the Jira subtree supplies on the other route: the problem frame and scope
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
     choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in the final report)", "Override and accept the finding", "Cancel the whole run", "Other… (describe)"]
     ```
     "Defer" means appending a `## Refinement notes` section to `specification.md` with a `- [ ]` item
     per deferred finding (mirrors `/epics`' Epic-refinement note), in addition to the final report.
   - **`MAJOR` / `MINOR` / `NIT`** (surfaced under `PASS WITH RECOMMENDATIONS`) — defer to the final
     report; no mandatory fix cycle.
   - **`PASS`** / **`PASS WITH RECOMMENDATIONS`** — proceed to Phase 7.

Cap: one fix cycle + one re-review maximum.

---

## Phase 7 — Handoff

Write the feature folder: `specification.md` (`Published: no`), `idea.md`, `_session.md`, `_glossary.md`, and the rendered `.html`. **Under `--from-brd` there is no `idea.md`** (Phase 2) — the other four are written exactly as above, into the BRD folder.

**Under `--from-brd`, also close the consumption loop before the offer.** The design's *Consumption
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

On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: spec`; `feature_folder` = the Epic subfolder for a **per-Epic** spec (a PRD + focus Epic) or a **stand-alone-Epic** spec (`<EPIC>` = `focus_key`, which for a stand-alone Epic equals `jira_key`), or the PRD dir for a **broad PRD-level** spec (`focus_key` null), or **the BRD folder under `--from-brd`** — Epic keys are globally unique, so the per-Epic form needs no PRD prefix, and both forms use hyphens; §2.2 derives `spec/<EPIC>-<eslug>` or `spec/<PRD>-<vslug>` from that folder, matching today's branch names, and `spec/<BRD-KEY>-<slug>` from a BRD folder (a slice's from its own folder basename) — which collides with neither `/dev-workflows:create-prd --from-brd`'s `prd/` branch on the same key, nor `/dev-workflows:create-ard --from-brd`'s `ard/` one, nor the `/brd-*` family's shared `brd/` one, because §2.2's prefix is the caller's own; `deliverable_paths` = `specification.md`, `_session.md`, `_glossary.md`, and the rendered `.html` — **plus, under `--from-brd`, `decisions.md`, `grounding/code-grounding.md` and `grounding/design-grounding.md`**, because the `consumed_by` writes above land in those three and an uncommitted consumption record is one no later run can read; `spec-seed.md` is not staged, because this run does not write to it; `title: <EPIC|PRD> Add specification`; and `body_facts` = the stage/user-story/AC/TC counts, the open-question count, and the `spec-reviewer` verdict — and, under `--from-brd`, the `<BRD-KEY>` this specification was seeded from and how many items were marked `consumed_by: specification`. **Merged-to-main = ready for the dev-team handover** — Devs and `/design` read the spec from `main`, never from the branch, and `require-on-main` now enforces that rather than merely stating it. Emit its §4.1 outcome line in the Final report.

### Next Epic (after a per-Epic spec from a multi-Epic PRD)

When this run authored a **per-Epic** spec that was selected from Step A's ≥2-Epics picker, offer — once Phase 7's write/commit completes — to continue with a sibling Epic under the same PRD:
```
choices: ["Next Epic — re-open the picker (Recommended)", "Stop here", "Other… (describe)"]
```
On **"Next Epic"**, **re-render the Phase 2 Step A progress-aware picker minus the just-completed Epic** — recompute each remaining Epic's ○/◐/● state from its feature folder, so the freshly-authored spec now shows **● done** and drops out of the actionable set — then, on selection, set `focus_key` to the new Epic and loop back through Phase 2 Step B → Phases 3–7 for it. This offer does **not** apply to a stand-alone Epic, a single-Epic PRD, or a broad PRD-level spec — there is no sibling to advance to. It does not apply **under `--from-brd`** either, and for a stronger reason: Step A never ran, so there is no picker to re-render and no Epic set to subtract from. The sibling that exists on that route is another *slice*, which is a separate BRD with its own folder and its own seed — reached by re-running `/dev-workflows:specify <SIBLING-SLICE-KEY> --from-brd`, which waits on nothing this run produced.

### Jira round-trip (document to the user — they will otherwise miss it)

The end-to-end flow:
1. `/dev-workflows:epics <PRD>` drafts child Epic definitions.
2. **You create those Epics in Jira** (manual — `/specify`/`/epics` never call Jira).
3. **You re-import** the PRD to `$VAULT_PATH/jira-products/<KEY>` so the new Epics appear in the export.
4. `/dev-workflows:specify <each Epic>` reads the Epic from the refreshed export and authors its `specification.md`.

Steps 2–3 are the round-trip; without them `/specify` cannot see the Epics.

**Under `--from-brd` that round-trip is not this route's, and the run needs none of it** — the flow
above starts at `/dev-workflows:epics`, which reads the Jira export, while this route read a BRD
folder and never touched one. Say instead which round-trip is still outstanding, because it is what
the *downstream* commands need: the PRD's own paste-and-re-import, in
`/dev-workflows:create-prd <BRD-KEY> --from-brd`'s handoff phase, is what first gives this work a
tracker identity — a `jira_key` minted by the tracker, distinct from the `<BRD-KEY>` folder name
(`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1). Until it has run there is no key any
Jira-driven command in this plugin could be given for this BRD, which is exactly what the `### Next
step` section below tests before naming one.

## Phase 8 — Session maintenance & feedback

Terminal phase — runs after Phase 7 and before the Final report is presented;
NEVER interrupts an earlier phase. `/specify` has no built-in maintenance agent,
so this phase invokes `impl-maintenance` on the Sonnet detection chain and then
persists the plugin-facing slice of its report as session feedback.

**Capture-at-block invariant.** This terminal phase captures gaps for a *completed* run. Separately, if an EARLIER phase **halts on a plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked), `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating — so a run abandoned at the block still records the gap. NEVER `emit-block` for a work-quality review BLOCK or an environment / user halt (repo/spec gate, jira-not-found, cancellation). **The three `--from-brd` stops are of that second class**: `SPECIFY_NEEDS_KEY`, `SPECIFY_BRD_NOT_FOUND` and `SPECIFY_BRD_NO_EPIC` report the operator's own argument list or BRD tree, not a capability this plugin lacks, so none of them `emit-block`s.

**Session-hygiene invariant.** End the report with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the
`resume.md` write runs later, in the terminal cost phase, per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the
guidance only), then a
span suggestion (PRD-level→`/dev-workflows:epics` `/compact`; Epic-level→`/dev-workflows:design` `/clear`) +
`/rename <PRD-ID>-<slug>-pe`. Guidance only, never auto-run.

**The run's key under `--from-brd`.** Phase 0 resolved a BRD key, which is a folder name and never a
tracker key (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1). The tracker key for this work,
if one exists at all, is the `jira_key` in the PRD this BRD folder holds — glob
`<BRD-dir>/<BRD-KEY>_*.md`, frontmatter `issue_type: ValueIncrement`. So the `jira_key` passed to
`emit-auto` (below) and `emit-cost` (Phase 9) is that minted key when the folder holds a PRD carrying
one, and `null` otherwise (`source: none` either way); `commit-artifacts` resolves its own key the
same way and commits under `NOISSUE` when there is none, per
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4 step 4. The `<BRD-KEY>` is never passed as a
`jira_key` — a folder key in a tracker-key field is the confusion the two fields exist to keep apart.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /specify
   > - What was done: [one-paragraph summary of the specification authored]
   > - Key events: [BLOCK reviews and their reason, unmounted-repo soft-gate advisories, unresolved open questions, picker / round-trip friction — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: [the spec-reviewer verdict — PASS | PASS WITH RECOMMENDATIONS | BLOCK]
   > - Test result: N/A (no tests in /specify)
   > - Project root: [the resolved feature folder under $SPECS_PATH]"
2. **Persist plugin feedback (automatic).** Project the report's plugin-facing
   slice into the specs repo by citing
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
   `emit-auto` entry point (§6). Pass the Lessons Learned report,
   `command: /specify`, the run's `jira_key` and `source`, and `plugin_version`
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
the run's `jira_key` (or `null`) and `source`, and `plugin_version` (read from
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
NEVER touches a code repo, a docs repo, the vault, or the current working
directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the
run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its
§6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git
for the deliverable is offered only in Phase 7; the terminal step above commits
only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes
into a docs/code repo or the current working directory; no user name is ever
written (§10 privacy).

## Final report

Report: feature-folder path; stage/user-story/AC/TC counts; open-question count; unmounted-repo advisories; the `spec-reviewer` verdict; the `Phase handoff:` outcome line from `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1); the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; and a reminder of the round-trip described above + that `Published: yes` is a human-only freeze step.

**Under `--from-brd`, additionally:** the `<BRD-KEY>` seeded from and its resolved folder; whether this
run was BRD-level or slice-level and, for a slice, the `parent:` key and the `(prd, epic)` pair Phase
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
was not, that no Jira export resolved for `<BRD-KEY>`.

### Next step

End the report with a `### Next step` recommendation per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` (guidance only — never auto-invoked): **Epic-level spec** (`<PRD> <Epic>`) → hand to Dev → `/dev-workflows:design <PRD> <Epic>` `<merge-clause>`, which will not start until this spec is on the default branch — on every path, since `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3.4's `/design` row is a stop even for a spec that reached no branch — and the **Epic fan-out** `/dev-workflows:specify <PRD> <another-Epic>` for a sibling Epic (breadth), which waits on nothing this run produced and carries no clause; **PRD-level spec** (`<PRD>` only) → `/dev-workflows:epics <PRD>` (PE) `<merge-clause>`, which stops rather than skipping wherever this spec reached a branch (§3.3 rows D/E) and skips exactly as it did before wherever it reached none (§3.4's `/epics` row). If the run BLOCKED or left open `- [ ]` items, recommend resolving those first.

**Under `--from-brd` neither branch above applies, because the key this run holds is a BRD key.**
`/dev-workflows:design` and `/dev-workflows:epics` are both jira-driven: each classifies its key
through `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`, which resolves
`$VAULT_PATH/jira-products/<KEY>` and fires Fallback B when that directory is missing. A `<BRD-KEY>`
is a folder name under `$SPECS_PATH` that was never checked against a tracker
(`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1), so naming either command with one is an
offer that cannot start. Test before naming:

- **Name `/dev-workflows:design <BRD-KEY>` `<merge-clause>` only when
  `$VAULT_PATH/jira-products/<BRD-KEY>/<BRD-KEY>-index.md` exists.** That one test settles both halves
  of reachability. It settles the key half directly — it is exactly what `jira-input-resolution.md`'s
  JiraID resolution requires — and it settles the folder half because `/dev-workflows:design` resolves
  its own directory from the same key through `specifications/` plus `addressing.md` §7's
  one-level-deep fallback, which reaches this BRD folder at either level. So the two resolutions land
  on the same place precisely when the BRD was keyed with the tracker's own key — which
  `/dev-workflows:brd-split` lets an operator do when it proposes the slice key, since a segment count
  is a naming convention and never a depth declaration (§1). Its Phase 0 step 4 then takes the
  "holds a flat `specification.md`" branch for this folder — the BRD key resolves no focus Epic, and a
  BRD folder holding a spec is exactly that case — and step 3's gate re-applies against it, which is
  the wait `<merge-clause>` states.
- **Where the export does not resolve, name no command and say why.** The PRD's paste-and-re-import
  round-trip — in `/dev-workflows:create-prd <BRD-KEY> --from-brd`'s handoff phase — is what mints a
  tracker key and creates the export at all. Say also that a *minted key different from the BRD key*
  does not make `/dev-workflows:design` reachable for this spec: under that key it resolves a
  different `specifications/` folder and reports this specification absent. Per the *When no option is
  safe to recommend* guidance in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`, nothing in
  that state is marked `(Recommended)`.
- **`/dev-workflows:epics` is not offered on this route either way.** It splits a PRD into Epic drafts
  and is upstream of this command, not downstream of it; and under a minted key it would resolve a
  different PRD directory, where this run's `specification.md` is not present — so the silent skip its
  row F takes would leave the offer stating a wait that is not real.

`<merge-clause>` is the placeholder `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` owns, resolved from this run's own `Phase handoff:` outcome line (§4.1) and never written as the unconditional "once the pull request above is merged" — a declined handoff, a failed push and a nothing-to-commit run each leave a different wait, and two of them open no pull request to wait on.

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 9), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:

- **PRD-level spec → `/dev-workflows:epics <PRD>` (still PE)?** → run **`/compact`** — context still relevant.
- **Epic-level spec → Dev `/dev-workflows:design <PRD> <Epic>` (even yourself)?** → run **`/clear`** for a clean slate.
- **`--from-brd`?** → run **`/clear`**. The two lines above name commands this route's key cannot reach (`### Next step`), so neither describes the span that follows: whatever comes next starts from a merged artifact and a key this session does not hold, which is the clean-slate case.
- Consider **`/rename <PRD-ID>-<slug>-pe`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
