# Environment guards (sub-project F) — design

**Ships as:** `dev-workflows` 2.47.0 (canonical + mgd) / 2.17.0 (copilot).

**Source:** two entries of the 2026-08-06 `/idea` feedback round (`$SPECS_PATH/dev-workflows-feedback/2026-08-06.md`) — `idea-docs-grounder-qmd-embed-stampede` and `idea-code-scanner-readonly-mount-fallback`. F is the first of three sub-projects (F/G/H) closing that round; G is prior-art discovery, H is `/idea` code grounding plus gate polish.

**Goal:** make three read-only agents behave correctly in the container environment they actually run in — no unbounded work on a user's critical path, no failure on a read-only mount, and every degradation named where a user can see and act on it.

---

## 1. The problem is one defect class, not two entries

Both entries are the same defect: **an agent that declares itself read-only performs a write in its prep step, and the write is what breaks.**

- `agents/docs-grounder.md` says "NEVER write or edit any file. Read-only." — then Path A step 1 instructs `qmd collection add "<docs_path>" --name docs` followed by `qmd embed`. On the reported run that began a 1.28 GB model download and re-embedded 15,330 of 25,519 files.
- `agents/code-scanner.md` says "NEVER modify files under `repo_path`" — then prescribes `git switch`, via a carve-out inside that same rule. On a read-only mount it fails with `Unable to create '.git/index.lock': Read-only file system` and the agent returns `REFRESH_BLOCKED`.

Neither is a missing guard. Each is an instruction that contradicts the agent it lives in.

The deeper cause of the first is structural and worth stating once, because it generalises: **an agent cannot ask.** Told to self-heal, `docs-grounder` had exactly two options — burn many minutes silently, or abort on its own judgment — and it took the second. Expensive work that needs consent must live where consent is possible, which is the orchestrator, not the agent. That single observation is what shapes §4.2.

## 2. Premise corrections

Verified against the tree on 2026-08-11. Seven things differ from what the feedback recorded or implies.

1. **`docs-grounding.md` §3's validity gate is correct and must not change.** The friction text observes that §3 "never checks whether the retrieval index is usable", which invites extending it. It must not be extended: §3 decides whether docs grounding runs *at all*, and Path B works with no index whatsoever. An index check there would disable grounding precisely where the fallback still works. The defect site is the agent's Path A precondition.
2. **The fix is not "never build the index".** Banning index maintenance outright leaves grounding permanently degraded, which is a worse outcome than the stampede. Building is legitimate — under consent, in the command, once (§4.2).
3. **The stampede is the default state of a fresh container, not an edge case.** On this machine `qmd status` reports `0 files indexed / 0 vectors / No collections` while `/workspace/docs` is a valid docs root. Every `/idea` run on a fresh container reaches the self-heal line.
4. **The qmd hazard is broader than embedding.** `qmd query` — the command the agent is told to use — needs *three* models: embedding, reranking (Qwen3-Reranker-0.6B), and query expansion (qmd-query-expansion-1.7B). `~/.cache/qmd/` on this container holds `index.sqlite` and nothing else, so no cheap probe can prove any of them are cached. Only `qmd search` is documented as needing no model at all ("Full-text BM25 keywords (no LLM)").
5. **Path B is unbounded**, so fixing entry 1 alone would have relocated the stampede rather than removed it. Path B scores "each page's frontmatter + first ~50 body lines"; the Bounding section's cap of 8 applies to *reading* after scoring, not to the enumeration. Over 25,519 files that pass is itself the expensive operation, and the qmd fix routes more runs into it.
6. **`diff-summarizer` has the same read-only exposure and fails harder.** Its `git fetch origin` is default-ON (`refresh.fetch: true`) and writes refs, so a read-only mount returns `REFRESH_BLOCKED` before a single PR is resolved — that is `/document` Jira mode and `/release-notes` diff grounding. The feedback names only `code-scanner`.
7. **`/create-ard` and `/release-notes` dispatch these agents with no failure handling at all.** Neither command mentions `REPO_MISSING`, `DIRTY_TREE`, or `REFRESH_BLOCKED`. `/create-ard` Phase 1 even prompts for a repo refresh policy whose recommended option is "fetch + pull default branch" — it can cause the failure and cannot respond to it. Pre-existing, latent, and squarely on F's theme.

