# Next-phase offer (embedded — shared reference)

The family-wide contract for the **next-phase offer**: the guidance every pipeline command
surfaces at the end of its run, naming the natural next command(s). Cited by all pipeline
commands so the routing graph and the offer rules live in ONE place (the same shape as
`emit-block` in `feedback-emission.md`).

## The offer contract (7 rules)

1. **Guidance-only** — the offer NAMES the next command(s); it NEVER auto-invokes anything.
2. **Role-labeled** — it names the concrete command(s) for the next step, tagged with the owning
   role (PM / PA / PE / Dev), even on a handoff — one person may wear several hats and just keep
   going. Never a bare "hand off to PA".
3. **Adaptive to outcome** — a clean run points forward; a BLOCK / incomplete / cancelled run
   recommends resolving THAT first, not advancing.
4. **Mode-aware** — the forward recommendation is a PIPELINE handoff. In a command's direct /
   ad-hoc mode (no PRD/Epic context — `/dev-workflows:implement` direct, `/docs-workflows:document` doc-edit) it is OMITTED,
   not invented.
5. **Epic fan-out** — a command operating at **Epic scope** offers TWO branches:
   - **Depth** — the next command for the SAME Epic (`/dev-workflows:design <EPIC>` → `/dev-workflows:implement <EPIC>`).
   - **Breadth** — the SAME command for the NEXT Epic under the PRD (`/dev-workflows:design <EPIC-1>` →
     `/dev-workflows:design <EPIC-2>`).

   So a team can go `/dev-workflows:design E1 → /dev-workflows:design E2 → /dev-workflows:implement E1 → /dev-workflows:implement E2` OR
   `/dev-workflows:design E1 → /dev-workflows:implement E1 → /dev-workflows:design E2 …` — their call. Applies to the per-Epic commands
   only: `/pm-workflows:create-ard <EPIC>`, `/pm-workflows:specify <EPIC>`, `/dev-workflows:design <EPIC>`,
   `/dev-workflows:implement <EPIC>`. `/docs-workflows:document` and `/docs-workflows:release-notes` are PRD-level (whole-feature, run
   once after ALL Epics are implemented) and do NOT fan out.
6. **Fully qualified when printed** — every command name the run PRINTS for the user to invoke is
   written `/<plugin>:<command>`, fully qualified with the plugin that ships it. A bare `/<command>` can resolve to a Claude Code built-in of
   the same name — Claude Code's own `/release-notes`, `/upgrade`, and `/statusline` all collide
   today, and the built-in wins — so the bare form is NEVER printed. Prose that describes the
   pipeline to a reader of the family's own source keeps the short form.
7. **One address, never a pair** — every offer prints exactly ONE positional address, because every
   keyed command takes exactly one (D4: a key encodes its own ancestry, so an Epic address is all an
   Epic-scoped run needs and the PRD is derived from the folder above it). An offer written
   `/pm-workflows:specify <PRD> <Epic>` names an argument form no command accepts: the run reads the
   first token, and the second either disagrees with it or is refused. Write `/pm-workflows:specify
   <EPIC>` for an Epic-scoped step and `/pm-workflows:specify <PRD>` for a PRD-scoped one — the kind
   of the folder the address resolves to is what sets the altitude, so the offer never has to say it
   twice.

