---
name: design
description: keyed engineering-design workflow (Dev phase). Takes over a merged specification.md from the specs repo's main branch, grounds strictly in the fully-mounted implementation code, and authors a reviewed engineering design.md through a relentless one-question-at-a-time grill that challenges the spec and designs the implementation; gates on the Opus design-reviewer and lands design.md + the spec's engineering-review edits on main via branch + PR for /implement. Optional --design-twice forces the Phase 5 interface fan-out even when no contested-interface signal fired.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Author an engineering design for the resolved item: $ARGUMENTS

`/design` is the **Dev-phase engineering-design** workflow — the design step of the PM→PA→PE→Dev pipeline
(`/specify` → `specification.md`; then `/design` → `design.md`). The developer *takes over* a merged
`specification.md`, grounds in the **fully-mounted** implementation code, and authors a reviewed
engineering `design.md` through a relentless one-question-at-a-time grill that **challenges** the spec
and **designs** the implementation. It gates on the Opus `design-reviewer` and offers to land
`design.md` + the spec's engineering-review edits on the specs repo's main branch (via branch + PR) so
`/implement` can plan and build from it.

Key distinction from `/specify`: `/specify` (PE) *authors* the requirements spec and grounds lightly
(soft repo gate); `/design` (Dev) *challenges* that spec and *designs* the implementation, and must see
**all** implementation repos — its repo gate is **strict** (hard-stop on any unmounted repo).

Flags: `--design-twice` forces the Phase 5 interface fan-out on the run's load-bearing interface, even when no contested-interface signal fired (`references/design-format.md` `## Seams`).

---

## Phase 0 — Resolve input

1. **Resolve the address — strip every recognised flag first.** `--design-twice` is removed from
   `$ARGUMENTS` before anything else, exactly as `commands/idea.md`'s Phase 1 strips its own: an
   unstripped flag is read as the positional token and resolution then fails on a token that was
   never an address.

   Parse the **single positional address** from the stripped `$ARGUMENTS` — a `<KEY>`, or an
   `@<path>` naming a folder or a file inside one — and resolve it with `resolve-address`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3). Carry forward:
   - `<PRD>` — the resolved **PRD folder's** `key`: the folder itself when the address named a
     `PRD-` folder, its parent when the address named an `EPIC-` folder.
   - `<EPIC>` — the resolved `EPIC-` folder's `key`, or `null` when the address named a `PRD-`
     folder. **The kind decides the altitude**, which is what replaces the two-key grammar: the
     second key was always derivable from the first.

   With no positional address, stop with
   `DESIGN_NEEDS_KEY: /design needs a PRD or Epic address — a key, or an @<path> to its folder.` —
   `/design` has no direct-prompt behaviour. **Resolution supplies the address and nothing else:
   `/design` reads no document for content at this step — the requirements source of truth is the
   merged `specification.md` in the specs repo.**

2. **Resolve `$SPECS_PATH`.** `/design` reads `specification.md` and writes `design.md` under
   `$SPECS_PATH/specifications/`. If `$SPECS_PATH` is unset, stop with a clear error naming `SPECS_PATH`
   (`choices: ["Set SPECS_PATH (enter the path)", "Cancel"]`).

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier
run, retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent
when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if
it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal
`commit-artifacts` step skips on it.

