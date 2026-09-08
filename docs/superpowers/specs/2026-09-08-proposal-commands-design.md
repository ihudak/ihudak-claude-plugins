# `/prd-proposal` and `/brd-proposal` — effort proposals for a slice and for a BRD — design

**Status:** approved in brainstorming 2026-09-08, not yet implemented. No ledger item — this is a new capability rather than a repair, and it opens no existing entry.

**Plugin:** both commands ship from `product-workflows`, which already owns the idea→PRD→ARD→specification ladder and the six-command BRD-to-PRD route. One new agent, `product-workflows/agents/proposal-reviewer.md`. One new reference, `product-workflows/references/proposal-format.md`. One new operator-owned config file in the specs repo.

**Derivation.** This design was reverse-engineered from two pairs of real proposal documents produced by hand during live engagements — a slice-level Time & Material proposal with its two-page rationale pre-read, and an earlier programme-level proposal aggregating roughly thirty stories across eleven epics into two phases. Those documents are the requirement; this design is the account of how a command reproduces them. **Every figure, requirement identifier, organisation name and product name in those sources has been genericised out of this specification and must stay out of the plugin** — see §13, which is a hard constraint on the implementation and not a stylistic preference.

## 1. The problem

The marketplace takes a requirement from a customer document to an implemented, documented change: `/brd-intake` through `/brd-reconcile` on the BRD route, `/idea` through `/create-prd` on the idea route, then `/create-ard`, `/specify`, `/epics`, `/design`, `/implement`, `/document`, `/release-notes`. A grep across every plugin for an estimate, proposal, effort or work-package concept returns nothing. The pipeline can say precisely what is to be built, why, against which verified evidence, and under which customer decisions — and then has nothing to say about **what it will cost in human time, who does it, and over how long.**

That gap is filled by hand today, and filling it by hand has three failure modes that are all visible in the source documents:

- **The rationale drifts from the estimate.** The proposal and its pre-read brief agree only because they were written in one sitting. The next revision of either is where they diverge, and the brief is the document that gets read first.
- **The reasoning is not reproducible.** The interesting property of a grounded estimate is not the number, it is the argument for why the number is roughly eight times what the naive reading of the requirement suggests. That argument is built entirely from grounding findings that already exist on disk, in a structured, verified, citable form — and is nonetheless re-derived from memory each revision.
- **Nothing checks the arithmetic.** A ten-package by seven-role hours table, authored by a language model in prose, is exactly where a silent addition error survives to a customer.

There is also a second, quieter gap. An operator repeatedly asked at what point a requirement set becomes estimable — after the PRD, after the ARD, after the specification, or only after Epics — and the pipeline offered no answer, so the question was settled by feel each time.

## 2. Decision

**Two commands, in `product-workflows`.**

`/prd-proposal <ADDRESS>` authors an effort proposal for one `PRD-` folder: work packages, hours by package and role, ranged with per-package confidence, a driver table in which every cost driver cites verified grounding evidence, a delivery approach, a team composition, an indicative schedule, assumptions, dependencies, risks, change control, acceptance, exclusions and traceability.

`/brd-proposal <ADDRESS>` authors the umbrella for a `BRD-` container: a roll-up over its slices' proposals, with the cross-slice effort that exists in no slice, de-duplication of shared work, one programme schedule, one team, and a coverage statement computed from the root coverage ledger.

Each run writes **two artifacts** — the full proposal and a short derived rationale brief — from one resolved data set, so the two cannot disagree.

**The hours are model-derived.** This is the decision that shapes everything else and it is taken deliberately rather than settled by default: in the source engagement both revisions of the estimate were produced by a language model from the requirement set and the grounding, and they held up under customer scrutiny. What made them defensible was not an external anchor — the first revision reconciled to a prior task-level estimate that most users of this marketplace will simply not have — but the **evidence chain**: every driver cited code at a specific line, every package carried a confidence grade with a stated reason, ranges widened where evidence was thin rather than expected values moving, and anything genuinely not estimable carried a declared re-estimate gate instead of a number pretending to be one. Every one of those properties is reproducible for any user with a grounded slice, and each is enforced in §6 and checked in §11.

