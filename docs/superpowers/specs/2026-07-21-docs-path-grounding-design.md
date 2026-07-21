# `$DOCS_PATH` documentation grounding — design

- **Date:** 2026-07-21
- **Status:** Approved (brainstorming complete; ready for implementation plan)
- **Repo scope:** `plugins/dev-workflows/` only. `.ai-containers/` and the sibling
  repos (`ihudak-copilot-plugins`, `mgd-claude-plugins`) are follow-ups (see §10).
- **Target version:** dev-workflows 2.36.0

## Problem

Several authoring commands produce noticeably better output when the operator
manually adds *"please also check the documentation in `<dir>`"* to the prompt.
`/create-vi` without it is "ok"; with it, "fantastic". The lift comes from
grounding the artifact in the product's **existing shipped documentation** —
current behavior, customer-facing terminology, what already ships — which the
author would otherwise have to recall or rediscover.

The container platform now provides a `$DOCS_PATH` env var pointing at that
documentation. The commands should consume it **automatically** so the operator
never has to type the manual hint again.

## Goal / success criterion

The operator no longer types *"please also check the documentation in `<dir>`"*
to get the high-quality result. When `$DOCS_PATH` is set and valid, the named
commands ground on it by default and reconcile the draft against it.

## Scope

**In scope — seven commands gain docs grounding:**

| Command | Consumes the digest at |
|---|---|
| `/idea` | Phase 3 grill |
| `/create-vi` | Phase 3 grill |
| `/update-vi` | Phase 3 grill |
| `/create-ard` | Phase 4 grill |
| `/specify` | Phase 5 grill |
| `/epics` | Phase 6 Epic writing (no grill) |
| `/release-notes` | Phase 6 `release-notes-writer` handoff (no grill) |

**In scope — `/document` consolidation (not grounding):** `$DOCS_PATH` becomes
the first-choice hint for the docs-repo it already resolves in Phase 0. See §4.

**Out of scope:**

- Full docs grounding for `/document` — it already reads neighboring pages via
  `doc-location-finder` and `counterpart-finder`; adding `docs-grounder` would be
  redundant. Only the discovery-hint consolidation applies.
- `.ai-containers/` wiring (documented as a contract in §7; the operator wires it).
- Sibling-repo ports (§10).

## Environment reality (constrains the design)

- `$DOCS_PATH` is a **full `dynatrace-docs` clone** — thousands of pages under
  `dynatrace/_content/` and `managed/_content/`. **Never readable wholesale**;
  retrieval must be targeted and the result bounded.
- `$DOCS_PATH` is a **single directory** (not a colon-separated list).
- `$DOCS_PATH` is **the same directory `/document` writes into**, differing only
  in use: the seven commands read it as reference; `/document` writes via its own
  resolved `docs_repo_path`.
- **Mount mode is not a plugin invariant.** In an AI container `$DOCS_PATH` is
  mounted read-only; on a host, or when it is a `/document` workdir, it may be
  writable. The seven commands treat it as **reference-only regardless of mount**
  — they must neither depend on read-only nor be surprised by writable.
- `qmd` (Quick Markdown Search — hybrid BM25 + vector + rerank over local GGUF
  models) is installed in the container (`build.sh INSTALL_QMD`, `sandbox.conf
  qmd=ON`) and already used by the `obsidian-llm-wiki` plugin's `wiki-query`
  skill. Its index lives at `~/.cache/qmd/index.sqlite` — **outside** the
  collection directory — so a read-only `$DOCS_PATH` indexes fine.

## Architecture — Approach A: shared reference + one agent + thin wiring

Mirrors the proven `$REPOS_PATH` + `code-scanner` shape already in the plugin.

### 1. `references/docs-grounding.md` (new, ~40 lines)

Single source of truth for **is docs grounding on, and against what root?**
Modeled on `references/vi-source-resolution.md`.

- **Resolution:** read `${DOCS_PATH:-}`. Single directory.
- **Validity gate — ON only when all hold:**
  1. `$DOCS_PATH` is set and non-empty,
  2. it is an existing, readable directory,
  3. it contains at least one markdown file.
  Otherwise → `docs_grounding: OFF` with a one-line reason.
- **Flags:** `--no-docs` forces OFF; `--docs <path>` overrides the root (validated
  by the same gate).
- **Default ON when valid**, surfaced at plan approval with an off switch —
  mirroring `/epics`' "Code examination on/off (default ON)".
- **Read-only, always.** The seven commands never write into `$DOCS_PATH`.
- **Every miss is a silent, non-blocking skip** — never an error, never
  `emit-block`. An absent or irrelevant docs tree is a normal environment, not a
  plugin gap.

### 2. `agents/docs-grounder.md` (new, read-only subagent)

Structurally a sibling of `counterpart-finder` (read-only, keyword-overlap
scoring, returns a grounding digest) but **decoupled** from `/document`'s
space/docstack model. It borrows `doc-location-finder`'s scoring technique **by
reference**, not by code reuse.

