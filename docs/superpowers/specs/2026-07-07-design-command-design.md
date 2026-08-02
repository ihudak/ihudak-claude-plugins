# `/design` — Dev Take-over (design) 

**Date:** 2026-07-07
**Repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`
**Effort:** net-new command. Phase 2 (Dev) of the PM→Dev pipeline; sibling of `/specify` (v2.4.0).
**Version target:** MINOR **2.5.0 → 2.6.0** (v2.5.0 was the shipped foundation).
**Spec/plan home:** this vault (`Projects/AI-First/dev-workflows - docs automation/{spec,plan}/`).

> **✅ FOUNDATION SHIPPED (v2.5.0, 2026-07-08).** `/design`'s prerequisite — the shared
> **`<VI> <Epic>` two-key input grammar** in `jira-input-resolution`, the **per-Epic specs-repo
> convention**, and the **`/specify` fix** — merged to `main` (@ `8e53830`). This doc was **reconciled
> to the shipped foundation on 2026-07-08** (see the *Reconciliation* section at the end): **hyphen**
> delimiters everywhere (`<VI>-<vslug>/<EPIC>-<eslug>/`, not underscore); the per-Epic `design.md` lands
> **flat** in that folder (not under a `spec/` subfolder); durable files are namespaced
> `_design-session.md`/`_design-glossary.md` (the flat folder is shared with `/specify`'s
> `_session.md`); `/design` **consumes `focus_key`** and, for a multi-Epic VI, renders the shipped
> **progress-aware Epic picker** (mirroring `/specify`) rather than merely guiding a manual re-run; and
> `/design` ships as **v2.6.0** (v2.5.0 was the foundation).

## Context & motivation

`/specify` (v2.4.0) is the PM half of a deliberate PM→Dev split: a PM authors a `specification.md`
(problem/scope/user-stories/AC/test-cases) and lands it on the `mgd-specifications` main branch.
`/design` is the **Dev half** — the developer *takes over* the merged spec and produces the
engineering design that implementation flows from.

The ownership rationale (from the `/specify` brainstorm): development teams own the consequences of
the code — bugs, incidents, on-call — so the **engineering-facing** artifacts must be produced by the
dev phase, not thrown over the wall by the PM's AI. `/design` is where the dev, grounded in the real
code, **challenges** the PM's spec and **designs** the implementation.

### Why this is better than the generic alternatives

`/design` blends the two lineages and adds what neither has:
- **superpowers:brainstorming** writes a design doc but with loose prose structure, **no checkable
  schema, and no reviewer** — quality is model-dependent and drifts.
- **mattpocock `to-prd`** has seams/test-strategy but is a **single-pass PRD synthesis — no interview,
  no challenge, no review gate** — and excludes implementation detail.
- **`grill-me`/`grilling`** is the interview technique but produces **no artifact**.

`/design` takes the grilling **interview rigor** + to-prd's **seams/test-strategy** forwardness, and
adds three things that are new here: **(a)** it grounds in the **fully-mounted implementation code**,
not a greenfield sketch; **(b)** it **adversarially challenges a real, PM-reviewed spec**; **(c)** it
is **codified + Opus-reviewed** so quality is a system property, not luck. The codified format is
**scalable and decision-dense** ("include a section only when it carries a real engineering decision;
omit N/A with a one-line why") — sharper than a freeform doc, lighter than a fill-every-box template.

## Goal

Given an Epic key whose `specification.md` is merged on the specs repo's main branch, produce a
reviewed engineering **`design.md`** — grounded in the fully-mounted code, with the spec's weaknesses
challenged and recorded back — and land it on main via branch+PR so `/implement` can plan and build
from it.

## Non-goals / out of scope

- Producing a `plan.md` / planning — deferred to `/implement` (its own risk-classified planner) or to
  `superpowers:writing-plans`.
- Implementing / writing code — that is `/implement`.
- Re-reading Jira — the `specification.md` is the requirements source of truth.
- The PM `/specify` half (shipped as v2.4.0).
- Any runtime dependency on the specs repo's `.claude`.

## Decisions (locked during brainstorming)

| Area | Decision |
|---|---|
| Output | `design.md` **only** — no `plan.md`. `/implement` (or `writing-plans`→SDD) owns planning. |
| Spec challenges | Recorded **into `specification.md`** — an `## Engineering review` section + new `- [ ]` open questions; raise substantive changes as proposals, don't unilaterally rewrite AC/TC; when `Published: yes`, annotate only, never mutate IDs (those route through change-management). PM sees them via the branch+PR. |
| `design.md` format | Codified **`references/design-format.md`** (net-new, ours) — scalable, decision-dense. Authored by the grill; validated by a new **`design-reviewer` (Opus)** gate. |
| Depth | One **classification** (`SIMPLE`/`MODERATE`/`SIGNIFICANT`/`HIGH-RISK`, Phase 1.5) scales grill depth, `design.md` section-inclusion, and reviewer rigor together. |
| Repo gate | **Strict** — derive candidates, the **developer confirms the complete set**, any unmounted → hard-stop + escalate + remount + re-run. |
| Input | **`<VI> <Epic>`** two-key grammar (shipped v2.5.0) → reads `specification.md` from `mgd-specifications` **main** at `specifications/<VI>-<vslug>/<EPIC>-<eslug>/`. Consumes `focus_key`. Single-key `<VI>` with ≥2 spec'd Epics → **progress-aware Epic picker** (done-predicate = `design.md` exists); 1 spec'd Epic → auto-select; stand-alone/top-level Epic → design directly. Does **not** re-read Jira. |
| Output location / handoff | `design.md` **flat** at the per-Epic home `…/<VI>-<vslug>/<EPIC>-<eslug>/design.md` (alongside `/specify`'s `specification.md`); **one branch+PR to main** carries `design.md` + the spec's engineering-review edits. Merged = ready for `/implement`. |
| Durability | `_design-session.md` + `_design-glossary.md` (namespaced — the flat per-Epic folder is shared with `/specify`'s `_session.md`/`_glossary.md`), resumable across remount re-runs. |
| Model routing | `code-scanner` → Sonnet; grill + `design.md` authoring → session model (orchestrator, interactive); `design-reviewer` → Opus (pinned). **Tiered model gate:** SIGNIFICANT/HIGH-RISK → **hard gate** (Opus required for the session); SIMPLE/MODERATE → advisory. |
| Open-question policy | `specification.md` open questions tolerated (dialogue). `design.md` open questions **hard-block**: `design-reviewer` BLOCKER + Phase 7 won't hand off; and `/implement` refuses on a design doc with unresolved `- [ ]` (spec-level exempt; logged override only). The **Epic is the unit of work** — no VI fan-out. |

## Command surface

```
/design <VI> <Epic>        # common case: Epic nested under its VI
/design <KEY>              # a top-level item: a VI (→ Epic picker if ≥2 spec'd Epics) or a stand-alone Epic
/design <dir> <Epic>       # jira-export directory + Epic key (no $VAULT_PATH needed) — shared-grammar form
```

Jira-driven only; uses the shared `references/jira-input-resolution.md` **two-key grammar** (shipped
v2.5.0) to parse `$ARGUMENTS`, classify the VI selector, and return `jira_key` (`<VI>`) + `focus_key`
(`<EPIC>`). The front-end is used only for grammar/classification — `/design` reads the actual spec
from the **specs repo**, not the Jira export. Rejects `mode: direct` (`DESIGN_NEEDS_JIRA`).

## `design.md` structure (`references/design-format.md`)

Scalable, decision-dense sections:

- **Context & problem** — brief, from the spec.
- **Requirements coverage** — traceability to the spec's in-scope items / user stories / ACs, with
  challenges noted (what was validated, what was questioned).
- **Architecture & components**.
- **Interfaces / contracts** — signatures, APIs, schemas.
- **Seams** — where the change is tested; prefer the highest seam (to-prd discipline).
- **Data flow**.
- **Error handling & edge cases**.
- **Test strategy** — what/how tested; prior art in the codebase.
- **Risks & mitigations**.
- **Migration / rollout / backward-compatibility** (if applicable).
- **Out of scope**.
- **Open questions** — genuinely unresolved items as `- [ ]`.

Inclusion rule: `SIMPLE` → core sections only (context, requirements coverage, architecture,
interfaces, test strategy, open questions); `SIGNIFICANT`/`HIGH-RISK` → all sections, thorough. Every
omitted section carries a one-line "N/A — why".

## Architecture / components

**New assets:**
- `commands/design.md` — the orchestrator (Phases 0–7; embeds the grilling technique inline).
- `references/design-format.md` — the engineering-design format authority (net-new, authored here — no
  import source; this is ours).
- `agents/design-reviewer.md` — Opus-pinned reviewer; validates `design.md` against
  `design-format.md` **and** traceability to the spec (every in-scope requirement addressed). Emits
  `BLOCKER/MAJOR/MINOR/NIT` + `PASS / PASS WITH RECOMMENDATIONS / BLOCK` (same schema as
  `spec-reviewer`/`epic-reviewer` so the Phase 6 fix loop can act on it).

**Reused (existing):** `references/jira-input-resolution.md`, `agents/code-scanner.md`,
`references/model-routing/classification.md`, `references/escalation-rules.md`, and the embedded
grilling technique (from the `/specify` pattern). `jira-reader` is **not** used.

**Durable artifacts (in the per-Epic feature folder):** `_design-session.md` (decisions + open
questions + confirmed repo set + stage progress), `_design-glossary.md` (ambiguous terms only).
Namespaced with a `_design-` prefix because the flat per-Epic folder is shared with `/specify`'s
`_session.md`/`_glossary.md` — reusing those names would collide and make `/design`'s picker
misread `/specify`'s in-progress state as its own.

## Model routing

The grill + `design.md` authoring run **inline on the orchestrator (the session model)** — NOT a
delegated subagent — because the interview is interactive (turn-by-turn with the developer) and
authoring is interleaved with it; a subagent cannot conduct a live interview. "Session model" =
whatever model the developer launched `/design` under (user-chosen at invocation); it is NOT forced to
Opus.

- `code-scanner` (Phase 4) → §2.1 Sonnet detection chain (delegated, mechanical).
- Grill + authoring (Phase 5) → `current_model` (session model).
- `design-reviewer` (Phase 6) → §2 Opus chain, frontmatter-pinned (recorded, no override) — the
  **quality backstop**: even if the grill ran on a non-Opus session, the Opus reviewer validates the
  design.
- **Tiered model gate (why this is stricter than `/implement`):** in `/implement` the critical
  synthesis (the plan) is an Opus-pinned *subagent*, so a Sonnet session still gets Opus judgment on
  the hard decisions. In `/design` the critical synthesis (challenge + design) is done **inline by the
  orchestrator** (the interview is interactive — it can't be a subagent), and the Opus
  `design-reviewer` only *reviews*, it doesn't author. So the session model directly determines design
  quality. Therefore:
  - **SIGNIFICANT / HIGH-RISK + session not on an Opus-tier model → HARD gate:** stop and require
    relaunching `/design` on Opus (resumable via `_design-session.md`). Design authoring for risky work must
    be Opus — a review can't originate good architecture.
  - **SIMPLE / MODERATE + not Opus → soft advisory:** recommend Opus, but proceed on the session model
    (the grill is short; the Opus `design-reviewer` backstops). Record the choice in the report.
  - **Opus session →** proceed (the intended case).

## Phase flow

- **Phase 0 — Resolve input.** Resolve via the shared **`<VI> <Epic>` grammar** (shipped v2.5.0,
  `references/jira-input-resolution.md`): the front-end parses `$ARGUMENTS`, classifies the VI selector
  (VI JiraID / nested-Epic key / jira-export directory), and returns `jira_key` (= `<VI>`) + `focus_key`
  (= `<EPIC>`, or `null`). Reject `mode: direct` (`DESIGN_NEEDS_JIRA`). Then map onto the specs repo:
  the VI dir `specifications/<VI>-<vslug>/` on `mgd-specifications` **main**, honoring an existing dir
  matched by key-number (tolerate a stray `-`/`_` and a human-adjusted slug), and — when `focus_key` is
  set — the per-Epic home `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` and its `specification.md`. If
  the target `specification.md` isn't on main → stop ("spec not handed off — run `/specify` first").
  Re-detect a prior `/design` run: a `_design-session.md` in the resolved folder → Phase 1 offers
  **resume** vs **fresh**. (`/design` reads the spec from the specs repo, not the Jira export — the
  front-end is used only to parse the grammar and classify the key; `jira-reader` is **not** used.)
  - **Granularity (the Epic is the unit of work; no fan-out) — progress-aware Epic picker.** One
    `design.md` per invocation. Resolve by `focus_key`:
    - **`focus_key` set** (explicit `<VI> <Epic>` / `<dir> <Epic>`, or a nested-Epic key auto-resolved
      by the front-end) → the Epic is chosen; design it directly (no picker).
    - **`focus_key` null** → inspect the resolved VI dir in the specs repo:
      - it holds a **flat `specification.md`** (a stand-alone top-level Epic, or a broad VI-level spec)
        → one design; proceed directly.
      - it holds **Epic subfolders** each with a `specification.md` on main (a VI split per Epic) →
        enumerate those **spec'd** Epics (subfolders **without** a merged `specification.md` are not yet
        designable — exclude them, report the count). Then, mirroring shipped `/specify` Phase 2 Step A
        (the shared **progress-aware Epic-picker pattern**, here **enumerated from the specs repo**, not
        via `jira-reader`), branch on count:
        - **exactly 1 spec'd Epic** → no picker; auto-select it; re-point the feature folder to its
          per-Epic subfolder.
        - **≥2 spec'd Epics** → render the picker, one row per spec'd Epic, status from `/design`'s
          **done-predicate** against that Epic's folder: **○ not started** (no `design.md`, no
          `_design-session.md`) → selectable; **◐ in progress** (`_design-session.md` present, no
          `design.md`) → resume; **● done** (`design.md` present) → greyed, not default-selectable,
          selecting offers *revise*. Default cursor = first actionable. After finishing one Epic's
          design, offer **"Next Epic — re-open the picker (minus the just-completed Epic) / Stop here"**,
          recomputing each remaining Epic's ○/◐/● state (mirrors `/specify`'s Next-Epic loop). No VI
          fan-out — the picker walks Epics one at a time under human control.
      - neither a flat spec nor any spec'd Epic subfolder → stop ("spec not handed off — run `/specify`
        first").
