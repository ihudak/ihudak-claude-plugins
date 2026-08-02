---
tags:
  - tasks-exclude
---

# `/create-ard` command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the `/create-ard` command (dev-workflows v2.17.0) — the Product Architect phase: grounds on the mounted repos (architect-driven, no PRs) and authors a scoped, optional ARD for a VI or Epic, gated by a new Opus `ard-reviewer`.

**Architecture:** Additive to dev-workflows (markdown commands/agents/references + JSON manifests). New orchestrator `commands/create-ard.md` grounds via `code-scanner` on an architect-confirmed repo set and authors inline (Opus grill) against a new `references/ard-format.md`, gated by a new Opus `agents/ard-reviewer.md`. Introduces the `pa`/`architecture` cost role.

**Tech Stack:** Markdown command/agent/reference files; JSON plugin manifests; `python3` (stdlib) for JSON validation. NO test framework, NO husky/prettier hook — verification is **structural** (grep anchors, `python3 json.load`, byte-diff).

## Global Constraints

- **Additive only.** No behavior change to existing commands except the count/enumeration reconciliations named below. ARD *consumption* by `/specify`/`/design`/`/implement` is the **v2.18.0 follow-up**, not this effort.
- **Version lock-step 2.17.0** in `plugins/dev-workflows/.claude-plugin/plugin.json` and the `dev-workflows` entry of the root `.claude-plugin/marketplace.json`; the two `description` strings stay **byte-identical**.
- **Siblings untouched & byte-identical:** `dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1.
- **Commit named files only — NEVER `git add -A`.** Branch `ivgu/NOISSUE-create-ard-command`. Trailer EXACTLY: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **Push only when the user asks** (pause at finish-branch).
- **Grounding is architect-driven, never PR-derived** (no PRs exist at ARD time). ARD is architecture only — no code writing.
- **Never write to cwd.** Watch for lima read-after-write git flakiness (fsck-first, `update-ref` the dangling commit if a ref-write fails; verify HEAD after each write).

---

## File Structure

**New (3):** `references/ard-format.md` (ARD contract), `agents/ard-reviewer.md` (Opus reviewer), `commands/create-ard.md` (orchestrator).
**Modified (7):** `references/feedback-emission.md` (ten→eleven), `references/cost-emission.md` (enum + `pa`/`architecture` row), `references/dependencies.md` (grilling list), `.claude-plugin/plugin.json` + root `.claude-plugin/marketplace.json` (v2.17.0 + counts), `CHANGELOG.md`, `README.md`.

All paths relative to repo root `/workspace/ihudak-claude-plugins`.

---

### Task 1: `references/ard-format.md` (ARD contract)

**Files:** Create `plugins/dev-workflows/references/ard-format.md`
**Interfaces:** Produces the frontmatter keys + `AD-N` structure + section headings that Task 2 (`ard-reviewer`) and Task 3 (`create-ard` Phase 4) rely on.

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
# Architecture Requirements/Decision Document (ARD) format (embedded authority)

The canonical structure and rules for an ARD authored by `/create-ard`. `ard-reviewer` reviews against
this file. The ARD is **architecture** — invariants, grounded as-is findings, and cross-cutting
decisions — NOT product requirements (that is the VI) and NOT a per-Epic implementation plan (that is
`/design`). One shape; **depth scales with altitude**: a VI-level ARD stays at invariants + frame; an
Epic-level ARD goes deeper on that Epic's repos/areas.

## Altitude & scope

- **VI-level** (`/create-ard <VI-KEY>`) — cross-cutting invariants + broad-but-shallow grounding across the affected repos.
- **Epic-level** (`/create-ard <VI-KEY> <Epic-KEY>`) — deeper grounding on the Epic's repos/areas; **inherits the VI-level ARD's `AD-N` read-only** and must not contradict them.
- **Per-area** — a big Epic spanning separable areas in one repo (e.g. backend `server/` + frontend `ui/`) may split into `<EPIC>-<area>_ARD.md` (grill-decided).

## Frontmatter

```yaml
---
title: <VI or Epic title> — ARD
scope: vi | epic
vi: <VI-KEY>
epic: <EPIC-KEY | null>
area: <name | null>
status: draft | reviewed
grounded_repos:
  - <repo-slug @ absolute path>
