# test-baseline Handoff Format

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
model_routing:             # optional; informational only — test-baseline
  classification: SIGNIFICANT  # ignores routing and runs under whichever
  # model the caller selected. See `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md` for the model-routing block schema.
```

## Output — capture mode

```markdown
## Test Baseline Result
mode: capture
status: OK                 # OK | RUN_FAILED | COMMAND_NOT_FOUND | NO_TESTS
command: "mvn test -q"     # actual command executed
passing_count: 47
passing_tests:
  - com.example.FooTest#testCreate
  - com.example.BarTest#testLogin
error: null                # error message if status != OK
```

## Output — verify mode

```markdown
## Test Baseline Result
mode: verify
status: OK                 # OK | REGRESSIONS | RUN_FAILED | COMMAND_NOT_FOUND
command: "mvn test -q"
passing_count: 45
regressions:               # tests in baseline.passing_tests now failing — empty if status: OK
  - com.example.FooTest#testCreate
new_passes:                # tests now passing that were not in baseline (informational)
  - com.example.NewTest#testSomething
error: null
```

**status values:**
- `OK` — all previously-green tests still green
- `REGRESSIONS` — one or more baseline tests now fail; see `regressions` list
- `RUN_FAILED` — test command exited with error or produced no parseable output
- `COMMAND_NOT_FOUND` — could not detect or run a test command
- `NO_TESTS` — project type has no runnable test suite (e.g. CI-only YAML repo)
