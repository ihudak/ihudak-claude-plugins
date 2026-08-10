# Model-reference refresh — design

**Status:** approved 2026-08-10
**Relationship:** a pre-pass for sub-project C (`2026-08-10-specs-repo-git-completeness-design.md`). It lands **first** because it edits five of the same command files C touches; running it after C would reopen them.
**Target versions:** canonical `dev-workflows` 2.44.0 → **2.44.1**; mgd 2.44.0 → **2.44.1**; copilot 2.14.0 → **2.14.1**

---

## 1. Problem

The plugin's model references are stale, and the three editions disagree with each other about what the fallback chain even is.

### 1.1 Opus 5 is absent

`references/model-routing/classification.md:79-86` tops the strong-tier chain at `claude-opus-4-8`. Opus 5 exists and is reachable. Five commands additionally hardcode `Co-Authored-By: Claude Opus 4.8 (1M context)` in their handoff commit trailers.

### 1.2 The copilot edition documents three different chains

| Source | Chain as written |
|---|---|
| `skills/_shared/model-routing.md:89-111` | Opus 4.8 → 4.7 → 4.6 → … → Opus 4.5 → Sonnet 4.6 → Sonnet 4.5 |
| `.github/copilot-instructions.md:110` | Opus 4.8 → 4.7 → 4.6 → GPT-5.5 → Opus 4.5 → Sonnet 4.6 → Sonnet 4.5 → GPT-5.4 → Gemini 3.1 Pro |
| `dev-workflows/README.md:253` | Opus 4.8 → 4.7 → 4.6 → **Haiku 4.5** → GPT-5.5 → Sonnet 4.6 → … |

The README variant is a defect independent of Opus 5: **Haiku 4.5 is listed as a strong-tier fallback above GPT-5.5.** Haiku is the cheapest model in the lineup. A SIGNIFICANT or HIGH-RISK review gate degrading to Haiku before it tries GPT-5.5 inverts the purpose of the tier. Fixed here, per explicit decision, because this pass already opens the file.

### 1.3 Sonnet 5 drift

- Canonical `CLAUDE.md:94` describes the chain as "Opus 4.8 → 4.7 → 4.6 → Sonnet 4.6 → Sonnet 4.5" — omitting `claude-sonnet-5`, which `classification.md` already carries at position 4.
- **The copilot edition has no `claude-sonnet-5` anywhere**, in either the strong chain or the mid-tier chain (`model-routing.md:137-138` tops the detection tier at Sonnet 4.6). The B-series ports never carried it across.

---

## 2. The chains after this pass

### 2.1 Canonical + mgd — strong tier (`classification.md` §2)

```
1. claude-opus-5          <- new
2. claude-opus-4-8
3. claude-opus-4-7
4. claude-opus-4-6
5. claude-sonnet-5        (fallback only — note that no Opus was available)
6. claude-sonnet-4-6      (further fallback)
7. claude-sonnet-4-5      (further fallback — note "no Opus or Sonnet 5/4.6 available")
```

Sonnet 4.5 remains the floor, and the existing abort-rather-than-downgrade rule is unchanged.

### 2.2 Canonical + mgd — mid tier (`classification.md` §2.1)

**Unchanged** — already `claude-sonnet-5` → `claude-sonnet-4-6` → `claude-sonnet-4-5`.

### 2.3 Copilot — strong tier (`skills/_shared/model-routing.md`)

**The copilot strong tier is a peer set, not a ladder, and that structure is preserved.** `model-routing.md:87-105` defines a first-class peer set with its own selection rule — *"prefer the model the orchestrator is already running under if it is in the strong-tier peer set; otherwise pick the first available peer in list order"* — and a separate **further fallbacks** list whose selection *is* announced as a degradation. GPT-5.5 is explicitly documented as a co-equal peer, never a downgrade. Flattening this into one ladder would erase the distinction and change behaviour.

**Peer set — grows from four to six.** Opus 5 first, GPT-5.6 second, the four existing peers in their current relative order:

```
- claude-opus-5          <- new
- gpt-5.6                <- new
- claude-opus-4.8
- claude-opus-4.7
- claude-opus-4.6
- gpt-5.5
```

The prose "These **four** are first-class peers" becomes "These **six** …", and GPT-5.6 joins the existing parenthetical explaining why GPT models are peers here and not in Claude Code.

**Further fallbacks — `claude-sonnet-5` slots above `claude-sonnet-4.6`,** preserving the relative order of everything already present. The list is renumbered from 7 (it currently starts at 5, implying the four peers occupied 1–4):

```
7.  claude-opus-4.5
8.  claude-sonnet-5      <- new
9.  claude-sonnet-4.6
10. claude-sonnet-4.5
11. gpt-5.4
12. gemini-3.1-pro-preview
```