inherits: <path to <VI>_ARD.md | null>
derived_from: <path to <VI>_ValueIncrement.md>
---
```

## Sections

- `## Context` — the problem/goal frame from the VI (Epic-level adds the Epic's scope).
- `## Grounding findings (architecture as-is)` — what exists today, each claim citing a real `file:line` in a `grounded_repos` entry. An unmounted/descoped repo appears only under Open questions — NEVER as an invented "as-is" claim.
- `## Architecture decisions` — `### [AD-N]: <title>`, each with **Binds:** (what it constrains) · **Prevents:** (the divergence it stops) · **Rule:** (a single testable statement). Epic-level lists inherited VI-level ADs read-only under "Inherited invariants".
- `## Cross-repo / component approach` — the Capability→Architecture map (which capability lands in which repo/component).
- `## Stack & invariants` — pinned versions / conventions that must hold.
- `## Edge cases & risks`.
- `## Open questions` — incl. ungrounded/descoped repos.
- `## Deferred` — VI-level → per-Epic `/create-ard` / `/design`; Epic-level → `/design` / `/implement`.

## Quality rules

- Every "as-is" claim cites a grounded `file:line`; no fabricated/uncited architecture.
- `AD-N` are **testable** and non-overlapping (Binds/Prevents/Rule each populated).
- **VI-level carries NO per-repo detailed solutions** — that is `/design`'s job.
- An Epic-level ARD may go deeper but stays architecture, not an implementation plan.
- Grounding is **architect-driven** (repos confirmed by the architect), never derived from PRs (which do not exist at ARD time).
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/references/ard-format.md
grep -q "^# Architecture Requirements/Decision Document" "$f" \
  && for h in "## Altitude & scope" "## Frontmatter" "## Context" "## Grounding findings" "## Architecture decisions" "## Cross-repo / component approach" "## Stack & invariants" "## Open questions" "## Deferred"; do grep -qF "$h" "$f" || { echo "MISSING: $h"; exit 1; }; done \
  && grep -q "scope: vi | epic" "$f" && grep -q "grounded_repos" "$f" && grep -q "inherits:" "$f" \
  && grep -q "AD-N" "$f" && grep -q "architect-driven" "$f" && grep -q "never derived from PRs" "$f" \
  && echo "OK ard-format"
