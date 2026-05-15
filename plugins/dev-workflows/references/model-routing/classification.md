# Model Routing by Task Complexity (Shared Policy)

This document is the **single source of truth** for how the `/impl`, `/vuln`, and
`/upgrade` workflows (and their sub-agents) classify tasks and route them to the
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
- Vulnerability fix that requires a **major** dependency version bump or **source-code changes** in the repo (API renames, signature changes, deprecation removals, behaviour adaptations). See the "Vulnerability-fix exception" below — a CVE's category alone (RCE, deserialization, auth bypass, etc.) does **not** force this class regardless of which orchestrator (`/vuln`, `/impl`, `/upgrade`) is invoking the rubric; what matters is the size of the actual fix.
- Touches authentication, authorization, sessions, tokens, OAuth/OIDC, JWT, cookies, CSRF, CORS, or permissions.
- Touches database schema, migrations, or data integrity (DDL, foreign keys, indexes, backfills).
- Public API or wire-protocol contract changes (REST/GraphQL/gRPC routes, request/response shape, event schemas, SDK signatures).
- Broad refactoring across multiple modules.
- Concurrency, caching, transactions, locking, retries, idempotency, async/queue processing.
- Payment, billing, audit, compliance, PII, or other security-sensitive logic.
- Changes touching **more than 3–5 non-test files**.
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
> of which orchestrator (`/vuln`, `/impl`, `/upgrade`) is invoking the
> rubric. Most CVEs are remediated by a patch or minor dependency bump with
> no source-code changes — those are MODERATE.
>
> **(b) Per-CVE size analysis — `/vuln` orchestrator only.** Only `/vuln`
> performs per-CVE fix-size analysis. In `/vuln`, escalate to SIGNIFICANT
> when the fix requires a major version bump or actual code changes in the
> repo (API renames, signature changes, deprecation removals, behaviour
> adaptations). Escalate to HIGH-RISK when a major bump targets a
> security-critical library (auth/authn frameworks, crypto, deserializers,
> JWT, OAuth, session libs). See `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/commands/vuln.md`
> "Step 0 — Classify & Route" for the full vulnerability rubric.
>
> **For `/impl` and `/upgrade` orchestrators**, the standard rubric in §1.1
> applies — there is no per-CVE size analysis available at classification
> time. If the user wants CVE-aware sizing, route the work through `/vuln`.

---

## 2. Model fallback chain ("strongest available reasoning model")

Use the first model in this list that is available in the environment:

1. `claude-opus-4.7`
2. `claude-opus-4.6`
3. `claude-opus-4.5`
4. `claude-sonnet-4.6` (fallback only — note in the report that no Opus was available)
5. `claude-sonnet-4.5` (further fallback — note "no Opus or Sonnet 4.6 available")

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
5. **Run tests** (build + test suite).
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
  current_model: <e.g. claude-opus-4.7>      # the model the orchestrator is running
  planning_model: <e.g. claude-opus-4.7>     # only set for SIGNIFICANT/HIGH-RISK
  review_model:   <e.g. claude-opus-4.7>     # only set for SIGNIFICANT/HIGH-RISK
  implementation_model: <e.g. claude-sonnet-4.6 or current_model>
  fixes_model:    <same as implementation_model>
  opus_available: true | false
  gate_tests_on_review: true | false   # optional; default false. Only meaningful for SIGNIFICANT/HIGH-RISK.
                                       # When true, the executor/fixer sub-agent stops after the build,
                                       # returns status: AWAITING_REVIEW, and waits for a follow-up call
                                       # with phase: verify-resume to run tests / commit / PR.
  notes: <optional — e.g. "Opus 4.7 unavailable, fell back to 4.6">
```

The `phase` field used to resume an executor/fixer after the Opus review is
completed is **`verify-resume`** (harmonised across workflows). The
executor/fixer must accept this value and run all remaining steps (verify
tests; for the fixer also commit + PR).

For SIMPLE/MODERATE the `planning_model` and `review_model` fields MAY be omitted
or set to `current_model`.

Sub-agents that receive a `model_routing` block:

- `risk-planner`, `code-review`, `epic-reviewer`: the orchestrator pins these to
  the §2 fallback chain via the `task` tool's `model:` argument. They receive
  the `model_routing` block for context validation and reporting.
- `doc-fixer`, `doc-location-finder`, `doc-planner`, `docs-style-checker`,
  `doc-reviewer`: receive the block for reporting; behaviour is unchanged.
- `test-baseline`, `impl-maintenance`: receive the block for reporting only;
  behaviour is unchanged.

---

## 5. Delegating to a model via the `task` tool

The CLI's `task` tool accepts an explicit `model:` override. Use it like this:

```
task(
  agent_type: "risk-planner"  | "code-review" | "general-purpose",
  model:      "claude-opus-4.7",   # or the highest available per §2
  prompt:     "<full self-contained context — sub-agent has no memory>",
  description:"Opus planning critique" | "Opus code review",
  mode:       "sync"               # always sync for plan/review gates
)
```

- For **planning** on SIGNIFICANT/HIGH-RISK tasks, prefer `agent_type: "risk-planner"`
  with Opus, asking it to critique the proposed plan.
- For **post-implementation review** on SIGNIFICANT/HIGH-RISK tasks, use
  `agent_type: "code-review"` with Opus, passing the diff and §6 checklist.
- If `code-review` is unavailable in the environment, fall back to
  `agent_type: "general-purpose"` with the same Opus model and the explicit
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
