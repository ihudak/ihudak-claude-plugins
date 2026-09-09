---
name: docs-brand
description: Extract a logo and a rough primary/accent colour pair from a product's own code and apply them to a documentation site's Material for MkDocs theme. Walks a fixed colour-source precedence (Tailwind config, CSS custom properties, a MUI theme, a web-app manifest, SCSS/LESS variables) and a fixed logo-search order, prints every extracted value with its file and line before applying anything, checks the pair against WCAG 2.2 contrast thresholds, and copies assets into docs/assets/ rather than linking back into the code repo. Runs standalone (branch, commit, drafted PR, never pushed) or --inline from /docs-init, which folds its diff and its contrast finding into that command's own review and PR — a rebrand should never require re-scaffolding the whole site.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Brand the documentation site: $ARGUMENTS

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

`/docs-brand` extracts a logo and a rough primary/accent colour pair from a product's own code and applies them to a documentation site's Material for MkDocs theme. Expectations are deliberately modest: a mark and a colour pair, not a design system. It runs two ways: **standalone**, reviewing its own diff and finishing on a branch with a drafted pull request the same way `/docs-workflows:docs-profile` does; and **`--inline`**, dispatched by `/docs-workflows:docs-init` Phase 5, where it skips its own preflight, its own review gate, its own pull request, and its own emitter tail entirely, and returns its diff plus its contrast finding for the caller's single review and single PR to absorb — rebrands happen, and re-scaffolding a whole docs site to pick up a new logo would be absurd (D14).

**Signature:** `/docs-brand [<docs-repo-path>] [--from <code-repo-path>] [--inline]`

---

## Phase 0 — Resolve and validate

0. **Flags.** Strip `--from <code-repo-path>` (together with the path token immediately after it) and `--inline` from `$ARGUMENTS` wherever they appear, before reading a positional token. Record `inline = true` when `--inline` was present, and `from_repo` when `--from` was. What remains is the optional `<docs-repo-path>`.

1. Execute **`resolve-docs-repo`** from `${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/repo-resolution.md` §1 — the signal-positive form, since branding applies to a site that already exists. Do not restate its ladder here; the entry point owns it. Report which rung answered, per its own hard rule — a command that quietly works in an unexpected directory is expensive to unpick afterwards.

2. **Validate the resolved repo is a writeable git work tree.** `git -C <repo> rev-parse --is-inside-work-tree` must print `true`; if it errors or prints anything else, stop: `DOCS_BRAND_NOT_A_GIT_WORKTREE: <repo> is not inside a git work tree.` `test -w <repo>` must succeed; if not, stop: `DOCS_BRAND_REPO_NOT_WRITEABLE: <repo> is not writeable.` Resolve and record the git root (`git -C <repo> rev-parse --show-toplevel`); all later reads and writes in this run are relative to it.

3. **Validate the repo has something to brand.** At least one of `mkdocs.yml` / `mkdocs.internal.yml` must exist at the resolved root — Phase 7's application is Material for MkDocs-specific (D8), and there is nothing to write a `theme:` block into otherwise. Neither present → stop: `DOCS_BRAND_NOT_MKDOCS: <repo> carries no mkdocs.yml. /docs-workflows:docs-brand's theme application is Material for MkDocs-specific (D8) — scaffold one with /docs-workflows:docs-init first, or point this run at a repo that already has one.`

4. **`--inline` skips the rest of this phase.** The specs-repo preflight below runs for a standalone invocation only — an `--inline` run is a phase of a caller (`/docs-workflows:docs-init`) that already ran its own at its own Phase 0, and running a second one here would be ceremony over the same repo.

**Specs-repo preflight (standalone only).** Invoke `Skill(skill: "workflows-core:reference", args: "specs-repo-git specs-preflight")` and execute its `specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run, retry an artifact commit that failed to push, and settle the branch. This runs against `$SPECS_PATH` only — `git -C "$SPECS_PATH"`, never a `cd`, so the docs repo and the code repo this run reads are untouched (§1 rule 1). Prompt-free and silent when the specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns `specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts` step skips on it. This family creates no branch of its own in `$SPECS_PATH` — its deliverable lives in the docs repo — so this preflight only ever settles a branch that already exists; it never switches onto one this run made.

