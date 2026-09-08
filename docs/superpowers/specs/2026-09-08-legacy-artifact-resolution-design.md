# Legacy artifact resolution — design

**Ledger item:** E-6, widened. Filed as a `/prd-ground` defect; the measurement found the class covers ten commands, three disagreeing implementations and five absences.

**Status:** design approved 2026-09-08. Blocks release under S18.

---

## 1. What is wrong

`workflows-core:addressing` §5 makes a promise to every operator whose specs repo predates the kind prefixes: *"Renaming a folder is one `git mv`, and the fallback means they need never do it."*

That promise covers **folder names**. The artifact half of it was built, deliberately kept once, and then deleted.

**It existed.** `75029fe` (2026-08-31) turned three glob resolvers into filename tests and reasoned explicitly about what to keep: *"`prd-source-resolution.md` keeps the `issue_type: ValueIncrement` check alongside the filename: a specs repo written before the rename still holds `<KEY>_<slug>.md`, which the legacy fallback resolves the folder for and **which that check is what identifies inside it**."*

**It was deleted.** `469c656` removed `prd-source-resolution.md` on the ground that the round-trip premise was false: *"what remained was 'resolve the folder, read `prd.md`' — two obvious lines, inlined into its two callers. **Duplicating those is not the drift risk that duplicating a key grammar was.**"*

What remained was three lines, not two, and the third was the legacy identification. Both callers lost it in the same commit. `/update-prd` gained *"It is the `prd.md` in the folder step 3 resolved — the only copy there is, and therefore **authoritative without a test**"* — the deleted rule restated as an assertion that no rule is needed. `/create-prd` gained a test for `kind: prd`, a field `1da7480` introduced **in the same commit as the rename**, so no genuine legacy file can ever carry it.

The duplication then drifted exactly as the deleted rule predicted.

### 1.1 The drift, measured

| Command | How it names the PRD | What a genuine pre-rename tree does |
|---|---|---|
| `/create-prd` step 6 | `prd.md`, legacy `<KEY>_<slug>.md` "and `kind: prd` is what identifies the draft inside it" | finds the file, cannot recognise it, treats the folder as greenfield — **authors a second PRD beside the first** |
| `/create-ard` Phase 0, `/specify` Phase 0 | `ls-tree` the ref; `prd.md`, else "a `<PRD>_*.md` entry" | `1da7480`'s diff names the legacy ARD `<PRD>_ARD.md`, which that glob matches and which sorts ahead of `<PRD>_<slug>.md` — **the PRD gate gates the ARD** |
| `/update-prd` step 4 | `prd.md`, "authoritative without a test" | `UPDATE_PRD_NO_PRD`, whose remedy table names `/create-prd`, which finds the PRD and redirects back to `/update-prd`. **A closed loop: neither command can run** |
| `/prd-ground` steps 5a, 6i, 8i | `prd.md` present and asserting `kind: prd` | the route split takes the interrupted-intake branch and stops with `PRD_GROUND_NO_INVENTORY`, naming a `@<brd-file>` that operator never had — **E-6 as originally filed** |
| `/epics` step 1b | `prd.md` asserting `kind: prd` | `EPICS_NO_PRD` — refused, and its remedy leads into the `/create-prd` behaviour above |
| `/release-notes`, `/document`, `/ready`, `/implement` | "the resolved folder's `prd.md`" | the read finds nothing and the run degrades silently |

**The shared authority carries the false premise too.** `product-workflows:coverage-ledger-format` §5.1 defines a legacy idea-route PRD folder as one *"holding `idea.md` and `prd.md`"*. That is the one folder shape §5's fallback exists to serve, and it does not hold `prd.md`. `epics.md:69` is a faithful restatement of §5.1 and inherits the error.

### 1.2 Why §4 could not answer this already

`addressing` §4 reads a folder's `kind` and `key` off frontmatter. `1da7480` introduced `kind:`, `key:` **and** the rename in one commit, so a genuine legacy folder holds **no artifact carrying either field** and §4 yields nothing for it. The tree already knows this — it is exactly why `coverage-ledger-format` §5.1 answers the BRD-versus-PRD question by file *presence* instead. The legacy story was built folder-name → folder-kind and then stopped, one step short of the artifact.

---

## 2. The rule

Two edits to `workflows-core:addressing`: an entry point in §3, beside its siblings, and a closed table in §5, beside the promise it completes.

### 2.1 Entry point (§3)

```
### Entry point: `resolve-artifact <KIND> <folder> [<ref>]`

status:  found | absent | ambiguous
paths:   [ <absolute path>, … ]     # found and ambiguous only
legacy:  true | false               # found only; true when §5.1's table resolved it
```

