# Documentation-workflow family — Increment 1 (cold-start scaffold) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `/docs-init`, `/docs-brand` and `/docs-serve` in `docs-workflows`, so a project with no documentation can scaffold a documentation repository that builds, serves, lints and is profiled.

**Architecture:** Three new slash commands and one new agent in `plugins/docs-workflows/`, backed by three new reference files under `plugins/docs-workflows/references/docs-workflow/` that carry the bulky, stable content (the scaffold tree and its configs, the two-build visibility model, the contrast rule). The commands orchestrate; the references hold what they write. Two existing contracts gain fields — `docs-profile-schema.md` (§8.5) and `frontmatter-guidelines.md` (§8.6) — and `/docs-profile` gains the `$DOCS_PATH` resolution rung D23 gives the whole family.

**Tech Stack:** Markdown command and agent bodies (no executable code in this repo beyond `scripts/*.sh|py`). The *scaffolded output* is Material for MkDocs (D8) + Vale + a GitHub Actions workflow; those artefacts are authored as templates inside the reference files, not executed here.

**Spec:** `docs/superpowers/specs/2026-08-29-docs-workflow-family-design.md`

**Verification model:** This repository has **no unit tests**. Its test suite is the seven CI gates in `.github/workflows/validate-catalog.yml`. Every task below states which gate proves it, how to make that gate go **red first**, and the exact command to run. That is the TDD cycle here, and it is a real one: `check-docs.sh` fails on a command with no docs page, an agent missing from the inventory, a count sentence that drifted, a `choices:` array with the wrong arity, or a core reference cited by path.

**The seven gates, in the order CI runs them:**

```bash
./scripts/validate-catalog.py --selftest
./scripts/validate-catalog.py .
./scripts/check-id-grammar.sh --selftest
./scripts/check-id-grammar.sh --root .
./scripts/check-docs.sh --selftest          # ~2 minutes
./scripts/check-docs.sh --root .
./plugins/workflows-core/scripts/session-cost.py --selftest
```

---

## Scope: this is increment 1 of 2 for Spec 1

Spec §2 decomposes the family into three specs and freezes Spec 1's contracts. Spec 1 itself has two halves that each produce something usable, so it is built as two increments:

| Increment | Commands | Ends with | Plan |
|---|---|---|---|
| **1 — the scaffold** (this plan) | `/docs-init`, `/docs-brand`, `/docs-serve` | A docs repo that builds, serves, lints, and carries a profile | this file |
| **2 — the audit** | `/docs-audit` | A prioritised backlog and a coverage grid | a separate plan, written after increment 1 merges |

**What increment 2 owns, so nothing here reaches for it:** `/docs-audit`, the agents `docs-auditor`, `ia-planner` and `docs-audit-reviewer`, the frozen contracts §8.1 (backlog schema), §8.2 (evidence contract) and §8.3 (walkthrough spec), the coverage model §5, and the route page `docs/docs-workflow.md` (§15.2) — that page states the eight-command procedure of §14 and is meaningless while three commands exist. `drift-detector` and `/docs-drift` belong to Spec 3 and are not built in either increment.

**Everything in §12 is contract-only and out of scope in both increments.**

---

## Global Constraints

Copied verbatim from the spec and from `CLAUDE.md`. Every task's requirements implicitly include this section.

**Packaging and reachability**

- The family ships from `plugins/docs-workflows/`. D1 is retired; do not place anything in `dev-workflows`.
- `docs-workflows` declares exactly `["workflows-core", "prose-style"]`. **Never dispatch a `dev-workflows` agent** — `code-review` and `review-fixer` are unreachable and are replaced by `docs-scaffold-reviewer` (D25).
- A `workflows-core` reference is cited `workflows-core:<name>` and loaded with `Skill(skill: "workflows-core:reference", args: "<name>")`, **never by path**. Every command and agent that cites one carries this preamble verbatim, as its first paragraph after the frontmatter:
  > **Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.
- This plugin's **own** references are reached as `${CLAUDE_PLUGIN_ROOT}/references/<path>` and keep that form. Check 16 relation 5 fails a *core* reference cited by path and says nothing about an own-plugin one.
- **Do not repeat the retired claim** that slash-command bodies cannot expand `${CLAUDE_PLUGIN_ROOT}`. It was verified false in a live run (spec §20 row 3; `CLAUDE.md`). `plugins/docs-workflows/commands/docs-profile.md:60` still carries it — that is a pre-existing defect, listed as a follow-up in this plan's closing section, not a pattern to copy.

**Authoring rules**

- Every `choices:` array is an `AskUserQuestion` call: **2–4 options, never an authored "Other"** (`workflows-core:escalation-rules` §0). Check 12 gates arity; its parser is bracket-matched and quote-aware.
- Requirement IDs are the bracketed `[PREFIX#N]` form, never dash-separated (`check-id-grammar.sh`).
- **Vendor neutrality (check 13):** no tracker name in any text file under `plugins/` without a `<!-- vendor-token-ok: <why> -->` marker on the line or on the fence opening its block. **Identity quarantine (check 14):** no organisation name anywhere in the repository, no marker, no exception.
- No page under `docs/` may name the marketplace or the containing repository (check 10). `getting-started.md` is the single sanctioned exception, pinned by check 7.
- Prose is never hard-wrapped (`workflows-core:prose-formatting`): one unbroken line per paragraph.
- No table cell exceeds **200 characters** (check 6), scoped to `docs/` trees plus the plugin README and repo README.
- Plugin `description` in both `plugin.json` and the `marketplace.json` entry: hard cap **1024 characters**, warning above 900. A new capability **replaces** wording; it never appends. Do not reformat `.claude-plugin/marketplace.json` — line-targeted edits only.

**Git**

- `git add -A` is never issued at repository scope; stage explicit paths.
- Verify the current branch with `git branch --show-current` **immediately before every commit**. This checkout is shared.
- Every commit ends with:
  ```
  Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01XQaUzS1o5p1rZeYANkcagU
  ```

**Counts that move in this increment** — every one is gated, and each is stated in exactly one file that `check-docs.sh` check 9 reads:

| What | File check 9 reads | Now | After increment 1 |
|---|---|---|---|
| Commands | `plugins/docs-workflows/README.md` | `Three slash commands` | `Six slash commands` |
| Agents | `plugins/docs-workflows/docs/reference/agents.md` | `seven agents` | `eight agents` |
| Reference files | `plugins/docs-workflows/docs/reference/references.md` | `14 files` | `18 files` |
| Hooks | `plugins/docs-workflows/docs/reference/hooks.md` | `two hooks` | unchanged |
| Bundled skills | `plugins/docs-workflows/docs/README.md` | `one bundled skills` | unchanged |
| Env vars | `plugins/docs-workflows/docs/reference/environment.md` | `four user-settable` | unchanged — `$DOCS_PATH` and `$REPOS_PATH` are already read by this plugin |
| Cost-emitting commands | `plugins/docs-workflows/docs/reference/session-cost.md` | `Two commands emit a cost entry` | `Four commands emit a cost entry` |

**The number-word trap, stated because it will bite.** `check-docs.sh`'s `_word2num` and each assertion's regex alternation enumerate a *partial* list of number words, and the lists differ per assertion. The agents/references/hooks alternations run `one|…|ten|twenty-one|thirty-four|ninety-eight|[0-9]+` — **`eleven` through `nineteen` are absent**. `eight` and `six` are present, and `[0-9]+` always matches, so **increment 1 needs no gate change**: use the word forms in the table above and the numeral `18` for reference files, exactly as `references.md` already does. Increment 2 takes agents to 11 and **will** need `eleven` taught to check 9 — with a fixture-growing selftest case proving the new word *converts*, not merely that an unknown word is rejected (`CLAUDE.md`). Do not pre-emptively widen the gate here.

---

## File Structure

**Created**