---

## Phase 1 — Model routing

Invoke the `model-routing` skill (Skill tool, `skill: "workflows-core:model-routing"`), then classify the task.

`/docs-brand` is **MODERATE** — deterministic extraction against a fixed precedence order, applied through a small, templated diff (two MkDocs configs at most, one CSS file, a handful of copied assets). State the classification and a one-line reason.

**The review gate is Opus regardless of class.** The family rule (D17, D20) is that every artefact-writing command in this family passes a high-tier review with no tiering by unit — a MODERATE classification lowers which model plans and executes, never which model reviews. Record a `model_routing` block:

```yaml
model_routing:
  classification: MODERATE
  reason: "deterministic extraction against a fixed precedence order; templated application"
  current_model: <the model this orchestrator is running under>
  review_model: <the §2 Opus chain — claude-opus-5, fallback per §2 — pinned regardless of MODERATE classification, per D17/D20>
  opus_available: true | false
  notes: <any §2 degradation, e.g. "Opus unavailable; docs-scaffold-reviewer fell back to Sonnet 5">
```

Phase 8 dispatches `docs-scaffold-reviewer`, which is already pinned to Opus by its own frontmatter — no dispatch override is needed unless Opus is unavailable, in which case the fallback is announced here and again in the final report.

---

## Phase 2 — Resolve the code repo to extract from

Resolve **one** code repository to read from, in order:

1. **`--from <code-repo-path>`**, when given. Taken as given — the operator (or, on `--inline`, the caller) named it. An `--inline` caller is expected to pass this explicitly, reusing the code repo `/docs-workflows:docs-init` already resolved in its own Phase 2; the rungs below still apply for a standalone run or an `--inline` caller that omits it.
2. **Else the resolved docs-profile's recorded source-repo set** (`.dev-workflows/docs-profile.yml` in the docs repo, when it exists). No shipped profile field records this today, so this rung is currently always a pass-through — it is named here so a later profile field is honoured without a second edit to this command.
3. **Else `ls ${REPOS_PATH:-/workspace}`, one level deep, and confirm with the operator.** The listing is unbounded, so apply `workflows-core:epic-picker` *The cap* (`Skill(skill: "workflows-core:reference", args: "epic-picker")`) rather than rendering one option per entry — the same shape `/docs-workflows:docs-serve`'s own Phase 1 step 3 already uses for an unbounded servable-space list. Print every candidate directory as prose above the prompt, one line each, then:
   - **Three or fewer entries** — the array carries them all: `choices: ["<repo-1> (Recommended)", "<repo-2>", "<repo-3>"]`.
   - **Four or more entries** — the array carries the first three plus the overflow option: `choices: ["<repo-1> (Recommended)", "<repo-2>", "<repo-3>", "Another repo from the list above — name it"]`.

   The typed answer is resolved against the directory names just printed — never parsed out of the free text.

Nothing resolves and the operator declines to name one → stop: `DOCS_BRAND_NO_CODE_REPO: no code repository resolved to extract from (checked --from, the docs profile's source-repo set, and ${REPOS_PATH:-/workspace}). Pass --from <path> explicitly, or mount the product's code repo under $REPOS_PATH.`

Validate the resolved code repo is readable (`test -r <repo>`). It is read **only** — nothing in this run writes into it, and the docs build never reaches into it at build time (Phase 7 step 3).

---

## Phase 3 — Extract colour

Walk this precedence in order; **first hit wins, and the source — file and line — is recorded with it.** Exclude `node_modules/`, `dist/`, `build/`, `vendor/`, and `.git/` from every search below.

