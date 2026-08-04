# /vuln + /upgrade dispatch file-handoff — design + plan

**Date:** 2026-08-02
**Status:** Shipped in dev-workflows v2.39.3 — pre-implementation design snapshot, kept as authored.
**Scope:** `dev-workflows` plugin, all three editions.
**Source:** superpowers "hand off by file, not paste". The M item
(`2026-08-02-implement-dispatch-file-handoff-design.md`) applied this to `/implement`; this is its
recorded sibling for `/vuln` + `/upgrade`. This doc doubles as the plan (S size — no separate plan file).

## Problem

`/vuln` and `/upgrade` paste large artifacts inline into dispatch prompts, same residency cost as
the M item:

| Cmd | Blob | Pasted into | Sites (canonical) |
|-----|------|-------------|-------------------|
| `/vuln` | READY **research report** | `vuln-fixer` (×2) + re-supplied in resume prose (×2) | `commands/vuln.md:105,143,153,157` |
| `/vuln` | review **git diff** | `code-review` (prose) | `vuln.md:148-149` |
| `/upgrade` | READY **planner handoff** (upgrade plan) | `risk-planner` + `upgrade-executor` + resume prose | `commands/upgrade.md:69,133,143` |
| `/upgrade` | review **git diff** | `code-review` (prose) | `upgrade.md:138-139` |

The research report (4 mentions) and planner handoff (3 mentions) are the highest-value offloads.

## Approach — reuse the M item's mechanism verbatim

Write each blob to a `mktemp` file (in `$TMPDIR`, **never inside a repo working tree** → no `git diff`
pollution) once, at the point it first becomes READY, and hand the path everywhere it's consumed.
Handles: `research_file` (/vuln, per-CVE), `plan_file` (/upgrade, per-component), `review_diff_file`
(both, the code-review diff). The `code-review` + `review-fixer` invocations are **prose** here (not
fielded `task()` templates), so reword the prose to pass the diff (and the already-filed research
handoff) as paths.

## Edit map (canonical; verbatim-copy to mgd, converted for Copilot)

**`commands/vuln.md`:**
- **V1 (write-once):** Step 3 per-CVE (near `:78`) — before the fix, write the CVE's READY research
  report to `mktemp -t dw-vuln-research-XXXX.md` (never inside a repo tree), record `research_file`.
- **V2 (`:105`)** vuln-fixer SIMPLE/MODERATE: `[paste the single READY research report verbatim]` →
  `[read the single READY research report from the file at research_file]`.
- **V3 (`:143`)** vuln-fixer SIGNIFICANT/HIGH-RISK: same replacement.
- **V4 (`:148-149`)** code-review: capture the diff to `mktemp -t dw-vuln-diff-XXXX.patch`
  (`review_diff_file`); reword `:149` so code-review gets the research handoff (`research_file` path),
  the fixer output, and the diff **from `review_diff_file`**.
- **V5 (`:153,:157`)** resume prose: "the original research report re-supplied verbatim" → "…re-supplied
  from `research_file`".

**`commands/upgrade.md`:**
- **U1 (write-once):** Phase 1 "Collect planner results" (near `:54`) — for each READY component, write
  its planner handoff to `mktemp -t dw-upgrade-plan-XXXX.md` (never inside a repo tree), record
  `plan_file` (persists into Phase 2).
- **U2 (`:69`)** risk-planner: `Upgrade plan: [paste the READY planner handoff]` →
  `Upgrade plan: read it from the file at [plan_file]`.
- **U3 (`:133`)** upgrade-executor: `[paste the full READY upgrade plan verbatim]` →
  `[read the full READY upgrade plan from the file at plan_file]`.
- **U4 (`:138-139`)** code-review: capture the diff to `mktemp -t dw-upgrade-diff-XXXX.patch`
  (`review_diff_file`); reword `:139` so code-review gets the approved risk plan, the executor output,
  and the diff **from `review_diff_file`**.
- **U5 (`:143`)** verify-resume prose: "the original READY plan" → "the original READY plan (from
  `plan_file`)".

**Agent notes (2 files — the others already carry it from the M item):**
- `agents/vuln-fixer.md` — its research-report input may arrive inline or as an absolute path → Read.
- `agents/upgrade-executor.md` — its upgrade-plan input may arrive inline or as an absolute path → Read.
- (`code-review`, `review-fixer`, `risk-planner` already note "inline or path" — no change.)

## Global constraints

- **Behavior-preserving** — relocate blobs to files only; no gate/branch/model-routing/classification
  change; the resume-path re-review already re-captures its own diff (nothing to preserve there).
- **No diff pollution** — all handles are `mktemp`, outside every repo tree.
- **No cleanup step** (matches the house pattern).
- **Three-edition parity** — canonical→mgd verbatim copy (verify byte-identity of the 4 files
  pre-change); Copilot conversion (`skills/{vuln,upgrade}/SKILL.md`, `agents/*.md`); **0 new
  `${CLAUDE_PLUGIN_ROOT}`**.
- Do **NOT** edit `references/specification-format.md` (frozen).
- **Version:** PATCH — canonical/mgd 2.39.2 → **2.39.3**; Copilot 2.9.2 → **2.9.3**. CHANGELOG **Changed**.
- **Pushes held.** Trailer `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

## Out of scope (proportionate — noted, not silent)

- The single-use **prose** references handed to `code-review` (the fixer/executor output; the approved
  risk plan) and the **review-output → review-fixer** prose invocation stay inline. They are single
  mentions, not repeated blobs; the `code-review`/`review-fixer` agent notes already accept a path if
  a later pass wants to file them. Filing them now would be over-application.

## Verification

- `claude plugin validate` (both Claude editions); Copilot SKILLs parse.
- Canonical ↔ mgd byte-identical for the 4 changed files.
- Copilot: 0 new `${CLAUDE_PLUGIN_ROOT}`.
- Grep: no remaining `[paste … research report | READY planner handoff | full READY upgrade plan]`;
  each new handle is `mktemp`-derived.
- Final Opus whole-branch review, then merge/push per user.
