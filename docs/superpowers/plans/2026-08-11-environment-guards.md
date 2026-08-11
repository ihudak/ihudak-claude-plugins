# Environment Guards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `docs-grounder`, `code-scanner`, and `diff-summarizer` behave correctly in the AI container they actually run in — no unbounded work on a user's critical path, no failure on a read-only mount, and every degradation named where a user can see and act on it.

**Architecture:** Two halves of one defect class (an agent that declares itself read-only writes in its prep step). Half A moves qmd index maintenance *up* into `resolve-docs-grounding`, where the orchestrator can ask for consent, and leaves the agent with a probe-and-select ladder that never mutates. Half B adds a new shared reference, `references/read-only-repos.md`, that all three git-touching agents follow when a mount is read-only: read at `origin/<default>` through git plumbing instead of switching the working tree.

**Tech Stack:** Prompt markdown — the "code" is instruction text an LLM executes at runtime. There is **no build and no test framework**. Verification is `grep`, `awk`, `diff`, and reading.

**Spec:** `docs/superpowers/specs/2026-08-11-environment-guards-design.md` (committed `1d008b8`).

**Ships as:** `dev-workflows` 2.47.0 (canonical + mgd) / 2.17.0 (copilot).

**Branch:** `iv-gu/environment-guards` (already exists in canonical, spec committed).

## Global Constraints

Every task's requirements implicitly include this section.

- **`references/docs-grounding.md` §3's validity gate is byte-unchanged.** It decides whether grounding runs *at all*; Path B works with no index. An index check there would disable grounding exactly where the fallback still works. Adding a condition to §3 is a defect, not an improvement.
- **`qmd query` is NEVER invoked** anywhere in any edition.
- **`docs-grounder` never builds or refreshes the index.** No `qmd collection add`, `collection remove`, `collection rename`, `qmd embed`, `qmd update`, `qmd init`, `qmd cleanup`. Building and refreshing belong to `resolve-docs-grounding` alone.
- **Nothing changes for writable mounts.** `git switch` and `git pull --ff-only` remain sanctioned prep on a writable clone. Read-only handling is purely additive.
- **Exact values, used verbatim:** staleness threshold **14 days** (shared by the ref check and the docs-checkout check); timeouts **10s** probe / **30s** retrieval / **60s** `qmd update`; consented builds are **uncapped**; Path B **3–8** keywords, drop any keyword returning **more than 200** files, shortlist cap **40** files; existing Bounding cap of **8** pages unchanged.
- **`retrieval:` enum is exactly** `qmd-vector | qmd-lexical | fallback`.
- **`prep` fields are exactly** `read_only`, `scanned_ref`, `ref_committed_at`, `head_divergence: { branch, ahead, behind }` — always present, never omitted.
- **Every git call is `git -C "<repo_path>" …`.** Never `cd`.
- **Derive file lists, never type them.** All three marketplace catalogs must be found with `find . -name 'marketplace.json'` across the three repos — copilot's lives at `.github/plugin/marketplace.json`, and a hand-written table has missed it three times.
- **Do NOT bend content to satisfy an inline expectation.** Where a step carries `# expect N`, that number is an observation recorded when this plan was written. If your actual count differs, **report the mismatch with your reasoning and do not change the content to match**. On the last two sub-projects, twelve such mismatches were reported and the plan was wrong all twelve times.
- **Prose is never hard-wrapped** (`references/prose-formatting.md`): each paragraph is one unbroken line.

---

## File Structure

**Canonical — `/workspace/ihudak-claude-plugins/plugins/dev-workflows/`**

| File | Responsibility |
|---|---|
| `references/read-only-repos.md` **(new)** | The read-only-mount contract: detection, what to skip, ref resolution, read primitives, escalation trigger, output contract, caller contract, hard rules |
| `references/docs-grounding.md` | Adds step 3.5 (index state + consent prompts), returns `retrieval`, extends the plan-approval line |
| `references/escalation-rules.md` | Adds the `Read-only mount — ref stale or diverged` entry |
| `references/handoff/code-scanner.md` | Adds the four `prep` fields |
| `references/handoff/diff-summarizer.md` | Adds the four `prep` fields |
| `agents/docs-grounder.md` | Rung ladder, Path B bounding, restated hard rules |
| `agents/code-scanner.md` | Read-only prep + ref-mode scanning |
| `agents/diff-summarizer.md` | Read-only prep |
| `commands/{implement,document,epics,specify,design}.md` | Cite the read-only escalation beside their existing `REFRESH_BLOCKED` handling |
| `commands/{create-ard,release-notes}.md` | Gain their first scanner/summarizer failure handling |
| `commands/{idea,create-vi,update-vi,create-ard,specify,epics}.md` | The extended plan-approval line |
| `CHANGELOG.md`, `.claude-plugin/plugin.json` | Version 2.47.0 |
| repo-root `CLAUDE.md`, `.claude-plugin/marketplace.json` | Source-truth bullet; catalog version |

**mgd — `/workspace/mgd-claude-plugins`:** the 18 content files copied verbatim; four identity files hand-edited.

**copilot — `/workspace/ihudak-copilot-plugins`:** the same content adapted to the `<name>:` dialect, own version track.

---

### Task 1: The read-only-mount reference

**Files:**
- Create: `plugins/dev-workflows/references/read-only-repos.md`

**Interfaces:**
- Produces: the section numbering `§1`–`§8` that Tasks 4, 5, 6, 7 cite by number, and the `prep` field names Tasks 4 and 5 emit.

- [ ] **Step 1: Create the file with exactly this content**

````markdown
# Read-only repository mounts (shared reference)

The AI container mounts repositories from the host, and some arrive **read-only** — verified 2026-08-11, 2 of 12 clones under `/workspace` are (`docs`, `observability-requirements`). Every agent that prepares a clone before reading it must work on those mounts rather than fail on them.

This file is the single source of truth for that behavior. Consumers: `code-scanner`, `diff-summarizer`, `docs-grounder`.

**Nothing here changes behavior on a writable mount.** `git switch` and `git pull --ff-only` remain sanctioned prep on a writable clone — they change which committed revision is present, not the content of it. Everything below is reached only when the mount is read-only.

## 1. Detection

Before any git call that writes:

```
test -w "<repo_path>" && test -w "<repo_path>/.git"
```

Either test failing ⇒ **read-only mode**. Secondary trigger: any git command failing with an error containing `Read-only file system` ⇒ enter read-only mode and retry there, rather than returning `REFRESH_BLOCKED`.

A false positive is benign: the agent then reads at `origin/<default-branch>`, which is what a caller passing `switch_to_default_branch: true` or `refresh.pull: true` asked for anyway.

## 2. What read-only mode skips

- `git fetch`, `git pull`, `git switch`, `git remote set-head` — all write.
- **The dirty-tree gate.** A dirty working tree is irrelevant when the working tree is never mutated, so read-only mode NEVER returns `DIRTY_TREE`.

Read-only mode is not a failure. It NEVER returns `REFRESH_BLOCKED` on its own; that status stays reserved for a genuine failure — §3's chain exhausted, or §4's read primitives all failing.

## 3. Resolving the ref without writing

In order, stopping at the first that succeeds:

1. `git -C "<repo_path>" symbolic-ref --short refs/remotes/origin/HEAD`
2. `git -C "<repo_path>" rev-parse --verify origin/main`
3. `git -C "<repo_path>" rev-parse --verify origin/master`

