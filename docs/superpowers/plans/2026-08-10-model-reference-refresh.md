# Model-Reference Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `claude-opus-5` (and its pricing) to the `dev-workflows` model-routing chain, and reconcile the copilot edition's three conflicting chain statements — including removing Haiku 4.5 from its strong-tier fallback list.

**Architecture:** Three repositories, each a prompt-markdown plugin: instruction text an LLM executes at run time. There is no build and no test framework. Every change is a text edit; every verification is a `grep` with an expected count, a `diff`, or a read. Canonical (`ihudak-claude-plugins`) is authored first; `mgd-claude-plugins` receives a content-verbatim port of its shared files; `ihudak-copilot-plugins` receives an adapted port in its own dialect.

**Tech Stack:** Markdown, YAML, JSON. `git`, `grep`, `diff`, `python3` (stdlib only, for JSON edits if preferred).

**Spec:** `docs/superpowers/specs/2026-08-10-model-reference-refresh-design.md`

## Global Constraints

- **`classification.md` §2 and `cost-prices.yaml` MUST change in the same task (Task 1).** The price engine exact-matches a model id, then falls back to the longest table key that is a **prefix** of the id. No existing key is a prefix of `claude-opus-5`. Shipping the chain change without the price entry silently records every SIGNIFICANT/HIGH-RISK run as `cost_usd: null`.
- **Opus 5 pricing, exact:** `input: 5.0`, `output: 25.0`, `cache_read: 0.5`, `cache_write_5m: 6.25`, `cache_write_1h: 10.0`. Identical to the existing Opus 4.6/4.7/4.8 entries.
- **Sonnet 5 pricing is NOT changed.** It stays `input: 3.0` / `output: 15.0`. Its $2/$10 is introductory through 2026-08-31; the file's existing comment explaining this is correct and stays.
- **Never edit any `CHANGELOG.md` historical entry.** Changelogs record what shipped; rewriting a past entry's model name falsifies it. Changelogs receive a **new** entry only.
- **The copilot strong tier is a PEER SET, not a ladder.** It has its own selection rule ("prefer the model the orchestrator is already running under if it is in the peer set") and its own semantics (choosing a peer is never announced as a downgrade, unlike the further-fallbacks list). Preserve that structure. Do not flatten it.
- **The copilot edition keeps dotted model ids** (`claude-opus-4.8`), canonical keeps hyphenated (`claude-opus-4-8`). This is a deliberate dialect difference. Do not normalise either way. **`claude-opus-5` and `claude-sonnet-5` have no dot-vs-hyphen variant** — they are spelled identically in both editions.
- **Canonical `agents/*.md` are NOT touched.** Nine agents pin `model: opus` — an alias, not a version — which resolves to the current Opus with no edit.
- **Excluded from every stale-string sweep:** all three `CHANGELOG.md` files, and `ihudak-copilot-plugins/docs/superpowers/{specs,plans}/2026-07-13-claude-to-copilot-port*` (historical design documents).
- **Versions:** canonical `2.44.0 → 2.44.1`; mgd `2.44.0 → 2.44.1`; copilot `2.14.0 → 2.14.1`.
- **Commit trailer for every commit in this plan:** `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`
- **Branch:** all three repos work on `iv-gu/model-reference-refresh`, created off `main`.

## File Structure

**Canonical — `/workspace/ihudak-claude-plugins`** (11 content files + 3 release files)

| File | Responsibility | Task |
|---|---|---|
| `plugins/dev-workflows/references/model-routing/classification.md` | routing authority: the §2 chain and every `model_routing` example | 1 |
| `plugins/dev-workflows/references/cost-prices.yaml` | price table keyed by model id | 1 |
| `plugins/dev-workflows/references/cost-emission.md` | worked-example cost entry | 1 |
| `plugins/dev-workflows/commands/{create-vi,create-ard,update-vi,design,specify}.md` | handoff commit trailers (1 each) | 2 |
| `plugins/dev-workflows/commands/docs-profile.md` | `§2 powerful chain` examples (2) | 2 |
| `plugins/dev-workflows/commands/document.md` | `§2 powerful chain` example (1) | 2 |
| `CLAUDE.md` | repo-root chain description | 2 |
| `plugins/dev-workflows/.claude-plugin/plugin.json` | plugin version | 3 |
| `.claude-plugin/marketplace.json` | catalog version | 3 |
| `plugins/dev-workflows/CHANGELOG.md` | new 2.44.1 entry | 3 |

**Copilot — `/workspace/ihudak-copilot-plugins`** (13 content files + 3 release files)

| File | Responsibility | Task |
|---|---|---|
| `dev-workflows/skills/_shared/model-routing.md` | routing authority: peer set, further fallbacks, mid-tier, examples | 4 |
| `dev-workflows/agents/{code-review,risk-planner,doc-reviewer,epic-reviewer,vi-reviewer,ard-reviewer,spec-reviewer,design-reviewer,readiness-reviewer}.md` | peer label — 2 sites each (frontmatter `description:` + body) | 5 |
| `dev-workflows/hooks/preload-context.sh` | peer label (1 site) | 5 |
| `.github/copilot-instructions.md` | chain summary + peer label | 5 |
| `dev-workflows/README.md` | routing table + chain prose (**Haiku 4.5 removal**) | 5 |
| `README.md` (repo root) | peer label in the plugin blurb | 5 |
| `dev-workflows/.plugin/plugin.json` | version + peer label in `description` | 6 |
| `.github/plugin/marketplace.json` | version + peer label in `description` | 6 |
| `dev-workflows/CHANGELOG.md` | new 2.14.1 entry | 6 |

