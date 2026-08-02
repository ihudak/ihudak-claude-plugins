# model-delegation for /implement, /vuln, /upgrade + Sonnet 5 adoption

**Date:** 2026-07-02
**Repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`, base `main` @ `6f54238` (v2.2.1)
**Version target:** MINOR **2.2.1 → 2.3.0** (additive capability — per-step routing on 3 more commands + Sonnet 5 tier)

## Context

Per-step model routing (each subagent dispatch pinned to a model tier via `model:`, driven by a
Phase 1.5 `model_routing` block) is fully adopted in `/epics` and `/document` but not in
`/implement`, `/vuln`, `/upgrade`. Separately, Sonnet 5 (`claude-sonnet-5`, Claude 5 family) has
shipped; the routing SSOT still pins the old `claude-sonnet-4-6` / `claude-sonnet-4-5` as the
Sonnet tier. This effort closes both gaps in one cohesive change.

**Routing SSOT:** `references/model-routing/classification.md` (loaded via the `dev-workflows:model-routing` skill).
Defines the **§2 Opus chain** (reasoning/gates), the **§2.1 Sonnet chain** (detection/mechanical),
the **§4 `model_routing` handoff schema** (`classification`, `current_model`, `planning_model`,
`review_model`, `implementation_model`, `detection_model`, `fixes_model`, `opus_available`, `notes`),
and the **§9 role→chain map**.

**Current state of the 3 targets (from recon):**
- `/implement` — Phase 1.5 classifies but builds **no** `model_routing` block; `jira-reader`,
  `code-scanner`, Phase 2A exploration, `test-writer`, `test-baseliner`, `review-fixer` all inherit
  the session model. `risk-planner` / `code-review` rely on frontmatter Opus pins. Flat architecture.
- `/vuln`, `/upgrade` — **partial**: pass skeletal `model_routing` blocks (only `classification`,
  sometimes `gate_tests_on_review`) to their All-tools coordinator agents; missing
  `detection_model`/`planning_model`/`review_model`/`opus_available` and any Sonnet pinning. Nested architecture (coordinators dispatch their own leaves internally).

**Agent frontmatter Opus pins (unchanged by this effort):** `code-review.md`, `risk-planner.md`,
`doc-reviewer.md`, `epic-reviewer.md` (`model: opus`). All other agents inherit / are overridden at dispatch.

## Goals

1. Adopt full per-step routing in `/implement`; complete it in `/vuln` and `/upgrade` (shallow,
   orchestrator-level).
2. Make Sonnet 5 the Sonnet-tier primary across the routing SSOT and its literal-ID example blocks.
3. Keep Opus 4.8 pinned on every judgment gate (review/planning) — no Sonnet-5 trial there yet.

## Design

### Decisions (user-approved)

- **Sonnet chain:** `claude-sonnet-5 → claude-sonnet-4-6 → claude-sonnet-4-5` (Sonnet 5 primary,
  4.6/4.5 as graceful-degradation fallbacks).
- **vuln/upgrade depth:** **shallow** — orchestrator-level pins only; coordinators' internal leaves
  inherit the pinned tier via `model:` inheritance. No coordinator-agent-file edits.
- **Uniform scan routing (added mid-execution 2026-07-02).** Routing is by **step nature**, not by
  pipeline or session. There is NO "inherit the session model" for mechanical scanning and NO
  per-command exception: `jira-reader`/`code-scanner` run on the §2.1 Sonnet chain in every command,
  even when their output feeds an Opus synthesis (`/implement`'s `risk-planner`). Only carve-out is
  size-driven: escalate a single oversized repo-slice `code-scanner` to Opus. *Why:* T2 surfaced that
  the plan's Sonnet pins contradicted the SSOT's stale `§8.3`/`§9.4` + `implement.md` Invariant, which
  still said scanning "inherits the session model" — reintroducing exactly the Opus-session waste that
  explicit routing exists to prevent. User chose to fix the doctrine. See Workstream A.

### Workstream A — Sonnet 5 (shared SSOT + examples)

- **`classification.md` §2.1** detection chain → `claude-sonnet-5 → claude-sonnet-4-6 → claude-sonnet-4-5` (currently `4-6 → 4-5` at lines 110–111).
- **`classification.md` §2** Opus-chain *fallback tail* (currently `… → opus-4-6 → sonnet-4-6 → sonnet-4-5` at lines 82–83) → lead the Sonnet fallback with `claude-sonnet-5`: `… → opus-4-6 → sonnet-5 → 4-6 → 4-5`.
  Opus primaries (`opus-4-8 → 4-7 → 4-6`) **unchanged**.
- **Literal-ID example blocks** (embed Sonnet IDs, must lead with `claude-sonnet-5`): `document.md:183`, `epics.md:104`, `docs-profile.md:60`, `docs-profile.md:61`, `docs-profile.md:64`, `docs-profile.md:73`, `docs-profile.md:75`.
- **Symbolic dispatch references** (`<detection_model — §2.1 Sonnet chain>`) need no per-ID edit — they cascade from the SSOT.
- **Leave** `CHANGELOG.md:132` (historical example). **Opus 4.8 stays** on frontmatter-pinned gates.
- **SSOT doctrine fix (uniform scan routing):** rewrite `classification.md` §8.3 and §9.4, and
  `implement.md`'s Invariant (line ~539), to drop "`jira-reader`/`code-scanner` inherit the session
  model" — replacing it with "pinned to the §2.1 detection (Sonnet) chain like every mechanical step,"
  keeping only the size-driven oversized-slice→Opus escalation. `/epics`/`/document` already scan on
  Sonnet, so this removes a carve-out only `/implement` referenced. Also pin `/implement`'s
  capture-mode `test-baseliner` (both `test-baseliner` calls now Sonnet-pinned).

### Workstream B — per-step routing

**`/implement` (flat → full adoption, mirror `/epics`/`/document`):**
- Phase 1.5: build the full §4 `model_routing` block (classification + `current_model` +
  `detection_model` + `planning_model` + `review_model` + `opus_available` + `notes`).
- Dispatch pins:

  | Dispatch | Tier |
  |---|---|
  | `jira-reader` (Phase 1.7) | `detection_model` (Sonnet) |
  | `code-scanner` (Phase 1.7) | `detection_model` (Sonnet) |
  | Phase 2A exploration (general-purpose, read-only) | `detection_model` (Sonnet) |
  | `risk-planner` (Phase 2B) | Opus (frontmatter, no override) |
  | `test-writer` (Phase 3.5 / 3B) | `detection_model` (Sonnet) |
  | `test-baseliner` (Phase 3.5) | `detection_model` (Sonnet) |
  | `code-review` (Phase 3B) | Opus (frontmatter, no override) |
  | `review-fixer` (Phase 3B) | `fixes_model` = `detection_model` (Sonnet) |
  | interactive implementation coding | `current_model` (session) — orchestrator codes inline |

  This finally *enforces* the existing "NEVER use Opus for routine implementation unless explicitly asked" principle via routing rather than convention.

**`/vuln` (nested → shallow):** complete the `model_routing` block to the full §4 schema and pin
coordinator dispatches:

  | Dispatch | Tier |
  |---|---|
  | `vuln-research` | Sonnet (detection) |
  | `vuln-fixer` | Sonnet (mechanical); Opus (`planning_model`) if HIGH-RISK |
  | `code-review` | Opus (frontmatter) |
  | `review-fixer` | Sonnet |

**`/upgrade` (nested → shallow):** same treatment:

  | Dispatch | Tier |
  |---|---|
  | `upgrade-planner` | Sonnet (compat detection) |
  | `test-baseliner` | Sonnet |
  | `upgrade-executor` | Sonnet (mechanical apply); Opus if HIGH-RISK |
  | `risk-planner` | Opus (frontmatter) |
  | `code-review` | Opus (frontmatter) |
  | `review-fixer` | Sonnet |

**Mechanism note:** each coordinator dispatch is pinned via `model:` (so it runs on the tier) AND
receives the `model_routing` block as data (for its internal gate decisions + report validation). A
Sonnet-pinned coordinator's internal leaves (e.g. `vuln-fixer` → `test-baseliner`) inherit Sonnet
because they are dispatched without their own `model:` — Level 2 handled for free.

### Packaging (lock-step)

- `plugins/dev-workflows/.claude-plugin/plugin.json`: `version` 2.2.1 → 2.3.0.
- `.claude-plugin/marketplace.json`: `plugins[0].version` 2.2.1 → 2.3.0 (siblings 0.2.2 / 0.3.1 untouched).
- `plugins/dev-workflows/CHANGELOG.md`: prepend `## [2.3.0] — 2026-07-02` above `## [2.2.1]`.

