---
name: epics
description: keyed Epic-writing workflow. Reads a Product Requirements Document and existing Epics from exported markdown, optionally scans code repos, drafts child Epic definitions, and gates on prose-style-checker and Opus epic-reviewer.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Draft child Epics for the resolved Product Requirements Document: $ARGUMENTS

`/epics` is the **keyed Epic-writing** workflow. Given a Product Requirements Document key, it reads the PRD plus its existing Epics from pre-exported markdown in the user's Obsidian vault, optionally scans code repos to identify reusable capabilities and gaps, drafts child Epic definitions as markdown files under the resolved output directory, and gates the result on an Opus review.

Key distinction from `/document` (keyed mode): the PRD being Epic-ized is **not yet implemented** — there are no PRs to diff. Code scanning (when enabled) is a plain filesystem search to understand what exists and what needs to be built.

`/epics` **never branches** and **never commits the Epic drafts** (still true — the run's git **writes** are confined to `$SPECS_PATH`, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`; the run does make read-only git calls elsewhere — Phase 4's `git remote get-url origin` per candidate clone and Phase 8's `git diff --stat` from `project_root` — but none of them writes), and writes only inside the resolved PRD folder — one `EPIC-<PRD-KEY>-NN-<eslug>/` per Epic, plus `_coverage.md` beside `prd.md`. Git hygiene of the write target is the user's responsibility — they may or may not have it under version control. The run commits only inside `$SPECS_PATH`, and only its bounded session-artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1) — via the `specs-preflight` flush at run start (§3.4) and the terminal `commit-artifacts` step (§4); never the drafts, never the write target. It still creates no branch (still true — `specs-preflight` switches `$SPECS_PATH` only between branches that already exist, and only plugin-created ones (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.2); it creates none).

---

## Phase 0 — Load

1. **Resolve the address.** Parse the **single positional address** from `$ARGUMENTS` — a `<KEY>`, or an
   `@<path>` naming a folder or a file inside one — and resolve it with
   `resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3).
   `status: found` → carry its `path`, `kind` and `key` forward; `absent` → the
   folder does not exist and there is nothing to partition; `ambiguous` → stop,
   naming every match and `@<path>` as the way through.

   `/epics` is **address-required**: with no positional address, stop with
   `EPICS_NEEDS_KEY: /epics needs a PRD or Epic address — a key, or an @<path> to its folder.` —
   `/epics` has no direct-prompt behavior. Downstream, `<PRD-KEY>` denotes the
   resolved folder's own `key` (`addressing.md` §4), read from its frontmatter
   and never parsed out of its directory name.

`/epics` is **cwd-agnostic**: it writes Epic drafts to an absolute output
directory (resolved in Phase 1), so it does **not** require cwd to be inside the
vault.

**Specs-repo preflight.** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`specs-preflight` entry point (§3) inline: flush any leftover session
artifacts from an earlier run, retry an artifact commit that failed to push,
and settle the branch. Prompt-free and silent when the specs repo is clean and
on its default branch. If a guard fires, emit its §5 notice; if it returns
`specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the
terminal `commit-artifacts` step skips on it.

---

## Phase 1 — Clarification

**Rule: Ask, don't guess. This rule is absolute.**

Group questions where possible; use `choices` arrays; the last choice in every array MUST be `"Other… (describe)"`.

Ask about:

- **Where Epics land — derived, not asked.** Each confirmed Epic gets its own folder under the
  resolved PRD folder: `EPIC-<PRD-KEY>-NN-<eslug>/`, holding `epic.md`. There is one home now, so
  there is no output-directory question and no `output_dir` to record.

  **Mint the key** as `<PRD-KEY>-NN` — the next unused two-digit segment under this PRD, skipping any
  an existing `EPIC-` folder already uses. Propose it, let the operator override, and validate
  whatever is used with `key-valid` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1); an invalid
  key is **re-prompted, never silently coerced**. This is `commands/brd-split.md` Phase 3 step 1's
  mechanism, reused rather than restated.

  **`_coverage.md` is PRD-holistic and belongs to no single Epic**, so it lands in the **PRD folder**,
  beside `prd.md` — not in any `EPIC-` folder. Putting it in one would make it look like that Epic's
  coverage, which is the opposite of what it reports.


- **Code examination on/off** (default ON). If ON, ask which repos under `$REPOS_PATH` to scan:
  ```
  choices: ["Scan repos referenced by sibling/parent Epics under this PRD (Recommended — auto-derived)", "Let me list the repos manually (you'll be prompted)", "Turn code scan off — produce Epic drafts from PRD content alone", "Other… (describe)"]
  ```
  When "auto-derived" is chosen, inspect the sibling/parent Epics' `## Pull Requests` sections (if any) for repo references; if none, fall back to asking the user to list repos.

- **Repo refresh policy** (only if code scan is ON):
  ```
  choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh", "Other… (describe)"]
  ```
  The `fetch + pull default branch` default matches `code-scanner`'s default (`refresh.switch_to_default_branch: true, refresh.pull: true`) — capability scans target present-day code and want the default-branch tip. This is deliberately different from `/document` (keyed mode), which keeps `pull: false` because historical merged commits must not move.

- **Repos search base (`$REPOS_PATH`)** (only if code scan is ON). Read `${REPOS_PATH:-/workspace}` (the container mounts every repo under `/workspace`). `$REPOS_PATH` may be a single directory or a colon-separated list. Ask:
  ```
  choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  If "different path", take free-text input (single dir or colon-separated list) and validate that at least one directory exists under it. Record the resolved value as `$REPOS_PATH`. Individual clones are located in Phase 4 by matching their `git remote` against each repo slug — not by assuming a `<base>/<slug>` directory name.

Also display (for user context):
- Resolved cwd absolute path
- Resolved output directory
- Resolved `$REPOS_PATH` (or "N/A — code scan off")
- Resolved `prd_dir` and `key` (plus `$VAULT_PATH` when set)

No branching context is shown — this command never branches (still true — `specs-preflight` only switches `$SPECS_PATH` between branches that already exist, and only ones the plugin created, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.2; it creates none).

---

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the classification rules, then classify the task as exactly one of: `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or `HIGH-RISK`. Epic writing is typically **MODERATE** (bounded scope, single PRD, vault-internal output). State the classification and a one-sentence reason.

