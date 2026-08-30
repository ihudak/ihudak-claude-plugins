# BRD → PRD Workflow, Increment 2 (Decisions and the Customer Loop) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `/brd-interview`, `/brd-package` and `/brd-reconcile`, so a grounded BRD becomes a decided one, is packaged for a customer who has no plugin installed, and has their answers ingested and propagated.

**Architecture:** Three commands orchestrate two new agents against four new references. `/brd-interview` sorts open questions by who may answer them and records decisions with argumentation. `/brd-package` runs an adversarial self-review, then renders a self-contained bundle. `/brd-reconcile` ingests the returned review, freezes customer decisions, and sweeps every dependent BRD.

**Tech Stack:** Markdown command/agent/reference files under `plugins/dev-workflows/`. No application code. Verification is by three repository gate scripts, each with a `--selftest` that mutates a fixture tree and asserts which check fired.

**Spec:** `docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` — §6 (interview and register), §8 (customer loop), and decision rows D9–D15, D19–D21, D23.

## Global Constraints

Every one of these was learned the expensive way in increment 1.

- **No real customer, vendor, product or partner name anywhere.** Roles are `customer` and `delivery team`. Example keys must satisfy `^[A-Z][A-Z0-9_]*(-\d+)+$` — increment 1 shipped an example its own grammar rejected, inside the message that taught the grammar.
- **Bracketed `[PREFIX#N]` identifiers only** — `[BR#n]`, `[DEF#n]`, `[CG#n]`, `[DG#n]`, `[VD#n]`, `[CD#n]`, `[AS#n]`, `[SR#n]`. `scripts/check-id-grammar.sh` gates `plugins/`.
- **Single owner: cite, do not restate.** Increment 1 corrected eight violations of this. Names may appear as output enums; definitions may not be copied.
- **Every new command, agent and reference lands with its documentation entry in the same commit**, or `scripts/check-docs.sh` fails the build.
- **Re-derive every count from the tree; never copy one** from this plan, a brief, or a report. `CLAUDE.md` records two wrong numbers propagating exactly that way.
- **A pinned agent uses the house alias** (`model: opus` / `model: sonnet`); an agent with no fixed pin omits the key and says so in its `description`.
- **Write internal cross-references by phase *name*, not bare number.** One increment-1 command needed twelve corrections after its phases were renumbered.
- **Verify every cross-file citation against the target file's actual headings**, with a whitespace-tolerant search — a stale reference survived one sweep by wrapping across a line break.
- **These three commands take no `--no-docs` and do no docs-grounding.** That is a decision, not an omission: `/brd-intake` and `/brd-ground` already grounded the BRD against shipped documentation, and these three operate on decisions and packaging, which documentation does not inform. Increment 1's docs-grounding gap existed because nobody wrote this sentence.
- **Escalation arrays are sourced from `references/escalation-rules.md`**, which now carries `/brd-*` rules. Do not inline new ones.
- **A `covered-by` row counts as covered only if the child covers it** (D23). `/brd-reconcile` updates the ledger and must respect the roll-up.
- No table cell under `plugins/dev-workflows/docs/` may exceed 200 characters. No page under `docs/` may name a marketplace or container repository.
- Reports quote the file **as committed**, never as intended.

**The gate triple** — run after every task, from the repository root:

```bash
python3 scripts/validate-catalog.py \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && ./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root .
```

**Baseline at plan time:** 24 commands, 37 agents, 102 reference files, 16 cost-emitting. Increment 2 ends at 27 / 39 / 106 / 19. **Re-measure before trusting those.**

---

## File Structure