`git remote set-head origin --auto` is **not** part of this chain — it writes. An exhausted chain is a genuine `REFRESH_BLOCKED` with reason `cannot resolve default branch on a read-only mount`.

Then record three facts, all pure reads:

- `git -C "<repo_path>" log -1 --format=%cI <ref>` → `ref_committed_at`
- `git -C "<repo_path>" rev-list --left-right --count <ref>...HEAD` → `behind` then `ahead`, tab-separated
- `git -C "<repo_path>" rev-parse --abbrev-ref HEAD` → the working-tree branch name

## 4. Reading at the ref

Two write-free scan targets:

- **The working tree**, with the native `Grep` / `Glob` / `Read` tools.
- **The ref**, via git plumbing that never consults or writes the index:
  - enumerate — `git -C "<repo_path>" ls-tree -r --name-only <ref>`
  - search — `git -C "<repo_path>" grep -n <pattern> <ref> -- <pathspec>`
  - read — `git -C "<repo_path>" show <ref>:<path>`

**When HEAD is already at the ref — `git -C "<repo_path>" rev-parse HEAD` equals `git -C "<repo_path>" rev-parse <ref>` — scan the working tree natively.** The content is identical and the native tools are better, so the common read-only case costs nothing extra.

Otherwise read at the ref. If `git grep <tree-ish>` is unavailable or errors, fall back to `git show`-per-file over an `ls-tree` shortlist. If that also fails, return `REFRESH_BLOCKED` with the one-line git error.

## 5. When to escalate

Escalate to the caller — which prompts the user per the `Read-only mount — ref stale or diverged` entry in `escalation-rules.md` — when **either** holds:

- `ref_committed_at` is more than **14 days** old — the host has not fetched recently, so the ref itself is stale; or
- `head_divergence.ahead > 0` — the working tree carries commits the ref does not, so local work is invisible at the scanned ref.

`head_divergence.behind > 0` alone is **silent**: the scan reads the ref, so being behind locally changes nothing. On a read-only mount sitting at the default branch with a recent ref, the run proceeds with no prompt.

## 6. Output contract

Every consuming agent reports these four fields in its `prep` block, always present so a caller never branches on absence:

```yaml
prep:
  read_only:        true | false
  scanned_ref:      <ref name, e.g. "origin/main"; the default branch name when writable>
  ref_committed_at: <ISO-8601 timestamp of the ref's newest commit>
  head_divergence:  { branch: <working-tree branch>, ahead: <n>, behind: <n> }
```

Every path an agent returns keeps its documented meaning — relative to the repo root — and denotes content **at `scanned_ref`**.

## 7. Caller contract

A caller that reads repository files directly, rather than through one of these agents, must first confirm `HEAD` is at the remote default ref — or cite the content via `scanned_ref` (`git -C "<repo_path>" show <scanned_ref>:<path>`). A working tree on an unmerged branch is not released behavior, and citing it as current is the failure this reference exists to prevent.

## 8. Hard rules

- NEVER edit, create, or delete files under `repo_path`. NEVER commit, cherry-pick, reset, rebase, or force.
- NEVER write to `.git` in read-only mode — that includes `git remote set-head`, `git fetch`, `git pull`, and `git switch`.
- NEVER delete an `index.lock`.
- NEVER make HTTPS / REST calls to any git host. All work is on the local clone.
- Read-only mode is never fatal: it degrades to reading at the ref and reports what it did.
````

- [ ] **Step 2: Verify the file parses as the reference the later tasks cite**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n '^## ' references/read-only-repos.md
# expect the eight sections §1–§8, numbered and in order
grep -n 'read_only\|scanned_ref\|ref_committed_at\|head_divergence' references/read-only-repos.md
# read each hit: all four names must appear in the §6 yaml block; §3 and §5 may reference them
grep -n 'git remote set-head' references/read-only-repos.md
# read each hit: every one must be an exclusion or a ban, never an instruction to run it
```

These are enumerate-and-judge checks, not counts. A count proves a rule was applied where you looked; reading each hit is what catches the site you did not think to look for.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/read-only-repos.md
git commit -m "feat(dev-workflows): add read-only-repos.md shared reference"
```

---

### Task 2: `docs-grounder` — rung ladder, bounded fallback, restated hard rules

**Files:**
- Modify: `plugins/dev-workflows/agents/docs-grounder.md`

**Interfaces:**
- Consumes: `references/read-only-repos.md` from Task 1 (cited once, in Path B step 2).
- Produces: the `retrieval: qmd-vector | qmd-lexical | fallback` enum that Task 3 and Task 8 display.

- [ ] **Step 1: Replace the whole `### Path A — qmd (preferred)` section**

Replace from the line `### Path A — qmd (preferred)` through the line `4. Record `retrieval: qmd`.` inclusive, with:

````markdown
### Path A — qmd (preferred)

Use when the `qmd` binary is available (`command -v qmd`). **This agent never builds or refreshes the index** — that belongs to `resolve-docs-grounding` (`${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` step 3.5), which can ask the user first. Here, probe what already exists and pick a rung.

1. **Probe — model-free and mutation-free.** `timeout 10s qmd status` and `timeout 10s qmd collection list`.
   - `qmd status`'s first line is `Index: <path>`. When that path is not the user-scope `~/.cache/qmd/index.sqlite`, a project-local `.qmd` index in the current directory is shadowing it: record that in `notes` and take rung 3.
   - For "does the collection have embeddings", prefer `timeout 10s qmd collection show <name>` when it reports a per-collection embedding count — a global `Vectors:` count from `qmd status` can be satisfied by a *different* collection. Fall back to the global count when per-collection is unavailable.
2. **Select the rung.**

| Rung | Precondition | Retrieval | `retrieval:` |
|---|---|---|---|
| 1 | a collection covers `docs_path` **and** it reports embedded vectors > 0 | `timeout 30s qmd search "<terms>"` + `timeout 30s qmd vsearch "<terms>"`, unioned | `qmd-vector` |
| 2 | a collection covers `docs_path`, vectors == 0 | `timeout 30s qmd search "<terms>"` | `qmd-lexical` |
| 3 | no collection covers `docs_path`, `qmd` absent, a project-local index is shadowing, or either probe fails | Path B | `fallback` |

   `<terms>` = `feature_summary` keywords + `themes`, minus stopwords. **Union of the two ranked lists:** interleave `qmd search` and `qmd vsearch` results by rank position, dedupe by path keeping the better rank, truncate at the Bounding cap of 8.
3. **Read the top hits** with `timeout 30s qmd get "<file>"` (or `Read`), capped per Bounding.
4. **A timeout or non-zero exit on any qmd call drops one rung** and is recorded in `notes` — except that a failing `qmd search` drops straight to Path B, because rung 2 depends on that same call and would fail identically. This is the backstop for anything qmd does that this procedure did not anticipate.

**`qmd query` is NEVER invoked.** It is the only entry point needing the reranking and query-expansion models on top of the embedding model, and no cheap probe can prove those are cached — a cold run downloads ~1.3 GB on the user's critical path. `vectors > 0` proves the *embedding* model already ran on this machine, which is exactly what makes `qmd vsearch` provably safe and `qmd query` not. The cost is rank polish on a retrieval capped at 8 pages that is advisory-only.
````

- [ ] **Step 2: Replace Path B step 1 with the bounded form**

Replace the three lines beginning `1. **Keyword-overlap scoring** (the `doc-location-finder` technique)` through `threshold;` … ending `keep matches above threshold.`, with:

````markdown
1. **Keyword-overlap scoring, bounded.** Never enumerate the whole root — `$DOCS_PATH` can hold tens of thousands of pages, and this path now receives every qmd miss.
   - Derive **3–8** salient keywords from `feature_summary` + `themes`, minus stopwords.
   - Shortlist with `Grep` in files-with-matches mode, one pass per keyword. **Drop any keyword returning more than 200 files** — it is too generic to discriminate.
   - Union the surviving hits, ordered by how many keywords each file matched, and **cap the shortlist at 40 files**.
   - Score only that shortlist: frontmatter (`title`/`description`/`tags`) + first ~50 body lines, overlap against `feature_summary` + `themes`; keep matches above threshold.
   - An empty shortlist ⇒ `status: EMPTY` with a `notes` line.
````

- [ ] **Step 3: Cross-reference the read-only reference from the git-grep backstop**

In Path B step 2, replace `This is a pure read and works on a read-only `.git`;` with:

```
This is a pure read and works on a read-only `.git` (see `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md`);
```

- [ ] **Step 4: Update the output contract's `retrieval` line**

Replace `retrieval: qmd | fallback` with `retrieval: qmd-vector | qmd-lexical | fallback`.

- [ ] **Step 5: Replace the `## Hard rules` section body**

Replace the five existing bullets with:

````markdown
- NEVER write into `$DOCS_PATH`, any git working tree, or any repository.
- MAY read and touch the user-scope qmd index under `~/.cache/qmd/` — qmd's read commands create and update that file (`qmd status` alone creates it), and it lies outside every git working tree.
- NEVER **build or refresh** the index from inside this agent: no `qmd collection add`, `qmd collection remove`, `qmd collection rename`, `qmd embed`, `qmd update`, `qmd init`, `qmd cleanup`. Building and refreshing belong to `resolve-docs-grounding`, which can ask the user first.
- NEVER run `qmd init` anywhere — a project-local `.qmd/` index resolves relative to cwd, and this plugin's commands routinely run standing in a different repo from the one they read.
- NEVER run `qmd update --pull` (it writes into a possibly-read-only docs clone).
- NEVER run `qmd query` — use the Path A rung ladder.
- Every qmd invocation carries an explicit wall-clock cap.
- NEVER make HTTPS/REST calls — `git` and the `qmd` CLI are local only.
- Advisory only — never a gate; `docs_challenges` are reconciliation prompts, not auto-applied edits.
- Respect the Bounding caps; a large clone must not flood the caller's context.
````

- [ ] **Step 6: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n 'qmd query' agents/docs-grounder.md
# read each hit: every one must be prose stating the ban. ZERO may be an instruction to run it.
grep -n 'qmd collection add\|qmd collection remove\|qmd collection rename\|qmd embed\|qmd update\|qmd init\|qmd cleanup' agents/docs-grounder.md
# read each hit: every one must sit inside a NEVER bullet
grep -n 'qmd-vector\|qmd-lexical\|fallback' agents/docs-grounder.md
# the three enum values must appear in the rung table AND in the output contract
grep -n 'timeout ' agents/docs-grounder.md
# every qmd invocation in the file must be prefixed with a timeout — check each qmd call, not the count
grep -n '200 files\|40 files\|3–8' agents/docs-grounder.md
# all three Path B bounds must be present
```

Enumerate and judge; do not compare counts. Each of these greps returns a set to read.

- [ ] **Step 7: Commit**

```bash
git add plugins/dev-workflows/agents/docs-grounder.md
git commit -m "fix(dev-workflows): docs-grounder probes the qmd index instead of building it"
```

---

### Task 3: `docs-grounding.md` — consent-gated index maintenance and the extended line

**Files:**
- Modify: `plugins/dev-workflows/references/docs-grounding.md`

**Interfaces:**
- Consumes: the `retrieval` enum from Task 2.
- Produces: the plan-approval line forms that Task 8 quotes verbatim in six commands.

- [ ] **Step 1: Insert step 3.5 and rewrite step 4 in `## Procedure — `resolve-docs-grounding <command-name>``**

**Do not touch step 3.** Insert between step 3 and step 4:

````markdown
3.5. **Index state — qmd only.** Skip entirely when `command -v qmd` fails: `retrieval: fallback`, silent, exactly as today. Otherwise probe with `timeout 10s qmd status` and `timeout 10s qmd collection list`. **If either probe fails or times out, treat that exactly as `qmd` absent** — `retrieval: fallback`, silent, no prompt — which mirrors `docs-grounder`'s rung 3 so the command and the agent degrade identically instead of disagreeing about the same broken install. Otherwise take one branch.

   **A collection covers `docs_root`** → `timeout 60s qmd update`. Incremental (qmd re-indexes only changed files), instant when nothing changed, and safe to kill because the index is SQLite and rolls back. On a cap breach, prompt once — never silently pay 60 seconds on every future run:

   ```
   choices: ["Continue with the current index — some pages may be stale (Recommended)",
             "Finish the refresh now — uncapped",
             "Turn docs grounding off for this run",
             "Other… (describe)"]
   ```

   **No collection covers `docs_root`** → prompt once, at plan approval, before any of the run's real work. `<N>` is `find "$docs_root" -type f -name '*.md' | wc -l`:

   ```
   choices: ["Build the docs index now — one-time, <N> markdown files, downloads a ~1.3 GB model on first use (Recommended — every later run is faster and better grounded)",
             "Skip — ground with keyword fallback this run",
             "Turn docs grounding off for this run",
             "Other… (describe)"]
   ```

   On "Build": `qmd collection add "<docs_root>" --name docs` then `qmd embed`, **uncapped** — killing a consented build wastes the work it has already done — reporting elapsed time on completion. The prompt disappears permanently once the index exists.

   **Index building NEVER happens inside `docs-grounder`.** An agent cannot ask, so an agent told to self-heal has only two options: burn many minutes silently, or abort on its own judgment. This step exists because the orchestrator can ask.
````

Then replace step 4 with:

````markdown
4. **Return** `{ docs_grounding, docs_root, retrieval, reason }`, where `retrieval` is `qmd-vector | qmd-lexical | fallback`. `docs-grounder` re-probes and its rung selection is authoritative; this value drives the prompts above and the line below.
````

- [ ] **Step 2: Replace the whole `## Plan-approval line` section**

````markdown
## Plan-approval line

When `resolve-docs-grounding` returns, surface one line in the command's plan/approval (or config-confirm) step, with an off switch. This reference owns the format; consumer commands quote it.

```
docs grounding: ON <root> (retrieval: qmd-vector)
docs grounding: ON <root> (retrieval: qmd-lexical — index has no embeddings)
docs grounding: ON <root> (retrieval: qmd-vector; index refresh exceeded 60s — some pages may be stale)
docs grounding: ON <root> (retrieval: qmd-vector; docs checkout <N> days old — refresh on the host)
docs grounding: ON <root> (retrieval: fallback — no qmd index; build once: qmd collection add "<root>" --name docs && qmd embed)
docs grounding: ON <root> (retrieval: fallback — a project-local .qmd index in <cwd> is shadowing the user-scope one; run from another directory or remove it)
docs grounding: OFF (<reason>)
```

Every form ends with the off switch `(turn off with --no-docs)` when the value is `ON`.

**Docs-checkout staleness.** A fresh index over a stale checkout still grounds on stale docs, and a read-only docs mount cannot be pulled from inside the container. One pure read — `git -C "$docs_root" log -1 --format=%cI`, skipped silently when the root is not a git checkout — appends the clause when the newest commit is more than **14 days** old. That threshold is shared with `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md` §5, so the two move together.

