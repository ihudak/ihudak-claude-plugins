---
name: release-notes
description: Release-notes drafting. Reads the resolved Product Requirements Document from exported markdown, optionally grounds in PR diffs, renders an example-docs release-notes body, runs a light prose-style-checker gate, and writes a persistent draft to publish wherever release notes are published.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Draft release notes for the resolved PRD: $ARGUMENTS

`/release-notes` produces a **customer-facing release-notes draft** for a resolved
Product Requirements Document (or any ticket) from pre-exported markdown in the user's Obsidian vault.
It optionally grounds the prose in merged PR diffs, renders the example-docs authored
release-notes body — a plain **Category:** label + `### title` + prose for the `feature-updates` /
`breaking-changes` destinations, or one bare past-tense sentence for `fixes` — with **no
`{{#internal-note}}`, no identifiers, no PR links** (the docs automation adds the metadata
wrapper), runs a light style gate, and writes the draft to a persistent destination for the
user to paste wherever their release notes are published.

Usage: `/release-notes <ADDRESS> [--version <v>] [--no-docs]`, where `<ADDRESS>` is a key or an
`@<path>` naming a folder in the specs tree.

- **`--version <v>`** (optional) — the release this note belongs to. Absent, the grill asks once;
  declined, the draft omits it. Never invented.

For full feature documentation use `/document`; for Epic drafting use `/epics`.

This command makes **zero external API calls** and **never writes into the docs repo**.

---

## Phase 0 — Load

1. **Resolve the address.** Parse the **single positional address** from `$ARGUMENTS` — a `<KEY>`, or an `@<path>` naming a
   folder or a file inside one — and resolve it with `resolve-address`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3). Carry the resolved `path`, `kind` and
   `key` forward; `absent` → the folder does not exist; `ambiguous` → stop, naming every match.

   With no positional address, stop with
   `RELEASE_NOTES_NEEDS_KEY: /release-notes needs a PRD or Epic address — a key, or an @<path> to its folder.` —
   this command has no direct-prompt behavior.

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

---

## Phase 1 — Clarification

**Rule: Ask, don't guess.** Group questions; use `choices` arrays; the last choice MUST be `"Other… (describe)"`.

- **Diff grounding** (default OFF — the PRD is usually enough for release notes):
  ```
  choices: ["PRD content only (Recommended)", "Also ground in merged PR diffs (you'll pick repos)", "Cancel", "Other… (describe)"]
  ```
  If "ground in PR diffs", additionally ask the two sub-questions below.

- **Repos search base (`$REPOS_PATH`)** (only if diff grounding is ON). Read `${REPOS_PATH:-/workspace}`; may be a colon-separated list. Ask:
  ```
  choices: ["Use $REPOS_PATH (default /workspace) (Recommended)", "Use a different path (you'll be prompted)", "Cancel", "Other… (describe)"]
  ```
  Clones are located in Phase 4 by matching `git remote` against each PR's repo slug — not by assuming a `<base>/<slug>` directory name.

- **PR status filter** (only if diff grounding is ON):
  ```
  choices: ["MERGED only (Recommended)", "All PRs (MERGED + OPEN + DECLINED)", "Specific list (you'll be prompted)", "Other… (describe)"]
  ```

- **Output destination — derived, not asked.** The draft lands in **`release-notes.md` in the
  resolved PRD folder**, appended as a section. There is one home now, so the destination question
  and its old fallback ladder are gone.

  **The three former destinations are three sections of that one file**, selected by Change Type
  exactly as they selected a file before: `## Breaking changes`, `## Feature updates`, `## Fixes`.
  The taxonomy is unchanged and `${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md` remains its
  authority — only where a draft lands changed.

  **The release version is the section heading**, under which those three sit:

  ```markdown
  # Release notes — ACME-77 billing

  ## 1.24.0

  ### Feature updates
  …
  ```

  Exactly one Summary per run, appended under the resolved version and type. A run whose version the
  operator declined appends under `## Unreleased`.

  **NEVER write into a docs repo, a code repo, the vault, or the current working directory.** The PRD
  folder is in `$SPECS_PATH`, which is where the terminal `commit-artifacts` step commits it with the
  rest of the run's artifacts.


