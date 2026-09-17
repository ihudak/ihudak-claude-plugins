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

1. **Detect every suite** — Scan the working directory for **every** marker below and **never stop at the first match** — first-match-wins is what made a Rails app carrying an asset-build `package.json` report a JavaScript baseline for a Ruby suite, a wrong number rather than a missing one. A marker becomes a **candidate** only where its own qualifier holds, and a **row** is one candidate however many of its markers are present — three Python markers in one repository are one pytest suite, not three. Every candidate is a suite except where the wrapper rule below folds one into another. Detection runs whether or not a `command_hint` was supplied: the hint decides what is *run*, never what is *detected*, so the return always names the whole set a caller could narrow to. Where a tool ships a pinned entry point, that is the command: `./mvnw`, `./gradlew`, and Ruby's `bin/` binstubs ahead of `bundle exec`.

   | Marker | Framework | Candidate when | Command |
   |---|---|---|---|
   | `pom.xml` | Maven | always | `./mvnw test -q` (fall back to `mvn test -q` if no wrapper) |
   | `build.gradle` or `build.gradle.kts` | Gradle | always | `./gradlew test` (fall back to `gradle test` if no wrapper) |
   | `Gemfile` | RSpec | `spec/` exists | `bin/rspec --format documentation` (fall back to `bundle exec rspec --format documentation` if no binstub) |
   | `Gemfile` | minitest | `test/` holds a `*_test.rb` or `test_*.rb` file other than `test_helper.rb`, or `Rakefile` declares a `test` task | `bin/rails test -v` where `bin/rails` exists, else `bundle exec rake test TESTOPTS=-v` |
   | `Package.swift` | SwiftPM | always | `swift test` |
   | `*.xcodeproj` or `*.xcworkspace` | Xcode | no `Package.swift` beside it — a package with a checked-in or generated project is one body of tests, and `swift test` is its pinned entry point | `xcodebuild test -scheme <scheme>`, the scheme read from `xcodebuild -list` |
   | `go.mod` | Go | always | `go test ./... -v` |
   | `Cargo.toml` | Cargo | always | `cargo test` |
   | `package.json` | Jest/npm | `scripts.test` is present and is not the `npm init` placeholder (`no test specified`) | `CI=true npm test`; with a `workspaces` field, `CI=true npm test --workspaces --if-present` |
   | `pyproject.toml`, `setup.py`, or `pytest.ini` | pytest | always | `pytest -v` |
   | `Makefile` | Make | a `test` target exists | `make test` |

   **A JavaScript suite must be told not to watch, which is what the `CI=true` prefix is for.** `npm test` runs whatever `scripts.test` holds, and several runners watch for file changes by default outside CI: a watcher never returns, the per-suite bound truncates it, and a suite that was fine gets recorded as a failed run. `CI=true` is the one lever that is not a guess about which runner the script names — Angular CLI, Vitest and `react-scripts` each document it as putting the run into non-interactive single-run mode, and `jest`, `mocha` and `playwright test` run once anyway and are unaffected by it. **Karma invoked directly reads no `CI`**: where `scripts.test` runs `karma start` without `--single-run`, this suite's command is `npx karma start <the script's own arguments> --single-run` instead of `npm test`. No other row's command watches — `./mvnw test`, `./gradlew test`, `bin/rspec`, `bin/rails test`, `swift test`, `xcodebuild test`, `go test`, `cargo test` and `pytest` each run once and exit — and `make test` runs the project's own recipe, which the wrapper rule resolves.

   Two rules resolve the candidate set, and neither drops a suite:
   - **`Make` is a wrapper, not a rival.** A `Make` candidate whose `test` recipe invokes another candidate's runner is not a suite of its own: that candidate runs through `make test`, the project's own pinned entry point, and is parsed with its own framework's row. Where the recipe invokes more than one candidate's runner, those candidates are **one** suite — `make test` runs once and its output is parsed with each of their rows. **Where the recipe names no runner directly, follow it one level** — the script it executes, or the `$(MAKE) -C <dir> <target>` it delegates to — and apply the same test to what you find; an indirection left unresolved is the case where the same tests run twice and are summed twice, which is the wrong number this step exists to prevent. Where one level does not settle it, both run and `### Notes` names the pair as possibly covering the same tests. Where the recipe's own flags suppress test names, the passing list may be empty and the verify diff falls back to counts.
   - **No candidate at all, and no `command_hint`** → run nothing and return the structure below with Framework = "not detected", all counts = 0, and a note explaining no runner was found. Do not fail.

   **Scope — what is run.** With no `command_hint`, **every** detected suite runs, in the table's own row order so that the same repository yields the same order on every run (verify mode pairs the two lists suite by suite). A repository holding a Rails suite and a JavaScript one, or a Java suite and an Angular one, has two real test suites, and a baseline taken from one of them cannot detect a regression in the other — which is why a second suite is never a reason to run nothing. A `command_hint` is one or more commands and becomes the run set instead: each is a suite, parsed with the row of the detected suite whose command it matches, or with the row of the runner it names where it matches none; every detected suite the hint leaves out is still reported, marked `not run`. **A hinted command matching no detected suite is a suite of its own** — its framework the runner its command names, or `hinted` where the command names none, and its `### Suites` marker column reads `command_hint`. A caller that sends a hint on the `capture` call sends the same hint on every `verify` call against that baseline, or the two runs have nothing to pair. Never ask the user which suites to run — the caller owns that question, and a subagent that prompts breaks the rule that commands orchestrate and agents execute.

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