- **Phase 1 — Config.** Confirm folder; repo-refresh policy; resume-vs-fresh.
- **Phase 1.5 — Classify.** Load `model-routing`; classify `SIMPLE`/`MODERATE`/`SIGNIFICANT`/
  `HIGH-RISK`; this sets grill depth, `design.md` section-inclusion, and reviewer rigor. Emit the
  `model_routing` block; fire the relaunch-on-Opus advisory for the high tiers if the session isn't
  Opus.
- **Phase 2 — Read the spec.** Read `specification.md` fully; extract in-scope items / user stories /
  ACs the design must cover. (No Jira re-read.)
- **Phase 3 — Derive repos + STRICT gate.** Derive candidate repos from spec themes/component
  mentions; **ask the developer to confirm the complete set** (they own it). Build the slug→clone map
  (`/epics`-style). Any repo in the confirmed set that is **unmounted → hard-stop**: escalate
  (describe the missing capability + why; cannot name/link an unmounted repo), the developer remounts
  (container restart), and re-runs `/design` — resuming from `_design-session.md`.
- **Phase 4 — Code scan.** `code-scanner` (batches ≤4 concurrent) over **all** confirmed repos, depth
  scaled by classification → existing capabilities, seams, interfaces, gaps.
- **Phase 5 — Grill: challenge + design.** Embedded grilling (one question at a time, recommended
  answer each, explore-code-to-self-answer, walk the design tree). Two intertwined tracks: **challenge
  the spec** (testability, seams, scope realism, missing cases) → record into `specification.md`'s
  `## Engineering review` + open questions; **design the implementation** → author `design.md` against
  `references/design-format.md`. Append settled decisions to `_design-session.md`, ambiguous terms to
  `_design-glossary.md`. A repo gap surfacing here → hard-stop (resumable).
