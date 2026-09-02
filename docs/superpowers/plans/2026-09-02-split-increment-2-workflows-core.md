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
- All four gates green before the PR: `./scripts/check-docs.sh --root .`, `./scripts/check-docs.sh --selftest`, `./scripts/check-id-grammar.sh --root .` (and `--selftest`), `python3 scripts/validate-catalog.py`.
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

**Documentation pages (6 command pages + 6 reference pages):** `docs/commands/{feedback,frames,prompt,prompt-brainstorm,prompt-grill-me,statusline}.md`; `docs/reference/{model-routing,session-cost,session-feedback,follow-ups,resume-and-checkpoints,commit-convention}.md`

### Stays in `dev-workflows` (36 reference files)

**Bound for `pm-workflows` (9):** `ard-format`, `brd-format`, `bundle-packaging`, `coverage-ledger-format`, `customer-review-schema`, `decision-register-format`, `idea-format`, `interview-tagging`, `specification-format`
**Bound for `dev-workflows` (15):** `bug-diagnosis`, `code-handoff`, `context-management`, `design-format`, `workflow-states`, `fix-vuln/build-systems`, `fix-vuln/nvd-api`, `handoff/test-baseliner`, `handoff/upgrade-executor`, `handoff/upgrade-planner`, `handoff/vuln-fixer`, `handoff/vuln-research`, `upgrade/compatibility`, `upgrade/ecosystems`, `upgrade/lts-sources`
**Bound for `docs-workflows` (12):** `docs-profiles/anchor-conventions`, `docs-profiles/changelog-guidelines`, `docs-profiles/docs-profile-schema`, `docs-profiles/frontmatter-guidelines`, `docs-profiles/render-verification`, `finish-and-handoff`, `gate-ledger`, `handoff/diff-summarizer`, `handoff/release-notes-writer`, `release-note-types`, `repo-verification-gates`, `toolchain-preflight`

Also staying: the `docs-frontmatter` skill (`/docs-profile` only), `specification-to-html.py` (`/specify` only), all five hooks (`preload-context.sh` matches only `/implement|/document|/epics|/release-notes|/vuln|/upgrade`, none of which move), and the non-markdown files under `references/docs-profiles/`.

**After this increment `dev-workflows` ships 20 commands, 31 agents, 36 reference files, 1 skill, 1 script, 5 hooks.**

### Four rulings that shaped this list

**R1 — `doc-fixer` moves to core, though the spec's §2 table counted it under pm.** Its two consumer groups are pm (`/epics`) and docs (`/document`). Both leave `dev-workflows` in later increments, so leaving it behind would strand an agent in a plugin that never dispatches it. Cost if wrong: one agent sits in core with two dependents instead of one — the same place S4 would put it anyway. Core therefore ships **5** agents, not the spec's measured 4; amend §2's table row rather than the tree.

**R2 — `upgrade/compatibility.md` stays in `dev-workflows`.** Its only core-side citation is `impl-maintenance.md:100`, inside a report template as the *example* path in `[path, e.g. …]`. An example is not a load. That citation is rewritten to name a core reference instead.

**R3 — `dependencies.md` moves to core and is corrected in the same commit.** It is loaded by nothing (`grilling-technique.md` names it in prose) but its subject is cross-plugin dependency convention, which is now core's. Its standing claim — that no command hard-requires another plugin "since Claude Code plugins express no dependency-manifest field" — is **false as of this increment**, which declares exactly such a field. This is the CLAUDE.md "a note saying a feature does not ship, left standing beside the now-shipped feature" case.

**R4 — a citation that would dangle after the move is demoted to a bare name, never promoted.** Nine sites, all pointer-shaped, listed in Task 4 step 4.

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
  scripts/session-cost.py           ← moved in Task 3 (with cost-emission.md), extended in Task 7
  scripts/command-namespaces.json   ← new manifest (Task 7)
  scripts/statusline-command.sh     ← moved in Task 5 (with /statusline)
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

### Task 3: Move the references and agents into core

**Files:**
- Move (`git mv`): 28 reference files + `cost-prices.yaml` + `scripts/session-cost.py`, 5 agent files — lists in *The measured allocation*
- Modify: `scripts/check-docs.sh` (`CORE_PLUGIN_REL`, `COST_PLUGIN_RELS`, `HANDOFF_PLUGIN_RELS`)
- Modify: both plugins' `docs/reference/{agents,references,environment}.md` and prose counts

