# Split increment 3 — `docs-workflows` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract `docs-workflows` — 3 commands, 7 agents, 12 reference files, 1 skill and its own hook — out of `dev-workflows`, depending on `workflows-core`.

**Architecture:** The same shape increment 2 proved: shared references live in `workflows-core` and are reached through `Skill(skill: "workflows-core:reference", args: "<name>")`, because `${CLAUDE_PLUGIN_ROOT}` resolves to the reading plugin. Agents cross natively as `subagent_type: "<plugin>:<agent>"`. Unlike increment 2, **the citations are rewritten as the files move, not afterwards** (spec §7), so this increment has no red window.

**Tech Stack:** Claude Code plugin manifests, markdown command/agent/reference files, bash (`scripts/check-docs.sh`), python (`scripts/validate-catalog.py`).

**Spec:** `docs/superpowers/specs/2026-09-02-marketplace-split-design.md` — S1–S18, §4, §5, §6 (including *What a new plugin must ship* and *What increment 2 learned*)

## Global Constraints

- **No behaviour changes.** Every command does exactly what it did at `eef3119`. (§9)
- **`dev-workflows` goes to 3.27.0** — a minor bump; 4.0.0 marks the end state of the whole split and no increment is published on its own. (S17)
- **`docs-workflows` starts at 1.0.0**, declaring `"dependencies": ["workflows-core"]` bare-name. (S6, S8)
- **`prose-style` becomes a declared dependency of `docs-workflows`, and its graceful-skip branches are deleted** (S12). Its optionality is an artefact of plugin dependencies not existing when it was written. Measure the skip branches before deleting; an unsatisfied dependency disables the plugin, which makes them unreachable.
- **Nothing is released while a known defect is open** (S18) — this increment may defer a fix, the release may not. Ledger: PS1–PS10 in the increment-2 plan.
- **All SEVEN gate invocations green — take the list from `.github/workflows/validate-catalog.yml`, never from this plan.** Increment 2's plan copied that list and went stale, leaving the session-cost selftest red across two tasks.
- Prose is never hard-wrapped; `.claude-plugin/marketplace.json` is not reformatted; **stage explicit paths, never `git add -A` at repository scope**.

---

## The measured allocation

Derived from the tree at `eef3119` by increment 2's rule — a file moves when more than one post-split plugin would load it — with dispatch edges from `subagent_type` and load edges from `${CLAUDE_PLUGIN_ROOT}` paths.

**The partition is exact: zero multi-group files and zero orphans.** Every reference and agent left in `dev-workflows` belongs to exactly one of pm / dev / docs. That is direct evidence increment 2 pulled out precisely what was shared, and it means this increment needs no promotion decisions.

### Moves to `docs-workflows`

**Commands (3):** `document.md`, `docs-profile.md`, `release-notes.md`

**Agents (7):** `diff-summarizer`, `doc-location-finder`, `doc-planner`, `doc-reviewer`, `doc-writer`, `docs-style-checker`, `release-notes-writer`

**Reference files (12):** `finish-and-handoff.md`, `gate-ledger.md`, `release-note-types.md`, `repo-verification-gates.md`, `toolchain-preflight.md`, `handoff/diff-summarizer.md`, `handoff/release-notes-writer.md`, and the five under `docs-profiles/` — `anchor-conventions.md`, `changelog-guidelines.md`, `docs-profile-schema.md`, `frontmatter-guidelines.md`, `render-verification.md` — **plus the non-markdown files in that subtree** (`docs-profile.default.yml` and its siblings), which move with it and appear in no inventory row, exactly as `cost-prices.yaml` did.

**Skill (1):** `docs-frontmatter/` — consumed by `/docs-profile` alone.

**Documentation (3 command pages):** `docs/commands/{document,docs-profile,release-notes}.md`.

**Not moving:** `scripts/specification-to-html.py` (consumed by `/specify` and `specification-format.md`, both pm — it goes in increment 4).

**The spec said fourteen references; it is twelve.** Two of the fourteen — `doc-structure-conventions.md` and `docs-grounding.md` — turned out to be multi-group and went to `workflows-core` in increment 2. Re-derive rather than trusting either number.

**After this increment `dev-workflows` ships 17 commands, 24 agents, 24 reference files.**

### `docs/reference/` pages do not move — R6 still holds, for the opposite reason

Increment 2 established that a documentation page documents a subsystem **from the invoking side**. There the mechanism moved and the invokers stayed, so the pages stayed. Here the invokers move — but `dev-workflows` keeps seventeen commands that still emit cost, still get feedback, still resume, so its pages stay true of it. `docs-workflows` **authors** whatever its own gate obligations require, derived by running the gate rather than copied. At minimum: `agents.md` and `references.md` (check 4), and a `session-cost.md` carrying the cost-emitting-set count sentence (check 9) — **derive that count from the extractor, not by eye**: increment 2's equivalent was wrong in the plan and caught only in review.

