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

Prefer the cheapest strategy that fits: checkpoint first; offload parallel steps only when they are
genuinely independent; decompose only when a single unit still overflows.

At each **checkpoint**, a long-run command may additionally suggest **`/compact`** to free
context before continuing the next scope/Epic — see `references/session-hygiene.md` §3
(mid-command → `/compact` only, never `/clear`; guidance-only).
