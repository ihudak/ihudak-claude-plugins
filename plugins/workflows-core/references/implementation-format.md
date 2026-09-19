# Implementation record — Shared Reference

The shape of `implementation.md`, the file `/implement` appends to when it finishes work for a keyed
run, and the commit convention that makes work findable when the plugin was not the one that did it.
Design authority: `docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` §7.3 and §7.3.1.

**Written by `/implement`. Read by `/document` and `/release-notes`**, which hand the refs it records
to `diff-summarizer`; and, for whether it exists or for the repositories its entries name, by
`references/epic-picker.md`'s ● marker, `/ready`, `/specify` and `/epics`. §3's commit convention is
a separate thing with a wider writer set — all three of the commands that change code — and §3 says
how each of them writes it.

## 1. The block

One `## <YYYY-MM-DD> — /implement` block per run, one entry per repository the run touched:

```markdown
# Implementation — ACME-77-01 order intake

## 2026-08-31 — /implement
- repo:    orders-service
  branch:  feat/ACME-77-01-order-intake
  base:    main
  commit:  a3f91c2          # squashed
  pushed:  true
- repo:    billing-api
  branch:  feat/ACME-77-01-order-intake
  base:    main
  commit:  7be0d41
  pushed:  false            # local only — resolvable on this machine
```

**Append-only.** A block is never edited and never removed, and a re-run adds a block rather than
replacing one. This is the shape `grounding/baselines.md` already uses, one layer up.

**Where it lives: in the folder of the unit the run implemented.** `/implement` implements one unit
per run — an Epic, whether its address named the Epic's folder or the run chose the Epic under a
PRD address, or a broad PRD-level slice — and the record is that Epic's folder's, or the PRD
folder's for the slice. A file the run creates opens with `# Implementation — <key> <slug>`, the
key and slug of the folder it sits in. **A block names no unit**: nothing in the shape above says
which, so the folder is what attributes a block to one, and no reader infers a unit from a branch
name. That is what lets an Epic-level reader read its Epic's record alone, the picker mark an Epic
done from its own folder, and a PRD-level reader take the PRD folder's record and every Epic's
under it.

**A block an earlier run left in the PRD folder for an Epic is the PRD folder's.** Until
`dev-workflows` 4.1.2 `/implement` wrote into the folder its address resolved, so a PRD-addressed
run that chose an Epic — through its picker, or as the PRD's only Epic — appended its block to the
PRD folder's record. That block says nothing of the Epic, so it is read as every PRD-folder block
is: by a PRD-level reader, and by no Epic-level one. No run moves or copies it — the file is
append-only — and the picker's ● marker, which reads the Epic's own folder, does not count it.

**So that Epic reads as not implemented to everything Epic-level, until its own folder holds a
record.** `/implement`'s picker marks it ◐ where its `design.md` stands and ○ where it does not, a
◐ row taking the default cursor; `/ready` derives its phase from an Epic folder holding no record;
and an Epic-level `/document` or `/release-notes` reads none of its refs. And where the PRD folder
also holds a flat `specification.md`, a PRD-level `/ready` reads that block as the broad PRD-level
slice's record. **Population: every Epic implemented under a PRD address before `dev-workflows`
4.1.2.**

**The way out is the operator's: append a copy of that block, by hand, to the Epic folder's
`implementation.md`** — creating the file where the folder has none, under the heading a run would
write, `# Implementation — <key> <slug>` with the Epic folder's key and slug — and leave the PRD
folder's block as it stands. Append-only binds the commands that write this file, not the
operator, and the copy edits nothing in either record: the Epic's gains a block, and the PRD
folder's keeps its own, which a PRD-level reader still reads as the PRD folder's. A reader that
then reads both counts the ref once (§4).

**Branch for convenience, commit for durability.** A merged branch is deleted; the squashed commit
stays reachable from the base. `diff-summarizer` accepts either, and recording both is what makes the
file survive branch cleanup.

**`pushed:` is recorded, not assumed.** A later run reading `pushed: false` says *"this was never
pushed"* rather than reporting an empty diff against a ref the remote does not have.

## 2. What it does not hold

**No summary of what was implemented.** A summary is a *description*, and `references/source-truth.md`
exists because descriptions drift from the code they describe — one here would be a new, unverified
description sitting in a folder of grounded artifacts, with nothing to check it against.

A ref cannot drift. Git resolves it or it does not, and either answer is true.

**Two limits, and the second is narrower than it used to be:**

- **`/implement` in direct mode writes nothing** — no address, no folder, nothing to append to. A
  directly-implemented change has no block, exactly as before.
- **This file records only what the plugin did.** Work done by hand or by another tool leaves no
  block — which is why it is not the only source. §3's convention and the scan that reads it recover
  that work, and §4 says how the two are combined.

## 3. The commit convention — and who actually writes it

**The key goes where a human will see it and copy it.** Who writes it is narrower than it first
appears, and the difference matters:

| Command | What it does with the code | What it does about the convention |
|---|---|---|
| `/implement` | branches, then commits and pushes through `dev-workflows:code-handoff`'s `finish-code-branch` (Phase 4.6) | **writes the subject itself** |
| `/upgrade` | branches, commits each component in step 6.5, pushes once in step 7.5 | **writes the subject itself** |
| `/vuln` | `vuln-fixer` branches and applies the fix; the orchestrator commits and pushes in Step 3.9, using its own template | **writes the subject itself**, from the template in `/vuln`'s Git Workflow |

**All three write it, and the history is worth keeping** because it explains why the convention is
also *documented* rather than merely emitted. Until `code-handoff.md` existed, `/implement` and
`/upgrade` left the working tree dirty and could only ask the operator to name the key — strictly
weaker than doing it, and a command that does not commit cannot write a commit subject. That is no
longer any command's situation: the commit is prompt-free (`code-handoff.md` §1 rule 5), so the only
runs that end uncommitted are the ones that typed `--no-commit`. The convention still needs to be
written down, because the people whose commits the §4 scan has to find are mostly not running the
plugin at all — which is what `docs/reference/commit-convention.md` is for.

- **The commit subject ends with `[<key>]`** — `feat(orders): add order intake [ACME-77-01]`.
  **The key is the unit's** — the Epic's wherever the run implemented an Epic, even one
  `/implement` chose under a PRD address, and otherwise the folder the address resolved: the folder
  §1 puts `/implement`'s block in, so a commit is found by the same key as the record beside it.
- **A `Work-Item: <workitem_key>` trailer**, when that unit's folder carries one
  (`references/prd-format.md`). Never invented; the trailer is simply absent when the field is.
- **The branch carries the key too** — `<prefix>/<key>-<slug>`, per `references/branch-naming.md`,
  the same unit's key, which gives a second recovery path.

**In the subject rather than a trailer, and that is the whole point.** A trailer does not survive
`git log --oneline`, so it is invisible to the person deciding what their own commit should look
like — and people copy the shape of the commits already in the log. A convention stated only in a
trailer is a convention nobody sees.

**The convention is documented as a convention**, in `docs/`, not merely implied by what the plugin
emits: a contributor who has never run `/implement` still has to be able to write a commit the scan
can find.

## 4. Reading it — the two sources, and their boundaries

A consumer combines **this file's blocks** with a **scan of commit messages** for the identifiers
the run already holds:

```
git -C <repo> log --grep='<key>' --grep='<workitem_key>' --extended-regexp --regexp-ignore-case
```

over the repositories this file names — or, when it names none, the repositories resolved from
`$REPOS_PATH` — with one `--grep` for each key and each `workitem_key` below; git lists a commit
matching any of them.

**The keys are those of the records the read takes, so its scope decides them.** An Epic-level read
greps that Epic's key and its `workitem_key`. A PRD-level read, which takes the PRD folder's record
and every Epic's under it (§1), greps the PRD folder's key and every `EPIC-` folder's, each with its
`workitem_key` — so a commit whose subject carries an Epic's key (§3) is found at both levels, as
that Epic's record is.

**This is a search for tokens the run already holds, never an extraction.** Each key is read off
its folder's carrier (`references/addressing.md` §4) — an Epic's off the `EPIC-` folder the run
listed under the PRD folder — and each `workitem_key` off the same folder. Nothing parses an
identifier out of a commit message, which is the rule `CLAUDE.md` states and the difference between
resolving and guessing.

**Merged and deduped by SHA.** A ref two records name — the same repository and the same commit, as
after an operator copies a block into its Epic's record (§1) — is one ref, counted once by a read
that takes both. What the scan finds beyond the recorded blocks is reported as **unrecorded work**,
named as such with its commits listed — a run that quietly folds hand-made commits into the recorded
set makes the record look more complete than it is.

**The two consumers take different boundaries, and the difference is not stylistic:**

- **`/document` reads every block under its scope** — the PRD's, which is the PRD folder's record
  and every Epic's under it, or, on an Epic address, that Epic's (§1). It documents the feature as
  it now stands, so every change that reached it is in scope.
- **`/release-notes` reads only the blocks no earlier note covers.** A second release must not
  re-describe the first one's work, and with no imported release field the notes already in
  `release-notes.md` are the only honest boundary. Each records its scope and date
  (`docs-workflows:release-note-types` §1): a note for the PRD covers every record under it, and a
  note for an Epic that Epic's record alone. So for each record the run reads — by the same scope
  as `/document` — it takes the blocks dated after the latest note covering that record, which for
  an Epic's record is the later of that Epic's latest note and the PRD's; a note drafted for one
  Epic moves no other Epic's boundary. A block dated the day of that note is read too, since a date
  cannot order the two, and a block read twice shows in the report where a block skipped would not.
  **The run names the blocks it used**, which makes a wrong boundary visible rather than silent.

**What is honestly still lost, and what a run therefore says out loud:** only a commit whose message
names the key is findable, no convention compels a human to follow one, and so **the run reports how
many commits it scanned and how many matched**. A zero-match scan in a repository that has commits is
a signal about the convention, not proof that no work happened.