## Verification (structural — no test framework)

- `classification.md`: `claude-sonnet-5` leads §2.1 (line ~110) and the §2 Sonnet fallback tail (~82);
  fallbacks `4-6`/`4-5` still present beneath.
- Example blocks (`document.md`, `epics.md`, `docs-profile.md`) lead with `claude-sonnet-5`.
- `/implement`, `/vuln`, `/upgrade`: each mechanical dispatch cites `detection_model` / §2.1 Sonnet
  chain; each judgment gate (`risk-planner`, `code-review`) has NO `model:` override (keeps frontmatter Opus); the full §4 `model_routing` block is present in each Phase 1.5 / Step 0.
- `python3 -c json.load` on both manifests; `plugins[0].version == "2.3.0"`; siblings unchanged.
- `CHANGELOG.md`: `[2.3.0]` prepended; `[2.2.1]` and older preserved.
- Plugin repo has no husky/prettier hook → commit runs clean.

## Non-goals

No change to Opus primaries or gate frontmatter pins; no Sonnet-5 on review/planning gates yet; no
deep agent-internal threading (shallow chosen); no re-routing of `/epics`/`/document`/`/docs-profile`
beyond the shared Sonnet-5 ID bump; B4 (working-file follow-up tasks) and brainstorm-spec-from-Jira stay out.

## Execution

~9 files with semantic routing edits across 3 command flows. Recommend
**subagent-driven-development** (per-task implementer + reviewer, whole-branch Opus review) over
inline — the review value is real (routing correctness, gate-pin preservation) unlike v2.2.1's
mechanical text edits. Likely task split: T1 SSOT + Sonnet 5 + example blocks; T2 `/implement`;
T3 `/vuln`; T4 `/upgrade`; T5 packaging.
