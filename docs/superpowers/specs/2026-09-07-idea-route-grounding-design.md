# Idea-route grounding — design

**Status:** approved in brainstorming, not yet implemented. Third and last of three sequenced release
gates; the first shipped as `product-workflows` 2.0.0 and the second as 2.1.0. Blocks the release
under S18.

**Settles:** §5 of `docs/superpowers/specs/2026-09-06-slice-first-grounding-design.md`, which recorded
this as sequenced third and named its blocker — that `/brd-ground` builds its claim list from
`[BR#n]` inventory rows and an idea-route folder has none, so the claim source is a design decision
rather than a clause.

## 1. The problem

The two routes into a PRD are unequal in one specific way. A BRD-route slice gets a verified
`[CG#n]` foundation: every requirement checked against real code at a pinned commit, every finding
independently re-derived by a second agent before it counts as evidence. An idea-route PRD folder
gets none. `/create-ard` and `/specify` both know how to read that foundation — they open
`grounding/code-grounding.md` and `grounding/design-grounding.md`, handle each file being absent,
and stamp `consumed_by` back onto what they drew on — but every one of those reads is gated on the
folder carrying `brd-link.md`. **The consumers already exist and are merely route-gated.**

What the idea route has instead is `/idea --ground-code`, and it is a different thing on purpose.
`code-scanner` answers *what capability exists for this theme?* — a broad sweep useful for scoping.
Grounding answers *is this specific claim true of this specific commit?* and adjudicates it. The
first is not a weaker version of the second; `grounding-format` §1 separates them explicitly, and
`idea-format` §7's *Feasibility grounding* section carries the scan's output with no `[CG#n]`, no
verifier and no pinned finding record.

**The blocker is that grounding needs claims, and an idea has none.** `idea.md` states a problem, a
value hypothesis, rough scope ("*What*, not *how*"), demand evidence and open questions. It carries
no identifier of any kind. There is nothing in it shaped like a `[BR#n]` — a stated requirement whose
premise can be true or false of a commit.

## 2. Decision

**Idea-route grounding runs after `/create-prd`, and its claims are the PRD's own requirement rows.**
One command serves both routes, its route detected from the resolved folder and never declared. The
engine — repository resolution, commit pinning, the `code-grounder` fan-out, `design-grounder`,
`grounding-verifier`'s independent re-derivation, horizons, the write and the handoff — is one run.
Only Phase 0 forks, on which file the claim list is read from and which gates guard it.

**The rule underneath is one rule, not two: ground the artifact that is authoritative for
requirements on that route.** On the BRD route that is the customer's own inventory. The PRD there is
derived from those rows plus signed `[CD#n]` decisions, so grounding the derivation would add grain
without adding truth — and it would falsify our paraphrase of the customer's ask while leaving a false
premise in their own document unchecked. On the idea route nothing upstream is authoritative, so the
PRD is.

**The BRD route does not move**, and the reason is a hard dependency rather than caution. Three
shipped gates close a cycle: `/create-prd` refuses a slice with any claimed row still `unallocated`
(`CREATE_PRD_BRD_UNALLOCATED`) and one with no `covered-here` row (`CREATE_PRD_BRD_NOT_ELIGIBLE`);
the only writer of `covered-here` is `/brd-split`'s `allocate-only` walk; and that walk's Phase 0
steps 6 and 7 — which run in `allocate-only` only — gate it on grounding being on main, non-empty
and carrying a verifier outcome for every finding. PRD depends on allocation, allocation depends on
grounding. Moving grounding after the PRD closes the loop, and cutting it open means deleting either
`/brd-split`'s grounding gate — which is BRD-1, reported by the operator and closed on 2026-09-06
precisely because it was too weak — or `/create-prd`'s ledger gates, after which a PRD claims rows
its slice may still defer.

**One pass per route.** A BRD-route slice is not ground a second time over its own PRD's rows. Its
acceptance criteria are finer-grained than any `[BR#n]` and stay unground, and this design says so
rather than leaving it to be discovered: a second pass would put two claim vocabularies in one id
space, make `/brd-split`'s `[CG#n]` count mix them, and re-derive near-identical findings over rows
the customer's inventory already stated — which is BRD-5, the waste the operator reported as a
defect. Re-running on the BRD route re-grounds `[BR#n]` rows, which is already sanctioned: `/brd-split`
Phase 7 offers exactly that when a sibling re-cut hands a slice a new row.

