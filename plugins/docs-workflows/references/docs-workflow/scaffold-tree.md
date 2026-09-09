# The scaffold — tree, stubs, nav, and configs

Single source of truth for **what `/docs-init` creates**. It is an executable template, not a description of one: a command reads it to know which directories and files to write, what goes in each, and what the two build configs and the linter config contain.

Consumed by `/docs-init` (Phase 3 writes §1–§4, Phase 4 writes §7) and by `docs-scaffold-reviewer`, whose checklist asserts relationships between the files this file specifies. `/docs-write` reads §4, because it regenerates the same `nav:` on every write.

Its entry points, so a command can say which part it is executing: **the tree** (§1), **the stubs** (§3), **nav generation** (§4), **the mkdocs configs** (§5 and §6), and **the vale config** (§7).

The navigation is **product-shaped** (design D15). Diátaxis lives in each page's `type:` frontmatter, which is what the coverage grid reads — so the tree looks like a documentation portal a reader recognises while the quadrant discipline stays fully intact.

---

## 1. The tree

```
mkdocs.yml                  # public build; strict: true; exclude_docs drops internal/
mkdocs.internal.yml         # INHERIT: mkdocs.yml + internal nav, builds everything
.vale.ini
docs/
  index.md                             # portal home
  discover/                            # "Discover <product>"
    index.md                           #   What is <product>          type: explanation
    how-it-works.md                    #   the mental model
    use-cases.md
    roles.md                           #   who does what             ← the role surface
    glossary.md                        #   terms, roles, integrations, primary workflows
    pricing.md                         #   optional: --with-pricing
    accessibility.md                   #   optional: --with-compliance
    security.md                        #   optional: --with-compliance
  get-started/
    index.md                           #   quickstart                 type: tutorial
    requirements.md
    install.md
  guides/                              # task-oriented                type: how-to
  reference/                           #                              type: reference
    api/
    configuration.md
    cli.md
    data-model.md
    limits.md                          #   limits and quotas
    errors.md                          #   error codes
  integrations/                        # optional
  administration/                      # users and roles, security, SSO, billing
  troubleshooting/
    index.md
    faq.md
    known-issues.md
  whats-new/
    index.md                           #   release-notes hub
    v<MAJOR>/
      index.md                         #   the major release
      maintenance.md                   #   per-build fixes in that major
    deprecations.md                    #   end-of-life and end-of-support
  support.md
  internal/                            # engineering docs; excluded from the public build
    architecture/
    decisions/
    runbooks/
  _snippets/                           # pymdownx.snippets base_path
  assets/                              # logo, favicon, images
  stylesheets/extra.css
.dev-workflows/
  docs-profile.yml
.github/workflows/docs.yml             # build both, lint, and the two visibility gates
```

Three of these are conditional. `integrations/` is written when the run has integrations to document — the source-repo set resolved in Phase 2 is what answers that, not a flag. `pricing.md` is written under `--with-pricing`. `accessibility.md` and `security.md` are written under `--with-compliance`. Everything else is unconditional: a portal missing one of the §2 sections is missing it, not customised.

**"What's new" is fed, not written by hand.** `/docs-audit` enumerates a `release` surface per major version from the `/release-notes` drafts already sitting in `$SPECS_PATH`, and `/docs-write` renders the page from them. `references/release-note-types.md` supplies the section split inside each page — breaking changes, feature updates, fixes — because that reference already owns the destination map and the per-destination prose shape. Nothing is re-derived here.

---

## 2. Why each section

The sections a reader would predict need no defence. These nine do, and each is standard rather than decoration — every one of them is a page a real portal has and a new portal forgets.

