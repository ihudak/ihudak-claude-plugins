---
name: brd-intake
description: BRD-intake workflow (PM phase, entry point of the BRD-to-PRD flow). Copies a customer-supplied business requirements document into the specs repo verbatim, dispatches brd-reader to extract a [BR#n] requirement inventory, confirms its defect candidates interactively against the six brd-format.md classes, and writes a coverage-ledger.md with every row unallocated. Rejects a non-markdown source rather than converting it. Optional --sort-existing migrates an already-hand-written package into seed files. Offers /brd-ground as the next step.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Intake the customer-supplied business requirements document: $ARGUMENTS

`/brd-intake` is the **entry point of the BRD-to-PRD flow** (PM phase) — the first of three
`/brd-*` commands (with `/brd-ground` and `/brd-split`) that turn a long, often internally
contradictory customer BRD into requirements a PRD can be built from. It copies the customer's
source into the specs repo **verbatim and immutably**, extracts a `[BR#n]` requirement inventory
via the `brd-reader` agent, classifies the document's defects **with a human** rather than on the
agent's say-so alone, and writes a coverage ledger in which every requirement starts life
`unallocated` — the state `/brd-split` (a later command) cannot complete past until each row has
been given a fate.

Usage: `/brd-intake <BRD-KEY> @<brd-file> [--sort-existing <dir>]`

---

## Phase 0 — Resolve inputs

1. **`<BRD-KEY>` (mandatory).** Parse the first non-flag token; validate it with `brd-key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §1 — shape only, `^[A-Z][A-Z0-9_]*(-\d+)+$`,
   never checked against a tracker). If absent or invalid, **stop gracefully**:
   `BRD_INTAKE_NEEDS_KEY: /brd-intake needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$, e.g. ACME-001) — pick a short stable identifier for this business requirements document, then re-run '/dev-workflows:brd-intake <KEY> @<brd-file>'.`
2. **`@<brd-file>` (mandatory).** The customer's source file argument. If absent, **stop**:
   `BRD_INTAKE_NEEDS_SOURCE: /brd-intake needs the customer's source as an @-argument — re-run '/dev-workflows:brd-intake <KEY> @<path-to-brd>'.`
