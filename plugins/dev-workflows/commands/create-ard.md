---
name: create-ard
description: Architecture-authoring workflow (Product Architect phase, sub-project 3 of the PRD-creation flow). Grounds on the mounted implementation repos (architect-driven discovery — no PRs) and authors an ARD for a PRD (/create-ard <PRD-KEY>) or an Epic (/create-ard <PRD-KEY> <Epic-KEY>, inheriting the PRD-level ARD), against references/ard-format.md, gated by the Opus ard-reviewer, written to $SPECS_PATH/specifications/<KEY>-<slug>/. Optional; scoped; product-architecture level (no code writing). Introduces the pa role.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Author an Architecture Requirements/Decision Document for the Jira item: $ARGUMENTS

`/create-ard` is **sub-project 3 of the PRD-creation flow** — the **Product Architect (PA)** phase. It
grounds on the mounted implementation repos and authors an **ARD** that establishes the architecture
invariants the downstream (`/specify`, `/design`, `/implement`) will later inherit. The ARD is
**optional** (a simple PRD may not need one) and **scoped** via the two-key grammar:

- `/create-ard <PRD-KEY>` → a **PRD-level** ARD.
- `/create-ard <PRD-KEY> <Epic-KEY>` → an **Epic-level** ARD (inherits the PRD-level ARD read-only).

It authors architecture only — no code writing; grounding is **architect-driven** (there are no PRs at
this stage). Zero Jira API.

---

## Phase 0 — Resolve input
1. **Resolve the Jira input** via `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against `$ARGUMENTS` → `jira_key` (the PRD), `focus_key` (the Epic, or `null`), `jira_export_root`, `source`. Define `<PRD>` = `jira_key`, `<EPIC>` = `focus_key`.
2. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
3. **Feature folder.** PRD-level → `specifications/<PRD>-<vslug>/`; Epic-level → `specifications/<PRD>-<vslug>/<EPIC>-<eslug>/`. Honor an existing dir matched by key-number (tolerate `-`/`_` drift). Auto-created on first write.
4. **Prior ARD.** If the target `*_ARD.md` exists → Phase 1 offers refine-vs-fresh.
5. **Optionality advisory.** Gauge size — the PRD's user-story count / scope breadth / number of candidate repos. For a small, single-repo PRD, note "an ARD may be optional here" and offer `choices: ["Author the ARD anyway", "Stop — no ARD needed", "Other… (describe)"]`.

`/create-ard` is **cwd-agnostic**; it reads the PRD/Epic and scans repos under `$REPOS_PATH`.

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it.

**Gate the PRD.** Execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against the PRD file in `specifications/<PRD>-<vslug>/` — **resolve its actual name on the ref first**: `git -C "$SPECS_PATH" ls-tree --name-only "origin/<default>" "specifications/<PRD>-<vslug>/"` filtered to `<PRD>_*.md`, falling back to the derived `<PRD>_<vslug>.md` only when that listing is empty. A human-adjusted slug is a supported state — `/create-prd` and this command's own Phase 2 reader both locate the PRD by glob plus frontmatter, and the feature folder is matched by key-number for the same reason — so gating an exact derived filename would report `absent` for a PRD that is present, and would let a slug-drifted file on a plugin branch escape the rows D/E stop entirely. Map its §3.7 return value by `stopped` first, never by `on_main` alone. Any stopping state → stop per §4.4. Otherwise (`stopped: false`): on `pass`/`pass_amending`, read the authored PRD in Phase 2 as today; on `absent`, the existing `jira-reader` fallback applies — but report it: *"No authored PRD on `<default>` for `<PRD>` — architecting from the Jira export at `<path>`. If a PRD exists on a branch, this run would have stopped; it does not, so none does."*; on `unmanaged`, behave exactly as before this feature — reachable here even after step 2's own `$SPECS_PATH` check, since that check only rejects an unset value, never an invalid path or a non-git directory.

---

## Phase 1 — Configure
Use `choices` arrays; the last choice is always `"Other… (describe)"`.
1. **Confirm** the scope (PRD-level vs Epic-level) and the feature folder.
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
Read the PRD from `$SPECS_PATH/specifications/<PRD>-<vslug>/` — glob `<PRD>_*.md` and use the file whose frontmatter is `issue_type: ValueIncrement` (canonical `<PRD>_<slug>.md`) when present (authored source); else dispatch `jira-reader` to read it from the export:

→ Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Return the structured handoff for this brief:
  >
  > jira_export_root: [resolved jira_export_root]
  > jira_key:         [<PRD> for a PRD-level run, <EPIC> for an Epic-level run]
  > depth:      prd-only (PRD-level) | full (Epic-level, scoped to focus_key)"

For an **Epic-level** run always dispatch `jira-reader` this way (`depth: full`, scoped to `focus_key`) for the Epic's scope — the authored-PRD-file check above only applies PRD-level. Resolve any PRD-level ARD via `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` (`prd: <PRD>`, `epic: null`, `$SPECS_PATH`). On `status: found`, load its `AD#N` invariants to **inherit read-only**. On `status: unmerged`, **stop**, naming the returned `branch` and any `pr`. On `status: none`, proceed unchanged — there is no PRD-level ARD to inherit.

Extract the problem/goal/scope frame + capability themes — the raw material for grounding + the grill.

---

