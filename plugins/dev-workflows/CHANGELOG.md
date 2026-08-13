# Changelog

All notable changes to the **dev-workflows** plugin are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [2.51.0] — 2026-08-13

### Fixed

- **`CLAUDE.md`'s workflow map and agent ledger were stale in twelve places.** Caller lists and invariant bullets had drifted out of sync as `/update-vi`, `/create-ard`, `/ready`, and `/upgrade` were added without updating the consumers they now call — `doc-fixer`'s ledger line wrongly credited `/release-notes`, `risk-planner`'s ledger line omitted `/upgrade`, the `model-routing` must-load roster omitted `/update-vi`, the `source-truth.md` consumer list named 3 of 5 real consumers, and more. All twelve corrected against the actual dispatch sites.
- **Eight more agent/reference "used by" lists carried the same drift, plus one routed-in fix.** `cost-emission.md` omitted `/update-vi`; `feedback-emission.md` and `README.md` said `emit-auto` has twelve callers when it has thirteen; `risk-planner.md` named `/vuln`, which never dispatches it; `vi-reviewer.md` omitted `/update-vi` Phase 4; `jira-reader.md` omitted `/create-ard` and `/ready`; `grilling-technique.md`'s bounded/relentless lists omitted `/prompt-grill-me`, `/update-vi`, and `/create-ard`; `jira-input-resolution.md` omitted `idea-reader` as a `resolve-export-for-key` consumer; and `README.md`'s `jira-reader` agent-table row was incomplete. Separately, `references/ard-resolution.md`'s Consumers list gained `/ready`, which resolves an applicable ARD in Phase 2.5 and checks artifacts against it.
- **`/document` direct mode was documented as running a `doc-reviewer` gate it never runs.** `CLAUDE.md`'s workflow map and invariants, and `commands/document.md`'s shared mode preamble, described direct mode as sharing `doc-reviewer` with Jira mode. It never dispatches one — direct mode's only gate is a mandatory style check plus `doc-fixer`, with no BLOCKER fix cycle and no re-review. Both files now say so explicitly, and `CLAUDE.md` cites the two `document.md` rules (`:1490`, `:1494`) that depend on that absence.
- **`/document`'s "no refresh" repo-refresh choice did nothing.** Phase 1 offered three choices (`fetch only`, `fetch + pull default branch`, `no refresh`), but the Phase 5 dispatch block hardcoded `fetch: true` regardless of which one was picked — choosing "no refresh" still fetched. The dispatch now sends `fetch: false` only when "no refresh" was chosen (and `pull: true` only for "fetch + pull"), and the choice label now states its consequence up front.
- **`diff-summarizer`'s GitHub (`gh` CLI) resolver fetched unconditionally, defeating the fix above.** When a PR's head/base commits were missing locally, the resolver always ran `git fetch` (falling back to `gh pr checkout`) regardless of `refresh.fetch` or a read-only mount. It now runs those writes only when `refresh.fetch` is true **and** the mount is not read-only; otherwise it records the PR under `unresolved_prs` with a reason instead.
- **Two SSOT promises overstated what their non-primary producer actually does.** `read-only-repos.md` said "every consuming agent" emits its §6 `prep` block, but `docs-grounder` returns a digest, not a `prep` block — narrowed to name `code-scanner` and `diff-summarizer` as the `prep` emitters, with `docs-grounder` following only §1–§4. `source-truth.md` §4.1 assigned `diff-summarizer` the duty of surfacing enum/schema/constant/label changes in its PR summary — a duty its own agent spec never implements — reassigned to `doc-planner`, which verifies those claims directly against shipped source.
- **`/ready` ran its dirty-tree/branch prompt before the preflight that would have cleared the dirt it was warning about.** The specs-repo preflight (which flushes leftover session artifacts and settles the branch) sat after the dirty-tree check in Phase 0, so none of that check's three choices could actually resolve state the preflight was about to fix. The preflight now runs immediately after `$SPECS_PATH` resolution, ahead of the dirty-tree check.
- **`/release-notes`' terminal phases ran in the wrong order, and the rule that should have caught it was too vague to.** Phase 9 emitted follow-up tasks and Phase 10 ran feedback — the reverse of every other command's feedback-then-follow-ups order. The phases are swapped (feedback is now Phase 9, follow-ups Phase 10, cost stays Phase 11), and `session-hygiene.md` rule 2 now names the binding "emitter tail" (feedback → follow-ups → cost → `resume.md` → `commit-artifacts`) explicitly, clarifying that a command's deliverable-side finish may land at any point before that tail without consequence.
- **`/idea`'s round-2 narrow code-scan didn't state its `refresh:` posture, risking a silent default.** Round 2 reused round 1's `capability_themes` and `search_hints` but never named the `refresh:` block, so a round-2 dispatch could pick up default (not-read-only) behavior instead of round 1's pinned read-only posture. `classification.md` §8.5 now states that round 2 reuses round 1's `refresh:` block verbatim.
- **`/idea`'s bounded grill was still capped at ≤5 questions across five citing files**, well under the cap that later commands were built to expect. Raised to ≤10 in `commands/idea.md`, `README.md`, `grilling-technique.md`, `docs-grounding.md`, and `vault-prior-art.md`. A follow-up fix-round correction: `grilling-technique.md`'s ambiguity-taxonomy sentence had briefly hardcoded the literal "≤10" for all bounded callers, which is false for `/prompt-grill-me` (still ≤5) — corrected to name each caller's own stated bound instead of a specific number.
- **§8.5's "outside-deferral" rule was written as a blanket rule but only holds for one caller.** A theme confirmed `absent` was called "resolved" only if nothing was deferred to a repo outside the scanned set — correct for `/implement`, whose premise is that the capability lives somewhere in-scope, but wrong for `/idea`, where the confirmed repo set *is* the whole world it grounds against. `classification.md` §8.5 now scopes the outside-deferral qualifier to `/implement` only; `/idea`'s `absent` findings resolve unconditionally. `idea-format.md`'s `sources[].provenance` enum also gained the `doc-grounding` value it was missing.
- **The cost-subsystem roster prose and price table had drifted from the actual routing chain.** `cost-emission.md` said the shipped price table covers "every model the routing policy can reach," but Haiku is priced despite no routing path currently reaching it — corrected, and a stale "Opus 4.5-4.8" chain-summary comment in `cost-prices.yaml` was corrected to "Opus 4.6-4.8," matching `classification.md`'s real chain. A run whose tokens are dominated by an unpriced model previously surfaced that only as an easy-to-miss `note: unpriced-model` field inside the persisted YAML — `emit-cost` now also prints a visible warning line to the run output naming the model and stating the figure is a lower bound. A new §12 maintainer checklist documents the two files (the fallback chain and the price table) that must be updated together when a new model generation ships.
- **`read-only-repos.md` was cited as consumed by "the seven commands that dispatch" its three consumer agents**, undercounting `/idea`'s sub-project-H wiring, which made it eight. Corrected in `CLAUDE.md` (canonical `README.md`'s copy was already corrected during an earlier fix round in this release).

## [2.50.0] — 2026-08-12

### Added

- **`/implement` adopts `classification.md` §8.5 — the seeded narrow second scan round.** Phase 1.7's fan-out previously ran one broad `code-scanner` per repo and stopped. A theme its round 1 leaves **inconclusive** — `classification` `partial`/`absent`/`error`, or two or more scanners whose per-theme `capability_map[].gap_summary` texts point at each other's repo in a cycle, or at a component/subsystem no scanned repo covers — now gets one narrow round 2 on `detection_model`, with `capability_themes` holding a single question and `search_hints` seeded from round 1's verified `evidence[].path`/`.symbols` (and the `<path>:<line>` anchor named in the `context` prose where `lines` is present), when round 1 left at least one anchor to seed from. Cap 4 dispatches, one round only, no round 3. This matters more here than in `/idea`, §8.5's first consumer: `/idea`'s summary feeds a grill with a human in it, while this one feeds `risk-planner`, whose output becomes code.

### Fixed

- **Phase 1.7's synthesis flattened uncertainty into false confidence — including the anchorless case round 2 can never reach.** Step 4 said only to combine the scanner reports into "relevant files, existing capabilities, gaps" — so two scanners each concluding "it must be in the other repo" were folded in as two ordinary **gaps**, and the planner received a summary that looked settled. Because a theme with no round-1 evidence anchor never enters round 2, and §8.5's Bounds called any `absent` theme "resolved" regardless of a deferral outside the scanned set, that anchorless mutual-deferral case — the exact defect this release targets — still reached the planner unmarked. The summary's `## Unresolved` section now names **every** theme still inconclusive at the end of Phase 1.7, explicitly including one that never entered round 2 for lack of an anchor, and §8.5's Bounds now states the precedence: mutual deferral and `error` are unresolved regardless of whether an anchor existed, and a "confirmed absent" resolution requires no deferral to a repo or component outside the scanned set. A gap asserts the capability is absent with nowhere else it could be; an unresolved theme asserts only that the scan could not tell, and once flattened the two are indistinguishable downstream.
- **`risk-planner` was never told which findings were uncertain — the dispatch changed but the agent didn't.** Phase 2B's dispatch gained an `Unresolved scan themes:` field, but `agents/risk-planner.md`'s `## Inputs` was a closed enumeration with no bullet for it and its `### Risks considered during planning` template was a fixed seven-item list with nowhere for an unresolved theme to go. The agent now declares the field (optional; never a confirmed gap or a confirmed capability) and carries an eighth `Unresolved scan themes` bullet in the risks template, with an explicit "none" form so a brief without the field still satisfies the exact shape.
- **The read-only-mount escalation rule was scoped to round 2, which most runs never reach.** The `prep.read_only: true` sentence sat at the end of the Round 2 paragraph instead of the round-1 "wait for all scanners" paragraph, so a run with no inconclusive theme — the common case — carried no read-only escalation rule at all. Moved back to the round-1 paragraph.
- **`classification.md` §8.5's own consumer list was made false by the above.** Its Opt-in paragraph said `/idea` was "its first and only current consumer" and that `/implement` "runs §8.2 alone and is unaffected"; it now names both consumers, leaving `/epics`, `/create-ard`, `/specify`, and `/design` correctly listed as unaffected. §8.5 also gains a **"Round 2 resolves; it does not license a guess"** rule binding every adopter to name what stayed unresolved in whatever it passes downstream — `/idea` into `[NEEDS CLARIFICATION]`, `/implement` into the summary and the plan's risks.
- **The mutual-deferral trigger assumed exactly two scanners.** `commands/implement.md` and `classification.md` §8.5 both defined it as two scanners naming each other's repo, missing a three-or-more-repo deferral cycle and a one-way deferral to a repo outside the scanned set. Both now read "two or more … in a cycle, or at a repo/component no scanned repo covers," and name the per-theme `capability_map[].gap_summary` field explicitly (the schema also has an unrelated top-level `gap_summary`).
- **`/implement`'s own `## Invariants` list never got the rule it was built to enforce.** Added a `WHEN fan_out is true and a theme stays inconclusive:` line alongside the file's existing per-feature invariant bullets.
- **Repo-root `CLAUDE.md`, `README.md`, and `agents/code-scanner.md` carried the same stale claim** — the workflow map's `/implement` line, the §8 policy bullet (which read "§8.5's opt-in seeded second round (`/idea` only)"), the `/implement` invariants, the `code-scanner` README row, the Code-grounding heading, and `code-scanner.md`'s own consumer-credit line (which credited only `/idea` with "broad-then-narrow per §8.5") are all reconciled.

## [2.49.0] — 2026-08-12

### Added

