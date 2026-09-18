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
   | `package.json` | Jest/npm | `scripts.test` is present and is not the `npm init` placeholder (`no test specified`), or a `workspaces` field is present and some workspace's own `package.json` has one | `CI=true npm test`; with a `workspaces` field, `CI=true npm test --workspaces --if-present` |
   | `pyproject.toml`, `setup.py`, or `pytest.ini` | pytest | always | `pytest -v` |
   | `Makefile` | Make | a `test` target exists | `CI=true make test` |

   **A JavaScript suite must be told not to watch, which is what the `CI=true` prefix is for.** `npm test` runs whatever `scripts.test` holds, and several runners watch for file changes by default outside CI: a watcher never returns, the per-suite bound truncates it, and a suite that was fine gets recorded as a failed run. `CI=true` is the one lever that is not a guess about which runner the script names — Vitest and `react-scripts` each document it as putting the run into non-interactive single-run mode. **It does not reach every watcher: the carve-out below names two runners it misses** — Karma and `ng test`. Either can be named by `scripts.test` itself or reached one level down through another npm script; Karma can additionally sit inside a `grunt` / `gulp` task, which is the third shape and the one the carve-out can only sometimes rebuild into a command of its own.

   **It is not inert for every runner that already runs once, and it is kept anyway — but what each effect does to a comparison depends on whether the runner fails a *test* or the *run*, so state it per runner rather than as one symmetry, and expect a runner it leaves alone entirely.** Both of those classes are symmetric in the sense that matters — capture and verify run under the same prefix, so nothing that was already true of the repository is read as this change's doing — and they surface in different places.

   Jest reads it as `--ci`, which is *"on by default in most popular CI environments"* and under which a snapshot with no committed file fails **the test**. A test is an identifier, so a stale committed snapshot fails at both ends and sits in the baseline's own `### Pre-existing failures`, never read as a regression, while one the run itself writes between the two calls fails at verify alone, as a **New failure** — a list the caller reads separately from the `Status` (verify step 6).

   The config `npm init playwright` writes takes `forbidOnly`, `retries` and `workers` from it, and that `only` guard fails the **run**, not a test — Playwright's own reference: *"Exits with an error if any tests or groups are marked with `test.only`"* — so no counts are produced and no identifier exists to list. A committed `.only` therefore aborts that suite at both ends: step 2 records it as a failed run, the baseline row reads `RUN_FAILED`, and verify step 6 settles it by its own ladder (`PARTIAL` where another suite produced counts, `RUN_FAILED` where none did). An `.only` the run leaves in aborts a suite the baseline recorded `OK`, so every baseline passing test of it — on a suite that was green, all of them — becomes **Missing from run** ⇒ `REGRESSIONS` (steps 3 and 6). It is not silent and it is not charged to the wrong run; which list it lands in is the runner's doing, not this prefix's. Playwright's built-in reporter default also becomes `dot` rather than `list` (`defaultReporter = process.env.CI ? 'dot' : 'list'`, and both print the `X passed` line step 3's table reads).

   **Mocha is in neither class, and its own documentation says otherwise.** Mocha's release notes and CLI page both state that `--forbid-only` defaults to true in CI from v12; **the shipped package does not implement it.** Measured on 12.0.0, 12.0.1 and 12.0.2, each with a committed `it.only` under `CI=true npm test`: all three exit 0 and print their counts, while `--forbid-only` passed explicitly aborts with `ERR_MOCHA_FORBIDDEN_EXCLUSIVITY` and exit 1. The package reads `process.env.CI` in exactly one place — `lib/utils.cjs`'s `isCI()` — whose one consumer appends *"(default in CI, …)"* to that error's **message**, after `forbidOnly` is already true; no rc file and no CLI default sets it. So nothing Mocha itself does changes under the prefix, and none of the tracing above is charged to it: a committed `.only` narrows what that suite reports identically at both ends and therefore moves nothing, while one the run leaves in is still caught — not as an aborted suite, but as every other baseline passing test turning up **Missing from run** (step 5's table), reaching the same `REGRESSIONS` by the ordinary route. **Take that as the standing rule for every runner named in this step, not merely in this paragraph: check the runner, not its documentation.** It is scoped that way on purpose — the doc-sourced assertions it exists to police are the *preceding* paragraph's, where Vitest and `react-scripts` are read out of what they document rather than out of what they do.

   Dropping the prefix costs a hang, which loses a whole suite; a per-runner flag costs the guess this prefix exists to avoid.

   **The watch carve-out — two runners the prefix does not reach, each told not to watch by its own flag.** The test is the script this command actually runs — the root `scripts.test`, or, under a `workspaces` field, each workspace's own, since `--workspaces` runs those and not the root's — and the command is issued from the directory that script belongs to:

   - **`karma start` without `--single-run`.** Karma invoked directly reads no `CI`. That script's suite is commanded `npx karma start <the script's own arguments> --single-run`.
   - **`ng test` without a `--watch` flag.** Measured against the builders `ng new` actually writes, because the CLI's documentation is not evidence about them: Angular 19 writes `@angular-devkit/build-angular:karma` and Angular 20 writes `@angular/build:karma`, and **neither derives its watch mode from `CI` at all** — each package's only `CI` reads are a build-cache toggle and a TTY helper the karma builders never consult. The 19 builder leaves Karma's `singleRun` **undefined** unless `--watch` was passed, so Karma's own `singleRun: false` default applies; the 20 builder defaults its `watch` option to `true` outright. (`@angular/build:unit-test` is the one Angular builder that derives `watch` from a TTY-and-`CI` test, and it is what neither `ng new` writes — so a project on it needs no carve-out and is unharmed by one, since `--watch=false` is what the flag would have resolved to anyway.) That script's suite is commanded `npx ng test <that invocation's own arguments> --watch=false`, an option all three of those builders' schemas declare — **rebuilt from the invocation, as the `karma` bullet rebuilds its own, and never appended to the script's text**: an append lands on the last segment, so `"test": "ng test && ng e2e"` would hand `--watch=false` to `ng e2e`, and what that does is the e2e builder's business rather than this row's. It is not reliably an error: `@cypress/schematic` 6.0.0, whose own `ng add` installs an `e2e` target, **declares** the option (`src/builders/cypress/schema.json`: `"watch": {"type": "boolean", …, "default": false}`) and its own `ng add` writes the `e2e` target with `watch: true` (`src/schematics/ng-add/index.js`), so there the flag is accepted and the append runs a whole e2e suite against a dev server under a row whose output is a unit-test count. Accepted-and-wrong is worse than rejected, which makes the rebuild more necessary than an unqualified "no schema declares it" would have. What a rebuild drops is a compound script's non-test segments — `"test": "ng lint && ng test"` no longer lints here — which is what the `karma` bullet has always done and is right for a row whose output is a test count; `/implement`, for one, runs its own lint and build in a step of its own. A browser-driven `ng test` still needs a browser; that is its own problem and not this flag's.

   **Where that script names neither runner directly, follow it one level and apply the two tests above to what you find**, as each bullet below refines them for its own shape — the same rung the `Make` wrapper rule below already carries, for the same reason, and npm-script indirection is at least as common as Make indirection. **Two shapes resolve, and nothing else does:**

   - **`npm run <name>` / `yarn <name>` / `pnpm run <name>`** → that name's own entry in the same `package.json`. `"test": "npm run test:unit"` over `"test:unit": "ng test"` is the second bullet's case, and the command is rebuilt from the **inner** script. Passing the flag through the outer one instead does nothing at all — measured: `npm test -- --watch=false` over that pair reached the inner command with `argv` identical to a bare `npm test`, npm having taken the flag as its own option at the second hop, while the same flag on `npm run test:unit` arrived.
   - **`grunt <task>` / `gulp <task>`** → that task in the repository's own `Gruntfile.js` / `gulpfile.js`. This is the AngularJS shape, and it is the first bullet's case with the invocation moved inside the task — but **what decides is the task's own resolved Karma options, and a configuration file is at most one input to them**, because both tools hand those options to Karma as a CLI-level override *on top of* whatever `configFile` they name. For `grunt` that object is `karma.options` merged with the target's own data, **the target winning** — `grunt-karma` 4.0.2's `_.merge(opts, this.data)`, whose own comment reads *"Merge options onto data, with data taking precedence"*, passed on as `parseConfig(data.configFile, data, …)`; for `gulp` it is the `Server` options object, reaching the same parser the same way. So the test is **that merged object's `singleRun` where it declares one, and the named configuration file's own only where it does not** — absent at both levels watches, since Karma's own default is `false`. Measured on `grunt-karma` 4.0.2 over Karma 6.4.4 with the browser held identical across every arm: a target declaring `singleRun: true` over a file declaring `false` returned in **1s**, while the inverse — file `true`, target `false` — **never returned** and was killed at **90s**; a `gulp` `Server` given `singleRun: true` over that same false-declaring file returned in **1s**. Reading the file alone is wrong in both directions — it fires on the first, which already runs once, and misses the second, which hangs.

     **Where that merged object's `singleRun` is absent or `false`, the carve-out fires only where the invocation is exactly a pointer at a configuration file** — a `configFile`, and nothing else beyond the watch pair (`singleRun` / `autoWatch`) that the replacement command overrides anyway. Then the suite is commanded `npx karma start <that configuration file> --single-run`, which is the first bullet's command with the task's own config file as its argument. Measured on that shape: `CI=true npm test` over `"test": "grunt test"` and over `"test": "gulp test"` ran to the kill at **90s** and **75s** against a config declaring `singleRun: false`, while the replacement command returned in **1s** against that same unmodified config — so what hangs is the watch setting and not the environment, and `CI=true` was in both arms.

     **Every other shape reports and does not fire, and the two below are ordinary configurations rather than exotic ones.** A task carrying any further Karma option beside `configFile` — `files` and `reporters` among them — would lose every one of them to the rebuild, and the test is that there is another option at all rather than a list of which ones matter, because a list is something to get wrong: measured on a target adding one spec glob and `reporters: ['dots']`, what `grunt` hands Karma resolves to three file patterns and `dots` where `npx karma start <that file> --single-run` resolves **two** and `progress` — a different suite's number, which is the wrong-number-rather-than-a-missing-one error this step opens by naming as the worse of the two. And a task naming **no `configFile` at all** — which `grunt-karma`'s own README calls the recommended configuration, *"You can either put your config in a [karma config file] or leave it all in your Gruntfile (recommended)"* — leaves nothing to hand `karma start`: measured, that shape ran to the **90s** kill under `CI=true npm test`, and `npx karma start --single-run` beside it found no configuration file, started a server with no files and no browser, and ran to its own **60s** kill. Neither of these is the excluded computed-path case below; both resolve perfectly well and simply cannot be rebuilt into one equivalent command.

   **One level, and only those two shapes.** A second level is not followed, and neither is any other indirection: a script that delegates again, a wrapper taking script names (`run-s`, `npm-run-all`), a shell script, or a task whose `configFile` is **assembled at run time** — out of a variable, a glob, or a call whose arguments are not all written out. `path.resolve(__dirname, '<literal>')` is **not** that, and the distinction is load-bearing rather than pedantic: every part of it is written out, it names exactly one file, and it is the standard `gulp` form the measurements above were taken on — an exclusion broad enough to swallow it would leave this rule refusing to fire on the very shape it cites as its evidence.

   **Wherever the carve-out does not fire on a script that does reach one of the two runners, that is reported rather than passed over** — a level or a configuration path that did not resolve, and equally the two resolved shapes above that cannot be rebuilt. The suite runs the table's own `CI=true npm test`, and `### Notes` names the script, what in it could not be resolved or could not be rebuilt, and that the suite may therefore run to the per-suite bound — the same section the `Make` rule below names an indirection one level did not settle in, though what is named there is a different fact. A carve-out that silently fails to fire is indistinguishable from a suite that genuinely failed: the per-suite bound truncates the watcher, the row reads `RUN_FAILED`, and nothing in the return says the runner was never reached.

   Whichever arm fired — and equally where none did, which the paragraph above makes a reachable outcome rather than an error — any other workspaces run through `CI=true npm test --if-present` with a `--workspace <name>` for each, so no workspace runs twice.

   No other row's command watches — `./mvnw test`, `./gradlew test`, `bin/rspec`, `bin/rails test`, `swift test`, `xcodebuild test`, `go test`, `cargo test` and `pytest` each run once and exit. **The wrapper rule below settles *parsing*, not watching**, so `make test` does not escape this paragraph — and it does not escape it conditionally either: the `Make` row's own command in the table above **is** `CI=true make test`, whether that rule folds another candidate into it, leaves both running, or finds no runner in the recipe at all, since a recipe inherits the environment it was invoked with and hands it to every process it starts, however many levels down the runner sits. Carrying it unconditionally is the cheaper error of the two: the alternative — carrying it only where the fold happened — leaves the unfolded branch, a recipe that reaches a JS runner without naming one, starting a watcher under a bare `make test`, which the per-suite bound then truncates into a lost suite; whereas a `CI` a recipe's runner does not read costs nothing, and one it does read gets the same `CI` every other JavaScript row in this table already carries — whose effects are the per-runner ones stated above, symmetric across capture and verify, rather than the blanket non-interactivity it would be convenient to claim. **Two residuals it does create, stated rather than assumed.** `make` imports the environment into its own variable namespace — measured on GNU Make 4.3, where `CI=true make test` takes the `ifdef CI` branch a bare `make test` does not — so a recipe carrying an `ifdef CI` / `ifeq ($(CI),true)` can select a different command, commonly a quieter or machine-readable reporter whose output the `Make` parse row may not recognise at all; that is symmetric, so it manufactures no regression, but the suite's counts can be silently lost, which is the harm this paragraph is otherwise avoiding. And a `test` recipe that also runs a **non-test** step whose tool reads `CI` can fail where it passed. Where the watch carve-out above replaced that row's command, the carve-out's command is the suite's and `make test` is not its entry point.

   Two rules resolve the candidate set, and neither drops a suite:
   - **`Make` is a wrapper, not a rival.** A `Make` candidate whose `test` recipe invokes another candidate's runner is not a suite of its own: that candidate runs through `make test`, the project's own pinned entry point — in the table's own form, `CI=true make test` — and is parsed with its own framework's row. Where the recipe invokes more than one candidate's runner, those candidates are **one** suite — `make test` runs once and its output is parsed with each of their rows. **Where the recipe names no runner directly, follow it one level** — the script it executes, or the `$(MAKE) -C <dir> <target>` it delegates to — and apply the same test to what you find; an indirection left unresolved is the case where the same tests run twice and are summed twice, which is the wrong number this step exists to prevent. Where one level does not settle it, both run and `### Notes` names the pair as possibly covering the same tests. Where the recipe's own flags suppress test names, the passing list may be empty and the verify diff falls back to counts.
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