## Phase 3 — Architect-driven grounding (no PRs)
There are no PRs at ARD time, so repos are **architect-driven**, not PR-derived:
1. **Cheap discovery.** List the top-level directories under each `$REPOS_PATH` entry (`ls`). Optionally attach each dir's one-line identity — `timeout 5 git -C <dir> remote get-url origin 2>/dev/null` (slug) or its README first heading. Do **not** deep-scan to guess relevance.
2. **Propose + ask.** From the PRD/Epic themes, propose a `theme → repo` mapping against those dirs, and **ask the architect to confirm / correct / add**. For any requirement that maps to no obvious repo, **ask outright**: "which repo covers `<X>`?"
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
Write the ARD file(s) into the feature folder. Then **offer** (commit-when-asked — never automatic), presenting `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim: `choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]`. On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: ard`; `feature_folder` as resolved in Phase 0 (the PRD dir for a PRD-level ARD, the Epic subfolder for an Epic-level ARD — §2.2 derives `ard/<PRD>-<vslug>` or `ard/<EPIC>-<eslug>` from it, matching today's branch names); `deliverable_paths` = the ARD file(s); `title: <PRD|EPIC> Add architecture requirements document`; and `body_facts` = the ARD scope (PRD/Epic, any per-area split), the grounded/descoped repos, the `AD#N` count, the open-question count, and the `ard-reviewer` verdict. Emit its §4.1 outcome line in the Final report.

---

## Phase 7 — Next-step offer (adaptive)
- **PRD-level ARD:** if the PRD has 0 Epics → `choices: ["Hand to a Product Engineer — /dev-workflows:epics <PRD> (then create them in Jira + re-import) (PE) (Recommended) <merge-clause>", "Author a PRD-level spec — /dev-workflows:specify <PRD> (PE) <merge-clause>", "Stop here", "Other… (describe)"]`; else offer `/dev-workflows:specify <PRD>` (PE) carrying the same `<merge-clause>`. *(No `/design` — no Epics yet.)*
- **Epic-level ARD:** `choices: ["Author the spec — /dev-workflows:specify <PRD> <Epic> (PE) (Recommended) <merge-clause>", "Hand to Dev — /dev-workflows:design <PRD> <Epic> (Dev) <merge-clause>", "Stop here", "Other… (describe)"]`. **Epic fan-out** — repeat this ARD for a sibling Epic: `/dev-workflows:create-ard <PRD> <another-Epic>`; that run inherits the PRD-level ARD, not this Epic-level one, so it waits on nothing this run produced and carries no clause.

**Every merge clause above is the `<merge-clause>` placeholder**, resolved from this run's own `Phase handoff:` outcome line per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`, and never the unconditional "once the pull request above is merged": a declined handoff, a failed push and a nothing-to-commit run each leave a different wait, and two of them open no pull request to wait on. It is a placeholder, not an instruction to reword an option, so the arrays are still presented verbatim per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. **The wait it names is real for every command named above**, and it is a stop, not a silent degradation: `/dev-workflows:epics`, `/dev-workflows:specify` and `/dev-workflows:design` each read this ARD through `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` and each stops on `status: unmerged`, naming the branch and any open pull request. Only a handoff that reached no branch at all resolves `status: none`, where that reference's no-regression rule has the run proceed exactly as it would with no ARD.

Guidance only — never auto-invokes another command. Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`.

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 8), per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. The next step hands off from PA
to PE/Dev, so:

- **Handing to PE (`/dev-workflows:epics <PRD>` / `/dev-workflows:specify <PRD> <Epic>`) or Dev (`/dev-workflows:design <PRD> <Epic>`), even yourself?** → run **`/clear`** for a clean slate; the ARD is on disk.
- Continuing to draft more ARD areas yourself right now? → **`/compact`** is fine.
- Consider **`/rename <PRD-ID>-<slug>-pa`** so you can find this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.

---

## Phase 8 — Session maintenance, feedback & cost
Terminal phase — runs after Phase 7, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference gap**, `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment / user halt (unset `$SPECS_PATH`, missing key, no-ARD-needed, unmounted-repo descope, cancellation) or a review BLOCK.

**Session-hygiene invariant.** End Phase 7 with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the
`resume.md` write runs later, in the terminal cost phase, per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the
guidance only), then a
PA→PE/Dev handoff suggestion (`/clear`) + `/rename <PRD-ID>-<slug>-pa`. Guidance only, never auto-run.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/create-ard`; what was authored (ARD scope + grounded repos); key events (grounding gaps/descopes, BLOCK reviews — or 'none'); workarounds; the `ard-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6) with the report, `command: /create-ard`, the run's `jira_key`, `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its `emit-cost` entry point with `command: /create-ard`, `phase: architecture`, `role: pa`, the run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite `<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the pointer reflects the completed run, and before the commit step below, so it is included in it. Redact per §1. Silent; the printed `### Context hygiene` guidance already appeared in the report.
5. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session artifacts (/create-ard)` with no `Co-Authored-By` trailer, and pushes to the branch this run's handoff phase created (§4.1). It NEVER touches a code repo, a docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is offered only in Phase 6; the terminal step above commits only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report
Report: the ARD path(s) + scope (PRD/Epic, any per-area split); the grounded repos + any descoped/ungrounded ones; `AD#N` count; open-question count; the `ard-reviewer` verdict; the `Phase handoff:` outcome line from `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1); resolved model routing (+ any Opus gate/degradation); the feedback + cost paths; the `Specs repo:` outcome line from `commit-artifacts` (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; and the adaptive next-step recommendation.
