# Bundle citation resolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/brd-package` checks that the identifiers and filenames it ships actually resolve inside the bundle it just assembled, and stops when they do not.

**Architecture:** Three relations run over the assembled bundle beside the existing plugin-free scan. The rules live in `product-workflows:bundle-packaging` as a new §6 — the embedded authority that already owns the plugin-free rule (§1) and the de-Obsidianising rule (§2) — and `/brd-package` Phase 8 executes them as a new step 8. The correctness half of the class-4 citation rule is stated in `workflows-core:grounding-format` §6.3, beside the presence half that already lives there.

**Tech Stack:** Markdown instruction files only. No code ships. Verification is the repository's seven CI gates plus per-task greps that assert the shipped text says what the task requires.

**Spec:** `docs/superpowers/specs/2026-09-08-bundle-citation-resolution-design.md`

## Global Constraints

- **Every requirement ID written anywhere is the bracketed `[PREFIX#N]` form**, never dash-separated. `./scripts/check-id-grammar.sh --root .` enforces it and must pass after every task.
- **Prose is never hard-wrapped** as a paragraph — but these files are already hard-wrapped at ~100 columns in their source, and `workflows-core:prose-formatting` governs the prose a *run* writes, not this repository's own instruction files. **Match the wrap of the file you are editing**, exactly as its neighbouring paragraphs do.
- **`brd-` names the route, not the folder kind.** `/brd-package` is one of the four route commands that refuse a root outright (`BRD_PACKAGE_ROOT_LEVEL`); every rule written here describes a **slice** run.
- **Never restate a rule another file owns — cite it.** `bundle-packaging.md` §6 derives its working-filename list from §1.1's own table rather than copying it; the spec's §9 names that as the risk this avoids.
- **A relation that comes up empty is a failure, never a pass** (`workflows-core:grounding-format` §2.1). A corpus file holding record-shaped content that parses to zero ids is `BRD_PACKAGE_CORPUS_UNREADABLE`, never "no references to check" — while a corpus holding no record-shaped content at all is legitimately empty and passes, the distinction the whole-branch review required so a skipped-design-grounding note and an entryless defect log do not stop correct packages.
- **The check stops; it never sanitises.** The plugin-free scan's own sentence states the reason, and §6 must not contradict it.
- **Plugin `description` hard cap 1024 characters**, warning at 900. `product-workflows` is at **988** — 36 characters of headroom. If this work touches the blurb at all, it **trims**; it never appends. Prefer not touching it: this ships a gate, not a capability a user selects.
- **`.claude-plugin/marketplace.json` must not be reformatted** — edit only the `version` value of the entry being bumped.
- Commit trailer on every commit:
  ```
  Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU
  ```
- **Nothing is pushed.** No task opens a pull request or runs `git push`.

**The seven gates**, run from the repository root, all of which must pass before any task commits:

```bash
python3 scripts/validate-catalog.py --selftest
python3 scripts/validate-catalog.py .
./scripts/check-id-grammar.sh --selftest
./scripts/check-id-grammar.sh --root .
./scripts/check-docs.sh --selftest          # ~2 minutes
./scripts/check-docs.sh --root .
python3 plugins/workflows-core/scripts/session-cost.py --selftest
```

`validate-catalog.py .` currently reports **0 errors, 2 warnings**; both warnings are pre-existing description-length warnings (ledger G3-4). Two warnings is the expected baseline — a third means this work touched a blurb.

---

## File Structure

| File | Responsibility in this change |
|---|---|
| `plugins/workflows-core/references/grounding-format.md` | §6.3 gains the correctness half of the class-4 citation rule, route-neutrally |
| `plugins/product-workflows/references/bundle-packaging.md` | new §6 (the three relations, the corpus table, the two exemptions, the three stops, what §6 cannot see); §2 gains one sentence extending the dead-filename rule from links to prose |
| `plugins/product-workflows/commands/brd-package.md` | Phase 8 gains step 8, which executes §6; the three stop strings; the Final report gains the check's outcome |
| `plugins/product-workflows/docs/commands/brd-package.md` | the `## Gates` section gains a bullet for the new check |
| `plugins/product-workflows/CHANGELOG.md`, `.claude-plugin/plugin.json` | product-workflows 3.1.0 |
| `plugins/workflows-core/CHANGELOG.md`, `.claude-plugin/plugin.json` | workflows-core 1.3.2 |
| `.claude-plugin/marketplace.json` | both version values |

