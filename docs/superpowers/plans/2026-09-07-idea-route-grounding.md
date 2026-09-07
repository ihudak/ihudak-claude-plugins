# Idea-route grounding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give a PRD folder authored from an idea the same verified `[CG#n]`/`[DG#n]` foundation a BRD-route slice gets, from one command renamed `/prd-ground` that serves both routes.

**Architecture:** One command, one engine. Only Phase 0 forks: a folder carrying `brd-link.md` is the BRD route and takes its claims from `brd/brd-inventory.md`'s `[BR#n]` rows exactly as today; a `PRD-` folder without one is the idea route and takes them from `prd.md`'s `[AC#n]` and `[FR#n]`. Phases 1–11 — repo resolution, commit pinning, the grounder fan-out, `grounding-verifier`, horizons, the write and the handoff — are unchanged and route-agnostic. Downstream, `/create-ard` and `/specify` stop gating their grounding reads on the BRD route and seed their `code-scanner` themes from the findings, and `/update-prd` gains the first writer `consumed_by: PRD` has ever had.

**Tech Stack:** Markdown instruction files (slash commands, agent system prompts, shared references), `bash`/`python3` build gates under `scripts/`, JSON plugin manifests. No application code.

**Spec:** `docs/superpowers/specs/2026-09-07-idea-route-grounding-design.md`

## Global Constraints

- **Citations.** A **command or agent** cites its own plugin's reference as `${CLAUDE_PLUGIN_ROOT}/references/<name>.md`. A **reference** citing a sibling reference in the same plugin uses the bare backticked `` `references/<name>.md` `` form. A `workflows-core` reference is cited from another plugin **only** as `workflows-core:<name>`, never by path. Never cite `docs/superpowers/specs/…` or `docs/superpowers/plans/…` from a shipped file — neither ships in the plugin, so the link dangles for an installed user.
- **Match the surrounding file.** Wrap prose at the width its neighbours use, keep the file's comment density and heading style, and never reflow a paragraph you did not otherwise need to touch.
- **`choices:` arrays are `AskUserQuestion` calls.** 2–4 options, never an authored "Other" — the harness supplies the free-text escape. `check-docs.sh` check 12 gates the arity.
- **Plugin `description` hard cap 1024 characters** in both `plugin.json` and the `marketplace.json` entry. A capability change **replaces** wording; it never appends. One over-long blurb makes the whole catalogue fail to install.
- **Never reformat `.claude-plugin/marketplace.json`** — Claude Code parses it. Edit the one value in place.
- **Every requirement ID is the bracketed `[PREFIX#N]` form.** No dash-separated IDs anywhere.
- **`git add -A` is never issued at repository scope.** Stage explicit paths.
- **Re-derive every count against the tree**, and prefer a citation to a count wherever one will do. A number written into a doc that nothing gates is a claim that goes stale in the next commit.
- **Versions when the work is complete:** `product-workflows` **3.0.0** (a removed command name is breaking), `workflows-core` **1.3.0**. Both in `plugin.json` and the `marketplace.json` entry, which `scripts/validate-catalog.py` asserts agree.
- **The seven gates, all of which must pass before any task's commit:**
  ```bash
  python3 scripts/validate-catalog.py --selftest
  python3 scripts/validate-catalog.py .
  ./scripts/check-id-grammar.sh --selftest
  ./scripts/check-id-grammar.sh --root .
  ./scripts/check-docs.sh --selftest          # ~2 minutes
  ./scripts/check-docs.sh --root .
  python3 plugins/workflows-core/scripts/session-cost.py --selftest
  ```
- **Commit trailer on every commit:**
  ```
  Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU
  ```
- **Nothing is pushed.** No task in this plan pushes, opens a pull request, or contacts a remote.

## The rename's stop-code map

Sixteen codes move, and other commands quote several of them in their own stops. This is the complete
map; apply it wherever a code appears, not only inside the renamed file.

| Old | New |
|---|---|
| `BRD_GROUND_DIRTY_TREE` | `PRD_GROUND_DIRTY_TREE` |
| `BRD_GROUND_EMPTY_INVENTORY` | `PRD_GROUND_EMPTY_INVENTORY` |
| `BRD_GROUND_INVENTORY_NOT_HANDED_OFF` | `PRD_GROUND_INVENTORY_NOT_HANDED_OFF` |
| `BRD_GROUND_NEEDS_INTAKE` | `PRD_GROUND_NEEDS_INTAKE` |
| `BRD_GROUND_NEEDS_KEY` | `PRD_GROUND_NEEDS_KEY` |
| `BRD_GROUND_NEEDS_REBASELINE` | `PRD_GROUND_NEEDS_REBASELINE` |
| `BRD_GROUND_NEEDS_SPLIT` | `PRD_GROUND_NEEDS_SPLIT` |
| `BRD_GROUND_NOTHING_TO_GROUND` | `PRD_GROUND_NOTHING_TO_GROUND` |
| `BRD_GROUND_NOT_FOUND` | `PRD_GROUND_NOT_FOUND` |
| `BRD_GROUND_NOT_HANDED_OFF` | `PRD_GROUND_NOT_HANDED_OFF` |
| `BRD_GROUND_NO_CODE_MATRIX` | `PRD_GROUND_NO_CODE_MATRIX` |
| `BRD_GROUND_NO_CODE_REBASELINE` | `PRD_GROUND_NO_CODE_REBASELINE` |
| `BRD_GROUND_NO_CODE_UNGROUNDED` | `PRD_GROUND_NO_CODE_UNGROUNDED` |
| `BRD_GROUND_NO_INVENTORY` | `PRD_GROUND_NO_INVENTORY` |
| `BRD_GROUND_ROOT_LEVEL` | `PRD_GROUND_ROOT_LEVEL` |
| `BRD_GROUND_VERIFY_COMMIT_MISMATCH` | `PRD_GROUND_VERIFY_COMMIT_MISMATCH` |