`gemini-3.1-pro-preview` remains the floor, and the existing abort-rather-than-downgrade rule is unchanged. Haiku 4.5 appears nowhere in either list. The copilot edition keeps its dotted model-id dialect (`claude-opus-4.8`, not `claude-opus-4-8`) — an existing, deliberate difference, not normalised here.

### 2.4 Copilot — mid tier (`model-routing.md` §2.1)

`claude-sonnet-5` is prepended; the existing `gpt-5.4` tail is retained:

```
1. claude-sonnet-5        <- new
2. claude-sonnet-4.6
3. claude-sonnet-4.5
4. gpt-5.4                (further fallback — note the degradation in the report)
```

### 2.5 The strong-tier peer label

Copilot describes the tier inline in many places as `Opus 4.8/4.7/4.6 or GPT-5.5`. That becomes:

> `Opus 5/4.8/4.7/4.6 or GPT-5.6/5.5`

Applied verbatim at every site in §4.2 that carries the old form.

### 2.6 Availability

`gpt-5.6` is included on the user's direct instruction as the model GitHub Copilot CLI currently exposes; it was not verifiable from this environment. The risk is nil either way: both chains are **first-available walks**, so an entry the runtime cannot reach is skipped, not fatal.

---

## 3. Pricing

`references/cost-prices.yaml` gains one entry. Rates re-verified 2026-08-10 against the source the file already names (`https://platform.claude.com/docs/en/about-claude/pricing`):

```yaml
  claude-opus-5:
    input: 5.0
    output: 25.0
    cache_read: 0.5
    cache_write_5m: 6.25
    cache_write_1h: 10.0
```

**Opus 5 bills identically to the entire Opus 4.5–4.8 block** ($5 / $25; cache read $0.50, 5m write $6.25, 1h write $10), so the entry is a copy of its neighbours and the block comment becomes `# Opus chain (§2). Opus 5 and Opus 4.5-4.8 all bill at $5 / $25.` The retrieval date in the file header moves to 2026-08-10.

### 3.1 Why this entry is load-bearing, not cosmetic

The price engine exact-matches a model id first, then falls back to **the longest table key that is a prefix of the id**. No existing key is a prefix of `claude-opus-5` — `claude-opus-4-8` is not. Routing to Opus 5 without adding this entry would silently price every SIGNIFICANT and HIGH-RISK run as `unpriced-model` with `cost_usd: null`, degrading the whole cost subsystem the moment the chain change took effect. The price entry and the chain change must therefore ship together.

### 3.2 What does NOT change

- **Sonnet 5 stays at its standard $3 / $15.** Its $2 / $10 is confirmed introductory through 2026-08-31. The file's existing rule — *"PERMANENT (standard) rates only … a temporary promo would make identical work look cheaper now and dearer later, distorting cross-VI efficiency comparisons"* — is correct as written and is re-confirmed, not edited.
- **Fast-mode pricing is not added.** Opus 5 and Opus 4.8 have a fast-mode rate of $10 / $50, but the file's header already states that fast-mode modifiers are not applied, because interactive Claude Code sessions bill at standard rates.
- No Fable 5, Mythos 5, or retired-model keys are added — the file's stated scope is "every model the plugin's routing policy can reach", and none of those is in either chain.

---

## 4. Files

### 4.1 Canonical (`/workspace/ihudak-claude-plugins`) — 11 files

| File | Change |
|---|---|
| `references/model-routing/classification.md` | §2 chain (§2.1 above); the `<e.g. claude-opus-4-8>` examples at `:167-169`; the degradation-note example at `:178`; the agent model pin example at `:218` |
| `references/cost-prices.yaml` | the `claude-opus-5` entry, the block comment, the retrieval date (§3) |
| `references/cost-emission.md:225` | worked-example cost entry naming `claude-opus-4-8` |
| `commands/create-vi.md:192` | handoff commit trailer |
| `commands/create-ard.md:131` | handoff commit trailer |
| `commands/update-vi.md:92` | handoff commit trailer |
| `commands/design.md:311` | handoff commit trailer |
| `commands/specify.md:410` | handoff commit trailer |
| `commands/docs-profile.md:61,102` | `§2 powerful chain` examples |
| `commands/document.md:234` | `§2 powerful chain` example |
| `CLAUDE.md:94` (repo root) | chain description — also gains the missing Sonnet 5 (§1.3) |

**mgd (`/workspace/mgd-claude-plugins`):** the same 11 changes, content-verbatim. Its 5 identity files are untouched.

### 4.2 Copilot (`/workspace/ihudak-copilot-plugins`) — 16 files

