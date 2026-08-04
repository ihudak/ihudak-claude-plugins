---
tags:
  - tasks-exclude
---

# `.obsidian` vault-check revisit — Design (dev-workflows v2.20.0)

**Status:** Shipped in dev-workflows v2.20.0 — pre-implementation design snapshot, kept as authored.
**Date:** 2026-07-10
**Repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`
**Version:** 2.19.0 → 2.20.0 (behavior change: loosen a write-gate; no new command/subagent)

## Goal

Replace the `.obsidian/`-directory **proxy** — used as a "this is the user's personal store"
gate before writing vault artifacts — with a check that trusts `$VAULT_PATH` itself, while
preserving the "never write to the wrong place" guard. The `.obsidian/` marker is
Obsidian-specific and over-strict: it rejects legitimate non-Obsidian personal stores (plain
markdown notes dirs, or a vault whose `.obsidian/` isn't present) for no real safety gain.

## Key finding (motivation)

**Most of the plugin already trusts `$VAULT_PATH` on "set" alone** — `release-notes.md`
(`$VAULT_PATH` set → resolve the project folder), `epics.md` ("an Obsidian vault when
`$VAULT_PATH` is set"), and `/document`'s screenshot staging all key off `$VAULT_PATH` being
set and never check `.obsidian/`. The four write-gates that DO require `.obsidian/` are the
**outliers**. Dropping the requirement makes the whole plugin consistent rather than
introducing a new convention.

## The change

At each of the 4 category-A write-gates, replace:

> `$VAULT_PATH` set **and** `$VAULT_PATH/.obsidian/` is a directory **and** writable

with:

> `$VAULT_PATH` set **and** is an existing directory **and** writable

## Guard preservation ("never write to the wrong place")

The guard still holds through four unchanged mechanisms:

1. `$VAULT_PATH` must be **set** — an explicit, deliberate user declaration (an env var, not an
   accidental cwd).
2. It must be an **existing, writable directory** — a stale/bogus path fails the check.
3. Writes always land in a **namespaced subdir** (`$VAULT_PATH/dev-workflows/…`,
   `$VAULT_PATH/Projects/…`) — never scattered at the vault root.
4. The standing **NEVER write into the current working directory** rule in every ladder is
   untouched (cwd may be a code repo).

We drop only the Obsidian-specific belt-and-suspenders, which the rest of the plugin never
applied anyway.

## Scope

**In scope — Category A (the 4 personal-store write-gates):**

- `commands/idea.md` — Phase 0 `$VAULT_PATH` validation (interactive; falls through to
  enter-a-directory / cancel).
- `references/feedback-emission.md` — tier 3 (vault as fallback when `$SPECS_PATH`
  unavailable). Silent.
- `references/cost-emission.md` — tier 3 (reuses the feedback ladder). Silent.
- `references/followup-emission.md` — §4 `vault_writable` (vault as primary target). Has a
  batch-preview gate.

**Out of scope (unchanged):**

- **Category B** — `commands/document.md` line 89: `.obsidian/` walk-up is a *defensive*
  guard that FORBIDS branch/commit (opposite polarity — a correct positive signal used to
  refuse git operations, not a write-gate).
- **Category C** — `references/followup-emission.md` line 27: reads `#tags` from
  `$VAULT_PATH/.obsidian/copilot/tag-index.md` — a genuine Obsidian-plugin path, not a proxy
  (no non-Obsidian equivalent).
- Descriptive prose elsewhere that says "the user's Obsidian vault" (release-notes, document,
  epics) — accurate for the common case; renaming is cosmetic scope-creep.
- **README** — never documented the `.obsidian/` gate, so no change.
- **No new SSOT reference** — the check is now a trivial one-liner already used elsewhere in
  the plugin (YAGNI).

## Per-file changes (7 files)

1. **`commands/idea.md`** (Phase 0, step 1) — drop the "look like the user's personal store
   (`$VAULT_PATH/.obsidian/` is a directory — the same marker the specs-first ladder uses)"
   clause. New wording: "It must be **set**, an **existing directory**, and **writable**." Keep
   the enter-a-directory / cancel fallback, the NEVER-cwd note, and the "this is an environment
   halt, not a plugin-gap halt — do NOT `emit-block`" note.
2. **`references/feedback-emission.md`** (tier 3) — `(\`$VAULT_PATH\` set **and**
   \`$VAULT_PATH/.obsidian/\` is a directory **and** writable)` → `(\`$VAULT_PATH\` set **and**
   an existing directory **and** writable)`. Loud-notice text unchanged.
3. **`references/cost-emission.md`** (tier 3) — `(\`$VAULT_PATH\` set **and**
   \`$VAULT_PATH/.obsidian/\` a writable dir)` → `(\`$VAULT_PATH\` set **and** an existing,
   writable dir)`. Notice unchanged.
4. **`references/followup-emission.md`** — §4 `vault_writable` = `\`$VAULT_PATH\` is set **and**
   \`$VAULT_PATH/.obsidian/\` is a directory **and** the path is writable.` → `\`$VAULT_PATH\`
   is set **and** is an existing directory **and** writable.` PLUS soften the §5 notice
   `⚠ No writable Obsidian vault — N follow-ups written to <path>` → `⚠ No writable vault — N follow-ups written to <path>` (accuracy — the gate no longer requires Obsidian).
5. **`plugins/dev-workflows/.claude-plugin/plugin.json`** + root
   **`.claude-plugin/marketplace.json`** — version `2.19.0` → `2.20.0` (lock-step). Descriptions
   byte-identical, counts unchanged (no new command/subagent).
6. **`plugins/dev-workflows/CHANGELOG.md`** — prepend a `## [2.20.0] — 2026-07-10` entry.

## No-regression

- **This is a loosening.** Every existing `.obsidian/` vault is still a writable directory, so
  it passes the new check unchanged — zero behavior change for current users.
- Silent tier-3 fallbacks (feedback/cost) are reached only when `$SPECS_PATH` is unavailable;
  the loud notice + namespaced subdir + never-cwd guard are all retained.
- `/vuln` + `/upgrade` have no vault gate — untouched.
- Sibling plugins `dt-style-guide` 0.2.2 + `obsidian-llm-wiki` 0.3.1 — untouched.

## Global constraints (verbatim)

- Version lock-step: `plugin.json` and the `dev-workflows` entry in `marketplace.json` both go
  to `2.20.0`; descriptions byte-identical except (they carry no version string).
- Commit trailer, exactly: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Never `git add -A`** — stage only named files.
- No test framework, no husky/prettier hook — verification is **structural** (grep, `python3 -c
  json.load`, `git diff --stat`).
- Commit / push only when the user asks.
- Branch `ivgu/NOISSUE-obsidian-vault-check`; ff-merge to `main`; delete branch.
- No user name in any file.

## Verification (structural)

- `grep -rn "\.obsidian" commands/idea.md references/feedback-emission.md
  references/cost-emission.md references/followup-emission.md` → **only** the Category-C
  tag-index line in followup-emission.md remains (the 4 write-gate `.obsidian/` occurrences are
  gone).
- `grep` each of the 4 gate sites for the new "existing directory … writable" wording.
- `grep -c "No writable Obsidian vault" references/followup-emission.md` → 0; the softened
  notice present.
- `python3 -c json.load` on both manifests; assert both `version == 2.20.0` and descriptions
  byte-identical.
- Byte-diff: `git diff --stat main -- commands/document.md commands/vuln.md commands/upgrade.md`
  empty (Category B + the maintenance commands untouched); sibling plugin dirs unchanged.
