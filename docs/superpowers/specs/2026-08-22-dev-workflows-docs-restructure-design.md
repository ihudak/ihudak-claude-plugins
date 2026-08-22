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

**Three defects are already known**, all found by grounding rather than by reading, and all fixed by this change:

- **D1 — the Commands table documents 19 of 21 commands.** `/vuln` and `/upgrade` sit in an unlabeled `Additionally:` table at the tail of the `## /implement workflow` section, so the plugin's two standalone maintenance commands are filed under a command they have nothing to do with, and a reader scanning the Commands table concludes they do not exist.
- **D2 — `references/cost-emission.md` §7 omits `/update-vi` from its own authority table.** That table is introduced as "Fixed per-command labels" and lists ten commands. `/update-vi` passes `phase: vi-update`, `role: pm` to `emit-cost`, and line 4 of the same file names `/update-vi` among the commands that run the Session cost phase — so `vi-update` is a phase value emitted by a shipped command and recorded in no authority. This is the dead-gate shape from the other side: not a rule with no consumer, but a consumer emitting a value its own reference does not enumerate.
- **D3 — `/ready`'s role has two names.** `cost-emission.md` §7 attributes it `role: team`; the README's role table files it under **QA**, with a legend defining QA as verification and quality gates rather than an artifact-authoring role. Both may be intentional, so this one is **reported, not resolved**: the docs state the `team` attribution because that is what the artifact records, and the discrepancy goes in the PR body for a human decision.

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
    roles-and-phases.md           prose companion to the diagram: what each role owns,
                                  what each phase is, what is handed over at each seam
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
      session-cost.md             how cost is computed and attributed, and how to read a
                                  cost file — with a worked sample entry
      session-feedback.md         what gets logged, the entry format, where it lands
      follow-ups.md               the task-line format, target-file resolution, the
                                  end-of-run batch preview
      resume-and-checkpoints.md   the prepare-checkpoint, resume.md, the role-aware
                                  suggestion, and the session-name aid
```

**34 pages under `docs/`, plus the rewritten `README.md`** — four top-level, 21 commands, nine reference. One page per command is the unit because the command is the unit a reader acts on. A small command gets a short page — `feedback.md` will be perhaps 20 lines — and that is correct, not a defect: a short file that answers one question beats a paragraph buried in a 74 KB table.

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

One sentence: what this is for.

## Who runs it       the role, its cost-attribution phase, and — where a command
                     serves more than one role — each variant explained separately
## Synopsis          the argument grammar, each accepted form explained separately
## How it runs       the Mermaid phase flow (see §6 for when this section exists)
## What it needs     environment variables, gated inputs, tool prerequisites — and for
                     each one, what happens when it is absent
## What it produces  the artifacts and exactly where they land
## Gates             which reviewer, which style check, what a BLOCK verdict does
## Example           one real invocation, start to finish
## See also          the neighbouring phases and the reference pages it depends on
```

`## Who runs it` is grounded, not editorial. The plugin already carries a machine-readable role model: every VI-lifecycle command calls `emit-cost` with a `phase:` and a `role:`, and `references/cost-emission.md` §7 holds the authoritative per-command table — `pe` for `/specify` and `/epics`, `dev` for `/design`, `/implement`, and `/document`, `pm` for `/idea` and `/create-vi`, `pa` for `/create-ard`, `team` for `/ready`. The page states the role from that table, never from the README's prose.

**A command that serves more than one role explains each variant separately.** `/release-notes` is the case that forces the rule: it passes `phase: inferred, role: inferred`, and §7 discriminates on the presence of downstream engineering artifacts — no `specification.md` or `design.md` under the VI's specs dir means the PM's early bare-VI run (`vi-creation` / `pm`), either present means the dev's documenting re-run (`documenting` / `dev`). A PM and a dev arriving at that page need different halves of it, so the page carries both, says which is which, and states the discriminator rather than leaving a reader to infer which run they are about to perform.