**Shadow detection.** `qmd status` prints `Index: <path>` as its first line, which step 3.5 already parses. When that path is not the user-scope `~/.cache/qmd/index.sqlite`, a project-local `.qmd` index in the current directory is shadowing it — name that cause rather than reporting a generic miss. A `qmd init` run by hand in a working repo silently disables docs grounding, and the failure is otherwise indistinguishable from never having built an index.
````

- [ ] **Step 3: Add the two new invariants**

At the end of `## Invariants`, append:

````markdown
- Index **building and refreshing** happen only in `resolve-docs-grounding` step 3.5, never inside `docs-grounder`, which only probes. A build always requires user consent; a refresh runs bounded at 60s and asks only when that cap is breached.
- The validity gate (step 3) checks the docs root, never the retrieval index — Path B works with no index at all, so gating on one would disable grounding exactly where the fallback still works.
````

- [ ] **Step 4: Verify step 3 is untouched and the rest landed**

```bash
cd /workspace/ihudak-claude-plugins
git diff -U0 plugins/dev-workflows/references/docs-grounding.md | grep -E '^-.*(non-empty|test -d|test -r|find "\$docs_root")'
# expect NO output. Match REMOVALS only: step 3 is unchanged iff none of its lines were deleted
# or rewritten. Do NOT match '+' lines — the new step 3.5 legitimately contains its own
# `find "$docs_root" … -name '*.md' | wc -l` for the build prompt's <N>, so matching additions
# reports a false failure on correct work.
cd plugins/dev-workflows
grep -n 'choices:' references/docs-grounding.md
# expect exactly two arrays: the capped-refresh prompt and the build prompt
grep -n 'retrieval' references/docs-grounding.md
# read each hit: the six line forms, the step 3.5 qmd-absent branch, and the step 4 return value
grep -n '14 days\|shadowing' references/docs-grounding.md
# the staleness threshold once, the shadow cause in both the line form and its explanation
```

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/references/docs-grounding.md
git commit -m "feat(dev-workflows): consent-gated qmd index maintenance in resolve-docs-grounding"
```

---

### Task 4: `code-scanner` — read-only prep and ref-mode scanning

**Files:**
- Modify: `plugins/dev-workflows/agents/code-scanner.md`
- Modify: `plugins/dev-workflows/references/handoff/code-scanner.md`

**Interfaces:**
- Consumes: `references/read-only-repos.md` §1–§6 from Task 1.
- Produces: the four `prep` fields Task 6 and Task 7 escalate on.

- [ ] **Step 1: Rewrite the agent's prep step (`## Process` item 2)**

Replace the whole of item 2 with:

````markdown
2. **Prep step.**

   **Read-only detection comes first.** Per `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md` §1, test whether `repo_path` and `repo_path/.git` are writable. On a read-only mount, follow that reference — §2 for what to skip, §3 for ref resolution, §4 for reading at the ref, §5 for when to escalate — then continue to step 3. A read-only mount is NOT `DIRTY_TREE` and NOT `REFRESH_BLOCKED`.

   On a **writable** mount, unchanged:
   - `git status --porcelain` — if output is non-empty AND `refresh.pull` is true → return `status: DIRTY_TREE`. The caller's escalation prompts the user to stash-and-retry, skip this repo, or cancel.
   - If `refresh.switch_to_default_branch` is true: resolve the default branch via `git symbolic-ref --short refs/remotes/origin/HEAD`. If that fails (unset `origin/HEAD`), run `git remote set-head origin --auto` and retry; if it still fails, try `main`, then `master`, in that order. If the fallback chain exhausts, return `status: REFRESH_BLOCKED` with reason `cannot resolve default branch`.
   - `git switch <default-branch>` — on failure, if the error contains `Read-only file system`, enter read-only mode per `read-only-repos.md` §1 and retry there; otherwise return `status: REFRESH_BLOCKED` with the one-line git error.
   - If `refresh.pull` is true: `git pull --ff-only`. On any failure (non-fast-forward, network, auth, etc.) return `status: REFRESH_BLOCKED` with the one-line git error.
````

- [ ] **Step 2: Make step 3's scan read-only aware**

Replace `3. **Scan — pure filesystem.** No git commands beyond step 2. For each theme:` with:

````markdown
3. **Scan.** On a writable mount, and on a read-only mount whose HEAD is already at `scanned_ref`, this is pure filesystem search with the native tools and no git commands beyond step 2. On a read-only mount whose HEAD is NOT at `scanned_ref`, run the same searches through the `read-only-repos.md` §4 ref primitives — `git grep -n <pattern> <ref> -- <pathspec>` to search, `git ls-tree -r --name-only <ref>` to enumerate, `git show <ref>:<path>` to read — so the evidence describes released content rather than an unmerged working tree. For each theme:
````

- [ ] **Step 3: Replace step 4's read instruction**

Replace `4. **Read top candidates.** For each theme, open the head (~80 lines) of the top 2–3 matching files.` with:

````markdown
4. **Read top candidates.** For each theme, open the head (~80 lines) of the top 2–3 matching files — with `Read` on the working tree, or `git show <scanned_ref>:<path>` in ref mode.
````

- [ ] **Step 4: Extend the agent's output `prep` block**

Replace the three-line `prep:` block with:

````yaml
prep:
  branch_at_scan:   <branch name | "unknown">
  refreshed:        true | false
  refresh_note:     <e.g. "switched to main, pulled 12 commits" | "read-only mount; scanned at origin/main" | "skipped per user">
  read_only:        true | false
  scanned_ref:      <ref name, e.g. "origin/main"; the default branch name when writable>
  ref_committed_at: <ISO-8601 timestamp of the ref's newest commit>
  head_divergence:  { branch: <working-tree branch>, ahead: <n>, behind: <n> }
````

- [ ] **Step 5: Restate the two hard rules**

Replace the bullet beginning `- NEVER modify files under `repo_path`.` and the bullet beginning `- NEVER commit, create branches,` with:

````markdown
- NEVER edit, create, or delete files under `repo_path`. NEVER commit, cherry-pick, reset, rebase, or force. This agent reads and classifies.
- Branch switching and fast-forward pulls remain sanctioned prep **on a writable clone** — they change which committed revision is present, not the content of it. Prep operations are limited to `git status`, `git symbolic-ref`, `git remote set-head`, `git switch`, `git pull --ff-only`. On a **read-only** mount none of those run; see `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md`. (The caller's terminal `commit-artifacts` step touches only `$SPECS_PATH` and never dispatches this agent's git.)
````

- [ ] **Step 6: Extend the handoff contract's `prep` block**

In `references/handoff/code-scanner.md`, replace the three-line `prep:` block inside the `## Output` fence with the same seven-line block from Step 4, and immediately after the closing fence add:

````markdown
`prep.read_only`, `prep.scanned_ref`, `prep.ref_committed_at`, and `prep.head_divergence` are always present, so a caller never branches on absence. Every `evidence.path` is relative to the repo root and denotes content **at `scanned_ref`**; on a read-only mount, open one with `git show <scanned_ref>:<path>`. See `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md`.
````

- [ ] **Step 7: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n 'read-only-repos.md' agents/code-scanner.md references/handoff/code-scanner.md
# every prep/scan/hard-rule site that needs the reference must cite it; read the hits
for f in read_only scanned_ref ref_committed_at head_divergence; do
  printf '%s: ' "$f"; grep -c "$f" agents/code-scanner.md references/handoff/code-scanner.md | tr '\n' ' '; echo