Task 4 adds five new codes, all under the new prefix: `PRD_GROUND_EPIC_LEVEL`,
`PRD_GROUND_NEEDS_PRD`, `PRD_GROUND_PRD_NOT_HANDED_OFF`, `PRD_GROUND_NO_CLAIMS`,
`PRD_GROUND_NO_PREREQUISITES`.

## File structure

| File | Responsibility after this plan | Task |
|---|---|---|
| `plugins/product-workflows/commands/prd-ground.md` | the grounding command, both routes; Phase 0 forks, Phases 1–11 shared | 1, 4, 5 |
| `plugins/product-workflows/docs/commands/prd-ground.md` | its documentation page | 1, 8 |
| `plugins/product-workflows/agents/design-grounder.md` | reconciles a frame set against a **requirement inventory**, whatever the prefix | 5 |
| `plugins/product-workflows/agents/grounding-verifier.md` | re-derives a finding from a **requirement premise**, whatever the prefix | 5 |
| `plugins/product-workflows/agents/code-grounder.md` | grounds a list of **requirement claims**, whatever the prefix | 5 |
| `plugins/workflows-core/references/grounding-format.md` | §6.1's foreclosures rewritten against what ships | 5 |
| `plugins/workflows-core/references/next-phase-offer.md` | scope paragraph names two family globs | 3 |
| `scripts/check-docs.sh` | `scope_family` returns every glob on the scope line | 3 |
| `plugins/product-workflows/commands/update-prd.md` | reads `grounding/`, stamps `consumed_by: PRD` | 6 |
| `plugins/product-workflows/commands/create-ard.md` | reads grounding on both routes; seeds themes from findings | 7 |
| `plugins/product-workflows/commands/specify.md` | same | 7 |

---

### Task 1: Rename the command, its stop codes and its documentation page

**Files:**
- Rename: `plugins/product-workflows/commands/brd-ground.md` → `plugins/product-workflows/commands/prd-ground.md`
- Rename: `plugins/product-workflows/docs/commands/brd-ground.md` → `plugins/product-workflows/docs/commands/prd-ground.md`
- Modify: both renamed files (self-references, stop codes, Usage lines, frontmatter `name:`)
- Modify: `plugins/product-workflows/commands/brd-split.md`, `brd-interview.md`, `brd-package.md`, `brd-reconcile.md`, `brd-intake.md`, `create-prd.md`, `create-ard.md`, `specify.md`, `update-prd.md`, `epics.md` — every quoted `/brd-ground` invocation and every quoted `BRD_GROUND_*` code
- Modify: `plugins/product-workflows/docs/README.md`, `plugins/product-workflows/README.md`, `plugins/product-workflows/docs/workflow.md` — check 15's three index surfaces

**Interfaces:**
- Produces: the command name `/product-workflows:prd-ground`, the file paths above, and the sixteen `PRD_GROUND_*` codes from the map in this plan's header. Every later task uses these names.

- [ ] **Step 1: Record the pre-change surface, so the sweep is checkable afterwards**

```bash
git grep -c 'brd-ground' -- plugins scripts CLAUDE.md | grep -v CHANGELOG | awk -F: '{s+=$NF} END{print "brd-ground occurrences:", s}'
git grep -c 'BRD_GROUND_' -- plugins | grep -v CHANGELOG | awk -F: '{s+=$NF} END{print "BRD_GROUND_ occurrences:", s}'
```

Write both numbers into the task report. They are the denominator for Task 2's completeness check; do not
copy the numbers from this plan, which were measured before Task 1 ran.

- [ ] **Step 2: Rename both files with `git mv`, so history follows**

```bash
git mv plugins/product-workflows/commands/brd-ground.md plugins/product-workflows/commands/prd-ground.md
git mv plugins/product-workflows/docs/commands/brd-ground.md plugins/product-workflows/docs/commands/prd-ground.md
```

- [ ] **Step 3: Change the command's own frontmatter and Usage line**

In `plugins/product-workflows/commands/prd-ground.md`, the frontmatter `name:` becomes `prd-ground`.
The `Usage:` line becomes:

```
Usage: `/prd-ground <KEY> [--depends-on <BRD-KEY>…] [--derivation-matrix|--no-derivation-matrix] [--no-code] [--no-design] [--no-docs] [--docs <path>] [--rebaseline]`
```

Leave the `description:` frontmatter alone in this task — Task 8 rewrites it once, against what the
command finally does, so it is not edited twice.

- [ ] **Step 4: Apply the sixteen-code map inside the renamed command**

Every `BRD_GROUND_` prefix in `plugins/product-workflows/commands/prd-ground.md` becomes `PRD_GROUND_`.
The suffixes do not change. Verify none survives:

```bash
grep -c 'BRD_GROUND_' plugins/product-workflows/commands/prd-ground.md   # expect 0
```

- [ ] **Step 5: Apply the map and the command rename in the ten sibling commands**

Several commands quote `/brd-ground` in their own stop text and next-step offers, and three quote its
stop codes. Replace `/product-workflows:brd-ground` → `/product-workflows:prd-ground`, bare
`/brd-ground` → `/prd-ground`, and every `BRD_GROUND_*` → its mapped `PRD_GROUND_*`.

```bash
for f in brd-split brd-interview brd-package brd-reconcile brd-intake create-prd create-ard specify update-prd epics; do
  grep -n 'brd-ground\|BRD_GROUND_' plugins/product-workflows/commands/$f.md
done
```

Read each hit in its own sentence before changing it. **A hit inside a sentence explaining why a command
is *not* the answer still renames** — the command it names has moved, and leaving the old name there is a
dangling reference, not a preserved caveat.

- [ ] **Step 6: Rename the command in check 15's three index surfaces**