- **`--ground-code [<repo>,…]` on `/idea`, and a new Phase 2.6 — Code grounding (optional).** Bare, the flag derives a repo set from the idea's themes and the directories under `${REPOS_PATH:-/workspace}` behind one confirm gate; given a value, it scans exactly those repos. Round 1 is the standard `code-scanner` fan-out (single response, cap 4); round 2 applies `references/model-routing/classification.md` §8.5 — a seeded narrow follow-up, capped at 4 dispatches, for each theme round 1 left inconclusive, with `search_hints` seeded from round 1's verified `evidence[].path` / `.symbols` (a `lines` anchor is named as `<path>:<line>` in the round-2 `context` prose, since `search_hints` has no line-number field). There is no round 3. Off by default and never auto-triggered: a run that names a mounted repo without the flag gets one inline suggestion line, never a prompt.
- **`references/model-routing/classification.md` §8.5 "Broad, then narrow (the seeded second round)"** — the shared, opt-in procedure behind the second round above. `/idea` (Phase 2.6) is its first and only current consumer; `/implement`, `/epics`, `/create-ard`, `/specify`, and `/design` still run §8.2 alone.
- **`## Feasibility grounding` — Section 7 of `references/idea-format.md`** (optional; renumbers the former Section 7 `Open questions & assumptions` to 8 and Section 8 `Candidate success signal` to 9). Written only when Phase 2.6 ran and returned at least one finding; opens with each grounded repo as `<repo>@<scanned_ref>`, then up to three optional slots (What exists / What's missing / Reframing), every bullet carrying a `<repo>/<path>:<line>` citation. Section 5 `Signals & evidence` gains a rule that code findings never go there — they belong in Section 7, since that section is demand evidence only.
- **`evidence[].lines`, an optional field on `code-scanner`'s handoff schema and agent instructions** (`references/handoff/code-scanner.md`, `agents/code-scanner.md`). Present with the 1-based line numbers when an evidence entry came from a grep hit; absent for a path glob or whole-file read; meaningful only together with `scanned_ref`, since a line number moves with the ref it was read at.
- **`## When a choice list fires` in `references/escalation-rules.md`** — a third plugin-wide rule: a choice list blocks whenever shown, a list is shown only when its firing condition holds, a list for a question whose answer is already determined is a defect, and the inline-confirmation form (one line, states the resolution, proceeds without waiting) is the correct shape for an unambiguous case.

### Changed

- **`/idea` Phase 1's single unconditional confirmation became two conditional choice lists plus an inline confirmation**, applying the new "When a choice list fires" rule. Case A fires only when a resolved key's `issue_type` is neither `ValueIncrement` nor `Product Need`. Case B fires only when the argument is path-like (contains `/`, ends in `.md`, or starts with `@`) but resolved to no existing file — fixing a real defect: without this gate the path string fell through to the `prompt` branch and was ingested as the idea's raw text, so a mistyped path became prose. Every other case — a resolving path/wikilink, a key typed `ValueIncrement`/`Product Need`, or plain prose — now gets a one-line inline confirmation instead of a list with one plausible answer.
- **`references/escalation-rules.md`'s `## Repo missing (after resolution)` list was replaced.** The old list (`"Stash changes and retry this repo"`, `"Skip this repo"`, `"Cancel"`) was byte-identical to the `/epics` variant of the `## Dirty working tree` list directly above it, and had no option for the case its own trigger names — a clone whose `origin` slug doesn't match `repo_url_slug`. The new list (`"Skip this repo"`, `"I'll clone it — wait"`, `"Specify a different absolute path for this repo"`, `"Cancel"`, `"Other… (describe)"`) adds that option and carries no `(Recommended)` marker, since which option is right depends entirely on why the repo is absent. Cited by seven callers: `/release-notes`, `/document`, `/create-ard`, `/specify`, `/epics` (pre-existing), and — newly — `/idea` (Phase 2.6, which has no earlier check) and `/implement` (Phase 1.7, which previously only promised to "surface" `DIRTY_TREE`/`REFRESH_BLOCKED` and never named `REPO_MISSING` at all).

## [2.48.0] — 2026-08-11

### Added

- **`vault-prior-art-finder` agent and `references/vault-prior-art.md`.** `/idea` and `/create-vi` now look for prior art on purpose instead of finding it by accident. The read-only agent searches `Projects/Products/**` and `Projects/ideas/**` for tracked initiatives that cover, precede, parallel, or are rewritten by the new work, and returns each match classified by relation, resolved to a Jira status, and summarised — plus reconciliation challenges and a write-path area proposal. There is no retrieval index and no consent gate: the corpus is a few hundred markdown files and retrieval is `Glob`/`Grep`. Advisory only, never a gate.
- **`resolve-export-for-key` entry point in `references/jira-input-resolution.md`.** Locates the export for one exact key at any depth, and takes the most recently modified copy when several exist — the same key legitimately appears under multiple parents (`jira-products/PRODUCT-14640/PRODUCT-14796/PRODUCT-14796.md` and `jira-products/PRODUCT-15448/PRODUCT-14796/…`), and those copies can disagree. Distinct from the existing VI-selector rule, which deliberately resolves a nested Epic *up to its parent*; this one never walks upward.
- **`## Prior art` section in `references/idea-format.md`.** The durable carrier for what the finder discovered — one bullet per initiative, carrying both a wikilink and a Jira key because a wikilink resolves by file name and dangles the moment a vault item is renamed. Every slot is transcribed from the digest rather than invented.
- **`--no-prior-art` off switch** on `/idea` and `/create-vi`, alongside the existing `--no-docs`.

### Changed

- **Both commands dispatch `docs-grounder` and `vault-prior-art-finder` in a single response at Phase 2.5**, so the two grounding reads run in parallel and neither being off suppresses the other. Phase 3 then ranks both challenge sets into its existing Impact × Uncertainty gap list, where they **compete** for the bounded question slots rather than adding any — `/idea`'s ≤5-question bound is unchanged.
- **`idea-reader` returns a `salient_summary` for every followed wikilink and source reference.** It already read those files; summarising what is in its context saves the orchestrator re-reading them, which is the most expensive place to put a read. A `vi` source additionally returns a `tracked` block carrying the item's `issue_type`, `status`, and `summary`.
- **`/idea`'s write path derives a container from the source's own location** instead of flattening every idea to `Projects/<Products|ideas>/<slug>/`. A source already sitting under a `Projects/Products/` grouper now lands beside its neighbours, matching the convention the vault already follows — with no prior-art match required. On top of that, one assembled gate offers a rewrite target and a high-confidence area proposal when either exists, and records the answer as `vi_disposition`.
- **`/create-vi`'s `Usage:` line names both grounding off switches**, and the README documents vault prior-art grounding in one section-level paragraph beside the `$DOCS_PATH` one rather than per command row.

### Fixed

- **`/idea` classified every Jira key as `rfe`, reading a Value Increment as a demand ticket.** Phase 1 now types the source from the export's `issue_type` frontmatter — `ValueIncrement` → `vi`, `Product Need` → `rfe`, anything else surfaces the actual type and asks — never from the project prefix, which is a coincidence of Jira configuration. A `vi` source is prior art: `idea-reader` distills its problem, goal, and scope instead of mining it for requesters and upvotes that a Value Increment does not have.
- **Key lookup assumed a top-level `jira-products/<KEY>/` directory.** 431 keys in a real export exist only nested, including the Value Increments `PRODUCT-14796` and `PRODUCT-14592`, so `/idea PRODUCT-14796` returned `NOT_FOUND`.
- **The next-phase offer always said "first create an empty Jira workitem".** When the idea rewrites the Value Increment it came from — same goal, different approach, same key — that instructed the user to mint a key they must not mint. The offer is now driven by `vi_disposition`.
- **Classification stripped only `--deep`** while the command honours four flags, so `--no-prior-art` and the rest landed inside the classified idea text and reached `idea-reader` as though the user had typed them.
- **The `--as` future-work note advertised a `file` source type that never existed** and omitted the new `vi`.
- **The Phase 4 gate's `(Recommended)` marker could name a row absent from the array.** The marker is derived from the top prior-art match's relation, but the rows it can name are conditional — and the gate can fire with no match at all, since a `vi` source alone opens it. Every derivation branch now falls back to row 3, the only always-present destination, so the gate can never render with nothing marked.
- **Several user-facing descriptions still advertised "an exported RFE Jira ticket" as the only Jira source** — the `idea-reader` agent description, the `/idea` command description and flag line, and three README rows — after the widening above made that false.
- **`references/workflow-states.md` spelled a status `Use cases defined` where Jira and every export emit `Usecases defined`.** `readiness-reviewer` string-matches against that table, so the rung never matched.

## [2.47.1] — 2026-08-11

### Fixed

- **`/epics` discarded its documentation grounding whenever code scan was off — after asking the user to pay for it.** Phase 4 and Phase 5 both say "If code scan is OFF, skip to Phase 6", and `dispatch-docs-grounder` sat inside Phase 5, so the digest was never produced on those runs even though its own text claimed it "runs even when code scan is OFF". 2.47.0 sharpened the consequence rather than causing it: moving `resolve-docs-grounding` to Phase 2 meant the run could prompt for a one-time index build and then skip the dispatch that would have used it. The dispatch is now its own **Phase 3.6**, before both conditional phases — it only ever needed Phase 3's VI goal and `jira-reader` themes, never the code scan.

## [2.47.0] — 2026-08-11

### Fixed

- `docs-grounder` no longer builds the qmd index. It probes (`qmd status`, `qmd collection list`) and selects a retrieval rung: `qmd-vector` (`qmd search` + `qmd vsearch`, when the collection has embeddings), `qmd-lexical` (`qmd search` alone), or `fallback`. `qmd query` is never invoked — it is the only entry point needing the reranking and query-expansion models, which no cheap probe can prove are cached. Previously the agent was instructed to "self-heal" with `qmd collection add` + `qmd embed`, which on a fresh container means a ~1.3 GB model download and embedding every page in `$DOCS_PATH` on the user's critical path.
- The keyword fallback is bounded — 3–8 keywords, generic keywords dropped above 200 matching files, shortlist capped at 40 — so the qmd fix does not relocate the cost into an unbounded scan.
- `code-scanner` and `diff-summarizer` no longer fail on read-only mounts, where `git switch` and `git fetch` cannot write. They read at `origin/<default>` via `git ls-tree` / `git grep <ref>` / `git show <ref>:<path>` instead of returning `REFRESH_BLOCKED`, and skip the dirty-tree gate, since the working tree is never mutated. Writable mounts are unchanged. Both agents report `prep.read_only`, `prep.scanned_ref`, `prep.ref_committed_at`, and `prep.head_divergence`. Two of the twelve repository clones in the AI container are read-only mounts today.
- `/create-ard` and `/release-notes` gain their first handling for `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED`; `/epics` gains the `docs grounding:` line it never printed.

### Added

- New `references/read-only-repos.md`, the single source of truth for read-only mounts: the detection probe, what read-only mode skips, write-free ref resolution and reading, the escalation trigger, and the `prep` output contract. Consumed by `code-scanner`, `diff-summarizer` and `docs-grounder`, and cited by the seven commands that dispatch them.
- New `Read-only mount — ref stale or diverged` escalation, fired only when the ref is more than 14 days old or the working tree is ahead of it, offering a host-side `git fetch` or a read-write re-mount.

### Changed

- Index building and refreshing move into `resolve-docs-grounding` step 3.5, where the user can consent: an existing collection gets a bounded incremental `qmd update`, a missing one gets a one-time build prompt. An agent cannot ask the user; the orchestrator can.
- The `docs grounding:` line now reports the retrieval rung, a stale docs checkout, a capped index refresh, and a project-local `.qmd` index shadowing the user-scope one.

## [2.46.1] — 2026-08-11

### Fixed

- **The workflow diagram named commands two different ways without saying why.** One node read `/dev-workflows:statusline` while `/release-notes` and `/upgrade` — which collide with a Claude Code built-in exactly as `/statusline` does — sat bare beside it. A reader could see the inconsistency but not infer the rule behind it. The three colliding names are now qualified throughout the diagram, everything else keeps its short form, and a line beneath the diagram says which names need the prefix and why (`references/next-phase-offer.md` rule 6).

## [2.46.0] — 2026-08-11

### Fixed

- **Printed next-step suggestions named commands that resolve to something else.** A bare `/release-notes` typed at the prompt reaches Claude Code's built-in release-notes view, not this plugin — and the same is true of `/upgrade` and `/statusline`. The plugin already knew this for exactly one command: `statusline.md` has always told users to type the fully-qualified `/dev-workflows:statusline`. That reasoning is now the general rule (`references/next-phase-offer.md` rule 6), and every command name the plugin prints for the user to invoke carries the `/dev-workflows:` prefix. Finding them all took seven distinct detectors: `### Next step` sections and `choices:` arrays are structurally delimited, but the rest are not — quoted handoffs, inline "surface a recommendation to run X" instructions, the role-handoff line that names your next command beside `/compact`, annotated bullets expanding an offer, multi-line printed literals whose trigger phrase and command sit on different lines, and STOP messages carrying a `re-run this` instruction. Names that are printed but are not invocation targets stay bare: `command: /implement` handed to `emit-cost` is a data field, "Phase 5 of the inherited `/implement` workflow" names the workflow the run is inside, and `CREATE_VI_NEEDS_KEY: /create-vi needs a Jira key` names which command is complaining.
- **`/update-vi` cited a routing graph it did not appear in.** `update-vi.md` names `references/next-phase-offer.md` as the authority for its Phase 6 offer, and that file had never mentioned `/update-vi` — in any edition. It now appears as a PM re-entry node, reached when `/create-vi` redirects an existing-VI call or when a later phase forces a refresh. The README's workflow diagram gained the node its own role table has always listed.

## [2.45.0] — 2026-08-10

### Fixed

- **`$SPECS_PATH` is a git repository that no command ever committed.** Seventeen of the twenty-one commands write bookkeeping artifacts into it — feedback, cost entries, follow-ups, resume pointers — and none of them committed those artifacts. The five commands that do run git against the specs repo commit only their deliverable, in a handoff phase that fires *before* the artifacts are written, so the artifacts were untracked by construction. `references/feedback-emission.md` states the purpose outright — feedback reaches the maintainer only if it lands in the committed, pushed specs repo — and nothing in the plugin made that landing happen; twenty-eight tracked artifact files across nine VI directories all arrived by hand-written housekeeping commits, one of which had to commit the feedback entry recording this very defect. New `references/specs-repo-git.md` owns two entry points: `specs-preflight` at Phase 0 (flush leftovers onto the current branch, retry an artifact commit whose push failed, settle the branch) and `commit-artifacts` as the run's last action (stage the bounded artifact paths, commit `<KEY|NOISSUE> Add dev-workflows session artifacts (<command>)`, push). Every git call is `git -C "$SPECS_PATH"` and never a `cd` — nine of the seventeen commands are standing in a *different* repository when these run. Staging is by enumeration, never by glob, and never `git add -A` at repository scope. The plugin manages only branches it created (`vi|ard|spec|design/*`); a detached HEAD is the one blocking state, because a commit made there is reachable from no ref and garbage-collectable, and a run that reported a SHA over it would be a failure that looked like success.
- **Eight of the ten commands that write `resume.md` violated the ordering `references/session-hygiene.md` §1 already required.** It states the pointer is written after `emit-cost` / feedback / follow-up; only `/design` and `/specify` complied, and those two wrote it inside their Final report — after the point where `commit-artifacts` now runs, which would have left it uncommitted. All ten now write the pointer as the last step of their cost phase, immediately before the commit that captures it. The printed `### Context hygiene` block keeps its `/compact` | `/clear` | `/rename` guidance and no longer carries the write instruction, because six commands compose that report *before* their cost phase runs.
- **Sixty-seven `NEVER commits` assertions had to be re-checked against the terminal step; twenty of them became false.** They were swept across nine phrasing variants — including `never branches`, `NEVER auto-commit`, `no branch, no commit`, `git is the user's responsibility`, and two that wrap across a line break and defeat any line-level grep — and reconciled rather than deleted: the protective intent is real, only the scope changed. Assertions that stayed true (the vault, `jira-products/`, a code or docs repo) are annotated with the reason they stayed true. `/statusline` keeps its unscoped assertion — it writes only under `~/.claude/` and is out of scope.

- **The preflight did not run on every path, so the detached-HEAD guard was silently absent on some.** `commit-artifacts` refuses to commit when `specs_git: blocked` is set, and `specs-preflight` is the only thing that sets it — a commit on a detached HEAD is reachable from no ref and garbage-collectable, so a run that made one would print a SHA and a success line over data already on its way to being unrecoverable. In `document.md` the executable preflight sat inside Mode A's Phase 0, but the shared `## Mode detection` section dispatches to a mode *before* Mode A is entered, so a Mode B (`@file` / free-text) run never reached it and still ran the terminal commit. Mode B's own note already asserted the preflight had run "before mode detection" — the contract was right and only the placement contradicted it. The executable block now sits in the shared section ahead of the dispatch sentence, and both modes' notes plus the two `## Invariants` bullets that still said "at Phase 0" were corrected. Found by the Copilot port, which hit the same shape and declined to propagate it. Note that no count would have caught this: the citation was present in every file throughout.

- **Two routing rules were wrong in ways only a second read found.** `specs-preflight`'s branch matching compared the branch key against a *single* run key, but an Epic-scoped run carries two: `/specify <VI> <Epic>` authors its spec on `spec/<EPIC>-…`, so a following `/design <VI> <Epic>` — whose run key resolves to the VI — matched nothing, took B4, switched to the default branch, and removed the `specification.md` its own Phase 0 gate had just verified. That is the identical failure §3.6 documents for `/create-ard` and warns must never be "simplified away"; it simply was not covered for the commands that take an Epic. The run key is now a **set** (the VI, plus the Epic where the command takes one), B3 matches any member, and B4 applies only when none do — a different VI's branch, a different Epic's branch, and a keyless run all still route to B4. Separately, eight commands per edition stated that the terminal step "pushes to the specs repo's default branch"; it pushes to the current branch's upstream, and both G2 and B3 deliberately leave runs elsewhere, so the run could print a branch its own text had just denied. Those now cite §4 step 5 rather than restating it — which is what §7 rule 4 asks for.
- **The terminal step is not always literally last, and the reference now says so.** `/prompt-brainstorm` hands the session to `superpowers:brainstorming` and `/prompt-grill-me` enters an open-ended grill; both commit immediately *before* that hand-off, because a commit after it would never run. §4 and §7 previously admitted no exception, so a future cleanup could have "corrected" the ordering and stranded the artifacts. The carve-out is narrow: it applies only where control genuinely leaves the command, never as a convenience to commit early.

### Added

- **`references/specs-repo-git.md`** — the bounded write authority (three path shapes, `^(vi|ard|spec|design)/` branches), the three preflight guards and their four-part notice contract, the three-stage resolution, the seven-step commit, and the `Specs repo:` outcome line. Never force-pushes, never `branch -D`, never merges/rebases/resets, never deletes an `index.lock`, and never fails the run.
- **A `Specs repo:` outcome line at the end of every in-scope run** — eighteen sites, one per command plus one per `/document` mode. Where the Final Report is the run's last output the line lives in the report template; where the report is composed before the terminal phases, `commit-artifacts` prints its own block, as the follow-up and cost phases already do.

## [2.44.1] — 2026-08-10

### Fixed

- **The model-routing references had gone stale.** `references/model-routing/classification.md` §2 topped the strong chain at `claude-opus-4-8`; it now tops at `claude-opus-5`, with 4.8/4.7/4.6 shifted down one and the Sonnet 5/4.6/4.5 tail and Sonnet 4.5 floor unchanged. The mid-tier chain (§2.1) already read Sonnet 5 → 4.6 → 4.5 and is untouched. Five commands (`create-vi`, `create-ard`, `update-vi`, `design`, `specify`) hardcoded `Co-Authored-By: Claude Opus 4.8 (1M context)` in their handoff commit trailers — now `Claude Opus 5`, with the `(1M context)` qualifier dropped because the 1M window is standard on 4.6 and later. Chain examples in `docs-profile.md`, `document.md`, and `classification.md`'s own `model_routing` block follow.
- **`CLAUDE.md`'s chain description disagreed with the reference it summarises.** It listed Opus 4.8 → 4.7 → 4.6 → Sonnet 4.6 → Sonnet 4.5, omitting `claude-sonnet-5` which `classification.md` has carried at position 4. Both now read Opus 5 → 4.8 → 4.7 → 4.6 → Sonnet 5 → 4.6 → 4.5.

### Added

- **`claude-opus-5` in `references/cost-prices.yaml`.** Not cosmetic: the price engine exact-matches a model id and then falls back to the longest table key that is a *prefix* of it, and no existing key is a prefix of `claude-opus-5`. Routing to Opus 5 without this entry would have priced every SIGNIFICANT and HIGH-RISK run as `unpriced-model` with `cost_usd: null`. Opus 5 bills identically to the whole Opus 4.5–4.8 block ($5 / $25; cache read $0.50, 5m write $6.25, 1h write $10), verified 2026-08-10 against the pricing source the file already cites, so the entry is a copy of its neighbours. Sonnet 5 deliberately stays at its standard $3 / $15 — its $2 / $10 runs through 2026-08-31 only, and the file's rule against promotional rates (they make identical work look cheaper now and dearer later, distorting cross-VI comparison) is unchanged.

## [2.44.0] — 2026-08-10

### Fixed

- **The deprecation note was not missed. It was forbidden.** `agents/doc-location-finder.md`'s exclusion rule banned every path under `_content/whats-new/...` as a `/release-notes`-only destination — correct for the 182 automation-generated pages at that prefix, wrong for the 10 hand-authored announcement pages (`end-of-life-announcements.md`, `end-of-support-news.md`, `technology/index.md`) that live under the same prefix and have no automation touching them at all; their git history is human PRs. The rule's exclusion set is now keyed on what's genuinely automation-owned — `meta.content-type: release-notes` frontmatter, `_data/release-notes/**`, `_snippets/release-notes/**` — and gains one named exemption: a page declared in the profile's new `announcement_pages` block (`{postid, path, kinds}`, in `references/dynatrace-docs/docs-profile-schema.md` + `.default.yml`) is a valid target, proposed **alongside** the feature-subtree target rather than in place of it. `doc-location-finder`'s two mirrors in `doc-planner.md` change in lock-step — removing one and leaving the others is a failure mode this repo has hit before. A repo with no `announcement_pages` block falls back on the same content-type-keyed heuristic, which is necessary rather than decorative (`end-of-support-news.md` carries no `content-type` at all). `commands/docs-profile.md` learns to discover the block.
- **The provenance comments were not improvised. They were mandated.** `agents/doc-writer.md` and `doc-reviewer.md` dimension 12 ("Source traceability") required every claim to cite its Jira key and/or PR URL inline — while three other places in the same plugin (`doc-writer.md`, `doc-planner.md` ×2, `commands/document.md`) already stated the opposite: traceability lives in the commit message, not the reader-visible page. The writer emitted provenance and the reviewer endorsed it, both correctly following instructions the plugin itself contradicted. New `references/doc-structure-conventions.md` §1 states the boundary once — rendered page carries the customer-facing claim only, the commit message carries the Jira key, the run handoff carries per-claim attribution — and `doc-writer` + `doc-reviewer` now cite it instead of restating it. Dimension 12 **inverts**: a Jira key (bare or as a `[[wikilink]]`), a PR URL, or a `<!-- KEY: … -->` comment appearing anywhere in a written file is now **MAJOR**. The `source-truth.md` §7.6 `<!-- intentional-discrepancy: … -->` marker is unaffected — it's a deliberate, user-decided gap flag, not provenance.
- **`doc-location-finder`'s input contract had a scope gap.** It defined its entire input as `repo_root`, `feature_summary`, `diff_highlights` — no `target_spaces`, no `profile` — so nothing stopped it proposing a SaaS-only path on a Managed-only run. Both are now part of the contract, and `commands/document.md` passes them.

### Added

- **Callout scope and adjacency — new `references/doc-structure-conventions.md` §2.** A callout that qualifies one option in a mutually exclusive set is placed with that option, immediately beneath it, never as an *unqualified* trailing block after the whole set — a trailing callout that names its own scope in its first clause ("This applies only to the built-in cluster registry.") is §2 rule 3's permitted alternative, and the enforcers carry that carve-out so a page following it is not flagged; a callout that applies to the whole set goes in the lead-in, before the options. `doc-planner` plans placement per option, `doc-writer` writes it, and `doc-reviewer` flags a scope violation at **MAJOR** — a misread scope changes what the customer believes is required or prohibited. The motivating case: an ARM limitation specific to the built-in cluster container registry read as applying to all four registry options on the shipped page, including a customer-owned private registry where it's simply false.
- **Component-pattern fidelity — `doc-structure-conventions.md` §3.** `doc-planner`'s existing 5–10-page sibling sample (already used to classify image policy) gains a second job: recording which content component the area already uses for a recurring content shape, as a `component_patterns` block (`shape`, `component`, `evidence`, `count`). `doc-writer` reuses the dominant component for a matching shape instead of inventing a structure; `doc-reviewer` flags a divergence at **MINOR** (an ad-hoc structure still renders). No component list is vendored — the rule is repo-agnostic and the evidence always comes from whatever repo is in front of it. On the shipped page, 4 of 5 sibling pages used `{{#tabgroup}}` for the same mutually-exclusive-options shape the writer built ad hoc.
- **Images: one phase, two lists.** Phase 5.6 is now the single image step and **always runs**, sourcing a to-add list (unchanged) and a possibly-stale list — every image already present on an `extend-existing` target, listed **per occurrence** (not per URL) with its section and space-gating (`{{#if project='…'}}` or none). Answering "No screenshots needed" no longer skips the phase outright, which is exactly how three stale images — one of them SaaS-gated in a space where the feature doesn't exist — survived a run where the user was asked about screenshots and answered. Stale replacements reuse the existing Phase 6.1 CDN-URL-collection flow, and the writer swaps the existing reference rather than inserting a new one. CDN immutability — every new or replacing screenshot is a new URL; an image is never refreshed in place — is now stated in `docs-profile.default.yml`'s `images.policy`, `docs-profile-schema.md`, and the `doc-writer` image step. `doc-reviewer` dimension 9 extends to swap completeness: every accepted replacement URL must land at every occurrence the review listed, or the stale image stays live and invisible in the diff.
- **New ledger gate `image_review` — `references/gate-ledger.md` §4.** Phase 5.6, preconditioned on ≥1 candidate image (to add or possibly-stale). It's an input-side gate rather than an output-verification gate like the other six, but the accountability need is identical. The §4 direct-mode carve-out paragraph is updated in the same edit — direct mode has no Phase 5.6, so the "three registered, N never-appearing" gate count becomes four never-appearing.
- **Anchor conventions — new `references/dynatrace-docs/anchor-conventions.md`.** One `{:#id}` per heading — multi-anchor `{:#a #b}` is unsupported (0 occurrences across 1,580 files under `dynatrace/_content` + `managed/_content`); the four verified link forms (`[text](postid)`, `[text](postid#anchor)` — 19,560 occurrences, `[text](#anchor)` — 4,006, `{{#tabgroup anchor='id'}}` — 698); the `pnpm docstack validate-anchors` contract (an anchor link must target a hardcoded id, not a generated one); and the reconciliation rule that a product `dt-url` deep link's anchor wins — a mismatch is recorded as a Phase 5.8 discrepancy, never deferred on an in-session judgment that the syntax "appears unsupported." Consumed by `doc-writer` (authoring), `doc-reviewer` (dimension 5), and `doc-planner` (planning cross-link anchors).
- **Lifecycle dates — a twelfth `source-truth.md` §2 claim class.** End-of-life, end-of-support, shutdown, sunset, and availability dates are now a verified claim type, checked against UI notice strings and banner constants, announcement/config expiry values, feature-flag sunset metadata, and sibling announcement pages that already carry the date. A load-bearing milestone-equivalence rule ships with it: compare the milestone a date denotes, not its surface form — "EOY 2027," "end of 2027," "December 31, 2027," and "stops working on January 1, 2028" all denote one boundary and are not a discrepancy; a discrepancy exists only when the milestones genuinely differ. Without this rule the class would be a false-positive generator. §7.5's `<KEY>-implementation-gaps.md` bug-report trigger widens to `document-as-code`, conditionally: emit a gap only when the Jira phrasing asserts a specific value that **contradicts** the source; skip when it's merely vague or non-committal. The judgment resolves toward over-inclusion — a spurious entry costs a paragraph the user reviews; a miss leaves a wrong customer-facing claim in the ticket indefinitely.
- **`doc-reviewer` grows from 16 to 17 dimensions.** New: **Page structure conventions** (callout scope + component-pattern fidelity, above). Extended: **Structural integrity** (anchor form and the `validate-anchors` contract), **Screenshots** (swap completeness), **Source traceability** (inverted, above). The dimension table and the output-slot headings stay in lock-step, seventeen of each, per the existing "never invent a dimension beyond the ones listed" rule.
- **Phase 8 maintenance agents split into propose and apply.** Agents 2 (knowledge base) and 3 (instructions, incl. `CLAUDE.md`) stop writing into the target docs repo directly — each now returns a precise proposed edit (file, anchor, replacement text, reason) instead of applying it; Agent 1 (documentation) and Agent 4 (`impl-maintenance`, already suggest-only) are unaffected. A new apply phase — Jira mode Phase 8.6, running after Phase 8.5 has sealed the docs commit; direct mode Phase 4.5, between maintenance and the final report — presents the proposals (`choices: ["Skip — report only (Recommended)", "Apply all", "Choose per proposal", "Cancel"]`) and, on acceptance, re-dispatches the same agent in apply mode. Applied edits are left **uncommitted** by design: because the phase runs after the squash, an accepted `CLAUDE.md` edit can never ride the docs commit or the docs PR — a governance change needs its own PR on the user's own timing. The Phase 9 / Phase 5 final report gains **one** new section, `### Maintenance applied (uncommitted)`. No separate "proposed" section is added: the reports' existing Agent 2 (knowledge base) and Agent 3 (instructions) sections already list every proposal and now carry its disposition, so a second listing would duplicate them. `commands/document.md` and `references/finish-and-handoff.md` drop the "Agent 3 (`CLAUDE.md`) may have edited without committing" clause — nothing uncommitted originates there anymore.

## [2.43.0] — 2026-08-08

### Added

- **`/document` Phase 0 toolchain preflight — new `references/toolchain-preflight.md`.** Before anything is written, the run derives the tools its gates will invoke — from the resolved profile (`commands.*`, `commands.per_space.*`, `dev_servers[].command`, `prerequisites`), the repo's config signals (`.vale.ini`, `pnpm-lock.yaml`/`package-lock.json`/`yarn.lock`, `node_modules/`, `.markdownlint.json(c)`, `.remarkrc*`), and the repo's own documented `Prerequisites` section — checks each with `command -v` / `test -d`, and maps every tool to the gates it powers. On a healthy container it contributes one Readiness row and never prompts. When something is missing it states the run's outcome in advance ("with `vale` and `pnpm` missing, `style_check` would be DEGRADED, `build_check` and `render_smoke_check` UNAVAILABLE") and offers Cancel as the recommended option, so a run started in the wrong container stops before writing rather than shipping quieter, worse documentation behind a green CI. Direct mode gets the same check scoped to the style gate, deriving its required set without a profile.
- **Gate ledger — new `references/gate-ledger.md`.** Six outcomes — `RAN`, `DEGRADED`, `FAILED`, `UNAVAILABLE`, `SKIPPED_BY_USER`, `NOT_APPLICABLE` — and **none of them is an orchestrator-assignable "skipped"**. Every non-run path terminates in a named missing precondition, a named missing tool, or the user's decision quoted verbatim; `UNAVAILABLE` is explicitly not a resting state and is converted by asking. Each gate appends its row **when it completes**, never reconstructed at report time. `doc-reviewer` gains a **Verification-gate integrity** dimension that BLOCKs on a missing row, an unconverted `UNAVAILABLE`, an unattributed skip, or an underpopulated `DEGRADED`, and Phase 9 prints a `### Verification gates` table naming what CI will check that the run did not.
- **"Choice lists are presented verbatim" in `references/escalation-rules.md`** — a phase's options, their order, their wording, and the `(Recommended)` marker are not the orchestrator's to change; an orchestrator that disagrees says so in prose beside the list. Binds every command. This is the rule a `/document` run broke when it moved `(Recommended)` onto Phase 6.5's Skip option and never exercised the render gate.
- **`commands.per_space` in the docs profile.** `dynatrace-docs` defines `dynatrace:lint`, `managed:lint`, `dynatrace:build`, and `managed:build`; the built-in profile knew only `pnpm dynatrace:lint` and no build command at all. Per-space `lint`/`build`/`format` are now declared, documented in `docs-profile-schema.md`, and detected by `/docs-profile`.
- **Commands and code blocks are a verified claim class.** `references/source-truth.md` §2 gains a row for helm/kubectl/pnpm invocations, flags, image references, chart names, registry paths, and YAML keys in fenced blocks, plus a §3.7 technique that checks them against `Chart.yaml`/`values.yaml`/`templates/**`, the release workflow, sibling docs pages, and `--help` output. `doc-reviewer` checks them in **every** run at MAJOR — readers run a documented command verbatim, so an unverified one is a defect even when the rest of the page verified cleanly.
- **`repo_verification_gates` from `doc-planner`.** The repo's own pre-PR checklist — for `dynatrace-docs`, `CONTRIBUTING.md` `## PR checklist` — is now extracted and checked, instead of being discarded by the planner's "ignore operational content" rule. `doc-reviewer` holds the written files against each gate and cites the repo's own section in the finding.

### Fixed

- **`docs-style-checker` climbs the ladder instead of jumping off it.** A failure at any primary rung now continues to the next rung; previously every step-1/2/3 failure jumped straight to `dt-style-checker`, so a repo with a `.vale.ini` but no `vale` binary silently abandoned `pnpm dynatrace:lint` — the linter CI actually runs. Step 2 also becomes space-aware through a new optional `spaces` input, so a Managed-only file set is linted by `managed:lint` rather than the SaaS linter, and a new `primary_attempts` output records every rung tried, which is what fills the ledger's `not_run` and `ci_still_checks`.
- **`references/dynatrace-docs/render-verification.md` no longer claims dynatrace-docs has no build command.** That false statement disabled Phase 6.5's gating Step 1 outright; `dynatrace:build` and `managed:build` both exist and now run per space.
- **The render smoke-check boots the protected space, not only the target.** The cross-space invariant has two halves — the delta marker PRESENT in the target render and ABSENT in the protected one — and iterating `target_spaces` alone could never check the second, which is the half the 3a protection depends on. Static conditional analysis is declared necessary but never sufficient: it corroborates the gate and can never satisfy it.
- **`changelog-guidelines.md` has consumers in the write path.** It was cited only by a skill that no agent invokes and `doc-writer` cannot invoke (its tool list has no Skill), so `doc-planner`, `doc-writer`, and `doc-reviewer` each worked from two inlined rules. All three now read the reference itself; a non-conforming entry — meta phrasing, a run of "Added", internal jargon such as "Managed-only", a broken period rule — is a MAJOR reviewer finding. No rule text is duplicated.
- **Phase 5.8 tries once more before escalating.** An `AMBIGUOUS`/`NOT_FOUND` verification warning whose repo is resolved in `code_repos` now gets one supplementary direct grep against the local path — **including when `diff-summarizer` returned `REFRESH_BLOCKED`**, since a read-only mount that cannot `git fetch` can still be grepped. Resolving a claim this way records the gate as `DEGRADED`, never a clean `RAN`.
- **`status: NOT_CONFIGURED` stops being a silent proceed, in both modes.** It now maps to an `UNAVAILABLE` ledger row that must be converted by asking the user, rather than a no-op on the way to the reviewer. Jira mode converts it before `doc-reviewer`; direct mode, which has no reviewer gate, converts it before Phase 4.

## [2.42.0] — 2026-08-07

### Changed

- **Release-notes field hygiene — `/create-vi` and `/release-notes` stop asking for Jira dropdowns.** `release_versions`, `change_type`, and `release_notes_category` were filed as PM-authorable VI frontmatter; they are Jira dropdowns the PM sets on the ticket and the importer returns on the round-trip, so they move to the Jira-mirror class in `references/vi-format.md`. `/create-vi` no longer asks for any of them and `vi-reviewer` no longer requires or validates them. A dropdown question earns its place only when the answer changes what the plugin generates — deciding it in a chat window costs exactly what deciding it in Jira costs.
- **`references/release-note-types.md` rewritten as a destination + shape authority.** Evidence from the shipped `dynatrace-docs` corpus: across 852 `{{#context}}` lines in generated release-note snippets, none carries a change type — the Change Type instead routes the note to `breaking-changes.md`, `feature-updates.md`, or `fixes.md`. And `fixes.md` publishes one bare sentence (1 `{{#context}}` line across 57 files) rather than label + title + prose, so classifying a VI as `Bug fix` used to emit an unpublishable shape. The reference now maps Change Type → destination → draft shape, and adopts the docs team's own per-destination prose rules (breaking: present tense + remediation link; feature update: benefit-led + a docs/blog link; fixes: one past-tense sentence).
- **A deprecation is never classified `Bug fix`.** `fixes.md`'s one-bare-sentence shape has no `{{#context}}` line, no title, and no room for a trailing `> Note:` line — so a deprecation routed there would have nowhere to carry its required end-of-life date. §2's tie-breakers now exclude `Bug fix` outright for a deprecating change: it resolves to `Breaking change` when the customer must act now, else `New technology support` when a new capability supersedes the old one, so the note always lands in a titled destination with room for the §5 deprecation note.
- **The feature-update documentation link is now phase-gated.** `/release-notes` runs twice in a VI's life — once from the PM at VI creation, once from the dev after implementation — and only the second run has a page to link to. The writer resolves `run_phase` from the same `specification.md` / `design.md` presence signal `references/cost-emission.md` §7 already infers `phase`/`role` from: neither file present → `pm`, and the link is omitted entirely (never asked for — the feature isn't built and the docs don't exist yet); either present → `dev`, and the author may supply a redirect short link. No URL is ever invented at either phase.
- **The `{{#context}}` label is now sourced, not guessed.** It is exactly the Dynatrace Solution taxonomy the VI already carries as `release_notes_category` — yet `release-notes-writer` was explicitly forbidden from using it, so it guessed and then asked. The prohibition is gone: the label is the imported `release_notes_category` used verbatim, and the line is omitted when the import carries none.
- **Exactly one Summary per run.** `release_versions` used to emit one Summary block per declared version, but the prose may never name a version — so the blocks were identical. The `(unspecified)` fallback and the `release_version` gap are gone.
- **`/release-notes` is gated on `relevant_for_release_notes`.** An explicit `false` in the *imported* frontmatter stops the run with `RELEASE_NOTES_NOT_RELEVANT` (overridable); an absent value proceeds silently, since the field defaults to true. Previously the check ANDed the flag with `release_versions`, so a VI correctly flagged not-relevant still proceeded whenever a version happened to be set.
- **One question survives, reframed.** A low-confidence *destination* inference is still confirmed — but only when the Jira dropdown is unset, and the options now name each choice's shape and destination file instead of the four opaque enum values.

## [2.41.0] — 2026-08-04

### Changed

- **Branch naming is now repo-rule-first.** 2.40.0 introduced the `$GIT_USER_INITIALS` ladder but made it the *primary* mechanism, and only `/document` and `/docs-profile` ever read the target repo's own branch-naming convention — so `references/branch-naming.md`'s claim that a documented pattern "outranks this ladder" was unenforceable in `/implement`, `/upgrade`, and `/vuln`, which never looked. The priority is inverted and the gap closed. All five branch-creating commands now read the repo's `CONTRIBUTING.md` / `CONTRIBUTION.md` / `README.md` / `DOCUMENTATION-GUIDELINES.md` / `CLAUDE.md` **first** (§1.1), classify the documented pattern's segments (§1.2), and fill each from its proper source: an **identity** placeholder (`<your-name-or-initials>`, `<user>`, `<initials>`, …) from the `$GIT_USER_INITIALS` → `git config user.initials` → existing-branch-inference → prompt ladder, now §2; an **issue-key** segment from the run's already-resolved Jira key (or the pattern's documented no-issue literal); the **description** segment from each command's own slug rule (§3). Against `dynatrace-docs`' documented `<your-name-or-initials>/<JIRA-ISSUE-KEY>-<short-branch-name>`, `GIT_USER_INITIALS=iv-gu` now yields `iv-gu/PRODUCT-17753-add-oauth`. The ladder supplies the *whole* prefix only when a repo documents no convention at all (§1.4, per-command fallback `feat/` / `docs/` / `fix/` / `chore/`).
- **A pattern with no identity segment no longer gets one.** Injecting initials into a repo whose documented convention is a plain `feat/<slug>` would violate that convention; §1.2 and §5 now forbid it explicitly. Identity inference also ignores the generic prefixes (`feat/`, `docs/`, `fix/`, `chore/`, …) — they are not identities — and the §2.5 escalation drops its "use the generic fallback" choice when it is an identity being filled, since a documented convention requires a real one.
- **`/implement` composes a compliant name in issue-key repos.** When a documented pattern has no separate issue-key segment but the run resolved a Jira key, the key is prefixed to the slug (`<KEY>-<slug>`), matching the Jira-driven commands' pre-existing behaviour.
- Assembling a name from a documented convention still ends in the user confirmation (§1.3) — identity strings and slugs are subjective.