**A next-step offer that names a downstream command must also name the merge.** The downstream command executes `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) and stops while this phase's pull request is open, so an offer that reads "next: `/pm-workflows:create-ard <KEY>`" without "once the pull request is merged" sends the user into a stop they were not warned about.

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

**Where this rule applies: every next-step offer the dependent plugin family prints — today the commands named below, which span `pm-workflows`, `dev-workflows` and `workflows-core`.** The `<merge-clause>` placeholder is the convention the six `/dev-workflows:brd-*` commands write their offers to, and an offer added to that route carries it. It is equally the convention of the **six** older pipeline offers, converted after the route shipped: `/pm-workflows:create-prd`'s and `/pm-workflows:update-prd`'s *Next steps* phases, `/pm-workflows:create-ard`'s *Next-step offer (adaptive)* phase, the `### Next step` sections of `/pm-workflows:specify` and `/dev-workflows:design`, and `/pm-workflows:idea`'s Phase 5 handoff offer. Four of the first five hardcoded "once the pull request above is merged" on runs that reach outcomes opening no pull request; the fifth, `/pm-workflows:update-prd`, named two downstream commands that gate this run's own PRD and stated no wait at all. **The sixth was left off this list for a round and was defective the whole time**: `/idea` Phase 5 recommended `/pm-workflows:create-prd <KEY>` with no clause of any kind, while `/create-prd` Phase 0 step 3 rung 1 runs `require-on-main` on the very `idea.md` whose pull request that offer had just opened — this rule's own named failure, in the one adopter the rule's own adopter list omitted. It carries the placeholder now; and its `status: draft` branch, which hands nothing off so no row of the table above could resolve, names the `@<path>` read form instead of a wait. No offer in that family now names a downstream gate its own run feeds and states the wait unconditionally, and an offer added anywhere in it carries the placeholder. This reference ships in `workflows-core`, which prints one offer of its own, `/workflows-core:frames`, and that one carries no clause on purpose: nothing runs `require-on-main` on a frame-set index, so no downstream gate reads what it writes.

**A gate enforces adoption, and it enforces exactly one half of this rule.** `scripts/check-docs.sh` check 11 asserts that every `choices:` option in the `/dev-workflows:brd-*` family naming a command whose `require-on-main` target the offering run writes carries the `<merge-clause>` token. It derives that family from the first such phrase in the scope paragraph above, the gate targets from `phase-handoff.md` §3.4's table, and what a run writes from each command's own `deliverable_paths` list. **Three things it does not check, and each is a place a defect has lived or can live:**

1. **Presence, not resolution.** The gate sees the token `<merge-clause>` in the option text. It cannot see which row of the table above a run resolves it to. Picking the wrong row is a real, shipped defect — an offer once told the operator to name a branch on a **declined** handoff, where `handoff-to-main` committed nothing and §4.1's declined line carries no branch. A reader who assumes the gate covers resolution will reintroduce that. The table above, and the sentence that only two of its rows name a branch, are enforced by review alone.
2. **`choices:` arrays only.** An offer written as prose — a `### Next step` paragraph, a final-report sentence — is invisible to it. The universal minimum surface this contract defines is exactly the surface the gate does not cover.
3. **Declared paths only.** A run's writer set is what its command file lists after `deliverable_paths` =. A file a run writes but never declares there is not in that set, so an offer that should carry the clause because of it will not be asked to. This under-fires rather than over-fires, and a family command whose declaration yields nothing at all turns the build red rather than going quiet.

The gate is a floor under the convention, never a substitute for reading it: an offer can satisfy check 11 and still be false.

**The family scope is deliberate, and recorded here so widening is not re-proposed without new evidence.** Adoption is family-wide, as the scope paragraph above says; the gate is not. **Re-measured on the current tree, and the number moved.** Removing the family filter and running check 11 over every command in `dev-workflows` fires on **three** sites and catches **none** of the six offers converted for the paragraph above. All three hits are correct content: `/docs-workflows:document` runs neither `handoff-to-main` nor `require-on-main`, so it declares no `deliverable_paths` and the per-command writer assertion rejects it outright; and `/dev-workflows:implement`'s Phase 0 design-doc open-question guard and `/dev-workflows:specify`'s Phase 2 zero-Epic redirect are refusals rather than offers, both taken long before the offering run reaches its own handoff phase, so there is no §4.1 outcome line for a clause to resolve from. **The fourth hit this paragraph used to name is gone, and its going is evidence rather than tidying**: it was the option scanner reading a report sentence trailing a `choices:` array on one line of `/dev-workflows:idea`, in the relocation branch D7 retired — so the widened check's whole yield fell by a quarter while finding no defect and preventing none. The six real defects stay invisible to the widened check as well, and for two different reasons — only one of which is the extractor. `/dev-workflows:specify`'s and `/dev-workflows:design`'s offers **do** carry the intersection the check looks for: `specification.md` and `design.md` are both backticked in §3.4's rows, and each run declares the file it writes. They are missed solely because they are prose. The three that *are* `choices:` arrays are missed on both relations at once: §3.4 names their gated inputs in prose — "the PRD", "the ARD" — so `targets` is empty for `/dev-workflows:create-ard` and `/dev-workflows:specify` as *offered* commands, and the same prose in each offering command's own `deliverable_paths` = declaration ("the ARD file(s)", "the PRD file") leaves `writers` blind to what it wrote. **`/idea`'s is the sixth and the plainest**: its offer is a prose sentence, so the widened check cannot see it at all — widening would have bought nothing on the one live instance of exactly the failure it targets, found instead by reading. A `choices:` array in `dev-workflows` is a refusal or a mid-run branch point as often as it is an offer, and nothing in the file marks which; a gate that cannot tell them apart blocks correct work, and a gate that blocks correct work gets disabled. Same verdict, and the same reason, as the stop-routing check `scripts/check-docs.sh` records as never shipped. **The measurement is recorded here so widening is not re-proposed without new numbers: three correct sites fired on, zero of six defects caught.**