| Section | Why every portal has it |
|---|---|
| **Glossary** | The highest-leverage page in a new portal: it is what lets every other page stop re-explaining terms. It also seeds the Vale vocabulary (§7), so product nouns stop being reported as misspellings. |
| **Roles** | A reader's first question is which of these instructions are for them. It is also this family's coverage dimension, so the page and the grid read the same list. |
| **Troubleshooting / FAQ / Known issues** | The highest-traffic pages on most portals, and the main support-deflection surface. Absent, the traffic arrives as tickets instead. |
| **Limits and quotas** | Routinely the single most-visited reference page, and the one most often missing. An evaluator looks for it before they look at features. |
| **Error codes** | The only page a reader arrives at by pasting a string out of a log. Nothing else in the portal serves that entry path. |
| **Administration** | Role-gated tasks that do not belong in user guides, and the first thing an evaluator opens to judge whether the product is operable. |
| **Deprecations / end-of-life** | Pairs with What's new. `references/release-note-types.md` already requires an end-of-life date on every deprecation note, so the destination has to exist. |
| **Support** | How to reach a human. Every other page implicitly promises this escape hatch; the portal has to keep the promise. |
| **Accessibility and security statements** | Increasingly a procurement requirement. Scaffolded as stubs under `discover/` when `--with-compliance` is passed. |

---

## 3. Stubs

**Each directory gets one stub that states what belongs there and what does not**, carrying the section's default `type:` in its frontmatter. The stub is that directory's own `index.md`. §1's tree names an `index.md` only where the spec had something to say about its content; every other directory in the tree gets one from this section, and the three in §3.13 get none at all.

This is not filler. The commonest failure of a documentation tree is contributors putting explanation into how-to guides — a guide that starts with four paragraphs of background, a reference page that becomes a tutorial, a concept page that grows numbered steps. The stub is where that is prevented, at the moment someone opens the directory to add a page. A convention stated only in a style guide nobody opens is not a convention; a convention stated in the file you are about to edit is.

Every stub carries six frontmatter fields — `title`, `description`, `type`, `audience`, `visibility`, `order`. The full page contract is larger (`references/docs-profiles/frontmatter-guidelines.md` and the `docs-frontmatter` skill own it); a stub carries the six that decide where the page sits, who it is for, and which build it lands in, and the writer fills the rest when the page stops being a stub.

**Every file under `internal/` carries the visibility marker** as its first line after the frontmatter — see `visibility.md` §5. The stubs below show it. A stub written without it is the exact file the gate cannot see.

### 3.1 Portal home

`docs/index.md`

```markdown
---
title: <product> documentation
description: Everything published about <product>, by what you are trying to do.
type: explanation
audience: user
visibility: public
order: 1
---

Start here. This page routes to the rest of the portal: what <product> is, how to get it running, how to do a specific task, and where the exact values live.

**What belongs here:** signposting — one short paragraph per section, naming who each is for. Nothing else.

**What does not:** product explanation (that is `discover/`), installation steps (`get-started/`), or anything a reader would need to scroll to reach. A home page that has to be read is a home page nobody reads.
```

### 3.2 `discover/`

`docs/discover/index.md`

```markdown
---
title: What is <product>
description: What <product> does, who it is for, and the model behind it.
type: explanation
audience: user
visibility: public
order: 1
---

The concept layer. Pages here answer *what is this and why is it shaped like this* for someone who has not decided to use the product yet.

**What belongs here:** the product's purpose, its mental model, the vocabulary the rest of the portal uses, the roles it recognises, and the shapes of problem it solves.

**What does not:** instructions. The moment a page here acquires a numbered list of steps, it belongs in `get-started/` or `guides/`. Explanation earns its place by being readable in any order; steps do not.
```

### 3.3 `get-started/`

`docs/get-started/index.md`

```markdown
---
title: Get started
description: Install <product> and reach a first working result.
type: tutorial
audience: user
visibility: public
order: 1
---

The one guaranteed path from nothing to a working result. A reader following this page in order arrives somewhere real, without deciding anything.

**What belongs here:** prerequisites, installation, and a single end-to-end first run with a stated outcome.

**What does not:** alternatives, options, and platform variants. A tutorial that branches has stopped being a tutorial; branches belong in `guides/`, values belong in `reference/`. If a step needs a caveat, the caveat links out rather than opening a fork in the path.
```