3. **Reject a PDF — do not convert it.** If the resolved source does not end in `.md`/`.markdown`
   (a PDF, a Word document, a slide deck, any non-markdown source), **stop**:
   `BRD_INTAKE_NEEDS_MARKDOWN: the source must be markdown — convert it first, and check the conversion. It becomes the immutable record every [BR#n] anchors into.`
   The reason this is a hard stop rather than a best-effort conversion: once intaken, `brd/source/`
   is never edited again (`${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §1), and every `[BR#n]`
   locates itself inside that text by `source_anchor`. An unchecked machine conversion — a dropped
   clause, a misplaced heading, a table read out of row order — would silently become the record of
   what the customer asked for, with no later step positioned to catch it. Converting is the
   operator's own step, done where they can eyeball the result against the original before handing
   it back to this command.
4. **`--sort-existing <dir>` (optional).** If present, validate `<dir>` exists; carry it forward to
   Phase 6. This does not change anything else about Phase 0 — the BRD source is still required and
   still gated by step 3.
5. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH`
   (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).
6. **Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute
   its `specs-preflight` entry point (§3) inline. Prompt-free and silent when the specs repo is
   clean and on its default branch. If a guard fires, emit its §5 notice; if it returns
   `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal
   `commit-artifacts` step skips on it.
7. **Resolve or derive the BRD folder** via `resolve-brd <BRD-KEY>`
   (`${CLAUDE_PLUGIN_ROOT}/references/brd-addressing.md` §2). Found → this is an existing BRD folder
   (a re-run, or a slice already created by a parent's `/brd-split`); use it. Absent → this is a
   brand-new BRD: derive `<slug>` from the source file's first heading (kebab-cased), falling back
   to a kebab of the source filename when no heading is found, and prepare to create
   `specifications/<BRD-KEY>-<slug>/` — the directory is not actually created until Phase 2's first
   write.

`/brd-intake` is the **first command of the BRD-to-PRD route** — unlike every downstream `/brd-*`
command, it consumes no prior phase's deliverable, so it runs no `require-on-main` gate here. It is
cwd-agnostic and needs no repos mounted (no `$REPOS_PATH`); grounding against code and design is
`/brd-ground`'s job, not this one's.

---

## Phase 1 — Confirm

Show, and confirm before writing anything:

- The BRD folder (existing, or the derived `<BRD-KEY>-<slug>` to be created).
- The resolved absolute path to `@<brd-file>`.
- Whether `--sort-existing <dir>` is in play, and its resolved directory.

```
choices: ["Proceed with <folder> (Recommended)", "Use a different key or path (you'll be prompted)", "Cancel", "Other… (describe)"]
```

---

## Phase 1.5 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT for an unusually long or heavily-conflicting BRD
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # brd-reader (frontmatter-pinned to sonnet; recorded, no override)
  authoring_model: <= current_model>   # Phase 1's confirmation and Phase 4's interactive defect classification (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

`brd-reader` runs on Sonnet regardless of `classification` — its extraction work is mechanical, per
its own frontmatter pin. If no Opus resolves for `current_model`, **degrade to best-available +
record** in `notes` and the final report — do not hard-block.

---

## Phase 2 — Copy the source

Copy `@<brd-file>` **verbatim, byte-for-byte** into `<BRD-dir>/brd/source/<basename>` (creating the
BRD folder now, if Phase 0 derived a new one, and `brd/source/` inside it). This is the only write
this phase makes. Per `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §1, nothing under
`brd/source/` is ever edited, reworded, or reformatted after this point, no matter how badly worded
a requirement inside it is — defects found in it are logged beside it (Phase 4), never corrected in
it.

---

## Phase 3 — Extract the inventory

Dispatch `brd-reader`:

→ Agent (subagent_type: "dev-workflows:brd-reader", model: `<detection_model — frontmatter-pinned to sonnet>`):
  > "source_path: [absolute path to the copied file under `<BRD-dir>/brd/source/`]"

Act on `status`:
- **`OK`** — write `<BRD-dir>/brd/brd-inventory.md` per `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md`
  §2: one row per returned `[BR#n]` (`id`, `text`, `source_anchor`), numbered exactly as returned.
  Leave each row's `defects` column empty for now — it is filled in Phase 4, once a candidate is
  actually confirmed into a `[DEF#n]`, never before. Carry every returned `defect_candidates` entry
  forward into Phase 4; nothing here treats a candidate as a decision.
- **`EMPTY`** — report that the source contained no identifiable requirement. Skip Phase 4 (nothing
  to classify) and write an empty `brd/brd-inventory.md` and `coverage-ledger.md` in Phase 5; the
  final report's ledger line reads `ledger: 0 requirements — 0 covered, 0 deferred, 0 rejected, 0 unallocated`.
- **`NOT_FOUND`** — surface the agent's exact message and stop; this should not occur (Phase 0/2
  already confirmed the source exists and is markdown), so treat its appearance as worth
  investigating rather than retrying blindly.

---

## Phase 4 — Confirm defects

**This is the human-in-the-loop step `brd-reader` cannot do itself.** Every `defect_candidates`
entry the agent returned is a hypothesis, never a decision (`agents/brd-reader.md`) — confirming or
rejecting each one, against the customer or the delivery team, is this phase's job alone.

Group the carried-forward candidates by class and walk them **one class at a time**, in the fixed
order `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` §3 lists its six classes. Within a class,
confirm each candidate individually via `AskUserQuestion`:

```
choices: ["Confirm as written (Recommended)", "Confirm with an edited reason", "Reject — not a defect", "Cancel", "Other… (describe)"]
```

On confirmation, assign the next `[DEF#n]` id contiguously across the whole document (ids are never
reused or renumbered, per `brd-format.md` §3–§4) and record it against every `[BR#n]` it was raised
on. A `conflict` or `duplicate` entry always names its counterpart `[BR#n]`, carried straight from
the candidate. On rejection, the candidate is simply dropped — it never becomes a `[DEF#n]`, so
nothing further records that it was proposed.

When every class has been walked, write `<BRD-dir>/brd/brd-defect-log.md`: one entry per confirmed
`[DEF#n]`, each carrying resolution `open` (`brd-format.md` §4 — none of the other three
resolutions has happened yet at intake time). Then update `brd/brd-inventory.md`'s `defects` column
for every affected row with its confirmed `[DEF#n]` ids.

---

## Phase 5 — Write the coverage ledger

Write `<BRD-dir>/coverage-ledger.md` per `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md`
§2: one row per `[BR#n]` from the (now defect-annotated) inventory — `id`, `text`, `defects`
mirrored from the inventory, `evidence` empty (grounding has not run yet — that is `/brd-ground`'s
job), and **`disposition: unallocated` on every row**, per §3: "the initial state; the only one of
the six that blocks §4." No row is ever written in any other disposition here.

---

## Phase 6 — Migrate existing work (`--sort-existing <dir>`, optional)

Only when `--sort-existing <dir>` was given (Phase 0/1). Read the hand-written package at `<dir>`
and sort its sections **by altitude** — product-level content (what / why / for-whom) into
`<BRD-dir>/prd-seed.md`, architecture-level content into `<BRD-dir>/ard-seed.md`, and
implementation-level content into `<BRD-dir>/spec-seed.md`. State plainly in the run's output that
this is **the migration path for work already done by hand**, before this workflow existed — and
that it **writes seeds only, never findings**: no `[CG#n]`/`[DG#n]` grounding, no ledger
disposition, comes out of this phase. Those are `/brd-ground`'s and `/brd-split`'s to produce, once
grounding has actually run. When `--sort-existing` was not given, this phase is skipped silently.

---

## Phase 7 — Handoff

Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md`
§2) with `prefix: brd`, `feature_folder` as resolved in Phase 0, `deliverable_paths` = every file
this run wrote under `<BRD-dir>` (`brd/source/**`, `brd/brd-inventory.md`, `brd/brd-defect-log.md`,
`coverage-ledger.md`, and — only when Phase 6 ran — `prd-seed.md`, `ard-seed.md`, `spec-seed.md`),
`title: <BRD-KEY> Intake BRD source and requirement inventory`, and `body_facts` = the requirement
count, the confirmed-defect count by class, and whether Phase 6 wrote seeds; emit its §4.1 outcome
line in the final report.

`brd` is the branch prefix `phase-handoff.md` §2.9 lists as shared by the three `/brd-*`
commands (the way `prd` is shared by `/create-prd` and `/update-prd`) — a BRD is neither a PRD nor
any of the other five prefixes, and reusing `prd` would collide with the eventual
`prd/<BRD-KEY>-<slug>` branch `/create-prd --from-brd` opens against the same key once this BRD is
PRD-eligible.

---

## Phase 8 — Next steps

```
choices: ["Ground the inventory against code and design once it lands — /dev-workflows:brd-ground <BRD-KEY> is not yet available; a later task in this increment adds it (Recommended)", "Stop here", "Other… (describe)"]
```

`/dev-workflows:brd-ground <BRD-KEY>` will ground every `[BR#n]` against the mounted implementation
and design repos, once it lands — it has not shipped yet, a later task in this increment adds it —
and, once it does, it will not start reading this BRD's artifacts until the pull request above is
merged to the specs repo's main. Guidance only — never auto-invokes another command, and never
asserts a role or cost-attribution row for a command that has not landed; `/brd-ground` carries its
own once it exists. Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`.

### Context hygiene

Per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`, the resume pointer is written in the
terminal cost phase (Phase 9), after the cost entry and before the commit step. Continuing this
route yourself once `/dev-workflows:brd-ground <BRD-KEY>` lands, even as the same person? → run
**`/clear`** for a clean slate. Guidance only — nothing is auto-run.

---

## Phase 9 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 8, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command /
reference gap**, `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that
halt **before** escalating. None of Phase 0's stops qualify — a missing key, a missing source, a
non-markdown source, and an unset `$SPECS_PATH` are all environment / user halts, never a plugin
capability gap, so `emit-block` never fires from this command's own Phase 0.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model:
   `<detection_model — §2.1 Sonnet chain>`) with a compact handoff: command `/brd-intake`; what was
   produced (the inventory, the confirmed defect log, the ledger skeleton); key events (a rejected
   PDF, an `EMPTY` read, unresolved candidates left `open` — or "none"); workarounds; test result
   N/A; project root = the BRD folder.
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /brd-intake`, the run's `jira_key` (the `<BRD-KEY>`),
   `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`).
   Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call
   its `emit-cost` entry point with `command: /brd-intake`, `phase: brd-to-prd`, `role: pm`, the
   run's `jira_key`, `source`, and `plugin_version`. Surface the persisted path (or the report-only
   notice).
4. **Write the resume pointer.** Cite `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and
   write/overwrite `<BRD-dir>/dev-workflows/resume.md` now — after the cost entry above, and before
   the commit step below. Redact per §1. Silent.
5. **Commit session artifacts (terminal).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its `commit-artifacts` entry
   point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths
   inside `$SPECS_PATH`, commits `<BRD-KEY> Add dev-workflows session artifacts (/brd-intake)` with
   no `Co-Authored-By` trailer, and pushes to the branch Phase 7's handoff created. It NEVER touches
   a code repo, a docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER
   fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting
   that notice. Hold its §6 outcome line for the final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable is
offered only in Phase 7), and NEVER writes into a code/docs repo or the current working directory;
no user name is ever written.

---

## Final report

Report: the BRD folder + source path; the requirement count; the confirmed-defect count by class
(and how many candidates were rejected); whether Phase 6 wrote seeds and which; resolved model
routing (+ any Opus degradation); the feedback + cost paths; the `Phase handoff:` outcome line from
`handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1), including the `brd`
prefix note; the `Specs repo:` outcome line from `commit-artifacts`
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6); the next-step recommendation; and end with
the ledger line, exactly per `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated
```

Since `/brd-intake` writes every row `unallocated`, this run's own line always reads
`ledger: <N> requirements — 0 covered, 0 deferred, 0 rejected, <N> unallocated` (or the Phase 3
`EMPTY` line above) — the non-zero counts appear only once `/brd-split` has run.
