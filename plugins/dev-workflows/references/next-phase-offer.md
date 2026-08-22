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
   ad-hoc mode (no VI/Epic context — `/dev-workflows:implement` direct, `/dev-workflows:document` doc-edit) it is OMITTED,
   not invented.
5. **Epic fan-out** — a command operating at **Epic scope** offers TWO branches:
   - **Depth** — the next command for the SAME Epic (`/dev-workflows:design <VI> E1` → `/dev-workflows:implement <VI> E1`).
   - **Breadth** — the SAME command for the NEXT Epic under the VI (`/dev-workflows:design <VI> E1` →
     `/dev-workflows:design <VI> E2`).

   So a team can go `/dev-workflows:design E1 → /dev-workflows:design E2 → /dev-workflows:implement E1 → /dev-workflows:implement E2` OR
   `/dev-workflows:design E1 → /dev-workflows:implement E1 → /dev-workflows:design E2 …` — their call. Applies to the per-Epic commands
   only: `/dev-workflows:create-ard <VI> <Epic>`, `/dev-workflows:specify <VI> <Epic>`, `/dev-workflows:design <VI> <Epic>`,
   `/dev-workflows:implement <VI> <Epic>`. `/dev-workflows:document` and `/dev-workflows:release-notes` are VI-level (whole-feature, run
   once after ALL Epics are implemented) and do NOT fan out.
6. **Fully qualified when printed** — every command name the run PRINTS for the user to invoke is
   written `/dev-workflows:<command>`. A bare `/<command>` can resolve to a Claude Code built-in of
   the same name — Claude Code's own `/release-notes`, `/upgrade`, and `/statusline` all collide
   today, and the built-in wins — so the bare form is NEVER printed. Prose that describes the
   pipeline to a reader of this plugin's source keeps the short form.

**A next-step offer that names a downstream command must also name the merge.** The downstream command executes `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) and stops while this phase's pull request is open, so an offer that reads "next: `/dev-workflows:create-ard <KEY>`" without "once the pull request is merged" sends the user into a stop they were not warned about.

## Surface

The universal minimum is an adaptive **`### Next step`** section at the END of the command's
Final Report (guidance-only prose). A command MAY additionally present a richer interactive
`choices:` offer (the reference commands `/dev-workflows:idea`, `/dev-workflows:create-vi`, `/dev-workflows:create-ard` do) — compatible,
not required.

## The routing graph (role-aware)

**PM — ideation & framing**

- `/dev-workflows:idea` — refined → `/dev-workflows:create-vi <JIRA-KEY>` (PM); draft → `/dev-workflows:idea @<path> --deep` (PM, refine)
  or `/dev-workflows:create-vi <JIRA-KEY>` (PM, proceed on a draft — not recommended).
- `/dev-workflows:create-vi <JIRA-KEY>` — after the paste-into-Jira + re-import round-trip:
  `/dev-workflows:release-notes <VI>` (PM — draft the release note; recommended clear next step); hand to PA
  *(optional)* → `/dev-workflows:create-ard <VI>`; or hand to PE → `/dev-workflows:epics <VI>` (or `/dev-workflows:specify <VI>`).
- `/dev-workflows:update-vi <KEY>` — re-entry, not a linear node: reached when
  `/dev-workflows:create-vi` redirects an existing-VI call, or when a later phase forces a VI
  refresh. After the paste-into-Jira + re-import round-trip it offers:
  `/dev-workflows:release-notes <VI>` (PM), `/dev-workflows:create-ard <VI>` (PA, if one exists),
  `/dev-workflows:specify <VI>` (PE, if one exists).

**PA — architecture (optional)**

- `/dev-workflows:create-ard <VI>` (VI-level) → PE → `/dev-workflows:epics <VI>` (recommended) or `/dev-workflows:specify <VI>`.
  *(No `/dev-workflows:design` — no Epics yet.)*
- `/dev-workflows:create-ard <VI> <Epic>` (Epic-level) → `/dev-workflows:specify <VI> <Epic>` (recommended) or Dev →
  `/dev-workflows:design <VI> <Epic>`.

**PE — breakdown & specification**

- `/dev-workflows:specify <VI>` (VI-level spec) → `/dev-workflows:epics <VI>`.
- `/dev-workflows:epics <VI>` → `/dev-workflows:specify <VI> <Epic>` (per Epic); optional PA → `/dev-workflows:create-ard <VI> <Epic>`.
- `/dev-workflows:specify <VI> <Epic>` (Epic-level spec) → Dev → `/dev-workflows:design <VI> <Epic>`.

**Dev — build, verify & deliver**

- `/dev-workflows:design <VI> <Epic>` → optionally `/dev-workflows:ready <VI> <Epic>` (verify readiness) →
  `/dev-workflows:implement <VI> <Epic>`.
- `/dev-workflows:ready <VI> [<Epic>]` → **SUPPORTED** → `/dev-workflows:implement <VI> [<Epic>]`; **PARTIAL / NOT-SUPPORTED**
  → resolve the named gaps + update the Jira status, then re-run `/dev-workflows:ready`. *(Read-only verifier;
  not itself a linear pipeline node — an optional gate before build.)*
- `/dev-workflows:implement <VI> <Epic>` → finish remaining Epics (breadth); once ALL Epics implemented →
  `/dev-workflows:document <VI>` → `/dev-workflows:release-notes <VI>`. *(Direct mode → no forward offer.)*
- `/dev-workflows:document <VI>` (VI-level, after all Epics) → `/dev-workflows:release-notes <VI>`. *(Doc-edit mode → no
  forward offer.)*
- `/dev-workflows:release-notes <VI>` (VI-level) → leaf/closure: release note drafted; continue any pending
  PA/PE phase, else the VI is fully processed.

## Not pipeline nodes

`/dev-workflows:vuln`, `/dev-workflows:upgrade`, `/dev-workflows:feedback`, `/dev-workflows:prompt*`, `/dev-workflows:docs-profile`, `/dev-workflows:statusline`, and the reviewer
commands are NOT part of the linear VI→docs pipeline and carry no next-phase offer.

## Session hygiene co-fires here

The `### Next step` this contract produces is immediately followed by a
`### Context hygiene` block (`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`): the compact-vs-clear
choice reads the SAME role labels computed here (same role → `/compact`; role handoff →
`/clear`). This reference owns the role graph; `session-hygiene.md` only reads it.
