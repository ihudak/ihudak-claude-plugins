# Grounding format (embedded authority)

The canonical finding contract for the BRD→PRD workflow's grounding engine: what grounding is and
is not, the finding record every `[CG#n]`/`[DG#n]` carries, the six verdicts, the
`baseline-integrity` procedure that gates every run, the two horizons a finding can carry, the four
design-grounding reconciliation classes, the optional derivation matrix, and the four verification
outcomes. Design authority: `docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` §5
(all subsections) and decision rows D6, D7, D19 in §3. Requirement identifiers are defined once
each and cited here, not restated: `[BR#n]` in `product-workflows:brd-format` for the BRD route,
`[AC#n]`/`[FR#n]`/`[US#n]` in `references/prd-format.md` for the idea route. The read-only posture for a
mounted repository is defined once in `references/read-only-repos.md` and applies unchanged to
every repository grounding reads.

**Consumed by** the three grounding agents that write against the contract fixed here —
`product-workflows:code-grounder`, `product-workflows:design-grounder`, and `product-workflows:grounding-verifier` — and by
the two commands that read what they produce: `/product-workflows:prd-ground`, which orchestrates all
three, and `/product-workflows:brd-split`, whose Phase 0 gate turns on §8's verification outcomes.

## 1. What grounding is, and is not

Grounding answers one question: **is this specific claim true of this specific commit?** A
`[CG#n]`/`[DG#n]` finding is always an answer to a premise stated by one requirement row — a BRD's
`[BR#n]` on the BRD route, or a PRD's `[AC#n]`, `[FR#n]` or `[US#n]` on the idea route — checked
against a pinned revision of a real repository. For design grounding the premise is one such
requirement reconciled against one exported frame.

This is a narrower question than `code-scanner` answers. `code-scanner` answers **what capability
exists for this theme?** — a broad-then-narrow sweep across a repository, useful for scoping an
Epic or a specification before anything has been claimed as true. Grounding does not scope; it
adjudicates. Both ship, and they are not alternatives: a BRD route may use `code-scanner`'s output
to decide *what to check*, but nothing `code-scanner` returns is itself a finding, and nothing a
finding says is a capability inventory.

The failure this document exists to prevent is an agent **inferring a plausible mechanism and
citing something adjacent to it** — producing a confident finding that is false because the cited
line supports a *related* claim rather than the claim under test. Every section below exists to
make that failure either impossible or visible.

## 2. The finding record

Every finding — `[CG#n]` from `code-grounder`, `[DG#n]` from `design-grounder` — carries:

| Field | Meaning |
|---|---|
| `id` | `[CG#1]`, `[DG#1]`, … — contiguous within its own prefix, assigned once, never renumbered |
| `claim` | the requirement premise under test — a `[BR#n]` on the BRD route, an `[AC#n]`/`[FR#n]`/`[US#n]` on the idea route — quoted or closely paraphrased |
| `verdict` | exactly one of the six values in §3 |
| `evidence` | a `file:line` list, or — when the verdict is `NOT-PROVABLE` or the finding asserts an absence — an explicit statement of why no evidence exists rather than an empty field |
| `control` | *(required wherever the finding asserts an absence — the same trigger `evidence`'s absence clause uses; omitted otherwise)* the **positive control** on the search that reached that absence: the same method, run against a case of the same kind known to be present in this same source, and what it returned (§2.2) |
| `commit` | the pinned commit SHA the finding was checked against (`baseline-integrity`, §4); **absent on a `[DG#n]` of class 1, 2 or 3**, which is settled from the frame set and the requirement text alone (§6) and is pinned to no commit. A class-4 `[DG#n]` carries the cited `[CG#n]`'s own |
| `altitude` | one of `product \| architecture \| implementation` |
| `horizon` | one of `current \| will-change` (§5), naming the prerequisite decision when `will-change` |
| `class` | *(design-grounding only)* one of the four `[DG#n]` reconciliation classes defined in §6; absent on a `[CG#n]` |
| `cites` | *(design-grounding only)* a `[CG#n]` id; required when `class` is the fourth (§6), **omitted** on a `[DG#n]` of class 1, 2 or 3 (§2.1 — never written empty), absent on a `[CG#n]` |
| `prerequisite` | the prerequisite decision this finding's horizon turns on; **required when `horizon` is `will-change`, omitted otherwise** (§5). Both grounder agents emit it, so it is a field of the record rather than a phrase inside `horizon`'s |
| `consumed_by` | one of `PRD \| ARD \| specification \| none` — which downstream artifact has actually drawn on this finding; `none` until something has |

`class` and `cites` apply only to `[DG#n]` findings — a `[CG#n]` finding carries neither. See §6 for
what the four classes mean and why the fourth requires a citation; this table fixes only the field
names, where they apply, and when `cites` is required.

**`commit`'s applicability is not universal — nor is `class`'s, `cites`'s, `prerequisite`'s or
`control`'s — and saying so is load-bearing.**
§8's verification is fail-closed on exactly this: `product-workflows:grounding-verifier`'s Inputs table puts
a `[DG#n]` in the design-only row **only** where its `class` positively reads 1, 2 or 3, and demands
`repo_path` and `commit` everywhere else. A design-only finding that carried a `commit` anyway would
be honoured — that agent uses a commit it is given rather than ignoring it — and would then be
re-derived against a repository it was never checked against. A field listed without its
applicability is a field an emitter fills to satisfy the table.

**`evidence` is never blank.** A finding that asserts a mechanism is absent still owes the reader
what was searched and where it was expected — "no route under `api/` handles this verb; searched
`api/**/*.py` at the pinned commit" is evidence; a bare empty field is not. **That is what was
searched; `control` (§2.2) is whether the search could have found it**, and an absence claim owes
both — the first without the second is the reason this field set gained a row.

**`consumed_by` starts at `none` and is written later**, by whichever downstream authoring command
actually cites the finding — this file fixes only that the field exists and what its values mean,
not when a caller updates it.

### 2.1 How a finding is serialised, and why exactly one spelling is canonical

The table above fixes the field **names**. This section fixes the **bytes**, because a writer free to
choose between two renderings produces an artifact whose readers are wrong in a way that looks like
data.

That is not hypothetical. A live run wrote `- id:       [CG#1]` in one section of a
`code-grounding.md` and `- id: [CG#12]` in the next — column-aligned where a block's other keys
happened to be long, unpadded where they were not. Both are valid YAML, both read identically to a
person, and a `^  - id: \[CG#` scan matched only the second. It reported **140 findings as missing
that were on the page**: a false absence, which is the one class of wrong answer a grounding
artifact must never produce, because everything downstream treats an absent finding as a gap to be
filled rather than a record to be read.

So, canonically:

- **One space after every key's colon — never padding, never alignment**, whatever the longest key
  in that block happens to be. Alignment is a rendering choice made per block, which makes the
  bytes of a record a property of its neighbours.
- **One block per finding**, keys in the §2 table's order, every key of a block at the same
  indentation, and no blank line inside a block. `outcome` (§8) and any verifier `notes` follow the
  §2 fields, in that order, where the run that wrote the block had them.
- **The field set is closed: §2's fields, `outcome` and `notes`, and nothing else.** A verifier
  returns more than the record keeps — `own_verdict`, `own_evidence` and its own re-derivation
  `commit` are how it reports to the caller, which **acts** on them (§8) rather than transcribing
  them. **`own_verdict` in particular is never a record field**, and writing it is not a harmless
  extra: `verdict` is what every downstream consumer reads, so a block carrying both states two
  verdicts at once and a reader can quote whichever half suits. Where a re-derivation moved the
  verdict, §8's `contradict` handling has already replaced `verdict` and left a one-line note of what
  it was — so a correct record carries exactly one verdict plus its history, never a live
  disagreement. This is the same failure §2.1 exists to prevent, met at the field set rather than at
  the bytes: a writer free to add a field produces an artifact whose readers disagree about which
  value is the finding's.
- **A field that does not apply is omitted, never written empty** — `class` and `cites` on a
  `[CG#n]`, `cites` on a `[DG#n]` of class 1, 2 or 3, `commit` on a `[DG#n]` of class 1, 2 or 3,
  `prerequisite` on any finding whose `horizon` is `current`, and `control` on a finding that
  asserts no absence. An empty value asserts that the field
  applies and its value is unknown, which is a different claim from the field not applying. §2's
  `cites` row said "empty otherwise" until this section was written; the two rules met head-on for
  forty-five lines, and §2 was the one corrected.

```
- id: [CG#12]
  claim: [BR#7] — the nightly export runs at 02:00 UTC
  verdict: CONFIRMED
  evidence:
    - scheduler/jobs.py:88
    - scheduler/config/nightly.yaml:12
  commit: 4f1c9ab
  altitude: implementation
  horizon: current
  consumed_by: none
  outcome: agree
```

**A relation over these records fails when either side comes up empty.** A reader that resolves
findings against something else — an inventory, a directory listing, a section of another file — and
finds nothing on one side has learned that its read failed, not that the tree is clean. Report it as
a failure. This is the same rule `check-docs.sh` states for its own build-time checks, and it is
stated here because the runtime gates over these artifacts need it and had nowhere to cite: a gate
that counts findings is satisfied by zero findings, which is how a BRD with no design grounding at
all once passed `/brd-split`.

**The reading rule does not go away once the writer is fixed.** Findings already on file were
written before this section existed, and a hand-edited artifact is sanctioned everywhere else on
this route — so a reader still resolves an id **against the finding set it has parsed**, never by
matching a fixed column or a fixed run of leading spaces. That is this repo's "resolve against a
known set, never parse one out of free text" rule met at the one place the free text is an artifact
this family wrote itself. A count that disagrees with the file is reported as a parse failure, never
as an absence: a scan that cannot read a block has learned nothing about whether the finding exists.

### 2.2 `control` — the positive control on an absence

**An absence claim rests on a search returning nothing, and a search returns nothing for two
different reasons.** Either the thing is not there, or the method could never have found it. Those
two are indistinguishable from the result, and only one of them is a finding. `control` is the field
that separates them, and it is a field rather than an instruction because the difference has already
been explained in prose and reproduced anyway: a run explicitly warned about this failure filed an
empty `grep` as evidence of absence in the same pass.

The canonical case is a Rails repository and the claim *"the record stores who approved it"*.
`grep 'associate_id'` returns nothing, and attribution **is** written — through the association,
which never spells the column name anywhere the grep could see. The empty result was true; the
inference from it was false.

**What `control` holds.** The same method, pointed at a case of the same kind that is known to be
present in this same source, and what it returned:

- **Same method.** The grep that reached the absence, not a different or easier one.
- **Same kind.** A case of the shape the claim is about — another attributed field, another
  scheduled job, another frame carrying the class of element that is missing. A control that
  succeeds on an unrelated shape proves only that the tool runs.
- **Known present.** Established independently of this search — from a finding already settled in
  this run, or from a file the agent has read and can cite. Not assumed.
- **Its result.** The `file:line` the control matched. A control that matched nothing is a **failed
  control**, and it does not become evidence by being reported.

**A failed control forecloses the absence, not the finding.** Where the control does not fire, the
search has established nothing about the source and the verdict may not rest on the absence: the
finding is `NOT-PROVABLE`, its `evidence` says what was searched, and its `control` records the
control that failed. That is a true and useful record — it says this method cannot see this class of
thing here — where a `REWRITTEN` on the same search would be a fabrication with a citation.

**Where it applies is the claim, not the verdict.** Any finding asserting that something is not
there carries it, whichever of §3's six verdicts it lands on — this is the same trigger `evidence`'s
absence clause already uses, deliberately, so a writer resolves one question rather than two. A
`FALSE-FRIEND` carries one whenever the half being asserted is that the plausible name does *not* do
the thing. A `[DG#n]` of class 2 — a requirement asks for a field no frame shows — is an absence over
a frame set and carries a control drawn from the frame set: another field of that kind, found in
these frames by the same reading. A class-4 `[DG#n]` carries none of its own, because its code half
is not its own search: it cites a `[CG#n]`, and the control belongs to the finding that did the
searching (§6.3).

**The verifier checks the control, and checks it the way it checks everything else — by
re-deriving.** `product-workflows:grounding-verifier` does not confirm that the control's cited line
exists; it runs the control itself. A control that does not reproduce falsifies the absence, and the
outcome is `contradict` on that ground alone, whatever the verifier's own search turned up.

```
- id: [CG#31]
  claim: [BR#12] — an approval records which associate approved it
  verdict: NOT-PROVABLE
  evidence:
    - no column, association or writer under app/models matches approver attribution
    - searched `git grep -n 'approv' <commit> -- app/models app/services`
  control: same grep shape for `submitted` attribution, which BR#9 settled as written — app/models/request.rb:41
  commit: 4f1c9ab
  altitude: implementation
  horizon: current
  consumed_by: none
  outcome: agree
```

## 3. Verdicts

Exactly six:

| Verdict | Meaning |
|---|---|
| `CONFIRMED` | The premise holds, with evidence |
| `AMENDED` | Partly true; the finding states the correction |
| `REWRITTEN` | The premise is materially wrong; the finding replaces it |
| `FALSE-FRIEND` | A name, field or constant appears to support the premise and does not |
| `NOT-PROVABLE` | Cannot be established from the repository — a valid, final answer |
| `SUPERSEDED` | Replaced by a later finding; the ID is retained |

### `NOT-PROVABLE` is a destination, not a defeat

Write this plainly, because it is the single most valuable line in this document: **where a claim
cannot be proved from the repository, the finding says so rather than inferring.** `NOT-PROVABLE`
is not what an agent reaches for after failing to find evidence — it is the correct verdict for a
premise the repository genuinely cannot settle, and landing there on a well-searched claim is the
system working as designed, not a shortfall to apologize for or paper over.

The failure it prevents is the one named in §1: an agent under pressure to produce findings, unable
to confirm a premise outright, reaches instead for the nearest plausible-looking line and files a
`CONFIRMED` or `AMENDED` against it. That finding is worse than no finding at all, because it reads
as settled and nobody re-checks a settled question. `NOT-PROVABLE` closes that path: it is a
complete, legitimate, terminal answer, and a package carrying several `NOT-PROVABLE` findings is
not a weaker package than one with none — it is a package that told the truth about the limits of
what the repository can say. A `NOT-PROVABLE` finding still carries `evidence` (§2): what was
searched, and why it fell short of settling the claim.

### Why `FALSE-FRIEND` earns its own verdict

An absent mechanism is easy to be honest about — nothing is there, so the finding says
`NOT-PROVABLE` or `REWRITTEN` and a careful reader keeps looking if they need to. A
**plausibly-named** constant, column, or field is more dangerous than an absent one, because it
gives the reader a place to stop. A configuration key called `AUTO_APPROVE_THRESHOLD` reads as
though it supports a BRD premise about automatic approval; if it is in fact unused, or gates an
unrelated batch job, or is read by code that was deleted, a reader who finds it stops looking and
treats the premise as supported. `FALSE-FRIEND` exists precisely to catch that reader before they
stop: it says, in one verdict, "this name looks like your answer, and it is not" — something a
`REWRITTEN` or a `NOT-PROVABLE` finding, both silent about the decoy, would not surface on their
own.

## 4. Baseline integrity

Before any finding is written, every repository grounding reads is pinned and proven clean **in
content, not merely in `git status`**.

### Entry point: `baseline-integrity`

Run once per repository, before the first finding against it:

```bash
git -C "<repo>" rev-parse HEAD                      # record in baselines.md
git -C "<repo>" diff --ignore-cr-at-eol --stat      # must be empty
git -C "<repo>" status --porcelain                  # any entry -> line-count comparison
```

1. **`rev-parse HEAD`** pins the commit every `file:line` in the package will cite. Record it in
   `baselines.md`.
2. **`diff --ignore-cr-at-eol --stat`** must produce no output. `--ignore-cr-at-eol` is not
   optional: without it, a checkout can report hundreds of modified files that differ only in line
   endings, and a gate that fires on every line-ending checkout trains its own operators to ignore
   it.
3. **`status --porcelain`** — any entry it reports still needs a line-count comparison against the
   pinned commit before the repository is trusted, even when step 2 came back empty. `--porcelain`
   surfaces untracked and renamed paths that a `--stat` diff against `HEAD` would not.

**The failure this prevents:** without this check, every `file:line` this package produces is a
citation into an unidentifiable snapshot — a reviewer, or the customer's own reviewer, cannot tell
whether the line a finding names is the line that exists on disk today. Baseline integrity is what
makes a citation checkable at all.

The outcome is recorded as **a `[CG#n]` finding**, the same prefix as any other code-grounding
output — a verified fact about a code repository at a commit is exactly what `[CG#n]` denotes, and
baseline integrity is not exempted from the record it protects by inventing a prefix of its own.
The same three commands are handed to the customer's reviewer in the delivery prompt, so the
customer can re-run them against their own checkout rather than take the package's word for the
pin.

### 4.1 A baseline finding differs from a claim finding in three ways, and each has a consequence

Sharing the `[CG#n]` prefix is deliberate (above), but a baseline finding is an answer about a
**repository**, not about a requirement row. Three rules follow, so that a consumer written against §2's
record does not treat it as one:

1. **Its `claim` is not a requirement premise** — not a `[BR#n]`, and not an `[AC#n]`/`[FR#n]`/`[US#n]`
   either. It reads "baseline integrity: `<repo>` is pinned at a
   verified, unmodified commit". Anything that resolves a finding back to the requirement it answers
   finds none, and that is correct rather than a missing link.
2. **Its `evidence` carries command output, not `file:line`.** The three commands' results *are* the
   evidence, and §2's never-blank rule is satisfied by them. A consumer expecting a path list gets
   none.
3. **It is never `consumed_by` anything, and `none` on it does not mean "unconsumed".** There is
   nothing for a PRD, an ARD or a specification to draw *from* it — it asserts that a commit is
   identifiable, which is a precondition of every other finding rather than content of its own. So
   **a report that lists what is still `consumed_by: none` excludes baseline findings**, and says it
   excludes them. Counting them would put one permanently-open item per repository into every such
   report, on every run, with no action that could ever close one — a gap that cannot be closed
   trains its reader to skim the list that also carries the real ones.

**Verification is unchanged and is not an exception.** `grounding-verifier` re-derives a baseline
finding by re-running `baseline-integrity` against the commit it was handed, which its own Process
step 1 already does for every finding that rests on code — so the re-derivation *is* that re-run,
and the outcome it returns is a real outcome, not a courtesy. Its `own_evidence` for such a finding
carries the same command output the finding does, in place of the `path`/`lines` shape a claim
finding uses. A baseline finding with no outcome blocks `/brd-split` exactly like any other (§8);
none of this section excuses it from the gate.

## 5. Horizon

Every finding carries one of two horizons:

| `horizon` | Meaning |
|---|---|
| `current` | True of the pinned commit, and no declared prerequisite's decisions change it |
| `will-change` | True of the pinned commit, but a prerequisite decision makes it false once built |

**A `will-change` finding names the prerequisite decision that overturns it.** Naming the
prerequisite BRD alone is not enough — a prerequisite can carry many decisions, and only one of
them is the one that overturns this particular finding; the finding names that specific decision.

Grounding reads only a prerequisite's **frozen** decisions, never speculation, a draft position, or
an interview answer still open for revision. **"Frozen" is a field, not a judgement: it means
`status: decided`**, the second of the five statuses `product-workflows:decision-register-format` §3
fixes, and nothing else qualifies — `open` and `reopened` may not be consumed downstream at all,
`superseded` and `withdrawn` describe a position no longer held, and an `[AS#n]` never reaches
`decided` (§7 there). A reader that weighed how settled a record *sounds* instead of reading its
status would be inferring the one thing the register records outright. **A prerequisite whose
decisions are not yet frozen
contributes no `will-change` horizons at all** — there is nothing stable enough to name, so every
finding that touches it stays `current`, and that absence is itself reported rather than silently
assumed. A `will-change` finding is not deleted once its prerequisite ships and the code catches up
— it stays as a true record of what the pinned commit showed; what changes is that a *later*
finding, at a *later* commit, supersedes it (§3, `SUPERSEDED`).

The motivating shape: a finding says a mechanism does not exist, and a prerequisite BRD has already
decided to build exactly that mechanism. The finding is not wrong — it is true of the code under
review — but a decision built on it is standing on ground that is about to move. `horizon` exists so
that shape is visible to whoever writes the decision, not discovered later when the prerequisite
ships and the assumption quietly stops holding.

## 6. Design grounding

### 6.1 Where frame sets live

**`design/` is a reserved subdirectory of any folder under `specifications/`** — a BRD folder, a PRD
folder, or an Epic folder alike. Each of its immediate subdirectories is **one exported frame set**:
screen or report images plus **an index file** naming what each frame depicts.

```
<any-specs-folder>/design/<frame-set-name>/   <images…> + an index file
```

**The index is not optional, and its absence is recoverable in exactly one way.** `design-grounder`
returns `NO_INDEX` rather than reading the directory, because a filename is not a reliable statement of what
a frame shows, and a finding citing a frame the agent cannot actually identify is worse than no
finding. The index may be named by whatever the frame-set convention uses — a manifest, a captions
file, a README enumerating the frames — but something must map frame to subject.

**The way out is `/workflows-core:frames <ADDRESS>`**, which looks at the frames of every set in one
resolved folder and writes the index this section requires. Any command or agent that reports
`NO_INDEX` to a human names it: a refusal whose remedy is not stated reads as a dead end, and the
hand-export it fires on is the ordinary way a frame set arrives.

**The location is stated here once and cited, never restated.** A command that re-derived it would
be a second copy of a path rule, which is how the copies drift.

**Defining the location is not the same as consuming it.** `design-grounder` is dispatched by
`/prd-ground` and by nothing else — `/frames` indexes a set on any route; it never reconciles one.
`/prd-ground` now reads a `design/` folder as a frame set on both routes: the BRD route's `[BR#n]`
inventory, and — in this same increment — the idea route's PRD-level `[AC#n]`/`[FR#n]`/`[US#n]`
inventory. A PRD folder on the `/idea` route holds one whenever that idea's source linked an image the
reader could open. Grounding it is optional on that route — nothing gates on it — so a set
`/prd-ground` has not yet been run against is not a gap in this section: it is a run nobody has asked
for yet, which `/prd-ground` settles the moment an operator invokes it.

**Two commands WRITE a frame set's index, and §6.2 is the one format both write.** `/idea` Phase 4.5
copies the images it actually read into `<PRD-folder>/design/idea-sources/` and indexes that set;
`/frames` (re)builds the index of **every** `design/*/` set of one resolved folder, whatever kind of
folder that is. **Writing images into a set without its index was never an option**: the paragraph
above makes the index's absence unrecoverable, so images dropped into a frame set with no index would
be a directory `design-grounder` refuses on sight. That is also the state a human produces by
exporting frames and dropping the folder in, and it is exactly what `/frames` exists to repair — the
requirement above is strict *and*, until that command, had no recovery but hand-authoring an index.

**Writing an index is not consuming one, on either route.** Neither writer dispatches
`design-grounder`, produces a `[DG#n]`, consults an index, or reaches a verifier — `/idea` Phase 4.5
stops at the index exactly as `/frames` does. The index makes the frame set *readable* — it does not
make anything read it. **`/frames` is not that capability and must not be read as it having
arrived**: it describes frames so that a set *can* be read, and reconciles nothing against any
requirement. Indexing makes frames readable; grounding makes them `[DG#n]` findings, and only
`/prd-ground` does the second — on both routes now, since it takes its inventory from a BRD's
`[BR#n]` rows or, on the idea route, a PRD's `[AC#n]`/`[FR#n]`/`[US#n]` rows. This paragraph exists to
foreclose the mistake of reading `idea-reader`'s image support, `frame-describer`'s descriptions, or
either writer's index as itself being that reconciliation: a frame set becomes evidence only once
`/prd-ground` grounds it, never at the moment it is written or indexed.

**Reading a picture is not design grounding, and both writers do the first without doing the second.**
`idea-reader` reads the images an idea source links; `frame-describer` reads the frames of a set being
indexed. Each returns a description of what it saw — as **context**, never as evidence. Neither
produces a `[DG#n]` or reaches a verifier, so none of this section's *finding* requirements applies to
them: the index rule above exists because a *filename* is not a reliable statement of what a frame
depicts, which is the right standard for a finding someone will act on and the wrong one for a
description whose whole job is to say what the operator's own export shows. What both writers inherit
from this section is the index obligation alone — because that one is about the directory, which they
create or repair, rather than about a finding, which neither makes.

### 6.2 The frame-set index

**The format §6.1 makes mandatory is fixed here, once, and every writer cites it.** It lived in
`product-workflows:idea-format` while `/idea` was its only author; `/frames` is a
second author, and one format with two authorities is the defect family this plugin family keeps paying for.
That file now states only what `/idea` contributes to a row and cites this section for everything
else. It belongs here rather than there because it is the *satisfaction* of §6.1's requirement, and a
requirement and its satisfaction drift apart the moment they live in different files.

`<any-specs-folder>/design/<frame-set>/index.md`:

```markdown
---
kind: frame-set-index
key: <the resolved folder's own key, read from its frontmatter, never parsed from its name>
frame_set: <the frame-set directory's own name>
written_by: <the command that last wrote this file>
---

# Frame set: <frame-set>

Every frame this set holds. The set accumulates across runs and across commands, so a row may well
predate the run that last wrote this file. Each description is the describing agent's own account of
what the frame shows — **context, not evidence**: what somebody drew, not what anything does.

| Frame | Linked from | What the frame shows |
|---|---|---|
| `toggle-01.png` | `notes/dark-mode.md` | <the description, verbatim> |
```

**`index.md` is the name a *writer* writes.** §6.1 lets a *reader* accept whatever name the frame-set
convention used, because a set exported elsewhere may already carry a manifest under another name. A
writer has no such excuse, and picks one name so that two writers never leave two indexes disagreeing
in one directory. A run that finds an index under another name **reads it as §6.1 already permits any reader to, adopts every row it can resolve into the `index.md` it writes, and still never edits the original.** The two halves are separable and both matter: a writer that rewrote that file would be fixing a shape it never defined, which is what this rule has always forbidden — but a writer that *ignored* it threw away an operator's curated descriptions and re-emitted every frame as `_no description on record_`, so a set that already had a hand-written manifest came out worse for being indexed. Adoption is not a new tolerance; it is the reader tolerance §6.1 already grants, finally used by the one participant that had been declining it.

**What adoption carries, and what it does not.** A row is adopted when its image resolves to a file in the set's own listing and it carries a description; that description is preserved **verbatim**, under the same rule §6.2 step 2 applies to a row in a real `index.md` — a writer preserves what it did not produce and does not judge it. A row naming an image the listing does not hold is **not** adopted and is reported, because the frame it describes is not in this set. A file the run cannot parse into rows at all is reported and nothing is adopted from it — never a partial guess. The original stays byte-for-byte as it was, and the report names both files so the operator can retire the older one deliberately.

**`key` is read, never parsed** — `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §4, the same rule
every resolver follows. **`written_by` names the command that last wrote the file**, so it changes when
a second writer rebuilds an index the first one authored; it is a record of authorship, never a claim
of ownership, and no rule anywhere keys off it.

**`Linked from` is provenance, and it is frequently absent.** Where the frame arrived through a link —
`/idea` vendoring an image an idea source pointed at — it is the original path of the file that carried
that link, kept as the frame's provenance and **never repointed at the copy**. Where nothing linked it —
a human exported the frames and dropped the folder in — it is `—`.

#### The reconciliation contract

**The index is rebuilt from the frame set as it stands on disk, never from the list of images the run
itself produced.** A set accumulates, so from the second run onward "what this run touched" and "what
the set holds" are different sets — and writing the smaller one leaves every earlier frame sitting in
an indexed directory that identifies none of them: §6.1's own unrecoverable failure, reproduced at row
granularity and silently. Nor is it recoverable from the run's own inputs, because a run holds no
description for a frame it never looked at.

Every writer runs exactly these steps, **after** whatever files it was going to add have landed:

1. **List the images actually in the directory** — every file carrying one of the **frame
   extensions**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.webp`, case-insensitive. `index.md` is not
   a frame and is never a row.

   **This set is defined here and nowhere else, and every writer lists by it.** Two writers of one
   index listing by two vocabularies is not a difference of taste: a file one includes and the other
   does not is a row the second writer drops at step 5 and reports as an image that is no longer
   there, while it sits in the directory — reproducing at row granularity the exact failure that moving
   this format into one authority was meant to end. The set is the extensions a reader can actually
   open, because a frame nothing can render can never carry a description and would hold a permanent
   placeholder that rejoins the describe set on every run, defeating convergence. A file in the
   directory outside this set is **not a frame and never a row**; a writer that finds one names it once
   in its own report so it is visibly not indexed rather than invisibly missing.
1a. **A set that once held frames and now holds none is reported as stale, not silently left.**
   Step 6 forbids writing an index where the listing is empty, and step 5 requires dropping every row
   whose image is gone; on an all-gone set those pull against each other, and the resolution is step 6
   — nothing is written and nothing is removed. That leaves an `index.md` every row of which is, in
   step 5's own words, a promise that resolves to nothing, and because an index is *present*
   `design-grounder` will not return `NO_INDEX`: it will try to read frames that are not there. So the
   writer **names that set explicitly as stale** — the index path, its row count, and that every row's
   image is gone — rather than folding it into "skipped for holding no image". Nothing is deleted here:
   an operator who moved frames out temporarily has not asked for their descriptions to be destroyed,
   and the descriptions are the expensive part.

2. **Preserve every existing row whose image is still in that listing, verbatim** — the frame, its
   `Linked from`, and its description exactly as they stand. A run cannot reproduce a description it
   never received, so a row it cannot reproduce is a row it must not rewrite. **One exception, and it
   is that reason read forwards**: a row whose description is step 4's literal `_no description on
   record_` holds no description to preserve, so a writer that *can* obtain one replaces that row
   instead of preserving it. A writer that cannot leaves it exactly as it stands. Without this
   exception the placeholder would be permanent, and step 4 would convert every cap and every failed
   read into a frame nothing could ever describe.
3. **Append one row per frame this run accounts for and the index does not, in run order**, after the
   rows already present, built from that frame's description and its `Linked from` — **transcribed
   verbatim, never invented**. What a run "accounts for" is the one thing that differs per writer, and
   the table below is where each writer's answer is recorded.
4. **A frame in the listing the run accounts for in no way still gets a row** — `—` in `Linked from`,
   and the literal `_no description on record_` in the last column. Something the run cannot speak for
   put that frame in the set, or a cap or a failed read stopped the run from looking at it. Omitting it
   would rebuild the exact defect this contract exists to prevent, and inventing a description for it is
   the inference §6.1 forbids. **Report it**, with the run's reason where it has one, so the operator
   knows a re-run has work left.
5. **A row whose image is no longer in the listing is dropped**, and reported. The index states what the
   set holds, and a row naming a frame that is not there is a promise `design-grounder` would resolve to
   nothing. Nothing is restored and nothing is re-copied: this step reconciles an index with a directory,
   it never manages the directory.
6. **Write the index whenever that listing is non-empty** — not only when the run added something. A
   re-run that added nothing writes it too, and, with every row preserved and none appended, writes back
   exactly the file that was there. Where the listing is empty, or the directory does not exist, **write
   nothing and create nothing**: an empty index is a claim about a set that does not exist, and an empty
   `design/<frame-set>/` is a directory `design-grounder` would open for nothing.

**The index is written whole or not at all.** Steps 1–5 resolve every row before step 6 writes the file
once, so a run stopped by a cap, an unreadable frame, or an image nothing could describe still leaves a
**valid and complete** index — every frame in the listing carries a row — rather than a half-written
one. What such a run leaves behind is step 4's placeholder and a report saying so; step 2's exception is
what lets the next run finish the job.

**What each writer accounts for.** The steps above are identical for every writer; only this differs:

| Writer | The frames it accounts for | Where a new row's description comes from |
|---|---|---|
| `/idea` | each image it copied into `design/idea-sources/` this run | `idea-reader`'s per-image `description` |
| `/frames` | each frame `frame-describer` read for the set this run | that agent's per-frame `description` |

Neither invents one. An image `/idea`'s reader never opened is not copied and is accounted for nowhere;
a frame `/frames` could not describe, or did not reach before its cap bit, is accounted for nowhere
either. Both land on step 4, and both are reported.

### 6.3 The four reconciliation classes

`design-grounder` reads an exported frame set — screen or report images plus an index — and
reconciles it against the requirement inventory it was handed — a BRD's `[BR#n]` rows, or a PRD's
`[AC#n]`/`[FR#n]`/`[US#n]` rows — in exactly four classes:

1. **A frame shows a field no requirement ever asks for.** The design carries more than the
   requirement asked for; the finding names the field and the frame.
2. **A requirement asks for a field no frame shows.** The inventory names something the design
   never surfaces; the finding names the requirement id and the frame set that was checked.
3. **A frame contradicts the requirement text.** The design and the requirement disagree about the
   same behaviour — for instance, a synthetic BRD requiring a single combined status column while
   the exported frame shows the same information split across two separate columns.
4. **A frame implies a capture the code cannot perform.** This class is why design grounding
   exists: it is where "the report shows who approved this record" meets "no write path in the
   pinned commit records an actor." **This class always cites a `[CG#n]`** — whether the code can
   perform the capture is a code-grounding question, and `design-grounder` answers it by pointing
   at the finding that settled it, never by re-deriving the code answer itself. A `[DG#n]` of this
   class carrying no `[CG#n]` citation is incomplete.
   **A citation that is present and wrong is worse than one that is absent, so the requirement is
   not only that a `[CG#n]` is named but that it is the right one: the cited finding's `claim`
   names the same requirement id as the citing `[DG#n]`'s own `claim`.** An absent citation is
   visibly incomplete and a reader stops; a citation that resolves sends the reader to a real
   finding about a different requirement, which they have no way to detect. Both values sit in
   the two records, so this is checkable wherever both are on hand — `product-workflows:bundle-packaging`
   §6 is the first consumer to check it, at the point the findings are copied in front of a customer.
   **A class-4 finding's standing is derived, not its own, and that is the half a resolving citation
   hides.** Every other finding stands or falls on a search its own writer ran; this one stands on a
   conclusion another finding reached, so it goes stale when that finding moves while its own record
   shows nothing — the ids still match, the citation still resolves, and the correctness test above
   passes on a pair that now disagree. **Wherever a cited `[CG#n]`'s `verdict` is replaced — by §8's
   `contradict` handling, or by a re-grounding run marking it `SUPERSEDED` — every class-4 `[DG#n]`
   citing it is re-derived or superseded alongside it, never left standing.** A class-4 finding
   outliving its own foundation is the one way this class reads as settled while resting on nothing,
   and a reader cannot detect it: they follow a citation that resolves.

## 7. The derivation matrix

Optional (`--derivation-matrix`); one row per data element the BRD asks to display or store. This
is what converts a vague reporting or data requirement into a build list — naming, for each
element, the physical source it would actually come from. Always **implementation-altitude**: even
a BRD requirement written at product altitude decomposes here into implementation facts about where
each element lives.

Seven classes:

| Class | Meaning |
|---|---|
| `EXISTS` | The element is already captured and stored, unchanged |
| `DERIVED` | Computed from data that already exists, not stored directly |
| `NEW-CAPTURE` | Nothing today records it; a new capture point is required |
| `NEW-CONFIG` | Not data at all but a configuration value that must be introduced |
| `PARTNER` | Sourced from a partner or external system, not this codebase |
| `DEFERRED` | Deliberately not resolved by this grounding pass; named as future work |
| `DEPENDENCY` | Available only once a named prerequisite decision ships (§5) |

## 8. Verification

**A finding is not evidence until independently re-derived by a different agent.** `grounding-verifier`
runs as a separate pass, on a different agent from whichever wrote the finding it is checking.

**The verifier does not check citations.** Confirming that a cited `file:line` exists and contains
what the finding says proves only that the citation is real — it does not prove the citation
answers the claim. Instead, `grounding-verifier` independently re-derives the claim **from whatever
source the finding rests on**, starting from the requirement premise — a `[BR#n]` on the BRD route,
an `[AC#n]`/`[FR#n]`/`[US#n]` on the idea route — rather than from the finding's evidence, and
returns one of four outcomes, each with its own evidence.

**Which source that is follows from the finding, not from the verifier's convenience.** Which
finding rests on what, and which anchor inputs are therefore required of a caller, is the table in
`product-workflows:grounding-verifier`'s Inputs section — the single owner of that matrix, including its
fail-closed treatment of an absent or unreadable `class`. It is not restated here. What this
section fixes is the consequence that makes the matrix necessary: demanding a commit of a
design-only finding would leave it permanently unverifiable, and a finding that can never carry an
outcome can never become evidence by the rule below.

| Outcome | Meaning |
|---|---|
| `agree` | Independent re-derivation reaches the same verdict |
| `extend` | The claim holds, but the verifier's own search surfaces evidence the original finding missed |
| `contradict` | Independent re-derivation reaches a different verdict |
| `unprovable` | The verifier could not settle the claim either way, independent of what the original finding concluded |

**`agree` and `extend` both assert the verdict holds, so a differing re-derived verdict falsifies the
outcome rather than qualifying it.** The verifier returns its own re-derived verdict alongside every
outcome, `agree` included. Where that verdict differs from the finding's while the outcome reads
`agree` or `extend`, the two halves of the return contradict each other — this table defines `agree`
as reaching *the same verdict* and `extend` as the claim *holding* — and the caller **normalises the
outcome to `contradict`** and acts on that branch, which is the one that believes the re-derivation.
The normalisation is recorded, never silent. **`unprovable` is never normalised**: its re-derived
verdict is `NOT-PROVABLE` and therefore differs from the finding's by definition, while the outcome
means only that the verifier's own search settled nothing — which is not the same as the finding
being wrong, and normalising it would rewrite every inconclusive finding into a contradiction nobody
reached.

**A failed or absent control is its own route to `contradict`, independent of the verifier's own
search.** Where the finding asserts an absence, the verifier runs its `control` (§2.2) rather than
reading it, and returns `control_outcome` alongside the four outcomes above. `failed` — the control
did not reproduce — and `absent` — the finding asserts an absence and carries no control at all —
each force `contradict` on their own, **including where the verifier's own search also found
nothing**: two searches sharing one blind spot is exactly the state the control exists to expose, and
an `agree` between them would launder it into evidence. `control_outcome` is a return field, never a
record field, on the same terms as `own_verdict` (§2.1) — the caller acts on it and writes `verdict`
and `outcome`, never a third column of its own.

A finding without a verifier outcome is not evidence and cannot be recorded as `consumed_by`
anything. **Findings inherited from another team's report, or from an earlier run of this
workflow, are unverified by definition** — a verifier outcome attached to a different commit, a
different repository state, or a different finding's evidence does not carry forward; each finding
is re-derived against the commit it is currently pinned to.
