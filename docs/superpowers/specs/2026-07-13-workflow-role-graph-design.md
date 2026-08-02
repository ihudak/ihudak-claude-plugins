---
tags:
  - tasks-exclude
---

# Workflow role-graph — design

**Date:** 2026-07-13
**Task:** AI-First.md line 96, priority `[2]` — "Make a graph of the implementation and documentation workflows with the roles (PM/PE/Dev/QA) for the steps and input/output artifacts (files, jira imports, jira rotation, sources of truth). Highlight the workflow starting commands for each role. Highlight the outcomes from each role."
**Repo:** `/workspace/ihudak-claude-plugins` (documentation + a `/specify` role-label consistency fix; **no runtime behavior change**; ships as dev-workflows **v2.27.0**).
**Also folds in two recorded stale-doc follow-ups:** `plugins/dev-workflows/README.md` line 3 ("Twelve workflow slash commands"), and the retired `/impl:*` colon-taxonomy in the repo-root `CLAUDE.md`.

## Context (from exploration)

- The plugin ships **20 commands**. `CLAUDE.md` line 30 correctly says "twenty slash commands"; `README.md` line 3 still says "Twelve workflow slash commands" (stale, enumerates 13 workflow types).
- Two role/workflow SSOTs already exist, both prose-arrow (no diagram):
  - `references/next-phase-offer.md` (78 lines) — role-aware routing graph, role headers `PM — ideation & framing`, `PA — architecture (optional)`, `PE — breakdown & specification`, `Team/Dev — build`, plus a `## Not pipeline nodes` list (`/vuln`, `/upgrade`, `/feedback`, `/prompt*`, `/docs-profile`, `/statusline`, reviewer commands).
  - `references/workflow-states.md` (45 lines) — Jira-status → owning-role → transition-command → expected-artifacts tables (VI ladder + Epic ladder). Declares "Jira is the source of truth for status; this reference NEVER stores status."
- **No mermaid/dot/ASCII diagram of the PM→…→Team pipeline exists anywhere.** The only formal diagram in the doc set is the `/implement` mermaid `flowchart TD` in `README.md` (fence L110–191).
- The plugin's real role vocabulary is **PM / PA / PE / Team** — there is no QA role and no standalone "Dev" (it is "Team/Dev").
- The retired `/impl:*` colon-taxonomy in the repo-root `CLAUDE.md` is spread across ~L100–202 (model-routing reference, source-truth reference, the `## dev-workflows workflow relationships` diagram at L110–136, and the per-command invariants blocks). L119 of the diagram also names a non-existent `dt-doc-fixer` agent.

**Two documented role inconsistencies:**
1. `/specify` — frontmatter + README L20 label it "PM phase", but `next-phase-offer.md` and `workflow-states.md` file it under **PE**. **Resolved in this effort: both `/specify <VI>` and `/specify <VI> <Epic>` are PE**; the legacy "(PM phase)" label is corrected in the command, the README table, and `workflow-states.md` (see change surface D). No legend caveat.
2. `/release-notes` — PM for an early bare-VI draft, Dev once spec/design exist (`cost-emission.md` infers this). Shown in **both** lanes (legend note retained — it genuinely serves two moments).

## Decisions (locked)

