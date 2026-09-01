# Roles and phases

[Workflow overview](workflow.md) shows where each command sits in the pipeline. This page says what each role is accountable for, and — in its second half — what each cost-attribution phase means when you see it on a cost report or a run's output.

## The handover model

Every phase ends the same way: a producing command lands its deliverable on the specs repo's default branch — not merely written to disk, and not merely committed to a branch of its own. What the next command in the chain does when that hasn't happened yet depends on which state it finds, and two states show up often enough that you will actually hit them.

- **The artifact exists but sits on an unmerged branch** — a pull request open, or one that never got opened. The next command stops cold and names the branch (and the open PR, if there is one) rather than guessing at content that might still change underneath it.
- **The artifact does not exist on any branch at all.** The next command treats it as absent and falls back to whatever it already did before this artifact existed — an absent optional input is never promoted into a new prerequisite. `/design`'s `specification.md` is the one exception: it is not optional, and its absence is a hard stop.

`/ready` is the one caller allowed to keep going past a stop like this: because its whole job is to report on readiness, an artifact it can't verify becomes a finding that caps its verdict at `PARTIAL` rather than a reason to halt.

## PM — product management

- **Owns:** turning a raw prompt, community post, RFE, or existing PRD into a refined idea, then into a well-formed Product Requirements Document, and keeping an existing PRD current.
- **Runs:** `/idea`, `/create-prd`, `/update-prd`; also the early run of `/release-notes`, before any specification or design exists yet.
- **Consumes:** a prompt, file, community post, RFE, or existing PRD as its source; then a refined `idea.md` plus a user-supplied address.
- **Produces:** `idea.md` in the PRD folder the address names, then **prd.md** written to that same folder under `$SPECS_PATH/specifications/`; an early release-notes draft.
- **Hands over at the seam:** `/idea` writes `idea.md` in its final folder and lands it, and `/create-prd` / `/update-prd` land the PRD, each onto the specs repo's default branch. `/create-ard` and `/specify` each gate on the PRD there — an absent PRD falls back to reading the resolved folder directly instead of stopping (reported, not silent), and the hard stop is an unmerged PRD, never a missing one. `/epics` reads the PRD unconditionally through the folder read, with no PRD gate at all — see PE below for the input it does gate.
- **Cost phase(s):** `prd-creation` (`/idea`, `/create-prd`), `prd-update` (`/update-prd`), `brd-to-prd` (`/brd-intake`, `/brd-split`, `/brd-interview`, `/brd-package`, `/brd-reconcile`) — all role `pm`.
- **Also owns the BRD-to-PRD route** ([BRD workflow](brd-workflow.md)): turning a customer-supplied BRD into a requirement inventory that is grounded, fully allocated, decided, and reviewed by the customer who supplied it. This route is PM-owned end to end — every command on it runs as PM except `/brd-ground`, which is PM-initiated and PA/Dev-executed: PM starts it, and PA/Dev do the actual grounding against the mounted code and design repos.
- **Hands over at the BRD route's own seams:** each `/brd-*` command lands its deliverable on the specs repo's default branch and the next one gates on it there — `/brd-ground` on the intake ledger, `/brd-split` on the grounding findings, `/brd-interview` on `/brd-split`'s fully-allocated ledger (it refuses a single row still `unallocated`) as well as on those findings, `/brd-package` on the decision register, `/brd-reconcile` on the sent package. Between `/brd-package` and `/brd-reconcile` the route leaves the plugin entirely: the customer reviews the bundle off-platform, with a vanilla agent and nothing installed, and the route resumes only when an operator hands `/brd-reconcile` the file that came back. the BRD route on `/create-prd`, `/create-ard` and `/specify` ships, so `/brd-reconcile` is where this route hands over rather than where it ends: its next-step phase offers all three against the same BRD key — `/create-prd` on the BRD route only where the reconciled ledger leaves no row `unallocated` and at least one `covered-here`, and the other two unconditionally, since neither dispatches the folder read, neither gates a PRD and neither reads the ledger.

## PA — product architecture

