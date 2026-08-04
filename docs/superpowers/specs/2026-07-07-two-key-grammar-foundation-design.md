# Two-key `<VI> <Epic>` grammar + progress-aware Epic picker — foundation design

**Date:** 2026-07-07
**Effort:** dev-workflows plugin — foundation for the PM→Dev pipeline (fixes a shipped `/specify` bug; unblocks `/design`).
**Ships as:** a `/specify` change + an additive change to the shared `references/jira-input-resolution.md`.
**Repo:** `/workspace/ihudak-claude-plugins`, plugin `dev-workflows`.

---

## 1. Context

`/specify` (v2.4.0, shipped) is the PM half of a PM→Dev pipeline: it authors an org-standard
`specification.md` for one Jira Epic and lands it on the `mgd-specifications` repo `main` via branch+PR.
`/design` (brainstorm done, **blocked on this effort**) is the Dev half.

Both repos are keyed differently than `/specify` assumed. This effort establishes a shared, correct
input grammar and per-Epic output convention, fixes `/specify`, and unblocks `/design`.

### Verified repository reality (checked 2026-07-07)

- **Vault `$VAULT_PATH/jira-products/`** — top level is **VI-keyed** (`PRODUCT-<n>`) plus occasional
  stand-alone non-PRODUCT items (`OA-64450`, `PRODFB-929`). Inside a VI dir, **every descendant
  (Epics, Stories, sub-VIs) is a FLAT sibling dir keyed by raw Jira key, no slug**
  (`PRODUCT-14640/MGD-9226/`), each holding only `<KEY>.md` + `<KEY>-comments.md`. **Only the VI level
  has `<VI>-index.md`.** The Epic→Story hierarchy lives in **markdown links, not the directory tree** —
  an Epic's Stories are flat siblings under the VI, not nested under the Epic.
- **Specs repo `$SPECS_PATH/specifications/`** — **VI-keyed** dirs, now normalized by the user to a
  **consistent `PRODUCT-<n>-<slug>` (hyphen) convention**. Inside a VI dir: a top-level `<VI>-<slug>.md`
  plus ad-hoc `spec/`, `plan/`, `epics/`. **No `specification.md` exists anywhere, and there is no
  per-Epic dir convention** — this effort *introduces* one.

### The shipped `/specify` bugs this fixes

1. **Input:** Phase 0 looks for `$VAULT_PATH/jira-products/<KEY>/` containing `<KEY>-index.md`. That
   only exists for top-level VIs, so **a bare Epic key never resolves** (falls to Fallback B). Epics
   live nested and unslugged with no index of their own.
2. **Output:** writes `specifications/<KEY>_<slug>/` — **underscore delimiter** (mismatches the repo's
   now-consistent hyphen convention) and **collides with the VI's own dir** when `<KEY>` is a VI. No
   per-Epic home.

---

## 2. Goals / non-goals

**Goals**
- A shared, correct input grammar for pointing at a VI or one Epic, robust to the flat/unslugged vault
  and the VI-keyed specs repo.
- A per-Epic output convention in the specs repo.
- Fix `/specify`'s input resolution + output path.
- Add a progress-aware Epic picker so a user can drive a multi-Epic VI without looking up Epic keys.
- Do all of the above **additively** so the other Jira-driven commands keep working unchanged.

**Non-goals (deferred, tracked in `docs/superpowers/harvest/NEXT.md`)**
- Adopting the grammar / `focus_key` / picker in `/implement`, `/document`, `/epics`, `/release-notes`.
- `/design` itself (separate effort; brainstorm+doc done, resumes at writing-plans after this ships).
- Deciding `/implement`'s per-Epic "done" predicate (open question).
- Any jira-reader change (explicitly avoided — see §6).

---

## 3. Input grammar — Hybrid

`$ARGUMENTS` is a whitespace-separated token list, classified by the existing rules (JiraID / path /
command-specific trailing option / free-text). The **VI selector** (first positional) may be either a
**VI JiraID** (resolved under `$VAULT_PATH/jira-products/<VI-Key>` — bare key, no slug — requires
`$VAULT_PATH`) or a **jira-export directory** (used directly as the export root; **no `$VAULT_PATH`
needed** — the non-AI-Containers path). An optional **focus Epic** (a JiraID) may follow either form.