`docs/README.md` and `README.md` list it in prose or a table; `docs/workflow.md` names it in **prose and
inside the mermaid diagram**, which check 15 asserts separately. Change all four sites — the mermaid node
id may stay whatever it is, but its label must read `/prd-ground`:

```bash
grep -n 'brd-ground' plugins/product-workflows/docs/README.md plugins/product-workflows/README.md plugins/product-workflows/docs/workflow.md
```

- [ ] **Step 7: Update the renamed documentation page's own self-references**

In `plugins/product-workflows/docs/commands/prd-ground.md`, the title, every `/brd-ground` mention, every
quoted stop code, and every relative link **to** it from sibling pages (`grep -rn '](brd-ground.md)'
plugins/product-workflows/docs/`) move to the new name. Check 1 fails on a link that no longer resolves,
so this is gated.

- [ ] **Step 8: Run the gates**

```bash
python3 scripts/validate-catalog.py --selftest && python3 scripts/validate-catalog.py . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && ./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . \
  && python3 plugins/workflows-core/scripts/session-cost.py --selftest
```

Expect **check 4 or 15 to fail** if any of the three index surfaces was missed, and **check 1** if a
relative link dangles. Both are the point of running it here.

- [ ] **Step 9: Commit**

```bash
git add plugins/product-workflows/commands plugins/product-workflows/docs plugins/product-workflows/README.md
git commit -m "refactor(prd-ground): rename the command, its stop codes and its docs page"
```

---

### Task 2: Sweep the rename through the rest of the tree

**Files:**
- Modify: every remaining file naming `brd-ground`, derived by `git grep` — at time of writing this
  reaches `plugins/dev-workflows/docs/getting-started.md`, `docs/reference/environment.md`,
  `docs/roles-and-phases.md`; `plugins/product-workflows/agents/{code-grounder,design-grounder,grounding-verifier}.md`,
  `references/coverage-ledger-format.md`, `docs/brd-workflow.md`, `docs/getting-started.md`,
  `docs/roles-and-phases.md`, `docs/reference/{agents,environment,model-routing,references,resume-and-checkpoints,session-cost}.md`,
  the remaining `docs/commands/*.md`; `plugins/workflows-core/commands/frames.md`,
  `docs/commands/frames.md`, `docs/reference/agents.md`, `references/{cost-emission,docs-grounding,escalation-rules,feedback-emission,grounding-format,next-phase-offer,phase-handoff}.md`,
  `scripts/command-namespaces.json`; `scripts/check-docs.sh`; `CLAUDE.md`
- Modify: `plugins/product-workflows/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` — the `description` blurb only

**Interfaces:**
- Consumes: the names and stop-code map Task 1 produced.

- [ ] **Step 1: Derive the remaining surface — never work from this plan's list**

```bash
git grep -l 'brd-ground\|BRD_GROUND_' -- plugins scripts CLAUDE.md | grep -v CHANGELOG
```

The list in **Files** above was measured when the plan was written and Task 1 has since removed part of
it. This command is the authority.

- [ ] **Step 2: Sweep, reading each hit in its own paragraph**

Apply the same three substitutions as Task 1 step 5. **A phrase hit dispositions the whole paragraph,
not the matched sentence** — several of these files describe the command's behaviour around the name, and
a paragraph that says "`/brd-ground` is the BRD-to-PRD route's grounding step" needs its *claim* revisited,
not just its token swapped, because after this increment the command serves two routes.

Two files need more than substitution and are called out so they are not treated as mechanical:

- `plugins/workflows-core/references/cost-emission.md` — its §7 row `| /brd-ground | brd-to-prd | pa |`
  is gated by `check-docs.sh` check 8, which asserts every command handing `emit-cost` a fixed
  phase/role pair has a matching row and no row names a command that emits none. Rename the row's command
  and leave `brd-to-prd`/`pa` alone: the phase label is the route's, and the BRD route still exists.
- `plugins/workflows-core/scripts/command-namespaces.json` — a data file, not prose. Change the one
  string and change nothing else about the file's formatting.

- [ ] **Step 3: Rewrite the `description` blurb in both manifests**

`plugins/product-workflows/.claude-plugin/plugin.json` and the `product-workflows` entry in
`.claude-plugin/marketplace.json` both carry a capability blurb naming `/brd-ground`. **Replace the
wording, never append**, and keep both under 1024 characters — `validate-catalog.py` fails above it and
warns above 900. The two strings must be byte-identical to each other. Do not reformat
`marketplace.json`; change the one value in place.

```bash
python3 -c "import json;d=json.load(open('plugins/product-workflows/.claude-plugin/plugin.json'));print(len(d['description']))"
```

- [ ] **Step 4: Verify the sweep is complete**

```bash
git grep -c 'brd-ground\|BRD_GROUND_' -- plugins scripts CLAUDE.md | grep -v CHANGELOG
```

Expect **no output**. A hit inside `CHANGELOG.md` is correct and excluded — history keeps the old name,
exactly as `check-id-grammar.sh` excludes the changelog for the same reason.

- [ ] **Step 5: Run the gates and commit**

```bash
python3 scripts/validate-catalog.py --selftest && python3 scripts/validate-catalog.py . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && ./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . \
  && python3 plugins/workflows-core/scripts/session-cost.py --selftest
git add CLAUDE.md .claude-plugin/marketplace.json plugins scripts/check-docs.sh
git commit -m "refactor(prd-ground): sweep the rename through the rest of the tree"
```

---

### Task 3: Keep check 11's coverage across the rename

**Files:**
- Modify: `scripts/check-docs.sh` — `scope_family()`, its two callers, and its selftest cases
- Modify: `plugins/workflows-core/references/next-phase-offer.md` — the scope paragraph

**Interfaces:**
- Consumes: the command name `/prd-ground` from Task 1.
- Produces: a family derivation that covers both `product-workflows:brd-*` and `product-workflows:prd-*`.