| File | Responsibility |
|---|---|
| `references/interview-tagging.md` | The `[G]`/`[V]`/`[C]` rule, re-tagging, and what makes a question untaggable |
| `references/decision-register-format.md` | `[VD#n]`/`[CD#n]`/`[AS#n]` shape, statuses, reopening, `conditional_on` |
| `references/customer-review-schema.md` | The schema the customer's reviewer fills, rendered inline into the prompt |
| `references/bundle-packaging.md` | De-Obsidianising, degradation tiers, plugin-free rendering, the delivery note's length rule |
| `agents/brd-package-reviewer.md` | Adversarial self-review → `[SR#n]` (Opus, pinned) |
| `agents/customer-review-reader.md` | Parse schema mode / normalise free text (no fixed pin) |
| `commands/brd-interview.md` | Tagged rounds → decision register |
| `commands/brd-package.md` | Self-review → prompt, bundle, delivery note |
| `commands/brd-reconcile.md` | Ingest → freeze → correct → propagate → sweep |
| `docs/commands/brd-{interview,package,reconcile}.md` | Per-command human docs |

**Modified:** `scripts/check-docs.sh`, `docs/brd-workflow.md`, `docs/README.md`, `docs/roles-and-phases.md`, `docs/reference/{agents,references,session-cost,environment}.md`, `references/cost-emission.md`, `references/escalation-rules.md`, `plugins/dev-workflows/README.md`, `CHANGELOG.md`, both `.claude-plugin` manifests, `CLAUDE.md`.

---

### Task 1: Teach the prose-count gate the number words this increment needs

`_word2num` in `scripts/check-docs.sh` knows `one`–`sixteen`, `twenty-one`–`twenty-four`, `thirty-four`, `ninety-eight`. This increment needs `seventeen`, `eighteen`, `nineteen` (cost-emitting 16→19) and `twenty-five`, `twenty-six`, `twenty-seven` (commands 24→27). An unknown word falls through and is string-compared against a number.

**Files:** Modify `scripts/check-docs.sh` — `_word2num`, the commands alternation, the cost-emitting alternation, and the selftest block.

**Interfaces:** Produces — `_word2num` maps all six new words; both alternations match them.

- [ ] **Step 1: Read the fixture before writing anything.** `selftest()` mutates a copy of `scripts/fixtures/docs/pass/`, whose README says "A fixture plugin of one slash commands" and whose tree holds one command. A mutation written against the real repository's wording matches nothing and silently no-ops.

- [ ] **Step 2: Add a discriminating selftest case.** It must be red before the converter change and green after. Verify by stashing the change, not by reasoning about it.

- [ ] **Step 3: Run the selftest to confirm the new case is red**

Run: `./scripts/check-docs.sh --selftest`

- [ ] **Step 4: Extend the converter and both alternations**

```bash
    seventeen) echo 17 ;; eighteen) echo 18 ;; nineteen) echo 19 ;;
    twenty-five) echo 25 ;; twenty-six) echo 26 ;; twenty-seven) echo 27 ;;
```

Add the same six words to the `_one "commands"` and `_one "cost-emitting commands"` alternations. Leave the other five alone unless Task 0's defect fix already anchored them — check, do not assume.

- [ ] **Step 5: Run the selftest, then the gate triple, and commit**

```bash
git add scripts/check-docs.sh
git commit -m "test(gates): teach the prose-count converter increment 2's number words"
```

---

### Task 2: `references/interview-tagging.md`

**Files:** Create `plugins/dev-workflows/references/interview-tagging.md`; modify `docs/reference/references.md`.

**Interfaces:** Produces the three tags and the re-tagging rule, consumed by `/brd-interview` (Task 8) and by `/brd-package` (Task 9, which routes `[C]` questions into the prompt).