done
# each of the four names must be non-zero in BOTH files
grep -n 'git switch\|git pull --ff-only' agents/code-scanner.md
# the writable path must NOT regress — both must still be described as sanctioned prep
```

- [ ] **Step 8: Commit**

```bash
git add plugins/dev-workflows/agents/code-scanner.md plugins/dev-workflows/references/handoff/code-scanner.md
git commit -m "fix(dev-workflows): code-scanner reads at the ref on read-only mounts"
```

---

### Task 5: `diff-summarizer` — read-only prep

**Files:**
- Modify: `plugins/dev-workflows/agents/diff-summarizer.md`
- Modify: `plugins/dev-workflows/references/handoff/diff-summarizer.md`

**Interfaces:**
- Consumes: `references/read-only-repos.md` §1–§6 from Task 1.
- Produces: the same four `prep` fields as Task 4, with identical names and shapes.

Context an implementer needs: this agent's `refresh.fetch` defaults to **true** and `git fetch` writes refs, so a read-only mount fails *before* any PR is resolved — harder than `code-scanner`, which at least reaches a scan. Its handoff already lists `"skipped — RO mount"` as an example `refresh_note`; read-only mounts were documented and never implemented.

- [ ] **Step 1: Insert read-only detection ahead of the refresh steps**

In `## Refresh step`, insert a new item between item 1 (`Verify repo exists`) and item 2 (`Clean-tree check`), renumbering the rest to 3, 4, 5:

````markdown
2. **Read-only detection.** Per `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md` §1, test whether `repo_path` and `repo_path/.git` are writable. On a read-only mount, skip items 3–5 entirely and follow that reference — §2 for what to skip, §3 for ref resolution, §4 for reading at the ref, §5 for when to escalate. `refresh.fetch` writes refs and `refresh.pull` writes the working tree, so neither can run; PR resolution proceeds against the object database as it stands. A read-only mount is NOT `DIRTY_TREE` and NOT `REFRESH_BLOCKED`.
````

Then in the (renumbered) item 5, replace `; `git switch <default>` + `git pull --ff-only`. On any failure return `status: REFRESH_BLOCKED`.` with:

````markdown
; `git switch <default>` + `git pull --ff-only`. On a failure whose error contains `Read-only file system`, enter read-only mode per `read-only-repos.md` §1 and continue there; on any other failure return `status: REFRESH_BLOCKED`.
````

- [ ] **Step 2: Extend the agent's and the handoff's `prep` blocks**

In both `agents/diff-summarizer.md` and `references/handoff/diff-summarizer.md`, replace the `prep:` block with:

````yaml
prep:
  fetched:          true | false
  pulled:           true | false
  refresh_note:     <e.g. "fetched 3 new refs" | "read-only mount; resolved at origin/main" | "tree was dirty, refresh skipped">
  read_only:        true | false
  scanned_ref:      <ref name, e.g. "origin/main"; the default branch name when writable>
  ref_committed_at: <ISO-8601 timestamp of the ref's newest commit>
  head_divergence:  { branch: <working-tree branch>, ahead: <n>, behind: <n> }
````

In `references/handoff/diff-summarizer.md`, immediately after the closing fence of that `## Output` block, add:

````markdown
`prep.read_only`, `prep.scanned_ref`, `prep.ref_committed_at`, and `prep.head_divergence` are always present, so a caller never branches on absence. See `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md`.
````

- [ ] **Step 3: Add the hard rule**

At the end of the agent's hard-rules list, append:

````markdown
- On a read-only mount, NEVER `git fetch`, `git pull`, `git switch`, or `git remote set-head` — all write. Follow `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md` instead of returning `REFRESH_BLOCKED`.
````

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n 'read-only-repos.md' agents/diff-summarizer.md references/handoff/diff-summarizer.md
# the detection step, the switch-failure fallback, the hard rule, and the handoff note must each cite it
grep -n '^[0-9]\.' agents/diff-summarizer.md | sed -n '/Refresh step/,$p'
# confirm the refresh step is numbered 1..5 with no duplicate or skipped number
diff <(grep -A7 '^prep:' agents/diff-summarizer.md) <(grep -A7 '^prep:' references/handoff/diff-summarizer.md)
# expect no differences — the two prep blocks must be identical
```

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/agents/diff-summarizer.md plugins/dev-workflows/references/handoff/diff-summarizer.md
git commit -m "fix(dev-workflows): diff-summarizer resolves PRs on read-only mounts"
```

---

### Task 6: The escalation entry and its five existing consumers

**Files:**
- Modify: `plugins/dev-workflows/references/escalation-rules.md`
- Modify: `plugins/dev-workflows/commands/design.md` (near line 230)
- Modify: `plugins/dev-workflows/commands/specify.md` (near line 342)
- Modify: `plugins/dev-workflows/commands/epics.md` (near line 317)
- Modify: `plugins/dev-workflows/commands/document.md` (near line 407)
- Modify: `plugins/dev-workflows/commands/implement.md` (near line 222)

**Interfaces:**
- Consumes: `prep.read_only`, `prep.scanned_ref`, `prep.ref_committed_at`, `prep.head_divergence` from Tasks 4 and 5.

This task is the **dead-gate guard** for the whole sub-project. Four new output fields and a caller contract ship in Tasks 4 and 5; without this task nothing reads them.

- [ ] **Step 1: Add the escalation entry**

In `references/escalation-rules.md`, insert immediately after the `## Refresh blocked` section:

````markdown
## Read-only mount — ref stale or diverged

`choices: ["Scan released code at `<ref>` (Recommended — cites shipped behavior)", "Scan the working tree at `<branch>` instead — unreleased; citations must say so", "Cancel — refresh on the host (`git -C <path> fetch`) or re-mount read-write, then re-run", "Other… (describe)"]`

Used when `code-scanner` or `diff-summarizer` returns `prep.read_only: true` **and** either `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`, per `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md` §5. Present per affected repo.

A read-only mount is not a failure and does not use the `Refresh blocked` list: the scan proceeds at `prep.scanned_ref`. This prompt exists only because the container cannot fetch, so refreshing the clone is an action only the user can take on the host.

The condition gates the prompt, so the `(Recommended — <why>)` reason annotation is well-formed under the rules at the top of this file.
````

- [ ] **Step 2: Wire the five commands**

In each of `design.md`, `specify.md`, `epics.md`, `document.md`, add a sibling bullet immediately after that file's existing `- `REFRESH_BLOCKED` — escalate…` bullet:

````markdown
- `prep.read_only: true` — not a failure. The scan ran at `prep.scanned_ref`. Escalate per the `Read-only mount — ref stale or diverged` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`; otherwise proceed silently and cite evidence at `prep.scanned_ref`.
````

In `implement.md`, the handling is one line (`A scanner returning `DIRTY_TREE`/`REFRESH_BLOCKED` is surfaced, not hidden.`). Replace it with:

````markdown
   Wait for all scanners in the batch to return. A scanner returning `DIRTY_TREE`/`REFRESH_BLOCKED` is surfaced, not hidden. A scanner returning `prep.read_only: true` is not a failure — it scanned at `prep.scanned_ref`; escalate per the `Read-only mount — ref stale or diverged` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` only when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`, and cite evidence at `prep.scanned_ref`.
````

- [ ] **Step 3: Verify every consumer exists**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -l 'Read-only mount — ref stale or diverged' commands/*.md references/*.md
# expect 6 files: escalation-rules.md + design, specify, epics, document, implement
grep -c 'prep.read_only' commands/*.md | grep -v ':0'
# expect 5 command files, each >=1
```

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/references/escalation-rules.md plugins/dev-workflows/commands/design.md plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/epics.md plugins/dev-workflows/commands/document.md plugins/dev-workflows/commands/implement.md
git commit -m "feat(dev-workflows): read-only mount escalation and its five consumers"
```

---

### Task 7: `/create-ard` and `/release-notes` — their first scan-failure handling

**Files:**
- Modify: `plugins/dev-workflows/commands/create-ard.md` (after the `code-scanner` dispatch, near line 85–90)
- Modify: `plugins/dev-workflows/commands/release-notes.md` (after the `diff-summarizer` dispatch, near line 173)

**Interfaces:**
- Consumes: the escalation entry from Task 6 and the `prep` fields from Tasks 4 and 5.

Context: neither command mentions `REPO_MISSING`, `DIRTY_TREE`, or `REFRESH_BLOCKED` anywhere today. `/create-ard` Phase 1 item 4 even prompts for a repo refresh policy whose recommended option is "fetch + pull default branch" — it can cause the failure and cannot respond to it. This is pre-existing and latent; the read-only work surfaces it.

- [ ] **Step 1: Add the handling block to `/create-ard`**

Immediately after the `code-scanner` dispatch block (the fenced `→ Agent (subagent_type: "dev-workflows:code-scanner"…` block), insert:

````markdown
   **Per-repo scanner status.** Wait for each batch. Handle each returned status before continuing:

   - `OK` / `PARTIAL` / `EMPTY` — use the result. `PARTIAL` and `EMPTY` are data, not failures.
   - `REPO_MISSING` — escalate per the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
   - `DIRTY_TREE` — escalate per the `Dirty working tree` rule in the same file.
   - `REFRESH_BLOCKED` — escalate per the `Refresh blocked` rule in the same file.
   - `prep.read_only: true` — not a failure. The scan ran at `prep.scanned_ref`. Escalate per the `Read-only mount — ref stale or diverged` rule **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`; otherwise proceed silently and cite evidence at `prep.scanned_ref`.

   A repo the user skips is dropped from the confirmed set and named in the Phase 5 handoff; it never silently disappears.
````

- [ ] **Step 2: Add the handling block to `/release-notes`**

Immediately after the sentence `Collect the outputs into a `diff_summaries` array.`, insert:

````markdown
**Per-repo summarizer status.** Handle each returned status before continuing:

- `OK` / `PARTIAL` / `NO_PRS_RESOLVED` — use the result; record unresolved PRs in the run report.
- `REPO_MISSING` — escalate per the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`.
- `DIRTY_TREE` — escalate per the `Dirty working tree` rule in the same file.
- `REFRESH_BLOCKED` — escalate per the `Refresh blocked` rule in the same file.
- `prep.read_only: true` — not a failure. Resolution ran at `prep.scanned_ref`. Escalate per the `Read-only mount — ref stale or diverged` rule **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`; otherwise proceed silently.

Diff grounding is opt-in and advisory here: a repo the user skips degrades the grounding, never the run.
````

- [ ] **Step 3: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
for f in create-ard release-notes; do
  printf '%s: ' "$f"
  grep -c 'REPO_MISSING\|DIRTY_TREE\|REFRESH_BLOCKED\|prep.read_only' commands/$f.md
done   # expect 4 each
grep -c 'escalation-rules.md' commands/create-ard.md commands/release-notes.md   # expect >=1 each
```

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/commands/create-ard.md plugins/dev-workflows/commands/release-notes.md
git commit -m "fix(dev-workflows): create-ard and release-notes handle scan failures"
```

---

### Task 8: The plan-approval line in its six consumers

**Files:**
- Modify: `plugins/dev-workflows/commands/idea.md` (near line 74)
- Modify: `plugins/dev-workflows/commands/create-vi.md` (near line 48)
- Modify: `plugins/dev-workflows/commands/update-vi.md` (near line 37)
- Modify: `plugins/dev-workflows/commands/create-ard.md` (near line 38)
- Modify: `plugins/dev-workflows/commands/specify.md` (near line 102)
- Modify: `plugins/dev-workflows/commands/epics.md` (the docs-grounding paragraph, near line 322)

**Interfaces:**
- Consumes: the line forms owned by `references/docs-grounding.md` from Task 3.

- [ ] **Step 1: Update the five verbatim quotations**

In `idea.md`, `create-vi.md`, `update-vi.md`, `create-ard.md`, and `specify.md`, replace each occurrence of

```
Show the `docs grounding: ON <root> | OFF (<reason>)` line (off switch: --no-docs).
```

with

```
Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).
```

Note the leading list marker and indentation differ between files (`idea.md` has none; the other four are indented list items). Preserve each file's existing prefix exactly.

- [ ] **Step 2: Give `/epics` the line it never had**

In `epics.md`, at the end of the `**Documentation grounding (optional, independent of code scan).**` paragraph, append:

```
Show the `docs grounding:` line that `resolve-docs-grounding` returned, verbatim, in this phase's plan/approval output — including any index-build, staleness, or shadowing clause (off switch: --no-docs).
```

- [ ] **Step 3: Verify all six**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -l 'docs grounding:' commands/*.md
# expect these 6: idea, create-vi, update-vi, create-ard, specify, epics.
# release-notes is NOT among them — it writes "docs grounding on/off" without a colon, in prose, and is left alone.
grep -c 'retrieval' commands/idea.md commands/create-vi.md commands/update-vi.md commands/create-ard.md commands/specify.md commands/epics.md
# expect >=1 each
grep -n 'docs grounding: ON <root> | OFF' commands/*.md
# expect NO output — the old single-form quotation must be gone everywhere
```

`/release-notes` already describes the line in prose in its Plan step and is compatible as written; do not edit it in this task.

- [ ] **Step 4: Commit**

```bash
git add plugins/dev-workflows/commands/idea.md plugins/dev-workflows/commands/create-vi.md plugins/dev-workflows/commands/update-vi.md plugins/dev-workflows/commands/create-ard.md plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/epics.md
git commit -m "feat(dev-workflows): surface qmd retrieval state on the docs-grounding line"
```

---

### Task 9: Canonical version bump, changelog, catalog, source-truth bullet

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json`
- Modify: `plugins/dev-workflows/CHANGELOG.md`
- Modify: `.claude-plugin/marketplace.json` (repo root)
- Modify: `CLAUDE.md` (repo root)

- [ ] **Step 1: Bump both version fields**

Set `version` to `2.47.0` in `plugins/dev-workflows/.claude-plugin/plugin.json`, and in the **`dev-workflows` entry only** of the root `.claude-plugin/marketplace.json`. The catalog lists four plugins; a blind bump corrupts three siblings.

- [ ] **Step 2: Add the changelog entry**

At the top of `plugins/dev-workflows/CHANGELOG.md`, above the existing newest entry:

````markdown
## 2.47.0 — Environment guards

- `docs-grounder` no longer builds the qmd index. It probes (`qmd status`, `qmd collection list`) and selects a retrieval rung: `qmd-vector` (`qmd search` + `qmd vsearch`, when the collection has embeddings), `qmd-lexical` (`qmd search` alone), or `fallback`. `qmd query` is never invoked — it is the only entry point needing the reranking and query-expansion models, which no cheap probe can prove are cached. Previously the agent was instructed to "self-heal" with `qmd collection add` + `qmd embed`, which on a fresh container means a ~1.3 GB model download and embedding every page in `$DOCS_PATH` on the user's critical path.
- Index building and refreshing move into `resolve-docs-grounding` step 3.5, under user consent: an existing collection gets a bounded incremental `qmd update`, a missing one gets a one-time build prompt. An agent cannot ask the user; the orchestrator can.
- The keyword fallback is bounded — 3–8 keywords, generic keywords dropped above 200 matching files, shortlist capped at 40 — so the qmd fix does not relocate the cost into an unbounded scan.
- New `references/read-only-repos.md`. `code-scanner` and `diff-summarizer` now read at `origin/<default>` via `git ls-tree` / `git grep <ref>` / `git show <ref>:<path>` on read-only mounts instead of returning `REFRESH_BLOCKED`; a read-only mount also skips the dirty-tree gate, since the working tree is never mutated. Writable mounts are unchanged. Both agents report `prep.read_only`, `prep.scanned_ref`, `prep.ref_committed_at`, and `prep.head_divergence`.
- New `Read-only mount — ref stale or diverged` escalation, fired only when the ref is more than 14 days old or the working tree is ahead of it, offering a host-side `git fetch` or a read-write re-mount.
- `/create-ard` and `/release-notes` gain their first handling for `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED`; `/epics` gains the `docs grounding:` line it never printed.
- The `docs grounding:` line now reports the retrieval rung, a stale docs checkout, a capped index refresh, and a project-local `.qmd` index shadowing the user-scope one.
````

- [ ] **Step 3: Add the source-truth bullet to the root `CLAUDE.md`**

In the `## Source-truth reference` section, after the `specs-repo-git.md` paragraph, insert:

````markdown
`plugins/dev-workflows/references/read-only-repos.md` is the **single source of truth** for read-only repository mounts — the detection probe (`test -w` on the repo and `.git`, plus the `Read-only file system` error as a secondary trigger), what read-only mode skips (`fetch`/`pull`/`switch`/`remote set-head`, and the dirty-tree gate), write-free ref resolution and reading (`ls-tree`, `git grep <ref>`, `git show <ref>:<path>`), the 14-day staleness / ahead-of-ref escalation trigger, and the `prep` output contract (`read_only`, `scanned_ref`, `ref_committed_at`, `head_divergence`). Consumed by `code-scanner`, `diff-summarizer`, and `docs-grounder`, and cited by the seven commands that dispatch them. Writable mounts are unaffected: `git switch` and `git pull --ff-only` remain sanctioned prep on a writable clone.
````

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -n '"version"' plugins/dev-workflows/.claude-plugin/plugin.json
python3 -c "import json;d=json.load(open('.claude-plugin/marketplace.json'));print([(p['name'],p.get('version')) for p in d['plugins']])"
# only dev-workflows may have changed, and it must read 2.47.0
head -3 plugins/dev-workflows/CHANGELOG.md
grep -c 'read-only-repos.md' CLAUDE.md   # expect 1
```

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json plugins/dev-workflows/CHANGELOG.md .claude-plugin/marketplace.json CLAUDE.md
git commit -m "chore(dev-workflows): 2.47.0 — environment guards"
```

---

### Task 10: Port to `mgd-claude-plugins`

**Files:**
- Copy from canonical: the 18 changed files under `plugins/dev-workflows/` (derive the list; do not type it)
- Hand-edit: `plugins/dev-workflows/CHANGELOG.md`, `plugins/dev-workflows/.claude-plugin/plugin.json`, repo-root `CLAUDE.md`, repo-root `.claude-plugin/marketplace.json`

**Never `cp` the repo-root `CLAUDE.md`** — it carries edition-specific paths, and copying it silently dropped 18 lines during sub-project C.

- [ ] **Step 1: Create the branch and derive the file list**

```bash
cd /workspace/mgd-claude-plugins && git switch -c iv-gu/environment-guards
cd /workspace/ihudak-claude-plugins
git diff --name-only main..HEAD -- plugins/dev-workflows/ \
  | grep -v -E '(CHANGELOG\.md|\.claude-plugin/plugin\.json)$' > /tmp/f-port-list.txt
cat /tmp/f-port-list.txt
```

- [ ] **Step 2: Copy each file**

```bash
cd /workspace/ihudak-claude-plugins
while read -r f; do
  mkdir -p "/workspace/mgd-claude-plugins/$(dirname "$f")"
  cp "$f" "/workspace/mgd-claude-plugins/$f"
done < /tmp/f-port-list.txt
```

- [ ] **Step 3: Hand-edit the four identity files**

Set `version` to `2.47.0` in mgd's `plugins/dev-workflows/.claude-plugin/plugin.json` and in the `dev-workflows` entry of mgd's root `.claude-plugin/marketplace.json`. Add the same changelog entry as Task 9 Step 2 to mgd's `plugins/dev-workflows/CHANGELOG.md`, with `(ported from `ihudak-claude-plugins`)` appended to the heading line, matching the annotation style of the entries already there. Add the Task 9 Step 3 source-truth paragraph to mgd's root `CLAUDE.md` **by hand**, in the same position.

- [ ] **Step 4: Verify parity — exactly six identity files differ**

```bash
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows /workspace/mgd-claude-plugins/plugins/dev-workflows
# expect exactly: .claude-plugin/plugin.json, LICENSE, README.md, references/dependencies.md, CHANGELOG.md
diff -q /workspace/ihudak-claude-plugins/CLAUDE.md /workspace/mgd-claude-plugins/CLAUDE.md
diff -q /workspace/ihudak-claude-plugins/.claude-plugin/marketplace.json /workspace/mgd-claude-plugins/.claude-plugin/marketplace.json
```

A **seventh** differing file is the signal that something was missed. `references/dependencies.md` differing is CORRECT — it names the `mgd-plugins` marketplace, which is identity, not drift; it was mislabelled as drift by three reviewers during sub-project C.

- [ ] **Step 5: Commit**

```bash
cd /workspace/mgd-claude-plugins
git add -A && git commit -m "chore(dev-workflows): 2.47.0 — environment guards (ported)"
```

---

### Task 11: Port to `ihudak-copilot-plugins`

**Files:**
- Create: `dev-workflows/skills/_shared/read-only-repos.md`
- Modify: the `_shared` counterparts of `docs-grounding.md`, `escalation-rules.md`, and both handoff contracts
- Modify: `dev-workflows/agents/{docs-grounder,code-scanner,diff-summarizer}.md`
- Modify: the `SKILL.md` of each command changed in Tasks 6–8
- Modify: `dev-workflows/README.md` (`_shared` reference list), `.github/copilot-instructions.md` if it describes changed behavior
- Modify: `dev-workflows/.plugin/plugin.json`, `CHANGELOG.md`, `.github/plugin/marketplace.json`

Adapt, never copy. Dialect rules: references are addressed as `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<file>.md`, **not** `${CLAUDE_PLUGIN_ROOT}/references/<file>.md`; agent dispatch is `→ task(agent_type: "dev-workflows:X", model: …)`, not `Agent (subagent_type: …)`; commands are named `<name>:`, not `/<name>`.

- [ ] **Step 1: Branch and derive the target list**

```bash
cd /workspace/ihudak-copilot-plugins && git switch -c iv-gu/environment-guards
ls dev-workflows/skills/_shared/ | grep -E 'docs-grounding|escalation|handoff'
find dev-workflows -path '*handoff*' -name '*.md'
```

Confirm where the copilot edition keeps the two handoff contracts before editing — the location differs from canonical's `references/handoff/` and must be **found**, not assumed.

- [ ] **Step 2: Create `_shared/read-only-repos.md`**

Same content as Task 1, with every `${CLAUDE_PLUGIN_ROOT}/references/<file>.md` rewritten to `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<file>.md`.

- [ ] **Step 3: Apply Tasks 2–8's changes to the copilot counterparts**

Work task by task in the same order, translating paths and dispatch syntax. The content decisions — rung table, timeouts, Path B bounds, escalation `choices:` array, `prep` fields, line forms — are identical; only addressing changes.

- [ ] **Step 4: Bump to 2.17.0 in all three places**

`dev-workflows/.plugin/plugin.json`, the `dev-workflows` entry of `.github/plugin/marketplace.json`, and a `CHANGELOG.md` entry. **The catalog is at `.github/plugin/marketplace.json`, not `.claude-plugin/`** — it has been missed three times, most recently in sub-project D where the plan carried an explicit warning about catalogs and still listed only two of the three.

- [ ] **Step 5: Add the `_shared` reference bullet**

Copilot has no root `CLAUDE.md`; its equivalent index is the `_shared` reference list in `dev-workflows/README.md`. Add a bullet for `read-only-repos.md` next to the `docs-grounding.md` entry.

- [ ] **Step 6: Verify the dialect is clean**

```bash
cd /workspace/ihudak-copilot-plugins
git diff --name-only main..HEAD | while read -r f; do
  if grep -q 'CLAUDE_PLUGIN_ROOT\|subagent_type\|Agent (subagent_type' "$f" 2>/dev/null; then echo "LEAK: $f"; fi
done   # expect no output
find . -name 'marketplace.json'   # confirm .github/plugin/marketplace.json was the one edited
grep -n '"version"' dev-workflows/.plugin/plugin.json
```

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "chore(dev-workflows): 2.17.0 — environment guards"
```

---

### Task 12: Whole-branch verification sweep

**Files:** none modified unless a check fails.

Run every check from spec §8. **Re-derive each expected value from the tree** — never restate it from the spec or this plan. A check that reads its expectation from the artifact under test passes by confirming its own error; that is how sub-project D shipped a wrong collision count through four documents and a "passing" verification.

- [ ] **Step 1: Half A checks (V1–V4, V11–V13), all three editions**

```bash
for r in /workspace/ihudak-claude-plugins/plugins/dev-workflows \
         /workspace/mgd-claude-plugins/plugins/dev-workflows \
         /workspace/ihudak-copilot-plugins/dev-workflows; do
  echo "=== $r ==="
  g=$(ls "$r"/agents/docs-grounder.md 2>/dev/null)
  echo "V1 mutating invocations (each hit must be inside a NEVER bullet):"
  grep -n 'qmd collection add\|qmd collection remove\|qmd collection rename\|qmd embed\|qmd update\|qmd init\|qmd cleanup' "$g"
  echo "V2 qmd query occurrences (all must be ban prose):"; grep -n 'qmd query' "$g"
  echo "V3 retrieval enum:"; grep -c 'qmd-vector\|qmd-lexical' "$g"
  echo "V12 Path B bounds:"; grep -c '200 files\|40 files\|3–8' "$g"
done
```

- [ ] **Step 2: V11 — the validity gate is byte-unchanged**

```bash
cd /workspace/ihudak-claude-plugins
git diff main..HEAD -U0 -- plugins/dev-workflows/references/docs-grounding.md \
  | grep -E '^-.*(non-empty|test -d|test -r|find "\$docs_root")'
# expect NO output. REMOVALS only — the new step 3.5 legitimately adds its own `find "$docs_root"
# … -name '*.md' | wc -l`, so a pattern matching '+' lines fails on correct work.
```

- [ ] **Step 3: V6–V9 — Half B wiring and the dead-gate check**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
echo "V6 agents citing the reference:"; grep -l 'read-only-repos.md' agents/*.md   # expect 3
echo "V7 commands citing the escalation (THE dead-gate check):"
grep -l 'Read-only mount — ref stale or diverged' commands/*.md   # expect 7
echo "V9 handoff prep fields:"
for f in references/handoff/code-scanner.md references/handoff/diff-summarizer.md; do
  printf '%s: ' "$f"; grep -c 'read_only\|scanned_ref\|ref_committed_at\|head_divergence' "$f"
done
echo "V8 escalation entry shape:"; grep -A3 'Read-only mount — ref stale or diverged' references/escalation-rules.md
```

V7 expecting 7 is the one number to check hardest: five commands from Task 6 plus `/create-ard` and `/release-notes` from Task 7. If the actual count is lower, a command dispatches one of these agents and cannot see its new fields — that is the defect this task exists to catch, not a number to relax.

- [ ] **Step 4: V10 — no regression on writable mounts**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -n 'git switch\|git pull --ff-only' agents/code-scanner.md agents/diff-summarizer.md
# both agents must still describe the writable path
```

- [ ] **Step 5: V14–V18 — cross-repo**

```bash
diff -rq /workspace/ihudak-claude-plugins/plugins/dev-workflows /workspace/mgd-claude-plugins/plugins/dev-workflows
# V14 — expect exactly 5 here plus the 2 root files checked separately = 6 identity files
for r in /workspace/ihudak-claude-plugins /workspace/mgd-claude-plugins /workspace/ihudak-copilot-plugins; do
  echo "=== $r ==="; (cd "$r" && find . -name 'marketplace.json' -not -path './node_modules/*')
done
# V15 — three catalogs, all three must carry the new version
```

- [ ] **Step 6: Write the results table**

Create `docs/superpowers/plans/2026-08-11-environment-guards-verification.md` with one row per check: check id, command run, actual value, pass/fail, and — where an expectation in this plan proved wrong — which was wrong, the plan or the content.

- [ ] **Step 7: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add docs/superpowers/plans/2026-08-11-environment-guards-verification.md
git commit -m "docs(dev-workflows): F verification results"
```

---

## Self-review

**Spec coverage.** §4.1 rung ladder → Task 2 Step 1. §4.2 index maintenance → Task 3 Step 1. §4.3 Path B bounding → Task 2 Step 2. §4.4 hard rules → Task 2 Step 5. §4.5 plan-approval line → Task 3 Step 2 (format) + Task 8 (consumers). §5.1–§5.6 read-only contract → Task 1, applied in Tasks 4 and 5. §5.4 escalation → Task 6 Step 1. §5.5 output + handoff contracts → Tasks 4 Step 6, 5 Step 2. §5.7 command wiring → Tasks 6 and 7. §6 file inventory → Tasks 9, 10, 11. §8 verification → Task 12. §3.2's non-goals are enforced negatively: Task 3 Step 4 asserts the §3 gate is unchanged, and Task 2 Step 6 asserts `qmd query` appears only as prose.

**Interface consistency.** The four `prep` field names are written identically in Task 1 §6, Task 4 Steps 4 and 6, Task 5 Step 2, Task 6 Steps 1 and 2, and Task 7 Steps 1 and 2. The `retrieval` enum is written identically in Task 2 Steps 1 and 4 and Task 3 Steps 1 and 2. The escalation entry title `Read-only mount — ref stale or diverged` is written identically in Tasks 6, 7, and 12 — an em dash, not a hyphen, because Task 12's `grep -l` matches it literally.

**Known ordering constraint.** Task 1 must precede Tasks 2, 4, 5, 6, and 7, which cite the file it creates. Tasks 10 and 11 must follow Task 9. Task 12 is last.
