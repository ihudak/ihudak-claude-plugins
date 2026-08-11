# Printed-output correctness — sub-project D design

**Date:** 2026-08-11
**Sub-project:** D (final strand of the 2026-08-07 PM feedback round on `dev-workflows`)
**Ships as:** `dev-workflows` 2.46.0 (canonical + mgd), 2.16.0 (copilot)

## Goal

Every command name a run **prints** is one the user can actually invoke, and the routing graph contains every command that cites it as its authority.

## Background — what the feedback said, and what is actually true

Three strands were carried into D from the 2026-08-07 round. Two had premises that do not survive contact with the tree. Per the standing lesson that feedback entries are symptom reports rather than diagnoses, each was re-verified before design.

### (a) "Next-step suggestions collide with another plugin"

**Wrong cause, real symptom.** There is no colliding plugin: zero command-name overlaps across the four installed marketplaces (`claude-plugins-official`, `karpathy-skills`, `obsidian-skills`, `ihudak-plugins`), their skills, or user-level commands.

The real mechanism is **Claude Code's own built-in commands**, and the plugin already documents it for one case — `commands/statusline.md:17`:

> Claude Code ships its own built-in `/statusline` command (backed by the `statusline-setup` agent). Because this command shares that name, the bare `/statusline` resolves to Claude Code's built-in flow — direct users to the fully-qualified `/dev-workflows:statusline` to reach this command.

`/release-notes` and `/upgrade` are Claude Code built-ins too, so they collide identically. The convention and its justification already exist; they were simply never generalised. The README's mermaid diagram is the visible symptom: one node reads `/dev-workflows:statusline` while all fourteen siblings are bare.

### (b) "README + workflow diagram are missing `/update-vi` and `/idea --deep`"

**Both stated gaps are false; a worse one is real.**

- `--deep` is documented in six places: `README.md`, root `CLAUDE.md`, `commands/idea.md`, `references/grilling-technique.md`, `references/next-phase-offer.md`, and the CHANGELOG. Nothing to do. **Dropped from scope.**
- `/update-vi` is in the README command table, the README role table, the root `CLAUDE.md` command list, and the `CLAUDE.md` workflow map. Also nothing to do there.
- **What is actually broken:** `commands/update-vi.md:107` cites `references/next-phase-offer.md` as the authority for its Phase 6 offer, and that file mentions `/update-vi` **zero times** — in all three editions. A command points at a routing graph it does not appear in. Separately, all three README mermaid diagrams lack an `/update-vi` node (the PM subgraph runs `idea → create-vi → release-notes` only), while the role table directly beneath lists it.

This is the same defect shape as sub-project C's two Criticals: the rule is cited, the citation resolves to a real file, and the thing it promises is not in it.

### (c) mgd's root `CLAUDE.md`

**Verified real.** The `doc-structure-conventions.md` source-truth paragraph, added to canonical in `3f9acfb` (the 2.44.0 / B2 release), was never ported: canonical 1 occurrence, mgd 0, and `git log -S` shows it was never in mgd's history. It survived because the cross-repo parity check covers `plugins/dev-workflows` only, not the repository root.

## The rule

`references/next-phase-offer.md` already owns the offer contract (five rules) and is cited by every pipeline command. D adds **rule 6**, so the naming rule is stated once and applied by its citers — the same single-source-of-truth shape as `specs-repo-git.md`.

**Canonical / mgd wording:**

> 6. **Fully qualified when printed** — every command name the run PRINTS for the user to invoke is written `/dev-workflows:<command>`. A bare `/<command>` can resolve to a Claude Code built-in of the same name — `/release-notes`, `/upgrade`, and `/statusline` all collide today, and the built-in wins — so the bare form is NEVER printed. Prose that describes the pipeline to a reader of this plugin's source keeps the short form.

**Copilot wording** (no slash commands exist in that edition; the collision concept does not apply, but the same defect does — a printed slash-style reference invokes nothing):

> 6. **Printed in this edition's invocation idiom** — every skill name the run PRINTS for the user to invoke is written `<name>:` (e.g. `release-notes: <VI>`). Slash-style `/<name>` is a Claude Code idiom that invokes nothing here, so it is NEVER printed. Prose that describes the pipeline to a reader of this edition's source keeps the short form.

`commands/statusline.md`'s paragraph is retained but rewritten to cite rule 6 as the general rule rather than presenting itself as a one-off exception. No information is lost; the special case becomes an instance.

## The five printed surfaces

"User-facing" is not a decidable test, and sub-project C established that a hand-written file list loses sites and that the enumeration axis decides what is visible. So the rule names its surfaces, and each surface names its extraction method.

