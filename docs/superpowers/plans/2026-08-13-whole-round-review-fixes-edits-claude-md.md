# EDITS — repo-root CLAUDE.md sweep (Group A) + R35 dispatcher count (Group B)

Derived 2026-08-13 on branch `iv-gu/whole-round-review-fixes`, tree clean at start.
All OLD strings verified byte-exact and unique (`grep -cF` = 1) in their file at derivation time.
All counts and caller lists re-derived from the tree, not copied from the requirements file.

Files touched:
- `/workspace/ihudak-claude-plugins/CLAUDE.md` (all Group A items)
- `/workspace/ihudak-claude-plugins/plugins/dev-workflows/skills/model-routing/SKILL.md` (R16 companion — count lives there too; no other group owns it)
- `/workspace/ihudak-claude-plugins/plugins/dev-workflows/references/ard-resolution.md` (R30 companion — the requirement says "both lists"; no other group owns it)
- `/workspace/mgd-claude-plugins/CLAUDE.md` (R35)
- `/workspace/ihudak-copilot-plugins/dev-workflows/README.md` (R35)

Location drift found: R30 (recorded CLAUDE.md:186 → actually :250), R32 (recorded :220 → actually :221).
Already-fixed or premise-wrong: none — every premise checked out against the tree.

---

### R5 (CLAUDE.md half) — direct-mode `/document` review gate that does not exist

Verified: `commands/document.md:1490` "Direct mode has no reviewer gate, so this prompt is the only place the gap surfaces"; `:1494` "direct mode has no reviewer gate, so this is where the repo's own rules surface"; `:1561` "Review verdict: N/A (no review gate in /document direct mode)". The only `doc-reviewer` dispatch in document.md is Jira-mode Phase 7 (`:920`). Direct mode's actual pipeline: Phase 3.5 mandatory `docs-style-checker` (`:1482-1484`), `VIOLATIONS_FOUND` → one safe-fix cycle via `doc-fixer` then one re-run (direct-mode section, "apply safe fixes via `doc-fixer` (one fix cycle), then re-run once"), Phase 4 `impl-maintenance` (Agent 4), terminal `commit-artifacts`.

Three edits (a = map edge, b = invariant bullets, c = consistency companion on the ledger line).

#### R5a — CLAUDE.md:138 (workflow-map edge)
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 138
OLD:
```
/document (direct)   → [doc-reviewer] → [doc-fixer] → impl-maintenance → commit-artifacts
```
NEW:
```
/document (direct)   → [docs-style-checker] → [doc-fixer] → impl-maintenance → commit-artifacts
```
ASSERT: `grep -cF '/document (direct)   → [docs-style-checker] → [doc-fixer]' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED: direct mode's dispatched agents are docs-style-checker (Phase 3.5, mandatory), doc-fixer (conditional, one cycle), impl-maintenance (Phase 4 Agent 4); no doc-reviewer dispatch anywhere in the direct-mode phase list.

#### R5b — CLAUDE.md:203-204 (direct-mode invariant bullets)
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 203-204
OLD:
```
- `doc-reviewer` performs comprehensive review: links, headings, wikilinks, style, completeness
- BLOCKER findings trigger a fix cycle via `doc-fixer` (max one fix + one re-review); CONCERNs are recorded and may be fixed inline
```
NEW:
```
- **No reviewer gate** — direct mode never dispatches `doc-reviewer` (`doc-reviewer` is Jira-mode-only); gaps surface through the mandatory `docs-style-checker` pass (Phase 3.5), the repo's own `repo_verification_gates` checklist, and the gate ledger
- Style violations (`VIOLATIONS_FOUND`) trigger one safe-fix cycle via `doc-fixer`, then one re-run
```
ASSERT: `grep -qF 'direct mode never dispatches `doc-reviewer`' /workspace/ihudak-claude-plugins/CLAUDE.md && ! grep -qF 'performs comprehensive review' /workspace/ihudak-claude-plugins/CLAUDE.md && echo OK`   # expect OK
VERIFIED: document.md:1490 (style-check prompt "the only place the gap surfaces"), :1494 (repo_verification_gates row "where the repo's own rules surface"), direct-mode fix rule "apply safe fixes via `doc-fixer` (one fix cycle), then re-run once".

#### R5c — CLAUDE.md:157 (doc-reviewer ledger line, consistency companion)
Not named in R5's recorded fix direction, but once R5a/R5b land, the bare "(used by /document)" next to R25's corrected "both modes" line would imply doc-reviewer also covers both modes. Optional but recommended; skipping it leaves no false claim, only an imprecise one.
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 157
OLD:
```
                      └── doc-reviewer       (used by /document)
