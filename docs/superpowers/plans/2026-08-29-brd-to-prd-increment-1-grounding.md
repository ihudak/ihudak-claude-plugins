# BRD → PRD Workflow, Increment 1 (Grounding) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `/brd-intake`, `/brd-ground` and `/brd-split` to `dev-workflows`, so a customer-supplied BRD becomes a requirement inventory, a defect log, a coverage ledger, and a set of code- and design-grounding findings verified against pinned commits.

**Architecture:** Three slash commands orchestrate four new subagents against four new reference documents. The commands write into `$SPECS_PATH/specifications/<BRD-KEY>-<slug>/`, read code repositories read-only, and hand each artifact onto the specs repo's default branch through the existing `phase-handoff.md` gate. Nothing here writes a PRD; increment 3 does that.

**Tech Stack:** Markdown command/agent/reference files under `plugins/dev-workflows/`. No application code. Verification is by three repository gate scripts (`scripts/validate-catalog.py`, `scripts/check-id-grammar.sh`, `scripts/check-docs.sh`), each with a `--selftest` that mutates a fixture tree and asserts *which* check fired.

**Spec:** `docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md`

## Global Constraints

- **No real customer, vendor, product or partner name appears anywhere** (spec D16). Roles are `customer` and `delivery team`. Any worked example is synthetic.
- **Every minted identifier uses the house bracketed form** (spec D21): `[BR#n]`, `[DEF#n]`, `[CG#n]`, `[DG#n]`, `[VD#n]`, `[CD#n]`, `[AS#n]`, `[SR#n]`. The dash form is rejected by `scripts/check-id-grammar.sh`; `BRD-FR-001` trips it via its `-FR-001` substring. `plugins/` is gated; the repo-root `docs/` is excluded by `EXCLUDED_SUBTREES` in that script.
- **Agents and skills cite bundled files as `${CLAUDE_PLUGIN_ROOT}/references/<file>.md`.** Commands cite the same path textually (every existing command does); only model-routing *content* is reached through the `model-routing` skill.
- **Every new command, agent and reference file must land with its documentation entry in the same commit**, or `scripts/check-docs.sh` check 4 fails the build. Adding a file without its entry is a red build, not a follow-up.
- **Prose counts are gated** (check 9). Current tree: 21 commands, 33 agents, 98 reference files, 4 hooks, 2 skills, 13 cost-emitting commands. Increment 1 ends at 24 commands, 37 agents, 102 reference files, 16 cost-emitting commands.
- **No table cell in `plugins/dev-workflows/docs/` may exceed 200 characters** (check 7).
- **No page under `plugins/dev-workflows/docs/` may name a marketplace or container repo** (identity quarantine); `getting-started.md` is the only sanctioned exception.
- **Read-only against code repositories** throughout, per `references/read-only-repos.md`.
- **The verification record is written last** — after the final fix wave, per `CLAUDE.md`. Re-derive every expected count against the tree being verified; never copy a number from this plan without re-measuring.

**The gate triple** — run after every task, from the repository root:

```bash
python3 scripts/validate-catalog.py \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && ./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root .
```

---

## File Structure

**Created under `plugins/dev-workflows/`:**

| File | Responsibility |
|---|---|
| `references/brd-addressing.md` | Key grammar; one-level-deep folder resolution; the shared fallback |
| `references/brd-format.md` | What a BRD is; the six defect classes; the inventory contract |
| `references/coverage-ledger-format.md` | Ledger row shape, dispositions, the allocation gate, the ledger line |
| `references/grounding-format.md` | Finding contract, verdict set, horizon, baseline integrity, verification |
| `agents/brd-reader.md` | Extract `[BR#n]` inventory from a BRD (Sonnet chain, pinned) |
| `agents/code-grounder.md` | Forensic per-repo grounding (no fixed pin) |
| `agents/design-grounder.md` | BRD ↔ design-frame reconciliation (no fixed pin) |
| `agents/grounding-verifier.md` | Independently re-derive findings (Opus, pinned) |
| `commands/brd-intake.md` | BRD → inventory, defect log, ledger skeleton |
| `commands/brd-ground.md` | Baselines, findings, horizons, verification |
| `commands/brd-split.md` | Child BRDs; every requirement allocated |
| `docs/commands/brd-intake.md`, `docs/commands/brd-ground.md`, `docs/commands/brd-split.md` | Per-command human docs |
| `docs/brd-workflow.md` | The route's own page: diagram + parameter table |

**Modified:** `scripts/check-docs.sh`, `plugins/dev-workflows/README.md`, `docs/README.md`, `docs/workflow.md`, `docs/roles-and-phases.md`, `docs/reference/agents.md`, `docs/reference/references.md`, `docs/reference/session-cost.md`, `references/cost-emission.md`, `CHANGELOG.md`, `.claude-plugin/marketplace.json`, `plugins/dev-workflows/.claude-plugin/plugin.json`, `CLAUDE.md`.

---

### Task 1: Teach the prose-count gate the number words this increment needs

The commands sentence in `plugins/dev-workflows/README.md` reads "twenty-one slash commands". Increment 1 takes it to 24, and the cost-emitting sentence from thirteen to 16. `_word2num` in `scripts/check-docs.sh` knows `one`–`fourteen`, `twenty-one`, `thirty-four`, `ninety-eight` and bare digits — none of `fifteen`, `sixteen`, `twenty-two`, `twenty-three`, `twenty-four`. An unknown word falls through to `*) echo "$1"`, so `twenty-four` would be compared against `24` as a string and fail check 9 with a confusing message. Extending the converter keeps the prose in words rather than forcing digits mid-sentence.