### Notes
[one per line: anything step 1 or step 3 was told to name here — a watch carve-out that did not fire and what in the script could not be resolved or rebuilt, a `Make` indirection one level did not settle, "no runner found", a parser that recognised no count pattern — or "none"]

### Suites
[one line per DETECTED suite, in run order, whether or not it ran:
`<Framework> | <the marker that qualified it> | `<command>` | <OK | RUN_FAILED | NO_TESTS | not run> | Total [n], Passing [n], Failing [n], Skipped [n]`
— or "none detected"]
```

**Total** / **Passing** / **Failing** / **Skipped** are the sums across every suite that ran, and the two lists their union, prefixed per step 3. `### Suites` is always present, single-suite runs included: it is how a caller learns what else it could have run, what this baseline does and does not cover, and the set a `command_hint` narrows from. **`### Notes` is always present too, reading "none" where there is nothing to say.** It is where every rule above that says "name it in the notes" lands, and it is not decoration: the states it carries — a carve-out that did not fire, a wrapper that may double-count, a recipe whose output no parse pattern matched — are each indistinguishable, from the `Status` and `### Suites` alone, from a suite that genuinely failed. A rule that reports into a section the structure does not define is a rule that cannot be followed, since step 5 admits nothing else.

---

## Mode: verify

Re-run every suite and diff against a previously captured baseline. Use this **after** making changes to detect regressions.

