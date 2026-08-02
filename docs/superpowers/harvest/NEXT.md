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

## Wave 3 — SHIPPED (2026-08-01; NIT follow-up 2026-08-02)
Five deferred nuggets + the cheap half of the Adjacent item shipped to all three editions. Current tips:
canonical `72bb7ae` (**2.39.1**), mgd `5478b74` (**2.39.1**), Copilot `9fca4db` (**2.9.1**) — the `.1`
patch was a whole-branch-review NIT follow-up (`context-management.md` 4th-strategy summary consistency);
wave-3 base was 341b5df/557526b/fa25405 (2.39.0 / 2.9.0). Spec + plan:
`docs/superpowers/specs|plans/2026-08-01-dev-workflows-deferred-nuggets*.md`. What shipped: ADR
3-condition candidacy filter (`ard-format.md`), wide-refactor expand→migrate→contract exception
(`epics.md`), prototype-snippet exception (`design-format.md`), missing-adoption gap (`code-review.md`
dim 4), `resume.md` redaction reminder (`session-hygiene.md`), and the context "hand off by file, not
paste" 4th strategy (`context-management.md`, **reference-only**). Also **fixed** a pre-existing `/idea`
+ `/create-vi` YAML-frontmatter bug (a colon-space in the unquoted `description:` silently dropped all
frontmatter at runtime). Passed the Opus whole-branch review (READY; 3 minors fixed). Do NOT redo.

## Wave M (the `/implement` dispatch file-handoff) — SHIPPED (2026-08-02)
The deferred M item shipped to all three editions. Current tips: canonical `5d8f56c` (**2.39.2**),
mgd `f2d0ac3` (**2.39.2**), Copilot `2de7eb2` (**2.9.2**). Spec + plan:
`docs/superpowers/specs|plans/2026-08-02-implement-dispatch-file-handoff*.md`. What shipped: extended
the existing `/document` + `/epics` `mktemp` handoff pattern to `/implement`'s four in-loop dispatches
(`risk-planner`, `test-writer`, `code-review`, `review-fixer`) plus the Phase 3.5 sibling — the
multi-source summary, approved plan, review diff, and code-review report are written to `mktemp` files
(outside every repo tree → no `git diff` pollution) and handed as absolute **paths**, not pasted
inline; each agent's `## Inputs` notes a field may arrive inline or as a path. Behavior-preserving
(Design A, surgical per-artifact). Passed the Opus whole-branch review (READY WITH MINORS; both fixed —
the re-review paths now refresh `review_diff_file`, and a review-fixer note period). Do NOT redo.

## Wave S (the `/vuln` + `/upgrade` dispatch file-handoff) — SHIPPED (2026-08-02)
The S follow-up shipped to all three editions. Current tips: canonical `04e51f4` (**2.39.3**),
mgd `e1a7ab5` (**2.39.3**), Copilot `d7ad4b3` (**2.9.3**). Spec+plan (one doc):
`docs/superpowers/specs/2026-08-02-vuln-upgrade-dispatch-file-handoff-design.md`. What shipped: the
`/vuln` research report (→ `vuln-fixer`, `code-review`, resumes) and the `/upgrade` planner handoff
(→ `risk-planner`, `upgrade-executor`, resumes), plus each command's `code-review` `git diff`, are
written to `mktemp` files (outside every repo tree → no `git diff` pollution) and handed as absolute
**paths**; `vuln-fixer` + `upgrade-executor` `## Process` note a field may arrive inline or as a path.
Behavior-preserving. Passed the Opus whole-branch review (READY WITH MINORS; all fixed — the
`/upgrade` regression-resume `plan_file` gap + 2 NITs). Do NOT redo.

## NEXT: no active item
The "hand off by file, not paste" pattern is now applied across every code-oriented command
(`/implement`, `/vuln`, `/upgrade`; `/document` + `/epics` already used it). No active follow-up
remains from this thread. The only backlog is the "Rejected on merits" list below — parked unless asked.

**Rejected on merits (revisit only if asked):** CLI/template scaffolding, `constitution`, governance
presets, SDD ledger / 5-round fix-breaker, generic lens engine, git-push-blocking hook, PRD-coach
"never recommend an answer", batch-grill-me denser rounds. (See INDEX.md "Deliberately NOT adopting".)

## Standing constraints (still apply for any new work)
- PUSHES HELD for explicit user confirmation. Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Do NOT edit `references/specification-format.md` (frozen snapshot).
- mgd push bypasses a PR-required branch rule (user: "ok for now").