**Resolving this placeholder is not a rewording.** The array is still presented verbatim per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`'s *Choice lists are presented verbatim*, exactly as `<BRD-KEY>` or `<KEY>` is substituted in the same strings. A command that instead told the orchestrator to *adjust the wording* of an option would be contradicting that convention, which is why the variation lives in a placeholder and not in an instruction.

## Surface

The universal minimum is an adaptive **`### Next step`** section at the END of the command's
Final Report (guidance-only prose). A command MAY additionally present a richer interactive
`choices:` offer (the reference commands `/pm-workflows:idea`, `/pm-workflows:create-prd`, `/pm-workflows:create-ard` do) — compatible,
not required.

**When there are more forward options than the array can hold.** `AskUserQuestion` renders at most
four options (`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` §0), and several offers have
more forward steps than that. The prose is what carries the complete set — it is the universal
minimum precisely because it has no arity limit — so an overflowing offer resolves like this, and
never by silently deleting a route:

1. **List every option in the prose**, above the prompt, each with the command that runs it. A route
   named in prose is a route the operator can still take.
2. **The array carries `Stop here` plus the three the run's own outcome makes most likely**, in the
   same order the prose lists them. Rule 3 (adaptive to outcome) is what decides "most likely"; where
   a command already drops options on their own triggers, that filtering runs first and the cap
   applies to what survives it.
3. **Say, in one line, that the prose list is longer than the prompt** and that anything on it is
   reachable through the harness's free-text option. A demoted route the operator cannot find is the
   same defect as a deleted one.

An offer whose options fit in four does none of this: the prose stays the universal minimum and the
array carries every option.

## The routing graph (role-aware)

**PM — ideation & framing**

- `/pm-workflows:idea` — refined → `/pm-workflows:create-prd <KEY>` (PM); draft → `/pm-workflows:idea @<path> --deep` (PM, refine)
  or `/pm-workflows:create-prd <KEY>` (PM, proceed on a draft — not recommended).
- `/pm-workflows:create-prd <ADDRESS>`:
  `/docs-workflows:release-notes <PRD>` (PM — draft the release note; recommended clear next step); hand to PA
  *(optional)* → `/pm-workflows:create-ard <PRD>`; or hand to PE → `/pm-workflows:epics <PRD>` (or `/pm-workflows:specify <PRD>`).
- `/pm-workflows:update-prd <KEY>` — re-entry, not a linear node: reached when
  `/pm-workflows:create-prd` redirects an existing-PRD call, or when a later phase forces a PRD
  refresh. It offers:
  `/docs-workflows:release-notes <PRD>` (PM), `/pm-workflows:create-ard <PRD>` (PA, if one exists),
  `/pm-workflows:epics <PRD>` (PE), `/pm-workflows:specify <PRD>` (PE, if one exists).

**PM / PA — the BRD-to-PRD route**

- `/pm-workflows:brd-intake <BRD-KEY> @<brd-file>` — the route's entry point → hand to PA →
  `/pm-workflows:brd-ground <BRD-KEY>` (PA).
- `/pm-workflows:brd-ground <BRD-KEY>` → `/pm-workflows:brd-split <BRD-KEY>` (PM). On a slice
  (`brd-link.md` carries a `parent:`), the same command runs allocate-only and creates no child.
