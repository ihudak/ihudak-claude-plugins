# Changelog

All notable changes to the **workflows-core** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.
A section headed `— Unreleased` has not been published yet; where more than one of them stands, they all ship together in the next release.

## [1.7.1] — Unreleased

### Changed — two references name the agent that now reads the family's pictures, and the artifacts it writes

`grounding-format.md` §6.1 and §6.2 named `idea-reader` as the agent reading the images an idea source links. `product-workflows` 3.7.0 moved that job to its new `figure-reader`, which also transcribes the images a customer's BRD links for `/brd-intake`, and both sections now name it: §6.1's paragraph on reading a picture says which of the family's picture readers each claim is true of, and that `brd/brd-figures.md` — the file `/brd-intake` writes from those transcriptions — is not a frame-set index and sits in no `design/` directory, so the index obligation does not reach it; §6.1's account of when an idea-route PRD folder holds a frame set now says an image the run's link walk took and `figure-reader` read; and §6.2's writer table says `/idea`'s per-image description is `figure-reader`'s `depicts` sentence, with the sentence under it saying that an image `/idea` never had transcribed is not copied, so it reaches step 4 only where an earlier run or a person left a copy in the set — it had said such an image lands on step 4 outright, which a file never copied cannot. `phase-handoff.md` §4.0's register classifies the two artifacts `/brd-intake` gains, `brd/source-external/*` and `brd/brd-figures.md`, as **advisory** beside `brd/source/*`, naming `/brd-package` and a later `/brd-intake` run as their readers — an artifact absent from that table is unclassified, and `/brd-intake`'s handoff declares both. No behaviour of any `workflows-core` command or agent changes.

## [1.7.0] — 2026-09-18

**Update this plugin, not only the one whose workflow you were thinking about.** `claude plugin update` re-fetches exactly one plugin, and everything below is shared: the `test-notify` hook that arrives with this plugin on every machine, since each family plugin declares it as a dependency, and four references the dependent plugins' own instructions cite by name — `model-routing/classification.md`, `phase-handoff.md`, `cost-emission.md` and `session-hygiene.md`. A machine that updates `dev-workflows` alone runs its new instructions against the old shared corpus.

### Fixed — `test-notify` has never read a test result, so a red suite was notified as `0 failed`

`hooks/test-notify.sh` piped the captured test output into `python3 -` and attached its parser program as a here-document **on the same command**. A pipe and a here-document compete for file descriptor 0 and the here-document wins, so python read its *program* from stdin and `sys.stdin.read()` returned the empty string. Every one of the four branches that reads output was dead, and their `"0"` defaults are indistinguishable from a genuinely empty run — which is the harm: a suite with two failures notified `0 failed`, and you had no way to tell that from a green one. The program now goes to `-c` and the output keeps the pipe (so `ARG_MAX` is still not in play on a large log). Measured, shipped script against fixed, same payloads: a Maven run of 12 tests with 2 failures and 1 error went from `0 run, 0 failed, 0 errors` to `12 run, 2 failed, 1 errors`; a 2.3 MB, 60,007-test log from zeros to `60007 run, 1 failed, 0 errors`; a pytest run from `0 passed, 0 failed` to `5 passed, 2 failed`.

Making the Maven branch live for the first time exposed a second wrong number in it. Surefire prints a `Tests run:` line **per test class** and a summary line **per module**, and the unanchored pattern summed both — 24 for a 12-test run, 120,014 for the 60,007-test one. The summary line is matched on its own shape so modules sum without classes being counted twice, with a fallback to the unanchored counts where nothing matches the anchored form. **That anchor was then itself wrong on any run with a flake**: Surefire's own `RunStatistics.getSummary()` (3.2.5 sources, read for this fix) appends `, Flakes: N` whenever flakes > 0, so a module whose suite flaked matched nothing — and in a reactor that is a silent drop rather than a fallback, because the green module's summary still matches. Measured on the shipped script, a two-module reactor whose web module had five real failures plus one flake notified `10 run, 0 failed`. One optional group fixes it; nine flaky fixtures move to their true values and the other twenty-four rows are byte-identical.

### Fixed — `test-notify` no longer prints a zero it did not measure, and `./mvnw test` is matched at all

The parser's two helpers returned `"0"` where their pattern did not match at all, so three branches printed zeros they had never measured. Proved on a real process rather than a fixture: an `npm test` running `node --test` with two passing and two failing tests, exit 1, notified `0 passed, 0 failed`, because nothing outside Jest prints a `Tests:` line — and the same for mocha and vitest, and a green Gradle run reported `0 completed, 0 failed`. That was harmless only while every family reported zero; with the branches now live, an unread zero reads as a measured one. Both helpers return "no match" instead, and a branch reports numbers only where at least one lookup hit — a miss **beside a hit** is a real zero, since a runner omits a zero clause from a summary it did print, but a miss beside nothing is no measurement at all and now prints the same `tests completed` the unrecognised-command branch already used. A run that genuinely reports zero tests still says so.

Separately, the command gate listed `gradlew test` beside `gradle test` — so wrapper invocations were meant to be covered — and carried no `mvnw` counterpart. These are substring matches, and `mvnw test` does not contain `mvn test`, so **`./mvnw test`, the way most Maven projects are actually invoked, matched nothing and notified nothing.** One alternation added. Measured, shipped script against fixed over 58 command-form fixtures: exactly six change, five of them `./mvnw test` forms going from silence to their real counts, and the sixth the honest cost — a command that merely *mentions* `./mvnw test` now notifies, exactly as one mentioning `npm test` already did. `./mvnw --version` and `./mvnw help:evaluate` stay silent; the gate requires the literal ` test`. Every one of the twenty Maven fixtures was re-run against `./mvnw <same args>` and compared with the same fixture under `mvn`: 20/20 identical, CRLF, flake-suffix, no-summary fallback, zero-tests and stacktrace-midline among them. Three widenings were measured and **refused** rather than reasoned away: `mvn …[[:space:]]test\b` fires on `mvn clean package -P test` (a profile named `test`) and still misses `mvn clean install`, which does run tests; covering the lifecycle goals fires on `mvn clean install -DskipTests`, which runs none; and `(npm|yarn|pnpm) run test` indexes your own script namespace, firing on 8 of 10 plausible script names, 6 of them not test runs, where the current gate fires on 0. Only the wrapper has evidence of intent behind it. The never-block contract was re-verified on the edited script across 19 adverse conditions — an empty `PATH`, a `python3` exiting 3, a symlink-looped `grep`, six malformed payloads, a NUL byte, three locales and a 2.7 MB payload — all exit 0.

### Fixed — `classification.md` §5 told `dev-workflows` its own two Opus agents were unreachable

§5 conditioned `dev-workflows:risk-planner` and `dev-workflows:code-review` on the calling plugin declaring `dev-workflows` in its `dependencies`, and made the negation a fallback trigger. **`dev-workflows` declares `["workflows-core"]`** — a plugin does not depend on itself — while `/implement` dispatches both, `/upgrade` dispatches `risk-planner` and `/vuln` dispatches `code-review`. `CLAUDE.md` requires `/implement` and `/upgrade` to load and follow this file at every invocation, so a run held two executable instructions at once, and taking the §5 branch swapped the frontmatter-Opus-pinned `code-review` for `general-purpose` — defeating the *Opus review gate runs before tests for `SIGNIFICANT` / `HIGH-RISK` tasks* invariant and dropping the three conditional dimensions §6's eight-item checklist does not carry. **The condition was wrong, not the fallback**: all five sites now exempt the owning plugin, and the environment half of the trigger survives verbatim, which is the only route by which `dev-workflows` itself can still reach it. A dispatch-form census in the same section, which partitioned the three code-changing commands by whether they name an agent bare or plugin-qualified, was **dropped rather than corrected** — `/upgrade` is in both halves, and the rule it was offered as evidence for does not turn on the form.

### Fixed — `phase-handoff.md` §1 headed a widened rule "unchanged", inviting the deletion of the two prohibitions that protect uncommitted work

§1 headed rules 1–4 *"Inherited from `specs-repo-git.md`, unchanged:"* while rule 4 under it opens *"this one is WIDER than the rule it inherits, deliberately"* — it adds `stash` and `checkout --` to the destructive-command list, because a deliverable commit runs where your own work may be uncommitted and both of those discard it silently. The heading sits inside the section whose own lead-in warns that a reader who "corrects" one of these breaks the contract, and the correction it invited was deleting exactly those two prohibitions. It now reads three unchanged and one widened, with the reason, in this file and at both `CLAUDE.md` sites that repeated the claim.

### Fixed — `cost-emission.md` §9 and `session-hygiene.md` described runs their own commands make impossible

§9's keyless tier gave *"idea refinement, pre-PRD work"* as its case. `/idea` takes a mandatory key as its first argument and refuses without one, and its own body says the entry lands on the keyed tier and never on the pending ladder — so an agent executing `/idea`'s cost step and loading this reference read its own run named as the keyless case and filed to pending. §9 now states the **property** (no key resolves, and §8 tier 2's documentation branch does not apply) instead of an example, and names what actually reaches the tier, derived from tier 2's own `Otherwise` branch. The same paragraph had also gained `/vuln` and `/upgrade` as members: neither emits a cost entry at all — this file says so three times elsewhere — and §9's pending file is written by `emit-cost` alone, so a run that never calls it never enters the ladder. That clause is cut rather than replaced.

`session-hygiene.md` carried two more. Its resume-pointer omit-condition was keyed on membership of §4's rename-aid set: §4 enumerates eight commands, **eighteen** commands execute the template, and nine of those eighteen appear in neither list. The condition now reads a property the run already holds — omit the line where this command's own `### Context hygiene` block carries no `/rename` suggestion — which is decidable for all eighteen and correct for all eighteen. And §4 justified excluding `/idea` and `/create-prd` from the rename aid by their running *"before the handoff that mints the PRD, so there is usually no PRD-ID to name a session after"*: both now take a mandatory key and refuse without one, so a PM run always has one. **A reason that no longer holds needs a new reason rather than a deletion** — the exclusion stands on phase length alone, and five further sites carrying the retired premise, in `product-workflows` and `dev-workflows` as well as here, were swept by subject and corrected with it. A third claim, that `/vuln` and `/upgrade` *"have no PRD directory to write into"*, is refuted by name in `cost-emission.md`: both run `specs-preflight` and `commit-artifacts` and do write into `$SPECS_PATH`, and a keyed run of either resolves a folder. The partition is three ways rather than two.

## [1.6.0] — 2026-09-18

Everything here is a shared contract another plugin reads, which is why the arrival of `docs-workflows`' cold-start commands (`/docs-init`, `/docs-brand`, `/docs-serve`) moves this plugin's version rather than only theirs.

### Fixed — §4.3's own closing paragraph still counted the arrays as three, in the same section as the sentence that had just corrected the count to four (1.6.0)

The commit that tied §4.3's array count to §4.1's bullet list edited one occurrence of the literal string `between the three` and left a second occurrence of the **same string** in the **same section**: `:388`'s `remote: none` paragraph read *"the class parenthetical is already the only thing that varies between the three"* and priced the rejected alternative at *"three more literal strings"*, against `:360`'s *"four, not three"* at the head of the same section. Both sentences quantify the same set — §4.3's arrays, mechanically **4** (`awk '/^### 4.3/,/^### 4.4/' … | grep -c 'choices: \["Branch + commit'`) — and the section that binds a producer to agree with §4.1 could not count its own arrays. `:388` now states the cost **per array** rather than as a number, which is what §4.3's own opening asks for (*"the count is derived rather than asserted"*), and says so where a later reader would otherwise re-add one. `:388`'s third *three* — *"still the best of the three"* — was always correct, counting an array's **options**, and now reads *"the best of the three options"* so the two readings cannot be confused again; that confusion is exactly what §4.0`:269` records as the origin of the four-against-three state.

**Two smaller falsifications from the same change, both found by re-deriving §§4.0–4.3 rather than by grepping the corrected phrase.** §4.3`:380`'s *"Each wrong pick misleads in its own direction"* enumerated **three** of the four arrays, silently dropping the advisory one, while §4.1`:346`'s parallel sentence names all four; it now names all four too. And §4.3`:360` states as a rule that *"each array below names the bullet it pairs with"*, which only the two gated arrays did — the advisory and unread ones paired by shared label alone, so a reader adding a fifth clause value met a convention half its members did not follow. Both now carry `(§4.1 bullet 3)` and `(§4.1 bullet 4)`.

**What was checked and found correct, recorded so it is not "fixed" next round:** §4.0's heading and `:269` (*"three"* is the **class** count, which is right), §4.3`:362`'s *"stood at three arrays"* and *"four-against-three"* (past tense, correct history), and §4.3`:382`'s *"the gated array"* in the `_readiness.md` narrative (historical, when there was one). A **wrap-insensitive** sweep for `between the three` over `plugins/` plus the two root files returns **8 occurrences on 6 lines**, none of them about §4.3. Four are live prose — `cost-emission.md:46` (the three cost files), the `dev-workflows` and `product-workflows` `session-feedback.md` pages (*"between the three subsystems"* — `workflows-core`'s third copy of that page does not carry the string) and `CLAUDE.md`'s seventh sweep refinement, which quotes the retired string as its worked example — and the other four are this entry and the one above it, quoting their own subject, the same self-exclusion `CLAUDE.md`'s check-13 paragraph records. **The first draft of this sentence said 3**, having been measured on the parent tree before the commit's own edits added the refinement and these quotations; it is the certificate for a rule about counting after the edit, so it is corrected here rather than quietly dropped. **Ungated** — `check-docs.sh` does not open §4.3 — verified by mutation.

### Fixed — `next-phase-offer.md`'s effort-proposal routing heading said the pair gates nothing, directly above the bullet that names the gate (1.5.0)

