---
name: dynatrace-docs-frontmatter
description: Apply dynatrace-docs frontmatter conventions — changelog entries and managed-docs owners — when creating or editing documentation pages under dynatrace/_content/** or managed/_content/** in the dynatrace-docs repository. Use whenever you change a Dynatrace documentation page's content or frontmatter, or when the user mentions changelog, page owners, or dynatrace-docs frontmatter.
user-invocable: true
allowed-tools: Read, Edit, Glob, Grep, Bash
---

# dynatrace-docs frontmatter conventions

Apply when creating or editing `.md` pages under `dynatrace/_content/**` or
`managed/_content/**` in the `dynatrace-docs` repo. Three conventions, all in the
page's YAML frontmatter, applied in the same pass: changelog entries, managed-docs
owners, and the core metadata fields.

## 1. Changelog (changed existing pages only)

For every **changed existing** page (NOT brand-new pages — first publish uses the
`published` timestamp instead), prepend a `changelog:` entry dated **today**:

1. Get today's date: run `date +%F` (yields `YYYY-MM-DD`, two-digit month).
2. Prepend the entry as the **first** list item under `changelog:` (newest first):
   ```yaml
   changelog:
     - <today> <change description>
     - <older entries unchanged>
   ```
3. Keep each entry — including the leading `- ` and date — within **200 characters**.
4. Write the description per the guidelines reference. The most-missed rule:
   **the period rule — verify before finalizing each entry:**
   - complete sentence → **ends with a period**;
   - phrase / fragment → **no period**.
   Also: past tense; active verbs; meaningful and customer-facing; no "documented";
   don't overuse "added"; no section titles; never expose "hidden"; no short forms
   ("info", "max"); single paragraph.

Full rules and worked examples (source of truth):
`${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/changelog-guidelines.md`

## 2. Owners (changed managed pages only)

For changed pages under `managed/_content/**` that have — or should have — an
`owners:` block, ensure every required ID is present. **Union only — never remove
existing owners.**

1. Read the required IDs (ignore `#` comments and blank lines):
   `${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/managed-owners.txt`
2. If the page has no `owners:` block but one is warranted (most managed pages
   carry owners), add one containing the required IDs.
3. If an `owners:` block exists, add any required IDs that are missing and leave
   all existing owners in place.

Pages under `dynatrace/_content/**` (SaaS) are out of scope for the owners rule.

## 3. Metadata fields (all pages)

Set/validate the core frontmatter fields per the guidelines reference:

- `title` — required; sentence case; no trailing period.
- `description` — required; **120–160 characters** (SEO). Warn if outside the band.
- `meta.content-type` — **mandatory on new pages**; one of the enum
  (`how-to`, `tutorial`, `explanation`, `reference`, `get-started`,
  `troubleshooting`, `upgrade`, `best-practices`, `app`, `extension`).
  **Never `overview`** (deprecated); `release-notes` pages are automation-generated,
  not authored here.
- `meta.i18n-priority` — optional number (lower = higher priority).
- `meta.generation` — `latest` / `classic` array (advisory; a `latest`-only page
  that surfaces in Managed breaks the build — use both when unsure).
- `published` — creation date on new pages only; never pair it with a first-publish
  changelog entry.

Detect which optional fields the neighbourhood uses by sampling 2–3 adjacent pages;
never strip unknown/pre-existing fields.

Full field rules (source of truth):
`${CLAUDE_PLUGIN_ROOT}/references/dynatrace-docs/frontmatter-guidelines.md`

## Notes

- A warn-only `PostToolUse` hook (`changelog-owners-reminder`) reminds about these
  same checks if this skill did not fire; applying the conventions here keeps it
  silent.
- This does not duplicate the repo's CI (`pnpm dynatrace:lint`); it gets the
  frontmatter right at edit time so the PR is not bounced later.
