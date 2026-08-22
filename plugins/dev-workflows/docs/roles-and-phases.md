# Roles and phases

[Workflow overview](workflow.md) shows where each command sits in the pipeline. This page says what each role is accountable for, and — in its second half — what each cost-attribution phase means when you see it on a cost report or a run's output.

## The handover model

Every phase but one ends the same way: a producing command lands its deliverable on the specs repo's default branch, and the next command in the chain refuses to start any expensive work until it finds that deliverable actually on the branch — not merely written to disk, and not merely committed to a branch of its own. Two states show up often enough that you will actually hit them.

- **The artifact exists but sits on an unmerged branch** — a pull request open, or one that never got opened. The next command stops cold and names the branch (and the open PR, if there is one) rather than guessing at content that might still change underneath it.
- **The artifact does not exist on any branch at all.** The next command treats it as absent and falls back to whatever it already did before this artifact existed — an absent optional input is never promoted into a new prerequisite. `/design`'s `specification.md` is the one exception: it is not optional, and its absence is a hard stop.

`/ready` is the one caller allowed to keep going past a stop like this: because its whole job is to report on readiness, an artifact it can't verify becomes a finding that caps its verdict at `PARTIAL` rather than a reason to halt.

## PM — product management

- **Owns:** turning a raw prompt, community post, RFE, or existing VI into a refined idea, then into a well-formed Value Increment, and keeping an existing VI current.
- **Runs:** `/idea`, `/create-vi`, `/update-vi`; also the early run of `/release-notes`, before any specification or design exists yet.
- **Consumes:** a prompt, file, community post, RFE, or existing VI as its source; then a refined `idea.md` plus a user-supplied Jira key.
- **Produces:** `idea.md` in `$VAULT_PATH` before a Jira key exists, then `<KEY>_<slug>.md` written to `$SPECS_PATH/specifications/<KEY>-<slug>/`; an early release-notes draft.
- **Hands over at the seam:** `/idea` relocates and lands `idea.md`, and `/create-vi` / `/update-vi` land the VI, each onto the specs repo's default branch; `/create-ard`, `/epics`, and `/specify` each refuse to start until they find the VI there.
- **Cost phase(s):** `vi-creation` (`/idea`, `/create-vi`), `vi-update` (`/update-vi`) — both role `pm`.

## PA — product architecture

- **Owns:** architecture decisions for a VI, or for one Epic inside it — the only optional role in the pipeline.
- **Runs:** `/create-ard`.
- **Consumes:** the VI (and the Epic, when scoped), grounded on the mounted implementation repos it discovers under `$REPOS_PATH` — architect-driven discovery, never a pull-request read.
- **Produces:** `<VI>_ARD.md`, or `<EPIC>-<area>_ARD.md` for a big Epic split by area, written into the same specs feature folder as the VI.
- **Hands over at the seam:** the VI must be found on the specs repo's default branch before `/create-ard` starts (its absence falls back to reading the Jira export directly, reported rather than silent); `/create-ard` then lands the ARD the same way, and `/epics`, `/specify`, `/design`, `/implement`, and `/ready` each consult it once it's there.
- **Cost phase:** `architecture`, role `pa`.

## PE — product engineering

- **Owns:** breaking a VI into Epics, and writing an org-standard specification for one item — an Epic, or, for a small VI, the whole VI.
- **Runs:** `/epics`, `/specify`.
- **Consumes:** the VI, plus the ARD when one exists and any Epics already drafted.
- **Produces:** Epic drafts under `$VAULT_PATH/jira-drafts/<VI-KEY>/`; `specification.md`, landed on the specs repo's default branch.
- **Hands over at the seam:** both commands refuse to start until the VI is found on the specs repo's default branch (`/epics` also checks for an optional VI-level `specification.md`); `/specify` lands `specification.md` the same way, and `/design` refuses to start until it finds that specification there.
- **Cost phase(s):** `epic-refinement` (`/epics`), `specification` (`/specify`) — both role `pe`.

## Dev — build and deliver

