# Next-phase offer (embedded — shared reference)

The plugin-wide contract for the **next-phase offer**: the guidance every pipeline command
surfaces at the end of its run, naming the natural next command(s). Cited by all pipeline
commands so the routing graph and the offer rules live in ONE place (the same shape as
`emit-block` in `feedback-emission.md`).

## The offer contract (6 rules)

1. **Guidance-only** — the offer NAMES the next command(s); it NEVER auto-invokes anything.
2. **Role-labeled** — it names the concrete command(s) for the next step, tagged with the owning
   role (PM / PA / PE / Dev), even on a handoff — one person may wear several hats and just keep
   going. Never a bare "hand off to PA".
3. **Adaptive to outcome** — a clean run points forward; a BLOCK / incomplete / cancelled run
   recommends resolving THAT first, not advancing.
4. **Mode-aware** — the forward recommendation is a PIPELINE handoff. In a command's direct /
   ad-hoc mode (no PRD/Epic context — `/dev-workflows:implement` direct, `/dev-workflows:document` doc-edit) it is OMITTED,
   not invented.
5. **Epic fan-out** — a command operating at **Epic scope** offers TWO branches:
   - **Depth** — the next command for the SAME Epic (`/dev-workflows:design <PRD> E1` → `/dev-workflows:implement <PRD> E1`).
   - **Breadth** — the SAME command for the NEXT Epic under the PRD (`/dev-workflows:design <PRD> E1` →
     `/dev-workflows:design <PRD> E2`).

   So a team can go `/dev-workflows:design E1 → /dev-workflows:design E2 → /dev-workflows:implement E1 → /dev-workflows:implement E2` OR
   `/dev-workflows:design E1 → /dev-workflows:implement E1 → /dev-workflows:design E2 …` — their call. Applies to the per-Epic commands
   only: `/dev-workflows:create-ard <PRD> <Epic>`, `/dev-workflows:specify <PRD> <Epic>`, `/dev-workflows:design <PRD> <Epic>`,
   `/dev-workflows:implement <PRD> <Epic>`. `/dev-workflows:document` and `/dev-workflows:release-notes` are PRD-level (whole-feature, run
   once after ALL Epics are implemented) and do NOT fan out.
6. **Fully qualified when printed** — every command name the run PRINTS for the user to invoke is
   written `/dev-workflows:<command>`. A bare `/<command>` can resolve to a Claude Code built-in of
   the same name — Claude Code's own `/release-notes`, `/upgrade`, and `/statusline` all collide
   today, and the built-in wins — so the bare form is NEVER printed. Prose that describes the
   pipeline to a reader of this plugin's source keeps the short form.