**mgd — `/workspace/mgd-claude-plugins`** (Task 7)

Ten canonical files are **shared** and copied byte-for-byte. Five are mgd-**identity** files that must be hand-edited, never copied: `plugins/dev-workflows/{.claude-plugin/plugin.json, CHANGELOG.md, LICENSE, README.md, references/dependencies.md}`. Two more repo-root files also differ from canonical and must be hand-edited: `CLAUDE.md` and `.claude-plugin/marketplace.json`.

---

## Task 1: Canonical routing authority + pricing

**Files:**
- Modify: `plugins/dev-workflows/references/model-routing/classification.md` (§2 chain at `:79-86`; examples at `:167-169`, `:178`, `:218`)
- Modify: `plugins/dev-workflows/references/cost-prices.yaml`
- Modify: `plugins/dev-workflows/references/cost-emission.md:225`

**Interfaces:**
- Produces: the canonical chain text and the `claude-opus-5` price key that Task 7 copies verbatim to mgd, and that Task 4 mirrors (in copilot dialect and structure).

- [ ] **Step 1: Create the branch**

```bash
cd /workspace/ihudak-claude-plugins
git checkout main && git pull --ff-only
git checkout -b iv-gu/model-reference-refresh
```

- [ ] **Step 2: Record the "before" counts**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
grep -c "claude-opus-4-8" references/model-routing/classification.md   # expect 5
grep -n "claude-opus-5" references/cost-prices.yaml                    # expect no output
```

If a count differs, the file has moved on since the plan was written — **stop and report the mismatch** rather than adjusting the edit to fit. (Every implementer who flagged such a mismatch on this repo has been right.)

- [ ] **Step 3: Replace the §2 chain in `classification.md`**

Find this block (currently at `:79-86`):

```markdown
1. `claude-opus-4-8`
2. `claude-opus-4-7`
3. `claude-opus-4-6`
4. `claude-sonnet-5` (fallback only — note in the report that no Opus was available)
5. `claude-sonnet-4-6` (further fallback)
6. `claude-sonnet-4-5` (further fallback — note "no Opus or Sonnet 5/4.6 available")
```

Replace with:

```markdown
1. `claude-opus-5`
2. `claude-opus-4-8`
3. `claude-opus-4-7`
4. `claude-opus-4-6`
5. `claude-sonnet-5` (fallback only — note in the report that no Opus was available)
6. `claude-sonnet-4-6` (further fallback)
7. `claude-sonnet-4-5` (further fallback — note "no Opus or Sonnet 5/4.6 available")
```

Leave the two paragraphs that follow ("Sonnet 4.5 is the floor…" and "The list of available models…") **exactly as they are**. Leave §2.1 (the mid-tier chain) **entirely unchanged** — it already reads `claude-sonnet-5` → `claude-sonnet-4-6` → `claude-sonnet-4-5`.

- [ ] **Step 4: Update the `model_routing` examples in `classification.md`**

At `:167-169`, change three lines:

```yaml
  current_model: <e.g. claude-opus-5>        # the model the orchestrator is running
  planning_model: <e.g. claude-opus-5>       # only set for SIGNIFICANT/HIGH-RISK
  review_model:   <e.g. claude-opus-5>       # only set for SIGNIFICANT/HIGH-RISK
```

At `:178`, change the degradation-note example:

```yaml
  notes: <optional — e.g. "Opus 5 unavailable, fell back to 4.8">
```

At `:218`, inside the `task(...)` block:

```
  model:      "claude-opus-5",   # or the highest available per §2
```

Do **not** touch `implementation_model` or `detection_model` — they name Sonnet 4.6 as an example, and the mid-tier chain is unchanged.

- [ ] **Step 5: Add the Opus 5 price entry**

In `references/cost-prices.yaml`, the block comment currently reads:

```yaml
  # Opus chain (§2). Opus 4.5-4.8 all bill at $5 / $25.
```

Change it to, and insert the new entry immediately below it, **above** `claude-opus-4-8`:

```yaml
  # Opus chain (§2). Opus 5 and Opus 4.5-4.8 all bill at $5 / $25.
  claude-opus-5:
    input: 5.0
    output: 25.0
    cache_read: 0.5
    cache_write_5m: 6.25
    cache_write_1h: 10.0
```

In the file header comment, change the retrieval date:

```
# Rates sourced from https://platform.claude.com/docs/en/about-claude/pricing (standard
# first-party Claude API, retrieved 2026-08-10). Batch / fast-mode / data-residency
```

Change **nothing else** in this file. In particular the Sonnet 5 entry stays at `input: 3.0` / `output: 15.0`, and the paragraph explaining why (introductory pricing through 2026-08-31 is not used) stays verbatim.

- [ ] **Step 6: Update the worked example in `cost-emission.md`**

At `:225`, change the model id only:

```yaml
  - {model: claude-opus-5, cost_usd: 2.9114, input_tokens: 12043, output_tokens: 88210, cache_read_tokens: 2109887, cache_write_tokens: 145002}