## [2.40.0] — 2026-08-04

### Added

- **`$GIT_USER_INITIALS` branch prefixes — new `references/branch-naming.md`.** Every branch-creating command now resolves its prefix through one shared ladder: `$GIT_USER_INITIALS` → `git config user.initials` → inference from existing branch names → a per-command fallback (`feat/` for `/implement`, `docs/` for `/document` + `/docs-profile`, `fix/` for `/vuln`, `chore/` for `/upgrade`). Set `GIT_USER_INITIALS=iv-gu` once and `/implement` produces `iv-gu/PRODUCT-17753-add-oauth` instead of `feat/add-oauth`. Reaching the fallback is no longer silent — it triggers a mandatory prompt (registered in `escalation-rules.md` as "Branch prefix undetected") offering the fallback or your initials, and suggests persisting them via the env var or git config without ever writing them itself. Wired into `/implement` (Phase 3 step 2), `/document` (Phase 6.2 steps 3–4, both modes), `/docs-profile` (Phase 6 step 1), `/upgrade` (Phase 2 prep), and `/vuln`'s "Git Workflow" spec that `vuln-fixer` follows. Inference accepts hyphenated initials (`iv-gu/`, `a-hue/`) as well as unhyphenated ones. A branch pattern documented in the repo's own `CONTRIBUTING.md` / `README.md` still outranks the ladder for the name's overall *shape*; the ladder supplies its `<user>` / `<prefix>` placeholder. Replaces `/docs-profile`'s ad-hoc `git config user.name`-derived initials prompt and `/implement`'s prefix-only `git branch -a` sniff.

### Fixed

- **Two dead `LS` tool names survived the 2.39.4 sweep.** That release removed `LS` from all 50 frontmatter `allowed-tools` / `tools` lists but missed the two *inline* Agent-dispatch specs that name their tool restriction in prose — `/document` Phase 10's structure-scout and `/implement` Phase 2A's exploration subagent both still read `tools: Read/Glob/Grep/LS only`. Claude Code grants no `LS` tool and has no alias for it, so the entry was silently dropped; both now read `tools: Read/Glob/Grep only`, matching the Copilot edition, which already had it right.

## [2.39.4] — 2026-08-02

### Fixed

- **`/vuln` + `/upgrade` re-review read a stale diff.** After `review-fixer` applied the `BLOCKER`/`MAJOR` fixes, "re-run the Opus review once" re-used the `review_diff_file` captured *before* those fixes, so the second verdict was computed on the pre-fix diff (and a `BLOCK` could never clear). Both paths now overwrite `review_diff_file` with a fresh `git add -N . && git diff` before the re-review — the same correction `/implement` received as a 2.39.2 follow-up but which was not carried into the 2.39.3 siblings.
- **`/implement`'s `test-writer` dispatches told the agent to shell out.** Phase 3.5 step 1 and Phase 3B step 4a embedded the `mktemp` + `git add -N . && git diff` capture *inside* the agent-facing prompt and left it unbracketed; `test-writer` has no `Bash` tool, so it could not comply. The capture is now an orchestrator action recorded as `test_diff_file`, and the prompt hands only that path — matching the `/document` + `/epics` handoff pattern.
- **Dispatch substitution brackets carried instructions instead of values.** `/vuln`'s two `vuln-fixer` dispatches and `/upgrade`'s `upgrade-executor` dispatch wrapped the whole "read … from the file at `<handle>`" sentence in `[…]`, which the house convention reads as "substitute the content here" — the opposite of the intent, and enough to defeat the file-handoff. Only the path handle is bracketed now.
- **`/vuln`'s SIMPLE/MODERATE regression-resume was a missed adoption site.** It still said "passing the same CVE input verbatim" while every other `/vuln` resume had moved to `research_file`.
- **`references/context-management.md` omitted the load-bearing temp-file guard.** As the authority for "hand off by file, not paste" it did not say the handoff file must be `mktemp`-ed **outside every repo working tree** — the property that keeps a later `git add -N . && git diff` from picking it up.
- **`references/handoff/vuln-fixer.md` + `references/handoff/upgrade-executor.md` described their report/plan section as inline-only.** Both now state the section may instead arrive as an absolute path to `Read`, matching what the orchestrators have sent since 2.39.3.
- **Dead `LS` tool entry removed from every `allowed-tools` / `tools` list.** Claude Code no longer ships an `LS` tool and provides no alias for it (v2.1.218: zero occurrences of `"LS"` in the binary; the legacy alias map is `Task→Agent`, `KillShell→TaskStop`, … with no `LS` entry). Unmatched entries are silently dropped, so the lists worked — but they advertised a tool that cannot be granted, and a `tools` list whose entries *all* fail to match makes the Agent tool refuse to launch. Removed from 50 command/agent files; the `ready:`-reviewer tool list in prose was corrected too. `Task` is kept: it is still a live alias for `Agent`.
- **`agents/risk-planner.md`'s requirement-ID example used the wrong form.** `[AC-3]`/`[TC-7]` → `[AC03]`/`[TC07]`, the form `references/specification-format.md` defines and `code-review`'s spec/design-conformance dimension traces against.

## [2.39.3] — 2026-08-02

### Changed

- **`/vuln` + `/upgrade` now hand their large dispatch artifacts to sub-agents as temp-file paths instead of pasting them inline.** The `/vuln` research report (to `vuln-fixer`, `code-review`, and the resume steps) and the `/upgrade` planner handoff (to `risk-planner`, `upgrade-executor`, and the resume step), plus each command's `code-review` `git diff`, are written to `mktemp` files — outside every repo working tree, so a captured `git diff` never picks them up — and handed as absolute paths. Extends the `/implement` file-handoff (2.39.2) and the `/document` + `/epics` pattern to the two remaining code-oriented commands; `vuln-fixer` and `upgrade-executor` `## Process` now notes that a field may arrive inline or as a path to `Read`. Behavior-preserving.

## [2.39.2] — 2026-08-02

### Changed

- **`/implement` now hands its large dispatch artifacts to sub-agents as temp-file paths instead of pasting them inline.** The multi-source codebase summary (Phase 1.7 / 2B), the approved plan (Phase 2A / 2B), the review diff (Phase 3B / 3.5), and the code-review report (Phase 3B review-fixer) are written to `mktemp` files — outside every repo working tree, so a captured `git diff` never picks them up — and handed to `risk-planner` / `test-writer` / `code-review` / `review-fixer` as absolute paths. This matches the existing `/document` + `/epics` handoff pattern and keeps the orchestrator's context lean on long runs. Behavior-preserving: each agent receives identical content, and its `## Inputs` now notes that a field may arrive inline or as a path to `Read`.

## [2.39.1] — 2026-08-02

### Fixed

- **`references/context-management.md` 4th-strategy consistency.** The wave-3 "Hand off by file, not paste" bullet left the section's trailing "Prefer the cheapest strategy…" summary enumerating only the original three offload strategies. Clarified that "Hand off by file" is orthogonal — applied whenever a sub-agent is dispatched, regardless of the chosen offload strategy. (Whole-branch-review NIT follow-up.)

## [2.39.0] — 2026-08-01

### Added

- **Deferred-backlog sharpeners (wave 3).** Six additive, single-location refinements harvested from the 2026-07-29 upstream deferred backlog (all additive/conditional; `references/specification-format.md` untouched):
  - **ADR candidacy filter** — `references/ard-format.md`: an `AD-N` earns its place only when the decision is hard-to-reverse AND surprising-without-context AND the result of a real trade-off (missing any of the three → an ordinary implementation choice, left to `/design`). [Matt `domain-modeling`]
  - **Wide-refactor sequencing exception** — `commands/epics.md` Phase 2: a named carve-out for blast-radius-wide *mechanical* changes that cannot be tracer-bulleted — expand → migrate-in-batches → contract, each phase its own Epic, contract blocked by every migrate-batch. [Matt `to-tickets`]
  - **Prototype-snippet exception** — `references/design-format.md`: prose is the default, with a narrow exception for a decision-encoding snippet (state machine / schema / type shape) that pins a decision down more precisely than prose. [Matt `to-spec`]
  - **Missing-adoption gap** — `agents/code-review.md` dimension 4: flags a sibling call site that should adopt changed behavior and doesn't (an untouched caller of the same pattern), uncaught by tests. Complements the wave-2 converge gate. [BMAD `lens-verification-gap`]
  - **`resume.md` redaction reminder** — `references/session-hygiene.md`: the `Carry-forward decisions` line redacts secrets / credentials / tokens / PII. [Matt `handoff`]
  - **Context "hand off by file, not paste"** — `references/context-management.md`: a 4th long-run strategy — write dispatch context (brief / diff / review package / summary) to a file and hand the subagent a path. Reference-only; the matching `/implement` dispatch-prompt refactor is deferred. [superpowers SDD]

### Fixed

- **`/idea` and `/create-vi` YAML frontmatter.** An unquoted `description:` value containing `: ` (colon-space) — `idea.md: a lean` and `profiles: --lean` — was parsed as a nested mapping, so `claude plugin validate` failed and the whole frontmatter (`name`, `allowed-tools`) was silently dropped at runtime. Removed the offending colon-space; both commands now validate and load their metadata. Pre-existing, unrelated to the wave-3 additions.

## [2.38.0] — 2026-07-29

### Added

- **Upstream-harvest improvements.** Adapted eight improvements from four upstreams (GitHub SpecKit, Matt Pocock skills, superpowers, BMAD) into the pipeline, all additive and conditional:
  - **Spec→code conformance ("converge").** `code-review` gains a conditional 10th dimension "Spec/design conformance" (active only when a `specification.md`/`design.md` is in scope) that traces every in-scope `[Uxx]`/`[ACxx]`/`[TCxx]` against the shipped diff (satisfied / missing / partial / contradicts, with severity mirroring the ARD-conformance dimension). `risk-planner` tags plan steps with the requirement IDs they implement. `/implement` extracts in-scope IDs, passes `applicable_spec` to the Opus review, reports conformance in Phase 5, and escalates unresolved `missing`/`contradicts` gaps as `- [ ]` notes back onto the spec/design (never silently, never as invented Jira work).
  - **Bug-diagnosis discipline.** New `references/bug-diagnosis.md` — feedback-loop-first: a red-capable, deterministic repro before hypothesizing; 3–5 ranked falsifiable hypotheses; `[DEBUG-xxxx]`-tagged instrumentation with a mandatory cleanup gate; regression test at a correct seam ("no correct seam" is itself a finding). Folded into `risk-planner` (`task_shape: bug` → repro-first plan + `### Hypotheses (ranked)`) and `/implement` (bug-shape detection + strip-before-review; `code-review` flags leftover `[DEBUG-xxxx]`).
  - **Quality gates.** `test-writer` gains a falsifiability gate + no-mirror-assertion / no-change-detector / production-methods-only constraints + a mutation self-check. `review-fixer` gains a `plan-conflict` disposition (a finding that contradicts the approved plan is surfaced for a human ruling, never auto-fixed against the plan). `code-review` gains a Fowler 12-smell floor in the Architectural-consistency dimension (MINOR/NIT, overridden by a documented repo standard).
  - **Authoring sharpeners.** `grilling-technique.md` gains a terminology-precision forcing move and an altitude-aware `## Ambiguity taxonomy` (NFR / integration / implicit-enum-branch / pre-mortem gap-categories that feed the existing Impact×Uncertainty ranking — no new mandatory questions). `spec-reviewer` gains NFR-coverage + implicit-enum-branch checks. `design-format.md` + `design-reviewer` gain deep-module / deletion-test / two-adapters seam-quality vocabulary. `risk-planner` gains a "No placeholders" self-review. `vi-format` + `vi-reviewer` gain optional counter-metrics (`[SM-C1]`).
  - Renamed the grill's "design tree" → "decision tree" (removes the naming clash with the `design.md` artifact).

## [2.37.0] — 2026-07-22

### Changed

- **No-hard-wrap prose convention.** New `references/prose-formatting.md` — the single source of truth: never hard-wrap prose; write each paragraph/prose block as one unbroken line, since Obsidian and IntelliJ Idea both soft-wrap for reading, and a straight copy-paste into Jira/Grammarly needs no manual cleanup. Consumed by every authoring command/agent that writes prose: `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, `epic-writer`, `doc-writer`, `release-notes-writer`.

## [2.36.0] — 2026-07-21

### Added

- **Documentation grounding on `$DOCS_PATH`.** `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, and `/specify` now ground their grill on the product's existing shipped documentation when `$DOCS_PATH` (default `${DOCS_PATH:-/workspace/docs}`) is set and valid; `/epics` and `/release-notes` attach the same docs digest to their writer handoff. New `references/docs-grounding.md` — the single source of truth for the `resolve-docs-grounding` resolution gate (read-only, silent non-blocking skip on any miss), the `dispatch-docs-grounder` procedure, and the two consumption modes (grill-rank for the five grill commands; writer-attach for `/epics` and `/release-notes`). New read-only `docs-grounder` agent — retrieves via the `qmd` CLI when available (`qmd update`, never `--pull`), falling back to keyword-overlap + `git log --grep` matching. Grounding is **positive-first**: each match is classified by `relation` (`same_feature` / `analogous_precedent` / `building_block`) with extracted `structural_facts`, plus bounded reconciliation `docs_challenges` (`already_documented`, `terminology_mismatch`, `contradicts_documented_behavior`, `diverges_from_precedent`, `adjacent_undocumented`). Advisory only — never a gate, never a reviewer BLOCKER; disable per-run with `--no-docs` or override the root with `--docs <path>`.
- **`/document` docs-repo discovery hint.** `/document` (Jira mode) now prefers `${DOCS_PATH:-/workspace/docs}` as a docs-repo discovery hint (checked between the cwd-with-signals path and the `$REPOS_PATH` search) — a write-target hint only, with no `docs-grounder` consumption.

## [2.35.0] — 2026-07-18

### Added

- **`/release-notes` Change Type + type-aware Summary (documenting a merged-but-undocumented feature).** New `references/release-note-types.md` — the single authority for the four-value **Change Type** taxonomy (`Breaking change` / `Bug fix` / `New technology support` / `not applicable`), the classification order (with tie-breakers), and per-type Summary shaping rules: Breaking change leads with customer benefit and an Action plan when the customer must act; Bug fix is past-tense, symptom-first, no hedging and no jargon; New technology support uses the existing benefit-led/enumeration shaping. Also defines an orthogonal **deprecation note** (`> Note:` line with a required end-of-life date, optional end-of-support date, never invented) triggered by VI deprecation signals. `release-notes-writer` applies this file and emits the proposed `change_type` (plus any `gaps[]`) on its handoff; `/release-notes` renders the type on a separate `Change type:` line — never inside the pipeline-consumed Summary body.
- **Authored/imported sourcing ladder for `change_type` / `release_notes_category`.** `release-note-types.md` §6 defines the precedence: an explicit `change_type_hint` always wins; otherwise the re-imported Jira VI frontmatter (surfaced by `jira-reader`) is authoritative; otherwise the authored `$SPECS_PATH` draft VI is read as secondary grounding per `references/vi-source-resolution.md` §5; otherwise the type is inferred from content. `jira-reader` now surfaces `change_type` and `release_notes_category` from VI frontmatter; when both imported and authored sources are present and differ, the imported value wins and a non-blocking divergence note is recorded. `release_notes_category` follows the same ladder minus the hint (imported → authored → none) and is always surfaced, never inferred.
- **`/create-vi` captures optional `change_type` + `release_notes_category`.** `references/vi-format.md` frontmatter gains optional `change_type` (`Breaking change | New technology support | Bug fix | not applicable`) and `release_notes_category` (the Dynatrace Solution) fields, authored-then-mirrored like `release_versions`. The grill asks for both only when `relevant_for_release_notes: yes`; dates/deprecation stay out of VI frontmatter (they belong in the release-notes Summary).
- **`vi-reviewer` validates the new fields.** Flags a `change_type` value outside the four-value enum as `MAJOR`, and raises a `MINOR` (recommended, not required) when `relevant_for_release_notes: yes` but `change_type` is absent; `release_notes_category`, when present, is free text with no format check.

## [2.34.0] — 2026-07-17

### Added

- **New `/update-vi` command (PM VI refresh).** Refreshes an existing Value Increment — routine refresh or an obstacle-driven re-do. Resolves the VI **Jira-import-first** (a new `references/vi-source-resolution.md`: the re-imported `$VAULT_PATH/jira-products/<KEY>` is the source of truth, 3-day freshness gate; the `$SPECS_PATH` draft is secondary), grounds on VI + comments + any ARD/spec/`@transcript`, updates via the grill against `references/vi-format.md`, gated by the Opus `vi-reviewer`, and writes **canonical + archived** revisions (`<KEY>_<slug>.md` latest; prior snapshot under `revisions/`). Product-level (no code scan).
- **`/create-vi --from-vi <VI-KEY|path>` seeding.** Author a new VI seeded read-only from a sibling VI (the techFit family pattern), recorded in a new `seeded_from_vi` frontmatter field; resolved Jira-import-first. A bare `/create-vi <existing-VI>` now redirects to `/update-vi`.
- **`vi-reviewer` non-contradiction dimension + `vi-format` internal-consistency rule + `/create-vi` grill self-consistency nudge** — flags a VI that contradicts itself (AC vs Out-of-scope, Goal vs Scope, conflicting US) at product altitude.

### Changed

- **VI filename standardized to `<KEY>_<slug>.md`** (frontmatter-based detection: `issue_type: ValueIncrement`), replacing the documented `<KEY>_ValueIncrement.md` across `create-vi`, `create-ard`, `vi-reviewer`, `vi-format`, `pre-lint`, and `ard-format`.

## [2.33.0] — 2026-07-15

### Added
- **`/document` (Jira mode): counterpart-space grounding.** A space-constrained run (`saas`|`managed`) now discovers the OTHER space's existing documentation for the same feature and hands it to the writer as **read-only grounding** — concepts, terminology, and structure to consult, never text to copy and never screenshots to reuse. New `counterpart-finder` agent (in-tree keyword search + `git log --grep`, plus an optional `--counterpart <JiraID|PR-url>` for an unmerged counterpart PR, resolved via the existing diff-summarizer strategies — zero new external API). New Phase 5.6.5; `counterpart_references[]` threads into `doc-planner` (grounding + a "target may already be covered" write-strategy signal) and `doc-writer`; `doc-reviewer` gains a cross-space leak/screenshot-provenance check.

## [2.32.1] — 2026-07-15

