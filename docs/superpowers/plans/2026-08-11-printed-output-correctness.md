# Printed-Output Correctness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every command name a `dev-workflows` run prints is one the user can actually invoke, and the routing graph contains every command that cites it as its authority.

**Architecture:** A naming rule (rule 6) is added to `references/next-phase-offer.md`, and then the qualified form is written **literally** into the source at every printed site across five named surfaces. Correctness is a static property of shipped text, never a runtime behaviour — this is the whole point, and it is what lets grep gate the result.

**Tech Stack:** Markdown instruction files executed by an LLM at runtime. No build, no test framework. Verification is grep, diff, and reading.

**Spec:** `docs/superpowers/specs/2026-08-11-printed-output-correctness-design.md`

**Ships as:** `dev-workflows` 2.46.0 (canonical + mgd), 2.16.0 (copilot).

## Global Constraints

- **G-1 — Authoring order.** Canonical (`/workspace/ihudak-claude-plugins`) is authored first. mgd (`/workspace/mgd-claude-plugins`) is produced by **copying** canonical's changed files, never by re-editing them. Copilot (`/workspace/ihudak-copilot-plugins`) is adapted by hand into its own dialect.
- **G-2 — mgd identity set is exactly SIX files**, never copied from canonical: `plugins/dev-workflows/.claude-plugin/plugin.json`, `plugins/dev-workflows/LICENSE`, `plugins/dev-workflows/README.md`, `plugins/dev-workflows/references/dependencies.md`, root `CLAUDE.md`, root `.claude-plugin/marketplace.json`. `references/dependencies.md` correctly says `mgd-plugins` where canonical says `ihudak-plugins` — that is identity content, **not drift**.
- **G-3 — The qualification criterion.** A site is qualified **iff** it is (1) printed to the user AND (2) names a command as an **invocation target** — something the user could type to run it. Two classes are printed but are NOT invocation targets and MUST be left bare: data-field values (`command: /idea` passed to `emit-auto` / `emit-cost`) and descriptive references to a workflow or phase ("Phase 5 of the inherited `/implement` workflow").
- **G-4 — Never shorten an already-qualified name.** The README mermaid diagram's existing `/dev-workflows:statusline` node stays byte-identical. Re-bareing it would print a name that resolves to Claude Code's built-in — the exact defect this sub-project removes.
- **G-5 — Out of scope, do not touch:** `references/` prose (425 occurrences) other than `next-phase-offer.md`; `agents/` prose (122); README command tables and role tables; root `CLAUDE.md` prose; copilot's slash-style refs outside printed surfaces (~66 — these **work**, slash invocation is valid in Copilot, they are merely inconsistent).
- **G-6 — R1, the load-bearing constraint.** The qualified form is written **literally into the source** at every site. A site is NEVER satisfied by adding a citation to rule 6, or by any instruction telling the model to qualify names at runtime. Confirmed hazard: `commands/implement.md:111` prints a `/ready` recommendation and there are **zero** citations of `next-phase-offer.md` anywhere near it — the offer contract is consulted ~500 lines later. Gated by V16.
- **G-7 — Counting discipline.** Every count is whitespace-normalised (`tr '\n' ' '`) because several files hard-wrap; line-level `grep -c` produced four false counts in the previous sub-project. Surface i extraction MUST be indent-tolerant (`/^[[:space:]]*### Next step/`) — anchoring at line start finds 11 sites in 5 files; the indent-tolerant form finds 15 in 7 and adds `ready.md` and `release-notes.md` outright.
- **G-8 — Copilot dialect.** Copilot prints `<name>:` (e.g. `release-notes: <VI>`), never `/name`. Slash-style invocation works there, but `/release-notes`, `/upgrade`, `/feedback`, and `/statusline` are Copilot built-ins and win the collision.
- **G-9 — Release files.** Canonical + mgd → `2.46.0`; copilot → `2.16.0`. **All THREE** `marketplace.json` catalogs must be bumped: canonical root `.claude-plugin/marketplace.json`, mgd root `.claude-plugin/marketplace.json`, and copilot `.github/plugin/marketplace.json` — note copilot's lives at a **different path**, which is how it gets forgotten. A catalog was missed in 2.42.0, and the first draft of this plan repeated the miss for copilot while warning against it for the other two.
- **G-10 — CHANGELOGs are append-only.** Add a new entry; never rewrite shipped history. Verify version ordering stays monotonic.
- **G-11 — Commit trailer.** Every commit message ends with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.
- **G-12 — Counts in this plan are OBSERVATIONS from spec time, not gates.** Re-derive every one. If a derived count differs from the plan, **STOP and report the mismatch** — do not force the number and do not invent a site to reach it. In the previous sub-project, implementers who flagged a count mismatch were right 6 times out of 6.

---

## The command-name regex

Every task uses this. It is written once here and referenced by number.

```bash
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
BARE="(^|[^:a-z-])/($CMDS)\b"
```

Two properties, both verified:

- `prompt-brainstorm` and `prompt-grill-me` precede `prompt` in the alternation, so longer names win.
- `[^:a-z-]` makes the pattern **go to zero as sites are fixed**: in `/dev-workflows:release-notes` the slash is followed by `dev-workflows`, not by `release-notes`. It also excludes file paths (`references/design-format.md`), where the character before the slash is a letter.

## File structure

**Canonical — `/workspace/ihudak-claude-plugins/`**

| File | Responsibility | Task |
|---|---|---|
| `plugins/dev-workflows/references/next-phase-offer.md` | rule 6; `/update-vi` routing node; surface v qualification | 1 |
| `plugins/dev-workflows/commands/{design,document,epics,implement,ready,release-notes,specify}.md` | surface i sites | 2 |
| `plugins/dev-workflows/commands/{create-ard,create-vi,design,document,implement,specify,update-vi}.md` | surface ii sites | 2 |
| `plugins/dev-workflows/commands/*.md` (15 files) | surfaces iii/iv classification + sweep | 3 |
| `plugins/dev-workflows/commands/statusline.md` | bespoke paragraph → cites rule 6 | 4 |
| `plugins/dev-workflows/README.md` | `/update-vi` node in the mermaid diagram | 4 |
| `plugins/dev-workflows/.claude-plugin/plugin.json` | version → 2.46.0 | 5 |
| `plugins/dev-workflows/CHANGELOG.md` | 2.46.0 entry | 5 |
| `.claude-plugin/marketplace.json` | catalog version | 5 |

**mgd — `/workspace/mgd-claude-plugins/`**

| File | Responsibility | Task |
|---|---|---|
| `plugins/dev-workflows/**` (copied from canonical) | all content changes | 6 |
| `CLAUDE.md` (root, identity file — hand-edited) | `doc-structure-conventions.md` paragraph | 6 |
| `plugins/dev-workflows/.claude-plugin/plugin.json` (identity) | version → 2.46.0 | 6 |
| `plugins/dev-workflows/CHANGELOG.md` (copied) | 2.46.0 entry | 6 |
| `.claude-plugin/marketplace.json` (identity) | catalog version | 6 |

**Copilot — `/workspace/ihudak-copilot-plugins/`**

| File | Responsibility | Task |
|---|---|---|
| `dev-workflows/skills/_shared/next-phase-offer.md` | rule 6 (copilot dialect); `update-vi:` routing node | 7 |
| `dev-workflows/skills/*/SKILL.md` | printed-surface sweep in `<name>:` dialect | 7 |
| `dev-workflows/skills/create-vi/SKILL.md:136` | `epics:` Phase 6.1 → 6.2 | 7 |
| `dev-workflows/README.md` | `update-vi` node in the mermaid diagram | 7 |
| `dev-workflows/.plugin/plugin.json` | version → 2.16.0 | 7 |
| `.github/plugin/marketplace.json` | catalog version → 2.16.0 — **different path** from the other two editions | 7 |
| `dev-workflows/CHANGELOG.md` | 2.16.0 entry | 7 |