- **Style check** (default ON when the `prose-style` plugin is installed):
  ```
  choices: ["Run prose-style-checker then apply safe fixes (Recommended)", "Run prose-style-checker, report only (no auto-fix)", "Skip style check", "Other… (describe)"]
  ```

Also display: the resolved PRD folder, its `key`, `$REPOS_PATH` (or "N/A — PRD-only"), and the version this draft will be filed under.

---

## Phase 1.5 — Classify

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`), then classify the task. Release-notes drafting is **MODERATE** (bounded prose synthesis from a single ticket; no Opus planning or review gate). State the classification and a one-sentence reason.

---

## Phase 2 — Worthiness check + plan/approval

1. **Worthiness gate.** Read `relevant_for_release_notes` directly from the **imported PRD frontmatter**
   under `prd_dir` (this phase runs before Phase 3, so the folder has not been read yet,
   and the folder read does not surface this field in any case). NEVER read it from the authored specs
   draft.
   - **`false` / `no`** → stop:
     `RELEASE_NOTES_NOT_RELEVANT: <KEY> is flagged not relevant for release notes; the PRD's status rule does not require one.`
     Offer an override for drafting ahead of the flag:
     ```
     choices: ["Cancel — nothing to draft (Recommended)", "Draft anyway — I'll set the flag later", "Other… (describe)"]
     ```
   - **`true` / `yes`** → proceed.
   - **absent** → **proceed silently.** The field defaults to true; absent is not false.

   `release_versions` plays no part in this gate.

2. **Plan.** Before presenting the plan, run `resolve-docs-grounding release-notes` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` — this is the run's only consent-bearing step (an index build or a capped refresh), so it must resolve here, before Phase 3's the folder read and Phase 4/5's diff resolution do any of the run's real work. Present: resolved `key`, destination, diff-grounding on/off (+ `$REPOS_PATH` and repos to scan when on), style-check choice, and the `docs grounding:` line that `resolve-docs-grounding` returned, verbatim — including its `retrieval:` value and any index-build, staleness, or shadowing clause (off switch: --no-docs). Ask:
   ```
   choices: ["Approve & continue (Recommended)", "Revise plan", "Cancel"]
   ```

---

## Phase 3 — Read the PRD folder

Invoke the folder read. Use `depth: prd-only` when diff grounding is OFF; `depth: full` when ON (to collect PR URLs from the hierarchy's `## Pull Requests` sections).

**Read the resolved folder directly.** Read its `prd.md` for the product content.

**Resolve the diff sources — two of them, merged.** **Only when diff grounding is ON** (Phase 1): it is opt-in and advisory here, so a run that declined it skips this step entirely and grounds its prose in the PRD alone. When it is on, follow
`${CLAUDE_PLUGIN_ROOT}/references/implementation-format.md` §4:

1. **The record.** Read `implementation.md` in the resolved folder. **Read only the blocks appended since the last section was written to `release-notes.md`** — a second release must not re-describe the first one's work, and with no imported release field that file's own last-written date is the only honest boundary. **Name the blocks this run used**, so a wrong boundary is visible rather than silent.
2. **The scan.** For each repository — those `implementation.md` names, or, when it names none, the
   repositories resolved from `$REPOS_PATH` — search commit messages for the identifiers this run
   already holds:

   ```
   git -C <repo> log --grep='<key>' --grep='<workitem_key>' --extended-regexp --regexp-ignore-case
   ```

   The keys come from the resolved folder's own `key:` and its `workitem_key`; **nothing is parsed
   out of a commit message.** This is what finds work the plugin did not do — a commit written by
   hand after a session ended, a colleague's push, a follow-up nobody ran a command for.

