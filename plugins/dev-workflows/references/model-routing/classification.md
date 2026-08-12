# Model Routing by Task Complexity (Shared Policy)

This document is the **single source of truth** for how the dev-workflows commands (`/implement`, `/vuln`, `/upgrade`, and related commands) and their sub-agents classify tasks and route them to the
appropriate model. Every top-level orchestrator MUST load and follow this policy
before doing any planning, implementation, or review work.

---

## 1. Complexity Classes

Every task MUST be classified into exactly one of:

| Class         | Plain meaning                                                                 |
|---------------|-------------------------------------------------------------------------------|
| `SIMPLE`      | Trivial, mechanical, low blast radius (typo, comment, single-line tweak).     |
| `MODERATE`    | Localized feature/fix in 1–3 files, well-understood, no security implications.|
| `SIGNIFICANT` | Multi-file or cross-cutting, non-trivial design, real correctness risk.       |
| `HIGH-RISK`   | Security-, data-, or contract-sensitive; mistakes cause outages or breaches.  |

### 1.1 Classify as `SIGNIFICANT` or `HIGH-RISK` if **any** of the following apply

- Major framework or library upgrade (any **major** version bump, e.g. Spring Boot 2→3, React 17→18, Java 11→21).
- Vulnerability fix that requires a **major** dependency version bump or **source-code changes** in the repo (API renames, signature changes, deprecation removals, behaviour adaptations). See the "Vulnerability-fix exception" below — a CVE's category alone (RCE, deserialization, auth bypass, etc.) does **not** force this class regardless of which orchestrator (`/vuln`, `/implement`, `/upgrade`) is invoking the rubric; what matters is the size of the actual fix.
- Touches authentication, authorization, sessions, tokens, OAuth/OIDC, JWT, cookies, CSRF, CORS, or permissions.
- Touches database schema, migrations, or data integrity (DDL, foreign keys, indexes, backfills).
- Public API or wire-protocol contract changes (REST/GraphQL/gRPC routes, request/response shape, event schemas, SDK signatures).
- Broad refactoring across multiple modules.
- Concurrency, caching, transactions, locking, retries, idempotency, async/queue processing.
- Payment, billing, audit, compliance, PII, or other security-sensitive logic.
- Changes touching **more than 3–5 non-test files**.
- **Multi-source input** — `/implement` was given more than one code repository, or any directory input (an exported Jira ticket folder, or a spec/design folder). Large multi-source briefs are cross-cutting by nature; this floors the task at `SIGNIFICANT`. See §8 for the fan-out scan this triggers. The floor is overridable at plan approval if the user judges the work genuinely smaller than its input footprint.
- Unclear requirements, large unknowns, or otherwise high blast radius.

`HIGH-RISK` is the same list with an additional severity multiplier — pick it
when the change is **production-critical, security-critical, or data-irreversible**
(e.g. an auth bypass CVE in a public service; a destructive DB migration).

### 1.2 Classify as `MODERATE` when

- 1–3 files; well-scoped feature, bugfix, or refactor; no items from §1.1 apply.

### 1.3 Classify as `SIMPLE` when

- Single trivial edit (typo, formatting, log message, comment, dead-code removal)
  with no behavioural impact.

> **When in doubt, escalate one level.** Misclassifying upward is cheap; the
> only cost is one extra Opus call. Misclassifying downward can ship bugs.