---

## Four deliberate deviations from the spec

All four were found while deriving the site inventory or during execution. They are recorded here because a reviewer will otherwise read them as defects.

**D-1 — Surface v widens from "the routing graph section" to the whole file.** The spec scoped surface v to `## The routing graph` (35 sites). The plan qualifies **all 63** command names in `next-phase-offer.md`, except rule 6's three citations of Claude Code's own built-ins (Task 1 Step 4). Reason: rule 5's Epic-fan-out examples (`` `/design <VI> E1` → `/implement <VI> E1` ``) are *templates for printed offers*, and a bare example is a leak path — a model reproducing rule 5 emits bare names. Qualifying the whole file also replaces a fiddly section boundary with a near-trivial gate.

**D-1 and G-3 deliberately disagree, and the asymmetry is intended.** `next-phase-offer.md` is qualified uniformly; command files follow G-3's invocation-target test. So the identical annotation `*(No `/design` — no Epics yet.)*` ends up **qualified** at `next-phase-offer.md:60` and **bare** at `create-ard.md:138`. This is not an oversight:

- The two files have different jobs. `next-phase-offer.md` is the source a run reads to *construct* printed offers, so uniform qualification there is protective — a bare name in it can be copied into output. A command file is mixed prose and printed text, where G-3 is the only workable test.
- Qualifying a descriptive negation states nothing false — `/dev-workflows:design` genuinely is the command not being offered. That is what separates it from rule 6's case, where qualifying the built-in citations made the sentence actively untrue and had to be reverted.

A reviewer comparing the two files will see the mismatch; this paragraph is the answer.

**D-2 — Surface ii is not a blanket zero.** The spec's V3 reads "0 bare names on `choices:` lines". **Three** sites are printed-adjacent but are not invocation targets and must stay bare per G-3:

- `commands/implement.md:387` and `commands/implement.md:445` — both read "Skip tests for this run (document why in the final report — Phase 5 of the inherited `/implement` workflow)". That `/implement` names the workflow the run is already inside, not something to type.
- `commands/create-ard.md:60` — the `/design` in "**Tiered HARD model gate (like `/design`):**", prose comparing this command's gate to `/design`'s, addressed to a reader of the source. The same line's `/create-ard`, inside the printed `choices:` array, **is** qualified.
- `commands/create-ard.md:138` — the `/design` in the trailing annotation `*(No `/design` — no Epics yet.)*`, which sits **outside** the `choices:` array and names the option that is NOT offered. A negation is not an invocation target. The same line's three in-array names **are** qualified.

V3 therefore gates at **exactly these 4 documented exceptions**, not 0.

**How to find these reliably:** compute each line's `choices: [ … ]` bracket span and test every regex match's character position against it. A match outside the span is prose and takes a G-3 verdict on its own merits. Two of the four exceptions were found this way after inspection alone had missed them.

**Surface ii's extraction is line-based, and that is its one weakness.** A line matching `choices:` may also carry ordinary prose outside the array, so occurrence counts alone cannot be trusted to equal qualification counts — `create-ard.md:60` was mis-tallied exactly this way during planning, and the arithmetic ("23 qualify") forced a wrong edit before it was caught. Every surface-ii line must be classified by reading, not by counting. Corrected totals: **25 occurrences on 14 lines → 21 qualify, 4 stay bare.**

**D-3 — a SIXTH printed surface exists; the spec named five.** Found after Task 2 shipped, by auditing the residue the five surfaces left behind. It is the risk R4 predicted — a printed site phrased on an axis none of the five catches — and it is the largest single miss in this sub-project: **17 lines, 25 occurrences**, more than surface i.

**Surface vi — printed guidance naming the next command, outside both a `### Next step` heading and a `choices:` array.** Two detectors:

```bash
# vi-a — role-handoff / context-hygiene lines: recommend /compact or /clear AND name what you run next
grep -nHE '/(compact|clear)\b' *.md | grep -E "(^|[^:a-z-])/($CMDS)\b"     # 14 lines, 22 occurrences

# vi-b — annotated offer bullets: a bullet whose first token is a command name, expanding a printed choices: block
grep -nHE "^[[:space:]]*[-*][[:space:]]+\*{0,2}\`?/($CMDS)\b" *.md          # 5 lines, 5 occurrences
```

Why the five missed it: a line like ``- **Continuing as PM (`/release-notes <VI>` after the round-trip)?** → run **`/compact`**`` sits under a `### Context hygiene` heading, carries no `choices:`, no quotation, and no instruction verb. It is nonetheless printed, and `/release-notes <VI>` is exactly what the user types next.

`/compact` and `/clear` in these lines are Claude Code built-ins and stay bare, exactly as in Task 1's carve-out.

Not every hit qualifies — vi-b in particular is mixed. `create-ard.md:14-15` document the command's two calling forms to a reader of the source and stay bare; `create-vi.md:213-215` annotate a printed offer and qualify. Classify by reading, as with surfaces iii/iv.

**D-4 — a SEVENTH printed surface; found by the Task 3 reviewer.** The spec named five, D-3 added a sixth, and this is the seventh. It is the more instructive of the two late finds, because the Critical it produced was **the brief's own worked ACCEPT example** — `idea.md:143`, cited in the plan as the model of a surface-iii site, was never in the candidate set the plan generated.

**Surface vii — printed offers and STOP/error messages whose command mention the line-based detectors cannot reach.** Two failure modes:

- **vii-a — multi-line printed literals.** `idea.md:143-147` prints an italic quoted offer where the trigger phrase ("then run") is on one line and the command on the next. The quoted-literal detector needs the `"…"` span on a single line; the trigger-verb detector needs the verb within 120 characters *on the same line*. A two-line sentence defeats both.
- **vii-b — STOP/error messages with an embedded run-instruction.** `CREATE_VI_NEEDS_KEY: … then re-run '/create-vi <KEY>'`, `PROFILE_REQUIRED: …; run /docs-profile`, `spec not handed off — run /specify`. Single-quoted or unquoted, and "re-run" was not in the trigger-verb list.

```bash
# vii-a — bare name within 3 lines AFTER a quoted/italic literal opener
for f in *.md; do awk -v F="$f" '/\*"|: \*"/{for(i=0;i<4;i++){if((getline line)>0){print F":"NR": "line}}}' "$f"; done 2>/dev/null | grep -E "(^|[^:a-z-])/($CMDS)\b"
# vii-b — run / re-run instruction, or a NAMED_ERROR: code, carrying a bare command
grep -nHE "([A-Z][A-Z0-9_]{3,}:|re-run|\brun\b)[^.]{0,170}(^|[^:a-z-])/($CMDS)\b" *.md
```

**The distinction that decides vii-b.** A STOP message that merely names which command needs the missing input is self-referential and stays bare — the five `*_NEEDS_JIRA` messages (`design.md:36`, `epics.md:30`, `release-notes.md:37`, `ready.md:44`, `specify.md:39`). One that additionally tells the user what to type is an invocation target and qualifies. Several lines carry both and take a split verdict, exactly like `create-ard.md:60`.

**The standing lesson.** Two surfaces were discovered *after* the spec froze, both by auditing the residue rather than by re-reading the spec. Any future sweep of this kind should budget for that audit as a first-class step, not a verification afterthought: a detector set proves only what it can see, and enumerating on N axes never proves there is no axis N+1. See the spec's risk R4, which predicted exactly this and was right twice.