`:162` read *"**PM — effort proposals (optional, and they gate nothing)**"*, and the first bullet under it reads *"`/product-workflows:brd-proposal <BRD-KEY>` (PM) … **carrying `<merge-clause>`**: that command runs `require-on-main` against the very `proposal.md` this run wrote."* Two live contradictory instructions, the second directly under the first, in the file `CLAUDE.md` names as the authority for the offer convention. The heading now reads *"gate nothing on the build ladder"*, the qualification `/brd-proposal`'s own body and both places on its one documentation page already carried. This is the class `CLAUDE.md`'s sixth sweep refinement describes — the sibling shares the *subject*, not the correction's wording — and it was reached by sweeping the subject (*the proposal pair's gating*) across `plugins/` rather than the plugin the claim was corrected in.

### Fixed — `phase-handoff` §4.3 offered three consent arrays against §4.1's four clause values, so `/idea` promised a stop `/create-prd` does not make (1.0.0)

§4.3 opened *"One array per §4.0 class"* and carried three arrays, while §4.1's `<next-phase-clause>` *"resolves four ways: §4.0's three classes, with the **gated** one split by §3.4's own column"* — and §4.3's own rule says the array *"must agree with the `<next-phase-clause>` §4.1 prints on that same decline"*. For the split-gated half that agreement was structurally impossible: no array said what that clause says. **The reachable run is `/idea` on `status: refined`**, which cited the gated array and told the operator *"the next phase will stop until this is on main"*, while `idea.md`'s **only** §3.4 row — `/create-prd <KEY>`, the idea ladder — falls through rather than stopping, and the run's own §4.1 outcome line on that same decline printed *"the next phase does not stop on that"*. `/idea` Phase 5 already said so twice in its own prose: row F is *"a fall-through rather than a stop"*, and `/create-prd <KEY>` with no path *"grills the PRD from scratch, ignoring this file"* — which is what declining actually costs, and it is not a stop.

**This is a reintroduction, which is why the fix binds the two lists rather than only adding the missing array.** `8647f7ad` (2026-09-01) fixed the same asymmetry once at three clause values against one array, recording the shape — *"4.1 has three clause variants and argues why, while 4.3, the array shown BEFORE the decision, had one"*; `0fe3b394` (2026-09-05, **1.0.0**) then wrote the three-class table and split the gated clause in two in the same change, and left §4.3 at the class count. §4.3 now derives its count from §4.1's bullet list — *"one array per `<next-phase-clause>` value, not per §4.0 class"* — each array names the bullet it pairs with, §4.1's bullets name the array, and §5 rule 4's citing obligation gains its other half: a command that cites rather than quotes names the class **and**, where that class is gated, which of its two arrays, because *"the gated variant"* now identifies two.

**§4.1's split is restated as a quantifier over the artifact's rows, and the membership moves.** It read *"§3.4's row for that consumer"*, which under-determines every artifact with more than one row, and its falling-back bullet named the PRD — read by `/create-ard` and `/specify`, which fall back, but also by `/prd-ground` **(idea route)** and `/prd-proposal`, which each mint a `*_PRD_NOT_HANDED_OFF` stop for exactly the state a decline leaves. The rule is now: **any** stopping row takes the stopping clause, **every** row falling back takes the other, and a `deliverable_paths` set spanning both takes the stopping half — §4.0's strongest-class rule one level down. Read off §3.4's column 3, the falling-back artifacts today are `idea.md`, the ARD and `design.md`; the PRD, `specification.md` and every `/brd-*` deliverable are stopping. **Three command sites follow from it**: `/product-workflows:idea` names the falling-back array; `/product-workflows:create-ard` and `/dev-workflows:implement` Phase 4.5 each select per run, because each has a `deliverable_paths` set that spans the two halves on some runs and not others (the ARD alone versus the ARD beside `grounding/` files and `decisions.md`; an annotated `design.md` alone versus `specification.md` with it). `/dev-workflows:design` needed no change and shows why the set rule is stated: its `design.md` stops nothing, but the amended `specification.md` beside it does.

**Ungated** — no check in `scripts/` opens §4.0, §4.1 or §4.3; check 11 reads §3.4's column 2 only and check 12 reads a `choices:` array's arity, which is three options in all four arrays — verified by mutation.

### Fixed — `phase-handoff` §4.0's `unread` register held three artifacts a later run of their own command reads (1.1.0)

§4.0 classes every declared deliverable, and §4.3 picks the consent array from that class, so an artifact in the wrong row is a prompt that misinforms the operator. Three members of the **unread** row were read the whole time, each by a later run of the command that wrote it — which §4.0 already treats as a reader, in its own `customer-review-<YYYYMMDD>.md` row (*"and a later run of it reads one already on file"*, the only downstream read that row names).

- **`proposal.md` (a `BRD-` umbrella)** — `/brd-proposal` Phase 0 step 5 notes an existing one and Phase 6 step 9 anchors the re-run's figures on it (`product-workflows:proposal-format` §8). The cell refuted itself in its own last clause, which described that read while the class denied it. **This one had a user-facing consequence**, fixed in `product-workflows`: the command presented the `unread` array and its `<downstream-clause>`.
- **`/specify`'s `_session.md`** — Phase 0 step 4 detects one, Phase 1 step 2 reads it back for resume-vs-fresh, and the Epic picker marks an Epic *"◐ in progress (resume)"* on it.
- **`/design`'s `_design-session.md`** — Phase 0 step 5 and Phase 1 step 2, identically.

The last two move **no array**: both commands' `deliverable_paths` sets also hold a gated path (`specification.md`, `design.md`), and §4.0's strongest-class rule already selects the gated array. They are corrected because the register is what a producer adding a deliverable consults — *"Treat an unlisted path as unclassified rather than as unread, name its reader, add its row"* — and because the row claimed a verification it had not had (*"handed off, and no reader found for any of them"*). The remaining members were re-checked one by one and stay `unread`: `_glossary.md`, `_design-glossary.md`, `/specify`'s rendered `.html`, `/update-prd`'s archived revision, `proposal-brief.md` at either level (opened by `proposal-reviewer` check 7 inside the run that wrote it) and both commands' archived proposal revisions. §4.3's register sentence is rewritten to match, and its closing instruction now says where to look: *"in this run's own folder as well as downstream, since a later run of the producing command is a reader like any other."* `next-phase-offer`'s `/brd-proposal` clause, which justified that command carrying no `<merge-clause>` anywhere by *"it hands off an artifact nothing reads"*, keeps its conclusion — the options name no gate — on the reason that actually holds: no `require-on-main` gate targets it, and a read is not a gate.

**False the day each was written.** `290a01f1` (2026-09-06, **1.1.0**) wrote *"handed off, and no reader found for any of them"* while `commands/specify.md` at that same commit already read `_session.md` back at its Phase 1 step 2. `10a72f2b` (2026-09-09, **1.3.5**) added the umbrella row in the commit that created the reader. **Ungated** — check 11 reads §3.4's row-F table, column 2, and opens neither §4.0 nor §4.3 — verified by mutation.

### Fixed — the *Required path environment variable unset* rule's own derivation recipe returned one of the nine commands its paragraph names (1.0.0)

The paragraph tells a reader not to trust its list and then hands over a recipe that cannot reproduce it: *"Derive the set rather than trusting this list: `grep -rl 'Required path environment variable unset' commands/`"*. **Settled by running it, which is the one thing a recipe permits.** From the repository root there is no such path — `ugrep: warning: commands/: No such file or directory`, exit 2. From `plugins/workflows-core/` it returns exactly one file, `commands/frames.md`, against the **nine** commands the same paragraph names two sentences above. The working form returns all nine and nothing else: `grep -rl 'Required path environment variable unset' plugins/*/commands/*.md` → `/prd-proposal`, `/brd-intake`, `/brd-proposal`, `/prd-ground`, `/brd-interview`, `/frames`, `/brd-reconcile`, `/brd-package`, `/brd-split`. **This repository had already written the rule this breaks, on exactly this ground**: `CLAUDE.md`, beside `specs-repo-git.md`'s `commit-artifacts` census — *"A recipe that returns a wrong answer is worse than a stale count, because the next reader trusts what it returns."* **The knowledge was in this very release and did not reach the file**: the `/frames` step-0 entry below derives the same population with the **working** form and prints the nine, so the changelog ran one recipe while the reference it documents kept another. **True where it was written, broken by the move that shipped 1.0.0 — measured at both commits, not inferred.** `707b6562` (2026-09-01, pre-split `dev-workflows` 3.21.0) authored it into `plugins/dev-workflows/references/escalation-rules.md`, where all **seven** citers of the day sat in `plugins/dev-workflows/commands/`, so `commands/` resolved against the plugin root and returned every one of them. `153452e8` the next day moved the reference into this plugin and left six of those seven behind in `dev-workflows/commands/`; only `/frames` travelled with it, so at **1.0.0** the identical string returned 1 of 7 — the relative path survived a move that changed what it was relative to. The fix writes the form that works and says where it runs, which is the house convention five sibling recipes already carry and this one alone did not: `grounding-format.md`, `dev-workflows:docs/reference/environment.md` (twice), `docs-workflows:docs/reference/environment.md` and `docs-workflows:docs/reference/references.md` all say *"run from the repository root"*. A sweep for any other recipe naming a bare plugin-internal directory across `plugins/` and the two root files returns **zero**: this was the last one. **Ungated**, verified by mutation.

### Fixed — *Branch prefix undetected* named `/document` unqualified while qualifying `/docs-brand` in the same list, and its sibling in this plugin carries the restriction (1.0.0)

The rule read *"Used by every branch-creating command (`/implement`, **`/document`**, `/docs-profile`, `/docs-init`, `/docs-brand` standalone, `/upgrade`, `/vuln`)"*. Direct mode creates no branch — `document.md` Phase 3 step 7, *"Do NOT create a branch, and do NOT commit the doc edits"*, and its invariant list, *"NEVER create a git branch — this mode never branches"* — so a sentence asserting *every branch-creating command* named `/document` as one of them without the mode that makes it one. **The sentence already knew how to carry a qualification**, restricting `/docs-brand` to *standalone* four words later, which is what marks this as an omission rather than a convention. The wording is taken from `branch-naming.md`'s consumer line rather than invented, so the two now read alike: *"(keyed mode only — a direct-mode run creates no branch)"*. **This is the surviving half of a correction made on this branch.** `73d7bea9` corrected `branch-naming.md`'s consumer line from *"`/document` (both modes)"* and did not sweep the file in the same plugin that restates the same population — before it the two agreed and were both wrong, after it they disagreed, which is the two-live-contradictory-instructions shape `workflows-core:instruction-file-maintenance` calls a defect. **Every other consumer list in the family was already right, which is what made this the outlier**: `dev-workflows:docs/reference/environment.md` (*"(keyed mode; direct mode creates no branch)"*), `docs-workflows:docs/reference/environment.md`, `docs-workflows:docs/getting-started.md` and `docs-workflows:docs/workflow.md` each restrict it. A sweep of every sentence pairing "branch" with `/document` or `/docs-brand` across `plugins/` plus the repo-root `README.md` and `CLAUDE.md` returns **38**, and this was the only unqualified list among them. **Two sites were judged correct rather than fixed, and the reason is recorded so they are not "corrected" later**: `read-only-repos.md` (*"where each bases a branch in a docs repository"*) and `CLAUDE.md` (*"before cutting a branch in a docs repository"*) name no mode but carry a conditional that scopes all four commands uniformly, so a direct-mode `/document` falls outside each by the sentence's own terms — verified, `/document`'s only two `read-only-repos` citations sit in Phase 0's profile guard and Phase 6.2 *Branch setup (conditional)*, both under `# Mode A`. **Pre-existing:** the bare `/document` entered with the corpus move `153452e8` and shipped at **1.0.0**, where the list read `/implement`, `/document`, `/docs-profile`, `/upgrade`, `/vuln` and `branch-naming.md` beside it said *"(both modes)"*. **Ungated**, verified by mutation.

### Fixed — `branch-naming.md` §3 listed an `/epics`-adjacent flow among the commands that prepend a key to the slug (1.0.0)

§3's key-prepend paragraph read *"the commands that are keyed (`/document` keyed mode, **`/epics`-adjacent flows**, `/implement` with a resolved key)"*, in a file whose lead scopes it to *"every command that creates a git branch"* and whose consumer line is a closed seven-command list that does not contain `/epics`. `/epics` creates no branch anywhere — `epics.md` says so at `:17` (twice), `:270`, `:528` and `:928`, and `epic-writer.md` at `:9` and `:166` (*"it runs no git at all"*) — and no flow adjacent to it does either: `/create-ard`, `/specify` and `/design` cut **specs-repo handoff branches**, which `workflows-core:phase-handoff` §2.2 names instead and which `dev-workflows`' own environment page says *"never enter"* this file. §2.4's fallback table and §3's slug list already carry exactly those seven and no `/epics` row, so the member was the one place in the file naming a command none of its tables holds — after the cut, a census of every backticked command token in the file returns exactly those seven and nothing else. It is dropped; the rule survives on `/document` keyed mode and `/implement`, the two commands §3 gives a keyed slug rule to. **Pre-existing and older than the split:** it entered at `7cd36fa0` (*"branch naming is repo-rule-first"*, `dev-workflows` 2.41.0) inside a clause phrased around the tracker this family no longer reads, and the two later de-vendoring sweeps rewrote every word around it and left the member standing — the same shape as this release's other survivors, where the correction's wording shares nothing with the stale neighbour and only the subject reaches both. It reached this plugin unchanged with the corpus move at **1.0.0**. **Ungated**, verified by mutation.

### Fixed — two pages said no command of this plugin reads an environment variable; `/frames` gates on `$SPECS_PATH` and stops (1.0.0)