```
NEW:
```
                      └── doc-reviewer       (used by /document Jira mode)
```
ASSERT: `grep -cF 'doc-reviewer       (used by /document Jira mode)' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED: doc-reviewer's only dispatch is document.md:920, Jira-mode Phase 7.

---

### R7 — CLAUDE.md:246 "the grill is bounded" is true of `/idea` only
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 246
OLD:
```
- The embedded grill is **bounded** (≤5 questions; `--deep` on `/idea` relaxes it); leftover gaps become capped `[NEEDS CLARIFICATION]` markers + logged assumptions
```
NEW:
```
- Only `/idea`'s embedded grill is **bounded** (≤5 questions; `--deep` switches it to relentless), with leftover gaps becoming capped `[NEEDS CLARIFICATION]` markers + logged assumptions; `/create-vi`, `/create-ard`, `/specify`, and `/design` (and `/update-vi`) grill **relentlessly** to convergence with no cap (`references/grilling-technique.md`)
```
ASSERT: `grep -cF 'grill **relentlessly** to convergence with no cap' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED: `references/grilling-technique.md` §Depth — "Bounded — … Used by `/idea` (≤5; `--deep` switches to relentless)" / "Relentless — keep walking the tree until convergence, no cap". Each of the five commands declares a **relentless** interview in its own body: create-vi.md:123, update-vi.md:57, create-ard.md:112, specify.md:352 (plus :12), design.md:238 (plus :12). Note grilling-technique.md's own relentless roster omits `/update-vi` and `/create-ard` — that is R26 (Group 2), not this edit; the command files themselves are the ground truth here.

---

### R16 — CLAUDE.md model-routing must-load roster omits `/update-vi`
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 102 (the wrapped roster sentence spans lines 100-102; the edit lands on line 102)
OLD:
```
`/create-ard`, `/specify`, `/design`, `/ready`) must load and follow this file at the
```
NEW:
```
`/update-vi`, `/create-ard`, `/specify`, `/design`, `/ready`) must load and follow this file at the
```
ASSERT: `grep -cF '`/update-vi`, `/create-ard`, `/specify`, `/design`, `/ready`) must load' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED: update-vi.md:44 is a real skill invocation — "Invoke the `model-routing` skill (Skill tool, `skill: \"dev-workflows:model-routing\"`)". CLAUDE.md's roster currently names 13 commands and the exempt list names 7, totalling 20 of the 21 commands; `/update-vi` is the missing 21st and belongs on the must-load side. CLAUDE.md itself contains no "13" numeral — the list is the only edit there.

