---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-28
---

# dev-workflows docs automation — Per-step model delegation for /impl:jira:docs (design)

## Context

SP2 (Inc1–3) plus the pipeline-hardening pass shipped (plugin `main` @ `0666cf6`,
v1.14.2). The `/impl:jira:docs` pipeline (Phase 0→9) is coherent end-to-end but
does **no per-step model routing**: it classifies once at Phase 1.5 and then lets
**every subagent inherit the session model**. Consequences:

- A **Sonnet-launched** run runs the highest-judgment synthesis — `doc-planner`
  (Phase 5.7: source-truth reconciliation + write-strategy + the documentation
  checklist) — on **Sonnet**.
- An **Opus-launched** run burns Opus on the mechanical fan-out — `diff-summarizer`
  ×N, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, the 4 maintenance
  agents — the exact anti-pattern §2.1 of the routing policy exists to prevent.
- The two **orchestrator-executed** judgment steps (Phase 6 writing the prose,
  Phase 5.8 discrepancy framing) **and the orchestration itself** always run on
  the session model and **cannot be `model:`-overridden** from inside the command
  (a running command cannot change its own session model).

`commands/impl/docs/profile.md` already demonstrates the target pattern: a
`model_routing` block resolved up front + per-dispatch `task model:` overrides
resolving `detection_model` (§2.1 Sonnet chain) and `planning_model` (§2 Opus
chain). This effort brings the same discipline to `docs.md` and extracts the
**reusable policy** into a new `classification.md` **§9** so `epics.md` (and
future authoring pipelines) can adopt it later.

Release: **MINOR `v1.15.0`** (adds delegation behavior; no breaking change).

## Goals

- **Force Opus on `doc-planner` (5.7)** regardless of the session model — the
  highest-value escalation.
- **De-escalate every mechanical subagent step to the §2.1 Sonnet chain**
  regardless of the session model — so an Opus session stops burning Opus on
  cheap work, and a Sonnet session records the chain explicitly.
- Surface a **Phase 1.5 advisory** recommending Opus for the **whole run**
  (orchestration coordination + the inline writer + a 1M context window) when the
  session is not on the §2 Opus chain **and** Opus is available.
- **Record** every routing decision in a `model_routing` block and the Phase 9
  report.
- Extract the reusable policy into **`classification.md` §9** (role→chain map +
  the escalate/de-escalate/advisory rules) so `docs.md` references it rather than
  re-deriving it inline.

## Non-goals

- Wiring **`epics.md`** — scoped follow-up. (§9 is written generically so it can
  adopt the policy with a small later pass: a `model_routing` block + `model:`
  lines on its 5 dispatches + a report section. Its incremental value is mostly
  de-escalation/cost, since epic writing is MODERATE and it has no `doc-planner`.)
- Touching `/impl:code`, `/upgrade`, `/vuln`.
- **Delegating the inline writer (Phase 6) to a subagent** — **deferred** to a
  dedicated writer-extraction refactor, paired with the `epics.md` inline writer
  (same situation). It would *close* the writer model gap (pin the writer to Opus
  on a Sonnet session — no relaunch needed) and relieve orchestrator context (the
  heavy writing inputs move into the subagent), but it is a larger change: a new
  `doc-writer` agent, repackaging every Phase 6 input as a file handoff, moving
  the multi-space write mechanics into the agent, and a commit-ownership decision.
  This effort uses the Phase 1.5 advisory instead; once the writer is a subagent,
  the advisory narrows to orchestration-coordination only.
- Changing the **frontmatter `model: opus` pins** on the cross-command reviewers
  (`doc-reviewer`, `code-review`, `epic-reviewer`, `risk-planner`).
- The command-namespace refactor / monotonic phase renumber (separate effort).

## Design

### 1. The `model_routing` block (Phase 1.5)

Resolved **once** at Phase 1.5, hung on the `model-routing` skill invocation
already there. It reuses the existing §4 field names — nothing new is invented:

```yaml
model_routing:
  classification: SIGNIFICANT                # already produced at 1.5
  reason: <one-line justification>
  current_model: <the model the orchestrator runs under>   # = the inline writer + 5.8 framing
  detection_model: <§2.1 Sonnet chain: claude-sonnet-4-6 → 4-5>   # mechanical/throughput steps
  planning_model:  <§2 Opus chain: claude-opus-4-8 … → Sonnet floor>   # doc-planner (5.7)
  review_model:    <§2 Opus chain>           # doc-reviewer (frontmatter-pinned; recorded here)
  implementation_model: <= current_model>    # the INLINE writer (6) + discrepancy framing (5.8); NOT overridable
  fixes_model: <= detection_model>           # doc-fixer (6.7 / 7) runs on the detection chain (see §2 note)
  opus_available: true | false
  notes: <any §2/§2.1 fallback or degradation>
```

Notes on two fields that deviate from §4's defaults:

- **`implementation_model` = `current_model`** because the "implementation" (the
  prose writing) is performed by the orchestrator itself, not a subagent — it
  cannot be overridden. The block records this so the report is honest about what
  model wrote the docs.