**Files:**
- Modify: `scripts/check-docs.sh:453-461` (`_word2num`), `scripts/check-docs.sh:482` (commands alternation), `scripts/check-docs.sh:510-512` (cost-emitting alternation)
- Modify: `scripts/check-docs.sh` selftest block (add one case)

**Interfaces:**
- Consumes: nothing
- Produces: `_word2num` accepts `fifteen`→15, `sixteen`→16, `twenty-two`→22, `twenty-three`→23, `twenty-four`→24; both alternations match those words

- [ ] **Step 1: Write the failing test** — add a selftest case asserting check 9 fires when the commands sentence uses a word the converter must now understand but the tree disagrees. Add inside `selftest()`, beside the existing check-9 cases:

```bash
expect_fail "check 9: word-form command count that disagrees with the tree" 9 \
  "sed -i.bak 's/one slash commands/twenty-four slash commands/' plugins/dev-workflows/README.md && rm -f plugins/dev-workflows/README.md.bak"
```

**The mutation targets the fixture's wording, not the repository's.** `selftest()` copies
`scripts/fixtures/docs/pass/` and mutates the copy; that fixture's README reads *"A fixture plugin of
one slash commands."* and its tree holds exactly one command. A `sed` written against the real
repository's "twenty-one" would match nothing, the mutation would be a silent no-op, and the case
would fail forever because no check fired. Read the fixture before writing the mutation.

- [ ] **Step 2: Run the selftest to verify the new case fails**

Run: `./scripts/check-docs.sh --selftest`
Expected: the new case reports `FAIL` — the mutation makes the sentence say `twenty-four`, which `_word2num` passes through unchanged, so the comparison is `twenty-four` vs the fixture's command count. It does fail check 9, but for the wrong reason; confirm the case is red before proceeding so the fix is what turns it green for the right one.

- [ ] **Step 3: Extend the converter and both alternations**

```bash
# in _word2num, after the eleven..fourteen line:
    fifteen) echo 15 ;; sixteen) echo 16 ;;
    twenty-two) echo 22 ;; twenty-three) echo 23 ;; twenty-four) echo 24 ;;
```

Add `fifteen|sixteen|twenty-two|twenty-three|twenty-four` to the alternation in the `_one "commands"` line and to the `_one "cost-emitting commands"` line. Leave the agents, reference-files, hooks, skills and environment-variable alternations alone — those sentences already use digits.

- [ ] **Step 4: Run the selftest to verify it passes**

Run: `./scripts/check-docs.sh --selftest`
Expected: every case `ok`, including the new one, which now fails check 9 because 24 ≠ the fixture's count rather than because the word was unreadable.

- [ ] **Step 5: Run the full gate triple and commit**

```bash
python3 scripts/validate-catalog.py \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && ./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root .
git add scripts/check-docs.sh
git commit -m "test(gates): teach the prose-count converter the words this increment needs"
```

---

### Task 2: `references/brd-addressing.md`

The key grammar and folder resolution every later task depends on. Written first because both commands and all three later reference documents cite it.

**Files:**
- Create: `plugins/dev-workflows/references/brd-addressing.md`
- Modify: `plugins/dev-workflows/docs/reference/references.md`

**Interfaces:**
- Consumes: nothing
- Produces: entry points `resolve-brd <KEY>` and `brd-key-valid <KEY>`, cited by every `/brd-*` command and by increment 3's `--from-brd` work

- [ ] **Step 1: Create the reference file**

Required sections and their normative content:

- `## 1. Key grammar` — `^[A-Z][A-Z0-9_]*(-\d+)+$`. Valid at any depth: a two-segment key and a three-segment key are both keys. State explicitly: **shape only, never checked against a tracker** — a BRD is a markdown file in `$SPECS_PATH`, not a ticket. Define `brd-key-valid <KEY>` as the entry point returning valid/invalid.
- `## 2. Folder resolution` — define `resolve-brd <KEY>`: match `specifications/<KEY>{-|_}<slug>/` at the top level; on no match, search `specifications/*/` one level deeper for the same pattern; tolerate a human-adjusted slug and a stray `-`/`_` after the key, exactly as the existing feature-folder resolution does. Return the absolute path, or `absent`. State that resolution never descends more than one level below `specifications/`.
- `## 3. Nesting` — a child BRD folder lives inside its parent's folder. Give the shape `specifications/<PARENT-KEY>-<slug>/<CHILD-KEY>-<slug>/`.
- `## 4. The shared fallback for existing commands` — state that `/create-prd`, `/create-ard`, `/epics`, `/specify`, `/design` and `/ready` resolve a PRD dir as flat `specifications/<KEY>-<slug>/` and gain the same one-level-deep fallback in increment 3; the rule is defined here so it is written once. Mark the section as **not yet adopted** in this increment.

Use `[BR#n]`-style identifiers only if identifiers appear at all. No customer or vendor names.

- [ ] **Step 2: Run the docs gate to verify it fails**

Run: `./scripts/check-docs.sh --root .`
Expected: `FAIL check 4: reference file 'brd-addressing' is absent from reference/references.md`, and `FAIL check 9: reference files: plugins/dev-workflows/docs/reference/references.md says 98 (98), tree has 99`.

- [ ] **Step 3: Add the docs entry and the count**

In `plugins/dev-workflows/docs/reference/references.md`, add a row naming `` `brd-addressing.md` `` with a one-line description in the same style as its neighbours, and change the count sentence from `98 files` to `99 files`.

**`references.md` carries more than the gated number.** Its opening paragraph states an arithmetic
reconciliation — total files, top-level markdown files, how many are named individually, the
subtree sum, and what is accounted for against the total. Check 9 sees only the total, but leaving
the rest stale is the drift this repository has a documented history of. Update every figure the
new file changes: the total, the top-level count, the "N of the M" clause, the `36 + 1 + 1 = 38`
arithmetic, and the `38 + 55 = 93 accounted for, against 98 files on disk` sentence. The
"remaining five" non-markdown files are unchanged.