1. **Tailwind config `theme.extend.colors`.** `Glob` for `tailwind.config.{js,ts,cjs,mjs}` (repo root, then one level deep). Read `theme.extend.colors`; take the `primary` key if present, else `brand`, else the first key whose name is not one of Tailwind's own neutral-family names (`gray`, `grey`, `slate`, `zinc`, `neutral`, `stone`). A shade object (`{50: …, 500: '#…', 900: …}`) takes its `500` shade — Tailwind's own "base" convention; a flat string value is used as-is.
2. **CSS custom properties matching `--(color-)?(primary|brand|accent)`.** `Grep` `**/*.css` for the pattern with a hex value (e.g. `--primary: #1565C0;`, `--color-brand: #1565c0;`). The first match, by file path, wins.
3. **A MUI `createTheme({ palette: { primary, secondary } })` call.** `Grep` `**/*.{js,jsx,ts,tsx}` for `createTheme(` calls carrying a `palette:` block; extract `primary.main`.
4. **`manifest.json` / `site.webmanifest` `theme_color`.** `Glob` for either filename; read the `theme_color` field.
5. **SCSS/LESS variables matching `$(primary|brand|accent)`.** `Grep` `**/*.scss`, `**/*.less` for `$primary:` / `$brand:` / `$accent:` assignments carrying a hex value.

**Accent is extracted independently**, by the same three rules that name it explicitly — CSS custom properties' `accent` group (rule 2), MUI's `secondary.main` (rule 3), and SCSS/LESS's `$accent` (rule 5) — walked in that order, regardless of which rule supplied the primary. **No explicit accent source found → accent defaults to the primary value.** This is never a silent substitution: Phase 5 confirms it like any extracted value, and states plainly that it is a default rather than a find.