**The estimate is of human delivery time, in hours.** The marketplace already emits model spend in USD through `workflows-core:cost-emission`. Two different quantities, both colloquially "cost". No command, agent, reference or artifact introduced by this design may conflate them, and the proposal artifacts carry **no money at all** (§9).

## 3. Command surface, altitude and refusals

```
/prd-proposal <ADDRESS> [--no-brief] [--profile] [--baseline <path>] [--redo]
/brd-proposal <ADDRESS> [--no-brief] [--profile] [--redo]
```

- `--no-brief` suppresses the rationale brief. The brief is on by default and is additionally suppressed below tier 2 by §4.
- `--profile` forces a re-grill of the proposal profile (§9) instead of reading the stored one.
- `--baseline <path>` supplies a prior task-level estimate. It is the **only** thing that makes the reconciliation section render; absent, that section does not exist, is not a gap, and the document does not apologise for its absence.
- `--redo` forces a clean-room re-derivation that ignores the prior revision as an anchor (§6, §10).

**Address resolution** is `workflows-core:addressing` §3 `resolve-address`, taken after `$SPECS_PATH` is settled, exactly as `/create-prd` and `/create-ard` state the ordering and for the same reason: a resolution taken before the variable is known returns `absent` for a folder that exists.

**Altitude, and a deliberate inversion of the container refusal.** Seven commands on the BRD route today refuse a resolved `BRD-` container and demand a slice. `/brd-proposal` is the **first command whose natural altitude is the root**, joining `/brd-intake` and `/brd-split`. The two new commands therefore refuse each other symmetrically, and each names the other:

- `/prd-proposal` on a `BRD-` container stops with `PRD_PROPOSAL_BRD_NOT_SLICED`, and — unlike the seven existing refusals, which can only redirect — offers a genuine alternative: `/brd-proposal <BRD-KEY>` for the umbrella, **and** `/prd-proposal <SLICE-KEY>` once per enumerated slice.
- `/brd-proposal` on a `PRD-` folder stops with `BRD_PROPOSAL_NOT_A_CONTAINER`, names `/prd-proposal <SLICE-KEY>` as the run intended, and offers the parent BRD's key read from `brd-link.md`'s `parent:`.

The container test is the **directory prefix**, never the folder's asserted `kind:` — `/brd-split` writes `kind: brd` into the `brd-link.md` inside a `PRD-` slice folder, so a slice asserts `brd` while being exactly the folder a proposal belongs in. Where a folder resolved through `workflows-core:addressing` §5's legacy fallback and carries no prefix, the question is answered by the positive evidence test in `product-workflows:coverage-ledger-format` §5.1, the shared authority the other refusals already take. None of this is restated in the command; it is cited.

**`/prd-proposal` is not BRD-route-only.** A `PRD-` folder is a `PRD-` folder. An idea-route PRD carrying no `brd-link.md`, no `decisions.md` and no `grounding/` estimates fine — it simply grades at tier 1 (§4). This matters for marketplace generality: most users are on the idea route, and a command reachable only after `/brd-intake` would serve almost nobody. `/brd-proposal` is inherently BRD-route-only, because a `BRD-` container is the only thing it can aggregate.

**Gate.** `require-on-main` (`workflows-core:phase-handoff` §3) on `prd.md` in the resolved folder, the same gate `/create-ard` and `/specify` apply, mapped by `stopped` first and never by `on_main` alone, and resolving the file's actual name on the ref before gating it — the keyless `prd.md` on a current tree, a `<KEY>_*.md` entry only through the legacy fallback. `/brd-proposal` gates on each **included** slice's `proposal.md` being on the default branch. **Nothing gates on `ard.md` or `specification.md`** — that is what grading replaces, and it is the whole answer to the estimability question.

**Model routing.** Both commands classify as **SIGNIFICANT** under `workflows-core:model-routing`: the output is a customer-facing commercial document, it carries an Opus review gate, and an error in it is expensive and slow to discover. The proposal is authored inline by the command, as `prd.md`, `ard.md` and `specification.md` are — there is no writer agent, because the authoring is the command's whole purpose and a handoff would only add a place for the resolved data set to be lost.

## 4. Readiness grading — when a PRD is ready to be estimated

The command **grades rather than gates**. There is exactly one hard refusal, no `prd.md`, and `require-on-main` already performs it.

