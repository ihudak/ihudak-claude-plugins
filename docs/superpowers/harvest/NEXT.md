# Harvest status pointer — dev-workflows upstream harvest

## COMPLETE & SHIPPED (2026-07-29)
The 8-item harvest (freebie + Tier 1 + Tier 2) is implemented, reviewed, and **merged to `main` + pushed**
in all three editions:
- `ihudak-claude-plugins` (canonical) — `main` at `b9cfd38`; dev-workflows **2.38.0**. Passed the opus
  whole-branch review (Ready-to-merge: YES; 4 Minors fixed in `dab042c`).
- `mgd-claude-plugins` — `main` at `dd39786`; dev-workflows **2.38.0** (byte-identical copy of canonical).
- `ihudak-copilot-plugins` — `main` at `e4e3703`; dev-workflows **2.8.0** (hand-adapted conversion:
  `~/.copilot/…/skills/_shared/` paths, `implement:`/`design:` keywords).

What shipped: spec→code **converge** gate (code-review 10th dim + risk-planner ID-tags + /implement
wiring), `bug-diagnosis.md` discipline, test-writer falsifiability/mutation gate, review-fixer
plan-conflict, code-review Fowler floor, altitude-aware ambiguity taxonomy + "design tree"→"decision
tree" rename, deep-module/seam vocab, risk-planner no-placeholders, VI counter-metrics. Spec + plan:
`docs/superpowers/specs|plans/2026-07-29-dev-workflows-upstream-harvest*.md`. Do NOT redo any of this.

## Wave 3 — SHIPPED (2026-08-01; NIT follow-up 2026-08-02)
Five deferred nuggets + the cheap half of the Adjacent item shipped to all three editions. Current tips:
canonical `72bb7ae` (**2.39.1**), mgd `5478b74` (**2.39.1**), Copilot `9fca4db` (**2.9.1**) — the `.1`
patch was a whole-branch-review NIT follow-up (`context-management.md` 4th-strategy summary consistency);
wave-3 base was 341b5df/557526b/fa25405 (2.39.0 / 2.9.0). Spec + plan:
`docs/superpowers/specs|plans/2026-08-01-dev-workflows-deferred-nuggets*.md`. What shipped: ADR
3-condition candidacy filter (`ard-format.md`), wide-refactor expand→migrate→contract exception
(`epics.md`), prototype-snippet exception (`design-format.md`), missing-adoption gap (`code-review.md`
dim 4), `resume.md` redaction reminder (`session-hygiene.md`), and the context "hand off by file, not
paste" 4th strategy (`context-management.md`, **reference-only**). Also **fixed** a pre-existing `/idea`
+ `/create-vi` YAML-frontmatter bug (a colon-space in the unquoted `description:` silently dropped all
frontmatter at runtime). Passed the Opus whole-branch review (READY; 3 minors fixed). Do NOT redo.

## Wave M (the `/implement` dispatch file-handoff) — SHIPPED (2026-08-02)
The deferred M item shipped to all three editions. Current tips: canonical `5d8f56c` (**2.39.2**),
mgd `f2d0ac3` (**2.39.2**), Copilot `2de7eb2` (**2.9.2**). Spec + plan:
`docs/superpowers/specs|plans/2026-08-02-implement-dispatch-file-handoff*.md`. What shipped: extended
the existing `/document` + `/epics` `mktemp` handoff pattern to `/implement`'s four in-loop dispatches
(`risk-planner`, `test-writer`, `code-review`, `review-fixer`) plus the Phase 3.5 sibling — the
multi-source summary, approved plan, review diff, and code-review report are written to `mktemp` files
(outside every repo tree → no `git diff` pollution) and handed as absolute **paths**, not pasted
inline; each agent's `## Inputs` notes a field may arrive inline or as a path. Behavior-preserving
(Design A, surgical per-artifact). Passed the Opus whole-branch review (READY WITH MINORS; both fixed —
the re-review paths now refresh `review_diff_file`, and a review-fixer note period). Do NOT redo.

