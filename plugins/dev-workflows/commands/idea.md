---
name: idea
description: Idea-refinement workflow (PM phase, front of the PRD-creation flow). Takes one source — an inline prompt, a markdown file (whose wikilinks are followed two levels deep and whose linked images are read as context), a community post, or a saved file (product feedback, or an existing Product Requirements Document the idea extends, parallels, or rewrites) — and, through a bounded one-question-at-a-time grill (--deep for relentless), authors a well-refined idea.md — a lean one-page brief that seeds the future /create-prd. Copies the sources it actually read into the PRD folder (text and markdown into attachments/, images into design/idea-sources/ with the index that frame set requires) and rewrites idea.md's links onto the copies. Writes into the PRD folder the key names; no code change; `idea.md` lands in `$SPECS_PATH/specifications/PRD-<KEY>-<slug>/` on the first write and is never relocated (D7), and on a completed handoff the run also opens a pull request for it (`references/phase-handoff.md` §2) — declining leaves it written in place but not on the default branch; its session artifacts are committed by `commit-artifacts`.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill WebFetch
---

Refine an idea into `idea.md`: $ARGUMENTS

`/idea` is the **front door of the PRD-creation flow** (PM phase) — upstream of `/create-prd` and
the existing pipeline. It ingests one source, refines it through a grill, and writes a lean one-page
`idea.md` (per `${CLAUDE_PLUGIN_ROOT}/references/idea-format.md`) that seeds the Product Requirements Document. It is
**not** a PRD: no code change. Output lands in the PRD folder the key names, on the first write and never relocated.
It then **vendors what it read into that same folder** (Phase 4.5) so the record the specs repo keeps is
one whose links resolve for everybody, not only for the operator whose disk the sources came off.

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
choices: ["Re-enter the path (Recommended)", "Read the argument as a prompt — the literal text is the idea", "Cancel"]
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
choices: ["Re-enter the source", "Cancel"]
```
This is an environment/user halt — do NOT `emit-block`. On `OK`, carry forward `raw_context`,
`signals`, `images`, `candidate_title`, `candidate_slug`, `source_refs`, `provenance`, `tracked` (a
`prd` source only), all three wikilink lists — `wikilinks_followed`, `wikilinks_not_followed`,
`wikilinks_broken` — and `links_other`. `source_refs`/`provenance` feed the `sources:` frontmatter
entry in Phase 4, and `tracked` seeds `## Prior art`. **Every one of those lists is also Phase 4.5's
input**: `wikilinks_followed` and the read `images` are what gets copied, and the other three are what
gets reported instead. **Carry each entry whole, `target` included.** Every link array names the target
**as written** beside the path it resolved to; that pairing is the only map Phase 4.5 has from a link in
`idea.md` back to the copy it belongs to, and dropping it would force that phase to resolve links itself —
which it is forbidden to do.

**What the digest now carries, and what it is worth.** The reader follows wikilinks **two levels
deep** under one total-file cap and **reads** the images the source links, returning a
`description` of what each frame shows rather than a bare path. Both are **context**: they inform the
grill and the prose Phase 4 writes. Neither is grounded evidence — an image here is never a `[DG#n]`
finding, carries no index file, and gets no verifier pass (`${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md`
§6 governs *that*, and this route does not enter it). Treat a described frame the way you treat a
sentence in the source file: something the operator handed over, to be put back to them as a question,
never a fact about what ships.

**Every bound that bit is surfaced, never swallowed.** An `images` entry with `read: false` names its
`reason` (`cap`, `unreadable`, `not_an_image`), and `wikilinks_not_followed` names each in-scope link
the traversal did not reach and why (`cap`, `depth`). `links_other` names each link that resolved to a
file the reader neither follows nor renders — a PDF, an archive, any other binary — enumerated and never
opened. Carry all of them to the Final report — a truncated read the operator is not told about is
indistinguishable from a source that said less, and a link nothing copied and nothing reported is
indistinguishable from a link that was never there.

---

## Phase 2.5 — Grounding: documentation (optional)

Dispatch both grounding agents **in a single response** so they run in parallel. Each is independent; either being OFF never suppresses the other.