### 3.4 `guides/`

`docs/guides/index.md`

```markdown
---
title: Guides
description: Task-oriented instructions for the things people do with <product>.
type: how-to
audience: user
visibility: public
order: 1
---

One page per task, each named for the task in the reader's words — *Import a customer list*, not *The import subsystem*.

**What belongs here:** a stated goal, the prerequisites for it, the steps, and how to tell it worked.

**What does not:** background. A guide's reader has already decided to do the thing; explaining why it exists costs them the top of the page. Link to `discover/` for the why, and to `reference/` for the exact values, and keep the steps unbroken.
```

### 3.5 `reference/`

`docs/reference/index.md`

```markdown
---
title: Reference
description: Exact values — configuration, CLI, data model, limits, errors.
type: reference
audience: user
visibility: public
order: 1
---

The lookup layer. A reader arrives here knowing what they want and needing its exact name, type, default, or value.

**What belongs here:** complete, structured, scannable statements of fact — tables, parameter lists, enumerations, error codes. Consistency of shape matters more than prose quality.

**What does not:** narrative and advice. A reference page that explains when to use an option has become an explanation with a table in it, and the table is now harder to scan. Put the recommendation in a guide and link it.
```

### 3.6 `reference/api/`

`docs/reference/api/index.md`

```markdown
---
title: API reference
description: Endpoints, request and response shapes, authentication, and errors.
type: reference
audience: user
visibility: public
order: 10
---

The HTTP (or equivalent) surface, one page per resource or generated from a schema.

**What belongs here:** endpoints with their methods, parameters, request and response bodies, status codes, and auth requirements — every one of them derived from the shipped source or spec, never from memory.

**What does not:** integration tutorials and client walkthroughs. Those are `guides/`. This directory is also the one most likely to be generated; a hand-written page that duplicates a generated one is a page that will disagree with the API within a release.
```

### 3.7 `integrations/`

`docs/integrations/index.md`

```markdown
---
title: Integrations
description: How <product> connects to the other systems it works with.
type: how-to
audience: user
visibility: public
order: 1
---

One page per integrated system, each covering what the connection does, what it needs, and how to set it up.

**What belongs here:** the third-party prerequisites, the credentials and permissions required, the setup steps, and what breaks when the connection is wrong.

**What does not:** documentation of the third-party product itself. Link to their docs and keep this page about the seam. A page that re-explains someone else's console is a page that goes stale on their release schedule, not yours.
```

### 3.8 `administration/`

`docs/administration/index.md`

```markdown
---
title: Administration
description: Managing users, roles, security, and billing for <product>.
type: how-to
audience: user
visibility: public
order: 1
---

Tasks that require elevated permissions: user and role management, authentication and SSO, security settings, quotas, and billing.

**What belongs here:** anything a reader without an admin role cannot do, kept separate precisely so ordinary guides do not send readers into a wall.

**What does not:** engineering operations. A runbook for the team that operates the service is `internal/runbooks/`; this section is for the customer's own administrator. The test is whose console the reader is in.
```

### 3.9 `troubleshooting/`

`docs/troubleshooting/index.md`

```markdown
---
title: Troubleshooting
description: Symptoms, causes, and fixes — plus the FAQ and known issues.
type: how-to
audience: user
visibility: public
order: 1
---

Organised by **symptom**, in the words a reader would use before they know the cause: what they saw, what it means, what to do.

**What belongs here:** symptom-first entries, the FAQ, and the current known-issues list with its status and workaround.

**What does not:** error-code tables — those are `reference/errors.md`, because a reader pasting a code wants a lookup, not a narrative. Nor does anything organised by subsystem: a reader who knew which subsystem failed would not be here.
```