- **Phase 6 — Review gate.** `design-reviewer` (Opus) validates `design.md` against
  `design-format.md` **and** traceability (every in-scope requirement addressed; challenges coherent).
  Fix loop scaled by classification (BLOCKER/MAJOR fixed + re-reviewed; MINOR/NIT deferred to report).
- **Phase 7 — Handoff.** Write `design.md` (flat in the per-Epic folder, alongside `specification.md`)
  + the updated `specification.md`; **offer** (commit-when-asked — never automatic): create the branch —
  `design/<EPIC>-<eslug>` for a per-Epic or stand-alone-Epic design, or `design/<VI>-<vslug>` for a
  broad VI-level design (hyphen delimiters, mirroring shipped `/specify`; Epic keys are globally unique,
  so the per-Epic form needs no VI prefix). main is protected — commit ONLY the feature folder (never
  `git add -A`), push, open **one PR** targeting main. Commit trailer
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Merged-to-main = ready for
  `/implement`. Final report (design-folder path, classification, sections authored, spec challenges
  recorded, `design-reviewer` verdict, PR URL) + "run `/implement <VI> <Epic>` next." After a per-Epic
  design selected from a ≥2-Epic picker, offer the **Next Epic** loop (Phase 0 granularity).

## `/implement` integration

`design.md` is the **engineering source of truth** (it incorporates and challenges the spec);
`specification.md` provides the requirements context. When the developer runs `/implement <VI> <Epic>`,
it should consume both from the per-Epic home `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` as its
description and do its own risk-classified planning + implementation. `/implement` also accepts an
explicit `@…/<EPIC>-<eslug>/design.md` path (any single `.md` is a valid spec file), so the design is
consumable directly today. **Note (scope boundary):** teaching `/implement`'s spec-resolution to
auto-discover the *nested* per-Epic `design.md`/`specification.md` (and to consume `focus_key`) is part
of the separate **grammar-adoption effort** for the shipped Jira-driven commands — NOT this effort.
This effort's only touch to `/implement` is the **open-question guard** below.