### Changed
- **README `/specify` VI-level scope note (docs-only).** The "Workflow overview" role table's `/specify <VI> [<Epic>]` signature already implies the Epic is optional, but the diagram/table collapse that variant into the same PE node, which read as if only `<VI> <Epic>` were real. Added a note under the role table clarifying: `/specify <VI>` is valid and stays in the PE lane; on a VI with ≥2 Epics, Phase 2's picker offers picking one Epic, an explicit "Author one broad VI-level spec instead," or the tool's own recommendation to split into Epics via `/epics` first; on a single-Epic VI it auto-resolves to that Epic; and a broad VI-level spec writes to `spec/<VI>-<vslug>` with its `### Next step` pointing to `/epics <VI>` rather than `/design <VI> <Epic>`.

## [2.32.0] — 2026-07-14

### Changed

- **`release-notes-writer` — editorial shaping (enhancement).** The writer no
  longer defaults to a flat "2–4 sentence paragraph" for every entry. Process
  step 3 now instructs conditional shaping grounded in shipped dynatrace-docs
  feature-updates: prose stays the default, but when a feature **enumerates
  discrete options** (e.g. a new dropdown with N selectable values) the writer
  uses a short intro sentence + a **bulleted list** (bold each option); it leads
  with the recommended/new default path and **demotes deprecated or manual-only
  options** to a trailing sentence or an optional `> Note:` line rather than
  presenting them as equal peers; and it uses **bold** for UI/field names and
  inline `code` for filenames, identifiers, and flags. The
  `release-notes-writer` handoff schema's `prose` field description was relaxed
  to match (no longer contradicts the agent by mandating a single paragraph).
  Motivation: a real release note enumerating four container-registry options
  read better as a list with the deprecated option footnoted than as a
  comma-chained paragraph. Ported from the Copilot variant of this marketplace
  (`ihudak-copilot-plugins` dev-workflows v2.1.0).

## [2.31.2] — 2026-07-14

### Fixed

- **`/statusline` install instructions were ambiguous with Claude Code's own built-in `/statusline` command.** The root README, plugin README, `statusline.md`, and `cost-emission.md` told users to "run `/statusline`", but Claude Code ships its own built-in `/statusline` (backed by the `statusline-setup` agent) under the same bare name — typing it runs Claude Code's built-in flow instead of installing this plugin's status line. All install instructions and cross-references now use the fully-qualified `/dev-workflows:statusline`, with an explicit note on the naming collision.

## [2.31.1] — 2026-07-14

### Fixed

- `epics.md`'s Phase 6.1/6.2 sub-phase label swap (v2.31.0) missed one cross-reference: the Phase 6 handoff-recording step still said `clarifications_needed[]` was recorded "for Phases 6.2 and 7" — but that field is consumed by the clarification gate (now Phase 6.1) and the review (Phase 7), never by the style check (Phase 6.2). Corrected to "Phases 6.1 and 7".

## [2.31.0] — 2026-07-14

Fixes from a full internal-correctness audit (2 BLOCKER, 7 MAJOR, 26 MINOR findings). No new commands, agents, or hooks — counts unchanged.

### Fixed (post-audit correction, same release)

- **`vuln-fixer` / `upgrade-executor` cannot use `AskUserQuestion` — subagents never can.** This session's own BUG-2 fix (granting explicit `tools:` to these agents) initially included `AskUserQuestion` to preserve their documented "ask the user" step, but Claude Code subagents cannot use that tool under any circumstances, even when it's listed in `tools:` — it depends on the main conversation's UI/session state. Both agents' "Test regression" step always instructed asking the user directly, so this was latent and broken before this session touched these files at all, not something introduced by the BUG-2 fix. Corrected properly: `AskUserQuestion` removed from both `tools:` lists; both agents now **stop and return** (`status: TEST_REGRESSION`, with the failing-test list + a diagnosis) instead of trying to ask; `vuln.md`/`upgrade.md` gained a `phase: regression-resume` + `regression_decision: keep-anyway | revert` handshake (mirroring the existing `AWAITING_REVIEW` / `verify-resume` pattern) so the **orchestrator** — which does run interactively — asks the user and resumes the subagent with the decision. Both handoff SSOTs updated to match.

### Fixed

**Blockers**
- `test-baseliner` never emitted the `status:` field that `vuln-fixer`/`upgrade-executor` branch their entire verify → proceed/revert control flow on (it only returned a differently-named, differently-valued `Comparison status:`) — every status-branch in both consumers was dead code. Added an explicit `Status` line with a documented computation rule to both capture and verify output, and rewrote the handoff SSOT to match the agent's real Markdown output shape.
- `docs-style-checker` dispatches `dt-style-guide:dt-style-checker` as its complementary/fallback/sole pass but didn't declare `Task` in `tools:` — the dispatch couldn't execute, so the style gate silently no-op'd on any repo without a primary linter.

**Majors**
- `vuln.md` (3×) and `upgrade.md` (4×) used the Copilot CLI's `agent_type:` instead of Claude Code's `subagent_type:`, breaking every sub-agent dispatch in both commands; the `model-routing` SSOT §5 example taught the same wrong param. Also fixed a leaked GitHub Copilot bot co-author trailer in `vuln.md`'s commit template and `vuln-fixer.md`.
- `implement.md` Phase 2B/3B carried stale "invoke via `general-purpose` with a `model: opus` override" prose that contradicted the frontmatter-pinned `subagent_type` dispatch directly below it.
- `upgrade-planner.md` claimed the orchestrator pins it to Opus for SIGNIFICANT/HIGH-RISK; `upgrade.md` always invokes it on the Sonnet chain before classification even happens — Opus review of a risky plan is `risk-planner`'s job, not a re-invocation of `upgrade-planner`.
- All 14 commands that invoke the `Skill` tool (the 13 model-routing-aware commands plus `prompt-brainstorm.md`) omitted `Skill` from `allowed-tools` — none of them could run their mandatory classification step if `allowed-tools` is enforced.
- `doc-writer.md` was told to name the Jira key in the changelog entry — `doc-planner`/`doc-reviewer`/`document.md` Phase 8.5 all BLOCK on exactly that.
- `references/handoff/jira-reader.md`'s `pull_requests[]` schema had a phantom `also_in` field (nothing emits it) and was missing `branch_from`/`branch_to`, which the agent does emit and `diff-summarizer` requires.
- `impl-maintenance`'s `Command run` enum (handoff + agent) listed only 9 of the 12 invoking commands — `/idea`, `/create-vi`, `/create-ard`, `/ready` had no valid slot to pass.

