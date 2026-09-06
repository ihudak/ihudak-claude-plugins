# Increment 4 — `product-workflows` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the twelve product-management commands, their twelve agents and their nine references out of `dev-workflows` into a new `product-workflows` plugin, leaving `dev-workflows` as the five code-facing commands and nothing else — the last structural increment of the five-plugin split.

**Architecture:** `product-workflows` declares `workflows-core` and `prose-style` as dependencies, exactly as `docs-workflows` does. The move is a `git mv` of a partition that measurement shows is **exact**: no agent and no reference is shared between the pm and dev groups, so every `${CLAUDE_PLUGIN_ROOT}/references/<name>` citation among the moving files stays correct by construction, because the citing file and the cited file move together. The rewrite surface is therefore small and mechanical — 38 lines of `dev-workflows:<token>` that must become `product-workflows:<token>` — plus one bare-basename cross-boundary citation the loader gate cannot see.

**Tech Stack:** Markdown plugin content; `bash` gates under `scripts/`; `python3` for `validate-catalog.py`; git.

**Spec:** `docs/superpowers/specs/2026-09-02-marketplace-split-design.md`

---

## Global Constraints

Copied verbatim from the spec's decision table and this repo's `CLAUDE.md`. Every task's requirements implicitly include this section.

- **S1 — five plugins.** `workflows-core`, `product-workflows`, `dev-workflows`, `docs-workflows`, `guideline-reviewers`. After this increment all five exist and `dev-workflows` is simply what remains — there is no fifth structural step.
- **S4 / S16 — a file or agent moves to core when its second consumer group *actually exists*, never in anticipation of one.** `design-grounder` has one consumer group today (`/brd-ground`, pm) and therefore moves **to `product-workflows`**, not to core.
- **S8 — `dev-workflows` goes to 4.0.0; `product-workflows` starts at 1.0.0.** A version describes a plugin's own interface, not the provenance of its files.
- **S12 — `prose-style` is a declared dependency of `product-workflows`, and the graceful-skip branches are deleted.** Increment 3 retired `docs-workflows`'s share; increment 4 inherits the balance in `/epics`, `/create-prd`, `/update-prd` and their documentation pages. **Count statements, not forks** — the sentences describing the branch are the half that goes stale silently, because nothing gates them.
- **S13 — `design-grounder` stays with the pm route**; `/frames` and `grounding-format.md` are already in core and do not move again.
- **S14 — the split is a breaking change requiring user action, and the CHANGELOG says so in a migration note** listing every moved command and its new plugin, plus the one-line install for each.
- **S18 — nothing is released while a known defect is open.** The release that publishes this work (4.0.0, per S17) is gated on the follow-up ledger being empty, not on the increments being done. **Check the ledger before tagging, not before merging.** This plan therefore records defects it does not fix; it does not stop for them.
- **`${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin.** A dependency grants installation, never file access. A shared reference is reached only through `Skill(skill: "workflows-core:reference", args: "<name>")`. This variable **does** expand in slash-command bodies (verified live; PS12) — so a command's own-plugin `${CLAUDE_PLUGIN_ROOT}/references/<name>` citation is load-bearing and correct, and must not be "fixed" into a loader call.
- **Seven CI gates, taken from `.github/workflows/validate-catalog.yml` and never from this plan:** `validate-catalog.py --selftest`, `validate-catalog.py --root .`, `check-id-grammar.sh --selftest`, `check-id-grammar.sh --root .`, `check-docs.sh --selftest`, `check-docs.sh --root .`, `session-cost.py --selftest`. Run all seven, by reading that workflow file, before reporting any task green.
- **`git add -A` is never issued at repository scope.** Stage explicit paths. This rule is in `workflows-core:specs-repo-git` §1 rule 2 and was violated three times in increment 2 — every violation swept an unrelated file into a commit.
- **A plugin `description` is a stable capability blurb, never a changelog.** Hard budget 1024 characters in both `plugin.json` and the `marketplace.json` entry; `validate-catalog.py` fails above it and warns above 900.
- **No page under `docs/` may name the marketplace or the container repo** (`getting-started.md` excepted, pinned by check 7). Check 10 enforces it.
- **No text file under any plugin may write a tracker's name** without a `<!-- vendor-token-ok: <why> -->` marker on the line or its opening fence. Check 13 enforces it.

---

## The measured allocation

Re-derived against the tree at `3d47ff1` by dispatch and citation, **not** taken from the spec's §2 table. The spec's pre-split figures have been wrong at every increment so far and are wrong again here: §2 says eight references, and the tree says nine.

**Commands — 12 move, 5 stay (17 total):**

| → `product-workflows` | stays in `dev-workflows` |
|---|---|
| `/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/epics`, `/brd-intake`, `/brd-ground`, `/brd-split`, `/brd-interview`, `/brd-package`, `/brd-reconcile` | `/design`, `/implement`, `/ready`, `/upgrade`, `/vuln` |

**Agents — 12 move, 12 stay (24 total). Zero multi-group agents.**

| → `product-workflows` | stays in `dev-workflows` |
|---|---|
| `ard-reviewer`, `brd-package-reviewer`, `brd-reader`, `code-grounder`, `customer-review-reader`, `design-grounder`, `epic-reviewer`, `epic-writer`, `grounding-verifier`, `idea-reader`, `prd-reviewer`, `spec-reviewer` | `code-review`, `design-reviewer`, `interface-designer`, `readiness-reviewer`, `review-fixer`, `risk-planner`, `test-baseliner`, `test-writer`, `upgrade-executor`, `upgrade-planner`, `vuln-fixer`, `vuln-research` |

**No agent dispatches another agent** — verified by scanning `agents/` for `subagent_type` and for any plugin-qualified token resolving to a sibling agent file. Both come back empty, so the attribution is direct and needs no transitive closure. `test-baseliner`'s "via `upgrade-executor` / `vuln-fixer`" in `CLAUDE.md` describes the *command* dispatching it around those agents, not the agents dispatching it.

**References — 9 move, 15 stay (24 total). Zero multi-group references on the strict scan.**

| → `product-workflows` (9) | stays in `dev-workflows` (15) |
|---|---|
| `ard-format.md`, `brd-format.md`, `bundle-packaging.md`, `coverage-ledger-format.md`, `customer-review-schema.md`, `decision-register-format.md`, `idea-format.md`, `interview-tagging.md`, `specification-format.md` | `bug-diagnosis.md`, `code-handoff.md`, `context-management.md`, `design-format.md`, `workflow-states.md`, `fix-vuln/build-systems.md`, `fix-vuln/nvd-api.md`, `handoff/test-baseliner.md`, `handoff/upgrade-executor.md`, `handoff/upgrade-planner.md`, `handoff/vuln-fixer.md`, `handoff/vuln-research.md`, `upgrade/compatibility.md`, `upgrade/ecosystems.md`, `upgrade/lts-sources.md` |

**Why this partition makes the move cheap:** a same-plugin reference is cited `${CLAUDE_PLUGIN_ROOT}/references/<name>.md`, and that variable resolves to the reading plugin. Because the partition is exact, every such citation among the moving files points at a file that moves with it — so the citation is correct before and after, untouched. Do **not** convert these into loader calls.

**The one thing the strict scan missed.** A loose scan for bare basenames found exactly one cross-group citation: `plugins/dev-workflows/commands/ready.md:237` cites `` `ard-format.md` `` as a parenthetical pointer to the `grounded_repos:` frontmatter field. `/ready` stays in dev; `ard-format.md` moves to pm. This is precisely the **bare-basename class** `CLAUDE.md` names as undecidable by pattern and left to review, and it is the reason this plan runs a loose scan at all — check 16 gates the `args:` and `${CLAUDE_PLUGIN_ROOT}` forms and is blind to this one.

**Hooks — all three stay in `dev-workflows` for now** (`preload-context.sh`, `notify-done.sh`, `test-notify.sh`), pending the two rulings in Task 4.

---

## File Structure

**Created:**
- `plugins/product-workflows/.claude-plugin/plugin.json` — name, description, author, version `1.0.0`, `dependencies: ["workflows-core", "prose-style"]`
- `plugins/product-workflows/README.md`, `plugins/product-workflows/LICENSE`
- `plugins/product-workflows/commands/` — 12 files, moved
- `plugins/product-workflows/agents/` — 12 files, moved
- `plugins/product-workflows/references/` — 9 files, moved
- `plugins/product-workflows/docs/` — a new tree, derived from what the plugin ships

**Modified:**
- `.claude-plugin/marketplace.json` — one new entry
- `plugins/dev-workflows/.claude-plugin/plugin.json` — version → `4.0.0`, description rewritten to the five remaining commands
- `plugins/workflows-core/references/` — 8 file-slots carrying `dev-workflows:<pm-reference>` prose citations
- `plugins/workflows-core/scripts/command-namespaces.json` — `product-workflows` key added, `dev-workflows` reduced to five
- `scripts/check-docs.sh` — `PLUGIN_RELS`, `COST_PLUGIN_RELS`, `HANDOFF_PLUGIN_RELS`
- `plugins/dev-workflows/docs/` — reduced to the five remaining commands
- `CLAUDE.md`, `CHANGELOG.md`

---

### Task 1: Scaffold `product-workflows` and move the 33 files

**Files:**
- Create: `plugins/product-workflows/.claude-plugin/plugin.json`, `plugins/product-workflows/README.md`, `plugins/product-workflows/LICENSE`
- Move: 12 commands, 12 agents, 9 references (exact lists in "The measured allocation" above)
- Modify: `.claude-plugin/marketplace.json`

**Interfaces:**
- Produces: the `product-workflows` plugin directory and its catalogue entry. Every later task assumes both exist.
- Consumes: nothing.

- [ ] **Step 1: Create the plugin skeleton, modelled on `docs-workflows`**

Read `plugins/docs-workflows/.claude-plugin/plugin.json` first and match its shape exactly — same keys, same order. Set `"version": "1.0.0"` and `"dependencies": ["workflows-core", "prose-style"]`.

The `description` is a **stable capability blurb, never a changelog**, and must be **≤1024 characters** (warn above 900). Write it from what the plugin ships: the BRD-to-PRD route, the idea→PRD→ARD→specification ladder, and `/epics`. Do not append release detail.

Copy `LICENSE` verbatim from `plugins/docs-workflows/LICENSE`.

- [ ] **Step 2: Move the files with `git mv`, one directory at a time**

```bash
cd /home/ihudak/dev/ai-tools/ihudak-claude-plugins
mkdir -p plugins/product-workflows/{commands,agents,references}
for c in idea create-prd update-prd create-ard specify epics \
         brd-intake brd-ground brd-split brd-interview brd-package brd-reconcile; do
  git mv plugins/dev-workflows/commands/$c.md plugins/product-workflows/commands/$c.md