Two conditions were confirmed live rather than assumed: `/workspace/docs` is read-only **right now** (tree and `.git` both), and 2 of 12 repos under `/workspace` are read-only today (`docs`, `observability-requirements`). Half B guards a current condition, not a hypothetical.

## 3. Scope

### 3.1 In scope

- `agents/docs-grounder.md` — retrieval rung ladder, index-mutation ban, Path B bounding, hard-rule restatement.
- `references/docs-grounding.md` — the Phase 0 index probe, consent-gated build, bounded refresh, and the extended plan-approval line.
- `references/read-only-repos.md` (new) — the read-only-mount contract shared by all three git-touching agents.
- `agents/code-scanner.md`, `agents/diff-summarizer.md` — read-only prep and ref-mode reading.
- `references/escalation-rules.md` — the host-refresh escalation.
- `references/handoff/code-scanner.md`, `references/handoff/diff-summarizer.md` — the new `prep` fields.
- The seven commands that dispatch either agent, plus the docs-grounding consumers.

### 3.2 Explicit non-goals, with reasons

- **No `--build-docs-index` flag and no `/docs-index` maintenance command.** §4.2 offers the build exactly when it is needed and refreshes incrementally on every grounded run, so neither adds capability. A flag would mean new surface on seven commands across three repos for something already handled.
- **`docs-grounding.md` §3's validity gate is byte-unchanged** (§2 item 1).
- **The plugin never uses `qmd init`.** Not because writing is risky — the user-scope index at `~/.cache/qmd/` is outside every git working tree (`$HOME` is not a repo here), so touching it is unproblematic. Because a project-local `.qmd/` index resolves relative to **cwd**, and this plugin's commands routinely run standing in a different repo from the one they read; retrieval would become silently cwd-dependent. It is also impossible for the one root that matters: `/workspace/docs` is read-only. A user who runs `qmd init` manually gets told (§4.5, shadow detection) rather than silently degraded.
- **No rule forbidding an orchestrator's ad-hoc reads of a repo working tree**, beyond the one-sentence caller contract in §5.5. The reported harm — citing `docs/setup-remote.md` from an unmerged branch as released behavior — happened *before* the agent returned, so no agent-side change reaches it. A general discipline for direct repo reads has no consumed surface today and is its own sub-project.

---

## 4. Half A — qmd retrieval and index maintenance

### 4.1 The rung ladder (in the agent)

Path A step 1's self-heal is deleted. The agent probes with two model-free, mutation-free calls — `timeout 10s qmd status` and `timeout 10s qmd collection list` — and selects a rung:

| Rung | Precondition | Retrieval | `retrieval:` value |
|---|---|---|---|
| 1 | a collection covers `docs_path` **and** the index reports embedded vectors > 0 | `timeout 30s qmd search` + `timeout 30s qmd vsearch`, hits unioned | `qmd-vector` |
| 2 | a collection covers `docs_path`, vectors == 0 | `timeout 30s qmd search` | `qmd-lexical` |
| 3 | no collection covers `docs_path`, `qmd` absent, or either probe fails | Path B (§4.3) | `fallback` |

Reading the selected hits is unchanged: `qmd get` or `Read`, capped at the top 8 per the existing Bounding section.

Two mechanics the implementer must not have to guess. **Where "vectors > 0" comes from:** prefer `qmd collection show <name>` when it reports a per-collection embedding count, since a global count from `qmd status` can be satisfied by a *different* collection; fall back to the global count when it does not, and rely on the 30s cap (R3) to catch the residual case. **How rung 1 unions two ranked lists:** interleave `qmd search` and `qmd vsearch` results by rank position, dedupe by path keeping the better rank, and truncate at the Bounding cap of 8.

