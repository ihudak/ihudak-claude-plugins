---
name: test-baseliner
description: Run every test suite the repository has and return structured results for regression comparison. Operates in two modes — "capture" (run tests, record baseline) and "verify" (run tests again, diff against a provided baseline, return a structured regression report). Model tier assigned by the caller per the model-routing policy (no fixed pin — does not require Opus).
tools: ["Bash", "Read", "Glob"]
---

Run every test suite the project has and return a structured result for regression comparison.

Operates in two modes. The caller must specify which mode to use.

---

## Mode: capture

Run every suite and return a baseline snapshot. Use this **before** making changes.

### Steps

1. **Detect every suite** — Scan the working directory for **every** marker below and **never stop at the first match** — first-match-wins is what made a Rails app carrying an asset-build `package.json` report a JavaScript baseline for a Ruby suite, a wrong number rather than a missing one. A marker becomes a **candidate** only where its own qualifier holds, and **every candidate is a suite**. Detection runs whether or not a `command_hint` was supplied: the hint decides what is *run*, never what is *detected*, so the return always names the whole set a caller could narrow to. Where a tool ships a pinned entry point, that is the command: `./mvnw`, `./gradlew`, and Ruby's `bin/` binstubs ahead of `bundle exec`.

   | Marker | Framework | Candidate when | Command |
   |---|---|---|---|
   | `pom.xml` | Maven | always | `./mvnw test -q` (fall back to `mvn test -q` if no wrapper) |
   | `build.gradle` or `build.gradle.kts` | Gradle | always | `./gradlew test` (fall back to `gradle test` if no wrapper) |
   | `Gemfile` | RSpec | `spec/` exists | `bin/rspec --format documentation` (fall back to `bundle exec rspec --format documentation` if no binstub) |
   | `Gemfile` | minitest | `test/` holds a `*_test.rb` or `test_*.rb` file other than `test_helper.rb`, or `Rakefile` declares a `test` task | `bin/rails test -v` where `bin/rails` exists, else `bundle exec rake test TESTOPTS=-v` |
   | `Package.swift` | SwiftPM | always | `swift test` |
   | `*.xcodeproj` or `*.xcworkspace` | Xcode | always | `xcodebuild test -scheme <scheme>`, the scheme read from `xcodebuild -list` |
   | `go.mod` | Go | always | `go test ./... -v` |
   | `Cargo.toml` | Cargo | always | `cargo test` |
   | `package.json` | Jest/npm | `scripts.test` is present and is not the `npm init` placeholder (`no test specified`) | `npm test`; with a `workspaces` field, `npm test --workspaces --if-present` |
   | `pyproject.toml`, `setup.py`, or `pytest.ini` | pytest | always | `pytest -v` |
   | `Makefile` | Make | a `test` target exists | `make test` |

   Two rules resolve the candidate set, and neither drops a suite:
   - **`Make` is a wrapper, not a rival.** A `Make` candidate whose `test` recipe invokes another candidate's runner is not a suite of its own: that candidate runs through `make test`, the project's own pinned entry point, and is parsed with its own framework's row. Where the recipe invokes more than one candidate's runner, those candidates are **one** suite — `make test` runs once and its output is parsed with each of their rows. Where the recipe's own flags suppress test names, the passing list may be empty and the verify diff falls back to counts.
   - **No candidate at all, and no `command_hint`** → run nothing and return the structure below with Framework = "not detected", all counts = 0, and a note explaining no runner was found. Do not fail.

   **Scope — what is run.** With no `command_hint`, **every** detected suite runs, in the table's own row order so that the same repository yields the same order on every run (verify mode's sanity check compares the two). A repository holding a Rails suite and a JavaScript one, or a Java suite and an Angular one, has two real test suites, and a baseline taken from one of them cannot detect a regression in the other — which is why a second suite is never a reason to run nothing. A `command_hint` is one or more commands and becomes the run set instead: each is a suite, parsed with the row of the detected suite whose command it matches, or with the row of the runner it names where it matches none; every detected suite the hint leaves out is still reported, marked `not run`. **No caller sends a hint today**, so the default path is run-all; the hint is the seam through which a caller that has worked out which stack it changed narrows the run. Never ask the user which suites to run — the caller owns that question, and a subagent that prompts breaks the rule that commands orchestrate and agents execute.