## 3. The claim source

**`[AC#n]` and `[FR#n]`, plus a `[US#n]` only where its story carries no acceptance criterion.**

`prd-format` puts `[AC#N]` under each story and requires it to be externally-observable pass/fail,
which is the shape a commit can satisfy or falsify. `[FR#N]` exists on the `--full` profile carrying
*Implements: `[UC#n]`/`[US#n]`* and adds capability rather than paraphrasing, so it is a distinct
claim rather than a second spelling of one. A `[US#n]` is reached through its own acceptance
criteria; grounding both would ground one capability twice, so a story contributes a claim of its own
**only** where it carries none — which keeps a PRD that skipped acceptance criteria from
contributing nothing at all.

**Three prefixes are excluded, and the exclusion is reported with counts rather than merely applied.**
`[UC#n]` is a narrative journey whose evidence is a list of sites rather than an anchor, which is
where a plausible-but-adjacent finding hides most easily. `[SM#n]` and `[SMC#n]` are
measurable, technology-agnostic **outcomes** — no commit satisfies or falsifies one, and grounding
one returns evidence about whether the metric is *instrumented*, a claim adjacent to the one the row
states. Adjacency is the named failure `grounding-format` §1 exists to prevent. The run therefore
reports what it ground **and what it did not**, by count and prefix, so a later reader cannot
conclude the PRD was fully ground.

**Zero claims is a stop, not a quiet completion**, for the reason `/brd-ground` step 8 already
records. A `--lean` PRD with no `[AC#n]` and no `[FR#n]` writes no finding, so it hands nothing off,
so a folder is left whose grounding file exists and is empty — which reads as *checked, nothing
found*. Stop with `PRD_GROUND_NO_CLAIMS`, naming `/update-prd` as the fix and never `/create-prd`,
which would rewrite the PRD rather than add acceptance criteria to it.

## 4. The rename, and the rule that bounds it

**`/brd-ground` becomes `/prd-ground`.** It refuses a root outright (`BRD_GROUND_ROOT_LEVEL`) and runs
only on a slice, and a slice is a `PRD-` folder — so it has never ground a BRD on any route since
slice-first shipped. After this design it runs on an idea-route PRD folder with no BRD anywhere in
its ancestry, where `brd-` is not merely imprecise but false.

**The rename is taken now because nothing has published.** `product-workflows` does not exist on
`origin/main` at all; what is published is the pre-split `/dev-workflows:brd-ground`. Every command
in this plugin is already acquiring a new fully-qualified name in this unreleased increment, so the
rename costs installed users nothing extra. After the release it would be a breaking change against
a name people had learned.

**Exactly one command renames, and the rule says why.** Four of the six route commands refuse a root
— `/brd-ground`, `/brd-interview`, `/brd-package` and `/brd-reconcile` each stop with their own
`*_ROOT_LEVEL` — so "runs on a slice" would rename three more, and that is the wrong test. **`brd-`
names the route, not the folder kind.** Interviewing, packaging and reconciling exist only because a
customer handed over a BRD; the slice they run on is a slice *of* one, and none of them will ever run
anywhere else. `/brd-intake` and `/brd-split` are route commands that genuinely run at root.
`/prd-ground` is the only one of the six that **leaves the route**, and that is what earns it a new
name. Writing this rule down is part of the deliverable: without it, the next reader renames three
more commands on the slice argument.

**Nothing else renames.** `code-grounder`, `design-grounder`, `grounding-verifier`, `grounding/`,
`code-grounding.md`, `design-grounding.md` and `baselines.md` are already route-neutral;
`brd-link.md`, `coverage-ledger.md`, `slices.md`, `brd/` and `brd-reader` stay because they *are*
BRD-route artifacts.