| # | Surface | Extraction | Decidable? |
|---|---------|-----------|-----------|
| i | `### Next step` sections | `awk '/^[[:space:]]*### Next step/{inb=1;next} /^[[:space:]]*#{1,3} [A-Z]/{if(inb)inb=0} inb'` | yes — hard gate |
| ii | `choices:` arrays | lines matching `choices:` | yes — hard gate |
| iii | quoted literals the command emits verbatim | candidate grep, then classify by reading | no — judgment, recorded |
| iv | "surface / report / recommend … `/cmd`" instructions | candidate grep, then classify by reading | no — judgment, recorded |
| v | the routing graph in `next-phase-offer.md` | whole `## The routing graph` section | yes — hard gate |

**Surface i's extraction must allow leading whitespace.** Several `### Next step` blocks are indented inside fenced report templates. An anchored `/^### Next step/` finds 11 sites in 5 files; allowing indentation finds **15 sites in 7 files**, adding `ready.md` and `release-notes.md` entirely. This is not a detail — it is the same line-anchoring hazard that produced four false counts in sub-project C, and the corrected form is the one that ships.

### The command-name regex

```
CMDS='implement|document|docs-profile|epics|release-notes|vuln|upgrade|idea|create-vi|update-vi|create-ard|specify|design|ready|feedback|prompt-brainstorm|prompt-grill-me|prompt|statusline|api-guideline-reviewer|guideline-reviewer'
BARE="(^|[^:a-z-])/($CMDS)\b"
```

Two properties matter and both were checked:

- `prompt-brainstorm` and `prompt-grill-me` precede `prompt` in the alternation, so the longer names win.
- The `[^:a-z-]` guard means the pattern **goes to zero as sites are fixed**: in `/dev-workflows:release-notes` the slash is followed by `dev-workflows`, not by `release-notes`, so a qualified name does not match. It also excludes file paths (`references/design-format.md`, `docs/design`), where the character before the slash is a letter.

### Candidate set for surfaces iii and iv

Not delimited by structure, so they are found by marker and confirmed by reading:

```
grep -nEi "(surface|report|offer|recommend|print|announce|emit|say|tell|direct users|end (the|with))[^.]{0,120}/($CMDS)\b" *.md
grep -nE '(\*"|"[^"]*)/('"$CMDS"')\b[^"]*"' *.md
```

Union at spec time: **60 lines across 15 files**. Each candidate is classified by reading as printed (qualify it) or prose (leave it). The classification is recorded per file in the implementation plan so a reviewer checks the judgment rather than re-deriving the set.

Worked examples of each:

- **iii** — `commands/idea.md:143`, a quoted literal the command emits: *"Idea refined. Next: create the VI — first create an empty Jira workitem, then run `/create-vi <JIRA-KEY> @<idea.md path>`."*
- **iv** — `commands/implement.md:111`: "Surface a **one-line, non-blocking** recommendation to run `/ready <VI> [<Epic>]` first when…"

Both are printed suggestions that sit nowhere near a `### Next step` heading. A sweep drawn only on the heading axis misses both.

### Observed counts at spec time

Re-derive these at implementation time rather than trusting them; they are recorded to size the work and to make drift visible, not as gates.

| Surface | Canonical sites | Files |
|---|---|---|
| i — `### Next step` | 15 | design 2, document 1, epics 2, implement 3, ready 2, release-notes 2, specify 3 |
| ii — `choices:` | 25 | create-ard 9, create-vi 5, document 3, implement 3, update-vi 3, design 1, specify 1 |
| iii + iv candidates | 60 lines / 15 files | document 9, implement 8, create-vi 7, create-ard 6, update-vi 4, ready 4, specify 3, idea 3, docs-profile 3, design 3, vuln 2, upgrade 2, statusline 2, release-notes 2, epics 2 |

For context, `commands/*.md` holds 369 bare occurrences in total; `references/` holds 425 and `agents/` 122. Those latter two trees are **out of scope** — they are prose read by the model, not printed to the user.

## Scope

### In scope

1. Rule 6 in `references/next-phase-offer.md` (all three editions, each in its own dialect).
2. The printed-surface sweep across surfaces i–v in `commands/` (canonical, mgd) and `skills/` (copilot).
3. `/update-vi` added to the routing graph in all three editions.
4. `/update-vi` node added to all three README mermaid diagrams.
5. `commands/statusline.md`'s paragraph rewritten to cite rule 6.
6. mgd root `CLAUDE.md` — the `doc-structure-conventions.md` paragraph, copied byte-identical from canonical.
7. copilot `skills/create-vi/SKILL.md:136` — cites `epics:` Phase **6.1**; the style check is Phase **6.2** in both editions (6.1 is *Resolve clarifications*). Canonical is already correct.
8. Version bump + CHANGELOG entry in all three editions; both `marketplace.json` catalogs.

### Explicitly out of scope