### 3.10 `whats-new/`

`docs/whats-new/index.md`

```markdown
---
title: What's new
description: Releases, what changed in each, and what is being retired.
type: reference
audience: user
visibility: public
order: 1
---

The release hub: one entry per major version, newest first, plus the deprecations page.

**What belongs here:** links to the per-major pages and the deprecation schedule. Nothing that has to be edited when a release ships — the per-major pages carry that.

**What does not:** hand-written release prose. These pages are rendered from the release-notes drafts the pipeline already produced; writing them by hand creates a second source of truth that disagrees with the first by the following release.
```

`docs/whats-new/v<MAJOR>/index.md`

```markdown
---
title: v<MAJOR>
description: What changed in <product> v<MAJOR>.
type: reference
audience: user
visibility: public
order: 1
---

One major version. Sections follow `references/release-note-types.md`: breaking changes, feature updates, fixes.

**What belongs here:** the changes shipped in this major, in that section order, each one rendered from its release-notes draft.

**What does not:** migration tutorials. A breaking change names its remediation in a sentence and links a guide; the guide lives in `guides/`, where it can be found by someone who is not reading release notes.
```

### 3.11 `internal/`

`docs/internal/index.md`

```markdown
---
title: Internal documentation
description: Engineering documentation for the team that builds and runs <product>.
type: explanation
audience: engineering
visibility: internal
order: 1
---
<!-- docs-visibility: internal -->

Everything in this tree is excluded from the public build. It is for the people who build and operate the product.

**What belongs here:** architecture, decision records, and runbooks — plus anything that names internal hostnames, internal tooling, or unreleased work.

**What does not:** anything a customer should be able to read. A page that is merely technical is not internal; API reference is engineering-shaped and public. The test is whether publishing it would be wrong, not whether it is advanced. Every file here carries the visibility marker on its first line after the frontmatter.
```

`docs/internal/architecture/index.md`

```markdown
---
title: Architecture
description: How <product> is built — components, boundaries, and data flow.
type: explanation
audience: engineering
visibility: internal
order: 1
---
<!-- docs-visibility: internal -->

The system as it is today: components, the boundaries between them, what crosses each boundary, and where state lives.

**What belongs here:** structure and rationale that a new engineer needs before reading code, with a diagram wherever a diagram is what is actually being described.

**What does not:** decisions and their alternatives — those are `internal/decisions/`, where they can be dated and superseded. An architecture page that carries its own history stops describing the present.
```

`docs/internal/decisions/index.md`

```markdown
---
title: Decision records
description: Decisions taken about <product>, with their context and consequences.
type: explanation
audience: engineering
visibility: internal
order: 1
---
<!-- docs-visibility: internal -->

One page per decision, dated, stating the context, the decision, the alternatives considered, and the consequences.

**What belongs here:** decisions that constrain later work, including the ones that were reversed — a superseded record is marked superseded and kept, never deleted.

**What does not:** the current state of the system. That is `internal/architecture/`. A decision record is a record of a moment; editing it to match today destroys the only thing it was for.
```

`docs/internal/runbooks/index.md`

```markdown
---
title: Runbooks
description: What to do when something breaks or has to be operated.
type: how-to
audience: engineering
visibility: internal
order: 1
---
<!-- docs-visibility: internal -->

Operational procedures, written to be followed at three in the morning by someone who did not write them.

**What belongs here:** the trigger, the checks, the steps, the rollback, and who to escalate to — each step executable without judgement calls the reader cannot make under pressure.

**What does not:** explanation of why the system works this way. Link it. A runbook whose first screen is background is a runbook nobody reaches the steps of.
```

### 3.12 The named leaf pages

The tree names individual pages inside four sections. Each is created as a stub too, in the same shape as the directory stubs — six frontmatter fields, a "what belongs here", a "what does not" — with the `type:` and `order:` below. The directory stub's `type:` is the section default; a leaf listed here that differs from its section is a deliberate exception, not an oversight.

