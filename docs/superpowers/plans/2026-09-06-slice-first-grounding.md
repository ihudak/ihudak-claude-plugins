# Slice-First Grounding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the slice the only level at which a BRD is ground and interviewed, enforced by refusal, with the root keeping intake and the coverage ledger.

**Architecture:** One gate loosens and four commands gain a refusal. `/brd-split` runs its grounding gates only in `allocate-only` mode and requires a slicing instruction on a root; `/brd-ground`, `/brd-interview`, `/brd-package` and `/brd-reconcile` refuse a resolved root, detecting pre-existing root-level artifacts so the stop says *the level moved* rather than *the key is wrong*. Everything else already works slice-first.

**Tech Stack:** Markdown command bodies, agent prompts and shared reference files that Claude Code loads and executes. No code, no unit tests — verification is the seven CI gates plus greps that assert each property.

**Spec:** `docs/superpowers/specs/2026-09-06-slice-first-grounding-design.md`

## Global Constraints

- Every refusal tests the **directory prefix** (`BRD-` vs `PRD-`), never the folder's asserted `kind:` — a slice is a `PRD-` folder asserting `kind: brd`, so an asserted-kind test refuses every slice and accepts nothing.
- On a folder resolved through the legacy unprefixed fallback there is no prefix to test: answer the root question by **positive evidence that it is a root** — `coverage-ledger.md` or `brd/brd-inventory.md` present and no `brd-link.md` naming a `parent:` — never by the absence of a file.
- Every stop message names a command or an action the reader can take.
- Do not invent new dispositions, new stop-ID prefixes, or a fourth grounding level.
- `git add -A` is never issued at repository scope; stage explicit paths.
- Commit trailer on every commit:
  `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
  `Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU`
- **Before each commit, run the concept sweep**: `grep -rn` every phrase the task changed across `plugins/ docs/ CLAUDE.md`, read the hits, and fix any neighbouring text the change falsified. Three of the last two review rounds' blockers were self-contradictions inside a file the same commit had open.
- Do not add explanatory prose carrying section citations, step pointers, paragraph pointers, counts or grep recipes unless load-bearing — and open the target before writing one. Six findings in the last round were errors inside such prose.

## File Structure

| File | Responsibility in this change |
|---|---|
| `plugins/product-workflows/commands/brd-split.md` | Gates run in `allocate-only` only; instruction required on a root; Phase 2 becomes instruction-driven |
| `plugins/product-workflows/commands/brd-ground.md` | Refuses a resolved root |
| `plugins/product-workflows/commands/brd-interview.md` | Refuses a resolved root |
| `plugins/product-workflows/commands/brd-package.md` | Refuses a resolved root |
| `plugins/product-workflows/commands/brd-reconcile.md` | Refuses a resolved root |
| `plugins/workflows-core/references/phase-handoff.md` | §3.4 rows for these commands narrow to the slice level |
| `plugins/product-workflows/docs/brd-workflow.md` | Route map, parameter table, folder-layout tree |
| `plugins/product-workflows/docs/commands/brd-*.md` (5) | Per-command pages retire the two-level model |
| `CLAUDE.md` | Workflow map rows and the BRD-route paragraph |
| `plugins/product-workflows/CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` | Release entry and version bump |

**Stop IDs introduced** (verified not to collide with the 58 already in the tree): `BRD_SPLIT_NEEDS_INSTRUCTION`, `BRD_GROUND_ROOT_LEVEL`, `BRD_INTERVIEW_ROOT_LEVEL`, `BRD_PACKAGE_ROOT_LEVEL`, `BRD_RECONCILE_ROOT_LEVEL`.

---

### Task 1: `/brd-split` — gates become slice-only, instruction becomes required on a root

**Files:**
- Modify: `plugins/product-workflows/commands/brd-split.md` (Phase 0 steps 6 and 7; Phase 0 step 1a; Phase 2's opening)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: the guarantee later tasks rely on — that a root BRD is never ground, so `/brd-ground`'s refusal in Task 2 cannot strand a working route.

- [ ] **Step 1: Establish the current behaviour so the change is provable**

```bash
cd /home/ihudak/dev/ai-tools/ihudak-claude-plugins
grep -n 'split_mode' plugins/product-workflows/commands/brd-split.md | head -20
sed -n '/^6\. \*\*Gate the grounding deliverable on main/,/^8\. /p' plugins/product-workflows/commands/brd-split.md
```

Expected: step 6 executes `require-on-main` unconditionally; step 7's three tests run unconditionally; `split_mode` is resolved at step 5.

- [ ] **Step 2: Make step 6 and step 7 conditional on `split_mode: allocate-only`**

Open step 6 and add, as its first sentence, that it runs in one mode only:

> **This step and step 7 run in `split_mode: allocate-only` only.** A root BRD is never ground — grounding and the customer interview happen at the slice and nowhere else — so on a `full` run there is no grounding to gate and both steps are skipped entirely. The `coverage-ledger.md` gate in step 8 still runs in both modes: that ledger is `/brd-intake`'s deliverable and this walk reads it.

Add the mirror sentence at step 7's opening so a reader arriving there directly meets it too.

- [ ] **Step 3: Require the instruction on a root**

At Phase 0 step 1a (where the optional instruction is parsed), add the refusal:

> **On a root the instruction is mandatory.** Phase 2 clusters candidate slices by each requirement's `verdict` and `horizon`, and a root carries no findings to read, so the grouping comes from the instruction or from nowhere. Absent on a `split_mode: full` run, stop:
> `BRD_SPLIT_NEEDS_INSTRUCTION: /brd-split on <BRD-KEY> needs a slicing instruction — a root BRD is never ground, so there are no findings to cluster candidate slices from. Re-run '/product-workflows:brd-split <BRD-KEY> "<how to cut it>"' naming the slice you want carved. On a slice the instruction stays optional: its walk takes recommendations from one but does not need it.`

- [ ] **Step 4: Re-base Phase 2 on the instruction**

Replace Phase 2's findings-clustering paragraph so it reads from the instruction rather than from `verdict`/`horizon`. Keep the `[BR#n]` grouping and the "never a single row on its own unless nothing else clusters with it" rule; delete the buildable / blocked / depends-on clustering, which is unreachable without findings.

- [ ] **Step 5: Verify the property, then the gates**

```bash
grep -c 'BRD_SPLIT_NEEDS_INSTRUCTION' plugins/product-workflows/commands/brd-split.md   # expect 1
grep -n 'allocate-only. only' plugins/product-workflows/commands/brd-split.md            # expect 2 (steps 6 and 7)
grep -c 'verdict. and .horizon' plugins/product-workflows/commands/brd-split.md          # expect 0 in Phase 2
python3 scripts/validate-catalog.py . && ./scripts/check-id-grammar.sh --root . && ./scripts/check-docs.sh --root .
```

Expected: all three gates PASS. **check 11 reads `phase-handoff.md`'s row-F table for gate targets** — it should be unaffected here because no row is removed, but a failure means the `<merge-clause>` relation moved and must be resolved before committing.

- [ ] **Step 6: Concept sweep, then commit**

```bash
for c in 'every finding carries a verifier outcome' 'Gates on every grounding finding' 'grounding/code-grounding.md'; do
  echo "== $c"; grep -rln "$c" plugins/ docs/ CLAUDE.md | grep -v CHANGELOG
done
```

Read every hit; fix any that now describes a root run. Then:

```bash
git add plugins/product-workflows/commands/brd-split.md
git commit   # subject: fix(brd-split): grounding gates run on a slice only; a root split needs its instruction
```

---

### Task 2: `/brd-ground` refuses a resolved root

**Files:**
- Modify: `plugins/product-workflows/commands/brd-ground.md` (Phase 0, immediately after the folder is resolved)

**Interfaces:**
- Consumes: Task 1's guarantee that a root is never ground, so this refusal strands nothing.
- Produces: the refusal shape Task 3 repeats three times — prefix test, legacy fallback by positive evidence, root-artifact detection, stop naming `/brd-split`.

- [ ] **Step 1: Write the refusal, immediately after `resolve-address` returns**

> **A root BRD is refused: grounding happens at the slice and nowhere else.** Test the **resolved directory's prefix** — `BRD-` is a root, `PRD-` is a slice. Never test the folder's asserted `kind:`, which reads `brd` on a slice and would refuse every slice while accepting nothing. Where the folder resolved through the legacy unprefixed fallback there is no prefix: treat it as a root only on **positive evidence** — `coverage-ledger.md` or `brd/brd-inventory.md` present, and no `brd-link.md` naming a `parent:`.
>
> On a root, look for root-level artifacts this run would have produced under the retired two-level model — `grounding/code-grounding.md`, `grounding/design-grounding.md`, `grounding/baselines.md` — and name them in the stop where any exist, so an operator whose BRD was ground under that model is told the level moved rather than that their key is wrong. Never delete them; they record work done.
>
> `BRD_GROUND_ROOT_LEVEL: <BRD-KEY> is a root BRD, and grounding happens at the slice. Carve one with '/product-workflows:brd-split <BRD-KEY> "<how to cut it>"', then run '/product-workflows:brd-ground <SLICE-KEY>'.<where root-level grounding exists, append:> This BRD carries root-level grounding at <paths> from the earlier two-level model; it is left in place and nothing reads it.`

- [ ] **Step 2: Retire the sentence this reverses**

The file's opening currently says *"Unlike `/brd-split`, this command refuses neither: a slice is ground exactly as its parent is."* Replace it with the slice-only statement. Leave the two-level `resolve-address` search intact — the command must still *resolve* a root in order to refuse it by name.

- [ ] **Step 3: Verify**

```bash
grep -c 'BRD_GROUND_ROOT_LEVEL' plugins/product-workflows/commands/brd-ground.md    # expect 1
grep -c 'refuses neither' plugins/product-workflows/commands/brd-ground.md          # expect 0
grep -c 'asserted .kind:' plugins/product-workflows/commands/brd-ground.md          # expect 1 (the warning)
python3 scripts/validate-catalog.py . && ./scripts/check-id-grammar.sh --root . && ./scripts/check-docs.sh --root .
```

- [ ] **Step 4: Concept sweep, then commit**

```bash
grep -rln 'a slice is ground exactly as its parent' plugins/ docs/ CLAUDE.md | grep -v CHANGELOG
git add plugins/product-workflows/commands/brd-ground.md
git commit   # subject: fix(brd-ground): refuse a root — grounding happens at the slice
```

---

### Task 3: `/brd-interview`, `/brd-package` and `/brd-reconcile` refuse a resolved root

Batched deliberately: three files, one shape, reviewed as one diff.

**Files:**
- Modify: `plugins/product-workflows/commands/brd-interview.md`, `.../brd-package.md`, `.../brd-reconcile.md` (Phase 0, after `resolve-address`)

**Interfaces:**
- Consumes: Task 2's refusal shape — prefix test, legacy positive evidence, artifact detection, stop naming the way forward.
- Produces: nothing later tasks consume.

- [ ] **Step 1: Apply Task 2's refusal to each, with the artifacts and next command each one's level owns**

| Command | Stop ID | Root-level artifacts to detect | Stop names |
|---|---|---|---|
| `/brd-interview` | `BRD_INTERVIEW_ROOT_LEVEL` | `decisions.md`, `interview/` | `/product-workflows:brd-split`, then `/product-workflows:brd-interview <SLICE-KEY>` |
| `/brd-package` | `BRD_PACKAGE_ROOT_LEVEL` | `bundle-<YYYYMMDD>/`, `customer-review-prompt-<YYYYMMDD>.md`, `self-review-<YYYYMMDD>.md` | `/product-workflows:brd-split`, then `/product-workflows:brd-package <SLICE-KEY>` |
| `/brd-reconcile` | `BRD_RECONCILE_ROOT_LEVEL` | `customer-review-<YYYYMMDD>.md`, `reconciliation-<YYYYMMDD>.md` | `/product-workflows:brd-split`, then `/product-workflows:brd-reconcile <SLICE-KEY> @<review-file>` |

- [ ] **Step 2: Replace the "refuses neither" sentence in each**

Each file opens with *"It refuses neither and behaves identically at both: a slice holds its own …"*. Keep the second half — a slice does hold its own — and replace the first half with the refusal.

- [ ] **Step 3: Verify**

```bash
for f in interview package reconcile; do
  printf "%-10s root-stop=%s refuses-neither=%s\n" "$f" \
    "$(grep -c "BRD_${f^^}_ROOT_LEVEL" plugins/product-workflows/commands/brd-$f.md)" \
    "$(grep -c 'refuses neither' plugins/product-workflows/commands/brd-$f.md)"
done
```

Expected: `root-stop=1 refuses-neither=0` on all three. Then the three gates.

- [ ] **Step 4: Concept sweep, then commit**

```bash
grep -rln 'refuses neither\|behaves identically at both' plugins/ docs/ CLAUDE.md | grep -v CHANGELOG
git add plugins/product-workflows/commands/brd-interview.md plugins/product-workflows/commands/brd-package.md plugins/product-workflows/commands/brd-reconcile.md
git commit   # subject: fix(brd): the interview, package and reconcile levels move to the slice
```

---

### Task 4: `phase-handoff` §3.4 rows narrow to the slice

**Files:**
- Modify: `plugins/workflows-core/references/phase-handoff.md` (§3.4's rows for `/brd-split`, `/brd-interview`, `/brd-package`, `/brd-reconcile`)

**Interfaces:**
- Consumes: the refusals from Tasks 2–3, which are what make these rows slice-only facts.
- Produces: the row-F table `check-docs.sh` check 11 derives gate targets from — so this task's verification is the one that proves check 11 still holds.

- [ ] **Step 1: Annotate each row's Caller column with the level it now applies at**

Change the Caller cell to name the level, e.g. `/brd-split` **(a slice)**, `/brd-interview` **(a slice)**. **Leave column 2's backticked artifact basenames untouched** — check 11 parses those to build its gate-target set, and changing them silently drops a command out of the check.

- [ ] **Step 2: State why the rows narrowed, once, in §3.4's prose**

> Four of these callers refuse a root outright: grounding and the customer interview happen at the slice. Their rows therefore describe a slice run, and a root never reaches the gate at all.

- [ ] **Step 3: Verify check 11 specifically, then all gates**

```bash
./scripts/check-docs.sh --root . 2>&1 | grep -iE 'check 11|merge-clause|row-F' || echo "check 11 silent (pass)"
python3 scripts/validate-catalog.py . && ./scripts/check-id-grammar.sh --root . && ./scripts/check-docs.sh --root .
```

Expected: check 11 silent, all gates PASS. A check-11 failure here means the gate-target set moved — restore the column-2 basenames before doing anything else.

- [ ] **Step 4: Commit**

```bash
git add plugins/workflows-core/references/phase-handoff.md
git commit   # subject: docs(handoff): §3.4's four BRD rows describe a slice run
```

---

### Task 4.5: Sweep the root-branches the refusals made unreachable

Added mid-flight. Task 2 surfaced that refusing a root leaves every downstream "this BRD owns its source document" branch unreachable — 8 sites in `brd-ground.md` alone — and Task 3 creates the same condition in three more files. Swept once here rather than four times inside the tasks that caused it.

**Files:**
- Modify: `plugins/product-workflows/commands/brd-{ground,interview,package,reconcile}.md`
- Modify: `plugins/product-workflows/references/coverage-ledger-format.md`

**Interfaces:**
- Consumes: the refusals from Tasks 2–3, and both implementers' reported lists of dead branches.
- Produces: a tree where no command carries a branch only a refused root could reach.

- [ ] **Step 1: Collect the reported sites**

Read the dead-branch lists in `task-2-report.md` and `task-3-report.md`, then re-derive rather than trust them. **The phrase grep is a starting point and not the sweep** — Task 2's review found an active defect that used none of that phrasing, so a phrase-scoped collection certifies files it never checked:

```bash
grep -n 'owns its source document\|a BRD with a source document of its own' plugins/product-workflows/commands/brd-{ground,interview,package,reconcile}.md
```

Then, for each of the four commands: read its Phase 0 in full, and grep every `BRD_*` stop-ID the file defines, asking of each whether the refusal changed when or whether it fires. A stop whose reachability moved, or two steps that claim the same slot in the ordering, are both in scope here and neither carries the phrase above.

- [ ] **Step 2: Rule on each site, one of three dispositions**

Each site is either **dead** (only a refused root reaches it — delete, or fold into the refusal), **still live** (a slice reaches it too — leave, and say why in the report), or **the refusal itself** (leave). Do not delete a branch without establishing which it is; a slice legitimately reads its parent's source document in places.

- [ ] **Step 3: Give the prefix/legacy-fallback test one authority**

The four refusals each state the directory-prefix test and the legacy positive-evidence rule inline. `coverage-ledger-format.md` §5.1 already owns that test for its existing consumers. Update §5.1's consumer set to include the four refusing commands, and repoint the four at it — replacing the inline restatement with a citation. Verify §5.1's stated consumer count against the tree before writing it; do not add a fifth consumer to a section that names four without correcting the number.

- [ ] **Step 4: Verify**

```bash
python3 scripts/validate-catalog.py . && ./scripts/check-id-grammar.sh --root . && ./scripts/check-docs.sh --root .
grep -c 'asserted .kind:' plugins/product-workflows/commands/brd-{ground,interview,package,reconcile}.md
```

- [ ] **Step 5: Concept sweep, then commit**

```bash
for c in 'owns its source document' 'positive evidence that it is a root'; do echo "== $c"; grep -rln "$c" plugins/ docs/ CLAUDE.md | grep -v CHANGELOG; done
git add plugins/product-workflows/commands/ plugins/product-workflows/references/coverage-ledger-format.md
git commit   # subject: fix(brd): retire the root-branches the refusals made unreachable
```

---

### Task 5: Retire the two-level model from every documentation surface

**Files:**
- Modify: `plugins/product-workflows/docs/brd-workflow.md` (route map, parameter table, folder-layout tree)
- Modify: `plugins/product-workflows/docs/commands/brd-{ground,split,interview,package,reconcile}.md`
- Modify: `CLAUDE.md` (the workflow-map rows for the five commands; the BRD-route paragraph)

**Interfaces:**
- Consumes: the stop IDs and gate conditions from Tasks 1–4, quoted exactly.
- Produces: nothing later tasks consume.

- [ ] **Step 1: Enumerate every surface asserting the two-level model**

```bash
grep -rn 'either level\|either of the two levels\|both levels\|refuses neither' \
  plugins/product-workflows/docs/ CLAUDE.md plugins/product-workflows/commands/ | grep -v CHANGELOG
```

Every hit is either updated or confirmed still true (`resolve-address` genuinely still searches both levels — that is how a root is resolved in order to be refused).

- [ ] **Step 2: Update `brd-workflow.md`**

Route map gains the protocol order from the spec's §3, including `/brd-split` appearing twice. The parameter table's `/brd-split` row marks the instruction **required on a root, optional on a slice**. The folder-layout tree stays as-is — the artifacts still exist, only their level changed.

- [ ] **Step 3: Update the five per-command pages**

Each gains the refusal in its "What it needs" list, naming its stop ID and the `/brd-split` route forward.

- [ ] **Step 4: Update `CLAUDE.md`**

The workflow-map rows for the five commands, and the BRD-route paragraph's description of where grounding and the interview happen.

- [ ] **Step 5: Verify**

```bash
python3 scripts/validate-catalog.py . && ./scripts/check-id-grammar.sh --root . && ./scripts/check-docs.sh --root .
./scripts/check-docs.sh --selftest 2>&1 | tail -2
```

Expected: gates PASS, `SELFTEST PASS`.

- [ ] **Step 6: Concept sweep, then commit**

```bash
for c in 'either level' 'behaves identically at both' 'a slice is ground exactly as'; do
  echo "== $c"; grep -rln "$c" plugins/ docs/ CLAUDE.md | grep -v CHANGELOG
done
git add plugins/product-workflows/docs/ plugins/product-workflows/commands/ CLAUDE.md
git commit   # subject: docs: retire the two-level BRD model from every surface
```

---

### Task 6: Release entry and version bump

**Files:**
- Modify: `plugins/product-workflows/CHANGELOG.md`, `plugins/product-workflows/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Modify: `docs/superpowers/brd-route-follow-ups.md` (mark gate 1 shipped)

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: Add the entry under a new minor version**

`product-workflows` goes to **1.2.0** — a behaviour change to a shipped route, not a fix. The entry states plainly that four commands now refuse a root, that this is breaking for anyone running the route at root level, and that root-level artifacts are left in place and read by nothing.

- [ ] **Step 2: Bump both manifests to the same version**

Edit `plugin.json` and the matching `marketplace.json` entry textually — do not reformat `marketplace.json`, which Claude Code parses.

- [ ] **Step 3: Verify the manifests agree**

```bash
python3 scripts/validate-catalog.py --selftest && python3 scripts/validate-catalog.py .
```

Expected: 0 errors, 0 warnings. This is the check that catches a manifest pair disagreeing.

- [ ] **Step 4: Mark gate 1 shipped in the ledger, run every gate, commit**

```bash
python3 scripts/validate-catalog.py --selftest && python3 scripts/validate-catalog.py . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && ./scripts/check-docs.sh --root . && ./scripts/check-docs.sh --selftest \
  && python3 plugins/workflows-core/scripts/session-cost.py --selftest
git add plugins/product-workflows/CHANGELOG.md plugins/product-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json docs/superpowers/brd-route-follow-ups.md
git commit   # subject: release: product-workflows 1.2.0 — slice-first grounding and interviewing
```

---

## After this plan

Two release gates remain, in order: the spec's **§8** (a slice grounding shows is too big hands its deferred rows to a sibling, by re-pointing `covered-by`) and its **§5** (verified grounding for the idea route). Each needs its own brainstorm and spec before a plan.

Whatever ships from this plan goes through one combined review round together with the round-4 changes already on `main`, rather than a round of its own.