**The rename makes this a major version.** `product-workflows` goes to 3.0.0 — a removed command name
is breaking however unpublished the plugin is, and the version is the one place a reader looks to
find out. `workflows-core` takes a minor bump for the shared references this touches. Both manifests
carry the change in `plugin.json` and in the `marketplace.json` entry, which
`scripts/validate-catalog.py` asserts agree.

## 5. Phase 0 — route detection and the idea branch

**The route is detected by positive evidence in both directions.** After `resolve-address`, a `BRD-`
folder is refused as today. A `PRD-` folder carrying `brd-link.md` is the BRD route and every existing
step applies unchanged. A `PRD-` folder without one is the idea route.

**An `EPIC-` folder is refused, and this design adds that refusal rather than inheriting it.**
`resolve-address` searches every level `workflows-core:addressing` §3 bounds, so an Epic key resolves
to a folder — and an Epic folder holds no `prd.md`, because §2's tree places it one level up. Today
that case is unreachable in practice because the BRD route never produces an Epic key to ground;
after this design a claim list is built from `prd.md`, so an unrefused Epic folder would fail
somewhere downstream with a message about a missing file rather than about the wrong altitude.
Grounding is PRD-altitude on both routes; refuse by directory prefix, the same test §5 already uses
for `BRD-`.

**The legacy unprefixed fallback needs its own split.** Today a folder resolved through
`workflows-core:addressing` §5 with no `coverage-ledger.md` and no `brd/brd-inventory.md` reads as an
interrupted intake; after this design it could equally be a legacy idea-route PRD folder. That branch
splits on `prd.md` being present and asserting `kind: prd` — positive evidence each way, never the
absence of a file, which is the rule `coverage-ledger-format` §5.1 already fixes for the root
question.

**`prd.md` is gated with `require-on-main`**, for the reason the BRD route gates its inventory: a
claim list read off an unmerged artifact produces a finding set nothing downstream can reproduce.

**Every ledger-shaped stop stays BRD-route-only.** There is no `coverage-ledger.md`, no
`brd/brd-inventory.md` and no `parent:` on this route, so none of `BRD_GROUND_NEEDS_SPLIT`,
`NO_INVENTORY`, `EMPTY_INVENTORY` or the row-F branches is reachable — and the idea branch must not
borrow their messages, the same discipline the file already applies where it says row F needs its own
two-branch stop and must not borrow step 8's.

**Horizons collapse to one value, and the flag that produces the other is refused.** A `will-change`
horizon names a prerequisite's **frozen** `status: decided` record. The idea route has no decision
register anywhere, so there is nothing to freeze and every finding is `current`. `--depends-on` is
refused with a stop rather than accepted and quietly ignored: a documented flag with no effect is
R-4's shape.

**The other flags carry over unchanged.** `--no-code`, `--no-design`, `--rebaseline`,
`--derivation-matrix`/`--no-derivation-matrix`, `--no-docs` and `--docs <path>` all mean on this
route what they mean on the other, including their existing refusal combinations.

## 6. Design grounding on the idea route

**`[DG#n]` ships on this route in the same increment**, and the marginal cost is one agent's contract
rather than a new mechanism. A class 1, 2 or 3 `[DG#n]` is settled from the frame set and the
requirement text alone and is pinned to no commit (`grounding-format` §2); a class 4 cites a `[CG#n]`
and inherits its commit. What `design-grounder` needs beyond the frames is the **inventory**, and this
design is already building one.

**The claim list is the inventory, which is what makes class 1 provable.** A class-1 finding asserts
*the frame shows X and no requirement asks for X* — a negative over the whole inventory. BRD-4 was
that dispatch arriving without one, and the verifier correctly returning `NOT-PROVABLE`. On this route
the inventory arrives by construction.

**The frames are the idea's own source images.** `/idea` Phase 4.5 copies the images it actually read
into `<PRD-folder>/design/idea-sources/` and writes the mandatory §6.2 index, so a class-1 finding here
reads *this mockup shows a screen no `[AC#n]` asks for* — a reconciliation available before
`/create-ard` and available on no other route.

**A folder with no `design/` at all is the common case, and the file is still written.**
`design-grounding.md` is written on every run, carrying the note that the pass was skipped and why plus
the `## Frame sets covered` census — never omitted. `/create-ard` and `/specify` both report *which of
the four grounding inputs were absent*, and absent must keep meaning *the file is not there*, never
*the pass was declined*.

