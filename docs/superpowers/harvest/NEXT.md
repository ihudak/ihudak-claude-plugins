# RESUME POINTER — dev-workflows upstream harvest

Read this first after compaction. Beside it: `INDEX.md` (ranked shortlist) + the design spec + plan
(now RELOCATED INTO THE REPO — see paths below).

## Done & shipped (do NOT redo)
- **acli feature COMPLETE and pushed** to all three repos' `origin/main` (earlier effort). Plan lives in
  the workspace scratch `/workspace/dev/docs/superpowers/plans/2026-07-29-acli-skill-distribution-and-mgd-removal.md`.
  Nothing pending on acli.

## Done in THIS harvest effort (do NOT redo)
- **Design decided + spec written + plan written.** Design forks resolved with the user:
  (1) converge → GATE in code-review (conditional 10th dim) + risk-planner ID-tags; (2) bug-diagnosis →
  FOLDED into risk-planner (repro-first + ranked hypotheses via the existing plan-approval gate); (3)
  ambiguity taxonomy → ALTITUDE-AWARE across all grills. Adjacent "hand-off-by-file" item → DEFERRED
  (user wants details later; other deferred nuggets enumerated in chat — revisit after this package).
- **Docs relocated into the canonical repo** `ai-tools/ihudak-claude-plugins/docs/superpowers/`:
  - Spec: `specs/2026-07-29-dev-workflows-upstream-harvest-design.md`
  - Plan: `plans/2026-07-29-dev-workflows-upstream-harvest.md`  ← THE authority for execution
  - Harvest analysis: `harvest/{INDEX,mattpocock,superpowers,bmad,speckit}.md` (+ this NEXT.md)

## Current task: EXECUTE the plan via superpowers:subagent-driven-development
- Plan = `.../docs/superpowers/plans/2026-07-29-dev-workflows-upstream-harvest.md` (12 tasks).
- **Wave 1 (T1–T4)** converge contract + bug-diagnosis + /implement wiring + test-writer gate →
  **Wave 2 (T5–T9)** taxonomy/plan-conflict/Fowler/seam-vocab/no-placeholders+counter-metrics →
  **Wave 3 (T10–T12)** port to mgd (straight copy) + Copilot (hybrid: agents straight, refs→skills/_shared/,
  implement→skills/implement/SKILL.md CONVERSION) + doc-surface sync (marketplace version bumps, READMEs,
  CLAUDE.md / copilot-instructions.md, CHANGELOGs).
- Canonical edits happen first on a feature branch off `main` in `ihudak-claude-plugins`.

## Standing constraints
- PUSHES ARE HELD for explicit user confirmation before each push (all 3 repos). Plan produces commits only.
- Commit trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Do NOT edit `references/specification-format.md` (frozen snapshot) — Item 4 coverage lands in spec-reviewer.
- Additive adaptations judged for fit to the Jira-driven, Opus-gated pipeline — not upstream purity.

## Immediate next action after compaction
Resume SDD at the first task in the plan's progress ledger not marked complete (check
`ihudak-claude-plugins/.superpowers/sdd/progress.md` + `git log`); if none started, begin Wave 1 Task 1.
