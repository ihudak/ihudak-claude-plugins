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
  folder's frontmatter per §4, never parsed from the directory name) and its title — **capped at four
  options, see *The cap* below**.
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

## The cap

`AskUserQuestion` renders at most four options (`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`
§0), and this picker is built from a directory listing — so a PRD with five Epics overflows it, and a
`/specify` run that appends its own option overflows at four. A picker that is one row per Epic is a
picker that stops working on a perfectly ordinary PRD, which is why this is part of the picker rather
than advice beside it.

**Print every Epic as prose above the prompt** — marker, key and title, one line each, in the
ordering above — and let the array carry **at most three Epic rows plus one option naming the
remainder**:

    Epics under PRD-ACME-77 orders:
      ◐ EPIC-ACME-77-02  order intake       (in progress)
      ○ EPIC-ACME-77-03  billing hand-off
      ○ EPIC-ACME-77-05  refund path
      ● EPIC-ACME-77-01  catalogue sync     (done — selecting it offers to revise)

    choices: ["◐ EPIC-ACME-77-02 order intake (Recommended)", "○ EPIC-ACME-77-03 billing hand-off", "○ EPIC-ACME-77-05 refund path", "Another Epic from the list above — name its key"]

The last option is answered through the harness's free-text option, and the run resolves the typed
key **against the keys it just listed** — never by parsing one out of the answer
(`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1). Four or fewer Epics need none of this: the
array carries them all, and the prose list is still printed because a greyed ● row reads better
there.

**A command that adds its own option to this picker counts it against the four.** `/specify` appends
*"Author one broad PRD-level spec instead"*, so its array carries at most **two** Epic rows plus that
option plus the remainder option. The added option is never the one dropped: it is the alternative to
picking any Epic at all, and a picker that hides it forces a choice the command means to leave open.

**Reading the artifact rather than a declared status is the point, not an accident of the rewrite.**
A status is a human's claim about the work and can lag it — which is why the version of this picker
that read one had to print the raw status text beside each row as a hedge. A file either exists or
does not.

**A command whose done-predicate artifact does not exist yet shows the markers it can support and
says which it cannot.** Claiming ● on a signal the tree cannot supply is worse than a shorter legend.
Every consumer can support all three today — `/specify` on `specification.md`, `/design` on
`design.md`, `/implement` on `implementation.md` — so this is a rule for the next command that adopts
the picker, not a live caveat.

## What the picker does not do

**One Epic per invocation, with no "next Epic?" loop where the command's own work is heavy.**
`/implement` is explicit about this — code-writing is branchy, so each run targets one Epic. A
lighter command may offer a next-Epic loop; that is the command's call, not this file's.

**It never picks silently.** Auto-selection at one Epic emits a notice; a greyed ● row is selectable
only deliberately; and "author one broad PRD-level artifact instead" is always an explicit option
rather than something inferred from an empty selection.