*(The preflight runs here, before the gate below, because `require-on-main` performs **no** `fetch` of its own — §3.2 — and relies on this step's best-effort one. Gating first would test never-fetched refs: a just-merged artifact would be missed on `origin/<default>` while the stale remote-tracking ref for its deleted branch still carries it, producing a false row D/E stop. `specs-preflight` self-gates on `$SPECS_PATH`, so it is safe this early.)*

3. **Map onto the specs repo + require the spec on main.** Derive provisional kebab-case slugs from the relevant title(s): `<vslug>` for `<PRD>`, and `<eslug>` for `<EPIC>` when `focus_key` is set.
   - **Resolve the PRD dir:** call `resolve-address <PRD>` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3) and use its `path`; on `ambiguous`, stop naming every match and `@<path>` as the way through. No matching rule is written here — §5 owns it, and it carries the legacy fallback. Use a freshly derived `PRD-<PRD>-<vslug>` only on `status: absent`. Every later `specifications/<PRD>-<vslug>/` in this command — the Epic-enumeration ref test included — names the dir resolved here.
   - **Resolve the feature folder** by case:
     - **`focus_key` set** → the per-Epic home `specifications/<PRD>-<vslug>/EPIC-<EPIC>-<eslug>/` (same honor-existing tolerance on the `EPIC-<EPIC>-<eslug>` segment); the target is `specification.md` there.
     - **`focus_key` null** → resolved in step 4 (Granularity): either the flat PRD dir (stand-alone Epic / broad PRD spec) or a per-Epic subfolder the picker selects.
   - **Gate the resolved target on main** (the `mgd-specifications` **main** branch is the handoff surface, verified against `origin/<default>` by ref — never a worktree file-existence check). Execute `require-on-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3) against the resolved `specification.md` path — immediately once `focus_key` is set, or once step 4 resolves the target for `focus_key` null — and map its §3.7 return value by `stopped` first, never by `on_main` alone: any stopping state → stop per §4.4, naming the concrete branch/PR state it reports; otherwise (`stopped: false`) `pass` → proceed; `pass_amending` → proceed, printing §3.3's row-B message (this run's own in-progress branch amends `specification.md`, so it legitimately differs from `<default>`) — proceed as-is, never offering a repair here, since that would discard this run's own in-progress amendments; `absent` (row F) → stop: `no specification.md exists yet for this item — run /dev-workflows:specify for it and merge it to the specs repo main first.`; `unmanaged` → behave exactly as before this feature.

4. **Granularity — the Epic is the unit of work; no fan-out. Progress-aware Epic picker.** One
   `design.md` per invocation. Resolve by `focus_key`:
   - **`focus_key` set** (a bare Epic key, whose folder's own `kind` sets the altitude — there is no second positional key auto-resolved by
     the front-end) → the Epic is chosen; the feature folder is its per-Epic home. Skip the picker; go
     to step 5.
   - **`focus_key` null** → inspect the resolved PRD dir in the specs repo:
     - it holds a **flat `specification.md`** (a stand-alone top-level Epic, or a broad PRD-level spec) → one design; the feature folder is the PRD dir itself. Skip the picker; go to step 5 (step 3's gate re-applies against this flat path).
     - it holds **Epic subfolders** → enumerate the **spec'd** ones using the ref test `git -C "$SPECS_PATH" cat-file -e "origin/<default>:specifications/<PRD>-<vslug>/EPIC-<EPIC>-<eslug>/specification.md" 2>/dev/null` (exit 0 = present on `<default>`; the `2>/dev/null` is required — git writes `fatal:` to stderr on absence) — never a worktree file-existence check, which would list a branch-only Epic as designable for a user to select before step 3's gate stops on it. A subfolder that fails the test is excluded from the actionable set and counted in the excluded-count report, with the reason distinguished: *"N Epic(s) excluded — no specification.md; M excluded — specification.md not yet merged to `<default>`."* Then branch on count — this is the reusable **progress-aware Epic-picker pattern** in `${CLAUDE_PLUGIN_ROOT}/references/epic-picker.md`, applied here with `/design`'s own done-predicate and enumerated from the specs repo, which is now the only place any command enumerates Epics from:
       - **exactly 1 spec'd Epic** → no picker; auto-select it; re-point the feature folder to its per-Epic subfolder; emit a one-line notice.
       - **≥2 spec'd Epics** → render the picker per `${CLAUDE_PLUGIN_ROOT}/references/epic-picker.md`, listing every spec'd Epic as prose and letting the array carry at most three rows plus *"Another Epic from the list above — name its key"* (that file's *The cap* section — four spec'd Epics already overflow the prompt, and a typed key is resolved against the keys just listed, never parsed). Compute each Epic's state from `/design`'s **done-predicate** against that Epic's resolved folder:
         - **○ not started** — a `specification.md` exists there but no `design.md` and no `_design-session.md` → selectable.
         - **◐ in progress** — a `_design-session.md` exists there but no `design.md` → selectable as a resume (per-Epic stage resume then runs in Phase 5 from that `_design-session.md`).
         - **● done** — a `design.md` exists there → shown greyed, **not** default-selectable; selecting offers *revise*.
         Default cursor = the first actionable row (in-progress before not-started). On selecting an Epic → set `focus_key` = that Epic and re-point the feature folder to its per-Epic subfolder; step 3's gate re-applies against that Epic's `specification.md`.
     - neither a flat `specification.md` nor any spec'd Epic subfolder exists at all → the equivalent of step 3's `absent` outcome; stop with its wording, unchanged.

5. **Detect a prior `/design` run.** If a `_design-session.md` exists in the resolved feature folder,
   record that a resume is available — Phase 1 asks resume-vs-fresh. (Distinct from `/specify`'s
   `_session.md`, which may coexist in the same flat folder.)

`/design` is **cwd-agnostic** — it reads/writes an absolute `$SPECS_PATH`-rooted feature folder and
scans repos under `$REPOS_PATH`; cwd need not be inside either.

---

## Phase 1 — Configure

**Rule: Ask, don't guess. This rule is absolute.** Use `choices` arrays; 2–4 options, and never author an "Other" option — the harness supplies the free-text escape itself (`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` §0).

1. **Feature folder.** Confirm the path resolved in Phase 0:
   `choices: ["Use <feature_folder> (Recommended)", "Use a different path (you'll be prompted)", "Cancel"]`
2. **Resume vs fresh** (only if step 5 found a `_design-session.md`): read it back and summarise which
   stages are settled:
   `choices: ["Resume — skip settled stages (Recommended)", "Start fresh — discard the prior design session", "Cancel"]`
3. **Repo refresh policy** (governs Phase 4's `code-scanner` dispatches):
   `choices: ["fetch + pull default branch (Recommended)", "fetch only", "no refresh"]`
4. **Repos search base (`$REPOS_PATH`).** Read `${REPOS_PATH:-/workspace}` (may be colon-separated):
   `choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel"]`

