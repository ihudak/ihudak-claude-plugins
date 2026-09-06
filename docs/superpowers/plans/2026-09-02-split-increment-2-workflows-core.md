# Split increment 2 — `workflows-core` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract `workflows-core` — 6 commands, 5 agents, 28 reference files, 2 skills, 2 scripts — out of `dev-workflows`, have `dev-workflows` depend on it, and route every cross-plugin reference read through one argument-taking loader skill.

**Architecture:** A new plugin holds everything more than one future plugin loads. Because `${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin, a dependent plugin cannot read core's files by path; it reads them through `Skill(skill: "workflows-core:reference", args: "<name>")`, whose body executes inside core and therefore resolves core's own root. Agents cross the boundary natively via `subagent_type: "workflows-core:<agent>"`.

**Tech Stack:** Claude Code plugin manifests, markdown command/agent/reference files, bash (`scripts/check-docs.sh`), python (`scripts/validate-catalog.py`, `plugins/workflows-core/scripts/session-cost.py`).

**Spec:** `docs/superpowers/specs/2026-09-02-marketplace-split-design.md` (S1–S17, §5 loader, §6 gate changes, §8 cost boundary)

## Global Constraints

- **No behaviour changes.** Every command does exactly what it did at `52d47ed`. A split that also improves something cannot be bisected when it breaks. (spec §9)
- **`dev-workflows` goes to 3.26.0, not 4.0.0.** Each increment is a minor bump; 4.0.0 marks the end state. **The CHANGELOG entry's first sentence carries the required install command.** (S17)
- **`workflows-core` starts at 1.0.0.** (S8)
- **Dependencies are declared bare-name**, never version-ranged: `"dependencies": ["workflows-core"]`. (S6)
- **Nothing splits a reference file.** A subtree may be split file-by-file — `handoff/` is one directory of nine independent per-agent contracts, not one reference. (spec §10)
- **A file moves to core iff more than one post-split plugin would *load* it.** A pointer citation ("the same rule as X §2.6") never forces a move. (S4, S16)
- **`${CLAUDE_PLUGIN_ROOT}` does not expand in slash-command bodies** — commands reach bundled content through a skill. (CLAUDE.md)
- Every `[PREFIX#N]` requirement ID stays bracketed; `./scripts/check-id-grammar.sh --root .` must pass. (CLAUDE.md)
- Prose is never hard-wrapped: one unbroken line per paragraph. (`references/prose-formatting.md`)
- **All SEVEN gate invocations green before the PR — take the list from `.github/workflows/validate-catalog.yml`, never from this plan.** Six are the familiar `check-docs.sh --root .` / `--selftest`, `check-id-grammar.sh --root .` / `--selftest`, `validate-catalog.py` / `--selftest`. The seventh is the one this plan originally omitted and every task through Task 5 therefore skipped: the session-cost selftest, which CI discovers by path rather than hardcoding. It was **red from Task 4 through Task 5** — a namespace sweep had rewritten a constant inside its own fixture — and no task noticed, because every task ran the six gates the plan named. A plan's gate list is a copy, and this one was already stale when it was written.
- `CLAUDE.md` is updated in the same commit as the change it describes. (spec §7 "Every increment")

---

## The measured allocation

Derived from the tree at `52d47ed` by the rule above: dispatch edges are `subagent_type: "dev-workflows:<agent>"` only; load edges are `${CLAUDE_PLUGIN_ROOT}/references/<file>.md` only; each agent inherits the groups of the commands that dispatch it, transitively. Group membership follows the spec's own final allocation: **core** = `/feedback` `/frames` `/prompt` `/prompt-brainstorm` `/prompt-grill-me` `/statusline`; **pm** = `/idea` `/create-prd` `/update-prd` `/create-ard` `/specify` `/epics` and the six `/brd-*`; **dev** = `/design` `/implement` `/ready` `/vuln` `/upgrade`; **docs** = `/document` `/docs-profile` `/release-notes`.

### Moves to `workflows-core`

**Commands (6):** `feedback.md`, `frames.md`, `prompt.md`, `prompt-brainstorm.md`, `prompt-grill-me.md`, `statusline.md`

**Agents (5):** `code-scanner.md` (dev+pm), `doc-fixer.md` (docs+pm), `docs-grounder.md` (docs+pm, dispatched from inside `docs-grounding.md` — S4), `frame-describer.md` (core, follows `/frames` — S13), `impl-maintenance.md` (all four)

**Reference files (28) — 25 flat:** `addressing.md`, `ard-resolution.md`, `branch-naming.md`, `cost-emission.md`, `dependencies.md`, `doc-structure-conventions.md`, `docs-grounding.md`, `epic-picker.md`, `escalation-rules.md`, `feedback-emission.md`, `finding-triage.md`, `followup-emission.md`, `grilling-technique.md`, `grounding-format.md`, `implementation-format.md`, `instruction-file-maintenance.md`, `next-phase-offer.md`, `phase-handoff.md`, `prd-format.md`, `pre-lint.md`, `prose-formatting.md`, `read-only-repos.md`, `session-hygiene.md`, `source-truth.md`, `specs-repo-git.md`
**— and 3 from subtrees:** `handoff/code-scanner.md`, `handoff/impl-maintenance.md`, `model-routing/classification.md`
**— plus one non-markdown data file:** `cost-prices.yaml` (moves with `cost-emission.md`; check 4 counts markdown only, so it appears in no inventory row)

**Skills (2):** `model-routing/` (moved verbatim), `reference/` (new — the loader)

**Scripts (2):** `session-cost.py`, `statusline-command.sh`

**Documentation pages (6 command pages only):** `docs/commands/{feedback,frames,prompt,prompt-brainstorm,prompt-grill-me,statusline}.md`

**No `docs/reference/` page moves — see R6.**

### Stays in `dev-workflows` (36 reference files)

**Bound for `product-workflows` (9):** `ard-format`, `brd-format`, `bundle-packaging`, `coverage-ledger-format`, `customer-review-schema`, `decision-register-format`, `idea-format`, `interview-tagging`, `specification-format`
**Bound for `dev-workflows` (15):** `bug-diagnosis`, `code-handoff`, `context-management`, `design-format`, `workflow-states`, `fix-vuln/build-systems`, `fix-vuln/nvd-api`, `handoff/test-baseliner`, `handoff/upgrade-executor`, `handoff/upgrade-planner`, `handoff/vuln-fixer`, `handoff/vuln-research`, `upgrade/compatibility`, `upgrade/ecosystems`, `upgrade/lts-sources`
**Bound for `docs-workflows` (12):** `docs-profiles/anchor-conventions`, `docs-profiles/changelog-guidelines`, `docs-profiles/docs-profile-schema`, `docs-profiles/frontmatter-guidelines`, `docs-profiles/render-verification`, `finish-and-handoff`, `gate-ledger`, `handoff/diff-summarizer`, `handoff/release-notes-writer`, `release-note-types`, `repo-verification-gates`, `toolchain-preflight`

Also staying: the `docs-frontmatter` skill (`/docs-profile` only), `specification-to-html.py` (`/specify` only), all five hooks (`preload-context.sh` matches only `/implement|/document|/epics|/release-notes|/vuln|/upgrade`, none of which move), and the non-markdown files under `references/docs-profiles/`.

**After this increment `dev-workflows` ships 20 commands, 31 agents, 36 reference files, 1 skill, 1 script, 5 hooks.**

### Four rulings that shaped this list

**R1 — `doc-fixer` moves to core, though the spec's §2 table counted it under pm.** Its two consumer groups are pm (`/epics`) and docs (`/document`). Both leave `dev-workflows` in later increments, so leaving it behind would strand an agent in a plugin that never dispatches it. Cost if wrong: one agent sits in core with two dependents instead of one — the same place S4 would put it anyway. Core therefore ships **5** agents, not the spec's measured 4; amend §2's table row rather than the tree.

**R2 — `upgrade/compatibility.md` stays in `dev-workflows`.** Its only core-side citation is `impl-maintenance.md:100`, inside a report template as the *example* path in `[path, e.g. …]`. An example is not a load. That citation is rewritten to name a core reference instead.

**R3 — `dependencies.md` moves to core and is corrected in the same commit.** It is loaded by nothing (`grilling-technique.md` names it in prose) but its subject is cross-plugin dependency convention, which is now core's. Its standing claim — that no command hard-requires another plugin "since Claude Code plugins express no dependency-manifest field" — is **false as of this increment**, which declares exactly such a field. This is the CLAUDE.md "a note saying a feature does not ship, left standing beside the now-shipped feature" case.

**R4 — a citation that would dangle after the move is demoted to a bare name, never promoted.** Nine sites, all pointer-shaped, listed in Task 4 step 4.

**R6 — the six documentation *reference* pages stay in `dev-workflows`; core authors its own.** Measured before deciding: `docs/reference/{model-routing,session-cost,session-feedback,follow-ups,resume-and-checkpoints,commit-convention}.md` carry **about ninety inbound links** from `dev-workflows` pages that are not moving — `session-cost.md` alone is linked from 27 of them, `session-feedback.md` from 24. Moving those pages breaks every one of those links (check 1), and check 10 forbids the obvious repair, because a link into another plugin's docs would have to name the marketplace or the container repo. The mirror problem is real too: `commit-convention.md` links out to five *command* pages that stay.

The deeper reason is that these pages do not document core in the first place — they document a subsystem **from the invoking side**, and the invoking side is exactly what stays. A `dev-workflows` user still emits cost, still gets feedback prompts, still resumes a checkpointed run; the page describing that belongs with the commands that do it. What moves is the *mechanism* — `cost-emission.md`, `feedback-emission.md`, `followup-emission.md`, `session-hygiene.md` — which is a reference, not a documentation page.

So `workflows-core` **authors** whatever `docs/reference/` pages its own gate obligations require, rather than inheriting `dev-workflows`'s list. Derive that set by running the gate, not by copying: core ships cost-emitting commands of its own (`/feedback`, `/prompt`), so check 9's cost-emitting-set count sentence needs a home in core, and check 4 needs `agents.md` and `references.md` to inventory what core actually ships. Do not duplicate a page core has no obligation to carry — a second copy of an explanatory page is a second copy to keep true.

Cost if wrong: some prose is stated twice across two plugins' documentation trees. That is the cheaper error. The alternative — ninety dangling links, repairable only by a URL a fork would have to rewrite — is the expensive one.

---

## The citation convention

Three forms, and every rewrite in Task 4 produces exactly one of them.

| Situation | Form |
|---|---|
| A dependent plugin **loads** a core reference | `Skill(skill: "workflows-core:reference", args: "phase-handoff")` |
| A dependent plugin loads one **entry point** of it | `Skill(skill: "workflows-core:reference", args: "specs-repo-git specs-preflight")` |
| A dependent plugin **names** it in prose (an anchor, a "per X §3.4") | `` `workflows-core:phase-handoff` §3.4 `` — a name, never a path |
| Core's own files cite each other | unchanged `${CLAUDE_PLUGIN_ROOT}/references/<name>.md` |
| A core file names a file that stayed behind | bare `` `references/<name>.md` `` — a name, never a path |

Subtree references keep their path inside the argument: `workflows-core:model-routing/classification`, `workflows-core:handoff/code-scanner`.

**Every file in a dependent plugin that carries at least one namespaced citation gains one preamble line**, immediately after its frontmatter (agents) or its opening description block (commands):

> **Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

**Why the entry-point argument matters beyond convenience:** `cost-emission.md` cites `${CLAUDE_PLUGIN_ROOT}/scripts/session-cost.py`, and `specs-repo-git.md`, `phase-handoff.md` and `feedback-emission.md` cite core-relative paths of their own. Read through the loader those expand against **core's** root and resolve; read any other way they do not. Scripts do not cross a plugin boundary any more than references do — the loader is what makes the cost subsystem reachable from `dev-workflows` at all.

---

## File structure

```
plugins/workflows-core/
  .claude-plugin/plugin.json        ← name, description (≤1024 chars), author, version 1.0.0
  README.md                         ← role-indexed pointer table + "6 slash commands"
  LICENSE                           ← MIT, copied
  CHANGELOG.md                      ← 1.0.0, install command in the first sentence
  commands/            (6)
  agents/              (5)
  references/          (25 flat + handoff/2 + model-routing/1 + cost-prices.yaml)
  skills/model-routing/SKILL.md     ← moved verbatim
  skills/reference/SKILL.md         ← new loader
  scripts/session-cost.py           ← moved in Task 3 (with cost-emission.md), extended in Task 6
  scripts/command-namespaces.json   ← new manifest (Task 7)
  scripts/statusline-command.sh     ← moved in Task 3 (with /statusline)
  docs/README.md, getting-started.md, workflow.md
  docs/commands/       (6)
  docs/reference/agents.md, references.md, environment.md,
                 model-routing.md, session-cost.md, session-feedback.md,
                 follow-ups.md, resume-and-checkpoints.md, commit-convention.md
```

---

### Task 1: Create the `workflows-core` skeleton and register it

**Files:**
- Create: `plugins/workflows-core/.claude-plugin/plugin.json`, `README.md`, `LICENSE`, `CHANGELOG.md`
- Create: `plugins/workflows-core/docs/README.md`, `docs/getting-started.md`, `docs/workflow.md`
- Create: `plugins/workflows-core/docs/reference/agents.md`, `references.md`, `environment.md`
- Modify: `.claude-plugin/marketplace.json`, `README.md` (repo root), `scripts/check-docs.sh:30`

**Interfaces:**
- Consumes: nothing
- Produces: an empty-but-green plugin at `plugins/workflows-core/`, present in `PLUGIN_RELS`, that later tasks fill

The plugin ships **nothing** at the end of this task. That is deliberate: it proves the ten-row checklist in spec §6 passes on an empty tree before any content is at stake.

- [ ] **Step 1: Write the manifest**

`plugins/workflows-core/.claude-plugin/plugin.json`:

```json
{
  "name": "workflows-core",
  "description": "Shared foundation for the dev-workflows plugin family: the addressing grammar and specs-repo git entry points, phase handoff, model routing, escalation and finding-triage rules, cost/feedback/follow-up emission, and the reference loader skill that lets a dependent plugin read them. Also carries the family-meta utility commands — /feedback, /prompt, /prompt-brainstorm, /prompt-grill-me, /statusline — and /frames for indexing design frame sets.",
  "version": "1.0.0",
  "author": {"name": "Ivan Gudak"}
}
```

Copy `LICENSE` verbatim from `plugins/dev-workflows/LICENSE`.

- [ ] **Step 2: Root README gains the install line BEFORE anything else**

Check 7 tests that each plugin's `getting-started.md` install block is a **subset** of the repo-root README's. Add to `README.md`'s install block, after the `guideline-reviewers` line:

```
claude plugin install workflows-core@ihudak-plugins
```

Add a marketplace-index row for the plugin in the same file, matching the shape of the existing rows.

- [ ] **Step 3: Register in the catalogue**

Add to `.claude-plugin/marketplace.json`, matching the existing entries' formatting exactly (the file is parsed by Claude Code — do not reformat):

```json
{
  "name": "workflows-core",
  "source": "./plugins/workflows-core",
  "description": "<the same string as plugin.json, verbatim>"
}
```

- [ ] **Step 4: Write the four required documentation pages**

`docs/README.md` — the index. Must state the skill count as a **digit** while the tree is empty: check 9's accepted word list runs `one`…`ten` and **does not contain "zero"**. Write `0 bundled skills`, and `0 slash commands` in the plugin `README.md`.

`docs/getting-started.md` — carries the install commands **inline** (it is check 7's sanctioned exception to the identity quarantine, so it may name the marketplace; no other page under `docs/` may).

`docs/workflow.md` — must contain a ```mermaid fenced block. With no commands yet, a single node naming the plugin satisfies check 15; Task 5 fills it.

`docs/reference/agents.md`, `references.md`, `environment.md` — each an empty table with its header row. `environment.md` must document **exactly** the variables the plugin reads: none yet.

- [ ] **Step 5: Add the plugin to the gate's list**

`scripts/check-docs.sh:30`:

```bash
PLUGIN_RELS="${PLUGIN_RELS:-plugins/dev-workflows plugins/guideline-reviewers plugins/workflows-core}"   # copilot: dev-workflows
```

Leave `COST_PLUGIN_RELS` and `HANDOFF_PLUGIN_RELS` unchanged — core ships neither subsystem yet, and membership is declared, never inferred.

- [ ] **Step 6: Run every gate**

```bash
./scripts/check-docs.sh --root . && ./scripts/check-docs.sh --selftest \
  && ./scripts/check-id-grammar.sh --root . && ./scripts/check-id-grammar.sh --selftest \
  && python3 scripts/validate-catalog.py && python3 scripts/validate-catalog.py --selftest
```
Expected: all PASS, 0 errors, 0 warnings.

- [ ] **Step 7: Commit**

```bash
git add plugins/workflows-core .claude-plugin/marketplace.json README.md scripts/check-docs.sh
git commit -m "feat(core): create the empty workflows-core plugin and register it"
```

---

### Task 2: Teach checks 8, 9 and 11 to resolve a shared reference across plugins

**Files:**
- Modify: `scripts/check-docs.sh` (config block; `check_cost_attribution`, `check_prose_counts`, `check_merge_clause`, and their selftest cases)

**Interfaces:**
- Consumes: Task 1's `PLUGIN_RELS` entry
- Produces: `CORE_PLUGIN_REL`, a single config variable naming the plugin that holds the shared reference corpus

This lands **before** the move so the tree stays green at every step: the variable defaults to `plugins/dev-workflows`, which is where those references still are. Task 3 flips it.

Three checks read a reference file and its call sites and assert both directions between them. After Task 3 the reference is in core and the call sites are not.

- [ ] **Step 1: Add the config variable**

Beside `COST_PLUGIN_RELS` / `HANDOFF_PLUGIN_RELS` at `scripts/check-docs.sh:50`:

```bash
# The plugin that holds the shared reference corpus. Checks 8, 9 and 11 read a
# reference from HERE and their call sites from $PLUGIN_REL -- after the split
# those are different plugins. Set to the plugin under check before the split.
CORE_PLUGIN_REL="${CORE_PLUGIN_REL:-plugins/dev-workflows}"   # copilot: dev-workflows
```

Name it in the header's required-config list, next to the three that are already there.

- [ ] **Step 2: Check 8 reads its table from core**

In `check_cost_attribution`, the §7 table comes from `$CORE_PLUGIN_REL/references/cost-emission.md`; the `emit-cost` call sites stay `$PLUGIN_REL/commands/`. Both directions still assert — a command emitting a fixed pair with no §7 row, and a §7 row naming a command that emits none. **The reverse direction must scan the call sites of every plugin in `COST_PLUGIN_RELS`, not just the one under check**, or every row fires the moment the emitting commands spread across plugins.

- [ ] **Step 3: Check 9's cost-emitting-set count follows**

In `check_prose_counts`, the sentence lives in `$PLUGIN_REL/docs/reference/session-cost.md` and counts `emit-cost` call sites in `$PLUGIN_REL/commands/`. Guard the assertion on the plugin actually shipping that page: a plugin with no `docs/reference/session-cost.md` skips this one count and keeps the other six.

- [ ] **Step 4: Check 11 derives its family from core**

In `check_merge_clause`, `next-phase-offer.md` is read from `$CORE_PLUGIN_REL`; the `/brd-*` commands, the `phase-handoff.md` row-F table and each command's `deliverable_paths` are read from `$PLUGIN_REL`. The `phase-handoff.md` read also moves to `$CORE_PLUGIN_REL`. Every relation coming up empty must still **fail**, not pass — that property is what makes a reworded handoff sentence turn the build red, and it is the easiest thing to lose in this edit.

- [ ] **Step 5: Add a selftest case per check for the cross-plugin shape**

Three new cases, each copying the fixture tree and moving the shared reference into a second plugin directory, asserting the check still fires on its own defect from there. Pair each with a **green** case in the same shape — a check that silently no-ops when the reference is in another plugin passes every red case.

- [ ] **Step 6: Run the gates.** Same command as Task 1 Step 6. Expected: all PASS, and `--selftest` reports its new cases as `ok`.

- [ ] **Step 7: Commit**

```bash
git add scripts/check-docs.sh
git commit -m "test(gate): let checks 8, 9 and 11 resolve their shared reference from another plugin"
```

---

### Task 3: Move everything into core

**Files:**
- Move (`git mv`): 28 reference files + `cost-prices.yaml`, 5 agent files, 6 command files, `skills/model-routing/`, `scripts/session-cost.py`, `scripts/statusline-command.sh`, 6 `docs/commands/` pages — lists in *The measured allocation*; **no `docs/reference/` page moves (R6)**
- Modify: `scripts/check-docs.sh` (`CORE_PLUGIN_REL`, `COST_PLUGIN_RELS`, `HANDOFF_PLUGIN_RELS`)
- Modify: both plugins' `docs/README.md`, `docs/workflow.md`, `docs/reference/{agents,references,environment}.md`, plugin `README.md`, `docs/roles-and-phases.md`

**Interfaces:**
- Consumes: Task 2's `CORE_PLUGIN_REL`
- Produces: core's complete content at its final paths; `dev-workflows` at 20 commands, 31 agents, 36 reference files

**One task, not two, and the reason is a conflict the pre-flight scan found.** Moving the six commands *after* the sweep would have the sweep rewrite their citations into loader calls, and then move them into the very plugin whose files cite by plain path — leaving six commands calling a loader to read their own plugin's references. Everything that moves, moves here; Task 4 then sweeps only what stayed.

**This task deliberately leaves the tree red.** `dev-workflows` is left citing 767 paths that no longer exist. Do not attempt partial rewrites here — a half-swept tree is harder to reason about than a fully broken one.

- [ ] **Step 1: Move the files with `git mv`**, preserving `references/handoff/` and `references/model-routing/` as directories inside core. Move `cost-prices.yaml` alongside `cost-emission.md`.

Each script travels with the file that cites it: `session-cost.py` with `references/cost-emission.md` (which cites `${CLAUDE_PLUGIN_ROOT}/scripts/session-cost.py`), `statusline-command.sh` with `commands/statusline.md`. Both land in core in this task, so both pairings hold. Nothing gates a script path — this pairing is held by this instruction alone.

- [ ] **Step 2: Flip the gate config**

```bash
CORE_PLUGIN_REL="${CORE_PLUGIN_REL:-plugins/workflows-core}"
COST_PLUGIN_RELS="${COST_PLUGIN_RELS:-plugins/dev-workflows plugins/workflows-core}"
HANDOFF_PLUGIN_RELS="${HANDOFF_PLUGIN_RELS:-plugins/dev-workflows}"
```

`COST_PLUGIN_RELS` holds both because both ship cost-emitting commands — core's `/feedback`, `/prompt`, `/frames` and the two ceding grill commands, and `dev-workflows`'s twenty. `HANDOFF_PLUGIN_RELS` holds `dev-workflows` **alone**: the `/brd-*` family stays there until increment 4, and core ships not one command of it.

- [ ] **Step 2a: Re-base both applicability checks on the call sites, not the reference file (R7)**

While in the header, correct one sentence it now overstates: the required-config note says a ported edition omitting one of these variables *aborts at the dispatch loop*, which is true of the three list variables the loop expands but not of `CORE_PLUGIN_REL`, which is read only inside check bodies.

`check_cost_applicability` and `check_handoff_applicability` both trigger on a plugin **shipping the reference** — `cost-emission.md` and `next-phase-offer.md` respectively. This move falsifies that premise in both directions at once, and the two failures look nothing alike:

- `dev-workflows` keeps twenty cost-emitting commands and stops shipping `cost-emission.md`, so its assertion **goes silent**. Drop it from `COST_PLUGIN_RELS` afterwards and nothing catches it — a gate that quietly stopped guarding the plugin it was written for.
- `workflows-core` starts shipping `next-phase-offer.md` and ships no `/brd-*` command, so it is **forced into** `HANDOFF_PLUGIN_RELS`, whereupon check 11 runs for it, derives an empty family, and fails — with neither branch green, because "relations fail when empty" is the property that must not be relaxed.

Both are the same defect: shipping the reference no longer implies shipping the call sites the check is about. Re-base each trigger on the call sites:

- **cost:** a plugin whose `commands/` contain an `emit-cost` call site must be declared in `COST_PLUGIN_RELS`.
- **handoff:** a plugin whose `commands/` contain at least one command of the family derived from `$CORE_PLUGIN_REL/references/next-phase-offer.md` must be declared in `HANDOFF_PLUGIN_RELS`.

The "declared, never inferred from a missing file" property is untouched — the shipped-test simply now asks the right question. Each direction needs a paired red/green `--selftest` case: a plugin with call sites and no declaration must fail, and a plugin holding only the reference must pass.

**Do not instead narrow the dispatch guard.** Two other fixes suggest themselves — making check 11 run only for a plugin that is both declared *and* has commands matching the family, or exempting `$CORE_PLUGIN_REL` — and both are absence-implies-skip at the dispatch site. Under either, a plugin whose family commands were renamed drops out of check 11 entirely, and the `route_n > 0` guard cannot catch it because the check never runs at all. Re-basing the trigger keeps the loud direction loud; narrowing the guard trades a hard failure for a silent one.

- [ ] **Step 3: Author core's own `docs/reference/` pages, and move none**

Per R6, no `docs/reference/` page moves. `dev-workflows` keeps all six of its subsystem pages and every inbound link to them stays valid. Core authors only what its own gate obligations require — determine that set by running `./scripts/check-docs.sh --root .` and reading the failures, never by copying `dev-workflows`'s page list. At minimum that is `agents.md` and `references.md` (check 4) and a `session-cost.md` carrying the cost-emitting-set count sentence (check 9).

**Core's cost-emitting set is FIVE, not two** — verified against the extractor, not counted by eye: `/feedback`, `/frames` and `/prompt` carry an `emit-cost` call; `/prompt-brainstorm` and `/prompt-grill-me` yield a triple through their §13 `defer` marker, because they cede the session before they can write their own entry. Only `/statusline` emits nothing and correctly has no §7 row. Write `five`, or check 9 reddens on the page this step just authored.

Correspondingly, `dev-workflows`'s own sentence at `docs/reference/session-cost.md:32` goes from `Twenty-two` to **`Seventeen`**, its command list loses those five names, and its `Sixteen … six infer it` sub-counts and its whole `/frames` sentence must be re-derived — `/frames` is core's now.

- [ ] **Step 4: Update both inventories**

`plugins/workflows-core/docs/reference/agents.md` gains a `` | `<name>` `` row per moved agent. `references.md` gains a row per **flat** file plus one subtree row, `` `handoff/` (2) `` — N is the **markdown-only** count, so `cost-prices.yaml` is counted nowhere.

**`model-routing/` is NOT a subtree row.** `check-docs.sh` sets `REF_FLAT_EXTRA="model-routing"`, which makes check 4 inventory `references/model-routing/*.md` **file by file, as flat rows**, and skip it in the subtree loop. Core's `references.md` therefore carries `` `classification.md` `` as an ordinary flat row and no `` `model-routing/` `` row at all. Writing the subtree row instead fails check 4 twice over — once for a claimed subtree the loop never counts, once for a flat file nothing names.

`plugins/dev-workflows/docs/reference/*` loses exactly the moved rows, and its `` `handoff/` `` row drops from 9 to **7** (`test-baseliner`, `upgrade-executor`, `upgrade-planner`, `vuln-fixer`, `vuln-research`, `diff-summarizer`, `release-notes-writer`). Its `upgrade/` (3), `fix-vuln/` (2) and `docs-profiles/` (5) rows are unchanged. `REF_FLAT_EXTRA` is global config across every plugin in `PLUGIN_RELS`, and needs no edit: after the move `dev-workflows` simply has no `references/model-routing/` directory, and the `ls` behind it is already error-suppressed.

- [ ] **Step 5: Update `environment.md` on both sides**

Check 5 runs in both directions, so this move fires it **twice**. Re-derive each plugin's variable set from what its files now read — `$SPECS_PATH`, `$REPOS_PATH`, `$DOCS_PATH` and the rest follow their references — and write only what is read.

- [ ] **Step 6: Fill core's `docs/workflow.md` mermaid diagram**

Check 15 asserts every command appears **inside the diagram**, not in prose below it. All six, by name.

- [ ] **Step 7: Remove the six commands from `dev-workflows`'s three listing surfaces** — `docs/README.md`, the plugin `README.md`, and `docs/workflow.md`'s mermaid diagram. Check 15 is **forward-only**: a diagram still naming a departed command passes silently, so this is by hand.

- [ ] **Step 8: Update every prose count** in both plugins' `docs/README.md` and plugin `README.md`: `20 slash commands` / `6 slash commands`, agents, reference files, skills, and the cost-emitting-set size.

`dev-workflows`'s `docs/reference/session-cost.md` stays put under R6 but its cost-emitting-set sentence counts six departed commands — check 9 goes red on it until it is rewritten. Core's own `session-cost.md`, authored in Step 3, carries the count for core's emitters.

Also reword the repo-root `README.md` plugin-table row for `workflows-core`. Task 1 trimmed it to 181 of check 6's 200 characters and, in doing so, dropped the six utility commands `plugin.json` names. They exist now, so the row can name them truthfully — within the cap.

- [ ] **Step 9: Verify the move landed, then commit**

```bash
ls plugins/workflows-core/references/*.md | wc -l          # expect 25
ls plugins/workflows-core/references/handoff/*.md | wc -l  # expect 2
ls plugins/workflows-core/agents/*.md | wc -l              # expect 5
ls plugins/workflows-core/commands/*.md | wc -l            # expect 6
ls plugins/dev-workflows/commands/*.md | wc -l             # expect 20
ls plugins/dev-workflows/agents/*.md | wc -l               # expect 31
find plugins/dev-workflows/references -name '*.md' | wc -l # expect 36
git add -A plugins/ scripts/check-docs.sh
git commit -m "refactor(core): move the shared corpus, five agents and six commands into workflows-core"
```

The gate is expected to FAIL after this commit. Record the failure count in the ledger; Task 4 must return it to zero.

---

### Task 4: The loader skill and the citation sweep

**Files:**
- Create: `plugins/workflows-core/skills/reference/SKILL.md`
- Modify: every **remaining** `plugins/dev-workflows/commands/*.md` and `agents/*.md` carrying a core citation, plus the sites inside the references that stayed. The six moved commands and five moved agents are **out of scope** — they are core's own files now and cite by plain path
- Modify: 9 sites inside moved core references that now point at files left behind

**Interfaces:**
- Consumes: Task 3's completed move
- Produces: a green tree; the `workflows-core:reference` skill contract every later plugin uses

- [ ] **Step 0: Anchor check 11's family extraction to the scope paragraph — BEFORE step 6a runs**

Step 6a rewrites `next-phase-offer.md:210`'s `/dev-workflows:prompt*` to `/workflows-core:prompt*`. That line sits under `## Not pipeline nodes` — a list of commands that carry **no** offer — and check 11 extracts its family with `head -1` over a `grep` of the **whole file**. So the moment step 6a runs, the extractor hands `workflows-core` the family `prompt*`, core is found to ship three commands matching it, and every branch is red:

```
FAIL check 11: plugins/workflows-core ships 3 command(s) of the 'prompt*' family … but is not a member of HANDOFF_PLUGIN_RELS
```
and, once declared:
```
FAIL check 11: no offer in the 'prompt*' family names a command whose require-on-main target that offer's own run writes
```

That is verbatim the trap R7 was written to remove, reappearing for a different reason. **`head -1` was never the contract** — `CLAUDE.md` has always said the family is derived from *"the first such phrase in `references/next-phase-offer.md`'s scope paragraph"*, and whole-file `head -1` was a proxy that held only while the scope paragraph happened to come first.

Anchor both extraction sites — `check_merge_clause` and `check_handoff_applicability` use the same idiom — to the scope paragraph, the single unwrapped line beginning `**Where this rule applies:`:

```bash
glob=$(grep '^\*\*Where this rule applies:' "$ref" 2>/dev/null \
       | grep -oE "$qual[a-z][a-z0-9-]*\*" | head -1 | sed "s|^$qual||")
```

**Measured, not argued** — the same three qualifier/file combinations, before and after:

| | whole-file `head -1` | scope-anchored |
|---|---|---|
| `/dev-workflows:` today | `brd-*` | `brd-*` |
| `/workflows-core:` today | *(empty)* | *(empty)* |
| `/workflows-core:` after step 6a | **`prompt*`** ← the trap | *(empty)* ← correct |

So the change is **behaviour-preserving today** and eliminates the trap. It also makes the check strictly stronger in the way `CLAUDE.md` asks for: a reworded scope sentence now empties the glob and turns the build red, where before any stray phrase elsewhere in the file would silently stand in for it. Keep both existing empty-glob dispositions exactly as they are — `fail 11` in `check_merge_clause`, the early `return` in `check_handoff_applicability`, which is safe only because the other is loud. Add a `--selftest` case pairing a reworded scope sentence (must fail) with a stray `$qual<family>*` phrase added under another heading (must still pass).

- [ ] **Step 1: Write the loader skill**

`plugins/workflows-core/skills/reference/SKILL.md`, exactly as spec §5 fixes it:

```markdown
---
name: reference
description: Read a shared workflows-core reference by name, and optionally execute one of its entry points.
user-invocable: false
allowed-tools: Read
---

The invocation arguments name one reference file and, optionally, one entry
point within it.

Read `${CLAUDE_PLUGIN_ROOT}/references/<the first argument>.md` and treat it as
the single source of truth for the current step. When a second argument is
present, execute that entry point of it inline. Never paraphrase, summarise, or
cache its contents.
```

Do **not** use `$ARGUMENTS` or `$N` substitution: the append-fallback is the branch that has been observed on a live machine, and the substitution branch has not.

- [ ] **Step 2: Rewrite the prose citations mechanically**

For each of the 28 core reference names, in `plugins/dev-workflows/commands/`, `agents/` and `references/`:

```bash
# `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md`  ->  `workflows-core:phase-handoff`
sed -i 's|\${CLAUDE_PLUGIN_ROOT}/references/phase-handoff\.md|workflows-core:phase-handoff|g' <files>
```

Subtree names keep their inner path (`workflows-core:model-routing/classification`). Run the substitution once per name, then assert nothing is left:

```bash
CORE=$(ls plugins/workflows-core/references/*.md | xargs -n1 basename | sed 's/\.md$//' | tr '\n' '|' | sed 's/|$//')
grep -rnE "\\\$\\{CLAUDE_PLUGIN_ROOT\\}/references/($CORE)\\.md" plugins/dev-workflows/ | wc -l   # expect 0
grep -rn 'CLAUDE_PLUGIN_ROOT}/references/handoff/code-scanner\|CLAUDE_PLUGIN_ROOT}/references/handoff/impl-maintenance\|CLAUDE_PLUGIN_ROOT}/references/model-routing/' plugins/dev-workflows/ | wc -l   # expect 0
```

- [ ] **Step 3: Convert the load sites and add the preamble**

A citation is a **load site** when the surrounding sentence tells the reader to read, follow, apply or execute the reference *now* — including every entry-point invocation (`specs-preflight`, `commit-artifacts`, `handoff-to-main`, `require-on-main`, `emit-cost`, `emit-feedback`, `emit-followups`, `resolve-docs-grounding`, `resolve-address`). Those become:

```
Skill(skill: "workflows-core:reference", args: "specs-repo-git specs-preflight")
```

Every file touched gains the **Core references** preamble line quoted in *The citation convention*, immediately after its frontmatter (agents) or opening description block (commands).

- [ ] **Step 4: Demote the nine dangling core-side citations**

These moved into core and point at files that stayed. All nine are pointer-shaped; each becomes a bare `` `references/<name>.md` `` with no `${CLAUDE_PLUGIN_ROOT}`:

| File | Points at | Treatment |
|---|---|---|
| `references/grilling-technique.md:27` | `idea-format.md` | bare name |
| `references/grounding-format.md:279` | `idea-format.md` | bare name |
| `references/phase-handoff.md:63` | `idea-format.md` | bare name |
| `references/phase-handoff.md:97` | `code-handoff.md` | bare name |
| `references/read-only-repos.md:41` | `code-handoff.md` | bare name |
| `references/specs-repo-git.md:18` | `code-handoff.md` | bare name |
| `references/doc-structure-conventions.md:7` | `docs-profiles/` (a directory, not a `.md`) | bare name |
| `references/handoff/impl-maintenance.md:59` | `upgrade/compatibility.md` | bare name |
| `agents/impl-maintenance.md:100` | `upgrade/compatibility.md` | a template *example* path (R2) — replace with a core reference name |

These nine are the **complete** set, enumerated against the final core file list. Note what is **not** here: `handoff/upgrade-executor.md` and `handoff/vuln-fixer.md` cite `context-management.md`, and all three of those files stay in `dev-workflows` — their citations remain correct and must not be touched. Enumerate before editing:

```bash
CORE=$(ls plugins/workflows-core/references/*.md | xargs -n1 basename | sed 's/\.md$//' | tr '\n' '|' | sed 's/|$//')
grep -rnEo '\$\{CLAUDE_PLUGIN_ROOT\}/references/[a-z0-9./-]+' plugins/workflows-core/ | grep -vE "/($CORE)$"
```

Line numbers are a starting point only — locate each by its surrounding phrase, never by line number.

- [ ] **Step 5: Rewrite the agent dispatch prefixes**

26 sites across commands, agents and references:

```bash
for a in code-scanner doc-fixer docs-grounder frame-describer impl-maintenance; do
  grep -rl "dev-workflows:$a" plugins/dev-workflows plugins/workflows-core \
    | xargs -r sed -i "s|dev-workflows:$a|workflows-core:$a|g"
done
grep -rn 'dev-workflows:\(code-scanner\|doc-fixer\|docs-grounder\|frame-describer\|impl-maintenance\)' plugins/ | wc -l   # expect 0
```

This also catches the `/dev-workflows:<agent>` prose mentions, which is correct — they name the same thing.

- [ ] **Step 6: Rewrite the `model-routing` skill namespace**

Every pipeline command invokes it by name; all call sites move with the skill:

```bash
grep -rl 'dev-workflows:model-routing' plugins/ | xargs -r sed -i 's|dev-workflows:model-routing|workflows-core:model-routing|g'
grep -rn 'dev-workflows:model-routing' plugins/ | wc -l   # expect 0
```

- [ ] **Step 6a: Rewrite every `/dev-workflows:<moved-command>` reference — 33 sites in 17 files**

Step 5 rewrites moved *agents*; this is the moved *commands*, a separate category and a larger one. Every one of these names a command that no longer resolves under that namespace:

```bash
for c in feedback frames prompt prompt-brainstorm prompt-grill-me statusline; do
  grep -rl "dev-workflows:$c\b" plugins/ | xargs -r sed -i "s|dev-workflows:$c\b|workflows-core:$c|g"
done
grep -rn 'dev-workflows:\(feedback\|frames\|prompt\|prompt-brainstorm\|prompt-grill-me\|statusline\)\b' plugins/ | wc -l   # expect 0
```

Measured distribution: `/statusline` 12 sites, `/frames` 11, `/prompt` 5, `/prompt-grill-me` 2, `/feedback` 2, `/prompt-brainstorm` 1. **Use a word boundary** — `prompt` is a prefix of `prompt-brainstorm` and `prompt-grill-me`, so an unanchored substitution corrupts the two longer names. Note that `next-phase-offer.md`, now core's own, is among the files carrying these: it names `/dev-workflows:prompt*` and `/dev-workflows:frames`, harmless today only because check 11's family derivation takes the first matching phrase.

- [ ] **Step 6b: Resolve the eight bare `scripts/session-cost.py` prose sites**

Eight sites across seven `dev-workflows` command files — `ready.md`, `implement.md`, `document.md` (×2), `release-notes.md`, `epics.md`, `design.md`, `specify.md` — describe running `scripts/session-cost.py` **without** a `${CLAUDE_PLUGIN_ROOT}` prefix, so neither Step 2's substitution nor its assertion grep sees them. The script is core's now, and a `dev-workflows` command cannot run it by path at all: reword each to say the work happens through the cost-emission entry point it already invokes, naming no path. `CHANGELOG.md` is excluded — it is history.

- [ ] **Step 7: Sweep the prose and the documentation links that describe what left**

This is the step that returns the gate to zero, and it is **not** reachable by Step 2's `sed`: the 53 residual failures are markdown links under `docs/`, not `${CLAUDE_PLUGIN_ROOT}` citations. They cluster in `docs/commands/` (`brd-ground.md` 9, `idea.md` 6, `epics.md` 4, `document.md` 4, `brd-split.md` 4, and eleven more pages with 1–3 each) with **two outside it** — `docs/brd-workflow.md` carries 2 — which are the easy ones to miss.

A link into another plugin's docs cannot be repaired with a URL: check 10 forbids naming the marketplace or the container repo, and a hardcoded URL is wrong in anyone's fork. De-link each one to a plain code span naming the reference and, where it helps the reader, the plugin that now owns it. Then sweep the surrounding prose the same way, including `plugins/dev-workflows/README.md`.

**Sweep `plugins/workflows-core/docs/**` too, not only `dev-workflows`'s.** Task 3 de-linked twelve dangling links on core's side but stopped at the link and did not follow through to the sentence around it — `plugins/workflows-core/docs/commands/statusline.md:9` still says *"Two other commands in **this plugin** collide with a Claude Code built-in the same way: `/release-notes` and `/upgrade`"*, and both halves are now false: those two ship in `dev-workflows`, and core's `workflow.md` no longer carries a three-name list. Nothing else in the plan owns core's documentation prose.

**`dev-workflows`'s `docs/reference/session-feedback.md` needs a rewrite, not a cut.** It documents two capture paths, and only the interactive one left with `/feedback`; the automatic path is still live, cited by nineteen `dev-workflows` commands through `feedback-emission.md`. Over-cutting it would delete documentation for behaviour the plugin still has.

Ungated failure mode, per spec §6. In `plugins/dev-workflows/docs/**` and `plugins/dev-workflows/README.md`, find every sentence describing a moved agent, reference or command and rewrite it to name the plugin that now ships it. Search by name, not by line number.

- [ ] **Step 8: Run the gates.** Expected: all PASS, and `check-docs --root .` at **zero** failures — this is the task that returns the tree to green.

- [ ] **Step 9: Commit**

```bash
git add -A plugins/
git commit -m "refactor(core): route every cross-plugin reference read through the loader skill"
```

---

### Task 5: The loader-contract gate

**Files:**
- Modify: `scripts/check-docs.sh` (new check + its selftest cases, and the check count in the header comment)

**Interfaces:**
- Consumes: Task 4's loader invocations
- Produces: a build-time failure for an unresolvable loader argument or an unreached core reference

- [ ] **Step 1: Write the check, both directions**

Every `args:` string passed to `workflows-core:reference` names a reference that exists in `$CORE_PLUGIN_REL/references/` (first token, plus `.md`), and every markdown file in `$CORE_PLUGIN_REL/references/` is reached by at least one citation. Parse the first whitespace-separated token of the argument, so the entry-point form is handled by the same code path.

**The forward direction must exclude the documentation placeholder.** The preamble line added to 58 files quotes the invocation form literally, `args: "<name>"`, as documentation of the convention. A gate that resolves every `args:` string it finds will try to open `<name>.md`, fail, and report 58 defects on entirely correct content — the single most likely way to get this check wrong. Skip any argument that is not a plausible reference name (it is bracketed), and add a green selftest case containing exactly such a preamble line, so a naive implementation is caught by the suite rather than by a reviewer.

**Relation 3 — every citing file carries the preamble — is scoped to `commands/`, `agents/` and `references/`, and nothing else.** Measured on the tree it will run against: within those three directories the match is exact — 64 cite core, 64 carry the preamble. But **31 further `dev-workflows` files cite core from outside them** — human-facing pages under `docs/` and one shell hook — and none should carry a runtime loader instruction. A gate implementing the relation as "every file that cites" fires 31 times on a correct tree.

**A fourth relation, earned rather than designed: no loader call may sit inside a fenced block.** Fix round 1 put one inside `epics.md`'s Phase 9 report template — a `[…]` placeholder line the command *prints to the user* — where it would be read as text and never executed. It is worth gating for three reasons: the tree is at zero today so the check starts green; the failure is invisible to every other relation, because the call is perfectly well-formed and its argument resolves; and it took a careful reviewer reading fence boundaries to find, having been introduced by the same commit that wrote the principle forbidding it. Red fixture: a bare token inside a report template converted to a call. Green fixture: any of the eleven bare tokens that correctly sit inside such templates today — the green case is what discriminates, since a checker that simply ignores fenced content passes the red case for the wrong reason.

**Do not append `.md` blindly when resolving a citation.** The token set briefly included `workflows-core:cost-prices.yaml`, a data file that moved with `cost-emission.md`; fix round 2 removed it, so a resolver appending `.md` is safe **today**. Keep the guard anyway — the pressure to namespace that file again will recur every time someone reads the citation convention and applies it uniformly.

**The reverse direction counts any citation, not only a loader call** — a plain `${CLAUDE_PLUGIN_ROOT}/references/<name>.md` from inside core counts. Requiring a *loader* call would fail on every core reference that only core's own files read: `instruction-file-maintenance.md` is cited by `impl-maintenance.md` alone, and `handoff/code-scanner.md` by `code-scanner.md` alone — both now core-internal, both correct, and neither will ever appear in an `args:` string. A reverse direction that demanded a loader call would report the two most obviously correct files in the corpus.

**The tree's measured state, re-measured after Task 4's fix round — the earlier figures in this plan were taken before it and are all superseded:** 334 loader invocations, of which **64 are the `<name>` documentation placeholder** and **270 are real**, carrying **28 distinct `args:` strings**, every one resolving to a core reference. **141 of the 270 are two-argument entry-point calls.** Relation 3 is an exact match: **64 `dev-workflows` files under `commands/`, `agents/` and `references/` cite core, and all 64 carry the preamble** — while 31 files outside those three directories cite core and correctly carry none.

**The reverse direction must count three citation forms, not two**, or it fires on correct content. A core reference is reached by: a loader `args:` string; a `${CLAUDE_PLUGIN_ROOT}/references/<name>.md` path inside core; **or a bare `` `references/<name>.md` `` inside core**. That third form became unambiguous in Task 4's `48bd77d`, which split the bare name into core-internal (33 sites, core's own files) and outward-pointing (23 sites, now `dev-workflows:<name>`). Counting only the first two forms reports `dependencies.md` as unreached when `grilling-technique.md:65` cites it perfectly well.

- [ ] **Step 0a: Give the loader skill the tools its own body promises (R9)**

`plugins/workflows-core/skills/reference/SKILL.md` declares `allowed-tools: Read`, while its body says *"When a second argument is present, execute that entry point of it inline."* **Measured after the fix round: 141 of the 270 real invocations are two-argument entry-point calls** — `specs-repo-git specs-preflight`, `specs-repo-git commit-artifacts`, `phase-handoff handoff-to-main`, `phase-handoff require-on-main`, `feedback-emission emit-auto`, `cost-emission emit-cost` — and every one of them runs `git -C "$SPECS_PATH" …` or `python3 …/session-cost.py`. A majority of call sites therefore cannot do what the skill says they do.

This is inherited from the design's §5 block, which fixed the skill text before anyone enumerated the entry points; the sibling `model-routing` skill declares `Read` correctly, because it only ever reads. Declare `allowed-tools: Read, Bash`, matching this repo's own convention — `docs-frontmatter` and `prose-style-rules` both declare `Bash` for the same reason.

Whether `allowed-tools` actually constrains the invoking turn is not settled by reading; **the verification phase must exercise a two-argument invocation on a live machine**, and that step already exists. Declaring the tool is the cheap side of the bet: harmless if unenforced, and the difference between working and silently broken if enforced.

- [ ] **Step 0: Correct `dependencies.md`, and give it a real citation (R3, overdue)**

R3 said this file moves to core **and is corrected in the same commit**. The move happened; the correction did not, because the ruling was stated in prose and never became a step. **The reason is now purely its content, not its reachability** — an earlier measurement of mine called it the one unreached core reference, and that was an artefact of counting only two of the three citation forms; `grilling-technique.md:65` cites it. What remains wrong is what it says. Its opening is now materially false in three ways: it calls `dev-workflows` *"self-contained: no command hard-requires another plugin"*; it states there is *"**no dependency-manifest field** in `.claude-plugin/plugin.json` (Claude Code plugins don't express one)"*, which is the exact mechanism this entire increment rests on; and it is still titled for the plugin it no longer lives in. This is `CLAUDE.md`'s own named defect class — a note saying a feature does not ship, left standing beside the now-shipped feature.

Rewrite it to describe what actually ships: a declared `dependencies` field, auto-installed, with an unsatisfied dependency disabling the plugin — and keep the genuinely-still-true half about optional companions resolved at runtime with graceful fallback, which is what `superpowers` and `prose-style` still are. Then have `grilling-technique.md` cite it as a reference rather than name it in passing, so the reverse direction reaches it honestly. **Do not satisfy the gate by weakening it** — counting a bare prose mention as "reached" would make the reverse direction unfalsifiable.

- [ ] **Step 2: Selftest cases, paired red and green** — an unresolvable argument fires; an unreferenced core reference fires; the entry-point form does **not** fire; a correct tree passes. The entry-point green case is the discriminator: an implementation that matches the whole argument string instead of its first token passes both red cases and fails that one.

- [ ] **Step 3: Update the check count** in the script header and in `CLAUDE.md`'s enumeration of what the gate checks.

- [ ] **Step 3a: Two carried-over repairs while you are in these files**

`check_merge_clause`'s empty-glob message says the reference *"no longer names the command family … (expected a `/<plugin>:<family>*` phrase)"*. Since Step 0 of Task 4 that phrase can be present and the check still fire, because it is not on the scope-paragraph line — a maintainer would grep, find it, and conclude the gate is broken. Name the anchor line in the message.

`plugins/workflows-core/agents/impl-maintenance.md:51` step 3 still says to read command files from `${CLAUDE_PLUGIN_ROOT}/commands/`, which now resolves to core's six utility commands rather than the `dev-workflows` command that dispatched the agent. The `hooks/` line beside it was fixed; this one was missed because it is not a dangling path — core does ship `commands/` — so no assertion sees it.

- [ ] **Step 4: Run the gates.** Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/check-docs.sh CLAUDE.md
git commit -m "test(gate): assert the loader contract in both directions"
```

---

### Task 6: The cost boundary fix (spec §8)

**Files:**
- Create: `plugins/workflows-core/scripts/command-namespaces.json`
- Modify: `plugins/workflows-core/scripts/session-cost.py` (`load_command_names`, `command_marker`, the deferred-record writer, `--selftest`)
- Modify: `plugins/workflows-core/references/cost-emission.md` (§13.1 record shape, §13.2 boundary rule)
- Modify: `scripts/check-docs.sh` (manifest-equals-inventory check, inside the existing loop)

**Interfaces:**
- Consumes: Task 3's moved `session-cost.py`
- Produces: a boundary detector that resolves `<any known plugin>:<that plugin's known command>`

The defect, reproduced in the spec: a deferred claim replayed by core's own `/prompt` swallows an intervening `/dev-workflows:vuln` segment, because a sibling plugin's boundary is invisible to a single-plugin detector. 9000 tokens claimed where 5000 is correct.

- [ ] **Step 1: Ship the manifest**

`plugins/workflows-core/scripts/command-namespaces.json` — namespace → sorted command-name list, one entry per plugin in this marketplace that ships commands. It is **derived, never hand-maintained**: Step 5 makes the gate assert it against the tree in both directions.

- [ ] **Step 1a: Fix `cost-emission.md`'s own `--commands-dir`, which now points at the wrong plugin**

Line 78 passes `--commands-dir "${CLAUDE_PLUGIN_ROOT}/commands"`. That file is core's, and it is read **through the loader**, so `${CLAUDE_PLUGIN_ROOT}` expands to **core's** root — six utility commands — while the run emitting the entry is one of `dev-workflows`'s twenty. The boundary set is therefore resolved against the wrong plugin today. It is the same class as the `impl-maintenance.md` `${CLAUDE_PLUGIN_ROOT}/commands/` defect Task 5 repaired, and no assertion sees either, because core genuinely ships a `commands/` directory and the path resolves — just to the wrong six files. The §8 manifest supersedes the flag's purpose, so fix the two together rather than patching the flag and leaving the map to contradict it.

- [ ] **Step 2: Resolve against the map, not one plugin's set**

`command_marker` currently accepts a boundary only when `ns == plugin_name and rest in known`. It becomes: `ns` is a key of the manifest **and** `rest` is in that namespace's list. Both halves still resolve against a held set — nothing is parsed out of free text, which is what keeps the two safety properties intact.

- [ ] **Step 3: Carry the ceding plugin in the deferred record**

```json
{"command": "/prompt-grill-me", "plugin": "workflows-core", "plugin_version": "1.0.0", …}
```

Its purpose is **uniqueness, not resolvability** — matching by bare name across five plugins is unambiguous only because S1 gives each command one home, and this field makes that a guarantee rather than a coincidence. Update `cost-emission.md` §13.1 and §13.2 to state the widened rule and the new field.

- [ ] **Step 4: Author the four probe fixtures**

**The spec's four transcripts were never committed** — §8.6 records their *numbers*, not their files, and nothing matching `split*.jsonl` exists anywhere in the tree. So they are authored here, not adopted. Follow the existing pattern rather than shipping data files: `selftest()` already builds every fixture programmatically into a `tempfile.mkdtemp()` directory, and the four new cases join it the same way. Two discriminate: the segment case (`split2`) and the two safety cases (`split3`). Assert the exact numbers spec §8.2 and §8.4 recorded:

| Fixture | Assertion |
|---|---|
| segment case | claim 5000, remainder 4800, `/vuln` boundary seen |
| safety cases | bare `/upgrade` mints no boundary; `superpowers:implement` mints none |
| cross-plugin claim | matched |
| same-plugin claim | matched, segment terminates at the sibling boundary |

An implementation that widens namespaces without widening the per-namespace name sets **passes the safety case and fails the segment case** — that pairing is the point.

- [ ] **Step 5: Gate the manifest against the tree**

Inside `check-docs.sh`'s existing plugin loop, where `cmd_names` is already computed: assert the manifest's entry for this plugin's namespace equals its derived command inventory, in both directions. A few lines in the loop, not a new dispatched check.

- [ ] **Step 6: Run the gates plus the cost selftest.** Expected: all PASS.

- [ ] **Step 7: Commit**

```bash
git add plugins/workflows-core scripts/check-docs.sh
git commit -m "fix(cost): resolve a deferred boundary against every plugin's own command set"
```

---

### Task 7: Declare the dependency and close the increment

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`, `CHANGELOG.md`
- Modify: `plugins/workflows-core/CHANGELOG.md`
- Modify: `CLAUDE.md`, `.claude-plugin/marketplace.json`

**Interfaces:**
- Consumes: everything above
- Produces: the increment's user-visible contract

- [ ] **Step 1: Declare the dependency — and verify it, because a shipped file already asserts it**

**This step is load-bearing for a claim already in the tree.** Task 5 rewrote `workflows-core/references/dependencies.md` to state that `dev-workflows` *declares* `workflows-core` in `dependencies` — present tense, chosen over "will declare" to avoid the note-that-goes-stale class. No manifest carries the field today, so **that sentence is false until this step lands, and nothing gates it**: `validate-catalog.py` never reads a `dependencies` key and `check-docs.sh` does not compare prose to a manifest. The one earlier ruling in this increment that was written as prose rather than a checkbox (R3, the same file) was missed for two whole tasks. Verify explicitly after editing:

```bash
python3 -c "import json;d=json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'));print(d.get('dependencies','ABSENT'))"   # expect ['workflows-core']
```

Note that `dev-workflows`'s `keywords` list already contains the word "dependencies", so a bare `grep '"dependencies"'` reports a false positive. Test the parsed key, never the raw text.


```json
"dependencies": ["workflows-core"]
```

Bare name, tracking latest (S6). Mirror it in the plugin's `marketplace.json` entry if that file carries dependency data.

- [ ] **Step 2: Bump versions** — `dev-workflows` to `3.26.0` (minor, per S17), `workflows-core` stays `1.0.0`.

- [ ] **Step 3: Write both CHANGELOG entries**

`dev-workflows` 3.26.0's **first sentence carries the install command** (S17):

> Run `claude plugin install workflows-core@ihudak-plugins` — this release moves the shared reference corpus, five agents and six utility commands into a new `workflows-core` plugin, which `dev-workflows` now declares as a dependency.

Then list every moved command and its new plugin. Note that a declared dependency is auto-installed, so the explicit install is belt-and-braces for a machine that has not refreshed the catalogue.

**`workflows-core` 1.0.0's entry must record one breaking change of its own, which no task has written down yet:** `session-cost.py`'s `--commands-dir` flag is **removed**, not deprecated. It existed to supply one plugin's command set, which is precisely the assumption §8 had to abandon — a boundary now resolves against a namespace→command-set manifest covering every plugin. The removal is loud (an unknown flag is an error, not a silent misread) but it is real, and anyone invoking the script directly is affected. Say so plainly rather than letting it be discovered.

**Also record the cost-boundary fix itself in user-facing terms**: before it, a deferred claim replayed by a core command could absorb the spend of an intervening command from another plugin — never double-billing and never corrupting an entry already written, but silently misattributing between two entries of the same replay.

- [ ] **Step 4: Update `CLAUDE.md`**

**Ten reference paths in it are already stale** — measured, not estimated. Each names `plugins/dev-workflows/references/<f>.md` for a file now in `workflows-core`: `doc-structure-conventions`, `docs-grounding`, `finding-triage`, `implementation-format`, `instruction-file-maintenance`, `phase-handoff`, `prose-formatting`, `read-only-repos`, `source-truth`, `specs-repo-git`. Six others in the same file are correct and must not be touched: `bug-diagnosis`, `code-handoff`, `gate-ledger`, `release-note-types`, `repo-verification-gates`, `toolchain-preflight`. Re-derive rather than trusting this list — nothing gates a path in this file, which is why ten went stale unnoticed.


The workflow map, the command/agent/reference/skill counts, the "Active plugin" paragraph (now two active plugins), the reference-authority paragraphs that name paths inside `dev-workflows` for files that moved, and the citation convention under *Internal reference convention*. Re-derive every number against the tree; nothing in `CLAUDE.md` is gated.

- [ ] **Step 4a: Closing sweep — re-derive every carried defect, do not trust this list**

Three defects were deferred into Tasks 6 and 7 rather than fixed where they were found. Each is a checkbox in its owning step, but the one ruling in this increment that was written as prose instead of a checkbox (R3) was missed for two whole tasks — so this step re-derives all three against the tree before the increment is called done:

```bash
# 1. the dependency field the shipped dependencies.md already asserts (Task 7 step 1)
python3 -c "import json;print(json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')).get('dependencies','ABSENT'))"
# expect ['workflows-core'] -- and never grep the raw text: the keywords list contains the word

# 2. no core reference passes a --commands-dir that resolves to core (Task 6 step 1a)
grep -rn 'commands-dir .*CLAUDE_PLUGIN_ROOT' plugins/workflows-core/references/   # expect no hit

# 3. no CLAUDE.md reference path names a file that has moved (Task 7 step 4)
grep -o 'plugins/dev-workflows/references/[a-z-]*\.md' CLAUDE.md | sort -u \
  | while read -r f; do [ -f "$f" ] || echo "STALE: $f"; done                     # expect no output
```

- [ ] **Step 5: Run every gate one final time.** Expected: all PASS, 0 errors, 0 warnings.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(core): dev-workflows declares workflows-core as a dependency"
```

---

## Post-split follow-ups — the operator's own bug list

Two defects found while using pre-split `dev-workflows`, recorded here because both land in **`workflows-core`** and so become fixable the moment this increment merges. They are **not** in scope for increment 2 — the split changes no behaviour (§9) — and neither is a consequence of the split.

**Status, kept current — a list that does not say what is done is a list nobody trusts.** PS4–PS9 are **fixed and merged**: PS8 at `6c698fd`, PS5/PS7 at `0fe3b39`, PS6 at `5200870`, PS4 at `09c8cfa`, PS9's sweep at `fa5d1bf`, all under merge `b07d78d`. PS1, PS2, PS3 and PS10 remain **open**, deliberately, for the reason given at the foot of this list.

**PS1 — a wrong `$SPECS_PATH` and a read-only specs mount produce the same symptom: silence.** `environment.md` deliberately tolerates an unwritable `.git`, which is right, because a read-only mount is normal here. But it also swallows **no `.git` at all**, which is never normal. The run writes its deliverables, commits nothing, opens no pull request, and ends on a terminal "gate failed" line that never names the cause — after `brd-reader` has read a 30-page document and a human has walked its defect candidates. The whole cost is paid before the failure surfaces. The fix is a Phase 0 stop that distinguishes *unwritable* from *absent* and names which it found; the guard, the preflight and the handoff entry points are all core's now.

**PS2 — `/frames` cannot adopt an existing index under another name.** An operator who already keeps one must hand-convert it or lose it. `/frames` and `grounding-format.md` are both core's as of this increment (S13).

**PS3 — a foreign marketplace's command between a cede and its replay has its spend absorbed** (spec §8.7). Found by increment 2's review of its own cost fix, and deliberately not fixed there. **Pre-existing, not split-caused**: the pre-split selftest asserts the same behaviour as intended. **Not blocked by the split either** — the cost subsystem is entirely in `workflows-core` from increment 2 onward and moves in neither remaining increment. Needs a decision before a patch: may a foreign command cut a window without being claimable? One test answers both questions today and they pull opposite ways.

**PS4 — `ready.md` quotes `workflows-core:phase-handoff` §4.3's consent array instead of citing it, in two places.** The standard array's second option promises that "the next phase will stop until this is on main", which is false for `_readiness.md`: §3.4's table has no row for it and no command gates on it. §4.3 already directs that such an artifact gets the other variant. Two instances — the Phase 5 consent choice and the Phase 5 step 4 report template. This is the same defect as PS7 seen from the command side.

**PS5 — §4.3's has-a-row / has-no-row binary has no branch for *read but never gated*.** `/implement` Phase 0.5 does read a co-located `_readiness.md` and surfaces a one-line advisory on `NOT-SUPPORTED`/`PARTIAL`, explicitly never blocking (`implement.md:113-117`). So the no-row variant's own wording — "nothing downstream reads this" — is also untrue for this artifact. Both variants are wrong for a third case neither anticipates. Fix the taxonomy, not the wording of one branch.

**PS6 — `phase-handoff` §2.1's gate never probes for a remote.** It tests path, git-dir, `.git` writability and `specs_git: blocked`, then §2.5 pushes. On a repo with no `origin` the run therefore offered a branch-commit-push-PR option marked **(Recommended)** that could not possibly succeed, and only avoided misleading the operator because the command had separately reasoned about the missing remote in its option text. The primitive already exists twenty lines away in §2.6, which derives `OWNER_REPO` from `git remote get-url origin`.

**PS7 — two live contradictory instructions inside `phase-handoff.md`.** §4.3 says "Every producing command presents this array verbatim"; §5 rule 4 says never to copy a rule into a command, because the copy goes stale. Both cannot be followed. `CLAUDE.md`'s own `instruction-file-maintenance` rule names this exact shape — *"two live contradictory instructions is a defect"* — so this is the reference that defines the rule breaking it. Resolve toward citing: name which variant applies, never reproduce the array. Blast radius measured during the run: the standard array is quoted across the producer set while §4.3's literal variant string has **zero** users.

**PS8 — `follow-ups.md` is written to a path `commit-artifacts` cannot stage, and this is the priority of the batch.** `workflows-core:followup-emission` §2 places it at `<PRD-dir>/follow-ups.md`; `workflows-core:specs-repo-git` §2.1's bounded set covers `dev-workflows/**`, `implementation.md` and `release-notes.md` only. Verified by classification, not by inference: that path matches neither regex, so it is classified `OTHER` and never staged — leaving it permanently dirty, which fires §3.3's G1 guard on **every later run of any of the twenty-four callers**, suppressing the leftover flush and the branch disposition for the rest of the session. §2.1 documents having already fixed this exact failure twice. Two traces confirm it is drift from the follow-up ladder being cut from four rungs to two: §2.1's own comment still lists follow-ups in tier 1, and its source citation points at "followup-emission.md §4", a section now titled *What no longer produces follow-ups*.

**PS9 — only `/ready` was checked against §3.4's table.** Fourteen other producers call `handoff-to-main`; each one's deliverable needs the same check before PS4–PS7 are applied to it. A `check-docs.sh` relation binding each producer's declared deliverable to its §3.4 row is derivable — but measure its false-positive rate against the tree first, as this repo requires and has twice enforced.

**How PS4–PS9 were found, which is worth as much as the findings.** They came out of one live `/ready` run in a container, and every one was found by *executing* a step rather than reading it — PS8 in particular by classifying the real path against the real regexes. None is caused by the split; all predate increment 2. The run also corrected one of its own claims mid-flight (PS5), which is why that finding is precise rather than approximate.

**PS10 — `workflows-core`'s own six commands cite their bundled content by `${CLAUDE_PLUGIN_ROOT}` path, which `CLAUDE.md` says does not expand in a slash-command body.** Measured: 54 citations across `frames.md` (20), `feedback.md` (10), `prompt.md` (9), `prompt-grill-me.md` (7), `prompt-brainstorm.md` (5) and `statusline.md` (3). Pre-existing and byte-identical on `main` before the split, so not a regression — and increment 2 converted every *`dev-workflows`* command to the loader while leaving the plugin that **ships** the loader unconverted. **Its practical impact is genuinely unclear and must be measured before it is "fixed":** a live `/workflows-core:statusline` run installed its script correctly, so either the citation does expand in that position, or the model resolved the path by other means. Establish which before changing 54 sites. The same question recurs for every command moved in increments 3 and 4.

**Why PS1, PS2, PS3 and PS10 are deferred rather than forgotten — one reason, and it is the split's own.** Non-goal §9 of the design says the split makes **no behaviour changes**, so that a break can be bisected to the move that caused it. PS1 (a Phase 0 stop that distinguishes an absent `.git` from an unwritable one) and PS2 (teaching `/frames` to adopt an existing index) are behaviour changes. PS3 needs a *decision* first — may a foreign command cut a window without being claimable? — and then a fixture rewrite, because the current fixtures assert the conflated behaviour explicitly. PS10 needs a measurement first. Interleaving any of them with increments 3 and 4 would put behaviour changes inside the window the no-behaviour-change rule exists to keep clean.

**So: after increment 4, as one batch.** All four live in `workflows-core`, which moves in neither remaining increment, so none of them blocks or is blocked by the rest of the split. If a live run makes one of them urgent before then, take it on its own branch and say in the commit that it is deliberately outside the split's no-behaviour-change rule.

**PS11 — `/document` direct mode has no writability gate, and fails late.** Found by increment 3's live verification against a read-only docs mount. Keyed mode gates it at `commands/document.md:72` — `test -w <docs_repo_path>` and a named `REPO_NOT_WRITEABLE` stop in Phase 0. Direct mode has neither, and `test -w` occurs exactly once in the file. So a read-only mount surfaces as a raw `EROFS` from the editor at Phase 3, **after** the exploration subagent has run and the plan has been built. Not split-caused — direct mode never resolved a docs repo. It is **PS1's twin**: the whole cost is paid before the failure surfaces, and the error names a temp file rather than the condition. Fix: a Phase 0 `test -w` in Mode B, reusing the stop Mode A already has.

**PS12 — the `${CLAUDE_PLUGIN_ROOT}` non-expansion claim may be stale, but the evidence does not settle it, and this also decides PS10.** `CLAUDE.md` states *"This variable does NOT expand in slash-command bodies"*, and `workflows-core`'s `model-routing` skill gives that as its **reason for existing**. Increment 3's verification observed `document.md`'s 33 literal tokens arriving **expanded**, which would falsify both. **But the command was loaded through the `Skill` tool — `Skill(docs-workflows:document)` — not by typing the slash command**, and a skill body has always expanded the variable. The observation is therefore equally consistent with the claim still holding and the expansion coming from the invocation path.

**The discriminating test is one line:** type `/docs-workflows:document <path>` literally, as a slash command, and see whether the body arrives expanded. Until that runs, change nothing — "fixing" a true invariant on a confounded reading is worse than leaving a stale one standing. If the variable does expand, **PS10 is not a defect** and `workflows-core`'s 54 self-citations work; if it does not, they are inert.

**Either way the loader's own rationale is untouched.** It exists because `${CLAUDE_PLUGIN_ROOT}` resolves to the **reading** plugin, which does not carry another plugin's corpus — not because it fails to expand. That reasoning, and check 16, stand regardless.

**PS10 and PS12 — SETTLED, and closed.** A live slash-command invocation (not the Skill tool, so not confounded) proved `${CLAUDE_PLUGIN_ROOT}` **does** expand in slash-command bodies: all 33 literal tokens in `docs-workflows`'s `document.md` arrived as absolute paths, quoted on-disk against received. Two details make it conclusive rather than suggestive — the substitution is **specific to that variable** (`${DOCS_PATH:-…}` and `${REPOS_PATH:-…}` arrived literal in the same body, so this is a deliberate harness feature, not general expansion), and it resolved to the **working tree** rather than the cache, matching the directory-source marketplace. Consequences: **PS10 is not a defect** — the 54 self-citations in `workflows-core`'s commands work, as do 208 in `dev-workflows` and 48 in `docs-workflows`. `CLAUDE.md`'s claim and the `model-routing` skill's stated reason for existing were both false and are corrected. **The loader's own rationale is untouched**: it exists because the variable resolves to the *reading* plugin, which does not carry another plugin's corpus — line 9 of the received body demonstrates it, expanding to `…/plugins/docs-workflows` in the very sentence explaining why that path cannot reach core.

**PS13 — direct mode anchors `repo_root` on the current working directory, not on the docs repo it was given.** Observed live: invoked as `/docs-workflows:document /workspace/docs`, Phase 0's toolchain preflight and `repo_verification_gates` were derived from the **plugins repo** (the cwd) while the style check ran against `/workspace/docs`. Mode B has no docs-repo resolution step at all. This subsumes **PS11**, which is its narrowest symptom: a missing `test -w` is one consequence of never resolving the repo. Not split-caused.

**PS14 — the style gate's `findings:` count is a sample, not a measurement.** Two runs of `docs-style-checker` in one session, against byte-identical files, returned 2 findings then 3 — and the same defect came back under two different rule ids (`Prose.Formatting.CodeInText`, then `Prose.Formatting.CodeFormatting`). Expected of an LLM-based checker rather than a deterministic linter, but `gate-ledger.md` records that number as if it were reproducible. Either the ledger should say what the number is, or it should stop recording it.

**PS15 — nothing gates an agent dispatching outside its sanctioned set.** `docs-style-checker` self-disclosed mis-dispatching a stray agent mid-run with a placeholder prompt; its only sanctioned dispatch is `prose-style:prose-style-checker`. It reports that agent did no work. The disclosure is the good part — but an agent carrying `Task` can dispatch anything, and no check in `scripts/` looks at what an agent dispatches, only at whether a named `subagent_type` resolves. Worth measuring before gating, per this repo's own record on widenings.

**Smaller items, recorded so they are not rediscovered.** Two further bare `doc-fixer` mentions in `document.md` (~`:827`, `:831`) left because the namespaced dispatch sits in the adjacent bullet; three borderline "this plugin" sites outside the eight that were fixed (`grounding-format.md:280`, `cost-emission.md:3`, `phase-handoff.md:184`); neither `session-cost.md` page mentions the namespace discipline; §4.0's artifact register is derived but hand-held, so adding a reader to an artifact silently invalidates a row; and the cleanup and follow-up batches carry no CHANGELOG entry or version bump, which is a release decision rather than a defect. None waits on increments 3 or 4.

## Verification (after the branch is green, before the merge)

These cannot run inside the implementation session and are not subagent tasks.

1. **Fresh session.** Skill discovery is bound to session start (spec §5): a newly installed skill returns `Unknown skill` until a new session begins. Every check below runs in a session started *after* installation.
2. **Dependency auto-install.** On a machine with neither plugin: `claude plugin install dev-workflows@ihudak-plugins` and confirm `workflows-core` arrives with it and neither reports `dependency-unsatisfied`.
3. **The loader resolves.** In a fresh session, run a `dev-workflows` command whose Phase 0 loads a core reference — `/dev-workflows:ready <ADDRESS>` reaches `addressing`, `specs-repo-git` and `phase-handoff` — and confirm the loaded content appears and the run behaves as it did before the split.
4. **Cross-plugin agent dispatch.** Confirm a `dev-workflows` command dispatching `workflows-core:impl-maintenance` succeeds.
5. **A moved command runs from its new home:** `/workflows-core:frames <ADDRESS>`.
6. **The cost boundary, end to end:** cede a session with `/prompt-grill-me`, run a `dev-workflows` command that emits no cost entry, then a cost-emitting one, and confirm the replayed claim's segment terminates at the sibling boundary.
