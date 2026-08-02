---
tags:
  - spec
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-29
---

# dev-workflows — Shared Jira-input resolution front-end (Effort B2) (design)

## Context

`/implement` and `/document` both work from the **same** Jira input — a Jira
ticket hierarchy exported to markdown by the **`jira-workitem-import`** tool
(https://github.com/ivan-gudak/jira-workitem-import) — which imports tickets from
Jira into `$VAULT_PATH/jira-products/<KEY>/` and maintains the index (Value
Increment, Epics, Stories, Sub-tasks, attachments). A ticket's structure is identical
whether or not it carries PR links (PR links are just an optional section), so
the same exported hierarchy feeds both commands. Yet today the two commands
accept and parse input **differently**:

- **`/document`** (Mode A) takes a bare **JiraID**, resolves `$VAULT_PATH` →
  `jira-products/<KEY>/`, scans for a specs dir, and runs the Jira-driven doc
  pipeline. It does **not** accept a directory.
- **`/implement`** takes free-text prose + `@path` tokens (spec folder / Jira
  ticket folder / code repo, classified by inspection) but does **not** discover
  a bare JiraID.

The `$VAULT_PATH` + `jira-products/<KEY>/` resolution is duplicated across
`/document`, `/epics`, `/release-notes`, and the `jira-reader` input contract.
`/document`'s Phase 0 is ~85 lines, much of it this resolution — the source of
the "large `document.md`" concern flagged during the B1 command-surface
redesign.

This effort extracts a **shared Jira-input resolution front-end** into a
reference that both `/implement` and `/document` cite, giving them one identical
input grammar (JiraID **or** directory **or** direct prompt) and slimming both
command files. Plugin `main` at `6da1783` (v2.0.1). Release: **MINOR `v2.1.0`**
(purely additive — every existing invocation still works).

## Goals

- One **shared reference** (`references/jira-input-resolution.md`) defining the
  input grammar, the resolution algorithm, the normalized output contract, and
  the fallback prompts. Both commands' Phase 0 cite and execute it.
- **Identical parameter grammar** for `/implement` and `/document`: a token list
  where each token is a JiraID, a path/`@path`, or free-text, plus
  command-specific trailing options. Same parser, same classification.
- **Directory input** (the new capability): accept an imported-Jira directory —
  the same exporter output rooted anywhere — so the commands work when
  `$VAULT_PATH` is unset/absent or a ticket was imported elsewhere.
- **JiraID discovery for `/implement`** (the other new capability): a bare
  JiraID triggers the same `$VAULT_PATH` discovery `/document` already does.
- **`SPECS_PATH`** — a first-class AI-Containers env var (same rules as
  `VAULT_PATH`; mounted to `/workspace/specs` in-container, an arbitrary dir on a
  host) as the deterministic specs source, replacing the old `REPOS_PATH`
  name-search; ask the user on a miss.
- **Specs required for `/implement`** (jira-driven), additive for `/document`.
- Slim both command Phase 0 sections by replacing duplicated resolution with a
  citation.

## Non-goals (recorded as future work)

- **`/epics` + `/release-notes` adoption.** The reference is *designed* to be
  adoptable by them later, but this effort wires only `/implement` + `/document`.
- **Projects/Products removal.** Dropped from the *shared* front-end (it resolves
  no `workdir`). `/document` keeps its existing command-local use of the
  persistent Obsidian project folder (`$VAULT_PATH/Projects/Products/**/<KEY>*`)
  for **screenshot staging** and the **`<KEY>-implementation-gaps.md`
  destination** — **unchanged**. Removing/rewiring that (screenshots → source
  attachment paths; gaps → report-only or a chosen space) is a deferred
  follow-up; gaps in particular need a real persistent space, so this may stay.
- **"Brainstorm spec + dev-plan from a Jira ticket" command(s).** A future
  release will add one or two commands that generate the spec + dev plan from a
  Jira ticket (the upstream of `/implement`'s now-required specs). Out of scope.
- No changes to either command's **downstream** pipeline (doc synthesis / code
  implementation), to `/document`'s docs-repo/profile/write-context/space
  resolution, or to the `jira-reader` reading logic itself.

## Design

### A. Form — a shared reference, not a subagent

The front-end is inherently **interactive** (resolve `$VAULT_PATH`, prompt when
unset, disambiguate multiple matches, gate on required specs). Subagents handle
interactive prompting poorly. So the mechanics live in a new top-level reference
`references/jira-input-resolution.md` that **both commands' Phase 0 cite and
execute inline** — the established pattern (`finish-and-handoff.md`,
`render-verification.md`). The orchestrator owns all prompts; the reference
defines the algorithm and the normalized output contract each command consumes.
*(Rejected: a discovery subagent — wrong fit for interactive resolution. No
command-level snippet-include mechanism exists in this plugin.)*

### B. Unified parameter grammar + mode classifier

`$ARGUMENTS` is a token list. Each token is classified:

- **JiraID** — matches `^[A-Z][A-Z0-9]+-[0-9]+`.
- **Path / `@path`** — a directory (or, in direct mode, a file).
- **Command-specific trailing option** — parsed by the command *after* the
  shared resolution (`/document`: optional `saas` | `managed`). Not the
  front-end's concern.
- **Free-text** — anything else.

The front-end decides a **`mode`**:

- **`jira-driven`** — any JiraID **or** any directory that inspects as a
  Jira-export (contains `<KEY>-index.md`).
- **`direct`** — no Jira input present: only free-text and/or a file/`@file`
  (a prompt, or a doc/spec to act on).

Both commands accept the **same** tokens and parse them the **same** way. Only
the downstream work differs:

| Input resolves to | `/document`                     | `/implement`                                  |
| ----------------- | ------------------------------- | --------------------------------------------- |
| `jira-driven`     | full Jira doc pipeline (Mode A) | full implement pipeline, folding Jira context |
| `direct`          | one-shot doc edit (Mode B)      | existing free-text/spec implement flow        |

`/document` keeps its **explicit Mode A / Mode B labels** (its two pipelines are
genuinely different); `/implement`'s single flow already absorbs the direct case
by complexity-branching, so it needs no visible "mode" — it just optionally
receives Jira context. The **parsing is identical**; the downstream structural
difference is pre-existing and justified.

### C. `/document` Mode-detection update

Today: JiraID → Mode A; `@file`/free-text → Mode B. Add one branch: a
**directory that inspects as a Jira-export** → **Mode A** (jira-driven via the
front-end). An `@file` or free-text → **Mode B** (its existing direct-edit
inputs). So "jira-driven" is triggered by *either* a JiraID *or* a Jira-export
directory — symmetric with `/implement`. A non-Jira-export directory is an
unusual `/document` input (directories of that shape — spec folders, code repos —
are primarily an `/implement` concern); when one is passed to `/document`, the
front-end reports it `direct` and Mode B handles it via its existing
"anything else" path rather than inventing new behavior.

### D. Resolution algorithm (executed by the orchestrator, per the reference)

1. **Tokenize `$ARGUMENTS`** and classify each token (§B).
2. **Decide `mode`** (§B).
3. **`jira-driven` — JiraID branch** (requires `$VAULT_PATH`):
   - `jira_export_root` = `$VAULT_PATH/jira-products/<KEY>` — validate it exists.
   - `specs` = resolve the ticket's specs/plans (§G).
4. **`jira-driven` — directory branch** (works *without* `$VAULT_PATH`):
   - Inspect-classify each passed directory: **jira-export** (`<KEY>-index.md`;
     derive `<KEY>` from the index / the nested `<KEY>/` subdir) | **spec-folder**
     (`prompt.md` / `*-design.md`) | other. This is the same content-inspection
     `/implement`'s Phase 0 already performs for `@dir`.
   - `jira_export_root` = the jira-export directory.
   - `specs` = a passed spec-folder, or specs copied inside the jira-export dir
     (§G).
5. **`direct`** — collect the free-text prose and file(s); no Jira/specs.
6. **Feed `jira-reader`** (jira-driven only) the resolved **`jira_export_root`**
   (§H).

**Multiple tokens resolve additively.** The jira-export source (a JiraID *or* a
Jira-export directory — exactly one is expected) fixes `jira_key` +
`jira_export_root`; any *additional* directory token is classified and merged —
a passed **spec-folder** contributes to / overrides `specs` (so
`PRODUCT-123 @/path/to/specs` and the multi-directory form
`@/path/to/jira-export @/path/to/specs` both work). If two tokens both inspect as
jira-exports, disambiguate (fallback prompts below).

**Fallback prompts** (orchestrator-owned, unified):
- JiraID given but `$VAULT_PATH` unset/absent → ask to set it or pass a directory.
- JiraID-shaped but `jira-products/<KEY>` missing → today's `/document` prompt
  (`["Re-enter the Jira key", "Treat as a direct edit instead", "Cancel"]`).
- Multiple jira-export directories → disambiguate.

### E. Normalized output contract

The reference returns one shape; each command consumes its subset:

```
mode:             jira-driven | direct
source:           vault | directory | none
jira_key:         <KEY> | null
jira_export_root: <abs path to the ticket export dir> | null   # → jira-reader
specs:            [<abs paths>]    # specs/plans (additive); may be []
direct_prompt:    <free-text> | null
direct_files:     [<abs paths>]
```

No `workdir` field (Projects/Products is not a shared concern — see Non-goals).

### F. Per-command consumption + specs requiredness

| Field | `/document` | `/implement` |
|---|---|---|
| `jira_export_root` | Phase 3 `jira-reader` (`depth: full`) | Phase 1.7 `jira-reader` fan-out |
| `specs` | Phase 5.7 **additive** context | folded into the implementation description |
| `direct_prompt` / `direct_files` | Mode B one-shot edit | existing free-text/spec flow |
| trailing `saas\|managed` | parsed by `/document`, post-resolution | n/a |

The front-end is **neutral** on specs — it resolves them and reports `[]` when
none are found. **Requiredness is a per-command policy on the result:**

- **`/document`** — `specs: []` → proceed (additive). Unchanged.
- **`/implement` (jira-driven)** — specs are the source of truth (no code in the
  input, especially for a ValueIncrement). `specs: []` → **required**, so it
  prompts rather than proceeding blind:
  `choices: ["Point me at a specs directory (you'll provide the path)", "Proceed without specs — not recommended", "Cancel"]`
  Required-with-explicit-override, not a brittle hard stop. `/implement`
  **direct mode** is unaffected (the prompt itself is the instruction).

### G. Specs resolution + `SPECS_PATH`

`SPECS_PATH` is a first-class AI-Containers environment variable governed by the
**same rules as `VAULT_PATH`** — the host provides it and it is mounted into the
container (at `/workspace/specs` in Ai-Containers; an arbitrary directory on a
host). It is the deterministic source for a ticket's specifications, replacing
the previous `${REPOS_PATH}` name-search (e.g. `/workspace/mgd-specifications`).

Specs are resolved (try first; the on-miss prompt is each command's policy, §F):

1. If **`$SPECS_PATH`** is set → look for the ticket's specs at
   `$SPECS_PATH/{specs|specifications|vis}/…/<JIRA_KEY>{-|_}<slug>/…/*.md` — a
   `specs`/`specifications`/`vis` root inside `$SPECS_PATH`, then a
   `<JIRA_KEY>`-prefixed folder (tolerate `-`/`_` separators and a trailing slug)
   holding the `.md` specs/plans. Shared by **both** commands.
2. Directory-input case → a passed spec-folder (`prompt.md` / `*-design.md`), or
   specs copied into the imported-jira directory.
3. `SPECS_PATH` unset, or set but no `<JIRA_KEY>` match → `specs: []`, and the
   consuming command applies its policy: **`/implement` asks the user where the
   specs are** (§F's required-with-override prompt); **`/document` proceeds**
   (additive).

### H. `jira-reader` additive input

`jira-reader` today constructs `<vault_path>/jira-products/<jira_key>/…`. Add an
**additive** input — `jira_export_root` (the resolved ticket export directory) —
that, when present, is used directly instead of the
`<vault_path>/jira-products/<jira_key>` construction. The front-end (used by
`/implement` + `/document`) passes `jira_export_root`. **`/epics` and
`/release-notes` are untouched** — they keep passing `vault_path` + `jira_key`,
which the existing construction still serves (back-compat). The
`references/handoff/jira-reader.md` contract doc is updated accordingly.

## Touch list

- **NEW `references/jira-input-resolution.md`** — algorithm, output contract,
  fallback prompts, `VAULT_PATH` (Jira-input) + `SPECS_PATH` (specs) semantics.
  (`REPOS_PATH` is *not* a front-end concern — it stays command-local for
  docs-repo / code-repo discovery.)
- **`commands/document.md`** — Mode-detection gains the Jira-export-dir→Mode A
  branch; Phase 0 replaces steps 1–2 (vault+key) + step 6 (specs) with a
  citation + contract consumption; **keeps** steps 3–5 (docs repo/profile), 7
  (write-context), 8 (space) and the Projects/Products staging + gaps use
  (unchanged); Phase 3 passes `jira_export_root` to `jira-reader`.
- **`commands/implement.md`** — Phase 0 cites the reference; gains JiraID +
  Jira-export-dir recognition (unifying its `@dir` classifier as the directory
  branch); jira-driven adds the specs-required gate; Phase 1.7 passes
  `jira_export_root` to the `jira-reader` fan-out; direct/code-repo flow
  unchanged.
- **`agents/jira-reader.md`** + **`references/handoff/jira-reader.md`** — additive
  `jira_export_root` input; `/epics` + `/release-notes` unchanged.
- **`hooks/preload-context.sh`** — extend so `/implement <JiraID>` also preloads
  Jira context, and the directory case is handled.
- **Manifests + README + CHANGELOG** — `v2.1.0`; document `SPECS_PATH` as an
  AI-Containers env var (same rules as `VAULT_PATH`; `/workspace/specs`
  in-container) alongside `VAULT_PATH` / `REPOS_PATH`; reference the
  `jira-workitem-import` tool (https://github.com/ivan-gudak/jira-workitem-import)
  so users know how `$VAULT_PATH/jira-products/` is populated; refresh the
  `/document` + `/implement` input-grammar rows.

## Risks & mitigations

- **Two commands changed at once.** Mitigation: the shared reference is the
  single source of the resolution; each command's change is a Phase 0 citation +
  contract consumption. Per-command behavior outside Phase 0 is untouched.
  Structural verification (grep anchors; the reference cited by both; the contract
  fields consumed) plus a functional hook test.
- **`jira-reader` contract change leaking to `/epics`/`/release-notes`.**
  Mitigation: the `jira_export_root` input is purely **additive**; the existing
  `vault_path` + `jira_key` construction is preserved. Verify by confirming the
  `/epics` and `/release-notes` dispatch blocks are byte-unchanged (they still
  pass `vault_path` + `jira_key`) and that the agent keeps the old construction
  alongside the new param.
- **Specs-resolution behavior change (`/document`).** Replacing the
  `${REPOS_PATH}` vis-root name-search with `$SPECS_PATH` changes how `/document`
  finds specs. Mitigation: specs are **additive** for `/document` (a miss → `[]`
  → proceed, no hard break); `SPECS_PATH` is the new AI-Containers standard
  (host-provided, mounted `/workspace/specs`) and is documented in the README;
  the directory-input spec-folder path and the `/implement` ask-gate cover the
  unset/miss cases. Verify the layout matcher
  (`$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md`) tolerates
  the `-`/`_` separator and trailing-slug variants.
- **Mode-detection regression in `/document`.** Adding the directory branch must
  not reclassify existing JiraID or `@file`/free-text inputs. Mitigation: the new
  branch is gated strictly on "directory that contains `<KEY>-index.md`"; verify
  the three existing cases (JiraID→A, `@file`→B, free-text→B) still route as
  before.
- **`/implement` specs-required gate over-blocking.** Mitigation: required *with*
  an explicit override + the directory-input escape (pass a specs dir); direct
  mode exempt.
- **Behavior drift / scope creep.** Mitigation: the Non-goals list is explicit
  (no Projects/Products removal, no `/epics`/`/release-notes` wiring, no
  downstream pipeline change).

## Invariants preserved

- Zero external API; existing invocations unchanged (additive MINOR release).
- `/document` Mode A/B pipelines, multi-space writing, render verification,
  finish-and-handoff, model routing, and the v2.0.x phase numbering are all
  untouched outside the Phase 0 citation.
- `jira-reader` reading logic, depths, and the `/epics` + `/release-notes`
  contracts are unchanged.
- The shared front-end is **neutral** (resolves; does not enforce policy);
  requiredness lives in each consumer.

## Open items

- None — scope (two commands), directory layout (exporter output rooted
  anywhere), resolver boundary (Jira-input + specs; no workdir), classification
  (inspect-by-content), the direct/jira-driven symmetry, specs requiredness
  (required-with-override for `/implement`), `SPECS_PATH`, and the
  Projects/Products deferral are all settled.