```
Expected: `OK ard-format`

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/ard-format.md
git commit -m "feat(create-ard): add ARD format reference

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `agents/ard-reviewer.md` (Opus ARD reviewer)

**Files:** Create `plugins/dev-workflows/agents/ard-reviewer.md`
**Interfaces:** Consumes `references/ard-format.md` (Task 1). Produces the reviewer dispatched by Task 3 Phase 5 (input: ARD path + scope; output: findings + PASS/PASS WITH RECOMMENDATIONS/BLOCK).

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
---
name: ard-reviewer
description: Reviews an Architecture Requirements/Decision Document (ARD) authored by /create-ard for grounding integrity (every as-is claim cites a real file:line), AD-N well-formedness (Binds/Prevents/testable Rule), non-contradiction of inherited VI-level invariants, altitude purity (no per-repo solutions at VI level), and recorded open questions. Read-only; returns findings + a PASS / PASS WITH RECOMMENDATIONS / BLOCK verdict. Uses Claude Opus.
model: opus
tools: ["Read", "Glob", "Grep", "LS"]
---

Read-only whole-ARD reviewer for drafts produced by `/create-ard`. Uses the strongest available
reasoning model (Claude Opus). Reads the **whole** ARD and checks it against the rules in
`${CLAUDE_PLUGIN_ROOT}/references/ard-format.md` plus the dimensions below. Never edits the ARD.

Invoked from `/create-ard` Phase 5 after authoring. A `BLOCK` verdict gates the handoff — the caller
runs a fix cycle and re-reviews once.

## Input contract

- **ARD path** — absolute path to the `*_ARD.md`. Required; if absent, stop and report.
- **Scope** — `vi | epic`. Review at the stated altitude; for an Epic-level ARD also read the inherited VI-level ARD named in `inherits:` (if any) to check for contradictions.

## Review method

1. Read the ARD end-to-end before judging.
2. Verify frontmatter: `scope`; `vi` matches `^[A-Z][A-Z0-9_]*-\d+$`; `grounded_repos` present; Epic-level has `epic` + (if a VI-level ARD exists) `inherits`.
3. For each "as-is" claim in Grounding findings, confirm it cites a `file:line` in a `grounded_repos` entry — spot-check that the cited path plausibly exists (Glob/Grep). An uncited or clearly-fabricated claim → BLOCKER.
4. Apply the dimensions below; record findings in the severity schema; route gaps needing human input to **needs architect input**; never fabricate a fix.

## Dimensions

- **Grounding integrity (BLOCKER):** every architectural "as-is" statement cites a real `file:line` in a grounded repo; a decision resting on an uncited/fabricated claim → BLOCKER. An ungrounded/descoped repo must appear only as an Open question.
- **`AD-N` well-formed (MAJOR):** each decision has **Binds** / **Prevents** / a single **testable Rule**; vague or untestable → MAJOR.
- **Inherited invariants (Epic-level, BLOCKER):** the Epic ARD must not contradict an inherited VI-level `AD-N`.
- **Altitude purity (MAJOR):** a VI-level ARD carries no per-repo detailed solutions (that is `/design`); an Epic-level ARD stays architecture, not an implementation plan.
- **Open questions:** ungrounded/descoped repos and unresolved decisions are recorded, not silently dropped.
- **Identifier integrity:** `[AD-N]` unique + contiguous; cross-references point at existing IDs.

## Output contract

Return only findings, no preamble, ordered `BLOCKER` → `MAJOR` → `MINOR` → `NIT`:

```
[BLOCKER|MAJOR|MINOR|NIT] — <Section or AD-N>
Violation: <what rule is broken and where>
Fix: <concrete recommendation, or "needs architect input">
```

Then a final verdict line:
- `PASS` — no findings above MINOR.
- `PASS WITH RECOMMENDATIONS` — MAJOR/MINOR/NIT only, no BLOCKER.
- `BLOCK` — at least one BLOCKER.

If nothing is actionable, say so and state the scope reviewed.
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/agents/ard-reviewer.md
grep -q "^name: ard-reviewer" "$f" && grep -q "^model: opus" "$f" && grep -q '"Read", "Glob", "Grep", "LS"' "$f" \
  && grep -q "Grounding integrity (BLOCKER)" "$f" && grep -q "Inherited invariants (Epic-level, BLOCKER)" "$f" \
  && grep -q "Altitude purity (MAJOR)" "$f" && grep -q "PASS WITH RECOMMENDATIONS" "$f" && echo "OK ard-reviewer"
```
Expected: `OK ard-reviewer`

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/ard-reviewer.md
git commit -m "feat(create-ard): add Opus ard-reviewer agent

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `commands/create-ard.md` (orchestrator)

**Files:** Create `plugins/dev-workflows/commands/create-ard.md`
**Interfaces:** Consumes `references/ard-format.md` (T1), `agents/ard-reviewer.md` (T2), `references/grilling-technique.md`, `references/jira-input-resolution.md`, `agents/jira-reader.md`, `agents/code-scanner.md`, `references/feedback-emission.md`, `references/cost-emission.md`, the `dev-workflows:model-routing` skill.

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
---
name: create-ard
description: Architecture-authoring workflow (Product Architect phase, sub-project 3 of the VI-creation flow). Grounds on the mounted implementation repos (architect-driven discovery — no PRs) and authors an ARD for a VI (/create-ard <VI-KEY>) or an Epic (/create-ard <VI-KEY> <Epic-KEY>, inheriting the VI-level ARD), against references/ard-format.md, gated by the Opus ard-reviewer, written to $SPECS_PATH/specifications/<KEY>-<slug>/. Optional; scoped; product-architecture level (no code writing). Introduces the pa role.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Author an Architecture Requirements/Decision Document for the Jira item: $ARGUMENTS

`/create-ard` is **sub-project 3 of the VI-creation flow** — the **Product Architect (PA)** phase. It
grounds on the mounted implementation repos and authors an **ARD** that establishes the architecture
invariants the downstream (`/specify`, `/design`, `/implement`) will later inherit. The ARD is
**optional** (a simple VI may not need one) and **scoped** via the two-key grammar:

- `/create-ard <VI-KEY>` → a **VI-level** ARD.
- `/create-ard <VI-KEY> <Epic-KEY>` → an **Epic-level** ARD (inherits the VI-level ARD read-only).

It authors architecture only — no code writing; grounding is **architect-driven** (there are no PRs at
this stage). Zero Jira API.

---