### Inputs

The caller must provide:
- The full baseline block from a prior `capture` run (the `## Test Baseline` markdown block)
- The project root path

### Steps

1. **Detect every suite** — Same detection logic as capture mode, `command_hint` included. Where **no candidate matched and no `command_hint` supplied one** — capture step 4's own test for this state, word for word, because a hint that matches no detected suite is a suite of its own (step 1's Scope paragraph) and so is something to run rather than nothing — run nothing and return the step-7 structure with `Status: COMMAND_NOT_FOUND`, `Comparison status: invalid` and every count 0.

2. **Pair each detected suite with the baseline** — match on framework, against the baseline's `### Suites` rows:
   - **matched** — compared normally in step 5. A differing **command** is a `### Notes` line, not a refusal: the identifiers still come from the same runner, so they remain comparable.
   - **new since the baseline** — detected now, named nowhere in the baseline. Run it. It has no baseline, so nothing in it can be a regression and a failure in it is a **New failure**; `### Notes` records that it is new. This is the ordinary result when the run's own `test-writer` created the repository's first suite of that kind, so it is never a reason to refuse the comparison.
   - **gone since the baseline** — in the baseline, not detected now. Whatever baseline tests it holds fall out of step 5 as **Missing from run**, which is already regression-severity; a row the baseline marked `RUN_FAILED`, `not run` or `NO_TESTS` holds none, so nothing falls out and the status comes from the other suites, exactly as in step 3. `### Notes` records that the suite is gone either way.
   - **left out by this call's `command_hint`** — where the baseline's own row for it reads `not run` as well, it has no baseline tests and contributes `PARTIAL`. Where the baseline **ran** it, the hint has narrowed the scope between the two calls: that is not like-for-like, so its baseline tests are **Missing from run** and `### Notes` says the hint narrowed the run.

   Only where **no** detected suite matches any baseline suite is there nothing to compare. Then run nothing and return the step-7 structure with `Status: RUN_FAILED`, every count 0, and:
   ```
   Comparison status: invalid
   Reason: no detected suite matches the baseline — [baseline frameworks] became [current frameworks]. Manual comparison required.
   ```
   A baseline reading `Framework: not detected` names no suite at all, so nothing can pair with it and every verify call against it returns `invalid`. That baseline is what a `command_hint` on the **capture** call can prevent; a hint supplied here for the first time cannot repair it.