- [ ] **Step 4: Run the gate triple to verify it passes**

Run: the gate triple.
Expected: all green.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/references/brd-addressing.md plugins/dev-workflows/docs/reference/references.md
git commit -m "feat(brd): add the BRD key grammar and folder-resolution reference"
```

---

### Task 3: `references/brd-format.md`

**Files:**
- Create: `plugins/dev-workflows/references/brd-format.md`
- Modify: `plugins/dev-workflows/docs/reference/references.md`

**Interfaces:**
- Consumes: `brd-addressing.md` (§1 key grammar)
- Produces: the `[BR#n]` inventory row shape and the six `[DEF#n]` classes, consumed by `agents/brd-reader.md` and `commands/brd-intake.md`

- [ ] **Step 1: Create the reference file**

Required sections:

- `## 1. What a BRD is here` — a customer-supplied statement of what they are paying for; **immutable** once intaken (spec D11); markdown only, because every `[BR#n]` anchors into it and an unchecked machine conversion must not become the record.
- `## 2. The inventory` — one row per requirement: `id` (`[BR#1]`, contiguous, never renumbered), `text` (verbatim, or its first sentence plus a source anchor), `source_anchor` (heading path or line range in `brd/source/`), `defects` (`[DEF#n]` list). State that a requirement carrying more than one obligation is **split**, each part getting its own `[BR#n]`, and the split recorded as a `[DEF#n]` of class `duplicate`.
- `## 3. Defect classes` — exactly six, each with a one-line test a reader can apply:

| Class | Fires when |
|---|---|
| `ambiguity` | Two competent readers can implement it differently and both be right |
| `conflict` | It cannot hold at the same time as another `[BR#n]`, which it names |
| `untestable` | No externally observable outcome would distinguish success from failure |
| `unsourced` | It asserts system behaviour that grounding must confirm before it can be built on |
| `duplicate` | It restates, or is a part of, another `[BR#n]`, which it names |
| `scope-leak` | It specifies implementation rather than the outcome required |

- `## 4. Defect resolution` — a defect is never fixed in the source. Resolutions: `customer-amended <date>` (with the amended text held in the ledger), `withdrawn`, `resolved-by: [CG#n]`, `open`.
- `## 5. Non-goals` — this reference does not describe a PRD; `prd-format.md` owns that.

- [ ] **Step 2: Run the docs gate to verify it fails**

Run: `./scripts/check-docs.sh --root .`
Expected: `FAIL check 4: reference file 'brd-format' is absent from reference/references.md` and `FAIL check 9: reference files: … says 99 (99), tree has 100`.

- [ ] **Step 3: Add the docs entry and the count**

Add the `` `brd-format.md` `` row to `docs/reference/references.md`; change `99 files` to `100 files`.

**`references.md` carries more than the gated number.** Its opening paragraph states an arithmetic
reconciliation — total files, top-level markdown files, how many are named individually, the
subtree sum, and what is accounted for against the total. Check 9 sees only the total, but leaving
the rest stale is the drift this repository has a documented history of. Update every figure the
new file changes: the total, the top-level count, the "N of the M" clause, the `36 + 1 + 1 = 38`
arithmetic, and the `38 + 55 = 93 accounted for, against 98 files on disk` sentence. The
"remaining five" non-markdown files are unchanged.

- [ ] **Step 4: Run the gate triple to verify it passes**

Expected: all green.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/references/brd-format.md plugins/dev-workflows/docs/reference/references.md
git commit -m "feat(brd): add the BRD inventory and defect-class reference"
```

---

### Task 4: `references/coverage-ledger-format.md`

**Files:**
- Create: `plugins/dev-workflows/references/coverage-ledger-format.md`
- Modify: `plugins/dev-workflows/docs/reference/references.md`

**Interfaces:**
- Consumes: `brd-format.md` (`[BR#n]`, `[DEF#n]`)
- Produces: the ledger row shape, the five dispositions, the allocation gate, and the exact `ledger:` report line — consumed by `/brd-intake`, `/brd-split`, and increment 3's `/create-prd --from-brd`

- [ ] **Step 1: Create the reference file**

Required sections:

- `## 1. Purpose` — the only place a requirement's fate is recorded; without it nothing detects a requirement every child quietly deferred.
- `## 2. Row shape` — `id`, `text`, `disposition`, `defects`, `evidence`.
- `## 3. Dispositions` — exactly six, of which only the last blocks:

| Disposition | Meaning |
|---|---|
| `covered-here` | This BRD builds it; the BRD is therefore PRD-eligible |
| `covered-by: <CHILD-KEY>` | A child BRD builds it |
| `deferred-to: <this BRD>` | Kept as a live obligation, not built now |
| `rejected: [DEF#n]` | Not built, citing the defect that justifies it |
| `superseded-by: [BR#n]` | Replaced by another requirement |
| `unallocated` | The initial state; the only one that blocks |

State that `unallocated` is the initial state written by `/brd-intake` and that deferring **is** an allocation.

- `## 4. The allocation gate` — `/brd-split` cannot complete while any row is `unallocated`; it presents each remaining row one at a time with the four resolutions.
- `## 5. PRD eligibility` — a BRD is PRD-eligible if and only if at least one row is `covered-here`. If every row is `covered-by` or `deferred-to`, the BRD was fully sliced and holds no PRD; a consumer must refuse and name the children.
- `## 6. The ledger line` — the exact one-line summary every `/brd-*` command prints in its final report, with a worked synthetic example:

```
ledger: 47 requirements — 31 covered, 12 deferred, 2 rejected, 2 unallocated
```

State that `covered` sums `covered-here` and `covered-by`, and that `superseded-by` rows are excluded from all four counts and from the total.

- [ ] **Step 2: Run the docs gate to verify it fails**

Expected: `FAIL check 4: reference file 'coverage-ledger-format' is absent from reference/references.md` and check 9 reporting tree has 101.

- [ ] **Step 3: Add the docs entry and the count** — change `100 files` to `101 files`.

**`references.md` carries more than the gated number.** Its opening paragraph states an arithmetic
reconciliation — total files, top-level markdown files, how many are named individually, the
subtree sum, and what is accounted for against the total. Check 9 sees only the total, but leaving
the rest stale is the drift this repository has a documented history of. Update every figure the
new file changes: the total, the top-level count, the "N of the M" clause, the `36 + 1 + 1 = 38`
arithmetic, and the `38 + 55 = 93 accounted for, against 98 files on disk` sentence. The
"remaining five" non-markdown files are unchanged.

- [ ] **Step 4: Run the gate triple to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/references/coverage-ledger-format.md plugins/dev-workflows/docs/reference/references.md
git commit -m "feat(brd): add the coverage-ledger reference"
```

---

### Task 5: `references/grounding-format.md`

The largest reference. It owns the finding contract that both grounding agents and the verifier write against.

**Files:**
- Create: `plugins/dev-workflows/references/grounding-format.md`
- Modify: `plugins/dev-workflows/docs/reference/references.md`

**Interfaces:**
- Consumes: `brd-format.md` (`[BR#n]`), `read-only-repos.md`
- Produces: the `[CG#n]`/`[DG#n]` finding record, the six verdicts, the two horizons, the `baseline-integrity` procedure, and the four verifier outcomes — consumed by `code-grounder`, `design-grounder`, `grounding-verifier` and `/brd-ground`

- [ ] **Step 1: Create the reference file**

Required sections:

- `## 1. What grounding is, and is not` — it answers *is this specific claim true of this specific commit?* Distinguish it explicitly from `code-scanner`, which answers *what capability exists for this theme?* Both ship; they are not alternatives.
- `## 2. The finding record` — every finding carries `id` (`[CG#1]` / `[DG#1]`), `claim` (the `[BR#n]` premise under test), `verdict`, `evidence` (`file:line` list, or an explicit statement of why none exists), `commit`, `altitude` (`product | architecture | implementation`), `horizon`, `consumed_by` (`PRD | ARD | specification | none`, initially `none`).
- `## 3. Verdicts` — exactly six:

| Verdict | Meaning |
|---|---|
| `CONFIRMED` | The premise holds, with evidence |
| `AMENDED` | Partly true; the finding states the correction |
| `REWRITTEN` | The premise is materially wrong; the finding replaces it |
| `FALSE-FRIEND` | A name, field or constant appears to support the premise and does not |
| `NOT-PROVABLE` | Cannot be established from the repository — a valid, final answer |
| `SUPERSEDED` | Replaced by a later finding; the ID is retained |

Under `NOT-PROVABLE`, state the rule plainly: **where a claim cannot be proved from the repository, say so rather than inferring.** Under `FALSE-FRIEND`, say why it earns its own verdict — a plausibly named constant or column that a reader will assume supports the requirement is more dangerous than an absent one.

- `## 4. Baseline integrity` — the `baseline-integrity` entry point, run before any finding is written, per repository:

```bash
git -C "<repo>" rev-parse HEAD                      # record in baselines.md
git -C "<repo>" diff --ignore-cr-at-eol --stat      # must be empty
git -C "<repo>" status --porcelain                  # any entry -> line-count comparison
```

State the failure this prevents: a checkout can report hundreds of modified files that differ only in line endings, and without this check every `file:line` in the package is a citation into an unidentifiable snapshot. The outcome is recorded as a finding with its own ID.

- `## 5. Horizon` — `current` and `will-change`, with the rule that a `will-change` finding **names the prerequisite decision that overturns it**, and that grounding reads only a prerequisite's *frozen* decisions, never speculation. A prerequisite whose decisions are not frozen contributes no `will-change` horizons and is reported as such.
- `## 6. Design grounding` — the four reconciliation classes: a frame shows a field the BRD never requires; the BRD requires a field no frame shows; a frame contradicts BRD text; a frame implies a capture the code cannot perform.
- `## 7. The derivation matrix` — optional; one row per data element the BRD asks to display or store, classed `EXISTS | DERIVED | NEW-CAPTURE | NEW-CONFIG | PARTNER | DEFERRED | DEPENDENCY`. Always implementation-altitude.
- `## 8. Verification` — a finding is not evidence until independently re-derived by a different agent. The verifier does **not** check citations; it re-derives the claim and returns `agree | extend | contradict | unprovable` with its own evidence. Findings inherited from another team's report, or from an earlier run, are unverified by definition.

- [ ] **Step 2: Run the docs gate to verify it fails**

Expected: `FAIL check 4: reference file 'grounding-format' is absent from reference/references.md` and check 9 reporting tree has 102.

- [ ] **Step 3: Add the docs entry and the count** — change `101 files` to `102 files`.

**`references.md` carries more than the gated number.** Its opening paragraph states an arithmetic
reconciliation — total files, top-level markdown files, how many are named individually, the
subtree sum, and what is accounted for against the total. Check 9 sees only the total, but leaving
the rest stale is the drift this repository has a documented history of. Update every figure the
new file changes: the total, the top-level count, the "N of the M" clause, the `36 + 1 + 1 = 38`
arithmetic, and the `38 + 55 = 93 accounted for, against 98 files on disk` sentence. The
"remaining five" non-markdown files are unchanged.

- [ ] **Step 4: Run the gate triple to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/references/grounding-format.md plugins/dev-workflows/docs/reference/references.md
git commit -m "feat(brd): add the grounding finding-contract reference"
```

---

### Task 6: `agents/brd-reader.md`

**Files:**
- Create: `plugins/dev-workflows/agents/brd-reader.md`
- Modify: `plugins/dev-workflows/docs/reference/agents.md`

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md`
- Produces: an inventory document — `[BR#n]` rows with `text`, `source_anchor`, and `defect_candidates` (class + reason, unconfirmed)

- [ ] **Step 1: Create the agent**

Frontmatter, matching the house pattern for a pinned-Sonnet worker:

```yaml
---
name: brd-reader
description: Extracts a requirement inventory from a customer-supplied BRD — one [BR#n] row per requirement, with a source anchor and unconfirmed defect candidates. Splits a requirement carrying more than one obligation. Read-only; never writes the source. Pinned to the §2.1 Sonnet chain — extraction is mechanical; defect classification is the caller's judgement.
model: claude-sonnet-5
tools: ["Read", "Glob", "Grep"]
---
```

Body must: read `${CLAUDE_PLUGIN_ROOT}/references/brd-format.md` for the row shape and the six classes; refuse to run without a markdown source path; emit `defect_candidates` as *candidates* and state that confirmation is the orchestrator's, not the agent's; never rewrite or normalise the source text.

- [ ] **Step 2: Run the docs gate to verify it fails**

Expected: `FAIL check 4: agent 'brd-reader' is absent from reference/agents.md` and `FAIL check 9: agents: … says 33 (33), tree has 34`.

- [ ] **Step 3: Add the docs entry and the count**

Add a `` `brd-reader` `` row to `docs/reference/agents.md` in the established style; change `33 agents` to `34 agents`.

- [ ] **Step 4: Run the gate triple to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/brd-reader.md plugins/dev-workflows/docs/reference/agents.md
git commit -m "feat(brd): add the brd-reader agent"
```

---

### Task 7: `commands/brd-intake.md`

**Files:**
- Create: `plugins/dev-workflows/commands/brd-intake.md`
- Create: `plugins/dev-workflows/docs/commands/brd-intake.md`
- Modify: `plugins/dev-workflows/README.md`, `plugins/dev-workflows/docs/README.md`, `plugins/dev-workflows/references/cost-emission.md`, `plugins/dev-workflows/docs/reference/session-cost.md`

**Interfaces:**
- Consumes: `brd-addressing.md` (`brd-key-valid`, `resolve-brd`), `brd-format.md`, `coverage-ledger-format.md`, agent `dev-workflows:brd-reader`
- Produces: `brd/source/`, `brd/brd-inventory.md`, `brd/brd-defect-log.md`, `coverage-ledger.md` with every row `unallocated`

- [ ] **Step 1: Create the command**

Usage: `/brd-intake <BRD-KEY> @<brd-file> [--sort-existing <dir>]`

Phases, following the house structure (`## Phase 0 — Resolve inputs` onward):

- **Phase 0** — validate `<BRD-KEY>` with `brd-key-valid`; require `$SPECS_PATH`; run `specs-preflight` per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §3; resolve or derive the BRD folder via `resolve-brd`. **Reject a PDF** with: `BRD_INTAKE_NEEDS_MARKDOWN: the source must be markdown — convert it first, and check the conversion. It becomes the immutable record every [BR#n] anchors into.`
- **Phase 1** — confirm the folder, the source file, and whether `--sort-existing` is in play.
- **Phase 1.5** — invoke the `model-routing` skill and record the `model_routing` block; classification is typically `MODERATE`.
- **Phase 2** — copy the source verbatim into `brd/source/`; never edit it.
- **Phase 3** — dispatch `brd-reader` (subagent_type `dev-workflows:brd-reader`, model = the `detection_model` from the routing block) and write `brd/brd-inventory.md`.
- **Phase 4** — confirm each defect candidate interactively via `AskUserQuestion`, one class at a time; write `brd/brd-defect-log.md`.
- **Phase 5** — write `coverage-ledger.md` with one row per `[BR#n]`, all `unallocated`.
- **Phase 6** — `--sort-existing <dir>`: read an existing hand-written package and sort its sections by altitude into `prd-seed.md`, `ard-seed.md`, `spec-seed.md`. State that this is the migration path for work already done by hand and that it writes seeds only, never findings.
- **Terminal** — offer `handoff-to-main` per `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3; emit cost per `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md`; final report ends with the ledger line from `coverage-ledger-format.md` §6.

- [ ] **Step 2: Run the docs gate to verify it fails**

Expected: `FAIL check 4: command 'brd-intake' has no page at docs/commands/brd-intake.md`, plus check 9 on the commands count (tree has 22) and on the cost-emitting count (tree has 14).

- [ ] **Step 3: Add the docs page, the index row, the counts and the cost row**

- `docs/commands/brd-intake.md` — synopsis derived from the command's Phase 0 argument parsing, phases from its `## Phase` headings, gates from its dispatches. No table cell over 200 characters.
- `docs/README.md` — a row in the task table: `| turn a customer BRD into a grounded requirement inventory | [`/brd-intake`](commands/brd-intake.md) |`
- `plugins/dev-workflows/README.md` — `twenty-one slash commands` → `twenty-two slash commands`.
- `references/cost-emission.md` §7 — a row `| `/brd-intake` | brd-to-prd | pm |`. The phase label is shared by all three commands of this route, the way `/idea` and `/create-prd` share `prd-creation`; the roles are the valid vocabulary `pm | pe | pa | dev`.
- `docs/reference/session-cost.md` — `Thirteen commands emit a cost entry` → `Fourteen commands emit a cost entry`.

- [ ] **Step 4: Run the gate triple to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/brd-intake.md plugins/dev-workflows/docs/commands/brd-intake.md \
        plugins/dev-workflows/README.md plugins/dev-workflows/docs/README.md \
        plugins/dev-workflows/references/cost-emission.md plugins/dev-workflows/docs/reference/session-cost.md
git commit -m "feat(brd): add /brd-intake"
```

---

### Task 8: `agents/code-grounder.md`

**Files:**
- Create: `plugins/dev-workflows/agents/code-grounder.md`
- Modify: `plugins/dev-workflows/docs/reference/agents.md`

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md`, `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md`
- Produces: `[CG#n]` findings with `claim`, `verdict`, `evidence`, `commit`, `altitude`, `horizon`

- [ ] **Step 1: Create the agent**

```yaml
---
name: code-grounder
description: Grounds specific BRD claims against a single code repository at a pinned commit — one [CG#n] finding per claim, with file:line evidence and a verdict from the closed set. Answers "is this claim true of this commit?", not "what capability exists?" — that is code-scanner. Read-only; one instance per repo, up to 4 concurrent. Model tier assigned by the caller per the model-routing policy (no fixed pin).
tools: ["Read", "Glob", "Grep", "Bash"]
---
```

Body must: take `repo_path`, `commit`, and a list of claims (each a `[BR#n]` premise); refuse to run without all three; verify `git -C <repo_path> rev-parse HEAD` matches the supplied `commit` and return a failure status on mismatch rather than grounding against the wrong tree; emit one finding per claim; state the `NOT-PROVABLE` rule verbatim from the reference; and state the `FALSE-FRIEND` obligation — a name that misleads must be reported even when the claim is otherwise answered.

- [ ] **Step 2: Run the docs gate to verify it fails**

Expected: `FAIL check 4: agent 'code-grounder' is absent from reference/agents.md` and check 9 reporting tree has 35.

- [ ] **Step 3: Add the docs entry and the count** — `34 agents` → `35 agents`.

- [ ] **Step 4: Run the gate triple to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/code-grounder.md plugins/dev-workflows/docs/reference/agents.md
git commit -m "feat(brd): add the code-grounder agent"
```

---

### Task 9: `agents/design-grounder.md`

**Files:**
- Create: `plugins/dev-workflows/agents/design-grounder.md`
- Modify: `plugins/dev-workflows/docs/reference/agents.md`

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §6
- Produces: `[DG#n]` findings in the same record shape as `[CG#n]`

- [ ] **Step 1: Create the agent**

```yaml
---
name: design-grounder
description: Reconciles a BRD against an exported design frame set — one [DG#n] finding per divergence, in four classes: a frame shows a field the BRD never requires; the BRD requires a field no frame shows; a frame contradicts BRD text; a frame implies a capture the code cannot perform. Read-only. Model tier assigned by the caller per the model-routing policy (no fixed pin).
tools: ["Read", "Glob", "Grep"]
---
```

Body must: take a frame-set directory (images plus an index file) and the inventory; refuse to run when no index file is present, reporting that an unindexed frame dump cannot be reconciled; state that the fourth class is the one that requires code evidence, so a finding in that class **cites a `[CG#n]`** rather than asserting the code limitation itself.

- [ ] **Step 2: Run the docs gate to verify it fails** — expected: check 4 on `design-grounder`, check 9 reporting tree has 36.

- [ ] **Step 3: Add the docs entry and the count** — `35 agents` → `36 agents`.

- [ ] **Step 4: Run the gate triple to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/design-grounder.md plugins/dev-workflows/docs/reference/agents.md
git commit -m "feat(brd): add the design-grounder agent"
```

---

### Task 10: `agents/grounding-verifier.md`

**Files:**
- Create: `plugins/dev-workflows/agents/grounding-verifier.md`
- Modify: `plugins/dev-workflows/docs/reference/agents.md`

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §8
- Produces: per finding, one of `agree | extend | contradict | unprovable`, with its own independently derived evidence

- [ ] **Step 1: Create the agent**

```yaml
---
name: grounding-verifier
description: Independently re-derives a grounding finding from the repository and returns agree / extend / contradict / unprovable with its own evidence. It does NOT check citations — checking a citation only proves the cited line exists. A finding is not evidence until this agent has re-derived it. Read-only. Uses Claude Opus.
model: claude-opus-5
tools: ["Read", "Glob", "Grep", "Bash"]
---
```

Body must state, as its first instruction, that it is forbidden to reach its verdict by reading the finding's own `evidence` list first — it derives the answer from the claim and the repository, then compares. It must return `contradict` with evidence rather than softening to `extend` when the original is wrong, and must treat a finding inherited from another team's report as unverified regardless of how confident that report sounds.

- [ ] **Step 2: Run the docs gate to verify it fails** — expected: check 4 on `grounding-verifier`, check 9 reporting tree has 37.

- [ ] **Step 3: Add the docs entry and the count** — `36 agents` → `37 agents`.

- [ ] **Step 4: Run the gate triple to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/grounding-verifier.md plugins/dev-workflows/docs/reference/agents.md
git commit -m "feat(brd): add the grounding-verifier agent"
```

---

### Task 11: `commands/brd-ground.md`

**Files:**
- Create: `plugins/dev-workflows/commands/brd-ground.md`
- Create: `plugins/dev-workflows/docs/commands/brd-ground.md`
- Modify: `plugins/dev-workflows/README.md`, `plugins/dev-workflows/docs/README.md`, `plugins/dev-workflows/references/cost-emission.md`, `plugins/dev-workflows/docs/reference/session-cost.md`

**Interfaces:**
- Consumes: `brd-addressing.md`, `grounding-format.md`, `coverage-ledger-format.md`, agents `dev-workflows:code-grounder`, `dev-workflows:design-grounder`, `dev-workflows:grounding-verifier`
- Produces: `grounding/baselines.md`, `grounding/code-grounding.md`, `grounding/design-grounding.md`; a `brd-link.md` carrying `depends-on`

- [ ] **Step 1: Create the command**

Usage: `/brd-ground <BRD-KEY> [--depends-on <BRD-KEY>…] [--derivation-matrix|--no-derivation-matrix] [--no-design] [--rebaseline]`

Phases:

- **Phase 0** — resolve the BRD via `resolve-brd`; gate the intake artifacts on the specs default branch with `require-on-main` per `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3; require `$REPOS_PATH`; run `specs-preflight`.
- **Phase 1** — resolve repositories by matching `git -C <dir> remote get-url origin` against each repo slug, exactly as `/epics` Phase 4 does; never assume a `<base>/<slug>` directory name.
- **Phase 1.5** — `model-routing` skill; record the block. Classification floors at `SIGNIFICANT` when more than one repository is in scope, per the multi-source rule in the classification reference.
- **Phase 2 — baseline integrity gate.** Run `baseline-integrity` from `grounding-format.md` §4 per repository. On any non-empty content diff, **stop**: `BRD_GROUND_DIRTY_TREE: <repo> has content changes at <sha> — grounding it would cite an unidentifiable snapshot.` Write `grounding/baselines.md`.
- **Phase 3 — prerequisites.** Persist any `--depends-on` keys into `brd-link.md` (additive; the file may also be edited by hand). For each, read its frozen decisions and report readiness in the form given in spec §5.6.
- **Phase 4 — fan out.** Dispatch `code-grounder` once per repository, at most 4 concurrent, each with the claim list and the pinned commit. Then `design-grounder` over the frame set unless `--no-design`.
- **Phase 5 — horizons.** Assign each finding `current` or `will-change`; a `will-change` finding names the prerequisite decision that overturns it.
- **Phase 6 — verify.** Dispatch `grounding-verifier` over every finding, pinned to the Opus chain. A finding whose verdict is `contradict` is rewritten, and the rewrite retains the ID.
- **Phase 7** — write the findings; `--derivation-matrix` (default on for reporting and data-centric BRDs) adds the matrix as implementation-altitude rows.
- **Terminal** — `handoff-to-main`; cost; final report includes the prerequisite-readiness block and the ledger line.

`--rebaseline` re-runs against moved code and supersedes findings by ID rather than renumbering them, so citations in an already-sent package still resolve.

- [ ] **Step 2: Run the docs gate to verify it fails** — expected: check 4 on the missing `docs/commands/brd-ground.md`, check 9 on commands (tree has 23) and cost-emitting (tree has 15).

- [ ] **Step 3: Add the docs page, the index row, the counts and the cost row** — `twenty-two slash commands` → `twenty-three slash commands`; `Fourteen commands emit a cost entry` → `Fifteen commands emit a cost entry`; `cost-emission.md` §7 row `| `/brd-ground` | brd-to-prd | pa |`.

- [ ] **Step 4: Run the gate triple to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/brd-ground.md plugins/dev-workflows/docs/commands/brd-ground.md \
        plugins/dev-workflows/README.md plugins/dev-workflows/docs/README.md \
        plugins/dev-workflows/references/cost-emission.md plugins/dev-workflows/docs/reference/session-cost.md
git commit -m "feat(brd): add /brd-ground"
```

---

### Task 12: `commands/brd-split.md`

**Files:**
- Create: `plugins/dev-workflows/commands/brd-split.md`
- Create: `plugins/dev-workflows/docs/commands/brd-split.md`
- Modify: `plugins/dev-workflows/README.md`, `plugins/dev-workflows/docs/README.md`, `plugins/dev-workflows/references/cost-emission.md`, `plugins/dev-workflows/docs/reference/session-cost.md`

**Interfaces:**
- Consumes: `brd-addressing.md` §3, `coverage-ledger-format.md` §4
- Produces: `slices.md`; one nested child-BRD folder per confirmed slice, each with its own `brd-link.md`; a ledger with no `unallocated` row

- [ ] **Step 1: Create the command**

Usage: `/brd-split <BRD-KEY>`

Phases:

- **Phase 0** — resolve the BRD; gate on every finding carrying a verifier verdict, stopping with `BRD_SPLIT_UNVERIFIED: N findings have no verifier verdict — run /dev-workflows:brd-ground first.` if not.
- **Phase 1** — `model-routing`; record the block.
- **Phase 2 — propose.** Derive candidate slices from the grounded picture: what is buildable now, what is blocked, what depends on what. Present them; the operator confirms, edits, or replaces.
- **Phase 3 — key each slice.** Take a key per confirmed slice, validated with `brd-key-valid`, and create its folder **inside** this one per `brd-addressing.md` §3, each with a `brd-link.md` naming the parent and its claimed `[BR#n]` rows.
- **Phase 4 — walk the ledger.** For every `unallocated` row, present the four resolutions one row at a time via `AskUserQuestion`: assign to a named slice, defer to this BRD, reject citing a `[DEF#n]`, or mark superseded by another `[BR#n]`. The command cannot complete while any row remains `unallocated`.
- **Phase 5** — write `slices.md` with the rationale for each slice and for each deferral.
- **Terminal** — `handoff-to-main`; cost; the ledger line, which now shows zero unallocated.

State that re-running on a fully-allocated BRD is a no-op that prints the ledger.

- [ ] **Step 2: Run the docs gate to verify it fails** — expected: check 4 on the missing `docs/commands/brd-split.md`, check 9 on commands (tree has 24) and cost-emitting (tree has 16).

- [ ] **Step 3: Add the docs page, the index row, the counts and the cost row** — `twenty-three slash commands` → `twenty-four slash commands`; `Fifteen commands emit a cost entry` → `Sixteen commands emit a cost entry`; `cost-emission.md` §7 row `| `/brd-split` | brd-to-prd | pm |`.

- [ ] **Step 4: Run the gate triple to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/brd-split.md plugins/dev-workflows/docs/commands/brd-split.md \
        plugins/dev-workflows/README.md plugins/dev-workflows/docs/README.md \
        plugins/dev-workflows/references/cost-emission.md plugins/dev-workflows/docs/reference/session-cost.md
git commit -m "feat(brd): add /brd-split"
```

---

### Task 13: `docs/brd-workflow.md` — the route's own page

**Files:**
- Create: `plugins/dev-workflows/docs/brd-workflow.md`
- Modify: `plugins/dev-workflows/docs/README.md`, `plugins/dev-workflows/docs/workflow.md`, `plugins/dev-workflows/docs/roles-and-phases.md`

**Interfaces:**
- Consumes: the three command pages
- Produces: the page users navigate the procedure from

- [ ] **Step 1: Write the page**

It must carry, in this order:

1. A one-paragraph statement of what the route is for and how it differs from `/idea → /create-prd`.
2. The mermaid diagram from spec §13, trimmed to increment 1's commands with the later phases shown as greyed-out future steps and labelled as not yet implemented.
3. **The parameter table** — one row per command with required and optional arguments spelled out, because users navigate from the diagram and must not open three command pages to learn what an argument takes. Rows for `/brd-intake`, `/brd-ground` and `/brd-split` exactly as in spec §13. Keep every cell under 200 characters.
4. A short "what lands where" section pointing at the folder layout.

Identity quarantine applies: name no marketplace and no container repository.

- [ ] **Step 2: Run the docs gate to verify it fails**

Run: `./scripts/check-docs.sh --root .`
Expected: `FAIL check 2` — the new page is unreachable from `docs/README.md`.

- [ ] **Step 3: Link it and extend the two pipeline pages**

- `docs/README.md` — link `brd-workflow.md` alongside `workflow.md`.
- `docs/workflow.md` — add the second route into a PRD to the existing mermaid diagram and a sentence naming it, so both routes appear in one picture.
- `docs/roles-and-phases.md` — add the route: PM-owned, with `/brd-ground` PM-initiated and PA/Dev-executed.

- [ ] **Step 4: Run the gate triple to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/docs/brd-workflow.md plugins/dev-workflows/docs/README.md \
        plugins/dev-workflows/docs/workflow.md plugins/dev-workflows/docs/roles-and-phases.md
git commit -m "docs(brd): add the BRD route page, diagram and parameter table"
```

---

### Task 14: Catalog, changelog, and the verification record

Written last, per `CLAUDE.md`: a record written before the final fix wave goes stale, and one of the 2026-08-07 round's records was falsified by its own next commit seventeen minutes later.

**Files:**
- Modify: `.claude-plugin/marketplace.json`, `plugins/dev-workflows/.claude-plugin/plugin.json`, `plugins/dev-workflows/CHANGELOG.md`, `CLAUDE.md`

**Interfaces:**
- Consumes: the finished tree
- Produces: a catalog whose description is within budget and prose counts that match

- [ ] **Step 1: Re-derive every count against the tree**

```bash
cd plugins/dev-workflows
echo "commands: $(ls commands/*.md | wc -l)"   # expect 24
echo "agents:   $(ls agents/*.md | wc -l)"      # expect 37
echo "refs:     $(find references -type f | wc -l)"  # expect 102
```

Do not trust these numbers from this plan — re-measure. If they differ, the tree is right and the plan is wrong; fix the prose to match the tree.

- [ ] **Step 2: Update the descriptions, replacing rather than appending**

In both `.claude-plugin/marketplace.json` and `plugins/dev-workflows/.claude-plugin/plugin.json`, update the `description`: change the command count and name the BRD route. **A description is a stable capability blurb, never a changelog** — the new capability replaces wording, it never appends. Hard budget 1024 characters; `validate-catalog.py` warns above 900 and fails above 1024, and Copilot CLI rejects the **whole catalog** on overflow, so one long blurb breaks every plugin here.

- [ ] **Step 3: Verify the catalog before writing anything else**

Run: `python3 scripts/validate-catalog.py`
Expected: PASS, with no length warning. If it warns above 900, cut wording now rather than later.

- [ ] **Step 4: Write the changelog entry and update `CLAUDE.md`**

`CHANGELOG.md` — a new version entry naming the three commands, four agents, four references, and the docs page. `CLAUDE.md` — update the command count and the agent count in the "Active plugin" paragraph, and add `/brd-intake`, `/brd-ground`, `/brd-split` to the command list and to the model-routing "must load" list.

- [ ] **Step 5: Run the gate triple one final time and commit**

```bash
python3 scripts/validate-catalog.py \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && ./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root .
git add .claude-plugin/marketplace.json plugins/dev-workflows/.claude-plugin/plugin.json \
        plugins/dev-workflows/CHANGELOG.md CLAUDE.md
git commit -m "chore(brd): catalog, changelog and instruction-file counts for increment 1"
```

---

## What increment 1 deliberately does not do

- No `/brd-interview`, `/brd-package` or `/brd-reconcile` — increment 2.
- No `--from-brd` on `/create-prd`, `/create-ard` or `/specify`, and **no** one-level-deep resolution fallback in the six existing commands — increment 3. `brd-addressing.md` §4 defines the rule and marks it unadopted.
- No decision register, no self-review, no customer bundle. `/brd-split` is the end of the line here.

A BRD that has been through these three commands has a requirement inventory, a defect log, verified findings against pinned commits, and a ledger accounting for every requirement. That is useful on its own, which is the test that this split is real.