**Why this task exists.** `check-docs.sh` check 11 gates the `<merge-clause>` placeholder in every
`choices:` offer made by a command of the family it derives from **one** glob on
`next-phase-offer.md`'s scope-paragraph line. `/prd-ground` leaving `brd-*` is correct — the spec's §4
rule is that `brd-` names the *route*, and this command now leaves it — but five commands still match, so
`route_n` stays above zero, the check keeps passing, and `/prd-ground`'s offers silently leave its
coverage. The script's own comments name this case: *"a plugin whose family commands were RENAMED drops
out of check 11 entirely."*

- [ ] **Step 1: Read the current parser and both call sites**

```bash
sed -n '835,880p' scripts/check-docs.sh          # scope_family and the comment block above it
grep -n 'scope_family' scripts/check-docs.sh      # both callers
```

`scope_family()` today greps the one line beginning `**Where this rule applies:`, extracts
`<qualifier><family>*` matches, and takes `head -1`.

- [ ] **Step 2: Make the scope paragraph name both globs**

In `plugins/workflows-core/references/next-phase-offer.md`, the scope-paragraph line currently binds the
rule to `` the six `/product-workflows:brd-*` commands ``. It must also name
`` `/product-workflows:prd-*` ``, with the reason stated in the file rather than only here — that
`/prd-ground` serves both routes and so is no longer a member of the `brd-` family, while every offer it
prints still names a downstream command whose `require-on-main` gate that same run feeds.

The line must keep beginning with `**Where this rule applies:` — the parser anchors on it and fails
loudly if it stops matching.

- [ ] **Step 3: Return every glob on that line, not the first**

```bash
scope_family() { # <next-phase-offer.md> <qualifier>  -> one family glob per line, or empty
  grep '^\*\*Where this rule applies:' "$1" 2>/dev/null \
    | grep -oE "$2[a-z][a-z0-9-]*\*" | sed "s|^$2||" | sort -u
}
```

The only change is dropping `head -1` and de-duplicating. **Do not widen the anchor grep** — the comment
block above the function records that binding the family to the scope-paragraph line, rather than to the
first such phrase anywhere in the file, is the whole point.

- [ ] **Step 4: Make both callers iterate the returned globs**

`check_merge_clause` and `check_handoff_applicability` each call `scope_family` and use the result as a
single glob. Each must now loop over the returned lines, accumulating `route_n` and `req_n` across all of
them. **The two empty dispositions stay exactly as they are** — `fail 11` in `check_merge_clause`, an
early `return` in `check_handoff_applicability` — and the emptiness test is now "the function returned no
line at all", not "the first line was empty".

The vacuity guard keeps its current meaning and message: if the accumulated `route_n` is zero across every
glob, the family was renamed or retired and the check examines nothing, so it fails loudly.

- [ ] **Step 5: Add the paired selftest cases**

`check-docs.sh --selftest` copies a fixture tree per case and asserts both the exit code and *which* check
fired. Add two cases, red and green, in the shape the file's existing pairs use:

- **red:** a fixture whose scope paragraph names both globs and whose `prd-*` command makes an offer
  naming a downstream command it writes the gate target for, with **no** `<merge-clause>` placeholder →
  check 11 must fire.
- **green:** the same fixture with the placeholder present → the gate must pass.

The pair is required rather than optional: an implementation that read both globs but only ever checked
the first passes the green case for the wrong reason, and only the red one discriminates.

- [ ] **Step 6: Run the gates and commit**

```bash
./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root .
git add scripts/check-docs.sh plugins/workflows-core/references/next-phase-offer.md
git commit -m "fix(gate): derive check 11's family from every glob the scope paragraph names"
```

---

### Task 4: Phase 0's idea-route branch, the handoff and the offer

**Files:**
- Modify: `plugins/product-workflows/commands/prd-ground.md` — Phase 0 steps 1, 2, 5a, 6, 8, 9; Phase 9; Phase 10; the Final report

**Interfaces:**
- Consumes: the file name and stop-code prefix from Task 1.
- Produces: the route flag this run carries (`route: brd | idea`), the five new stop codes, and the
  `claims` array Phase 5 draws from — unchanged in shape (`id` + `text` per entry), changed only in where
  it is read from.

- [ ] **Step 1: Add the `EPIC-` refusal to step 5a**

`resolve-address` searches every level `workflows-core:addressing` §3 bounds, so an Epic key resolves to a
folder — and an Epic folder holds no `prd.md`, because §2's tree places it one level up. Add the refusal
beside the existing `BRD-` one, tested on the **resolved directory's prefix** exactly as that one is:

```
PRD_GROUND_EPIC_LEVEL: <KEY> resolves to an Epic folder, and grounding is PRD-altitude on both routes. Run '/product-workflows:prd-ground <PRD-KEY>' against the PRD folder this Epic sits in.
```

State in the body why it is a prefix test and not a `prd.md` presence test: absence of a file is not
evidence of a kind, and the run that would create `prd.md` is `/create-prd`, not this one.

- [ ] **Step 2: Fork the route in step 5a, by positive evidence in both directions**

After the `BRD-` and `EPIC-` refusals, set the run's route:

- the resolved directory carries `brd-link.md` → `route: brd`. Every existing Phase 0 step applies
  unchanged.
- a `PRD-` directory with no `brd-link.md` → `route: idea`.
- resolved through `workflows-core:addressing` §5's legacy unprefixed fallback, where there is no prefix
  to test: **split on `prd.md` being present and asserting `kind: prd`.** Present → `route: idea`.
  Absent → the existing interrupted-intake branch, unchanged.

Write the rule into the body in the form the file already uses for §5.1's root question: positive
evidence each way, never the absence of a file.

- [ ] **Step 3: Gate `prd.md` on main, with the two-branch split row F needs**

