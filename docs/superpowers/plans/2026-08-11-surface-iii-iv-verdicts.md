# Surfaces iii/iv/vi — classification verdicts

Task 3 of the 2026-08-11 printed-output-correctness plan. One row per candidate from Step 1
(surfaces iii/iv — 60 candidates, derived pre-Task-1/2) and Step 1b (surface vi — 19 candidates,
D-3). 60 + 19 = 79 rows.

**Count-drift note (read before the table):** re-running Step 1's grep against the current tree
(after Tasks 1–2 landed) returns 48 live bare-form matches, not 60. The other 12 do not vanish —
they are candidates Task 2 already qualified (or, for `create-ard.md:60`/`:138`, deliberately kept
bare) because Task 2's `### Next step` / `choices:` surfaces overlap textually with this task's
marker grep. Each of those 12 gets a row below with verdict `HANDLED (Task 2)`, confirmed against
`git show 12c3c72` / `git show a31d6e8` and a byte-for-byte re-run of Step 1's grep against
`12c3c72~1` (the pre-Task-2 tree). 48 + 12 + 19 = 79. No candidate was invented or dropped to hit
the number — see the full reconciliation in `task-3-report.md`.

**A second, unrelated finding:** several LEAVE verdicts below are not judgment calls at all —
they're marker-grep false positives. The grep's `/($CMDS)\b` term matches `/feedback` inside the
literal path `${CLAUDE_PLUGIN_ROOT}/references/feedback-emission.md` (because `feedback` is itself
a command name), `/docs-profile` inside `.dev-workflows/docs-profile.yml`, `/statusline` inside
`statusline-command.sh`, and `/epics` inside the glob `*/epics/*`. None of these name a command at
all, let alone print an invocation — they're flagged `LEAVE (false positive)` below.

Surface legend: **iii** = quoted literal the command emits; **iv** = surface/report/recommend
… `/cmd` instruction; **iii/iv** = matched both marker greps; **vi-a** = role-handoff /
context-hygiene guidance; **vi-b** = annotated offer bullet expanding a `choices:` block.