- [ ] **Step 1: Write the reference.** Required sections:
  - `## 1. The three tags` — `[G]` answerable from grounding, `[V]` a delivery-side design decision, `[C]` a genuine business decision, each with **who may answer**. State D8 and D9 as rules, not observations: a `[G]` is **never** asked of a human, and a `[V]` is **never** routed to the customer as if it were a business choice.
  - `## 2. Why the rule exists` — a `[G]` put to a person returns their belief about the system rather than the system, and that belief then becomes a requirement. A `[V]` dressed as a `[C]` extracts authority the customer never meant to give and cannot defend later.
  - `## 3. Re-tagging` — a `[G]` that grounding cannot settle becomes a `NOT-PROVABLE` finding and is re-tagged, usually to `[V]`. It does not become a question by default.
  - `## 4. Untaggable questions` — a question carrying more than one tag is a defect in the question; it is split until each part carries exactly one.
  - `## 5. Rounds` — resumable; a round closes only when every question in it has a disposition; the register records which round produced each decision.

  Cite `grounding-format.md` for `NOT-PROVABLE`; do not restate it.

- [ ] **Step 2: Run the docs gate; capture the red output** — expect check 4 (absent from `reference/references.md`) and check 9 (count).

- [ ] **Step 3: Add the docs entry and update the count.** `references.md` opens with an arithmetic reconciliation — total, top-level count, "N of the M" named individually, and the accounted-for sum. Update **every** figure, re-derived from the tree.

- [ ] **Step 4: Run the gate triple; expect green**

- [ ] **Step 5: Commit** — `feat(brd): add the interview-tagging reference`

---

### Task 3: `references/decision-register-format.md`

**Files:** Create the reference; modify `docs/reference/references.md`.

**Interfaces:** Produces the `[VD#n]`/`[CD#n]`/`[AS#n]` record and its statuses — consumed by `/brd-interview`, `/brd-package`, `/brd-reconcile`, and by increment 3's `--from-brd`.

- [ ] **Step 1: Write the reference.** Required sections:
  - `## 1. Record shape` — the YAML block from spec §6.2 verbatim in structure: `id`, `statement`, `options_considered`, `chosen`, `argumentation`, `evidence`, `altitude`, `conditional_on`, `status`, `consumed_by`, `round`.
  - `## 2. Argumentation is mandatory` — a decision without a recorded reason cannot be defended weeks later and cannot be safely reopened.
  - `## 3. Statuses` — `open | decided | reopened | superseded | withdrawn`. `withdrawn` is first-class so a request the customer's answer made unnecessary stops being asked for in customer-facing text.
  - `## 4. Reopening is explicit` — only a new finding or an incoming customer decision may reopen a decision, and the reopening records its cause.
  - `## 5. `conditional_on`` — what it means, and that it is what makes `/brd-reconcile`'s propagation sweep able to find a position built on a prerequisite.
  - `## 6. The will-change rule (D19)` — a decision may not rest solely on a `horizon: will-change` finding; the three resolutions from spec §6.2.
  - `## 7. Assumptions` — `[AS#n]`, and the rule that every open one is surfaced in the customer prompt. An assumption that never reaches the customer is a liability disguised as a fact.

- [ ] **Step 2: Run the docs gate; capture the red output**
- [ ] **Step 3: Add the docs entry; update the whole arithmetic paragraph, re-derived**
- [ ] **Step 4: Run the gate triple; expect green**
- [ ] **Step 5: Commit** — `feat(brd): add the decision-register reference`

---

### Task 4: `references/customer-review-schema.md`

This one is unusual: its content is rendered **into** the customer's prompt verbatim, for a reader with no plugin installed.

**Files:** Create the reference; modify `docs/reference/references.md`.

**Interfaces:** Produces the schema `/brd-package` inlines and `customer-review-reader` parses.

- [ ] **Step 1: Write the reference.** It defines the sections the customer's reviewer must produce, at minimum: review identity and **evidence limitations**; executive verdict; approved and deferred scope; requirement traceability; code-grounding confirmations *and challenges*; design review; the decision log; accepted assumptions and rejected alternatives; ownership; unresolved blockers; a readiness statement; and required changes to downstream documents.

  Two rules the schema itself must carry:
  - **Evidence limitations come first**, not last. A review of an unidentified snapshot must say so before any claim rests on it.
  - **The output is exactly one new file; nothing in the package is modified** (D13). State it as a rule of the schema, so it survives being inlined.

  Also state that this file is **rendered into the prompt**, so it must contain no `${CLAUDE_PLUGIN_ROOT}` path, no slash command, and no instruction a plugin-less agent cannot follow.