**Merge and dedupe by SHA.** Anything the scan finds beyond the recorded blocks is reported as
**unrecorded work**, named as such with its commits listed: folding hand-made commits silently into
the recorded set would make the record look more complete than it is.

**Report the scan's own reach.** Say **how many commits it scanned and how many matched**. Only a
commit whose message names the key is findable, and no convention compels a human to follow one — so
a zero-match scan in a repository that has commits is a signal about the commit convention
(`docs/reference/commit-convention.md`), not proof that no work happened.

Hand each resolved ref to `diff-summarizer` as a `{repo_path, branch_from, branch_to}` triple — a
shape its Inputs already declare, on the pure-local-git path it prefers when `gh` is absent. No URL,
no host classification, no `gh` requirement.

  >
  > prd_dir: [resolved prd_dir]
  > key:         [resolved key]
  > depth:      [prd-only | full]"

When `focus_key` is set (explicit `<PRD> <Epic>`), scope the **Phase 6 render input**
to the focus Epic's subtree — the focus Epic plus its linked descendants — so the
release note covers that Epic's user-facing changes rather than the whole PRD. This
scopes only what Phase 6 renders; it does not mutate the stored handoff that other
phases read. When `focus_key` is null, the draft covers the whole ticket/PRD exactly as
today.

If `status: NOT_FOUND` / `EMPTY`, surface `["Re-enter key", "Cancel"]`.

Capture `change_type` and `release_notes_category` from the resolved folder's `prd.md`, where it
carries them (null when absent). **Read them from the PRD, which is the reversal**: these were
dropdowns set outside the plugin and returned by an import, so this step used to read the import and
was told explicitly *not* to read the authored PRD. Nothing returns them now, and the PRD is the only
place either can come from (`${CLAUDE_PLUGIN_ROOT}/references/prd-format.md`).

**`release_versions` — `--version <v>`, else ask.** The flag takes the release this note belongs to.
Absent, the grill asks once; declined, the draft omits it. **Never invent one.** It is not parsed
from anything, because nothing supplies it.

---

## Phase 4 — Resolve repos (only if diff grounding is ON)

Build a slug→clone map: for each top-level directory under each entry of `$REPOS_PATH`, run `timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, strip a trailing `.git`, and take the URL's last path segment as the clone's slug. Resolve each in-scope PR repo slug against the map: one match → use it; multiple → auto-prefer basename ending `-repo`, then `_repo`/`_fast`, then alphabetically last; zero matches → escalate:
```
choices: ["Skip and continue without its PRs", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]
```

---

## Phase 5 — Diff summarisation (only if diff grounding is ON)

Spawn `diff-summarizer` in batches of up to 4 concurrent agents per Agent message, passing each resolved absolute `repo_path` plus `repo_url_slug` and the PRs filtered to that repo. Collect the outputs into a `diff_summaries` array.

**Per-repo summarizer status.** Handle each returned status before continuing:

- `OK` / `PARTIAL` / `NO_PRS_RESOLVED` — use the result; record unresolved PRs in the run report.
- `REPO_MISSING` — escalate per the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
- `DIRTY_TREE` — escalate per the `Dirty working tree` rule in the same file.
- `REFRESH_BLOCKED` — escalate per the `Refresh blocked` rule in the same file.
- `prep.read_only: true` — not a failure. Resolution ran at `prep.scanned_ref`. Escalate per the `Read-only mount — ref stale or diverged` rule **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`; otherwise proceed silently.

Diff grounding is opt-in and advisory here: a repo the user skips degrades the grounding, never the run.

---

## Phase 5.5 — Documentation grounding dispatch (optional)

`docs_grounding` was already resolved in Phase 2 — consume that cached result here; never re-run `resolve-docs-grounding`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the ticket goal + release themes, `key` = `key`. Carry the digest into Phase 6 with **writer-attach** consumption. When OFF, skip silently. (Independent of diff grounding.)

---

## Phase 6 — Render the draft