Also display (context): resolved feature folder; resolved `<PRD>` / `<EPIC>` (or 'none — PRD-level');
resolved `$SPECS_PATH`; resolved `$REPOS_PATH`.

---

## Phase 1.5 — Classify + tiered model gate

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then classify as
`SIMPLE` / `MODERATE` / `SIGNIFICANT` / `HIGH-RISK`. This single classification scales **grill depth**,
`design.md` **section-inclusion** (per `design-format.md`), and **`design-reviewer` rigor** together.
Resolve per-step routing per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §9:

```yaml
model_routing:
  classification: <SIMPLE|MODERATE|SIGNIFICANT|HIGH-RISK>
  reason: <one-line>
  current_model: <the model this orchestrator/grill is running under>
  detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # code-scanner, interface-designer, impl-maintenance
  review_model:    <§2 Opus chain>     # design-reviewer (frontmatter-pinned; recorded, no override)
  authoring_model: <= current_model>   # the interactive grill + design.md authoring (session model, not a delegated subagent)
  opus_available: <true if a §2 Opus model resolved, else false>
  notes: <any §2/§2.1 fallback or degradation>
```

The grill + authoring run inline on `current_model` (interactive judgment — not a delegated subagent).

**Tiered model gate (stricter than `/implement` — `/design`'s critical synthesis is inline, not an Opus
subagent):**
- **SIGNIFICANT / HIGH-RISK + `current_model` is not an Opus-tier model → HARD gate.** Stop and require
  relaunching `/design` on Opus (the run is resumable from `_design-session.md`):
  `choices: ["I'll relaunch /dev-workflows:design on Opus (Recommended)", "Override — proceed on the current model (logged in the final report)", "Cancel"]`
  Design authoring for risky work must be Opus — the Opus `design-reviewer` reviews, it cannot originate
  good architecture.
- **SIMPLE / MODERATE + not Opus → soft advisory.** Recommend Opus but proceed; record the choice in
  `notes` and the final report.
- **Opus session →** proceed (the intended case).

---