**Light and dark variants are derived from the confirmed primary**, never from accent (the source supplies only one primary value in the ordinary case, per the design's own §7.2): convert to HSL, lift lightness by 15 percentage points (capped at 95%) for the light variant and drop it by 15 points (floored at 10%) for the dark variant, then convert back to hex. State the formula in the report; it is arithmetic, not a design choice, so a reader can check it the way `contrast.md` §2's own worked example is meant to be checked.

**No colour source matches any of the five rules** → ask:
```
"No brand colour was found in <code-repo> (checked Tailwind config, CSS custom properties, a MUI theme, manifest theme_color, and SCSS/LESS variables). How should I proceed?"
choices: ["Enter a primary colour myself", "Skip colour branding — logo only", "Cancel"]
```

---

## Phase 4 — Extract logo

Search, in this order, for logo candidates: `public/`, `src/assets/`, `static/`, any file matching `logo*`, `brand*`, or `icon*`, any `favicon.*`, and every entry of a found manifest's `icons[]`. Exclude the same four directories Phase 3 excludes.

Rank candidates **SVG over PNG over any other format, and — within one format — larger over smaller** (`wc -c`). The top-ranked candidate is proposed; Phase 5 confirms it like any other extracted value, and — when more than three other candidates exist — offers them the same capped way Phase 2 offers a repo listing, so the operator can pick a different one without a five-option array the harness would reject.

**No logo candidate found** → ask:
```
"No logo was found in <code-repo> (checked public/, src/assets/, static/, logo*/brand*/icon* filenames, favicon.*, and manifest icons[]). How should I proceed?"
choices: ["Enter a logo path myself", "Skip logo — colour only", "Cancel"]
```

**Both colour and logo end up absent or declined** → stop: `DOCS_BRAND_NOTHING_TO_APPLY: no colour and no logo to apply — Phase 3 and Phase 4 both came back empty or declined. There is nothing for this run to brand.`

---

## Phase 5 — Confirm (never applies silently)

Print every value Phases 3–4 settled on, each with the file and line (or path) it came from — and, for a defaulted accent or a manually entered value, say plainly that it was defaulted or entered rather than found. Then confirm:

```
"Extracted from <code-repo>:
  primary: #1565C0  (tailwind.config.js:12, theme.extend.colors.primary)
  accent:  #1565C0  (defaulted from primary — no --accent / secondary.main / $accent found)
  logo:    src/assets/logo.svg  (296 KB, ranked over 2 smaller PNG candidates)
Apply these to <docs-repo>?"
choices: ["Apply as shown (Recommended)", "Edit a value before applying", "Cancel"]
```

"Edit a value" re-asks per value as free text — the harness's own escape — and the typed answer becomes the new value rather than being parsed out of anything. A wrong brand colour applied quietly is worse than no branding, which is the whole reason this phase exists as its own step rather than folding confirmation into Phase 7.

---

## Phase 6 — Contrast check

Execute **the thresholds**, **the formula**, and **the adjudication** from `${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/contrast.md` — do not restate them here; the file exists precisely so this command and any later image-contrast check share one copy.

Check the confirmed **primary** and **accent** (never their derived light/dark variants) against `#FFFFFF`, the scaffold's one light background — the scaffold declares no dark colour scheme, so there is no second background to check. Both are checked against the **body-text threshold** (4.5:1): a docs-site primary/accent pair is read as text — link colour, header titles — not merely a decorative fill, which is the "body text" framing the design's own §7.3 uses for exactly this pair. Report each ratio to two decimal places.

For each colour that **fails**:
```
"<label> #<hex> on white measures <ratio>:1 against SC 1.4.3's 4.5:1 body-text minimum — it will read as low-contrast text. Apply it anyway?"
choices: ["Apply anyway — it's the brand", "Choose a different value", "Cancel"]
```

A confirmed failing colour is **still applied** — never silently corrected — and the finding (the ratio, the pair, the criterion) is carried into the Phase 9 PR message and the Phase 10 report. A **passing** colour produces no prompt at all: silence is the pass signal (`contrast.md` §3).

---

## Phase 7 — Apply

Nothing in this phase touches the code repo — every write below lands only in the resolved docs repo, and logo assets are **copied**, never linked, so the docs build never reaches into the code repo at build time.

1. **Theme block.** In every MkDocs config that exists among `mkdocs.yml` and `mkdocs.internal.yml`, set (creating the `theme:` / `extra_css:` keys if absent):
   ```yaml
   theme:
     palette:
       primary: custom
       accent: custom
     logo: assets/<logo-filename>
     favicon: assets/<favicon-filename>
   extra_css:
     - stylesheets/extra.css
   ```
   Apply the **same** block to both configs when both exist — `docs-scaffold-reviewer` dimension 2 (build-config parity) requires the `theme:` and `extra_css:` keys to match between them. Named Material for MkDocs palette colours do not accept hex values, which is the thing that silently does nothing if this step is skipped: `primary: custom` / `accent: custom` is what makes the CSS variables below take effect at all.
2. **CSS variables.** Create `docs/stylesheets/extra.css` if it does not already exist (it does on a repo `/docs-workflows:docs-init` scaffolded); write or update a block:
   ```css
   :root > * {
     --md-primary-fg-color:        #<primary>;
     --md-primary-fg-color--light: #<primary-light>;
     --md-primary-fg-color--dark:  #<primary-dark>;
     --md-accent-fg-color:         #<accent>;
   }
   ```
   Hand edits below this block are preserved; only this block is replaced on a re-run — `scaffold-tree.md` §3.13 already names this file as what a later rebrand reconciles.
3. **Assets.** Copy the confirmed logo (and a favicon, when the source is distinguishable from the logo — e.g. a dedicated `favicon.*` candidate — else the logo doubles as both) into `docs/assets/` under the resolved repo, overwriting the same filename on a re-run rather than adding a new one beside it. This is D16's `in-repo` overwrite-in-place rule, applied here unconditionally: a logo is a persistent brand asset rather than a documentation screenshot on a churn lifecycle, so this step does not read the profile's `images.policy` at all — the design's own §7.3 names `docs/assets/` directly, with no policy branch.

---

## Phase 8 — Review gate (standalone only)

**`--inline` skips this phase entirely.** Its diff and its Phase 6 contrast finding are contributed to the caller's own review instead — `docs-scaffold-reviewer`'s own description states this directly: an `--inline` run "contributes its diff to that command's own Phase 7.5 review rather than running a second one." Everything below is the standalone path.

Dispatch `docs-scaffold-reviewer` — pinned to Opus by its own frontmatter, per Phase 1:

→ Agent (subagent_type: "docs-workflows:docs-scaffold-reviewer"):
  > "Review the documentation-repository scaffold changes from this brief:
  >
  > Task description: [/docs-brand standalone run — theme colours and a logo extracted from <code-repo> and applied to <docs-repo>]
  > Written file paths: [absolute paths of every file Phase 7 wrote: whichever of mkdocs.yml / mkdocs.internal.yml exist, docs/stylesheets/extra.css, and every copied asset under docs/assets/]
  > docs_tree: [Glob docs/** in the resolved docs repo]
  > profile: [the resolved .dev-workflows/docs-profile.yml, or 'absent — this repo carries no profile; images.policy/root/max_bytes defaults assumed (in-repo, docs/assets, 307200)' when none exists]"

**Triage before applying anything** — invoke `Skill(skill: "workflows-core:reference", args: "finding-triage")` and follow it: for each finding, verify its claimed consequence at the location it names; keep or dismiss with a reason that disposes of that finding's own claim; carry survivors only into the next step, and every dismissal into the Phase 10 report. Where triage empties the survivor set entirely on a non-PASS verdict, follow the reference's own disposition — surface it and let the operator settle the verdict; never silently promote it to PASS.

**There is no dedicated fixer for this diff (D17, D25) — the orchestrator applies survivors itself**, editing the named file directly, bound by `finding-triage.md`'s patch gate: fix only a defect a finding actually demonstrated, never guard state it did not show. A survivor whose fix is not a safe mechanical patch is surfaced rather than guessed at:
```
"docs-scaffold-reviewer flagged <finding> as <SEVERITY>, and the fix isn't a safe mechanical patch: <why>. How should I proceed?"
choices: ["Describe the fix yourself — I'll apply it", "Defer — note it in the report, run continues", "Override — accept the finding as-is", "Cancel this run"]
```
A **BLOCKER** left deferred (neither fixed nor overridden) stops the run before Phase 9: `DOCS_BRAND_UNRESOLVED_BLOCKER: a BLOCKER finding from docs-scaffold-reviewer was neither fixed nor overridden — resolve it and re-run.` A BLOCKER that is fixed, or explicitly overridden by the operator, proceeds. MAJOR survivors are applied the same way; MINOR / NIT are deferred to the report without a prompt.

There is no re-review cycle — with no fixer, there is no second pass to gate against: the orchestrator's direct edit is the fix, applied against the same finding it answers, and Phase 9 proceeds once every BLOCKER survivor is resolved or overridden.

---

## Phase 9 — Finish

**`--inline` returns here instead of running any of this.** Its diff (Phase 7) and its contrast finding (Phase 6) are returned to the caller — `/docs-workflows:docs-init`'s own Phase 8 branches, commits, and drafts the single PR for the whole scaffold, this diff included. Nothing below runs on `--inline`: no branch, no commit, no PR, and — see Phase 11 — no emitter tail.

**Standalone** finishes the same way `/docs-workflows:docs-profile` does — branch, commit, draft a PR message, **never push, never merge**:

1. **Resolve the branch name.** When the resolved `.dev-workflows/docs-profile.yml` carries `branch_naming.pattern`, fill its placeholders — the identity placeholder from `Skill(skill: "workflows-core:reference", args: "branch-naming")` §2's ladder, and the issue-key segment takes that pattern's documented no-issue literal, since branding has no ticket. Otherwise use `<prefix>/NOISSUE-docs-brand`, `<prefix>` from the same §2 ladder, fallback `docs/`. Always confirm the final name: `choices: ["Use proposed branch <name> (Recommended)", "Edit the name"]`.
2. **Prepare the working tree.** `git -C <repo-root> status --porcelain`; non-empty → `choices: ["Stash changes and continue (Recommended)", "Proceed anyway — pre-existing changes will appear in the diff", "Cancel"]`. Base the branch on the repo's default branch (`git -C <repo-root> symbolic-ref --short refs/remotes/origin/HEAD`, falling back to `main` then `master`): `switch` + `pull --ff-only`, then create the branch (`switch -c <name>`, or `switch <name>` if it already exists).
3. **Commit.** `git -C <repo-root> add` — only the files Phase 7 wrote or Phase 8 edited — then `git -C <repo-root> commit -m "docs: apply brand colours and logo (docs-brand)"`.
4. **Draft the PR message.** Detect the host (`git -C <repo-root> remote get-url origin`); draft a copy-paste-ready title + body for Bitbucket or GitHub. The body states the extracted values and their sources (Phase 5), the review verdict and every applied or dismissed finding (Phase 8), and — **always, whether it passed or failed** — the Phase 6 contrast findings, so a reviewer sees a confirmed-failing colour before it ships. **Do not push, do not open the PR via any CLI** — present the branch name and the drafted message for the operator to push and open themselves.

---

## Phase 10 — Report

**`--inline` reports nothing of its own** — control returns to `/docs-workflows:docs-init`'s Phase 8, which produces the consolidated report; this run returns straight to Phase 6's contrast finding and Phase 7's diff, no report of its own.

**Standalone** produces:

```
## Docs-brand Report

### Classification
MODERATE — deterministic extraction against a fixed precedence order; templated application (review gate is Opus regardless, D17/D20)

### Source
Code repo: <resolved path>
Docs repo: <resolved path>  (resolved via: <which resolve-docs-repo rung answered>)

### Extracted
- primary: #<hex>  (<source file:line, or "entered manually", or "unchanged — declined to edit">)
- accent:  #<hex>  (<source file:line, or "defaulted from primary">)
- primary-light / primary-dark: #<hex> / #<hex>  (derived, HSL lightness ±15 points)
- logo: <path>  (<why it ranked first, or "entered manually">)
- favicon: <path | "reused the logo">

### Contrast
- primary vs #FFFFFF: <ratio>:1 — <PASS | FAIL, applied anyway — operator confirmed | FAIL, not applied>
- accent  vs #FFFFFF: <ratio>:1 — <PASS | FAIL, applied anyway — operator confirmed | FAIL, not applied>

### Review
Verdict: <PASS | PASS WITH RECOMMENDATIONS | BLOCK, resolved>
Findings: <N reviewed, M survived triage, K applied, J deferred or overridden with reason>

### Branch
<branch name> — <N> commit(s). NOT pushed and NOT merged.

### PR draft (copy-paste)
**Title:** <title>

<body>

### Next step
[leaf/closure per `workflows-core:next-phase-offer` — guidance only, never auto-invoked: once the drafted pull request above is pushed and merged, `/docs-workflows:docs-serve` previews the branded site. This offer carries no `<merge-clause>` — the pull request this run drafted targets the docs repo, not `$SPECS_PATH`, and this family creates no `$SPECS_PATH` branch of its own and runs neither `handoff-to-main` nor `require-on-main` against a docs-repo PR, so there is no downstream gate to name a clause against — the same reasoning `/docs-workflows:docs-serve`'s own closing section gives for the same omission.]
```

---

## Phase 11 — Session maintenance & feedback (standalone only)

**`--inline` skips this phase and everything after it** — the caller's own emitter tail covers the whole run, this diff included.

Terminal phase — runs AFTER the Phase 10 report; NEVER interrupts an earlier phase.

1. **Invoke `impl-maintenance`** (subagent_type: "workflows-core:impl-maintenance", model: `<Sonnet detection chain — claude-sonnet-5, fallback claude-sonnet-4-6 / 4-5>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /docs-brand
   > - What was done: [one-paragraph summary — colour/logo extracted from <code-repo>, applied to <docs-repo>, contrast passed or applied over a finding]
   > - Key events: [a failing contrast confirmed anyway, a defaulted accent, a manually entered value, a deferred or overridden review finding — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: [PASS | PASS WITH RECOMMENDATIONS | BLOCK, resolved]
   > - Test result: N/A (no tests in /docs-brand)
   > - Project root: [the resolved docs repo root]"
2. **Persist plugin feedback (automatic).** Invoke `Skill(skill: "workflows-core:reference", args: "feedback-emission emit-auto")` and call its `emit-auto` entry point (§6), passing the Lessons Learned report, `command: /docs-brand`, `key: null` (this run resolves no PRD/Epic key), `source: none`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). With no PRD dir to match, `feedback-emission.md` §2 rung 2 applies: the entry lands at `$SPECS_PATH/dev-workflows-feedback/<date>.md`, unfiled — still committed, never lost.
3. **Surface** the persisted path (or "no plugin-facing signal — nothing persisted") as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits, NEVER makes an external API call, and NEVER writes into a docs repo, a code repo, or the current working directory.

---

## Phase 12 — Emit follow-up tasks (standalone only)

Terminal phase — runs AFTER Phase 10 and Phase 11; NEVER interrupts an earlier phase. Invoke `Skill(skill: "workflows-core:reference", args: "followup-emission")` and execute its steps inline.

1. **Collect** the qualifying follow-ups: the mandatory manual step ("push `<branch>` and open the pull request"), and any deferred or overridden review finding from Phase 8.
2. **Filter** them with the reference's §6 qualifying predicate.
3. This run resolves **no PRD or Epic folder** — `followup-emission.md` §2's "no folder resolved" rung applies: report-only, kept in the Phase 10 report, with the one-line notice `⚠ No resolved folder — N follow-up(s) kept in this report only.`

ADDITIVE — this phase NEVER fails the run, NEVER commits, and NEVER writes into a docs repo, a code repo, or the current working directory.

---

## Phase 13 — Session cost (standalone only)

Terminal phase — the final operational phase; runs after Phase 12 and NEVER interrupts an earlier phase. Records this command's token-cost contribution by invoking `Skill(skill: "workflows-core:reference", args: "cost-emission emit-cost")` and calling its single `emit-cost` entry point. **Cost ALWAYS runs on the standalone path.**

Call `emit-cost` with `command: /docs-brand`, `phase: docs-scaffold`, `role: dev` — a **fixed** pair (`workflows-core:cost-emission` §7), never `inferred`. **Only the standalone path emits.** An `--inline` run's cost belongs to `/docs-workflows:docs-init`'s own entry; emitting a second time would double-count one run, which is exactly why Phases 11–13 are skipped there rather than run with a key-less variant of the same call. Pass `key: null`, `source: none`, and `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). With no PRD dir, `cost-emission.md` §8 rung 2 applies: the entry lands **pending**, at `$SPECS_PATH/dev-workflows-cost/pending-<date>-<sid8>.md` (§9) — reconciled automatically into a PRD directory later, if this session or a future one ever resolves one. Documentation work on a docs repo alone often never will; that is the gap the design's own D19 names for a later increment's dedicated per-docs-repo bookkeeping rung to close, not something this task adds.

**Then write the resume pointer.** Invoke `Skill(skill: "workflows-core:reference", args: "session-hygiene")` §1. With no PRD dir, rung 2 applies: skip the file, rely on the printed `### Next step`.

**Then commit session artifacts (terminal).** Invoke `Skill(skill: "workflows-core:reference", args: "specs-repo-git commit-artifacts")` and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH` (here: the pending feedback and cost files above), commits, and pushes per §4 step 5. It NEVER touches the docs repo or the code repo; NEVER force-pushes; NEVER fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting that notice. Print its §6 outcome line here, as the run's last output — prefixed `Specs repo:`, with any guard notice repeated in full.

---

## Invariants (always enforced)

- ALWAYS resolve the docs repo via `resolve-docs-repo` (`${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/repo-resolution.md` §1) and report which rung answered
- ALWAYS validate the resolved docs repo carries at least one of `mkdocs.yml` / `mkdocs.internal.yml` before doing anything else (Phase 0 step 3) — this command's application is Material for MkDocs-specific
- ALWAYS print every extracted value with its file and line (or path) and confirm before applying it (Phase 5) — NEVER applies silently
- ALWAYS check the confirmed primary and accent against `${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/contrast.md`'s thresholds, report the ratio to two decimals, and carry a failing finding into the PR message and the report — NEVER silently accept and NEVER silently correct a failing colour; it IS still applied if the operator confirms
- ALWAYS copy logo/favicon assets into `docs/assets/`; NEVER reference the code repo by path from the docs build
- ALWAYS keep the `theme:` / `extra_css:` blocks identical across `mkdocs.yml` and `mkdocs.internal.yml` when both exist
- ALWAYS dispatch `docs-scaffold-reviewer` at Opus for a standalone run (D17, D20 — no tiering by unit); NEVER for `--inline`, whose diff joins the caller's own review instead
- ALWAYS triage `docs-scaffold-reviewer`'s findings (`workflows-core:finding-triage`) before applying anything; there is NO dedicated fixer (D25) — the orchestrator applies survivors itself, bound by the patch gate, and surfaces a survivor it cannot safely patch rather than guessing
- ALWAYS use `choices` arrays for a genuine decision point; 2–4 options, and NEVER author an "Other" option — the harness supplies the free-text escape itself. Where the candidate set is unbounded (Phase 2's repo listing, Phase 4's overflow logo candidates) the array is never sized to the list itself: print every candidate as prose first, then cap at three concrete rows plus one overflow option, per `workflows-core:epic-picker` *The cap*
- ALWAYS run `specs-preflight` at Phase 0 and `commit-artifacts` as the last standalone action (`workflows-core:specs-repo-git`) — bounded to `$SPECS_PATH`'s artifact paths and to plugin-created branches, of which this family creates none; always `git -C "$SPECS_PATH"` and never a `cd`; never force-pushing; never failing the run
- NEVER push or auto-merge the docs-repo branch — output a reviewable PR (branch + commit + drafted message) for the operator to push, the same discipline as `/docs-workflows:docs-profile`
- NEVER let `--inline` run its own preflight, review gate, PR, or emitter tail (Phase 0 step 4, Phase 8, Phase 9, Phases 11–13) — it returns its diff and its contrast finding to the caller, whose own single review and single PR cover it
- NEVER let the standalone path skip its cost entry, and NEVER let `--inline` emit one — emitting on both paths would double-count one run (`workflows-core:cost-emission` §7)
- ALWAYS end a standalone Phase 10 report with a `### Next step` recommendation (per `Skill(skill: "workflows-core:reference", args: "next-phase-offer")`) — guidance only, never auto-invoked; `--inline` prints none, since control returns to the caller's own report
- ALWAYS reference this plugin's own bundled files with `${CLAUDE_PLUGIN_ROOT}`; every `workflows-core:<name>` citation is loaded through `Skill(skill: "workflows-core:reference", args: "<name>")`, never by path
