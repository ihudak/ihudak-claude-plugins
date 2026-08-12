# `/idea` code grounding + choice-gate polish — design

**Sub-project H** of the 2026-08-07 PM feedback round on `dev-workflows`, and the last of it. Closes the final 2 of the 7 open entries in the 2026-08-06 `/idea` round (`$SPECS_PATH/dev-workflows-feedback/2026-08-06.md`):

- `2026-08-06-idea-code-grounding` (missing-capability, friction)
- `2026-08-06-idea-phase1-confirmation-gate-ambiguity` (ambiguous-prompt, polish)

Ships as dev-workflows **2.49.0** (canonical + mgd) / **2.19.0** (copilot).

The two entries share a command and nothing else. One adds a capability to `/idea`; one settles a convention that binds the whole plugin. They ship together because both rewrite `/idea` Phase 1–2.x text and splitting them would mean two passes over the same paragraphs.

Branch `iv-gu/idea-code-grounding` forks from `iv-gu/vault-prior-art` (sub-project G's tip), not from `main` — H edits Phase 1 and Phase 2.5 text that G rewrote days ago and that is not yet merged.

---

## 1. Premise corrections

Two claims in the feedback do not survive contact with the tree. Both are recorded here because the design would be different if either held.

**1.1 — `/idea` never declared "no code scan".** The entry quotes `/idea` as *"Product-level (no code scan)"*. That string appears in `create-vi.md:3`, `create-vi.md:37`, `update-vi.md:3`, `update-vi.md:26`, and `vi-source-resolution.md:30` — never in `idea.md` and never in `/idea`'s README row. What `/idea` actually says is "no Jira write, no code change, no specs-repo write" (`idea.md:12`) — a statement about **writing**, not scanning. So `--ground-code` relaxes no stated principle and needs no exemption clause; it is purely additive. The spec must not claim otherwise, and `/create-vi` and `/update-vi` keep their declarations intact (§6).

**1.2 — the "recurring judgment call" does not need 188 labels.** The entry asks for explicitness about "which of the command's `choices:` blocks are hard gates and which are informational". There are **188** `choices:` blocks across `commands/` (154) and `references/` (34). Labelling each is not the fix, because `references/escalation-rules.md` already owns two plugin-wide binding rules about choice lists and a third settles the question for all 188 at once by supplying the **default**. Only sites whose *written* default is wrong then need touching (§2).

---

## 2. Entry (2) — when a choice list fires

### 2.1 The rule

`references/escalation-rules.md` gains a third binding section, placed after *"The `(Recommended)` marker is unconditional"* and before *"Jira key dir not found"* — i.e. with the other two rules that bind the plugin, above the catalogue of per-scenario lists.

**[R1]** The section is titled **`## When a choice list fires`** and states four things:

1. **A choice list blocks whenever it is shown.** Presenting one and continuing without an answer is never correct — the list *is* the wait.
2. **A list is shown only when its firing condition holds.** A list with no written condition is shown every time its phase runs. That is the default and it is right for most phases.
3. **A list written for a question whose answer is already determined is a defect**, not a formality — it spends a user turn on a prompt with one plausible answer. Where the answer is determined on some runs and open on others, write the firing condition and keep the list for the open runs.
4. **The inline-confirmation form.** When the answer is determined, state the resolution in one line that names what was resolved and how to correct it, then proceed without waiting. An inline confirmation carries **no `choices:` array**, never waits, and the run continues on the stated resolution.

**[R2]** The section closes with the same binding clause the other two carry: *"This rule binds every command in the plugin, not only the ones documented below."*

**[R3]** The rule is consistent with the two rules above it and must not restate them. In particular it does not touch option wording, option order, or the `(Recommended)` marker — only *whether the list is presented at all*. The existing rule "the condition **gates the prompt** (the list is only shown in that case)" is the same idea seen from the marker's side; the new section is where that idea is stated in its own right, and the marker rule's phrasing stays as it is.

### 2.2 The site the feedback names — `/idea` Phase 1

Post-G, Phase 1 classifies by precedence (Jira key → `.md` path/`@wikilink` → prompt) and then unconditionally presents one list. Two of its cases are genuinely open and the rest are determined.

**[R4]** Phase 1's confirmation becomes conditional, with **two** lists, each carrying its firing condition:

| # | Fires when | List |
|---|---|---|
| A | the key resolved, but its `issue_type` is neither `ValueIncrement` nor `Product Need` | `choices: ["Read this as a vi — an existing Value Increment (Recommended)", "Read this as an rfe — product feedback", "Cancel", "Other… (describe)"]` |
| B | the argument is **path-like** — contains `/`, ends in `.md`, or starts with `@` — but resolved to no existing file | `choices: ["Re-enter the path (Recommended)", "Read the argument as a prompt — the literal text is the idea", "Cancel", "Other… (describe)"]` |

List A already exists in substance: G added the `issue_type` fallback and told the orchestrator to "name the actual `issue_type` in the confirmation below and let the user choose; **default vi**". R4 keeps that behaviour and moves it into its own list, so the fallback's default is expressed as the `(Recommended)` marker rather than as prose the orchestrator has to translate into a list at runtime. The unexpected `issue_type` is named in the prose beside the list, never inside an option — choice lists are presented verbatim, so their options carry no per-run values.

**[R5]** List B is new, and it fixes a defect the feedback did not identify. Today a path-like argument that resolves to nothing falls through precedence rule 3 to **`prompt`**, and the path string itself becomes the raw idea text handed to `idea-reader`. A mistyped path is silently ingested as prose. `(Recommended)` sits on *Re-enter the path* because a path-shaped argument that does not resolve is far more often a typo than prose.

**[R6]** In every other case — a `.md` path or `@wikilink` that resolves, a key typed `ValueIncrement` or `Product Need`, and plain prose — Phase 1 states the resolution in one line that invites correction and **proceeds without waiting**, citing `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` "When a choice list fires". The parenthetical about a future `--as` override stays; it now sits with the inline form, which is what it actually covers.

### 2.3 The targeted sweep

**[R7]** Grep the other twenty commands for the one linguistic marker of a vacuous confirmation — a choice list whose lead-in is a *confirm/surface-a-confirmation* verb rather than a conditional — and fix only what that finds. Concretely: `grep -n -B4 'choices:' commands/*.md` filtered to lead-ins matching `confirm|confirmation` with no `if|when|unless|on <status>` in the same lead-in.

**[R8]** A site found by R7 is fixed the same way as Phase 1: name the firing condition, or convert to the inline form. A site whose list is already conditional, or whose answer genuinely varies every run, is **left alone** and is not annotated — R1's default already covers it, and annotating 180 correct sites is the labelling job §1.2 rejected.

**[R9]** If R7 finds nothing beyond `/idea`, that is the honest outcome and is recorded as such. The rule still lands, because Phase 1 is its consumer — this is not a dead gate.

### 2.4 A shared list whose options do not fit its trigger

Found while verifying R16's citation, and in scope because R16 would otherwise ship `/idea` a broken gate.

**[R9a]** `escalation-rules.md`'s `## Repo missing (after resolution)` carries `choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel"]` — byte-identical to the `## Dirty working tree` list above it, and wrong for its own trigger. `REPO_MISSING` means `repo_path` is not a directory, **or** the repo's `origin` slug does not match `repo_url_slug`. Stashing changes cannot help either case; there is nothing to stash and nothing to retry. The list reads as a copy-paste from its neighbour.

**[R9b]** It is replaced with options that fit the trigger, mirroring the `## Repo unresolved (zero matches)` list that already handles the same situation one phase earlier:

```
choices: ["Skip this repo", "I'll clone it — wait", "Specify a different absolute path for this repo", "Cancel", "Other… (describe)"]
```

*Specify a different absolute path* is the option that resolves the slug-mismatch half of the trigger, which the current list has no answer for at all. No `(Recommended)` marker: which option is right depends entirely on why the repo is absent.

**[R9c]** **Six** commands cite this rule by name — `/create-ard`, `/document`, `/epics`, `/release-notes`, `/specify`, and (after R16) `/idea`. None is edited: they cite the rule, so fixing the rule fixes all six. That is the check — after the change, the six citations still resolve and no command inlines a competing copy of the old list.

---

## 3. Entry (1) — `--ground-code`

### 3.1 The flag and the nudge

**[R10]** `/idea` accepts `--ground-code [<repo>[,<repo>…]]`. Bare, it derives the repo set (§3.2); with a value, it uses exactly the named repos and runs no derivation.

**[R11]** Phase 1's flag-stripping list gains `--ground-code` **and its optional value**. It currently strips `--deep`, `--no-docs`, `--no-prior-art`, and `--docs <path>`. An unstripped flag lands inside the `prompt` branch's raw idea text and is ingested as if the user had written it — the exact failure Phase 1 already warns about.

**[R12]** When `--ground-code` is absent, `/idea` runs **one** detection, in **one** place (Phase 2.6, §3.3), and prints at most one line:

> `This idea names <repo>; re-run with --ground-code to verify it against the code.`

It proceeds without waiting — an inline confirmation per R1.4, not a gate.

**[R13]** The detection rule is bounded and stated so it cannot match half the workspace. Tokenise the raw argument and the `idea-reader` digest's `raw_context`; match tokens case-insensitively against the **basenames of git repositories** (a `.git` entry present) directly under each `${REPOS_PATH:-/workspace}` entry (may be colon-separated); exclude `$DOCS_PATH`, `$SPECS_PATH`, and `$VAULT_PATH`. Exact token match only — no substring, no stemming. No match ⇒ silent. Git-repo-only plus exact-token is what keeps `docs`, `specs`, and `vault` from matching nearly every idea.

**[R14]** There is no auto-trigger. A detected repo reference produces the line in R12 and nothing else. Grounding is expensive (up to eight `code-scanner` dispatches) and starts only on the user's explicit flag.

### 3.2 Choosing the repos

**[R15]** With `--ground-code` bare, the repo set is derived on `/create-ard`'s pattern — the only precedent that fits a keyless command with no PR URLs to derive from:

1. **Cheap discovery.** `ls` the top-level directories under each `${REPOS_PATH:-/workspace}` entry. Optionally attach each directory's one-line identity (`timeout 5 git -C <dir> remote get-url origin 2>/dev/null`, or its README's first heading). Do **not** deep-scan to guess relevance.
2. **Propose** a candidate set from the `idea-reader` digest's themes.
3. **One consolidated gate** — this list's answer genuinely varies every run, so it fires unconditionally and R1's default applies:
   `choices: ["Ground the proposed set (Recommended)", "Ground a different set (you'll be prompted)", "Ground nothing — continue without a code scan", "Cancel", "Other… (describe)"]`
