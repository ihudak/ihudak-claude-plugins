# Changelog

All notable changes to the **product-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [3.6.0] — 2026-09-10

### Fixed — `/brd-split` Phase 6 quoted the **stopping** consent array unconditionally, for a set that is advisory-only on a reachable path (1.0.0)

Phase 6 presented `workflows-core:phase-handoff` §4.3's **gated — stopping** array for every run. On Phase 0 step 10's third branch — `unallocated_zero` with at least one standing empty child, where Phases 2–4 are skipped and **Phase 4.5 runs alone** — an operator who answers that phase's picker with **keep** for every child leaves `deliverable_paths` at that child's `brd-link.md` and nothing else: Phase 4 never walked, and Phase 5 *"rewrites only what the removal changed"* so `slices.md` is untouched. Phase 6's own closing paragraph already said as much (*"a 'keep' that wrote or updated a `reason:` stages that child's `brd-link.md`, so it opens a pull request like any other run"*). §4.0's register classes `brd-link.md` **advisory** — read by BRD-route detection in `/create-prd`, `/create-ard` and `/specify`, by `/epics` step 1a and by this command's own Phase 0 step 5, and named in no §3.4 row — so the run told the operator that declining costs a downstream stop no command makes, and then, three paragraphs later, printed §4.1's **advisory** outcome clause against its own prompt: the precise contradiction §4.3 exists to forbid.

**The phase now selects between two arrays**, the shape `/create-ard` Phase 6 and `/implement` Phase 4.5 already use: **stopping** where the set holds any *slice-level* `coverage-ledger.md` or `brd/brd-inventory.md`, which `/prd-ground` gates; **advisory** where it holds neither. The second branch is exhaustive over the rest and is reachable three ways — the keep-only Phase 4.5-only run, the no-op path and a keep that changed nothing (both empty sets), and a `full` root run that carved nothing, whose whole set is a **root's** ledger and `slices.md`, both advisory in §4.0's register. **Why the previous round's producer walk missed it:** §4.1's new *"a producer whose set varies between runs resolves this per run, and two do"* is scoped to sets spanning the two **gated** halves, and is correct on that reading; `/brd-split`'s variation is one level up, gated-vs-advisory under §4.0's set rule. **Ungated** — check 12 reads arity only, and both arrays carry three options — verified by mutation.

### Fixed — the reader census was re-stated as **two** readers on six surfaces while §0 and this section's own heading say **three** (3.6.0)

The previous round replaced the unscoped *"the one reader a proposal has"* with a scoped head plus an **exhaustive** remainder — *"every other read is a later run of the producing command"* — which is one reader short of the census it was summarising. `references/proposal-format.md` §0, the entry below, and the tree all agree on the same four reads: `/brd-proposal` on each **included** slice's `proposal.md` (the one cross-folder read, and the only gated one), a later run of `/prd-proposal` and a later run of `/brd-proposal` each on their own folder's as §8's stability anchor, and `agents/proposal-reviewer.md`, which *"Refuse[s] to run without a readable `proposal.md` at the given path"* (`:62`) and is dispatched by `/prd-proposal` Phase 9 and `/brd-proposal` Phase 10 — **inside the run that wrote the file**, which is neither of the other two relations. One cross-folder reader, three further readers, and the heading above was right. Every surface now says that: `commands/prd-proposal.md`'s framing and its `## Final report` instruction, `commands/brd-proposal.md`'s framing and its `## Final report` instruction, `docs/roles-and-phases.md`'s `proposal` paragraph, `docs/commands/{prd,brd}-proposal.md`, `docs/reference/proposal-format.md`, and `CLAUDE.md`'s plugin paragraph.

**Two surfaces still carried the retired claim outright, and one of them instructs a run to print it.** `references/proposal-format.md` **§1** read *"The one command that does read a proposal is `/brd-proposal`"* — in the same file as, and directly under, the §0 the previous round had just made the census, so the corrected file contradicted itself, which `workflows-core:instruction-file-maintenance` calls a defect outright. `commands/prd-proposal.md`'s `## Final report` is worse in kind: it is not description but *"**Say plainly, at the end**, … the one command that does read one is the sibling umbrella"*, so a run following the file in order printed the retired sentence to the operator having read the scoped one at `:32`. §1 now scopes the head and points at §0 rather than restating it, with a line saying not to restate it — it is the sentence the six copies were taken from. Two further sites outside the previous round's list fell to the same probe: `commands/brd-proposal.md`'s *"the only reader of the umbrella this run writes"* and its own `## Final report` *"the one thing that ever reads an umbrella"*, both false of `proposal-reviewer`, which reads the umbrella in that same run.

### Fixed — three "gates nothing" labels about the proposal pair, and `roles-and-phases.md` contradicting itself between its role bullet and its phase paragraph (3.3.3)

`docs/roles-and-phases.md`'s **PM** bullet called the two commands *"which gate nothing and which nothing waits on"*, while the same page's `proposal` paragraph says *"`/brd-proposal`'s gate on a slice's `proposal.md`"* is real. The previous round's residual deliberately left five compact labels standing on the test that *"the subject is the **role or phase group** rather than a command"*; this bullet names **the two commands** and is ordinary prose in a bullet with no width constraint, so it met neither half. `README.md`'s two role cells are the same failure with the row's own Commands column naming one command each. Both are now *"gates nothing on the build ladder"*, and the bullet names what each **does** gate — `/prd-proposal` the folder's `prd.md`, `/brd-proposal` each included slice's `proposal.md`.

**The `proposal` paragraph itself was falsified by the same walk and is corrected with it**, which no grep of the bullet's wording would have reached: *"the one phase here that no other phase waits on and that gates nothing **outside itself** — `/brd-proposal`'s gate on a slice's `proposal.md` is this same phase gating its own earlier run"* disposed of one of the pair's two input gates and not the other. `/prd-proposal` runs `require-on-main` on `prd.md` (`workflows-core:phase-handoff` §3.4, `PRD_PROPOSAL_NEEDS_PRD` / `PRD_PROPOSAL_PRD_NOT_HANDED_OFF`), which is the `prd-creation` phase behind it and squarely *outside itself*. The paragraph now says nothing it gates lies **downstream** of it and names both input gates. Two further compact labels went with them — `docs/workflow.md`'s mermaid subgraph label and its role table cell — and `commands/create-ard.md`'s next-step guidance lost an unqualified *"nothing waits on a proposal"* in the one place a `PRD-` folder it offers may be a slice an umbrella will wait on.

### Fixed — positional claims in this section's own records, measured against the blobs they describe

*"read `"It gates nothing"` **twelve lines under** a *Gates* section"* — `docs/commands/brd-proposal.md` has `## Gates` at `:70` and that bullet at `:79` at every revision where it read so, which is **nine**, or **seven** from the `"only hard refusal on readiness"` bullet the sentence quotes. *"`/specify` being affirmed as carrying the clause **three lines above**"* — in `a251768f`'s own blob the affirmation is at `:468` and the *"Neither option …"* sentence at `:477`, which is **nine**; the same pair sits fourteen apart at `226b1e4d`. A **third** distance on that same line, which no ruling named and which the line-number sweep found only because the fix grepped its own string: *"the `/specify` bullet **three lines above**"*, about the pre-fix tree, where the two sit at `:647` and `:661` — **fourteen**. And in the `/create-prd` rung-4 entry, *"ten lines apart"* / *"the paragraph ten lines above"* is **nine** from the sentence and **eleven** from the paragraph's first line in `6914b5b3`'s blob, so no reading gives ten. Every one is replaced by a relative reference rather than re-derived, because a line distance goes stale on the next edit above it — the disposition an earlier round already chose for *"sixteen lines above the gate"*. **Verified correct and left alone**, so they are not "fixed" next round: `workflows-core:CHANGELOG`'s *"`dependencies.md` undercounted the family…"* entry, whose *"nine lines above"* is 36 → 45 in `480ab946^`'s `dependencies.md`, and its *"`dependencies.md` says who declares `prose-style`"* entry, whose *"eleven lines later"* is 11 → 22 in `2ca15cf0^`'s — cited by heading rather than by line, since this entry's own ruling is that a line citation into another file goes stale on that file's next insertion, and the two `:115` / `:236` pointers first written here were already stale in the commit that published them — plus `commands/frames.md:287` and `workflows-core:prd-format:57`, both re-measured by the previous review.

### Fixed — "the one reader a proposal has" stood on six surfaces, beside the census that names three further readers (3.3.3, and 3.4.0 for the two in `CLAUDE.md`)

`references/proposal-format.md` §0 names the readers: the one command that reads **another folder's** proposal is `/brd-proposal`, and *"the other readers open only their own folder's"* — `/prd-proposal` and `/brd-proposal` each on a re-run, plus `proposal-reviewer` inside the run that wrote it. The unscoped form said there is one, and it survived on `docs/roles-and-phases.md`'s `proposal` paragraph, `commands/prd-proposal.md`'s framing and its §4.3 class justification, `docs/commands/prd-proposal.md`'s *What it does not do* bullet, and both copies in the repository's `CLAUDE.md`, which arrived a release later at **3.4.0** (`5076d2ca`) and are the reason the sweep scope is `plugins/` **plus** the root files. On `docs/roles-and-phases.md` the refutation was the *next sentence*, added in the same delta: *"The umbrella itself is read only by a later run of `/brd-proposal`"* establishes that a later run of the producing command is a reader, and `/prd-proposal` reads a slice's `proposal.md` on exactly that relation — Phase 0's revision note, Phase 6 step 6, and §8's stability rule, which carries a package's expected hours forward from it. Each head is now scoped the way `docs/commands/brd-proposal.md`'s twin already was, and says beside it that a later run of the producing command reads its own folder's. **`commands/prd-proposal.md`'s consent class is unaffected** and says so: the own-folder read is off the working tree and stops nothing, so a `PRD-` folder's `proposal.md` stays gated by `/brd-proposal`'s §3.4 row.

**Two exclusivity claims about *gating* fell to the same probe, both on `/brd-proposal`'s page.** Its *What it does not do* bullet lost the word `downstream` in this delta and read *"It gates nothing"* under a *Gates* section naming the command's *"only hard refusal on readiness"* — no line distance is stated, because one goes stale on the next edit above it; its opening paragraph carried the same claim unqualified from `10a72f2b` (2026-09-09, **3.3.3**). Both now read *"gates nothing on the build ladder"* and point at the input gate — the command body's own form. `docs/reference/proposal-format.md`'s twin needed no change: its subject is the **document**, not the command. **Ungated** — `check-docs.sh` check 9 is the only gate over a documentation page's prose and it reads inventory **count** sentences alone (checks 1, 10, 13 and 15 read the same pages for links, marketplace tokens, vendor tokens and command listings, none of which this sentence carries) — verified by mutation.

### Fixed — `/idea` read two link forms where `/brd-intake` reads four, so a screenshot a source embedded as `<img src>` reached nothing and was reported nowhere (dev-workflows 3.20.0)

`agents/idea-reader.md` said *"Both syntaxes are followed — `[[wikilink]]` and standard markdown `[text](path.md)` alike"*, and `grep -cE '<img|reference-style|\[label\]:'` returned **0** on that file and on `commands/idea.md` alike. So an idea source carrying a screenshot as `<img src="shot.png">`, or naming a page or an image in a reference-style definition `[label]: target`, had that file reached by nothing: not followed by the traversal, not read by the image pass, not enumerated into `links_other`, and not named in `wikilinks_not_followed` or `wikilinks_broken` — the state *"a link nothing copied and nothing reported is indistinguishable from a link that was never there"* forbids, which is the same silence `/brd-intake` Phase 2 removed for a customer's BRD. **3.20.0 widened the set from one form to two**, adding standard markdown because *"a source written outside a vault uses the second form"*; that argument covers the other two exactly as well, and they were never added. A new `### The link forms` section now fixes the set in one place for every pass below it — the `[[wikilink]]` plus `/brd-intake` Phase 2's list, taken from there unchanged and restated in full rather than re-invented — and states that the form decides only *that* something is a link while the extension decides which pass takes it, so `<img src="shot.png">` is read exactly as `![shot](shot.png)` is.

**The caps and the reporting vocabulary are untouched, which is the whole of the trade.** `/idea` reads for a grill under 12-file and 6-image caps while `/brd-intake` preserves an immutable record; only *which forms are recognised* moves, and no form gains an array, a `reason` or a cap of its own. Verified against a fixture source linking an image beside it, one in a subdirectory, one above it, an absolute path, a URL and a missing file, plus a page reachable only through a reference-style definition and a `.pdf` named only there. Before: two pages and three images, **nine further targets found by nothing**. After: the appendix followed at depth 1 and its own frame reached at depth 2, three further images read, the `.pdf` in `links_other`, the URL and both missing targets in `wikilinks_broken`, and the frame past the six-image cap listed with `read: false` and `reason: cap` — every new form disposed of through vocabulary that already existed.

**Four surfaces stated the old coverage and are rewritten rather than appended to** — `idea-reader`'s `description` and its `## Bounding` depth bullet, `/idea`'s own `description` and Phase 2 prose, `docs/commands/idea.md`'s *What it reads*, and `docs/reference/agents.md`'s row. Phase 4.5's rewrite list keeps its four forms and now says why it is the shorter one: it matches links in `idea.md`, which Phase 4 authored and into which every link this phase writes is standard markdown. **A fifth sentence fell to the same sweep**, and its history is three releases rather than one: `commands/create-prd.md` Phase 2 called the bound *"two wikilink levels"*, which was **true when it was written** — `7fa6fa75`, 2026-09-01, `dev-workflows` **3.16.0**, whose `idea-reader` traversed *"`[[...]]` wikilinks … up to two levels deep"* and nothing else. 3.20.0 (`107cc7c8`, the same day) falsified it as a **count** by widening the traversal to two forms, and `idea-reader`'s own vocabulary rule — reserve "wikilink" for the `[[...]]` syntax and say "link" everywhere else in `/idea`'s chain — then forbade it outright as **wording**, entering a day later at `5225e0d8`, `dev-workflows` **3.24.1** (2026-09-02). The draft of this entry dated that rule to 3.20.0; `git show 107cc7c8:plugins/dev-workflows/agents/idea-reader.md` carries no such rule, which is why provenance here is read out of a blob rather than off a nearby version number. **Ungated** — nothing in `scripts/` reads an agent's traversal rules — verified by mutation.

### Fixed — `/create-ard`'s BRD-route offer swapped the command out of an option and left its role label, lead-in and merge clause behind (dev-workflows 3.13.0, before the split)

