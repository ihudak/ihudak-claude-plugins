# Counterpart-space documentation grounding for `/document`

- **Date:** 2026-07-15
- **Status:** Design approved (pending written-spec review)
- **Command affected:** `dev-workflows` `/document` (Jira mode) — Claude Code, mirrored to Copilot `document:` and the `mgd` marketplace
- **Kind:** Read-path enhancement (no change to the render-protection write path)

## 1. Problem & context

`/document PRODUCT-NNNN [saas|managed]` documents a single Dynatrace space when a
space constraint is passed, and leaves the **other** space's *rendered* output
unchanged (editing shared source files is fine; the render must not move — the
"file touched ≠ render changed" invariant in
`references/dynatrace-docs/multi-space-writing.md §2`).

`dynatrace-docs` is a **single repo holding both spaces** — SaaS under
`dynatrace/_content/`, Managed under `managed/_content/` plus SaaS pages pulled
into the Managed render via the `docstack.jsonc` allowlist
(`profile.cross_space_override`).

**Gap:** when a run documents one space, the *other* space's existing
documentation for the same feature — often already written by someone else — is
prime reference material (concepts, terminology, facts, structure). No current
phase deliberately ingests it. `doc-location-finder` only searches the *target*
space for write targets. So a writer authoring Managed docs re-derives context
that already exists on the SaaS side (and vice-versa).

## 2. Decisions locked during brainstorming

1. **Role = grounding only.** The counterpart doc is a read-only reference the
   writer consults; it authors fresh target-space prose. It is **never** a text
   source to copy from and **never** a template to mechanically mirror.
2. **Discovery = auto + optional pointer.** Auto-discovery of the merged/in-tree
   counterpart is the default; an optional explicit ref reaches an *unmerged*
   counterpart PR and overrides a wrong auto-match.
3. **Screenshots are comprehension-only.** SaaS and Managed UIs differ, so a
   counterpart screenshot may be *read* to understand how a feature works but
   must **never** become an image in the target doc. Target images keep sourcing
   from the normal Phase 5.6 path only.

## 3. Scope

**In scope**

- Space-constrained runs only (`target_spaces` is exactly one space).
- Symmetric: `--managed` grounds on SaaS; `--saas` grounds on Managed.
- A new bounded read-only agent, a new discovery sub-phase, and additive fields
  on the `doc-planner` / `doc-writer` handoffs and the `doc-reviewer` checklist.
- One optional new command flag.

**Out of scope**

- Unconstrained (both-space) runs — no single "other" space exists, so the
  feature is inactive there.
- The write/render-protection path (Phase 5.9, Phase 6.3, Phase 6.5) — unchanged.
- Any structural-mirroring or port/translate behavior (explicitly rejected).
- Any new external-API surface.

## 4. Design

### 4.1 Concept

When `target_spaces == [X]` (single space), the **counterpart space** is the
other space present in the resolved `profile.spaces[]`. The command discovers the
counterpart's documentation for the feature and threads it into planning and
writing as **read-only grounding**: concepts, terminology, verified facts, and —
for the writer's understanding only — the counterpart's section structure and
screenshots. The writer authors fresh target-space content and cites nothing
from the counterpart in the reader-visible page.

### 4.2 Discovery mechanism — two layers

Both layers reuse existing, proven machinery.

**Layer 1 — auto (default).**
1. Keyword-overlap search of the counterpart space's `content_root` using the
   same technique `doc-location-finder` applies to the target space.
2. `git -C <docs_repo_path> log --all -E --grep=<Jira-key>` to locate the merge
   that added the counterpart page (covers a page that landed recently and is
   named unlike the feature).
In-tree matches are read directly.