MODERATE → no separate Opus planner; the `epic-reviewer` gate (Opus, frontmatter-pinned) is mandatory. Resolve the per-step routing per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT possible
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # the folder read, code-scanner, prose-style-checker, doc-fixer, epic-writer (MODERATE)
  review_model:    <§2 Opus chain>     # epic-reviewer (frontmatter-pinned; recorded, no override)
  implementation_model: <= detection_model>   # the epic-writer subagent (Phase 6); planning_model if SIGNIFICANT/HIGH-RISK
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

Each subagent dispatch below cites its chain (§9 role→chain map). **No relaunch advisory** for MODERATE — the writer runs on its detection pin and the gates run on `current_model`, which §3.1 allows (if a run is classified SIGNIFICANT/HIGH-RISK, the §9.1 advisory applies and `epic-writer` escalates to the §2 chain). If no Opus is available, `epic-reviewer` falls to the Sonnet floor — record the degradation in `notes` and the Phase 9 report.

---

## Phase 2 — Plan + approval

**Documentation grounding (optional, independent of code scan).** Before presenting the plan below, run `resolve-docs-grounding epics` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` — this is the run's only consent-bearing step (an index build or a capped refresh), so it must resolve here, before Phase 3's the folder read, Phase 4's repo resolution, and Phase 5's parallel code scan do any of the run's real work. This runs ahead of Phase 2.5/2.6's `require-on-main`/`ard-resolution.md` gates — a deliberate exception to `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §5 rule 2's ordering, kept here rather than moved because `resolve-docs-grounding`'s only expensive step is itself behind its own consent prompt (`docs-grounding.md` step 3.5), and an index build it produces is a durable, run-independent artifact, not per-run work a later stop would waste.

Present a concise plan:

- Resolved `key` and the `prd_dir` path
- Existing Epics identified under this PRD (will NOT be duplicated)
- Repos to scan (or "code scan off")
- Docs grounding: the `docs grounding:` line that `resolve-docs-grounding` returned, verbatim — including its `retrieval:` value and any index-build, staleness, or shadowing clause (off switch: --no-docs)
- Output directory with one file per new Epic; propose a name stub per Epic if the themes already suggest them
- Parallelism plan (up to 4 `code-scanner` instances per batch, single Agent message per batch)
- Proposed Epic sizing/sequencing — prefer fewer, larger Epics where the PRD direction is validated; split only at a genuine risk / feedback-loop boundary; order so that no Epic depends on a later one
- **Wide-refactor exception** — a blast-radius-wide *mechanical* change (rename/retype a shared symbol, column, or type) that genuinely cannot be tracer-bulleted into independent vertical slices is sequenced **expand → migrate-in-batches → contract**: one Epic adds the new form alongside the old, one-or-more Epics migrate call sites in batches, and a final Epic removes the old form (blocked by every migrate-batch). Prefer this over forcing the change into an awkward vertical slice

Ask:
```
"Epic drafting plan ready. What would you like to do?"
choices: ["Approve & continue (Recommended)", "Revise plan", "Cancel"]
```

- **Approve** → proceed to Phase 3
- **Revise** → ask what to change, update, re-show, re-ask
- **Cancel** → stop and summarise what was planned

---

## Phase 2.5 — Resolve applicable ARD (optional)

Resolve any PRD-level ARD for this PRD by citing
`${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with `prd = key`,
**`epic: null`** (Epics do not exist yet — PRD-level ARD only), and `$SPECS_PATH`.

- On `status: none` (including `$SPECS_PATH` unset/unresolvable) → **skip and
  proceed exactly as before.** No prompt, no extra output.
- On `status: unmerged` → **stop**, naming the returned `branch` and any `pr` — an ARD that exists but has not landed on `<default>` is a weaker architectural basis than the one about to arrive, and Epics drafted against it would need re-doing once it does.
- On `status: found` → carry `invariants` + `guidance_summary` forward: pass them
  to `epic-writer` (Phase 6 handoff, as `applicable_ard`) so drafts stay
  consistent with the `AD#N`, and to `epic-reviewer` (Phase 7, as `applicable_ard`)
  which then activates its ARD-conformance dimension. A necessary deviation is
  recorded by the writer in the Epic draft (`- ARD deviation: … flag: architect`)
  and surfaced in the Phase 9 report — never edit the ARD.

---

## Phase 2.6 — PRD-level spec enrichment (optional)

If a PRD-level specification exists, fold its requirements into the coverage
inventory. **Additive, zero-cost when absent** — the common case, since
`/specify` usually runs per-Epic *after* `/epics`.

