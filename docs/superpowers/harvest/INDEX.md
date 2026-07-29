# dev-workflows harvest — consolidated shortlist (2026-07-29)

Cross-checked the adapted `dev-workflows` artifacts against four upstreams' recent churn
(SpecKit +956, Matt Pocock +295/316, superpowers +273, BMAD +242 commits). Analysis is on the
canonical `ihudak-claude-plugins/plugins/dev-workflows`; adopted changes then port to the copilot
mirror + mgd via the existing sync. Per-upstream detail: `mattpocock.md`, `superpowers.md`,
`bmad.md`, `speckit.md`. Nothing was edited — this is advisory.

## Freebie (do regardless — it's a real collision)
- **`references/grilling-technique.md`: "design tree" → "decision tree".** Upstream (Matt) renamed
  it months ago; our term now collides with our own `design.md` artifact. Trivial, removes real
  confusion.

## Tier 1 — highest leverage (real capability gaps; M effort each)
1. **Spec→code traceability + a `converge` drift check.** Nothing today verifies the *built code*
   actually satisfies `specification.md`/`design.md` IDs (`[Uxx]`/`[ACxx]`/`[TCxx]`). Adopt SpecKit's
   `converge` idea as a post-implementation coverage/drift check, enabled by ID-tagging
   `risk-planner` steps (SpecKit tasks-template). Sources: speckit #1 + #3.
2. **A `references/bug-diagnosis.md` for `/implement`'s bug-shaped SIGNIFICANT/HIGH-RISK tasks.**
   Feedback-loop-first: red-capable repro before hypothesizing, ranked *falsifiable* hypotheses,
   tagged instrumentation. Genuine gap — we have no bug-diagnosis discipline today. Source: Matt
   `diagnosing-bugs`.
3. **`agents/test-writer.md` test-quality discipline.** Add the falsifiability gate,
   no-change-detectors, mirror-assertion trap, and a mutation check. Source: superpowers
   `writing-good-tests`.

## Tier 2 — quick sharpeners (S effort, additive)
4. **Unified ambiguity/clarify taxonomy.** Our coverage check is scope-only; systematically also
   probe NFR / integration / terminology / implicit-enum-branch gaps + pre-mortem / assumption
   audit. Fold into `grilling-technique.md`, `/create-vi`, `/create-ard`, `/specify`, `spec-reviewer`.
   Sources: speckit #2 + bmad #2 + bmad #4 (deduped — same theme).
5. **`agents/review-fixer.md`: plan-conflict disposition** — when a finding contradicts the approved
   plan, ask the human which governs (don't auto-fix against the plan). Source: superpowers SDD.
   *(We hit exactly this need earlier this session.)*
6. **`agents/code-review.md`: Fowler 12-smell checklist** in the architectural-consistency dimension
   (skip Matt's two-parallel-subagent split — not worth the doubled cost). Source: Matt `code-review`.
7. **`references/design-format.md` + `agents/design-reviewer.md`: deep-module/seam quality vocab**
   (depth, seam, adapter, deletion-test) — we have a `## Seams` section but no standard for judging
   seam/interface quality. Source: Matt `codebase-design`.
8. **`agents/risk-planner.md`: a "No Placeholders" self-review pass** on the plan. Source:
   superpowers `writing-plans`.
9. **Small format tweaks:** counter-metrics (`SM-C1`) in `vi-format.md` + a `vi-reviewer` note;
   a terminology-precision forcing move in `grilling-technique.md`. Sources: bmad #3 + #1.

## Adjacent (M; judgment call)
- **Context "hand off as files, not pasted text"** — `references/context-management.md` covers *when*
  to offload but not the *how*; our own `implement.md` dispatch prompts do the anti-pattern upstream
  now names. Source: superpowers. Worth it if we invest in the multi-agent dispatch prose.

## Deliberately NOT adopting (reassurance — these were considered and rejected)
- BMAD/SpecKit **CLI + template scaffolding**, `constitution`, community-governance presets,
  extension hooks — standalone machinery that doesn't fit a Jira-driven, specs-repo pipeline.
- superpowers **SDD ledger / plan-scoped workspace / 5-round fix-breaker** — solves a per-task
  multi-subagent coordination problem `/implement`'s single-orchestrator design doesn't have; our
  capped one-pass-then-ask-human is arguably more conservative, not behind.
- BMAD `bmad-review`'s **generic lens engine** — would be a large refactor of our already-working
  per-artifact Opus reviewers.
- Matt's **git-push-blocking hook** — incompatible with our approve-then-push design.
- BMAD PRD-coach's **"never recommend an answer"** — a deliberate disagreement with our grill's
  "recommend an answer" mechanic, not an oversight.

## Confirmed good alignment (no action)
- Our `vi-reviewer` "substance over theater" + the VI Spine/Adapt-in-Menu structure are already
  near-convergent with BMAD's PRD-coach.
- `systematic-debugging`, `using-git-worktrees`, `finishing-a-development-branch` were never embedded
  (grep-clean) — nothing to refresh; `/prompt-brainstorm` is a clean runtime call to
  `superpowers:brainstorming` (auto-benefits from updates).
