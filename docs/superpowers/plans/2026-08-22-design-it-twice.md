# Design it twice — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended)
> or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`)
> syntax for tracking.

**Goal:** Give `/design` a way to *diverge* before it converges — three deliberately different takes on
a contested interface, compared on named axes — and make "what did you reject, and why" a standing
requirement of every design rather than a by-product of that fan-out.

**Architecture:** One new bounded agent (`interface-designer`), one offered fan-out inside `/design`'s
existing Phase 5 grill, one new flag, two additions to `design-format.md`, and two extensions to
existing `design-reviewer` dimensions. Everything new is conditional or additive: declining the offer
reproduces today's behaviour exactly.

**Tech Stack:** Markdown agent/command/reference files; Claude Code plugin manifests
(`.claude-plugin/*.json`); GitHub Copilot plugin manifests (`.plugin/*.json`, `skills/*/SKILL.md`).
No compiled code, no test framework — verification is read-back, derived greps, reachability tracing,
and the repo's own gates.

**Spec:** `docs/superpowers/specs/2026-08-22-design-it-twice-design.md` — read it before Task 1. The
plan argues from the spec; where they disagree the spec governs, and the mismatch is a finding to
report rather than silently resolve.

## Global Constraints

- **Branch** `iv-gu/design-it-twice` in all three repos, off `main`. Canonical already exists at
  `74a175f` with the spec committed — do **not** re-create it.
- **Commit trailer**, every commit: `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- **Versions:** canonical + mgd `2.55.0 → 2.56.0`; Copilot `2.25.0 → 2.26.0`. Minor — new agent, new
  capability, backward-compatible.
- **Pushes:** merge to `main` and push in all three when the round is done — after the final
  whole-branch review, not incrementally. **mgd goes through a PR** (`gh pr create`), never a direct
  push: that org requires PRs on `main` and the account's bypass privilege would skip its review gate.
- **Never edit** `references/specification-format.md` (frozen snapshot).
- **Never `cp` into the Copilot edition.** Apply every edit surgically. Four dialect rules:
  `task(agent_type:)` not `Agent(subagent_type:)`; absolute
  `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<f>.md` not
  `${CLAUDE_PLUGIN_ROOT}`; colon-form command names (`design:`, never `/design`); lowercase
  `tools: [view, glob, grep, bash]`. Copilot prose legitimately says "Opus review" — do not normalise it.
- **Never `cp` a repo-root `CLAUDE.md`** between editions.
- **mgd port:** `cp -r` the agents/commands/references dirs, then **immediately**
  `git checkout -- plugins/dev-workflows/references/dependencies.md` — that `cp` overwrites an mgd
  identity file, and `diff -rq` cannot detect it (an overwritten identity file makes the two files
  *match*, dropping the count from five to four; fewer differences reads like better parity). Verify
  identity by **content**, never by difference count.
- **Every count is re-derived, never copied.** Where a step gives an expected number it gives the
  command that produces it. If the command disagrees with this plan, **the plan is wrong** — report the
  mismatch rather than editing to match it.
- **Never let a phrase a grep depends on be split across a line break.** This defect has occurred five
  times across recent rounds, including in a plan's own insert blocks and in a controller's own
  tooling. When a count comes in one short, check for a split phrase **before** concluding an edit is
  missing.
- **A failing check is the suspect, not the tree.** Eleven broken verification patterns were found in
  the last two rounds — wrong inflection, wrong case, wrong file, wrong code-span shape, a working-tree
  comparison that passed vacuously, a pattern matching the tail of a longer number. Two would have
  required damaging correct content to satisfy.
- **Bugs-first:** no defect found during execution is carried past this round, including Minors,
  pre-existing ones, and ones found in this plan. A defect may be closed as *deliberately not fixed*
  only with a written reason.
- **Prose wrapping:** `references/*.md` and agent bodies wrap at ~100 columns. `CLAUDE.md`'s
  source-truth index entries are ONE unbroken paragraph each. Match whatever you are editing.

## File Structure

**New (canonical paths; per-edition equivalents in Tasks 6–7):**
- `plugins/dev-workflows/agents/interface-designer.md` — one take on one interface under one constraint

**Modified:**
- `references/design-format.md` — alternatives requirement (§5), dependency categories + contested
  signals (§6, §4.1)
- `agents/design-reviewer.md` — two extended cross-cutting checks
- `commands/design.md` — `--design-twice` (six places), the Phase 5 offer + dispatch + comparison, the
  Phase 5 report line
- `CLAUDE.md`, `plugins/dev-workflows/README.md` — agent ledger, agent table, counts, `/design`
  workflow line, flag signature

---

## Task 1: The `interface-designer` agent

**Files:**
- Create: `plugins/dev-workflows/agents/interface-designer.md`

**Interfaces:**
- Produces: agent name **`interface-designer`**, dispatched by Task 4 as
  `Agent (subagent_type: "dev-workflows:interface-designer")`.
- Produces: a `## Interface proposal` wrapper around the five output headings Task 4's comparison reads
  field-by-field — `### Interface`, `### Usage example`, `### What it hides`, `### Dependency strategy`,
  `### Trade-offs`.