**Tools:** `["Read", "Glob", "Grep", "LS", "Bash"]` (Bash for both `qmd` CLI and
`git log --grep`). Model tier assigned by the caller per model-routing (no pin).

**Inputs:**

```yaml
docs_path:       <resolved single directory>
feature_summary: <2–4 sentences: Jira/idea goal + themes>
jira_key:        <optional — enables the git-grep backstop>
themes:          <optional capability themes from the caller>
```

**Two-path retrieval** (copies the `wiki-query` Path A / Path B pattern):

- **Path A — qmd (preferred).** When the `qmd` binary is available and a `docs`
  collection is registered: query via the **Bash CLI** (`qmd query <q>` for
  ranked hits, `qmd get <file>` for content). CLI, not MCP — a subagent has Bash
  but not the session's MCP tools; the CLI works identically in-container and on a
  host. **Self-heal:** if the collection is missing, the agent registers it
  (`qmd collection add <docs_path> --name docs` + embed); if stale, it runs
  `qmd update` (**never `--pull`** — that needs write access to the clone). On any
  qmd failure, fall through to Path B.
- **Path B — fallback.** No qmd binary, `qmd=OFF`, or Path A failed: keyword-
  overlap scoring over frontmatter + first body lines (the `doc-location-finder`
  technique) plus a `git log --all -E --grep=<jira_key>` backstop. The backstop is
  **best-effort** — a git failure (e.g. odd read-only mount) degrades to
  keyword-overlap only, never an error.

**Bounding (must not crowd out the Jira/idea content in a grill):** read at most
the top 8 pages; `docs_references[]` capped at 8; `docs_challenges[]` capped at 5
and severity-ranked; each `salient_summary` ≤150 words.

**Output contract:**

```yaml
status: OK | EMPTY | ERROR
retrieval: qmd | fallback          # honest record of which path ran
docs_references:
  - path:            <absolute path>
    salient_summary: <≤150 words: concepts, current behavior, verified facts>
    section_outline: [<heading>, ...]
    terminology:     [<customer-facing term the docs use>, ...]
    match_confidence: high | medium | low
    match_reason:    <why this page matched>
docs_challenges:                    # the part that reproduces the manual-prompt lift
  - kind:      already_documented | terminology_mismatch | contradicts_documented_behavior | adjacent_undocumented
    challenge: <the reconciliation question to put to the author>
    evidence:  { path: <page>, quoted_line: <verbatim line from the docs> }
    severity:  high | medium | low
notes: <when EMPTY: why nothing found; when a path degraded: which and why>
```

`kind` semantics:
- `already_documented` — this capability appears to ship already; how is the new
  work different?
- `terminology_mismatch` — the docs call it X; the draft calls it Z.
- `contradicts_documented_behavior` — the draft asserts behavior the docs
  describe differently.
- `adjacent_undocumented` — a closely related area the docs do **not** cover
  (a scope/opportunity signal).

**Hard rules:** never writes or edits any file; advisory only — never a gate;
never HTTPS/REST (git and qmd CLI are local); challenges are advisory
reconciliation prompts, never auto-applied edits.

### 3. Per-command wiring (three small edits each)

Every command gets the same three edits, differing only in the dispatch point:

1. **Resolve** in the inputs/config phase via `references/docs-grounding.md`.
2. **Surface at plan approval** — `docs_grounding: ON/OFF (root)` with an off
   switch.
3. **Dispatch `docs-grounder`** before the grill / writer.

| Command | Dispatch point | Digest feeds |
|---|---|---|
| `/idea` | new Phase 2.5, after `idea-reader` | Phase 3 grill gap list |
| `/create-vi` | new Phase 2.5, after "Read the seed" | Phase 3 grill |
| `/update-vi` | Phase 2, alongside existing grounding | Phase 3 grill |
| `/create-ard` | Phase 3, with repo grounding | Phase 4 grill |
| `/specify` | Phase 4, parallel with `code-scanner` | Phase 5 grill |
| `/epics` | Phase 5, parallel with code scanning | Phase 6 Epic writing |
| `/release-notes` | new Phase 5.5 | Phase 6 writer handoff |

**Consuming `docs_challenges`:**

- **Five grill commands** (`/idea`, `/create-vi`, `/update-vi`, `/create-ard`,
  `/specify`) **rank** the challenges into their existing Impact × Uncertainty
  gap list — they do **not** append. This preserves `/idea`'s ≤5-question bound:
  a docs challenge competes for a slot, it doesn't add one.
- **Two non-grill commands** (`/epics`, `/release-notes`) pass the digest straight
  into the writer handoff (`epic-writer` / `release-notes-writer` input contract).

## 4. `/document` discovery-hint consolidation

`/document` Phase 0 step (b) currently searches `${REPOS_PATH:-/workspace}` for a
`dynatrace-docs` clone. Change: **prefer `$DOCS_PATH` first** when it is set and
recognizes as dynatrace-docs (the existing `is_dynatrace_docs` signal check),
then fall back to today's `$REPOS_PATH` search. This is the *only* `/document`
change — no `docs-grounder` dispatch, no grounding. Purely a first-choice hint
for the write target it already resolves.