`docs/reference/environment.md` opened *"Every one of the five is read by a reference this plugin ships **rather than by a command of its own**"*, and `docs/getting-started.md` repeated it. `commands/frames.md` Phase 0 **step 0** is the command's own environment gate — *"`$SPECS_PATH` must resolve: every path this command reads or writes is under it. Unset or not a directory → apply the *Required path environment variable unset* rule … and stop there"* — and `references/escalation-rules.md` lists `/frames` among the nine commands citing that rule, of which it says *"It is a stop, not a degradation: there is no 'continue without it' option."* The repository's own gate agrees on what counts as a read: `check-docs.sh` check 5 treats a `$VAR` occurrence **in a command file** as a plugin read, and its selftest case appends one to a command to prove it. The consequential half was the environment page's **When unset** answer for `$SPECS_PATH` — *"Cost, feedback and follow-up entries fall through to their report-only tier"* — which is the emitters' behaviour and the opposite of what `/frames` does. Both pages now carry the exception, and both `$SPECS_PATH` sections say that `/frames` refuses rather than degrades. The other five commands are unaffected, and four of them were the reason the claim looked true: `/feedback`, `/prompt`, `/prompt-brainstorm` and `/prompt-grill-me` each name `$SPECS_PATH` only as the scope of the shared entry points they cite. `/statusline` names none of the five variables at all and cites neither entry point, so it was never evidence either way. **False the day it was written:** all three sentences entered in the same commit, `153452e8` (2026-09-02), shipping at **1.0.0**. **Ungated**, verified by mutation.

### Fixed — `escalation-rules.md` cited `/frames` Phase 0 step 1 for a gate that is step 0 (1.0.0)

The *Required path environment variable unset* rule's citer list read *"`/frames` (Phase 0 step 1)"*. Step 1 is *"**The address (mandatory).**"* and cites nothing of this rule; the gate is step 0, *"**The environment.**"*. Derived rather than trusted, exactly as the rule's own paragraph instructs: for each of the nine commands the list names, the first line matching `Required path environment variable unset` and the nearest preceding step marker — `/brd-intake` 5, `/prd-ground` 3 and 7, `/brd-split` 2, `/brd-interview` 3, `/brd-package` 3, `/brd-reconcile` 3, `/prd-proposal` 1, `/brd-proposal` 1, all correct; `/frames` the one miss. The population is right too — `grep -rl 'Required path environment variable unset' plugins/*/commands/*.md` returns exactly those nine. **Wrong the day it was written:** `707b6562` (2026-09-01, pre-split `dev-workflows` 3.21.0) added the `/frames` member, and that same commit's `frames.md` already had the gate at step 0. It reached this plugin unchanged with the corpus move at **1.0.0**. **Ungated**, verified by mutation.

### Fixed — `doc-structure-conventions.md` §1 kept the vault's property when the vault-deletion commit rewrote its subject (1.0.0)

§1's scope sentence read *"This section does not govern **specs-tree documents**, such as the `epic.md` files `/epics` writes, where a `[[KEY]]` wikilink is the native idiom, **resolves**, and is the required traceability form."* `product-workflows:idea-format`, *Vendored sources*, says the opposite of that same tree — *"`$SPECS_PATH` is a git repository … it is **not** an Obsidian vault. Nothing there resolves `[[name]]`, and a forge renders it as literal text"* — and `[[KEY]]` is the clearest case of all, because it names a key rather than a page: there is no file for it to resolve to anywhere. **How the false half survived is visible in one diff.** `6914b5b3` (2026-08-31, `dev-workflows` 3.9.0, *"increment D, deleting $VAULT_PATH"*) rewrote this sentence's subject from *"**vault documents**, such as the Epic drafts `/epics` writes **into an Obsidian vault**"* to *"specs-tree documents"* and left the trailing clause standing, so the vault's property is now asserted of the specs tree. **The rule is unchanged and the reason is corrected**: the wikilink is still the native idiom and the required traceability form, and the sentence now says what it does instead of resolve. `/epics`' own invariant carried the identical claim from the identical rewrite and is corrected in `product-workflows`. It reached this plugin unchanged with the corpus move, at **1.0.0**.

**The marketplace `CLAUDE.md` kept a second piece of the same residue.** Its requirement-ID rule ended *"and **the vault importer** rewrites it into a triple-bracketed wikilink on export"* — a definite article naming a tool of a store this family does not have. The same commit `6914b5b3` changed that clause to *"a wiki-style importer"* in all three reviewers that execute the rule (`product-workflows:prd-reviewer`, `ard-reviewer`, `epic-reviewer`), and `references/pre-lint.md` §2 says *"a wiki-style importer"* too; that commit never touched `CLAUDE.md`, so four files moved and the one describing them did not. It now reads as they do.

**Ungated**, verified by mutation: with both sentences restored verbatim the nine-gate CI chain exits **0**.

### Fixed — this plugin's own docs described `branch-naming.md` as a code-repo file, at two sites (1.0.0)

`docs/reference/references.md` introduced the reference as *"how a command that **branches in a code repo** decides a branch name"*, and `docs/reference/environment.md`'s `$GIT_USER_INITIALS` entry said the identity ladder is one *"`branch-naming.md` applies **for a code repository**"*. The file's own lead scopes it to *"every command that creates a git branch"*, and four of its seven consumers branch in a **documentation** repository: `/document` (keyed mode), `/docs-profile`, `/docs-init` and `/docs-brand` (standalone) — §2.4's fallback-prefix table gives each of the four a `docs/` prefix, which is the same fact stated inside the reference. `/implement`, `/upgrade` and `/vuln` are the code-repo three. **Widened rather than enumerated**, taking the shape from the file's own lead, because a list of repository kinds on an index line is one more thing to keep true: the entry now reads *"how every command that creates a git branch decides the branch name"* and the environment page *"the identity ladder `branch-naming.md` applies wherever a command creates a git branch"*. **It was false the day it was written, and its three sibling pages were already right.** Both sentences were authored for this plugin's own docs tree in `153452e8`, the corpus move, and shipped at **1.0.0**; at that release the consumer line read `/implement`, `/document`, `/docs-profile`, `/upgrade`, `/vuln` — two of five already docs-repo — and this branch's addition of `/docs-init` and `/docs-brand` widened the gap rather than creating it. Meanwhile `dev-workflows:docs/reference/environment.md` says *"in a **code or docs** repo"*, `docs-workflows:docs/reference/environment.md` and `docs/getting-started.md` say *"a **documentation** repository"*, and the repo-root `README.md` says *"a **code or documentation** repository"*, so the plugin that owns the reference was the one place describing it wrongly. **What the gates see here, established by mutation in both directions:** with both sentences restored verbatim the full nine-gate CI chain exits **0**, so the prose is ungated; deleting the `branch-naming.md` bullet from `references.md` fails `check-docs.sh` **check 4** (*"reference file 'branch-naming.md' has no row/entry"*), so that check reads the line for its backticked filename only and never for what the line says about it.

### Fixed — `branch-naming.md` named `/document` "(both modes)" in a file scoped to commands that create a branch (1.0.0)

The consumer line read *"Commands that consume this: `/implement`, **`/document` (both modes)**, …"* under a lead that scopes the file to *"every command that creates a git branch"*. Direct mode creates none — `document.md` Phase 3 step 7 says *"Do NOT create a branch, and do NOT commit the doc edits"* and its invariant list says *"NEVER create a git branch — this mode never branches"* — and it cites this reference nowhere: all four `branch-naming` citations in `document.md` (`:81`, `:642`, `:648`, `:992`) sit above `# Mode B`, which opens at `:1290`. **Two rows carried the same claim into the tables**, so fixing only the lead would have left the file contradicting itself: §2.4 gave `/document` (doc-edit mode) a fallback prefix and §3 gave it a slug rule, for a mode that reaches neither. All three are corrected together — the lead now reads *"`/document` (keyed mode only — a direct-mode run creates no branch)"* and the two doc-edit rows are dropped, which is exactly the shape `/docs-brand` already has in this file: a restriction on the consumer line, and a table row for the branching mode only, with none for `--inline`. Nothing else moves: the seven-command population is unchanged, so `dev-workflows:docs/reference/environment.md`'s *"seven commands that name branches in a code or docs repo"* still holds, and `/document` (keyed mode)'s own `docs/` prefix and PRD-summary slug are untouched. **The claim was false the day it was written, not true-then-stale:** it entered in `2e8a2d4c` (pre-split `dev-workflows` 2.40.0, 2026-08-04) alongside both table rows, and that same commit's `document.md` already read *"Do NOT create a branch or commit"* at `:1213`. It reached this plugin unchanged with the corpus move at **1.0.0** — `153452e8`'s copy of the file carries the consumer line verbatim, and that release's own entry names the *"Twenty-nine reference files, moved from `dev-workflows` with their rules intact"* this is one of. **Recorded because of how it survived**, not only because it was wrong: `a232e372` on this branch rewrote this very sentence to add `/docs-init` and `/docs-brand`, wrote the correct form of exactly this distinction for the new entry (*"standalone only — an `--inline` run writes on its caller's branch and creates none"*), and left the stale carve-out three words to its left — `CLAUDE.md`'s sixth sweep refinement in miniature, since the correction's wording shares nothing with the sentence beside it and only the subject reaches both. **Nothing gates any of the three, proven by mutation:** with all three restored verbatim the full nine-gate CI chain exits 0, so a green build is no evidence here. `check-docs.sh`'s only mention of this file is check 13's comment naming its quotes of a repository's own convention file, none of which the edit touches.

### Fixed — `session-cost.py`'s namespace-map docstring put a sibling plugin's command count at twenty (1.1.0)

`load_namespace_map`'s docstring explains why the manifest is not read off a `${CLAUDE_PLUGIN_ROOT}/commands` directory: that path resolves to *"the reference's own six utility commands while the emitting run is one of **a sibling's twenty**."* No sibling has twenty — `ls plugins/<p>/commands/*.md | wc -l` gives `dev-workflows` **5**, `product-workflows` **14**, `docs-workflows` **6**; the six is this plugin's own and is correct. **It was true where it was written and stale where it stood.** The sentence was authored in `3d2b3c96` (2026-09-03) straight into this plugin's own copy of the script — `153452e8` had deleted `dev-workflows`' copy the day before, so there was no other — while that sibling still held exactly twenty commands, which is why it shipped true in **1.0.0**. It went stale by **1.1.0**, by which point `dev-workflows` held five and the largest sibling twelve. Cut rather than re-derived, per the standing preference for a sentence that works without the number: it now reads *"while the emitting run is a command of a sibling plugin"*, which is all the argument needs — the point is that the path resolves to the wrong plugin, never how many commands the right one has. **Nothing gates it, proven by mutation:** with the sentence restored verbatim, `python3 plugins/workflows-core/scripts/session-cost.py --selftest` exits 0 and so does the full nine-gate CI chain, so a green build is no evidence here. Behaviour is unchanged — this is a docstring.

### Fixed — `impl-maintenance`'s `Command run` was a closed list of thirteen command names, wrong in both directions since 1.0.0 (1.0.0)