- Produces: input field names `constraint`, `problem_frame`, `code_context`, `dependency_category`.

- [ ] **Step 1: Confirm the branch and a clean tree.**

```bash
cd /workspace/ihudak-claude-plugins
git switch iv-gu/design-it-twice
git status --porcelain          # expect no output
git log --oneline -1            # expect 74a175f (the spec's cross-ref fix)
```

Do NOT run `git switch main`, `git pull`, or `git switch -c` — the branch exists.

- [ ] **Step 2: Record the baseline agent count.**

```bash
ls plugins/dev-workflows/agents/*.md | wc -l      # baseline (expect 33)
```

If it is not 33, STOP and report — every count in Task 8 derives from this.

- [ ] **Step 3: Create the agent file** at `plugins/dev-workflows/agents/interface-designer.md` with
exactly this content:

```markdown
---
name: interface-designer
description: Produces ONE interface proposal for ONE contested interface under ONE named design constraint, for `/design`'s Phase 5 fan-out. Dispatched three times in parallel with different constraints so the takes diverge; the caller compares them on depth, locality, and seam placement. Read-only — proposes an interface, never writes one. Model tier assigned by the caller per the model-routing policy (no fixed pin).
tools: ["Read", "Glob", "Grep", "Bash"]
---

Produce **one** interface proposal for **one** interface, under **one** named constraint. You are one of
three takes dispatched in parallel; the others are working the same problem under different constraints
and you cannot see them. That is deliberate — divergence is the product. Do not hedge toward what you
imagine the others will say, and do not propose a compromise: the caller will build the hybrid if one
is warranted.

You are **not** writing a design document. One interface.

## Inputs

- **`constraint`** (required) — the single design constraint this take must satisfy. One of:
  - *Minimise the interface* — aim for 1–3 entry points; maximise the behaviour a caller can reach per
    unit of interface they must learn.
  - *Maximise flexibility* — support extension and use cases beyond the immediate one.
  - *Optimise for the most common caller* — make the dominant case trivial, even at the cost of the
    rare one.
  Follow it wholeheartedly. A take that quietly optimises for something else wastes the seat.
- **`problem_frame`** (required) — what the interface is for, the constraints any proposal must satisfy,
  and the seam it sits at.
- **`code_context`** (required) — the caller's Phase 4 `code-scanner` findings for the relevant repo(s):
  the existing shape, its callers, and what already depends on it. May arrive inline or as an absolute
  file path — `Read` the file first when given a path. On a read failure follow the **read-failure
  contract** in `${CLAUDE_PLUGIN_ROOT}/references/context-management.md`: this is an *evidence* input —
  hard stop, return `status: BLOCKED` naming the unreadable path, and never reconstruct it by scanning
  on your own initiative.
- **`dependency_category`** (optional) — the seam's category if the caller already settled it (see
  `${CLAUDE_PLUGIN_ROOT}/references/design-format.md` `## Seams`). Absent ⇒ classify it yourself and say
  which you chose.

## Method

1. Read `code_context` before proposing anything. An interface designed without knowing its callers is
   a guess.
2. Establish how the current shape is actually used — how many callers, what they pass, what they do
   with the result. `git grep -c`, `git grep -n`, and `git log` on the relevant paths are the fastest
   way; use them.
3. Design the interface your `constraint` demands. Push the constraint until it costs something, then
   say what it cost — that trade-off is the most useful thing you return.
4. Do not evaluate your own take against the others. The caller compares.

## Output

Return exactly this shape, no preamble:

```markdown
## Interface proposal

### Interface
[Signatures, and the facts a caller must know that a signature does not carry: invariants, ordering
constraints, error modes, required configuration. Real names, real types.]

### Usage example
[How a caller actually uses it — the dominant case, in code.]

### What it hides
[The behaviour that sits behind the seam and never reaches the caller.]

### Dependency strategy
[The seam's dependency category, and the adapters it implies. If you classified it yourself, say so.]

### Trade-offs
[Where leverage is high — behaviour reached per unit of interface learned. Where it is thin. What
following the constraint cost. What this take is bad at.]
```

## Hard rules

- NEVER produce more than one interface proposal. Three takes exist because each is single-minded; a
  take that offers options is a fourth comparison the caller did not ask for.
- NEVER soften your constraint to look balanced. The caller wants the extreme so it can see the range.
- NEVER mutate anything with `Bash`. You hold it to **read and inspect** — `git grep`, `git log`, `ls`,
  reading files. Never edit, create, or delete a file; never `git add`, commit, switch, stash, or reset;
  never touch the index, `HEAD`, or branch state; never install, upgrade, or remove a dependency. You
  propose; the caller writes.
- NEVER dispatch a subagent. You have no `Task` tool and must not ask the caller to grant one.
- NEVER invent a caller, a file, or a signature you did not read. Cite `path:line` for every claim about
  existing code.
