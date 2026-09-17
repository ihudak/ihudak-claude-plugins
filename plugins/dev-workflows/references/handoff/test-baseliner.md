# test-baseliner Handoff Format

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

## Input

```markdown
## Test Baseline Request
repo: /absolute/path/to/repo
mode: capture              # capture | verify
command_hint: "./mvnw test -q"   # optional; one or more commands. Detection still runs —
                                 # the hint narrows what is RUN, never what is DETECTED.
                                 # Omitted ⇒ every detected suite runs. A hint sent on the
                                 # capture call is sent again on every verify call against
                                 # that baseline, or the two runs have nothing to pair.
baseline: |                # required for mode: verify — the full `## Test Baseline` block
  ## Test Baseline         # from the capture call, verbatim, `### Suites` included
  - **Mode**: capture
  …
```

**Hand verify the whole block, not a re-keyed digest of it.** Its `### Suites` rows are
what verify pairs the current run against, and they are also what separates a suite the
baseline recorded `OK` and that aborts now (a regression — the change is the only thing
that moved) from one that could not run at either end (`PARTIAL` — a fact about the
environment). A caller that passes counts alone leaves verify unable to tell those apart.

**No `model_routing:` block is passed.** The caller pins this agent's tier with `model:` on the dispatch, and nothing in the agent reads a field of that block.

## Output — capture mode

The agent returns a Markdown block, not YAML — this is the exact structure
(see `agents/test-baseliner.md` "Mode: capture" step 5):

```markdown
## Test Baseline
- **Mode**: capture
- **Status**: OK                 <!-- OK | PARTIAL | RUN_FAILED | COMMAND_NOT_FOUND | NO_TESTS -->
- **Framework**: Maven
- **Command**: `./mvnw test -q`
- **Total**: 47 | **Passing**: 47 | **Failing**: 0 | **Skipped**: 0

### Pre-existing failures
none

### Passing tests
com.example.FooTest#testCreate
com.example.BarTest#testLogin

### Suites
Maven | pom.xml | `./mvnw test -q` | OK | Total 47, Passing 47, Failing 0, Skipped 0
```

**A repository with more than one suite baselines all of them**, which the block
above expresses without changing shape: **Framework** and **Command** become
comma-separated lists in run order, the counts are the sums, the two test lists
are the union with each identifier prefixed `[<Framework>] `, and `### Suites`
carries one line per detected suite — framework, marker, command, per-suite
status, per-suite counts — including any the `command_hint` left `not run`. A
single-suite repository's block is unchanged in every field, `### Suites` aside.

**capture status values:**
- `OK` — every detected suite ran and produced counts, Total > 0
- `PARTIAL` — at least one suite produced counts and at least one did not. The
  baseline covers exactly the suites `### Suites` marks `OK` or `NO_TESTS`, and
  names each one it does not cover with the command that failed. It is
  incompleteness, never a verdict on the code: a caller that stops on it stops
  because a JavaScript runner is not installed
- `RUN_FAILED` — **every** suite that was run aborted with no parseable counts,
  so the baseline records nothing for a later verify to compare against
- `NO_TESTS` — every suite ran cleanly and the combined Total = 0
- `COMMAND_NOT_FOUND` — detection selected no suite at all (**Framework** then
  reads `not detected`)

**Field mapping for callers that need YAML-shaped fields** (e.g. `vuln-fixer`'s
and `upgrade-executor`'s `baseline:` input — see their own handoff docs):
`passing_count` = the **Passing** number; `passing_tests` = the `### Passing
tests` list — with several suites, that number and that list are already the
totals across them, so neither caller changes. The orchestrator re-keys these
when constructing the next agent's prompt — this agent never emits raw YAML.
**Those two keys are a convenience beside the block, never a replacement for
it:** whatever else a caller sends, the `verify` call gets the whole block.

## Output — verify mode

```markdown
## Test Verify Report
- **Mode**: verify
- **Status**: REGRESSIONS              <!-- OK | PARTIAL | REGRESSIONS | RUN_FAILED | COMMAND_NOT_FOUND -->
- **Framework**: Maven
- **Command**: `./mvnw test -q`
- **Comparison status**: exact         <!-- exact | best-effort | invalid -->
- **Total**: 47 | **Passing**: 46 | **Failing**: 1 | **Skipped**: 0
- **Baseline passing**: 47 | **Regressions**: 1 | **Missing from run**: 0

### Regressions (previously passing, now failing)
com.example.FooTest#testCreate

### Missing from run (previously passing, not present in current run)
none

### Newly fixed (previously failing, now passing)
none

### New failures (new tests that are already failing)
none

### Notes
none

### Suites
Maven | pom.xml | `./mvnw test -q` | OK | Total 47, Passing 46, Failing 1, Skipped 0

### Current passing tests
com.example.BarTest#testLogin
```

**verify status values (the authoritative field callers branch on):**
- `OK` — every detected suite ran and all previously-green tests are still green
- `REGRESSIONS` — one or more baseline tests now fail, or are missing from the
  run entirely; see the `### Regressions` / `### Missing from run` lists. A suite
  the baseline recorded `OK` and that aborts here lands here too, because every
  baseline test of it is then unaccounted for — it ran before this change and
  does not now
- `PARTIAL` — no regressions, and at least one detected suite produced no counts
  here **and none in the baseline either**. The comparison is sound as far as it
  reaches and says nothing about that suite; `### Suites` names it
- `RUN_FAILED` — nothing was verified: no detected suite matches the baseline
  (**Comparison status**: `invalid`), or no suite produced counts in this run at
  all. It is tested **after** `REGRESSIONS`, so a run in which every suite aborted
  is a regression where the baseline had run them
- `COMMAND_NOT_FOUND` — detection selected no suite at all, so nothing ran
  (**Framework** then reads `not detected`). Never emitted once a call reaches
  the run step

**What a consumer may do with each.** `REGRESSIONS` is the only value that is
evidence about the change, and the only one on which reverting it is warranted.
`PARTIAL`, `RUN_FAILED` and `COMMAND_NOT_FOUND` each say a suite could not be
run — they are facts about the environment, so a consumer records which suite and
proceeds or escalates, and **never reverts work on them**. Reverting on one of
those rolls back a correct change in one language because a runner for another
is not installed.

**Note:** `passing_count` / `regressions` / `new_passes` as bare YAML keys
are a caller-side re-keying convenience, not literal fields this agent
emits — see the field mapping above and each consumer's own handoff doc
for the exact keys it expects back from the *orchestrator* (not from this
agent directly).
