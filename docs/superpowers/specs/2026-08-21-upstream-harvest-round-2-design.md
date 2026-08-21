# Upstream harvest round 2 — verify what you assert — design

**Status:** approved for planning — pre-implementation design snapshot
**Ships as:** dev-workflows 2.54.0 (canonical + mgd) / 2.24.0 (copilot)
**Branch:** `iv-gu/upstream-harvest-round-2` (all three repos)
**Origin:** upstream survey 2026-08-21 of BMAD-METHOD, github/spec-kit, obra/superpowers, and
mattpocock/skills against the 2026-07-29 harvest baseline (`docs/superpowers/harvest/INDEX.md`,
`NEXT.md`). Four Tier-1 items adopted; items 5–7 recorded as backlog.

## 1. Context

The 2026-07-29 harvest took eight items from the same four upstreams and shipped them through
dev-workflows 2.38.0–2.41.0. Since then the upstreams produced 383 commits (SpecKit 196, mattpocock
123, BMAD 63, superpowers 1 — a squashed v6.3.0 release). Four changes in that window converge on a
single discipline this plugin does not currently hold, and each of the four upstreams arrived at some
part of it independently:

- **superpowers** (task-reviewer-prompt.md): *"Evidence you cannot see is not evidence that doesn't
  exist… Re-running the suite to regenerate what you failed to read is not verification."*
