# Next-phase offer (embedded — shared reference)

The plugin-wide contract for the **next-phase offer**: the guidance every pipeline command
surfaces at the end of its run, naming the natural next command(s). Cited by all pipeline
commands so the routing graph and the offer rules live in ONE place (the same shape as
`emit-block` in `feedback-emission.md`).

## The offer contract (5 rules)

1. **Guidance-only** — the offer NAMES the next command(s); it NEVER auto-invokes anything.
2. **Role-labeled** — it names the concrete command(s) for the next step, tagged with the owning
   role (PM / PA / PE / Team), even on a handoff — one person may wear several hats and just keep
   going. Never a bare "hand off to PA".
3. **Adaptive to outcome** — a clean run points forward; a BLOCK / incomplete / cancelled run
   recommends resolving THAT first, not advancing.
4. **Mode-aware** — the forward recommendation is a PIPELINE handoff. In a command's direct /
   ad-hoc mode (no VI/Epic context — `/implement` direct, `/document` doc-edit) it is OMITTED,
   not invented.
5. **Epic fan-out** — a command operating at **Epic scope** offers TWO branches:
   - **Depth** — the next command for the SAME Epic (`/design <VI> E1` → `/implement <VI> E1`).
   - **Breadth** — the SAME command for the NEXT Epic under the VI (`/design <VI> E1` →
     `/design <VI> E2`).

   So a team can go `/design E1 → /design E2 → /implement E1 → /implement E2` OR
   `/design E1 → /implement E1 → /design E2 …` — their call. Applies to the per-Epic commands
   only: `/create-ard <VI> <Epic>`, `/specify <VI> <Epic>`, `/design <VI> <Epic>`,
   `/implement <VI> <Epic>`. `/document` and `/release-notes` are VI-level (whole-feature, run
   once after ALL Epics are implemented) and do NOT fan out.

## Surface

The universal minimum is an adaptive **`### Next step`** section at the END of the command's
Final Report (guidance-only prose). A command MAY additionally present a richer interactive
`choices:` offer (the reference commands `/idea`, `/create-vi`, `/create-ard` do) — compatible,
not required.

## The routing graph (role-aware)

**PM — ideation & framing**

- `/idea` — refined → `/create-vi <JIRA-KEY>` (PM); draft → `/idea @<path> --deep` (PM, refine)
  or `/create-vi <JIRA-KEY>` (PM, proceed on a draft — not recommended).
- `/create-vi <JIRA-KEY>` — after the paste-into-Jira + re-import round-trip:
  `/release-notes <VI>` (PM — draft the release note; recommended clear next step); hand to PA
  *(optional)* → `/create-ard <VI>`; or hand to PE → `/epics <VI>` (or `/specify <VI>`).

**PA — architecture (optional)**

- `/create-ard <VI>` (VI-level) → PE → `/epics <VI>` (recommended) or `/specify <VI>`.
  *(No `/design` — no Epics yet.)*
- `/create-ard <VI> <Epic>` (Epic-level) → `/specify <VI> <Epic>` (recommended) or Team →
  `/design <VI> <Epic>`.

**PE — breakdown & specification**

- `/specify <VI>` (VI-level spec) → `/epics <VI>`.
- `/epics <VI>` → `/specify <VI> <Epic>` (per Epic); optional PA → `/create-ard <VI> <Epic>`.
- `/specify <VI> <Epic>` (Epic-level spec) → Team → `/design <VI> <Epic>`.

**Team/Dev — build**

- `/design <VI> <Epic>` → optionally `/ready <VI> <Epic>` (verify readiness) →
  `/implement <VI> <Epic>`.
- `/ready <VI> [<Epic>]` → **SUPPORTED** → `/implement <VI> [<Epic>]`; **PARTIAL / NOT-SUPPORTED**
  → resolve the named gaps + update the Jira status, then re-run `/ready`. *(Read-only verifier;
  not itself a linear pipeline node — an optional gate before build.)*
- `/implement <VI> <Epic>` → finish remaining Epics (breadth); once ALL Epics implemented →
  `/document <VI>` → `/release-notes <VI>`. *(Direct mode → no forward offer.)*
- `/document <VI>` (VI-level, after all Epics) → `/release-notes <VI>`. *(Doc-edit mode → no
  forward offer.)*
- `/release-notes <VI>` (VI-level) → leaf/closure: release note drafted; continue any pending
  PA/PE phase, else the VI is fully processed.

## Not pipeline nodes

`/vuln`, `/upgrade`, `/feedback`, `/prompt*`, `/docs-profile`, `/statusline`, and the reviewer
commands are NOT part of the linear VI→docs pipeline and carry no next-phase offer.

## Session hygiene co-fires here

The `### Next step` this contract produces is immediately followed by a
`### Context hygiene` block (`references/session-hygiene.md`): the compact-vs-clear
choice reads the SAME role labels computed here (same role → `/compact`; role handoff →
`/clear`). This reference owns the role graph; `session-hygiene.md` only reads it.