done
for a in ard-reviewer brd-package-reviewer brd-reader code-grounder customer-review-reader \
         design-grounder epic-reviewer epic-writer grounding-verifier idea-reader \
         prd-reviewer spec-reviewer; do
  git mv plugins/dev-workflows/agents/$a.md plugins/product-workflows/agents/$a.md
done
for r in ard-format brd-format bundle-packaging coverage-ledger-format customer-review-schema \
         decision-register-format idea-format interview-tagging specification-format; do
  git mv plugins/dev-workflows/references/$r.md plugins/product-workflows/references/$r.md
done
```

- [ ] **Step 3: Verify the counts against the tree, in both directions**

```bash
ls plugins/product-workflows/commands | wc -l    # expect 12
ls plugins/product-workflows/agents   | wc -l    # expect 12
ls plugins/product-workflows/references | wc -l  # expect 9
ls plugins/dev-workflows/commands | wc -l   # expect 5
ls plugins/dev-workflows/agents  | wc -l    # expect 12
find plugins/dev-workflows/references -type f | wc -l  # expect 15
```

Every one of those six numbers must match. A mismatch means the partition was wrong, not that the expectation was — stop and report rather than adjusting the number.

- [ ] **Step 4: Register in `marketplace.json`**

Add one entry with `"source": "./plugins/product-workflows"`, matching the shape of the `docs-workflows` entry. **Do not reformat the file** — Claude Code parses it. The entry's `description` must be the same blurb as `plugin.json`'s, under the same 1024-character budget.

- [ ] **Step 5: Run `validate-catalog.py` — the only gate that can pass this early**

```bash
./scripts/validate-catalog.py --selftest && ./scripts/validate-catalog.py --root .
```

`check-docs.sh` will still be red at this point (no `product-workflows` docs tree, and `PLUGIN_RELS` does not name it) — that is expected and is Tasks 5 and 6's work. Report it as expected-red, not as green.

- [ ] **Step 6: Commit**

```bash
git add plugins/product-workflows .claude-plugin/marketplace.json plugins/dev-workflows
git commit -m "feat(split): extract product-workflows — 12 commands, 12 agents, 9 references"
```

---

### Task 2: Rewrite the 38 cross-boundary citations, and rule on the bare-basename one

**Files:**
- Modify: 10 files under `plugins/product-workflows/commands/`, 8 file-slots under `plugins/workflows-core/references/`, `plugins/dev-workflows/README.md`, `CLAUDE.md`
- Modify: `plugins/dev-workflows/commands/ready.md:237` (the ruling)

**Interfaces:**
- Consumes: Task 1's moved tree.
- Produces: a tree where no `dev-workflows:<token>` names a thing that now lives in `product-workflows`.

- [ ] **Step 1: Re-derive the rewrite set against the tree you actually have**

Do not trust this plan's count of 38 — it was measured before Task 1 ran. Re-derive it:

```bash
PMA="ard-reviewer brd-package-reviewer brd-reader code-grounder customer-review-reader design-grounder epic-reviewer epic-writer grounding-verifier idea-reader prd-reviewer spec-reviewer"
PMR="ard-format brd-format bundle-packaging coverage-ledger-format customer-review-schema decision-register-format idea-format interview-tagging specification-format"
pat=$(echo $PMA $PMR | tr ' ' '|')
grep -rEn "dev-workflows:($pat)\b" --include=*.md --include=*.sh --include=*.json plugins scripts CLAUDE.md
```

Expected shape at measurement time: **38 lines across 20 files** — 10 files in `plugins/product-workflows/commands/` (moved files citing their own agents), 8 in `plugins/workflows-core/references/`, `plugins/dev-workflows/README.md`, and `CLAUDE.md`.

- [ ] **Step 2: Rewrite each to `product-workflows:<token>`**

This is a rename, not a redesign. `workflows-core` citing a *dependent* plugin's reference in prose is **established practice, not a defect** — core already carries five `dev-workflows:code-handoff` citations and one `dev-workflows:bug-diagnosis`. These are pointers for a reader, never loads, so they do not need a dependency and do not need converting.

Read each line before changing it. A context-blind substitution is the single recurring root cause of increment 2's and 3's defects: three separate defects came from "a substitution that could not see the context it was editing" — a fenced template, a selftest fixture, a bare name with two meanings.

- [ ] **Step 3: Rule on `ready.md:237`**

The line reads:

```
   spans>`); and any ARD's `grounded_repos:` frontmatter list (`ard-format.md`). Dedupe.
```