| Path | Responsibility |
|---|---|
| `plugins/docs-workflows/references/docs-workflow/scaffold-tree.md` | The scaffolded directory tree, the per-section rationale, the stub rule, the `nav:` generation rule, both `mkdocs` configs, and the `.vale.ini` template. Everything `/docs-init` Phase 3–4 writes. |
| `plugins/docs-workflows/references/docs-workflow/visibility.md` | The two-build model, both traps, the marker convention, the two output-level CI gates, and the GitHub Actions workflow template. |
| `plugins/docs-workflows/references/docs-workflow/contrast.md` | D24: the SC 1.4.3 / SC 1.4.11 threshold pair, the relative-luminance formula, and the adjudication rule. |
| `plugins/docs-workflows/references/docs-workflow/repo-resolution.md` | D23's two resolution forms — `resolve-docs-repo` (signal-positive, four consumers) and `resolve-scaffold-target` (inverted, `/docs-init` only) — plus the shared signal set. |
| `plugins/docs-workflows/agents/docs-scaffold-reviewer.md` | The seven-item scaffold review (spec §6 Phase 7.5). Opus. No `Task` tool. |
| `plugins/docs-workflows/commands/docs-serve.md` | Start/stop/status the docs server; report a reachable URL. |
| `plugins/docs-workflows/commands/docs-brand.md` | Extract and apply logo + colours, with a contrast finding. |
| `plugins/docs-workflows/commands/docs-init.md` | Scaffold the docs repo end to end. |
| `plugins/docs-workflows/docs/commands/docs-serve.md` | Human-facing page for `/docs-serve`. |
| `plugins/docs-workflows/docs/commands/docs-brand.md` | Human-facing page for `/docs-brand`. |
| `plugins/docs-workflows/docs/commands/docs-init.md` | Human-facing page for `/docs-init`. |
| `plugins/docs-workflows/docs/reference/docs-visibility.md` | Human-facing page for the two-build model (§15.2). |

**Modified**

| Path | Change |
|---|---|
| `plugins/docs-workflows/references/docs-profiles/docs-profile-schema.md` | §8.5: `generator`, `builds[]`, `dev_servers.*` additions, and the structured `images:` block with all three policies. |
| `plugins/docs-workflows/references/docs-profiles/docs-profile.default.yml` | The same fields, as defaults. |
| `plugins/docs-workflows/references/docs-profiles/frontmatter-guidelines.md` | §8.6: the four reserved keys `type`, `audience`, `visibility`, `unit`, plus `order`, `review_by`, `evidence`. |
| `plugins/docs-workflows/commands/docs-profile.md` | Phase 0 step 1 gains the `$DOCS_PATH` rung (D23, signal-positive form). |
| `plugins/docs-workflows/README.md` | Role table gains three rows; the opening sentence's command count; the agent/reference arithmetic paragraph. |
| `plugins/docs-workflows/docs/README.md` | "I want to…" rows; command index; the ships-N sentence. |
| `plugins/docs-workflows/docs/workflow.md` | The mermaid diagram gains all three commands (check 15 asserts diagram membership separately from the page). |
| `plugins/docs-workflows/docs/reference/agents.md` | `docs-scaffold-reviewer` row; count `seven` → `eight`. |
| `plugins/docs-workflows/docs/reference/references.md` | Three new reference rows; count `14` → `17`. |
| `plugins/docs-workflows/docs/reference/session-cost.md` | Count `Two` → `Four`; which commands emit and what they charge to. |
| `plugins/docs-workflows/docs/reference/environment.md` | `$DOCS_PATH`'s resolution paragraph gains D23's two forms. |
| `plugins/docs-workflows/docs/getting-started.md` | A first-run path for a project with no docs repo. |
| `plugins/workflows-core/references/cost-emission.md` | §7 gains a row for `/docs-init` and one for `/docs-brand`. |
| `plugins/workflows-core/references/specs-repo-git.md` | §2.1 gains the fourth bounded path shape (D19). |
| `plugins/docs-workflows/.claude-plugin/plugin.json` | Version bump; `description` **replaced**, not appended. |
| `.claude-plugin/marketplace.json` | The `docs-workflows` entry's `description`, line-targeted. |
| `plugins/docs-workflows/CHANGELOG.md`, `plugins/workflows-core/CHANGELOG.md` | Release entries. |
| `CLAUDE.md` | The `docs-workflows` inventory sentence, the workflow map, the command lists, the model-routing consumer count. |

**Not touched in this increment:** anything under `plugins/dev-workflows/`, `plugins/product-workflows/`, `plugins/guideline-reviewers/`, `plugins/prose-style/`, and `scripts/check-docs.sh` (see the number-word trap above).

---

## Task 1: The `references/docs-workflow/` corpus

The bulky, stable content the commands write lives here, so the command bodies stay orchestration. Four files, plus the human-facing page for the one of them that documents a model rather than a template.

**Files:**
- Create: `plugins/docs-workflows/references/docs-workflow/scaffold-tree.md`
- Create: `plugins/docs-workflows/references/docs-workflow/visibility.md`
- Create: `plugins/docs-workflows/references/docs-workflow/contrast.md`
- Create: `plugins/docs-workflows/references/docs-workflow/repo-resolution.md`
- Create: `plugins/docs-workflows/docs/reference/docs-visibility.md`
- Modify: `plugins/docs-workflows/docs/reference/references.md`
- Modify: `plugins/docs-workflows/docs/README.md`

**Interfaces:**
- Produces, for Tasks 4–7: four reference paths, cited from command bodies as `${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/<name>.md`. Their entry points, named in prose so a command can say which part it is executing: `scaffold-tree.md` → *the tree*, *the stubs*, *nav generation*, *mkdocs configs*, *vale config*; `visibility.md` → *the model*, *the traps*, *the gates*, *the CI workflow*; `contrast.md` → *the thresholds*, *the formula*, *the adjudication*; `repo-resolution.md` → *resolve-docs-repo* (signal-positive) and *resolve-scaffold-target* (the inversion).
- Consumes: nothing from earlier tasks.

- [ ] **Step 1: Make check 4 go red, so the gate is proven to be watching**

Create the directory and one file, and run the gate before writing the inventory row:

```bash
mkdir -p plugins/docs-workflows/references/docs-workflow
printf '# placeholder\n' > plugins/docs-workflows/references/docs-workflow/contrast.md
./scripts/check-docs.sh --root . 2>&1 | tail -20
```

Expected: **FAIL**, check 4 naming `references/docs-workflow/contrast.md` as present in the tree but absent from `docs/reference/references.md`, and check 9 reporting the reference-file count says 14 while the tree has 15.

This is the cycle for every file this task creates. Run it once, watch both checks fire, and stop treating the gate as decoration.

- [ ] **Step 2: Write `contrast.md`**

`plugins/docs-workflows/references/docs-workflow/contrast.md`, in full:

````markdown
# Contrast — the accessibility rule this family carries itself

**Why this file exists.** `/docs-brand` derives a palette from a product's own code and must not apply one that makes body text unreadable. The rule it needs is a threshold pair and a formula, not a review rulebook — so the family carries it rather than reaching into `guideline-reviewers`, whose `references/guidelines/accessibility.md` states the same rule inside 183 lines of application-UI review vocabulary and is not loadable from `docs-workflows` at all (design D24). That file is worth reading and is cited here as further reading; **nothing loads it at runtime**, so an install without that plugin behaves identically.

## 1. The thresholds

| What | Minimum contrast ratio | WCAG 2.2 success criterion |
|---|---|---|
| Body text against its background | **4.5:1** | SC 1.4.3 Contrast (Minimum) |
| Large text — 18pt / 24px, or 14pt / 18.66px bold — against its background | **3:1** | SC 1.4.3 |
| UI component boundaries, and graphical objects that carry meaning | **3:1** | SC 1.4.11 Non-text Contrast |
| A visible focus indicator | **3:1** | SC 2.4.7, SC 2.4.11, SC 2.4.13 |

`/docs-brand` checks the first three. The fourth is named because a theme that overrides focus styling can fail it, and the command reports rather than fixes.

## 2. The formula

Contrast ratio is `(L1 + 0.05) / (L2 + 0.05)`, where `L1` is the relative luminance of the lighter colour and `L2` of the darker.

Relative luminance of an sRGB colour, per WCAG 2.2:

```
for each channel C in {R, G, B}, with c = C / 255:
    c_lin = c / 12.92                      if c <= 0.04045
    c_lin = ((c + 0.055) / 1.055) ** 2.4   otherwise

L = 0.2126 * R_lin + 0.7152 * G_lin + 0.0722 * B_lin
```

Worked example — `#1565C0` on `#FFFFFF`:

```
R = 0x15 = 21   -> 21/255  = 0.0824 -> ((0.0824+0.055)/1.055)^2.4 = 0.00605
G = 0x65 = 101  -> 101/255 = 0.3961 -> 0.13287
B = 0xC0 = 192  -> 192/255 = 0.7529 -> 0.52712
L1(white) = 1.0
L2        = 0.2126*0.00605 + 0.7152*0.13287 + 0.0722*0.52712 = 0.13444
ratio     = (1.0 + 0.05) / (0.13444 + 0.05) = 5.69:1     -> passes SC 1.4.3
```

Report the ratio to two decimal places. Never report a pass or fail without the number.

## 3. Adjudication