```

**Do not recompute `cost_usd`.** Opus 5 bills identically to Opus 4.8, so 2.9114 remains correct for those token counts. Changing it would be wrong.

- [ ] **Step 7: Verify**

```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# V1 — opus-5 is chain position 1
grep -n "claude-opus-5" references/model-routing/classification.md          # expect 5 hits: chain #1, 3 examples, 1 task() pin
grep -n "^1\. \`claude-opus-5\`" references/model-routing/classification.md # expect 1
# V2 — price entry present and exact
grep -A5 "^  claude-opus-5:" references/cost-prices.yaml
#   expect: input: 5.0 / output: 25.0 / cache_read: 0.5 / cache_write_5m: 6.25 / cache_write_1h: 10.0
# Sonnet 5 untouched
grep -A2 "^  claude-sonnet-5:" references/cost-prices.yaml                  # expect input: 3.0, output: 15.0
# no stale top-of-chain
grep -c "claude-opus-4-8" references/model-routing/classification.md        # expect 1 (chain position 2 only)
```

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/references/model-routing/classification.md \
        plugins/dev-workflows/references/cost-prices.yaml \
        plugins/dev-workflows/references/cost-emission.md
git commit -m "feat(dev-workflows): route to claude-opus-5 and price it

classification.md §2 tops the strong chain at claude-opus-5; the
cost-prices.yaml entry ships in the same commit because the price
engine's prefix fallback has no key matching claude-opus-5, so the
chain change alone would price every SIGNIFICANT run as null.

Opus 5 bills identically to Opus 4.5-4.8 (\$5/\$25), so the entry is a
copy of its neighbours and cost-emission.md's worked figure stays valid.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 2: Canonical commands + repo-root guidance

**Files:**
- Modify: `plugins/dev-workflows/commands/create-vi.md:192`
- Modify: `plugins/dev-workflows/commands/create-ard.md:131`
- Modify: `plugins/dev-workflows/commands/update-vi.md:92`
- Modify: `plugins/dev-workflows/commands/design.md:311`
- Modify: `plugins/dev-workflows/commands/specify.md:410`
- Modify: `plugins/dev-workflows/commands/docs-profile.md:61,102`
- Modify: `plugins/dev-workflows/commands/document.md:234`
- Modify: `CLAUDE.md:94`

**Interfaces:**
- Consumes: the chain established in Task 1 — every example here must name `claude-opus-5` consistently with it.
- Produces: the eight edited files; the seven under `plugins/` are copied verbatim to mgd in Task 7, while root `CLAUDE.md` is mgd-specific and is hand-edited there.

- [ ] **Step 1: Replace the five handoff commit trailers**

Each of `create-vi.md:192`, `create-ard.md:131`, `update-vi.md:92`, `design.md:311`, `specify.md:410` contains this exact string:

```
Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
```

Replace every occurrence with:

```
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

The `(1M context)` qualifier is dropped: the 1M window is standard on Claude 4.6 and later, so it no longer distinguishes anything.

- [ ] **Step 2: Update the chain examples in `docs-profile.md`**

At `:61`:

```
  planning_model: <§2 powerful chain: claude-opus-5 … fallback Sonnet 5/4.6/4.5>
```

At `:102`:

```
→ Agent (subagent_type: "general-purpose", model: `<planning_model — §2 chain: claude-opus-5, fallback per §2>`):
```

- [ ] **Step 3: Update the chain example in `document.md`**

At `:234`:

```
  planning_model:  <§2 powerful chain: claude-opus-5 … fallback Sonnet per §2>   # doc-planner (5.7)
```

- [ ] **Step 4: Update the repo-root chain description**

`CLAUDE.md:94` currently reads:

```markdown
- The model fallback chain (Opus 4.8 → 4.7 → 4.6 → Sonnet 4.6 → Sonnet 4.5)
```

Replace with — note this also adds the **Sonnet 5** that `classification.md` has carried all along and this line omitted:

```markdown
- The model fallback chain (Opus 5 → 4.8 → 4.7 → 4.6 → Sonnet 5 → Sonnet 4.6 → Sonnet 4.5)
```

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-claude-plugins
# no stale trailer anywhere
grep -rn "Opus 4.8 (1M context)" plugins/ CLAUDE.md          # expect no output
# new trailer at exactly 5 files
grep -rl "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" plugins/dev-workflows/commands/ | wc -l   # expect 5
# chain examples refreshed
grep -rn "claude-opus-4-8" plugins/dev-workflows/commands/    # expect no output
# root guidance
grep -n "model fallback chain" CLAUDE.md                      # expect the Opus 5 … Sonnet 5 form
```

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/commands/create-vi.md plugins/dev-workflows/commands/create-ard.md \
        plugins/dev-workflows/commands/update-vi.md plugins/dev-workflows/commands/design.md \
        plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/docs-profile.md \
        plugins/dev-workflows/commands/document.md CLAUDE.md
git commit -m "docs(dev-workflows): refresh command-level model references to Opus 5

Five handoff commit trailers named Opus 4.8 (1M context); the qualifier
is dropped since the 1M window is standard on 4.6 and later. Chain
examples in docs-profile and document follow classification.md §2.

CLAUDE.md's chain description also gains the Sonnet 5 entry it had been
missing — classification.md has carried it for some time.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 3: Canonical release — 2.44.1

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json:3`
- Modify: `.claude-plugin/marketplace.json:12`
- Modify: `plugins/dev-workflows/CHANGELOG.md`

**Interfaces:**
- Consumes: the content changes from Tasks 1–2, which the changelog entry describes.
- Produces: the canonical `2.44.1` release; Task 7 mirrors the version numbers into mgd's own manifests.

