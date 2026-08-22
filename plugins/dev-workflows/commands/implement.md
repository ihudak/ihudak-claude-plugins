---
name: implement
description: End-to-end code implementation workflow. Classifies task risk, creates a branch, plans (Opus for SIGNIFICANT/HIGH-RISK), implements, writes tests, runs Opus code review, and performs post-session maintenance.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Implement the following: $ARGUMENTS

---

## Phase 0 — Load and classify inputs

`$ARGUMENTS` may contain free-text prose plus **zero or more `@path` tokens** (today's single-`@file` form is a subset). Resolve each `@path` relative to the current working directory. Classify each `@path` — and the current working directory — **by inspection, not by matching the path string**:

| Detected as | Recognition rule | Handling |
|---|---|---|
| **Spec file** | a single `.md` file | read fully; use as the description/spec |
| **Spec folder** | a directory containing `prompt.md` and/or a `*-design.md` | read all `.md` specs within; fold into the description |
| **Jira ticket folder** | a directory containing a `*-index.md`, or ticket-key subdirectories each containing a `KEY.md` | hand to `jira-reader` in Phase 1.7 |
| **Code repo** | a directory where `git -C <path> rev-parse --is-inside-work-tree` succeeds (includes the cwd) | scan target in Phase 1.7 |

**Jira-input resolution (shared front-end).** Before the per-`@path`
classification above, run `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`
against `$ARGUMENTS`. It unifies the input grammar with `/document`: a **JiraID**
token (`^[A-Z][A-Z0-9]+-[0-9]+`) is discovered under `$VAULT_PATH/jira-products/`
(Fallbacks A/B on miss); a directory that inspects as a **jira-export** is used as
`jira_export_root`; a **spec-folder** contributes to `specs`; everything else is
`direct` (free-text/`@file`, this command's existing flow). The classification
table above is the directory branch of that front-end — a Jira ticket folder ↔
jira-export, a spec folder ↔ spec-folder, a code repo ↔ an `/implement`-only
target. Carry `mode`, `jira_key`, `jira_export_root`, `focus_key`, and `specs` forward.

**Epic-unit resolution (jira-driven).** `/implement` implements one Epic at a time.
After the front-end resolves, when `mode: jira-driven`:

- **`focus_key` set** (explicit `<VI> <Epic>`, a bare nested `<Epic>`, or chosen in
  the picker below) → proceed for that Epic. The Jira read (Phase 1.7) and specs
  resolution both scope to it.
- **`focus_key` null** → classify the target with a cheap `jira-reader`
  `depth: vi-plus-epics` read on `jira_export_root`, then follow
  `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` §"Progress-aware Epic
  picker":
  - the item is **itself an Epic** (stand-alone / top-level) → no picker; proceed
    directly (`focus_key` stays null; specs resolve at the item's top-level dir).
  - **VI with exactly 1 Epic** → no picker; set `focus_key` to that Epic and proceed.
  - **VI with ≥2 Epics** → render the picker. `/implement`'s **done-predicate is the
    Epic's Jira status** (`linked_items[].status`): map *done / closed / resolved* →
    ● (greyed, not default-selectable; selecting offers "implement anyway"), *in
    progress / in review* → ◐, anything else → ○; always show the raw status text
    beside each row so a lagging status can't mislead. If the export carries no
    status, degrade to a plain unstatused selection list. Include the explicit choice
    **"Implement one broad VI-level slice instead"** (`focus_key` stays null → specs
    resolve VI-level). Selecting an Epic sets `focus_key` and proceeds for **that Epic
    only** — there is **no "Next Epic?" loop** (code-writing is heavy and branchy;
    each `/implement` run targets one Epic).
  - **VI with 0 Epics** → offer: split with `/dev-workflows:epics` first (then re-import), or
    implement one broad VI-level slice (`focus_key` stays null).

When the picker (or the 1-Epic auto-path) sets `focus_key` that was initially null,
**re-resolve `specs`** per the shared reference §Specs-resolution now that `focus_key`
is set — the front-end's first pass resolved `specs` with `focus_key` null, so it must
run again to pick up the Epic's nested per-Epic home.

Rules:
- The **primary description** is: the spec file if one was given → else the spec-folder design doc → else the inline prose. Echo `📄 Reading prompt from <file>…` (or `from inline text`) and confirm `"Loaded prompt (N lines)."`.
- **Design-doc open-question guard.** If the primary description is a **design doc** — a file named
  `design.md` or matching `*-design.md` (the `/design` output; distinct from a `specification.md`) —
  scan it for unresolved `- [ ]` open questions under its `## Open questions` heading. If any exist,
  **refuse to proceed**:
  `choices: ["Cancel — resolve the design's open questions in /dev-workflows:design first (Recommended)", "Override and implement anyway (logged in the Phase 5 report)", "Other… (describe)"]`
  A design must be decision-complete before implementation (enforced upstream by `design-reviewer`;
  this is the cross-command backstop). **`specification.md`-level open questions are exempt** — they are
  the spec's way of flagging what the design phase resolves, and a design doc may legitimately
  incorporate a spec that still carries them. "Override" is the only escape and is recorded in the
  Phase 5 report's `### Assumptions & limitations`.
- Multiple inputs of the same kind are allowed.
- A referenced `@dir` that is missing, or is neither a recognized folder type nor a git repo, MUST be surfaced to the user immediately (do not silently skip) — then ask whether to continue without it or stop. This mirrors `classification.md` §8.4.
- Note any embedded images as "referenced image: <path>".
- If a single `@file` cannot be read, stop and report the error immediately.
- **Specs are required for jira-driven runs.** When `mode: jira-driven` and the
  front-end resolved `specs: []`, do not plan blind — prompt:
  `choices: ["Point me at a specs directory (you'll provide the path)", "Proceed without specs — not recommended", "Cancel"]`
  "Point me…" takes a path, classifies it as a spec-folder, and re-resolves
  `specs`. "Proceed without specs" is logged in the Phase 5 report's
  `### Assumptions & limitations`. Direct-mode runs (no Jira input) are exempt —
  the prompt/spec file is the instruction.

**Specs-repo preflight.** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`specs-preflight` entry point (§3) inline: flush any leftover session
artifacts from an earlier run, retry an artifact commit that failed to push,
and settle the branch. This runs against `$SPECS_PATH` only — `git -C
"$SPECS_PATH"`, never a `cd`, so the code/docs repo this run is working
in is untouched (§1 rule 1). Prompt-free and silent when the specs repo
is clean and on its default branch. If a guard fires, emit its §5 notice;
if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole
run — the terminal `commit-artifacts` step skips on it.

**Gate the in-scope specs on `$SPECS_PATH`'s main.** This runs after the cheap `focus_key`-null `jira-reader` classification above — a deliberate, bounded exception to `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §5 rule 2's "before its first subagent dispatch", and structurally forced: this gate's `specs` set is derived from `focus_key`, which that dispatch resolves. The exception is bounded to that one read-only Epic-unit classification; every expensive step — the Phase 1.7 fan-out, `risk-planner`, and all writes — still follows the gate. (`/epics` records its own §5 rule 2 deviation the same way.) For each resolved `specs` path whose basename is `specification.md` or `design.md` — `/implement`'s **in-scope** spec/design files, the same set Phase 2B and the invariants section reference for the conformance dimension — execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against it, mapping its §3.7 return value by `stopped` first, never by `on_main` alone. Any stopping state → stop per §4.4, naming `$SPECS_PATH` explicitly — `/implement` stands in a **code** repo, so an unqualified stop message would point at the wrong repository. Otherwise (`stopped: false`): `pass`/`pass_amending` → proceed (on `pass_amending`, print §3.3's row-B message — reachable only when an **earlier** `/implement` run's Phase 4.5 handoff created the branch and `specs-repo-git.md` §3.5 B3 kept this run's preflight checkout on it — never this run's own Phase 4.5, which has not executed when this Phase 0 gate runs; `/implement` does not itself author `specification.md`/`design.md`, so a leftover `spec/`/`design/` branch left by an earlier `/specify`/`/design` run is never row B for this gate — it is row C/C′, and the stop/repair path above already covers it). `absent` → **only an in-scope spec is gated at all** — a direct-prompt run resolves none of these `specs` entries and is entirely unaffected, so do not stop; behave exactly as before this feature. `unmanaged` → behave exactly as before this feature. A spec/design supplied directly as a lone `@path` primary description — the Design-doc open-question guard's own input above, a separate mechanism from the `specs` list this gate reads — is **out-of-contract**: read where it sits, deliberately not gated here, the same rule this plan set for `/create-vi <KEY> @<path>`.

---

## Phase 0.5 — Readiness pre-flight (jira-driven only; advisory)

**Jira mode only.** When `mode: direct` this phase is a **no-op** — skip it entirely
(direct-mode runs are byte-identical to before).

When `mode: jira-driven`, read the resolved item's declared Jira status (reuse the
Phase 0 `vi-plus-epics` read if it ran, else a cheap Status-column read of
`<jira_export_root>/<jira_key>-index.md`). Also, if `$SPECS_PATH` is set, check for a
co-located `_readiness.md` in the item's specs dir.

Surface a **one-line, non-blocking** recommendation to run `/dev-workflows:ready <VI> [<Epic>]` first when
EITHER: the status is below the readiness bar (VI below **Ready for Implementation**; Epic below
**Refined**), OR a `_readiness.md` records **NOT-SUPPORTED** / **PARTIAL**. This NEVER blocks —
proceed regardless; it is guidance only. If neither condition holds, say nothing and continue.

---

## Phase 1 — Clarification

**Rule: Ask, don't guess. This rule is absolute.**

Before producing a plan, analyze the description for:
- Ambiguous scope or unclear boundaries
- Missing constraints (performance, security, backwards-compatibility)
- Multiple valid implementation approaches
- Undefined integration points or dependencies
- Missing acceptance criteria

If **any** ambiguity exists, ask the user. Rules:
- Use `choices` arrays for every question — never plain text questions
- The **last choice** in every `choices` array MUST be `"Other… (describe)"` to allow free-text
- When a clearly superior default exists, make it the first choice and label it `"(Recommended)"`
- Group related decisions into a single question (minimize total questions)
- Do **not** proceed until all questions are answered

If **nothing** is ambiguous, skip directly to Phase 1.5.

---

## Phase 1.5 — Classify task complexity

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load the classification rules, then classify the task as exactly one of:

- **SIMPLE** — local, trivial, clearly reversible; no mandatory Opus steps
- **MODERATE** — bounded scope, few files, clear requirements; no mandatory Opus steps
- **SIGNIFICANT** — risky in at least one dimension from the classification reference; Opus planning + Opus review are mandatory
- **HIGH-RISK** — multiple risky dimensions, or security/migration/compliance scope; Opus planning + Opus review are mandatory and must be especially thorough

State the classification and the specific criterion that triggered it. When in doubt between MODERATE and SIGNIFICANT, pick SIGNIFICANT.

**Resolve the per-step routing.** Following `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9, record a `model_routing` block resolving each model against the fallback chains:

```yaml
model_routing:
  classification: <SIMPLE | MODERATE | SIGNIFICANT | HIGH-RISK>
  reason: <one-line>
  current_model: <the model this orchestrator is running under>   # = the inline implementation coding
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # jira-reader, code-scanner, Phase 2A exploration, test-writer, test-baseliner, review-fixer
  planning_model: <§2 Opus chain>   # risk-planner (Phase 2B; SIGNIFICANT/HIGH-RISK only; frontmatter-pinned, recorded, no override)
  review_model:  <§2 Opus chain>    # code-review (Phase 3B; frontmatter-pinned, recorded, no override)
  implementation_model: <= current_model>   # coding done inline by the orchestrator
  fixes_model: <= detection_model>          # review-fixer (Phase 3B)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2 / §2.1 fallback or degradation>
```

Each subagent dispatch below cites its chain (§9 role→chain map); mechanical steps pin `detection_model` via `model:`, and the frontmatter-Opus gates (`risk-planner`, `code-review`) are recorded but never overridden.

**Detect task shape.** Inspect the description for defect signals (fix / bug / regression / broken / incorrect / wrong output / crash / fails). If bug-shaped, set `task_shape: bug`. `task_shape: bug` only affects the SIGNIFICANT / HIGH-RISK path (Phase 2B/3B); for SIMPLE / MODERATE it is guidance only (no extra question). On the SIGNIFICANT / HIGH-RISK path, if it is genuinely ambiguous whether this is a defect fix or new work, ask with a `choices` prompt (last choice `"Other… (describe)"`).

Then choose the branch:

- **SIMPLE / MODERATE** → continue to Phase 2A (standard planning)
- **SIGNIFICANT / HIGH-RISK** → continue to Phase 2B (Opus-planned)

---

## Phase 1.6 — Input scale assessment

From the Phase 0 classification, compute:
- `repo_count` = number of code repos (cwd + referenced git-repo dirs)
- `has_ticket_folder` = any Jira ticket folder present
- `has_spec_folder` = any spec/design folder present

Set `fan_out = (repo_count > 1) OR has_ticket_folder OR has_spec_folder`.

- **`fan_out = true`** → the input is multi-source. Per `classification.md` §1.1 (the multi-source trigger; see §8 for the fan-out policy) this floors the classification at **SIGNIFICANT** (raise it now if Phase 1.5 chose SIMPLE/MODERATE). Announce: `"Multi-source input detected (<facts>) — flooring at SIGNIFICANT; this is overridable at plan approval."` Then run **Phase 1.7** (fan-out scan) and continue on the SIGNIFICANT/HIGH-RISK branch (Phase 2B).
- **`fan_out = false`** → unchanged behavior; skip Phase 1.7 and proceed to Phase 2A or 2B exactly as the Phase 1.5 classification directs (the single-explorer path).

---

## Phase 1.7 — Multi-source exploration (only when `fan_out = true`)

Runs after Phase 1.6 and replaces the single Phase 2B exploration subagent for multi-source input. Follows `classification.md` §8.

1. **Read Jira ticket folders.** For each Jira ticket folder, invoke `jira-reader` (read-only):

   → Agent (subagent_type: "dev-workflows:jira-reader", model: `<detection_model — §2.1 Sonnet chain>`):
     > "Return the structured handoff for this brief — linked items, PR URLs (identifiers only — no fetching), and capability themes:
     >
     > jira_export_root: [the resolved jira_export_root (from the Phase 0 front-end), or the ticket-folder absolute path]
     > jira_key:         [the resolved <KEY>]
     > depth:            full"

   Run multiple `jira-reader` calls sequentially (it is fast and read-only). Collect the themes and PR references.

   When `focus_key` is set, scope the collected result to the focus Epic's subtree:
   keep the focus Epic plus the items linked beneath it (its Stories / Sub-tasks) and
   drop sibling Epics' subtrees before folding themes/PRs into the plan. `jira-reader`
   itself is not modified — the scoping is done here, mirroring `/specify`.

2. **Read spec/design folders inline.** Read each spec-folder `.md` and fold its content into the themes and primary description.

3. **Fan out `code-scanner` — one per repo, single response, cap 4 concurrent.** Spawn all repo scanners in **one** message (batch in groups of 4 if there are more than 4 repos). For each code repo:

   → Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §2.1 Sonnet chain>`):
     > "repo_path: <absolute repo path>
     >  capability_themes: <themes from steps 1–2 + the implementation spec>
     >  context: <3–5 sentences: the implementation goal and what the change must accomplish>
     >  search_hints: <symbols/paths/keywords derived from the spec, if any>"

   Wait for all scanners in the batch to return. A scanner returning `REPO_MISSING` — the path is not a directory — escalates per the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`; `DIRTY_TREE` escalates per the `Dirty working tree` rule and `REFRESH_BLOCKED` per the `Refresh blocked` rule in the same file. None is ever hidden, and none is merely announced — each offers the user a way forward (§8.4). A scanner returning `prep.read_only: true` is not a failure — it scanned at `prep.scanned_ref`; escalate per the `Read-only mount — ref stale or diverged` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` only when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`, and cite evidence at `prep.scanned_ref`.

   **Round 2 — narrow and seeded (§8.5).** Apply `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §8.5. A theme is **inconclusive** when its round-1 `classification` is `partial`, `absent`, or `error`, or when **two or more** scanners' per-theme `capability_map[].gap_summary` texts point at each other's repo in a cycle, or at a component/subsystem that no scanned repo covers — the shape that yields confident answers which together say nothing. For every inconclusive theme that round 1 left at least one evidence anchor for, dispatch `code-scanner` again on `detection_model` with `capability_themes` holding exactly **one** question — the single thing round 1 failed to settle, not the broad theme — and `search_hints.paths`/`.symbols`/`.keywords` seeded from that round's verified `evidence[].path` and `.symbols`; where an evidence entry carries `lines`, name the anchor as `<path>:<line>` in the `context` prose. Cap **4 dispatches, one round only** — there is no round 3. This matters more here than where §8.5 was first adopted: `/idea`'s summary feeds a grill with a human in it, while this one feeds a planner whose output becomes code. **A theme round 1 left with no evidence anchor never enters round 2** — it stays inconclusive with no round-2 attempt possible, and that absence of an attempt is not itself a resolution.

4. **Synthesize.** Combine the `jira-reader` output, all `code-scanner` reports, and the spec into a single **multi-source codebase summary** (per-repo: relevant files, existing capabilities, gaps; plus the cross-repo picture and the Jira themes/PR references). This summary is the codebase context for Phase 2B — do **not** also run the single Explore subagent. Write this summary to a temp file (`mktemp -t dw-impl-summary-XXXX.md` — **never inside a repo working tree**, so a captured `git diff` never picks it up) and record its absolute path as `summary_file`; Phase 2B receives this path, not the pasted summary.

   **Name what the scan did not settle.** The summary carries a `## Unresolved` section listing **every theme still inconclusive at the end of Phase 1.7** — this explicitly includes a theme that never entered round 2 because round 1 left no anchor to seed from, a theme classified `error`, and a mutual-deferral theme, whether or not either scanner logged an anchor. None of these becomes resolved merely by having had no round-2 attempt. Per `classification.md` §8.5 Bounds, name **why** each theme is unresolved — mutual deferral / scan error / partial-or-absent with no anchor — and give the repos-and-conclusions detail only where scanners actually disagreed. An inconclusive theme is **never** folded in as an ordinary gap: a gap asserts the capability is absent with no deferral outside the scanned set, an unresolved theme asserts only that the scan could not tell, and once flattened the two are indistinguishable to the planner. Omit the section entirely when nothing is unresolved.

---

## Phase 1.8 — Resolve applicable ARD (Jira mode; optional)

Only when the run resolved a Jira key (VI/Epic) — i.e. NOT direct-prompt mode — resolve any ARD by citing `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with the resolved `<VI>`, `<EPIC>`, and `$SPECS_PATH`. Direct mode (no Jira key) → treat as `status: none`. On `status: none`, **skip and proceed exactly as before**. On `status: unmerged`, **stop**, naming the returned `branch` and any `pr` and naming `$SPECS_PATH` explicitly (`/implement` stands in a code repo, not the specs repo, so an unqualified message would point at the wrong one) — per `ard-resolution.md`'s Output section, this state is unreachable when no ARD resolves. On `status: found`, carry the `invariants` as **implementation guardrails** (the implementer honors each `AD#N` `rule`; a necessary deviation is logged as an `- ARD deviation:` line in the Phase 5 report), and — in the SIGNIFICANT / HIGH-RISK path — pass them to `code-review` (Phase 3B) as `applicable_ard`. In the SIMPLE / MODERATE path there is no `code-review` gate, so the guardrails act as guidance only.

---

## Phase 2A — Standard Plan (SIMPLE / MODERATE only)

**Codebase exploration** — Before writing the plan, spawn an exploration subagent to map the relevant parts of the codebase:

→ Agent (subagent_type: "general-purpose", tools: Read/Glob/Grep only — no Bash, no Edit, model: `<detection_model — §2.1 Sonnet chain>`):
  "Given this implementation description: [paste the full implementation description from Phase 0 or Phase 1 here], find and return:
   - Relevant source files and their primary responsibility
   - Existing patterns and conventions used in this codebase
   - Test file locations and test naming conventions
   - Naming conventions (class names, method names, file names)
   Return a structured summary — no code changes, no file edits."

**Wait for the agent's response before proceeding. If the agent returns no relevant files or fails, proceed with the plan using your own file reads to gather context. Do not begin writing the plan until the file map is returned or you have gathered context yourself.**

→ Use the returned file map as codebase context when writing the plan below.

Produce a written implementation plan:

1. **Classification** — `SIMPLE` or `MODERATE` (with reason)
2. **Goal** — one-sentence summary of what will be built
3. **Approach** — chosen strategy and why
4. **Steps** — numbered, concrete implementation steps
5. **Files to create/modify** — list with brief rationale
6. **Tests** — what tests will be added or run
7. **Assumptions** — decisions made without user input (must be minimal)
8. **Out of scope** — explicitly list what is NOT being done

Then ask:
```
"Implementation plan ready. What would you like to do?"
choices: ["Approve & implement now (Recommended)", "Revise plan", "Cancel"]
```

- **Approve** → write the approved plan to a temp file (`mktemp -t dw-impl-plan-XXXX.md`, never inside a repo tree) and record its absolute path as `plan_file`; proceed to Phase 3A
- **Revise** → ask what to change, update, re-show, re-ask
- **Cancel** → stop and summarize what was planned

---

## Phase 2B — Opus-planned (SIGNIFICANT / HIGH-RISK)

**Codebase exploration** — If Phase 1.7 ran (`fan_out = true`), use its **multi-source codebase summary** (already written to `summary_file` in Phase 1.7 step 4) as the codebase context and skip the single Explore subagent. Otherwise, run the same exploration subagent call as Phase 2A (same prompt, same fallback rule), then write the Explore agent's returned output to a temp file (`mktemp -t dw-impl-summary-XXXX.md`, never inside a repo tree) recorded as `summary_file`. Either way, `summary_file` holds an absolute path before the planner is dispatched.

Once the file map is returned, delegate planning to Opus.

When a `specification.md`/`design.md` is in scope, extract its **in-scope** `[Uxx]`/`[ACxx]`/`[TCxx]` IDs (reuse the specs resolved in Phase 0) into `in_scope_ids` for the review dispatch below. When `task_shape: bug`, the plan will lead with a repro step and a ranked-hypotheses section — surface them in the normal plan-approval gate (no extra interrupt) **when the ranking is present**. When the planner instead returns `Ranking withheld — no red-capable repro`, the withheld-repro branch below fires first and the normal gate does not run.

→ Agent (subagent_type: "dev-workflows:risk-planner"):  # planning_model — §2 Opus chain; frontmatter-pinned, recorded in model_routing, no override added
  > "Produce the risk-weighted plan for the following brief:
  >
  > Task description: [substitute full description]
  > Classification: [SIGNIFICANT | HIGH-RISK] — reason: [the criterion from Phase 1.5, or the multi-source floor from Phase 1.6 when fan_out]
  > Codebase summary: read it from the file at [the `summary_file` absolute path]
  > Constraints: [any from clarification, plus runtime/version/deadline known]
  > Current state: branch = [git branch], uncommitted = [git status --short summary]
  > Specs in scope: [the resolved specification.md/design.md path(s) from Phase 0, or "none"]
  > Unresolved scan themes: [the summary's `## Unresolved` entries, or "none"] — each is a theme the scan could not settle, NOT a confirmed gap; carry every one into the plan's risks and never plan as though its location is known
  > task_shape: [bug | omit]"

**Wait for the risk-planner to return.** Its output is one of:

1. A full plan in the risk-weighted format (the normal case).
2. A short `### Re-classification` section, if the planner decided on inspection that the task is actually `SIMPLE` or `MODERATE`.

**If the return contains `### Re-classification`:** surface it to the user, ask for confirmation of the revised level with a `choices` prompt (`["Accept revised classification (Recommended)", "Override and stay SIGNIFICANT/HIGH-RISK", "Cancel"]`). If the user accepts, **fall back to Phase 2A** (standard plan) using the codebase context already captured above (the `summary_file` path) — the Phase 1.7 **multi-source codebase summary** when `fan_out = true`, otherwise the Explore summary — and do not re-run exploration. Accepting here is the user exercising the **plan-approval override** of the multi-source SIGNIFICANT floor (Phase 1.6); that is the sanctioned way to leave the fan_out floor. If the user overrides, re-invoke risk-planner with an additional constraint stating the classification is intentional; do not down-classify again. If the user cancels, stop and summarize.

**If the return is a full plan whose `### Hypotheses (ranked)` section contains `Ranking withheld`:**
the planner could not get a red-capable repro, so its hypotheses are absent by design and the rest of
the plan rests on unverified theory. Do NOT fall through to the normal approval gate — its Recommended
option is "Approve & implement now", which is exactly the proceed-on-a-guess outcome
`${CLAUDE_PLUGIN_ROOT}/references/bug-diagnosis.md` step 1 forbids. Surface the planner's `Tried:` line
verbatim and ask:

```
choices: ["Help construct a repro (you'll be prompted for what to try)", "Proceed without a repro (recorded in the Phase 5 report)", "Cancel"]
```

- **Help construct a repro** → take the user's suggestion, re-dispatch `risk-planner` with it carried in the brief, and re-enter this branch on the new return.
- **Proceed without a repro** → record it in the Phase 5 report's `### Assumptions & limitations` as `No repro: <what the planner tried>` and continue to the normal full-plan gate below.
- **Cancel** → stop.

**If the return is a full plan** (ranking present, or the user chose to proceed without a repro)**:** present it to the user verbatim and ask:

```
"Opus-planned. What would you like to do?"
choices: ["Approve & implement now (Recommended)", "Revise plan", "Cancel"]
```

- **Approve** → write the approved plan to a temp file (`mktemp -t dw-impl-plan-XXXX.md`, never inside a repo tree) and record its absolute path as `plan_file`; proceed to Phase 3B
- **Revise** → ask what to change, then re-invoke risk-planner with the **complete** brief plus the additional constraint merged in (never send just a delta — the planner refuses to plan without a full brief). Re-show, re-ask.
- **Cancel** → stop and summarize

---

## Pre-Phase 3 — Create feature branch

Before writing any file:

1. **Clean-tree check** — Run `git status --porcelain`. If the output is non-empty:
   - Show the user what is dirty (paste the `git status --short` output).
   - Ask:
     ```
     choices: ["Stash changes and continue (Recommended)", "Proceed anyway — pre-existing changes will appear in the diff and review outputs", "Cancel"]
     ```
   - **Stash**: run `git stash push -m "pre-impl stash"`, then continue.
   - **Proceed**: note in the Phase 5 report that the working tree was dirty at implementation start.
   - **Cancel**: stop and summarize what was planned.

2. **Resolve the branch name** per `${CLAUDE_PLUGIN_ROOT}/references/branch-naming.md` — **the repo's own documented convention wins**. Read the target repo's `CONTRIBUTING.md`, `CONTRIBUTION.md`, `README.md`, `DOCUMENTATION-GUIDELINES.md`, `CLAUDE.md` (+ `.claude/`) for a branch-naming section (§1.1); if one is found, classify its segments (§1.2) and fill them: an **identity** placeholder (`<your-name-or-initials>`, `<user>`, …) from the §2 ladder (`$GIT_USER_INITIALS` → `git config user.initials` → inference from existing branches → the §2.5 prompt), an **issue-key** segment from the `jira_key` resolved in Phase 0 (or the pattern's documented no-issue literal in direct mode), and the **description** segment from step 3's slug. A pattern with no identity segment gets none — never inject initials into a convention that does not ask for one. Only when the repo documents no convention (§1.4) build `<prefix>/<slug>` with `<prefix>` from the §2 ladder, whose fallback here is `feat/`.

3. **Generate slug** — derive from the implementation description: lowercase, hyphens, max 40 chars, strip punctuation and special chars. Example: "Add user authentication to login page" → `add-user-authentication-login-page`. When a `jira_key` is resolved and the chosen shape has no separate issue-key segment, prefix it: `<jira_key>-<slug>`.

4. **Check HEAD context** — if HEAD is NOT on the default branch (`main` / `master` / `develop`), check for ahead commits: `git log origin/HEAD..HEAD --oneline 2>/dev/null`. If output is non-empty (branch has commits ahead), ask:
   ```
   choices: ["Branch from current position — continue on this work (Recommended)", "Branch from default branch — fresh start", "Cancel"]
   ```

5. **Create and checkout** — `git checkout -b <prefix>/<slug>`. If that name already exists, append the first 7 chars of HEAD's SHA: `<prefix>/<slug>-<short-sha>`.

---

## Pre-Phase 3.5 — Capture test baseline

Placed **after** branch creation (Pre-Phase 3), **before** any file edits. The `.5` numbering signals "inserted between step 3 and step 4 of the existing ordering" — it is its own phase, not a sub-step of Pre-Phase 3's branch-creation steps.

Invoke the `test-baseliner` agent in capture mode:

→ Agent (subagent_type: "dev-workflows:test-baseliner", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Run the agent in the following mode:
  >
  > Mode: capture
  > Project root: [absolute path of the current working directory]"

Store the returned `## Test Baseline` block verbatim — it will be passed to `test-baseliner` again in verify mode at Phase 3.5 and to `test-writer` as the baseline snapshot. If `Framework: not detected`, note it in session memory but continue — Phase 3.5 will surface the missing-framework case to the user explicitly.

---

## Phase 3A — Implementation (SIMPLE / MODERATE)

**Implement immediately. Do NOT ask "Should I implement?" or any variation.**

1. Work through each step in order
2. Make precise, surgical changes — do not modify unrelated code
3. Follow existing code style and LF line endings
4. Assume broad permissions; avoid unnecessary stops
5. If a **new ambiguity** emerges mid-implementation: STOP, ask with choices (last: `"Other… (describe)"`), resume after answer
6. **Run Phase 3.5 below** (test writing + regression verification) — do NOT run tests directly here; Phase 3.5 owns the lint/build/test sequence and the fix loop
7. Verify the outcome matches the approved plan
8. Proceed to Phase 4 (post-implementation maintenance).

---

## Phase 3.5 — Write and verify tests (SIMPLE / MODERATE)

Runs after Phase 3A step 5 completes (all code changes written), before the outcome-verification step.

1. **Invoke `test-writer` agent.** First, at the orchestrator, capture the diff for the dispatch: write `git add -N . && git diff` (so new files are included) to a temp file (`mktemp -t dw-impl-diff-XXXX.patch`, never inside a repo tree) and record its absolute path as `test_diff_file`. `test-writer` has no shell tool — it can only `Read` the path it is given. Then spawn:

   → Agent (subagent_type: "dev-workflows:test-writer", model: `<detection_model — §2.1 Sonnet chain>`):
     > "Write tests for this brief:
     >
     > Task description: [substitute full description]
     > Plan: read it from the file at [the `plan_file` path recorded at Phase 2A approval]
     > Diff: read it from the file at [the `test_diff_file` path]
     > Project root: [absolute path]
     > Baseline: [paste the ## Test Baseline block captured in Pre-Phase 3.5]"

2. **Handle a `test-writer` stop.** Check the report's first line before anything else. If it is `Diff: unreadable at <path>`, the orchestrator's own `test_diff_file` could not be read — this is an orchestrator bug, not a user choice: surface the unreadable path to the user and **stop the run**; do not run the framework prompt below, and do not offer to skip tests (skipping would silently proceed past evidence that could not be read). Otherwise, if the report shows `Framework: not detected`, ask the user:
   ```
   choices: ["Specify test command to use", "Skip tests for this run (document why in the final report — Phase 5 of the inherited /implement workflow)", "Cancel"]
   ```
   - **Specify test command** → take free-text, use it as the test runner for step 4 below; continue.
   - **Skip tests** → take free-text rationale; record it in the Phase 5 `### Deferred items` section; skip steps 3–5 of Phase 3.5 and proceed to Phase 3A step 7 (Verify outcome).
   - **Cancel** → stop and summarize.

3. **Run linters and builds.** Use the project's standard lint/build commands as discovered in Phase 2A exploration. Do not run the full test suite here — that is step 4.

4. **Invoke `test-baseliner` in verify mode** against the baseline captured in Pre-Phase 3.5:

   → Agent (subagent_type: "dev-workflows:test-baseliner", model: `<detection_model — §2.1 Sonnet chain>`):
     > "Run the agent in the following mode:
     >
     > Mode: verify
     > Baseline: [paste the captured ## Test Baseline block]
     > Project root: [absolute path]"

5. **Fix loop** — if the verify report lists regressions or new failures:
   - The **session model** (not a subagent) applies fixes. No `review-fixer`-style indirection is used here — the scope is narrow and the context is already fully in-session. Use the `test-baseliner` verify report as the authoritative list of what broke.
   - After each fix attempt, re-capture the diff (`git add -N . && git diff`) and re-run `test-baseliner` in verify mode against the **original** baseline (never re-baseline mid-loop — a mid-loop re-baseline would silently absorb a regression as the new normal).
   - Cap at **2 fix attempts**. If regressions remain after the second attempt, surface to the user:
     ```
     choices: ["Investigate further", "Accept regressions and proceed (document in Phase 5 report)", "Cancel"]
     ```
     - **Investigate further** → stop the automated loop; the session model diagnoses manually and re-runs verify when ready.
     - **Accept regressions** → record each regression in the Phase 5 `### Deferred items` section with the user's rationale; proceed.
     - **Cancel** → stop and summarize.

Once Phase 3.5 returns (passed, skipped, or accepted-with-regressions), return to Phase 3A step 7 (Verify outcome).

---

## Phase 3B — Implementation + Opus review (SIGNIFICANT / HIGH-RISK)

Use the currently selected model or Sonnet for implementation itself. Opus is reserved for the review.

For a long step list, apply `${CLAUDE_PLUGIN_ROOT}/references/context-management.md` — checkpoint at N,
offload parallel-safe (`[P]`) steps to subagents, or decompose — so the run does not degrade as context fills.

At each checkpoint, also consider suggesting **`/compact`** to free context before the next scope/Epic (per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §3 — mid-command → `/compact` only, never `/clear`; guidance only).

1. Work through each step in order
2. Make precise, surgical changes — do not modify unrelated code
3. Follow existing code style and LF line endings
4. If a **new ambiguity** emerges mid-implementation: STOP, ask with choices (last: `"Other… (describe)"`), resume after answer
4a. **Invoke `test-writer` agent** (inserted before the review diff capture in step 5 so the Opus review sees code and tests together — test adequacy is already a review dimension in `code-review.md`). First, at the orchestrator, capture the diff for the dispatch: write `git add -N . && git diff` (so new files are included) to a temp file (`mktemp -t dw-impl-diff-XXXX.patch`, never inside a repo tree) and record its absolute path as `test_diff_file`. `test-writer` has no shell tool — it can only `Read` the path it is given. Then spawn:

   → Agent (subagent_type: "dev-workflows:test-writer", model: `<detection_model — §2.1 Sonnet chain>`):
     > "Write tests for this brief:
     >
     > Task description: [substitute full description]
     > Plan: read it from the file at [the `plan_file` path]
     > Diff: read it from the file at [the `test_diff_file` path]
     > Project root: [absolute path]
     > Baseline: [paste the ## Test Baseline block captured in Pre-Phase 3.5]"

   Check the `test-writer` report's first line before invoking Opus review. If it is `Diff: unreadable at <path>`, the orchestrator's own `test_diff_file` could not be read — this is an orchestrator bug, not a user choice: surface the unreadable path to the user and **stop the run**; do not invoke Opus review and do not run the framework prompt below. Otherwise, if the report shows `Framework: not detected`, ask the user **before** invoking Opus review (mirrors the SIMPLE/MODERATE branch — keeps the Opus-review input deterministic):
   ```
   choices: ["Specify test command to use", "Skip tests for this run (document why in the final report — Phase 5 of the inherited /implement workflow)", "Cancel"]
   ```
   Record the choice. A "Skip" decision must be explicit and logged in the Phase 5 report.

5. After all changes are written: **DO NOT run tests yet.** When `task_shape: bug`, first **strip every `[DEBUG-xxxx]` probe** added during diagnosis (per `${CLAUDE_PLUGIN_ROOT}/references/bug-diagnosis.md`); the review diff must contain no debug instrumentation. Capture the diff and the project root. Use `git add -N . && git diff` — this includes intent-to-add untracked new files so the diff is never empty for implementations that only create new files, and it now also includes the test files from step 4a. Write this diff to a temp file (`mktemp -t dw-impl-diff-XXXX.patch`, never inside a repo tree) and record its absolute path as `review_diff_file`; the code-review dispatch (step 6) receives this path. Also capture `git diff --stat` for the summary (small — kept inline).
6. **Opus code review** — spawn.

   → Agent (subagent_type: "dev-workflows:code-review"):  # review_model — §2 Opus chain; frontmatter-pinned, recorded in model_routing, no override added
     > "Produce the Opus code review for this brief:
     >
     > Task description: [substitute full description]
     > Classification: [SIGNIFICANT | HIGH-RISK] — reason: [from Phase 1.5]
     > Plan: read it from the file at [the `plan_file` path]
     > Diff: read it from the file at [the `review_diff_file` path from step 5]
     > Project root: [absolute path]
     > applicable_ard: [the ARD invariants from Phase 1.8, or omit if none / direct mode]
     > applicable_spec: [ { spec_paths: [...], in_scope_ids: [...] } when a spec/design is in scope, else omit ]
     > claims_file: [the `claims_file` path — pass it only when a `review-fixer` Fix Report exists for this run; omit otherwise]"

7. Act on the return:
   - **`### Re-classification` section** — the reviewer decided the change is actually `SIMPLE` or `MODERATE` on inspection. Surface it to the user and ask `choices: ["Accept revised classification (Recommended)", "Override and keep the BLOCK-gated review", "Cancel"]`. If accepted, treat the review as an implicit PASS: skip the BLOCK branch, proceed to step 8, and do NOT re-invoke the reviewer on later fix deltas. Record the revised classification for the Phase 5 report. If overridden, re-invoke code-review with an explicit note that the classification is intentional.
   - **BLOCK** — invoke the review-fixer agent (see Review-fixer sub-step below). If `Stop condition flag` is `CLEAR`, re-run the Opus code review on the updated diff (one re-review only). If `Stop condition flag` is `NEEDS HUMAN`, do not re-review: surface the deferred BLOCKER(s) to the user with the reason `review-fixer` gave and stop. If the second verdict is still BLOCK, stop: surface the remaining blockers to the user and ask `choices: ["Investigate further", "Abandon implementation and restore to pre-impl state", "Cancel"]`. Do not run tests until the verdict is not BLOCK.
   - **PASS WITH RECOMMENDATIONS** — invoke the review-fixer agent for MAJOR findings (see Review-fixer sub-step below). MINOR / NIT findings may be deferred — note them in the Phase 5 report.
   - **PASS** — proceed.

   **Triage sub-step** (before any fixer dispatch): follow `${CLAUDE_PLUGIN_ROOT}/references/finding-triage.md`. For each finding, verify its claimed consequence at the location it names; keep or dismiss; record every dismissal with a reason that disposes of that finding's own claim. Hand the fixer **survivors only**, and carry the dismissal list into this run's report.

   **Review-fixer sub-step** (for BLOCK and PASS WITH RECOMMENDATIONS): first write the **triaged survivor list** from the sub-step above — the surviving findings only, each with its severity, location, observation, and suggestion — to a temp file (`mktemp -t dw-impl-review-XXXX.md`, never inside a repo tree) and record its path as `review_file`. Dismissed findings NEVER enter that file; they go to the `### Review triage` report section instead.

   → Agent (subagent_type: "dev-workflows:review-fixer", model: `<fixes_model — = detection_model, §2.1 Sonnet chain>`):
     > "Fix the review findings for this brief:
     >
     > Task description: [substitute full description]
     > Review output: read it from the file at [the `review_file` path]
     > Project root: [absolute path]
     > Severities to fix: BLOCKER and MAJOR"

   Wait for the fix report. Re-capture the diff after the fixer completes, **overwriting `review_diff_file`** (write a fresh `git add -N . && git diff` to that same path) — so the one re-review at step 7 reads the post-fix diff, not the stale step-5 capture. Also write the fixer's full Fix Report to a temp file (`mktemp -t dw-impl-claims-XXXX.md`, never inside a repo tree) and record its path as `claims_file` — the one re-review reads it as the deferred claims input, so the reviewer checks the fixer's account of its own work instead of assuming it.

   - If the fix report contains any `DEFERRED — plan-conflict` finding, surface it to the user **immediately** (do not wait for the BLOCK-still-BLOCK path): show the finding beside the plan text it contradicts and ask `choices: ["Revise the plan (the finding governs)", "Apply the fix against the plan (the plan governs — logged in Phase 5)", "Other… (describe)"]`. Act on the answer before re-running the review.

7.5. **Spec/design conformance escalation.** For each unresolved `missing`/`contradicts` in-scope requirement from the code-review Spec/design-conformance dimension, write a `- [ ]` note back onto the source `specification.md`/`design.md` under an `## Engineering review` heading (the same escalation `/design` uses; annotate only — never mutate existing `[Uxx]`/`[ACxx]`/`[TCxx]` IDs). Never silently drop them, never invent new Jira work. Record which of `specification.md`/`design.md` actually received a note — the handoff step needs to know whether only one, or both, were annotated. The notes are written here and handed off later — see the escalation handoff after Phase 4.
8. **Run Phase 3.5 (post-review).** After the review gate clears (non-BLOCK verdict), run the Phase 3.5 sequence (lint/build, `test-baseliner` verify, fix loop) — **not before**. This preserves the invariant "NEVER run tests for SIGNIFICANT / HIGH-RISK before Opus review returns non-BLOCK". The fix loop inside Phase 3.5 applies fixes via the session model; if the fixes are non-trivial **and** the reviewer was NOT down-classified in step 7, re-invoke the Opus code review on the delta after Phase 3.5 completes (first overwrite `review_diff_file` with a fresh `git add -N . && git diff` so the re-review reads the post-Phase-3.5 diff). If the reviewer WAS down-classified, skip the re-review.
9. Verify the outcome matches the approved plan and the review verdict.
10. Proceed to Phase 4.

---

## Phase 4 — Post-implementation maintenance (both branches)

First gather the actual change context:

a. Run `git diff --stat` (or equivalent) and capture the list of changed files with line counts.
b. Compose a **change summary block**:

```
Implementation: [one-sentence description of what was built]
Change type: code
Classification: [SIMPLE | MODERATE | SIGNIFICANT | HIGH-RISK]
Files changed (from git diff --stat):
<paste the git diff --stat output>
Notable additions/removals: [new commands, APIs, config keys, dependencies — one line each; or "none"]
Opus review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK — or "N/A (SIMPLE / MODERATE)"]
```

Then spawn all four agents. They are independent and can run in any order — spawn them all before waiting for any to complete:

**Agent 1 — Documentation** (general-purpose):
> "Post-implementation documentation review. Change summary:
> [paste change summary block]
>
> Scan for README.md, CHANGELOG.md, docs/, or any .md files in the project root or a docs/ directory.
> Determine if documentation needs updating:
> - Skip if: purely a bug fix, vulnerability fix, internal refactor, or test-only change
> - Update if: new feature, changed behavior, new commands/APIs/config options, altered usage patterns
> Use the file list above to reason precisely about what changed. If an update is warranted: apply minimal edits to the relevant section(s).
> Return: file updated and what changed, OR 'no update required (reason)'."

**Agent 2 — Knowledge base** (general-purpose):
> "Post-implementation knowledge review. Change summary:
> [paste change summary block]
>
> Check ~/.claude/memory/ (global) and .claude/memory/ (project-level, preferred for repo-specific knowledge) for existing knowledge files.
> Determine if a new knowledge entry is warranted — look for: reusable insights or patterns, non-obvious constraints or gotchas, anti-patterns discovered, clarified trade-offs.
> If YES: append to the most appropriate existing file (never create a new file if an existing one fits) using this format:
> ### [Short title]
> - **Context**: what problem/situation triggered this
> - **Insight**: the learned rule, pattern, or gotcha
> - **When it applies**: conditions under which this matters
> - **Date**: YYYY-MM-DD
> - **Ref**: [first 60 chars of implementation description]
> Return: file updated/created and summary of entry, OR 'no update required'."

**Agent 3 — Instructions** (general-purpose):
> "Post-implementation instructions review. Change summary:
> [paste change summary block]
>
> Check CLAUDE.md in the project root and ~/.claude/CLAUDE.md (global).
> Determine if any rules, guidance, or guardrails are missing because of what this implementation revealed.
> Skip if: the implementation followed existing patterns with no surprises, required no novel constraints, and introduced no anti-patterns. Only update if a concrete, recurring rule would have prevented a decision point or misunderstanding during this implementation.
> If YES: apply minimal, additive, scoped changes only — do not rewrite sections wholesale.
> Return: what was changed and why, OR 'no update required'."

**Agent 4 — Session maintenance** (dev-workflows:impl-maintenance):
> "Analyse this session and return a Lessons Learned report.
>
> Session handoff:
> - Command run: /implement
> - What was done: [one-paragraph summary of the implementation]
> - Key events: [BLOCK reviews encountered and their reason, test regressions, workarounds, unexpected ambiguities — or 'none']
> - Workarounds used: [manual steps not automated by the workflow — or 'none']
> - Review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK | N/A]
> - Test result: [passed N tests, N regressions, not run — or actual result]
> - Project root: [absolute path]"

Collect all four summaries for the Phase 5 report.

**Persist plugin feedback (automatic).** After Agent 4 (`impl-maintenance`)
returns, project its plugin-facing slice into the specs repo by citing
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
`emit-auto` entry point (§6). Pass Agent 4's Lessons Learned report,
`command: /implement`, the run's `jira_key` and `source`, and `plugin_version`
(read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto`
renders only the report's **Command workflow improvements**, **New agents /
skills**, and plugin **Reference docs** sections plus the **Key observations**
that triggered them (§4 plugin-facing predicate) — never target-project
`CLAUDE.md`/hook advice — as `origin: auto` entries, dedupes by stable `id`
(§3), resolves the target via the §2 specs-first ladder, and writes silently.
List the persisted path (or "no plugin-facing signal — nothing persisted") in
the Phase 5 `### Session learnings` line. ADDITIVE — the impl-maintenance
report still appears in the report; this step NEVER fails the run, NEVER
commits (still true — this step only writes the feedback file; those writes
are committed by the terminal `commit-artifacts` step in Phase 7, per
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and NEVER writes
into the code repo or the current working directory.

---

## Phase 4.5 — Escalation handoff (spec/design conformance notes)

A **silent no-op** when step 7.5 (Phase 3B) wrote no `- [ ]` notes — which covers every SIMPLE/MODERATE run (no `code-review`, so step 7.5 never runs) and every run with no spec/design in scope, direct-prompt or otherwise.

When step 7.5 did write one or more notes: `prefix` = `spec` when only `specification.md` was annotated, otherwise `design`; `feature_folder` = the directory the annotated file(s) live in (the same specs-repo folder Phase 0 resolved them from); `deliverable_paths` = the annotated file(s) themselves. Present `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's consent choice verbatim:

`choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]`

On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix`, `feature_folder`, and `deliverable_paths` as above; `title: <KEY> Record spec/design conformance findings from /implement`; and `body_facts` = the count of escalated `- [ ]` notes, the code-review Spec/design-conformance dimension summary they came from, and the fact that whoever next reads this `specification.md`/`design.md` will not see them until this pull request is merged. Emit its §4.1 outcome line in the Phase 5 `### Spec/design conformance` section.

Placement is deliberate, not stylistic: step 7.5 sits inside Phase 3B, before the tests run, so calling `handoff-to-main` there would commit mid-review — hence the notes are written in 7.5 and handed off here instead, after Phase 4's post-implementation maintenance and before Phase 6's follow-ups and Phase 7's cost/`resume.md`/`commit-artifacts`. A call from inside Phase 6 or Phase 7 would falsify Phase 7's never-commits-the-deliverable claim below.

---

## Phase 5 — Final Report

Output a structured report — do NOT ask any closing confirmation:

```
## Implementation Report

### Classification
[SIMPLE | MODERATE | SIGNIFICANT | HIGH-RISK] — [reason]

### Branch
[branch name created in Pre-Phase 3, e.g. feat/add-user-authentication]

### What was implemented
[High-level summary]

### Files changed
- path/to/file.ext — [what changed]

### Opus review (if applicable)
[Verdict and 1-line summary, or "N/A (SIMPLE / MODERATE)"]

### Review triage
- **Review triage:** [N findings reviewed, M survived] — dismissals: [one line per dismissal, `finding — reason`; or "none"] — or "N/A (SIMPLE / MODERATE, no Opus review)"

### Spec/design conformance (if a spec/design was in scope)
[coverage summary from code-review's dimension; list any missing/partial/contradicts — or "N/A"; if Phase 4.5 escalated notes, add the `Phase handoff:` outcome line from `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.1)]

### Commands / tests run
- [command] → [result]

### Knowledge base
- [file updated/created] — [summary of entry] OR "no update required"

### Instructions
- [summary of change] OR "no update required"

### Documentation
- [file updated] — [what was added/changed] OR "no update required (bug fix / no user-facing change)" OR "no documentation files found"

### Session learnings
- [top suggestions from impl-maintenance agent, or "no suggestions — routine session"]

### Assumptions & limitations
- [list any]

### Deferred items (from review or tests)
- [MINOR / NIT findings that were not applied] OR "none"

### Next step
[Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — guidance only, never auto-invoked. Jira mode: finish the remaining Epics under the VI (breadth) — `/dev-workflows:implement <VI> <another-Epic>` — and, once **all** Epics are implemented, `/dev-workflows:document <VI>` then `/dev-workflows:release-notes <VI>` (both VI-level, run once). Depth vs breadth is the team's call. Direct mode: no forward pipeline step (omit). If review is still BLOCK, resolve that first.]

### Context hygiene

*(Jira mode only — omit this whole block in direct-prompt mode, like the `### Next step` above.)*
The resume pointer is written in the terminal cost phase (Phase 7), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:

- **More Epics to build (`/dev-workflows:implement <VI> <Epic2>`) or on to `/dev-workflows:document <VI>` — same build lane?** → run **`/compact`** — context stays relevant.
- Consider **`/rename <VI-ID>-<slug>-team`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
```

---

## Phase 6 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 5 Final Report is composed; NEVER
interrupts an earlier phase. Persist the run's out-of-scope / manual-step
follow-ups by citing `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md`
and executing its steps inline.

1. **Collect** the qualifying follow-ups: manual publish/config steps and
   out-of-scope maintenance items surfaced in the Phase 5 `### Session
   learnings` section (e.g. an impl-maintenance suggestion that touches
   another repo or team, or a manual post-merge step). **Do NOT** collect the
   report's `### Deferred items (from review or tests)` or skipped tests — §6
   explicitly excludes those as in-scope work already carried by the current
   task.
2. **Filter** them with the reference's §6 qualifying predicate.
3. **Resolve** the write target via the §4 ladder using `jira_key` and `source`
   (jira-driven runs carry a key; direct-prompt runs usually do not, so tasks
   land in `Tasks.md # Irregular` when the vault is writable, else report-only);
   render + place tasks and verbose notes per §1–§3; dedupe per §5.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 5 report. This phase NEVER
fails the run, NEVER commits (still true — this phase only writes follow-up
files; those writes are committed by the terminal `commit-artifacts` step in
Phase 7, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and
NEVER writes into the code repo or the current working directory.

---

## Phase 7 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 6 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /implement`, `phase: implementation`,
`role: dev`, the run's `jira_key` (or `null`) and `source`, and `plugin_version`
(read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the
session transcript + subagents (§1), loads and **advances the chained
checkpoint** (§3), runs `scripts/session-cost.py` to compute the per-model
token-cost delta against the price table (§4), records the optional statusline
cross-check (§5), and appends one per-invocation entry to
`<VI-dir>/dev-workflows/cost/<sid8>.md` via the specs-first ladder (§8) — pending
+ opportunistic move-then-delete reconciliation (§9) when no VI key resolves.
**The checkpoint advances even in the pending / report-only tiers.** Surface the
persisted path (or the report-only notice) as this phase's only output.

**Then write the resume pointer (Jira mode only).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite
`<VI-dir>/dev-workflows/resume.md` now — after the cost entry above, so the
pointer reflects the completed run, and before the commit step below, so it
is included in it. Redact per §1. Silent; the printed `### Context hygiene`
guidance already appeared in the Phase 5 report.

**Then commit session artifacts (terminal).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`commit-artifacts` entry point (§4) inline — the LAST action of the run. It
stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits
`<KEY> Add dev-workflows session artifacts (/implement)`, and pushes per §4
step 5. It NEVER writes into the code repo this run just changed — the
implementation changes and the branch created in Pre-Phase 3 are untouched —
NEVER touches a docs repo, the vault, or the current working directory;
NEVER force-pushes;
NEVER fails the run; and skips entirely when the run carries `specs_git:
blocked` (§3.3 G0), re-emitting that notice. Because the Phase 5 report was
composed before this phase, **print its §6 outcome line here**, as the run's
last output — prefixed `Specs repo:`, with any guard notice repeated in full.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable
(the implementation remains uncommitted on the branch created in Pre-Phase 3;
the terminal step above commits only the bounded session-artifact paths in
`$SPECS_PATH`; the spec/design conformance notes from step 7.5 are handed off separately, before this phase, via `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2), and NEVER writes into the code repo or the current working
directory; no user name is ever written (§10 privacy).

---

## Invariants (always enforced)

- ALWAYS `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) before escalating a halt caused by a **plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked) — so a run abandoned at the block still records it. NEVER for a work-quality review BLOCK or an environment / user halt (repo-missing, dirty-tree, jira-not-found, cancellation)
- NEVER skip Phase 1.5 classification — every run must state the level
- NEVER use Opus for routine implementation; reserve it for planning + review on SIGNIFICANT / HIGH-RISK
- NEVER run tests on SIGNIFICANT / HIGH-RISK work before the Opus code review returns a non-BLOCK verdict
- NEVER skip Phase 3.5 — if no test framework is detected, ask the user rather than silently skipping; a "Skip" decision must be explicit and logged in the Phase 5 report
- NEVER make assumptions that could have been asked — ask instead
- NEVER end implementation with "Should I implement?" — if approved, implement
- NEVER rewrite files wholesale when only an append/edit is needed
- NEVER skip Phase 4 — documentation, knowledge, instructions, and session-maintenance are mandatory after every successful impl; always collect all four agent summaries for Phase 5
- ALWAYS capture a test baseline (Pre-Phase 3.5) before writing any file
- ALWAYS create a feature branch (Pre-Phase 3) before writing any file — never implement directly on the default branch
- ALWAYS check for a clean working tree before branching; stash or get explicit user consent if dirty
- ALWAYS run `specs-preflight` at Phase 0 and `commit-artifacts` as the run's last action (per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`) — bounded to `$SPECS_PATH`'s artifact paths (§2.1) and to plugin-created branches (§2.2), always `git -C "$SPECS_PATH"` and never a `cd` (§1 rule 1), never force-pushing, and never failing the run
- ALWAYS spawn Phase 4 agents in a single message — never sequentially
- ALWAYS use `choices` arrays for decision points; last choice is always `"Other… (describe)"`
- ALWAYS produce the Phase 5 report as the final output
- ALWAYS end the Phase 5 report with a `### Next step` recommendation (per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`) — guidance only, never auto-invoked; omitted in direct mode (no VI/Epic pipeline context)
- ALWAYS pass `Command run: /implement` in the Phase 4 Agent 4 session handoff
- ALWAYS pass `Change type: code` in the Phase 4 change summary block (scopes the four maintenance agents' suggestions to code-change territory — docs / Jira variants use `docs`)
- AFTER one review-fixer pass + one re-review, if verdict is still BLOCK: stop and surface to user — do NOT loop
- AFTER two Phase 3.5 fix-loop attempts, if regressions remain: stop and surface to user — do NOT loop
- ALWAYS classify each `@path` input by inspection (Phase 0) — never by matching the path string
- WHEN `fan_out` is true (multi-repo or any directory input): floor classification at SIGNIFICANT (overridable at plan approval), run Phase 1.7, and feed its synthesized summary to the planner instead of the single Explore subagent
- WHEN `fan_out` is true and a theme stays inconclusive: run round 2 (§8.5) when round 1 left an evidence anchor to seed it, and name every still-unresolved theme — including one that never entered round 2 for lack of an anchor — in the summary's `## Unresolved` section and the risk-planner brief's `Unresolved scan themes:` field; NEVER fold it in as an ordinary gap
- WHEN a `specification.md`/`design.md` is in scope on a SIGNIFICANT / HIGH-RISK run: extract its in-scope IDs, pass `applicable_spec` to `code-review`, report conformance in Phase 5, and escalate unresolved `missing`/`contradicts` as `- [ ]` notes on the spec/design — never silently
- WHEN `task_shape: bug` on a SIGNIFICANT / HIGH-RISK run: risk-planner follows `bug-diagnosis.md` (repro-first + ranked hypotheses), and all `[DEBUG-xxxx]` instrumentation is stripped before the Opus-review diff is captured
- WHEN `task_shape: bug`: the ranked hypotheses MUST be backed by a repro `risk-planner` **actually ran** — its `### Hypotheses (ranked)` block carries the command, its redacted output, and the reproduction rate (`bug-diagnosis.md` step 1's completion criterion). If it returns "Ranking withheld — no red-capable repro", do NOT proceed to implementation on a guess: surface what it tried and ask `choices: ["Help construct a repro (you'll be prompted for what to try)", "Proceed without a repro (recorded in the Phase 5 report)", "Cancel"]`. Proceeding is the user's call to make explicitly, never the default.
- ALWAYS fan out `code-scanner` one-per-repo in a single response, capped at 4 concurrent — never sequentially
- NEVER silently skip a referenced `@dir` that is missing or unrecognized — surface it and ask (classification.md §8.4)
- Scanning agents (`jira-reader`, `code-scanner`) are pinned to the §2.1 detection (Sonnet) chain like every mechanical step (never inherit the session model); escalate a single scanner to Opus only when one repo slice is oversized
- ALWAYS end the Phase 5 report with a `### Context hygiene` block per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the `resume.md` write runs later, in the terminal cost phase, per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the guidance only), then a same-lane `/compact` suggestion + `/rename <VI-ID>-<slug>-team`; **omitted in direct mode** (no VI/Epic context, no `resume.md`); the Phase 3B checkpoint additionally suggests `/compact` mid-run. Guidance only, never auto-run.
