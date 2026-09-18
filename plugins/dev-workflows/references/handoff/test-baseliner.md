# test-baseliner Handoff Format

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

## Input

```markdown
## Test Baseline Request
repo: /absolute/path/to/repo   # the project root, and the scan root in BOTH modes.
                               # Callers send it under their own label — `/implement`
                               # Pre-Phase 3.5 and `/upgrade`'s batch capture each send
                               # `Project root:` — and it is this field either way.
                               # Required for `mode: verify`; on `mode: capture` a caller
                               # may omit it (`vuln-fixer` step 1 does) and the scan falls
                               # back to the working directory.
mode: capture              # capture | verify
command_hint: "./mvnw test -q"   # optional; one or more commands. Detection still runs —
                                 # the hint narrows what is RUN, never what is DETECTED.
                                 # Omitted ⇒ every detected suite runs. A hint sent on the
                                 # capture call is sent again on every verify call against
                                 # that baseline, or the two runs have nothing to pair.
                                 # A hinted command runs in the directory of the detected
                                 # suite it matches, or at the scan root (`repo:`, or the
                                 # working directory where a capture call omits it) where
                                 # it matches none — every other suite runs where capture
                                 # step 2's four sources put it, not at the scan root, and
                                 # that holds in BOTH modes (agents/test-baseliner.md
                                 # capture step 2, verify step 3).
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

### Notes
none

### Suites
Maven | pom.xml | `./mvnw test -q` | OK | Total 47, Passing 47, Failing 0, Skipped 0
```

**A repository with more than one suite baselines all of them**, which the block
above expresses without changing shape: **Framework** and **Command** become
comma-separated lists in run order — positionally paired, so a framework repeats
where the run holds more than one suite of it rather than being de-duplicated —
the counts are the sums, the two test lists are the union with each identifier
prefixed `[<Framework>] `, or `[<Framework> <marker path>] ` where that framework
names more than one **detected** suite — `### Suites`' own set, not what ran, so
a `command_hint` cannot move the prefix between a capture and its verify
(`agents/test-baseliner.md` capture step 3) — and `### Suites`
carries one line per detected suite — framework, the qualifying marker **as a
path relative to the scan root**, command, per-suite status, per-suite counts —
including any the `command_hint` left `not run`. The marker is a path rather than
a bare filename for two reasons. It tells apart two suites of one framework:
qualifying markers of one row whose directories do not contain each other are
siblings, and siblings are separate suites, so more than one row here can read
`Jest/npm` (`agents/test-baseliner.md` capture step 1). And for every suite whose
run directory is its marker's own, the path says where that row's command ran,
which is not the project root — the rule holding in **both** modes
(`agents/test-baseliner.md` capture step 2 and verify step 3, each stating it at
its own number): `pom.xml` for a suite at the scan root,
`frontend/package.json` for one below it. **Three run directories are not a
marker's own** — a suite the `Make` wrapper folded runs at the `Makefile`'s, a
workspace the watch carve-out fired on runs at that workspace's, and a hinted
command matching no suite runs at the scan root — and the first two are named in
`### Notes`, the third being what a `command_hint` marker value already says. A
single-suite repository's block is unchanged in every field, `### Suites` aside.

**`### Notes` is present on every capture return, "none" included**, and it
carries what no other field can: a suite whose watch carve-out did not fire and
why, a qualifying marker whose directory another of its own row's contains, the run directory
of a suite that did not run at its own marker's (a folded `Make` suite's
`Makefile`, a carve-out workspace's own), a `Make` wrapper one level did not
settle, "no runner found", a recipe whose output matched no parse pattern. Each
of those reads, from **Status** and
`### Suites` alone, exactly like a suite that genuinely failed — a `RUN_FAILED`
row with a command beside it — so a caller that reports a failed suite without
reading this section reports the wrong cause. Verify mode has carried the same
section since before capture did, and it is the same section: capture's detection
is what verify step 1 re-runs, so a note owed at one end is owed at both.

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
- `COMMAND_NOT_FOUND` — no candidate matched and no `command_hint` supplied one,
  so nothing ran (**Framework** then reads `not detected`)

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
- `OK` — the comparison was possible and every previously-green test is still
  green. The aborts it tolerates are the ones that could lose no baseline
  *passing* test: a suite whose baseline row is `NO_TESTS`, one with no row at
  all because the suite is new since the baseline, and one whose baseline row is
  `OK` but which contributed no passing test — each of which `### Notes` names
- `REGRESSIONS` — one or more baseline tests now fail, or are missing from the
  run entirely; see the `### Regressions` / `### Missing from run` lists. A suite
  the baseline recorded `OK` with at least one passing test and that aborts here
  lands here too, because those tests are then unaccounted for — it ran before
  this change and does not now
- `PARTIAL` — no regressions, and at least one detected suite produced no counts
  here **and no counts in the baseline either — its baseline row reads
  `RUN_FAILED` or `not run`**, so it aborted at both ends or the `command_hint`
  left it out at both. The comparison is sound as far as it reaches and says
  nothing about that suite; `### Suites` names it. A suite whose baseline row is
  `NO_TESTS`, or which has no row at all, is **not** this — that abort is `OK`'s
  above, which is where the agent's own "set the first that applies" ladder
  (verify step 6) puts it
- `RUN_FAILED` — nothing was verified: no detected suite matches the baseline
  (**Comparison status**: `invalid`), or no suite produced counts in this run at
  all. It is tested **after** `REGRESSIONS`, so a run in which every suite aborted
  is a regression where the baseline had run them, and what reaches this value is
  a baseline holding no passing test that could go missing
- `COMMAND_NOT_FOUND` — no candidate matched and no `command_hint` supplied one,
  so nothing ran (**Framework** then reads `not detected`) — the same test capture
  mode applies, a hint being something to run rather than nothing. Never emitted
  once a call reaches the run step

**What a consumer may do with each.** `REGRESSIONS` is the only value that is
evidence about the change, and the only one on which reverting it is warranted.
`PARTIAL`, `RUN_FAILED` and `COMMAND_NOT_FOUND` each say a suite could not be
run — they are facts about the environment, so a consumer records which suite and
proceeds or escalates, and **never reverts work on them**. Reverting on one of
those rolls back a correct change in one language because a runner for another
is not installed.

**`### New failures` is outside that ladder, because it is not a `Status` value
at all.** A test failing now that was in neither baseline list moves no value
above, so `OK` and `PARTIAL` are both returned with that list non-empty. A caller
that writes tests between its capture and its verify — `/implement`, through
`test-writer` — reads the list as well as the `Status`, or it reads its own
broken test as a pass; `/upgrade` and `/vuln` write none and branch on the
`Status` alone.

**Note:** `passing_count` / `regressions` / `new_passes` as bare YAML keys
are a caller-side re-keying convenience, not literal fields this agent
emits — see the field mapping above and each consumer's own handoff doc
for the exact keys it expects back from the *orchestrator* (not from this
agent directly).