- `/pm-workflows:brd-split <BRD-KEY>` — **depth** → `/pm-workflows:brd-interview <BRD-KEY>` (PM);
  **breadth** → `/pm-workflows:brd-ground <CHILD-KEY>` (PA) once per **non-empty** child the run
  created, each such child re-entering the route at grounding. A child whose `claims:` list is
  empty — including one the parent's walk emptied by withdrawing every provisional claim, leaving
  it holding only orphan rows — is a standing empty child (`/pm-workflows:brd-split` Phase 7), and
  grounding it stops at `BRD_GROUND_EMPTY_INVENTORY`, so it is not offered.
- `/pm-workflows:brd-interview <BRD-KEY>` → `/pm-workflows:brd-package <BRD-KEY>` (PM), offered
  only where this run's own state is one `/pm-workflows:brd-package` would accept
  (`/pm-workflows:brd-package` Phase 0 owns that test); otherwise → another
  `/pm-workflows:brd-interview <BRD-KEY>` round (PM), or `/pm-workflows:brd-ground <BRD-KEY>` (PA)
  for a question no finding bears on yet.
- `/pm-workflows:brd-package <BRD-KEY>` → *(the customer reviews it off-platform, and the round
  holding each customer question stays open until the answer comes back)* →
  `/pm-workflows:brd-reconcile <BRD-KEY> @<review-file>` (PM).
