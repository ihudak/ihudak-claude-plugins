---
tags:
  - tasks-exclude
---

# `/idea` command — design (dev-workflows v2.15.0)

**Date:** 2026-07-10
**Effort:** dev-workflows **v2.15.0** — additive
**Repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`
**Sub-project:** 1 of 3 in the *VI-creation flow* (AI-First.md lines 95–98). Order: **`/idea`** → `/create-vi` → `/create-ard`.
**Trailer:** `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` — commit named files only, never `git add -A`.

---

## Goal

Add the front door of the VI-creation flow: a `/idea` command that takes one of four source types and, through a bounded grilling loop, produces a well-refined **`idea.md`** — a lean one-page brief that is a strong, self-describing seed for the later `/create-vi` command.

## Why (scope framing)

The existing dev-workflows pipeline (`/specify` → `/epics` → `/design` → `/implement` → `/document` → `/release-notes`) assumes the **VI already exists in Jira**. This effort begins the *upstream* PM/PA flow that creates the VI. The full cluster was decomposed into three staged commands (different owners, different sessions, per-phase cost attribution); this spec covers only the foundation, `/idea`. Everything downstream consumes `idea.md`, so it is built first.

## Research basis (six-repo sweep, 2026-07-10)

- **Mike** (`observability-requirements`) and **Alex** (`mgd-specifications`) — the two VI/spec authorities; Alex uses an **`idea.md`** as the input artifact to spec authoring.
- **SpecKit** — bounded clarification loop (≤5 questions ranked by Impact×Uncertainty, one at a time, recommended answers), an **11-category ambiguity taxonomy**, and `[NEEDS CLARIFICATION]`-capped-at-3 + logged Assumptions.
- **BMAD** — the lean *five-field kernel* alternative and the elicitation-method idea (not adopted for v1).
- **mattpocock `grilling`** — self-contained, model-invocable "walk the design tree one question at a time, recommend each answer, fact-vs-decision split"; the `--deep` mode mirrors it.
- **dev-workflows downstream contract** — the plugin consumes a **pre-exported Obsidian markdown tree** (never talks to Jira); has **no dependency-manifest field** (cross-plugin relations are convention + runtime-resolve + graceful fallback); roles/phases are `pm` (vi-creation), `pe` (specification, epic-refinement), `dev` (documenting, implementation).

## Decisions (locked in brainstorming)

1. **idea.md shape** — lean 1-page brief: **Problem · Who · Desired outcome & value · Rough scope (In/Out) · Signals & evidence · Open questions & assumptions · Candidate success signal**, plus frontmatter.
2. **Source handling** — one argument, **auto-detected** with **provenance tags**; a dedicated `idea-reader` subagent ingests.
3. **idea.md home** — keyless **`$VAULT_PATH/Projects/<area>/<slug>/idea.md`**; `/create-vi` **relocates** it later.
4. **Grilling** — **bounded by default** (≤5), **`--deep`** switches to relentless.
5. **No idea-reviewer** — the grilling loop + gaps/assumptions discipline is the quality mechanism at the idea stage; the full Opus reviewer lives at `/create-vi`.

---

## Architecture

### Command flow (`commands/idea.md`)

```
/idea <prompt | @file | JIRA-KEY> [--deep]

