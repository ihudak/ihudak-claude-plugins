# superpowers → dev-workflows harvest

Read-only audit. Scope: places where `dev-workflows` **embedded/adapted** a superpowers
technique into its own commands/agents/references (candidates for refresh), as distinct
from **CALL sites** that invoke `superpowers:*` at runtime and get upstream improvements
for free (not interesting — no action).

Upstream inspected: `/workspace/dev/ai-tools/superpowers` (branch `main`, 680 commits total,
273 in the last 120 days). Skills read in full: `brainstorming`, `writing-plans`,
`subagent-driven-development`, `executing-plans`, `test-driven-development` (+
`writing-good-tests.md`), `systematic-debugging`, `requesting-code-review`,
`receiving-code-review`, `verification-before-completion`, `finishing-a-development-branch`,
`using-git-worktrees`, `dispatching-parallel-agents`.

Canonical plugin inspected: `/workspace/dev/ai-tools/ihudak-claude-plugins/plugins/dev-workflows`
— `commands/implement.md`, `agents/{risk-planner,code-review,review-fixer,test-writer,
test-baseliner,impl-maintenance}.md`, `references/{model-routing/classification,source-truth,
prose-formatting,design-format,context-management,session-hygiene}.md`,
`commands/prompt-brainstorm.md`.

## Method note — architecture mismatch

`subagent-driven-development` (SDD) and `writing-plans` are built around **decomposing a
plan into independent tasks, each executed by a fresh implementer subagent** with a
per-task review + fix loop. `/implement` does **not** use that architecture: the
orchestrator implements inline in one session; `risk-planner` produces one plan, and
`code-review`/`review-fixer` run **once** at the end (capped at one fix pass + one
re-review), not per-task. Most of SDD's recent, heaviest churn (plan-scoped `.superpowers/sdd/`
workspace, ledger, five-round fix breaker, per-round model escalation, task-brief/review-package
scripts) has **no clean landing surface** in our architecture — it answers a problem
(coordinating many subagent-executed tasks across a long, compaction-prone session) that
`/implement` doesn't have. Those items are marked Skip below with that rationale, not because
they were rejected on merits.

## Harvest table