4. **Compute Status** — one Status for the run, computed from its per-suite outcomes:
   - `COMMAND_NOT_FOUND` — step 1 selected no suite at all, so nothing was run: no candidate matched and no `command_hint` supplied one (the "not detected" fallback). To a caller it means what it always meant: this agent has no command to give it
   - `RUN_FAILED` — **every** suite that was run aborted with no parseable pass/fail counts (see step 2), so this baseline records nothing and a later verify has nothing to compare against
   - `PARTIAL` — at least one suite produced counts and at least one did not. The baseline covers exactly the suites `### Suites` marks `OK` or `NO_TESTS`, which is what a later verify compares against, and `### Suites` names each suite it does not cover with the command that failed. **`PARTIAL` is incompleteness, never a verdict on the code** — a caller that refuses to work on it is refusing because a runner is not installed, not because anything is wrong with what it was about to change
   - `NO_TESTS` — every suite ran cleanly and the combined Total = 0 (no test files/suite present, e.g. a CI-only YAML repo)
   - `OK` — otherwise (every suite ran and produced parseable counts, Total > 0)

5. **Return this exact structure and nothing else:**

```markdown
## Test Baseline
- **Mode**: capture
- **Status**: [OK | PARTIAL | RUN_FAILED | COMMAND_NOT_FOUND | NO_TESTS]
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

**Total** / **Passing** / **Failing** / **Skipped** are the sums across every suite that ran, and the two lists their union, prefixed per step 3. `### Suites` is always present, single-suite runs included: it is how a caller learns what else it could have run, what this baseline does and does not cover, and the set a `command_hint` narrows from.

---

## Mode: verify

Re-run every suite and diff against a previously captured baseline. Use this **after** making changes to detect regressions.

### Inputs

The caller must provide:
- The full baseline block from a prior `capture` run (the `## Test Baseline` markdown block)
- The project root path

### Steps

1. **Detect every suite** — Same detection logic as capture mode, `command_hint` included. Where detection selects no suite at all, run nothing and return the step-7 structure with `Status: COMMAND_NOT_FOUND`, `Comparison status: invalid` and every count 0.