#### R16-companion — skills/model-routing/SKILL.md:3 count ("13" → "14")
The recorded fix direction says to update this count "to match"; no other task group owns this file, so it is included here.
FILE: /workspace/ihudak-claude-plugins/plugins/dev-workflows/skills/model-routing/SKILL.md
LINE: 3
OLD:
```
the 13 pipeline commands (`/implement`, `/document`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/docs-profile`, `/idea`, `/create-vi`, `/create-ard`, `/specify`, `/design`, `/ready`)
```
NEW:
```
the 14 pipeline commands (`/implement`, `/document`, `/epics`, `/release-notes`, `/vuln`, `/upgrade`, `/docs-profile`, `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, `/ready`)
```
ASSERT: `grep -cF 'the 14 pipeline commands' /workspace/ihudak-claude-plugins/plugins/dev-workflows/skills/model-routing/SKILL.md`   # expect 1
VERIFIED: 13 commands currently listed in the SKILL.md description; adding `/update-vi` makes 14. Count re-derived by listing, not copied.

---

### R17 — CLAUDE.md:110 source-truth consumer list (3 named, 5 actual)
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 110
OLD:
```
It is consulted by `doc-planner`, `doc-reviewer`, and `release-notes-writer` to verify user-visible claims
```
NEW:
```
It is consulted by `doc-planner`, `doc-writer`, `doc-reviewer`, `release-notes-writer`, and `risk-planner` to verify user-visible claims
```
ASSERT: `grep -cF '`doc-planner`, `doc-writer`, `doc-reviewer`, `release-notes-writer`, and `risk-planner`' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED (re-derived): `grep -rl 'source-truth' plugins/dev-workflows/agents/` returns exactly 5 files — doc-planner.md, doc-writer.md, release-notes-writer.md, risk-planner.md, doc-reviewer.md. The set is exactly the current 3 plus doc-writer and risk-planner; no sixth consumer exists.

---

### R21 — CLAUDE.md:155 risk-planner ledger omits `/upgrade`
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 155
OLD:
```
                      └── risk-planner       (used by /implement plan critique)
```
NEW:
```
                      └── risk-planner       (used by /implement plan critique, /upgrade)
```
ASSERT: `grep -cF 'risk-planner       (used by /implement plan critique, /upgrade)' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED: upgrade.md:69 ("invoke `risk-planner` before execution") and :73 (`subagent_type: "dev-workflows:risk-planner"`) — a real dispatch for SIGNIFICANT/HIGH-RISK components. Also re-confirmed R20's premise as a cross-check: vuln.md has zero risk-planner references, so `/vuln` is correctly NOT added here.

---

### R22 — CLAUDE.md:158 doc-fixer ledger wrongly credits `/release-notes`
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 158
OLD:
```
                      └── doc-fixer          (used by /document, /epics, /release-notes)
```
NEW:
```
                      └── doc-fixer          (used by /document, /epics)
```
ASSERT: `grep -cF 'doc-fixer          (used by /document, /epics)' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED (re-derived): `grep -rl 'dev-workflows:doc-fixer' plugins/dev-workflows/commands/` returns exactly document.md and epics.md. release-notes.md:272 dispatches `dt-style-guide:dt-doc-fixer` (a different plugin's agent); CLAUDE.md's own `/release-notes` map edge at :142 already names `dt-doc-fixer` correctly.

---

### R25 — CLAUDE.md:162 docs-style-checker "Jira mode" qualifier is stale
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 162
OLD:
```
                      └── docs-style-checker (used by /document Jira mode)
```
NEW:
```
                      └── docs-style-checker (used by /document, both modes)
```
ASSERT: `grep -cF 'docs-style-checker (used by /document, both modes)' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED: direct mode dispatches it too — document.md:1482-1484 (Phase 3.5, `subagent_type: "dev-workflows:docs-style-checker"`), :1748 ("ALWAYS run Phase 3.5 (style check)"), and it is mandatory in both modes (:787 Jira, :1492 direct "Never skip this phase").

---

### R29 — CLAUDE.md:153 test-baseliner ledger omits direct `/upgrade`/`/vuln` invocations
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 153
OLD:
```
                      └── test-baseliner      (used by upgrade-executor, vuln-fixer, and /implement)
```
NEW:
```
                      └── test-baseliner      (used by /implement, and by /upgrade and /vuln both directly and via upgrade-executor / vuln-fixer)
```
ASSERT: `grep -cF 'both directly and via upgrade-executor / vuln-fixer' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED (re-derived): direct orchestrator invocations at upgrade.md:104 (`subagent_type: "dev-workflows:test-baseliner"`) and vuln.md:119 ("Capture baseline at the orchestrator using the existing `test-baseliner` agent"); agent-side users re-confirmed via `grep -rl test-baseliner plugins/dev-workflows/agents/` → vuln-fixer.md, upgrade-executor.md (plus test-baseliner itself and a test-writer cross-reference, which are not invocations). So the full user set is: /implement, /upgrade (direct + via upgrade-executor), /vuln (direct + via vuln-fixer).

---

### R30 — CLAUDE.md ARD-consumer sentence omits `/ready` (LOCATION DRIFT: recorded :186, actually :250)
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 250 (NOT :186 as recorded — the sentence lives in the VI-creation-flow invariants block)
OLD:
```
- `/design`, `/implement`, `/specify`, `/epics` respect the applicable ARD via `references/ard-resolution.md`
```
NEW:
```
- `/design`, `/implement`, `/specify`, `/epics`, `/ready` respect the applicable ARD via `references/ard-resolution.md`
```
ASSERT: `grep -cF '`/epics`, `/ready` respect the applicable ARD' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED: ready.md:176 ("Resolve any applicable ARD by citing `${CLAUDE_PLUGIN_ROOT}/references/ard-resolution.md`"), :181 (no-regression rule "per `ard-resolution.md`"), :183 (carries `invariants` forward as `applicable_ard`). Note the sentence's tail on line 250 ("an `AD-N` Rule violated without a recorded \"ARD deviation\" is a reviewer BLOCKER") stays as-is — it holds for `/ready` too (ready.md: an artifact violating an `AD-N` without a matching deviation line is a BLOCKER per the reviewer's ARD-conformance dimension).

