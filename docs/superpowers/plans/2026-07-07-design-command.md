---
tags:
  - tasks-exclude
---
# `/design` Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `/design` — the Dev-phase engineering-design command (phase 2 of the PM→Dev pipeline) — to the `dev-workflows` plugin, shipping as **v2.6.0**.

**Architecture:** `/design` mirrors the shipped `/specify` (v2.4.0/v2.5.0) sibling: a Jira-driven-only orchestrator that reuses the shared `jira-input-resolution` front-end (grammar + `focus_key`), grounds strictly in fully-mounted code via `code-scanner`, authors an engineering `design.md` through an embedded one-question-at-a-time grill that **challenges** a merged `specification.md` and **designs** the implementation, gates on a new Opus `design-reviewer`, and lands `design.md` + the spec's engineering-review edits on the specs repo's main via branch + PR. Three net-new assets (`references/design-format.md`, `agents/design-reviewer.md`, `commands/design.md`) + one additive touch to shipped `/implement` (an open-question guard) + the v2.6.0 release surfaces.

**Tech Stack:** Markdown command/agent/reference files + JSON plugin manifests. No test framework and no husky/prettier hook in this repo — **verification is STRUCTURAL** (grep anchors, `python3 -c json.load`, byte-diff review).

**Source of truth:** the reconciled design doc `Projects/AI-First/dev-workflows - docs automation/spec/2026-07-07-design-command-design.md` (reconciled to shipped v2.5.0 on 2026-07-08). Mirror the shipped siblings verbatim in structure: `commands/specify.md`, `references/specification-format.md`, `agents/spec-reviewer.md`.

## Global Constraints

*(Every task's requirements implicitly include this section.)*

- **Repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`. Feature branch: `ivgu/NOISSUE-design-command` (branch off `main` @ `8e53830`; never implement on `main`).
- **No test framework / no commit hook** — verification is structural only; commits run clean (no `--no-verify` needed).
- **Delimiter = hyphen** everywhere `/design` writes: `specifications/<VI>-<vslug>/<EPIC>-<eslug>/`, branch `design/<EPIC>-<eslug>` or `design/<VI>-<vslug>`.
- **Flat layout** — `design.md` lands **flat** in the per-Epic folder, alongside `/specify`'s `specification.md`. No `spec/` subfolder.
- **Namespaced durable files** — `/design` writes `_design-session.md` / `_design-glossary.md` (NOT `_session.md` / `_glossary.md`, which `/specify` owns in the same flat folder).
- **`/design` does NOT use `jira-reader`** and does not read the Jira export for content — the front-end is used only to parse the grammar + classify the key; the requirements source of truth is the merged `specification.md` in the specs repo. (`code-scanner` IS used.)
- **`focus_key` consumed** — `/design` acts on the shared front-end's `focus_key` output field.
- **Version lock-step 2.6.0** — `plugins/dev-workflows/.claude-plugin/plugin.json` `version` + repo-root `.claude-plugin/marketplace.json` `plugins[0].version` + `plugins/dev-workflows/CHANGELOG.md` prepend, all `2.6.0`. Siblings **`dt-style-guide` 0.2.2 / `obsidian-llm-wiki` 0.3.1 untouched**.
- **Commit trailer** on every commit: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **Never `git add -A`** — stage only the files each task names.
- **Additive to shipped files** — the only shipped command touched is `/implement` (one additive Phase 0 guard bullet). Do not alter `/specify`, the shared `jira-input-resolution.md`, or `jira-reader`. Extending `/implement`'s spec-resolution to auto-discover nested per-Epic paths / consume `focus_key` is a SEPARATE effort — out of scope here.
- **Counts recomputed, never asserted from memory** — the README workflow-command count, subagent count, and Opus-gate count are recomputed from the manifest/`agents/` dir (the `/specify` "Eight vs Ten" scare confirmed this discipline).

---

## Task 1: `references/design-format.md` (net-new format authority)

**Files:**
- Create: `plugins/dev-workflows/references/design-format.md`

**Interfaces:**
- Consumes: nothing (net-new; no import source).
- Produces: the engineering-design format authority that `commands/design.md` (T3) authors against and `agents/design-reviewer.md` (T2) reviews against — the section set, the decision-density/omit-N/A rule, the header (with the `Open questions` MUST-be-0 handoff gate), and the traceability expectations.

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
# Design format (embedded authority)

The canonical structure and per-section rules for an engineering `design.md`. `/design` authors
against this file; `design-reviewer` reviews against it. **Net-new — authored for the dev-workflows
plugin, no import source** (unlike `specification-format.md`, which is a snapshot from
`mgd-specifications`).

## Principle — decision-dense, scalable

A `design.md` records **engineering decisions**, not prose. Include a section only when it carries a
real decision for this change; omit a section that does not apply and replace it with a one-line
`_N/A — <why>_`. Never pad. The classification (`SIMPLE` → `HIGH-RISK`) scales how many sections appear
and how deep each goes — a `SIMPLE` design is a few decisions; a `HIGH-RISK` design is thorough across
every section.

## Header

```
# Design

- **Feature name**: <human-readable name>
- **Spec**: <specification.md path, or the Epic key it designs>
- **Classification**: SIMPLE | MODERATE | SIGNIFICANT | HIGH-RISK
- **Version**: 1
- **Created**: <YYYY-MM-DD>
- **Author**: <whoami>
- **Repos**: <the confirmed implementation repos this design spans>
- **Open questions**: 0
```

Rules: **`Open questions` MUST be 0 to hand off.** A `design.md` is the last gate before code, so any
unresolved `- [ ]` under its `## Open questions` hard-blocks (`design-reviewer` BLOCKER; Phase 7
refuses; `/implement` refuses). This is the opposite of `specification.md`, where open questions are
tolerated. `Classification` matches the Phase 1.5 result and governs section inclusion below.

## Sections (in order)

Each section header is `## <name>`. Inclusion: **core** = always present (even `SIMPLE`); **scaled** =
present for `MODERATE`+ or whenever the change touches that concern, else a one-line `_N/A — why_`.

1. **## Context & problem** (core) — 2–5 sentences from the spec: who is affected, what the change
   delivers. Reference, don't restate, the spec.
2. **## Requirements coverage** (core) — a table/list tracing every in-scope spec item / user story
   (`[Uxx]`) / acceptance criterion (`[ACxx]`) to how this design addresses it, with a **challenge
   note** per row where the design questioned or refined the spec (`validated` / `questioned` /
   `proposed-change`). Every in-scope requirement is addressed or explicitly deferred with a reason.
   This is where the "challenge the spec" track lands in the design.