- A derived colour that **fails** is reported as a finding naming the measured ratio, the pair it was measured against, and the criterion — never silently accepted and never silently corrected.
- **It is still applied if the operator confirms.** It is their brand; the command's job is that the choice is informed, not that it is overridden. The finding is carried into the PR message so the decision is visible to a reviewer.
- A **passing** colour produces no output. Silence is the pass signal.

## Further reading

`guideline-reviewers`' `references/guidelines/accessibility.md` covers WCAG 2.2 AA across an application's whole UI — keyboard navigation, accessible names, form fields, media — with the axe-core and W3C ACT rule ids for each. It is the right document for reviewing a product; it is not loadable from this plugin and nothing here reads it.
````

- [ ] **Step 3: Write `visibility.md`**

`plugins/docs-workflows/references/docs-workflow/visibility.md` carries spec §9 in full — the model, both traps, and both gates — plus the CI workflow template, which the spec describes but does not write out. Sections: `## 1. The model`, `## 2. Trap 1 — the dev server does not exclude`, `## 3. Trap 2 — snippets cross the boundary invisibly`, `## 4. The two gates`, `## 5. The marker convention`, `## 6. The CI workflow`.

§5 fixes the marker so both halves agree — every file under `docs/internal/` and every snippet intended for internal pages carries, as its first line after the frontmatter:

```markdown
<!-- docs-visibility: internal -->
```

and §6 is the workflow the scaffold writes to `.github/workflows/docs.yml`:

```yaml
name: docs
on:
  pull_request:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements-docs.txt
      - name: Build public site
        run: mkdocs build --strict -f mkdocs.yml
      - name: Build internal site
        run: mkdocs build --strict -f mkdocs.internal.yml
      - name: Gate 2 — no internal marker in the public build
        run: |
          if grep -rl 'docs-visibility: internal' site/; then
            echo "::error::internal content reached the public build"
            exit 1
          fi
      - name: Gate 3 — every public image URL resolves to the public prefix
        run: scripts/check-image-prefix.sh
      - name: Image size budget
        run: |
          find docs/assets -type f -size +300k -print -exec false {} + \
            || { echo "::error::image over the 300 KB budget"; exit 1; }
      - name: Vale
        run: vale docs/
```

**Gate 3 is conditional on the profile's `images.policy`.** Under `in-repo` it is not written at all — there are no URLs to check. Under `object-store` or `cdn` it is written and asserts every image URL in the built public output starts with the profile's `images.public_prefix`. State that in §4 rather than leaving the reader to infer it from the template.

**The size-budget step is likewise `in-repo`-only**, and its threshold is the profile's `images.max_bytes`, not a literal — the template above shows the default of 307200 bytes rendered as `+300k`.

- [ ] **Step 4: Write `scaffold-tree.md`**

`plugins/docs-workflows/references/docs-workflow/scaffold-tree.md` carries spec §6 Phase 3 and Phase 4 as an executable template. Sections and what each holds:

| Section | Content |
|---|---|
| `## 1. The tree` | The directory listing from spec §6 Phase 3 verbatim, with the optional sections marked by the flag that produces them (`--with-pricing`, `--with-compliance`) |
| `## 2. Why each section` | The nine-row rationale table from spec §6 Phase 3 |
| `## 3. Stubs` | One stub per directory, stating what belongs there and what does not, carrying the section's default `type:` in frontmatter. The stub bodies, written out — this is the content that stops contributors putting explanation into how-to guides |
| `## 4. `nav:` generation` | Sort each section's pages on frontmatter `order`, then `title`. Regenerated on every write by `/docs-init` and `/docs-write`; never hand-maintained |
| `## 5. `mkdocs.yml`` | The public build, written out |
| `## 6. `mkdocs.internal.yml`` | The internal build, written out |
| `## 7. `.vale.ini` and the vocabulary` | The Vale config, `vale sync`, and the `Project` vocabulary seeding rule |

§5's `mkdocs.yml`:

```yaml
site_name: <product>
strict: true
theme:
  name: material
  logo: assets/logo.svg
  favicon: assets/favicon.png
  features: [navigation.sections, navigation.top, search.suggest, content.code.copy]
markdown_extensions:
  - admonition
  - attr_list
  - md_in_html
  - toc: { permalink: true }
  - pymdownx.snippets: { base_path: [docs/_snippets] }
  - pymdownx.superfences
  - pymdownx.tabbed: { alternate_style: true }
exclude_docs: |
  internal/
validation:
  nav:
    omitted_files: warn
    absolute_links: warn
extra_css:
  - stylesheets/extra.css
nav:
  # generated — see §4; do not hand-edit
```

§6's `mkdocs.internal.yml`:

```yaml
INHERIT: mkdocs.yml
site_name: <product> (internal)
exclude_docs: ""
nav:
  # generated — the public nav plus the internal/ sections; see §4
```

**`exclude_docs: ""` is the whole of the difference between the two builds, and stating that here is what makes review item 2 checkable** (spec §6 Phase 7.5): a second `nav:` source, a different `markdown_extensions` list, or a divergent `theme` block in the internal config is a defect, not a customisation.

§7's `.vale.ini`:

```ini
StylesPath = styles
MinAlertLevel = suggestion
Packages = Google, write-good
Vocab = Project

[*.md]
BasedOnStyles = Vale, Google, write-good
```

After writing it, run `vale sync` to download the packages, and seed `styles/config/vocabularies/Project/accept.txt` from the domain nouns `/docs-audit` extracts for its `concept` surfaces. **`/docs-audit` does not exist until increment 2**, so in this increment the file is always created with the comment form:

```
# Product terms Vale should not flag as misspellings.
# /docs-workflows:docs-audit seeds this from the domain nouns it extracts for
# `concept` surfaces. Until then, add terms by hand — one per line, regex-escaped.
```

Without this file every product term is a spelling error on day one and the team turns Vale off in week two.

- [ ] **Step 5: Write `repo-resolution.md` — the one place the docs repo is resolved**

D23 gives the family one docs-repo default and one inversion, and four commands need it. Restating a resolution ladder in four command bodies is how the family's longest-running defect class started (`CLAUDE.md`: *resolve an identifier against a known set*; *re-measure in one place, cite it everywhere else*). So it is written once, here, with two named entry points.

`plugins/docs-workflows/references/docs-workflow/repo-resolution.md`:

`## 1. resolve-docs-repo` — the **signal-positive** form, used by `/docs-brand`, `/docs-serve`, `/docs-profile` and (increment 2) `/docs-audit`. It resolves a docs repo that already exists:

1. the first positional token, if there is one;
2. else cwd, **when it carries ≥ 1 docs signal**;
3. else `${DOCS_PATH:-/workspace/docs}`, **when it carries ≥ 1 docs signal** — in an AI container the docs clone is mounted here, which makes this the common fast path;
4. else search `${REPOS_PATH:-/workspace}` one level deep for a directory carrying signals; a single hit is taken, several are offered as a choice;
5. else ask.

`## 2. resolve-scaffold-target` — the **inverted** form, used by `/docs-init` alone:

1. the first positional token, if there is one;
2. else `${DOCS_PATH:-/workspace/docs}`, **when it is absent, or exists and carries no docs signal**;
3. else the current working directory.

**A `$DOCS_PATH` carrying a signal is never skipped silently at rung 2.** It is reported, with the redirect to `/docs-profile`, because it is almost certainly the repository the operator meant — they pointed the variable at a docs repo and then asked to scaffold one.

`## 3. The signal set` — the single list both forms test against, identical to `/document` Phase 0's: a `*:start` / `*:build` / `*:lint` / `docs:*` script in `package.json`, `.docstack/`, `mkdocs.yml`, `docusaurus.config.js`, `antora.yml`, `.vale.ini`, `DOCUMENTATION-GUIDELINES.md`, any `*/_content/`, or any `_snippets/`. **Signal-based, never keyed to a repository's name or file layout.**

`## 4. Why the two forms are opposite` — spell it out, because an implementer copying `/document`'s ladder into `/docs-init` gets it backwards and the scaffold then refuses the one directory it was pointed at. Every other consumer wants a docs repo that exists; `/docs-init` wants a place to make one, and its Phase 0 step 4 refuses to scaffold over an existing docs repo. Same variable, same default, opposite predicate.

`## 5. What this file does not do` — it resolves a path and reports which rung answered. It never creates a directory, never runs `git init`, and never validates writability; those belong to the calling command's Phase 0, because the right response differs per command.

- [ ] **Step 6: Write the human-facing `docs/reference/docs-visibility.md`**

Covers the two-build model, both traps and both output-level gates (spec §15.2). Derived from `references/docs-workflow/visibility.md`, which is the thing that runs — not from the design document. No table cell over 200 characters. No mention of the marketplace or the container repo (check 10).