## Phase 0 — Resolve input
1. **Resolve the Jira input** via `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against `$ARGUMENTS` → `jira_key` (the VI), `focus_key` (the Epic, or `null`), `jira_export_root`, `source`. Define `<VI>` = `jira_key`, `<EPIC>` = `focus_key`.
2. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH` (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
3. **Feature folder.** VI-level → `specifications/<VI>-<vslug>/`; Epic-level → `specifications/<VI>-<vslug>/<EPIC>-<eslug>/`. Honor an existing dir matched by key-number (tolerate `-`/`_` drift). Auto-created on first write.
4. **Prior ARD.** If the target `*_ARD.md` exists → Phase 1 offers refine-vs-fresh.
5. **Optionality advisory.** Gauge size — the VI's user-story count / scope breadth / number of candidate repos. For a small, single-repo VI, note "an ARD may be optional here" and offer `choices: ["Author the ARD anyway", "Stop — no ARD needed", "Other… (describe)"]`.

`/create-ard` is **cwd-agnostic**; it reads the VI/Epic and scans repos under `$REPOS_PATH`.

---

## Phase 1 — Configure
Use `choices` arrays; the last choice is always `"Other… (describe)"`.
1. **Confirm** the scope (VI-level vs Epic-level) and the feature folder.
2. **Refine vs fresh** (only if a prior `*_ARD.md` exists): `choices: ["Refine the existing ARD (Recommended)", "Start fresh — overwrite", "Cancel", "Other… (describe)"]`.
3. **Repos search base (`$REPOS_PATH`).** Read `${REPOS_PATH:-/workspace}` (may be colon-separated): `choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]`.
4. **Repo refresh policy** (governs Phase 3's `code-scanner`): `choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh", "Other… (describe)"]`.

---

## Phase 1.5 — Classify + model routing
Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE | SIGNIFICANT | HIGH-RISK   # architecture; SIGNIFICANT common for cross-repo VIs
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # code-scanner, impl-maintenance
  review_model:    <§2 Opus chain>     # ard-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + ARD authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

**Tiered HARD model gate (like `/design`):** for `SIGNIFICANT` / `HIGH-RISK`, require an Opus session — if `opus_available` is false, stop: `choices: ["I'll relaunch /create-ard on Opus (Recommended)", "Override — proceed on the current model (logged in the final report)", "Cancel", "Other… (describe)"]`. For `SIMPLE`/`MODERATE`, degradation is advisory (record in `notes`).

---

## Phase 2 — Read the VI (+ Epic, + inherited ARD)
Read the VI from `$SPECS_PATH/specifications/<VI>-<vslug>/<VI>_ValueIncrement.md` when present (authored source); else dispatch `jira-reader` against `jira_export_root` to read it from the export. For an **Epic-level** run, dispatch `jira-reader` (`depth: full`, scoped to `focus_key`) for the Epic's scope, and if a `<VI>_ARD.md` exists load its `AD-N` invariants to **inherit read-only**.

Extract the problem/goal/scope frame + capability themes — the raw material for grounding + the grill.

---

## Phase 3 — Architect-driven grounding (no PRs)
There are no PRs at ARD time, so repos are **architect-driven**, not PR-derived:
1. **Cheap discovery.** List the top-level directories under each `$REPOS_PATH` entry (`ls`). Optionally attach each dir's one-line identity — `timeout 5 git -C <dir> remote get-url origin 2>/dev/null` (slug) or its README first heading. Do **not** deep-scan to guess relevance.
2. **Propose + ask.** From the VI/Epic themes, propose a `theme → repo` mapping against those dirs, and **ask the architect to confirm / correct / add**. For any requirement that maps to no obvious repo, **ask outright**: "which repo covers `<X>`?"
3. **Missing repo → consolidated mount-or-descope gate:** `choices: ["Mount now & re-scan", "Ground only the confirmed-mounted set (record the rest as open questions)", "Specify an absolute path for this repo", "Cancel", "Other… (describe)"]`.
4. **Ground the confirmed set.** Spawn `code-scanner` in batches of up to 4 concurrent agents per Agent message on the confirmed repos (wait for each batch), scoped by the themes:

   → Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §2.1 Sonnet chain>`):
     > "repo_path: <resolved absolute path>
     >  repo_url_slug: <slug>
     >  capability_themes: [themes]
     >  context: |
     >    [3–5 sentences: the VI/Epic goal, what the ARD must ground]
     >  search_hints: { symbols: […], paths: […], keywords: […] }
     >  refresh: { switch_to_default_branch: [per Phase 1], pull: [per Phase 1] }"

   Store the per-repo as-is findings (`file:line`). Descoped/unmounted repos become Open questions.

---

## Phase 4 — Author via grill
**Interview technique (grilling — embedded; no runtime dependency).** Conduct a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, explore the Phase 3 grounding findings / the VI to self-answer (fact-vs-decision), walk the design tree in dependency order, continue to shared understanding then write each section.

Author the ARD live against `${CLAUDE_PLUGIN_ROOT}/references/ard-format.md` at the resolved altitude: Context → Grounding findings (cite `file:line`) → Architecture decisions (`AD-N`: Binds/Prevents/Rule) → Cross-repo/component approach → Stack & invariants → Edge cases & risks → Open questions → Deferred. At Epic level, list inherited VI-level ADs read-only and never contradict them; VI level stays at invariants/frame (no per-repo detailed solutions).

**Per-area split.** If (Epic level) the confirmed grounding spans separable areas in one repo (e.g. `server/` backend + `ui/` frontend), grill: `choices: ["One combined ARD (Recommended)", "One ARD per area (backend / frontend / …)", "Other… (describe)"]`. On per-area, author one `<EPIC>-<area>_ARD.md` per area (each with its own `area:` frontmatter).

---

## Phase 5 — Review gate
Dispatch `ard-reviewer` (Opus, frontmatter-pinned; recorded as `review_model`, no override):

→ Agent (subagent_type: "dev-workflows:ard-reviewer", model: `<review_model — §2 Opus chain>`):
  > "Review the ARD:
  >
  > ARD path: [absolute path to the *_ARD.md]
  > Scope: [vi | epic]"

On `BLOCK`, fix the BLOCKER findings inline (the orchestrator/grill edits the ARD — no delegated writer) and re-review **once**; if still `BLOCK`, escalate per the `Review verdict BLOCK` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. `PASS` / `PASS WITH RECOMMENDATIONS` → proceed. Cap: one fix cycle + one re-review. (For a per-area split, review each area ARD.)

---

## Phase 6 — Handoff
Write the ARD file(s) into the feature folder. Then **offer** (commit-when-asked — never automatic): `choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git", "Cancel"]`. Branch `ard/<VI>-<vslug>` (VI-level) or `ard/<EPIC>-<eslug>` (Epic-level); commit ONLY the feature folder (never `git add -A`); push; open a PR targeting `main`. Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## Phase 7 — Next-step offer (adaptive)
- **VI-level ARD:** if the VI has 0 Epics → `choices: ["Split into Epics — /epics <VI> (then create them in Jira + re-import) (Recommended)", "Author a spec — /specify", "Stop here", "Other… (describe)"]`; else offer `/specify`.
- **Epic-level ARD:** `choices: ["Author the spec — /specify <VI> <Epic> (Recommended)", "Design it — /design <VI> <Epic>", "Stop here", "Other… (describe)"]`.

Guidance only — never auto-invokes another command.

---

## Phase 8 — Session maintenance, feedback & cost
Terminal phase — runs after Phase 7, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference gap**, `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER `emit-block` for an environment / user halt (unset `$SPECS_PATH`, missing key, no-ARD-needed, unmounted-repo descope, cancellation) or a review BLOCK.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/create-ard`; what was authored (ARD scope + grounded repos); key events (grounding gaps/descopes, BLOCK reviews — or 'none'); workarounds; the `ard-reviewer` verdict; test result N/A; project root = the feature folder.
2. **Persist plugin feedback (automatic).** Cite `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6) with the report, `command: /create-ard`, the run's `jira_key`, `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its `emit-cost` entry point with `command: /create-ard`, `phase: architecture`, `role: pa`, the run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only notice).

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is offered only in Phase 6), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report
Report: the ARD path(s) + scope (VI/Epic, any per-area split); the grounded repos + any descoped/ungrounded ones; `AD-N` count; open-question count; the `ard-reviewer` verdict; the PR URL (if opened); resolved model routing (+ any Opus gate/degradation); the feedback + cost paths; and the adaptive next-step recommendation.
````