- **Owns:** architecture decisions for a PRD, or for one Epic inside it — an optional role in the pipeline; also grounding a BRD's requirement claims against code and design, once a PM has initiated `/brd-ground` (see [BRD workflow](brd-workflow.md)).
- **Runs:** `/create-ard`; also `/brd-ground`, PM-initiated but PA/Dev-executed.
- **Consumes:** the PRD (and the Epic, when scoped), grounded on the mounted implementation repos it discovers under `$REPOS_PATH` — architect-driven discovery, never a pull-request read; for `/brd-ground`, the BRD's `[BR#n]` inventory from `/brd-intake` and the mounted implementation and design repos, pinned to a verified commit.
- **Produces:** **ard.md**, or **ard-\<area\>.md** for a big Epic split by area, written into the same specs feature folder as the PRD; for `/brd-ground`, `[CG#n]`/`[DG#n]` grounding findings written into the BRD's own specs feature folder.
- **Hands over at the seam:** `/create-ard` gates on the PRD — an absent PRD falls back to reading the resolved folder directly instead of stopping (reported, not silent), and the hard stop is an unmerged PRD, never a missing one; `/create-ard` then lands the ARD the same way, and `/epics`, `/specify`, `/design`, `/implement`, and `/ready` each consult it once it's there. `/brd-ground` gates on `/brd-intake`'s ledger landing on main, then lands its own grounding findings the same way, and `/brd-split` refuses to allocate a row until every finding on it carries a verifier verdict.
- **Cost phase(s):** `architecture` (`/create-ard`), `brd-to-prd` (`/brd-ground`) — both role `pa`.

## PE — product engineering

- **Owns:** breaking a PRD into Epics, and writing an org-standard specification for one item — an Epic, or, for a small PRD, the whole PRD.
- **Runs:** `/epics`, `/specify`.
- **Consumes:** the PRD, plus the ARD when one exists and any Epics already drafted.
- **Produces:** one `EPIC-<PRD-KEY>-NN-<eslug>/epic.md` per Epic under the PRD folder, plus a PRD-holistic `_coverage.md` beside `prd.md`; `specification.md`, landed on the specs repo's default branch.
- **Hands over at the seam:** `/specify` gates on the PRD the same way `/create-ard` does — an absent PRD falls back to the resolved folder, and is reported rather than silent, and the hard stop is an unmerged PRD, never a missing one. `/epics` has no PRD gate at all, but it does gate two other inputs: an optional PRD-level `specification.md`, whose absence is a silent skip (`vi_spec_present: false`), and the applicable ARD, where `status: unmerged` stops the run like every caller but `/ready`. `/specify` lands `specification.md` onto the specs repo's default branch, and `/design` refuses to start until it finds that specification there.
- **Cost phase(s):** `epic-refinement` (`/epics`), `specification` (`/specify`) — both role `pe`.

## Dev — build, verify, and deliver

- **Owns:** the engineering design, the implementation, and the documentation of the shipped feature — plus deriving the workflow phase from the artifacts on record — and, with `--claimed`, checking a status you declare against it — which this role checks but never sets.
- **Runs:** `/design`, `/implement`, `/document`, `/ready`; also the final run of `/release-notes`, once a specification or design already exists.
- **Consumes:** the merged `specification.md` (plus the ARD, when one exists), then the merged `design.md`, then the code under `$REPOS_PATH`; `/ready` additionally consumes the artifacts present for the PRD or Epic in question.
- **Produces:** `design.md`, landed on the specs repo's default branch; code committed on a feature branch in `$REPOS_PATH`, pushed and opened as a pull request where you agree to it; product documentation in the external docs repo; the final release-notes draft; and, from `/ready`, a `SUPPORTED` / `PARTIAL` / `NOT-SUPPORTED` verdict plus an optional `_readiness.md` snapshot, committed and handed off only behind your consent.
- **Hands over at the seam:** `/design` is the one hard exception to the optional-input rule above — it stops outright if `specification.md` is not found on the specs repo's default branch. It then lands `design.md` the same way. `/implement` gates its own in-scope `specification.md` / `design.md` the same way `/create-ard` and `/specify` gate the PRD — an unmerged one is a hard stop, but an absent one is not: the run behaves exactly as it did before this gate existed, and a direct-prompt run (which resolves no in-scope spec/design at all) is unaffected either way. `/ready` is the opposite extreme, and the exception named [above](#the-handover-model): it is the sole caller that keeps running past a stop another command would treat as fatal, turning an unmerged or missing artifact into a finding that caps its verdict at `PARTIAL` instead of halting.
- **Cost phase(s):** `planning` (`/design`), `implementation` (`/implement`), `documenting` (`/document`), `readiness` (`/ready`) — all role `dev`.