- [ ] **Step 7: Add the four reference rows and fix the count**

In `plugins/docs-workflows/docs/reference/references.md`, add one row per new file under a `docs-workflow/` grouping, and change the count sentence. The current sentence reads `14 files`; it becomes `18 files`. Re-derive rather than trusting this plan:

```bash
find plugins/docs-workflows/references -type f | wc -l
```

- [ ] **Step 8: Link the new page from the index**

`plugins/docs-workflows/docs/README.md` gains a link to `reference/docs-visibility.md`. Check 3 fails a page unreachable from this index.

- [ ] **Step 9: Run the gates**

```bash
./scripts/check-docs.sh --root . && ./scripts/check-id-grammar.sh --root .
```

Expected: **PASS** on both. If check 9 still reports the reference count, the sentence wording drifted from the regex — the assertion needs a numeral or word immediately before the literal word `files`.

- [ ] **Step 10: Commit**

```bash
git branch --show-current    # must be the increment branch, not main
git add -- plugins/docs-workflows/references/docs-workflow \
           plugins/docs-workflows/docs/reference/docs-visibility.md \
           plugins/docs-workflows/docs/reference/references.md \
           plugins/docs-workflows/docs/README.md
git commit -m "feat(docs-workflows): the docs-workflow reference corpus for the scaffold"
```

---

## Task 2: The two contracts the scaffold writes into

`/docs-init` Phase 6 writes a profile, and every scaffolded stub carries frontmatter. Both schemas are existing files that gain fields; neither adds a file, so no count moves.

**Files:**
- Modify: `plugins/docs-workflows/references/docs-profiles/docs-profile-schema.md`
- Modify: `plugins/docs-workflows/references/docs-profiles/docs-profile.default.yml`
- Modify: `plugins/docs-workflows/references/docs-profiles/frontmatter-guidelines.md`

**Interfaces:**
- Produces, for Task 6: the profile keys `generator`, `builds[]`, `dev_servers.servers[].public_base_url`, `dev_servers.readiness_timeout_seconds`, and the structured `images:` block. For Task 4: `dev_servers` is what `/docs-serve` reads. For Task 5: `images.policy` decides which gates Task 1's CI template emits.
- Consumes: nothing.

- [ ] **Step 1: Add the §8.5 profile fields**

Append to `docs-profile-schema.md`, as additive optional keys:

```yaml
generator: mkdocs-material            # informational; consumers still go through commands.*
builds:                               # two builds from ONE content root
  - { id: public,   config: mkdocs.yml,          command: "mkdocs build --strict -f mkdocs.yml",          out: site,          visibility: public }
  - { id: internal, config: mkdocs.internal.yml, command: "mkdocs build --strict -f mkdocs.internal.yml", out: site-internal, visibility: internal }
dev_servers:
  readiness_timeout_seconds: 120
  servers:
    - { space: docs, command: "mkdocs serve -a 0.0.0.0:8000", port: 8000, public_base_url: "http://localhost:8001" }
```

State **why `builds:` is not a second `spaces[]` entry**, verbatim from spec §8.5: `spaces[]` is defined by content-root ownership — a page belongs to whichever entry's `content_root` prefixes its path — so two spaces sharing one root breaks that rule. Two builds over one root is a different axis and needs its own field.

State why `public_base_url` exists: a command running inside a container cannot infer the host's published port mapping (spec §10.2).

- [ ] **Step 2: Convert `images.policy` from prose to structure**

The existing key is a free-text sentence. It becomes:

```yaml
images:
  policy: in-repo | object-store | cdn  # all three of D16's policies
  root: docs/assets                     # in-repo only
  max_bytes: 307200                     # in-repo only; the CI budget
  public_prefix: https://…/public/      # object-store and cdn; every public-build image URL must start here
  internal_prefix: https://…/internal/  # object-store only; what the third visibility gate asserts against
```

**All three policies, and both prefix fields.** Spec §8.4 requires a third visibility gate under `object-store`, and a gate cannot assert against a prefix the profile does not record. Writing `in-repo | cdn` here silently deletes a policy D16 decided — the defect the spec review caught and closed.

Document each policy's obligations from spec §8.4: `in-repo` gets the 300 KB budget, SVG preference, and one-path-per-slot; `object-store` additionally owes an orphan sweep and the third gate; `cdn` inverts the overwrite rule — every replacement is a new URL.

- [ ] **Step 3: Mirror the fields into `docs-profile.default.yml`**

The same keys with the scaffold's defaults — `generator: mkdocs-material`, both builds, `images.policy: in-repo`, `images.max_bytes: 307200`. This file is read as **data**, not prose; keep it valid YAML.

```bash
python3 -c "import yaml,sys; yaml.safe_load(open('plugins/docs-workflows/references/docs-profiles/docs-profile.default.yml')); print('valid')"
```

- [ ] **Step 4: Declare the four reserved frontmatter keys**

In `frontmatter-guidelines.md`, add a section stating that this family reserves `type`, `audience`, `visibility` and `unit`, and touches nothing else in the skill's territory (D18). Give each its vocabulary:

- `type` — user: `tutorial | how-to | reference | explanation`; engineering: `architecture | decision | runbook | api-reference`
- `audience` — `user | engineering`
- `visibility` — `public | internal`, **defaulting from `audience` but independently settable** (D12): API reference is engineering-audience and usually public; a runbook naming hostnames is not
- `unit` — the backlog unit id; **written by increment 2's `/docs-audit` and `/docs-write`, and left absent by every stub this increment scaffolds**