#### R30-companion — references/ard-resolution.md consumers list omits `/ready`
The recorded fix direction says "Add `/ready` to both lists"; the reference-file half is not owned by any other task group, so it is included here.
FILE: /workspace/ihudak-claude-plugins/plugins/dev-workflows/references/ard-resolution.md
LINE: 62 (insert a new bullet AFTER this line; the `## Consumers (informative)` heading is at :57, bullets at :59-62)
OLD:
```
- `/epics` — VI-level only (`epic: null`, Epics do not exist yet); `AD-N` = inherited invariants the drafted Epics must respect; deviations → a `- ARD deviation: …` line in the Epic draft + the Phase 9 report.
```
NEW:
```
- `/epics` — VI-level only (`epic: null`, Epics do not exist yet); `AD-N` = inherited invariants the drafted Epics must respect; deviations → a `- ARD deviation: …` line in the Epic draft + the Phase 9 report.
- `/ready` — read-only verification; `AD-N` = the conformance bar the artifacts are checked against; never edits the ARD or authors a deviation record — it only checks whether one already exists (a violation without one is a BLOCKER in the readiness report).
```
ASSERT: `grep -cF '- `/ready` — read-only verification' /workspace/ihudak-claude-plugins/plugins/dev-workflows/references/ard-resolution.md`   # expect 1
VERIFIED: ready.md:174-186 (Phase 2.5 — resolves via ard-resolution.md; `status: none` → dimension inactive; `status: found` → `invariants` carried to the reviewer as `applicable_ard`; "/ready never edits the ARD and never authors a deviation record itself — it only checks whether one already exists"). The trailing sentence at ard-resolution.md:64-65 ("Each passes `invariants` to its reviewer as `applicable_ard`; … skipped entirely when it is absent") also holds for `/ready` (ready.md:231, :249, :583), so the new bullet does not falsify it.

---

### R31 — CLAUDE.md:214 branch-policy bullet is stale three ways
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 214
OLD:
```
- Branch policy: walk up cwd for `.obsidian/` → `obsidian` (never branch); else `git rev-parse` → `git_repo` (branch opt-in) or `plain_dir` (never branch). User override is allowed at plan approval
```
NEW:
```
- Branch policy: `/epics` never branches. `/document` classifies its write context against the resolved `docs_repo_path` (not necessarily cwd) — walk up for `.obsidian/` → `obsidian` (never branch); else `git rev-parse` plus docs signals → `docs_repo` (branch opt-in, confirmed at plan approval) or `non_docs_repo` (user confirmation promotes it to `docs_repo` behaviour); else `plain_dir` (never branch)
```
ASSERT: `grep -qF '`non_docs_repo` (user confirmation promotes it to `docs_repo` behaviour)' /workspace/ihudak-claude-plugins/CLAUDE.md && ! grep -qF 'git_repo`' /workspace/ihudak-claude-plugins/CLAUDE.md && echo OK`   # expect OK  (note: the negative grep uses 'git_repo`' with the closing backtick so it cannot false-match `non_docs_repo`/`docs_repo`; after the edit no bare `git_repo` token remains — re-derived: `grep -c git_repo commands/document.md` = 0)
VERIFIED all three staleness claims: (1) epics.md:13 "`/epics` **never branches**" and :98 "this command never branches" — not opt-in; (2) document.md's real context set is `obsidian | docs_repo | non_docs_repo | plain_dir` (document.md:101 classification, :170 preflight table, :223 display, :776-779 branch table); `git_repo` appears 0 times in document.md; (3) document.md:101 — "computed against the resolved `docs_repo_path` (not necessarily cwd)". The old bullet's "User override is allowed at plan approval" is subsumed by "branch opt-in, confirmed at plan approval" (document.md:777 "YES (opt-in confirmed at plan approval)").

---

### R32 — CLAUDE.md bug-report-draft enum `document-as-jira` doesn't exist (LOCATION DRIFT: recorded :220, actually :221)
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 221 (one below the recorded :220)
OLD:
```
- A bug-report draft (`<KEY>-implementation-gaps.md`) is written to the vault project folder for `document-as-jira` / `skip-and-report` decisions
```
NEW:
```
- A bug-report draft (`<KEY>-implementation-gaps.md`) is written to the vault project folder for `document-as-spec` / `skip-and-report` decisions, and for a `document-as-code` decision where the Jira phrasing asserts a specific value the source contradicts (`references/source-truth.md` §7.5)
```
ASSERT: `grep -qF 'document-as-spec' /workspace/ihudak-claude-plugins/CLAUDE.md && ! grep -qF 'document-as-jira' /workspace/ihudak-claude-plugins/CLAUDE.md && echo OK`   # expect OK
VERIFIED: source-truth.md §7.4 — the real enum is `document-as-spec` / `document-as-code` / `skip-and-report` ("The `decision` field is one of `document-as-spec`, `document-as-code`, or `skip-and-report`"); §7.5 trigger set — emit on ANY `document-as-spec` or `skip-and-report`, plus `document-as-code` "where the Jira phrasing asserts a specific value that contradicts the source" (vague/non-committal `document-as-code` entries are skipped). document.md:1189-1191 already uses exactly these three terms. `document-as-jira` appears nowhere in the tree except CLAUDE.md:221.

---

### R33 — CLAUDE.md:166 vi-reviewer ledger omits `/update-vi`
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 166
OLD:
```
                      └── vi-reviewer         (used by /create-vi)
