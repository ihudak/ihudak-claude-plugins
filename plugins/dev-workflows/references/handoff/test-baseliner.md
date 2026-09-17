# test-baseliner Handoff Format

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

## Input

```markdown
## Test Baseline Request
repo: /absolute/path/to/repo
mode: capture              # capture | verify
command_hint: "./mvnw test -q"   # optional; one or more commands. Detection still runs —
                                 # the hint narrows what is RUN, never what is DETECTED.
                                 # Omitted (the only form any caller sends today) ⇒ every
                                 # detected suite runs.
baseline:                  # required only for mode: verify
  passing_count: 47
  passing_tests:           # may be [] if only count was available
    - com.example.FooTest#testCreate
    - com.example.BarTest#testLogin
```

**No `model_routing:` block is passed.** The caller pins this agent's tier with `model:` on the dispatch, and nothing in the agent reads a field of that block.

## Output — capture mode

The agent returns a Markdown block, not YAML — this is the exact structure
(see `agents/test-baseliner.md` "Mode: capture" step 5):

```markdown
## Test Baseline
- **Mode**: capture
- **Status**: OK                 <!-- OK | RUN_FAILED | COMMAND_NOT_FOUND | NO_TESTS -->
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

**Field mapping for callers that need YAML-shaped fields** (e.g. `vuln-fixer`'s
and `upgrade-executor`'s `baseline:` input — see their own handoff docs):
`passing_count` = the **Passing** number; `passing_tests` = the `### Passing
tests` list — with several suites, that number and that list are already the
totals across them, so neither caller changes. The orchestrator re-keys these
when constructing the next agent's prompt — this agent never emits raw YAML.

## Output — verify mode

```markdown
## Test Verify Report
- **Mode**: verify
- **Status**: REGRESSIONS              <!-- OK | REGRESSIONS | RUN_FAILED | COMMAND_NOT_FOUND -->
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

**status values (the authoritative field callers branch on):**
- `OK` — all previously-green tests still green
- `REGRESSIONS` — one or more baseline tests now fail, or are missing from
  the run entirely; see the `### Regressions` / `### Missing from run` lists
- `RUN_FAILED` — **any** suite's command exited with error or produced no
  parseable output, or the framework set changed since baseline (**Comparison
  status**: `invalid`) so no comparison was possible. Any, not all: a run
  missing one of the repository's suites cannot detect a regression in it.
  `### Suites` names which one, and with what command
- `COMMAND_NOT_FOUND` — detection selected no suite at all, so nothing ran
  (**Framework** then reads `not detected`). Never emitted once a call reaches
  the run step

**Note:** `passing_count` / `regressions` / `new_passes` as bare YAML keys
are a caller-side re-keying convenience, not literal fields this agent
emits — see the field mapping above and each consumer's own handoff doc
for the exact keys it expects back from the *orchestrator* (not from this
agent directly).