- [ ] **Step 2: Run the docs gate; capture the red output**
- [ ] **Step 3: Add the docs entry; update the arithmetic, re-derived**
- [ ] **Step 4: Run the gate triple; expect green**
- [ ] **Step 5: Commit** — `feat(brd): add the customer-review schema`

---

### Task 5: `references/bundle-packaging.md`

**Files:** Create the reference; modify `docs/reference/references.md`.

**Interfaces:** Produces the bundle contract consumed by `/brd-package`.

- [ ] **Step 1: Write the reference.** Required sections:
  - `## 1. Plugin-free by construction (D12)` — the four rules from spec §8.1, including that documents are located by **filename search, not path**, because paths drift the moment a bundle is extracted.
  - `## 2. De-Obsidianising` — wikilinks rewritten to plain filename references; callouts kept because they degrade to blockquotes anywhere; the bundle is plain markdown plus images and nothing else.
  - `## 3. Degradation tiers` — the three tiers from spec §8.3 and what each obliges the reviewer to state.
  - `## 4. The delivery note` — a hard length rule; what is attached, which file is the prompt, which file comes back, and anything that must not sit buried in a document. Not a per-file table.
  - `## 5. Where the bundle lands` — `bundle-<YYYYMMDD>/` inside the BRD folder, committed (D18), so a git-capable customer pulls it and everyone else gets one archive command.

- [ ] **Step 2: Run the docs gate; capture the red output**
- [ ] **Step 3: Add the docs entry; update the arithmetic, re-derived**
- [ ] **Step 4: Run the gate triple; expect green**
- [ ] **Step 5: Commit** — `feat(brd): add the bundle-packaging reference`

---

### Task 6: `agents/brd-package-reviewer.md`

**Files:** Create the agent; modify `docs/reference/agents.md`.

**Interfaces:** Produces `[SR#n]` findings consumed by `/brd-package`'s disposition gate.

- [ ] **Step 1: Write the agent.** Frontmatter pinned to the house alias:

```yaml
---
name: brd-package-reviewer
description: Adversarially reviews a BRD package before it goes to the customer — attacks the position rather than summarising it, and returns [SR#n] findings each requiring a disposition. Read-only. Uses Claude Opus.
model: opus
tools: ["Read", "Glob", "Grep"]
---
```

  The body's first instruction is that it **attacks the package, not summarises it**. It must be told what it is looking for: a decision resting on a finding that does not support it; a `[C]` question that is really a `[V]`; an assumption presented as a fact; a claim the grounding does not carry; a position that will not survive the customer's own review. Cite `decision-register-format.md` and `interview-tagging.md`; do not restate them.

- [ ] **Step 2: Run the docs gate; capture the red output** — expect check 4 and check 9 on agents.
- [ ] **Step 3: Add the docs entry; re-derive the agent count from the tree**
- [ ] **Step 4: Run the gate triple; expect green**
- [ ] **Step 5: Commit** — `feat(brd): add the brd-package-reviewer agent`

---

### Task 7: `agents/customer-review-reader.md`

**Files:** Create the agent; modify `docs/reference/agents.md`.

**Interfaces:** Produces a schema-shaped digest consumed by `/brd-reconcile`.

- [ ] **Step 1: Write the agent.** No fixed model pin — omit the `model:` key and say the tier is caller-assigned, as `code-scanner` does. Two modes:
  - **Schema mode** — the returned file matches `customer-review-schema.md`; parse it directly.
  - **Free-text mode** — draft the same schema from prose.

  **The rule that matters most:** in free-text mode every inferred decision is emitted as a **candidate**, explicitly unconfirmed. This agent never promotes an inference to a customer decision — that is the orchestrator's, done with a human (D14). Write it so it cannot be skimmed past. Normalising prose into a register is inference; promoting inference to customer authority silently is the one way this workflow could manufacture a mandate the customer never gave.