## 5. Data flow

```
$DOCS_PATH ──(docs-grounding.md gate)──> docs_grounding ON/OFF
                                            │ ON
                            caller dispatches docs-grounder
                                            │
                    Path A (qmd CLI) ─or─ Path B (keyword + git-grep)
                                            │
                        { docs_references[], docs_challenges[] }
                                            │
        grill commands: rank challenges into Impact×Uncertainty gap list
        writer commands: attach digest to epic-writer / release-notes-writer input
```

## 6. Failure modes / invariants

**Governing invariant: docs grounding never blocks a run, and never degrades it
below today's behavior.**

| Condition | Behavior |
|---|---|
| `$DOCS_PATH` unset / missing / no markdown | OFF, one line at plan approval |
| `--no-docs` | OFF |
| qmd absent or `qmd=OFF` | Path B fallback, `retrieval: fallback` |
| qmd collection missing | agent registers it; on failure → Path B |
| qmd index stale | `qmd update` (never `--pull`) |
| `git log --grep` fails (read-only mount edge) | keyword-overlap only, best-effort |
| nothing relevant found | `status: EMPTY`, run proceeds as today |
| `docs-grounder` errors | OFF, run proceeds as today |

## 7. Container contract (documented; operator wires it — not edited here)

For the container team, so the optimization is available. Because indexing uses
**container wiring + agent self-heal**, the plugin is fully correct before any of
this is wired — the container side only moves the one-time indexing cost to
startup.

- Mount `$DOCS_PATH` (read-only is fine) and re-export it into the container,
  parallel to how `VAULT_PATH`/`SPECS_PATH` are handled in `runme.sh`.
- Register a qmd collection named `docs` from `$DOCS_PATH` at container start and
  embed it.
- Emit a `qmd=OFF` warning when `$DOCS_PATH` is set but qmd is off — mirroring the
  existing `VAULT_PATH`-with-`qmd=OFF` warning at `runme.sh:522`.
- **Dependency is the `qmd` binary, not a qmd skill.** No skill is bundled or
  installed (see §9).

## 8. Verification

This change is prompt/reference content, so the repo's code-test requirement does
not apply. Three checks instead:

1. **Frontmatter valid** on the new `agents/docs-grounder.md` (YAML `---`, `name`,
   `description`, `tools`).
2. **Cross-reference integrity** per the CLAUDE.md "Surgical Changes" rule: the
   CLAUDE.md workflow map, README, and invariants sections all updated in the same
   change; the seven command files, the new reference, and the new agent all
   cross-reference consistently (no dangling edge).
3. **Behavioral smoke test:** run `/create-vi` with `$DOCS_PATH` **unset** and
   confirm byte-for-byte today's behavior (grounding silently OFF); then set a
   small docs dir and confirm challenges surface in the grill.

## 9. qmd skill decision — no skill installed

The bundled qmd skills are `qmd` (general search) and `release` (irrelevant).
**Neither is installed.** `docs-grounder` embeds retrieval mechanics directly and
calls qmd via the Bash CLI. Rationale:

- **Precedent:** `obsidian-llm-wiki`'s `wiki-query` uses the qmd interface
  directly with its own Path A/B logic; it does not vendor the qmd skill.
- **Shape:** the bundled `qmd` skill is a user-facing interactive search skill —
  wrong for a subagent doing one bounded retrieval.
- **CLI over MCP:** a subagent has Bash but not the session's MCP tools; the CLI
  works identically in-container and on a host, and degrades cleanly when the
  binary is absent.

README mentions the `qmd` **binary** as an optional host prerequisite (one line):
optional; enables semantic docs grounding; without it the command uses keyword
fallback.

## 10. Out of scope / follow-ups

- **`.ai-containers/` wiring** — per §7 contract; operator handles it.
- **Sibling repos** (`ihudak-copilot-plugins`, `mgd-claude-plugins`) — port as a
  separate change, consistent with prior cross-repo ports. Note: Copilot has no
  subagents/MCP the same way — the port there may need the fallback-only path.
- **Docs grounding for `/document`** proper — deliberately excluded (§3 covers
  only the discovery hint).

## Decision log

- **Docs shape:** full `dynatrace-docs` clone → targeted retrieval + bounded
  digest mandatory.
- **Extra scope beyond the original four:** added `/specify`, `/epics`,
  `/create-ard`; excluded `/document` grounding.
- **Assertiveness:** additive **+ challenge the grill** (reproduces the manual-
  prompt lift); not reviewer-enforced (kept advisory to limit cost/wiring).
- **Approach A** over inline-per-command (B, context-cost) and generalizing
  `counterpart-finder` (C, superficial reuse).
- **Read-only is a mount property, not a plugin invariant.**
- **Single directory**, not colon-separated.
- **qmd two-path retrieval**; no writable mount needed (index in `~/.cache/qmd`).
- **Indexing:** container wiring + agent self-heal.
- **Repo scope:** plugin only; container contract documented.
- **No qmd skill installed;** CLI via Bash.