```
NEW:
```
                      └── vi-reviewer         (used by /create-vi, /update-vi)
```
ASSERT: `grep -cF 'vi-reviewer         (used by /create-vi, /update-vi)' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED: update-vi.md:80 (`subagent_type: "dev-workflows:vi-reviewer"`) and create-vi.md:181 (same) — exactly two dispatchers. CLAUDE.md:147's own `/update-vi` map edge already shows `[vi-reviewer@Opus]`, so this ledger line was the lone stale surface. Counterpart R23 (agents/vi-reviewer.md:12) belongs to Group 2.

---

### R34 — CLAUDE.md:144 `/upgrade` map edge omits `[risk-planner@Opus]`
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 144
OLD:
```
upgrade-planner → upgrade-executor
```
NEW:
```
upgrade-planner → [risk-planner@Opus] → upgrade-executor
```
ASSERT: `grep -cF 'upgrade-planner → [risk-planner@Opus] → upgrade-executor' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED: upgrade.md:69 — step 6 "Risk plan for SIGNIFICANT / HIGH-RISK components — For every component classified `SIGNIFICANT` or `HIGH-RISK`, invoke `risk-planner` before execution" with the dispatch at :73; it sits between planning (upgrade-planner) and execution (upgrade-executor). Brackets match the map's convention for conditional steps (the step runs only for SIGNIFICANT/HIGH-RISK components). Counterpart R21 is above; both land in this same pass.

---

### R35 — "seven" → "eight" dispatcher count, all three editions

Count re-derived independently per edition (not copied from the requirement):
- **canonical:** `grep -rl 'Read-only mount — ref stale or diverged' plugins/dev-workflows/commands/` = exactly 8 files (create-ard, design, document, epics, idea, implement, release-notes, specify) — `/idea` (H) is the eighth.
- **mgd:** same grep over `/workspace/mgd-claude-plugins/plugins/dev-workflows/commands/` = 8 files.
- **copilot:** the raw grep over the edition returns 10 files, but three are NOT dispatching skills — `CHANGELOG.md`, `skills/_shared/read-only-repos.md` (the SSOT itself), and `skills/_shared/escalation-rules.md` (a reference doc). The dispatching skills are exactly 8: create-ard, design, document, epics, idea, implement, release-notes, specify SKILL.md files — the same set as canonical. "eight" is correct for all three.

#### R35a — canonical
FILE: /workspace/ihudak-claude-plugins/CLAUDE.md
LINE: 124 (matches the recorded location)
OLD:
```
and cited by the seven commands that dispatch them
```
NEW:
```
and cited by the eight commands that dispatch them
```
ASSERT: `grep -cF 'cited by the eight commands that dispatch them' /workspace/ihudak-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED: 8 command files cite the marker (list above). NOTE FOR IMPLEMENTERS: R3 (another task) edits a different clause of this same line 124 (the `prep`-contract tail). This OLD string is deliberately minimal so both edits apply independently in either order.

