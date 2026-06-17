# Scale-aware fan-out scanning for `/impl:code`

**Date:** 2026-06-17
**Status:** Approved (design)
**Plugin:** `dev-workflows`
**Affected files:** `plugins/dev-workflows/commands/impl/code.md`, `plugins/dev-workflows/references/model-routing/classification.md`, `CLAUDE.md` (workflow map + invariants)

## Problem

`/impl:code` today accepts only inline text or a single `@file` markdown prompt, and its
only codebase-exploration step is **one** `general-purpose` subagent that scans the current
working directory and **inherits the session model**. Because managed settings pin
**Sonnet 4.6 on restart**, that scan frequently runs on a weaker model than Opus.

Real implementation briefs are larger than this: a single invocation may reference a design
spec, an exported **Jira ticket folder** (a Value Increment hierarchy with nested
tickets, comments, and attachments), a **spec/design folder**, and **multiple code
repositories**. Example invocation:

```
dev-workflows:impl:code @/workspace/obsidian/Projects/Products/PRODUCT-17713 - .../spec/2026-06-09-...-design.md;
  more details in @/workspace/obsidian/jira-products/PRODUCT-17713/ and
  @/workspace/obsidian/Projects/Products/PRODUCT-17713 - .../ . cluster repo is current dir,
  docs repo is @/workspace/dynatrace-docs/
```

A single explorer on a weak model cannot reliably comprehend that volume, and the initial
planning/synthesis suffers. We need (a) multi-source input handling and (b) scale-aware
model routing for the scan + planning step.

## Goals

1. Let `/impl:code` accept multiple `@path` inputs (spec files, Jira ticket folders, spec
   folders, code repos) in one invocation.
2. When the input is large, structure the scan as a **parallel fan-out** so each subagent
   handles a bounded slice — and route the **synthesis/initial planning** to Opus.
3. Express the scan-routing as a **shared policy** in `classification.md` that all scanning
   agents/commands point to (not a `/impl:code`-only hack).
4. Keep small-input invocations **fully backward compatible** — the current single-explorer
   path is unchanged.

## Non-goals

- Byte/line counting of inputs to drive routing (rejected: thresholds drift, needs a
  counting step). Routing triggers on **input shape**, not measured volume.
- A separate "scan tier" routing axis. Scale is folded into the existing risk
  classification instead (see Decision 3).
- Changing downstream phases (branch, baseline, implement, Opus review, tests, maintenance,
  report) beyond what feeds the planner.

## Design

### 1. New input handling (Phase 0 rewrite)

`$ARGUMENTS` is parsed into free-text prose plus **zero or more `@paths`**. Each `@path`
(and the cwd) is classified **by inspection, not by path-string matching**:

| Detected as | Recognition rule | Handled by |
|---|---|---|
| **Spec file** | a single `.md` file | read as the description/spec |
| **Spec folder** | a directory containing `prompt.md` and/or `*-design.md` | read all `.md` specs within |
| **Jira ticket folder** | a directory with `*-index.md`, or ticket-key subdirs each containing `KEY.md` | `jira-reader` |
| **Code repo** | a directory that is a git repo (`git rev-parse --is-inside-work-tree`), including the cwd and e.g. `dynatrace-docs` | scan target |

Rules:
- The **primary description** is: the spec file if given → else the spec-folder design doc →
  else the inline prose.
- Multiple inputs of the same kind are allowed (e.g. two ticket folders, three repos).
- A referenced `@dir` that is missing or is neither a recognized folder type nor a git repo
  is **surfaced to the user, never silently skipped** (mirrors the epics-flow
  `REFRESH_BLOCKED` honesty invariant).
- Existing single-`@file` and inline-text behavior is a strict subset of this and must keep
  working unchanged.

### 2. Scan-path decision (new Pre-Phase 2 "Input scale assessment")

Compute input-shape facts at Phase 0:
- `repo_count` = number of code repos (cwd + referenced dirs that are git repos)
- `has_ticket_folder` = any Jira ticket folder present
- `has_spec_folder` = any spec folder present

**Trigger the fan-out path** when **any** of:
`repo_count > 1` **OR** `has_ticket_folder` **OR** `has_spec_folder`.

Otherwise → today's single-explorer Phase 2A/2B runs unchanged.

### 3. Classification coupling (`classification.md` §1.1)

Add one trigger bullet to §1.1:

> Multi-source input — more than one code repository referenced, or any directory input
> (exported Jira ticket folder, spec/design folder) supplied to `/impl:code`.

This **floors the task at SIGNIFICANT**, which automatically pulls in Opus planning
(`risk-planner`) and Opus review via existing machinery. The floor is **auto-applied,
announced in the Phase 1.5 routing record, and overridable at plan approval** — consistent
with the existing re-classification override flow (the user may down-classify if they judge
the work genuinely smaller than its input footprint suggests).

### 4. Fan-out scan (new Phase 1.7 "Multi-source exploration" — only when triggered)