| Tier | Reached when the resolved folder holds | What the tier changes |
| --- | --- | --- |
| **1 · Indicative** | `prd.md` | The driver section renders as an explicit statement that the cost drivers are **not known** — never as an empty or omitted section. Standing banner in the header block. |
| **2 · Grounded** | \+ verified grounding, \+ a settled decision register | Driver table with `file:line` evidence; accepted deviations; scope levers. **The floor for a document that goes to a customer.** |
| **3 · Architected** | \+ `ard.md` | The discovery package becomes *translation* of an existing architecture rather than authoring one. Architecture-bearing packages become eligible for High confidence. |
| **4 · Specified** | \+ `specification.md` | QA effort is sized from the authored test-case count rather than a ratio of development effort; the definition of done is built from the acceptance criteria; analysis effort falls to refinement rather than acceptance-criteria authoring. |

**Both tier conditions reuse rules that already exist, and neither introduces a second definition.** *Verified grounding* means every finding carries a verifier outcome — `workflows-core:grounding-format`'s rule that a finding without an outcome is not evidence, which `/brd-split` already gates on. *A settled register* means every interview round is settled, the test `/brd-package` already applies.

**An idea-route PRD caps at tier 1 today, and that is a truthful grade rather than a defect.** Verified grounding and a settled decision register are both produced by the BRD route and by nothing else: `/prd-ground` gates on a `coverage-ledger.md` and `/brd-interview` on grounding, so neither is reachable from a folder `/idea` and `/create-prd` built. `/idea --ground-code` does not close the gap and must not be treated as closing it — `code-scanner` discovers capability, whereas `workflows-core:grounding-format` fixes grounding's question as whether a specific claim is true of a specific commit, and only the second can carry a driver. A tier-1 proposal is still a real document: scope, work packages, team, schedule, a ranged number and every assumption and dependency. What it does not carry is the argument for why the number is what it is, which on the idea route genuinely has no evidence behind it. Extending an evidence source to the idea route is a plausible later feature and is out of scope here (§15).

**The tier caps confidence; it never sets it.** This is the load-bearing mechanic. Range width is computed bottom-up from per-package confidence (§6), and the tier is a **ceiling** on how confident any package may be — evidence can only push a package lower. In the source engagement the slice sat at tier 4 and still carried an asymmetric range roughly −20 %/+40 %, because one package remained un-profiled and therefore Low regardless of tier. A tier-derived global percentage would have flattened precisely the signal the document existed to convey.

**Two structural consequences, expressed as behaviour rather than as warnings:**

- **The brief does not render below tier 2**, irrespective of `--no-brief`. Its entire content is the driver argument. A two-page pre-read explaining why a number is large, written when the reasons are unknown, is the one artifact in this design that must not exist.
- **The tier is printed in the header block of both artifacts**, beside the date. A reader cannot be handed a tier-1 number without being told what it is.

**Epics are not an input, and their absence is not a gap.** The source slice reached a defensible tier-4 estimate with no `EPIC-` folder anywhere beneath it; `/epics` never ran. The estimate decomposes by **work package**, a delivery-sequencing unit the proposal derives (§5), which is not the same object as an Epic and is not substitutable for one. Where `EPIC-` folders exist they seed the clustering; where they do not, nothing is missing and the command says nothing about it.

## 5. Work packages

Requirements cluster by **delivery seam** — what can be built, tested and accepted independently. That property is not decorative: the delivery-approach and acceptance sections both depend on it, and a package that cannot be accepted on its own makes both sections false.

**Two packages are always present:** a discovery-and-design package first, and a test/UAT/release package last. Where `EPIC-` folders exist under the resolved PRD, they seed the clustering of the middle packages.

**A defect-remediation package is created automatically, and it is never a scope lever.** Where the resolved folder's `code-defect-log.md` holds an unresolved `[CDF#n]`, its repair becomes its own work package. This encodes the bug-first policy structurally rather than leaving it to be remembered: in the source engagement the first revision offered two found security defects back to the customer as priced options, and the second withdrew that offer and moved them into scope, on the reasoning that asking a customer to authorise deferring a defect the vendor's own work found returns that deferral carrying the customer's authority on a question the vendor's policy has already answered.

The command therefore **refuses to render a defect-remediation package into the scope-lever table or the priced-options table**, and the reviewer (§11) checks it. Where such a package genuinely cannot fit the delivery window, that is disclosed in the document as a schedule fact, not tendered as a scope option.