## Phase 2 — Read the spec

Read the resolved `specification.md` **fully** (from the specs repo main). Extract the in-scope items,
user stories (`[Uxx]`), acceptance criteria (`[ACxx]`), and test cases (`[TCxx]`) the design must cover
— this is the traceability baseline for **Requirements coverage** and the raw material the grill
challenges. Note the spec's `Published` flag (governs whether Phase 5 may propose ID changes or must
annotate-only) and any existing `- [ ]` open questions (spec-level; tolerated — the design may resolve
or inherit them). **No PRD re-read** — the spec is the requirements source of truth.

---

## Phase 2.5 — Resolve applicable ARD (optional)

Resolve any ARD for this item by citing `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md` with `<PRD>`, `<EPIC>` (`focus_key`), and `$SPECS_PATH`. On `status: none`, **skip the rest of this phase and proceed exactly as before** (no ARD in play). On `status: unmerged`, **stop**, naming the returned `branch` and any `pr`. On `status: found`, carry the returned `invariants` (PRD-level inherited + Epic-level `AD#N`) and `guidance_summary` into Phase 5 — the design is authored **within** them, and a necessary deviation is recorded in a `## ARD deviations` section of `design.md` + as a `- [ ]` open question (never edit the ARD). The `invariants` list is passed to `design-reviewer` in Phase 6 as `applicable_ard`.

---

## Phase 3 — Derive repos + STRICT gate

1. **Auto-derive candidate repos** from the spec's themes / component mentions / any referenced code
   paths. Build the slug→clone map (`/epics`-style): for each top-level dir under each `$REPOS_PATH`
   entry, `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, take the
   URL's last path segment as the slug; skip dirs with no `.git` or a failing/timed-out call.
2. **Confirm the complete set — the developer owns it.** Present the derived candidates and ask the
   developer to confirm the **complete** list of implementation repos this design must span:
   `choices: ["Confirm this set (Recommended)", "Add repos (you'll be prompted)", "Remove repos (you'll be prompted)", "Cancel"]`
3. **Resolve each confirmed repo against the map.** One match → use it. Ambiguous or zero matches
   escalate per the `Repo unresolved (zero matches) — /epics` rule in
   `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`:
   `choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo"]`
