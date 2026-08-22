# Finding triage (embedded — shared reference)

The step between a reviewer's findings and a fixer's edits. Run by the **orchestrator**, never by the
fixer: `review-fixer` and `doc-fixer` run on the detection/Sonnet chain while `code-review`,
`doc-reviewer`, and `epic-reviewer` are Opus-pinned, and a dismissal decision must not sit at a weaker
station than the one that produced the finding.

## When this runs

Wherever an **Opus reviewer's reasoned findings feed a fixer**:

| Path | Triage |
|---|---|
| `code-review` → `review-fixer` (`/implement`, `/vuln`, `/upgrade`) | yes |
| `doc-reviewer` → `doc-fixer` (`/document`, Jira mode) | yes |
| `epic-reviewer` → `doc-fixer` (`/epics`) | yes |
| a style checker → `doc-fixer` (`/document` direct mode, and the style-fix cycles inside `/document` Jira mode and `/epics`) | **no** |

The seam is **reasoned-claim producer vs deterministic producer**, not code vs docs. A reviewer finding
is a claim about consequence and can be checked against the thing it names. A linter violation is not —
a rule matched or it did not, and there is nothing to trace. `/document` and `/epics` each dispatch
`doc-fixer` more than once; this step attaches to the **reviewer-fed dispatch only**.

A review that returns the `Diff: unreadable at <path>` marker never reaches this step. That verdict
reports a capture failure, not a finding about the change: there is no location to verify it at, and its
own BLOCKER says so. The caller stops on the marker (`/implement`, `/vuln`, `/upgrade` each check the
review's first line before acting on the verdict), so no fixer is dispatched and nothing is triaged.

## The step

For each finding, **before any grouping or deduplication**:

1. **Verify its own claimed consequence** at the location it names. Read past the changed lines — into
   the callers, the guards upstream, whatever else the site depends on — far enough to tell whether that
   consequence actually occurs. Another finding's outcome, however adjacent, never settles this one.
2. **Keep or dismiss.** Keep a finding only where verification confirmed its consequence. Dismiss noise,
   claims the verification refuted, and claims it could not substantiate — no path to the claimed
   consequence at the named site is a valid disposal. Whatever the reason, **it must dispose of that
   finding's own claim**: a true fact about neighbouring code that leaves the claim standing is not a
   dismissal, and the finding stays kept.
3. **Record every dismissal with its reason.** Never drop a finding silently. There is no "reject and
   say nothing" disposition and none may be added.

Only survivors are handed to the fixer.

## When triage empties the survivor set

Triage disposes of findings; it does not restate the verdict. Where every finding behind a non-`PASS`
verdict is dismissed, the verdict is left standing on nothing — and because the **verdict**, not the
survivor set, is what gates every downstream branch, the run would otherwise dispatch a fixer with no
findings to apply, or escalate a `BLOCKER` triage has already refuted. The disposition, in order:

1. **Never dispatch the fixer with an empty survivor list.** It has nothing to apply, and the Fix
   Report a later re-review would falsify has nothing to be falsified against. Skip the dispatch.
2. **Never run the unresolved-`BLOCKER` escalation on a refuted `BLOCKER`.** That escalation exists
   for a `BLOCKER` that survived a fix cycle, not for one that never survived triage.
3. **Surface it and let the user settle the verdict.** Report the verdict, the fact that nothing
   survived, and every dismissal with its reason, then ask:
   ```
   choices: ["Proceed as if the verdict were PASS — the dismissals are recorded (Recommended)", "Re-review, supplying the dismissal reasons", "Keep the verdict and stop for a human decision", "Cancel"]
   ```
   **Never** promote a non-`PASS` verdict to `PASS` silently. The orchestrator's authority under this
   reference is over *findings*; a verdict its own findings no longer support is the user's to settle.

A partly emptied set is not this case: where at least one finding survived, the verdict stands and the
command's normal branch runs on the survivors.

## The patch gate

A survivor may be auto-fixed only where it shows a defect that **actually occurs**, missing coverage for
a specific case, or a broken gate or convention — **not a state nothing reaches** — and where the
smallest fix adds no public surface and **guards no state the finding did not demonstrate**. A survivor
failing any of those conditions is surfaced for a human decision instead of patched.

That last clause is the load-bearing one: a guard added for a state the finding never demonstrated is
the most common shape of a "fix" applied to a false positive, and it is invisible afterwards because it
looks like defensive coding.

## Reporting

The orchestrator's run report names, for the triage step: how many findings were reviewed, how many
survived, and **every dismissal with its reason**. A triage that reports only survivors is
indistinguishable from a reviewer that found less.