## 6. The estimate

**The naive baseline is computed and printed first.** A short statement of what the requirement would cost if read at face value — storage and exposure, with no correctness, completeness or enforcement obligation — precedes the driver table. This is mandatory at every tier. It is the anchor that makes the real number legible: without it the reader has nothing to compare against, and the argument in the driver table has no subject.

**Every driver must cite evidence.** One driver row is one or more verified grounding findings, cited by identifier with the `file:line` location the finding itself records. **A driver with no finding behind it cannot render at all.** This is the anti-invention rule, and its value is that it is mechanically checkable rather than a matter of authorial care — the reviewer resolves every citation against the grounding file.

**Hours per package and role** are derived from the requirement count and kind within the package, the drivers touching that package, and the profile's productivity basis and hours-per-developer-day (§9). QA effort is sized from the authored test-case count at tier 4 and from a stated ratio below it, and **the document says which of the two it used** — a ratio silently replaced by a count, or the reverse, is a change in basis that a reader is entitled to see.

**Confidence is per package, with a stated reason, and rolls up into the range.** The document states explicitly that the low and high figures describe a credible range rather than best and worst cases. A package graded Low gets a **declared re-estimate gate naming its trigger event** — the completion of a profiling activity, the arrival of a decision, a load measurement — together with the commitment that no implementation hours inside that package are incurred before the gate. A wide range with a dated gate is an honest artifact; a narrow range over unprofiled work is not.

**Open items become dependencies automatically.** Open assumption records, unanswered customer questions from the interview round, and any code defect recorded as blocking render into the dependencies section and into the short "what is needed before week 1" list. Derived from the register, not authored — so a question raised of the customer and not yet answered cannot silently vanish between the review package and the proposal.

**The stability rule, which is what makes a re-run safe.** Model-derived hours have a failure mode operator-supplied hours do not: an estimate that wanders when nothing changed. A re-run therefore **always re-derives its inputs**, but the prior revision is an **anchor** — a package's expected hours carry forward unchanged unless something feeding them changed, and where a figure moves, the changelog section (§10) must name the cause. A figure that moved with no cited cause is a defect the reviewer raises, not a refresh. `--redo` discards the anchor deliberately, for when the prior estimate is known to be wrong.

## 7. `/brd-proposal` — enumeration, the readiness walk, and coverage

**Slices are enumerated by the positive test that already exists** — an immediate subdirectory carrying a `brd-link.md` whose `parent:` names this BRD, exactly as `/brd-split` Phase 0 defines it. A name match is not the test. Zero slices is a stop, naming `/brd-split <BRD-KEY>` as the run that carves one.

**The readiness walk.** Three states, not two, and the command always carries a computed recommendation rather than presenting a bare menu:

| Slice state | Recommendation |
| --- | --- |
| No `proposal.md`, and the slice grades tier ≥ 2 | **Stop.** Run `/prd-proposal <SLICE-KEY>` first — the slice is estimable, and excluding it understates the programme. |
| No `proposal.md`, and the slice grades tier 1 or holds no `prd.md` | **Exclude, and disclose.** Nothing better is available today, and stopping buys nothing. |
| `proposal.md` present but older than the slice's own `prd.md`, `decisions.md` or grounding files | **Re-run it.** This is the common case and the easiest to miss. |

Exclude-or-stop remains the operator's decision in every case; only the recommendation is computed.

**Coverage is computed from the root coverage ledger, never asserted.** The walk classifies every root row: `covered-by` an included slice; `covered-by` an **excluded** slice, disclosed by requirement identifier; still `unallocated`, meaning never sliced and therefore never estimated; or terminal — `deferred-to`, `rejected`, `superseded-by` — disclosed with the reason the ledger records. The umbrella then states what proportion of the BRD's requirements the proposal covers **and enumerates the remainder by identifier**, which is a materially stronger statement than "it includes the existing PRDs" and cannot go stale, because it is recomputed from the ledger on every run.

## 8. `/brd-proposal` — the roll-up

**The roll-up is not a sum**, and its three adjustments are each named in the document rather than absorbed into a total:

- **Umbrella effort that exists in no slice** — programme management across slices, cross-slice integration, one release and one acceptance campaign rather than one per slice.
- **De-duplication, which is mechanically detectable.** Two slices that each priced the same discovery activity or the same shared component will **cite the same verified finding identifier** in their driver tables. The command flags every finding claimed by more than one included slice and asks the operator whether it is genuinely two pieces of work. A silent sum double-counts exactly this.
- **Sequencing.** Slices sharing a team do not add their FTE figures; peak concurrency is computed from the programme schedule. Slice order is taken from `depends_on` in each slice's PRD frontmatter, which is already written by `/create-prd` and already correct.

**Detail stays in the slice proposals**, per the instruction this design was written to. The umbrella carries one row per slice — hours, range, tier, confidence — plus aggregated roles, one team composition, one schedule, the cross-slice dependency graph, and the coverage statement. It does not restate driver tables, and it does not re-derive any slice's hours.

**The umbrella's tier is the minimum of its included slices' tiers, and it prints the mix.** A programme cannot claim to be specified because three of its five slices are.

**Ranges are summed, and stated as summed**, carrying forward the same caveat that low and high are not simultaneous outcomes. A statistical roll-up would be narrower and would be unexplainable in the meeting the document exists to survive; that is the wrong trade here, and it is recorded so it is not proposed as an improvement later.

## 9. The proposal profile

Model-derived hours are meaningless without a stated productivity basis, and a small set of inputs cannot be derived from any artifact on disk. They live in one operator-owned file in the specs repo, `$SPECS_PATH/.dev-workflows/proposal-profile.yml`, which borrows the **shape and directory name** `/docs-profile` established with `.dev-workflows/docs-profile.yml` — but not its location: that file lives in the docs repository because that is what `/docs-profile` writes to, and this one lives in the specs repository for the same reason.

```yaml
vendor:
  name: ""                      # no default ships with the plugin
  footer_note: ""
client:
  name: ""
engagement_model: time-and-material   # or fixed-price
roles:
  - { id: tl, title: "Tech Lead / Architect", part_time: true }
  - { id: be, title: "Backend Engineer",       count: 2 }
  # ...operator's own team shape; the plugin ships generic titles only
productivity:
  hours_per_developer_day: 8
  basis: ""                     # e.g. "two backend engineers working with AI assistants"
calendar:
  hours_per_week: 40
```

It is grilled on the first run that needs it, shown back for confirmation on later runs, and re-grilled with `--profile`. `engagement_model` restructures the engagement-governance, change-control and priced-options sections wholesale, and is asked rather than assumed.

**No rates, no currency, no money for human hours** — not in the profile, not in either artifact, at any tier, under any flag. The source documents carry none: rates are contractual and belong in a document this pipeline does not produce, and a marketplace plugin that writes a rate card into a git-committed file is a disclosure waiting to happen. The reviewer checks for it (§11). Model spend in USD is emitted by `workflows-core:cost-emission` and is untouched by this design.

## 10. Artifacts, versioning, and the changelog section

**Canonical artifacts** are `proposal.md` and `proposal-brief.md`, written into the resolved folder — the `PRD-` slice folder for `/prd-proposal`, the `BRD-` container for `/brd-proposal` — beside the artifacts they cite, so the traceability section is relative links that resolve rather than names a reader must go and find.

**Prior revisions are archived.** The archive path and naming **must match `/update-prd`'s existing canonical-plus-archived convention**; this design deliberately does not specify a shape, because a convention already exists and the implementer is to read and follow it rather than create a parallel one.

**The document's structure is fixed by a new reference**, `product-workflows/references/proposal-format.md`, in the manner of `prd-format.md` and `specification-format.md`: the section set, which sections are conditional and on what, the identifier namespaces the document mints, and the rules a reviewer checks.

**Two namespaces, and deliberately only two.** `[WP#n]` names a work package and `[ED#n]` names an estimate driver; every hours figure, confidence grade, schedule row, acceptance clause and scope lever attaches to a `[WP#n]`, and every driver row to an `[ED#n]`. A re-estimate gate is a **property of its `[WP#n]`**, not a namespace of its own — the family already carries fifteen bracketed namespaces, and a sixteenth earning its keep is a higher bar than a seventeenth being conceivable. Two sections are conditional — the reconciliation section renders only under `--baseline`, and the changelog section only on a revision.