## 7. What comes back to the PRD

**A `SUPPORTED` verdict on an `[AC#n]` means the PRD asks for something the code already does.** The
run **reports** it — by id, with counts — and offers `/update-prd`. It never edits `prd.md`.

**Three reasons it never edits.** `prd.md` has exactly two writers, `/create-prd` and `/update-prd`,
both gated by `prd-reviewer@Opus`, and `/update-prd` archives the prior revision before writing the
new one; a grounding run has neither gate nor archive step, so it would be a third ungated writer of a
strictly-formatted artifact. And the BRD route already answers the same question the other way: a
`SUPPORTED` `[BR#n]` does not auto-disposition the ledger — it goes to `/brd-interview`, where a human
decides with the operator. Grounding adjudicates a claim; it never decides what to do about it.

**`/update-prd` learns to read `grounding/` and to stamp `consumed_by: PRD`** on the findings it drew
on, exactly as `/create-ard` and `/specify` already stamp theirs. This gives that enum value its first
writer anywhere in the tree: `consumed_by` has always admitted `PRD | ARD | specification | none`, and
`/create-prd` reads no `grounding/` file on either route, so nothing has ever written `PRD`. Without
the stamp, every PRD-altitude finding stays `none` for the life of the folder and the unconsumed
report cannot distinguish *nobody acted* from *acted, never recorded* — which is the ambiguity the
field exists to remove.

## 8. How grounding directs the downstream scans

**`/create-ard` and `/specify` each run their own `code-scanner` fan-out, and neither is replaced.**
The two answer different questions and the plugin already treats that difference as load-bearing:
`code-scanner` answers *what capability exists for this theme?*, grounding answers *is this claim true
of this commit?*, and `/create-ard` rests a whole refusal on the distinction — it may not reopen a
`[VD#n]` because "the architect-driven scan in Phase 3 is `code-scanner` output, which
`workflows-core:grounding-format` §1 says is a capability inventory and explicitly **not** a finding."

**What changes is where those two derive their themes from when verified grounding is present.**
On the BRD route `/specify` already does this: it extracts capability themes from `spec-seed.md`, the
implementation-altitude `decided` statements and the derivation-matrix rows, and those feed its repo
derivation and its `code-scanner` dispatches **in place of** the PRD-derived themes. An idea-route
folder has no seed files, so without a rule here both commands would read the `[CG#n]` set and then
scan as though it did not exist — two agents re-deriving, on a cheaper model and with no verifier,
what a verified corpus already settled.

**The rule: where the resolved folder holds verified grounding, each command seeds its theme set from
the findings before falling back to its own derivation.** A `[CG#n]` whose verdict says a capability is
absent is a theme worth scanning — that is where the work is. One whose verdict says it is present,
verified, names the code that already implements it, so the scan is directed at it rather than
searching for it. The fallback is unchanged and is what runs when no grounding is present, which stays
the ordinary idea-route case.

**This is the shipped pattern, not a new one.** `workflows-core:model-routing/classification` §8.5's
seeded second round already establishes that a scan narrowed by verified anchors beats a scan run
again from scratch, and `/specify`'s own BRD-route theme extraction is the same move from the same
inputs. Neither command's scan becomes conditional and neither gains a flag: the seeding is an input
change, so a folder with no grounding behaves exactly as it does today.

## 9. When it is worth running, stated because optional is not the same as always

Grounding on this route is optional and nothing gates on it, so the design owes an operator the signal
rather than leaving them to discover it after paying.

**It earns its cost where the PRD describes an existing product being extended.** There, the
high-value outcome is common: an `[AC#n]` the code already satisfies is scope that does not need
building, and a premise the code contradicts is a requirement that would have been built on sand.
Both are found before an architecture is authored against them.

**It earns little on a greenfield PRD.** Where nothing described exists yet, every finding is a
verified absence — true, and low-information — and each one still costs an independent Opus
re-derivation. The operator's own BRD-route corpora ran to 142 findings in a single slice; the same
volume of confirmed absences buys almost nothing.