- [ ] **Step 1: Bump the plugin version**

`plugins/dev-workflows/.claude-plugin/plugin.json:3` — `"version": "2.44.0"` becomes `"version": "2.44.1"`.

- [ ] **Step 2: Bump the catalog version**

`.claude-plugin/marketplace.json:12` — the `dev-workflows` entry's `"version": "2.44.0"` becomes `"version": "2.44.1"`. **Only line 12.** The three other version fields in this file (`0.2.4`, `0.4.0`, `0.1.1`) belong to other plugins and must not change.

- [ ] **Step 3: Add the changelog entry**

Insert immediately below the header block (above `## [2.44.0] — 2026-08-10`) in `plugins/dev-workflows/CHANGELOG.md`. Match the existing Keep-a-Changelog shape — `## [x.y.z] — YYYY-MM-DD`, an em-dash separator, then `### Fixed` / `### Added` sections with bolded lead sentences:

```markdown
## [2.44.1] — 2026-08-10

### Fixed

- **The model-routing references had gone stale.** `references/model-routing/classification.md` §2 topped the strong chain at `claude-opus-4-8`; it now tops at `claude-opus-5`, with 4.8/4.7/4.6 shifted down one and the Sonnet 5/4.6/4.5 tail and Sonnet 4.5 floor unchanged. The mid-tier chain (§2.1) already read Sonnet 5 → 4.6 → 4.5 and is untouched. Five commands (`create-vi`, `create-ard`, `update-vi`, `design`, `specify`) hardcoded `Co-Authored-By: Claude Opus 4.8 (1M context)` in their handoff commit trailers — now `Claude Opus 5`, with the `(1M context)` qualifier dropped because the 1M window is standard on 4.6 and later. Chain examples in `docs-profile.md`, `document.md`, and `classification.md`'s own `model_routing` block follow.
- **`CLAUDE.md`'s chain description disagreed with the reference it summarises.** It listed Opus 4.8 → 4.7 → 4.6 → Sonnet 4.6 → Sonnet 4.5, omitting `claude-sonnet-5` which `classification.md` has carried at position 4. Both now read Opus 5 → 4.8 → 4.7 → 4.6 → Sonnet 5 → 4.6 → 4.5.

### Added

- **`claude-opus-5` in `references/cost-prices.yaml`.** Not cosmetic: the price engine exact-matches a model id and then falls back to the longest table key that is a *prefix* of it, and no existing key is a prefix of `claude-opus-5`. Routing to Opus 5 without this entry would have priced every SIGNIFICANT and HIGH-RISK run as `unpriced-model` with `cost_usd: null`. Opus 5 bills identically to the whole Opus 4.5–4.8 block ($5 / $25; cache read $0.50, 5m write $6.25, 1h write $10), verified 2026-08-10 against the pricing source the file already cites, so the entry is a copy of its neighbours. Sonnet 5 deliberately stays at its standard $3 / $15 — its $2 / $10 runs through 2026-08-31 only, and the file's rule against promotional rates (they make identical work look cheaper now and dearer later, distorting cross-VI comparison) is unchanged.
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-claude-plugins
grep -n '"version"' plugins/dev-workflows/.claude-plugin/plugin.json    # expect 2.44.1
sed -n '10,14p' .claude-plugin/marketplace.json                          # expect dev-workflows at 2.44.1
grep -n "^## \[" plugins/dev-workflows/CHANGELOG.md | head -4            # expect 2.44.1 above 2.44.0
```

Changelog ordering must be monotonically descending — this repo has shipped an out-of-order changelog twice.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json \
        plugins/dev-workflows/CHANGELOG.md
git commit -m "chore(dev-workflows): release 2.44.1 — model-reference refresh

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 4: Copilot routing authority

**Files:**
- Modify: `dev-workflows/skills/_shared/model-routing.md` — six regions, all located by the verbatim text below rather than by line number: the §2 peer-set bullet list, the "These four are first-class peers" paragraph, the selection-rule parenthetical, the further-fallbacks numbered list, the §2.1 mid-tier list, and the `model_routing` / `task(...)` examples near `:195-200` and `:248`

**Interfaces:**
- Consumes: the chain semantics from Task 1, adapted — copilot uses dotted ids and has GPT/Gemini entries canonical does not.
- Produces: the authoritative copilot chain that Tasks 5 and 6 restate as flat summaries. Those restatements must flatten to exactly: Opus 5 → GPT-5.6 → Opus 4.8 → 4.7 → 4.6 → GPT-5.5 → Opus 4.5 → Sonnet 5 → Sonnet 4.6 → Sonnet 4.5 → GPT-5.4 → Gemini 3.1 Pro Preview.

- [ ] **Step 1: Create the branch**

```bash
cd /workspace/ihudak-copilot-plugins
git checkout main && git pull --ff-only
git checkout -b iv-gu/model-reference-refresh
```

- [ ] **Step 2: Grow the peer set from four to six**

In `dev-workflows/skills/_shared/model-routing.md`, this bulleted list:

```markdown
- `claude-opus-4.8`
- `claude-opus-4.7`
- `claude-opus-4.6`
- `gpt-5.5`
```

becomes:

```markdown
- `claude-opus-5`
- `gpt-5.6`
- `claude-opus-4.8`
- `claude-opus-4.7`
- `claude-opus-4.6`
- `gpt-5.5`
```

Then the paragraph immediately below it, currently:

```markdown
These four are **first-class peers**. GPT-5.5 is a strong reasoning model in its
own right — it is **not** a degraded fallback, and choosing it is never announced
as a downgrade. (GPT models were unavailable in Claude Code, so the original
policy was Opus-only; on Copilot CLI, GPT-5.5 is a co-equal strong option.)
```

becomes:

```markdown
These six are **first-class peers**. GPT-5.6 and GPT-5.5 are strong reasoning
models in their own right — they are **not** degraded fallbacks, and choosing one
is never announced as a downgrade. (GPT models were unavailable in Claude Code, so
the original policy was Opus-only; on Copilot CLI, GPT-5.6 and GPT-5.5 are co-equal
strong options.)
```

**Do not convert the peer set into a numbered ladder.** Its "prefer the session model if it is a peer" rule and its never-a-downgrade semantics are the reason it is a set rather than a list.

- [ ] **Step 3: Refresh the selection-rule example**

The selection rule's parenthetical currently reads:

```markdown
   strong-tier peer set (e.g. an Opus 4.8 session pins gates to Opus 4.8; a
   GPT-5.5 session pins gates to GPT-5.5).
```

becomes:

```markdown
   strong-tier peer set (e.g. an Opus 5 session pins gates to Opus 5; a
   GPT-5.6 session pins gates to GPT-5.6).
```

- [ ] **Step 4: Renumber the further-fallbacks list and add Sonnet 5**

The list currently starts at 5 (the four peers implicitly occupied 1–4). With six peers it starts at 7. `claude-sonnet-5` goes directly above `claude-sonnet-4.6`, preserving the relative order of every existing entry:

```markdown
7.  `claude-opus-4.5`
8.  `claude-sonnet-5`
9.  `claude-sonnet-4.6`
10. `claude-sonnet-4.5`
11. `gpt-5.4`
12. `gemini-3.1-pro-preview`
```

The sentence that follows — `gemini-3.1-pro-preview` is the floor, abort rather than silently downgrade — is unchanged.

- [ ] **Step 5: Add Sonnet 5 to the mid-tier chain**

The §2.1 detection chain currently reads:

```markdown
1. `claude-sonnet-4.6`
2. `claude-sonnet-4.5`
3. `gpt-5.4` (further fallback — note the degradation in the report)
```

becomes — note the `gpt-5.4` tail is **retained**:

```markdown
1. `claude-sonnet-5`
2. `claude-sonnet-4.6`
3. `claude-sonnet-4.5`
4. `gpt-5.4` (further fallback — note the degradation in the report)
```

- [ ] **Step 6: Update the `model_routing` examples**

At `:195-200`:

```yaml
  current_model: <e.g. claude-opus-5 or gpt-5.6>   # the model the orchestrator is running
  planning_model: <e.g. claude-opus-5>       # strong tier; only set for SIGNIFICANT/HIGH-RISK
  review_model:   <e.g. claude-opus-5>       # strong tier; only set for SIGNIFICANT/HIGH-RISK
  implementation_model: <e.g. claude-sonnet-5 or current_model>
  detection_model: <e.g. claude-sonnet-5>    # mid-tier steps (§2.1); never the session model
  fixes_model:    <same as implementation_model>
  opus_available: true | false             # true if any §2 peer (Opus 5/4.8/4.7/4.6 or GPT-5.6/5.5) is available
```

At `:248`, inside the `task(...)` block:

```
  model:      "claude-opus-5",   # or the highest available strong-tier peer per §2
```

- [ ] **Step 7: Verify**

```bash
cd /workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared
grep -n "claude-opus-5\|gpt-5.6\|claude-sonnet-5" model-routing.md
#   expect: peer set entries 1-2, mid-tier #1, fallback #8, and the examples
grep -n "These six are" model-routing.md            # expect 1 hit
grep -n "Haiku" model-routing.md                    # expect no output
grep -n "gemini-3.1-pro-preview" model-routing.md   # expect the fallback list + the floor sentence
grep -n "^7\.\|^12\." model-routing.md              # expect the renumbered fallback bounds
```

- [ ] **Step 8: Commit**