`/ready` stays in `dev-workflows`; `ard-format.md` is now in `product-workflows`. Read the surrounding phase to decide which of these it is, then apply the matching fix:

1. **The citation is explanatory** — it names where a frontmatter field is defined and `/ready` never reads the file. Then rewrite it to name the field without pointing at an unreachable file, e.g. drop the parenthetical or qualify it as `product-workflows:ard-format`, whichever the surrounding sentence supports.
2. **The citation is load-bearing** — `/ready` genuinely needs the file's content. Then `ard-format.md` has two consumer groups and S4 puts it in `workflows-core`, reached by both sides through the loader.

Record the ruling and its evidence in the ledger. **S16 is the tiebreaker**: promote to core only if the second consumer group *actually reads the file*, not because it mentions its name.

- [ ] **Step 4: Sweep for any other bare-basename cross-boundary citation**

Check 16 cannot see this class, so it must be swept by hand — once, here:

```bash
for r in ard-format brd-format bundle-packaging coverage-ledger-format customer-review-schema \
         decision-register-format idea-format interview-tagging specification-format; do
  hits=$(grep -rn "$r" plugins/dev-workflows --include=*.md | grep -v "product-workflows:$r")
  [ -n "$hits" ] && echo "== $r ==" && echo "$hits"
done
```

Then the same scan in the other direction (a `product-workflows` file naming a reference that stayed in dev). Every hit is either a real dangling pointer or correct prose — decide each one by reading it, and record what you decided.

- [ ] **Step 5: Run the gates and commit**

Read `.github/workflows/validate-catalog.yml` and run every gate it names. `check-docs.sh` may still be red pending Tasks 5–6; say so explicitly rather than reporting green.

```bash
git add plugins/product-workflows plugins/workflows-core plugins/dev-workflows CLAUDE.md
git commit -m "fix(split): repoint pm-bound citations at product-workflows"
```

---

### Task 3: Retire the `prose-style` skip branches that increment 3 left behind (S12)

**Files:**
- Modify: `plugins/product-workflows/commands/epics.md`, `create-prd.md`, `update-prd.md`
- Modify: `plugins/dev-workflows/agents/risk-planner.md`
- Modify: the corresponding pages under `docs/`, and `getting-started.md`

**Interfaces:**
- Consumes: Task 1's moved tree, Task 2's rewritten citations.
- Produces: a tree with no unreachable "if `prose-style` is not installed" state in the pm corpus.

- [ ] **Step 1: Census the balance before touching anything**

S12's original figure was a whole-tree census of **branches**, and increment 3 found that counting *statements* in a smaller corpus gives a **larger** number — 31 statements across 7 files, against a branch count of 22 across 18. Expect the same ratio here.

```bash
grep -rn "prose-style" plugins/product-workflows/commands/{epics,create-prd,update-prd}.md \
  plugins/dev-workflows/agents/risk-planner.md \
  plugins/product-workflows/docs plugins/dev-workflows/docs 2>/dev/null
```

At measurement time the pm-bound corpus carried **25 mentions, of which 10 are branch-bearing**. Write the census — every line, classified — into the ledger before editing. Classify each as: a true fork on plugin presence, a state reachable only through the absent case, a ledger rule, or a **sentence describing the branch**. The last class is the one nothing gates and the one that goes stale silently.

- [ ] **Step 2: Delete the unreachable branches**

`prose-style` is a declared dependency of `product-workflows`, so an unsatisfied dependency **disables the plugin** rather than letting it half-run. Every "skipped gracefully" path is therefore unreachable, and keeping unreachable branches is its own defect.

For `/epics` specifically, `prose-style-checker` is the **primary** style checker — so "skipped gracefully" meant no style check at all, which is what makes this worth doing rather than cosmetic.

- [ ] **Step 3: Rewrite the sentences, do not merely delete them**