---

## Task 1: Rule 6 and the routing graph

**Files:**
- Modify: `plugins/dev-workflows/references/next-phase-offer.md`

**Interfaces:**
- Produces: rule 6, cited by Task 4's `statusline.md` edit. The `/dev-workflows:<command>` form established here is the exact string every later task writes.

- [ ] **Step 1: Record the baseline count**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/references
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
grep -oE "(^|[^:a-z-])/($CMDS)\b" next-phase-offer.md | wc -l
```

Expected: `63`. If it differs, STOP and report (G-12).

- [ ] **Step 2: Add rule 6 to the offer contract**

The `## The offer contract (5 rules)` heading becomes `## The offer contract (6 rules)`. Append after rule 5, verbatim:

```markdown
6. **Fully qualified when printed** — every command name the run PRINTS for the user to invoke is
   written `/dev-workflows:<command>`. A bare `/<command>` can resolve to a Claude Code built-in of
   the same name — Claude Code's own `/release-notes`, `/upgrade`, and `/statusline` all collide
   today, and the built-in wins — so the bare form is NEVER printed. Prose that describes the
   pipeline to a reader of this plugin's source keeps the short form.
```

The three names in that sentence stay **bare** — they are Claude Code's built-ins, not this plugin's commands. See Step 4's carve-outs.

- [ ] **Step 3: Add the `/update-vi` re-entry node to the routing graph**

In `**PM — ideation & framing**`, after the `/create-vi` entry, insert verbatim:

```markdown
- `/dev-workflows:update-vi <KEY>` — re-entry, not a linear node: reached when
  `/dev-workflows:create-vi` redirects an existing-VI call, or when a later phase forces a VI
  refresh. After the paste-into-Jira + re-import round-trip it offers:
  `/dev-workflows:release-notes <VI>` (PM), `/dev-workflows:create-ard <VI>` (PA, if one exists),
  `/dev-workflows:specify <VI>` (PE, if one exists).
```

The three paths match what `commands/update-vi.md` Phase 6 prints. Do **not** describe them as "the same forward paths as `/create-vi`" — `/create-vi` also offers `/dev-workflows:epics <VI>`, which `/update-vi` does not.

- [ ] **Step 4: Qualify every command name in the file (D-1)**

Rewrite every `/<command>` to `/dev-workflows:<command>` throughout `next-phase-offer.md` — the routing graph, rules 1–6, the `## Surface` section, and the `## Not pipeline nodes` list. This file is the offer contract; every command name in it is either a printed template or an example of one.

**Two carve-outs. Both name commands that are not this plugin's, so qualifying them would state a falsehood:**

- `/compact` and `/clear` in the session-hygiene paragraph — Claude Code built-ins, correctly named as such.
- **Rule 6's own three illustrative names.** Rule 6 cites `/release-notes`, `/upgrade`, and `/statusline` as examples of names that *collide with a Claude Code built-in*. The qualified forms are precisely the ones that do NOT collide, so qualifying them inverts the rule's meaning. Under G-3 these are descriptive references to an external fact, not invocation targets. Rule 6's text as written in Step 2 already reads "Claude Code's own `/release-notes`, `/upgrade`, and `/statusline`" — the possessive is deliberate, marking them as external so no later sweep re-qualifies them.

- [ ] **Step 5: Verify the file is clean**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/references
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
echo "bare (expect 3):     $(grep -oE "(^|[^:a-z-])/($CMDS)\b" next-phase-offer.md | wc -l)"
echo "qualified (expect >=66): $(grep -oE "/dev-workflows:($CMDS)\b" next-phase-offer.md | wc -l)"
echo "update-vi (expect >=1):  $(grep -c 'dev-workflows:update-vi' next-phase-offer.md)"
echo "rule 6 (expect 1):       $(grep -c 'Fully qualified when printed' next-phase-offer.md)"
echo "heading (expect 1):      $(grep -c 'offer contract (6 rules)' next-phase-offer.md)"
```

**`bare` is 3, not 0** — exactly rule 6's three Claude Code built-in names (Step 4's second carve-out). Confirm they are those three and nothing else:

```bash
grep -oE "(^|[^:a-z-])/($CMDS)\b" next-phase-offer.md | tr -d ' '
# expect exactly: /release-notes /upgrade /statusline
```

Qualified is `>= 66` rather than exactly 63 because Step 3 adds new names.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/next-phase-offer.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): next-phase-offer rule 6 + /update-vi routing node

Rule 6 makes the fully-qualified form the contract for printed command
names. A bare /<command> can resolve to a Claude Code built-in of the
same name; /release-notes, /upgrade and /statusline all collide today.

/update-vi joins the routing graph as a re-entry node. update-vi.md
cites this file as the authority for its Phase 6 offer, and the file
had never mentioned it.

Qualifies the whole file rather than only the routing-graph section:
rule 5's fan-out examples are templates for printed offers, so a bare
example is a leak path.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Surfaces i and ii — the structural sweep

**Files:**
- Modify: `plugins/dev-workflows/commands/create-ard.md`, `create-vi.md`, `design.md`, `document.md`, `epics.md`, `implement.md`, `ready.md`, `release-notes.md`, `specify.md`, `update-vi.md`

**Interfaces:**
- Consumes: the `/dev-workflows:<command>` form from Task 1.
- Produces: surfaces i and ii clean, so Task 3 can skip any candidate line already handled here.

Surface i is `### Next step` sections; surface ii is `choices:` arrays. Both are structurally delimited, which is why they are one task and gate cleanly.

- [ ] **Step 1: Confirm the surface i inventory**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
for f in *.md; do
  awk -v F="$f" '/^[[:space:]]*### Next step/{inb=1} /^[[:space:]]*#{1,3} [A-Z]/{if(inb && !/### Next step/)inb=0} inb{print F":"NR":"$0}' "$f"
done | grep -E "(^|[^:a-z-])/($CMDS)\b" | sed 's/\(:[0-9]*:\).*/\1/' | uniq -c
```

Expected — 8 lines carrying 15 sites:

| Site | Names to qualify |
|---|---|
| `design.md:434` | `/implement`, `/design` |
| `document.md:1207` | `/release-notes` |
| `epics.md:621` | `/specify`, `/create-ard` |
| `implement.md:627` | `/implement`, `/document`, `/release-notes` |
| `ready.md:348` | `/implement` |
| `ready.md:349` | `/ready` |
| `release-notes.md:288` | `/create-ard`, `/epics` |
| `specify.md:537` | `/design`, `/specify`, `/epics` |

All 15 are invocation targets. All 15 qualify.

- [ ] **Step 2: Qualify surface i**

Rewrite each name in the table above to `/dev-workflows:<command>`, preserving the surrounding argument placeholders (`<VI>`, `<Epic>`, `<another-Epic>`) exactly.

Example — `design.md:434` before:

```
hand to the team → `/implement <VI> <Epic>` (depth); the **Epic fan-out** `/design <VI> <another-Epic>` designs a sibling Epic (breadth).
```

after:

```
hand to the team → `/dev-workflows:implement <VI> <Epic>` (depth); the **Epic fan-out** `/dev-workflows:design <VI> <another-Epic>` designs a sibling Epic (breadth).
```

- [ ] **Step 3: Confirm the surface ii inventory**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
grep -nH 'choices:' *.md | grep -E "(^|[^:a-z-])/($CMDS)\b" | cut -d: -f1,2
```

