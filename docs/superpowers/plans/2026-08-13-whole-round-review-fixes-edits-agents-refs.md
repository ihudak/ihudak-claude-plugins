# Verbatim find-and-replace pairs — Group A (agent/reference caller lists) + Group B (R14, R42)

All paths relative to `/workspace/ihudak-claude-plugins/`. Branch: `iv-gu/whole-round-review-fixes`.
Every caller list below was RE-DERIVED from the tree on 2026-08-13 (derivation shown per item as
VERIFIED). Every OLD string was uniqueness-checked with `grep -Fc` (count = 1) before writing.
OLD/NEW blocks are exact and byte-for-byte, including hard-wraps — apply with exact-match replace.

---

### R13 — cost-emission.md caller roster omits `/update-vi`

FILE: plugins/dev-workflows/references/cost-emission.md
LINE: 4
OLD:
```
"Session cost" phase of every VI-lifecycle command (`/idea`, `/create-vi`, `/create-ard`, `/specify`, `/epics`,
```
NEW:
```
"Session cost" phase of every VI-lifecycle command (`/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/epics`,
```
ASSERT (raw shell, backticks are literal inside the single quotes):
    grep -Fc '`/create-vi`, `/update-vi`, `/create-ard`' plugins/dev-workflows/references/cost-emission.md   # expect 1 (currently 0)
VERIFIED: `grep -l 'emit-cost' commands/*.md` → 11 commands: create-ard, create-vi, design, document, epics, idea, implement, ready, release-notes, specify, **update-vi**. The roster at :4-5 names 10, omitting only `/update-vi`. `commands/update-vi.md:127` (Phase 7 step 3) really calls `emit-cost` with `command: /update-vi`. `/vuln` and `/upgrade` do NOT call `emit-cost` (confirmed absent from grep) — they stay off this roster correctly. This is the file's only caller-roster line (other `/release-notes` hits at :246, :251, :333, :343 are phase/role-table content, untouched).

---

### R19 — "twelve workflow commands" for `emit-auto` is thirteen (3 sites, 2 files)

VERIFIED (shared): `grep -l 'emit-auto' commands/*.md` → 13 commands: create-ard, create-vi, design, document, epics, idea, implement, ready, release-notes, specify, update-vi, upgrade, vuln. The lists name 12, omitting only `/update-vi` (`commands/update-vi.md:126`, Phase 7 step 2, calls `emit-auto` with `command: /update-vi`). `grep -c 'twelve'` today: feedback-emission.md = 2 (lines 4, 191), README.md = 1 (line 128) — exactly the three sites below, no others.

#### R19a
FILE: plugins/dev-workflows/references/feedback-emission.md
LINE: 4
OLD:
```
capture surface — the automatic maintenance phase of all twelve workflow
```
NEW:
```
capture surface — the automatic maintenance phase of all thirteen workflow
```

#### R19b
FILE: plugins/dev-workflows/references/feedback-emission.md
LINE: 191
OLD:
```
### `emit-auto` — automatic callers (the twelve commands' maintenance phases)
```
NEW:
```
### `emit-auto` — automatic callers (the thirteen commands' maintenance phases)
```

#### R19c
FILE: plugins/dev-workflows/README.md
LINE: 128-130
OLD:
```
- **Automatic.** The end-of-run maintenance phase of all twelve workflow commands
  (`/implement`, `/document`, `/epics`, `/vuln`, `/upgrade`, `/release-notes`,
  `/specify`, `/design`, `/idea`, `/create-vi`, `/create-ard`, `/ready`) projects the plugin-facing slice of the
```
NEW:
```
- **Automatic.** The end-of-run maintenance phase of all thirteen workflow commands
  (`/implement`, `/document`, `/epics`, `/vuln`, `/upgrade`, `/release-notes`,
  `/specify`, `/design`, `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/ready`) projects the plugin-facing slice of the
```

ASSERT (all of R19): `grep -o 'twelve' plugins/dev-workflows/references/feedback-emission.md plugins/dev-workflows/README.md | wc -l`   # expect 0 (currently 3)

---

### R20 — risk-planner.md:11 names `/vuln`, which never dispatches it

FILE: plugins/dev-workflows/agents/risk-planner.md
LINE: 11
OLD:
```
Invoked from the dev-workflows commands (`/implement`, `/vuln`, `/upgrade`) only when the classification step
```
NEW:
```
Invoked from the dev-workflows commands (`/implement`, `/upgrade`) only when the classification step
```
ASSERT (raw shell):
    grep -Fc '`/vuln`' plugins/dev-workflows/agents/risk-planner.md   # expect 0 (currently 1) — MUST use the backticked form: line 22's "upgrade/vuln work" contains the bare substring "/vuln" and stays.
