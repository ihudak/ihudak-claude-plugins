# Rationale — the evidence behind the repository's rules

Never auto-loaded. Each section holds the measured cases, refused widenings and history behind one rule in `CLAUDE.md` or `.claude/rules/`, each linking back here by a `why` reference to its matching `#<slug>` heading. Read a section before proposing to change its rule. Figures marked *(as of d5f3034b)* were true on that commit and have not been re-derived.

## description-budget

Claude Code enforces no limit, which is exactly why over-long blurbs kept shipping: the Claude editions grew unchecked and the Copilot edition inherited the overflow at port time. The blurb reached 2788 chars by appending one sentence per release, and was trimmed by hand three times in the Copilot edition before the check existed.

## id-grammar

The exit code alone was not enough and this was proven rather than assumed: each negative fixture carries several violating lines, so any surviving alternation holds the exit at 1, and a review deleted both `SM-C` alternations, watched `--selftest` print PASS, and then watched the degraded gate accept a live bracketed legacy counter-metric ID in a shipped reference file. `scripts/validate-catalog.py` now carries a `--selftest` of its own for the same reason.

The `id-grammar-ok` census was five such lines across five files *(as of d5f3034b)* (one accepts the legacy form as a tolerant reader — `workflows-core:ard-resolution`; the other four are the reviewers that check identifier integrity and must quote the form they reject). **The count fell from ten when the tracker-reading agent that held five of them was deleted.**

## docs-tree

Deriving every claim on a page from the thing that runs it is how the restructure found six defects the README had been asserting for releases.

No case count is stated for `check-docs.sh --selftest` because it changes every time a check gains a failure mode, and the two readings of it (cases that mutate a copy, and cases in total) differ by the unmutated-fixture pass — so a count is a claim that goes stale in the same commit that improves the gate. The `CLAUDE.md` sentence that stated it asserted 37 while the tree had 39, and was then corrected to a number the correcting commit's own diff had already moved.

## number-gating

A count taken off the prose it was meant to check agrees with that prose by construction and tells nobody anything, and it is at its most convincing exactly when the finding beside it is right. **The case is `CLAUDE.md`'s own**: a branch reported a released changelog entry as claiming *eleven* states where it says *ten* and lists ten, having read a 660-character window centred on another word, met it mid-way at *"n-state gate"*, and completed it from memory — from `CLAUDE.md`, which does say eleven, about today's table. The rendering was read for the thing, the gap filled from a belief about the current tree, and nothing beside it was wrong.

## check-10

Check 10 enforces the identity quarantine; before that check existed two per-command pages linked a sibling plugin by full container URL and survived releases, found only by hand. The binding reason is **forks**: a hardcoded container URL is wrong in anyone's fork.

Check 10 matches its tokens on word boundaries, not as substrings: an unanchored match produced 38 failures on correct pages when the marketplace was renamed to a word another identifier contains, and a gate a fork must disable is a gate a fork does not have.

## check-11

What check 11 excludes is stated because a reader who assumes otherwise reintroduces a shipped defect.

The widening census lives only in `workflows-core:next-phase-offer`'s scope-paragraph section. The `CLAUDE.md` sentence stating the rule used to carry its own copy of the site count, naming `/document`, `/implement`, `/specify` and `/idea`, and the reference file carried a second copy naming three of those four — both true when written, both stale within two increments as commands moved plugins, and disagreeing with each other in the meantime. The rule that would have prevented that is the one the rule now follows: re-measure in one place, cite it everywhere else.

## check-12

Check 12's parser is **bracket-matched and quote-aware, not a non-greedy regex**, and that is the whole point: `choices:\s*\[(.*?)\]` stops at a `]` inside an option string and silently skips that array, which is how the census that motivated the check missed three live arrays, two of them six-option.

## stop-routing-no-check