```bash
cd /workspace/ihudak-copilot-plugins
git add dev-workflows/skills/_shared/model-routing.md
git commit -m "feat(dev-workflows): copilot strong-tier peer set grows to six

claude-opus-5 first, gpt-5.6 second, the four existing peers in their
current relative order. The peer set stays a set — its \"prefer the
session model if it is a peer\" rule and its never-a-downgrade semantics
are why it is not a ladder.

Further fallbacks renumber from 7 and gain claude-sonnet-5 above
claude-sonnet-4.6; the mid-tier chain gains it at the top. The copilot
edition had no claude-sonnet-5 anywhere — the B-series ports never
carried it across.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 5: Copilot peer-label sweep + the Haiku defect

**Files:**
- Modify: `dev-workflows/agents/code-review.md`, `risk-planner.md`, `doc-reviewer.md`, `epic-reviewer.md`, `vi-reviewer.md`, `ard-reviewer.md`, `spec-reviewer.md`, `design-reviewer.md`, `readiness-reviewer.md` — **2 sites each** (the `description:` frontmatter line and one body line): 18 sites
- Modify: `dev-workflows/hooks/preload-context.sh:58`
- Modify: `.github/copilot-instructions.md:110,174`
- Modify: `dev-workflows/README.md:250,252-253`
- Modify: `README.md:9`

**Interfaces:**
- Consumes: the peer set and flattened order from Task 4. Every restatement here must flatten to that same 12-model sequence.

- [ ] **Step 1: Sweep the peer label**

**Twenty** occurrences of this exact substring:

```
Opus 4.8/4.7/4.6 or GPT-5.5
```

become:

```
Opus 5/4.8/4.7/4.6 or GPT-5.6/5.5
```

Sites, totalling 20: the nine agent files listed above at **two each** = 18 (verify with `grep -c "Opus 4\.8/4\.7/4\.6" dev-workflows/agents/*.md`, which must report `2` for each of those nine and `0` for the other twenty-three agents), plus `dev-workflows/hooks/preload-context.sh:58` and `.github/copilot-instructions.md:174`.

Two more sites carry the same label in **different wording** and are handled separately — `dev-workflows/README.md:250,252` in Step 3 and `README.md:9` in Step 4. `copilot-instructions.md:110` restates the whole chain and is handled in Step 2. The two manifest `description` fields are Task 6's.

- [ ] **Step 2: Update the chain summary in `copilot-instructions.md`**

`:110` currently reads:

```markdown
- Model fallback chain (Opus 4.8 → 4.7 → 4.6 → GPT-5.5 → Opus 4.5 → Sonnet 4.6 → Sonnet 4.5 → GPT-5.4 → Gemini 3.1 Pro); Opus 4.8/4.7/4.6 + GPT-5.5 are co-equal strong-tier peers, the rest are further fallbacks
```

becomes:

```markdown
- Model fallback chain (Opus 5 → GPT-5.6 → Opus 4.8 → 4.7 → 4.6 → GPT-5.5 → Opus 4.5 → Sonnet 5 → Sonnet 4.6 → Sonnet 4.5 → GPT-5.4 → Gemini 3.1 Pro Preview); Opus 5/4.8/4.7/4.6 + GPT-5.6/5.5 are co-equal strong-tier peers, the rest are further fallbacks
```

- [ ] **Step 3: Fix the routing table and the Haiku defect in `dev-workflows/README.md`**

`:250` currently reads:

```markdown
| SIGNIFICANT / HIGH-RISK | Strong tier — `claude-opus-4.8` / `4.7` / `4.6` or `gpt-5.5`, pinned via `model:` override |
```

becomes:

```markdown
| SIGNIFICANT / HIGH-RISK | Strong tier — `claude-opus-5` / `4.8` / `4.7` / `4.6` or `gpt-5.6` / `gpt-5.5`, pinned via `model:` override |
```

`:252-253` currently reads — note `Haiku 4.5` sitting in the strong-tier fallback position, **above** GPT-5.5:

```markdown
The strong tier treats Opus 4.8/4.7/4.6 and GPT-5.5 as peers (fallback chain:
Opus 4.8 → 4.7 → 4.6 → Haiku 4.5 → GPT-5.5 → Sonnet 4.6 → Sonnet 4.5 → GPT-5.4 →
Gemini 3.1 Pro).
```

becomes — Haiku 4.5 **removed**, because a SIGNIFICANT or HIGH-RISK gate must never degrade to the cheapest model in the lineup ahead of GPT-5.5:

```markdown
The strong tier treats Opus 5/4.8/4.7/4.6 and GPT-5.6/5.5 as peers (fallback chain:
Opus 5 → GPT-5.6 → Opus 4.8 → 4.7 → 4.6 → GPT-5.5 → Opus 4.5 → Sonnet 5 → Sonnet 4.6
→ Sonnet 4.5 → GPT-5.4 → Gemini 3.1 Pro Preview).
```

- [ ] **Step 4: Update the repo-root README blurb**

`README.md:9` contains, inside the `dev-workflows` table row:

```
with strong-tier (Opus 4.8/4.7/4.6 or GPT-5.5) planning, code review, and doc / Epic / design review gates.
```

becomes:

```
with strong-tier (Opus 5/4.8/4.7/4.6 or GPT-5.6/5.5) planning, code review, and doc / Epic / design review gates.
```

- [ ] **Step 5: Verify**

```bash
cd /workspace/ihudak-copilot-plugins
# old label fully gone from live content (changelog + historical port docs excluded)
grep -rn "Opus 4.8/4.7/4.6 or GPT-5.5" dev-workflows/agents dev-workflows/hooks \
     dev-workflows/README.md README.md .github/copilot-instructions.md   # expect no output
# new label present at 2 sites in each of exactly 9 agent files
grep -rc "Opus 5/4.8/4.7/4.6 or GPT-5.6/5.5" dev-workflows/agents/*.md | grep -v ":0"  # expect 9 lines, each ending :2
# Haiku gone from every strong-tier statement
grep -rn "Haiku 4.5" dev-workflows/README.md .github/copilot-instructions.md \
     dev-workflows/skills/_shared/model-routing.md                        # expect no output
# the three chain statements flatten to the same sequence — read and compare by eye
grep -n "fallback chain" .github/copilot-instructions.md dev-workflows/README.md
```

The last check is a **read**, not a count: `model-routing.md` is structured (peer set + fallbacks) while the other two are flat summaries, so they are legitimately different text. What must match is the order they imply.

- [ ] **Step 6: Commit**

```bash
git add dev-workflows/agents dev-workflows/hooks/preload-context.sh \
        dev-workflows/README.md README.md .github/copilot-instructions.md
git commit -m "fix(dev-workflows): drop Haiku 4.5 from the copilot strong tier

dev-workflows/README.md listed Haiku 4.5 as a strong-tier fallback ahead
of GPT-5.5, so a SIGNIFICANT or HIGH-RISK gate would degrade to the
cheapest model in the lineup before trying a strong peer. Removed.

All three of the edition's chain statements — model-routing.md,
copilot-instructions.md, and the README — now flatten to the same
sequence; they had drifted in three different directions, which is how
the Haiku entry survived.

Peer label refreshed to Opus 5/4.8/4.7/4.6 or GPT-5.6/5.5 across nine
agents (frontmatter + body), the preload hook, and both READMEs.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 6: Copilot release — 2.14.1

**Files:**
- Modify: `dev-workflows/.plugin/plugin.json:4` (version) and its `description` field
- Modify: `.github/plugin/marketplace.json:17` (version) and its `description` field
- Modify: `dev-workflows/CHANGELOG.md`

**Interfaces:**
- Consumes: Tasks 4–5. Both manifest `description` fields carry the peer label swept in Task 5 and must end up consistent with it.

- [ ] **Step 1: Bump both versions**

`dev-workflows/.plugin/plugin.json:4` — `"version": "2.14.0"` becomes `"version": "2.14.1"`.

`.github/plugin/marketplace.json:17` — the `dev-workflows` entry's `"version": "2.14.0"` becomes `"version": "2.14.1"`. **Only line 17.** The file's other version fields (`1.0.0` at line 5, then `0.3.3`, `0.3.4`, `0.1.0`) belong to the catalog itself and to other plugins.

- [ ] **Step 2: Update the peer label in both `description` fields**

Both files' `dev-workflows` `description` strings contain:

```
Strong-tier model routing (Opus 4.8/4.7/4.6 or GPT-5.5)
```

Replace in both with:

```
Strong-tier model routing (Opus 5/4.8/4.7/4.6 or GPT-5.6/5.5)
```

These two catalogs were each missed in the 2.42.0 release. They are listed explicitly here for that reason.

- [ ] **Step 3: Add the changelog entry**

Insert above `## [2.14.0] — 2026-08-10` in `dev-workflows/CHANGELOG.md`:

```markdown
## [2.14.1] — 2026-08-10

### Fixed

- **Haiku 4.5 was listed as a strong-tier fallback.** `README.md`'s chain read `Opus 4.8 → 4.7 → 4.6 → Haiku 4.5 → GPT-5.5 → …`, so a SIGNIFICANT or HIGH-RISK gate would degrade to the cheapest model in the lineup before trying a strong peer. Removed. The root cause was drift: the edition documented its chain in three places — `skills/_shared/model-routing.md`, `.github/copilot-instructions.md`, and `README.md` — and the three had diverged in three different directions. All three now flatten to one sequence, with `model-routing.md` as the authority.
- **The model references had gone stale.** The strong-tier peer set grows from four to six — `claude-opus-5` first, `gpt-5.6` second, the existing four in their prior relative order. It remains a *peer set*, not a ladder: the "prefer the model the orchestrator is already running under" rule and the never-announced-as-a-downgrade semantics are unchanged. Further fallbacks renumber from 7. The peer label `Opus 4.8/4.7/4.6 or GPT-5.5` becomes `Opus 5/4.8/4.7/4.6 or GPT-5.6/5.5` across nine reviewer agents (frontmatter and body), the preload hook, both READMEs, `copilot-instructions.md`, and both catalogs.

### Added

- **`claude-sonnet-5`, which this edition was missing entirely.** It appeared in neither the strong-tier further-fallbacks list nor the mid-tier detection chain — the canonical edition has carried it for some time and the B-series ports never brought it across, leaving the detection tier topped at Sonnet 4.6. It now sits above `claude-sonnet-4.6` in both.
```

- [ ] **Step 4: Verify**

```bash
cd /workspace/ihudak-copilot-plugins
grep -n '"version"' dev-workflows/.plugin/plugin.json          # expect 2.14.1
sed -n '15,19p' .github/plugin/marketplace.json                 # expect dev-workflows at 2.14.1
grep -c "Opus 4.8/4.7/4.6 or GPT-5.5" dev-workflows/.plugin/plugin.json .github/plugin/marketplace.json  # expect 0 0
grep -n "^## \[" dev-workflows/CHANGELOG.md | head -4           # expect 2.14.1 above 2.14.0
python3 -c "import json;[json.load(open(p)) for p in ['dev-workflows/.plugin/plugin.json','.github/plugin/marketplace.json']];print('JSON OK')"
```

- [ ] **Step 5: Commit**

```bash
git add dev-workflows/.plugin/plugin.json .github/plugin/marketplace.json dev-workflows/CHANGELOG.md
git commit -m "chore(dev-workflows): release 2.14.1 — model-reference refresh

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 7: mgd port — 2.44.1

**Files:**
- Copy verbatim from canonical (10 shared files): `plugins/dev-workflows/references/{model-routing/classification.md, cost-prices.yaml, cost-emission.md}`, `plugins/dev-workflows/commands/{create-vi,create-ard,update-vi,design,specify,docs-profile,document}.md`
- Hand-edit (mgd-specific, **never copy**): `CLAUDE.md:106`, `plugins/dev-workflows/.claude-plugin/plugin.json:3`, `.claude-plugin/marketplace.json:12`, `plugins/dev-workflows/CHANGELOG.md`

**Interfaces:**
- Consumes: the finished canonical files from Tasks 1–3.

- [ ] **Step 1: Create the branch**

```bash
cd /workspace/mgd-claude-plugins
git checkout main && git pull --ff-only
git checkout -b iv-gu/model-reference-refresh
```

- [ ] **Step 2: Copy the ten shared files**

```bash
CANON=/workspace/ihudak-claude-plugins/plugins/dev-workflows
MGD=/workspace/mgd-claude-plugins/plugins/dev-workflows
cp "$CANON/references/model-routing/classification.md" "$MGD/references/model-routing/classification.md"
cp "$CANON/references/cost-prices.yaml"                 "$MGD/references/cost-prices.yaml"
cp "$CANON/references/cost-emission.md"                 "$MGD/references/cost-emission.md"
for f in create-vi create-ard update-vi design specify docs-profile document; do
  cp "$CANON/commands/$f.md" "$MGD/commands/$f.md"
done
```

**Do not `cp` anything else.** mgd has five identity files under `plugins/dev-workflows/` — `.claude-plugin/plugin.json`, `CHANGELOG.md`, `LICENSE`, `README.md`, `references/dependencies.md` — plus two at the repo root (`CLAUDE.md`, `.claude-plugin/marketplace.json`). Copying any of them over would destroy mgd's identity. This has gone wrong before.

- [ ] **Step 3: Hand-edit mgd's own `CLAUDE.md`**

The chain line is at `:106` in mgd (not `:94` as in canonical — the files differ). It currently reads:

```markdown
- The model fallback chain (Opus 4.8 → 4.7 → 4.6 → Sonnet 4.6 → Sonnet 4.5)
```

Replace with:

```markdown
- The model fallback chain (Opus 5 → 4.8 → 4.7 → 4.6 → Sonnet 5 → Sonnet 4.6 → Sonnet 4.5)
```

- [ ] **Step 4: Bump mgd's versions and add its changelog entry**

`plugins/dev-workflows/.claude-plugin/plugin.json:3` → `"version": "2.44.1"`.
`.claude-plugin/marketplace.json:12` → the `dev-workflows` entry → `"version": "2.44.1"`. Only that line.

Add the **same `## [2.44.1]` entry body** used in Task 3 Step 3 to `plugins/dev-workflows/CHANGELOG.md`, inserted above `## [2.44.0]`. The entry text is identical; only the surrounding file is mgd's own.

- [ ] **Step 5: Verify parity**

```bash
diff -rq /workspace/mgd-claude-plugins/plugins/dev-workflows \
         /workspace/ihudak-claude-plugins/plugins/dev-workflows
```

Expected: **exactly five** differing files — `.claude-plugin/plugin.json`, `CHANGELOG.md`, `LICENSE`, `README.md`, `references/dependencies.md`. Any sixth differing file is a port miss; any *fewer* means an identity file was overwritten.

```bash
cd /workspace/mgd-claude-plugins
grep -n "model fallback chain" CLAUDE.md                     # expect the Opus 5 … Sonnet 5 form
grep -n '"version"' plugins/dev-workflows/.claude-plugin/plugin.json   # expect 2.44.1
grep -n "^## \[" plugins/dev-workflows/CHANGELOG.md | head -4          # expect 2.44.1 above 2.44.0
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore(dev-workflows): port model-reference refresh — 2.44.1

Ten shared files copied verbatim from canonical. mgd's five plugin
identity files and its two repo-root files are hand-edited, never
copied.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Final verification (after Task 7)

Run the spec's §5 checks across all three repos:

```bash
# V3 — no stale trailer anywhere in live content
grep -rn "Opus 4.8 (1M context)" /workspace/ihudak-claude-plugins/plugins \
     /workspace/mgd-claude-plugins/plugins                                  # expect no output

# V6 — Haiku nowhere in a strong-tier statement
grep -rn "Haiku 4.5" /workspace/ihudak-copilot-plugins/dev-workflows/README.md \
     /workspace/ihudak-copilot-plugins/.github/copilot-instructions.md \
     /workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/model-routing.md   # expect no output

# V7/V8 — sonnet-5 and gpt-5.6 present in copilot
grep -rn "claude-sonnet-5\|gpt-5.6" /workspace/ihudak-copilot-plugins/dev-workflows/skills/_shared/model-routing.md

# V9 — old peer label gone from live copilot content
grep -rn "Opus 4.8/4.7/4.6 or GPT-5.5" /workspace/ihudak-copilot-plugins \
     --include=*.md --include=*.json --include=*.sh \
     | grep -v CHANGELOG | grep -v "docs/superpowers"                       # expect no output

# V12 — changelog ordering monotonic in all three
for f in /workspace/ihudak-claude-plugins/plugins/dev-workflows/CHANGELOG.md \
         /workspace/mgd-claude-plugins/plugins/dev-workflows/CHANGELOG.md \
         /workspace/ihudak-copilot-plugins/dev-workflows/CHANGELOG.md; do
  echo "== $f"; grep -n "^## \[" "$f" | head -5
done

# V13 — every manifest bumped
grep -n '"version"' /workspace/ihudak-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json \
                    /workspace/mgd-claude-plugins/plugins/dev-workflows/.claude-plugin/plugin.json \
                    /workspace/ihudak-copilot-plugins/dev-workflows/.plugin/plugin.json
```

**Changelogs must still contain their historical `Opus 4.8` references.** A sweep that "cleaned" them has falsified shipped history and must be reverted.