**The run says so rather than only reporting.** Where every claim comes back a verified absence, the
final report says that outright — that this PRD is greenfield against the repositories resolved, which
is itself a finding worth having once — instead of presenting a wall of absences as though they were
a mixed result. A second run over the same greenfield folder is the one this guidance exists to
prevent.

## 10. The handoff

**The branch prefix is `prd/` on the idea route and `brd/` on the BRD route**, chosen at the call
site, which already passes `prefix:` explicitly. The eight-prefix branch authority in
`workflows-core:specs-repo-git` §1 and `workflows-core:phase-handoff` §1 rule 3 is unchanged, and no
ninth prefix is added. Sharing is already the norm — `prd/` is `/create-prd`'s and `/update-prd`'s,
`brd/` is the route's six — and a collision is unreachable in the sanctioned flow, because this run
gates `prd.md` with `require-on-main` and therefore only proceeds once `/create-prd`'s branch has
merged.

**`deliverable_paths` on the idea route are the grounding artifacts** — `grounding/code-grounding.md`,
`grounding/design-grounding.md`, `grounding/baselines.md` — and no BRD-route file, since none exists.

**The next-step offer forks with the route, and both branches carry the `<merge-clause>` placeholder.**
On the BRD route the offer is `/brd-split` as today. On the idea route it is `/create-ard` and
`/specify` — the two consumers of what this run just wrote — with `/update-prd` named **first** where
any claim came back `SUPPORTED`, since a PRD asking for something the code already does is worth
revising before an architecture is authored against it. Every one of those offers names a command
whose `require-on-main` gate targets a path this run writes, which is exactly the relation the
placeholder exists for and exactly what check 11 gates — see §13.

## 11. Out of scope, stated so a reader does not reintroduce them

- **The BRD route's grounding position, claim source and gates.** Settled in §2 against a cycle, not a
  preference.
- **A second, post-PRD grounding pass on the BRD route.** Its PRD's acceptance criteria stay unground.
- **`/create-prd` reading grounding.** It reads none on either route; on this one grounding runs after
  it.
- **`/epics` reading grounding.** It reads none on either route today and this design does not change
  that.
- **`/idea --ground-code` becoming grounding.** It stays a `code-scanner` scoping sweep with no
  `[CG#n]` and no verifier. `idea-format` §7 keeps its name and gains one sentence pointing at the
  verified pass downstream, so the two are not confused.
- **Grounding becoming mandatory on the idea route.** Nothing gates on it; `/create-ard` and
  `/specify` keep their absent branches unchanged.
- **Renaming any other `/brd-*` command**, per §4's rule.
- **Replacing `/create-ard`'s or `/specify`'s `code-scanner` fan-out with grounding.** §8 seeds their
  themes from the findings; it does not make either scan conditional, optional or removable. The two
  answer different questions, and a command that stopped scoping because something else adjudicated
  would cover only what the PRD's rows happened to claim.

## 12. The sweep

Three kinds, and per `CLAUDE.md`'s own bullet the sweep is scoped to `plugins/` rather than to the
shipping plugin, backed by an end-to-end read of every phase the change touches, run with an
exclusivity probe (`only when`, `is the only`, `nothing else`, `and no other`, `only ever`) as its own
axis, and each phrase hit dispositions its whole paragraph rather than the matched sentence.

**(a) The rename.** Re-derive every count against the tree rather than copying these:
`grep -r 'brd-ground' plugins/ scripts/ CLAUDE.md | grep -v CHANGELOG` and
`grep -rho 'BRD_GROUND_[A-Z_]*' plugins/ | sort -u` are the two recipes. It reaches the command file
and its docs page, the stop codes other commands quote in their own stops, both manifest
descriptions (1024-char cap, and a change **replaces** wording rather than appending),
`workflows-core/scripts/command-namespaces.json`, `workflows-core:cost-emission` §7's row (gated by
check 8), `workflows-core:docs-grounding`'s consumer list, `workflows-core:next-phase-offer`,
`workflows-core:phase-handoff`, `workflows-core:grounding-format`,
`product-workflows:coverage-ledger-format`, the three `dev-workflows` docs pages that name it
cross-plugin, and `CLAUDE.md`. Check 15 asserts a command's membership in `docs/README.md`, the plugin
README **and** `docs/workflow.md`'s mermaid diagram separately, so all three move.