- [ ] **Step 2: Run the docs gate; capture the red output**
- [ ] **Step 3: Add the docs entry; re-derive the agent count**
- [ ] **Step 4: Run the gate triple; expect green**
- [ ] **Step 5: Commit** — `feat(brd): add the customer-review-reader agent`

---

### Task 8: `commands/brd-interview.md`

**Files:** Create the command and `docs/commands/brd-interview.md`; modify `plugins/dev-workflows/README.md`, `docs/README.md`, `references/cost-emission.md`, `docs/reference/session-cost.md`.

**Interfaces:** Consumes `interview-tagging.md`, `decision-register-format.md`, `grounding-format.md`, `brd-addressing.md`. Produces `decisions.md` and the `[C]` question set Task 9 packages.

- [ ] **Step 1: Write the command.** Usage: `/brd-interview <BRD-KEY> [--round N]`

  Phases, following `/brd-ground`'s structure: resolve and gate the grounding artifacts on the default branch with `require-on-main`; `model-routing`; generate the question set; **tag every question before asking it**; answer every `[G]` from the findings without asking; put `[V]` to the operator one round at a time via `AskUserQuestion`, recording argumentation for each; hold `[C]` for the customer; enforce the will-change rule; write the register; terminal `handoff-to-main` with `prefix: brd`, cost, and the ledger line.

  **`--round N`:** with no flag, continue at the first round holding undisposed questions, and propose a new round only when findings or decisions have changed since the last. `--round N` resumes an open round or re-opens a closed one, recorded as a re-open with its cause.

- [ ] **Step 2: Run the docs gate; capture the red output** — expect check 4 (missing page), check 8 (cost row), check 9 (both counts).
- [ ] **Step 3: Add the docs page, index row, both counts and the cost row.** Cost §7 row: `| `/brd-interview` | brd-to-prd | pm |`. Re-derive both counts.
- [ ] **Step 4: Run the gate triple; expect green**
- [ ] **Step 5: Commit** — `feat(brd): add /brd-interview`

---

### Task 9: `commands/brd-package.md`

**Files:** Create the command and its docs page; modify the same four side-files.

**Interfaces:** Consumes `bundle-packaging.md`, `customer-review-schema.md`, `decision-register-format.md`, agent `dev-workflows:brd-package-reviewer`. Produces the self-review, the prompt, the delivery note, and `bundle-<date>/`.

- [ ] **Step 1: Write the command.** Usage: `/brd-package <BRD-KEY> [--depends-on <BRD-KEY>…]`

  Phases: resolve and gate; `model-routing`; dispatch `brd-package-reviewer`; **the disposition gate** — no bundle is built while any `[SR#n]` is undisposed; render the prompt in spec §8.2's fixed eleven-part order with the schema **inlined from the reference at build time**; render the delivery note under its length rule; assemble the de-Obsidianised bundle including any dependency packages marked *not for re-review*; emit the repo→SHA table; terminal handoff, cost, ledger line.

  Two things the prompt must carry that are easy to lose: every open `[AS#n]` and every `accepted-risk` `[SR#n]` under "where to attack us hardest", and every prerequisite whose decisions are not yet customer-reviewed under "what could still move" (D20).

- [ ] **Step 2: Run the docs gate; capture the red output**
- [ ] **Step 3: Add the docs page, index row, both counts, cost row** — `| `/brd-package` | brd-to-prd | pm |`. Re-derive.
- [ ] **Step 4: Run the gate triple; expect green**
- [ ] **Step 5: Commit** — `feat(brd): add /brd-package`

---

### Task 10: `commands/brd-reconcile.md`

**Files:** Create the command and its docs page; modify the same four side-files.

**Interfaces:** Consumes `customer-review-schema.md`, `decision-register-format.md`, `coverage-ledger-format.md`, agent `dev-workflows:customer-review-reader`.