**Two unrelated `phase:` vocabularies exist and must not be conflated on any page.** The cost-attribution phases (`vi-creation`, `vi-update`, `architecture`, `specification`, `epic-refinement`, `planning`, `implementation`, `documenting`, `readiness`) name where a run sits in the product lifecycle. The model-routing resume phases (`full`, `verify-resume`, `regression-resume`), which `/vuln` and `/upgrade` pass, name how far a re-entered run should re-execute. They share a field name and nothing else. `/vuln` and `/upgrade` emit no cost attribution at all — they have no VI to attribute to, and `cost-emission.md` never mentions them.

`## What it needs` is the section the current README has nowhere. Today a reader learns that `/specify` requires its VI to be on the specs repo's default branch only by running it and hitting `require-on-main`. Stating each prerequisite together with its absent-case behaviour is the single largest readability gain in this design, because absent-case behaviour is exactly what `references/phase-handoff.md` §3.4 already defines and no user-facing page repeats.

### The roles-and-phases page

`docs/roles-and-phases.md` is the prose companion the diagram cannot be. A flowchart shows that `/specify` sits between `/epics` and `/design`; it cannot say what a PE is accountable for, what they receive, what they must decide, or what they are handing the next person. The page carries one section per role — PM, PA, PE, Dev, and the `team` attribution `/ready` uses — and for each: what the role owns, which commands it runs, what it consumes, what it produces, and **what it hands over at the seam**, since every seam in this pipeline is a `handoff-to-main` / `require-on-main` pair with real failure modes a reader will meet.

It then carries one entry per cost-attribution phase — `vi-creation`, `vi-update`, `architecture`, `specification`, `epic-refinement`, `planning`, `implementation`, `documenting`, `readiness` — naming the command that emits it and what being in that phase means for the work. This is the vocabulary a reader will see in their own cost files, so it needs a definition somewhere; today it is defined only inside a reference written for agents.

Both halves are derived: roles and phases from `references/cost-emission.md` §7 and each command's own `emit-cost` call, seams from `references/phase-handoff.md` §2 and §3. The page links to `workflow.md` for the picture and is linked from it in return, so a reader can move between the two without going through the index.

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
4. **Inventory agrees, in both directions.** Every file in `commands/` has a page in `docs/commands/` and every page names a real command; the same both ways for the 34 agents against `reference/agents.md`, the reference set against `reference/references.md`, and the 4 `hooks.json` declarations against `reference/hooks.md`. The reference inventory is the 36 top-level `references/*.md` **plus** `references/model-routing/classification.md`, which is the single source of truth for model routing and lives one level down. The remaining six subtrees are described as groups with their counts rather than enumerated page by page, and check 4 verifies those counts: `api-guidelines/` (24), `guidelines/` (11), `handoff/` (10), `dynatrace-docs/` (6), `upgrade/` (3), `fix-vuln/` (2). That accounts for all 93 markdown files under `references/` — 36 top-level, 1 in `model-routing/`, 56 across the six groups — so no file falls outside the check. Every inventory is derived from the edition being checked, never from a number written into a page.
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

**Copilot is adapted, never copied**, per the standing four dialect rules: `task(agent_type:)` rather than `Agent(subagent_type:)`; absolute `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<file>.md` paths rather than `${CLAUDE_PLUGIN_ROOT}/references/<file>.md`; colon-form command names (`specify:`, `design:`, `document:`) never slash-form; and lowercase tool names (`view`, `glob`, `grep`, `bash`). Its command pages are named for its skills — 20 of them, with `statusline` absent, matching its own "Not ported from the Claude Code edition" section, which also excludes session cost reporting. That exclusion is real on disk and not merely declared: `skills/_shared/` has no `cost-emission.md`, while `feedback-emission.md`, `followup-emission.md`, and `session-hygiene.md` are all present. So the copilot set drops `reference/session-cost.md` and keeps the other three.

Both editions happen to carry 36 top-level reference files, but the sets are not the same and the equal count is a coincidence worth not relying on: copilot lacks `cost-emission.md` and carries `model-routing.md` as a flat file, where canonical has a `references/model-routing/` directory holding `classification.md`. This is exactly why check 4 derives its inventory from the edition it is running in rather than from a number written into a page.