A sentence that named the absence as its *reason* for an offer needs a **new reason**, not a deletion. Rewrite each against what the shipped thing now enforces, read out of its own Phase 0 — never assumed. `plugins/docs-workflows/docs/commands/document.md:73` is the worked model from increment 3: state the dependency, then name what is left conditional.

- [ ] **Step 4: Verify no unreachable state survives**

Re-run the Step 1 census. Every surviving mention must be either a statement of the dependency or a genuinely conditional path (the repo's own linter rungs, which are still conditional). No mention may describe `prose-style` itself as possibly absent.

- [ ] **Step 5: Run the gates and commit**

```bash
git add plugins/product-workflows plugins/dev-workflows
git commit -m "refactor(pm): retire the prose-style absent case (S12)"
```

---

### Task 4: Rule on the two hook decisions increment 3 deferred (I3-2, I3-3)

**Files:**
- Modify: `plugins/dev-workflows/hooks/preload-context.sh`, `plugins/docs-workflows/hooks/preload-context.sh`
- Possibly create: `plugins/product-workflows/hooks/`, or `plugins/workflows-core/hooks/`

**Interfaces:**
- Consumes: Task 1's moved tree — `/epics` is now a `product-workflows` command while the hook that preloads for it is still in `dev-workflows`.
- Produces: a decided, recorded hook topology for all five plugins.

This task is a **ruling task**. Both questions were designed and deferred deliberately; neither is a defect today. Decide both, implement what you decide, and record the reasoning — including for a decision to change nothing.

- [ ] **Step 1: Establish what actually fires, by reading the scripts**

`plugins/dev-workflows/hooks/preload-context.sh:47` gates on:

```bash
if [[ ! "$prompt" =~ ^/(implement|epics|vuln|upgrade)[[:space:]]+[^[:space:]-] ]]; then
```

`/epics` has moved to `product-workflows`, but a `UserPromptSubmit` hook fires on **every** message from **every** installed plugin — it is not scoped to its plugin's own commands. So today, after Task 1: a user holding both plugins still gets the preload; a user holding `product-workflows` alone gets none.

**Measured evidence, gathered before this task was dispatched. Read it before deciding anything.**

- **`notify-done.sh` (18 lines) and `test-notify.sh` (90 lines) have zero coupling to `dev-workflows`.** Neither names `dev-workflows`, `${CLAUDE_PLUGIN_ROOT}`, `$SPECS_PATH` or `$REPOS_PATH`. They are pure session-wide utilities, which removes the main technical objection to relocating them.
- **`docs-workflows` already ships its own `preload-context.sh`, and the two regexes are disjoint** — `^/(implement|epics|vuln|upgrade)` against `^/(document|release-notes)`. **Disjointness is the entire mechanism preventing double-injection today.** It is not enforced by anything; it holds because each script was written to match only its own plugin's commands. Any widening must preserve it, and the reviewer must be able to check that property directly.
- **`docs-workflows` ships no `Stop` hook and no `PostToolUse`/`Bash` hook.** So I3-3's cost is already being paid: a `docs-workflows`-only user gets no completion notification today.

**One consequence is not a judgement call — it is required work.** `/epics` has moved to `product-workflows`, but `plugins/dev-workflows/hooks/preload-context.sh` still matches bare `/epics`. Leaving that is a plugin preloading context for a command it no longer ships, and it breaks outright for anyone holding `product-workflows` without `dev-workflows`. So, at minimum: **`epics` leaves `dev-workflows`'s regex, and whatever preload `/epics` still deserves ships from `product-workflows`.** Read the routing comment at the top of `dev-workflows/hooks/preload-context.sh` — it documents what each matched command gets — and carry `/epics`'s row across intact rather than re-deriving it.

**What travels, measured — and why duplication here is forced rather than chosen.**

`/epics`'s entire preload row is one call: `emit_specs_context`, a 10-line function. That function **already exists identically in two plugins** — `dev-workflows/hooks/preload-context.sh` and `docs-workflows/hooks/preload-context.sh` — verified byte-identical by `diff`. So a third copy in `product-workflows` follows established precedent; it is not a new design decision, and the scripts are small (123 and 86 lines).

**Do not try to share it instead.** A hook script is invoked as `bash ${CLAUDE_PLUGIN_ROOT}/hooks/<script>`, and that variable resolves to the *reading* plugin — so a hook cannot source a sibling plugin's file, and reaching one by relative path would be exactly the hardcoded plugin-cache path this repo forbids. This is the same axiom the whole split turns on: **a dependency grants installation, never file access.** The duplication is the cost of that axiom, already paid twice, and "improving" it is not available.

Model `product-workflows`'s script on `docs-workflows`'s, the smaller of the two.

**One pre-existing doc defect noticed while measuring, yours if you touch the file:** `dev-workflows/hooks/preload-context.sh`'s header comment describes `/epics` as accepting its input "via the shared front-end" and `/implement` as keyed "via the shared address resolver". `CLAUDE.md` records that the shared front-end was **retired** — its authority was removed and folded into its callers. Verify against the script's actual code before repeating either phrase.

- [ ] **Step 2: Rule on I3-2 — the prefix-qualified form matches no hook**

Confirmed live in increment 3: `/docs-workflows:document …` is matched by neither `preload-context.sh`. **Pre-existing** — the pre-split script did not match `/dev-workflows:implement` either — but likelier to be hit now that the namespaced form is the disambiguating one.

The constraint that made this a deferral: widening the two regexes **independently is exactly how double-injection returns**, which is the failure the split's hook work exists to avoid. Any widening must be coordinated across every plugin that ships a matching hook, and the coordination must be verifiable — the reviewer must be able to prove that for any single prompt, at most one plugin's hook injects.

Decide, implement, and prove. If the proof is that no widening is safe without a mechanism this increment should not build, record that as the ruling and leave the regexes alone.

- [ ] **Step 3: Rule on I3-3 — `notify-done.sh` and `test-notify.sh` are session-wide**

Neither is pipeline-specific: `notify-done.sh` is a `Stop` hook and `test-notify.sh` a `PostToolUse`/`Bash` hook, so both fire regardless of which command ran. They stayed with `dev-workflows` through increment 3, which means a user who installs `product-workflows` alone gets no completion notification.

The three candidate end states, and what each costs:

1. **Leave them in `dev-workflows`.** A pm-only or docs-only user gets no notification. No double-fire.
2. **Duplicate them into `product-workflows`.** Everyone holding both plugins gets **double-notified** — the failure increment 3 named explicitly when it declined to duplicate.
3. **Move them to `workflows-core`**, which every plugin depends on. One copy, everyone gets it. Costs: `workflows-core` ships no hooks today, so this gives it a `hooks/` directory and a `hooks.json` for the first time, and `check-docs.sh` check 9 gates a hook-inventory sentence per plugin — both trees' documentation moves with it.

Increment 3's own note says *"the end state probably wants them in `workflows-core`"*. **The second half of that verification is already done** — neither script reads a `dev-workflows`-only path (measured above). What remains is to confirm `workflows-core` is a declared dependency of every plugin that would need the notification, and to decide whether giving `workflows-core` its first `hooks/` directory is in scope for this increment or is itself a follow-up. Either answer is acceptable; an undecided one is not.

- [ ] **Step 4: Implement the rulings and run the gates**

If hooks move or are added, `check-docs.sh` check 5 (hook inventory) and check 9 (prose counts) both bind — every affected plugin's `docs/reference/hooks.md` and its inventory sentences must match the shipped tree in **both** directions.

- [ ] **Step 5: Commit**

```bash
git add plugins
git commit -m "fix(hooks): settle the pm/dev hook topology (I3-2, I3-3)"
```

---

### Task 5: Repoint every script, manifest and fixture at the five-plugin tree

**Files:**
- Modify: `scripts/check-docs.sh` (`PLUGIN_RELS`, `COST_PLUGIN_RELS`, `HANDOFF_PLUGIN_RELS`)
- Modify: `plugins/workflows-core/scripts/command-namespaces.json`
- Modify: `scripts/fixtures/` as the gates require

**Interfaces:**
- Consumes: the moved tree from Tasks 1–4.
- Produces: gates that see `product-workflows`. Task 6 and Task 7 cannot be verified until this lands.

- [ ] **Step 1: Add `product-workflows` to the three dispatch lists**

`scripts/check-docs.sh` carries three, and they are **not** the same list — read each one's comment before editing:

```bash
PLUGIN_RELS="...plugins/dev-workflows plugins/guideline-reviewers plugins/workflows-core plugins/docs-workflows"
COST_PLUGIN_RELS="...plugins/dev-workflows plugins/docs-workflows plugins/workflows-core"
HANDOFF_PLUGIN_RELS="...plugins/dev-workflows"
```

- `PLUGIN_RELS` gates every plugin's docs tree identically — `product-workflows` joins it.
- `COST_PLUGIN_RELS` scopes check 8 (`emit-cost` phase/role pairs against `workflows-core:cost-emission` §7) — `product-workflows` joins it, because the moved commands emit cost.
- `HANDOFF_PLUGIN_RELS` scopes check 11 (the `/brd-*` `choices:` placeholder rule) and today names `plugins/dev-workflows` **only**. Every `/brd-*` command has now moved, so this becomes `plugins/product-workflows` — a **replacement, not an addition**.

**Both directions are already guarded, and you should expect the gate to teach you rather than go quiet.** This was verified by reading the script, and it corrects an earlier draft of this plan which warned that a mis-scoped check 11 would pass silently. It does not:

- **Forgetting to add `product-workflows`** to either scoped list fails loudly, but only once `product-workflows` is in `PLUGIN_RELS` — the dispatch loop iterates `PLUGIN_RELS`, and `check_cost_applicability` / `check_handoff_applicability` then assert membership from the **call sites**, not from which plugin ships the reference file. That re-basing is itself a correction the tree already absorbed: extracting the corpus made the reference-shipping plugin the wrong trigger in both directions at once.
- **Leaving `dev-workflows` in `HANDOFF_PLUGIN_RELS`** also fails loudly: `check_merge_clause` derives the family, matches no command, and hits the vacuity guard — *"the family was renamed or retired and this check now examines nothing"*. "A relation that comes up empty fails" is the property the script protects deliberately, and it must not be relaxed.
- **`dev-workflows` stays in `COST_PLUGIN_RELS`** — its five remaining commands still emit cost.

So the failure mode to actually guard against here is not a silent pass; it is **"fixing" a loud failure by relaxing a guard**. If check 11 fails after your edit, the fix is the list, never the guard.

- [ ] **Step 1c: Make `validate-catalog.py` reject duplicate plugin names (I4-4)**

Task 4's review disproved a claim this plan implicitly relied on: **`validate-catalog.py` does not enforce plugin-name uniqueness.** A fixture with two directories both declaring `"name": "dupname"` validates clean. In the source, `manifests[name] = (...)` is a plain dict assignment and `advertised` is a `set[str]` — a duplicate silently overwrites in one and is absorbed by the other.

This matters more after Task 4 than before it. The hook regexes are now disjoint on two invariants — distinct plugin names, distinct command-name sets — and the report claimed the first was structurally enforced. It is not; **both hold by authorship alone**. A new plugin added with a copy-pasted `plugin.json` whose `name` was never edited would collide, and nothing would catch it.

Add the check where the manifest is first recorded, and give it a **paired selftest case** — a red fixture with the duplicate and a green one without — because a check that never fires is indistinguishable from one that cannot. Follow the file's existing selftest conventions rather than inventing a shape.

- [ ] **Step 2: Split the namespace manifest**

`plugins/workflows-core/scripts/command-namespaces.json` currently lists all 17 commands under `"dev-workflows"`. Reduce that key to the five that stay, and add a `"product-workflows"` key with the twelve that moved. Keys are sorted; keep the file's existing formatting.

This manifest is what makes cost-boundary detection work across plugins — it replaced single-plugin resolution in increment 2. A command in no namespace is a command whose cost is attributed to nothing.

- [ ] **Step 3: Do NOT sweep the fixtures — read this before touching any file under `scripts/fixtures/` or either selftest**

This is where increment 2's worst defect lived, and the tree now carries scar tissue naming it. Measured for this plan:

- **`plugins/workflows-core/scripts/session-cost.py`'s selftest builds its own `command-namespaces.json` in a temp directory.** It never reads the real manifest. Its names are **deliberate fixture data chosen for string properties**, documented in the comment above them: `prompt` is a strict prefix of `prompt-brainstorm` and `prompt-grill-me`, which is what catches a claim matcher using `startswith` instead of equality; `upgrade` is a shipped name, which is what makes the bare-built-in row a real trap. The fixture models *"the deferring commands ship from the plugin holding this script, the work commands from a sibling"* — the sibling's identity is arbitrary. **`specify` sitting under `dev-workflows` there is correct fixture data, not a stale path.**
- The same file carries an explicit warning at its `G = "/workflows-core:prompt-grill-me"` constant: *"Keep this name, the manifest built in selftest(), and the replaying `/dev-workflows:implement` below consistent with each other — a sweep that rewrote this constant alone once left eight assertions failing."* That is the increment-2 defect, recorded where the next sweep will meet it.
- Two comments in that file (near its `/dev-workflows:vuln` and `/dev-workflows:implement` prose) **quote command names to explain a measured finding**. They are prose about history. Do not rewrite them.
- **`check-docs.sh`'s selftest overrides all three lists** to fixture paths (`PLUGIN_RELS="plugins/dev-workflows plugins/fixture-two"`, and likewise for the other two). The fixture tree at `scripts/fixtures/docs/pass/plugins/dev-workflows/` is a **fake plugin that happens to share the name**, not the real one. It keeps its name.

So: your edit is to the three **defaults** on lines 39, 70 and 71 of `check-docs.sh` and to the real `command-namespaces.json`. Nothing under `scripts/fixtures/` and nothing inside either selftest changes. If you believe a fixture must change, stop and report why rather than changing it — that belief is what produced the two-task-long red gate in increment 2.

- [ ] **Step 1b: Rewrite the family glob on `next-phase-offer.md`'s scope-paragraph line — atomically with `HANDOFF_PLUGIN_RELS`**

This is the coordination the word "replacement" was hiding, and it is measured, not guessed.

`check_merge_clause` and `check_handoff_applicability` both derive the family through `scope_family()`, which greps **only** the single line beginning `**Where this rule applies:` and extracts `<qualifier><family>*`, where the qualifier is built from the plugin under check (`/${PLUGIN_REL##*/}:`). That line currently reads `` `/dev-workflows:brd-*` ``. Simulated on the current tree:

- qualifier `/dev-workflows:` → glob `brd-*`
- qualifier `/product-workflows:` → **empty**

So `HANDOFF_PLUGIN_RELS` and that one glob must change together:

| Change | Result |
|---|---|
| `HANDOFF_PLUGIN_RELS` → `product-workflows`, glob left as `dev-workflows` | glob empty → `check_merge_clause:927` **fails loudly**: *"no longer names the command family … the family is read ONLY from the scope-paragraph line"* |
| glob → `product-workflows`, `HANDOFF_PLUGIN_RELS` left as `dev-workflows` | glob empty for dev → same loud failure |
| `dev-workflows` left in `HANDOFF_PLUGIN_RELS` after the glob moves | glob resolves, `route_n` 0 → **loud** vacuity failure: *"the family was renamed or retired and this check now examines nothing"* |
| both changed together | check 11 runs against `product-workflows`, silent for `dev-workflows` (empty glob → early return in the applicability guard, which is the one guard that is deliberately quiet) |

Only the last row is green, which is exactly why this is one step and not two.

**Two traps in that failure message, and it states both itself:** a `/product-workflows:brd-*` phrase **elsewhere in the file does not count** and will not silence it — only the scope-paragraph line is read; and the message is not telling you to relax the check. Task 2 deliberately left this line alone as gate-coupled rather than citation-shaped, so it is yours.

- [ ] **Step 3b: Re-measure check 11's widening census — this is the only honest moment to do it**

Two documented copies of one measurement now disagree, and this step is where check 11's scope actually moves:

- `plugins/workflows-core/references/next-phase-offer.md:69` says removing the family filter fires on **three** sites, naming `/docs-workflows:document` and `/dev-workflows:implement` among them.
- `CLAUDE.md` says **four**, naming `/document`, `/implement`, `/specify` and `/idea`.

`CLAUDE.md`'s own rule predicted this: *"two copies of one census is how they came to disagree."* Both were true when written; increment 3 moved `/document` out and this increment moves `/specify` and `/idea`, so neither is true now.

Task 2 deliberately left that sentence untouched — rewriting its prefixes while it still says "every command in `dev-workflows`" would have made it self-contradictory, and its prefixes are already mixed across two plugins. **Re-measure it here**, after `HANDOFF_PLUGIN_RELS` becomes `plugins/product-workflows`, because only then does the sentence have a tree to be true about. Then reconcile the two copies — and **prefer a citation to a second copy**, which is the rule that would have prevented this.

The sentence's purpose is to stop the widening being re-proposed without new evidence. That purpose survives; only its numbers are stale. Do not delete it, and do not soften it into something unfalsifiable.

- [ ] **Step 4: Run all seven gates — read the workflow file, do not use this plan's list**

```bash
grep -n "run:" .github/workflows/validate-catalog.yml
```

Then run every command it names, in order. `check-docs.sh --selftest` takes roughly two minutes; let it finish. Report each gate's result individually. **A task that reports "all gates green" without naming which gates it ran is not a task that ran the gates.**

- [ ] **Step 5: Commit**

```bash
git add scripts plugins/workflows-core/scripts
git commit -m "chore(gates): teach the scripts about product-workflows"
```

---

### Task 6: Build `product-workflows`'s documentation tree

**Files:**
- Create: `plugins/product-workflows/docs/` — index, top-level pages, 12 command pages, reference pages
- Modify: `plugins/product-workflows/README.md` (role-indexed pointer table)

**Interfaces:**
- Consumes: Task 5's `PLUGIN_RELS`, without which none of this is gated.
- Produces: a docs tree that passes all sixteen checks.

- [ ] **Step 1: Derive the page set from what the plugin ships, not from a template**

The sibling trees are the model, and they differ from each other because their plugins do:

| Plugin | Top-level | Commands | Reference |
|---|---|---|---|
| `docs-workflows` | README, getting-started, workflow | 3 | agents, environment, hooks, references, session-cost |
| `workflows-core` | README, getting-started, workflow, roles-and-phases | 6 | agents, environment, references, session-cost, session-feedback |
| `guideline-reviewers` | README, getting-started, workflow | 2 | agents, environment, references |

Every tree carries `README.md`, `getting-started.md`, `workflow.md`, and `reference/{agents,environment,references}.md`. The rest is present **only when the plugin ships the thing the page documents** — `hooks.md` iff it ships hooks, `session-cost.md` iff its commands emit cost.

Derive `product-workflows`'s set the same way, and state the derivation. `brd-workflow.md` and `roles-and-phases.md` are the two candidates that need a decision: measured against the current `dev-workflows` tree, `brd-workflow.md` names pm commands 98 times and `roles-and-phases.md` 74 — both are overwhelmingly pm content.

- [ ] **Step 2: Move what moves, author what does not exist**

Twelve command pages already exist under `plugins/dev-workflows/docs/commands/` and move with their commands: `idea`, `create-prd`, `update-prd`, `create-ard`, `specify`, `epics`, `brd-intake`, `brd-ground`, `brd-split`, `brd-interview`, `brd-package`, `brd-reconcile`. Use `git mv`.

**The retired page is a source of topics, never a source of facts.** Every claim on a page is derived from the thing that runs it — a synopsis from the command's argument-parsing phase, phases from its `## Phase` headings, gates from its reviewer dispatch, the agent inventory from `agents/`. This is how the original restructure found six defects the README had been asserting for releases. A moved page's claims must be **re-derived against the moved tree**, not carried across on trust.

- [ ] **Step 3: Honour the identity quarantine**

No page under `docs/` may name the marketplace or the container repository — `getting-started.md` is the single sanctioned exception, pinned by check 7, which is why it carries the install commands **inline** instead of linking out. Check 10 enforces this and matches on **word boundaries**, not substrings. Check 7 requires `getting-started.md`'s install commands to match the repo-root README **verbatim**.

- [ ] **Step 4: Satisfy checks 9, 11, 12, 15 explicitly**

- **Check 9** gates seven prose counts per plugin — commands, agents, reference files, hooks, skills, environment variables, and the size of the cost-emitting set. Re-derive each against the tree; do not copy a number from `dev-workflows`'s pages.
- **Check 11** gates the `/brd-*` `choices:` placeholder rule and now runs against `product-workflows`. It derives its family from the first such phrase in `workflows-core:next-phase-offer`'s scope paragraph, its targets from `phase-handoff.md`'s row-F table, and its writers from each command's own `deliverable_paths`. **Every one of those relations coming up empty fails rather than passes** — so if check 11 reports nothing, verify it is because the content is correct, not because `HANDOFF_PLUGIN_RELS` points at a plugin with no `/brd-*` commands in it.
- **Check 12** gates every `choices:` array at 2–4 options with no authored "Other".
- **Check 15** gates index membership: every command must appear in `docs/README.md`, in the plugin README, **and inside `docs/workflow.md`'s mermaid diagram** — asserted separately from the page, because prose below a diagram is where a command lands when someone adds it in a hurry. The defect that actually shipped this way was `/frames` reaching the workflow page's prose but not its diagram.

- [ ] **Step 5: Run all seven gates and commit**

```bash
git add plugins/product-workflows plugins/dev-workflows
git commit -m "docs(pm): build the product-workflows documentation tree"
```

---

### Task 7: Repair every documentation tree this increment touched except `product-workflows`'s

**Files:**
- Modify/delete: `plugins/dev-workflows/docs/` — the pages for moved commands are gone by Task 6; the survivors must stop asserting a 17-command plugin
- Modify: `plugins/dev-workflows/README.md`

**Interfaces:**
- Consumes: Task 6's moves.
- Produces: a `dev-workflows` tree whose every claim matches a five-command plugin.

- [ ] **Step 0: Own all three remaining trees, not just `dev-workflows`'s**

Task 6 owns `product-workflows/docs/`. **Everything else is yours**, and that is wider than this task's original name implied:

| Tree | Why it needs you |
|---|---|
| `plugins/dev-workflows/docs/` | 12 command pages leave, and check 9's four stale counts live here |
| `plugins/workflows-core/docs/` | **Task 2 edited it** (`docs/commands/frames.md`) and no task verified it. If Task 4's follow-up ever moves the notify hooks here, this tree gains a `hooks.md` |
| `plugins/docs-workflows/docs/` | Task 2 fixed a mermaid subgraph label here; Task 4 changed its hook regex, so `docs/reference/hooks.md` quotes a regex that no longer exists |

**This gap is the reason the step exists.** Two files have now been found stale by a reviewer rather than by a task, both for the same structural reason: **a task scoped to one plugin cannot see a file that describes several.** `workflows-core/references/dependencies.md` has been corrected in four commits across three increments, always as someone else's finding. Do not let a third instance through.

Task 4's report specifies the exact wording each `hooks.md` needs. Use it rather than re-deriving.

- [ ] **Step 1: Re-derive every inventory sentence**

`dev-workflows` now ships 5 commands, 12 agents, 15 reference files, and (pending Task 4) some number of hooks and no skills. Check 9 gates seven such sentences per plugin **in both directions**, so a stale "seventeen slash commands" turns the build red — but only where a gated sentence exists. Sentences the gate does not reach are held by hand.

- [ ] **Step 1b: Retire the moved rows from the README table — and with them a defect Task 1's review found**

`plugins/dev-workflows/README.md`'s role table still lists all twelve moved commands. Convert their rows to the *"Moved to the sibling `product-workflows` plugin"* form the same table already uses for `guideline-reviewers`, `workflows-core` and `docs-workflows` — do not simply delete them, because the pointer is what tells an existing user where their command went (S14's migration story in miniature).