**Why there is no separate verification role.** `/ready` reads a status and reports on it. Its `_readiness.md` is a record rather than a handoff — the one command that reads it, `/implement` at Phase 0.5, only softens a non-blocking recommendation — and it is normally run by the same person who just wrote the design or is about to start the implementation. Giving it a lane of its own would suggest a handover that does not happen — so it sits in `dev`, the role that already owns everything it verifies.

## Cost-attribution phases

Every cost-emitting command tags its cost line with a `phase` and a `role`. Eleven phases exist; each entry below names the command that emits it and what being in that phase means. The first ten are lifecycle phases; the eleventh exists for spend that belongs to no phase at all. Each of the ten can also be reached **by inheritance**: `/prompt` and `/feedback` adopt the phase and role of whatever they are correcting, so a correction to a `/specify` output is a second entry in `specification`. Only the commands named below emit a phase *directly*.

### prd-creation

Emitted by `/idea` and `/create-prd`, role `pm`. Being in this phase means the PRD does not yet have a merged specification or design — the work underway is idea refinement or PRD authoring, and Epics may or may not exist yet. `/release-notes` also lands here, by inference, on a run where neither `specification.md` nor `design.md` exists under the PRD's specs directory.

### prd-update

Emitted by `/update-prd`, role `pm`. Being in this phase means an existing PRD is being refreshed or re-done, never created from scratch — the distinction cost aggregation needs between a first PRD write and a later revision.

### brd-to-prd

Emitted by `/brd-intake`, `/brd-split`, `/brd-interview`, `/brd-package` and `/brd-reconcile`, role `pm`, and by `/brd-ground`, role `pa`. Being in this phase means a customer-supplied BRD is somewhere on the BRD-to-PRD route — its requirement inventory is being extracted, grounded against code and design, split and allocated, decided, packaged for customer review, or reconciled against the review that came back — rather than a PRD already existing for it. This is the one phase in this section shared across two roles: every command on the route runs as PM except `/brd-ground`, which is PM-initiated but PA/Dev-executed, and all of them tag their cost line `brd-to-prd`.

### architecture

Emitted by `/create-ard`, role `pa`. Being in this phase means architecture decisions are being recorded for a PRD or one of its Epics — an optional phase.

### specification

Emitted by `/specify`, role `pe`. Being in this phase means an org-standard `specification.md` is being authored for one item, lightly grounded in code.

### epic-refinement

Emitted by `/epics`, role `pe`. Being in this phase means a PRD is being broken down into child Epic drafts.

### planning

Emitted by `/design`, role `dev`. Being in this phase means an engineering `design.md` is being authored from a merged specification, grounded strictly in the mounted code.

### implementation

Emitted by `/implement`, role `dev`. Being in this phase means code is actually being written, tested, and reviewed.

### documenting

Emitted by `/document`, role `dev`. Being in this phase means product documentation is being written or updated for a shipped feature. `/release-notes` also lands here, by inference, on a run where a `specification.md` or `design.md` already exists for the PRD.

### readiness

Emitted by `/ready`, role `dev`. Being in this phase means the workflow phase is being derived from the ARD / spec / design record, never changed.

### plugin-feedback

Emitted by `/prompt` and `/feedback`, role `n/a`. Being in this phase means the run was about **the plugin itself** rather than the product, and no lifecycle phase owns it. Neither command reaches this phase by default: each first tries to inherit the labels of the command it is correcting or remarking on, so a `/prompt` against a `/specify` output is priced as `specification`/`pe`. This phase is the fallback for a run with no target command, a target that emits no cost of its own, or a target that is itself a feedback command. `role: n/a` is the absence of a role recorded rather than guessed — aggregation should treat it as unattributed, never fold it into `dev`.

---

**A second, unrelated `phase:` vocabulary exists in this plugin.** The model-routing resume phases — `full`, `verify-resume`, `regression-resume` — are what `/vuln` and `/upgrade` pass to their fixer/executor agents to say how far a re-entered run should re-execute after a review or a failed test. Neither `/vuln` nor `/upgrade` emits a cost-attribution phase at all; they sit outside the ten phases above entirely. The two vocabularies share a field name, `phase`, and nothing else — one names where a run sits in the product lifecycle, the other names how much of a single command's own work must be redone.