**VI selector = VI JiraID** → classify a single `<KEY>` against `$VAULT_PATH/jira-products/`:
- `<KEY>` **is a top-level dir** → a **VI** (or a stand-alone top-level item). `jira_export_root` =
  `jira-products/<KEY>`; `source = vault`; `focus_key = null`.
- `<KEY>` **is not a top-level dir** → treat as a **nested Epic**: **auto-resolve its parent VI** by
  scanning `jira-products/*/` for a child dir named `<KEY>` containing `<KEY>.md`.
  - exactly one parent → that VI is `jira_export_root`; `focus_key = <KEY>`.
  - zero parents → **Fallback D**; ≥2 parents → **Fallback E**.

**VI selector = jira-export directory** (`@/path` or a bare path that **content-inspects** as a
jira-export — contains `<VI>-index.md` and flat `<KEY>/` child dirs, same classification the front-end
already performs). `jira_export_root` = this dir; `source = directory`; **no `$VAULT_PATH` required**.
This is exactly what Fallback A ("JiraID but no `$VAULT_PATH`") already points users to.

**Optional focus Epic** (second positional, a JiraID) — binds to whichever root the selector resolved:
validate `<root>/<Epic>/<Epic>.md` exists → `focus_key = <Epic>`. Missing → **Fallback D**.

Resulting forms:

| Input | Root | `$VAULT_PATH`? | `focus_key` |
|---|---|---|---|
| `<VI-Key>` | `jira-products/<VI-Key>` | required | null |
| `<Epic-Key>` | parent VI (auto-resolved) | required | the Epic |
| `<VI-Key> <Epic-Key>` | `jira-products/<VI-Key>` | required | the Epic |
| `<dir>` | `<dir>` | not needed | null |
| `<dir> <Epic-Key>` | `<dir>` | not needed | the Epic |

**Disambiguation:** a directory token is classified **by content** (jira-export vs spec-folder), exactly
as today — so `<dir> <Epic-Key>` (jira-export dir + focus) never collides with the existing
`<VI-Key> @spec-folder` form (a spec-folder contributes to `specs`, not to the VI root).

This is a strict superset of single-key behavior: a bare top-level VI resolves exactly as it does today,
with `focus_key = null`; the directory forms extend the front-end's existing directory support.

### Output contract change (additive)

The shared `## Output contract` gains one nullable field:

```
focus_key:        <EPIC key> | null    # the Epic to center on within jira_export_root; null for a bare VI/stand-alone
```

`jira_key` continues to denote the resolved top-level key (the VI, when a focus Epic is present);
`jira_export_root` continues to point at the VI dir (which holds the index and all flat children).
Commands that do not read `focus_key` behave byte-for-byte as before.

### New fallbacks (orchestrator-owned)

- **D — Epic key given but not found** (single-key: no parent VI contains it; two-key/dir:
  `<root>/<Epic>/` missing): `choices: ["Re-enter the Epic key", "Pass <VI> <Epic> explicitly", "Cancel"]`.
- **E — nested Epic key found under multiple VIs:** list the candidate VIs;
  `choices: ["<first> (Recommended)", "<other VIs…>", "Cancel"]`.

---

## 4. VI semantics are per-command (the resolver is policy-neutral)

**Critical principle:** the shared reference resolves the grammar, enumerates a VI's Epics, and emits
`focus_key` — but it **does not decide** whether a VI means "per-Epic" or "VI-level". **The picker and
`focus_key` are opt-in per command; the resolver never forces per-Epic.**

- **Epic-unit commands** (`/specify`, and later `/design`, `/implement`): the Epic is the unit of a
  reviewable, ownable artifact. VI input is handled per §5.
- **VI-level commands** (`/epics`, `/document`, `/release-notes`): operate at VI scope and **MUST keep
  working for a VI that has not been split into Epics** (zero child Epics — `/epics`' entire job is to
  *create* them). They must **never** be forced into the picker. (Their adoption of the grammar, when it
  comes, is limited to honoring `focus_key` when a user *explicitly* passes `<VI> <Epic>`, defaulting to
  VI-level otherwise. Deferred — see §9.)

Only `/specify` implements §5 in this effort.

---

## 5. Progress-aware Epic picker (`/specify`, first implementer)

