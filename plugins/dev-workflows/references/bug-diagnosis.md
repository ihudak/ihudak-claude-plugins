# Bug-diagnosis discipline (embedded — shared reference)

Feedback-loop-first discipline for **bug-shaped** SIGNIFICANT / HIGH-RISK tasks. Cited by
`/implement` (Phase 2B) and followed by `risk-planner` when the caller sets `task_shape: bug`. Adapted
from mattpocock `diagnosing-bugs`; aligns with `superpowers:verification-before-completion`.

## Principle — build the feedback loop before hypothesizing

A bug fix is only as trustworthy as the loop that proves it. Establish a failing, observable loop
first; only then reason about cause.

## Steps

1. **Repro first.** Construct a **red-capable, deterministic, fast, agent-runnable** reproduction
   command that fails *because of this bug* — before forming any hypothesis. Minimize it to the
   smallest input/state that still fails. A bug you cannot reproduce on demand is not yet ready to fix.
2. **Rank falsifiable hypotheses.** List **3–5** candidate causes, each stating (a) what it predicts
   you would observe and (b) the cheapest observation that would **falsify** it. Order by likelihood ×
   cheapness-to-test. A hypothesis you cannot falsify is not a hypothesis — drop it.
3. **Instrument with tagged, removable probes.** Add temporary instrumentation tagged `[DEBUG-xxxx]`
   (a short unique token per probe). Test the ranked hypotheses against the repro. Every `[DEBUG-xxxx]`
   probe MUST be removed before the change is finalized (the `/implement` Phase 3B cleanup gate strips
   them before the review diff is captured).
4. **Fix at the correct seam; regression-test there.** Land the fix and its regression test at the
   **correct seam** (see `${CLAUDE_PLUGIN_ROOT}/references/design-format.md` `## Seams` — prefer the
   highest seam that still isolates the behavior). If **no correct seam exists**, that is itself a
   finding — record it (the code needs a seam before it can be safely tested); do NOT bolt a test onto
   the wrong seam to manufacture green.
5. **Evidence before the claim.** Never report the bug fixed until the repro from step 1 goes green.