| Upstream skill/change | Our embedding (file) | Adopt/Adapt/Skip | Why | Effort |
|---|---|---|---|---|
| `test-driven-development/writing-good-tests.md` (new file, built up over ~9 commits: falsifiability gate function, "no change detectors", mirror-assertion anti-pattern, mock-the-right-level discipline, production-methods-not-test-methods rule, mutation check) | `agents/test-writer.md` steps 5–6 + Hard rules | **Adopt** | Our embedded test-writing discipline ("cover happy path + one error path", "deterministic data", "match discovered style") is materially thinner than upstream's current rules. Concretely missing: (1) the gate function — name the exact production change that would make the new test fail, *before* writing it; (2) the "no change detector" trap (asserting a constant/private structure instead of the behavior that depends on it); (3) the mirror-assertion trap (expected value computed by the same code under test); (4) "production classes carry production methods only" (test-only cleanup belongs in test utilities, not the class under test); (5) a mutation-check self-review before returning. All five are concrete, cheap to state, and directly reduce the risk of `test-writer` producing tests that look like coverage but never fail on a real regression — which is exactly the failure mode Opus `code-review`'s "Test adequacy" dimension is supposed to catch, so a stronger `test-writer` reduces BLOCK-cycle churn. | M — add a short "Test quality gate" subsection to `test-writer.md` (steps 5–6) porting the 4 rules + mutation check; no architecture change. |
| `subagent-driven-development` fix loop: *"Finding conflicts with plan text? → ask human partner which governs"* (new, explicit branch in the resume-based fix-loop redesign) | `agents/review-fixer.md` (Fix method + Deferred reason enum); `commands/implement.md` Phase 3B step 7 | **Adopt** | `review-fixer`'s current "Deferred" reasons are design change / migration / process / cross-cutting test strategy / other. There is no explicit category for "this BLOCKER/MAJOR finding is really a disagreement with what the **approved** risk-planner plan explicitly mandated." Today that case silently falls into "fix it if locally actionable" (review-fixer overrides the plan without telling anyone) or a generic "other" defer (no signal that the plan itself may be wrong). Upstream's recent SDD redesign made this its own first-class branch specifically because silently overriding an approved plan, or silently deferring the conflict, both lose information the human needs. Cheap, concrete, and fits our existing "ask, don't guess" invariant. | S — add one Deferred-reason category ("plan-conflict — approved plan explicitly mandated this; needs human ruling") to `review-fixer.md`, and one sentence in `implement.md` Phase 3B step 7 telling the orchestrator to surface plan-conflict deferrals to the user immediately rather than waiting for the generic BLOCK-still-BLOCK path. |
| `writing-plans` "No Placeholders" self-review checklist (added alongside Task Right-Sizing / Global Constraints / Interfaces blocks) | `agents/risk-planner.md` "Planning discipline" section | **Adopt** (narrow slice only) | Upstream's Task Right-Sizing, Global Constraints header, and per-task Interfaces (Consumes/Produces) blocks are decomposition mechanics for a *multi-subagent-executed* plan — not applicable to `risk-planner`'s single-shot plan for inline implementation (Skip, architecture mismatch). But the **"No Placeholders" self-review pass** — scan the finished plan for "TBD", "add proper error handling", "similar to Task N", vague non-code instructions — is architecture-agnostic and cheap. `risk-planner.md` has no equivalent self-check today; its "Planning discipline" list (cite the criterion, minimize scope, name rejected alternatives, flag blockers, no implementation, re-classify) stops one short of "and then re-read your own plan for vagueness before returning it." | S — add one bullet to `risk-planner.md`'s Planning discipline list. |
| Context-preservation principle repeated across `subagent-driven-development` ("Hand artifacts over as files... everything you paste into a dispatch prompt stays resident in your context for the rest of the session") and `dispatching-parallel-agents` (same principle, "isolated context... construct exactly what they need") | `references/context-management.md` (cited by `implement.md` Phase 3B); the dispatch prompts in `implement.md` Phase 1.7, 2B, 3B literally say "paste the Phase 1.7 multi-source summary", "paste git diff output", "paste the full code-review agent output" | **Adapt** | `context-management.md`'s three strategies (Scope-to-N/checkpoint, sub-agent-per-`[P]`, decompose) cover *when* to offload, but not upstream's now-explicit *how*: write dispatch context (briefs, diffs, review packages, summaries) to a file and hand the subagent a path, rather than pasting the content into the prompt — because pasted content "stays resident in your context for the rest of the session and is re-read on every later turn." `/implement`'s own dispatch templates do exactly the anti-pattern upstream now names explicitly (paste multi-source summaries, full `git diff` output, full review reports into the prompt, which also land back in the orchestrator's context via the subagent's own echo/summary). For long/multi-Epic sessions this is a real, current cost driver, not a cosmetic gap. | M — add a fourth strategy ("Hand off by file, not paste") to `context-management.md`; a fuller fix touching the Phase 1.7/2B/3B "paste X" wording in `implement.md` is a separate, larger follow-up (not required to land the reference update). |
| `verification-before-completion` (Iron Law: no completion claim without fresh verification evidence run in this message) | `test-baseliner.md` capture/verify modes + `implement.md` Phase 3.5 / Pre-Phase 3.5 gating | **Skip** | Already well embedded: Phase 3.5 mandates a fresh `test-baseliner` verify run against the captured baseline before any "tests pass" claim, and the fix loop re-runs verify after every fix attempt rather than trusting the prior run. Upstream's own recent history on this skill is a single "drop persuasion sections" editorial trim — no functional change to harvest. |
| `requesting-code-review` / `receiving-code-review` (recent churn: trim to table form; "scope spec reviewer to task diff, make reviewers read-only") | `agents/code-review.md`, `agents/review-fixer.md` | **Skip** | Already matches: `code-review.md` is read-only ("NEVER modify files. The reviewer reads; the caller writes."), diff-scoped, and produces a severity-tagged findings list the caller (not the reviewer) acts on — exactly the shape upstream's "read-only reviewer, task-diff-scoped" change codified. Nothing upstream added here that we lack. |
| `dispatching-parallel-agents` ("issue all dispatches in the same response = parallel"; focused/self-contained/specific-about-output prompt structure) | `implement.md` Phase 1.7 (`code-scanner` fan-out, cap 4) and Phase 4 (four maintenance agents in one message) | **Skip** | Already a faithful, current embedding — "spawn them all before waiting for any to complete," capped concurrency, one bounded scope per agent. Upstream churn here is purely editorial (dropped a "social proof" paragraph). No drift. |
| `subagent-driven-development` "park with a ruling, never silently discard" (findings that don't block get an explicit ruling recorded in the ledger, re-surfaced at final review) | `code-review.md` PASS-WITH-RECOMMENDATIONS handling; `implement.md` Phase 5 `### Deferred items` | **Skip** | Already equivalent in spirit at our scale: MINOR/NIT findings are recorded (not silently dropped) in the Phase 5 report with severity + location + reason. The upstream version is heavier machinery (a ledger, re-surfaced at a *later* final-branch review) built for the multi-task SDD loop we don't run; a one-shot report entry is the right-sized analog for a one-shot review gate. |
| `systematic-debugging` (Iron Law: root-cause investigation before any fix; 3-strikes → question architecture) | — (grepped the whole plugin: no `root cause` / `systematic-debug` reference anywhere) | **Not embedded — no candidate** | `review-fixer.md`'s fix method goes straight from "parse findings" to "fix if locally actionable"; it never adopted a root-cause-first discipline, so there's nothing to refresh. Flagging as a genuine gap would be a *new adoption*, out of this audit's scope (embedded-and-stale only). |
| `using-git-worktrees`, `finishing-a-development-branch` (isolated workspace before implementation; post-implementation merge/PR/keep-as-is menu) | — (grepped the whole plugin: no `worktree` reference anywhere; `implement.md` Pre-Phase 3 does a plain `git checkout -b` on the current tree, and Phase 5 ends with a report + "Next step" recommendation, never a merge/PR/keep menu) | **Not embedded — no candidate** | Neither technique was ever adopted (by design — `/implement` works directly in the current checkout, not a worktree, and leaves branch integration to the user). Nothing to refresh; adopting either now would be a new feature decision for the plugin maintainer, not a "catch-up" refresh. |
| `writing-plans` Task Right-Sizing / Global Constraints header / per-task Interfaces (Consumes/Produces) blocks | `risk-planner.md` plan shape | **Skip (architecture mismatch)** | These mechanics exist to let an *independent fresh subagent* execute one task correctly without reading the whole plan. `risk-planner` produces a single plan for **inline** orchestrator execution in the same session — there is no per-task subagent that needs an isolated Interfaces block. Porting this would add ceremony with no consumer. |
| `subagent-driven-development` ledger + plan-scoped `.superpowers/sdd/<plan>/` workspace, 5-round fix breaker with per-round model escalation, `task-brief`/`review-package` scripts | `implement.md` Phase 3B fix cycle (cap: one `review-fixer` pass + one re-review, then stop and ask) | **Skip (architecture mismatch)** | This is the heaviest recent churn in superpowers (the `ebdd4ec` "lifecycle restructure" release) but it solves compaction-survival and per-task coordination across a long multi-subagent execution — a problem `/implement` doesn't have (single orchestrator, single review gate, capped at one retry by explicit design). Our simpler cap-at-one-then-escalate-to-human is arguably *more* conservative than upstream's 5-round automated loop, not behind it. |

## Out of scope — different upstream lineage (not superpowers, noted for completeness)

- `references/grilling-technique.md` and `references/design-format.md` explicitly self-declare
  **"adapted from mattpocock grill-me/grilling"** — a different upstream project entirely, not
  `superpowers`. The embedded grilling technique used by `/idea`, `/create-vi`, `/update-vi`,
  `/create-ard`, `/specify`, `/design` is therefore not a candidate for a superpowers-driven
  refresh; if it needs refreshing, that's a separate audit against the mattpocock skill.
- `references/model-routing/classification.md`'s role-tiering (mechanical/detection vs.
  reasoning/judgment steps get different model chains) is conceptually adjacent to SDD's
  "Model Selection" section (mechanical vs. integration vs. architecture tiers, "turn count
  beats token price"), but carries no provenance note and uses an entirely independent
  taxonomy (`SIMPLE`/`MODERATE`/`SIGNIFICANT`/`HIGH-RISK` vs. upstream's task-signal buckets).
  Read as parallel, independently-evolved design, not an embedding — no action.
- Note for context, not actionable via this audit: `/implement` writes tests **after**
  implementation (`test-writer` runs post-diff, gated by Opus `code-review`'s "Test adequacy"
  dimension), which is the opposite order from TDD's Iron Law ("no production code without a
  failing test first"). This is a long-standing architectural choice, not a regression caused
  by upstream drift — the TDD skill's Iron Law itself hasn't changed. Flagging only so it isn't
  mistaken for an oversight during any future redesign discussion.

## CALL sites (auto-benefit, no action)

- `commands/prompt-brainstorm.md` — hands off to `superpowers:brainstorming` via the Skill tool
  at runtime; no technique is copied into the command body. Confirmed by reading the file: Phase 3
  is a bare `Invoke superpowers:brainstorming (Skill tool)...` with no embedded brainstorming
  logic. Any upstream improvement to `brainstorming` is free.
- `references/dependencies.md` lists `superpowers` (skill `brainstorming`) as a "Recommended
  companion" for `/prompt-brainstorm` with graceful fallback (soft dependency, not embedded
  logic) — the "Embedded technique" phrase in that row is loose wording for "the fallback
  path is self-contained," not a claim that brainstorming's technique is copied in.
- The `superpowers:*` skill listing available in this environment (`brainstorming`,
  `dispatching-parallel-agents`, `executing-plans`, `finishing-a-development-branch`,
  `receiving-code-review`, `requesting-code-review`, `subagent-driven-development`,
  `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `writing-plans`,
  `verification-before-completion`, `writing-skills`, `using-superpowers`) — none of these are
  invoked by name anywhere else in `dev-workflows` beyond the one call site above; every other
  place these methodologies show up in the plugin is an independent, adapted, or mattpocock-sourced
  implementation (covered in the table above), not a runtime call.