Matching the stop-ID condition suffix (`BRD_SPLIT_EMPTY_INVENTORY` → `PRD_GROUND_EMPTY_INVENTORY`) fires 7 times on content that is correct, because a stop legitimately names a command to warn against it (“do not run …, which stops on the same emptiness” — though both instances of exactly that wording, in `/brd-split`'s full-mode stop and `/brd-interview`'s, proved false on 2026-09-23, `/prd-ground` refusing each folder before it reads any inventory, which is the point about stop texts made again) or names it against a *different* key (`<PARENT-KEY>`); silencing those needs three hand-tuned filters, after which it fires on nothing and would have caught none of the eleven route defects that motivated it. “Names the emitting command itself” fires 11 times, all correct (`re-run '/product-workflows:brd-split <KEY>'` on a bad key). “Names no exit at all” fires 14 times, all correct (a dirty tree, a prompt leak, a schema boundary — the remedy is not a command). What the eleven actually shared is a claim about another command's *behaviour* in a state, which no file states.

## check-13

Vendor neutrality was a hard constraint held by prose alone until it was not. The marker convention already existed with exactly one user and no enforcer.

**The narrow token set is evidence, not taste, and is recorded so the widening is not re-proposed:** the tracker names fire on 13 sites, of which 3 were real defects (the plugin README claiming `/ready` verifies a Jira status when it is artifact-anchored and reads no tracker; `docs/commands/vuln.md` twice calling `/vuln`'s optional address — a key resolved against `$SPECS_PATH` — a Jira ID) and 10 correct content, now marked. <!-- vendor-token-ok: quotes the two shipped defects check 13 was created to remove, which cannot be cited without naming the token they carried -->

Adding the git-forge names fires on **70 further sites, every one correct and none a defect** — host classification, CLI capability facts, and rules forbidding REST calls: a forge is something the plugin stands in front of and must name to behave correctly, a tracker is something it deliberately does not read. That is the same fires-only-on-correct-content result on which check 11's widening was measured and rejected twice.

**Its scope is every text file, not just markdown, and the widening was measured before it was made.** A tracker name leaks as readily through `plugin.json`'s user-visible `description` or a hook-script comment as through prose — the argument its sibling check 14 already makes for reading everything — and scoped to `*.md` it could see neither. Measured first, as this repo requires of any widening: 17 non-markdown text files under the plugin, and the widened scan fires on **none** of them, which is why this widening was taken where check 11's (which fired only on correct content) was twice rejected.

Six of the fourteen marked lines sat in `workflows-core` *(as of d5f3034b)*, so the census recipe reads `plugins` rather than one plugin. The older `| grep -v '/CHANGELOG.md:'` filter silently dropped the `CLAUDE.md` sentence describing it from its own audit, because the sentence quoted the filter.

## check-14

Check 14's token list is stored base64-encoded for one reason worth stating plainly: a denylist written in clear text would itself put the names into the tree, making the gate the only violation of the rule it enforces and every future `grep` come back dirty. It has zero live sites — the tree and its history are both clean — so it exists to keep a constraint that currently holds by discipline from quietly stopping to hold. It was added after a review mutated a docs page with those names and watched check 13 pass, which is also the correction to the belief that check 13 covered them: it never did.

## check-15

**Check 15 gates index membership** — every command must appear in `docs/README.md`, in the plugin README, and inside `docs/workflow.md`'s **mermaid diagram**, asserted separately from the page because prose below a diagram is where a command lands when someone adds it in a hurry. Check 4 proves a command has a page and check 3 proves that page is reachable from *some* page; neither proves it is findable, and a review demonstrated the gap by deleting a command from all four listing surfaces and watching the build stay green. The defect that actually shipped this way was the same shape and smaller: `/frames` reached the workflow page's prose but not its diagram, under an opening sentence promising "every command shown here".

## check-16

The loader contract is the trade the split made explicit: the shared reference corpus lives in `workflows-core`, `${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin, and a dependent plugin therefore reaches every reference through one argument-taking skill rather than through 28 named wrappers — one skill whose argument nothing validates unless something does.

Each of the three citation forms is load-bearing for a different file: the **bare** form is the only thing reaching `dependencies.md`, while the **plugin-root** form is the only reason `instruction-file-maintenance.md`, `handoff/code-scanner.md` and `handoff/impl-maintenance.md` are not reported as dead, since each is read by one of core's own agents by path.

No file outside core cites a core reference by path in either of the two forms that resolve to the reading plugin — the defect the loader exists to prevent, gated only over `commands/`, `agents/` and `references/` because widening it to the whole plugin fires once, on correct content, which is the result on which two earlier widenings were refused. **Scope is `commands/`, `agents/` and `references/`, measured rather than chosen**: within them the preamble relation is an **exact** match — every file that cites, carries — while a comparable number of files outside them cite a core reference and correctly carry none, so an unscoped implementation fires on every one of those on a clean tree. **All four of those figures live in `scripts/check-docs.sh`'s check-16 header and nowhere else, deliberately**: the `CLAUDE.md` sentence describing check 16 carried a second copy of them, both copies went stale, and the rule stated with check 11 — re-measure in one place, cite it everywhere else — is the one that would have prevented it — and admitting `docs/` as a *citation source* would make the reverse direction unfalsifiable, since core's own `docs/reference/references.md` enumerates every reference file by name.

## check-17

A ledger item (PS15) recorded a live defect: an agent self-disclosed dispatching a stray subagent mid-run, outside its own sanctioned set. Verifying *runtime* behaviour is impossible from a static script, and a check that merely asserted "the rule exists" would have passed on the very run that misbehaved: **measured first**, only 3 of the agents under `PLUGIN_RELS` carried `Task` in their tool list at all (`upgrade-executor`, `vuln-fixer`, `docs-style-checker`), and all three already carried a NEVER-dispatch rule naming their sanctioned subagent, in near-identical wording, when one of them still mis-dispatched. That is 3-for-3 today *(as of d5f3034b)* — green on the current tree — and it fires the moment a fourth agent gains `Task` without the rule, which is the realistic way this decays. **The reverse direction is asserted too**, the same call checks 8 and 11 already made for their own declared-vs-observed pairs: an agent carrying the rule but not `Task` declares a dispatch authority the harness would refuse, which is stale and misleading — verified green on the same three-file tree before it shipped.

## check-18

A gate that fired on both the red case and its green twin would be red for the life of every release branch, and a gate that blocks correct work is a gate someone disables. **The recurrence is what bought it**: commit 47050554 dated every such section on 2026-09-19 and said so in its message, and by 2026-09-22 seven more stood across four plugins, all live on origin. Matching the bare `## [Unreleased]` form would fire on correct content and nothing else, the same result on which earlier widenings of `check-docs.sh` were refused.

## check-19

The organisation's name and its internal repositories were named by the design archive and its neighbouring records across more than a hundred files until they were swept out on 2026-09-23. The denylist is encoded because a clear-text denylist would be the one violation of its own rule.

## mermaid-gate

Until `scripts/mermaid/check-mermaid.mjs` existed nothing in this repository parsed mermaid (`check-docs.sh` check 15 extracts diagrams, but only to test which commands appear in one). `plugins/product-workflows/docs/workflow.md` shipped from product-workflows 3.0.0 onward with five unquoted edge labels carrying `[BR#n]`, `[CG#n]/[DG#n]` and `[AC#n]/[FR#n]`, which mermaid reads as the start of a node shape; a person found it by opening the page.

**Its first version used a hand-rolled fence scanner, and a release review found three kinds of diagram GitHub draws that it never saw** — inside a blockquote, on a list-marker line, and after a line opening with a backtick code span — plus a four-space-indented block it wrongly rejected.

A failure is located by content because mermaid numbers its errors from text it has already rewritten, and a replay of those rewrites is never complete: the gate's second version tried one and pointed confidently at the wrong line after a decision node. The parser was calibrated against a real headless render of the repository's tree, where the two agreed block for block.

## choices-arity

The plugin nonetheless shipped a convention saying the opposite of the harness schema (2–4 options, no authored Other), stated across the command files (*"last choice is always `"Other… (describe)"`"*), which authored duplicate options in bulk and pushed dozens of arrays past the cap — the measured figures are in `scripts/check-docs.sh`'s check-12 header, cited rather than restated in `CLAUDE.md` because two copies of one census is how they came to disagree while `workflows-core:escalation-rules` simultaneously required every array be presented verbatim — a rule the harness made unfollowable. **Two consequences outlive the cleanup** (both stated in `CLAUDE.md`). Six closed-vocabulary pickers used to protect themselves by omitting the free-text option.

## code-handoff-citation

The code-oriented commands' not-clean-finish invariant cites `code-handoff`'s *A run that did not end clean* by heading rather than by number: it read §2.8 from 3.10.0, where that was right, until 3.12.0 inserted `### 2.7 The title and the body file` above that section and shifted every later section by one — and a stale §-citation is invisible to a §-existence sweep, because it resolves, to the wrong section.

## implement-phase-3-5

The `/implement` invariant that Phase 3.5 **names what it did not cover rather than assuming it** is the honest form of the "full test suite is verified" that invariant used to claim in `CLAUDE.md`, a claim three reachable completions denied — the three the invariant now lists.

## test-writing-requirement

Changing the tree to meet an unqualified first clause of the test-writing requirement was the alternative and was rejected: it would have to remove **both** escapes a user can choose — *"Accept the remaining failures and proceed"* and Pre-Phase 3.5's *"Skip tests for this run"* — and a gate-failed run that cannot finish is a run that leaves the implementation uncommitted, which `dev-workflows:code-handoff` §1 rule 5 exists to prevent. The completions nobody chooses are not options to remove at all: a suite that will not start is the environment's answer, not the operator's.

The silent fourth member of kind 2 — a runner that narrows its own run past the test `test-writer` just wrote — was measured on Mocha 12.0.2, which does not default `--forbid-only` from `CI` (`dev-workflows:test-baseliner` capture step 1 draws that distinction per runner, and names the runners that abort instead): with an `it.only` already committed in the repository, `CI=true npm test` printed `1 passing` and exited 0 both before the run wrote a failing spec beside it and after.

## brd-recut-readers

The sibling re-cut rule names no recipe for its readers because the recipe that stood in its `CLAUDE.md` bullet was wrong. That recipe — `grep -l unallocated plugins/product-workflows/commands/brd-*.md` — returns six files and is wrong in both directions: `/brd-proposal` is in it and reads neither §3.2 nor the re-cut (its one `§3.2` is `workflows-core:phase-handoff`'s), and `/brd-intake` is in it citing §3.2 only to say it offers no re-cut, while `/create-prd`, `/create-ard`, `/specify` and `/prd-ground` each cite `coverage-ledger-format` §3.2 by name for a disposition the re-cut leaves behind and are all outside the glob.

## addressing-fallback-totals

The "twelve files, eleven commands" totals the `workflows-core:addressing` §7 bullet in `CLAUDE.md` used to tell readers to re-derive went false twice — cutting the tracker moved them without moving the number, and by 2026-09-23 the commands citing §7 did so for other reasons — `/brd-split` for its *Adoption is additive* rule, `/release-notes` to say why it has a row — and none to reach the fallback, while `/implement`, `/vuln` and `/brd-proposal` resolved through §3 with no row — so §7 now keeps none.

## prose-style-roles

**The `CLAUDE.md` sentence stating `docs-workflows`' style-gate dependency used to call the dispatch a fallback gated on the rungs failing**, which left the ordinary case — a repo whose Vale run succeeds, where the checker runs anyway as the complementary semantic pass — unstated.

## docs-grounding-flags

`/idea` was the only implementation of `--no-docs` / `--docs <path>` until the other eight consumers were given a flag-stripping rung, four of which had none at all and would have read the flag as a positional token.

## release-notes-worthiness

`/release-notes` once read the PRD's own `relevant_for_release_notes` and stopped on an explicit `false` or `no`. Every PRD is relevant for release notes, so the field asked a question with one answer and the only value that changed anything was one nobody should write.
