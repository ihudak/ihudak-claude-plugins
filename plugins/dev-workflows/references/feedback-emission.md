# Session Feedback Emission — Shared Reference

Single source of truth for the dev-workflows session-feedback emitter. Every
capture surface — the automatic maintenance phase of all ten workflow
commands, and the `/feedback` and `/prompt*` commands — cites this file and
executes its steps inline. The orchestrator owns every prompt; this reference
owns the entry format, the persistence ladder, dedup/attribution, the
plugin-facing predicate, and the caller contract.

**Purpose.** Capture friction and improvement signals about the **dev-workflows
plugin itself** and persist them per-VI into the **specs repo** so the plugin
maintainer can aggregate feedback across engineers. Feedback reaches the
maintainer only if it lands in the committed, pushed specs repo — hence the
persistence ladder is **specs-first** (§2).

**Self-contained — no hard cross-plugin dependency.** `/prompt-brainstorm` uses
`superpowers:brainstorming`; `/prompt-grill-me` runtime-resolves `/grilling`
(mattpocock-skills) and falls back to `superpowers:brainstorming` if it is not
installed. Neither is a declared install-time dependency.

**Relationship to B4 (`followup-emission.md`).** B4 captures the *engineer's own*
follow-up actions → vault-first, audience = the engineer. This feature captures
*plugin* friction → specs-first, audience = the maintainer. Both share the
`<VI-dir>/dev-workflows/` per-VI area. **No dedup between them** — different
purpose, different audience.

**Relationship to `impl-maintenance`.** The automatic surface reuses the existing
`impl-maintenance` agent's analysis; the agent definition is **untouched**. The
caller passes its Lessons Learned report to `emit-auto` (§6), which projects the
plugin-facing slice (§4) and persists it. This reference never analyses a
session itself.

## 1. Entry format (machine-friendly hybrid)

One file per VI, named `<KEY>-feedback.md`. Deterministic YAML for
filtering/clustering; prose for human judgment.

File-level frontmatter, written once on creation:

```yaml
---
type: dev-workflows-feedback
vi: PRODUCT-14902
slug: env-ag-update-window
---
```

- `vi` — the run's Jira key, or `n/a` when no key resolved.
- `slug` — the feature slug from the VI dir, or the ISO date on a keyless file.

Each entry is appended as a dated H2 header + a fenced YAML block + prose:

````markdown
## 2026-07-09 — /document — missing-capability

```yaml
id: PRODUCT-14902-document-saas-managed-split
date: 2026-07-09
command: /document           # controlled: exact command name, or n/a
plugin_version: 2.9.0
origin: auto                 # auto | manual | prompt
author: ivan.gudak@dynatrace.com
category: missing-capability # controlled, extensible, reuse-first
impact: friction             # blocker | friction | polish
```

**Friction:** One page covered both SaaS and Managed; the SaaS half got pushed
back in review because the two products differ here.

**Suggested improvement:** Add an optional `saas|managed` parameter to
`/document` so the run scopes to one product.
````

- YAML fields, all required: `id`, `date`, `command`, `plugin_version`,
  `origin`, `author`, `category`, `impact`.
