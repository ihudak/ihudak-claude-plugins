---
name: frames
description: (Re)builds the frame-set index of one resolved folder. For each design/<frame-set>/ subdirectory of a BRD, PRD or Epic folder it lists the images, reads the index already there, describes the frames no row accounts for, and writes the index that references/grounding-format.md §6.1 makes mandatory and §6.2 formats. This is the recovery path for a frame set a human exported and dropped in by hand, which design-grounder otherwise refuses on sight as NO_INDEX. Indexing only — it dispatches no design-grounder, produces no [DG#n], and reaches no verifier. Writes into the resolved folder; on a completed handoff it also opens a pull request for the indexes it wrote (`references/phase-handoff.md` §2); its session artifacts are committed by `commit-artifacts`.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

(Re)build the frame-set indexes of: $ARGUMENTS

`design/` is a reserved subdirectory of **any** folder under `specifications/` — a BRD folder, a PRD
folder, or an Epic folder alike — and each of its immediate subdirectories is one exported frame set
(`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §6.1). That section makes each set's **index
mandatory and its absence unrecoverable**: `design-grounder` returns `NO_INDEX` rather than reading a
set without one, because a filename is not a reliable statement of what a frame shows.

**This command is the recovery path for that.** The obvious workflow — a human exports frames and
drops the folder in — produces a set nothing can read, and until this command the only way out was
hand-authoring an index. `/frames` looks at the frames and writes the index for every set of one
resolved folder.

**`/frames` is not design grounding, and must not be mistaken for it.** Indexing makes frames
*readable*; grounding makes them `[DG#n]` findings. This command dispatches no `design-grounder`,
produces no finding, cites no `[BR#n]` or `[CG#n]`, and never reaches `grounding-verifier`.
`/idea`-route design grounding remains deliberately unbuilt, §6.1 says so, and this command keeps
that true. The one command that grounds a frame set is `/brd-ground`, on the BRD route.

**The name.** `design/` and *frame set* are §6.1's own vocabulary, so `/frames` names what it acts on.
It is deliberately not `/design-index`: `/design` is the engineering-design workflow, and a name
adjacent to it would invite an operator who wanted an index into the wrong command.

---

## Phase 0 — Resolve the address + model routing

0. **The environment.** `$SPECS_PATH` must resolve: every path this command reads or writes is under
   it. Unset or not a directory → apply the *Required path environment variable unset* rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` and stop there. Without this the only
   reachable stop is the key-resolution one below, which would report "no folder under
   `/specifications/`" — a message naming a failure that is not the failure.

   **`/frames` defines no flags, and takes exactly one address.** A second non-flag token, or a token
   beginning with `--`, is a stop rather than a silent discard:
   `FRAMES_EXTRA_ARGUMENT: /frames takes one address and no flags; '<token>' is neither. It indexes the frame sets of one folder per run — re-run once per folder.`
   A discarded second address is a folder the operator believes was indexed and was not.

1. **The address (mandatory).** Parse the first non-flag token and resolve it with `resolve-address`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3) — a key, or `@<path>` to a folder or a file
   inside one. **Pass no `<KIND>`**: `design/` is reserved at every level, so a BRD folder, a PRD
   folder and an Epic folder are all valid targets and narrowing the resolution would refuse two of
   the three. Absent or malformed → stop:
   `FRAMES_NEEDS_ADDRESS: /frames needs the folder whose frame sets it should index — a key (^[A-Z][A-Z0-9_]*(-\d+)+$, e.g. ACME-77) or '@<path>' to the folder. Re-run '/dev-workflows:frames <KEY>|@<path>'.`

   Handle the resolution record exactly as it comes back:
   - `status: invalid` → the same stop above, naming the token that failed the grammar.
   - `status: absent` → stop:
     `FRAMES_NO_FOLDER: no folder under $SPECS_PATH/specifications/ asserts key <KEY>. This command indexes an existing folder's frame sets and creates no folder. Re-run with '@<path>' to the folder, or with the key of one that exists.`
     **This command creates no folder**, so `absent` is a stop rather than a create.
   - `status: ambiguous` → §3 rule 5's hard stop, naming **every** match and `@<path>` as the way
     through it. Never choose between them.
   - `status: found` → carry `path`, `kind` and `key`. Report `legacy: true` once as deprecated when
     §5's fallback resolved it.

   **Then test the kind, because passing no `<KIND>` removed the only guard the path branch had.**
   §3's path branch checks a supplied `<KIND>` against the folder's own and nothing else, so with none
   supplied *any* directory resolves. `kind` must be one of `brd`, `prd`, `epic`; anything else — or a
   folder asserting no `kind:` at all — is a stop:
   `FRAMES_NOT_A_SPEC_FOLDER: <path> is not a BRD, PRD or Epic folder (it asserts <kind, or 'no kind'>). A design/<frame-set>/ directory is one of the sets this command indexes, not the folder that holds them. Re-run against the folder above it — '/dev-workflows:frames <KEY>' or '@<path to that folder>'.`
   **The reachable case is the documented one**: `@<path>` to a frame image resolves to its parent — the
   frame-set directory — whose `index.md` asserts `kind: frame-set-index` (§6.2's frontmatter). Without
   this gate the run would look for `design/` *inside* a frame set, report "no design/ subdirectory"
   about a directory visibly holding frames, and reach Phase 4's cost attribution on a kind
   `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` declares unreachable precisely because this
   refusal exists.

2. **Resolve model routing.** Invoke the `model-routing` skill (Skill tool,
   `skill: "dev-workflows:model-routing"`), then record:
   ```yaml
   model_routing:
     classification: MODERATE          # a bounded read plus a mechanical reconciliation
     reason: <one-line>
     current_model: <the model this orchestrator is running under>
     detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # frame-describer
     opus_available: <true if a §2 Opus model resolved, else false>
     notes: <any §2/§2.1 fallback or degradation>
   ```
   `frame-describer` runs on `detection_model` — describing a picture is detection work, not
   judgement. **No Opus is required anywhere in this command** and no reviewer gates it: there is no
   artifact of opinion here to review. If no model of the detection chain resolves, degrade to the
   best available and record it in `notes` and the Final report.

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run,
retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent when the
specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns
`specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts`
step skips on it.

---

## Phase 1 — Enumerate the frame sets

1. **List the immediate subdirectories of `<folder>/design/`.** Each one is a frame set. Do not
   recurse: §6.1 fixes one set per *immediate* subdirectory, and a directory nested deeper is part of
   whatever that set holds, not a set of its own.

2. **No `design/` at all, or a `design/` holding no subdirectory → report and stop, having created
   nothing.** This is a clean outcome, not a failure and not a stop worth a hard-stop token:
   ```
   frame sets: none — <folder> has no design/ subdirectory (nothing created)
   ```
   or `… — <folder>/design/ holds no frame set (nothing created)`.
   **Create no `design/`, create no
   frame-set directory, and write no index.** §6.2 step 6 forbids writing an index where the listing
   is empty, and an empty `design/<frame-set>/` is a directory `design-grounder` would open for
   nothing. Skip Phases 2 and 3 entirely and go to Phase 4 — the run still records its own spend.

2a. **Images sitting directly in `design/` are reported wherever they are found — not only when
   there is no frame set.** A set is a subdirectory of `design/`, so a frame dropped into `design/`
   itself is indexed by nothing. Say so and name the fix:
   `design/: N images sit directly in design/ and are in no frame set; a set is a subdirectory. Move them into design/<set-name>/ and re-run.`
   **This test is deliberately outside item 2.** Nesting it there — its first home — made it
   unreachable in the state that produces it most often: `/idea` creates `design/idea-sources/` for
   any idea-route folder whose source linked a readable image, so `design/` very commonly holds a
   subdirectory *and* loose frames an operator exported later. Item 2 does not fire then, and the
   loose frames went unmentioned while the run reported success on the sets it did find. A guard for
   a near-miss has to fire in the mixed state or it does not fire at all.

3. **List each set's images** — every file carrying one of the frame extensions §6.2 step 1 fixes.
   The set is that section's, not this command's: two writers of one index listing by two vocabularies
   would each drop the other's rows as images that are no longer there. This listing is §6.2 step 1
   and it is the whole truth about what the set holds; `index.md` is not a frame and is never a row.
   A set whose listing is **empty** is reported and skipped — nothing is written into it and nothing
   is removed from it, exactly as §6.2 step 6 requires.

   **Hold every file in the set that is NOT in that extension set, and name each once.** §6.2 step 1
   requires it of every writer — *"a writer that finds one names it once in its own report so it is
   visibly not indexed rather than invisibly missing"* — and this run is the writer. It gets no row
   and is never described; it is reported so an operator who exported a `.fig`, a `.pdf` or a `.sketch`
   into a set learns it will never be grounded, instead of inferring it from a row count. `index.md`
   itself is excluded: it is this format's own file, not an un-indexed frame.

4. **Read the index already there, where there is one.** `index.md` is the name every writer writes
   (§6.2). An index found under **another** name — a manifest, a captions file, a README — is
   reported and left byte-for-byte alone: this command did not fix that file's shape and will not
   rewrite it. It writes `index.md` beside it, and the report says both files are now present so the
   operator can retire the older one deliberately.

---

## Phase 2 — Describe and index, one set at a time

**One authority, executed inline and restated nowhere.** Cite
`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §6.2 and run its six reconciliation steps for
each set. That section owns the filename, the frontmatter, the table shape, the `Linked from`
semantics, and every step below that is not about *this* command's cap. **It is the same contract
`/idea` Phase 4.5 follows** — deliberately, because two writers reconciling one directory by two sets
of rules is how a set ends up holding an index neither of them would have written.

For each frame set, in directory order:

1. **Reconcile the listing against the index in memory first.** Every frame in Phase 1's listing falls
   into exactly one of:
   - **has a row whose description is real** → §6.2 step 2 preserves it **verbatim** — the frame, its
     `Linked from`, and its description exactly as they stand. This command never rewrites a
     description it did not produce, and never re-describes a frame that already has a row in
     `index.md` — an index under some other name is reported and never read, so it neither preserves
     nor contradicts what that file happens to say.
   - **has a row whose description is the literal `_no description on record_`** → §6.2 step 2's one
     exception. That row holds no description to preserve and this command *can* obtain one, so the
     frame joins the describe set. **This is what makes a capped run recoverable**, and it is why the
     placeholder is a marker rather than an answer.
   - **has no row at all** → the frame joins the describe set (§6.2 step 3).

   A row whose image is **not** in the listing is dropped (§6.2 step 5) and reported. Nothing is
   restored and nothing is re-copied: this command reconciles an index with a directory and never
   manages the directory. **It deletes no image, ever.**

2. **Apply the cap — 40 frames described per run, counted across every set the run touches.**
   Consume the budget set by set in directory order, and within a set in listing order.

   **Why 40, and not `/idea`'s 6.** That cap bounds an *incidental* read inside a command whose
   subject is a brief; six mockups is generous for that. This command is invoked precisely *to*
   index, so a cap of six would make it useless on the first real export it met. Forty is the size of
   a feature's screen flow as humans actually export one, and it is a bound on the most
   context-expensive read this plugin does: forty images in one `frame-describer` context, and none
   of them in this orchestrator's.

   **What happens when it bites.** Every frame past the budget stays in the listing and still gets a
   row — §6.2 step 4's `—` and the literal `_no description on record_` — with `cap` as its reason in
   the report. **The index is still valid and complete**: §6.2 writes the file once, after every row
   is resolved, so a capped run leaves a full index rather than a half-written one, and every frame
   in the set is named in it. The run reports the cap and names the re-run that finishes the job.
   Because step 1 treats that placeholder as a row to be filled rather than preserved, each re-run
   describes up to 40 more and the set converges — 100 frames is three runs, and no run ever leaves
   the set unreadable in between.

3. **Describe the frames in this set's describe set — where there is one.** An **empty** describe set
   dispatches nothing: every frame already carries a real description, or the cap was spent before this
   set. That is the ordinary shape of a re-run over a complete index and of every set after the one the
   cap fell in, and `frame-describer` refuses an empty `frames` list with `INPUT_MISSING` — so
   dispatching would spend an agent to manufacture a failure status, and the report would name a set
   that "stopped" while being complete and correct. Skip to step 4 and write the index from the rows
   already resolved.

   Otherwise dispatch once per set, never per frame:

   → Agent (subagent_type: "dev-workflows:frame-describer", model: `<detection_model — §2.1 Sonnet chain>`):
     > "Describe these frames and return the structured result:
     >
     > frame_set_dir: [absolute path of this design/<frame-set>/ directory]
     > frames:        [the basenames in this set's describe set, in listing order]
   "

   Wait for the result. On `status: INPUT_MISSING` or `FRAME_SET_MISSING`, describe nothing for this
   set, give **every** frame in its describe set the `_no description on record_` row with that status
   as the reason, and carry on to the next set — a set this command could not look at is still a set
   whose index must state what it holds. On `OK`, pair `frames[]` with the listing **by basename** and
   take each `description` **verbatim**. An entry with `read: false` gets the placeholder row and its
   `reason` (`missing`, `not_an_image`, `unreadable`, `not_a_frame`) is reported.

   **Never write a description this command produced itself.** `grounding-format.md` §6.1's index rule
   exists to forbid exactly the inference a filename invites, and this orchestrator never sees the
   image — which is the point of dispatching an agent rather than reading here.

4. **Write the index** per §6.2 step 6 — once, whole, after every row is resolved. `key` is the
   resolved folder's own key as Phase 0 read it (never parsed from a directory name);
   `frame_set` is this directory's own name; `written_by` is `/frames`, including on a set `/idea`
   wrote first — that field records who last wrote the file and nothing keys off it.

5. **Nothing here is fatal.** A set that could not be described, an index that could not be written
   (permissions, a full disk), a frame that would not open — each is recorded against that set and the
   run moves to the next one. A failure in one set never abandons the sets after it, and never fails
   the run.

Hold, per set: the index path **as a repo-relative path** — that is the form `deliverable_paths`
takes in Phase 3, and `handoff-to-main` §2.3 matches it against `git status --porcelain` output, which
is repo-relative; an absolute path there matches nothing and stages nothing, silently. Hold also how
many rows it now holds, how many this run added, how many it
preserved, how many carry `_no description on record_` and why (`cap`, `missing`, `not_an_image`,
`unreadable`, `not_a_frame`, or an agent status), and every row dropped because its image is gone.
Hold also **each file in the set that is not a frame at all** (Phase 1 step 3), which carries no row
and must still be named, and **any `notes` the describer returned** — a frame illegible at the
resolution supplied, or a set that is plainly several unrelated exports. `frame-describer` documents
`notes` as output and nothing read it, so the observation it exists to surface was discarded; it is
reported, never acted on, exactly as `/brd-ground` consumes `design-grounder`'s. Carry the literal list of index paths written into Phase 3.

**The bookkeeping steps do not stage any of this.**
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1 classifies `design/**` as OTHER, so
`commit-artifacts` never touches an index. They are deliverables, and they reach the default branch
only through Phase 3's handoff.

---

## Phase 3 — Handoff

**Only where at least one index was written.** A run that wrote none — no `design/`, no set, every
set empty — has no deliverable, offers no handoff, and says so; offering one would name a pull
request for nothing.

Report what each set now holds, then present
`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's consent choice verbatim — the **no-§3.4-row variant**, whose second option says nothing downstream reads this rather than promising a stop. A frame-set index has no downstream gate, so the default array's parenthetical would be false here and would contradict the §4.1 clause this phase prints on a decline. On the first
option, execute `handoff-to-main` (§2) with all five of its §2.9 inputs: `prefix: frames`;
`feature_folder` = the folder Phase 0 resolved; `deliverable_paths` = **every `index.md` this run
wrote, one literal path each, repo-relative as Phase 2 held them**; `title: <KEY> Index design frame sets`; and
`body_facts` = each set with its row count, how many rows this run added, how many carry no
description on record and why, and every row dropped.

**The indexes are named literally, one path each — never a directory and never a glob.** §2.3 stages
by enumeration and classifies everything it was not handed as OTHER, so an index left out of this
list is one that never reaches the default branch: the set stays `NO_INDEX` for everybody but the
operator who ran this command, which is the exact state the run set out to repair. Pass the list
Phase 2 held, unchanged.

**Decline and the indexes are written but on no ref.** They are still on disk, and a grounding pass
reads a frame set from the working tree rather than off a ref, so a declined handoff is an unshared
repair rather than a blocked one. Say that, and say one thing more, because it is not free: each
index is an OTHER path under `design/**`, so on the next run of any command sharing this repo
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §3.3's **G1** matches — the preflight ends there
at advisory severity listing the paths, and §3.4's leftover flush and §3.5's branch disposition are
suppressed for the rest of that session. G1 does not set `specs_git: blocked`, so nothing is lost or
halted, and the suppression repeats until the paths are committed or the handoff is taken. Beyond
those two facts, neither more nor less — and name no command that could not run against the folder
this run actually resolved.

**No downstream gate reads these files, so no offer here carries a `<merge-clause>`**, and a declined
run takes §4.1's third `<next-phase-clause>` — the one written for an artifact with no §3.4 row. Nothing runs
`require-on-main` on a frame-set index (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3.4's
table names none), and `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`'s rule attaches the
clause to an offer naming a gate this run's own output feeds. There is none. Recommend nothing
unconditional either: this command sits beside the pipeline rather than inside it, and what to run
next is a question about the folder, not about the index.

### Context hygiene

No `resume.md` is written for `/frames` (`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 skip
list — indexing is not a pipeline phase, so there is nothing to resume; the durable state is the index
on disk and the pull request).

A `/frames` run over a large set carries forty descriptions and nothing else it needs to keep. Going
on to other work in this session? → run **`/compact`**; every index is already on disk. Guidance only —
see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.

---

## Phase 4 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 3, NEVER interrupts an earlier phase, and **runs on every path that reached Phase 1**,
including the run that found no `design/` at all.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference
gap** (a capability the run needed but the plugin lacked), `emit-block` (per
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating. NEVER
`emit-block` for an environment / user halt (an address that resolves to nothing, a cancellation).

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /frames
   > - What was done: [the folder resolved, how many frame sets, how many frames described, how many indexes written]
   > - Key events: [frames that could not be read, sets skipped, the cap biting, an index found under another name, rows dropped — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: N/A (no reviewer in /frames)
   > - Test result: N/A (no tests in /frames)
   > - Project root: [the resolved folder]"
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /frames`, `key` = the resolved folder's key, the run's
   `source`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`).
   Surface the persisted path (or "no plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call
   its `emit-cost` entry point with `command: /frames`, `phase: inferred`, `role: inferred`, `key` =
   the resolved folder's key, the run's `source`, and `plugin_version`. §7's discriminator is the
   resolved folder's own `kind`, which Phase 0 already read: `brd` attributes the run to
   `brd-to-prd`/`pm`, `prd` and `epic` to `prd-creation`/`pm`. The key is always present on any path that reaches here — Phase 0's stops (`FRAMES_NEEDS_ADDRESS`, `FRAMES_EXTRA_ARGUMENT`, `FRAMES_NO_FOLDER`, `FRAMES_NOT_A_SPEC_FOLDER`, an ambiguous key, an unset `SPECS_PATH`) all refuse before a folder is resolved, and this phase runs after them, which is why its scope is stated as *every path that reached Phase 1* rather than every path. This
   command refuses to run without a resolved folder — so the entry lands on the keyed tier and never
   on the pending ladder (§9), which **advances the chained checkpoint** (§3); surface the persisted
   path (or the report-only notice).
4. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`
   and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages
   ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows session
   artifacts (/frames)` and pushes. It NEVER touches a code/docs repo or the current working
   directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries
   `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its §6 outcome line for the Final
   report.

ADDITIVE — this phase NEVER fails the run, NEVER commits a deliverable (each `index.md` is handed off
separately, before this phase, via `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2, behind
Phase 3's §4.3 consent choice), and NEVER writes into a code/docs repo or the current working
directory; no user name is ever written.

---

## Final report

Report: the resolved folder with its `kind` and `key`, and whether §5's legacy fallback resolved it;
**the frame sets found**, or plainly that there were none and that nothing was created — naming no
directory this run did not actually create. Then, per set: the index path and whether it was
written, created, or rewritten; how many rows it now holds; how many rows this run **added**, how
many it **preserved verbatim**, and how many carry `_no description on record_` with the reason for
each (`cap`, `missing`, `not_an_image`, `unreadable`, `not_a_frame`, or the agent status that
stopped the set); every row **dropped** because its image is no longer in the directory; a set
skipped for holding no image; **each file in the set that is not a frame**, named once so it is
visibly not indexed rather than invisibly missing (§6.2 step 1); and an index found under a name
other than `index.md`, with the fact that `index.md` now sits beside it. Report, too, any images
sitting directly in `design/` outside every set (Phase 1 step 2a).

**Report the cap explicitly whenever it bit** — how many frames were described, how many were left,
and that `/dev-workflows:frames <the same address>` describes the next 40 and converges. State the
count even when it did not bite ("all N frames described; the 40-frame cap did not apply"), because
the absence of a truncation notice is only informative once the run is known to print one.

Also report: the resolved model routing (with any degradation); the feedback path; the cost path (or
the report-only notice); the `Specs repo:` outcome line from `commit-artifacts`
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full;
and the `Phase handoff:` outcome line when the handoff ran, or the fact that it was declined and the
indexes are on disk and on no ref.

**Say what this run did not do.** It reconciled no frame against any requirement, produced no
`[DG#n]`, and dispatched no `design-grounder` — the indexes make these sets *readable*, which is a
precondition of design grounding and not design grounding itself.