Phase 0  Validate environment ($VAULT_PATH) + resolve model routing
Phase 1  Resolve source type (argument classification, with confirmation)
Phase 2  idea-reader ingests the source  → structured digest  (§2.1 Sonnet)
Phase 3  Grilling loop (Opus orchestrator): gap-scan → ≤5 ranked Q (or --deep)
Phase 4  Synthesize + write idea.md  (set status: draft|refined)
Phase 5  Maintenance tail: cost + feedback (emit-auto)
Phase 6  Adaptive next-phase offer → /create-vi
```

### Phase 0 — environment + model routing

- **`$VAULT_PATH` validation:** must be set **and** the directory exists **and** looks like the vault (`.obsidian/` present) **and** is writable. If any check fails → **stop with a clear message and offer a user-specified target directory** for `idea.md` (write there on confirmation), else cancel. **Never** write to the current working directory.
- **Model routing:** invoke the `model-routing` skill (`Skill: "dev-workflows:model-routing"`) at start (command bodies cannot expand `${CLAUDE_PLUGIN_ROOT}`). Orchestration + grilling + synthesis run on the **§2 Opus chain**; `idea-reader` on the **§2.1 Sonnet chain**. Record the resolved models. If no Opus resolves → **degrade to best-available and record the degradation** (do not hard-block — a PM must not be blocked from capturing an idea by a momentary Opus outage).

### Phase 1 — source classification

Precedence, applied to the single argument:

1. Matches Jira-key regex `^[A-Z][A-Z0-9_]*-\d+$` → **RFE** (locate under `$VAULT_PATH/jira-products/<KEY>/…`).
2. Is an existing `.md` path or `@wikilink` → **markdown** (a community post is just a markdown file, typically under `Projects/Products/…`).
3. Otherwise → **inline prompt** (the argument text is the raw idea).

Surface a one-line confirmation of the detected type before ingesting (e.g. *"Read this as an RFE (PRODFB-929) — correct?"*). A future `--as prompt|file|rfe` override is **out of scope for v1**.

### Phase 2 — `idea-reader` subagent (new agent, `agents/idea-reader.md`)

Mirrors `jira-reader`: read-only, keeps the orchestrator context clean, on the **§2.1 Sonnet chain**.

**Inputs:** `argument`, `provenance_hint` (from Phase 1), `vault_path`.

**Behavior:**
- **RFE:** read the exported ticket markdown + its `attachments/` and wikilinked context.
- **markdown:** read the file; follow wikilinks to other `.md` (one level, bounded) for context; enumerate linked images (paths only); if it is a community post (location/thread shape), extract **demand signals** — requesters, upvote/vote counts, recurring asks.
- **prompt:** treat the argument text as the raw idea; no filesystem reads.
- Note unresolved wikilinks/images as broken and continue.

**Output (structured digest):** `provenance` (`prompt|markdown|community-post|rfe`), `source_refs[]` (paths / Jira key / URLs), `raw_context` (distilled problem/users/value/scope hints), `signals[]` (demand evidence), `images[]` (paths, for later VI/doc use), `wikilinks_followed[]`, `wikilinks_broken[]`, `candidate_title`, `candidate_slug`. Never writes.

### Phase 3 — grilling loop (Opus orchestrator, not delegated)

- Build a gap list from an **ambiguity taxonomy** trimmed to the idea stage: *problem clarity, target users, desired outcome/value, scope boundaries, evidence/demand sufficiency, success signal, terminology.*
- Rank gaps by **Impact × Uncertainty**.
- **Default (bounded):** ask **≤5** questions, **one at a time, each with a recommended answer.** Fact-vs-decision split — **look up facts** (from the digest / vault), only put **decisions** to the user. After 5 (or earlier convergence), remaining high-impact gaps become **`[NEEDS CLARIFICATION: …]` capped at 3** in `idea.md`; reasonable defaults are recorded as **Assumptions**.
- **`--deep`:** relentless grill-me-style design-tree walk, no cap, until the user confirms shared understanding.
- Embed the technique (no hard dependency), consistent with `/specify` and `/design`. Optionally *recommend* `mattpocock-skills` `/grilling` with graceful fallback (see Dependencies).

### Phase 4 — synthesize + write `idea.md`

- Render the lean brief (artifact spec below) into `$VAULT_PATH/Projects/<area>/<slug>/idea.md`.
- `<slug>` from `candidate_slug`; `<area>` defaults to `ideas` (or `Products` when the source already lives under `Projects/Products/…`).
- **If an `idea.md` already exists for the slug** → offer **refine existing** (re-open, resolve open clarifications, append to the sources list) vs **new**.
- **`status` rule:** `refined` **iff** zero open `[NEEDS CLARIFICATION]` remain; otherwise `draft`.

### Phase 5 — maintenance tail (cost + feedback)

`/idea` is a new pipeline command, so it carries the standard tail exactly like the other commands:
- **Cost:** report against **role `pm` / phase `vi-creation`** per `references/cost-emission.md`.
- **Feedback:** `emit-auto` per `references/feedback-emission.md` (plugin-facing slice only; silent; specs-first ladder).
- **`emit-block` invariant:** included in the command's Invariants block (before escalating a halt caused by a plugin/skill/command/reference gap; **not** for env/user halts such as bad `$VAULT_PATH` or source-not-found).

### Phase 6 — adaptive next-phase offer

On finish, offer the next phase, **adapting to `status`:**
- `status: refined` → *"Continue to `/create-vi` from this idea?"*
- `status: draft` (open gaps) → *"This idea has N open clarifications. (a) run `/idea --deep` to resolve them, or (b) continue to `/create-vi`, which will grill you on the rest."*

Declining leaves a clean `idea.md`. (This is the **reference implementation** for the cross-cutting "next-phase offer on every command" follow-up — see below.)

---

## Artifact spec — `idea.md`

```markdown
---
title: <candidate title>
slug: <candidate-slug>
sources:
  - provenance: rfe | markdown | community-post | prompt
    ref: <path | JIRA-KEY | url>
created: 2026-07-10
status: draft | refined       # refined iff 0 open [NEEDS CLARIFICATION]
---

## Problem
<solution-free statement of the pain>

## Who
<target users / personas affected>

## Desired outcome & value
<the value hypothesis — what "better" looks like>

## Rough scope
**In:** …
**Out:** …

## Signals & evidence
<RFE / community-post demand signals, wikilinked docs, image refs>

## Open questions & assumptions
- [NEEDS CLARIFICATION: …]        # capped at 3
- **Assumption:** …               # logged reasonable defaults