4. **Fan out on the confirmed set**, capped at 4 concurrent (§3.4).

**[R15a]** When the proposal is **empty** — no theme matches any mounted repo — the R15.3 list is not shown at all. Its first option would name a set that does not exist, which is exactly the unreachable-guard shape this project has shipped four times. `/idea` escalates instead on the existing `## No repos derivable — /epics` list in `escalation-rules.md`, as `/specify` Phase 3 already does. Every option in a shown list must name something that exists.

**[R16]** A repo named on the flag or in the proposal that is not mounted is handled by the existing `## Repo missing (after resolution)` list in `escalation-rules.md` — never invented, never silently dropped.

**[R17]** A repo the user drops is named in the Phase 5 handoff and the Final report, with the themes it would have grounded left unverified. It never silently disappears.

### 3.3 Phase 2.6 — Code grounding (optional)

**[R18]** Code grounding is a **new Phase 2.6**, after Phase 2.5, not folded into it. Phase 2.5's two-way parallel dispatch (docs-grounder + vault-prior-art-finder, G's, single response) is left exactly as it is. The reasons are structural, not stylistic: the repo gate (R15.3) needs a user answer, which cannot happen inside a parallel dispatch; and the code round is inherently sequential (§3.4), so it cannot fully parallelise with the other two anyway. Isolating it also means a run without the flag reaches an unchanged Phase 2.5.