VERIFIED: `grep -l 'dev-workflows:risk-planner' commands/*.md` → implement.md, upgrade.md ONLY (vuln.md: 0 hits for `risk-planner` at all).
NOTE for implementer (no pair produced — outside R20's decided fix): `agents/risk-planner.md:22` still says "For upgrade/vuln work, this includes the ..." — a residual bare-word mention in the Inputs prose, not a caller claim. Harmless but flag it upward if a broader sweep is wanted.

---

### R23 — vi-reviewer.md:12 caller note omits `/update-vi`

FILE: plugins/dev-workflows/agents/vi-reviewer.md
LINE: 12
OLD:
```
Invoked from `/create-vi` Phase 4 after authoring. A `BLOCK` verdict gates the handoff — the caller
```
NEW:
```
Invoked from `/create-vi` Phase 4 after authoring and `/update-vi` Phase 4 after updating. A `BLOCK` verdict gates the handoff — the caller
```
ASSERT (raw shell):
    grep -Fc '`/update-vi` Phase 4' plugins/dev-workflows/agents/vi-reviewer.md   # expect 1 (currently 0)
VERIFIED: `grep -l 'dev-workflows:vi-reviewer' commands/*.md` → create-vi.md, update-vi.md. The update-vi dispatch (`commands/update-vi.md:80`) sits under `## Phase 4 — Review gate` (update-vi.md:76), so "Phase 4" is correct for both callers.

---

### R24 — jira-reader.md:11 self-described caller list omits `/create-ard` and `/ready`

FILE: plugins/dev-workflows/agents/jira-reader.md
LINE: 11 (a single long unwrapped line; OLD/NEW below are a mid-line fragment)
OLD:
```
and `/specify` (Phase 2, `depth: vi-plus-epics then full`). The caller decides
```
NEW:
```
`/specify` (Phase 2, `depth: vi-plus-epics then full`), `/create-ard` (Phase 2, `depth: vi-only` VI-level / `full` Epic-level), and `/ready` (Phase 2, `depth: vi-plus-epics`). The caller decides
```
ASSERT (raw shell):
    grep -c 'Invoked from.*`/create-ard`.*`/ready`' plugins/dev-workflows/agents/jira-reader.md   # expect 1 (currently 0)
VERIFIED: `grep -l 'dev-workflows:jira-reader' commands/*.md` → 7 dispatchers: create-ard, document, epics, implement, ready, release-notes, specify. Line 11 names 3 (document, epics, specify); lines 15-18 already name `/implement` (Form 1) and `/release-notes` (Form 2), so ONLY `/create-ard` + `/ready` are missing from the file's self-description — matching the requirement, not the full 7. Depths re-derived from the dispatch sites: `commands/create-ard.md:67-72` (under `## Phase 2 — Read the VI` at :64; `depth: vi-only (VI-level) | full (Epic-level, scoped to focus_key)`) and `commands/ready.md:151-156` (under `## Phase 2 — Read ground truth` at :146; `depth: vi-plus-epics`).

---

### R26 — grilling-technique.md:27-28 depth caller lists under-count both modes

VERIFIED (shared): `grep -l 'grilling-technique' commands/*.md` → 7 commands: create-ard, create-vi, design, idea, prompt-grill-me, specify, update-vi. Bounded citers: `/idea` (grilling-technique.md:27 itself) + `/prompt-grill-me` (`commands/prompt-grill-me.md:70-71`: "Depth: **bounded** — a capped set (≤5) ... then stop"). Relentless citers: `/create-vi`, `/specify`, `/design` (already listed) + `/update-vi` (`commands/update-vi.md:58`: "Conduct a **relentless** interview per .../grilling-technique.md") + `/create-ard` (`commands/create-ard.md:112`: same phrasing). Current file mentions of `prompt-grill-me` / `update-vi` / `create-ard`: 0 / 0 / 0 — so exactly three entries are missing.

#### R26a — bounded list
FILE: plugins/dev-workflows/references/grilling-technique.md
LINE: 27
OLD:
```
Used by `/idea` (≤5; `--deep` switches to relentless).
```
NEW:
```
Used by `/idea` (≤5; `--deep` switches to relentless) and `/prompt-grill-me` (≤5).
```

#### R26b — relentless list
FILE: plugins/dev-workflows/references/grilling-technique.md
LINE: 28
OLD:
```
Used by `/create-vi`, `/specify`, `/design`.
```
NEW:
```
Used by `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`.
```

ASSERT (both of R26, raw shell):
    grep -Fc 'prompt-grill-me' plugins/dev-workflows/references/grilling-technique.md && grep -Fc '`/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`' plugins/dev-workflows/references/grilling-technique.md   # expect 1 and 1 (currently 0 and 0)

---

### R27 — jira-input-resolution.md:153 `resolve-export-for-key` consumer list omits `idea-reader`

FILE: plugins/dev-workflows/references/jira-input-resolution.md
LINE: 153-154
OLD:
```
never walks upward. Consumed by `/idea` (source typing) and `vault-prior-art-finder`
(status resolution) — neither wants a parent.
```
NEW:
```
never walks upward. Consumed by `/idea` (source typing), `idea-reader` (export
location for `rfe`/`vi` sources), and `vault-prior-art-finder` (status
resolution) — none of them wants a parent.
```
ASSERT (raw shell):
    grep -Fc 'idea-reader' plugins/dev-workflows/references/jira-input-resolution.md   # expect 1 (currently 0)
VERIFIED: `agents/idea-reader.md:36` ("Locate the export with `resolve-export-for-key <KEY>` (...jira-input-resolution.md) — **never** by assuming a top-level `jira-products/<KEY>/` directory") and `:85` ("always resolve through `resolve-export-for-key`") — a real, always-on consumer for `rfe`/`vi`-provenance sources. Note the closing clause changes "neither" → "none of them" because the list grows from two consumers to three.

---

### R28 — README.md:256 jira-reader "Used by" row lists 4 of 7 dispatchers

FILE: plugins/dev-workflows/README.md
LINE: 256 (end of the `jira-reader` agent-table row)
OLD:
```
Used by `/document`, `/epics`, `/release-notes`, and `/implement` (multi-source input). |
```
NEW:
```
Used by `/document`, `/epics`, `/release-notes`, `/implement` (multi-source input), `/create-ard`, `/specify`, and `/ready`. |
```
ASSERT (raw shell):
    grep -Fc '(multi-source input), `/create-ard`, `/specify`, and `/ready`' plugins/dev-workflows/README.md   # expect 1 (currently 0)
VERIFIED: same 7-dispatcher derivation as R24. Ordering matches CLAUDE.md:165's ledger line (`/document, /epics, /release-notes, /implement multi-source fan-out, /create-ard, /specify, /ready`), which the requirement holds up as the already-correct list.

### R14 — classification.md §8.5 gives `/idea` two opposite rules for `absent` + outside-deferral
FILE: plugins/dev-workflows/references/model-routing/classification.md
LINES: 378-388 (precedence paragraph); the contradicting altitude paragraph is 390-393
OLD:
A theme confirmed `absent`
— by round 2, or by round 1 when no anchor existed to seed one — is a
**resolved** finding only when that `absent` carries **no deferral to a repo
or layer outside the scanned set**: for `/idea`, it belongs in Section 7's
*What's missing*, not in Open questions. `[NEEDS CLARIFICATION]` (or the
caller's equivalent) is for a theme the scan could not settle — mutual
deferral, `error`, or `absent` everywhere scanned **plus** a deferral outside
the scanned set.
NEW:
A theme confirmed `absent`
— by round 2, or by round 1 when no anchor existed to seed one — is a
**resolved** finding, and the outside-deferral qualifier below is
caller-scoped. For **`/implement`** it is resolved only when that `absent`
carries **no deferral to a repo or layer outside the scanned set**, because
that caller's premise is that the capability lives somewhere across the repos
in scope. For **`/idea`** it is resolved unconditionally — the confirmed repo
set *is* the world the idea grounds against (see the altitude paragraph that
follows) — and it belongs in Section 7's *What's missing*, not in Open
questions. `[NEEDS CLARIFICATION]` (or the caller's equivalent) is for a theme
the scan could not settle — mutual deferral, `error`, or, **for `/implement`
only**, `absent` everywhere scanned **plus** a deferral outside the scanned
set.
ASSERT: awk 'NR>=376 && NR<=395' plugins/dev-workflows/references/model-routing/classification.md | grep -c 'caller-scoped'   # expect 1
ASSERT2: awk 'NR>=376 && NR<=395' plugins/dev-workflows/references/model-routing/classification.md | grep -c 'for `/implement` only'   # expect 1
VERIFIED: the two passages contradict for exactly one state — `/idea`, absent everywhere scanned, plus a deferral outside the scanned set. Precedence made it unresolved; altitude made it missing-but-resolved. `commands/idea.md` follows altitude, so the precedence sentence is the one narrowed. No behaviour change for `/implement`.

**Corrected 2026-08-13 (fix round 1):** ASSERT2 as written returns **0** on a faithful, verbatim application of the NEW text above, not 1 — it is unsatisfiable by construction. The NEW text's own hard-wrap point splits the phrase across two lines: "…mutual deferral, `error`, or, **for `/implement`" ends one line and "only**, `absent` everywhere scanned…" begins the next, so a line-scoped `grep -c` can never match the phrase `for \`/implement\` only` — confirmed against the live file at `:394`-`:395`. Wrap-aware corrected form: `awk 'NR>=376 && NR<=395' plugins/dev-workflows/references/model-routing/classification.md | tr '\n' ' ' | grep -oc 'for \`/implement\` only'   # expect 1` (verified to return 1 against the applied text).

### R42 — idea-format.md provenance enum never gained `doc-grounding`
FILE: plugins/dev-workflows/references/idea-format.md
LINE: 14
OLD:
  - provenance: rfe | vi | markdown | community-post | prompt
NEW:
  - provenance: rfe | vi | markdown | community-post | prompt | doc-grounding
ASSERT: grep -c 'provenance: rfe | vi | markdown | community-post | prompt | doc-grounding' plugins/dev-workflows/references/idea-format.md   # expect 1
VERIFIED: enum currently has 5 values at :14; `doc-grounding` is the value the 2026-07-20 feedback entry asked for and is the only part of that entry still open (axis6 PARTIAL).