- `origin` — `auto | manual | prompt`.
- `impact` — `blocker | friction | polish`.
- **`category`** — controlled vocab, extensible, reuse-first (reuse an existing
  value when it fits so clusters don't fragment):
  `missing-capability`, `wrong-output`, `ambiguous-prompt`,
  `missing-reference-doc`, `model-routing`, `manual-workaround`,
  `false-positive`, `docs-ux`, `other`.
- **`origin: prompt` entries add two more prose blocks** after Friction /
  Suggested improvement: **User prompt** (the user's corrective request,
  verbatim) and **Resolution** (what the AI actually did).
- `id` — stable: `<KEY>-<command>-<short-slug>` (drop the leading `/` from the
  command; use `manual` / `prompt` when `command` is `n/a`).

## 2. Persistence ladder (specs-first; never cwd)

`$SPECS_PATH` is primary — central aggregation is the whole point. Resolution is
**deterministic** (no interactive vault-path prompt, consistent with silent
capture, §5). Walk the ladder top-down and stop at the first tier that applies:

1. **`$SPECS_PATH` resolvable + writable + the VI dir exists** — the dir matched
   by `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…` →
   `<VI-dir>/dev-workflows/<KEY>-feedback.md`. *[primary — the whole point]*
2. **`$SPECS_PATH` writable but no VI dir matched** (no `jira_key`, or no
   matching spec dir) → `$SPECS_PATH/dev-workflows-feedback/<KEY-or-date>.md` at
   the specs-repo root. Still committed & aggregated; notice:
   `unfiled — move under the VI dir if it belongs to one.`
3. **No `$SPECS_PATH` (unset / missing / read-only) AND the vault is writable**
   (`$VAULT_PATH` set **and** `$VAULT_PATH/.obsidian/` is a directory **and**
   writable) → `$VAULT_PATH/dev-workflows/feedback/<KEY>-feedback.md`, with a
   **loud notice**:
   `⚠ $SPECS_PATH unavailable — saved to your vault; it will NOT auto-aggregate to the maintainer. Set $SPECS_PATH and commit, or forward manually.`
4. **`source = directory`** (imported Jira dir, no specs/vault) → beside the
   imported directory, where `/epics` + `/release-notes` already drop their
   no-vault output.
5. **Nothing resolvable** → **report-only**: keep the feedback in the run's
   final output and emit the notice. **NEVER write into the current working
   directory** — it may be a code repo.

In every non-primary tier the feedback also stays in the run's final output
(zero loss) and the run never fails. A write that fails mid-write (read-only
mount / permission) drops to the next tier with the same notice.

## 3. Dedup / append + attribution

- **Append-only.** Never modify or delete an existing entry. Append entries
  **chronologically** (newest at the end) for clean git diffs.
- **Auto entries dedupe:** before appending an `origin: auto` entry, read the
  existing `id:` values in the file and **skip** any that already exist (report
  `SKIP — already logged`). Because `id = <KEY>-<command>-<short-slug>` is
  stable, re-running a pipeline never double-logs.
- **Manual (`/feedback`) and prompt (`/prompt*`) entries are intentional** and
  are **never silently skipped.** On an `id` collision, append a numeric suffix
  (`-2`, `-3`, …) and warn if one looks near-identical.
- The file is created from the frontmatter template (§1) on first write.
- **Attribution:** `author` from `git config user.email` run in the specs repo
  (best-effort; `unknown` if unset). The *commit* author gives a second,
  authoritative layer once the engineer commits and pushes the specs.
  `plugin_version` is read at run time from
  `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
  (`python3 -c "import json;print(json.load(open('<path>'))['version'])"`).

## 4. Plugin-facing predicate — what persists

Persist **only** signals about the dev-workflows plugin itself:

- Command workflow improvements (a command should behave differently — e.g. the
  `saas|managed` scoping case).
- New agents / skills the plugin should offer.
- Gaps in the plugin's own reference docs (`${CLAUDE_PLUGIN_ROOT}/references/**`).
- Corrective interactions captured by `/prompt*` (any command output the user
  had to fix).

**Do NOT persist target-project tooling advice** — project `CLAUDE.md` rules,
target-repo hooks, and other repo-specific suggestions stay in
`impl-maintenance`'s in-session report, not the feedback file. That advice is
for the engineer's current repo, not the plugin maintainer.

When projecting an `impl-maintenance` report (§6 `emit-auto`), the plugin-facing
slice is exactly its **Command workflow improvements**, **New agents / skills**,
and **Reference docs** (paths under `${CLAUDE_PLUGIN_ROOT}`) sections, plus the
**Key observations** that triggered them. Discard its **CLAUDE.md rules** and
**Hooks** sections (target-project advice).

## 5. Interaction model — silent, high-recall

No curation/approval gate on capture. Capture is high-recall and zero-friction;
curation is the maintainer's job, centrally, at analysis time. A non-expert
engineer asked to approve/select/edit would rubber-stamp or drop the exact
signal the maintainer needs.

- **Automatic (`emit-auto`)** entries are written **silently**; the caller lists
  the persisted path (or "no plugin-facing signal — nothing persisted") in its
  output. A routine session with no plugin-facing signal writes nothing — no
  empty entry, byte-identical to today's report-only behavior.
- **`/feedback` and `/prompt*`** are user-invoked, so invocation *is* the
  intent; they write silently and surface the resulting path (and any
  degradation notice) in the command output.
- **`emit-block`** writes silently exactly like `emit-auto`; the halt is
  surfaced by the caller's existing `BLOCKED` escalation, **not** by a feedback
  prompt — capture-at-block stays inside the silent model (no interrupt beyond
  the block that was already happening, no curation gate).

## 6. Caller contract

Three named entry points. Every caller supplies `plugin_version` (§3) and lets
this reference resolve the target (§2), dedupe/append (§3), and format the entry
(§1). None of them commits; none writes into a docs/code repo or the current
working directory.

### `emit-auto` — automatic callers (the ten commands' maintenance phases)

Inputs: the `impl-maintenance` **Lessons Learned report**, `command` (the exact
slash-command name), `jira_key` (or `null`), `source` (`vault | directory |
none`).

Behavior: project the plugin-facing slice per §4 (Command workflow improvements
+ New agents / skills + plugin Reference docs + the triggering Key observations);
render one `origin: auto` entry per distinct plugin-facing signal (Friction =
the observation, Suggested improvement = the suggestion); dedupe by stable `id`
(§3); resolve the target (§2); write silently (§5). Return the persisted path,
or "no plugin-facing signal — nothing persisted" when the slice is empty.

### `emit-manual` — `/feedback`

Inputs: `command` (the exact name, or `n/a`), the user-authored **Friction** and
**Suggested improvement** prose, an inferred-and-confirmed `category` (§1 vocab),
`impact`, `jira_key` (or `null`), `source`.

Behavior: `origin: manual`; never silently skipped (§3 collision rule); resolve
the target (§2); write; surface the path + any degradation notice.

### `emit-prompt` — `/prompt`, `/prompt-brainstorm`, `/prompt-grill-me`

Inputs: `command` (inferred from recent context, or `n/a`), the **corrective
triple** — Friction, the **verbatim User prompt**, and the Resolution — a
`category`, `impact`, `jira_key` (or `null`), `source`.

Behavior: `origin: prompt`; write the entry with the two extra prose blocks
(User prompt verbatim + Resolution, §1); never silently skipped (§3); resolve
the target (§2); write silently (§5); surface the path.

### `emit-block` — capture-at-block (a run halting on a plugin gap)

Inputs: `command` (exact slash-command name), `jira_key` (or `null`), `source`
(`vault | directory | none`), and the **halting gap** — a short description of
the plugin capability / reference / skill / command-path the run needed but the
plugin lacked. Unlike `emit-auto`, no `impl-maintenance` report exists (the run
is being abandoned mid-flight), so the gap is passed directly.

Behavior: render **one** entry with `origin: auto` and **`impact: blocker`**;
`category` from the §1 vocab (`missing-capability` / `missing-reference-doc` /
`manual-workaround` / `model-routing` as fits); dedupe by the stable `id` (§3) —
so it will not double-log if a later terminal `emit-auto` captures the same gap
on a resumed run; resolve the target (§2); **write silently** (§5). Return the
persisted path (for the caller's block message / report). The caller then
surfaces its normal `BLOCKED` escalation — `emit-block` never prompts.

**Predicate — fires ONLY for a plugin-facing gap** (the plugin lacked something
the run needed). It does **NOT** fire for: a code / doc / Epic review **BLOCK**
(a defect in the *work*, not the plugin); an environment / user halt
(repo-missing, dirty-tree, jira-not-found, refresh-blocked, and the other
`escalation-rules.md` cases); or user cancellation. The §4 plugin-facing scoping
applies (never target-project `CLAUDE.md` / hook advice).