| File | Change |
|---|---|
| `dev-workflows/skills/_shared/model-routing.md` | strong chain (§2.3), mid-tier chain (§2.4), the `<e.g. …>` examples at `:195-199`, the agent pin example at `:248` |
| `dev-workflows/agents/{code-review, risk-planner, doc-reviewer, epic-reviewer, vi-reviewer, ard-reviewer, spec-reviewer, design-reviewer, readiness-reviewer}.md` | 9 files — the peer label (§2.5) in both the `description:` frontmatter and the body |
| `dev-workflows/hooks/preload-context.sh:58` | peer label |
| `dev-workflows/.plugin/plugin.json` | peer label in `description` |
| `.github/plugin/marketplace.json` | peer label in `description` |
| `.github/copilot-instructions.md:110,174` | chain (§2.3) + peer label |
| `dev-workflows/README.md:250,252-253` | chain (§2.3) — **including the Haiku 4.5 removal (§1.2)** |
| `README.md:9` (repo root) | peer label |

Both catalog files (`.plugin/plugin.json`, `.github/plugin/marketplace.json`) and `.github/copilot-instructions.md` appear explicitly above; each was missed in 2.42.0.

### 4.3 Explicitly excluded

- **All three `CHANGELOG.md` files.** They are a historical record of what shipped; rewriting a past entry's model name would falsify it.
- `ihudak-copilot-plugins/docs/superpowers/{specs,plans}/2026-07-13-claude-to-copilot-port*`. Historical design documents describing the state at the time.
- Canonical `agents/*.md`. Nine agents pin `model: opus` — an **alias**, not a version, so it resolves to the current Opus with no edit.

---

## 5. Verification

Prompt-markdown repo: no build, no test framework. Verification is grep, diff, and reading.

| # | Check | Expectation |
|---|---|---|
| V1 | `claude-opus-5` in canonical `classification.md` §2, at position 1 | present, first |
| V2 | `claude-opus-5` entry in `cost-prices.yaml` with input 5.0 / output 25.0 / cache_read 0.5 / write_5m 6.25 / write_1h 10.0 | exact match (§3) |
| V3 | `Opus 4.8 (1M context)` in canonical `commands/` | 0 occurrences |
| V4 | `claude-opus-4-8` in canonical `classification.md` | appears **only** as chain position 2; every `<e.g. …>` example now names `claude-opus-5` |
| V5 | Copilot's three chain statements agree. They legitimately differ in *shape* — `model-routing.md` is the structured authority (peer set + further fallbacks), `copilot-instructions.md:110` and `README.md` are flat summaries — so the check is that **the flattened order each implies is the same 12-model sequence** (§2.3), not that the text is identical |
| V5b | `model-routing.md` still distinguishes peer set from further fallbacks, and still says peer selection is never announced as a downgrade | preserved (§2.3) — flattening it would be a behaviour change |
| V6 | `Haiku 4.5` in any copilot strong-tier chain or fallback list | 0 occurrences (§1.2) |
| V7 | `claude-sonnet-5` in the copilot edition | present in the further-fallbacks list and at the top of the mid-tier chain |
| V8 | `gpt-5.6` in the copilot edition | present as peer-set entry 2 in all three sources; peer prose reads "These six" |
| V9 | Peer label `Opus 4.8/4.7/4.6 or GPT-5.5` (old form) in copilot | 0 occurrences; replaced by the §2.5 form |
| V10 | Canonical `CLAUDE.md:94` chain description | matches §2.1 including Sonnet 5 |
| V11 | mgd diff against canonical | exactly the 5 identity files |
| V12 | CHANGELOG entries added, ordering monotonic | canonical/mgd 2.44.1 → 2.44.0 → …; copilot 2.14.1 → 2.14.0 → … |
| V13 | Version bumped in every manifest | canonical + mgd `plugin.json` and `marketplace.json`; copilot `.plugin/plugin.json` and `.github/plugin/marketplace.json` |

---

## 6. Risks

**R1 — The price entry and the chain change separating.** If the chain ships without the `cost-prices.yaml` entry, every SIGNIFICANT run silently reports `cost_usd: null` (§3.1). *Mitigation:* both live in one task; V1 and V2 are checked together. This is the one ordering constraint in the pass.

**R2 — Copilot's three chain copies drifting again.** They drifted once already, in three different directions, which is how the Haiku defect survived. *Mitigation:* `model-routing.md` is named the authority and the other two cite it rather than restating it independently; V5 asserts all three are identical.

**R3 — A CHANGELOG being "fixed".** A sweep for stale model strings will hit the changelogs, and rewriting them falsifies shipped history. *Mitigation:* §4.3 excludes them explicitly, and every verification grep in §5 is scoped to exclude them.

**R4 — `gpt-5.6` not existing.** *Mitigation:* none needed — a first-available walk skips an unreachable entry (§2.6).
