# Changelog

All notable changes to the **dev-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [3.20.1] — 2026-09-01

### Fixed — `/frames` asked for consent on a promise it then contradicted

`/frames` presents `phase-handoff.md` §4.3's consent array verbatim, whose second option reads *"Just
write the files — I'll handle git (the next phase will stop until this is on main)"*. §4.3 declares that
parenthetical **load-bearing** — "the only place the user learns that declining has a downstream cost."
For a frame-set index there is no such cost: nothing consumes it, `§3.4`'s table names no row for it,
and `/frames` says so itself. So the operator was told to expect a refusal that cannot happen, and the
run then **contradicted its own prompt** — §4.1's third `<next-phase-clause>`, added for exactly this
case, correctly reports that nothing downstream reads it.

The asymmetry is the giveaway: §4.1 was carefully given three clause variants and argues why ("printing
the stop clause on a seam that does not stop tells the operator to expect a refusal they will not
meet"), while §4.3 — the array shown *before* the decision, where it actually matters — had one. §4.3
now carries a **no-§3.4-row variant** differing only in that parenthetical, and `/frames` cites it. Still
three options, so the `AskUserQuestion` arity rule is unaffected; the thirteen producers that inline the
default array are untouched.

**Also:** `/update-prd` emitted `UPDATE_VI_NEEDS_KEY` — "Value Increment", the retired vocabulary —
while its own sibling stop is `UPDATE_PRD_NO_PRD` and every other command uses `<COMMAND>_NEEDS_KEY`.
The command and its docs page agreed with each other and were both wrong. Renamed.

## [3.20.0] — 2026-09-01

Four-dimension review of 3.18.0 and 3.19.0 (`/idea`'s vendoring and `/frames`), fixed in full —
plus the two gate holes the review found by mutating the gates themselves.

### Fixed — `/idea` vendoring: the policy was specified, the mechanism was not

- **Nothing bound `idea.md`'s links to the rewrite map's keys.** The map was keyed on the target
  *as written in the source*, while `idea-format.md` Section 5 told the author to cite a linked image
  *by path* — and `images[].path` is absolute. A brief citing a source the way its own format
  document said to would match no key, rewrite nothing, and land on the default branch pointing at
  one operator's disk, beside vendored copies nothing referenced. **Both forms are now keys** of the
  map — the written `target` and the resolved absolute `path`, both already in the digest — and
  Section 5 says so from the authoring side. A resolved path names exactly one file, so a bullet that
  cited a path is never ambiguous.
- **A `.md` page reached only by a standard markdown link was followed by nothing, copied by nothing
  and reported by nothing.** The traversal followed `[[wikilinks]]` only, and `links_other[]`
  excludes `.md` by construction — so the page fell into no array at all, which is exactly the state
  "a link nothing copied and nothing reported is indistinguishable from a link that was never there"
  forbids. Two documents meanwhile published a rewrite row for precisely that case, unreachable.
  **`idea-reader` now follows both syntaxes**; a source written outside a vault uses the second.
- **A re-run over an *edited* source left an orphan and a stale link.** The collision rule minted
  `notes_01.md` for the changed content, while `idea.md` still pointed at `notes.md` — the copy
  committed and unreferenced, the link committed and wrong, repeating every run. A copy is a mirror
  of its source, not a version history, so an edited source now **refreshes the copy it wrote before**
  — detected by the one condition only an earlier run of this command can produce: `idea.md` links
  that exact destination path. A name taken by something `idea.md` does not link is still a genuine
  second file and still takes a suffix.
- **Byte-identity was compared against the candidate name rather than the destination directory**, so
  a third run could mint `notes_02.md` as a twin of `notes_01.md`, and a fourth another — unbounded
  growth from the rule written to prevent it.
- **`deliverable_paths` was handed over short.** Phase 4.5 carried "the paths **written**"; Phase 5
  required "every file Phase 4.5 wrote **or reused**" and said to pass the list through unchanged. A
  reused copy from an earlier declined run therefore reached no ref, and `idea.md` landed linking it.
- **Phase 4.5 restated a rule it said it restated none of, and got it wrong**: it wrote the frame-set
  index "only where an image lands", while `grounding-format.md` §6.2 step 6 and `idea-format.md` both
  require it wherever the set is non-empty — which is how a row whose image was deleted gets dropped.
- **`## Prior art` could not be written at all.** It fires on `provenance: prd`, which Phase 1 cannot
  compute and nothing upgraded to; its "Discovered" bullet shape transcribed `relation` and
  `match_reason` from a prior-art finder deleted two releases ago; and it read `tracked_status`, a
  field the producer emits on a *different* array. `idea-reader` now tags a source carrying
  `kind: prd` as `prd` and fills `tracked` from its own frontmatter, the dead shape is gone with its
  reason recorded, and the remaining slots name fields that exist.
- **Two consumers with no producer**: `area_proposal` and `prior_art_challenges`, both left behind by
  the same deletion. Phase 2.5 dispatches one grounding agent, not two.
- **Phase 4's "Create a new one" offer produced a permanently ambiguous tree.** The key is fixed in
  Phase 0, so a second brief under a different slug is a second folder asserting the same key —
  `addressing.md` §4 rule 5's hard stop, which makes the key unaddressable by every command that
  resolves one, including the `/create-prd <KEY>` the same run goes on to recommend. The option is
  removed; a separate idea is a separate key, and the phase says so.
- **Link anchors were undefined end to end.** `[[notes#Rollout]]` would have keyed on the anchor and
  matched nothing, or dropped it silently. An anchor is now split off before matching and re-appended
  verbatim.
- **Percent-encoding covered the space and not the parentheses**, so a frame named `Screenshot (1).png`
  produced a markdown link terminating at the first `)` — nothing, in a rewrite whose whole purpose is
  a link that resolves.
- Smaller, same family: `attachments/` was described as taking "text and markdown" when markdown is
  all the reader opens, and a linked `.txt` was reported as "neither text/markdown nor an image",
  which is false about that file — it is a file nothing read; `wikilinks_broken[]` was claimed by two
  files to carry a `target:` field its schema did not define (it does now); Phase 1's gate cited a
  "precedence rule 3" in a two-rule list; and `provenance_hint` was passed a five-value vocabulary of
  which Phase 1 can compute two.

### Fixed — `/frames`: refusals a reference asserted and the command did not implement

- **The kind refusal `cost-emission.md` relies on did not exist.** Passing no `<KIND>` is right for a
  command whose subject is reserved at every level, but it also disables the only guard the `@<path>`
  branch has — so `@<path>` to a *frame*, the form the docs page teaches, resolved to the frame-set
  directory, whose `index.md` asserts `kind: frame-set-index`. The run then looked for `design/`
  inside a frame set, reported "no design/ subdirectory" about a directory holding eleven frames, and
  reached a cost branch the reference declares unreachable. There is now a fourth-kind stop.
- **Two writers of one index listed by two image vocabularies** — eight extensions here, six in
  `idea-reader` — so each would drop the other's rows at §6.2 step 5 as frames that had gone missing,
  while the files sat in the directory. The set is now defined **once**, in §6.2, as the extensions a
  reader can actually open; a permanently unreadable frame would otherwise hold a placeholder that
  rejoins the describe set on every run and defeats convergence.
- **The clean re-run dispatched an agent to manufacture a failure.** With every description already on
  record the describe set is empty, `frame-describer` refuses an empty list with `INPUT_MISSING`, and
  the run reported a set as "stopped" while it was complete and correct. Same for every set after the
  one the cap fell in. An empty describe set now dispatches nothing.
- **`NO_INDEX` named no way out at either place a human meets it.** `/brd-ground` skips a set in
  Phase 5 and hard-stops in Phase 7, and neither named `/frames` — the command built to repair
  exactly that, shipped with no route to it. Both now name it, the Phase 7 stop as the fourth part of
  its stop contract, and §6.1 names it at the refusal itself.
- **`/frames` wrote no `resume.md` and appeared on neither list of the runs that skip one**, while
  §1 calls the checkpoint unconditional for PRD-scoped runs and `/frames <PRD-KEY>` has the anchor.
  The skip list now carries it with the reason stated — indexing is a repair, not a phase anyone
  resumes — and the command states its exemption where `/vuln` states its own.
- **A declined handoff had no true `<next-phase-clause>`**: §4.1 offered "the next phase will stop"
  and "the next phase does not stop on that", and §3.4 has no row for a frame-set index because
  nothing consumes one. A third value now exists for an artifact with no consumer, and the command
  cites it instead of departing from the contract. The decline also now states the G1 consequence
  `/idea` documents for the identical state.
- Smaller: `deliverable_paths` demanded repo-relative paths from a list Phase 2 held in no stated
  form; `$SPECS_PATH` was never validated, so an unset variable surfaced as a key-resolution failure;
  a second address or an invented `--flag` was discarded in silence; images dropped directly into
  `design/` — the near-miss of the gesture the command exists for — got a message naming no fix; and
  the Epic-scoped command enumerations in `specs-repo-git.md` did not list it.

### Fixed — enumerations no script gates

`/frames` is the 21st `model-routing` loader, the 11th row of `addressing.md` §7's adopter table and
the 28th documentation page. Every prose restatement of those was off by one: the skill's own
frontmatter and `docs/reference/model-routing.md` said twenty, `docs/reference/references.md` said
fourteen, `CLAUDE.md`'s loader/exempt partition accounted for 27 of 28 commands, and its docs-tree
sentence said 42 pages and 27 command pages. Where a count restated another file's list, it is now a
citation instead — which is what that section's own instruction always said. Also: `CLAUDE.md` drew
the deprecated unprefixed folder its own §2 rule forbids, described `/ready` as read-only for a
*tracker* status it never reads, and mapped `/idea`'s handoff as one file; `docs/brd-workflow.md`'s
tree comment said `attachments/` is "PRD level only, never here" ten lines above the paragraph saying
both levels; and one CHANGELOG version boundary had no blank line before it.

### Fixed — documentation that contradicted the commands

- `/idea`'s page said a read image "needs no index file", sixty lines above the section describing the
  index it writes; the command said the same thing. An index makes a set readable, which is not the
  same as grounding it, and both now say that instead.
- `/idea`'s page promised **four** source forms and listed three, one of them twice, for a classifier
  with two branches; it omitted the `--docs` flag; and its prior-art bullet had lost the negation that
  made it true, asserting under "What it needs" that the command performs discovery it does not.
- `/frames`'s page omitted five behaviours the command has — the mandatory address, the
  create-nothing outcomes, the empty-set skip, the foreign index left alone with `index.md` written
  beside it, and what counts as a frame.
- `docs/reference/environment.md`'s PRD-folder tree listed neither `idea.md`, `attachments/` nor
  `design/`; `docs/workflow.md`'s diagram omitted `/frames` under a sentence promising every command.

### Fixed — `CLAUDE.md` described the plugin in a vocabulary the plugin no longer uses

The plugin reached **zero** unmarked tracker mentions some releases ago. `CLAUDE.md` — which
*describes* the plugin, and which check 13 did not scan — still held ten, and they were not
rationale but claims: `/ready` "read-only for Jira status" (the very defect check 13's own header
records as fixed, corrected in the README and left standing here), `doc-planner` "synthesizes Jira +
diffs" when its agent file says PRD content, `/update-prd` excluded from `require-on-main` because
"its base is the Jira import" when the command resolves a PRD from the specs tree, a written claim
required to cite "the originating Jira key", and six more. Every authority they cite —
`prose-formatting.md`, `doc-structure-conventions.md`, `diff-summarizer`, `release-notes-writer`,
`source-truth.md` — was already neutral; only the file describing them was not.

**Check 13's scope now includes `CLAUDE.md`.** A file outside the gate that describes the thing
inside it is how a constraint comes back, and this is the evidence for it rather than the argument.
The repo-root README stays out for its existing reason (it documents a sibling plugin whose subject
is a vendor CLI). Three lines that must name a tracker to explain a hazard — the two rationales for
the requirement-ID grammar and the pre-lint autolink detector, and check 13's own description
quoting the defects it removed — carry the marker instead, and the sanctioned census is re-derived
at 14 lines across 6 files in four kinds.

### Fixed — a gate direction, and an undefined read

- **Check 4's agent direction accepted a prose mention where a row was required.** A review replaced
  an agent's table row in `docs/reference/agents.md` with a sentence naming it, and the gate passed —
  the inventory table the page exists to be had silently lost a row. The reverse direction has been
  row-anchored since it was written; a pair that disagrees about what counts as listed catches
  phantoms and misses drop-outs, which is the half that actually goes wrong.
- **`design-grounder` had no rule for two indexes in one directory** — a state `grounding-format.md`
  §6.2 deliberately produces, by having a writer leave a foreign index alone and write `index.md`
  beside it. `index.md` is now stated as the one read, with the other reported and not read.
- `/frames` was the only command dispatching two or more subagents whose page carried no
  *How it runs* diagram.

### Added — two gates, because two constraints were held by nothing

- **Check 14 — foreign-identity quarantine, repo-wide.** The organisation this plugin was extracted
  from must be named nowhere in the repository. That was believed to be check 13's job and never was:
  a review appended those names to a documentation page and to `CLAUDE.md` and the gate passed both
  times — check 13's token set is trackers, and its scope stops at the plugin. The new check has no
  sanctioning marker, no exception, and reads every text file outside `.git`. **Its token list is
  stored base64-encoded**, for the reason that a denylist in clear text would itself put the names
  into the tree — the gate would be the only violation of the rule it enforces. It has zero live
  sites: the tree and its history are clean, and the check exists so that stays true by construction.
- **Check 15 — index membership.** Check 4 proves a command has a page and check 3 proves that page
  is reachable from *some* page; neither proves a reader can find it. A review deleted `/frames` from
  the docs index, the workflow diagram and the plugin README's role table, and the build stayed green.
  Every command must now appear in `docs/README.md`, in the plugin README, and inside
  `docs/workflow.md`'s **mermaid diagram** — asserted separately from the page, because prose below a
  diagram is where a command lands when someone adds it in a hurry. It caught the live defect on its
  first run.
- **`check-id-grammar.sh --selftest` now asserts which forms the gate named**, not only its exit code.
  Each negative fixture carries several violating lines, so any surviving alternation of `PATTERN`
  holds the exit at 1 — a review deleted both legacy counter-metric alternations, watched the selftest
  print PASS, and then watched the degraded gate accept a live violation in a shipped reference file.
  Verified by re-running that exact degradation against the hardened selftest, which now fails it.
- **`scripts/validate-catalog.py` has a `--selftest`**, its two siblings having had one for releases,
  and it is wired into the same workflow ahead of the run it guards.

## [3.19.0] — 2026-09-01

### Added — `/frames`: the recovery path for a frame set nothing could read

`references/grounding-format.md` §6.1 makes a frame set's index **mandatory and its absence
unrecoverable** — `design-grounder` returns `NO_INDEX` rather than reading a directory, because a
filename is not a reliable statement of what a frame shows. That requirement is right and it had no
recovery. The obvious workflow is a human exporting frames and dropping the folder into `design/`,
which produces a set the plugin refuses to read and no command could repair; 3.18.0 taught `/idea` to
write an index for the images *it* vendors, and nothing else wrote one.

**`/frames <KEY>|@<path>` (re)builds the index of every `design/*/` set of one resolved folder.** It
lists the images, reads the index already there, describes the frames no row accounts for, and writes
the index. **One address, any kind** — `design/` is reserved in BRD, PRD **and** Epic folders, so the
command calls `references/addressing.md`'s `resolve-address` with no `<KIND>`; narrowing it would
refuse two of the three. It creates no folder: an address resolving to nothing is a stop, and a folder
with no `design/` is a clean report that creates nothing, not even an empty directory.

**Name.** `/design-index` was considered and rejected: `/design` is the engineering-design workflow,
and an adjacent name invites an operator who wants indexing into the wrong command. *Frame set* and
*frame* are §6.1's own vocabulary.

**The boundary is stated in the command, in the docs page, and in §6.1.** Indexing makes frames
*readable*; grounding makes them `[DG#n]` findings. `/frames` dispatches no `design-grounder`,
produces no finding, cites no `[BR#n]` or `[CG#n]`, and never reaches `grounding-verifier`.
`/idea`-route design grounding remains deliberately unbuilt and §6.1 still says so.

### Changed — the frame-set index format moved to `grounding-format.md` §6.2, and both writers cite it

The format lived in `references/idea-format.md` because `/idea` was its only writer. With a second
writer that is two authorities for one format — the defect family this repo keeps paying for — so the
format, the frontmatter, the table shape, the `Linked from` semantics and the six-step reconciliation
contract are now **`references/grounding-format.md` §6.2**, beside the §6.1 requirement they satisfy.
`idea-format.md` keeps only what `/idea` contributes to a row (`idea-reader`'s `description`, the
digest's `linked_from`, the `idea-sources` set name) and cites §6.2 for the rest; `commands/idea.md`
Phase 4.5 step 3 cites it too and restates none of it. The former §6.2, *The four reconciliation
classes*, is now §6.3; nothing cited it by number.

**§6.2 carries one new rule, and it is what makes a capped or failed run recoverable.** Step 2
preserves an existing row verbatim *because* a run cannot reproduce a description it never received —
so a row whose description is step 4's literal `_no description on record_` holds no description to
preserve, and a writer that **can** obtain one replaces it instead of preserving it. Without that
exception the placeholder would be permanent and every cap would be a frame nothing could ever
describe. `/idea` still cannot obtain one and still leaves such a row exactly as it stands.

### Added — the `frame-describer` agent (37 → 38)

A bounded read returning a structured result, the plugin's own idiom: it is handed a frame set
directory and an explicit list of basenames, looks at each one, and returns a plain-language
description per frame. **Inline was the alternative and it was worse on three counts.** Forty images
is the most context-expensive read this plugin does and it belongs outside the orchestrator's window;
describing a picture is detection work that should run on the Sonnet chain while the orchestrator
stays on its own tier; and separating the looker from the writer makes "transcribed, never inferred"
**structural** — the orchestrator never sees an image, so it cannot describe one from a filename,
which is the exact inference §6.1 exists to forbid. The agent reads only the basenames it was handed
(the cap lives in the caller), emits no finding, no verdict, no id and no citation, and never opens an
index, a requirements document, or any code.

### Added — a cap of 40 frames per run, and an index that is valid whether or not it bites

`/idea` caps at 6 images because reading a mockup is incidental to writing a brief. `/frames` is
invoked *to* index, so 6 would make it useless on the first real export it met; 40 is the size of a
feature's screen flow as humans actually export one, counted across every set a run touches.

**When it bites, the set still ends in a valid, complete index.** §6.2 resolves every row before
writing the file once, so every frame in the listing carries a row: the ones past the budget carry
`_no description on record_` with `cap` as the reported reason. Because §6.2 step 2's new exception
treats that placeholder as a row to be filled rather than preserved, the next run describes the next
40 and the set converges — a 45-frame set is two runs, a 100-frame set three, and it is readable after
the first. A half-written index is not a state this command can reach.

### Added — the eighth branch prefix, and the handoff that makes the indexes real

The indexes are deliverables, so `/frames` calls `handoff-to-main` with `deliverable_paths` naming
**every `index.md` it wrote, one literal path each** — never a directory and never a glob
(`references/phase-handoff.md` §2.3). An index left out of that list is classified OTHER, never
staged, and never reaches the default branch, leaving the set `NO_INDEX` for everybody but the
operator who ran the command. That required an eighth branch prefix, `frames`, at **every** site
that enumerates the set: `references/specs-repo-git.md` §1 rule 3 / §2.2 / §3.3 G2 / §3.5
`branch-key` / §4.1 / §5's G2 notice, `references/phase-handoff.md` §1 rule 3 / §2.9 / §3.2,
`CLAUDE.md`, and `docs/reference/environment.md`. Declining the handoff is reported honestly: the indexes are on disk and on no ref, and
`/brd-ground` reads a frame set from the working tree, so a decline is an unshared repair rather than
a blocked grounding pass. No offer carries a `<merge-clause>` — nothing runs `require-on-main` on a
frame-set index, and `references/next-phase-offer.md` now says so in place.

### Added — cost attribution for `/frames`, inferred from the resolved folder's kind

Describing 40 frames is real spend, and a run that measured nothing would not be free — per
`references/cost-emission.md` §3 it would roll into whatever command ran next. `/frames` therefore
emits, as the sixth inferred exception in §7, with a discriminator that is re-derivable from disk like
`/release-notes`'s: the resolved folder's own `kind`. `brd` attributes the run to `brd-to-prd`/`pm`,
`prd` and `epic` to `prd-creation`/`pm`. **No new phase was invented** — the eleven in
`docs/roles-and-phases.md` are unchanged.

### Fixed — a stale caller count in `feedback-emission.md`

`### emit-auto — automatic callers (the thirteen commands' maintenance phases)` had said *thirteen*
since long before the count was nineteen; its own opening paragraph said *nineteen* four lines above.
Both now say **twenty**, and `docs/reference/session-feedback.md`'s parenthetical — which derived the
same stale thirteen from "the fourteen `model-routing` pipeline commands minus `/docs-profile`" — is
replaced by a rule that can be checked against the tree.

### Fixed — the eighth branch prefix reached three sites it had missed

The `frames` prefix was added to `specs-repo-git.md`'s §1 rule 3, §2.2 and §4.1 and skipped its three
remaining enumerations, each of which does real work.

**§3.5 `branch-key` step 1** stripped seven prefixes and not `frames/`, so a `frames/<KEY>-<slug>`
branch fell to *no prefix matches → not a plugin branch* and resolved to no key. The consequence sits
one file over: `references/phase-handoff.md` §2.2 **rule 3** calls `branch-key` by name to recognise a
run's own in-progress branch, so it could never recognise one for `/frames`, and **rule 4 fired
instead — a second branch suffixed `-2` and a second pull request, the first orphaned**. The 40-frame
cap makes a re-run over one folder the ordinary path (100 frames is three runs), so this was the
common case, not the edge.

**§3.3 guard G2** omitted `frames` from its alternation, and any guard match ends the preflight. So
whenever `$SPECS_PATH` sat on a `frames/` branch, *every* command's preflight stopped at stage 1: the
leftover-artifact flush, the failed-push retry and the branch disposition were all skipped, and a
non-`/frames` run stayed on the frames branch and committed its artifacts there instead of switching
to the default branch per B4.

**§5's G2 operator notice** still listed seven prefixes, telling the operator a `frames/` branch was
one "this plugin did not create" — false, and it misdirected the repair.

The same sweep found an eighth site outside `specs-repo-git.md`: `docs/reference/environment.md`'s
list of the specs-repo handoff branches that never enter the code-repo identity ladder. `CLAUDE.md`
and `phase-handoff.md` were already correct.

### Fixed — two documents that named the §6.2 step list they said they did not restate

`references/idea-format.md` and `commands/idea.md` Phase 4.5 step 3 each bolded a claim (*"this file
restates none of it"*, *"restated nowhere"*) and then re-enumerated all six `grounding-format.md` §6.2
steps in the next sentence, literal `_no description on record_` included — and re-enumerated them
**incompletely**, omitting step 2's placeholder exception and step 6's write-nothing-on-empty rule.
Not a second normative copy, but a second place a reader learns the list, already out of date on the
day it shipped. Both now name what §6.2 owns and send the reader there, matching the shape
`commands/frames.md` Phase 2 already used.

### Fixed — two counts that contradicted the tree

`docs/reference/session-cost.md` said *the ten cost-attribution phases* while
`docs/roles-and-phases.md` documents **eleven** (ten lifecycle phases plus `plugin-feedback`) and
ships eleven `###` sections; that page's own closing note about the unrelated `model-routing` `phase:`
vocabulary said *the ten phases above* for the same eleven. Both now say eleven.
`docs/commands/epics.md` said *the fourteen commands* that offer a branch + commit + push +
pull-request handoff and listed fourteen, omitting `/frames` — the producer set became fifteen in this
same release (`grep -l handoff-to-main commands/*.md` returns 15).

### Counts moved, in this commit

27 → 28 commands (`plugin.json`, `marketplace.json`, the repo-root `README.md`, the plugin `README.md`,
`CLAUDE.md`, and `scripts/check-docs.sh`'s check-9 word list and alternation, which had no
`twenty-eight`); 37 → 38 agents (`plugin.json`, `marketplace.json`, `CLAUDE.md`,
`docs/reference/agents.md` twice, plus its unpinned subtotal 25 → 26); 23 → 24 `commit-artifacts`
callers (`CLAUDE.md` three sentences, `references/specs-repo-git.md`, `commands/create-prd.md`);
14 → 15 `handoff-to-main` producers; 7 → 8 branch prefixes; 21 → 22 cost-emitting commands with 5 → 6
inferring; 19 → 20 `emit-auto` and `emit-cost` callers; and `references/addressing.md`'s §7 adopter
arithmetic from eleven files / eleven commands to twelve and twelve.

## [3.18.1] — 2026-09-01

### Fixed — three defects in 3.18.0's vendoring: an orphaning index, an unresolvable link map, and links that resolved nowhere

Review of 3.18.0 found three ways the new Phase 4.5 damages, or fails to repair, the record it exists to
protect. All three are fixed here, with three smaller inaccuracies beside them.

**The `design/idea-sources/` index orphaned every frame an earlier run vendored.** The frame set is one
per PRD folder and accumulates across runs, but the index was written "from the `description` of each
image **copied**" — this run's copies only. A second run that vendored one new image therefore rewrote
the index down to that one row, leaving run 1's frames sitting in an indexed directory that identified
none of them: `references/grounding-format.md` §6.1's own unrecoverable failure, reproduced at row
granularity and silently. Nor could a run repair it, because this run's digest holds no `description`
for a frame an earlier run vendored. Under the byte-identical-content rule it was worse again — an
idempotent re-run copies nothing, so "each image copied" was empty and the index resolved to no rows at
all. **The index is now rebuilt from the frame set as it stands on disk**: the directory is listed, every
existing row whose image is still there is preserved **verbatim**, rows for this run's copies are
appended, and it is written **whenever that listing is non-empty** rather than only when something was
copied. Two states the old rule never named are now stated and reported: a row whose image is gone is
dropped (an index must state what the set holds, not what it once held), and an image with no row and no
description in hand is given one carrying `_no description on record_` — omitting it would rebuild the
very defect, and inventing a description for it is the inference §6.1 forbids.

**Link rewriting had no way back from a link to the copy it belonged to.** `references/idea-format.md`
made the rewrite decision "the file the target **resolved to**, never the shape of the string" — correct,
and unimplementable, because neither copied list carried the target *as written*: `images[]` had
`path`/`linked_from` and `wikilinks_followed[]` had `path` alone, while `wikilinks_not_followed[]` and
`links_other[]` both carried `target:`. Phase 4.5 would have had to re-resolve every link, which
`commands/idea.md` forbids in the same breath. The concrete cost: two `toggle-01.png` in different
directories, copied as `toggle-01.png` and `toggle-01_01.png`, with nothing to stop a link being
repointed at the wrong frame. **`idea-reader` now returns `target:` on `images[]` and `wikilinks_followed[]`,
and `from:` on `wikilinks_followed[]`**, so every link array carries the written form beside the path it
resolved to; Phase 4.5 pairs them into a written-form → copy map and matches on it, re-resolving nothing.
Targets that merely *look* alike (`settings/toggle-01.png` vs `onboarding/toggle-01.png`) are distinct
keys and each reaches its own copy. Where two entries were written **identically** and reached different
files, `idea.md` records nothing per occurrence to separate them, so **neither is rewritten** and the
ambiguity is reported with each source and each copy — a link nobody else can follow is a poor record,
but a link pointing confidently at the wrong frame is a false one.

### Fixed — a rewritten link stayed a wikilink, so it resolved nowhere the repo is read

Phase 4.5 preserved the original syntax on rewrite: `[[rollout]]` became `[[attachments/rollout.md|rollout]]`.
But `$SPECS_PATH` is a **git repository** — browsed on a forge's web view and in ordinary editors — not an
Obsidian vault. Nothing there resolves `[[name]]`; a forge renders it as literal text. A link deliberately
repointed *into* the repo so that it would resolve therefore still resolved nowhere the record is actually
read, which is the entire failure vendoring exists to fix: the copy landed and the brief stayed
unfollowable. **Every rewritten link is now standard markdown** — `[rollout](attachments/rollout.md)`,
`[the plan](attachments/rollout.md)` for an alias, `![toggle-01](design/idea-sources/toggle-01.png)` for an
image embed — which resolves on the forge, in editors **and** in Obsidian, so nothing is lost by
converting. Display text is preserved (a bare `[[name]]` takes `name`; an aliased one keeps its alias), and
a bare image embed derives its alt from the **original** basename, never from the name the collision rule
minted, so a `_NN` suffix never surfaces as alt text. Markdown links and images were already in the right
form and continue to have their target replaced and nothing else.

**`![[note]]` on a markdown file becomes a plain link, and the call is stated rather than buried.** An
Obsidian transclusion has no standard-markdown equivalent, and `![…](…)` pointed at a `.md` file renders as
a broken image rather than as the page. The embed renders nothing on a forge or in an editor either way, so
preserving it preserves only the appearance of meaning, while `[note](attachments/note.md)` resolves and
opens the copy everywhere — in Obsidian too, where only the inline transclusion is lost. We take the trade:
a link the reader must follow beats an embed nobody's reader expands. It is written where the rule lives so
nobody restores the embed believing the conversion was an oversight.

**A link whose target was NOT copied keeps its original syntax, deliberately.** Past a cap, broken,
unreadable, a PDF, an external URL: it is left byte-for-byte, wikilink and all. A surviving `[[rollout]]` is
the visible signal that the cap bit and the author may want to vendor that file by hand; converting it would
give a dead link the shape of a repaired one.

### Fixed — three smaller inaccuracies

- **`wikilinks_followed[].path`** said "path of a followed .md" where every sibling field says
  **absolute**. Phase 4.5 copies from that field.
- **`docs/brd-workflow.md`** drew `attachments/` inside the **BRD** folder annotated "written by /idea",
  but `/idea`'s write root is always a **PRD** folder and no route writes attachments at BRD level. It now
  hangs off the `PRD-<CHILD-KEY>-…` slice folder, beside `design/idea-sources/`. The `design/` entry at
  BRD level is `/brd-ground`'s and is unchanged.
- **The G1 consequence was understated by an order of magnitude.** `commands/idea.md` said a declined
  handoff leaves the vendored files dirty "exactly as it already leaves `idea.md`". It leaves far more:
  `idea.md` **plus every path Phase 4.5 wrote** — up to 12 copies in `attachments/`, 6 in
  `design/idea-sources/` and that set's `index.md`, so as many as **20 dirty OTHER paths**. And a decline
  is not the only route there: the `status: draft` branch never offers a handoff at all, so a draft run
  reaches that state by construction. `references/specs-repo-git.md` §3.3 G1 then ends the preflight and,
  because §3.4's leftover flush and §3.5's branch disposition run only when stage 1 matched nothing,
  **suppresses both for the rest of the session** — not merely "an advisory notice". It still does not set
  `specs_git: blocked`, so the terminal commit runs and nothing is lost.

### Changed — `deliverable_paths` names reused copies too

A copy the collision rule matched byte-for-byte was not *written* by this run, so "every file Phase 4.5
wrote" left it out — yet `idea.md`'s link points at it and an earlier declined handoff may have left it on
no ref. The declaration is now "every file Phase 4.5 wrote **or reused**": naming a path whose content is
unchanged stages nothing, while omitting one is a link to a file that never lands.

Counts unchanged: 27 commands / 37 agents / 105 reference files.

## [3.18.0] — 2026-09-01

### Added — `/idea` vendors the sources it read into the PRD folder

**`idea.md` used to land in the system of record carrying links only its author could follow.** The
brief was written into `$SPECS_PATH/specifications/PRD-<KEY>-<slug>/`, but every file and image it
cited still pointed at wherever the operator's source happened to live — usually outside the specs
repo entirely. The folder that is the record therefore held a provenance document nobody else could
open. A new **Phase 4.5** copies the sources the run actually read into that same folder and rewrites
`idea.md`'s links onto the copies.

- **Text and markdown → `<PRD-folder>/attachments/`** — the source file itself and every page the
  wikilink traversal followed.
- **Images → `<PRD-folder>/design/idea-sources/`** — every image `idea-reader` opened, reusing the
  frame-set convention `references/grounding-format.md` §6.1 already reserves rather than inventing a
  second place for pictures.
- **Nothing else, ever.** No PDF, no archive, no other binary. `idea-reader` now returns a
  `links_other[]` list — every link that resolved to a file it neither follows nor renders,
  enumerated and never opened — so a linked PDF is named in the report instead of vanishing between
  the copy set and the digest.

**The frame set is written with its index, and that was never optional.** §6.1 makes a frame set's
index mandatory and its absence unrecoverable — `design-grounder` returns `NO_INDEX` rather than read
a directory without one, because a filename is not a reliable statement of what a frame shows. Images
dropped into `design/idea-sources/` without an index would therefore have been a frame set nothing
could ever read, and no later run could repair it. The material was already in hand: `idea-reader`
returns a `description` per read image, and `index.md` is written from those descriptions,
transcribed verbatim and never inferred.

**Writing an index is not consuming one, and `/idea` design grounding has NOT shipped.** Nothing on
this route dispatches `design-grounder`, produces a `[DG#n]`, consults an index, or reaches a
verifier. The index makes the frame set *readable*; it does not make anything read it. That
capability remains deliberately unbuilt, `references/grounding-format.md` §6.1 still says so, and
that paragraph was rewritten rather than deleted so the distinction is met where the mistake would be
made.

**Only what was actually read is copied, and everything else is reported.** The copy set is exactly
the digest's positive reads and inherits `idea-reader`'s existing caps — 12 files, 6 images — adding
no bound of its own, because Phase 4.5 opens no path the reader did not already open. Four sets are
deliberately left behind and each is named in the Final report with its reason: `wikilinks_not_followed`
(`cap`/`depth`), `wikilinks_broken`, `images[].read: false` (`cap`/`unreadable`/`not_an_image`), and
the new `links_other`. None of them is copied, none has its link rewritten, and none of them is fatal
— nor is a copy that simply fails, which leaves that file unvendored and its link untouched.

**Name collisions get a suffix that never compounds.** Two linked files may share a basename from
different directories, and a re-run meets its own earlier copies. Byte-identical content at the
destination is reused rather than duplicated, which makes a re-run idempotent; otherwise the name
takes the lowest free `_NN`, derived from the destination directory and appended to the **original**
basename. The third collision is `notes_03.md`, never `notes_01_01.md`. The same rule, with the same
counter, applies in both destinations.

### Changed — `deliverable_paths` grew, because a copy nothing declares never lands

`/idea` declared `deliverable_paths` = `idea.md` alone. `references/specs-repo-git.md` and
`references/phase-handoff.md` §2.3 both stage **the literal declared paths only**, classifying
everything else as OTHER, so the copies would have been written, left dirty, and never reached the
default branch — landing `idea.md` there pointing at `attachments/` paths that exist on one machine
and on no ref, a worse record than the one this release set out to repair. The declaration now names
`idea.md` plus every file Phase 4.5 wrote, **one literal path each, never a directory and never a
glob**, which is what §2.3's enumeration requires. A bare-prompt run vendors nothing and passes
`idea.md` alone, exactly as before.

### Changed — the two reserved subdirectory names are registered together

`references/addressing.md` §2 listed `design/` among the reserved subdirectory names resolution
passes over; `attachments/` now sits beside it, with the rule made explicit that the register cites
each name's authority rather than defining it — `design/` is `grounding-format.md` §6.1's,
`attachments/` is `idea-format.md`'s. `references/idea-format.md` gains the **Vendored sources**
section that owns the two destinations, the copy set, the index format, the collision rule and the
link-rewriting rule, plus a `sources[].vendored` field: `ref` is never rewritten, because how the
idea arrived is still true of a path nobody else can resolve, and `vendored` says where it can be
read now.

### Fixed — a drawn tree that had never shown `design/`

`plugins/dev-workflows/docs/brd-workflow.md`'s "What lands where" tree enumerated the BRD folder's
files but omitted the reserved `design/` subdirectory `/brd-ground` Phase 5 reads — the one route
that has consumed frame sets since they were defined. Both reserved names are now drawn there and in
the design's §4.1 tree, each with a line saying what it holds and who writes it.

## [3.17.1] — 2026-09-01

### Fixed — the review leftovers, cleared rather than carried

**The leftovers, cleared rather than carried.** Every remaining finding across the five reviewer
reports is fixed in this release, including the ones that were only MINOR: `docs/reference/session-cost.md`
said `date` is when an entry's window ended, which is false for a deferred entry (dated when its run
ceded, near the *start* of what it measures); `docs/roles-and-phases.md` said only the commands listed
there emit a phase directly, while listing two that never do; `docs/reference/references.md` described
`cost-emission.md` as cited by "every PRD-lifecycle command's terminal Session cost phase", wrong on
both counts; and neither command's documentation page mentioned the cost entry it now produces or
linked the page explaining it. Two **never-fails** violations were also fixed — a non-string `model`
in a transcript reached `sorted()` and a dict key and raised, and an unreadable price file raised out
of `open()` — both pre-existing on `main`, both a hard failure in a script whose contract is that it
never fails. The script now also reports a `notes` line distinguishing "no boundary in this window"
from "namespace could not be resolved", which previously looked identical from outside.

## [3.17.0] — 2026-09-01

### Added — `/idea` reads more of the source it was given

**An idea run now opens the images its source links, and follows that source's wikilinks two levels
instead of one.** Given a markdown source, `idea-reader` previously recorded an image as a path and
nothing else, and stopped at the source's immediate neighbours. Both bounds have moved, and both
moves are bounded in their own right.

- **Linked images are read, and what each frame shows reaches the grill.** The reader enumerates
  every image the source *and every followed page* links, opens the first **6** in traversal order,
  and returns a ≤60-word `description` of each — the screens, fields, states and flow on the frame.
  A run over a note that links a mockup can now ask "the frame puts the toggle per project; is the
  setting per project or per account?" instead of asking what the file is.
- **Wikilinks are followed two levels deep** — the source's own `[[links]]`, and the links on those
  pages. Depth 3 is never reached, and links found on a depth-2 page are listed rather than walked.

**What an image counts as: context, not evidence — and that is the whole design.** A read image
informs `raw_context`, the grill's questions and the prose `idea.md` ends up with. It does **not**
become a `[DG#n]` design-grounding finding, it needs **no** index file, and it gets **no** verifier
pass. `design-grounder` is not wired into this route and `references/grounding-format.md` §6's
index requirement is deliberately *not* imported: that requirement exists because a **filename** is
not a reliable statement of what a frame depicts, which is the right standard for a finding somebody
will act on and the wrong one for a brief whose operator handed the mockup over themselves. §6.1 now
says so where a reader will meet it, so nobody mistakes this for the `/idea`-route design-grounding
capability — which remains deliberately unbuilt and is a decision of its own. The rule that carries
the distinction: **a described frame is never written into `idea.md` as fact** unless the grill
confirmed it or the source's prose already said it, and an image that was not read carries no
description at all — never one inferred from its filename.

### Changed — one level was the bound, so it was replaced with a real one

At two levels a wikilink read fans out as the product of two branching factors, so the old
"one level deep (bounded)" clause stopped being a bound the moment the depth moved. Three mechanisms
replace it, all stated in the agent's new `## Bounding` section:

- **Cycle protection.** A visited set of resolved absolute paths, with the source file as its first
  member. The same file is never read twice, so A→B→A terminates. **A revisit is a silent skip** —
  not an error, not a broken link, not counted against the cap, not re-summarised; the file's
  existing `wikilinks_followed` entry is the record.
- **A total-file cap of 12** across the whole traversal, the source counting as the first — a
  *total*, never a per-level allowance. Twelve rather than the 8 pages `docs-grounder` reads, because
  that traversal prunes a ranked candidate set while this one starts from a file the operator named:
  depth 1 *is* the source's own context, and a tighter cap would spend the whole budget there and
  never reach depth 2, which is the capability the new depth exists to permit.
- **An image cap of 6**, for the item that costs the most per unit of information in the digest.
  Six takes a short screen flow whole, which is the shape a linked mockup set usually has.

**Nothing is truncated silently, and nothing new is fatal.** Every bound that bites is reported on
the item it stopped, following the shape `wikilinks_broken` already set: a new `wikilinks_not_followed`
array names each in-scope link the traversal did not reach with `reason: cap | depth`, and each
`images` entry that was not opened carries `read: false` with `reason: cap | unreadable |
not_an_image`. A missing image path still goes to `wikilinks_broken`; an image that exists but cannot
be rendered, and a non-image file behind an image extension, are noted and survived exactly as a
broken wikilink always has been. `/idea`'s Final report now states what the source read cost and what
it left — **including when it left nothing**, because the absence of a truncation notice only means
anything once the run is known to print one.

### Changed — digest schema

`idea-reader`'s output gained one array and reshaped two, so every consumer is updated in the same
release:

- `images[]` — was a list of bare paths; is now `{path, linked_from, read, description?, reason?}`.
- `wikilinks_followed[]` — gained `depth: 1 | 2`.
- `wikilinks_not_followed[]` — **new**: `{target, from, reason}`.
- `images`, `wikilinks_followed`, `wikilinks_not_followed` and `wikilinks_broken` are each `[]` when
  empty and never omitted, so a caller can tell "nothing linked" from "the key went missing".

`/idea` Phase 2 carries all three wikilink lists forward, Phase 3 states how a description is used in
the grill (material for a question, never an answer in it, never a slot of its own),
`references/idea-format.md` §5 states how an image is cited in **Signals & evidence** (by path; a
frame is never the sole support for a demand bullet), and the `idea-reader` frontmatter `description`
— what a user meets in `/help` — now says two levels and images-read instead of one level and
paths-only.

**`/create-prd` is unchanged, and now says so.** It reads `idea.md` directly and never dispatches
`idea-reader`; an image path cited in the brief's **Signals & evidence** is carried forward as
provenance and **not reopened** there. `idea-reader`'s caps and reporting belong to the `/idea` run
and do not travel with the file, so opening one downstream would be an unbounded read with no cap and
no reporting line behind it.

### Fixed

- **`docs-grounder` and `references/docs-grounding.md` still offered "keyless `/idea`" as the example
  of a caller that omits `key`.** `/idea` has taken a mandatory key since the address became an
  argument, and its Phase 2.5 dispatch passes it — the example named a state the command cannot be
  in. The tolerant no-key branch stays (a caller that holds no key still omits the field); the false
  example is gone.
- **`docs/commands/idea.md`'s worked example ran `/dev-workflows:idea` with no key**, which stops at
  `IDEA_NEEDS_KEY` before Phase 1 — while the sentence under it said "the run validates the key". The
  example now carries one, and a second example shows a markdown source with a linked mockup.
- **The same page listed four subagents and then said "All three run at the caller's
  `detection_model`".**

## [3.16.1] — 2026-09-01

### Fixed — review round 2 on the deferred-attribution feature

Three Opus reviewers went over 3.16.0. Both of that release's own blocking findings were
confirmed fixed and backward compatibility was verified byte-identical against the twelve
largest real transcripts on the author's machine. What follows is what round 2 found on top.

- **A bare built-in minted a phantom boundary.** Claude Code's built-ins are written *bare*
  (`/upgrade`) while plugin commands are written *namespaced* (`/dev-workflows:upgrade`) — and
  `/upgrade` is a name this plugin also ships. Accepting a bare marker therefore turned Claude
  Code's own subscription command into a cost boundary, observed on real transcripts, which
  truncated a ceded run's segment and moved most of its spend into the replaying run. **A
  namespace is now required**, checked against the `name` in the plugin's own `plugin.json`.
  This errs safe by design: a missed invocation becomes an unmatched claim, reported and
  dropped, where a phantom one silently misfiles spend.
- **§2 — the script's documented invocation — omitted `--commands-dir` and `--claim`, and its
  stdout schema omitted `command_boundaries`, `claims` and `unmatched_claims`.** A run following
  §2 literally would have passed no `--commands-dir`, detected no boundary, and discarded every
  attribution: the inertness failure of 3.16.0, reachable a second way. §2 now documents all of
  it, and says outright that omitting `--commands-dir` turns detection silently off.
- **The intent file was declared a JSON array and shown as a bare object**, with no append
  instruction in either command. A session that ceded twice would have overwritten the first
  record and lost an attribution nothing can reconstruct. Both the reference and both commands
  now state append-never-overwrite, and the schema is shown as an array.
- **§3 still described the retired window boundary** — closing a ceded run's window "at the
  transcript boundary where that run began" rather than at the next command of any kind, which
  is the misattribution §13.3 exists to remove, contradicting it from 500 lines earlier.
- **The deferral moved out of a Phase 2.5 and back inside Phase 2, ahead of `commit-artifacts`.**
  A new phase after the terminal commit falsified six sentences across `specs-repo-git.md`,
  `session-hygiene.md` and `CLAUDE.md` that say the commit is the last thing these runs do before
  ceding. The deferral has no dependency on the commit, so **reordering keeps all six true** —
  cheaper and safer than rewording an invariant stated in three authorities.
- **The file's own opening scope sentence** claimed every cost-emitting command has a terminal
  "Session cost" phase citing `emit-cost`; two of the twenty-one have neither.
- Also: `target_command` is required of all four feedback commands, not two; §6.1's unpriced-model
  warning now fires per built entry, replayed ones included; §5's auto-detect documents its third
  suppressor; the record carries `epic` so a replayed entry is keyed like a self-measured one; and
  the "sum to the window" claim is restated as **token-exact**, since per-bucket rounding can move
  the summed dollars by a fraction of a cent.

**`scripts/check-docs.sh` — check 8 was green for the wrong reason.** The two deferring commands
contain no `emit-cost` at all; their §7 rows were satisfied because an intent-record bullet
happened to match the call-site regex verbatim. Rewording that bullet — an entirely natural edit —
would have turned the build red with a message blaming the §7 table, the exact inversion the
check's own comment exists to prevent. Check 8 now recognises **two** routes to a §7 row (calls
`emit-cost`, or records a §13 intent), its extractor-coverage backstop sees both, and a new
selftest case rejects a row backed only by look-alike prose.

**The selftest was decoration and is now a gate.** Review measured 18 of 39 mutations surviving,
ten on load-bearing lines with real dollar consequences — including the very flooring defect the
code's own comment says it prevents. The fixture was rebuilt around the defects rather than around
coverage: sub-second boundary and record stamps, records sitting exactly on a segment's start and
end, the same command ceding twice, a shipped command name that is a strict prefix of another, a
usage record with no timestamp, subagent spend inside and outside the window, a bare built-in whose
name this plugin ships, and a foreign namespace. Fifteen of fifteen mutations are now caught,
against three of sixteen for the original. **No count of caught mutations is recorded in the
file**, deliberately: the last one written there was measured against a fixture two rewrites old.

## [3.16.0] — 2026-09-01

### Fixed — the spend of a command that cedes the session is no longer misattributed

**`/prompt-brainstorm` and `/prompt-grill-me` now produce a cost entry.** Both cede the session at
their Phase 3 — a hand-off to a brainstorming skill, or a long interactive grill — and never regain
control, so neither could ever run a cost phase after its own expensive work. The consequence was
not a missing number but a **wrong** one: because neither advanced the chained checkpoint, its spend
rolled into the next command's window per §3's ordinary semantics, so a long grill followed by
`/implement` was priced as `implementation`/`dev`. Fixing a documentation page looked like
implementation spend, and the phase whose output was actually being corrected looked cheap.

`references/cost-emission.md` recorded this as a known limitation and asserted it could not be fixed
without *"a cost hook that survives the hand-off, which the current entry point does not provide"*.
**That claim was wrong**, and its removal is the substance of this release: no new harness capability
is needed, because the transcript already records every slash-command invocation, and a boundary that
is written down does not have to be hooked.

- **`references/cost-emission.md` §13 (new)** — deferred attribution. A ceding command writes a
  local, transient, never-committed intent record beside the §3 checkpoint, holding only the labels
  that cannot be re-derived from disk once the run is over (`target_command` above all). The next
  cost-emitting run in the session replays it: it splits its own measurement window at the boundary
  where the ceded run began, writes the earlier slice under the ceded run's labels, and keeps only
  the later slice for itself. The slices are disjoint and sum to the window that run would otherwise
  have claimed whole. §3, §7 and §11 pick up the cross-references; §11 gains step 0, a no-op when no
  intent record exists, so the nineteen self-measuring commands are untouched.
- **`scripts/session-cost.py`** — gains `--commands-dir` (the known-command set
  and this plugin's own namespace) and a repeatable `--claim`, and reports
  `command_boundaries`. Given claims it partitions the window: each claim takes the
  segment from its own invocation to the next boundary of any kind, and the
  remainder — including whole segments belonging to commands that emit no cost
  entry — stays with the replaying run. **Three disciplines are load-bearing, and
  each was a defect first.** (a) The match is anchored on the *envelope*, not on
  one tag: Claude Code writes built-ins name-first and plugin commands
  message-first, so a matcher anchored on `<command-name>` alone sees no plugin
  command at all and the feature is silently inert — which is how it was first
  written here. (b) Claims are matched **by name, never by position**: a window
  routinely holds boundaries no claim corresponds to (`/vuln`, `/upgrade`,
  `/statusline`, `/docs-profile`, the two guideline reviewers, or an interrupted
  run), and positional pairing shifts every claim by one, filing a security run's
  spend under a PRD lifecycle phase. (c) A namespace is **resolved against the
  plugin's declared name**, never stripped, so another plugin's
  `/superpowers:implement` is not a boundary.
- **`scripts/session-cost.py --selftest` (new)** — 21 checks over a fixture built
  to discriminate rather than merely to pass, using the **real** transcript record
  shapes. The splitter's failure mode is silent: a boundary missed or invented
  still yields a plausible dollar figure filed against the wrong phase. So the
  fixture carries a message-first plugin invocation, a `/vuln` boundary between the
  ceding run and the replaying one, a foreign namespace over a shared bare name, a
  marker quoted mid-message, a marker with no timestamp, list-block content,
  subagent spend either side of a boundary, and a statusline snapshot. Nine of ten
  mutations are caught, including every one above; the tenth (dropping the
  leading-slash test) is not independently observable, because that test and the
  offset after it are coupled — recorded in a comment rather than covered by an
  assertion that could not fail. Wired into CI.

**What is still not measured, stated rather than buried:** a session in which no cost-emitting
command ever follows the grill. There the spend stays in §3's ordinary post-last-command tail,
unattributed — the same tail every other command already has. The statusline cross-check (option B)
is also not split, since it measures whole renders; a split slice omits it and leaves the delta to
the final slice.

**Stale claims retired**, swept by phrase rather than by line. The first sweep was done per file
remembered rather than per phrase and missed several, which review caught: `docs/reference/session-cost.md`
(the count sentence, the *what does not emit one* paragraph, a *"cannot report honestly"* paragraph
that survived two lines above the section contradicting it, and a *"why the other eight"* count that
is now six), `docs/reference/session-feedback.md` (never opened by the first sweep, and flatly wrong),
`docs/roles-and-phases.md` (**two** sentences — the `plugin-feedback` phase and the inheritance rule,
both naming two of four commands), `references/cost-emission.md` itself (*"three inferred exceptions"*
above a five-row table, plus five §11 sites still describing the pre-change contract), both command
pages, and `CLAUDE.md`.

## [3.15.0] — 2026-09-01

### Removed — BREAKING for Epic content: team ownership

**An Epic no longer records who owns it, and refined Epic files no longer carry a `**Team:**`
line.** Team ownership was tracker-era machinery: a team owned an Epic because a tracker said so,
and `/epics` read that assignment out of an import, carried it through the writer handoff, wrote it
under the Epic's H1, and had `epic-reviewer` check it survived. The import is gone and §6.3 of the
specs-native pipeline design retired the mode that populated the field, but the field itself stayed
behind. It is now removed at every producer and consumer:

- **`epic-writer`** drops `team` from the `refinement_targets[]` contract (`{key, scope_hint,
  current_body_path}`), drops the `**Team:**` line from the Epic template, and drops the *Surface
  the team* rule — including the `[NEEDS CLARIFICATION — team not found in import]` marker it
  emitted, and the `clarifications_needed[]` entry that came with it, when the field was empty.
- **`epic-reviewer`** loses the **Team preserved** dimension entirely (its findings section too),
  and **Cross-team dependency sanity** is renamed **Inter-target dependency sanity** — the same
  check, judging the same build-order edges between two refined Epics, without asserting that a
  different team sits behind each one.
- **`/epics`** stops reading `team` off `epic.md` at the folder read, stops printing it in the
  Phase 3.5 detection list, stops carrying a `[NEEDS CLARIFICATION — team]` note into the writer
  handoff, and drops `team` from the handoff contract. The refinement candidates are described as
  what they are — near-empty Epic drafts left as placeholders — rather than as *team-Epic shells
  encoding team boundaries*; the Phase 6.1 leftover option reads *Assign to Epic `<KEY>`*; and the
  adaptive code-scan default is now justified by a scope boundary rather than a cross-team one
  (the threshold, ON at ≥2 targets and OFF at 1, is unchanged).
- **`references/pre-lint.md`** drops the `grep -nE '^\*\*Team:\*\*'` check on refined Epic files;
  the `## Scope` half of that rule is unchanged. **`references/workflow-states.md`** describes
  `refinement_candidate: true` drafts as placeholders rather than *team placeholders*.

**What an Epic no longer contains.** A refined `epic.md` written by this version has no `**Team:**`
line and no team-not-found clarification marker, so nothing in the artifact records which team owns
it. A team that still needs to be named as a **dependency** names it in `## Dependencies`, which
continues to list "other Epics, repos, teams, external systems" — that is a dependency on an
organisation, not ownership of the Epic, and it is deliberately kept. Existing Epic files are not
rewritten: a `**Team:**` line already on disk simply stops being produced, checked, or preserved.

### Changed — `built_from_import` is now `built_from_date`

The field `/update-prd` writes to record which day's material a refresh was built from was named
for an import ladder that no longer exists. It is renamed **`built_from_date`** — the `built_from`
stem the surrounding prose already uses ("the date the update was built from"), with the one
tracker-era word replaced by what the value actually is. **No migration is needed and that is why
it happens now**: no PRD has yet been authored by this workflow, so no file on disk carries the old
name. Waiting would have turned a rename into a migration. Sites: `references/prd-format.md`,
`commands/update-prd.md` Phase 5, `docs/commands/update-prd.md`.

### Added — check 13: vendor-token quarantine

`scripts/check-docs.sh` gains a **thirteenth check**, and vendor neutrality stops being a
prose-only constraint. No `*.md` under `plugins/dev-workflows/` (CHANGELOG.md excepted, as history)
may write a tracker's name unless the line — or the fence opening the block it sits in — carries
`<!-- vendor-token-ok: <why> -->`. That marker convention already existed in
`references/branch-naming.md` with **exactly one user and no enforcer**; it now has both.

**The token set is narrow on measurement, and the numbers are recorded in the check so the widening
is not re-proposed.** Over `commands/`, `references/`, `agents/`, `docs/` and `skills/` the tracker
names fire on **13 sites: 3 real defects and 10 correct ones**. Adding the git-forge names fires on
**70 further sites, every one correct content and none a defect** — host classification, CLI
capability facts, and hard rules forbidding REST calls. A forge is something this plugin stands in
front of and must name to behave correctly; a tracker is something it deliberately does not read.
That is the same fires-only-on-correct-content result on which check 11's widening was measured and
rejected twice, so it is rejected here for the same reason. `--selftest` gains **four** cases in two
discriminating pairs — marked/unmarked line, and marked/unmarked fenced block. The fence pair is the
load-bearing one: an implementation that simply skipped fenced code would pass the marked case for
the wrong reason, and templates and handoff blocks are exactly where a tracker-shaped field hides.

### Fixed — three sites where the plugin spoke a tracker's language about its own behaviour

Found by the check-13 measurement, and each one a claim that was false, not merely off-tone:

- **`README.md`** said `/ready` will "verify a Jira status against the record". `/ready` is
  artifact-anchored: it derives the workflow phase from the artifacts and reads no tracker at all.
- **`docs/commands/vuln.md`** called `/vuln`'s optional address "a Jira ID" and "a Jira ticket".
  That argument is a key resolved against `$SPECS_PATH` (`references/addressing.md` §3), never a
  tracker lookup, exactly as the command's own Step 1 says. The page now says so, and its mention
  of the `NOISSUE` / `NOJIRA` / `NO-JIRA` placeholder literals — foreign text the run *matches* in
  a repo's own branch and commit history — is marked rather than removed.
- **`commands/update-prd.md`**'s description advertised "a 3-day freshness gate" over an imported
  copy plus grounding on "comments". Phase 0 step 4 retired both when the import ladder went —
  there is one copy, in the resolved folder, and nothing to go stale.

## [3.14.0] — 2026-09-01

### Changed — increment E: the BRD is a container

**D5 and D6 are now enforced structurally rather than assumed.** A `BRD-` folder is refused by
`/create-prd`, `/create-ard`, `/specify` and `/epics` on the **resolved folder's kind, before a
single coverage-ledger row is read** (`CREATE_PRD_BRD_NOT_SLICED`, `CREATE_ARD_BRD_NOT_SLICED`,
`SPECIFY_BRD_NOT_SLICED`, `EPICS_BRD_NOT_SLICED`), and each refusal's remedy is a directory listing
of the `PRD-` slices under it — never a ledger read, and never a command whose output the refusal
would then refuse. `/create-prd` stopped arguing *for* the behaviour the design forbids: the
paragraph justifying an unsliced BRD's PRD cited an escape valve deleted in 3.5.0, and its two data
refusals are now slice-only.

**Epics come from a PRD only, and `/epics <EPIC-KEY>` re-refines.** `/epics` accepts a `PRD-` folder
(draft) or an `EPIC-` folder with a PRD above it (re-refine) and refuses a stand-alone `EPIC-` folder
(`EPICS_EPIC_NOT_UNDER_PRD`) and a `BRD-` container. **The accept gate is `prd.md`'s own `kind: prd`,
never the folder's asserted kind** — a slice folder is `PRD-`-prefixed and asserts `kind: brd`, so an
asserted-kind gate would refuse every slice and accept nothing. `focus_key` is derived from the
resolved `EPIC-` folder, which revives a refine path that was written and unreachable. `/create-ard`
and `/specify` no longer auto-create an absent `EPIC-` folder: `/epics` is the only command that
creates one, and the *stand-alone top-level Epic* case is retired.

**The two routes are identical from the PRD onward.** The PRD `require-on-main` gate runs on every
route in `/create-ard` and `/specify`, and its `absent` branch reports and proceeds, so `/create-prd`
remains a prerequisite for neither. Both read the authored `prd.md`; the BRD seed, register and
findings are read *in addition*. `/create-ard`'s optionality advisory is one rule over the union of
what the folder holds, with the PRD winning the gauge where a slice carries both.

**`/brd-split` resolves in bulk.** Phase 4 gains a Step 1 uniform-answer offer that writes one
disposition across every remaining `unallocated` row behind a single confirmation, naming each row
first and refusable per row; the one-at-a-time walk stays the default and is where a declined or
unparsed answer lands. A forty-row BRD resolved to a single slice costs 2 confirmations instead of
80 prompts.

**The round-trip that no command performs is gone.** `key` is written by `/create-prd` on **both**
routes, set to the resolved folder's own key. `release_versions`, `change_type` and
`release_notes_category` are authored fields, not importer returns. Two-key offer forms
(`/specify <PRD> <Epic>` and its five siblings) are retired everywhere a user reads them, not only
where they were parsed (D4). `/idea` no longer claims to relocate anything (D7).

### Fixed — review round D (the last finding before the pull request)

- **`/create-prd`'s two `absent` branches contradicted each other, and the unreachable one was the
  stop.** Phase 0 step 5 made `status: absent` a graceful `CREATE_PRD_BRD_NOT_FOUND` on the BRD
  route while the paragraph beneath it auto-created `PRD-<KEY>-<slug>/` at the first write. Only
  one can be live, and it is the auto-create: **the BRD route is *detected* from a `brd-link.md`
  inside the folder the address resolved to**, so a run that resolved no folder read no
  `brd-link.md` and is on the idea route by construction — there is no state in which that stop
  fires. It also contradicted four other stops that name this command *for* creating a folder
  (`CREATE_ARD_NOT_FOUND`, `SPECIFY_BRD_NOT_FOUND`, `/update-prd`'s `absent` branch and
  `EPICS_EPIC_NOT_UNDER_PRD` each send an operator to `/dev-workflows:create-prd <KEY>` where
  nothing exists), so the stop reading would have made every one of them a dead end. The stop is
  **retired**, for the same reason `CREATE_ARD_BRD_NOT_FOUND` was retired earlier in this
  increment; a `BRD-` key whose folder *does* resolve is `CREATE_PRD_BRD_NOT_SLICED`'s to refuse,
  so no state loses its report. The capture-at-block invariant and
  `docs/commands/create-prd.md` drop it with the stop.
- **The ordering that hid the contradiction is stated rather than left to inference.** Step 1 said
  to print the route *"before doing anything else"* while the address is resolved at step 5, which
  reads as though a route could be known before a folder was. It now says detection waits on
  resolution, that the single `resolve-address` call is taken as soon as step 2b settles
  `$SPECS_PATH` — ahead of step 2's `--full` default and step 3's skipped ladder, both of which
  read the route — and that an address resolving to nothing is the idea route, not a stop.
- **`/create-ard` and `/specify` do not share the defect, checked.** Both create no folder on any
  route, so each takes one `absent` stop for both routes; `/specify` already records the reason this
  fix turns on — *"a folder that resolved to nothing carries no `brd-link.md` to say which route it
  would have been on"*.

### Fixed — review round A (the three correctness findings)

- **`/brd-intake` created the root BRD folder without its kind prefix.** Its Phase 0 step 7 said
  `specifications/<BRD-KEY>-<slug>/` and cited no addressing rule, so **every BRD this plugin
  produced landed in the pre-prefix shape `references/addressing.md` §5 exists only to *tolerate***
  — a drift live since increment A introduced the prefixes. Three consequences, all on the ordinary
  current route: every fresh BRD resolved through §5's legacy fallback and was reported
  `legacy: true` once per run by every downstream command; the primary `BRD-`-prefix test of all four
  container refusals (`/create-prd` 5a, `/create-ard` 1a, `/specify` s0, `/epics` 1a) never fired on
  a folder this plugin wrote, leaving only `coverage-ledger-format.md` §5.1's *legacy* branch doing
  real work; and `/brd-split` Phase 3 step 2 wrote its slice into
  `specifications/BRD-<PARENT-KEY>-<parent-slug>/…`, **a parent path that did not exist**, which
  followed literally creates a second empty `BRD-` folder and orphans the slice. `/brd-intake` now
  writes `specifications/BRD-<BRD-KEY>-<slug>/` citing §2, and `/brd-split` creates its slice inside
  **the folder this run resolved** rather than a path re-derived from `<PARENT-KEY>` — which is also
  what keeps a legacy unprefixed parent working. §5's fallback is untouched: it still resolves every
  folder a pre-prefix repo holds, and this plugin no longer adds to them. Swept across
  `commands/brd-intake.md`, `commands/brd-split.md`, `references/coverage-ledger-format.md` §5.1
  (whose root-BRD bullet now says the shape is what `/brd-intake` wrote *before* the prefixes
  shipped), the five `/brd-*` documentation pages, and the repo-root README's specs-tree sketch.

- **`/epics` step 1a was prefix-only, and its dead end was reachable from one typo.** The other
  three container refusals each cite `coverage-ledger-format.md` §5.1's positive test for an
  unprefixed folder; `/epics` did not, while §5.1 itself claimed to serve "all three consumers". On
  a legacy root BRD carrying `coverage-ledger.md` and `brd/brd-inventory.md`, step 1a never fired,
  step 1b emitted `EPICS_NO_PRD` naming `/dev-workflows:create-prd <KEY>`, and `/create-prd` honoured
  §5.1 and refused the same folder as a container — **a stop whose remedy stops**, verbatim the
  anatomy step 1a exists to prevent. Step 1a now carries the same §5.1 clause, §5.1 names **four**
  consumers as a list, and the design spec's §5.3 amendment — which asserted *"`/epics` is
  unaffected: §6.3's gate reads `prd.md`'s own `kind: prd`"*, true of step 1b and false of step 1a —
  is corrected in place rather than deleted.

- **Four offers named `/create-prd` having tested one of its three refusals.** `/create-prd` refuses
  a container, `CREATE_PRD_BRD_UNALLOCATED`, and `CREATE_PRD_BRD_NOT_ELIGIBLE`. `/epics`'s
  `EPICS_NO_PRD`, `/create-ard` Phase 7's BRD-route bullet, `/specify`'s `### Next step` and
  `/specify` Phase 3 Step A's zero-Epics picker each tested only the first — the `/epics` prose even
  claimed step 1a had "already taken the one folder `/create-prd` would refuse", wrong on the count.
  One state breaks all four: a slice, ground and allocated, every claimed row `deferred-to` or
  `rejected`, no `prd.md`. Each sent the operator into `CREATE_PRD_BRD_NOT_ELIGIBLE` — the branch
  that by design **names no command at all**. The rule is now stated once, in
  `references/coverage-ledger-format.md` §5.2, and follows `commands/brd-reconcile.md` Phase 14's
  precedent: run both data tests over the slice's own ledger rows narrowed by its `brd-link.md`
  `claims:`, read out of the file and never off a `ledger:` line, then **drop the option and say
  which test failed** — naming `/brd-split` on the slice for an `unallocated` row, `/brd-split` on
  the parent for a standing empty child, and nothing at all for the branch that names nothing. A
  folder carrying no `brd-link.md` has no gate set and reaches `/create-prd` on the container test
  alone, so the idea route is unchanged.

### Fixed — review round C (the last findings before the pull request)

- **`/update-prd` named `/create-prd` without testing its refusals.** Phase 0 step 4's
  `UPDATE_PRD_NO_PRD` stop ran *"run `/dev-workflows:create-prd <ADDRESS>` to author one first"*
  unconditionally, on a folder that exists and holds no `prd.md` — so on a `BRD-` container it named
  a command that refuses a container, and on a slice whose every claimed row is `deferred-to` or
  `rejected` it sent the operator into `CREATE_PRD_BRD_NOT_ELIGIBLE`, the branch that by design names
  no command at all. `references/coverage-ledger-format.md` §5.2 already stated the rule — an offer
  naming `/create-prd` is safe only once it has tested all three refusals — and four sites followed
  it while this one, in the command furthest from the BRD route, did not. Step 4 now resolves its
  remedy from a six-row table applying §5.2: the container's slices, `/create-prd` where the folder
  has no gate set or clears both data tests, `/brd-split` against the slice or the parent where one
  fails, and **no command at all** for the non-empty not-eligible branch, which reports what the rows
  resolved to instead. That is the only coverage ledger `/update-prd` ever opens; it is confined to
  the stop and runs after the refusal. Step 3's `absent` branch keeps naming `/create-prd`
  unqualified and now says why it may — nothing resolved, so there is no folder, no gate set and no
  kind to test — instead of claiming it is "the same remedy step 4 names".
- **The route map made the same offer unconditionally.** `references/next-phase-offer.md`'s PE entry
  told every caller to offer `/create-prd <ADDRESS>` where the resolved folder holds no PRD; it now
  carries the §5.2 qualification the two commands that implement it already carried.
- **A stale rationale outlived its instruction.** `commands/create-prd.md` Phase 0 step 3 rung 1 read
  *"do not relocate, `/idea` already did"* — but D7 retired relocation and `/idea` writes `idea.md`
  in place on the first write. The instruction was right and the reason was false; the reason is now
  that nothing relocated it, because nothing does. The docs mirror carried the same claim.
- **An overstated claim about §5.1's test.** `/epics` step 1a called it *"a directory listing … it
  asks which files the folder carries, and opens neither"* — but §5.1's root-versus-slice rows read
  `brd-link.md` for `parent:`. The load-bearing claim is that no *ledger* is opened at step 1a, and
  that is what the sentence now says.
- **An unspecified edge in the three new ledger reads.** None of `/epics`, `/create-ard` and
  `/specify` said what to do on a slice carrying `brd-link.md` and **no** `coverage-ledger.md`.
  `/brd-split` writes and lands both together, so it is reachable only by hand damage — which is a
  thing to state rather than leave silent. `coverage-ledger-format.md` §5.2 now states it once, in
  the authority all of them cite: it is not an empty gate set, so it must not resolve to the standing
  empty child's `/brd-split <PARENT-KEY>`; name no option, report the missing path, and leave
  recovery from the specs repo's history to the operator.
- **A pre-existing count error.** `docs/reference/references.md` said *"The **55**-file subtree
  figures below"* in the same paragraph that computes 24 + 11 + 9 + 5 + 3 + 2 = **54**. The six
  subtrees hold 54 markdown pages and five non-markdown files; the sentence is the markdown count.
  Not gated by `check-docs.sh` check 9, and carried since `cb45c0a`.
- **Two docs pages still said their command "does not read the ledger".** `/create-ard`'s and
  `/specify`'s pages were written before those commands gained the next-step read that decides
  whether `/create-prd` can be named. Both now say what the commands say: nothing they author from
  is a ledger row, and the read that exists gates nothing. `/update-prd`'s page dropped its retired
  claim that an unimported key stops the run, and states the `UPDATE_PRD_NO_PRD` routing instead.

### Fixed — review round B (the remaining findings)

- **The destructive remedy was the only one offered.** Where a root BRD's ledger is fully allocated
  *and* holds an illegal root `covered-here`, four stops named a `/brd-intake <KEY> @<file>` re-run —
  whose Phase 5 rewrites **every** row back to `unallocated`, discarding the walk's `deferred-to`,
  `rejected` and `superseded-by` decisions along with the illegal row. **A narrower repair exists and
  is now offered first**: the illegal state is one row wide and every other row is already legal and
  terminal, so hand-editing that single `disposition:` — to a legal terminal fate, or back to
  `unallocated` so `/brd-split` has a row to walk — repairs it while leaving every other decision
  standing. `references/coverage-ledger-format.md` §5 already named hand editing as the *cause* of
  this state and §3 forbids no hand repair (it binds commands); §5 now owns the ordered remedy and
  all four stops follow it. The `/brd-intake` re-run is second, and every stop that names it now
  names **which** decisions it destroys rather than saying the dispositions are "replaced".
  `/brd-intake` itself gains a re-run warning and a confirmation at Phase 0 step 7 — before the first
  write, the last point at which declining is free — and Phase 5 restates what the rewrite discarded.
- **`/brd-split`'s bulk offer fell through two opposite ways.** At the hold-back prompt an
  **unparseable** answer fell to option 3, the walk, expressly so nothing was written nobody answered
  for — while an **empty** answer "named no exception and was option 1", the maximal write. A stray
  Enter is the input nearest to unparseable and got the opposite treatment. Every answer the step
  cannot use now falls to the walk, at both prompts, and a **second** invalid id after the one
  re-prompt — previously unspecified — falls there too.
- **The four container refusals presented a state with a documented exit as having none.** The
  "one slice removed as a standing empty child" sub-branch said *name none* — true of the customer
  decision, false of the carrying-out, which is the same escape the sibling sub-branch names two
  clauses later. It now reads as an ending rather than a sealed state, and names the two repairs that
  carry the decision out once it is taken.
- **`/idea` sent the operator into a stop it had just caused.** Phase 5's handoff offer recommended
  `/create-prd <KEY>` with **no `<merge-clause>`**, while `/create-prd` Phase 0 step 3 rung 1 runs
  `require-on-main` on that very `idea.md` and stops on rows D/E while the pull request is open —
  the exact defect `references/next-phase-offer.md` names, in the one adopter its own adopter list
  omitted. Both are fixed. `scripts/check-docs.sh` check 11 stays family-scoped: re-measured on this
  tree, widening fires on **three** correct sites (down from four — the fourth went with the
  relocation branch D7 retired) and catches **none** of the six defects, `/idea`'s included, whose
  offer is prose and invisible to any `choices:` scanner. The numbers are recorded in
  `next-phase-offer.md` and in check 11's own header so widening is not re-proposed without new ones.
- **`/idea`'s `status: draft` path offered no next step at all**, and the un-handed-off `idea.md` was
  then silently unread: `/create-prd` rung 1 gets row F `absent` for a file on no ref, falls through,
  and grills from scratch in the folder it just resolved. The draft path now names two steps — re-run
  `/idea` to close the markers, or `/create-prd <KEY> @<path>` to read the draft in place on rung 2's
  terms — and rung 1 reports an in-contract `idea.md` that exists but is on no ref instead of passing
  it over in silence. The fall-through itself is unchanged: `/idea` is not a prerequisite.
- **`/specify` Phase 0 step 3 contradicted itself three ways on `absent`** — "Create
  `PRD-<PRD>-<vslug>/` … only on `status: absent`" against "The PRD dir is not created here" against
  "`absent` is a graceful stop, not a folder to create". It is a stop, on both routes; `/specify`
  specifies a PRD that exists and creates no folder. `SPECIFY_BRD_NOT_FOUND` is now reachable on the
  idea route too, so it names every creator rather than only the BRD route's.
- **`/document` Mode A's `absent` stop named only `/create-prd <KEY>`** — wrong on the BRD route,
  where that command refuses the container above the slice, and wrong for an `EPIC-` address, which
  it never mints. It names the three creators, as `/ready`, `/release-notes`, `/epics` and
  `/create-ard` already did.
- **`/brd-split`'s frontmatter described the bulk offer's firing condition with one of its two
  clauses**, omitting *two or more rows still `unallocated`*; `docs/commands/brd-split.md`'s summary
  the same. Both now state both.
- **`references/workflow-states.md` lost the only user-facing description of the detected refine
  mode** when the re-refine description replaced it rather than joining it. `/epics <PRD>` still
  detects `refinement_candidate: true` Epics and offers to partition the PRD across them; the entry
  describes both ways in, and no longer names a `<EPIC-KEY>.md` file. `references/pre-lint.md` and
  `/epics`' own report grouping named that filename too — `agents/epic-writer.md` forbids it.
- **`commands/create-prd.md` still read *"Nothing writes it now, so the field stayed permanently
  unset"*** ten lines under *"`key` — written on every route"*.
- **The BRD design record still drew the pre-prefix tree** (`<BRD-KEY>-<slug>/`,
  `<BRD-KEY>_<slug>.md`) and still compared the slice picker's four resolutions to five. Amended in
  place as **R26**, with the reason recorded: leaving the wrong shape in the record this route's
  implementers read is how `/brd-intake` came to write it.

### Fixed — the closing sweep

- **`diff-summarizer`'s handoff contradicted its own agent, and `/document` dispatched the stale
  one.** `references/handoff/diff-summarizer.md` declared only `pr_refs` and refused any input
  lacking it; the agent declares `refs:` as the ordinary shape because that is what
  `implementation.md` records — no URL, no host, no PR id. The handoff now carries `refs`, the
  `refs`-or-`pr_refs` refusal, and per-element output fields that a `refs` element can actually fill
  (`ref`, `resolved_via: local_ref`). `/document` Phase 5 passed `pr_refs: [… from the folder read
  handoff …]` while Phases 3/4 built `refs[]` from the implementation record — it now passes what it
  built, and the PR-shaped vocabulary around it (a "recorded PRs" gate, a `host: other` filter on
  elements that carry no host) says what the run actually holds. `/release-notes` Phases 4–5 the
  same.
- **Four commands could report a state with no way out of it.** `/epics`, `/ready`,
  `/release-notes`, `/update-prd` and `/document` (keyed mode) each answered `resolve-address`'s
  `absent` with "the folder does not exist" and named nothing — no error code, no remedy, no command
  that creates one. `/epics` gains `EPICS_NOT_FOUND`; the others surface `escalation-rules.md`'s
  `key dir not found` rule and name the run that creates the folder.
- **Three stops named a remedy this increment had just made insufficient.**
  `CREATE_PRD_BRD_NOT_FOUND`, `CREATE_ARD_BRD_NOT_FOUND` and `SPECIFY_BRD_NOT_FOUND` offered
  `/brd-intake <BRD-KEY> @<brd-file>` as a way to produce the folder — which produces the `BRD-`
  container all three now refuse. They name `/brd-split` on the parent, and say a parent BRD must be
  grounded and split before any slice exists. `CREATE_ARD_BRD_NOT_FOUND` is retired outright: the
  BRD route has one resolution and takes `CREATE_ARD_NOT_FOUND` like every other route.
- **`/epics`' `EPICS_FOCUS_NOT_FOUND` was unreachable and offered a retired argument form.**
  `focus_key` is derived from the resolved folder, so it cannot disagree with `prd_dir`; the check
  and its *"Re-enter the Epic key"* choice belonged to the two-key grammar D4 removed.
- **`/ready` read a `<prd_dir>/<KEY>-index.md` that nothing writes.** A tracker export wrote it; the
  status peek is retired rather than reconstructed, since D8 derives the phase from artifacts and
  `--claimed` is the only status anyone declares. `/implement`'s input-classification table
  recognised a specs folder by `*-index.md` / `KEY.md` — both export shapes, and both keyed
  filenames D3 forbids — and now recognises it by the `key:` a keyless artifact asserts.
- **`/epics` handed `epic-writer` a `current_body_path` of `<prd_dir>/<EPIC-KEY>/<EPIC-KEY>.md`**,
  the shape that agent explicitly forbids, so every refine run regenerated instead of iterating. It
  is `<prd_dir>/EPIC-<EPIC-KEY>-<eslug>/epic.md`, matching what the agent writes.
- **`workflow-states.md` described a refine mode that cannot happen** — a PE pre-creating empty Epic
  folders per team, with drafts keyed `<EPIC-KEY>.md`. `/epics` is the only command that creates an
  `EPIC-` folder (D6) and filenames carry no key (D3); the note now describes refine as §6.3 defines
  it.
- **`docs/roles-and-phases.md` said `/brd-reconcile` offers all three PRD-pipeline commands "against
  the same BRD key", and `/create-ard` and `/specify` "unconditionally, since neither gates a PRD".**
  All three refuse a `BRD-` container, the offers are made off a slice key, and both commands now run
  the PRD gate.
- **Three frontmatter `description:` fields named a folder shape that does not exist** —
  `$SPECS_PATH/specifications/<KEY>-<slug>/` for `/create-prd`, `/create-ard` and `/update-prd`,
  unprefixed since increment A. Same in `docs/reference/environment.md`'s tree, `docs/workflow.md`
  and `docs/getting-started.md`. `/create-prd` also carried **two different texts for one
  `CREATE_PRD_NEEDS_KEY`**, one of which told the operator to "create an address first to get the
  ID" — an act with no counterpart since the cut.
- **`handoff-to-main`'s declined-handoff line promised a stop that does not happen.** Declining
  writes no branch and no commit, so the next phase's gate reads row F — which *delegates*. §4.1 now
  resolves the clause from §3.4's row for that artifact: a stop where the input is a prerequisite,
  and report-and-proceed for the `/create-prd` idea ladder and the PRD read in `/create-ard` and
  `/specify`.
- **`/design` named `mgd-specifications` as the handoff surface** — another edition's repository, in
  the canonical edition — and its no-spec stop named `/dev-workflows:specify` with no address (D4).
- **Residual importer vocabulary, live on four surfaces.** `release-notes-writer`'s handoff and agent
  declared `imported_change_type` "from the imported PRD frontmatter", its own `description` sourced
  the category label "from the imported `release_notes_category`", and both carried the empty
  `{{#context}}` gap left by the macro's retirement ("a  label", "the  line"). `/update-prd` twice
  ruled that "the import wins" three paragraphs after its own step 4 states there is nothing to
  import. `release-note-types.md` §7 read "the category label label".
- **`references/branch-naming.md`'s vendor tokens are now framed once, where a reader meets the
  first one.** `<JIRA-ISSUE-KEY>` is quoted from a repository's own `CONTRIBUTING.md` and matched, not
  written — and it is deliberately **not** genericised: the recognition table is what makes the
  plugin honour a team's documented convention, and a swept list would drop such a repo into §1.4's
  no-convention branch and give it a branch name its team does not use. `/upgrade` separately said
  "the run's Jira key" of a key the plugin mints itself.
- **`grilling-technique.md`** justified `/brd-split`'s ≤5 cap with "a walk that visits every row
  anyway", which predates E5's Step 1; **`2026-08-29-brd-to-prd-workflow-design.md`** R18/R24/R25 and
  §9.3, and `CLAUDE.md`'s BRD-route line, still described a slice's walk as "four resolutions instead
  of five" — the parent's picker lost `covered-here` in 3.5.0, so both walks offer four and differ in
  one member.
- `CLAUDE.md` records the two traps this increment turns on: a slice folder is `PRD-`-prefixed while
  asserting `kind: brd`, and PRD-eligibility is a folder-kind question before it is a ledger
  question.

Counts unchanged: **27 commands / 37 agents / 105 reference files.**

## [3.13.0] — 2026-09-01

### Fixed — the whole-design review, round 1

Four Opus reviewers swept every change from the four increments and three fix waves at once, each
along one dimension, looking **across increment boundaries** — where the per-increment reviews
structurally could not see. Between them: **10 BLOCKER, 27 MAJOR, 16 MINOR** after deduplication, every
one verified at the location it named before anything was edited. Two are worth stating first because
they were structural rather than textual.

**`resolve-key` matched folder *names*, so the first child broke its parent.** The glob
`specifications/**/*-<KEY>-*` matches every folder whose key merely *extends* `<KEY>` — and a child
keyed from its parent is this plugin's default (`/brd-split` proposes "the parent's key plus the next
unused two-digit segment" and nests it inside). On a BRD holding two slices the glob returned **three**
matches for the parent's key, so `resolve-address` hard-stopped as `ambiguous` on a tree that was
entirely correct, making the parent unaddressable by all six `/brd-*` commands from the moment its
first child existed. The inverse was worse: a legacy parent holding a prefixed child globbed to exactly
one match — the *child* — and returned `found` for it silently. §3 now **filters candidates by the key
each one asserts**, which is `addressing.md` §4's own read applied as a filter rather than only to the
winner. `<KIND>` moved into that filter too, since a slice is a `PRD-` folder asserting `kind: brd` and
narrowing the glob by prefix missed it.

**Nothing committed `implementation.md` or `release-notes.md`.** `commit-artifacts` classifies by a
regex requiring a `dev-workflows/` path segment; both land without one, so both were classified `OTHER`
and skipped — while `/implement` and `/release-notes` each told the operator the terminal step
committed them. They then sat permanently dirty, firing the preflight's G1 guard on every later run of
any of the twenty-three callers. §2.1 gains a fourth and fifth shape naming **the two files, never
their folder** — the folder also holds the phase deliverables, which are `phase-handoff.md`'s to commit
behind its own consent choice.

**The other blockers:** the PRD gate globbed `<PRD>_*.md` while `/create-prd` writes `prd.md`, so
`require-on-main` returned `absent` for every PRD that was present and its stop could never fire; a
`--from-brd` → "the BRD route" substitution landed inside executable strings, and `/specify`'s stop told
the operator to re-run a form whose extra tokens trigger the identical stop — a loop with no exit;
`/release-notes`' worthiness gate read a field from an import that no longer exists and forbade the one
file that carries it, so a PRD marked `relevant_for_release_notes: false` had a note drafted anyway;
`getting-started.md` told a first-time user `/idea` "needs no key" and printed an example that
hard-stops; `/create-prd` ran no `specs-preflight`, alone among the twenty-three, so its gate ran
before the fetch it depends on; `/design`, `/ready` and `/specify` derived Epic subfolders without the
`EPIC-` prefix that `/epics` creates, so `/design`'s ref test could never match and every Epic was
excluded; the BRD-route PRD deferred its `key` to a round-trip that no longer exists, and
`prd-reviewer` was told never to flag the absence; and `CLAUDE.md` described `/idea` in terms of a
vault, a relocation step and a `prd_disposition` gate that increment D deleted.

**Dead consumers with no producer**, all now wired to what exists: `/epics`' `requirements[]` — the
coverage ground truth `epic-reviewer` gates on — was returned by a deleted agent and rebuilt by nothing;
`pull_requests[]` had three consumers and no writer; `## Pull Requests` had five; `diff-summarizer`
refused any input lacking `pr_refs`, which is not the shape either caller has; two agent contracts
pointed at a schema file that does not exist; and `code-review`'s ARD-deviation branch read a record
written after it returns.

**Counts, every one re-derived rather than adjusted:** 37 agents (not 39), 42 documentation pages (not
41), 10 reference pages (not 9), `/document`'s 34 phases split 23/11 (not 37 and 26/11), 20 commands
loading `model-routing` (not 14), 19 with a maintenance phase (not 13), 5 `id-grammar-ok` markers
across 5 files (not 10 across 6), 14 handoff producers (not 8), and `references/`'s own reconciliation
arithmetic. The `phase-handoff.md` gate gains row C″ for a state rows B and C′ both missed, where the
repair offer it fell to was a no-op on the branch the user was already standing on.

**Also:** `phase-handoff.md` stripped the host from a remote, so a GitHub Enterprise specs repo opened
its pull request against **github.com** — the same defect fixed in `code-handoff.md` in 3.12.0 and
missed in its sibling; it also had no existing-pull-request probe, so every branch-reuse re-run reported
"PR NOT opened" for one that was open. `/brd-interview`'s decision picker was the plugin's one
runtime-built array with no cap, exceeding `AskUserQuestion`'s four options at three options considered.
And the three-file release-note destination model still sat inside the authority that replaced it.

## [3.12.0] — 2026-08-31

### Fixed — the upstream review wave, audited against this edition

`mgd-claude-plugins` ran a four-agent Opus review over the same code-repo handoff this edition ported
in 3.10.0, and found **48 findings**. This edition inherited the pre-review version verbatim, so every
git-mechanics defect it found is one this tree also had. Each was re-verified here before porting;
three did not apply and are named below rather than ported blind.

**Four that would have broken a run:**

- **`/vuln` never told `vuln-fixer` which branch to create.** The agent would invent a name, the
  orchestrator would push the one *it* resolved, and the gate would fail on the mismatch — or worse,
  succeed and report a push that never happened. Branch naming now happens once, in Step 1 step 5,
  and is passed in both dispatches; the fixer never derives one, and returns `BLOCKED` when it is
  missing or collides.
- **`BLOCKED` means two opposite things**, and Step 3.9's skip list keyed on it. It is returned by a
  *first* fixer call that changed nothing, and by a *resume* call where the branch exists and the fix
  is already applied — and it is also the label the command writes for orchestrator-side stops that
  are explicitly required to hand off. What to hand off is now decided by **the tree**, not the label.
- **`/implement`'s post-branch stop exits all bypassed Phase 4.6** — including the persisting-`BLOCK`
  state Phase 4.6 itself names as a `clean_finish: false` case. Each now runs it before stopping.
  This edition's exit list differs from the upstream's and is written against its own: the repro
  prompt sits in Phase 2B, *before* the branch exists, and there is no abandon-and-restore arm here.
- **`/upgrade`'s per-component commit ran with no gate**, because the split sanctioned "§2.2–§2.3
  only". A caller whose branch creation had failed would commit its whole batch onto the default
  branch and only discover it at the terminal call. The gate is now inside the split.

**Git mechanics that were wrong, every one of them ported here verbatim in 3.10.0:**

- `symbolic-ref --quiet HEAD` prints `refs/heads/<name>`, which can never compare equal to the short
  name the ladder resolves — so the default-branch check **could never fire**. `--short` added, plus a
  check that HEAD is on the branch the caller named (`git commit` writes to HEAD, `git push -u origin
  <branch>` pushes the ref *named*; a mismatch reports a push that never happened).
- The base-branch ladder's lower rungs used `rev-parse`, which prints a **SHA**: `--base <sha>` is
  rejected outright and `git switch <sha>` detaches HEAD, the state the gate treats as blocking. They
  are existence probes; the literal name probed is what is used.
- The `OWNER_REPO` parse dropped `ssh://` remotes and **stripped the host**, so a GitHub Enterprise
  remote resolved against `github.com` — silently targeting an unrelated public repository if one sat
  at that path. Fixed here and at its root in `phase-handoff.md` §2.6, which carried the same
  two-expression form.
- The commit went through `commit -m`, which command-substitutes `$(…)` and backticks out of free
  text — and `/vuln`'s template interpolates an NVD CVE description straight into it. Now written to a
  file and committed with `-F`.
- The pull-request body file was referenced three times and produced nowhere; §2.7 now defines it.
- The writability pre-probe could strand finished work on a false positive; the real error is the
  trigger instead.

**Contradictions removed:** an undeclared `git add -A` divergence from two siblings that both forbid
it (now declared in §1, with the reason the bound moved rather than vanished); a staging prompt that
fired once per unit and offered a skip contradicting the unconditional commit; cached consent with no
re-ask trigger; a missing existing-pull-request probe; and obligation 3 against the split's
emits-none rule.

**One BLOCKER of this edition's own, surfaced by the same audit.** `grilling-technique.md` keyed the
open-question notation on *depth* — `[NEEDS CLARIFICATION]` for bounded callers, `- [ ]` for
relentless ones. `/idea --deep` switches `/idea` from bounded to relentless at runtime, so an
autonomous `--deep` run wrote `- [ ]` into an `idea.md`, left zero `[NEEDS CLARIFICATION]` markers,
computed `status: refined` — which `idea-format.md` defines as **iff** zero markers remain — and handed
an idea carrying unresolved decisions to `/create-prd`. The notation is now the **artifact's** choice,
never the depth's.

**Also fixed:** `docs-grounding.md`'s grill-rank claimed a challenge "competes for a question slot",
true only for `/idea` — the other five consumers grill to convergence, where rank orders what is asked
first and never how much. `/implement`'s documentation page still claimed 17 `## Phase` headings
against a tree with 19. And the `/vuln` path still parsed "Jira IDs" and carried `jira:` handoff
fields in a plugin whose design cut the tracker; increment B had recorded that as out of scope, and it
is now swept.

**Three upstream findings deliberately not ported**, because this edition does not have the code they
fix: the two-rhythm grilling model (here `--deep` changes depth, not rhythm), its round-ranking rule,
and its autonomous round-enumeration rule are all fixes to a feature harvest this edition never took.

## [3.11.0] — 2026-08-31

### Fixed — every `choices:` array now fits the prompt that renders it

`AskUserQuestion`'s schema is `minItems: 2, maxItems: 4`, and says in as many words: *"There should be
no 'Other' option, that will be provided automatically."* The plugin shipped a convention saying the
opposite — *"last choice is always `"Other… (describe)"`"*, stated in eight command files — which
authored **139 duplicate options across 30 files** and pushed **42 arrays past the cap**, while
`references/escalation-rules.md` simultaneously required every array be presented verbatim. A rule the
harness made unfollowable. A five-option array is not a long prompt: it is a tool call rejected at
validation, so the run cannot present it at all.

**`escalation-rules.md` §0 states the real rule** — 2–4 options, never an authored "Other" — and
retires *"adding the trailing entry is the one permitted adjustment"* along with the carve-out table
built on it.

**Two consequences that outlive the cleanup**, because the fix is not only arithmetic:

- **The free-text option is now unconditional.** Six closed-vocabulary pickers used to protect
  themselves by *omitting* it, and three of those are how a customer's authority enters the decision
  register — D14 exists because normalising prose into a register row is inference, and promoting
  inference to customer authority silently is the one way that workflow could fabricate a mandate the
  customer never gave. The harness supplies the option whatever the array says, so the protection
  moves from the array's shape to the run's handling of the answer: a free-text answer on those
  pickers is **normalised into the picker's own vocabulary, or the question is re-asked** — never
  written through as a value no consumer handles.
- **A fifth option moves rather than disappears.** `references/next-phase-offer.md` gains an overflow
  rule: the prose `### Next step` list — already that contract's "universal minimum" — carries every
  route, the array carries `Stop here` plus the three the run's own outcome makes likeliest, and the
  run says out loud that the list is longer than the prompt. Applied to `/brd-reconcile`'s two offers
  and `/update-prd`'s.

**The defect no static check can see, found while fixing the ones it can.** The progress-aware Epic
picker `/specify`, `/design` and `/implement` share is built from a directory listing — *"one row per
Epic"* — so a PRD with four Epics overflows a prompt that has no literal options to count, and
`/specify`, which appends its own option, overflows at three. `references/epic-picker.md` gains *The
cap*: every Epic listed as prose, the array carrying at most three rows plus one naming the remainder,
whose typed key is resolved against the keys just listed rather than parsed out of the answer.

**`scripts/check-docs.sh` gains check 12**, so the class cannot return: 2–4 options, no authored
"Other", across every markdown file in the plugin. Its parser is **bracket-matched and quote-aware
rather than a non-greedy regex** — `choices:\s*\[(.*?)\]` stops at a `]` inside an option string and
skips that array silently, which is how the census that motivated this work missed three live arrays,
two of them six-option, and reported 40 over-cap and 136 authored Others across 232 arrays when the
truth was 42 and 139 across 227. Its selftest pairs each
failure mode with a **green** case whose option text also contains brackets, because a skipping parser
passes the red case and the green one for the same wrong reason.

**Nine trailing `Cancel` options were dropped** from arrays that were over the cap. Where cancelling
had a documented consequence — `/brd-package`'s and `/brd-reconcile`'s walks both state one — the
reasoning moved into the prose introducing the walk, which is where it is visible without spending one
of four slots.

## [3.10.0] — 2026-08-31

### Fixed — the code repo's own commit, push, and pull request

Ported from `mgd-claude-plugins` 2.59.0, adapted to this edition. 3.8.0 introduced
`references/code-handoff.md` and got the shape of the problem right; it got two things about the
answer wrong, and left `/vuln` out of the file that was written to generalise `/vuln`.

**The commit is no longer something you can decline.** §1 rule 5 inverts 3.8.0's five-option choice:
committing is local and reversible, so it is not the user's to approve, and a prompt that can be
answered "no" at the end of a long run is exactly the failure this file exists to remove. Only the
push and the pull request leave the machine, and only they are asked about — one three-option choice,
asked once per run and reused for every later branch in it. `--no-commit` survives on `/implement`
and `/upgrade` as the single opt-out, typed rather than clicked.

**A run whose gates failed is still committed and still pushed.** 3.8.0 skipped the handoff entirely
on an unresolved BLOCKER, which left the work in a working tree in precisely the case where losing it
hurts most. §2.8 commits and pushes it like any other run and degrades only the pull request — opened
`--draft`, with `> ⚠ DO NOT MERGE — <the blocking fact>.` as the first line of its body.

**`/vuln` is now a caller, and two real defects in it are fixed.** `vuln-fixer` created its branch
*after* applying the fix, so every early return — `BUILD_FAILED`, `TEST_REGRESSION`,
`AWAITING_REVIEW`, and an orchestrator-side stop at an unresolved `BLOCK` — left the change
uncommitted on the base branch, breaking the plugin's own "branch created before any file is touched"
invariant on exactly the paths where work most needs saving. And each CVE branched off the previous
CVE's branch, so CVE N's diff, its Opus review, and its pull request all carried every earlier CVE's
fix. The fixer now branches at step 2, before its first edit, and stops there; Step 3 switches to the
resolved base before each CVE; and the commit, push, and pull request move to the orchestrator's new
Step 3.9, because the consent choice they sit behind is one no subagent can ask.

**`/upgrade` commits per component instead of once at the end.** Step 6.5 commits each component as
its own gates settle (`§2.11`'s split-call form) and step 7.5 pushes once for the batch, so a run that
dies on component three still has one and two committed, each with its own message, on a branch that
bisects. The old step 9a is gone.

**Mechanics the reference had left unstated**, all now specified: the §2.1 gate (read-only mount,
detached HEAD, never the default branch), §2.2's staging carve-outs for a dirty tree and a pushed
stash with `--untracked-files=all` enumeration, §2.7's base-branch ladder (`origin/HEAD` →
`origin/main` → `origin/master` → `origin/develop` — `/vuln` had hardcoded `main`), §2.6's `gh`
capability probe with §3.2's no-CLI fallback text, and §3.1's thirteen-case `Code repo:` outcome line.

**Stale claims retired.** `/upgrade`'s terminal step still asserted the upgrade changes were "left
uncommitted on the current branch by `upgrade-executor`, exactly as before" — false since 3.8.0's own
step 9a; its step 9a also read as skipping the whole batch's handoff when any one component reverted.
`implementation-format.md` §3 and its `CLAUDE.md` summary still said only `/vuln` could write a
compliant commit subject; all three write one now. Four documentation pages described the retired
five-option choice by name, and four more asserted something it made false; all eight are rewritten.

## [3.9.0] — 2026-08-31

### Removed — `$VAULT_PATH` (increment D)

Last of four increments implementing
`docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md`. **The plugin reads and writes
one tree.** `$VAULT_PATH` appears nowhere in it — not in a command, an agent, a reference, a hook or
a documentation page.

**A capability is lost, and it is the only one in this whole design.** `vault-prior-art-finder`
searched a personal store for tracked initiatives an idea should reconcile against, and fed `/idea`
and `/create-prd` a bounded digest. It was genuinely useful and it is gone. It was already advisory,
already optional and already a silent skip when absent, so nothing gates on it and no run breaks —
that is what made the deletion safe, not what made it free. **Prior art now means a PRD you hand the
command yourself, as a path.** Prior-art discovery over `specifications/**` is a plausible
replacement and a separate design; no half of it ships here.

- **The four emitter ladders lose their vault tier.** Feedback, cost and session-hygiene each lose one branch they already preferred `$SPECS_PATH` over, so a specs-resolved run is unchanged. **Follow-ups lose their *primary* tier** and everything shaped by it — the Obsidian-Tasks line with Fibonacci effort checkboxes, `#tags` from a vault's tag index, `P<NNNN>` project files, `Tasks.md`, `Journal.md`. A plain `follow-ups.md` checklist in the resolved folder is now the only tier.
- **`/idea` takes its key up front**, resolves the folder, and writes `idea.md` there on the first write — never relocated. The write-path gate, the container rule, `area_proposal` and `prd_disposition` go with it, and Phase 5's three-way handoff collapses to one.
- **The plugin description is rewritten**, not appended to: **883 → 810 characters**, which is the direction a rewrite after four deletion increments should go.
- **`gen3` leaves the docs-profile examples.** Detection was always generic; only the example was vendor-shaped.

### Fixed

- **A gap in 3.6.0.** Spec §6.1 said `/idea` takes its key up front and that the relocation phase, write-path derivation, container rule, `area_proposal` and `prd_disposition` all go with it. None of it had been done; `/idea` still validated `$VAULT_PATH` as its write root.
- **Eight mangled substitutions** left by 3.6.0's `--from-brd` sweep — `` `the BRD route <dir>` `` in five command sites and four docs synopses, where a flag name was replaced without regard for the surrounding grammar.
- A sentence in `prose-formatting.md` broken by the same release's vocabulary sweep (*"actively harmful in / on paste"*).

### Note for anyone who set `$VAULT_PATH`

**Nothing deletes your files.** The plugin simply stops reading them. What you lose is prior-art
discovery and the Obsidian task format for follow-ups; what you gain is that every artifact the
pipeline produces now lives in one git-tracked tree.

## [3.8.0] — 2026-08-31

### Fixed — `/implement` and `/upgrade` no longer abandon work in a dirty tree

**Two of the three commands that change code left the working tree uncommitted, and nothing anywhere
stated a reason** — not the commands, not their agents, not their documentation.
`agents/upgrade-executor.md` carried it as a bare invariant: *"Leave all changes uncommitted — no
git commits, no PRs."* Meanwhile `/vuln` committed **and** opened a pull request in the same plugin,
on the same kind of repository, and `phase-handoff.md` §4.3 already owned the consent-gated
commit + push + PR pattern the other two should have been using.

- **New `references/code-handoff.md`** — a consent choice offering commit + push + pull request (recommended), commit + push, commit only, or leave it uncommitted, executed against the **code** repository. Its mechanics are `phase-handoff.md`'s §2.4–§2.6 and §4.2, cited rather than restated, including the `gh` capability probe and its no-CLI fallback.
- **`/implement` gains Phase 4.6** and **`/upgrade` step 9a**, both after the review gate and the test run, both skipped on an unresolved BLOCKER and under the new **`--no-commit`** flag.
- **`upgrade-executor`'s invariant is re-stated as a division of labour**, not a policy about the work: an agent cannot prompt, so the commit decision belongs to the orchestrator.

**Why uncommitted was the wrong default, stated because it was never stated:** a stray `git checkout`
or a container restart loses an uncommitted tree, while a commit on a branch is recoverable by
anyone. Not opening a pull request is defensible on a host with no CLI; not committing is not — and
those are separate decisions, kept separate here.

**This also makes `implementation-format.md` §3 true as originally written.** The commit convention
needs the key in the subject so `/document` and `/release-notes` can find the work later; a command
that does not commit cannot write that subject, only ask for it. All three commands write it now.
The convention stays documented in `docs/reference/commit-convention.md` because an operator may
decline the commit, and because work arrives that no command ran at all.

### Fixed

- `--no-commit` and `--claimed` were both named in prose and parsed by nothing. Both are parsed now; `--no-commit` is stripped before any other argument handling, since an unstripped flag is read as free text or as a component name.

## [3.7.0] — 2026-08-31

### Added — what the tracker used to supply (increment C)

Third of four increments implementing
`docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md`. Increment B removed the tracker
and left three degradations in its own text; **this release closes all three**.

- **`implementation.md`** — new `references/implementation-format.md`, written by `/implement` in a new Phase 4.7 for keyed runs. An append-only pointer record: one block per run, one entry per repository, holding refs and never a summary. A ref cannot drift; a description can, which is why `source-truth.md` exists.
- **`/epics` mints Epic keys and writes `epic.md`** into `EPIC-<PRD-KEY>-NN-<eslug>/` under the PRD folder. Those folders **are** the linked-item hierarchy every other command now enumerates — a directory listing replaces an import. The output-directory question and its `$VAULT_PATH` ladder are gone: one home, derived. `_coverage.md` is PRD-holistic and lands beside `prd.md`, never inside an Epic folder.
- **`/document` and `/release-notes` diff again**, from two sources merged: the record, and a `git log --grep` scan for the run's own `key` and `workitem_key` — which is what finds work the plugin did not do. Two honesty rules: anything beyond the recorded blocks is reported as **unrecorded work**, and the run reports **how many commits it scanned and how many matched**, because a zero-match scan is a signal about the commit convention rather than proof that no work happened.
- **Release notes land in the PRD folder** as three sections of one `release-notes.md`, under a heading for the release version. The taxonomy is unchanged and `release-note-types.md` is still its authority; only where a draft lands changed.
- **`/ready` derives the workflow phase from the artifacts** and gains **`--claimed "<status>"`**, which was named in 3.6.0's prose and parsed by nothing. A claim *above* the derived phase caps the verdict; a claim below is reported and does not, because artifacts can legitimately run ahead of somebody's bookkeeping.
- **New `docs/reference/commit-convention.md`** — end your commit subject with `[<key>]`. Documented as a convention because a contributor who has never run the plugin must be able to write a findable commit.
- **`{{#context}}` is retired.** A docs-automation macro renders as literal text in a plain markdown file; a **Category:** label does the same job.

### Fixed

- **A spec defect found by execution.** §7.3.1 said `/implement`, `/vuln` and `/upgrade` all write the commit convention. They do not: `/implement` and `/upgrade` leave their changes **uncommitted**, so `/vuln` is the only command that commits into a code repository. The mechanism now matches — `/vuln` writes a compliant subject, the other two **state the convention at handover**, to the operator who writes that commit. *(That `/implement` and `/upgrade` leave work uncommitted at all is a separate defect, fixed next.)*
- `/ready` Phase 2 still read a declared status from fields that no longer exist; it now reads the per-Epic artifact inventory the derivation needs.
- `/implement`'s Epic picker can show ● again, now that `implementation.md` supplies the signal.

## [3.6.0] — 2026-08-31

### Removed — the tracker round-trip (increment B)

Second of four increments implementing
`docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md`. **No command reads a tracker any
more, by any mechanism.** `$SPECS_PATH` is the system of record; the plugin reads and writes one
markdown tree and calls no external service.

- **`agents/jira-reader.md`, `references/jira-input-resolution.md` and `references/prd-source-resolution.md` are deleted.** The shared input front-end is replaced by three lines in each command's own Phase 0 — parse one address, resolve it, branch on the kind — and `resolve-existing-prd` collapsed to *resolve the folder, read its `prd.md`*, which is two obvious lines and no longer earns a file.
- **`mode: jira-driven | direct` becomes `keyed | direct`**, the test being whether a positional address is present. `/document` and `/implement` keep both modes; the other four stop on a missing address exactly as they stopped on `mode: direct`.
- **The two-key argument grammar collapses** in `/ready`, `/design` and `/specify`: the resolved folder's kind decides the altitude, and the second key was always derivable from the first.
- **New `references/epic-picker.md`.** The progress-aware Epic picker was already artifact-based and policy-neutral; it lived in the front-end only because that is where key classification happened. `/implement`'s picker joins it — its done-predicate was an Epic's tracker status and is now the artifacts present, which is what `/design`'s picker already did.
- **The paste-and-re-import round-trip is gone**, with every instruction, reminder, conditional offer and now-vacuous `jira-products/` guardrail built around it. Next-step offers that were withheld pending an import are unconditional, because the commands they offer read the specs tree this run just wrote.
- **`issue_type` and `ValueIncrement` are retired** in favour of `kind:`, added alongside them in 3.5.0 so this could be a deletion rather than a swap.
- **`--from-brd` is retired as a flag.** The BRD route is a property of the resolved folder — it carries `brd-link.md` — so a flag restating it could only disagree with the folder it named. `--from-prd` survives: it names a *different* PRD to seed from, which no folder can decide on the operator's behalf.
- **`jira_key` becomes `key`**, and **`workitem_key` is added** — reserved, documented, preserved across every frontmatter rewrite, displayed in reports, and never minted, validated, or resolved by. **Unknown frontmatter keys are preserved**, stated in all three format authorities.
- **The three former mirror fields are authored here now.** `change_type` and `release_notes_category` are inferred and confirmed in `/release-notes`'s grill; `release_versions` comes from a new `--version` flag or the same grill. `prd-format.md` reverses its own rule, which forbade authoring them while the answer existed elsewhere.
- **`workflow-states.md` no longer names a tracker as the source of truth for status.** It is read in the direction its own *expected artifacts* column already supported, with `/ready --claimed "<status>"` named as what a tracker-keeping operator uses for the divergence check they otherwise lose.
- **`CLAUDE.md`'s two-grammar rule is retired.** It forbade widening a tracker-side check to accept three segments; with no tracker read anywhere, every check is folder-side and the defect family it guarded cannot occur. What survives is the reason: `pre-lint.md`'s collision grep reads like a key validator and is not one — it is an auto-link detector, and its narrowness is what makes it correct.
- **620 vendor-named tokens swept to zero in scope.** Three exceptions are deliberate and each records why: `/vuln` and `/upgrade` (out of scope, and a user-supplied ticket ID is a real thing); vault prior art (deleted in the next increment); and `branch-naming.md`, which quotes tokens a repository's *own* convention file may contain and whose job is to recognise them.

### Known gap until the next increment

`/document` and `/release-notes` have **no diff source**: PR URLs came from the tracker export, and `implementation.md` replaces them in increment C. Diff grounding was already opt-in and advisory in both, so this reduces an optional input to absent — and both now say so where they would have dispatched `diff-summarizer`, rather than producing an ungrounded draft silently.

### Fixed

- Five documentation pages named `*_NEEDS_JIRA` stop codes the commands never emitted.
- `/ready`'s body described a status-anchored gate while its own description said artifact-anchored.

## [3.5.0] — 2026-08-31

### Changed — one addressing authority for the whole specs tree (increment A)

First of four increments implementing
`docs/superpowers/specs/2026-08-31-specs-native-pipeline-design.md`. **The tracker round-trip is
untouched**: every Jira path still works exactly as before, which is what makes this increment
shippable on its own.

- **`references/brd-addressing.md` becomes `references/addressing.md`** and addresses the whole tree — BRD, PRD and Epic folders alike — rather than BRDs only. Three entry points: `key-valid`, `resolve-key`, and the caller-facing `resolve-address`. Every citation across the tree follows, including the section renumbering.
- **Directories carry a kind prefix** — `BRD-`, `PRD-`, `EPIC-` — under two invariants: kinds run in a fixed order down any path, and no path holds two folders of the same kind. The tree is therefore at most three levels deep, and resolution is bounded by that constant rather than by anything about a key.
- **One address, two forms.** A command takes `<KEY>`, resolved against the tree, or `@<path>`, used verbatim with no glob and no ambiguity. Two folders sharing a key is a hard stop naming both, with `@<path>` named as the way through.
- **A folder asserts its own key.** Every artifact carries `kind:` and `key:` frontmatter, and the command that creates a folder writes a keyed artifact into it in the same act — so nothing parses a key out of a directory name.
- **Filenames lose their keys**: `prd.md`, `ard.md` (`ard-<area>.md` when area-scoped), joining `specification.md` and `design.md`, which already worked this way. Three glob-based resolvers collapse to filename tests.
- **A slice's folder is its PRD folder.** `/brd-split` creates `PRD-<CHILD-KEY>-<slug>/` directly inside the BRD instead of a nested BRD folder holding a PRD folder holding one file.
- **A BRD is a container, never implementable.** `/brd-split` always produces at least one slice; where nothing clusters, the whole BRD becomes one. `covered-here` leaves the parent's picker, which becomes a different four rather than a smaller five. PRD eligibility is now a property of a slice.
- **`/brd-split` enumerates children by a positive test** — a subdirectory carrying a `brd-link.md` whose `parent:` names this BRD — never by a name match. A name match plus an absent-file-reads-as-empty inference could count an Epic folder as a standing empty child and offer to remove it, deleting `epic.md`, `specification.md` and `design.md` with it.
- **`design/` is a reserved subdirectory, defined once.** `references/grounding-format.md` §6.1 fixes where exported design frame sets live for any folder under `specifications/`; the location had been stated inside `/brd-ground` and was undefined for the `/idea` route. Location only — `design-grounder` is still dispatched by `/brd-ground` alone.
- **Nine hand-rolled folder-match rules deleted**, not re-pointed. Each was a local copy of the rule the addressing authority owns, which is the drift that family of defects is made of.

### Fixed

- `docs/commands/brd-split.md` cited the addressing reference through a markdown link, where the `)` between filename and section number defeated the citation sweep.
- Three resolution steps carried a `resolve-address` call followed by the fallback prose it replaced, contradicting themselves mid-sentence.
- `/create-prd`'s copy of the PRD-eligibility table had drifted from the authority it mirrors.

## [3.4.4] — 2026-08-31

### Changed — three ideas ported back from the upstream grilling technique

3.4.3 recorded where `references/grilling-technique.md` diverges from the
`mattpocock-skills:grilling` it forks, and closed with "read upstream for ideas". These are the
three ideas, taken deliberately. **Each arrived in part, never whole, and the half left behind was
the same one every time — whatever depended on asking a full round at once.**

- **Ask from the frontier.** The *frontier* is every decision whose prerequisites are settled — the
  questions answerable now without guessing at an answer not yet heard. Ask **one**, then recompute.
  This replaces "walk the decision tree in dependency order" with the same rule **named**, which is
  what turns "is this askable yet?" into a test rather than a feeling. Upstream asks the *whole*
  frontier in one round; that half is not ported.
- **Fetch a fact rather than asking for it.** The fact-vs-decision split said facts are yours to
  resolve; it did not say what to do when resolving one needs more than a read. It now does: where a
  fact needs a sweep, dispatch for it — a question that hands the user a lookup spends their turn on
  the half of the work they are worst placed to do. **Bounded to a fact a question actually being
  asked turns on**, so a speculative dispatch is cost with no question behind it. Upstream's
  *don't block on the dispatch* half is not ported: it works by asking the rest of the frontier
  meanwhile, which one-question-at-a-time has no way to do.
- **`Q<n>/<cap>` numbering, bounded callers only.** A bounded question renders as `Q3/5`, `Q7/10`, so
  the user sees what they are committing to before answering. **The denominator is the cap, not a
  plan** — a bounded grill that converges at `Q2/5` is finished, not truncated. A relentless caller
  has no denominator (`Q4/?` is noise) and numbers nothing.

**Where the fetch clause does *not* fire, said where it would otherwise look like a gap.**
`/brd-split` Phase 1 states that no agent but `impl-maintenance` runs in that command; its Phase 1.5
reads a row's `text`, `source_anchor` and disposition, all local reads of files the run already
holds. Nothing there reaches for something a sweep would find, so no dispatch arises and that
statement stays literally true.

## [3.4.3] — 2026-08-31

### Changed — the grilling technique records why it is a fork of the now-official upstream

`mattpocock-skills:grilling` ships in the official marketplace, and
`references/grilling-technique.md` has always said it was "adapted from mattpocock grill-me/grilling"
without saying **where it diverges or why**. That omission is the whole gap: the next reader who
notices the upstream skill either re-derives the comparison or proposes a swap that would silently
change eight commands.

The file now carries the comparison — cadence, depth, the no-human-turn case, altitude — and says
which way to jump on each. Three of the four rows are **caller management upstream has no reason to
carry**: this plugin invokes the technique from eight commands at three depths, one of which may run
with no human turn available, and a single-context skill has nothing to say about a `≤5` cap or about
what to write when nobody is there to answer.

**The cadence row is recorded as a genuine disagreement, not a win.** Upstream batches a computed
*frontier* of questions in one numbered round; this file asks one at a time. For the relentless
callers upstream may well have the better of it — numbering plus a per-question recommendation
answers this file's own "a firehose is bewildering" objection. It is not adopted because
`/brd-split`'s ledger walk is the one caller that is both a grilling caller and a never-batch caller,
and a cadence that differs by caller is worse than one that is merely debatable.

Also recorded: adopting it wholesale would cost the plugin its self-containment. Grilling is
**mid-run in eight commands**, which is a different risk from `/prompt-brainstorm`'s single terminal
hand-off to `superpowers:brainstorming` — the precedent the swap would be reasoned from.

`references/dependencies.md` gains an *Attribution, not a companion* section so `mattpocock-skills`
is not mistaken for an uninstalled dependency: nothing resolves it at runtime, nothing degrades when
it is absent, and installing it changes no behaviour. `references/bug-diagnosis.md` is named there
too, on the same footing.

## [3.4.2] — 2026-08-31

### Fixed — five documentation stalls, four of them created by this release line

A dedicated pass over `docs/` for the claims `scripts/check-docs.sh` structurally cannot see: it
gates links, anchors, inventories, counts and identity, never whether a page's *claims* still match
the thing that runs. Four mechanical sweeps came back clean — every stop code a page names exists in
a command, no page under-reports a dispatched agent, no page documents a flag its command does not
parse, and every produced-artifact table matches its command's `deliverable_paths`. What the sweeps
did **not** cover, and what these five were found by, is prose describing an artifact's internal
structure and an authority's scope.

- **`/brd-split`'s produced-artifact bullet described the old `slices.md`.** 3.4.0 added a third
  block — the slicing instruction verbatim, with how it was read — and updated the synopsis, the
  mode table, the flow diagram and the example, but not this. The rationale line was stale too: a
  group a slicing instruction placed carries what in the instruction placed it, not a
  buildable/blocked/depends-on reading.
- **`grilling-technique.md`'s one-liner said "every authoring command (and `/prompt-grill-me`)".**
  3.4.0 added `/brd-split` as a caller, and `/brd-split` is not an authoring command — it grills a
  slicing instruction against a BRD's own rows. The line now names the callers and the depth each
  declares.
- **`bundle-packaging.md`'s one-liner omitted its content allow-list.** 3.3.2 made §1.1 the rule
  that decides what may reach a customer, and 3.4.1 added §2.1's byte-for-byte source copy; neither
  reached the summary a reader consults to decide whether to open the file.
- **`coverage-ledger-format.md`'s one-liner omitted §3.1.** 3.4.1 made it the rule two commands read
  to scope a round and a review, and it is the reason a delegated requirement no longer reaches the
  customer in two packages.
- **`grounding-format.md`'s one-liner omitted §4.1** — the three ways a baseline finding differs
  from a claim finding, added in 3.3.2.

**Why the summaries matter enough to gate on.** A reference one-liner is what a reader consults to
decide whether the file answers their question. One that omits the file's newest rule sends them
away from the answer, and the omission is invisible to every check in `scripts/` — it is prose about
prose.

## [3.4.1] — 2026-08-31

### Fixed — six defects from a third round, scoped to the surface two rounds had not read closely

Rounds 1 and 2 swept the six commands, the BRD references and three of the six agents in full. This
round read what was left: `/brd-reconcile` Phases 4–8, three agent bodies, the delivery note,
`bundle-packaging.md` §4–§5 and `customer-review-schema.md` §5–§6. Every finding below is in that
remainder.

- **A section-12 row could instruct an edit this command may not make.** Phase 6 sorted correction
  targets into three classes and put `decisions.md`, `coverage-ledger.md`, `brd/brd-inventory.md`
  and `brd-link.md` in the "live working document — corrected in place" class. Each of those carries
  fields another rule fixes: allocation belongs to `/brd-split`'s walk and this command writes
  exactly three ledger dispositions; an inventory row's `text` is the requirement **verbatim** from
  the immutable source, so rewriting it edits the customer's document in the one place it is
  mirrored; a register record moves only through this command's freeze, §4's two reopening causes,
  or the sweep's four dispositions; `parent:` and `claims:` are `/brd-split`'s. The class is now
  split per field, with `refused-with-reason` on each, **naming the channel that does carry the
  substance** — a `[CD#n]`, a `customer-amended` defect resolution, a `/brd-split` walk. What is
  refused is the edit, not the change. This is the same carve-out 3.3.3 added to the stale
  cross-reference sweep; that sweep reaches these files by a text match the command made, while this
  phase reaches them by an instruction the **customer** wrote, which is the channel with external
  authority behind it and the worse one to leave open.

- **A customer decision could not overturn an earlier customer decision.** Phase 5 reopened only
  `[VD#n]`, though `decision-register-format.md` §3's statuses govern "each `[VD#n]` **and**
  `[CD#n]`" and §4 admits an incoming customer decision as a reopening cause. The case is the
  corrected resend Phase 2 explicitly calls an ordinary state: two reviews of one date, or a
  corrected file weeks later, answer the same `[C]`, and Phase 4's skip rule covers only an earlier
  pass over *this same review*. So a second `decided` `[CD#n]` was minted for one question — two
  customer answers one record has no way to hold, arriving through the affordance built to accept a
  correction. The earlier record now takes `superseded` where the new answer replaces it and
  `reopened` where it contradicts without replacing, and the reconciliation record says which.

- **The third id shape was unmatchable.** Phase 3 states that section 7 carries three id shapes and
  argues at length that dropping the third would look like customer silence — but
  `customer-review-reader` was given neither the self-review path nor an `[SR#n]` value in its
  `answers` field, so every answer to a deliberately escalated finding came back `unmatched`. A rule
  shipped whose consumer never gets the data. The agent gains `package.self_review`, matches all
  three shapes, and reports which question sets it was given, so an unmatched row can be told from a
  question set nobody passed.

- **`bundle-packaging.md` §5 sent the reader to the wrong commit entry point.** It said the bundle is
  committed "through the commit entry point `references/specs-repo-git.md` owns" — but that
  reference's §2.1 bounds staging to three path shapes, all under `dev-workflows/**`, and a bundle is
  under none of them. The bundle is a **deliverable** and travels through `handoff-to-main` behind
  its consent choice. The repair a reader would reach for is widening §2.1, which would let the
  prompt-free bookkeeping step commit a customer-facing deliverable with no consent in front of it —
  exactly the boundary the two references were split to hold. "Committed" also now means "where the
  operator accepted the handoff", since declining leaves the bundle written and uncommitted.

- **`commit` was listed as a universal finding field.** §2 notes `class` and `cites` as
  design-grounding-only but gave `commit` no applicability note, while `grounding-verifier`'s Inputs
  table, `/brd-ground`'s Phase 7 dispatch and `design-grounder`'s own process all treat a class-1/2/3
  `[DG#n]` as pinned to no commit. That matters because the verifier **honours** a commit it is
  given: a design-only finding carrying one would be re-derived against a repository it was never
  checked against. Fixed in §2, `design-grounder`'s output, `grounding-verifier`'s output and
  `/brd-ground`'s write phase.

- **A `[CD#n]` does not record which review froze it.** Phase 2 claimed the canonical name meant a
  `[CD#n]` frozen from a corrected resend "is never mistaken for one frozen from the file it
  replaced" — but §1 fixes eleven fields and none names a source document. The mapping lives in the
  reconciliation record, whose per-pass heading names the review file; Phase 2 now says so, which is
  what Phase 4's skip rule actually keys on.

## [3.4.0] — 2026-08-31

### Added — `/brd-split <BRD-KEY> [<instruction>]`, a verbal slicing instruction

`/brd-split` accepts an optional trailing instruction in the operator's own words —
`cover orders and measurements in the first iteration`, `slice everything no child covers`. Omit it
and the command behaves exactly as it did before, on every path.

**It seeds two things and decides nothing.** In `full` mode it seeds the Phase 2 grouping and the
Phase 4 walk's per-row recommendation; in `allocate-only`, where Phase 2 never runs, it seeds the
walk alone — which is what makes it a real argument on a slice rather than an ignored one.

**New Phase 1.5 reads it in two steps.** *Step A* places every row the instruction plainly
determines and raises no prompt — the fact-vs-decision split `grilling-technique.md` already
mandates, applied before the grill rather than inside it; a set operation over the ledger resolves
entirely here and asks nothing. *Step B* grills only the residue, bounded, **≤5 and gated on a value
test: ask only where one answer places more than one row.**

**The value test is the real gate, and the fallback is why.** Phase 4 visits every unallocated row
one at a time regardless, and Phase 2's picker moves rows by hand, so an unplaced row costs nothing
that was not already being paid and a question disambiguating a single row spends a turn to save a
prompt that is coming anyway. That also sizes the cap against `/idea`'s ≤10: there an unresolved
bounded question ships as a `[NEEDS CLARIFICATION]` marker inside the artifact, so the cap buys a
hole in the deliverable; here the residue has a free fallback. `grilling-technique.md` gains
`/brd-split` as a bounded caller and states that a caller's cap is sized by what its residue costs.

**The instruction proposes; the grounded picture constrains.** Where a placement puts a
`NOT-PROVABLE`, `REWRITTEN`, `FALSE-FRIEND` or `will-change` row into a group whose other rows are
buildable now, Phase 2 names those rows with the verdict or prerequisite that blocks each and asks
include-anyway / hold-back / decide-per-row. The operator's grouping wins where they confirm it and
never silently — a slice that quietly mixed a blocked row in with buildable ones would discard the
one signal that makes a slice worth carving.

**Phase 4 gains a `<recommended>` placeholder**, resolved per row exactly as `<merge-clause>` and
`<BRD-KEY>` are substituted, so the array is still presented verbatim. It is **not** a reversal of
3.3.2's markerless picker: that marker was removed for printing its own condition for the operator to
evaluate, which `escalation-rules.md` calls malformed; a marker the command computes and prints bare,
with its reason, is the fix that rule prescribes — and it exists only because there is now an
instruction to compute it from. On a run with no instruction the `full` picker is byte-for-byte what
it was. The `allocate-only` picker's standing `covered-here` recommendation now reaches the option
through the same placeholder rather than being written into it, so an instruction can never put two
contradictory markers in one list. `escalation-rules.md` records the placeholder mechanism, so a
per-row marker is not "corrected" later by someone reading the verbatim rule alone.

**Nothing is invented for a row the reading could not place.** It is left unclustered and walked with
no recommendation — the fate a row nothing clusters with already had. No new marker vocabulary
reaches a ledger or an inventory whose field sets are fixed elsewhere. `slices.md`, the handoff facts
and the final report carry the instruction verbatim alongside how it was read: rows placed directly,
rows the grill settled and by what terminology decision, and rows left unplaced. Where a path
swallowed the instruction — the no-op, or a run with no `unallocated` row — it is reported unused,
naming that path, because an instruction typed and silently discarded is indistinguishable from one
the command failed to parse.

## [3.3.3] — 2026-08-31

### Fixed — seven defects from a second review round

Two of the seven are defects the 3.3.2 round introduced; they are marked as such.

- **A split parent questioned and packaged requirements it does not own.**
  `/brd-interview` generated its round from "the findings and the inventory" and `/brd-package`
  stated review scope from the ledger and the inventory, neither reading the `disposition` column.
  On a **slice** that is correct — its inventory is exactly the rows it claims — and on a **split
  parent** it is over-broad, because the parent's inventory still holds every `[BR#n]` its own walk
  delegated. So a delegated requirement was questioned at both levels and put to the customer in two
  packages: the contradiction `interview-tagging.md` §5 names, reached across levels instead of
  within one, costing two `[VD#n]` records in two registers that can disagree with nothing linking
  them. `coverage-ledger-format.md` gains §3.1 — a `covered-by` row's requirement leaves this BRD's
  scope as a *subject* while staying readable as context — and both commands read the `disposition`
  column, never the inventory and never `claims:`. New stop `BRD_INTERVIEW_ALL_DELEGATED` for the
  state scoping makes reachable: a BRD that kept nothing has nothing to decide, and an empty round
  record is permanent and append-only.

- **The propagation sweep could not reach a child.** `/brd-reconcile`'s ledger phase says a
  `covered-by` row whose obligation the customer just withdrew is named in the owning BRD by "the
  propagation sweep" — but that sweep found only BRDs declaring `depends-on:`, and a child declares
  `parent:` and `claims:`. A customer withdrawing a delegated requirement therefore left the owning
  BRD still grounding, interviewing and packaging an obligation that was gone. The swept set now has
  two sources: the declared-dependents scan, and a **lookup** over this ledger's own `covered-by`
  keys — no scan needed, because that relation is listed in this BRD's own folder, which is exactly
  why it was missed.

- **The stale cross-reference sweep could write what two other rules forbid.** Its scope is every
  markdown file under the parent and names "the ledger" and "the inventory" outright, while its
  `updated` outcome is guarded only by `require-on-main` — which passes on a merged file. So a hit
  on a ledger `disposition` licensed the cross-BRD ledger write the same command's previous phase
  prohibits, and a hit on an inventory row licensed an edit to text that mirrors an immutable
  source. Hits inside a ledger disposition, an inventory row's `id`/`text`/`source_anchor`, and a
  register record's `status`/`chosen`/`evidence` are now `needs-a-human`. `updated` is for prose.

- **The customer's own source document was being de-Obsidianised** *(introduced in 3.3.2)*. The
  §1.1 allow-list put `brd/source/<basename>` in the bundle without exempting it from the rendering
  pass — but every `[BR#n]` anchors into it by heading path or line range, so a rendered copy breaks
  the traceability the file is included to support; it is immutable by rule; and it is the
  customer's own writing going back to them reformatted. New §2.1: copied byte for byte, with
  anything a plain reader cannot open named in the manifest instead. The plugin-free scan gains its
  only exemption for the same file — a hit there is the customer's own text, so it is reported for
  the operator to decide rather than deadlocking a BRD that can never be repackaged.

- **Two files the allow-list added were resolved nowhere** *(introduced in 3.3.2)*. `/brd-package`
  Phase 0 now resolves `brd/source/` and `brd/brd-defect-log.md` — one hop up on a slice — so an
  absent one is reported before a prompt is built. The returned-review date ladder now rejects a
  filename date matching **any** packaging date in the folder, not only the most recent: a review
  may legitimately answer an earlier package and would echo that package's stamp.

- **`CLAUDE.md` named two of the four commands that need a minted tracker key.** `/epics`,
  `/release-notes`, `/design` and `/ready` are all jira-driven-only front-end consumers; the map
  line read as though `/design` and `/ready` ran on a BRD key. `/specify --from-brd` and
  `/create-ard --from-brd` already test for the export before naming one.

- **`/specify` named an artifact nothing writes** — "`/design` → `design.md` + `plan.md`".
  `plan.md` appeared exactly once in the plugin and nothing produces it.

## [3.3.2] — 2026-08-31

### Fixed — thirteen defects from a whole-feature review of the BRD route

A comprehensive review of everything the BRD-to-PRD route shipped, read against the tree rather
than against the plan. All three gates were green before and after; every one of these is content
no gate can see.

**Outward-facing and authority-level.**

- **The customer bundle could ship the self-review.** Its content set was a deny-list — "this
  package's own documents", with the delivery note as the only named exclusion — and the
  documentation asserted outright that `self-review-<date>.md` was in the bundle. That file holds
  every `[SR#n]` the adversarial pass raised, including the ones disposed `rejected-with-reason`,
  whose reason "stays inside the delivery organisation. Nothing rejected reaches the customer".
  The prompt's parts 7 and 9 carry a **filtered** set for exactly that reason; shipping the file
  defeated the filter and handed the customer an internal disagreement to referee. The plugin-free
  scan could never have caught it — it hunts plugin-internal tokens, and a self-review has none
  while being the most internal document the command writes. `bundle-packaging.md` §1.1 is now an
  **allow-list**, derived from the rule that a document reaches the bundle only where a prompt part
  sends the reviewer to it, with the self-review excluded by name and by reason.
- **A returned review was dated by when the package was sent.** `/brd-reconcile` derived the
  review's date from the supplied filename first, and `/brd-package` stamped that filename with its
  own packaging date — so the ordinary path, a customer returning the file unrenamed, produced the
  date the delivery team *sent* the package, which the same phase says the date must not be. It
  also fired the same-date suffix prompt on reviews returned weeks apart, telling the operator both
  were "genuinely written on the same day". Fixed at both ends: the schema and the prompt ask the
  reviewer for the date they finish, and the ladder reads the review's own section 1 first,
  rejecting a filename date equal to the packaging date rather than trusting it.
- **A shared authority contradicted the command it governs.** `escalation-rules.md`'s
  closed-vocabulary carve-out listed five arrays and declared itself closed, so its own "one
  permitted adjustment" rule instructed an orchestrator to add `"Other… (describe)"` to
  `/brd-package`'s degradation-tier picker — a sixth such array, whose command forbids exactly
  that. Added as a sixth row. A rule contradicted by its own authority is not a rule.

**Claims with an expiry date, swept by phrase.**

- **The three altitude seed files have no producer on the live route.** Only
  `/brd-intake --sort-existing` writes one, and the route overview already said so — but four
  places asserted the opposite, three commands routed skipped content to "its own seed's consumer",
  and three input bullets described a seed as what the router "sent here". Nothing broke, since
  every consumer already tolerated absence; but a reader told a decision was routed to a seed goes
  looking for a file that is not there and concludes the content was lost. Every such sentence now
  names the real channel — `decisions.md`, filtered by each record's `altitude`, plus the grounding
  files and the derivation matrix — and the design's §7.2 router table is recorded as the unbuilt
  half rather than left to read as a description of what runs.
- **`/brd-ground` still said "nothing in this increment freezes a decision".** `/brd-interview`
  writes the register and `/brd-reconcile` freezes `[CD#n]` in it; both ship. The
  no-frozen-decision case is still ordinary — a prerequisite is declared while it is in flight —
  but that is sequencing, not absence of the capability, and the two are now reported apart.
- **"Frozen" had no definition**, though the register has carried the exact field since increment
  2. `grounding-format.md` §5 now fixes it as `status: decided` and nothing else, with each
  exclusion sourced to `decision-register-format.md` §3; `/brd-ground` and `code-grounder` read the
  field instead of judging how settled a record sounds, and an unparseable register is reported as
  unparseable rather than as empty.
- **`/brd-split`'s description still described the one-part no-op** and offered grounding "on each
  new child" — both superseded by the standing-empty-child work, which swept the phase bodies and
  the docs page but not the frontmatter. The same one-part claim stood in
  `coverage-ledger-format.md` §4 and in `/brd-ground`'s row-F clause, where it was reachable and
  wrong: a slice claiming nothing makes the parent re-run live, so that clause now branches on the
  slice's own `claims:` list.

**The rest.**

- **`/brd-reconcile` presented ten options in one array** — more than double any other list in the
  plugin, offering advance into the PRD pipeline in the same breath as naming four reasons the
  route is not finished. Split into two mutually exclusive lists on a resolved `advance_ready`,
  each six options, with every re-entry option dropped where its trigger did not fire. Dropping the
  three `--from-brd` options on the re-entry path is a refusal **only this phase can make**:
  `/create-ard --from-brd` and `/specify --from-brd` run no gate that catches a reopened decision,
  since routing an `open` record into their own open-questions section is correct behaviour rather
  than a stop.
- **A conditional `(Recommended when …)` marker** on `/brd-split`'s full-mode ledger picker, which
  `escalation-rules.md` calls malformed by name — it hands the operator the gate the phase was
  supposed to evaluate and cannot be honoured verbatim. The condition moved into the option's text
  and the marker is gone; the `allocate-only` picker keeps its, because there `covered-here` is
  genuinely unconditional.
- **`/brd-interview`'s guarantee 3 contradicted its own Phase 6**, saying the operator queue "is
  never appended to mid-round from another tag" when a re-tagged `[G]` is supposed to arrive.
  Restated as what is actually guaranteed.
- **`/brd-ground` Phase 10 branched on a `parent:` field its cited step never took.** Step 9 read
  `depends-on:` only, and the two steps that do read `parent:` sit inside branches that stop, so on
  the ordinary path neither had run. Step 9 now carries both.
- **The baseline `[CG#n]` findings can never be consumed**, so `/create-ard`'s and `/specify`'s
  unconsumed-item reports listed one permanently-open item per repository on every run, with no
  action that could close one. `grounding-format.md` gains §4.1 and both reports exclude them.

## [3.3.1] — 2026-08-30

### Fixed — a slice's withdrawn claim no longer strands its ledger row

`/brd-split` Phase 3 writes a child's `claims:` list **provisionally** and seeds one `unallocated`
ledger row per claimed `[BR#n]`. Phase 4's walk settles each requirement on the parent's ledger and
may settle one away from the child that provisionally claimed it. What became of the child's ledger
row was ambiguous, and both readings were wrong:

- Deleting it violated `coverage-ledger-format.md` §2 ("never deleted and never renumbered") and
  erased that the slice had ever claimed the requirement.
- Keeping it at `unallocated` left `/brd-split` unable to complete on that slice for good (§4 blocks
  while any row is `unallocated`), with `/brd-ground` and `/brd-interview` gated behind it — the
  slice permanently unresolvable.

The row is now **kept and always terminal**: it takes the disposition the parent's walk settled on.
Where that is `covered-by`, the disposition is widened rather than the row deleted — `covered-by`
is now legal on a slice, naming **a sibling under the same parent, or that parent**, and written by
the **parent's** walk, never the slice's own. §3's prohibition existed because a slice has no
*children*; naming a sibling or a parent is a different relation, and no key a slice writes ever
names a child, so nesting stays capped at one level.

A slice's own picker is unchanged at four resolutions. Letting a slice delegate would put a second
`covered-by` in the path of a parent's roll-up and turn D23's single hop into two.

Also fixed:

- An orphan row carrying the parent's `superseded-by` could name a `[BR#n]` the slice never
  claimed, which §6.3 said could not exist. Both carried-across dispositions now resolve one hop
  up, as an inherited `[DEF#n]` already did.
- `/brd-split` Phase 7 (allocate-only) claimed there was "no `covered-by` key to follow", which the
  same file contradicted 160 lines later.
- `/brd-ground` was offered "once per child the run created"; a child left holding only orphan rows
  is a standing empty child, and grounding it stops at `BRD_GROUND_EMPTY_INVENTORY`. Now offered
  only for non-empty children.
- The `BRD_GROUND_EMPTY_INVENTORY` doc page dropped the qualifier that once the parent's ledger has
  no `unallocated` row left, removal is the only thing that can change a standing empty child.

Recorded as **R24**, amending **D23**.

## [3.3.0] — 2026-08-30

### Added — the BRD route reaches the PRD pipeline (increment 3)

Increment 2 ended at a reconciled, decided BRD whose seeds were ready and whose only reader was a
human. This increment connects it to the pipeline that was already there. `--from-brd` on
`/create-prd`, `/create-ard` and `/specify` carries a reconciled BRD into a PRD, an ARD and a
specification, so the route now runs `/brd-intake` → `/brd-ground` → `/brd-split` →
`/brd-interview` → `/brd-package` → *(the customer reviews it off-platform)* → `/brd-reconcile` →
`/create-prd --from-brd` → `/create-ard --from-brd` → `/specify --from-brd`, and from there feeds
`/epics`, `/design` and `/ready` exactly as the `/idea` route does.

- **`--from-brd` is a switch, not a path.** On all three commands the positional token becomes a
  **BRD key** — two segments for a parent (`EPIC-008`), three for a slice (`EPIC-008-01`) — and
  `references/brd-addressing.md` §2 resolves it to a folder, so `/create-prd EPIC-008-01 --from-brd`
  needs no path at all. A directory may still be given for a BRD that sits outside the normal
  layout. On `/create-prd`, `--from-brd` and `--from-prd` are two seeds for one document and are
  mutually exclusive.
- **`/create-prd --from-brd` — the reconciled BRD becomes a PRD, through the same gate.** It reads
  `prd-seed.md` and `decisions.md` from the resolved BRD folder, profiles to `--full` unless a flag
  overrides it, restricts the grill to what the seed does not settle, and may **not** reopen a
  `[VD#n]` or a `[CD#n]` — a customer signed those off in the review the seed came from. Two Phase 0
  refusals guard it: a ledger row still `unallocated`, and a ledger with no
  `covered-here` row at all, which reports **where the requirements went** per
  `coverage-ledger-format.md` §5 rather than assuming they went to children — a BRD that was never
  split and a slice that deferred everything both reach that state with no child to name. The
  `prd-reviewer` Opus gate is the same one the `/idea` route passes; `prd-format.md`'s
  no-implementation-detail rule is not relaxed, which is what the ARD and specification seeds exist
  for.
- **`/create-ard --from-brd` and `/specify --from-brd`.** Each reads its own altitude's seed —
  `ard-seed.md` plus the architecture-altitude findings, `spec-seed.md` including its derivation
  matrix — and marks every item it draws on `consumed_by: ARD` or `consumed_by: specification`.
  Neither carries `/create-prd`'s refusals: neither reads the ledger, dispatches `jira-reader`, or
  runs the PRD gate. Each of the three closes the loop by reporting, by id, what at its own altitude
  is still `consumed_by: none`, so "nothing was lost" stays checkable rather than hoped for.
- **A PRD authored from a BRD carries that BRD's identity in its frontmatter** — `brd_key`,
  `brd_parent` and `depends_on`, written from the BRD's own `brd-link.md`, and written only by
  `/create-prd --from-brd`. They record committed BRD provenance on the PRD itself, and **no command
  consumes them yet**: neither `/epics` nor `/ready` reads any of the three, and wiring a consumer is
  separate work with its own review. Recording the provenance now is what makes such a consumer
  possible at all — re-deriving it later would mean re-reading a BRD tree that may have moved on.
- **A nested BRD folder is now visible to every command that resolves a PRD directory.**
  `references/brd-addressing.md` §4's one-level-deep fallback was defined but marked not yet
  adopted; it is now adopted in **twelve files** — nine commands (`/create-prd`, `/update-prd`,
  `/create-ard`, `/epics`, `/specify`, `/design`, `/ready`, `/idea`, `/release-notes`) plus three
  shared authorities: `references/ard-resolution.md` and `references/jira-input-resolution.md`,
  through which `/implement` and `/document` adopt it by delegation without resolving a PRD
  directory of their own, and `references/prd-source-resolution.md`, which resolves the frozen specs
  draft for `/update-prd` and `/create-prd --from-prd` and so needed the fallback in its own right.
  **The adoption is additive:** the fallback is reached only where the flat
  match already returned nothing, so a key whose folder sits directly under `specifications/`
  resolves exactly as it did before, and a command that creates the folder it did not find still
  creates it flat — the fallback honours a nested folder that exists, it never proposes one.

### Fixed

- **Two keys, two uses — a BRD key never reaches a tracker path.** Folder identity (a BRD key, which
  may carry three segments) names a folder under `$SPECS_PATH` and is validated for shape only.
  Tracker identity (`jira_key`, minted by the tracker, two segments) resolves
  `jira-products/<jira_key>` and is the only key `/epics`, `/release-notes` and `jira-reader` may
  receive — that agent validates `^[A-Z][A-Z0-9_]*-\d+$` and refuses a three-segment slice key on
  sight. The round-trip declared the split and then every downstream reader on the route kept
  substituting one for the other: `/create-prd`'s re-import step built `jira-products/<KEY>` from a
  folder address, its Phase 6 offered `/epics` and `/release-notes` with a key those cannot resolve,
  and `prd-source-resolution.md` reached a tracker path before any tracker key had been resolved.
  Each site now uses the key its own destination requires, and where no `jira_key` has been minted
  the option is withheld and the round-trip named as the step that unblocks it, rather than offered
  with a key that would fail.
- **`/update-prd`'s key grammar no longer dead-ends `/create-prd`'s own redirect.** `/create-prd`
  offered `/update-prd <BRD-KEY>` as the recommended option on finding an existing PRD, and
  `/update-prd` then hard-stopped on the three-segment key. Its validation, and the same regex in
  `references/prd-source-resolution.md` which it executes, now use `brd-addressing.md` §1's grammar —
  a superset, so a two-segment refresh behaves exactly as before. `ard-reviewer`'s `prd` field was
  widened with them — on the `--from-brd` route it holds a BRD key. Those three are every folder-side
  site. `references/ard-format.md`, the format authority for the ARD's own frontmatter, now specifies
  both shapes rather than only the pre-BRD one: `prd` and `epic` may hold a BRD key, and
  `derived_from` may name the folder's `ard-seed.md` where it holds no PRD — exactly what
  `/create-ard` writes and `ard-reviewer` accepts, so writer, reviewer and format authority agree. **`jira-reader` and `prd-reviewer`'s `jira_key` check were deliberately not widened** — both
  validate a *tracker* key, and no tracker mints a three-segment one. `prd-reviewer` instead excuses
  an **absent** `jira_key` beside a present `brd_key`, which is exactly the state
  `/create-prd --from-brd` authors: that reviewer runs at Phase 4, before the round-trip that mints a
  key, so a correct BRD-route PRD now passes its own gate instead of being flagged for a field it is
  right not to carry.
- **`/update-prd` carries `brd_key`, `brd_parent` and `depends_on` through a refresh unchanged.** It
  reads no BRD tree, so a value it dropped was one nothing later could restore, and the first refresh
  of a slice's PRD would have silently made it look like an ordinary one. Carrying an existing value
  forward is preservation, not authoring: this command mints none of the three and writes none onto a
  PRD that arrived without them.
- **A branch's key is resolved against the run's key set, never extracted by pattern.**
  `references/specs-repo-git.md` §3.5 pulled the key out of a branch name with a leading-token regex,
  which reads `EPIC-008` out of `ard/EPIC-008-01-<slug>`; a resumed slice run therefore failed guard
  B3, landed on B4, and `phase-handoff.md` §2.2 rule 4 minted a `-2` duplicate branch on every
  `--from-brd` resume. §3.5 now defines `branch-key <branch>`: strip the plugin prefix, then test the
  remainder against the keys the run already holds, a key counting as a candidate only where the
  remainder is exactly it or continues with `-` or `_`, longest candidate wins, no candidate means
  B4. Nothing in a branch name can *become* a key, so slug text cannot be captured — the obvious
  widening to a multi-segment regex would have read `PRODUCT-1234-2` out of
  `spec/PRODUCT-1234-2fa-rollout`. `phase-handoff.md` §2.2 rule 3 cites the same entry point, so a
  branch the preflight stayed on is the branch the handoff reuses.
- **Eleven sentences saying `--from-brd` does not ship were retired.** They sat in `/brd-reconcile`,
  `/brd-split`, `/brd-package`, `/brd-intake`, `references/brd-addressing.md`,
  `references/next-phase-offer.md`, `references/coverage-ledger-format.md` (which also leaked a
  plan-internal label) and three documentation pages. `/brd-reconcile` Phase 14 mattered most — the
  route's terminal command, still pointing at nothing — and now offers `/create-prd <BRD-KEY>
  --from-brd` where the ledger it leaves satisfies that command's two Phase 0 refusals, dropping the
  option otherwise, plus `/create-ard` and `/specify` with `--from-brd` unconditionally. `/brd-split`
  and `/brd-package` keep their existing offers but state the reason the state they leave actually
  gives — a register not yet written, or not yet frozen — instead of "does not ship".
- **`/create-prd`'s `/epics` and `/release-notes` offers now depend on both halves of the Jira
  round-trip.** `jira-reader` resolves the export directory, not the key, so a recorded `jira_key`
  with no re-import behind it landed both options in `jira-input-resolution.md`'s Fallback B — on the
  `/idea` route as much as under `--from-brd`.
- **`/create-prd --from-brd` refused the ordinary happy path.** Both Phase 0 refusals were defined
  over the `[BR#n]` set the BRD's `brd-link.md` `claims:`, and that field is written by exactly one
  place — `/brd-split`, and only into a **child's** `brd-link.md`. On a BRD that owns its source
  document and was never split — the two-segment key this route reaches most often — the field does
  not exist, the claimed set read empty, no row could be `covered-here`, and the command stopped with
  `CREATE_PRD_BRD_NOT_ELIGIBLE` plus a diagnostic table none of whose rows fitted. The gate set is
  now defined the way `references/coverage-ledger-format.md` §3's creator table and §5 already
  defined it: a BRD's **own ledger rows**, which on a source-owning BRD are its inventory's and on a
  slice are the ones `claims:` narrows to. §1 of that reference stated the slice rule as if it held
  at both levels and is corrected with it. `/brd-reconcile` Phase 14 computed its `/create-prd`
  offer the same wrong way and would have withheld it from every unsliced BRD; it now reads the same
  gate set. The refusals, the diagnostic table and the "where the requirements went" branches are
  correct at both levels, and a fourth branch covers an **empty** gate set, which reports the
  emptiness and names the one run that can change it instead of enumerating dispositions that do not
  exist.
- **A declined handoff could not be recovered by the command the stop named.** `/brd-ground` and
  `/brd-package` mapped `require-on-main` row F to a single stop naming the producing command, but
  that command is a no-op in the state the stop reports: `/brd-split` re-run on a fully-allocated
  parent stages nothing and opens no pull request, and `/brd-interview`'s no-new-round path does the
  same — so a slice's or a register's files could never reach the default branch by following the
  stop. Both now split row F the way `/brd-reconcile` already did: *never produced* names the
  producer, while *produced but never handed off* (`BRD_GROUND_NOT_HANDED_OFF`,
  `BRD_PACKAGE_REGISTER_NOT_HANDED_OFF`) asks for the files already on disk to be committed and
  merged. Each names the producing command only where re-running it would in fact stage them —
  `/brd-intake` over an existing folder does and is offered as the slower second route, `/brd-split`
  on a fully-allocated parent and `/brd-interview` on an unchanged BRD do not and are named as dead
  ends rather than offers.
- **`/create-prd --from-brd` read a `source:` field nothing writes.** The PRD's `sources` provenance
  ref was taken from `brd-link.md`'s `source:`; no writer of that file emits one at either level, so
  the ref resolved to nothing. It is now resolved by level and the file named: the single document
  under the BRD's own `brd/source/`, or — on a slice, which holds none — the path the `source:`
  header of its `brd/brd-inventory.md` names, relative to the parent's folder
  (`references/brd-format.md` §2.1).
- **A resumed `--from-brd` run duplicated its own branch.** `references/specs-repo-git.md` §3.2
  declared `/create-prd` structurally keyless, which is true on the `/idea` route and false under
  `--from-brd`, where the key is resolved at the call site and the branch is `prd/<BRD-KEY>-<slug>`.
  With an empty key set, §3.5 took B4 and switched away and `phase-handoff.md` §2.2 rule 3 had no key
  to resolve into, so rule 4 appended `-2` — the same duplication `31c614b` fixed for slice keys,
  reached by a different door. Keyless is now a property of the **route**: `/create-prd` contributes
  its BRD key under `--from-brd` and stays keyless on the `/idea` route, with the original reason for
  keyless intact where it applies. The contributed key is a folder identity used for branch matching
  only; `jira_key` is untouched and stays two-segment.
- **Four smaller route-walk findings.** `docs/commands/brd-reconcile.md` never named the route's exit
  and now carries the three `--from-brd` handovers with their conditions, in its diagram and its
  worked example — where its own example also printed an unquoted attachment path with spaces, which
  the positional parser would have read as four tokens. `docs/commands/brd-split.md` said a slice's
  Phase 7 ends the route, contradicting the command and its own prose, and now names
  `/brd-interview`. And `BRD_GROUND_DIRTY_TREE` stated only its consequence
  where every other stop on the route names an action; it now names the three ways to settle the
  tree and the `--rebaseline` re-run.

Counts are unmoved at 27 commands, 39 agents and 106 reference files: this increment added no
command, agent or reference file, and both plugin descriptions were re-worded rather than extended,
holding at 893 characters against the 1024-character catalog limit.

## [3.2.0] — 2026-08-30

### Added — BRD-to-PRD decisions and the customer loop (increment 2)

Increment 1 left a BRD grounded, split, and with every requirement carrying a recorded fate. What it
could not do was **decide** anything: the open questions a customer BRD is full of stayed open, and
nothing put them back in front of the customer who could settle them. This increment closes that
loop. The route is now `/brd-intake` → `/brd-ground` → `/brd-split` → `/brd-interview` →
`/brd-package` → *(the customer reviews it off-platform)* → `/brd-reconcile`, and it ends at a BRD
whose decisions are frozen against the customer's own returned words.

- **`/brd-interview` — decide the open questions, one round at a time.** It gates on a fully
  allocated ledger and on every grounding finding carrying a verifier outcome, then generates a
  round's questions **before** tagging any of them and tags each into exactly one of three: a
  question the findings already answer, one the delivery team decides with argumentation, and one
  only the customer can settle. No question of the third kind is ever put to a human in the room.
  Rounds are numbered, permanent, contiguous and resumable, and the command fixes the vocabulary the
  whole route reads state in: five **terminal dispositions** against four **holding states**, with a
  holding state keeping its round open — which is what stops a round with an outstanding customer
  question from being declared finished around the customer.
- **`/brd-package` — build what the customer actually reviews.** An Opus `brd-package-reviewer` runs
  an adversarial self-review of the package before anybody sees it; every finding it raises takes a
  recorded disposition, and the run assigns itself a degradation tier saying plainly what the bundle
  could not include. The rendered customer prompt is scanned for anything plugin-internal — a
  plugin-root path, a reference-file citation, a section sign, a slash command, an agent name, a
  design-decision row id — and the run **stops** on a hit rather than sanitising it, because a
  citation that reached the prompt reached it from a sentence written for a reader who has the
  plugin. A dated bundle is never rewritten.
- **`/brd-reconcile` — freeze what came back, and sweep what it moved.** It gates on the package
  that was actually sent, canonicalises the returned review and commits it **before anything reads
  it**, and never overwrites a returned review. Every candidate decision is confirmed with an
  operator before it becomes a customer decision — nothing is inferred into one. It then applies the
  corrections the review asked for, banners the superseded dated snapshots, resolves the defects the
  review settled, moves the ledger rows the review moved, and runs two sweeps: one across every
  dependent BRD whose position rested on a decision that just changed, and one for stale
  cross-references under the parent — including a search for prose asserting a now-superseded
  position with no identifier in it at all, which is the half that cannot be reduced to a pattern.
- **A cross-BRD write guard, stated once for all three paths that need it.** Three phases write
  outside the BRD folder the run was given — a slice's parent defect log, a dependent BRD's
  register, a sibling slice's artifacts. Each runs the merge gate against that artifact first and,
  on any stopping row, **records the intended change rather than writing it**, so an in-flight run
  belonging to somebody else is never silently overwritten. It never stops the run.
- **Two agents:** `brd-package-reviewer` (Opus-pinned adversarial review of the package) and
  `customer-review-reader` (reads the returned review, fail-closed: anything short of a positive,
  in-order schema match is treated as free text, and there is no second dispatch to talk it into a
  parse).
- **Four references:** `interview-tagging.md` (the three question tags, the re-tag and split rules,
  and the round/disposition vocabulary), `decision-register-format.md` (the decision and assumption
  record shapes, the reopen and supersede causes, and the will-change resolutions),
  `customer-review-schema.md` (the twelve-section shape the returned review is written in, with its
  own render boundary declared in the file so the renderer and the schema cannot drift apart), and
  `bundle-packaging.md` (what a bundle contains, and why a dated one is immutable).
- **`docs/brd-workflow.md` extended to the full six-command loop,** including the off-platform wait
  and both of `/brd-reconcile`'s return edges, plus per-command documentation pages for the three
  new commands.

### Fixed

- **Two identity-quarantine violations.** The `/guideline-reviewer` and `/api-guideline-reviewer`
  documentation pages linked the sibling `prose-style` plugin by full container URL. A hardcoded
  container URL is wrong in anyone's fork, so both keep the reference and drop the container. No
  gate enforces the quarantine rule, which is why both survived.
- **`references/cost-emission.md`'s preamble no longer carries a roster of its own.** It named a
  fixed list of PRD-lifecycle emitters that had already omitted every `/brd-*` emitter; the set is
  now section 7's attribution table and nothing else.
- **`references/next-phase-offer.md` knows the route exists.** The reference that owns next-phase
  routing carried no `/brd-*` command at all. It now carries the whole route as a role-labelled
  block, with the slice fan-out drawn as the same depth/breadth pair the Epic rule uses, and with
  reconciliation marked leaf/closure.
- **`/brd-interview` cites its downstream gate instead of restating it.** Its gated `/brd-package`
  offer held a second copy of a precondition `commands/brd-package.md` owns; the copy is replaced by
  a citation, so the offer and the gate cannot drift apart.
- **A claimless BRD no longer dead-ends the route.** When `brd-reader` found no requirement in the
  customer's document, `/brd-ground` reported "nothing to ground" and ended successfully without
  handing anything off — so `/brd-split` and `/brd-interview` both refused the BRD and named
  `/brd-ground` as the fix, which would report the same emptiness again. The only exit, re-running
  `/brd-intake` over the same folder with a corrected source, was documented nowhere. `/brd-ground`
  now **stops** on a zero-row inventory and names the upstream fix by level; `/brd-split` and
  `/brd-interview` split their row-F stop on the same zero-row test and name that fix too, saying
  outright not to run `/brd-ground`; and `/brd-intake` reports the `EMPTY` read as a route-stopping
  state and offers a corrected re-run instead of offering grounding. Four new stop tokens, each
  branched for a source-owning BRD and for a slice, because a slice's inventory is its parent's
  `/brd-split` to write and re-intaking one is never the answer.
- **A child kept empty is reachable again — `/brd-split` gains Phase 4.5.** The empty-child
  resolution used to sit at the tail of Phase 4 and was scoped to children *created that run*, while
  Phase 0's no-op test skipped Phases 2–5 whenever no ledger row was `unallocated`. After a
  completed split no row is unallocated by construction, so every later run no-op'd, the resolution
  never ran, and a child kept empty with a recorded reason could never afterwards be removed or
  given rows — by any command, in any run. The check is now its own phase, scoped to **every child
  standing**, and the no-op test is two-part: no unallocated row **and** no standing empty child. A
  parent holding one skips the walk it has no rows for and runs Phase 4.5 alone. A child with no
  recorded reason is offered removal; one already carrying a reason is offered keeping it
  (recommended), removing it now, or updating the reason, so a deliberate decision is not
  re-litigated but removal stays reachable. The phase states outright that it cannot give a child
  rows — `covered-by` is Phase 4's, and only against a row still `unallocated`.
- **The next-step merge clause is resolved from the run's actual handoff outcome.**
  `references/next-phase-offer.md` required every offer naming a downstream command to name the merge,
  unconditionally — but a no-op run, a run that kept a standing empty child unchanged, and a declined
  handoff all open no pull request, and only one of the two failing outcomes has a branch to name at
  all. The reference now owns a `<merge-clause>` placeholder resolved from the `phase-handoff.md`
  §4.1 line the run emitted, mapping every one of its outcomes, and the route's offers carry the
  placeholder instead of a fixed sentence. It is a placeholder rather than an instruction to reword an
  option, so choice arrays are still presented verbatim as `escalation-rules.md` requires.
- **The five offers that predate the route now resolve their merge clause too.** Scoping the rule to
  the `/brd-*` family left `/create-prd`, `/create-ard`, `/specify` and `/design` promising "once the
  pull request above is merged" on a declined handoff, a failed push, or a nothing-to-commit run —
  states in which no pull request exists — and left `/update-prd` offering two commands that gate its
  own PRD with no wait named at all. All five now carry the `<merge-clause>` placeholder on exactly
  the options whose downstream `require-on-main` target the offering run writes, and each says beside
  its array or paragraph which parts carry it and why the others do not. Two of the five are prose
  `### Next step` sections rather than `choices:` arrays, so no gate can see them — the universal
  minimum surface the offer contract defines is exactly the surface `check-docs.sh` check 11 does
  not cover.
- **`/brd-split`'s no-op decision is taken in both run modes again.** Moving that decision into Phase 0
  step 9 — which runs in `full` mode only — meant a fully-allocated **slice** never reached it, fell
  through into Phase 5 and opened a pull request for a run that changed nothing, contradicting this
  command's own promise to a slice. The decision now has its own step, after the enumeration it needs
  and outside the mode-scoped one, so it is reached on a slice exactly as on a parent.
- **The three slice-level empty-inventory stops name what actually works.** They previously ended
  "re-run `/brd-split <PARENT-KEY>` and allocate rows to this slice, or remove the empty slice — that
  run offers the removal itself". Neither half was true before Phase 4.5 existed. They now name the
  resolution Phase 4.5 actually offers and say plainly that on a parent with no unallocated row left,
  removal is the only thing that can change the slice's state.
- **`BRD_PACKAGE_NOTHING_TO_REVIEW` names something that helps.** It sent the operator to
  `/brd-interview`, which opens a new round only when the findings or the decisions have moved and
  would therefore report a no-op. The stop now reports a **finished** state — every question settled
  from verified findings, nothing for a customer to decide — says outright that another round is not
  the fix, and names the one action that changes it, a `--rebaseline` grounding pass or a reopened
  decision. `/brd-interview`'s own next-step offer was computing only the first of `/brd-package`'s
  two content gates, so it offered a run that then stopped on the second; it now computes both and
  carries a third list for the decided-BRD case.
- **A second fixture-growing selftest case for the docs gate.** Only one of the two prose-count
  alternations taught new number words was exercised end to end; the cost-emitting one was covered
  by inspection alone. The new case grows the fixture to eighteen commands, seventeen of them
  cost-emitting, and re-words both count sentences to deliberately different numbers.

Roster corrections that landed with this increment: the command and agent counts and the command
list in `CLAUDE.md` and in both plugin descriptions; the model-routing must-load list; the
`specs-repo-git.md` caller count and the `phase-handoff.md` producer and consumer rosters; the
documentation-page inventory and the docs gate's selftest case count; and `phase-handoff.md` §3.4's
closing paragraph, which named two `/brd-*` consumers where there are now five.

Not in this increment: `--from-brd` on `/create-prd`, `/create-ard`, or `/specify`, and no
one-level-deep resolution fallback in the six commands that resolve a PRD directory. No PRD is
written by this route. It ends at a reconciled, decided BRD whose seeds are ready.

## [3.1.0] — 2026-08-30

### Added — BRD-to-PRD grounding route (increment 1)

A customer-supplied business requirements document (BRD) is long, internally inconsistent, and not
implementable as written. This route turns one into a requirement inventory every row of which has
been checked against real code and design, and given a recorded fate, before a PRD is ever written
from it — useful on its own, without any of the follow-on work increment 2/3 will add.

- **Three commands, PM-owned end to end.** `/brd-intake` copies the customer's document in verbatim
  and immutably, extracts a `[BR#n]` requirement inventory, confirms candidate defects with a human,
  and writes a coverage ledger with every row `unallocated`. `/brd-ground` — PM-initiated but
  PA/Dev-executed — pins every mounted repository to a verified commit and grounds every `[BR#n]`
  claim against code and an exported design frame set, with every finding independently re-derived
  before it counts as evidence. `/brd-split` gates on every finding carrying a verifier verdict,
  proposes candidate slices, and walks every unallocated ledger row to one of five recorded fates —
  building here, assigning it to a named child BRD, deferring it, rejecting it against a logged
  defect, or marking it superseded — until none remain `unallocated`. A confirmed slice nests inside
  its parent's folder and re-enters at `/brd-ground` for its own grounding pass.
- **A slice is a BRD, and `/brd-split` gives it everything one needs.** Alongside `brd-link.md`, a
  new child folder gets a `brd/brd-inventory.md` — the parent's claimed rows copied verbatim under a
  header naming the parent's `brd/source/`, which every `source_anchor` still resolves against — and
  a `coverage-ledger.md` seeded `unallocated`. Those are the two files `/brd-ground` gates on and
  reads, and `/brd-intake` never runs on a slice (there is no separate document to intake), so
  `/brd-split` writes them: without that, the loop back to grounding dead-ends. A slice holds no
  `brd/source/` and no `brd/brd-defect-log.md` of its own and inherits both from its parent
  (`references/brd-format.md` §2.1).
- **Verification is anchored to whatever a finding actually rests on.** A `[CG#n]` and a class-4
  `[DG#n]` are re-derived against the pinned repository; a `[DG#n]` of class 1, 2, or 3 is
  design-only and is re-derived against the frame set, which `grounding-verifier` now receives.
  Requiring a commit of those would have left them permanently unverifiable and blocked `/brd-split`
  forever. The agent's row selection is fail-closed — anything not explicitly asserting a
  design-only class is treated as resting on code — so no code finding can be verified without its
  commit. `/brd-ground` Phase 7 also acts on the verifier's refusal statuses, stopping before any
  finding is written without an outcome.
- **Four agents:** `brd-reader` (Sonnet-pinned extraction), `code-grounder`, `design-grounder`, and
  `grounding-verifier` (Opus-pinned independent re-derivation).
- **Four references:** `brd-addressing.md`, `brd-format.md`, `coverage-ledger-format.md`, and
  `grounding-format.md`.
- **A new branch prefix, `brd`,** shared by all three commands the way `prd` is shared by
  `/create-prd` and `/update-prd`; registered in `references/phase-handoff.md` and
  `references/specs-repo-git.md`.
- **`docs/brd-workflow.md`** — a route overview page with a Mermaid diagram of the three-command
  loop and each command's parameter table.
- **`/brd-intake` and `/brd-ground` ground on the shipped product documentation** when `$DOCS_PATH`
  resolves, bringing the route's consumers of `references/docs-grounding.md` from seven to nine
  (`--no-docs` turns it off; every miss stays a silent, non-blocking skip). `/brd-intake` consumes
  it **grill-rank** over Phase 4's defect walk: challenges are ranked into the walk order, and one
  may be raised as an extra candidate in the two classes documentation can speak to — `unsourced`
  and `ambiguity` — so a `[DEF#n]` confirmed by a human is the only thing documentation can put on
  a `[BR#n]` row. `/brd-ground` consumes it **lead-only** (a third mode, defined in
  `references/docs-grounding.md`): a page may say where to look, and a page the code contradicts is
  recorded as a divergence in `grounding/code-grounding.md` — but **a document is never evidence
  for a `[CG#n]`**, because a document is a claim *about* behaviour and citing one would let a
  stale page satisfy a claim the code does not. A divergence carries no identifier of its own; it
  names the verified `[CG#n]` it diverges from, so it can never stand on the page alone.
  `/brd-split` deliberately gets none — it allocates requirements, which documentation does not
  inform.

- **Nesting is capped at one level — on nesting only, never on allocation.** A slice is a BRD in
  every other respect: same commands, same artifacts, free to depend on any other BRD. What the cap
  forbids is creating a child *below* a slice, so `/brd-split` now runs in one of two modes,
  resolved in Phase 0 step 5 from the folder's own `brd-link.md` `parent:` field. On a BRD that owns
  its source document, `split_mode: full` — nothing changes. On a slice, `split_mode: allocate-only`
  — the slice-proposal and child-creation phases are skipped and the ledger walk offers **four**
  resolutions instead of five, with `covered-by` unavailable because it names a child BRD and no
  child can exist below a slice. The walk itself always runs: a slice whose rows could never leave
  `unallocated` could never become PRD-eligible (`references/coverage-ledger-format.md` §5), which
  would make slicing pointless. `BRD_SPLIT_ON_SLICE` is a **notice, not a stop** — emitted at Phase
  0 and repeated in the final report, because a run that silently skipped two phases and dropped a
  resolution would be worse than one that says so. `resolve-brd` matches the cap exactly, searching
  `specifications/` and one level below it and no further (`references/brd-addressing.md` §2, §3),
  and the cap is what makes every inheritance in the route literal: a slice's parent is always the
  BRD that owns the customer's document, so `brd-format.md` §2.1's inherited `source:` path always
  exists and §4's inherited defect log — which an `allocate-only` `rejected: [DEF#n]` actually
  reaches for — is always exactly one hop away. A grandchild would have had neither.

Roster corrections that landed with this route: `CLAUDE.md`'s specs-repo-git caller count (twenty,
not seventeen — all three `/brd-*` commands run `specs-preflight` and `commit-artifacts`) and its
`read-only-repos.md` consumer list (`code-grounder` and `grounding-verifier` consume it, and
`/brd-ground` is the first command to cite it directly); `references/specs-repo-git.md` §4.1's
branch-opener roster (all three `/brd-*` commands open a `brd/*` branch, not only `/brd-intake`);
`references/phase-handoff.md` §3.4's row-F delegation table, which now carries `/brd-ground` and
`/brd-split` with the reason their `absent` stop is legitimate — a gated input that shipped with
its consumer was never optional, so nothing was promoted into a prerequisite.

Not in this increment: `/brd-interview`, `/brd-package`, `/brd-reconcile`; `--from-brd` on
`/create-prd`, `/create-ard`, or `/specify`; a decision register; a self-review pass; a customer
bundle. `references/brd-addressing.md` §4 defines the shared resolution fallback for the six
existing commands and marks it unadopted.

## [3.0.0] — 2026-08-29

One release, one exercise: make the marketplace publishable as open source. It removes organization-specific content and naming, retires vocabulary that only made sense inside one company, drops a feature that existed only because one vendor ships two product editions, and restores machine-checkable enforcement from public sources. It is a single major because it is a single migration — everything below applies at once.

### Changed — BREAKING: vendor-neutral de-branding

- **The `dt-style-guide` plugin became `prose-style`.** Its agents are now `prose-style:prose-style-checker` and `prose-style:prose-fixer` (were `dt-style-guide:dt-style-checker` / `dt-doc-fixer`). Every dispatch site in `/document`, `/epics`, `/release-notes`, `/create-prd`, and `/update-prd` was re-pointed, along with `docs-style-checker`'s fallback chain. The phase formerly named "Dynatrace style check" is now "Prose style check". `prose-style` also gains a pluggable overlay: it ships a vendor-neutral baseline and layers your own style guide on top.
- **`references/dynatrace-docs/` became `references/docs-profiles/`**, the `dynatrace-docs-frontmatter` skill became `docs-frontmatter`, and `managed-owners.txt` became `default-owners.txt`.
- **The built-in docs profile is now a generic worked example** (`example-docs`) rather than one specific private repo. A real repo supplies its own `.dev-workflows/docs-profile.yml`, which overrides the built-in default — run `/docs-profile` once to generate it.
- **`references/guidelines/` was rewritten against public standards** — Apple Human Interface Guidelines, Material Design 3, Microsoft Fluent 2, W3C WCAG 2.2 and the ARIA Authoring Practices Guide, and Nielsen Norman Group heuristics — replacing content summarized from an internal wiki. `grail-naming.md` became `data-naming.md`. `/guideline-reviewer` reviews against generic component vocabulary (app header, data table, filter field) rather than one design system's component names.
- **`references/api-guidelines/` was rewritten against public sources** — Google AIP, the Zalando RESTful API Guidelines, the Microsoft REST API Guidelines, OpenAPI 3.1, and the relevant RFCs.

### Changed — BREAKING: Value Increment renamed to PRD

"Value Increment" is SAFe/organization-specific vocabulary that reads as opaque to anyone outside the team that coined it. The artifact is a Product Requirements Document, so the plugin calls it that. Vocabulary only — no phase, gate, or workflow edge changed behaviour.

- **Commands:** `/create-vi` → **`/create-prd`**, `/update-vi` → **`/update-prd`**; the `--from-vi` seed flag is now `--from-prd`.
- **Agent:** `vi-reviewer` → **`prd-reviewer`**.
- **References:** `vi-format.md` → **`prd-format.md`**; `vi-source-resolution.md` → **`prd-source-resolution.md`** (`resolve-existing-vi` → `resolve-existing-prd`).
- **Branch prefix:** the six-prefix authority is now `^(idea|prd|ard|spec|design|ready)/`.
- **Records:** the cost/feedback `vi:` key is now `prd:`; phases `vi-creation` / `vi-update` are now `prd-creation` / `prd-update`.
- **Enums:** `depth: vi-only` → `prd-only`, `vi-plus-epics` → `prd-plus-epics`; `/idea`'s source type and `provenance:` `vi` → `prd`; ARD `scope: vi | epic` → `prd | epic`; `seeded_from_vi` → `seeded_from_prd`.

**`ValueIncrement` is deliberately unchanged** — a Jira `issue_type` value read from exported frontmatter, external system data rather than this plugin's vocabulary. Only the mapping target changed. No Jira configuration changes. Nothing depends on a project-key prefix: every key match is the same generic `^[A-Z][A-Z0-9_]*-\d+$`, so the rename carries no parsing risk.

### Removed — BREAKING: cross-space writing

`/document` could author one page so it rendered differently in two documentation "spaces" (product editions) — conditional wrappers, copies into a second content tree, manifest allowlists, and counterpart-space grounding. That existed because one vendor ships two editions. Most documentation sets are single-product, and this was the largest source of intricacy in the command.

**Multiple content roots still work.** `profile.spaces[]` remains a plain list; a page is written into whichever root already owns it, and per-root lint / build / dev-server commands still route by that root. What is gone is *cross*-space writing.

- **Command signature** is now `/document <KEY>` — there is no space-constraint token and no `--counterpart` flag.
- **Phases removed:** 4.5, 5.6.5, and 5.9 (write-strategy approval — its entire body was the `conditional`/`override-copy` choice). Surviving phases are **not** renumbered; those three numbers are simply unused.
- **Agent removed:** `counterpart-finder` (34 subagents → 33).
- **Reference removed:** `docs-profiles/multi-space-writing.md` (subtree 6 → 5 markdown files).
- **Write strategies collapsed away** — no one-valued enum survives. `doc-planner` still records each target's `space`, which keeps per-root command routing meaningful.
- **Profile fields removed:** `cross_space_override`, `shared_registries`, `tokens.project_conditionals`, and `/docs-profile`'s detection of all three.
- **`doc-location-finder`'s announcement-page exemption** removed; `profile.announcement_pages` itself kept.
- **`render-verification.md` §4** removed; §5 → §4, §6 → §5.
- **The `gating` field** removed from `existing_image_decisions[]`.
- **`doc-writer`'s routing BLOCKER was dropped, not rewritten** — reinterpreting it as "no declared content root matches" would have been a *new* gate that could false-fire on a legitimate write outside a root.

### Added — machine-checkable rules, and an overlay for what cannot ship publicly

Replacing vendored internal rules with public standards was right, but it cost the *mechanically checkable* half: the vendored copy named concrete literals a reviewer could grep for, and prose criteria have to be interpreted. This restores enforcement from public sources and gives organization-specific rules a private home.

- **`/api-guideline-reviewer` lints with Spectral.** `references/api-guidelines/spectral/ruleset.yaml` extends `spectral:oas` with **40 custom rules** across version consistency, naming, scope grammar, status codes, schema composition, and header hygiene — including the canonical tenant-header spelling, the literal check the rewrite cost most. Every rule was verified to fire against a purpose-built violating fixture, so none ships inert.
- **`/guideline-reviewer` findings carry checkable identifiers** — 51 axe-core `ruleId`s and 35 **W3C ACT Rule** ids beside the WCAG criteria, all verified against the shipped axe-core bundle and the W3C published index. The reviewer runs the target repo's own `eslint-plugin-jsx-a11y` when configured.
- **A rule overlay for both reviewers**, resolved exactly as `prose-style` resolves its own: `--rules <path>` → `<repo-root>/.dev-workflows/{ui,api}-guidelines/` → `$UI_GUIDELINES_PATH` / `$API_GUIDELINES_PATH` → the bundled baseline. First hit wins. This is where rules with no public equivalent belong — kept private instead of shipped.
- **`frontmatter.owners_spaces` in the docs-profile schema** — the space ids whose pages require an owners block. The `changelog-owners-reminder` hook and the `docs-frontmatter` skill resolve content roots and owners policy from the applicable profile instead of hardcoding paths. The hook parses with a tolerant line scan, so it never depends on PyYAML and never raises.
- **Two new environment variables:** `$UI_GUIDELINES_PATH` and `$API_GUIDELINES_PATH` (six user-settable → eight). Both optional; every miss falls through silently.

### Honesty constraints, deliberately encoded
- **axe-core needs a rendered DOM and cannot run against source files.** `accessibility.md` says so in a "what can actually run" table, and the agent may not claim a rule executed when it only cited one: *a review reporting an axe rule id is naming the rule a violation would trip, not reporting a rule that ran*. A runtime harness (`jest-axe`, `cypress-axe`, `@axe-core/playwright`) is **detected and named, never executed**.
- Rules with **no** deterministic equivalent are marked reviewer judgement rather than given a fabricated id.
- A **version-agreement** Spectral rule was deliberately not shipped: it needs `@root` inside a JSONPath filter, which behaved inconsistently under test. The three per-field format rules ship; the agreement check is named an LLM-pass responsibility rather than shipped flaky.

### Fixed
- **`/document`'s docs-repo discovery was keyed to a repository name.** Step (b) searched `$REPOS_PATH` for a checkout named after one specific repo, and the `$DOCS_PATH` hint required that repo's exact layout; after de-branding both matched a name nothing has, leaving two of four discovery paths inert. Discovery is now signal-based, and no repository name is special-cased.
- **Two *trigger conditions* were briefly narrowed to the generic example** — `changelog-owners-reminder.py`'s content-root matcher and the `docs-frontmatter` skill's description. Both previously matched one specific repo; genericising the example silently narrowed them to a fiction. Both are now profile-driven, which is strictly more general than either prior state.
- **`changelog-owners-reminder.py` resolved its owners file through the pre-rename directory.** The path is assembled with `os.path.join` rather than written as a literal, so a path-level search-and-replace could not see it; the hook would have silently stopped emitting the owners reminder.
- **`check_guidelines.py`'s settings-before-help ordering check compared positions inside `import` statements** rather than the markup, so it could pass on genuinely out-of-order markup.
- **An accessibility rule asserted a WCAG exception that does not exist** — "include placeholder text in all input fields (enables WCAG color contrast exception)". Placeholder text must meet the 4.5:1 ratio of SC 1.4.3.
- **The bundled OpenAPI template** gained a `requestBody` description — it violated the new ruleset and the guideline requires one. The rule was not loosened; one inherited rule (`oas3-unused-component`) is scoped off for the template file only, because a starter's reusable error responses are unused by design.
- Roughly 14 dead image links, a malformed RFC link, a wrong template path, and a broken `#delete` anchor in the API guidelines.

### Migration

Everything here applies together — this is one upgrade from 2.x, not several.

- **Commands:** use `/create-prd` and `/update-prd`; `/prose-review-pr`, `/prose-review-docs`, `/prose-style-refresh` replace the `/dt-review-*` trio. No aliases; the old names are gone.
- **Agents:** `dev-workflows:vi-reviewer` → `dev-workflows:prd-reviewer`; `dt-style-guide:dt-style-checker` / `dt-doc-fixer` → `prose-style:prose-style-checker` / `prose-style:prose-fixer`.
- **`/document` takes only a Jira key.** Drop any space token and any `--counterpart` flag from saved invocations — both are now parse errors rather than ignored arguments.
- **Docs profile:** rename `frontmatter.managed_owners` to `frontmatter.default_owners`. A profile still declaring `cross_space_override`, `shared_registries`, or `tokens.project_conditionals` is **not** an error — those fields are simply no longer read.
- **Pages carrying `{{#if project='…'}}` wrappers are left exactly as they are.** Nothing rewrites or validates them; they are ordinary page content now. A repo that needs conditional rendering should handle it in its own docs toolchain.
- **Cost and feedback records already emitted keep the old `vi:` key and `vi-creation` / `vi-update` phase labels.** Aggregating a cost series across this release means treating old and new labels as the same phase.
- **Specs-repo branches named `vi/...` are no longer recognized as plugin-created.** `specs-preflight` leaves unrecognized named branches alone, so this is safe by default — such a branch is simply never switched away from or deleted.

## [2.58.5] — 2026-08-23

### Fixed
- **`CLAUDE.md`'s "Updating installed plugins after editing" section only told the reader to reinstall the affected plugin**, while `docs/getting-started.md` correctly attributes "the latest command, agent, hook, and reference content" to `claude plugin marketplace update ihudak-plugins` — a whole-marketplace refresh that, per the maintainer, already refreshes every plugin installed from it. The two files reading differently invited exactly the confusion a review flagged. Added a sentence noting the one-step marketplace-refresh alternative; kept the `reinstall` guidance, which is still the right call for a single plugin.

## [2.58.4] — 2026-08-23

### Fixed
- **`docs/getting-started.md` overstated repo-matching, silent degradation, and the `dt-style-guide` relationship.** Its `$REPOS_PATH` paragraph claimed repos are "matched by their `origin` slug, never by directory name" as a blanket rule — but `docs/reference/environment.md` says that's true only where a repo is resolved from a PR URL (`/document`, `/epics`, `/release-notes`); `/idea`, `/create-ard`, and `/design` instead list top-level directories and match on basenames, so a repo renamed on disk is *not* found by those three. Its environment-variables paragraph claimed only `$DOCS_PATH` and `$DEV_WORKFLOWS_COST_PRICES` degrade silently — `environment.md` also documents `$REPOS_PATH`'s `/workspace` default as taking over silently; three of the four optional variables degrade silently, not two. And its dependencies paragraph called `dt-style-guide` "the one other plugin it genuinely reaches for" (unscoped — `superpowers:brainstorming` is reached for too, four lines later on the same page) and said every command using it "degrades gracefully when it is absent" — false for `/document`, where an absent `dt-style-guide` with no other configured linter is a real coverage hole that `gate-ledger.md` §5 forces an explicit choice about, never a silent no-op. All three corrected in place.
- **`CLAUDE.md` said the docs selftest runs 36 cases; it runs 37.** Re-derived by actually running `./scripts/check-docs.sh --selftest` rather than trusting the prose.
- **`references/handoff/upgrade-executor.md:18` cited the Copilot edition's orchestrator location.** "The orchestrator (`upgrade/SKILL.md` Phase 2 Step 1)" is Copilot's file layout; in this edition the orchestrator is `commands/upgrade.md`, and the baseline capture the comment describes is Phase 2 prep's Step 2. Legacy staleness predating the Copilot port, not a back-leak from it — the same file already gets the reference right two other places in the same block.
- **`.github/workflows/validate-catalog.yml`'s header comment never mentioned `scripts/check-docs.sh`, though the workflow runs it**, and its step name read "Check docs" where mgd and the Copilot edition both say "Check docs against the plugin tree." Added the missing header paragraph (Copilot's shape, verified accurate here too) and renamed the step so all three editions match byte-for-byte on this file.

## [2.58.3] — 2026-08-23

### Fixed
- **`/update-vi`'s forward-path offer omitted `/epics`.** `references/next-phase-offer.md`, `commands/update-vi.md`'s Phase 6 `choices` array, and `docs/commands/update-vi.md`'s See-also line each named only `/release-notes`, `/create-ard`, and `/specify` as the destinations re-offered after a refresh. Confirmed with the maintainer: `/update-vi` offers the same four forward paths as `/create-vi`, including `/epics` — `/update-vi` improves a VI that `/create-vi` created, so everything downstream is identical, and the omission was an understatement rather than a deliberate exclusion. Added `/epics <VI>` (PE) alongside the other three in all three sites; the existing "(if one exists)" qualifiers on `/create-ard` and `/specify` are untouched.

## [2.58.2] — 2026-08-23

### Fixed
- **`docs/getting-started.md` listed every prerequisite except the one external plugin the pipeline actually cedes control to.** It named `dt-style-guide`, `jira-workitem-import`, and the two marketplace siblings that are *not* needed — and omitted `superpowers`, which `/prompt-brainstorm` hands its Phase 3 to. The repo-root README has carried it as a recommended weak dependency all along; the new page did not inherit it. Added, with the distinction that matters: **brainstorming is external, grilling is not** — the relentless-interrogation technique the authoring commands run is bundled at `references/grilling-technique.md`, so only the brainstorm hand-off has an outside dependency.

## [2.58.1] — 2026-08-23

### Fixed
- **Two review findings reported as fixed in 2.58.0 were not.** One was skipped by an accidental no-op in the batch edit that applied the wave (the "before" and "after" strings were identical, so the loop's guard silently passed over it) and was then reported as applied without re-reading the file; the other was never addressed at all. Both are real and both are fixed here. The reporting error is the more useful half: a fix wave that reports from its own script's intent rather than from the resulting file will always over-report, which is the same failure shape as a verification table asserting PASS for a check that never ran.
  - `docs/commands/prompt.md` claimed "the only checkpoints are the specs-repo git guards". `references/cost-emission.md` §9's reconciliation is a **suggest-and-confirm** offer that fires "whenever any command resolves a VI key and pending files exist" — and as of 2.58.0 `/prompt` runs a cost phase and resolves a `jira_key`, so it is reachable. The page now names both interrupt sources. (Its Phase 3 "Write silently" line is unchanged and still correct: it describes the feedback append, which is silent; the cost step that follows it is a separate step.)
  - `commands/prompt.md` Phase 1 offers `"Other… (describe)"`, whose answer is free text, while §11 requires `target_command` to be a bare §7 row name. Phase 1 now normalises the answer onto a row name before it travels, and uses `n/a` when it names none — an unnormalised value matches no row and silently degrades the entry to `plugin-feedback`/`n/a`, the exact failure the 2.58.0 chain fix existed to prevent.

## [2.58.0] — 2026-08-23

### Added
- **`/prompt` and `/feedback` now emit a session-cost entry, inheriting the labels of the command they are about.** Both already resolved a **target command** (the one whose output is being corrected or remarked on) and a `jira_key`; neither used them for cost. Each now calls `emit-cost` with `phase: inferred, role: inferred`, and `references/cost-emission.md` §7 resolves the real values from that target: a `/prompt` correcting a `/specify` output is priced as `specification`/`pe`, one correcting a `/design` output as `planning`/`dev`. **The cost of fixing a phase's output belongs to that phase** — so "what did specifying cost" now includes the cost of making the spec right, rather than pooling every correction in a bucket of its own.
- **New cost phase `plugin-feedback`, with `role: n/a`.** The fallback when no target resolves, when the target emits no cost of its own (`/vuln`, `/upgrade`, `/docs-profile`, `/statusline`, the two guideline reviewers), or when the target is itself a feedback command — a correction to a correction has no lifecycle phase, and inheriting from an inferred row would regress with no base case. `n/a` is the **absence** of a role recorded rather than guessed; aggregation must treat it as unattributed and never fold it into `dev`. Ten phases now, nine of them lifecycle.
- **`check-docs.sh` check 9 gained the cost-emitting count** — derived from the same extractor check 8 uses. This is the exact count that went stale the moment these two commands started emitting ("Eleven commands emit a cost entry"), and nothing was guarding it. It fires on a wrong number and on the sentence being reworded away. Its numeral matching is now case-insensitive, since a count can open a sentence; the word map gained eleven through fourteen. Selftest 35 → 36.

### Fixed
- **The inference rule shipped without a transport leg** (caught before merge). §7 said `/prompt` and `/feedback` resolve their labels from a target command, but §11 — the caller contract — had no input for one, still described `inferred` as "the marker for `/release-notes`", and both call sites passed only `command`/`phase`/`role`/`jira_key`/`source`/`plugin_version`. The two inferring paths are **not alike**: `/release-notes`' discriminator is filesystem state (`specification.md` / `design.md` presence) that `emit-cost` reads itself, while a target command lives in the run's own context and cannot be re-derived from disk. The rule read correctly in isolation and would simply never have executed — every correction would have fallen through to `plugin-feedback`/`n/a`. `target_command` is now a required §11 input for those two commands, passed by both call sites, and §7 names it as the discriminator instead of describing it in prose.

- **Two Opus reviews of this branch found 14 more, 13 fixed and 1 dismissed.** The producer → transport → consumer chain was confirmed complete by tracing, and the recursion base case verified to terminate on every path. What they found instead:
  - **The rationale for `/prompt-brainstorm` and `/prompt-grill-me` emitting nothing was refuted by §3 of the same file.** It said a wrong number is worse than a missing one — but because neither advances the §3 checkpoint, their spend is **not missing**: per §3's own semantics, "activity between commands rolls into the next command's bucket", so a long grill followed by `/implement` is priced `implementation`/`dev`. That is a *larger* error, not a smaller one. The section now states the structural reason (there is no point after the hand-off at which the command still controls execution) and records the misattribution honestly as a known limitation.
  - **A `/release-notes` target on a keyless run had no defined outcome.** Its discriminator is file presence under the VI's specs dir, which cannot be evaluated when no VI dir resolves — and the nearest reading attributed a keyless plugin correction to `vi-creation`/`pm`, exactly the guess `role: n/a` exists to forbid. It now falls to the `n/a` case explicitly.
  - **Four standing claims were falsified by §7's new list of commands with nothing to inherit.** `docs/commands/vuln.md`, `upgrade.md` and `docs-profile.md` each said `cost-emission.md` "never mentions" the command — and the first two shipped a **runnable** `grep -c … → 0` a reader could execute and watch fail (it returns 1 now). `docs/reference/session-cost.md` said the same in prose.
  - **The phase count went stale in the commit that added the tenth phase** — `docs/roles-and-phases.md` said "Ten phases exist" at one line and "outside the nine phases above" 44 lines later, and `session-cost.md` still said "the nine cost-attribution phases". The same commit had built a check-9 guard for the *emitter* count on the grounds that nothing was guarding it, then broke a second count and left it unguarded.
  - `cost-emission.md`'s own caller roster still read "every VI-lifecycle command" and listed eleven; the emitter tail was cited to `specs-repo-git.md` §4, where it is not defined (`session-hygiene.md` §5); `target_command`'s value domain silently differed from `command`'s (`/document` vs `/document (Jira mode)`); the new `plugin-feedback` heading was the only phase in the set with no inbound link; and neither command page listed the cost entry under "What it produces".
  - **Dismissed, with its reason:** `/release-notes` being "the plugin's one dual-role command" was flagged as newly false since three commands now infer. Verified: neither that claim nor the README's "one command in two rows" quantifies over inference — `/release-notes` remains the only command that runs at two points in a VI's life.

### Changed
- **`/prompt-brainstorm` and `/prompt-grill-me` still emit nothing, and the reason is now written down** rather than left as an unexplained absence. Both end at a Phase 3 that *cedes the session* — a hand-off to `superpowers:brainstorming`, or a long interactive grill — so the expensive part of the run happens after the command's last controllable step. A cost line written there would price only the logging prologue and report a misleadingly small figure, and a wrong number is worse than a missing one because it gets aggregated and trusted. The same constraint already puts their `commit-artifacts` step *before* the hand-off (`references/specs-repo-git.md` §4).
- `references/cost-emission.md` §7 introduced itself as having "one inferred exception" and now has three. `docs/reference/session-cost.md`, `docs/roles-and-phases.md`, `docs/reference/session-feedback.md`, and the four feedback command pages all carried claims this change falsified — every one of them said these commands had no cost phase and that `cost-emission.md` "never mentions" them.

## [2.57.0] — 2026-08-22

### Added
- **`plugins/dev-workflows/docs/` — a 34-page documentation tree (new).** Four top-level orientation pages (`README.md`, `getting-started.md`, `workflow.md`, `roles-and-phases.md`), 21 per-command pages under `docs/commands/`, and 9 reference index pages under `docs/reference/`, replacing a single plugin README that had grown to 379 lines / 74,620 bytes, with a table cell of 2,066 characters against a 200-character readability target.
- **`scripts/check-docs.sh` (new CI gate).** Nine checks — internal links and anchors resolve; every docs page is reachable from `docs/README.md`; the commands/agents/reference-files/hooks/skills inventories match the shipped plugin tree; every plugin-read environment variable is documented, and every documented one is actually read; no table cell exceeds 200 characters; `getting-started.md`'s install commands match the repo-root README; every command that hands `emit-cost` a fixed phase/role pair has a matching row in `references/cost-emission.md` §7, with no §7 row naming a command that emits no fixed pair; and every prose count of an inventory matches the tree — plus a `--selftest` mode running 33 cases that mutate a copy of the passing fixture and assert both the gate's exit code and *which* check fired, so a check that stops being able to fail shows up as a red build instead of a green one. Wired into `.github/workflows/validate-catalog.yml` alongside the pre-existing `check-id-grammar.sh` and `validate-catalog.py` steps.

### Changed
- **`plugins/dev-workflows/README.md` rewritten from 379 lines / 74,620 bytes to 47 lines / 4,750 bytes**, its longest table cell cut from 2,066 to 196 characters. The full command reference, workflow map, and per-command detail moved into the new `docs/` tree; the README itself is now a role-indexed pointer table with a `## Documentation` section linking into `docs/`.
- **The repository's own `CLAUDE.md` now registers the `docs/` tree and its gate.** The structure block lists `docs/`, and a new convention bullet carries the derivation contract ("the retired README is a source of topics, never a source of facts"), the eight `check-docs.sh` checks with their pre-push and CI invocations, and the identity-quarantine rule that keeps every marketplace and container-repo name out of `docs/` except `getting-started.md`. Without it the next agent to add a command, agent, or environment variable would learn about the gate from a red build.
- **The role vocabulary is now four roles, not five: `team` is folded into `dev` (resolves D3 and D6).** `references/cost-emission.md` §7 had split the delivery lane into `dev` (`/design`, `/implement`, `/document`, and `/release-notes`'s inferred late run) and `team` (`/ready`, alone), while `references/next-phase-offer.md`, `references/session-hygiene.md`, and `references/workflow-states.md` all described a four-way `PM / PA / PE / Team` split — with `workflow-states.md` genuinely assigning `/implement` the role "Team" where §7 gave it `dev`. Two live contradictory instructions is a defect under `references/instruction-file-maintenance.md`, so the vocabularies are reconciled rather than annotated. **`dev` is the surviving name** on two grounds: it already labelled four of the five delivery-lane call sites against `team`'s one, and `team` collides with an unrelated live identifier — `jira-reader` emits a per-Epic `team` field verbatim from Jira Epic frontmatter (`[DTT] Team Storage`), which `epic-writer`, `epic-reviewer`, and `references/pre-lint.md` all read. That collision is untouched: every `team:`-the-Jira-field site is unchanged, and only role-sense occurrences moved.
  - `references/cost-emission.md` §7: `/ready`'s row is now `readiness | dev`. Nine cost phases, unchanged — only the role label moved.
  - `commands/ready.md`: the `emit-cost` call passes `role: dev`; the next-phase offer and `/rename` aid say Dev and `-dev`. The same `/rename` lane tag changes in `commands/document.md`, `commands/implement.md`, and `commands/design.md`, and role labels change in `commands/create-ard.md` (including one `choices:` option) and `commands/specify.md`.
  - `references/workflow-states.md`: both status ladders read `PE→Dev` / `Dev` / `Dev/PM`. `references/next-phase-offer.md` and `references/session-hygiene.md` read `PM / PA / PE / Dev`, and the session lane tags are `pm / pa / pe / dev`.
  - `docs/roles-and-phases.md`: the `## Team — verification` section is merged into `## Dev — build, verify, and deliver`, which now names `/ready` in its Runs/Consumes/Produces/seam bullets and carries a short paragraph on why verification is not a lane of its own. Inbound anchors in five command pages updated.
  - `docs/workflow.md`: the Mermaid `QA["Team — verification & gates"]` subgraph is gone — `ready` sits inside `DEV["Dev — build, verify & deliver"]`, and the Roles table's `Team` row is merged into `Dev`. `docs/commands/ready.md`, `docs/reference/resume-and-checkpoints.md`, and the plugin README follow.
  - The new `check-docs.sh` check 8 defends the §7 side of this: `/ready`'s emitted role and its §7 row can no longer drift apart silently.

### Fixed
- **Review round 2 (Ivan, 2026-08-23).** Five items from reading the rendered docs:
  - **No vendor name in open-source documentation.** Eleven descriptive sites said "Dynatrace REST API guidelines", "Dynatrace app code", "Dynatrace Experience Standards"; they now say "the bundled"/"vendored" guidance. Literal identifiers are deliberately kept — `dt-style-guide` / `dt-style-checker` (a real plugin and agent), `dynatrace-docs` (a real reference subtree and repo), `dynatrace-docs-frontmatter` (a real skill), and the verbatim `## Phase 3.5 — Dynatrace style check` headings, which the diagrams must quote exactly. A sample `author:` line carrying a real work address became `you@example.com`.
  - **Sample Jira IDs made obviously fake, everywhere.** `PRODUCT-14902` / `PRODUCT-15001` read like live tickets and had leaked into eight files including `references/source-truth.md` (§6 was even titled "Example (real, from PRODUCT-14902)"), `agents/jira-reader.md`, `hooks/preload-context.sh`, and the repo-root README's branch-naming example. A second, inconsistent convention (`PROD-1234`/`PROD-5678`) existed alongside. All now use `PRODUCT-1234` for a VI and `EPIC-98760` for an Epic. `docs/superpowers/**` is left alone — historical records, same rule as `CHANGELOG.md`.
  - **`/release-notes` had no link in the README's Dev row.** Its Commands cell was already 192 of its 200-character budget, so the link went into the row's description cell rather than breaking the readability invariant the restructure exists to establish.
  - **`/statusline` was findable only by scrolling the full command list.** It now has two rows in the docs index lookup table, and its Getting Started section explains what it actually buys. **That section was rewritten after checking the source:** the first draft claimed cost reporting is "priced from" the status line snapshot and is otherwise "reconstructed rather than measured" — the inverse of the truth. `references/cost-emission.md` §5 makes the snapshot **Option B, an optional cross-check**; Option A reads the transcript and works without it. The gap between the two is the signal that the bundled price table has drifted.
  - **`/feedback` and `/prompt*` were documented as one signal; they are two.** `/feedback` records what you say about the plugin. `/prompt*` records what you *did* about a bad result — the unsatisfactory output, every correction, and the output you settled on. That triple is the actionable one, because a correction made by hand three times is a rule the command should apply itself. `docs/reference/session-feedback.md` gains a section on this, and `/prompt`'s page a note to correct through the command rather than a plain prompt. **A claim was cut here too:** the draft said routing through `/prompt*` also gets the fix's cost accounted for. It does not — none of the four feedback commands emits a cost entry; the emitting set is a fixed eleven.
- **Getting Started installed two plugins `dev-workflows` does not use.** It listed all four marketplace plugins as if the pipeline needed them. Verified against the tree: `dt-style-guide` is referenced 32 times (primary style checker for `/epics` and the VI commands, fallback linter for `/document`), **`acli` zero times**, and `references/followup-emission.md:8` states outright that it has "NO runtime dependency on the obsidian-llm-wiki plugin" — it only *mirrors* that plugin's vault task conventions. The page now installs `dev-workflows` plus the recommended `dt-style-guide`, names `jira-workitem-import` as the non-plugin prerequisite it always was, and points at the marketplace README for the other two.
- **`check-docs.sh` check 7 relaxed from an equality pin to a subset pin.** The root README documents the whole marketplace; the plugin's Getting Started documents one plugin and should install only what that plugin needs — which equality forbade. Every install line on the page must still appear verbatim in the root README (what catches a drifted marketplace name), the `marketplace add`/`update` lines must be present, and the page must install the plugin itself. The fixture's root README now lists more than its Getting Started, so the standing pass-case exercises the subset direction rather than a degenerate equal-sets case. Two new fail-cases; selftest 33 → 35.
- **`session-cost.md` said eleven commands emit a cost entry and never said why the other ten do not.** Now it does, and the four feedback commands split: `/prompt-brainstorm` and `/prompt-grill-me` **cannot** report honestly, because both cede the session at Phase 3 and the expensive part of the run happens after their last controllable step — pricing only the logging prologue would produce a misleadingly small figure that then gets aggregated and trusted (the same constraint their git step already acknowledges). `/feedback` and `/prompt` have no such obstacle: both end in an ordinary terminal report phase, `/prompt` already resolves the `jira_key`, and §9's pending-file flow already handles a keyless run. That one is a gap, not a decision, and nothing in the plugin documents a reason.
- **D1 — the old README's Commands table listed 19 of 21 commands.** `/vuln` and `/upgrade` were orphaned in an unlabeled "Additionally:" table nested under the `/implement` workflow section, so a reader scanning the Commands table alone would not learn either command existed. Both are now first-class rows in the README's role table and in `docs/README.md`'s command list, and `check-docs.sh` check 4 defends the 21-command count going forward.
- **D2 — `references/cost-emission.md` §7 omitted `/update-vi`.** The table introduced itself as the complete "Fixed per-command labels" authority but listed ten commands; `commands/update-vi.md` calls `emit-cost` with `phase: vi-update, role: pm`, a phase value the table never enumerated. One row inserted immediately after `/create-vi`, preserving lifecycle-stage row order; the table now has eleven rows. That bidirectional check is now `check-docs.sh` check 8 rather than the one-off grep that originally found it, so a future command added with a fixed phase/role and no §7 row — or a §7 row whose phase or role drifts from what the command actually emits — fails the build.
- **D4 — Environment prerequisites gave a proper entry to 1 of 6 variables the plugin actually reads.** `DEV_WORKFLOWS_COST_PRICES` — the user-overridable per-model token-price table path used by session-cost reporting — was undocumented anywhere in the repository. All six variables now have proper entries in `docs/reference/environment.md`, defended by `check-docs.sh` check 5's exclusion list.
- **D5 — `references/` inventory undercounted by 5 files.** A markdown-only census (93 files) missed 5 non-markdown files actually in `references/`, including `cost-prices.yaml` — user-facing and user-overridable (see D4). `docs/reference/references.md` now inventories reference files by type rather than by markdown extension, defended by `check-docs.sh` check 4, which counts the same way.
- **`docs/workflow.md`'s pipeline diagram showed `/epics → /specify` as the only path into `/specify`**, omitting the direct VI-level path (`createvi -->|VI-level spec| specify`) that `docs/commands/specify.md` calls "genuinely valid, not a fallback of last resort". Carried verbatim from the old README.
- **Follow-ups had two different "primary location" answers.** `docs/workflow.md`'s artifact-homes bullet and `docs/reference/environment.md`'s layout block both filed follow-ups under `<VI-dir>/dev-workflows/` in `$SPECS_PATH`, while `docs/reference/follow-ups.md` — the authority — makes the vault primary and reaches the specs path only at tier 2 "no vault". Both now name the vault first and point at the full ladder.
- **`docs/commands/ready.md`'s collapsed Mermaid node relabelled from headings verbatim** — "Phase 6 — Post-run maintenance & feedback / Phase 7 — Emit follow-up tasks / Phase 8 — Session cost", matching `commands/ready.md`'s own `## Phase` headings and the equivalent node in `docs/commands/epics.md`.
- **`docs/commands/ready.md`'s `/design` comparison dropped the single-Epic case** its own parenthetical states one clause earlier: the two commands part company as soon as spec'd Epic subfolders exist at all, not only once they multiply.
- **`docs/commands/release-notes.md`'s `## Example` read dev-first**, walking the dev re-run in full and folding the PM run into a closing sentence, though `## Who runs it` presents the two symmetrically. Both runs now get equal treatment.
- **The plugin README's opening pitch enumerated phases and stopped short**, omitting `/epics`, `/release-notes`, and `/ready` — an enumeration asserting completeness by implication. It now names the spine explicitly and hands completeness to the table below it.
- **`docs/workflow.md`'s Jira-status bullet paraphrased the retired README** rather than deriving from a primary source; it now cites `references/workflow-states.md`, which states the same thing outright and stores no status of its own.
- **`docs/reference/environment.md` attributed "the bookkeeping is not committed" to `specs-preflight`**, which prepares but never commits; the commit is the terminal `commit-artifacts` step's, and the two share the §3.1 writable gate. The consequence was true, only the attribution was loose.
- **`scripts/check-docs.sh` check 6's own comment cited 2,177 characters** — the longest *line* of the retired README, not its longest *cell* (2,066). The gate measures cells.
- **`scripts/spec-id-baseline.txt` regenerated at −1 for each of `[Uxx]`, `[ACxx]`, `[TCxx]`,** with the reason recorded in its header. The README clause carrying all three placeholders was being kept solely to hold the frozen counts steady — the census constraining the corpus rather than describing it. No concrete `[U01]`/`[AC01]`/`[TC01]`-style identifier moved, which is what the tripwire actually guards.
- **The gate itself was adversarially reviewed by mutation, and hardened.** Every one of its 27 `fail()` sites was proven to fire with the correct check number — but the selftest could not detect the *deletion* of 13 of them, including the exact defect this gate was written to prevent: neutralising check 1's root-README file-list entry left `SELFTEST PASS`, because `scripts/fixtures/docs/pass/README.md` had no relative link to break. The fixture root README now has one, and that mutation now turns the suite red.
  - **check 6 now scans the repo-root README**, which it had never covered — a 298-character cell was sitting there unflagged, on the page a new user reads first. It also no longer drops the final cell of a row written without a trailing `|`, which GitHub accepts.
  - **check 7 pins `reinstall`**, the verb `CLAUDE.md`'s own "Updating installed plugins" section teaches; only `marketplace add`, `marketplace update`, and `install` were pinned, so a drifted marketplace name on a `reinstall` line passed.
  - **checks 1 and 2 now strip fenced code blocks**, which they alone did not. This failed in both directions at once: an illustrative link inside a ` ```markdown ` block tripped check 1, while `#` lines *inside* fences were harvested as real headings — three exist today, and a link to one was being accepted.
  - **The reference-subtree check derives its directory list from the tree** instead of a hardcoded six, so a wholly new `references/<subtree>/` can no longer ship undocumented; and it gained the reverse direction, so deleting a subtree the page still advertises now fails.
  - **check 5's reverse direction no longer depends on `**` emphasis markers** — reformatting `environment.md` silently emptied the loop, and no case covered that direction at all.
  - **check 8 gained an extractor-coverage assertion.** A reworded `emit-cost` call site made it go *quiet*, and the message it did print blamed the table — inviting a "fix" (delete the row) that would have silenced it permanently. Any command mentioning `emit-cost` that yields no triple now fails, naming the extractor as the culprit.
  - **Substring matching anchored** in checks 4 and 5: `references/format.md` passed because `vi-format.md` was listed, and `$PATH` passed because `SPECS_PATH` was documented.
- **check 9 (new): the prose counts nothing was gating.** check 4 gates the inventories in both directions, but not the sentences stating their size — a 22nd command with a page and an index link would pass while `plugins/dev-workflows/README.md` still read "twenty-one slash commands", and a reader meets the sentence before the table. Six counts are now derived from the tree: commands, agents, reference files, hooks, skills, and user-settable environment variables (that last from check 5's own scan, so the two cannot disagree about what "user-settable" means). It fires on a wrong number **and** on a count sentence reworded away — the vacuous-pass mode that would otherwise silence it.
- **`RUNTIME_VARS` frozen against a checked constant.** Every name in check 5's exclusion list silences both directions for that variable permanently, and no fixture mutation can reveal it. Changing the list now trips a tripwire demanding the justification comment be updated in the same edit. It guards a constant in the file that runs it, so `--selftest` structurally cannot exercise it; it is verified out-of-band and the script says so at the definition.
- **Six gate bugs that fail on *correct* content, fixed.** `slugify()` deleted non-ASCII letters, so a correct `#über-config` link failed check 2; it never generated GitHub's `-1` duplicate-heading suffix, so a correct link to a second `## Notes` failed too. Both are now produced by `python3`, which casefolds and classifies Unicode independently of locale — verified byte-identical to the previous path on all 292 headings in the tree, and verified correct under a forced `LC_ALL=C`, which is what this container actually runs. Check 1 rejected `[x](f.md "Title")` and `[x](<f.md>)` — both legal CommonMark — by resolving the title or the brackets as part of the path. Check 3 treated `docs/README.md` as the sole reachability root, making a page linked only from the plugin README a false orphan. Check 6 measured tables inside `~~~` fences and, in its one vacuous direction, never measured an indented row at all. All six were first deferred as "latent"; three of them are one to three lines, and the deferral had neither an owner nor a trigger.
- **`check-docs.sh --selftest` grew from 11 cases to 33** — the skills sub-check's second direction (a documented skill that does not exist) had no case, and the new check 8 gets three: an unattributed `emit-cost` call, a drifted role in §7, and a §7 row for a command that emits no fixed pair.

## [2.56.2] — 2026-08-22

### Fixed
- **`api-guideline-reviewer` declared an unused `Bash` grant.** The agent reviews OpenAPI specs by
  reading them; it names no executable, and `references/api-guidelines/` holds only markdown and a YAML
  template — there is no script to run. Every other read-only reviewer declares
  `["Read", "Glob", "Grep"]`, and every other `Bash` holder either uses it (`code-scanner`,
  `diff-summarizer`, `docs-grounder`, `guideline-reviewer`, `test-baseliner`) or bounds it explicitly
  (`risk-planner`, `interface-designer`, `doc-writer`). This one did neither. Its sibling
  `guideline-reviewer` keeps `Bash`: it genuinely runs `references/guidelines/check_guidelines.py`, so
  the pair now diverges at the agent level for a real reason. Both commands' `allowed-tools` are
  deliberately unchanged — each is a thin dispatcher and the pair declares an identical set.

## [2.56.1] — 2026-08-22

### Fixed
- **`doc-fixer`'s `NEEDS HUMAN` stop had no consumer anywhere.** The agent has emitted
  `Stop condition flag: [CLEAR | NEEDS HUMAN]` since 1.1.0, and its own hard rules say the caller "reads
  it to decide whether re-running the review is worth doing" and "must surface the deferred BLOCKERs to
  the user and stop the automated cycle". No caller read it: `/document` (both modes) and `/epics` went
  straight from `doc-fixer` to re-invoking the reviewer or the linter. Three unconsumed sites are now
  closed — `/document` Phase 7 (`doc-reviewer`-fed), `/document` Phase 6.4 and direct-mode Phase 3.5
  (`docs-style-checker`-fed, which maps a linter's own blocking failure to `BLOCKER`). The style-cycle
  handlers record the `style_check` row from the user's answer per `references/gate-ledger.md`. The
  `/epics` style cycle deliberately gets no handler: `dt-style-checker` caps at `MAJOR`, so `NEEDS HUMAN`
  cannot fire there and a guard would protect a state nothing reaches — `doc-fixer.md` now records that
  reachability map so the absence is not read as an oversight. 2.54.0 fixed exactly this class for
  `review-fixer` across its three callers, but scoped the sweep to `review-fixer` and never asked whether
  the plugin's other fixer emitted the same flag. It did.
- **A `code-review` `BLOCK` caused by an unreadable diff was indistinguishable from a substantive one.**
  2.54.0's read-failure contract had `code-review` return `BLOCK` when the **Diff** evidence input could
  not be read, but gave the verdict no marker — so `/implement`, `/vuln`, and `/upgrade` routed it through
  the ordinary BLOCK branch, triaged a finding that names a capture failure, and handed `review-fixer` a
  finding no fixer can act on, reaching the correct outcome only after spending a fix dispatch and a
  re-review. `code-review` now returns the literal first-line marker `Diff: unreadable at <path>`,
  mirroring `test-writer`'s, and all three commands check that line before acting on the verdict. The
  plugin already treated the three sibling cases this way in these words — an orchestrator bug, not a
  user choice — for `test_diff_file`, `research_file`, and `plan_file`; `review_diff_file` was the
  fourth and was the only one left out.
- **`/design`'s `model_routing` block under-reported its own detection chain.** The `detection_model`
  comment read `# code-scanner` while three agents route on that chain — `code-scanner`,
  `interface-designer` (2.56.0), and `impl-maintenance`. Now names all three.

## [2.56.0] — 2026-08-22

### Added
- **`interface-designer` agent (new).** Produces **one** interface proposal for **one** contested
  interface under **one** named design constraint, read-only, dispatched three times in parallel and
  blind to each other so the takes genuinely diverge instead of converging on what an agent imagines its
  siblings will say. A design's interface is the highest-leverage decision it makes and the hardest to
  walk back once callers depend on it — a single pass tends to anchor on the first workable shape rather
  than surface the trade-off space.
- **`/design` Phase 5 offers a three-take interface fan-out** when the interview reaches an interface
  decision that is **contested** — two or more plausible adapters, a shape spanning a process/network
  boundary, three or more callers sharing it, or two or more recorded candidate shapes with none
  eliminated (`references/design-format.md` `## Seams`). The three takes are compared on **depth**
  (behaviour reached per unit of interface a caller must learn), **locality** (where change, bugs, and
  verification concentrate), and **seam placement** (whether the boundary falls where things actually
  vary) — named axes instead of impressions, so the comparison is repeatable. Declining costs nothing:
  the interview continues and `### Alternatives considered` is filled by hand as it always was.
- **`--design-twice`** forces the fan-out even when no contested-interface signal fired: the offer is
  skipped and the three takes are dispatched directly. A user who typed the flag has already given the
  answer the offer would ask for, so re-asking would be a prompt that changes nothing. The offer itself
  carries **no `(Recommended)` marker on either option** — it is shown only once the interface is already
  contested, so no option is safe to recommend across the runs that reach it.
- **`### Alternatives considered` is now unconditional** in `design-format.md`'s
  `## Architecture & components` section — every `design.md` records at least one genuinely rejected alternative and why, whether or
  not the fan-out ran. `risk-planner` already holds plans to this bar ("name at least one alternative
  that was rejected and the reason"); a design was the weaker artifact for not matching it. Making it
  unconditional turns the fan-out into a quality upgrade to a requirement that already fires every time,
  rather than a prerequisite that only exists when the fan-out is chosen — so declining the fan-out never
  reads as skipping a step.
- **Four dependency categories** — `in-process`, `local-substitutable`, `remote-but-owned`,
  `true-external` — now classify each seam in `## Seams` and decide how `## Test strategy` tests it: a
  port with an in-memory adapter for `remote-but-owned`, a mock adapter for `true-external`, no adapter
  needed for the first two. A category implying only one plausible adapter is a hypothetical seam under
  the existing two-adapters heuristic — it should not exist yet.
- **`design-reviewer` gains two checks.** Every named seam's dependency category is cross-checked against
  its test strategy — a `remote-but-owned` seam tested without a port, or a `true-external` dependency
  tested without a mock adapter, is a `MAJOR`; a `MODERATE`+ design with an uncategorized seam is a
  `MINOR`. `### Alternatives considered` must be present **and substantive** — missing is `MAJOR`, and an
  alternative nobody would have shipped ("we considered not having an interface") is `MAJOR` too, because
  it satisfies the check while teaching the reader nothing, which is worse than the check failing openly.
- **The `/design` final report always states the fan-out outcome** — `ran`, `offered and declined`, or
  `not offered — no contested interface`. A run where the signal was too narrow to fire is now visible in
  the report instead of silently indistinguishable from a run where the fan-out was never relevant.

## [2.55.0] — 2026-08-22

### Added
- **Bug-diagnosis evidence gate.** `bug-diagnosis.md` gains a **redaction** section — the discipline has
  you show commands, their output, and captured artifacts, and a HAR file or core dump carries auth
  headers — plus step 1's **completion criterion**: name **one** command you have *already run at least
  once*, showing the invocation and its redacted output. Red-capable, deterministic, fast, agent-runnable.
  *No red-capable command, no step 2.* Flaky bugs get reproduction-rate guidance: raise the rate until the
  bug is debuggable rather than chasing a clean repro.
- **`risk-planner` can now run the repro it reasons about.** It gains ``Bash`` for that purpose alone —
  bounded to the repro and read-only commands, never mutating the working tree, index, `HEAD`, or branch
  state. A plan is produced *before* the user has approved any action, so a repro that would itself mutate
  the tree is described rather than run. It must show the repro it ran, or **withhold the ranking** and say
  what it tried; ``/implement`` Phase 2B consumes that with a Help / Proceed-and-record / Cancel choice instead
  of falling through to "Approve & implement now". Ranking a bug's causes without ever observing it reads as
  confident work and is exactly what the criterion exists to prevent.
- **Dispatch bounds on the three agents that hold ``Task``.** `docs-style-checker`, `upgrade-executor`,
  and `vuln-fixer` each name their single legitimate target and may never spawn a reviewer. The bound rests
  on **authority, not redundancy**: the caller owns the gate policy, and on some paths it deliberately runs
  no reviewer at all — so a reviewer a worker spawns silently overrides that choice while producing a verdict
  nobody consumes. Each agent cites the mechanism its *own* caller uses — mode for `docs-style-checker`,
  classification for the other two.

### Notes
- `code-review` deliberately does **not** gain ``Bash``. Its verdict gates the test run, and its hard rule
  "NEVER modify files" would become unenforceable.
- The upstream rule that reviewers must not route findings through a host findings-reporting tool was
  **considered and dropped**: all eight gating reviewers declare restrictive tool lists, so it could never
  fire. Recorded in `NEXT.md` so it is not re-derived as a gap.

## [2.54.0] — 2026-08-21

### Added
- `references/context-management.md` gains a read-failure contract for every input a caller hands over inline or as a path: an unreadable **evidence** input (a diff, a research report, an upgrade plan) is a hard stop that is never regenerated by other means, while an unreadable **context** input degrades to absent and the output records the degradation. Closes a gap where `code-review` could silently re-derive its own `git diff` at the wrong base, or `test-writer` could proceed with no diff at all, both while reporting success. Cited by `/implement`, `/vuln`, and `/upgrade`, and stated by six agents: `risk-planner`, `code-review`, `test-writer`, `review-fixer`, `vuln-fixer`, `upgrade-executor`.
- `code-review`, `doc-reviewer`, and `epic-reviewer` gain an optional `claims_file` input and a final conditional **Claims falsification** dimension (10→11, 17→18, 18→19 dimensions respectively) that runs only after every other dimension is complete and its findings are recorded. The file holds the fixer's or executor's own account of what it changed; the reviewer treats it as testimony, not evidence, and tries to falsify each checkable claim against the diff or files it has already traced independently — so it never reads the account of what the change supposedly did before forming its own view.
- `references/finding-triage.md` (new): the orchestrator-run step between an Opus reviewer's findings and a fixer's dispatch. Verifies each finding's claimed consequence at the location it names, keeps or dismisses (recording every dismissal with a reason that disposes of that finding's own claim), and hands the fixer survivors only. Its patch gate blocks a fixer from adding a guard for state the finding did not demonstrate — the most common shape a "fix" for a false positive takes, and the reason it's invisible afterwards (it looks like defensive coding). Attaches only to a reasoned-claim producer feeding a fixer (`code-review`/`doc-reviewer`/`epic-reviewer` → `review-fixer`/`doc-fixer`), never to a style-checker-fed dispatch.
- A triage step citing `finding-triage.md` added to five commands — `/implement`, `/document`, `/epics`, `/vuln`, `/upgrade` — between the reviewer verdict and the fixer dispatch, plus a `### Review triage` section in each final report (findings reviewed, survivors, every dismissal with its reason).
- `references/instruction-file-maintenance.md` (new): rules for changing an agent-instruction file (`CLAUDE.md`, rules files, this plugin's own `references/*.md`) — verify every claim against the thing that runs it, itemise a narrowing rewrite as the deletion it is, prefer an observable trigger over one the agent must judge, and require grounds for retirement, never "it looks derivable" or "nothing has failed on it lately". Cited by `impl-maintenance` before it proposes any instruction-file change, and binding on hand edits too — which is where most stale claims originate.

### Changed
- `claims_file` wiring added at the `/implement`, `/document`, and `/epics` re-reviews (passed once a fix cycle produces a Fix Report). At `/vuln` and `/upgrade`, `claims_file` is **relocated** out of the inline review brief: previously `code-review` read the fixer's/executor's account of its own work as part of the same brief everything else came from, before tracing anything. It now arrives as its own temp-file path and is read only in the deferred Claims falsification dimension, after every other dimension is complete.

### Fixed
- `README.md`'s agent table said `code-review` had 8 dimensions and `epic-reviewer` had 9 — both counts were already stale before this round: the actual pre-round counts were 10 (eight base plus the previously-shipped conditional ARD-conformance and spec/design-conformance dimensions) and 18 (the previously-shipped conditional partition-integrity, cross-team-dependency, and team-preserved dimensions among others). Both entries now carry the correct post-round counts (11 and 19); `doc-reviewer`'s entry, which was accurate before this round, moves from 17 to 18.

## [2.53.2] — 2026-08-18

### Fixed
- `ard-resolution.md` now accepts a legacy `### [AD-N]:` heading and emits `AD#N`, matching the
  tolerance `jira-reader` already has. It is a reader, and unlike a VI — which `/update-vi` rewrites —
  an ARD has no `/update-ard` to convert it, so a dash-form ARD authored by a pre-2.53.0 install on
  another machine would never drain. The failure was silent in the worst way: the file still resolves
  `status: found`, but with an empty `invariants` list every consumer's ARD-conformance dimension is
  skipped exactly as if no ARD existed — a binding architecture document enforcing nothing, under a
  run reporting success.
- `scripts/spec-id-baseline.txt` no longer counts `CHANGELOG.md`. Counting it desensitised the
  tripwire — any release note quoting a spec ID shifted the numbers and trained the reader to
  regenerate the baseline instead of investigating. The old header claimed changelog counting was
  what made the three editions comparable; the opposite was true, since the editions keep different
  changelogs. With it excluded, all three editions' baselines are byte-identical, so drift in one is
  now visible as a difference from the other two.

## [2.53.1] — 2026-08-18

### Fixed
- `readiness-reviewer` no longer BLOCKs on a legacy dash-form requirement ID. The previous release
  made it a BLOCKER, which forces a `NOT-SUPPORTED` verdict — but `/ready` reads artifacts it did not
  author, and that same release deliberately left pre-existing artifacts unconverted, to drain as
  `/update-vi` rewrites each one. The rule could therefore only ever fire on the case the design chose
  to tolerate: every canonical VI already under `$SPECS_PATH` would have failed `/ready` on grammar
  alone, while anything freshly authored had already cleared `vi-reviewer` / `ard-reviewer` /
  `epic-reviewer`. It is now a MINOR that never moves the verdict on its own, reported with the fix
  ("convert via `/update-vi`"). The four authoring gates are unchanged and still BLOCK.
- `scripts/check-id-grammar.sh` caught `[US-N]` but missed `[US-n]`, `[AC-x]`, `[SM-Cx]` and bare
  `SM-Cx`: the bracketed branch used the number class `[N0-9]` while the bare branch used `[Nn0-9]`,
  and neither covered the `x` / `X` placeholder. The blind spot had already cost one hand-fix during
  the conversion itself, when `[SM-Cx]` passed the gate green in `vi-reviewer.md`. All four
  alternations now share `[NnXx0-9]`.
- The gate excluded `docs`, `fixtures`, `.remember` and `.superpowers` by bare directory name, so a
  directory with any of those names at any depth — a future `plugins/<name>/docs/` — was silently
  unscanned. The exclusions are now anchored to the scan root.

### Added
- `scripts/check-id-grammar.sh --selftest` asserts the gate's exit code against each fixture, and CI
  runs it before the tree scan. The fixtures shipped in the previous release but nothing executed
  them, so nothing proved the gate could still fail. A new fixture,
  `scripts/fixtures/vi-bad-placeholders.md`, fails *only* on placeholder forms — re-narrowing the
  number class turns the self-test red instead of passing unnoticed.

## [2.53.0] — 2026-08-18

### Changed
- VI, ARD, and Epic requirement IDs now use `[PREFIX#N]` (`[AC#1]`, `[US#1]`, `[AD#1]`) instead of
  `[AC-1]`. The dash form has the shape of a Jira issue key, so pasting an artifact into Jira
  auto-linked criteria to unrelated tickets in any project sharing the prefix, and the vault
  importer rewrote them into `[[[AC-1]]]` on export. `vi-reviewer`, `ard-reviewer`, `epic-reviewer`,
  and `readiness-reviewer` now treat a surviving dash-form ID as a BLOCKER (for `readiness-reviewer`,
  that means a `NOT-SUPPORTED` verdict).
- `epic-writer`'s `## Covers` now emits bracketed IDs; it previously emitted bare `US-2, AC-4`,
  which both Jira and the importer mangled.
- `jira-reader` accepts both forms inside requirement-bearing sections and always emits `#`, so
  already-published VIs still parse.

### Added
- `pre-lint.md` gains a Jira-key collision check for VI / ARD / Epic files. Its contract sentence and
  the four commands that produce those artifacts (`/create-vi`, `/update-vi`, `/create-ard`, `/epics`)
  name the check explicitly, so it actually runs; `/specify` and `/design` do not, because the check's
  scope excludes `specification.md` / `design.md`. A hit that is neither a requirement ID nor a real
  ticket — a standards or protocol reference such as `ISO-8601` or `RFC-8446` — is reported and left
  exactly as written, never converted and never wrapped in a wikilink.
- `scripts/check-id-grammar.sh` gates the repo against reintroducing the dash form, and now runs on
  every push via `.github/workflows/validate-catalog.yml`. The grammar and the script that enforces it
  are documented in `CLAUDE.md`'s Conventions section.

## [2.52.0] — 2026-08-15

### Breaking changes

- **`/create-vi` no longer relocates `idea.md`.** `/idea` now owns relocation and hands the idea off itself. `/dev-workflows:create-vi <KEY>` derives the idea from `specifications/<KEY>-<slug>/idea.md` and requires it on the specs repo's default branch. `/dev-workflows:create-vi <KEY> @<path>` is explicitly out-of-contract: it reads the idea where it sits, does not move it, and is not gated. A run that previously passed `@<path>` for a vault idea keeps working; a run that relied on `/create-vi` moving the file must now let `/idea` do it.

### Added

- **New shared reference `phase-handoff.md`, with two entry points.** `handoff-to-main` (§2, the producer side) resolves or reuses a plugin branch, stages the deliverable by enumeration, commits with a carried `Co-Authored-By` trailer, pushes, and opens a pull request via a `gh` capability probe rather than a host-type classification. `require-on-main` (§3, the consumer side) is a ten-state gate — rows H/I/G/A/B/C′/C/D/E/F, first matching row applies — tested against `origin/<default>` by ref rather than by worktree contents. §3.4 carries the row-F delegation table naming each caller's pre-existing absent-input behaviour, so a gate never turns an optional artifact into a hard prerequisite; §4.1 defines the single `Phase handoff:` outcome line every producer emits exactly once; §4.3 defines the three-choice consent array (`Branch + commit + push + open PR` / `Just write the files` / `Cancel`) every producer presents verbatim. It inherits four of `specs-repo-git.md`'s hard rules unchanged and deliberately diverges on three: `require-on-main` is fatal by design (a gate that reports and continues is not a gate), the deliverable commit carries the `Co-Authored-By` trailer `specs-repo-git.md` forbids for bookkeeping commits, and `handoff-to-main` runs only behind the caller's own consent choice rather than prompt-free.
- **Eight producers now commit, push, and open a pull request for their deliverable, via `handoff-to-main`.** `/idea` (Phase 5, on a completed handoff — relocating `idea.md` into `$SPECS_PATH` first), `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, a new Phase 4.5 in `/implement` (for the spec/design-conformance notes step 7.5 writes back), and a new handoff step in `/ready`'s Phase 5 (for its `_readiness.md` snapshot).
- **Seven consumers refuse to proceed until the artifact they depend on is on the default branch, via `require-on-main`.** `/create-vi` (its own `idea.md`), `/create-ard` (the VI), `/specify` (the VI), `/design` (`specification.md`, gated at both the flat and per-Epic resolution points), `/implement` (its in-scope `specification.md`/`design.md`), `/epics` (the VI-level `specification.md`), and `/ready` (every `specification.md`/`design.md` in its artifact inventory). An absent optional input still delegates to each command's pre-existing behaviour per §3.4's row F — `/idea` stays optional for `/create-vi`, `/create-ard` still falls back to `jira-reader`, and VI-level `/specify` grounding is still just skipped, never gated. `/update-vi` deliberately never calls `require-on-main` at all: its authoritative base is the Jira import, and gating its read-only secondary grounding would block a legitimate refresh over an unrelated branch.
- **`ard-resolution.md` gains `status: unmerged`, alongside the existing `found`/`none`.** Reachable only when an ARD file resolves but is not yet on the specs repo's default branch (verified via `phase-handoff.md` §3), carrying the resolved `branch` and any open `pr` through to the caller. Every caller stops on it except `/ready`, which records "ARD authored, not handed off" as a readiness finding capping the verdict at `PARTIAL` — reporting that distinction is the one thing `/ready` exists to do. `status: none` is unchanged: the no-regression rule still guarantees a run with no ARD at all is byte-identical to before this feature.
- **Two new branch prefixes, `idea/` and `ready/`.** `specs-repo-git.md`'s plugin-owned-branch authority is now `^(idea|vi|ard|spec|design|ready)/` everywhere it is declared — the hard rules (§1 rule 3), §2.2, the G2 stop-notice table row, and the branch-key-extraction list that strips a caller's prefix before matching a run's key set.

### Fixed

- **`/design`'s on-main gate was a worktree file-existence check at both the sites that need it, so a branch carrying an unmerged `specification.md` passed it.** Phase 0 step 3's target resolution now executes `require-on-main` against the resolved path and stops on any non-`pass`/`pass_amending` state; the Epic picker (step 4) now enumerates spec'd Epics with `git cat-file -e "origin/<default>:…"` directly, so an Epic whose `specification.md` exists only on a branch is excluded from the picker (and counted separately, with its own reason) instead of being offered as selectable.
- **`/implement`'s Phase 7.5 spec/design-conformance notes and `/ready`'s `_readiness.md` snapshot previously had no commit path of their own, so they sat uncommitted in the specs repo indefinitely** — tripping `specs-repo-git.md`'s dirty-OTHER-path advisory on every subsequent run instead of ever reaching anyone who could act on them. `/implement` gains a new Phase 4.5 that hands the annotated `specification.md`/`design.md` off via `handoff-to-main`, placed after Phase 4's maintenance and before Phase 6's follow-ups — calling it from inside Phase 3B, where step 7.5 writes the notes, would commit mid-review. `/ready` hands `_readiness.md` off at its Phase 5 step 3, behind the same consent choice, without ever stopping on the outcome itself — an unmerged or missing artifact becomes a readiness finding, never a run-stopping gate, because reporting readiness is `/ready`'s whole function.
- **The "never opens a PR" statements in `finish-and-handoff.md`, `specs-repo-git.md`, and `document.md`'s host footer read as a blanket policy; they were only ever a host-capability limit.** Bitbucket — the docs-repo host `finish-and-handoff.md` and `document.md` govern — has no CLI that can open a pull request, so that flow still only writes a draft plus a footer instruction. The GitHub-hosted specs repo does have one: `phase-handoff.md` §2.6 opens the pull request there through a capability probe (attempt `gh pr create`, fall back to the manual-open instructions on any failure) rather than a host-type classification, because push authority and pull-request authority can differ for the same account even on the same host.

## [2.51.0] — 2026-08-13

### Fixed

- **`CLAUDE.md`'s workflow map and agent ledger were stale in twelve places.** Caller lists and invariant bullets had drifted out of sync as `/update-vi`, `/create-ard`, `/ready`, and `/upgrade` were added without updating the consumers they now call — `doc-fixer`'s ledger line wrongly credited `/release-notes`, `risk-planner`'s ledger line omitted `/upgrade`, the `model-routing` must-load roster omitted `/update-vi`, the `source-truth.md` consumer list named 3 of 5 real consumers, and more. All twelve corrected against the actual dispatch sites.
- **Eight more agent/reference "used by" lists carried the same drift, plus one routed-in fix.** `cost-emission.md` omitted `/update-vi`; `feedback-emission.md` and `README.md` said `emit-auto` has twelve callers when it has thirteen; `risk-planner.md` named `/vuln`, which never dispatches it; `vi-reviewer.md` omitted `/update-vi` Phase 4; `jira-reader.md` omitted `/create-ard` and `/ready`; `grilling-technique.md`'s bounded/relentless lists omitted `/prompt-grill-me`, `/update-vi`, and `/create-ard`; `jira-input-resolution.md` omitted `idea-reader` as a `resolve-export-for-key` consumer; and `README.md`'s `jira-reader` agent-table row was incomplete. Separately, `references/ard-resolution.md`'s Consumers list gained `/ready`, which resolves an applicable ARD in Phase 2.5 and checks artifacts against it.
- **`/document` direct mode was documented as running a `doc-reviewer` gate it never runs.** `CLAUDE.md`'s workflow map and invariants, and `commands/document.md`'s shared mode preamble, described direct mode as sharing `doc-reviewer` with Jira mode. It never dispatches one — direct mode's only gate is a mandatory style check plus `doc-fixer`, with no BLOCKER fix cycle and no re-review. Both files now say so explicitly, and `CLAUDE.md` cites the two `document.md` rules (`:1490`, `:1494`) that depend on that absence.
- **`/document`'s "no refresh" repo-refresh choice did nothing.** Phase 1 offered three choices (`fetch only`, `fetch + pull default branch`, `no refresh`), but the Phase 5 dispatch block hardcoded `fetch: true` regardless of which one was picked — choosing "no refresh" still fetched. The dispatch now sends `fetch: false` only when "no refresh" was chosen (and `pull: true` only for "fetch + pull"), and the choice label now states its consequence up front.
- **`diff-summarizer`'s GitHub (`gh` CLI) resolver fetched unconditionally, defeating the fix above.** When a PR's head/base commits were missing locally, the resolver always ran `git fetch` (falling back to `gh pr checkout`) regardless of `refresh.fetch` or a read-only mount. It now runs those writes only when `refresh.fetch` is true **and** the mount is not read-only; otherwise it records the PR under `unresolved_prs` with a reason instead.
- **Two SSOT promises overstated what their non-primary producer actually does.** `read-only-repos.md` said "every consuming agent" emits its §6 `prep` block, but `docs-grounder` returns a digest, not a `prep` block — narrowed to name `code-scanner` and `diff-summarizer` as the `prep` emitters, with `docs-grounder` following only §1–§4. `source-truth.md` §4.1 assigned `diff-summarizer` the duty of surfacing enum/schema/constant/label changes in its PR summary — a duty its own agent spec never implements — reassigned to `doc-planner`, which verifies those claims directly against shipped source.
- **`/ready` ran its dirty-tree/branch prompt before the preflight that would have cleared the dirt it was warning about.** The specs-repo preflight (which flushes leftover session artifacts and settles the branch) sat after the dirty-tree check in Phase 0, so none of that check's three choices could actually resolve state the preflight was about to fix. The preflight now runs immediately after `$SPECS_PATH` resolution, ahead of the dirty-tree check.
- **`/release-notes`' terminal phases ran in the wrong order, and the rule that should have caught it was too vague to.** Phase 9 emitted follow-up tasks and Phase 10 ran feedback — the reverse of every other command's feedback-then-follow-ups order. The phases are swapped (feedback is now Phase 9, follow-ups Phase 10, cost stays Phase 11), and `session-hygiene.md` rule 2 now names the binding "emitter tail" (feedback → follow-ups → cost → `resume.md` → `commit-artifacts`) explicitly, clarifying that a command's deliverable-side finish may land at any point before that tail without consequence.
- **`/idea`'s round-2 narrow code-scan didn't state its `refresh:` posture, risking a silent default.** Round 2 reused round 1's `capability_themes` and `search_hints` but never named the `refresh:` block, so a round-2 dispatch could pick up default (not-read-only) behavior instead of round 1's pinned read-only posture. `classification.md` §8.5 now states that round 2 reuses round 1's `refresh:` block verbatim.
- **`/idea`'s bounded grill was still capped at ≤5 questions across six citing files**, well under the cap that later commands were built to expect. Raised to ≤10 in `commands/idea.md`, `README.md`, `grilling-technique.md`, `docs-grounding.md`, `vault-prior-art.md`, and `CLAUDE.md` (its two "VI-creation flow" and "`$DOCS_PATH` docs grounding" invariant bullets). A follow-up fix-round correction: `grilling-technique.md`'s ambiguity-taxonomy sentence had briefly hardcoded the literal "≤10" for all bounded callers, which is false for `/prompt-grill-me` (still ≤5) — corrected to name each caller's own stated bound instead of a specific number.
- **§8.5's "outside-deferral" rule was written as a blanket rule but only holds for one caller.** A theme confirmed `absent` was called "resolved" only if nothing was deferred to a repo outside the scanned set — correct for `/implement`, whose premise is that the capability lives somewhere in-scope, but wrong for `/idea`, where the confirmed repo set *is* the whole world it grounds against. `classification.md` §8.5 now scopes the outside-deferral qualifier to `/implement` only; `/idea`'s `absent` findings resolve unconditionally. `idea-format.md`'s `sources[].provenance` enum also gained the `doc-grounding` value it was missing.
- **The cost-subsystem roster prose and price table had drifted from the actual routing chain.** `cost-emission.md` said the shipped price table covers "every model the routing policy can reach," but Haiku is priced despite no routing path currently reaching it — corrected, and a stale "Opus 4.5-4.8" chain-summary comment in `cost-prices.yaml` was corrected to "Opus 4.6-4.8," matching `classification.md`'s real chain. A run whose tokens are dominated by an unpriced model previously surfaced that only as an easy-to-miss `note: unpriced-model` field inside the persisted YAML — `emit-cost` now also prints a visible warning line to the run output naming the model and stating the figure is a lower bound. A new §12 maintainer checklist documents the two files (the fallback chain and the price table) that must be updated together when a new model generation ships.
- **`read-only-repos.md` was cited as consumed by "the seven commands that dispatch" its three consumer agents**, undercounting `/idea`'s sub-project-H wiring, which made it eight. Corrected in `CLAUDE.md` (canonical `README.md`'s copy was already corrected during an earlier fix round in this release).
- **`README.md`'s reference-docs catalog carried the same stale caller/count claims found and fixed elsewhere in this release — a third, previously unswept copy.** A systematic re-derivation (from the actual citing files, not copied from `CLAUDE.md`) of every consumer/caller/count claim in the catalog found six more divergences: `ard-resolution.md`'s consumer list missing `/ready` (which resolves an applicable ARD in Phase 2.5); `grilling-technique.md`'s missing `/create-ard` and `/update-vi`; `source-truth.md`'s missing `doc-writer` and `risk-planner`; `followup-emission.md`'s missing `/ready` (duplicated in the Environment-prerequisites section too); the "nine VI-lifecycle commands" cost-phase claim undercounting `/update-vi` and `/ready` (duplicated across the Session-cost-reporting section and the `cost-emission.md` catalog entry — both now "eleven"); and the "Architecture (ARD) consumption" section's command list missing `/epics` and `/ready`. All six corrected at every site they appear; every other catalog entry was checked against the tree and found already correct.
- **The Environment-prerequisites section's own `SPECS_PATH` bullet was the same defect class again, and the biggest instance of it.** "Used by `/implement` (required) and `/document` (additive)" described the world before sub-project C wired specs-repo git into the whole command surface — 17 commands now touch `$SPECS_PATH`, not 2, and lumping them into one required/one additive erased three more real distinctions: six commands (`/design`, `/specify`, `/create-ard`, `/create-vi`, `/update-vi`, `/ready`) hard-require it with no override; `/implement` requires it only in Jira-driven mode and only with an override ("Proceed without specs — not recommended"); three (`/document`, `/epics`, `/release-notes`) read/write its content additively; and the remaining seven never touch specs content at all — their only use is the session-artifact bookkeeping every one of the seventeen commands shares. The bullet now states all four tiers. The adjacent `VAULT_PATH`, `REPOS_PATH`, and `DOCS_PATH` claims (the "Sources of truth" bullets and the `$DOCS_PATH` / `$VAULT_PATH` grounding paragraphs) were checked the same way and found already accurate — no fix needed there.
- **`source-truth.md`'s own "sub-agent that synthesises documentation" sentence was stale by one name.** It listed `doc-planner`, `doc-reviewer`, and `release-notes-writer` — an earlier fix in this release corrected the parallel `CLAUDE.md` catalog entry from three names to five, but never touched this sentence inside the reference file itself, leaving `doc-writer` (which writes the documentation the other three plan, verify, and draft) still missing. Added `doc-writer`. `risk-planner` — also a `source-truth.md` consumer per `CLAUDE.md`'s catalog — was deliberately left out of this specific sentence: it cites the file's §7 escalation rule only to avoid silently resolving a Jira-vs-source discrepancy while risk-planning code changes, and its deliverable is an implementation plan, not documentation, so it falls outside "sub-agent that synthesises documentation."
- **Whole-branch review fix wave (five Minors on live plugin surfaces).** `vi-reviewer.md`'s frontmatter `description` and body opening still said the reviewer is for VIs "authored by `/create-vi`" after an earlier fix corrected only the "Invoked from" line — both now also name `/update-vi`. `CLAUDE.md`'s canonical-terminal-order bullet had not received the earlier "emitter tail" clarification, so a reader could still mistake `/document`'s Phase 8.5 finish for a rule violation — it now states the emitter tail explicitly. `session-hygiene.md` rule 2 said a deliverable-side finish "may precede the tail," contradicting its own `/document` example (Phase 8.5 sits *between* feedback and follow-ups) — reworded to "may sit anywhere relative to the tail, including between its members." `risk-planner.md` still said "For upgrade/vuln work," though `/vuln` never dispatches this agent (confirmed via `grep -l 'risk-planner' commands/*.md` → `implement.md`, `upgrade.md` only) — narrowed to "For upgrade work." `diff-summarizer.md`'s GitHub-resolver step cited "the Refresh step's read-only detection above," but `## Refresh step` sits below that line — corrected to "item 2 below."
- **`read-only-repos.md`'s `## 6. Output contract` introduced its `prep:` fence with the wrong sentence.** The two-emitter sentence ("`code-scanner` and `diff-summarizer` report these four fields…") ended in a colon that should have led straight into the fence, but the `docs-grounder` aside was inserted between the sentence and the colon, so the fence read as describing `docs-grounder`'s shape rather than the two emitters' it actually documents. Reordered so the colon and the fence belong to the sentence that introduces it, with the `docs-grounder` aside now following as its own sentence after the fence. No behavior or contract change — readability only.

## [2.50.0] — 2026-08-12

### Added

- **`/implement` adopts `classification.md` §8.5 — the seeded narrow second scan round.** Phase 1.7's fan-out previously ran one broad `code-scanner` per repo and stopped. A theme its round 1 leaves **inconclusive** — `classification` `partial`/`absent`/`error`, or two or more scanners whose per-theme `capability_map[].gap_summary` texts point at each other's repo in a cycle, or at a component/subsystem no scanned repo covers — now gets one narrow round 2 on `detection_model`, with `capability_themes` holding a single question and `search_hints` seeded from round 1's verified `evidence[].path`/`.symbols` (and the `<path>:<line>` anchor named in the `context` prose where `lines` is present), when round 1 left at least one anchor to seed from. Cap 4 dispatches, one round only, no round 3. This matters more here than in `/idea`, §8.5's first consumer: `/idea`'s summary feeds a grill with a human in it, while this one feeds `risk-planner`, whose output becomes code.

### Fixed

- **Phase 1.7's synthesis flattened uncertainty into false confidence — including the anchorless case round 2 can never reach.** Step 4 said only to combine the scanner reports into "relevant files, existing capabilities, gaps" — so two scanners each concluding "it must be in the other repo" were folded in as two ordinary **gaps**, and the planner received a summary that looked settled. Because a theme with no round-1 evidence anchor never enters round 2, and §8.5's Bounds called any `absent` theme "resolved" regardless of a deferral outside the scanned set, that anchorless mutual-deferral case — the exact defect this release targets — still reached the planner unmarked. The summary's `## Unresolved` section now names **every** theme still inconclusive at the end of Phase 1.7, explicitly including one that never entered round 2 for lack of an anchor, and §8.5's Bounds now states the precedence: mutual deferral and `error` are unresolved regardless of whether an anchor existed, and a "confirmed absent" resolution requires no deferral to a repo or component outside the scanned set. A gap asserts the capability is absent with nowhere else it could be; an unresolved theme asserts only that the scan could not tell, and once flattened the two are indistinguishable downstream.
- **`risk-planner` was never told which findings were uncertain — the dispatch changed but the agent didn't.** Phase 2B's dispatch gained an `Unresolved scan themes:` field, but `agents/risk-planner.md`'s `## Inputs` was a closed enumeration with no bullet for it and its `### Risks considered during planning` template was a fixed seven-item list with nowhere for an unresolved theme to go. The agent now declares the field (optional; never a confirmed gap or a confirmed capability) and carries an eighth `Unresolved scan themes` bullet in the risks template, with an explicit "none" form so a brief without the field still satisfies the exact shape.
- **The read-only-mount escalation rule was scoped to round 2, which most runs never reach.** The `prep.read_only: true` sentence sat at the end of the Round 2 paragraph instead of the round-1 "wait for all scanners" paragraph, so a run with no inconclusive theme — the common case — carried no read-only escalation rule at all. Moved back to the round-1 paragraph.
- **`classification.md` §8.5's own consumer list was made false by the above.** Its Opt-in paragraph said `/idea` was "its first and only current consumer" and that `/implement` "runs §8.2 alone and is unaffected"; it now names both consumers, leaving `/epics`, `/create-ard`, `/specify`, and `/design` correctly listed as unaffected. §8.5 also gains a **"Round 2 resolves; it does not license a guess"** rule binding every adopter to name what stayed unresolved in whatever it passes downstream — `/idea` into `[NEEDS CLARIFICATION]`, `/implement` into the summary and the plan's risks.
- **The mutual-deferral trigger assumed exactly two scanners.** `commands/implement.md` and `classification.md` §8.5 both defined it as two scanners naming each other's repo, missing a three-or-more-repo deferral cycle and a one-way deferral to a repo outside the scanned set. Both now read "two or more … in a cycle, or at a repo/component no scanned repo covers," and name the per-theme `capability_map[].gap_summary` field explicitly (the schema also has an unrelated top-level `gap_summary`).
- **`/implement`'s own `## Invariants` list never got the rule it was built to enforce.** Added a `WHEN fan_out is true and a theme stays inconclusive:` line alongside the file's existing per-feature invariant bullets.
- **Repo-root `CLAUDE.md`, `README.md`, and `agents/code-scanner.md` carried the same stale claim** — the workflow map's `/implement` line, the §8 policy bullet (which read "§8.5's opt-in seeded second round (`/idea` only)"), the `/implement` invariants, the `code-scanner` README row, the Code-grounding heading, and `code-scanner.md`'s own consumer-credit line (which credited only `/idea` with "broad-then-narrow per §8.5") are all reconciled.

## [2.49.0] — 2026-08-12

### Added

- **`--ground-code [<repo>,…]` on `/idea`, and a new Phase 2.6 — Code grounding (optional).** Bare, the flag derives a repo set from the idea's themes and the directories under `${REPOS_PATH:-/workspace}` behind one confirm gate; given a value, it scans exactly those repos. Round 1 is the standard `code-scanner` fan-out (single response, cap 4); round 2 applies `references/model-routing/classification.md` §8.5 — a seeded narrow follow-up, capped at 4 dispatches, for each theme round 1 left inconclusive, with `search_hints` seeded from round 1's verified `evidence[].path` / `.symbols` (a `lines` anchor is named as `<path>:<line>` in the round-2 `context` prose, since `search_hints` has no line-number field). There is no round 3. Off by default and never auto-triggered: a run that names a mounted repo without the flag gets one inline suggestion line, never a prompt.
- **`references/model-routing/classification.md` §8.5 "Broad, then narrow (the seeded second round)"** — the shared, opt-in procedure behind the second round above. `/idea` (Phase 2.6) is its first and only current consumer; `/implement`, `/epics`, `/create-ard`, `/specify`, and `/design` still run §8.2 alone.
- **`## Feasibility grounding` — Section 7 of `references/idea-format.md`** (optional; renumbers the former Section 7 `Open questions & assumptions` to 8 and Section 8 `Candidate success signal` to 9). Written only when Phase 2.6 ran and returned at least one finding; opens with each grounded repo as `<repo>@<scanned_ref>`, then up to three optional slots (What exists / What's missing / Reframing), every bullet carrying a `<repo>/<path>:<line>` citation. Section 5 `Signals & evidence` gains a rule that code findings never go there — they belong in Section 7, since that section is demand evidence only.
- **`evidence[].lines`, an optional field on `code-scanner`'s handoff schema and agent instructions** (`references/handoff/code-scanner.md`, `agents/code-scanner.md`). Present with the 1-based line numbers when an evidence entry came from a grep hit; absent for a path glob or whole-file read; meaningful only together with `scanned_ref`, since a line number moves with the ref it was read at.
- **`## When a choice list fires` in `references/escalation-rules.md`** — a third plugin-wide rule: a choice list blocks whenever shown, a list is shown only when its firing condition holds, a list for a question whose answer is already determined is a defect, and the inline-confirmation form (one line, states the resolution, proceeds without waiting) is the correct shape for an unambiguous case.

### Changed

- **`/idea` Phase 1's single unconditional confirmation became two conditional choice lists plus an inline confirmation**, applying the new "When a choice list fires" rule. Case A fires only when a resolved key's `issue_type` is neither `ValueIncrement` nor `Product Need`. Case B fires only when the argument is path-like (contains `/`, ends in `.md`, or starts with `@`) but resolved to no existing file — fixing a real defect: without this gate the path string fell through to the `prompt` branch and was ingested as the idea's raw text, so a mistyped path became prose. Every other case — a resolving path/wikilink, a key typed `ValueIncrement`/`Product Need`, or plain prose — now gets a one-line inline confirmation instead of a list with one plausible answer.
- **`references/escalation-rules.md`'s `## Repo missing (after resolution)` list was replaced.** The old list (`"Stash changes and retry this repo"`, `"Skip this repo"`, `"Cancel"`) was byte-identical to the `/epics` variant of the `## Dirty working tree` list directly above it, and had no option for the case its own trigger names — a clone whose `origin` slug doesn't match `repo_url_slug`. The new list (`"Skip this repo"`, `"I'll clone it — wait"`, `"Specify a different absolute path for this repo"`, `"Cancel"`, `"Other… (describe)"`) adds that option and carries no `(Recommended)` marker, since which option is right depends entirely on why the repo is absent. Cited by seven callers: `/release-notes`, `/document`, `/create-ard`, `/specify`, `/epics` (pre-existing), and — newly — `/idea` (Phase 2.6, which has no earlier check) and `/implement` (Phase 1.7, which previously only promised to "surface" `DIRTY_TREE`/`REFRESH_BLOCKED` and never named `REPO_MISSING` at all).

## [2.48.0] — 2026-08-11

### Added

- **`vault-prior-art-finder` agent and `references/vault-prior-art.md`.** `/idea` and `/create-vi` now look for prior art on purpose instead of finding it by accident. The read-only agent searches `Projects/Products/**` and `Projects/ideas/**` for tracked initiatives that cover, precede, parallel, or are rewritten by the new work, and returns each match classified by relation, resolved to a Jira status, and summarised — plus reconciliation challenges and a write-path area proposal. There is no retrieval index and no consent gate: the corpus is a few hundred markdown files and retrieval is `Glob`/`Grep`. Advisory only, never a gate.
- **`resolve-export-for-key` entry point in `references/jira-input-resolution.md`.** Locates the export for one exact key at any depth, and takes the most recently modified copy when several exist — the same key legitimately appears under multiple parents (`jira-products/PRODUCT-14640/PRODUCT-14796/PRODUCT-14796.md` and `jira-products/PRODUCT-15448/PRODUCT-14796/…`), and those copies can disagree. Distinct from the existing VI-selector rule, which deliberately resolves a nested Epic *up to its parent*; this one never walks upward.
- **`## Prior art` section in `references/idea-format.md`.** The durable carrier for what the finder discovered — one bullet per initiative, carrying both a wikilink and a Jira key because a wikilink resolves by file name and dangles the moment a vault item is renamed. Every slot is transcribed from the digest rather than invented.
- **`--no-prior-art` off switch** on `/idea` and `/create-vi`, alongside the existing `--no-docs`.

### Changed

- **Both commands dispatch `docs-grounder` and `vault-prior-art-finder` in a single response at Phase 2.5**, so the two grounding reads run in parallel and neither being off suppresses the other. Phase 3 then ranks both challenge sets into its existing Impact × Uncertainty gap list, where they **compete** for the bounded question slots rather than adding any — `/idea`'s ≤5-question bound is unchanged.
- **`idea-reader` returns a `salient_summary` for every followed wikilink and source reference.** It already read those files; summarising what is in its context saves the orchestrator re-reading them, which is the most expensive place to put a read. A `vi` source additionally returns a `tracked` block carrying the item's `issue_type`, `status`, and `summary`.
- **`/idea`'s write path derives a container from the source's own location** instead of flattening every idea to `Projects/<Products|ideas>/<slug>/`. A source already sitting under a `Projects/Products/` grouper now lands beside its neighbours, matching the convention the vault already follows — with no prior-art match required. On top of that, one assembled gate offers a rewrite target and a high-confidence area proposal when either exists, and records the answer as `vi_disposition`.
- **`/create-vi`'s `Usage:` line names both grounding off switches**, and the README documents vault prior-art grounding in one section-level paragraph beside the `$DOCS_PATH` one rather than per command row.

### Fixed

- **`/idea` classified every Jira key as `rfe`, reading a Value Increment as a demand ticket.** Phase 1 now types the source from the export's `issue_type` frontmatter — `ValueIncrement` → `vi`, `Product Need` → `rfe`, anything else surfaces the actual type and asks — never from the project prefix, which is a coincidence of Jira configuration. A `vi` source is prior art: `idea-reader` distills its problem, goal, and scope instead of mining it for requesters and upvotes that a Value Increment does not have.
- **Key lookup assumed a top-level `jira-products/<KEY>/` directory.** 431 keys in a real export exist only nested, including the Value Increments `PRODUCT-14796` and `PRODUCT-14592`, so `/idea PRODUCT-14796` returned `NOT_FOUND`.
- **The next-phase offer always said "first create an empty Jira workitem".** When the idea rewrites the Value Increment it came from — same goal, different approach, same key — that instructed the user to mint a key they must not mint. The offer is now driven by `vi_disposition`.
- **Classification stripped only `--deep`** while the command honours four flags, so `--no-prior-art` and the rest landed inside the classified idea text and reached `idea-reader` as though the user had typed them.
- **The `--as` future-work note advertised a `file` source type that never existed** and omitted the new `vi`.
- **The Phase 4 gate's `(Recommended)` marker could name a row absent from the array.** The marker is derived from the top prior-art match's relation, but the rows it can name are conditional — and the gate can fire with no match at all, since a `vi` source alone opens it. Every derivation branch now falls back to row 3, the only always-present destination, so the gate can never render with nothing marked.
- **Several user-facing descriptions still advertised "an exported RFE Jira ticket" as the only Jira source** — the `idea-reader` agent description, the `/idea` command description and flag line, and three README rows — after the widening above made that false.
- **`references/workflow-states.md` spelled a status `Use cases defined` where Jira and every export emit `Usecases defined`.** `readiness-reviewer` string-matches against that table, so the rung never matched.

## [2.47.1] — 2026-08-11

### Fixed

- **`/epics` discarded its documentation grounding whenever code scan was off — after asking the user to pay for it.** Phase 4 and Phase 5 both say "If code scan is OFF, skip to Phase 6", and `dispatch-docs-grounder` sat inside Phase 5, so the digest was never produced on those runs even though its own text claimed it "runs even when code scan is OFF". 2.47.0 sharpened the consequence rather than causing it: moving `resolve-docs-grounding` to Phase 2 meant the run could prompt for a one-time index build and then skip the dispatch that would have used it. The dispatch is now its own **Phase 3.6**, before both conditional phases — it only ever needed Phase 3's VI goal and `jira-reader` themes, never the code scan.

## [2.47.0] — 2026-08-11

### Fixed

- `docs-grounder` no longer builds the qmd index. It probes (`qmd status`, `qmd collection list`) and selects a retrieval rung: `qmd-vector` (`qmd search` + `qmd vsearch`, when the collection has embeddings), `qmd-lexical` (`qmd search` alone), or `fallback`. `qmd query` is never invoked — it is the only entry point needing the reranking and query-expansion models, which no cheap probe can prove are cached. Previously the agent was instructed to "self-heal" with `qmd collection add` + `qmd embed`, which on a fresh container means a ~1.3 GB model download and embedding every page in `$DOCS_PATH` on the user's critical path.
- The keyword fallback is bounded — 3–8 keywords, generic keywords dropped above 200 matching files, shortlist capped at 40 — so the qmd fix does not relocate the cost into an unbounded scan.
- `code-scanner` and `diff-summarizer` no longer fail on read-only mounts, where `git switch` and `git fetch` cannot write. They read at `origin/<default>` via `git ls-tree` / `git grep <ref>` / `git show <ref>:<path>` instead of returning `REFRESH_BLOCKED`, and skip the dirty-tree gate, since the working tree is never mutated. Writable mounts are unchanged. Both agents report `prep.read_only`, `prep.scanned_ref`, `prep.ref_committed_at`, and `prep.head_divergence`. Two of the twelve repository clones in the AI container are read-only mounts today.
- `/create-ard` and `/release-notes` gain their first handling for `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED`; `/epics` gains the `docs grounding:` line it never printed.

### Added

- New `references/read-only-repos.md`, the single source of truth for read-only mounts: the detection probe, what read-only mode skips, write-free ref resolution and reading, the escalation trigger, and the `prep` output contract. Consumed by `code-scanner`, `diff-summarizer` and `docs-grounder`, and cited by the seven commands that dispatch them.
- New `Read-only mount — ref stale or diverged` escalation, fired only when the ref is more than 14 days old or the working tree is ahead of it, offering a host-side `git fetch` or a read-write re-mount.

### Changed

- Index building and refreshing move into `resolve-docs-grounding` step 3.5, where the user can consent: an existing collection gets a bounded incremental `qmd update`, a missing one gets a one-time build prompt. An agent cannot ask the user; the orchestrator can.
- The `docs grounding:` line now reports the retrieval rung, a stale docs checkout, a capped index refresh, and a project-local `.qmd` index shadowing the user-scope one.

## [2.46.1] — 2026-08-11

### Fixed

- **The workflow diagram named commands two different ways without saying why.** One node read `/dev-workflows:statusline` while `/release-notes` and `/upgrade` — which collide with a Claude Code built-in exactly as `/statusline` does — sat bare beside it. A reader could see the inconsistency but not infer the rule behind it. The three colliding names are now qualified throughout the diagram, everything else keeps its short form, and a line beneath the diagram says which names need the prefix and why (`references/next-phase-offer.md` rule 6).

## [2.46.0] — 2026-08-11

### Fixed

- **Printed next-step suggestions named commands that resolve to something else.** A bare `/release-notes` typed at the prompt reaches Claude Code's built-in release-notes view, not this plugin — and the same is true of `/upgrade` and `/statusline`. The plugin already knew this for exactly one command: `statusline.md` has always told users to type the fully-qualified `/dev-workflows:statusline`. That reasoning is now the general rule (`references/next-phase-offer.md` rule 6), and every command name the plugin prints for the user to invoke carries the `/dev-workflows:` prefix. Finding them all took seven distinct detectors: `### Next step` sections and `choices:` arrays are structurally delimited, but the rest are not — quoted handoffs, inline "surface a recommendation to run X" instructions, the role-handoff line that names your next command beside `/compact`, annotated bullets expanding an offer, multi-line printed literals whose trigger phrase and command sit on different lines, and STOP messages carrying a `re-run this` instruction. Names that are printed but are not invocation targets stay bare: `command: /implement` handed to `emit-cost` is a data field, "Phase 5 of the inherited `/implement` workflow" names the workflow the run is inside, and `CREATE_VI_NEEDS_KEY: /create-vi needs a Jira key` names which command is complaining.
- **`/update-vi` cited a routing graph it did not appear in.** `update-vi.md` names `references/next-phase-offer.md` as the authority for its Phase 6 offer, and that file had never mentioned `/update-vi` — in any edition. It now appears as a PM re-entry node, reached when `/create-vi` redirects an existing-VI call or when a later phase forces a refresh. The README's workflow diagram gained the node its own role table has always listed.

## [2.45.0] — 2026-08-10

### Fixed

- **`$SPECS_PATH` is a git repository that no command ever committed.** Seventeen of the twenty-one commands write bookkeeping artifacts into it — feedback, cost entries, follow-ups, resume pointers — and none of them committed those artifacts. The five commands that do run git against the specs repo commit only their deliverable, in a handoff phase that fires *before* the artifacts are written, so the artifacts were untracked by construction. `references/feedback-emission.md` states the purpose outright — feedback reaches the maintainer only if it lands in the committed, pushed specs repo — and nothing in the plugin made that landing happen; twenty-eight tracked artifact files across nine VI directories all arrived by hand-written housekeeping commits, one of which had to commit the feedback entry recording this very defect. New `references/specs-repo-git.md` owns two entry points: `specs-preflight` at Phase 0 (flush leftovers onto the current branch, retry an artifact commit whose push failed, settle the branch) and `commit-artifacts` as the run's last action (stage the bounded artifact paths, commit `<KEY|NOISSUE> Add dev-workflows session artifacts (<command>)`, push). Every git call is `git -C "$SPECS_PATH"` and never a `cd` — nine of the seventeen commands are standing in a *different* repository when these run. Staging is by enumeration, never by glob, and never `git add -A` at repository scope. The plugin manages only branches it created (`vi|ard|spec|design/*`); a detached HEAD is the one blocking state, because a commit made there is reachable from no ref and garbage-collectable, and a run that reported a SHA over it would be a failure that looked like success.
- **Eight of the ten commands that write `resume.md` violated the ordering `references/session-hygiene.md` §1 already required.** It states the pointer is written after `emit-cost` / feedback / follow-up; only `/design` and `/specify` complied, and those two wrote it inside their Final report — after the point where `commit-artifacts` now runs, which would have left it uncommitted. All ten now write the pointer as the last step of their cost phase, immediately before the commit that captures it. The printed `### Context hygiene` block keeps its `/compact` | `/clear` | `/rename` guidance and no longer carries the write instruction, because six commands compose that report *before* their cost phase runs.
- **Sixty-seven `NEVER commits` assertions had to be re-checked against the terminal step; twenty of them became false.** They were swept across nine phrasing variants — including `never branches`, `NEVER auto-commit`, `no branch, no commit`, `git is the user's responsibility`, and two that wrap across a line break and defeat any line-level grep — and reconciled rather than deleted: the protective intent is real, only the scope changed. Assertions that stayed true (the vault, `jira-products/`, a code or docs repo) are annotated with the reason they stayed true. `/statusline` keeps its unscoped assertion — it writes only under `~/.claude/` and is out of scope.
- **The preflight did not run on every path, so the detached-HEAD guard was silently absent on some.** `commit-artifacts` refuses to commit when `specs_git: blocked` is set, and `specs-preflight` is the only thing that sets it — a commit on a detached HEAD is reachable from no ref and garbage-collectable, so a run that made one would print a SHA and a success line over data already on its way to being unrecoverable. In `document.md` the executable preflight sat inside Mode A's Phase 0, but the shared `## Mode detection` section dispatches to a mode *before* Mode A is entered, so a Mode B (`@file` / free-text) run never reached it and still ran the terminal commit. Mode B's own note already asserted the preflight had run "before mode detection" — the contract was right and only the placement contradicted it. The executable block now sits in the shared section ahead of the dispatch sentence, and both modes' notes plus the two `## Invariants` bullets that still said "at Phase 0" were corrected. Found by the Copilot port, which hit the same shape and declined to propagate it. Note that no count would have caught this: the citation was present in every file throughout.
- **Two routing rules were wrong in ways only a second read found.** `specs-preflight`'s branch matching compared the branch key against a *single* run key, but an Epic-scoped run carries two: `/specify <VI> <Epic>` authors its spec on `spec/<EPIC>-…`, so a following `/design <VI> <Epic>` — whose run key resolves to the VI — matched nothing, took B4, switched to the default branch, and removed the `specification.md` its own Phase 0 gate had just verified. That is the identical failure §3.6 documents for `/create-ard` and warns must never be "simplified away"; it simply was not covered for the commands that take an Epic. The run key is now a **set** (the VI, plus the Epic where the command takes one), B3 matches any member, and B4 applies only when none do — a different VI's branch, a different Epic's branch, and a keyless run all still route to B4. Separately, eight commands per edition stated that the terminal step "pushes to the specs repo's default branch"; it pushes to the current branch's upstream, and both G2 and B3 deliberately leave runs elsewhere, so the run could print a branch its own text had just denied. Those now cite §4 step 5 rather than restating it — which is what §7 rule 4 asks for.
- **The terminal step is not always literally last, and the reference now says so.** `/prompt-brainstorm` hands the session to `superpowers:brainstorming` and `/prompt-grill-me` enters an open-ended grill; both commit immediately *before* that hand-off, because a commit after it would never run. §4 and §7 previously admitted no exception, so a future cleanup could have "corrected" the ordering and stranded the artifacts. The carve-out is narrow: it applies only where control genuinely leaves the command, never as a convenience to commit early.

### Added

- **`references/specs-repo-git.md`** — the bounded write authority (three path shapes, `^(vi|ard|spec|design)/` branches), the three preflight guards and their four-part notice contract, the three-stage resolution, the seven-step commit, and the `Specs repo:` outcome line. Never force-pushes, never `branch -D`, never merges/rebases/resets, never deletes an `index.lock`, and never fails the run.
- **A `Specs repo:` outcome line at the end of every in-scope run** — eighteen sites, one per command plus one per `/document` mode. Where the Final Report is the run's last output the line lives in the report template; where the report is composed before the terminal phases, `commit-artifacts` prints its own block, as the follow-up and cost phases already do.

## [2.44.1] — 2026-08-10

### Fixed

- **The model-routing references had gone stale.** `references/model-routing/classification.md` §2 topped the strong chain at `claude-opus-4-8`; it now tops at `claude-opus-5`, with 4.8/4.7/4.6 shifted down one and the Sonnet 5/4.6/4.5 tail and Sonnet 4.5 floor unchanged. The mid-tier chain (§2.1) already read Sonnet 5 → 4.6 → 4.5 and is untouched. Five commands (`create-vi`, `create-ard`, `update-vi`, `design`, `specify`) hardcoded `Co-Authored-By: Claude Opus 4.8 (1M context)` in their handoff commit trailers — now `Claude Opus 5`, with the `(1M context)` qualifier dropped because the 1M window is standard on 4.6 and later. Chain examples in `docs-profile.md`, `document.md`, and `classification.md`'s own `model_routing` block follow.
- **`CLAUDE.md`'s chain description disagreed with the reference it summarises.** It listed Opus 4.8 → 4.7 → 4.6 → Sonnet 4.6 → Sonnet 4.5, omitting `claude-sonnet-5` which `classification.md` has carried at position 4. Both now read Opus 5 → 4.8 → 4.7 → 4.6 → Sonnet 5 → 4.6 → 4.5.

### Added

- **`claude-opus-5` in `references/cost-prices.yaml`.** Not cosmetic: the price engine exact-matches a model id and then falls back to the longest table key that is a *prefix* of it, and no existing key is a prefix of `claude-opus-5`. Routing to Opus 5 without this entry would have priced every SIGNIFICANT and HIGH-RISK run as `unpriced-model` with `cost_usd: null`. Opus 5 bills identically to the whole Opus 4.5–4.8 block ($5 / $25; cache read $0.50, 5m write $6.25, 1h write $10), verified 2026-08-10 against the pricing source the file already cites, so the entry is a copy of its neighbours. Sonnet 5 deliberately stays at its standard $3 / $15 — its $2 / $10 runs through 2026-08-31 only, and the file's rule against promotional rates (they make identical work look cheaper now and dearer later, distorting cross-VI comparison) is unchanged.

## [2.44.0] — 2026-08-10

### Fixed

- **The deprecation note was not missed. It was forbidden.** `agents/doc-location-finder.md`'s exclusion rule banned every path under `_content/whats-new/...` as a `/release-notes`-only destination — correct for the 182 automation-generated pages at that prefix, wrong for the 10 hand-authored announcement pages (`end-of-life-announcements.md`, `end-of-support-news.md`, `technology/index.md`) that live under the same prefix and have no automation touching them at all; their git history is human PRs. The rule's exclusion set is now keyed on what's genuinely automation-owned — `meta.content-type: release-notes` frontmatter, `_data/release-notes/**`, `_snippets/release-notes/**` — and gains one named exemption: a page declared in the profile's new `announcement_pages` block (`{postid, path, kinds}`, in `references/dynatrace-docs/docs-profile-schema.md` + `.default.yml`) is a valid target, proposed **alongside** the feature-subtree target rather than in place of it. `doc-location-finder`'s two mirrors in `doc-planner.md` change in lock-step — removing one and leaving the others is a failure mode this repo has hit before. A repo with no `announcement_pages` block falls back on the same content-type-keyed heuristic, which is necessary rather than decorative (`end-of-support-news.md` carries no `content-type` at all). `commands/docs-profile.md` learns to discover the block.
- **The provenance comments were not improvised. They were mandated.** `agents/doc-writer.md` and `doc-reviewer.md` dimension 12 ("Source traceability") required every claim to cite its Jira key and/or PR URL inline — while three other places in the same plugin (`doc-writer.md`, `doc-planner.md` ×2, `commands/document.md`) already stated the opposite: traceability lives in the commit message, not the reader-visible page. The writer emitted provenance and the reviewer endorsed it, both correctly following instructions the plugin itself contradicted. New `references/doc-structure-conventions.md` §1 states the boundary once — rendered page carries the customer-facing claim only, the commit message carries the Jira key, the run handoff carries per-claim attribution — and `doc-writer` + `doc-reviewer` now cite it instead of restating it. Dimension 12 **inverts**: a Jira key (bare or as a `[[wikilink]]`), a PR URL, or a `<!-- KEY: … -->` comment appearing anywhere in a written file is now **MAJOR**. The `source-truth.md` §7.6 `<!-- intentional-discrepancy: … -->` marker is unaffected — it's a deliberate, user-decided gap flag, not provenance.
- **`doc-location-finder`'s input contract had a scope gap.** It defined its entire input as `repo_root`, `feature_summary`, `diff_highlights` — no `target_spaces`, no `profile` — so nothing stopped it proposing a SaaS-only path on a Managed-only run. Both are now part of the contract, and `commands/document.md` passes them.

### Added

- **Callout scope and adjacency — new `references/doc-structure-conventions.md` §2.** A callout that qualifies one option in a mutually exclusive set is placed with that option, immediately beneath it, never as an *unqualified* trailing block after the whole set — a trailing callout that names its own scope in its first clause ("This applies only to the built-in cluster registry.") is §2 rule 3's permitted alternative, and the enforcers carry that carve-out so a page following it is not flagged; a callout that applies to the whole set goes in the lead-in, before the options. `doc-planner` plans placement per option, `doc-writer` writes it, and `doc-reviewer` flags a scope violation at **MAJOR** — a misread scope changes what the customer believes is required or prohibited. The motivating case: an ARM limitation specific to the built-in cluster container registry read as applying to all four registry options on the shipped page, including a customer-owned private registry where it's simply false.
- **Component-pattern fidelity — `doc-structure-conventions.md` §3.** `doc-planner`'s existing 5–10-page sibling sample (already used to classify image policy) gains a second job: recording which content component the area already uses for a recurring content shape, as a `component_patterns` block (`shape`, `component`, `evidence`, `count`). `doc-writer` reuses the dominant component for a matching shape instead of inventing a structure; `doc-reviewer` flags a divergence at **MINOR** (an ad-hoc structure still renders). No component list is vendored — the rule is repo-agnostic and the evidence always comes from whatever repo is in front of it. On the shipped page, 4 of 5 sibling pages used `{{#tabgroup}}` for the same mutually-exclusive-options shape the writer built ad hoc.
- **Images: one phase, two lists.** Phase 5.6 is now the single image step and **always runs**, sourcing a to-add list (unchanged) and a possibly-stale list — every image already present on an `extend-existing` target, listed **per occurrence** (not per URL) with its section and space-gating (`{{#if project='…'}}` or none). Answering "No screenshots needed" no longer skips the phase outright, which is exactly how three stale images — one of them SaaS-gated in a space where the feature doesn't exist — survived a run where the user was asked about screenshots and answered. Stale replacements reuse the existing Phase 6.1 CDN-URL-collection flow, and the writer swaps the existing reference rather than inserting a new one. CDN immutability — every new or replacing screenshot is a new URL; an image is never refreshed in place — is now stated in `docs-profile.default.yml`'s `images.policy`, `docs-profile-schema.md`, and the `doc-writer` image step. `doc-reviewer` dimension 9 extends to swap completeness: every accepted replacement URL must land at every occurrence the review listed, or the stale image stays live and invisible in the diff.
- **New ledger gate `image_review` — `references/gate-ledger.md` §4.** Phase 5.6, preconditioned on ≥1 candidate image (to add or possibly-stale). It's an input-side gate rather than an output-verification gate like the other six, but the accountability need is identical. The §4 direct-mode carve-out paragraph is updated in the same edit — direct mode has no Phase 5.6, so the "three registered, N never-appearing" gate count becomes four never-appearing.
- **Anchor conventions — new `references/dynatrace-docs/anchor-conventions.md`.** One `{:#id}` per heading — multi-anchor `{:#a #b}` is unsupported (0 occurrences across 1,580 files under `dynatrace/_content` + `managed/_content`); the four verified link forms (`[text](postid)`, `[text](postid#anchor)` — 19,560 occurrences, `[text](#anchor)` — 4,006, `{{#tabgroup anchor='id'}}` — 698); the `pnpm docstack validate-anchors` contract (an anchor link must target a hardcoded id, not a generated one); and the reconciliation rule that a product `dt-url` deep link's anchor wins — a mismatch is recorded as a Phase 5.8 discrepancy, never deferred on an in-session judgment that the syntax "appears unsupported." Consumed by `doc-writer` (authoring), `doc-reviewer` (dimension 5), and `doc-planner` (planning cross-link anchors).
- **Lifecycle dates — a twelfth `source-truth.md` §2 claim class.** End-of-life, end-of-support, shutdown, sunset, and availability dates are now a verified claim type, checked against UI notice strings and banner constants, announcement/config expiry values, feature-flag sunset metadata, and sibling announcement pages that already carry the date. A load-bearing milestone-equivalence rule ships with it: compare the milestone a date denotes, not its surface form — "EOY 2027," "end of 2027," "December 31, 2027," and "stops working on January 1, 2028" all denote one boundary and are not a discrepancy; a discrepancy exists only when the milestones genuinely differ. Without this rule the class would be a false-positive generator. §7.5's `<KEY>-implementation-gaps.md` bug-report trigger widens to `document-as-code`, conditionally: emit a gap only when the Jira phrasing asserts a specific value that **contradicts** the source; skip when it's merely vague or non-committal. The judgment resolves toward over-inclusion — a spurious entry costs a paragraph the user reviews; a miss leaves a wrong customer-facing claim in the ticket indefinitely.
- **`doc-reviewer` grows from 16 to 17 dimensions.** New: **Page structure conventions** (callout scope + component-pattern fidelity, above). Extended: **Structural integrity** (anchor form and the `validate-anchors` contract), **Screenshots** (swap completeness), **Source traceability** (inverted, above). The dimension table and the output-slot headings stay in lock-step, seventeen of each, per the existing "never invent a dimension beyond the ones listed" rule.
- **Phase 8 maintenance agents split into propose and apply.** Agents 2 (knowledge base) and 3 (instructions, incl. `CLAUDE.md`) stop writing into the target docs repo directly — each now returns a precise proposed edit (file, anchor, replacement text, reason) instead of applying it; Agent 1 (documentation) and Agent 4 (`impl-maintenance`, already suggest-only) are unaffected. A new apply phase — Jira mode Phase 8.6, running after Phase 8.5 has sealed the docs commit; direct mode Phase 4.5, between maintenance and the final report — presents the proposals (`choices: ["Skip — report only (Recommended)", "Apply all", "Choose per proposal", "Cancel"]`) and, on acceptance, re-dispatches the same agent in apply mode. Applied edits are left **uncommitted** by design: because the phase runs after the squash, an accepted `CLAUDE.md` edit can never ride the docs commit or the docs PR — a governance change needs its own PR on the user's own timing. The Phase 9 / Phase 5 final report gains **one** new section, `### Maintenance applied (uncommitted)`. No separate "proposed" section is added: the reports' existing Agent 2 (knowledge base) and Agent 3 (instructions) sections already list every proposal and now carry its disposition, so a second listing would duplicate them. `commands/document.md` and `references/finish-and-handoff.md` drop the "Agent 3 (`CLAUDE.md`) may have edited without committing" clause — nothing uncommitted originates there anymore.

## [2.43.0] — 2026-08-08

### Added

- **`/document` Phase 0 toolchain preflight — new `references/toolchain-preflight.md`.** Before anything is written, the run derives the tools its gates will invoke — from the resolved profile (`commands.*`, `commands.per_space.*`, `dev_servers[].command`, `prerequisites`), the repo's config signals (`.vale.ini`, `pnpm-lock.yaml`/`package-lock.json`/`yarn.lock`, `node_modules/`, `.markdownlint.json(c)`, `.remarkrc*`), and the repo's own documented `Prerequisites` section — checks each with `command -v` / `test -d`, and maps every tool to the gates it powers. On a healthy container it contributes one Readiness row and never prompts. When something is missing it states the run's outcome in advance ("with `vale` and `pnpm` missing, `style_check` would be DEGRADED, `build_check` and `render_smoke_check` UNAVAILABLE") and offers Cancel as the recommended option, so a run started in the wrong container stops before writing rather than shipping quieter, worse documentation behind a green CI. Direct mode gets the same check scoped to the style gate, deriving its required set without a profile.
- **Gate ledger — new `references/gate-ledger.md`.** Six outcomes — `RAN`, `DEGRADED`, `FAILED`, `UNAVAILABLE`, `SKIPPED_BY_USER`, `NOT_APPLICABLE` — and **none of them is an orchestrator-assignable "skipped"**. Every non-run path terminates in a named missing precondition, a named missing tool, or the user's decision quoted verbatim; `UNAVAILABLE` is explicitly not a resting state and is converted by asking. Each gate appends its row **when it completes**, never reconstructed at report time. `doc-reviewer` gains a **Verification-gate integrity** dimension that BLOCKs on a missing row, an unconverted `UNAVAILABLE`, an unattributed skip, or an underpopulated `DEGRADED`, and Phase 9 prints a `### Verification gates` table naming what CI will check that the run did not.
- **"Choice lists are presented verbatim" in `references/escalation-rules.md`** — a phase's options, their order, their wording, and the `(Recommended)` marker are not the orchestrator's to change; an orchestrator that disagrees says so in prose beside the list. Binds every command. This is the rule a `/document` run broke when it moved `(Recommended)` onto Phase 6.5's Skip option and never exercised the render gate.
- **`commands.per_space` in the docs profile.** `dynatrace-docs` defines `dynatrace:lint`, `managed:lint`, `dynatrace:build`, and `managed:build`; the built-in profile knew only `pnpm dynatrace:lint` and no build command at all. Per-space `lint`/`build`/`format` are now declared, documented in `docs-profile-schema.md`, and detected by `/docs-profile`.
- **Commands and code blocks are a verified claim class.** `references/source-truth.md` §2 gains a row for helm/kubectl/pnpm invocations, flags, image references, chart names, registry paths, and YAML keys in fenced blocks, plus a §3.7 technique that checks them against `Chart.yaml`/`values.yaml`/`templates/**`, the release workflow, sibling docs pages, and `--help` output. `doc-reviewer` checks them in **every** run at MAJOR — readers run a documented command verbatim, so an unverified one is a defect even when the rest of the page verified cleanly.
- **`repo_verification_gates` from `doc-planner`.** The repo's own pre-PR checklist — for `dynatrace-docs`, `CONTRIBUTING.md` `## PR checklist` — is now extracted and checked, instead of being discarded by the planner's "ignore operational content" rule. `doc-reviewer` holds the written files against each gate and cites the repo's own section in the finding.

### Fixed

- **`docs-style-checker` climbs the ladder instead of jumping off it.** A failure at any primary rung now continues to the next rung; previously every step-1/2/3 failure jumped straight to `dt-style-checker`, so a repo with a `.vale.ini` but no `vale` binary silently abandoned `pnpm dynatrace:lint` — the linter CI actually runs. Step 2 also becomes space-aware through a new optional `spaces` input, so a Managed-only file set is linted by `managed:lint` rather than the SaaS linter, and a new `primary_attempts` output records every rung tried, which is what fills the ledger's `not_run` and `ci_still_checks`.
- **`references/dynatrace-docs/render-verification.md` no longer claims dynatrace-docs has no build command.** That false statement disabled Phase 6.5's gating Step 1 outright; `dynatrace:build` and `managed:build` both exist and now run per space.
- **The render smoke-check boots the protected space, not only the target.** The cross-space invariant has two halves — the delta marker PRESENT in the target render and ABSENT in the protected one — and iterating `target_spaces` alone could never check the second, which is the half the 3a protection depends on. Static conditional analysis is declared necessary but never sufficient: it corroborates the gate and can never satisfy it.
- **`changelog-guidelines.md` has consumers in the write path.** It was cited only by a skill that no agent invokes and `doc-writer` cannot invoke (its tool list has no Skill), so `doc-planner`, `doc-writer`, and `doc-reviewer` each worked from two inlined rules. All three now read the reference itself; a non-conforming entry — meta phrasing, a run of "Added", internal jargon such as "Managed-only", a broken period rule — is a MAJOR reviewer finding. No rule text is duplicated.
- **Phase 5.8 tries once more before escalating.** An `AMBIGUOUS`/`NOT_FOUND` verification warning whose repo is resolved in `code_repos` now gets one supplementary direct grep against the local path — **including when `diff-summarizer` returned `REFRESH_BLOCKED`**, since a read-only mount that cannot `git fetch` can still be grepped. Resolving a claim this way records the gate as `DEGRADED`, never a clean `RAN`.
- **`status: NOT_CONFIGURED` stops being a silent proceed, in both modes.** It now maps to an `UNAVAILABLE` ledger row that must be converted by asking the user, rather than a no-op on the way to the reviewer. Jira mode converts it before `doc-reviewer`; direct mode, which has no reviewer gate, converts it before Phase 4.

## [2.42.0] — 2026-08-07

### Changed

- **Release-notes field hygiene — `/create-vi` and `/release-notes` stop asking for Jira dropdowns.** `release_versions`, `change_type`, and `release_notes_category` were filed as PM-authorable VI frontmatter; they are Jira dropdowns the PM sets on the ticket and the importer returns on the round-trip, so they move to the Jira-mirror class in `references/vi-format.md`. `/create-vi` no longer asks for any of them and `vi-reviewer` no longer requires or validates them. A dropdown question earns its place only when the answer changes what the plugin generates — deciding it in a chat window costs exactly what deciding it in Jira costs.
- **`references/release-note-types.md` rewritten as a destination + shape authority.** Evidence from the shipped `dynatrace-docs` corpus: across 852 `{{#context}}` lines in generated release-note snippets, none carries a change type — the Change Type instead routes the note to `breaking-changes.md`, `feature-updates.md`, or `fixes.md`. And `fixes.md` publishes one bare sentence (1 `{{#context}}` line across 57 files) rather than label + title + prose, so classifying a VI as `Bug fix` used to emit an unpublishable shape. The reference now maps Change Type → destination → draft shape, and adopts the docs team's own per-destination prose rules (breaking: present tense + remediation link; feature update: benefit-led + a docs/blog link; fixes: one past-tense sentence).
- **A deprecation is never classified `Bug fix`.** `fixes.md`'s one-bare-sentence shape has no `{{#context}}` line, no title, and no room for a trailing `> Note:` line — so a deprecation routed there would have nowhere to carry its required end-of-life date. §2's tie-breakers now exclude `Bug fix` outright for a deprecating change: it resolves to `Breaking change` when the customer must act now, else `New technology support` when a new capability supersedes the old one, so the note always lands in a titled destination with room for the §5 deprecation note.
- **The feature-update documentation link is now phase-gated.** `/release-notes` runs twice in a VI's life — once from the PM at VI creation, once from the dev after implementation — and only the second run has a page to link to. The writer resolves `run_phase` from the same `specification.md` / `design.md` presence signal `references/cost-emission.md` §7 already infers `phase`/`role` from: neither file present → `pm`, and the link is omitted entirely (never asked for — the feature isn't built and the docs don't exist yet); either present → `dev`, and the author may supply a redirect short link. No URL is ever invented at either phase.
- **The `{{#context}}` label is now sourced, not guessed.** It is exactly the Dynatrace Solution taxonomy the VI already carries as `release_notes_category` — yet `release-notes-writer` was explicitly forbidden from using it, so it guessed and then asked. The prohibition is gone: the label is the imported `release_notes_category` used verbatim, and the line is omitted when the import carries none.
- **Exactly one Summary per run.** `release_versions` used to emit one Summary block per declared version, but the prose may never name a version — so the blocks were identical. The `(unspecified)` fallback and the `release_version` gap are gone.
- **`/release-notes` is gated on `relevant_for_release_notes`.** An explicit `false` in the *imported* frontmatter stops the run with `RELEASE_NOTES_NOT_RELEVANT` (overridable); an absent value proceeds silently, since the field defaults to true. Previously the check ANDed the flag with `release_versions`, so a VI correctly flagged not-relevant still proceeded whenever a version happened to be set.
- **One question survives, reframed.** A low-confidence *destination* inference is still confirmed — but only when the Jira dropdown is unset, and the options now name each choice's shape and destination file instead of the four opaque enum values.

## [2.41.0] — 2026-08-04

### Changed

- **Branch naming is now repo-rule-first.** 2.40.0 introduced the `$GIT_USER_INITIALS` ladder but made it the *primary* mechanism, and only `/document` and `/docs-profile` ever read the target repo's own branch-naming convention — so `references/branch-naming.md`'s claim that a documented pattern "outranks this ladder" was unenforceable in `/implement`, `/upgrade`, and `/vuln`, which never looked. The priority is inverted and the gap closed. All five branch-creating commands now read the repo's `CONTRIBUTING.md` / `CONTRIBUTION.md` / `README.md` / `DOCUMENTATION-GUIDELINES.md` / `CLAUDE.md` **first** (§1.1), classify the documented pattern's segments (§1.2), and fill each from its proper source: an **identity** placeholder (`<your-name-or-initials>`, `<user>`, `<initials>`, …) from the `$GIT_USER_INITIALS` → `git config user.initials` → existing-branch-inference → prompt ladder, now §2; an **issue-key** segment from the run's already-resolved Jira key (or the pattern's documented no-issue literal); the **description** segment from each command's own slug rule (§3). Against `dynatrace-docs`' documented `<your-name-or-initials>/<JIRA-ISSUE-KEY>-<short-branch-name>`, `GIT_USER_INITIALS=iv-gu` now yields `iv-gu/PRODUCT-17753-add-oauth`. The ladder supplies the *whole* prefix only when a repo documents no convention at all (§1.4, per-command fallback `feat/` / `docs/` / `fix/` / `chore/`).
- **A pattern with no identity segment no longer gets one.** Injecting initials into a repo whose documented convention is a plain `feat/<slug>` would violate that convention; §1.2 and §5 now forbid it explicitly. Identity inference also ignores the generic prefixes (`feat/`, `docs/`, `fix/`, `chore/`, …) — they are not identities — and the §2.5 escalation drops its "use the generic fallback" choice when it is an identity being filled, since a documented convention requires a real one.
- **`/implement` composes a compliant name in issue-key repos.** When a documented pattern has no separate issue-key segment but the run resolved a Jira key, the key is prefixed to the slug (`<KEY>-<slug>`), matching the Jira-driven commands' pre-existing behaviour.
- Assembling a name from a documented convention still ends in the user confirmation (§1.3) — identity strings and slugs are subjective.

## [2.40.0] — 2026-08-04

### Added

- **`$GIT_USER_INITIALS` branch prefixes — new `references/branch-naming.md`.** Every branch-creating command now resolves its prefix through one shared ladder: `$GIT_USER_INITIALS` → `git config user.initials` → inference from existing branch names → a per-command fallback (`feat/` for `/implement`, `docs/` for `/document` + `/docs-profile`, `fix/` for `/vuln`, `chore/` for `/upgrade`). Set `GIT_USER_INITIALS=iv-gu` once and `/implement` produces `iv-gu/PRODUCT-17753-add-oauth` instead of `feat/add-oauth`. Reaching the fallback is no longer silent — it triggers a mandatory prompt (registered in `escalation-rules.md` as "Branch prefix undetected") offering the fallback or your initials, and suggests persisting them via the env var or git config without ever writing them itself. Wired into `/implement` (Phase 3 step 2), `/document` (Phase 6.2 steps 3–4, both modes), `/docs-profile` (Phase 6 step 1), `/upgrade` (Phase 2 prep), and `/vuln`'s "Git Workflow" spec that `vuln-fixer` follows. Inference accepts hyphenated initials (`iv-gu/`, `a-hue/`) as well as unhyphenated ones. A branch pattern documented in the repo's own `CONTRIBUTING.md` / `README.md` still outranks the ladder for the name's overall *shape*; the ladder supplies its `<user>` / `<prefix>` placeholder. Replaces `/docs-profile`'s ad-hoc `git config user.name`-derived initials prompt and `/implement`'s prefix-only `git branch -a` sniff.

### Fixed

- **Two dead `LS` tool names survived the 2.39.4 sweep.** That release removed `LS` from all 50 frontmatter `allowed-tools` / `tools` lists but missed the two *inline* Agent-dispatch specs that name their tool restriction in prose — `/document` Phase 10's structure-scout and `/implement` Phase 2A's exploration subagent both still read `tools: Read/Glob/Grep/LS only`. Claude Code grants no `LS` tool and has no alias for it, so the entry was silently dropped; both now read `tools: Read/Glob/Grep only`, matching the Copilot edition, which already had it right.

## [2.39.4] — 2026-08-02

### Fixed

- **`/vuln` + `/upgrade` re-review read a stale diff.** After `review-fixer` applied the `BLOCKER`/`MAJOR` fixes, "re-run the Opus review once" re-used the `review_diff_file` captured *before* those fixes, so the second verdict was computed on the pre-fix diff (and a `BLOCK` could never clear). Both paths now overwrite `review_diff_file` with a fresh `git add -N . && git diff` before the re-review — the same correction `/implement` received as a 2.39.2 follow-up but which was not carried into the 2.39.3 siblings.
- **`/implement`'s `test-writer` dispatches told the agent to shell out.** Phase 3.5 step 1 and Phase 3B step 4a embedded the `mktemp` + `git add -N . && git diff` capture *inside* the agent-facing prompt and left it unbracketed; `test-writer` has no `Bash` tool, so it could not comply. The capture is now an orchestrator action recorded as `test_diff_file`, and the prompt hands only that path — matching the `/document` + `/epics` handoff pattern.
- **Dispatch substitution brackets carried instructions instead of values.** `/vuln`'s two `vuln-fixer` dispatches and `/upgrade`'s `upgrade-executor` dispatch wrapped the whole "read … from the file at `<handle>`" sentence in `[…]`, which the house convention reads as "substitute the content here" — the opposite of the intent, and enough to defeat the file-handoff. Only the path handle is bracketed now.
- **`/vuln`'s SIMPLE/MODERATE regression-resume was a missed adoption site.** It still said "passing the same CVE input verbatim" while every other `/vuln` resume had moved to `research_file`.
- **`references/context-management.md` omitted the load-bearing temp-file guard.** As the authority for "hand off by file, not paste" it did not say the handoff file must be `mktemp`-ed **outside every repo working tree** — the property that keeps a later `git add -N . && git diff` from picking it up.
- **`references/handoff/vuln-fixer.md` + `references/handoff/upgrade-executor.md` described their report/plan section as inline-only.** Both now state the section may instead arrive as an absolute path to `Read`, matching what the orchestrators have sent since 2.39.3.
- **Dead `LS` tool entry removed from every `allowed-tools` / `tools` list.** Claude Code no longer ships an `LS` tool and provides no alias for it (v2.1.218: zero occurrences of `"LS"` in the binary; the legacy alias map is `Task→Agent`, `KillShell→TaskStop`, … with no `LS` entry). Unmatched entries are silently dropped, so the lists worked — but they advertised a tool that cannot be granted, and a `tools` list whose entries *all* fail to match makes the Agent tool refuse to launch. Removed from 50 command/agent files; the `ready:`-reviewer tool list in prose was corrected too. `Task` is kept: it is still a live alias for `Agent`.
- **`agents/risk-planner.md`'s requirement-ID example used the wrong form.** `[AC-3]`/`[TC-7]` → `[AC03]`/`[TC07]`, the form `references/specification-format.md` defines and `code-review`'s spec/design-conformance dimension traces against.

## [2.39.3] — 2026-08-02

### Changed

- **`/vuln` + `/upgrade` now hand their large dispatch artifacts to sub-agents as temp-file paths instead of pasting them inline.** The `/vuln` research report (to `vuln-fixer`, `code-review`, and the resume steps) and the `/upgrade` planner handoff (to `risk-planner`, `upgrade-executor`, and the resume step), plus each command's `code-review` `git diff`, are written to `mktemp` files — outside every repo working tree, so a captured `git diff` never picks them up — and handed as absolute paths. Extends the `/implement` file-handoff (2.39.2) and the `/document` + `/epics` pattern to the two remaining code-oriented commands; `vuln-fixer` and `upgrade-executor` `## Process` now notes that a field may arrive inline or as a path to `Read`. Behavior-preserving.

## [2.39.2] — 2026-08-02

### Changed

- **`/implement` now hands its large dispatch artifacts to sub-agents as temp-file paths instead of pasting them inline.** The multi-source codebase summary (Phase 1.7 / 2B), the approved plan (Phase 2A / 2B), the review diff (Phase 3B / 3.5), and the code-review report (Phase 3B review-fixer) are written to `mktemp` files — outside every repo working tree, so a captured `git diff` never picks them up — and handed to `risk-planner` / `test-writer` / `code-review` / `review-fixer` as absolute paths. This matches the existing `/document` + `/epics` handoff pattern and keeps the orchestrator's context lean on long runs. Behavior-preserving: each agent receives identical content, and its `## Inputs` now notes that a field may arrive inline or as a path to `Read`.

## [2.39.1] — 2026-08-02

### Fixed

- **`references/context-management.md` 4th-strategy consistency.** The wave-3 "Hand off by file, not paste" bullet left the section's trailing "Prefer the cheapest strategy…" summary enumerating only the original three offload strategies. Clarified that "Hand off by file" is orthogonal — applied whenever a sub-agent is dispatched, regardless of the chosen offload strategy. (Whole-branch-review NIT follow-up.)

## [2.39.0] — 2026-08-01

### Added

- **Deferred-backlog sharpeners (wave 3).** Six additive, single-location refinements harvested from the 2026-07-29 upstream deferred backlog (all additive/conditional; `references/specification-format.md` untouched):
  - **ADR candidacy filter** — `references/ard-format.md`: an `AD-N` earns its place only when the decision is hard-to-reverse AND surprising-without-context AND the result of a real trade-off (missing any of the three → an ordinary implementation choice, left to `/design`). [Matt `domain-modeling`]
  - **Wide-refactor sequencing exception** — `commands/epics.md` Phase 2: a named carve-out for blast-radius-wide *mechanical* changes that cannot be tracer-bulleted — expand → migrate-in-batches → contract, each phase its own Epic, contract blocked by every migrate-batch. [Matt `to-tickets`]
  - **Prototype-snippet exception** — `references/design-format.md`: prose is the default, with a narrow exception for a decision-encoding snippet (state machine / schema / type shape) that pins a decision down more precisely than prose. [Matt `to-spec`]
  - **Missing-adoption gap** — `agents/code-review.md` dimension 4: flags a sibling call site that should adopt changed behavior and doesn't (an untouched caller of the same pattern), uncaught by tests. Complements the wave-2 converge gate. [BMAD `lens-verification-gap`]
  - **`resume.md` redaction reminder** — `references/session-hygiene.md`: the `Carry-forward decisions` line redacts secrets / credentials / tokens / PII. [Matt `handoff`]
  - **Context "hand off by file, not paste"** — `references/context-management.md`: a 4th long-run strategy — write dispatch context (brief / diff / review package / summary) to a file and hand the subagent a path. Reference-only; the matching `/implement` dispatch-prompt refactor is deferred. [superpowers SDD]

### Fixed

- **`/idea` and `/create-vi` YAML frontmatter.** An unquoted `description:` value containing `: ` (colon-space) — `idea.md: a lean` and `profiles: --lean` — was parsed as a nested mapping, so `claude plugin validate` failed and the whole frontmatter (`name`, `allowed-tools`) was silently dropped at runtime. Removed the offending colon-space; both commands now validate and load their metadata. Pre-existing, unrelated to the wave-3 additions.

## [2.38.0] — 2026-07-29

### Added

- **Upstream-harvest improvements.** Adapted eight improvements from four upstreams (GitHub SpecKit, Matt Pocock skills, superpowers, BMAD) into the pipeline, all additive and conditional:
  - **Spec→code conformance ("converge").** `code-review` gains a conditional 10th dimension "Spec/design conformance" (active only when a `specification.md`/`design.md` is in scope) that traces every in-scope `[Uxx]`/`[ACxx]`/`[TCxx]` against the shipped diff (satisfied / missing / partial / contradicts, with severity mirroring the ARD-conformance dimension). `risk-planner` tags plan steps with the requirement IDs they implement. `/implement` extracts in-scope IDs, passes `applicable_spec` to the Opus review, reports conformance in Phase 5, and escalates unresolved `missing`/`contradicts` gaps as `- [ ]` notes back onto the spec/design (never silently, never as invented Jira work).
  - **Bug-diagnosis discipline.** New `references/bug-diagnosis.md` — feedback-loop-first: a red-capable, deterministic repro before hypothesizing; 3–5 ranked falsifiable hypotheses; `[DEBUG-xxxx]`-tagged instrumentation with a mandatory cleanup gate; regression test at a correct seam ("no correct seam" is itself a finding). Folded into `risk-planner` (`task_shape: bug` → repro-first plan + `### Hypotheses (ranked)`) and `/implement` (bug-shape detection + strip-before-review; `code-review` flags leftover `[DEBUG-xxxx]`).
  - **Quality gates.** `test-writer` gains a falsifiability gate + no-mirror-assertion / no-change-detector / production-methods-only constraints + a mutation self-check. `review-fixer` gains a `plan-conflict` disposition (a finding that contradicts the approved plan is surfaced for a human ruling, never auto-fixed against the plan). `code-review` gains a Fowler 12-smell floor in the Architectural-consistency dimension (MINOR/NIT, overridden by a documented repo standard).
  - **Authoring sharpeners.** `grilling-technique.md` gains a terminology-precision forcing move and an altitude-aware `## Ambiguity taxonomy` (NFR / integration / implicit-enum-branch / pre-mortem gap-categories that feed the existing Impact×Uncertainty ranking — no new mandatory questions). `spec-reviewer` gains NFR-coverage + implicit-enum-branch checks. `design-format.md` + `design-reviewer` gain deep-module / deletion-test / two-adapters seam-quality vocabulary. `risk-planner` gains a "No placeholders" self-review. `vi-format` + `vi-reviewer` gain optional counter-metrics (`[SM-C1]`).
  - Renamed the grill's "design tree" → "decision tree" (removes the naming clash with the `design.md` artifact).

## [2.37.0] — 2026-07-22

### Changed

- **No-hard-wrap prose convention.** New `references/prose-formatting.md` — the single source of truth: never hard-wrap prose; write each paragraph/prose block as one unbroken line, since Obsidian and IntelliJ Idea both soft-wrap for reading, and a straight copy-paste into Jira/Grammarly needs no manual cleanup. Consumed by every authoring command/agent that writes prose: `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, `epic-writer`, `doc-writer`, `release-notes-writer`.

## [2.36.0] — 2026-07-21

### Added

- **Documentation grounding on `$DOCS_PATH`.** `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, and `/specify` now ground their grill on the product's existing shipped documentation when `$DOCS_PATH` (default `${DOCS_PATH:-/workspace/docs}`) is set and valid; `/epics` and `/release-notes` attach the same docs digest to their writer handoff. New `references/docs-grounding.md` — the single source of truth for the `resolve-docs-grounding` resolution gate (read-only, silent non-blocking skip on any miss), the `dispatch-docs-grounder` procedure, and the two consumption modes (grill-rank for the five grill commands; writer-attach for `/epics` and `/release-notes`). New read-only `docs-grounder` agent — retrieves via the `qmd` CLI when available (`qmd update`, never `--pull`), falling back to keyword-overlap + `git log --grep` matching. Grounding is **positive-first**: each match is classified by `relation` (`same_feature` / `analogous_precedent` / `building_block`) with extracted `structural_facts`, plus bounded reconciliation `docs_challenges` (`already_documented`, `terminology_mismatch`, `contradicts_documented_behavior`, `diverges_from_precedent`, `adjacent_undocumented`). Advisory only — never a gate, never a reviewer BLOCKER; disable per-run with `--no-docs` or override the root with `--docs <path>`.
- **`/document` docs-repo discovery hint.** `/document` (Jira mode) now prefers `${DOCS_PATH:-/workspace/docs}` as a docs-repo discovery hint (checked between the cwd-with-signals path and the `$REPOS_PATH` search) — a write-target hint only, with no `docs-grounder` consumption.

## [2.35.0] — 2026-07-18

### Added

- **`/release-notes` Change Type + type-aware Summary (documenting a merged-but-undocumented feature).** New `references/release-note-types.md` — the single authority for the four-value **Change Type** taxonomy (`Breaking change` / `Bug fix` / `New technology support` / `not applicable`), the classification order (with tie-breakers), and per-type Summary shaping rules: Breaking change leads with customer benefit and an Action plan when the customer must act; Bug fix is past-tense, symptom-first, no hedging and no jargon; New technology support uses the existing benefit-led/enumeration shaping. Also defines an orthogonal **deprecation note** (`> Note:` line with a required end-of-life date, optional end-of-support date, never invented) triggered by VI deprecation signals. `release-notes-writer` applies this file and emits the proposed `change_type` (plus any `gaps[]`) on its handoff; `/release-notes` renders the type on a separate `Change type:` line — never inside the pipeline-consumed Summary body.
- **Authored/imported sourcing ladder for `change_type` / `release_notes_category`.** `release-note-types.md` §6 defines the precedence: an explicit `change_type_hint` always wins; otherwise the re-imported Jira VI frontmatter (surfaced by `jira-reader`) is authoritative; otherwise the authored `$SPECS_PATH` draft VI is read as secondary grounding per `references/vi-source-resolution.md` §5; otherwise the type is inferred from content. `jira-reader` now surfaces `change_type` and `release_notes_category` from VI frontmatter; when both imported and authored sources are present and differ, the imported value wins and a non-blocking divergence note is recorded. `release_notes_category` follows the same ladder minus the hint (imported → authored → none) and is always surfaced, never inferred.
- **`/create-vi` captures optional `change_type` + `release_notes_category`.** `references/vi-format.md` frontmatter gains optional `change_type` (`Breaking change | New technology support | Bug fix | not applicable`) and `release_notes_category` (the Dynatrace Solution) fields, authored-then-mirrored like `release_versions`. The grill asks for both only when `relevant_for_release_notes: yes`; dates/deprecation stay out of VI frontmatter (they belong in the release-notes Summary).
- **`vi-reviewer` validates the new fields.** Flags a `change_type` value outside the four-value enum as `MAJOR`, and raises a `MINOR` (recommended, not required) when `relevant_for_release_notes: yes` but `change_type` is absent; `release_notes_category`, when present, is free text with no format check.

## [2.34.0] — 2026-07-17

### Added

- **New `/update-vi` command (PM VI refresh).** Refreshes an existing Value Increment — routine refresh or an obstacle-driven re-do. Resolves the VI **Jira-import-first** (a new `references/vi-source-resolution.md`: the re-imported `$VAULT_PATH/jira-products/<KEY>` is the source of truth, 3-day freshness gate; the `$SPECS_PATH` draft is secondary), grounds on VI + comments + any ARD/spec/`@transcript`, updates via the grill against `references/vi-format.md`, gated by the Opus `vi-reviewer`, and writes **canonical + archived** revisions (`<KEY>_<slug>.md` latest; prior snapshot under `revisions/`). Product-level (no code scan).
- **`/create-vi --from-vi <VI-KEY|path>` seeding.** Author a new VI seeded read-only from a sibling VI (the techFit family pattern), recorded in a new `seeded_from_vi` frontmatter field; resolved Jira-import-first. A bare `/create-vi <existing-VI>` now redirects to `/update-vi`.
- **`vi-reviewer` non-contradiction dimension + `vi-format` internal-consistency rule + `/create-vi` grill self-consistency nudge** — flags a VI that contradicts itself (AC vs Out-of-scope, Goal vs Scope, conflicting US) at product altitude.

### Changed

- **VI filename standardized to `<KEY>_<slug>.md`** (frontmatter-based detection: `issue_type: ValueIncrement`), replacing the documented `<KEY>_ValueIncrement.md` across `create-vi`, `create-ard`, `vi-reviewer`, `vi-format`, `pre-lint`, and `ard-format`.

## [2.33.0] — 2026-07-15

### Added
- **`/document` (Jira mode): counterpart-space grounding.** A space-constrained run (`saas`|`managed`) now discovers the OTHER space's existing documentation for the same feature and hands it to the writer as **read-only grounding** — concepts, terminology, and structure to consult, never text to copy and never screenshots to reuse. New `counterpart-finder` agent (in-tree keyword search + `git log --grep`, plus an optional `--counterpart <JiraID|PR-url>` for an unmerged counterpart PR, resolved via the existing diff-summarizer strategies — zero new external API). New Phase 5.6.5; `counterpart_references[]` threads into `doc-planner` (grounding + a "target may already be covered" write-strategy signal) and `doc-writer`; `doc-reviewer` gains a cross-space leak/screenshot-provenance check.

## [2.32.1] — 2026-07-15

### Changed
- **README `/specify` VI-level scope note (docs-only).** The "Workflow overview" role table's `/specify <VI> [<Epic>]` signature already implies the Epic is optional, but the diagram/table collapse that variant into the same PE node, which read as if only `<VI> <Epic>` were real. Added a note under the role table clarifying: `/specify <VI>` is valid and stays in the PE lane; on a VI with ≥2 Epics, Phase 2's picker offers picking one Epic, an explicit "Author one broad VI-level spec instead," or the tool's own recommendation to split into Epics via `/epics` first; on a single-Epic VI it auto-resolves to that Epic; and a broad VI-level spec writes to `spec/<VI>-<vslug>` with its `### Next step` pointing to `/epics <VI>` rather than `/design <VI> <Epic>`.

## [2.32.0] — 2026-07-14

### Changed

- **`release-notes-writer` — editorial shaping (enhancement).** The writer no
  longer defaults to a flat "2–4 sentence paragraph" for every entry. Process
  step 3 now instructs conditional shaping grounded in shipped dynatrace-docs
  feature-updates: prose stays the default, but when a feature **enumerates
  discrete options** (e.g. a new dropdown with N selectable values) the writer
  uses a short intro sentence + a **bulleted list** (bold each option); it leads
  with the recommended/new default path and **demotes deprecated or manual-only
  options** to a trailing sentence or an optional `> Note:` line rather than
  presenting them as equal peers; and it uses **bold** for UI/field names and
  inline `code` for filenames, identifiers, and flags. The
  `release-notes-writer` handoff schema's `prose` field description was relaxed
  to match (no longer contradicts the agent by mandating a single paragraph).
  Motivation: a real release note enumerating four container-registry options
  read better as a list with the deprecated option footnoted than as a
  comma-chained paragraph. Ported from the Copilot variant of this marketplace
  (`ihudak-copilot-plugins` dev-workflows v2.1.0).

## [2.31.2] — 2026-07-14

### Fixed

- **`/statusline` install instructions were ambiguous with Claude Code's own built-in `/statusline` command.** The root README, plugin README, `statusline.md`, and `cost-emission.md` told users to "run `/statusline`", but Claude Code ships its own built-in `/statusline` (backed by the `statusline-setup` agent) under the same bare name — typing it runs Claude Code's built-in flow instead of installing this plugin's status line. All install instructions and cross-references now use the fully-qualified `/dev-workflows:statusline`, with an explicit note on the naming collision.

## [2.31.1] — 2026-07-14

### Fixed

- `epics.md`'s Phase 6.1/6.2 sub-phase label swap (v2.31.0) missed one cross-reference: the Phase 6 handoff-recording step still said `clarifications_needed[]` was recorded "for Phases 6.2 and 7" — but that field is consumed by the clarification gate (now Phase 6.1) and the review (Phase 7), never by the style check (Phase 6.2). Corrected to "Phases 6.1 and 7".

## [2.31.0] — 2026-07-14

Fixes from a full internal-correctness audit (2 BLOCKER, 7 MAJOR, 26 MINOR findings). No new commands, agents, or hooks — counts unchanged.

### Fixed (post-audit correction, same release)

- **`vuln-fixer` / `upgrade-executor` cannot use `AskUserQuestion` — subagents never can.** This session's own BUG-2 fix (granting explicit `tools:` to these agents) initially included `AskUserQuestion` to preserve their documented "ask the user" step, but Claude Code subagents cannot use that tool under any circumstances, even when it's listed in `tools:` — it depends on the main conversation's UI/session state. Both agents' "Test regression" step always instructed asking the user directly, so this was latent and broken before this session touched these files at all, not something introduced by the BUG-2 fix. Corrected properly: `AskUserQuestion` removed from both `tools:` lists; both agents now **stop and return** (`status: TEST_REGRESSION`, with the failing-test list + a diagnosis) instead of trying to ask; `vuln.md`/`upgrade.md` gained a `phase: regression-resume` + `regression_decision: keep-anyway | revert` handshake (mirroring the existing `AWAITING_REVIEW` / `verify-resume` pattern) so the **orchestrator** — which does run interactively — asks the user and resumes the subagent with the decision. Both handoff SSOTs updated to match.

### Fixed

**Blockers**
- `test-baseliner` never emitted the `status:` field that `vuln-fixer`/`upgrade-executor` branch their entire verify → proceed/revert control flow on (it only returned a differently-named, differently-valued `Comparison status:`) — every status-branch in both consumers was dead code. Added an explicit `Status` line with a documented computation rule to both capture and verify output, and rewrote the handoff SSOT to match the agent's real Markdown output shape.
- `docs-style-checker` dispatches `dt-style-guide:dt-style-checker` as its complementary/fallback/sole pass but didn't declare `Task` in `tools:` — the dispatch couldn't execute, so the style gate silently no-op'd on any repo without a primary linter.

**Majors**
- `vuln.md` (3×) and `upgrade.md` (4×) used the Copilot CLI's `agent_type:` instead of Claude Code's `subagent_type:`, breaking every sub-agent dispatch in both commands; the `model-routing` SSOT §5 example taught the same wrong param. Also fixed a leaked GitHub Copilot bot co-author trailer in `vuln.md`'s commit template and `vuln-fixer.md`.
- `implement.md` Phase 2B/3B carried stale "invoke via `general-purpose` with a `model: opus` override" prose that contradicted the frontmatter-pinned `subagent_type` dispatch directly below it.
- `upgrade-planner.md` claimed the orchestrator pins it to Opus for SIGNIFICANT/HIGH-RISK; `upgrade.md` always invokes it on the Sonnet chain before classification even happens — Opus review of a risky plan is `risk-planner`'s job, not a re-invocation of `upgrade-planner`.
- All 14 commands that invoke the `Skill` tool (the 13 model-routing-aware commands plus `prompt-brainstorm.md`) omitted `Skill` from `allowed-tools` — none of them could run their mandatory classification step if `allowed-tools` is enforced.
- `doc-writer.md` was told to name the Jira key in the changelog entry — `doc-planner`/`doc-reviewer`/`document.md` Phase 8.5 all BLOCK on exactly that.
- `references/handoff/jira-reader.md`'s `pull_requests[]` schema had a phantom `also_in` field (nothing emits it) and was missing `branch_from`/`branch_to`, which the agent does emit and `diff-summarizer` requires.
- `impl-maintenance`'s `Command run` enum (handoff + agent) listed only 9 of the 12 invoking commands — `/idea`, `/create-vi`, `/create-ard`, `/ready` had no valid slot to pass.

**Minors**
- Gave `upgrade-executor`, `upgrade-planner`, `vuln-fixer`, `vuln-research` explicit `tools:` (previously undeclared, inheriting everything) for parity with the other 26 agents.
- Added `BASELINE_FAILED` to `vuln-fixer`'s declared status enum and an explicit `NO_TESTS` branch in its baseline step; required `Command run: /vuln` / `/upgrade` in each command's `impl-maintenance` handoff (both previously defaulted to mislabeling as `/implement`); renumbered `implement.md`'s "Pre-Phase 2" to "Phase 1.6" (it sat between 1.5 and 1.7).
- Fixed `document.md`'s Phase 0 step numbering (1, 3–8 → 1–7) and every cross-reference to it; repointed 3 dead "Increment 2/3" pointers to the real phases (5.9, 6.3) that implement that logic.
- Swapped `epics.md`'s inverted 6.1/6.2 sub-phase labels (clarifications physically ran before the style check but was numbered after it) across all internal and 3 external cross-references.
- Reconciled `release-notes-writer`'s handoff schema (missing `code_repos` input, missing `jira_phrasing`/`source_phrasing`/`source_location` in `gaps[]`); aligned `doc-fixer`'s declared finding-schema field name (`description` → `message`, matching what producers actually emit); gave `doc-writer` `Bash` (scoped to local screenshot copy only) since `image_policy: local` requires a file copy its prior tools couldn't perform.
- `specify.md`: deleted a dead "(design §7)" pointer. `create-ard.md`: converted a prose jira-reader fallback into a formal Agent block with `depth`/`jira_key` (the agent hard-refuses without them) and added it to the `detection_model` consumer annotation. `ready.md`: added the missing `model:` on the `readiness-reviewer` dispatch. Replaced the non-enum "CONCERN" severity term with `MINOR` in `readiness-reviewer.md` / `workflow-states.md`. `idea.md`: carried `source_refs`/`provenance` forward so Phase 4 can build the `sources:` frontmatter entry it claims to append.
- Reworded `api-guideline-reviewer.md`'s self-contradicting "load ALL files — never a subset" (it lists a curated subset); marked `guideline-reviewer.md`'s dt-app MCP lookup section optional/environment-dependent (this plugin doesn't bundle that MCP server); synced `code-scanner`/`diff-summarizer`'s inline Output blocks to their handoff SSOTs (both were missing the `prep:` block; diff-summarizer was also missing several per-PR fields); prefixed 3 remaining bare `references/…`/`scripts/…`/`agents/…` citations with `${CLAUDE_PLUGIN_ROOT}/`; documented that `jira-reader`'s `NOT_FOUND` status covers both the Form-1 (`jira_export_root`) and Form-2 (vault path) resolution.

### Notes

- `guideline-reviewer.md`/`api-guideline-reviewer.md`'s remaining bare `references/guidelines/…` mentions, and `create-vi.md`/`create-ard.md`'s description-frontmatter mentions of `references/*-format.md`, are confirmed **not** bugs — the former carry their own "all paths relative to `${CLAUDE_PLUGIN_ROOT}`" preamble, the latter are human-facing catalog text, not runtime citations (both already excluded by the prior `12c245a` cleanup).

## [2.30.0] — 2026-07-13

### Changed

- **Documentation-consistency refresh.** README, repo-root CLAUDE.md, and the `model-routing` SKILL.md were brought in line with the plugin as shipped: the README Agents section now says **Thirty** subagents and **nine** Opus gates (added `vi-reviewer`, `ard-reviewer`, `readiness-reviewer`, `idea-reader` rows); the Commands table covers all 20 commands (one merged `/document` row + 8 previously-undocumented commands) with corrected classification framing; the Reference-docs catalog lists the ~18 SSOTs added since v2.14; and the `model-routing` consumer list is corrected to the **13** commands that invoke it (in CLAUDE.md and the skill's own description).
- **CLAUDE.md relationships diagram** extended to the six VI-creation-flow commands (`/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`, `/ready`) and their agents, with a concise VI-creation invariants block.
- The stale `## /implement workflow` per-phase mermaid graph was **replaced** with a coarse decision-shape graph (no Phase-N nodes) that no longer drifts when a phase is inserted.
- The four newly-cited handoff schemas (`code-scanner`, `diff-summarizer`, `impl-maintenance`, `jira-reader`) were reconciled to the agents' current input/output contracts — they had silently drifted while uncited (e.g. `impl-maintenance`'s schema still described a write-to-KB contract, contradicting the agent's current suggest-only report). No agent behavior changed; only the schema docs were corrected.

### Added

- The four handoff-schema references (`code-scanner`, `diff-summarizer`, `impl-maintenance`, `jira-reader`) are now cited by their agents, matching the wired sibling pattern.

### Notes

- No new command, agent, or hook — counts unchanged (Twenty slash commands / Thirty reusable subagents). Docs + one additive agent citation each; no command body changed.

## [2.29.0] — 2026-07-13

### Added

- `references/session-hygiene.md` — the plugin-wide SSOT for **session-hygiene suggestions**: a prepare-checkpoint that flushes resume-critical state to `<VI-dir>/dev-workflows/resume.md`, then a role-aware `/compact` (same role) vs `/clear` (cross-role handoff) suggestion, plus a `/rename <VI-ID>-<slug>-<role>` session-name aid. Guidance-only — never auto-run.
- A `### Context hygiene` block at the Final Report of every pipeline command (role-aware per `next-phase-offer.md`), and a mid-phase `/compact` suggestion at `/implement`'s checkpoint.

### Changed

- `/vuln` and `/upgrade` now end with a plain `/compact` suggestion (big non-pipeline runs).
- `next-phase-offer.md` and `context-management.md` cross-reference `session-hygiene.md`.

### Notes

- No new command, agent, or hook — counts unchanged (Twenty slash commands / Thirty reusable subagents).
- `/idea` and `/create-vi` (pre-VI-Key PM ideation) get the suggestion but no `resume.md`/`/rename`; direct/doc-edit modes omit the block.

## [2.28.0] — 2026-07-13

### Added

- **`/epics` refinement & VI-partition mode** — when a PE pre-creates empty Epic shells in Jira (one per team) and they are re-imported, `/epics <VI>` now detects them and offers to **refine** them in place: it partitions the VI scope across the team-Epics, fills each in (keyed `<EPIC-KEY>.md` in `jira-drafts/`, carrying a `**Team:**` line), captures cross-team dependencies, and routes leftover VI scope through an inline batched gate (assign to a team-Epic / propose a net-new Epic / defer). `/epics <VI> <Epic>` re-refines a single Epic by iterating on its current imported content. No new command — refinement is an auto-detected mode of `/epics`.
- `jira-reader` (`depth: vi-plus-epics`) now emits three additive per-Epic fields — `refinement_candidate`, `team` (verbatim from the Epic frontmatter `team:`), and `scope_hint` — used to detect empty team-Epic shells. Additive and depth-gated; other consumers are unaffected.
- `epic-reviewer` gains four conditional refinement dimensions (refinement completeness, partition integrity, cross-team dependency sanity, team preserved), active only when the review brief includes refinement targets.

### Changed

- The code-examination default is now **adaptive in refinement mode** — ON when 2+ team-Epics are being refined, OFF for a single target (always still asked interactively). The generate-net-new path is unchanged.

### Notes

- Strictly additive / no-regression: `/epics <VI>` with no empty shells and no focus key is byte-identical to 2.27.0. `/vuln`, `/upgrade`, and the sibling plugins are untouched. Command / agent counts unchanged (Twenty / Thirty).

## [2.27.0] — 2026-07-13

### Added

- **`## Workflow overview`** in `README.md` — a mermaid role-graph (PM / PA / PE / Dev / QA lanes) of the idea→VI→ARD→Epics→spec→design→implement→document→release-notes pipeline, an annotation table (role · starting command · consumes · produces), a "Sources of truth & artifact homes" note (including where feedback / cost / follow-up files land in the specs repo, and that committing them is expected), and a "Cross-cutting commands" subsection surfacing `/feedback`, `/prompt*`, `/vuln`, `/upgrade`, and the setup / review utilities.

### Changed

- **`/specify` is labelled PE, not PM**, everywhere — `commands/specify.md`, `commands/design.md`, the `README.md` command table, and `references/workflow-states.md` — matching `references/next-phase-offer.md` (already routed under PE) and the command's own `role: pe` cost attribution. No behavior change.
- Repo-root `CLAUDE.md` — de-staled the retired `/impl:*` colon-taxonomy (`/impl:code`, `/impl:docs`, `/impl:jira:*`, …) to the current flat commands (`/implement`, `/document`, `/docs-profile`, `/epics`, `/release-notes`) across the workflow-relationships diagram, the model-routing / source-truth references, and the per-command invariants blocks.
- Corrected the stale "Twelve workflow slash commands" lead in `README.md` to "Twenty …".

## [2.26.0] — 2026-07-12

### Added

- **`references/pre-lint.md`** — new SSOT of deterministic, grep-expressible structural checks (universal + per-artifact for VI/ARD/spec/Epic/design). A thin advisory **Structural pre-lint** phase now runs immediately before the Opus reviewer in `/create-vi` (3.6), `/create-ard` (4.5), `/specify` (5.5), `/design` (5.5), and `/epics` (6.3): it surfaces mechanical defects (missing sections, duplicate/gapped IDs, stray placeholders, ARD `Binds`/`Prevents`/`Rule`, spec open-questions-count) and inline-fixes the trivial ones so an Opus pass is not consumed on structure. Advisory — never hard-blocks; the reviewers remain the gate and are unchanged.
- **`references/context-management.md`** — new long-run strategy doc (scope-to-N / sub-agent-per-`[P]` / decompose); `/implement` Phase 3B cites it for long step lists.

### Changed

- **Grilling technique** — added an "Autonomous / background invocation" guard: with no human turn available, genuine decisions are recorded as open questions (`[NEEDS CLARIFICATION]` / `- [ ]`) rather than self-answered.
- **`vi-reviewer`** — the substance-over-theater dimension now also flags non-empty-but-hollow prose (vision/persona/NFR that reads well but states no testable commitment) as `MAJOR`.

### Notes

- Polish batch from the AI-First line-85 borrow analysis. 2 new reference docs, 0 new commands/agents — counts unchanged (20 commands / 30 subagents), descriptions byte-identical. No-regression: `/vuln`, `/upgrade`, the four other reviewer agents, and the sibling plugins are untouched. (Items "/idea URL-fetch policy" and "/specify seam step" were dropped — no live fetch exists in `/idea`, and the seam concept already lives in `/design`.)

## [2.25.0] — 2026-07-12

### Changed

- **`/prompt-grill-me`** no longer hands off to Matt Pocock's `/grilling` skill (or the `superpowers:brainstorming` fallback). It now grills the fix **inline** — a bounded one-question-at-a-time interrogation of the correction following the embedded `references/grilling-technique.md`. Feedback capture (`emit-prompt`, `origin: prompt`) and the "never commits / never writes to a repo or the cwd" guarantees are unchanged.
- **Dropped the optional `mattpocock-skills` dependency.** Removed it from the *Recommended companions* table in `references/dependencies.md` and the operational mentions in `README.md`, `references/feedback-emission.md`, and `references/grilling-technique.md`. The grilling technique remains fully embedded; the "adapted from mattpocock grill-me/grilling" attribution is retained.

### Notes

- Closes AI-First line 87. The five authoring commands (`/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`) were already zero-dependency. Counts unchanged — **20** commands / **30** subagents (`/prompt-grill-me` retargeted, not removed). No-regression: `/vuln`, `/upgrade`, `jira-reader`, and the sibling plugins are untouched.

## [2.24.0] — 2026-07-12

### Added

- **`/ready <VI> [<Epic>]`** — new status-anchored readiness gate. Reads the Jira workflow status (already emitted by `jira-reader` — no importer/reader change) and verifies the ARD/spec/design artifacts justify it and the next transition; returns **SUPPORTED / PARTIAL / NOT-SUPPORTED** with a coverage roll-up and cross-artifact findings. Read-only: never sets Jira status, never branches, never auto-commits. Writes a `_readiness.md` evidence snapshot to `$SPECS_PATH` for team visibility. Doc-only, with a best-effort repo-availability presence check.
- **`readiness-reviewer`** — new Opus subagent; the only reviewer doing joint cross-artifact analysis (status consistency, coverage chain, alignment, ARD conformance, scope integrity, identifier integrity, repo availability).
- **`references/workflow-states.md`** — new rubric mapping VI/Epic Jira status ladders ↔ pipeline command ↔ owning role ↔ expected artifacts.
- `/implement`: additive Jira-mode **Phase 0.5 readiness pre-flight** (advisory, non-blocking; direct mode byte-identical). `next-phase-offer.md`: `/ready` added as an optional Team/Dev gate.

### Notes

- Flagship borrow from the BMAD + SpecKit + Superpowers + grill-me analysis (AI-First line 85). New command + agent — counts 19 → **20** commands / 29 → **30** subagents. No-regression: `jira-reader`, `/vuln`, `/upgrade`, and the sibling plugins are untouched; `/implement` direct mode is byte-identical.

## [2.23.0] — 2026-07-12

### Added

- `/epics`: new optional **Phase 2.6 VI-level spec enrichment** — when a VI-level `specification.md` exists (detected via the VI dir `/epics` already resolves), its `[Uxx]`/`[ACxx]` requirements are folded into the coverage inventory as `spec-story`/`spec-criterion` rows, so the `_coverage.md` matrix reflects the richer spec-level requirements. Test cases (`[TCxx]`) are excluded (per-AC, non-unique, below Epic granularity). `epic-writer` notes `+ VI-level spec` on the `_source:` line; `epic-reviewer` checks the spec rows identically (uncovered → MAJOR).

### Notes

- Closes the last v2.21.0 follow-up (Cluster B / #4). Strictly additive: a run with no VI-level spec (the common case) is byte-identical to v2.22.0. No new command or agent — counts unchanged (19 / 29). `jira-reader`, `vi-reviewer`, `/vuln`, `/upgrade`, and the sibling plugins are untouched.

## [2.22.0] — 2026-07-12

### Added

- `/create-vi`: new **Phase 3.5 Dynatrace style check** — runs `dt-style-checker` on the authored VI before the `vi-reviewer` gate (emphasis: terminology + customer-facing captions/labels/messages/text), fixes applied inline, graceful skip when `dt-style-guide` is not installed. Advisory (non-gating); mirrors `/epics` Phase 6.1. VIs previously got no style check.
- `/create-vi`: **nudge toward richer requirements for complex VIs** — a Phase 1.5 non-blocking profile suggestion (SIGNIFICANT + `--lean`/`--hybrid` → consider `--full` for `FR-N`/`UC-N`) and Phase 3 active-pull of the `FR-N`/`UC-N` clusters, for finer downstream `/epics` coverage traceability. `vi-reviewer` unchanged (authoring-side only).

### Notes

- Closes two recorded follow-ups from v2.21.0. No new command or agent — counts unchanged (19 / 29). No-regression: a SIMPLE/MODERATE VI (or one run without `dt-style-guide`) behaves as before; `/vuln`, `/upgrade`, `agents/vi-reviewer.md`, and the sibling plugins are untouched. The two marginal v2.21.0 follow-ups (graded reviewer rubric; cross-iteration regression tracking) were dropped.

## [2.21.0] — 2026-07-12

### Added

- `/epics`: requirement→Epic **coverage matrix** with gap-detection — `jira-reader` now emits a `requirements[]` inventory (native VI `US/AC/SM/FR/UC` IDs, with a goal+themes `derived` fallback); `epic-writer` writes `_coverage.md` (VI-holistic, roll-up verdict + coverage %); `epic-reviewer` verifies it (uncovered requirement = MAJOR).
- `/epics`: `[NEEDS CLARIFICATION]` markers (cap 3/Epic; deps > AC > scope) + a Phase 6.2 batched resolution gate; unresolved-by-choice markers become reviewer BLOCKERs.
- `/epics`: Given/When/Then acceptance criteria + an `## Independent Test` line; source-anchored `[Source: path#Section]` citations; a pre-draft dedup pre-flight + a sizing/sequencing heuristic.
- `/epics`: new `epic-reviewer` dimensions — epic-independence (no-forward-dependency, MAJOR), internal terminology-drift (MINOR), anti-pattern + filler/"theater" detection under goal clarity.
- `/epics`: **ARD wiring** — new optional Phase 2.5 resolves the VI-level ARD (mirrors `/specify`); writer respects `AD-N` + records deviations; reviewer gains a conditional ARD-conformance dimension (BLOCKER without a deviation record). Additive, guarded on `status: found`. `/epics` added to `references/ard-resolution.md` consumers.
- `/epics`: Phase 6.1 `dt-style-checker` brief now emphasizes terminology + customer-facing captions/labels/messages/text.

### Notes

- No new command or agent — counts unchanged (19 commands / 29 agents). No-regression: a run with no ARD and no clarification markers behaves as before; `/vuln`, `/upgrade`, `/document`, and the sibling plugins are untouched.

## [2.20.0] — 2026-07-10

### Changed

- **The personal-store write-gate no longer requires an Obsidian `.obsidian/` directory.** The four vault write-gates — `/idea` Phase 0, and the `$VAULT_PATH`-fallback tiers of `references/feedback-emission.md`, `references/cost-emission.md`, and `references/followup-emission.md` — now accept `$VAULT_PATH` when it is **set + an existing directory + writable**, dropping the `.obsidian/`-directory proxy. Setting `$VAULT_PATH` is the user's explicit declaration of their personal store, and the rest of the plugin (`/release-notes`, `/epics`, `/document` staging) already trusted it on "set" alone — so this makes the four outlier gates consistent and lets non-Obsidian personal stores work. The "never write to the wrong place" guard is preserved: `$VAULT_PATH` must be set + exist + be writable, writes always land in a namespaced subdir (`$VAULT_PATH/dev-workflows/…`, `$VAULT_PATH/Projects/…`), and the NEVER-cwd rule is untouched. The `/followup` no-vault notice is softened `⚠ No writable Obsidian vault` → `⚠ No writable vault`. **No-regression:** existing `.obsidian/` vaults are still writable directories, so they behave identically; `/document`'s defensive `.obsidian/` git-forbid guard and the `.obsidian/copilot/` tag-index path are unchanged, and `/vuln`, `/upgrade`, and sibling plugins are untouched. No new command or subagent (version-only manifest bump).

## [2.19.0] — 2026-07-10

### Added

- **Every pipeline command now ends with an adaptive `### Next step` recommendation.** The end-of-run next-phase offer — previously only in `/idea`, `/create-vi`, `/create-ard` — is now a plugin-wide invariant backed by a new single-source-of-truth reference, `references/next-phase-offer.md` (the role-aware routing graph + a 5-rule contract: guidance-only / role-labeled / adaptive-to-outcome / mode-aware / Epic fan-out). The six pipeline commands that lacked it — `/specify`, `/design`, `/implement`, `/document`, `/epics`, `/release-notes` — now close their Final Report with a `### Next step` section naming the next command(s) tagged with the owning role (PM / PA / PE / Team), so a multi-hat user just keeps going. **Epic fan-out:** the per-Epic commands (`/create-ard <VI> <Epic>`, `/specify <VI> <Epic>`, `/design`, `/implement`) offer both depth (next command, same Epic) and breadth (same command, next Epic); `/document` + `/release-notes` are VI-level and run once after all Epics are implemented. The three reference commands are retrofitted to cite the SSOT; `/create-vi` also gains the PE → `/epics` handoff (and marks `/release-notes` recommended, `/create-ard` optional). **Strictly no-regression / additive:** the `### Next step` only *adds* a report section, and it is omitted in a command's direct / doc-edit mode (no VI/Epic pipeline context), so those runs are byte-identical. `/vuln` and `/upgrade` are not pipeline nodes and are untouched. No new command or subagent (version-only manifest bump — Nineteen commands / Twenty-nine subagents unchanged). Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched. **Follow-up:** revisit the `.obsidian/` vault-check.

## [2.18.0] — 2026-07-10

### Added

- **`/design`, `/implement`, and `/specify` now respect the ARD produced by `/create-ard`.** A new shared `references/ard-resolution.md` resolves the applicable ARD(s) for a `<VI>` (+ optional `<Epic>`/area) — most-specific first (per-area → Epic-level → inherited VI-level `AD-N`) — and returns a normalized context or **`none`**. Each consumer resolves early and passes the `AD-N` invariants to its reviewer as an optional `applicable_ard`; `design-reviewer`, `spec-reviewer`, and the shared `code-review` gain a **conditional** "ARD conformance" dimension that checks the artifact honors every `AD-N` `Rule`. Enforcement is **binding + deviation-record**: a violation with no recorded "ARD deviation" (flagged to the architect, in the consumer's own artifact — never the ARD) is a reviewer **BLOCKER**; a recorded deviation is allowed-but-flagged. **Strictly no-regression:** when no ARD resolves (the common case — `/create-ard` is optional) every command behaves byte-identically to before, and the reviewer dimension is skipped. Because `code-review` is shared, its dimension is gated on the caller passing `applicable_ard` — **`/vuln` and `/upgrade` never do and are not modified**. No new command or subagent (version-only manifest bump). Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched. **Follow-ups:** next-phase-offer-everywhere; revisit the `.obsidian/` vault-check.

## [2.17.0] — 2026-07-10

### Added

- **New `/create-ard` command — sub-project 3 (final) of the VI-creation flow (Product Architect phase).** `/create-ard <VI-KEY> [<Epic-KEY>]` grounds on the mounted implementation repos and authors an **ARD** (Architecture Requirements/Decision Document) that establishes the architecture invariants the downstream inherits. **Optional** (a simple VI may not need one — Phase 0 advises) and **scoped** via the two-key grammar: `<VI-KEY>` → VI-level (cross-cutting invariants + broad grounding); `<VI-KEY> <Epic-KEY>` → Epic-level (deeper; inherits the VI-level ARD's `AD-N` read-only). A big Epic spanning separable areas in one repo (e.g. `cluster2` `server/`+`ui/`) can split into `<EPIC>-<area>_ARD.md`. Grounding is **architect-driven, not PR-derived** (no PRs exist at ARD time): cheap `$REPOS_PATH` discovery + a `theme→repo` proposal + ask the architect + a consolidated mount-or-descope gate, then `code-scanner` on the confirmed set. Authored inline via the relentless grill against a new `references/ard-format.md` (Context · Grounding findings with real `file:line` · Architecture decisions `AD-N: Binds/Prevents/Rule` · Cross-repo map · Stack & invariants · Edge cases · Open questions · Deferred), gated by a new Opus **`ard-reviewer`** (grounding integrity, `AD-N` testability, no contradiction of inherited invariants, altitude purity), with a `/design`-style tiered hard model gate, written to `$SPECS_PATH/specifications/<KEY>-<slug>/`, branch+PR offer. Introduces the **`pa` (Product Architect)** role / `architecture` phase in the cost + feedback model. `references/feedback-emission.md` (ten → eleven commands) and `references/dependencies.md` (grilling list) reconciled. The sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched. **Follow-up (v2.18.0):** wire ARD *consumption* into `/design`, `/implement`, and `/specify` (both VI + Epic levels) — this effort ships the producer only.

## [2.16.0] — 2026-07-10

### Added

- **New `/create-vi` command — sub-project 2 of the VI-creation flow (PM phase).** `/create-vi <JIRA-KEY> [@idea.md] [--lean|--hybrid|--full]` turns a refined `idea.md` + a user-supplied Jira key (an empty workitem the user created for the ID; mandatory — graceful fail without it) into a product-level **Value Increment**. A new `references/vi-format.md` defines a mandatory **spine** (Problem · Goal · Target audience · User Stories `[US-N]` · Acceptance Criteria `[AC-N]` · Scope · Success Metrics `[SM-N]`) plus an **adapt-in menu** (union of Mike's + Alex's sections) selected by profile and pulled only when the idea warrants it. Authored inline via a relentless grill, gated by a new Opus **`vi-reviewer`**, written to `$SPECS_PATH/specifications/<KEY>-<slug>/<KEY>_ValueIncrement.md` (the relocated `idea.md` co-located; `sources` propagated from the idea's real provenance, not the literal `idea.md`), with a branch+PR offer and a documented paste-into-Jira + re-import round-trip. Product-level: **no code scan, no repos required** (`/specify` does the light code grounding + Test Cases downstream). Phase 6 offers **both** next steps — `/release-notes` (PM, now) and `/create-ard` (Product Architect handoff). Wired into the terminal tail: `impl-maintenance` + `emit-auto` + `emit-cost` (`vi-creation`/`pm`) + capture-at-block.

### Changed

- **Grilling technique consolidated into `references/grilling-technique.md` (SSOT).** `/idea`, `/specify`, and `/design` now cite it instead of each embedding the ~5-line technique (DRY; each keeps its own depth — bounded/`--deep` for `/idea`, relentless for the others — and stage list). Still no runtime dependency. `references/feedback-emission.md` (nine → ten commands) and `references/cost-emission.md` (VI-lifecycle enum + the promoted `/create-vi` attribution row) reconciled. Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched.

## [2.15.0] — 2026-07-10

### Added

- **New `/idea` command — the front door of the VI-creation flow (PM phase).** `/idea <prompt | @file | JIRA-KEY> [--deep]` ingests one of four sources — an inline prompt, a markdown file (wikilinks + images followed), a community post, or an exported RFE Jira ticket — via a new read-only `idea-reader` subagent (Sonnet tier; auto-detects the source type with provenance tags, follows wikilinks one level, enumerates linked images by path, captures community-post demand signals). The Opus orchestrator then refines it through the embedded grilling technique — bounded by default (≤5 Impact×Uncertainty questions, one at a time, recommended answers; leftover gaps become `[NEEDS CLARIFICATION]` capped at 3 + logged Assumptions) or relentless under `--deep` — and writes a lean one-page `idea.md` (new `references/idea-format.md` is the SSOT) to the vault under `$VAULT_PATH/Projects/<area>/<slug>/`, keyless, `status: refined` iff zero open clarifications remain. `$VAULT_PATH` is validated (falls back to a user-supplied directory, never cwd). The grill is the quality gate (no reviewer agent at the idea stage). On finish it makes an adaptive next-phase offer toward the future `/create-vi`. Wired into the standard terminal tail: `impl-maintenance` + `emit-auto` feedback, `emit-cost` (`phase: vi-creation`, `role: pm`, keyless → pending ladder), and the capture-at-block invariant. A new `references/dependencies.md` documents the recommended companions (`mattpocock-skills` `/grilling`, `superpowers`, `dt-style-guide`) and the external `jira-workitem-import` importer, all convention + runtime-resolve + graceful fallback (no manifest field). `references/feedback-emission.md` (eight → nine commands) and `references/cost-emission.md` (VI-lifecycle enumeration + the `/idea` attribution row) are reconciled. The sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.14.0] — 2026-07-10

### Added

- **Capture-at-block: a workflow that halts on a plugin gap now records it immediately, so an abandoned run doesn't lose its highest-value feedback.** A new `emit-block` entry point in `references/feedback-emission.md` (fourth alongside `emit-auto` / `emit-manual` / `emit-prompt`) writes one silent `origin: auto`, `impact: blocker` feedback entry when a run stops because the plugin lacked a capability / reference / skill / command-path the run needed — passing the gap directly (no `impl-maintenance` report exists mid-flight), deduped by the stable `id` so it never double-logs with a later terminal `emit-auto`. All eight pipeline commands (`/implement`, `/document`, `/epics`, `/release-notes`, `/specify`, `/design`, `/vuln`, `/upgrade`) carry the invariant: `emit-block` **before** escalating a plugin-gap halt. It fires **only** for plugin-facing gaps — never for a code/doc/Epic review BLOCK (a defect in the work), an environment/user halt (repo-missing, dirty-tree, jira-not-found, refresh-blocked), or a cancellation. This is not an interrupt or an enforced-collection gate — capture-at-block stays inside the deliberate silent, high-recall model (the halt is surfaced by the command's normal BLOCKED escalation, not a feedback prompt). The `impl-maintenance` agent and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.13.0] — 2026-07-10

### Added

- **`/document` (Jira mode) now discovers images from the project folder too.** Phase 5.6 gains a fourth candidate source — a recursive scan of the ticket's persistent Obsidian project folder (`<project_dir>`, resolved in Phase 1 under `$VAULT_PATH/Projects/<VI-dir>`) — alongside the existing specs-dir scan, the `jira-reader` Jira attachments (developer-attached screenshots under `jira-products/<VI-dir>/…`), and manual paths. So curated diagrams and screenshots kept in the project folder are offered automatically (deduped with the other sources; the "select a subset" flow still applies; contributes nothing when no project folder exists). The candidate summary now reports the per-source counts including "from the project folder." The add-a-new-image guidance is made explicit: place new images in the Projects VI-dir, **never** under `jira-products/` (which the Jira importer regenerates, discarding manual additions). Downstream placement, `image_policy`, and the CDN upload/defer handoff are unchanged; `jira-reader`, the doc agents, `/release-notes`, direct mode, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.12.0] — 2026-07-10

### Added

- **`/document` now applies the full dynatrace-docs frontmatter/metadata rules, not just changelog + owners.** A new reference `references/dynatrace-docs/frontmatter-guidelines.md` is the source of truth for the metadata fields: `title` (sentence case), `description` (**120–160 chars** SEO), `meta.content-type` (**mandatory** on new pages — the Diátaxis-plus-Dynatrace enum `how-to`/`tutorial`/`explanation`/`reference`/`get-started`/`troubleshooting`/`upgrade`/`best-practices`/`app`/`extension`; `overview` is deprecated; `release-notes` pages remain automation-generated), `meta.i18n-priority` (number), and `meta.generation` (`latest`/`classic`, with the Managed-build caveat). The `dynatrace-docs-frontmatter` skill sets/validates them, `doc-planner` plans them, `doc-writer` writes them, and `doc-reviewer` gates them — **missing/invalid `content-type` on a new page → BLOCKER; `description` outside 120–160 → warning; the rest advisory**. Applied only under the dynatrace-docs profile; a generic docs repo is unaffected. The `changelog:` and `owners:` conventions keep their own references (only cross-linked).
- **`/document` (Jira mode) now ingests a docs repo's own authoring rules.** `doc-planner` reads whichever guidance files a repo has — `CONTRIBUTING.md`, `CONTRIBUTION.md`, `README.md`, `CLAUDE.md` (+ `.claude/`), `STYLE.md`, `DOCUMENTATION-GUIDELINES.md` — and extracts the **authoring/structural** rules (required sections, voice/tone, page templates, structure/naming conventions), emitting a `repo_authoring_guidance` block that is surfaced in the Phase 5.7 plan (so you see "this repo's CONTRIBUTING.md requires …" before approving), passed to `doc-writer` (which follows it), and checked by `doc-reviewer` (a missing repo-mandated section → MAJOR). Generic (any repo); it **augments, never overrides** the built-in references and `dt-style-guide`, and does not duplicate the existing branch-naming read. Direct mode already ingests these files in its Phase 2A exploration and is unchanged. `/release-notes` and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.11.0] — 2026-07-10

### Changed

- **`/document` (Jira mode) now shows a single consolidated repo gate up front instead of a per-repo escalation loop.** As soon as the affected-repo set is known — Phase 4, right after `jira-reader` returns the PR links and before any diff work — `/document` presents one summary: the repositories the VI's Jira PRs span, which are mounted (✓) and which are missing (✗), and a note that missing repos are skipped so their code is not diff-summarised or checked against the VI's requirements (the discrepancy analysis is partial). It then offers **mount the missing repo(s) now and re-scan** (recommended — mount whichever are available under `$REPOS_PATH`, re-scan, repeat, which also gives per-repo control), **proceed without them** (Jira-only for the missing repos — byte-identical downstream state to the previous per-repo "skip"), **cancel**, or **specify an absolute path** for a missing repo. The all-mounted happy path is unchanged apart from a one-line "Resolved N/N repositories" note. The choice semantics still come from the `Repo unresolved (zero matches) — /document` rule in `references/escalation-rules.md`, now applied to the whole missing set at once. Jira mode only — `/document` direct mode (no repos), `/design`'s hard repo gate, and every subagent / reference / sibling plugin (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.10.2] — 2026-07-10

### Fixed

- **Session-cost price table now carries real Claude API rates for every model the routing policy can reach.** `references/cost-prices.yaml` had shipped with placeholder rates: Claude Opus 4.8 was priced at the old Opus 4.1 rates (`$15` / `$75` per MTok — roughly 3× too high), and `claude-sonnet-4-6` — a real, heavily-used Sonnet-chain fallback — had no key at all, so its usage was silently priced `null` (`unpriced-model`). Rates are now the standard first-party Claude API prices from Anthropic's pricing page: Opus 4.6–4.8 `$5` / `$25`, Sonnet 5 / 4.5 / 4.6 `$3` / `$15`, Haiku 4.5 `$1` / `$5`, with the cache 5m / 1h / read tiers at the standard 1.25× / 2× / 0.1× multipliers. Keys now cover the whole Opus chain (`4-8` / `4-7` / `4-6`), the whole Sonnet chain (`5` / `4-6` / `4-5`), and Haiku (`4-5`); prefix-matching prices dated transcript ids (e.g. `claude-haiku-4-5-20251001`) off their undated base key. **Permanent standard rates are used deliberately — never promotional / introductory rates** (Sonnet 5 is keyed at its standard `$3` / `$15`, not the `$2` / `$10` introductory price in effect through 2026-08-31) so cost figures stay comparable across Value Increments over time. `references/cost-emission.md` §4 is reconciled to describe the real permanent-rate table. Data / documentation only — no `session-cost.py` engine logic changed.

## [2.10.1] — 2026-07-10

### Changed

- **`impl-maintenance` agent — completed its illustrative `Command` enumeration.** The agent's two command lists (the `Command run` input description and the `Command workflow improvements` output section) now include `/design`, `/specify`, and `/release-notes` alongside the existing `/implement`, `/document` (both modes), `/epics`, `/vuln`, and `/upgrade` — matching the eight commands that actually invoke the agent (the three were added by the v2.9.0 feedback / maintenance phases). Documentation-only; no behavior change (the agent already defaults correctly when `Command run` is absent).

## [2.10.0] — 2026-07-09

### Added

- **Session cost reporting — the plugin now records how many dollars a Value Increment cost across its lifecycle, by phase / role / model, persisted per-VI into the specs repo for the maintainer to aggregate.** Claude Code stores no dollar figure in the transcript, so cost is **computed**: a new stdlib-only engine `scripts/session-cost.py` reads the session's main transcript from a chained-checkpoint line offset forward plus the session's `subagents/agent-*.jsonl` within a `(last_ts, now]` window, sums `usage` by model, and applies the new `references/cost-prices.yaml` price table (USD per million tokens; the cache 5m/1h split priced exactly; unknown model → tokens recorded, cost `null`; overridable via `$DEV_WORKFLOWS_COST_PRICES`). A new shared reference `references/cost-emission.md` is the single source of truth: session-artifact resolution, the chained-checkpoint model (advance ALWAYS — even report-only), the machine-friendly per-invocation entry format written to `<VI-dir>/dev-workflows/cost/<sid8>.md` (one file per session → merge-safe under massive team fan-out), the specs-first persistence ladder (never the cwd), pending + opportunistic move-then-delete reconciliation for keyless runs, the optional statusline cross-check, attribution (incl. the `/release-notes` PM-vs-dev inference keyed on `specification.md` / `design.md` presence, never Epics), privacy (no user name in any cost file), and the single `emit-cost` caller contract.
- **Terminal cost phase across the six VI-lifecycle commands.** `/specify` (specification/pe), `/epics` (epic-refinement/pe), `/design` (planning/dev), `/implement` (implementation/dev), `/document` (documenting/dev — Mode A + Mode B), and `/release-notes` (phase/role inferred) gain a terminal Session cost phase — the new final operational phase, after the feedback phase — that cites `cost-emission.md` and calls `emit-cost`. Cost **always runs** and always advances the chained checkpoint (even report-only), so per-command costs sum to the session total. `/vuln` and `/upgrade` are deliberately out of scope (no VI to attribute to).
- **New command `/statusline`.** Installs the plugin's multi-line status line into `~/.claude/settings.json` (idempotent; backs up any existing script + `statusLine` block; confirms before writing). Its vendored script also writes a per-render `{ts, cost_usd}` snapshot from `.cost.total_cost_usd` to `~/.claude/dev-workflows/cost-snapshots/<session_id>.json`, enabling the Option B authoritative cross-check in session cost reporting.

Additive only — the `impl-maintenance` agent, `jira-reader`, the reviewers, the format references, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; no cost phase ever fails the run, commits, or writes into the current working directory, and no user name is written to any cost file.

## [2.9.0] — 2026-07-09

### Added

- **Session feedback collection — the plugin now captures friction and improvement signals about itself and persists them per-VI into the specs repo for the maintainer to aggregate.** A new shared reference `references/feedback-emission.md` is the single source of truth: the machine-friendly entry format (file frontmatter `type` / `vi` / `slug` + per-entry YAML `id` / `date` / `command` / `plugin_version` / `origin` / `author` / `category` / `impact` + prose), the **specs-first** persistence ladder (`$SPECS_PATH` VI dir `<VI-dir>/dev-workflows/<KEY>-feedback.md` → `$SPECS_PATH/dev-workflows-feedback/` → a writable vault with a loud "won't auto-aggregate" notice → beside an imported Jira directory → report-only; **never the cwd**), append-only dedup with `git`-derived attribution, the plugin-facing predicate (persist plugin signal only — never target-project `CLAUDE.md` / hook advice), and a three-entry-point caller contract (`emit-auto`, `emit-manual`, `emit-prompt`).
- **Automatic capture across all eight workflow commands.** `/implement`, `/document` (Mode A + Mode B), `/epics`, `/vuln`, and `/upgrade` now persist the plugin-facing slice of their existing `impl-maintenance` report (Command workflow improvements + New agents/skills + Reference-doc gaps + the triggering Key observations) as `origin: auto` feedback, silently, after maintenance runs. `/release-notes`, `/specify`, and `/design` gain a new lightweight terminal maintenance phase that invokes `impl-maintenance` on the Sonnet detection chain and then persists. A routine session with no plugin-facing signal writes nothing (byte-identical to before).
- **New commands `/feedback`, `/prompt`, `/prompt-brainstorm`, and `/prompt-grill-me`.** `/feedback <text>` logs a universal manual note (`origin: manual`). The `/prompt*` family captures a corrective interaction — Friction, your verbatim prompt, and the Resolution (`origin: prompt`): `/prompt` acts on the correction directly, `/prompt-brainstorm` hands off to `superpowers:brainstorming`, and `/prompt-grill-me` runtime-resolves `/grilling` (mattpocock-skills) and falls back to `superpowers:brainstorming` if it is not installed. No hard cross-plugin dependency.

Additive only — the `impl-maintenance` agent core, `jira-reader`, the reviewers, `format-refs`, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; feedback also always remains in the run's final output (zero loss) and no capture phase ever fails the run.

## [2.8.0] — 2026-07-09

### Added

- **Follow-up task & journal emission — `/document`, `/release-notes`, `/epics`, and `/implement` now persist out-of-scope / manual-step follow-ups at end-of-run.** Each command gains a terminal "Emit follow-up tasks" phase (after its Final Report) that filters the run's follow-up signals to those whose action lands *outside* the current change or needs a *manual human step* (files owned by other teams, Jira-vs-source implementation gaps, "paste release notes into Jira", "create these Epics in Jira manually", screenshots to upload), then persists them as durable Obsidian-Tasks `- [ ]` lines — with a `Journal.md` (or project `### Notes`) entry when an item needs more than a task line. A batch preview grouped by target file (`approve-all | select | cancel`) gates every write; nothing is written without one confirmation. In-scope items the report already tracks (deferred review BLOCKERs, skipped tests, in-draft TODOs) are deliberately excluded.
- **New shared reference `references/followup-emission.md`.** The single source of truth for the emitter: task-line format, Jira-key → project-file resolution (`P<NNNN> <slug>.md` → `## Work Items → ### Tasks`, else `Tasks.md # Irregular`), notes placement (project `### Notes` → `Journal.md`), stable-key dedupe, and the no-vault fallback ladder (`$VAULT_PATH` → the VI's `$SPECS_PATH` dir `<VI-dir>/dev-workflows/<KEY>-followups.md` → beside the imported Jira directory → report-only; never the cwd). **Self-contained** — no runtime dependency on the `obsidian-llm-wiki` plugin; it mirrors that plugin's `_shared/task-rules.md` + `vault-conventions.md` as upstream and adds journaling (which exists in neither plugin).

Additive only — existing phase behaviour, `jira-reader`, the reviewers, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; the follow-ups also remain in each command's Final Report (zero regression) and the phase never fails the run.

## [2.7.0] — 2026-07-09

### Changed

- **`/implement`, `/document`, `/epics`, and `/release-notes` now honor the shared front-end's `focus_key`.** Since the v2.5.0 foundation these four commands parsed the two-key `<VI> <Epic>` grammar but ignored the focus Epic (they resolved the VI and read the whole subtree). They now consume `focus_key`:
  - **`/implement`** is treated as an Epic-unit command: for a bare multi-Epic VI it renders the progress-aware Epic picker (done-predicate = the Epic's Jira status — done / in-progress / not-started, degrading to a plain list if the export carries no status), scopes the Jira read to the chosen Epic's subtree, and resolves specs from the nested per-Epic home. Each run targets **one** Epic — there is **no "Next Epic?" loop** (unlike `/specify`+`/design`), because code-writing is heavy and branchy.
  - **`/document`** (Jira mode) and **`/release-notes`** stay VI-level and gain no picker; when an explicit focus Epic is passed they scope their change-driven phases (diff summarisation, doc planning / release-note rendering) to that Epic's subtree, defaulting to whole-VI otherwise.
  - **`/epics`** stays VI-level (its partition analysis reads the whole VI); an explicit focus Epic is honored as a **refinement target** — Phase 6 re-drafts only that Epic's definition and Phase 7 reviews only that file (`epic-writer` unchanged).
- **Shared `references/jira-input-resolution.md` §Specs-resolution is now `focus_key`-aware.** With a focus Epic it prefers the nested per-Epic home `specifications/<VI>-<vslug>/<EPIC>-<eslug>/{specification.md,design.md}` (matched by Jira key-number, tolerating slug drift), falling back to the VI-flat layout when no nested Epic folder exists; with no focus Epic the VI-flat resolution is unchanged. This is the nested per-Epic path discovery `/implement` needed.

Single-key and directory inputs, and un-split-VI (0-Epic) behaviour, are unchanged; `jira-reader`, `/specify`, `/design`, the reviewers, and the format references are untouched.

## [2.6.0] — 2026-07-08

### Added

- **`/design` — Jira-driven engineering design authoring (Dev phase).** The developer take-over half of the PM→Dev pipeline: reads a merged `specification.md` from the specs repo's main branch, grounds strictly in the fully-mounted implementation code (a **hard** repo gate — any unmounted repo in the confirmed set stops the run until remounted, unlike `/specify`'s soft gate), and authors an engineering `design.md` through a relentless one-question-at-a-time grill that both **challenges** the spec (recording an `## Engineering review` section + `- [ ]` open questions back onto `specification.md`) and **designs** the implementation. A single complexity classification scales grill depth, `design.md` section-inclusion, and reviewer rigor together; a **tiered model gate** hard-stops SIGNIFICANT/HIGH-RISK work that is not running on Opus (the critical synthesis is inline, not a subagent). Consumes the shared front-end's `focus_key`; for a multi-Epic VI it renders the progress-aware Epic picker (○/◐/●, done-predicate `design.md` exists) enumerated from the specs repo, and offers a Next-Epic loop. Writes `design.md` **flat** in the per-Epic home `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` (durable/resumable via `_design-session.md` + `_design-glossary.md`, namespaced to coexist with `/specify`'s session files), gates on the new Opus `design-reviewer`, and offers a branch+PR handoff (`design/<EPIC>-<eslug>` / `design/<VI>-<vslug>`) to the specs repo's main for `/implement`. `design.md` open questions **hard-block** handoff (opposite of `specification.md`, where they are tolerated). New assets: `commands/design.md`, `references/design-format.md` (net-new format authority), `agents/design-reviewer.md` (Opus). `/design` uses the shared Jira-input front-end only to parse the grammar — it does not read Jira content (`jira-reader` is not used).
- **`/implement` refuses to implement a design doc with unresolved open questions.** A cross-command backstop for `/design`'s decision-completeness policy: when the primary description is a design doc (`design.md` / `*-design.md`) with unresolved `- [ ]` items, `/implement` stops (override-only, logged in the Phase 5 report). `specification.md`-level open questions remain exempt.

## [2.5.0] — 2026-07-08

### Added

- **VI-selector two-key grammar for the shared Jira-input front-end** (`references/jira-input-resolution.md`). `/implement`, `/document`, `/epics`, `/specify`, and `/release-notes` share a uniform way to point at one Epic inside a multi-Epic VI: `<VI> <Epic>` (both under `$VAULT_PATH/jira-products/`) or `<dir> <Epic>` (a jira-export directory plus an Epic key, no `$VAULT_PATH` needed). A single nested-Epic key alone now auto-resolves to its parent VI (Fallback E if the parent is ambiguous; Fallback D if the Epic isn't found). The resolver exposes a new nullable `focus_key` output field (the resolved Epic, or `null` for a bare VI / stand-alone item) and documents a reusable progress-aware Epic-picker pattern (○ not-started / ◐ in-progress / ● done) for commands that need to let the user choose among a VI's Epics. All five commands now accept the grammar and resolve `focus_key`, but only `/specify` acts on it this release (below) — `/implement`, `/document`, `/epics`, and `/release-notes` resolve the VI and ignore `focus_key` for now.
- **`/specify` resolves nested/bare Epic keys and writes per-Epic output paths.** Phase 0 now accepts a nested or stand-alone Epic key directly (previously only a VI key or directory worked) and, once an Epic is in focus, writes to the hyphen-delimited per-Epic path `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` — replacing the old flat `specifications/<KEY>_<slug>/` target, whose underscore delimiter mismatched the repo's hyphen convention and which had no per-Epic home (it collided with / duplicated the VI's own dir). The PR-handoff branch name follows suit: `spec/<EPIC>-<eslug>` (per-Epic) / `spec/<VI>-<vslug>` (broad VI-level) — replacing the old `spec/<KEY>_<slug>`.
- **`/specify` progress-aware Epic picker.** For a VI with two or more Epics and no Epic already selected, Phase 2 Step A now renders the shared picker (○/◐/●) before the full-depth read, so the interview scopes to one Epic's linked Stories/Sub-tasks instead of the whole VI. A single-Epic VI or a stand-alone top-level Epic skips the picker and auto-focuses; a broad VI-level spec remains available as an explicit choice. After finishing a per-Epic spec, `/specify` offers to loop back into the picker (Epic dropped from the actionable set) to author a sibling Epic's spec next.

## [2.4.0] — 2026-07-07

### Added

- **`/specify` — Jira- and code-grounded specification authoring (PM phase).** A grilling command that reads a Jira Epic/VI from exported markdown, lightly grounds in code (auto-derived repos, soft advisory gate), and authors an org-standard `specification.md` (problem → scope → user stories → acceptance criteria → test cases) through a relentless one-question-at-a-time interview — resolving open questions live and leaving genuinely unresolvable ones as `- [ ]`. Durable/resumable via `_session.md` + `_glossary.md`; a VI-without-Epics pre-flight; gates on the new Opus `spec-reviewer`; renders HTML; and offers a branch+PR handoff to the specs repo's main branch (`Published: no`) for the future `/design` dev take-over. New assets: `commands/specify.md`, `references/specification-format.md`, `agents/spec-reviewer.md`, `scripts/specification-to-html.py` (format/reviewer/renderer imported from mgd-specifications; grilling technique embedded — no runtime plugin dependency).

## [2.3.1] — 2026-07-02

### Fixed

- **Docs reflect the uniform routing doctrine.** The 10 mechanical agent descriptions and the plugin README's subagent table + summary no longer say those agents "inherit the session's model" (stale after v2.3.0). They now state each agent has no fixed model pin and its tier is assigned by the caller per the model-routing policy (mechanical → Sonnet, synthesis/review → Opus). The four Opus-pinned reviewers/planners remain marked explicitly.

## [2.3.0] — 2026-07-02

### Added

- **Per-step model routing for `/implement`, `/vuln`, `/upgrade`.** These commands now build the full §4 `model_routing` block at classification time and pin each subagent dispatch to a tier: mechanical steps (readers, scanners, `test-writer`/`test-baseliner`, `review-fixer`, and the `/vuln`/`/upgrade` coordinators) run on the §2.1 Sonnet chain, while judgment gates (`risk-planner`, `code-review`) keep their frontmatter Opus pins. `/vuln` and `/upgrade` pin at the orchestrator level; their coordinators' internal leaves inherit the pinned tier.

### Changed

- **Sonnet 5 is the Sonnet-tier primary.** The §2.1 detection chain and the §2 Opus-chain Sonnet fallback now lead with `claude-sonnet-5` (then `claude-sonnet-4-6` → `claude-sonnet-4-5`). Opus primaries (`claude-opus-4-8` …) and all review/planning-gate Opus pins are unchanged.

## [2.2.1] — 2026-07-02

### Fixed

- **`/epics` wording now reflects cwd-agnostic output.** Corrected prose that still asserted the Obsidian vault as the only output home (intro line, doc-maintenance dispatch, git-state report template) and normalized the "vault git is the user's responsibility" idiom to "git … responsibility" — accurate when Epics are drafted to `epic-drafts/<jira_key>/` beside an imported hierarchy without `$VAULT_PATH`.
- **`/release-notes` placeholder normalized.** Replaced the uppercase `<JIRA_KEY>` display token with the canonical `jira_key` (prose) / `<jira_key>` (report template), and dropped the now-redundant binding note.
- **Marketplace README command list refreshed.** Replaced the pre-B1 `/impl:*` names with the current surface: `/implement`, `/document`, `/docs-profile`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/api-guideline-reviewer`, `/guideline-reviewer`.

## [2.2.0] — 2026-07-02

### Added

- **`/epics` and `/release-notes` adopt the shared Jira-input front-end.** Both commands now accept the same grammar as `/implement` and `/document`: a **JiraID** (discovered under `$VAULT_PATH/jira-products/`) **or** an **imported-Jira directory** (the same exporter output rooted anywhere — works when `$VAULT_PATH` is unset). Input is resolved via `references/jira-input-resolution.md`, and `jira-reader` is invoked with `jira_export_root`.

### Changed

- **`/epics` is now cwd-agnostic** — it no longer requires the working directory to be inside `$VAULT_PATH`. Epic drafts are written to an absolute output directory: `$VAULT_PATH/jira-drafts/<VI-KEY>/`, or `<import-parent>/epic-drafts/<VI-KEY>/` when `$VAULT_PATH` is unset.
- **`/release-notes` always writes a file** — the draft (and any implementation-gaps report) goes to the vault project folder when `$VAULT_PATH` is set, or beside the imported directory when it is unset. Print-to-screen is a secondary option, never the default.

## [2.1.0] — 2026-06-29

### Added

- **Shared Jira-input resolution front-end** (`references/jira-input-resolution.md`). `/implement` and `/document` now share one input grammar: a **JiraID** (discovered under `$VAULT_PATH/jira-products/`), an **imported-Jira directory** (the same exporter output rooted anywhere — works when `$VAULT_PATH` is unset), or a **direct prompt/`@file`**. `/implement` gains JiraID discovery; `/document` gains directory input.
- **`SPECS_PATH`** env var (same rules as `VAULT_PATH`) — the deterministic source for a ticket's specifications at `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md`. Specs are **required (with override)** for `/implement` jira-driven runs and **additive** for `/document`.
- `jira-reader` accepts an additive `jira_export_root` input (an explicit ticket export directory); `/epics` and `/release-notes` keep using `vault_path` + `jira_key` unchanged.

### Changed

- The `jira-workitem-import` tool (https://github.com/ivan-gudak/jira-workitem-import) is now referenced as the source of the `jira-products/` export.

## [2.0.1] — 2026-06-28

### Changed

- **Internal phase renumber — documentation only, no behavior change.** Renumbered the `/document` (Jira mode) Phase 6 cluster to monotonic execution order — CDN image handoff `6.2`→`6.1`, branch setup `6.5`→`6.2` (its section now physically precedes the writer), write `6`→`6.3`, style check `6.7`→`6.4`, render verification `6.8`→`6.5` — and removed the execution-order note the old non-monotonic numbering required. Renumbered the `/epics` Dynatrace style-check phase `6.7`→`6.1` (the `/epics` Write phase stays `6`). Every step, gate, and agent dispatch is unchanged.

## [2.0.0] — 2026-06-28

### Changed (BREAKING)
- Renamed all `/impl:*` commands to top-level verbs: `/impl:code` → `/implement`; `/impl:jira:docs` → `/document`; `/impl:jira:epics` → `/epics`; `/impl:jira:release-notes` → `/release-notes`; `/impl:docs:profile` → `/docs-profile`.
- `/impl:docs` (one-shot doc editor) is **folded into `/document`** as direct mode — `/document <JiraID> [saas|managed]` runs the Jira pipeline; `/document @file` or `/document <free-text>` runs the one-shot edit. The standalone `/impl:docs` command is removed.
- The `/impl` dispatcher command is removed (no namespace left to dispatch).
- The context hook now matches the new verbs and routes `/document` by argument (JiraID → vault/repos context; free-text → silent).

### Added
- `references/escalation-rules.md` — the shared escalation `choices:` rules, resolving the previously-dangling "§15" references.

## [1.16.0] — 2026-06-28

### Changed
- `/impl:jira:docs` and `/impl:jira:epics`: the Phase 6 writers are extracted into dedicated write-only subagents (`doc-writer`, `epic-writer`) fed by a structured temp handoff file. `doc-writer` is pinned to the Opus reasoning chain (closes the docs writer gap on non-Opus sessions); `epic-writer` is pinned to the Sonnet detection chain for MODERATE runs (stops MODERATE Epic writing from running on an Opus session). Orchestrators commit (docs) or never commit (epics) as before; output is unchanged.
- `/impl:jira:docs` Phase 1.5 advisory narrowed to a context-window note (the synthesis and writing now run on Opus regardless of session).

### Added
- `/impl:jira:epics`: per-step model routing — `jira-reader`, `code-scanner`, `dt-style-checker`, `doc-fixer` pinned to the Sonnet detection chain; `epic-reviewer` keeps its Opus pin; a `model_routing` block + Phase 9 `### Model Routing` section.
- `classification.md` §9: delegated-writer routing rows, the advisory classification gate, and the code-scanner-no-synthesis refinement.

## [1.15.0] — 2026-06-28

### Added
- `/impl:jira:docs`: per-step model delegation. A `model_routing` block resolved at Phase 1.5 pins `doc-planner` (Phase 5.7) to the §2 Opus chain and the mechanical steps (`jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, Phase 8 maintenance) to the §2.1 Sonnet chain. `doc-reviewer` keeps its frontmatter Opus pin.
- A Phase 1.5 advisory recommends relaunching the whole run on Opus (orchestration + the 5.8/5.9 gates + the inline writer + a 1M context window) when the session is not on the Opus chain; a no-Opus-available path records the degradation.
- `references/model-routing/classification.md` §9 — the reusable per-step routing policy for multi-phase authoring pipelines (role→chain map, no-Opus rule, §8.3 reconciliation).

## [1.14.2] — 2026-06-28

### Fixed
- **`/impl:jira:docs` pipeline hardening (post-review).** A comprehensive 3a–3d pipeline review + this spec review found five cross-phase seams, now fixed: (I#1) a Phase 6 ordering note clarifying that Phase 6.5 branch-setup runs before the writer (full renumber deferred); (I#2) the downstream agent briefs and the write invariant now consume the resolved `docs_repo_path` rather than "cwd's git root", so a docs repo discovered outside cwd (or user-entered) is scanned/written correctly; (I#4) `/impl:docs:profile` now bases its branch on the repo's default branch (clean profile PR); (I#5) when `/impl:jira:docs` invokes profiling inline it passes `--inline`, and `/impl:docs:profile` then skips its branch-naming prompt and standalone PR-draft — one branch, one decision, one handoff; (I#6) a Phase 0 guard warns when an in-repo profile is not yet on the base branch (so the docs branch won't include it). No command behavior changed beyond I#4. (`§15` escalation cleanup + the monotonic phase renumber remain deferred to the namespace refactor.)

## [1.14.1] — 2026-06-28

### Fixed
- **README & `/impl` dispatcher accuracy (docs-only).** Corrected the stale slash-command counts (intro now reads eight workflow commands plus the `/impl` dispatcher; the classification sentence now names the five `/impl:*` commands that run per-task SIMPLE/MODERATE/SIGNIFICANT/HIGH-RISK classification and notes that `/impl:docs:profile` runs at a fixed SIGNIFICANT). Refreshed the `/impl:jira:docs` description to cover multi-space write safety, render verification (Phase 6.8), and finish & handoff (Phase 8.5 — squash, opt-in push, copy-paste PR draft). Added the missing `/impl:docs:profile` and `/impl:jira:release-notes` rows to the `/impl` dispatcher and a "which docs command?" note. Clarified that the `obsidian`/`plain_dir` write contexts are defensive guards (Phase 0 normally resolves a real docs repo). No command behavior changed.

## [1.14.0] — 2026-06-27

### Added
- **`references/finish-and-handoff.md`.** Single source of truth for `/impl:jira:docs` finish & handoff: the branch entering Phase 8.5, the contextual squash (profile-config commit vs merge-base), the opt-in push, host detection, and the copy-paste PR-draft template.
- **`commit_convention` profile field (default `"<JIRA-KEY> <summary>"`).** The squash commit-message format Phase 8.5 uses; inferred from `git log` / `CONTRIBUTING` when absent.

### Changed
- **`/impl:jira:docs` finish & handoff (Increment 3c).** Phase 6.5 now adopts the inline-profiling branch (renames it to the docs-branch convention and records the profile-config commit) instead of leaving the run on it. A new **Phase 8.5** squashes the run into clean history (keeping the profile-config commit separate when profiling ran), offers an opt-in `git push`, and writes a copy-paste PR draft to the vault project folder — host-aware (Bitbucket web UI / a `gh pr create` command the user may run), with a DO-NOT-MERGE banner when document-as-spec/skip-and-report gaps exist. Phase 9's git-state line reports the squash/push/draft outcome. The zero-external-API invariant is preserved — the plugin never creates a PR via an API.

## [1.13.0] — 2026-06-27

### Added
- **`references/dynatrace-docs/render-verification.md`.** Single source of truth for `/impl:jira:docs` render verification: build-vs-boot proof, sequential dev-server boot + readiness poll + stop, route derivation, delta-marker extraction + the cross-space invariant check, prerequisites best-effort/no-auto-apply, and graceful fallback to the pages-to-visit table.
- **`dev_servers.readiness_timeout_seconds` profile field (default 120).** Overridable per-repo; how long Phase 6.8 polls a booted dev server for readiness before falling back to the manual table.

### Changed
- **`/impl:jira:docs` Phase 6.8 — render verification (Increment 3b).** New phase after the style check: runs the profile's build command (gating, with the content→`doc-fixer` / environmental→ask split); offers an opt-in best-effort sequential dev-server smoke-check that asserts HTTP 200 per affected page and verifies the 3a invariant on cross-space pages (delta marker present in the target space's render, absent in the protected space's); always emits a "pages to visit" table. Results thread into the Phase 7 `doc-reviewer` invocation and a new Phase 9 `### Render verification` section. The `.docstack` shim is checked but never auto-applied.

## [1.12.0] — 2026-06-27

### Added
- **`references/dynatrace-docs/multi-space-writing.md`.** Single source of truth for writing dynatrace-docs across the SaaS and Managed spaces: shared-vs-single pages, the render-unchanged-≠-file-untouched invariant, the conditional-vs-override-copy strategies + heuristic, the shared-registries lock-step, and token correctness. Cited by `doc-planner` and `/impl:jira:docs`.

### Changed
- **`/impl:jira:docs` multi-space write safety (Increment 3a).** `doc-planner` now receives the resolved `profile` + `target_spaces`, classifies each target's `space_scope`/`rendered_in`, and recommends a per-target `write_strategy` (`conditional` | `override-copy` | `plain`). A new **Phase 5.9** presents those recommendations for approval/override. **Phase 6** consumes `profile` + `target_spaces` + the approved strategies to route each write to the correct space's `content_root`, edit shared pages in place with `{{#if project='…'}}` conditionals for small diffs, override-copy + `managed/docstack.jsonc` `ignore` for structural ones, keep `schema-ids.yml`/`schema-mappings.yml` in lock-step, and validate token correctness — so a `saas`/`managed`-constrained run never changes the other space's rendered output.

## [1.11.0] — 2026-06-26

### Added
- **`jira-reader` image attachment enumeration.** `jira-reader` now enumerates image attachments found in the Jira hierarchy and surfaces them as an `attachments[]` array in its output, making images available to downstream phases without manual discovery.

### Changed
- **`/impl:jira:docs` spec-tree as authoritative intended source (`doc-planner`).** Phase 5.7 now feeds the VI spec tree to `doc-planner` as the authoritative intended source, enabling 3-way `Jira|Spec|Code` discrepancy detection in Phase 5.8. `doc-planner` records `spec_phrasing` alongside `jira_phrasing` and `source_phrasing`; the new `spec-markdown` technique lets writers ground prose in the spec tree before cross-checking against Jira and source. `source-truth.md` updated to describe the spec-authoritative 3-way protocol.
- **`/impl:jira:docs` auto-discovers candidate images (Phase 5.6).** Before the writer phase, Phase 5.6 now automatically scans spec files for embedded images, enumerates Jira attachment images from `jira-reader`'s `attachments[]`, and falls back to a manual discovery prompt — producing a ranked candidate list the writer uses for screenshot placement.
- **`/impl:jira:docs` interactive CDN handoff with async fallback.** When `image_policy` is `cdn_upload_required`, the command now offers an interactive handoff step: the user can paste CDN links immediately and the command substitutes real URLs into the draft. When the user defers, the existing async fallback (stage screenshots to the persistent Obsidian project folder, surface in the Phase 9 report) is used unchanged.

## [1.10.0] — 2026-06-26

### Added
- **Built-in dynatrace-docs default profile (`references/dynatrace-docs/docs-profile.default.yml`).** Provides zero-config profile resolution for dynatrace-docs clones: when no in-repo `.dev-workflows/docs-profile.yml` exists and `is_dynatrace_docs` is true, Phase 0 loads this built-in instead of invoking on-demand profiling.

### Changed
- **`/impl:jira:docs` Phase 0 — preflight discovery.** Phase 0 now resolves the docs repo (cwd-preferred → search `/workspace` for a dynatrace-docs clone → ask), the profile (in-repo → built-in dynatrace-docs default → inline `/impl:docs:profile` on-demand), and the VI's specs dir under `${REPOS_PATH:-/workspace}` before Phase 1 clarification. A readiness table summarises all resolved items.
- **`/impl:jira:docs` Phase 4.5 — applicability determination.** New phase determines and confirms the applicable space(s) (`saas`, `managed`, or both) from the Jira hierarchy and resolved repos when no space constraint is passed; skips determination when `saas|managed` is supplied as the optional second argument.
- **`/impl:jira:docs` optional `saas|managed` space constraint.** The command now accepts `PRODUCT-NNNN [saas|managed]` as its signature. Passing `saas` or `managed` scopes the run to that space and leaves the other space's output unchanged; omitting it triggers Phase 4.5 auto-determination.

## [1.9.0] — 2026-06-25

### Added
- **`/impl:docs:profile` command.** Scans a docs repo and writes/refreshes `.dev-workflows/docs-profile.yml` + CLAUDE.md guidance as a reviewable PR; consumed by `/impl:jira:docs`.
- **model-routing SSOT §2.1 — mid-tier Sonnet chain.** Mid-tier Sonnet detection chain (`claude-sonnet-4-6` → `claude-sonnet-4-5`), pinned via `model:` so detection never inherits an Opus session.
- **`references/dynatrace-docs/docs-profile-schema.md`.** The docs-profile schema.

## [1.8.0] — 2026-06-25

### Added
- **`dynatrace-docs-frontmatter` skill.** Applies the dynatrace-docs frontmatter conventions when editing documentation pages under `dynatrace/_content/**` or `managed/_content/**`: prepends a `changelog:` entry dated today on changed existing pages (newest-first, ≤200 chars, with the period rule — complete sentence ends with a period, phrase does not), and unions the required managed-docs owners into `managed/_content/**` pages without removing existing owners. Cites two new reference files as source of truth.
- **`changelog-owners-reminder` hook (`PostToolUse`: `Edit|Write|MultiEdit`).** Warn-only `systemMessage` reminder when a dynatrace-docs content page is edited without a `changelog:` entry dated today, or (managed pages) without the required owners. Skips the changelog check for brand-new/untracked pages (first-publish rule). A `.sh` wrapper delegates to `.py` logic that reads the payload from stdin; always exits 0, never blocks.
- **`references/dynatrace-docs/changelog-guidelines.md`** — single source of truth for dynatrace-docs changelog writing rules (format, business-critical rationale, the period rule, worked examples) plus the managed-docs owners policy.
- **`references/dynatrace-docs/managed-owners.txt`** — managed-docs owner IDs unioned into `managed/_content/**` pages (read by the skill and the hook). Ships with `ivan.gudak` only; extend by adding one ID per line.

### Changed
- **Docs.** README gains a `## Skills` section and a Hooks-table row for `changelog-owners-reminder`; the dev-workflows hook count is now four (root `CLAUDE.md`, `plugin.json`, `marketplace.json`).

## [1.7.2] — 2026-06-17

### Added
- **`/impl:code` multi-source fan-out (Phase 1.7).** When the input includes more than one repo or any directory (spec file folder, Jira ticket folder), the task is floored at SIGNIFICANT (overridable at plan approval) and a Phase 1.7 fan-out scan runs before planning: `jira-reader` (for Jira folders) + per-repo `code-scanner` (single response, cap 4 concurrent) → synthesised summary fed to the planner. A referenced directory that is missing or unrecognised is surfaced, never silently skipped.
- **`references/model-routing/classification.md` §8 — large-input scan fan-out policy.** New section defines the input-shape trigger (multi-repo or any directory), the `jira-reader → parallel code-scanner (cap 4) → Opus synthesis` pattern, and the SIGNIFICANT floor it imposes. Single source of truth for all commands that dispatch fan-out scans.

### Changed
- **`code-scanner` agent generalised.** Now serves both `/impl:jira:epics` (theme-gap scan) and `/impl:code` (multi-source fan-out scan) callers; the agent description and handoff reference updated accordingly.

### Fixed
- **`/impl:code` reclassification fallback.** When the `risk-planner` returns a reclassification notice (task is actually SIMPLE/MODERATE), the command now correctly falls back to the standard-plan path instead of staying on the Opus path.
- **Planner `reason` field and diagram label.** Minor wording corrections in the Phase 2B plan presentation.

## [1.7.1] — 2026-06-16

### Fixed
- **`docs-style-checker` now chains Vale + `dt-style-checker` as complementary passes, not fallback-only.** Previously (1.7.0) `dt-style-checker` ran only when the primary linter failed — so whenever Vale ran successfully, the entire semantic / cross-page class of findings was silently dropped (engineer jargon like `latest-minus-one`, cross-page UI-label consistency, subject-verb agreement, plural/singular label mismatch). Vale and `dt-style-checker` are complementary, not redundant. Now, when the primary linter succeeds, `dt-style-checker` ALSO runs as a complementary pass and both finding sets are merged with line-level dedupe; fallback behaviour is preserved when the primary fails; the chain degrades to primary-only when `dt-style-guide` is not installed. Output **schema v3**: `linter`/`command` → `primary_linter`/`primary_command`, new `complementary_linter`/`complementary_command`/`complementary_error`, and each violation carries a `source: primary|complementary` tag. `/impl:jira:docs` Phase 6.7 and `/impl:docs` Phase 3.5 updated to describe the internal chain (the command no longer dispatches `dt-style-checker` separately). Ports Copilot dev-workflows v1.8.2.
- **`/impl:docs` phase-numbering contradiction fixed** — the "There is no Phase 3.5" disclaimer was stale after 1.7.0 added a mandatory Phase 3.5 style check.

## [1.7.0] — 2026-06-16

### Added
- **Source-truth discrepancy escalation (`references/source-truth.md`).** The docs flow now verifies user-visible claims against the shipped source and, when Jira and source disagree, escalates to the user (`/impl:jira:docs` Phase 5.8) instead of silently picking a side — document-as-source / document-as-jira (+ `<KEY>-implementation-gaps.md` bug-report draft + `intentional-discrepancy` marker) / skip-and-report. `doc-planner` records both `jira_phrasing` and `source_phrasing` (never auto-corrects); `doc-reviewer` gains a marker-aware Source-code accuracy dimension; the release-notes flow escalates the same way. Ports Copilot dev-workflows v1.7.0 + v1.8.0.

### Fixed
- **Style checks are robust and mandatory.** `docs-style-checker` falls back to the LLM-based `dt-style-checker` when the primary linter (Vale, etc.) errors or is missing — `NOT_CONFIGURED` only when nothing is available. `/impl:jira:docs` Phase 6.7 and a new `/impl:docs` Phase 3.5 are mandatory. `risk-planner` forbids recommending a skipped style check. (Copilot v1.7.0)
- **`doc-planner` accuracy rules.** No Jira key in changelog entries (commit carries traceability); no changelog-only frontmatter updates; cross-product parity touches are one-line pointers, never copied implementation detail. (Copilot v1.7.1 + v1.8.1)

## [1.6.0] — 2026-06-16

### Added
- **`/impl:jira:release-notes` command.** Standalone Jira-driven release-notes
  drafting: reads a VI (or any ticket) from the vault, optionally grounds the prose
  in merged PR diffs (reusing `$REPOS_PATH` resolution + `diff-summarizer`), and
  renders the dynatrace-docs authored release-notes body — a `{{#context}}` label,
  an `### title`, and customer-facing prose. The draft carries **no Jira IDs, no PR
  links, and no `{{#internal-note}}` block**; it is pasted into the ticket's Jira
  release-notes field, where the docs team's automation adds the metadata wrapper.
  Light `dt-style-checker` gate (optional; skipped if `dt-style-guide` is absent).
  Never branches, commits, or writes into the docs repo; the default destination is
  persistent.
- **`release-notes-writer` agent** + handoff reference — renders the
  `release_notes_block` (one entry per declared release version).

### Fixed
- **Docs flow no longer treats release notes as a repo write target.** `doc-planner`
  and `doc-location-finder` previously proposed "What's New / Release Notes" pages as
  documentation targets, but those pages are generated from Jira by automation — a
  manual write would be overwritten. Both now exclude release-notes / what's-new paths,
  and `/impl:jira:docs` defers release notes to `/impl:jira:release-notes`.

## [1.5.1] — 2026-06-16

### Fixed
- **`/impl:jira:docs` screenshot staging is now persistent.** When a docs repo's
  `image_policy` is `cdn_upload_required`, screenshots awaiting manual CDN upload
  were staged under `/tmp/<JIRA_KEY>-screenshots/`. `/tmp` is in-image and
  ephemeral, so the staged files were lost on container restart — before the user
  had uploaded them. Staging now targets the ticket's **persistent Obsidian project
  folder** under `$VAULT_PATH` (always host-mounted), resolved by the command as a
  directory under `$VAULT_PATH/Projects/` whose name starts with `<JIRA_KEY>` (its
  `Doc screenshots/` or `Attachments/` subfolder); when no project folder is found
  the command asks for a persistent directory. The command passes the resolved
  `screenshot_staging_dir` to `doc-planner`. Neither the docs repo (which may be a
  docker repo-volume, not on the host) nor `/tmp` is used. Affects `doc-planner` and
  the `/impl:jira:docs` Phase 1 resolution, Phase 6 writer step, Phase 9 report, and
  invariants.

## [1.5.0] — 2026-06-16

### Changed (breaking for orchestrators that hardcode `/repos/`)
- **`/impl:jira:*` repo discovery is now `$REPOS_PATH`-based.** The old fixed
  `<repos_base>/<slug>` directory lookup (default `/repos`) is replaced by a scan
  rooted at `$REPOS_PATH` (default `/workspace`; colon-separated list supported)
  that maps each PR's repo-URL slug to an absolute local clone by matching
  `git remote get-url origin`. Multiple clones of one upstream are disambiguated
  by the preference order `<slug>-repo` > `<slug>_repo` > `<slug>_fast` >
  alphabetically last. This matches the container's `/workspace` umbrella layout
  (every repo and the Obsidian vault mounted under `/workspace`).
- **`diff-summarizer` / `code-scanner` inputs.** `repo_path` is now any absolute
  path (no longer assumed `/repos/<name>`), and a new optional `repo_url_slug`
  enables an upstream cross-check — on mismatch the agent returns `REPO_MISSING`
  instead of summarising the wrong repo.
- **`preload-context.sh`.** Emits `repos_path: ${REPOS_PATH:-/workspace}`
  (previously `repos_base: ${REPOS_BASE:-/repos}`).

### Migration notes
- If your clones still live under `/repos`, set `REPOS_PATH=/repos` to preserve
  the old base. The slug→clone match by `git remote` works regardless of base.

## [1.4.0] — 2026-06-15

### Changed
- **Subagent dispatch via `subagent_type`** — agents are now invoked as `dev-workflows:<agent>` (e.g. `dev-workflows:risk-planner`); Claude Code loads each agent's file body as its system prompt and honours its `model:` frontmatter. No caller-side `model` override or file-path read is needed. Supersedes the earlier `general-purpose` + `"Read and adopt ~/.claude/agents/<name>.md"` workaround.
- **Bundled reference paths via `${CLAUDE_PLUGIN_ROOT}`** — agent and skill bodies (and hook configs) now reference vendored docs via `${CLAUDE_PLUGIN_ROOT}/references/...` instead of hardcoded absolute data-directory paths.
- **`model-routing` skill** — new skill for command-level classification; slash commands invoke it to load `references/model-routing/classification.md` (skills can resolve `${CLAUDE_PLUGIN_ROOT}`, commands cannot).
- **Model fallback chain refreshed** — Opus 4.8 / Sonnet 4.6 with hyphenated model IDs throughout `references/model-routing/classification.md`.
- **Guideline commands (`/api-guideline-reviewer`, `/guideline-reviewer`) now dispatch their review in a subagent** — consistent with the rest of the command set.
- **`preload-context.sh` cosmetic fix** — the model-routing path hint now reads "invoke the model-routing skill" instead of the old `~/.claude/plugins/data/...` absolute path.

## [1.3.0] — 2026-05-15

### Changed
- **Cross-platform naming sync with Copilot CLI plugin (v1.3.0).**
  - Renamed `code-diff-summarizer` agent → `diff-summarizer` (aligns with
    Copilot CLI naming; all cross-references updated repo-wide).
  - Renamed `test-baseline` agent → `test-baseliner` (aligns with Copilot
    CLI naming; all cross-references updated repo-wide including handoff
    docs, orchestrator commands, and design specs).
  - Version numbers now track 1:1 between Claude Code and Copilot CLI
    plugin repos. Previous version drift: Claude 1.2.1 / Copilot 1.2.1.

## [1.2.1] — 2026-05-15

### Added
- **`upgrade-planner` agent.** Dedicated sub-agent for analysing a project and
  producing a versioned, step-by-step upgrade plan with risk annotations.
- **`upgrade-executor` agent.** Dedicated sub-agent that executes an approved
  upgrade plan step-by-step, running builds/tests after each step.
- **`vuln-research` agent.** Dedicated sub-agent for vulnerability triage —
  reads advisories, assesses exploitability, and recommends fix vs mitigate.
- **`vuln-fixer` agent.** Dedicated sub-agent that applies vulnerability
  remediation (dependency bumps, code patches) and verifies the fix.
- **Nine handoff reference docs** under `references/handoff/` for sub-agents
  that receive delegated work: code-scanner, diff-summarizer,
  impl-maintenance, jira-reader, test-baseliner, upgrade-executor,
  upgrade-planner, vuln-fixer, vuln-research.

### Changed
- `/upgrade` command refactored to delegate planning and execution to the new
  `upgrade-planner` and `upgrade-executor` agents via the `task` tool.
- `/vuln` command refactored to delegate research and remediation to the new
  `vuln-research` and `vuln-fixer` agents via the `task` tool.
- `CLAUDE.md` expanded from 60 → 204 lines: added skill taxonomy table,
  orchestrator/sub-agent relationship diagram, model-routing contract,
  key invariants, test requirements, update procedures, and guardrails.

## [1.2.0] — 2026-05-15

### Added
- **`guideline-reviewer` agent.** Reviews code and UI for compliance with
  Dynatrace Experience Standards (GUIDElines). Covers component usage
  (AppHeader, DataTable, FilterField, etc.), accessibility/WCAG compliance,
  terminology, settings patterns, and permissions. Reference docs in
  `references/guidelines/`.
- **`api-guideline-reviewer` agent.** Reviews OpenAPI specification files
  against Dynatrace REST API and IAM permission naming guidelines. Two-pass
  review (comprehensive analysis + detailed verification) checking version
  consistency, required elements, naming conventions, IAM scope format,
  HTTP status codes, and schema composition. Reference docs in
  `references/api-guidelines/` (REST API guidelines, permission guidelines,
  and an OpenAPI template).
- **`check_guidelines.py` script** in `references/guidelines/` — automated
  checklist generator for GUIDEline reviews.
- **`checklist-template.md`** in `references/guidelines/` — structured
  review template.

### Changed
- `plugin.json` keywords expanded.
- `marketplace.json` description updated (15 → 17 agents).
- **Model routing reference (`references/model-routing/classification.md`)
  expanded** from 92 to 265 lines — now includes model fallback chain,
  `model_routing` handoff block format, `task` tool delegation pattern,
  mandatory code-review checklist verdicts, and reporting section (synced
  from Copilot CLI port).

## [1.1.0] — 2026-05-10

`plugin.json` and `marketplace.json` declare `1.1.0`. The work landed across seven increments:

- **Increment A** — scaffolding (commit `25c73fc`)
- **Increment B** — `/impl:code` + `test-writer` agent (commit `29a727f`)
- **Increment C** — `/impl:docs` one-shot doc editing (commit `052e772`)
- **Increment D** — `/impl:jira:docs` + `/impl:jira:epics` + 9 agents (commit `e785adb`)
- **Increment E** — hook regex, README refresh, marketplace description refresh
- **Increment F** — per-command routing in `preload-context.sh` per spec §3 table (commit `4e18081`)
- **Increment G** — `/impl` repurposed as a dispatcher (breaking for 1.0.x users); verbatim-copy maintenance tax eliminated (this commit)

### Breaking changes
- **`/impl <description>` no longer runs the code-implementation workflow** (Increment G). In 1.0.x, `/impl <description>` was the canonical invocation for the full code workflow. In 1.1.0, `/impl` is a **dispatcher**: it prints a help message listing the `/impl:*` variants plus `/vuln` / `/upgrade`, then stops. If you have muscle-memory invocations like `/impl add rate limiting`, re-run them as `/impl:code add rate limiting` — the workflow body is unchanged (it lives in `commands/impl/code.md` and is registered as the slash command `/impl:code`). No aliasing; the redirect is a printed message only. Mid-1.1.0, an Increment-A iteration briefly shipped `commands/impl.md` as a verbatim copy of `commands/impl/code.md` with a `<!-- KEEP IN SYNC -->` marker — that approach is **not** what 1.1.0 ultimately ships; Increment G replaced it with the dispatcher to remove ~27 KB of duplication and eliminate the drift risk the marker was trying to manage.

### Added
- **Namespaced command layout.** New directory `commands/impl/` with sub-files `code.md`, `docs.md`, `jira/docs.md`, `jira/epics.md` — these become the slash commands `/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics` via Claude Code's directory-to-namespace convention.
- **`/impl:code` full workflow (Increment B).** `commands/impl/code.md` is the canonical code-implementation command: classify → optional Opus planning → feature branch → **capture test baseline (new Pre-Phase 3.5)** → implement → **test-writing + regression verification (new Phase 3.5)** → optional Opus review → Phase 4 maintenance → Phase 5 report. Same structure as the pre-split `/impl`, with the two new test-related phases inserted and three new invariants added (`ALWAYS capture baseline`, `NEVER skip Phase 3.5`, `AFTER two fix-loop attempts, stop and surface`).
- **`commands/impl.md` is now a dispatcher** (final shape after Increment G). Prints a help page listing the four `/impl:*` variants (`/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`), a Related-commands section for `/vuln` and `/upgrade`, and a migration note pointing 1.0.x users at `/impl:code`. Does not execute any workflow — no classification, no branching, no agents, no git. The file is ~40 lines instead of ~27 KB; no "keep in sync" marker is needed because there is no longer a shadow copy of `commands/impl/code.md`. See the **Breaking changes** section above for the 1.0.x impact.
- **`agents/test-writer.md` (Increment B).** Default-model agent that writes tests for new or changed behaviour based on a diff. Mirrors `test-baseliner`'s framework detection and returns `Framework: not detected` immediately if none matches, so the caller can ask the user. Does NOT run tests — the caller runs `test-baseliner` verify separately. Hard rules: never retrofit tests for unchanged code, never invent a framework the project doesn't already use, never modify production code.
- **`/impl:docs` full workflow (Increment C).** `commands/impl/docs.md` is the one-shot doc-editing command: classify (always SIMPLE or MODERATE — redirects to `/impl:jira:docs` / `/impl:jira:epics` if the task turns out to be SIGNIFICANT on inspection) → plan with the `/impl:code`-style repo-exploration subagent → implement → validation checks (link integrity, heading structure, frontmatter parse, broken `[[wikilinks]]`) → Phase 4 maintenance → Phase 5 report. No branch, no baseline, no tests, no Opus, no commit — the user manages git manually. Phase 4 handoff sets `Change type: docs` and `Command run: /impl:docs`. Explicit invariants block all five "never" axes.
- **`/impl:jira:docs` full workflow (Increment D).** `commands/impl/jira/docs.md` is the Jira-driven feature-documentation command: Phase 0 vault + docs-repo detection → Phase 1 PR-status filter / refresh policy / `<repos_base>` / optional screenshot paths → Phase 1.5 classification (SIGNIFICANT; Jira read *is* the plan so no Opus planning) → Phase 2 plan + approval → Phase 3 `jira-reader` depth `full` → Phase 4 repo resolution (escalate missing per §15) → Phase 5 parallel `diff-summarizer` (batches of 4; aggregate "All PRs unresolved" gate) → Phase 5.5 `doc-location-finder` (3 status branches) → Phase 5.7 `doc-planner` (gap dispositions: ask-user / mark-TODO / skip-with-note) → Phase 6 writer (main command, with three-branch `image_policy` screenshot placement — `local` / `cdn_upload_required` / `ambiguous`) → Phase 6.5 branch setup (conditional on `docs_repo` context + user opt-in at plan approval) → Phase 6.7 `docs-style-checker` + `doc-fixer` + re-lint → Phase 7 `doc-reviewer` Opus gate (1-fix-1-rereview cap; per-BLOCKER escalation) → Phase 8 four maintenance agents in a single message → Phase 9 final report including `### Screenshots to upload manually` when any target used `cdn_upload_required`. Phase 8 handoff sets `Change type: docs` and `Command run: /impl:jira:docs`. Invariants from spec §6 preserved verbatim.
- **`/impl:jira:epics` full workflow (Increment D).** `commands/impl/jira/epics.md` is the Jira-driven Epic-writing command: Phase 0 vault-only context check (refuses to run outside `$VAULT_PATH`) → Phase 1 output dir / code-scan on-off / refresh policy / `<repos_base>` → Phase 1.5 classification (MODERATE; no Opus planning) → Phase 2 plan + approval → Phase 3 `jira-reader` depth `vi-plus-epics` (VI + every Epic linked to it, skipping Stories / Sub-tasks / Research / RFA) → Phase 4 conditional repo resolution (auto-derived from sibling Epics' PR URLs or manual) → Phase 5 conditional parallel `code-scanner` (batches of 4; scanner defaults `pull: true`, deliberately asymmetric with `diff-summarizer`'s `pull: false`) → Phase 6 writer (one `.md` per Epic with `## Goal` / `## Business value` / `## Scope (in / out)` / `## Acceptance criteria` / `## Dependencies` / `## Suggested stories` / `## References`) → Phase 7 `epic-reviewer` Opus gate (1-fix-1-rereview cap; "Defer" appends a `## Refinement notes` section to the draft) → Phase 8 four maintenance agents → Phase 9 final report. NEVER branches, NEVER commits, NEVER writes inside `jira-products/` or `_archive/`, NEVER writes outside `$VAULT_PATH`, NEVER runs `docs-style-checker` (enforced by absence of a Phase 6.7). Phase 8 handoff sets `Change type: docs` and `Command run: /impl:jira:epics`.
- **Nine new agents (Increment D).** All declare `tools:` as YAML arrays matching the existing in-repo style (`risk-planner`, `code-review`, `test-writer`).
  - **`agents/jira-reader.md` (§12)** — reads the pre-exported Jira markdown hierarchy under `$VAULT_PATH/jira-products/<JIRA_KEY>/`; three depths (`full` / `vi-plus-epics` / `vi-only`). Output: `value_increment` + `linked_items` + `pull_requests` + `themes`. Parses the Jira-to-Obsidian exporter's two-line-per-PR bulleted format with backticked branch names and a Unicode `→` arrow (not ASCII `->`). Three host categories recognised (`github_cloud`, `bitbucket_cloud`, `bitbucket_server`); `bitbucket_server` detected by the substring rule (hostname contains `bitbucket` and is not `bitbucket.org`), never a hardcoded domain. Inherits the session's model.
  - **`agents/doc-fixer.md` (§10)** — shared between `/impl:jira:docs` and `/impl:jira:epics`. Applies BLOCKER / MAJOR fixes from a `doc-reviewer`, `epic-reviewer`, or `docs-style-checker` output. Returns a `Fix Report` with the same `Stop condition flag` contract as `review-fixer`. Doc-type-agnostic because the finding schema is shared. Inherits the session's model.
  - **`agents/diff-summarizer.md` (§13)** — resolves a single repo's PR diffs and returns a doc-focused summary. Host-aware resolver: `gh` CLI for `github_cloud` (when installed + authenticated), local-git Strategies 1–4 for the rest (including GitHub fallback). Strategy 1: Bitbucket Server `refs/pull-requests/*` (usually absent). Strategy 2: branch search (0 or 2+ matches fall through silently). Strategy 3: merge-commit grep (`[Pp]ull[ _-]?[Rr]equest[ _-]?#?<pr_id>\b`). Strategy 4: cross-hierarchy Jira-key commit grep (last resort; summary MUST carry the "reconstructed from commit — may not exactly correspond" caveat). Statuses: `OK` / `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED` / `NO_PRS_RESOLVED` / `PARTIAL`. `refresh.pull` defaults to `false`. Inherits the session's model.
  - **`agents/doc-location-finder.md` (§10a)** — finds write target(s) in a docs repository. Heuristic + grep scoring across the detected docs-tree root(s); three placement kinds (`extend-existing` / `new-page-in-existing-section` / `new-section`). Statuses: `OK` / `LOW_CONFIDENCE` (with `confidence_notes`) / `EMPTY`. Never writes. Inherits the session's model.
  - **`agents/doc-planner.md` (§10b)** — synthesises the documentation checklist the writer follows and `doc-reviewer` checks against. Detects the repo's `image_policy` by sampling sibling / ancestor markdown pages: `local` (copy screenshots to `<page-dir>/img/`), `cdn_upload_required` (stage under `/tmp/<JIRA_KEY>-screenshots/` — NEVER inside the repo — and surface in Phase 9), or `ambiguous` (writer prompts the user at Phase 6). Per-page YAML frontmatter updates (including the mandatory `changelog:` append), snippet reuse / extract, cross-links, and gap dispositions. Inherits the session's model.
  - **`agents/docs-style-checker.md` (§10c)** — runs the repo's project-configured prose linter on files written in Phase 6 and normalises output into the shared finding schema. Detection order: Vale via `.vale.ini` → `package.json` `*:lint` / `lint:*` script → `.markdownlint.json(c)` / `.remarkrc*` → `NOT_CONFIGURED`. Severity mapping: `error` → MAJOR, `warning` → MINOR, `suggestion` → NIT. 2-minute cap. Never promotes linter severity. Inherits the session's model.
  - **`agents/doc-reviewer.md` (§9, Opus)** — reviews product documentation written by `/impl:jira:docs`. Eleven dimensions: factual correctness, completeness vs plan, coverage, audience fit, structural integrity, YAML frontmatter, screenshots (both `image_policy` branches), snippets, actionability, source traceability, style-check follow-through (from `docs-style-checker`). Verdict: PASS / PASS WITH RECOMMENDATIONS / BLOCK. `model: opus` declared in frontmatter and `model: "opus"` passed on the caller's Agent call (belt-and-braces, mirroring `risk-planner` / `code-review`).
  - **`agents/code-scanner.md` (§14)** — scans a single code repo for existing capabilities and gaps relative to a set of themes. Pure filesystem search (grep / glob / read); no HTTPS. `refresh.pull` defaults to `true` (capability scans target the default-branch tip — deliberately asymmetric with `diff-summarizer`). Per-theme 30-second budget; themes that can't be scanned get `classification: error` + reason and do NOT abort the whole scan. Statuses: `OK` / `PARTIAL` / `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED` / `EMPTY`. Inherits the session's model.
  - **`agents/epic-reviewer.md` (§9b, Opus)** — reviews Epic drafts written by `/impl:jira:epics`. Nine dimensions: goal clarity, business value, scope (in / out), acceptance criteria (testable), dependencies, suggested stories, non-duplication (BLOCKER when undetected; cross-checks against `jira-reader` `linked_items` filtered to `type == Epic`), references (code paths must match `code-scanner` `evidence.path` when that output is provided), structural integrity. Never treats the absence of a `code-scanner` output as a finding — the user may have opted out of code examination. `model: opus` in frontmatter + `model: "opus"` on the caller's Agent call.

### Changed
- **`agents/impl-maintenance.md` input / output enums.** The Inputs section now requires a `Command run:` field (one of `/impl`, `/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`, `/vuln`, `/upgrade`); missing values default to `/impl:code` with a note in the report. The "Command workflow improvements" output enum broadened to match, so maintenance suggestions from the three new Jira/docs commands are scoped to the right command variant.
- **`commands/vuln.md` and `commands/upgrade.md` session handoffs.** Both now pass `Command run: /vuln` and `Command run: /upgrade` respectively to `impl-maintenance`. Without this, the agent would default to `/impl:code` and misattribute any `/vuln` or `/upgrade` suggestions — a silent regression the spec's Wave 6 W6-m2 + §3 update implied but didn't explicitly call out for the two pre-existing commands.
- **`commands/impl/code.md` Phase 4 change summary block now includes `Change type: code`** (and a matching invariant). Aligns with `/impl:docs` (`Change type: docs`) and the two new Jira commands (both `docs`). The field is a scoping hint for the Documentation / Knowledge / Instructions maintenance agents — their prompts already reference the change summary block, so no agent prompt changes are needed.
- **`hooks/preload-context.sh` regex (Increment E).** Replaced `^/(impl|vuln|upgrade)[[:space:]]+[^[:space:]-]` with `^/(impl(:(code|docs|jira(:(docs|epics))?))?|vuln|upgrade)[[:space:]]+[^[:space:]-]` so `/impl:code`, `/impl:docs`, `/impl:jira:docs`, and `/impl:jira:epics` now trigger context injection. The normative regex is defined in spec §3 and verified against a 28-case matrix. Bare `/impl:jira foo` also matches — the `:(docs|epics)` sub-namespace is optional by design (over-match is preferable to missing a valid invocation). Header comment updated to list all covered commands.
- **`hooks/preload-context.sh` per-command routing (Increment F).** After the regex match the hook now reads `${BASH_REMATCH[1]}` and routes per the spec §3 table: `/impl`, `/impl:code`, `/vuln`, `/upgrade` get the full block (model-routing reminder + git status + recent commits + small-repo directory listing); `/impl:jira:docs` and `/impl:jira:epics` get a `Jira workflow` header with `VAULT_PATH` (or an unset-note fallback), a `repos_base` default (`${REPOS_BASE:-/repos}`), and `git branch --show-current` only when cwd is inside a git repo — no model-routing, no full status/log, no directory listing; `/impl:docs` exits silently (spec: "None — user manages git manually; model-routing is not triggered"). Bare `/impl:jira foo` (spec-intentional over-match) is routed to the Jira branch. Verified with a 10-assertion stdin harness covering all four routing paths plus noise.
- **`hooks/preload-context.sh` — `/impl` moved to silent branch (Increment G).** Follows the dispatcher change. `/impl <args>` now prints help and stops, so injecting the full git context + model-routing reminder would be pure noise before a help screen. `/impl:code`, `/vuln`, `/upgrade` continue to get the full context; `/impl:jira:docs` / `/impl:jira:epics` continue to get the Jira context; `/impl` joins `/impl:docs` in the silent branch. This is a minor deviation from spec §3's "`/impl` (alias) → Full" row, justified by the alias no longer existing; the spec table is superseded for the `/impl` row by Increment G.
- **`agents/impl-maintenance.md` — `/impl` removed from the live Command-run enum (Increment G).** The Inputs section now lists six live values (`/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`, `/vuln`, `/upgrade`). For replay compatibility with archived 1.0.x handoffs, the literal legacy value `/impl` is still accepted on input and internally mapped to `/impl:code` with a note in the report. The "Command workflow improvements" output enum drops `/impl` entirely — the agent will never suggest changes against a command that no longer runs a workflow.
- **`commands/impl/code.md` Phase 4 handoff (Increment G).** Dropped the now-stale parenthetical on the `Command run: /impl:code` line that explained the "`/impl` alias is a transport detail". The alias is gone; no explanation is needed.
- **`README.md` refresh (Increment E).** Rewritten to document the final 1.1.0 shape: dropped the "1.1.0 in progress" banner; rebuilt the Commands section as a 5-row table for the `/impl` family plus a secondary 2-row table for `/vuln` and `/upgrade`; rebuilt the Agents section as 15 rows with a Model column (Opus for `risk-planner`, `code-review`, `doc-reviewer`, `epic-reviewer`; `inherits` for the other 11); added an Environment prerequisites section covering `gh auth login`, optional `vale`, and the recommended [ihudak/ai-containers](https://github.com/ihudak/ai-containers) environment (per spec §17); updated the Hooks table to list the seven command shapes the matcher now covers.
- **`.claude-plugin/marketplace.json` dev-workflows description (Increment E).** Refreshed from "Three slash commands (/impl, /vuln, /upgrade) … five reusable subagents … three notification hooks" to name all five `/impl`-family commands plus `/vuln` and `/upgrade`, list all fifteen subagents, and describe the three notification / context hooks. `version` field unchanged (1.1.0).

Design spec: `docs/superpowers/specs/2026-04-30-impl-split-and-test-writing-design.md`.
Review history: `docs/superpowers/specs/2026-05-08-impl-split-and-test-kiro-review.md` (waves 1–7).

---

## Pre-plugin-split history (prior monorepo)

The sections below describe the original [`ihudak-claude-plugins`](https://github.com/ihudak/ihudak-claude-plugins) monorepo from which this plugin was extracted. They reference infrastructure that no longer applies to the standalone plugin — root-level `install.sh` / `uninstall.sh` / `install.ps1`, `plugins/workflow-tools/`, `tests/smoke.sh`, and `~/.claude/settings.json` hook merging. Retained as provenance; not part of the **dev-workflows** plugin's own version history.

### [Unreleased] (pre-plugin-split)

#### Added
- **Model routing across `/impl`, `/vuln`, `/upgrade`.** Every command now classifies the task as `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or `HIGH-RISK` before planning. `SIMPLE` / `MODERATE` continue on the currently selected model. `SIGNIFICANT` / `HIGH-RISK` route planning and post-implementation review through Opus and gate the test run on the review verdict.
- **`agents/risk-planner.md`** — Opus-backed risk-weighted planner system prompt. Returns a structured plan with explicit security, migration, API-stability, concurrency, dependency, rollback, and test-adequacy sections. Refuses to run without a classification. Includes a re-classification escape hatch: if the task turns out to be `SIMPLE` / `MODERATE` on inspection, the planner returns a `### Re-classification` section instead of the full plan and the caller falls back to the non-Opus path.
- **`agents/code-review.md`** — Opus-backed post-implementation reviewer system prompt. Checks eight dimensions (correctness, security, architecture, edge cases, migration risks, dependency risks, test adequacy, rollback). Returns `PASS` / `PASS WITH RECOMMENDATIONS` / `BLOCK`. `BLOCK` gates the test run. Same re-classification escape hatch.
- **`agents/test-baseliner.md`** — moved from `plugins/workflow-tools/` to the repo's top-level `agents/`. Same behaviour, now installed at `~/.claude/agents/test-baseliner.md` as a user-level subagent.
- **`agents/review-fixer.md`** — default-model agent that auto-fixes BLOCKER and MAJOR findings from a code-review report, deferring findings that require design judgment, migration sequencing, or cross-cutting test strategy. Returns a structured fix report with a `Stop condition flag` so callers know whether to re-review. Wired into all three commands' BLOCK and PASS-WITH-RECOMMENDATIONS branches.
- **`agents/impl-maintenance.md`** — default-model suggest-only post-session analyst. Reads the session handoff, scans existing rules/hooks/agents, returns a structured Lessons Learned report (CLAUDE.md rules, hooks, reference doc gaps, new agent suggestions, command workflow improvements). Does not write files.
- **`references/model-routing/classification.md`** — single source of truth for the four complexity levels, the triggers, the routing rules, and the eight review dimensions. All three commands link to it.
- **`tests/smoke.sh`** — install → uninstall → install smoke test in a throwaway `HOME`. 54 assertions. Covers full install, idempotent re-run, subtractive `--no-hooks`, `--no-plugin` rejection (the flag is retired), `uninstall.sh`, round-trip re-install, legacy `plugins/workflow-tools` cleanup, JSON validity, and agent-file frontmatter validation.
- **`uninstall.ps1`** — native Windows uninstaller (PowerShell). Mirrors `uninstall.sh`: removes managed symlinks/copies and strips hook entries from `settings.json` if Python is available.
- **`.gitignore`** — added `settings.local.json`, `settings-local.json`, `.claude/settings.local.json` to prevent accidental commit of Claude Code machine-specific overrides.
- **`test-baseliner.md` verify mode** — second mode alongside `capture`: re-runs tests, diffs against a prior baseline, returns a structured regression report (regressions, missing-from-run, newly fixed, new failures, current snapshot for chaining). All three commands now use verify mode for post-fix comparisons.
- **Feature-branch pre-step in `/impl`, `/vuln`, `/upgrade`** — clean-tree check (stash/proceed/cancel), branch-convention detection, slug generation, HEAD context check, `git checkout -b` BEFORE any file is written. Branch naming: `feat/<slug>` for impl, `chore/upgrade-<component>-to-<ver>` for upgrade, `fix/[JIRA-]CVE-XXXX-XXXXX` for vuln.
- **Ruby/Bundler section in `references/fix-vuln/build-systems.md`** and **PHP/Composer section in `references/upgrade/ecosystems.md`** — expand ecosystem coverage to match `/vuln` Detect agent scan list.

#### Changed in commands
- **`/impl`** — new Phase 1.5 classification step; for `SIGNIFICANT` / `HIGH-RISK`, planning is delegated to `risk-planner` (Opus) and the post-implementation `code-review` (Opus) gates the test run. Implementation itself stays on the currently selected model or Sonnet — Opus is reserved for planning and review. Phases 4 and 5 include the classification and the review verdict. Phase 2B "Revise" re-sends the full risk-planner brief (the planner refuses partial briefs).
- **`/vuln`** — step 5 classifies each CVE on the actual change required (same-major patch/minor bump → `MODERATE`; major bump or API-break or security-sensitive code path → `SIGNIFICANT` / `HIGH-RISK`). `MODERATE` keeps the existing flow; `SIGNIFICANT` / `HIGH-RISK` delegate planning to Opus, review the fix with Opus, and gate tests on the verdict. Classification is included in the commit message and PR body. The risk-planner brief no longer overstates the inputs — it passes declaration paths from the Detect agent and lets the planner do its own usage-site grep.
- **`/upgrade`** — Phase 1 step 5 classifies each component. `MODERATE` components follow the existing apply → build → test path. `SIGNIFICANT` / `HIGH-RISK` components plan with Opus (Phase 1 step 8) and get an Opus review before build/test (Phase 2 step 6). Summary table gains `Class` and `Review` columns. Same brief-correctness fix as `/vuln` — the brief passes inventory paths + Agent A's compat output and delegates usage-site scanning to the planner.

#### Changed in hooks
- **`preload-context.sh`** — injects a one-line model-routing reminder before the existing git context for `/impl`, `/vuln`, `/upgrade`. Points at `references/model-routing/classification.md` so the rules are one read away. Regex tightened to require at least one non-whitespace, non-hyphen argument so bare `/impl` or `/impl --help` no longer triggers a context injection. Directory listing now gated to repos with ≤30 root entries — large repos no longer leak the listing into context.

#### Changed in installers / docs
- **`install.sh --no-hooks` is subtractive**, not just a skip-flag. It actively removes previously-installed hook symlinks and strips matching entries from `settings.json` so the post-flag state matches what users expect.
- **`uninstall.sh` and `uninstall.ps1` symlink matching tightened** — require a path-segment boundary (`/claude-config/` rather than a loose substring) so unrelated paths like `claude-config-backup` can't be matched.
- **`install.sh` / `install.ps1` legacy-plugin cleanup** — on upgrade from a pre-restructure install, both installers remove any leftover `~/.claude/plugins/workflow-tools` symlink and drop the empty `~/.claude/plugins/` parent if nothing else lives there.
- **`README.md`** — surfaces the Windows installation path from the main Install section; adds the native Windows uninstall command and update workflow; documents the new `Class` / `Review` columns in the `/upgrade` example table; new "Subagents" section explaining the `general-purpose` + `model: "opus"` invocation pattern; replaces "commands + plugin" framing with "commands + agents".

#### Fixed
- **Subagent invocation pattern: `general-purpose` + `model` override.** Earlier iterations of this release tried two layouts that did not actually register the subagents — `plugins/workflow-tools/` (which requires marketplace registration + `installed_plugins.json` + `enabledPlugins`, not satisfied by a local symlink) and a user-level `agents/*.md` install (which requires a session restart to be discovered). Both produced static-correctness wins but a no-op routing in the installing session. The three commands now invoke the agents via `Agent(subagent_type: "general-purpose", model: "opus", prompt: "Read and adopt ~/.claude/agents/<name>.md, then [brief]")`. The `model` argument on the `Agent` tool itself forces Opus for `risk-planner` / `code-review` regardless of discovery; `test-baseliner` omits the override and inherits the session's model. Agent files are still installed at `~/.claude/agents/` so a future Claude Code release with reliable user-agent discovery can invoke them directly with no further changes. Verified empirically in-session. Removes the `--no-plugin` installer flag (the agents are required by `/vuln`, `/upgrade`, and the Opus-gated `/impl` flow — there is no opt-out).
- **`agents/risk-planner.md` and `agents/code-review.md` cite classification rules by absolute path** (`~/.claude/claude-config/references/model-routing/classification.md`). The agents' working directory is the caller's project, not this repo, so relative paths wouldn't resolve.
- **Classification file-count threshold made exclusive** — was `more than 3-5` on SIGNIFICANT and `fewer than 3-5` on MODERATE, which both matched at exactly 4. Pinned to `4 or more` for SIGNIFICANT and `3 or fewer` for MODERATE.
- **`agents/test-baseliner.md` Makefile parse row** — previously detected `make test` but had no parse pattern; a Make-driven project would silently get `Total: 0 | Passing: 0 | Failing: 0`. The parse table now has a Make row with best-effort pattern matching and a note explaining the limitation.
- **`install.ps1` / `uninstall.ps1`** — removed PowerShell 7+ only operators (`||`, `??`) that broke on Windows PowerShell 5.1 (the default on Windows 10/11). Replaced with PS5.1-compatible forms.
- **`install.ps1` / `uninstall.ps1`** — replaced em-dashes and box-drawing characters with ASCII. Windows PowerShell 5.1 reads BOM-less script files using the ANSI code page, which mangled UTF-8 multi-byte sequences and caused parser errors at every line with fancy characters.
- **`uninstall.ps1`** — probe Python with a real `--version` call before using it, so the Windows Store `python3.exe` stub (a placeholder that errors at runtime) is correctly identified as "not Python" and the script prints a helpful skip-message instead of a red error.
- **NVD/Detect circular dependency in `/vuln`** — split research into Round A (NVD + Baseline in parallel, no package name needed) then Round B (Detect agents per CVE, package names now known). Per-CVE failure handling explicit.
- **`subagent_type: "Explore"`** replaced with `general-purpose` + explicit Read/Glob/Grep/LS tool restrictions in `/impl` and `/vuln` (Explore is not a valid Claude Code Agent type).
- **`git diff` for new-file-only implementations** — all three commands now use `git add -N . && git diff` so the code-review agent never receives an empty diff.
- **`/upgrade` Agent B is now read-only** in Phase 1; changes are applied in Phase 2 prep step 3, AFTER baseline capture, so the baseline is pristine.
- **`/upgrade` Opus planning** moved before user confirmation; user now sees the full Opus-generated plan before approving.
- **`code-review.md` `Bash` removed from tools list** — reviewer must be read-only; the "NEVER modify files" prompt rule is now enforced by the toolset.
- **Stop condition enforcement** — all three commands enforce: after one review-fixer pass + one re-review, if verdict is still BLOCK, stop and surface to user. No infinite loops.
- **OWASP filter regex** in `/vuln` — `A\d` → `A\d{2}` (OWASP IDs use two digits).
- **`/vuln` Detect agent scan list** expanded to include `*.csproj`, `Gemfile`, `composer.json` (aligning with `build-systems.md` coverage).
- **`hooks/test-notify.sh` ARG_MAX** — switched from passing test output as argv to stdin pipe; large test outputs (>128KB on Linux, >256KB on macOS) no longer crash the hook.
- **`commands/vuln.md` SIGNIFICANT/HIGH-RISK path numbering** — fixed duplicated step 4, missing step 5; downstream references updated.
- **`commands/upgrade.md` Phase 2 structure** — split into "Phase 2 prep (once)" + per-component loop with unambiguous numbering (prep: 1–3, loop: 1–8).
- **`commands/impl.md` Phase 4 agent count** — corrected "three agents" → "four agents".
- **`commands/impl.md` Phase 5 report** — now surfaces feature-branch name under `### Branch`.
- **`references/model-routing/classification.md`** — "4+ non-test files" threshold qualified to require non-trivial logic changes (excludes pure renames, import updates, mechanical refactors, generated-code changes).
- **`references/fix-vuln/nvd-api.md` safe-version derivation** — added worked examples for `.Final`/`-RELEASE` suffixes; clarified range-matching against project's current version line to avoid wrong-range selection.
- **`references/upgrade/compatibility.md`** — new "Known major migrations" section documenting Spring Boot `javax`→`jakarta` migration with detection command, fix approach, and companion changes.
- **`/upgrade` companion-upgrade chain** — now hard-capped at 3 levels with cycle detection; chains exceeding the limit are surfaced as `BLOCKED — companion-cycle` in the summary table (matters for unattended ai-container runs).
- **`hooks/preload-context.sh`** — directory listing gated to repos with ≤30 root entries; large repos no longer leak the listing into context.
- **`/vuln` commit template** — removed hardcoded `Co-authored-by: Claude Code <noreply@anthropic.com>` (some corp Bitbucket instances reject the email).
- **All PowerShell code fences in `references/fix-vuln/build-systems.md`** corrected to `bash` fences.

#### Verified
- End-to-end install and uninstall on Windows with both Windows PowerShell 5.1 and PowerShell 7.6.1. PS 5.1 falls back to file copies (no Dev Mode / admin); PS 7.6.1 successfully creates symlinks. Round-trip install → uninstall → install works cleanly on both. Smoke test (`tests/smoke.sh`) is 54/54 green on Linux.

### 2026-04-24 (monorepo 1.1.0)

#### Added
- **`uninstall.sh`** — idempotent reverse of `install.sh`; removes managed symlinks and strips our hook entries from `~/.claude/settings.json`.
- **`install.sh --no-hooks` / `--no-plugin` / `--help`** flags for granular installs.
- **`install.ps1`** — native Windows installer (PowerShell). Creates symlinks with auto-fallback to file copy when Developer Mode / admin isn't available. Skips hooks (bash-only).
- **`references/fix-vuln/`** and **`references/upgrade/`** — reference docs for `/vuln` and `/upgrade` are now vendored into the repo (previously external at `~/.copilot/skills/`).
- **`CHANGELOG.md`** — this file.

#### Changed
- **Hook field names corrected**: `preload-context.sh` now reads the `prompt` field (with `user_prompt`/`message` fallbacks) from the UserPromptSubmit payload; `test-notify.sh` now reads `tool_input.command` and `tool_response.output` (with top-level fallbacks) from the PostToolUse payload. Both hooks were previously silently exiting early due to reading the wrong fields.
- **`preload-context.sh` hardening** — removed `set -euo pipefail`, added `python3` availability guard, error-tolerant command substitution. Matches the robustness of `test-notify.sh`.
- **`/impl` step 8 agents** now receive a structured change summary block (including `git diff --stat` output and notable additions/removals) instead of a one-sentence description. Documentation, knowledge, and instructions agents can now reason precisely about what changed.
- **`install.sh` location guard** — refuses to run unless located at `$HOME/.claude/claude-config/`. Prevents silent misconfiguration when the repo is cloned elsewhere.
- **`install.sh` plugin symlink** — now unconditionally `rm -rf`s the target before `ln -sf`, preventing the "stray nested symlink" bug that occurred on repeated runs.
- **`install.sh` settings.json guard** — creates an empty `{}` skeleton if `~/.claude/settings.json` doesn't exist, rather than crashing.
- **`test-notify.sh` output parsing** — uses `python3` for framework output parsing (portable) instead of `grep -oP` (GNU-only, fails on macOS).
- **`/vuln` intro** — clarified the sequential-then-parallel execution model.
- **`/upgrade` Phase 2 step 3** — excludes `.github/workflows/` to prevent GitHub Actions from being processed twice.
- **README** — added detailed per-command phase explanations, Windows section, uninstall instructions, install-flag table.

### 2026-04-24 (monorepo 1.0.0)

Initial shareable repo.

#### Added
- **`commands/impl.md`** — `/impl` command with Explore subagent before planning and three parallel post-implementation agents (Documentation / Knowledge / Instructions).
- **`commands/vuln.md`** — `/vuln` command with parallel NVD / Detect / Baseline research before fix.
- **`commands/upgrade.md`** — `/upgrade` command with parallel compatibility research and GitHub Actions agents in Phase 1; uses `workflow-tools:test-baseliner` for the test baseline.
- **`plugins/workflow-tools/`** — plugin with the reusable `test-baseliner` agent (Maven / Gradle / npm / pytest / Makefile detection).
- **`hooks/notify-done.sh`** — Stop hook; cross-platform desktop notification (macOS / Linux / WSL2 fallback chain).
- **`hooks/preload-context.sh`** — UserPromptSubmit hook; injects git branch/status/log for `/impl` / `/vuln` / `/upgrade`.
- **`hooks/test-notify.sh`** — PostToolUse:Bash hook; parses test output and notifies.
- **`install.sh`** — idempotent installer; `ln -sf` symlinks + Python JSON merge.
- **`settings-additions.json`** — hook entries merged into `~/.claude/settings.json`.
- **`README.md`** — setup, usage, and platform notes.
- **`docs/specs/2026-04-24-command-subagents-hooks-design.md`** — design document.