2. **Pair each detected suite with the baseline** — match on framework, against the baseline's `### Suites` rows:
   - **matched** — compared normally in step 5. A differing **command** is a `### Notes` line, not a refusal: the identifiers still come from the same runner, so they remain comparable.
   - **new since the baseline** — detected now, named nowhere in the baseline. Run it. It has no baseline, so nothing in it can be a regression and a failure in it is a **New failure**; `### Notes` records that it is new. This is the ordinary result when the run's own `test-writer` created the repository's first suite of that kind, so it is never a reason to refuse the comparison.
   - **gone since the baseline** — in the baseline, not detected now. Its baseline tests fall out of step 5 as **Missing from run**, which is already regression-severity; `### Notes` records that the suite is gone.
   - **left out by this call's `command_hint`** — where the baseline's own row for it reads `not run` as well, it has no baseline tests and contributes `PARTIAL`. Where the baseline **ran** it, the hint has narrowed the scope between the two calls: that is not like-for-like, so its baseline tests are **Missing from run** and `### Notes` says the hint narrowed the run.

   Only where **no** detected suite matches any baseline suite is there nothing to compare. Then run nothing and return the step-7 structure with `Status: RUN_FAILED`, every count 0, and:
   ```
   Comparison status: invalid
   Reason: no detected suite matches the baseline — [baseline frameworks] became [current frameworks]. Manual comparison required.
   ```
   A baseline reading `Framework: not detected` names no suite at all, so nothing can pair with it and every verify call against it returns `invalid`. That baseline is what a `command_hint` on the **capture** call can prevent; a hint supplied here for the first time cannot repair it.

3. **Run** — Execute each matched or new suite's command, under the same **per-suite** 10-minute bound as capture and in the same run order. Capture stdout and stderr combined per suite. If any suite aborts (non-zero exit, truncated output, or unrecognized runner output), set `Comparison status: best-effort`, record it in `### Suites` and `### Notes`, and still run the rest. **What that abort means is settled by the suite's own baseline row.** `OK` — it ran and produced tests before this change and does not now, so every baseline test of it falls out of step 5 as **Missing from run** and the run is a regression; the change is the only thing that moved. `RUN_FAILED` or `not run` — it could not run at either end, so it contributed no baseline tests, nothing falls out, and step 6 reports `PARTIAL`: a fact about the environment, never evidence about the change. `NO_TESTS` — it ran clean with nothing in it, so there is nothing to lose either way; record the abort and let the other suites settle the status.

4. **Parse** — Same patterns as capture mode.

5. **Diff against baseline** — Compare using the test identifiers from the baseline's `### Passing tests` list:

   | Category | Definition |
   |----------|-----------|
   | **Regressions** | Was in baseline `### Passing tests` AND is now failing |
   | **Missing from run** | Was in baseline `### Passing tests` AND is not present in the current run at all (treat as regression-severity — test may have been silently dropped or suite aborted early) |
   | **Newly fixed** | Was in baseline `### Pre-existing failures` AND is now passing |
   | **New failures** | Is failing now AND was not in baseline `### Pre-existing failures` AND was not in baseline `### Passing tests` (new test added and already failing) |

6. **Compute Status** — before returning, set the first that applies:
   - `REGRESSIONS` — **Regressions** count > 0 OR **Missing from run** count > 0 (both are regression-severity per the table above). This is where a suite the baseline recorded `OK` and that aborted here lands, since every baseline test of it is then unaccounted for. **It is tested first**, so a run in which every suite aborted is a regression where the baseline had run them, rather than being written off as a run that did not happen
   - `RUN_FAILED` — no suite produced counts in this run at all, so nothing was verified. Reached only where the baseline covered nothing either: any suite it recorded `OK` would have put its tests into **Missing from run** above
   - `PARTIAL` — some suite produced counts, and at least one produced none here **and none in the baseline either** — it aborted at both ends, or the `command_hint` left it `not run`. The comparison is sound as far as it reaches and says nothing at all about that suite
   - `OK` — otherwise (every detected suite ran, the comparison was possible, and it found no regressions)

   Steps 1 and 2 return before this one — `COMMAND_NOT_FOUND` where detection selected no suite, `RUN_FAILED` where nothing pairs with the baseline — so neither is computed here.

   **The `Status` carries regressions; it does not carry new failures.** A test failing now that was in neither baseline list is a **New failure** by step 5's table, and no value above counts one — so `OK` and `PARTIAL` are both reachable with `### New failures` non-empty. A caller whose own run wrote tests between the capture and this call reads that list as well as the `Status`, or it reads its own broken test as a pass.

7. **Return this exact structure and nothing else:**

```markdown
## Test Verify Report
- **Mode**: verify
- **Status**: [OK | PARTIAL | REGRESSIONS | RUN_FAILED | COMMAND_NOT_FOUND]
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

