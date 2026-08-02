---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-06-29
---

# Effort B2 — Shared Jira-input resolution front-end Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `/implement` and `/document` one identical Jira-input grammar (JiraID **or** imported-Jira directory **or** direct prompt) via a shared reference, adding JiraID-discovery to `/implement` and directory-input to `/document`, plus an `SPECS_PATH` env var and a required-specs gate for `/implement`.

**Architecture:** A new reference `references/jira-input-resolution.md` defines the input grammar, resolution algorithm, fallback prompts, and a normalized output contract. Both commands' Phase 0 cite and execute it (the orchestrator owns all prompts) and consume the contract; each layers its own downstream work. `jira-reader` gains an additive `jira_export_root` input so a directory-rooted export feeds it. Purely additive — every existing invocation still works.

**Tech Stack:** Markdown command/agent/reference files + one bash hook in the `dev-workflows` Claude Code plugin (`/workspace/ihudak-claude-plugins/plugins/dev-workflows`). No test framework — verification is **structural** (grep anchors, `bash -n`, a functional hook test, `python3 -c json.load` for manifests).

## Global Constraints

- **Repo / branch:** work in `/workspace/ihudak-claude-plugins`. Branch off `origin/main` (`6da1783`, v2.1.0 target): `ivgu/NOISSUE-jira-input-resolution`. Never start on `main`.
- **Purely additive (MINOR `v2.1.0`).** Every existing invocation keeps working: `/document <JiraID> [saas|managed]`, `/document @file`/free-text, `/implement <free-text/@dir>`. New: `/implement <JiraID>`, `/document <jira-export-dir>`, `SPECS_PATH`.
- **Per-site bare "Phase"/token discipline:** the shared front-end resolves only Jira-input + specs. It uses `$VAULT_PATH` (JiraID branch) and `$SPECS_PATH` (specs). `$REPOS_PATH` stays **command-local** (docs-repo / code-repo discovery) — do NOT move it into the reference.
- **`jira-reader` change is additive.** Add `jira_export_root`; KEEP the `vault_path`+`jira_key` construction. `/epics` and `/release-notes` dispatch blocks must remain **byte-unchanged** (they keep passing `vault_path`+`jira_key`).
- **`/document` keeps unchanged:** its docs-repo/profile/write-context/space resolution (Phase 0 steps 3–5, 7, 8) and its Projects/Products screenshot-staging + `<KEY>-implementation-gaps.md` use. Only steps 1–2 (vault+key) and step 6 (specs) are replaced by the reference citation.
- **Importer attribution:** the Jira export under `$VAULT_PATH/jira-products/` is produced by the **`jira-workitem-import`** tool (https://github.com/ivan-gudak/jira-workitem-import) — never call it "the Obsidian importer."
- **Commit hygiene:** stage explicit paths only — never `git add -A`, never `.superpowers/` or `.docstack`. Commit trailer on every commit:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
  This plugin repo has **no** husky/prettier hook (verified during B1b) — commits run clean, no `--no-verify` needed.

## The normalized output contract (every task references this)

```
mode:             jira-driven | direct
source:           vault | directory | none
jira_key:         <KEY> | null
jira_export_root: <abs path to the ticket export dir> | null   # → jira-reader
specs:            [<abs paths>]    # specs/plans; may be []
direct_prompt:    <free-text> | null
direct_files:     [<abs paths>]
```

`SPECS_PATH` specs layout: `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md`.

---

## Task 1: NEW `references/jira-input-resolution.md`

**Files:**
- Create: `plugins/dev-workflows/references/jira-input-resolution.md`

**Interfaces:**
- Produces: the resolution algorithm + the normalized output contract that Tasks 3 (`document.md`) and 4 (`implement.md`) cite and consume, and the `jira_export_root` field Task 2 (`jira-reader`) implements.

**Model suggestion:** Opus (authoring the keystone contract).

- [ ] **Step 1: Branch**

```bash
cd /workspace/ihudak-claude-plugins
git fetch origin
git switch -c ivgu/NOISSUE-jira-input-resolution origin/main
git log --oneline -1   # expect 6da1783
```

- [ ] **Step 2: Write the reference**

Create `plugins/dev-workflows/references/jira-input-resolution.md` with exactly this content:

````markdown
# Jira-input resolution (shared front-end)

Shared input-resolution mechanics for `/implement` and `/document`. The command's
Phase 0 **cites this file and executes these steps inline** — the orchestrator
owns every prompt. Both commands parse `$ARGUMENTS` identically and consume the
normalized output contract (§ Output contract); each then layers its own
downstream work. `/epics` and `/release-notes` do **not** use this yet (the
reference is written to be adoptable by them later).

## Input grammar

`$ARGUMENTS` is a whitespace-separated token list. Classify each token:

- **JiraID** — matches `^[A-Z][A-Z0-9]+-[0-9]+`.
- **Path** — a `@path` token, or a bare path that exists on disk (a directory; or,
  in direct mode, a file).
- **Command-specific trailing option** — consumed by the command *after* this
  resolution (`/document`: an optional `saas` | `managed` token). Not resolved here.
- **Free-text** — anything else (the direct-mode prompt).

## Mode decision

- **`jira-driven`** — at least one JiraID token, **or** at least one directory that
  inspects as a **jira-export** (contains `<KEY>-index.md`).
- **`direct`** — no Jira input: only free-text and/or a file token.

## Resolution

### jira-driven — JiraID token (requires `$VAULT_PATH`)

1. Resolve `$VAULT_PATH` (env). Unset/absent → **Fallback A**.
2. `jira_export_root` = `$VAULT_PATH/jira-products/<KEY>` — validate it exists and
   contains `<KEY>-index.md`. Missing → **Fallback B**.
3. `jira_key` = `<KEY>`; `source = vault`.
4. Resolve `specs` (§ Specs resolution).

### jira-driven — directory token (works *without* `$VAULT_PATH`)

Inspect-classify each path token **by content, not by name** (this is the same
classification `/implement` performs for `@dir`):

- **jira-export** — a directory containing `<KEY>-index.md` (or ticket-key
  subdirectories each containing `<KEY>.md`). `jira_export_root` = this directory;
  `jira_key` = `<KEY>` derived from the `<KEY>-index.md` basename / the nested
  `<KEY>/` subdirectory name; `source = directory`.
- **spec-folder** — a directory containing `prompt.md` and/or a `*-design.md`.
  Contributes to `specs`.
- **other** — surface to the user (never silently skip): ask whether to continue
  without it or stop.

Exactly one jira-export is expected; **≥ 2 → Fallback C**. Additional spec-folders
merge into `specs`. A JiraID **and** a spec-folder directory may be given together
(`PRODUCT-123 @/path/to/specs`): the JiraID fixes the hierarchy, the spec-folder
contributes/overrides `specs`.

### direct

Collect free-text prose into `direct_prompt` and any file tokens into
`direct_files`. No Jira/specs resolution.

## Specs resolution (jira-driven)

`SPECS_PATH` is an AI-Containers environment variable governed by the **same rules
as `VAULT_PATH`** — host-provided, mounted into the container (at
`/workspace/specs` in Ai-Containers; an arbitrary directory on a host). Resolve in
order:

1. **`$SPECS_PATH` set →** look for the ticket's specs at
   `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md` — a
   `specs`/`specifications`/`vis` root inside `$SPECS_PATH`, then a `<KEY>`-prefixed
   folder (tolerate `-`/`_` separators and a trailing slug) holding the `.md`
   specs/plans.
2. **Directory case →** a passed spec-folder, or specs found inside
   `jira_export_root`.
3. **None found →** `specs: []`. The **consuming command** applies its policy:
   `/implement` (jira-driven) prompts the user where the specs are
   (required-with-override); `/document` proceeds (additive).

## Fallback prompts (orchestrator-owned)

- **A — JiraID but no `$VAULT_PATH`:**
  `choices: ["Set VAULT_PATH (enter the path)", "Pass an imported-Jira directory instead", "Cancel"]`
- **B — JiraID-shaped but `jira-products/<KEY>` missing:**
  `choices: ["Re-enter the Jira key", "Treat the text as a direct edit instead", "Cancel"]`
- **C — multiple jira-export directories:** list them;
  `choices: ["<first> (Recommended)", "<other candidates…>", "Cancel"]`

## Output contract

The resolution yields one normalized shape; each command reads only the fields it
needs:

```
mode:             jira-driven | direct
source:           vault | directory | none
jira_key:         <KEY> | null
jira_export_root: <abs path to the ticket export dir> | null   # → jira-reader (jira_export_root input)
specs:            [<abs paths>]    # specs/plans; may be []
direct_prompt:    <free-text> | null
direct_files:     [<abs paths>]
```
````

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins
f=plugins/dev-workflows/references/jira-input-resolution.md
test -f "$f" && echo "exists"
grep -c 'jira-driven\|direct' "$f"                 # mode terms present
grep -n 'jira_export_root' "$f"                     # contract field present
grep -n 'SPECS_PATH/{specs|specifications|vis}' "$f"  # specs layout present
grep -nE 'Fallback A|Fallback B|Fallback C' "$f"    # all three fallbacks
grep -n 'jira-workitem-import' "$f" || echo "(tool ref not required in reference; fine)"
awk 'BEGIN{n=0} /^```/{n++} END{print "fences:", n}' "$f"  # even number
```
Expected: `exists`; mode terms > 0; `jira_export_root` present; specs-layout line present; all three fallbacks; fence count even.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/jira-input-resolution.md
git commit -m "$(cat <<'EOF'
PRODUCT v2.1.0: add references/jira-input-resolution.md (shared Jira-input front-end)

The keystone reference: input grammar (JiraID | imported-Jira directory |
direct prompt), the jira-driven|direct mode decision, the resolution algorithm
(VAULT_PATH JiraID branch + content-inspected directory branch), SPECS_PATH
specs resolution, fallback prompts, and the normalized output contract that
/document and /implement consume.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `jira-reader` additive `jira_export_root` input

**Files:**
- Modify: `plugins/dev-workflows/agents/jira-reader.md` (Inputs + Process read paths)
- Modify: `plugins/dev-workflows/references/handoff/jira-reader.md` (Input block)

**Interfaces:**
- Consumes: the `jira_export_root` field name from Task 1's contract.
- Produces: a `jira-reader` that reads from an explicit `jira_export_root` when given, else constructs `<vault_path>/jira-products/<jira_key>`. Tasks 3 and 4 pass `jira_export_root`.

**Model suggestion:** Opus (back-compat correctness across two consumers).

- [ ] **Step 1: Update the Inputs section of `agents/jira-reader.md`**

Replace the current Inputs block:

```
The caller passes:

\```yaml
vault_path: <absolute path, e.g. /home/user/obsidian-vault>
jira_key:   <e.g. JIRA-12345>
depth:      full | vi-plus-epics | vi-only
\```

Refuse to run without all three fields.
```

with:

```
The caller passes **either** an explicit export root (preferred — used by
`/document` and `/implement` via the shared `jira-input-resolution.md`
front-end) **or** a vault path + key (used by `/epics` and `/release-notes`):

\```yaml
# Form 1 — explicit export root:
jira_export_root: <absolute path to the ticket export dir, e.g. .../jira-products/PRODUCT-14902>
jira_key:         <e.g. JIRA-12345>
depth:            full | vi-plus-epics | vi-only

# Form 2 — vault + key (export root is derived as <vault_path>/jira-products/<jira_key>):
vault_path: <absolute path, e.g. /home/user/obsidian-vault>
jira_key:   <e.g. JIRA-12345>
depth:      full | vi-plus-epics | vi-only
\```

Resolve the **export root** once: `EXPORT_ROOT = jira_export_root` when provided,
else `<vault_path>/jira-products/<jira_key>`. All reads below use `EXPORT_ROOT`.
Refuse to run without `depth`, `jira_key`, and at least one of
`{jira_export_root, vault_path}`.
```

- [ ] **Step 2: Update the Process read paths in `agents/jira-reader.md`**

The three depth-read bullets and the index-read currently hardcode
`<vault_path>/jira-products/<jira_key>/…`. Re-root them on `EXPORT_ROOT`:

- Index read (step 1): `Open <vault_path>/jira-products/<jira_key>/<jira_key>-index.md` → `Open <EXPORT_ROOT>/<jira_key>-index.md`.
- `depth: full`: `<vault_path>/jira-products/<jira_key>/<LINKED_KEY>/<LINKED_KEY>.md` → `<EXPORT_ROOT>/<LINKED_KEY>/<LINKED_KEY>.md`; the VI nested path → `<EXPORT_ROOT>/<jira_key>/<jira_key>.md`.
- `depth: vi-plus-epics` and `depth: vi-only`: same substitution (`<vault_path>/jira-products/<jira_key>/` → `<EXPORT_ROOT>/`).
- The "Hard rules" line that says `NEVER look for <vault_path>/jira-products/<LINKED_KEY>/…` → reword to `<EXPORT_ROOT>/<LINKED_KEY>/…` (same meaning, re-rooted).

Make the EXACT string substitutions only — do not change the parsing logic, the index header check, the depths, or the image-enumeration behavior.

- [ ] **Step 3: Update the Input block of `references/handoff/jira-reader.md`**

In the `## Input` YAML block, add `jira_export_root` as the preferred alternative to `vault_path`:

```
\```yaml
# Preferred (from the jira-input-resolution front-end): an explicit export root.
jira_export_root: /absolute/path/to/jira-products/PRODUCT-14902
# OR (legacy — /epics, /release-notes): vault path + key.
vault_path: /absolute/path/to/vault
jira_key:   PRODUCT-14902
depth:      full | vi-only
model_routing:
  …(unchanged)…
\```
```
Keep the rest of the handoff doc (Output schema, status codes) unchanged.

- [ ] **Step 4: Verify additive + back-compat**

```bash
cd /workspace/ihudak-claude-plugins
echo "=== jira-reader accepts both forms ==="
grep -n 'jira_export_root' plugins/dev-workflows/agents/jira-reader.md
grep -n 'EXPORT_ROOT' plugins/dev-workflows/agents/jira-reader.md
grep -n 'vault_path' plugins/dev-workflows/agents/jira-reader.md   # legacy form still documented
echo "=== handoff doc updated ==="
grep -n 'jira_export_root' plugins/dev-workflows/references/handoff/jira-reader.md
echo "=== /epics + /release-notes dispatch blocks BYTE-UNCHANGED (no jira-reader call edits) ==="
git diff --stat origin/main -- plugins/dev-workflows/commands/epics.md plugins/dev-workflows/commands/release-notes.md
```
Expected: `jira_export_root` + `EXPORT_ROOT` present in the agent and `jira_export_root` in the handoff doc; `vault_path` still present (legacy form); the `git diff --stat` for `epics.md` + `release-notes.md` shows **no changes** (this task touches neither).

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/agents/jira-reader.md plugins/dev-workflows/references/handoff/jira-reader.md
git commit -m "$(cat <<'EOF'
PRODUCT v2.1.0: jira-reader accepts an additive jira_export_root input

Read from an explicit export root when given (used by /document + /implement via
the shared front-end), else derive <vault_path>/jira-products/<jira_key> as
before (used by /epics + /release-notes — unchanged). Resolves the pre-existing
seam where /implement already passed a folder path in prose.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: `commands/document.md` — cite the front-end, add the directory mode

**Files:**
- Modify: `plugins/dev-workflows/commands/document.md` (Mode detection block lines ~17–25; Phase 0 steps 1–2 + step 6; Phase 3 `jira-reader` call)

**Interfaces:**
- Consumes: Task 1's reference + contract (`mode`, `jira_key`, `jira_export_root`, `specs`); Task 2's `jira_export_root` jira-reader input.
- Produces: `/document` resolving its Jira-input via the shared front-end.

**Model suggestion:** Opus (Mode-detection correctness; must not regress existing routing).

- [ ] **Step 1: Add the Jira-export-directory branch to Mode detection**

Replace the two Mode-detection bullets:

```
- **Jira mode** — the first token matches a JiraID (`^[A-Z][A-Z0-9]+-[0-9]+`), optionally followed by `saas` | `managed`. Run **Mode A** below. If the token is JiraID-shaped but no ticket folder exists under `$VAULT_PATH/jira-products/<KEY>`, ask: `choices: ["Re-enter the Jira key", "Treat the text as a direct edit instead", "Cancel"]`.
- **Direct mode** — anything else (a leading `@file` token, or free-text prose). Run **Mode B** below.
```

with:

```
- **Jira mode (Mode A)** — the input resolves `jira-driven` via the shared front-end (`${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`): a first token matching a JiraID (`^[A-Z][A-Z0-9]+-[0-9]+`), optionally followed by `saas` | `managed`, **or** a directory that inspects as a Jira-export (contains `<KEY>-index.md`). The front-end's Fallback B handles a JiraID-shaped token with no `jira-products/<KEY>` folder.
- **Direct mode (Mode B)** — the input resolves `direct` (a leading `@file` token, free-text prose, or a non-Jira-export directory, which Mode B handles via its existing "anything else" path).
```

- [ ] **Step 2: Replace Phase 0 steps 1–2 with the front-end citation**

Replace step 1 ("Resolve `$VAULT_PATH`…") and step 2 ("Resolve `<JIRA_KEY>`…") with a single step that cites the reference:

```
1. **Resolve the Jira input via the shared front-end.** Execute
   `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md` against
   `$ARGUMENTS`. For Mode A the result is `mode: jira-driven` with `jira_key`,
   `jira_export_root` (the ticket export dir — `$VAULT_PATH/jira-products/<KEY>`
   for a JiraID, or the passed directory), `source`, and `specs`. The front-end
   owns the `$VAULT_PATH`/`jira-products` validation and Fallbacks A/B. Carry
   `jira_key`, `jira_export_root`, and `specs` forward.
```

(The downstream phases that referenced `$VAULT_PATH/jira-products/<JIRA_KEY>/` now use `jira_export_root`; the Phase 9 report's "Jira directory path" line uses `jira_export_root`.)

- [ ] **Step 3: Replace Phase 0 step 6 (specs) with contract consumption**

Replace step 6 ("Discover the specs dir … under `${REPOS_PATH:-/workspace}` … vis-root … `<JIRA_KEY>*`") with:

```
6. **Specs (additive).** Use the `specs` list from the front-end (§Specs
   resolution — `$SPECS_PATH` then the directory case). `specs: []` is fine —
   specs are additive context for `/document`; proceed without prompting.
```

Leave steps 3–5 (docs repo / profile / guard), 7 (write context), and 8 (space constraint) **unchanged**. Step 8 still reads the optional `saas|managed` trailing token (now the front-end has already tokenized `$ARGUMENTS`; the trailing option is parsed by this command as before).

- [ ] **Step 4: Update the Phase 3 `jira-reader` call to pass `jira_export_root`**

Replace the Phase 3 dispatch body:

```
  > vault_path: [resolved $VAULT_PATH]
  > jira_key:   [resolved <JIRA_KEY>]
  > depth:      full"
```

with:

```
  > jira_export_root: [resolved jira_export_root from Phase 0]
  > jira_key:         [resolved <JIRA_KEY>]
  > depth:            full"
```

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
d=plugins/dev-workflows/commands/document.md
echo "=== cites the front-end ==="
grep -n 'jira-input-resolution.md' "$d"
echo "=== Mode A now triggered by JiraID OR jira-export dir ==="
grep -n 'inspects as a Jira-export' "$d"
echo "=== Phase 3 passes jira_export_root ==="
grep -n 'jira_export_root' "$d"
echo "=== kept steps intact (docs repo / profile / write context / space) ==="
grep -nE 'Resolve the docs repo|Resolve the profile|Classify write context|optional space constraint' "$d"
echo "=== Projects/Products staging + gaps still present (unchanged) ==="
grep -nc 'jira-products\|implementation-gaps' "$d"
```
Expected: citation present; the Jira-export-dir branch present; `jira_export_root` present in Phase 0 + Phase 3; the four kept-step anchors all present; staging/gaps references still present.

- [ ] **Step 6: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/document.md
git commit -m "$(cat <<'EOF'
PRODUCT v2.1.0: /document Phase 0 cites the shared Jira-input front-end + directory mode

Mode detection gains the Jira-export-directory -> Mode A branch; Phase 0 steps
1-2 (vault+key) and 6 (specs) are replaced by a citation to
jira-input-resolution.md and consume its contract; Phase 3 passes
jira_export_root to jira-reader. Docs-repo/profile/write-context/space and the
Projects/Products staging+gaps use are unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `commands/implement.md` — cite the front-end, add JiraID + specs gate

**Files:**
- Modify: `plugins/dev-workflows/commands/implement.md` (Phase 0 classifier; Phase 1.7 `jira-reader` call; add the jira-driven specs-required gate)

**Interfaces:**
- Consumes: Task 1's reference + contract; Task 2's `jira_export_root`.
- Produces: `/implement` resolving a bare JiraID (and a jira-export directory) via the shared front-end, with specs required (with override) in jira-driven mode.

**Model suggestion:** Opus (integrates with the multi-source fan-out + classification).

- [ ] **Step 1: Add the front-end citation to Phase 0**

After the existing Phase 0 intro paragraph (`$ARGUMENTS may contain free-text prose plus zero or more @path tokens…`) and its classification table, add:

```
**Jira-input resolution (shared front-end).** Before the per-`@path`
classification above, run `${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`
against `$ARGUMENTS`. It unifies the input grammar with `/document`: a **JiraID**
token (`^[A-Z][A-Z0-9]+-[0-9]+`) is discovered under `$VAULT_PATH/jira-products/`
(Fallbacks A/B on miss); a directory that inspects as a **jira-export** is used as
`jira_export_root`; a **spec-folder** contributes to `specs`; everything else is
`direct` (free-text/`@file`, this command's existing flow). The classification
table above is the directory branch of that front-end — a Jira ticket folder ↔
jira-export, a spec folder ↔ spec-folder, a code repo ↔ an `/implement`-only
target. Carry `mode`, `jira_key`, `jira_export_root`, and `specs` forward.
```

- [ ] **Step 2: Add the jira-driven specs-required gate**

Add a Phase 0 rule (in the "Rules:" list) for required specs:

```
- **Specs are required for jira-driven runs.** When `mode: jira-driven` and the
  front-end resolved `specs: []`, do not plan blind — prompt:
  `choices: ["Point me at a specs directory (you'll provide the path)", "Proceed without specs — not recommended", "Cancel"]`
  "Point me…" takes a path, classifies it as a spec-folder, and re-resolves
  `specs`. "Proceed without specs" is logged in the Phase 5 report's
  `### Assumptions & limitations`. Direct-mode runs (no Jira input) are exempt —
  the prompt/spec file is the instruction.
```

- [ ] **Step 3: Update the Phase 1.7 `jira-reader` call to pass `jira_export_root`**

Replace the Phase 1.7 jira-reader dispatch prose:

```
     > "Read the exported Jira hierarchy at <ticket-folder absolute path> and return the structured handoff: linked items, PR URLs (identifiers only — no fetching), and capability themes."
```

with:

```
     > "Return the structured handoff for this brief — linked items, PR URLs (identifiers only — no fetching), and capability themes:
     >
     > jira_export_root: [the resolved jira_export_root (from the Phase 0 front-end), or the ticket-folder absolute path]
     > jira_key:         [the resolved <KEY>]
     > depth:            full"
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
i=plugins/dev-workflows/commands/implement.md
echo "=== cites the front-end ==="
grep -n 'jira-input-resolution.md' "$i"
echo "=== JiraID recognition + specs gate ==="
grep -n 'JiraID' "$i"
grep -n 'Specs are required for jira-driven' "$i"
echo "=== Phase 1.7 passes jira_export_root ==="
grep -n 'jira_export_root' "$i"
echo "=== existing classifier + fan-out intact ==="
grep -nE 'Jira ticket folder|Code repo|fan_out' "$i" | head
```
Expected: citation present; JiraID recognition + the specs-gate line present; `jira_export_root` in Phase 1.7; the existing classification table + fan-out anchors intact.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/commands/implement.md
git commit -m "$(cat <<'EOF'
PRODUCT v2.1.0: /implement cites the shared Jira-input front-end (JiraID + specs gate)

Phase 0 runs jira-input-resolution.md (unifying the grammar with /document):
a bare JiraID is now discovered under $VAULT_PATH/jira-products; a jira-export
directory feeds jira_export_root; specs are required-with-override for
jira-driven runs. Phase 1.7 passes jira_export_root to the jira-reader fan-out
(formalizing the prior prose folder-path call). Direct/code-repo flow unchanged.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: `hooks/preload-context.sh` — `/implement <JiraID>` + `SPECS_PATH`

**Files:**
- Modify: `plugins/dev-workflows/hooks/preload-context.sh`

**Interfaces:**
- Consumes: nothing (independent).
- Produces: the hook preloads Jira context for `/implement <JiraID>` and surfaces `SPECS_PATH`.

**Model suggestion:** Sonnet (small bash change with a functional test).

- [ ] **Step 1: Add `SPECS_PATH` to `emit_jira_context`**

In `emit_jira_context()`, after the `repos_path:` echo and before `emit_git_branch_if_repo`, add:

```bash
    if [[ -n "${SPECS_PATH:-}" ]]; then
        echo "SPECS_PATH: $SPECS_PATH"
    else
        echo "SPECS_PATH: (not set — the command will use \$VAULT_PATH-based specs or ask)"
    fi
```

- [ ] **Step 2: Emit Jira context for `/implement <JiraID>`**

In the `implement|vuln|upgrade)` case, after `emit_dir_listing_if_small`, add a JiraID check that appends Jira context for `/implement` only:

```bash
        # /implement <JiraID> is jira-driven — also preload Jira context.
        if [[ "$cmd" == "implement" && "$prompt" =~ ^/implement[[:space:]]+[A-Z][A-Z0-9]+-[0-9]+ ]]; then
            emit_jira_context
        fi
```

(The directory-input case needs no hook change — a passed directory is self-contained; the command resolves it. The hook stays a best-effort context preloader.)

- [ ] **Step 3: Update the header comment**

Update the `/implement` and `/document` lines in the top comment block to note: `/implement` adds Jira context when the argument is a JiraID; `emit_jira_context` now includes `SPECS_PATH`. (Comment-only; match the existing comment style.)

- [ ] **Step 4: Verify — syntax + functional test**

```bash
cd /workspace/ihudak-claude-plugins
h=plugins/dev-workflows/hooks/preload-context.sh
bash -n "$h" && echo "syntax OK"
echo "=== /implement <JiraID> → model routing + git + Jira context (incl SPECS_PATH) ==="
echo '{"prompt":"/implement PRODUCT-14902 add a flag"}' | VAULT_PATH=/tmp/v SPECS_PATH=/tmp/s bash "$h" | grep -E 'Model routing|VAULT_PATH|SPECS_PATH'
echo "=== /implement <free-text> → NO Jira context ==="
echo '{"prompt":"/implement add a --verbose flag"}' | bash "$h" | grep -c 'VAULT_PATH' ; echo "(expect 0)"
echo "=== /document <JiraID> → Jira context incl SPECS_PATH ==="
echo '{"prompt":"/document PRODUCT-14902"}' | SPECS_PATH=/tmp/s bash "$h" | grep -E 'VAULT_PATH|SPECS_PATH'
echo "=== /document <free-text> → silent ==="
echo '{"prompt":"/document fix a typo on the install page"}' | bash "$h" | grep -c 'VAULT_PATH' ; echo "(expect 0)"
```
Expected: syntax OK; `/implement PRODUCT-…` emits Model routing + VAULT_PATH + SPECS_PATH; `/implement <free-text>` emits 0 VAULT_PATH lines; `/document PRODUCT-…` emits VAULT_PATH + SPECS_PATH; `/document <free-text>` emits 0.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/hooks/preload-context.sh
git commit -m "$(cat <<'EOF'
PRODUCT v2.1.0: preload-context hook — /implement <JiraID> Jira context + SPECS_PATH

/implement with a JiraID argument now also preloads Jira context (it is
jira-driven via the shared front-end); emit_jira_context surfaces SPECS_PATH
alongside VAULT_PATH/REPOS_PATH. Directory-input needs no hook change.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: README + manifests + CHANGELOG (`v2.1.0`)

**Files:**
- Modify: `plugins/dev-workflows/README.md` (env-var docs; `/document` + `/implement` rows; reference the import tool)
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (top-level `version`)
- Modify: `.claude-plugin/marketplace.json` (`plugins[0].version`)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (`[2.1.0]` entry)

**Interfaces:**
- Consumes: the shipped behavior from Tasks 1–5.

**Model suggestion:** Sonnet (mechanical docs + version bump).

- [ ] **Step 1: README — env vars + import tool + command rows**

In `README.md`:
- Where `VAULT_PATH` / `REPOS_PATH` are documented, add **`SPECS_PATH`** — "Optional, AI-Containers env var (same rules as `VAULT_PATH`; mounted to `/workspace/specs` in-container). The deterministic source for a Jira ticket's specifications, at `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md`. Used by `/implement` (required) and `/document` (additive)."
- Add a sentence referencing the importer: "The Jira hierarchy under `$VAULT_PATH/jira-products/<KEY>/` is produced by the [`jira-workitem-import`](https://github.com/ivan-gudak/jira-workitem-import) tool, which imports tickets from Jira and maintains the index."
- Update the `/implement` and `/document` rows to note the unified input grammar: each accepts a **JiraID**, an **imported-Jira directory**, or a **direct prompt/`@file`** (`/implement` also takes `@spec`/`@repo`; `/document` keeps the optional `saas|managed`).

- [ ] **Step 2: Bump versions**

- `plugins/dev-workflows/.claude-plugin/plugin.json` top-level `"version"` → `"2.1.0"`.
- `.claude-plugin/marketplace.json` `plugins[0].version` → `"2.1.0"` (leave the other entries `0.2.2` / `0.3.1` untouched).

- [ ] **Step 3: CHANGELOG `[2.1.0]` entry**

Prepend above `## [2.0.1]`, matching the file's heading style (em-dash date):

```markdown
## [2.1.0] — 2026-06-29

### Added

- **Shared Jira-input resolution front-end** (`references/jira-input-resolution.md`). `/implement` and `/document` now share one input grammar: a **JiraID** (discovered under `$VAULT_PATH/jira-products/`), an **imported-Jira directory** (the same exporter output rooted anywhere — works when `$VAULT_PATH` is unset), or a **direct prompt/`@file`**. `/implement` gains JiraID discovery; `/document` gains directory input.
- **`SPECS_PATH`** env var (same rules as `VAULT_PATH`) — the deterministic source for a ticket's specifications at `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md`. Specs are **required (with override)** for `/implement` jira-driven runs and **additive** for `/document`.
- `jira-reader` accepts an additive `jira_export_root` input (an explicit ticket export directory); `/epics` and `/release-notes` keep using `vault_path` + `jira_key` unchanged.

### Changed

- The `jira-workitem-import` tool (https://github.com/ivan-gudak/jira-workitem-import) is now referenced as the source of the `jira-products/` export.
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json; print('plugin', json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json'))['version'])"
python3 -c "import json; d=json.load(open('.claude-plugin/marketplace.json')); print('mkt[0]', d['plugins'][0]['version']); print('others', [p['version'] for p in d['plugins'][1:]])"
grep -n '^## \[2.1.0\] — 2026-06-29' plugins/dev-workflows/CHANGELOG.md
grep -n '^## \[2.0.1\]' plugins/dev-workflows/CHANGELOG.md   # preserved
grep -n 'SPECS_PATH' plugins/dev-workflows/README.md
grep -n 'jira-workitem-import' plugins/dev-workflows/README.md
echo "=== both commands cite the shared reference (completeness) ==="
grep -rl 'jira-input-resolution' plugins/dev-workflows/commands
```
Expected: both versions `2.1.0`; marketplace others `0.2.2`/`0.3.1`; `[2.1.0]` em-dash heading present; `[2.0.1]` preserved; `SPECS_PATH` + `jira-workitem-import` in README; the `grep -rl` lists BOTH `commands/document.md` and `commands/implement.md`.

- [ ] **Step 5: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/README.md plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md
git commit -m "$(cat <<'EOF'
PRODUCT dev-workflows v2.1.0: release the shared Jira-input front-end

Bump plugin.json + marketplace.json plugins[0].version to 2.1.0; document
SPECS_PATH and the jira-workitem-import tool in the README; refresh the
/document + /implement input-grammar rows; add the CHANGELOG [2.1.0] entry.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**1. Spec coverage** (against `spec/2026-06-29-jira-input-resolution-b2-design.md`):
- §A form (reference, not subagent) → Task 1. ✓
- §B grammar + mode classifier → Task 1 (reference) + Tasks 3/4 (consumption). ✓
- §C `/document` Mode-detection branch → Task 3 Step 1. ✓
- §D resolution algorithm (tokenize, mode, JiraID branch, directory branch, direct, feed jira-reader, additive multi-token, fallbacks) → Task 1. ✓
- §E output contract → Task 1 (defined) + Tasks 3/4 (consumed). ✓
- §F per-command consumption + specs requiredness → Task 3 (additive) + Task 4 Step 2 (required-with-override). ✓
- §G SPECS_PATH + layout + ask-on-miss → Task 1 (reference) + Task 4 (gate) + Task 6 (README). ✓
- §H jira-reader additive input → Task 2. ✓
- Touch list (reference, document.md, implement.md, jira-reader+handoff, hook, manifests/README/CHANGELOG) → Tasks 1–6. ✓
- Non-goals respected: no `/epics`/`/release-notes` wiring (Task 2 Step 4 verifies byte-unchanged); Projects/Products kept in `/document` (Task 3 Step 5 verifies staging/gaps present); no downstream pipeline change. ✓
- Risks: jira-reader byte-unchanged for the two non-adopting commands (T2 S4); Mode-detection no-regress (T3 S5 + the functional hook test T5 S4); specs-gate required-with-override (T4 S2); additive release (T6). ✓

**2. Placeholder scan:** No "TBD"/"handle appropriately". The reference content is given verbatim; every edit shows exact old→new strings; commands have expected outputs. ✓

**3. Type/name consistency:** The contract field names (`mode`, `source`, `jira_key`, `jira_export_root`, `specs`, `direct_prompt`, `direct_files`) are identical in Task 1 (defined), Tasks 3/4 (consumed), and Task 2 (`jira_export_root` input). `EXPORT_ROOT` is the agent-internal derivation in Task 2. The SPECS_PATH layout string is identical in Task 1, Task 4, and Task 6. ✓
