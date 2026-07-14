# test-baseliner Handoff Format

## Input

```markdown
## Test Baseline Request
repo: /absolute/path/to/repo
mode: capture              # capture | verify
command_hint: "mvn test"   # optional; overrides auto-detection
baseline:                  # required only for mode: verify
  passing_count: 47
  passing_tests:           # may be [] if only count was available
    - com.example.FooTest#testCreate
    - com.example.BarTest#testLogin
model_routing:             # optional; informational only — test-baseliner
  classification: SIGNIFICANT  # ignores routing and runs under whichever
  # model the caller selected. See `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` for the model-routing block schema.
```

## Output — capture mode

The agent returns a Markdown block, not YAML — this is the exact structure
(see `agents/test-baseliner.md` "Mode: capture" step 5):

```markdown
## Test Baseline
- **Mode**: capture
- **Status**: OK                 <!-- OK | RUN_FAILED | COMMAND_NOT_FOUND | NO_TESTS -->
- **Framework**: Maven
- **Command**: `mvn test -q`
- **Total**: 47 | **Passing**: 47 | **Failing**: 0 | **Skipped**: 0

### Pre-existing failures
none

### Passing tests
com.example.FooTest#testCreate
com.example.BarTest#testLogin
```

**Field mapping for callers that need YAML-shaped fields** (e.g. `vuln-fixer`'s
and `upgrade-executor`'s `baseline:` input — see their own handoff docs):
`passing_count` = the **Passing** number; `passing_tests` = the `### Passing
tests` list. The orchestrator re-keys these when constructing the next
agent's prompt — this agent never emits raw YAML.

## Output — verify mode

```markdown
## Test Verify Report
- **Mode**: verify
- **Status**: OK                       <!-- OK | REGRESSIONS | RUN_FAILED | COMMAND_NOT_FOUND -->
- **Framework**: Maven
- **Command**: `mvn test -q`
- **Comparison status**: exact         <!-- exact | best-effort | invalid -->
- **Total**: 45 | **Passing**: 45 | **Failing**: 2 | **Skipped**: 0
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

### Current passing tests
com.example.BarTest#testLogin
```

**status values (the authoritative field callers branch on):**
- `OK` — all previously-green tests still green
- `REGRESSIONS` — one or more baseline tests now fail, or are missing from
  the run entirely; see the `### Regressions` / `### Missing from run` lists
- `RUN_FAILED` — test command exited with error, produced no parseable
  output, or the framework changed since baseline (**Comparison status**:
  `invalid`) so no comparison was possible
- `COMMAND_NOT_FOUND` — schema parity with capture mode; not emitted by the
  current detection logic once a verify call reaches the run step

**Note:** `passing_count` / `regressions` / `new_passes` as bare YAML keys
are a caller-side re-keying convenience, not literal fields this agent
emits — see the field mapping above and each consumer's own handoff doc
for the exact keys it expects back from the *orchestrator* (not from this
agent directly).