**Minors**
- Gave `upgrade-executor`, `upgrade-planner`, `vuln-fixer`, `vuln-research` explicit `tools:` (previously undeclared, inheriting everything) for parity with the other 26 agents.
- Added `BASELINE_FAILED` to `vuln-fixer`'s declared status enum and an explicit `NO_TESTS` branch in its baseline step; required `Command run: /vuln` / `/upgrade` in each command's `impl-maintenance` handoff (both previously defaulted to mislabeling as `/implement`); renumbered `implement.md`'s "Pre-Phase 2" to "Phase 1.6" (it sat between 1.5 and 1.7).
- Fixed `document.md`'s Phase 0 step numbering (1, 3–8 → 1–7) and every cross-reference to it; repointed 3 dead "Increment 2/3" pointers to the real phases (5.9, 6.3) that implement that logic.
- Swapped `epics.md`'s inverted 6.1/6.2 sub-phase labels (clarifications physically ran before the style check but was numbered after it) across all internal and 3 external cross-references.
- Reconciled `release-notes-writer`'s handoff schema (missing `code_repos` input, missing `jira_phrasing`/`source_phrasing`/`source_location` in `gaps[]`); aligned `doc-fixer`'s declared finding-schema field name (`description` → `message`, matching what producers actually emit); gave `doc-writer` `Bash` (scoped to local screenshot copy only) since `image_policy: local` requires a file copy its prior tools couldn't perform.
- `specify.md`: deleted a dead "(design §7)" pointer. `create-ard.md`: converted a prose jira-reader fallback into a formal Agent block with `depth`/`jira_key` (the agent hard-refuses without them) and added it to the `detection_model` consumer annotation. `ready.md`: added the missing `model:` on the `readiness-reviewer` dispatch. Replaced the non-enum "CONCERN" severity term with `MINOR` in `readiness-reviewer.md` / `workflow-states.md`. `idea.md`: carried `source_refs`/`provenance` forward so Phase 4 can build the `sources:` frontmatter entry it claims to append.
- Reworded `api-guideline-reviewer.md`'s self-contradicting "load ALL files — never a subset" (it lists a curated subset); marked `guideline-reviewer.md`'s dt-app MCP lookup section optional/environment-dependent (this plugin doesn't bundle that MCP server); synced `code-scanner`/`diff-summarizer`'s inline Output blocks to their handoff SSOTs (both were missing the `prep:` block; diff-summarizer was also missing several per-PR fields); prefixed 3 remaining bare `references/…`/`scripts/…`/`agents/…` citations with `${CLAUDE_PLUGIN_ROOT}/`; documented that `jira-reader`'s `NOT_FOUND` status covers both the Form-1 (`jira_export_root`) and Form-2 (vault path) resolution.

### Notes

- `guideline-reviewer.md`/`api-guideline-reviewer.md`'s remaining bare `references/guidelines/…` mentions, and `create-vi.md`/`create-ard.md`'s description-frontmatter mentions of `references/*-format.md`, are confirmed **not** bugs — the former carry their own "all paths relative to `${CLAUDE_PLUGIN_ROOT}`" preamble, the latter are human-facing catalog text, not runtime citations (both already excluded by the prior `12c245a` cleanup).

## [2.30.0] — 2026-07-13

### Changed

- **Documentation-consistency refresh.** README, repo-root CLAUDE.md, and the `model-routing` SKILL.md were brought in line with the plugin as shipped: the README Agents section now says **Thirty** subagents and **nine** Opus gates (added `vi-reviewer`, `ard-reviewer`, `readiness-reviewer`, `idea-reader` rows); the Commands table covers all 20 commands (one merged `/document` row + 8 previously-undocumented commands) with corrected classification framing; the Reference-docs catalog lists the ~18 SSOTs added since v2.14; and the `model-routing` consumer list is corrected to the **13** commands that invoke it (in CLAUDE.md and the skill's own description).
- **CLAUDE.md relationships diagram** extended to the six VI-creation-flow commands (`/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`, `/ready`) and their agents, with a concise VI-creation invariants block.
- The stale `## /implement workflow` per-phase mermaid graph was **replaced** with a coarse decision-shape graph (no Phase-N nodes) that no longer drifts when a phase is inserted.
- The four newly-cited handoff schemas (`code-scanner`, `diff-summarizer`, `impl-maintenance`, `jira-reader`) were reconciled to the agents' current input/output contracts — they had silently drifted while uncited (e.g. `impl-maintenance`'s schema still described a write-to-KB contract, contradicting the agent's current suggest-only report). No agent behavior changed; only the schema docs were corrected.

### Added

- The four handoff-schema references (`code-scanner`, `diff-summarizer`, `impl-maintenance`, `jira-reader`) are now cited by their agents, matching the wired sibling pattern.

### Notes

- No new command, agent, or hook — counts unchanged (Twenty slash commands / Thirty reusable subagents). Docs + one additive agent citation each; no command body changed.

## [2.29.0] — 2026-07-13

### Added

- `references/session-hygiene.md` — the plugin-wide SSOT for **session-hygiene suggestions**: a prepare-checkpoint that flushes resume-critical state to `<VI-dir>/dev-workflows/resume.md`, then a role-aware `/compact` (same role) vs `/clear` (cross-role handoff) suggestion, plus a `/rename <VI-ID>-<slug>-<role>` session-name aid. Guidance-only — never auto-run.
- A `### Context hygiene` block at the Final Report of every pipeline command (role-aware per `next-phase-offer.md`), and a mid-phase `/compact` suggestion at `/implement`'s checkpoint.

### Changed

- `/vuln` and `/upgrade` now end with a plain `/compact` suggestion (big non-pipeline runs).
- `next-phase-offer.md` and `context-management.md` cross-reference `session-hygiene.md`.

### Notes

- No new command, agent, or hook — counts unchanged (Twenty slash commands / Thirty reusable subagents).
- `/idea` and `/create-vi` (pre-VI-Key PM ideation) get the suggestion but no `resume.md`/`/rename`; direct/doc-edit modes omit the block.

## [2.28.0] — 2026-07-13

### Added

- **`/epics` refinement & VI-partition mode** — when a PE pre-creates empty Epic shells in Jira (one per team) and they are re-imported, `/epics <VI>` now detects them and offers to **refine** them in place: it partitions the VI scope across the team-Epics, fills each in (keyed `<EPIC-KEY>.md` in `jira-drafts/`, carrying a `**Team:**` line), captures cross-team dependencies, and routes leftover VI scope through an inline batched gate (assign to a team-Epic / propose a net-new Epic / defer). `/epics <VI> <Epic>` re-refines a single Epic by iterating on its current imported content. No new command — refinement is an auto-detected mode of `/epics`.
- `jira-reader` (`depth: vi-plus-epics`) now emits three additive per-Epic fields — `refinement_candidate`, `team` (verbatim from the Epic frontmatter `team:`), and `scope_hint` — used to detect empty team-Epic shells. Additive and depth-gated; other consumers are unaffected.
- `epic-reviewer` gains four conditional refinement dimensions (refinement completeness, partition integrity, cross-team dependency sanity, team preserved), active only when the review brief includes refinement targets.

### Changed

- The code-examination default is now **adaptive in refinement mode** — ON when 2+ team-Epics are being refined, OFF for a single target (always still asked interactively). The generate-net-new path is unchanged.

### Notes

- Strictly additive / no-regression: `/epics <VI>` with no empty shells and no focus key is byte-identical to 2.27.0. `/vuln`, `/upgrade`, and the sibling plugins are untouched. Command / agent counts unchanged (Twenty / Thirty).

## [2.27.0] — 2026-07-13

### Added

- **`## Workflow overview`** in `README.md` — a mermaid role-graph (PM / PA / PE / Dev / QA lanes) of the idea→VI→ARD→Epics→spec→design→implement→document→release-notes pipeline, an annotation table (role · starting command · consumes · produces), a "Sources of truth & artifact homes" note (including where feedback / cost / follow-up files land in the specs repo, and that committing them is expected), and a "Cross-cutting commands" subsection surfacing `/feedback`, `/prompt*`, `/vuln`, `/upgrade`, and the setup / review utilities.

### Changed

- **`/specify` is labelled PE, not PM**, everywhere — `commands/specify.md`, `commands/design.md`, the `README.md` command table, and `references/workflow-states.md` — matching `references/next-phase-offer.md` (already routed under PE) and the command's own `role: pe` cost attribution. No behavior change.
- Repo-root `CLAUDE.md` — de-staled the retired `/impl:*` colon-taxonomy (`/impl:code`, `/impl:docs`, `/impl:jira:*`, …) to the current flat commands (`/implement`, `/document`, `/docs-profile`, `/epics`, `/release-notes`) across the workflow-relationships diagram, the model-routing / source-truth references, and the per-command invariants blocks.
- Corrected the stale "Twelve workflow slash commands" lead in `README.md` to "Twenty …".

## [2.26.0] — 2026-07-12

### Added

- **`references/pre-lint.md`** — new SSOT of deterministic, grep-expressible structural checks (universal + per-artifact for VI/ARD/spec/Epic/design). A thin advisory **Structural pre-lint** phase now runs immediately before the Opus reviewer in `/create-vi` (3.6), `/create-ard` (4.5), `/specify` (5.5), `/design` (5.5), and `/epics` (6.3): it surfaces mechanical defects (missing sections, duplicate/gapped IDs, stray placeholders, ARD `Binds`/`Prevents`/`Rule`, spec open-questions-count) and inline-fixes the trivial ones so an Opus pass is not consumed on structure. Advisory — never hard-blocks; the reviewers remain the gate and are unchanged.
- **`references/context-management.md`** — new long-run strategy doc (scope-to-N / sub-agent-per-`[P]` / decompose); `/implement` Phase 3B cites it for long step lists.

### Changed

- **Grilling technique** — added an "Autonomous / background invocation" guard: with no human turn available, genuine decisions are recorded as open questions (`[NEEDS CLARIFICATION]` / `- [ ]`) rather than self-answered.
- **`vi-reviewer`** — the substance-over-theater dimension now also flags non-empty-but-hollow prose (vision/persona/NFR that reads well but states no testable commitment) as `MAJOR`.

### Notes

- Polish batch from the AI-First line-85 borrow analysis. 2 new reference docs, 0 new commands/agents — counts unchanged (20 commands / 30 subagents), descriptions byte-identical. No-regression: `/vuln`, `/upgrade`, the four other reviewer agents, and the sibling plugins are untouched. (Items "/idea URL-fetch policy" and "/specify seam step" were dropped — no live fetch exists in `/idea`, and the seam concept already lives in `/design`.)

## [2.25.0] — 2026-07-12

### Changed

- **`/prompt-grill-me`** no longer hands off to Matt Pocock's `/grilling` skill (or the `superpowers:brainstorming` fallback). It now grills the fix **inline** — a bounded one-question-at-a-time interrogation of the correction following the embedded `references/grilling-technique.md`. Feedback capture (`emit-prompt`, `origin: prompt`) and the "never commits / never writes to a repo or the cwd" guarantees are unchanged.
- **Dropped the optional `mattpocock-skills` dependency.** Removed it from the *Recommended companions* table in `references/dependencies.md` and the operational mentions in `README.md`, `references/feedback-emission.md`, and `references/grilling-technique.md`. The grilling technique remains fully embedded; the "adapted from mattpocock grill-me/grilling" attribution is retained.

### Notes

- Closes AI-First line 87. The five authoring commands (`/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`) were already zero-dependency. Counts unchanged — **20** commands / **30** subagents (`/prompt-grill-me` retargeted, not removed). No-regression: `/vuln`, `/upgrade`, `jira-reader`, and the sibling plugins are untouched.

## [2.24.0] — 2026-07-12

### Added

- **`/ready <VI> [<Epic>]`** — new status-anchored readiness gate. Reads the Jira workflow status (already emitted by `jira-reader` — no importer/reader change) and verifies the ARD/spec/design artifacts justify it and the next transition; returns **SUPPORTED / PARTIAL / NOT-SUPPORTED** with a coverage roll-up and cross-artifact findings. Read-only: never sets Jira status, never branches, never auto-commits. Writes a `_readiness.md` evidence snapshot to `$SPECS_PATH` for team visibility. Doc-only, with a best-effort repo-availability presence check.
- **`readiness-reviewer`** — new Opus subagent; the only reviewer doing joint cross-artifact analysis (status consistency, coverage chain, alignment, ARD conformance, scope integrity, identifier integrity, repo availability).
- **`references/workflow-states.md`** — new rubric mapping VI/Epic Jira status ladders ↔ pipeline command ↔ owning role ↔ expected artifacts.
- `/implement`: additive Jira-mode **Phase 0.5 readiness pre-flight** (advisory, non-blocking; direct mode byte-identical). `next-phase-offer.md`: `/ready` added as an optional Team/Dev gate.

### Notes

- Flagship borrow from the BMAD + SpecKit + Superpowers + grill-me analysis (AI-First line 85). New command + agent — counts 19 → **20** commands / 29 → **30** subagents. No-regression: `jira-reader`, `/vuln`, `/upgrade`, and the sibling plugins are untouched; `/implement` direct mode is byte-identical.

## [2.23.0] — 2026-07-12

### Added

- `/epics`: new optional **Phase 2.6 VI-level spec enrichment** — when a VI-level `specification.md` exists (detected via the VI dir `/epics` already resolves), its `[Uxx]`/`[ACxx]` requirements are folded into the coverage inventory as `spec-story`/`spec-criterion` rows, so the `_coverage.md` matrix reflects the richer spec-level requirements. Test cases (`[TCxx]`) are excluded (per-AC, non-unique, below Epic granularity). `epic-writer` notes `+ VI-level spec` on the `_source:` line; `epic-reviewer` checks the spec rows identically (uncovered → MAJOR).

### Notes

- Closes the last v2.21.0 follow-up (Cluster B / #4). Strictly additive: a run with no VI-level spec (the common case) is byte-identical to v2.22.0. No new command or agent — counts unchanged (19 / 29). `jira-reader`, `vi-reviewer`, `/vuln`, `/upgrade`, and the sibling plugins are untouched.

## [2.22.0] — 2026-07-12

### Added

- `/create-vi`: new **Phase 3.5 Dynatrace style check** — runs `dt-style-checker` on the authored VI before the `vi-reviewer` gate (emphasis: terminology + customer-facing captions/labels/messages/text), fixes applied inline, graceful skip when `dt-style-guide` is not installed. Advisory (non-gating); mirrors `/epics` Phase 6.1. VIs previously got no style check.
- `/create-vi`: **nudge toward richer requirements for complex VIs** — a Phase 1.5 non-blocking profile suggestion (SIGNIFICANT + `--lean`/`--hybrid` → consider `--full` for `FR-N`/`UC-N`) and Phase 3 active-pull of the `FR-N`/`UC-N` clusters, for finer downstream `/epics` coverage traceability. `vi-reviewer` unchanged (authoring-side only).

### Notes

- Closes two recorded follow-ups from v2.21.0. No new command or agent — counts unchanged (19 / 29). No-regression: a SIMPLE/MODERATE VI (or one run without `dt-style-guide`) behaves as before; `/vuln`, `/upgrade`, `agents/vi-reviewer.md`, and the sibling plugins are untouched. The two marginal v2.21.0 follow-ups (graded reviewer rubric; cross-iteration regression tracking) were dropped.

## [2.21.0] — 2026-07-12

### Added

- `/epics`: requirement→Epic **coverage matrix** with gap-detection — `jira-reader` now emits a `requirements[]` inventory (native VI `US/AC/SM/FR/UC` IDs, with a goal+themes `derived` fallback); `epic-writer` writes `_coverage.md` (VI-holistic, roll-up verdict + coverage %); `epic-reviewer` verifies it (uncovered requirement = MAJOR).
- `/epics`: `[NEEDS CLARIFICATION]` markers (cap 3/Epic; deps > AC > scope) + a Phase 6.2 batched resolution gate; unresolved-by-choice markers become reviewer BLOCKERs.
- `/epics`: Given/When/Then acceptance criteria + an `## Independent Test` line; source-anchored `[Source: path#Section]` citations; a pre-draft dedup pre-flight + a sizing/sequencing heuristic.
- `/epics`: new `epic-reviewer` dimensions — epic-independence (no-forward-dependency, MAJOR), internal terminology-drift (MINOR), anti-pattern + filler/"theater" detection under goal clarity.
- `/epics`: **ARD wiring** — new optional Phase 2.5 resolves the VI-level ARD (mirrors `/specify`); writer respects `AD-N` + records deviations; reviewer gains a conditional ARD-conformance dimension (BLOCKER without a deviation record). Additive, guarded on `status: found`. `/epics` added to `references/ard-resolution.md` consumers.
- `/epics`: Phase 6.1 `dt-style-checker` brief now emphasizes terminology + customer-facing captions/labels/messages/text.

### Notes

- No new command or agent — counts unchanged (19 commands / 29 agents). No-regression: a run with no ARD and no clarification markers behaves as before; `/vuln`, `/upgrade`, `/document`, and the sibling plugins are untouched.

## [2.20.0] — 2026-07-10

### Changed

- **The personal-store write-gate no longer requires an Obsidian `.obsidian/` directory.** The four vault write-gates — `/idea` Phase 0, and the `$VAULT_PATH`-fallback tiers of `references/feedback-emission.md`, `references/cost-emission.md`, and `references/followup-emission.md` — now accept `$VAULT_PATH` when it is **set + an existing directory + writable**, dropping the `.obsidian/`-directory proxy. Setting `$VAULT_PATH` is the user's explicit declaration of their personal store, and the rest of the plugin (`/release-notes`, `/epics`, `/document` staging) already trusted it on "set" alone — so this makes the four outlier gates consistent and lets non-Obsidian personal stores work. The "never write to the wrong place" guard is preserved: `$VAULT_PATH` must be set + exist + be writable, writes always land in a namespaced subdir (`$VAULT_PATH/dev-workflows/…`, `$VAULT_PATH/Projects/…`), and the NEVER-cwd rule is untouched. The `/followup` no-vault notice is softened `⚠ No writable Obsidian vault` → `⚠ No writable vault`. **No-regression:** existing `.obsidian/` vaults are still writable directories, so they behave identically; `/document`'s defensive `.obsidian/` git-forbid guard and the `.obsidian/copilot/` tag-index path are unchanged, and `/vuln`, `/upgrade`, and sibling plugins are untouched. No new command or subagent (version-only manifest bump).

## [2.19.0] — 2026-07-10

### Added

- **Every pipeline command now ends with an adaptive `### Next step` recommendation.** The end-of-run next-phase offer — previously only in `/idea`, `/create-vi`, `/create-ard` — is now a plugin-wide invariant backed by a new single-source-of-truth reference, `references/next-phase-offer.md` (the role-aware routing graph + a 5-rule contract: guidance-only / role-labeled / adaptive-to-outcome / mode-aware / Epic fan-out). The six pipeline commands that lacked it — `/specify`, `/design`, `/implement`, `/document`, `/epics`, `/release-notes` — now close their Final Report with a `### Next step` section naming the next command(s) tagged with the owning role (PM / PA / PE / Team), so a multi-hat user just keeps going. **Epic fan-out:** the per-Epic commands (`/create-ard <VI> <Epic>`, `/specify <VI> <Epic>`, `/design`, `/implement`) offer both depth (next command, same Epic) and breadth (same command, next Epic); `/document` + `/release-notes` are VI-level and run once after all Epics are implemented. The three reference commands are retrofitted to cite the SSOT; `/create-vi` also gains the PE → `/epics` handoff (and marks `/release-notes` recommended, `/create-ard` optional). **Strictly no-regression / additive:** the `### Next step` only *adds* a report section, and it is omitted in a command's direct / doc-edit mode (no VI/Epic pipeline context), so those runs are byte-identical. `/vuln` and `/upgrade` are not pipeline nodes and are untouched. No new command or subagent (version-only manifest bump — Nineteen commands / Twenty-nine subagents unchanged). Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched. **Follow-up:** revisit the `.obsidian/` vault-check.

## [2.18.0] — 2026-07-10

### Added

- **`/design`, `/implement`, and `/specify` now respect the ARD produced by `/create-ard`.** A new shared `references/ard-resolution.md` resolves the applicable ARD(s) for a `<VI>` (+ optional `<Epic>`/area) — most-specific first (per-area → Epic-level → inherited VI-level `AD-N`) — and returns a normalized context or **`none`**. Each consumer resolves early and passes the `AD-N` invariants to its reviewer as an optional `applicable_ard`; `design-reviewer`, `spec-reviewer`, and the shared `code-review` gain a **conditional** "ARD conformance" dimension that checks the artifact honors every `AD-N` `Rule`. Enforcement is **binding + deviation-record**: a violation with no recorded "ARD deviation" (flagged to the architect, in the consumer's own artifact — never the ARD) is a reviewer **BLOCKER**; a recorded deviation is allowed-but-flagged. **Strictly no-regression:** when no ARD resolves (the common case — `/create-ard` is optional) every command behaves byte-identically to before, and the reviewer dimension is skipped. Because `code-review` is shared, its dimension is gated on the caller passing `applicable_ard` — **`/vuln` and `/upgrade` never do and are not modified**. No new command or subagent (version-only manifest bump). Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched. **Follow-ups:** next-phase-offer-everywhere; revisit the `.obsidian/` vault-check.

## [2.17.0] — 2026-07-10

### Added

- **New `/create-ard` command — sub-project 3 (final) of the VI-creation flow (Product Architect phase).** `/create-ard <VI-KEY> [<Epic-KEY>]` grounds on the mounted implementation repos and authors an **ARD** (Architecture Requirements/Decision Document) that establishes the architecture invariants the downstream inherits. **Optional** (a simple VI may not need one — Phase 0 advises) and **scoped** via the two-key grammar: `<VI-KEY>` → VI-level (cross-cutting invariants + broad grounding); `<VI-KEY> <Epic-KEY>` → Epic-level (deeper; inherits the VI-level ARD's `AD-N` read-only). A big Epic spanning separable areas in one repo (e.g. `cluster2` `server/`+`ui/`) can split into `<EPIC>-<area>_ARD.md`. Grounding is **architect-driven, not PR-derived** (no PRs exist at ARD time): cheap `$REPOS_PATH` discovery + a `theme→repo` proposal + ask the architect + a consolidated mount-or-descope gate, then `code-scanner` on the confirmed set. Authored inline via the relentless grill against a new `references/ard-format.md` (Context · Grounding findings with real `file:line` · Architecture decisions `AD-N: Binds/Prevents/Rule` · Cross-repo map · Stack & invariants · Edge cases · Open questions · Deferred), gated by a new Opus **`ard-reviewer`** (grounding integrity, `AD-N` testability, no contradiction of inherited invariants, altitude purity), with a `/design`-style tiered hard model gate, written to `$SPECS_PATH/specifications/<KEY>-<slug>/`, branch+PR offer. Introduces the **`pa` (Product Architect)** role / `architecture` phase in the cost + feedback model. `references/feedback-emission.md` (ten → eleven commands) and `references/dependencies.md` (grilling list) reconciled. The sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched. **Follow-up (v2.18.0):** wire ARD *consumption* into `/design`, `/implement`, and `/specify` (both VI + Epic levels) — this effort ships the producer only.

## [2.16.0] — 2026-07-10

### Added

- **New `/create-vi` command — sub-project 2 of the VI-creation flow (PM phase).** `/create-vi <JIRA-KEY> [@idea.md] [--lean|--hybrid|--full]` turns a refined `idea.md` + a user-supplied Jira key (an empty workitem the user created for the ID; mandatory — graceful fail without it) into a product-level **Value Increment**. A new `references/vi-format.md` defines a mandatory **spine** (Problem · Goal · Target audience · User Stories `[US-N]` · Acceptance Criteria `[AC-N]` · Scope · Success Metrics `[SM-N]`) plus an **adapt-in menu** (union of Mike's + Alex's sections) selected by profile and pulled only when the idea warrants it. Authored inline via a relentless grill, gated by a new Opus **`vi-reviewer`**, written to `$SPECS_PATH/specifications/<KEY>-<slug>/<KEY>_ValueIncrement.md` (the relocated `idea.md` co-located; `sources` propagated from the idea's real provenance, not the literal `idea.md`), with a branch+PR offer and a documented paste-into-Jira + re-import round-trip. Product-level: **no code scan, no repos required** (`/specify` does the light code grounding + Test Cases downstream). Phase 6 offers **both** next steps — `/release-notes` (PM, now) and `/create-ard` (Product Architect handoff). Wired into the terminal tail: `impl-maintenance` + `emit-auto` + `emit-cost` (`vi-creation`/`pm`) + capture-at-block.

### Changed

- **Grilling technique consolidated into `references/grilling-technique.md` (SSOT).** `/idea`, `/specify`, and `/design` now cite it instead of each embedding the ~5-line technique (DRY; each keeps its own depth — bounded/`--deep` for `/idea`, relentless for the others — and stage list). Still no runtime dependency. `references/feedback-emission.md` (nine → ten commands) and `references/cost-emission.md` (VI-lifecycle enum + the promoted `/create-vi` attribution row) reconciled. Sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) untouched.

## [2.15.0] — 2026-07-10

### Added

- **New `/idea` command — the front door of the VI-creation flow (PM phase).** `/idea <prompt | @file | JIRA-KEY> [--deep]` ingests one of four sources — an inline prompt, a markdown file (wikilinks + images followed), a community post, or an exported RFE Jira ticket — via a new read-only `idea-reader` subagent (Sonnet tier; auto-detects the source type with provenance tags, follows wikilinks one level, enumerates linked images by path, captures community-post demand signals). The Opus orchestrator then refines it through the embedded grilling technique — bounded by default (≤5 Impact×Uncertainty questions, one at a time, recommended answers; leftover gaps become `[NEEDS CLARIFICATION]` capped at 3 + logged Assumptions) or relentless under `--deep` — and writes a lean one-page `idea.md` (new `references/idea-format.md` is the SSOT) to the vault under `$VAULT_PATH/Projects/<area>/<slug>/`, keyless, `status: refined` iff zero open clarifications remain. `$VAULT_PATH` is validated (falls back to a user-supplied directory, never cwd). The grill is the quality gate (no reviewer agent at the idea stage). On finish it makes an adaptive next-phase offer toward the future `/create-vi`. Wired into the standard terminal tail: `impl-maintenance` + `emit-auto` feedback, `emit-cost` (`phase: vi-creation`, `role: pm`, keyless → pending ladder), and the capture-at-block invariant. A new `references/dependencies.md` documents the recommended companions (`mattpocock-skills` `/grilling`, `superpowers`, `dt-style-guide`) and the external `jira-workitem-import` importer, all convention + runtime-resolve + graceful fallback (no manifest field). `references/feedback-emission.md` (eight → nine commands) and `references/cost-emission.md` (VI-lifecycle enumeration + the `/idea` attribution row) are reconciled. The sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.14.0] — 2026-07-10

### Added

- **Capture-at-block: a workflow that halts on a plugin gap now records it immediately, so an abandoned run doesn't lose its highest-value feedback.** A new `emit-block` entry point in `references/feedback-emission.md` (fourth alongside `emit-auto` / `emit-manual` / `emit-prompt`) writes one silent `origin: auto`, `impact: blocker` feedback entry when a run stops because the plugin lacked a capability / reference / skill / command-path the run needed — passing the gap directly (no `impl-maintenance` report exists mid-flight), deduped by the stable `id` so it never double-logs with a later terminal `emit-auto`. All eight pipeline commands (`/implement`, `/document`, `/epics`, `/release-notes`, `/specify`, `/design`, `/vuln`, `/upgrade`) carry the invariant: `emit-block` **before** escalating a plugin-gap halt. It fires **only** for plugin-facing gaps — never for a code/doc/Epic review BLOCK (a defect in the work), an environment/user halt (repo-missing, dirty-tree, jira-not-found, refresh-blocked), or a cancellation. This is not an interrupt or an enforced-collection gate — capture-at-block stays inside the deliberate silent, high-recall model (the halt is surfaced by the command's normal BLOCKED escalation, not a feedback prompt). The `impl-maintenance` agent and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.13.0] — 2026-07-10

### Added

- **`/document` (Jira mode) now discovers images from the project folder too.** Phase 5.6 gains a fourth candidate source — a recursive scan of the ticket's persistent Obsidian project folder (`<project_dir>`, resolved in Phase 1 under `$VAULT_PATH/Projects/<VI-dir>`) — alongside the existing specs-dir scan, the `jira-reader` Jira attachments (developer-attached screenshots under `jira-products/<VI-dir>/…`), and manual paths. So curated diagrams and screenshots kept in the project folder are offered automatically (deduped with the other sources; the "select a subset" flow still applies; contributes nothing when no project folder exists). The candidate summary now reports the per-source counts including "from the project folder." The add-a-new-image guidance is made explicit: place new images in the Projects VI-dir, **never** under `jira-products/` (which the Jira importer regenerates, discarding manual additions). Downstream placement, `image_policy`, and the CDN upload/defer handoff are unchanged; `jira-reader`, the doc agents, `/release-notes`, direct mode, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.12.0] — 2026-07-10

### Added

- **`/document` now applies the full dynatrace-docs frontmatter/metadata rules, not just changelog + owners.** A new reference `references/dynatrace-docs/frontmatter-guidelines.md` is the source of truth for the metadata fields: `title` (sentence case), `description` (**120–160 chars** SEO), `meta.content-type` (**mandatory** on new pages — the Diátaxis-plus-Dynatrace enum `how-to`/`tutorial`/`explanation`/`reference`/`get-started`/`troubleshooting`/`upgrade`/`best-practices`/`app`/`extension`; `overview` is deprecated; `release-notes` pages remain automation-generated), `meta.i18n-priority` (number), and `meta.generation` (`latest`/`classic`, with the Managed-build caveat). The `dynatrace-docs-frontmatter` skill sets/validates them, `doc-planner` plans them, `doc-writer` writes them, and `doc-reviewer` gates them — **missing/invalid `content-type` on a new page → BLOCKER; `description` outside 120–160 → warning; the rest advisory**. Applied only under the dynatrace-docs profile; a generic docs repo is unaffected. The `changelog:` and `owners:` conventions keep their own references (only cross-linked).
- **`/document` (Jira mode) now ingests a docs repo's own authoring rules.** `doc-planner` reads whichever guidance files a repo has — `CONTRIBUTING.md`, `CONTRIBUTION.md`, `README.md`, `CLAUDE.md` (+ `.claude/`), `STYLE.md`, `DOCUMENTATION-GUIDELINES.md` — and extracts the **authoring/structural** rules (required sections, voice/tone, page templates, structure/naming conventions), emitting a `repo_authoring_guidance` block that is surfaced in the Phase 5.7 plan (so you see "this repo's CONTRIBUTING.md requires …" before approving), passed to `doc-writer` (which follows it), and checked by `doc-reviewer` (a missing repo-mandated section → MAJOR). Generic (any repo); it **augments, never overrides** the built-in references and `dt-style-guide`, and does not duplicate the existing branch-naming read. Direct mode already ingests these files in its Phase 2A exploration and is unchanged. `/release-notes` and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.11.0] — 2026-07-10

### Changed

- **`/document` (Jira mode) now shows a single consolidated repo gate up front instead of a per-repo escalation loop.** As soon as the affected-repo set is known — Phase 4, right after `jira-reader` returns the PR links and before any diff work — `/document` presents one summary: the repositories the VI's Jira PRs span, which are mounted (✓) and which are missing (✗), and a note that missing repos are skipped so their code is not diff-summarised or checked against the VI's requirements (the discrepancy analysis is partial). It then offers **mount the missing repo(s) now and re-scan** (recommended — mount whichever are available under `$REPOS_PATH`, re-scan, repeat, which also gives per-repo control), **proceed without them** (Jira-only for the missing repos — byte-identical downstream state to the previous per-repo "skip"), **cancel**, or **specify an absolute path** for a missing repo. The all-mounted happy path is unchanged apart from a one-line "Resolved N/N repositories" note. The choice semantics still come from the `Repo unresolved (zero matches) — /document` rule in `references/escalation-rules.md`, now applied to the whole missing set at once. Jira mode only — `/document` direct mode (no repos), `/design`'s hard repo gate, and every subagent / reference / sibling plugin (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched.

## [2.10.2] — 2026-07-10

### Fixed

- **Session-cost price table now carries real Claude API rates for every model the routing policy can reach.** `references/cost-prices.yaml` had shipped with placeholder rates: Claude Opus 4.8 was priced at the old Opus 4.1 rates (`$15` / `$75` per MTok — roughly 3× too high), and `claude-sonnet-4-6` — a real, heavily-used Sonnet-chain fallback — had no key at all, so its usage was silently priced `null` (`unpriced-model`). Rates are now the standard first-party Claude API prices from Anthropic's pricing page: Opus 4.6–4.8 `$5` / `$25`, Sonnet 5 / 4.5 / 4.6 `$3` / `$15`, Haiku 4.5 `$1` / `$5`, with the cache 5m / 1h / read tiers at the standard 1.25× / 2× / 0.1× multipliers. Keys now cover the whole Opus chain (`4-8` / `4-7` / `4-6`), the whole Sonnet chain (`5` / `4-6` / `4-5`), and Haiku (`4-5`); prefix-matching prices dated transcript ids (e.g. `claude-haiku-4-5-20251001`) off their undated base key. **Permanent standard rates are used deliberately — never promotional / introductory rates** (Sonnet 5 is keyed at its standard `$3` / `$15`, not the `$2` / `$10` introductory price in effect through 2026-08-31) so cost figures stay comparable across Value Increments over time. `references/cost-emission.md` §4 is reconciled to describe the real permanent-rate table. Data / documentation only — no `session-cost.py` engine logic changed.

## [2.10.1] — 2026-07-10

### Changed

- **`impl-maintenance` agent — completed its illustrative `Command` enumeration.** The agent's two command lists (the `Command run` input description and the `Command workflow improvements` output section) now include `/design`, `/specify`, and `/release-notes` alongside the existing `/implement`, `/document` (both modes), `/epics`, `/vuln`, and `/upgrade` — matching the eight commands that actually invoke the agent (the three were added by the v2.9.0 feedback / maintenance phases). Documentation-only; no behavior change (the agent already defaults correctly when `Command run` is absent).

## [2.10.0] — 2026-07-09

### Added

- **Session cost reporting — the plugin now records how many dollars a Value Increment cost across its lifecycle, by phase / role / model, persisted per-VI into the specs repo for the maintainer to aggregate.** Claude Code stores no dollar figure in the transcript, so cost is **computed**: a new stdlib-only engine `scripts/session-cost.py` reads the session's main transcript from a chained-checkpoint line offset forward plus the session's `subagents/agent-*.jsonl` within a `(last_ts, now]` window, sums `usage` by model, and applies the new `references/cost-prices.yaml` price table (USD per million tokens; the cache 5m/1h split priced exactly; unknown model → tokens recorded, cost `null`; overridable via `$DEV_WORKFLOWS_COST_PRICES`). A new shared reference `references/cost-emission.md` is the single source of truth: session-artifact resolution, the chained-checkpoint model (advance ALWAYS — even report-only), the machine-friendly per-invocation entry format written to `<VI-dir>/dev-workflows/cost/<sid8>.md` (one file per session → merge-safe under massive team fan-out), the specs-first persistence ladder (never the cwd), pending + opportunistic move-then-delete reconciliation for keyless runs, the optional statusline cross-check, attribution (incl. the `/release-notes` PM-vs-dev inference keyed on `specification.md` / `design.md` presence, never Epics), privacy (no user name in any cost file), and the single `emit-cost` caller contract.
- **Terminal cost phase across the six VI-lifecycle commands.** `/specify` (specification/pe), `/epics` (epic-refinement/pe), `/design` (planning/dev), `/implement` (implementation/dev), `/document` (documenting/dev — Mode A + Mode B), and `/release-notes` (phase/role inferred) gain a terminal Session cost phase — the new final operational phase, after the feedback phase — that cites `cost-emission.md` and calls `emit-cost`. Cost **always runs** and always advances the chained checkpoint (even report-only), so per-command costs sum to the session total. `/vuln` and `/upgrade` are deliberately out of scope (no VI to attribute to).
- **New command `/statusline`.** Installs the plugin's multi-line status line into `~/.claude/settings.json` (idempotent; backs up any existing script + `statusLine` block; confirms before writing). Its vendored script also writes a per-render `{ts, cost_usd}` snapshot from `.cost.total_cost_usd` to `~/.claude/dev-workflows/cost-snapshots/<session_id>.json`, enabling the Option B authoritative cross-check in session cost reporting.

Additive only — the `impl-maintenance` agent, `jira-reader`, the reviewers, the format references, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; no cost phase ever fails the run, commits, or writes into the current working directory, and no user name is written to any cost file.

## [2.9.0] — 2026-07-09

### Added

- **Session feedback collection — the plugin now captures friction and improvement signals about itself and persists them per-VI into the specs repo for the maintainer to aggregate.** A new shared reference `references/feedback-emission.md` is the single source of truth: the machine-friendly entry format (file frontmatter `type` / `vi` / `slug` + per-entry YAML `id` / `date` / `command` / `plugin_version` / `origin` / `author` / `category` / `impact` + prose), the **specs-first** persistence ladder (`$SPECS_PATH` VI dir `<VI-dir>/dev-workflows/<KEY>-feedback.md` → `$SPECS_PATH/dev-workflows-feedback/` → a writable vault with a loud "won't auto-aggregate" notice → beside an imported Jira directory → report-only; **never the cwd**), append-only dedup with `git`-derived attribution, the plugin-facing predicate (persist plugin signal only — never target-project `CLAUDE.md` / hook advice), and a three-entry-point caller contract (`emit-auto`, `emit-manual`, `emit-prompt`).
- **Automatic capture across all eight workflow commands.** `/implement`, `/document` (Mode A + Mode B), `/epics`, `/vuln`, and `/upgrade` now persist the plugin-facing slice of their existing `impl-maintenance` report (Command workflow improvements + New agents/skills + Reference-doc gaps + the triggering Key observations) as `origin: auto` feedback, silently, after maintenance runs. `/release-notes`, `/specify`, and `/design` gain a new lightweight terminal maintenance phase that invokes `impl-maintenance` on the Sonnet detection chain and then persists. A routine session with no plugin-facing signal writes nothing (byte-identical to before).
- **New commands `/feedback`, `/prompt`, `/prompt-brainstorm`, and `/prompt-grill-me`.** `/feedback <text>` logs a universal manual note (`origin: manual`). The `/prompt*` family captures a corrective interaction — Friction, your verbatim prompt, and the Resolution (`origin: prompt`): `/prompt` acts on the correction directly, `/prompt-brainstorm` hands off to `superpowers:brainstorming`, and `/prompt-grill-me` runtime-resolves `/grilling` (mattpocock-skills) and falls back to `superpowers:brainstorming` if it is not installed. No hard cross-plugin dependency.

Additive only — the `impl-maintenance` agent core, `jira-reader`, the reviewers, `format-refs`, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; feedback also always remains in the run's final output (zero loss) and no capture phase ever fails the run.

## [2.8.0] — 2026-07-09

### Added

- **Follow-up task & journal emission — `/document`, `/release-notes`, `/epics`, and `/implement` now persist out-of-scope / manual-step follow-ups at end-of-run.** Each command gains a terminal "Emit follow-up tasks" phase (after its Final Report) that filters the run's follow-up signals to those whose action lands *outside* the current change or needs a *manual human step* (files owned by other teams, Jira-vs-source implementation gaps, "paste release notes into Jira", "create these Epics in Jira manually", screenshots to upload), then persists them as durable Obsidian-Tasks `- [ ]` lines — with a `Journal.md` (or project `### Notes`) entry when an item needs more than a task line. A batch preview grouped by target file (`approve-all | select | cancel`) gates every write; nothing is written without one confirmation. In-scope items the report already tracks (deferred review BLOCKERs, skipped tests, in-draft TODOs) are deliberately excluded.
- **New shared reference `references/followup-emission.md`.** The single source of truth for the emitter: task-line format, Jira-key → project-file resolution (`P<NNNN> <slug>.md` → `## Work Items → ### Tasks`, else `Tasks.md # Irregular`), notes placement (project `### Notes` → `Journal.md`), stable-key dedupe, and the no-vault fallback ladder (`$VAULT_PATH` → the VI's `$SPECS_PATH` dir `<VI-dir>/dev-workflows/<KEY>-followups.md` → beside the imported Jira directory → report-only; never the cwd). **Self-contained** — no runtime dependency on the `obsidian-llm-wiki` plugin; it mirrors that plugin's `_shared/task-rules.md` + `vault-conventions.md` as upstream and adds journaling (which exists in neither plugin).

Additive only — existing phase behaviour, `jira-reader`, the reviewers, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; the follow-ups also remain in each command's Final Report (zero regression) and the phase never fails the run.

## [2.7.0] — 2026-07-09

### Changed

- **`/implement`, `/document`, `/epics`, and `/release-notes` now honor the shared front-end's `focus_key`.** Since the v2.5.0 foundation these four commands parsed the two-key `<VI> <Epic>` grammar but ignored the focus Epic (they resolved the VI and read the whole subtree). They now consume `focus_key`:
  - **`/implement`** is treated as an Epic-unit command: for a bare multi-Epic VI it renders the progress-aware Epic picker (done-predicate = the Epic's Jira status — done / in-progress / not-started, degrading to a plain list if the export carries no status), scopes the Jira read to the chosen Epic's subtree, and resolves specs from the nested per-Epic home. Each run targets **one** Epic — there is **no "Next Epic?" loop** (unlike `/specify`+`/design`), because code-writing is heavy and branchy.
  - **`/document`** (Jira mode) and **`/release-notes`** stay VI-level and gain no picker; when an explicit focus Epic is passed they scope their change-driven phases (diff summarisation, doc planning / release-note rendering) to that Epic's subtree, defaulting to whole-VI otherwise.
  - **`/epics`** stays VI-level (its partition analysis reads the whole VI); an explicit focus Epic is honored as a **refinement target** — Phase 6 re-drafts only that Epic's definition and Phase 7 reviews only that file (`epic-writer` unchanged).
- **Shared `references/jira-input-resolution.md` §Specs-resolution is now `focus_key`-aware.** With a focus Epic it prefers the nested per-Epic home `specifications/<VI>-<vslug>/<EPIC>-<eslug>/{specification.md,design.md}` (matched by Jira key-number, tolerating slug drift), falling back to the VI-flat layout when no nested Epic folder exists; with no focus Epic the VI-flat resolution is unchanged. This is the nested per-Epic path discovery `/implement` needed.

Single-key and directory inputs, and un-split-VI (0-Epic) behaviour, are unchanged; `jira-reader`, `/specify`, `/design`, the reviewers, and the format references are untouched.

## [2.6.0] — 2026-07-08

### Added

- **`/design` — Jira-driven engineering design authoring (Dev phase).** The developer take-over half of the PM→Dev pipeline: reads a merged `specification.md` from the specs repo's main branch, grounds strictly in the fully-mounted implementation code (a **hard** repo gate — any unmounted repo in the confirmed set stops the run until remounted, unlike `/specify`'s soft gate), and authors an engineering `design.md` through a relentless one-question-at-a-time grill that both **challenges** the spec (recording an `## Engineering review` section + `- [ ]` open questions back onto `specification.md`) and **designs** the implementation. A single complexity classification scales grill depth, `design.md` section-inclusion, and reviewer rigor together; a **tiered model gate** hard-stops SIGNIFICANT/HIGH-RISK work that is not running on Opus (the critical synthesis is inline, not a subagent). Consumes the shared front-end's `focus_key`; for a multi-Epic VI it renders the progress-aware Epic picker (○/◐/●, done-predicate `design.md` exists) enumerated from the specs repo, and offers a Next-Epic loop. Writes `design.md` **flat** in the per-Epic home `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` (durable/resumable via `_design-session.md` + `_design-glossary.md`, namespaced to coexist with `/specify`'s session files), gates on the new Opus `design-reviewer`, and offers a branch+PR handoff (`design/<EPIC>-<eslug>` / `design/<VI>-<vslug>`) to the specs repo's main for `/implement`. `design.md` open questions **hard-block** handoff (opposite of `specification.md`, where they are tolerated). New assets: `commands/design.md`, `references/design-format.md` (net-new format authority), `agents/design-reviewer.md` (Opus). `/design` uses the shared Jira-input front-end only to parse the grammar — it does not read Jira content (`jira-reader` is not used).
- **`/implement` refuses to implement a design doc with unresolved open questions.** A cross-command backstop for `/design`'s decision-completeness policy: when the primary description is a design doc (`design.md` / `*-design.md`) with unresolved `- [ ]` items, `/implement` stops (override-only, logged in the Phase 5 report). `specification.md`-level open questions remain exempt.

## [2.5.0] — 2026-07-08

### Added

- **VI-selector two-key grammar for the shared Jira-input front-end** (`references/jira-input-resolution.md`). `/implement`, `/document`, `/epics`, `/specify`, and `/release-notes` share a uniform way to point at one Epic inside a multi-Epic VI: `<VI> <Epic>` (both under `$VAULT_PATH/jira-products/`) or `<dir> <Epic>` (a jira-export directory plus an Epic key, no `$VAULT_PATH` needed). A single nested-Epic key alone now auto-resolves to its parent VI (Fallback E if the parent is ambiguous; Fallback D if the Epic isn't found). The resolver exposes a new nullable `focus_key` output field (the resolved Epic, or `null` for a bare VI / stand-alone item) and documents a reusable progress-aware Epic-picker pattern (○ not-started / ◐ in-progress / ● done) for commands that need to let the user choose among a VI's Epics. All five commands now accept the grammar and resolve `focus_key`, but only `/specify` acts on it this release (below) — `/implement`, `/document`, `/epics`, and `/release-notes` resolve the VI and ignore `focus_key` for now.
- **`/specify` resolves nested/bare Epic keys and writes per-Epic output paths.** Phase 0 now accepts a nested or stand-alone Epic key directly (previously only a VI key or directory worked) and, once an Epic is in focus, writes to the hyphen-delimited per-Epic path `specifications/<VI>-<vslug>/<EPIC>-<eslug>/` — replacing the old flat `specifications/<KEY>_<slug>/` target, whose underscore delimiter mismatched the repo's hyphen convention and which had no per-Epic home (it collided with / duplicated the VI's own dir). The PR-handoff branch name follows suit: `spec/<EPIC>-<eslug>` (per-Epic) / `spec/<VI>-<vslug>` (broad VI-level) — replacing the old `spec/<KEY>_<slug>`.
- **`/specify` progress-aware Epic picker.** For a VI with two or more Epics and no Epic already selected, Phase 2 Step A now renders the shared picker (○/◐/●) before the full-depth read, so the interview scopes to one Epic's linked Stories/Sub-tasks instead of the whole VI. A single-Epic VI or a stand-alone top-level Epic skips the picker and auto-focuses; a broad VI-level spec remains available as an explicit choice. After finishing a per-Epic spec, `/specify` offers to loop back into the picker (Epic dropped from the actionable set) to author a sibling Epic's spec next.

## [2.4.0] — 2026-07-07

### Added

- **`/specify` — Jira- and code-grounded specification authoring (PM phase).** A grilling command that reads a Jira Epic/VI from exported markdown, lightly grounds in code (auto-derived repos, soft advisory gate), and authors an org-standard `specification.md` (problem → scope → user stories → acceptance criteria → test cases) through a relentless one-question-at-a-time interview — resolving open questions live and leaving genuinely unresolvable ones as `- [ ]`. Durable/resumable via `_session.md` + `_glossary.md`; a VI-without-Epics pre-flight; gates on the new Opus `spec-reviewer`; renders HTML; and offers a branch+PR handoff to the specs repo's main branch (`Published: no`) for the future `/design` dev take-over. New assets: `commands/specify.md`, `references/specification-format.md`, `agents/spec-reviewer.md`, `scripts/specification-to-html.py` (format/reviewer/renderer imported from mgd-specifications; grilling technique embedded — no runtime plugin dependency).

## [2.3.1] — 2026-07-02

### Fixed

- **Docs reflect the uniform routing doctrine.** The 10 mechanical agent descriptions and the plugin README's subagent table + summary no longer say those agents "inherit the session's model" (stale after v2.3.0). They now state each agent has no fixed model pin and its tier is assigned by the caller per the model-routing policy (mechanical → Sonnet, synthesis/review → Opus). The four Opus-pinned reviewers/planners remain marked explicitly.

## [2.3.0] — 2026-07-02

### Added

- **Per-step model routing for `/implement`, `/vuln`, `/upgrade`.** These commands now build the full §4 `model_routing` block at classification time and pin each subagent dispatch to a tier: mechanical steps (readers, scanners, `test-writer`/`test-baseliner`, `review-fixer`, and the `/vuln`/`/upgrade` coordinators) run on the §2.1 Sonnet chain, while judgment gates (`risk-planner`, `code-review`) keep their frontmatter Opus pins. `/vuln` and `/upgrade` pin at the orchestrator level; their coordinators' internal leaves inherit the pinned tier.

### Changed

- **Sonnet 5 is the Sonnet-tier primary.** The §2.1 detection chain and the §2 Opus-chain Sonnet fallback now lead with `claude-sonnet-5` (then `claude-sonnet-4-6` → `claude-sonnet-4-5`). Opus primaries (`claude-opus-4-8` …) and all review/planning-gate Opus pins are unchanged.

## [2.2.1] — 2026-07-02

### Fixed

- **`/epics` wording now reflects cwd-agnostic output.** Corrected prose that still asserted the Obsidian vault as the only output home (intro line, doc-maintenance dispatch, git-state report template) and normalized the "vault git is the user's responsibility" idiom to "git … responsibility" — accurate when Epics are drafted to `epic-drafts/<jira_key>/` beside an imported hierarchy without `$VAULT_PATH`.
- **`/release-notes` placeholder normalized.** Replaced the uppercase `<JIRA_KEY>` display token with the canonical `jira_key` (prose) / `<jira_key>` (report template), and dropped the now-redundant binding note.
- **Marketplace README command list refreshed.** Replaced the pre-B1 `/impl:*` names with the current surface: `/implement`, `/document`, `/docs-profile`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/api-guideline-reviewer`, `/guideline-reviewer`.

## [2.2.0] — 2026-07-02

### Added

- **`/epics` and `/release-notes` adopt the shared Jira-input front-end.** Both commands now accept the same grammar as `/implement` and `/document`: a **JiraID** (discovered under `$VAULT_PATH/jira-products/`) **or** an **imported-Jira directory** (the same exporter output rooted anywhere — works when `$VAULT_PATH` is unset). Input is resolved via `references/jira-input-resolution.md`, and `jira-reader` is invoked with `jira_export_root`.

### Changed

- **`/epics` is now cwd-agnostic** — it no longer requires the working directory to be inside `$VAULT_PATH`. Epic drafts are written to an absolute output directory: `$VAULT_PATH/jira-drafts/<VI-KEY>/`, or `<import-parent>/epic-drafts/<VI-KEY>/` when `$VAULT_PATH` is unset.
- **`/release-notes` always writes a file** — the draft (and any implementation-gaps report) goes to the vault project folder when `$VAULT_PATH` is set, or beside the imported directory when it is unset. Print-to-screen is a secondary option, never the default.

## [2.1.0] — 2026-06-29

### Added

- **Shared Jira-input resolution front-end** (`references/jira-input-resolution.md`). `/implement` and `/document` now share one input grammar: a **JiraID** (discovered under `$VAULT_PATH/jira-products/`), an **imported-Jira directory** (the same exporter output rooted anywhere — works when `$VAULT_PATH` is unset), or a **direct prompt/`@file`**. `/implement` gains JiraID discovery; `/document` gains directory input.
- **`SPECS_PATH`** env var (same rules as `VAULT_PATH`) — the deterministic source for a ticket's specifications at `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…/*.md`. Specs are **required (with override)** for `/implement` jira-driven runs and **additive** for `/document`.
- `jira-reader` accepts an additive `jira_export_root` input (an explicit ticket export directory); `/epics` and `/release-notes` keep using `vault_path` + `jira_key` unchanged.

### Changed

- The `jira-workitem-import` tool (https://github.com/ivan-gudak/jira-workitem-import) is now referenced as the source of the `jira-products/` export.

## [2.0.1] — 2026-06-28

### Changed

- **Internal phase renumber — documentation only, no behavior change.** Renumbered the `/document` (Jira mode) Phase 6 cluster to monotonic execution order — CDN image handoff `6.2`→`6.1`, branch setup `6.5`→`6.2` (its section now physically precedes the writer), write `6`→`6.3`, style check `6.7`→`6.4`, render verification `6.8`→`6.5` — and removed the execution-order note the old non-monotonic numbering required. Renumbered the `/epics` Dynatrace style-check phase `6.7`→`6.1` (the `/epics` Write phase stays `6`). Every step, gate, and agent dispatch is unchanged.

## [2.0.0] — 2026-06-28

### Changed (BREAKING)
- Renamed all `/impl:*` commands to top-level verbs: `/impl:code` → `/implement`; `/impl:jira:docs` → `/document`; `/impl:jira:epics` → `/epics`; `/impl:jira:release-notes` → `/release-notes`; `/impl:docs:profile` → `/docs-profile`.
- `/impl:docs` (one-shot doc editor) is **folded into `/document`** as direct mode — `/document <JiraID> [saas|managed]` runs the Jira pipeline; `/document @file` or `/document <free-text>` runs the one-shot edit. The standalone `/impl:docs` command is removed.
- The `/impl` dispatcher command is removed (no namespace left to dispatch).
- The context hook now matches the new verbs and routes `/document` by argument (JiraID → vault/repos context; free-text → silent).

### Added
- `references/escalation-rules.md` — the shared escalation `choices:` rules, resolving the previously-dangling "§15" references.

## [1.16.0] — 2026-06-28

### Changed
- `/impl:jira:docs` and `/impl:jira:epics`: the Phase 6 writers are extracted into dedicated write-only subagents (`doc-writer`, `epic-writer`) fed by a structured temp handoff file. `doc-writer` is pinned to the Opus reasoning chain (closes the docs writer gap on non-Opus sessions); `epic-writer` is pinned to the Sonnet detection chain for MODERATE runs (stops MODERATE Epic writing from running on an Opus session). Orchestrators commit (docs) or never commit (epics) as before; output is unchanged.
- `/impl:jira:docs` Phase 1.5 advisory narrowed to a context-window note (the synthesis and writing now run on Opus regardless of session).

### Added
- `/impl:jira:epics`: per-step model routing — `jira-reader`, `code-scanner`, `dt-style-checker`, `doc-fixer` pinned to the Sonnet detection chain; `epic-reviewer` keeps its Opus pin; a `model_routing` block + Phase 9 `### Model Routing` section.
- `classification.md` §9: delegated-writer routing rows, the advisory classification gate, and the code-scanner-no-synthesis refinement.

## [1.15.0] — 2026-06-28

### Added
- `/impl:jira:docs`: per-step model delegation. A `model_routing` block resolved at Phase 1.5 pins `doc-planner` (Phase 5.7) to the §2 Opus chain and the mechanical steps (`jira-reader`, `diff-summarizer`, `doc-location-finder`, `docs-style-checker`, `doc-fixer`, Phase 8 maintenance) to the §2.1 Sonnet chain. `doc-reviewer` keeps its frontmatter Opus pin.
- A Phase 1.5 advisory recommends relaunching the whole run on Opus (orchestration + the 5.8/5.9 gates + the inline writer + a 1M context window) when the session is not on the Opus chain; a no-Opus-available path records the degradation.
- `references/model-routing/classification.md` §9 — the reusable per-step routing policy for multi-phase authoring pipelines (role→chain map, no-Opus rule, §8.3 reconciliation).

## [1.14.2] — 2026-06-28

### Fixed
- **`/impl:jira:docs` pipeline hardening (post-review).** A comprehensive 3a–3d pipeline review + this spec review found five cross-phase seams, now fixed: (I#1) a Phase 6 ordering note clarifying that Phase 6.5 branch-setup runs before the writer (full renumber deferred); (I#2) the downstream agent briefs and the write invariant now consume the resolved `docs_repo_path` rather than "cwd's git root", so a docs repo discovered outside cwd (or user-entered) is scanned/written correctly; (I#4) `/impl:docs:profile` now bases its branch on the repo's default branch (clean profile PR); (I#5) when `/impl:jira:docs` invokes profiling inline it passes `--inline`, and `/impl:docs:profile` then skips its branch-naming prompt and standalone PR-draft — one branch, one decision, one handoff; (I#6) a Phase 0 guard warns when an in-repo profile is not yet on the base branch (so the docs branch won't include it). No command behavior changed beyond I#4. (`§15` escalation cleanup + the monotonic phase renumber remain deferred to the namespace refactor.)

## [1.14.1] — 2026-06-28

### Fixed
- **README & `/impl` dispatcher accuracy (docs-only).** Corrected the stale slash-command counts (intro now reads eight workflow commands plus the `/impl` dispatcher; the classification sentence now names the five `/impl:*` commands that run per-task SIMPLE/MODERATE/SIGNIFICANT/HIGH-RISK classification and notes that `/impl:docs:profile` runs at a fixed SIGNIFICANT). Refreshed the `/impl:jira:docs` description to cover multi-space write safety, render verification (Phase 6.8), and finish & handoff (Phase 8.5 — squash, opt-in push, copy-paste PR draft). Added the missing `/impl:docs:profile` and `/impl:jira:release-notes` rows to the `/impl` dispatcher and a "which docs command?" note. Clarified that the `obsidian`/`plain_dir` write contexts are defensive guards (Phase 0 normally resolves a real docs repo). No command behavior changed.

## [1.14.0] — 2026-06-27

### Added
- **`references/finish-and-handoff.md`.** Single source of truth for `/impl:jira:docs` finish & handoff: the branch entering Phase 8.5, the contextual squash (profile-config commit vs merge-base), the opt-in push, host detection, and the copy-paste PR-draft template.
- **`commit_convention` profile field (default `"<JIRA-KEY> <summary>"`).** The squash commit-message format Phase 8.5 uses; inferred from `git log` / `CONTRIBUTING` when absent.

### Changed
- **`/impl:jira:docs` finish & handoff (Increment 3c).** Phase 6.5 now adopts the inline-profiling branch (renames it to the docs-branch convention and records the profile-config commit) instead of leaving the run on it. A new **Phase 8.5** squashes the run into clean history (keeping the profile-config commit separate when profiling ran), offers an opt-in `git push`, and writes a copy-paste PR draft to the vault project folder — host-aware (Bitbucket web UI / a `gh pr create` command the user may run), with a DO-NOT-MERGE banner when document-as-spec/skip-and-report gaps exist. Phase 9's git-state line reports the squash/push/draft outcome. The zero-external-API invariant is preserved — the plugin never creates a PR via an API.

## [1.13.0] — 2026-06-27

### Added
- **`references/dynatrace-docs/render-verification.md`.** Single source of truth for `/impl:jira:docs` render verification: build-vs-boot proof, sequential dev-server boot + readiness poll + stop, route derivation, delta-marker extraction + the cross-space invariant check, prerequisites best-effort/no-auto-apply, and graceful fallback to the pages-to-visit table.
- **`dev_servers.readiness_timeout_seconds` profile field (default 120).** Overridable per-repo; how long Phase 6.8 polls a booted dev server for readiness before falling back to the manual table.

### Changed
- **`/impl:jira:docs` Phase 6.8 — render verification (Increment 3b).** New phase after the style check: runs the profile's build command (gating, with the content→`doc-fixer` / environmental→ask split); offers an opt-in best-effort sequential dev-server smoke-check that asserts HTTP 200 per affected page and verifies the 3a invariant on cross-space pages (delta marker present in the target space's render, absent in the protected space's); always emits a "pages to visit" table. Results thread into the Phase 7 `doc-reviewer` invocation and a new Phase 9 `### Render verification` section. The `.docstack` shim is checked but never auto-applied.

## [1.12.0] — 2026-06-27

### Added
- **`references/dynatrace-docs/multi-space-writing.md`.** Single source of truth for writing dynatrace-docs across the SaaS and Managed spaces: shared-vs-single pages, the render-unchanged-≠-file-untouched invariant, the conditional-vs-override-copy strategies + heuristic, the shared-registries lock-step, and token correctness. Cited by `doc-planner` and `/impl:jira:docs`.

### Changed
- **`/impl:jira:docs` multi-space write safety (Increment 3a).** `doc-planner` now receives the resolved `profile` + `target_spaces`, classifies each target's `space_scope`/`rendered_in`, and recommends a per-target `write_strategy` (`conditional` | `override-copy` | `plain`). A new **Phase 5.9** presents those recommendations for approval/override. **Phase 6** consumes `profile` + `target_spaces` + the approved strategies to route each write to the correct space's `content_root`, edit shared pages in place with `{{#if project='…'}}` conditionals for small diffs, override-copy + `managed/docstack.jsonc` `ignore` for structural ones, keep `schema-ids.yml`/`schema-mappings.yml` in lock-step, and validate token correctness — so a `saas`/`managed`-constrained run never changes the other space's rendered output.

## [1.11.0] — 2026-06-26

### Added
- **`jira-reader` image attachment enumeration.** `jira-reader` now enumerates image attachments found in the Jira hierarchy and surfaces them as an `attachments[]` array in its output, making images available to downstream phases without manual discovery.

### Changed
- **`/impl:jira:docs` spec-tree as authoritative intended source (`doc-planner`).** Phase 5.7 now feeds the VI spec tree to `doc-planner` as the authoritative intended source, enabling 3-way `Jira|Spec|Code` discrepancy detection in Phase 5.8. `doc-planner` records `spec_phrasing` alongside `jira_phrasing` and `source_phrasing`; the new `spec-markdown` technique lets writers ground prose in the spec tree before cross-checking against Jira and source. `source-truth.md` updated to describe the spec-authoritative 3-way protocol.
- **`/impl:jira:docs` auto-discovers candidate images (Phase 5.6).** Before the writer phase, Phase 5.6 now automatically scans spec files for embedded images, enumerates Jira attachment images from `jira-reader`'s `attachments[]`, and falls back to a manual discovery prompt — producing a ranked candidate list the writer uses for screenshot placement.
- **`/impl:jira:docs` interactive CDN handoff with async fallback.** When `image_policy` is `cdn_upload_required`, the command now offers an interactive handoff step: the user can paste CDN links immediately and the command substitutes real URLs into the draft. When the user defers, the existing async fallback (stage screenshots to the persistent Obsidian project folder, surface in the Phase 9 report) is used unchanged.

## [1.10.0] — 2026-06-26

### Added
- **Built-in dynatrace-docs default profile (`references/dynatrace-docs/docs-profile.default.yml`).** Provides zero-config profile resolution for dynatrace-docs clones: when no in-repo `.dev-workflows/docs-profile.yml` exists and `is_dynatrace_docs` is true, Phase 0 loads this built-in instead of invoking on-demand profiling.

### Changed
- **`/impl:jira:docs` Phase 0 — preflight discovery.** Phase 0 now resolves the docs repo (cwd-preferred → search `/workspace` for a dynatrace-docs clone → ask), the profile (in-repo → built-in dynatrace-docs default → inline `/impl:docs:profile` on-demand), and the VI's specs dir under `${REPOS_PATH:-/workspace}` before Phase 1 clarification. A readiness table summarises all resolved items.
- **`/impl:jira:docs` Phase 4.5 — applicability determination.** New phase determines and confirms the applicable space(s) (`saas`, `managed`, or both) from the Jira hierarchy and resolved repos when no space constraint is passed; skips determination when `saas|managed` is supplied as the optional second argument.
- **`/impl:jira:docs` optional `saas|managed` space constraint.** The command now accepts `PRODUCT-NNNN [saas|managed]` as its signature. Passing `saas` or `managed` scopes the run to that space and leaves the other space's output unchanged; omitting it triggers Phase 4.5 auto-determination.

## [1.9.0] — 2026-06-25

### Added
- **`/impl:docs:profile` command.** Scans a docs repo and writes/refreshes `.dev-workflows/docs-profile.yml` + CLAUDE.md guidance as a reviewable PR; consumed by `/impl:jira:docs`.
- **model-routing SSOT §2.1 — mid-tier Sonnet chain.** Mid-tier Sonnet detection chain (`claude-sonnet-4-6` → `claude-sonnet-4-5`), pinned via `model:` so detection never inherits an Opus session.
- **`references/dynatrace-docs/docs-profile-schema.md`.** The docs-profile schema.

## [1.8.0] — 2026-06-25

### Added
- **`dynatrace-docs-frontmatter` skill.** Applies the dynatrace-docs frontmatter conventions when editing documentation pages under `dynatrace/_content/**` or `managed/_content/**`: prepends a `changelog:` entry dated today on changed existing pages (newest-first, ≤200 chars, with the period rule — complete sentence ends with a period, phrase does not), and unions the required managed-docs owners into `managed/_content/**` pages without removing existing owners. Cites two new reference files as source of truth.
- **`changelog-owners-reminder` hook (`PostToolUse`: `Edit|Write|MultiEdit`).** Warn-only `systemMessage` reminder when a dynatrace-docs content page is edited without a `changelog:` entry dated today, or (managed pages) without the required owners. Skips the changelog check for brand-new/untracked pages (first-publish rule). A `.sh` wrapper delegates to `.py` logic that reads the payload from stdin; always exits 0, never blocks.
- **`references/dynatrace-docs/changelog-guidelines.md`** — single source of truth for dynatrace-docs changelog writing rules (format, business-critical rationale, the period rule, worked examples) plus the managed-docs owners policy.
- **`references/dynatrace-docs/managed-owners.txt`** — managed-docs owner IDs unioned into `managed/_content/**` pages (read by the skill and the hook). Ships with `ivan.gudak` only; extend by adding one ID per line.

### Changed
- **Docs.** README gains a `## Skills` section and a Hooks-table row for `changelog-owners-reminder`; the dev-workflows hook count is now four (root `CLAUDE.md`, `plugin.json`, `marketplace.json`).

## [1.7.2] — 2026-06-17

### Added
- **`/impl:code` multi-source fan-out (Phase 1.7).** When the input includes more than one repo or any directory (spec file folder, Jira ticket folder), the task is floored at SIGNIFICANT (overridable at plan approval) and a Phase 1.7 fan-out scan runs before planning: `jira-reader` (for Jira folders) + per-repo `code-scanner` (single response, cap 4 concurrent) → synthesised summary fed to the planner. A referenced directory that is missing or unrecognised is surfaced, never silently skipped.
- **`references/model-routing/classification.md` §8 — large-input scan fan-out policy.** New section defines the input-shape trigger (multi-repo or any directory), the `jira-reader → parallel code-scanner (cap 4) → Opus synthesis` pattern, and the SIGNIFICANT floor it imposes. Single source of truth for all commands that dispatch fan-out scans.

### Changed
- **`code-scanner` agent generalised.** Now serves both `/impl:jira:epics` (theme-gap scan) and `/impl:code` (multi-source fan-out scan) callers; the agent description and handoff reference updated accordingly.

### Fixed
- **`/impl:code` reclassification fallback.** When the `risk-planner` returns a reclassification notice (task is actually SIMPLE/MODERATE), the command now correctly falls back to the standard-plan path instead of staying on the Opus path.
- **Planner `reason` field and diagram label.** Minor wording corrections in the Phase 2B plan presentation.

## [1.7.1] — 2026-06-16

### Fixed
- **`docs-style-checker` now chains Vale + `dt-style-checker` as complementary passes, not fallback-only.** Previously (1.7.0) `dt-style-checker` ran only when the primary linter failed — so whenever Vale ran successfully, the entire semantic / cross-page class of findings was silently dropped (engineer jargon like `latest-minus-one`, cross-page UI-label consistency, subject-verb agreement, plural/singular label mismatch). Vale and `dt-style-checker` are complementary, not redundant. Now, when the primary linter succeeds, `dt-style-checker` ALSO runs as a complementary pass and both finding sets are merged with line-level dedupe; fallback behaviour is preserved when the primary fails; the chain degrades to primary-only when `dt-style-guide` is not installed. Output **schema v3**: `linter`/`command` → `primary_linter`/`primary_command`, new `complementary_linter`/`complementary_command`/`complementary_error`, and each violation carries a `source: primary|complementary` tag. `/impl:jira:docs` Phase 6.7 and `/impl:docs` Phase 3.5 updated to describe the internal chain (the command no longer dispatches `dt-style-checker` separately). Ports Copilot dev-workflows v1.8.2.
- **`/impl:docs` phase-numbering contradiction fixed** — the "There is no Phase 3.5" disclaimer was stale after 1.7.0 added a mandatory Phase 3.5 style check.

## [1.7.0] — 2026-06-16

### Added
- **Source-truth discrepancy escalation (`references/source-truth.md`).** The docs flow now verifies user-visible claims against the shipped source and, when Jira and source disagree, escalates to the user (`/impl:jira:docs` Phase 5.8) instead of silently picking a side — document-as-source / document-as-jira (+ `<KEY>-implementation-gaps.md` bug-report draft + `intentional-discrepancy` marker) / skip-and-report. `doc-planner` records both `jira_phrasing` and `source_phrasing` (never auto-corrects); `doc-reviewer` gains a marker-aware Source-code accuracy dimension; the release-notes flow escalates the same way. Ports Copilot dev-workflows v1.7.0 + v1.8.0.

### Fixed
- **Style checks are robust and mandatory.** `docs-style-checker` falls back to the LLM-based `dt-style-checker` when the primary linter (Vale, etc.) errors or is missing — `NOT_CONFIGURED` only when nothing is available. `/impl:jira:docs` Phase 6.7 and a new `/impl:docs` Phase 3.5 are mandatory. `risk-planner` forbids recommending a skipped style check. (Copilot v1.7.0)
- **`doc-planner` accuracy rules.** No Jira key in changelog entries (commit carries traceability); no changelog-only frontmatter updates; cross-product parity touches are one-line pointers, never copied implementation detail. (Copilot v1.7.1 + v1.8.1)

## [1.6.0] — 2026-06-16

### Added
- **`/impl:jira:release-notes` command.** Standalone Jira-driven release-notes
  drafting: reads a VI (or any ticket) from the vault, optionally grounds the prose
  in merged PR diffs (reusing `$REPOS_PATH` resolution + `diff-summarizer`), and
  renders the dynatrace-docs authored release-notes body — a `{{#context}}` label,
  an `### title`, and customer-facing prose. The draft carries **no Jira IDs, no PR
  links, and no `{{#internal-note}}` block**; it is pasted into the ticket's Jira
  release-notes field, where the docs team's automation adds the metadata wrapper.
  Light `dt-style-checker` gate (optional; skipped if `dt-style-guide` is absent).
  Never branches, commits, or writes into the docs repo; the default destination is
  persistent.
- **`release-notes-writer` agent** + handoff reference — renders the
  `release_notes_block` (one entry per declared release version).

### Fixed
- **Docs flow no longer treats release notes as a repo write target.** `doc-planner`
  and `doc-location-finder` previously proposed "What's New / Release Notes" pages as
  documentation targets, but those pages are generated from Jira by automation — a
  manual write would be overwritten. Both now exclude release-notes / what's-new paths,
  and `/impl:jira:docs` defers release notes to `/impl:jira:release-notes`.

## [1.5.1] — 2026-06-16

### Fixed
- **`/impl:jira:docs` screenshot staging is now persistent.** When a docs repo's
  `image_policy` is `cdn_upload_required`, screenshots awaiting manual CDN upload
  were staged under `/tmp/<JIRA_KEY>-screenshots/`. `/tmp` is in-image and
  ephemeral, so the staged files were lost on container restart — before the user
  had uploaded them. Staging now targets the ticket's **persistent Obsidian project
  folder** under `$VAULT_PATH` (always host-mounted), resolved by the command as a
  directory under `$VAULT_PATH/Projects/` whose name starts with `<JIRA_KEY>` (its
  `Doc screenshots/` or `Attachments/` subfolder); when no project folder is found
  the command asks for a persistent directory. The command passes the resolved
  `screenshot_staging_dir` to `doc-planner`. Neither the docs repo (which may be a
  docker repo-volume, not on the host) nor `/tmp` is used. Affects `doc-planner` and
  the `/impl:jira:docs` Phase 1 resolution, Phase 6 writer step, Phase 9 report, and
  invariants.

## [1.5.0] — 2026-06-16

### Changed (breaking for orchestrators that hardcode `/repos/`)
- **`/impl:jira:*` repo discovery is now `$REPOS_PATH`-based.** The old fixed
  `<repos_base>/<slug>` directory lookup (default `/repos`) is replaced by a scan
  rooted at `$REPOS_PATH` (default `/workspace`; colon-separated list supported)
  that maps each PR's repo-URL slug to an absolute local clone by matching
  `git remote get-url origin`. Multiple clones of one upstream are disambiguated
  by the preference order `<slug>-repo` > `<slug>_repo` > `<slug>_fast` >
  alphabetically last. This matches the container's `/workspace` umbrella layout
  (every repo and the Obsidian vault mounted under `/workspace`).
- **`diff-summarizer` / `code-scanner` inputs.** `repo_path` is now any absolute
  path (no longer assumed `/repos/<name>`), and a new optional `repo_url_slug`
  enables an upstream cross-check — on mismatch the agent returns `REPO_MISSING`
  instead of summarising the wrong repo.
- **`preload-context.sh`.** Emits `repos_path: ${REPOS_PATH:-/workspace}`
  (previously `repos_base: ${REPOS_BASE:-/repos}`).

### Migration notes
- If your clones still live under `/repos`, set `REPOS_PATH=/repos` to preserve
  the old base. The slug→clone match by `git remote` works regardless of base.

## [1.4.0] — 2026-06-15

### Changed
- **Subagent dispatch via `subagent_type`** — agents are now invoked as `dev-workflows:<agent>` (e.g. `dev-workflows:risk-planner`); Claude Code loads each agent's file body as its system prompt and honours its `model:` frontmatter. No caller-side `model` override or file-path read is needed. Supersedes the earlier `general-purpose` + `"Read and adopt ~/.claude/agents/<name>.md"` workaround.
- **Bundled reference paths via `${CLAUDE_PLUGIN_ROOT}`** — agent and skill bodies (and hook configs) now reference vendored docs via `${CLAUDE_PLUGIN_ROOT}/references/...` instead of hardcoded absolute data-directory paths.
- **`model-routing` skill** — new skill for command-level classification; slash commands invoke it to load `references/model-routing/classification.md` (skills can resolve `${CLAUDE_PLUGIN_ROOT}`, commands cannot).
- **Model fallback chain refreshed** — Opus 4.8 / Sonnet 4.6 with hyphenated model IDs throughout `references/model-routing/classification.md`.
- **Guideline commands (`/api-guideline-reviewer`, `/guideline-reviewer`) now dispatch their review in a subagent** — consistent with the rest of the command set.
- **`preload-context.sh` cosmetic fix** — the model-routing path hint now reads "invoke the model-routing skill" instead of the old `~/.claude/plugins/data/...` absolute path.

## [1.3.0] — 2026-05-15

### Changed
- **Cross-platform naming sync with Copilot CLI plugin (v1.3.0).**
  - Renamed `code-diff-summarizer` agent → `diff-summarizer` (aligns with
    Copilot CLI naming; all cross-references updated repo-wide).
  - Renamed `test-baseline` agent → `test-baseliner` (aligns with Copilot
    CLI naming; all cross-references updated repo-wide including handoff
    docs, orchestrator commands, and design specs).
  - Version numbers now track 1:1 between Claude Code and Copilot CLI
    plugin repos. Previous version drift: Claude 1.2.1 / Copilot 1.2.1.

## [1.2.1] — 2026-05-15

### Added
- **`upgrade-planner` agent.** Dedicated sub-agent for analysing a project and
  producing a versioned, step-by-step upgrade plan with risk annotations.
- **`upgrade-executor` agent.** Dedicated sub-agent that executes an approved
  upgrade plan step-by-step, running builds/tests after each step.
- **`vuln-research` agent.** Dedicated sub-agent for vulnerability triage —
  reads advisories, assesses exploitability, and recommends fix vs mitigate.
- **`vuln-fixer` agent.** Dedicated sub-agent that applies vulnerability
  remediation (dependency bumps, code patches) and verifies the fix.
- **Nine handoff reference docs** under `references/handoff/` for sub-agents
  that receive delegated work: code-scanner, diff-summarizer,
  impl-maintenance, jira-reader, test-baseliner, upgrade-executor,
  upgrade-planner, vuln-fixer, vuln-research.

### Changed
- `/upgrade` command refactored to delegate planning and execution to the new
  `upgrade-planner` and `upgrade-executor` agents via the `task` tool.
- `/vuln` command refactored to delegate research and remediation to the new
  `vuln-research` and `vuln-fixer` agents via the `task` tool.
- `CLAUDE.md` expanded from 60 → 204 lines: added skill taxonomy table,
  orchestrator/sub-agent relationship diagram, model-routing contract,
  key invariants, test requirements, update procedures, and guardrails.

## [1.2.0] — 2026-05-15

### Added
- **`guideline-reviewer` agent.** Reviews code and UI for compliance with
  Dynatrace Experience Standards (GUIDElines). Covers component usage
  (AppHeader, DataTable, FilterField, etc.), accessibility/WCAG compliance,
  terminology, settings patterns, and permissions. Reference docs in
  `references/guidelines/`.
- **`api-guideline-reviewer` agent.** Reviews OpenAPI specification files
  against Dynatrace REST API and IAM permission naming guidelines. Two-pass
  review (comprehensive analysis + detailed verification) checking version
  consistency, required elements, naming conventions, IAM scope format,
  HTTP status codes, and schema composition. Reference docs in
  `references/api-guidelines/` (REST API guidelines, permission guidelines,
  and an OpenAPI template).
- **`check_guidelines.py` script** in `references/guidelines/` — automated
  checklist generator for GUIDEline reviews.
- **`checklist-template.md`** in `references/guidelines/` — structured
  review template.

### Changed
- `plugin.json` keywords expanded.
- `marketplace.json` description updated (15 → 17 agents).
- **Model routing reference (`references/model-routing/classification.md`)
  expanded** from 92 to 265 lines — now includes model fallback chain,
  `model_routing` handoff block format, `task` tool delegation pattern,
  mandatory code-review checklist verdicts, and reporting section (synced
  from Copilot CLI port).

## [1.1.0] — 2026-05-10

`plugin.json` and `marketplace.json` declare `1.1.0`. The work landed across seven increments:

- **Increment A** — scaffolding (commit `25c73fc`)
- **Increment B** — `/impl:code` + `test-writer` agent (commit `29a727f`)
- **Increment C** — `/impl:docs` one-shot doc editing (commit `052e772`)
- **Increment D** — `/impl:jira:docs` + `/impl:jira:epics` + 9 agents (commit `e785adb`)
- **Increment E** — hook regex, README refresh, marketplace description refresh
- **Increment F** — per-command routing in `preload-context.sh` per spec §3 table (commit `4e18081`)
- **Increment G** — `/impl` repurposed as a dispatcher (breaking for 1.0.x users); verbatim-copy maintenance tax eliminated (this commit)

### Breaking changes
- **`/impl <description>` no longer runs the code-implementation workflow** (Increment G). In 1.0.x, `/impl <description>` was the canonical invocation for the full code workflow. In 1.1.0, `/impl` is a **dispatcher**: it prints a help message listing the `/impl:*` variants plus `/vuln` / `/upgrade`, then stops. If you have muscle-memory invocations like `/impl add rate limiting`, re-run them as `/impl:code add rate limiting` — the workflow body is unchanged (it lives in `commands/impl/code.md` and is registered as the slash command `/impl:code`). No aliasing; the redirect is a printed message only. Mid-1.1.0, an Increment-A iteration briefly shipped `commands/impl.md` as a verbatim copy of `commands/impl/code.md` with a `<!-- KEEP IN SYNC -->` marker — that approach is **not** what 1.1.0 ultimately ships; Increment G replaced it with the dispatcher to remove ~27 KB of duplication and eliminate the drift risk the marker was trying to manage.

### Added
- **Namespaced command layout.** New directory `commands/impl/` with sub-files `code.md`, `docs.md`, `jira/docs.md`, `jira/epics.md` — these become the slash commands `/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics` via Claude Code's directory-to-namespace convention.
- **`/impl:code` full workflow (Increment B).** `commands/impl/code.md` is the canonical code-implementation command: classify → optional Opus planning → feature branch → **capture test baseline (new Pre-Phase 3.5)** → implement → **test-writing + regression verification (new Phase 3.5)** → optional Opus review → Phase 4 maintenance → Phase 5 report. Same structure as the pre-split `/impl`, with the two new test-related phases inserted and three new invariants added (`ALWAYS capture baseline`, `NEVER skip Phase 3.5`, `AFTER two fix-loop attempts, stop and surface`).
- **`commands/impl.md` is now a dispatcher** (final shape after Increment G). Prints a help page listing the four `/impl:*` variants (`/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`), a Related-commands section for `/vuln` and `/upgrade`, and a migration note pointing 1.0.x users at `/impl:code`. Does not execute any workflow — no classification, no branching, no agents, no git. The file is ~40 lines instead of ~27 KB; no "keep in sync" marker is needed because there is no longer a shadow copy of `commands/impl/code.md`. See the **Breaking changes** section above for the 1.0.x impact.
- **`agents/test-writer.md` (Increment B).** Default-model agent that writes tests for new or changed behaviour based on a diff. Mirrors `test-baseliner`'s framework detection and returns `Framework: not detected` immediately if none matches, so the caller can ask the user. Does NOT run tests — the caller runs `test-baseliner` verify separately. Hard rules: never retrofit tests for unchanged code, never invent a framework the project doesn't already use, never modify production code.
- **`/impl:docs` full workflow (Increment C).** `commands/impl/docs.md` is the one-shot doc-editing command: classify (always SIMPLE or MODERATE — redirects to `/impl:jira:docs` / `/impl:jira:epics` if the task turns out to be SIGNIFICANT on inspection) → plan with the `/impl:code`-style repo-exploration subagent → implement → validation checks (link integrity, heading structure, frontmatter parse, broken `[[wikilinks]]`) → Phase 4 maintenance → Phase 5 report. No branch, no baseline, no tests, no Opus, no commit — the user manages git manually. Phase 4 handoff sets `Change type: docs` and `Command run: /impl:docs`. Explicit invariants block all five "never" axes.
- **`/impl:jira:docs` full workflow (Increment D).** `commands/impl/jira/docs.md` is the Jira-driven feature-documentation command: Phase 0 vault + docs-repo detection → Phase 1 PR-status filter / refresh policy / `<repos_base>` / optional screenshot paths → Phase 1.5 classification (SIGNIFICANT; Jira read *is* the plan so no Opus planning) → Phase 2 plan + approval → Phase 3 `jira-reader` depth `full` → Phase 4 repo resolution (escalate missing per §15) → Phase 5 parallel `diff-summarizer` (batches of 4; aggregate "All PRs unresolved" gate) → Phase 5.5 `doc-location-finder` (3 status branches) → Phase 5.7 `doc-planner` (gap dispositions: ask-user / mark-TODO / skip-with-note) → Phase 6 writer (main command, with three-branch `image_policy` screenshot placement — `local` / `cdn_upload_required` / `ambiguous`) → Phase 6.5 branch setup (conditional on `docs_repo` context + user opt-in at plan approval) → Phase 6.7 `docs-style-checker` + `doc-fixer` + re-lint → Phase 7 `doc-reviewer` Opus gate (1-fix-1-rereview cap; per-BLOCKER escalation) → Phase 8 four maintenance agents in a single message → Phase 9 final report including `### Screenshots to upload manually` when any target used `cdn_upload_required`. Phase 8 handoff sets `Change type: docs` and `Command run: /impl:jira:docs`. Invariants from spec §6 preserved verbatim.
- **`/impl:jira:epics` full workflow (Increment D).** `commands/impl/jira/epics.md` is the Jira-driven Epic-writing command: Phase 0 vault-only context check (refuses to run outside `$VAULT_PATH`) → Phase 1 output dir / code-scan on-off / refresh policy / `<repos_base>` → Phase 1.5 classification (MODERATE; no Opus planning) → Phase 2 plan + approval → Phase 3 `jira-reader` depth `vi-plus-epics` (VI + every Epic linked to it, skipping Stories / Sub-tasks / Research / RFA) → Phase 4 conditional repo resolution (auto-derived from sibling Epics' PR URLs or manual) → Phase 5 conditional parallel `code-scanner` (batches of 4; scanner defaults `pull: true`, deliberately asymmetric with `diff-summarizer`'s `pull: false`) → Phase 6 writer (one `.md` per Epic with `## Goal` / `## Business value` / `## Scope (in / out)` / `## Acceptance criteria` / `## Dependencies` / `## Suggested stories` / `## References`) → Phase 7 `epic-reviewer` Opus gate (1-fix-1-rereview cap; "Defer" appends a `## Refinement notes` section to the draft) → Phase 8 four maintenance agents → Phase 9 final report. NEVER branches, NEVER commits, NEVER writes inside `jira-products/` or `_archive/`, NEVER writes outside `$VAULT_PATH`, NEVER runs `docs-style-checker` (enforced by absence of a Phase 6.7). Phase 8 handoff sets `Change type: docs` and `Command run: /impl:jira:epics`.
- **Nine new agents (Increment D).** All declare `tools:` as YAML arrays matching the existing in-repo style (`risk-planner`, `code-review`, `test-writer`).
  - **`agents/jira-reader.md` (§12)** — reads the pre-exported Jira markdown hierarchy under `$VAULT_PATH/jira-products/<JIRA_KEY>/`; three depths (`full` / `vi-plus-epics` / `vi-only`). Output: `value_increment` + `linked_items` + `pull_requests` + `themes`. Parses the Jira-to-Obsidian exporter's two-line-per-PR bulleted format with backticked branch names and a Unicode `→` arrow (not ASCII `->`). Three host categories recognised (`github_cloud`, `bitbucket_cloud`, `bitbucket_server`); `bitbucket_server` detected by the substring rule (hostname contains `bitbucket` and is not `bitbucket.org`), never a hardcoded domain. Inherits the session's model.
  - **`agents/doc-fixer.md` (§10)** — shared between `/impl:jira:docs` and `/impl:jira:epics`. Applies BLOCKER / MAJOR fixes from a `doc-reviewer`, `epic-reviewer`, or `docs-style-checker` output. Returns a `Fix Report` with the same `Stop condition flag` contract as `review-fixer`. Doc-type-agnostic because the finding schema is shared. Inherits the session's model.
  - **`agents/diff-summarizer.md` (§13)** — resolves a single repo's PR diffs and returns a doc-focused summary. Host-aware resolver: `gh` CLI for `github_cloud` (when installed + authenticated), local-git Strategies 1–4 for the rest (including GitHub fallback). Strategy 1: Bitbucket Server `refs/pull-requests/*` (usually absent). Strategy 2: branch search (0 or 2+ matches fall through silently). Strategy 3: merge-commit grep (`[Pp]ull[ _-]?[Rr]equest[ _-]?#?<pr_id>\b`). Strategy 4: cross-hierarchy Jira-key commit grep (last resort; summary MUST carry the "reconstructed from commit — may not exactly correspond" caveat). Statuses: `OK` / `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED` / `NO_PRS_RESOLVED` / `PARTIAL`. `refresh.pull` defaults to `false`. Inherits the session's model.
  - **`agents/doc-location-finder.md` (§10a)** — finds write target(s) in a docs repository. Heuristic + grep scoring across the detected docs-tree root(s); three placement kinds (`extend-existing` / `new-page-in-existing-section` / `new-section`). Statuses: `OK` / `LOW_CONFIDENCE` (with `confidence_notes`) / `EMPTY`. Never writes. Inherits the session's model.
  - **`agents/doc-planner.md` (§10b)** — synthesises the documentation checklist the writer follows and `doc-reviewer` checks against. Detects the repo's `image_policy` by sampling sibling / ancestor markdown pages: `local` (copy screenshots to `<page-dir>/img/`), `cdn_upload_required` (stage under `/tmp/<JIRA_KEY>-screenshots/` — NEVER inside the repo — and surface in Phase 9), or `ambiguous` (writer prompts the user at Phase 6). Per-page YAML frontmatter updates (including the mandatory `changelog:` append), snippet reuse / extract, cross-links, and gap dispositions. Inherits the session's model.
  - **`agents/docs-style-checker.md` (§10c)** — runs the repo's project-configured prose linter on files written in Phase 6 and normalises output into the shared finding schema. Detection order: Vale via `.vale.ini` → `package.json` `*:lint` / `lint:*` script → `.markdownlint.json(c)` / `.remarkrc*` → `NOT_CONFIGURED`. Severity mapping: `error` → MAJOR, `warning` → MINOR, `suggestion` → NIT. 2-minute cap. Never promotes linter severity. Inherits the session's model.
  - **`agents/doc-reviewer.md` (§9, Opus)** — reviews product documentation written by `/impl:jira:docs`. Eleven dimensions: factual correctness, completeness vs plan, coverage, audience fit, structural integrity, YAML frontmatter, screenshots (both `image_policy` branches), snippets, actionability, source traceability, style-check follow-through (from `docs-style-checker`). Verdict: PASS / PASS WITH RECOMMENDATIONS / BLOCK. `model: opus` declared in frontmatter and `model: "opus"` passed on the caller's Agent call (belt-and-braces, mirroring `risk-planner` / `code-review`).
  - **`agents/code-scanner.md` (§14)** — scans a single code repo for existing capabilities and gaps relative to a set of themes. Pure filesystem search (grep / glob / read); no HTTPS. `refresh.pull` defaults to `true` (capability scans target the default-branch tip — deliberately asymmetric with `diff-summarizer`). Per-theme 30-second budget; themes that can't be scanned get `classification: error` + reason and do NOT abort the whole scan. Statuses: `OK` / `PARTIAL` / `REPO_MISSING` / `DIRTY_TREE` / `REFRESH_BLOCKED` / `EMPTY`. Inherits the session's model.
  - **`agents/epic-reviewer.md` (§9b, Opus)** — reviews Epic drafts written by `/impl:jira:epics`. Nine dimensions: goal clarity, business value, scope (in / out), acceptance criteria (testable), dependencies, suggested stories, non-duplication (BLOCKER when undetected; cross-checks against `jira-reader` `linked_items` filtered to `type == Epic`), references (code paths must match `code-scanner` `evidence.path` when that output is provided), structural integrity. Never treats the absence of a `code-scanner` output as a finding — the user may have opted out of code examination. `model: opus` in frontmatter + `model: "opus"` on the caller's Agent call.

### Changed
- **`agents/impl-maintenance.md` input / output enums.** The Inputs section now requires a `Command run:` field (one of `/impl`, `/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`, `/vuln`, `/upgrade`); missing values default to `/impl:code` with a note in the report. The "Command workflow improvements" output enum broadened to match, so maintenance suggestions from the three new Jira/docs commands are scoped to the right command variant.
- **`commands/vuln.md` and `commands/upgrade.md` session handoffs.** Both now pass `Command run: /vuln` and `Command run: /upgrade` respectively to `impl-maintenance`. Without this, the agent would default to `/impl:code` and misattribute any `/vuln` or `/upgrade` suggestions — a silent regression the spec's Wave 6 W6-m2 + §3 update implied but didn't explicitly call out for the two pre-existing commands.
- **`commands/impl/code.md` Phase 4 change summary block now includes `Change type: code`** (and a matching invariant). Aligns with `/impl:docs` (`Change type: docs`) and the two new Jira commands (both `docs`). The field is a scoping hint for the Documentation / Knowledge / Instructions maintenance agents — their prompts already reference the change summary block, so no agent prompt changes are needed.
- **`hooks/preload-context.sh` regex (Increment E).** Replaced `^/(impl|vuln|upgrade)[[:space:]]+[^[:space:]-]` with `^/(impl(:(code|docs|jira(:(docs|epics))?))?|vuln|upgrade)[[:space:]]+[^[:space:]-]` so `/impl:code`, `/impl:docs`, `/impl:jira:docs`, and `/impl:jira:epics` now trigger context injection. The normative regex is defined in spec §3 and verified against a 28-case matrix. Bare `/impl:jira foo` also matches — the `:(docs|epics)` sub-namespace is optional by design (over-match is preferable to missing a valid invocation). Header comment updated to list all covered commands.
- **`hooks/preload-context.sh` per-command routing (Increment F).** After the regex match the hook now reads `${BASH_REMATCH[1]}` and routes per the spec §3 table: `/impl`, `/impl:code`, `/vuln`, `/upgrade` get the full block (model-routing reminder + git status + recent commits + small-repo directory listing); `/impl:jira:docs` and `/impl:jira:epics` get a `Jira workflow` header with `VAULT_PATH` (or an unset-note fallback), a `repos_base` default (`${REPOS_BASE:-/repos}`), and `git branch --show-current` only when cwd is inside a git repo — no model-routing, no full status/log, no directory listing; `/impl:docs` exits silently (spec: "None — user manages git manually; model-routing is not triggered"). Bare `/impl:jira foo` (spec-intentional over-match) is routed to the Jira branch. Verified with a 10-assertion stdin harness covering all four routing paths plus noise.
- **`hooks/preload-context.sh` — `/impl` moved to silent branch (Increment G).** Follows the dispatcher change. `/impl <args>` now prints help and stops, so injecting the full git context + model-routing reminder would be pure noise before a help screen. `/impl:code`, `/vuln`, `/upgrade` continue to get the full context; `/impl:jira:docs` / `/impl:jira:epics` continue to get the Jira context; `/impl` joins `/impl:docs` in the silent branch. This is a minor deviation from spec §3's "`/impl` (alias) → Full" row, justified by the alias no longer existing; the spec table is superseded for the `/impl` row by Increment G.
- **`agents/impl-maintenance.md` — `/impl` removed from the live Command-run enum (Increment G).** The Inputs section now lists six live values (`/impl:code`, `/impl:docs`, `/impl:jira:docs`, `/impl:jira:epics`, `/vuln`, `/upgrade`). For replay compatibility with archived 1.0.x handoffs, the literal legacy value `/impl` is still accepted on input and internally mapped to `/impl:code` with a note in the report. The "Command workflow improvements" output enum drops `/impl` entirely — the agent will never suggest changes against a command that no longer runs a workflow.
- **`commands/impl/code.md` Phase 4 handoff (Increment G).** Dropped the now-stale parenthetical on the `Command run: /impl:code` line that explained the "`/impl` alias is a transport detail". The alias is gone; no explanation is needed.
- **`README.md` refresh (Increment E).** Rewritten to document the final 1.1.0 shape: dropped the "1.1.0 in progress" banner; rebuilt the Commands section as a 5-row table for the `/impl` family plus a secondary 2-row table for `/vuln` and `/upgrade`; rebuilt the Agents section as 15 rows with a Model column (Opus for `risk-planner`, `code-review`, `doc-reviewer`, `epic-reviewer`; `inherits` for the other 11); added an Environment prerequisites section covering `gh auth login`, optional `vale`, and the recommended [ihudak/ai-containers](https://github.com/ihudak/ai-containers) environment (per spec §17); updated the Hooks table to list the seven command shapes the matcher now covers.
- **`.claude-plugin/marketplace.json` dev-workflows description (Increment E).** Refreshed from "Three slash commands (/impl, /vuln, /upgrade) … five reusable subagents … three notification hooks" to name all five `/impl`-family commands plus `/vuln` and `/upgrade`, list all fifteen subagents, and describe the three notification / context hooks. `version` field unchanged (1.1.0).

Design spec: `docs/superpowers/specs/2026-04-30-impl-split-and-test-writing-design.md`.
Review history: `docs/superpowers/specs/2026-05-08-impl-split-and-test-kiro-review.md` (waves 1–7).

---

## Pre-plugin-split history (prior monorepo)

The sections below describe the original [`ihudak-claude-plugins`](https://github.com/ihudak/ihudak-claude-plugins) monorepo from which this plugin was extracted. They reference infrastructure that no longer applies to the standalone plugin — root-level `install.sh` / `uninstall.sh` / `install.ps1`, `plugins/workflow-tools/`, `tests/smoke.sh`, and `~/.claude/settings.json` hook merging. Retained as provenance; not part of the **dev-workflows** plugin's own version history.

### [Unreleased] (pre-plugin-split)

#### Added
- **Model routing across `/impl`, `/vuln`, `/upgrade`.** Every command now classifies the task as `SIMPLE`, `MODERATE`, `SIGNIFICANT`, or `HIGH-RISK` before planning. `SIMPLE` / `MODERATE` continue on the currently selected model. `SIGNIFICANT` / `HIGH-RISK` route planning and post-implementation review through Opus and gate the test run on the review verdict.
- **`agents/risk-planner.md`** — Opus-backed risk-weighted planner system prompt. Returns a structured plan with explicit security, migration, API-stability, concurrency, dependency, rollback, and test-adequacy sections. Refuses to run without a classification. Includes a re-classification escape hatch: if the task turns out to be `SIMPLE` / `MODERATE` on inspection, the planner returns a `### Re-classification` section instead of the full plan and the caller falls back to the non-Opus path.
- **`agents/code-review.md`** — Opus-backed post-implementation reviewer system prompt. Checks eight dimensions (correctness, security, architecture, edge cases, migration risks, dependency risks, test adequacy, rollback). Returns `PASS` / `PASS WITH RECOMMENDATIONS` / `BLOCK`. `BLOCK` gates the test run. Same re-classification escape hatch.
- **`agents/test-baseliner.md`** — moved from `plugins/workflow-tools/` to the repo's top-level `agents/`. Same behaviour, now installed at `~/.claude/agents/test-baseliner.md` as a user-level subagent.
- **`agents/review-fixer.md`** — default-model agent that auto-fixes BLOCKER and MAJOR findings from a code-review report, deferring findings that require design judgment, migration sequencing, or cross-cutting test strategy. Returns a structured fix report with a `Stop condition flag` so callers know whether to re-review. Wired into all three commands' BLOCK and PASS-WITH-RECOMMENDATIONS branches.
- **`agents/impl-maintenance.md`** — default-model suggest-only post-session analyst. Reads the session handoff, scans existing rules/hooks/agents, returns a structured Lessons Learned report (CLAUDE.md rules, hooks, reference doc gaps, new agent suggestions, command workflow improvements). Does not write files.
- **`references/model-routing/classification.md`** — single source of truth for the four complexity levels, the triggers, the routing rules, and the eight review dimensions. All three commands link to it.
- **`tests/smoke.sh`** — install → uninstall → install smoke test in a throwaway `HOME`. 54 assertions. Covers full install, idempotent re-run, subtractive `--no-hooks`, `--no-plugin` rejection (the flag is retired), `uninstall.sh`, round-trip re-install, legacy `plugins/workflow-tools` cleanup, JSON validity, and agent-file frontmatter validation.
- **`uninstall.ps1`** — native Windows uninstaller (PowerShell). Mirrors `uninstall.sh`: removes managed symlinks/copies and strips hook entries from `settings.json` if Python is available.
- **`.gitignore`** — added `settings.local.json`, `settings-local.json`, `.claude/settings.local.json` to prevent accidental commit of Claude Code machine-specific overrides.
- **`test-baseliner.md` verify mode** — second mode alongside `capture`: re-runs tests, diffs against a prior baseline, returns a structured regression report (regressions, missing-from-run, newly fixed, new failures, current snapshot for chaining). All three commands now use verify mode for post-fix comparisons.
- **Feature-branch pre-step in `/impl`, `/vuln`, `/upgrade`** — clean-tree check (stash/proceed/cancel), branch-convention detection, slug generation, HEAD context check, `git checkout -b` BEFORE any file is written. Branch naming: `feat/<slug>` for impl, `chore/upgrade-<component>-to-<ver>` for upgrade, `fix/[JIRA-]CVE-XXXX-XXXXX` for vuln.
- **Ruby/Bundler section in `references/fix-vuln/build-systems.md`** and **PHP/Composer section in `references/upgrade/ecosystems.md`** — expand ecosystem coverage to match `/vuln` Detect agent scan list.

#### Changed in commands
- **`/impl`** — new Phase 1.5 classification step; for `SIGNIFICANT` / `HIGH-RISK`, planning is delegated to `risk-planner` (Opus) and the post-implementation `code-review` (Opus) gates the test run. Implementation itself stays on the currently selected model or Sonnet — Opus is reserved for planning and review. Phases 4 and 5 include the classification and the review verdict. Phase 2B "Revise" re-sends the full risk-planner brief (the planner refuses partial briefs).
- **`/vuln`** — step 5 classifies each CVE on the actual change required (same-major patch/minor bump → `MODERATE`; major bump or API-break or security-sensitive code path → `SIGNIFICANT` / `HIGH-RISK`). `MODERATE` keeps the existing flow; `SIGNIFICANT` / `HIGH-RISK` delegate planning to Opus, review the fix with Opus, and gate tests on the verdict. Classification is included in the commit message and PR body. The risk-planner brief no longer overstates the inputs — it passes declaration paths from the Detect agent and lets the planner do its own usage-site grep.
- **`/upgrade`** — Phase 1 step 5 classifies each component. `MODERATE` components follow the existing apply → build → test path. `SIGNIFICANT` / `HIGH-RISK` components plan with Opus (Phase 1 step 8) and get an Opus review before build/test (Phase 2 step 6). Summary table gains `Class` and `Review` columns. Same brief-correctness fix as `/vuln` — the brief passes inventory paths + Agent A's compat output and delegates usage-site scanning to the planner.

#### Changed in hooks
- **`preload-context.sh`** — injects a one-line model-routing reminder before the existing git context for `/impl`, `/vuln`, `/upgrade`. Points at `references/model-routing/classification.md` so the rules are one read away. Regex tightened to require at least one non-whitespace, non-hyphen argument so bare `/impl` or `/impl --help` no longer triggers a context injection. Directory listing now gated to repos with ≤30 root entries — large repos no longer leak the listing into context.

#### Changed in installers / docs
- **`install.sh --no-hooks` is subtractive**, not just a skip-flag. It actively removes previously-installed hook symlinks and strips matching entries from `settings.json` so the post-flag state matches what users expect.
- **`uninstall.sh` and `uninstall.ps1` symlink matching tightened** — require a path-segment boundary (`/claude-config/` rather than a loose substring) so unrelated paths like `claude-config-backup` can't be matched.
- **`install.sh` / `install.ps1` legacy-plugin cleanup** — on upgrade from a pre-restructure install, both installers remove any leftover `~/.claude/plugins/workflow-tools` symlink and drop the empty `~/.claude/plugins/` parent if nothing else lives there.
- **`README.md`** — surfaces the Windows installation path from the main Install section; adds the native Windows uninstall command and update workflow; documents the new `Class` / `Review` columns in the `/upgrade` example table; new "Subagents" section explaining the `general-purpose` + `model: "opus"` invocation pattern; replaces "commands + plugin" framing with "commands + agents".

#### Fixed
- **Subagent invocation pattern: `general-purpose` + `model` override.** Earlier iterations of this release tried two layouts that did not actually register the subagents — `plugins/workflow-tools/` (which requires marketplace registration + `installed_plugins.json` + `enabledPlugins`, not satisfied by a local symlink) and a user-level `agents/*.md` install (which requires a session restart to be discovered). Both produced static-correctness wins but a no-op routing in the installing session. The three commands now invoke the agents via `Agent(subagent_type: "general-purpose", model: "opus", prompt: "Read and adopt ~/.claude/agents/<name>.md, then [brief]")`. The `model` argument on the `Agent` tool itself forces Opus for `risk-planner` / `code-review` regardless of discovery; `test-baseliner` omits the override and inherits the session's model. Agent files are still installed at `~/.claude/agents/` so a future Claude Code release with reliable user-agent discovery can invoke them directly with no further changes. Verified empirically in-session. Removes the `--no-plugin` installer flag (the agents are required by `/vuln`, `/upgrade`, and the Opus-gated `/impl` flow — there is no opt-out).
- **`agents/risk-planner.md` and `agents/code-review.md` cite classification rules by absolute path** (`~/.claude/claude-config/references/model-routing/classification.md`). The agents' working directory is the caller's project, not this repo, so relative paths wouldn't resolve.
- **Classification file-count threshold made exclusive** — was `more than 3-5` on SIGNIFICANT and `fewer than 3-5` on MODERATE, which both matched at exactly 4. Pinned to `4 or more` for SIGNIFICANT and `3 or fewer` for MODERATE.
- **`agents/test-baseliner.md` Makefile parse row** — previously detected `make test` but had no parse pattern; a Make-driven project would silently get `Total: 0 | Passing: 0 | Failing: 0`. The parse table now has a Make row with best-effort pattern matching and a note explaining the limitation.
- **`install.ps1` / `uninstall.ps1`** — removed PowerShell 7+ only operators (`||`, `??`) that broke on Windows PowerShell 5.1 (the default on Windows 10/11). Replaced with PS5.1-compatible forms.
- **`install.ps1` / `uninstall.ps1`** — replaced em-dashes and box-drawing characters with ASCII. Windows PowerShell 5.1 reads BOM-less script files using the ANSI code page, which mangled UTF-8 multi-byte sequences and caused parser errors at every line with fancy characters.
- **`uninstall.ps1`** — probe Python with a real `--version` call before using it, so the Windows Store `python3.exe` stub (a placeholder that errors at runtime) is correctly identified as "not Python" and the script prints a helpful skip-message instead of a red error.
- **NVD/Detect circular dependency in `/vuln`** — split research into Round A (NVD + Baseline in parallel, no package name needed) then Round B (Detect agents per CVE, package names now known). Per-CVE failure handling explicit.
- **`subagent_type: "Explore"`** replaced with `general-purpose` + explicit Read/Glob/Grep/LS tool restrictions in `/impl` and `/vuln` (Explore is not a valid Claude Code Agent type).
- **`git diff` for new-file-only implementations** — all three commands now use `git add -N . && git diff` so the code-review agent never receives an empty diff.
- **`/upgrade` Agent B is now read-only** in Phase 1; changes are applied in Phase 2 prep step 3, AFTER baseline capture, so the baseline is pristine.
- **`/upgrade` Opus planning** moved before user confirmation; user now sees the full Opus-generated plan before approving.
- **`code-review.md` `Bash` removed from tools list** — reviewer must be read-only; the "NEVER modify files" prompt rule is now enforced by the toolset.
- **Stop condition enforcement** — all three commands enforce: after one review-fixer pass + one re-review, if verdict is still BLOCK, stop and surface to user. No infinite loops.
- **OWASP filter regex** in `/vuln` — `A\d` → `A\d{2}` (OWASP IDs use two digits).
- **`/vuln` Detect agent scan list** expanded to include `*.csproj`, `Gemfile`, `composer.json` (aligning with `build-systems.md` coverage).
- **`hooks/test-notify.sh` ARG_MAX** — switched from passing test output as argv to stdin pipe; large test outputs (>128KB on Linux, >256KB on macOS) no longer crash the hook.
- **`commands/vuln.md` SIGNIFICANT/HIGH-RISK path numbering** — fixed duplicated step 4, missing step 5; downstream references updated.
- **`commands/upgrade.md` Phase 2 structure** — split into "Phase 2 prep (once)" + per-component loop with unambiguous numbering (prep: 1–3, loop: 1–8).
- **`commands/impl.md` Phase 4 agent count** — corrected "three agents" → "four agents".
- **`commands/impl.md` Phase 5 report** — now surfaces feature-branch name under `### Branch`.
- **`references/model-routing/classification.md`** — "4+ non-test files" threshold qualified to require non-trivial logic changes (excludes pure renames, import updates, mechanical refactors, generated-code changes).
- **`references/fix-vuln/nvd-api.md` safe-version derivation** — added worked examples for `.Final`/`-RELEASE` suffixes; clarified range-matching against project's current version line to avoid wrong-range selection.
- **`references/upgrade/compatibility.md`** — new "Known major migrations" section documenting Spring Boot `javax`→`jakarta` migration with detection command, fix approach, and companion changes.
- **`/upgrade` companion-upgrade chain** — now hard-capped at 3 levels with cycle detection; chains exceeding the limit are surfaced as `BLOCKED — companion-cycle` in the summary table (matters for unattended ai-container runs).
- **`hooks/preload-context.sh`** — directory listing gated to repos with ≤30 root entries; large repos no longer leak the listing into context.
- **`/vuln` commit template** — removed hardcoded `Co-authored-by: Claude Code <noreply@anthropic.com>` (some corp Bitbucket instances reject the email).
- **All PowerShell code fences in `references/fix-vuln/build-systems.md`** corrected to `bash` fences.

#### Verified
- End-to-end install and uninstall on Windows with both Windows PowerShell 5.1 and PowerShell 7.6.1. PS 5.1 falls back to file copies (no Dev Mode / admin); PS 7.6.1 successfully creates symlinks. Round-trip install → uninstall → install works cleanly on both. Smoke test (`tests/smoke.sh`) is 54/54 green on Linux.

### 2026-04-24 (monorepo 1.1.0)

#### Added
- **`uninstall.sh`** — idempotent reverse of `install.sh`; removes managed symlinks and strips our hook entries from `~/.claude/settings.json`.
- **`install.sh --no-hooks` / `--no-plugin` / `--help`** flags for granular installs.
- **`install.ps1`** — native Windows installer (PowerShell). Creates symlinks with auto-fallback to file copy when Developer Mode / admin isn't available. Skips hooks (bash-only).
- **`references/fix-vuln/`** and **`references/upgrade/`** — reference docs for `/vuln` and `/upgrade` are now vendored into the repo (previously external at `~/.copilot/skills/`).
- **`CHANGELOG.md`** — this file.

#### Changed
- **Hook field names corrected**: `preload-context.sh` now reads the `prompt` field (with `user_prompt`/`message` fallbacks) from the UserPromptSubmit payload; `test-notify.sh` now reads `tool_input.command` and `tool_response.output` (with top-level fallbacks) from the PostToolUse payload. Both hooks were previously silently exiting early due to reading the wrong fields.
- **`preload-context.sh` hardening** — removed `set -euo pipefail`, added `python3` availability guard, error-tolerant command substitution. Matches the robustness of `test-notify.sh`.
- **`/impl` step 8 agents** now receive a structured change summary block (including `git diff --stat` output and notable additions/removals) instead of a one-sentence description. Documentation, knowledge, and instructions agents can now reason precisely about what changed.
- **`install.sh` location guard** — refuses to run unless located at `$HOME/.claude/claude-config/`. Prevents silent misconfiguration when the repo is cloned elsewhere.
- **`install.sh` plugin symlink** — now unconditionally `rm -rf`s the target before `ln -sf`, preventing the "stray nested symlink" bug that occurred on repeated runs.
- **`install.sh` settings.json guard** — creates an empty `{}` skeleton if `~/.claude/settings.json` doesn't exist, rather than crashing.
- **`test-notify.sh` output parsing** — uses `python3` for framework output parsing (portable) instead of `grep -oP` (GNU-only, fails on macOS).
- **`/vuln` intro** — clarified the sequential-then-parallel execution model.
- **`/upgrade` Phase 2 step 3** — excludes `.github/workflows/` to prevent GitHub Actions from being processed twice.
- **README** — added detailed per-command phase explanations, Windows section, uninstall instructions, install-flag table.

### 2026-04-24 (monorepo 1.0.0)

Initial shareable repo.

#### Added
- **`commands/impl.md`** — `/impl` command with Explore subagent before planning and three parallel post-implementation agents (Documentation / Knowledge / Instructions).
- **`commands/vuln.md`** — `/vuln` command with parallel NVD / Detect / Baseline research before fix.
- **`commands/upgrade.md`** — `/upgrade` command with parallel compatibility research and GitHub Actions agents in Phase 1; uses `workflow-tools:test-baseliner` for the test baseline.
- **`plugins/workflow-tools/`** — plugin with the reusable `test-baseliner` agent (Maven / Gradle / npm / pytest / Makefile detection).
- **`hooks/notify-done.sh`** — Stop hook; cross-platform desktop notification (macOS / Linux / WSL2 fallback chain).
- **`hooks/preload-context.sh`** — UserPromptSubmit hook; injects git branch/status/log for `/impl` / `/vuln` / `/upgrade`.
- **`hooks/test-notify.sh`** — PostToolUse:Bash hook; parses test output and notifies.
- **`install.sh`** — idempotent installer; `ln -sf` symlinks + Python JSON merge.
- **`settings-additions.json`** — hook entries merged into `~/.claude/settings.json`.
- **`README.md`** — setup, usage, and platform notes.
- **`docs/specs/2026-04-24-command-subagents-hooks-design.md`** — design document.