**Layer 2 — optional pointer (`--counterpart <JiraID | PR-url>`).**
Routes through the existing `diff-summarizer` **host-aware resolver** (gh for a
GitHub-cloud docs repo when available, with local-git fallback; local-git-only
for Bitbucket — PR refs / merge-commit grep; **never** Bitbucket REST), but
extracts the *added/modified doc pages* as reference rather than a code-diff
summary. Reaches an **unmerged** counterpart PR and pins/overrides a wrong
auto-match. Because the docs-repo clone the run already operates on *is* the
target of any counterpart PR, the local-git strategies apply directly.

**Confirmation gate.** Candidates are shown ranked (page · space · confidence ·
why). The user chooses the set to ground on, supplies a `--counterpart` ref
instead, or skips grounding. **Default: always ask**, with the high-confidence
matches pre-selected (consistent with the command's confirmation culture; the
grounding is only as good as the page it picks).

**Graceful no-op.** Nothing found / ref unresolvable → record a one-line note and
proceed exactly as today. The feature never blocks a run (same best-effort ethos
as the Phase 6.5 render smoke-check).

### 4.3 `counterpart_references[]` data contract

Emitted by the discovery phase; threaded into the `doc-planner` (Phase 5.7) and
`doc-writer` handoffs. One entry per grounded counterpart page:

```yaml
counterpart_references:
  - source_kind:          in_tree | pr_ref
    path:                 <absolute path when in_tree; null for pr_ref>
    pr_ref:               <the resolved ref/url when pr_ref; null when in_tree>
    space:                saas | managed        # the counterpart (non-target) space
    salient_summary:      <writer-facing grounding digest: concepts, verified
                           facts, terminology; NO target-space claims>
    section_outline:      [<heading>, ...]      # for the writer's understanding only
    is_shared_into_target: true | false         # counterpart page already pulled
                                                # into the target render (allowlist)
    screenshots_seen:                            # comprehension-only; NEVER reused
      - path:             <path>
        comprehension_only: true
    match_confidence:     high | medium | low
    match_reason:         <why this page matched>
```

### 4.4 Phase-flow integration

- **New Phase 5.6.5 — Counterpart-space reference discovery.** Runs after
  `target_spaces` is fixed (Phase 4.5) and the image scan (Phase 5.6), and
  before the `doc-planner` dispatch (Phase 5.7). Active only when
  `target_spaces` is a single space and (auto is enabled **or** `--counterpart`
  was passed). Emits `counterpart_references[]`.
- **New agent `counterpart-finder`** (tools: `Read, Glob, Grep, LS, Bash`;
  read-only, never writes). Does the Layer-1 in-tree search and the Layer-2
  ref resolution (reusing `diff-summarizer`'s host-aware resolver — gh for a
  GitHub-cloud docs repo with local-git fallback; local-git-only for Bitbucket).
  Model tier is caller-assigned per the model-routing policy (no fixed Opus pin
  — it is a bounded search/extraction agent).
- **`doc-planner` consumes `counterpart_references[]`** as grounding for topic
  and section planning, and gains a **write-strategy signal**: an entry with
  `is_shared_into_target: true` is strong evidence for a `conditional`
  (edit-in-place delta) over a fresh `managed/_content/` page — and may mean the
  target space is *already covered*, which is surfaced to the user.
- **`doc-writer` receives `counterpart_references[]`** as read-only reference
  alongside the planner checklist.

### 4.5 Screenshots (the corrected rule)

- Counterpart screenshots are enumerated in `screenshots_seen[]` with
  `comprehension_only: true` and are used **only** to help the writer/planner
  understand the feature.
- They are **never** added to the Phase 5.6 image candidate list. Target-doc
  images continue to come exclusively from the four Phase 5.6 sources: the
  `specs_dir` scan, `jira-reader` `attachments[]` (`$VAULT_PATH/jira-products/…`,
  read-only), the `<project_dir>` scan (`$VAULT_PATH/Projects/<VI-dir>/…`,
  authored/curated), and user-provided manual paths.
- `doc-reviewer` gains a check that no target-doc image traces to a counterpart
  screenshot.

### 4.6 Guardrails & edge cases

