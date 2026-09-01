---
name: docs-profile
description: Scan a documentation repository and write/refresh a machine-readable docs-profile (.dev-workflows/docs-profile.yml) plus complementary CLAUDE.md guidance, as a reviewable PR. Captures content roots, per-space dev-servers and lint/build/format commands, templating tokens, links, announcement pages, branch-naming, images, and prerequisites; defers changelog/owners to the docs-frontmatter skill. Bootstraps or refreshes the profile that /document consumes.
allowed-tools: Read Edit Write Bash Glob Grep Task Skill
---

Profile the documentation repository: $ARGUMENTS

`$ARGUMENTS` is an optional repo path (default: the current working directory), optionally followed by `--inline`. The `--inline` token is passed when `/document` (keyed mode) invokes this flow inline (its Phase 0 case (c)); it switches this command to **inline mode** — see Phase 5 step 1, step 2, step 6, and Phase 6.

`/docs-profile` **bootstraps or refreshes** the machine-readable docs-profile that `/document` (keyed mode) consumes. It scans a documentation repository, synthesises a `.dev-workflows/docs-profile.yml` (and complementary CLAUDE.md guidance) that conforms to `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/docs-profile-schema.md`, then writes the result as a **reviewable PR** — branch + commit + a drafted PR message. It never pushes or auto-merges.

The command is **generic** — it works on any docs repo. A repo publishing one documentation set gets a single `spaces[]` entry; a repo publishing several gets one entry per content root, plus the per-space dev-server and lint/build/format commands that go with them.

It does **not** re-specify changelog or owners rules. Those are owned by the `docs-frontmatter` skill (+ `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/changelog-guidelines.md`, `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/default-owners.txt`); the profile's `frontmatter:` fields are **pointers only**.

For one-off doc edits use direct mode; for keyed feature documentation use `/document` (keyed mode).

---

## Phase 0 — Resolve and validate the target repo

1. **Resolve the repo path.** Take the first token of `$ARGUMENTS` as the target path; if `$ARGUMENTS` is empty, default to the current working directory. Resolve it to an absolute path and record it as `<repo>`. Treat a `--inline` token (in any position) as the inline-mode flag, not a path; record `inline = true` when present.

2. **Validate it is a writeable git work tree:**
   - `git -C <repo> rev-parse --is-inside-work-tree` must print `true`. If it errors or prints anything else, stop with the named error: `NOT_A_GIT_WORKTREE: <repo> is not inside a git work tree.`
   - `test -w <repo>` must succeed. If not, stop with the named error: `REPO_NOT_WRITEABLE: <repo> is not writeable.`
   - Resolve and record the repo's git root: `git -C <repo> rev-parse --show-toplevel`. All later detection and writes are relative to this root.

3. **Detect docs-repo signals** under the git root:
   - `package.json` with any doc script (matching `*:start`, `*:build`, `*:lint`, `docs:*`, `prettier`),
   - a `.docstack/` directory,
   - a `.vale.ini` file,
   - any `*/_content/` directory (e.g. `cloud/_content`, `self-hosted/_content`),
   - any `_snippets/` directory.

   If **≥ 1** signal is present → proceed silently to Phase 1.
   If **0** signals are present → ask before continuing:
   ```
   "No documentation-repo signals detected under <repo> (checked: package.json doc scripts, .docstack/, .vale.ini, */_content/, _snippets/). Profile it anyway?"
   choices: ["Proceed — I confirm this is a docs repo (Recommended)", "Cancel — point me at a docs repo first"]
   ```
   Default = Proceed. On Cancel, stop and report.

---

## Phase 1 — Model routing

Invoke the `model-routing` skill (Skill tool, `skill: "dev-workflows:model-routing"`) to load `${CLAUDE_PLUGIN_ROOT}/references/model-routing/classification.md`. Slash-command bodies cannot expand `${CLAUDE_PLUGIN_ROOT}` themselves, so the skill is what makes the policy text available.

Profiling is **SIGNIFICANT** — it is a cross-cutting synthesis of the whole repository whose output (`docs-profile.yml`) steers every later `/document` run, so a wrong profile has a large blast radius. State the classification and a one-line reason.