**Corrected 2026-08-13 (fix round 1):** the OLD anchor `and cited by the seven commands that dispatch them` no longer existed in the tree when Task 11 ran — R3 (which this note already flags as touching the same line) had already rewritten the sentence into two sentences: "Consumed by `code-scanner` and `diff-summarizer`, which emit the `prep` block; `docs-grounder` also consumes it (§1–§4 only — read-only detection, what to skip, ref resolution, reading at the ref) but returns a digest, not a `prep` block. Cited by the eight commands that dispatch them." — capital-C "Cited", a standalone sentence, not the lowercase mid-sentence "and cited" this OLD/NEW pair targets. The literal case-sensitive ASSERT above (`grep -cF` on lowercase `cited by…`) therefore returns **0** against the live file, not 1, even though "eight" (the substantive fix this row exists to land) is already correctly present — verified: `grep -icF 'cited by the eight commands that dispatch them' CLAUDE.md` → 1; the case-sensitive form → 0. No further edit to `CLAUDE.md` is needed — R3's rewrite already carries the correct count; only this row's anchor/ASSERT text was stale.

#### R35b — mgd
FILE: /workspace/mgd-claude-plugins/CLAUDE.md
LINE: 136 (matches the recorded location)
OLD:
```
and cited by the seven commands that dispatch them
```
NEW:
```
and cited by the eight commands that dispatch them
```
ASSERT: `grep -cF 'cited by the eight commands that dispatch them' /workspace/mgd-claude-plugins/CLAUDE.md`   # expect 1
VERIFIED: mgd's own commands/ tree has 8 files citing the marker (same grep, run against `/workspace/mgd-claude-plugins/plugins/dev-workflows/commands/`).

**Corrected 2026-08-13 (fix round 1):** same stale anchor as R35a. The OLD anchor `and cited by the seven commands that dispatch them` no longer existed in mgd's `CLAUDE.md` when Task 11 ran — mgd's own R3 porting had already rewritten the sentence into two sentences ending "…but returns a digest, not a `prep` block. Cited by the eight commands that dispatch them." (capital-C, standalone sentence). The literal case-sensitive ASSERT above returns **0** against the live file, not 1 — verified: `grep -icF 'cited by the eight commands that dispatch them' CLAUDE.md` → 1; the case-sensitive form → 0. "Eight" is already correctly present; no further edit to mgd's `CLAUDE.md` is needed, only this row's anchor/ASSERT text was stale.

#### R35c — copilot (dialect: "skills", not "commands")
FILE: /workspace/ihudak-copilot-plugins/dev-workflows/README.md
LINE: 369 (matches the recorded location)
OLD:
```
and cited by the seven skills that dispatch them
```
NEW:
```
and cited by the eight skills that dispatch them
```
ASSERT: `grep -cF 'cited by the eight skills that dispatch them' /workspace/ihudak-copilot-plugins/dev-workflows/README.md`   # expect 1
VERIFIED: 8 dispatching SKILL.md files in the copilot edition (raw grep hits 10; CHANGELOG.md + the two `skills/_shared/` reference docs excluded as non-dispatchers). The word stays "skills" per the copilot dialect.

---

## Sweep summary

- 14 requirement items → 19 find-and-replace pairs (R5 has 3 edits; R16 and R30 each carry a companion edit in a second file; R35 spans 3 files).
- Already-fixed: 0. Premise-wrong: 0. Every recorded premise re-verified true against the tree.
- Location drift: R30 (recorded CLAUDE.md:186 → :250) and R32 (recorded :220 → :221). All other recorded line numbers matched exactly.
- Post-sweep global check (run after ALL edits): `grep -cF 'document-as-jira' CLAUDE.md` → expect 0; `grep -cF 'seven commands that dispatch' CLAUDE.md` → expect 0.
- Porting note: every CLAUDE.md/SKILL.md/ard-resolution.md edit here is canonical and must be ported to mgd content-verbatim and hand-adapted for copilot per the standing dialect rules; R35b/R35c above ARE the mgd/copilot instances of R35 only.
