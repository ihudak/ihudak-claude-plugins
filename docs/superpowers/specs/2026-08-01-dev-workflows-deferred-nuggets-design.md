# dev-workflows deferred-nuggets harvest (wave 3) — design

Follow-on to the 2026-07-29 upstream harvest (`2026-07-29-dev-workflows-upstream-harvest-design.md`
+ `…-plans/2026-07-29-dev-workflows-upstream-harvest.md`). Six items from that harvest's
**deferred backlog** (recorded in `docs/superpowers/harvest/NEXT.md`) were selected by the user on
2026-08-01. All six are additive, single-location, low-risk sharpeners of existing artifacts — no new
commands, no new agents, no new reference files, no phase changes.

## Scope — the six selected items

| # | Item | Canonical target · anchor | Source | Effort |
|---|------|---------------------------|--------|--------|
| 1 | ADR 3-condition candidacy filter | `references/ard-format.md` · `## Quality rules` (with the AD-N testability rule) | Matt `domain-modeling` | S |
| 2 | Wide-refactor expand→migrate→contract exception | `commands/epics.md` · Phase 2 sizing bullet | Matt `to-tickets` | S/M |
| 3 | Prototype-snippet exception | `references/design-format.md` · Principle | Matt `to-spec` | S |
| 4 | Missing-adoption gap | `agents/code-review.md` · dim 4 (Missed edge cases) | BMAD `lens-verification-gap` | S |
| 5 | `resume.md` redaction reminder | `references/session-hygiene.md` · §1 template | Matt `handoff` | S |
| 6 | Context "hand off by file, not paste" (4th strategy) | `references/context-management.md` · strategy list | superpowers SDD / dispatching-parallel-agents | S (reference-only) |

## Per-item adaptation (exact intent)

1. **ADR 3-condition filter.** `ard-format.md`'s `## Architecture decisions` section says *how* to shape
   an `AD-N` (Binds/Prevents/Rule) but not *which* decisions earn one. Add the candidacy test: a decision
   becomes an `AD-N` only when it is **hard to reverse** AND **surprising without context** AND the result
   of a **real trade-off** — a decision missing any of the three is an ordinary implementation choice, not
   architecture, and is left to `/design`.

2. **Wide-refactor exception.** `epics.md` Phase 2's sizing bullet prefers fewer, larger, dependency-ordered
   Epics but is silent on a blast-radius-wide *mechanical* change (rename/retype a shared symbol/column/type)
   that genuinely cannot be tracer-bulleted into independent vertical slices. Add a named carve-out:
   sequence it **expand → migrate-in-batches → contract** — one Epic adds the new form alongside the old,
   one-or-more Epics migrate call sites in batches, a final Epic removes the old form (blocked by every
   migrate-batch).

3. **Prototype-snippet exception.** `design-format.md`'s Principle records decisions in prose by default.
   Add a narrow, named exception: where a snippet (state machine, reducer, schema, type shape) encodes a
   decision *more precisely than prose can*, inline it, note it if it came from a prototype, and trim to the
   decision-rich parts — never paste a whole prototype. (`specification-format.md` is **frozen**; this lands
   only in `design-format.md`.)

4. **Missing-adoption gap.** `code-review.md` dimension 4 (Missed edge cases) covers null/empty/boundary/
   concurrency but not the *sibling call site* case. Add: a call site that should adopt the changed behavior
   and doesn't (an untouched caller of the same pattern), with no test catching the omission. This
   complements the converge gate shipped in wave 2 (the conditional 10th dimension) — that traces in-scope
   IDs against the diff; this catches an *adjacent* site the diff left behind.

5. **`resume.md` redaction reminder.** `session-hygiene.md` §1's tiny `resume.md` template has a
   `Carry-forward decisions` line that could summarize content out of a Jira ticket/session. Add a one-line
   rule: redact any secret, credential, token, or PII — a resume pointer records *what to do next*, never
   sensitive values.

6. **Context "hand off by file, not paste".** `context-management.md` documents three strategies for *when*
   to offload context but not the *how* upstream now names. Add a 4th strategy: when dispatching a subagent,
   write the context it needs (task brief, diff, review package, prior-phase summary) to a file and hand the
   subagent the *path*, not the pasted content — pasted dispatch content stays resident in the orchestrator's
   context and is re-read on every later turn. **Reference-only:** the matching rewrite of `/implement`'s
   Phase 1.7/2B/3B dispatch prompts is explicitly **deferred** (see Out of scope).

## Global constraints

- **Additive & backward-compatible.** Every edit *adds* guidance; no existing rule, `AD-N`/`[Uxx]` ID,
  section header, or dimension number is removed or renumbered. A run that never hits the new case behaves
  byte-for-byte as before.
- **`references/specification-format.md` stays FROZEN** — untouched (it is a snapshot from
  `mgd-specifications`). Item 3 lands only in `design-format.md`.
- **Three editions kept in parity.** Canonical `ihudak-claude-plugins` (Claude) → `mgd-claude-plugins`
  (byte-identical copy) → `ihudak-copilot-plugins` (Copilot conversions: `references/*` → `skills/_shared/*`,
  `commands/epics.md` → `skills/epics/SKILL.md`, `${CLAUDE_PLUGIN_ROOT}` → `~/.copilot/…/skills/_shared/`,
  model phrasing, keyword command names). The added prose contains **no path references**, so items 1–6 port
  as identical prose additions; only the surrounding file (e.g. `code-review.md` model phrasing) already
  differs.
- **Versioning.** MINOR bump + CHANGELOG entry each edition: Claude/mgd **2.38.0 → 2.39.0**, Copilot
  **2.8.0 → 2.9.0** (`plugin.json` + `marketplace.json`).
- **No README / CLAUDE.md / AGENTS / copilot-instructions changes expected** — no new command, no new
  reference file, no user-visible command behavior change. (Verified during execution by grepping the doc
  surfaces for anything that enumerates the changed guidance; corrected if a surface names it.)
- **Pushes HELD** for explicit user confirmation. Commit trailer:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **mgd** push bypasses a PR-required branch rule (user: "ok for now").

## Out of scope (deferred)

- The **`/implement` dispatch-prompt refactor** — rewording Phase 1.7 / 2B / 3B to write dispatch context to
  a file and hand a path (the "full" option of item 6). It touches a working command's hot path (three
  dispatch sites) and deserves its own SDD pass against `/implement`; tracked in `NEXT.md`.
- The **"Rejected on merits"** backlog in `NEXT.md` (CLI/template scaffolding, `constitution`, governance
  presets, SDD ledger / 5-round fix-breaker, generic lens engine, git-push-blocking hook, PRD-coach
  "never recommend an answer", batch-grill-me) — revisit only if asked.
