# Grounding format (embedded authority)

The canonical finding contract for the BRD→PRD workflow's grounding engine: what grounding is and
is not, the finding record every `[CG#n]`/`[DG#n]` carries, the six verdicts, the
`baseline-integrity` procedure that gates every run, the two horizons a finding can carry, the four
design-grounding reconciliation classes, the optional derivation matrix, and the four verification
outcomes. Design authority: `docs/superpowers/specs/2026-08-29-brd-to-prd-workflow-design.md` §5
(all subsections) and decision rows D6, D7, D19 in §3. Requirement identifiers (`[BR#n]`) are
defined once in `references/brd-format.md` — cited here, not restated; the read-only posture for a
mounted repository is defined once in `references/read-only-repos.md` and applies unchanged to
every repository grounding reads.

**Consumed by** the three grounding agents that write against the contract fixed here —
`agents/code-grounder.md`, `agents/design-grounder.md`, and `agents/grounding-verifier.md` — and by
the two commands that read what they produce: `commands/brd-ground.md`, which orchestrates all
three, and `commands/brd-split.md`, whose Phase 0 gate turns on §8's verification outcomes.

## 1. What grounding is, and is not

Grounding answers one question: **is this specific claim true of this specific commit?** A
`[CG#n]`/`[DG#n]` finding is always an answer to a premise stated by one `[BR#n]` (or, for design
grounding, one BRD requirement reconciled against one exported frame), checked against a pinned
revision of a real repository.

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
| `claim` | the `[BR#n]` premise under test, quoted or closely paraphrased |
| `verdict` | exactly one of the six values in §3 |
| `evidence` | a `file:line` list, or — when the verdict is `NOT-PROVABLE` or the finding asserts an absence — an explicit statement of why no evidence exists rather than an empty field |
| `commit` | the pinned commit SHA the finding was checked against (`baseline-integrity`, §4) |
| `altitude` | one of `product \| architecture \| implementation` |
| `horizon` | one of `current \| will-change` (§5), naming the prerequisite decision when `will-change` |
| `class` | *(design-grounding only)* one of the four `[DG#n]` reconciliation classes defined in §6; absent on a `[CG#n]` |
| `cites` | *(design-grounding only)* a `[CG#n]` id; required when `class` is the fourth (§6) and empty otherwise; absent on a `[CG#n]` |
| `consumed_by` | one of `PRD \| ARD \| specification \| none` — which downstream artifact has actually drawn on this finding; `none` until something has |

`class` and `cites` apply only to `[DG#n]` findings — a `[CG#n]` finding carries neither. See §6 for
what the four classes mean and why the fourth requires a citation; this table fixes only the field
names, where they apply, and when `cites` is required.

**`evidence` is never blank.** A finding that asserts a mechanism is absent still owes the reader
what was searched and where it was expected — "no route under `api/` handles this verb; searched
`api/**/*.py` at the pinned commit" is evidence; a bare empty field is not.

**`consumed_by` starts at `none` and is written later**, by whichever downstream authoring command
actually cites the finding — this file fixes only that the field exists and what its values mean,
not when a caller updates it.

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
an interview answer still open for revision. **A prerequisite whose decisions are not yet frozen
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

`design-grounder` reads an exported frame set — screen or report images plus an index — and
reconciles it against the BRD's requirements in exactly four classes:

1. **A frame shows a field the BRD never requires.** The design carries more than the customer
   asked for; the finding names the field and the frame.
2. **The BRD requires a field no frame shows.** The customer asked for something the design never
   surfaces; the finding names the `[BR#n]` and the frame set that was checked.
3. **A frame contradicts BRD text.** The design and the requirement disagree about the same
   behaviour — for instance, a synthetic BRD requiring a single combined status column while the
   exported frame shows the same information split across two separate columns.
4. **A frame implies a capture the code cannot perform.** This class is why design grounding
   exists: it is where "the report shows who approved this record" meets "no write path in the
   pinned commit records an actor." **This class always cites a `[CG#n]`** — whether the code can
   perform the capture is a code-grounding question, and `design-grounder` answers it by pointing
   at the finding that settled it, never by re-deriving the code answer itself. A `[DG#n]` of this
   class carrying no `[CG#n]` citation is incomplete.

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
source the finding rests on**, starting from the `[BR#n]` premise rather than from the finding's
evidence, and returns one of four outcomes, each with its own evidence.

**Which source that is follows from the finding, not from the verifier's convenience.** Which
finding rests on what, and which anchor inputs are therefore required of a caller, is the table in
`agents/grounding-verifier.md`'s Inputs section — the single owner of that matrix, including its
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

A finding without a verifier outcome is not evidence and cannot be recorded as `consumed_by`
anything. **Findings inherited from another team's report, or from an earlier run of this
workflow, are unverified by definition** — a verifier outcome attached to a different commit, a
different repository state, or a different finding's evidence does not carry forward; each finding
is re-derived against the commit it is currently pinned to.