```

- [ ] **Step 4: Verify.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# CORRECTED — the original two checks here were wrong and were retired during Task 1's fix rounds.
# They demanded a 4-space-indented fence, which in CommonMark stops being a fence at all. The house
# convention (code-review, doc-reviewer, risk-planner, review-fixer) is a column-0 fence wrapping a
# `## <report title>` line and `###` fields. grep is line-based and counts the in-fence wrapper.
grep -c '^## ' agents/interface-designer.md      # expect 5 — 4 real sections + the in-fence wrapper
grep -cE '^### (Interface|Usage example|What it hides|Dependency strategy|Trade-offs)$' agents/interface-designer.md   # expect 5
grep -c '^#### ' agents/interface-designer.md    # expect 0
grep -cE '^ +```' agents/interface-designer.md   # expect 0 — no indented fence
grep -c '^```' agents/interface-designer.md      # expect 2
grep -c "read-failure contract" agents/interface-designer.md   # expect 1
ls agents/*.md | wc -l                                          # expect 34 (baseline 33 + 1)
cd /workspace/ihudak-claude-plugins && claude plugin validate .
```

Then read the file end to end and confirm the frontmatter parses and the fenced output block is intact.

- [ ] **Step 5: Commit.**

```bash
git add plugins/dev-workflows/agents/interface-designer.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): interface-designer agent — one take, one constraint

One bounded agent for /design's Phase 5 fan-out: given a framed problem, the
Phase 4 code context, and ONE named constraint, produce ONE interface proposal.

Dispatched three times in parallel under different constraints, blind to each
other — divergence is the product, so a take that hedges toward a compromise
wastes the seat. Tools match code-scanner rather than the reviewers: designing
an interface against real code means knowing how many callers exist and what
they pass, and git grep is how you find out. Bash is bounded read-only.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `design-format.md` — alternatives considered

**Files:**
- Modify: `plugins/dev-workflows/references/design-format.md` (section 3, `## Architecture & components`)

**Interfaces:**
- Produces: the requirement Task 5's reviewer check reads, and the section Task 4's comparison writes
  into. The phrase **`### Alternatives considered`** (THREE hashes) is used verbatim by Tasks 4 and 5. Task 2's Step 1 block is authoritative on the hash count; an earlier draft of this line said two, and an anchored `^##` grep against the wrong form would silently miss the real heading.

- [ ] **Step 1: Extend section 3.** Locate this text (section 3 of `## Sections (in order)`):

```
   Favor **deep modules** (small interface, substantial implementation — see `## Seams` for the
   depth / deletion-test / two-adapters vocabulary).
```

Append immediately after it, at the same indentation:

```
   **Record at least one rejected alternative, and why** — as a short `### Alternatives considered`
   block inside this section. This is **unconditional**: it applies to every design, whether or not the
   Phase 5 interface fan-out ran. `risk-planner` already demands the same of plans ("Name at least one
   alternative that was rejected and the reason"); a design is the weaker artifact if it does not. When
   the fan-out ran, the losing takes fill this with real trade-offs and are named as such (take,
   constraint, why it lost); otherwise the author names alternatives by hand. An "alternative" that was
   never plausible ("we considered not having an interface") is theatre — see `design-reviewer`.
```

- [ ] **Step 2: Verify.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c "Alternatives considered" references/design-format.md   # expect 1
grep -c "unconditional" references/design-format.md             # expect >= 1
awk 'length > 100' references/design-format.md | head           # expect no new over-long lines
```

Read section 3 end to end and confirm it still reads as one coherent instruction.

- [ ] **Step 3: Commit.**

```bash
git add plugins/dev-workflows/references/design-format.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): design.md must record a rejected alternative

design-format.md had no requirement to name what was rejected, and
design-reviewer checked for none — while risk-planner has demanded exactly this
of plans for months. Designs were the weaker artifact.

Deliberately unconditional: it applies whether or not the interface fan-out ran,
so the fan-out is a quality upgrade to a requirement that fires every time
rather than a prerequisite for one.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: `design-format.md` — dependency categories and contested signals

**Files:**
- Modify: `plugins/dev-workflows/references/design-format.md` (section 5 `## Seams`, section 8
  `## Test strategy`)

**Interfaces:**
- Consumes: nothing from Tasks 1–2.
- Produces: the four category names Task 1's agent and Task 5's reviewer both use verbatim —
  **in-process**, **local-substitutable**, **remote-but-owned**, **true-external**.
- Produces: the four **contested-interface signals** Task 4's offer keys on.

- [ ] **Step 1: Extend section 5 (`## Seams`).** Locate the end of section 5 — the text ending:

```
   second real consumer exists — YAGNI for seams).
```

Append immediately after it, at the same indentation:

```
   **Classify each seam's dependency category** — it decides how the seam can be tested, and
   `## Test strategy` keys off it:
   - **in-process** — pure computation, in-memory state, no I/O. Test through the interface directly;
     no adapter needed.
   - **local-substitutable** — a real local stand-in exists (PGLite for Postgres, an in-memory
     filesystem). Test with the stand-in; the seam is internal, so no port at the external interface.
   - **remote-but-owned** — your own service across a network boundary. Define a **port** at the seam;
     an in-memory adapter for tests, HTTP/gRPC for production.
   - **true-external** — a third party you do not control. Injected port; tests supply a mock adapter.

   A category implying only one adapter is a hypothetical seam — the two-adapters heuristic above
   already says not to introduce it yet.

   **When an interface is *contested*** — any one of these — `/design` Phase 5 offers the three-take
   interface fan-out (`--design-twice` forces it):
   - two or more adapters are plausible for the same seam;
   - the interface spans a process or network boundary, so its shape decides what can be tested locally;
   - three or more callers share the shape;
   - two or more candidate shapes for the same interface are already recorded in `_design-session.md` and
     none has been eliminated (count the recorded candidates — do not judge whether an argument between
     them is "discriminating"; that is the unobservable form this list exists to avoid).
```

- [ ] **Step 2: Extend section 8 (`## Test strategy`)** — cross-reference, do not restate. Locate
section 8 and append to its text:

```
   Key each seam's approach to the **dependency category** recorded for it in `## Seams` — a
   remote-but-owned seam tested without a port, or a true-external dependency tested without a mock
   adapter, is a mismatch `design-reviewer` flags.
```

- [ ] **Step 3: Verify.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for c in in-process local-substitutable remote-but-owned true-external; do
  printf '%-22s %s\n' "$c" "$(grep -c -- "$c" references/design-format.md)"
done
# ^ expect >= 1 each. Note the leading `--` on grep: three of the four names begin with a hyphen-
#   containing token and an unguarded pattern can be read as an option.
grep -c "contested" references/design-format.md        # expect >= 1
grep -c "design-twice" references/design-format.md     # expect >= 1
```

- [ ] **Step 4: Commit.**

```bash
git add plugins/dev-workflows/references/design-format.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): dependency categories and contested-interface signals

## Seams said where to test but not how to test across a dependency. The four
categories (in-process, local-substitutable, remote-but-owned, true-external)
decide the test approach, so they are classified where the seam is named and
## Test strategy cross-references rather than restating them.

Also names the four observable signals that make an interface "contested", so
Phase 5's fan-out offer keys on something checkable rather than on feel.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `/design` — the flag, the offer, the dispatch, the report line

**Files:**
- Modify: `plugins/dev-workflows/commands/design.md` (frontmatter `description:`; a `Flags:` line; the
  Phase 1.5 classification/argument handling; Phase 5; the Final report)

**Interfaces:**
- Consumes: `interface-designer` (Task 1), the contested signals and category names (Task 3), the
  `### Alternatives considered` block (Task 2).
- Produces: the flag token **`--design-twice`**; the three Phase 5 report strings Task 8's residue audit
  audits. These are the three **outcomes** the report must distinguish — `ran`, `offered and declined`,
  `not offered` — rendered as one bracket-enumerated template line, NOT three literal strings. Tasks 8
  and 10 grep the decomposed forms (`Interface fan-out` ≥2, `not offered` ≥1) accordingly; do not write
  a check against the three full phrases, because none of them exists as a continuous substring.

**This task carries the spec's §8 risk.** A described-but-unwired offer is the defect the whole spec is
guarding against. Every step below must land in the command's **flow**, not beside it.

- [ ] **Step 1: The flag, all six places (spec §9.2).** Five are documentation; **the third is
  behaviour and breaks the command if missed.**

  1. **Frontmatter `description:`** — append to the existing sentence:
     ` Optional --design-twice forces the Phase 5 interface fan-out even when no contested-interface signal fired.`
  2. **A `Flags:` line** near the top of the body, mirroring `idea.md:15`'s placement and style:
     ```
     Flags: `--design-twice` forces the Phase 5 interface fan-out on the run's load-bearing interface, even when no contested-interface signal fired (`references/design-format.md` `## Seams`).
     ```
  3. **Argument parsing — the load-bearing one.** Find where `$ARGUMENTS` is classified/parsed in
     Phase 0/1.5 and make it read `$ARGUMENTS` **minus every recognised flag**, exactly as
     `commands/idea.md:65` does. An unstripped `--design-twice` is parsed as part of the Jira key and
     the run resolves the wrong feature — or fails. **If `design.md` has no flag-stripping step today
     because it had no flags, add one** and say so in the task report.
  4. **Phase 5, beside the offer** (Step 3 below) — what the flag forces and what it does not.
  5. **`README.md`** — Task 8.
  6. **`CLAUDE.md`** — Task 8.

- [ ] **Step 2: Verify the flag is stripped before classification.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n -- "--design-twice" commands/design.md | cut -c1-140     # expect >= 3 hits in this file
grep -n "minus every recognised flag" commands/design.md          # expect 1
```

If the second returns 0, step 1.3 did not land — the command will mis-parse its own argument.

- [ ] **Step 3: The Phase 5 offer.** Inside `## Phase 5 — Grill: challenge + design`, after the two
intertwined tracks are described and before Phase 5.5, insert:

```markdown
**Interface fan-out (offered on a signal; forced by `--design-twice`).** When the interview reaches an
interface decision that is **contested** — any signal in `${CLAUDE_PLUGIN_ROOT}/references/design-format.md`
`## Seams` — say which interface is contested, which signal fired, and your own read of the trade-off,
then offer. **Neither option carries a `(Recommended)` marker, and neither is recommended by default**:
this list is shown only once the interface is *already* contested, so which way to go depends on how
contested it actually is — a judgement that belongs to the user rather than to a marker, per the
"no option safe to recommend" remedy in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.

```
choices: ["Design it three ways (3 parallel takes, then compare)", "Decide it in the interview", "Other… (describe)"]
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
```

- [ ] **Step 4: The Phase 5 report line.** In the command's Final report section, add a line that
states exactly one of these whenever the run reaches the Final report (the offer is not
classification-gated, so gating the line would leave a MODERATE fan-out invisible):

```markdown
- **Interface fan-out:** [one of — `ran — <interface>, <N> of 3 takes returned, chose <A|B|C|hybrid>` — `<N>` counted from the takes that actually returned, naming the constraint of any that returned `BLOCKED` | `offered and declined — <interface>` | `not offered — no contested interface (no signal in design-format.md ## Seams)`]
```

**The third value is the point of this step.** Without it, "the contested-interface signals are too
narrow" and "there genuinely was no contested interface" produce identical output — silence — and the
feature could fail indefinitely without anyone learning it had.

- [ ] **Step 5: Verify reachability — this is the task's real gate.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c "interface-designer" commands/design.md          # expect >= 1 (the dispatch)
grep -c "Interface fan-out" commands/design.md           # expect >= 2 (offer heading + report line)
grep -c "not offered" commands/design.md                 # expect >= 1 (the silence-instrumenting value)
grep -n "choices:" commands/design.md | wc -l            # the offer is a real prompt, not prose
```

Then **trace it as an executing agent would**: read Phase 5 top to bottom and confirm the offer sits in
the flow the phase actually executes — not in a note beside it — and that the dispatch follows from
accepting the offer rather than standing alone.

- [ ] **Step 6: Commit.**

```bash
git add plugins/dev-workflows/commands/design.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): /design offers a three-take interface fan-out

Phase 5's grill is relentless and good at converging; it is not good at
diverging, because each question is asked in the context of the answers before
it. When an interface is contested by a named signal, the grill now offers three
parallel takes under opposed constraints and compares them on depth, locality,
and seam placement. --design-twice forces the offer.

The Final report states when a fan-out was NOT offered. Without that line, "the
signals are too narrow" and "nothing was contested" both produce silence, and
the feature could fail indefinitely without anyone learning it had.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: `design-reviewer` — two extended checks

**Files:**
- Modify: `plugins/dev-workflows/agents/design-reviewer.md` (`## Cross-cutting checks`)

**Interfaces:**
- Consumes: `### Alternatives considered` (Task 2) and the four category names (Task 3).
- Produces: no new dimension — both checks extend existing bullets, so no dimension count changes
  anywhere.

- [ ] **Step 1: Extend the Architecture-coherence check.** Locate this bullet in
`## Cross-cutting checks`:

```
- **Architecture coherence:** components and data flow are consistent; an interface referenced by no
  component (or vice-versa) → `MAJOR`.
```

Append to that same bullet:

```
  **Alternatives considered** is present and **substantive**: at least one genuinely plausible
  rejected alternative with the reason it lost. Missing → `MAJOR`. Present but theatre (an
  "alternative" nobody would have shipped — "we considered not having an interface") → `MAJOR`; it is
  worse than absent, because it satisfies the check while teaching the reader nothing. When the Phase 5
  fan-out ran, the losing takes should appear here named by constraint.
```

- [ ] **Step 2: Extend the Seam / test-strategy check.** Locate the bullet beginning
`- **Seam / test-strategy soundness:**` and append to it:

```
  Each named seam carries a **dependency category** (`in-process` / `local-substitutable` /
  `remote-but-owned` / `true-external`, per `${CLAUDE_PLUGIN_ROOT}/references/design-format.md`
  `## Seams`), and the test strategy matches it — a `remote-but-owned` seam tested without a port, or a
  `true-external` dependency tested without a mock adapter, → `MAJOR`. A seam with no category on a
  `MODERATE`+ design → `MINOR`.
```

- [ ] **Step 3: Verify.**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c "Alternatives considered" agents/design-reviewer.md    # expect 1
grep -c "dependency category" agents/design-reviewer.md         # expect >= 1
sed -n '/^## Cross-cutting checks/,/^## /p' agents/design-reviewer.md | grep -cE "^- \*\*"
# ^ cross-cutting bullet count — must be UNCHANGED by this task. Derived 2026-08-22: **10**. Treat that
#   as a hypothesis to test, not a target: record the actual number BEFORE editing and compare after.
#   Both checks EXTEND existing bullets; a new bullet would change the reviewer's shape, which this
#   task must not do. If the before-count is not 10, Tasks 1-4 touched a file they should not have.
```

- [ ] **Step 4: Commit.**

```bash
git add plugins/dev-workflows/agents/design-reviewer.md
git commit -m "$(cat <<'EOF'
feat(dev-workflows): design-reviewer checks alternatives and seam categories

Both extend existing cross-cutting bullets — no new dimension, no count change.

The alternatives check treats theatre as worse than absence: an "alternative"
nobody would have shipped satisfies the requirement while teaching the reader
nothing, which is the failure mode a mandatory section invites.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Port to mgd

- [ ] **Step 1: Branch, and check divergence against this round's own changed-file list.**

```bash
cd /workspace/mgd-claude-plugins
git switch main && git pull --ff-only && git switch -c iv-gu/design-it-twice
git status --porcelain     # expect no output
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows plugins/dev-workflows
```

The pre-copy diff will show **every file this round touched** plus the five identity files — that is
expected, because canonical is at the round's tip. Do **not** halt on the count. Cross-check each
differing path against `git -C /workspace/ihudak-claude-plugins diff --name-only main..HEAD`. A path on
neither that list nor the identity list means the editions were already out of lockstep — STOP and
report.

- [ ] **Step 2: Copy, then immediately restore the identity file.**

```bash
cd /workspace/mgd-claude-plugins
SRC=/workspace/ihudak-claude-plugins/plugins/dev-workflows
cp -r "$SRC"/agents "$SRC"/commands "$SRC"/references plugins/dev-workflows/
git checkout -- plugins/dev-workflows/references/dependencies.md
git diff --stat plugins/dev-workflows/references/dependencies.md   # expect NO output
grep -c "mgd-plugins" plugins/dev-workflows/references/dependencies.md   # expect >= 1
```

The restore is **mandatory**: `cp -r references` overwrites `dependencies.md`, an mgd identity file, and
`diff -rq` cannot detect it — an overwritten identity file makes the two files *match*, dropping the
count from five to four, and fewer differences reads like better parity.

`README.md`, `LICENSE`, `CHANGELOG.md`, and `plugin.json` are **not** in that `cp` and must not be added.

- [ ] **Step 3: Hand-edit mgd's own `README.md` and repo-root `CLAUDE.md`** with Task 8's edits. Never
`cp` either — README carries the `mgd-plugins` marketplace name and the `mgd-ai-containers` repo;
`CLAUDE.md` carries mgd-specific paths and a `## Plugin: managed-docs` section canonical does not have.

- [ ] **Step 4: Verify parity by content, not count.**

```bash
cd /workspace/mgd-claude-plugins
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows plugins/dev-workflows
# expect exactly five: plugin.json, README.md, LICENSE, references/dependencies.md, CHANGELOG.md
grep -c "mgd-plugins"        plugins/dev-workflows/references/dependencies.md   # >= 1
grep -c "Dynatrace Managed"  plugins/dev-workflows/.claude-plugin/plugin.json   # >= 1
grep -c "Dynatrace LLC"      plugins/dev-workflows/LICENSE                      # >= 1
grep -c "mgd-ai-containers"  plugins/dev-workflows/README.md                    # >= 1
ls plugins/dev-workflows/agents/*.md | wc -l                                    # expect 34
claude plugin validate .
```

- [ ] **Step 5: Commit** with the canonical message body plus `(ported from ihudak-claude-plugins)`.

---

## Task 7: Port to Copilot

**Never `cp` anything into this repo.** Apply each edit surgically. Path mapping:
`references/<f>.md` → `dev-workflows/skills/_shared/<f>.md`; `agents/<a>.md` →
`dev-workflows/agents/<a>.md`; `commands/<c>.md` → `dev-workflows/skills/<c>/SKILL.md`.

- [ ] **Step 1: Branch.**

```bash
cd /workspace/ihudak-copilot-plugins
git switch main && git pull --ff-only && git switch -c iv-gu/design-it-twice
git status --porcelain   # expect no output
```

- [ ] **Step 2: Apply Tasks 1–5 to Copilot's paths**, reading canonical's diffs
(`git -C /workspace/ihudak-claude-plugins diff main..HEAD`) and applying the equivalent by hand.

Dialect on every inserted line: absolute `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<f>.md`
(never `${CLAUDE_PLUGIN_ROOT}`); `task(agent_type: "dev-workflows:interface-designer", model: …)` (never
`Agent`/`subagent_type`); colon-form command names (`design:`, never `/design`); lowercase
`tools: [view, glob, grep, bash]` in the new agent's frontmatter.

**Anchors will differ.** Copilot's files carry genuinely different *content*, not only different
dialect — its `bug-diagnosis.md` header, for instance, cites a different discipline than canonical's.
Locate by quoted surrounding text, and when a canonical anchor is absent, find Copilot's equivalent
rather than forcing canonical's wording in. If no equivalent exists, **STOP and report** — do not invent
a section.

- [ ] **Step 3: The `_shared` index bullet.** Copilot has no `CLAUDE.md`; its reference index is the
`_shared` list in `dev-workflows/README.md`. `design-format.md` is already indexed there, so this round
adds no new reference file and needs no new bullet — **confirm that** rather than assuming, and say so
in the report.

- [ ] **Step 4: `.github/copilot-instructions.md` — NOT this task.** Task 8 owns it, together with
`CLAUDE.md` in the two Claude editions, so all three editions' instruction files are edited in one pass
and stay consistent. An earlier draft of this plan assigned it to **both** Task 7 and Task 8; the
implementer of Task 7 caught the duplication and reported it rather than silently choosing. If you are
executing Task 7, skip this file entirely.

- [ ] **Step 5: Verify no dialect leaked.**

```bash
cd /workspace/ihudak-copilot-plugins
grep -rn "CLAUDE_PLUGIN_ROOT" dev-workflows/ | grep -v CHANGELOG   # expect no output
grep -rn "subagent_type"      dev-workflows/ | grep -v CHANGELOG   # expect no output
grep -rn "[a-z]:\.md"         dev-workflows/                        # expect no output
ls dev-workflows/agents/*.md | wc -l                                # expect 34
python3 -c "import json;[json.load(open(p)) for p in ['dev-workflows/.plugin/plugin.json','.github/plugin/marketplace.json']];print('JSON OK')"
```

- [ ] **Step 6: Commit.**

---

## Task 8: Docs, counts, and the residue audit

**Files:**
- Modify: `CLAUDE.md`, `plugins/dev-workflows/README.md` (all three editions, hand-edited per edition)

- [ ] **Step 1: Derive the counts. Do not increment by hand.**

```bash
for r in ihudak-claude-plugins mgd-claude-plugins ihudak-copilot-plugins; do
  d=$([ "$r" = ihudak-copilot-plugins ] && echo dev-workflows || echo plugins/dev-workflows)
  printf '%-24s agents=%s\n' "$r" "$(ls /workspace/$r/$d/agents/*.md | wc -l)"
done
```

- [ ] **Step 2: Update the printed counts.** `plugins/dev-workflows/README.md:230` reads
"Thirty-three reusable subagents" — it becomes **thirty-four**, spelled the same way. Find the
equivalent claim in `CLAUDE.md` and in Copilot's README and update each **to the number derived in
step 1**, not to a number copied from this plan.

- [ ] **Step 3: Add the agent-table row** for `interface-designer` to each edition's README, matching
that table's existing column shape. Model column: `per routing` in the Claude editions,
`Strong tier, caller-pinned`-style wording per that edition's own convention in Copilot — **read a
neighbouring row and match it** rather than copying canonical's.

- [ ] **Step 4: `CLAUDE.md`** (Claude editions; `.github/copilot-instructions.md` for Copilot, where a
target exists): add `interface-designer` to the agent ledger naming `/design` as its only caller, and
extend the `/design` workflow-map line with the offered fan-out.

- [ ] **Step 5: The flag's remaining two homes** (spec §9.2 items 5–6): the README command-table
invocation signature gains `[--design-twice]` in the same bracketed style as `[--deep]`, and `CLAUDE.md`
states the behaviour where the `/design` invariants are described.

- [ ] **Step 6: Residue audit — "what did I just make false?"** The starting greps are a floor:

```bash
cd /workspace/ihudak-claude-plugins
grep -rnE "[Tt]hirty-three|33 (reusable )?sub-?agents" CLAUDE.md plugins/dev-workflows/README.md
# ^ expect no output after step 2
grep -rn "design-twice" CLAUDE.md plugins/dev-workflows/README.md plugins/dev-workflows/commands/design.md | wc -l
grep -rn "interface-designer" CLAUDE.md plugins/dev-workflows/README.md | wc -l   # expect >= 2
```

Then ask of every claim this round touched: is it still true? Specifically — any statement about what
`/design` does, any consumer list for `design-format.md`, any agent-count or reviewer-dimension claim,
and any statement that `design.md` has no alternatives requirement.

- [ ] **Step 7: Mermaid — confirm unchanged, deliberately.** Spec §9.1: **neither diagram changes.**
Diagram 1 shows `/design` as a node in a command-to-command graph and this round changes no command's
inputs, outputs, or position; diagram 2 is `/implement`'s internals. Verify with a form that cannot pass
vacuously — compare against the pre-task commit, not the working tree:

```bash
cd /workspace/ihudak-claude-plugins
git diff <TASK8_BASE> HEAD -- plugins/dev-workflows/README.md | grep -E "^[-+].*(subgraph|flowchart)"
# expect no output. Record TASK8_BASE (git rev-parse HEAD) BEFORE editing.
```

- [ ] **Step 8: Commit** in each repo.

---

## Task 9: Versions, catalogs, changelogs

- [ ] **Step 1: Derive the six files. Do not type them.**

```bash
for r in ihudak-claude-plugins mgd-claude-plugins ihudak-copilot-plugins; do
  find /workspace/$r \( -name 'marketplace.json' -o \( -name 'plugin.json' -path '*dev-workflows*' \) \) -not -path '*/.git/*'
done
```

Expect six. Copilot's catalog is at `.github/plugin/marketplace.json` — **depth 3**, where a bounded
`find` misses it. That exact miss has shipped a mismatched catalog four times.

- [ ] **Step 2: Bump.** canonical + mgd `2.55.0 → 2.56.0`; Copilot `2.25.0 → 2.26.0`. Each catalog lists
**four** plugins — edit only the `dev-workflows` entry.

- [ ] **Step 3: Leave every `description` blurb unchanged.** Hard 1024-char budget enforced by
`scripts/validate-catalog.py`, which rejects the **whole catalog** — one over-long blurb breaks installs
for every plugin in that marketplace. This round is a capability addition; if a blurb genuinely must
change it **replaces** wording and never appends.

- [ ] **Step 4: CHANGELOG entries** in all three, matching each file's existing voice (this repo's
changelog explains *why* a defect mattered, not only what changed). mgd's is annotated
`(ported from ihudak-claude-plugins)`.

- [ ] **Step 5: Verify.**

```bash
for r in ihudak-claude-plugins mgd-claude-plugins ihudak-copilot-plugins; do
  echo "== $r"
  grep -h '"version"' $(find /workspace/$r -name 'plugin.json' -path '*dev-workflows*' -not -path '*/.git/*')
  python3 -c "
import json,glob
p=[x for x in json.load(open(glob.glob('/workspace/$r/**/marketplace.json',recursive=True)[0]))['plugins'] if x['name']=='dev-workflows']
print('catalog:',p[0]['version'])"
done
cd /workspace/ihudak-claude-plugins && python3 scripts/validate-catalog.py
```

The two numbers must match within each repo.

- [ ] **Step 6: Commit** in each repo.

---

## Task 10: Cross-edition verification

**Verify, do not fix.** A verification pass that also edits can hide what it changed. Report defects;
the fix is a separate wave.

- [ ] **Step 1: Gates.** canonical: `claude plugin validate .`, `python3 scripts/validate-catalog.py`,
`./scripts/check-id-grammar.sh --selftest` then `--root .`. mgd: `claude plugin validate .`. Copilot:
both JSON manifests parse.

- [ ] **Step 2: Parity** — canonical ↔ mgd `diff -rq` expects exactly five identity files, **each
verified by content** (§Global Constraints). Four entries means an identity file was destroyed.

- [ ] **Step 3: Reachability, per edition.** Derive, do not assert:

```bash
# Claude editions (canonical, mgd) — run in each repo root:
D=plugins/dev-workflows
grep -rl "interface-designer" $D/agents $D/commands        # expect: the agent file + commands/design.md
grep -c "Interface fan-out"       $D/commands/design.md     # expect >= 2
grep -c "not offered"             $D/commands/design.md     # expect >= 1
grep -c "Alternatives considered" $D/references/design-format.md $D/agents/design-reviewer.md  # >= 1 each