Record a `model_routing` block modeled on §4 (a profiling command does no implementation/fix edits, so those fields are N/A), resolving each model against the fallback chains:

```yaml
model_routing:
  classification: SIGNIFICANT
  reason: "cross-cutting synthesis of the whole docs repo; output steers all later /document runs"
  current_model: <the model this orchestrator is running under>
  detection_model: <§2.1 mid-tier Sonnet chain: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>
  planning_model: <§2 powerful chain: claude-opus-5 … fallback Sonnet 5/4.6/4.5>
  review_model: <same as planning_model — conceptually the synthesis_model; the synthesis step runs on the §2 Opus chain>
  opus_available: true | false
  notes: <any §2.1/§2 degradation, e.g. "Opus unavailable; synthesis fell back to claude-sonnet-5">
```

The detection phase (Phase 2) pins its subagent to `detection_model` (the §2.1 chain) via the `task` tool's `model:` override — never the session model. The synthesize phase (Phase 3) pins to `planning_model` (the §2 Opus chain). Announce any fallback now and again in Phase 6.

---

## Phase 2 — Detect (Sonnet-tier)

Dispatch a **read-only** detection subagent **pinned to the §2.1 mid-tier chain** via the `task` tool's `model:` override — `claude-sonnet-5`, fallback `claude-sonnet-4-6`/`claude-sonnet-4-5`; record the model actually used as `detection_model` in the `model_routing` block. Detection is mechanical repo scanning, so it must NOT inherit the session model (an Opus session would otherwise burn Opus on a cheap step, per §2.1).