| Page | `type:` | `order:` | What belongs on it |
|---|---|---|---|
| `discover/how-it-works.md` | explanation | 20 | The mental model: the pieces, how they relate, what the product does on your behalf. |
| `discover/use-cases.md` | explanation | 30 | The shapes of problem the product is for, each with who has it. |
| `discover/roles.md` | explanation | 40 | Every role the product recognises and what each can do. The coverage grid reads this list. |
| `discover/glossary.md` | reference | 50 | Every term, role, integration and workflow name the portal uses, defined once. |
| `discover/pricing.md` | reference | 60 | Plans, what each includes, and what is metered. `--with-pricing` only. |
| `discover/accessibility.md` | explanation | 70 | The accessibility conformance statement. `--with-compliance` only. |
| `discover/security.md` | explanation | 80 | The security posture statement. `--with-compliance` only. |
| `get-started/requirements.md` | reference | 20 | Supported platforms, versions, and the resources a working install needs. |
| `get-started/install.md` | how-to | 30 | Installation, per supported platform, ending in a verification step. |
| `reference/configuration.md` | reference | 20 | Every setting: name, type, default, effect, and where it is set. |
| `reference/cli.md` | reference | 30 | Every command, its flags, its arguments, and its exit codes. |
| `reference/data-model.md` | reference | 40 | The entities, their fields, and the relationships between them. |
| `reference/limits.md` | reference | 50 | Limits and quotas, with the value, the scope, and whether it is raisable. |
| `reference/errors.md` | reference | 60 | Every error code, what causes it, and what to do about it. |
| `troubleshooting/faq.md` | how-to | 20 | Questions in the reader's words, each with a short answer that links out. |
| `troubleshooting/known-issues.md` | reference | 30 | Current defects with status and workaround; entries are removed when fixed. |
| `whats-new/v<MAJOR>/maintenance.md` | reference | 20 | Per-build fixes within that major, newest first. |
| `whats-new/deprecations.md` | reference | 90 | Every deprecation with its end-of-life date, and its end-of-support date when set. |
| `support.md` | how-to | 90 | How to reach a human, what to include, and what response to expect. |

### 3.13 The three directories that get no stub

`_snippets/`, `assets/` and `stylesheets/` hold no pages, and a page stub in any of them would be **built into the site** — `exclude_docs` drops `internal/` and nothing else (§5), so a stub under `docs/_snippets/` would render as a public page and `validation.nav.omitted_files` would report it as omitted from the nav.

So their convention is stated here rather than in a file that ships:

- **`_snippets/`** — reusable Markdown fragments included with `pymdownx.snippets`. A fragment intended for internal pages carries the visibility marker (`visibility.md` §5); this is the file the snippet leak travels in, and nothing else marks it. No fragment carries frontmatter — it is inlined into a page that has its own.
- **`assets/`** — the logo, the favicon, and images, under `images.root` when the profile's `images.policy` is `in-repo`. One path per slot: a replacement overwrites, and never lands beside the old file under a new name. An image only internal pages may see does **not** go here — it goes under `internal/`, because `exclude_docs` drops files rather than only Markdown, and everything in `assets/` is copied into both builds whether a public page references it or not (`visibility.md` §4).
- **`stylesheets/`** — `extra.css` and nothing else unless the brand needs it. `/docs-brand` writes here; hand edits are what a rebrand then has to reconcile.

---

## 4. `nav:` generation

**`nav:` is generated, never hand-maintained.**

MkDocs takes navigation order from `mkdocs.yml`, not from frontmatter, so a page's `order:` field would otherwise be decorative — present, plausible, and read by nothing. Generating the block is what makes the field real.

The rule: **sort each section's pages on frontmatter `order`, then on `title`.** Ties break on title so the result is stable rather than filesystem-ordered, and a page with no `order:` sorts after every page that has one.