Runs after Phase 1.5 classification, before Phase 2B planning:

1. **`jira-reader`** over each Jira ticket folder → themes, PR references (identifiers only),
   linked items. Read-only; never modifies vault files.
2. **Spec folder(s)** read inline (cheap) → folded into the description/themes.
3. **`code-scanner` fanned out one-per-repo in a single message, capped at 4 concurrent**
   (reuse the `/impl:jira:epics` cap). Each scanner receives the spec/themes and its own
   repo path; returns existing capabilities, gaps, and relevant files for that repo.
4. **Synthesis** — the orchestrator combines the `jira-reader` output, all scanner reports,
   and the spec into the single "codebase summary" that feeds Phase 2B's `risk-planner`.

Ordering: `jira-reader` runs first (fast) so its themes can focus the scanners, matching the
`/impl:jira:epics` sequence.

### 5. Model routing inside the fan-out (cross-cutting policy)

- `jira-reader` and `code-scanner` **inherit the session model** — each handles a bounded
  slice, so even a Sonnet-pinned session copes.
- The SIGNIFICANT floor (Decision 3) means **synthesis/planning runs on
  `risk-planner@Opus`** — this is the "powerful model for the initial planning step" the
  feature targets. No separate synthesis-model rule is required.
- **Optional escalation hook:** if a single repo slice is itself oversized, the orchestrator
  *may* pin that one scanner to Opus via the `task` tool `model:` override. Documented as
  optional to avoid byte-counting.

### 6. Shared policy section (`classification.md` new §8 "Large-input scan fan-out")

A new section that is the single source of truth for scan routing. It documents:
- the input-shape trigger (Decision 2),
- the `jira-reader → parallel code-scanner (cap 4) → Opus synthesis` pattern,
- the SIGNIFICANT floor (Decision 3),
- the "scanning agents inherit the session model unless a single slice is oversized" rule,
- a note that `/impl:jira:epics` already implements the fan-out half (parallel `code-scanner`,
  cap 4), so this section generalizes an existing pattern rather than inventing one.

`/impl:code` references this section; the `model-routing` skill already surfaces
`classification.md` to commands.

### 7. Unchanged downstream

Branch creation (Pre-Phase 3), test baseline (Pre-Phase 3.5), implementation (Phase 3B),
Opus code review, Phase 3.5 test verification, Phase 4 maintenance, and the Phase 5 report
are untouched. Scanners are read-only (Read/Glob/Grep/LS/Bash); implementation writes only
where the approved plan specifies (the cwd plus explicitly referenced repos such as the docs
repo).

## Decisions (resolved during brainstorming)

1. **Scan architecture:** parallel fan-out (reuse the epics pattern), not a single beefy
   scanner.
2. **Trigger:** input shape (multi-repo or any directory input), not measured volume.
3. **Scale × risk:** scale floors the classification at SIGNIFICANT, reusing existing Opus
   gates, rather than adding an independent scan-tier axis.
4. **Defaults (approved):** the SIGNIFICANT floor is automatic + announced + overridable;
   scanners inherit the session model with only optional Opus escalation for an oversized
   single repo.

## Affected files

- `plugins/dev-workflows/commands/impl/code.md` — Phase 0 multi-input parsing, Pre-Phase 2
  input scale assessment, new Phase 1.7 fan-out, Phase 2B input wiring, new invariants.
- `plugins/dev-workflows/references/model-routing/classification.md` — §1.1 trigger bullet,
  new §8 fan-out policy.
- `plugins/dev-workflows/README.md` — **(a)** the `/impl:code` command-description table row
  (multi-input support); **(b)** the `## /impl:code workflow` **mermaid diagram**: broaden
  the Phase 0 node text (multiple `@paths`), add an "Input scale assessment" decision node
  after Phase 1.5, and a "Phase 1.7: multi-source fan-out (jira-reader → parallel
  code-scanner cap 4 → synthesis)" branch feeding Phase 2B; **(c)** the Agents table —
  note `jira-reader` and `code-scanner` now also serve `/impl:code`.
- `README.md` (repo root) — refresh any `/impl:code` capability summary if it describes the
  single-`@file` input shape.
- `CLAUDE.md` — `/impl:code` workflow-map line, the `/impl:code` invariants block, and the
  source-of-truth note pointing at the new `classification.md` §8.

## Risks / open considerations

- `code-scanner`'s current description is Epic-oriented ("themes from a Value Increment /
  Epic"). For `/impl:code` it scans relative to an implementation spec. The prompt passed to
  it must generalize; the agent body may need a minor wording tweak so it accepts
  spec-derived themes, not only Epic themes.
- The cwd repo is both a scan target and the implementation target. The fan-out must include
  the cwd as one scanner; the implementation phase still writes only per the approved plan.
- Multiple Jira ticket folders → multiple `jira-reader` calls; confirm whether these run
  sequentially or in parallel (sequential is fine — `jira-reader` is fast and read-only).
