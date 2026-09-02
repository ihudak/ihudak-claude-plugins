# Implementation record — Shared Reference

The shape of `implementation.md`, the file `/implement` appends to when it finishes work for a keyed
run, and the commit convention that makes work findable when the plugin was not the one that did it.
Design authority: `docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md` §7.3 and §7.3.1.

**Written by `/implement`. Read by `/document` and `/release-notes`**, which hand the refs it records
to `diff-summarizer`. §3's commit convention is a separate thing with a wider writer set — all three
of the commands that change code — and §3 says how each of them writes it.

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
| `/implement` | branches, then commits and pushes through `references/code-handoff.md`'s `finish-code-branch` (Phase 4.6) | **writes the subject itself** |
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
- **A `Work-Item: <workitem_key>` trailer**, when the resolved folder carries one
  (`references/prd-format.md`). Never invented; the trailer is simply absent when the field is.
- **The branch carries the key too** — `<prefix>/<key>-<slug>`, per `references/branch-naming.md`,
  which gives a second recovery path.

**In the subject rather than a trailer, and that is the whole point.** A trailer does not survive
`git log --oneline`, so it is invisible to the person deciding what their own commit should look
like — and people copy the shape of the commits already in the log. A convention stated only in a
trailer is a convention nobody sees.

**The convention is documented as a convention**, in `docs/`, not merely implied by what the plugin
emits: a contributor who has never run `/implement` still has to be able to write a commit the scan
can find.

## 4. Reading it — the two sources, and their boundaries

A consumer combines **this file's blocks** with a **scan of commit messages** for the run's own
identifiers:

```
git -C <repo> log --grep='<key>' --grep='<workitem_key>' --extended-regexp --regexp-ignore-case
```

over the repositories this file names — or, when it names none, the repositories resolved from
`$REPOS_PATH`.

**This is a search for tokens the run already holds, never an extraction.** The keys come from the
resolved folder's own `key:` (`references/addressing.md` §4) and its `workitem_key`. Nothing parses
an identifier out of a commit message, which is the rule `CLAUDE.md` states and the difference
between resolving and guessing.

**Merged and deduped by SHA.** What the scan finds beyond the recorded blocks is reported as
**unrecorded work**, named as such with its commits listed — a run that quietly folds hand-made
commits into the recorded set makes the record look more complete than it is.

**The two consumers take different boundaries, and the difference is not stylistic:**

- **`/document` reads every block under the PRD.** It documents the feature as it now stands, so
  every change that reached it is in scope.
- **`/release-notes` reads only blocks appended since its last section was written.** A second
  release must not re-describe the first one's work, and with no imported release field the file's
  own last-written date is the only honest boundary — so **the run names the blocks it used**, which
  makes a wrong boundary visible rather than silent.

**What is honestly still lost, and what a run therefore says out loud:** only a commit whose message
names the key is findable, no convention compels a human to follow one, and so **the run reports how
many commits it scanned and how many matched**. A zero-match scan in a repository that has commits is
a signal about the convention, not proof that no work happened.