**Resolve `run_phase`.** `/release-notes` runs at two points in a PRD's life, and the
`release-note-types.md` §4 documentation-link rule depends on which. Reuse the existing signal from
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` §7 — resolve the PRD's specs dir
by calling `resolve-address <KEY>` (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §3), then glob it for `specification.md` and `design.md`. That entry point searches every level §3 bounds and carries §5's legacy fallback; §7 records why this command is one of its adopters.
A flat glob alone would also be **narrower than the signal this step says it reuses**: §7 defers to
the specs-dir matching `feedback-emission.md` and `followup-emission.md` perform, whose pattern
already spans both levels.

- **neither present** → `run_phase: pm`. The feature is not built and its documentation does not
  exist yet, so the note carries no documentation link and the command never asks for one.
- **either present** → `run_phase: dev`. The author may supply a redirect short link that will later
  point at the page `/document` publishes.
- **`$SPECS_PATH` unset or the dir missing** → `run_phase: pm` (the safe default — it only suppresses
  a link, never fabricates one).

This is the same inference `emit-cost` already applies in Phase 11; do not add a question for it.

→ Agent (subagent_type: "dev-workflows:release-notes-writer"):
  > "Render the release-notes draft for this brief:
  >
  > folder_read: [the Phase 3 handoff — scoped to the focus Epic's subtree when focus_key is set]
  > diff_summaries:      [the Phase 5 array, or omit when diff grounding was off]
  > docs_grounding:      [the Phase 5.5 digest, or omit when OFF/EMPTY]
  > imported_change_type:            [from Phase 3, else null]
  > release_notes_category: [from Phase 3, else null]
  > run_phase:           [pm | dev — resolved immediately above, in this phase]
  > model_routing:       [the block from Phase 1.5]
  > code_repos:          [the Phase-4 resolved {slug, path} map when diff grounding is on; omit otherwise]"

If `status: PARTIAL`, surface each `gaps` entry with `recommended_action: "ask user"` and let the user supply the label/prose or accept a `<!-- TODO -->` marker.

For a `field: change_type` gap, the destination was inferred with low confidence — and the
destination decides the draft's whole shape. Confirm it by **consequence**, never by enum label.
This fires ONLY when `change_type` was null; when the PRD already carries one, no
prompt appears.

State the inference, then ask:

> This note reads like a `<proposed type>`, so the draft is shaped as `<shape>` and lands in
> `<destination>`.

```
choices: ["<proposed type> — <its shape>, in <its destination> (Recommended)", "Feature update — titled section with a docs link, in feature-updates.md", "Breaking change — titled section with remediation steps, in breaking-changes.md", "Fix — one self-contained sentence, in fixes.md", "Other… (describe)"]
```

Drop the option that duplicates the recommended one. Apply the choice to
`release_notes_block.change_type` (Feature update → `New technology support`, Breaking change →
`Breaking change`, Fix → `Bug fix`) + `destination` and **re-render** the draft in the chosen shape —
switching between `fixes` and a titled destination changes the body structure, not just a label. The
chosen value never becomes text in the draft.

For a `field: deprecation_eol` gap (a deprecation was detected but the required
end-of-life date is unclear), ask the user:
```
choices: ["Enter the end-of-life date (you'll be prompted; end-of-support optional)", "Leave the <!-- TODO: end-of-life date --> marker in the draft", "This isn't a deprecation — drop the note", "Other… (describe)"]
```
On a supplied date, replace the `<!-- TODO: end-of-life date -->` placeholder with the
end-of-life date (and end-of-support date when given), formatted per the prose-style
(e.g. `November 30, 2026`).

When `release-notes-writer` returns `gaps[]` entries that have `prd_phrasing` and `source_phrasing` (source-truth discrepancies), present the discrepancy table and per-claim prompt as in `/document` (keyed mode) Phase 5.8:

1. Show the analysis table (claim, PRD phrasing, source phrasing, location).
2. Ask:
   ```
   choices: ["Decide per discrepancy (Recommended)", "Document ALL as actual (code)", "Document ALL as intended (PRD)", "Skip ALL and report (drafts a bug report)", "Cancel", "Other… (describe)"]
   ```
3. Apply the decision to the draft prose: `document-as-code` → use source phrasing; `document-as-spec` → use PRD phrasing (no marker in release notes prose — the gap is recorded only in the gaps file); `skip-and-report` → omit the claim.
4. For `document-as-spec` or `skip-and-report`: resolve `bug_report_destination` to the resolved PRD folder. Write/append `<bug_report_destination>/<KEY>-implementation-gaps.md` using the §7.5 format from `${CLAUDE_PLUGIN_ROOT}/references/source-truth.md`, setting `Spec phrasing:` to `(no spec)` (this flow has no spec).

Pass `code_repos` (the Phase-4 resolved map) to the writer when diff-grounding is on.

---

## Phase 7 — Style gate (optional)

If the user chose a style check AND the `prose-style` plugin is installed:

→ Agent (subagent_type: "prose-style:prose-style-checker") on the `combined_rendered` draft (write it to the destination first when the destination is a file, or pass it inline). If violations are returned and the user chose auto-fix:

→ Agent (subagent_type: "prose-style:prose-fixer") to apply safe fixes.

If `prose-style` is not installed, skip this phase and note "style check skipped — prose-style not installed" in the report.

---

## Phase 8 — Write + report

1. **Write** the `combined_rendered` draft to the resolved destination:
   - `file:<path>` → write it. If the file exists, ask: `["Overwrite", "Write to <path>.new", "Print to screen instead", "Skip"]`.
   - `stdout` → include the full draft in the report under `### Release-notes draft`.
   - `skip` → do not write.
   NEVER write into a docs repo.