- **Owns:** the engineering design, the implementation, and the documentation of the shipped feature.
- **Runs:** `/design`, `/implement`, `/document`; also the final run of `/release-notes`, once a specification or design already exists.
- **Consumes:** the merged `specification.md` (plus the ARD, when one exists), then the merged `design.md`, then the code under `$REPOS_PATH`.
- **Produces:** `design.md`, landed on the specs repo's default branch; code and a pull request in `$REPOS_PATH`; product documentation in the external docs repo; the final release-notes draft.
- **Hands over at the seam:** `/design` is the one hard exception to the optional-input rule above — it stops outright if `specification.md` is not found on the specs repo's default branch. It then lands `design.md` the same way, and `/implement` refuses to start on its in-scope `specification.md` / `design.md` until they are there.
- **Cost phase(s):** `planning` (`/design`), `implementation` (`/implement`), `documenting` (`/document`) — all role `dev`.

## Team — verification

- **Owns:** verifying that a Jira status is actually justified by the artifacts on record — it never sets status.
- **Runs:** `/ready`.
- **Consumes:** the Jira workflow status, plus the ARD, `specification.md`, and `design.md` for the VI or Epic in question.
- **Produces:** a `SUPPORTED` / `PARTIAL` / `NOT-SUPPORTED` verdict; optionally a `_readiness.md` snapshot, committed and handed off only behind your consent.
- **Hands over at the seam:** as [above](#the-handover-model), `/ready` is the sole caller that keeps running past a stop another command would treat as fatal — an artifact on an unmerged branch, or missing entirely, becomes a finding that caps the verdict at `PARTIAL` instead of halting the run.
- **Cost phase:** `readiness`, role `team`.

## Cost-attribution phases

Every VI-lifecycle command tags its cost line with a `phase` and a `role`. Nine phases exist; each entry below names the command that emits it and what being in that phase means.

### vi-creation

Emitted by `/idea` and `/create-vi`, role `pm`. Being in this phase means the VI does not yet have a merged specification or design — the work underway is idea refinement or VI authoring, and Epics may or may not exist yet. `/release-notes` also lands here, by inference, on a run where neither `specification.md` nor `design.md` exists under the VI's specs directory.

### vi-update

Emitted by `/update-vi`, role `pm`. Being in this phase means an existing VI is being refreshed or re-done, never created from scratch — the distinction cost aggregation needs between a first VI write and a later revision.

### architecture

Emitted by `/create-ard`, role `pa`. Being in this phase means architecture decisions are being recorded for a VI or one of its Epics — the plugin's one optional phase.

### specification

Emitted by `/specify`, role `pe`. Being in this phase means an org-standard `specification.md` is being authored for one item, lightly grounded in code.

### epic-refinement

Emitted by `/epics`, role `pe`. Being in this phase means a VI is being broken down into child Epic drafts.

### planning

Emitted by `/design`, role `dev`. Being in this phase means an engineering `design.md` is being authored from a merged specification, grounded strictly in the mounted code.

### implementation

Emitted by `/implement`, role `dev`. Being in this phase means code is actually being written, tested, and reviewed.

### documenting

Emitted by `/document`, role `dev`. Being in this phase means product documentation is being written or updated for a shipped feature. `/release-notes` also lands here, by inference, on a run where a `specification.md` or `design.md` already exists for the VI.

### readiness

Emitted by `/ready`, role `team`. Being in this phase means a Jira status is being checked against the ARD / spec / design record, never changed.

---

**A second, unrelated `phase:` vocabulary exists in this plugin.** The model-routing resume phases — `full`, `verify-resume`, `regression-resume` — are what `/vuln` and `/upgrade` pass to their fixer/executor agents to say how far a re-entered run should re-execute after a review or a failed test. Neither `/vuln` nor `/upgrade` emits a cost-attribution phase at all; they sit outside the nine phases above entirely. The two vocabularies share a field name, `phase`, and nothing else — one names where a run sits in the product lifecycle, the other names how much of a single command's own work must be redone.