For an Epic-unit command given a **top-level key** (`focus_key = null`), first **determine the item's
type** via `jira-reader depth: vi-plus-epics` (cheap):

- **The item is itself an Epic** (a stand-alone/top-level Epic, e.g. `OA-64450`) → **no picker**;
  specify it directly (equivalent to `focus_key` = itself). This preserves the shipped "Epic input →
  proceed" branch.
- **The item is a VI** → branch on its child-Epic count:

- **VI with exactly 1 Epic** → **no picker**; auto-proceed for that Epic (one-line notice:
  "PRODUCT-123 has one Epic MGD-9226 — specifying it").
- **VI with ≥2 Epics** → render an **interactive, status-aware picker**. Status is computed from the
  command's **own output artifact** (`/specify`'s predicate = `specification.md` exists in the Epic's
  per-Epic home):
  - **○ not started** — no `specification.md` → selectable.
  - **◐ in progress** — a `_session.md` exists but no `specification.md` → selectable as **resume**.
  - **● done** — `specification.md` exists → **shown greyed, not default-selectable**; selecting it
    offers *revise/annotate*, not redo-from-scratch. (Shown, not hidden, so the picker doubles as a
    "how complete is this VI?" view.)
  - Default cursor = first actionable Epic (in-progress before not-started).
  - An explicit **"Author one broad VI-level spec instead"** choice (the escape hatch — treats the VI
    as a single unit; output per §7).
- **VI with 0 Epics** → the existing `/specify` handling: offer
  `["Split into Epics first with /epics, then create them in Jira and re-import (Recommended)",
  "Author one broad VI-level spec now", "Cancel"]`.

After finishing one Epic, offer **"Next Epic? [picker] / Stop here"** — chaining several in one sitting
or resuming days later are both fine. **Two layers of resume stack:** the **VI picker** (which Epic) +
`/specify`'s existing **`_session.md`** (where in the grill).

The **picker pattern is documented in the shared reference** (each command supplies its own done-predicate);
`/specify` is its first consumer.

---

## 6. Reading one Epic's Jira material (no jira-reader change)

Because the vault is flat and hierarchy is in links, we cannot point the reader at the Epic's own dir.
Instead:

- `jira_export_root` stays the **VI dir** (has the index and all flat children).
- `/specify` dispatches `jira-reader` at `depth: full` against the VI root (unchanged), then **scopes
  the grill material to `focus_key`'s subtree in-orchestrator** — jira-reader already returns the
  linked-item hierarchy, so the orchestrator filters to the Epic + its descendants.
- **jira-reader is not modified.** Other commands can adopt the same orchestrator-side scoping later.

---

## 7. Output-path layout

Per-Epic dir nested under the VI dir, mirroring the vault's VI→Epic nesting, coexisting with the legacy
`spec/`/`plan/`/`epics/` dirs (untouched):

```
specifications/
  PRODUCT-14900-lambda-govcloud/            ← VI dir: honor existing name; else <VI>-<slug>
    PRODUCT-14900-lambda-govcloud.md        ← legacy VI top file (untouched)
    spec/  plan/  epics/                     ← legacy ad-hoc dirs (untouched)
    MGD-9226-container-perf-hint/           ← NEW per-Epic home: <EPIC>-<eslug>
      specification.md                       ← /specify output (Published: no)
      specification.html                     ← rendered
      idea.md  _session.md  _glossary.md     ← /specify working/resume files
      design.md                              ← /design output (later effort) — SAME dir, flat
    specification.md                         ← VI-LEVEL spec (only for the "broad VI spec" escape hatch)
```

- **Per-Epic home** = `specifications/<VI>-<slug>/<EPIC>-<eslug>/`. `<eslug>` is derived from the Epic
  title (kebab-case; vault Epic dirs are unslugged) — the same slug derivation `/specify` already does,
  applied to the Epic.
- **VI dir honored if it exists** (match by key-number; a human may have set the slug); created as
  `<VI>-<slug>` only if absent.
- **VI-level "broad spec" escape hatch** → `specifications/<VI>-<slug>/specification.md` (flat at VI
  level, alongside the legacy top file).
- **Stand-alone top-level Epic** (a top-level item that is itself an Epic, no parent VI, e.g. `OA-64450`)
  → `specifications/<EPIC>-<eslug>/specification.md` (a top-level dir keyed by the Epic, since there is
  no VI to nest under).