## Wave S (the `/vuln` + `/upgrade` dispatch file-handoff) — SHIPPED (2026-08-02)
The S follow-up shipped to all three editions. Current tips: canonical `04e51f4` (**2.39.3**),
mgd `e1a7ab5` (**2.39.3**), Copilot `d7ad4b3` (**2.9.3**). Spec+plan (one doc):
`docs/superpowers/specs/2026-08-02-vuln-upgrade-dispatch-file-handoff-design.md`. What shipped: the
`/vuln` research report (→ `vuln-fixer`, `code-review`, resumes) and the `/upgrade` planner handoff
(→ `risk-planner`, `upgrade-executor`, resumes), plus each command's `code-review` `git diff`, are
written to `mktemp` files (outside every repo tree → no `git diff` pollution) and handed as absolute
**paths**; `vuln-fixer` + `upgrade-executor` `## Process` note a field may arrive inline or as a path.
Behavior-preserving. Passed the Opus whole-branch review (READY WITH MINORS; all fixed — the
`/upgrade` regression-resume `plan_file` gap + 2 NITs). Do NOT redo.

## Review-fix wave — SHIPPED (2026-08-02; committed + pushed)
An independent whole-branch review of the last 10 days across all three editions found 9 defects in
the shipped waves and fixed them: canonical/mgd **2.39.4**, Copilot **2.9.4**. Two were functional:
(1) the `/vuln` + `/upgrade` post-`review-fixer` re-review re-used the *pre-fix* `review_diff_file`
(the `/implement` correction from the 2.39.2 follow-up was never carried into the 2.39.3 siblings), and
(2) `/implement`'s two `test-writer` dispatches embedded the `mktemp` + `git diff` capture **inside**
the agent-facing prompt unbracketed — `test-writer` has no `Bash`/`bash` tool, so it could not comply
(now an orchestrator step recorded as `test_diff_file`). The rest: dispatch brackets holding
instructions instead of values (`/vuln` ×2, `/upgrade` ×1), `/vuln`'s SIMPLE/MODERATE
regression-resume left on "verbatim", `context-management.md` missing the load-bearing
"`mktemp` outside every repo working tree" guard, both `handoff/` docs describing the report/plan as
inline-only, the `risk-planner` ID example in `[AC-3]` instead of `[AC03]` form, and — Copilot only —
two long-standing conversion gaps: the never-ported `phase: regression-resume` directive in
`vuln-fixer` + `upgrade-executor`, and 16 Claude tool names (`Read`/`Write`/`Glob`/`Grep`/`LS`) in
prose that edition never grants. Verified: `claude plugin validate` clean (both Claude repos),
canonical↔mgd byte-identical outside the 5 expected files, handle counts match canonical↔Copilot.
Both this wave and the pre-existing-issue wave below were squashed into one commit per repo and
pushed: canonical `2d20bd2`, mgd `4b78b34`, Copilot `2b54f94`.