| Site | Text (truncated) | Surface | Verdict | Reason |
|---|---|---|---|---|
| `create-ard.md:14` | `` `/create-ard <VI-KEY>` → a VI-level ARD. `` | vi-b | LEAVE | documents the command's own calling forms to a source reader, top of file |
| `create-ard.md:15` | `` `/create-ard <VI-KEY> <Epic-KEY>` → an Epic-level ARD… `` | vi-b | LEAVE | same as :14 — calling-forms documentation |
| `create-ard.md:60` | Tiered HARD model gate (like `/design`) | iii | HANDLED (Task 2) | deliberate bare exception (comparison clause); reverted in `a31d6e8` |
| `create-ard.md:138` | VI-level ARD… else offer `/dev-workflows:specify`… *(No `/design` — no Epics yet.)* | iii/iv | HANDLED (Task 2) | `/epics`/`/specify` qualified in `12c3c72`; the `(No /design…)` negation reverted bare in `a31d6e8` (deliberate exception) |
| `create-ard.md:139` | Epic-level ARD `choices: […]`. Epic fan-out: `/dev-workflows:create-ard <VI> <another-Epic>` | iii/iv | HANDLED (Task 2) | fully qualified in `12c3c72` |
| `create-ard.md:149` | Handing to PE (`/epics <VI>` / `/specify <VI> <Epic>`) or Team (`/design <VI> <Epic>`)? → run `/clear` | vi-a | QUALIFY | printed role-handoff offer; user really runs one of these next |
| `create-ard.md:160` | Capture-at-block invariant… `emit-block` (per `.../feedback-emission.md`)… | iv | LEAVE (false positive) | grep matched `/feedback` inside the reference-file path, not a command mention |
| `create-ard.md:170` | `emit-auto` entry point with `command: /create-ard`, the run's `jira_key`… | iv | LEAVE | data-field value passed to `emit-auto`, not printed as invocation |
| `create-ard.md:171` | `emit-cost` entry point with `command: /create-ard`, `phase: architecture`… | iv | LEAVE | data-field value passed to `emit-cost` |
| `create-vi.md:3` | frontmatter: "Offers /release-notes and /create-ard as next steps." | iv | LEAVE | descriptive prose in the plugin catalog description, not a printed offer during a run |
| `create-vi.md:52` | redirect: `choices: ["Switch to /dev-workflows:update-vi <KEY>…"]` | iii | HANDLED (Task 2) | qualified in `12c3c72` |
| `create-vi.md:56` | redirect: `choices: ["Update the existing <KEY> instead — /dev-workflows:update-vi <KEY>…"]` | iii | HANDLED (Task 2) | qualified in `12c3c72` |
| `create-vi.md:210` | `choices: [… /dev-workflows:release-notes … /dev-workflows:create-ard … /dev-workflows:epics …]` | iii/iv | HANDLED (Task 2) | qualified in `12c3c72` (surface ii `choices:` array) |
| `create-vi.md:213` | `` `/release-notes <KEY>` `` (PM) — draft the customer-facing release note now… | vi-b | QUALIFY | printed bullet expanding the `choices:` block directly above (line 210) |
| `create-vi.md:214` | `` `/create-ard <KEY>` `` (PA, optional) — hand to a Product Architect… | vi-b | QUALIFY | same pattern as :213 |
| `create-vi.md:215` | `` `/epics <KEY>` `` (PE) — hand to a PE… (or author a VI-level spec → `/specify <KEY>`) | vi-b | QUALIFY | annotated offer bullet; both `/epics` and the embedded `/specify` alternative are printed offers |
| `create-vi.md:226` | Continuing as PM (`/release-notes <VI>` after the round-trip)? → run `/compact` | vi-a | QUALIFY | brief's own worked ACCEPT example; leave `/compact` bare |
| `create-vi.md:227` | Handing to PA (`/create-ard <VI>`) or PE (`/epics <VI>`), even yourself? → run `/clear` | vi-a | QUALIFY | printed role-handoff offer; leave `/clear` bare |
| `create-vi.md:237` | Capture-at-block invariant… `emit-block` (per `.../feedback-emission.md`)… | iv | LEAVE (false positive) | same `/feedback`-in-path false positive as `create-ard.md:160` |
| `create-vi.md:248` | `emit-auto` entry point with `command: /create-vi`, the run's `jira_key`… | iv | LEAVE | data-field value, matches `idea.md:189` REJECT pattern |
| `create-vi.md:249` | `emit-cost` entry point with `command: /create-vi`, `phase: vi-creation`… | iv | LEAVE | data-field value, matches `idea.md:195` REJECT pattern |
| `design.md:150` | HARD gate: `choices: ["I'll relaunch /dev-workflows:design on Opus…"]` | iii | HANDLED (Task 2) | qualified in `12c3c72` |
| `design.md:337` | Capture-at-block invariant… `emit-block` (per `.../feedback-emission.md`)… | iv | LEAVE (false positive) | same `/feedback`-in-path false positive |
| `design.md:387` | Call `emit-cost` with `command: /design`, `phase: planning`, `role: dev`… | iv | LEAVE | data-field value |
| `design.md:440` | Continuing on this Epic (`/ready` / `/implement <VI> <Epic>`) or next Epic (`/design <VI> <Epic2>`)? → `/compact` | vi-a | QUALIFY | printed role-continuation offer naming three invocation targets; leave `/compact` bare |
| `docs-profile.md:58` | `reason: "…output steers all later /document runs"` | iii | LEAVE | descriptive consequence in a `model_routing.reason` field, not a printed offer to type |
| `docs-profile.md:191` | `git -C <repo-root> commit -m "docs: add/refresh .dev-workflows/docs-profile.yml"` | iii | LEAVE (false positive) | grep matched `/docs-profile` inside the `.yml` filename, not a command mention |
| `docs-profile.md:200` | Inline mode: control returns to `/document` (Jira mode), which produces the consolidated report… | iv | LEAVE | descriptive reference to how `--inline` control flow works, not a printed offer |
| `document.md:260` | HARD gate: `choices: ["Relaunch /dev-workflows:document under Opus…"]` | iii | HANDLED (Task 2) | qualified in `12c3c72` |
| `document.md:464` | `find "<specs_dir>" \( -path "*/epics/*" -o … \)` | iii | LEAVE (false positive) | grep matched `/epics` inside a directory-name glob, not a command mention |
| `document.md:654` | "…resolved exactly like the release-notes destination in `/release-notes`…" | iv | LEAVE | comparison between commands (how a destination is resolved), not an invocation |
| `document.md:1204` | Git state: "/document (Jira mode) writes but does not commit the docs write target…" | iii | LEAVE | self-description of the current command's own behavior, not an invocation target |
| `document.md:1258` | Call `emit-cost` with `command: /document (Jira mode)`, `phase: documenting`… | iv | LEAVE | data-field value |
| `document.md:1301` | ALWAYS `emit-block` (per `.../feedback-emission.md`) before escalating… | iv | LEAVE (false positive) | same `/feedback`-in-path false positive |
| `document.md:1407` | redirect: `choices: ["Re-run under /dev-workflows:document (Jira mode)…", "Re-run under /dev-workflows:epics…"]` | iii/iv | HANDLED (Task 2) | qualified in `12c3c72` |
| `document.md:1707` | Call `emit-cost` with `command: /document (direct mode)`, `phase: documenting`… | iv | LEAVE | data-field value |
| `document.md:1745` | ALWAYS `emit-block` (per `.../feedback-emission.md`) before escalating… | iv | LEAVE (false positive) | same `/feedback`-in-path false positive |
| `document.md:1213` | On to `/release-notes <VI>` (docs → PM handoff), even yourself? → run `/clear` | vi-a | QUALIFY | printed role-handoff offer; leave `/clear` bare |
| `epics.md:627` | Continuing as PE (`/specify <VI> <Epic>`)? → run `/compact` | vi-a | QUALIFY | printed role-continuation offer |
| `epics.md:628` | Handing to PA (`/create-ard <VI> <Epic>`), even yourself? → run `/clear` | vi-a | QUALIFY | printed role-handoff offer; leave `/clear` bare |
| `epics.md:669` | Call `emit-cost` with `command: /epics`, `phase: epic-refinement`, `role: pe`… | iv | LEAVE | data-field value |
| `epics.md:712` | ALWAYS `emit-block` (per `.../feedback-emission.md`)…; `/epics` is cwd-agnostic and rejects `mode: direct` | iv | LEAVE | false-positive `/feedback` match, plus a genuine but self-referential `/epics` invariant statement — neither is a printed invocation |
| `idea.md:151` | next-phase-offer contract; `/idea` is one reference implementation. | iv | LEAVE | brief's own worked REJECT example — prose describing the contract to a source reader |
| `idea.md:155` | Continuing to `/create-vi` (still the PM phase)? → run `/compact` | vi-a | QUALIFY | printed role-continuation offer; leave `/compact` bare |
| `idea.md:189` | `emit-auto` entry point (§6) with the report, `command: /idea`, `jira_key: null`… | iv | LEAVE | brief's own worked REJECT example — data-field value |
| `idea.md:195` | `emit-cost` entry point with `command: /idea`, `phase: vi-creation`, `role: pm`… | iv | LEAVE | brief's own worked REJECT example — data-field value |
| `implement.md:56` | VI with 0 Epics → offer: split with `/epics` first (then re-import)… | iv | QUALIFY | brief's own worked ACCEPT example |
| `implement.md:70` | `choices: ["Cancel — resolve the design's open questions in /dev-workflows:design first…"]` | iii | HANDLED (Task 2) | qualified in `12c3c72`; the brief's own named example of an already-fixed candidate |
| `implement.md:111` | Surface a one-line, non-blocking recommendation to run `/ready <VI> [<Epic>]` first… | iv | QUALIFY | brief's own worked ACCEPT example |
| `implement.md:387` | `choices: […"Phase 5 of the inherited /implement workflow"…]` | iii/iv | LEAVE (deliberate exception) | Task 2 exception — names the workflow the run is already inside, not something to type |
| `implement.md:445` | `choices: […"Phase 5 of the inherited /implement workflow"…]` | iii/iv | LEAVE (deliberate exception) | same as `:387` |
| `implement.md:634` | More Epics (`/implement <VI> <Epic2>`) or on to `/document <VI>` — same build lane? → `/compact` | vi-a | QUALIFY | printed role-continuation offer naming two invocation targets |
| `implement.md:680` | Call `emit-cost` with `command: /implement`, `phase: implementation`… | iv | LEAVE | brief's own worked REJECT example — data-field value |
| `implement.md:723` | ALWAYS `emit-block` (per `.../feedback-emission.md`) before escalating… | iv | LEAVE (false positive) | same `/feedback`-in-path false positive |
| `implement.md:746` | …escalate unresolved `missing`/`contradicts` as `- [ ]` notes on the spec/design — never silently | iv | LEAVE | "spec/design" is a compound noun (document-type shorthand), not an invocation of `/design` |
| `ready.md:52` | main branch is the handoff surface for every artifact `/ready` judges (per `/design`'s Phase 0 rule) | iv | LEAVE | self-referential description of `/ready`'s own scope, plus a citation of `/design`'s rule — neither is an invocation |
| `ready.md:356` | SUPPORTED → `/implement <VI> [<Epic>]` (still Team)? → run `/compact` | vi-a | QUALIFY | printed offer of the next command on a SUPPORTED verdict |
| `ready.md:452` | Pass Agent 4's Lessons Learned report, `command: /ready`, the run's `jira_key`… | iv | LEAVE | data-field value |
| `ready.md:514` | Call `emit-cost` with `command: /ready`, `phase: readiness`, `role: team`… | iv | LEAVE | data-field value |
| `ready.md:564` | ALWAYS `emit-block` (per `.../feedback-emission.md`) before escalating… | iv | LEAVE (false positive) | same `/feedback`-in-path false positive |
| `release-notes.md:295` | A PA/PE phase still pending (e.g. `/create-ard`, `/epics`), even yourself? → run `/clear` | vi-a | QUALIFY | printed role-handoff offer naming two example next commands |
| `release-notes.md:380` | Call `emit-cost` with `command: /release-notes`, `phase: inferred`, `role: inferred`… | iv | LEAVE | data-field value |
| `release-notes.md:424` | ALWAYS `emit-block` (per `.../feedback-emission.md`) before escalating… | iv | LEAVE (false positive) | same `/feedback`-in-path false positive |
| `specify.md:217` | `choices: ["Split into Epics first with /dev-workflows:epics…"]` | iii | HANDLED (Task 2) | qualified in `12c3c72` |
| `specify.md:444` | Capture-at-block invariant… `emit-block` (per `.../feedback-emission.md`)… | iv | LEAVE (false positive) | same `/feedback`-in-path false positive |
| `specify.md:451` | span suggestion (VI-level→`/epics` `/compact`; Epic-level→`/design` `/clear`) | vi-a | QUALIFY (judgment) | template describing what the printed Context-hygiene block (realized verbatim at `:543`/`:544`, both QUALIFY) will show — same shape as `next-phase-offer.md` rule 5's arrow-sequence examples, which Task 1 qualified on "every command name in it is either a printed template or an example of one." Applying that same standard for consistency: it names a real invocation target and would otherwise contradict its own realization two lines away |
| `specify.md:495` | Call `emit-cost` with `command: /specify`, `phase: specification`, `role: pe`… | iv | LEAVE | data-field value |
| `specify.md:543` | VI-level spec → `/epics <VI>` (still PE)? → run `/compact` | vi-a | QUALIFY | printed offer; the realization of `:451`'s template |
| `specify.md:544` | Epic-level spec → Team `/design <VI> <Epic>` (even yourself)? → run `/clear` | vi-a | QUALIFY | printed offer; the realization of `:451`'s template |
| `statusline.md:58` | `"command": "bash ~/.claude/dev-workflows/statusline-command.sh"` | iii | LEAVE (false positive) | grep matched `/statusline` inside the script filename, not a command mention |
| `statusline.md:63` | `jq '. + {statusLine: {…command:"bash ~/.claude/dev-workflows/statusline-command.sh"}}'` | iii | LEAVE (false positive) | same filename false positive as `:58` |
| `update-vi.md:109` | `choices: ["Re-draft the release note — /dev-workflows:release-notes <KEY>…"]` | iii | HANDLED (Task 2) | qualified in `12c3c72` |
| `update-vi.md:122` | Capture-at-block invariant… `emit-block` (per `.../feedback-emission.md`)… | iv | LEAVE (false positive) | same `/feedback`-in-path false positive |
| `update-vi.md:127` | `emit-auto` (§6) with the report, `command: /update-vi`, the run's `jira_key`… | iv | LEAVE | data-field value |
| `update-vi.md:128` | `emit-cost` with `command: /update-vi`, `phase: vi-update`, `role: pm`… | iv | LEAVE | data-field value |
| `upgrade.md:161` | `emit-auto` entry point (§6). Pass the Lessons Learned report, `command: /upgrade`… | iv | LEAVE | data-field value |
| `upgrade.md:219` | ALWAYS `emit-block` (per `.../feedback-emission.md`) before escalating… | iv | LEAVE (false positive) | same `/feedback`-in-path false positive |
| `vuln.md:183` | Pass the Lessons Learned report, `command: /vuln`, the run's `jira_key`… | iv | LEAVE | data-field value |
| `vuln.md:258` | ALWAYS `emit-block` (per `.../feedback-emission.md`) before escalating… | iv | LEAVE (false positive) | same `/feedback`-in-path false positive |

## Tally

- Total candidates: **79** (48 live Step 1 + 12 HANDLED-in-Task-2 Step 1 + 19 Step 1b) = 79 rows
- **QUALIFY** (fresh edits applied by this task): **19** — `create-ard.md:149`; `create-vi.md:213,214,215,226,227`; `design.md:440`; `document.md:1213`; `epics.md:627,628`; `idea.md:155`; `implement.md:56,111,634`; `ready.md:356`; `release-notes.md:295`; `specify.md:451,543,544`
- **LEAVE**: **48** — 44 plain LEAVE + 2 pre-existing Task 2 deliberate exceptions (`implement.md:387`, `:445`, not touched) + 2 Step 1b vi-b sites (`create-ard.md:14`, `:15`)
- **HANDLED (Task 2)**: **12** — already qualified (or, for `create-ard.md:60`/`:138`, deliberately kept bare) before this task ran; no edit made here

19 (QUALIFY) + 48 (LEAVE) + 12 (HANDLED) = 79.