→ Agent (subagent_type: "general-purpose", model: `<detection_model — §2.1: claude-sonnet-5, fallback claude-sonnet-4-6/4-5>`):
  > "Read-only detection scan for a docs-profile. Do NOT write or edit any file — return a structured detection report only.
  >
  > repo_root: <resolved git root from Phase 0>
  >
  > Gather and report, each with the file path + a short verbatim excerpt as evidence:
  >
  > 1. **package.json scripts** — every script whose name matches `*:start`, `*:lint`, `*:build`, `docs:*`, `format`/`prettier`. For each `*:start` script, extract the dev-server port and base path (grep the script and any referenced config — e.g. `--port`, `PORT=`, a `base`/`basePath` in a docusaurus/mkdocs/eleventy/vitepress config). Note whether two `*:start` servers can run concurrently (distinct ports → concurrent; shared port / single server → sequential).
  > 2. **Templating tokens** — grep the content roots for the repo's own inline markers, e.g. `{{tag kind='latest'}}` (a "latest version" marker) and `::app-settings::` (a settings breadcrumb). Report each marker's exact spelling and where it occurs.
  > 3. **Content + snippet roots** — every `*/_content` and every `*/_snippets` directory (e.g. `cloud/_content`, `cloud/_snippets`, `self-hosted/_content`, `self-hosted/_snippets`). This determines the `spaces[]` list: one rendered space per content root.
  > 4. **Branch-naming + internal-link conventions** — read CONTRIBUTING.md, CONTRIBUTION.md, README.md, DOCUMENTATION-GUIDELINES.md, and CLAUDE.md at the repo root (and `.claude/`). Quote any documented branch-naming pattern (e.g. `<initials>/<KEY>-<slug>`) and any internal-link convention (e.g. `[text](<postid>)` where postid comes from target frontmatter).
  > 5. **Image policy** — any documented rule for screenshots/images (CDN-hosted vs committed binaries); quote the source.
  > 6. **Prerequisites** — anything a dev server needs before `*:start` boots (e.g. a `.docstack` toolchain / shim, an axios version pin, an env var); quote the source.
  > 7. **Announcement pages** — hand-authored destination pages inside an otherwise automation-owned tree (e.g. a release-notes / what's-new tree). Detection signal: a page under such a tree whose frontmatter does NOT carry `meta.content-type: release-notes` (absent, or any other value) AND whose `git log` shows human PR commits rather than automation. For each match, record its `postid` (frontmatter `postid:`), its repo-relative `path`, and a proposed `kinds` list inferred from the page title and headings (e.g. an "End-of-life announcements" page → `[deprecation, end-of-life, shutdown, sunset]`). Report `announcement_pages: []` explicitly when none are found.
  >
  > Return one section per item above. For anything not found, say `not found` explicitly — do not guess. End with a one-paragraph summary: how many content roots the repo publishes, and whether each has its own dev server and lint/build scripts."

**Wait for the detection report.** If the agent returns nothing usable or fails, gather the same facts yourself via Glob/Grep/Read (read-only) before Phase 3 — but still record `detection_model` as the chain you attempted.

---

## Phase 3 — Synthesize the draft profile (Opus)

On the §2 powerful chain (`planning_model`), turn the detection report into a draft `docs-profile.yml`. This synthesis is the SIGNIFICANT reasoning step, so it runs on the strongest available reasoning model (Opus), pinned via the `task` tool's `model:` override — not the §2.1 detection chain.

→ Agent (subagent_type: "general-purpose", model: `<planning_model — §2 chain: claude-opus-5, fallback per §2>`):
  > "Synthesise a docs-profile from a detection report. This is a planning/synthesis task, not a code change — return the drafted YAML + drafted CLAUDE.md additions, nothing else; do not write files.
  >
  > Schema (the draft MUST conform exactly): `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/docs-profile-schema.md`
  > Detection report: [paste the full Phase 2 report]
  > model_routing: [paste the Phase 1 block]
  >
  > Rules:
  > - Emit `schema_version: 1` and one `spaces[]` entry per detected content root (`id`, `content_root`, `snippet_root`, `base_path`). `spaces[]` is required and non-empty.
  > - `dev_servers`: one `servers[]` entry per `*:start` script with its `command`, `port`, `base_path`; set `concurrent: false` unless detection proved two servers can run at once.
  > - `commands`: `lint`, `format`, and any commit-hook chain detected.
  > - `tokens`: only the markers detection actually found (e.g. `latest_tag`, `settings_breadcrumb`).
  > - `internal_links.convention`, `branch_naming.pattern`, `images.policy`, `prerequisites[]`: fill from detection; leave a field out rather than inventing it.
  > - `announcement_pages[]`: one entry per page found by detection item 7 (Announcement pages), each `{postid, path, kinds}`. Emit `announcement_pages: []` explicitly when detection found none — do not omit the key.
  > - `commands.per_space:` — when `package.json` (or the repo's task runner) exposes **per-space** lint / build / format scripts whose names correspond to entries in `spaces[]` (e.g. `docs:lint` + `self-hosted:lint` for spaces `cloud` + `self-hosted`), record them under `commands.per_space.<space id>`. Map the script name to the space id by the space's `content_root` (`cloud/_content` ⇒ script prefix `docs`), never by guessing. Omit `per_space` entirely when the repo has one content root, or when only whole-repo scripts exist.
  > - `frontmatter:` is **POINTERS ONLY** — set `owned_by_skill: docs-frontmatter`, `changelog_guidelines: references/docs-profiles/changelog-guidelines.md`, `default_owners: references/docs-profiles/default-owners.txt`. NEVER copy any changelog or owners rule text into the profile.
  > - Mark every field as `detected` (grounded in the report) or `needs-confirmation` (inferred / not found) so the orchestrator knows what to ask in Phase 4.
  > - Separately, draft minimal complementary **CLAUDE.md additions** ONLY for conventions not already covered by the docs-frontmatter skill or its reminder hook (e.g. dev-server sequencing, a repo-specific snippet or token convention). Do NOT restate changelog/owners — defer to the skill."

**Wait for the synthesis.** Hold the drafted `docs-profile.yml` and the drafted CLAUDE.md additions for Phase 4. If Opus was unavailable and the synthesis fell back to Sonnet, note it in `model_routing.notes` and carry it to Phase 6.

---

## Phase 4 — Confirm and fill gaps

**Rule: Ask, don't guess.** For every field the synthesis marked `needs-confirmation` — and anything detection could not settle — ask the user. Use `choices` arrays; 2–4 options, and never author an "Other" option — the harness supplies the free-text escape itself (`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` §0); the recommended default is first and labelled `"(Recommended)"`. Group related fields into one question where possible.

Typical gaps:

- **Exact build / start command** when a script was ambiguous:
  ```
  choices: ["Use detected `<cmd>` (Recommended)", "Enter the correct command", "Leave unset"]
  ```
- **Prerequisites** such as the `.docstack` shim (e.g. an axios>=1.16 pin) that must be in place before `*:start` boots:
  ```
  choices: ["Record detected prerequisite(s) (Recommended)", "Add a prerequisite I'll describe", "No prerequisites"]
  ```
- **Ambiguous space mapping** (a content root with no obvious `id` / `base_path`):
  ```
  choices: ["Accept proposed space mapping (Recommended)", "Edit a space's id/base_path", "Drop this space"]
  ```
- **Branch-naming convention** when none was documented (drives Phase 5):
  ```
  choices: ["Use repo convention if detected, else `<prefix>/NOISSUE-docs-profile` (Recommended)", "Enter a different pattern"]
  ```

**Idempotent refresh.** Before writing, check whether `<repo-root>/.dev-workflows/docs-profile.yml` already exists:
- **Exists** → show a **field-level diff** (existing value → new value, per key) and confirm:
  ```
  "A docs-profile already exists. Apply these field-level changes?"
  choices: ["Apply the diff — overwrite changed fields (Recommended)", "Keep existing, write nothing", "Edit specific fields first (you'll be prompted)"]
  ```
  Do not overwrite without this confirmation.
- **Absent** → bootstrap: proceed to Phase 5 with the confirmed draft.

Record the final, confirmed `docs-profile.yml` and CLAUDE.md additions, and tag each field `detected` vs `user-supplied` for the Phase 6 report.

---

## Phase 5 — Write as a reviewable PR

Produce a reviewable PR in the **target repo** (never the plugin). **Never push or auto-merge** unless the user explicitly asks.

1. **Resolve the branch name.** **Inline mode** (`--inline`): skip the prompt and the confirmation entirely — use the deterministic name `dev-workflows/docs-profile-bootstrap`; `/document` (keyed mode) Phase 6.2 renames it to the docs-branch convention. **Standalone** (default):
   - If the repo documents a branch-naming convention (detected in Phase 2 / confirmed in Phase 4), fill its placeholders and use it.
   - If the convention has an **identity** placeholder, fill it from the §2 ladder in `${CLAUDE_PLUGIN_ROOT}/references/branch-naming.md` (`$GIT_USER_INITIALS` → `git config user.initials` → inference from existing branches → the §2.5 prompt); its issue-key segment takes the documented no-issue literal, since profiling has no ticket.
   - Else (no convention documented, §1.4) use `<prefix>/NOISSUE-docs-profile`, where `<prefix>` comes from the same §2 ladder with fallback `docs/`. If the ladder yields nothing, run its §2.5 escalation:
     ```
     "I couldn't infer a branch prefix from $GIT_USER_INITIALS, `git config user.initials`, or existing branches. This command's default is `docs/`. What prefix should I use?"
     choices: ["Use `docs/` (default for this command)", "Use my initials — I'll enter them"]
     ```
   Always confirm the final name (initials/slugs are subjective):
   ```
   choices: ["Use proposed branch `<name>` (Recommended)", "Edit the name"]
   ```

2. **Prepare the working tree.** `git -C <repo-root> status --porcelain`; if non-empty:
   ```
   choices: ["Stash changes and continue (Recommended)", "Proceed anyway — pre-existing changes will appear in the diff", "Cancel"]
   ```
   Then base the branch on the repo's default branch so the profile PR is cut from a clean base: resolve the base (`git -C <repo-root> symbolic-ref --short refs/remotes/origin/HEAD`; fall back to `main`, then `master`) and run `git -C <repo-root> switch <base> && git -C <repo-root> pull --ff-only` (the clean-tree check above already ran; if the fast-forward pull fails, offer the same stash/proceed/cancel choices). Then create the branch: `git -C <repo-root> switch -c <name>` (or `git -C <repo-root> switch <name>` if it already exists).

3. **Write the profile.** Create `<repo-root>/.dev-workflows/` if absent, then write the confirmed `.dev-workflows/docs-profile.yml`. It MUST conform to `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/docs-profile-schema.md`. Apply the confirmed complementary CLAUDE.md additions to the repo's root `CLAUDE.md` (create the file if absent) — minimal, additive, scoped edits only; never restate changelog/owners rules owned by the docs-frontmatter skill.

4. **Format / lint.** If the repo has a formatter or linter (the `format`/`lint` commands captured in the profile), run it on the written files; fix anything it flags on those files. Skip silently if none is configured.

5. **Commit.** `git -C <repo-root> add .dev-workflows/docs-profile.yml CLAUDE.md` (only the files this command wrote), then commit:
   ```
   git -C <repo-root> commit -m "docs: add/refresh .dev-workflows/docs-profile.yml"
   ```

6. **Draft the PR message.** **Inline mode** (`--inline`): skip this step — control returns to `/document` (keyed mode), which owns the single PR draft (its Phase 8.5). **Standalone:** Detect the host (`git -C <repo-root> remote get-url origin`) and draft a copy-paste-ready PR title + body for Bitbucket or GitHub (whichever the remote indicates). Title e.g. `docs: bootstrap docs-profile for /document`; body summarising the profile (spaces, dev-servers, commands, tokens, branch-naming, images, prerequisites) and the CLAUDE.md additions. **Do not push, do not open the PR via any CLI** — present the branch name + the drafted message for the user to push and open themselves.

---

## Phase 6 — Final report

**Inline mode** (`--inline`): skip this report — control returns to `/document` (keyed mode), which produces the consolidated report (its Phase 9). The rest of this section is the standalone report.

Output a structured report — do NOT ask any closing confirmation:

```
## Docs-profile Report

### Classification
SIGNIFICANT — cross-cutting synthesis of the whole docs repo; output steers all later /document runs

### Target repo
<resolved git root>  (<N> content root(s))

### Profile written
<repo-root>/.dev-workflows/docs-profile.yml  (bootstrapped | refreshed)

### Fields: detected vs user-supplied
- detected: [spaces, dev_servers, commands, tokens, internal_links, announcement_pages, branch_naming, images, prerequisites — list those that were detected]
- user-supplied: [list the fields confirmed/filled in Phase 4]
- omitted: [e.g. "commands.per_space — the repo has only whole-repo scripts"]
- frontmatter: pointers only → docs-frontmatter skill (+ changelog-guidelines.md, default-owners.txt); changelog/owners NOT re-specified

### CLAUDE.md additions
- [what was added to the repo's CLAUDE.md, or "none — all conventions covered by the docs-frontmatter skill"]

### Branch
<branch name created>

### PR draft (copy-paste)
**Title:** <title>

<body>

### Model Routing
- Classification: SIGNIFICANT
- Detection model (§2.1): <detection_model>
- Synthesis model (§2): <planning_model>
- Opus available: <true | false>
- Notes: <any §2.1/§2 fallback that occurred, or "none">

### Git state
Branch <name> created with 1 commit on <repo-root>. NOT pushed and NOT merged — push and open the PR yourself when ready.

### Assumptions & limitations
- [list any]
```

---

## Invariants (always enforced)

- ALWAYS validate the target is a writeable git work tree (Phase 0); stop with a named error if not
- ALWAYS pin detection to the §2.1 mid-tier Sonnet chain via the `task` `model:` override — never inherit the session model — and record `detection_model`
- ALWAYS run the synthesis on the §2 powerful (Opus) chain via the `task` `model:` override
- ALWAYS conform the written profile to `${CLAUDE_PLUGIN_ROOT}/references/docs-profiles/docs-profile-schema.md`
- ALWAYS treat `frontmatter:` as pointers to the docs-frontmatter skill; NEVER copy changelog/owners rules into the profile
- ALWAYS show a field-level diff and confirm before overwriting an existing `.dev-workflows/docs-profile.yml` (idempotent refresh)
- ALWAYS write the profile to `.dev-workflows/docs-profile.yml` in the TARGET repo — never the plugin
- NEVER push or auto-merge — output a reviewable PR (branch + commit + drafted PR message) for the user to push
- ALWAYS use `choices` arrays for decision points; recommended default first and labelled "(Recommended)"; 2–4 options, and never author an "Other" option — the harness supplies the free-text escape itself (`${CLAUDE_PLUGIN_ROOT}/references/escalation-rules.md` §0)
- ALWAYS reference plugin paths with `${CLAUDE_PLUGIN_ROOT}`
- ALWAYS produce the Phase 6 report as the final output, noting any §2.1/§2 model fallback