---

### Task 1: Create the `docs-workflows` skeleton and register it

**Files:** create `plugins/docs-workflows/.claude-plugin/plugin.json`, `README.md`, `LICENSE`, `CHANGELOG.md`, `docs/{README,getting-started,workflow}.md`, `docs/reference/{agents,references,environment}.md`; modify `.claude-plugin/marketplace.json`, repo-root `README.md`, `scripts/check-docs.sh`.

The plugin ships **nothing** at the end of this task, which is how increment 1 and 2 both proved the ten-row checklist in spec §6 before any content was at stake.

- [ ] **Step 1: Manifest.** Name, description (≤1024 chars, byte-identical in `plugin.json` and the `marketplace.json` entry), version `1.0.0`, author `{"name": "Ivan Gudak", "email": "ihudak@gmail.com"}`, plus `homepage`, `repository`, `license` and `keywords` — every sibling carries all four, and increment 2 shipped without them and had to add them later. Declare `"dependencies": ["workflows-core", "prose-style"]` (S12).
- [ ] **Step 2: Repo-root README first.** Add the install line and a plugin-table row **before** writing `getting-started.md` — check 7 tests that the plugin's install block is a subset of the root README's, so the root must gain the line first. Keep every table cell ≤200 characters (check 6) **and keep the `[Docs]` link**: increment 2 traded it away to fit and had to trade it back.
- [ ] **Step 3: Register** in `.claude-plugin/marketplace.json`, matching existing entries' shape exactly; do not reformat the file.
- [ ] **Step 4: The four required pages.** `docs/README.md` (index), `docs/getting-started.md` (the sanctioned exception that may name the marketplace), `docs/workflow.md` (**must contain a real ```mermaid block** — check 15 asserts diagram membership, and prose below a diagram does not count), and the three `docs/reference/` inventories. Write counts as the **digit `0`** while empty: check 9's accepted word list runs `one`…`ten` and has no "zero".
- [ ] **Step 5: Gate config.** Add `plugins/docs-workflows` to `PLUGIN_RELS` in `scripts/check-docs.sh`. Leave `COST_PLUGIN_RELS` and `HANDOFF_PLUGIN_RELS` alone — those are re-based on **call sites** (increment 2's R7), so they follow the commands in Task 3, not the empty plugin here.
- [ ] **Step 6: Run all seven gates.** Expected: all PASS.
- [ ] **Step 7: Commit.**

---

### Task 2: Move everything, rewriting citations as they move

**Files:** `git mv` the 3 commands, 7 agents, 12 references + the `docs-profiles/` non-markdown files, the `docs-frontmatter/` skill, and 3 documentation pages; modify both plugins' inventories, counts and diagrams; modify `scripts/check-docs.sh` config.

**Citations are rewritten in the same commit as the move** (spec §7), so unlike increment 2 there is no red window. That is the whole reason this increment is cheaper than the last one.

- [ ] **Step 1: `git mv` every path.** Never copy-and-delete; history must follow the files.
- [ ] **Step 2: Rewrite every core citation in the moved files** to the loader form — `Skill(skill: "workflows-core:reference", args: "<name>")` for a load or entry point, `workflows-core:<name>` for a prose anchor — and add the **Core references preamble** to every moved file that carries one. Copy the preamble text verbatim from an existing `dev-workflows` command; check 16 relation 3 gates its presence over `commands/`, `agents/` and `references/`.
- [ ] **Step 3: Rewrite every dispatch and command namespace.** `subagent_type: "dev-workflows:<moved-agent>"` → `"docs-workflows:<agent>"`, and `/dev-workflows:<moved-command>` → `/docs-workflows:<command>`, **in both plugins and in `workflows-core`**. Use word boundaries. Then assert zero remain, excluding `CHANGELOG.md`, which is history.
- [ ] **Step 4: Add `Skill` to the `tools:` allowlist of every moved agent that carries a loader call or the preamble.** Increment 2's blocker: all 31 agents declared a `tools:` list and none included `Skill`, so six agents were handed calls they could not execute. Commands are unaffected — they already grant it.
- [ ] **Step 5: Demote any citation that now dangles in either direction** — a moved file citing something left behind, or a file left behind citing something moved — to a bare name, never by promoting the target. Enumerate them; do not work from a list.
- [ ] **Step 6: Update the gate's applicability lists.** `COST_PLUGIN_RELS` and `HANDOFF_PLUGIN_RELS` are keyed on **call sites** (R7): add `plugins/docs-workflows` iff its commands carry `emit-cost` call sites / commands of the `next-phase-offer` family. Derive, do not assume.
- [ ] **Step 7: Update both inventories and every count sentence**, on both sides: `agents.md` rows, `references.md` flat rows and subtree counts (**markdown-only**), `environment.md` in both directions (check 5 fires twice on a move), the two `docs/README.md`s, both plugin READMEs, both `docs/workflow.md` mermaid diagrams — **removing the departed commands from `dev-workflows`'s diagram by hand, since check 15 is forward-only.**
- [ ] **Step 8: Verify the counts**: `docs-workflows` 3 commands / 7 agents / 12 reference markdown files / 1 skill; `dev-workflows` 17 / 24 / 24. **Step 9: Gates. Step 10: Commit.**

---

### Task 3: Give `docs-workflows` its own hook, and narrow `dev-workflows`'s

**Files:** create `plugins/docs-workflows/hooks/hooks.json` and its scripts; modify `plugins/dev-workflows/hooks/preload-context.sh`.

**Ordered after the move deliberately.** Step 3 narrows `dev-workflows`'s regex to the commands it still ships — which is only true once Task 2 has moved them. Running it first would strip the preload from two commands that are still in the plugin. Nothing breaks in the window between: a `UserPromptSubmit` hook fires on every prompt regardless of which plugin ships it, so the old regex keeps working until it is narrowed.

**This is the one thing neither earlier increment faced, and spec §6's checklist does not mention it, because `guideline-reviewers` and `workflows-core` ship no hooks.** `dev-workflows`'s `preload-context.sh` fires on `UserPromptSubmit` and matches `^/(implement|document|epics|release-notes|vuln|upgrade)`. **Two of those six — `/document` and `/release-notes` — move in this increment.** Hooks do not cross a plugin boundary (§4): each plugin ships its own, and `${CLAUDE_PLUGIN_ROOT}` in `hooks.json` is correct only for the plugin that ships it.

The failure is quiet rather than loud, which is why it needs naming: a `UserPromptSubmit` hook fires on every prompt in a session regardless of which plugin ships it, so **as long as both plugins are installed the preload keeps working and nothing looks wrong**. It breaks for the user who installs `docs-workflows` and not `dev-workflows` — which is now a supported configuration, since `docs-workflows` depends on `workflows-core`, not on `dev-workflows`.

- [ ] **Step 1: Read `preload-context.sh` end to end** and establish exactly which branches serve `/document` and `/release-notes` — its header comment routes them differently (`/document` gets specs context only when its argument is an address; `/release-notes` gets `$SPECS_PATH` + `$REPOS_PATH`). Do not split by pattern-matching the regex alone.
- [ ] **Step 2: Give `docs-workflows` a hook** carrying those two branches, with its own `hooks.json` using `${CLAUDE_PLUGIN_ROOT}`. Hook scripts must exit 0 always — a hook must never block Claude.
- [ ] **Step 3: Narrow `dev-workflows`'s regex** to the four commands it still ships, and update the header comment, which enumerates all six by name.
- [ ] **Step 4: Move `changelog-owners-reminder`, which Task 2 broke — and note *why* this step's original wording would have missed it**

Task 2 found and reported this itself. `hooks/changelog-owners-reminder.py` reads two files under its own `${CLAUDE_PLUGIN_ROOT}` — `references/docs-profiles/default-owners.txt` (line 63) and `references/docs-profiles/docs-profile.default.yml` (line 93) — and **both moved to `docs-workflows` in Task 2**. Verified: neither path now exists under `plugins/dev-workflows/`. The hook swallows the `OSError` and still exits 0, so it **fails silently**, losing the owners check and the built-in default profile with no signal at all.

This step originally asked only about **command-name** coupling. That is the wrong question: this is **reference-path** coupling, and no amount of grepping for command names would have surfaced it. Move the hook and its `hooks.json` entry to `docs-workflows`, where its data now lives. `dev-workflows/docs/reference/hooks.md` currently documents the degradation as an interim truth — remove that once the hook moves, and make sure `docs-workflows`'s own `hooks.md` and hook count replace it.

- [ ] **Step 4a: Now check the remaining two hooks — `notify-done.sh` and `test-notify.sh` — for coupling of *either* kind**: a command name, and a path into `references/`, `agents/`, `commands/` or `skills/`. Report what you find even if the answer is none.
- [ ] **Step 5: Update both plugins' `docs/reference/hooks.md`** and their hook-count sentences (check 9 gates the count).
- [ ] **Step 6: Gates. Step 7: Commit.**

---

### Task 4: Delete `prose-style`'s graceful-skip branches (S12)

**Files:** every file that guards a `prose-style` call behind an availability check.

S12: with `prose-style` a declared dependency, an unsatisfied dependency disables the plugin, so the skip branches are unreachable — and keeping unreachable branches is its own defect. For `/epics` it is the **primary** style checker, so "skipped gracefully" meant no style check at all.

- [ ] **Step 1: Measure first.** Find every skip branch in the moved files and report the count before deleting; the spec's figure (22 branches across 18 files) predates two increments and covers plugins this task does not touch. **Only `docs-workflows`'s own files are in scope** — `/epics` is pm's and moves in increment 4.
- [ ] **Step 2: Delete them**, leaving the call unconditional. **Step 3: Gates. Step 4: Commit.**

---

### Task 5: Close the increment

- [ ] **Step 1: Bump** `dev-workflows` to 3.27.0; `docs-workflows` stays 1.0.0.
- [ ] **Step 2: CHANGELOGs.** `dev-workflows`'s entry leads with the install command (S17). `docs-workflows` 1.0.0 lists every moved command and its new namespace.
- [ ] **Step 2a: One contradiction to resolve while you are in `CLAUDE.md` — found by Task 2's resolution pass, and pre-existing rather than split-caused.**

`CLAUDE.md`'s `/document` (direct mode) invariants say *"**No branch creation by default** — it works on the current branch unless the user requests one"*. The command is stronger: `commands/document.md:1352` says *"**Do NOT create a branch, and do NOT commit the doc edits.** The user manages git manually for doc edits."* Never, not "not by default", and no user-request escape. Two live contradictory instructions is the defect `workflows-core:instruction-file-maintenance` names, and the rule there is that the **thing that runs** is the authority — verify against `document.md`'s own Phase 3 and rewrite `CLAUDE.md` to match, not the reverse. Check whether the same sentence was carried into `docs-workflows`'s documentation pages.

- [ ] **Step 2b: Bridge the twelve-versus-fourteen reference count, once, where a reader meets both.**

Three statements about `docs-workflows`'s corpus are each true and read as contradictory: the description says "twelve reference **pages**", `README.md` says "14 reference **files**", and `docs/reference/references.md` says "bundles 14 files". Twelve markdown pages, fourteen files — the extra two being `default-owners.txt` and `docs-profile.default.yml`, data the hook reads rather than pages anyone reads. My earlier ruling fixed the description's noun and stopped there, which was half a fix: **a reviewer with full context still read the pair as a contradiction**, which is the evidence that the distinction is not landing on its own.

State the relationship explicitly in `README.md`, where both numbers meet — twelve markdown reference pages plus two bundled data files, fourteen in all — rather than leaving a reader to infer it from two different nouns. Do not change the description; it is at 887 of a 900-character warning and is correct as written.

- [ ] **Step 2c: Finish `workflows-core:dependencies`, which Task 4 deliberately left half-updated.**

Task 4 fixed only the clause its own change falsified — the `prose-style` companion row, which now correctly says *"Optional companion there, **declared dependency** of `docs-workflows`"*. It reported the rest as out of its scope, which was right. What remains:

- The **Marketplace siblings** section opens *"Four plugins ship alongside this family"* and lists `prose-style`, `obsidian-llm-wiki`, `guideline-reviewers`, `acli`. `docs-workflows` is now a **family member**, not a sibling, so the framing and any count that follows from it need re-deriving.
- That section calls `prose-style` *"the one sibling this family resolves **at runtime**"*. It is now a **declared dependency** of `docs-workflows` and a runtime resolution for `dev-workflows` — two different relationships in one sentence, which is the shape §12 of this same file warns about.

Re-derive both against the tree rather than editing the numbers in place.

- [ ] **Step 3: `CLAUDE.md`** — the workflow map, the per-plugin counts, the active-plugins paragraph, and every reference path that moved. **Nothing gates any path or number in this file**; increment 2 left eleven stale paths there and found them only by a hand sweep. Re-derive.
- [ ] **Step 4: Closing sweep — re-derive, do not trust.** Assert zero `dev-workflows:<moved-agent>` and `/dev-workflows:<moved-command>` tokens outside `CHANGELOG.md`; zero dangling `${CLAUDE_PLUGIN_ROOT}` paths in all four plugins; every loader `args:` first token resolving; `dependencies` parsed from JSON (never grepped — `keywords` contains the word); and every `CLAUDE.md` reference path resolving.
- [ ] **Step 5: All seven gates. Step 6: Commit.**

---

## Verification (after the branch is green, before the merge)

Skill discovery is session-start-bound, so every check runs in a session started **after** installation. `claude plugin marketplace add` accepts a **local path**, so no push is needed.

1. Install `docs-workflows` alone; confirm `workflows-core` and `prose-style` both arrive as declared dependencies.
2. `/docs-workflows:document` runs end to end against a real docs repo (spec §7's stated verification for this increment).
3. A two-argument loader call from a moved command executes — the branch increment 2 proved, re-checked from a new plugin.
4. A moved agent dispatches and returns, confirming Task 3 Step 4's `Skill` grant.
5. The new hook fires for `/document` with `dev-workflows` **not installed**.