Expected — 14 lines carrying 25 sites. **21 qualify; 4 stay bare (D-2).**

Classify each line by **reading** it, not by counting matches: a `choices:` line can also carry prose outside the array, and the two can take opposite verdicts on the same line.

| Site | Verdict |
|---|---|
| `create-ard.md:60` | **split verdict** — qualify `/create-ard` ("I'll relaunch … on Opus", inside the array); **LEAVE BARE** the `/design` in "Tiered HARD model gate (like `/design`)", which is prose comparing the two commands' gates |
| `create-ard.md:138` | **split verdict** — qualify the three names inside the `choices:` array; **LEAVE BARE** the `/design` in the trailing `*(No `/design` — no Epics yet.)*` annotation, which names the option that is not offered |
| `create-ard.md:139` | qualify (3) |
| `create-vi.md:52` | qualify — "Switch to `/update-vi <KEY>`" |
| `create-vi.md:56` | qualify |
| `create-vi.md:210` | qualify (3) |
| `design.md:150` | qualify — "I'll relaunch `/design` on Opus" |
| `document.md:260` | qualify — "Relaunch `/document` under Opus" |
| `document.md:1407` | qualify (2) |
| `implement.md:70` | qualify — "resolve the design's open questions in `/design` first" |
| `implement.md:387` | **LEAVE BARE** — "Phase 5 of the inherited `/implement` workflow" names the workflow, not an invocation target (G-3) |
| `implement.md:445` | **LEAVE BARE** — identical text to `:387` |
| `specify.md:217` | qualify — "Split into Epics first with `/epics`" |
| `update-vi.md:109` | qualify (3) |

- [ ] **Step 4: Qualify surface ii, honouring the two exceptions**

Example — `create-vi.md:210` before:

```
choices: ["Draft the release note now — /release-notes <KEY> (PM) (Recommended)", "Hand to a Product Architect — /create-ard <KEY> (PA, optional)", "Hand to a Product Engineer — /epics <KEY> (PE)", "Stop here", "Other… (describe)"]
```

after:

```
choices: ["Draft the release note now — /dev-workflows:release-notes <KEY> (PM) (Recommended)", "Hand to a Product Architect — /dev-workflows:create-ard <KEY> (PA, optional)", "Hand to a Product Engineer — /dev-workflows:epics <KEY> (PE)", "Stop here", "Other… (describe)"]
```

`implement.md:387` and `:445` are edited **not at all**.

- [ ] **Step 5: Verify both surfaces**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
echo "surface i bare (expect 0):"
for f in *.md; do awk '/^[[:space:]]*### Next step/{inb=1} /^[[:space:]]*#{1,3} [A-Z]/{if(inb && !/### Next step/)inb=0} inb' "$f"; done | grep -cE "(^|[^:a-z-])/($CMDS)\b"
echo "surface ii bare (expect exactly 4):"
grep -nH 'choices:' *.md | grep -E "(^|[^:a-z-])/($CMDS)\b" | cut -d: -f1,2
```

The second command must print exactly `create-ard.md:60`, `create-ard.md:138`, `implement.md:387`, and `implement.md:445` — the four D-2 exceptions, and nothing else.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/
git commit -m "$(cat <<'EOF'
feat(dev-workflows): qualify printed command names in surfaces i and ii

36 of 40 structurally-delimited printed sites now name commands as
/dev-workflows:<command>: 15 in `### Next step` sections, 21 in
`choices:` arrays.

Three sites stay bare deliberately. implement.md:387 and :445 read
"Phase 5 of the inherited /implement workflow", naming the workflow the
run is already inside rather than something to type. create-ard.md:60
carries a split verdict: its choices: entry is qualified, but the
"(like /design)" in the surrounding prose compares the two commands'
gates and is not an invocation target.

The surface i extraction is indent-tolerant; several `### Next step`
blocks are nested inside fenced report templates, and anchoring at line
start misses ready.md and release-notes.md entirely.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Surfaces iii, iv and vi — the judgment sweep

**Files:**
- Modify: `plugins/dev-workflows/commands/*.md` — candidates in 15 files
- Create: `docs/superpowers/plans/2026-08-11-surface-iii-iv-verdicts.md` (the verdict record)

**Interfaces:**
- Consumes: Task 1's qualified form; Task 2's completed surfaces (skip any candidate already handled there).
- Produces: the verdict record, which the final review reads to audit judgment instead of re-deriving the candidate set.

Surfaces iii (quoted literals the command emits), iv ("surface / report / recommend … `/cmd`" instructions) and vi (printed guidance outside a `### Next step` heading and outside a `choices:` array — see D-3) are **not** structurally delimited. They are found by marker and confirmed by reading.

- [ ] **Step 1: Generate the candidate set**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
{ grep -nHEi "(surface|report|offer|recommend|print|announce|emit|say|tell|direct users|end (the|with))[^.]{0,120}/($CMDS)\b" *.md;
  grep -nHE '(\*"|"[^"]*)/('"$CMDS"')\b[^"]*"' *.md; } | sort -t: -k1,1 -k2,2n -u
```

Expected: **60 lines across 15 files** — `document.md` 9, `implement.md` 8, `create-vi.md` 7, `create-ard.md` 6, `update-vi.md` 4, `ready.md` 4, `specify.md` 3, `idea.md` 3, `docs-profile.md` 3, `design.md` 3, `vuln.md` 2, `upgrade.md` 2, `statusline.md` 2, `release-notes.md` 2, `epics.md` 2.

- [ ] **Step 1b: Generate the surface vi candidate set (D-3)**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows/commands
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
# vi-a — role-handoff / context-hygiene guidance (14 lines, 22 occurrences)
grep -nHE '/(compact|clear)\b' *.md | grep -E "(^|[^:a-z-])/($CMDS)\b" | cut -d: -f1,2
# vi-b — annotated offer bullets (5 lines, 5 occurrences)
grep -nHE "^[[:space:]]*[-*][[:space:]]+\*{0,2}\`?/($CMDS)\b" *.md | cut -d: -f1,2
```

Expected vi-a: `idea.md:155`, `create-ard.md:149`, `implement.md:634`, `create-vi.md:226`, `create-vi.md:227`, `epics.md:627`, `epics.md:628`, `document.md:1213`, `design.md:440`, `release-notes.md:295`, `specify.md:451`, `specify.md:543`, `specify.md:544`, `ready.md:356`.

Expected vi-b: `create-ard.md:14`, `create-ard.md:15`, `create-vi.md:213`, `create-vi.md:214`, `create-vi.md:215`.

**`/compact` and `/clear` on these lines are Claude Code built-ins — leave them bare.** Only the `dev-workflows` command name on the line is in question.

- [ ] **Step 2: Classify every candidate by reading it**

Apply G-3: qualify **iff** printed AND an invocation target. Read the surrounding lines — the marker grep is deliberately over-inclusive.

Worked **ACCEPT** examples:

- `implement.md:111` — "Surface a **one-line, non-blocking** recommendation to run `/ready <VI> [<Epic>]` first when…" → printed, and names a command to type. Qualify.
- `implement.md:56` — "**VI with 0 Epics** → offer: split with `/epics` first (then re-import)" → a printed offer naming the next command. Qualify.
- `idea.md:143` — the quoted literal *"Idea refined. Next: create the VI — first create an empty Jira workitem, then run `/create-vi <JIRA-KEY> @<idea.md path>`."* → printed verbatim. Qualify.

Worked examples specific to **surface vi**:

- **ACCEPT** — `create-vi.md:226`: ``- **Continuing as PM (`/release-notes <VI>` after the round-trip)?** → run **`/compact`**.`` The user really does run `/release-notes <VI>` next. Qualify it; leave `/compact` bare.
- **ACCEPT** — `create-vi.md:213`: ``- **`/release-notes <KEY>`** (PM) — draft the customer-facing release note now…`` — a printed bullet expanding the `choices:` block directly above it.
- **REJECT** — `create-ard.md:14`: ``- `/create-ard <VI-KEY>` → a **VI-level** ARD.`` — documents the command's own calling forms to a reader of the source, at the top of the file, nowhere near a printed offer.
- **JUDGEMENT, record your reasoning** — `specify.md:451`: an invariant line describing what the hygiene block must print (``span suggestion (VI-level→`/epics` `/compact`; …)``). It is a template for printed text rather than printed text itself, which is the same shape as rule 5's examples in `next-phase-offer.md`. Decide and say why.

Worked **REJECT** examples for surfaces iii/iv:

- `idea.md:189` — "with the Lessons Learned report, `command: /idea`, `jira_key: null`" → a **data-field value** passed to `emit-auto`, not printed as an invocation. Leave bare.
- `idea.md:195` — "`emit-cost` entry point with `command: /idea`, `phase: vi-creation`" → same. Leave bare.
- `implement.md:680` — "Call `emit-cost` with `command: /implement`" → same. Leave bare.
- `idea.md:151` — "next-phase-offer contract; `/idea` is one reference implementation." → prose describing the contract to a source reader. Leave bare.

Candidates already fixed in Task 2 (`implement.md:70`) or deliberately exempt (`implement.md:387`, `:445`) are recorded as "handled in Task 2" and skipped.

- [ ] **Step 3: Write the verdict record**

Create `docs/superpowers/plans/2026-08-11-surface-iii-iv-verdicts.md` with one row per candidate:

```markdown
# Surfaces iii/iv — classification verdicts

| Site | Text (truncated) | Verdict | Reason |
|---|---|---|---|
| `implement.md:111` | Surface a one-line…run `/ready <VI>` | QUALIFY | iv; printed; invocation target |
| `idea.md:189` | with the Lessons Learned report, `command: /idea` | LEAVE | iii/iv; data-field value, not printed as invocation |
| `create-vi.md:226` | Continuing as PM (`/release-notes <VI>`…)? → run `/compact` | QUALIFY | vi-a; user runs it next |
| `create-ard.md:14` | `/create-ard <VI-KEY>` → a VI-level ARD | LEAVE | vi-b; documents calling forms to a source reader |
```

Add a `surface` column as shown. Every candidate from Step 1 **and** Step 1b gets a row — 60 + 19 = **79 rows**. A candidate with no row is an incomplete task.

- [ ] **Step 4: Apply the QUALIFY verdicts**

Edit only the sites marked QUALIFY, rewriting `/<command>` to `/dev-workflows:<command>`.

- [ ] **Step 5: Verify the sweep is complete and bounded**

```bash
cd /workspace/ihudak-claude-plugins
# every candidate has a verdict row
echo "verdict rows: $(grep -cE '^\| `[a-z-]+\.md:[0-9]+`' docs/superpowers/plans/2026-08-11-surface-iii-iv-verdicts.md)"   # expect 79
# no QUALIFY site still bare
cd plugins/dev-workflows/commands
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
grep -oE "/dev-workflows:($CMDS)\b" *.md | wc -l   # expect >= 38 from Task 2, plus this task's accepts
```

Then re-read each QUALIFY row and confirm the file now shows the qualified form at that line.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/ docs/superpowers/plans/2026-08-11-surface-iii-iv-verdicts.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): qualify printed command names in surfaces iii and iv

Quoted literals the command emits, and "surface/report/recommend …
/cmd" instructions. Neither is structurally delimited, so the 60
candidates come from a stated marker grep and each carries a recorded
verdict.

The distinction that matters: printed is not sufficient — the name must
be an invocation target. `command: /idea` passed to emit-cost is
printed nowhere the user types, and stays bare.

These sites are why the rule could not live in next-phase-offer.md
alone: implement.md:111 prints a /ready recommendation ~500 lines from
any citation of that file.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `statusline.md` and the README diagram

**Files:**
- Modify: `plugins/dev-workflows/commands/statusline.md:17-20`
- Modify: `plugins/dev-workflows/README.md` (mermaid PM subgraph)

**Interfaces:**
- Consumes: rule 6 from Task 1.

- [ ] **Step 1: Rewrite `statusline.md`'s bespoke paragraph**

Current text at `commands/statusline.md:17-20`:

```
Note: Claude Code ships its own built-in `/statusline` command (backed by the
`statusline-setup` agent). Because this command shares that name, the bare
`/statusline` resolves to Claude Code's built-in flow — direct users to the
fully-qualified `/dev-workflows:statusline` to reach this command.
```

Replace with:

```
Note: Claude Code ships its own built-in `/statusline` command (backed by the
`statusline-setup` agent), so the bare `/statusline` resolves to Claude Code's
built-in flow. This is one instance of the general rule — see rule 6 of
`${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`: printed command names
are always fully qualified. Direct users to `/dev-workflows:statusline`.
```

- [ ] **Step 2: Add the `/update-vi` node to the README mermaid diagram**

In `plugins/dev-workflows/README.md`, the `PM` subgraph currently reads:

```
    subgraph PM["PM — ideation & framing"]
        idea["/idea"] --> createvi["/create-vi"]
        createvi --> rnpm["/release-notes (early draft)"]
    end
```

Replace with:

```
    subgraph PM["PM — ideation & framing"]
        idea["/idea"] --> createvi["/create-vi"]
        createvi --> rnpm["/release-notes (early draft)"]
        createvi -.->|VI exists| updatevi["/update-vi"]
        updatevi --> rnpm
    end
```

Node labels keep the short form — the diagram is documentation prose, not printed output (G-5). The existing `/dev-workflows:statusline` node elsewhere in the diagram is **not** touched (G-4).

**The `updatevi` grep returns 2, not 1** — the insert adds two lines that both carry the identifier (the node declaration and its edge to `rnpm`). Both are required.

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "statusline cites rule 6 (expect 1): $(grep -c 'next-phase-offer.md' commands/statusline.md)"
echo "mermaid update-vi node (expect 2):  $(awk '/```mermaid/,/^```$/' README.md | grep -c 'updatevi')"
echo "diagram statusline untouched (expect 1): $(awk '/```mermaid/,/^```$/' README.md | grep -c '/dev-workflows:statusline')"
```

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/statusline.md plugins/dev-workflows/README.md
git commit -m "$(cat <<'EOF'
docs(dev-workflows): statusline cites rule 6; /update-vi joins the diagram

statusline.md's collision note predates rule 6 and read as a one-off
exception. It now cites the general rule and keeps the specifics.

The README mermaid PM subgraph gained /update-vi, which the role table
directly beneath it has always listed.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Canonical release files

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`
- Modify: `.claude-plugin/marketplace.json`

**Interfaces:**
- Consumes: all canonical content from Tasks 1–4.

- [ ] **Step 1: Bump the plugin version**

In `plugins/dev-workflows/.claude-plugin/plugin.json`, `"version": "2.45.0"` → `"version": "2.46.0"`.

- [ ] **Step 2: Bump the marketplace catalog**

In `.claude-plugin/marketplace.json`, find the `dev-workflows` entry and set its version to `2.46.0`. **This file was missed in 2.42.0** — do not skip it. Do not reformat the file; Claude Code parses it.

- [ ] **Step 3: Add the CHANGELOG entry**

Insert directly above the `## [2.45.0]` heading:

```markdown
## [2.46.0] — 2026-08-11

### Fixed

- **Printed next-step suggestions named commands that resolve to something else.** A bare `/release-notes` typed at the prompt reaches Claude Code's built-in release-notes view, not this plugin — and the same is true of `/upgrade` and `/statusline`. The plugin already knew this for exactly one command: `statusline.md` has always told users to type the fully-qualified `/dev-workflows:statusline`. That reasoning is now the general rule (`references/next-phase-offer.md` rule 6), and every command name the plugin prints for the user to invoke carries the `/dev-workflows:` prefix. Finding them all took seven distinct detectors: `### Next step` sections and `choices:` arrays are structurally delimited, but the rest are not — quoted handoffs, inline "surface a recommendation to run X" instructions, the role-handoff line that names your next command beside `/compact`, annotated bullets expanding an offer, multi-line printed literals whose trigger phrase and command sit on different lines, and STOP messages carrying a `re-run this` instruction. Names that are printed but are not invocation targets stay bare: `command: /implement` handed to `emit-cost` is a data field, "Phase 5 of the inherited `/implement` workflow" names the workflow the run is inside, and `CREATE_VI_NEEDS_KEY: /create-vi needs a Jira key` names which command is complaining.
- **`/update-vi` cited a routing graph it did not appear in.** `update-vi.md` names `references/next-phase-offer.md` as the authority for its Phase 6 offer, and that file had never mentioned `/update-vi` — in any edition. It now appears as a PM re-entry node, reached when `/create-vi` redirects an existing-VI call or when a later phase forces a refresh. The README's workflow diagram gained the node its own role table has always listed.
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
echo "plugin.json:     $(grep '"version"' plugins/dev-workflows/.claude-plugin/plugin.json)"
echo "marketplace:     $(grep -A3 '"name": "dev-workflows"' .claude-plugin/marketplace.json | grep version)"
echo "changelog head:  $(grep -m3 '^## \[' plugins/dev-workflows/CHANGELOG.md | tr '\n' ' ')"
python3 -c "import json;json.load(open('.claude-plugin/marketplace.json'));print('marketplace.json parses')"
```

The changelog head must read `[2.46.0] [2.45.0] [2.44.1]` — monotonic descending.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/.claude-plugin/plugin.json plugins/dev-workflows/CHANGELOG.md .claude-plugin/marketplace.json
git commit -m "$(cat <<'EOF'
release(dev-workflows): 2.46.0 — printed-output correctness

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Port to mgd

**Files:**
- Modify: `/workspace/mgd-claude-plugins/plugins/dev-workflows/**` (copied from canonical)
- Modify: `/workspace/mgd-claude-plugins/CLAUDE.md` (identity file — hand-edited)
- Modify: `/workspace/mgd-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json` (identity)
- Modify: `/workspace/mgd-claude-plugins/.claude-plugin/marketplace.json` (identity)

**Interfaces:**
- Consumes: canonical Tasks 1–5, complete and committed.

mgd is content-verbatim except its six identity files (G-2). Content changes are **copied**, never re-typed.

- [ ] **Step 1: Copy the changed content files**

```bash
cd /workspace/ihudak-claude-plugins
FORK=$(git merge-base HEAD main)
echo "fork point: $FORK"
for f in $(git diff --name-only "$FORK"..HEAD -- plugins/dev-workflows/ | grep -vE 'plugins/dev-workflows/(\.claude-plugin/plugin\.json|LICENSE|README\.md|references/dependencies\.md)$'); do
  echo "copy: $f"; cp "$f" "/workspace/mgd-claude-plugins/$f"
done
```

The `grep -v` excludes four of the six identity files; the other two live outside `plugins/dev-workflows/` and are never matched by this path filter.

**`README.md` is an identity file and is NOT copied.** Apply Task 4's mermaid change to mgd's README by hand, keeping mgd's own surrounding identity content.

- [ ] **Step 2: Add the missing `doc-structure-conventions.md` paragraph to mgd's root `CLAUDE.md`**

This paragraph was added to canonical in `3f9acfb` (the 2.44.0 / B2 release) and never ported. Copy it byte-identical from canonical's root `CLAUDE.md`, placing it in the same position relative to its neighbouring source-truth paragraphs:

```bash
cd /workspace/ihudak-claude-plugins
grep -n 'doc-structure-conventions' CLAUDE.md   # locate it and its neighbours
```

Insert into mgd's root `CLAUDE.md` after the `repo-verification-gates.md` paragraph and before the `## \`dev-workflows\` workflow relationships` section, matching canonical's ordering. Do **not** copy canonical's whole `CLAUDE.md` — it is an identity file and differs by design.

- [ ] **Step 3: Bump mgd's identity version files by hand**

`plugins/dev-workflows/.claude-plugin/plugin.json` → `2.46.0`; `.claude-plugin/marketplace.json` `dev-workflows` entry → `2.46.0`. `CHANGELOG.md` is a content file and arrived via Step 1.

- [ ] **Step 4: Verify parity is exactly six files**

```bash
cd /workspace/ihudak-claude-plugins
echo "=== files differing under plugins/dev-workflows (expect 4) ==="
diff -rq plugins/dev-workflows /workspace/mgd-claude-plugins/plugins/dev-workflows 2>&1 | sed 's|.*/plugins/dev-workflows/||'
echo "=== root identity files (expect 2, both differing by design) ==="
diff -q CLAUDE.md /workspace/mgd-claude-plugins/CLAUDE.md
diff -q .claude-plugin/marketplace.json /workspace/mgd-claude-plugins/.claude-plugin/marketplace.json
echo "=== the ported paragraph (expect 1) ==="
grep -c 'doc-structure-conventions' /workspace/mgd-claude-plugins/CLAUDE.md
```

Six differing files total, no more. A seventh is the signal that something was copied that should not have been, or missed that should have been.

- [ ] **Step 5: Commit**

```bash
cd /workspace/mgd-claude-plugins
git add -A
git commit -m "$(cat <<'EOF'
release(dev-workflows): 2.46.0 — printed-output correctness

Ports canonical's printed-name qualification, next-phase-offer rule 6,
and the /update-vi routing node.

Also fixes a 2.44.0 port miss this repo has carried since: the root
CLAUDE.md never received the doc-structure-conventions.md source-truth
paragraph. It survived two releases because the parity check covers
plugins/dev-workflows and not the repository root.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: The copilot edition

**Files:**
- Modify: `dev-workflows/skills/_shared/next-phase-offer.md`
- Modify: `dev-workflows/skills/*/SKILL.md` (printed surfaces)
- Modify: `dev-workflows/skills/create-vi/SKILL.md:136`
- Modify: `dev-workflows/README.md`
- Modify: `dev-workflows/.plugin/plugin.json`
- Modify: `dev-workflows/CHANGELOG.md`

**Interfaces:**
- Consumes: the canonical design; adapts it to the `<name>:` dialect (G-8).

Copilot's routing graph **already** uses the `<name>:` idiom — a baseline check returns 0 slash refs in that section. So its work is rule 6, the `update-vi:` node, its own printed-surface sweep, and the phase-citation fix.

- [ ] **Step 1: Add rule 6 in the copilot dialect**

In `dev-workflows/skills/_shared/next-phase-offer.md`, change the contract heading to 6 rules and append verbatim:

```markdown
6. **Printed in this edition's invocation idiom** — every skill name the run PRINTS for the user to
   invoke is written `<name>:` (e.g. `release-notes: <VI>`). Slash-style `/<name>` does invoke the
   skill, but it can resolve to a Copilot built-in of the same name instead — Copilot's own
   `/release-notes`, `/upgrade`, `/feedback`, and `/statusline` all collide today — so the slash
   form is NEVER printed. Prose that describes the pipeline to a reader of this edition's source
   keeps the short form.
```

Those four names stay **bare and slash-style**: they name Copilot's built-ins, not skills shipped here. Qualifying or `<name>:`-converting them would state a falsehood. This is the copilot twin of Task 1 Step 4's second carve-out, and it means copilot's `next-phase-offer.md` legitimately goes from 0 slash refs to 4.

- [ ] **Step 2: Add the `update-vi:` re-entry node**

In the same file's `**PM — ideation & framing**` section, after the `create-vi:` entry:

```markdown
- `update-vi: <KEY>` — re-entry, not a linear node: reached when `create-vi:` redirects an
  existing-VI call, or when a later phase forces a VI refresh. After the paste-into-Jira +
  re-import round-trip it offers the same forward paths as `create-vi:`: `release-notes: <VI>`
  (PM), `create-ard: <VI>` (PA, if one exists), `specify: <VI>` (PE, if one exists).
```

- [ ] **Step 3: Sweep copilot's printed surfaces**

**Baseline, measured before this plan was written: copilot's surfaces i, ii and v are ALREADY clean.** All 7 `### Next step` sections (`implement`, `document`, `design`, `epics`, `release-notes`, `specify`, `ready`) exist and already use the `<name>:` idiom; `choices:` lines carry no slash-style refs; the routing graph carries none either. A zero here means *already correct*, not *missing* — do not go looking for work that is not there, and do not "fix" a `<name>:` that is already right.

Copilot's real work in this step is **surfaces iii and iv only**. Run the candidate greps below against `dev-workflows/skills/*/SKILL.md`, converting each printed **invocation target** from `/<name>` to `<name>:`. Apply G-3 unchanged — data-field values and descriptive workflow references stay as they are.

```bash
cd /workspace/ihudak-copilot-plugins/dev-workflows/skills
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
# surface i
for f in */SKILL.md; do awk -v F="$f" '/^[[:space:]]*### Next step/{inb=1} /^[[:space:]]*#{1,3} [A-Z]/{if(inb && !/### Next step/)inb=0} inb{print F":"NR}' "$f"; done
# surface ii
grep -nH 'choices:' */SKILL.md | grep -E "(^|[^:a-z-])/($CMDS)\b" | cut -d: -f1,2
# surfaces iii/iv candidates
{ grep -nHEi "(surface|report|offer|recommend|print|announce|emit|say|tell|direct users|end (the|with))[^.]{0,120}/($CMDS)\b" */SKILL.md;
  grep -nHE '(\*"|"[^"]*)/('"$CMDS"')\b[^"]*"' */SKILL.md; } | sort -u
```

Record verdicts in `docs/superpowers/plans/2026-08-11-surface-iii-iv-verdicts.md` under a `## Copilot edition` heading, same table shape as Task 3.

Out of scope, do not touch: slash-style refs in prose, and the ~66 occurrences outside printed surfaces (G-5). These work; they are merely inconsistent.

- [ ] **Step 4: Fix the phase citation**

`dev-workflows/skills/create-vi/SKILL.md:136` reads `(mirrors \`epics:\` Phase 6.1).` — Phase 6.1 is *Resolve clarifications*; the Dynatrace style check is Phase **6.2** in both editions. Change `6.1` → `6.2`. Canonical `commands/create-vi.md:138` already reads 6.2 and is the reference.

- [ ] **Step 5: Add the `update-vi` node to copilot's README diagram**

In `dev-workflows/README.md`, the `PM` subgraph currently reads:

```
    subgraph PM["PM — ideation & framing"]
        idea["idea:"] --> createvi["create-vi:"]
        createvi --> rnpm["release-notes: (early draft)"]
    end
```

Replace with:

```
    subgraph PM["PM — ideation & framing"]
        idea["idea:"] --> createvi["create-vi:"]
        createvi --> rnpm["release-notes: (early draft)"]
        createvi -.->|VI exists| updatevi["update-vi:"]
        updatevi --> rnpm
    end
```

Node labels use this edition's `<name>:` idiom, matching every sibling node.

- [ ] **Step 6: Bump version and add the CHANGELOG entry**

`dev-workflows/.plugin/plugin.json` `"version": "2.15.0"` → `"2.16.0"`, **and** `.github/plugin/marketplace.json`'s `dev-workflows` entry → `"2.16.0"` (do not reformat the catalog). Insert above `## [2.15.0]`:

```markdown
## [2.16.0] — 2026-08-11

### Fixed

- **The printed-name contract is now stated, before it is needed.** Slash-style invocation works in this edition, so a printed `/release-notes` is not broken — but Copilot registers its own built-in slash commands, and four of them collide with skill names shipped here: `/release-notes`, `/upgrade`, `/feedback`, and `/statusline`. In a collision the built-in wins, and `/feedback` is a collision the Claude edition does not have. A sweep of every printed surface found this edition **already** using the `<name>:` idiom throughout, so no printed text needed converting. `skills/_shared/next-phase-offer.md` rule 6 now states the contract explicitly so it stays that way.

**Write this bullet only after the sweep has run, and make it match the sweep's actual result.** The wording above assumes zero conversions, which is what was observed. If a future run of this plan finds real conversions, say so instead — a changelog that claims a fix which never happened is a defect in its own right, and the first draft of this entry had exactly that flaw.
- **`update-vi:` cited a routing graph it did not appear in.** `skills/update-vi/SKILL.md` names `skills/_shared/next-phase-offer.md` as the authority for its Phase 6 offer, and that file had never mentioned it. It now appears as a PM re-entry node.
- **`create-vi:` cited the wrong `epics:` phase.** Its Phase 3.5 style check said it mirrored `epics:` Phase 6.1 (*Resolve clarifications*); the style check is Phase 6.2.
```

- [ ] **Step 7: Verify**

```bash
cd /workspace/ihudak-copilot-plugins/dev-workflows
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
echo "rule 6 (expect 1):        $(grep -c 'Printed in this edition' skills/_shared/next-phase-offer.md)"
echo "update-vi node (expect >=1): $(grep -c 'update-vi:' skills/_shared/next-phase-offer.md)"
echo "phase fix (expect 1):     $(grep -c 'epics:\` Phase 6.2' skills/create-vi/SKILL.md)"
echo "phase 6.1 gone (expect 0):$(grep -c 'epics:\` Phase 6.1' skills/create-vi/SKILL.md)"
echo "mermaid update-vi (expect >=1): $(awk '/```mermaid/,/^```$/' README.md | grep -ci 'update-vi')"
echo "version: $(grep '"version"' .plugin/plugin.json)"
```

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-copilot-plugins
git add -A
git commit -m "$(cat <<'EOF'
release(dev-workflows): 2.16.0 — printed-output correctness

Copilot registers /release-notes, /upgrade, /feedback and /statusline as
built-in slash commands, so a printed slash-style suggestion reaches the
built-in rather than the skill. Slash invocation itself works here — the
defect is collision, not failure. Printed names now use this edition's
<name>: idiom, contracted by next-phase-offer.md rule 6.

Also adds the update-vi: routing node its own SKILL.md cites, and fixes
create-vi:'s citation of epics: Phase 6.1 — the style check is 6.2.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Cross-repo verification

**Files:**
- Create: `docs/superpowers/plans/2026-08-11-verification-results.md`

**Interfaces:**
- Consumes: all seven prior tasks, committed in all three repos.

This task produces the evidence table. It writes no plugin content — any defect it finds is reported, not silently fixed.

- [ ] **Step 1: Run V1–V16 across all three editions**

```bash
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'

# glob scopes the sweep to command/skill files only — copilot's skills/_shared/*.md are
# references, which are out of scope (G-5) and would otherwise inflate V2/V3
for R in "/workspace/ihudak-claude-plugins/plugins/dev-workflows:commands/*.md:references" \
         "/workspace/mgd-claude-plugins/plugins/dev-workflows:commands/*.md:references" \
         "/workspace/ihudak-copilot-plugins/dev-workflows:skills/*/SKILL.md:skills/_shared"; do
  root=$(echo "$R" | cut -d: -f1); glob=$(echo "$R" | cut -d: -f2); rdir=$(echo "$R" | cut -d: -f3)
  echo "=== $root ==="
  echo "V1  rule 6:            $(grep -c 'when printed\|this edition' "$root/$rdir/next-phase-offer.md")"
  echo "V2  surface i bare:    $(cd "$root" && for f in $glob; do awk '/^[[:space:]]*### Next step/{inb=1} /^[[:space:]]*#{1,3} [A-Z]/{if(inb && !/### Next step/)inb=0} inb' "$f"; done | grep -cE "(^|[^:a-z-])/($CMDS)\b")"
  echo "V3  surface ii bare:   $(cd "$root" && grep -h 'choices:' $glob | grep -oE "(^|[^:a-z-])/($CMDS)\b" | wc -l)"
  echo "V4  next-phase bare:   $(grep -oE "(^|[^:a-z-])/($CMDS)\b" "$root/$rdir/next-phase-offer.md" | wc -l)"
  echo "V6  update-vi in graph:$(grep -c 'update-vi' "$root/$rdir/next-phase-offer.md")"
  echo "V7  update-vi mermaid: $(awk '/```mermaid/,/^```$/' "$root/README.md" | grep -ci 'update.\?vi')"
done
```

Expected: V1 = 1; V2 = 0; V3 = 4 for canonical and mgd (the four documented D-2 exceptions — `create-ard.md:60`, `create-ard.md:138`, `implement.md:387`, `implement.md:445`) and 0 for copilot unless its own sweep records exceptions; **V4 = 3 for canonical and mgd, 4 for copilot**; V6 ≥ 1; V7 ≥ 1.

**V4 is not zero, and that is correct.** Rule 6 cites the built-in command names it warns about, and those must stay bare or the rule states a falsehood (Task 1 Step 4 carve-out; Task 7 Step 1 for copilot). Confirm the residue is exactly those names and nothing else:

```bash
grep -oE "(^|[^:a-z-])/($CMDS)\b" "$root/$rdir/next-phase-offer.md" | tr -d ' ' | sort | tr '\n' ' '
# canonical/mgd expect: /release-notes /statusline /upgrade
# copilot expect:       /feedback /release-notes /statusline /upgrade
```

Any name outside those sets is a real defect.

- [ ] **Step 2: Run the risk re-checks V14, V15, V16**

```bash
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline'
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "V14 printed sites outside commands/ (expect 0 real):"
grep -rnEi "(surface|report|recommend|offer|next step|suggest)[^.]{0,100}/($CMDS)\b" agents/ references/ | grep -v 'next-phase-offer.md'
echo "V15 slashless names in surfaces i/ii (expect 0):"
cd commands && for f in *.md; do { awk '/^[[:space:]]*### Next step/{inb=1} /^[[:space:]]*#{1,3} [A-Z]/{if(inb && !/### Next step/)inb=0} inb' "$f"; grep -h 'choices:' "$f"; } | grep -oE "\`($CMDS)\`"; done | wc -l
echo "V16 no site defers to rule 6 at runtime (expect 0):"
grep -rniE 'qualify .{0,40}(at runtime|per rule 6)|apply rule 6 when' . | wc -l
```

V14 hits must all be path false positives (e.g. `.../handoff/vuln-research.md`); any real printed site is a defect to report.

- [ ] **Step 3: Verify mgd parity and changelog monotonicity**

```bash
cd /workspace/ihudak-claude-plugins
echo "=== mgd parity: expect 4 under plugins/, 2 at root, 6 total ==="
diff -rq plugins/dev-workflows /workspace/mgd-claude-plugins/plugins/dev-workflows 2>&1 | wc -l
diff -q CLAUDE.md /workspace/mgd-claude-plugins/CLAUDE.md >/dev/null; echo "root CLAUDE.md differs: $?"
diff -q .claude-plugin/marketplace.json /workspace/mgd-claude-plugins/.claude-plugin/marketplace.json >/dev/null; echo "root marketplace differs: $?"
echo "=== changelog heads ==="
for c in plugins/dev-workflows/CHANGELOG.md /workspace/mgd-claude-plugins/plugins/dev-workflows/CHANGELOG.md /workspace/ihudak-copilot-plugins/dev-workflows/CHANGELOG.md; do
  echo "$c: $(grep -m3 '^## \[' "$c" | tr '\n' ' ')"
done
echo "=== marketplace catalogs parse and carry the new version ==="
python3 -c "import json;d=json.load(open('.claude-plugin/marketplace.json'));print('canonical ok')"
python3 -c "import json;d=json.load(open('/workspace/mgd-claude-plugins/.claude-plugin/marketplace.json'));print('mgd ok')"
```

- [ ] **Step 4: Write the results file**

Create `docs/superpowers/plans/2026-08-11-verification-results.md` with one row per check: ID, expected, observed, PASS/FAIL, and for every FAIL the exact command and output. Do not fix defects here — report them.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add docs/superpowers/plans/2026-08-11-verification-results.md
git commit -m "$(cat <<'EOF'
docs(superpowers): D verification results — V1-V16 across three editions

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

## Verification summary

| ID | Check | Expected | Task |
|----|-------|----------|------|
| V1 | rule 6 present, correct dialect | 1 per edition | 1, 7, 8 |
| V2 | surface i bare names (indent-tolerant) | 0 per edition | 2, 8 |
| V3 | surface ii bare names | 4 canonical/mgd (D-2), 0 copilot | 2, 8 |
| V4 | `next-phase-offer.md` bare names | 3 canonical/mgd, 4 copilot — exactly rule 6's built-in citations | 1, 7, 8 |
| V5 | surfaces iii/iv/vi — every candidate has a verdict | 79 rows canonical | 3 |
| V17 | surface vi (D-3) — no QUALIFY site left bare | 0 | 3, 8 |
| V18 | surface vii (D-4) — vii-a and vii-b detectors return no unclassified printed invocation site | 0 | 3, 8 |
| V6 | `/update-vi` in each routing graph | ≥1 per edition | 1, 7, 8 |
| V7 | `/update-vi` node in each README mermaid | ≥1 per edition | 4, 6, 7 |
| V8 | `statusline.md` cites rule 6 | 1 | 4 |
| V9 | mgd root `CLAUDE.md` paragraph | 1, byte-identical | 6 |
| V10 | copilot cites `epics:` Phase 6.2 | 1; zero 6.1 | 7 |
| V11 | copilot printed surfaces carry no slash refs | 0 | 7 |
| V12 | mgd parity | exactly 6 identity files | 6, 8 |
| V13 | CHANGELOGs monotonic; **all three** catalogs bumped and parsing | pass | 5, 6, 7, 8 |
| V14 | R2 re-check — printed sites outside `commands/` | 0 real | 8 |
| V15 | R3 re-check — slashless names in surfaces i/ii | 0 | 8 |
| V16 | R1 — no site defers to rule 6 at runtime | 0 | 8 |