**Interfaces:**
- Consumes: Task 2's `CORE_PLUGIN_REL`
- Produces: core's reference corpus and agent set, at their final paths

**This task deliberately leaves the tree red.** `dev-workflows` is left citing 767 paths that no longer exist; Task 4 rewrites them. Do not attempt partial rewrites here — a half-swept tree is harder to reason about than a fully broken one.

- [ ] **Step 1: Move the files with `git mv`**, preserving `references/handoff/` and `references/model-routing/` as directories inside core. Move `cost-prices.yaml` alongside `cost-emission.md`.

**`scripts/session-cost.py` moves in this task, not with the other script in Task 5.** `cost-emission.md` cites it as `${CLAUDE_PLUGIN_ROOT}/scripts/session-cost.py`, and that path is correct only while the two sit in the same plugin — so the script travels with its citing reference. `statusline-command.sh` is cited by `commands/statusline.md` and travels with *it*, in Task 5, for exactly the same reason. Nothing gates a script path, so both pairings are held by this instruction alone.

- [ ] **Step 2: Flip the gate config**

```bash
CORE_PLUGIN_REL="${CORE_PLUGIN_REL:-plugins/workflows-core}"
COST_PLUGIN_RELS="${COST_PLUGIN_RELS:-plugins/dev-workflows plugins/workflows-core}"
HANDOFF_PLUGIN_RELS="${HANDOFF_PLUGIN_RELS:-plugins/dev-workflows plugins/workflows-core}"
```

Both subsystems are now shipped by core *and* still called from `dev-workflows`, so both plugins are declared. The both-directions applicability assertion added in increment 1 checks exactly this.

- [ ] **Step 3: Update both inventories**

`plugins/workflows-core/docs/reference/agents.md` gains a `` | `<name>` `` row per moved agent; `references.md` gains a row per **flat** file plus `` `handoff/` (2) `` and `` `model-routing/` (1) `` — N is the **markdown-only** count, so `cost-prices.yaml` is counted nowhere. `plugins/dev-workflows/docs/reference/*` loses exactly those rows.

- [ ] **Step 4: Update `environment.md` on both sides**

Check 5 runs in both directions, so this move fires it **twice**. Re-derive each plugin's variable set from what its files now read — `$SPECS_PATH`, `$REPOS_PATH`, `$DOCS_PATH` and the rest follow their references — and write only what is read.

- [ ] **Step 5: Update every prose count** in both plugins' `docs/README.md` and plugin `README.md`: agents, reference files, skills, commands.

- [ ] **Step 6: Verify the move landed, then commit**

```bash
ls plugins/workflows-core/references/*.md | wc -l          # expect 25
ls plugins/workflows-core/references/handoff/*.md | wc -l  # expect 2
ls plugins/workflows-core/agents/*.md | wc -l              # expect 5
ls plugins/dev-workflows/agents/*.md | wc -l               # expect 31
find plugins/dev-workflows/references -name '*.md' | wc -l # expect 36
git add -A plugins/workflows-core plugins/dev-workflows scripts/check-docs.sh
git commit -m "refactor(core): move the shared reference corpus and five agents into workflows-core"
```

The gate is expected to FAIL after this commit. Record the failure count in the ledger; Task 4 must return it to zero.

---

### Task 4: The loader skill and the citation sweep

**Files:**
- Create: `plugins/workflows-core/skills/reference/SKILL.md`
- Modify: every `plugins/dev-workflows/commands/*.md` and `agents/*.md` carrying a core citation (52 files, 767 sites), plus 55 sites inside the references that stayed
- Modify: 9 sites inside moved core references that now point at files left behind

**Interfaces:**
- Consumes: Task 3's moved corpus
- Produces: a green tree; the `workflows-core:reference` skill contract every later plugin uses

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

- [ ] **Step 6: Sweep the prose that describes what left**

Ungated failure mode, per spec §6. In `plugins/dev-workflows/docs/**` and `plugins/dev-workflows/README.md`, find every sentence describing a moved agent, reference or command and rewrite it to name the plugin that now ships it. Search by name, not by line number.

- [ ] **Step 7: Run the gates.** Expected: all PASS — this is the task that returns the tree to green.

