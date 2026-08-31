# Specs-Native Pipeline — Increment C: refill what the tracker supplied

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild, inside the specs tree, the four things the tracker export used to supply — the Epic hierarchy, the record of where implemented work landed, the release-note destinations, and the workflow status — so that increment B's stated degradations close.

**Architecture:** `/epics` mints Epic keys and writes `epic.md` into `EPIC-` folders, which *is* the linked-item hierarchy. `/implement` writes `implementation.md`, an append-only pointer record, and adopts a commit convention it also teaches. `/document` and `/release-notes` diff from that record **plus** a scan of commit messages for the run's own identifiers, which recovers work the plugin did not do. Release notes move into the PRD folder as three sections of one file. `/ready` derives the phase from artifacts and gains `--claimed`.

**Tech Stack:** Markdown only. No test framework. The cycle is a **failing grep assertion**, then the edit, then the same assertion passing, then the three repository gates.

**Spec:** `docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` §§6.3, 6.4, 7.1–7.5, and §11's increment C.

**Predecessors:** increment A (PR #32, v3.5.0) and increment B (PR #33, v3.6.0), both merged.

## What C is closing

Increment B left three things stated-but-unbuilt. C is where each lands, and the plan is organised around them rather than around the spec's clause order:

| B left | C builds |
|---|---|
| `/document` and `/release-notes` say "no diff source exists yet" | `implementation.md` + the commit scan |
| `/implement`'s Epic picker shows ○/◐ and says ● is not determinable | `implementation.md` supplies ● |
| `/release-notes` states the no-version-in-a-title rule **inverts** but the section heading has not landed | `release-notes.md` with three sections and a version heading |

**A task that leaves one of those half-built is worse than one that does not start it**, because B's text already promises the reader that C closes them.

## Global Constraints

- **Every constraint from increments A and B still binds** — one key grammar, `<KIND>-<KEY>-<slug>/` directories, a three-level bound, `resolve-address` as the only resolution entry point, `key-valid` as the only validator, no tracker read by any mechanism, and no vendor name in prose outside the three recorded exceptions.
- **`$VAULT_PATH` is still not deleted.** That is increment D. C may *stop writing* to it where the specs tree is now the right home, but must not remove the variable or its documentation.
- **`implementation.md` is a pointer, not a record** (D9). It holds refs, never a summary of what was implemented — a summary is a description, and `source-truth.md` exists because descriptions drift from code.
- **The commit scan searches for tokens the run already holds** (`key`, `workitem_key`), never a pattern extracted from a commit message. That is the difference between resolution and guessing, and `CLAUDE.md`'s standing rule is about exactly this.
- **Branch first.** Every task commits to `iv-gu/specs-native-increment-c`, never to `main`.

## Repository Gates — run after every task

```bash
cd /workspace/ihudak-claude-plugins
./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && python3 scripts/validate-catalog.py
```

**Check 9's counts move in this increment**: `references/` gains at least `implementation-format.md`. Re-derive with a command; never decrement or increment by hand — increment B moved that arithmetic twice and never by the amount a guess would have given.

## Assertion discipline — carried forward

Increment A's suites misreported six times and increment B's sweeps introduced a duplicate YAML key and three orphaned sentence fragments. The rules that caught those:

1. **Run every assertion before the edit and require it to fail.** An assertion that already passes tests nothing, or tests the wrong thing.
2. **Read which lines flipped**, never the exit code alone.
3. **Never `sed`-patch a shell string containing backticks**, and never build a search string from context output where newlines were rendered as spaces — both produced silent misses in B.
4. **Always run from the repository root.** The Bash tool's working directory persists.
5. **When an assertion fails on correct content, fix the assertion.** Twice in A that call prevented a real regression.
6. **After any multi-file substitution, read the changed lines.** Three of B's defects were grammatical wreckage a substitution left behind, and no gate can see them.

---

### Task C1: `implementation.md` and the commit convention

**Files:**
- Create: `references/implementation-format.md`
- Modify: `commands/implement.md` — a new terminal phase, and the branch/commit steps
- Modify: `commands/vuln.md`, `commands/upgrade.md` — the commit convention only
- Modify: `references/branch-naming.md` — the key in the branch name
- Modify: `docs/reference/references.md` (new entry + count), `docs/commands/implement.md`, `docs/commands/vuln.md`, `docs/commands/upgrade.md`
- Modify: `CLAUDE.md` — the reference inventory and `/implement`'s workflow-map line

**Interfaces:**
- Produces — the record every later task in this increment reads:

```markdown
# Implementation — <KEY> <title>

## <YYYY-MM-DD> — /implement
- repo:    orders-service
  branch:  feat/ACME-77-01-order-intake
  base:    main
  commit:  a3f91c2          # squashed
  pushed:  true
```

  Append-only, one block per run, one entry per repository — the shape `grounding/baselines.md` already uses.

- Produces — the commit convention, which is **written as well as read** (spec §7.3.1):
  - the commit **subject** ends with `[<key>]`;
  - a `Work-Item: <workitem_key>` trailer when the folder carries one;
  - the branch carries the key: `<prefix>/<key>-<slug>`.

- [ ] **Step 1: Branch and write the failing assertion** (`scratchpad/assert-c1.sh`): `references/implementation-format.md` exists and is in `docs/reference/references.md`; `commands/implement.md` names `implementation.md` and `[<key>]`; `vuln.md` and `upgrade.md` name the subject convention; the reference-file count matches `find references -type f | wc -l`.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: Write `references/implementation-format.md`** — the block shape, the append-only rule, the two limits (direct mode writes nothing; the plugin knows only what it did, **which §7.3.1's scan is what softens**), and *why it holds no summary*: a ref cannot drift, a description can, and `pushed: false` is recorded so a later run says "this was never pushed" rather than reporting an empty diff.

- [ ] **Step 4: `/implement` writes it** in a new terminal phase, before the emitter tail. Keyed runs only.

- [ ] **Step 5: The commit convention, in all three commands.** Subject, not trailer — a trailer does not survive `git log --oneline` and is invisible to the person deciding what their own commit should look like. `/vuln` and `/upgrade` adopt the subject and branch halves; **they do not write `implementation.md`**, because neither resolves a PRD folder.

- [ ] **Step 6: Document the convention as a convention** — a `docs/reference/` section a contributor who has never run `/implement` can follow.

- [ ] **Step 7: Assertion green, gates green, commit**

---

### Task C2: `/epics` mints keys and writes `epic.md`

**Files:** `commands/epics.md`, `agents/epic-writer.md`, `agents/epic-reviewer.md`, `references/epic-picker.md` (the ● predicate), `docs/commands/epics.md`, `CLAUDE.md`.

**Interfaces:**
- Consumes: `resolve-address`, the `key:` frontmatter (A), `epic-picker.md` (B).
- Produces: `EPIC-<PRD-KEY>-NN-<eslug>/epic.md` under the PRD folder — **the linked-item hierarchy every other command now enumerates**.

- [ ] **Step 1: Write the failing assertion** — `/epics` names `EPIC-<PRD-KEY>-NN`, writes `epic.md`, and no longer resolves an `output_dir` under `$VAULT_PATH`.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: Mint the key** — `<PRD-KEY>-NN`, the next unused two-digit segment, operator may override, validated with `key-valid` and **re-prompted rather than coerced**. This is `/brd-split` Phase 3 step 1's mechanism; cite it rather than restating it.

- [ ] **Step 4: Write `epic.md`** into `EPIC-<PRD-KEY>-NN-<eslug>/`, with `kind: epic` and `key:` frontmatter per A. The output-directory prompt and its `$VAULT_PATH` / `epic-drafts/` ladder go: there is one home now, and it is derived rather than asked for.

**`_coverage.md` needs a decision, not a default.** It is PRD-holistic and belongs to no single Epic, so it lands in the PRD folder, not in any `EPIC-` folder. Say so where it is written.

- [ ] **Step 5: The refine mode** — `/epics <EPIC-ADDRESS>` and `/epics @<file>` both re-ground an Epic that exists. Refine's job changed when the tracker went (spec §6.3): it used to fill in empty Epics somebody else created, an artefact of one organisation's tooling. Say what it means now rather than letting a reader assume continuity.

- [ ] **Step 6: `epic-picker.md`'s ● predicate** — with `epic.md` and `implementation.md` both real, the picker's three markers are all determinable. Remove B's "● is not determinable in this increment" note **and the sentences in `/implement` that cite it**.

- [ ] **Step 7: Documentation, gates, commit**

---

### Task C3: Release notes land in the PRD folder

**Files:** `commands/release-notes.md`, `references/release-note-types.md`, `agents/release-notes-writer.md`, `references/handoff/release-notes-writer.md`, `docs/commands/release-notes.md`.

**Interfaces:**
- Produces: `release-notes.md` in the PRD folder, with the three destinations as **sections** and the release version as the **section heading**.

- [ ] **Step 1: Write the failing assertion** — `release-notes.md` is named as the output; the three destinations are sections; the version-in-heading rule is stated as current rather than as forthcoming.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: The destination map becomes a section map.** The taxonomy stays — breaking change / feature update / fix is universal, and `release-note-types.md` remains the authority for per-type shape, prose rules, and the deprecation note with its required end-of-life date. Only *where a draft lands* changes.

- [ ] **Step 4: Land the inversion B recorded.** `/release-notes` currently says the no-version-in-a-title rule *is about to* invert. Make it current: the version is the section heading, and the prohibition survives for body prose alone. **Delete the forward-looking sentence** — a note saying a thing has not shipped, left standing beside the shipped thing, is its own defect.

- [ ] **Step 5: Retire `{{#context}}`.** It is a docs-automation macro; in a plain markdown file it renders as literal text. A plain label does the same job. This touches the writer agent and its handoff contract as well as the command.

- [ ] **Step 6: Documentation, gates, commit**

---

### Task C4: `/document` and `/release-notes` diff again

**Files:** `commands/document.md`, `commands/release-notes.md`, `agents/diff-summarizer.md`, `references/handoff/diff-summarizer.md`, `references/implementation-format.md` (the consumer rules), docs pages.

**Interfaces:**
- Consumes: C1's `implementation.md`.
- Produces: the two consumers reading it, **and** the §7.3.1 commit scan.

- [ ] **Step 1: Write the failing assertion** — neither command says "no diff source exists"; both name `implementation.md`; both name the commit scan and its honesty report.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: Wire the two consumers, with different boundaries.** `/document` reads **every** block under the PRD — it documents the feature as it now stands. `/release-notes` reads **only blocks appended since the last section was written**, because a second release must not re-describe the first one's work; the file's own last-written date is the boundary, and **the run names the blocks it used** so a wrong boundary is visible rather than silent.

- [ ] **Step 4: The commit scan** (spec §7.3.1). `git log --grep` for the folder's `key` and its `workitem_key`, over the repos `implementation.md` names — or, when it names none, the repos resolved from `$REPOS_PATH`. Merge and dedupe by SHA; report what it finds beyond the recorded blocks as **unrecorded work**, named as such. **The run reports how many commits it scanned and how many matched**: a zero-match scan in a repository with commits is a signal about the convention, not proof that no work happened.

- [ ] **Step 5: Delete B's degradation notices** in both commands. They named an absence that has ended.

- [ ] **Step 6: Documentation, gates, commit**

---

### Task C5: `/ready` derives the phase

**Files:** `commands/ready.md`, `references/workflow-states.md`, `agents/readiness-reviewer.md`, `docs/commands/ready.md`.

**Interfaces:**
- Produces: `--claimed "<status>"`, and a verdict that reads *"this PRD is at Ready for Implementation, and here is what is missing to leave it."*

- [ ] **Step 1: Write the failing assertion** — `--claimed` is parsed and documented; `workflow-states.md`'s ladder is read artifacts-first; no phase reads a declared status as ground truth.

- [ ] **Step 2: Run it, confirm every line fails**

- [ ] **Step 3: Invert `workflow-states.md`.** Its *expected artifacts* column becomes the rubric. **B already rewrote the file's opening claim**; this is the table and the per-status rules following it.

- [ ] **Step 4: `--claimed "<status>"`.** Anyone with a tracker pastes what it says and gets exactly the old divergence check, with no dependency on which tracker. Without it, a derived phase cannot contradict itself — **state that cost where the flag is documented**, not only in the spec.

- [ ] **Step 5: `readiness-reviewer`'s inputs** change from declared statuses to derived phases plus an optional claim. Its verdict vocabulary (SUPPORTED / PARTIAL / NOT-SUPPORTED) is unchanged.

- [ ] **Step 6: Documentation, gates, commit**

---

### Task C6: Residue audit and increment review

- [ ] **Step 1: Re-run every assertion suite** — A's, B's, and C's. A and B's are the regression check.

- [ ] **Step 2: The four mechanical sweeps** — stop codes; agents dispatched vs documented (bare names, under-report direction); documented flags vs parsed flags (filter git flags); produced-artifact tables vs `deliverable_paths`.

- [ ] **Step 3: The residue audit** — *what did this increment make false?*

| Phrase | Why it may now be false |
|---|---|
| `no diff source`, `until increment C`, `does not exist yet` | C is that increment |
| `● is not determinable` | `implementation.md` supplies it |
| `is about to invert`, `arrives with that file` | it arrived |
| `epic-drafts`, `output_dir`, `jira-drafts` | one home now |
| `{{#context}}` | retired |
| `three destinations`, `destination map` | three sections |
| `declared status`, `status is read` | derived |

**Every one of these is a promise increment B made to the reader.** A stale forward-reference is worse than a stale claim, because it tells the reader to expect something that has already happened.

- [ ] **Step 4: Re-derive every count.** `references/` gains at least one file.

- [ ] **Step 5: Read every changed command end to end.** Not a diff read.

- [ ] **Step 6: Fix every defect found**, unrelated ones in their own PR.

- [ ] **Step 7: Version bump, changelog, gates, PR.** Minor. **Do not touch the plugin description** — 883 of a 900-char threshold, and rewriting it is increment D's.

---

## Self-Review

**Spec coverage — increment C's six clauses, mapped:**

| Spec §11 increment C clause | Task |
|---|---|
| "`/epics` mints keys and writes `epic.md`" | C2 |
| "`/implement` writes `implementation.md`" | C1 |
| "`/document` and `/release-notes` diff from it" | C4 |
| "`release-notes.md` lands in the PRD folder with sections not destinations" | C3 |
| "`/ready` derives the phase and gains `--claimed`" | C5 |
| "`workflow-states.md` is inverted" | C5 |
| §7.3.1's commit convention (written) and scan (read) | C1 (written), C4 (read) |
| §11 "Verification" + "Review protocol" | C6 |

**One thing this plan adds that §11 does not name:** the §7.3.1 commit convention, which was added to the spec after §11 was written. It splits across C1 and C4 because writing it and reading it are different commands.

**Placeholder scan:** none. Every step names the file and what the replacement must say.

**Name consistency:** `implementation.md`, `epic.md`, `release-notes.md`, `--claimed`, `--version` match the spec and increments A/B.

**What C deliberately does not do:** delete `$VAULT_PATH` or `vault-prior-art-finder` (D), rewrite the plugin description (D), or add prior-art discovery over the specs tree (a separate design, spec §8.2).