- **Roles (superset):** PM / PA / PE / **Dev** / **QA**. Keep PA; rename the plugin's "Team" lane to **Dev** for familiarity; add an explicit **QA** lane anchored on `/ready` plus the embedded Opus reviewer gates. A legend note maps Dev≈Team and explains QA = verification, not a role that authors artifacts.
- **Home & form:** a new `## Workflow overview` section in `plugins/dev-workflows/README.md` with a **mermaid `flowchart`** (consistent with the existing `/implement` flowchart) + a compact annotation table. `next-phase-offer.md` and `workflow-states.md` remain the authoritative edge SSOTs the diagram visualizes — the README graph is a visualization, not a competing SSOT.
- **`/release-notes` in both lanes:** PM (early draft from the VI) and Dev (final, grounded in merged PR diffs) — two distinct mermaid nodes labeled accordingly.
- **Cross-cutting commands are first-class:** all 20 commands appear in the overview. The non-pipeline commands get an "Anytime" lane + a prose subsection, with `/feedback` and `/prompt*` framed as the plugin's improvement loop ("please use these").
- **Plugin-generated artifacts are documented and normalized:** the overview states where feedback / cost / follow-up files land in `$SPECS_PATH` and that committing them with the specs is expected and encouraged.
- **`/specify` role:** both `/specify <VI>` and `/specify <VI> <Epic>` = **PE**. The legacy "(PM phase)" label is corrected in the command, the README table, and `workflow-states.md` so nothing contradicts (change surface D). The specification is the Product Engineer's breakdown artifact at either scope; `next-phase-offer.md` already treats even the VI-level `/specify` as a PE hand-off.
- **Versioning:** because this edits a command file (`specify.md`) and a runtime-consumed reference (`workflow-states.md`, which feeds `/ready`), the effort carries a **minor version bump to v2.27.0**, lock-stepped across `plugins/dev-workflows/plugin.json` + the `marketplace.json` dev-workflows entry (line 12) + a `CHANGELOG.md` entry. The README/CLAUDE.md graph + de-stale work rides along in the same release. Counts stay 20 commands / 30 agents; manifest description count-strings stay **byte-identical** (no command added/removed); siblings (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched.

## Change surface

### A. `plugins/dev-workflows/README.md` — new `## Workflow overview` section

Inserted after the `## Commands` block (with its two prose notes at L23/L25) and before `## Session feedback` (L35). Contents:

1. **A mermaid `flowchart TD`** with one subgraph per role lane:
   - **PM — ideation & framing:** `/idea` → `/create-vi <KEY>` → `/release-notes <VI>` *(early draft)*.
   - **PA — architecture (optional):** `/create-ard <VI> [<Epic>]`.
   - **PE — breakdown & specification:** `/epics <VI>`; `/specify <VI> [<Epic>]`.
   - **Dev — build:** `/design <VI> <Epic>` → `/implement <VI> <Epic>` → `/document <VI>` → `/release-notes <VI>` *(final)*.
   - **QA — verification & gates:** `/ready <VI|Epic>` (with a note that every authoring/build command embeds an Opus reviewer gate — the automated QA layer).
   - **Anytime — improve the plugin & utilities:** `/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me` (+ a dashed edge indicating "from any command"); `/vuln`, `/upgrade`; `/statusline`, `/docs-profile`, `/api-guideline-reviewer`, `/guideline-reviewer`.
   - Cross-lane edges from `next-phase-offer.md`: `/create-vi` → PA (`/create-ard`) or PE (`/epics`/`/specify`); `/create-ard` → PE; `/epics` → `/specify`; `/specify` → Dev (`/design`); `/ready` verifies the Dev artifacts (dashed).
   - `/release-notes` appears as two nodes (`relnotes_pm` "early draft", `relnotes_dev` "final") so the same command's two moments are unambiguous.

2. **An annotation table** — `Role · Starts with · Consumes · Produces / outcome (where it lands)`:
   - **PM** · `/idea`, `/create-vi <KEY>`, `/release-notes <VI>` · prompt / community post / RFE; refined `idea.md` + JIRA-KEY · `<KEY>_ValueIncrement.md` in `$SPECS_PATH/specifications/<KEY>-<slug>/` (idea.md relocated in); early release-notes draft in the vault; paste-to-Jira → re-import to `$VAULT_PATH/jira-products/<KEY>/`.
   - **PA** (optional) · `/create-ard <VI> [<Epic>]` · the VI (+ Epic) · `<VI>_ARD.md` / `<EPIC>-<area>_ARD.md` in the same specs folder.
   - **PE** · `/epics <VI>`, `/specify <VI> [<Epic>]` · VI (+ ARD, existing Epics) · Epic drafts in `$VAULT_PATH/jira-drafts/<VI-KEY>/`; `specification.md` on specs-repo main (branch+PR).
   - **Dev** · `/design <VI> <Epic>`, `/implement <VI> <Epic>`, `/document <VI>`, `/release-notes <VI>` · specification.md (+ ARD), design.md, code repos · `design.md` on specs-repo main; code + PR in `$REPOS_PATH`; product docs in the docs repo; final release-notes draft in the vault.
   - **QA** · `/ready <VI|Epic>` (+ embedded Opus reviewer gates) · Jira status + the ARD/spec/design artifacts · `SUPPORTED / PARTIAL / NOT-SUPPORTED` verdict (read-only; sets no status).

3. **A "Sources of truth & artifact homes" note:**
   - **Jira** = source of truth for workflow *status*; imported by the external `jira-workitem-import` tool into `$VAULT_PATH/jira-products/<KEY>/`. The plugin never sets status.
   - **`$SPECS_PATH/specifications/<KEY>-<slug>/`** = shared, team-visible home for VI / ARD / specification / design.
   - **`$VAULT_PATH`** = personal store: `Projects/<area>/<slug>/idea.md`, the imported `jira-products/` tree, `jira-drafts/<VI-KEY>/` Epic drafts, release-notes drafts.
   - **`$REPOS_PATH`** = code clones (implement branches/PRs); the external **docs repo** = product documentation.
   - **Plugin-generated artifacts in the specs repo** (so nobody is surprised): written under `<VI-dir>/dev-workflows/` in `$SPECS_PATH` — `<KEY>-feedback.md`, `cost/<sid8>.md`, `<KEY>-followups.md`. **Committing and pushing these alongside the specs is expected and encouraged** — team-visible feedback and cost transparency is the point.

4. **A "Cross-cutting commands (any time)" prose subsection:**
   - **Plugin improvement — please use these:** `/feedback` logs a note about the plugin; `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me` turn a correction into logged feedback + a fix. "This is how the plugin keeps getting better — run them whenever something felt off."
   - **Standalone maintenance:** `/vuln`, `/upgrade`.
   - **Setup / repo tooling:** `/statusline`, `/docs-profile`, `/api-guideline-reviewer`, `/guideline-reviewer`.

5. **Legend notes:** Dev≈the plugin's "Team" lane; QA = verification/gates, not an authoring role; `/release-notes` serves PM (early) and Dev (final). (`/specify` is simply PE — resolved in D, no caveat.)

### B. `plugins/dev-workflows/README.md` line 3 — fix the count

Replace `Twelve workflow slash commands for …` with an accurate **"Twenty slash commands …"** lead covering the current surface (idea refinement, VI authoring, architecture, Epic drafting, specification, engineering design, readiness gating, structured implementation, one-shot doc edits, docs-repo profiling, Jira-driven feature documentation, release-notes drafting, vulnerability remediation, dependency upgrades — plus API/UI guideline reviewers and feedback/prompt/statusline utilities), keeping the existing tail about Opus-backed risk planning / code review / test regression / style + doc review gates. Exact wording pinned in the plan.

### C. Repo-root `CLAUDE.md` (~L100–202) — de-stale the `/impl:*` taxonomy

Apply one authoritative rename map everywhere the retired taxonomy appears (the workflow-relationships diagram L110–136, the model-routing / source-truth reference lines, and the per-command invariants blocks):

| Retired | Current |
|---|---|
| `/impl:code`, `/impl` | `/implement` |
| `/impl:docs` (one-shot doc edits) | `/document` (direct mode) |
| `/impl:jira:docs` | `/document` (Jira mode) |
| `/impl:docs:profile` | `/docs-profile` |
| `/impl:jira:epics` | `/epics` |
| `/impl:jira:release-notes` | `/release-notes` |

Also remove the reference to the non-existent `dt-doc-fixer` agent (diagram L119) and keep the helper-agent "used by …" relationships accurate to the renamed commands. The plan Reads the full L87–227 block first so every change is an exact old→new string that preserves each invariant's meaning — only command names change.

### D. `/specify` role reconciliation (→ PE)

Make `/specify` consistently PE everywhere; a label correction only, no behavior/step change.

- `plugins/dev-workflows/commands/specify.md` — frontmatter `description:` "(PM phase)" → "(PE phase)". Then grep the whole file for any other "PM phase" / PM-role framing (phase headers, prose) and correct it to PE. Do NOT touch any workflow step, gate, or output.
- `plugins/dev-workflows/README.md` command-table row for `/specify` (~L20) — "(PM phase)" → "(PE phase)".
- `plugins/dev-workflows/references/workflow-states.md` — L15: move the optional `/specify <VI>` mention out of the PM ("Use cases defined") row so PE owns `/specify` at both levels; `/create-vi` stays the PM transition command for that row. The "Ready for Implementation | PE→Team | /epics, /specify, /design" row is unchanged.
- `plugins/dev-workflows/references/next-phase-offer.md` — already files `/specify` under PE; verify no stray "(PM …)" tag on a `/specify` edge, fix only if found.
- Grep the rest of `references/` (e.g. `cost-emission.md`, `source-truth.md`) for any hard-coded `/specify` = PM tag; correct only if found.

### E. Version bump to v2.27.0

- `plugins/dev-workflows/plugin.json` — `version` → `2.27.0`.
- `marketplace.json` — the dev-workflows entry (line 12) `version` → `2.27.0`. Siblings' entries (lines 24 / 36) untouched.
- `plugins/dev-workflows/CHANGELOG.md` — new `## 2.27.0` entry: workflow-overview graph in the README, corrected "Twenty" command count, `/impl:*` de-stale in the repo-root `CLAUDE.md`, and the `/specify` → PE role-consistency fix.

## Non-goals

- No new command/agent; no change to any command's runtime steps/behavior (the `/specify` edit is a role-label correction only).
- Not rewriting `next-phase-offer.md`'s or `workflow-states.md`'s structure — only the single `/specify` role placement is corrected; they stay the authoritative edge SSOTs the README graph visualizes.
- Not touching any `CLAUDE.md` content beyond the stale `/impl:*` taxonomy.
- Sibling plugins (`dt-style-guide`, `obsidian-llm-wiki`) untouched; manifest description count-strings byte-identical.

## Verification (structural — no test framework)

- README `## Workflow overview` exists between `## Commands` and `## Session feedback`; the mermaid fence is balanced (opening ```` ```mermaid ````/closing ```` ``` ````), parses as a `flowchart`, and every command node in the diagram also appears in the annotation table (and vice-versa).
- Every one of the 20 commands is named somewhere in the overview (pipeline lanes + Anytime subsection).
- The feedback / cost / follow-up artifact paths and the "expected and encouraged to commit" statement are present.
- README no longer contains the token `Twelve`; the new lead says "Twenty".
- `CLAUDE.md` contains **zero** `/impl:` colon-taxonomy tokens (`grep -c '/impl:' CLAUDE.md == 0`) and zero `dt-doc-fixer`; the workflow-relationships diagram uses only the current flat command names; the surrounding invariants prose is internally consistent.
- **`/specify` is PE everywhere:** `grep -rn 'PM phase' plugins/dev-workflows/commands/specify.md` returns nothing; the README `/specify` row and `workflow-states.md` both present `/specify` as PE; no reference tags `/specify` as PM.
- **Version:** `plugins/dev-workflows/plugin.json` and the `marketplace.json` dev-workflows entry both read `2.27.0`; siblings stay `0.2.2` / `0.3.1`; both manifests parse (`python3 -c json.load`); manifest description count-strings byte-identical to before; a `## 2.27.0` CHANGELOG entry exists.
- Changed files are exactly: `plugins/dev-workflows/README.md`, repo-root `CLAUDE.md`, `plugins/dev-workflows/commands/specify.md`, `plugins/dev-workflows/references/workflow-states.md`, `plugins/dev-workflows/plugin.json`, `marketplace.json`, `plugins/dev-workflows/CHANGELOG.md` (+ `references/next-phase-offer.md` only if a stray `/specify` PM tag is found). Everything else — other `commands/`, `agents/`, other `references/`, `scripts/`, and both sibling plugins — is 0-line diff.
- Any markdown links introduced resolve to existing files.

## Risks

- **Low-to-moderate.** Documentation only. The main risk is factual drift — a role placement, artifact path, or command name in the graph contradicting the source references, or the CLAUDE.md rewrite mangling an invariant's meaning. Mitigated by: sourcing every edge from `next-phase-offer.md` / `workflow-states.md`; sourcing every path from the exploration; the mermaid↔table consistency check; and Reading the full CLAUDE.md block so each de-stale edit is an exact, meaning-preserving string swap. The CLAUDE.md pass is the highest-risk task and gets its own review.
