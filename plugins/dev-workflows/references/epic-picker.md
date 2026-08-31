# Progress-aware Epic picker — Shared Reference

How an **Epic-unit** command chooses which Epic to work on when it was given a PRD folder rather than
an Epic folder. Extracted from the retired tracker-input front-end, which owned it only because that
front-end happened to be where key classification lived; nothing about the pattern was ever
tracker-specific.

**Consumed by the Epic-unit commands** — `/specify`, `/design` and `/implement`. **PRD-level commands
never use it**: `/epics`, `/document` and `/release-notes` operate on the PRD as a whole and must keep
working for a PRD with no Epics at all.

## The picker

Given a resolved `PRD-` folder (`references/addressing.md` §3) and no Epic in the address:

1. **Enumerate the `EPIC-` folders directly under it.** A directory listing — the tree *is* the
   hierarchy, so there is nothing to read and nothing to import.
2. Branch on how many there are:

- **The address named an `EPIC-` folder** → no picker; proceed for that Epic.
- **Exactly one `EPIC-` folder** → no picker; auto-proceed for it, and emit a one-line notice saying
  which, so an auto-selection is never silent.
- **Two or more** → render the picker, one row per Epic: its marker, its `key` (read from the
  folder's frontmatter per §4, never parsed from the directory name) and its title.
- **None** → the command's own no-Epics policy — typically: split with `/dev-workflows:epics` first,
  or author one broad PRD-level artifact.

## The marker, and where it comes from

**Each command supplies its own done-predicate, and the predicate is always a file in the Epic
folder** — never a status somebody declared:

- **○ not started** — the command's output artifact is absent → selectable.
- **◐ in progress** — a resume file exists but the final artifact does not → selectable as a resume.
- **● done** — the artifact exists → shown greyed and not default-selectable; selecting it offers to
  revise.

Default cursor on the first actionable row, in-progress before not-started.

**Reading the artifact rather than a declared status is the point, not an accident of the rewrite.**
A status is a human's claim about the work and can lag it — which is why the version of this picker
that read one had to print the raw status text beside each row as a hedge. A file either exists or
does not.

**A command whose done-predicate artifact does not exist yet shows the markers it can support and
says which it cannot.** Claiming ● on a signal the tree cannot supply is worse than a shorter legend.

## What the picker does not do

**One Epic per invocation, with no "next Epic?" loop where the command's own work is heavy.**
`/implement` is explicit about this — code-writing is branchy, so each run targets one Epic. A
lighter command may offer a next-Epic loop; that is the command's call, not this file's.

**It never picks silently.** Auto-selection at one Epic emits a notice; a greyed ● row is selectable
only deliberately; and "author one broad PRD-level artifact instead" is always an explicit option
rather than something inferred from an empty selection.