**(b) The claims design grounding falsifies.** `workflows-core:grounding-format` §6.1 forecloses
idea-route `[DG#n]` outright, one paragraph of which states that a `/idea`-route `design/` folder is
"a known and deliberate state, not a gap", and another that the capability "remains deliberately
unbuilt on every other route". `/idea` Phase 4.5 carries one of its own, asserting that writing an
index "does not mean `/idea` design grounding has shipped". Derive the set rather than counting it
here — `grep -n 'NOT shipped\|deliberately unbuilt\|not a gap\|has shipped' plugins/` finds them,
and §6.1's own writer-versus-consumer paragraph must be read alongside even though it forecloses
nothing itself, because it is the one that fixes what "consuming" means. Each is rewritten against
what ships, read out of its own phase rather than assumed — and a sentence that named the absence as
its *reason* for something needs a new reason, not a deletion.

**(c) The route-gated reads, and the theme derivation beside them.** `/create-ard` and `/specify` gate
their grounding reads on the BRD route in their Phase 0 confirm lines, their Phase 2 reads, their
`consumed_by` stamping and their `deliverable_paths` staging alike. Each becomes "wherever the folder
holds `grounding/`". §8's seeding lands in the same two files but in a different phase — `/specify`'s
theme extraction and `/create-ard`'s Phase 3 scan scoping — so it is swept for separately rather than
assumed to travel with the read: the read and the derivation are adjacent in the file and independent
in effect, which is exactly the adjacency a phrase sweep walks past. The
BRD-route-specific exclusions those two apply — the baseline findings, and the findings a re-cut
leaves behind on a slice whose ledger now shows the row `covered-by` — are unchanged: the first
applies on both routes, the second has no subject on the idea route and is reported as an empty set
rather than as an unrun check.

**The diagram.** `product-workflows/docs/workflow.md`'s mermaid moves `/prd-ground` out of the BRD
subgraph into one of its own, reached from both routes with the claim source on the edge label —
solid from `/brd-split (root)` because grounding is required before the `allocate-only` walk, dotted
from `/create-prd` because it is optional on the idea route.

## 13. Risks

**The rename takes a gate with it, silently.** `check-docs.sh` check 11 derives the command family
from a single `product-workflows:brd-*` glob in `next-phase-offer.md`'s scope paragraph, and checks
only offers made by a command matching it. `/prd-ground` leaving that glob is *correct* under §4's
rule and removes its offers from the gate — while five commands still match, so `route_n > 0` and the
build stays green. This is the one item in the sweep that a sweep cannot fix: it has to be designed.
The scope paragraph already names six non-glob commands individually, so the shape of the answer
exists; what does not is a parser that reads more than one family.

**The sweep's blind spot is the one gate 2 paid for.** Three `dev-workflows` docs pages name
`/brd-ground`, and a grep scoped to `product-workflows` cannot see them — the same structural blindness
that let two Important findings reach gate 2's final review.

**Widening the wording is not widening the contract.** `code-grounder` and `grounding-verifier` each
name `[BR#n]` a handful of times — `grep -c 'BR#' plugins/product-workflows/agents/*grounder*.md
plugins/product-workflows/agents/grounding-verifier.md` gives the live figures — in prose *and* in
their output templates. An agent told its claims
are "requirement rows" while still shown a `[BR#n]`-shaped example will keep producing `[BR#n]`-shaped
claims — which is BRD-6's shape, where fixing a file's writer left the defect intact one hop upstream
in the agent whose template the model actually copied.

**Two claim vocabularies now exist in one engine, and a reader may conflate them.** A `[CG#n]` in a
BRD-route folder cites a `[BR#n]`; one in an idea-route folder cites an `[AC#n]` or `[FR#n]`. Nothing
in the finding record says which route produced it, and nothing needs to — but any consumer that
pattern-matches a claim's prefix rather than resolving it against the claim list it was handed is
wrong on one of the two routes. That is this repo's own *resolve against a known set, never parse one
out of free text* rule, arriving in a new place.
