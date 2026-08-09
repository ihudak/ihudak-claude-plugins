# Gate ledger (shared)

Single source of truth for how a command records whether each of its verification gates actually ran.

Consumed by `/document` (both modes). Written generically so other commands can adopt it — see §6.

---

## 1. The problem it solves

A phase that says "Mandatory — never skip on your own judgement" is still skipped when the
orchestrator finds a plausible-sounding reason. `/document` Phase 6.4 has carried that exact wording
since v2.0.0 and was skipped anyway, and Phase 6.5's `(Recommended)` marker was moved onto the Skip
option on the same run. Emphasis is not enforcement.

The ledger removes the cell in which a run can write *"I decided this wasn't necessary."* Every gate
ends in one of six outcomes, and every non-run path terminates in a **named missing precondition**, a
**named missing tool**, or a **verbatim user decision**.

## 2. Outcomes

| Outcome | Means | Assignable by |
|---|---|---|
| `RAN` | The gate's primary mechanism executed. | evidence only |
| `DEGRADED` | Only a fallback executed. Records what did not run, why, and what CI will still check. | evidence only |
| `FAILED` | Ran and found blocking problems. Feeds the caller's existing fix loops. | evidence only |
| `UNAVAILABLE` | Nothing ran and no fallback exists, with the precondition met. **Not a resting state** — see §5. | the orchestrator, but never as a final answer |
| `SKIPPED_BY_USER` | The user chose to skip. Carries their decision quoted verbatim. | the user only |
| `NOT_APPLICABLE` | A named precondition is unmet. | evidence only |

There is no orchestrator-assignable "skipped". "Flaky, and the static analysis was sufficient" has
nowhere to go.

`DEGRADED` proceeds — a weaker check is not a documentation defect, and the final report names what
CI will check that the run did not. Total absence of coverage does not proceed.

## 3. Row schema

The ledger is an in-context YAML block. The orchestrator **appends a row at the moment each gate
completes** — never reconstructs the ledger at report time from memory.
A phase whose outcome is not yet known at append time may write a **provisional** row, but only when a named later step in that same phase rewrites it before the phase ends — Phase 5.8's `Ledger (final)` and Phase 6.5's `Ledger (final)` are the two sanctioned cases. A provisional row is never the outcome a later reader sees.

```yaml
gate_ledger:
  - gate: <registry id from §4>
    phase: "<the phase that owns it>"
    outcome: RAN | DEGRADED | FAILED | UNAVAILABLE | SKIPPED_BY_USER | NOT_APPLICABLE
    mechanism: <what actually executed; omitted when nothing did>
    not_run:                                        # DEGRADED only, non-empty
      - mechanism: <the primary mechanism that did not run>
        reason:    <why>

    ci_still_checks: <one line>                     # DEGRADED only, non-empty
    precondition_unmet: <the named precondition>    # NOT_APPLICABLE only, non-empty
    user_decision: "<the user's choice, verbatim>"  # SKIPPED_BY_USER only, non-empty
    findings: <count>                               # RAN / DEGRADED / FAILED
```

## 4. The `/document` gate registry

| Gate id | Phase | Precondition | Primary | Fallback |
|---|---|---|---|---|
| `toolchain_preflight` | 0 | always (runs after profile resolution) | `command -v` / `test -d` over the required set (`toolchain-preflight.md` §2) | none |
| `source_truth_verification` | 5.8 | ≥1 entry in `code_repos` | claim-class verification per `source-truth.md` §2–§3 | one supplementary direct grep against the resolved local path |
| `style_check` | 6.4 | ≥1 file written | the repo linter ladder **plus** `dt-style-checker` complementary | `dt-style-checker` alone |
| `repo_checklist` | 6.4 | the repo publishes authoring/verification guidance | `repo_verification_gates` applied to the written files | none |
| `build_check` | 6.5 S1 | write context is a buildable repo | `commands.per_space.<space>.build` per written space, else whole-repo `commands.build` | the Step 2 dev-server boot |
| `render_smoke_check` | 6.5 S2 | buildable repo with ≥1 affected page | dev servers for the target **and** protected spaces | the manual pages-to-visit table |

A gate whose precondition is unmet records `NOT_APPLICABLE` with the precondition named. It is never
silently absent from the ledger.

**Direct mode** (`/document` Mode B) registers exactly three gates: `toolchain_preflight` (Phase 0),
`repo_checklist` (Phase 0 extraction, checked at Phase 3.5), and `style_check` (Phase 3.5). The other
three ids never appear in a direct-mode ledger — not even as `NOT_APPLICABLE`:

- `source_truth_verification` — direct mode has no Phase 5.8, no `jira-reader`, and no `code_repos`.
- `build_check` and `render_smoke_check` — direct mode has no Phase 6.5 and no `target_spaces`.

Direct mode has no `doc-planner`, so its orchestrator extracts `repo_verification_gates` itself per
`${CLAUDE_PLUGIN_ROOT}/references/repo-verification-gates.md` §5.

## 5. Converting `UNAVAILABLE`

`UNAVAILABLE` means the precondition was met and neither the primary nor the fallback ran — a real
coverage hole. The orchestrator converts it before the run continues, with a choice list bound by the
"Choice lists are presented verbatim" rule in `escalation-rules.md`:

```
choices: ["Install <named tool> and retry this gate", "Proceed without this check — record my decision", "Cancel the run", "Other… (describe)"]
```

- "Install and retry" → re-run the gate and rewrite its row.
- "Proceed without this check" → rewrite the row as `SKIPPED_BY_USER` with the user's choice quoted
  verbatim in `user_decision`.
- "Cancel the run" → stop.

The orchestrator never selects among these on the user's behalf.

## 6. The reviewer contract

The caller passes the completed `gate_ledger` to its review gate. For `/document` that is
`doc-reviewer`'s **Verification-gate integrity** dimension. The reviewer raises a **BLOCKER** when any
of these holds:

- a registry gate has **no row** in the ledger;
- a row's outcome is `UNAVAILABLE` (§5 never converted it);
- `SKIPPED_BY_USER` with an empty or absent `user_decision`;
- `NOT_APPLICABLE` with an empty or absent `precondition_unmet`;
- `DEGRADED` with an empty `not_run` or an empty `ci_still_checks`.

`DEGRADED` is otherwise not a finding — the reviewer notes it, and the final report prints its
`ci_still_checks` line.

## 7. Adopting this in another command

A command adopting the ledger declares its own registry table in the shape of §4 (gate id, phase,
precondition, primary, fallback), appends rows per §3, converts `UNAVAILABLE` per §5, and passes the
block to its review gate with the §6 contract. Nothing in §2, §3, or §5 is `/document`-specific.

## 8. Hard rules

- NEVER write a ledger row from memory at report time. Append it when the gate completes.
- NEVER record an outcome the evidence does not support — a gate that did not execute is not `RAN`.
- NEVER leave `UNAVAILABLE` as a final outcome; §5 always converts it.
- NEVER paraphrase the user's words in `user_decision`; quote the option they chose.
- NEVER omit a registry gate's row because it seemed irrelevant — record `NOT_APPLICABLE` and name the
  precondition.
- NEVER promote `DEGRADED` to a finding on its own; the reviewer's §6 list is exhaustive.