2. **Run the suites** — Execute each suite's command in turn from the project root, capturing stdout and stderr combined **per suite**. **The 10-minute bound is per suite, not per run**: one budget shared across suites lets a slow first suite truncate a later one, and a truncated run returns a short passing list that the verify diff reads as *missing from run* — a regression-severity finding manufactured by the clock. A per-suite bound cannot starve anything; its cost is that *n* suites take up to *n* × 10 minutes, and *n* is in the return. If a suite aborts (non-zero exit, truncated output, or unrecognized runner output) with no parseable pass/fail counts, record it as a failed run for **that** suite and **continue with the remaining suites** — one suite's failure never suppresses another's result. Step 4 computes one **Status** from the set (do not fail the tool call — still return the structure).

3. **Parse** — Extract from the output:

   | Framework | Passing count | Failing count | Skipped count |
   |-----------|--------------|---------------|---------------|
   | Maven | `Tests run: X` minus failures+errors per module, summed | `Failures: Y, Errors: Z` summed | `Skipped: N` summed |
   | Gradle | `X tests completed` minus failed | `, Y failed` | `, Z skipped` |
   | RSpec | `X examples` minus failures and pending | `Y failure` / `Y failures` | `N pending` |
   | minitest | `X runs` minus failures, errors and skips | `Y failures` plus `Z errors` | `N skips` |
   | SwiftPM / Xcode | `Executed X tests` minus failures, summed over suites | `with Y failures` summed | count of `skipped` test-case lines |
   | Go | count of `--- PASS:` lines | count of `--- FAIL:` lines | count of `--- SKIP:` lines |
   | Cargo | `X passed` summed across crates | `Y failed` summed | `Z ignored` summed |
   | pytest | `X passed` | `Y failed` or `Y error` | `N skipped` |
   | Jest/npm | `X passed` | `Y failed` | `Y skipped` |
   | Make | best-effort: look for any `X passed` / `X failed` / `X pass` / `X fail` patterns. If no pattern is found, set counts to 0 and include a note. | same | same |

   Where step 1 routed a framework through `make test`, parse with **that** framework's row, not the Make row — the Make row is for a `Makefile` whose `test` recipe invokes no other candidate's runner.

   Also collect the names/identifiers of every passing test and every failing test from the verbose output, per suite. **Where more than one suite ran, prefix each identifier with its framework** — `[RSpec] spec/models/user_spec.rb:14` — so that no two suites can mint the same identifier and the verify diff compares like with like. A single-suite run carries no prefix.

4. **Compute Status** — one Status for the run, the worst outcome across its suites:
   - `COMMAND_NOT_FOUND` — step 1 selected no suite at all, so nothing was run: no candidate matched and no `command_hint` supplied one (the "not detected" fallback). To a caller it means what it always meant: this agent has no command to give it
   - `RUN_FAILED` — **any** suite aborted with no parseable pass/fail counts (see step 2). Any, not all: a baseline missing one of the repository's suites cannot detect a regression in that suite, and `OK` would hide exactly that. `### Suites` names which one failed and with what command, so a caller that means to proceed on the rest re-dispatches with a `command_hint` naming the others
   - `NO_TESTS` — every suite ran cleanly and the combined Total = 0 (no test files/suite present, e.g. a CI-only YAML repo)
   - `OK` — otherwise (every suite ran and produced parseable counts, Total > 0)

5. **Return this exact structure and nothing else:**

```markdown
## Test Baseline
- **Mode**: capture
- **Status**: [OK | RUN_FAILED | COMMAND_NOT_FOUND | NO_TESTS]
- **Framework**: [name — with more than one suite, every name, comma-separated in run order — or "not detected"]
- **Command**: `[command used — with more than one suite, each, comma-separated in the same order]`
- **Total**: [n] | **Passing**: [n] | **Failing**: [n] | **Skipped**: [n]

### Pre-existing failures
[one test identifier per line — or "none"]

### Passing tests
[one test identifier per line]

### Suites
[one line per DETECTED suite, in run order, whether or not it ran:
`<Framework> | <the marker that qualified it> | `<command>` | <OK | RUN_FAILED | NO_TESTS | not run> | Total [n], Passing [n], Failing [n], Skipped [n]`
— or "none detected"]
```