Also document `order` (generates the nav — without it MkDocs takes order from `mkdocs.yml` and the field is decorative), `review_by` (the calendar backstop for rot no diff can see), and `evidence` (what the page's claims rest on). Note that `readtime` is **computed**, never typed.

- [ ] **Step 5: Run the gates and commit**

```bash
./scripts/check-docs.sh --root . && ./scripts/check-id-grammar.sh --root .
git branch --show-current
git add -- plugins/docs-workflows/references/docs-profiles
git commit -m "feat(docs-workflows): profile and frontmatter contracts for the scaffold"
```

Expected: PASS. No count moves in this task — if check 9 fires, a file was added rather than modified.

---

## Task 3: `docs-scaffold-reviewer`

The gate D25 puts in place of the unreachable `code-review` + `review-fixer` pair.

**Files:**
- Create: `plugins/docs-workflows/agents/docs-scaffold-reviewer.md`
- Modify: `plugins/docs-workflows/docs/reference/agents.md`

**Interfaces:**
- Produces, for Tasks 5 and 6: `subagent_type: "docs-workflows:docs-scaffold-reviewer"`. It returns findings only — **no fixer**; the orchestrator applies survivors after triage.
- Consumes: `references/docs-workflow/scaffold-tree.md` and `visibility.md` from Task 1, which are what makes items 1–3 and 5 checkable.

- [ ] **Step 1: Make check 4 go red**

```bash
printf -- '---\nname: docs-scaffold-reviewer\ndescription: placeholder\n---\n' \
  > plugins/docs-workflows/agents/docs-scaffold-reviewer.md
./scripts/check-docs.sh --root . 2>&1 | tail -20
```

Expected: **FAIL** — check 4 reports the agent is in the tree but not in `docs/reference/agents.md`, and check 9 reports the agent count says seven while the tree has eight.

- [ ] **Step 2: Write the agent**

Frontmatter, exactly:

```yaml
---
name: docs-scaffold-reviewer
description: Reviews the documentation-repository scaffold written by /docs-init and /docs-brand — the mkdocs configs, the generated nav, .vale.ini, the CI workflow and the theme CSS. Returns PASS / PASS WITH RECOMMENDATIONS / BLOCK. Uses Claude Opus. Product documentation prose is reviewed by doc-reviewer; this reviewer never reads page content.
model: opus
tools: ["Read", "Glob", "Grep", "Bash", "Skill"]
---
```

**No `Task` in the tool list.** Check 17 asserts the pair in both directions: an agent granted `Task` must carry the NEVER-dispatch anchor sentence, and an agent carrying that sentence without `Task` declares an authority the harness would refuse. This agent dispatches nothing, so it gets neither.

Body: the core-references preamble verbatim, then the seven checks from spec §6 Phase 7.5, each with what it is checked against:

1. the generated `nav:` lists every scaffolded page exactly once, and every page it lists exists — check against the tree, not against the config's own claim;
2. the two builds differ **only** by the exclusion — `mkdocs.internal.yml` is `INHERIT` plus `exclude_docs: ""` plus its nav, and nothing else;
3. `strict: true` is set and `validation.nav.omitted_files` / `absolute_links` are `warn`, so a public page linking into `internal/` fails the build;
4. `.vale.ini` parses and every style it names resolves — `vale ls-config` is the cheap proof;
5. the CI workflow runs **both** builds and every gate the profile's `images.policy` calls for, not only the build;
6. the image size budget is wired to the policy the profile actually records — a budget step under a `cdn` policy is as wrong as a missing one under `in-repo`;
7. no `internal/` path, hostname or marker appears in the public config.

State in the body **why the list is written down rather than left to judgement**: six of the seven assert a relationship between two files, which is exactly what a reviewer reading one diff hunk at a time misses.

Verdict vocabulary and the finding shape follow `doc-reviewer`'s — read `plugins/docs-workflows/agents/doc-reviewer.md` and match it, so the orchestrator's triage step handles both identically.

- [ ] **Step 3: Add the inventory row and fix the count**

In `docs/reference/agents.md`, add the row and change `seven agents` to `eight agents`. `eight` is in check 9's agent alternation; `eleven` is not, which is increment 2's problem, not this one.

- [ ] **Step 4: Run the gates**

```bash
./scripts/check-docs.sh --root .
```

Expected: **PASS**, including check 17 green on a four-agent-with-`Task` tree unchanged — this agent adds none.

- [ ] **Step 5: Commit**

```bash
git branch --show-current
git add -- plugins/docs-workflows/agents/docs-scaffold-reviewer.md \
           plugins/docs-workflows/docs/reference/agents.md
git commit -m "feat(docs-workflows): docs-scaffold-reviewer, the gate D25 puts in reach"
```

---

## Task 4: `/docs-serve`

The smallest of the three, built first because it exercises Task 1's resolver and Task 2's `dev_servers` block with nothing else attached. It writes no artefact, so it carries **no review gate** (D17's sole exemption), **no `specs-preflight`**, **no `commit-artifacts`** and **no cost entry** — it starts a process and reports a URL. Its closest sibling is `/statusline`, not `/document`.

**Files:**
- Create: `plugins/docs-workflows/commands/docs-serve.md`
- Create: `plugins/docs-workflows/docs/commands/docs-serve.md`
- Modify: `plugins/docs-workflows/README.md`, `plugins/docs-workflows/docs/README.md`, `plugins/docs-workflows/docs/workflow.md`, `plugins/docs-workflows/docs/reference/session-cost.md`

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/repo-resolution.md` *resolve-docs-repo* (Task 1); the profile's `dev_servers` block (Task 2).
- Produces, for Task 6: nothing — `/docs-init` names `/docs-serve` in its closing next-step offer but never invokes it.

- [ ] **Step 1: Make check 4 and check 15 go red**

```bash
printf -- '---\nname: docs-serve\ndescription: placeholder\nallowed-tools: Read Bash Skill\n---\nplaceholder\n' \
  > plugins/docs-workflows/commands/docs-serve.md
./scripts/check-docs.sh --root . 2>&1 | tail -25
```

Expected: **FAIL** on check 4 (no `docs/commands/docs-serve.md`), check 15 (absent from `docs/README.md`, the plugin README, and `docs/workflow.md`'s mermaid diagram — asserted separately from the page), and check 9 (`Three slash commands`, tree has 4).

- [ ] **Step 2: Write the command**

Frontmatter:

```yaml
---
name: docs-serve
description: Start, stop or check the documentation site's dev server for a profiled docs repo, and report a URL that actually opens from the host. Reads the profile's dev_servers block; never starts a second server on a port that already answers; falls forward to the next free port on a collision and says so. --build runs the profile's build command and exits. Writes no documentation and no artefact.
allowed-tools: Read Bash Glob Grep Skill
---
```

Body, following spec §10:

- The core-references preamble verbatim.
- **Signature line:** `/docs-serve [<docs-repo-path>] [--internal] [--stop] [--status] [--build] [--port <n>]`. Strip flags before the positional token is read.
- **Phase 0 — Resolve.** Execute *resolve-docs-repo* from `${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/repo-resolution.md`. Report which rung answered. **No `specs-preflight`** — state that it is deliberate, with the reason: this command writes nothing into `$SPECS_PATH`, so a preflight would open a branch discipline for a run that has no artefact.
- **Phase 1 — Read `dev_servers`.** `--internal` selects the internal build's server; default is public. A profile with no `dev_servers` block stops with `DOCS_SERVE_NO_DEV_SERVER`, naming `/docs-profile` as what writes one.
- **Phase 2 — Already-running detection.** If the port answers and the response identifies the docs site, report the existing URL and stop. **Never start a second server.**
- **Phase 3 — Port collision.** If the port is occupied by something that is not the docs site, take the next free port, use it, and **say so explicitly** — a silently shifted port is a URL the operator will not find.
- **Phase 4 — Start.** Bash `run_in_background`. Bind `0.0.0.0`, never `localhost`: a server bound to the container's loopback is unreachable from the host, which is where the browser is.
- **Phase 5 — Readiness.** Poll up to `dev_servers.readiness_timeout_seconds` (default 120), then print the URL.
- **Phase 6 — Report the host-visible URL.** `public_base_url` from the profile when set; otherwise the in-container URL **with an explicit caveat naming the likely mismatch**. It never silently prints a URL that will not open. A port-shifted stack is the normal case, not the exotic one, and guessing the mapping would be wrong more often than right.
- **Phase 7 — Record state.** pid and port under `.dev-workflows/`, so `--stop` and `--status` work across sessions.
- `--build` runs the profile's build command and exits without serving. Say why there is no `/docs-build`: the pipeline already gates on the profile's build, and a flag is cheaper than a command.
- **A closing next-step offer** carrying `workflows-core:next-phase-offer`'s merge clause. Check 11 does **not** cover the `/docs-*` family — no `/docs-*` glob appears in that reference's scope paragraph — so this is discipline, not gate, and the command says so where the offer is written.

Any `choices:` array here carries **2–4 options and no authored "Other"** (check 12).

- [ ] **Step 3: Write the human-facing page**

`plugins/docs-workflows/docs/commands/docs-serve.md`, following the established shape: synopsis, when to use it, prerequisites, phases, gates, outputs, failure modes. **Every claim derived from the command file, not from this plan or from the design document** — the synopsis from the argument-parsing phase, the phases from the `## Phase` headings. No table cell over 200 characters.

- [ ] **Step 4: Index it in all three surfaces check 15 asserts**

1. `plugins/docs-workflows/docs/README.md` — a command-index row, plus an "I want to…" row: *open the docs in a browser* → `/docs-serve`.
2. `plugins/docs-workflows/README.md` — the role table. `/docs-serve` joins the **Anytime — setup** row beside `/docs-profile`, per spec §15.1: it is a utility reached at any point, not a stage.
3. `plugins/docs-workflows/docs/workflow.md` — **the mermaid diagram**, not only the prose. Add `docsserve["/docs-workflows:docs-serve"]` to the `SETUP` subgraph. This is the half that shipped broken once before (`/frames` reached the page's prose but not its diagram).

- [ ] **Step 5: Record that it emits no cost entry**

In `docs/reference/session-cost.md`, leave the count at `Two` for now and add a sentence naming `/docs-serve` among the commands that emit nothing, with the reason. Check 8's reverse direction fails a `cost-emission` §7 row naming a command that emits no fixed pair, so **do not add a §7 row for this command**.

- [ ] **Step 6: Run the gates**

```bash
./scripts/check-docs.sh --root . && ./scripts/check-id-grammar.sh --root . && ./scripts/validate-catalog.py .
```

Expected: PASS. Check 9's command count must now read `Four slash commands` in the plugin README.

- [ ] **Step 7: Commit**

```bash
git branch --show-current
git add -- plugins/docs-workflows/commands/docs-serve.md \
           plugins/docs-workflows/docs/commands/docs-serve.md \
           plugins/docs-workflows/docs/README.md \
           plugins/docs-workflows/docs/workflow.md \
           plugins/docs-workflows/docs/reference/session-cost.md \
           plugins/docs-workflows/README.md
git commit -m "feat(docs-workflows): /docs-serve — run the docs site from any profiled repo"
```

---

## Task 5: `/docs-brand`

Extract a logo and a rough colour pair from the product's own code and apply them. Expectations are deliberately modest: a mark and a primary/accent pair, not a design system.

**Files:**
- Create: `plugins/docs-workflows/commands/docs-brand.md`
- Create: `plugins/docs-workflows/docs/commands/docs-brand.md`
- Modify: `plugins/workflows-core/references/cost-emission.md` (§7 row)
- Modify: `plugins/docs-workflows/README.md`, `docs/README.md`, `docs/workflow.md`, `docs/reference/session-cost.md`

**Interfaces:**
- Consumes: *resolve-docs-repo* and `contrast.md` from Task 1; `docs-scaffold-reviewer` from Task 3.
- Produces, for Task 6: the `--inline` contract. An `--inline` run **skips its own preflight, review gate and PR** and returns its diff into `/docs-init`'s Phase 7.5 review and single PR. This is the dual shape `/docs-profile` already uses (standalone, plus `--inline` from `/document` Phase 0 case (c)), and D14 chose it for the same reason: rebrands happen, and re-scaffolding to pick up a new logo is absurd.

- [ ] **Step 1: Make the gates go red**

Create the command file as a placeholder and run `./scripts/check-docs.sh --root .`. Expected: checks 4, 15 and 9 fire exactly as in Task 4 step 1.

- [ ] **Step 2: Write the extraction phase**

Spec §7.1. **Colour**, in precedence order, first hit wins and **the source is recorded** — file and line:

1. Tailwind config `theme.extend.colors` (`primary`, `brand`, or the first non-neutral entry)
2. CSS custom properties matching `--(color-)?(primary|brand|accent)`
3. A MUI `createTheme({ palette: { primary, secondary } })` call
4. `manifest.json` / `site.webmanifest` `theme_color`
5. SCSS/LESS variables matching `$(primary|brand|accent)`

**Logo**, preferring SVG over PNG and larger over smaller: `public/`, `src/assets/`, `static/`, files matching `logo*` / `brand*` / `icon*`, `favicon.*`, and manifest `icons[]`.

`--from <code-repo-path>` names the repo to extract from; absent, use the profile's recorded source-repo set, and where that is absent too, `ls ${REPOS_PATH:-/workspace}` and confirm.

- [ ] **Step 3: Write the application phase**

Spec §7.2. Material takes hex brand colours through a custom palette plus CSS variables — **named palette colours do not accept hexes**, which is the thing that silently does nothing if you get it wrong:

```yaml
theme:
  palette:
    primary: custom
  logo: assets/logo.svg
  favicon: assets/favicon.png
extra_css:
  - stylesheets/extra.css
```

```css
:root > * {
  --md-primary-fg-color:        #<primary>;
  --md-primary-fg-color--light: #<primary-light>;
  --md-primary-fg-color--dark:  #<primary-dark>;
  --md-accent-fg-color:         #<accent>;
}
```

Light and dark variants are derived from the primary where the source supplies only one value.

- [ ] **Step 4: Write the honesty and accessibility phase**

Spec §7.3, three rules, each stated as a rule rather than a preference:

- **Never applies silently.** Print each extracted value with the file and line it came from, and ask to confirm. A wrong brand colour applied quietly is worse than no branding.
- **Contrast check** against `${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/contrast.md` — *the thresholds*, *the formula*, *the adjudication*. Report the measured ratio to two decimals with the criterion. A failing colour is **still applied if the operator confirms** — it is their brand — and the finding is carried into the PR message.
- **Copies, never links.** Logo assets are copied into `docs/assets/`; the docs build never reaches into a code repo at build time.

- [ ] **Step 5: Write the review gate and the finish**

`docs-scaffold-reviewer` at Opus over the config and CSS diff, triaged per `workflows-core:finding-triage`, **survivors applied by the orchestrator** — there is no fixer (D25). A survivor that fails the patch gate is surfaced for a human decision rather than patched.

Standalone runs review their own diff and end with branch + commit + a drafted PR message, never a push and never a merge — the same discipline as `/docs-profile`. Then the emitter tail: feedback → follow-ups → cost → `resume.md` → `commit-artifacts`, and exactly one `Specs repo:` line.

An `--inline` run does none of that: no preflight, no review, no PR, no emitter tail. It returns its diff and its contrast finding to the caller.

- [ ] **Step 6: Add the cost-emission §7 row**

In `plugins/workflows-core/references/cost-emission.md` §7's table:

```
| `/docs-brand` | docs-scaffold | dev |
```

Check 8 fails in both directions, so this row and the command's `emit-cost` call must arrive together. **Only the standalone path emits** — an `--inline` run's cost belongs to `/docs-init`'s entry, and emitting twice would double-count one run.

- [ ] **Step 7: Index, count, and run the gates**

`docs/README.md`, the plugin README's **Anytime — setup** row (spec §15.1 puts `/docs-brand` there beside `/docs-profile` and `/docs-serve`), and `docs/workflow.md`'s mermaid diagram. Command count → `Five slash commands`. Cost count → `Three commands emit a cost entry`.

```bash
./scripts/check-docs.sh --root . && ./scripts/check-id-grammar.sh --root . && ./scripts/validate-catalog.py .
```

- [ ] **Step 8: Commit**

```bash
git branch --show-current
git add -- plugins/docs-workflows/commands/docs-brand.md \
           plugins/docs-workflows/docs/commands/docs-brand.md \
           plugins/docs-workflows/docs/README.md \
           plugins/docs-workflows/docs/workflow.md \
           plugins/docs-workflows/docs/reference/session-cost.md \
           plugins/docs-workflows/README.md \
           plugins/workflows-core/references/cost-emission.md
git commit -m "feat(docs-workflows): /docs-brand — logo and colours, with a contrast finding"
```

---

## Task 6: `/docs-init`

The scaffold. Its bulk lives in Task 1's references, so this command body is orchestration: resolve, refuse, preflight, scaffold, lint, brand, profile, verify, review, finish.

**Files:**
- Create: `plugins/docs-workflows/commands/docs-init.md`
- Create: `plugins/docs-workflows/docs/commands/docs-init.md`
- Modify: `plugins/workflows-core/references/cost-emission.md` (§7 row)
- Modify: `plugins/workflows-core/references/specs-repo-git.md` (§2.1 fourth path shape)
- Modify: `plugins/docs-workflows/README.md`, `docs/README.md`, `docs/workflow.md`, `docs/getting-started.md`, `docs/reference/session-cost.md`

**Interfaces:**
- Consumes: all four of Task 1's references; Task 2's profile and frontmatter contracts; Task 3's reviewer; Task 5's `--inline` contract.
- Produces: a scaffolded docs repo, and `.dev-workflows/docs-profile.yml` — which is what makes `/docs-serve` and (increment 2) `/docs-audit` work on it.

- [ ] **Step 1: Make the gates go red**

Placeholder command file, then `./scripts/check-docs.sh --root .`. Expected: checks 4, 15, 9 fire.

- [ ] **Step 2: Phase 0 — Resolve and validate**

Spec §6 Phase 0, four steps in this order:

1. Execute *resolve-scaffold-target* from `repo-resolution.md` — the **inverted** form. Print which rung answered: a scaffold that writes into an unexpected directory is expensive to unpick.
2. Run `specs-preflight` against `$SPECS_PATH` via `Skill(skill: "workflows-core:reference", args: "specs-repo-git specs-preflight")`, as early as `$SPECS_PATH` is known.
3. The target must be a writable git work tree, or an empty/absent directory the command offers to `git init`. A non-empty directory that is not a git work tree stops with `NOT_A_GIT_WORKTREE`.
4. **Refuse to scaffold over an existing docs repo.** With ≥ 1 docs signal present (the signal set in `repo-resolution.md` §3), stop and point at `/docs-profile`. Scaffolding is for cold start; describing an existing repo is a different command.

- [ ] **Step 3: Phases 1–2 — Routing and preflight**

Phase 1: invoke `Skill(skill: "workflows-core:model-routing")`. `/docs-init` is **MODERATE** — mechanical scaffolding against a known template whose output is reviewed as a PR. State the classification and a one-line reason. (Contrast `/docs-audit`, SIGNIFICANT — increment 2.)

Phase 2: resolve the code repos to be documented — `ls ${REPOS_PATH:-/workspace}` plus any explicitly named — and **confirm the set with the operator**. This set is recorded in the profile and reused by `/docs-audit` and `/docs-drift`. Then run the toolchain check per `${CLAUDE_PLUGIN_ROOT}/references/toolchain-preflight.md` for `python3`/`pip` (or `uv`), `mkdocs`, `vale`, `git`. Prompt **only** when something required is missing, Cancel recommended.

- [ ] **Step 4: Phases 3–4 — Scaffold and Vale**

Execute *the tree*, *the stubs*, *nav generation*, *mkdocs configs* and *vale config* from `${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/scaffold-tree.md`, and *the CI workflow* and *the marker convention* from `visibility.md`. `--public-only` omits `mkdocs.internal.yml`, the `internal/` tree and gate 2; `--with-pricing` and `--with-compliance` add their optional stubs.

**The command body does not restate the tree.** It names the entry points and the flags that vary them. A second copy of a forty-directory tree is a second thing to keep in step, and this repository has paid for that mistake more than once.

- [ ] **Step 5: Phases 5–6 — Branding and profile**

Phase 5: run `/docs-brand --inline` (Task 5) unless `--no-brand`. Its diff and its contrast finding join this run's review and this run's single PR.

Phase 6: write `.dev-workflows/docs-profile.yml` conforming to `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/docs-profile-schema.md`, including Task 2's `generator`, `builds[]`, `dev_servers` and structured `images:` block. `images.policy` defaults to `in-repo` (D16).

- [ ] **Step 6: Phase 7 — Verify the scaffold**

Four steps, in order, because a scaffold that cannot build is not a scaffold:

1. `mkdocs build --strict -f mkdocs.yml` succeeds (public).
2. `mkdocs build --strict -f mkdocs.internal.yml` succeeds (internal) — skipped under `--public-only`.
3. `vale docs/` runs and returns; findings are informational at this stage, but the run must not error on configuration.
4. The visibility gate passes against the **public build output** — `visibility.md` *the gates*.

**A failure at any step is reported and left unfixed rather than worked around.** Write that as a rule in the command body, not as advice.

- [ ] **Step 7: Phases 7.5–8 — Review and finish**

Phase 7.5: dispatch `docs-scaffold-reviewer` at Opus over the written diff, triage per `workflows-core:finding-triage`, orchestrator applies survivors, a survivor failing the patch gate is surfaced rather than patched. Tell the reviewer which of its seven items `--public-only` makes inapplicable, rather than letting it report a missing internal build as a defect.

Phase 8: branch, commit, draft a PR message. **Never pushes, never merges.** Then the emitter tail: feedback → follow-ups → cost → `resume.md` → `commit-artifacts`, exactly one `Specs repo:` line. Close with a next-step offer naming `/docs-serve` and, once increment 2 lands, `/docs-audit` — carrying the `next-phase-offer` merge clause by discipline, since check 11 does not cover this family.

- [ ] **Step 8: Add the cost-emission §7 row and the specs-repo-git path shape**

`cost-emission.md` §7:

```
| `/docs-init` | docs-scaffold | dev |
```

`specs-repo-git.md` §2.1 gains a **fourth bounded path shape** (D19), for the documentation run that has no PRD and never will:

```
$SPECS_PATH/documentation/<docs-repo-slug>/dev-workflows/{cost,feedback}/
```

`<docs-repo-slug>` comes from the resolved docs repo's git remote, or its directory name. Per-repo rather than one flat bucket, because a person documenting two products must still be able to answer what documenting each one cost. **Staging stays enumeration-based; nothing else about the bookkeeping commit changes.** And the inner `dev-workflows/` directory is the live convention naming the *family*, not the plugin — do not "correct" it per-plugin; renaming it would fragment one repository's cost record across four directories.

Add no new branch prefix: this family creates no branch in `$SPECS_PATH`. Its deliverables live in the docs repo.

- [ ] **Step 9: Index, count, getting-started, and run the gates**

`docs/README.md` gains the command row and an "I want to…" row — *start documenting a project that has no docs* → `/docs-init`. The plugin README gains a **Docs** role row (spec §15.1). `docs/workflow.md`'s mermaid diagram gains `/docs-init` and `/docs-brand` in a `COLD["Cold start"]` subgraph feeding `SETUP`. `getting-started.md` gains a first-run path for a project with no docs repo — and it is the **one page allowed to name the marketplace** (check 7 pins its install block to the repo-root README verbatim; check 10 exempts only this page).

Counts: `Six slash commands`, `Four commands emit a cost entry`.

```bash
./scripts/validate-catalog.py --selftest && ./scripts/validate-catalog.py . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && ./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . \
  && ./plugins/workflows-core/scripts/session-cost.py --selftest
```

All seven green. This is the first task where the full set is worth running — `check-docs.sh --selftest` takes about two minutes.

- [ ] **Step 10: Commit**

```bash
git branch --show-current
git add -- plugins/docs-workflows/commands/docs-init.md \
           plugins/docs-workflows/docs/commands/docs-init.md \
           plugins/docs-workflows/docs/README.md \
           plugins/docs-workflows/docs/workflow.md \
           plugins/docs-workflows/docs/getting-started.md \
           plugins/docs-workflows/docs/reference/session-cost.md \
           plugins/docs-workflows/README.md \
           plugins/workflows-core/references/cost-emission.md \
           plugins/workflows-core/references/specs-repo-git.md
git commit -m "feat(docs-workflows): /docs-init — scaffold a docs repo that builds, serves and lints"
```

---

## Task 7: `/docs-profile` gains the `$DOCS_PATH` rung

The family cannot claim one docs-repo default while its own profiler ignores the variable. Small, separable, and the only change in this increment to a command that already shipped.

**Files:**
- Modify: `plugins/docs-workflows/commands/docs-profile.md` (Phase 0 step 1)
- Modify: `plugins/docs-workflows/docs/commands/docs-profile.md`
- Modify: `plugins/docs-workflows/docs/reference/environment.md`

**Interfaces:**
- Consumes: *resolve-docs-repo* from Task 1.
- Produces: nothing new. Behaviour changes only where cwd carries no docs signal and `$DOCS_PATH` does.

- [ ] **Step 1: Replace Phase 0 step 1's ladder with the shared entry point**

Today it reads *first token, else cwd*. It becomes: execute *resolve-docs-repo* from `${CLAUDE_PLUGIN_ROOT}/references/docs-workflow/repo-resolution.md`, keeping the `--inline` token handling exactly as it is — a `--inline` token in any position is the flag, never a path.

**Do not delete Phase 0 step 3's own signal check.** It asks the operator to confirm a repo with **zero** signals, which is a different question from resolution and is the branch that lets `/docs-profile` profile a repo the resolver would never have found. Removing it because "the resolver already tests signals" is exactly the shared-rule-inlining mistake `CLAUDE.md` records: itemise what the rule still says before assuming it is covered.

- [ ] **Step 2: Fix the retired-claim sentence while you are in this file**

`plugins/docs-workflows/commands/docs-profile.md` Phase 1 currently says *"Slash-command bodies cannot expand `${CLAUDE_PLUGIN_ROOT}` themselves, so the skill is what makes the policy text available."* That claim was **verified false in a live run** (spec §20 row 3; `CLAUDE.md` records the retirement). Replace it with the reason that survives: the skill is invoked because `model-routing` is a `workflows-core` skill and the classification file is a `workflows-core` reference, which this plugin cannot read by path.

- [ ] **Step 3: Update the two docs pages**

`docs/commands/docs-profile.md`'s prerequisites and resolution description, derived from the command file. `docs/reference/environment.md`'s `$DOCS_PATH` paragraph gains D23's two forms and names which commands take which.

- [ ] **Step 4: Run the gates and commit**

```bash
./scripts/check-docs.sh --root . && ./scripts/check-id-grammar.sh --root .
git branch --show-current
git add -- plugins/docs-workflows/commands/docs-profile.md \
           plugins/docs-workflows/docs/commands/docs-profile.md \
           plugins/docs-workflows/docs/reference/environment.md
git commit -m "fix(docs-profile): resolve through the shared docs-repo ladder, and retire a false claim"
```

---

## Task 8: Release — versions, changelogs, `CLAUDE.md`, marketplace

The documentation deliverable is part of the change, not a follow-up (spec §15). This task is the wave that makes the increment installable.

**Files:**
- Modify: `plugins/docs-workflows/.claude-plugin/plugin.json`, `plugins/workflows-core/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `plugins/docs-workflows/CHANGELOG.md`, `plugins/workflows-core/CHANGELOG.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Bump versions**

`docs-workflows` takes a **minor** bump — three new commands and one new agent are new capability, not a fix. `workflows-core` takes a **minor** bump too: `cost-emission` §7 gained rows and `specs-repo-git` §2.1 gained a path shape, both of which other plugins read. Re-derive the current values rather than assuming:

```bash
python3 -c "import json;[print(p, json.load(open(f'plugins/{p}/.claude-plugin/plugin.json'))['version']) for p in ['docs-workflows','workflows-core']]"
```

- [ ] **Step 2: Rewrite the `docs-workflows` description in both places**

The blurb is a **stable capability sentence, never a changelog**, and a new capability **replaces** wording rather than appending. Hard cap **1024 characters** in `plugin.json` and in the `marketplace.json` entry; `validate-catalog.py` warns above 900 and fails above 1024, and Copilot CLI rejects the **whole catalog** on one over-long blurb.

Edit `.claude-plugin/marketplace.json` **line-targeted** — do not reformat it; Claude Code parses that file.

```bash
python3 -c "
import json
for f,k in [('plugins/docs-workflows/.claude-plugin/plugin.json',None),('.claude-plugin/marketplace.json','docs-workflows')]:
    d=json.load(open(f))
    s=d['description'] if k is None else next(p['description'] for p in d['plugins'] if p['name']==k)
    print(f, len(s))
"
```

Both must be ≤ 1024, and they must **agree** — `validate-catalog.py` asserts that, and `claude plugin tag` asserts it again at release time.

- [ ] **Step 3: Write both changelogs**

One entry per plugin, naming the commands, the agent, the references, the two contract changes and D23/D24/D25 by decision id. `CHANGELOG.md` is excluded from `check-id-grammar.sh` and from check 13's vendor scan, so historical forms in it are fine.

- [ ] **Step 4: Update `CLAUDE.md`**

Nothing gates any number in this file, so re-derive every one you touch:

- the `docs-workflows` paragraph: three slash commands → six, seven subagents → eight, fourteen reference files → eighteen, and the new commands named;
- the **workflow map**: three new lines in the shape the existing entries use, plus `docs-scaffold-reviewer` in the agent list at the foot of the map;
- the **model-routing consumer list**: `/docs-init` and `/docs-brand` invoke the skill, so "Twenty-three commands" becomes twenty-five and the enumeration grows. `/docs-serve` does **not** — it is a utility, and the exempt list gains it;
- the **`specs-repo-git` consumer count**: `/docs-init` and `/docs-brand` run `commit-artifacts`, `/docs-serve` does not. Re-derive with `grep -l commit-artifacts plugins/*/commands/*.md | wc -l` and write what you counted;
- the **`docs-grounding` consumer list**: none of the three resolves docs grounding. `/docs-init` and `/docs-brand` read a *code* repo for branding and a *docs* repo as a write target; neither is grounding. Say so where the six non-consumers are already listed, so the next reader does not re-litigate it.

- [ ] **Step 5: Run every gate, twice — once clean, once after a deliberate break**

```bash
./scripts/validate-catalog.py --selftest && ./scripts/validate-catalog.py . \
  && ./scripts/check-id-grammar.sh --selftest && ./scripts/check-id-grammar.sh --root . \
  && ./scripts/check-docs.sh --selftest && ./scripts/check-docs.sh --root . \
  && ./plugins/workflows-core/scripts/session-cost.py --selftest \
  && echo ALL SEVEN GREEN
```

Then prove the docs gate is actually watching this increment's new content: delete `/docs-init` from `docs/workflow.md`'s mermaid diagram, confirm check 15 fails, and restore it. A gate that passes on a tree you never made fail is a gate you have not tested.

- [ ] **Step 6: Commit**

```bash
git branch --show-current
git add -- plugins/docs-workflows/.claude-plugin/plugin.json \
           plugins/workflows-core/.claude-plugin/plugin.json \
           .claude-plugin/marketplace.json \
           plugins/docs-workflows/CHANGELOG.md \
           plugins/workflows-core/CHANGELOG.md \
           CLAUDE.md
git commit -m "release(docs-workflows): the cold-start scaffold — /docs-init, /docs-brand, /docs-serve"
```

---

## Two decisions this plan makes that the spec left open

Both are named in spec §15 as things to settle rather than assume, so they are settled here rather than discovered mid-task.

**1. The family data-flow diagram (§15.3) draws only what exists.** Spec §15.1 puts the §4 diagram in the plugin README under a `## Documentation workflow` heading. That diagram has eight commands; increment 1 ships three. Drawing all eight now would put `/docs-write`, `/docs-capture`, `/docs-verify` and `/docs-drift` in a shipped README as though they were installable — a claim with an expiry date, which this repository has retired eleven of before. **Increment 1's README diagram shows `/docs-init → /docs-brand → /docs-serve` and the profile they produce, with one sentence saying the audit and iteration stages arrive next.** Increment 2 replaces it. `docs/reference/docs-coverage-model.md`, the diagram's third home, is increment 2's page and does not exist yet.

**2. The Docs role is recorded in `docs/workflow.md`, not in a new `roles-and-phases.md`.** Spec §15.2 states that page does not exist in `docs-workflows` — three plugins carry one and this is not among them — and names two ways out. Creating it means a new page check 3 requires be reachable from `docs/README.md`, for a role table with one row. `docs/workflow.md` already carries subgraph lane labels that do exactly this job (`SETUP["Anytime — setup utility"]`), so the Docs role lands there as a lane, at no cost in pages.

---

## Self-review

Run against the spec with fresh eyes, per the writing-plans checklist.

**1. Spec coverage.** Every Spec 1 section maps to a task or is explicitly increment 2's:

| Spec | Task | Spec | Task |
|---|---|---|---|
| §6 Phase 0 | 6.2 | §8.5 profile additions | 2.1–2.3 |
| §6 Phases 1–2 | 6.3 | §8.6 frontmatter | 2.4 |
| §6 Phase 3 tree | 1.4, 6.4 | §9 visibility | 1.3 |
| §6 Phase 4 Vale | 1.4, 6.4 | §10 `/docs-serve` | 4 |
| §6 Phase 5 branding | 6.5 | §13.1–13.2 | 1, 2 |
| §6 Phase 6 profile | 2, 6.5 | §13.3 gate impact | Global Constraints, 8 |
| §6 Phase 7 verify | 6.6 | §13.4 bookkeeping (D19) | 6.8 |
| §6 Phase 7.5 review | 3, 6.7 | §15.1 README | 4.4, 5.7, 6.9 |
| §6 Phase 8 finish | 6.7 | §15.2 docs pages | 1.6, 4.3, 5.7, 6.9 |
| §7 `/docs-brand` | 5 | §15.3 diagrams | decision 1 above |
| §8.4 images | 2.2 | §15.4 counts | Global Constraints, 8 |
| D23 | 1.5, 7 | D24 | 1.2, 5.4 |
| D25 | 3, 5.5, 6.7 | | |

Increment 2's, declared in Scope: §5, §8.1, §8.2, §8.3, §11, §14's route page. Spec 3's: `/docs-drift`, `drift-detector`. Contract-only: all of §12.

**2. Placeholder scan.** No "TBD", no "add appropriate error handling", no "similar to Task N". Every config the scaffold writes — `mkdocs.yml`, `mkdocs.internal.yml`, `.vale.ini`, the CI workflow, the CSS variables, the marker comment — appears in full in Task 1 or Task 5. The scaffold **tree** is cited to spec §6 Phase 3 rather than duplicated, which is deliberate and safe: the spec travels with this plan, the executor reads both, and a second copy of a forty-directory tree is a second thing to keep in step.

**3. Name consistency.** The resolver entry points are `resolve-docs-repo` and `resolve-scaffold-target` in Task 1, Task 4, Task 6 and Task 7 alike. The agent is `docs-scaffold-reviewer` in Tasks 3, 5 and 6. The reference paths are `references/docs-workflow/{scaffold-tree,visibility,contrast,repo-resolution}.md` throughout. The profile keys are `generator`, `builds[]`, `dev_servers.{servers,readiness_timeout_seconds}` and `images.{policy,root,max_bytes,public_prefix,internal_prefix}` in Tasks 2, 4, 5 and 6.

**4. Count arithmetic, re-derived rather than carried.** Commands 3 → 4 (Task 4) → 5 (Task 5) → 6 (Task 6). Agents 7 → 8 (Task 3). Reference files 14 → 18 (Task 1). Cost-emitting 2 → 3 (Task 5) → 4 (Task 6). Every task that moves a count fixes its sentence in the same task, so the gates are green at every commit — which is what makes the task boundaries real rather than decorative.

---

## Follow-ups this increment deliberately does not take

- **`/document` Phase 0's ladder is not refactored onto `repo-resolution.md`.** It is the existing implementation the new file is derived *from*, and rewiring a 1640-line command that four gates cover is a change with its own risk profile. Worth doing; not here. Until then two implementations of one ladder exist, and `repo-resolution.md` §1 says so rather than pretending otherwise.
- **Check 11 is not widened to the `/docs-*` family.** `CLAUDE.md` records that widening it was measured and refused twice, and this family's offers carry the merge clause by discipline. Re-test the conclusion when `next-phase-offer`'s scope paragraph gains a glob — do not re-propose it without new evidence.
- **`eleven` is not taught to check 9's agent alternation.** Increment 2 needs it and owes the fixture-growing selftest case that proves the word *converts*; adding it here would ship an untested gate widening for a count nothing yet reaches.
- **`git-lfs` is named in the profile, never scaffolded** (spec §8.4). A project can adopt it and the profile records that it did.