## 10. Global constraints

Copied verbatim into the plan, because each is a gate that bites at push time rather than at edit time:

- **Requirement IDs use the bracketed form only.** `scripts/check-id-grammar.sh` scans everything under the repository root and fails on `US-1`, `AC-1`, `SM-1`, `SMC-1`, `UC-1`, `FR-1`, `AD-1`, and `SM-C1` in both bracketed and bare forms. Any docs page illustrating an ID writes `[US#1]`, `[AC#1]`, `[AD#1]`. A page that must quote the legacy form in order to forbid it carries the `id-grammar-ok:` marker, and every such line is audited individually.
- **The spec-ID census must not shift.** `scripts/spec-id-baseline.txt` freezes the counts of `[U0N]`, `[AC0N]`, `[TC0N]`, `[Uxx]`, `[ACxx]`, `[TCxx]` across `plugins/` and `CLAUDE.md`. New pages live under `plugins/`, so a page using those literals as examples changes the census and trips the tripwire. Docs pages therefore use no spec-ID literals. If one is genuinely needed, the baseline is regenerated deliberately, in its own commit, with the reason stated.
- **Prose is never hard-wrapped.** Per `references/prose-formatting.md`, each paragraph is one unbroken line so Obsidian and IntelliJ soft-wrap it and a copy-paste needs no cleanup. Tables and code fences are exempt, and check 6 bounds table cells regardless.
- **Every page is reachable from `docs/README.md`,** or check 3 fails.
- **The plugin `description` blurbs are untouched** and stay under the 1024-character budget `scripts/validate-catalog.py` enforces.

## 11. Sequencing

Three pull requests, in order, each merged before the next begins:

1. **Canonical.** Build the 34 `docs/` pages against the grounding contract, rewrite `README.md` to roughly 50 lines, write `scripts/check-docs.sh` with its self-test, wire both into CI, update the repo-root `README.md` links, and record the defect table in the PR body. This is where all the derivation work lives.
2. **mgd.** Copy `docs/` verbatim, copy `scripts/check-docs.sh`, hand-write `README.md` with the mgd identity strings, and verify the parity check still reports exactly five differing files.
3. **copilot.** Hand-adapt 32 `docs/` pages under the four dialect rules — 20 command pages rather than 21, and no `reference/session-cost.md` — hand-write `README.md`, and adapt the gate's check 4 to the `skills/<cmd>/SKILL.md` layout and the 35-reference `_shared/` inventory.

Ordering matters for the reason recorded in *upstream reservoir defects*: a constraint enforced in one edition only breaks there forever while the lax upstream refills it. The gate ships in canonical first so the other two inherit an enforced rule rather than a described one.

## 12. Success criteria

- `plugins/dev-workflows/README.md` is under 60 lines in all three editions.
- No table cell in any documented file exceeds 200 characters, enforced by check 6.
- All 21 commands (20 in copilot) have a page; checks 4 and 3 pass in both directions.
- Every command page names the role that runs it, and the role matches `references/cost-emission.md` §7 rather than the old README prose. `/release-notes` explains both its PM and its Dev variant, and states the discriminator between them.
- `docs/roles-and-phases.md` covers every role and every cost-attribution phase that appears in §7, including `vi-update` once D2 is fixed.
- `./scripts/check-docs.sh --selftest` passes, and each of checks 1–6 has been observed failing against its own fixture before being trusted.
- `diff -rq` between the canonical and mgd `plugins/dev-workflows/` trees reports exactly five differing files.
- Every claim on every page was derived from `commands/`, `agents/`, `references/`, or `hooks/` during this change — not carried across from the old README — and the discrepancies found are listed in the canonical PR body.
- `python3 scripts/validate-catalog.py`, `./scripts/check-id-grammar.sh --selftest`, and `./scripts/check-id-grammar.sh --root .` all pass unchanged.