## Candidate success signal
<how we'd know it worked>
```

Format SSOT lives in **`references/idea-format.md`** (the command and `idea-reader` both cite it).

---

## Carry-forward to `/create-vi` (recorded now; honored in sub-project 2)

- `/idea` writes `idea.md` to a **stable, self-describing keyless path** and **never bakes in a Jira key**.
- **`/create-vi` accepts a `JIRA-KEY` param** (user creates the empty Jira workitem first): `/create-vi <JIRA-KEY> @<idea.md>` (or by slug). With a key it authors the VI **and relocates** `idea.md` (copy/move — **never a symlink**, which would break across `$VAULT_PATH`/`$SPECS_PATH`) under `$SPECS_PATH/specifications/<KEY>-<slug>/`. Pre-key, it can still produce the VI body to paste into Jira, then relocate on a follow-up.
- **`/create-vi` warns-and-folds on `status: draft`** (resolves open clarifications in its own grilling, or offers `/idea --deep`) — it does **not** hard-block.

## Follow-ups (separate efforts)

- **Next-phase offer everywhere (v2.16.0 candidate)** — generalize the next-phase offer to every pipeline command (idea → create-vi → create-ard → specify → epics → design → implement → document → release-notes), as a cross-cutting invariant like `emit-block`. `/idea` ships the pattern first; the generalization touches all nine commands and gets its own spec.
- **Revisit the `.obsidian/` vault check plugin-wide** — the `.obsidian/` marker is a *proxy* for "this is the user's personal store," not a hard dependency (wikilinks are plain markdown; the auto-backup is the user's own setup). `$VAULT_PATH` = personal storage; `$SPECS_PATH` = shared company/department storage. The same `.obsidian/` test also lives in `references/feedback-emission.md` tier 3 and other resolution logic, so changing it is cross-cutting. Goal: replace the proxy with a more explicit personal-store marker (or a one-time confirmation) that keeps the never-write-to-the-wrong-place guard without requiring Obsidian specifically. `/idea` keeps the existing check for consistency until this lands.

## Dependencies documentation (new, this effort)

Create **`references/dependencies.md`** as the SSOT for optional/recommended companions (there is still no manifest field — all relations are convention + runtime-resolve + graceful fallback):
- `mattpocock-skills` `/grilling` — recommended; fallback → `superpowers:brainstorming` → embedded technique.
- `superpowers` — brainstorming/grilling fallback.
- `dt-style-guide` (in our marketplace) — existing docs-style-checker fallback + planning-doc style checker.
- `https://github.com/ivan-gudak/jira-workitem-import` - Jira WorkItem Reporter. It imports Jira tickets to $VAULT_PATH/jira-products with the structure expected by `dev-workflows` plugin.

Point CLAUDE.md / README at it.

---

## Out of scope (YAGNI)

- No idea-reviewer agent (decision 5).
- No multiple sources in one run (single primary source + followed wikilinks); no `--deep=N`; no dedicated community-post parser (auto-detect + provenance covers it).
- No Jira writes and no relocation from `/idea` (both belong to `/create-vi`).
- The v2.16.0 next-phase-offer generalization is **not** built here.

## Verification (structural — no test framework, no husky/prettier hook)

- `python3 -c "import json; json.load(open(...))"` on `plugin.json` and `marketplace.json`.
- grep anchors: `commands/idea.md` phases present; Invariants block contains the `emit-block` invariant; `agents/idea-reader.md` output-schema keys present; `references/idea-format.md` and `references/dependencies.md` exist with expected headings.
- `feedback-emission.md` command-count reference updated (eight → nine).
- byte-diff: sibling plugins `dt-style-guide` (0.2.2) and `obsidian-llm-wiki` (0.3.1) unchanged; version lock-step between `plugin.json` and the `dev-workflows` entry in `marketplace.json`.

## File manifest

**New**
- `commands/idea.md`
- `agents/idea-reader.md`
- `references/idea-format.md`
- `references/dependencies.md`

**Modified**
- `.claude-plugin/plugin.json` — version → 2.15.0
- `.claude-plugin/marketplace.json` — `dev-workflows` entry version → 2.15.0 (siblings byte-identical)
- `CHANGELOG.md` — prepend `## [2.15.0] — 2026-07-10`
- `references/feedback-emission.md` — command count eight → nine
- `references/cost-emission.md` — add `/idea` where commands are enumerated (if applicable)
- `CLAUDE.md` / `README` — list `/idea`; point at `references/dependencies.md`

## Release discipline

Branch `ivgu/NOISSUE-idea-command`; commit named files only (never `git add -A`); trailer as above. Version lock-step (plugin.json + marketplace.json dev-workflows entry). Prepend CHANGELOG entry (history preserved, em-dash date). Merge ff to `main`, push origin, delete branch. Watch for lima read-after-write flakiness on commit (fsck-first, `update-ref` the dangling commit if needed).