> **Vulnerability-fix exception — classify by fix size, not CVE category.**
> Two distinct rules apply here:
>
> **(a) Universal — CVE category never forces SIGNIFICANT/HIGH-RISK.** A
> CVE's category (RCE, deserialization, auth bypass, etc.) drives *attention*
> but does **not** by itself force a SIGNIFICANT/HIGH-RISK class, regardless
> of which orchestrator (`/vuln`, `/implement`, `/upgrade`) is invoking the
> rubric. Most CVEs are remediated by a patch or minor dependency bump with
> no source-code changes — those are MODERATE.
>
> **(b) Per-CVE size analysis — `/vuln` orchestrator only.** Only `/vuln`
> performs per-CVE fix-size analysis. In `/vuln`, escalate to SIGNIFICANT
> when the fix requires a major version bump or actual code changes in the
> repo (API renames, signature changes, deprecation removals, behaviour
> adaptations). Escalate to HIGH-RISK when a major bump targets a
> security-critical library (auth/authn frameworks, crypto, deserializers,
> JWT, OAuth, session libs). See `${CLAUDE_PLUGIN_ROOT}/commands/vuln.md`
> "Step 0 — Classify & Route" for the full vulnerability rubric.
>
> **For `/implement` and `/upgrade` orchestrators**, the standard rubric in §1.1
> applies — there is no per-CVE size analysis available at classification
> time. If the user wants CVE-aware sizing, route the work through `/vuln`.

---

## 2. Model fallback chain ("strongest available reasoning model")

Use the first model in this list that is available in the environment:

1. `claude-opus-5`
2. `claude-opus-4-8`
3. `claude-opus-4-7`
4. `claude-opus-4-6`
5. `claude-sonnet-5` (fallback only — note in the report that no Opus was available)
6. `claude-sonnet-4-6` (further fallback)
7. `claude-sonnet-4-5` (further fallback — note "no Opus or Sonnet 5/4.6 available")

Sonnet 4.5 is the floor; if no model in the list is available, abort the
SIGNIFICANT/HIGH-RISK gates and ask the user how to proceed rather than
silently downgrading.

The list of available models can be inspected from the `task` tool's `model`
parameter documentation. If none of the Opus models are available **and** the
task is `SIGNIFICANT` / `HIGH-RISK`, proceed with Sonnet but **announce the
degradation** in the Phase 0 / Step 0 routing record and again in the final report.

The "currently selected model" is whatever the orchestrator itself is running
under. Sub-agents inherit it unless the orchestrator explicitly overrides via
the `task` tool's `model` argument.

---

## 2.1 Mid-tier ("detection / throughput") fallback chain

Some steps are deliberately **not** reasoning-heavy — mechanical detection,
repo scanning, transcription, formatting. Pin these to the strongest **Sonnet**
model available via the `task` tool's `model:` override; do **not** let them
inherit the session model (an Opus session would otherwise run "cheap" steps on
Opus, defeating the point).

Use the first available:

1. `claude-sonnet-5` (latest Sonnet)
2. `claude-sonnet-4-6` (fallback)
3. `claude-sonnet-4-5` (further fallback — note the degradation in the report)

If neither Sonnet is available, fall back to the session model and announce it.
Record the chosen model as `detection_model:` in the `model_routing` block.

---

## 3. Routing rules

### 3.1 SIMPLE / MODERATE

