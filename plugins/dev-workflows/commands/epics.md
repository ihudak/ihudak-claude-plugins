---
name: epics
description: keyed Epic-writing workflow. Takes one address and accepts exactly two shapes — a PRD- folder (draft new Epics) or an EPIC- folder that has a PRD above it (re-refine that Epic) — refusing a stand-alone EPIC- folder and a BRD- container, since Epics come from a PRD only and this is the only command that creates an EPIC- folder. Reads the Product Requirements Document and existing Epics from the resolved folder in the specs tree, optionally scans code repos, drafts child Epic definitions, and gates on prose-style-checker and Opus epic-reviewer.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Draft child Epics for the resolved Product Requirements Document: $ARGUMENTS

`/epics` is the **keyed Epic-writing** workflow. Given a Product Requirements Document key, it reads the PRD plus its existing Epics from the resolved PRD folder, optionally scans code repos to identify reusable capabilities and gaps, drafts child Epic definitions as markdown files under the resolved output directory, and gates the result on an Opus review.

Key distinction from `/document` (keyed mode): the PRD being Epic-ized is **not yet implemented** — there are no PRs to diff. Code scanning (when enabled) is a plain filesystem search to understand what exists and what needs to be built.

**`/epics` accepts exactly two shapes and refuses everything else** (Phase 0 steps 1a and 1b): a `PRD-` folder, which it partitions into new Epics, or an `EPIC-` folder **that has a PRD above it**, which it re-refines. A stand-alone `EPIC-` folder and a `BRD-` container are both refused. **Epics come from a PRD only**, and `/epics` is the only command in this plugin that creates an `EPIC-` folder — `/create-ard` and `/specify` refuse an absent one rather than minting it.

`/epics` **never branches** and **never commits the Epic drafts** (still true — the run's git **writes** are confined to `$SPECS_PATH`, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`; the run does make read-only git calls elsewhere — Phase 4's `git remote get-url origin` per candidate clone and Phase 8's `git diff --stat` from `project_root` — but none of them writes), and writes only inside the resolved PRD folder — one `EPIC-<PRD-KEY>-NN-<eslug>/` per Epic, plus `_coverage.md` beside `prd.md`. Git hygiene of the write target is the user's responsibility — they may or may not have it under version control. The run commits only inside `$SPECS_PATH`, and only its bounded session-artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1) — via the `specs-preflight` flush at run start (§3.4) and the terminal `commit-artifacts` step (§4); never the drafts, never the write target. It still creates no branch (still true — `specs-preflight` switches `$SPECS_PATH` only between branches that already exist, and only plugin-created ones (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.2); it creates none).

---

## Phase 0 — Load

1. **Resolve the address.** Parse the **single positional address** from `$ARGUMENTS` — a `<KEY>`, or an
   `@<path>` naming a folder or a file inside one — and resolve it with
   `resolve-address` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), **with no `<KIND>`
   argument**: a slice folder is `PRD-`-prefixed while the `brd-link.md` inside it asserts
   `kind: brd`, so narrowing the resolution by kind would refuse on one route the very folder it
   resolves on the other (`addressing.md` §3, `resolve-key` step 1). The kind gate is step 1b's, and
   it is taken on what the resolved folder **holds**.
   `status: found` → carry its `path`, `kind` and `key` forward; `ambiguous` → stop,
   naming every match and `@<path>` as the way through. **`absent` is a graceful stop, not a folder
   to create** — `/epics` partitions a PRD folder that exists and creates no PRD folder of its own:
   ```
   EPICS_NOT_FOUND: no folder found for <ADDRESS> under $SPECS_PATH/specifications/ (every level addressing.md §3 bounds, plus §5's legacy fallback) — check the address. /epics partitions an existing PRD folder and creates none. A PRD folder is created by /dev-workflows:idea <KEY> or /dev-workflows:create-prd <KEY> on the idea route, and by /dev-workflows:brd-split on its parent BRD on the BRD route; an EPIC- folder is created by this command and by no other, so an Epic address that resolves to nothing was never drafted here.
   ```
   Every command that stop names creates the folder it claims to, and none of them is a command this
   one would then refuse: `/idea` and `/create-prd` each write `PRD-<KEY>-<slug>/` on their first
   write, and `/brd-split` carves the `PRD-` slice — all three `PRD-` folders that pass step 1a.

   `/epics` is **address-required**: with no positional address, stop with
   `EPICS_NEEDS_KEY: /epics needs a PRD or Epic address — a key, or an @<path> to its folder.` —
   `/epics` has no direct-prompt behavior. Downstream, `<PRD-KEY>` denotes the
   **PRD folder's** own `key` (`addressing.md` §4), read from its frontmatter
   and never parsed out of its directory name — the resolved folder itself when the address named a
   PRD, its parent when the address named an Epic (step 1b).

1a. **Refuse a `BRD-` container**, the moment step 1 returns `status: found` and ahead of every read
   this command makes. **Epics come from a PRD only, and there are no Epics at BRD level**
   (`docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` D6): a BRD is a container,
   and the `EPIC-` folders this command writes belong under the `PRD-` slices carved from it — never
   beside `brd/`, `grounding/`, `coverage-ledger.md` and `slices.md`, in a folder
   `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §2 invariant 1 gives no Epic. This refusal is
   taken here rather than left to step 1b: a container fails 1b's test anyway (it holds no `prd.md`),
   but 1b's remedy names `/dev-workflows:create-prd`, which refuses a container in turn — a stop
   whose remedy stops is a dead end, and this step is what keeps it from being one.

   **The test is the directory prefix, and never the folder's asserted `kind:`** — `/brd-split`
   writes `kind: brd` into the `brd-link.md` it places inside a `PRD-` slice folder, so a slice
   **asserts `brd` while being exactly the folder Epics belong under**, and a gate on the asserted
   kind would refuse every slice and accept nothing.

   **Where the folder resolved through `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §5's legacy
   fallback and carries no prefix, the question is answered by positive evidence that it is a BRD,
   never by the absence of a file** — `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md`
   §5.1, the shared authority `/create-prd`, `/create-ard` and `/specify` take this same test from.
   In short: a legacy folder carrying `coverage-ledger.md` or `brd/brd-inventory.md`, and no
   `brd-link.md` naming a `parent:`, is a root container; a legacy folder carrying **neither** of
   those two files is a legacy **idea-route PRD folder**, which holds `prd.md` and no `brd-link.md`
   either — this refusal does not fire on it, and refusing it would offer `/dev-workflows:brd-split`
   on a folder with no coverage ledger to walk. **Without this clause step 1a is prefix-only, and
   the dead end this step exists to prevent is reachable from one typo**: an unprefixed root BRD
   would pass 1a, fail 1b for holding no `prd.md`, and be sent to `/dev-workflows:create-prd`, which
   takes §5.1 and refuses it as a container — a stop whose remedy stops. §5.1's test **opens no
   ledger**, exactly like the remedy below: it asks which files the folder carries —
   `coverage-ledger.md` and `brd/brd-inventory.md` are tested for presence and never read — and
   opens at most one file, the `brd-link.md` whose `parent:` separates a legacy root from a legacy
   slice, which is the same single file the remedy's slice enumeration below reads. The one place
   this command opens a `coverage-ledger.md` is step 1b's `EPICS_NO_PRD` offer test, which runs only
   after the run has already been refused.

   Stop gracefully:
   ```
   EPICS_BRD_NOT_SLICED: <BRD-KEY> resolves to a BRD- container at <path>, and a BRD has no Epics — they are minted under the PRD- slices carved from it, one set each (addressing.md §2 invariant 1). <the remedy, per the branch below>
   ```

   **The remedy is a directory listing rather than a ledger read** — this command reads no coverage
   ledger and does not start now. Enumerate slices by `/brd-split` Phase 0 step 9's **positive
   test**: an immediate subdirectory carrying a `brd-link.md` whose `parent:` names this BRD.
   - **One or more slices** — the ordinary shape, since a split always confirms at least one. Name
     every slice and offer `/dev-workflows:epics <SLICE-KEY>` once per slice. That run resolves a
     `PRD-` folder and passes this refusal; whether it then passes step 1b depends on whether a
     `prd.md` has been authored in that slice, which the offer **states** rather than promises. Do
     **not** name `/dev-workflows:brd-split <BRD-KEY>` here: the slices it would carve exist, and on
     a parent whose ledger is fully allocated that run is a no-op (`commands/brd-split.md` Phase 0
     step 10).
   - **No slice at all** — `/dev-workflows:brd-split <BRD-KEY>` is the run that carves one, walking
     every row still `unallocated` and always confirming at least one slice (its Phase 2), after
     which `/dev-workflows:create-prd <SLICE-KEY>` authors the PRD and `/dev-workflows:epics
     <SLICE-KEY>` partitions it. **Two conditions travel with that offer**, in its own text, because
     this command holds neither answer: its Phase 0 gates on this BRD's grounding findings each
     carrying a verifier verdict and stops naming `/dev-workflows:brd-ground <BRD-KEY>` when they do
     not; and **where this BRD's ledger leaves no row `unallocated` that run is a no-op** (its
     Phase 0 step 10) and carves nothing, since nothing in this plugin moves a terminal row back to
     `unallocated` (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §3). Say what the
     operator does then rather than leaving the offer to fail silently. There are two ways to reach
     it and **both are leaveable** — one by a decision, one by a repair. Either the one slice the
     walk confirmed was removed as a standing empty child, in which case every requirement is
     `deferred-to`, `rejected` or `superseded-by`, every row is legal and terminal, and no Epic is
     owed by anybody: that is an **ending rather than a failure**, and no command decides otherwise,
     because un-deferring a requirement is a decision taken with the customer. Name no command for
     the decision — and say, rather than implying the state is sealed, that once it is taken it is
     carried out by the same two repairs the other way below names, in the same order: hand-edit the
     one row that is now to be built back to `unallocated`, after which
     `/dev-workflows:brd-split <BRD-KEY>` has a row to walk and carves the slice; or re-run
     `/dev-workflows:brd-intake <BRD-KEY> @<brd-file>`, which reopens **every** row and discards
     every deferral and rejection recorded here. Or the ledger
     records a fate a container can no longer hold — a **root** row `covered-here`, which only a
     tree written before a BRD became a container, or a hand edit, can have produced
     (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5). **Offer the narrower repair
     first**, because the illegal state is one row wide and every other row is already legal and
     terminal: hand-edit that one row's `disposition:` in `coverage-ledger.md`, leaving every other
     row untouched — to `deferred-to: <this BRD>`, `rejected: [DEF#n]` or `superseded-by: [BR#n]`
     where the requirement is not to be built here, which makes the ledger legal and lands on the
     ending above; or back to `unallocated` where it is, after which `/dev-workflows:brd-split
     <BRD-KEY>` has a row to walk, confirms a slice, and that slice's own walk takes the row to
     `covered-here`, the one level at which `covered-here` is legal. §3's *no command ever moves a
     row back to `unallocated`* binds the commands; this is a hand repair of a value no command
     wrote, and §5 already names hand editing as how this state arises. **Offer the `/brd-intake`
     re-run second, and only where the whole inventory is to be re-taken:** re-running
     `/dev-workflows:brd-intake <BRD-KEY> @<brd-file>` over this same folder is a re-run rather than
     a refusal (its Phase 0 step 7 warns and confirms before the first write) and rewrites the
     ledger with **every** row `unallocated`, after which `/dev-workflows:brd-split <BRD-KEY>` has
     rows to walk. It also **discards every disposition this ledger records**: each `deferred-to`,
     `rejected` and `superseded-by` the walk decided is replaced by `unallocated` and must be
     re-taken, and a `rejected` row must be re-cited against its `[DEF#n]`. Name those decisions —
     saying only that the dispositions are replaced is not the disclosure.