**The changelog section is generated by diffing against the anchor**, one row per moved figure or changed section, each with a direction and a pointer to the section that now carries it.

**And it classifies each row as a re-estimate or a correction.** This is the most valuable distinction in the source document and it is a computed classification, not prose: a change that **withdraws or contradicts a statement the previous revision made to the customer** is a correction; a figure that moved is a re-estimate. Corrections are listed first, are stated in the customer's own terms, and are never folded into a net total — a revision that quietly nets a withdrawn claim against a re-estimate is precisely the artifact this rule exists to prevent.

## 11. The `proposal-reviewer` agent

A new Opus agent in `product-workflows/agents/`, read-only, adversarial in the mould of `brd-package-reviewer`, returning findings plus a `PASS` / `PASS WITH RECOMMENDATIONS` / `BLOCK` verdict. It checks:

1. **Evidence.** Every driver cites at least one verified grounding finding, and every citation resolves to a finding that exists and carries a verifier outcome.
2. **Arithmetic.** Package-by-role totals reconcile to the role totals and to the grand total; every range brackets its expected value; FTE reconciles to hours ÷ weeks ÷ hours-per-week; the umbrella's totals reconcile to its slice rows plus its named adjustments. This is the check with the highest expected yield in the whole design: a model-authored table of ten packages by seven roles is where a silent addition error survives to a customer.
3. **Stability.** No figure has moved from the anchor without a cause named in the changelog section.
4. **Policy.** No defect-remediation package appears in the scope-lever or priced-options tables.
5. **Money.** No rate, currency symbol or monetary total for human hours appears anywhere in either artifact.
6. **Tier honesty.** The tier claimed in the header is the tier the evidence on disk supports, and the brief is absent below tier 2.
7. **Brief agreement.** Every figure the brief repeats matches the proposal.
8. **Completeness of obligations.** Every open assumption record, unanswered customer question and blocking code defect reaches the dependencies section.
9. **Coverage** (`/brd-proposal` only). The coverage statement reconciles to the root ledger, and every excluded slice's requirements are enumerated.

Findings are triaged and verified by the caller under `workflows-core:finding-triage`, as every other reviewer gate in the family is.

## 12. Pipeline integration

### 12.1 The shared machinery both commands run

Nothing here is novel; it is enumerated rather than gestured at, because "the standard shape" is not a specification and an implementer cannot build from it.

- **`specs-preflight`** (`workflows-core:specs-repo-git` §3), as early as `$SPECS_PATH` is known. A `specs_git: blocked` return is carried for the whole run and skips the terminal commit.
- **`workflows-core:escalation-rules`** for every prompt either command raises — the profile grill (§9) and the readiness walk (§7). Choices arrays of two to four options, and **never an authored "Other"**: §0 is explicit that the harness supplies the free-text escape itself.
- **`workflows-core:grilling-technique`** governs the profile grill.
- **`workflows-core:prose-formatting`** governs both artifacts. They are prose documents; prose is never hard-wrapped, one unbroken line per paragraph.
- **`workflows-core:pre-lint`** before the review gate, as `/create-prd` runs it — a cheap pass ahead of an expensive Opus one.
- **`handoff-to-main`** (`workflows-core:phase-handoff` §4.3) for `proposal.md`, `proposal-brief.md` and, on a revision, the archived prior.
- **`impl-maintenance`**, whose Lessons Learned report feeds **`emit-auto`** (`workflows-core:feedback-emission`, the automatic caller of the three named entry points).
- **`emit-cost`** (`workflows-core:cost-emission` §11), supplying `command`, `phase`, `role`, `key`, `source` and `plugin_version` like the other twenty measuring commands. This entry records **model spend in USD** and has no relationship whatever to the human hours the artifacts contain (§2).
- **`followup-emission`** §8's caller contract, with the end-of-run batch preview.
- **`next-phase-offer`**, with **`session-hygiene`** co-firing on the same role labels — §12.2.
- **`commit-artifacts`** as the last action, skipped on `specs_git: blocked`.

**Neither command takes documentation grounding, and neither carries `--no-docs`.** This is a decision, not an omission: `docs-grounder` retrieves existing product-documentation pages, which bear on how a feature is described and not at all on what it costs to build. The inputs to an estimate are the specs tree and the profile. Adding the switch would buy a consent prompt and a retrieval round for a digest nothing in either artifact could consume.

