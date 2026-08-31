# Code-repository handoff — Shared Reference

What a command does with the code it just changed, in the repository it changed it in. The specs-repo
equivalent is `references/phase-handoff.md`; this file is deliberately short, because the mechanics
are that file's and are **cited, never restated**.

**Consumed by `/implement` and `/upgrade`.** `/vuln` does not use it — `vuln-fixer` already commits
and opens a pull request as part of its own contract, which is the behaviour this file generalises.

## 1. Why this exists

Three commands in this plugin change code in a repository under `$REPOS_PATH` or the cwd. Until
this file, one of them committed and opened a pull request and **two left the working tree dirty**,
with no reason stated anywhere — not in the commands, not in their agents, not in their
documentation pages. `agents/upgrade-executor.md` carried it as a bare invariant: *"Leave all
changes uncommitted — no git commits, no PRs."*

**Uncommitted is the worst of the three available states**, not the most cautious one. A stray
`git checkout`, a `git stash` somebody forgets, a container restart — and the work is gone. A commit
on a branch is recoverable by anyone; an uncommitted tree is recoverable by nobody.

It also broke a rule this plugin states elsewhere. `references/implementation-format.md` §3 needs the
key in the commit subject so `/document` and `/release-notes` can find the work later. A command that
does not commit cannot write that subject — it can only *ask* the operator to, which is strictly
weaker than doing it.

**Not opening a pull request is a defensible position on a host with no CLI. Not committing is not.**
Those are separate decisions and this file keeps them separate: the commit and the push always
happen behind consent; the pull request happens where a capability probe succeeds.

## 2. The handoff

Run this **after** the review gate and the test run have both passed, and **before** the emitter
tail. Never on a run that ended in an unresolved BLOCKER — the point is to hand over work that is
ready, not to persist work that is not.

**Present the consent choice verbatim**, the same shape `phase-handoff.md` §4.3 uses for the specs
repo, so an operator meets one convention rather than two:

```
choices: ["Commit + push + open a pull request (Recommended)", "Commit + push — I'll open the PR", "Commit only — don't push", "Leave it uncommitted — I'll handle git", "Cancel"]
```

**"Recommended" sits on the first option, and that is a real recommendation rather than a default.**
The work is reviewed, the tests pass, and the alternative is a tree only this machine can recover.

**On any of the first three**, execute `phase-handoff.md`'s mechanics against **the code repository**
rather than `$SPECS_PATH`:

- **§2.4's commit**, with this addition: the subject ends with `[<key>]` and carries a
  `Work-Item:` trailer where the folder has one (`references/implementation-format.md` §3). This is
  where the plugin **writes** that convention rather than merely teaching it.
- **§2.5's push** — `-u origin <branch>`, never forced, a non-fast-forward rejection reported rather
  than resolved.
- **§2.6's pull request** — the `gh` capability probe, falling back to §4.2's text on any failure.
  A host with no CLI gets a pushed branch and printed instructions, which is the outcome that was
  previously being called "leave it uncommitted".

**On "Leave it uncommitted"**, say what that costs in one line — the work is recoverable only on this
machine, and `/document` and `/release-notes` will not find it later — and continue. It is the
operator's call and it is not argued twice.

## 3. What this file does not change

- **The branch is still created before any file is touched**, by the command's own pre-implementation
  phase. This handoff never creates one.
- **`--no-commit`** on either command skips the choice entirely and restores the old behaviour, for
  anyone whose workflow depends on it.
- **Nothing here touches `$SPECS_PATH`.** The run's session artifacts are committed by the terminal
  `commit-artifacts` step exactly as before (`references/specs-repo-git.md` §4), and the two commits
  are separate — different repositories, different bounded paths, different reasons.
- **`/implement`'s `implementation.md` records what this handoff did**, including `pushed: false`
  when the operator declined the push. That record is written in the specs repo either way.