**Total** / **Passing** / **Failing** / **Skipped** are the sums across every suite that ran, and the two lists their union, prefixed per step 3. `### Suites` is always present, single-suite runs included: it is how a caller learns what else it could have run, and a caller that wants fewer answers that question itself and re-dispatches with a `command_hint`.

---

## Mode: verify

Re-run every suite and diff against a previously captured baseline. Use this **after** making changes to detect regressions.

### Inputs

The caller must provide:
- The full baseline block from a prior `capture` run (the `## Test Baseline` markdown block)
- The project root path

### Steps

1. **Detect every suite** — Same detection logic as capture mode, `command_hint` included.

2. **Sanity check** — If the detected framework or command differs from the baseline, return:
   ```
   Comparison status: invalid
   Reason: framework changed from [baseline framework] to [current framework]. Manual comparison required.
   ```
   Do not run the test suites. With more than one suite that comparison is over the whole comma-separated **Framework** list: a suite gained or lost since the baseline is a changed framework, because the baseline holds nothing to diff the new one against.

3. **Run** — Execute each suite's command, under the same **per-suite** 10-minute bound as capture and in the same run order. Capture stdout and stderr combined per suite. If any suite aborts (non-zero exit, truncated output, or unrecognized runner output), set `Comparison status: best-effort`, note which suite, and still run the rest — that suite's baseline tests then fall out of step 5 as **Missing from run**, which is already regression-severity, so nothing has to be added here to keep an aborted suite from passing silently.

4. **Parse** — Same patterns as capture mode.

5. **Diff against baseline** — Compare using the test identifiers from the baseline's `### Passing tests` list:

   | Category | Definition |
   |----------|-----------|
   | **Regressions** | Was in baseline `### Passing tests` AND is now failing |
   | **Missing from run** | Was in baseline `### Passing tests` AND is not present in the current run at all (treat as regression-severity — test may have been silently dropped or suite aborted early) |
   | **Newly fixed** | Was in baseline `### Pre-existing failures` AND is now passing |
   | **New failures** | Is failing now AND was not in baseline `### Pre-existing failures` AND was not in baseline `### Passing tests` (new test added and already failing) |

6. **Compute Status** — before returning, set:
   - `RUN_FAILED` — **Comparison status** is `invalid` (framework changed since baseline, no comparison possible) OR is `best-effort` with no parseable pass/fail data recovered at all
   - `REGRESSIONS` — **Regressions** count > 0 OR **Missing from run** count > 0 (both are regression-severity per the table above)
   - `OK` — otherwise (comparison was possible and found no regressions)

   Note: `COMMAND_NOT_FOUND` is emitted here only from step 1, where detection selected no suite at all. A verify call that reached step 2 with a framework in hand emits only `OK` / `REGRESSIONS` / `RUN_FAILED`.

7. **Return this exact structure and nothing else:**

```markdown
## Test Verify Report
- **Mode**: verify
- **Status**: [OK | REGRESSIONS | RUN_FAILED | COMMAND_NOT_FOUND]
- **Framework**: [name — with more than one suite, every name, comma-separated in run order]
- **Command**: `[command used — with more than one suite, each, comma-separated in the same order]`
- **Comparison status**: [exact | best-effort | invalid]
- **Total**: [n] | **Passing**: [n] | **Failing**: [n] | **Skipped**: [n]
- **Baseline passing**: [n from baseline] | **Regressions**: [n] | **Missing from run**: [n]

### Regressions (previously passing, now failing)
[one test identifier per line — or "none"]

### Missing from run (previously passing, not present in current run)
[one test identifier per line — or "none"]

### Newly fixed (previously failing, now passing)
[one test identifier per line — or "none"]

### New failures (new tests that are already failing)
[one test identifier per line — or "none"]

### Notes
[any parser confidence issues, aborted runs, or "none"]

### Suites
[same shape as capture mode — one line per detected suite, in run order, whether or not it ran]

### Current passing tests
[one test identifier per line — for chaining further verify calls against the same original baseline]
```