Regenerated on every write, by `/docs-init` when it scaffolds and by `/docs-write` when it adds or renames a page. One source of truth, no extra plugin, and no state that can drift: the block is derived from the tree each time rather than edited.

Both configs' `nav:` blocks are generated. The internal one is the public nav plus the `internal/` sections, in the same order by the same rule.

A hand-edit to a generated `nav:` survives until the next write and then vanishes, which is worse than being rejected. The block therefore carries the comment shown in §5 and §6, so the next person to open the file is told before they edit rather than after.

---

## 5. `mkdocs.yml`

The public build.

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

`strict: true` plus the `validation.nav.*` settings are gate 1 (`visibility.md` §4): a public page linking into `internal/` becomes a build failure rather than a broken link a reader finds. Dropping either one retires that gate while the CI step still appears to run.

---

## 6. `mkdocs.internal.yml`

The internal build.

```yaml
INHERIT: mkdocs.yml
site_name: <product> (internal)
exclude_docs: ""
nav:
  # generated — the public nav plus the internal/ sections; see §4
```

**`exclude_docs: ""` is the whole of the difference between the two builds**, and stating it here is what makes the reviewer's second checklist item checkable. A second `nav:` **source**, a different `markdown_extensions` list, or a divergent `theme` block in the internal config is a **defect, not a customisation** — two configs that differ in more than the exclusion are two sites, and the shared snippets, shared search index and working cross-links that the one-tree model buys are gone.

The generated `nav:` differs, of course; that is §4 running over a larger file set, not a second source of truth.

---

## 7. `.vale.ini` and the vocabulary

Vale is the deterministic pre-lint the family's existing style gate already knows how to run — `docs-style-checker` runs a repo's `.vale.ini` as its primary rung — so writing this file lights up an existing gate with no new wiring.

```ini
StylesPath = styles
MinAlertLevel = suggestion
Packages = Google, write-good
Vocab = Project

[*.md]
BasedOnStyles = Vale, Google, write-good
```

`Packages` load in order, with later entries overriding earlier ones, so a project package added later can override Google's rules without editing them.

After writing the file, run **`vale sync`** to download the packages. A `.vale.ini` naming a package that was never synced fails at the first lint, which the scaffold's own verification phase surfaces immediately rather than leaving for the first contributor.

### The vocabulary is seeded, not left empty

`styles/config/vocabularies/Project/accept.txt` holds the product's own terms — one per line, regex-escaped — so Vale stops reporting them as misspellings.

**Seeding it is not a nicety.** Without it every product noun is a spelling error on day one, the first lint returns dozens of findings that are all wrong, and the team turns Vale off in week two. A linter that cried wolf once is a linter nobody re-enables.

`/docs-audit` extracts the domain nouns for its `concept` surfaces, and those are what seed the file. **`/docs-audit` does not exist until increment 2**, so in this increment the file is always created carrying exactly this comment and nothing else:

```
# Product terms Vale should not flag as misspellings.
# /docs-workflows:docs-audit seeds this from the domain nouns it extracts for
# `concept` surfaces. Until then, add terms by hand — one per line, regex-escaped.
```

The file is created either way. An absent `accept.txt` beside a `Vocab = Project` line is a configuration error; an empty one with a comment is a working configuration and an invitation.

---

## 8. Hard rules

- NEVER hand-edit a generated `nav:`. Change `order:` or `title:` and regenerate (§4).
- NEVER let the two configs differ by anything but `exclude_docs` and the generated `nav:` (§6).
- NEVER write a directory without its stub, and never write a stub without its "what does not belong" half (§3).
- NEVER write a file under `internal/` without the visibility marker on its first line after the frontmatter (`visibility.md` §5).
- NEVER put a page stub in `_snippets/`, `assets/` or `stylesheets/` (§3.13).
- NEVER create `.vale.ini` without also creating `accept.txt` (§7).