### 12.2 The workflow edges — and they run in both directions

Adding a command adds edges to the routing graph, and `CLAUDE.md`'s Surgical Changes rule makes the reverse direction mandatory rather than optional: a node nothing offers is a node nobody finds.

**Role label: PM.** The proposal is authored from PM-altitude artifacts and is commercially owned. Every printed command name is fully qualified per rule 6.

**Offers out of `/prd-proposal`,** on a clean run, following rule 5's depth-and-breadth shape with the slice standing where an Epic stands:

- **Depth** — `/product-workflows:brd-proposal <BRD-KEY>`, where the folder has a parent BRD, so the slice's proposal rolls into the umbrella.
- **Breadth** — `/product-workflows:prd-proposal <SIBLING-SLICE-KEY>`, for the next sibling holding no current proposal.
- **And, below tier 4, the command that would raise the tier** — `/product-workflows:create-ard` at tier 2, `/product-workflows:specify` at tier 3 — named together with the plain statement that re-running the proposal afterwards narrows the range. This is the one offer that tells the operator the document they just received is improvable, which is worth more than a forward pointer.

**Offers out of `/brd-proposal`:** no forward advance — the umbrella is the end of this branch, not a phase in the build ladder. It offers re-runs: `/product-workflows:prd-proposal <SLICE-KEY>` for each slice the readiness walk found stale or excluded, and itself afterwards.

**Offers into the new commands, added to exactly three existing commands** — the three at which the tier actually changes, and no others, so the offer is never noise:

| Add an offer of `/product-workflows:prd-proposal <KEY>` to | Because that run takes the slice to |
| --- | --- |
| `/brd-reconcile` | tier 2 — the register settles, and the slice becomes sendable |
| `/create-ard` | tier 3 |
| `/specify` | tier 4 |

**One interaction the implementer must check rather than assume.** This repository's build gates include a check that enforces a `<merge-clause>` on any offer of `/create-ard` or `/specify` within the command-family globs. `/prd-proposal` offers both of those commands under the tier-raising rule above, so it may fall inside that check's scope the moment it is added. Run the repository's own gate checks after wiring the offers, and satisfy the clause rather than exempting the command from the check.

### 12.3 Documentation and catalogue

Both commands are added to the workflow map in the repository `CLAUDE.md`, to `product-workflows/README.md`, to its `docs/` tree with a page each in the shape the existing per-command pages take, and to the plugin's `CHANGELOG.md`. `next-phase-offer.md`'s routing graph gains both nodes. The `product-workflows` blurb in **both** `plugin.json` and `marketplace.json` must be **re-worded rather than appended to**, and must stay inside the 1024-character catalogue limit `scripts/validate-catalog.py` enforces — the limit is Copilot CLI's and it rejects the whole catalogue, so one over-long blurb breaks installation for every plugin in the marketplace.

## 13. Vendor neutrality — a hard constraint on the implementation

This design was derived from real customer-facing proposals. **No organisation name, product name, customer name, personal name, repository name, requirement identifier or monetary or hours figure originating in those documents may appear anywhere in the plugin** — not in a command, an agent, a reference, a README, a docs page, an example, a fixture or a test. Every illustration in the shipped material uses neutral placeholders in the style the marketplace already uses for example keys.

This applies to the implementing agent as well as to the authored files: the plugin repository is public, and the marketplace is installed by third parties. Where an example is needed, invent one.

## 14. Alternatives considered and rejected, recorded so they are not re-proposed

**Operator supplies the hours; the command only structures them.** Rejected on evidence: the source estimates were model-derived and survived customer scrutiny, and a command that demands a number for every package before it will render anything discards the countable inputs — acceptance-criteria counts, test-case counts, verified finding counts — that are already on disk.

**Require reconciliation to a prior task-level estimate.** Rejected as a *requirement* and kept as an *option* (`--baseline`). The reconciliation in the source document was excellent and is worth supporting, but it existed only because that engagement happened to carry an earlier whole-epic estimate. Most marketplace users have none, and a command that requires one is unusable for them.

**Gate the proposal on the ARD and the specification.** Rejected in favour of grading (§4). Gating would refuse to estimate the single most common state a user is in — a PRD with grounding and no ARD — which is also a state in which a perfectly defensible ranged estimate is available.