- Continue with the currently selected model.
- Do **not** add mandatory Opus steps.
- Proceed with normal planning, implementation, testing, and fixes.
- Skip the dedicated Opus code review (the standard `risk-planner` consult
  — when called — uses the workflow's default model selection).

### 3.2 SIGNIFICANT / HIGH-RISK — mandatory sequence

The orchestrator MUST execute these steps in order:

1. **Classify** the task and record the decision (see §4).
2. **Plan with Opus.** Delegate planning (or planning critique) to a sub-agent
   running on the strongest available reasoning model from §2. See §5 for the
   exact `task` invocation pattern.
3. **Implement** with the currently selected model **or** Sonnet (Sonnet is fine
   for raw coding throughput; Opus is not required here). Sub-agents that do
   the actual file edits inherit the orchestrator's model unless overridden.
4. **Opus code review** of the completed implementation. This is a dedicated
   `code-review` sub-agent invocation pinned to Opus. It MUST cover every item
   in the §6 checklist. Tests MUST NOT be run until this review completes.
5. **Run tests** (build + test suite per the executor / fixer workflow).
6. **Apply review fixes** — fixes flagged by the Opus review may be implemented
   by the currently selected model **or** Sonnet (no Opus required for the fix
   edits themselves).
7. **Re-run tests** if any review fixes were applied.
8. **Final summary** — include the classification, the Opus models used at each
   step (or the Sonnet fallback notice), and a one-line outcome per checklist
   item from §6.

> **Do not use Opus for routine implementation steps unless the user explicitly
> requested it.** Opus is reserved for the planning and the dedicated review.

---

## 4. The `model_routing` handoff block

Every orchestrator MUST record its routing decision and pass it to every
sub-agent it invokes. Format:

```yaml
model_routing:
  classification: SIMPLE | MODERATE | SIGNIFICANT | HIGH-RISK
  reason: <one-line justification citing the §1 trigger that applied>
  current_model: <e.g. claude-opus-5>        # the model the orchestrator is running
  planning_model: <e.g. claude-opus-5>       # only set for SIGNIFICANT/HIGH-RISK
  review_model:   <e.g. claude-opus-5>       # only set for SIGNIFICANT/HIGH-RISK
  implementation_model: <e.g. claude-sonnet-5 or current_model>
  detection_model: <e.g. claude-sonnet-5>    # mid-tier steps (§2.1); never the session model
  fixes_model:    <same as implementation_model>
  opus_available: true | false
  gate_tests_on_review: true | false   # optional; default false. Only meaningful for SIGNIFICANT/HIGH-RISK.
                                       # When true, the executor/fixer sub-agent stops after the build,
                                       # returns status: AWAITING_REVIEW, and waits for a follow-up call
                                       # with phase: verify-resume to run tests / commit / PR.
  notes: <optional — e.g. "Opus 5 unavailable, fell back to 4.8">
```

The `phase` field used to resume an executor/fixer after the Opus review is
completed is **`verify-resume`** (harmonised across `/upgrade` and `/vuln`
workflows). The executor/fixer must accept this value and run all remaining
steps (verify tests; for the fixer also commit + PR).

For SIMPLE/MODERATE the `planning_model` and `review_model` fields MAY be omitted
or set to `current_model`.

Sub-agents that receive a `model_routing` block:

- Research / planning sub-agents (NVD lookup, detect, compatibility checks):
  use the `planning_model` if present (orchestrator should invoke them with
  the corresponding `task` tool `model:` arg).
- Executor / fixer sub-agents: **do not run tests** until the orchestrator
  has confirmed the Opus review has completed (when classification is
  SIGNIFICANT/HIGH-RISK). The orchestrator achieves this by invoking the
  executor/fixer **without** the build+test phase first (apply changes only),
  then running the review, then invoking the executor/fixer again to run tests.
  Equivalently, the orchestrator may invoke a single combined call with a
  `gate_tests_on_review: true` flag — both styles are acceptable.
- `risk-planner`, `code-review`, `epic-reviewer`: the orchestrator pins these to
  the §2 fallback chain via the `task` tool's `model:` argument. They receive
  the `model_routing` block for context validation and reporting.
- `doc-fixer`, `doc-location-finder`, `doc-planner`, `docs-style-checker`,
  `doc-reviewer`: receive the block for reporting; behaviour is unchanged.
- `test-baseliner`, `impl-maintenance`: receive the block for reporting only;
  behaviour is unchanged.

---

## 5. Delegating to a model via the `task` tool

The CLI's `task` tool accepts an explicit `model:` override. Use it like this:

```
task(
  subagent_type: "dev-workflows:risk-planner" | "dev-workflows:code-review" | "general-purpose",
  model:      "claude-opus-5",   # or the highest available per §2
  prompt:     "<full self-contained context — sub-agent has no memory>",
  description:"Opus planning critique" | "Opus code review",
  mode:       "sync"               # always sync for plan/review gates
)
```

- For **planning** on SIGNIFICANT/HIGH-RISK tasks, prefer `subagent_type: "dev-workflows:risk-planner"`
  with Opus, asking it to critique the proposed plan.
- For **post-implementation review** on SIGNIFICANT/HIGH-RISK tasks, use
  `subagent_type: "dev-workflows:code-review"` with Opus, passing the diff and §6 checklist.
- If `code-review` is unavailable in the environment, fall back to
  `subagent_type: "general-purpose"` with the same Opus model and the explicit
  §6 checklist embedded in the prompt.

---

## 6. Mandatory Opus code-review checklist (SIGNIFICANT / HIGH-RISK)

The post-implementation Opus review MUST explicitly comment on each of:

1. **Correctness** — does the change actually do what was planned, including all
   listed acceptance criteria and edge cases?
2. **Security impact** — new attack surface, authn/authz changes, secret
   handling, input validation, deserialization, injection vectors, supply chain.
3. **Architectural consistency** — boundaries respected, abstractions intact,
   no leaking concerns, idiomatic for the codebase.
4. **Missed edge cases** — empty/null/zero/negative/very-large inputs, partial
   failures, concurrent access, time-zone / DST / locale, off-by-one, retries.
5. **Migration risks** — schema changes, data backfills, feature flags, ordering
   between deploy and migration, forward/backward compatibility windows.
6. **Dependency risks** — new transitive deps, license changes, abandoned
   packages, known CVEs in the new versions, lockfile drift.
7. **Test adequacy** — does the test suite actually cover the new behaviour?
   Are negative tests and boundary tests present? Are tests deterministic?
8. **Rollback considerations** — how is this change reverted? Are migrations
   reversible? Is there a feature flag? What is the worst-case incident playbook?

The review output MUST include a verdict per item: `OK` / `CONCERN` / `BLOCKER`,
plus a free-text comment for any non-`OK` finding. The orchestrator MUST address
every `BLOCKER` (and document the disposition of each `CONCERN`) before
proceeding to tests.

---

## 7. Reporting

The orchestrator's final report MUST include a `### Model Routing` section:

```
### Model Routing
- Classification: <class>
- Reason: <trigger>
- Planning model: <model>
- Implementation model: <model>
- Review model: <model>  (or "n/a — SIMPLE/MODERATE")
- Opus checklist verdicts:
  - Correctness: OK | CONCERN | BLOCKER
  - Security: ...
  - Architecture: ...
  - Edge cases: ...
  - Migration: ...
  - Dependencies: ...
  - Tests: ...
  - Rollback: ...
- Notes: <degradation, fallbacks, deferred items>
```

For SIMPLE/MODERATE tasks the verdict list MAY be omitted; the classification
and reason are still required.

---

## 8. Large-input scan fan-out

When a scanning step must digest more than a single working tree, a single
explorer subagent on a weak session model comprehends it poorly. This section
is the shared policy for that case. It is consulted by `/implement` and
generalizes the pattern `/epics` already uses.

### 8.1 Trigger (input shape, not measured volume)

Fan out when **any** of these structural facts hold for the invocation:

- more than one code repository is referenced;
- an exported Jira ticket folder is supplied;
- a spec/design folder is supplied.

Counting files or bytes is explicitly **not** used — the trigger is the shape
of the input, which is cheap to detect and easy to explain. A single repo with
inline/`@file` text only does **not** trigger fan-out; the caller keeps its
normal single-explorer path.

### 8.2 The fan-out pattern

1. `jira-reader` reads each ticket folder (read-only) → themes, PR references
   (identifiers only), linked items.
2. Spec/design folders are read inline and folded into the themes.
3. `code-scanner` is fanned out **one instance per repository, in a single
   response, capped at 4 concurrent**. Each instance receives the themes and
   its own repo path; it returns capabilities, gaps, and relevant files.
4. The orchestrator synthesizes the `jira-reader` output, all scanner reports,
   and the spec into one codebase summary that feeds the Opus planner.

### 8.3 Model routing inside the fan-out

- `jira-reader` and `code-scanner` are **pinned to the §2.1 detection (Sonnet)
  chain** via the `task` tool `model:` override — the same rule as every other
  mechanical step (§2.1, §9.1). Scanning is mechanical filesystem work; it must
  not inherit the session model (an Opus session would otherwise burn Opus on a
  cheap step), and its tier must not depend on which model the session happens
  to run under.
- Because the trigger floors the task at `SIGNIFICANT` (§1.1), synthesis and
  planning run on the strongest available reasoning model via `risk-planner`
  (§2 chain). That is where reasoning power is applied — the mechanical scan
  that feeds it does not need it.
- **Optional escalation:** if a single repo slice is itself oversized for the
  detection tier to comprehend, the orchestrator MAY pin that one `code-scanner`
  to Opus via the `task` tool `model:` override. This is a size-driven, judgment-
  based exception — not session-driven.

### 8.4 Honesty

A referenced directory that is missing, or is neither a recognized folder type
nor a git repository, MUST be surfaced to the user — never silently skipped
(mirrors the `REFRESH_BLOCKED` honesty rule used by the Jira-driven flows).

### 8.5 Broad, then narrow (the seeded second round)

A broad prompt lets each scanner defer to the layer it did not scan. Round 1
asks every repo the same wide question, and a capability spanning two layers can
come back attributed to the *other* layer by both scanners — a pair of confident
answers that together say nothing. Naming a verified anchor removes the escape.

**Round 1** is the §8.2 fan-out unchanged: one `code-scanner` per repository,
broad themes, single response, cap 4 concurrent.

**Inconclusive** describes a round-1 theme whose `classification` is `partial`,
`absent`, or `error`, **or** for which **two or more** scanners' per-theme
`capability_map[].gap_summary` texts point at each other's repo in a cycle, or
at a component/subsystem that no scanned repo covers.

**Round 2** fires for an inconclusive theme when round 1 produced at least one
evidence anchor to seed from. It dispatches the **same** `code-scanner` agent
with a narrowed brief:

- `capability_themes` holds exactly **one** question — not the broad theme, but
  the single thing round 1 failed to settle;
- `search_hints.paths` / `.symbols` / `.keywords` are seeded from round 1's
  verified `evidence[].path` and `.symbols`; where an evidence entry carries
  `lines`, name the anchor as `<path>:<line>` in the round-2 `context` prose,
  since `search_hints` has no line-number field.

No new agent and no input-contract change: the narrowing lives entirely in what
the caller puts in the existing fields.

**Bounds.** Round 2 is capped at **4 dispatches** and is **one round only**.
There is no round 3. A theme still inconclusive after round 2 is reported
unresolved — never guessed at. **Precedence: mutual deferral and `error` are
unresolved regardless of whether a round-1 evidence anchor existed to seed a
round 2** — a theme with no anchor never gets a round-2 attempt, but the
absence of an attempt is not itself a resolution. A theme confirmed `absent`
— by round 2, or by round 1 when no anchor existed to seed one — is a
**resolved** finding only when that `absent` carries **no deferral to a repo
or layer outside the scanned set**: for `/idea`, it belongs in Section 7's
*What's missing*, not in Open questions. `[NEEDS CLARIFICATION]` (or the
caller's equivalent) is for a theme the scan could not settle — mutual
deferral, `error`, or `absent` everywhere scanned **plus** a deferral outside
the scanned set.

The altitude differs by caller. For `/idea --ground-code`, the confirmed repo
set **is** the world the idea is grounding against, so `absent` everywhere
scanned genuinely means missing. For `/implement`'s fan-out, the premise is
that the capability lives *somewhere* across the repos in scope — so `absent`
everywhere scanned **plus** a deferral outside the scanned set means "the scan
could not tell," not "the capability does not exist."

**Opt-in.** §8.5 is a shared procedure a caller adopts by saying so in its own
body. Its consumers are `/idea` (Phase 2.6) and `/implement` (Phase 1.7).
`/epics`, `/create-ard`, `/specify`, and `/design` run §8.2 alone and are
unaffected by this section.

**Round 2 resolves; it does not license a guess.** A caller that adopts §8.5
also owes its downstream consumer the truth about what stayed unresolved. An
inconclusive theme is not a gap: a gap asserts the capability is absent, an
unresolved theme asserts only that the scan could not tell, and flattening the
second into the first hands the next step a confident-looking answer that was
never earned. Name unresolved themes explicitly in whatever the caller passes
on — `/idea` carries them into `[NEEDS CLARIFICATION]`, `/implement` into the
codebase summary's `## Unresolved` section and from there into the plan's
risks.

---

## 9. Per-step routing for multi-phase authoring pipelines

The Jira-driven authoring pipelines (`/document` and `/epics`) run a long sequence of phases — some
judgment-heavy, some mechanical. They MUST NOT let every step inherit the
session model. Apply this policy, resolving each model against the §2 (Opus)
and §2.1 (Sonnet) fallback chains.

### 9.1 Principle

- **Judgment-heavy authoring / synthesis** steps run on the §2 reasoning (Opus)
  chain — escalate to Opus even when the session is Sonnet.
- **Mechanical detection / throughput / fix** steps run on the §2.1 detection
  (Sonnet) chain — de-escalate off the session model even when the session is
  Opus (otherwise an Opus session burns Opus on cheap work).
- **Orchestrator-executed** judgment steps — the inline prose writing and the
  interactive gates, plus the orchestration itself — run on the session model
  and CANNOT be overridden from inside a running command. Handle them with an
  **advisory** (recommend relaunching on the §2 chain), never an override. This advisory applies when the task is SIGNIFICANT/HIGH-RISK; for SIMPLE/MODERATE the writer runs on its detection pin without a relaunch advisory (per §3.1).

### 9.2 Role → chain map

| Role | Chain |
|------|-------|
| Synthesis / planner (e.g. `doc-planner`) | §2 reasoning (Opus) |
| Reader / summarizer / locator / style-checker / fixer / maintenance (`jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, maintenance agents) | §2.1 detection (Sonnet) |
| Domain reviewer (`doc-reviewer`, `epic-reviewer`) | §2 review (Opus) — usually already frontmatter-pinned; the orchestrator records it and adds **no** override |
| Delegated writer (`doc-writer` / `epic-writer`) | §2 reasoning (Opus) for SIGNIFICANT/judgment writing; §2.1 detection (Sonnet) for MODERATE writing |
| Coordination + interactive gates (the orchestrator itself) | session model; narrowed window advisory for large non-Opus runs (§9.1) |

### 9.3 No-Opus degradation

When no Opus model is available (per §2), run the reasoning / review roles on the
Sonnet floor, **skip** the relaunch advisory (there is nothing to relaunch onto),
and announce the degradation in the `model_routing` record and the final report —
the same rule as §2.

### 9.4 One rule across commands (`/implement` included)

Routing is by **step nature**, not by pipeline or session: `jira-reader` and
`code-scanner` are mechanical, so they run on the §2.1 detection (Sonnet) chain
in **every** command — `/implement`'s fan-out (§8.3), `/epics`, and `/document`
alike. There is no "inherit the session model" for scanning and no per-command
exception. A step's downstream consumer does not change its tier: a mechanical
scan that feeds an Opus synthesis (e.g. `/implement`'s `risk-planner`) still runs
on Sonnet — the reasoning power is applied in the synthesis step, not the scan.
The only carve-out is size-driven, not session-driven: escalate a single
oversized repo slice's `code-scanner` to Opus (§8.3).