On `route: idea`, step 6 gates `prd.md` instead of the ledger and the inventory. Execute `require-on-main`
(`Skill(skill: "workflows-core:reference", args: "phase-handoff require-on-main")`, §3) against
`<PRD-dir>/prd.md`, mapping the §3.7 return by `stopped` first. Row F splits on whether the file is in the
worktree at all — the same split the BRD route already makes, and for the same reason: *never produced*
and *produced, handoff declined* name different fixes.

```
PRD_GROUND_NEEDS_PRD: <KEY> has no prd.md on any ref and none in the folder — there is nothing to build a claim list from. Run '/product-workflows:create-prd <KEY>' and merge its handoff first.
```

```
PRD_GROUND_PRD_NOT_HANDED_OFF: <KEY>'s prd.md is written at <path> but is on no branch — its handoff was declined, so nothing is missing but the commit. Commit and merge it to the specs repo's default branch, then re-run '/product-workflows:prd-ground <KEY>'. Do not re-run /product-workflows:create-prd, which would rewrite the PRD rather than land the one on disk.
```

State why the gate is here rather than skipped: a claim list read off an unmerged artifact produces a
finding set nothing downstream can reproduce.

- [ ] **Step 4: Build the claim list from the PRD, and report the exclusions**

On `route: idea`, step 8 reads `<PRD-dir>/prd.md` instead of `brd/brd-inventory.md` and extracts, as
`claims` entries of `id` + `text`:

- every `[AC#n]` under `## Acceptance Criteria`;
- every `[FR#n]` under `## Functional requirements`;
- every `[US#n]` **whose story carries no `[AC#n]` beneath it**, and no others — a story is reached
  through its own acceptance criteria, and grounding both grounds one capability twice.

Excluded, each with its reason stated in the body: `[UC#n]`, because a journey's evidence is a list of
sites rather than an anchor; `[SM#n]` and `[SMC#n]`, because an outcome metric is not a property of a
commit and grounding one returns evidence about whether it is *instrumented* — a claim adjacent to the one
the row states, which is `workflows-core:grounding-format` §1's named failure.

**The exclusion is reported, not merely applied.** The Phase 1 confirmation and the Final report both
carry the count and the prefixes — "11 of 19 requirement rows ground; 8 excluded — 3 `[UC#n]`, 5
`[SM#n]`/`[SMC#n]`" — so a later reader cannot conclude the PRD was fully ground.

- [ ] **Step 5: Stop on zero claims, naming the right upstream fix**

```
PRD_GROUND_NO_CLAIMS: <KEY>'s prd.md holds no [AC#n] and no [FR#n] row, so there is no claim to ground. Add acceptance criteria with '/product-workflows:update-prd <KEY>' and re-run. Do not re-run /product-workflows:create-prd, which rewrites the PRD rather than adding to it.
```

Carry the file's existing reasoning for why this is a stop rather than an empty handoff: writing an empty
`code-grounding.md` would assert that grounding ran when nothing was checked.

- [ ] **Step 6: Refuse `--depends-on` on the idea route**

A `will-change` horizon names a prerequisite's **frozen** `status: decided` record. The idea route has no
decision register anywhere, so there is nothing to freeze and every finding is `current`. Refuse rather
than ignore:

```
PRD_GROUND_NO_PREREQUISITES: --depends-on names a prerequisite BRD whose frozen decisions set a finding's will-change horizon, and <KEY> is on the idea route, which has no decision register to read. Drop the flag and re-run; every finding on this route is horizon: current.
```

State in the body that a documented flag with no effect is R-4's shape, which is why this is a stop.

- [ ] **Step 6a: Confirm the remaining flags carry over unchanged, and say so**

`--no-code`, `--no-design`, `--rebaseline`, `--derivation-matrix`/`--no-derivation-matrix`, `--no-docs`
and `--docs <path>` all mean on the idea route what they mean on the other, including their existing
refusal combinations. Read each one's Phase 0 handling end to end and confirm nothing in it reads a
BRD-route artifact:

```bash
grep -n 'no-code\|no-design\|rebaseline\|derivation-matrix' plugins/product-workflows/commands/prd-ground.md | head -30
```

The one that needs looking at rather than assuming is **`--no-code`'s deferred check**, which stops when
`grounding/code-grounding.md` is absent, holds no `[CG#n]`, or holds one carrying no verifier outcome.
That is route-agnostic and works unchanged — but its stop text is reached from a step whose neighbours are
ledger-shaped, so confirm the message names nothing BRD-specific. State in the body that the flags carry
over, rather than leaving a reader to infer it from silence.

- [ ] **Step 7: Set the handoff prefix by route**

In Phase 9, `handoff-to-main` is called with `prefix: brd` on the BRD route and **`prefix: prd`** on the
idea route. The eight-prefix authority in `workflows-core:specs-repo-git` §1 and
`workflows-core:phase-handoff` §1 rule 3 is unchanged and no ninth prefix is added. Note in the body why
`prd` cannot collide in the sanctioned flow: this run gates `prd.md` with `require-on-main`, so it only
proceeds once `/create-prd`'s branch has merged.

`deliverable_paths` on the idea route are `grounding/code-grounding.md`,
`grounding/design-grounding.md` and `grounding/baselines.md`, and no BRD-route file.

- [ ] **Step 8: Fork the next-step offer, both branches carrying `<merge-clause>`**

Phase 10 keeps its `/brd-split` offer on the BRD route. On the idea route it offers
`/product-workflows:create-ard` and `/product-workflows:specify`, with
`/product-workflows:update-prd` named **first** where any claim came back `SUPPORTED` — a PRD asking for
something the code already does is worth revising before an architecture is authored against it.

Every option carries the `<merge-clause>` placeholder, per `workflows-core:next-phase-offer`; the array
stays 2–4 options with no authored "Other". If the idea-route branch would need five, put the full menu in
prose and let the array carry the likeliest, which is that reference's own overflow rule.

- [ ] **Step 9: Report the greenfield case rather than presenting a wall of absences**