Phase 7's BRD-route array shipped one literal option — *"Hand to a Product Engineer — `/product-workflows:epics <SLICE-KEY>` (PE) `<merge-clause>`"* — under an instruction resolving **the command alone** by a test: `/epics` where the slice holds an authored `prd.md`, otherwise `/product-workflows:create-prd <SLICE-KEY>`, `/product-workflows:brd-split` against the slice or its parent, or no second option at all. Measured across the tree, `/create-prd` carries **(PM)** at every other offer site (`commands/brd-reconcile.md` Phase 14's prose list and its array, `commands/create-ard.md`'s own idea-route bullet, `workflows-core:next-phase-offer`'s routing graph) and `/brd-split` carries **(PM)** too (`next-phase-offer`'s BRD-route node); `/epics` carries **(PE)**. So on three of the four substitution branches the run printed a PM command under a Product-Engineer lead-in and a `(PE)` label — a false role attribution to the operator, in an array `workflows-core:escalation-rules` requires be presented verbatim. **The clause was in the same position and wrong in both directions**: `/create-prd` gates only `idea.md` and reads no ARD, and `/brd-split <PARENT-KEY>` is a root run in `split_mode: full` that skips the grounding gate entirely — neither waits on anything this run writes — while `/brd-split <SLICE-KEY>` runs `allocate-only` and does gate this slice's `grounding/code-grounding.md`, which this run's own `deliverable_paths` stages for the `consumed_by: ARD` writes. **The fix writes the five arrays out**, one per branch of the test, each option carrying the lead-in, role label and clause of the command *it* names — the same repair `/prd-ground` Phase 10 took one round earlier, and the shape this command already used for its other two routes. Three options per array except the drop branch's two, inside `AskUserQuestion`'s 2–4 (check 12), no authored "Other", and `(Recommended)` on `/product-workflows:specify <SLICE-KEY>`, which is reachable on every branch.

**Two sentences beside it were falsified by the same paragraph and are corrected with it**, neither reachable by grepping the option's wording. The `/epics` bullet closed *"No option here gates anything this run produced, so none carries a merge clause"* — contradicted by both options of its own array and by the `/specify` bullet above it (*"so the wait is real and the clause is required"*); `workflows-core:ard-resolution` names `/epics` among the **five** of its six consumers that **stop** on `status: unmerged` — `/ready` is the sixth and is excepted by name in that same file, recording it as a readiness finding capping the verdict at `PARTIAL` — so its option's clause was right and the sentence denying it was not. That contradiction is older than the substitution rule: `c17f8118` (2026-09-01, **dev-workflows 3.13.0**) wrote *"`/epics <ADDRESS>` is offered unconditionally … It gates nothing this run produced, so it carries no merge clause"* above an array that already carried the placeholder on it; `a251768f` the same day extended it to the replacement option beside it (*"**Neither option** gates anything this run produced, so **neither** carries a merge clause"* — two of that array's three, `/specify` being affirmed as carrying the clause at the close of the bullet immediately above); and `4a7cc6f0` (**dev-workflows 3.14.0**) then made it the universal this fix removes. The bullet's lead-in carried the second: *"only one of the three usual options can be reached with one \[slice key]"*, while the array beneath it named two of them — `/specify` and `/epics` both take the slice key, and it is `/dev-workflows:design` alone that a slice key cannot reach. The closing paragraph's *"the wait it names is real for every command named above"* is scoped to the options that carry the clause, since two commands named above now correctly carry none.

**Ungated in both directions, and measured rather than assumed.** `check-docs.sh` check 11's family glob is `/product-workflows:brd-*` and `/product-workflows:prd-*` (`next-phase-offer`'s scope paragraph), so `/create-ard` is inside the `<merge-clause>` *convention* — that paragraph names its *Next-step offer (adaptive)* phase among the six converted pipeline offers — and outside the *gate* that enforces it; check 12 sees only arity, which the fix keeps legal on every branch. Verified by mutation.

### Fixed — the `/brd-proposal` docs page's replacement exclusivity claim was still stronger than the agent it describes (3.6.0)

`658b1b21` replaced one over-claim (*"Only its Coverage check tells the two apart"*) with a narrower one that is still false: *"Two checks tell the two apart … **Nothing else about it differs by folder kind.**"* The same commit taught `agents/proposal-reviewer.md` the clause that falsifies it — *"A rule a check **delegates** to still carries its own scope: check 6 re-grades against `references/proposal-format.md` §5, which grades no umbrella off its ladder at all"* — and §5 confirms it: *"an umbrella's tier is **not graded off this ladder at all**: it is the minimum of its included slices' tiers (§14)."* Check 6's behaviour therefore does differ by folder kind, and a reader of the page concludes the reviewer re-grades an umbrella against a ladder that reads `prd.md`, `ard.md` and `specification.md` — none of which a `BRD-` container holds — which would file a tier BLOCKER against every umbrella claiming tier ≥ 2. Both surfaces now carry the agent's own scoping: nothing else in that agent *narrows a check* to an umbrella, though a rule a check delegates to keeps its own scope. **The command body carried the same sentence and is corrected with the page**, from `10a72f2b` (2026-09-09, 3.3.3); the page's own form entered in `658b1b21` at **3.6.0**, in the commit that also wrote the agent clause refuting it. **Ungated** — no check opens an agent's hard rules, and none reads a `Gates` bullet's exclusivity claim: `check-docs.sh` check 9 is the only gate over a documentation page's prose and it reads inventory **count** sentences alone (checks 1, 10, 13 and 15 read the same pages for links, marketplace tokens, vendor tokens and command listings, none of which this sentence carries) — verified by mutation.

### Fixed — `/create-prd`'s capture-at-block invariant named a stop the command cannot emit (dev-workflows 3.5.0, before the split)

Phase 7's invariant closed *"`CREATE_PRD_NEEDS_KEY` and **`CREATE_PRD_TWO_SEEDS`** are the same."* `grep -rn 'TWO_SEEDS' .` over the whole repository returned that one line and nothing else — after the fix it returns this entry alone, which quotes the name in order to retire it: there is no emission site, and no state that could reach one — the stop fired when `--from-prd` and `--from-brd` were given together, and `/create-prd` has had exactly one value-taking seed flag since `--from-brd` was retired. Phase 7 is an executed instruction list, so this named a stop id a run can never produce and left a dangling member for anyone auditing the command's stop inventory against the tree. **Dangling from the commit that removed its cause:** `7088dff1` (2026-08-31, *"retire issue_type, `--from-brd`, and the two-grammar rule"*, `dev-workflows` **3.5.0**) deleted the emission block and rewrote this very sentence in the same diff, carrying both `CREATE_PRD_BRD_NOT_FOUND` and `CREATE_PRD_TWO_SEEDS` across unchanged; the first was later retired from the sentence and recorded as retired at the head of the file, the second was not. The name is dropped — the sentence reads correctly without it. **Ungated**: `check-id-grammar.sh` matches dash-separated requirement IDs and `check-docs.sh` opens no stop ids; verified by mutation.

### Fixed — `/brd-proposal` told the operator that nothing reads the file its own re-run reads (3.3.3)

Phase 11 presented `workflows-core:phase-handoff` §4.3's **`unread`** consent array — *"Just write the files — I'll handle git (nothing downstream reads this, so no command stops on it)"* — and its justification recorded a search that never looked in the run's own folder: *"no command of the build ladder reads a proposal, `/prd-proposal` reads only the profile and its own folder, and the one command that reads another folder's proposal — this one — reads a **slice's**, never an umbrella's."* Every clause is about *other* folders. **This command reads its own umbrella on every re-run:** Phase 0 step 5 notes whether `proposal.md` already stands in the resolved folder, and Phase 6 step 9 *"Apply §8's stability rule on a re-run, against the prior revision Phase 0 noted"* — the anchor `references/proposal-format.md` §8 makes the thing a moved figure owes a named cause against. §4.0's own test settles the class: *"no §3.4 row, **but** a command reads the artifact and never gates on it"* is **advisory**, and its `customer-review-<YYYYMMDD>.md` row is advisory on exactly this relation — a later run of the same command. The array is now the advisory one (*"no command stops on this; what reads it reads your working copy"*), which is also what is true: declining the handoff leaves the anchor on the working copy, where the next run reads it. The `<downstream-clause>` §4.1 prints follows the class automatically and needed no edit here.

**Three sibling sentences stated the retired claim and are corrected with it**, none of them reachable by grepping the array's wording: the command's own framing (*"nothing reads the umbrella this run writes"*), its `## Final report` instruction (*"nothing — this command included — reads an umbrella"*), and `docs/commands/brd-proposal.md`'s *What it does not do* bullet, which carried the strongest form of all — *"It gates nothing downstream, and **nothing reads what it writes**"* — against a reference twin that was already correctly qualified (`docs/reference/proposal-format.md`: *"It gates nothing, and nothing on the build ladder waits on it"*). `docs/roles-and-phases.md`'s `proposal` phase paragraph carried a fourth (*"and nothing reads the umbrella itself"*). **The census the class was derived from is corrected too**, since it is the recurrence vector: `references/proposal-format.md`'s reader list named *"two other readers … inside the pair"* and omitted `/brd-proposal`'s own-folder read — the one this defect turned on — and it now names both commands, the Phase 6 read and the `proposal.md`-authoring phase that archives after it — **Phase 7 in `/prd-proposal`, Phase 8 in `/brd-proposal`**, since the two do not share the number and `/prd-proposal`'s Phase 8 authors the *brief* — and why the umbrella is `advisory`.

**False the day it was written, in the same commit:** `10a72f2b` (2026-09-09, **3.3.3**) created `/brd-proposal` with Phase 0 step 5 and the §8 stability rule already in it, selected the `unread` array in the same file, and added the §4.0 row asserting *"The umbrella is read by nothing"* — a row whose own last clause then described the read (*"the anchor a later re-run diffs against is the canonical `proposal.md` it reads before archiving it"*). **Ungated** — no gate in `scripts/` opens a §4.3 array's parenthetical; check 12 sees its arity, which does not change — verified by mutation.

### Fixed — `/prd-ground` Phase 10's `/brd-split` withhold test ordered an edit to an array the family presents verbatim (1.1.0)

The `route: brd` branch shipped **one** literal `choices:` array, hardcoding `(Recommended — allocate-only, so no child is created)` with no placeholder in it, and above that array an instruction to replace the recommended option wherever the run recorded a frame set `skipped: no index`: *"do not offer `/brd-split` as Recommended … Offer the repair the stop itself names, **in the same position**"*. There is no third thing a run can do with those two sentences. `workflows-core:escalation-rules`' *Choice lists are presented verbatim* reads *"Its options, their order, their wording, and the `(Recommended)` marker are not the orchestrator's to change"* and, a few lines on, *"There is no permitted adjustment"*; `workflows-core:next-phase-offer` states it from the other side — *"A command that instead told the orchestrator to adjust the wording of an option would be contradicting that convention, which is why the variation lives in a placeholder and not in an instruction."* So a run reaching that state either edited a verbatim array or recommended `/brd-split` on a key `/brd-split`'s own Phase 0 step 7 test b refuses with `BRD_SPLIT_DESIGN_NOT_GROUND` — the exact stop the test was written to keep the operator out of. **The state is reachable**: Phase 5 gets `NO_INDEX` for a frame set, Phase 8 records `skipped: no index` in `## Frame sets covered`, and the test fires. **The fix writes the second array**, selected by the stated test, which is the mechanism this same phase's `route: idea` branch has used all along; the placeholder form `/brd-split` Phase 4's `<recommended>` uses is equally sanctioned (`escalation-rules`, *A marker the command resolves through a placeholder is not a violation of this rule*), and two literal arrays is what this phase already reads like. The withheld array recommends `/workflows-core:frames <BRD-KEY>` and names `/brd-split` in none of its options, because neither half of the repair the stop itself prescribes — write the index, then re-ground with `--no-code` — has run yet; the prose above both arrays still names `/brd-split` and where it sits in the route, which is `next-phase-offer`'s universal minimum for a route an array does not carry. Three options per array, inside `AskUserQuestion`'s 2–4 (check 12), no authored "Other", and each `(Recommended)` marker on an option that can actually be taken.

**Two sentences beside it were falsified by the same paragraph and are corrected with it.** The justification *"The offer's wording is deliberately 'its grounding is complete and verified' rather than the older 'now that every finding carries a verifier outcome'"* described **no array in the tree** — `grep -rn` over `plugins/` returned that one line and nothing else; after the fix the only occurrences are the replacement sentence, which quotes one phrase as retired history, and this entry. Both phrases are real history: `e7aac79f` (2026-08-30) wrote *"Split the BRD once every finding carries a verifier outcome"*, `e86c5ecd` replaced it with *"now that its grounding is complete and verified"*, and `a1109d82` (2026-09-06) retired the root-level branch that array belonged to while keeping the sentence that described it; a later pass then updated the count inside that very sentence (*three* → *four* tests) without re-reading the clause beside it. The rule it carries survives, restated against the arrays that ship: a marker naming one of `/brd-split`'s four tests promises a pass the offer cannot deliver, so each marker says what the run it recommends will *do*. And `docs/commands/prd-ground.md` said the offer *"always names `/brd-split`"* while the command said *"unless the test below withholds it"*; the page now carries the exception in one clause. Two sentences below the arrays that spoke of "the offer" in the singular are scoped to the array that carries `/brd-split`, since the other one does not.

**Unfollowable from the day it was written, at 1.1.0:** `e86c5ecd` (2026-09-06) authored *"in the same position"* beside an array that already hardcoded `(Recommended)` with no placeholder, and `escalation-rules`' verbatim rule already stood. **Ungated** — check 12 reads a `choices:` array's arity and never the prose that selects it — verified by mutation.

### Fixed — `/prd-ground` Phase 10 branched on a grounding verdict that does not exist (3.0.0)

The idea route's next-step offer selected between its two `choices:` arrays on a claim coming back **`SUPPORTED`**, at seven sites in the command and one on its documentation page. `SUPPORTED` is not a grounding verdict: `workflows-core:grounding-format` §3 is closed at **exactly six** — `CONFIRMED`, `AMENDED`, `REWRITTEN`, `FALSE-FRIEND`, `NOT-PROVABLE`, `SUPERSEDED` — and its §2 field table says a finding's `verdict` is *"exactly one of the six values in §3"*. **The consequence is a route no run could reach:** the *"At least one claim `SUPPORTED`"* array is selected by a predicate no finding can satisfy, so the `(Recommended)` *"Revise the PRD first — `/update-prd`"* option was unreachable and the no-claim array fired on every run, including the runs the recommendation exists for. The verdict the paragraph meant is named by its own stated reason — *"a PRD asking for something the code already does"* — which in §3's vocabulary is `CONFIRMED`, *"the premise holds, with evidence"*, and it is the only one of the six that says so — `AMENDED` says partly true, `REWRITTEN` materially wrong, `FALSE-FRIEND` a decoy, `NOT-PROVABLE` unsettleable from the repository, and `SUPERSEDED` a finding a later one replaced. `REWRITTEN` in particular is ruled out rather than merely passed over, because §3 names it and `NOT-PROVABLE` as the verdicts an absent mechanism lands on — and this command's own final report already reports an all-absence run as *greenfield*, the case that needs no PRD revision at all, so a set including `REWRITTEN` would have recommended `/update-prd` on exactly the run that headline exists to close. The correction is a vocabulary one, applied at all eight sites, and the paragraph now carries §3's definition so the token is not re-invented. **The `<N>` the array prints is defined with it, and a raw tally would have been the wrong operand:** it is a count of **distinct requirement claims** — the requirement id read off each `CONFIRMED` finding's own `claim` field, de-duplicated — and it excludes Phase 3's baseline `[CG#n]`, which is `CONFIRMED` by construction and written one per resolved repository, on the property `workflows-core:grounding-format` §4.1 rule 1 already states and already excludes baselines from its own report for: a baseline finding's `claim` is not a requirement premise. Counting the run's whole `CONFIRMED` tally instead would have replaced an unreachable branch with one that fires on **every** idea-route run, greenfield included — the run this command's own final report calls greenfield. Neither Phase 9's `body_facts` nor the final report supplies that de-duplicated quantity (both state finding counts by verdict), so the paragraph says outright to count it from the findings Phase 8 wrote. **Dangling from the day it was written:** six of the seven command sites entered in `e816544c` (2026-09-08), and the seventh — the frontmatter `description` — together with the documentation site in `59b303e0`, the commit that cut **3.0.0**; §3 already read "Exactly six" at both. **Ungated** — check 12 reads these two arrays for arity and never for what the prose above them tests — verified by mutation.

### Fixed — `proposal-reviewer`'s catch-all severity rule stopped one section short of the contract it governs (3.4.0)

Process step 4 read *"a violation of an absolute rule **§1–§13** states is a **BLOCKER**"*. A bare `§N` in this file means `references/proposal-format.md`'s §N — the file says so itself (*"This file cites it by section number throughout and never restates it"*), and its own checks are "check N", never "§N". That contract carries **§1–§14**: `## 14. The umbrella — what `/brd-proposal` adds over a slice's own proposal` is its last heading. §14 states absolute rules no check 1–11 assigns a severity to — the umbrella's per-slice rows are *"read out of that slice's own `proposal.md` and never re-derived"*, it *"does not restate a slice's `[ED#n]` driver table"*, *"Ranges are summed, and stated as summed"*, and its tier *"is the minimum of its included slices' tiers"* — so under the range as written they fell into the only remaining bucket, RECOMMENDATION, and an umbrella that re-derived a slice's hours or claimed a tier above the minimum would have been reported as advisory. `workflows-core:finding-triage`'s BLOCKER escalation never fires on that. **The range is replaced by a citation rather than widened to §14**, so the next section added to the contract does not reopen this. The same step's enumeration *"(2, 6, 7)"* of checks naming both severities goes with it: only check 2 names both (a no-reason band deviation is a RECOMMENDATION, everything else a BLOCKER), and checks 6 and 7 name BLOCKER alone — the clause *"where a check names both, follow the rule stated there"* is what the step actually needs and is true of any check. **True the day it was written and falsified by the commit that taught this file to cite §14:** `2037b4a2` created the agent when the contract's last heading was `## 13.`, and `10a72f2b` added `## 14. The umbrella` **and this agent's two §14 citations** without widening the range. **Ungated**, verified by mutation.

### Fixed — `proposal-reviewer`'s header said only check 9 distinguishes a slice run from an umbrella run (3.4.0)

The header read *"the same review, over a `PRD-` slice's own proposal or the `BRD-` umbrella's, and **only check 9 tells the two apart**"*, and the Hard rules repeated it as *"reviewed by checks 1, **2**, 3, 4, 5, 6, 7, 8, 10 and 11 exactly as a `BRD-` umbrella's is; only check 9 differs by folder kind"*. Check 2's final bullet is umbrella-conditional and says so on check 9's own test — *"(Umbrella runs only — the same folder-kind test as check 9.)"* — and it is the only relation in the file that catches a programme total which merely sums its slice rows, the thing §14 calls *"indistinguishable from an arithmetic error"*. The header is scoping guidance the agent reads before any check, so an agent told the review is *the same* except for check 9 has a stated reason to work check 2 in its slice form on an umbrella. Both sentences drop the count rather than enumerate around it: the header now says a check that tests the folder kind says so where it applies, and the Hard rule names check 2's bullet as the one place this file narrows a check beyond check 9 — and, separately, that a rule a check **delegates** to carries its own scope, which is how check 6's re-grade meets §5's *"an umbrella's tier is not graded off this ladder at all"*. `commands/brd-proposal.md`'s own dispatch paragraph already named both checks and was the one site that had it right. **True the day it was written:** `2037b4a2` wrote the header when check 9 genuinely was the only folder-kind-conditional check; `60f27877` added check 2's bullet and left both exclusivity claims standing. **Ungated**, verified by mutation.

### Fixed — the `$DOCS_PATH` consumption-mode partition gave `/epics` a mode it does not use (1.0.0)

`docs/reference/environment.md` enumerated the six commands that resolve no docs grounding, leaving eight consumers, and then offered two modes for them — *"grill-rank in the authoring/interview commands, lead-only in `/prd-ground`"*. There are three. `workflows-core:docs-grounding` names **`writer-attach`** for `/epics` and `/release-notes`, grill-rank for `/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify` and `/brd-intake`, and lead-only for `/prd-ground`; `CLAUDE.md` states the same split. `/epics` is an authoring command by any reading — `epic-writer` is *"the sole author of the Epic drafts"* — so the omitted member is covered by the phrase that names the partition's first half, while `/epics` runs no grill at all and has nothing for ranking to reorder. The line now names all three modes and the six commands the first covers. Nowhere else on this page or in `docs/getting-started.md` is writer-attach named. **False the day it was written:** `4ec4a374` (2026-09-06) built this documentation tree with the two-mode clause already in it, under a `plugin.json` reading **1.0.0** (the plugin was still named `pm-workflows`; the rename carried the version across) — and at that commit `epics.md` was already in it and `workflows-core:docs-grounding` already named `writer-attach` for `/epics`. The non-consumer enumeration beside it has been rewritten twice since; the partition was never re-read.

### Fixed — `/prd-ground` Phase 10 sourced its count from a Phase 0 step that reports a different one (3.0.0)

The next-step offer's `SUPPORTED`-claims branch read *"**Phase 8i's** report carried the count"*, and both halves were wrong. There is no Phase 8i: the command's `## Phase` headings are 0, 1, 2, 3, 4, 4.5, 5, 6, 7, 8, 9, 10 and 11, and `8i` is a **step of Phase 0** — the one that reads the claim list from `prd.md` on `route: idea`. Every one of the file's six other mentions calls it that (*"step 8i"*, or *"step 8 (or 8i)"*); this was the only one that promoted it to a phase. **And the step it named carries the wrong number.** Step 8i reports how many requirement rows were *excluded* from grounding — its own words are *"11 of 19 requirement rows ground; 8 excluded — 3 `[UC#n]`, 5 `[SM#n]`/`[SMC#n]`"* — and it runs in Phase 0, before Phase 5 grounds anything and Phase 7 verifies it, so it cannot hold a count of how any claim came back. The `<N>` Phase 10's own array prints is the verdict tally instead: Phase 9's `body_facts` sentence already carries it, and the Final report states it for `[CG#n]` and `[DG#n]` separately. The clause now names that. **Correcting the phase token alone was not enough, and that is recorded rather than quietly re-cut:** an earlier pass on this branch changed `Phase 8i` → `step 8i` and left the referent, which is the whole-sentence rule this release's changelog discipline exists for. **Dangling from the day it was written:** the sentence entered in `e816544c` (2026-09-08) and shipped at **3.0.0**, where `grep '^## Phase'` already listed the same thirteen headings and step 8i already reported only the exclusion count. **Ungated**, verified by mutation.

### Fixed — the deleted vault was still a live place in four `product-workflows` sentences (1.0.0)

`references/bundle-packaging.md` §2 opened *"The working documents live in a vault and use its syntax"*, and `references/idea-format.md`, *Vendored sources*, says the opposite of the same tree: *"`$SPECS_PATH` is a git repository, read on a forge's web view and in ordinary editors; it is **not** an Obsidian vault. Nothing there resolves `[[name]]`, and a forge renders it as literal text."* Both cannot be true, and the tree settles it — `$VAULT_PATH` was deleted in increment D and appears **nowhere** in the four family plugins, the repo-root `README.md` or `CLAUDE.md`; the full env-var census over that scope returns `$CLAUDE_PLUGIN_ROOT`, `$SPECS_PATH`, `$REPOS_PATH`, `$DOCS_PATH`, `$GIT_USER_INITIALS`, the two guideline paths and the cost-price variable, and no vault variable of any spelling. **The section's work is right and is untouched**: the artifacts genuinely do carry `[[KEY]]` wikilinks, which is what the de-Obsidianising pass rewrites for a reader outside a vault. Only the premise changes, to what the tree holds — they live in the specs repository, which is a git repository and not a vault, and carry wikilink syntax anyway, `[[KEY]]` being the specs tree's traceability form and the customer's own source document arriving with whatever its author wrote. Two definite articles pointing back at the deleted premise (*"resolves to nothing outside **the** vault"*, *"a reader outside **the** vault"*) become indefinite; every sentence about a reader outside a vault is otherwise left exactly as it stood, because that reasoning is the whole point of the rendered copy.

**`/epics`' invariant carried the same premise without the word**, and its provenance shows how: `6914b5b3` (2026-08-31, `dev-workflows` 3.9.0, *"increment D, deleting $VAULT_PATH"*) rewrote *"`/epics` writes into an Obsidian vault, where a wikilink is the native idiom **and resolves**"* into *"`/epics` writes markdown that Obsidian and IntelliJ both render, **where a wikilink resolves**"* — the store was removed from the sentence and its property kept. The invariant's instruction is unchanged (`[[KEY]]` wikilinks stay) and only its reason is corrected: they are the specs tree's required traceability form, not a link that has to resolve. The matching clause in `workflows-core:doc-structure-conventions` §1, which the same commit edited the same way, is corrected in that plugin.

**`/brd-package`'s two never-write lists named the vault as a fourth place a run must not touch** — *"NEVER touches a code repo, a docs repo, **the vault**, or the current working directory"* and *"NEVER writes into a code/docs repo, **the vault**, or the current working directory"*. `workflows-core:specs-repo-git` §1 *Scope* fixes the triple (*"a code repo, a docs repo, or the current working directory, where it is not the specs repository"*) and some twenty sibling sites across the family carry exactly it; these two were the outliers. The token is dropped; nothing else in either sentence moves.

**Ungated**, verified by mutation: with all four sentences restored verbatim the nine-gate CI chain exits **0**.

### Fixed — `/create-prd` treated its `idea.md` rung 4 as retired and as a live picker, in one step of one ladder (1.0.0)

Phase 0 step 3's ladder numbers rung 4 *"(retired — the discover rung searched a personal store for a stray `idea.md`. `/idea` writes into the resolved folder now, so rung 1 finds it.)"*, while the BRD-route paragraph above it justified skipping the whole ladder by saying *"**rungs 3 and 4** would then offer an idea from some other initiative — a picker over stray `idea.md` files is exactly the offer that names something this run has no business reading."* Two live contradictory instructions about one structure, inside a command body an agent executes in order. **The ladder itself settles it twice over**: rung 4 is the tombstone, and rung 1's own fall-through text says an unhandled-off `idea.md` *"would otherwise be passed over in silence all the way to rung 5's grill-from-scratch"* — a sentence that is only true if nothing between rungs 1 and 5 can find a file. **The enumeration is what changes, not the reasoning**: rung 3 is a real source of a stray `idea.md` — a same-session `/idea` output path, offered for confirmation — so the paragraph still has its reason for skipping the ladder, now resting on the one rung that can supply one. The "picker over stray files" phrasing went with rung 4, which is the only rung that ever was a picker. `docs/commands/create-prd.md`'s *"a rung-3 or rung-4 picker"* transcribed the same claim and is corrected with it; that page's own list of remaining rungs already named two, not three. **Born of a retirement that did not sweep its own file:** the sentence entered in `b2c93124` (2026-08-30) when both rungs were live, and `6914b5b3` (2026-08-31, `dev-workflows` 3.9.0, *"increment D, deleting $VAULT_PATH"*) retired rung 4 — the personal store — without touching the step-3 lead-in above it (no line distance is stated: measured against `6914b5b3`'s blob it is nine lines from the sentence and eleven from the paragraph's first line, which is why the number was wrong at ten and would go stale at either); `git show 6914b5b3:plugins/dev-workflows/commands/create-prd.md` carries both lines. It reached this plugin unchanged with the extraction, at **1.0.0**. **Ungated**, verified by mutation: with both sentences restored verbatim the nine-gate CI chain exits **0**.

### Fixed — `/prd-ground` cited a "four-part stop contract" that exists nowhere in the tree (1.0.0)

The `REPO_MISSING` / `FRAME_SET_MISSING` / `NO_INDEX` / `STALE_INDEX` branch read *"Stop, naming the finding and the path the agent reported — and, **per the four-part stop contract**, the command that resolves it"*. There is no four-part stop contract to consult: `grep -rn 'stop contract' plugins CLAUDE.md README.md` returns that one line and nothing else, and the only *four-part* shape in the corpus is `workflows-core:specs-repo-git` §5's **guard notice** contract, which governs the specs-repo guards G0/G1/G2 rather than a command's stop. A run following the line is sent to an authority it cannot find. **The pointer is cut, not repointed** — naming §5 would assert that a `/prd-ground` stop is a specs-repo guard notice, which it is not — and every instruction in the sentence survives untouched: it still names the finding, the path the agent reported, and the command that resolves it. **Dangling from the day it was written:** the clause entered in `107cc7c8` (2026-09-01) as `dev-workflows` 3.20.0's `commands/brd-ground.md`, and `git grep 'four-part stop' 107cc7c8` at that same commit returns only the line itself; it reached this plugin unchanged with the extraction, at **1.0.0**. **Ungated**, verified by mutation: with the clause restored verbatim the nine-gate CI chain exits **0**.

### Fixed — `docs/commands/epics.md` counted another plugin's command wrong, ranked its own wrong, and undercounted its dispatches (3.5.0)

*"`/epics` has 20 `## Phase` headings — the second-most in the plugin, after `/document`'s 37"* was false in both halves. `/document` has **34**, not 37 — `grep -c '^## Phase' plugins/docs-workflows/commands/document.md`, which is also what `docs-workflows`' own `docs/commands/document.md` has said since the re-derivation that produced the 34, so the tree carried two live contradictory statements of one number. And `/epics`' 20 is the **most** in this plugin, not the second-most: the next is `/brd-reconcile` at 16, and `/document` ships from another plugin altogether, so the comparison the sentence made was with the family and not with the plugin it named. The cross-plugin number is **cut rather than corrected**, because a count owned by another plugin's command is a count this page cannot keep true: the re-derivation fixed the page that owns `/document` and left this one, which only cites it, standing. What the sentence exists to say — that `/epics` is large — survives in the half this page can verify against its own tree.

Beside it, *"Six subagents are dispatched"* enumerated six and omitted `prose-style:prose-style-checker`, which Phase 6.2 dispatches unconditionally. That is not a convention here: the same page names it twenty lines below as a non-gating quality pass, and the sibling pages for `/create-prd` and `/update-prd` both count it inside their own number. Seven named agents are dispatched, re-derived by intersecting the family's agent inventory (`plugins/*/agents/*.md` basenames) with `commands/epics.md` and reading every hit — `docs-style-checker` appears there too, only ever in the rule never to run it. The omitted dispatch is the one that crosses into the `prose-style` dependency, which is exactly what a reader asks this sentence.

### Fixed — `docs/commands/epics.md` cited a line of `/epics` that carries a different gate (3.5.0)

The optional PRD-level `specification.md` bullet cited *"Phase 2.6, `commands/epics.md:180`"*. Phase 2.6 begins at `:340` and executes its `require-on-main` at `:353`; `:180` is a Phase 0 coverage-ledger stop — a different phase, a different gate, and the one place `/epics` reads a ledger. The citation is inherited from `origin/main`, where the line held the same text, so it has never resolved. The line number is cut rather than renumbered, per this repository's own convention: the phase name does not go stale on the next edit above it. It was the only citation into a file of this tree, outside a changelog, that did not resolve — the other two, `changelog-owners-reminder.sh:7` and `cost-prices.yaml:22`, both do.

### Fixed — three HARD model gates tested the environment where they meant the session, and so missed the state they were written for (3.5.0)

`/create-ard`, `/prd-proposal` and `/brd-proposal` each open with *"require an Opus session"* and then stop on `opus_available` being false. Those are not the same condition, and `workflows-core:model-routing/classification` §2 keeps them apart deliberately: `opus_available` is *"true if a §2 Opus model resolved"* — what the `task` tool can reach — while the session's own tier is the separate `current_model` field of the same block, which every one of these three records beside it. Reading the field as the session's tier broke the gate in both directions at once.

**It missed the state it exists for.** On a Sonnet session with Opus reachable — `opus_available: true` — the gate did not fire at all, so a `SIGNIFICANT`/`HIGH-RISK` run authored an ARD, or a customer-facing estimate, inline on Sonnet with no advisory of any kind; `/create-ard`'s own line reserves the soft advisory for `SIMPLE`/`MODERATE`, and the two proposal commands, floored at `SIGNIFICANT`, carry no advisory line at all — while §9.1's third bullet requires one at SIGNIFICANT/HIGH-RISK wherever the orchestrator authors inline, which all three do. `/create-ard` declares its gate *"(like `/design`)"*, and `/design` tests `current_model`; the copy dropped the condition.

**And where it did fire, its recommendation was impossible.** `opus_available: false` is the one state the gate reached, and in it the `(Recommended)` option was *"I'll relaunch … on Opus"* — a relaunch onto a chain the run had just established the environment does not carry, which §9.3 forbids.

All three now test `current_model`, as `/design` does, and drop the relaunch option where `opus_available` is also false, leaving proceed-on-the-floor or cancel. `docs/reference/model-routing.md` described the retired condition for all three in one paragraph and is corrected with them. The semantics are stated once, in `workflows-core` 1.6.0's §9.3, and cited here rather than restated three times.

### Fixed — `docs/getting-started.md` told a reader a renamed clone is lost to `/create-ard`, which matches no name at all (3.5.0)

Its `REPOS_PATH` section said `/create-ard` and `/idea --ground-code` *"list top-level directories under `$REPOS_PATH` and match on their **basenames**, so a repo renamed on disk is not found by those two unless the rename is also reflected there"*. Neither command resolves a repository by name on that path: both `ls` one level down, propose a candidate set and confirm it with the operator (`create-ard.md:401`, `idea.md:162`'s bare form), so a renamed clone appears under its new name and is offered like any other. What the sentence names instead is `/idea`'s **explicit** `--ground-code <repo>,<repo>` argument, whose parts must each match a top-level basename or the token is read as idea text instead — that one really does break on a rename. It is not the only basename match in `/idea`: Phase 2.6's OFF branch (`idea.md:188`) matches idea-text tokens against `$REPOS_PATH` basenames too and goes silent on a rename the same way, but the page scopes itself to `--ground-code`, so it correctly leaves that one out. A reader debugging *"why was my clone not offered?"* was sent to a remedy that changes nothing; the real causes are the directory not being where the listing looks, or `$REPOS_PATH` resolving elsewhere. Found by sweeping what this release's `docs-workflows` sibling had just corrected — the identical overshoot, one plugin over, and older.

### Fixed — six `/epics` dispatches carried no model tier, against the command's own invariant (3.5.0)

`/epics` says twice that every subagent dispatch pins its §9 chain — as a role→chain map at Phase 1.5 and as an ALWAYS invariant naming `doc-fixer` among the mechanical steps — and `docs/reference/agents.md` states the same universal for every agent carrying no frontmatter pin. Phase 7's BLOCK branch and its "Manual fix notes" resolution dispatched `doc-fixer` bare, and Phase 8 spawned its four maintenance agents — three `general-purpose`, one `workflows-core:impl-maintenance` — bare. All six now pin the §2.1 Sonnet chain, and both the `detection_model` comment and the invariant name the Phase 8 maintenance agents they had left out of their consumer lists.

*"Nothing — the pipeline reads and writes one markdown tree and calls no external service."* **Neither half survives**, and the first correction of this entry cut only the second: a consented handoff opens a pull request through `gh` (`workflows-core:phase-handoff` §2.6) and `docs-grounder` retrieves through the `qmd` CLI, while *one markdown tree* is wrong in two further directions — `$DOCS_PATH` is a second markdown tree the grounding commands read, and the clones under `$REPOS_PATH` are no markdown tree at all. The same over-claim was retired from `workflows-core:dependencies` in 1.6.0 and this is the copy one file away. The answer is now `gh`, when present, with the two read-only sources named beside it — matching the sibling `dev-workflows` page, which answered the identical question differently.

### Fixed — `/specify`'s page said its repo candidates come from PR URLs (3.5.0)

`docs/commands/specify.md` had the candidate repos *"auto-derived from the PRD's capability themes and linked PR URLs"*, and its BRD-route note contrasted `grounding/baselines.md` with *"PRD themes and PR URLs, which this route has none of"*. The command's own Phase 3 step 1 says the opposite in as many words — it builds the list from the Phase 2 capability themes and the resolved folder's `implementation.md` `repo:` entries, and *"There is no PR list to read: nothing here reads a tracker or a pull-request API"* — so the page and the command it documents were two live contradictory instructions. The page now names the implementation record.

### Fixed — `/prd-ground`'s baseline gate skipped a path `git status --porcelain` quotes (3.5.0)

Phase 1's baseline-integrity step 3 compares each porcelain-reported entry's working-tree line count against `git show <sha>:<path> | wc -l`. `--porcelain` quotes a path carrying a space, a `"`, a `\` or a non-ASCII byte, and `git show <sha>:"<quoted path>"` resolves to nothing — which step 3 reads as "exists nowhere at the pin", its own not-a-signal case. So a dirty tracked path with a space passed a gate whose whole purpose is that every `file:line` in the package cites an identifiable snapshot. The path is now read from `git -C "<repo>" status --porcelain -z`; `workflows-core:grounding-format` §4 step 3 is the authority and states why, and the readable three-command block is unchanged because `/brd-package` Part 4 hands it to the customer's reviewer to run by hand. `/brd-split`'s note on why a folder-shaped declaration stages no removal names the same `-z` form `workflows-core:phase-handoff` §2.3 now reads.

### Fixed — `/brd-intake` captures the files the customer's BRD links

Phase 2 copied `@<brd-file>` byte-for-byte into `brd/source/<basename>` and copied nothing else, and 3.5.0 shipped that. A customer's BRD routinely carries screenshots, diagrams and appendices beside it; after intake every one of those links resolved to nothing, and `brd/source/` is the immutable record every `[BR#n]` anchors into (`references/brd-format.md` §1, D11) — nothing under it is ever written again, so what intake did not capture was outside the record permanently. The run meanwhile reported a faithful verbatim copy, which is what made the loss silent. Phase 2 now copies, byte-for-byte and whatever the type, **every file the document links from its own directory**, to the same relative path under `brd/source/`, so the copied text's links resolve exactly as the customer's did with no edit to the text. The forms covered are the ones a customer's markdown uses: markdown inline images and links, reference-style definitions, and HTML `<img src>`. Each target is resolved against **the directory of the file the link sits in** and normalised as text, and is copied only where it carries no URI scheme, does not begin with `/`, lands inside the source document's own directory, and names a readable file there — that containment test being what keeps every copy inside `brd/source/` rather than above it. The capture then repeats over each markdown file it copied, to a fixed point, so a linked appendix's own links do not reproduce the loss one level down.

The test was a syntactic *"contains no `..` segment"* while this entry was first written, and it was wrong the moment the transitive pass was added beside it: `../images/flow.png`, written in a copied `appendix/notes.md`, resolves **inside** the boundary and its literal path from the copy stays inside `brd/source/`. Measured on a fixture of the ordinary export shape — a document, an appendix one directory down, and a shared `images/` folder beside it — the syntactic rule refused six links whose targets were all in scope, lost `appendix/diagram.png` outright, and wrote `outside the source directory` into the log about files the copy in fact holds; the containment rule refuses only the four that genuinely are a URL, an absolute path, an escaping `../`, or a missing file, and the no-edit invariant holds under it because the copy mirrors the source tree's own layout.

**What could not be captured is named rather than dropped.** A new `brd/brd-link-log.md` carries the source document's basename, the run's counts, and one row per uncopied link — the target as written, the file it sits in, and one of four reasons (above the source document's own directory, an absolute path, a URL, unreadable) — and the final report says the same. It is written on every run, including one that captured everything, so its counts are the positive record that the capture ran. It is the **plugin's** record, not the customer's, which is why it sits in `brd/` beside `brd-inventory.md` and `brd-defect-log.md` and never under `brd/source/`, where every byte is the customer's own. `references/brd-format.md` gains §1.1 as the authority for all of it, Phase 7's `deliverable_paths` enumerates the copied files and the log, and `brd-reader` is told the linked files sit beside the source so a link is not a dead end — it still reads only `source_path`.

One consequence is worth stating because a reader will meet it: `brd/source/` can now hold more than one markdown file, so **which file in it is the customer's document is read, never guessed** — `brd/brd-link-log.md`'s opening line names it, and a BRD intaken before that log existed holds exactly one file there. `brd-format.md` §2.1 says so where it fixes the `source:` header a slice's inventory carries, which is the one place that name is re-derived. What a screenshot *means* to the requirements — a `[BR#n]` anchored to an image, the defect walk reading one, grounding against one, a package returning one — is not in this release; this is capture and fidelity only.

**Why this is 3.6.0 and not 3.5.1.** The run writes files it did not write before — every in-directory linked file, and the link log — so the artifact set a consumer sees is larger, which is added behaviour at the plugin level rather than a repair that leaves the output unchanged.

### Fixed — the workflow diagram renders again

`docs/workflow.md`'s mermaid diagram failed to render on GitHub — `Parse error on line 42 … got 'SQS'` — and had since 3.0.0, when the `/prd-ground` edges were drawn. Five edge labels carried a bracketed requirement ID (`[BR#n]`, `[CG#n]/[DG#n]`, `[AC#n]/[FR#n]`) unquoted, and inside a mermaid edge label `[` opens a node shape. Each label is now quoted (`-->|"…"|`). The diagram parses under mermaid 10.9.8, 11.17.2 and 12.0.0, and renders. No gate checked mermaid syntax, which is how it shipped; the repository's CI now runs `scripts/mermaid/check-mermaid.mjs`, which parses every diagram in every tracked markdown file outside its own fixture tree, `scripts/fixtures/mermaid/`, on each push.

### Changed — a count the `docs-workflows` cold-start increment moved

`commands/create-prd.md` Phase 0 called this command *"the only one of the **twenty-six** `commit-artifacts` callers running no preflight"* — true in 3.5.0, and moved to twenty-eight by `docs-workflows`' `/docs-init` and `/docs-brand`. It is a runtime instruction an installed user reads, not a documentation page. The count was doing no work in a sentence that is a historical note about a past defect, so it is **removed rather than corrected** — the claim it makes is about being the only one, not about how many there are.

### Fixed — `bundle-packaging.md` no longer miscounts `specs-repo-git.md` §2.1

`references/bundle-packaging.md` said `specs-repo-git.md` §2.1 *"bounds staging to three path shapes, all of them under `dev-workflows/**`"*. §2.1 named six in `workflows-core` 1.5.0 — three directory shapes and three single files, the files sitting beside a feature folder's artifacts rather than under `dev-workflows/**` — and names nine in 1.6.0, its fourth directory shape, `documentation/<docs-repo-slug>/…`, not under a feature folder at all. Like the count above, it is read at run time. Restated as "a fixed, enumerated set of path shapes", which is what the paragraph's argument actually needs — the point is that a bundle matches **none** of them, not how many there are.

### Fixed — the documentation route's gaps draft is named as it is written

`references/code-defect-log-format.md` cites `workflows-core:source-truth` §7.5 as the family's sibling code-defect record and named its draft `implementation-gaps.md`, the name §7.5 itself carried. `docs-workflows` writes it as `<KEY>-implementation-gaps.md`, which is what §7.5 now says too, so a reader sent to the documentation route looks for the file that exists.

### Fixed — the grounding agents read the repository they were handed

A subagent's Bash tool starts every call in the session's directory — where `/prd-ground` stands — and a `cd` does not persist between calls. `code-grounder` wrote its three read primitives bare (`git show <commit>:<path>`, `git grep -n <pattern> <commit>`, `git ls-tree -r --name-only <commit>`) beside a citation of `workflows-core:read-only-repos` §4, where they carry `-C`; run from the session's directory they exit 128, the pinned commit not being there. `grounding-verifier` named `baseline-integrity`'s three steps as bare `rev-parse HEAD`, `diff --stat` and `status --porcelain`, which would compare the pin against the session's `HEAD`. Both now write `git -C "<repo_path>"`, and each is told why and to give `Grep` and `Glob` the handed root as their path. Where a call runs in the repository instead, it is a `(builtin cd "<repo_path>" >/dev/null && …)` subshell, so a `cd` function or alias of the user's, which the Bash tool's shell carries, neither runs in its place nor prints into what the agent reads.

### Fixed — `/epics`' claims file template ends in `XXXXXX`

`/epics` named the file it hands `epic-reviewer` as `claims_file` with `mktemp -t dw-epics-claims-XXXX.md`, a template BusyBox's `mktemp` — the one Alpine ships — rejects with *mktemp: Invalid argument*, since it takes a template only where it ends in six `X`s (BusyBox 1.36.1; GNU's accepts it). It is now `dw-epics-claims-XXXXXX`, which GNU, BusyBox and BSD `mktemp` all accept.

### Fixed — `/create-prd` no longer says `/release-notes` asks for the category label

Phase 3's frontmatter step, and the command page, did not ask for `release_notes_category`, on the ground that `/release-notes` "infers and confirms `change_type` and `release_notes_category` in its own grill". That command uses the label verbatim where the PRD carries one and otherwise omits it, never inferring or asking; so a PRD whose release notes should carry a label must carry the field. Both now say that the field is optional, that `/release-notes` infers `change_type` and confirms it only where the inference is uncertain, and that it takes the release from `--version` or its grill, never from the PRD's `release_versions`. The step still asks for none of the three, and still writes whichever the operator volunteers.

### Fixed — `/update-prd` no longer names the import it retired

Phase 0 step 4 says the base PRD is the resolved folder's own `prd.md`, and that the ladder which read an imported copy, stopped when none existed and offered a refresh past three days is gone. Yet Phase 7 still listed `not-imported` among the environment halts that must never raise a plugin-feedback block, and asked `impl-maintenance` for "import/freshness friction" among the run's key events, so both the reader and the maintenance handoff were told to expect a halt and a check the command no longer has. The invariant now names the halts it does have — a key whose folder does not resolve, or holds no `prd.md` — and the handoff asks for BLOCK reviews and unresolved clarifications.

### Fixed — no command says it never commits in a working directory that is the specs repository

`/idea`, `/specify`, `/epics`, and the BRD route's `/brd-intake`, `/brd-split`, `/prd-ground`, `/brd-interview`, `/brd-package` and `/brd-reconcile` said their terminal `commit-artifacts` step "NEVER touches" the current working directory, and `/epics`' invariants that it never commits "anything in the current working directory". Where the session stands inside `$SPECS_PATH`, that step commits and pushes in the working directory's own repository. Each now says so only where the working directory is not the specs repository.

### Fixed — no command says it never writes into a working directory that is the specs repository

All fourteen commands said their final phase "NEVER writes into" the current working directory — `/specify` and `/epics` said it of their feedback phase too, and `/epics` of its follow-up phase — while the `/prd-proposal` and `/brd-proposal` pages said each writes "nothing in your current working directory" and the session-cost page that the plugin "never writes into your current working directory". Where the session stands inside `$SPECS_PATH`, those phases write their feedback, follow-up, cost and resume files into the working directory's own repository. Each now makes the claim only where the working directory is not the specs repository. The session-feedback page's sentence, which speaks of a run where nothing resolves and so nothing is written, holds as written.

### Fixed — a run removes the temp files it made

`/epics` wrote `epic-writer`'s handoff file at Phase 6 and, on a BLOCK verdict, `doc-fixer`'s Fix Report at Phase 7, both to `mktemp` paths outside every repository and outside the specs tree, and nothing removed either: every run left them under the system's temporary directory, where no later phase and no later run looks. Phase 8 now removes both — `command rm -f -- "<path>"`, so an `rm -i` or `rm -I` alias of the user's cannot answer the prompt from an empty standard input and leave the file — and a run that stops before Phase 8 removes what it had made.

### Fixed — `/epics` creates its temp files with `command mktemp`

`epic-writer`'s handoff file (Phase 6) and `doc-fixer`'s Fix Report (Phase 7) were named with a bare `mktemp`, which the Bash tool's own shell resolves through any alias or shell function of that name before `mktemp` runs — so the path the run writes to and hands on is whatever that printed. Both now run `command mktemp`, the rule `dev-workflows:context-management` states.

### Fixed — `/create-prd` says when `/release-notes` settles `change_type`

The Phase 3 frontmatter step and the command's page both said `/release-notes` infers a type "where the PRD carries no `change_type`". It also infers one for a value that is present but not routable — `not applicable`, or `Bug fix` on a deprecating change (`docs-workflows:release-note-types` §7) — so both now say "no **routable** `change_type`".

## [3.5.0] — 2026-09-09

Five open defects from a live-engagement defect register, found running the family across two
customer engagements.

### Changed — both grounders are pinned to Opus

`code-grounder` and `design-grounder` carried no model pin and `/prd-ground` dispatched them on the
Sonnet detection chain. **Grounding adjudicates** — it decides whether a claim is true of a commit —
and detection is what `code-scanner` does. The measurement: blind re-derivation of a Sonnet-ground
corpus found **18 of 18 code-citing findings defective** (nine `contradict`, seven `extend`, no
`agree` at all), with a second slice near 50% verdict error. An Opus-ground corpus of 314 findings
still moved 85%, but mostly by *omission* rather than error — so the tier is a real and separable
cause and not the whole cause, which is why the pin ships beside `control` rather than instead of it.

Both are now frontmatter-pinned, like every reviewer. `workflows-core:docs-grounder` deliberately is
not: it **retrieves**, and a missed lead costs a lead. `/prd-ground` reports `ground_tier` on every
run, not only a degraded one, because a reader cannot otherwise tell an Opus corpus from a degraded
one and the two are not interchangeable evidence.

The standing cost objection is answered rather than dismissed: cheap and wrong grounding is the more
expensive option, since a corpus in which every code-citing finding is defective has negative value
and the cost is deferred and multiplied through verification, reconciliation and the human reading
the result. Where the spend is unacceptable on a given run, make the pin conditional on
classification rather than reverting it.

### Added — every absence claim carries a positive control

Both grounders emit `control` (`workflows-core:grounding-format` §2.2) wherever a finding asserts an
absence, and `code-grounder` gains step 4a and a hard rule for it. `design-grounder` carries it on
**class 2** — a requirement asks for a field no frame shows — which is an absence over a frame set
and fails the same way: the field may be there and this reading may not be one that finds it. Classes
1 and 3 resolve against the `inventory` the caller handed the agent, which is a lookup rather than a
search and so has nothing to control for; class 4's code half is the cited `[CG#n]`'s own search.

`grounding-verifier` is handed the field and **runs** the control rather than reading it, returning
`control_outcome`. It settles **owed-ness first**, by §2.2's closed-set rule: a negative over a set
the caller handed in is a lookup, not a search, so classes 1 and 3 owe no control and class 4's code
half belongs to the cited `[CG#n]`. Only class 2 — a negative over the frame set, which is read —
owes one. A `missing` control forces `contradict`; a `failed` one does too, **except** on a finding
already reading `NOT-PROVABLE` with that failed control recorded, which is what §2.2 tells a writer to
do and which the verifier is merely reproducing.

### Fixed — a class-4 `[DG#n]` is no longer left standing on a citation that moved

`/prd-ground` Phase 7 sweeps every class-4 finding whose cited `[CG#n]` this run rewrote and
re-derives the pair — **reading the `[DG#n]` set from `design-grounding.md` rather than from what the
run happens to hold**, since a `--no-design` run produces no `[DG#n]` at all while still rewriting
`[CG#n]`, and a sweep over held findings would report "none" on precisely the run that created the
staleness; Phase 8 supersedes class-4 findings alongside the `[CG#n]` that took them there
on a `--rebaseline` pass. Previously a design finding could keep a verifier outcome earned against a
version of its citation that no longer existed, with the id still resolving and the claim ids still
matching — undetectable by a reader who follows the citation.

### Added — a customer-answerable question from `/create-prd` reaches the customer

PRD authoring surfaces questions nothing before it could have — a scope boundary the requirement text
never drew, a rule the acceptance criteria need and nobody stated. Some are settled only by an
authority the customer holds, and they landed in `prd.md` under `## Assumptions & open questions`,
**which the customer never receives**. Every later reader then met them as flat statements in a
document full of grounded ones: read as settled, built on, argued from, while the one party who could
have corrected them in a sentence never saw the file.

The route back already existed and nothing pointed at it. `/create-prd` now triages each surviving
gap by `interview-tagging.md` §2's test — what kind of thing would settle it — and writes a
customer-authority one as an `[AS#n]` in `decisions.md`, which `/brd-package` surfaces (every open
one, twice) and `/brd-reconcile` supersedes with the answering `[CD#n]`. **Writing the record is not
asking the customer anything**: no `[CD#n]` is written here and none may be (D14).

`decision-register-format.md` §7 gains the second writer and the rule that **such a record omits
`round` entirely**. Giving it the last closed round's number would claim it was in front of whoever
answered that round; giving it any invented value is worse, because `round` is **read**, not just
displayed — `/brd-package` derives the set of rounds a BRD has from the distinct `round` values across
its records and then requires an `interview/round-<N>.md` for each, so a value no round record answers
to would make the slice permanently unpackageable. That command's derivation now says explicitly that
a record carrying no round contributes nothing to the set, and that this is the only reason a record
legitimately omits the field.

`/create-prd`'s third write guarantee is narrowed and the narrowing itemised rather than made
silently: it protected a settled decision from a grill answer, and it now says so over *existing*
records, leaving this command free to create one new `[AS#n]` — never a `[VD#n]`, never a `[CD#n]`.
Ids continue from the highest on file and a gap already recorded is not recorded twice, because the
sanctioned fresh-PRD re-run puts this command over the same folder more than once.

### Added — two checks over what a run restates, both measured against real packages

Two verification gaps the register named, built the second time against assembled artifacts rather
than against the format documents. The first attempt at each was cut before release because both
fired on **correct** trees; every relation below is narrower than its obvious form, and each
narrowing is a false positive somebody would otherwise have met.

**`/brd-package` — `bundle-packaging.md` §7, `set-resolution`.** The manifest, the delivery note and
several prompt parts each restate a set held elsewhere, and nothing compared them. Three relations,
comparing **membership** and never counts, since two sets of the same size with different members
read as correct. What measurement changed: the review-scope part renders its source as **prose in the
customer's vocabulary**, not identifiers, so relation 1 reaches only the parts that genuinely
enumerate identified records; a manifest writes filenames **with or without the extension** — both
conventions occur across builds of one package — and names images only sometimes, so relation 2
matches basenames tolerantly, excludes the manifest and non-review markers, and leaves images to §6;
and a delivery note **abbreviates** its commits, so relation 3 tests each as a **prefix** of a
baseline rather than for equality. An equality test reports every correct note as carrying no pin.

**`/brd-intake` — `brd-format.md` §2.2.** A section the read skipped and one that genuinely holds no
obligation look identical in an inventory. Two relations, both derived from the `source_anchor`
column already written: every anchor resolves to a section the source has, and every **top-level
section** either holds a row or is accounted for. **No agent returns a new field and nothing new is
stored** — the first design added one and persisted it nowhere. Granularity is the finding: real BRDs
carry fifty to sixty headings under about fifteen top-level sections, nine of which legitimately hold
nothing, so the operator answers nine questions rather than fifty. On a real package the sections
holding no row included the user stories and the acceptance tests — the pair worth asking about.

### Added — a recorded review verdict names the version it was taken against

`/create-prd`, `/update-prd`, `/create-ard`, `/specify`, `/epics`, `/prd-proposal` and
`/brd-proposal` cite the new `workflows-core:escalation-rules` rule. The one-fix-cycle cap assumes a
fix only removes defects; three live runs saw the fix introduce something the re-review then found
with the budget already spent, leaving a `PASS` on record beside a file the `PASS` never saw.

## [3.4.0] — 2026-09-08

### Added — two effort-proposal commands, and the format they author against

- **`/prd-proposal <ADDRESS>`** authors a customer-facing effort proposal for one `PRD-` folder — an
  idea-route PRD or a BRD-route slice, since a `PRD-` folder is a `PRD-` folder either way. It writes
  `proposal.md` and, at tier 2 and above, `proposal-brief.md`: work packages clustered by delivery
  seam, hours by package and role, and a range whose width is computed bottom-up from per-package
  confidence. Flags: `--no-brief`, `--profile`, `--baseline <path>`, `--redo`.
- **`/brd-proposal <ADDRESS>`** rolls a `BRD-` container's slice proposals into one programme
  umbrella — one row per included slice, read out of that slice's own proposal and never re-derived;
  the cross-slice effort that exists in no slice; and a coverage statement computed from the root
  `coverage-ledger.md`, with the remainder enumerated by identifier. Its natural altitude is the
  root, which inverts the rest of the BRD route: it refuses a slice, where `/prd-ground`,
  `/brd-interview`, `/brd-package` and `/brd-reconcile` each refuse a root. The roll-up is not a sum:
  each of its three adjustments — umbrella effort, de-duplication where two slices cite the same
  finding identifier, and peak concurrency rather than summed FTE — is named in the document rather
  than absorbed into a total.
- **`references/proposal-format.md`** is the authority both commands author against and
  `proposal-reviewer` checks: the section sets of both artifacts, the `[WP#n]` work-package and
  `[ED#n]` estimate-driver namespaces, the readiness tiers, the confidence grades and their default
  bands, the closed evidence set, and — in §14 — what the umbrella adds over a slice's own proposal.
  `docs/reference/proposal-format.md` documents the same subsystem from the reader's side.

### Added — readiness is graded, never gated

- **Neither command requires an ARD or a specification.** What those artifacts change is the
  **readiness tier** printed in the header beside the date — 1 · Indicative (the PRD alone),
  2 · Grounded (verified grounding plus a settled decision register), 3 · Architected (`ard.md`),
  4 · Specified (`specification.md`). Grading replaces the gate that would otherwise have stood here,
  which is the whole answer to when a requirement set becomes estimable. The only hard refusal on
  readiness is each command's own `require-on-main` gate on its input.
- **The tier is a ceiling on confidence and never sets it.** Tier 1 caps every package at Low, tier 2
  at Medium, tier 4 at High, and tier 3 at High only for a package an `[AD#n]` covers; confidence
  itself is computed from the evidence each package actually has, and evidence can only push a
  package lower. A tier-1 proposal is still a real document — it simply says outright that its cost
  drivers are not known.

### Added — what a cost driver may cite, and what happens when it cites nothing

- **A closed set of three evidence classes**, each resolving to something on disk an independent
  reader can open: a verified grounding finding (`[CG#n]`/`[DG#n]`, carrying its verifier outcome,
  cited with the `file:line` the finding records), a frozen decision (`[VD#n]`/`[CD#n]`), or a
  confirmed code defect (`[CDF#n]`). The narrowing is per driver: one making a claim about the code
  cites the first class, because a decision cannot evidence a statement about a repository.
- **A driver citing nothing from that set does not render at all**, and the run names every candidate
  it dropped. The value of the rule is that it is mechanically checkable rather than a matter of
  authorial care.

### Added — the defect-remediation package, and why it is never a lever

- **Where the folder records an unrepaired code defect, its repair becomes its own `[WP#n]`
  automatically**, swept from three sources and unioned: every `[CDF#n]` in `code-defect-log.md`
  whose disposition is `open`, `in-scope` or `conditional` (no confirmation needed — a standing entry
  is one somebody already adjudicated), a verified grounding finding whose own text records a defect,
  and an `[SR#n]` self-review finding in the packaged bundle dispositioned `accepted-risk` or
  `escalated-to-customer`. The last two need operator confirmation, because neither is a defect
  *register*.
- **The first source names the three dispositions it admits rather than filtering on *unresolved*.**
  That vocabulary has no value meaning resolved, so a filter phrased that way would admit all five.
  The two it leaves out are left out for opposite reasons: `withdrawn` means the intent basis was
  wrong and there was never a defect, while `out-of-scope` **is** unrepaired and is excluded anyway,
  because its repair is recorded and deliberately not this engagement's work — neither may be priced
  into a mandatory scope the customer is then forbidden to decline.
- **It never renders into the scope-lever or priced-options table.** Where it cannot fit the delivery
  window, that is disclosed as a schedule fact. Asking a customer to authorise deferring a defect the
  vendor's own work found would return that deferral carrying the customer's authority on a question
  the vendor's policy has already answered.

### Added — the rationale brief, and why it is withheld below tier 2

- **`proposal-brief.md` is derived from the same resolved data set as the proposal**, never
  re-authored from it, and its spine is the driver argument: the naive baseline, why the number is
  not that, and what the largest share of the estimate is owed to. It also carries the corrections
  this revision owes the customer, each deliberately-unpriced item with the gate that will price it,
  and what is needed before week 1.
- **It does not render below tier 2 irrespective of `--no-brief`**, because below tier 2 that spine
  does not exist. A two-page pre-read explaining why a number is large, written when the reasons are
  unknown, is the one artifact this format must not produce. The final report says which of the two
  reasons applied.

### Added — `proposal-reviewer`, the review gate both commands dispatch

- Opus-pinned by frontmatter with no override, dispatched with both artifact paths, the profile, the
  resolved tier and the anchor revision where one exists. Its findings are triaged by the
  orchestrator before anything is edited, per `workflows-core:finding-triage`.
- **Its arithmetic check is the reason the agent exists**, and it is the one check that cannot be
  delegated to judgement: it re-adds every column and every row of the `[WP#n]` × role grid — the
  Expected column first, then Low and High **independently**, because the Low and High columns each
  summing to the stated range is the relation a reader is least likely to re-add and exactly where a
  silent error survives — checks that every package's range brackets its own expected figure, and
  compares every band against its confidence grade's default within the one-percentage-point
  tolerance whole-hour rounding needs.

### Added — the no-money rule

- **Neither artifact carries money at all** — no rate, no currency symbol, no monetary total for
  human hours, at any tier and under any flag. Rates are contractual and belong in a document this
  pipeline does not produce, and a git-committed rate card is a disclosure waiting to happen. Note
  the collision this rule exists to prevent: `workflows-core:cost-emission` already records a
  quantity called **cost**, and it is USD of model spend for a run. The two are unrelated, and no
  sentence in either artifact lets a reader take one for the other.

### Added — what these commands do *not* do, stated because it is the property most likely to be misread

- **Neither command gates anything downstream, and nothing on the build ladder waits on either.** No
  command of that ladder reads a proposal: `/create-ard`, `/specify`, `/epics`, and the `dev-workflows`
  commands below them each resolve the same folder and neither know nor care whether it holds one.
  No readiness tier withholds permission to begin work. **The one reader is the sibling umbrella
  `/brd-proposal`**, which runs `require-on-main` on each included slice's `proposal.md` in order to
  roll it up — a gate that stays inside the pair, on a second proposal rather than a phase of the
  build.
- **Neither resolves documentation grounding**, and neither takes `--no-docs`. An estimate's inputs
  are the specs tree and the profile; a documentation page bears on how a feature is described rather
  than on what it costs to build. There is no flag to turn off and no `docs grounding:` line in
  either report.
- **Neither opens a code repository.** Every commit a grounding finding cites was pinned by
  `/prd-ground`, and these commands read the finding rather than the repository.

### Changed — a `/brd-*` glob that stopped meaning "the BRD-to-PRD route"

`/brd-proposal` matches `/brd-*` without being a phase of that route, so every claim written as a
glob over the family had to be re-read against it. `coverage-ledger-format.md` §6 said *"every
`/brd-*` command's final report ends with"* the ledger line; `/brd-proposal` prints no such line —
it reads a container's ledger only to compute the coverage statement inside the document it writes.
§6 now states the route as the test and records why the glob is not, and the three pages that cited
it (`docs/commands/brd-intake.md`, `docs/commands/prd-ground.md`, `docs/roles-and-phases.md`) follow
it. `commands/create-prd.md`'s refusal cites the same convention by route rather than by glob, and
`commands/brd-intake.md`'s opening no longer describes what "the `/brd-*` commands between them"
do. The prefix claims are untouched and stay glob-shaped: `brd` genuinely is the branch prefix every
`/brd-*` command shares, `/brd-proposal` included.

## [3.3.3] — 2026-09-08

### Fixed

- **`/brd-reconcile` reaches a dependent BRD's `code-defect-log.md`.** A `[CDF#n]` declares its
  dependency by a field — `blocked_on: <BRD-KEY>/<decision-id>` — exactly as a decision does with
  `conditional_on`, but the propagation sweep walks decisions and `[AS#n]` only, and the stale
  cross-reference sweep stopped at the parent's folder. Inside the parent the log was always swept;
  outside it, a defect blocked on a decision that had just moved was reached by neither. The stale
  sweep's **first** search — the literal-id one — now also runs over the propagation sweep's
  already-resolved dependent set. No new traversal and no new outcome: a hit keeps `needs-a-human`,
  because every disposition on that log is the operator's.
- **The write surface deliberately did not move with it.** Outside the parent's folder the only
  outcomes are `still-true` and `needs-a-human`, never `updated`, and the second search — the prose
  one — does not follow at all: it cannot be reduced to a pattern and needs a reader who knows what
  the old position claimed. Two claims moved in the same change rather than being left to go stale:
  the sweep's opening now says the parent root bounds everything except search 1, and the guard's
  *"why this sweep's root being the parent's folder is safe"* became **writing root**.

## [3.3.2] — 2026-09-08

### Removed

- **`/create-prd` no longer captures `relevant_for_release_notes`**, and no longer asks to confirm a `no`.
  It asked a question with one answer — every PRD is relevant for release notes — so the only value it
  could carry that changed anything was one nobody should write.

## [3.3.1] — 2026-09-08

### Fixed

- **`/create-ard` and `/specify` no longer fall back to a key-globbed PRD filename at the `require-on-main`
  gate.** The fallback matched nothing on a current tree, and on the pre-rename tree it was written for it
  also matched that tree's ARD (`<KEY>_ARD.md`), so the PRD gate could gate the wrong artifact. Both now
  gate `prd.md`, the only name the plugin writes — correct on a current tree, and `absent` on a pre-rename
  one, which is what `workflows-core:addressing` §5 now tells that operator to fix.
- **`/create-prd` step 6 no longer claims a pre-rename `<KEY>_<slug>.md` is identified by `kind: prd`.**
  That field arrived in the same change as the rename, so no pre-rename file can carry it and the branch
  could never recognise the file it had found.

## [3.3.0] — 2026-09-08

### Added — `code-defect-log.md`, a route-local register for what `/prd-ground` finds broken in the code

`/prd-ground` spends its whole effort reading code at pinned commits, and routinely establishes that the code is broken — an active regression, a missing index the code assumes, a write path that never sets a column — and the route had nowhere to put that. `references/brd-format.md` §4's `[DEF#n]` log is for **requirement** defects only, so the fact landed in a decision's `argumentation`, and two instances in one shipped register asserted a defect *"is recorded"* while nothing held one, surviving drafting, the round record, and a first adversarial review.

The new `references/code-defect-log-format.md` fixes the `[CDF#n]` record: `id`, `statement`, `behaviour` (exactly one **verified** `[CG#n]` in this BRD's own `grounding/code-grounding.md`), `intent`, `intent_basis` (a `file:line`/document pointer, or the literal `operator-judgment` followed by the reasoning), `disposition`, and `blocked_on` (required only when `disposition: conditional`). Five dispositions, mirroring `decision-register-format` §3: `open`, `in-scope`, `out-of-scope`, `conditional`, `withdrawn`. **There is no `fixed` disposition** — nothing on the BRD-to-PRD route builds anything and no command can observe a repair; `withdrawn` means the intent basis turned out to be wrong, not that the bug got fixed, and using it for a repaired defect would put a false statement in the log.

`/brd-interview` is the **only** writer, at two points that already exist — Phase 6 raises an entry, held for the register phase exactly as a `[VD#n]` is; Phase 9 writes `code-defect-log.md` alongside `decisions.md` and the round record; Phase 10 adds the path to `deliverable_paths`. `/prd-ground`, which does the actual code reading, is deliberately **not** a writer, for a cost reason rather than a preference: its Phase 7 verifies every finding through `grounding-verifier`, and a defect entry emitted there would need its own verification contract and a change to the `code-grounder` agent; an entry raised at interview time cites a finding that is already verified and adds only the intent basis, which is the operator's judgment either way.

### Added — `defects:`, a twelfth field on the decision register

`decision-register-format.md` §1 gains `defects:`, listing the `[CDF#n]` ids a `[VD#n]`, `[CD#n]` or `[AS#n]` turns on, omitted when absent. It is deliberately **not** `evidence`: §6's will-change rule inspects the `evidence` list alone, firing when every finding in it carries `horizon: will-change`, and a `[CDF#n]` mixed into that list would silently change what the rule fires on. §7's per-field accounting grows from eleven rows to twelve to match, so a twelfth field is never one an author has to settle for themselves.

### Added — the log ships in the customer bundle

`bundle-packaging.md` §1.1's allow-list gains `code-defect-log.md`, and three dispositions map onto three prompt parts that already exist — `in-scope` to part 6 *Review scope*, because a defect disposed `in-scope` **is** the delivery boundary: the repair has to happen inside this PRD's scope or the feature cannot be delivered; `conditional` to part 8 *What could still move*, beside the `conditional_on` positions that part already carries; `out-of-scope` to part 11 *What this session cannot settle*. Shipping it also buys §3's evidence rule a mechanical check for free: `behaviour: [CG#12]` now sits in a bundle document, so it resolves against the partition's own shipped `grounding/code-grounding.md`, and an entry citing a finding that does not exist stops the packaging run with `BRD_PACKAGE_DEAD_CITATION`. Every entry ships, including `out-of-scope` and `withdrawn` ones — but seeing is not deciding: the operator settles every disposition exactly as before, a code defect never becomes an `interview-tagging.md` `[V]` or `[C]` question, and a customer who disagrees with one pushes back through the returned review, which `/brd-reconcile` already reads.

### Added — `brd-package-reviewer`'s sixth hunt class

Class 6, *"an argumentation that asserts a defect nothing holds"*: for every `[VD#n]`, `[CD#n]` and `[AS#n]`, the reviewer reads `argumentation` for a claim that a code defect is recorded, raised, or known, and checks the record's own `defects` list — a claim with nothing behind it is a finding. This is the class that catches the exact failure the design started from. It stands in for the prose-trigger check the design's §8 considered and **deliberately did not build**: the tree carries no corpus of real registers to measure a phrase-matching check against — the two `argumentation:` examples in the whole tree are both illustrative, both inside `decision-register-format.md` itself — so an unmeasurable pattern was left to the reviewer's judgment instead of shipped as a static check. What did ship at write time is a structural offer rather than a pattern: `/brd-interview` Phase 6 offers to raise a `[CDF#n]` exactly when a decision's `evidence` holds a `REWRITTEN`, `AMENDED` or `FALSE-FRIEND` finding — the three verdicts meaning grounding found the code does something other than claimed — reading the trigger off the record rather than out of prose.

## [3.2.0] — 2026-09-08

### Fixed — the package told every reviewer to extract an archive, including the ones who pull the repository

`bundle-packaging.md` §5 has always said the committed bundle serves **both** delivery routes — a customer with repository access pulls it, everyone else gets an archive command. Nothing recorded which route a given package was taking, so every other site assumed the archive — across the command, the reference and the documentation. Two of them were not statements about delivery at all but *justifications* that happened to name an attachment: rule 4's argument for filenames over paths, and the delivery note's 200-word ceiling. Both rules are right on either route; only their reasons were half-stated, and rule 4's mattered — naming only the archive case read as though a committed bundle could safely be addressed by path, which is the one reading that breaks rule 1 for the route now recommended.

The sharpest was in the customer's own prompt. Part 1's input table listed *the archive command* among what the prompt is filled from, and its OS note opened *"extract the archive to a real folder before pointing anything at it"* — so a customer who pulled the specs repository received a shell command for an archive nobody sent them, and an instruction naming a file they did not have, in the one document whose entire job is to be followable by somebody with no context and no plugin. That is the failure the de-Obsidianising pass exists to prevent — an instruction that looks actionable, is not, and gives the reader no way to tell which — reached by a different route.

**The prompt now names no delivery route at all, and the delivery note names the actual one.** The two have different readers, and that is what settles which may assume anything. The note is a covering letter to a named customer whose situation the operator knows; the prompt is handed on — to a colleague, to an agent, to whoever actually does the review — so a prompt that names a route is wrong for some of its readers about the first thing it tells them. The archive command is gone from the prompt entirely: assembling an archive is a delivery-team action, and a reviewer who was sent one has already had it done for them.

**The route is settled once, at the delivery note, and half of it is derived rather than asked.** The repository route exists only where the *Handoff* phase's consent choice was accepted — a bundle on no ref is a bundle nobody can pull — so where the handoff was declined the run takes the archive route without asking and says why. Where it was accepted the run asks, recommending the repository route. On that route no archive command is produced, and the note carries the repository, the committed `bundle-<YYYYMMDD>/` directory by path, and the instruction to open the prompt there and paste it.

**One constraint that survives the change and is worth stating, because it looks like an inconsistency:** even on the repository route the *prompt* must not name the specs-repo path. `bundle-packaging.md`'s own rule 1 holds that a path is correct exactly once, in the directory layout one machine had — so the note carries the path and the prompt carries filename search. The note tells the reviewer where to stand; the prompt works once they are standing there.

The Final report now names the route and why, on both branches, so a reader cannot mistake an absent archive command for a step that failed.

## [3.1.0] — 2026-09-08

### Added — `bundle-packaging.md` §6, a citation-resolution check over the assembled bundle

The plugin-free scan (§1) deliberately exempts identifiers — `[BR#n]`, `[CG#n]`, `[DG#n]`,
`[VD#n]`, `[AS#n]` and `[SR#n]` are how a returned review cites the package's own claims without
minting identifiers of its own — but nothing then checked that they land. `/brd-package` Phase 8
now runs a second pass over every document in the finished bundle, testing three relations: every
identifier reference resolves inside its own source package's corpus for its class, unless it
carries the owning BRD key at the point of use — in the prose form `<BRD-KEY> [CG#7]`, or inside a
structured field whose format another authority fixes and which that authority defines to name
another BRD's record, such as the register's own `conditional_on: <BRD-KEY>/<decision-id>`; those
fields are derived from the authorities that own them, not listed in §6, and the check reads them
rather than refusing them; a class-4 `[DG#n]`'s `cites` resolves within the
same partition and names the same requirement as the citing finding's own `claim` (the correctness
half of `workflows-core:grounding-format` §6.3's rule, added there in 1.3.2); and a bare
`<name>.md` token names a document actually present in the bundle.

Two exemptions, both principled rather than convenient. `[SR#n]` is exempt entirely — the
self-review file it would resolve against is excluded from the bundle by rule, and the `[SR#n]`
content a customer may see reaches them filtered through the prompt, never through the file
itself, so without this exemption the check would fire on every package the command ever builds.
And a hit inside the customer's own source document reports rather than stops, for the identical
reason the plugin-free scan already treats that file that way: it is copied byte for byte and
immutable by rule, so a hard stop would make that BRD permanently unpackageable.

Three stops: `BRD_PACKAGE_DEAD_CITATION` for a reference that resolves to nothing;
`BRD_PACKAGE_CITATION_MISMATCH` for one that resolves, but to a finding about the wrong
requirement; and `BRD_PACKAGE_CORPUS_UNREADABLE` for a corpus file that holds record-shaped
content and still parses to zero ids of its class, so a parse failure is never reported as an
absence. A corpus holding no record-shaped content is a legitimately **empty** corpus and passes —
a `design-grounding.md` written as a short note because design grounding was skipped, and a defect
log whose walk confirmed nothing, are both ordinary and neither is a parse failure.

**The honest consequence: relation 2 will refuse bundles that ship today.** A parent BRD's
verified findings, hand-narrowed onto a slice, is common enough that the first run against an
existing slice may stop on a mismatched `[CG#n]` citation. The repair is by hand, because the
plugin has no supported mechanism for narrowing a parent's findings to a slice's claimed subset —
that gap is a separate, already-tracked item, and this check catches a broken citation regardless
of how it got there, which is the point of checking at delivery rather than at authoring.

**One limit the design accepted.** An unkeyed bundle document — one that reached the bundle
without the `<BRD-KEY>`-carrying filename `commands/brd-package.md` rule 1 requires — is reported
rather than guessed at: §6 has no partition to place it in, so it names the document and stops
with `BRD_PACKAGE_DEAD_CITATION` rather than assigning it to a corpus by inference.

This is a minor bump, not a patch: the check can refuse a bundle a 3.0.0 run would have shipped,
which is a behaviour change a user will meet.

## [3.0.0] — 2026-09-08

### Changed (breaking) — `/brd-ground` renamed to `/prd-ground`

Every fully-qualified invocation, docs page, and cross-plugin citation must use
`/product-workflows:prd-ground`; `/brd-ground` no longer exists. The rename is taken now because
nothing has published — `product-workflows` does not exist on `origin/main` at all — so it costs
installed users nothing extra, and after a release it would have been a breaking change against a
name people had learned. It is called out as breaking anyway: a removed command name is breaking
however unpublished the plugin is, and the version is the one place a reader looks to find out.

**The rule that bounds it, so a future reader does not rename three more commands on the slice
argument.** `brd-` names the **route**, not the folder kind. Four of the six route commands refuse a
root — `/prd-ground` (`PRD_GROUND_ROOT_LEVEL`), `/brd-interview`, `/brd-package` and
`/brd-reconcile`, each with its own `*_ROOT_LEVEL` stop — so "runs on a slice" is the wrong test for
which one renames: `/brd-intake` and `/brd-split` are route commands that genuinely run at root, and
interviewing, packaging and reconciling exist only because a customer handed over a BRD — the slice
they run on is a slice *of* one, and none of them will ever run anywhere else. `/prd-ground` is the
only one of the six that **leaves the route**: after this release it runs on an idea-route PRD folder
with no BRD anywhere in its ancestry, where `brd-` was not merely imprecise but false. That is what
earns it the new name, and nothing else in the six-command route is touched — `code-grounder`,
`design-grounder`, `grounding-verifier`, `grounding/`, `code-grounding.md`, `design-grounding.md`,
`baselines.md`, `brd-link.md`, `coverage-ledger.md`, `slices.md`, `brd/` and `brd-reader` all keep
their names, the first six because they were already route-neutral and the rest because they *are*
BRD-route artifacts.

### Added — `/prd-ground` now serves the idea route too, optionally and ungated

Idea-route grounding runs after `/create-prd`, once merged, on the same PRD folder — never on a
root, and never on a resolved `EPIC-` folder (`PRD_GROUND_EPIC_LEVEL`, new). The route is detected
from the resolved folder, never declared: a `PRD-` folder carrying `brd-link.md` is still the BRD
route; a `PRD-` folder without one is the idea route. The claim list is built from the PRD's own
`[AC#n]` and `[FR#n]` rows, plus a `[US#n]` whose story carries neither — `[UC#n]`, `[SM#n]` and
`[SMC#n]` are excluded, and the run reports the count and the excluded prefixes both before the repo
prompt and in the Final report, so a clean run is never read as a fully-ground PRD. A PRD with no
resulting claim stops with `PRD_GROUND_NO_CLAIMS`, naming `/update-prd` as the fix and never
`/create-prd`, which would rewrite the PRD rather than add acceptance criteria to it. `--depends-on`
is refused outright on this route (`PRD_GROUND_NO_PREREQUISITES`): a `will-change` horizon needs a
decision register to freeze a prerequisite's decision in, and the idea route has none, so every
finding on it is `current`. Five new stops altogether: `PRD_GROUND_EPIC_LEVEL`,
`PRD_GROUND_NEEDS_PRD`, `PRD_GROUND_PRD_NOT_HANDED_OFF`, `PRD_GROUND_NO_CLAIMS`, and
`PRD_GROUND_NO_PREREQUISITES`. The branch prefix on this route is `prd/`, shared with `/create-prd`
and `/update-prd`; the next-step offer names `/create-ard` and `/specify`, with `/update-prd` named
first, marked `(Recommended)`, wherever a claim came back `SUPPORTED`. Grounding stays optional here
and nothing gates on it — the run's own Final report says outright when every claim came back a
verified absence, so a PRD that is greenfield against the resolved repositories reads as one finding
rather than a wall of absences, and a second run over the same folder is exactly what that headline
exists to make unnecessary.

### Added — design grounding ships on the idea route in the same release

A class 1, 2 or 3 `[DG#n]` is settled from the frame set and the requirement text alone; a class 4
cites a `[CG#n]` and inherits its commit. The frames are `/idea`'s own source images, vendored into
`design/idea-sources/` with their mandatory index — a class-1 finding here reads *this mockup shows a
screen no `[AC#n]` asks for*, a reconciliation available before `/create-ard` and on no other route.
A folder with no `design/` at all is the common case, and `grounding/design-grounding.md` is still
written on every run, carrying the `## Frame sets covered` census — absent always means the file is
not there, never that the pass was declined.

### Changed — `/create-ard` and `/specify` read grounding wherever the resolved folder holds it, and seed their scans from it

Both commands already knew how to read `grounding/code-grounding.md` and `grounding/design-grounding.md`
and to stamp `consumed_by` back onto what they drew on — that reading was gated on `brd-link.md`
being present. The gate is gone: wherever the resolved folder holds either file, on either route, its
findings are read, stamped `consumed_by: ARD` or `consumed_by: specification`, and — new in this
release — used to **seed** each command's own theme extraction before it falls back to the
PRD/Epic-derived themes it always used. A `[CG#n]`/`[DG#n]` whose verdict says a capability is absent
is a theme worth scanning; one whose verdict says it is present names the code that already
implements it, directing the scan at it instead of searching blind. Neither command's own
`code-scanner` fan-out is replaced, made conditional, or put behind a flag — the two answer different
questions, and a folder with no grounding derives its themes exactly as before this release.

### Added — `/update-prd` reads grounding and gives `consumed_by: PRD` its first writer onto a grounding finding

`/update-prd` now discovers `grounding/code-grounding.md` and `grounding/design-grounding.md` in the
resolved folder (all optional, read-only, never gating — the same posture as its existing `ard.md`
and `specification.md` reads) and carries their findings into the grill with the same **grill-rank**
consumption the documentation digest already uses. Where it draws on a finding to change the PRD, it
sets `consumed_by: PRD` on that finding — the same write `/create-ard` and `/specify` already make at
their own altitudes. This is the **first time `PRD` has been written onto a grounding finding
record**: `/create-prd` already writes `consumed_by: PRD`, but only onto a `decisions.md` decision
record on the BRD route, never inside a grounding file, since it reads no `grounding/` file on either
route.

## [2.2.0] — 2026-09-07

### Fixed — `/brd-ground` never checked a verifier's outcome against the verdict it re-derived

Phase 7 now reconciles the two before acting on either. `grounding-verifier` returns `own_verdict` on every outcome, and an `agree` or `extend` carrying a verdict that differs from the finding's is a return contradicting itself — the outcome is normalised to `contradict`, the finding is rewritten to the re-derivation as that branch already does, and the normalisation is recorded and reported in the Final report's verifier tally, with an explicit "none" where nothing was normalised so a clean run reads as checked rather than as unchecked. `unprovable` is never normalised.

### Fixed — Phase 8 could write the verifier's return fields into the finding record

Phase 8 now writes §2's fields plus `outcome` and `notes` **and nothing else**, per `workflows-core:grounding-format` §2.1's newly-closed field set. `own_verdict`, `own_evidence` and the verifier's re-derivation `commit` are return fields Phase 7 has already acted on; a block carrying `own_verdict` beside `verdict` states two verdicts at once and every downstream reader is free to quote whichever half suits.

### Added — `/brd-split` and `/brd-interview` refuse a malformed finding block

A fourth test in `/brd-split` Phase 0 step 7 (`BRD_SPLIT_MALFORMED_FINDING`) and a third in `/brd-interview` Phase 0 step 7 (`BRD_INTERVIEW_MALFORMED_FINDING`): every `[CG#n]`/`[DG#n]` block's keys are tested against the closed field set, and any other key stops the run naming the finding, the key, and the hand repair. **The existing outcome test cannot see this** — such a block carries an `outcome`, so it passes on presence while the disagreement travels into a slice's allocation, or into a `[VD#n]` frozen against whichever half the run read and then put in front of a customer. That is the same "a relation testing a property of what exists cannot catch what should not exist" shape as BRD-1, and the reason this is a relation of its own rather than a stricter count.

The stop names the hand edit rather than `--rebaseline`, which would re-derive an entire verified corpus to delete a line no command should have written. `/brd-package` gains nothing: it has no findings gate at all, and a `--rebaseline` that moves the findings forces a new interview round through the check above.

## [2.1.0] — 2026-09-07

### Added — the sibling re-cut: a slice may hand a row it has refused to build to a sibling

Slice-first grounding carves a slice before it is ground, so *"this slice is larger than one deliverable"* is a normal discovery. The route's only answer was deferral: the slice's own walk sent the rows it would not build to `deferred-to: <itself>`, where they stayed its live obligation. That was enough for *build less now* and not enough for *two independently deliverable slices*, because the blocker sat on the **parent** — its row for the delegated requirement read `covered-by: <that slice>`, `/brd-split` walked only `unallocated` rows, and no command returns a row to `unallocated`. A future sibling could never claim it.

`/brd-split` on a fully-allocated **root** carrying an `<instruction>` now performs the re-cut. Phase 0 step 9a builds a **re-cut candidate set** — every `[BR#n]` whose row on this ledger reads `covered-by: <A>` while A's own ledger reads `deferred-to: <A>`, two ledgers already agreeing that nobody is building it — and computes the eligible receivers; step 10 tests that set **before** the no-op, so a run that can move a row is no longer swallowed by the no-op it otherwise looks identical to. Phase 1.5 reads the instruction over that set instead of over an empty unallocated one, Phase 2 proposes groups and **fixes a receiver per group**, and Phase 4's new **Step 2R** offers each move one row at a time — showing the donor, both dispositions quoted from the two ledgers, the receiver, and every decision in the donor's register whose evidence touches the row. Accepting writes `covered-by: <B-KEY>` on the parent's row and then on the donor's, in that order. Phase 4's bulk offer gained a third firing condition for the uniform case; Step 3's reconcile widened its input set so the donor's claim and copied inventory row are withdrawn and the receiver's three files are written; Phase 4.5 now recomputes emptiness *after* the walk and repairs any `covered-by` key left pointing at a folder it removes; and `slices.md` gained a re-cut block and a removal block, because the ledger records neither.

**The precondition is the design, not a guard on it.** `deferred-to: <A>` is A stating in its own ledger that it is not building this, so the parent re-points against a refusal the row's owner wrote down and never over a live commitment. A row A still intends to build reads `covered-here` and cannot be moved. The receiver must be a sibling under the same parent that has **not been interviewed** — no `decisions.md` holding a `[VD#n]` or `[CD#n]`, no `interview/round-*.md` — because a register that exists and holds decisions is closed to added scope; a slice the run carves itself qualifies by construction. Nothing travels with the row: the donor's findings and decisions stay where they are and are never edited, and the receiver re-derives against the same pins, since a finding carried in from an earlier run is unverified by definition.

**What this does not relax.** No row returns to `unallocated` — every write replaces one terminal disposition with another — so the allocation gate is never reopened, and a receiver removed later takes the row to `deferred-to: <PARENT-KEY>` rather than back to the donor or back to `unallocated`. The one-level nesting cap is untouched: a re-cut carves a **sibling**, never a child. What relaxes is only the weaker rule that `/brd-split` never re-allocates a row already carrying a fate, and it relaxes against the owner's own recorded refusal and against nothing else. `references/coverage-ledger-format.md` §3.2 is the authority for all of it.

**Minor version, not a major one.** Nothing that worked before stops working. There is no new flag and no new argument: the re-cut reuses the `<instruction>` the route already made mandatory for carving a root, on the one run where it was otherwise free — and on that exact run the previous behaviour was to parse it, discard it and report it unused, naming the path that swallowed it. A bare `/brd-split <PARENT-KEY>` on a fully-allocated parent is still the same no-op; the ordinary walk, the `allocate-only` walk, the four resolutions at each level and every existing stop are unchanged. The one behaviour a user could have depended on — that an instruction there did nothing — is one nobody could have depended on for anything.

**A stop was designed for this and then retired, which a reader tracking the design will look for.** `BRD_SPLIT_RECUT_NO_RECEIVER` was to fire where a non-empty candidate set met no receiver. It does not exist and no code path reaches it: Phase 3 can always key a new slice, so the state in which nothing could *ever* receive a row is unreachable — and the state that *is* reachable, every proposed target declined with no eligible child standing, is an operator's answer rather than an error. This route already refuses to call one a failure. Step 2R simply has nothing to offer, every candidate is reported left with its donor, and the run finishes normally.

## [2.0.0] — 2026-09-07

### Changed — grounding, the interview, packaging and reconciliation move to the slice; a root now refuses all four

`/brd-ground`, `/brd-interview`, `/brd-package` and `/brd-reconcile` used to accept a BRD key at either level. They now refuse a resolved root outright, in Phase 0 before any other gate — `BRD_GROUND_ROOT_LEVEL`, `BRD_INTERVIEW_ROOT_LEVEL`, `BRD_PACKAGE_ROOT_LEVEL`, `BRD_RECONCILE_ROOT_LEVEL` — each naming `/brd-split <BRD-KEY> "<how to cut it>"` as the remedy.

**This breaks the route for anyone running it at root level.** The six `/brd-*` commands carried this two-level model since they shipped in `dev-workflows` at `v3.24.1`, an ancestor of this release, so the model has been in users' hands the whole time the route has existed; a run that worked against a root in 1.1.0 now stops at the first gate. The design's decision was to refuse and detect rather than offer a compatibility path: where root-level grounding, decisions, interview records, package artifacts or a reconciliation record already exist from the earlier model, the refusal names their exact paths and says plainly that they are **left in place and read by nothing** — nothing migrates them and nothing deletes them.

**Major version, not another minor one.** `product-workflows` 1.0.0 and 1.1.0 both shipped this route as an installable plugin someone could pin against, unlike an internal step of a multi-part split — so unlike a case where no intermediate version was ever separately consumed, a run that worked against a root in either of those versions is exactly what this stops. Semver's own contract is that an incompatible change is a major version, not a minor one carrying a bold warning in its own prose; `2.0.0` is the number that tells an installer what this entry would otherwise have to say by hand.

Twelve documentation files, including both of the route's mermaid diagrams, were brought into line with the same fact, and the level-conditional branches only a refused root could still reach — "at either level," offers that fanned a root out into its slices, a next-step offer recommending a command that would now refuse the key it was handed — were removed rather than left as dead prose a future reader would have to re-verify is dead.

### Changed — `/brd-split` on a root now requires a slicing instruction

A root is never ground, so nothing exists yet to cluster candidate slices from. The `<instruction>` argument, previously optional at both levels, is now **mandatory on a root whose ledger still holds an `unallocated` row** — `BRD_SPLIT_NEEDS_INSTRUCTION` if absent — and stays optional on a slice, where it only seeds the allocation walk's per-row recommendation. The stop is taken late in Phase 0, once the ledger has been read, so a root run that proposes nothing still runs without one: that is the run three other stops on this route name as the way to resolve a child left standing while claiming nothing, and it carves no slice.

The route now runs intake → split (root, instruction required) → ground (slice) → split (the same slice, `allocate-only`) → interview → package → reconcile. `/brd-split` runs twice, with grounding sitting between the two runs rather than before the first. Route ordinals ("the second command...") were removed from all six command bodies and from the surrounding documentation, since counting a fixed position stopped meaning anything once a command occupies two different steps of its own route.

### Fixed — the PRD-eligibility test's consumer list undercounted itself by half

`coverage-ledger-format.md` §5.1's positive test for "this unprefixed folder is a BRD container" is the same test `/create-prd`, `/create-ard`, `/specify` and `/epics` already shared. The four newly-refusing `/brd-*` commands cite it too now, rather than each restating the rule inline — which is what keeps a fifth divergent copy from shipping the way a fourth once did. §5.1's own consumer list grew from four to eight to say so.

## [1.1.0] — 2026-09-06

### Fixed — three more gates that a count could satisfy with nothing

`/brd-reconcile` froze zero `[CD#n]`, swept nothing and reported success on a digest the reader had failed to parse: its three gates all count *undisposed* items, so an empty digest satisfied them vacuously. `BRD_RECONCILE_EMPTY_DIGEST` reads the verdict written in section 2, which the schema fixes to three values: `approved` beside three empty sets is a customer who agreed and is recorded as the approval it is; any other verdict, or a section 2 that is absent or gives none, is a review contradicting itself or a parse that failed.

`/brd-package` step 7's *"every question in every round"* is a universal, true over no rounds at all. The rounds a BRD has are now **derived from `decisions.md`'s `round` fields** rather than from the `interview/` listing, and each one is gated with `require-on-main`; any on no ref stop together with `BRD_PACKAGE_ROUNDS_NOT_ON_MAIN`. Deriving the set is what makes a partial merge visible — enumerating the directory finds the rounds that landed and never learns a third was owed, which is the case the gate exists for. Step 8 gained `BRD_PACKAGE_NOT_INTERVIEWED`: it had reported a BRD with no `[VD#n]` as **finished**, which is right for one that was interviewed and settled and wrong for one that never was.

`--docs <path>` was declared by `workflows-core:docs-grounding` for all nine of its consumers and parsed by `/idea` alone; the other eight took `--no-docs` and nothing else, so an operator whose documentation is not at `$DOCS_PATH` could only turn grounding off. Implemented in all eight, each stripping the flag and its value together before anything counts positional tokens.

**`/create-ard` and `/specify` needed a flag-parsing step before they could accept either flag**, and finding that out is the more useful half: neither had one, and both refuse a second positional token outright — so the `--no-docs` both of them have documented since they shipped would have tripped `CREATE_ARD_ONE_ADDRESS` / `SPECIFY_ONE_ADDRESS` and stopped the run. The flag was named in two Usage lines and parsed nowhere.

`/epics` gained the `--no-docs` / `--docs` parsing step it had never declared, and its "Provide manual fix notes" escalation option gained the resolution instruction it never had — every other option in that array had one.

### Added — `/brd-ground --no-code`, so a missing design pass can be added without re-deriving the code findings

`--no-code` is a run mode, not a step skip: `grounding/code-grounding.md` is read-only for the whole run, the run produces no `[CG#n]`, and every finding already on file keeps its verdict, evidence and verifier outcome — never renumbered, never re-verified, never rewritten. Repositories are still resolved and pinned, because a class-4 `[DG#n]` is pinned to the commit of the `[CG#n]` it cites.

It exists because there was no way to reach the state without it. A BRD found to have exported frame sets and no design grounding could only be repaired by a full re-run, which on the engagement that reported this would have put **278 verified findings** back through derivation. `--no-design` had existed since the route shipped; `--no-code` never had.

Documentation grounding and the derivation matrix are off under this mode — both are written into the file it holds read-only — and the run refuses it outright alongside `--no-design`, alongside `--rebaseline`, alongside an explicit `--derivation-matrix`, or against a BRD with no verified code grounding to build on.

### Added — `/brd-reconcile --sent`, so an out-of-band customer review can be reconciled at all

The reconcile gate required a `customer-review-prompt-<YYYYMMDD>.md` that `/brd-package` had built and handed off. A review answering a package authored by hand, or sent before the route existed, could therefore never become a `[CD#n]` by any route — and no re-run of `/brd-package` could produce the missing artifact, since it will not rewrite a dated bundle and a fresh one is a *different* document from the one the customer answered.

What that gate protects is that a quotation can be checked against a committed copy of the document it came from. `--sent <path>` supplies that copy from the other direction: the operator names what was actually sent, each path is copied verbatim into `customer-sent-<YYYYMMDD>/` and committed beside the review before anything reads either. The invariant holds; only its provenance changes, and the run records which of the two it worked from in the reconciliation record and the final report. It replaces the package gate and nothing else, and is refused where a handed-off package already exists.

### Fixed — `/brd-split` passed a BRD whose designs had never been ground

The gate counted findings carrying no verifier outcome, so **zero findings satisfied it vacuously**: a BRD with two indexed frame sets and no `grounding/design-grounding.md` at all sailed through, and its slices could reach build with their designs never reconciled. A count tests a property of the records that exist; what was wrong was the records that did not.

Two presence relations now run before the count, each failing when its own side comes up empty. A `code-grounding.md` on main recording no `[CG#n]` stops with `BRD_SPLIT_NO_FINDINGS`. A **design/** subdirectory covered by no entry in `design-grounding.md`'s new frame-set list stops with `BRD_SPLIT_DESIGN_NOT_GROUND`, which names `/brd-ground <KEY> --no-code` as the repair. A set the operator explicitly skipped with `--no-design` passes and is recorded in `slices.md` as a limit on what the split could check. The design test executes `require-on-main` against `design-grounding.md` rather than reading the worktree — `--no-code` hands that file off in its own commit, so the single-commit implication the code gate relies on does not reach it, and without the gate the repair this very stop recommends could satisfy it with an unmerged file. A BRD ground before this release has no frame-set census and is passed with a recorded note rather than sent into a re-derivation it does not need.

**`/brd-interview` carried the identical vacuous count and is fixed with it** — `BRD_INTERVIEW_NO_FINDINGS`. It matters more there than in `/brd-split`: with zero findings that command answers every `[G]` from an empty evidence set and freezes `[VD#n]` against nothing. It takes no design relation, deliberately — a frame set with no `[DG#n]` yields no question to answer wrongly, and `/brd-split` gates the same BRD before any slice reaches build. `/brd-ground` Phase 8 now writes that frame-set list — every subdirectory on disk, covered or not — which is what makes the relation checkable rather than inferred.

### Fixed — `/epics` dispatched `doc-fixer` without its plugin namespace

The **BLOCK** branch said "invoke `doc-fixer`" with no `subagent_type`. `doc-fixer` ships from `workflows-core`, so the unqualified name resolves to nothing. Every other dispatch in the file was already qualified; this branch was the one that carried its instruction in prose rather than in a dispatch block.

## [1.0.0] — 2026-09-06

### Added — the product-definition half of `dev-workflows`, extracted into its own plugin

Install it with `claude plugin install product-workflows@ihudak-plugins`. Updating the marketplace alone does **not** install it: `dev-workflows` does not declare it, because no `dev-workflows` run loads anything from it.

Twelve commands move here from `dev-workflows` 3.27.0, and each keeps its bare name once this plugin is installed — only the namespaced form changes, from `/dev-workflows:<command>` to `/product-workflows:<command>`:

- the idea → PRD → ARD → specification ladder: `/idea`, `/create-prd`, `/update-prd`, `/create-ard`, `/specify`
- the Epic breakdown: `/epics`
- the six-command BRD-to-PRD route: `/brd-intake`, `/brd-ground`, `/brd-split`, `/brd-interview`, `/brd-package`, `/brd-reconcile`

Twelve agents and nine reference files move with them. The partition is exact: no agent and no reference is shared with the commands that stayed, so every `${CLAUDE_PLUGIN_ROOT}` citation among the moved files points at a file that moved alongside it.

### Dependencies

Two, both declared, both host-resolved at install:

- **`workflows-core`** — the shared reference corpus every command here loads in its first phase. An unsatisfied dependency disables the plugin rather than letting it half-run, which is the intended behaviour: there is no degraded mode to fall back to.
- **`prose-style`** — `prose-style-checker` is `/epics`'s primary style checker, not a fallback. Declaring it removes the absent case entirely; the "skipped gracefully when not installed" branches that shipped while it was an optional companion are retired, because for `/epics` "skipped gracefully" meant no style check at all.

`dev-workflows` is **not** a dependency in either direction. This plugin's spine hands `specification.md` to `/dev-workflows:design`, but it installs and runs without it, against a specs tree someone else's engineering work will eventually fill in.

### Hooks

One `UserPromptSubmit` hook, which preloads `$SPECS_PATH` and `$REPOS_PATH` context for `/epics`. It matches both the bare and the plugin-qualified form; the family's three preload hooks accept only their own plugin's prefix and cover disjoint command sets, so no single prompt can match two.