1. **Resolve the PRD dir:** call `resolve-address <PRD>` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md`
   §3), which searches every level §3 bounds and carries §5's legacy fallback. `status: found` →
   use its `path`; `status: absent` → none exists; `status: ambiguous` → stop, naming every match
   and `@<path>` as the way through. No matching rule is written here: a second copy of the one §5
   states is the drift §1 warns about. If `$SPECS_PATH` is
   unset/unresolvable, or no PRD dir matches at either level → **skip** (set
   `vi_spec_present: false`) — the skip a PRD with no nested folder takes today,
   unchanged.
2. **Detect:** execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against `<PRD-dir>/specification.md`, mapping its §3.7 return value by `stopped` first, never by `on_main` alone. On any stopping state, stop per §4.4, naming `$SPECS_PATH` explicitly — a spec that exists but has not yet landed on `<default>` is a weaker grounding basis than the one about to arrive, and Epics drafted against it would need re-doing. Otherwise (`stopped: false`): on `pass`/`pass_amending`, proceed to step 3 (`pass_amending` prints §3.3's row-B message). On `unmanaged`, behave exactly as before this feature — **skip** (set `vi_spec_present: false`). On `absent`, **skip** (set `vi_spec_present: false`); the run proceeds byte-identically to today — this is the common case, and PRD-level `/specify` remains optional.
3. **Parse** `<PRD-dir>/specification.md` directly (Read it — one file, a simple
   heading scan): extract its user stories `[Uxx]` and their nested acceptance
   criteria `[ACxx]` into `vi_spec_requirements[]`. **Skip `[TCxx]` test cases**
   (per-AC, non-unique, below Epic granularity) and the prose sections
   (Problem/Scope). Because `[ACxx]` numbering restarts per story, qualify each
   `spec-criterion` id with its parent story (`<Uxx>/<ACxx>`) so every `Req` id
   in `_coverage.md` is unique; `spec-story` `[Uxx]` ids are document-unique and
   used as-is:

   ```yaml
   vi_spec_requirements:
     - id:   <Uxx (story) | <parent-Uxx>/<ACxx> (criterion)>   # spec-story id is document-unique; qualify criterion ids with the parent story
       type: spec-story | spec-criterion
       text: <requirement text>
   ```

   Set `vi_spec_present: true` and record the resolved `specification.md` path
   for the Phase 9 report.

---

## Phase 3 — Read the PRD folder

Invoke the folder read with `depth: prd-plus-epics`. This depth is specifically designed for Epic writing: richer than `prd-only` so themes extracted for `code-scanner` aren't starved of context, but lighter than `full` so the agent doesn't read dozens of already-closed child Stories.

**Read the PRD folder directly.** Read its `prd.md` for the product content, and list the `EPIC-`
subfolders under it for the Epics that already exist — that listing *is* the linked-item hierarchy
the retired reader used to return. Each Epic folder's `key` and title come from its own frontmatter
(`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §4), never from its directory name.
  >
  > prd_dir: [resolved prd_dir]
  > key:         [resolved key]
  > depth:      prd-plus-epics"

Wait for the handoff. If `status: NOT_FOUND` or `status: EMPTY`, surface the `key dir not found` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`["Re-enter key", "Cancel"]`). On `OK`, carry the handoff `requirements[]` and `requirements_source` forward —
they are the coverage ground truth for Phases 6–7.

When Phase 2.6 set `vi_spec_present: true`, **append** its
`vi_spec_requirements[]` to this `requirements[]` — the PRD's own rows are
unchanged; the appended rows carry `type: spec-story` / `spec-criterion`, which
separates them from the PRD's `story`/`criterion` rows. The merged list flows
unchanged into the Phase 6 handoff and the Phase 7 reviewer brief. When
`vi_spec_present: false`, `requirements[]` is exactly what the folder read returned.

Identify the Epics that already exist — the `EPIC-` folders directly under the resolved PRD folder, each read for its `epic.md` — the new Epic drafts MUST NOT duplicate their scope (enforced later by `epic-reviewer`).

**What refine means now, because it changed.** Refine used to fill in *empty Epics somebody else had created in a tracker* — shells that existed so that linking one to a PRD would surface the PRD on that team's dashboard. That was an artefact of one organisation's tooling and has no analogue here: nothing creates an empty Epic. **Refine now means iterating on an Epic that exists** — re-grounding it, sharpening it after the specification moved, or splitting it. Do not read the phases below as though they were still filling in a shell.

**Refinement target (`focus_key`).** `/epics` always reads and analyses the whole PRD
(the partition and non-duplication logic are inherently PRD-holistic). When `focus_key`
is set (explicit `<PRD> <Epic>`), validate it is among the linked Epics; if it is not,
surface `EPICS_FOCUS_NOT_FOUND: <focus_key> is not a linked Epic of <KEY>.` and
offer `choices: ["Proceed PRD-level (draft the full partition)", "Re-enter the Epic key", "Cancel"]`.
When present, treat `focus_key` as the **single refinement target**: Phase 6 re-drafts
only that Epic's definition, and Phase 7 reviews only that file. The non-duplication
set (`existing_epics`) is the *other* linked Epics — exclude the focus Epic so Phase 6
re-emits it rather than skipping it as a duplicate. When `focus_key` is null, behaviour
is unchanged (draft the full partition of new Epics).
When `focus_key` is set, `mode = refine` and `refinement_targets = [the focus Epic]` — Phase 6 iterates on its current imported content (see `epic-writer` refinement mode) rather than regenerating from the PRD alone.

**Refinement candidates.** From those same `EPIC-` folders, read each `epic.md`'s `refinement_candidate`, `team`, and `scope_hint` (emitted by the folder read at `prd-plus-epics`). Collect `refinement_candidates` = every linked Epic with `refinement_candidate: true`. These are empty/almost-empty team-Epic shells the PE pre-created to encode team boundaries — refinement *targets to fill in*, not non-duplication constraints. This set drives the Phase 3.5 gate.

---

## Phase 3.5 — Refinement-mode gate (conditional)

Runs only when `focus_key` is set OR `refinement_candidates` is non-empty. Otherwise skip silently — `mode = generate`, behaviour byte-identical to the legacy net-new flow.

**Focus key set** → `mode = refine`, `refinement_targets = [focus Epic]`; skip the mode question (the PE named the target explicitly).

**No focus key, `refinement_candidates` non-empty** → present the detected set as a CONFIRMABLE list (detection only *proposes*; the PE is the authority) and ask the mode:
```
Detected N empty/almost-empty team-Epic shells linked to <KEY>:
  - <EPIC-KEY> · <team, or "team: [NEEDS CLARIFICATION]"> · <scope_hint>
  ...
choices: ["Refine these N (partition the PRD across them) (Recommended)", "Generate net-new Epics (ignore the shells)", "Both — refine the shells and draft net-new for leftover scope", "Let me adjust which shells to refine (you'll be prompted)", "Other… (describe)"]
```
Record `mode` (`refine` | `generate` | `both`) and the confirmed `refinement_targets` (empty for `generate`). A target whose `team` is empty carries a `[NEEDS CLARIFICATION — team]` note into the writer handoff.

