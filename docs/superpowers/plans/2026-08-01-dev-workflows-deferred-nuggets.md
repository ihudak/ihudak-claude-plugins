# dev-workflows deferred-nuggets (wave 3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land six additive, single-location sharpeners into the `dev-workflows` plugin (from the
2026-07-29 harvest's deferred backlog) across all three editions, with version + CHANGELOG sync.

**Architecture:** Six independent prose additions to existing reference/agent/command files. Edit
canonical (`ihudak-claude-plugins`) first, port byte-identically to `mgd-claude-plugins`, port as
prose-identical additions to `ihudak-copilot-plugins` (path/skill-layout differs, added prose does not).
Bump MINOR version + add a CHANGELOG entry in each edition. Hold all pushes.

**Tech Stack:** Markdown plugin files; `claude plugin validate` for Claude editions; JSON manifests.

## Global Constraints

- **Additive & backward-compatible** — every edit adds guidance; no existing rule, ID, section header, or
  dimension number is removed or renumbered.
- **`references/specification-format.md` is FROZEN** — never edit it. Item 3 lands only in `design-format.md`.
- **Match each file's local wrap width** (the harvest's final review flagged wrap drift):
  `ard-format.md` = single-line bullets (no hard wrap); `epics.md` = single-line bullets;
  `design-format.md` ≈ 100 cols; `code-review.md` ≈ 72 cols; `session-hygiene.md` ≈ 78 cols;
  `context-management.md` ≈ 100 cols.
- **Version:** Claude/mgd `2.38.0 → 2.39.0`; Copilot `2.8.0 → 2.9.0` (`plugin.json` + `marketplace.json`).
- **Pushes HELD** for explicit user confirmation. Commit trailer:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **Copilot conversions:** added prose has NO path references, so it ports identically; only surrounding
  files already differ. Verify 0 `${CLAUDE_PLUGIN_ROOT}` leaks introduced.

---

### Task 1: Canonical (`ihudak-claude-plugins/plugins/dev-workflows`) — six additive edits

**Files:**
- Modify: `references/ard-format.md` (after the `AD-N are testable…` quality rule)
- Modify: `commands/epics.md` (after the Phase 2 sizing/sequencing bullet, ~L125)
- Modify: `references/design-format.md` (after the Principle paragraph, ~L14)
- Modify: `agents/code-review.md` (dimension 4, Missed edge cases, ~L89-91)
- Modify: `references/session-hygiene.md` (after the §1 `resume.md` template code fence, ~L44)
- Modify: `references/context-management.md` (after the three strategy bullets, ~L12)

- [ ] **Step 1 — ard-format.md (item 1, single-line bullet).** Insert immediately after the quality rule
  ``- `AD-N` are **testable** and non-overlapping (Binds/Prevents/Rule each populated).``:

```
- An `AD-N` earns its place only when the decision is **hard to reverse** AND **surprising without context** AND the result of a **real trade-off**; a decision missing any of the three is an ordinary implementation choice (leave it to `/design`), not an architecture decision.
```

- [ ] **Step 2 — epics.md (item 2, single-line bullet).** Insert immediately after the Phase 2 bullet
  `- Proposed Epic sizing/sequencing — prefer fewer, larger Epics … order so that no Epic depends on a later one`:

```
- **Wide-refactor exception** — a blast-radius-wide *mechanical* change (rename/retype a shared symbol, column, or type) that genuinely cannot be tracer-bulleted into independent vertical slices is sequenced **expand → migrate-in-batches → contract**: one Epic adds the new form alongside the old, one-or-more Epics migrate call sites in batches, and a final Epic removes the old form (blocked by every migrate-batch). Prefer this over forcing the change into an awkward vertical slice.
```

- [ ] **Step 3 — design-format.md (item 3, wrap ≈100).** Insert a new paragraph immediately after the
  Principle paragraph (after `…a HIGH-RISK design is thorough across every section.`), before `## Header`:

```
**Prose is the default; a decision-encoding snippet is the exception.** Where a snippet — a state machine,
reducer, schema, or type shape — encodes a decision *more precisely than prose can*, inline it (note it if it
came from a prototype) and trim it to the decision-rich parts. Never paste a whole prototype; the snippet
earns its place only by pinning down a decision prose would leave ambiguous.
```

- [ ] **Step 4 — code-review.md (item 4, wrap ≈72).** Extend dimension 4 by appending to its last line
  (`… idempotency, rate limiting.`):

```
4. **Missed edge cases** - nulls, empty collections, zero/negative/boundary
   values, unicode, timezones, concurrent access, partial failures, retries,
   idempotency, rate limiting. Also the **missing-adoption gap** — a sibling
   call site that should adopt the changed behavior and doesn't (an untouched
   caller of the same pattern), with no test catching the omission.
```

- [ ] **Step 5 — session-hygiene.md (item 5, wrap ≈78).** Insert immediately after the §1 `resume.md`
  template's closing code fence (the ``` after the `Carry-forward decisions:` line), before `## 2.`:

```
**Redact before writing.** The `Carry-forward decisions` line may summarize content pulled from a Jira
ticket or the session — redact any secret, credential, token, or PII. A resume pointer records *what to do
next*, never a sensitive value.
```

- [ ] **Step 6 — context-management.md (item 6, wrap ≈100).** Insert a 4th strategy bullet immediately
  after the `**Decompose**` bullet (`…finish the current unit before starting the next.`):

