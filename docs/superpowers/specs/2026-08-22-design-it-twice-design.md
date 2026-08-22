# Design it twice — parallel interface exploration for `/design` — design

**Status:** approved for planning — pre-implementation design snapshot
**Ships as:** dev-workflows 2.56.0 (canonical + mgd) / 2.26.0 (copilot)
**Branch:** `iv-gu/design-it-twice` (all three repos)
**Origin:** harvest item 6, surveyed 2026-08-21, deliberately deferred out of rounds 2 and 3a for its own
architectural cycle. Source: mattpocock `codebase-design/DESIGN-IT-TWICE.md` and `DEEPENING.md`.

## 1. Context

`/design` authors `design.md` through a **relentless** interview (Phase 5): decisions settle one at a
time, and the section is written as each settles. That mechanic is good at *converging* — it is not
good at *diverging*. When several interface shapes are defensible, an interview tends to walk down the
first shape that survives scrutiny, because each question is asked in the context of the answers before
it. Ousterhout's observation is that the first idea is rarely the best one; upstream's response is to
generate several deliberately different interfaces in parallel and compare them.

Two gaps make this worth adopting rather than noting:

- **`design-format.md` has no requirement to record a rejected alternative.** Verified 2026-08-22:
  zero matches for alternative / rejected / trade-off in that file, and `design-reviewer` checks for
  none. `risk-planner` already demands this of *plans* ("Name at least one alternative that was
  rejected and the reason"), so designs are the weaker artifact today.
- **`design-format.md`'s `## Seams` says where to test but not how to test across a dependency.**
  It carries the two-adapters heuristic already; it does not say that a seam's *dependency category*
  determines the test approach.

## 2. What ships

1. A new **`interface-designer`** agent — one bounded take on one interface under one named constraint.
2. An **offered fan-out** inside Phase 5's grill: three takes in parallel, compared, recommended.
3. **`--design-twice`**, forcing the fan-out on the load-bearing interface.
4. `design-format.md`: an **alternatives-considered** requirement, and the **four dependency
   categories** in `## Seams`.
5. `design-reviewer`: two checks, both extending existing dimensions.

## 3. The `interface-designer` agent

**Job.** Given a framed problem, the code context `/design` already scanned in Phase 4, and **one**
named constraint, produce a single interface proposal. Not a design document — one interface.

**Output** (fixed shape, so three takes can be compared field by field):

- **Interface** — signatures, plus the facts a caller must know that a signature does not carry:
  invariants, ordering constraints, error modes, required configuration.
- **Usage example** — how a caller actually uses it.
- **What it hides** — the behaviour that sits behind the seam.
- **Dependency strategy** — the seam's dependency category (§6) and the adapters implied.
- **Trade-offs** — where leverage is high, and where it is thin.

**Tools:** `["Read", "Glob", "Grep", "Bash"]`, matching `code-scanner` rather than the reviewers. To
design an interface against real code the agent needs to know how many callers exist and what they
pass; `git grep -c` and `git log` are the natural way to find out. `Bash` is bounded exactly as
`risk-planner`'s is: **read and inspect only** — never edit, create or delete a file; never `git add`,
commit, switch, stash or reset; never touch the index, `HEAD`, or branch state; never install or
remove a dependency. It proposes; the caller writes.

**Model tier:** detection chain (§2.1). Each take is *bounded generation under a prescriptive
constraint* — the expensive judgement, comparing three takes on depth, locality, and seam placement,
stays with the orchestrator, which is already on the strong chain for a SIGNIFICANT/HIGH-RISK design.
This matches the plugin's standing mechanical→detection, synthesis→strong split.

**It dispatches nothing.** No `Task` in its tool list, and a hard rule saying so.

## 4. The fan-out, inside Phase 5

### 4.1 When it is offered

The grill offers the fan-out when it reaches an interface decision that is genuinely **contested**.
"Contested" is not left to feel — `design-format.md` carries observable signals, any one of which
qualifies:

- two or more adapters are plausible for the same seam (the two-adapters heuristic says the seam is
  real, which is exactly when its shape matters);
- the interface spans a process or network boundary, so its shape decides what can be tested locally;
- three or more callers share the shape, so the cost of getting it wrong multiplies;
- the interview has produced two defensible shapes and no discriminating argument between them.

Absent any signal, no offer is made and the interview proceeds exactly as it does today.

### 4.2 The offer

The grill states which interface is contested, why, and its own read of the trade-off — then offers,
in the plugin's standard `choices:` form. Declining costs nothing and changes nothing; the interview
continues and the alternatives requirement (§5) is satisfied by hand as it would have been anyway.

### 4.3 The takes

On acceptance: **three dispatches in a single response** — the plugin's existing parallel-fan-out
pattern — each with the same brief and a different constraint:

| Take | Constraint |
|---|---|
| A | **Minimise the interface** — aim for 1–3 entry points; maximise behaviour per entry point learned. |
| B | **Maximise flexibility** — support extension and use cases beyond the immediate one. |
| C | **Optimise for the most common caller** — make the dominant case trivial, even at the cost of the rare one. |

Each take receives the framed problem, the relevant `code-scanner` findings from Phase 4, the seam's
dependency category if already known, and its constraint. Each is blind to the others — that is what
makes the takes diverge rather than converge.

### 4.4 The comparison

The orchestrator presents the three takes, then compares them **on named axes**, not impressions:
**depth** (behaviour per unit of interface a caller must learn), **locality** (where change, bugs, and
verification concentrate), and **seam placement** (whether the boundary falls where things actually
vary). It then gives an opinionated recommendation — and proposes a **hybrid** where the strongest
ideas split across takes, which is a common outcome and should not be treated as indecision.

The user chooses. The interview resumes with the chosen interface settled.

### 4.5 `--design-twice`

Forces the fan-out on the run's load-bearing interface even when no §4.1 signal fired. It exists
because the user may know the interface is hard before the grill discovers it. It is **not** the
mitigation for §8's risk — §5 and §7 are.

**Deliberately not named `--deep`.** On `/idea`, `--deep` switches a *bounded* grill to relentless.
`/design`'s grill is already relentless, so `--deep` there would either be a no-op or mean something
different from the same flag on a sibling command. Same-name-different-meaning across commands is a
defect this plugin has paid for before.

## 5. `design-format.md` — alternatives considered

`## Architecture & components` gains: **name at least one alternative that was rejected, and why.**

This mirrors `risk-planner`'s existing requirement for plans and is **unconditional** — it applies to
every design, fan-out or not. That is deliberate and is the load-bearing decision of this spec: the
durable requirement fires every time, and the fan-out is one way of satisfying it well. A design that
never fans out still records alternatives, written by hand; a design that does fans them out and
records real ones, with the trade-offs the takes actually surfaced.

The consequence is that the fan-out is a **quality upgrade to a requirement**, not a prerequisite for
one. If the fan-out never fired, no design would be missing a section.

## 6. `design-format.md` — dependency categories in `## Seams`

A seam's dependency category determines how it can be tested. Classify it where the seam is named:

| Category | What it is | How the seam is tested |
|---|---|---|
| **In-process** | pure computation, in-memory state, no I/O | test through the interface directly; no adapter needed |
| **Local-substitutable** | a real local stand-in exists (PGLite for Postgres, in-memory filesystem) | test with the stand-in; the seam is internal, no port at the external interface |
| **Remote but owned** | your own service across a network boundary | define a **port** at the seam; in-memory adapter for tests, HTTP/gRPC for production |
| **True external** | a third party you do not control | injected port; tests provide a mock adapter |

`## Test strategy` **cross-references** the category rather than restating it — one definition, one
consumer, per this repo's single-source-of-truth convention. Pairs with the two-adapters heuristic
`## Seams` already carries: a category that implies only one adapter is a hypothetical seam.

## 7. `design-reviewer` — two checks

Both extend existing dimensions; no new dimension, no change to the dimension count.

- **Architecture coherence** gains: the alternatives-considered entry is present **and substantive**.
  A rejected alternative that was never plausible ("we considered not having an interface") is
  theatre and is a finding, not a pass.
- **Seam / test-strategy soundness** gains: each named seam carries a dependency category, and the
  test strategy matches it — a remote-but-owned seam tested without a port, or a true-external
  dependency tested without a mock adapter, is a finding.

## 8. The risk, and how it is handled

**The risk:** the grill never recognises a contested interface, the offer never appears, and the round
ships an agent nobody dispatches — a dead gate with a price tag. This plugin has shipped that class
repeatedly, most recently a rule whose branch could not fire.

Three things handle it, in order of strength:

1. **The artifact requirement is unconditional (§5).** If the fan-out never fires, no design is missing
   anything; the worst case is an unused agent, not a hole in the output. The fan-out is not
   load-bearing for correctness.
2. **The non-firing is observable (§8.1).** Silence is instrumented rather than trusted.
3. **`--design-twice` (§4.5)** gives a way to invoke it directly, so the feature is reachable even if
   the recognition signals turn out to be too narrow.

### 8.1 Instrumenting the silence

On a SIGNIFICANT / HIGH-RISK run, the Phase 5 report states exactly one of:

- `Interface fan-out: ran — <interface>, 3 takes, chose <A|B|C|hybrid>`
- `Interface fan-out: offered and declined — <interface>`
- `Interface fan-out: not offered — no contested interface (no §4.1 signal)`

The third line is the point. Without it, "the recognition signals are too narrow" and "there genuinely
was no contested interface" produce identical output — silence — and the feature could fail for months
without anyone learning it had. With it, a handful of runs tells you which.

## 9. Residue this creates

- Agent count moves **33 → 34**. Claimed in `plugins/dev-workflows/README.md:230` ("Thirty-three
  reusable subagents") and in `CLAUDE.md`'s agent ledger. **Derive the new count** (`ls
  plugins/dev-workflows/agents/*.md | wc -l`); do not increment the printed number by hand.
- `CLAUDE.md`'s `/design` workflow-map line gains the fan-out.
- `CLAUDE.md`'s agent ledger gains an `interface-designer` row naming `/design` as its only caller.
- `README.md`'s agent table gains a row.

### 9.2 Documenting `--design-twice` — six places, derived from how `--deep` is documented

A flag in this plugin is not documented by mentioning it once. Derived 2026-08-22 from `/idea`'s
`--deep` and `/document`'s `--counterpart`, every flag appears in all of these, and a plan task must
name each:

1. **`commands/design.md` frontmatter `description:`** — this is what the slash-command listing shows.
2. **`commands/design.md` body, the `Flags:` line** near the top (`idea.md:15` is the pattern), stating
   what the flag does in one sentence.
3. **`commands/design.md` argument parsing** — the classification step must read `$ARGUMENTS` **minus
   every recognised flag**. `idea.md:65` does this explicitly. **This is the one that breaks the command
   if missed**: an unstripped `--design-twice` is parsed as part of the Jira key or the argument text,
   and the run fails or resolves the wrong feature. It is also the only one of the six that is not
   documentation at all but behaviour, which is exactly why it is easy to omit from a documentation
   checklist.
4. **`commands/design.md`, the section where it takes effect** — Phase 5, beside the §4.1 offer, saying
   what the flag forces and what it does not.
5. **`plugins/dev-workflows/README.md`** — the command table's invocation signature, in the same
   bracketed style as `[--deep]` / `[--ground-code …]`.
6. **`CLAUDE.md`** — wherever the behaviour is stated as an invariant, so the flag and the rule it
   overrides are described in one place rather than two that can drift.

All six exist in each of the three editions, with Copilot's paths mapped per §10.5 and its colon-form
command names (`design:`, never `/design`).

### 9.1 Mermaid — deliberately unchanged

`README.md` carries two mermaid diagrams. **Neither changes**, and this is recorded so a later reader
does not "helpfully" edit one into inconsistency:

- **Diagram 1** (PM/PA/PE/Dev/QA pipeline overview) shows `/design` as a *node* in a command-to-command
  graph (`design["/design"] --> implement["/implement"]`). This round changes no command's inputs,
  outputs, or position in the pipeline.
- **Diagram 2** is `/implement`'s internal workflow. This round does not touch `/implement`.

There is **no `/design` internals diagram**, and this round does not create one. `/implement` has one
because it is the most complex command in the plugin, not because internals diagrams are the
convention.

## 10. Verification

No test framework — verification is derived greps, reachability tracing, and the repo's gates.

1. **Reachability, the primary check.** Trace the fan-out from offer to dispatch to output: the Phase 5
   offer exists in the command's *flow* (not merely described beside it); the dispatch names
   `interface-designer`; the comparison lands in `design.md`'s alternatives entry; the Phase 5 report
   line is emitted on every SIGNIFICANT/HIGH-RISK run. A described-but-unwired offer is this spec's
   own §8 risk realised.
2. **Producer/consumer string match.** Any marker the command branches on must be exactly what the
   agent emits. A branch testing for a string the producer never writes is a dead gate wearing a
   different hat — this has occurred twice in recent rounds.
3. **Counts derived, never copied** — the agent count in particular (§9).
4. **Gates:** `claude plugin validate .`, `scripts/validate-catalog.py`,
   `scripts/check-id-grammar.sh --selftest` then the tree scan.
5. **Cross-edition:** canonical ↔ mgd differ in exactly the five identity files, **verified by content
   not by count** (an overwritten identity file *lowers* the count); Copilot shows zero
   `${CLAUDE_PLUGIN_ROOT}` or `subagent_type` leakage and uses `task(agent_type:)` and colon-form
   command names.
6. **The verification record is written last**, after the final fix wave.

## 11. Open questions

None. Five decisions were settled in the 2026-08-22 brainstorm: the unit and trigger (one contested
interface, offered inside the grill), who decides (the grill offers, the user chooses), where the
output lands (an unconditional alternatives requirement the fan-out populates), the fan-out's shape
(new `interface-designer` agent, three takes, detection tier), and the scope of the DEEPENING material
(four categories into `## Seams`, consumed by `## Test strategy`, with a reviewer check).

Two decisions were made while writing this spec and are flagged as the author's call rather than the
user's: the flag is named `--design-twice` rather than `--deep` (§4.5), and `interface-designer`
carries `Bash` on the `code-scanner` precedent rather than the reviewer precedent (§3).