- `/pm-workflows:brd-reconcile <BRD-KEY> @<review-file>` → the route's hand-over into the PRD
  pipeline, and its own re-entry. **Re-entry:** another `/pm-workflows:brd-interview <BRD-KEY>`
  round where this run reopened a decision, `/pm-workflows:brd-package <BRD-KEY>` where questions
  remain for the customer, or `/pm-workflows:brd-ground <BRD-KEY> --rebaseline` where the review
  challenged a code claim. **Advance, and the first condition is the level.** the BRD route on
  `/pm-workflows:create-prd`, `/pm-workflows:create-ard` and `/pm-workflows:specify` all ship, and
  that command's next-step phase offers all three off **a slice key** — never off a root BRD key. A
  BRD is a container and each of the three refuses a `BRD-` folder in its own Phase 0
  (`CREATE_PRD_BRD_NOT_SLICED`, `CREATE_ARD_BRD_NOT_SLICED`, `SPECIFY_BRD_NOT_SLICED`;
  `pm-workflows:coverage-ledger-format` §5), so naming one against a root hands over a run that
  stops on its first phase. **A root's advance is its slices instead** — `/pm-workflows:brd-ground
  <SLICE-KEY>` once per non-empty slice, each re-entering the route in its own right and reaching
  this same hand-over on its own key. That one **does** carry `<merge-clause>`, because
  `/pm-workflows:brd-ground` gates `coverage-ledger.md` on the default branch and the reconciliation
  wrote to a ledger.
  **On a slice, and only on a slice, the three are offered — but only on a run that left nothing to
  re-enter for.** Advance and re-entry are separate arrays there, not one: where that run reopened a
  decision, left a `[C]` held for the customer, left a finding for a `--rebaseline` pass, or could
  only record a dependent's sweep, all three advance options are dropped, because a `reopened` record
  may not be consumed downstream (`pm-workflows:decision-register-format` §3) and all three consume
  the register. On an advancing slice run, `/pm-workflows:create-prd <SLICE-KEY>` carries the further
  condition that the reconciled ledger leaves no row `unallocated` and at least one `covered-here`
  (`pm-workflows:coverage-ledger-format` §5, the two refusals its Phase 0 raises); the other two
  carry none of their own: neither reads the ledger, and although both now run the PRD gate on every
  route, that gate's `absent` branch proceeds — a slice holding no authored `prd.md` is the ordinary
  state for both, since `/pm-workflows:create-prd` is a prerequisite for neither. **That difference is where the conditions come from, and it matters:**
  the level test and `/create-prd`'s eligibility test are each enforced by the offered command's own
  Phase 0, so offering either wrongly hands over a run that stops;
  the advance/re-entry split is enforced **nowhere downstream** — `/create-ard` on the BRD route and
  `/specify` on the BRD route treat an `open` or `reopened` record as an open question to record rather
  than as a stop — so `/pm-workflows:brd-reconcile` is the only station that can make it. None of
  the three carries `<merge-clause>`: none of them runs `require-on-main` against anything
  `/pm-workflows:brd-reconcile` writes.

**PA — architecture (optional)**

- `/pm-workflows:create-ard <PRD>` (PRD-level) → PE → `/pm-workflows:epics <PRD>` (recommended) or `/pm-workflows:specify <PRD>`.
  *(No `/dev-workflows:design` — no Epics yet.)*
- `/pm-workflows:create-ard <EPIC>` (Epic-level) → `/pm-workflows:specify <EPIC>` (recommended) or Dev →
  `/dev-workflows:design <EPIC>`.

**PE — breakdown & specification**

- `/pm-workflows:specify <PRD>` (PRD-level spec) → `/pm-workflows:epics <PRD>`.
- `/pm-workflows:epics <PRD>` → `/pm-workflows:specify <EPIC>` (per Epic); optional PA → `/pm-workflows:create-ard <EPIC>`.
  **Every `/pm-workflows:epics` option above and below is conditional on the folder it names
  holding an authored `prd.md`** (`kind: prd`): `/epics` accepts a PRD folder or an `EPIC-` folder
  under one and refuses everything else (`/pm-workflows:epics` Phase 0 step 1b). Where the caller's
  resolved folder holds no PRD — which the BRD route reaches legitimately, since
  `/pm-workflows:create-prd` is not a prerequisite for `/pm-workflows:create-ard` there — the
  offer is `/pm-workflows:create-prd <ADDRESS>` instead, **and only where that command can itself
  run**: it refuses three shapes and not one, so on a BRD-route slice the two data refusals on that
  slice's own ledger are tested first and the offer resolves to `/pm-workflows:brd-split` against
  one of two keys, or to no option at all, where either fails
  (`pm-workflows:coverage-ledger-format` §5.2, the authority, applied by each offering command). An
  offer whose run stops the moment it starts is the same defect the `<merge-clause>` rules below
  exist to prevent, one command further on: a next step the operator cannot take from the state the
  report describes.
- `/pm-workflows:specify <EPIC>` (Epic-level spec) → Dev → `/dev-workflows:design <EPIC>`.

**Dev — build, verify & deliver**

- `/dev-workflows:design <EPIC>` → optionally `/dev-workflows:ready <EPIC>` (verify readiness) →
  `/dev-workflows:implement <EPIC>`.
- `/dev-workflows:ready <ADDRESS>` → **SUPPORTED** → `/dev-workflows:implement <ADDRESS>` (the same address); **PARTIAL / NOT-SUPPORTED**
  → resolve the named gaps, then re-run `/dev-workflows:ready`. *(Read-only verifier;
  not itself a linear pipeline node — an optional gate before build.)*
- `/dev-workflows:implement <EPIC>` → finish remaining Epics (breadth); once ALL Epics implemented →
  `/docs-workflows:document <PRD>` → `/docs-workflows:release-notes <PRD>`. *(Direct mode → no forward offer.)*
- `/docs-workflows:document <PRD>` (PRD-level, after all Epics) → `/docs-workflows:release-notes <PRD>`. *(Doc-edit mode → no
  forward offer.)*
- `/docs-workflows:release-notes <PRD>` (PRD-level) → leaf/closure: release note drafted; continue any pending
  PA/PE phase, else the PRD is fully processed.

## Not pipeline nodes

`/dev-workflows:vuln`, `/dev-workflows:upgrade`, `/workflows-core:feedback`, `/workflows-core:prompt*`, `/docs-workflows:docs-profile`, `/workflows-core:statusline`, `/workflows-core:frames`, and the reviewer
commands are NOT part of the linear PRD→docs pipeline and carry no next-phase offer. `/workflows-core:frames`
repairs a folder's frame-set indexes and advances no phase; it makes the §4.3 handoff offer its
deliverables require and no next-phase offer at all, so no `<merge-clause>` arises — nothing runs
`require-on-main` on a frame-set index.

## Session hygiene co-fires here

The `### Next step` this contract produces is immediately followed by a
`### Context hygiene` block (`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`): the compact-vs-clear
choice reads the SAME role labels computed here (same role → `/compact`; role handoff →
`/clear`). This reference owns the role graph; `session-hygiene.md` only reads it.
