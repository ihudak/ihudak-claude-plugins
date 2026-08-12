---
name: idea
description: Idea-refinement workflow (PM phase, front of the VI-creation flow). Takes one source — an inline prompt, a markdown file (with wikilinks/images), a community post, or an exported Jira ticket (product feedback, or an existing Value Increment the idea extends, parallels, or rewrites) — and, through a bounded one-question-at-a-time grill (--deep for relentless), authors a well-refined idea.md — a lean one-page brief that seeds the future /create-vi. Writes to the vault (keyless); no Jira, no code, no specs deliverable — the only `$SPECS_PATH` writes are the run's own session artifacts, committed by `commit-artifacts`.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Refine an idea into `idea.md`: $ARGUMENTS

`/idea` is the **front door of the VI-creation flow** (PM phase) — upstream of `/create-vi` (future) and
the existing pipeline. It ingests one source, refines it through a grill, and writes a lean one-page
`idea.md` (per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md`) that seeds the Value Increment. It is
**not** a VI: no Jira write, no code change, no specs-repo write. Output lands keyless in the vault;
`/create-vi` relocates it under `$SPECS_PATH` once a Jira key exists.

Flags: `--deep` switches the grill from bounded (≤5 questions) to relentless (until convergence).
`--no-docs` and `--no-prior-art` each turn off one grounding source (see Phase 1).
`--ground-code [<repo>[,<repo>…]]` grounds the idea against mounted code (see Phase 2.6) — bare it derives the repo set, with a value it scans exactly those repos.

---

## Phase 0 — Validate environment + resolve model routing

1. **Validate `$VAULT_PATH`.** It must be **set**, an **existing directory**, and **writable** — the
   env var is the user's explicit declaration of their personal store; the plugin trusts it and does
   NOT require an Obsidian `.obsidian/` marker. If any check fails, STOP and offer:
   ```
   choices: ["Enter a directory to write idea.md into", "Cancel", "Other… (describe)"]
   ```
   On a user-supplied directory, validate it exists and is writable, then use it as the **write root**
   for this run. **NEVER** write into the current working directory (it may be a code repo). This is an
   environment halt, **not** a plugin-gap halt — do NOT `emit-block`.

2. **Resolve model routing.** Invoke the `model-routing` skill (Skill tool,
   `skill: "dev-workflows:model-routing"`), then record:
   ```yaml
   model_routing:
     classification: MODERATE          # idea refinement is typically MODERATE
     reason: <one-line>
     current_model: <the model this orchestrator/grill is running under>
     detection_model: <§2.1 Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>   # idea-reader
     authoring_model: <= current_model>   # the interactive grill + idea.md authoring (session model, not a delegated subagent)
     opus_available: <true if a §2 Opus model resolved, else false>
     notes: <any §2/§2.1 fallback or degradation>
   ```
   The grill + authoring run inline on `current_model` (the §2 Opus chain — interactive judgment, not a
   delegated subagent). `idea-reader` runs on `detection_model`. If no Opus resolves, **degrade to the
   best available and record the degradation** in `notes` and the final report — do NOT hard-block (a PM
   must not be blocked from capturing an idea by a momentary Opus outage). A `--ground-code` run does
   **not** floor the classification at `SIGNIFICANT`: §1.1's multi-source floor is written for
   `/implement`, and §8.3's purpose — the strongest available model on synthesis — is already met
   here, because the grill and authoring run inline on `current_model` while the scanners run on
   `detection_model`.

**Specs-repo preflight.** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` and execute its
`specs-preflight` entry point (§3) inline: flush any leftover session artifacts from an earlier run,
retry an artifact commit that failed to push, and settle the branch. Prompt-free and silent when the
specs repo is clean and on its default branch. If a guard fires, emit its §5 notice; if it returns
`specs_git: blocked` (§3.3 G0), carry that flag for the whole run — the terminal `commit-artifacts`
step skips on it.

---

## Phase 1 — Classify the source

Classify `$ARGUMENTS` **minus every recognised flag** (`--deep`, `--no-docs`, `--no-prior-art`, `--docs <path>` with its value, and `--ground-code` with its optional comma-separated repo value) by precedence. Strip them all before classifying: an unstripped flag lands inside the `prompt` branch's raw idea text and is handed to `idea-reader` as if the user had written it.

1. Matches the Jira-key regex `^[A-Z][A-Z0-9_]*-\d+$` → resolve it with `resolve-export-for-key <KEY>`
   (`${CLAUDE_PLUGIN_ROOT}/references/jira-input-resolution.md`), then type it from the export's
   **`issue_type` frontmatter** — never from the project prefix, which is a coincidence of Jira
   configuration:
   - `ValueIncrement` → **vi** — an existing VI. Prior art the user supplied.
   - `Product Need` → **rfe** — product feedback, handled as demand evidence exactly as today.
   - anything else → name the actual `issue_type` in the confirmation below and let the user choose;
     **default vi**, since a tracked delivery item is closer to prior art than to demand evidence.

   `NOT_FOUND` from the entry point is handled as today (an environment/user halt, never `emit-block`).
2. An existing `.md` path or an `@wikilink` → **markdown** (a community post is just a markdown file,
   typically under `Projects/Products/…` — the reader tags it `community-post`; an existing `idea.md`
   passed back for re-refinement is detected here too).
3. Otherwise → **prompt** (the argument text is the raw idea).

**Confirm the classification — conditionally.** Per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` ("When a choice list fires"), a list is shown only where the answer genuinely varies. Two cases here do; the rest do not.

**A — the key resolved but its `issue_type` is neither `ValueIncrement` nor `Product Need`.** Name the actual `issue_type` in prose beside the list, never inside an option:
```
choices: ["Read this as a vi — an existing Value Increment (Recommended)", "Read this as an rfe — product feedback", "Cancel", "Other… (describe)"]
```

**B — the argument is path-like (contains `/`, ends in `.md`, or starts with `@`) but resolved to no existing file.** Without this gate it falls through precedence rule 3 to **prompt** and the path string itself becomes the raw idea text — a mistyped path silently ingested as prose:
```
choices: ["Re-enter the path (Recommended)", "Read the argument as a prompt — the literal text is the idea", "Cancel", "Other… (describe)"]
```

**Everything else** — a `.md` path or `@wikilink` that resolves, a key typed `ValueIncrement` or `Product Need`, and plain prose — is unambiguous. State the resolution in one line that invites correction and **proceed without waiting**; the list would have one plausible answer. (A dedicated `--as prompt|markdown|rfe|vi` override is future work — this inline confirmation covers a mis-detection.)

Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).

Show the `prior art:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md` resolved — `ON <vault-root>` or `OFF (<reason>)` — verbatim (off switch: --no-prior-art). Run `resolve-prior-art idea` per that reference to obtain it; it runs exactly once per run.

---

## Phase 2 — Ingest the source (idea-reader)

Dispatch `idea-reader` to read the source and return a structured digest:

→ Agent (subagent_type: "dev-workflows:idea-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Ingest this idea source and return the structured digest:
  >
  > argument:        [the resolved argument]
  > provenance_hint: [prompt | markdown | community-post | rfe | vi from Phase 1]
  > vault_path:      [resolved $VAULT_PATH]"

Wait for the digest. If `status: NOT_FOUND` (invalid key / missing file), surface:
```
choices: ["Re-enter the source", "Cancel", "Other… (describe)"]
```
This is an environment/user halt — do NOT `emit-block`. On `OK`, carry forward `raw_context`,
`signals`, `images`, `candidate_title`, `candidate_slug`, `source_refs`, `provenance`, `tracked` (a
`vi` source only), and the followed/broken wikilinks — `source_refs`/`provenance` feed the `sources:`
frontmatter entry in Phase 4, and `tracked` seeds `## Prior art`.

---

## Phase 2.5 — Grounding: documentation + vault prior art (optional)

Dispatch both grounding agents **in a single response** so they run in parallel. Each is independent; either being OFF never suppresses the other.

**Docs.** Run `resolve-docs-grounding idea` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the `idea-reader` digest's problem/outcome, `themes` = its signals; **omit `jira_key`** (idea is keyless, so the git-grep backstop is skipped). When OFF, skip silently.

**Prior art.** Using the `resolve-prior-art idea` result already obtained in Phase 1: when `prior_art: ON`, `dispatch-prior-art-finder` per `${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md` with `feature_summary` = the same problem/outcome, `themes` = the digest's signals, and `known_refs` built from the reader's digest: every `wikilinks_followed` path and every filesystem-path `source_refs` ref as `{path, has_summary: true}` (`idea-reader` already summarised them), plus — for a `vi` source — `{jira_key: <KEY>, has_summary: true}`. Passing the key rather than a path is deliberate: the orchestrator does not know which vault directory holds that VI, and resolving it is the finder's job. The supplied VI is then classified and status-resolved by the same code path as a discovered one. When OFF, skip silently.

Carry both digests into Phase 3 with **grill-rank** consumption — challenges from the two compete together for the ≤5 question slots, they do not add slots. Carry `area_proposal` and the `vi` source's match into Phase 4.

---

## Phase 2.6 — Code grounding (optional)

Runs only when `--ground-code` was given; otherwise take the OFF branch at the end of this phase. Kept separate from Phase 2.5 because the repo gate needs a user answer (which cannot happen inside a parallel dispatch) and because the scan is two-round and therefore sequential.

**1. Resolve the repo set.** With `--ground-code <repo>[,<repo>…]`, use exactly those repos and skip to step 2. Bare, derive them:

- **Cheap discovery.** List the top-level directories under each `${REPOS_PATH:-/workspace}` entry (may be colon-separated) with `ls`. Optionally attach each directory's one-line identity — `timeout 5 git -C <dir> remote get-url origin 2>/dev/null` (slug) or its README's first heading. Do **not** deep-scan to guess relevance.
- **Propose** a candidate set from the `idea-reader` digest's themes.
- **Gate** — this list's answer varies every run, so it fires unconditionally:
  ```
  choices: ["Ground the proposed set (Recommended)", "Ground a different set (you'll be prompted)", "Ground nothing — continue without a code scan", "Cancel", "Other… (describe)"]
  ```
- **Empty proposal — do not show that list.** When no theme matches any mounted repo its first option names a set that does not exist. Escalate instead per the `No repos derivable — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. Every option in a shown list must name something that exists.

Validate each resolved path is a directory; a repo that is not mounted is handled by the `Repo missing (after resolution)` rule in the same file — never invented, never silently dropped. A repo the user drops is carried to Phase 5 by name, with the themes it would have grounded left unverified.

**2. Round 1 — broad.** Spawn `code-scanner` on the confirmed set in **batches of up to 4 concurrent agents per Agent message**, on `detection_model` per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §8.3. For each repo in the batch:

→ Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Scan this repo for the brief:
  >
  > repo_path:        <resolved absolute path>
  > capability_themes: <the idea's themes from the idea-reader digest>
  > context:          <3–5 sentences: the idea's problem + desired outcome, and what a finding would change>
  > search_hints:     <symbols/paths/keywords derived from the idea, if any>"

Handle every returned status through the list `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` already carries for it — `REPO_MISSING` → *Repo missing (after resolution)*; `DIRTY_TREE` → *Dirty working tree*; `REFRESH_BLOCKED` → *Refresh blocked*. `prep.read_only: true` is **not** a failure: the scan ran at `prep.scanned_ref`; escalate per *Read-only mount — ref stale or diverged* **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`, and cite evidence at `prep.scanned_ref` either way.

**3. Round 2 — narrow.** Apply §8.5 of the model-routing reference: for each theme round 1 left **inconclusive** (`classification` `partial` / `absent` / `error`, or two scanners' `gap_summary` texts each naming the other's repo or layer), and for which round 1 produced at least one evidence anchor, dispatch `code-scanner` again with `capability_themes` holding exactly **one** question and `search_hints` seeded from that round's verified `evidence[].path`, `.symbols`, and `.lines`. Cap **4 dispatches, one round only** — there is no round 3, and a theme still inconclusive is carried to Phase 4 as a `[NEEDS CLARIFICATION]`, never guessed at.

**OFF branch** (no `--ground-code`). Run one detection and print at most one line. Tokenise the raw argument and the digest's `raw_context`; match tokens case-insensitively against the basenames of the **git repositories** (a `.git` entry present) directly under each `${REPOS_PATH:-/workspace}` entry, excluding `$DOCS_PATH`, `$SPECS_PATH`, and `$VAULT_PATH`. Exact token match only — no substring, no stemming. On ≥1 match print:

```
This idea names <repo>; re-run with --ground-code to verify it against the code.
```

and **proceed without waiting** — an inline confirmation per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` ("When a choice list fires"), not a gate. No match ⇒ silent. There is no auto-trigger: grounding is up to eight scanner dispatches and starts only on the user's explicit flag.

---

## Phase 3 — Refine via grill

**Interview technique (grilling — embedded; no runtime dependency).** Follow the shared technique in `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split (look up facts from the `idea-reader` digest / vault, put only decisions to the user), walk the design tree in dependency order. **Depth: bounded by default (below); `--deep` = relentless.**

Scan for gaps against an idea-stage **ambiguity taxonomy**: *problem clarity, target users, desired
outcome/value, scope boundaries, evidence/demand sufficiency, success signal, terminology.* Rank gaps by **Impact × Uncertainty**, ranking every `docs_challenges` and `prior_art_challenges` entry from Phase 2.5 into that same list. Challenges **compete** for the slots below; they never add slots.

- **Default (bounded):** ask **≤5** questions across the ranked gaps, then stop. Remaining high-impact
  gaps become `- [NEEDS CLARIFICATION: <question>]` in the `idea.md` **Open questions & assumptions**
  section, **capped at 3**; reasonable defaults are recorded as `- **Assumption:** <text>`.
- **`--deep`:** relentless — keep walking the design tree one question at a time until you and the user
  reach shared understanding; the cap does not apply.

---

## Phase 4 — Write idea.md

Author `idea.md` per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` into the write root resolved in
Phase 0, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`:

- **Path (container default):** `<container(source path)>/<candidate_slug>/idea.md`, where the container
  is derived per `${CLAUDE_PLUGIN_ROOT}/references/vault-prior-art.md`. A source already sitting under a
  `Projects/Products/` grouper lands beside its neighbours in that grouper; an inline prompt, a Jira key
  with no vault item, and any source outside `Projects/Products/` all resolve to `Projects/ideas/`
  exactly as before.
- **Write-path gate.** Assemble **one** `choices:` array, in this row order, and present it verbatim:

  | Row | Included when | Text |
  |---|---|---|
  | 1 | `provenance: vi` | `Rewrite <KEY> — reuse its Jira key; write into <item-dir>/` when the finder resolved one, else `Rewrite <KEY> — reuse its Jira key; write to <container default>/<candidate_slug>/` |
  | 2 | `area_proposal.path` non-null, `confidence: high`, **and** it differs from the container default | `New idea under <area_proposal.path>/<candidate_slug>/` |
  | 3 | always | `New idea — a new Jira key will be minted; write to <container default>/<candidate_slug>/ as detected` |
  | 4 | always | `Enter a different path` |
  | 5 | always | `Cancel` |
  | 6 | always | `Other… (describe)` |

  The gate **fires only when at least one of rows 1–2 is present**; otherwise the container default
  applies silently. Append `(Recommended)` to **exactly one** row, chosen by the **top match** — the
  `prior_art` entry with the highest `match_confidence`, ties broken by array order — and its
  `relation`: `supersedes_self` → row 1 **when present, else row 3**; every other relation → row 2
  when present, else row 3. `supersedes_self` needs its own fallback because it is reachable for **any**
  `known_refs` entry — a `markdown` source that wikilinks a VI work document can carry it — while row 1
  ships only for `provenance: vi`.
  **When there is no top match at all — prior-art grounding OFF, an invalid `$VAULT_PATH`, a non-vault
  write root, or the finder returning `EMPTY` — recommend row 3.** That state is reachable precisely
  because row 1 fires on `provenance: vi` alone, and nothing is then known about whether this is a
  rewrite; the neutral default is the one that mints no Jira key. Every branch must name a row that is
  actually in the array, or the gate renders with nothing marked. Never recommend row 1 without
  `supersedes_self` — extending and paralleling a VI are as common as rewriting one, and a wrong
  default here silently mints or fails to mint a Jira key. Validate every chosen path sits inside the
  resolved write root and is writable.

  Record the choice as **`vi_disposition`** — `rewrite` for row 1, `new` for every other row — and carry
  it into Phase 5. **When the gate does not fire at all, `vi_disposition` is `new`.** Row 1 keys only on
  `provenance: vi`, never on the finder resolving anything, so a `vi` source always reaches this question
  even when prior-art grounding is OFF or the key has no vault work document — the disposition decides
  whether the user is told to mint a Jira key, which is not an advisory matter and must not depend on an
  advisory, user-disableable subsystem. This is the only point in the flow where the three shapes of a supplied VI (extend,
  parallel, rewrite-in-place) can be told apart.
- **`## Prior art`:** write the section per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` when
  Phase 2.5 returned any `prior_art` entry **or** the source is `vi`; omit it entirely otherwise. A `vi`
  source contributes its Phase 2 `tracked` block (key, status, summary) even when prior-art grounding is
  OFF — it is prior art the user handed over, not something the finder discovered — and appears there
  **and** in `sources:`. Merge by Jira key so a supplied VI the finder also matched yields one bullet: the finder's entry wins,
  because it is a strict superset of `tracked` (it adds `relation`, `match_reason`, and a vault path). A
  finder match with `jira_key: null` cannot collide — a supplied VI always has a key.
- **Existing file:** if `idea.md` already exists at that path, offer:
  ```
  choices: ["Refine the existing idea.md (Recommended)", "Create a new one (you'll be prompted for a slug)", "Cancel", "Other… (describe)"]
  ```
  On *refine*, re-open it, resolve its open `[NEEDS CLARIFICATION]` items, and append the new source
  (`{provenance, ref}` built from Phase 2's `provenance` and `source_refs`) to `sources`.
- **`status`:** set frontmatter `status: refined` IFF zero `[NEEDS CLARIFICATION]` markers remain;
  otherwise `status: draft`.

---

## Phase 5 — Handoff: adaptive next-phase offer

Report where `idea.md` was written and its `status`, then offer the next phase — **adapted to status**:

- **`refined`, `vi_disposition: new`** (and every run with no `vi` source): *"Idea refined. Next: create
  the VI — first create an empty Jira workitem, then run `/dev-workflows:create-vi <JIRA-KEY> @<idea.md
  path>`."*
- **`refined`, `vi_disposition: rewrite`:** *"Idea refined. Next: `/dev-workflows:create-vi <KEY>
  @<idea.md path>` — this rewrites the existing VI, so no new Jira workitem is needed. If an authored VI
  already exists for `<KEY>`, `/create-vi` will redirect you to `/dev-workflows:update-vi <KEY>`."*
- **`draft`** (N open clarifications): *"This idea has N open clarification(s). You can (a) run
  `/dev-workflows:idea @<idea.md path> --deep` to resolve them, or (b) proceed to
  `/dev-workflows:create-vi <KEY-or-JIRA-KEY> @<idea.md path>`, which will grill you on the rest."* Use
  the same `vi_disposition` clause as above when a `vi` source was given.

Also report any prior art found — matched keys with their statuses, and the alternative container path
when one exists — **whether or not the gate fired**, so the user can relocate before `/create-vi` makes
the path sticky.

`/create-vi` is a separate command; this offer is guidance the user acts on — it never auto-invokes
another command. (Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — the plugin-wide
next-phase-offer contract; `/idea` is one reference implementation.)

### Context hygiene

Continuing to `/dev-workflows:create-vi` (still the PM phase)? → run **`/compact`** to free context; your
`idea.md` is already on disk. (No resume pointer or `/rename` label here — the VI-Key is
minted later, and the ideation phase is short.) Guidance only — see
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.

---

## Phase 6 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 5, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference
gap** (a capability the run needed but the plugin lacked), `emit-block` (per
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating — so a run
abandoned at the block still records the gap. NEVER `emit-block` for an environment / user halt (bad
`$VAULT_PATH`, source-not-found, cancellation).

**Session-hygiene invariant.** End Phase 5 with a `### Context hygiene` note per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — a same-role `/compact` suggestion
(no `resume.md`, no `/rename`: pre-VI, short PM phase). Guidance only, never auto-run.

1. **Invoke `impl-maintenance`** (subagent_type: "dev-workflows:impl-maintenance", model: `<detection_model — §2.1 Sonnet chain>`):
   > "Analyse this session and return a Lessons Learned report.
   >
   > Session handoff:
   > - Command run: /idea
   > - What was done: [one-paragraph summary of the idea refined + source type]
   > - Key events: [source-detection corrections, unresolved clarifications, broken wikilinks — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: N/A (no reviewer in /idea)
   > - Test result: N/A (no tests in /idea)
   > - Project root: [the idea.md folder]"
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /idea`, `jira_key: null`, the run's `source`, and
   `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It renders only the
   plugin-facing slice (§4), dedupes by stable `id` (§3), resolves the target via the §2 specs-first
   ladder, and writes silently. Surface the persisted path (or "no plugin-facing signal — nothing
   persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its
   `emit-cost` entry point with `command: /idea`, `phase: vi-creation`, `role: pm`, `jira_key: null`,
   the run's `source`, and `plugin_version`. A keyless run writes to the pending ladder (§9) and
   **advances the chained checkpoint** (§3); surface the persisted path (or the report-only notice).
4. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`
   and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages
   ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `NOISSUE Add dev-workflows
   session artifacts (/idea)` (this run is keyless — no VI-Key exists yet), and pushes. It NEVER
   touches a code/docs repo, the vault, or the current working directory; NEVER force-pushes; NEVER
   fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting
   that notice. Hold its §6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (idea.md carries no git offer
of its own — the terminal step above commits only the bounded session-artifact paths in `$SPECS_PATH`),
and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the `idea.md` path + `status` (refined / draft with N open clarifications); the source type and
`sources`; the count of `[NEEDS CLARIFICATION]` items and Assumptions; any source-detection correction
or broken wikilinks; the resolved model routing (+ any Opus degradation); the feedback path; the cost
path (or notice); the `Specs repo:` outcome line from `commit-artifacts`
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; any
prior art found (keys + statuses), any `status_conflict` a match reported (both values and the export's
date — it is the signal that catches a broken sync) and any `notes` the finder returned; the resolved
`vi_disposition`; and the adaptive next-phase recommendation.