**A next-step offer that names a downstream command must also name the merge.** The downstream command executes `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) and stops while this phase's pull request is open, so an offer that reads "next: `/dev-workflows:create-ard <KEY>`" without "once the pull request is merged" sends the user into a stop they were not warned about.

**And it must name it truthfully, which means the clause is never unconditional.** A run that staged nothing, or whose handoff the user declined, opened no pull request — and "once the pull request above is merged" then parks the operator waiting for a merge that will never happen, on a run they could often start immediately. Worse, the two failing outcomes differ: only one of them has a branch to name. So an offer carries the clause as the placeholder **`<merge-clause>`**, resolved from the `Phase handoff:` line `phase-handoff.md` §4.1 actually emitted:

| §4.1 outcome | `<merge-clause>` resolves to |
|---|---|
| Committed, pushed, PR opened | `(once the pull request above is merged)` |
| PR not opened | `(once you open the pull request for <branch> and it is merged)` |
| Push failed | `(once <branch> is pushed, its pull request opened, and merged)` |
| Nothing to commit | `(its inputs are already on the default branch — you can run it now)` |
| Declined by the user | `(once this run's artifacts reach the default branch — they are written but not there)` |
| Gate failed | `(once this run's artifacts reach the default branch — the handoff did not run)` |
| Anything else, or unresolvable | `(once this phase's artifacts are on the default branch)` |

`Branch name substituted` is an append to another line rather than an outcome of its own — whatever branch the emitted line ends up naming is the branch the clause names. **Only two rows name a branch, and that is the point**: §4.1's declined and gate-failed lines carry none, because on those paths `handoff-to-main` committed nothing, so there is no branch in existence to send anyone to.

**Resolving this placeholder is not a rewording.** The array is still presented verbatim per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`'s *Choice lists are presented verbatim*, exactly as `<BRD-KEY>` or `<KEY>` is substituted in the same strings. A command that instead told the orchestrator to *adjust the wording* of an option would be contradicting that convention, which is why the variation lives in a placeholder and not in an instruction.

## Surface

The universal minimum is an adaptive **`### Next step`** section at the END of the command's
Final Report (guidance-only prose). A command MAY additionally present a richer interactive
`choices:` offer (the reference commands `/dev-workflows:idea`, `/dev-workflows:create-prd`, `/dev-workflows:create-ard` do) — compatible,
not required.

## The routing graph (role-aware)

**PM — ideation & framing**

- `/dev-workflows:idea` — refined → `/dev-workflows:create-prd <JIRA-KEY>` (PM); draft → `/dev-workflows:idea @<path> --deep` (PM, refine)
  or `/dev-workflows:create-prd <JIRA-KEY>` (PM, proceed on a draft — not recommended).
- `/dev-workflows:create-prd <JIRA-KEY>` — after the paste-into-Jira + re-import round-trip:
  `/dev-workflows:release-notes <PRD>` (PM — draft the release note; recommended clear next step); hand to PA
  *(optional)* → `/dev-workflows:create-ard <PRD>`; or hand to PE → `/dev-workflows:epics <PRD>` (or `/dev-workflows:specify <PRD>`).
- `/dev-workflows:update-prd <KEY>` — re-entry, not a linear node: reached when
  `/dev-workflows:create-prd` redirects an existing-PRD call, or when a later phase forces a PRD
  refresh. After the paste-into-Jira + re-import round-trip it offers:
  `/dev-workflows:release-notes <PRD>` (PM), `/dev-workflows:create-ard <PRD>` (PA, if one exists),
  `/dev-workflows:epics <PRD>` (PE), `/dev-workflows:specify <PRD>` (PE, if one exists).

**PM / PA — the BRD-to-PRD route**

- `/dev-workflows:brd-intake <BRD-KEY> @<brd-file>` — the route's entry point → hand to PA →
  `/dev-workflows:brd-ground <BRD-KEY>` (PA).
- `/dev-workflows:brd-ground <BRD-KEY>` → `/dev-workflows:brd-split <BRD-KEY>` (PM). On a slice
  (`brd-link.md` carries a `parent:`), the same command runs allocate-only and creates no child.
- `/dev-workflows:brd-split <BRD-KEY>` — **depth** → `/dev-workflows:brd-interview <BRD-KEY>` (PM);
  **breadth** → `/dev-workflows:brd-ground <CHILD-KEY>` (PA) once per child the run created, each
  child re-entering the route at grounding.
- `/dev-workflows:brd-interview <BRD-KEY>` → `/dev-workflows:brd-package <BRD-KEY>` (PM), offered
  only where this run's own state is one `/dev-workflows:brd-package` would accept
  (`commands/brd-package.md` Phase 0 owns that test); otherwise → another
  `/dev-workflows:brd-interview <BRD-KEY>` round (PM), or `/dev-workflows:brd-ground <BRD-KEY>` (PA)
  for a question no finding bears on yet.
- `/dev-workflows:brd-package <BRD-KEY>` → *(the customer reviews it off-platform, and the round
  holding each customer question stays open until the answer comes back)* →
  `/dev-workflows:brd-reconcile <BRD-KEY> @<review-file>` (PM).
- `/dev-workflows:brd-reconcile <BRD-KEY> @<review-file>` → leaf/closure: the route ends at a
  reconciled BRD. Re-entry, never advance: another `/dev-workflows:brd-interview <BRD-KEY>` round
  where this run reopened a decision, `/dev-workflows:brd-package <BRD-KEY>` where questions remain
  for the customer, or `/dev-workflows:brd-ground <BRD-KEY> --rebaseline` where the review
  challenged a code claim. `--from-brd` on `/dev-workflows:create-prd`, `/dev-workflows:create-ard`
  and `/dev-workflows:specify` does **not** ship, so no offer here crosses into the PRD pipeline.

**PA — architecture (optional)**

- `/dev-workflows:create-ard <PRD>` (PRD-level) → PE → `/dev-workflows:epics <PRD>` (recommended) or `/dev-workflows:specify <PRD>`.
  *(No `/dev-workflows:design` — no Epics yet.)*
- `/dev-workflows:create-ard <PRD> <Epic>` (Epic-level) → `/dev-workflows:specify <PRD> <Epic>` (recommended) or Dev →
  `/dev-workflows:design <PRD> <Epic>`.

**PE — breakdown & specification**

- `/dev-workflows:specify <PRD>` (PRD-level spec) → `/dev-workflows:epics <PRD>`.
- `/dev-workflows:epics <PRD>` → `/dev-workflows:specify <PRD> <Epic>` (per Epic); optional PA → `/dev-workflows:create-ard <PRD> <Epic>`.
- `/dev-workflows:specify <PRD> <Epic>` (Epic-level spec) → Dev → `/dev-workflows:design <PRD> <Epic>`.

**Dev — build, verify & deliver**

- `/dev-workflows:design <PRD> <Epic>` → optionally `/dev-workflows:ready <PRD> <Epic>` (verify readiness) →
  `/dev-workflows:implement <PRD> <Epic>`.
- `/dev-workflows:ready <PRD> [<Epic>]` → **SUPPORTED** → `/dev-workflows:implement <PRD> [<Epic>]`; **PARTIAL / NOT-SUPPORTED**
  → resolve the named gaps + update the Jira status, then re-run `/dev-workflows:ready`. *(Read-only verifier;
  not itself a linear pipeline node — an optional gate before build.)*
- `/dev-workflows:implement <PRD> <Epic>` → finish remaining Epics (breadth); once ALL Epics implemented →
  `/dev-workflows:document <PRD>` → `/dev-workflows:release-notes <PRD>`. *(Direct mode → no forward offer.)*
- `/dev-workflows:document <PRD>` (PRD-level, after all Epics) → `/dev-workflows:release-notes <PRD>`. *(Doc-edit mode → no
  forward offer.)*
- `/dev-workflows:release-notes <PRD>` (PRD-level) → leaf/closure: release note drafted; continue any pending
  PA/PE phase, else the PRD is fully processed.

## Not pipeline nodes

`/dev-workflows:vuln`, `/dev-workflows:upgrade`, `/dev-workflows:feedback`, `/dev-workflows:prompt*`, `/dev-workflows:docs-profile`, `/dev-workflows:statusline`, and the reviewer
commands are NOT part of the linear PRD→docs pipeline and carry no next-phase offer.

## Session hygiene co-fires here

The `### Next step` this contract produces is immediately followed by a
`### Context hygiene` block (`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`): the compact-vs-clear
choice reads the SAME role labels computed here (same role → `/compact`; role handoff →
`/clear`). This reference owns the role graph; `session-hygiene.md` only reads it.