2. **Report:**
   ```
   ## Release-notes draft — <KEY>
   - Destination: <path | stdout | skipped>
   - Shaped as: <Feature update | Breaking change | Fix> → <destination file>  (source: <imported | inferred>)
   - Category label: <the value | none — omitted from the draft>
   - Deprecation: <EOL <date> (end-of-support <date | —>) | none>
   - Diff grounding: <on (repos: …) | off>
   - Style check: <applied N safe fixes | report only (M findings) | skipped (prose-style absent)>
   - Reminder: paste this wherever your release notes are published — the docs automation adds the {{#internal-note}} metadata and emits it into example-docs.

   ### Next step
   [leaf/closure per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — guidance only, never auto-invoked: the release note is drafted. If earlier pipeline phases remain, continue — hand to PA → `/dev-workflows:create-ard <PRD>` or PE → `/dev-workflows:epics <PRD>`; if the change is already built and documented, the PRD is fully processed.]

   ### Context hygiene

   The resume pointer is written in the terminal cost phase (Phase 11), per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1. Then:

   - **Release note drafted and the PRD fully processed?** → nothing to suggest — you're done.
   - **A PA/PE phase still pending for this PRD (e.g. `/dev-workflows:create-ard`, `/dev-workflows:epics`), even yourself?** → run **`/clear`** before switching roles.
   - Consider **`/rename <PRD-ID>-<slug>-<role>`** to relocate this session later — `<role>` is this run's inferred lane (`pm` on the early run, `dev` once a spec or design exists).

   Guidance only — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.
   ```

---

## Phase 9 — Session maintenance & feedback

