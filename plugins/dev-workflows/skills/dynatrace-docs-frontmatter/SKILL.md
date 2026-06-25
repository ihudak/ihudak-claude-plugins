---
name: dynatrace-docs-frontmatter
description: Apply dynatrace-docs frontmatter conventions — changelog entries and managed-docs owners — when creating or editing documentation pages under dynatrace/_content/** or managed/_content/** in the dynatrace-docs repository. Use whenever you change a Dynatrace documentation page's content or frontmatter, or when the user mentions changelog, page owners, or dynatrace-docs frontmatter.
user-invocable: true
allowed-tools: Read, Edit, Glob, Grep, Bash
---

# dynatrace-docs frontmatter conventions

Apply when creating or editing `.md` pages under `dynatrace/_content/**` or
`managed/_content/**` in the `dynatrace-docs` repo. Two conventions, both in the
page's YAML frontmatter, applied in the same pass.

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

## Notes

- A warn-only `PostToolUse` hook (`changelog-owners-reminder`) reminds about these
  same checks if this skill did not fire; applying the conventions here keeps it
  silent.
- This does not duplicate the repo's CI (`pnpm dynatrace:lint`); it gets the
  frontmatter right at edit time so the PR is not bounced later.