`<KIND>` is exactly `prd` or `ard` — the two artifacts the rename touched, and §5.1 states why the set is closed. `<folder>` is the folder a caller already resolved, never a path re-derived here. With `<ref>`, candidates come from `git -C "$SPECS_PATH" ls-tree --name-only <ref> <folder>/` and a frontmatter test reads `git show <ref>:<path>`; without it, from the worktree. The ref form is what the three `require-on-main` gates need.

1. **The current name first.** `prd` → `prd.md`; `ard` → `ard.md` **and** every `ard-<area>.md` beside it. Any present → return them, `legacy: false`.
2. **Otherwise §5.1's legacy table.**
3. **Neither → `absent`.** The caller's own absent branch runs, unchanged.

**Arity is per kind, and this is not an oversight.** A folder holds at most one PRD, so two surviving PRD candidates are `ambiguous` and the caller stops naming both — the same disposition `resolve-address` already gives an ambiguous folder. An ARD is legitimately several files on a current tree (`ard.md` plus per-area files), so multiple ARD paths are ordinary. On a legacy tree the ARD is always exactly one file: area-scoped ARDs postdate the rename, verified against all 32 pre-rename occurrences of the `_ARD.md` form.

**A half-migrated folder is settled by step 1 and needs no test.** Where a folder holds both a current and a legacy name, the current name wins. That is not a new rule — it is what `/create-ard` and `/specify` already do (*"take `prd.md` when the listing carries it"*), and it means an operator who renames one file at a time is never worse off mid-migration.

**A `legacy: true` result is reported once per run as deprecated**, in the same line §5 already uses for a legacy folder. One notice per run, not one per artifact.

### 2.2 The closed legacy table (§5.1)

| kind | current | legacy | what identifies the legacy file |
|---|---|---|---|
| PRD | `prd.md` | `<KEY>{-\|_}<slug>.md` | its frontmatter carries `issue_type:` |
| ARD | `ard.md`, `ard-<area>.md` | `<KEY>_ARD.md` | the `_ARD.md` suffix |

`<KEY>` is **the key the run already holds** — the folder's own key, from resolution. Candidate filenames are tested against it; nothing is ever parsed *out of* a filename to produce a key. That is `CLAUDE.md`'s standing rule and the shape `workflows-core:specs-repo-git` §3.5's `branch-key` already works in. The `{-|_}` tolerance and the human-adjusted slug are §5's own, applied to the filename rather than restated: an operator who adjusted one adjusted both.

**The PRD's name pattern matches the legacy ARD, and the frontmatter test is what separates them.** `<KEY>_ARD.md` satisfies `<KEY>{-|_}<slug>.md` with the slug `ARD` — which is precisely the collision `/create-ard` and `/specify` ship today, where the name is the only test. The two arms are ordered and both are read: a candidate carrying the `_ARD.md` suffix is the ARD, and a PRD is a candidate whose frontmatter carries `issue_type:`. Neither arm alone is sufficient, and a design that keeps only the names reproduces the defect.

**Both arms are positive evidence.** The ARD asserted its own kind in its filename before `kind:` existed, so its suffix is an assertion rather than an absence. The PRD's frontmatter field is the assertion `75029fe` already identified. Neither arm is "the one that is not the other" — this tree forbids an absence test, and `prd-ground.md` states the reason on every one of its own branches.

**Why this enumeration is permitted where §4 forbids one.** §4 bars a per-kind carrier list because *"it would be a list that goes stale the first time a command writes a new artifact, and nothing in `scripts/` would catch it."* This list cannot go stale that way: **no command writes a legacy name any more.** The set was frozen by `1da7480` and can change only if someone rewrites history. That sentence ships inside §5.1, because a reader who meets the table without it will delete it as a §4 violation.

### 2.3 `issue_type` is a reader tolerance

The field is **recognised and never written**. It appears in no authored document, no template and no format spine — `1da7480` retired it and nothing in the current tree carries it, which is exactly what makes its presence a reliable legacy marker.

This is the category `workflows-core:ard-resolution`'s `[AD-N]` tolerance already occupies: a reader that accepts an older document's form so a real artifact is not silently read as empty. `CLAUDE.md` sanctions it by name.

**The test is presence, not value.** The historical rule checked `issue_type: ValueIncrement`; presence alone discriminates a PRD from an ARD, since no ARD frontmatter ever carried the field, and it keeps the tracker-shaped *value* out of the tree entirely. A legacy-named file with no `issue_type:` is not a PRD this plugin authored, so it yields `absent` and the caller's existing absent branch runs.

---

## 3. What each consumer changes

Every one of the ten commands already loads `workflows-core:addressing` and calls `resolve-address`, so **no file gains a loader preamble**.