**`qmd query` is never invoked.** It is the only entry point requiring the reranker and query-expansion models on top of the embedding model, and no cheap probe can prove those are cached. `vectors > 0` proves the *embedding* model ran on this machine, which is exactly what makes `qmd vsearch` provably safe and `qmd query` not. What is given up is rank polish on a retrieval that is capped at 8 pages and is advisory-only — never a gate, never a reviewer BLOCKER.

**The timeout is the backstop, not the primary guard.** Every qmd invocation runs under an explicit wall-clock cap; a timeout or non-zero exit drops one rung. This catches anything qmd does that this design did not anticipate, without requiring the design to model qmd's internals.

### 4.2 Index maintenance (in the command, consent-gated)

`resolve-docs-grounding` in `references/docs-grounding.md` gains **step 3.5 — index state**, run after the §3 validity gate passes and only when `command -v qmd` succeeds. It probes with the same two calls and takes one of three branches:

**A collection covers `docs_root`** → `timeout 60s qmd update`. Incremental (qmd re-indexes only changed files), instant when nothing changed, and a killed run rolls back because the index is SQLite. On a cap breach, prompt once rather than silently paying 60s on every future run:

```
choices: ["Continue with the current index — some pages may be stale (Recommended)",
          "Finish the refresh now — uncapped",
          "Turn docs grounding off for this run",
          "Other… (describe)"]
```

**No collection covers `docs_root`** → prompt once, at plan approval, before any of the run's real work:

```
choices: ["Build the docs index now — one-time, <N> markdown files, downloads a ~1.3 GB model on first use (Recommended — every later run is faster and better grounded)",
          "Skip — ground with keyword fallback this run",
          "Turn docs grounding off for this run",
          "Other… (describe)"]
```

`<N>` comes from `find "$docs_root" -type f -name '*.md' | wc -l`. A consented build runs `qmd collection add "<docs_root>" --name docs` then `qmd embed`, **uncapped** — killing a consented build wastes the work it already did — and reports elapsed time. The prompt disappears permanently once the index exists.

**`qmd` absent** → `retrieval: fallback`, silent, exactly as today.

`resolve-docs-grounding` returns `retrieval` alongside `{ docs_grounding, docs_root, reason }`. The agent re-probes and its rung selection is authoritative; the command's probe exists to drive the prompts and the displayed line. Both probes are two SQLite reads.

**Why the split.** The agent never mutates the index and never prompts; the command does both. That is the fix for §1's structural cause, and it is what makes a permanently-absent index impossible without the user having declined it in so many words.

### 4.3 Path B bounding

Path B's step 1 gains an explicit bound, because it is now where every qmd miss lands:

- Derive **3–8** salient keywords from `feature_summary` + `themes`, minus stopwords.
- Shortlist candidates with `Grep` in files-with-matches mode, one pass per keyword. **Drop any keyword returning more than 200 files** as too generic to discriminate.
- Union the surviving hits and **cap the shortlist at 40 files** (highest keyword-hit count first).
- Score only the shortlist on frontmatter + first ~50 body lines. **Never enumerate the whole root.**
- Empty shortlist → `status: EMPTY` with a `notes` line, which the caller already handles.

The git-grep backstop (step 2) is unchanged in behavior and gains a cross-reference to `references/read-only-repos.md`; its existing claim that `git log` is a pure read that works on a read-only `.git` is correct.

### 4.4 Hard rules, restated

`docs-grounder`'s hard rules become, replacing "NEVER write or edit any file. Read-only." — which is already false, since `qmd status` alone creates `~/.cache/qmd/index.sqlite`:

- NEVER write into `$DOCS_PATH`, any git working tree, or any repository.
- MAY read and touch the user-scope qmd index under `~/.cache/qmd/` — qmd's read commands create and update that file (`qmd status` alone creates it), and it lies outside every git working tree.
- NEVER **build or refresh** the index from inside this agent: no `qmd collection add`, `qmd collection remove`, `qmd collection rename`, `qmd embed`, `qmd update`, `qmd init`, `qmd cleanup`. Building and refreshing belong to `resolve-docs-grounding` (§4.2), which can ask.
- NEVER run `qmd init` anywhere (§3.2), and NEVER run `qmd update --pull` (it writes into a possibly-read-only docs clone).
- NEVER run `qmd query`. Use the §4.1 ladder.
- Every qmd invocation carries an explicit wall-clock cap.

### 4.5 The plan-approval line

`docs-grounding.md` owns the format; the consumer commands quote it. Forms:

```
docs grounding: ON <root> (retrieval: qmd-vector)
docs grounding: ON <root> (retrieval: qmd-lexical — index has no embeddings)
docs grounding: ON <root> (retrieval: qmd-vector; index refresh exceeded 60s — some pages may be stale)
docs grounding: ON <root> (retrieval: qmd-vector; docs checkout <N> days old — refresh on the host)
docs grounding: ON <root> (retrieval: fallback — no qmd index; build once: qmd collection add "<root>" --name docs && qmd embed)
docs grounding: ON <root> (retrieval: fallback — a project-local .qmd index in <cwd> is shadowing the user-scope one; run from another directory or remove it)
docs grounding: OFF (<reason>)
```

**Docs-checkout staleness.** A fresh index over a stale checkout still grounds on stale docs, and a read-only docs mount cannot be pulled from inside the container. One pure read — `git -C "$docs_root" log -1 --format=%cI`, skipped silently when the root is not a git checkout — appends the clause when the newest commit is older than the **14-day** threshold shared with §5.4. Quiet in the healthy case: `/workspace/docs` here is on `main` at 2026-08-11T04:42Z.

**Shadow detection.** `qmd status` prints `Index: <path>` as its first line, which the probe already parses. When that path is not the user-scope `~/.cache/qmd/index.sqlite`, a project-local `.qmd` index in the current directory is shadowing it; name that cause instead of reporting a generic miss. One string comparison on output already in hand, and it converts an invisible degradation into a diagnosis.

**Consumers.** Five commands quote the line verbatim today (`/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`); `/release-notes` describes it in prose in its Plan step and is compatible as written; **`/epics` prints nothing at all and gains the line**, making the reference's "Plan-approval line" section true for all seven consumers rather than five.

---

## 5. Half B — read-only mounts

New shared reference `references/read-only-repos.md`, cited by `agents/code-scanner.md`, `agents/diff-summarizer.md`, and `agents/docs-grounder.md`.

**Nothing changes for writable mounts.** `git switch` and `git pull --ff-only` remain sanctioned prep on a writable clone: they change which committed revision is present, not the content of it. The read-only path is purely additive and is reached only when the mount is read-only.

### 5.1 Detection

Before any mutating git call: read-only iff `test -w "<repo_path>"` fails **or** `test -w "<repo_path>/.git"` fails. Secondary trigger: any git error containing `Read-only file system` — on that, retry in read-only mode rather than returning `REFRESH_BLOCKED`.

A false positive is benign: the agent reads at `origin/<default>`, which is what a caller passing `switch_to_default_branch: true` asked for anyway.

### 5.2 Read-only mode

Skipped entirely: `git fetch`, `git pull`, `git switch`, `git remote set-head` — all write. Also skipped: **the dirty-tree gate**. A dirty working tree is irrelevant when the working tree is never mutated, so read-only mode never returns `DIRTY_TREE` and is strictly *more* robust than the writable path.

Ref resolution without writes: `git symbolic-ref --short refs/remotes/origin/HEAD` → else `git rev-parse --verify origin/main` → else `git rev-parse --verify origin/master`. An exhausted chain is a genuine `REFRESH_BLOCKED`.