**Adaptive code-scan default (refine / both only).** Re-surface the code-examination choice now that the target count is known — the Phase 1 answer was given before detection. Default **ON when `len(refinement_targets) >= 2`** (a real cross-team boundary to draw), **OFF when == 1**:
```
choices: ["<adaptive default> (Recommended)", "<the other setting>", "Keep my Phase 1 choice", "Other… (describe)"]
```
with a one-line rationale ("2+ team-Epics → code context helps draw the boundary" / "single Epic → no cross-team boundary; scan off is faster"). This runs ONLY in the refine branch, so the generate / no-candidate path never sees it (no-regression).

---

## Phase 3.6 — Documentation grounding dispatch

**Documentation grounding dispatch (optional, independent of code scan).** `docs_grounding` was already resolved in Phase 2 — consume that cached result here; never re-run `resolve-docs-grounding`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the PRD goal + Epic-set intent, `key` = the PRD key, `themes` = the folder read themes. Carry the digest into Phase 6 with **writer-attach** consumption. When OFF, skip silently.

This phase sits **before** the conditional repo-resolution and code-scanning phases deliberately. It needs only Phase 3's output — the PRD goal and the folder read themes — and nothing from the code scan, and Phase 4 and Phase 5 both skip to Phase 6 when code scan is OFF. Dispatching from inside either of them would discard the digest on exactly the runs that turned code scanning off, after Phase 2 had already asked the user to consent to building an index for it.

---

## Phase 4 — Resolve repos (conditional)

If code scan is OFF, skip to Phase 6.

If code scan is ON:

1. Derive the repo list:
   - **Auto-derived** (Phase 1 default) — walk the `EPIC-` folders under the PRD folder; for each `epic.md` (already read during Phase 3), collect repo names from its `## Pull Requests` section URLs. Dedupe. If the auto-derived list is empty, fall back to asking the user.
   - **Manual list** — prompt for a free-text list of repo short names (one per line or space-separated). Resolve each against the `$REPOS_PATH` slug→clone map built in step 2 below.

2. Build a slug→clone map. For each top-level directory under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as that clone's slug. Skip directories with no `.git` or whose `git remote` call fails/times out. Resolve each in-scope repo slug against the map: one match → use it; multiple matches → auto-prefer basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last (show candidates at plan approval); zero matches → escalate per the `Repo unresolved (zero matches) — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]
   ```

3. If the final resolved repo list is empty (every repo was skipped or missing), escalate per the `No repos derivable — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["List repos to scan manually", "Proceed without code scan", "Cancel", "Other… (describe)"]
   ```

---

## Phase 5 — Parallel code scanning (conditional)

If code scan is OFF, skip to Phase 6.

Spawn `code-scanner` instances in **batches of up to 4 concurrent agents** per Agent message. Wait for each batch before spawning the next.

For each repo in the batch:

→ Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Scan this repo for the brief:
  >
  > repo_path:     <resolved absolute path for this repo from Phase 4>
  > repo_url_slug: <repo slug, e.g. "cluster">
  > capability_themes:
  >   [paste the themes array from the folder read, plus any PRD-goal-derived themes]
  > context: |
  >   [3–5 sentences: PRD goal, what the Epic-set is meant to achieve]
  > search_hints:
  >   symbols:  [class/function names inferred from PRD/Epic descriptions, or []]
  >   paths:    [directory globs inferred from themes, or []]
  >   keywords: [grep keywords extracted from themes]
  > refresh:
  >   switch_to_default_branch: [true if Phase 1 chose 'fetch + pull default branch' (default) or 'fetch only'; false if 'no refresh']
  >   pull: [true if 'fetch + pull default branch'; false otherwise]"

Handle per-repo status after the batch returns:

- `OK` / `PARTIAL` / `EMPTY` — store the output, continue.
- `REPO_MISSING` — should not happen at this stage (Phase 4 already checked). If it does, escalate per the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
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

## Phase 6 — Write Epics

The drafting is delegated to the **`epic-writer`** subagent (pinned to the §2.1 Sonnet detection chain for MODERATE; §2 Opus only if the run is SIGNIFICANT/HIGH-RISK — see `classification.md` §9.2). The orchestrator prepares a handoff and dispatches; it does not write Epics itself, and **nothing commits in this phase** (still true — `/epics` never branches, and the Epic drafts it writes are never committed; git hygiene of the write target is the user's responsibility. The run commits only inside `$SPECS_PATH`, and only its bounded session-artifact paths, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).

1. **Write the handoff file.** Create a temp file (`mktemp` — never the vault, never a repo) containing the `epic-writer` input contract: `folder_read`, `code_scanner_outputs` (empty if no scan), `scope` (Phase 2 in/out of scope), `existing_epics` (non-duplication), `output_dir` (resolved Phase 1 dir), `vi_goal`, `key`, `requirements` + `requirements_source` (from Phase 3), `applicable_ard` (the Phase 2.5 invariants + guidance_summary, or omit when status was none), `existing_epic_themes` (themes of the already-linked Epics), `mode` (`generate` | `refine` | `both` — from Phase 3.5; `generate` when 3.5 skipped), `refinement_targets` (list of `{key, team, scope_hint, current_body_path}`, where `current_body_path = <prd_dir>/<EPIC-KEY>/<EPIC-KEY>.md`; empty in `generate` mode), and `docs_grounding` (the Phase 3.6 digest, or omit when OFF/EMPTY). Record its absolute path. When `focus_key` is set (the Phase 3 refinement target), set `scope` in-scope to just the focus Epic and `existing_epics` to the *other* linked Epics, so `epic-writer` re-drafts the single focus Epic's definition file; `output_dir` is unchanged.

2. **Dispatch the writer:**

→ Agent (subagent_type: "dev-workflows:epic-writer", model: `<detection_model — §9 / §2.1 Sonnet chain; planning_model (§2 Opus) only if classification is SIGNIFICANT/HIGH-RISK>`):
  > "Write the child Epic definitions for this brief.
  >
  > handoff_file: [absolute path of the temp handoff file from step 1]"

3. **Handle the return.** `status: DONE` → record `files_written` for Phase 6.1 onward. `status: BLOCKED` → surface the named gap:
   ```
   choices: ["Provide the missing input (you'll be prompted)", "Cancel"]
   ```
   On a provided value, rewrite the handoff and re-dispatch once. Nothing is committed here (still true — this step writes only Epic drafts into the vault / output directory, which `commit-artifacts` never stages; git management there is the user's responsibility).

   Also record `coverage_file` (the `_coverage.md` path) and `clarifications_needed[]` for Phases 6.1 and 7.

---

## Phase 6.1 — Resolve clarifications

If the writer returned a non-empty `clarifications_needed[]`, resolve it BEFORE
the style check and review (so no review cycle is spent on known unknowns).
Present ONE batched prompt listing every marker grouped by Epic; for each:
```
choices: ["Use the writer's suggested answer", "I'll answer (you'll be prompted)", "Leave unresolved", "Other… (describe)"]
```
Fold each resolved answer into the affected Epic draft (Edit the file inline, or
re-dispatch `epic-writer` once with the resolutions). Markers the user chooses to
**leave unresolved** stay visible in the draft and become `epic-reviewer`
BLOCKERs in Phase 7. If `clarifications_needed[]` is empty, this phase is a
**silent no-op** (byte-identical to a run without it).

**Leftover disposition (refine / both only).** After the writer returns, read `_coverage.md`; every `❌ gap` row is a PRD requirement no team-Epic covers. In ONE batched prompt, ask per gap:
```
choices: ["Assign to team-Epic <KEY> (re-drafts that Epic to include it)", "Propose as a new (net-new, slug-named) Epic", "Defer (leave as an uncovered row)", "Other… (describe)"]
```
Fold the results back: *assign* → re-dispatch `epic-writer` once (or Edit inline) to add the requirement to the named target's `## Covers` + scope; *new Epic* → add a slug-named net-new draft; *defer* → the row stays `❌ gap` in `_coverage.md` and is listed in the Phase 9 report. Reuses the same batched-gate pattern as the clarification resolution above; no gaps → silent no-op.