3. **## Architecture & components** (core) — the components changed/added and their responsibilities;
   a diagram or bullet decomposition. Name real modules/files where the code scan revealed them.
4. **## Interfaces / contracts** (core) — exact signatures, API shapes, schemas, events, config keys
   the change introduces or alters. Concrete types, not prose promises.
5. **## Seams** (scaled) — where the change is exercised under test; prefer the **highest** seam that
   still isolates the change. Name the seam per component.
6. **## Data flow** (scaled) — how data moves through the changed path; state transitions; persistence.
7. **## Error handling & edge cases** (scaled) — failure modes, boundaries, and the defined behaviour
   for each.
8. **## Test strategy** (core) — what is tested and how (unit / integration / e2e), keyed to the seams;
   cite existing test prior art in the scanned repos.
9. **## Risks & mitigations** (scaled) — engineering risks (performance, concurrency, data-loss, blast
   radius) and the mitigation or explicit acceptance for each.
10. **## Migration / rollout / backward-compatibility** (scaled) — schema/data migration, feature
    flags, rollout order, compat guarantees. `_N/A — why_` when the change is additive and
    self-contained.
11. **## Out of scope** (core) — what this design deliberately does not cover (bounds the
    implementation).
12. **## Open questions** (core; MUST be empty to hand off) — genuinely unresolved engineering items as
    `- [ ]`. Any present blocks handoff; resolve them in the grill, or push a genuinely undecidable one
    onto the `specification.md` as a spec-level `- [ ]` for the PM (the design then waits on it).

## Traceability & identifiers

- Every in-scope spec item and user story (`[Uxx]`) appears in **Requirements coverage** (addressed or
  explicitly deferred).
- Reference spec IDs (`[Uxx]` / `[ACxx]` / `[TCxx]`) rather than restating them; a design section that
  duplicates a `specification.md` section **verbatim** should reference it instead (both docs live in
  the same per-Epic folder).
- Where the design proposes changing an AC/TC, it does **not** rewrite the spec's IDs — it records the
  proposal in the spec's `## Engineering review` section (see the command) and references it here.

## Engineering-review edits to the specification