3. **Run** — Execute each matched or new suite's command, under the same **per-suite** 10-minute bound as capture and in the same run order. Capture stdout and stderr combined per suite. If any suite aborts (non-zero exit, truncated output, or unrecognized runner output), set `Comparison status: best-effort`, record it in `### Suites` and `### Notes`, and still run the rest. **What that abort means is settled by the suite's own baseline row.** `OK` — it ran and produced tests before this change and does not now, so every baseline **passing** test of it falls out of step 5 as **Missing from run**; where it contributed any, the run is a regression and the change is the only thing that moved, and where it contributed none (a suite whose every test was already failing) nothing falls out, which is the third abort step 6's `OK` names. `RUN_FAILED` or `not run` — it could not run at either end, so it contributed no baseline tests, nothing falls out, and step 6 settles the status by its own first-that-applies ladder: `PARTIAL` where some suite produced counts, `RUN_FAILED` where none did. Either way it is a fact about the environment, never evidence about the change. `NO_TESTS`, **or no baseline row at all** (a suite new since the baseline, step 2) — it holds no baseline test that could go missing, so there is nothing to lose either way; record the abort and let the rest of the run settle the status, which step 6's `OK` and `RUN_FAILED` each say how.

4. **Parse** — Same patterns as capture mode.

5. **Diff against baseline** — Compare using the test identifiers from the baseline's `### Passing tests` list:

   | Category | Definition |
   |----------|-----------|
   | **Regressions** | Was in baseline `### Passing tests` AND is now failing |
   | **Missing from run** | Was in baseline `### Passing tests` AND is not present in the current run at all (treat as regression-severity — test may have been silently dropped or suite aborted early) |
   | **Newly fixed** | Was in baseline `### Pre-existing failures` AND is now passing |
   | **New failures** | Is failing now AND was not in baseline `### Pre-existing failures` AND was not in baseline `### Passing tests` (new test added and already failing) |