**`workflows-core` — the rule.**
- `addressing` §3 gains the entry point; §5 gains §5.1's table and its closed-set argument.

**`product-workflows` — the authority and five commands.**
- `coverage-ledger-format` §5.1: the legacy idea-route PRD folder no longer claims to hold `prd.md`. Fixed at the authority, so `epics.md`'s restatement is corrected by citing rather than by re-wording.
- `/prd-ground`: the Phase 0 step 5a route split, step 6i's `require-on-main` target and its row-F worktree test, step 8i's claim-list read, and three later prose sites — one of which restates the gate target as the literal path `<PRD-dir>/prd.md`, while the other two are statements about what the command does and may or may not need rewording.
- `/update-prd` step 4: resolve, then stop. `UPDATE_PRD_NO_PRD` and its remedy table survive intact and now fire only where there is genuinely no PRD. **This closes the loop.**
- `/epics` step 1b: the accept gate. On a legacy file there is no `kind:` to assert, so the accept condition is that `resolve-artifact prd` returns a file; the `EPIC-`-folder arm and the container refusals are untouched.
- `/create-prd` step 6: cite the entry point and drop the `kind: prd` claim, which cannot hold for the file the sentence is about.
- `/create-ard` and `/specify` Phase 0: replace the hand-rolled `ls-tree` + `<PRD>_*.md` fallback with `resolve-artifact prd <default-ref>`. **This removes the ARD collision.** The surrounding paragraph's argument survives and is worth keeping: gating an exact derived filename would report `absent` for a PRD that is present.

**`dev-workflows`** — `/ready` and `/implement`, at their folder reads.
**`docs-workflows`** — `/release-notes` (its content read and its `change_type` / `release_notes_category` capture) and `/document`.

**Plus the sweeps this repo requires of any capability landing:** the docs-page pass over the fourteen pages naming `prd.md`, touching only those stating a resolution rule; the `check-docs` check 9 count censuses; and the phrase sweep, run **by phrase and never by line number**, with the exclusivity probe as its own axis — *"the only copy there is"*, *"authoritative without a test"*, *"holds `prd.md`"*, *"the only copy"* name none of the vocabulary this change introduces and are invisible to a search for what it adds.

---

## 4. Non-goals

**No migration command.** §5's standing rule is unchanged and this design strengthens its reason: with the artifact half built, a legacy tree genuinely needs no rename.

**No new `check-docs` gate.** The relation would have to recognise "resolves an artifact by literal filename", which is prose. This repository has twice measured and refused a widening that fires only on correct content, and the honest statement is that this class is held by review.

**`specification.md` and `design.md` are untouched.** `1da7480` says they were already keyless — the convention it generalised — so they have no legacy name.

**`relevant_for_release_notes` is not retired here.** The field encodes a premise its owner rejects (every PRD is relevant), but nothing misbehaves, so it is a design change rather than a defect. Filed as **E-7**; nine sites across five files and two plugins plus `CLAUDE.md`, and `/create-prd` already defaults it to `yes`.

---

## 5. Risks

**A consumer inlines the rule instead of citing it, producing a fourth copy.** This is precisely how the tree reached three disagreeing copies, and nothing in `scripts/` catches it. Mitigated only by the entry point being loadable from every consumer with no new preamble — the friction that made inlining attractive is gone — and by §1 of this spec surviving in the ledger as the record of what inlining cost.

**The `issue_type` tolerance reads as a regression to a reader who does not meet §2.3.** Mitigated by stating the write prohibition in the table's own section rather than only here.

**Four plugins move at once.** The blast radius is real. It is also the point: a rule with one owner and ten consumers cannot be landed in one plugin, and landing it in one is how the current state arose.

---

## 6. Verification

The repo has no unit tests; the seven CI gates are the harness, and all seven must be green on the branch tip and again on the merged result.

Beyond the gates, each of the ten consumers is walked by hand against **both** tree shapes — a current folder and a pre-rename folder holding `idea.md`, `<KEY>_<slug>.md` with `issue_type:`, and `<KEY>_ARD.md` — and the walk records, per command, which branch each shape takes. Two specific results are the point of the increment and are asserted by name: `/update-prd` on a legacy folder reaches its Phase 2 read instead of `UPDATE_PRD_NO_PRD`, and `/prd-ground` on one reaches `route: idea` instead of `PRD_GROUND_NO_INVENTORY`.

**Version bumps:** `workflows-core` 1.3.3 → 1.4.0 (new entry point), `product-workflows` 3.3.0 → 3.4.0, `dev-workflows` 4.0.2 → 4.0.3, `docs-workflows` 1.1.1 → 1.1.2. These are fixes and one shared resolution, not a new user-facing capability, so every plugin `description` stays as it is.