Two facts, both pure reads:

- ref age — `git log -1 --format=%cI <ref>`
- divergence — `git rev-list --left-right --count <ref>...HEAD`, plus `git rev-parse --abbrev-ref HEAD`

### 5.3 Scan targets

Both are write-free:

- **Working tree**, with native `Grep`/`Glob`.
- **The ref**, via `git ls-tree -r --name-only <ref>` to enumerate, `git grep -n <pattern> <ref> -- <pathspec>` to search, and `git show <ref>:<path>` to read. None consults or writes the index.

**When HEAD is already at the ref — `git rev-parse HEAD` equals `git rev-parse <ref>` — scan the working tree natively.** Identical content, better tooling, so the common read-only case costs nothing. Otherwise read at the ref.

If `git grep <tree-ish>` is unavailable or errors, fall back to `git show`-per-file over an `ls-tree` shortlist; if that also fails, `REFRESH_BLOCKED` as today.

### 5.4 Escalation

Fires **only** when the ref's newest commit is older than **14 days**, or when HEAD is **ahead** of the ref by one or more commits. HEAD merely *behind* the ref is silent — the scan reads the ref, so being behind locally changes nothing. On a healthy read-only mount sitting at the default branch, the run proceeds with no prompt.

New entry in `references/escalation-rules.md`:

```
## Read-only mount — ref stale or diverged

choices: ["Scan released code at `<ref>` (Recommended — cites shipped behavior)",
          "Scan the working tree at `<branch>` instead — unreleased; citations must say so",
          "Cancel — refresh on the host (`git -C <path> fetch`) or re-mount read-write, then re-run",
          "Other… (describe)"]
```

Presented per affected repo. The condition gates the prompt, so the `(Recommended — <why>)` reason annotation is well-formed under that file's own rules.

### 5.5 Output and handoff contract

Both agents' `prep` block, and both handoff references, gain four fields — always present, so a consumer never branches on absence:

```yaml
prep:
  read_only:        true | false
  scanned_ref:      <ref name, e.g. "origin/main" | the default branch when writable>
  ref_committed_at: <ISO-8601 timestamp of the ref's newest commit>
  head_divergence:  { branch: <name>, ahead: <n>, behind: <n> }
```

`evidence.path` keeps its documented meaning — a path relative to the repo root — and now denotes content **at `scanned_ref`**. A caller that wants to open one on a read-only mount uses `git show <scanned_ref>:<path>`.

**Caller contract**, one sentence in the new reference and cited by the dispatching commands: a caller reading repo files directly must first confirm HEAD is at the remote default ref, or cite via `scanned_ref`.

### 5.6 Hard rules, restated

`code-scanner`'s rule becomes: NEVER edit, create, or delete files under `repo_path`; never commit, cherry-pick, reset, rebase, or force. Branch switching and fast-forward pulls remain sanctioned prep **on a writable clone**. Read-only mounts take the ref path instead. `diff-summarizer` gains the equivalent.

### 5.7 Command wiring

The seven commands that dispatch either agent cite the new reference and the new escalation entry: `/implement`, `/document`, `/epics`, `/specify`, `/design` (which already handle `REFRESH_BLOCKED`), plus `/create-ard` and `/release-notes`, which today have **no** handler for `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED` and gain one (§2 item 7).

---

## 6. Files changed

**Canonical — `/workspace/ihudak-claude-plugins`, 22 files.** Under `plugins/dev-workflows/`: `references/read-only-repos.md` (new), `references/docs-grounding.md`, `references/escalation-rules.md`, `references/handoff/code-scanner.md`, `references/handoff/diff-summarizer.md`, `agents/docs-grounder.md`, `agents/code-scanner.md`, `agents/diff-summarizer.md`, `commands/{idea,create-vi,update-vi,create-ard,specify,epics,release-notes,implement,document,design}.md`, `CHANGELOG.md`, `.claude-plugin/plugin.json`. At the repo root: `CLAUDE.md` (a Source-truth bullet for the new reference) and `.claude-plugin/marketplace.json`.

