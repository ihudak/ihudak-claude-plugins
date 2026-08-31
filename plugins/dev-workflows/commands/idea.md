---
name: idea
description: Idea-refinement workflow (PM phase, front of the PRD-creation flow). Takes one source — an inline prompt, a markdown file (with wikilinks/images), a community post, or a saved file (product feedback, or an existing Product Requirements Document the idea extends, parallels, or rewrites) — and, through a bounded one-question-at-a-time grill (--deep for relentless), authors a well-refined idea.md — a lean one-page brief that seeds the future /create-prd. Writes into the PRD folder the key names; no code change; it relocates `idea.md` into `$SPECS_PATH/specifications/<KEY>-<slug>/`, and on a completed handoff also opens a pull request for it (`references/phase-handoff.md` §2) — declining leaves it relocated but not on the default branch; its session artifacts are committed by `commit-artifacts`.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Refine an idea into `idea.md`: $ARGUMENTS

`/idea` is the **front door of the PRD-creation flow** (PM phase) — upstream of `/create-prd` (future) and
the existing pipeline. It ingests one source, refines it through a grill, and writes a lean one-page
`idea.md` (per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md`) that seeds the Product Requirements Document. It is
**not** a PRD: no code change. Output lands in the PRD folder the key names, on the first write and never relocated.

Flags: `--deep` switches the grill from bounded (≤10 questions) to relentless (until convergence).
`--no-docs` turns off documentation grounding (see Phase 1).
`--ground-code [<repo>[,<repo>…]]` grounds the idea against mounted code (see Phase 2.6) — bare it derives the repo set, with a value it scans exactly those repos. The token after `--ground-code` is its value **only** when it contains no whitespace and every comma-separated part matches a top-level directory basename under `${REPOS_PATH:-/workspace}`; otherwise the flag is bare and the token is idea text.

---

## Phase 0 — Resolve the address + model routing

1. **The address (mandatory).** Parse the first non-flag token and validate it with `key-valid`
   (`${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §1). Absent or malformed → stop:
   `IDEA_NEEDS_KEY: /idea needs a PRD key (^[A-Z][A-Z0-9_]*(-\d+)+$, e.g. ACME-77) — it names the folder this idea will live in. Re-run '/dev-workflows:idea <PRD-KEY> [<prompt>|@<file>]'.`

   **The key is an argument because there is nowhere keyless to write.** `idea.md` lands in its final
   folder on the first write — `PRD-<KEY>-<slug>/` under `$SPECS_PATH/specifications/`, resolved with
   `resolve-address` and created there when absent (`addressing.md` §2, §3). It is never relocated
   afterwards, and `/create-prd <KEY>` finds it there.

   **Validated for shape and checked against nothing**, exactly as `/brd-intake <BRD-KEY>` already
   asks. Nothing looks a key up, because there is nothing to look it up in.

   **Accepted cost:** an abandoned idea leaves a folder in `specifications/`. Reintroducing a staging
   area to avoid that would restore the relocation step this removes.
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

Classify `$ARGUMENTS` **minus every recognised flag** (`--deep`, `--no-docs`, `--docs <path>` with its value, and `--ground-code` with its optional comma-separated repo value) by precedence. Strip them all before classifying: an unstripped flag lands inside the `prompt` branch's raw idea text and is handed to `idea-reader` as if the user had written it. The token after `--ground-code` is its value **only** when it contains no whitespace and every comma-separated part matches a top-level directory basename under `${REPOS_PATH:-/workspace}`; otherwise the flag is bare and the token is idea text — strip only the flag itself.

1. An existing `.md` path → **markdown** (a community post is just a markdown file,
   typically under `Projects/Products/…` — the reader tags it `community-post`; an existing `idea.md`
   passed back for re-refinement is detected here too).
2. Otherwise → **prompt** (the argument text is the raw idea).

**There is no tracker-export source type, and there is no third classification.** A key used to
resolve an export and be typed from a frontmatter field on it; nothing exports anything now, so an
existing PRD reaches `/idea` the way every other file does — as a path — and `/create-prd --from-prd`
is the route that seeds one PRD from another. **Case A of the confirmation below went with it**: it
asked which of two tracker item types an unrecognised one should be read as, and there are no item
types to disambiguate.

**Confirm the classification — conditionally.** Per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` ("When a choice list fires"), a list is shown only where the answer genuinely varies. Two cases here do; the rest do not.

**B — the argument is path-like (contains `/`, ends in `.md`, or starts with `@`) but resolved to no existing file.** Without this gate it falls through precedence rule 3 to **prompt** and the path string itself becomes the raw idea text — a mistyped path silently ingested as prose:
```
choices: ["Re-enter the path (Recommended)", "Read the argument as a prompt — the literal text is the idea", "Cancel", "Other… (describe)"]
```

**Everything else** — a `.md` path that resolves, and plain prose — is unambiguous. State the resolution in one line that invites correction and **proceed without waiting**; the list would have one plausible answer. (A dedicated `--as prompt|markdown|rfe|prd` override is future work — this inline confirmation covers a mis-detection.)

Show the `docs grounding:` line in the form `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md` resolved — `ON <root> (retrieval: …)` or `OFF (<reason>)` — verbatim, including any index-build, staleness, or shadowing clause it carries (off switch: --no-docs).


---

## Phase 2 — Ingest the source (idea-reader)

Dispatch `idea-reader` to read the source and return a structured digest:

→ Agent (subagent_type: "dev-workflows:idea-reader", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Ingest this idea source and return the structured digest:
  >
  > argument:        [the resolved argument]
  > provenance_hint: [prompt | markdown | community-post | rfe | prd from Phase 1]
"

Wait for the digest. If `status: NOT_FOUND` (invalid key / missing file), surface:
```
choices: ["Re-enter the source", "Cancel", "Other… (describe)"]
```
This is an environment/user halt — do NOT `emit-block`. On `OK`, carry forward `raw_context`,
`signals`, `images`, `candidate_title`, `candidate_slug`, `source_refs`, `provenance`, `tracked` (a
`prd` source only), and the followed/broken wikilinks — `source_refs`/`provenance` feed the `sources:`
frontmatter entry in Phase 4, and `tracked` seeds `## Prior art`.

---

## Phase 2.5 — Grounding: documentation (optional)

Dispatch both grounding agents **in a single response** so they run in parallel. Each is independent; either being OFF never suppresses the other.

**Docs.** Run `resolve-docs-grounding idea` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the `idea-reader` digest's problem/outcome, `themes` = its signals; **omit `key`** (idea is keyless, so the git-grep backstop is skipped). When OFF, skip silently.

Carry both digests into Phase 3 with **grill-rank** consumption — challenges from the two compete together for the ≤10 question slots, they do not add slots. Carry `area_proposal` and the `prd` source's match into Phase 4.

---

## Phase 2.6 — Code grounding (optional)

Runs only when `--ground-code` was given; otherwise take the OFF branch at the end of this phase. Kept separate from Phase 2.5 because the repo gate needs a user answer (which cannot happen inside a parallel dispatch) and because the scan is two-round and therefore sequential.

**1. Resolve the repo set.** The token after `--ground-code` is its value **only** when it contains no whitespace and every comma-separated part matches a top-level directory basename under `${REPOS_PATH:-/workspace}`; otherwise the flag is bare and the token is idea text. Validate each resolved path is a directory; a repo that is not mounted is handled by the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` — never invented, never silently dropped. A repo the user drops is carried to Phase 5 by name, with the themes it would have grounded left unverified. With `--ground-code <repo>[,<repo>…]`, use exactly those repos and skip the derivation below. Bare, derive them:

- **Cheap discovery.** List the top-level directories under each `${REPOS_PATH:-/workspace}` entry (may be colon-separated) with `ls`. Optionally attach each directory's one-line identity — `timeout 5 git -C <dir> remote get-url origin 2>/dev/null` (slug) or its README's first heading. Do **not** deep-scan to guess relevance.
- **Propose** a candidate set from the `idea-reader` digest's themes.
- **Gate** — this list's answer varies every run, so it fires unconditionally:
  ```
  choices: ["Ground the proposed set (Recommended)", "Ground a different set (you'll be prompted)", "Ground nothing — continue without a code scan", "Cancel", "Other… (describe)"]
  ```
- **Empty proposal — do not show that list.** When no theme matches any mounted repo its first option names a set that does not exist. Escalate instead per the `No repos derivable — /epics` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md`. Every option in a shown list must name something that exists.
- **"Ground nothing — continue without a code scan"** ends this phase for the run: no scanner is dispatched, Phase 4 writes no `## Feasibility grounding` section, and the Final report shows `code grounding: declined at the repo gate` — distinct from `code grounding: off`, which means the flag was never given at all.

**2. Round 1 — broad.** Spawn `code-scanner` on the confirmed set in **batches of up to 4 concurrent agents per Agent message**, on `detection_model` per `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md` §8.3. For each repo in the batch:

→ Agent (subagent_type: "dev-workflows:code-scanner", model: `<detection_model — §2.1 Sonnet chain>`):
  > "Scan this repo for the brief:
  >
  > repo_path:        <resolved absolute path>
  > capability_themes: <the idea's themes from the idea-reader digest>
  > context:          <3–5 sentences: the idea's problem + desired outcome, and what a finding would change>
  > search_hints:     <symbols/paths/keywords derived from the idea, if any>
  > refresh:          { switch_to_default_branch: false, pull: false }"

Handle every returned status through the list `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` already carries for it — `REPO_MISSING` → *Repo missing (after resolution)*. `prep.read_only: true` is **not** a failure: the scan ran at `prep.scanned_ref`; escalate per *Read-only mount — ref stale or diverged* **only** when `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`, and cite evidence at `prep.scanned_ref` either way. With `switch_to_default_branch` and `pull` both false, every repo is scanned read-only as it stands, at `prep.scanned_ref`, without switching branches or pulling — `code-scanner`'s dirty-tree status is gated on `pull: true`, a condition never met here, so this scan never produces it.

**3. Round 2 — narrow.** Apply §8.5 of the model-routing reference: for each theme round 1 left **inconclusive** (`classification` `partial` / `absent` / `error`, or **two or more** scanners' per-theme `capability_map[].gap_summary` texts point at each other's repo in a cycle, or at a component/subsystem that no scanned repo covers), and for which round 1 produced at least one evidence anchor, dispatch `code-scanner` again with `capability_themes` holding exactly **one** question and `search_hints.paths` / `.symbols` / `.keywords` seeded from that round's verified `evidence[].path` and `.symbols`; where an evidence entry carries `lines`, name the anchor as `<path>:<line>` in the round-2 `context` prose, since `search_hints` has no line-number field. Round 2 reuses round 1's `refresh:` block verbatim — `switch_to_default_branch: false`, `pull: false` — so the read-only posture and the "dirty-tree status never produced here" claim at `:162` hold for both rounds. Cap **4 dispatches, one round only** — there is no round 3, and a theme still inconclusive is carried to Phase 4 as a `[NEEDS CLARIFICATION]`, never guessed at. A theme confirmed `absent` — by round 2, or by round 1 when no anchor existed to seed a round 2 — is a **resolved** finding: it belongs in Section 7's *What's missing*, not in Open questions. `[NEEDS CLARIFICATION]` is for a theme the scan could not settle — mutual deferral, or `error`.

**OFF branch** (no `--ground-code`). Run one detection and print at most one line. Tokenise the raw argument and the digest's `raw_context`; match tokens case-insensitively against the basenames of the **git repositories** (a `.git` entry present) directly under each `${REPOS_PATH:-/workspace}` entry, excluding `$DOCS_PATH` and `$SPECS_PATH`. Exact token match only — no substring, no stemming. On ≥1 match print:

```
This idea names <repo>; re-run with --ground-code to verify it against the code.
```

and **proceed without waiting** — an inline confirmation per `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` ("When a choice list fires"), not a gate. No match ⇒ silent. There is no auto-trigger: grounding is a fan-out across every confirmed repo plus a second seeded round, and starts only on the user's explicit flag.

---

## Phase 3 — Refine via grill

**Interview technique (grilling — embedded; no runtime dependency).** Follow the shared technique in `${CLAUDE_PLUGIN_ROOT}/references/grilling-technique.md` — one question at a time, recommend each answer, fact-vs-decision split (look up facts from the `idea-reader` digest, put only decisions to the user), walk the design tree in dependency order. **Depth: bounded by default (below); `--deep` = relentless.**

Scan for gaps against an idea-stage **ambiguity taxonomy**: *problem clarity, target users, desired
outcome/value, scope boundaries, evidence/demand sufficiency, success signal, terminology.* Rank gaps by **Impact × Uncertainty**, ranking every `docs_challenges` and `prior_art_challenges` entry from Phase 2.5 into that same list. Challenges **compete** for the slots below; they never add slots. **Code findings are facts, not questions.** A Phase 2.6 finding answers a gap rather than raising one — look it up, cite it, and do not spend a question on it. The one exception is the finding that **contradicts the idea's premise** (the capability already exists, or the gap is far smaller than the idea assumes): that becomes a challenge ranked into the same Impact × Uncertainty list, competing for a slot exactly like a `docs_challenges` or `prior_art_challenges` entry and never adding one. At most **2** such challenges.

- **Default (bounded):** ask **≤10** questions across the ranked gaps, then stop. Remaining high-impact
  gaps become `- [NEEDS CLARIFICATION: <question>]` in the `idea.md` **Open questions & assumptions**
  section, **capped at 3**; reasonable defaults are recorded as `- **Assumption:** <text>`.
- **`--deep`:** relentless — keep walking the design tree one question at a time until you and the user
  reach shared understanding; the cap does not apply.

---

## Phase 4 — Write idea.md

Author `idea.md` per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` into the write root resolved in
Phase 0, applying the no-hard-wrap prose convention in `${CLAUDE_PLUGIN_ROOT}/references/prose-formatting.md`:

- **Path.** `idea.md` in the folder Phase 0 resolved. There is no container derivation, no
  write-path gate and no `prd_disposition`: the operator named the folder when they named the key,
  which is what removes the question.
- **`## Prior art`:** write the section per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` when the
  source is a `prd` the user supplied — its Phase 2 `tracked` block (key, status, summary), which
  appears there **and** in `sources:`. Omit the section entirely otherwise. **Nothing discovers prior
  art any more**; what the user hands over is the only prior art there is.
- **`## Feasibility grounding`:** write the section per
  `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` when Phase 2.6 ran **and** returned at least one
  finding; omit it entirely otherwise. Head it with each grounded repo as `<repo>@<scanned_ref>`; give
  every bullet a repo-qualified `<repo>/<path>:<line>` citation (the first entry of that evidence's
  `lines`, or `<repo>/<path>` when it has none); write a **Reframing** line only when a finding
  contradicted the idea's premise. A theme still inconclusive after round 2 becomes a
  `[NEEDS CLARIFICATION]` in **Open questions & assumptions**, never a hedged bullet.
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

- **`status: refined`** — offer the handoff. Present
  `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's consent choice verbatim, then on the
  first option execute `handoff-to-main` (§2) with `prefix: idea`, `feature_folder` = the folder
  Phase 0 resolved, and `deliverable_paths` = `idea.md`. Then recommend
  `/dev-workflows:create-prd <KEY>`, which finds `idea.md` in that folder.

  **There is no key round-trip to wait for and no disposition to branch on.** The key was given in
  Phase 0, the folder was resolved from it, and `idea.md` was written there — so the three states this
  offer used to distinguish (rewrite in place, mint a new key, or neither) collapse into one.
- **`status: draft`** (N open `[NEEDS CLARIFICATION]`) — **never hand off**, and do not ask. By the
  governing principle the phase is not finished, so there is nothing to hand over.

Also report the code grounding when Phase 2.6 ran: the grounded repos with their `scanned_ref`s, any
repo descoped or unmounted with the themes left unverified, any theme still inconclusive after round 2,
and — first, because it is the most consequential thing a run can produce — the **Reframing** line if
one was written. A reframing that changed the idea's Problem section must not be reported only inside
the file.

`/create-prd` is a separate command; this offer is guidance the user acts on — it never auto-invokes
another command. (Per `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md` — the plugin-wide
next-phase-offer contract; `/idea` is one reference implementation.)

### Context hygiene

Continuing to `/dev-workflows:create-prd` (still the PM phase)? → run **`/compact`** to free context; your
`idea.md` is already on disk. (No resume pointer or `/rename` label here — the PRD-Key is
minted later, and the ideation phase is short.) Guidance only — see
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md`.

---

## Phase 6 — Session maintenance, feedback & cost

Terminal phase — runs after Phase 5, NEVER interrupts an earlier phase.

**Capture-at-block invariant.** If an EARLIER phase **halts on a plugin / skill / command / reference
gap** (a capability the run needed but the plugin lacked), `emit-block` (per
`${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md`) at that halt **before** escalating — so a run
abandoned at the block still records the gap. NEVER `emit-block` for an environment / user halt (bad
source-not-found, cancellation).

**Session-hygiene invariant.** End Phase 5 with a `### Context hygiene` note per
`${CLAUDE_PLUGIN_ROOT}/references/session-hygiene.md` — a same-role `/compact` suggestion
(no `resume.md`, no `/rename`: pre-PRD, short PM phase). Guidance only, never auto-run.

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
   with the Lessons Learned report, `command: /idea`, `key: null`, the run's `source`, and
   `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It renders only the
   plugin-facing slice (§4), dedupes by stable `id` (§3), resolves the target via the §2 specs-first
   ladder, and writes silently. Surface the persisted path (or "no plugin-facing signal — nothing
   persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its
   `emit-cost` entry point with `command: /idea`, `phase: prd-creation`, `role: pm`, `key: null`,
   the run's `source`, and `plugin_version`. A keyless run writes to the pending ladder (§9) and
   **advances the chained checkpoint** (§3); surface the persisted path (or the report-only notice).
4. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`
   and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages
   ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `NOISSUE Add dev-workflows
   session artifacts (/idea)` (this run is keyless — no PRD-Key exists yet), and pushes. It NEVER
   touches a code/docs repo, or the current working directory; NEVER force-pushes; NEVER
   fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting
   that notice. Hold its §6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (idea.md itself is handed off separately, before this phase, via `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2, behind Phase 5's §4.3 consent choice; the terminal step above commits only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the `idea.md` path + `status` (refined / draft with N open clarifications); the source type and
`sources`; the count of `[NEEDS CLARIFICATION]` items and Assumptions; any source-detection correction
or broken wikilinks; the resolved model routing (+ any Opus degradation); the feedback path; the cost
path (or notice); the `Specs repo:` outcome line from `commit-artifacts`
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; the
`Phase handoff:` outcome line when the handoff ran; the code grounding outcome — the grounded repos with their `scanned_ref`s, any
descoped or inconclusive ones, and — first, because it is the most consequential thing a run can
produce — the **Reframing** line if one was written; or, when no scan ran, `code grounding: off` (no
`--ground-code`) or `code grounding: declined at the repo gate` (`--ground-code` given, "Ground
nothing" chosen); and the adaptive next-phase recommendation.
