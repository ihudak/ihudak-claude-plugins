# Harvest status pointer — dev-workflows upstream harvest

## COMPLETE & SHIPPED (2026-07-29)
The 8-item harvest (freebie + Tier 1 + Tier 2) is implemented, reviewed, and **merged to `main` + pushed**
in all three editions:
- `ihudak-claude-plugins` (canonical) — `main` at `b9cfd38`; dev-workflows **2.38.0**. Passed the opus
  whole-branch review (Ready-to-merge: YES; 4 Minors fixed in `dab042c`).
- `mgd-claude-plugins` — `main` at `dd39786`; dev-workflows **2.38.0** (byte-identical copy of canonical).
- `ihudak-copilot-plugins` — `main` at `e4e3703`; dev-workflows **2.8.0** (hand-adapted conversion:
  `~/.copilot/…/skills/_shared/` paths, `implement:`/`design:` keywords).

What shipped: spec→code **converge** gate (code-review 10th dim + risk-planner ID-tags + /implement
wiring), `bug-diagnosis.md` discipline, test-writer falsifiability/mutation gate, review-fixer
plan-conflict, code-review Fowler floor, altitude-aware ambiguity taxonomy + "design tree"→"decision
tree" rename, deep-module/seam vocab, risk-planner no-placeholders, VI counter-metrics. Spec + plan:
`docs/superpowers/specs|plans/2026-07-29-dev-workflows-upstream-harvest*.md`. Do NOT redo any of this.

## NEXT: the DEFERRED / POSTPONED backlog (to review together)
Considered during the harvest but NOT shipped — each is a judgment call worth revisiting. Detail lives
in `INDEX.md` (Adjacent + "NOT adopting") and the per-upstream files (`mattpocock.md`, `bmad.md`,
`superpowers.md`, `speckit.md`).

**Could adopt later (judgment calls):**
1. **Adjacent — context "hand off by file, not paste"** → new 4th strategy in
   `references/context-management.md` + reword `/implement` Phase 1.7/2B/3B dispatch prompts that paste
   summaries/diffs/review output. Source: superpowers. Effort **M** (the one real `/implement` refactor).
2. **ADR-candidacy 3-condition filter** → `references/ard-format.md`: offer an `AD-N` only when a decision
   is hard-to-reverse AND surprising-without-context AND a real trade-off. Source: Matt `domain-modeling`. **S**.
3. **Prototype-snippet exception** → `references/design-format.md`: allow a narrow decision-encoding
   snippet (state machine / schema / type shape) where prose is less precise. Source: Matt `to-spec`. **S**.
4. **Wide-refactor expand→migrate→contract exception** → `commands/epics.md` Phase 2: a named
   Epic-sequencing carve-out for blast-radius-wide mechanical changes. Source: Matt `to-tickets`. **S/M**.
5. **`resume.md` redaction line** → `references/session-hygiene.md`: one-line "redact secrets/PII"
   reminder. Source: Matt `handoff`. **S**.
6. **"Missing-adoption gap"** → `agents/code-review.md` edge-case dimension: a sibling call site that
   should adopt changed behavior and doesn't, uncaught by tests. Source: BMAD `lens-verification-gap`. **S**.

**Rejected on merits (revisit only if asked):** CLI/template scaffolding, `constitution`, governance
presets, SDD ledger / 5-round fix-breaker, generic lens engine, git-push-blocking hook, PRD-coach
"never recommend an answer", batch-grill-me denser rounds. (See INDEX.md "Deliberately NOT adopting".)

## Standing constraints (still apply for any new work)
- PUSHES HELD for explicit user confirmation. Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Do NOT edit `references/specification-format.md` (frozen snapshot).
- mgd push bypasses a PR-required branch rule (user: "ok for now").