- [ ] **Step 2: Verify**

```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/commands/create-ard.md
grep -q "^name: create-ard" "$f" && grep -q "allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS" "$f" \
  && for h in "## Phase 0 — Resolve input" "## Phase 1 — Configure" "## Phase 2 — Read the VI" "## Phase 3 — Architect-driven grounding" "## Phase 4 — Author via grill" "## Phase 5 — Review gate" "## Phase 6 — Handoff" "## Phase 7 — Next-step offer" "## Phase 8 — Session maintenance, feedback & cost"; do grep -qF "$h" "$f" || { echo "MISSING: $h"; exit 1; }; done \
  && grep -q "jira-input-resolution.md" "$f" && grep -q 'skill: "dev-workflows:model-routing"' "$f" \
  && grep -q "references/grilling-technique.md" "$f" && grep -q "references/ard-format.md" "$f" \
  && grep -q 'subagent_type: "dev-workflows:ard-reviewer"' "$f" && grep -q 'subagent_type: "dev-workflows:code-scanner"' "$f" \
  && grep -q "no PRs" "$f" && grep -q "mount-or-descope" "$f" \
  && grep -q "phase: architecture" "$f" && grep -q "role: pa" "$f" && grep -q "Capture-at-block invariant" "$f" \
  && echo "OK create-ard"
```
Expected: `OK create-ard`

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/create-ard.md
git commit -m "feat(create-ard): add /create-ard orchestrator command

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Subsystem wiring (feedback + cost + dependencies)

