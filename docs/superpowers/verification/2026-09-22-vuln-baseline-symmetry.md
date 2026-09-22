# Verification record — `/vuln` baseline symmetry (dev-workflows 4.2.0)

Branch `iv-gu/vuln-baseline-symmetry`, four commits off `1bca72d3`. Written after the final fix wave, per this repo's rule that a verification record is written last.

## What was changed

1. `/vuln` captures its test baseline **once per run, at the orchestrator, on both classification paths**. It previously captured inside `vuln-fixer` on the `SIMPLE`/`MODERATE` path (`baseline_tests: run-fresh`) and at the orchestrator, per CVE, on the other.
2. A capture returning `RUN_FAILED` or `COMMAND_NOT_FOUND` now **asks the operator** — specify a test command / apply unverified / cancel — in `/vuln` and in `/upgrade`. Neither asked before; `/vuln` abandoned the CVE on one path and proceeded on the other.
3. `baseline_tests: run-fresh` and the `BASELINE_FAILED` status are **retired**.
4. `test-baseliner` verify **refuses a baseline that covers no suite**, before running anything.
5. `/vuln` and `/upgrade` read the verify report's `### New failures` list, marked `NEW-FAILURE: ` in `notes`, and set `clean_finish: false` on it.

## How it was verified

**Four agent runs, none of them a reading pass.** Three executed the shipped prose against synthetic fixtures with expectations written down *first* and compared afterwards; the fourth was a scoped re-review of the fix wave. Fixtures were described concretely (a Maven + Vitest repository with `mvn` absent and `node_modules` removed, so that *both* suites abort — which is what `RUN_FAILED` actually requires; a `Cargo.toml` with zero `#[test]` functions for `NO_TESTS`, since a Maven- or pytest-only testless repo returns a failed run rather than `NO_TESTS`).

**Found: 3 Critical, 11 Important, plus 8 residuals on re-review.** Two of the three Criticals were *introduced* by the first commit, which is the return on running the checks at all:

- **The operator's test command never reached the verify call.** The "Specify test command" option was copied from `/implement` without its carry-forward rule, and here the verify belongs to the agent rather than the command, so the hint had one more boundary to cross and no declared field to cross it. Worse than inert in two directions: a hint that was all that was detected leaves verify detecting nothing (`COMMAND_NOT_FOUND`, every unit `TESTS_NOT_RUN` after the operator supplied a command that worked), and a hint naming a working alternative leaves its `command_hint#<n>` row pairing with nothing, so its baseline tests fall out as **Missing from run** and verify reports `REGRESSIONS` — offering a revert on a security remediation against a regression the run manufactured.
- **`vuln-fixer` step 1's new arms collided with its Model Routing gate.** Step 1 was previously skipped on `baseline_tests: provided`, so its arms had never met the gate; running on every call they did, and on a `HIGH-RISK` CVE the losing branch skipped the Opus review outright — reachable in any repository without tests.
- **A shared reference told both agents their commands "branch on the `Status` alone"**, four lines into the file each agent's new instruction cites as its authority.

The remaining Importants were of the same family: `code-handoff` §2.9 listing four `clean_finish` conditions while both commands asserted a fifth; a New failure with no marker, leaving the commands testing free text that also holds a `TEST_REGRESSION`'s failing list; `TESTS_NOT_RUN` — now the ordinary outcome of a dead baseline — having no `Result` label, so an agent copying the table's two examples would write `OK`; `/upgrade`'s `Not verified:` line reporting `none` on the run that verified least; and "the capture" acquiring a second referent in `/vuln` Step 3, making the base-branch rule circular and inviting a baseline taken on the operator's own branch.

## Gates

`GATES_EXIT=0`, **198** `ok`, **5** `SELFTEST PASS`, and `PASS: all 36 mermaid blocks in 578 tracked markdown files parse` — run on each of the four commits.

## What is NOT verified, stated plainly

- **The shipping tree has never been executed.** The three execution runs read commit `4ee0efe7`; the scoped re-review read `d51b303b`. The last commit, `fdc73f53`, closes the eight residuals and is **unrun** — it was reviewed by hand against the files it names and by the gate chain, and by nothing else. Its changes are small, local and each confined to the sentence the finding named, which is the reason a fifth round was judged disproportionate rather than unnecessary.
- **No live `/vuln` or `/upgrade` run was made against a real repository.** Every scenario was played by an agent executing the prose; none dispatched `test-baseliner` at a real test suite. The failure this cannot catch is one where a real runner's output disagrees with the parse table — which this change does not touch.
- **`/implement` was checked and deliberately left alone.** It cannot reach an uncovering baseline at verify: of its three Pre-Phase 3.5 arms, one re-captures, one records `test_decision: skip` which drops steps 4–6, and one cancels. Its own enumeration of verify's `RUN_FAILED` causes therefore stays complete for what it can reach.

## Open findings

None. Every finding from all four runs was verified at the location it named and closed on this branch.
