# Whole-round review fixes — design (sub-project I)

**Ships as:** dev-workflows 2.51.0 (canonical + mgd) / 2.21.0 (copilot)
**Branch:** `iv-gu/whole-round-review-fixes` (all three repos)
**Origin:** the seven-axis whole-round review of the 2026-08-07 PM feedback round (2026-08-13)

## Goal

Close the 45 requirements of the whole-round review, so the round's documentation, caller lists, and
verification records describe what the plugin actually does.

## Context

The 2026-08-07 round shipped eight sub-projects (A, B1, B2, C, D, E, F, G, H) plus four in-between
fixes, across twelve versions. Each was reviewed in isolation; none was reviewed against the others.
The whole-round review ran seven independent axes over the result.

**The product came out sound.** ~300 verification checks were re-run against the current tree and
**zero shipped requirements had been silently undone** by a later sub-project. The invariant the
round cared about most — `specs-preflight` at run start, `commit-artifacts` last — traces sound on
every path of all seventeen in-scope commands, and all eight of the round's unreachable-guard fixes
remain in place.

What did not come out sound is the *bookkeeping*. Three classes dominate:

1. **Caller-list residue** — 11 of 18 residue findings. `/update-vi`, `/ready` and `/create-ard`
   shipped and nobody updated the "used by" lists that name their consumers. `CLAUDE.md`'s agent
   ledger is the stalest surface in the repo.
2. **Dead gates** — three more instances of a rule whose consumer never receives the data.
3. **Verification-record arithmetic** — 26 wrong `expect N` values and 3 wrong-target checks across
   four sub-project plans, plus records written before their own sub-project's final fix wave.

## Non-goals

- **The phase-handoff-gate feature is out of scope.** The review's `I3` (`/design`'s "spec is on
  main" gate cannot fire on the case it was written for, and contradicts `specs-repo-git.md` §3.6)
  is **deferred to sub-project J**, which will build on-main gates across the command family, add
  PR creation to `commit-artifacts`, and revise §3.6. Nothing in this sub-project touches PR
  creation, on-main gates, or the `/idea` → `/create-vi` handoff.