- **`fixes_model` = `detection_model`** (not `implementation_model`). The docs
  pipeline routes `doc-fixer` to the Sonnet detection chain (it applies
  reviewer-specified targeted fixes; classification.md §3.2 step 6 says fix edits
  do not need Opus).
- `gate_tests_on_review` is **N/A** for docs (no test suite).

### 2. Per-step routing map

|                             Phase | Step                                   | Executor     | Routed to                      | Direction               |
| --------------------------------: | -------------------------------------- | ------------ | ------------------------------ | ----------------------- |
|                                 3 | `jira-reader`                          | subagent     | **`detection_model`** (Sonnet) | de-escalate             |
|                                 5 | `diff-summarizer` ×N                   | subagent     | **`detection_model`** (Sonnet) | de-escalate             |
|                               5.5 | `doc-location-finder`                  | subagent     | **`detection_model`** (Sonnet) | de-escalate             |
|                               5.7 | **`doc-planner`**                      | subagent     | **`planning_model`** (Opus)    | **escalate**            |
|                               5.8 | discrepancy framing                    | orchestrator | `current_model` (advisory)     | —                       |
|                                 6 | **write prose**                        | orchestrator | `current_model` (advisory)     | —                       |
|                               6.7 | `docs-style-checker`                   | subagent     | **`detection_model`** (Sonnet) | de-escalate             |
|                             6.7/7 | `doc-fixer`                            | subagent     | **`detection_model`** (Sonnet) | de-escalate             |
|                                 7 | `doc-reviewer`                         | subagent     | `review_model` (Opus)          | unchanged (frontmatter) |
|                                 8 | 4 maintenance agents (general-purpose) | subagents    | **`detection_model`** (Sonnet) | de-escalate             |
| 0,1,2,4,4.5,5.6,5.9,6.2,6.5,6.8,9 | orchestrator plumbing / interaction    | orchestrator | `current_model`                | —                       |

**Net effect:** a Sonnet-launched run still gets an **Opus `doc-planner`** (the
single most important synthesis), and an Opus-launched run **drops the entire
mechanical fan-out to Sonnet**. The only residual gap is the inline writer +
gates, which the Phase 1.5 advisory surfaces.

**`doc-reviewer` (Phase 7):** stays Opus via its **own frontmatter pin** — the
dispatch adds **no** `model:` override (avoid double-specifying); the block just
records `review_model` for the report.

### 3. Advisory + degradation (Phase 1.5)

After resolving the block, set `opus_available` = (a §2 Opus model resolved).
Then:

- **`current_model` is on the §2 Opus chain** → no advisory. Detection steps still
  de-escalate to Sonnet via their overrides.
- **`current_model` is NOT on the §2 chain, and `opus_available: true`** (the
  common "launched on Sonnet, Opus exists" case) → emit the advisory:

  ```
  ⚠ This run is on <current_model>. /impl:jira:docs is a long, judgment-heavy,
    context-heavy orchestration: the Phase 0–9 coordination, the discrepancy
    (5.8) and write-strategy (5.9) gates, and the prose writing (Phase 6) all
    run on the session model and cannot be delegated. Opus is recommended for
    the whole run — better reasoning on the gates and the prose, plus a 1M
    context window that removes window pressure on large multi-repo tickets.
    doc-planner (5.7) is escalated to Opus regardless of this choice.

  choices:
   ["Relaunch /impl:jira:docs under Opus — I'll restart (Recommended)",
    "Proceed on <current_model> — record the degradation in the report",
    "Cancel"]
  ```

  - **Relaunch** → stop cleanly with an instruction to relaunch under Opus (the
    command cannot change its own session model).
  - **Proceed** → set a degradation flag; carry it to the Phase 9 report.
  - **Cancel** → stop.

