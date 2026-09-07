---
name: brd-ground
description: BRD-grounding workflow (PA phase of the BRD-to-PRD route, run once per slice `/brd-split` carves, and again on an already-ground slice a later re-cut gives a new row). Pins every mounted repository to a verified commit, grounds every [BR#n] claim against code (code-grounder) and an exported design frame set (design-grounder), independently re-derives every finding (grounding-verifier, Opus), and assigns each finding a current/will-change horizon against declared prerequisite BRDs. Read-only against every repository. Grounds on the shipped product documentation when $DOCS_PATH resolves (off with --no-docs, and under --no-code) — as a lead and a divergence finding, NEVER as evidence for a [CG#n]. Optional --depends-on persists prerequisites to brd-link.md; --no-code adds design grounding over an already-verified code grounding without re-deriving it; --derivation-matrix adds an implementation-altitude build list; --rebaseline re-runs against moved code, superseding findings by ID. Offers /brd-split as the next step.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Ground the BRD's requirement inventory against code and design: $ARGUMENTS

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

`/brd-ground` is the **BRD-to-PRD route's grounding step** (PA phase), run once per slice
`/brd-split` carves — and **again on an already-ground slice a later re-cut gave a new row**, the third of the three cases `commands/brd-split.md` Phase 7 distinguishes when it offers this command, because no `[CG#n]` on file was derived against a row that arrived after them — it takes the `[BR#n]` inventory that slice's own `brd/brd-inventory.md`
holds and checks its premises against real code and real design assets, at pinned commits, rather
than letting a plausible-sounding claim stand unverified. Every
finding is independently re-derived by a different agent before it counts as evidence
(`workflows-core:grounding-format` §8) — this command's whole job is to make
that discipline happen, not to ground anything itself.

Usage: `/brd-ground <BRD-KEY> [--depends-on <BRD-KEY>…] [--derivation-matrix|--no-derivation-matrix] [--no-code] [--no-design] [--no-docs] [--docs <path>] [--rebaseline]`

`<BRD-KEY>` still resolves through either of the two levels `resolve-address` searches
(`workflows-core:addressing` §3) — a BRD that owns its source document, or one of its slices —
because a root must be resolved before Phase 0 step 5a can refuse it by name. **Only a slice is
ground: a root BRD is refused, and grounding happens at the slice and nowhere else**, over the
requirements that slice's own inventory claims.

**Standing rule, stated in full at Phase 4.5 and binding on every phase: documentation is a lead
and a divergence finding — it is NEVER evidence for a `[CG#n]`.** No finding this run writes may
cite a documentation page in its `evidence`, under any verdict. A document is a claim *about*
behaviour, not the behaviour.

**`--no-code` is a run mode, not a step skip.** It exists so a BRD whose code grounding is already verified can gain the design grounding it is missing — the state `/brd-split`'s design-presence gate reports — without re-deriving what is already on file. Under it, **`<BRD-dir>/grounding/code-grounding.md` is read-only for the whole run**: this invocation produces no `[CG#n]` at all, its finding set is the new `[DG#n]` only, and every `[CG#n]` already on file keeps the verdict, evidence and verifier outcome it carries — never renumbered by Phase 5, never re-dispatched by Phase 7, never rewritten by Phase 8. Phases 1 and 3 still run in full, because a class-4 `[DG#n]` is pinned to the commit of the `[CG#n]` it cites and Phase 7 re-derives it against that repository. Documentation grounding is off for this run, and so is the derivation matrix: Phase 8 appends both into that same read-only file. Four flag states are refused rather than reconciled, all in Phase 0 step 2.

---

## Phase 0 — Resolve inputs and gate on main

1. **`<BRD-KEY>` (mandatory).** Parse the first token that is neither a flag nor a flag's value — `--depends-on` and `--docs` each consume the token after them (step 2), and a value skipped as "non-flag" would be read as the key; validate with `key-valid`
   (`workflows-core:addressing` §1). If absent or invalid, stop:
   `BRD_GROUND_NEEDS_KEY: /brd-ground needs a BRD key (shape ^[A-Z][A-Z0-9_]*(-\d+)+$) — re-run '/product-workflows:brd-ground <KEY>'.`
2. **Flags.** `--depends-on <BRD-KEY>` — repeatable, each consuming the next token; validate each
   with `key-valid` and drop (warn, do not stop the run) any that fail shape. `--no-design` —
   boolean, skips Phase 5's `design-grounder` step. `--no-docs` — boolean, turns documentation
   grounding off for this run (Phase 1 step 0, Phase 4.5). `--docs <path>` — points documentation grounding at that root for this run instead of `${DOCS_PATH:-/workspace/docs}`; **strip the flag and its value together** before any remaining-argument classification, or the path is read as part of the address. Declared for every consumer by `workflows-core:docs-grounding` §1's *Flags first* rung, which resolves it; this command only has to recognise it and pass the invocation through. `--rebaseline` — boolean, see Phase 3. `--derivation-matrix`
   / `--no-derivation-matrix` — mutually exclusive; absent means "let Phase 8 decide the default".
   `--no-code` — boolean, the **run mode** stated above the phases. Its four refusals are checked
   here, before anything expensive runs:
   - With `--no-design`, nothing is left to ground:
     `BRD_GROUND_NOTHING_TO_GROUND: --no-code and --no-design together leave this run nothing to ground — drop one and re-run '/product-workflows:brd-ground <BRD-KEY>'.`
   - With `--rebaseline`, which supersedes `[CG#n]` findings by id — a write this mode forbids:
     `BRD_GROUND_NO_CODE_REBASELINE: --rebaseline supersedes [CG#n] findings by id, which --no-code forbids — re-run '/product-workflows:brd-ground <BRD-KEY> --rebaseline' without --no-code to re-ground the moved code, or drop --rebaseline to add design grounding over what is already on file.`
   - With an **explicit** `--derivation-matrix`, which Phase 8 appends into `code-grounding.md`:
     `BRD_GROUND_NO_CODE_MATRIX: the derivation matrix is appended to grounding/code-grounding.md, which --no-code forbids writing — re-run '/product-workflows:brd-ground <BRD-KEY> --derivation-matrix' without --no-code.`
     An explicit `--no-derivation-matrix` is redundant here but harmless; an unset default resolves
     **off** under this mode and is reported rather than left silent.
   - Where there is no verified code grounding to build on. This one needs the resolved folder, so
     take it immediately after step 5a rather than here — **after**, never before. **Not only on a
     slice, though**: step 5a refuses every root it can identify as one, but the interrupted-intake
     folder passes it unrefused (`coverage-ledger-format.md` §5.1) and reaches this check too, before
     step 6 would otherwise name it properly. It fails here the same way an under-grounded slice
     does, and the redirect it gives still lands on step 6's own stop for that folder on the next
     run. Stop when
     `<BRD-dir>/grounding/code-grounding.md` is absent, holds no `[CG#n]`, or holds one carrying no
     verifier `outcome`. The third is the state `/brd-split` itself refuses
     (`workflows-core:grounding-format` §8), so reporting it now costs one read and saves a whole
     design pass that still could not split:
     `BRD_GROUND_NO_CODE_UNGROUNDED: --no-code adds design grounding over an existing code grounding, and <BRD-KEY> has <no code grounding on file | no [CG#n] findings | N of M [CG#n] findings carrying no verifier outcome> — re-run '/product-workflows:brd-ground <BRD-KEY>' without --no-code.`
3. **`$SPECS_PATH` (required).** If unset, stop naming `SPECS_PATH`, per the
   `Required path environment variable unset` rule in `workflows-core:escalation-rules`:
   ```
   choices: ["Set SPECS_PATH (enter the path)", "Cancel"]
   ```
4. **Specs-repo preflight.** Invoke `Skill(skill: "workflows-core:reference", args: "specs-repo-git specs-preflight")` and execute its `specs-preflight` entry point (§3) inline, **before** the gate below — `require-on-main`
   performs no fetch of its own (`workflows-core:phase-handoff` §3.2) and relies on this step's best-effort
   one, the same ordering `/design` Phase 0 uses and for the same reason. Prompt-free and silent
   when the specs repo is clean and on its default branch. If it returns `specs_git: blocked`
   (§3.3 G0), carry that flag for the whole run.
5. **Resolve the BRD folder.** `resolve-address <BRD-KEY>` (`Skill(skill: "workflows-core:reference", args: "addressing resolve-address")`, §3), which searches
   `specifications/` and the levels below it that `resolve-address` searches (three, per `workflows-core:addressing` §3) — either level a `<BRD-KEY>` can name — a BRD folder directly under `specifications/`, or the `PRD-` folder of a slice inside it.
   Absent → stop, without asserting which command would create it: no folder exists, so no
   `brd-link.md` exists either, and nothing on disk says whether this key names a BRD with a source
   document or a slice of one. Naming `/brd-intake` unconditionally would be the wrong advice for
   half the cases, exactly as it is in step 6's `absent` branch below:
   `BRD_GROUND_NOT_FOUND: no BRD folder found for <BRD-KEY> under $SPECS_PATH/specifications/ (both levels searched) — check the key. A BRD with a source document of its own is created by /product-workflows:brd-intake <BRD-KEY> @<brd-file>; a slice is created by /product-workflows:brd-split on its parent. Do not run /brd-intake on a slice; it has no source document of its own.`
5a. **The root refusal — grounding happens at the slice and nowhere else.** Take this the moment
    step 5 returns a resolved folder, before step 6 opens anything and before step 2's deferred
    `--no-code` check — the level question is answered before any flag-combination question,
    because a root is refused whatever flags it carries. Test the **resolved directory's
    prefix**: `BRD-` is a root, `PRD-` is a slice — the kind-prefix convention
    `workflows-core:addressing` §2 fixes, read off the resolved folder's own name. **Never test the
    folder's asserted `kind:`** — `/brd-split` writes `kind: brd` into the `brd-link.md` it places
    inside the `PRD-` slice folder it carves (`commands/brd-split.md` Phase 3), so a slice
    **asserts** `brd` while being exactly the folder this refusal must accept; a gate on the
    asserted kind would refuse every slice and accept nothing.

    **Where the folder resolved through `workflows-core:addressing` §5's legacy unprefixed
    fallback, there is no prefix to test.** Answer the root question by **positive evidence, never
    by the absence of a file** — `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5.1,
    the shared authority every consumer of this test takes it from, and not restated here.

    On a root, look for the root-level artifacts this run would have produced under the retired
    two-level model — `grounding/code-grounding.md`, `grounding/design-grounding.md`,
    `grounding/baselines.md` — and name whichever exist in the stop, so an operator whose BRD was
    ground under that model is told the level moved rather than that their key is wrong. Never
    delete them; they record work done, and nothing in this run reads them.

    Stop:
    `BRD_GROUND_ROOT_LEVEL: <BRD-KEY> is a root BRD, and grounding happens at the slice. Carve one with '/product-workflows:brd-split <BRD-KEY> "<how to cut it>"', then run '/product-workflows:brd-ground <SLICE-KEY>'.<where root-level grounding exists, append:> This BRD carries root-level grounding at <paths> from the earlier two-level model; it is left in place and nothing reads it.`
6. **Gate this BRD's own inventory and ledger on main.** Execute `require-on-main` (`Skill(skill: "workflows-core:reference", args: "phase-handoff require-on-main")`, §3) against the resolved BRD folder's `coverage-ledger.md`. Whichever
   command wrote that ledger wrote the inventory beside it in the same handoff commit
   (`coverage-ledger-format.md` §3's creator table). **That is a fact about the run that wrote them
   and not about the tree, so execute `require-on-main` against `brd/brd-inventory.md` as well
   rather than inferring it** (`workflows-core:phase-handoff` §4.0 — never infer an artifact's
   merged-ness from a sibling's gate). Step 8 stops on that inventory being empty and builds this
   run's whole claim list from it, so the stop and the claim list both depend on reading the one that
   is actually shared; a hand-committed set can land partially, which `/brd-reconcile`'s §3.4 row
   states outright. Map its return exactly as the ledger's below, **except
   for row F, which needs its own two-branch stop and must not borrow step 8's.** Step 8's
   `BRD_GROUND_EMPTY_INVENTORY` reports a *content* fact — the inventory holds no `[BR#n]` row — and
   its remedy re-runs `/brd-split <PARENT-KEY>` to resolve the standing empty child. Row F reports a
   *merge* fact, and sending that operator to `/brd-split` on the parent risks the same no-op the
   next split below refuses to name unconditionally — a fully-allocated parent stages nothing on a **bare** re-run.
   Split it on the same test the
   ledger's own row F uses — is the file in the folder at all:
   - **No `brd/brd-inventory.md` in the folder** — never produced. Read the resolved folder's
     `brd-link.md` and branch on its `parent:` field: 5a's own legacy-fallback test lets a folder
     carrying **neither** `coverage-ledger.md` **nor** `brd/brd-inventory.md` through unrefused
     (`coverage-ledger-format.md` §5.1), so a folder reaching this branch is not always the slice
     step 5a would otherwise guarantee — it may be a legacy root BRD whose intake was interrupted
     after `brd/source/` was copied and before Phase 3/5 ever wrote the inventory and ledger.
     - **No `brd-link.md`, or one with no `parent:`** — this reads as an interrupted intake, not a
       slice with a `<PARENT-KEY>` to read. Stop:
       `BRD_GROUND_NO_INVENTORY: <BRD-KEY> has no brd/brd-inventory.md and no brd-link.md naming a parent — this reads as an interrupted intake, not a slice. Re-run '/product-workflows:brd-intake <BRD-KEY> @<brd-file>' to complete it (an existing BRD folder is a re-run, not a refusal).`
     - **`parent: <PARENT-KEY>` present** — this is a slice. Stop:
       `BRD_GROUND_NO_INVENTORY: <BRD-KEY> has no brd/brd-inventory.md, so there is no claim list to ground. Run '/product-workflows:brd-split <PARENT-KEY> "<how to cut it>"', which writes the slice's inventory from the rows the parent delegated to it.`
   - **The inventory is in the folder and on no ref** — produced, handoff declined. Land what is
     already on disk, and **do not name `/brd-intake`**: re-running it rewrites the inventory and the
     ledger dispositions recorded against it go with it:
     `BRD_GROUND_INVENTORY_NOT_HANDED_OFF: <BRD-KEY>'s brd/brd-inventory.md is written at <path> but is on no branch — its handoff was declined. Commit and merge it to the specs repo's default branch and re-run; do not re-run /product-workflows:brd-intake, which would rewrite the inventory and orphan the coverage-ledger dispositions already recorded against it.` What the single-commit fact still buys is the *rest* of the set: it was
   `/brd-split` running on the parent, and there is no defect log to land — a slice reads the parent's
   (`brd-format.md` §2.1). Map the §3.7 return by `stopped` first: any stopping row → stop, naming
   the concrete branch/PR state it reports; `pass` → proceed; `pass_amending` → proceed, printing
   the §3.3 row-B message; `unmanaged` → proceed as before this feature.

   **`absent` (row F) — nothing for this BRD is on any ref — is split twice before it is reported.**
   Row F conflates two states: *never produced* and *produced, handoff declined*. Reported as one,
   the message tells an operator whose files are already written to go and produce them — and on a
   slice it names `/brd-split`, which in that state is a no-op that stages nothing and can never land
   those files at all. Split row F **first on whether `coverage-ledger.md` exists in the worktree**,
   then by level — reading the resolved folder's `brd-link.md` from the worktree (it is there whether
   or not anything reached main) and branching on its `parent:` field, because a slice must never be
   told to run a command that would refuse it.

   **(a) No `coverage-ledger.md` in the folder — it was never produced.** Read `brd-link.md`, if
   present, and branch on its `parent:` field: 5a's own legacy-fallback test lets a folder carrying
   **neither** `coverage-ledger.md` **nor** `brd/brd-inventory.md` through unrefused
   (`coverage-ledger-format.md` §5.1), so a folder reaching this branch is not always the slice
   step 5a would otherwise guarantee — it may be a legacy root BRD whose intake was interrupted
   after `brd/source/` was copied and before Phase 3/5 ever wrote the inventory and ledger.
   - **No `brd-link.md`, or one with no `parent:`** — this reads as an interrupted intake. Stop:
     `BRD_GROUND_NEEDS_INTAKE: no intake artifacts on main for <BRD-KEY>, and none in the folder either — run /product-workflows:brd-intake <BRD-KEY> @<brd-file> for it and merge the pull request first.`
   - **`parent: <PARENT-KEY>` present** — this is a slice, and `/brd-intake` is not the fix: a
     slice has no document of its own to intake (`brd-format.md` §2.1), and the command that writes
     a slice's ledger and inventory is `/brd-split` on the parent
     (`coverage-ledger-format.md` §3). Stop:
     `BRD_GROUND_NEEDS_SPLIT: <BRD-KEY> is a slice of <PARENT-KEY> and its inventory and ledger exist on no ref and in no folder — where <PARENT-KEY>'s ledger still holds unallocated rows, run /product-workflows:brd-split <PARENT-KEY> "<how to cut it>" and merge the pull request first. Where the parent is already fully allocated and this slice claims rows, that run carves nothing — with no row left unallocated there is nothing for the instruction to group — and where that parent holds no re-cuttable row it is a no-op that stages nothing: the slice's files were lost after they were written, and no command re-creates the rows they held — restore them from the ref that carried them, or report it. Do not run /brd-intake on a slice; it has no source document of its own.`

     **The condition qualifies the remedy, and both branches must carry it.** The sibling rule thirty lines below already says not to name `/brd-split` for a fully-allocated parent, because re-running it **bare** there stages nothing and opens no pull request. Naming it unconditionally here sent the operator to a command that would report success and change nothing, leaving the slice ungroundable with no other route offered — and `coverage-ledger-format.md` rules on this same shape elsewhere with *"name no option at all"* rather than a remedy that cannot work.

   **(b) `coverage-ledger.md` is in the folder, and on no ref — it was produced and its handoff was
   declined.** The files exist; what is missing is a commit. **Say so, and name landing them as the
   action** — one stop code, because the remedy does not differ. **It speaks for the ledger only**: the inventory has its own gate above, with its own two stops, and this message must not report a merge state it did not test:
   `BRD_GROUND_NOT_HANDED_OFF: <BRD-KEY>'s coverage-ledger.md is written at <BRD-dir> but is on no branch — their handoff was declined, so nothing is missing but the commit. Commit brd/brd-inventory.md and coverage-ledger.md to the specs repo's default branch, then re-run '/product-workflows:brd-ground <BRD-KEY>'. <the clause below>`

   **`/brd-split` is not a way out here, so do not name it.** Re-running it **bare** on a parent whose ledger is fully
     allocated and whose children are non-empty is a no-op by its own Phase 0
     (`coverage-ledger-format.md` §4): it stages nothing, reports `nothing to commit` and opens no
     pull request. `handoff-to-main` stages only the paths *that* run declared, so the slice's
     already-written files are OTHER to it
     (`workflows-core:phase-handoff` §2.3) and can never reach main by that
     route.

     **Every part of that condition matters, so the clause carries all of it.** A parent re-run is a
     no-op only where its ledger is fully allocated **and** no child is left standing while claiming
     nothing **and** no row is re-cuttable under an instruction the run was given
     (`commands/brd-split.md` Phase 0 step 10); a standing empty child keeps that run alive through its empty-child phase, which does
     stage a `brd-link.md` it writes a `reason:` into, and a re-cuttable row keeps it alive through its
     walk, which stages the receiving child's three files. Read the `claims:` list of the `brd-link.md`
     step 6 already opened for its `parent:` and branch on it, because the two states take different
     clauses and asserting the first over the second would tell an operator a live run does nothing:
     - **This slice claims at least one `[BR#n]`** — the ordinary case, and the bare parent re-run is a
       genuine no-op: `Re-running the bare /product-workflows:brd-split <PARENT-KEY> will not land them — with this slice claiming rows and the parent's ledger fully allocated, that run is a no-op: it stages nothing and opens no pull request. An instruction typed after the key can still make it a live run, where the parent holds a row a child has recorded it will not build; that run stages what its own walk moved, never these files as they stand.`
     - **This slice claims nothing** — it is a standing empty child, so the parent re-run is not a
       no-op, but a bare one still will not land *these* files: it declares that child's `brd-link.md`, not
       its inventory and ledger. An **instructed** run that re-cuts a row onto this slice is the one form that
       does declare all three, and it lands them as its own walk leaves them rather than as they stand here.
       Say all of it, so the operator is neither sent to a no-op, nor told a
       live run is one, nor left believing no form of that run reaches these files: `Re-running /product-workflows:brd-split <PARENT-KEY> is not a no-op — this slice claims nothing, so that run resolves it. The bare form offers to remove it or to keep it against a recorded reason, and it will not land these files: it stages that decision, not this slice's inventory and ledger. Adding an instruction, '/product-workflows:brd-split <PARENT-KEY> "<what to peel off>"', can instead re-cut onto this slice a row a sibling has recorded it will not build — where such a row exists and this slice has never been interviewed — and that run does stage this slice's inventory and ledger, with the re-cut row added to them. Committing what is already on disk remains the direct route to landing them as they stand.`

   This is the same split `/product-workflows:brd-reconcile` makes on its own row F
   (`BRD_RECONCILE_NEEDS_PACKAGE` versus `BRD_RECONCILE_PACKAGE_NOT_HANDED_OFF`), for the same
   reason: *never produced* and *produced but never handed off* are different facts, and a stop that
   collapses them names a command that does nothing in the state it is reporting.
7. **Require `$REPOS_PATH`.** Resolve `${REPOS_PATH:-/workspace}` (`docs/reference/environment.md`)
   as one directory or a colon-separated list. If no entry resolves to an existing directory,
   stop naming `REPOS_PATH`, per the `Required path environment variable unset` rule in
   `workflows-core:escalation-rules` — grounding has nothing to check a claim
   against without at least one mounted repository:
   ```
   choices: ["Set REPOS_PATH (enter the path)", "Cancel"]
   ```
8. **Read the claim list, and stop if there is none.** From the gated
   `<BRD-dir>/brd/brd-inventory.md`, extract every `[BR#n]` row's `id` and `text`
   (`brd-format.md` §2 field shape) — this is the `claims` array every dispatch in Phase 5 draws
   from.

   **Zero rows is a stop, not a quiet completion.** With no claim there is nothing to ground, so
   this run writes no finding; writing no finding means there is nothing to hand off; and
   `/brd-split` and `/brd-interview` both gate on exactly that handoff. Reporting "nothing to
   ground" and ending successfully therefore leaves a BRD whose next two commands refuse it and name
   **this** command as the fix — sending the operator back here to be told "nothing to ground"
   again, with the one thing that would change the state named nowhere. The fix for a claimless
   slice is upstream — its inventory is written by `/brd-split` on the parent, and `/brd-intake` is
   never the fix: a slice has no document of its own to intake (`brd-format.md` §2.1). Read
   `<PARENT-KEY>` from the resolved folder's `brd-link.md` `parent:` field. A slice reaches this
   state only as the empty child `/brd-split`'s empty-child check offered to keep with a recorded
   reason:
     `BRD_GROUND_EMPTY_INVENTORY: <BRD-KEY> is a slice of <PARENT-KEY> and its inventory holds no [BR#n] row — it claims nothing, so there is nothing to ground. Do not run /product-workflows:brd-intake on a slice; it has no source document of its own. Re-run /product-workflows:brd-split on <PARENT-KEY>: either way it resolves every standing empty child, so it will offer to remove this slice or to keep it against its recorded reason. Which form to type depends on that parent's own ledger. Where it still holds an unallocated row, the run walks it too and will offer covered-by against this slice — and a run with rows still to place needs a slicing instruction to group them, so type '/product-workflows:brd-split <PARENT-KEY> "<how to cut it>"'. Where no row is left unallocated, the bare '/product-workflows:brd-split <PARENT-KEY>' is the run, and removing this slice or keeping it against a recorded reason is the whole of what it offers here. Adding an instruction to that same run, '/product-workflows:brd-split <PARENT-KEY> "<what to peel off>"', can additionally re-cut onto this slice a row the parent delegated to a sibling that has since recorded it will not build it — the one case in which /brd-split re-allocates a row already carrying a fate, and the only third thing that can change this slice's state. That third one is not guaranteed to be on offer: it needs such a row to exist, and it needs this slice never to have been interviewed, so a slice emptied after its own interview can only be removed or kept.`

   **Why a stop rather than an empty handoff.** Writing an empty `grounding/code-grounding.md` and
   handing it off would let both downstream gates pass, but it would assert that grounding ran over
   this BRD when nothing was ever checked, and it would carry `/brd-interview` into generating a
   round's questions for a BRD with no requirement — leaving an empty round record permanently on
   file, which no later run may delete or renumber. A stop that names the upstream fix leaves the
   tree honest and the operator able to act.
9. **Read `brd-link.md`, if present**, and carry **both** of its fields for the rest of the run:
   - `depends-on:` — any prerequisite already recorded by an earlier run. Phase 4 merges this run's
     `--depends-on` into it additively, never replacing it.
   - `parent:` — always present: by this step, step 6's gates have already guaranteed
     `coverage-ledger.md` and `brd/brd-inventory.md` are both on main — positive evidence 5a's
     legacy-fallback test would have refused had this BRD been a root — and `/brd-split` always
     writes `parent:` into a genuine slice. Carried forward for the messages elsewhere in this run
     that name `<PARENT-KEY>` (steps 6 and 8's stops, when reached).

---

## Phase 1 — Resolve repositories

BRDs carry no PR links to auto-derive a repo list from (unlike `/epics`), so this phase is always
the manual path:

0. **Resolve documentation grounding, once, before prompting.** Run
   `resolve-docs-grounding brd-ground` per `Skill(skill: "workflows-core:reference", args: "docs-grounding resolve-docs-grounding")` and
   surface the `docs grounding:` line it returns — `ON <root> (retrieval: …)` or `OFF (<reason>)` —
   **verbatim**, including any index-build, staleness, or shadowing clause it carries (off switch:
   --no-docs), alongside the repo prompt below. **Under `--no-code` this command overrides the
   returned value to `OFF`** and surfaces that, rather than the procedure's own line: a divergence has
   nowhere to be written, because Phase 8 appends the `## Documentation divergences` section into
   `grounding/code-grounding.md` and this mode holds that file read-only. Say it as an override —
   `docs grounding: OFF (--no-code: divergences are written into code-grounding.md, which this run
   does not write)` — and not as something `resolve-docs-grounding` decided. That procedure's
   *Flags first* rung knows `--no-docs` and `--docs` only, is shared by nine commands of which one
   has `--no-code`, and executed as written on this run it returns `ON`. Teaching it a flag that
   exists in a single caller would put that caller's vocabulary in everybody's procedure. It runs **exactly once per run**, here; Phase 4.5
   consumes the cached result and never re-resolves. Resolving at the phase that prompts is what
   puts the only consent-bearing step (an index build, or a refresh that breached its cap) in front
   of the operator at the moment they are already answering a question, rather than mid-fan-out.
   The `/epics` consent-ordering exception — resolving *ahead* of a `require-on-main` gate
   (`commands/epics.md` Phase 2) — is deliberately not taken here: this command's gate is Phase 0's
   route-sequencing gate, which must stay first so a BRD whose inventory never merged is refused
   before anything else happens at all, and an index build is a durable, run-independent artifact
   that a later stop does not waste.
1. Prompt for the repos in scope for this BRD's claims — a free-text list of short names, one per
   line or space-separated.
2. **Build a slug→clone map**, exactly as `/epics` Phase 4 does: for each top-level directory
   under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin
   2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as that clone's
   slug. Skip directories with no `.git` or whose `git remote` call fails/times out. **Never
   assume a `<base>/<slug>` directory name** — resolution is always by remote slug.
3. Resolve each named repo against the map: one match → use it; multiple matches → auto-prefer
   basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last (show candidates before
   proceeding); zero matches → escalate per the `Repo unresolved (zero matches) — /brd-ground` rule
   in `Skill(skill: "workflows-core:reference", args: "escalation-rules")`:
   ```
   choices: ["Skip and continue without this repo", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo"]
   ```
4. Empty final list (every repo skipped or missing) → escalate per the `No repos derivable — /epics`
   rule in `workflows-core:escalation-rules`, whose `/brd-ground` variant
   this is:
   ```
   choices: ["List repos to check manually", "Cancel"]
   ```

Read-only throughout (`workflows-core:read-only-repos`) — this command never
switches a branch, fetches, or pulls any repository it resolves here; Phase 3 reads whatever
`HEAD` already is.

---

## Phase 2 — Classify + model routing

Invoke the `model-routing` skill (Skill tool, `skill: "workflows-core:model-routing"`), then record:

```yaml
model_routing:
  classification: MODERATE        # floors at SIGNIFICANT when Phase 1 resolved >1 repository —
                                   # the multi-source rule in model-routing/classification.md §1.1
  reason: <one-line>
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # docs-grounder (Phase 4.5), code-grounder, design-grounder (Phase 5)
  review_model:    <§2 Opus chain>     # grounding-verifier (frontmatter-pinned; recorded, no override)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

`grounding-verifier` keeps its frontmatter Opus pin regardless of classification, the same way
`design-reviewer`/`epic-reviewer` do elsewhere — the floor at `SIGNIFICANT` records that a
multi-repository run carries more cross-cutting risk; it does not change which model verification
runs on. If no Opus resolves, degrade to best-available and record it in `notes` and the final
report — never hard-block.

---

## Phase 3 — Baseline integrity gate

Invoke `Skill(skill: "workflows-core:reference", args: "grounding-format")` and run its
`baseline-integrity` procedure (§4) **once per resolved repository, before any finding is
written**:

```bash
git -C "<repo>" rev-parse HEAD
git -C "<repo>" diff --ignore-cr-at-eol --stat
git -C "<repo>" status --porcelain
```

1. Record `rev-parse HEAD` as the repo's pinned commit.
2. `diff --ignore-cr-at-eol --stat` must be empty. Any output → **non-empty content diff, stop**:
   `BRD_GROUND_DIRTY_TREE: <repo> has content changes at <sha> — grounding it would cite an unidentifiable snapshot. Settle that repository's working tree and re-run '/product-workflows:brd-ground <BRD-KEY>': commit the changes, stash them, or check out a clean copy — the plugin will not do it for you, because these are your files in a code repository this route never writes to. If the changes are what you want grounded, commit them first and re-run with --rebaseline so the new commit becomes the recorded pin.`

   **Under `--no-code`, drop the final sentence and name the re-run without the flag instead** — `--rebaseline` is refused in that mode (Phase 0 step 2), so a message ending in it sends the operator into a second stop: `… commit them first and re-run '/product-workflows:brd-ground <BRD-KEY> --rebaseline' without --no-code, so the new commit becomes the recorded pin.`

   **Every other stop on this route names a command or an action, and this one must too.** The
   remedy is the operator's, not the plugin's — `/brd-ground` mounts code repositories read-only and
   commits to none of them — but "settle the tree, three ways, then re-run this command" is still an
   action a reader can take, and naming which repository and which commit is what makes it one. Both
   named re-runs resolve in the state being reported: the BRD folder and its ledger are already
   gated on main by Phase 0, so nothing about this stop invalidates the command it offers.
3. For every entry `status --porcelain` reports, compare its working-tree line count against
   `git show <sha>:<path> | wc -l` when the path exists at the pinned commit (an untracked path
   that exists nowhere at the pin has nothing to compare against and is not itself a dirty-pin
   signal). A line-count mismatch is a non-empty content diff — stop with the same message above,
   naming the porcelain-flagged path.

**This gate is the orchestrator's, never delegated.** `code-grounder` and `grounding-verifier`
each re-verify `HEAD` against the commit *they* are handed (their own step 1/2), but that check
alone would let a repository whose working tree is dirty *around* an otherwise-matching `HEAD*`
pass silently — the content-diff and line-count checks above are what this phase adds, and they
run before Phase 5's first dispatch, not inside it.

**`--rebaseline`, and a plain re-run against moved code.** If `<BRD-dir>/grounding/baselines.md`
already records a pin for a repository:
- **Its `HEAD` still matches the recorded pin** → nothing moved; this is a harmless re-run. Skip
  re-grounding claims this repository already answered (Phase 5) unless a new `--depends-on` was
  added this run (Phase 6 still reassesses horizons against it).
- **Its `HEAD` has moved, and `--rebaseline` was NOT given** → stop:
  `BRD_GROUND_NEEDS_REBASELINE: <repo> moved since the last grounding pin (<old-sha> -> <new-sha>) — re-run with --rebaseline to supersede the affected findings by ID.`
- **Its `HEAD` has moved, and `--rebaseline` WAS given** → proceed; Phase 5 re-grounds every claim
  against the new pin, and Phase 8 supersedes the old findings by ID rather than renumbering them
  (grounding-format.md §3, `SUPERSEDED`) — a citation into an already-sent package still resolves.

**Record the outcome as a `[CG#n]` finding** (`workflows-core:grounding-format` §4: "the outcome is recorded
as a `[CG#n]` finding" — a verified fact about a code repository at a commit is exactly what that
prefix denotes, and inventing a separate prefix for it would only fragment the namespace). One per
repository that passes this gate, assigned first, in repo-resolution order, **before** Phase 5's
claim-level findings — `CG#1..CG#R` on a first run for `R` resolved repositories, continuing after
whatever the highest `CG#n` already on file is on a `--rebaseline` run. Each carries every field
`workflows-core:grounding-format` §2 defines: `claim` — "baseline integrity: `<repo>` is pinned at a verified,
unmodified commit"; `verdict: CONFIRMED` (a repository that failed this gate never reaches a
finding — it stopped the run instead); `evidence` — the three command outputs (the pinned SHA, the
empty `--stat` diff, and the `--porcelain`/line-count result); `commit` — the same pinned SHA;
`altitude: implementation`; `horizon: current`; `consumed_by: none` — which on a baseline finding is
permanent and reports no gap, per `workflows-core:grounding-format` §4.1: there is nothing for a PRD, an ARD or a
specification to draw from an assertion that a commit is identifiable, so every downstream
unconsumed-item report excludes these findings rather than carrying one open item per repository
forever. Phase 5 continues the BRD-wide
`[CG#n]` sequence from these, never restarting at `CG#1` once a baseline finding already claimed
it. Phase 7 verifies these findings the same as any other — `grounding-verifier`'s own Process
step 1 already re-runs `baseline-integrity` for whatever finding it is handed, so re-checking a
baseline finding is exactly that re-run.

**Under `--no-code` this gate still runs in full** — every check, every stop — and writes nothing.
No baseline `[CG#n]` is assigned and no entry is appended to `grounding/baselines.md`: both would be
this invocation producing a `[CG#n]`, which the mode forbids. The pins it verifies are still
load-bearing, which is why the gate is not skipped along with the writes — a class-4 `[DG#n]` is
pinned to the commit of the `[CG#n]` it cites, and Phase 7 re-derives it against that repository at
that commit. A repository whose `HEAD` has moved stops here exactly as it always does, but the
remedy the message names changes: `--rebaseline` is unavailable under this mode, so name the re-run
**without** `--no-code`. Adding design grounding on top of a code grounding that no longer describes
the tree would pin new findings to a commit the repository has left.

Append (never overwrite) one dated entry per repository to `<BRD-dir>/grounding/baselines.md` — **except under `--no-code`, which writes no baseline entry at all** (stated in full above; repeated here because this is the instruction it excepts, and a reader who arrives at an unconditional imperative does not go looking for its exception):
the repo, the pinned commit, the verification result, and the `[CG#n]` id assigned above — the same
three commands are what the customer's own reviewer re-runs later against their own checkout.

---

## Phase 4 — Prerequisites

Persist any Phase 0 `--depends-on` keys into `<BRD-dir>/brd-link.md` under a `depends-on:` list —
**additive only**: merge into whatever the file already carries (including a `parent:` or
`claims:` field another command wrote), never drop an existing prerequisite, and never touch any
field but `depends-on:`. The file may also be edited by hand between runs; this phase reads it
fresh, adds, and writes back.

For every declared prerequisite (this run's plus any already on file):

1. `resolve-address <PREREQ-KEY>`. Absent → report `<PREREQ-KEY> — BRD not found`.
2. Found → look for `decisions.md` in its folder. Absent → report
   `<PREREQ-KEY> — no decisions.md yet; contributes no will-change horizons` (per
   `workflows-core:grounding-format` §5: a prerequisite whose decisions are not yet frozen contributes none).
3. Present → read only the decisions that are **frozen, which is a field test and not a judgement:
   `status: decided`**, the second of the five statuses
   `${CLAUDE_PLUGIN_ROOT}/references/decision-register-format.md` §3 fixes. Nothing else counts, and
   each exclusion is that section's own rule rather than this command's caution: `open` and
   `reopened` "may not be consumed downstream" while they stand; `superseded` and `withdrawn` are
   terminal and describe a position that is no longer held; and an `[AS#n]` never reaches `decided`
   at all (§7), so an assumption is never a frozen decision however confidently it is written.
   **Read the status, do not infer it from how settled a record sounds** — the register carries the
   answer in a field precisely so that this reader does not have to weigh prose, and
   `/product-workflows:brd-reconcile` uses the same equivalence when it says what freezing a `[CD#n]`
   means. A `decisions.md` this reader genuinely cannot parse into records with statuses — not one
   whose records simply carry no `decided` — is treated as "none frozen" and **reported as
   unparseable rather than as empty**, because the two are different facts and only the first is
   worth someone's attention. Two outcomes:
   - **No record carries `status: decided`** → report
     `<PREREQ-KEY> — decisions.md present, none frozen yet; contributes no will-change horizons`
     — the same "contributes none" consequence as the absent-file case above, just reached from a
     different cause.
   - **At least one record carries `status: decided`** → report readiness in this exact form — the
     `prerequisites:` block, one aligned line per prerequisite, which the Final report below
     reproduces verbatim:
     ```
     prerequisites: EPIC-008-01 — decisions frozen, customer-reviewed 2026-08-27, not yet built
                    EPIC-002    — decisions frozen, NOT customer-reviewed
     ```
     "customer-reviewed `<date>`" comes from the newest `customer-review-<date>.md` in the
     prerequisite's folder, if any, else "NOT customer-reviewed"; "not yet built" is this
     prerequisite's default state — grounding is what tells the operator when a decision is about
     to move the ground it is standing on, so it is stated even when obvious.

No declared prerequisites at all → `prerequisites: none declared`. Hold this block for the final
report; Phase 6 also uses it to decide which findings get `horizon: will-change`.

---

## Phase 4.5 — Documentation leads (optional)

Consume the `resolve-docs-grounding brd-ground` result cached in Phase 1 step 0 — never re-run it.
`docs_grounding: OFF` → skip silently, reporting the `OFF` line once. `docs_grounding: ON` →
`dispatch-docs-grounder` (`workflows-core:docs-grounding`) with
`feature_summary` = two to four sentences built from the Phase 0 step 8 claim list (what this BRD
asserts and asks for, in product terms), `key` = `<BRD-KEY>`, and `themes` = the capability
themes those claims cluster into.

### A document is never evidence for a `[CG#n]`. Never.

**No `[CG#n]` or `[DG#n]` may cite a documentation page in its `evidence`, under any verdict, in
any phase of this run.** Not as a supporting line, not as a corroborating second source, not as the
thing that turns a `NOT-PROVABLE` into a `CONFIRMED`. Grounding answers one question — *is this
claim true of this specific commit?* (`workflows-core:grounding-format` §1) —
and a document cannot answer it, because **a document is a claim about behaviour, not the
behaviour**. It was written by a person, at a date, about a version, and nothing keeps it in step
with the code. Cite one and a confident, stale page satisfies a claim the code does not: precisely
the failure `NOT-PROVABLE` exists to make sayable. If the code will not settle a claim, the answer
is `NOT-PROVABLE`, and a page that seems to settle it changes nothing about that.

This is why the digest is **not** passed into `code-grounder`, `design-grounder`, or
`grounding-verifier` — none of their input contracts carries a documentation field, and none is to
be given one. The digest is consumed by this orchestrator alone, in exactly two ways:

1. **As a lead — where to look.** A `docs_references` page naming a subsystem, service, or module
   that **no repository resolved in Phase 1 covers** is surfaced now, before Phase 5 dispatches
   anything, with one choice: add that repository and re-resolve it through Phase 1 step 2–3 (then
   pin it through Phase 3 like any other), or proceed on the record and let the affected claims
   land as `NOT-PROVABLE`. A lead is a question about coverage, never an answer about behaviour.
2. **As a divergence — recorded in Phase 8, after verification, never before.** See below.

### A doc-versus-code divergence gets no identifier of its own

**It is recorded without one, and names the `[CG#n]` it diverges from instead.** Two reasons, and
neither is stylistic:

- **`[CG#n]`/`[DG#n]` cannot carry it.** Those prefixes denote a *finding* — an answer to a `[BR#n]`
  premise checked against a pinned commit or a frame set (`workflows-core:grounding-format` §1, §2). A
  divergence is not an answer to a `[BR#n]`; it is an observation about two artifacts, neither of
  which is the requirement. Minting a `[CG#n]` for it would also make it citable and
  `consumed_by`-able — the exact outcome the rule above forbids.
- **A new prefix would be worse, not better.** Every `[CG#n]`/`[DG#n]` must carry a verifier
  outcome or it is not evidence and blocks `/brd-split` (`workflows-core:grounding-format` §8). A divergence
  cannot earn one: `grounding-verifier` re-derives from a pinned repository or from a frame set,
  and a documentation page is neither, so a new prefix would either need a verification pass this
  workflow does not have or would sit permanently unverified in the namespace. The existing
  namespace carries the divergence perfectly well **by reference** — the identifier in the entry is
  the finding's, never the divergence's.

Because an entry must name a `[CG#n]`, a divergence can never stand on the page alone, and can
never be written before Phase 7 has verified that finding. That ordering is the safeguard, not a
formality.

---

## Phase 5 — Fan out grounding

**Under `--no-code`, skip this phase's `code-grounder` fan-out and its renumbering entirely**, and
read the `[CG#n]` set from `<BRD-dir>/grounding/code-grounding.md` instead — every finding on file,
with the `id`, `claim`, `verdict`, `evidence` and `commit` Phase 8 wrote there. Those findings are
this run's **input, never its output**: not renumbered here, not re-verified in Phase 7, not
rewritten in Phase 8. The `[DG#n]` sequence still continues from the highest already on file, the
same as on any other re-run.

**`code-grounder`, one per repository, ≤4 concurrent per Agent message** (wait for a batch before
starting the next). Each dispatch gets the *whole* claim list (Phase 0 step 8) and its own pinned
commit (Phase 3) — a BRD carries no per-repo claim tagging, and a claim that genuinely belongs to a
different system is exactly what `NOT-PROVABLE` exists to say, not a reason to pre-filter:

→ Agent (subagent_type: "product-workflows:code-grounder", model: `<detection_model>`):
  > "repo_path: [resolved absolute path from Phase 1]
  > commit:    [Phase 3 pinned commit for this repo]
  > claims:
  >   - id:   [BR#n]
  >     text: [requirement text]
  >   [… every claim from Phase 0 step 8]
  > refresh:
  >   pull: false"

Handle `status`: `OK` → collect `findings`, **and collect `notes`** — a claim that touched a false-friend name, a claim whose search budget was exhausted. Report them with the findings: without them a `NOT-PROVABLE` `[CG#n]` whose search ran out is indistinguishable from one the code genuinely refutes, and only the first is worth another pass. `INPUT_MISSING` / `REPO_MISSING` → should not occur
(Phases 0/1/3 already checked); if it does, stop and name the gap. `COMMIT_MISMATCH` → the tree
moved between Phase 3 and this dispatch — stop and re-run from Phase 3 **with `--rebaseline`**, for
the reason Phase 7's `BRD_GROUND_VERIFY_COMMIT_MISMATCH` row states: this run already recorded a
pin, so a plain re-run stops with `BRD_GROUND_NEEDS_REBASELINE`.

**Renumber into one BRD-wide sequence.** Each `code-grounder` instance numbers its own output from
`CG#1` (its own contract, per dispatch) — this is per-instance, not global. Merge every batch's
findings, in repo-resolution order, into one contiguous `[CG#n]` sequence continuing from the
highest `CG#n` already assigned this run — Phase 3's own baseline findings on a first run, or
whatever the highest `CG#n` already on file is on a `--rebaseline` run — never trusting an agent's
own numbers as the BRD's numbering.

**Then `design-grounder`, unless `--no-design`.** Look for `<BRD-dir>/design/`; each immediate
subdirectory is a candidate exported frame set. The location and the index requirement are
`workflows-core:grounding-format` §6.1's, cited here rather than restated —
`design/` is a reserved subdirectory of any folder under `specifications/`, so the same path resolves
whether this run stands on a BRD folder or on the PRD folder a slice is. None found → skip, reporting
why (`--no-design` given, or no `design/` folder exists yet for this BRD). One or more found → dispatch one instance per frame set, same ≤4
concurrent discipline, **after** the code-grounder batch above has fully returned — this agent's
fourth reconciliation class cites a `[CG#n]`, so the findings it needs must already exist. Under
`--no-code` there is no batch to wait for and that precondition is already met: the `[CG#n]` set
read from file is what `cg_findings` carries, which is the whole reason the mode can add design
grounding at all:

→ Agent (subagent_type: "product-workflows:design-grounder", model: `<detection_model>`):
  > "frame_set_dir: [absolute path to this frame set]
  > inventory:
  >   - id:   [BR#n]
  >     text: [requirement text]
  >   [… every claim from Phase 0 step 8]
  > cg_findings:
  >   [… every merged [CG#n] finding from this phase, in the shape design-grounder's Inputs declare:
  >      id, claim, verdict, evidence, commit]"

Handle `status`: `OK` → collect `findings` (may be empty — agreement produces none). `INPUT_MISSING`
/ `FRAME_SET_MISSING` → should not occur; stop and name the gap if it does. `NO_INDEX` → this
frame set cannot be reconciled without an index file; report it and skip that directory rather
than guessing at frame identity — and name the repair, `/workflows-core:frames <this run's KEY>`,
which writes the index and lets a re-run ground the set. Renumber into one BRD-wide `[DG#n]` sequence the same way as
`[CG#n]` above, continuing from the highest `DG#n` already on file.

**Record which frame set each `[DG#n]` came from** as you merge — the dispatch that produced it
names exactly one `frame_set_dir`, and Phase 7 hands that same directory back to
`grounding-verifier` so it can re-derive a design-only finding at all. Recovering the association
after the merge would mean guessing; carrying it forward costs nothing.

A `design-grounder` `notes` entry naming a class-4 gap it deferred for lack of a settling
`[CG#n]` is carried into the final report verbatim — it is a real, actionable gap, not noise.

---

## Phase 6 — Horizons

Every finding leaves Phase 5 as `horizon: current` by default (an agent grounding one claim
against one repository or frame set has no visibility into another BRD's decisions to do
otherwise). This phase is where prerequisite awareness — Phase 4's readiness block — is applied
across the whole finding set:

For each finding, and for each declared prerequisite whose decisions Phase 4 found **frozen**:
read the frozen decision text and judge whether it directly determines this finding's claim once
built — not merely mentions the same area. Where it does, set `horizon: will-change` and record
`prerequisite: <the specific decision, by id and a one-line summary>` — naming the decision itself,
never merely the prerequisite BRD (`workflows-core:grounding-format` §5). Where no declared prerequisite has any
`status: decided` record at all, every finding stays `current`, and this is reported plainly rather
than left to look like nothing was checked.

**That case is ordinary, and it is no longer the *only* case.** A prerequisite's `decisions.md` is
written by `/product-workflows:brd-interview` (its register phase) and gains its `[CD#n]` records from
`/product-workflows:brd-reconcile`, both of which ship — so a prerequisite that has been through the
route carries frozen decisions as a matter of course, and this phase does real work on it. What
makes the no-frozen-decision case still ordinary is **sequencing, not absence of the capability**:
a prerequisite is typically declared while it is in flight, which is exactly when its register holds
`open` records and no `decided` ones. Report which of the two it is — a prerequisite with nothing
frozen yet, or one this run had nothing to declare against — because "every finding stayed
`current`" reads identically in both and means different things.

A finding already carrying `horizon: will-change` from a previous `--rebaseline` pass keeps it
unless the naming decision itself has since shipped (superseded by a later finding, per §3) —
`will-change` findings are never silently reverted to `current`.

---

## Phase 7 — Verify

Dispatch `grounding-verifier` over **every** finding this run holds — Phase 3's baseline `[CG#n]`
findings, freshly-merged Phase 5 claim findings, and any pre-existing ones a `--rebaseline` pass is
re-checking — one instance per finding, same ≤4-concurrent batching discipline as Phase 5, pinned
to the Opus chain (`review_model`, frontmatter-pinned, no override):

→ Agent (subagent_type: "product-workflows:grounding-verifier", model: `<review_model>`):
  > "finding:
  >   id:       [CG#n or DG#n]
  >   claim:    [the BR#n premise as the finding recorded it]
  >   class:    [1-4 — DG#n only, omit for CG#n]
  >   verdict:  [the finding's verdict]
  >   evidence: [the finding's evidence list]
  >   commit:   [the finding's pinned commit — every CG#n and every class-4 DG#n; omit only for a
  >              class-1/2/3 DG#n, which is pinned to no commit]
  >   cites:    [class-4 DG#n only — the CG#n it cites]
  > repo_path:     [the repository this finding is pinned against — every CG#n; for a class-4
  >                 DG#n, the repository the cited CG#n is pinned against; omit for a
  >                 class-1/2/3 DG#n]
  > frame_set_dir: [every DG#n — the Phase 5 frame set this finding was reconciled against; omit
  >                 for a CG#n]
  > inventory:     [every DG#n — the Phase 0 step 8 claim list, id and text, exactly as
  >                 design-grounder was handed it; omit for a CG#n]
  > provenance: [own-run | inherited — see below]"

Supply the finding **exactly as the agent's own Inputs contract declares it** — including
`evidence` and, for a class-4 `[DG#n]`, `cites` — even though the agent's own hard rules forbid
reading either before it finishes its independent re-derivation. That sequencing discipline is the
agent's to enforce on itself (its Process step 2 is explicit about it); this orchestrator's job is
only to hand over the full, correctly-shaped record, never to withhold a field the contract lists.

**Which anchor fields go with which finding is that contract's own Inputs table, not this
command's** — read it there (`agents/grounding-verifier.md`, Inputs), never from a copy kept here
that could drift from it. Two consequences for this dispatch:

- **Always pass `class` for a `[DG#n]`.** The agent's row selection is fail-closed — a `[DG#n]`
  arriving without a readable `class` is treated as resting on code and refused for want of a
  commit — so an omitted `class` does not relax the gate, it stops the finding. Phase 5 recorded
  the class on every `[DG#n]` it merged; pass it through.
- **Always pass `frame_set_dir` for a `[DG#n]`.** Phase 5 dispatched `design-grounder` once per
  frame set, so every `[DG#n]` on file traces back to exactly one directory; carry that association
  forward from Phase 5 rather than re-deriving it here. A class-4 `[DG#n]` gets both it and the
  code pair — it is the one finding with a foot in each source.
- **Always pass `inventory` for a `[DG#n]`** — the same Phase 0 step 8 claim list Phase 5 handed
  `design-grounder`, unchanged. A `[DG#n]` is a reconciliation between the frame set and the
  inventory, so handing over only the frames gives the verifier one side of the comparison. A
  **class-1** finding cannot be re-derived at all without it: it asserts that no requirement asks
  for what the frame shows — a negative over the whole set — and its `claim` is the literal
  `none — frame-only`, so there is no `[BR#n]` in the record to stand in for the set. The verifier
  correctly returns `NOT-PROVABLE`, and the finding is then permanently unverifiable and can never
  become evidence (`workflows-core:grounding-format` §8). This dispatch omitted the field, which is
  where that dead end came from.

**Under `--no-code`, "every finding this run holds" is the new `[DG#n]` set and nothing else.**
Every `[CG#n]` on file was neither produced nor reproduced by this invocation and already carries
the outcome from the run that did produce it. Re-dispatching them would spend one Opus verification
per finding to re-decide a settled one, and a single `contradict` would rewrite a finding into a
file this mode holds read-only — which is precisely the exposure the mode exists to remove. The
`[CG#n]` a class-4 `[DG#n]` cites is still checked in passing: the verifier re-runs
`baseline-integrity` against the pin it is handed, as its own Process step 1.

**`provenance` is set per finding, by origin — never by which phase produced it, and never
blanket.** `own-run` for any finding **this invocation itself produced**, regardless of which
phase did the producing: Phase 3's baseline `[CG#n]` findings qualify exactly as Phase 5's claim
findings do, because Phase 3 re-runs `baseline-integrity` and assigns a fresh id every invocation —
first run or `--rebaseline` alike — never carrying a prior run's baseline finding forward
unreproduced. `inherited` for a finding **this invocation did not reproduce** — concretely, any re-run in which
a given repository's `HEAD` still matched its recorded pin, so Phase 3's first bullet skipped
re-grounding that repository's claims and the pre-existing findings from an earlier invocation
stand as they were, now being re-checked rather than regenerated. **That bullet fires on a plain
re-run and on a `--rebaseline` pass alike** — it is keyed on the pin still matching, not on the
flag — so a plain re-run against an unmoved repository inherits exactly as a `--rebaseline` pass
over one does. Illustrating only the flagged case would read as though the flag were what made a
finding `inherited`; the rule is the origin, and the flag never enters it. Phrasing the rule by origin rather than by
phase number is deliberate: it is immune to a future renumbering the way a phase-keyed rule is not.
The agent's own Inputs contract and `workflows-core:grounding-format` §8 both define `inherited` as "another
team's report **or an earlier run of this workflow**," and a finding surviving from before this
invocation, unreproduced, is the second of those, regardless of how confident its write-up reads —
mislabelling it `own-run` would tell the verifier to relax exactly where §5 of its own instructions
say rigor must not drop.

**Act on `status` first — an `outcome` exists only on `status: OK`.** The four statuses below are
refusals, not verdicts: the agent performed no re-derivation and returned no `outcome`, and a
finding carrying no outcome is not evidence and blocks `/brd-split` for as long as it stays on file
(`workflows-core:grounding-format` §8). So none of them may be shrugged off and none may be written:

- **`OK`** — act on `outcome`, below.
- **`COMMIT_MISMATCH`** — the repository moved between Phase 3's pin and this dispatch. Stop:
  `BRD_GROUND_VERIFY_COMMIT_MISMATCH: <finding-id> could not be verified — <repo> is at <resolved-HEAD>, not the pinned <commit>. Re-run '/product-workflows:brd-ground <BRD-KEY> --rebaseline' from a clean tree.`
  **Under `--no-code` the same message names the re-run without the mode** — `'/product-workflows:brd-ground <BRD-KEY> --rebaseline'`, no `--no-code` — since that mode refuses the flag the remedy requires, and the finding that failed here is pinned to a repository the design pass cannot re-pin on its own.
  The same repair as Phase 5's own `COMMIT_MISMATCH`: re-run from Phase 3, which re-pins and
  re-grounds. **`--rebaseline` is part of the remedy, not an optional extra**, and the message says
  so: Phase 3 already appended this repository's pin to `grounding/baselines.md` before dispatching
  anything, so the re-run finds a recorded pin its `HEAD` no longer matches and stops with
  `BRD_GROUND_NEEDS_REBASELINE` unless the flag is given. "Re-run from a clean tree" on its own
  would send the operator straight into that second stop.
- **`INPUT_MISSING`** — this orchestrator's dispatch was malformed (most often a `[DG#n]` sent
  without its `inventory`, its `class` or its `frame_set_dir` — `inventory` first, because it is the
  newest requirement and the one whose omission made a class-1 finding permanently unverifiable). Stop, quoting the field and row the agent named, and
  fire `emit-block` per Phase 11's capture-at-block invariant — a dispatch this command controls
  getting the contract wrong is a plugin gap, unlike Phase 0's environment halts.
- **`REPO_MISSING` / `FRAME_SET_MISSING` / `NO_INDEX` / `STALE_INDEX`** — the source this finding rests on is gone
  or unusable (a repository unmounted mid-run, a frame set removed or exported without an index
  since it was ground). Stop, naming the finding and the path the agent reported — and, per the
  four-part stop contract, the command that resolves it: on `NO_INDEX` that is
  `/workflows-core:frames <this run's KEY>`, then re-run this command. **On `STALE_INDEX` it is
  not** — the index is there and its descriptions are intact; the frames are gone. Re-running
  `/frames` on an empty directory writes nothing (`workflows-core:grounding-format` §6.2 step 6 forbids it), so
  naming it would send the operator to a no-op. Name the missing frames instead: restore them to the
  directory, then re-run this command — and `/frames` only if the set changed while they were away.

**Nothing reaches Phase 8 unverified.** Any stop above happens before Phase 8's first write, so a
finding without an outcome is never written into the package; whatever was on file from a previous
run stands untouched until a clean run replaces it. This is the invariant `/brd-split`'s Phase 0
gate depends on — it counts findings carrying no outcome and refuses to split while any exists, so
a run that wrote one would deadlock the route rather than merely leave a gap.

Act on `outcome`:
- **`agree`** — keep the finding as written; record the outcome alongside it.
- **`extend`** — keep the finding's verdict; append the verifier's additional evidence to the
  finding's `evidence` list; record the outcome.
- **`unprovable`** — keep the finding's verdict unchanged (the verifier's own search settling
  nothing either way is not the same as it being wrong); record the outcome and flag the finding
  in the report as verification-inconclusive.
- **`contradict`** — **the finding is rewritten, and the rewrite retains the same id.** Replace
  the finding's `verdict` and `evidence` with the verifier's `own_verdict` and `own_evidence`, and
  keep a one-line note of the pre-rewrite verdict for the audit trail. The id never changes, so
  every existing citation into it still resolves.

A finding carrying no verifier outcome is not evidence (`workflows-core:grounding-format` §8) and is never
written to the package with `consumed_by` anything but `none` — this phase is what stands between
a raw finding and one a downstream command may cite.

---

## Phase 8 — Write findings

Write `<BRD-dir>/grounding/code-grounding.md` (every `[CG#n]`) and
`<BRD-dir>/grounding/design-grounding.md` (every `[DG#n]`, or a short note when Phase 5 skipped
design grounding and why) — one block per finding, **serialised exactly as
`workflows-core:grounding-format` §2.1 fixes it**: one space after every colon, never alignment
padding, keys in the §2 table's order, and an inapplicable field omitted rather than written empty.
That section is not a style note — a writer that aligns one section's keys and not the next produces
a file whose readers report findings as missing that are on the page. Each block carries every field
`workflows-core:grounding-format` §2 defines (`id`, `claim`, `verdict`, `evidence`, `altitude`, `horizon`,
`consumed_by: none`, plus `class`/`cites` on a `[DG#n]` and `commit` on everything **except** a
`[DG#n]` of class 1, 2 or 3 — those are settled from the frame set alone and are pinned to no commit,
per §2's applicability note) plus this run's verifier `outcome` **and any `notes` the verifier returned**. Its contract calls those *"anything the caller should know before recording this outcome"*, so they are read before the outcome is written, not after — a verdict recorded without them is recorded against a caveat the verifier raised and nothing carried.
A `--rebaseline` run appends its new findings after the existing ones and marks any finding it
superseded with `verdict: SUPERSEDED`, id retained, rather than deleting or renumbering it.

**Under `--no-code` this phase writes `design-grounding.md` and nothing else.**
`code-grounding.md` is not opened for writing at all — not for findings, not for the documentation
divergences below (documentation grounding is off for the run), and not for the derivation matrix
below (resolved off, or refused outright in Phase 0 when it was asked for explicitly). Every
`[CG#n]` on file stands byte-for-byte as the run that wrote it left it. The `[DG#n]` this run
verified are appended after any already on file, continuing the sequence rather than replacing the
file's contents.

**`design-grounding.md` names every frame set on disk, covered or not.** Write a
`## Frame sets covered` section — **replacing any section of that name already in the file, never
appending a second one.** It is a census of the tree as this run left it, not a log: two sections
would leave `/brd-split`'s gate reading "the" section with no rule for which, and the older one
records a state that has since changed.

**Enumerate `<BRD-dir>/design/` here, in this phase, rather than reusing what Phase 5 saw.** Phase 5's
listing sits behind `--no-design`, so on a run carrying that flag it never happens — and a section
built from "what this run saw" would then be empty, no `skipped: --no-design` row could ever be
written, and `/brd-split` would stop a run whose flag it is supposed to honour. The census must be of
the directory, not of the run. List **every** immediate subdirectory, each against exactly one
disposition:

- `ground` — with the `[DG#n]` ids this run reconciled against that set.
- `skipped: --no-design` — the operator turned the pass off for this run.
- `skipped: no index` — Phase 5 got `NO_INDEX` for that set and could not reconcile it.

**A set this run re-ground supersedes its own prior findings, and the mode that makes that ordinary
is `--no-code`.** Where this run wrote `[DG#n]` for a frame set that already had them on file, mark
every superseded one `verdict: SUPERSEDED`, id retained, exactly as a `--rebaseline` pass does for
`[CG#n]` — never delete or renumber, so an existing citation still resolves. Without this rule a
second `--no-code` run over a changed frame set appends a whole new finding set beside the stale one,
both unmarked, and `/brd-split` sees the set recorded `ground` and passes. `--rebaseline` cannot be
the answer here: it is a code-pin concept and `--no-code` refuses it outright, so the supersession
that mode needs has to be its own rule rather than a flag.

A run with no `design/` folder, or an empty one, writes the section with an explicit "no frame sets
on disk" line rather than omitting it. **The section is what makes design coverage checkable at
all**: `/brd-split`'s design-presence gate compares the subdirectories on disk against the names
recorded here, and a relation with nothing on one side fails rather than passing
(`workflows-core:grounding-format` §2.1's reading rule). Omitting a set because it was skipped is
what would make that gate report a clean tree it never read.

**Documentation divergences (only when Phase 4.5 ran).** Append a `## Documentation divergences`
section to `<BRD-dir>/grounding/code-grounding.md` — appended there, like the derivation matrix
below, because it is not a produced artifact in its own right. One prose entry per divergence, each
carrying: the documentation page (path relative to the resolved `docs_root`), what it states, and
the **`[CG#n]` whose verified evidence it diverges from**, quoted by id. **No entry gets an
identifier of its own, and no entry may exist without naming a verified `[CG#n]`** (Phase 4.5) —
so a divergence is always the code contradicting a page, established by a finding, never a page
asserting anything about the code. A run with docs grounding ON that found no divergence writes the
section with an explicit "none found" line rather than omitting it; a run with it OFF writes no
section at all. Nothing in this section is ever copied into a finding's `evidence`, and no ledger
row's `evidence` column ever names a page.

**Derivation matrix.** Resolve whether it runs: an explicit `--derivation-matrix` /
`--no-derivation-matrix` wins outright; otherwise default it **on** when the BRD inventory reads
as reporting- or data-centric (a judgment call this command makes from the claim text — recurring
language about reports, dashboards, exports, extracts, or stored/displayed data fields) and **off**
otherwise. When on, append one implementation-altitude row per data element the inventory asks to
display or store to `<BRD-dir>/grounding/code-grounding.md`, classed per `workflows-core:grounding-format` §7
(`EXISTS | DERIVED | NEW-CAPTURE | NEW-CONFIG | PARTNER | DEFERRED | DEPENDENCY`) — appended there
rather than as a new file, since it is not in this command's produced-artifact set on its own.

---

## Phase 9 — Handoff

Invoke `Skill(skill: "workflows-core:reference", args: "phase-handoff")` and present its §4.3 choice array verbatim — the **gated** variant (§4.0), **in every mode including `--no-code`**:

```
choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]
```

**Why the same array under `--no-code`, where `code-grounding.md` is not in the set.** §4.0's rule is that a handoff spanning classes takes the strongest class in it, and both artifacts a `--no-code` run hands off are classed: `grounding/design-grounding.md` is **gated** — §3.4 carries a conditional `/brd-split` row for it, and that command executes `require-on-main` against it wherever the BRD has frame sets on disk. So the promised stop is real in both modes, and the operator who declines will meet it. This array was hardcoded here before `design-grounding.md` was classified at all, which made it right by luck on a full run (`code-grounding.md` rode in the set) and wrong on a `--no-code` one; it is now right for the stated reason in both.

On the first choice, execute `handoff-to-main` (`Skill(skill: "workflows-core:reference", args: "phase-handoff handoff-to-main")`, §2) with `prefix: brd` (shared
by every `/brd-*` command, per `brd-intake.md`'s own precedent), `feature_folder` as resolved
in Phase 0, `deliverable_paths` = every file this run wrote or updated under `<BRD-dir>`
(`grounding/baselines.md`, `grounding/code-grounding.md`, `grounding/design-grounding.md`,
`brd-link.md`) — **under `--no-code` that set is `grounding/design-grounding.md` and, where Phase 4
persisted a prerequisite, `brd-link.md`**: the other two are untouched, and naming an unchanged path
in a handoff is how a commit comes to claim work it did not do — `title: <BRD-KEY> Ground requirements against code and design`, and `body_facts` =
the finding counts by verdict, the verifier agreement/extend/contradict/unprovable tally, and the
prerequisite-readiness block; emit its §4.1 outcome line in the final report.

---

## Phase 10 — Next steps

**This run always stands on a slice** — by the time Phase 10 runs, step 6's gates have already
guaranteed `coverage-ledger.md` and `brd/brd-inventory.md` are both on main, which is positive
evidence 5a's legacy-fallback test would have refused had this BRD been a root — so there is no
level branch to take here. `/product-workflows:brd-split <BRD-KEY>` is always offered, unless the
test below withholds it.

**That offer still carries one qualifying test, and this run holds the answer to it.** `/brd-split`'s
Phase 0 step 7b stops on any `design/` subdirectory this run recorded `skipped: no index`, and on any
it could not cover. So where Phase 8's `## Frame sets covered` section carries such a row, **do not
offer `/brd-split` as Recommended** — it would refuse the key just ground. Offer the repair the stop
itself names, in the same position: `/workflows-core:frames <BRD-KEY>` to write the missing index,
then a `--no-code` re-run. The offer's wording is deliberately "its grounding is complete and
verified" rather than the older "now that every finding carries a verifier outcome": the outcome
count is one of three tests that command applies, and naming one of them as though it were the
precondition is how this offer came to promise a pass it cannot deliver.

`/product-workflows:brd-split <BRD-KEY>` allocates this slice's own ledger, and it is the last step
that has to run before this BRD's requirements all carry a recorded fate — **it is not the end
of the route**. `/product-workflows:brd-interview <BRD-KEY>` follows it, and `/brd-split`'s own Phase 7
is what offers it, so it is not offered here: putting it in this list would name a step out of
order, since it refuses a ledger that still holds an unallocated row. `/brd-split` will not start
until this phase's findings are on the specs repo's default branch — its own Phase 0 gates
`grounding/code-grounding.md` on `origin/<default>`; **which words state that wait are
`<merge-clause>`'s**, resolved from this run's own `Phase handoff:` outcome line per
`Skill(skill: "workflows-core:reference", args: "next-phase-offer")`, since a declined handoff opened no pull
request to wait on — and it carries its own role and
cost-attribution row (`docs/roles-and-phases.md`). Guidance only, per
`workflows-core:next-phase-offer` — names only that `/brd-split` exists and
where it sits in the route, never its behaviour, which `commands/brd-split.md` owns.

**The offer says which of `/brd-split`'s two modes will run**, so nobody
expects a fan-out that cannot happen: on a slice it runs `allocate-only`
(`commands/brd-split.md` Phase 0 step 5) — it creates no child, because nesting is
capped at one level (`workflows-core:addressing` §6), and walks this
slice's ledger to a recorded fate through its own four resolutions, `covered-by` being the
one that command's walk does not offer on a slice. Allocating is what
makes this slice PRD-eligible
(`${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §5), so it is a real next step, not a
formality:

```
choices: ["Allocate this slice's ledger — /product-workflows:brd-split <BRD-KEY> (Recommended — allocate-only, so no child is created) <merge-clause>", "Ground another declared prerequisite first", "Stop here"]
```

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 11), per
`workflows-core:session-hygiene` §1. Grounding another repository or
prerequisite in the same BRD? → run **`/compact`**. Handing off to `/brd-split`, even yourself? →
run **`/clear`**. Guidance only — nothing is auto-run.

---

## Phase 11 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 10, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase halts on a plugin / skill / command /
reference gap, `emit-block` (`workflows-core:feedback-emission`) fires at
that halt before escalating. None of Phase 0's stops qualify — a missing key, an unresolved BRD,
a resolved root BRD, an inventory or ledger not yet on main (`BRD_GROUND_NO_INVENTORY`, `BRD_GROUND_INVENTORY_NOT_HANDED_OFF`,
`BRD_GROUND_NEEDS_INTAKE` or, for a slice, `BRD_GROUND_NEEDS_SPLIT`; `BRD_GROUND_NOT_HANDED_OFF` where they exist and were never handed off),
an inventory carrying no claim at all
(`BRD_GROUND_EMPTY_INVENTORY`, which is a fact about what the
parent allocated, not about this plugin), and an unset `$REPOS_PATH` are environment / sequencing
halts, never a plugin capability gap. `BRD_GROUND_DIRTY_TREE`, `BRD_GROUND_NEEDS_REBASELINE`, and Phase 7's
`BRD_GROUND_VERIFY_COMMIT_MISMATCH` are repository state, not a plugin gap, either — unlike Phase
7's `INPUT_MISSING`, which is this command getting its own dispatch contract wrong and does fire
`emit-block`.

1. **Invoke `impl-maintenance`** (subagent_type: "workflows-core:impl-maintenance", model:
   `<detection_model>`) with a compact handoff: command `/brd-ground`; what was produced (baselines,
   code/design findings, verifier tally, prerequisite readiness, documentation divergences); key
   events (a dirty-tree stop, a rebaseline, a skipped design pass, an unresolved repo, docs
   grounding OFF or a lead that added a repository — or "none"); workarounds; test result
   N/A; project root = the BRD folder.
2. **Persist plugin feedback (automatic).** Invoke `Skill(skill: "workflows-core:reference", args: "feedback-emission emit-auto")` and call its `emit-auto` entry point (§6) with the Lessons Learned report, `command: /brd-ground`,
   the run's `key` (the `<BRD-KEY>`), `source`, and `plugin_version` (read from
   `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). Surface the persisted path (or "no
   plugin-facing signal — nothing persisted").
3. **Session cost (ALWAYS runs).** Invoke `Skill(skill: "workflows-core:reference", args: "cost-emission emit-cost")` and call its `emit-cost` entry point with `command: /brd-ground`, `phase: brd-to-prd`, `role: pa`,
   the run's `key`, `source`, and `plugin_version`. Surface the persisted path (or the
   report-only notice).
4. **Write the resume pointer.** Invoke `Skill(skill: "workflows-core:reference", args: "session-hygiene")` and, per its §1, write/overwrite `<BRD-dir>/dev-workflows/resume.md` now — after the cost entry, before the
   commit step below. Redact per §1. Silent.
5. **Commit session artifacts (terminal).** Invoke `Skill(skill: "workflows-core:reference", args: "specs-repo-git commit-artifacts")` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. Stages
   ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits
   `<BRD-KEY> Add dev-workflows session artifacts (/brd-ground)` with no `Co-Authored-By` trailer,
   and pushes to the branch Phase 9's handoff created. NEVER touches a code repo, or the current working directory; NEVER force-pushes; NEVER fails the run; skips entirely when the run
   carries `specs_git: blocked`, re-emitting that notice. Hold its §6 outcome line for the final
   report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git for the deliverable
is offered only in Phase 9), and NEVER writes into a code repo, or the current working
directory; no user name is ever written.

---

## Final report

Report: the BRD folder + resolved repositories (with each one's pinned commit); the classification
and model routing (+ any Opus degradation); the prerequisite-readiness block from Phase 4, verbatim
in the two-column form Phase 4 step 3 fixes; finding counts by verdict for `[CG#n]` and `[DG#n]`
separately, and the verifier
tally (`agree` / `extend` / `contradict` / `unprovable`) with every `contradict` rewrite named by
id; the `docs grounding:` line from Phase 1 step 0 verbatim, any repository a Phase 4.5 lead added,
and the count of documentation divergences recorded (each named by the `[CG#n]` it diverges from —
never by an identifier of its own, because it has none); whether the derivation matrix ran and why; any `design-grounder` class-4 gap deferred for want
of a settling `[CG#n]`; the feedback + cost paths; the `Phase handoff:` outcome line
(`workflows-core:phase-handoff` §4.1); the `Specs repo:` outcome line (`workflows-core:specs-repo-git` §6); the next-step
recommendation; and end with the ledger line, read fresh from the (unmodified-by-this-run)
`coverage-ledger.md`, exactly per `${CLAUDE_PLUGIN_ROOT}/references/coverage-ledger-format.md` §6:

```
ledger: <N> requirements — <covered> covered, <deferred> deferred, <rejected> rejected, <unallocated> unallocated, <unresolved> unresolved (<delegated> delegated, <not-built> not built)
```

`/brd-ground` never changes a ledger disposition — that line simply reports where allocation stands
going into `/brd-split`.

**Reporting it now reads one ledger per `covered-by` row.** §6 counts a delegated row through the
BRD it names — this run always stands on a slice (by Final-report time, step 6's gates have long
since guaranteed `coverage-ledger.md` and `brd/brd-inventory.md` are both on main, positive evidence
5a would have refused had this BRD been a root), so that is always a sibling or the parent
(`coverage-ledger-format.md` §3) — so this report resolves each
`covered-by: <BRD-KEY>` row one hop
into that BRD's own `coverage-ledger.md`, resolved from the
working tree by `resolve-address` (`Skill(skill: "workflows-core:reference", args: "addressing resolve-address")`, §3). **This adds
no precondition and no gate.** A child folder that is absent from the tree this run is standing in —
its split not yet merged, most commonly — makes that row `unresolved` in the line and nothing more:
grounding this BRD does not depend on any child, and a run must never stop, degrade, or withhold its
findings because a child could not be read. Phase 0's `require-on-main` gates stay exactly as they
are, on this BRD's own inventory and ledger. A slice does **not** always reach this with
nothing to resolve. `covered-by` is legal on a slice (`coverage-ledger-format.md` §3), where it
names a sibling under the same parent or that parent and marks an **orphan row** — a ledger row for a `[BR#n]` this slice no longer claims, reached by either of §2's two routes: the parent's walk withdrawing a claim that was never more than provisional, or a re-cut moving a claim the slice had committed to and then recorded it would not build (§3.2). Those rows are resolved one hop exactly like a parent's
delegated rows, so a slice reports zero delegated only when its parent withdrew none of its
claims.