---

## Phase 6.2 — Prose style check

Invoke `prose-style-checker` on the files written in Phase 6. Unlike `/document` (keyed mode), this does NOT use `docs-style-checker` (no repo linter for vault content). Instead, the prose style checker validates terminology, trademarks, voice/tone, and inclusive language.

→ Agent (subagent_type: "prose-style:prose-style-checker", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Run the style check for this brief:
  >
  > files:    [absolute paths of every Epic file written in Phase 6]
  > doc_type: epic
  > emphasis: terminology and customer-facing captions, labels, messages, and text"

Act on the return:

- **`status: OK`** — zero violations. Proceed to Phase 7.
- **`status: VIOLATIONS_FOUND`** — invoke `doc-fixer` with the violations treated as per their severity. After `doc-fixer` completes, re-run `prose-style-checker` once:

  → Agent (subagent_type: "dev-workflows:doc-fixer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
    > "Fix the style violations for this brief:
    >
    > Task description: [Epic drafting for <KEY>]
    > Reviewer or style-checker output: [paste full prose-style-checker output]
    > Project root: [resolved project_root]
    > Severities to fix: MAJOR only"

  If violations remain after the re-run, proceed to Phase 7 — the remaining findings (mostly MINOR/NIT for epics) are informational and will appear in the Phase 9 report.

- **`status: ERROR`** — surface the error reason. Proceed to Phase 7 regardless (style check is not a gate for Epics, but a quality enhancement).

If `prose-style-checker` is unavailable (agent file not found), proceed directly to Phase 7. The style check is optional but recommended.

---

## Phase 6.3 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against each drafted Epic file: the **Universal checks**,
the **key-collision** check (run on the whole Epic file — the template has no frontmatter), and
the **Epic** block (required headings incl. `## Independent Test`; Given/When/Then acceptance
criteria; `[NEEDS CLARIFICATION]` ≤ 3 per Epic; `_coverage.md` present). Surface every finding;
inline-fix the mechanical ones (delete a stray placeholder token); leave content gaps for the author.
**Advisory** — never blocks; proceed to Phase 7 once findings are surfaced. `epic-reviewer` remains the
gate.

## Phase 7 — Epic review gate

Invoke `epic-reviewer` (Opus). This reviewer is Epic-specific — scope clarity, acceptance-criteria testability, non-duplication of existing Epics. `docs-style-checker` is NOT used here (no repo linter for vault content); Prose style is handled by the Phase 6.2 `prose-style-checker` step above.

→ Agent (subagent_type: "dev-workflows:epic-reviewer"):
  > "Review the Epic drafts for this brief:
  >
  > Task description: [one-paragraph: PRD key, PRD goal, number of Epics drafted]
  > Written Epic file paths: [absolute paths of every Epic file written in Phase 6]
  > the folder read handoff: [paste full YAML from Phase 3]
  > code-scanner output:  [paste array of per-repo scanner outputs from Phase 5, or 'N/A — code scan off']
  > requirements:        [paste the requirements[] array from Phase 3]
  > _coverage.md path:    [absolute path of the coverage file from Phase 6]
  > applicable_ard:       [the Phase 2.5 invariants, or omit if status was none]"

When `mode` is `refine`/`both`, include `refinement_targets` in the `epic-reviewer` brief so its conditional refinement dimensions (completeness, partition integrity, cross-team dependency sanity, team preserved) activate; omit it in `generate` mode so those dimensions report N/A.

Act on the verdict (same shape as `/document` keyed mode Phase 7):

**Triage sub-step** (before any fixer dispatch): follow `${CLAUDE_PLUGIN_ROOT}/references/finding-triage.md`. For each finding, verify its claimed consequence at the location it names; keep or dismiss; record every dismissal with a reason that disposes of that finding's own claim. Hand the fixer **survivors only**, and carry the dismissal list into this run's report.

- **BLOCK** — invoke `doc-fixer` with `Severities to fix: BLOCKER and MAJOR`. Write the `doc-fixer` Fix Report to a temp file (`mktemp -t dw-epics-claims-XXXX.md`, never inside a repo tree or the vault), record its path as `claims_file`, then **check `doc-fixer`'s `Stop condition flag` before re-invoking anything**. If it is `NEEDS HUMAN`, the fixer deferred at least one BLOCKER as needing a human decision: do NOT re-invoke `epic-reviewer` — a re-review can only re-find the BLOCKER the fixer has just reported it could not resolve — and instead surface each deferred BLOCKER with the reason the fixer gave, then escalate it individually per the `Review verdict BLOCK (unresolved after one fix cycle) — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`, which names this entry point alongside the second-BLOCK one. Only when the flag is `CLEAR` do you re-invoke `epic-reviewer` once **passing `claims_file`** — so the re-review falsifies the fixer's account rather than assuming it. If still BLOCK, escalate per the `Review verdict BLOCK (unresolved after one fix cycle) — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` for each unresolved BLOCKER individually:
  ```
  choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run", "Other… (describe)"]
  ```
  For `/epics`, "Defer" means the finding goes into an Epic-refinement note in the draft itself (appended as a `## Refinement notes` section) in addition to the Phase 9 report.

- **PASS WITH RECOMMENDATIONS** — invoke `doc-fixer` for MAJOR findings only:

  → Agent (subagent_type: "dev-workflows:doc-fixer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
    > "Fix the review findings for this brief:
    >
    > Task description: [Epic drafting for <KEY>]
    > Reviewer or style-checker output: [paste the triaged survivor list from the triage sub-step above — the surviving `epic-reviewer` findings only, never the dismissed ones]
    > Project root: [resolved project_root]
    > Severities to fix: BLOCKER and MAJOR"

  MINOR / NIT findings are deferred to the Phase 9 report.

- **PASS** — proceed to Phase 8.

Cap: one fix cycle + one re-review maximum.

---

## Phase 8 — Post-write maintenance

First gather the change context:

a. `project_root` (the vault when `$VAULT_PATH` is set, else the resolved PRD folder) is the "project root" for this run. Run `git diff --stat` from `project_root` if it is a git repo; otherwise list the written files manually. This command never commits anything under `project_root` — just report what changed (the terminal `commit-artifacts` step commits ONLY `$SPECS_PATH`'s bounded artifact paths, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
b. Compose a **change summary block**:

```
Implementation: [one-sentence description: how many Epics drafted for <KEY>, resolved output directory]
Change type: docs
Classification: MODERATE
Files changed:
<list of new Epic file paths, one per line>
Notable additions/removals: [new Epics by slug — one line each]
(In `refine`/`both` mode, refined Epics are identified by key `<EPIC-KEY>`, not slug.)
Epic-review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK]
```

Then spawn all four maintenance agents in a **single Agent message**. They are independent and run concurrently.

**Agent 1 — Documentation** (general-purpose):
> "Post-write documentation review. Change summary:
> [paste change summary block]
>
> The project root is an Obsidian vault when `$VAULT_PATH` is set, else the resolved PRD folder; look only for internal documentation files that reference the Epics (e.g., an index page enumerating them).
> Determine if any such file needs updating — e.g., a new entry in a drafts index.
> Skip if: no such file exists or drafts aren't indexed centrally.
> If an update is warranted: apply minimal edits.
> Return: file updated and what changed, OR 'no update required (reason)'."

**Agent 2 — Knowledge base** (general-purpose):
> "Post-write knowledge review. Change summary:
> [paste change summary block]
>
> Check ~/.claude/memory/ (global) and .claude/memory/ (project-level, preferred for vault-specific knowledge) for existing knowledge files.
> Determine if a new knowledge entry is warranted — look for: reusable insights about this PRD-family's Epic patterns, non-obvious scoping constraints uncovered, code-reuse discoveries from code-scanner, duplicate-Epic near-misses that required scope adjustment.
> If YES: append to the most appropriate existing file (never create a new file if an existing one fits) using this format:
> ### [Short title]
> - **Context**: what problem/situation triggered this
> - **Insight**: the learned rule, pattern, or gotcha
> - **When it applies**: conditions under which this matters
> - **Date**: YYYY-MM-DD
> - **Ref**: [first 60 chars of the key + PRD summary]
> Return: file updated/created and summary of entry, OR 'no update required'."

**Agent 3 — Instructions** (general-purpose):
> "Post-write instructions review. Change summary:
> [paste change summary block]
>
> Check CLAUDE.md in the project root and ~/.claude/CLAUDE.md (global).
> Determine if any Epic-drafting rules, guidance, or guardrails are missing because of what this run revealed (e.g., a domain-specific acceptance-criteria pattern, a naming convention for Epic files, a scope-boundary rule that caught you out).
> Skip if: the run followed existing conventions with no surprises.
> If YES: apply minimal, additive, scoped changes only.
> Return: what was changed and why, OR 'no update required'."

**Agent 4 — Session maintenance** (dev-workflows:impl-maintenance):
> "Analyse this session and return a Lessons Learned report.
>
> Session handoff:
> - Command run: /epics
> - What was done: [one-paragraph summary of Epics drafted]
> - Key events: [BLOCK reviews and their reason, DIRTY_TREE / REFRESH_BLOCKED scanner statuses, duplicate-Epic near-misses, missing repos, user override decisions — or 'none']
> - Workarounds used: [manual steps not automated by the workflow — or 'none']
> - Review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK]
> - Test result: N/A (no tests in /epics)
> - Project root: [resolved project_root]"

Collect all four summaries for the Phase 9 report.

**Persist plugin feedback (automatic).** After Agent 4 (`impl-maintenance`)
returns, project its plugin-facing slice into the specs repo by citing
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
`emit-auto` entry point (§6). Pass Agent 4's Lessons Learned report,
`command: /epics`, the run's `key` and `source`, and `plugin_version`
(read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto`
renders only the report's **Command workflow improvements**, **New agents /
skills**, and plugin **Reference docs** sections plus the **Key observations**
that triggered them (§4 plugin-facing predicate) — never target-project
`CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id`
(§3), resolves the target via the §2 specs-first ladder, and writes silently.
List the persisted path (or "no plugin-facing signal — nothing persisted") in
the Phase 9 report's Session learnings line. ADDITIVE — the impl-maintenance
report still appears in the report; this step NEVER fails the run, NEVER
commits (still true — this step only writes the feedback file; those writes
are committed by the terminal `commit-artifacts` step in Phase 11, per
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and NEVER writes
into the current working directory.

---

## Phase 9 — Final Report

Output a structured report — do NOT ask any closing confirmation:

**When `mode` is `refine`/`both`,** begin the report with a `Mode: <refine | both>` line and split the written-Epics listing into three labelled groups: **Refined** (keyed `<EPIC-KEY>.md`), **Net-new** (slug-named), and **Deferred** (PRD requirements left uncovered via the Phase 6.1 leftover gate). In `generate` mode the report is unchanged.

```
## keyed Epic Drafting Report

### Classification
MODERATE — vault-internal Epic drafting for a single PRD

### Model Routing
- Session model (current_model): [model]
- epic-writer (implementation_model): [model] — detection (MODERATE) | reasoning (SIGNIFICANT)
- Detection steps — the folder read, code-scanner, prose-style-checker, doc-fixer (detection_model): [model]
- epic-reviewer (review_model): [model]
- Opus available: [yes | no]

### PRD summary
- Key: <KEY>
- Summary: [PRD summary, 1 line]
- Goal: [2–3 sentence extraction from the folder read]

### Existing Epics (not duplicated)
- [<KEY>] [summary] — [status]
- ...
- _or_ "none"

### New Epics written
- [absolute path] — [1-line Epic summary]
- ...

### Repos scanned
- <repo-1> (<resolved repo_path>) — [status: OK | PARTIAL | EMPTY | DIRTY_TREE | REFRESH_BLOCKED; N themes classified present, M partial, K absent, E error]
- ...
- _or_ "N/A — code scan off"

### Epic review verdict
[PASS | PASS WITH RECOMMENDATIONS | BLOCK] — [1-line summary of findings applied / deferred]

### Review triage
- **Review triage:** [N findings reviewed, M survived] — dismissals: [one line per dismissal, `finding — reason`; or "none"]

### Requirement coverage
[Roll-up verdict + N/M covered (P%); list each ❌ gap requirement ID; _coverage.md path] If Phase 2.6 enriched the inventory, also name the PRD-level `specification.md` path and the count of `spec-*` rows added. — _or_ "derived (coarse) — PRD had no structured requirements"

### Clarifications
[Resolved: <n>; Deferred (left unresolved → became blockers): <n>] — _or_ "none raised"

### ARD conformance
[verdict + any `- ARD deviation:` lines recorded] — _omit this whole section when Phase 2.5 status was none_

### Prose style check (Phase 6.2)
[OK | VIOLATIONS_FOUND (N fixed, M remaining) | ERROR (reason) | SKIPPED (prose-style-checker unavailable)] — [1-line summary]

### Documentation (Agent 1)
- [file updated] — [what was added/changed] OR "no update required (reason)"

### Knowledge base (Agent 2)
- [file updated/created] — [summary of entry] OR "no update required"

### Instructions (Agent 3)
- [summary of change] OR "no update required"

### Session learnings (Agent 4)
- [top suggestions from impl-maintenance agent, or "no suggestions — routine session"]

### Deferred items
[MINOR / NIT findings that were not applied, OR epic-reviewer BLOCK findings that were overridden / deferred with the ## Refinement notes section appended — one line each; or "none"]

### Assumptions & limitations
- [list any]

### Git state
The project root has uncommitted changes. `/epics` never commits the project root — git management there is your responsibility. (This run's `$SPECS_PATH` session artifacts are committed separately by the terminal step — see its outcome line at the end of the run.)

### Next step
[Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — guidance only, never auto-invoked. For each Epic just drafted, author its spec → `/dev-workflows:specify <PRD> <Epic>` (PE); the **Epic fan-out** (depth vs breadth) applies from the spec/design stage on. Optionally a Product Architect adds an Epic-level ARD first → `/dev-workflows:create-ard <PRD> <Epic>`. If the review BLOCKED, resolve that first.]

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 11), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:

- **Continuing as PE (`/dev-workflows:specify <PRD> <Epic>`)?** → run **`/compact`** — context still relevant.
- **Handing to PA (`/dev-workflows:create-ard <PRD> <Epic>`), even yourself?** → run **`/clear`** for a clean slate.
- Consider **`/rename <PRD-ID>-<slug>-pe`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
```

---

## Phase 10 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 9 Final Report is composed; NEVER
interrupts an earlier phase. Persist the run's manual-step / out-of-scope
follow-ups by citing `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md`
and executing its steps inline.

1. **Collect** the qualifying follow-ups: the manual publish step ("create these
   drafted Epics elsewhere manually" — the drafts are plain files
   tickets) and the Phase 9 `### Deferred items` that are out-of-scope refinement.
2. **Filter** them with the reference's §6 qualifying predicate.
3. **Resolve** the write target via the §4 ladder using `key` and `source`;
   render + place tasks and verbose notes per §1–§3; dedupe per §5.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 9 report. This phase NEVER
fails the run, NEVER commits (still true — this phase only writes follow-up
files; those writes are committed by the terminal `commit-artifacts` step in
Phase 11, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and
NEVER writes into the current working directory.

---

## Phase 11 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 10 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the PRD by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /epics`, `phase: epic-refinement`, `role: pe`,
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

**Then write the resume pointer.** Cite
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite
`<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the
pointer reflects the completed run, and before the commit step below, so it is
included in it. Redact per §1. Silent; the printed `### Context hygiene`
guidance already appeared in the Phase 9 report.

**Then commit session artifacts (terminal).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`commit-artifacts` entry point (§4) inline — the LAST action of the run. It
stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits
`<KEY> Add dev-workflows session artifacts (/epics)`, and pushes per §4 step 5.
It NEVER touches a code/docs
repo, or the current working directory; NEVER
force-pushes; NEVER fails the run; and skips entirely when the run carries
`specs_git: blocked` (§3.3 G0), re-emitting that notice. Because the Phase 9
report was composed before this phase, **print its §6 outcome line here**, as
the run's last output — prefixed `Specs repo:`, with any guard notice repeated
in full.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git
for the deliverable remains the user's responsibility — `/epics` never
branches or opens a PR; the terminal step above commits only the bounded
session-artifact paths in `$SPECS_PATH`), and NEVER writes into
the current working directory; no
user name is ever written (§10 privacy).

---

## Invariants (always enforced)

- ALWAYS `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) before escalating a halt caused by a **plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked) — so a run abandoned at the block still records it. NEVER for a work-quality review BLOCK or an environment / user halt (repo-missing, dirty-tree, key-not-found, cancellation)
- ALWAYS resolve one positional address (Phase 0) — a key or an `@<path>`; see `$VAULT_PATH`; a folder in the specs tree works without it; `/epics` is cwd-agnostic and rejects `mode: direct`
- NEVER create a git branch — this command never branches. `specs-preflight` may switch `$SPECS_PATH` between branches that already exist, and only ones the plugin created (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.2); it creates none.
- NEVER commit the Epic drafts or anything in the vault, or the current working directory — git management there is the user's responsibility. The terminal `commit-artifacts` step commits ONLY `$SPECS_PATH`'s bounded artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
- ALWAYS run `specs-preflight` at Phase 0 and `commit-artifacts` as the run's last action (per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`) — bounded to `$SPECS_PATH`'s artifact paths (§2.1) and to plugin-created branches (§2.2), always `git -C "$SPECS_PATH"` and never a `cd` (§1 rule 1), never force-pushing, and never failing the run
- NEVER write inside `_archive/` — read-only by convention
- ALWAYS write inside the resolved PRD folder — each Epic in its own `EPIC-` subfolder, `_coverage.md` beside `prd.md` (there is one home and it is derived, so no path is asked for)
- ALWAYS write to `EPIC-<PRD-KEY>-NN-<eslug>/epic.md` under the resolved PRD folder — one home, derived rather than asked for  — auto-create the directory if missing
- ALWAYS escalate missing repos before proceeding — never silent skip
- ALWAYS invoke `epic-reviewer` before Phase 8 maintenance
- ALWAYS resolve the `model_routing` block at Phase 1.5 and pin each subagent dispatch to its §9 chain via `model:` — the mechanical steps (the folder read, `code-scanner`, `prose-style-checker`, `doc-fixer`) and `epic-writer` (MODERATE) to the §2.1 Sonnet chain; `epic-reviewer` keeps its frontmatter Opus pin (no override); coordination + interactive gates run on `current_model`
- ALWAYS delegate Phase 6 writing to the `epic-writer` subagent (write-only); the orchestrator never writes Epics itself and never commits the drafts (still true — the drafts land in the vault / output directory, which the terminal `commit-artifacts` step never stages; git management there is the user's responsibility)
- ALWAYS cap review/fix cycles: 1 fix + 1 re-review max
- ALWAYS pass `Change type: docs` in the Phase 8 change summary block
- ALWAYS pass `Command run: /epics` in the Phase 8 Agent 4 session handoff
- ALWAYS spawn Phase 8 agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; last choice is always `"Other… (describe)"`
- ALWAYS produce the Phase 9 report as the final output
- ALWAYS end the Phase 9 report with a `### Next step` recommendation (per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`) — guidance only, never auto-invoked
- ALL written claims must be traceable to a resolved key (from the folder read) or code paths (from `code-scanner`); do not invent content the sources don't contain. `[[KEY]]` wikilinks in the draft are correct here and stay: `/epics` writes into an Obsidian vault, where a wikilink is the native idiom and resolves. `${CLAUDE_PLUGIN_ROOT}/references/doc-structure-conventions.md` §1 — which bans in-page provenance — governs **rendered product-docs pages** (`/document`'s write targets), not vault documents; do not apply it to Epic drafts
- NEVER run `docs-style-checker` — Epic drafts are vault-internal and not subject to product-docs prose linting. Prose style is checked via `prose-style-checker` in Phase 6.2 instead.
- ALWAYS have `epic-writer` write `_coverage.md` to the PRD folder itself (PRD-holistic, even in focus mode); it is NOT an Epic definition and is never published
- ALWAYS run the Phase 6.1 clarification gate when the writer returns clarifications; unresolved-by-choice markers become `epic-reviewer` BLOCKERs
- ARD steps (Phase 2.5, writer/reviewer `applicable_ard`, the Phase 9 ARD section) are ADDITIVE and guarded on `status: found` — a run with no ARD is byte-identical to before
- ALWAYS pass `requirements[]`, the `_coverage.md` path, and `applicable_ard` (when found) to `epic-reviewer`
- ALWAYS treat linked Epics flagged `refinement_candidate: true` as fill-in targets (not non-duplication constraints) once the Phase 3.5 gate selects `refine`/`both`; the confirmed target set is the PE's, not the raw detection
- ALWAYS write every Epic to `EPIC-<key>-<eslug>/epic.md`, refined and net-new alike — the folder carries the key, the filename carries the kind (`<output_dir>/<slug>.md`; refined files carry a `**Team:**` line
- ALWAYS re-surface the code-scan default adaptively in Phase 3.5 for refine/both (ON at ≥2 targets, OFF at 1) — never in the generate path
- ALWAYS run the Phase 6.1 leftover-disposition gate in refine/both when `_coverage.md` has `❌ gap` rows; silent no-op when none
- Refinement mode (Phase 3.5 gate, `refinement_targets` handoff, leftover gate, keyed output) is ADDITIVE and guarded — no `refinement_candidate` targets AND no `focus_key` ⇒ `mode = generate` and the run is byte-identical to the legacy net-new flow
- ALWAYS end the Phase 9 report with a `### Context hygiene` block per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the `resume.md` write runs later, in the terminal cost phase, per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the guidance only), then a role-aware `/compact`|`/clear` suggestion + `/rename <PRD-ID>-<slug>-pe`; guidance only, never auto-run.
