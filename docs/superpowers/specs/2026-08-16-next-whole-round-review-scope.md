# Scope for the next whole-round review (written 2026-08-16, pre-compaction)

**Not a review. A scoping record**, so the review can start without re-deriving its own boundary.

## The boundary, established from git rather than memory

The previous whole-round review (seven axes) was conducted on **2026-08-13**, covering sub-projects **A, B1, B2, C, D, E, F, G, H** and the in-between-sub-project fixes. Its findings became sub-project **I**.

| Date | Merge | In the last review? |
|---|---|---|
| 2026-08-12 | `iv-gu/idea-code-grounding` (sub-project **H**) | yes |
| 2026-08-12 | `iv-gu/implement-scan-honesty` | yes — landed before the review |
| **2026-08-13** | **← the whole-round review was conducted here** | — |
| 2026-08-13 | `iv-gu/whole-round-review-fixes` (sub-project **I**, 2.51.0) | **no** |
| 2026-08-13 | `iv-gu/clear-deferred-minors` | **no** |
| 2026-08-13 | `iv-gu/persist-j-decisions` (docs only) | **no** |
| 2026-08-16 | `iv-gu/phase-handoff-gates` (sub-project **J**, 2.52.0) | **no** |
| 2026-08-16 | `748817b` bugs-first pass (post-J leftovers) | **no** |

**Scope of the next review: sub-projects I and J, plus the three smaller merges above.** Canonical range `bcffb4c..748817b` (`git log --oneline bcffb4c..main`).

## Repo state at the time of writing

| Repo | main | Version | Pushed |
|---|---|---|---|
| `/workspace/ihudak-claude-plugins` (canonical) | `748817b` | 2.52.0 | yes |
| `/workspace/mgd-claude-plugins` | `93daebb` | 2.52.0 | yes |
| `/workspace/ihudak-copilot-plugins` | `3b80883` | 2.22.0 | yes |

mgd parity: exactly five identity files (`plugin.json`, `LICENSE`, `README.md`, `CHANGELOG.md`, `references/dependencies.md`).

## What J changed, in one paragraph

A workflow phase is not finished until its artifact is on the specs repo's default branch. A new reference `references/phase-handoff.md` owns `handoff-to-main` (§2, producer: branch, stage, commit, push, `gh pr create` behind a capability probe) and `require-on-main` (§3, a ten-state consumer gate). **Eight producers** — `/idea`, `/create-vi`, `/update-vi`, `/create-ard`, `/specify`, `/design`, `/implement`, `/ready`. **Seven consumers** — the same minus `/idea` and `/update-vi`, plus `/epics`. `/update-vi` is deliberately a producer but not a consumer. Branch authority grew to `^(idea|vi|ard|spec|design|ready)/`. `ard-resolution.md` gained `status: unmerged` with six callers. Breaking change: `/create-vi` no longer relocates `idea.md`; `/idea` does.

## Where the evidence lives (all committed)

`docs/superpowers/`:
- `specs/2026-08-14-phase-handoff-gates-design.md` — J's spec: 53 requirements, 13 decisions, 9 risks
- `plans/2026-08-14-phase-handoff-gates.md` + `-appendix-reference.md` — the 20-task plan
- `plans/2026-08-14-phase-handoff-gates-verification.md` — 53/53, with R4 and R7 recorded as failing first
- `plans/2026-08-14-cross-cutting-checks.md` — the sweeps no per-task review could perform
- `plans/2026-08-14-gate-reachability.md` — the ten-state trace, carrying **two** in-place corrections
- `plans/2026-08-14-residue-sweep.md` — ten rows with `fixed` / `checked and correct` verdicts
- `plans/2026-08-14-primitive-harness.md` — network-free git harness, 16/16

Sub-project I's equivalents sit under the same directory with `2026-08-13-` prefixes.

## Where to point the review's attention

These are the places this round's own process proved weakest — not a list of known defects, but where undetected ones are most likely.

1. **The three most serious defects all escaped per-task review.** A Critical-shaped ordering bug in `/implement` and one in `/design` were caught only by the cross-cutting sweep; row G's unreachability only by the verification record; `idea.md:335`'s false claim only by hand-transcribing for copilot. **Cross-command consistency is where defects survive**, because each command reads sensibly alone.
2. **Claims that expired rather than being born wrong.** Twice a statement was true when written and false several tasks later, with no step responsible for revisiting it (`specs-repo-git.md` §4.1's producer list; `ard-resolution.md`'s consumer count, which then propagated into three mirrors). Look for counts and lists that name commands.
3. **Verification that verifies nothing.** Ten distinct ways a check misreported this round — see the `checks-that-misreport` memory. Any surviving assertion in the committed artifacts deserves the question "could this pass while the risk materialises, and could it fail while nothing is wrong?"
4. **Static reading cannot settle tool behaviour.** The harness falsified a `git add -A` rationale that had stood across several sub-projects. Other reference files assert what a command returns; those assertions are testable and largely untested.
5. **Identity files.** mgd's and copilot's `README.md` are parallel catalogs of the `references/*.md` docs; the port skips them and `diff -rq` calls them expected-to-differ. Sub-project I had four findings here; J found five more stale entries in canonical's README alone.

## Known-open, deliberately

- **No live end-to-end handoff has ever been exercised.** Every producer/consumer check is a static read. `gh pr create --dry-run` accepted a nonexistent head branch, so it does not prove a real PR opens. The first genuine handoff is the remaining proof.
- **~100 per-VI feedback entries** under `$SPECS_PATH/specifications/*/dev-workflows/*-feedback.md` remain unprocessed — out of scope for every sub-project so far, and the obvious candidate for the next one.