```
- **Hand off by file, not paste** — when dispatching a subagent, write the context it needs (task brief,
  diff, review package, prior-phase summary) to a file and hand the subagent the *path*, not the pasted
  content. Pasted dispatch content stays resident in the orchestrator's context and is re-read on every
  later turn; a file path costs one line.
```

- [ ] **Step 7 — validate.** Run `claude plugin validate plugins/dev-workflows` from the repo root; expect
  no errors. Grep-read-back each of the 6 insertions to confirm exact placement.

- [ ] **Step 8 — commit** (branch `feat/deferred-nuggets` created before any edit).

### Task 2: Port to `mgd-claude-plugins` (byte-identical)

**Files:** the same six under `mgd-claude-plugins/plugins/dev-workflows/` (`references/ard-format.md`,
`commands/epics.md`, `references/design-format.md`, `agents/code-review.md`, `references/session-hygiene.md`,
`references/context-management.md`).

- [ ] **Step 1 — confirm byte-identity of anchors.** For each file, grep the canonical anchor line; confirm
  mgd's pre-change file matches (mgd is a straight copy). If any anchor differs, STOP and surface it.
- [ ] **Step 2 — apply the six identical hunks** (same literal text as Task 1 Steps 1–6).
- [ ] **Step 3 — validate** `claude plugin validate plugins/dev-workflows`; grep-read-back all six.
- [ ] **Step 4 — commit** on `feat/deferred-nuggets`.

### Task 3: Port to `ihudak-copilot-plugins` (prose-identical, layout differs)

**Files (Copilot layout):**
- `dev-workflows/skills/_shared/ard-format.md` (item 1)
- `dev-workflows/skills/epics/SKILL.md` (item 2 — Phase 2 anchor)
- `dev-workflows/skills/_shared/design-format.md` (item 3)
- `dev-workflows/agents/code-review.md` (item 4)
- `dev-workflows/skills/_shared/session-hygiene.md` (item 5)
- `dev-workflows/skills/_shared/context-management.md` (item 6)

- [ ] **Step 1 — locate anchors.** Grep each Copilot file for the corresponding anchor (wording may differ
  slightly from canonical where the file was hand-converted — e.g. `code-review.md` model phrasing,
  `epics.md`→SKILL.md keyword names). Confirm the same logical insertion point exists.
- [ ] **Step 2 — apply the six additions as prose-identical text** (same literal wording as Task 1; the
  additions contain no paths so no conversion is needed). Match each Copilot file's local wrap width.
- [ ] **Step 3 — verify parity + no leaks.** `grep -rn 'CLAUDE_PLUGIN_ROOT' <the 6 files>` → the 6
  additions introduce **zero** new hits. Confirm each addition is present (grep the distinctive phrase, e.g.
  `missing-adoption gap`, `Wide-refactor exception`, `Hand off by file`).
- [ ] **Step 4 — commit** on `feat/deferred-nuggets` in the Copilot repo.

### Task 4: Version + CHANGELOG sync (all three editions)

**Files:**
- Claude: `.claude-plugin/marketplace.json`, `plugins/dev-workflows/.claude-plugin/plugin.json`,
  `plugins/dev-workflows/CHANGELOG.md`
- mgd: `.claude-plugin/marketplace.json`, `plugins/dev-workflows/.claude-plugin/plugin.json`,
  `plugins/dev-workflows/CHANGELOG.md`
- Copilot: `.github/plugin/marketplace.json`, `dev-workflows/.plugin/plugin.json`,
  `dev-workflows/CHANGELOG.md`

- [ ] **Step 1 — bump versions.** Claude/mgd `2.38.0 → 2.39.0` (both the marketplace entry and the
  per-plugin `plugin.json`); Copilot `2.8.0 → 2.9.0` (both). Grep for the old version string in each repo to
  confirm no stray copy is missed.
- [ ] **Step 2 — CHANGELOG entries.** Add a `[2.39.0] — 2026-08-01` (Claude/mgd) / `[2.9.0] — 2026-08-01`
  (Copilot) section listing the six additions (ADR 3-condition filter, wide-refactor exception,
  prototype-snippet exception, code-review missing-adoption gap, resume.md redaction reminder,
  context-management "hand off by file" 4th strategy). Leave prior entries intact.
- [ ] **Step 3 — doc-surface sweep.** Grep each repo's `README.md`, `CLAUDE.md` /
  `.github/copilot-instructions.md`, and `AGENTS.md` (if present) for anything that enumerates the changed
  guidance. Expectation: **no change needed** (no new command/reference/behavior). If a surface names one of
  the six, update it; otherwise record "no doc-surface change" in the report.
- [ ] **Step 4 — validate + commit.** `claude plugin validate` (Claude + mgd); confirm the Copilot manifests
  parse (JSON). Commit on each repo's `feat/deferred-nuggets`.

### Final: whole-branch review

- [ ] Dispatch an Opus whole-branch review over the canonical `feat/deferred-nuggets` diff (design intent =
  this plan + the design doc). Fix Critical/Important findings in one wave; record Minors. THEN stop and
  present the merge/push decision to the user (pushes held).

## Self-review (author checklist — done)

- **Coverage:** all six selected items have a task/step. ✓
- **Placeholders:** none — every insertion carries literal text. ✓
- **Consistency:** version numbers, file paths, and wrap widths match the design doc's Global Constraints. ✓
- **Frozen file:** `specification-format.md` appears only as a "never edit" constraint. ✓