**[R19]** Phase 2.6 has exactly two branches. **ON** (`--ground-code` present): the repo gate, then round 1, then the conditional round 2. **OFF**: the R12/R13 detection, then continue.

**[R20]** Every `code-scanner` status is handled with the list `escalation-rules.md` already carries for it — `REPO_MISSING` → *Repo missing (after resolution)*, `DIRTY_TREE` → *Dirty working tree*, `REFRESH_BLOCKED` → *Refresh blocked*, and a read-only mount whose ref is stale or diverged → *Read-only mount — ref stale or diverged*. Sub-project F found that `/create-ard` and `/release-notes` dispatch these agents with **no** failure handling; `/idea` does not join them.

**[R21]** Classification stays **MODERATE**. §1.1's multi-source SIGNIFICANT floor is already written as `/implement`-specific ("`/implement` was given more than one code repository…"), so there is no contradiction to resolve. §8.3's purpose — the strongest available model on synthesis — is already met: `/idea`'s grill and authoring run inline on `current_model` (the §2 Opus chain). Phase 0's `model_routing` block gains one clause saying so, because a reader who knows §8 will otherwise read the fan-out and expect the floor.

### 3.4 The two-phase shape — `model-routing/classification.md` §8.5

**[R22]** `references/model-routing/classification.md` gains **§8.5 — Broad, then narrow**, after §8.4 (Honesty). It describes a second, seeded round, generically, because the lesson is not `/idea`-specific.

