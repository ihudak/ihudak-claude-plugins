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

**Where this rule applies: every next-step offer this plugin prints.** The `<merge-clause>` placeholder is the convention the six `/dev-workflows:brd-*` commands write their offers to, and an offer added to that route carries it. It is equally the convention of the five older pipeline offers, converted after the route shipped: `/dev-workflows:create-prd`'s and `/dev-workflows:update-prd`'s *Next steps* phases, `/dev-workflows:create-ard`'s *Next-step offer (adaptive)* phase, and the `### Next step` sections of `/dev-workflows:specify` and `/dev-workflows:design`. Four of those five hardcoded "once the pull request above is merged" on runs that reach outcomes opening no pull request; the fifth, `/dev-workflows:update-prd`, named two downstream commands that gate this run's own PRD and stated no wait at all. No offer in this plugin now names a downstream gate its own run feeds and states the wait unconditionally, and an offer added anywhere carries the placeholder.

**A gate enforces adoption, and it enforces exactly one half of this rule.** `scripts/check-docs.sh` check 11 asserts that every `choices:` option in the `/dev-workflows:brd-*` family naming a command whose `require-on-main` target the offering run writes carries the `<merge-clause>` token. It derives that family from the first such phrase in the scope paragraph above, the gate targets from `phase-handoff.md` §3.4's table, and what a run writes from each command's own `deliverable_paths` list. **Three things it does not check, and each is a place a defect has lived or can live:**

1. **Presence, not resolution.** The gate sees the token `<merge-clause>` in the option text. It cannot see which row of the table above a run resolves it to. Picking the wrong row is a real, shipped defect — an offer once told the operator to name a branch on a **declined** handoff, where `handoff-to-main` committed nothing and §4.1's declined line carries no branch. A reader who assumes the gate covers resolution will reintroduce that. The table above, and the sentence that only two of its rows name a branch, are enforced by review alone.
2. **`choices:` arrays only.** An offer written as prose — a `### Next step` paragraph, a final-report sentence — is invisible to it. The universal minimum surface this contract defines is exactly the surface the gate does not cover.
3. **Declared paths only.** A run's writer set is what its command file lists after `deliverable_paths` =. A file a run writes but never declares there is not in that set, so an offer that should carry the clause because of it will not be asked to. This under-fires rather than over-fires, and a family command whose declaration yields nothing at all turns the build red rather than going quiet.

The gate is a floor under the convention, never a substitute for reading it: an offer can satisfy check 11 and still be false.

**The family scope is deliberate, and recorded here so widening is not re-proposed without new evidence.** Adoption is plugin-wide, as the scope paragraph above says; the gate is not. Removing the family filter and running check 11 over every command in this plugin fires on four sites and catches none of the five offers converted for the paragraph above. All four hits are correct content: `commands/document.md` runs neither `handoff-to-main` nor `require-on-main`, so it declares no `deliverable_paths` and the per-command writer assertion rejects it outright; `commands/implement.md`'s Phase 0 design-doc open-question guard and `commands/specify.md`'s Phase 2 zero-Epic redirect are refusals rather than offers, both taken long before the offering run reaches its own handoff phase, so there is no §4.1 outcome line for a clause to resolve from; and the `commands/idea.md` hit is the option scanner reading a report sentence that follows the array on the same line — a sentence on the path that says outright that nothing was handed off. The five real defects stay invisible to the widened check as well, and for two different reasons — only one of which is the extractor. `/dev-workflows:specify`'s and `/dev-workflows:design`'s offers **do** carry the intersection the check looks for: `specification.md` and `design.md` are both backticked in §3.4's rows, and each run declares the file it writes. They are missed solely because they are prose. The three that *are* `choices:` arrays are missed on both relations at once: §3.4 names their gated inputs in prose — "the PRD", "the ARD" — so `targets` is empty for `/dev-workflows:create-ard` and `/dev-workflows:specify` as *offered* commands, and the same prose in each offering command's own `deliverable_paths` = declaration ("the ARD file(s)", "the PRD file") leaves `writers` blind to what it wrote. A `choices:` array in this plugin is a refusal or a mid-run branch point as often as it is an offer, and nothing in the file marks which; a gate that cannot tell them apart blocks correct work, and a gate that blocks correct work gets disabled. Same verdict, and the same reason, as the stop-routing check `scripts/check-docs.sh` records as never shipped.

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
- `/dev-workflows:brd-reconcile <BRD-KEY> @<review-file>` → the route's hand-over into the PRD
  pipeline, and its own re-entry. **Re-entry:** another `/dev-workflows:brd-interview <BRD-KEY>`
  round where this run reopened a decision, `/dev-workflows:brd-package <BRD-KEY>` where questions
  remain for the customer, or `/dev-workflows:brd-ground <BRD-KEY> --rebaseline` where the review
  challenged a code claim. **Advance:** `--from-brd` on `/dev-workflows:create-prd`,
  `/dev-workflows:create-ard` and `/dev-workflows:specify` all ship, and that command's next-step
  phase offers all three off the one BRD key — `/dev-workflows:create-prd <BRD-KEY> --from-brd` only
  where the reconciled ledger leaves no row `unallocated` and at least one `covered-here`
  (`references/coverage-ledger-format.md` §5, the two refusals its Phase 0 raises), the other two
  unconditionally, since neither dispatches `jira-reader`, neither runs the PRD gate and neither
  reads the ledger. None of the three carries `<merge-clause>`: none of them runs `require-on-main`
  against anything `/dev-workflows:brd-reconcile` writes.

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