In the Final report: where **every** claim came back a verified absence, say so outright — that this PRD
is greenfield against the repositories resolved — instead of listing the absences as though they were a
mixed result. A second run over the same greenfield folder is what this line exists to prevent.

- [ ] **Step 10: Run the gates and commit**

```bash
./scripts/check-docs.sh --root . && python3 scripts/validate-catalog.py . && ./scripts/check-id-grammar.sh --root .
git add plugins/product-workflows/commands/prd-ground.md
git commit -m "feat(prd-ground): take the idea route's claims from the PRD's own rows"
```

---

### Task 5: Design grounding on the idea route

**Files:**
- Modify: `plugins/product-workflows/agents/design-grounder.md` — the `inventory` contract and its Process
- Modify: `plugins/product-workflows/agents/grounding-verifier.md` — the `claim`/`inventory` wording
- Modify: `plugins/product-workflows/agents/code-grounder.md` — the `claims` wording
- Modify: `plugins/workflows-core/references/grounding-format.md` — §2's `claim` row, §6.1's foreclosures
- Modify: `plugins/product-workflows/commands/idea.md` — Phase 4.5's foreclosure
- Modify: `plugins/product-workflows/commands/prd-ground.md` — Phase 5 and Phase 7 dispatch wording

**Interfaces:**
- Consumes: Task 4's `claims` array, which is also `design-grounder`'s `inventory`.

- [ ] **Step 1: Widen the three agents from `[BR#n]` to a requirement row**

```bash
grep -n 'BR#' plugins/product-workflows/agents/code-grounder.md plugins/product-workflows/agents/design-grounder.md plugins/product-workflows/agents/grounding-verifier.md
```

Every hit means "the claim's id and text as given". None resolves a prefix or opens an inventory file, so
the change is wording plus **the output templates**, which is the half that matters: an agent told its
claims are "requirement rows" while still shown a `[BR#n]`-shaped example keeps producing `[BR#n]`-shaped
claims. That is BRD-6's shape — fixing the file's writer while leaving the template the model copies.

The wording each agent takes: *a requirement identifier and its text, as the caller supplied them —
`[BR#n]` on the BRD route, `[AC#n]`, `[FR#n]` or `[US#n]` on the idea route. **Resolve an id against the
list you were handed; never parse one out of the text.***

- [ ] **Step 2: Widen `grounding-format` §2's `claim` row to match**

§2's field table describes `claim` as "the `[BR#n]` premise under test". It becomes "the requirement
premise under test — a `[BR#n]` on the BRD route, an `[AC#n]`/`[FR#n]`/`[US#n]` on the idea route —
quoted or closely paraphrased". §8's re-derivation sentence takes the same widening.

- [ ] **Step 3: Rewrite §6.1's foreclosures against what now ships**

```bash
grep -n 'NOT shipped\|deliberately unbuilt\|not a gap\|has shipped' plugins/workflows-core/references/grounding-format.md plugins/product-workflows/commands/idea.md
```

Three paragraphs of §6.1 foreclose idea-route `[DG#n]` outright, and a fourth — the writer-versus-consumer
one — must be read alongside because it fixes what "consuming" means. `/idea` Phase 4.5 carries a fifth.

Each is rewritten against what the shipped thing enforces, read out of its own phase rather than assumed.
Two rules apply and neither is optional:

- **A sentence that named the absence as its *reason* for something needs a new reason, not a deletion.**
  §6.1's "only `/brd-ground` reads a `design/` folder as a frame set" was the reason `/frames` is an
  indexing command and not a grounding one. That remains true and needs re-stating against the new fact,
  not removing.
- **`/idea` Phase 4.5's paragraph stays true in its narrow sense and false in its broad one.** Writing an
  index is still not grounding, and `/idea` still dispatches no `design-grounder`. What changes is that
  the set it writes is now *read* later, by `/prd-ground` on the same folder. Say that.

- [ ] **Step 4: Note in `prd-ground.md` that the census is written on every run**

The common idea-route case is a folder with **no** `design/` at all. Phase 8 already writes
`design-grounding.md` on every run with the skip note and the `## Frame sets covered` census; confirm the
wording covers a run that found no `design/` directory, because `/create-ard` and `/specify` both report
*which of the four grounding inputs were absent*, and absent must keep meaning *the file is not there*,
never *the pass was declined*.

- [ ] **Step 5: Run the gates and commit**

```bash
./scripts/check-docs.sh --root . && ./scripts/check-id-grammar.sh --root .
git add plugins/product-workflows/agents plugins/product-workflows/commands/prd-ground.md plugins/product-workflows/commands/idea.md plugins/workflows-core/references/grounding-format.md
git commit -m "feat(grounding): ground a requirement row, not only a [BR#n]"
```

---

### Task 6: `/update-prd` reads grounding and stamps `consumed_by: PRD`

**Files:**
- Modify: `plugins/product-workflows/commands/update-prd.md` — Phase 0 step 5, Phase 2, Phase 5, the Final report

**Interfaces:**
- Consumes: the `grounding/code-grounding.md` and `grounding/design-grounding.md` Task 4 writes.
- Produces: the first `consumed_by: PRD` value written anywhere in the tree.

- [ ] **Step 1: Discover the grounding files as secondary grounding, ungated**

Phase 0 step 5 already discovers `prd.md`, any `ard.md`, `specification.md` and passed-in notes, and the
file states outright that these reads are **not** gated — `require-on-main` is never executed by this
command, because its authoritative base is the resolved folder's own `prd.md` and gating advisory
grounding would block a legitimate refresh over an unrelated branch.

Add `grounding/code-grounding.md` and `grounding/design-grounding.md` to that same discovery, under the
same rule. Say in the body that they are advisory here for the same reason the ARD and specification are,
and that a finding carrying no verifier outcome is not evidence and grounds nothing
(`workflows-core:grounding-format` §8).