`agents/impl-maintenance.md` and `references/handoff/impl-maintenance.md` each declared the field *"One of"* thirteen named commands, and each output template repeated nine of them as a `[a | b | …]` placeholder — four copies of one enumeration. **Twenty-four commands dispatch this agent and all twenty-four pass a command identity**: `grep -l 'workflows-core:impl-maintenance' plugins/*/commands/*.md` returns 24, and the union of `grep -l 'Command run: /' plugins/*/commands/*.md` with ``grep -l 'compact handoff: command `/' plugins/*/commands/*.md`` returns the same 24 files. The distinct values they pass number **twenty-five** (14 in the literal `Command run:` form, 11 in the prose `command /x` form, no overlap), of which the list named thirteen — and one of its thirteen, `/document (keyed mode)`, was passed by nothing: keyed mode passed a bare `/document` where direct mode named its own mode. So the list over-named in one direction and under-named in the other. That keyed value is corrected in `docs-workflows` 1.2.0, so both modes now name themselves alike; the enumeration goes either way. **It was false from this plugin's first release**: at `153452e8` — the corpus move, shipping as **1.0.0** — this same thirteen-name list already stood, verbatim, beside a `/frames` passing `Command run: /frames` and a keyed `/document` passing bare `/document`, so both directions were wrong on day one; `/docs-init` and `/docs-brand` are later counterexamples rather than the cause. The list had already been extended twice — `ef4607df`, *"complete impl-maintenance's Command run enum (9 -> 12)"* — which is the pattern a closed list of command names in a shared contract produces. **Cut, not extended.** All four copies now say what the field is: the command variant that executed, named as the caller names it, `/document` additionally naming its mode, with the callers as the authority on the value. The default-to-`/implement` rule beneath it is untouched and still reads correctly — it fires on a *missing* field, and a value the agent has not met before is now simply the value.

### Fixed — `docs/getting-started.md` kept the agent-resolves-repositories claim its sibling page retired (1.5.0)

`### REPOS_PATH` still read *"`code-scanner` resolves repositories under it"* — the claim this release retired on `docs/reference/environment.md`, the page this very section links to two paragraphs above, where it read *"`code-scanner` and the grounding agents resolve a repository under it"*. Same claim, different words, and that is why the correcting round's sweep passed over it: the wording it had just written (*"no agent reads `$REPOS_PATH`"*) shares no word with the sentence left standing, and only the subject, `code-scanner`, reaches both. `origin/main` carried the claim on both pages; only one moved. This section now states what the reference page states: the command resolves the repository and hands `code-scanner` an absolute `repo_path`. The recipe is unchanged — `grep -l REPOS_PATH plugins/*/agents/*.md` returns nothing.

### Fixed — `classification.md` §4 routed the research/planning agents to `planning_model`, which no caller does and one agent's own file denies (1.5.0)

§4's first bullet told the orchestrator to invoke research / planning sub-agents on the `planning_model` "if present", and its parenthetical — *"NVD lookup, detect, compatibility checks"* — names exactly two agents: `vuln-research` and `upgrade-planner`. Both are dispatched on the `detection_model` at their first site (`upgrade.md:39–40`, `vuln.md:49–50`), `planning_model` **is** present in both payloads so the condition was met, and `upgrade-planner.md:54–59` cites §4 by number and then states the opposite of it — *"always runs on the `detection_model` … no Opus pinning is possible or performed here"*, because the orchestrator invokes it before per-component classification exists. An orchestrator following §4 literally burns one Opus call per requested component and per CVE on a step the agent's own file calls mechanical, which is the spend §2.1 exists to prevent. The bullet now says what the tree does and why: the tier is the `model:` argument, resolved by step nature per §9; both take the detection chain on their first dispatch, before their command has a per-unit classification, and they diverge once it exists — `/upgrade` escalates through the separate `risk-planner` and never re-invokes `upgrade-planner`, while `/vuln` re-invokes `vuln-research` on Opus (`vuln.md:77`, MUST for `HIGH-RISK`). **Bundling the two under one reason was this entry's own first attempt and shipped a worse defect than the one it fixed**: it told every orchestrator loading the family's routing SSOT that there was nothing to escalate on, which reads as licence to skip that mandatory Opus confirmation pass on a security fix. `upgrade-planner.md` is untouched; it was the half that was true.

### Fixed — §9's subsections still spoke to the two commands the lead had just stopped scoping to (1.5.0)

1.6.0 re-cut §9's lead to *"Apply this policy in every command"* and left §§9.1–9.3 as written for `/document` and `/epics`. Two rules did not survive the widening.

**§9.1's third bullet** justified giving no relaunch advisory at SIMPLE/MODERATE with *"the writer runs on its detection pin"* — true only of a **delegated** writer (`doc-writer`, `epic-writer`, `release-notes-writer`) and false of every command the widening swept in, which author inline on `current_model` and have no writer to pin. It then forbade the advisory *"per §3.1"*, while §3.1 says only *"Continue with the currently selected model. Do not add mandatory Opus steps."* — so the bullet forbade, in §3.1's name, something §3.1 permits, and `/design`'s *SIMPLE / MODERATE + not Opus → soft advisory* bullet was in breach of a rule its own citation did not support. The sentence now covers both authoring shapes and records that a command offering an advisory anyway is stricter by choice, not in breach. **Covering both shapes is not giving both the same firing condition**, and the first attempt did: it read as requiring the advisory at SIGNIFICANT/HIGH-RISK in both, which `/document` contradicts in the state it legislates for — its writer is already Opus-pinned, so `document.md:233` offers the relaunch *"only"* on a large multi-repo ticket and *"otherwise proceed without prompting"*. §9.1 now states the narrowing for the delegated-writer shape, which is what §9.2's row has cited it for since `a80b482d` wrote the two in one commit — **§9.1 never carried it**, so the row pointed at a condition its own target did not state, and the fix is a first statement rather than a restoration. **Covering the inline shape then over-claimed in the other direction**, and this is the correction: the bullet said the advisory *is* the command's own gate, while six of the ten commands carrying the inline-authoring marker have no gate at all — `/create-prd`, `/update-prd`, `/specify`, `/idea`, `/brd-intake` and `/brd-split` — and `/brd-package` and `/brd-reconcile` author inline, **floor** at `SIGNIFICANT` so the advisory reaches every one of their runs, and each say *never hard-block*. `dev-workflows`' own routing page already said the opposite in as many words (*"`/specify` and `/create-prd` don't gate this way at all; they degrade to the best available model and record the degradation instead of stopping"*), so the SSOT and a live page disagreed about the same two commands. The bullet now states what varies and names one command per behaviour instead of a category, and §9.3's *"the inline-authoring commands' HARD gate"* is narrowed to *"an inline-authoring command's"*. **§9.2's own orchestrator row (1.5.0) carried the delegated-writer condition unscoped**, so a reader resolving it for an inline-authoring command got the other shape's rule; the cell now names both shapes, and each shape has exactly one condition across §9.1 and §9.2.

**§9.3** said to skip the relaunch advisory when no Opus is available, *"there is nothing to relaunch onto"* — right, and contradicted by four commands that fire a relaunch-recommending gate in precisely that state. The section now settles the semantics the disagreement turned on, because nothing in the tree stated them: **`opus_available` is a property of the environment, never of the session.** §2 resolves it against what the `task` tool can reach and names the session's own tier separately as `current_model`, and every block carrying `opus_available` carries `current_model` beside it, so the two cannot mean one thing. Two consequences follow, and a command that confuses the fields gets both wrong at once: a gate meant to **require an Opus session** tests `current_model`, never `opus_available` — which is true on every Sonnet session that merely *could* dispatch Opus, so the gate misses the one state it was written for; and where such a gate fires with `opus_available` also false, the relaunch option is dropped rather than recommended, leaving a two-option array. `dev-workflows` 4.0.4 and `product-workflows` 3.6.0 correct the four gates against it.

### Fixed — `model-routing/classification.md` §9's lead scoped the routing policy to two commands while its own §9.4 says it has no scope (1.5.0)

The section's heading read *"Per-step routing for multi-phase authoring pipelines"* and its lead opened *"The keyed authoring pipelines (`/document` and `/epics`) run a long sequence of phases … They MUST NOT let every step inherit the session model"*. §9.4 is the governing rule and states the opposite — *"Routing is by **step nature**, not by pipeline or session … There is no 'inherit the session model' for scanning and no per-command exception"* — and it is §9.4 the tree follows: `/design`, `/ready`, `/specify` and `/implement` each cite §9 to resolve their own per-step routing, and not one of them is a keyed authoring pipeline. **The lead is the wrong half, and the cost of leaving it was measured rather than assumed**: a reviewer read the lead instead of §9.4 and dismissed a correct finding about `/document` direct mode as "correct by design" on the strength of it. The heading now carries the scope (*every command*) and the lead states the rule; the two pipelines stay as the motivating case and are named as such, not as the boundary. §9.1–§9.4 are unchanged: what is corrected is a scope statement, not a routing rule, so no chain in §9.2's map moves.

### Changed — `grounding-format.md` §4 declares where its `baseline-integrity` triad is inlined

Three files write the three commands out — `product-workflows:prd-ground` Phase 3, `product-workflows:brd-package` Part 4 and `product-workflows:grounding-verifier` step 1 — and only `/prd-ground` takes step 3's `-z` path read, because it alone goes on to read a reported path. That is correct in all three places, and nothing said so: an editor of §4 had copies to keep in step and no way to tell a deliberate divergence from an omission. §4 now names the inliners and the reason the other two stay as they are, the same declared-divergence pattern `dev-workflows:code-handoff` §1 rule 5 uses so a reader does not "correct" it in either direction. **The census itself was short by one and is re-derived rather than adjusted:** `grep -rln --exclude=CHANGELOG.md 'ignore-cr-at-eol' plugins/`, less §4's own file, returns **four** — the three above plus `/prd-ground`'s documentation page, which executes nothing but states the same three commands with the same flag, so a maintainer who renames a flag and updates only the executable copies leaves it asserting one the gate no longer passes. **The exclusion is load-bearing and the first version of this recipe lacked it**, so it returned five: this entry put the token into a changelog in the same commit that stated the recipe, and history is not a carrier. The repository's two marker recipes (`id-grammar-ok`, `vendor-token-ok:`) exclude it explicitly for the same reason. §4 carries the recipe now, not a list. No behaviour changes.

### Fixed — `followup-emission.md` §6 listed a follow-up category nothing can produce (1.5.0)

The qualifying-predicate list carried *"Unresolved PRs on unsupported hosts (must be documented manually)."* The only way a run met an unsupported host was a `diff-summarizer` `pr_refs` element whose `host` was `other`, and nothing in the tree ever built one; with that half of the agent retired, the category is unreachable outright. Cut rather than narrowed, and the narrowing was tested first: no command emits a follow-up for a diff element it could not resolve. `/document` Phase 10 collects from four named Phase 9 sections — `### Screenshots to upload manually`, `### Implementation gaps (PRD vs source)`, `### Skipped items` and `### Deferred items` — and an unresolved ref appears in none of them (it is in `### Refs in scope`, which §6's own DO-NOT clause excludes as an item the report already tracks); `/release-notes` Phase 10 collects the manual publish step and implementation-gap signals only.

### Fixed — three shared files described `diff-summarizer`'s output as PR URLs (1.5.0)

`doc-structure-conventions.md` §1's where-it-goes table sent *"per-claim attribution to resolved keys and PR URLs"* into the run handoff, a field that agent has never returned on either caller's path and no longer declares at all. `code-scanner`'s "Distinction from `diff-summarizer`" said that agent *"reads merged PR diffs"*, and `doc-fixer`'s editorial-judgement test named *"a factual contradiction between the PRD description and the PR diff"*. All three now name what the summaries carry: the ref, and the diff taken against it. The §1 ban on writing a PR URL into a rendered page is untouched — a prohibition holds whether or not the run has one.

### Fixed — `dependencies.md` named `diff-summarizer` as a `gh` caller (1.5.0)

The external-tools paragraph read *"`diff-summarizer` and `dev-workflows:code-handoff` §2.6 to `gh`, each degrading gracefully when it is absent."* That agent's `gh` resolver was reachable only through `pr_refs`, which nothing produces, and is now retired: it shells to no CLI at all and takes every diff with local `git`. `code-handoff` §2.6 remains, and is the whole of the claim.

### Fixed — `dependencies.md` undercounted the family in the sentence that says the manifest is complete (1.5.0)

The namespace-manifest paragraph had `scripts/command-namespaces.json` listing *"`guideline-reviewers`, `obsidian-llm-wiki` and `prose-style` as well as this family's own three"*. The manifest holds seven namespaces, and the same section's own lead-in nine lines above states *"The family is four plugins"* — two sentences disagreeing inside one section. The count was right when it was written and went stale the moment `product-workflows` was added, which is also why the sentence that exists to say the coupling is complete was the one that read incomplete. Corrected to four; the manifest is the authority, and `check-docs.sh` derives it from the tree in both directions.

### Fixed — `docs/reference/environment.md` said a command starts from a pull-request URL (1.5.0)

`$REPOS_PATH`'s resolution note read *"by `git remote get-url origin` slug where a command starts from a pull-request URL"*. No command in this family starts from one. The trigger is now what it actually is: a command that was handed the slug.

### Fixed — `escalation-rules.md`'s `/document` repo-unresolved array named PRs (1.5.0)

The *Repo unresolved (zero matches) — /document* rule offered *"Skip and continue without its PRs"*. That command builds its `refs[]` from `implementation.md` and the `git log --grep` scan beside it and reads no pull request (`/document` Phase 4 step 1), so the option named something the run does not have; it now names **refs**, and the rule says why beneath it. The array's arity is unchanged. `docs-workflows` 1.2.0 corrects the same vocabulary in the command itself.

### Fixed — §3.7's second stopping-row list omitted C″ (1.5.0)

One sentence in `phase-handoff.md` §3.7 enumerated the stopping rows twice and disagreed with itself: *"the other **seven** (I, C′, C″, C, D, E, G) define none"*, then *"Every stopping row (I, C′, C, D, E, G)"* — six members. §3.3's table marks C″ **stop** and `:263` names seven as well, so the short list was the outlier. `dev-workflows` 3.22.0 recorded fixing exactly this — *"the C″ fix had landed in the consumer and not in the authority"* — and corrected the first enumeration and `:263` while the second survived into 1.5.0. Consequence was low (the adjacent paragraph and the state table both correct it, and a caller is told to test `stopped` first anyway) and it is reported because the release rule admits no size floor.

### Fixed — a path `git status --porcelain` quotes was silently never staged (1.5.0)

`git status --porcelain` wraps a path carrying a space, a `"`, a `\` or a non-ASCII byte in double quotes and octal-escapes the non-ASCII bytes — measured on git 2.43.0, where `?? "brd/source/appendix/data table.csv"` is what a customer's linked file reports as. Both of this plugin's path classifiers read that output and matched the path as reported, and both are anchored at `^`, so the leading `"` alone put every such path in **OTHER**: never staged, never on a ref, and never mentioned. Step 1 of each now reads `--porcelain -z`, whose records are NUL-terminated and whose paths are emitted raw.

- **`phase-handoff.md` §2.3** is where it cost the most, and 1.5.0 shipped it. A deliverable the operator named — `/brd-intake`'s copy of a customer's document and, from `product-workflows` 3.6.0, of every file that document links; `/idea`'s vendored `attachments/*` and `design/idea-sources/*`; a `bundle-<YYYYMMDD>/` file — was reported quoted, matched no declared path, and was dropped, **while the run reported the handoff as done**. §2.3 gains a fourth step for that second half: every declared path is accounted for after staging, and one that staged nothing **and is not already on the branch unchanged** is named through a new §4.1 *declaration unaccounted for* clause. The test is `git -C "$SPECS_PATH" cat-file -t "HEAD:<path>"` printing `blob`, and it is `-t` rather than `-e` deliberately, because `-e` exits 0 on a tracked **directory** — the shape §2.9 forbids and this step exists to catch. **An existence test under `$SPECS_PATH` is what this must not be**, and that was shipped first and corrected inside this release: a re-run re-copies a file byte-for-byte, so every file under `/brd-intake`'s `brd/source/`, every `/idea` vendored source and every `/frames` index rebuilt verbatim exists, stages nothing, and is already committed — and the clause then fired, one per path, telling the operator that an artifact they had just handed off was not on the branch it was on. Measured on git 2.43.0 against a two-run `/brd-intake` folder, the `cat-file -t` test also names the two silent drops §2.3 warned about in prose and nothing detected — a declaration given as a directory or as a glob — plus two shapes §2.3 never named at all: one given as an absolute path, and one nothing wrote. §4.1 gains the positive half beside it: every path §2.3 step 3 staged is printed beneath the outcome line, raw as `-z` reported it, capped at eight — and, on the rows that open a pull request, §2.7's body file carries the **declared** set, which is not the staged set in exactly the case step 4 exists for. A drop with no voice is what let this run for releases, and neither list existed. **A `git status` record step 2 could not read as a path takes a clause of its own**, rather than the one beside it: that template reads `<path> was declared`, and an unreadable record was never declared and supplies no path to substitute, so a run reaching it would have asserted a declaration that never happened about a token it could not parse.
- **`specs-repo-git.md` §2.1** had the same flaw on the one segment it does not own. It already stated the hazard twice — for `<docs-repo-slug>`, which it answers by flattening, and for `/document`'s `Doc screenshots/`, which it answers by an exclude — but a feature folder is `<KIND>-<KEY>-<slug>` and `<slug>` is a kebab of a title, so `specifications/PRD-ACME-1-zahlungsauslösung/` is a folder this plugin itself creates. Measured on a real repository: every bookkeeping file under it classified OTHER, never staged, left permanently dirty, firing §3.3's G1 on every later preflight of all twenty-eight callers. The flattening rule is **unnarrowed** — the one-segment property was always the load-bearing half — but the quoting half of its stated reason is retired, and so is the quoting clause among the three reasons no shape stages a screenshot.
- **`grounding-format.md` §4 step 3** read the reported path to run `git show <sha>:<path> | wc -l`, and a quoted path resolves to no file, so the line-count comparison was skipped in silence for exactly the paths a person is likeliest to have left lying about. It now takes the path from the `-z` form. The three-command block above it keeps the readable form deliberately: it is what the customer's reviewer runs and reads by hand (`product-workflows:brd-package` Part 4).

`-c core.quotepath=false` is recorded in both sections as **not** a substitute: it suppresses only the octal escaping, and a path with a space is still quoted. Readers that only test the output for emptiness — `code-scanner`, `/ready` step 3, `require-on-main` row C′, the `docs-workflows` branch-prep checks — are unaffected and keep the plain form.

### Fixed — `dependencies.md` said the PRD-authoring pipeline calls no service (1.5.0)

*"That pipeline reads and writes one markdown tree and calls no service"* is false three ways, all inside it: every one of its commands hands off through `phase-handoff.md`, whose §2.6 runs `gh auth status` and `gh pr create` and whose §3.5 runs `gh pr list`; the commands `docs-grounding.md` lists as consumers dispatch `docs-grounder`, which shells to `qmd` and reads a second markdown tree under `$DOCS_PATH`; and the ones that ground against code scan clones under `$REPOS_PATH`, which is no markdown tree at all. What is true — that none of it *requires* an external tool, each degrading where one is absent — is kept, and §2.6 is now named on both sides of the `gh` sentence rather than only `dev-workflows:code-handoff`'s. The clause predates this branch; the narrowing that removed `diff-summarizer` from the same paragraph passed over it.

### Fixed — `classification.md` §8.2 described the fan-out's first step in retired vocabulary (1.5.0)

*"the folder read reads each ticket folder (read-only) → themes, PR references (identifiers only), linked items"* — three stale terms in one line, in the file twenty-five commands load at their classification step. There is no ticket folder (the input is a resolved specs folder), no PR reference to collect (`/implement` Phase 1.7 step 1: *"there are no PR references until `implementation.md` exists"*), and no linked-items level (the `EPIC-` folders are the hierarchy). Rewritten against what step 1 actually reads. `docs-workflows` 1.2.0 and `dev-workflows` 4.0.4 carry the other two sites the same sweep found.

### Fixed — `docs/reference/environment.md` said agents resolve a repository under `$REPOS_PATH` (1.5.0)

The sentence read *"`code-scanner` and the grounding agents resolve a repository under it"*, which omitted `diff-summarizer` — and the omission was the smaller half. No agent in this family reads `$REPOS_PATH` at all (`grep -l REPOS_PATH plugins/*/agents/*.md` returns nothing): the **command** builds the slug→clone map and hands the agent an absolute `repo_path`, which is why `code-scanner`'s and `diff-summarizer`'s handoff inputs both declare one. The page now says that, and names no set of agents, so nothing here goes stale when one is added. **Its second half — *"and by directory basename where it lists candidates to offer you"* — was carried forward unexamined and is corrected here too**: a command that lists candidates resolves your answer against that listing rather than matching a directory name, so a rename changes the name a clone is offered under, never whether it is offered. `dev-workflows` 4.0.4 and the repo-root `README.md` carried the same clause and are corrected with it.

### Fixed — `code-scanner`'s handoff declared a `model_routing:` input nothing sends, and §4 said every agent gets one (1.5.0)

Both halves measured across every dispatch in the tree. All six `code-scanner` callers — `/epics`, `/implement`, `/design`, `/specify`, `/idea`, `/create-ard` — pin the tier with `model:` on the Agent call and emit no block, and the agent body reads no field of one, so the declaration asked callers for an input none of them sends; dropped, with one sentence in its place. `classification.md` §4's opening MUST — *"pass it to every sub-agent it invokes"* — was false in the same direction and contradicted its own list two paragraphs below; it now reads *every sub-agent that reads one*, with the handoff file's declared input as the test. That list's last three bullets named ten agents (`risk-planner`, `code-review`, `epic-reviewer`, the five doc agents, `test-baseliner`, `impl-maintenance`) as receiving the block "for reporting", and no dispatch anywhere sends one to any of them — the Opus reviewers are pinned by their own frontmatter, the mechanical agents by the dispatch's `model:` argument. Replaced by the rule itself — a sub-agent whose handoff declares no `model_routing:` input is sent none and reads no field of one — with `release-notes-writer`, which the old list omitted while it does receive one, named beside the two categories that already were. `docs-workflows` 1.2.0 drops the same declaration from `diff-summarizer`'s handoff. **Two corrections the narrowing itself needed.** The new `release-notes-writer` bullet credited it with *"records the models it ran under"*, a behaviour that exists nowhere: its handoff's `## Output` declares `status`, `release_notes_block` and `gaps[]` and no echo of any kind, and `/release-notes`' own report has no model line to consume one — the same shape as the ten-agent "for reporting" claim this entry removed, re-introduced one bullet lower. The bullet now says what the return declares. And the narrowed rule was falsified by one live dispatch the measurement did not reach, `/docs-profile` Phase 3 pasting the block into a `general-purpose` agent that has no handoff file; `docs-workflows` 1.2.0 cuts that paste, having measured that the dispatch reads no field of it, so the rule stands rather than gaining an exception.

### Added — a bookkeeping destination for a run that has no PRD and never will (D19)

`specs-repo-git.md` §2.1 gains a **fourth directory shape**, `<specs-root>/documentation/*/dev-workflows/**`, and its staging classifier gains the matching `^documentation/[^/]+/dev-workflows/` branch. `cost-emission.md` §8 and `feedback-emission.md` §2 each gain the rung that writes there, inserted **before** pending / unfiled rather than folded into it: the old ladder parked a keyless entry as *pending*, awaiting reconciliation into a PRD directory, and documentation work frequently has no PRD and never will — so those entries would have accumulated forever against a reconciliation that is never coming. The path is per docs repo, because a person documenting two products must still be able to answer what documenting each one cost. **`<docs-repo-slug>` is defined once, in `specs-repo-git.md` §2.1 beside the shape it fills**: the docs repo's `origin` `OWNER_REPO`, derived exactly as `phase-handoff.md` §2.6 derives it, falling back to a directory name where there is no remote or the derivation comes out empty, and then flattened by one byte-wise substitution in the C locale — every byte outside `[A-Za-z0-9._-]`, `/` included, becomes `-` — because the classifier admits one segment there, and because a per-character rule would give a non-ASCII name a second, different directory. (The quoting half of that reason, stated here when this entry was written, is retired by the `-z` fix recorded above; the flattening rule is unchanged.) The flattening is load-bearing: the classifier admits exactly one path segment there, and an unflattened `owner/repo` (two segments on GitHub, three elsewhere) would be classified OTHER, never staged, and left dirty to fire the G1 guard on every later preflight. `feedback-emission.md` §2, `cost-emission.md` §8 and the emitting commands cite §2.1 rather than restating a derivation.

Two narrownesses are deliberate and are stated where they bite. The inner `dev-workflows/` names the **family**, not the emitting plugin — the shipped ladder already writes `<PRD-dir>/dev-workflows/cost/<sid8>.md` whatever emitted it, and renaming it per plugin would fragment one repository's record across four directories. And the rung tests **which run is running** — `/docs-init`, `/docs-brand` on its standalone path, and `/document` in direct mode — rather than "did the run resolve a docs repo". **Direct mode is on it from this release**: it has exactly the problem D19 describes, its cost entries having gone to pending and its feedback unfiled to the specs-repo root, reconciling against nothing. It now files both under the write target it resolved (`specs-repo-git.md` §2.1 gains the case it needs: a write target that is not a git work tree takes its path's basename — which a `/docs-init` cancelled before creating its target already reached, since that run's emitter tail still runs). Pending and unfiled entries earlier direct-mode runs left stay where they are; nothing moves them automatically.

**No new branch prefix goes with the shape.** §2.2's prefix authority governs branches the plugin creates *in* `$SPECS_PATH`, and this family creates none there — its deliverable is the docs repository, where it branches, commits and drafts a pull request it never pushes.

### Added — a class row for the intake artifact `product-workflows` 3.6.0 introduces

`phase-handoff.md` §4.0's own rule is that a producer adding a deliverable adds its row in the same change, so `/brd-intake`'s new `brd/brd-link-log.md` — the record of every link its source copy could not capture — takes its place in the **advisory** row, with its reader named as §4.0 requires rather than its class assumed: `/brd-split` Phase 3 step 4 reads the log's opening line for the parent's source basename when it writes each slice's inventory header (`product-workflows:brd-format` §1.1, §2.1). It is also added to the `coverage-ledger.md` **(a root)** row's enumeration of `/brd-intake`'s set, which that row cites to show no path in it lifts the set to `gated`; that conclusion is unchanged.

### Added — attribution and branch-naming rows for the new commands

`cost-emission.md` §7 gains `/docs-init` and `/docs-brand`, both `phase: docs-scaffold, role: dev` — the first fixed pair this family has carried. `branch-naming.md` gains both to its consumer list, its prefix table (`docs/`) and its slug list, with `/docs-brand` marked standalone-only because an `--inline` run writes on its caller's branch and creates none. `escalation-rules.md`'s initials-fallback prompt names them among the branch-creating commands. `scripts/command-namespaces.json` gains `docs-init`, `docs-brand` and `docs-serve` — the manifest a deferred cost claim is resolved against, so a cede-and-replay across one of these commands is matched rather than dropped. `cost-emission.md`'s rule for which runs carry a cost entry now names the docs repository as an attribution unit beside a PRD- or BRD-scoped artifact — the clause `/docs-init` and a standalone `/docs-brand` satisfy — and its lists of non-emitters name `/docs-serve`. `finding-triage.md` gains the `docs-scaffold-reviewer` → orchestrator path (`/docs-init`, standalone `/docs-brand`), which has no fixer agent and so triages before the orchestrator's own edit. `next-phase-offer.md` records that the three cold-start commands, though not pipeline nodes, each print a prose `### Next step` with no `<merge-clause>`.

### Changed — every caller count re-derived rather than incremented

`specs-repo-git.md`, `cost-emission.md` and `feedback-emission.md` each carried caller counts that this increment moved. All were re-derived against the tree: twenty-eight `commit-artifacts` callers, twenty-four commands with an automatic maintenance phase, twenty-six `§7` attribution rows of which twenty-four call `emit-cost` (the two that cede the session call it never). `dependencies.md`'s description of `docs-workflows` moves from three commands and seven agents to six and eight.

`skills/model-routing/SKILL.md`'s frontmatter `description` said **21** pipeline commands and enumerated them; it was already short by two before this increment (`/prd-proposal` and `/brd-proposal`) and is now **25**, enumerated in full. A skill description is what the harness matches on, so a stale enumeration there is not cosmetic.

### Fixed — a retired rationale removed from three documentation pages

`docs/reference/references.md` (twice) and `docs/workflow.md` still asserted that **a slash-command body cannot expand `${CLAUDE_PLUGIN_ROOT}`**, and used it as the reason both skills exist. That was verified false in a live run and is recorded as retired in `CLAUDE.md` and in the docs-workflow-family design's §20 row 3, but the three copies here survived the retirement. The reason that actually holds is unchanged and now stands alone: `${CLAUDE_PLUGIN_ROOT}` resolves to the **reading** plugin, so a sibling cannot open this plugin's `references/` by path whatever a command body can expand — which is what the loader skill is for.

### Changed — two documentation pages this increment moved

- `docs/roles-and-phases.md` described three phases and said the other **nine** are reachable only by inheritance, twelve in all. `docs-scaffold` makes it thirteen and ten. The sentence now states what it counts — the twelve lifecycle phases carried as fixed pairs in `references/cost-emission.md` §7, plus this plugin's own `plugin-feedback` fallback, which §7 has no row for — so the arithmetic is checkable and the sibling pages' figure of twelve reads as the different claim it is rather than as a disagreement.
- `docs/reference/session-cost.md`'s persistence-ladder paragraph describes a ladder that now has a rung ahead of pending. It is scoped to this plugin's five cost emitters, none of which can reach that rung, so the sentence was never false — but it now carries a one-clause pointer to `references/cost-emission.md` §8 so the "is this still true?" question is answered where it is asked, without a second copy of the rung's rules.

### Fixed — `docs/reference/hooks.md` no longer says `/frames` takes no address

The page said *"its six utility commands take no address and need no injected context"*. Five take none; `/frames` takes a **mandatory** one and resolves it with `resolve-address` in its own Phase 0. The page now says which is which.

### Fixed — `finding-triage.md` names every reviewer whose findings it triages

Its attachment table and the paragraph beneath it had no row for `proposal-reviewer` → the orchestrator itself, although `/prd-proposal` and `/brd-proposal` both invoke this reference over their reviewer's findings and, with no delegated writer, fix surviving BLOCKERs inline. The row is added, and the no-fixer paragraph covers it beside the new `docs-scaffold-reviewer` path (above). The consumer set was re-derived with `grep -l finding-triage plugins/*/commands/*.md plugins/*/agents/*.md` rather than patched, and `CLAUDE.md`'s copy of the list now matches it.

### Changed — the loader-contract census has one home

`scripts/check-docs.sh`'s check-16 header is now the only place the loader census is written, and it says so. `CLAUDE.md` carried a second copy of four of its figures, so a change to the tree could leave either copy stale, and this increment's commands and agents moved all four. The header's figures are re-derived from the scan itself (341 real invocations, 167 carrying an entry point, 74 files citing a core reference and 74 carrying the preamble, 38 citing files outside the scanned directories), and `CLAUDE.md` now cites the header instead of restating it. The agent total the check-17 header and `CLAUDE.md` share moves from 38 to 40; the **3** agents carrying `Task` is unchanged, and `docs-scaffold-reviewer` correctly carries none.

### Fixed — a switch onto the default branch takes its name, never the `origin/` ref

`git symbolic-ref --short refs/remotes/origin/HEAD` prints `origin/main`, and `git switch origin/main` exits 128 (*"a branch is expected, got remote branch 'origin/main'"*); `git switch -c <new> origin/main` succeeds but sets `<new>` to track `origin/main`. Sites across the family restated that resolution without the strip `dev-workflows:code-handoff` §2.8 and `specs-repo-git.md` §3.2 both make, and then switched to, or cut a branch from, what it printed — among them `code-scanner`'s writable refresh here, which ran `git switch <default-branch>` on the output. `read-only-repos.md` §3 now states the rule once, as **A switch takes the name**: a caller that switches onto the default branch or cuts a branch from it takes the branch's name — rung 1's output with its leading `origin/` removed, or the literal `main` or `master` whose ref rung 2 or 3 found — while a caller that only reads a tree, a file or a log may take the ref as it stands. A writable caller that also runs `git remote set-head origin --auto`, or falls back past the chain, says so where it cites the rule. `code-scanner` cites it, keeps its `set-head` retry as its own step, and now lists the chain's `git rev-parse --verify --quiet` probes among its sanctioned prep operations. Its consumer line names those callers, since a writable switching caller follows §3 too, and its opening says what a writable run reaches (below). It also names the two ladders that stay outside §3 — `dev-workflows:code-handoff` §2.8, which adds `develop` for the code-changing commands, and `specs-repo-git.md` §3.2 for the specs repository — so §3 is not read as the family's one definition of a default branch; `docs/reference/references.md` describes the rule.

### Fixed — a default-branch ladder no longer trusts a dangling `origin/HEAD`

After a remote renames its default branch `master` → `main` and a clone fetches with `--prune`, `git symbolic-ref --quiet --short refs/remotes/origin/HEAD` still prints `origin/master` and exits 0 — `origin/HEAD` names a branch the remote deleted. `read-only-repos.md` §3 stopped at that rung, so a reader got a ref `cat-file -e` rejects, while the `remote set-head origin --auto` retry that repairs it ran only on an **unset** `origin/HEAD`. §3's rung 1 now succeeds only where the ref it prints exists (`rev-parse --verify --quiet`); otherwise the chain goes on to rung 2, and a switching caller's `set-head` retry — which now runs wherever rung 1 fails — resets `origin/HEAD` to `main`. `specs-repo-git.md` §3.2's **Default branch** had the same flaw — `<default-ref>` became `origin/master`, so `require-on-main`'s presence test and the B2 ancestry test both failed — and treats a name without its `origin/` ref as unset. `code-scanner`'s `set-head` retry, which ran only on an unset `origin/HEAD`, runs wherever rung 1 fails. `dev-workflows:code-handoff` §2.8, the third ladder, takes the same fix in that plugin.

### Fixed — an agent handed a repository names it in every command

A subagent's Bash tool starts every call in the session's directory — where the dispatching command stands — and a `cd` does not persist between calls. `code-scanner`'s writable prep wrote `git status --porcelain`, `git remote set-head`, `git switch` and `git pull --ff-only` bare, beside a chain written `git -C "<repo_path>"`: the dirty check read the session's tree, and the switch and pull moved the session's repository while `repo_path` stayed on its feature branch, which the scan then read as the refreshed default branch. Each is now `git -C "<repo_path>"`, and the agent is told why, and to give `Grep` and `Glob` `repo_path` as their path and `Read` `<repo_path>/<path>`. Where a call runs in the repository instead, it is a `(builtin cd "<repo_path>" >/dev/null && …)` subshell, so a `cd` function or alias of the user's, which the Bash tool's shell carries, neither runs in its place nor prints into what the agent reads. `docs-grounder`'s one git call already named `docs_path`; it gains the same sentence, and says its `Grep` shortlist takes `docs_path` as its path while its `qmd` calls stay in the session's directory by design.

### Fixed — `read-only-repos.md` says what a writable run reaches, and `code-scanner` no longer forbids the chain it follows

The file's opening said everything below it is reached only when the mount is read-only. A writable run also reaches §3's chain and its three recorded facts, §6's `prep` block, which `code-scanner` and `diff-summarizer` report on every run, and §7's caller contract; the opening now names them and drops the "only". `code-scanner`'s hard rule listed `git symbolic-ref` among its prep operations and then said none of them run on a read-only mount, while step 2 sends a read-only mount to §3's chain, whose first rung is that very call; it also left out the reads behind §3's recorded facts. It now lists §3's reads — the chain's `symbolic-ref` and its `rev-parse --verify --quiet` probes among them — with the writes, and says a read-only mount runs only the write-free reads.

### Fixed — `source-truth.md` names the gaps draft and its marker as the writer writes them

§5 and §7.5 named the bug-report draft `implementation-gaps.md`, and §7.6's intentional-discrepancy marker ended "See `<PRD-folder>/implementation-gaps.md` gap #n", while `docs-workflows`' `doc-writer` and `/document` write `<KEY>-implementation-gaps.md` and a marker ending "See `<KEY>-implementation-gaps.md` gap #n" — so a `doc-reviewer` holding the page's marker against §7.6 could judge the writer's own marker invalid, and raise the BLOCKER the marker exists to prevent. §5, §7.5 and §7.6 now name `<KEY>-implementation-gaps.md` and give the marker the writer writes. `followup-emission.md`, which tells a follow-up to link the draft, names it the same way.

### Fixed — the two drafts `/document` leaves in the PRD folder are committed

`docs-workflows`' `/document` (keyed mode) writes `pr-draft.md` into the resolved PRD folder on every run that reaches its finish, and it and `/release-notes` write `<KEY>-implementation-gaps.md` there wherever a discrepancy decision calls for one — but `specs-repo-git.md` §2.1 matched neither, so `commit-artifacts` classified both as OTHER and left them untracked, and every later run of any caller met §3.3's G1 dirty-tree advisory, which skips the leftover flush and the branch settle, until someone committed or deleted them. §2.1 now names both as single-file shapes — `pr-draft.md`, and the keyed draft matched as `*-implementation-gaps.md` — beside `release-notes.md`, the draft it already named, and its classifier gains both: **four directory shapes and five single files, nine in all**. The folder is still never widened; `CLAUDE.md`'s count follows. A screenshot `/document` stages for manual upload is **not** made a shape — a temporary copy of the operator's own file, under a `Doc screenshots/` subfolder whose name `git status --porcelain` quotes, or an existing `Attachments/` one holding the operator's files — and §2.1 says so and why: `/document` keeps each copy it stages under `$SPECS_PATH` out of `git status` itself, through that repository's local exclude file.

### Fixed — `prd-format.md` says what `/release-notes` does with an absent release-notes field

1.5.0's `prd-format.md` said `change_type` and `release_notes_category` are "inferred and confirmed in `/release-notes`'s own grill". That command omits the category label where `release_notes_category` is absent, never inferring or asking for one, and confirms an inferred Change Type only where the inference is uncertain (`docs-workflows:release-note-types` §7). The paragraph now says so, and no longer says each field is asked for where it is not known.

### Fixed — no command says it never commits in a working directory that is the specs repository

`specs-repo-git.md` said nothing in it "ever touches a code repo, a docs repo, or the current working directory", and `/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me` and `/frames` said the same of their terminal step, the first four adding that they never commit "into a docs/code repo, or the current working directory". Where the session stands inside `$SPECS_PATH`, that terminal step commits and pushes in the working directory's own repository. Each sentence now makes the claim only where the working directory is not the specs repository.

### Fixed — no reference or command says it never writes into a working directory that is the specs repository

`cost-emission.md` §11 said `emit-cost` never writes "into a docs/code repo or the current working directory", `feedback-emission.md` §6 and `followup-emission.md` §8 said the same of what their callers write, `/frames` said it of its final phase, and the session-cost page said the plugin "never writes into your current working directory". Where the session stands inside `$SPECS_PATH`, each of those writes lands in the working directory's own repository. Each now makes the claim only where the working directory is not the specs repository. The three ladders' rule for their report-only rung — nothing resolved, so never fall back to writing into the working directory — holds as written, and is unchanged.

### Fixed — `dependencies.md` says who declares `prose-style`

The **Declared dependencies** section called `docs-workflows`' `prose-style` declaration "what makes it different from every other plugin here", though `product-workflows`' manifest declares the same two names, and then called `prose-style` "an optional companion in `dev-workflows`", which the same file's own companion table contradicts eleven lines later ("no tie to it at all since `/epics`, `/create-prd` and `/update-prd` moved out") and a grep of that plugin confirms. Both claims shipped in 1.5.0. The paragraph now names the two plugins that declare it and says `dev-workflows` has no tie of either kind.

### Fixed — `prd-format.md` says when `/release-notes` settles `change_type`

1.5.0 said each field is "inferred and confirmed in `/release-notes`'s own grill". The wording that replaced it settled the field "where it is absent", and `docs-workflows:release-note-types` §7 rung 1 also drops two **present** values to inference — `not applicable`, and `Bug fix` on a change that trips the deprecation trigger — so a PM authoring `change_type: not applicable` was told the carried value governs, and it does not. The sentence now says "absent or, for `change_type`, not routable", which is the rule §7 states.

## [1.5.0] — 2026-09-09

### Added — `control`, a positive control on every grounding absence claim

`grounding-format.md` §2's closed field set gains **`control`**, required wherever a finding asserts
an absence — the same trigger `evidence`'s absence clause already uses, so a writer resolves one
question rather than two. New §2.2 owns the rule.

**An absence claim rests on a search returning nothing, and a search returns nothing for two
different reasons**: the thing is not there, or the method could never have found it. Those are
indistinguishable from the result, and only one of them is a finding. `control` records the same
method, run against a case of the same kind known to be present in this same source, and what it
returned. A control that matched nothing is a **failed control** and does not become evidence by
being reported: the verdict is `NOT-PROVABLE`, and the failed control is recorded with it.

It is a field rather than an instruction because the difference had already been explained in prose
and reproduced anyway — a live run explicitly warned about this failure filed an empty `grep` as
evidence of absence in the same pass. The canonical case is a Rails repository where attribution is
written through an association and never spells the column name the grep was looking for.

**Who owes a control is settled by a closed-set rule, not by "does it assert an absence?"** A control
tests whether a **search** could have found the thing; a negative over a set the caller handed in is a
lookup, with no search to control for. So `[DG#n]` classes 1 and 3 (which resolve against the supplied
inventory) and class 4 (whose code half is the cited `[CG#n]`'s search) owe none, and class 2 — a
negative over the frame set, which is read — owes one. A reader working it out from "asserts an
absence" gets class 1 wrong, which is why the rule is stated rather than left derivable.

§8 gains `control_outcome` as a verifier **return** field (never a record field, on the same terms as
`own_verdict`): `not-owed` / `fired` / `failed` / `missing`. `missing` forces `contradict`; `failed`
does too — **including where the verifier's own search also found nothing**, since two searches
sharing one blind spot is exactly what the control exists to expose — **except** on a finding already
reading `NOT-PROVABLE` with its failed control recorded. That finding did what §2.2 instructs, the
control is deterministic so the verifier necessarily reproduces its result, and without the exception
the rule would overturn every honest finding on every run forever.

### Added — a class-4 `[DG#n]`'s standing is derived, and goes stale when its citation moves

`grounding-format.md` §6.3 now states what a resolving citation hides: a class-4 design finding
stands on a conclusion **another** finding reached, so when that `[CG#n]`'s verdict is replaced — by
§8's `contradict` handling, or by a re-grounding run marking it `SUPERSEDED` — the citing finding is
re-derived or superseded alongside it, never left standing. The ids still match and the citation
still resolves, so §6.3's existing correctness test passes on a pair that now disagree, and a reader
following the citation cannot detect it.

### Fixed — `/frames` no longer retries a frame the describer already failed on

`grounding-format.md` §6.2 step 4 wrote one placeholder, `_no description on record_`, and step 2's
exception put every such row back in the describe set on the next run. That is the right mechanism
for a capped run — it is what makes a hundred-frame set converge in three — and the wrong one for a
frame the describer looked at and could not read. **Three oversized exports returned to the describe
set on every future run, forever**, reproducing the identical failure and spending budget a reachable
frame would have used.

Step 4 now writes one of **two** literals, chosen by whether a re-run would do anything different and
by nothing else:

- **`_no description on record_`** — the run never looked (the cap bit, the frame is accounted for
  nowhere, or the whole dispatch failed). Step 2's exception still applies and the set converges.
- **`_could not be read: <reason>_`** — the describer opened that file, or tried to, and failed
  (`unreadable`, `not_an_image`). Step 2 preserves it and the frame is not retried.

**The test is whether the file was reached, not whether a reason came back.** `missing` and the
whole-set statuses are facts about the dispatch; `not_a_frame` is a fact about the *entry* — the
describer rejects a name carrying a path separator without ever opening anything — so all of them
stay in the first group, where a corrected re-run is exactly what should retry them. The reason goes inside the literal because it is the operator's whole remedy, and
`/frames` reports that group **by name rather than as a count** — it is the one group no re-run
clears. Clearing it: fix the file, delete the row, and the frame has no row at all next run. Nothing
in a set records what a run read last time, so deleting the row is what tells the next run the file
changed.

### Added — a recorded review verdict names the version it was taken against

`escalation-rules.md` gains the rule, beside the two BLOCK rules every affected command already
loads. The one-fix-cycle-plus-one-re-review cap assumes a fix cycle only removes defects; on three
live runs it **introduced** something the re-review then found, with the budget already spent — so
the run either shipped a known defect or fixed it and left the final text unreviewed. Both end with a
`PASS` on record beside a file the `PASS` never saw.

Every command that records a verdict now states what it covers, and where any edit followed it — an
inline `MAJOR` fix, an escalation's manual fix notes, a deferred finding written into the artifact, a
style pass, a resumed verify step — the final report says so and names the edits. **The set is
derived behaviourally, not by grepping for the cap phrase**: that first pass missed `/vuln` and
`/upgrade`, both of which run one fixer pass and one re-review and then edit through a resumed verify
step, and `/upgrade`'s own results table carries a `Review` column. Where none did, it says that too, so a
clean run reads as checked rather than as unreported. **Deliberately a reporting rule and not another
cycle**: raising the cap trades one unreviewed version for a later one and has no fixed point.

## [1.4.0] — 2026-09-08

### Added — the `proposal` cost phase, and its two `cost-emission` §7 rows

`product-workflows`'s `/prd-proposal` and `/brd-proposal` each take a fixed `phase: proposal`,
`role: pm` row in §7's attribution table, bringing that table to twenty-four rows.

**`proposal` is its own phase rather than a second `brd-to-prd` one**, and §7 records why:
`/prd-proposal` runs on the idea route as readily as on the BRD route, so filing its spend under
`brd-to-prd` would attribute idea-route spend to a route that run never touched — and an effort
proposal is a commercial activity over a requirement set rather than a step that advances one.

The counts that ride on §7 moved with it: the file's own opening sentence now reads twenty-two of
the twenty-four rows, and §11's and §13.3's *"commands that measure themselves"* both read
twenty-two. `scripts/command-namespaces.json` gains both command names under `product-workflows`,
which is what lets §13.2 cut a deferred run's window at either of them.

### Added — two `phase-handoff.md` §3.4 row-F rows, and one §4.0 classification

- **`/prd-proposal` on `prd.md`** — **stops**, splitting row F into `PRD_PROPOSAL_NEEDS_PRD` (never
  produced) and `PRD_PROPOSAL_PRD_NOT_HANDED_OFF` (produced, handoff declined). Never optional:
  there is nothing to estimate without it, and the command ships with no pre-gate behaviour to fall
  back to, which is the §3.4 test a stop has to pass.
- **`/brd-proposal` on each included slice's `proposal.md`** — **stops** with
  `BRD_PROPOSAL_SLICE_NOT_HANDED_OFF`, naming every included slice that came back row F in one stop
  rather than one run per slice. **It is the only row in that table that inverts the level rule**:
  the four callers above it refuse a root and their rows describe a slice run, while this one refuses
  a slice and gates a file in each of several **child** folders from the root.
- §4.0 classifies a slice's `proposal.md` as **gated** (conditionally gated is still gated, the same
  call `grounding/design-grounding.md`'s row makes), and an umbrella's `proposal.md`,
  `proposal-brief.md` at either level and the archived `revisions/` snapshots as **unread** — looked
  for, and none found. The §2.9 `prefix` row records that `prd` is now shared by `/prd-proposal`
  alongside `/create-prd`, `/update-prd` and idea-route `/prd-ground`, and `brd` by `/brd-proposal`
  alongside the route's six; the eight prefixes §1 rule 3 fixes are **not** extended.

### Added — both routing-graph nodes in `next-phase-offer.md`

A *PM — effort proposals* section: `/prd-proposal` offers depth (`/brd-proposal`, where the folder
has a parent BRD), breadth (the next unpriced sibling slice) and, below tier 4, the command that
would raise the tier; `/brd-proposal` offers no forward advance at all, because the umbrella is the
end of that branch rather than a phase in the build ladder.

**The `<merge-clause>` rule reaches the pair through the globs the scope paragraph already names** —
`` `/product-workflows:brd-*` `` and `` `/product-workflows:prd-*` `` — so both are inside the rule
by name rather than by adoption, and `check-docs.sh` check 11 gates them without being widened.
**The placeholder appears in exactly one option across the pair**: `/prd-proposal`'s offer of
`/brd-proposal`, whose `require-on-main` gate targets the `proposal.md` that same run has just
written. Every other option in the pair names a command gating on `prd.md`, which neither proposal
command writes, or names the offering command itself.

The scope paragraph also states the property most likely to be misread: neither command is a
prerequisite for the build ladder, none of `/create-ard`, `/specify`, `/epics`, `/design`,
`/implement` or `/ready` reads a proposal, and the pair's one internal read —
`/brd-proposal`'s gate on a slice's `proposal.md` — stays inside the pair and never reaches into the
pipeline above it.

### Changed — counts and enumerations the new commands moved

- `specs-repo-git.md`: twenty-six `commit-artifacts` callers, and §4.1's branch-opening list is
  seventeen, still matching `phase-handoff.md`'s producer count, with `/prd-proposal` named and
  `/brd-proposal` reached by the `/brd-*` glob.
- `feedback-emission.md`: twenty-one of the twenty-six callers ship from a sibling plugin.
- `escalation-rules.md`: both commands cite the *Required path environment variable unset* rule, and
  the clause that used to read "for the last four" now names its commands — counting from the end of
  a list is how it silently came to describe a different set.
- `addressing.md`: `/prd-proposal` joins the commands that are **not** in §7's adopter table because
  each resolves its own single positional address with `resolve-address` (§3). §7's two totals are
  unchanged at twelve files and twelve commands, re-derived rather than adjusted. The two places that
  counted the `/brd-*` consumers now say six, since `/brd-proposal` matches that glob and addresses
  the same parent containers §3's disambiguation step exists to keep addressable.
- `cost-emission.md`'s preamble sketch of who has a §7 row names the effort-proposal pair. The
  paragraph already refuses to be a roster — read the table — but an omitted class is what went stale
  there once before.
- `docs/roles-and-phases.md`: twelve phases exist, nine of them reachable from this plugin only by
  inheritance.

## [1.3.6] — 2026-09-08

### Fixed

- **`grounding-format` §1 reads as it was meant to.** The sentence defining what a finding answers put
  an em-dash clause immediately after a closing parenthesis, so *checked against a pinned revision*
  appeared to qualify the parenthetical rather than the clause it belongs to. The requirement-row list
  is now bracketed by a matched pair of em-dashes and the design-grounding case is its own sentence.
  No rule moved.

## [1.3.5] — 2026-09-08

### Removed

- **`relevant_for_release_notes` is retired from `prd-format`'s frontmatter.**
  It asked a question with one answer — every PRD is relevant for release notes — so the only value it
  could carry that changed anything was one nobody should write. A value left in an existing PRD is read by
  nothing, and the file records the retirement so the field is not reintroduced.

## [1.3.4] — 2026-09-08

### Changed

- **`addressing` §5's legacy fallback is stated as covering the folder name and nothing inside it.** The
  paragraph previously said the fallback meant a user "need never" rename, unqualified, and that claim
  covered artifact filenames it never reached. A tree written before the artifact filenames lost their
  keys still renames its own `<KEY>_<slug>.md` to `prd.md` and `<KEY>_ARD.md` to `ard.md`; no command
  resolves those for it. Recorded as a narrowing rather than a clarification: a resolver for the legacy
  artifact names is derivable from the unqualified claim, and was derived in full before the population
  it would serve was measured.

## [1.3.3] — 2026-09-08

### Added — `phase-handoff.md` §4.0 classifies `code-defect-log.md`

`product-workflows`'s `/brd-interview` now declares `<BRD-dir>/code-defect-log.md` in its
`deliverable_paths`, and §4.0 states four times over that the class table is derived from the tree's
`deliverable_paths` declarations, that an unlisted path is **unclassified rather than unread**, and
that *"a producer adding a deliverable adds its row here in the same change"*. This is that row.

The class is **advisory**: two commands read the file and neither gates on it — `/brd-package`
Phase 0 step 10 reads every `[CDF#n]` in it with its `disposition`, `statement`, `intent` and
`blocked_on`, and `product-workflows:brd-package-reviewer`'s sixth hunt class reads it to settle
whether an `argumentation` claiming a recorded defect actually has one. §3.4 names no `require-on-main`
gate on it, which rules out **gated**, and a named reader rules out **unread** — the two halves §4.0
requires before an array is picked. The row also records that the file's absence is an ordinary state
rather than a declined handoff, since `/brd-interview` writes it only where a round raised an entry.

### Changed — `addressing.md`'s slice-inheritance sentence says *which* defect log it means

§6's nesting-cap rationale said a slice *"inherits `brd/source/` and its defect log"* from its BRD. That
was unambiguous while the route had one defect log; it now has two, and only one of them inherits — the
requirement log is the parent's, the code-defect log is the slice's own. The sentence is qualified, and
names the other so a reader does not conclude the wrong one is reached one hop up. No rule changes.

## [1.3.2] — 2026-09-08

### Changed — `grounding-format.md` §6.3's class-4 reconciliation rule gained a correctness half

A class-4 `[DG#n]` already had to carry a `[CG#n]` citation — completeness was checked, correctness
was not. §6.3 now also requires that the cited finding's `claim` name the same requirement id as
the citing `[DG#n]`'s own `claim`: an absent citation is visibly incomplete and a reader stops, but
a citation that resolves sends the reader to a real finding about a different requirement, which
they have no way to detect by reading — the worse of the two failures. The rule is route-neutral,
like the rest of §6: it reads `claim` off both records the same way whether the requirement id in
front of it is a BRD's `[BR#n]` or a PRD's `[AC#n]`/`[FR#n]`/`[US#n]`, so it needs no route-specific
branch.

`product-workflows:bundle-packaging` §6 is the first enforcer, added in the same release
(`product-workflows` 3.1.0): its citation-resolution check's relation 2 traces this rule over an
assembled bundle's copied corpus files. This release adds the rule and its record shape only —
`grounding-format.md` states no way to run the check itself, since it has no bundle of its own to
check.

This is a patch, not a change of behaviour on its own: §6.3 already required a class-4 finding to
carry a `[CG#n]`; this widens what "carry" requires without altering `design-grounder`'s output
template or any field the format did not already mandate be present.

## [1.3.1] — 2026-09-08

### Fixed — `phase-handoff.md` §3.4's PRD rows named their gate target in prose, so `check-docs.sh` check 11 could not see it

Check 11 gates the `<merge-clause>` placeholder by intersecting an offering run's declared `deliverable_paths` with the offered command's `require-on-main` target, and it reads that target out of §3.4's row-F table — specifically, the backticked `*.md` in the Input column. The `/create-ard` and `/specify` rows both read simply *"the PRD"*, so the extractor found no filename, skipped both rows, and the relation never fired for either command anywhere in the tree. Nothing shipped was wrong; those offers were held by review alone.

Both rows now read ``the PRD (`prd.md`)``. That is the name `/create-ard`'s own Phase 0 resolves on the ref — falling back to the legacy `<KEY>_*.md` form — rather than one inferred from convention, because the row states what the gate targets and a row-F cell that misnames it would be worse than one that says nothing.

**The widening was measured before it was taken, and fires on nothing**: the writer set was extracted afresh for all six commands inside check 11's family globs and none declares `prd.md`. That measurement corrected an earlier estimate — that naming the file would "newly gate every offer of `/create-ard` and `/specify` across the tree" — which had been the reason for parking this. Check 11 only ever examines in-family commands, so `/create-prd` and `/update-prd` were never reachable by it.

Three rows of that table still name their target in prose and are deliberately unchanged: the ARD row and the `/ready` row. Both measured zero-fire too, but an ARD may be split per area and `/ready`'s row covers three artifacts with three resolution rules, so naming a single filename in either would assert something the gate does not.

## [1.3.0] — 2026-09-08

### Changed — `grounding-format.md`'s finding contract widened to a route-neutral claim, not only a `[BR#n]`

`product-workflows` shipped idea-route grounding: `/prd-ground` now takes its claim list from a
PRD's own `[AC#n]`/`[FR#n]`/`[US#n]` rows as readily as from a BRD's `[BR#n]` inventory. §1's finding
definition, §2's finding-record fields, and §6's design-grounding reconciliation classes now speak
of "a requirement id and its text, as the caller supplies them" rather than assuming `[BR#n]` — the
BRD-6 lesson applied one level up: a contract that still names one prefix in its own prose is a
contract whose worked examples keep reproducing it, however route-neutral the field shapes
underneath already were. `code-grounder`, `design-grounder` and `grounding-verifier` resolve an id
against the list the caller handed them, on either route, and their own output templates moved to
match — the same lesson again, since a template the model copies has to change too, not just the
prose around it.

### Fixed — §6.1's foreclosures asserted an absence this release makes false

Two paragraphs said a `/idea`-route `design/` folder reconciling into evidence was "a known and
deliberate state, not a gap" and that the capability "remains deliberately unbuilt on every other
route." Both are now false: `/prd-ground` reads a `design/` frame set as evidence on both routes in
this release. §6.1 is rewritten against what ships — a class-1/2/3 finding settled from the frame set
and the requirement text alone, a class-4 citing a `[CG#n]` and inheriting its commit, either route —
and its writer-versus-consumer paragraph, which forecloses nothing itself but fixes what "consuming"
a frame set means, is read alongside the correction rather than left to imply the old foreclosure
still holds. A cosmetic fix travels with it: §1's requirement-identifier clause had an em-dash-bounded
aside butting straight against a pre-existing parenthetical; the two are now nested rather than
stacked.

### Changed — `next-phase-offer.md`'s scope paragraph, and `check-docs.sh` check 11, now read a second family glob

`/product-workflows:prd-ground` left the `` `/product-workflows:brd-*` `` family the day its own
rename shipped — the rename made it stop matching. It still prints an offer naming a downstream
command whose `require-on-main` gate this same run feeds, exactly as the other five route commands
do, so it carries the `<merge-clause>` convention too, now under its own glob,
`` `/product-workflows:prd-*` ``, named in the scope paragraph on the same line as the first. Check
11's family derivation reads every glob the scope paragraph names rather than only the first, so the
rename does not silently drop `/prd-ground`'s offers out of the gate it was already subject to — a
risk this feature's own design flagged as the one item a sweep cannot fix, because it has to be
designed.

### Fixed — `phase-handoff.md` §2.9 named only two commands sharing the `prd` branch prefix

`/prd-ground` now uses `prefix: prd` on the idea route, which the parenthetical did not name. Fixed
to read "shared by `/create-prd`, `/update-prd` and, on the idea route, `/prd-ground`."

### Fixed — `specs-repo-git.md` §4.1's branch-opener enumeration silently dropped `/prd-ground` after the rename

`/prd-ground` still opens on the shared `brd` prefix on the BRD route, exactly as `/brd-ground` did
before it — but "every `/brd-*` command" stopped matching it the day the rename shipped, and a sweep
that greps for the literal string `/brd-ground` cannot catch this: the sentence never contained it.
The enumeration named nine commands plus "every `/brd-*`" and totalled fifteen only while the glob
still reached the command that is now `/prd-ground`; after the rename the glob matches five, so the
sentence silently named fourteen producers where `phase-handoff.md` still recorded fifteen. Added
`/prd-ground` back in by name, restated the total, and explained why it is named separately from the
glob rather than folded back into it — it left the `/brd-*` glob, not the branch-opening behavior, and
on the idea route it opens on the shared `prd` prefix instead. This is the defect class the rest of
this fix round exists to name: a command that leaves a `/brd-*`-shaped glob without leaving the route
it still serves, invisible to any sweep keyed on the old command name.

### Changed — renamed citations swept through the shared reference corpus

`docs-grounding.md`'s consumer list, `phase-handoff.md`'s branch-prefix and producer/consumer tables,
`feedback-emission.md`, and `workflows-core:frames`'s own command and docs page all cited
`/brd-ground` by its old name. Every citation now reads `/prd-ground`, and `phase-handoff.md`'s
six-consumer / fifteen-producer counts are unchanged — the rename moved a name, not a relationship.

## [1.2.0] — 2026-09-07

### Fixed — a verifier could disagree with a finding and nothing noticed

`grounding-verifier` returns its own re-derived verdict alongside **every** outcome. §8 defines `agree` as reaching *the same* verdict and `extend` as the claim *holding*, so either arriving with a differing `own_verdict` is a return whose two halves contradict each other — and nothing reconciled them. §8 now states the rule: such an outcome is **normalised to `contradict`** and the caller acts on the branch that believes the re-derivation, recorded rather than silent. **`unprovable` is never normalised** — its verdict is `NOT-PROVABLE` and differs from the finding's by definition, while the outcome means only that the verifier's own search settled nothing, so normalising it would rewrite every inconclusive finding into a contradiction nobody reached.

### Fixed — the finding record's field set was open, so a second verdict could be written beside the first

§2.1 fixed the *bytes* of a finding block and left its *field set* unstated. A writer holding the verifier's return therefore had nothing forbidding it from transcribing `own_verdict` into the record, producing a block that states two verdicts at once while `verdict` is what every downstream consumer reads — so a decision citing that finding could quote whichever half suited. Three corpora from a live engagement were counted by hand in this state. §2.1 now names the field set **closed** — §2's fields plus `outcome` and `notes`, and nothing else — and `product-workflows:grounding-verifier` says the same from the emitting end, because fixing the file's writer without fixing the agent whose output the model copies leaves the defect one hop upstream. That is BRD-6's lesson, and this is the same family met at the field set rather than at the bytes.

**Why the existing handling did not cover it.** §8's `contradict` branch has rewritten the finding to the verifier's verdict since `/brd-ground` first shipped. The gap was never that branch — it was that `agree` and `extend` never reached it, and that nothing bounded what a writer could add to the block.

## [1.1.1] — 2026-09-07

### Fixed — two shared authorities carried claims `product-workflows` 2.1.0 falsified

`product-workflows` 2.1.0 shipped the **sibling re-cut**: on a fully-allocated parent BRD, a row the parent delegated to one slice — and that slice's own ledger records `deferred-to: <itself>` for — can be re-pointed onto a sibling that has not been interviewed. Two sentences here described the world before it.

`next-phase-offer.md`'s `/brd-split` row offered grounding *"once per **non-empty** child the run created"* and described a child emptied *"by withdrawing every **provisional** claim"*. Both are now wrong in both directions: the offered set is every child that **gained a row this run**, so the old wording would offer a re-run for a non-empty child that gained nothing — the re-derivation `/brd-split` Phase 7 explicitly forbids — and would omit a standing receiver, the child whose grounding demonstrably no longer covers what it claims; and a re-cut empties a donor by withdrawing a **committed** claim, the eighth site of an appositive whose seven siblings were widened with the feature.

`phase-handoff.md` §3.4's `BRD_GROUND_NOT_HANDED_OFF` row said `/brd-split` is never a way out *"on a fully-allocated parent"*. It is, when that run is **instructed**: the re-cut stages the receiving slice's three files. The row now says **bare**, matching the qualification `/brd-ground` carries at every other site of the same claim.

**Why they were missed.** The feature's own consumer sweep was scoped to `plugins/product-workflows/commands/brd-*.md`, and nothing in this plugin was touched by that branch — so the recipe that found the seven other sites could not see either of these, even though `CLAUDE.md` names this plugin's `next-phase-offer.md` as the authority for the whole `/brd-*` offer convention and for `check-docs.sh` check 11's family derivation. A rule relaxed in one plugin is a claim re-opened in every plugin that documents it.

## [1.1.0] — 2026-09-06

### Fixed — a reader that stops on an artifact now gates it, and the class register is derived rather than remembered

`phase-handoff.md` §4.0 states the rule two increments kept re-deriving: **a stop is only as reliable as the ref it reads.** A command that refuses a state it found in the worktree can be satisfied by a file nobody else can see, so the refusal protects the operator who ran the producer and no one else. Found twice, in `/brd-split`'s design gate and `/brd-package`'s round gate, both of which had inherited a sibling's `require-on-main` through a "one handoff, one commit" implication that `/brd-ground --no-code` had already falsified. Both now gate what they stop on, and both have §3.4 rows.

The register itself is now derived from the tree's `deliverable_paths` declarations instead of from memory, and carries every artifact they name — including the four with no reader found, listed rather than omitted so that absence from the table means *unclassified* and never *unread*. It had twelve rows against roughly thirty declared paths; the gap cost nothing only because most unlisted artifacts rode in a set that already held a gated path, and `--no-code` produced the first set with no classified path in it at all.

`feedback-emission.md` §4's persist predicate said "the dev-workflows plugin itself" — one plugin of four, read literally dropping every signal about the other three — and reached for `${CLAUDE_PLUGIN_ROOT}/references/**` two paragraphs below the note explaining why that variable resolves to the wrong tree here. `/feedback` said the same thing three times in user-facing text.

### Added — the two session-wide hooks, and a serialisation the grounding artifacts never fixed

`notify-done` and `test-notify` now ship here. Both are session-wide rather than command-scoped, and every plugin in the family declares `workflows-core`, so one copy serves all of them instead of a copy per plugin (I4-3). Install or update `workflows-core` and both hooks arrive with it.

`grounding-format.md` gains §2.1, which fixes how a `[CG#n]`/`[DG#n]` finding is written to disk — one space after every key's colon, never alignment padding, keys in §2's order, an inapplicable field omitted rather than left empty. Nothing had fixed it, so a writer aligned one section of a `code-grounding.md` and not the next; a scan of that file then reported **140 findings as missing that were on the page**. §2.1 also states the reading rule that outlives the fix: resolve an id against the finding set you parsed, never by matching a column, and report a disagreeing count as a parse failure rather than as an absence.

### Fixed — a frame-set index is read, and every producer had been told it was not

`phase-handoff.md` §4.0's class register said a frame-set `index.md` was **unread**. It is not: `product-workflows:design-grounder` refuses to run on a frame set holding no index, and `grounding-verifier` returns `NO_INDEX`/`STALE_INDEX` on one. The index is **advisory** — read from the working tree, gated by nothing — and `/frames` now presents the advisory consent array. Until this fix it presented the unread array, telling the operator that nothing downstream reads a file `/brd-ground` refuses a frame set without, three lines above its own paragraph saying the set stays `NO_INDEX` for everybody else.

The register was verified against the tree rather than carried forward, which is how this surfaced: the gated row is a two-way match with §3.4's Input column, and each advisory row was re-derived by opening the reader it names. The **unread** class now has no member *in the register*, which is not the same as no artifact being unread — `slices.md` is handed off and no reader was found for it. §4.0 now says outright that it classifies the artifacts whose class a producer has had to resolve rather than everything the family hands off, and that an unlisted path is unclassified rather than unread.

### Fixed — the rest of the release-gating ledger

- **PS1** — an unwritable `.git` and a `$SPECS_PATH` that is not a repository are different states. The first is a silent no-op; the second now emits a named notice. Neither is ever fatal.
- **PS2** — `/frames` adopts a frame-set index kept under another name instead of refusing the set.
- **PS3** — the cost-boundary detector's *cut* test is now separate from its *claim* test. A command from outside this marketplace ends the open window without being claimable; before the split its spend was absorbed into somebody else's claim.
- **I4-6 / I4-7** — `<default-ref>` is resolved by probing for an `origin` remote and is owned by `specs-repo-git.md` §3.2, which `phase-handoff.md` now cites rather than redefining. Three git calls outside `require-on-main` had hardcoded `origin/<default>` too.
- **"this plugin" named the wrong plugin** in `cost-emission.md`, `feedback-emission.md` and `phase-handoff.md` §3.4. Each now names `workflows-core` outright, or says "the family" where the referent is family-wide — §3.4's row-F paragraph in particular, where the gate routinely runs across a plugin boundary and a one-plugin reading would stop the route at each one.

## [1.0.0] — 2026-09-03

### Added — the shared foundation of the `dev-workflows` plugin family

`workflows-core` is the second increment of the marketplace split designed in `docs/superpowers/specs/2026-09-02-marketplace-split-design.md` (the first extracted `guideline-reviewers`). It carries what more than one plugin in this family reads, so that a family member can be installed without dragging the rest of the pipeline along with it.

**Twenty-nine reference files**, moved from `dev-workflows` with their rules intact — what changed in the move is how they are *cited*, not what they say: the addressing grammar, the specs-repo git entry points and phase handoff, model routing, escalation, finding triage, grounding and grilling technique, the PRD format, cost / feedback / follow-up emission, and the price table they cost against.

**Six commands** — `/feedback`, `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`, `/statusline` and `/frames`. The first five are family-meta: they log friction about the plugin family itself or drive its status line. `/frames` indexes a design frame set, which every phase of the pipeline may hold.

**Five agents** — `code-scanner`, `doc-fixer`, `docs-grounder`, `frame-describer` and `impl-maintenance` — each dispatched by commands in more than one plugin, as `workflows-core:<agent>`.

**Two skills.** `model-routing` is the one that moved. `reference` is new, and it is the mechanism the whole split turns on: `${CLAUDE_PLUGIN_ROOT}` resolves to the *reading* plugin, so a dependent plugin cannot read a shared reference by path. `Skill(skill: "workflows-core:reference", args: "<name>")` reads one reference by name; an optional second argument names an entry point within it to execute inline. One argument-taking skill serves the whole corpus, rather than one wrapper per reference.

**The cost helper**, `scripts/session-cost.py`, and the status-line script beside it. New alongside them is `scripts/command-namespaces.json` — namespace to that plugin's own command names, one entry per plugin of this marketplace that ships commands — which is what command boundaries now resolve against.

`dev-workflows` 3.26.0 declares `workflows-core` as a dependency, so installing it installs this. The two changes below are stated against the same machinery as it shipped inside `dev-workflows` up to 3.25.0, because that is where it ran until now.

### Removed — `session-cost.py --commands-dir`, a breaking change for direct callers

**The flag is gone, not deprecated.** Anyone invoking `scripts/session-cost.py` by hand or from their own tooling and passing `--commands-dir` gets an unknown-argument error and must drop it. That failure is loud on purpose — an unrecognised flag is an error, never a silently ignored one — but it is real, so it is stated here rather than left to be discovered.

Nothing replaces it. The flag existed to hand the script one plugin's `commands/` directory as the set of names a slash-command boundary could be drawn from, and that is precisely the assumption the split had to abandon: a family that spans several plugins has no single such directory. Boundaries now resolve against `scripts/command-namespaces.json`, shipped beside the script and read with no flag and no path assumption. `--namespaces <path>` overrides that manifest and exists to be pointed at a test fixture; where it resolves to nothing, boundary detection is off and every claim is reported unmatched and dropped, rather than guessed at.

### Fixed — a replayed cost claim could absorb a sibling plugin's spend

A command that cedes the session (`/prompt-brainstorm`, `/prompt-grill-me`) cannot write its own cost entry, so it records its labels and the next cost-emitting run writes the entry on its behalf, splitting its window at the transcript's record of where that run began. The boundary used to be accepted only as `<this plugin>:<this plugin's own command>` — resolved against whichever single plugin supplied the command set. Once the family spanned more than one plugin, an intervening command **from a sibling plugin** was not recognised as a boundary at all, and a claim is given the segment up to the next boundary of any kind. The claim therefore swallowed the sibling's run whole.

Nothing was ever double-billed and no entry already written on disk was corrupted. What went wrong is attribution *between two entries of the same replay*: the deferred command's entry was charged for work it did not do, and the replaying run's own remainder was short by exactly that amount. Reproduced at 9000 tokens claimed where 5000 was correct.

Both halves of a boundary now resolve against the manifest — the namespace must be a key of it and the name must appear in *that key's* list — which is why widening the accepted namespaces alone would not have been enough, and why the fix still rejects a bare built-in whose name a plugin here happens to share, and still rejects another marketplace's identically-named command. `session-cost.py --selftest` pins each of those properties against the broken implementation it exists to catch, including the half-fix that widens namespaces without widening the per-namespace name sets.