6. **Compute Status** — before returning, set the first that applies:
   - `REGRESSIONS` — **Regressions** count > 0 OR **Missing from run** count > 0 (both are regression-severity per the table above). This is where a suite the baseline recorded `OK` **with at least one passing test** and that aborted here lands, since those tests are then unaccounted for. **It is tested first**, so a run in which every suite aborted is a regression where the baseline had run them, rather than being written off as a run that did not happen
   - `RUN_FAILED` — no suite produced counts in this run at all, so nothing was verified. Reached only where the baseline held **no passing test that could go missing**: any suite it recorded `OK` with passing tests would have put them into **Missing from run** above, so what is left here is a baseline of rows reading `RUN_FAILED`, `not run` or `NO_TESTS`, rows recorded `OK` that contributed no passing test, and suites that had no row at all
   - `PARTIAL` — some suite produced counts, and at least one produced none here **and no counts in the baseline either** — its baseline row reads `RUN_FAILED` or `not run`, so it aborted at both ends or the `command_hint` left it out at both. The comparison is sound as far as it reaches and says nothing at all about that suite
   - `OK` — otherwise: the comparison was possible and found no regressions. **The aborts this value tolerates are the ones that could lose no baseline *passing* test** — a suite whose baseline row is `NO_TESTS`, one with no row at all, and one whose baseline row is `OK` but whose contribution to `### Passing tests` was empty because its every test was already failing — each recorded by step 3 in `### Notes` and `### Suites`, and each moving nothing here; every abort that did lose a baseline passing test has already been taken by a value above

   Steps 1 and 2 return before this one — `COMMAND_NOT_FOUND` where no candidate matched and no `command_hint` supplied one, `RUN_FAILED` where nothing pairs with the baseline — so neither is computed here.

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
[any parser confidence issues, aborted runs, suite pairing facts from step 2, anything step 1's detection was told to name here (it is capture step 1's detection, so its notes are owed here too), or "none"]

### Suites
[same shape as capture mode — one line per detected suite, in run order, whether or not it ran]

### Current passing tests
[one test identifier per line — for chaining further verify calls against the same original baseline]
```