**mgd — `/workspace/mgd-claude-plugins`.** Copy canonical's 18 changed content files verbatim; hand-edit the four identity files that need it: `plugins/dev-workflows/CHANGELOG.md`, `plugins/dev-workflows/.claude-plugin/plugin.json`, root `CLAUDE.md`, root `.claude-plugin/marketplace.json`. **Never `cp` the repo-root `CLAUDE.md`** — it carries edition-specific paths. Post-port assertion: `diff -rq` reports exactly the six identity files (`plugins/dev-workflows/.claude-plugin/plugin.json`, `LICENSE`, `README.md`, `references/dependencies.md`, plus root `CLAUDE.md` and `.claude-plugin/marketplace.json`) and nothing else.

**copilot — `/workspace/ihudak-copilot-plugins`.** Adapted, not copied: `dev-workflows/skills/_shared/read-only-repos.md` (new) and the `_shared` counterparts of the changed references, `dev-workflows/agents/{docs-grounder,code-scanner,diff-summarizer}.md`, the `skills/<command>/SKILL.md` files matching the ten commands above, the `_shared` reference bullet in `dev-workflows/README.md`, `.github/copilot-instructions.md` if it describes any changed behavior, `dev-workflows/.plugin/plugin.json`, `CHANGELOG.md`, and `.github/plugin/marketplace.json`. References are addressed as `~/.copilot/installed-plugins/ihudak-copilot-plugins/dev-workflows/skills/_shared/<file>.md`; agent dispatch is `task(agent_type: …)`; no `${CLAUDE_PLUGIN_ROOT}` or `subagent_type` may leak in.

**Derive the copilot inventory, do not type it.** Its handoff-reference location must be confirmed during planning, and all three marketplace catalogs must be enumerated with `find . -name 'marketplace.json'` across the three repos — copilot's lives at `.github/plugin/marketplace.json`, and a hand-written file table has missed it three times.

## 7. Risks

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| R1 | The build prompt nags on every grounded run until an index exists | LOW | It disappears permanently once built; "Turn docs grounding off for this run" and `--no-docs` are both offered |
| R2 | A repo with thousands of changed files breaches the 60s update cap on **every** run — paying 60s forever and never completing | LOW | The cap breach prompts (§4.2) with "Finish the refresh now — uncapped"; stateless, and never silently repeats |
| R3 | `vectors > 0` does not prove the embedding model is cached — an index copied from another machine would trigger a download | LOW | The 30s retrieval cap kills it and drops a rung |
| R4 | `git grep <tree-ish>` unavailable or behaving differently across git versions | LOW | Falls back to `git show`-per-file over an `ls-tree` shortlist, then `REFRESH_BLOCKED` |
| R5 | Read-only detection false negative — `test -w` succeeds but writes fail | LOW | Secondary trigger on the `Read-only file system` error string retries in read-only mode |
| R6 | Read-only detection false positive on a writable mount | NEGLIGIBLE | Benign: reading at `origin/<default>` is what the caller requested anyway |
| R7 | The new escalation becomes noise | LOW | Fires only on read-only mounts (2 of 12 here), and only when stale or **ahead** — behind-only and at-ref are silent |
| R8 | **The `scanned_ref` fields and caller contract ship with no consumer** — the recurring dead-gate defect | MEDIUM | Wired into both handoff contracts, the escalation entry the commands already consume, and all seven dispatching commands; V7 verifies each citation exists |
| R9 | `/create-ard` and `/release-notes` need a *new* handling block, not an extension | LOW | Sized as its own task; §2 item 7 records why |

R8 is the one to watch. Three of the last four sub-projects produced a defect of exactly this shape, and this design adds four output fields and a caller contract whose only defence against being dead is explicit verification.