- [ ] **Step 8: Commit**

```bash
git add -A plugins/
git commit -m "refactor(core): route every cross-plugin reference read through the loader skill"
```

---

### Task 5: Move the six commands, the model-routing skill and the statusline script

**Files:**
- Move: 6 command files, `skills/model-routing/`, `scripts/statusline-command.sh`, 6 `docs/commands/` pages, 6 `docs/reference/` pages
- Modify: both plugins' `docs/README.md`, `docs/workflow.md`, plugin `README.md`, `docs/roles-and-phases.md`

**Interfaces:**
- Consumes: Task 4's green tree
- Produces: `dev-workflows` at 20 commands, core at 6

- [ ] **Step 1: `git mv` the commands and their documentation pages**, then the `model-routing` skill directory and `scripts/statusline-command.sh` (`session-cost.py` moved in Task 3).

- [ ] **Step 2: Fix the `model-routing` skill invocation namespace**

Every pipeline command invokes it by name. All 21 call sites move:

```bash
grep -rl 'skill: "dev-workflows:model-routing"' plugins/ | xargs -r sed -i 's|dev-workflows:model-routing|workflows-core:model-routing|g'
```

- [ ] **Step 3: Update core's `docs/workflow.md` mermaid diagram**

Check 15 asserts every command appears **inside the diagram**, not in prose below it. All six, by name.

- [ ] **Step 4: Remove the six commands from `dev-workflows`'s three listing surfaces** — `docs/README.md`, the plugin `README.md`, and `docs/workflow.md`'s mermaid diagram. Check 15 is **forward-only**: a diagram still naming a departed command passes silently, so this is by hand.

- [ ] **Step 5: Update every count sentence** in both plugins: `20 slash commands` / `6 slash commands`, skills, agents, references, and the cost-emitting-set size.

- [ ] **Step 6: Run the gates.** Expected: all PASS.

- [ ] **Step 7: Commit**

```bash
git add -A plugins/
git commit -m "refactor(core): move the six utility commands and model-routing into core"
```

---

### Task 6: The loader-contract gate

**Files:**
- Modify: `scripts/check-docs.sh` (new check + its selftest cases, and the check count in the header comment)

**Interfaces:**
- Consumes: Task 4's loader invocations
- Produces: a build-time failure for an unresolvable loader argument or an unreached core reference

- [ ] **Step 1: Write the check, both directions**

Every `args:` string passed to `workflows-core:reference` names a reference that exists in `$CORE_PLUGIN_REL/references/` (first token, plus `.md`), and every markdown file in `$CORE_PLUGIN_REL/references/` is named by at least one caller across `PLUGIN_RELS`. Parse the first whitespace-separated token of the argument, so the entry-point form is handled by the same code path.

- [ ] **Step 2: Selftest cases, paired red and green** — an unresolvable argument fires; an unreferenced core reference fires; the entry-point form does **not** fire; a correct tree passes. The entry-point green case is the discriminator: an implementation that matches the whole argument string instead of its first token passes both red cases and fails that one.

- [ ] **Step 3: Update the check count** in the script header and in `CLAUDE.md`'s enumeration of what the gate checks.

- [ ] **Step 4: Run the gates.** Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/check-docs.sh CLAUDE.md
git commit -m "test(gate): assert the loader contract in both directions"
```

---

### Task 7: The cost boundary fix (spec §8)

**Files:**
- Create: `plugins/workflows-core/scripts/command-namespaces.json`
- Modify: `plugins/workflows-core/scripts/session-cost.py` (`load_command_names`, `command_marker`, the deferred-record writer, `--selftest`)
- Modify: `plugins/workflows-core/references/cost-emission.md` (§13.1 record shape, §13.2 boundary rule)
- Modify: `scripts/check-docs.sh` (manifest-equals-inventory check, inside the existing loop)

**Interfaces:**
- Consumes: Task 5's moved `session-cost.py`
- Produces: a boundary detector that resolves `<any known plugin>:<that plugin's known command>`

The defect, reproduced in the spec: a deferred claim replayed by core's own `/prompt` swallows an intervening `/dev-workflows:vuln` segment, because a sibling plugin's boundary is invisible to a single-plugin detector. 9000 tokens claimed where 5000 is correct.