- **`current_model` is NOT on the §2 chain, and `opus_available: false`** (no Opus
  anywhere in the environment) → **skip the relaunch offer**; set `planning_model`
  and `review_model` to the Sonnet floor; record in `notes` and the Phase 9 report
  that `doc-planner`, `doc-reviewer`, **and** the writer all ran degraded (per
  §2's "announce the degradation" rule); proceed.

### 4. `classification.md` §9 (the shared SSOT)

New section: **"§9 — Per-step routing for multi-phase authoring pipelines."**
Contents:

1. **Principle.** Judgment-heavy authoring/synthesis steps → the §2 reasoning
   (Opus) chain; mechanical detection/throughput/fix steps → the §2.1 detection
   (Sonnet) chain; **orchestrator-executed** judgment steps (and the orchestration
   itself) cannot be overridden → **advisory** to relaunch on the §2 chain.
2. **Role→chain map** (reusable by `docs.md` now and `epics.md` later):

   | Role | Chain |
   |------|-------|
   | Synthesis/planner (e.g. `doc-planner`) | §2 reasoning (Opus) |
   | Reader / summarizer / locator / style-checker / fixer / maintenance (`jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, maintenance agents) | §2.1 detection (Sonnet) |
   | Domain reviewer (`doc-reviewer`, `epic-reviewer`) | §2 review (Opus) — typically already frontmatter-pinned |
   | Inline writer + interactive gates (the orchestrator) | session model → advisory |

3. **No-Opus degradation rule** (mirror §2): when no Opus is available, run the
   reasoning/review roles on the Sonnet floor and announce the degradation in the
   routing record and the final report.
4. **Reconciliation note with §8.3:** §8.3's "`jira-reader` / `code-scanner`
   inherit the session model" is the conservative default for the `/impl:code`
   large-input **fan-out**. Authoring pipelines that route per §9 pin
   **`jira-reader`** to the detection chain (reading pre-exported markdown is
   mechanical, so an Opus session should not pay for it). `code-scanner` remains
   governed by §8.3 when invoked under the large-input fan-out trigger.

`docs.md` cites §9 at each dispatch so the command body stays thin (each dispatch
reads `model: <planning_model / detection_model per §9>`).

### 5. `docs.md` Phase 1.5 reword

The existing line *"SIGNIFICANT → no Opus planning (the Jira hierarchy + diff
summaries are the plan); `doc-reviewer` gate is mandatory."* is reworded to:

> SIGNIFICANT → no separate Opus **risk-planner** for the high-level plan (the
> Jira hierarchy + diff summaries are the plan), **but `doc-planner` (5.7) is
> pinned to the §2 Opus reasoning chain**; the `doc-reviewer` gate (Opus) is
> mandatory. Resolve the `model_routing` block (above) per `classification.md`
> §9 and emit the advisory when the session is not on the §2 chain.

### 6. Edges

- **Inline-profiling (Phase 0 case c):** `profile.md` has its own independent
  routing (`detection_model`→Sonnet, `planning_model`→Opus) and runs **before**
  Phase 1.5 — no conflict; left as-is. `docs.md`'s block starts at Phase 1.5.
- **`docs.md` does not use `code-scanner`** — the §8.3 reconciliation note is
  forward-looking (for `epics.md`/`/impl:code`); it changes nothing in `docs.md`.

## Touch list

- **`references/model-routing/classification.md`** — add **§9** (principle +
  role→chain map + no-Opus rule + §8.3 reconciliation note).
- **`commands/impl/jira/docs.md`** —
  - Phase 1.5: resolve the `model_routing` block; add the advisory + degradation
    handling; reword the "no Opus planning" line (§5 above).
  - Add a `model:` line to each subagent dispatch per the §2 map:
    `jira-reader` (≈:192 → detection), `diff-summarizer` (≈:256 → detection),
    `doc-location-finder` (≈:295 → detection), **`doc-planner` (≈:359 → planning/Opus)**,
    `docs-style-checker` (≈:568 → detection), `doc-fixer` (≈:580 and ≈:677 →
    detection), the **4 Phase 8 maintenance agents** (≈:712+ → detection).
    `doc-reviewer` (≈:655) gets **no** override (frontmatter governs; recorded as
    `review_model`).
  - Phase 9: add a `### Model Routing` section listing classification,
    `current_model`, `detection_model`, `planning_model` (doc-planner),
    `review_model` (doc-reviewer), `implementation_model` (= writer),
    `fixes_model` (= doc-fixer), `opus_available`, and any degradation note.
- **Manifests + CHANGELOG** — MINOR release **v1.15.0** (`plugin.json` top-level
  `version`; `marketplace.json` `plugins[0].version`; `CHANGELOG.md [1.15.0]`).

> **Line numbers are anchors from `0666cf6` and will drift** once the Phase 1.5
> block is added (it inserts lines above every later dispatch). The implementer
> matches by **anchor text** — the `→ Agent (subagent_type: "…")` line plus its
> phase heading — **not** by line number.

~3 plan tasks (classification.md §9; docs.md wiring; the release).

## Out of scope

- `epics.md` wiring (scoped follow-up).
- Other commands (`/impl:code`, `/upgrade`, `/vuln`).
- Delegating the inline writer to a subagent (deferred to the writer-extraction
  refactor — see Non-goals; pairs with `epics.md`).
- The namespace refactor / monotonic phase renumber.

## Invariants preserved

- **Zero external API.** No new network calls; routing is local model selection.
- **The frontmatter Opus pins** on cross-command reviewers are untouched.
- **profile.md's inline routing** is untouched and independent.
- **No behavior change** for an Opus-launched run beyond cost (mechanical steps
  drop to Sonnet) and the added routing record; a Sonnet-launched run gains the
  Opus `doc-planner` escalation + the advisory.
- The multi-space render-unchanged invariant and opt-in commit/push are untouched.

## Open items (confirm during spec review)

- None — mechanism (orchestrator `task model:` overrides), the writer handling
  (advisory, broadened to the whole run), the `doc-fixer`/maintenance → Sonnet
  calls, and the scope (docs.md + §9; epics deferred) are all settled.