- **Delimiter = hyphen** everywhere; the resolver matches an existing dir by key-number and tolerates a
  stray delimiter as cheap insurance against future drift.
- **Internal layout is flat** — `specification.md` and (later) `design.md` sit directly in the Epic dir.
  This reconciles the `/design` draft's `…/spec/design.md` down to `…/design.md` when `/design` resumes.

---

## 8. `/specify` changes (the fix)

- **Phase 0 input:** replace the bare-`<KEY>` lookup with the §3 Hybrid grammar (single-key classify +
  auto-resolve parent; two-key explicit; Fallbacks D/E). Emit/consume `focus_key`.
- **Phase 0 output:** replace `specifications/<KEY>_<slug>/` with the §7 per-Epic home
  `specifications/<VI>-<slug>/<EPIC>-<eslug>/` (or the VI-level path for the escape hatch); switch the
  delimiter to hyphen; honor an existing VI dir.
- **VI handling:** implement the §5 picker (via `jira-reader depth: vi-plus-epics` enumeration + the
  `specification.md` done-predicate + "next?/stop" + two-layer resume). Keep the existing 0-Epics and
  broad-VI-spec paths.
- **Reader scoping:** §6 (read `full` against the VI root, scope the grill to `focus_key`'s subtree).
- **Phase 7 branch name:** `spec/<EPIC>-<eslug>` (hyphen; Epic keys are globally unique) for a per-Epic
  spec; `spec/<VI>-<slug>` for a VI-level spec.

---

## 9. Backward compatibility & follow-up

- The shared-reference change is **strictly additive**: single-key resolution and the existing Output
  contract fields are unchanged; `focus_key` is new and nullable. `/implement`, `/document`, `/epics`,
  `/release-notes` continue to work exactly as today.
- Until they individually adopt the grammar, those commands will **parse** a `<VI> <Epic>` input (they
  cite the shared reference) but **ignore `focus_key`** (resolve the VI, read the whole VI). This is a
  **known, recorded inconsistency, not a silent regression** — tracked in
  `docs/superpowers/harvest/NEXT.md` (⚠️ FOLLOW-UP) so it is not forgotten. `/epics`/`/document`/`/release-notes`
  must remain VI-capable for un-split VIs; `/implement`'s done-predicate is an open question.

---

## 10. Verification (structural — no test framework, no husky/prettier hook)

- `references/jira-input-resolution.md`: grep anchors for the new grammar section, `focus_key` in the
  Output contract, Fallbacks D/E, and the documented picker pattern; confirm single-key text is
  unchanged (diff review).
- `commands/specify.md`: grep anchors for the Hybrid Phase-0 resolution, the per-Epic hyphen output
  path, the picker (states, next/stop, done-predicate), `focus_key` scoping, and the branch-name change.
- Manifests: `python3 -c 'json.load(...)'` on `plugin.json` + `marketplace.json`; version bump
  lock-step (`plugin.json` version + `marketplace.json` `plugins[0].version` + CHANGELOG prepend;
  siblings `dt-style-guide`/`obsidian-llm-wiki` untouched).
- Byte-diff review of all edits; whole-branch Opus review before merge.

---

## 11. Files touched

- **Modify:** `references/jira-input-resolution.md` (grammar + `focus_key` + fallbacks + picker pattern,
  additive).
- **Modify:** `commands/specify.md` (Phase 0 input+output, picker, reader scoping, branch name).
- **Modify:** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (`plugins[0].version`),
  `CHANGELOG.md` (prepend). READMEs only if a documented behavior/count changed.
- **Not touched:** `agents/jira-reader.md` (§6), the other command files (§9), sibling plugins.

**Version:** this adds user-facing capability (two-key grammar + picker) on top of a bug fix →
recommend a **MINOR** bump to **v2.5.0**, which shifts the planned `/design` release to **v2.6.0**.
(Alternative: patch v2.4.1 if you prefer to keep `/design` at v2.5.0. Confirm at plan time.)

**Commit trailer:** `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Never
`git add -A`; never stage `.superpowers/` or `.docstack`. This design doc lives in the vault — do **not**
commit vault files (vault git is the user's responsibility).