- [ ] **Step 1: Write the command.** Usage: `/brd-reconcile <BRD-KEY> @<review-file>`

  Phases: accept the returned file from anywhere, copy it into the BRD folder under the canonical name, commit it, and only then ingest; choose schema or free-text mode; **in free-text mode every inferred decision is confirmed by the operator before it becomes a `[CD#n]`** (D14); freeze customer decisions; apply required corrections; **banner superseded dated snapshots rather than rewriting them** (D10); add `resolution:` rows to the defect log; update the coverage ledger **respecting D23's roll-up**; then the two sweeps.

  **Propagation** — every dependent BRD swept for decisions and findings citing a changed ID, each forced to `inherited-unchanged | reverted | reopened | withdrawn`, with `conditional_on` decisions the first target.

  **Stale cross-reference sweep** — every artifact under the parent searched for the changed IDs *and* for prose asserting a now-superseded position. Updating a register while a value document still states the old position is the characteristic failure of this step.

  Output: `reconciliation-<YYYYMMDD>.md` — what changed, why, which IDs, and what still needs a human.

- [ ] **Step 2: Run the docs gate; capture the red output**
- [ ] **Step 3: Add the docs page, index row, both counts, cost row** — `| `/brd-reconcile` | brd-to-prd | pm |`. Re-derive.
- [ ] **Step 4: Run the gate triple; expect green**
- [ ] **Step 5: Commit** — `feat(brd): add /brd-reconcile`

---

### Task 11: Route wiring and documentation — six commands

**Wire the route first, then document it.** Increment 1's commands were written when their successors did not exist, so they still say so: `/brd-ground`'s terminal phase and `/brd-split`'s Phase 7 both describe `/brd-split` as the route's last command, and **neither of their choice arrays offers `/brd-interview`**. That is a live dead-end, not stale prose — a user finishing a split is never shown the next step. Increment 1 shipped the mirror-image defect (commands telling users a successor had not shipped when it had), so this is a known failure mode of building a route in increments.

Do this **after** all three new commands exist, in one pass, so no command is left pointing at a half-built route: every terminal next-step offer names its real successor, and no command claims to be the route's end unless it is. Check `/brd-intake` and the three new commands too, not only the two named.

**Three more sites found during tasks 8 and 9, all the same class:**
- `docs/brd-workflow.md` still says `/brd-interview` **and** `/brd-package` "do not exist yet", and its diagram and prose describe a three-command route.
- `docs/commands/brd-intake.md` and `docs/commands/brd-ground.md` both say the cost phase is "shared by all three commands of the BRD-to-PRD route (`/brd-intake`, `/brd-ground`, `/brd-split`) … All three ship together". False since `/brd-interview`, doubly so now. Fix count-free — `docs/commands/brd-package.md` already models the right wording ("every command of the BRD-to-PRD route").
- `commands/brd-interview.md`'s terminal phase says `/brd-package` "is offered — but only where this round left something for a package to carry", yet its `choices:` array is unconditional. An operator on a *deferred*, *needs grounding* or *untagged* round is offered a run `/brd-package` will refuse. Either gate the option or drop the "only where" clause.

**Files:** Modify `docs/brd-workflow.md`, `docs/README.md`, `docs/workflow.md`, `docs/roles-and-phases.md`.

- [ ] **Step 1: Update the route page.** The diagram gains the three new commands and the external wait state between `/brd-package` and `/brd-reconcile` — that wait is the route's defining feature and must be visible. The **parameter table** gains three rows, each derived from the command's own argument parsing. Keep every cell under 200 characters. Only `--from-brd` and `/create-prd` remain unshipped; mark them as such.
- [ ] **Step 2: Update `roles-and-phases.md`** — the three commands into the PM section and the `brd-to-prd` cost-phase list. **If the phase count changes, change it in the same commit as the section it counts** — increment 1 split those and shipped a tree claiming eleven phases above ten subsections.
- [ ] **Step 3: Run the gate triple; expect green**
- [ ] **Step 4: Commit** — `docs(brd): extend the route page to the full customer loop`