1b. **`/epics` accepts exactly two shapes, and the gate is the artifact's own `kind:`.** A `PRD-`
   folder is partitioned into Epics; an `EPIC-` folder **that has a PRD above it** is re-refined.
   Everything else is refused, and `/epics` is the only command in this plugin that creates an
   `EPIC-` folder (D6).

   **Gate on `prd.md`'s own `kind: prd`, never on the folder's asserted `kind:`.** A slice folder
   asserts `kind: brd` (step 1a), so an asserted-kind gate would refuse every slice while accepting
   nothing. `/create-prd` cannot take this test — it is the run that writes the file — but this
   command can, because by the time it runs the PRD exists. The Epic side of the gate is the same
   test one level down: `epic.md`'s own `kind: epic`, which is also what settles an `@<path>` naming
   a file (§6.3 of the design: stop if the file is not an Epic, naming what it found instead).
   Neither test reads a directory name, so a folder resolved through `addressing.md` §5's legacy
   fallback — unprefixed — is classified exactly as a prefixed one is.

   | The resolved folder | What `/epics` does |
   |---|---|
   | Holds a `prd.md` asserting `kind: prd` | **Draft.** `prd_dir` = the resolved `path`, `<PRD-KEY>` = the folder's own `key`, `focus_key` = `null`. This is the `PRD-` folder on either route — the one `/idea` wrote into, or the slice `/brd-split` carved |
   | Holds an `epic.md` asserting `kind: epic`, and its **parent** holds a `prd.md` asserting `kind: prd` | **Re-refine.** `prd_dir` = the **parent**, `<PRD-KEY>` = the parent's own `key`, `focus_key` = the resolved Epic folder's own `key` — all three read from frontmatter (`addressing.md` §4), never parsed from a directory name |
   | Holds an `epic.md` asserting `kind: epic`, and its parent holds no such `prd.md` | Refuse — `EPICS_EPIC_NOT_UNDER_PRD` below |
   | Anything else — including a `PRD-` folder in which no `prd.md` has been authored yet | Refuse — `EPICS_NO_PRD` below |

   **This revives a path that was already written and unreachable.** `/epics` parses `focus_key`
   below (Phase 3, Phase 3.5, Phase 6) but nothing ever set it, so refine-by-focus could not run and
   an `EPIC-` address was silently partitioned as though it were a PRD. Deriving it here is what
   makes Phase 3's refinement target and Phase 3.5's `mode = refine` reachable at all. The derivation
   is `commands/specify.md` Phase 0 step 1's, reused rather than restated: **the resolved folder's
   kind decides the altitude**, and the second key the retired two-key grammar carried is derived
   from the one address rather than typed beside it (D4). `/epics` takes **one** address; there is no
   `<PRD> <Epic>` pair to give.

   **No authored PRD.** The remedy is `/dev-workflows:create-prd`, and it is named **only where that
   command can actually run**. `/create-prd` refuses **three** shapes, not one, and step 1a has
   taken only the first — the container
   (`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5.2, which is the authority and is
   not restated here). The other two are data refusals on a slice's own ledger, and they exist only
   for a folder carrying a `brd-link.md`, so an idea-route PRD folder takes the first row below with
   no ledger opened. Read the dispositions from `coverage-ledger.md` itself, never from a `ledger:`
   line (§6.1). **This is the one read of a coverage ledger `/epics` makes**, it is confined to this
   stop, and it happens after every other gate has already refused the run — the step 1a remedy
   above is still a directory listing, and no phase of a proceeding run opens a ledger.

   | The resolved folder | What the stop names |
   |---|---|
   | No `brd-link.md` — an idea-route `PRD-` folder | `/dev-workflows:create-prd <KEY>`. It is greenfield-only and redirects to `/update-prd` where a PRD is already there, which this stop has already excluded, and neither data refusal exists off the BRD route |
   | A `brd-link.md`; the gate set leaves **no** row `unallocated` **and** at least one `covered-here` | `/dev-workflows:create-prd <KEY>` — all three refusals cleared |
   | A `brd-link.md`; a gate-set row is still `unallocated` | **Not** `/create-prd`, which raises `CREATE_PRD_BRD_UNALLOCATED`. Name `/dev-workflows:brd-split <KEY>`, whose walk moves exactly those rows and which on a slice runs allocate-only — and say beside it that its own Phase 0 gates on this slice's grounding findings each carrying a verifier verdict and stops naming `/dev-workflows:brd-ground <KEY>` when they do not |
   | A `brd-link.md`; no gate-set row `covered-here`, and the gate set is **empty** | **Not** `/create-prd`, which raises `CREATE_PRD_BRD_NOT_ELIGIBLE`. This is a standing empty child: name the keep-or-remove `/dev-workflows:brd-split <PARENT-KEY>`, the one run that resolves one and not a no-op there (`commands/brd-split.md` Phase 0 step 10) |
   | A `brd-link.md`; no gate-set row `covered-here`, and the gate set is **non-empty** | **Name no command at all**, and say why rather than going quiet: this slice holds no PRD of its own, `/create-prd` would raise `CREATE_PRD_BRD_NOT_ELIGIBLE` whose non-empty branch names nothing either, and nothing in this plugin moves a terminal row back to `unallocated` (§3). Report what the gate-set rows actually resolved to — `deferred-to` is a live obligation of this slice, `rejected` is an obligation of nobody, `superseded-by` was absorbed by the `[BR#n]` that replaced it |

   Stop gracefully:
   ```
   EPICS_NO_PRD: <KEY> resolves to <path>, which holds no prd.md asserting kind: prd — /epics partitions a PRD and there is nothing here to partition. <the remedy, per the row above that matches — and in the last row, what became of the requirements and why no command is named>
   ```
   **Naming `/create-prd <KEY>` unconditionally was a defect of exactly the anatomy step 1a exists
   to prevent, one refusal further on.** The prose here claimed step 1a had "already taken the one
   folder `/create-prd` would refuse", which is wrong on the count: a slice that is ground,
   allocated, and holds every claimed row `deferred-to` or `rejected` passes step 1a, holds no
   `prd.md`, and reaches `/create-prd` only to be refused by a branch that names no command.

   **A stand-alone `EPIC-` folder — one with no PRD above it.** Stop gracefully. It names no plugin
   command, because none of them authors a PRD over an `EPIC-` folder that already exists:
   ```
   EPICS_EPIC_NOT_UNDER_PRD: <KEY> resolves to an Epic folder at <path> with no PRD above it, and an Epic comes from a PRD only — /epics drafts Epics under a PRD folder and re-refines an Epic that has one. No command in this plugin authors a PRD above an Epic folder that already exists. If this Epic's PRD folder exists elsewhere, move the folder into it (git mv) and re-run '/dev-workflows:epics <KEY>'. If the work has no PRD at all, it starts at /dev-workflows:create-prd <A-NEW-PRD-KEY>, which creates its own PRD- folder — this Epic folder is not an input to that run.
   ```
   A top-level `EPIC-` folder is a shape nothing in this plugin produces: `/epics` writes every
   `EPIC-` folder under a PRD folder, and `commands/create-ard.md` and `commands/specify.md` refuse
   an absent one rather than creating it. So it is a legacy tree or a hand-made folder, and `git mv`
   — not a plugin command — is what moves it.

`/epics` is **cwd-agnostic**: it writes Epic drafts to an absolute output
directory (resolved in Phase 1), so it does **not** require cwd to be anywhere in particular.

**Specs-repo preflight.** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`specs-preflight` entry point (§3) inline: flush any leftover session
artifacts from an earlier run, retry an artifact commit that failed to push,
and settle the branch. Prompt-free and silent when the specs repo is clean and
on its default branch. If a guard fires, emit its §5 notice; if it returns
`specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the
terminal `commit-artifacts` step skips on it.

---

## Phase 1 — Clarification

**Rule: Ask, don't guess. This rule is absolute.**

Group questions where possible; use `choices` arrays; 2–4 options, and never author an "Other" option — the harness supplies the free-text escape itself (`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` §0).

Ask about:

- **Where Epics land — derived, not asked.** Each confirmed Epic gets its own folder under the
  resolved PRD folder: `EPIC-<PRD-KEY>-NN-<eslug>/`, holding `epic.md`. There is one home now, so
  there is no output-directory question to ask.

  **Mint the key** as `<PRD-KEY>-NN` — the next unused two-digit segment under this PRD, skipping any
  an existing `EPIC-` folder already uses. Propose it, let the operator override, and validate
  whatever is used with `key-valid` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1); an invalid
  key is **re-prompted, never silently coerced**. This is `commands/brd-split.md` Phase 3 step 1's
  mechanism, reused rather than restated.

  **`_coverage.md` is PRD-holistic and belongs to no single Epic**, so it lands in the **PRD folder**,
  beside `prd.md` — not in any `EPIC-` folder. Putting it in one would make it look like that Epic's
  coverage, which is the opposite of what it reports.


- **Code examination on/off** (default ON). If ON, ask which repos under `$REPOS_PATH` to scan:
  ```
  choices: ["Scan repos referenced by sibling/parent Epics under this PRD (Recommended — auto-derived)", "Let me list the repos manually (you'll be prompted)", "Turn code scan off — produce Epic drafts from PRD content alone"]
  ```
  When "auto-derived" is chosen, inspect the sibling/parent Epics' `implementation.md` records (if any) for repo references; if none, fall back to asking the user to list repos.

- **Repo refresh policy** (only if code scan is ON):
  ```
  choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh"]
  ```
  The `fetch + pull default branch` default matches `code-scanner`'s default (`refresh.switch_to_default_branch: true, refresh.pull: true`) — capability scans target present-day code and want the default-branch tip. This is deliberately different from `/document` (keyed mode), which keeps `pull: false` because historical merged commits must not move.

- **Repos search base (`$REPOS_PATH`)** (only if code scan is ON). Read `${REPOS_PATH:-/workspace}` (the container mounts every repo under `/workspace`). `$REPOS_PATH` may be a single directory or a colon-separated list. Ask:
  ```
  choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel"]
  ```
  If "different path", take free-text input (single dir or colon-separated list) and validate that at least one directory exists under it. Record the resolved value as `$REPOS_PATH`. Individual clones are located in Phase 4 by matching their `git remote` against each repo slug — not by assuming a `<base>/<slug>` directory name.

Also display (for user context):
- Resolved cwd absolute path
- Resolved output directory
- Resolved `$REPOS_PATH` (or "N/A — code scan off")
- Resolved `prd_dir`, `key` and `focus_key` (or "none — PRD-level")

No branching context is shown — this command never branches (still true — `specs-preflight` only switches `$SPECS_PATH` between branches that already exist, and only ones the plugin created, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.2; it creates none).

---

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the classification rules, then classify the task as exactly one of: `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or `HIGH-RISK`. Epic writing is typically **MODERATE** (bounded scope, single PRD, specs-tree output). State the classification and a one-sentence reason.

MODERATE → no separate Opus planner; the `epic-reviewer` gate (Opus, frontmatter-pinned) is mandatory. Resolve the per-step routing per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9:

```yaml
model_routing:
  classification: MODERATE        # typical; SIGNIFICANT possible
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # the folder read, code-scanner, prose-style-checker, doc-fixer, epic-writer (MODERATE)
  review_model:    <§2 Opus chain>     # epic-reviewer (frontmatter-pinned; recorded, no override)
  implementation_model: <= detection_model>   # the epic-writer subagent (Phase 6); planning_model if SIGNIFICANT/HIGH-RISK
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

Each subagent dispatch below cites its chain (§9 role→chain map). **No relaunch advisory** for MODERATE — the writer runs on its detection pin and the gates run on `current_model`, which §3.1 allows (if a run is classified SIGNIFICANT/HIGH-RISK, the §9.1 advisory applies and `epic-writer` escalates to the §2 chain). If no Opus is available, `epic-reviewer` falls to the Sonnet floor — record the degradation in `notes` and the Phase 9 report.

---

## Phase 2 — Plan + approval

**Documentation grounding (optional, independent of code scan).** Before presenting the plan below, run `resolve-docs-grounding epics` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` — this is the run's only consent-bearing step (an index build or a capped refresh), so it must resolve here, before Phase 3's the folder read, Phase 4's repo resolution, and Phase 5's parallel code scan do any of the run's real work. This runs ahead of Phase 2.5/2.6's `require-on-main`/`ard-resolution.md` gates — a deliberate exception to `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §5 rule 2's ordering, kept here rather than moved because `resolve-docs-grounding`'s only expensive step is itself behind its own consent prompt (`docs-grounding.md` step 3.5), and an index build it produces is a durable, run-independent artifact, not per-run work a later stop would waste.

Present a concise plan:

- Resolved `key` and the `prd_dir` path
- Existing Epics identified under this PRD (will NOT be duplicated)
- Repos to scan (or "code scan off")
- Docs grounding: the `docs grounding:` line that `resolve-docs-grounding` returned, verbatim — including its `retrieval:` value and any index-build, staleness, or shadowing clause (off switch: --no-docs)
- Output directory with one file per new Epic; propose a name stub per Epic if the themes already suggest them
- Parallelism plan (up to 4 `code-scanner` instances per batch, single Agent message per batch)
- Proposed Epic sizing/sequencing — prefer fewer, larger Epics where the PRD direction is validated; split only at a genuine risk / feedback-loop boundary; order so that no Epic depends on a later one
- **Wide-refactor exception** — a blast-radius-wide *mechanical* change (rename/retype a shared symbol, column, or type) that genuinely cannot be tracer-bulleted into independent vertical slices is sequenced **expand → migrate-in-batches → contract**: one Epic adds the new form alongside the old, one-or-more Epics migrate call sites in batches, and a final Epic removes the old form (blocked by every migrate-batch). Prefer this over forcing the change into an awkward vertical slice

Ask:
```
"Epic drafting plan ready. What would you like to do?"
choices: ["Approve & continue (Recommended)", "Revise plan", "Cancel"]
```

- **Approve** → proceed to Phase 3
- **Revise** → ask what to change, update, re-show, re-ask
- **Cancel** → stop and summarise what was planned

---

## Phase 2.5 — Resolve applicable ARD (optional)

Resolve any PRD-level ARD for this PRD by citing
`${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with `prd = key`,
**`epic: null`** (Epics do not exist yet — PRD-level ARD only), and `$SPECS_PATH`.

- On `status: none` (including `$SPECS_PATH` unset/unresolvable) → **skip and
  proceed exactly as before.** No prompt, no extra output.
- On `status: unmerged` → **stop**, naming the returned `branch` and any `pr` — an ARD that exists but has not landed on `<default>` is a weaker architectural basis than the one about to arrive, and Epics drafted against it would need re-doing once it does.
- On `status: found` → carry `invariants` + `guidance_summary` forward: pass them
  to `epic-writer` (Phase 6 handoff, as `applicable_ard`) so drafts stay
  consistent with the `AD#N`, and to `epic-reviewer` (Phase 7, as `applicable_ard`)
  which then activates its ARD-conformance dimension. A necessary deviation is
  recorded by the writer in the Epic draft (`- ARD deviation: … flag: architect`)
  and surfaced in the Phase 9 report — never edit the ARD.

---

## Phase 2.6 — PRD-level spec enrichment (optional)

If a PRD-level specification exists, fold its requirements into the coverage
inventory. **Additive, zero-cost when absent** — the common case, since
`/specify` usually runs per-Epic *after* `/epics`.

1. **Resolve the PRD dir:** call `resolve-address <PRD>` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md`
   §3), which searches every level §3 bounds and carries §5's legacy fallback. `status: found` →
   use its `path`; `status: absent` → none exists; `status: ambiguous` → stop, naming every match
   and `@<path>` as the way through. No matching rule is written here: a second copy of the one §5
   states is the drift §1 warns about. If `$SPECS_PATH` is
   unset/unresolvable, or no PRD dir matches at either level → **skip** (set
   `vi_spec_present: false`) — the skip a PRD with no nested folder takes today,
   unchanged.
2. **Detect:** execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against `<PRD-dir>/specification.md`, mapping its §3.7 return value by `stopped` first, never by `on_main` alone. On any stopping state, stop per §4.4, naming `$SPECS_PATH` explicitly — a spec that exists but has not yet landed on `<default>` is a weaker grounding basis than the one about to arrive, and Epics drafted against it would need re-doing. Otherwise (`stopped: false`): on `pass`/`pass_amending`, proceed to step 3 (`pass_amending` prints §3.3's row-B message). On `unmanaged`, behave exactly as before this feature — **skip** (set `vi_spec_present: false`). On `absent`, **skip** (set `vi_spec_present: false`); the run proceeds byte-identically to today — this is the common case, and PRD-level `/specify` remains optional.
3. **Parse** `<PRD-dir>/specification.md` directly (Read it — one file, a simple
   heading scan): extract its user stories `[Uxx]` and their nested acceptance
   criteria `[ACxx]` into `vi_spec_requirements[]`. **Skip `[TCxx]` test cases**
   (per-AC, non-unique, below Epic granularity) and the prose sections
   (Problem/Scope). Because `[ACxx]` numbering restarts per story, qualify each
   `spec-criterion` id with its parent story (`<Uxx>/<ACxx>`) so every `Req` id
   in `_coverage.md` is unique; `spec-story` `[Uxx]` ids are document-unique and
   used as-is:

   ```yaml
   vi_spec_requirements:
     - id:   <Uxx (story) | <parent-Uxx>/<ACxx> (criterion)>   # spec-story id is document-unique; qualify criterion ids with the parent story
       type: spec-story | spec-criterion
       text: <requirement text>
   ```

   Set `vi_spec_present: true` and record the resolved `specification.md` path
   for the Phase 9 report.

---

## Phase 3 — Read the PRD folder

**Read the PRD folder directly.** Read its `prd.md` for the product content, and list the `EPIC-`
subfolders under it for the Epics that already exist — that listing *is* the linked-item hierarchy
the retired reader used to return. Each Epic folder's `key` and title come from its own frontmatter
(`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §4), never from its directory name.

**Build `requirements[]` here, from the PRD you just read.** It is the coverage ground truth Phases 6–7
run on — `epic-writer` receives it, `epic-reviewer` checks Epic coverage against it, and `_coverage.md`
is rendered from it — so nothing downstream works if this step leaves it unset. One row per requirement
the PRD states: its `id` (`[US#n]` / `[AC#n]` / `[SM#n]` / `[UC#n]` / `[FR#n]`), its `type`
(`story` / `criterion` / `metric` / `use-case` / `functional`), and its text. Set
`requirements_source: prd` alongside it.

**Existing Epics come from the same read**, as one entry per `EPIC-` subfolder with its `key` and
title, which is what the non-duplication dimension compares a new draft against. An empty PRD folder,
or one whose `prd.md` states no requirements, is the `key dir not found` case: surface the rule in
`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` (`choices: ["Re-enter key", "Cancel"]`) rather
than proceeding with an empty ground truth, which would let every Epic pass coverage vacuously.

**This step used to dispatch an agent and wait for a handoff.** That agent read a tracker export and
was deleted; the direct read replaced it, but the `requirements[]` the handoff used to return had no
replacement producer for a time — leaving `epic-reviewer`'s coverage dimension, whose undetected
failure it calls a BLOCKER, running against nothing.

When Phase 2.6 set `vi_spec_present: true`, **append** its
`vi_spec_requirements[]` to this `requirements[]` — the PRD's own rows are
unchanged; the appended rows carry `type: spec-story` / `spec-criterion`, which
separates them from the PRD's `story`/`criterion` rows. The merged list flows
unchanged into the Phase 6 handoff and the Phase 7 reviewer brief. When
`vi_spec_present: false`, `requirements[]` is exactly what the folder read returned.

Identify the Epics that already exist — the `EPIC-` folders directly under the resolved PRD folder, each read for its `epic.md` — the new Epic drafts MUST NOT duplicate their scope (enforced later by `epic-reviewer`).

**What refine means now, because it changed.** Refine used to fill in *empty Epics somebody else had created in a tracker* — shells that existed so that linking one to a PRD would surface the PRD on that team's dashboard. That was an artefact of one organisation's tooling and has no analogue here: nothing creates an empty Epic. **Refine now means iterating on an Epic that exists** — re-grounding it, sharpening it after the specification moved, or splitting it. Do not read the phases below as though they were still filling in a shell.

**Refinement target (`focus_key`).** `/epics` always reads and analyses the whole PRD
(the partition and non-duplication logic are inherently PRD-holistic). `focus_key` is **derived, not
typed** (Phase 0 step 1b — the address resolved to an `EPIC-` folder and `prd_dir` is its parent), so
**there is nothing left to validate here and no stop to raise**: the focus Epic is by construction an
`EPIC-` folder directly under `prd_dir`, which is exactly the set this phase enumerates. The old
`EPICS_FOCUS_NOT_FOUND` check and its *"Re-enter the Epic key"* choice belonged to the two-key
grammar, where the second key arrived independently of the first and could disagree with it; D4
removed the second key, and with it the disagreement. A focus Epic that the enumeration cannot see
would mean the resolved folder is not under the folder resolution said it was — a tree defect, not
an operator error, and `addressing.md` §3's ambiguity stop is where that is reported.
Treat `focus_key` as the **single refinement target**: Phase 6 re-drafts
only that Epic's `epic.md`, and Phase 7 reviews only that file. The non-duplication
set (`existing_epics`) is the *other* `EPIC-` folders under `prd_dir` — exclude the focus Epic so
Phase 6 re-emits it rather than skipping it as a duplicate. When `focus_key` is null, behaviour
is unchanged (draft the full partition of new Epics).
When `focus_key` is set, `mode = refine` and `refinement_targets = [the focus Epic]` — Phase 6 iterates on that Epic's current `epic.md` (see `epic-writer` refinement mode) rather than regenerating from the PRD alone.

**Refinement candidates.** From those same `EPIC-` folders, read each `epic.md`'s `refinement_candidate`, `team`, and `scope_hint` (emitted by the folder read at `prd-plus-epics`). Collect `refinement_candidates` = every linked Epic with `refinement_candidate: true`. These are empty/almost-empty team-Epic shells the PE pre-created to encode team boundaries — refinement *targets to fill in*, not non-duplication constraints. This set drives the Phase 3.5 gate.

---

## Phase 3.5 — Refinement-mode gate (conditional)

Runs only when `focus_key` is set OR `refinement_candidates` is non-empty. Otherwise skip silently — `mode = generate`, behaviour byte-identical to the legacy net-new flow.

**Focus key set** → `mode = refine`, `refinement_targets = [focus Epic]`; skip the mode question (the PE named the target explicitly).

**No focus key, `refinement_candidates` non-empty** → present the detected set as a CONFIRMABLE list (detection only *proposes*; the PE is the authority) and ask the mode:
```
Detected N empty/almost-empty team-Epic shells linked to <KEY>:
  - <EPIC-KEY> · <team, or "team: [NEEDS CLARIFICATION]"> · <scope_hint>
  ...
choices: ["Refine these N (partition the PRD across them) (Recommended)", "Generate net-new Epics (ignore the shells)", "Both — refine the shells and draft net-new for leftover scope", "Let me adjust which shells to refine (you'll be prompted)"]
```
Record `mode` (`refine` | `generate` | `both`) and the confirmed `refinement_targets` (empty for `generate`). A target whose `team` is empty carries a `[NEEDS CLARIFICATION — team]` note into the writer handoff.

**Adaptive code-scan default (refine / both only).** Re-surface the code-examination choice now that the target count is known — the Phase 1 answer was given before detection. Default **ON when `len(refinement_targets) >= 2`** (a real cross-team boundary to draw), **OFF when == 1**:
```
choices: ["<adaptive default> (Recommended)", "<the other setting>", "Keep my Phase 1 choice"]
```
with a one-line rationale ("2+ team-Epics → code context helps draw the boundary" / "single Epic → no cross-team boundary; scan off is faster"). This runs ONLY in the refine branch, so the generate / no-candidate path never sees it (no-regression).

---

## Phase 3.6 — Documentation grounding dispatch

**Documentation grounding dispatch (optional, independent of code scan).** `docs_grounding` was already resolved in Phase 2 — consume that cached result here; never re-run `resolve-docs-grounding`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the PRD goal + Epic-set intent, `key` = the PRD key, `themes` = the folder read themes. Carry the digest into Phase 6 with **writer-attach** consumption. When OFF, skip silently.

This phase sits **before** the conditional repo-resolution and code-scanning phases deliberately. It needs only Phase 3's output — the PRD goal and the folder read themes — and nothing from the code scan, and Phase 4 and Phase 5 both skip to Phase 6 when code scan is OFF. Dispatching from inside either of them would discard the digest on exactly the runs that turned code scanning off, after Phase 2 had already asked the user to consent to building an index for it.

---

## Phase 4 — Resolve repos (conditional)

If code scan is OFF, skip to Phase 6.

If code scan is ON:

1. Derive the repo list:
   - **Auto-derived** (Phase 1 default) — walk the `EPIC-` folders under the PRD folder; for each `epic.md` (already read during Phase 3), collect repo names from the `implementation.md` beside it, where one exists. Dedupe. If the auto-derived list is empty, fall back to asking the user.
   - **Manual list** — prompt for a free-text list of repo short names (one per line or space-separated). Resolve each against the `$REPOS_PATH` slug→clone map built in step 2 below.

2. Build a slug→clone map. For each top-level directory under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as that clone's slug. Skip directories with no `.git` or whose `git remote` call fails/times out. Resolve each in-scope repo slug against the map: one match → use it; multiple matches → auto-prefer basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last (show candidates at plan approval); zero matches → escalate per the `Repo unresolved (zero matches) — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo"]
   ```

3. If the final resolved repo list is empty (every repo was skipped or missing), escalate per the `No repos derivable — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   ```
   choices: ["List repos to scan manually", "Proceed without code scan", "Cancel"]
   ```

---

## Phase 5 — Parallel code scanning (conditional)

If code scan is OFF, skip to Phase 6.

Spawn `code-scanner` instances in **batches of up to 4 concurrent agents** per Agent message. Wait for each batch before spawning the next.

For each repo in the batch:

→ Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Scan this repo for the brief:
  >
  > repo_path:     <resolved absolute path for this repo from Phase 4>
  > repo_url_slug: <repo slug, e.g. "cluster">
  > capability_themes:
  >   [paste the themes array from the folder read, plus any PRD-goal-derived themes]
  > context: |
  >   [3–5 sentences: PRD goal, what the Epic-set is meant to achieve]
  > search_hints:
  >   symbols:  [class/function names inferred from PRD/Epic descriptions, or []]
  >   paths:    [directory globs inferred from themes, or []]
  >   keywords: [grep keywords extracted from themes]
  > refresh:
  >   switch_to_default_branch: [true if Phase 1 chose 'fetch + pull default branch' (default) or 'fetch only'; false if 'no refresh']
  >   pull: [true if 'fetch + pull default branch'; false otherwise]"

Handle per-repo status after the batch returns:

- `OK` / `PARTIAL` / `EMPTY` — store the output, continue.
- `REPO_MISSING` — should not happen at this stage (Phase 4 already checked). If it does, escalate per the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
- `DIRTY_TREE` — escalate:
  ```
  choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel"]
  ```
- `REFRESH_BLOCKED` — escalate:
  ```
  choices: ["Continue with current local state", "Skip this repo", "Cancel"]
  ```
- `prep.read_only: true` — not a failure. The scan ran at `prep.scanned_ref`. Escalate per the `Read-only mount — ref stale or diverged` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`; otherwise proceed silently and cite evidence at `prep.scanned_ref`.

---

## Phase 6 — Write Epics

The drafting is delegated to the **`epic-writer`** subagent (pinned to the §2.1 Sonnet detection chain for MODERATE; §2 Opus only if the run is SIGNIFICANT/HIGH-RISK — see `classification.md` §9.2). The orchestrator prepares a handoff and dispatches; it does not write Epics itself, and **nothing commits in this phase** (still true — `/epics` never branches, and the Epic drafts it writes are never committed; git hygiene of the write target is the user's responsibility. The run commits only inside `$SPECS_PATH`, and only its bounded session-artifact paths, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).

1. **Write the handoff file.** Create a temp file (`mktemp` — never a repo, never the specs tree) containing the `epic-writer` input contract: `folder_read`, `code_scanner_outputs` (empty if no scan), `scope` (Phase 2 in/out of scope), `existing_epics` (non-duplication), `prd_dir` (the resolved PRD folder), `vi_goal`, `key`, `requirements` + `requirements_source` (from Phase 3), `applicable_ard` (the Phase 2.5 invariants + guidance_summary, or omit when status was none), `existing_epic_themes` (themes of the already-linked Epics), `mode` (`generate` | `refine` | `both` — from Phase 3.5; `generate` when 3.5 skipped), `refinement_targets` (list of `{key, team, scope_hint, current_body_path}`, where `current_body_path = <prd_dir>/EPIC-<EPIC-KEY>-<eslug>/epic.md` — the keyed folder, keyless filename shape `epic-writer` writes and `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §2/§4 define; empty in `generate` mode), and `docs_grounding` (the Phase 3.6 digest, or omit when OFF/EMPTY). Record its absolute path. When `focus_key` is set (the Phase 3 refinement target), set `scope` in-scope to just the focus Epic and `existing_epics` to the *other* linked Epics, so `epic-writer` re-drafts the single focus Epic's `epic.md`; the PRD folder is unchanged.

2. **Dispatch the writer:**

→ Agent (subagent_type: "dev-workflows:epic-writer", model: `<detection_model — §9 / §2.1 Sonnet chain; planning_model (§2 Opus) only if classification is SIGNIFICANT/HIGH-RISK>`):
  > "Write the child Epic definitions for this brief.
  >
  > handoff_file: [absolute path of the temp handoff file from step 1]"

3. **Handle the return.** `status: DONE` → record `files_written` for Phase 6.1 onward. `status: BLOCKED` → surface the named gap:
   ```
   choices: ["Provide the missing input (you'll be prompted)", "Cancel"]
   ```
   On a provided value, rewrite the handoff and re-dispatch once. Nothing is committed here (still true — this step writes only `epic.md` files into the PRD folder, which `commit-artifacts` never stages; git management there is the user's responsibility).

   Also record `coverage_file` (the `_coverage.md` path) and `clarifications_needed[]` for Phases 6.1 and 7.

---

## Phase 6.1 — Resolve clarifications

If the writer returned a non-empty `clarifications_needed[]`, resolve it BEFORE
the style check and review (so no review cycle is spent on known unknowns).
Present ONE batched prompt listing every marker grouped by Epic; for each:
```
choices: ["Use the writer's suggested answer", "I'll answer (you'll be prompted)", "Leave unresolved"]
```
Fold each resolved answer into the affected Epic draft (Edit the file inline, or
re-dispatch `epic-writer` once with the resolutions). Markers the user chooses to
**leave unresolved** stay visible in the draft and become `epic-reviewer`
BLOCKERs in Phase 7. If `clarifications_needed[]` is empty, this phase is a
**silent no-op** (byte-identical to a run without it).

**Leftover disposition (refine / both only).** After the writer returns, read `_coverage.md`; every `❌ gap` row is a PRD requirement no team-Epic covers. In ONE batched prompt, ask per gap:
```
choices: ["Assign to team-Epic <KEY> (re-drafts that Epic to include it)", "Propose as a new (net-new, slug-named) Epic", "Defer (leave as an uncovered row)"]
```
Fold the results back: *assign* → re-dispatch `epic-writer` once (or Edit inline) to add the requirement to the named target's `## Covers` + scope; *new Epic* → add a slug-named net-new draft; *defer* → the row stays `❌ gap` in `_coverage.md` and is listed in the Phase 9 report. Reuses the same batched-gate pattern as the clarification resolution above; no gaps → silent no-op.

---

## Phase 6.2 — Prose style check

Invoke `prose-style-checker` on the files written in Phase 6. Unlike `/document` (keyed mode), this does NOT use `docs-style-checker` (no repo linter for specs-tree content). Instead, the prose style checker validates terminology, trademarks, voice/tone, and inclusive language.

→ Agent (subagent_type: "prose-style:prose-style-checker", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
  > "Run the style check for this brief:
  >
  > files:    [absolute paths of every Epic file written in Phase 6]
  > doc_type: epic
  > emphasis: terminology and customer-facing captions, labels, messages, and text"

Act on the return:

- **`status: OK`** — zero violations. Proceed to Phase 7.
- **`status: VIOLATIONS_FOUND`** — invoke `doc-fixer` with the violations treated as per their severity. After `doc-fixer` completes, re-run `prose-style-checker` once:

  → Agent (subagent_type: "dev-workflows:doc-fixer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
    > "Fix the style violations for this brief:
    >
    > Task description: [Epic drafting for <KEY>]
    > Reviewer or style-checker output: [paste full prose-style-checker output]
    > Project root: [resolved project_root]
    > Severities to fix: MAJOR only"

  If violations remain after the re-run, proceed to Phase 7 — the remaining findings (mostly MINOR/NIT for epics) are informational and will appear in the Phase 9 report.

- **`status: ERROR`** — surface the error reason. Proceed to Phase 7 regardless (style check is not a gate for Epics, but a quality enhancement).

If `prose-style-checker` is unavailable (agent file not found), proceed directly to Phase 7. The style check is optional but recommended.

---

## Phase 6.3 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against each drafted Epic file: the **Universal checks**,
the **key-collision** check (run on the whole Epic file — the template has no frontmatter), and
the **Epic** block (required headings incl. `## Independent Test`; Given/When/Then acceptance
criteria; `[NEEDS CLARIFICATION]` ≤ 3 per Epic; `_coverage.md` present). Surface every finding;
inline-fix the mechanical ones (delete a stray placeholder token); leave content gaps for the author.
**Advisory** — never blocks; proceed to Phase 7 once findings are surfaced. `epic-reviewer` remains the
gate.

## Phase 7 — Epic review gate

Invoke `epic-reviewer` (Opus). This reviewer is Epic-specific — scope clarity, acceptance-criteria testability, non-duplication of existing Epics. `docs-style-checker` is NOT used here (no repo linter for specs-tree content); Prose style is handled by the Phase 6.2 `prose-style-checker` step above.

→ Agent (subagent_type: "dev-workflows:epic-reviewer"):
  > "Review the Epic drafts for this brief:
  >
  > Task description: [one-paragraph: PRD key, PRD goal, number of Epics drafted]
  > Written Epic file paths: [absolute paths of every Epic file written in Phase 6]
  > existing_epics: [one entry per EPIC- folder already under the resolved PRD folder, as read in Phase 3 — its asserted key, its title, and the absolute path of its epic.md; when focus_key is set, the *other* Epics, excluding the focus one]
  > code-scanner output:  [paste array of per-repo scanner outputs from Phase 5, or 'N/A — code scan off']
  > requirements:        [paste the requirements[] array from Phase 3]
  > _coverage.md path:    [absolute path of the coverage file from Phase 6]
  > applicable_ard:       [the Phase 2.5 invariants, or omit if status was none]"

When `mode` is `refine`/`both`, include `refinement_targets` in the `epic-reviewer` brief so its conditional refinement dimensions (completeness, partition integrity, cross-team dependency sanity, team preserved) activate; omit it in `generate` mode so those dimensions report N/A.

Act on the verdict (same shape as `/document` keyed mode Phase 7):

**Triage sub-step** (before any fixer dispatch): follow `${CLAUDE_PLUGIN_ROOT}/references/finding-triage.md`. For each finding, verify its claimed consequence at the location it names; keep or dismiss; record every dismissal with a reason that disposes of that finding's own claim. Hand the fixer **survivors only**, and carry the dismissal list into this run's report.

- **BLOCK** — invoke `doc-fixer` with `Severities to fix: BLOCKER and MAJOR`. Write the `doc-fixer` Fix Report to a temp file (`mktemp -t dw-epics-claims-XXXX.md`, never inside a repo tree or the specs tree), record its path as `claims_file`, then **check `doc-fixer`'s `Stop condition flag` before re-invoking anything**. If it is `NEEDS HUMAN`, the fixer deferred at least one BLOCKER as needing a human decision: do NOT re-invoke `epic-reviewer` — a re-review can only re-find the BLOCKER the fixer has just reported it could not resolve — and instead surface each deferred BLOCKER with the reason the fixer gave, then escalate it individually per the `Review verdict BLOCK (unresolved after one fix cycle) — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`, which names this entry point alongside the second-BLOCK one. Only when the flag is `CLEAR` do you re-invoke `epic-reviewer` once **passing `claims_file`** — so the re-review falsifies the fixer's account rather than assuming it. If still BLOCK, escalate per the `Review verdict BLOCK (unresolved after one fix cycle) — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` for each unresolved BLOCKER individually:
  ```
  choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run"]
  ```
  For `/epics`, "Defer" means the finding goes into an Epic-refinement note in the draft itself (appended as a `## Refinement notes` section) in addition to the Phase 9 report.

- **PASS WITH RECOMMENDATIONS** — invoke `doc-fixer` for MAJOR findings only:

  → Agent (subagent_type: "dev-workflows:doc-fixer", model: `<detection_model — §9 / §2.1 Sonnet chain>`):
    > "Fix the review findings for this brief:
    >
    > Task description: [Epic drafting for <KEY>]
    > Reviewer or style-checker output: [paste the triaged survivor list from the triage sub-step above — the surviving `epic-reviewer` findings only, never the dismissed ones]
    > Project root: [resolved project_root]
    > Severities to fix: BLOCKER and MAJOR"

  MINOR / NIT findings are deferred to the Phase 9 report.

- **PASS** — proceed to Phase 8.

Cap: one fix cycle + one re-review maximum.

---

## Phase 8 — Post-write maintenance

First gather the change context:

a. `project_root` is the resolved PRD folder. Run `git diff --stat` from `project_root` if it is a git repo; otherwise list the written files manually. This command never commits anything under `project_root` — just report what changed (the terminal `commit-artifacts` step commits ONLY `$SPECS_PATH`'s bounded artifact paths, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
b. Compose a **change summary block**:

```
Implementation: [one-sentence description: how many Epics drafted for <KEY>, resolved output directory]
Change type: docs
Classification: MODERATE
Files changed:
<list of new Epic file paths, one per line>
Notable additions/removals: [new Epics by slug — one line each]
(In `refine`/`both` mode, refined Epics are identified by key `<EPIC-KEY>`, not slug.)
Epic-review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK]
```

Then spawn all four maintenance agents in a **single Agent message**. They are independent and run concurrently.

**Agent 1 — Documentation** (general-purpose):
> "Post-write documentation review. Change summary:
> [paste change summary block]
>
> The project root is the resolved PRD folder; look only for internal documentation files that reference the Epics (e.g., an index page enumerating them).
> Determine if any such file needs updating — e.g., a new entry in a drafts index.
> Skip if: no such file exists or drafts aren't indexed centrally.
> If an update is warranted: apply minimal edits.
> Return: file updated and what changed, OR 'no update required (reason)'."

**Agent 2 — Knowledge base** (general-purpose):
> "Post-write knowledge review. Change summary:
> [paste change summary block]
>
> Check ~/.claude/memory/ (global) and .claude/memory/ (project-level, preferred for project-specific knowledge) for existing knowledge files.
> Determine if a new knowledge entry is warranted — look for: reusable insights about this PRD-family's Epic patterns, non-obvious scoping constraints uncovered, code-reuse discoveries from code-scanner, duplicate-Epic near-misses that required scope adjustment.
> If YES: append to the most appropriate existing file (never create a new file if an existing one fits) using this format:
> ### [Short title]
> - **Context**: what problem/situation triggered this
> - **Insight**: the learned rule, pattern, or gotcha
> - **When it applies**: conditions under which this matters
> - **Date**: YYYY-MM-DD
> - **Ref**: [first 60 chars of the key + PRD summary]
> Return: file updated/created and summary of entry, OR 'no update required'."

**Agent 3 — Instructions** (general-purpose):
> "Post-write instructions review. Change summary:
> [paste change summary block]
>
> Check CLAUDE.md in the project root and ~/.claude/CLAUDE.md (global).
> Determine if any Epic-drafting rules, guidance, or guardrails are missing because of what this run revealed (e.g., a domain-specific acceptance-criteria pattern, a naming convention for Epic files, a scope-boundary rule that caught you out).
> Skip if: the run followed existing conventions with no surprises.
> If YES: apply minimal, additive, scoped changes only.
> Return: what was changed and why, OR 'no update required'."

**Agent 4 — Session maintenance** (dev-workflows:impl-maintenance):
> "Analyse this session and return a Lessons Learned report.
>
> Session handoff:
> - Command run: /epics
> - What was done: [one-paragraph summary of Epics drafted]
> - Key events: [BLOCK reviews and their reason, DIRTY_TREE / REFRESH_BLOCKED scanner statuses, duplicate-Epic near-misses, missing repos, user override decisions — or 'none']
> - Workarounds used: [manual steps not automated by the workflow — or 'none']
> - Review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK]
> - Test result: N/A (no tests in /epics)
> - Project root: [resolved project_root]"

Collect all four summaries for the Phase 9 report.

**Persist plugin feedback (automatic).** After Agent 4 (`impl-maintenance`)
returns, project its plugin-facing slice into the specs repo by citing
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
`emit-auto` entry point (§6). Pass Agent 4's Lessons Learned report,
`command: /epics`, the run's `key` and `source`, and `plugin_version`
(read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto`
renders only the report's **Command workflow improvements**, **New agents /
skills**, and plugin **Reference docs** sections plus the **Key observations**
that triggered them (§4 plugin-facing predicate) — never target-project
`CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id`
(§3), resolves the target via the §2 specs-first ladder, and writes silently.
List the persisted path (or "no plugin-facing signal — nothing persisted") in
the Phase 9 report's Session learnings line. ADDITIVE — the impl-maintenance
report still appears in the report; this step NEVER fails the run, NEVER
commits (still true — this step only writes the feedback file; those writes
are committed by the terminal `commit-artifacts` step in Phase 11, per
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and NEVER writes
into the current working directory.

---

## Phase 9 — Final Report

Output a structured report — do NOT ask any closing confirmation:

**When `mode` is `refine`/`both`,** begin the report with a `Mode: <refine | both>` line and split the written-Epics listing into three labelled groups: **Refined** (identified by the target's `<EPIC-KEY>`; the file itself is that Epic folder's own `epic.md`, never `<EPIC-KEY>.md`), **Net-new** (slug-named), and **Deferred** (PRD requirements left uncovered via the Phase 6.1 leftover gate). In `generate` mode the report is unchanged.

```
## keyed Epic Drafting Report

### Classification
MODERATE — Epic drafting for a single PRD

### Model Routing
- Session model (current_model): [model]
- epic-writer (implementation_model): [model] — detection (MODERATE) | reasoning (SIGNIFICANT)
- Detection steps — the folder read, code-scanner, prose-style-checker, doc-fixer (detection_model): [model]
- epic-reviewer (review_model): [model]
- Opus available: [yes | no]

### PRD summary
- Key: <KEY>
- Summary: [PRD summary, 1 line]
- Goal: [2–3 sentence extraction from the folder read]

### Existing Epics (not duplicated)
- [<KEY>] [summary] — [status]
- ...
- _or_ "none"

### New Epics written
- [absolute path] — [1-line Epic summary]
- ...

### Repos scanned
- <repo-1> (<resolved repo_path>) — [status: OK | PARTIAL | EMPTY | DIRTY_TREE | REFRESH_BLOCKED; N themes classified present, M partial, K absent, E error]
- ...
- _or_ "N/A — code scan off"

### Epic review verdict
[PASS | PASS WITH RECOMMENDATIONS | BLOCK] — [1-line summary of findings applied / deferred]

### Review triage
- **Review triage:** [N findings reviewed, M survived] — dismissals: [one line per dismissal, `finding — reason`; or "none"]

### Requirement coverage
[Roll-up verdict + N/M covered (P%); list each ❌ gap requirement ID; _coverage.md path] If Phase 2.6 enriched the inventory, also name the PRD-level `specification.md` path and the count of `spec-*` rows added. — _or_ "derived (coarse) — PRD had no structured requirements"

### Clarifications
[Resolved: <n>; Deferred (left unresolved → became blockers): <n>] — _or_ "none raised"

### ARD conformance
[verdict + any `- ARD deviation:` lines recorded] — _omit this whole section when Phase 2.5 status was none_

### Prose style check (Phase 6.2)
[OK | VIOLATIONS_FOUND (N fixed, M remaining) | ERROR (reason) | SKIPPED (prose-style-checker unavailable)] — [1-line summary]

### Documentation (Agent 1)
- [file updated] — [what was added/changed] OR "no update required (reason)"

### Knowledge base (Agent 2)
- [file updated/created] — [summary of entry] OR "no update required"

### Instructions (Agent 3)
- [summary of change] OR "no update required"

### Session learnings (Agent 4)
- [top suggestions from impl-maintenance agent, or "no suggestions — routine session"]

### Deferred items
[MINOR / NIT findings that were not applied, OR epic-reviewer BLOCK findings that were overridden / deferred with the ## Refinement notes section appended — one line each; or "none"]

### Assumptions & limitations
- [list any]

### Git state
The project root has uncommitted changes. `/epics` never commits the project root — git management there is your responsibility. (This run's `$SPECS_PATH` session artifacts are committed separately by the terminal step — see its outcome line at the end of the run.)

### Next step
[Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — guidance only, never auto-invoked. For each Epic just drafted, author its spec → `/dev-workflows:specify <EPIC>` (PE) — one address, the Epic's own (D4); the **Epic fan-out** (depth vs breadth) applies from the spec/design stage on. Optionally a Product Architect adds an Epic-level ARD first → `/dev-workflows:create-ard <EPIC>`. If the review BLOCKED, resolve that first.]

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 11), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:

- **Continuing as PE (`/dev-workflows:specify <EPIC>`)?** → run **`/compact`** — context still relevant.
- **Handing to PA (`/dev-workflows:create-ard <EPIC>`), even yourself?** → run **`/clear`** for a clean slate.
- Consider **`/rename <PRD-ID>-<slug>-pe`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
```

---

## Phase 10 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 9 Final Report is composed; NEVER
interrupts an earlier phase. Persist the run's manual-step / out-of-scope
follow-ups by citing `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md`
and executing its steps inline.

1. **Collect** the qualifying follow-ups: the manual publish step ("create these
   drafted Epics elsewhere manually" — the drafts are plain files
   tickets) and the Phase 9 `### Deferred items` that are out-of-scope refinement.
2. **Filter** them with the reference's §6 qualifying predicate.
3. **Resolve** the write target via the §4 ladder using `key` and `source`;
   render + place tasks and verbose notes per §1–§3; dedupe per §5.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 9 report. This phase NEVER
fails the run, NEVER commits (still true — this phase only writes follow-up
files; those writes are committed by the terminal `commit-artifacts` step in
Phase 11, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and
NEVER writes into the current working directory.

---

## Phase 11 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 10 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the PRD by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /epics`, `phase: epic-refinement`, `role: pe`,
the run's `key` (or `null`) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<PRD-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no PRD key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

**Then write the resume pointer.** Cite
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite
`<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the
pointer reflects the completed run, and before the commit step below, so it is
included in it. Redact per §1. Silent; the printed `### Context hygiene`
guidance already appeared in the Phase 9 report.

**Then commit session artifacts (terminal).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`commit-artifacts` entry point (§4) inline — the LAST action of the run. It
stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits
`<KEY> Add dev-workflows session artifacts (/epics)`, and pushes per §4 step 5.
It NEVER touches a code/docs
repo, or the current working directory; NEVER
force-pushes; NEVER fails the run; and skips entirely when the run carries
`specs_git: blocked` (§3.3 G0), re-emitting that notice. Because the Phase 9
report was composed before this phase, **print its §6 outcome line here**, as
the run's last output — prefixed `Specs repo:`, with any guard notice repeated
in full.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git
for the deliverable remains the user's responsibility — `/epics` never
branches or opens a PR; the terminal step above commits only the bounded
session-artifact paths in `$SPECS_PATH`), and NEVER writes into
the current working directory; no
user name is ever written (§10 privacy).

---

## Invariants (always enforced)

- ALWAYS `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) before escalating a halt caused by a **plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked) — so a run abandoned at the block still records it. NEVER for a work-quality review BLOCK or an environment / user halt (repo-missing, dirty-tree, key-not-found, cancellation)
- ALWAYS resolve one positional address (Phase 0) — a key or an `@<path>` naming a folder in the specs tree works without it; `/epics` is cwd-agnostic and rejects `mode: direct`
- ALWAYS gate the resolved folder in Phase 0 step 1b on **`prd.md`'s own `kind: prd`** (and, one level down, `epic.md`'s own `kind: epic`) — NEVER on the folder's asserted `kind:`, which a `PRD-` slice folder sets to `brd`; two shapes are accepted (a PRD folder → draft; an `EPIC-` folder with a PRD above it → re-refine, `focus_key` derived from it) and every other shape is refused
- NEVER partition a `BRD-` container (step 1a, `EPICS_BRD_NOT_SLICED`, taken on the directory prefix before any read) or a stand-alone `EPIC-` folder (`EPICS_EPIC_NOT_UNDER_PRD`) — Epics come from a PRD only, and `/epics` is the ONLY command that creates an `EPIC-` folder
- NEVER create a git branch — this command never branches. `specs-preflight` may switch `$SPECS_PATH` between branches that already exist, and only ones the plugin created (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.2); it creates none.
- NEVER commit the Epic files, or anything in the current working directory — git management there is the user's responsibility. **Say what leaving them uncommitted costs**: an `epic.md` in the PRD folder is an `OTHER` path to `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1, so it fires §3.3's G1 advisory on every later run of any command and keeps the preflight's leftover flush and branch settle skipped until it is committed or removed. The terminal `commit-artifacts` step commits ONLY `$SPECS_PATH`'s bounded artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
- ALWAYS run `specs-preflight` at Phase 0 and `commit-artifacts` as the run's last action (per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`) — bounded to `$SPECS_PATH`'s artifact paths (§2.1) and to plugin-created branches (§2.2), always `git -C "$SPECS_PATH"` and never a `cd` (§1 rule 1), never force-pushing, and never failing the run
- NEVER write inside `_archive/` — read-only by convention
- ALWAYS write inside the resolved PRD folder — each Epic in its own `EPIC-` subfolder, `_coverage.md` beside `prd.md` (there is one home and it is derived, so no path is asked for)
- ALWAYS write to `EPIC-<PRD-KEY>-NN-<eslug>/epic.md` under the resolved PRD folder — one home, derived rather than asked for  — auto-create the directory if missing
- ALWAYS escalate missing repos before proceeding — never silent skip
- ALWAYS invoke `epic-reviewer` before Phase 8 maintenance
- ALWAYS resolve the `model_routing` block at Phase 1.5 and pin each subagent dispatch to its §9 chain via `model:` — the mechanical steps (the folder read, `code-scanner`, `prose-style-checker`, `doc-fixer`) and `epic-writer` (MODERATE) to the §2.1 Sonnet chain; `epic-reviewer` keeps its frontmatter Opus pin (no override); coordination + interactive gates run on `current_model`
- ALWAYS delegate Phase 6 writing to the `epic-writer` subagent (write-only); the orchestrator never writes Epics itself and never commits the drafts (still true — the Epic files land in the PRD folder, which the terminal `commit-artifacts` step never stages; git management there is the user's responsibility)
- ALWAYS cap review/fix cycles: 1 fix + 1 re-review max
- ALWAYS pass `Change type: docs` in the Phase 8 change summary block
- ALWAYS pass `Command run: /epics` in the Phase 8 Agent 4 session handoff
- ALWAYS spawn Phase 8 agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; 2–4 options, and never author an "Other" option — the harness supplies the free-text escape itself (`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` §0)
- ALWAYS produce the Phase 9 report as the final output
- ALWAYS end the Phase 9 report with a `### Next step` recommendation (per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`) — guidance only, never auto-invoked
- ALL written claims must be traceable to a resolved key (from the folder read) or code paths (from `code-scanner`); do not invent content the sources don't contain. `[[KEY]]` wikilinks in the draft are correct here and stay: `/epics` writes markdown that Obsidian and IntelliJ both render, where a wikilink resolves. `${CLAUDE_PLUGIN_ROOT}/references/doc-structure-conventions.md` §1 — which bans in-page provenance — governs **rendered product-docs pages** (`/document`'s write targets), not Epic definitions; do not apply it to them
- NEVER run `docs-style-checker` — Epic definitions are specs-tree content and not subject to product-docs prose linting. Prose style is checked via `prose-style-checker` in Phase 6.2 instead.
- ALWAYS have `epic-writer` write `_coverage.md` to the PRD folder itself (PRD-holistic, even in focus mode); it is NOT an Epic definition and is never published
- ALWAYS run the Phase 6.1 clarification gate when the writer returns clarifications; unresolved-by-choice markers become `epic-reviewer` BLOCKERs
- ARD steps (Phase 2.5, writer/reviewer `applicable_ard`, the Phase 9 ARD section) are ADDITIVE and guarded on `status: found` — a run with no ARD is byte-identical to before
- ALWAYS pass `requirements[]`, `existing_epics`, the `_coverage.md` path, and `applicable_ard` (when found) to `epic-reviewer`
- ALWAYS treat linked Epics flagged `refinement_candidate: true` as fill-in targets (not non-duplication constraints) once the Phase 3.5 gate selects `refine`/`both`; the confirmed target set is the PE's, not the raw detection
- ALWAYS write every Epic to `EPIC-<key>-<eslug>/epic.md`, refined and net-new alike — the folder carries the key, the filename carries the kind (never `<slug>.md`; refined files carry a `**Team:**` line
- ALWAYS re-surface the code-scan default adaptively in Phase 3.5 for refine/both (ON at ≥2 targets, OFF at 1) — never in the generate path
- ALWAYS run the Phase 6.1 leftover-disposition gate in refine/both when `_coverage.md` has `❌ gap` rows; silent no-op when none
- Refinement mode (Phase 3.5 gate, `refinement_targets` handoff, leftover gate, keyed output) is ADDITIVE and guarded — no `refinement_candidate` targets AND no `focus_key` ⇒ `mode = generate` and the run is byte-identical to the legacy net-new flow
- ALWAYS end the Phase 9 report with a `### Context hygiene` block per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the `resume.md` write runs later, in the terminal cost phase, per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the guidance only), then a role-aware `/compact`|`/clear` suggestion + `/rename <PRD-ID>-<slug>-pe`; guidance only, never auto-run.