# Copilot — run in /workspace/ihudak-copilot-plugins:
D=dev-workflows
grep -rl "interface-designer" $D/agents $D/skills            # expect: the agent file + skills/design/SKILL.md
grep -c "Interface fan-out"       $D/skills/design/SKILL.md  # expect >= 2
grep -c "not offered"             $D/skills/design/SKILL.md  # expect >= 1
grep -c "Alternatives considered" $D/skills/_shared/design-format.md $D/agents/design-reviewer.md  # >= 1 each
```

- [ ] **Step 4: Producer/consumer string match.** Every marker `/design` branches on must be **exactly**
what `interface-designer` emits, and the `### Alternatives considered` heading must match between
`design-format.md`, `design-reviewer.md`, and `design.md`. A branch testing for a string the producer
never writes is a dead gate wearing a different hat — this has occurred twice in recent rounds.

- [ ] **Step 5: Report** — every command run with its verbatim output, including the checks that found
nothing. A report listing only problems is indistinguishable from one where the checks never ran.
Written **last**, after the final fix wave.

---

## Self-review notes

**Spec coverage.** §3 → Task 1; §4.1/§4.3/§4.4 → Task 4 Step 3; §4.5 → Task 4 Step 1 + §9.2 → Task 4
Steps 1–2 and Task 8 Step 5; §5 → Task 2; §6 → Task 3; §7 → Task 5; §8.1 → Task 4 Step 4; §9 → Task 8;
§9.1 → Task 8 Step 7; §10 → Task 10; §10 item 5 (cross-edition) → Tasks 6–7.

**Known plan-level decisions.** (a) **Confirmed while writing this plan:** `design.md` has **zero**
flag-stripping steps today (`grep -c "minus every recognised flag" commands/design.md` → 0), because it
has no flags. Task 4 Step 1.3 therefore **adds** that step rather than extending one; there is no anchor
to find, and an implementer looking for one will not find it. (b) Task 5 asserts the cross-cutting bullet count must be **unchanged** but does not
hardcode it; the step says to record it before editing, because a number written here would be a
copied expectation of exactly the kind that has gone stale in three previous rounds.

**Unverified line references.** Line numbers age as earlier tasks edit the same files. Every step
locates by quoted surrounding text; if a quoted string is absent, STOP and report rather than guessing.
`README.md:230` is the only hardcoded line reference and Task 8 Step 2 re-derives its content before
editing.
