# Instruction-file maintenance (embedded — shared reference)

Rules for proposing or making changes to an agent-instruction file — `CLAUDE.md`, `AGENTS.md`,
`.github/copilot-instructions.md`, a rules file, or any `references/*.md` in this plugin. Consulted by
`impl-maintenance` when it proposes changes, and binding on hand edits, which is where most stale claims
originate.

## 1. Verify every command claim against the thing that runs it

For any claim about what a command, script, gate, or agent does, read the target and confirm it before
writing the claim down. A claim about `scripts/foo.sh` is verified by reading `scripts/foo.sh`, not by
reading another document that describes it. A claim that a gate blocks on X is verified by finding the
rule that blocks on X.

## 2. A rewrite that narrows a rule is a deletion

If a rewrite weakens, narrows, or drops part of an existing rule, the lost part is a **deletion** and is
itemised separately, not folded silently into the rewrite. Keep the rule itself; examples may explain a
rule but can never replace it. "I made it more concise" is how a rule's binding half disappears.

## 3. A pointer must name an observable trigger

A line that sends the reader elsewhere names a trigger the agent can **observe** — a path, a file type, a
named command, a named task. Never one it must judge ("when the task is complex", "for significant
changes") or track about itself ("before your first edit", "once you have enough context"). An
unobservable trigger is a rule that never fires.

## 4. Two live contradictory instructions is a defect

When two instructions in force at the same time disagree, that is a defect to fix, not an ambiguity for
the reader to adjudicate. Fix it at the source; do not add a third instruction explaining which of the
two wins.

## 5. Retirement needs grounds

An instruction is removed only when it is stale, wrong, already enforced by a hook or check, harmful or
contradictory, or explicitly approved for removal as a line item. **Never** because it looks derivable
from the code, and **never** because nothing has failed on it lately — a rule that stops failures is
indistinguishable from a rule nobody needed, right up until it is removed.
