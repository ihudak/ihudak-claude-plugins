# BRD → PRD Workflow, Increment 3 (Handoff) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect the BRD route to the existing pipeline — `--from-brd` on `/create-prd`, `/create-ard` and `/specify`, and the one-level-deep PRD-dir resolution six commands need to see a nested BRD at all.

**Architecture:** No new command, agent or reference. Three existing commands gain a switch that reads an altitude-sorted seed; six gain a resolution fallback already defined in `references/brd-addressing.md` §4 and marked there as not yet adopted. After this, a reconciled BRD becomes a real PRD through `/create-prd`'s own `prd-reviewer` gate, and that PRD feeds `/create-ard → /epics → /specify → /design` exactly as the `/idea` route does.

**Tech Stack:** Markdown command and reference files under `plugins/dev-workflows/`. Verification is by three repository gate scripts, each with a `--selftest`.

**Spec:** `docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` — §4.3 (addressing), §7 (altitude routing), §10 (modified commands), and decision rows D2, D3, D4, D5.

## Global Constraints

Every one was learned in increments 1 and 2.

- **No new commands, agents or references** — so the prose counts should not move. **Verify that rather than assuming it**, and re-derive anything you touch. Two wrong numbers propagated in this repo by being copied.
- **`--from-brd` is a switch, not a path.** The positional key identifies the BRD and §4.3 resolves it. A path is accepted for a folder outside the normal layout, never required.
- **The one-level-deep fallback is additive.** A flat key must resolve exactly as it does today. This is the design's only change to behaviour outside the BRD family, and six commands share it — a regression here reaches `/epics`, `/design` and `/ready`, which have nothing to do with BRDs.
- **Decisions are frozen.** `/create-prd --from-brd`'s grill may fill what the seed does not settle and may **not** reopen a `[VD#n]` or `[CD#n]` (D3). A customer signed those.
- **`prd-format.md`'s no-implementation-detail rule is not relaxed** (D4). Sub-product-altitude content goes to the ARD and specification seeds; that is what §7's altitude router exists for.
- **Bracketed `[PREFIX#N]` identifiers only.** `check-id-grammar.sh` gates `plugins/`.
- **Cite, do not restate.** Increments 1 and 2 corrected ten violations of this between them.
- **Cross-references by phase *name*.** Verify any number with a whitespace-tolerant search, and **search by phrase, not line number** — three rounds running, a repeat of a just-corrected phrase survived within a few lines of its fix.
- **Offers must not name what does not exist in the state they report.** Eleven defects of that anatomy shipped across two increments, and five more were found in the commands this increment edits. **Check 11 stayed family-scoped to `/brd-*`, refused on measurement** — so `/create-prd`, `/create-ard`, `/specify`, `/design` and `/update-prd` are **NOT** gated. Their offers were converted by hand in the branch immediately before this one.
- **Do not undo that conversion.** All five of those files now carry `<merge-clause>` placeholders resolved from the run's own `phase-handoff.md` §4.1 outcome. `/create-prd`, `/create-ard` and `/specify` are the three you are about to amend. **Before editing any of them, grep for `<merge-clause>` and note where it sits; after editing, grep again and confirm the same sites survive.** Nothing in this increment should touch them, and the gate will not tell you if you do.
- **Applying a rule mechanically can produce a false statement.** Two claims in these same files were false on reachable `§4.1` rows and had to be corrected rather than preserved. If you add or reword an offer, check it against every row, not the common one.
- **The enumeration method for next-step surfaces is `grep -rinE '^[ \t]*#{2,4} .*next'` — unanchored.** The `^`-anchored form misses headings indented inside fenced report templates and made four passes short. Spec §13A records this.
- No table cell under `plugins/dev-workflows/docs/` over 200 characters. Identity quarantine applies under `docs/` and is now gated by check 10.
- Gate triple after every task.

**Baseline:** 27 commands, 39 agents, 106 reference files, 19 cost emitters. **Re-measure before trusting these.**

---

### Task 1: The one-level-deep resolution fallback, in six commands

`references/brd-addressing.md` §4 already defines the rule and marks it **not yet adopted**. This task adopts it and flips that marking.

**Files:** Modify `commands/{create-prd,create-ard,epics,specify,design,ready}.md`; `references/brd-addressing.md`.

**Interfaces:** Produces — all six resolve `specifications/<PARENT>-<slug>/<CHILD>-<slug>/` when the flat match fails.

