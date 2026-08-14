# `require-on-main` state-reachability trace (Risk 1's mitigation)

Companion to `plugins/dev-workflows/references/phase-handoff.md` §3.3. Each row below names a **concrete repository condition** that reaches the corresponding state — not a restatement of the state table's own predicate — so that every one of the ten rows is demonstrably reachable rather than merely definable.

| State | Concrete reaching condition | Observable outcome |
|---|---|---|
| H | `SPECS_PATH` unset, or set to a directory with no `.git` | returns `unmanaged`; caller unchanged |
| I | `git -C "$S" switch --detach origin/main` before the run | stop + the G0 notice |
| A | repo on `main`, freshly pulled, artifact committed and merged | pass |
| B | `/design` run 2 on `design/<KEY>-<slug>`, `specification.md` locally amended by run 1 | `pass_amending`, reported, **no switch offered** |
| C | repo on an unrelated named branch (G2 shape) that also carries an older `specification.md` | repair offer, re-test once |
| C′ | same as C, plus an uncommitted edit to a file the switch would overwrite | stop naming the files |
| D | artifact committed on `spec/<KEY>-<slug>`, pushed, PR open, `main` without it | stop naming PR #n |
| E | same as D but the PR closed unmerged, or never opened | stop naming the branch |
| F | a fresh VI folder with no `idea.md` anywhere | returns `absent`; the caller's ladder continues |
| G | `git -C "$S" update-ref -d refs/remotes/origin/main` (or a clone with no remote-tracking ref) | stop — cannot verify |

Every row was cross-checked against §3.3's first-matching-row predicates as inserted by Task 2: none of the ten conditions requires inventing a state or contradicts its row's predicate, so no defect in §3.3 is reported here.