**This is also how a real defect dies.** Task 1's review found that the row `| PA *(optional)* | /create-ard, /brd-ground |` asserts something the tree contradicts: `commands/brd-split.md` executes `require-on-main` on `grounding/code-grounding.md` in Phase 0, so `/brd-ground` is a hard precondition of `/brd-split`, not an optional PA step. It was fixed in `product-workflows`'s README. **The `dev-workflows` copy is fixed by this step removing the command names, not by editing the label** — but only if the conversion actually drops them. If you keep any moved command name in a row still marked `(optional)`, the defect survives the increment. `/create-ard` is the one command in that row whose optionality is real, and it has moved too.

- [ ] **Step 2: Fix the cross-plugin pointers, by phrase and never by line number**

`workflow.md`, `README.md` and `roles-and-phases.md` describe a pipeline that now spans three plugins. The pm→dev handoff — `/specify` → `/design` — is **the one place a phase boundary and a plugin boundary coincide**, and the spec calls for an explicit end-to-end test rather than reliance on a gate. The prose must say plainly that `/design` and `/implement` come from `dev-workflows` while the PRD ladder above them comes from `product-workflows`.

**Sweep by phrase, never by line number** — a line number goes stale on the next edit above it. This is the same discipline the "a note saying a feature does not ship" rule states: those sentences are ordinary prose, invisible to every script in `scripts/`.