## Strict repo gate (vs `/specify`'s soft gate)

`/specify` (PM) grounds *lightly* and proceeds when repos are missing (feasibility open-questions).
`/design` (Dev) must see **all** implementation repos to design seams/interfaces across them, so its
gate is **hard-stop**: the developer confirms the complete set, and any unmounted repo blocks until
remounted. This is the deliberate PM-soft / Dev-strict asymmetry.

## Open-question policy (design is a hard gate; spec is not)

- **`specification.md` open questions are tolerated** — they are the spec's way of flagging what the
  design phase resolves. `/design` happily consumes an open-question spec; `spec-reviewer` did not
  block on them.
- **`design.md` open questions hard-block** — the design is the last gate before code, so `/design`
  must be *decision-complete* to hand off. Enforced twice: **(a)** `design-reviewer` (Phase 6) treats
  any unresolved `- [ ]` in `design.md` as a **BLOCKER**, and Phase 7 will not hand off a design with
  open questions; **(b)** a small guard added to **`/implement`** (this effort's one touch to that
  shipped command): `/implement` refuses to proceed when the **design doc** it loads has unresolved
  `- [ ]` — `specification.md`-level open questions are exempt; a logged explicit override is the only
  escape.
- **Transitive:** a spec open question that actually blocks a design decision surfaces as a `design.md`
  open question → blocked; spec questions that don't block the design linger harmlessly.