**Task order is forced by citation direction.** Task 2's §6 cites Task 1's §6.3 rule, and Task 3's step 8 cites Task 2's §6. Task 4 documents all three. Do not reorder.

---

### Task 1: `grounding-format` §6.3 — a class-4 citation must be correct, not merely present

**Files:**
- Modify: `plugins/workflows-core/references/grounding-format.md` — §6.3, the class-4 bullet (locate by the phrase `A `[DG#n]` of this class carrying no `[CG#n]` citation is incomplete.`, never by line number)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: the rule `bundle-packaging.md` §6's relation 2 cites. Task 2 refers to it as **`workflows-core:grounding-format` §6.3**.

- [ ] **Step 1: Read §6.3 and confirm the anchor sentence is present and unique**

```bash
grep -c 'carrying no `\[CG#n\]` citation is incomplete' plugins/workflows-core/references/grounding-format.md
```

Expected: `1`. If it is `0`, the section was reworded — stop and report; do not guess a new anchor.

- [ ] **Step 2: Confirm §6 is route-neutral, because the new rule must be too**

```bash
grep -n "a BRD's \`\[BR#n\]\` rows, or a PRD's" plugins/workflows-core/references/grounding-format.md
```

Expected: one hit, in §6.3's opening paragraph. This is why the rule below says *the same requirement id* and never *the same `[BR#n]`* — `/brd-package` is BRD-route-only and will only ever see `[BR#n]`, but §6.3 is read by the idea route as well.

- [ ] **Step 3: Append the correctness rule to the class-4 bullet**

Immediately after `A `[DG#n]` of this class carrying no `[CG#n]` citation is incomplete.`, inside the same bullet, add:

```markdown
**A citation that is present and wrong is worse than one that is absent, so the requirement is not
only that a `[CG#n]` is named but that it is the right one: the cited finding's `claim` names the
same requirement id as the citing `[DG#n]`'s own `claim`.** An absent citation is visibly
incomplete and a reader stops; a citation that resolves sends the reader to a real finding about a
different requirement, which they have no way to detect. Both values sit in the two records, so
this is checkable wherever both are on hand — `product-workflows:bundle-packaging` §6 is the first
consumer to check it, at the point the findings are copied in front of a customer.
```

Match the file's existing wrap width. The phrase *"the same requirement id"* is load-bearing — do not write *"the same `[BR#n]`"*.

- [ ] **Step 4: Verify the rule landed and stayed route-neutral**

```bash
grep -c 'same requirement id as the citing' plugins/workflows-core/references/grounding-format.md   # expect 1
grep -c 'same `\[BR#n\]` as the citing' plugins/workflows-core/references/grounding-format.md       # expect 0
```

- [ ] **Step 5: Run the gates**

Run all seven. Expected: every one passes; `validate-catalog.py .` reports 0 errors, 2 warnings.

- [ ] **Step 6: Commit**

```bash
git add plugins/workflows-core/references/grounding-format.md
git commit -F <message-file>
```

Subject: `fix(core): a class-4 citation must name a finding about the same requirement`

---

### Task 2: `bundle-packaging.md` — §6 Citation resolution, and §2's prose sentence

**Files:**
- Modify: `plugins/product-workflows/references/bundle-packaging.md` — add `## 6. Citation resolution` after §5 (the file's current last section); add one sentence to §2 after its third bullet (locate by `explicit statement that it is not included.`, which ends that bullet immediately before the `### 2.1` heading)

**Interfaces:**
- Consumes: Task 1's §6.3 rule, cited as `workflows-core:grounding-format` §6.3.
- Produces: **§6**, with the entry-point name **`citation-resolution`** and the three stop identifiers `BRD_PACKAGE_DEAD_CITATION`, `BRD_PACKAGE_CITATION_MISMATCH`, `BRD_PACKAGE_CORPUS_UNREADABLE`. Task 3's Phase 8 step 8 cites `${CLAUDE_PLUGIN_ROOT}/references/bundle-packaging.md` §6 and emits exactly those three strings.

- [ ] **Step 1: Add the §2 sentence extending the rule from links to prose**

After §2's third bullet (the one ending `explicit statement that it is not included.`) and before the `### 2.1` heading, add:

```markdown
**The three cases above are about rewritten links, and the rule does not stop there.** A bundle
document that names a file **in prose** — not as a link — makes the identical promise to the
reviewer and breaks it the same way. That is not hypothetical: a shipped bundle named
`self-review-<YYYYMMDD>.md`, which §1.1 excludes by rule, in ordinary prose, and named three
grounding files by their working filenames after this pass had renamed them. Both survived
everything, because a rewrite rule inspects links. §6's relation 3 covers prose and links alike.
```

- [ ] **Step 2: Write §6, appended after §5**

The section must contain all of the following, in this order. Wrap to match the file.

1. **A one-paragraph statement of what §6 is for**, naming the gap: the plugin-free scan (§1) deliberately exempts identifiers because they are how a returned review cites the package, and nothing then checks that they land. Name the three observed failures compactly and cite the spec.

2. **`### 6.1 The corpus is built per source package, and never crossed`** — a prerequisite package is copied in wholesale (§1.1) with its own corpus numbered from 1, so one bundle can hold two different `[CG#7]`s. Bundle documents partition on the `<BRD-KEY>` each one's own filename carries — never by subtree, which the spec amendment at `09e7127` refuted: a path-keyed boundary inside a bundle whose whole addressing convention is path-free would make the boundary a property of where a document sits, so a later change that flattened the bundle would resolve every id against one corpus and pass. Then this table, verbatim:

```markdown
| Class | Corpus file, within the partition |
|---|---|
| `[BR#n]` | `brd/brd-inventory.md` |
| `[DEF#n]` | `brd/brd-defect-log.md` (the parent's on a slice, one hop — `references/brd-format.md` §4) |
| `[CG#n]`, `[DG#n]` | `grounding/code-grounding.md`, `grounding/design-grounding.md` |
| `[VD#n]`, `[CD#n]`, `[AS#n]` | `decisions.md` (`references/decision-register-format.md` §1 and §7) |
| `[SR#n]` | **none — exempt entirely, §6.3** |
```

Follow it with the parsing rule: every corpus is **parsed**, and an id is resolved against the set actually parsed, never by matching a fixed column — citing `workflows-core:grounding-format` §2.1 and its 140-findings-reported-missing precedent, because a column-anchored scan here would report every reference in the bundle as dead.

3. **`### 6.2 The three relations`** — each stated as a rule with its own reason:

   - **Relation 1**: every identifier reference resolves inside its own partition's corpus for that class, unless it carries the owning BRD key at the point of use. **The qualified prose form is `<BRD-KEY> [CG#7]`, one spelling only** — the key immediately before the bracketed id — and say why one spelling: §2.1's argument that two renderings produce readers who are wrong in a way that looks like data. **Amended after the whole-branch review**, which found this step's original *the qualified form* — unqualified, and so covering every rendering — produced a check that stopped correct packages on structured fields the operator cannot legally repair, `decision-register-format.md` §5's `conditional_on: <BRD-KEY>/<decision-id>` among them: hence **prose** above, and say also that a reference carried by a structured field whose format another authority fixes is qualified wherever that authority defines the field to name another BRD's record, with the fields derived from those authorities rather than listed in §6. Add that this also repairs a live ambiguity: today a reviewer reading a copied prerequisite's grounding file sees `[CG#7]` with nothing saying whose numbering it is.
   - **Relation 2**: for every `[DG#n]` whose `class` is 4, its `cites` resolves within the same partition **and** the cited `[CG#n]`'s `claim` names the same requirement id as the citing finding's `claim`. Cite `workflows-core:grounding-format` §6.3 as the owner of the rule; §6 enforces it. **State why the test is "names" and not "opens with"** — §2.1's canonical example opens with the id, but that same section sanctions hand-edited artifacts on this route, so a claim reading *"the nightly export, per `[BR#7]`, runs at 02:00"* is correct content a position test would refuse. **And state the disposition that looser test needs:** where a claim names more than one requirement id, §6 **reports the ambiguity** rather than picking one, because a silent pick is a guess.
   - **Relation 3**: a bare `<name>.md` token — **no path separator** — must name a document in the bundle when it is one of two shapes: it carries the `<BRD-KEY>-` prefix `commands/brd-package.md`'s *Assemble the bundle* rule 1 gives every bundle document, **or** it matches the working filename of a document §1.1 admits or excludes by name. **Derive that second list from §1.1's own table rather than restating it here**, and say so in one clause, because a document added to §1.1 without a matching entry would be invisible to exactly the check that exists to catch it. State the false positive this scoping avoids: a grounding finding's `evidence` is a repository `file:line` list, so an unscoped rule refuses a bundle over a correct `docs/api.md:12`.

4. **`### 6.3 Two exemptions`**:
   - **`[SR#n]` entirely** — `self-review-<YYYYMMDD>.md` is excluded by §1.1's one *rule* exclusion, while the `[SR#n]` content the customer may see reaches them filtered through the prompt's parts 7 and 9, cited by id. So an `[SR#n]` reference is correct content that resolves to nothing in the bundle, by design, and **a check without this exemption fires on every package**. Add the distinction a reader needs: naming the self-review *file* is dead (relation 3 catches it); naming an `[SR#n]` is the filter working (relation 1 must not).
   - **`brd/source/<basename>` reports rather than stops** — the customer's own document, immutable by §2.1 and `references/brd-format.md` §1. It inherits the plugin-free scan's treatment verbatim and for the identical reason: stopping outright would make that BRD permanently unpackageable, since the one repair the rule allows is not editing the file. Every other document's hit stays a hard stop.

5. **`### 6.4 What §6 cannot see`** — stated because a green check is otherwise read as a clean bundle:
   - a reference that **describes** a bundle document where rule 1 requires it to **name** one — no pattern separates a deliberate description from a missing filename;
   - a citation that resolves to the right id and is wrong in a way relation 2 does not test;
   - an identifier class shipping without a row in §6.1's table. The table is a closed list; the reverse case — a row whose file is not in the bundle — is `BRD_PACKAGE_CORPUS_UNREADABLE`, never a silent skip.

- [ ] **Step 2b: Repair this file's own preamble, which §6 falsifies in two places**

Found by the pre-flight scan, not by the sweep at the end, and both are the enumeration-goes-stale class that cost the previous increment the most — neither sentence contains any word this change introduces, so no search for "citation" finds them.

- The preamble's **"Consumed by `commands/brd-package.md`, which builds a bundle against this contract — its plugin-free rules, its §1.1 content allow-list, its de-Obsidianising pass, its degradation tiers, its delivery-note ceiling and its committed dated directory"** enumerates six things the command builds against. §6 is a seventh. Add it in the same voice; do not append a trailing clause.
- The preamble's **"the finding record and the `baseline-integrity` procedure … belong to `workflows-core:grounding-format` §2 and §4"** names the sections of that file this one cites. §6 cites **§2.1** (the reading rule) and **§6.3** (the class-4 correctness rule) as well. Extend the section list.

Verify both:

```bash
grep -c 'its committed dated directory' plugins/product-workflows/references/bundle-packaging.md   # expect 1, and read the sentence
grep -n 'workflows-core:grounding-format` §' plugins/product-workflows/references/bundle-packaging.md
```

- [ ] **Step 3: Verify the section's structure and its non-restatement**

```bash
grep -n '^## 6\.\|^### 6\.' plugins/product-workflows/references/bundle-packaging.md
```

Expected: `## 6. Citation resolution`, `### 6.1`, `### 6.2`, `### 6.3`, `### 6.4`.

```bash
grep -c 'BRD_PACKAGE_DEAD_CITATION\|BRD_PACKAGE_CITATION_MISMATCH\|BRD_PACKAGE_CORPUS_UNREADABLE' \
  plugins/product-workflows/references/bundle-packaging.md
```

Expected: at least `3` — each stop named at least once.

- [ ] **Step 4: Assert §6 derives the working-filename list rather than copying it**

Read §6.2's relation 3 and confirm it points at §1.1's table instead of listing the eight working filenames inline. A copy here is the staleness the spec's §9 names. If a list is unavoidable for readability, it must be introduced as *derived from §1.1* and carry the instruction to re-derive.

- [ ] **Step 5: Run the gates**

All seven. `check-docs.sh` check 16 gates the loader contract in both directions — this file is a `product-workflows` reference and cites `workflows-core:grounding-format`, so confirm it carries the loader preamble already (it does; do not add a second one).

- [ ] **Step 6: Commit**

```bash
git add plugins/product-workflows/references/bundle-packaging.md
git commit -F <message-file>
```

Subject: `feat(packaging): bundle-packaging §6 — citation resolution`

---

### Task 3: `/brd-package` Phase 8 step 8, the three stops, and the Final report

**Files:**
- Modify: `plugins/product-workflows/commands/brd-package.md` — Phase 8 (`## Phase 8 — Assemble the bundle`), after the numbered rule 7 that runs the plugin-free scan; and the `## Final report` section

**Interfaces:**
- Consumes: Task 2's §6, cited as `${CLAUDE_PLUGIN_ROOT}/references/bundle-packaging.md` §6, and its three stop identifiers.
- Produces: the shipped stop strings and the Final report line that Task 4 documents.

- [ ] **Step 1: Confirm the insertion point**

```bash
grep -n 'Run the plugin-free scan over every document in the finished bundle' \
  plugins/product-workflows/commands/brd-package.md
```

Expected: exactly one hit, numbered rule `7.` in Phase 8. Step 8 goes immediately after that rule's paragraph and before the `**The bundle is committed** (D18)` paragraph.

- [ ] **Step 2: Write rule 8**

```markdown
8. **Run the citation-resolution check over every document in the finished bundle**, per
   `${CLAUDE_PLUGIN_ROOT}/references/bundle-packaging.md` §6, and stop on any hit. It runs here and
   nowhere earlier because both of its inputs — the identifier corpus and the set of bundle
   filenames — are facts about the *assembled* bundle; the rendered prompt is covered because the
   prompt is itself a bundle document. It is a second pass rather than a widening of rule 7's scan:
   that scan hunts tokens a reader **cannot resolve**, and this one hunts tokens a reader **resolves
   to the wrong thing**, which is the worse failure and needs the bundle's own corpus to detect.
```

- [ ] **Step 3: Write the three stop strings, immediately below rule 8**

Each on the model of `BRD_PACKAGE_PROMPT_LEAK` — the identifier, a colon, then a sentence naming what was found, where, and what it failed against:

```markdown
`BRD_PACKAGE_DEAD_CITATION: <id-or-filename> in <bundle document> resolves to nothing — <what it was resolved against>. A reference the reviewer cannot follow is not fixed by deleting it: some sentence in the package assumed that id or that file, and the sentence is what has to change.`

`BRD_PACKAGE_CITATION_MISMATCH: <DG-id> is class 4 and cites <CG-id>, whose claim names <requirement-a> where the citing finding's claim names <requirement-b> — the citation resolves, to a finding about a different requirement, which is the one failure a reviewer cannot detect by following it.`

`BRD_PACKAGE_CORPUS_UNREADABLE: <corpus file> holds record-shaped content but parsed to zero <class> ids — that is a parse failure, not an empty corpus, and reporting it as an absence would report every reference in the bundle as dead (workflows-core:grounding-format §2.1).`
```

**Amended after the whole-branch review:** the `BRD_PACKAGE_CORPUS_UNREADABLE` string above originally read *is present and non-empty but parsed to zero ids*, which names a state that is ordinary and correct — a `design-grounding.md` written as a short note, an entryless defect log — and told the operator to repair a parse failure that had not occurred. The trigger it now names is **record-shaped content**, the distinction the Global Constraints above were amended to fix.

**The `BRD_PACKAGE_CITATION_MISMATCH` message must name both requirement ids.** The spec's §9 risk is that the first run against an existing hand-narrowed BRD stops and the repair is by hand; a stop that says only "something disagrees" makes that repair guesswork.

- [ ] **Step 4: Add the source-document exemption paragraph**

Below the stops, state that `brd/source/<basename>` reports rather than stops, exactly as it does under the plugin-free scan, naming §6.3 as the owner of the rule and giving the same reason (the one repair the rule allows is not editing the file). Do not restate §6.3's argument at length — cite it.

- [ ] **Step 5: Add the Final report line**

In `## Final report`, in the list of what the report states, after `the four artifacts written, by path;`, add:

```markdown
**the citation check's outcome** — how many identifier references resolved, across how many source
packages, how many carried an owning BRD key, and every hit inside the customer's own source
document that the operator was asked to rule on, **or an explicit "none"**;
```

The explicit-none half is the convention this command already uses for normalisations and prerequisites: a report that is silent when nothing fired is indistinguishable from a check that did not run.

- [ ] **Step 6: Verify**

```bash
grep -c 'BRD_PACKAGE_DEAD_CITATION\|BRD_PACKAGE_CITATION_MISMATCH\|BRD_PACKAGE_CORPUS_UNREADABLE' \
  plugins/product-workflows/commands/brd-package.md          # expect 3
grep -c 'bundle-packaging.md` §6' plugins/product-workflows/commands/brd-package.md   # expect >= 1
grep -n 'citation check' plugins/product-workflows/commands/brd-package.md            # expect a Final report hit
```

- [ ] **Step 7: Run the gates and commit**

All seven. Then:

```bash
git add plugins/product-workflows/commands/brd-package.md
git commit -F <message-file>
```

Subject: `feat(brd-package): check that shipped citations resolve inside the bundle`

---

### Task 4: Docs page, versions, changelogs

**Files:**
- Modify: `plugins/product-workflows/docs/commands/brd-package.md` — the `## Gates` section, the identifiers sentence in the plugin-free-scan bullet, and the `bundle-packaging.md` See-also description
- Modify: `plugins/product-workflows/docs/reference/references.md` — the `bundle-packaging.md` entry
- Modify: `plugins/product-workflows/.claude-plugin/plugin.json` → `3.1.0`; `plugins/workflows-core/.claude-plugin/plugin.json` → `1.3.2`
- Modify: `.claude-plugin/marketplace.json` — the two matching `version` values, **and nothing else in the file**
- Modify: `plugins/product-workflows/CHANGELOG.md`, `plugins/workflows-core/CHANGELOG.md`

**Interfaces:**
- Consumes: everything Tasks 1–3 shipped. Every claim on the docs page is derived from the command file, never from this plan.

- [ ] **Step 1: Add the docs-page gate bullet**

In `## Gates`, immediately after the `**Phases 6, 7 and 8 — the plugin-free scan.**` bullet, add a bullet of the same shape. It must state: where it runs (Phase 8, over the assembled bundle); the three relations in one sentence each; the two exemptions; and the three stop names. **Derive each claim by reading `commands/brd-package.md` rule 8 and `references/bundle-packaging.md` §6** — the retired-README rule applies to every page here: a docs page is a source of topics, never of facts.

- [ ] **Step 1b: Repair the three documentation sentences §6 falsifies**

All three found by the pre-flight scan. Each is an enumeration of what `bundle-packaging.md` covers, and each silently loses a member when §6 lands — the same class as Task 2's step 2b, on the documentation side.

- **`docs/reference/references.md`, the `bundle-packaging.md` entry.** Its description runs through the plugin-free rules, the de-Obsidianising pass, the three tiers, the allow-list, the delivery note's ceiling and the dated directory. Add the citation check in the same voice and at the same altitude — what it checks and why, not how.
- **`docs/commands/brd-package.md`, the See-also entry** — *"the authority for plugin-free construction, the de-Obsidianising pass, the three degradation tiers, the delivery note's ceiling, and where the bundle lands"*. Five members; add the sixth.
- **`docs/commands/brd-package.md`, the plugin-free-scan Gates bullet's last sentence** — *"identifiers are **not** in the scan's classes and are meant to travel — they are how the returned review cites the package without minting identifiers of its own."* **This sentence is correct and stays**: §6 checks that identifiers *land*, it does not stop them travelling. But it is the page's only statement about identifiers, and left alone it now reads as "and nothing checks them". Add the companion clause pointing at the new bullet. Do not delete or weaken the existing sentence — a sweep that removes it has misread the change.

- [ ] **Step 2: Bump both versions**

`product-workflows` 3.0.0 → **3.1.0** — minor, not patch: this adds a gate that can refuse a bundle a previous version shipped, which is a behaviour change a user will meet.

`workflows-core` 1.3.1 → **1.3.2** — patch: §6.3 gains a rule about content the format already required to be present.

Edit `.claude-plugin/marketplace.json` by replacing only the two `version` string values. Do not reformat.

- [ ] **Step 3: Write both changelog entries**

`product-workflows` `## [3.1.0] — 2026-09-08`, under `### Added`, covering: the gap (identifiers exempt from the scan, nothing checking they land); the three relations; the two exemptions and why each is principled — especially that `[SR#n]` without its exemption fires on every package; the three stops; and the honest consequence, that relation 2 will refuse bundles shipping today and the repair is by hand because the narrowing gap is a separate open item.

`workflows-core` `## [1.3.2] — 2026-09-08`, under `### Changed`, covering §6.3's new correctness half and why it is route-neutral.

- [ ] **Step 4: Run the gates**

All seven. `validate-catalog.py .` must still report **0 errors, 2 warnings** — a third warning means a blurb was touched, which this task does not do.

`check-docs.sh --root .` covers the docs page's own inventory relations; a failure here almost always means the page claimed something the command file does not say.

- [ ] **Step 5: Commit**

```bash
git add plugins/product-workflows/docs/commands/brd-package.md \
        plugins/product-workflows/.claude-plugin/plugin.json \
        plugins/product-workflows/CHANGELOG.md \
        plugins/workflows-core/.claude-plugin/plugin.json \
        plugins/workflows-core/CHANGELOG.md \
        .claude-plugin/marketplace.json
git commit -F <message-file>
```

Subject: `docs(brd-package): document the citation check; product-workflows 3.1.0`

---

## Whole-branch sweep, before the final review

Run these from the repository root and read every hit. They are not optional: gate 3's signature defect was prose that derived an obligation from a glob a rename had shrunk, invisible to a search for the renamed thing.

**Four sites were already found and repaired at pre-flight** — two in `bundle-packaging.md`'s preamble (Task 2 step 2b) and three across the documentation (Task 4 step 1b). The sweep below is still run in full: it is the second pass, and on the previous increment the second pass is what found the instance the first had walked past.

- [ ] **Exclusivity probe.** The claim *"the plugin-free scan is the only pass over the finished bundle"* — or any sentence of that shape — is now false.

```bash
grep -rn 'only pass\|only check\|is the only\|nothing else checks\|no other scan' \
  plugins/product-workflows/ --include=*.md | grep -v CHANGELOG
```

- [ ] **Absence claims the change falsifies.** A sentence saying nothing verifies citations, or that identifiers travel unchecked, is a claim with an expiry date and this change is its expiry.

```bash
grep -rn 'never checked\|nothing verifies\|not verified\|meant to travel' \
  plugins/product-workflows/ plugins/workflows-core/ --include=*.md | grep -v CHANGELOG
```

The `meant to travel` sentence in `commands/brd-package.md`'s plugin-free scan is **correct and stays** — identifiers *are* meant to travel, and §6 checks that they land rather than stopping them. Confirm it does not also claim nothing checks them.

- [ ] **Stop-count and gate-count sentences.** Any sentence counting `/brd-package`'s gates or stops.

```bash
grep -rn 'BRD_PACKAGE_' plugins/ --include=*.md | grep -v CHANGELOG | grep -c .
grep -rn 'three gates\|two gates\|its gates are' plugins/product-workflows/ --include=*.md | grep -v CHANGELOG
```

- [ ] **End-to-end read.** Read `commands/brd-package.md` Phase 8 in full, in order, as an agent executing it would — the two most expensive misses on the gate-3 branch contained none of the swept phrases and were found only this way.

- [ ] **Re-run all seven gates on the branch tip**, and record the `validate-catalog.py .` warning count.

## Self-review

**Spec coverage.** §2 → Tasks 2 and 3. §3 → Task 2 step 2 item 2. §4 relations 1 and 3 → Task 2 step 2 item 3; relation 2 → Task 1 plus Task 2. §5 → Task 2 step 2 item 4 and Task 3 step 4. §6 → Task 3 steps 3. §7 → Task 2 step 2 item 5. §8 is out-of-scope statements, carried into Task 4's changelog. §9's three risks → the mismatch stop's two-id requirement (Task 3 step 3), the derive-don't-copy rule (Task 2 step 4), and the partition assertion, which §6.1 states.

**One gap, named rather than papered over.** The spec's §9 third risk — that a future flattening of the bundle would silently make relation 1 resolve everything against one corpus, and would then *pass* — has no mechanical guard in this plan, because there is no bundle in this repository to assert against. Task 2 states the invariant in §6.1 prose. That is weaker than a check, it is the honest ceiling for an instruction file, and it should be said in the changelog rather than left for a reader to discover.