4. **STRICT mounted gate — hard-stop.** Any repo in the confirmed set that is **not mounted** under
   `$REPOS_PATH` **hard-stops** `/design` (unlike `/specify`'s soft gate): describe the missing
   capability and why the design needs it (you cannot name or link an unmounted repo's code), then:
   `choices: ["I've remounted — re-scan", "Remove this repo from the design's scope (you confirm it's not needed)", "Cancel"]`
   On "remounted", the developer restarts the container with the repo mounted and re-runs `/design`
   (resuming from `_design-session.md`); a design cannot be completed while a confirmed repo is missing
   unless the developer explicitly removes it from scope. Record the confirmed repo set in
   `_design-session.md`.

---

## Phase 4 — Code scan

Spawn `code-scanner` instances in **batches of up to 4 concurrent agents** per Agent message over
**all** confirmed, mounted repos (the scan runs over the full set regardless of classification — only
grill depth / sections / review scale by tier). Wait for each batch before the next.

→ Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Scan this repo for the brief:
  >
  > repo_path:     <resolved absolute path for this repo from Phase 3>
  > repo_url_slug: <repo slug, e.g. "cluster">
  > capability_themes:
  >   [themes derived from the specification]
  > context: |
  >   [3–5 sentences: what the spec requires; what the design must ground — seams, interfaces, gaps]
  > search_hints:
  >   symbols:  [names inferred from the spec, or []]
  >   paths:    [globs inferred from themes, or []]
  >   keywords: [grep keywords from themes]
  > refresh:
  >   switch_to_default_branch: [true if Phase 1 chose 'fetch + pull default branch' or 'fetch only'; false if 'no refresh']
  >   pull: [true only if 'fetch + pull default branch'; false otherwise]"

Handle per-repo status after the batch returns:
- `OK` / `PARTIAL` / `EMPTY` — store the capabilities / seams / interfaces / gaps output; this grounds
  Phase 5's design decisions.
- `REPO_MISSING` — should not occur post-gate; if it does, return to the Phase 3 strict gate for that
  repo.
- `DIRTY_TREE` — escalate per the `Dirty working tree` rule in
  `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
- `REFRESH_BLOCKED` — escalate per the `Refresh blocked` rule in
  `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
- `prep.read_only: true` — not a failure. The scan ran at `prep.scanned_ref`. Escalate per the `Read-only mount — ref stale or diverged` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`; otherwise proceed silently and cite evidence at `prep.scanned_ref`.

---

## Phase 5 — Grill: challenge + design

**Interview technique (grilling — embedded; no runtime dependency).** Conduct the design as a **relentless** interview per `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, explore the Phase 4 code scan / spec to self-answer (fact-vs-decision), walk the design tree in dependency order, continue to shared understanding then write the section.

Run **two intertwined tracks**, authoring `design.md` live against
`${CLAUDE_PLUGIN_ROOT}/references/design-format.md`, applying the no-hard-wrap prose convention in
`${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`, sections scaled by the Phase 1.5 classification:

- **Challenge the spec.** Interrogate testability, seams, scope realism, missing cases, and feasibility
  against the real code. Record every substantive challenge **into `specification.md`**: add/extend an
  `## Engineering review` section and new `- [ ]` open questions on the spec. Raise substantive changes
  to ACs/TCs as **proposals** — do not unilaterally rewrite them; when the spec is `Published: yes`,
  **annotate only, never mutate `[Uxx]` / `[ACxx]` / `[TCxx]` IDs** (those route through the specs
  repo's human change-management).
- **Design the implementation.** Author each `design.md` section: Context & problem, Requirements
  coverage (with the challenge notes cross-referencing the spec's `## Engineering review`), Architecture
  & components, Interfaces / contracts, Seams, Data flow, Error handling & edge cases, Test strategy,
  Risks & mitigations, Migration / rollout / backward-compatibility, Out of scope. Omit a
  non-applicable section with a one-line `_N/A — why_`.

As each decision settles, append it to `_design-session.md`. **For an interface decision, record each
live candidate shape there as it arises** — not only the settled outcome — and strike a candidate when it
is eliminated: the fourth contested-interface signal in `${CLAUDE_PLUGIN_ROOT}/references/design-format.md` `## Seams`
counts exactly those recorded, un-eliminated candidates, and a settled-only log leaves it nothing to
count. Capture a genuinely-ambiguous term in `_design-glossary.md`. **Resolve `design.md` open questions to zero** — the design is the last gate
before code. A residual engineering unknown that truly cannot be resolved is either (a) pushed onto the
`specification.md` as a spec-level `- [ ]` for the PM (and the design waits on it), or (b) kept as a
`design.md` `- [ ]` that will **block handoff** (Phase 6/7). A repo gap surfacing here → hard-stop (the
Phase 3 strict gate); resumable from `_design-session.md`.

**Interface fan-out (offered on a signal; forced by `--design-twice`).** When the interview reaches an
interface decision that is **contested** — any signal in `${CLAUDE_PLUGIN_ROOT}/references/design-format.md`
`## Seams` — say which interface is contested, which signal fired, and your own read of the trade-off,
then offer. **Neither option carries a `(Recommended)` marker, and neither is recommended by default**:
this list is shown only once the interface is *already* contested, so which way to go depends on how
contested it actually is — a judgement that belongs to the user rather than to a marker, per the
"no option safe to recommend" remedy in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.

```
choices: ["Design it three ways (3 parallel takes, then compare)", "Decide it in the interview"]
```

Declining costs nothing and changes nothing: the interview continues and the `### Alternatives considered` requirement is satisfied by hand as it would have been anyway.

**With `--design-twice` the offer does not run at all.** The flag forces the **fan-out**, not the
opportunity: say that the flag forced it and on which interface, then dispatch the three takes directly.
A user who typed the flag has already given the answer the offer would ask for, and re-asking is a
prompt that changes nothing.

On acceptance — or immediately, when `--design-twice` forced it — dispatch **three takes in a single
response** (the plugin's existing parallel fan-out pattern), each blind to the others. One constraint per
take, labelled **A**, **B**, and **C** in that order; those are the labels the Final report's
`chose <A|B|C|hybrid>` refers to:

→ Agent (subagent_type: "dev-workflows:interface-designer", model: `<detection_model — §2.1 Sonnet chain>`) ×3:
  > "Produce one interface proposal for this brief:
  >
  > constraint: [A — Minimise the interface | B — Maximise flexibility | C — Optimise for the most common caller]
  > problem_frame: [what the interface is for, the constraints any proposal must satisfy, the seam it sits at]
  > code_context: [the Phase 4 code-scanner findings for the relevant repo(s) — inline, or an absolute path]
  > dependency_category: [the seam's category if already settled, else omit]"

**Handle a take that stops.** A take returning `status: BLOCKED` could not read its `code_context` (the
read-failure contract in `${CLAUDE_PLUGIN_ROOT}/references/context-management.md`). Name the unreadable path, and do
**not** count it as a take. Then either re-dispatch that one constraint with a valid `code_context`, or
proceed with the takes that did return — saying which constraint is missing and that the comparison runs
on fewer than three. Never write the missing take yourself: a constraint the fan-out never explored is a
gap in the comparison, not a gap for the orchestrator to fill.

When the takes return, present them, then compare **on named axes, not impressions**: **depth**
(behaviour reached per unit of interface a caller must learn), **locality** (where change, bugs, and
verification concentrate), **seam placement** (whether the boundary falls where things actually vary).
Give an opinionated recommendation, and propose a **hybrid** where the strongest ideas split across
takes — that is a common outcome, not indecision.

The user chooses. Record the chosen interface in `## Interfaces / contracts`, and record the losing
takes in `### Alternatives considered` (take, constraint, why it lost) per
`${CLAUDE_PLUGIN_ROOT}/references/design-format.md` section 3. Then resume the interview.

---

## Phase 5.5 — Structural pre-lint

Before the review gate, run the deterministic checks in
`${CLAUDE_PLUGIN_ROOT}/references/pre-lint.md` against the drafted `design.md`: the **Universal checks**
plus the **design** block (core headings present; a MODERATE+ design has `## Seams` or a `_N/A — why_`;
report the `## Open questions` `- [ ]` count). Surface every finding; inline-fix the mechanical ones
(delete a stray placeholder token); leave content gaps for the grill/author. **Advisory** — never
blocks; proceed to Phase 6 once findings are surfaced. `design-reviewer` remains the gate (it still
enforces the open-questions hard block).

## Phase 6 — Review gate

Dispatch `design-reviewer` (Opus):

→ Agent (subagent_type: "dev-workflows:design-reviewer", model: `<review_model — §2 Opus chain; frontmatter-pinned, recorded, no override>`):
  > "Review the design for this brief:
  >
  > Design path:        [absolute path to design.md]
  > Specification path: [absolute path to specification.md]
  > Classification:     [the Phase 1.5 classification]
  > applicable_ard:     [the ARD invariants resolved in Phase 2.5, or omit if none]"

**Act on the verdict** (mirrors `/specify`):
- **`BLOCK`** — fix the BLOCKER findings (the orchestrator/grill edits `design.md` inline — no delegated
  writer) and re-review once. **Any unresolved `design.md` `- [ ]` is a BLOCKER by policy** — resolve it
  or push it onto the spec (Phase 5) before handoff. If still `BLOCK`, escalate per the
  `Review verdict BLOCK (unresolved after one fix cycle) — /epics` rule in
  `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`, per unresolved BLOCKER individually:
  `choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in the final report)", "Override and accept the finding", "Cancel the whole run"]`
- **`MAJOR` / `MINOR` / `NIT`** (surfaced under `PASS WITH RECOMMENDATIONS`) — defer to the final
  report; no mandatory fix cycle.
- **`PASS`** / **`PASS WITH RECOMMENDATIONS`** — proceed to Phase 7.

Cap: one fix cycle + one re-review maximum. Phase 7 will not hand off a `design.md` with any unresolved
`- [ ]`.

---

## Phase 7 — Handoff

Write the feature folder: `design.md` (flat, alongside `specification.md`), the updated `specification.md` (its `## Engineering review` + open-question edits), `_design-session.md`, and `_design-glossary.md`. **Refuse to proceed if `design.md` has any unresolved `- [ ]`** (the decision-completeness gate).

Then **offer** (commit-when-asked — never automatic), presenting `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's choice array verbatim:
`choices: ["Branch + commit + push + open PR to main (Recommended)", "Just write the files — I'll handle git (the next phase will stop until this is on main)", "Cancel"]`

On the first choice, execute `handoff-to-main` (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2) with `prefix: design`; `feature_folder` as resolved in Phase 0 — the per-Epic subfolder for a **per-Epic** or **stand-alone-Epic** design (`<EPIC>` = `focus_key`, which for a stand-alone Epic equals `key`), or the PRD dir for a **broad PRD-level** design (`focus_key` null); Epic keys are globally unique, so the per-Epic form needs no PRD prefix — §2.2 derives `design/<EPIC>-<eslug>` or `design/<PRD>-<vslug>` from it, matching today's branch names, both forms using hyphens; `deliverable_paths` = `design.md`, the amended `specification.md`, `_design-session.md`, and `_design-glossary.md`; `title: <EPIC|PRD> Add engineering design`; and `body_facts` = the `design.md` sections authored, the spec-challenge count (`## Engineering review` notes / new spec `- [ ]`), the confirmed repo set, and the `design-reviewer` verdict. **Merged-to-main = ready for `/implement`.** Emit its §4.1 outcome line in the Final report.

### Next Epic (after a per-Epic design from a multi-Epic PRD)

When this run designed a per-Epic Epic selected from Phase 0's ≥2-Epics picker, offer — once the
write/commit completes:
`choices: ["Next Epic — re-open the picker (Recommended)", "Stop here"]`
On **"Next Epic"**, re-render the Phase 0 picker **minus the just-completed Epic** (recompute each
remaining Epic's ○/◐/● state — the freshly-authored design now shows **● done** and drops out of the
actionable set), then, on selection, loop back through Phases 2–7 for the selected Epic. This offer does
not apply to a stand-alone Epic, a single-Epic PRD, or a broad PRD-level design.

## Phase 8 — Session maintenance & feedback

Terminal phase — runs after Phase 7 and before the Final report is presented;
NEVER interrupts an earlier phase. `/design` has no built-in maintenance agent,
so this phase invokes `impl-maintenance` on the Sonnet detection chain and then
persists the plugin-facing slice of its report as session feedback.

**Capture-at-block invariant.** This terminal phase captures gaps for a *completed* run. Separately, if an EARLIER phase **halts on a plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked), `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating — so a run abandoned at the block still records the gap. NEVER `emit-block` for a work-quality review BLOCK or an environment / user halt (repo/spec gate, key-not-found, cancellation).

**Session-hygiene invariant.** End the report with a `### Context hygiene` block per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the
`resume.md` write runs later, in the terminal cost phase, per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the
guidance only), then a
same-role `/compact` suggestion + `/rename <PRD-ID>-<slug>-dev`. Guidance only, never auto-run.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /design
   > - What was done: [one-paragraph summary of the engineering design authored]
   > - Key events: [BLOCK reviews and their reason, STRICT repo-gate hard-stops, model-gate overrides, unresolved design open questions — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: [the design-reviewer verdict — PASS | PASS WITH RECOMMENDATIONS | BLOCK]
   > - Test result: N/A (no tests in /design)
   > - Project root: [the resolved feature folder under $SPECS_PATH]"
2. **Persist plugin feedback (automatic).** Project the report's plugin-facing
   slice into the specs repo by citing
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
   `emit-auto` entry point (§6). Pass the Lessons Learned report,
   `command: /design`, the run's `key` and `source`, and `plugin_version`
   (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto`
   renders only the report's **Command workflow improvements**, **New agents /
   skills**, and plugin **Reference docs** sections plus the **Key observations**
   that triggered them (§4) — never target-project `CLAUDE.md`/hook advice — as
   `origin: auto` entries, dedupes by stable `id` (§3), resolves the target via
   the §2 specs-first ladder, and writes silently.
3. **Surface** the persisted path (or "no plugin-facing signal — nothing
   persisted") as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits (still true — git for
the deliverable is offered only in Phase 7, and this phase itself runs no git;
those writes are committed by the terminal `commit-artifacts` step in Phase 9,
per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), and NEVER writes
into the current working directory. The specs-first ladder writes the feedback
file inside `$SPECS_PATH`, alongside the feature folder — the intended home.

## Phase 9 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 8 (feedback)
and NEVER interrupts an earlier phase. Records this command's token-cost
contribution to the PRD by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /design`, `phase: planning`, `role: dev`, the
run's `key` (or `null`) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<PRD-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no PRD key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

**Write the resume pointer.** Cite
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite
`<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the
pointer reflects the completed run, and before the commit step below, so it is
included in it. Redact per §1. Silent; the printed `### Context hygiene`
guidance already appeared in the report.

**Commit session artifacts (terminal).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`commit-artifacts` entry point (§4) inline — the LAST action of the run. It
stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits
`<KEY> Add dev-workflows session artifacts (/design)` with no `Co-Authored-By`
trailer, and pushes to the branch this run's handoff phase created (§4.1). It
NEVER touches a code repo, a docs repo, or the current working
directory; NEVER force-pushes; NEVER fails the run; and skips entirely when the
run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Hold its
§6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (git
for the deliverable is offered only in Phase 7; the terminal step above commits
only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes
into a docs/code repo or the current working directory; no user name is ever
written (§10 privacy).

## Final report

Report: feature-folder path; classification + model-gate outcome; `design.md` sections authored (and
those `_N/A_`); spec challenges recorded (count of `## Engineering review` notes / new spec `- [ ]`);
confirmed repo set (and any removed-from-scope); the `design-reviewer` verdict; the PR URL (if
opened); the `Specs repo:` outcome line from `commit-artifacts`
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full;
and the `### Next step` recommendation (below).

The report always states exactly one of the Phase 5 interface fan-out outcomes whenever the run reaches the Final report (a Phase 1.5 model gate or a Phase 3 strict-repo hard stop ends the run before it):

- **Interface fan-out:** [one of — `ran — <interface>, <N> of 3 takes returned, chose <A|B|C|hybrid>` — `<N>` counted from the takes that actually returned, naming the constraint of any that returned `BLOCKED` | `offered and declined — <interface>` | `not offered — no contested interface (no signal in design-format.md ## Seams)`]

### Next step

End the report with a `### Next step` recommendation per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` (guidance only — never auto-invoked): → `/dev-workflows:implement <PRD> <Epic>` (depth, still Dev) `<merge-clause>`, which stops rather than proceeding wherever this design reached a branch (`${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3.3 rows D/E) and is unaffected wherever it reached none (§3.4's `/implement` row); the **Epic fan-out** `/dev-workflows:design <PRD> <another-Epic>` designs a sibling Epic (breadth, no merge wait — a different Epic's design). If the run BLOCKED or `design.md` has open questions, recommend resolving those first.

`<merge-clause>` is the placeholder `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` owns, resolved from this run's own `Phase handoff:` outcome line (§4.1) and never written as the unconditional "once the pull request above is merged" — the handoff offered above reaches a declined, a push-failed and a nothing-to-commit outcome, and two of the three open no pull request to wait on. This offer is prose rather than a `choices:` array, so `scripts/check-docs.sh` check 11 cannot see it: it is held by review alone, even though `design.md` is exactly the intersection that check looks for.

### Context hygiene

The resume pointer is written in the terminal cost phase (Phase 9), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:

- **Continuing on this Epic (`/dev-workflows:ready` / `/dev-workflows:implement <PRD> <Epic>`) or the next Epic (`/dev-workflows:design <PRD> <Epic2>`) — all still Dev?** → run **`/compact`** — context stays relevant.
- Consider **`/rename <PRD-ID>-<slug>-dev`** to relocate this session later.

Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