**Docs.** Run `resolve-docs-grounding idea` per `${CLAUDE_PLUGIN_ROOT}/references/docs-grounding.md`. When `docs_grounding: ON`, `dispatch-docs-grounder` with `feature_summary` = the `idea-reader` digest's problem/outcome, `themes` = its signals; pass `key` = the run's own key, which enables the git-grep backstop. When OFF, skip silently.

Carry both digests into Phase 3 with **grill-rank** consumption — challenges from the two compete together for the ≤10 question slots, they do not add slots. Carry `area_proposal` and the `prd` source's match into Phase 4.

---

## Phase 2.6 — Code grounding (optional)

Runs only when `--ground-code` was given; otherwise take the OFF branch at the end of this phase. Kept separate from Phase 2.5 because the repo gate needs a user answer (which cannot happen inside a parallel dispatch) and because the scan is two-round and therefore sequential.

**1. Resolve the repo set.** The token after `--ground-code` is its value **only** when it contains no whitespace and every comma-separated part matches a top-level directory basename under `${REPOS_PATH:-/workspace}`; otherwise the flag is bare and the token is idea text. Validate each resolved path is a directory; a repo that is not mounted is handled by the `Repo missing (after resolution)` rule in `${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` — never invented, never silently dropped. A repo the user drops is carried to Phase 5 by name, with the themes it would have grounded left unverified. With `--ground-code <repo>[,<repo>…]`, use exactly those repos and skip the derivation below. Bare, derive them:

- **Cheap discovery.** List the top-level directories under each `${REPOS_PATH:-/workspace}` entry (may be colon-separated) with `ls`. Optionally attach each directory's one-line identity — `timeout 5 git -C <dir> remote get-url origin 2>/dev/null` (slug) or its README's first heading. Do **not** deep-scan to guess relevance.
- **Propose** a candidate set from the `idea-reader` digest's themes.
- **Gate** — this list's answer varies every run, so it fires unconditionally:
  ```
  choices: ["Ground the proposed set (Recommended)", "Ground a different set (you'll be prompted)", "Ground nothing — continue without a code scan", "Cancel"]
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

**A described image is material for the grill, not an answer in it.** Where a Phase 2 `images` entry carries a `description`, use it the way you use the source's own prose — to sharpen a question (*"the mockup shows the toggle per project; is the setting per project or per account?"*) and to avoid asking about something the operator has already shown you. It never closes a gap on its own and it never adds a question slot, because a frame is what somebody drew, not what anything does. **Never write a described frame into `idea.md` as fact** unless the grill confirms it or the source's prose already says it. An image the reader did not read (`read: false`) contributes nothing at all — never reason from its filename or its path.

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
  choices: ["Refine the existing idea.md (Recommended)", "Create a new one (you'll be prompted for a slug)", "Cancel"]
  ```
  On *refine*, re-open it, resolve its open `[NEEDS CLARIFICATION]` items, and append the new source
  (`{provenance, ref}` built from Phase 2's `provenance` and `source_refs`) to `sources`.
- **`kind` and `key`:** write `kind: prd` and `key: <the key this run was invoked with>` into the
  frontmatter (`${CLAUDE_PLUGIN_ROOT}/references/idea-format.md`). This command creates the folder, so
  until `/create-prd` writes `prd.md` this file is the only artifact carrying the pair
  `${CLAUDE_PLUGIN_ROOT}/references/addressing.md` §4 resolves the folder's identity from — and §4's
  own invariant is that a folder is never keyless, not even between its creation and its first
  document.
- **`status`:** set frontmatter `status: refined` IFF zero `[NEEDS CLARIFICATION]` markers remain;
  otherwise `status: draft`.

---

## Phase 4.5 — Vendor the sources into the PRD folder

Runs after Phase 4 and before Phase 5, because the handoff stages what this phase writes.

**Why this phase exists.** `$SPECS_PATH` is the system of record, and Phase 4 has just written
`idea.md` there with links still pointing at wherever the operator's source happened to live. Left
alone, the record holds a provenance document nobody but that operator can follow. Cite
`${CLAUDE_PLUGIN_ROOT}/references/idea-format.md` and execute its **Vendored sources** rules inline —
that file owns the two destinations, the copy set, the collision rule and the rewriting rule, and
cites `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §6.2 for the index format and its
reconciliation contract. This phase restates none of them.

**It changes nothing the brief says.** `idea-reader` distilled every source into `raw_context` in
Phase 2 and the grill consumed it in Phase 3, so this phase never revisits what `idea.md` claims. It
repairs where `idea.md` points.

1. **Build the copy set from the Phase 2 digest, and from nothing else.** The source file (unless
   `provenance: prompt`), every `wikilinks_followed[]` entry, and every `images[]` entry with
   `read: true`. This phase opens no path of its own and reads no file the reader did not already
   read, so `idea-reader`'s caps — 12 files, 6 images — bound it without a second bound being
   written anywhere. Drop any entry that already sits inside the resolved PRD folder: it is vendored
   already, and its link stays as written.
2. **Copy each entry to its destination** — text and markdown to `<PRD-folder>/attachments/`, images
   to `<PRD-folder>/design/idea-sources/` — applying the collision rule. Byte-identical content at the
   destination is reused rather than re-copied; otherwise the name takes the lowest free `_NN`, derived
   from the destination directory and appended to the **original** basename, never to a name already
   carrying a suffix.
3. **Rebuild `design/idea-sources/index.md` per `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md`
   §6.2** — the one index format and reconciliation contract every writer of a frame-set index follows,
   executed inline and restated nowhere. Its six steps list the directory, preserve every existing row
   whose image is still there **verbatim**, append a row per frame this run accounts for, give a frame
   the run accounts for in no way the `_no description on record_` row, drop a row whose image is gone,
   and write the file whenever that listing is non-empty — reporting the last two. **What this run
   accounts for** is §6.2's writer table: the images step 2 copied, described from their digest
   `description`, transcribed verbatim and never invented. An image the collision rule *reused*
   (byte-identical content already at the destination) is not a new frame and gets no second row; the
   row already describing it stands. **The index is not optional**:
   `${CLAUDE_PLUGIN_ROOT}/references/grounding-format.md` §6.1 makes its absence unrecoverable, so images
   written without one would be a frame set nothing can ever read. **Writing it does not mean `/idea`
   design grounding has shipped** — nothing here dispatches `design-grounder`, produces a `[DG#n]`, or
   reaches a verifier, and that capability remains deliberately unbuilt (§6.1 says so; this phase keeps
   it true). A set left with rows the run could not describe is repaired by
   `/dev-workflows:frames <KEY>`, which reads the frames themselves and fills exactly those rows.
4. **Rewrite `idea.md`'s links onto the copies** — `[[wikilinks]]`, `![[embeds]]`, `[text](path)` and
   `![alt](path)`, absolute and relative alike — replacing the target, preserving the display text, and
   **writing every rewritten link as standard markdown**. `$SPECS_PATH` is a git repo read on a forge and
   in editors, not an Obsidian vault: nothing there resolves `[[name]]`, so a link repointed into the repo
   but left in wikilink syntax still resolves nowhere the record is actually read. `[[rollout]]` becomes
   `[rollout](attachments/rollout.md)`, `[[rollout|the plan]]` becomes `[the plan](attachments/rollout.md)`,
   `![[toggle-01.png]]` becomes `![toggle-01](design/idea-sources/toggle-01.png)` (alt from the **original**
   basename, never the collision-rule name), and `![[note]]` on a markdown file becomes the plain link
   `[note](attachments/note.md)` — a transclusion has no standard equivalent and renders nowhere here
   either way, so a link that resolves beats an embed that does not. **Rewrite only a link whose target
   this phase actually copied.** Every other link is left byte-for-byte as it stands, **syntax included**:
   a surviving `[[rollout]]` is the signal that the cap bit and the author may want to vendor that file by
   hand. The copies themselves are never edited.
   **Rewrite from the digest's own written-form → copy map, and re-resolve nothing.** Every link array
   carries the target **as written** beside the path it resolved to — `images[].target` with its
   `linked_from`, `wikilinks_followed[].target` with its `from` — and step 2 knows the name each copy took;
   pair them and match `idea.md`'s links on the target string. This phase opens no path of its own, so a
   target that is not a key of that map is a link nothing copied and is left alone. Where two entries share
   one written target but resolved to **different** files, that target is ambiguous — `idea.md` records
   nothing per occurrence to separate them — so **leave every occurrence as written and report it** rather
   than repoint one at the wrong copy. Targets that merely *look* alike but differ as strings
   (`settings/toggle-01.png` vs `onboarding/toggle-01.png`) are two keys and each is rewritten to its own
   copy.
5. **Record `vendored:`** beside each vendored entry's `ref:` in `sources:`. `ref` is not rewritten —
   it answers how the idea arrived, and that is still true of a path nobody else can resolve.
6. **Create nothing empty.** `attachments/` only where a file lands in it, `design/idea-sources/` and
   its index only where an image does. A bare-prompt run creates neither directory, writes no index,
   rewrites no link, and hands Phase 5 the deliverable set it would have handed it before this phase
   existed.
7. **Nothing here is fatal.** A copy that fails — permissions, a full disk, an unreadable source that
   was readable in Phase 2 — leaves that file unvendored, leaves its link exactly as written, and is
   reported beside the four sets below. A failed copy never blocks the handoff and never fails the run.
8. **Report what was not copied, in the Final report** — `wikilinks_not_followed[]` with each `cap`/
   `depth` reason, `wikilinks_broken[]`, every `images[]` entry with `read: false` and its reason, and
   every `links_other[]` entry with its extension. None of the four is copied, none of them has its
   link rewritten, and none of them is fatal. **Report three more things the steps above produce**: every
   ambiguous target step 4 declined to rewrite (with each source path and each copy), every frame step 3
   indexed as `_no description on record_`, and every index row step 3 dropped because its image is gone.

Hold the vendoring outcome — what landed in each destination, what was skipped and why, and any name
substituted by the collision rule — for the Final report, and carry the literal list of paths written
into Phase 5's `deliverable_paths`.

**The bookkeeping steps do not stage any of this.** `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`
§2.1 classifies `attachments/**` and `design/**` as OTHER, so `commit-artifacts` never touches them —
they are deliverables, and they reach the default branch only through Phase 5's handoff.

**What a run without a handoff therefore leaves behind, stated at its real size.** Not one file: `idea.md`
**and every path this phase wrote** — up to 12 copies in `attachments/` (the reader's total-file cap), up
to 6 in `design/idea-sources/` (its image cap) and that set's `index.md`, which is **19 beside `idea.md`,
so as many as 20 dirty OTHER paths**. Two routes reach that state, and only one of them is a decline:
Phase 5's `status: refined` branch offers the handoff and the operator may decline it, while its
`status: draft` branch **never offers one at all** — so a draft run leaves the whole set dirty by
construction rather than by a choice.

On the next run of any command sharing that repo, §3.3's **G1** matches. Its consequences are three, not
one: the preflight **ends** there, at advisory severity, listing the paths — no commit, no branch switch,
no push — and because §3.4's leftover flush and §3.5's branch disposition run only when stage 1 matched
nothing, **both are suppressed for the rest of that session**. G1 does **not** set `specs_git: blocked`,
so the terminal `commit-artifacts` still runs and nothing is lost or halted; the suppression repeats on
every later run until those paths are committed or the handoff is taken.

---

## Phase 5 — Handoff: adaptive next-phase offer

Report where `idea.md` was written and its `status`, and what Phase 4.5 vendored beside it, then offer
the next phase — **adapted to status**:

- **`status: refined`** — offer the handoff. Present
  `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §4.3's consent choice verbatim, then on the
  first option execute `handoff-to-main` (§2) with all five of its §2.9 inputs: `prefix: idea`;
  `feature_folder` = the folder Phase 0 resolved; `deliverable_paths` = `idea.md`, **plus every file
  Phase 4.5 wrote or reused** — each copy under `attachments/`, each image copy under
  `design/idea-sources/`, and that frame set's `index.md`. **Reused counts**: a copy the collision rule
  matched byte-for-byte was not written by this run, but `idea.md`'s link points at it and an earlier run
  may have left it on no ref — naming a path whose content is unchanged stages nothing, while omitting one
  is a link to a file that never lands; `title: <KEY> Add idea brief`; and `body_facts` = the idea's
  one-line goal, the number of `[NEEDS CLARIFICATION]` markers left open, the logged assumptions,
  whether docs grounding ran, and what was vendored.
  **All five are required** — §2.4's commit subject and §2.7's pull-request title are both derived
  from `title`, and §2.6 supplies every `gh` argument precisely so the run never blocks on an
  interactive editor; passing three of five leaves both unsourced.

  **The vendored files are named literally, one path each — never a directory and never a glob.**
  §2.3 stages by enumeration and classifies everything it was not handed as OTHER, so a copy left out
  of this list is a copy that never reaches the default branch: `idea.md` would land there pointing at
  `attachments/` paths that exist on the operator's disk and on no ref, which is a worse record than
  the one this feature set out to repair. Phase 4.5 hands over that literal list; pass it through
  unchanged. A bare-prompt run vendored nothing and passes `idea.md` alone, exactly as before this
  phase existed. Then recommend
  `/dev-workflows:create-prd <KEY> <merge-clause>`, which finds `idea.md` in that folder —
  `<merge-clause>` resolved from the `Phase handoff:` line §4.1 just emitted, per
  `${CLAUDE_PLUGIN_ROOT}/references/next-phase-offer.md`'s resolution table, and never written
  unconditionally. **The clause is load-bearing here, not decoration**: `/create-prd` Phase 0 step 3
  rung 1 runs `require-on-main` on exactly this `idea.md`, so while the pull request this offer just
  opened is still open that command stops on rows D/E — an unqualified recommendation sends the
  operator into a stop this run itself caused.

  **There is no key to wait for and no disposition to branch on.** The key was given in Phase 0, the
  folder was resolved from it, and `idea.md` was written there — so the three states this offer used
  to distinguish (rewrite in place, mint a new key, or neither) collapse into one.
- **`status: draft`** (N open `[NEEDS CLARIFICATION]`) — **never hand off**, and do not ask. By the
  governing principle the phase is not finished, so there is nothing to hand over. **Offer a next
  step even so**, because an offer left empty here is what makes a draft disappear: the file is
  written, on no branch, and the command that would read it does not. Two steps, in order:
  1. **Recommended — `/dev-workflows:idea <KEY> <the same source>`.** Re-running over the folder
     this run resolved takes Phase 4's *Refine the existing `idea.md`* path, re-opens this file, and
     puts the N open markers one at a time. Closing all of them sets `status: refined`, and the
     handoff offer above fires on that run instead. No merge clause: this run handed nothing off, so
     there is no pull request to wait for.
  2. **Only where the PRD is to be grilled from the draft as it stands —
     `/dev-workflows:create-prd <KEY> @<the absolute path of this idea.md>`.** The `@<path>` is
     required, and this is the one place the reason is visible. Nothing was handed off, so
     `/create-prd`'s in-contract rung 1 runs `require-on-main` against this file, finds it on no ref
     and returns row F `absent` — which is a fall-through rather than a stop, and no later rung of
     that ladder looks in the folder again. Named as a path, the file is read where it sits on
     rung 2's terms — never relocated, never gated, reported once as out-of-contract — and its open
     markers are folded into that command's own grill. `/dev-workflows:create-prd <KEY>` with no
     path resolves the same folder and grills the PRD from scratch, ignoring this file: that is the
     wait this offer names in place of a merge clause, and it is discharged by the path, not by a
     merge.

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
   > - Key events: [source-detection corrections, unresolved clarifications, broken wikilinks, links the traversal did not reach, images that were not read, links to files that are neither text/markdown nor an image, sources that failed to vendor — or 'none']
   > - Workarounds used: [manual steps not automated by the workflow — or 'none']
   > - Review verdict: N/A (no reviewer in /idea)
   > - Test result: N/A (no tests in /idea)
   > - Project root: [the idea.md folder]"
2. **Persist plugin feedback (automatic).** Cite
   `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` and call its `emit-auto` entry point (§6)
   with the Lessons Learned report, `command: /idea`, `key` = the run's own key, the run's `source`, and
   `plugin_version` (read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It renders only the
   plugin-facing slice (§4), dedupes by stable `id` (§3), resolves the target via the §2 specs-first
   ladder, and writes silently. Surface the persisted path (or "no plugin-facing signal — nothing
   persisted").
3. **Session cost (ALWAYS runs).** Cite `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and call its
   `emit-cost` entry point with `command: /idea`, `phase: prd-creation`, `role: pm`, `key` = the run's own key,
   the run's `source`, and `plugin_version`. The key is always present — `/idea` refuses to run without
   one — so the entry lands on the keyed tier and never on the pending ladder (§9), which
   **advances the chained checkpoint** (§3); surface the persisted path (or the report-only notice).
4. **Commit session artifacts (terminal).** Cite `${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md`
   and execute its `commit-artifacts` entry point (§4) inline — the LAST action of the run. It stages
   ONLY the §2.1 bounded artifact paths inside `$SPECS_PATH`, commits `<KEY> Add dev-workflows
   session artifacts (/idea)` — the key is mandatory here, so `NOISSUE` never applies — and pushes. It NEVER
   touches a code/docs repo, or the current working directory; NEVER force-pushes; NEVER
   fails the run; and skips entirely when the run carries `specs_git: blocked` (§3.3 G0), re-emitting
   that notice. Hold its §6 outcome line for the Final report.

ADDITIVE — this phase NEVER fails the run, NEVER commits the deliverable (idea.md itself is handed off separately, before this phase, via `${CLAUDE_PLUGIN_ROOT}/references/phase-handoff.md` §2, behind Phase 5's §4.3 consent choice; the terminal step above commits only the bounded session-artifact paths in `$SPECS_PATH`), and NEVER writes into a code/docs repo or the current working directory; no user name is ever written.

---

## Final report

Report: the `idea.md` path + `status` (refined / draft with N open clarifications); the source type and
`sources`; the count of `[NEEDS CLARIFICATION]` items and Assumptions; any source-detection correction
or broken wikilinks; **what the source read cost and what it left** — how many files the wikilink
traversal read (and at which depths), every `wikilinks_not_followed` entry with its `cap`/`depth`
reason, how many linked images were read, and every image left with `read: false` and why. Report
these even when nothing was excluded ("all N linked images read; no link left unfollowed"), because
the absence of a truncation notice is only informative once the run is known to print one; **what the
run vendored and what it did not** — the count of files copied into `attachments/` and of images copied
into `design/idea-sources/`, whether that frame set's `index.md` was written and how many rows it now
holds against how many this run added, every name the collision rule substituted, the number of links
rewritten in `idea.md` **and every target left unrewritten because two copied entries were written
identically** (with each source and each copy), every frame indexed with no description on record, every
index row dropped because its image is gone, and every source left uncopied with its
reason (`cap`, `depth`, broken, `unreadable`, `not_an_image`, a linked file that is neither
text/markdown nor an image with its extension, or a copy that failed) — stated plainly where nothing was
vendored at all ("no source to vendor: the idea came from a prompt", or "nothing linked"), and naming no
directory this run did not actually create; the resolved model routing (+ any Opus degradation); the feedback path; the cost
path (or notice); the `Specs repo:` outcome line from `commit-artifacts`
(`${CLAUDE_PLUGIN_ROOT}/references/specs-repo-git.md` §6), with any guard notice repeated in full; the
`Phase handoff:` outcome line when the handoff ran; the code grounding outcome — the grounded repos with their `scanned_ref`s, any
descoped or inconclusive ones, and — first, because it is the most consequential thing a run can
produce — the **Reframing** line if one was written; or, when no scan ran, `code grounding: off` (no
`--ground-code`) or `code grounding: declined at the repo gate` (`--ground-code` given, "Ground
nothing" chosen); and the adaptive next-phase recommendation.