- [ ] **Step 3: Watch for the de-linked pointer**

Increment 2's structural finding: **a link is gated by checks 1 and 3; a de-linked prose pointer is gated by nothing.** When a page stops linking to a moved page and starts describing it in prose, the gate stops watching. Every such rewrite must be verified by reading, not by a green build.

- [ ] **Step 4: Run all seven gates and commit**

```bash
git add plugins/dev-workflows
git commit -m "docs(dev): reduce the tree to the five remaining commands"
```

---

### Task 8: Versions, the migration note, and `CLAUDE.md`

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (→ `4.0.0`), `.claude-plugin/marketplace.json`
- Modify: `CHANGELOG.md`, `CLAUDE.md`

**Interfaces:**
- Consumes: every prior task.
- Produces: the releasable state — **gated by S18, which this task does not satisfy and must not claim to.**

- [ ] **Step 1: Move `dev-workflows` to 4.0.0 and rewrite its description (S8)**

Moving commands out breaks every `/dev-workflows:<cmd>` invocation, which is a major change. Update the version in **both** `plugin.json` and the `marketplace.json` entry, and rewrite the description to the five remaining commands — a **capability blurb, never a changelog**, ≤1024 characters.

- [ ] **Step 2: Write the migration note (S14)**

`claude plugin marketplace update` refreshes what is installed; it does **not** install plugins newly added to a catalogue. A user with `dev-workflows` installed, after updating:

- **gains** `workflows-core` automatically — it is a declared dependency
- **keeps** `/design`, `/implement`, `/ready`, `/vuln`, `/upgrade`
- **loses** `/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/epics`, every `/brd-*`, `/document`, `/docs-profile`, `/release-notes`, and the guideline reviewers, until they install the plugins that now hold them

Bare command names are unaffected — `/idea` still resolves once its plugin is installed. **Only the namespaced form moves.** List every moved command against its new plugin, and name the one-line install for each.

- [ ] **Step 2b: Update the repo-root `README.md` — the third cross-plugin file to be found stale by someone other than its owner**

`README.md:9` still says **"Seventeen slash commands"**. `dev-workflows` ships **five**. Task 6 already added `product-workflows`'s table row and install line (required by check 7), so the table is current and only the prose is stale — re-derive every count on the page rather than only that one.

**Nothing gates this.** The root README is outside check 10's `docs/` scope; check 6 reaches its table cells and check 7 pins its install block as a superset, but **no check reads its prose counts**.

**This is the third time this increment a cross-plugin file has been found stale by a reviewer or a neighbouring task rather than by its owner** — after `workflows-core/references/dependencies.md` and `workflows-core/docs/`. The Ownership note below was written after the first instance and did not list this file, which is the point: naming three files was necessary and not sufficient. **The rule is the shape, not the list** — if a file describes more than one plugin, no plugin-scoped task will look at it.