- `references/` and `agents/` prose (547 occurrences) — not printed to the user.
- README command tables, role tables, and root `CLAUDE.md` — prose; short forms stay.
- The copilot edition's remaining slash-style refs outside printed surfaces (~66 total occurrences, some of which are REST-path false positives in the API-guidelines references). This keeps all three editions' scope aligned, which is how parity is verified. The residue stays logged as the known pre-existing dialect bug.
- **Never shorten an already-qualified name.** The README diagram's existing `/dev-workflows:statusline` node stays exactly as it is. Re-bareing it would print a name that resolves to Claude Code's built-in — the very defect D exists to remove.

## `/update-vi` in the routing graph

Added to the **PM — ideation & framing** section as a re-entry node, not a linear one. It is reached when `/dev-workflows:create-vi` redirects an existing-VI call (README documents this redirect), or when a later phase forces a VI refresh. Its forward paths are exactly what `commands/update-vi.md` Phase 6 already prints — release note, ARD, spec:

```
- `/dev-workflows:update-vi <KEY>` — re-entry, not a linear node: reached when
  `/dev-workflows:create-vi` redirects an existing-VI call, or when a later phase forces a VI
  refresh. After the paste-into-Jira + re-import round-trip it offers the same forward paths as
  `/dev-workflows:create-vi`: `/dev-workflows:release-notes <VI>` (PM),
  `/dev-workflows:create-ard <VI>` (PA, if one exists), `/dev-workflows:specify <VI>` (PE, if one
  exists).
```

In the README mermaid, a dashed re-entry edge from `create-vi` to `update-vi`, with `update-vi` feeding the same PM downstream. Node labels in the diagram follow the diagram's existing convention (short form), per the out-of-scope rule above.

## Verification

No test framework — verification is grep, diff, and reading. Every count is whitespace-normalised where the source may hard-wrap (`tr '\n' ' '`), the hazard that produced four false counts in sub-project C.

| ID | Check | Expected |
|----|-------|----------|
| V1 | Rule 6 present in `next-phase-offer.md` | 1 per edition, correct dialect |
| V2 | Surface i — bare names inside `### Next step` (indent-tolerant awk) | 0 per edition |
| V3 | Surface ii — bare names on `choices:` lines | 0 per edition |
| V4 | Surface v — bare names in the routing-graph section | 0 per edition |
| V5 | Surfaces iii/iv — every candidate classified; accepted ones qualified | 0 unclassified; plan records each verdict |
| V6 | `/update-vi` in each routing graph | ≥1 per edition |
| V7 | `/update-vi` node in each README mermaid | ≥1 per edition |
| V8 | `statusline.md` cites rule 6; no orphan special-case wording | 1 citation |
| V9 | mgd root `CLAUDE.md` `doc-structure-conventions` paragraph | 1, byte-identical to canonical |
| V10 | copilot `create-vi/SKILL.md` cites `epics:` Phase 6.2 | 1; zero `6.1` in that context |
| V11 | Copilot printed surfaces carry zero slash-style refs | 0 |
| V12 | mgd parity — files differing from canonical under `plugins/dev-workflows` **plus repo root** | exactly the 6 identity files |
| V13 | CHANGELOGs monotonic; new entry in all three; both `marketplace.json` catalogs bumped | pass |

**Dialect note for V2–V4.** "Bare name" means the edition's *wrong* printed form. In canonical and mgd that is `/<command>` (unqualified); in copilot it is any slash-style `/<name>` at all, since that edition invokes skills as `<name>:`. The `BARE` regex above detects both cases — in copilot every match is a defect, in canonical/mgd only the unqualified ones are.

**V12 note.** mgd's identity set is **six** files, not five: `plugins/dev-workflows/.claude-plugin/plugin.json`, `LICENSE`, `README.md`, `references/dependencies.md`, plus root `CLAUDE.md` and `.claude-plugin/marketplace.json`. `references/dependencies.md` correctly says `mgd-plugins` where canonical says `ihudak-plugins` — it is not drift, and was mislabelled as such by three reviewers during sub-project C. A seventh differing file is the signal. This check must cover the repository root, since scoping it to `plugins/dev-workflows` is exactly what let (c) survive two releases.

## Risks

- **Over-qualification.** Rewriting prose that merely describes the pipeline makes dense text heavier without benefit. Mitigated by the surface list: only i–v are in scope, and iii/iv verdicts are recorded per file for review.
- **Under-qualification via the wrong axis.** The failure mode from C. Mitigated by naming five surfaces drawn on different axes (structure, quotation, instruction verb) rather than one, and by the indent-tolerant extraction for surface i.
- **Copilot divergence.** Fixing only printed surfaces leaves some files with mixed dialect. Accepted deliberately: aligned scope across editions is what makes parity checkable, and the residue is already logged.