- [ ] **Step 2: Carry the findings into the Phase 3 grill**

Phase 2 reads the base and the docs digest; the findings join it with **grill-rank** consumption, the same
mode the docs digest uses, so they rank challenges into the grill rather than being appended. The
highest-value case to name explicitly: a `[CG#n]` whose verdict says an `[AC#n]` the PRD asks for is
already satisfied at the pinned commit, which is scope the update can drop or narrow.

- [ ] **Step 3: Stamp `consumed_by: PRD` on what the update actually drew on**

In Phase 5, alongside writing the canonical and archived revisions, write `consumed_by: PRD` on each
`[CG#n]`/`[DG#n]` finding **this run actually drew on** — the same write `/create-ard` and `/specify`
already make at their own altitudes. Nothing else in the finding record is touched: no verdict, no
evidence, no id, no renumbering.

Add the grounding files to Phase 5's `deliverable_paths`, because the `consumed_by` writes land in them
and an uncommitted consumption record is one no later run can read.

- [ ] **Step 4: Report what is still unconsumed**

The Final report names, by id, every PRD-altitude finding still `consumed_by: none`, with an explicit
"none" where there are none, so an empty list reads as an empty set rather than as an unrun check. Where
no `grounding/` file was found at all, say that instead — a folder that was never ground is not a folder
whose findings went unconsumed.

- [ ] **Step 5: Run the gates and commit**

```bash
./scripts/check-docs.sh --root . && ./scripts/check-id-grammar.sh --root .
git add plugins/product-workflows/commands/update-prd.md
git commit -m "feat(update-prd): read grounding and give consumed_by: PRD its first writer"
```

---

### Task 7: `/create-ard` and `/specify` — read grounding on both routes, and seed themes from it

**Files:**
- Modify: `plugins/product-workflows/commands/create-ard.md` — Phase 0 confirm, Phase 2 reads, Phase 3 scan scoping, Phase 6 `consumed_by`, the handoff's `deliverable_paths`, the Final report
- Modify: `plugins/product-workflows/commands/specify.md` — the same phases plus its theme extraction

**Interfaces:**
- Consumes: the grounding artifacts Task 4 writes and the `consumed_by` convention Task 6 follows.

- [ ] **Step 1: Find every site that gates a grounding read on the BRD route**

```bash
grep -n 'BRD route' plugins/product-workflows/commands/create-ard.md plugins/product-workflows/commands/specify.md | grep -i 'ground\|consumed_by\|deliverable_paths'
```

Read each hit in its own paragraph. The gate becomes **"wherever the resolved folder holds
`grounding/`"**, in all four places each command has one: the Phase 0 confirmation line that reports which
inputs are present, the Phase 2 read, the `consumed_by` stamping, and the handoff's `deliverable_paths`.

- [ ] **Step 2: Leave the BRD-route-specific exclusions alone, and say which is which**

Both commands exclude the **baseline** `[CG#n]` findings from their unconsumed report, and both exclude
every finding whose `claim` cites a `[BR#n]` the slice's own `coverage-ledger.md` now shows as
`covered-by` — the state a sibling re-cut leaves.

The first applies on **both** routes and stays as it is. The second has **no subject** on the idea route,
which holds no ledger: it is reported as an empty set rather than as an unrun check, exactly as the
existing wording already requires for the first. Say so in the body, because a reader who assumes
otherwise either drops a live exclusion or invents a ledger read on a route that has none.

- [ ] **Step 3: Seed the theme set from the findings where grounding is present**

This is the composition rule and the reason grounding and the scan are not alternatives.

`/specify` already does this on the BRD route: it extracts capability themes from `spec-seed.md`, the
implementation-altitude `decided` statements and the derivation-matrix rows, and those feed Phase 3's repo
derivation and Phase 4's `code-scanner` dispatches **in place of** the PRD-derived themes. An idea-route
folder has no seed files, so without this step both commands read the `[CG#n]` set and then scan as though
it did not exist.

The rule for both commands: **where the resolved folder holds verified grounding, seed the theme set from
the findings before falling back to the command's own derivation.** A finding whose verdict says a
capability is absent is a theme worth scanning — that is where the work is. One whose verdict says it is
present names the code that already implements it, so the scan is directed at it rather than searching for
it.

**Neither scan becomes conditional, optional or removable, and neither command gains a flag.** The seeding
is an input change, so a folder with no grounding behaves exactly as it does today. Cite
`workflows-core:model-routing/classification` §8.5's seeded second round as the shipped precedent.

- [ ] **Step 4: Verify the seeding is stated in a different phase from the read**

```bash
grep -n 'grounding/' plugins/product-workflows/commands/specify.md | head -20
grep -n 'themes' plugins/product-workflows/commands/specify.md | head -20
```

The read and the theme derivation are **adjacent in the file and independent in effect** — which is the
adjacency a phrase sweep walks past. Confirm by reading both phases end to end that each carries its own
statement, rather than one being assumed to travel with the other.

- [ ] **Step 5: Run the gates and commit**

```bash
./scripts/check-docs.sh --root . && ./scripts/check-id-grammar.sh --root .
git add plugins/product-workflows/commands/create-ard.md plugins/product-workflows/commands/specify.md
git commit -m "feat(ard,spec): read grounding on both routes and seed the scan from it"
```

---

### Task 8: Documentation, `CLAUDE.md`, changelogs and versions

