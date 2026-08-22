# dev-workflows Documentation Restructure — Design

**Date:** 2026-08-22
**Status:** Approved for planning
**Scope:** `plugins/dev-workflows/` in all three marketplace editions
**Prior art:** [dynatrace-oss/dynatrace-managed-mcp#214](https://github.com/dynatrace-oss/dynatrace-managed-mcp/pull/214), [ihudak/ai-containers#78](https://github.com/ihudak/ai-containers/pull/78)

## 1. Problem

`plugins/dev-workflows/README.md` is **379 lines and 74,620 bytes**. That ratio is the defect: an average of 197 bytes per line, with a single table row reaching **2,177 characters**. Three sections carry 50,565 of those bytes:

| Section | Bytes | Lines | Shape |
|---|---|---|---|
| `## Commands` | 20,534 | 43 | 19 table rows, cells up to 2,177 characters |
| `## Reference docs` | 16,764 | 57 | 36 bullets, paragraph-length |
| `## Agents` | 13,267 | 42 | 34 table rows |

A 2,177-character cell renders in a GitHub table column roughly 30 characters wide. The information is present and mostly correct; it is simply unreadable in the shape it is stored in. This is the same disease as the two prior-art PRs in a different presentation — ai-containers made a reader scroll past 1,133 lines, this makes a reader squint at a column.

**The enumerations are honest.** Every count in the README was derived against the tree rather than trusted, and they hold: 21 command files on disk, 34 agent files against 34 table rows, 36 top-level references against 36 named, 4 hooks declared in `hooks.json` against 4 scripts on disk against 4 table rows, and exactly 9 agents carrying a `model: opus` frontmatter pin against the claimed "nine Opus-backed reviewers/planners". This README has not rotted the way ai-containers' had, which changes what the work is: **this is a re-shaping and a verification pass, not a rescue.**

**One structural defect is already known.** The `## Commands` table has 19 rows for 21 commands. `/vuln` and `/upgrade` are documented in an unlabeled `Additionally:` table at the tail of the `## /implement workflow` section, so the plugin's two standalone maintenance commands are filed under a command they have nothing to do with, and a reader scanning the Commands table concludes they do not exist.

**A second problem is invisible from the README itself.** `plugins/dev-workflows/README.md` is one of the five files the mgd edition must never copy (with `.claude-plugin/plugin.json`, `LICENSE`, `references/dependencies.md`, and `CHANGELOG.md`). It differs from canonical by **exactly two lines** — line 5 names the marketplace, line 289 names the recommended container repository. So 377 of 379 lines of shared content sit inside a file the porting discipline forbids copying, which is the standing trap recorded as *identity files are where fixes die*.

## 2. What this is not

- Not a rescue of rotten docs. The enumerations verify; the defects found so far are one misfiled table and whatever the grounding pass turns up.
- Not a change to `commands/`, `agents/`, `references/`, or `hooks/` — except where grounding proves a documented claim false, which is fixed under the bugs-first policy in its own commit and reported in the PR body.
- Not a maintainer guide. `CLAUDE.md` (327 lines) and `references/` already own how to edit the plugin, the three-edition porting discipline, and the invariants. No fact gets a second owner.
- Not a change to the `plugin.json` / `marketplace.json` description blurbs, which are bounded at 1024 characters by `scripts/validate-catalog.py` and are a separate concern.
- Not a restructure of the other plugins. `acli` (30 lines), `dt-style-guide` (175), and `obsidian-llm-wiki` (271) do not have this problem. The repo-root `README.md` (104 lines) gets link updates only.

## 3. Goals

1. A reader who wants to run one command opens **one file** and finds what to type, what it needs, what it produces, what gates it, and what happens when a prerequisite is absent.
2. Every claim on every page traces to something that actually runs — a line in `commands/`, `agents/`, `references/`, or `hooks/`.
3. Mermaid diagrams are kept and extended where they earn their place: showing where a role and phase sit, and the sequence of the workflow.
4. The shared content becomes copyable between the two Claude editions, shrinking mgd's never-copy surface from 379 lines to roughly 50.
5. Drift is mechanically defended, so the split does not multiply the places drift can hide.

## 4. The page set

```
plugins/dev-workflows/
  README.md                       ~50 lines — pitch, marketplace pointer, container
                                  recommendation, install pointer, compact capability
                                  table, link table into docs/
  docs/
    README.md                     index: an "I want to…" task table, then the page list
    getting-started.md            environment variables, /dev-workflows:statusline,
                                  one worked first run end to end
    workflow.md                   the pipeline Mermaid, the role table, artifact homes,
                                  sources of truth, cross-cutting commands
    commands/
      api-guideline-reviewer.md   create-ard.md      create-vi.md      design.md
      docs-profile.md             document.md        epics.md          feedback.md
      guideline-reviewer.md       idea.md            implement.md      prompt.md
      prompt-brainstorm.md        prompt-grill-me.md ready.md          release-notes.md
      specify.md                  statusline.md      update-vi.md      upgrade.md
      vuln.md                                                        (21 pages)
    reference/
      agents.md                   34 agents grouped by role, with the 9 real Opus pins
      references.md               36 reference docs grouped by concern
      environment.md              the 5 environment variables and the directory layout
      hooks.md                    the 4 hooks
      model-routing.md            classification, the fallback chain, the fan-out policy
      session-artifacts.md        the cost, feedback, follow-up, and resume files written
                                  under <VI-dir>/dev-workflows/ in $SPECS_PATH
```

**30 pages under `docs/`, plus the rewritten `README.md`** — three top-level, 21 commands, six reference. One page per command is the unit because the command is the unit a reader acts on. A small command gets a short page — `feedback.md` will be perhaps 20 lines — and that is correct, not a defect: a short file that answers one question beats a paragraph buried in a 74 KB table.

`docs/README.md` opens with the question a reader actually arrives with, not the catalog:

| I want to… | Go to |
|---|---|
| turn a raw idea into something actionable | [`/idea`](commands/idea.md) |
| write or refresh a Value Increment | [`/create-vi`](commands/create-vi.md), [`/update-vi`](commands/update-vi.md) |
| break a VI into Epics | [`/epics`](commands/epics.md) |
| write a specification, then a design | [`/specify`](commands/specify.md), [`/design`](commands/design.md) |
| build the thing | [`/implement`](commands/implement.md) |
| document it, then announce it | [`/document`](commands/document.md), [`/release-notes`](commands/release-notes.md) |
| check whether a ticket is really ready | [`/ready`](commands/ready.md) |
| fix a CVE or upgrade a dependency | [`/vuln`](commands/vuln.md), [`/upgrade`](commands/upgrade.md) |
| tell the plugin it got something wrong | [`/feedback`](commands/feedback.md), [`/prompt`](commands/prompt.md) |
| understand the whole pipeline first | [the workflow overview](workflow.md) |

## 5. Command page anatomy

Every command page carries the same seven sections in the same order, so a reader who learns one page has learned all twenty-one:

```markdown
# /specify

One sentence: what this is for and which role runs it.

## Synopsis          the argument grammar, each accepted form explained separately
## How it runs       the Mermaid phase flow (see §6 for when this section exists)
## What it needs     environment variables, gated inputs, tool prerequisites — and for
                     each one, what happens when it is absent
## What it produces  the artifacts and exactly where they land
## Gates             which reviewer, which style check, what a BLOCK verdict does
## Example           one real invocation, start to finish
## See also          the neighbouring phases and the reference pages it depends on
```

`## What it needs` is the section the current README has nowhere. Today a reader learns that `/specify` requires its VI to be on the specs repo's default branch only by running it and hitting `require-on-main`. Stating each prerequisite together with its absent-case behaviour is the single largest readability gain in this design, because absent-case behaviour is exactly what `references/phase-handoff.md` §3.4 already defines and no user-facing page repeats.

## 6. Mermaid policy

Both existing diagrams survive: the pipeline overview moves to `workflow.md`, and the `/implement` flow moves to `commands/implement.md`.

**A command page carries a `## How it runs` diagram when its command body dispatches two or more distinct subagents.** That trigger is observable — count the distinct `dev-workflows:<agent>` subagent types named in `commands/<name>.md` — rather than a judgement the writer has to make, which is what `references/instruction-file-maintenance.md` rule 3 requires of any pointer.

Thirteen commands qualify, with their dispatch counts: `document` (12), `implement` (9), `epics` (8), `create-vi` (6), `create-ard` (6), `update-vi` (5), `specify` (5), `release-notes` (4), `ready` (4), `idea` (4), `design` (4), `vuln` (3), `upgrade` (3).

Eight do not: `guideline-reviewer` (1), `docs-profile` (1), `api-guideline-reviewer` (1), `statusline` (0), `prompt-grill-me` (0), `prompt-brainstorm` (0), `prompt` (0), `feedback` (0). A linear sequence with no fan-out is a numbered list; drawing it as a flowchart is decoration.

**Diagram labels are derived from the command's own top-level phase headings, verbatim.** Two heading dialects exist on disk and both are honoured as written: `## Phase N — <title>` in eighteen commands, and `## Step N — <title>` in `/vuln`. The remaining two — the standalone reviewers — carry no top-level headings at all, which is consistent: neither qualifies for a diagram. Derived heading counts for the thirteen commands that get a diagram, which the plan will use as each page's expected node budget: `document` 37, `epics` 20, `implement` 17, `release-notes` 14, `specify` 13, `design` 13, `create-vi` 12, `create-ard` 11, `update-vi` 11, `ready` 11, `idea` 9, `vuln` 5 (steps), `upgrade` 3. A diagram may collapse consecutive phases into one node where they form a single user-visible step, but it may never introduce a node that no heading backs.

## 7. The grounding contract

This is the section that answers the ai-containers lesson, where a split shipped as a pure prose move and its own PR body recorded that a claim-by-claim verification "is worth doing and is not done here."

**The old README is a source of topics, never a source of facts.** No sentence moves from `README.md` to a new page without being re-derived from the thing that runs it. For each page element the derivation is fixed:

| Page element | Derived from | Never from |
|---|---|---|
| Synopsis | the command's own argument-parsing phase, plus its frontmatter `name` | the old table cell |
| Purpose sentence | frontmatter `description`, rewritten for a human reader | the old blurb |
| Phase flow | the command's `## Phase N` / `## Step N` headings | invention or inference |
| What it needs | the `$VAR` reads in the body, its `require-on-main` calls, its declared `allowed-tools` | assumption about what a command "obviously" needs |
| What it produces | the command's own write paths and its `handoff-to-main` calls | the old artifact table |
| Gates | the reviewer dispatch, the style-check dispatch, the `commit-artifacts` step | the old prose summary |
| Agent rows | each agent's frontmatter `description`, `tools`, and `model` | the old agent table |

**Every discrepancy is recorded and fixed, not silently corrected.** The PR body carries a defect table in the shape PR#214 used, so a reader of the history can see what was wrong rather than inferring it from a diff. A discrepancy that turns out to be a defect in a command or agent rather than in the README is fixed in its own commit under the bugs-first policy and named separately in that table.

**Grounding is per-page and independently checkable.** A page's derivation reads one command file plus the agents and references that command names. This is deliberately narrow so that a reviewer can re-derive any single page without holding the whole plugin in context — the failure mode from *verification tables need verifying*, where 45 of 46 rows read PASS while 22 of 50 commands were unrunnable.

## 8. The gate: `scripts/check-docs.sh`

Splitting prose multiplies the places drift can hide, so the split ships with its own gate, in the shape the repo already uses for `check-id-grammar.sh`.

1. **Links resolve.** Every relative link in every page and in both READMEs points at a file that exists.
2. **Anchors resolve.** Every `#anchor` resolves to a real heading in whichever file it names. A bare `#anchor` names no file, so a file-existence check cannot see it — this is the check that catches the 24 anchors ai-containers' split broke.
3. **No orphans.** Every page under `docs/` is reachable from `docs/README.md`, transitively.
4. **Inventory agrees, in both directions.** Every file in `commands/` has a page in `docs/commands/` and every page names a real command; the same both ways for the 34 agents against `reference/agents.md`, the 36 top-level references against `reference/references.md`, and the 4 `hooks.json` declarations against `reference/hooks.md`.
5. **Environment variables agree, in both directions.** Every variable documented in `reference/environment.md` is read somewhere in `commands/`, `agents/`, or `references/`, and every variable those files read is documented. Current usage, derived: `SPECS_PATH` 245 references, `VAULT_PATH` 94, `REPOS_PATH` 56, `DOCS_PATH` 16, `GIT_USER_INITIALS` 12. `CLAUDE_PLUGIN_ROOT` (690) is excluded — it is a Claude Code runtime variable, not a user-set one, and belongs to the maintainer surface in `CLAUDE.md`.
6. **No table cell exceeds 200 characters.** This is the readability invariant the whole change exists to establish, and it is the one a future edit will silently violate. Defending it mechanically is what stops a 2,177-character row from regrowing.
7. **`--selftest`.** Each of checks 1–6 is asserted against a fixture that must fail it and a fixture that must pass it, with the expected exit code checked. A gate that cannot be shown to fail proves nothing when it passes — and ai-containers' equivalent gate passed vacuously on its first run, examining nothing, because its file list came from `git ls-files` while the new pages were still untracked.

Wired into `.github/workflows/validate-catalog.yml` as two steps beside the existing pair, self-test first:

```yaml
      - name: Self-test the docs gate
        run: ./scripts/check-docs.sh --selftest

      - name: Check docs
        run: ./scripts/check-docs.sh --root .
```

## 9. Three editions

| Edition | `docs/` | `README.md` | Commands |
|---|---|---|---|
| canonical (`ihudak-claude-plugins`) | authored | hand-written, carries both identity strings | 21 |
| mgd (`mgd-claude-plugins`) | **copied verbatim** | hand-written | 21 |
| copilot (`ihudak-copilot-plugins`) | **hand-adapted, never copied** | hand-written | 20 |

**The identity-quarantine rule.** No page under `docs/` may name a marketplace (`ihudak-plugins`, `mgd-plugins`) or a container repository (`ihudak/ai-containers`, `Dynatrace-Internal/mgd-ai-containers`). Both facts are setup facts and belong with installation, which lives in the plugin `README.md` and the repo-root `README.md` — both already hand-maintained per edition. `docs/reference/environment.md` therefore explains what each variable means and how commands use it, and links to the README for the recommended container rather than naming one.

The consequence is the point: `docs/` is identity-free by construction, so mgd's parity check still reports **exactly five** differing files. A count of six means the rule was broken; a count of four still means `references/dependencies.md` was destroyed by a careless `cp -r`, which is the round-2 defect that `diff -rq` perversely rewards.

**Copilot is adapted, never copied**, per the standing four dialect rules: `task(agent_type:)` rather than `Agent(subagent_type:)`; absolute `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<file>.md` paths rather than `${CLAUDE_PLUGIN_ROOT}/references/<file>.md`; colon-form command names (`specify:`, `design:`, `document:`) never slash-form; and lowercase tool names (`view`, `glob`, `grep`, `bash`). Its command pages are named for its skills — 20 of them, with `statusline` absent, matching its own "Not ported from the Claude Code edition" section, which also excludes session cost reporting. Its `docs/reference/session-artifacts.md` therefore omits the cost file and says why.

## 10. Global constraints

Copied verbatim into the plan, because each is a gate that bites at push time rather than at edit time:

- **Requirement IDs use the bracketed form only.** `scripts/check-id-grammar.sh` scans everything under the repository root and fails on `US-1`, `AC-1`, `SM-1`, `SMC-1`, `UC-1`, `FR-1`, `AD-1`, and `SM-C1` in both bracketed and bare forms. Any docs page illustrating an ID writes `[US#1]`, `[AC#1]`, `[AD#1]`. A page that must quote the legacy form in order to forbid it carries the `id-grammar-ok:` marker, and every such line is audited individually.
- **The spec-ID census must not shift.** `scripts/spec-id-baseline.txt` freezes the counts of `[U0N]`, `[AC0N]`, `[TC0N]`, `[Uxx]`, `[ACxx]`, `[TCxx]` across `plugins/` and `CLAUDE.md`. New pages live under `plugins/`, so a page using those literals as examples changes the census and trips the tripwire. Docs pages therefore use no spec-ID literals. If one is genuinely needed, the baseline is regenerated deliberately, in its own commit, with the reason stated.
- **Prose is never hard-wrapped.** Per `references/prose-formatting.md`, each paragraph is one unbroken line so Obsidian and IntelliJ soft-wrap it and a copy-paste needs no cleanup. Tables and code fences are exempt, and check 6 bounds table cells regardless.
- **Every page is reachable from `docs/README.md`,** or check 3 fails.
- **The plugin `description` blurbs are untouched** and stay under the 1024-character budget `scripts/validate-catalog.py` enforces.

## 11. Sequencing

Three pull requests, in order, each merged before the next begins:

1. **Canonical.** Build the 30 `docs/` pages against the grounding contract, rewrite `README.md` to roughly 50 lines, write `scripts/check-docs.sh` with its self-test, wire both into CI, update the repo-root `README.md` links, and record the defect table in the PR body. This is where all the derivation work lives.
2. **mgd.** Copy `docs/` verbatim, copy `scripts/check-docs.sh`, hand-write `README.md` with the mgd identity strings, and verify the parity check still reports exactly five differing files.
3. **copilot.** Hand-adapt 29 `docs/` pages under the four dialect rules — 20 command pages rather than 21 — hand-write `README.md`, and adapt the gate's check 4 to the `skills/<cmd>/SKILL.md` layout.

Ordering matters for the reason recorded in *upstream reservoir defects*: a constraint enforced in one edition only breaks there forever while the lax upstream refills it. The gate ships in canonical first so the other two inherit an enforced rule rather than a described one.

## 12. Success criteria

- `plugins/dev-workflows/README.md` is under 60 lines in all three editions.
- No table cell in any documented file exceeds 200 characters, enforced by check 6.
- All 21 commands (20 in copilot) have a page; checks 4 and 3 pass in both directions.
- `./scripts/check-docs.sh --selftest` passes, and each of checks 1–6 has been observed failing against its own fixture before being trusted.
- `diff -rq` between the canonical and mgd `plugins/dev-workflows/` trees reports exactly five differing files.
- Every claim on every page was derived from `commands/`, `agents/`, `references/`, or `hooks/` during this change — not carried across from the old README — and the discrepancies found are listed in the canonical PR body.
- `python3 scripts/validate-catalog.py`, `./scripts/check-id-grammar.sh --selftest`, and `./scripts/check-id-grammar.sh --root .` all pass unchanged.