**[R23]** §8.5 defines **inconclusive**: a theme whose round-1 `classification` is `partial`, `absent`, or `error`, **or** for which two scanners' `gap_summary` texts each name the *other's* repo or layer as the likely location. The second condition is the failure the source run actually hit — two broad per-layer scans that both answered "the restriction must be in the other layer".

**[R24]** **Round 2 fires** for an inconclusive theme when round 1 produced at least one evidence anchor to seed from. It dispatches the **same** `code-scanner` agent with a narrowed brief — `capability_themes` holds **one** question, and `search_hints.paths` / `.symbols` / `.keywords` are seeded from round 1's verified `evidence[].path`, `.symbols`, and `.lines`. No new agent and no input-contract change: the narrowing is entirely in what the caller puts in the existing fields.

**[R25]** Round 2 is capped at **4 dispatches** and is **one round only**. There is no round 3. A theme still inconclusive after round 2 is reported unresolved and becomes a `[NEEDS CLARIFICATION]` in `idea.md`; it is never guessed at.

**[R26]** §8.5 states that it is a **shared procedure a caller opts into by saying so**, and names `/idea` as its first and only current consumer. This is explicit so the section is not read as silently rebinding `/implement`, `/epics`, `/create-ard`, `/specify`, or `/design`, none of which are edited by this sub-project.

**[R27]** §8.5 records *why*: a broad prompt lets each scanner defer to the layer it did not scan; naming a verified anchor removes that escape. Without the reason the shape reads as ceremony and the next editor deletes it.

### 3.5 `file:line` anchors — `code-scanner`'s output contract

**[R28]** `references/handoff/code-scanner.md` adds an optional `lines: [<n>]` to each `capability_map[].evidence[]` entry, and `agents/code-scanner.md` populates it when the match came from a grep hit (`grep -n` returns the number natively). Absent when the evidence came from a path glob or a whole-file read.

**[R29]** The field is **additive and optional**: `/epics`, `/implement`, `/create-ard`, `/specify`, and `/design` are not edited and simply ignore it. The contract's existing sentence about `evidence.path` being relative to the repo root and denoting content at `scanned_ref` extends to `lines` — a line number is only meaningful together with the ref it was read at.

### 3.6 How findings are consumed

**[R30]** In Phase 3's grill, code findings are **facts, not questions**: they answer gaps from the ambiguity taxonomy rather than raising new ones, and they are cited in the artifact.

**[R31]** The one exception is the payoff. A finding that **contradicts the idea's premise** — the capability already exists, or the gap is orders of magnitude smaller than the idea assumes — becomes a challenge ranked into the existing Impact × Uncertainty gap list, on G's `grill-rank` mechanism. Like every other challenge it **competes** for the ≤5 question slots and never adds one. Cap: at most **2** such challenges.

This is the mechanism that pays for the whole feature. In the source run it reframed an idea from "multi-sprint capability gap" to "one stale config value (`"distinct": true` on one entity type's tag filter, where every other entity type sets `false`)" — a one-line fix plus a UX decision. Without it `idea.md` would have confidently described a feature that did not need building.

### 3.7 Where findings land — `references/idea-format.md`

**[R32]** `idea-format.md` gains **Section 7, `## Feasibility grounding`**, between `## Prior art` (6) and `## Open questions & assumptions`; the two sections after it renumber 7→8 and 8→9. The order reads as a progression: why it matters (5, demand) → what is already tracked (6) → what already exists in code (7) → what is unknown (8) → how we would know it worked (9).

**[R33]** It is **optional with the same discipline as `## Prior art`**: written when code grounding ran **and** returned at least one finding; **omitted entirely** otherwise. A grounded run that found nothing writes no empty section and no "nothing found" line.

**[R34]** Its head records what the claims were true of: `<repo>@<scanned_ref>` for each grounded repo, from `code-scanner`'s `prep.scanned_ref` (always present, per F). Code moves; a finding with no ref is unfalsifiable a month later.

**[R35]** It carries three slots, each optional, each omitted when empty:

- **What exists** — capability present today.
- **What's missing** — the gap, characterised.
- **Reframing** — one line, written only when a finding contradicted the idea's premise: the framing the source implied, and the framing the code supports.

**[R36]** Every bullet carries a repo-qualified citation `<repo>/<path>:<line>` — the **first** entry of that evidence's `lines` — or `<repo>/<path>` when the entry has no `lines` (R28 leaves it absent for glob and whole-file matches). A bullet with no citation is not written: a feasibility claim without an anchor is the thing this section exists to prevent.

**[R37]** Nothing speculative goes here. A theme the scan could not resolve is a `[NEEDS CLARIFICATION]` in Section 8, not a hedged bullet in Section 7.