`/design` records spec challenges **into `specification.md`** (not only here): an `## Engineering
review` section plus new `- [ ]` open questions on the spec. When the spec is `Published: yes`,
annotate only — never mutate existing `[Uxx]` / `[ACxx]` / `[TCxx]` IDs (those route through the specs
repo's human change-management). This design doc's **Requirements coverage** cross-references those
spec edits.

## Provenance

Net-new, authored for the dev-workflows plugin — no upstream import source. The grilling technique
`/design` uses to author against this format is embedded in `commands/design.md` (adapted from
mattpocock grill-me/grilling), so `/design` has no runtime plugin dependency.
````

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
f=references/design-format.md
test -f "$f" && echo "EXISTS"
grep -qF '# Design format (embedded authority)' "$f" && echo "TITLE ok"
grep -qF 'decision-dense, scalable' "$f" && echo "PRINCIPLE ok"
grep -qF '**Open questions** MUST be 0' "$f" || grep -qF '`Open questions` MUST be 0 to hand off' "$f" && echo "GATE ok"
for h in '## Context & problem' '## Requirements coverage' '## Architecture & components' '## Interfaces / contracts' '## Seams' '## Data flow' '## Error handling & edge cases' '## Test strategy' '## Risks & mitigations' '## Migration / rollout / backward-compatibility' '## Out of scope' '## Open questions'; do
  grep -qF "$h" "$f" && echo "SECTION ok: $h" || echo "MISSING: $h"
done
grep -qF 'Net-new' "$f" && echo "PROVENANCE ok"
grep -qF '_N/A' "$f" && echo "OMIT-RULE ok"
```
Expected: `EXISTS`, `TITLE ok`, `PRINCIPLE ok`, `GATE ok`, all 12 `SECTION ok`, `PROVENANCE ok`, `OMIT-RULE ok`; no `MISSING`.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/design-format.md
git commit -m "feat(design): add design-format reference (engineering design authority)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: `agents/design-reviewer.md` (Opus review gate)

**Files:**
- Create: `plugins/dev-workflows/agents/design-reviewer.md`

**Interfaces:**
- Consumes: `references/design-format.md` (T1) — reviews against its section rules; the design + spec paths + classification passed by the caller.
- Produces: the `dev-workflows:design-reviewer` agent that `commands/design.md` (T3) Phase 6 dispatches. Verdict schema `PASS` / `PASS WITH RECOMMENDATIONS` / `BLOCK` (same as `spec-reviewer`), so the Phase 6 fix loop can act on it. `model: opus`, not caller-overridable.

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
---
name: design-reviewer
description: Reviews an engineering design.md authored by /design against the design-format authority and traceability to its specification.md — architecture/interface/seam/test-strategy soundness, coverage of every in-scope requirement, and decision-completeness. Treats any unresolved design.md open question as a BLOCKER. Read-only; returns findings + a PASS / PASS WITH RECOMMENDATIONS / BLOCK verdict. Uses Claude Opus.
model: opus
tools: ["Read", "Glob", "Grep", "LS"]
---

Read-only whole-design reviewer for drafts produced by `/design`. Uses the strongest available
reasoning model (Claude Opus). Reads the **whole** `design.md` and its source `specification.md`, and
checks the design against the per-section rules in `${CLAUDE_PLUGIN_ROOT}/references/design-format.md`
plus the cross-cutting checks below. Never edits either file.

Invoked from `/design` Phase 6 after authoring. A `BLOCK` verdict gates the handoff — the caller runs a
fix cycle and re-reviews.

## Input contract

The caller passes:
- **Design path** — absolute path to the `design.md`. Required; if absent, stop and report.
- **Specification path** — absolute path to the source `specification.md` (same per-Epic folder).
  Required for the traceability check; if absent, report that traceability could not be verified.
- **Classification** — `SIMPLE` / `MODERATE` / `SIGNIFICANT` / `HIGH-RISK`. Scales section-inclusion
  expectations (a `SIMPLE` design legitimately omits scaled sections with a one-line `_N/A — why_`; a
  `HIGH-RISK` design must cover them thoroughly). Never flag a section that `design-format.md` says is
  legitimately omittable at this classification.

## Review method

1. Read the design end-to-end, then the specification, before judging.
2. Verify header fields populated; `Classification` is one of the four; **`Open questions` equals the
   actual `- [ ]` count** and — the hard gate — that count is **0** (any unresolved `- [ ]` in
   `design.md` → `BLOCKER`).
3. For each section present, apply that section's rules from
   `${CLAUDE_PLUGIN_ROOT}/references/design-format.md`; for each omitted section, confirm a one-line
   `_N/A — why_` is present and the omission is legitimate at this classification.
4. Apply the cross-cutting checks (below).
5. Record each finding in the shared severity schema; never fabricate a design — route a genuinely
   undecidable item to **needs engineering input** (but note that an undecided item means the design
   is not ready to hand off).

## Cross-cutting checks

- **Traceability (BLOCKER on gap):** every in-scope item and user story (`[Uxx]`) in the specification
  appears in the design's **Requirements coverage** — addressed or explicitly deferred with a reason.
  An in-scope requirement with no coverage → `BLOCKER`.
- **Decision-completeness (BLOCKER):** any unresolved `- [ ]` open question in `design.md`. The design
  is the last gate before code.
- **Interface concreteness:** **Interfaces / contracts** gives real signatures/schemas, not prose
  promises → a vague interface = `MAJOR`.
- **Seam / test-strategy soundness:** **Test strategy** keys to named seams; a testability claim with
  no seam → `MAJOR`. Missing test strategy on a `MODERATE`+ design → `BLOCKER`.
- **Architecture coherence:** components and data flow are consistent; an interface referenced by no
  component (or vice-versa) → `MAJOR`.
- **Risk coverage (SIGNIFICANT/HIGH-RISK):** a risky dimension named in the spec/classification with no
  entry in **Risks & mitigations** → `MAJOR` (`SIGNIFICANT`) / `BLOCKER` (`HIGH-RISK`).
- **Verbatim duplication of the spec:** a design section restating a `specification.md` section verbatim
  instead of referencing it → `MINOR` (both docs live in the same folder; prefer a reference).
- **Challenge coherence:** each challenge recorded in **Requirements coverage** cross-references a real
  `## Engineering review` note / `- [ ]` on the specification; a challenge claimed but not recorded on
  the spec → `MINOR`.
- **Classification fit:** a `HIGH-RISK` design that omits scaled sections without justification →
  `MAJOR`; a `SIMPLE` design padded with empty scaled sections → `NIT`.

## Output contract

Return only findings, no preamble, ordered `BLOCKER` → `MAJOR` → `MINOR` → `NIT`:

```
[BLOCKER|MAJOR|MINOR|NIT] — <Section or Uxx/ACxx reference>
Violation: <what rule is broken and where>
Fix: <concrete recommendation, or "needs engineering input">
```

Then a final line — the verdict:
- `PASS` — no findings above MINOR.
- `PASS WITH RECOMMENDATIONS` — MAJOR/MINOR/NIT only, no BLOCKER.
- `BLOCK` — at least one BLOCKER (includes any unresolved `design.md` open question).

If nothing is actionable, say so and state the classification you reviewed against.

## Gotchas

- A section shown as `_N/A — why_` at `SIMPLE`/`MODERATE` is **not** a defect — it is the format's
  scaling rule. Only flag an omission the classification does not license.
- Test-strategy / design steps may describe how the system is built or exercised — that is design
  intent, not a "describes implementation" defect (implementation detail is expected in a design doc,
  unlike a specification).
- `specification.md`-level open questions are **not** the design's open questions — do not pull them
  into the design's `- [ ]` count. Only unresolved items under the design's own **## Open questions**
  block the handoff.
````

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
f=agents/design-reviewer.md
grep -qE '^name: design-reviewer$' "$f" && echo "NAME ok"
grep -qE '^model: opus$' "$f" && echo "MODEL-OPUS ok"
grep -qE '^tools: \[' "$f" && echo "TOOLS ok"
grep -qF '${CLAUDE_PLUGIN_ROOT}/references/design-format.md' "$f" && echo "CITES design-format ok"
grep -qF 'Specification path' "$f" && echo "INPUT spec-path ok"
grep -qF 'Classification' "$f" && echo "INPUT classification ok"
grep -qF 'Traceability (BLOCKER on gap)' "$f" && echo "TRACEABILITY ok"
grep -qF 'Decision-completeness (BLOCKER)' "$f" && echo "OPENQ-BLOCKER ok"
grep -qF 'PASS WITH RECOMMENDATIONS' "$f" && grep -qF 'BLOCK' "$f" && echo "VERDICT ok"
```
Expected: `NAME ok`, `MODEL-OPUS ok`, `TOOLS ok`, `CITES design-format ok`, `INPUT spec-path ok`, `INPUT classification ok`, `TRACEABILITY ok`, `OPENQ-BLOCKER ok`, `VERDICT ok`.

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/design-reviewer.md
git commit -m "feat(design): add design-reviewer agent (Opus design review gate)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: `commands/design.md` (the Phase 0–7 orchestrator)

**Files:**
- Create: `plugins/dev-workflows/commands/design.md`

**Interfaces:**
- Consumes: `references/jira-input-resolution.md` (shared front-end — `mode`, `jira_key`, `focus_key`); `references/design-format.md` (T1); `agents/design-reviewer.md` (T2, dispatched as `dev-workflows:design-reviewer`); `agents/code-scanner.md` (`dev-workflows:code-scanner`); `references/model-routing/classification.md` (§2/§2.1/§9); `references/escalation-rules.md`; the `dev-workflows:model-routing` skill.
- Produces: the `/design` command. Its Phase 7 writes `design.md` (flat) + the updated `specification.md`; branch `design/<EPIC>-<eslug>` or `design/<VI>-<vslug>`.

- [ ] **Step 1: Write the file** with exactly this content:

````markdown
---
name: design
description: Jira-driven engineering-design workflow (Dev phase). Takes over a merged specification.md from the specs repo's main branch, grounds strictly in the fully-mounted implementation code, and authors a reviewed engineering design.md through a relentless one-question-at-a-time grill that challenges the spec and designs the implementation; gates on the Opus design-reviewer and lands design.md + the spec's engineering-review edits on main via branch + PR for /implement.
allowed-tools: Read Edit Write Bash Glob Grep Task WebFetch LS
---

Author an engineering design for the Jira item: $ARGUMENTS

`/design` is the **Dev-phase engineering-design** workflow — phase 2 of the PM→Dev pipeline
(`/specify` → `specification.md`; then `/design` → `design.md`). The developer *takes over* a merged
`specification.md`, grounds in the **fully-mounted** implementation code, and authors a reviewed
engineering `design.md` through a relentless one-question-at-a-time grill that **challenges** the spec
and **designs** the implementation. It gates on the Opus `design-reviewer` and offers to land
`design.md` + the spec's engineering-review edits on the specs repo's main branch (via branch + PR) so
`/implement` can plan and build from it.

Key distinction from `/specify`: `/specify` (PM) *authors* the requirements spec and grounds lightly
(soft repo gate); `/design` (Dev) *challenges* that spec and *designs* the implementation, and must see
**all** implementation repos — its repo gate is **strict** (hard-stop on any unmounted repo).

---

## Phase 0 — Resolve input

1. **Resolve the Jira input via the shared front-end.** Execute
   `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against `$ARGUMENTS`. `/design` is
   **jira-driven only**: expect `mode: jira-driven`. The front-end owns the `$VAULT_PATH` /
   `jira-products` validation, Fallbacks A/B **and D/E**, and the VI-selector (key-or-directory) +
   focus-Epic grammar. Carry forward:
   - `jira_key` — the resolved **top-level** key: the **VI** when a focus Epic is present, or the
     stand-alone top-level item's own key otherwise. Define `<VI>` = `jira_key`.
   - `focus_key` — the **Epic** to design within its VI, or `null` for a bare VI / stand-alone item /
     directory. Define `<EPIC>` = `focus_key` (may be `null`).

   If the front-end returns `mode: direct`, stop with
   `DESIGN_NEEDS_JIRA: /design needs a Jira key (a VI or an Epic) or an imported-Jira directory.` —
   `/design` has no direct-prompt behaviour. **`/design` uses the front-end only to parse the grammar
   and classify the key; it does NOT call `jira-reader` and does NOT read the Jira export for content —
   the requirements source of truth is the merged `specification.md` in the specs repo.**

2. **Resolve `$SPECS_PATH`.** `/design` reads `specification.md` and writes `design.md` under
   `$SPECS_PATH/specifications/`. If `$SPECS_PATH` is unset, stop with a clear error naming `SPECS_PATH`
   (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).

3. **Map onto the specs repo + require the spec on main.** Derive provisional kebab-case slugs from the
   relevant Jira title(s): `<vslug>` for `<VI>`, and `<eslug>` for `<EPIC>` when `focus_key` is set.
   - **Resolve the VI dir:** `specifications/<VI>-<vslug>/` — honor an existing dir matched by
     key-number (tolerate a stray `-`/`_` after the key and a human-adjusted slug); use the freshly
     derived `<VI>-<vslug>` only if none exists.
   - **Resolve the feature folder + confirm the spec is on main** (the `mgd-specifications` **main**
     branch is the handoff surface — read from a clean main checkout, never a branch), by case:
     - **`focus_key` set** → the per-Epic home `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` (same
       honor-existing tolerance on the `<EPIC>-<eslug>` segment). Require `specification.md` there.
     - **`focus_key` null** → resolved in step 4 (Granularity): either the flat VI dir (stand-alone
       Epic / broad VI spec) or a per-Epic subfolder the picker selects.
   - If the target `specification.md` is not present on main → stop:
     `spec not handed off — run /specify for this item and merge it to the specs repo main first.`

4. **Granularity — the Epic is the unit of work; no fan-out. Progress-aware Epic picker.** One
   `design.md` per invocation. Resolve by `focus_key`:
   - **`focus_key` set** (explicit `<VI> <Epic>` / `<dir> <Epic>`, or a nested-Epic key auto-resolved by
     the front-end) → the Epic is chosen; the feature folder is its per-Epic home. Skip the picker; go
     to step 5.
   - **`focus_key` null** → inspect the resolved VI dir in the specs repo:
     - it holds a **flat `specification.md`** (a stand-alone top-level Epic, or a broad VI-level spec) →
       one design; the feature folder is the VI dir itself. Skip the picker; go to step 5.
     - it holds **Epic subfolders** each with a `specification.md` on main → enumerate those **spec'd**
       Epics (subfolders **without** a merged `specification.md` are not yet designable — exclude them
       and report the excluded count). Then branch on count — this is the reusable **progress-aware
       Epic-picker pattern** in `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`
       (§ Progress-aware Epic picker), applied here with `/design`'s own done-predicate and
       **enumerated from the specs repo** (not `jira-reader`):
       - **exactly 1 spec'd Epic** → no picker; auto-select it; re-point the feature folder to its
         per-Epic subfolder; emit a one-line notice.
       - **≥2 spec'd Epics** → render the picker, one `choices` entry per spec'd Epic (its ○/◐/● marker
         + key + title), then `"Other… (describe)"`. Compute each Epic's state from `/design`'s
         **done-predicate** against that Epic's resolved folder:
         - **○ not started** — a `specification.md` exists there but no `design.md` and no
           `_design-session.md` → selectable.
         - **◐ in progress** — a `_design-session.md` exists there but no `design.md` → selectable as a
           resume (per-Epic stage resume then runs in Phase 5 from that `_design-session.md`).
         - **● done** — a `design.md` exists there → shown greyed, **not** default-selectable; selecting
           offers *revise*.
         Default cursor = the first actionable row (in-progress before not-started). On selecting an
         Epic → set `focus_key` = that Epic and re-point the feature folder to its per-Epic subfolder.
     - neither a flat `specification.md` nor any spec'd Epic subfolder → stop
       (`spec not handed off — run /specify first`).

5. **Detect a prior `/design` run.** If a `_design-session.md` exists in the resolved feature folder,
   record that a resume is available — Phase 1 asks resume-vs-fresh. (Distinct from `/specify`'s
   `_session.md`, which may coexist in the same flat folder.)

`/design` is **cwd-agnostic** — it reads/writes an absolute `$SPECS_PATH`-rooted feature folder and
scans repos under `$REPOS_PATH`; cwd need not be inside either.

---

## Phase 1 — Configure

**Rule: Ask, don't guess. This rule is absolute.** Use `choices` arrays; the last choice in every array
MUST be `"Other… (describe)"`.

1. **Feature folder.** Confirm the path resolved in Phase 0:
   `choices: ["Use <feature_folder> (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]`
2. **Resume vs fresh** (only if step 5 found a `_design-session.md`): read it back and summarise which
   stages are settled:
   `choices: ["Resume — skip settled stages (Recommended)", "Start fresh — discard the prior design session", "Cancel", "Other… (describe)"]`
3. **Repo refresh policy** (governs Phase 4's `code-scanner` dispatches):
   `choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh", "Other… (describe)"]`
4. **Repos search base (`$REPOS_PATH`).** Read `${REPOS_PATH:-/workspace}` (may be colon-separated):
   `choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]`

Also display (context): resolved feature folder; resolved `<VI>` / `<EPIC>` (or 'none — VI-level');
resolved `$SPECS_PATH`; resolved `$REPOS_PATH`.

---

## Phase 1.5 — Classify + tiered model gate

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then classify as
`SIMPLE` / `MODERATE` / `SIGNIFICANT` / `HIGH-RISK`. This single classification scales **grill depth**,
`design.md` **section-inclusion** (per `design-format.md`), and **`design-reviewer` rigor** together.
Resolve per-step routing per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9:

```yaml
model_routing:
  classification: <SIMPLE|MODERATE|SIGNIFICANT|HIGH-RISK>
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # code-scanner
  review_model:    <§2 Opus chain>     # design-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + design.md authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

The grill + authoring run inline on `current_model` (interactive judgment — not a delegated subagent).

**Tiered model gate (stricter than `/implement` — `/design`'s critical synthesis is inline, not an Opus
subagent):**
- **SIGNIFICANT / HIGH-RISK + `current_model` is not an Opus-tier model → HARD gate.** Stop and require
  relaunching `/design` on Opus (the run is resumable from `_design-session.md`):
  `choices: ["I'll relaunch /design on Opus (Recommended)", "Override — proceed on the current model (logged in the final report)", "Cancel", "Other… (describe)"]`
  Design authoring for risky work must be Opus — the Opus `design-reviewer` reviews, it cannot originate
  good architecture.
- **SIMPLE / MODERATE + not Opus → soft advisory.** Recommend Opus but proceed; record the choice in
  `notes` and the final report.
- **Opus session →** proceed (the intended case).

---

## Phase 2 — Read the spec

Read the resolved `specification.md` **fully** (from the specs repo main). Extract the in-scope items,
user stories (`[Uxx]`), acceptance criteria (`[ACxx]`), and test cases (`[TCxx]`) the design must cover
— this is the traceability baseline for **Requirements coverage** and the raw material the grill
challenges. Note the spec's `Published` flag (governs whether Phase 5 may propose ID changes or must
annotate-only) and any existing `- [ ]` open questions (spec-level; tolerated — the design may resolve
or inherit them). **No Jira re-read** — the spec is the requirements source of truth.

---

## Phase 3 — Derive repos + STRICT gate

1. **Auto-derive candidate repos** from the spec's themes / component mentions / any referenced code
   paths. Build the slug→clone map (`/epics`-style): for each top-level dir under each `$REPOS_PATH`
   entry, `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, take the
   URL's last path segment as the slug; skip dirs with no `.git` or a failing/timed-out call.
2. **Confirm the complete set — the developer owns it.** Present the derived candidates and ask the
   developer to confirm the **complete** list of implementation repos this design must span:
   `choices: ["Confirm this set (Recommended)", "Add repos (you'll be prompted)", "Remove repos (you'll be prompted)", "Cancel", "Other… (describe)"]`
3. **Resolve each confirmed repo against the map.** One match → use it. Ambiguous or zero matches
   escalate per the `Repo unresolved (zero matches) — /epics` rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   `choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]`
4. **STRICT mounted gate — hard-stop.** Any repo in the confirmed set that is **not mounted** under
   `$REPOS_PATH` **hard-stops** `/design` (unlike `/specify`'s soft gate): describe the missing
   capability and why the design needs it (you cannot name or link an unmounted repo's code), then:
   `choices: ["I've remounted — re-scan", "Remove this repo from the design's scope (you confirm it's not needed)", "Cancel", "Other… (describe)"]`
   On "remounted", the developer restarts the container with the repo mounted and re-runs `/design`
   (resuming from `_design-session.md`); a design cannot be completed while a confirmed repo is missing
   unless the developer explicitly removes it from scope. Record the confirmed repo set in
   `_design-session.md`.

---

## Phase 4 — Code scan

Spawn `code-scanner` instances in **batches of up to 4 concurrent agents** per Agent message over
**all** confirmed, mounted repos (the scan runs over the full set regardless of classification — only
grill depth / sections / review scale by tier). Wait for each batch before the next.

→ Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Scan this repo for the brief:
  >
  > repo_path:     <resolved absolute path for this repo from Phase 3>
  > repo_url_slug: <repo slug, e.g. "cluster">
  > capability_themes:
  >   [themes derived from the specification]
  > context: |
  >   [3–5 sentences: what the spec requires; what the design must ground — seams, interfaces, gaps]
  > search_hints:
  >   symbols:  [names inferred from the spec, or []]
  >   paths:    [globs inferred from themes, or []]
  >   keywords: [grep keywords from themes]
  > refresh:
  >   switch_to_default_branch: [true if Phase 1 chose 'fetch + pull default branch' or 'fetch only'; false if 'no refresh']
  >   pull: [true only if 'fetch + pull default branch'; false otherwise]"

Handle per-repo status after the batch returns:
- `OK` / `PARTIAL` / `EMPTY` — store the capabilities / seams / interfaces / gaps output; this grounds
  Phase 5's design decisions.
- `REPO_MISSING` — should not occur post-gate; if it does, return to the Phase 3 strict gate for that
  repo.
- `DIRTY_TREE` — escalate per the `Dirty working tree` rule in
  `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
- `REFRESH_BLOCKED` — escalate per the `Refresh blocked` rule in
  `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.

---

## Phase 5 — Grill: challenge + design

**Interview technique (grilling — embedded; no runtime plugin dependency).** Conduct the design as a
relentless interview:
- Ask exactly ONE question at a time; wait for the answer before the next. Never batch questions — a
  firehose is bewildering.
- For every question, give your recommended answer, so the developer reacts to a proposal.
- If a question can be answered from the Phase 4 code scan or the spec, explore and answer it yourself
  instead of asking.
- Walk the design tree in dependency order — resolve a parent decision before dependent ones.
- Continue until you and the developer reach a shared understanding for the section, then write it.

(Technique adapted from mattpocock grill-me/grilling; embedded here so `/design` has no runtime
dependency.)

Run **two intertwined tracks**, authoring `design.md` live against
`${CLAUDE_PLUGIN_ROOT}/references/design-format.md`, sections scaled by the Phase 1.5 classification:

- **Challenge the spec.** Interrogate testability, seams, scope realism, missing cases, and feasibility
  against the real code. Record every substantive challenge **into `specification.md`**: add/extend an
  `## Engineering review` section and new `- [ ]` open questions on the spec. Raise substantive changes
  to ACs/TCs as **proposals** — do not unilaterally rewrite them; when the spec is `Published: yes`,
  **annotate only, never mutate `[Uxx]` / `[ACxx]` / `[TCxx]` IDs** (those route through the specs
  repo's human change-management).
- **Design the implementation.** Author each `design.md` section: Context & problem, Requirements
  coverage (with the challenge notes cross-referencing the spec's `## Engineering review`), Architecture
  & components, Interfaces / contracts, Seams, Data flow, Error handling & edge cases, Test strategy,
  Risks & mitigations, Migration / rollout / backward-compatibility, Out of scope. Omit a
  non-applicable section with a one-line `_N/A — why_`.

As each decision settles, append it to `_design-session.md`; capture a genuinely-ambiguous term in
`_design-glossary.md`. **Resolve `design.md` open questions to zero** — the design is the last gate
before code. A residual engineering unknown that truly cannot be resolved is either (a) pushed onto the
`specification.md` as a spec-level `- [ ]` for the PM (and the design waits on it), or (b) kept as a
`design.md` `- [ ]` that will **block handoff** (Phase 6/7). A repo gap surfacing here → hard-stop (the
Phase 3 strict gate); resumable from `_design-session.md`.

---

## Phase 6 — Review gate

Dispatch `design-reviewer` (Opus):

→ Agent (subagent_type: "dev-workflows:design-reviewer", model: `<review_model — §2 Opus chain; frontmatter-pinned, recorded, no override>`):
  > "Review the design for this brief:
  >
  > Design path:        [absolute path to design.md]
  > Specification path: [absolute path to specification.md]
  > Classification:     [the Phase 1.5 classification]"

**Act on the verdict** (mirrors `/specify`):
- **`BLOCK`** — fix the BLOCKER findings (the orchestrator/grill edits `design.md` inline — no delegated
  writer) and re-review once. **Any unresolved `design.md` `- [ ]` is a BLOCKER by policy** — resolve it
  or push it onto the spec (Phase 5) before handoff. If still `BLOCK`, escalate per the
  `Review verdict BLOCK (unresolved after one fix cycle) — /epics` rule in
  `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`, per unresolved BLOCKER individually:
  `choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in the final report)", "Override and accept the finding", "Cancel the whole run", "Other… (describe)"]`
- **`MAJOR` / `MINOR` / `NIT`** (surfaced under `PASS WITH RECOMMENDATIONS`) — defer to the final
  report; no mandatory fix cycle.
- **`PASS`** / **`PASS WITH RECOMMENDATIONS`** — proceed to Phase 7.

Cap: one fix cycle + one re-review maximum. Phase 7 will not hand off a `design.md` with any unresolved
`- [ ]`.

---

## Phase 7 — Handoff

Write the feature folder: `design.md` (flat, alongside `specification.md`), the updated
`specification.md` (its `## Engineering review` + open-question edits), `_design-session.md`, and
`_design-glossary.md`. **Refuse to proceed if `design.md` has any unresolved `- [ ]`** (the
decision-completeness gate).

Then **offer** (commit-when-asked — never automatic):
`choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git", "Cancel"]`

On the first choice, in the specs repo (`$SPECS_PATH`): create the branch — `design/<EPIC>-<eslug>` for
a **per-Epic** or **stand-alone-Epic** design (`<EPIC>` = `focus_key`, which for a stand-alone Epic
equals `jira_key`), or `design/<VI>-<vslug>` for a **broad VI-level** design (`focus_key` null). Epic
keys are globally unique, so the per-Epic form needs no VI prefix; both forms use hyphens. main is
protected — a PR is required — so commit ONLY the feature folder (never `git add -A`), push, and open a
PR targeting `main`. **Merged-to-main = ready for `/implement`.** Commit trailer:
`Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

### Next Epic (after a per-Epic design from a multi-Epic VI)

When this run designed a per-Epic Epic selected from Phase 0's ≥2-Epics picker, offer — once the
write/commit completes:
`choices: ["Next Epic — re-open the picker (Recommended)", "Stop here", "Other… (describe)"]`
On **"Next Epic"**, re-render the Phase 0 picker **minus the just-completed Epic** (recompute each
remaining Epic's ○/◐/● state — the freshly-authored design now shows **● done** and drops out of the
actionable set), then, on selection, loop back through Phases 2–7 for the selected Epic. This offer does
not apply to a stand-alone Epic, a single-Epic VI, or a broad VI-level design.

## Final report

Report: feature-folder path; classification + model-gate outcome; `design.md` sections authored (and
those `_N/A_`); spec challenges recorded (count of `## Engineering review` notes / new spec `- [ ]`);
confirmed repo set (and any removed-from-scope); the `design-reviewer` verdict; the PR URL (if opened);
and "run `/implement <VI> <Epic>` next."
````

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
f=commands/design.md
grep -qE '^name: design$' "$f" && echo "NAME ok"
grep -qE '^allowed-tools: ' "$f" && echo "TOOLS ok"
for a in '## Phase 0 — Resolve input' '## Phase 1 — Configure' '## Phase 1.5 — Classify' '## Phase 2 — Read the spec' '## Phase 3 — Derive repos + STRICT gate' '## Phase 4 — Code scan' '## Phase 5 — Grill' '## Phase 6 — Review gate' '## Phase 7 — Handoff'; do
  grep -qF "$a" "$f" && echo "PHASE ok: $a" || echo "MISSING PHASE: $a"
done
grep -qF '${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md' "$f" && echo "CITES input-resolution ok"
grep -qF '${CLAUDE_PLUGIN_ROOT}/references/design-format.md' "$f" && echo "CITES design-format ok"
grep -qF '${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md' "$f" && echo "CITES model-routing ok"
grep -qF '${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md' "$f" && echo "CITES escalation ok"
grep -qF 'DESIGN_NEEDS_JIRA' "$f" && echo "REJECT-DIRECT ok"
grep -qF 'focus_key' "$f" && echo "FOCUS_KEY ok"
grep -qF 'progress-aware' "$f" && grep -qF '○ not started' "$f" && echo "PICKER ok"
grep -qF 'STRICT mounted gate — hard-stop' "$f" && echo "STRICT-GATE ok"
grep -qF 'dev-workflows:code-scanner' "$f" && echo "CODE-SCANNER ok"
grep -qF 'dev-workflows:design-reviewer' "$f" && echo "DESIGN-REVIEWER ok"
grep -qF 'HARD gate' "$f" && echo "MODEL-GATE ok"
grep -qF 'design/<EPIC>-<eslug>' "$f" && grep -qF 'design/<VI>-<vslug>' "$f" && echo "BRANCH ok"
grep -qF '_design-session.md' "$f" && grep -qF '_design-glossary.md' "$f" && echo "NAMESPACED ok"
grep -qF 'grill-me/grilling' "$f" && echo "GRILL-EMBEDDED ok"
[ "$(grep -c 'subagent_type: "dev-workflows:jira-reader"' "$f")" = "0" ] && echo "NO jira-reader dispatch ok" || echo "FAIL: jira-reader is dispatched"
```
Expected: `NAME ok`, `TOOLS ok`, all 9 `PHASE ok`, all four `CITES … ok`, `REJECT-DIRECT ok`, `FOCUS_KEY ok`, `PICKER ok`, `STRICT-GATE ok`, `CODE-SCANNER ok`, `DESIGN-REVIEWER ok`, `MODEL-GATE ok`, `BRANCH ok`, `NAMESPACED ok`, `GRILL-EMBEDDED ok`, `NO jira-reader dispatch ok`. (The file mentions `jira-reader` only in the "does NOT call `jira-reader`" note — the check confirms there is **no** actual dispatch.)

- [ ] **Step 3: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/design.md
git commit -m "feat(design): add /design command (Dev-phase engineering-design orchestrator)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: `/implement` design-doc open-question guard (one additive touch)

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md` (Phase 0 "Rules:" list — add one bullet after the primary-description rule)

**Interfaces:**
- Consumes: nothing new — reads the primary description `/implement` already loads in Phase 0.
- Produces: the cross-command enforcement of "no implementation on an unresolved design" (the design-side of this policy is `design-reviewer` in T2). Purely additive — no existing behaviour changes.

- [ ] **Step 1: Add the guard bullet.** In `plugins/dev-workflows/commands/implement.md`, locate the Phase 0 `Rules:` list. After the bullet that begins `- The **primary description** is:` (ends with `confirm "Loaded prompt (N lines)."`) and before `- Multiple inputs of the same kind are allowed.`, insert this new bullet:

```markdown
- **Design-doc open-question guard.** If the primary description is a **design doc** — a file named
  `design.md` or matching `*-design.md` (the `/design` output; distinct from a `specification.md`) —
  scan it for unresolved `- [ ]` open questions under its `## Open questions` heading. If any exist,
  **refuse to proceed**:
  `choices: ["Cancel — resolve the design's open questions in /design first (Recommended)", "Override and implement anyway (logged in the Phase 5 report)", "Other… (describe)"]`
  A design must be decision-complete before implementation (enforced upstream by `design-reviewer`;
  this is the cross-command backstop). **`specification.md`-level open questions are exempt** — they are
  the spec's way of flagging what the design phase resolves, and a design doc may legitimately
  incorporate a spec that still carries them. "Override" is the only escape and is recorded in the
  Phase 5 report's `### Assumptions & limitations`.
```

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
f=commands/implement.md
grep -qF 'Design-doc open-question guard' "$f" && echo "GUARD ok"
grep -qF 'matching `*-design.md`' "$f" && echo "DETECT ok"
grep -qF '`specification.md`-level open questions are exempt' "$f" && echo "SPEC-EXEMPT ok"
grep -qF 'Override and implement anyway (logged' "$f" && echo "OVERRIDE-LOGGED ok"
# Placement: guard appears after the primary-description rule and before the "Multiple inputs" rule
awk '/The \*\*primary description\*\* is:/{p=NR} /Design-doc open-question guard/{g=NR} /Multiple inputs of the same kind/{m=NR} END{ if (p<g && g<m) print "ORDER ok"; else print "ORDER WRONG p="p" g="g" m="m }' "$f"
```
Expected: `GUARD ok`, `DETECT ok`, `SPEC-EXEMPT ok`, `OVERRIDE-LOGGED ok`, `ORDER ok`.

- [ ] **Step 3: Confirm no other Phase 0 behaviour changed** (byte-diff review):
```bash
cd /workspace/ihudak-claude-plugins
git diff --stat plugins/dev-workflows/commands/implement.md   # expect: 1 file changed, ~10 insertions, 0 deletions
git diff plugins/dev-workflows/commands/implement.md          # eyeball: only the new bullet added
```
Expected: additions only (no deletions/modifications to existing lines).

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/implement.md
git commit -m "feat(implement): guard against implementing a design doc with open questions

Cross-command backstop for /design's decision-completeness policy: refuse (override-only,
logged) when the loaded design doc has unresolved - [ ] items. specification.md-level open
questions remain exempt.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Release v2.6.0 (version lock-step + CHANGELOG + README surfaces)

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (`version` → `2.6.0`)
- Modify: `.claude-plugin/marketplace.json` (repo root — `plugins[0].version` → `2.6.0`; siblings untouched)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (prepend the `## [2.6.0]` block)
- Modify: `plugins/dev-workflows/README.md` (add `/design` command-list row + `design-reviewer` subagent-table row; recompute the workflow-command count, the classifier-count sentence, the subagent count, and the Opus-gate count)
- Modify: `README.md` (repo root — add `/design` to the dev-workflows command list)

**Interfaces:**
- Consumes: the three new assets (T1–T3) + the T4 touch exist and are committed.
- Produces: the shipped v2.6.0 surface. This task is last — it reflects everything above.

- [ ] **Step 1: Bump `plugin.json`.** In `plugins/dev-workflows/.claude-plugin/plugin.json`, change `"version": "2.5.0"` → `"version": "2.6.0"`.

- [ ] **Step 2: Bump `marketplace.json`.** In the repo-root `.claude-plugin/marketplace.json`, change the **dev-workflows** entry's `"version": "2.5.0"` → `"version": "2.6.0"`. Leave `dt-style-guide` (0.2.2) and `obsidian-llm-wiki` (0.3.1) untouched.

- [ ] **Step 3: Prepend the CHANGELOG block.** In `plugins/dev-workflows/CHANGELOG.md`, insert directly **above** the `## [2.5.0] — 2026-07-08` line:

```markdown
## [2.6.0] — 2026-07-08

### Added

- **`/design` — Jira-driven engineering design authoring (Dev phase).** The developer take-over half of the PM→Dev pipeline: reads a merged `specification.md` from the specs repo's main branch, grounds strictly in the fully-mounted implementation code (a **hard** repo gate — any unmounted repo in the confirmed set stops the run until remounted, unlike `/specify`'s soft gate), and authors an engineering `design.md` through a relentless one-question-at-a-time grill that both **challenges** the spec (recording an `## Engineering review` section + `- [ ]` open questions back onto `specification.md`) and **designs** the implementation. A single complexity classification scales grill depth, `design.md` section-inclusion, and reviewer rigor together; a **tiered model gate** hard-stops SIGNIFICANT/HIGH-RISK work that is not running on Opus (the critical synthesis is inline, not a subagent). Consumes the shared front-end's `focus_key`; for a multi-Epic VI it renders the progress-aware Epic picker (○/◐/●, done-predicate `design.md` exists) enumerated from the specs repo, and offers a Next-Epic loop. Writes `design.md` **flat** in the per-Epic home `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` (durable/resumable via `_design-session.md` + `_design-glossary.md`, namespaced to coexist with `/specify`'s session files), gates on the new Opus `design-reviewer`, and offers a branch+PR handoff (`design/<EPIC>-<eslug>` / `design/<VI>-<vslug>`) to the specs repo's main for `/implement`. `design.md` open questions **hard-block** handoff (opposite of `specification.md`, where they are tolerated). New assets: `commands/design.md`, `references/design-format.md` (net-new format authority), `agents/design-reviewer.md` (Opus). `/design` uses the shared Jira-input front-end only to parse the grammar — it does not read Jira content (`jira-reader` is not used).
- **`/implement` refuses to implement a design doc with unresolved open questions.** A cross-command backstop for `/design`'s decision-completeness policy: when the primary description is a design doc (`design.md` / `*-design.md`) with unresolved `- [ ]` items, `/implement` stops (override-only, logged in the Phase 5 report). `specification.md`-level open questions remain exempt.
```

- [ ] **Step 4: Update `plugins/dev-workflows/README.md`.**
  1. **Summary line (line ~3):** change `Eight workflow slash commands` → `Nine workflow slash commands`, and add `engineering design authoring,` to the purpose list (immediately after `specification authoring,`).
  2. **Command list — add a `/design` row** immediately after the `/specify` row:
     ```markdown
     | `/design <VI-KEY \| Epic-KEY \| jira-export-dir> [focus-Epic-KEY]` | Jira-driven engineering design authoring (Dev phase). Takes over a merged `specification.md` from the specs repo's main branch and authors a reviewed engineering `design.md` through a relentless one-question-at-a-time grill that **challenges** the spec (recording an `## Engineering review` section + open questions back onto it) and **designs** the implementation, grounded strictly in the fully-mounted code (hard repo gate — unmounted repos stop the run). Accepts the shared Jira-input grammar (`<VI> <Epic>` / `<dir> <Epic>`); for a multi-Epic VI it renders the progress-aware Epic picker (done-predicate `design.md` exists). A tiered model gate hard-stops SIGNIFICANT/HIGH-RISK work not on Opus. Durable/resumable via `_design-session.md` + `_design-glossary.md`; gated by Opus `design-reviewer`; `design.md` open questions hard-block handoff; offers a branch+PR handoff (`design/<EPIC>-<eslug>` / `design/<VI>-<vslug>`) to the specs repo's main for `/implement`. Does not read Jira content — the spec is the source of truth. |
     ```
  3. **Classifier-count sentence (line ~19):** change `Five of the six dev-workflows commands — \`/implement\`, \`/document\`, \`/epics\`, \`/release-notes\`, and \`/specify\` — classify` → `Six of the seven dev-workflows commands — \`/implement\`, \`/document\`, \`/epics\`, \`/release-notes\`, \`/specify\`, and \`/design\` — classify`, and (in the parenthetical) add `; \`/design\` Phase 1.5 scales grill/section/review depth and gates the model tier` after the `/specify` note.
  4. **Subagent intro (line ~123):** recompute the reusable-subagent count from `ls plugins/dev-workflows/agents/*.md` (it is currently `Twenty-five` → becomes `Twenty-six` with `design-reviewer` added); change `The five Opus-backed reviewers/planners are pinned` → `The six Opus-backed reviewers/planners are pinned`.
  5. **Subagent table — add a `design-reviewer` row** immediately after the `spec-reviewer` row:
     ```markdown
     | `design-reviewer` | Opus | Engineering-design reviewer for `/design` — validates `design.md` against the `design-format` authority (section inclusion scaled by classification) and traceability to its `specification.md` (every in-scope requirement covered; BLOCKER on a gap), plus interface concreteness, seam/test-strategy soundness, architecture coherence, and risk coverage. Treats any unresolved `design.md` `- [ ]` open question as a BLOCKER. Verdict: PASS / PASS WITH RECOMMENDATIONS / BLOCK. |
     ```
  6. **Opus-gate sentence (line ~153):** change `the five Opus gates (\`risk-planner\`, \`code-review\`, \`doc-reviewer\`, \`epic-reviewer\`, \`spec-reviewer\`)` → `the six Opus gates (\`risk-planner\`, \`code-review\`, \`doc-reviewer\`, \`epic-reviewer\`, \`spec-reviewer\`, \`design-reviewer\`)`.

- [ ] **Step 5: Update the repo-root `README.md`.** In the `dev-workflows` marketplace row, add `/design` to the command list and add a purpose clause. Change the command list to include `/design` (e.g. after `/specify`) and add `, engineering design authoring` to the purpose prose.

- [ ] **Step 6: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json;print('plugin', json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])"
python3 -c "import json;d=json.load(open('.claude-plugin/marketplace.json'));print([(p['name'],p['version']) for p in d['plugins']])"
grep -qF '## [2.6.0] — 2026-07-08' plugins/dev-workflows/CHANGELOG.md && echo "CHANGELOG ok"
grep -qF 'Nine workflow slash commands' plugins/dev-workflows/README.md && echo "COUNT ok"
grep -qF '`/design ' plugins/dev-workflows/README.md && echo "CMD-ROW ok"
grep -qF '`design-reviewer` | Opus |' plugins/dev-workflows/README.md && echo "AGENT-ROW ok"
grep -qF 'six Opus gates' plugins/dev-workflows/README.md && echo "OPUS-GATES ok"
grep -qF '/design' README.md && echo "ROOT-README ok"
# Subagent count sanity: number of agent files
echo "agent files: $(ls plugins/dev-workflows/agents/*.md | wc -l)"   # confirm the README word-count matches
```
Expected: `plugin 2.6.0`; marketplace shows `dev-workflows 2.6.0` with `dt-style-guide 0.2.2` / `obsidian-llm-wiki 0.3.1` unchanged; `CHANGELOG ok`, `COUNT ok`, `CMD-ROW ok`, `AGENT-ROW ok`, `OPUS-GATES ok`, `ROOT-README ok`. Confirm the agent-file count matches the word used in the README subagent intro (recompute — do not assume).

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md README.md
git commit -m "chore(release): dev-workflows v2.6.0 (/design command + design-reviewer)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Post-implementation (controller — after all tasks)

- Whole-branch review on the most capable model (Opus) via `superpowers:requesting-code-review` `code-reviewer.md`, pointed at the branch package (`scripts/review-package $(git merge-base main HEAD) HEAD`) + the Minor-findings roll-up.
- Then `superpowers:finishing-a-development-branch` — present the merge/PR options; commit/push only when the user asks.
- Update the SDD ledger (`/workspace/docs/.superpowers/sdd/progress.md`) per task and at the end; update `docs/superpowers/harvest/NEXT.md` when shipped (mark `/design` v2.6.0 done; the next backlog item becomes the grammar-adoption effort for the shipped Jira-driven commands).