- **The Epic is the unit of work** across `/specify` → `/design` → `/implement`; none of them fan out
  a VI through its Epics (interactive grills can't be batched; per-Epic gating/PRs are cleaner). VI
  input is guided to per-Epic runs (Phase 0).

## Verification (no test framework — structural, per plugin convention)

- `commands/design.md` parses; cites `jira-input-resolution`, `design-format`, `model-routing`,
  `escalation-rules`; all phase anchors (0,1,1.5,2,3,4,5,6,7) present; embeds the grilling technique;
  dispatches `code-scanner` + `dev-workflows:design-reviewer`; strict-gate + hard-stop present;
  branch+PR handoff present; `SPECIFY`-style reject-direct guard present.
- `references/design-format.md` present with the section set + the scalable/decision-dense/omit-N/A
  rule + the identifier/traceability expectations.
- `agents/design-reviewer.md` frontmatter valid; `model: opus`; not caller-overridable; validates
  against `design-format.md` + spec traceability; verdict schema present; treats unresolved `design.md`
  `- [ ]` open questions as a BLOCKER.
- `commands/design.md` implements the **tiered model gate** (hard-stop-and-relaunch for
  SIGNIFICANT/HIGH-RISK when the session isn't Opus; advisory for SIMPLE/MODERATE) and the
  **VI → per-Epic** granularity guidance (no fan-out).
- **`/implement` guard:** `/implement` refuses to proceed when the design doc it loads has unresolved
  `- [ ]` (spec-level open questions exempt; logged override only). Verify the guard is present and
  does not trip on `specification.md`-only open questions.
- **Input/paths reconciled to shipped v2.5.0:** `commands/design.md` consumes `focus_key`; writes
  `design.md` **flat** at `specifications/<VI>-<vslug>/<EPIC>-<eslug>/design.md` (hyphens); durable files
  are `_design-session.md`/`_design-glossary.md` (no collision with `/specify`'s `_session.md`); the
  ≥2-Epic **progress-aware picker** (enumerated from spec'd Epic subfolders; done-predicate `design.md`)
  + single-Epic auto-select + stand-alone-Epic-direct + Next-Epic loop are present; branch is
  `design/<EPIC>-<eslug>` / `design/<VI>-<vslug>`.
- Manifests valid JSON; version lock-step `2.6.0` (plugin.json + marketplace plugins[0] + CHANGELOG);
  siblings `dt-style-guide 0.2.2` / `obsidian-llm-wiki 0.3.1` untouched.
- README/command-list + subagent-table surfaces updated to include `/design` + `design-reviewer`
  (Opus row); the workflow-command count and Opus-gate count are **recomputed from the manifest**, not
  asserted from memory (the `/specify` effort's "Eight vs Ten" scare confirmed this discipline).

## Dependencies & provenance

- **No hard runtime plugin dependencies.** `/design` embeds the grilling technique and owns
  `design-format.md`; it invokes no external skill at runtime.
- **Dev-time only:** superpowers (brainstorming → writing-plans → SDD) builds the command.
- **Provenance:** grilling technique adapted from mattpocock `grill-me`/`grilling`; `design-format.md`
  is net-new (no import source). Unlike `/specify`, nothing is imported from `mgd-specifications` —
  `/design` only *reads/writes* files there, it doesn't borrow its authoring logic.

## Resolved during review

- **Branch name** → `design/<EPIC>-<eslug>` (per-Epic / stand-alone) or `design/<VI>-<vslug>` (broad VI-level); hyphen delimiters, mirroring shipped `/specify`.
- **Duplicate-flagging** → `design-reviewer` flags `design.md` sections that duplicate
  `specification.md` verbatim as **MINOR** (prefer a reference — both docs live in the same repo).
- **`code-scanner` scaling** → `code-scanner` has no depth/effort parameter; classification scales the
  **grill depth, `design.md` section-inclusion, and reviewer rigor** — NOT the scan (which runs over
  all confirmed repos regardless of tier).
- **Model gate** → tiered **hard** gate (SIGNIFICANT/HIGH-RISK require an Opus session; SIMPLE/MODERATE
  advisory). Stricter than `/implement`'s advisory because `/design`'s critical synthesis is inline.
- **Open-question policy** → `design.md` open questions hard-block (`design-reviewer` BLOCKER + a new
  `/implement` guard); `specification.md` open questions tolerated.
- **VI granularity** → the Epic is the unit of work; VI input is guided to per-Epic runs (no fan-out).

## Scope note

This effort is primarily net-new (`/design` + `design-format.md` + `design-reviewer`), but it makes
**one small, deliberate touch to the shipped `/implement`**: an open-question guard (refuse to
implement when the loaded design doc has unresolved `- [ ]`; spec-level exempt; logged override). That
guard is the cross-command enforcement of "no implementation on an unresolved design."

## Reconciliation (2026-07-08 — aligned to shipped v2.5.0 foundation)

This doc was authored while the two-key-grammar foundation was still a blocking prerequisite. The
foundation shipped as **v2.5.0** on 2026-07-08; the following deltas realign this design to what
actually shipped (see `spec/2026-07-07-two-key-grammar-foundation-design.md` and shipped
`commands/specify.md` for the mirrored patterns):

1. **Delimiter** — underscore → **hyphen** everywhere: `specifications/<VI>-<vslug>/<EPIC>-<eslug>/`,
   branch `design/<EPIC>-<eslug>` / `design/<VI>-<vslug>` (the foundation locked hyphen; the specs repo
   was normalized to `PRODUCT-<n>-<slug>`).
2. **Flat layout** — `design.md` lands **flat** in the per-Epic folder (was `…/spec/design.md`),
   alongside `/specify`'s `specification.md`, matching the shipped flat per-Epic home.
3. **Durable-file namespacing (new decision forced by the flat layout)** — `/design` writes
   `_design-session.md` / `_design-glossary.md`, NOT `_session.md` / `_glossary.md`. The flat per-Epic
   folder is shared with `/specify`, which already owns `_session.md` / `_glossary.md`; reusing those
   names would collide and make `/design`'s ◐-in-progress picker state misread `/specify`'s session as
   its own. This is the one genuinely new decision this reconciliation introduces.
4. **Progress-aware Epic picker** — Phase 0's single-key-VI path now **renders the shipped picker**
   (mirroring `/specify` Phase 2 Step A: ○/◐/● states, single-Epic auto-select, "Next Epic" loop, broad
   VI-level escape hatch) instead of merely instructing a manual per-Epic re-run. `/design`'s
   done-predicate is `design.md` exists; because `/design` does not read Jira, the picker **enumerates
   spec'd Epic subfolders from the specs repo** (Epics whose `specification.md` is merged) rather than
   from a `jira-reader` `vi-plus-epics` read — this preserves the "`jira-reader` not used" invariant and
   is more accurate (an Epic with no merged spec is not yet designable).
5. **`focus_key` consumption** — Phase 0 consumes the shared front-end's `focus_key` output field; the
   front-end is used only for grammar parsing + key classification, not for reading content.
6. **Version** — `/design` is **v2.6.0** (v2.5.0 was consumed by the foundation).
7. **`/implement` scope boundary clarified** — this effort's only touch to `/implement` is the
   open-question guard; teaching `/implement` to auto-discover the nested per-Epic paths + consume
   `focus_key` belongs to the separate grammar-adoption effort.