## Pre-existing-issue wave — SHIPPED (2026-08-02; committed + pushed)
Same session, after the user asked for older defects too. Six more, all older than the reviewed window:
- **Dead `LS` tool entry** in every `allowed-tools` / `tools` list (50 dev-workflows files per Claude
  edition + `managed-docs`' spec-planner + the `/ready` prose). Verified against the shipped Claude Code
  **v2.1.218** binary: zero occurrences of `"LS"`, and the legacy alias map is
  `{Task:"Agent", KillShell:"TaskStop", KillBash:"TaskStop", AgentOutputTool:"TaskOutput", …}` with no
  `LS` entry. Unmatched entries are dropped silently, so the lists worked — but a `tools` list whose
  entries *all* fail to match makes the Agent tool refuse to launch. **`Task` was kept** — still a live
  alias for `Agent`.
- **Stale `/impl:jira:docs` / `/impl:jira:epics` / `/impl` / `/impl:docs` command names** plus a
  non-existent "Phase 6.7", in `dt-style-guide/README.md` + `agents/dt-style-checker.md` (all three
  editions) and `managed-docs/commands/process-managed-doc.md`. Corrected to `/document` (Jira mode)
  **Phase 6.4** and `/epics` **Phase 6.2**, with the mechanism restated accurately (`docs-style-checker`
  runs the primary linter *and* `dt-style-checker` internally, merging both finding sets).
- Copilot marketplace: `obsidian-llm-wiki` entry had no `homepage` (only entry missing it).
- Copilot manifests: "Thirty-one dispatched sub-agents" and a `README.md` tree saying "30 sub-agents"
  where there are 32.
- `plugins/acli/plugin.json` `"skills": ["./skills"]` removed — the default `skills/` scan is always
  performed and the `skills` field only *adds* to it, so the entry registered the directory twice and
  diverged from every sibling plugin.
- mgd `dev-workflows/README.md` agent-table row order realigned to canonical (`idea-reader`).

Versions: dev-workflows **2.39.4** (canonical+mgd) / **2.9.4** (Copilot); dt-style-guide **0.2.4** /
**0.3.3**; acli **0.1.1** (Claude); managed-docs **0.1.1**. All `claude plugin validate` clean; all 12
marketplace↔plugin.json versions in sync; canonical↔mgd dev-workflows byte-identical outside the 5
expected files. Committed and pushed together with the review-fix wave above (canonical `2d20bd2`,
mgd `4b78b34`, Copilot `2b54f94`).

### RETRACTED finding — do not "fix" this
An earlier pass in this session flagged "18 unconverted `/slash-command` names" in the Copilot
`skills/_shared/docs-grounding.md`, `agents/docs-grounder.md`, and `skills/upgrade/README.md`, and by
extension the ~126 `/wiki-*` and ~20 `/dt-*` names in the other Copilot plugins' READMEs. **That was
wrong.** Copilot CLI registers every user-invocable loaded skill as a slash command — verified in the
CLI 1.0.74 bundle: `getLoadedSkills().filter(n=>n.userInvocable && …).map(n=>({name:`/${…}`, isSkill:!0,
skill:n}))`. `/wiki-init`, `/dt-review-pr`, and `/idea` are all valid invocations there. The dev-workflows
edition additionally documents a keyword form (`idea:`) via each skill's description; both work. Left
untouched deliberately.

**Copilot tool-name convention (verified against the shipped CLI, 1.0.74):** this edition declares the
CLI's own concrete tool names (`view`, `glob`, `grep`, `bash`, `create`, `edit`, `task`, `web_fetch`),
confirmed in the CLI bundle (`R_="view"`; `grepToolName??"grep"`, `globToolName??"glob"`,
`shellToolName??"bash"`; `["str_replace_editor","create","edit","insert","apply_patch"]`). GitHub's
`custom-agents-configuration` docs additionally define a portable *alias* layer
(`read`/`edit`/`search`/`execute`/`agent`/`web`/`todo`, case-insensitive, with `Read`/`Write`/`Grep`/
`Glob`/`Bash`/`Task` as compatible aliases). Both work on the CLI; the concrete names are kept for
consistency across all 32 agents. Switch to the alias layer only if this edition ever needs to run on
GitHub.com cloud agent or in an IDE as well.

**`acli` is intentionally opensource-only** (confirmed 2026-08-02): the Dynatrace side uses the
PII-scrubbing `acli-pii` (`cli-for-atlassian-proxy`), which cannot ship in a public repo — so the
opensource marketplaces carry plain `acli` instead. The 1:1 ihudak→mgd rule does **not** apply to this
plugin; do not "fix" the absence.

## Audit-residue + branch-naming wave — SHIPPED (2026-08-04; committed + pushed)
A full re-audit of every plan/design in `docs/superpowers` against the shipped plugins, plus a
three-edition port-parity sweep, found **zero functional gaps** — every plan, design, and recorded
deferral traces to a shipped artifact, all 12 marketplace↔plugin.json versions were in sync, and
`claude plugin validate` passed. Seven cosmetic residues were found and fixed:
- **Two dead `LS` tool names** the 2.39.4 sweep missed, in inline Agent-dispatch prose
  (`commands/document.md` Phase 10, `commands/implement.md` Phase 2A) — canonical + mgd only; the
  Copilot edition already read `view/glob/grep`. → folded into dev-workflows **2.40.0**.
- **Copilot `skills/_shared/branch-naming.md` was documented but never wired.** The `$GIT_USER_INITIALS`
  prefix ladder had shipped since Copilot 1.6.0 and both `README.md` and the CHANGELOG described it as
  live policy, but no skill loaded it — every branch-creating workflow silently used its own inline
  `git branch -a` sniff, so the env var had no effect. **An earlier pass in this session deleted the
  file as dead; that was wrong** — the user relies on the feature. Instead it is now genuinely wired
  into all five branch-creating orchestrators in **all three editions**, and promoted to a first-class
  feature: new canonical/mgd `references/branch-naming.md`, consumed by `/implement`, `/document`
  (both modes), `/docs-profile`, `/upgrade`, and `/vuln` (via `vuln-fixer`). Two latent defects in the
  policy fixed at the same time: §1.3 inference rejected **hyphenated** initials (`^[a-z0-9]+$` vs
  §4's `[a-z0-9-]`), so `iv-gu/…` branches were invisible to it; and §1.5's mandatory
  "no prefix detected" prompt was never implemented — now registered in `escalation-rules.md` as
  "Branch prefix undetected". `/docs-profile`'s ad-hoc `git config user.name` initials derivation was
  replaced by the shared ladder. `GIT_USER_INITIALS` is now documented in both repo-root READMEs.
  → dev-workflows **2.40.0** (canonical + mgd) / **2.10.0** (Copilot) — MINOR, not PATCH.
- **mgd carried two stray plugin-embedded planning docs** (`plugins/dev-workflows/docs/{plans,specs}/
  2026-07-17-update-vi-*`) with no canonical counterpart. `git mv`-ed to mgd's repo-root
  `docs/superpowers/`, restoring strict plugin 1:1. Canonical's empty `plugins/dev-workflows/docs/`
  tree removed too.
- **28 design docs carried pre-implementation `Status:` headers** (`pending implementation`,
  `approved-for-planning`, `awaiting spec review`, …) though the features verifiably shipped. Each now
  reads `Shipped in dev-workflows v<X.Y.Z> — pre-implementation design snapshot, kept as authored`,
  with the version cross-checked against the CHANGELOG entry that introduced it (two, where no version
  could be pinned with evidence, say `Shipped` without one). Bodies untouched.
- **This file claimed the last two waves were uncommitted with pushes held** — they were committed and
  pushed on 2026-08-02; corrected above.
- **Copilot `wiki-tags-refresh` omitted its `[directory]` argument** from the invoke line (the body
  already scanned it) and had lost the `-print0` rationale note. → obsidian-llm-wiki **0.3.4**.
- **Dangling tracker pointer `dev-workflows-next-efforts`** (a memory that does not exist) in
  `2026-07-07-two-key-grammar-foundation-design.md` ×2 and `2026-07-07-design-command.md` ×1 →
  repointed at `docs/superpowers/harvest/NEXT.md`, which superseded it.

Verified: `claude plugin validate` clean (both Claude repos), all 12 marketplace↔plugin.json versions
in sync, canonical↔mgd dev-workflows byte-identical outside the 5 expected files, zero `LS` outside
CHANGELOG history, and `branch-naming.md` reachable from all five branch-creating orchestrators in all
three editions (grep-proven, no orphan). Passed an independent whole-branch review over all three
diffs (READY TO MERGE; 10/10 hard invariants PASS, 2 NITs fixed — the `[a-z0-9-]` first-character
restriction is now stated in §1.5/§4 and `escalation-rules.md`, and §2's `implement`/`document`
doc-edit slug rule was aligned with the commands' own wording). **Merged to `main` + pushed.**

## Branch-naming repo-rule-first wave — SHIPPED (2026-08-04; committed + pushed)
The 2.40.0/2.10.0 branch-naming feature had the priority backwards. It made the `$GIT_USER_INITIALS`
ladder the **primary** mechanism, while only `/document` and `/docs-profile` ever read the target
repo's own documented convention — so `branch-naming.md`'s claim that a repo-documented pattern
"outranks this ladder" was **unenforceable** in `/implement`, `/upgrade`, and `/vuln`, which never read
those files. (Same class of defect as the orphaned Copilot file it replaced: policy documented, not
wired.) The user's intent: the repo's own `CONTRIBUTING.md` / `README.md` rule is the source of truth,
and initials fill an identity placeholder **only where the rule has one** — as `dynatrace-docs` does
(`<your-name-or-initials>/<JIRA-ISSUE-KEY>-<short-branch-name>`, `CONTRIBUTING.md` §Branch name).

Inverted and closed in all three editions: every branch-creating orchestrator now reads the repo's
guidance files **first** (§1.1), classifies the documented pattern's segments (§1.2), and fills each
from its proper source — identity from the ladder (now §2), issue key from the run's resolved Jira key,
description from each command's own slug rule (§3). A pattern with **no** identity segment never gets
one (a `feat/<slug>` repo still yields `feat/add-oauth`, not `iv-gu/…`); identity inference ignores the
generic prefixes; and the §2.5 escalation drops its generic-fallback choice when an identity is being
filled. The ladder supplies the whole prefix only when a repo documents no convention at all (§1.4).
`/implement` prefixes a resolved Jira key to its slug when the chosen shape has no key segment.
Passed an independent whole-branch review (READY TO MERGE; 12/12 criteria PASS incl. an end-to-end walk
of the dynatrace-docs case → `iv-gu/PRODUCT-17753-add-oauth`, and the no-identity case → `feat/…`;
1 NIT fixed — `DOCUMENTATION-GUIDELINES.md` added to canonical `/vuln` + `/upgrade` inline lists for
cross-edition parity). Versions: dev-workflows **2.41.0** (canonical + mgd) / **2.11.0** (Copilot).

## Harvest round 2 — "verify what you assert" — ON BRANCH ONLY (2026-08-21)
Second harvest from the same four upstreams (BMAD-METHOD, github/spec-kit, obra/superpowers,
mattpocock/skills), surveyed against the 2026-07-29 baseline. 383 upstream commits in the window; four
Tier-1 items adopted, all converging on one rule stated once and applied at three stations: **do not
act on, report, or accept a claim you have not verified against the thing it names.** Spec + plan:
`docs/superpowers/specs/2026-08-21-upstream-harvest-round-2-design.md` and
`docs/superpowers/plans/2026-08-21-upstream-harvest-round-2.md`.

What shipped on the branch (canonical only so far):
- **Item 1 — the read-failure contract** (`references/context-management.md`, new `## The read-failure
  contract` section). Every input a caller may hand over "inline or as an absolute file path" resolves
  into one of two tiers, fixed by the consuming agent where it takes that input, never at runtime:
  an unreadable **evidence** input is a hard stop that is **never** regenerated by other means (a resume
  that re-derives its own input is the failure the contract exists to prevent); an unreadable **context**
  input degrades to absent and the output records the degradation. Stated by six agents — `risk-planner`,
  `code-review`, `test-writer`, `review-fixer`, `vuln-fixer`, `upgrade-executor`. `status: BLOCKED` is
  consumed on the `/vuln` and `/upgrade` resume paths; `/implement` states `NEEDS HUMAN` at the call site.
- **Item 2 — orchestrator triage** (new `references/finding-triage.md`). Between an Opus reviewer's
  findings and a fixer's edits: verify each finding's own claimed consequence at the location it names,
  keep or dismiss, record every dismissal with a reason that disposes of that finding's own claim, hand
  the fixer survivors only. Run by the **orchestrator**, never the fixer — a dismissal must not sit at a
  weaker station than the Opus reviewer that produced the finding. Carries the patch gate (never a fix
  that guards state the finding did not demonstrate) and a reporting contract (a triage that reports only
  survivors is indistinguishable from a reviewer that found less). Wired into all five reviewer-fed paths
  — `/implement`, `/vuln`, `/upgrade`, `/document` (Jira mode), `/epics` — plus a `### Review triage`
  report section in each, and patch gates in `review-fixer` + `doc-fixer`. **Never** attaches to a
  style-checker-fed `doc-fixer` dispatch: a linter violation is not a claim about consequence.
- **Item 3 — claims falsification.** `code-review`, `doc-reviewer`, and `epic-reviewer` each gained an
  optional `claims_file` input and a final conditional dimension read **only after every other dimension
  is complete** — the deferral is what makes the falsification independent, and it is bought structurally
  (a path, read late) rather than by instruction. Dimension counts 10→11, 17→18, 18→19. Wired in five
  commands; in `/vuln` and `/upgrade` the fixer/executor output was **relocated** out of the inline
  review brief so it is named once, as `claims_file` — content left in both places would defeat the
  deferred read while appearing to implement it.
- **Item 4 — instruction-file maintenance** (new `references/instruction-file-maintenance.md`), cited by
  `impl-maintenance` and binding on hand edits: verify every command claim against the thing that runs
  it; a rewrite that narrows a rule is a deletion and is itemised separately; a pointer names an
  observable trigger, never one the agent must judge; two live contradictory instructions is a defect;
  retirement needs grounds, never "it looks derivable" and never "nothing has failed on it lately".

Also corrected en route (pre-existing drift, deliberately bounded — §10.3): the README agent table
claimed `code-review` had 8 dimensions (it already had 10) and `epic-reviewer` 9 (it already had 18).

**State as of this entry — read before assuming anything is done:**
- Canonical branch `iv-gu/upstream-harvest-round-2`, commits `5e66c6c` (the plan) through this one.
  **Not merged, not pushed.**
- **Not ported.** mgd and Copilot have not been touched (plan Tasks 8–9). Copilot is hand-adapted only —
  never `cp`; and its `epic-reviewer` README row carries **no** dimension count, so do not import
  canonical's.
- **Not versioned.** The round *targets* dev-workflows **2.54.0** (canonical + mgd) / **2.24.0**
  (Copilot), but at the time of writing `plugin.json` and `marketplace.json` still read **2.53.2** and no
  `CHANGELOG.md` entry exists in any edition. Plan Task 10 owns the bump and the three changelog entries.

## NEXT: harvest items 5–7 — named backlog, NOT rejected
These three were surveyed on 2026-08-21 and **deliberately left out of round 2**, for one reason only:
round 2 was scoped to a single discipline — verify what you assert — and these three are a different
kind of change. They were **not** considered and rejected, they are **not** covered by anything round 2
shipped, and they are not on the "Rejected on merits" list below. A later round must not read their
absence as a verdict. Source: round-2 design §1.1 and §12.

- **Item 5 — `references/bug-diagnosis.md` has drifted from its mattpocock source.** Missing a
  `## Redact` section, and missing the completion criterion "name one command you have already run, and
  show its output".
- **Item 6 — "design it twice" for `/design`.** Three parallel sub-agents under different interface
  constraints, compared on depth / locality / seam placement; plus `DEEPENING.md`'s four dependency
  categories for `design-format.md`'s `## Seams`.
- **Item 7 — subagent-dispatch bounds** for the three agents that hold `Task` (`docs-style-checker`,
  `upgrade-executor`, `vuln-fixer`), and the Claude-only half: reviewers must return findings as text,
  never through a host findings-reporting tool.

### Recorded upstream divergences — decisions, not gaps (2026-08-21)
Both are deliberate. Do not "resync" either one without a fresh decision.
- **superpowers has reversed the plan-conflict rule** this plugin imported from it in July
  (`review-fixer`'s `DEFERRED — plan-conflict`), in favour of "rule and record". We keep our version:
  our commands run with a human present.
- **mattpocock's `grilling` has moved fully to round-by-round frontier batching.**
  `references/grilling-technique.md` continues to reject that for the authoring commands, which stay
  one-question-at-a-time.

**Rejected on merits (revisit only if asked):** CLI/template scaffolding, `constitution`, governance
presets, SDD ledger / 5-round fix-breaker, generic lens engine, git-push-blocking hook, PRD-coach
"never recommend an answer", batch-grill-me denser rounds. (See INDEX.md "Deliberately NOT adopting".)

## Standing constraints (still apply for any new work)
- PUSHES HELD for explicit user confirmation. Commit trailer names **the model that did the work**, not
  whatever a previous round used: `Co-Authored-By: Claude <model> (1M context) <noreply@anthropic.com>`.
  Waves through 2.41.0 used `Claude Opus 4.8 (1M context)`; harvest round 2 used
  `Claude Opus 5 (1M context)`.
- Do NOT edit `references/specification-format.md` (frozen snapshot).
- mgd push bypasses a PR-required branch rule (user: "ok for now").
