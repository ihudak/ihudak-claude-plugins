# example-docs frontmatter fields — writing guidelines

Single source of truth for the **frontmatter metadata fields** on example-docs
pages. Companion to
[`changelog-guidelines.md`](changelog-guidelines.md) (the `changelog:` property)
and [`default-owners.txt`](default-owners.txt) (the `owners:` block) — those two
conventions are documented separately and only cross-linked here.

Applied by the `docs-frontmatter` skill and the `/document` docs
pipeline (`doc-planner` plans, `doc-writer` writes, `doc-reviewer` checks) **only
under the example-docs profile** — a generic docs repo is unaffected.

## Fields

### `title` (required)

Concise, sentence-case page title. No trailing period.

### `description` (required — SEO)

The search-result / social-preview snippet. **120–160 characters.** Shorter
under-describes the page for SEO; longer is truncated in results. A description
outside this band is a **warning**, not a hard block.

### `meta.content-type` (mandatory)

Mandatory metadata on every new page; visible in the page header. Implements the
Diátaxis content model extended with product-specific types. One of:

| Value | Use |
|---|---|
| `how-to` | Task/goal-oriented "how-to guide" |
| `tutorial` | Learning-oriented, step-by-step |
| `explanation` | Concept / background |
| `reference` | Options, flags, schema fields, API |
| `get-started` | Getting-started guide |
| `troubleshooting` | Problem/resolution |
| `upgrade` | Upgrade guide |
| `best-practices` | Best-practices guide |
| `app` | An app's documentation |
| `extension` | An extension's documentation |
| `release-notes` | Release-notes pages — **generated from Jira by docs automation, never authored by `/document`**; listed for completeness only |

- **`overview` is deprecated — never set it on new content.**
- A missing or invalid `content-type` on a **new** page is a **BLOCKER** at review.

### `meta.i18n-priority` (optional)

An integer translation-priority signal (lower = higher priority). Advisory —
set it when the page's translation priority is known; otherwise omit.

### `meta.generation` (advisory)

Array of `latest` / `classic` (both experiences → `[classic, latest]`). Governs
which product experience the page applies to. **Build caveat:** a page tagged
`latest`-only that also surfaces in the Self-hosted docs breaks the build — when in
doubt for cross-experience/deployment/API/CLI content, use both. Advisory here;
match the convention on adjacent pages.

### `published` (new pages only)

Creation date (`YYYY-MM-DD`) on brand-new pages. Do **not** add a `changelog:`
entry on first publish — the `published` timestamp is used instead (see
[`changelog-guidelines.md`](changelog-guidelines.md)).

## Detecting conventions

Field presence and shape vary by area. Sample 2–3 adjacent pages under the
target's directory to confirm which optional fields (`tags`, `readtime`,
`solution`, `core-technology`, `app-id`, …) the neighbourhood uses, and match
them. **Never strip unknown/pre-existing frontmatter fields** — union, don't
replace.

## Enforcement summary (doc-reviewer)

| Field | Severity when wrong/absent |
|---|---|
| `meta.content-type` (new page) | **BLOCKER** — missing or not in the enum |
| `description` | **warning** (MAJOR/MINOR) — outside 120–160 chars |
| `title` (new page) | MAJOR — missing |
| `meta.i18n-priority`, `meta.generation` | advisory note only |