- [ ] **Step 1: Read `brd-addressing.md` §4 and one existing resolver** (`/create-ard`'s Phase 0 is the shortest) before editing anything.
- [ ] **Step 2: Apply the same fallback to each of the six**, citing §4 rather than restating it. A flat key must behave exactly as before — the fallback runs only when the flat match returns absent.
- [ ] **Step 3: Flip §4's not-yet-adopted marking** and name the six adopters.
- [ ] **Step 4: Prove the additive claim.** For each of the six, state what a flat key does before and after. A reviewer will ask; answer it in the report.
- [ ] **Step 5: Gate triple, then commit** — `feat(brd): resolve a nested BRD folder in the six commands that consume a PRD dir`

---

### Task 2: `/create-prd --from-brd`

The one that carries the most risk: it refuses a fully-sliced BRD, freezes customer decisions against re-litigation, and writes the frontmatter `/epics` and `/ready` later read.

**Files:** Modify `commands/create-prd.md`, `docs/commands/create-prd.md`.

- [ ] **Step 1: Read the seed contract** — `references/coverage-ledger-format.md` §5 (PRD eligibility), `references/decision-register-format.md`, and §7's altitude routing. The seed is `prd-seed.md`; `ard-seed.md` and `spec-seed.md` are **not** this command's.
- [ ] **Step 2: Add the switch** per spec §10: reads `prd-seed.md` and `decisions.md` from the resolved BRD folder; grill restricted to gaps; may **not** reopen a `[VD#n]` or `[CD#n]`; profile defaults to `--full`; writes `brd_key:`, `brd_parent:` and `depends_on:` into the PRD frontmatter.
- [ ] **Step 3: The two refusals.** Refuse if any ledger row this BRD claims is `unallocated`. Refuse when the ledger shows no `covered-here` row — and say **where the requirements went** per `coverage-ledger-format.md` §5, which is *not always a list of children*: a BRD never split and a slice that deferred everything both reach that state with nothing to name.
- [ ] **Step 4: Check the offers.** Whatever this command offers next must not name something that cannot exist in the state it reports.
- [ ] **Step 5: Update the docs page from the command**, gate triple, commit — `feat(brd): /create-prd --from-brd`

---

### Task 3: `/create-ard --from-brd` and `/specify --from-brd`

Batched: three variations on one contract, and neither carries Task 2's refusal logic.

**Files:** Modify `commands/{create-ard,specify}.md`, `docs/commands/{create-ard,specify}.md`.

- [ ] **Step 1: `/create-ard`** — reads `ard-seed.md` plus the architecture-altitude findings; `[CG#n]`/`[DG#n]` seed the ARD's grounding-findings section; architecture decisions seed `AD#N`; each consumed item marked `consumed_by: ARD`.
- [ ] **Step 2: `/specify`** — reads `spec-seed.md` including the derivation matrix; each consumed item marked `consumed_by: specification`.
- [ ] **Step 3: Verify the `consumed_by` loop closes.** §7.3 says everything still `none` is reported. Say which command reports it and when — if nothing does, that is a finding, not an omission to paper over.
- [ ] **Step 4: Docs pages from the commands**, gate triple, commit each separately.

---

### Task 4: Documentation

**Files:** Modify `docs/brd-workflow.md`, `docs/workflow.md`, `docs/roles-and-phases.md`, `docs/README.md`.

- [ ] **Step 1: The route page** — the diagram gains the handoff into `/create-prd`, and `--from-brd` stops being marked unshipped **everywhere**. The parameter table gains the switch on three rows, each derived from the command's own argument parsing.
- [ ] **Step 2: `docs/workflow.md`'s overview diagram** — the BRD subgraph now *does* connect to the PRD node. The note explaining why it was disconnected must go, and the two diagrams must agree edge for edge. A summary diagram contradicting the detailed one is worse than no summary; increment 2 shipped exactly that defect.
- [ ] **Step 3: `roles-and-phases.md`** — if a phase count changes, change it in the same commit as the section it counts.
- [ ] **Step 4: Gate triple, commit** — `docs(brd): connect the route to the PRD pipeline`

---

### Task 5: Catalog, changelog, instruction files, and the end-to-end walk

Written last: a verification record written before the final fix wave goes stale.

**Files:** Modify `.claude-plugin/marketplace.json`, `plugins/dev-workflows/.claude-plugin/plugin.json`, `plugins/dev-workflows/CHANGELOG.md`, `CLAUDE.md`.

- [ ] **Step 1: Re-derive every count against the tree.** No new commands, agents or references were added — confirm that is still true rather than assuming it.
- [ ] **Step 2: Descriptions.** Hard budget 1024 characters, warn at 900; they stood at 893, so **there is almost no headroom** — replace wording, never append. Copilot CLI rejects the entire catalog on overflow. Verify immediately, before anything else is written.
- [ ] **Step 3: The end-to-end walk — the whole route, now including the handoff.** `/brd-intake` → `/brd-ground` → `/brd-split` → `/brd-interview` → `/brd-package` → external wait → `/brd-reconcile` → `/create-prd --from-brd` → `/create-ard --from-brd` → `/specify --from-brd`, at **parent and slice level**, including a claimless BRD and a kept-empty slice. **Name any state a user can enter and not leave.** Eleven such defects shipped across two increments; every one was found by this walk and none by a per-task review. Record it whether or not it finds anything.
- [ ] **Step 4: Changelog and `CLAUDE.md`**; search for anything this increment falsified.
- [ ] **Step 5: Gate triple, commit** — `chore(brd): catalog, changelog and instruction-file counts for increment 3`

---

## What increment 3 completes

The route runs end to end. A customer's BRD becomes a grounded, decided, customer-reviewed document, and its product-altitude seed becomes a PRD through `/create-prd`'s own `prd-reviewer` gate — feeding `/create-ard → /epics → /specify → /design` exactly as the `/idea` route does.

**There is no increment 4.** If the walk or the whole-branch review finds something structural, that is a finding to report, not a plan to defer into.