- [ ] **Step 3: Update `CLAUDE.md`**

Its "Active plugins" section, its workflow map, and its per-plugin inventory numbers all describe a four-plugin tree. **Nothing gates any number written in `CLAUDE.md`** — some have a counterpart sentence check 9 does gate, and the documentation-page totals, the check count and the `id-grammar-ok` tally have no counterpart anywhere. Re-derive all of them against the tree, and prefer a citation to a count wherever one will do.

The reinstall section must gain `product-workflows`, and its point restated: **reinstall the plugin that holds the file you edited — not the one whose workflow you were thinking about.**

- [ ] **Step 4: Verify the S18 ledger state and report it honestly**

The open ledger is **PS1, PS2, PS3, PS11 (subsumed by PS13), PS13, PS14, PS15, and I3-1…I3-5**, less whatever Tasks 2–4 closed. S18 gates the **release**, not the merge — so this task finishes with the ledger non-empty, and must say so. Do not describe the tree as releasable.

- [ ] **Step 5: Run all seven gates and commit**

```bash
git add plugins .claude-plugin CHANGELOG.md CLAUDE.md
git commit -m "chore(split): dev-workflows 4.0.0 + the S14 migration note"
```

---

### Ownership note — the files no task's file list names

Three of this increment's findings landed on files that no task claimed, and one of them, `plugins/workflows-core/references/dependencies.md`, has now been corrected in **four separate commits across increments 2, 3 and 4** — every time as someone else's finding, never as a task's own step.

**Before closing any task, check this list.** These files describe the plugin family rather than belonging to one plugin, so a task scoped to a plugin never reaches them:

| File | What goes stale in it | Owner |
|---|---|---|
| `plugins/workflows-core/references/dependencies.md` | the family's plugin count, every dependency tie, and every "resolves at runtime / skips when absent" claim | **whichever task changes a dependency** — increment 4: Task 1 (declared them) and Task 3 (retired the absent case) |
| `plugins/workflows-core/references/next-phase-offer.md` | the family glob, the offer inventory, and the widening census | Task 2 (citations), Task 5 (glob + census) |
| `CLAUDE.md` | every inventory count, the workflow map, the reinstall list | Task 8 |
| `README.md` (repo root) | the per-plugin command counts in its prose; its plugin table and install block | Task 8 |
| `plugins/*/docs/` for any plugin a task did not itself create | anything naming a moved command, or counting the family | Task 7 |

The recurring cause is not carelessness about this file; it is that a **per-plugin task scope cannot see a cross-plugin file**. So the check has to be a step, not a habit.

---

## Verification

The spec's stated verification for this increment: **the full pipeline runs across three plugins — a PRD authored in `product-workflows`, designed in `dev-workflows`, documented in `docs-workflows`.**

This is a live test on a clean Claude Code, run by the user, not a gate. It exists because the pm→dev handoff is the one place a phase boundary and a plugin boundary coincide. It works because `phase-handoff.md` is a core reference reached through the loader by both sides — which is the thing the test is checking, and the thing no script can check.

Write the verification record **last**, after the final fix wave. Three of the 2026-08-07 round's records went stale because the record was written first, and one was falsified by its own sub-project's next commit seventeen minutes later. Re-derive every expected value against the tree being verified, and never copy an `expect N` from another plan.

## Follow-up ledger

Append `I4-*` entries here as they are found. Per S18 they gate the release, not the merge.
