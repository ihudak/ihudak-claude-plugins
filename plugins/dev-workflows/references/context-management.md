# Long-run context management (embedded — shared reference)

Strategies for an implementation run whose step list is too long to complete in one context window
without degrading. Apply when the plan/step list is large or the run is nearing its context budget.

- **Scope-to-N** — implement the first N steps, **checkpoint** (commit the working increment + report
  progress), then continue from N+1. The commit history is the durable progress map.
- **Sub-agent-per-`[P]`** — for steps marked parallel-safe (`[P]`) or otherwise independent, dispatch a
  fresh subagent per step so their work never enters the orchestrator's context; the orchestrator only
  integrates the results.
- **Decompose** — if the remaining work is too large even with checkpoints, split it into independently
  shippable units and finish the current unit before starting the next.
- **Hand off by file, not paste** — when dispatching a subagent, write the context it needs (task brief,
  diff, review package, prior-phase summary) to a file and hand the subagent the *path*, not the pasted
  content. Pasted dispatch content stays resident in the orchestrator's context and is re-read on every
  later turn; a file path costs one line. Always `mktemp` the handoff file — **never inside a repo working
  tree** (and never in the vault) — so a later `git add -N . && git diff` never picks it up.

## The read-failure contract

A handed-over path is only useful if it can be read. Every agent that accepts an input "inline or as an
absolute file path" MUST state what happens when that read fails, and every such failure resolves into
exactly one of two tiers.

**Evidence inputs** — the artifact the agent's judgement rests on (a diff, a review report, a research
report, an upgrade plan). An unreadable evidence path is a **hard stop**: return the agent's structured
gap/blocked shape, naming the path that could not be read. **Never regenerate the artifact by any other
means** — not by re-running `git diff`, not by re-running a test suite, not by reconstructing it from
memory. Evidence you could not read is not evidence that does not exist, and regenerating what you
failed to read is not verification: it silently substitutes a different artifact (a diff at the wrong
base, a suite at the wrong commit) and then reports success over it.

**Context inputs** — optional grounding that sharpens the work but is not the work (a plan, an ARD
invariant set, a spec-scope block). An unreadable context path **degrades to absent**: proceed exactly
as if the input had not been passed — any dimension or section conditional on it stands down as it
already does — and **record the degradation in the output** so the skip is attributed rather than
silent. This matches `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §3.4 (an absent optional input
falls back to pre-existing behaviour, never becomes a new prerequisite) and
`${CLAUDE_PLUGIN_ROOT}/references/gate-ledger.md` (no skip goes unattributed).

Which tier an input belongs to is fixed by the consuming agent and stated **where that agent takes the
input** — its `## Inputs` section, or the `## Process` step that receives the brief for an agent that has
no `## Inputs` section (`vuln-fixer`, `upgrade-executor`) — never decided at runtime.

Prefer the cheapest strategy that fits: checkpoint first; offload parallel steps only when they are
genuinely independent; decompose only when a single unit still overflows. "Hand off by file" is
orthogonal — apply it whenever you dispatch a sub-agent, whichever offload strategy you chose.

At each **checkpoint**, a long-run command may additionally suggest **`/compact`** to free
context before continuing the next scope/Epic — see `${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` §3
(mid-command → `/compact` only, never `/clear`; guidance-only).