- **No-leak rule (critical).** Extends the existing cross-*product* anti-copy
  guardrail (`doc-planner:175`) to cross-*space*: consult the counterpart, but
  never copy space-specific UI paths, URLs, labels, defaults, or screenshots into
  the target doc. Enforced in `doc-planner` and re-checked in `doc-reviewer`.
- **Shared-page awareness.** `is_shared_into_target: true` may make the target
  work a small conditional delta rather than a new page — surfaced to the user
  and fed to Phase 5.9.
- **Both-run.** Discovery is skipped on unconstrained runs; an explicit
  `--counterpart` on a both-run is rejected with a one-line note.
- **Zero-API compliance.** The pointer path adds no new external surface — it is
  the same `diff-summarizer` resolver against a clone that is already present.

### 4.7 Reviewer additions (`doc-reviewer`)

1. No counterpart-space-specific detail (UI path, URL, label, default) leaked
   into the target doc.
2. No target-doc image whose provenance is a counterpart screenshot.

### 4.8 Argument surface

- Signature becomes `PRODUCT-NNNN [saas|managed] [--counterpart <JiraID | PR-url>]`.
- `--counterpart` is a **named flag** (not a positional token — avoids ambiguity
  with the existing `[saas|managed]` token). Valid only on a space-constrained
  run; on a both-run it is rejected with a note.

## 5. Rollout

All three marketplaces stay in parity. **Every rollout unit is code + docs** —
the command/agent/skill changes, the README documentation of the new use-case
and the `--counterpart` flag, an update to any `/document` workflow diagram that
depicts the affected phases, a version bump, and a CHANGELOG entry. Docs are not
a follow-up; they ship with the behavior.

1. **Claude `dev-workflows` (primary):**
   - New `counterpart-finder` agent, Phase 5.6.5, `counterpart_references[]`
     threading through `doc-planner` / `doc-writer`, `doc-reviewer` checks,
     `--counterpart` flag.
   - `CLAUDE.md`: workflow-map edge + key-invariant updates.
   - **README**: document the counterpart-grounding use-case and the
     `--counterpart` flag; update the `/document` workflow diagram if one exists.
   - Version bump + CHANGELOG.
2. **`mgd-claude-plugins` — 1:1 port.** Same Claude Code marketplace, so port
   every change verbatim (command, agent, `CLAUDE.md`, README, diagram),
   adjusting only the marketplace-identity strings that already differ
   (marketplace name, author, AI-containers URL). Independent version bump +
   CHANGELOG.
3. **`ihudak-copilot-plugins` — adapted port.** GitHub Copilot marketplace:
   translate to Copilot conventions — the `document:` skill under
   `skills/document/SKILL.md` (keyword-trigger), a `counterpart-finder` agent
   dispatched via `task(agent_type: "dev-workflows:counterpart-finder", model: …)`
   with **no** frontmatter `model:` pin (the caller pins the tier),
   `.plugin/plugin.json` + `.github/plugin/marketplace.json` version bumps, README
   documentation + diagram update, and CHANGELOG. The flag surface
   (`--counterpart`) and behavior stay identical; only the plumbing differs.

## 6. Resolved defaults

- **`--counterpart` flag name** — confirmed (named flag, not positional). Must be
  documented in every affected README.
- **Confirmation-gate default** — always ask, with high-confidence matches
  pre-selected.

## 7. Success criteria

- On a space-constrained run with a merged counterpart page, the writer's context
  includes that page's concepts/terminology, and the produced doc contains **no**
  counterpart-space UI paths/URLs and **no** counterpart screenshots.
- `--counterpart <PR-url>` to an unmerged counterpart PR surfaces its added pages
  as grounding with zero external-API calls beyond the existing resolver.
- When the counterpart page is already allowlisted into the target render, the
  run recommends `conditional` / flags "target may already be covered."
- No counterpart found → the run behaves exactly as it does today.