**Derive work packages from Epics, and require `/epics` first.** Rejected on evidence: the source slice reached tier 4 with no Epic folder in existence. Epics seed the clustering where they exist and are never required.

**A third command for the profile.** Rejected: its only job runs once, and `/docs-profile`'s precedent is a file, not a ceremony. Folded into the two commands as a first-run grill.

**A separate command for the rationale brief.** Rejected: its only real work would be re-reading the proposal, and a stale brief beside a fresh proposal is the exact failure it would introduce.

**Writing the artifacts outside the specs repo.** Rejected: it would need a write path outside `commit-artifacts` and outside the git contract every other command shares, for one command, and would be dead weight for users who keep no second repository. Copying a rendered file elsewhere is a thing the operator can do and the plugin need not know about — an `--export` flag was considered and dropped as unearned surface.

**Statistical roll-up of ranges across slices.** Rejected in §8.

## 15. Out of scope, stated so a reader does not reintroduce them

Pricing in money, rate cards and any commercial term. Contract or SOW generation. Tracker synchronisation of any kind — no work package, package estimate or schedule is written to any external system, consistent with the family's rule that a key addresses a folder and never a record in a tracker. Actuals capture, burn tracking or variance reporting against a delivered engagement: the proposal states how those will be governed, and does not perform them. Resource assignment of named individuals. Any modification to `cost-emission`, which measures a different quantity. Automatic re-running of `/prd-proposal` from `/brd-proposal` — the umbrella recommends and never runs the slice command itself. Documentation grounding, for the reason in §12. An evidence source that would lift an idea-route PRD above tier 1.

## 16. Risks

**A plausible number with a defensible-looking argument is more dangerous than an obviously rough one.** The mitigations are the tier printed in the header, the mandatory naive baseline, the citation rule that prevents a driver rendering without evidence, and per-package confidence — but the residual risk is real and the reference file should say so in as many words to the operator, who is the one sending the document.

**Model-derived hours drift between revisions.** Mitigated by the anchor rule (§6) and checked by the reviewer, which is why the anchor is a rule rather than a convention.

**The de-duplication check depends on two slices citing the same finding identifier.** Genuinely shared work described from two different findings will not be detected, and the umbrella will overstate. The command discloses the limit of the check rather than implying the sum is proven.

**Profile rot.** A productivity basis captured once and never revisited silently mis-scales every later proposal. Mitigated by showing the profile back for confirmation on every run rather than reading it silently.

**Most marketplace users are on the idea route, where the command caps at tier 1.** The capability lands strongest for BRD-route users and thinnest for everyone else. This is disclosed rather than mitigated: the tier is printed, the brief is withheld, and the driver section says outright that the drivers are unknown. It is nonetheless the sharpest limitation of the feature as specified, and whoever plans the work should know it before deciding how much to build.

## 17. Implementation sequencing

Four deliverables in strict order, because each is the previous one's consumer.

1. **`proposal-format.md`, then `/prd-proposal`, then `proposal-reviewer`** — the format fixes the section set and the two namespaces; the command authors against it; the agent checks against it. The reviewer is not optional and not a later increment: its arithmetic check (§11.2) is the highest-yield check in the design, and shipping the author without it ships an unchecked hours table to a customer.
2. **`/brd-proposal`** — it reads `proposal.md` files, so it cannot be specified against a format that does not exist yet, and its de-duplication check (§8) depends on the driver citations the first command writes.
3. **The workflow edges** (§12.2) — the offers out of both new commands, the offers into them added to `/brd-reconcile`, `/create-ard` and `/specify`, and both nodes added to `next-phase-offer.md`'s routing graph. Then run the repository's own build gates, because the tier-raising offer may bring `/prd-proposal` inside the `<merge-clause>` check.
4. **Documentation and catalogue** — the workflow map in `CLAUDE.md`, the `product-workflows` README and `docs/` pages, `CHANGELOG.md`, and the re-worded blurb inside the 1024-character limit.

A useful first milestone is `/prd-proposal` at tier 4 against a folder that already holds a PRD, an ARD, a specification, a settled register and verified grounding: it exercises every branch that matters, and the lower tiers are subtractions from it rather than separate paths.