## 8. Verification

No test framework — the "code" is instruction markdown an LLM executes. Verification is grep, diff, and reading. All counts whitespace-normalised (`tr '\n' ' '`) because several files hard-wrap.

| # | Check |
|---|---|
| V1 | The seven index-mutating invocations (`qmd collection add`, `collection remove`, `collection rename`, `qmd embed`, `qmd update`, `qmd init`, `qmd cleanup`) appear **zero** times as instructions in `agents/docs-grounder.md`, all three editions |
| V2 | `qmd query` appears zero times as an invocation in `agents/docs-grounder.md`, all three editions |
| V3 | The three `retrieval:` values (`qmd-vector`, `qmd-lexical`, `fallback`) appear in both the agent's output contract and `docs-grounding.md` |
| V4 | `resolve-docs-grounding` contains step 3.5 with all three branches, both `choices:` arrays, and the 60s cap |
| V5 | The plan-approval line format in `docs-grounding.md` is string-identical to the quotation in every consumer command, `/epics` included |
| V6 | `references/read-only-repos.md` exists and is cited by all three git-touching agents |
| V7 | **Each of the seven dispatching commands cites the new reference or the new escalation entry** — the R8 dead-gate check |
| V8 | `escalation-rules.md` contains the new entry, four options, last entry `"Other… (describe)"`, reason-annotated `(Recommended — …)` |
| V9 | Both handoff references define all four `prep` fields |
| V10 | `git switch` and `git pull --ff-only` are still present in `code-scanner`'s writable path — no regression for writable mounts |
| V11 | `docs-grounding.md` §3's validity gate is byte-unchanged (`git diff` shows no hunk in that range) |
| V12 | Path B's three bounds are present: 3–8 keywords, the 200-file keyword drop, the 40-file shortlist cap |
| V13 | Shadow detection and docs-checkout staleness both appear in `docs-grounding.md` |
| V14 | mgd parity: `diff -rq` reports exactly the six identity files, covering `plugins/dev-workflows` **and** the repo root |
| V15 | All three marketplace catalogs bumped, enumerated by `find . -name 'marketplace.json'` across the three repos, `dev-workflows` entry only |
| V16 | Copilot dialect clean: no `${CLAUDE_PLUGIN_ROOT}`, no `subagent_type`, no `Agent (subagent_type:` in changed copilot files |
| V17 | Source-truth bullet for the new reference added to canonical + mgd root `CLAUDE.md`, and to copilot's `dev-workflows/README.md` `_shared` list |
| V18 | Version consistent per repo across `plugin.json`, the catalog, and `CHANGELOG.md` |

Expected values are re-derived from the tree at verification time, never restated from this document — a check that reads its expectation from the artifact under test passes by confirming its own error.

## 9. Decision log

| Decision | Chosen | Why |
|---|---|---|
| Read-only fix scope | All three git-touching agents | `diff-summarizer` fails harder than `code-scanner` (default-ON fetch); `docs-grounder`'s backstop needs only a cross-reference |
| Path B | Bound it **and** add the `qmd search` rung | Otherwise the qmd fix relocates the stampede into an unbounded fallback |
| Index build | No new flag or command; consent-gated in `resolve-docs-grounding` | An agent cannot ask; the orchestrator can. Keeps indexes built and current without new surface |
| Read-only visibility | `scanned_ref` + wired consumers, not agent-side only | A deviation nobody reads is not a guard; `refresh_note` has zero command consumers today |
| `qmd init` | Banned for the plugin; `.qmd/` added to the user's global gitignore for manual use | Project-local indexes resolve by cwd and would shadow the user-scope index; the docs mount is read-only anyway |
| `qmd query` | Never invoked | The only entry point needing three models, with no probe that can prove they are cached |
| Staleness threshold | 14 days, shared by the ref check and the docs-checkout check | The one tunable number; stated once so both uses move together |
