# /implement dispatch-prompt file-handoff — design

**Date:** 2026-08-02
**Status:** approved (Design A — surgical per-artifact offload)
**Scope:** `dev-workflows` plugin, all three editions (canonical Claude, mgd Claude, Copilot)
**Source:** superpowers "hand off by file, not paste" context-management strategy (shipped
reference-only in wave 3; this is its `/implement` application — the deferred **M** item).

---

## Problem

`/implement`'s SIGNIFICANT/HIGH-RISK path (and the SIMPLE/MODERATE test step) dispatches
sub-agents whose prompts **paste large artifacts inline**. Pasted dispatch content stays
resident in the orchestrator's context and is re-read on every later turn; the same blobs are
also pasted into more than one dispatch. The four blobs:

| # | Blob | Written at | Pasted into (dispatch) |
|---|------|-----------|------------------------|
| 1 | multi-source **codebase summary** (or the single Explore agent's output) | Phase 1.7 synthesis / Phase 2B exploration | `risk-planner` (Phase 2B, `commands/implement.md:275`) |
| 2 | approved **plan** (risk-planner output; or the Phase 2A plan) | Phase 2B approval / Phase 2A | `test-writer` (Phase 3B 4a `:427`; Phase 3.5 `:~369`) and `code-review` (Phase 3B `:446`) |
| 3 | **git diff** (`git add -N . && git diff`) | Phase 3B step 5 / 4a; Phase 3.5 | `test-writer` (`:428`, `:~370`) and `code-review` (`:447`) |
| 4 | full **code-review report** (agent return) | Phase 3B step 7 | `review-fixer` (`:464`) |

Blobs 2 and 3 are each pasted into **two** dispatches, doubling their residency.

## The pattern already exists in-plugin

This is **not a new convention.** `/document` Phase 6.3 (`commands/document.md:645`) and `/epics`
Phase 6 (`commands/epics.md:321`) each `mktemp` a handoff file — *"never the vault, never a
repo"* — record its absolute path, and hand `doc-writer`/`epic-writer` only
`handoff_file: <path>`; those agents' `## Inputs` say *"read it first"*
(`agents/doc-writer.md:11`). The M item = **extend that established house mechanism to
`/implement`'s in-loop dispatches.**

The *"never … a repo"* guard is load-bearing here for a second reason: `mktemp` files live in
`$TMPDIR`, **outside every repo working tree**, so `git add -N . && git diff` (Phase 3B step 5)
never picks a handoff file up — no diff pollution.

## Chosen approach — Design A (surgical per-artifact)

Offload **only the four big blobs** to `mktemp` files and hand paths; keep small scalars (task
description, classification, project root, constraints, spec IDs, ARD invariants) inline. Each
consuming agent gets **one additive line** in its `## Inputs`: the field may arrive inline *or*
as an absolute file path to `Read`. This is additive — it does not break the agent's other
callers (`code-review` is also invoked by `/vuln` and `/upgrade`, which keep pasting inline and
remain valid under the "inline *or* path" wording).

Rejected alternative — **Design B (whole-handoff-file per agent):** convert each dispatch to a
full input-contract temp file and rewrite each agent's `## Inputs` to a single `handoff_file`
(the doc-writer/epic-writer idiom). Maximal cross-plugin consistency, but a larger interface
change to four shared reasoning agents, moving even trivial scalars into files for no token
benefit, and reworking the re-classification/revise re-dispatch loops. The token cost lives in
the big blobs; Design A captures ~all of it at a fraction of the blast radius on a working hot
path.

## Edit map (canonical; ported verbatim to mgd, converted for Copilot)

**`commands/implement.md`:**

1. **Phase 1.7 step 4 (Synthesize):** after building the multi-source summary, write it to
   `mktemp -t dw-impl-summary-XXXX.md` (never inside a repo tree), record its absolute path as
   the codebase-context handle. Prose that later refers to "the multi-source codebase summary"
   (Phase 2B exploration line, the re-classification/Phase 2A fallback at `:286`) refers to
   this file.
2. **Phase 2B exploration (non-fan_out path):** when the single Explore subagent is used
   instead, write its returned output to the same kind of temp file, so the codebase-context
   handle is *always* a path by the time the planner is dispatched.
3. **Phase 2B `risk-planner` dispatch (`:275`):** `Codebase summary: read from the file at
   <abs path>`.
4. **Phase 2B approval (after "Approve", `:295`):** write the approved plan to
   `mktemp -t dw-impl-plan-XXXX.md`, record its path; this single file is referenced by every
   later `Plan:` field.
5. **Phase 3B 4a `test-writer` dispatch (`:427`–`:428`):** capture the diff to
   `mktemp -t dw-impl-diff-XXXX.patch` and hand `Plan: read from <plan_file>` /
   `Diff: read from <diff_file>`.
6. **Phase 3B step 5 (diff capture) + step 6 `code-review` dispatch (`:446`–`:447`):**
   re-capture the review diff (after tests written + `[DEBUG-xxxx]` probes stripped) to a temp
   file; `Plan: read from <plan_file>` / `Diff: read from <review_diff_file>`. `git diff --stat`
   stays inline (small).
7. **Phase 3B step 7 → `review-fixer` dispatch (`:464`):** write the returned code-review report
   to `mktemp -t dw-impl-review-XXXX.md`; `Review output: read from the file at <review_file>`.
8. **Phase 3.5 `test-writer` dispatch (SIMPLE/MODERATE, `:~369`):** same `Plan`/`Diff`
   file-handoff as 3B 4a (sibling — folded in to avoid the missing-adoption gap; the Phase 2A
   plan is orchestrator-written but still written to a temp file at approval).

**Agent bodies (one additive `## Inputs` line each):**

- `agents/risk-planner.md` — **Codebase summary** may be inline or an absolute path → Read it.
- `agents/test-writer.md` — **Plan** / **Diff** may be inline or an absolute path → Read it.
- `agents/code-review.md` — **Plan** / **Diff** may be inline or an absolute path → Read it.
- `agents/review-fixer.md` — **Review output** may be inline or an absolute path → Read it.

## Global constraints

- **Behavior-preserving.** The refactor relocates *where* each blob lives (inline → temp file);
  it must not change any decision, gate, classification, model routing, or the content an agent
  receives. Every gate/branch/interrupt in Phase 1.7/2B/3B/3.5 is byte-for-byte unchanged except
  the four dispatch fields and the capture/write steps that feed them.
- **No diff pollution.** All handoff files are `mktemp` (in `$TMPDIR`, outside every repo tree).
  Verify no path used sits inside a repo working tree.
- **No cleanup step** — matches the existing doc-writer/epic-writer precedent (ephemeral
  `$TMPDIR`; adding cleanup would diverge from the house pattern).
- **Three-edition parity.** Canonical → mgd is a verbatim file copy (verify byte-identity of the
  five files pre-change); Copilot is a conversion (`${CLAUDE_PLUGIN_ROOT}` → `~/.copilot/…/
  skills/_shared/`, `/design`→`design:` etc., "Claude Opus"→"strong reasoning tier"). The
  `mktemp` mechanism itself is identical across editions. **Introduce zero new
  `${CLAUDE_PLUGIN_ROOT}` references in the Copilot edition.**
- Do **NOT** edit `references/specification-format.md` (frozen snapshot).
- **Version:** behavior-preserving internal refactor → **PATCH** proposed
  (2.39.1 → 2.39.2 canonical/mgd; 2.9.1 → 2.9.2 Copilot). Confirm at ship. CHANGELOG entry under
  **Changed**.
- **Pushes held** for explicit user confirmation. Commit trailer
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- mgd push bypasses a PR-required branch rule (user: "ok for now").

## Out of scope (recorded siblings — deliberate deferral, not a silent gap)

- **`/vuln` + `/upgrade`** dispatch `code-review` with an inline diff (`commands/vuln.md:148`,
  `commands/upgrade.md:138`). Same blob, separate commands. The additive `code-review` agent note
  keeps them valid; migrating their diff (and research/upgrade-plan) handoffs is a follow-up item
  to record in `NEXT.md`.
- **`/document` + `/epics`** already file-handoff — no change.

## Verification

- `claude plugin validate` passes (both Claude editions); Copilot manifest + SKILL.md parse.
- Canonical ↔ mgd byte-identical for the five changed files.
- Copilot edition: 0 new `${CLAUDE_PLUGIN_ROOT}` references introduced.
- Grep proof: no remaining `[paste …]` for the four blobs in the in-scope phases; every new path
  handle is `mktemp`-derived (no repo-tree path).
- Final independent **Opus whole-branch review** (the gate), then merge/push per user.