**Files:** Modify `references/feedback-emission.md`, `references/cost-emission.md`, `references/dependencies.md`

- [ ] **Step 1: feedback-emission.md — ten → eleven (both spots)**
  - `all ten workflow` → `all eleven workflow`
  - `the ten commands'` → `the eleven commands'`

- [ ] **Step 2: cost-emission.md — enum + new attribution row**
  - Header: `every VI-lifecycle command (`/idea`, `/create-vi`, `/specify`, `/epics`,` → `every VI-lifecycle command (`/idea`, `/create-vi`, `/create-ard`, `/specify`, `/epics`,`
  - §7 table: insert immediately **after** the `| `/create-vi` | vi-creation | pm |` row: `| `/create-ard` | architecture | pa |`

- [ ] **Step 3: dependencies.md — add `/create-ard` to the grilling row (both mentions)**
  - `the embedded grilling technique in `/idea`, `/create-vi`, `/specify`, `/design`` → `the embedded grilling technique in `/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design``
  - `The grilling *technique* is embedded in `/idea` / `/specify` / `/design`` → `The grilling *technique* is embedded in `/idea` / `/create-vi` / `/create-ard` / `/specify` / `/design``

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
fe=plugins/dev-workflows/references/feedback-emission.md
ce=plugins/dev-workflows/references/cost-emission.md
de=plugins/dev-workflows/references/dependencies.md
grep -q "all eleven workflow" "$fe" && grep -q "the eleven commands'" "$fe" && ! grep -q "all ten workflow" "$fe" \
  && grep -qF 'every VI-lifecycle command (`/idea`, `/create-vi`, `/create-ard`, `/specify`' "$ce" \
  && grep -qF '| `/create-ard` | architecture | pa |' "$ce" \
  && grep -qF 'in `/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`' "$de" \
  && grep -qF 'embedded in `/idea` / `/create-vi` / `/create-ard` / `/specify` / `/design`' "$de" \
  && echo "OK wiring"
```
Expected: `OK wiring`

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/feedback-emission.md plugins/dev-workflows/references/cost-emission.md plugins/dev-workflows/references/dependencies.md
git commit -m "chore(create-ard): wire /create-ard into feedback + cost + dependencies

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Version + manifests + CHANGELOG

**Files:** Modify `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/dev-workflows/CHANGELOG.md`

- [ ] **Step 1: plugin.json** — five edits:
  - `"version": "2.16.0"` → `"version": "2.17.0"`
  - `Eighteen slash commands` → `Nineteen slash commands`
  - `/idea, /create-vi, /specify, /design,` → `/idea, /create-vi, /create-ard, /specify, /design,`
  - `Twenty-eight reusable subagents` → `Twenty-nine reusable subagents`
  - `spec-reviewer, design-reviewer, vi-reviewer)` → `spec-reviewer, design-reviewer, vi-reviewer, ard-reviewer)`

- [ ] **Step 2: marketplace.json** — in the `dev-workflows` entry ONLY (do not touch `dt-style-guide` 0.2.2 / `obsidian-llm-wiki` 0.3.1): apply the exact same five edits so its `description` stays **byte-identical** to plugin.json.

- [ ] **Step 3: CHANGELOG.md** — insert directly above `## [2.16.0] — 2026-07-10`:

```markdown
## [2.17.0] — 2026-07-10

### Added

- **New `/create-ard` command — sub-project 3 (final) of the VI-creation flow (Product Architect phase).** `/create-ard <VI-KEY> [<Epic-KEY>]` grounds on the mounted implementation repos and authors an **ARD** (Architecture Requirements/Decision Document) that establishes the architecture invariants the downstream inherits. **Optional** (a simple VI may not need one — Phase 0 advises) and **scoped** via the two-key grammar: `<VI-KEY>` → VI-level (cross-cutting invariants + broad grounding); `<VI-KEY> <Epic-KEY>` → Epic-level (deeper; inherits the VI-level ARD's `AD-N` read-only). A big Epic spanning separable areas in one repo (e.g. `cluster2` `server/`+`ui/`) can split into `<EPIC>-<area>_ARD.md`. Grounding is **architect-driven, not PR-derived** (no PRs exist at ARD time): cheap `$REPOS_PATH` discovery + a `theme→repo` proposal + ask the architect + a consolidated mount-or-descope gate, then `code-scanner` on the confirmed set. Authored inline via the relentless grill against a new `references/ard-format.md` (Context · Grounding findings with real `file:line` · Architecture decisions `AD-N: Binds/Prevents/Rule` · Cross-repo map · Stack & invariants · Edge cases · Open questions · Deferred), gated by a new Opus **`ard-reviewer`** (grounding integrity, `AD-N` testability, no contradiction of inherited invariants, altitude purity), with a `/design`-style tiered hard model gate, written to `$SPECS_PATH/specifications/<KEY>-<slug>/`, branch+PR offer. Introduces the **`pa` (Product Architect)** role / `architecture` phase in the cost + feedback model. `references/feedback-emission.md` (ten → eleven commands) and `references/dependencies.md` (grilling list) reconciled. The sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched. **Follow-up (v2.18.0):** wire ARD *consumption* into `/design`, `/implement`, and `/specify` (both VI + Epic levels) — this effort ships the producer only.
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;print(json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])" | grep -qx 2.17.0
python3 -c "import json;m={p['name']:p for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']};a=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));assert m['dev-workflows']['version']=='2.17.0';assert m['dt-style-guide']['version']=='0.2.2';assert m['obsidian-llm-wiki']['version']=='0.3.1';assert m['dev-workflows']['description']==a['description'],'descriptions differ';print('json+lockstep OK')"
grep -q "Nineteen slash commands" plugins/dev-workflows/.claude-plugin/plugin.json && grep -q "Twenty-nine reusable subagents" plugins/dev-workflows/.claude-plugin/plugin.json
grep -q "/create-vi, /create-ard, /specify" plugins/dev-workflows/.claude-plugin/plugin.json && grep -q "vi-reviewer, ard-reviewer)" plugins/dev-workflows/.claude-plugin/plugin.json
head -12 plugins/dev-workflows/CHANGELOG.md | grep -q "## \[2.17.0\] — 2026-07-10"
echo "OK manifests+changelog"
```
Expected: `json+lockstep OK` then `OK manifests+changelog`.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "chore(release): dev-workflows 2.17.0 (/create-ard command)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: README updates

**Files:** Modify `plugins/dev-workflows/README.md`

- [ ] **Step 1: Read the current anchors:**

```bash
cd /workspace/ihudak-claude-plugins
grep -n "Eleven workflow slash commands" plugins/dev-workflows/README.md
grep -n "VI-lifecycle commands" plugins/dev-workflows/README.md
grep -n "projects the plugin-facing slice\|all ten workflow commands" plugins/dev-workflows/README.md
grep -n "| \`/specify <VI-KEY" plugins/dev-workflows/README.md
```

- [ ] **Step 2: Lead sentence** — `Eleven workflow slash commands for idea refinement, VI authoring, structured implementation,` → `Twelve workflow slash commands for idea refinement, VI authoring, architecture, structured implementation,`

- [ ] **Step 3: Command table — insert a `/create-ard` row** immediately **before** the `/specify` row (matched in Step 1). Insert this single line:

```
| `/create-ard <VI-KEY> [<Epic-KEY>]` | Architecture authoring (Product Architect phase, sub-project 3 of the VI-creation flow). **Optional**; grounds on the mounted implementation repos (architect-driven discovery — cheap `$REPOS_PATH` listing + `theme→repo` proposal + ask + mount-or-descope + `code-scanner`; **no PRs**) and authors an **ARD** (Context · Grounding findings with real `file:line` · Architecture decisions `AD-N: Binds/Prevents/Rule` · Cross-repo map · Stack & invariants · Edge cases · Open questions · Deferred) against `references/ard-format.md`. Scoped via the two-key grammar: `<VI-KEY>` → VI-level; `<VI-KEY> <Epic-KEY>` → Epic-level (inherits the VI-level ARD read-only; a big Epic can split per area → `<EPIC>-<area>_ARD.md`). Gated by the Opus `ard-reviewer`; tiered hard model gate (like `/design`); written to `$SPECS_PATH/specifications/<KEY>-<slug>/`; branch+PR offer. New `pa` role. Offers `/epics`/`/specify` (VI) or `/specify`/`/design` (Epic) next. |
```

- [ ] **Step 4: Cost-phase count** — `on the eight VI-lifecycle commands (\`/idea\`, \`/create-vi\`, \`/specify\`,` → `on the nine VI-lifecycle commands (\`/idea\`, \`/create-vi\`, \`/create-ard\`, \`/specify\`,`

- [ ] **Step 5: Reference-list cost line** — `the terminal cost phase of the eight VI-lifecycle commands` → `the terminal cost phase of the nine VI-lifecycle commands`.

- [ ] **Step 6: Feedback list** — `all ten workflow commands` → `all eleven workflow commands`; and `\`/idea\`, \`/create-vi\`) projects` → `\`/idea\`, \`/create-vi\`, \`/create-ard\`) projects`.

- [ ] **Step 7: Verify**

```bash
cd /workspace/ihudak-claude-plugins
r=plugins/dev-workflows/README.md
grep -q "Twelve workflow slash commands for idea refinement, VI authoring, architecture" "$r" \
  && grep -q "| \`/create-ard <VI-KEY>" "$r" \
  && grep -qF "nine VI-lifecycle commands (\`/idea\`, \`/create-vi\`, \`/create-ard\`" "$r" \
  && grep -q "terminal cost phase of the nine VI-lifecycle commands" "$r" \
  && grep -q "all eleven workflow commands" "$r" \
  && grep -qF "\`/idea\`, \`/create-vi\`, \`/create-ard\`) projects" "$r" \
  && ! grep -q "Eleven workflow slash commands" "$r" \
  && echo "OK readme"
```
Expected: `OK readme`

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/README.md
git commit -m "docs(readme): document /create-ard command

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Whole-branch verification (after all tasks)

```bash
cd /workspace/ihudak-claude-plugins
git diff --stat main -- plugins/dt-style-guide plugins/obsidian-llm-wiki   # expect: no output
python3 -c "import json;a=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));m={p['name']:p for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']};assert a['version']=='2.17.0'==m['dev-workflows']['version'];assert a['description']==m['dev-workflows']['description'];print('lockstep OK')"
git diff --stat main    # expect: 3 new + 7 modified = 10 files
```
Expected: no sibling diff; `lockstep OK`; 10 files changed.

Then finish via **superpowers:finishing-a-development-branch** (no tests — structural verification above is the gate): present merge/PR/keep/discard; **push only when the user asks**.

---

## Self-Review (against the spec)

**Spec coverage:** optional + two-key scope (T3 Phase 0/1) ✓; one ARD shape depth-scales (T1) ✓; per-area split (T1 + T3 Phase 4) ✓; architect-driven grounding no-PRs + mount-or-descope + code-scanner (T3 Phase 3) ✓; VI read specs-then-jira-reader + inherited ARD (T3 Phase 2) ✓; Opus `ard-reviewer` dimensions (T2 + T3 Phase 5) ✓; tiered hard model gate (T3 Phase 1.5) ✓; `pa`/`architecture` cost + feedback + emit-block (T3 Phase 8 + T4) ✓; next-step offer (T3 Phase 7) ✓; counts + lock-step + byte-identical + siblings untouched (T4/T5/T6) ✓. The v2.18.0 consumption-wiring follow-up + next-phase-offer-everywhere + `.obsidian` revisit are recorded in the spec/CHANGELOG — not built here.

**Placeholder scan:** none — full content for all 3 new files; exact old→new for every edit.

**Type consistency:** `ard-reviewer` input (ARD path + scope) matches T3 Phase 5 dispatch; `ard-format.md` frontmatter/`AD-N`/section names match T3 Phase 4 authoring + the reviewer's checks; `phase: architecture`/`role: pa` match `cost-emission.md` §7 (new row); `references/grilling-technique.md` + `references/ard-format.md` citation paths match T1's filenames.