- **Almost no new capability.** Nearly every change here makes an existing claim true, or makes an
  existing choice work. The three exceptions are called out explicitly: `R43` (a cost warning the
  feedback asked for — a surfacing change, not a calculation one), `R10` (a process rule), and
  `R45` (a user-requested change to `/idea`'s grill cap).
- **The ~100 per-VI feedback entries** remain deliberately deferred.

## Decisions

Six decisions were settled before specification. Each had a defensible alternative; the alternative
is recorded so it can be revisited without re-deriving the analysis.

**D1 — `docs-grounder`'s `prep` block: narrow the promise, do not wire the producer.**
`read-only-repos.md` promises a four-field `prep` block from all three named consumers;
`docs-grounder` emits none. Scope the §6 output contract to `code-scanner` and `diff-summarizer`,
and document `docs-grounder` as following the detection and read-at-ref rules (§1–§4) while
returning a digest rather than a `prep` block.
*Rejected:* wiring `docs-grounder` to emit `prep`. No consumer branches on it, and
`docs-grounding.md` already carries its own 14-day staleness clause for the docs mount. A uniform
contract is easier to keep true, but not worth changing an agent every authoring command reads.

**D2 — `source-truth.md` §4.1: narrow, applying D1's lens.**
§4.1 assigns `diff-summarizer` duties (surface enum changes, new constants, renamed labels) the
agent never receives and its own spec omits. Remove the duty assignment; the verification is
performed by the consulting agents reading shipped source directly, which is what `source-truth.md`
exists for.
*Rejected:* adding the duty to `diff-summarizer`'s contract. Flagged as the decision most worth
revisiting — if the docs pipeline genuinely wants that signal, wiring it is the better answer.

**D3 — `/document` "no refresh": make it functional.**
Send `fetch: [false if 'no refresh'; true otherwise]`, mirroring `/epics`' three-distinct-pairs
mapping, and sharpen the choice label to say a not-yet-fetched PR will not resolve. `fetch: false`
is genuinely supported — `diff-summarizer` already resolves PRs against the object database as it
stands on read-only mounts.
*Consequence, intended:* `refresh.fetch` also gates `DIRTY_TREE`, so "no refresh" additionally means
a dirty clone stops blocking. That is a real capability — running `/document` against dirty or
offline clones — not a side effect to suppress.
*Rejected:* removing the option. `/epics` supports it correctly; removing it from `/document` alone
would be the inconsistent choice.

**D4 — `/document` direct mode has no reviewer gate; correct the documentation.**
`CLAUDE.md:138` and `:203-204` claim direct mode runs `doc-reviewer` with a `doc-fixer` BLOCKER
cycle. Mode B (`document.md:1331`+) dispatches no reviewer and says so twice. Direct mode's
lightweight design — style-check and fix, no Opus review — is deliberate. Correct `CLAUDE.md` and
`document.md:35` to match.
*Rejected:* adding a reviewer gate to direct mode. That is a feature decision, not a review fix, and
belongs in its own sub-project if wanted.

**D5 — the grill-bounded claim: narrow to `/idea`, and raise `/idea`'s cap to 10.**
`CLAUDE.md:246` states the embedded grill is bounded (≤5) for the whole VI-creation flow. Only
`/idea` is bounded; `/create-vi`, `/create-ard`, `/specify`, `/design` and `/update-vi` are
deliberately relentless. Narrow the claim to `/idea` (R7), **and separately raise `/idea`'s own cap
from 5 to 10, making `--deep` fully uncapped rather than merely "relaxed" (R45).**

Five is too few for the one command whose purpose is discussion, brainstorming and challenge. The
cap is nevertheless kept rather than removed, because it is what makes leftover gaps become
`[NEEDS CLARIFICATION]` markers in `idea.md` instead of being forced to resolution in
conversation — recording an open question is the right outcome for an early artifact, and an
uncapped default would make that mechanism rarely fire. Ten gives the brainstorm real room while
keeping `/idea` predictably terminating on a half-formed thought.
*Rejected:* capping the other five — their relentless design is intentional. *Also rejected:*
uncapping `/idea` outright, which would additionally require retiring `--deep`, since the flag
would no longer mean anything.

**D6 — terminal order: align `/release-notes`, clarify the SSOT for `/document`.**
`session-hygiene.md:118-120` states the canonical terminal order (deliverable + handoff → feedback →
follow-ups → cost → `resume.md` → `commit-artifacts`). The two deviations turn out to be different
problems and get different answers.

**R11 — `/release-notes` runs follow-ups before feedback: align the command.** Measured across the
tree, **4 of 5 commands with both emitters follow the canonical order; `/release-notes` is the lone
inversion.** A rule governing seventeen commands is not rewritten to accommodate one, and the fix is
an adjacent-phase swap (Phase 9/10) — low risk.

**R12 — `/document` emits feedback before its Finish & handoff phase: clarify the rule, do NOT move
the phase.** Three facts, all verified, point the same way:
1. **There is no majority to align to.** `/document` is the **only** command in the plugin with a
   `Finish & handoff` phase (`grep -rn '^## Phase.*Finish\b' commands/*.md` → one hit,
   `document.md:1054`). An earlier measurement suggesting otherwise was a false positive matching
   `## Phase 6.1 — CDN image handoff`.
2. **The two steps cannot interact.** Phase 8.5 is the **docs-repo** git finish (squash → branch →
   PR draft); `emit-auto` writes plugin feedback into `$SPECS_PATH`. Different repositories.
3. **Moving it would manufacture an unreachable guard.** Phase 8.5 opens *"Run this phase only when
   Phase 6.3 wrote + committed in a git repo … Skip otherwise."* Relocating a **mandatory** feedback
   emission to sit after a phase that skips itself is exactly the defect class this round produced
   eight times, most of them created by moving a rule.

So the binding sequence is the **emitter tail** — feedback → follow-ups → cost → `resume.md` →
`commit-artifacts` — which `/document` already satisfies exactly. Amend `session-hygiene.md` rule 2
to say so: a command's deliverable-side finish may precede the tail, and where it sits is that
command's business.
*Rejected:* moving `document.md`'s Phase 8/8.5. This was the highest-risk edit in the sub-project;
it is not made, because the finding it would fix is a documentation imprecision rather than a
defect.

## Requirements

45 requirements, deduplicated across the seven axes. Full per-finding provenance, exact `file:line`,
and the axis label each came from are preserved in the review's own records; this section is the
authority for what gets built.

### Critical (1)

| ID | Requirement |
|---|---|
| **R1** | copilot `dev-workflows/skills/upgrade/README.md` documents `/upgrade` slash-form at 13 sites; rule 6 (`skills/_shared/next-phase-offer.md:30-34`) names `/upgrade` as colliding with a Copilot CLI built-in and forbids printing the slash form. **Delete the file** rather than convert it — it is the only README under `skills/` (the other 20 skills have none), nothing in the edition references it, `SKILL.md:5,:9` already documents the correct `upgrade:` invocation, and it is stale (17 Jul vs `SKILL.md`'s 11 Aug). Its existence *is* the drift. **First fold its two unique passages into `SKILL.md`** — `.sdkmanrc` in the Java version-declaration file list, and the "incompatible explicit versions" conflict example — then delete. **And** sharpen rule 6's exemption clause, which today exempts "prose that describes the pipeline to a reader of this edition's source" (which a README arguably is): restate it to exempt *narrative description of the pipeline* while explicitly binding *any text that tells a reader what to type* — usage blocks, example tables, quick-starts, tips — in whatever file it appears. That closes the class, not just the instance: D's seven printed surfaces were all command-file surfaces, which is precisely why a README could leak. Repo: **copilot** (both halves). |

### Important (10)

| ID | Requirement |
|---|---|
| **R2** | `/document`'s "no refresh" is inert — `document.md:395-397` hardcodes `fetch: true`. Apply **D3**: vary `fetch`, sharpen the `:196` label. |
| **R3** | `read-only-repos.md:5,:69` promises a `prep` block `docs-grounder` never emits. Apply **D1**. Update `CLAUDE.md`'s read-only-repos paragraph to match. |
| **R4** | `/ready` runs a dirty-tree prompt (`ready.md:51-57`) *before* the preflight (`:71-76`) whose §3.4 flush exists to clear exactly that dirt, violating §7.1's "as early as `$SPECS_PATH` is known". **Move the preflight to immediately after `$SPECS_PATH` resolves (`:47-49`), ahead of the dirt test** — §7.1 already requires that ordering, so relocating satisfies both the rule and the finding. Excluding the §2.1 paths from the dirt test would silence the symptom while leaving the ordering violation in place. |
| **R5** | `CLAUDE.md:138` and `:203-204` claim a direct-mode `doc-reviewer` gate. Apply **D4** to `CLAUDE.md`. |
| **R6** | `document.md:35` says both modes share `doc-reviewer`; `:1490`/`:1494`/`:1561` deny it. Apply **D4** to `document.md`. Do with R5 — one fact, two files. |
| **R7** | `CLAUDE.md:246`'s grill-bounded invariant is true of `/idea` only. Apply **D5**. |
| **R8** | `/idea` Phase 2.6's round-2 dispatch (`idea.md:163`) and `classification.md` §8.5 both omit `refresh:`, so an executor may fall back to `code-scanner`'s `true`/`true` default and switch/pull the user's clones — contradicting `:159-161`. State that round 2 reuses round 1's `refresh:` block verbatim. |
| **R9** | Sub-project F's verification record (`plans/2026-08-11-environment-guards-verification.md`) rows V5 and V8 were falsified by F's own final fix wave 17 minutes after the record was committed, while the preamble claims every value "was re-derived from the tree at verification time". **Correct V5 to 7 consumers and V8 to 3 choices, and add a one-line note to each row recording that the original value was superseded same-day by `7142976`.** Correcting alone would erase the evidence that the record went stale; annotating alone would leave two wrong numbers standing. |
| **R10** | No file owns the rule that would have prevented R9 and most of R37–R40. Add to this repo's `CLAUDE.md` conventions: **a sub-project's verification record is written last — after the final fix wave, never before it.** |
| **R45** | `/idea`'s embedded grill is capped at 5 questions — too few for the one command whose purpose is discussion and challenge. Apply **D5**: raise the default cap to **10**, and make `--deep` fully uncapped rather than "relaxed". Update `commands/idea.md`, `references/grilling-technique.md`, and `CLAUDE.md:246` together, and verify the `[NEEDS CLARIFICATION]` overflow path still fires at the new bound. User-requested behaviour change — needs a CHANGELOG entry. |

### Minor (34)

**Caller lists and rosters** — one defect class, `/update-vi` / `/ready` / `/create-ard` shipping
without their consumers' lists being updated:

`R13` `cost-emission.md:3-5` omits `/update-vi` · `R16` `CLAUDE.md` model-routing roster says 13,
is 14 (and `skills/model-routing/SKILL.md:3` repeats it) · `R17` `CLAUDE.md` source-truth list names
3 consumers, is 5 (`doc-writer`, `risk-planner`) · `R19` `feedback-emission.md:4,:191` and
`README.md:128-130` say "twelve workflow commands" for `emit-auto`; it is 13 · `R20`
`risk-planner.md:11` names `/vuln`, which never dispatches it · `R21` `CLAUDE.md:155` omits
`/upgrade`, which does · `R22` `CLAUDE.md:158` credits `/release-notes` with `doc-fixer`; it uses
`dt-doc-fixer` · `R23` `vi-reviewer.md:12` omits `/update-vi` · `R24` `jira-reader.md:11,15-18`
omits `/create-ard` and `/ready` · `R25` `CLAUDE.md:162`'s "Jira mode" qualifier on
`docs-style-checker` is stale — both modes use it · `R26` `grilling-technique.md:27-28` under-counts
both the bounded list (`/prompt-grill-me`) and the relentless list (`/update-vi`, `/create-ard`) ·
`R27` `jira-input-resolution.md:153` omits `idea-reader` · `R28` `README.md:256` lists 4 of 7
`jira-reader` dispatchers · `R29` `CLAUDE.md:153` omits `/upgrade`'s and `/vuln`'s direct
`test-baseliner` invocations · `R30` `ard-resolution.md:57` and `CLAUDE.md:186` omit `/ready` ·
`R33` `CLAUDE.md:166` omits `/update-vi` · `R35` "cited by the **seven** commands" is eight, in all
three editions (canonical `CLAUDE.md:124`, mgd `CLAUDE.md:136`, copilot
`dev-workflows/README.md:369`).

**Stale claims:** `R31` `CLAUDE.md:214`'s branch policy is stale three ways, including a `git_repo`
context that no longer exists · `R32` `CLAUDE.md:220` names a `document-as-jira` enum value that
exists nowhere (it is `document-as-spec`) · `R34` `CLAUDE.md:144`'s `/upgrade` map edge omits its
`risk-planner@Opus` step.

**Terminal order (D6):** `R11` `/release-notes` Phase 9/10 inverted — swap them · `R12`
`/document` emits feedback before its Finish & handoff phase — **amend `session-hygiene.md` rule 2**
so the binding sequence is the emitter tail (feedback → follow-ups → cost → `resume.md` →
`commit-artifacts`), which `/document` already satisfies; the phase is NOT moved.

**Model routing / cost:** `R14` §8.5 gives `/idea` two opposite rules for an `absent`-with-outside-
deferral theme (`classification.md:380-383` conditional vs `:389-391` unconditional) — scope the
precedence sentence to `/implement` · `R15` `cost-prices.yaml:22` names "Opus 4.5", in no chain, and
`cost-emission.md:154` calls Haiku "routing-policy-reachable" when no path reaches it · `R43` build
the cost feedback's durable asks: a visible warning when an unpriced model dominates a run, and a
maintainer checklist tying a new model generation to both files.

**The cost arithmetic itself is sound — R15 and R43 are prose and reporting only.** Verified: the
table's eight keys match the routing chains exactly (Opus 5/4.8/4.7/4.6, Sonnet 5/4.6/4.5, Haiku
4.5); there is **no `claude-opus-4-5` key**, so R15's comment names a version present in neither the
chain nor the table. Haiku *is* priced despite being unreachable — a harmless defensive entry; only
the "routing-policy-reachable" claim is wrong. And the engine **already detects** the unpriced case
(`scripts/session-cost.py:218` returns `"unpriced-model"`), so R43 is a one-line surfacing change,
not a calculation fix. No change to `session-cost.py`'s pricing logic is in scope.

**Dead gate:** `R18` `source-truth.md:217-221` §4.1 assigns `diff-summarizer` duties it never
receives. Apply **D2**.

**copilot-only:** `R41` "§2.1 Sonnet [detection] chain" survives at `agents/epic-writer.md:3`,
`skills/docs-profile/SKILL.md:255`, `skills/epics/SKILL.md:341` against 60+ correct sites.

**Format:** `R42` `idea-format.md:14`'s `sources[].provenance` enum never gained `doc-grounding`.

**Verification-record bookkeeping** (specs repo only, no plugin edition affected): `R36` D's V18
records a 28-line breakdown summing to 27, and G's tally says 25 PASS against 27 passing rows ·
`R37` 12 wrong `expect N` / wrong-target checks in C's plan · `R38` 4 wrong + 1 stale-at-ship in
B1's · `R39` 6 wrong + 2 wrong-target in B2's · `R40` 5 wrong in A's.

**Feedback:** `R44` annotate `2026-08-12-implement-broad-then-narrow-candidate` as CLOSED by 2.50.0.

## Implementation shape

Thirteen tasks, grouped so each is one coherent diff a reviewer can accept or reject:

1. **`CLAUDE.md` roster sweep** — R5(half), R7, R16, R17, R21, R22, R25, R29, R30, R31, R32, R33, R34
2. **Agent / reference caller-list sweep** — R13, R19, R20, R23, R24, R26, R27, R28
3. **Direct-mode reviewer gate** — R5 + R6 (one fact, two files)
4. **`/idea` fixes** — R8 (round-2 `refresh:`) + R45 (grill cap 5 → 10, `--deep` uncapped)
5. **`/document` "no refresh"** — R2
6. **Dead-gate narrowing** — R3 + R18 (same lens, D1/D2)
7. **`/ready` preflight ordering** — R4
8. **Terminal order** — R11 (swap `/release-notes` Phase 9/10) + R12 (amend
   `session-hygiene.md` rule 2; no command file is touched)
9. **Cost subsystem** — R15 + R43
10. **Dispatcher count, all three editions** — R35
11. **copilot dialect** — R1 + R41 (copilot-only, no canonical counterpart)
12. **Specs-repo bookkeeping** — R9, R10, R36, R37, R38, R39, R40, R44 (zero behavioural impact;
    lives entirely outside the three plugin editions)
13. **Standalone** — R14, R42

**Porting.** Tasks 1–9 and task 10's canonical half are canonical changes: port to **mgd**
content-verbatim (the five identity files stay divergent), then hand-adapt for **copilot** per the
four dialect rules — colon-form command names, `${CLAUDE_PLUGIN_ROOT}` → the installed path,
`subagent_type:` → `agent_type:`, and copilot's own detection chain. **Never `cp` into copilot.**
Task 11 and task 10's copilot half are copilot-only. Task 12 needs no porting at all.

## Verification

There is no test framework — the product is prompt markdown. Every requirement is verified by grep,
`diff`, or reading, with counts whitespace-normalized.

Three rules, adopted from what this round's own evidence got wrong:

- **A check must be capable of failing, and that must be proven** — run it against a deliberately
  broken copy in `/tmp` (never in the repo) and confirm it reports the failure.
- **Re-derive every expected value at the tree being verified.** Do not copy an `expect N` from
  another plan; 2 of this round's wrong values propagated exactly that way.
- **The verification record is written last** — after the final fix wave. This is R10, and this
  sub-project is its first application.

## Risks

- **The `document.md` phase move was removed, not mitigated.** It would have been the highest-risk
  edit here — relocating a mandatory emitter past a self-skipping phase in a 1745-line two-mode
  command. Verification showed the finding is a documentation imprecision, so D6 now amends the rule
  instead. No command file is touched for R12, and the residual risk is zero.
- **Task 1 is a large single diff.** Mitigation: every item is an independent one-line claim with a
  named true value; the reviewer checks each against the tree rather than reading for sense.
- **R43 and R45 are the only behaviour changes** in a sub-project otherwise made of corrections.
  R43 is included because the feedback entry that asked for it is otherwise only half-closed, and
  is smaller than it first appeared — the engine already computes `unpriced-model`, so only the
  surfacing is missing. R45 is user-requested; its one risk is the `[NEEDS CLARIFICATION]` overflow
  path, which must be verified to still fire at the new bound rather than silently never firing.