- [ ] **Step 1: Ship the manifest**

`plugins/workflows-core/scripts/command-namespaces.json` — namespace → sorted command-name list, one entry per plugin in this marketplace that ships commands. It is **derived, never hand-maintained**: Step 5 makes the gate assert it against the tree in both directions.

- [ ] **Step 2: Resolve against the map, not one plugin's set**

`command_marker` currently accepts a boundary only when `ns == plugin_name and rest in known`. It becomes: `ns` is a key of the manifest **and** `rest` is in that namespace's list. Both halves still resolve against a held set — nothing is parsed out of free text, which is what keeps the two safety properties intact.

- [ ] **Step 3: Carry the ceding plugin in the deferred record**

```json
{"command": "/prompt-grill-me", "plugin": "workflows-core", "plugin_version": "1.0.0", …}
```

Its purpose is **uniqueness, not resolvability** — matching by bare name across five plugins is unambiguous only because S1 gives each command one home, and this field makes that a guarantee rather than a coincidence. Update `cost-emission.md` §13.1 and §13.2 to state the widened rule and the new field.

- [ ] **Step 4: Adopt the four probe fixtures**

Add the spec's four transcripts as `--selftest` fixtures. Two discriminate: the segment case (`split2`) and the two safety cases (`split3`). Assert the exact numbers the spec recorded:

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

### Task 8: Declare the dependency and close the increment

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`, `CHANGELOG.md`
- Modify: `plugins/workflows-core/CHANGELOG.md`
- Modify: `CLAUDE.md`, `.claude-plugin/marketplace.json`

**Interfaces:**
- Consumes: everything above
- Produces: the increment's user-visible contract

- [ ] **Step 1: Declare the dependency**

```json
"dependencies": ["workflows-core"]
```

Bare name, tracking latest (S6). Mirror it in the plugin's `marketplace.json` entry if that file carries dependency data.

- [ ] **Step 2: Bump versions** — `dev-workflows` to `3.26.0` (minor, per S17), `workflows-core` stays `1.0.0`.

- [ ] **Step 3: Write both CHANGELOG entries**

`dev-workflows` 3.26.0's **first sentence carries the install command** (S17):

> Run `claude plugin install workflows-core@ihudak-plugins` — this release moves the shared reference corpus, five agents and six utility commands into a new `workflows-core` plugin, which `dev-workflows` now declares as a dependency.

Then list every moved command and its new plugin. Note that a declared dependency is auto-installed, so the explicit install is belt-and-braces for a machine that has not refreshed the catalogue.

- [ ] **Step 4: Update `CLAUDE.md`**

The workflow map, the command/agent/reference/skill counts, the "Active plugin" paragraph (now two active plugins), the reference-authority paragraphs that name paths inside `dev-workflows` for files that moved, and the citation convention under *Internal reference convention*. Re-derive every number against the tree; nothing in `CLAUDE.md` is gated.

- [ ] **Step 5: Run every gate one final time.** Expected: all PASS, 0 errors, 0 warnings.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(core): dev-workflows declares workflows-core as a dependency"
```

---

## Verification (after the branch is green, before the merge)

These cannot run inside the implementation session and are not subagent tasks.

1. **Fresh session.** Skill discovery is bound to session start (spec §5): a newly installed skill returns `Unknown skill` until a new session begins. Every check below runs in a session started *after* installation.
2. **Dependency auto-install.** On a machine with neither plugin: `claude plugin install dev-workflows@ihudak-plugins` and confirm `workflows-core` arrives with it and neither reports `dependency-unsatisfied`.
3. **The loader resolves.** In a fresh session, run a `dev-workflows` command whose Phase 0 loads a core reference — `/dev-workflows:ready <ADDRESS>` reaches `addressing`, `specs-repo-git` and `phase-handoff` — and confirm the loaded content appears and the run behaves as it did before the split.
4. **Cross-plugin agent dispatch.** Confirm a `dev-workflows` command dispatching `workflows-core:impl-maintenance` succeeds.
5. **A moved command runs from its new home:** `/workflows-core:frames <ADDRESS>`.
6. **The cost boundary, end to end:** cede a session with `/prompt-grill-me`, run a `dev-workflows` command that emits no cost entry, then a cost-emitting one, and confirm the replayed claim's segment terminates at the sibling boundary.