Terminal phase — runs AFTER the Phase 8 report is composed; NEVER interrupts
an earlier phase. `/release-notes` has no built-in maintenance agent, so this
phase invokes `impl-maintenance` on the Sonnet detection chain and then
persists the plugin-facing slice of its report as session feedback.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<Sonnet detection chain — claude-sonnet-5, fallback claude-sonnet-4-6 / 4-5>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /release-notes
   > - What was done: [one-paragraph summary of the release-notes draft produced]
   > - Key events: [source-truth discrepancies, PARTIAL renders, style-check failures, ambiguous destinations — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: N/A (light gate only, no Opus review)
   > - Test result: N/A (no tests in /release-notes)
   > - Project root: [the resolved prd_dir or the destination directory]"
2. **Persist plugin feedback (automatic).** Project the report's plugin-facing
   slice into the specs repo by citing
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and calling its
   `emit-auto` entry point (§6). Pass the Lessons Learned report,
   `command: /release-notes`, the run's `key` and `source`, and
   `plugin_version` (read from
   `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-auto` renders only
   the report's **Command workflow improvements**, **New agents / skills**, and
   plugin **Reference docs** sections plus the **Key observations** that
   triggered them (§4) — never target-project `CLAUDE.md`/hook advice — as
   `origin: auto` entries, dedupes by stable `id` (§3), resolves the target via
   the §2 specs-first ladder, and writes silently.
3. **Surface** the persisted path (or "no plugin-facing signal — nothing
   persisted") as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits (still true — this
phase only writes the feedback file; those writes are committed by the terminal
`commit-artifacts` step in Phase 11, per
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), NEVER makes an
external API call, and NEVER writes into a docs repo or the current working
directory.

---

## Phase 10 — Emit follow-up tasks

Terminal phase — runs AFTER the Phase 8 report and the Phase 9 feedback phase;
NEVER interrupts an earlier phase. Persist the run's manual-step follow-ups by
citing `${CLAUDE_PLUGIN_ROOT}/references/followup-emission.md` and executing
its steps inline.

1. **Collect** the qualifying follow-ups: the mandatory manual publish step
   ("paste this release-notes draft wherever your release notes are published")
   and any implementation-gap signals surfaced during the run.
2. **Filter** them with the reference's §6 qualifying predicate.
3. **Resolve** the write target via the §4 ladder using `key` and `source`;
   render + place tasks and verbose notes per §1–§3; dedupe per §5. The task
   references the draft file written in Phase 8 rather than duplicating it.
4. **Preview + confirm** per §7 (`approve-all | select | cancel`), then write.

ADDITIVE — the follow-ups also remain in the Phase 8 report. This phase NEVER
fails the run, NEVER commits (still true — this phase only writes follow-up
files; those writes are committed by the terminal `commit-artifacts` step in
Phase 11, per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §4), NEVER
makes an external API call, and NEVER writes into a docs repo or the current
working directory.

---

## Phase 11 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 10
(follow-ups) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the PRD by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs**.

`/release-notes` runs at two different phases by two roles (a PM's early bare-PRD
run and a dev's documenting re-run), so DO NOT pass a fixed phase/role: call
`emit-cost` with `command: /release-notes`, `phase: inferred`, `role: inferred`,
the run's `key` (or `null`) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-cost` applies the §7
inference: **no `specification.md` or `design.md` under the PRD's specs dir ->
`phase: prd-creation`, `role: pm`; either present -> `phase: documenting`, `role:
dev`.** Epic presence is deliberately NOT part of the signal. It then resolves
the transcript + subagents (§1), **advances the chained checkpoint** (§3), runs
`scripts/session-cost.py` against the price table (§4), records the optional
statusline cross-check (§5), and appends one entry to
`<PRD-dir>/dev-workflows/cost/<sid8>.md` via the specs-first ladder (§8) — pending
+ reconciliation (§9) when no PRD key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

**Then write the resume pointer.** Cite
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 and write/overwrite
`<PRD-dir>/dev-workflows/resume.md` now — after the cost entry above, so the
pointer reflects the completed run, and before the commit step below, so it
is included in it. Redact per §1. Silent; the printed `### Context hygiene`
guidance already appeared in the Phase 8 report.

**Then commit session artifacts (terminal).** Cite
`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`commit-artifacts` entry point (§4) inline — the LAST action of the run. It
stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits
`<KEY> Add dev-workflows session artifacts (/release-notes)`, and pushes per
§4 step 5. It NEVER writes into a docs repo — the release-note draft is
untouched — NEVER touches a code repo, the vault,
or the current working directory; NEVER force-pushes; NEVER fails the run;
and skips entirely when the run carries `specs_git: blocked` (§3.3 G0),
re-emitting that notice. Because the Phase 8 report was composed before this
phase, **print its §6 outcome line here**, as the run's last output — prefixed
`Specs repo:`, with any guard notice repeated in full.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (the
release-notes draft is a plain file for manual publication; the terminal
step above commits only the bounded session-artifact paths in `$SPECS_PATH`),
NEVER makes an external API call, and NEVER writes into a docs repo or the
current working directory; no user name is ever written (§10).

---

## Invariants (always enforced)

- ALWAYS `emit-block` (per `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) before escalating a halt caused by a **plugin / skill / command / reference gap** (a capability the run needed but the plugin lacked) — so a run abandoned at the block still records it. NEVER for a work-quality review BLOCK or an environment / user halt (repo-missing, dirty-tree, key-not-found, cancellation).
- ZERO external API calls — PR URLs are identifiers only; all resolution is local `git`.
- Every read of the specs tree is read-only.
- The draft contains NO identifiers, NO PR links, and NO `{{#internal-note}}` block.
- The draft is EXACTLY one Summary, shaped by its destination per `${CLAUDE_PLUGIN_ROOT}/references/release-note-types.md` §1/§3 — a plain **Category:** label + `### title` + prose for `breaking-changes` / `feature-updates`, or ONE bare past-tense sentence for `fixes`. It carries NO `Change type:` line and NO `Release-notes category:` line, and its **prose** names no release version — the version is the **section heading** the draft is filed under, which is the only thing that says which release a section belongs to now that the three destinations are three sections of one file. The prohibition survives for the body prose alone. When the change deprecates something the Summary carries a deprecation note (end-of-life date required, end-of-support optional).
- The category label IS the PRD's `release_notes_category`, used verbatim; when the import carries none the line is OMITTED. Change Type is sourced `change_type` → infer, and is confirmed with the user ONLY when it was inferred with low confidence — by shape and destination, never by enum label. Neither field is ever asked for by enum label.
- The run is GATED on the imported `relevant_for_release_notes`: an explicit `false` stops with `RELEASE_NOTES_NOT_RELEVANT` (overridable); absent proceeds silently.
- NEVER write into a docs repo; the default destination is persistent (never `/tmp`).
- ALWAYS use `choices` arrays; the last choice is always `"Other… (describe)"`.
- Light gate only — no Opus review, no tests, no branch (still true — `specs-preflight` switches `$SPECS_PATH` only between branches that already exist, and only plugin-created ones (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.2); it creates none), and no commit of the draft or of anything in a docs/code repo, the vault, or the current working directory. The terminal `commit-artifacts` step commits ONLY `$SPECS_PATH`'s bounded artifact paths (`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §2.1).
- ALWAYS run `specs-preflight` at Phase 0 and `commit-artifacts` as the run's last action (per `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`) — bounded to `$SPECS_PATH`'s artifact paths (§2.1) and to plugin-created branches (§2.2), always `git -C "$SPECS_PATH"` and never a `cd` (§1 rule 1), never force-pushing, and never failing the run
- ALWAYS end the Phase 8 report with a `### Next step` recommendation (per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`) — guidance only, never auto-invoked; the pipeline leaf (adaptive: continue any pending PA/PE phase, else the PRD is fully processed).
- ALWAYS end the Phase 8 report with a `### Context hygiene` block per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — prepare-first (the `resume.md` write runs later, in the terminal cost phase, per `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §1 — this block prints the guidance only), then a leaf-aware suggestion (done → nothing; pending role → `/clear`) + `/rename <PRD-ID>-<slug>-<role>` using this run's inferred lane (`pm` or `dev`, per the Phase 6 inference); guidance only, never auto-run.