---

### Task 12: Catalog, changelog, instruction files, and the end-to-end walk

Written last, per `CLAUDE.md`: a verification record written before the final fix wave goes stale.

**Files:** Modify `.claude-plugin/marketplace.json`, `plugins/dev-workflows/.claude-plugin/plugin.json`, `plugins/dev-workflows/CHANGELOG.md`, `CLAUDE.md`.

- [ ] **Step 1: Re-derive every count against the tree**

```bash
cd plugins/dev-workflows
ls commands/*.md | wc -l ; ls agents/*.md | wc -l ; find references -type f | wc -l
```

Trust the tree over any number in this plan.

- [ ] **Step 2: Update both descriptions, replacing wording rather than appending.** Hard budget 1024 characters; `validate-catalog.py` warns above 900 and Copilot CLI rejects the **entire catalog** on overflow. Verify immediately, before anything else is written.

- [ ] **Step 3: Walk the route end to end and record it.** `/brd-intake` → `/brd-ground` → `/brd-split` → `/brd-interview` → `/brd-package` → *(external wait)* → `/brd-reconcile`, at both parent and slice level. **Name any state a user can enter and not leave.** Increment 1 shipped three such states and found all three only in review — the allocation deadlock, the dead-ended child loop, and the unverifiable design findings. Each task was individually correct; only the walk found them. Record the walk in the report whether or not it finds anything.

- [ ] **Step 4: Changelog, `CLAUDE.md` counts and command lists, and the model-routing "must load" list**

  **Identity quarantine — two violations, user-confirmed as in scope.** `docs/commands/guideline-reviewer.md:59` and `docs/commands/api-guideline-reviewer.md:64` both link `prose-style` by full container URL (`https://github.com/ihudak/ihudak-claude-plugins/tree/main/plugins/prose-style`). `CLAUDE.md`'s rule: no page under `docs/` may name a marketplace or container repo, `getting-started.md` excepted. The binding reason is **forks** — a hardcoded container URL is wrong in anyone's fork of this plugin. Keep the reference to the sibling plugin; drop the container from it. Note that **no gate enforces this rule**, which is why both survived; say so in the report.

  **Carried from task 1 — an untested alternation.** Only `seventeen` and the commands alternation are exercised end-to-end by a selftest case; the `cost-emitting commands` alternation and the other five words were verified by inspection alone. Add a second fixture-growing case covering the cost-emitting alternation, verified red-before/green-after by stashing, so both gated alternations have real coverage.

  **Carried from task 11 — two more.** `references/next-phase-offer.md`'s routing graph contains **no `/brd-*` command at all**, so the reference that owns next-phase routing does not know this six-command route exists. And `/brd-interview`'s gated `/brd-package` offer duplicates a precondition `brd-package.md` owns, which can drift — replace the duplicate with a citation, or say why the duplication is load-bearing.

  **Carried from task 10 — a pre-existing falsification.** `references/cost-emission.md`'s preamble describes its emitters as "the eleven PRD-lifecycle ones … plus two", which already omitted every `/brd-*` emitter before this increment began. It was not falsified *by* any one command, which is why no task owned it. Re-derive it count-free against the tree.

- [ ] **Step 5: Run the gate triple one final time and commit** — `chore(brd): catalog, changelog and instruction-file counts for increment 2`

---

## What increment 2 deliberately does not do

- No `--from-brd` on `/create-prd`, `/create-ard` or `/specify`, and no one-level-deep resolution fallback in the six commands that resolve a PRD dir — increment 3.
- No PRD is written. The route ends with a reconciled, decided BRD whose seeds are ready.

A BRD that has been through all six commands has verified findings, a decision register with customer sign-off, a package the customer actually reviewed, and every dependent BRD swept. That is useful on its own, which is the test that this split is real.
