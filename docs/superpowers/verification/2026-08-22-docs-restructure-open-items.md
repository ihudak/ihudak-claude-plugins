# dev-workflows docs restructure — open items

**Branch:** `iv-gu/docs-restructure` · **Version:** 2.57.0 · **State:** all four gates pass, 49 commits, not pushed.

Everything below is open as of the final whole-branch review and its fix wave. Sources: the SDD ledger (`.superpowers/sdd/2026-08-22-dev-workflows-docs-restructure/progress.md`, gitignored), the final whole-branch review, and its scoped re-review. **Items 7–9 existed only in review output and had no durable record before this file.**

## A. Cosmetic minors — six, all verified non-false

1. **`docs/workflow.md`'s Jira-status bullet** paraphrases the old README rather than deriving fresh. Content verified true; neither cited authority (`cost-emission.md`, `phase-handoff.md`) covers that fact, so there is no better primary source. Compounds item 9.
2. **`docs/reference/environment.md`'s `$SPECS_PATH` paragraph** attributes "the bookkeeping is not committed" to `specs-preflight`; the commit is `commit-artifacts`' job at the terminal step. Both share the §3.1 writable gate, so the stated consequence is true — only the attribution is loose.
3. **`docs/commands/release-notes.md`'s `## Example`** walks the dev-phase run in full and folds the PM-phase run into a closing sentence, so a skimmer gets a dev-first impression though `## Who runs it` presents both symmetrically.
4. **`docs/commands/ready.md:15`'s closing summary** says the two commands "diverge only once Epic subfolders multiply", omitting the single-Epic case that its own parenthetical states correctly one clause earlier.
5. **`docs/commands/ready.md:71`'s See-also phrasing** needs a second read to parse. Not incorrect.
6. **`plugins/dev-workflows/README.md`'s pitch enumerates phases** — idea, VI authoring, architecture, specification, design, implementation, documentation — omitting `/epics`, `/release-notes`, `/ready`. The complete 21-command table sits directly below. This is the predicted side effect of replacing a false universal with an enumeration: an enumeration asserts completeness by implication.

## B. Findings that had no durable record until now

7. **Follow-ups have two different "primary location" answers.** `docs/workflow.md:63` and `docs/reference/environment.md:89`'s layout block both file follow-ups under `<VI-dir>/dev-workflows/` in `$SPECS_PATH`. `docs/reference/follow-ups.md:15` makes the **vault** primary (the Jira key's project file, else `$VAULT_PATH/Tasks.md`), with the specs-repo path reachable only at tier 2 "no vault". Both mirror `references/specs-repo-git.md:48`, so neither is wrong alone — but a reader asking "where do my follow-ups land" gets two different first answers.
8. **Diagram label convention drifts on collapsed nodes.** `docs/commands/ready.md:31`'s node `p678` reads "Phase 6 — Maintenance / Phase 7 — Follow-ups / Phase 8 — Session cost" against source headings "Post-run maintenance & feedback" / "Emit follow-up tasks" / "Session cost". `docs/commands/epics.md:36`'s equivalent node is verbatim. Spec §6 permits collapse but says labels come from headings verbatim.
9. **`docs/workflow.md`'s pipeline diagram shows `epics -->|Epic drafts| specify` as the only path into `/specify`**, omitting the direct `createvi → specify` VI-level path that `docs/commands/specify.md:15` calls "genuinely valid, not a fallback of last resort". Carried verbatim from the old README. A diagram may simplify — but this is the same simplification that produced a false comparative elsewhere in the branch.

## C. Gate follow-ups

10. **The skills sub-check's direction 2 has no selftest case.** `check_inventory`'s skills loops fire in both directions — a documented-but-nonexistent skill was proven to trip `FAIL check 4` by mutating a scratch copy — but the selftest exercises only direction 1 (an undocumented skill directory). **This exact gate has twice shipped an unreachable direction**, so a dedicated case is worth adding before trusting it long-term. Takes the selftest from 11 cases to 12.
11. **The spec-ID census now constrains the corpus rather than describing it.** `plugins/dev-workflows/README.md`'s Dev-row cell carries a `[Uxx]`/`[ACxx]`/`[TCxx]`-bearing clause kept solely to hold `scripts/spec-id-baseline.txt`'s frozen counts stable after the old README's converge-check sentence was deleted. The clean path, documented in the baseline's own header: regenerate by three with a stated reason, then simplify that cell to plain English.
12. **D2's fix is not defended by any persisted gate.** The bidirectional check that would have caught `/update-vi`'s missing §7 row ran once as inline bash; it is in neither `scripts/check-docs.sh` nor CI (`grep -c cost-emission` returns 0 for both). Recorded honestly in the defect report and changelog. A future command with a fixed `phase`/`role` and no §7 row will be caught by nothing.

## D. Decisions for the repository owner

13. **D3 — `/ready`'s role name.** `references/cost-emission.md` §7 attributes `role: team`; the now-deleted README filed it under `QA`. `CLAUDE.md` contains zero occurrences of "QA". The 34 docs pages all use `team`. Open question: is `team` the intended name, or was `QA` a deliberate human-facing lane label?
14. **D6 — the four-role vocabulary in three references.** `references/next-phase-offer.md:12`, `references/session-hygiene.md:71`, and `references/workflow-states.md:6` use `PM / PA / PE / Team`, collapsing what §7 splits into `dev` (`/design`, `/implement`, `/document`) and `team` (`/ready` alone). `workflow-states.md:21-22` genuinely assigns `/implement` the role "Team". Per `references/instruction-file-maintenance.md`, two live contradictory instructions is a defect. **Shipped plugin content, outside this restructure's scope.** The 34 new pages are all consistent with the five-role set — verified by whole-branch grep.

## E. Not to be "fixed" — a rejected finding, recorded so it is not re-raised

15. The final review flagged `ROOT` and `OWNER_REPO` as dead exclusions in `check-docs.sh`'s `RUNTIME_VARS`. **They are live and correctly excluded:** `$ROOT` is read at `hooks/changelog-owners-reminder.sh:10`, `$OWNER_REPO` at `references/phase-handoff.md:70,166,168`. One is a hook-local shell variable, the other a reference template placeholder; neither is user-settable. **Do not remove them from the exclusion list.**
