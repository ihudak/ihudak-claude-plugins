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

## Wave 3 — SHIPPED (2026-08-01, dev-workflows 2.39.0 / Copilot 2.9.0)
Five deferred nuggets + the cheap half of the Adjacent item shipped to all three editions (canonical
`341b5df`, mgd `557526b`, Copilot `fa25405`). Spec + plan:
`docs/superpowers/specs|plans/2026-08-01-dev-workflows-deferred-nuggets*.md`. What shipped: ADR
3-condition candidacy filter (`ard-format.md`), wide-refactor expand→migrate→contract exception
(`epics.md`), prototype-snippet exception (`design-format.md`), missing-adoption gap (`code-review.md`
dim 4), `resume.md` redaction reminder (`session-hygiene.md`), and the context "hand off by file, not
paste" 4th strategy (`context-management.md`, **reference-only**). Also **fixed** a pre-existing `/idea`
+ `/create-vi` YAML-frontmatter bug (a colon-space in the unquoted `description:` silently dropped all
frontmatter at runtime). Passed the Opus whole-branch review (READY; 3 minors fixed). Do NOT redo.

## NEXT: the one remaining deferred item (the M one)
- **Context "hand off by file, not paste" — the `/implement` refactor half.** The reference-only 4th
  strategy shipped in wave 3; what remains is rewording `/implement` **Phase 1.7 / 2B / 3B** dispatch
  prompts that currently *paste* the multi-source summary, `git diff` output, and the full code-review
  report into the subagent prompt — to write those to a file and hand a **path** instead. Touches a
  working command's hot path (three dispatch sites); deserves its own SDD pass. Source: superpowers.
  Effort **M**.

**Rejected on merits (revisit only if asked):** CLI/template scaffolding, `constitution`, governance
presets, SDD ledger / 5-round fix-breaker, generic lens engine, git-push-blocking hook, PRD-coach
"never recommend an answer", batch-grill-me denser rounds. (See INDEX.md "Deliberately NOT adopting".)

## Standing constraints (still apply for any new work)
- PUSHES HELD for explicit user confirmation. Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Do NOT edit `references/specification-format.md` (frozen snapshot).
- mgd push bypasses a PR-required branch rule (user: "ok for now").