**[R38]** Section 5 (`## Signals & evidence`) gains one closing rule: **code findings never go here** — this section is demand evidence only; feasibility findings belong in Section 7. That sentence is the direct fix for the feedback's complaint that findings "were folded into `Signals & evidence`, which the format defines as *demand* evidence only".

### 3.8 Reporting

**[R39]** Phase 5's handoff and the Final report gain: the grounded repos with their `scanned_ref`s, any repo descoped or unmounted with the themes left unverified, any theme still inconclusive after round 2, and the reframing line when one was written. A reframing that changed the idea's Problem section is the single most consequential thing a run can produce and must not be reported only inside the file.

---

## 4. Files touched

Canonical (`/workspace/ihudak-claude-plugins/plugins/dev-workflows/`):

| File | Change |
|---|---|
| `references/escalation-rules.md` | **new section** `## When a choice list fires` (R1–R3); `## Repo missing (after resolution)` list replaced (R9a–R9c) |
| `commands/idea.md` | Phase 1 conditional confirmation + list B (R4–R6, R11); Phase 0 MODERATE clause (R21); **new Phase 2.6** (R12–R20); Phase 3 consumption (R30–R31); Phase 4 writes §7 (R32–R37); Phase 5 + Final report (R39); `Flags:` line |
| `references/model-routing/classification.md` | **new §8.5** Broad, then narrow (R22–R27) |
| `references/handoff/code-scanner.md` | optional `lines: [<n>]` on `evidence[]` (R28–R29) |
| `agents/code-scanner.md` | populate `lines` from grep hits (R28) |
| `references/idea-format.md` | new Section 7 + renumber 7→8, 8→9 (R32–R37); Section 5 closing rule (R38) |
| `README.md` | `/idea` usage cell gains `--ground-code`, `--no-docs`, `--no-prior-art`; row body mentions code grounding; new **Code grounding** paragraph beside the docs / prior-art pair |
| `CHANGELOG.md` | 2.49.0 entry |
| `.claude-plugin/plugin.json` | 2.49.0 |
| `/CLAUDE.md` (repo root) | `/idea` workflow-map line gains the scanner fan-out; §8.5 named in the model-routing paragraph |
| ~0–N other `commands/*.md` | whatever R7's sweep finds (R8–R9) |

Ports: **mgd** content-verbatim except its identity files — the divergence set is verified empirically at port time rather than assumed, because the recorded count has been five and six at different times. **copilot** adapted per the four dialect rules, own version track (2.19.0), `skills/<name>/` for commands and `skills/_shared/` for references (`model-routing.md` flattened, not `model-routing/classification.md`). Never `cp` into copilot.

## 5. Verification

No test framework — verification is grep, diff, and reading. The plan carries the numbered table; the shape:

- Every `R` above has at least one check.
- **Flag stripping (R11):** `--ground-code` appears in Phase 1's strip list, in the `Flags:` line, and in the README usage cell — three sites, and a miss in the first is a live defect (an unstripped flag becomes idea text). The frontmatter `description` names only `--deep` today and is left that way; `--no-docs` and `--no-prior-art` are absent from it too, and this spec does not change that convention.
- **Renumbering (R32):** `idea-format.md` has exactly one `## Section N` per N for 1–9, no duplicates and no gaps, and every cross-reference to "Section 7"/"Section 8" elsewhere in the plugin still resolves.
- **No silent rebinding (R26):** `/implement`, `/epics`, `/create-ard`, `/specify`, `/design` are byte-identical except where this spec names them.
- **Three-repo parity:** identical content in canonical and mgd outside mgd's identity set; zero dialect leaks in copilot — no slash-form command names, no `→ Agent (subagent_type:`, no `${CLAUDE_PLUGIN_ROOT}`, no `§2.1 Sonnet chain`.
- **Residue (the standing question):** not "did my rule land everywhere" but **"what did I make false?"** — every statement about `/idea`'s phase count, its grounding sources, `idea-format.md`'s section count, and `code-scanner`'s output contract, in all three repos.

## 6. Non-goals

- **`/create-vi` and `/update-vi` keep "Product-level: no code scan, no repos."** It is stated in five places and stays true; neither command is edited.
- **No `--ground-code` on `/specify` or `/design`** — both already scan code.
- **No auto-trigger** (R14), **no round 3** (R25), **no new agent** (R24).
- **No labelling pass over the other ~180 `choices:` blocks** (§1.2, R8).
- **No change to `/implement`'s fan-out** — §8.5 is opt-in (R26).
- **`--build-docs-index`** and the other deferred items from earlier sub-projects stay deferred.