**Files:**
- Modify: `plugins/product-workflows/docs/commands/prd-ground.md` — the idea route, the claim source, the exclusions, the new stops
- Modify: `plugins/product-workflows/docs/commands/{create-ard,specify,update-prd,idea}.md`
- Modify: `plugins/product-workflows/docs/workflow.md` — the mermaid diagram
- Modify: `plugins/product-workflows/docs/README.md`, `plugins/product-workflows/README.md`
- Modify: `plugins/product-workflows/commands/prd-ground.md` — the `description:` frontmatter, once
- Modify: `CLAUDE.md`
- Modify: `plugins/product-workflows/CHANGELOG.md`, `plugins/workflows-core/CHANGELOG.md`
- Modify: `plugins/product-workflows/.claude-plugin/plugin.json`, `plugins/workflows-core/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

**Interfaces:**
- Consumes: everything Tasks 1–7 shipped. **This task is written last**, against the tree as it finally
  stands — a verification record written before the last change is a record of something else.

- [ ] **Step 1: Move `/prd-ground` into its own mermaid subgraph, reached from both routes**

In `plugins/product-workflows/docs/workflow.md`, take the node out of the BRD subgraph and give it one of
its own, with the claim source on each inbound edge label. Solid from `/brd-split (root)` because
grounding is required before the `allocate-only` walk; dotted from `/create-prd` because it is optional on
the idea route, and the existing direct `createvi --> createard` and `createvi --> specify` edges stay.

```
    subgraph GR["PA — grounding (one command, both routes)"]
        prdground["/prd-ground"]
    end

    brdsplitroot -->|each confirmed slice — claims are its [BR#n] rows| prdground
    prdground -->|verified [CG#n]/[DG#n] — required before the walk| brdsplitslice
    createvi -.->|optional — claims are the PRD's own [AC#n]/[FR#n]| prdground
    prdground -.->|verified [CG#n]/[DG#n]| createard
    prdground -.->|verified [CG#n]/[DG#n]| specify
```

Check 15 asserts membership in the diagram separately from the page, so this is gated.

- [ ] **Step 2: Rewrite the command page for two routes**

`docs/commands/prd-ground.md` gains: which folder puts the run on which route and how that is detected;
the idea route's claim source and the three excluded prefixes **with the reason for each**; the five new
stops; the `prd/` branch prefix; that grounding is optional on this route and nothing gates on it; and
§9's signal for when it is worth running — an existing product being extended, versus greenfield where
every finding is a verified absence at one Opus re-derivation each.

Every claim on the page is derived from the thing that runs it — the synopsis from the command's
argument-parsing phase, the phases from its `## Phase` headings, the stops from their own text.

- [ ] **Step 3: Update the four sibling pages**

`create-ard.md` and `specify.md`: the grounding inputs are read wherever the folder holds them, not only
on the BRD route, and the themes are seeded from the findings. `update-prd.md`: it reads grounding and
stamps `consumed_by: PRD`. `idea.md`: `--ground-code` is still a scoping scan with no `[CG#n]` and no
verifier, and the frame set it writes is now read later by `/prd-ground` on the same folder.

- [ ] **Step 4: Rewrite the command's `description:` frontmatter, once**

It is user-visible and must now describe both routes. Keep it a stable capability blurb, not a changelog.

- [ ] **Step 5: Update `CLAUDE.md`**

The workflow map's `/brd-ground` line, the `/create-ard` and `/specify` lines, the docs-grounding consumer
list, and the BRD-route tail paragraph.

**And record the rule that bounds the rename, because without it the next reader renames three more
commands.** Four of the six route commands refuse a root, so "runs on a slice" is the wrong test:
`brd-` names the **route**, not the folder kind, and `/prd-ground` is the only one of the six that leaves
the route. State it where the family is described, beside the invariant about the six-command route.

**Re-derive every count you touch against the tree** — the
command count for `product-workflows` stays at twelve (a rename, not an addition) and the documentation
page count stays where it is, but check both rather than assuming, since nothing gates a number in this
file.

- [ ] **Step 6: Write both changelogs**

`product-workflows` **3.0.0** with the rename called out as the breaking change and the rule that bounds
it — `brd-` names the route, not the folder kind, and `/prd-ground` is the only one of the six that leaves
the route. `workflows-core` **1.3.0** for the widened `grounding-format` contract, §6.1's rewritten
foreclosures, the scope paragraph's second family glob, and the renamed citations.

- [ ] **Step 7: Bump both versions in both places**

```bash
grep -h '"version"' plugins/product-workflows/.claude-plugin/plugin.json plugins/workflows-core/.claude-plugin/plugin.json
grep -n '"name": "product-workflows"' -A 1 .claude-plugin/marketplace.json
grep -n '"name": "workflows-core"' -A 1 .claude-plugin/marketplace.json
```

Change the one value in each place. Do not reformat `marketplace.json`.

- [ ] **Step 8: Run all seven gates and commit**

```bash
python3 scripts/validate-catalog.py --selftest && python3 scripts/validate-catalog.py . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && ./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . \
  && python3 plugins/workflows-core/scripts/session-cost.py --selftest
git add CLAUDE.md .claude-plugin/marketplace.json plugins/product-workflows plugins/workflows-core
git commit -m "docs(prd-ground): document the idea route; product-workflows 3.0.0"
```

---

## The whole-branch sweep, run once after Task 8

Not a task — the discipline every task's own sweep is measured against, and the one that caught what the
per-task sweeps missed on the previous two increments.

- **Scope it to `plugins/`, never to the plugin the capability shipped from.** The family's shared
  authorities live in `workflows-core`, and a per-plugin recipe is structurally blind to them. On the
  sibling re-cut, `workflows-core:next-phase-offer` and `workflows-core:phase-handoff` §3.4 both reached
  the final review untouched for exactly this reason.
- **Back the phrase sweep with an end-to-end read** of every phase this plan touches. The two most
  expensive misses on the previous branch contained none of the swept phrases at all.
- **Run an exclusivity probe as its own axis** — `only when`, `is the only`, `nothing else`, `and no
  other`, `only ever`. That is where a falsified claim hides when it names none of the change's
  vocabulary, and it is how §6.1's foreclosures would have been found without being told about them.
- **A phrase hit dispositions the whole paragraph**, not the matched sentence.