- **BMAD** (#2753): *"Verify its own claimed consequence at the location it names… Another finding's
  outcome, however adjacent, never settles this one."*
- **BMAD** (#2748, new `claims-check.md`): *"The narrative is the author's testimony, not evidence: a
  claim repeated in a code comment is still the same claim, not confirmation."*
- **BMAD** (#2733 / #2715): *"For every claim the block will make about what a command does, read the
  target or script that runs it and verify the claim."*

The common shape: **an agent asserted something it had not verified, and the next station believed
it.** That failure mode is well-attested in this plugin's own history — the 2.44.1 spec-file-table
Critical, the 45/46-PASS verification table over 22 unrunnable commands, the provenance inversion
where *"the writer emitted provenance and the reviewer endorsed it, both correctly following
instructions the plugin itself contradicted."*

This round closes it at three stations, plus a fourth item covering the instruction files where the
unverified claims accumulate.

### 1.1 What this round is not

Items 5–7 of the survey (bug-diagnosis redaction + completion criterion; "design it twice" for
`/design`; subagent-dispatch bounds) are **deliberately out of scope** and recorded in
`docs/superpowers/harvest/NEXT.md` as named backlog. They are not covered by anything below; a later
round must not read their absence as "considered and rejected."

## 2. The rule, and its three stations

One rule, stated once, applied at three stations:

> Do not act on, report, or accept a claim you have not verified against the thing it names.

| Station | Item | The claim | What "verify" means |
|---|---|---|---|
| Agent receiving handed-over evidence | 1 | "here is the diff / report you asked for" | the file at the stated path is readable |
| Orchestrator triaging findings | 2 | "this finding's consequence occurs at this location" | trace the location past the hunk |
| Reviewer handed an agent's account of its own work | 3 | "I applied X and it does Y" | falsify the account against the traced code |

Item 4 applies the same rule to the instruction files themselves.

## 3. Item 1 — the read-failure contract

### 3.1 The gap

Waves M and S (2.39.2 / 2.39.3) converted six agents' inputs from pasted content to `mktemp` file
paths. All six say *"Read the file first when given a path"*; **none states what to do when that read
fails.** Verified 2026-08-21 across `agents/{code-review,review-fixer,risk-planner,test-writer,
vuln-fixer,upgrade-executor}.md` — one match each for the inline-or-path wording, zero failure
branches.

The pattern exists elsewhere in the plugin — `agents/epic-writer.md:28` and `agents/doc-writer.md:32`
both return `BLOCKED` on a missing/unreadable handoff — so this is an omission in the wave, not an
unconsidered case.

The dangerous failure is silent, not loud: `code-review` re-deriving its own `git diff` (at whatever
base HEAD happens to be) or `test-writer` proceeding with no diff, then reporting success. That is
precisely the "re-running to regenerate what you failed to read" that upstream now forbids.

### 3.2 The contract

Two tiers, because `references/phase-handoff.md` §3.4 already holds that an absent optional input
falls back to the caller's pre-existing behaviour and never becomes a new prerequisite. A blanket
hard-stop would violate that for the optional inputs.

**Evidence inputs** — the artifact the agent's judgement rests on: `Diff` (`code-review`,
`test-writer`), review output (`review-fixer`), research report (`vuln-fixer`), upgrade plan
(`upgrade-executor`). An unreadable evidence path is a **hard stop**: return a structured gap naming
the path, and **never** regenerate the artifact by any other means.

**Context inputs** — optional grounding: `Plan`, `applicable_ard`, `applicable_spec`. An unreadable
context path **degrades to absent**: proceed exactly as if the input had not been passed (conditional
dimensions stand down as they already do), and record the degradation in the output so the skip is
attributed. This mirrors `references/gate-ledger.md`'s rule that no skip goes unattributed.

The load-bearing sentence is the prohibition, not the stop. A rule that only says "stop" invites an
agent to helpfully recover instead.

### 3.3 Placement

The rule text goes in `references/context-management.md`, which already owns the "Hand off by file,
not paste" strategy (`:13–17`, including the `mktemp`-outside-every-repo-tree guard). It is currently
cited by `references/session-hygiene.md` and `commands/implement.md` only; the six agents become new
citers via `${CLAUDE_PLUGIN_ROOT}`. Single source of truth, six one-line citations — not six copies.

## 4. Item 2 — orchestrator triage

### 4.1 The gap

`agents/review-fixer.md` goes from "parse all findings" (step 1) straight to "fix it if locally
actionable" (step 2). No step verifies that a finding's claimed consequence actually occurs. A
false-positive BLOCKER therefore gets a fix applied to it, and the most common such fix is a guard
for a state nothing reaches — the unreachable-guard class this repo has hit repeatedly, most sharply
in the feature where three consecutive fixes each caused the next.

### 4.2 The seam

Triage runs wherever an **Opus reviewer's reasoned findings feed a fixer**:

| Path | Triage |
|---|---|
| `code-review` → `review-fixer` (`/implement`, `/vuln`, `/upgrade`) | yes |
| `doc-reviewer` → `doc-fixer` (`/document`, Jira mode) | yes |
| `epic-reviewer` → `doc-fixer` (`/epics`) | yes |
| style-checker → `doc-fixer` (`/document` direct mode, `/release-notes`, the style-fix cycle inside Jira mode) | no |

The seam is **reasoned-claim producer vs deterministic producer**, not code vs docs. A `doc-reviewer`
finding is a claim about consequence; a Vale finding is not — a rule matched or it did not, and there
is nothing to trace. Note that `/document` direct mode falls outside by the rule itself (it has no
reviewer gate at all — style check plus `doc-fixer`, no BLOCKER cycle, per `commands/document.md`
`:1490`/`:1494`), not by a carve-out.

An earlier draft of this design excluded the docs path on the premise that its findings are mostly
deterministic linter output. **That premise is false** and is recorded here so it is not re-derived:
`doc-reviewer` carries 17 dimensions and `epic-reviewer` 18 — more reasoned-claim surface than
`code-review`'s 10 — and `doc-fixer` is explicitly doc-type-agnostic, collapsing all four producers
into one `file`/`line`/`severity`/`message`/`suggestion` stream.

### 4.3 The step

A new orchestrator phase between the review gate and the fixer dispatch.

**Which dispatch.** `/document` and `/epics` each invoke `doc-fixer` **more than once** — once on
style-checker violations and once on reviewer findings. The triage phase attaches to the
**reviewer-fed dispatch only**. A plan task that places it before every `doc-fixer` call has
implemented the wrong thing, and would put a verification step in front of linter output where §4.2
says it does not belong.

Authority sits with the orchestrator rather than the fixer because `review-fixer` and `doc-fixer` run
on the detection/Sonnet chain while `code-review`, `doc-reviewer`, and `epic-reviewer` are Opus-pinned;
letting the fixer dismiss findings would let a weaker model overrule a stronger one. BMAD places it
identically.

For each finding, before any grouping:

1. **Verify its own claimed consequence** at the location it names. Read past the hunk — into callers,
   guards upstream, whatever the site depends on — far enough to tell whether that consequence
   actually occurs. Another finding's outcome, however adjacent, never settles this one.
2. **Keep or dismiss.** Keep only where verification confirmed the consequence. Dismiss noise, claims
   verification refuted, and claims it could not substantiate. Whatever the reason, **it must dispose
   of that finding's own claim** — a true fact about neighbouring code that leaves the claim standing
   is not a dismissal, and the finding stays kept.
3. **Record every dismissal with its reason.** Never drop a finding silently. BMAD deleted its
   `reject` (drop-silently) category outright for this reason; this design has no such category to
   begin with and must not acquire one.

Only survivors reach the fixer.

### 4.4 The patch gate

`review-fixer` and `doc-fixer` gain the evidence gate on what they may apply (BMAD #2697): apply the
smallest fix only where the finding shows a defect that **actually occurs**, missing coverage for a
specific case, or a broken gate or convention — *not a state nothing reaches* — and where that fix
adds no public surface and **guards no state the finding did not demonstrate**.

`doc-fixer` already holds most of this in domain-specific form (it refuses to invent content that was
not in the sources, and to restructure prose); the gate generalises what is there rather than
introducing a new concept.

## 5. Item 3 — claims falsification

### 5.1 The mechanism

Three reviewers gain an optional **`claims_file`** input and a conditional final dimension.

The ordering property is the point of the whole item: the reviewer must trace the code
*independently*, and only then read the account of what the change supposedly did. BMAD buys that
property with step ordering, because its reviewer receives the claims file at step 5. Our reviewers
receive their whole brief in one prompt, so the property is not ours for free.

**We buy it with the file-handoff infrastructure waves M and S already shipped.** `claims_file` is
handed as a path with an explicit instruction not to read it until the final dimension. The agent
physically does not hold the content until it chooses to `Read` it, so the guarantee is structural
rather than honour-system — which matters, because an honour-system ordering instruction sitting
above content already in context is exactly the dead-gate shape this repo keeps rediscovering.

```
code-review inputs:
  Plan        → <path>   read at start
  Diff        → <path>   read at start
  claims_file → <path>   DO NOT read until the final dimension

Final dimension — Claims falsification (conditional):
  Precondition: all other dimensions complete, findings recorded.
  Read claims_file now, for the first time.
  Extract each checkable claim; try to falsify it against what you already traced.
  Verified claims produce nothing.
```

### 5.2 What feeds it

Agent testimony that already flows through the pipeline — no new artifact, no new authoring step.
Verified 2026-08-21, there are **two distinct wiring shapes**, and a plan task must not treat them as
one:

| Consumer | `claims_file` | When | Current state | Change |
|---|---|---|---|---|
| `code-review` | `review-fixer` Fix Report | re-review, `/implement` | not passed (`:486` re-captures the diff only) | **add** |
| `doc-reviewer` | `doc-fixer` Fix Report | re-review, `/document` Jira mode | not passed (`:939` bare "Re-invoke `doc-reviewer` once") | **add** |
| `epic-reviewer` | `doc-fixer` Fix Report | re-review, `/epics` | not passed (`:442` bare "Re-invoke `epic-reviewer` once") | **add** |
| `code-review` | `vuln-fixer` report | first review, `/vuln` | **passed inline in the brief** (`:153` "the fixer output") | **relocate** |
| `code-review` | `upgrade-executor` report | first review, `/upgrade` | **passed inline in the brief** (`:147` "the executor output") | **relocate** |

The first three are absent inputs: the Fix Report exists and is simply never handed to the re-review,
so the reviewer re-reads the artifact without ever checking the account against it.

The last two are worse than absent, and this was not visible when the item was scoped. `/vuln` and
`/upgrade` **already pass the fixer's own account into the review brief, where it is read at the
start** — before the reviewer has traced anything. That is not a missing check; it is active
anchoring, the precise failure §5.1's deferred read exists to prevent. For these two the change is to
**move** that content out of the brief and into `claims_file`, not to add a new input. Removing it
from the brief is mandatory, not optional: leaving it in both places would defeat the deferral while
appearing to implement it.

Absent `claims_file` ⇒ the dimension does not apply, is not mentioned, and nothing else changes —
matching the established `applicable_ard` / `applicable_spec` conditional-dimension pattern.

### 5.3 Finding shape

A falsified claim is a finding in each reviewer's existing severity schema, with `location` = where
the code contradicts the claim, `observation` = the claim quoted or tightly paraphrased against what
the code actually does, and `suggestion` = the correction. Severity by consequence for whoever
believed the claim. **Verified claims produce nothing** — this dimension is silent on success.

### 5.4 Residue

Each reviewer's dimension count is stated in more than one place, and the counts must move together.
Verified 2026-08-21:

- **`code-review`** — four anchors: `:43–44` ("each of the eight dimensions below (plus the
  conditional ninth and tenth…)"), `:49` ("one of the ten below"), the `## Review dimensions` list,
  and the `## Output` block.
- **`doc-reviewer`** — two anchors: the `## Review dimensions` section and the 17 `####` output
  slots. **No numeric count phrase exists** in this file.
- **`epic-reviewer`** — two anchors: the `## Review dimensions` table and the 18 `####` output slots.
  **No numeric count phrase exists** in this file.

An earlier draft asserted "three places each" for all three reviewers. That was a guess and it was
wrong; the counts above are derived from the files. Any plan task must re-derive rather than copy
them.

## 6. Item 4 — instruction-file maintenance

### 6.1 The gap

`agents/impl-maintenance.md` (125 lines) proposes CLAUDE.md, reference-doc, and hook changes after
every session. It contains **zero** rules about verifying what it proposes or protecting what is
already there — grepped 2026-08-21 for verify / claim / stale / contradict / narrow: no matches.

The consequence is visible in this repo's own history: the twelve-place stale workflow map, the
direct-mode `doc-reviewer` gate documented for a gate that never ran, and two separate expired-claims
audits.

### 6.2 The rules

New `references/instruction-file-maintenance.md`, five rules adapted from BMAD #2733 / #2715:

1. **Verify every command claim against the thing that runs it.** For any claim about what a command,
   script, or gate does, read the target and verify it before writing the claim down.
2. **A rewrite that narrows a rule is a deletion.** If a rewrite weakens, narrows, or drops part of a
   rule, the lost part is itemised as a deletion, not folded silently into the rewrite. Keep the rule
   itself; examples may explain a rule but cannot replace it.
3. **A pointer must name an observable trigger** — a path, a file type, a named task — never one the
   agent must judge ("when the task is complex") or track about itself ("before your first edit").
4. **Two live contradictory instructions is a defect**, to be fixed rather than left for the reader to
   adjudicate.
5. **Retirement needs grounds** — stale, wrong, already enforced by a check, harmful/contradictory, or
   explicitly approved as a line item. Never "it looks derivable" and never "nothing has failed on it
   lately."

### 6.3 Placement

The reference is cited by `agents/impl-maintenance.md` and indexed in `CLAUDE.md`'s source-truth
section (Copilot: the `_shared` reference list in `dev-workflows/README.md`, since that edition has no
`CLAUDE.md`; its counterpart `.github/copilot-instructions.md` is a separate file with different
content and is not the index).

Placing this in a reference rather than inside the agent is deliberate and self-applying: rules 1–5
govern the hand edits we make to `CLAUDE.md` in every session, which is where the stale claims
actually originate. An agent-only home would bind the suggestions and not the authors.

## 7. Waves

**Wave 1 — items 1, 2, 3.** Fifteen files per edition:

| File | 1 | 2 | 3 |
|---|:-:|:-:|:-:|
| `references/context-management.md` | ● | | |
| `agents/code-review.md` | ● | | ● |
| `agents/review-fixer.md` | ● | ● | |
| `agents/risk-planner.md` | ● | | |
| `agents/test-writer.md` | ● | | |
| `agents/vuln-fixer.md` | ● | | |
| `agents/upgrade-executor.md` | ● | | |
| `agents/doc-fixer.md` | | ● | |
| `agents/doc-reviewer.md` | | | ● |
| `agents/epic-reviewer.md` | | | ● |
| `commands/implement.md` | | ● | ● |
| `commands/vuln.md` | | ● | ● |
| `commands/upgrade.md` | | ● | ● |
| `commands/document.md` | | ● | ● |
| `commands/epics.md` | | ● | ● |

Sequenced item 1 → item 3 → item 2 within the wave: item 1 establishes the read contract that item 3's
deferred `claims_file` read depends on, and item 2 consumes findings item 3 can produce.

**Wave 2 — item 4.** `references/instruction-file-maintenance.md` (new), `agents/impl-maintenance.md`,
`CLAUDE.md`.

**Wave 3 — port + release.** Per §8.

## 8. Port

**mgd** — `cp` the `plugins/dev-workflows` tree. Five in-plugin files are mgd identity and are never
copied: `.claude-plugin/plugin.json`, `README.md`, `LICENSE`, `references/dependencies.md`,
`CHANGELOG.md`. Two repo-root files are hand-edited: `CLAUDE.md`, `.claude-plugin/marketplace.json`.
The post-port assertion is `diff -rq` on the two plugin trees reporting **exactly those five and
nothing else**.

**Copilot** — never `cp`; apply each edit surgically to Copilot's own file. Four dialect rules:
`task(agent_type:)` not `Agent(subagent_type:)`; absolute
`~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<file>.md` not
`${CLAUDE_PLUGIN_ROOT}`; **colon-form** command names (`idea:`, not `/idea`); lowercase
`tools: [view, glob, grep, bash]`. Copilot's `references/` equivalent is `skills/_shared/`; its
`commands/` equivalent is `skills/<cmd>/SKILL.md`.

All fifteen Wave-1 targets and all three Wave-2 targets were verified to exist in all three editions
on 2026-08-21, and Copilot carries the same inline-or-path wording in all six item-1 agents — so this
round has no missing-target asymmetry to design around. Confirm before editing regardless; the
absence of asymmetry here is a fact about this round, not a standing property.

**Catalogs and versions** — three catalogs, derived by `find <repo> -name 'marketplace.json' -not
-path '*/.git/*'` with no `-maxdepth`, never by a typed list: `.claude-plugin/marketplace.json`
(canonical, mgd) and `.github/plugin/marketplace.json` (Copilot, depth 3). Each catalog carries a
per-plugin `version` **and** a repeated `description`; each `plugin.json` carries its own `version`.
Six files, all six in the plan's file table. The description budget is 1024 characters, enforced by
`scripts/validate-catalog.py`, and this round is behavioural rather than capability-changing — the
blurbs should not need to grow, and must not be appended to if they do.

Copilot's `.github/copilot-instructions.md` is in the inventory from the start. It is asymmetric with
the other editions in content, so confirm each mirrored edit has a target there; skipping with a
stated reason is correct, inventing a section is not.

**Versions** — canonical + mgd `2.53.2 → 2.54.0`; Copilot `2.23.2 → 2.24.0`. Minor, not patch: new
behaviour.

## 9. Verification

There is no test framework. Verification is:

1. **Read-back** — re-read each edited file end to end.
2. **Consistency greps** — every `expect N` **re-derived against the tree being verified**, never
   copied from another task or from this document. §5.4's counts are the worked example of why.
3. **Manifest and gate checks** — `claude plugin validate` (both Claude repos), Copilot manifest
   parses as JSON, `scripts/validate-catalog.py`, `scripts/check-id-grammar.sh --selftest` then the
   tree scan.
4. **Residue audit** — the question is not "did my rule land everywhere" but **"what did I make
   false?"** Covering at minimum: `code-review`'s four dimension-count anchors; the two output-slot
   sets in `doc-reviewer` / `epic-reviewer`; `CLAUDE.md`'s workflow map, agent ledger, and key
   invariants for all five commands that gain a phase; and `README.md`'s agent/reference tables in all
   three editions.
5. **Reachability** — grep-prove that `context-management.md`'s new section and
   `instruction-file-maintenance.md` are each cited from every consumer named here, and that no
   consumer cites a section that does not exist.
6. **Relocation completeness** (§5.2) — for `/vuln` and `/upgrade`, grep-prove the fixer/executor
   output is named **once**, as `claims_file`, and **no longer appears in the review brief**. Content
   left in both places defeats the deferred read while appearing to implement it, and would pass every
   other check in this list.
7. **Port parity** — `diff -rq` per §8; canonical↔Copilot handle counts; zero `${CLAUDE_PLUGIN_ROOT}`
   or `subagent_type` leakage into Copilot files; zero slash-form command names introduced there.

**The verification record is written after the final fix wave, never before it.** Three of the
2026-08-07 round's records went stale because the record was written first, and one was falsified by
its own sub-project's next commit seventeen minutes later.

### 9.1 The self-referential risk

This round's subject matter is verification that lies, across a diff of fifteen files times three
editions. A single whole-branch review over all of it is the same shape of failure it exists to
prevent. Checkpoint after item 1 lands rather than reviewing all three items cold.

## 10. Documentation surfaces

Every surface below is part of the wave that changes the behaviour it describes, not a follow-up. A
doc surface updated in a later commit is a surface the port review cannot see.

### 10.1 Live surfaces that change

| Surface | Editions | What changes |
|---|---|---|
| `<plugin>/README.md` — agent table | 3 | `code-review`, `doc-reviewer`, `epic-reviewer` dimension counts (§10.3); `review-fixer` / `doc-fixer` rows gain the survivor + patch-gate contract |
| `<plugin>/README.md` — `/implement` mermaid | 3 | the review node gains the triage step (§10.2) |
| `<plugin>/README.md` — `_shared` reference list | Copilot only | index bullet for `instruction-file-maintenance.md` |
| `CLAUDE.md` — source-truth index, workflow map, key invariants | canonical + mgd | new reference indexed; the five commands that gain a triage phase; the read-failure and claims contracts as invariants |
| `.github/copilot-instructions.md` | Copilot | same content **where a target exists** — this file is asymmetric with the other editions; skipping with a stated reason is correct, inventing a section is not |
| `CHANGELOG.md` | 3 | one entry per edition; mgd's annotated "(ported from `ihudak-claude-plugins`)" |
| `marketplace.json` + `plugin.json` | 3 each | version only (§8). The `description` blurb is a stable capability statement and this round is behavioural — it should **not** grow, and must never be appended to |

### 10.2 Mermaid

Live mermaid exists in exactly one file per edition: `<plugin>/README.md`, two diagrams each. Verified
2026-08-21.

**Diagram 2 — `/implement` workflow — changes.** Its review node currently collapses the gate into one
step, which is the step this round splits:

- canonical + mgd: `RV["Opus code-review → review-fixer (gate before tests)"]`
- Copilot: `RV["test-writer → strong-tier code-review → review-fixer (gate: tests never run before non-BLOCK)"]`

The two are **not byte-identical** and must not be made so — Copilot says "strong tier" where the
Claude editions say "Opus", per that edition's model-tier vocabulary. Edit each in its own dialect;
never `cp`.

**Diagram 1 — the PM/PA/PE/Dev/QA pipeline overview — does NOT change.** It maps command-to-command
relationships, and this round changes no command's inputs, outputs, or position in the pipeline. This
is recorded as a decision so a later reader does not "helpfully" edit it into inconsistency.

**Mermaid under `docs/superpowers/**` is out of scope.** Those blocks live in plan and design
snapshots (**seven** files, canonical only — five under `plans/`, two under `specs/`) which convention
keeps as authored. This count was written as "six" on first drafting and corrected by deriving it; the
same discipline applies to every count a plan task carries.

### 10.3 Pre-existing drift, in scope

The README agent table already misstates two counts, independently of this round. Verified against the
agent files 2026-08-21:

| Row | README says | Actually today | After this round |
|---|---|---|---|
| `code-review` | 8 dimensions (all 3 editions) | **10** | 11 |
| `epic-reviewer` | 9 dimensions (canonical + mgd); **no count** (Copilot) | **18** | 19 |
| `doc-reviewer` | 17 dimensions (all 3 editions) | 17 ✓ | 18 |

The `code-review` row missed the two conditional dimensions added by the July harvest (ARD conformance,
spec/design conformance). The `epic-reviewer` row is stale by nine.

These are fixed in this round because we are editing those exact rows anyway, and because shipping a
round whose subject is "verify claims against the thing they describe" while leaving a false claim in
the row we just edited would be self-refuting. This is a deliberate, bounded scope extension — three
table rows — not licence to audit the whole README.

**Copilot's `epic-reviewer` row carries no number at all.** The correct fix there is to leave it
numberless or to add the *derived* count — never to copy canonical's, which is wrong. This asymmetry
is the reason §8 forbids `cp` into that edition.

### 10.4 Explicitly unchanged

Repo-root `README.md` in all three editions describes commands only and mentions no reviewer, fixer, or
dimension count (grep-verified 2026-08-21). No change expected; confirm rather than assume, since item
4 adds a reference file and some root READMEs index those.

## 11. Open questions

None. All six design decisions were settled in the 2026-08-21 brainstorm: round scope (Tier 1 only),
decomposition (one spec, three waves), the anti-anchoring mechanism (deferred file read), the claims
source (existing agent testimony), the verification station (orchestrator triage), and item 4's home
(new reference).

## 12. Backlog recorded, not dropped

`docs/superpowers/harvest/NEXT.md` is updated in Wave 3 to record what shipped and to carry items 5–7
forward as named, unaddressed backlog:

- **Item 5** — `references/bug-diagnosis.md` has drifted from its mattpocock source: no `## Redact`
  section, and no "name one command you have already run, and show its output" completion criterion.
- **Item 6** — "design it twice" for `/design` (three parallel sub-agents under different interface
  constraints, compared on depth/locality/seam placement), plus `DEEPENING.md`'s four dependency
  categories for `design-format.md`'s `## Seams`.
- **Item 7** — subagent-dispatch bounds for the three agents holding `Task` (`docs-style-checker`,
  `upgrade-executor`, `vuln-fixer`), and the Claude-only half: reviewers must return findings as text,
  never through a host findings-reporting tool.

Also recorded there, as decisions rather than gaps: superpowers has **reversed** the plan-conflict
rule this plugin imported from it in July (`review-fixer`'s `DEFERRED — plan-conflict`) in favour of
"rule and record"; that divergence is deliberate, since our commands run with a human present. And
mattpocock's `grilling` has moved fully to round-by-round frontier batching, which
`references/grilling-technique.md` continues to reject for the authoring commands.
