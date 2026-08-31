# Escalation rules (shared)

Canonical `choices:` arrays for escalation decision points. Every decision
point uses a `choices:` array whose **last** entry is `"Other… (describe)"` where
applicable. Command bodies are authoritative; where `/document` and `/epics`
differ for the same scenario, both variants are listed.

## Choice lists are presented verbatim

**A choice list written into a command phase is presented to the user verbatim. Its options, their
order, their wording, and the `(Recommended)` marker are not the orchestrator's to change. An
orchestrator that believes a different option is correct for this run says so in prose alongside the
list — it never edits the list.**

This rule binds every command in the plugin, not only the ones documented below. It exists because a
`/document` run presented Phase 6.5's `["Run smoke-check (Recommended)", "Skip — use the manual table
only", "Cancel"]` with the recommendation moved onto Skip, and the render gate was never exercised.

Adding the trailing `"Other… (describe)"` entry where a phase omits it is the one permitted
adjustment — **except on the arrays carved out by name below**, where the omission is part of the
list's meaning and adding the entry is a defect.

## The permitted adjustment does not reach these arrays

A picker whose options are drawn from a **closed vocabulary another authority fixes** has no room for
a free-text option: a fifth value is one nothing downstream can read, and the orchestrator that wrote
it has invented a state no consumer handles. Where a command says so in place, this file agrees with
it rather than authorising the opposite. **On the six arrays below, `"Other… (describe)"` is never
added:**

| Array | Its closed vocabulary | Owner |
|---|---|---|
| the candidate-confirmation picker | `confirm` / `correct` / `reject` / `ask-the-customer` | `commands/brd-reconcile.md`, *Confirm every candidate* |
| the missing-reason picker | ask the customer, or freeze `status: open` | `commands/brd-reconcile.md`, *Confirm every candidate* |
| the propagation-sweep picker | `inherited-unchanged` / `reverted` / `reopened` / `withdrawn` | `commands/brd-reconcile.md`, *The propagation sweep* |
| the will-change resolution picker | the exactly three resolutions of `references/decision-register-format.md` §6 | `commands/brd-interview.md` |
| the `[SR#n]` disposition picker | `fixed` / `accepted-risk` / `escalated-to-customer` / `rejected-with-reason` | `commands/brd-package.md` |
| the degradation-tier picker | `Full` / `Partial` / `Documents only` — the three rows of `references/bundle-packaging.md` §3 | `commands/brd-package.md` |

**The first three are load-bearing beyond tidiness, and the reason is worth carrying.** They are the
pickers through which a customer's authority enters the decision register, and D14 exists because
**normalising prose into a register row is inference, and promoting inference to customer authority
silently is the one way that workflow could fabricate a mandate the customer never gave.** A free-text
entry on a picker about what the customer decided is a box into which something that is neither their
decision nor a refusal of it can be typed and then frozen as theirs — the exact route D14 closes,
re-opened by an adjustment made in good faith against this file. A rule contradicted by its own
authority is not a rule, so the carve-out is written here, by name, rather than left to each command
to assert against a reference that overrules it.

`Cancel` is present on every one of the six, so no operator is ever trapped by the absence.

**This list is closed, and it is not a licence to prune elsewhere.** Every other array in the plugin
takes the trailing entry where its phase omits it, exactly as the paragraph above says.

## The `(Recommended)` marker is unconditional

**A `(Recommended)` marker applies whenever its list is shown.** A marker that carries its own
condition — `(Recommended for <case>)`, `(Recommended if <case>)` — is malformed: it hands the user
the gate the command was supposed to evaluate, and it cannot be honoured verbatim by an orchestrator
that must not edit the list. Write it one of two ways instead:

- the condition **gates the prompt** (the list is only shown in that case) → the marker is a plain
  `(Recommended)`; or
- the condition **lives in the option's own description** → the list carries no marker at all.

A **reason** annotation is not a condition and is fine: `(Recommended — <why>)` states why the option
is recommended, unconditionally, and is honoured verbatim like any other marker (`/document`
Phase 5 and `/epics` Phase 1 both use it).

**A marker the command resolves through a placeholder is not a violation of this rule, and it is not
an edit to the list.** Where which option is recommended varies per showing, the array may carry a
placeholder the command substitutes — `/brd-split`'s Phase 4 walk writes `<recommended>` on each of
its dispositions and resolves it, per row, to `(Recommended — <why>)` on one and to the empty string
on the rest. That is substitution, exactly as `<BRD-KEY>` and `<merge-clause>` are substituted in
the same strings (`references/next-phase-offer.md`), and it is the mechanism this section's first
bullet asks for: the **command** evaluates the condition and prints a bare, reasoned marker, rather
than printing the condition for the user to evaluate. What stays forbidden is the orchestrator
deciding a marker belongs somewhere the command did not put a placeholder.

When no option is safe to recommend across the runs that reach a prompt, omit the marker and say so
in prose beside the list (as `/document` Phase 5.6 does for its per-occurrence image review).

This rule binds every command in the plugin, not only the ones documented below.

## When a choice list fires

**A choice list blocks whenever it is shown.** Presenting one and continuing without an answer is never
correct — the list *is* the wait.

**A list is shown only when its firing condition holds.** A list with no written condition is shown
every time its phase runs. That is the default, and it is the right default for most phases.

**A list written for a question whose answer is already determined is a defect**, not a formality — it
spends a user turn on a prompt with one plausible answer. Where the answer is determined on some runs
and open on others, write the firing condition and keep the list for the runs where it is open.

**The inline-confirmation form.** When the answer is determined, state the resolution in one line that
names what was resolved and how to correct it, then proceed without waiting:

```
Reading this as a <type> — say so if it's actually a <other-type>.
```

An inline confirmation is **not** a choice list: it carries no `choices:` array, it never waits, and the
run continues on the stated resolution. It is the correct form wherever a phase would otherwise ask a
question with one plausible answer.

This rule governs only *whether* a list is presented. Option wording, option order, and the
`(Recommended)` marker are governed by the two rules above and are untouched by it.

This rule binds every command in the plugin, not only the ones documented below.

## key dir not found

`choices: ["Re-enter key", "Cancel"]`

Used when the folder read returns `status: NOT_FOUND` or `status: EMPTY`, or when
Phase 0 of the folder read rejects an invalid `key` format.

## Required path environment variable unset

`choices: ["Set <VAR> (enter the path)", "Cancel"]`

Used when a command stops in Phase 0 because a path environment variable it requires is unset, or
resolves to nothing that exists. `<VAR>` is that variable's own name, written out — the list names
the variable the run is missing, never a generic placeholder.

`/brd-intake` (Phase 0 step 5), `/brd-ground` (Phase 0 step 3 for `SPECS_PATH` and Phase 0 step 7
for `REPOS_PATH`), `/brd-split` (Phase 0 step 2), `/brd-interview` (Phase 0 step 3),
`/brd-package` (Phase 0 step 3) and `/brd-reconcile` (Phase 0 step 3) cite this rule by name — for
the last three, `SPECS_PATH` is the only path variable they need, since none of them opens a
repository. It is a stop, not a
degradation: there is no "continue without it" option, because the path is where the run's inputs
and outputs live. Other commands reproduce the same two-option list inline without naming the
rule; a citer that names the rule uses the list written here.

## Repo unresolved (zero matches) — /document

`choices: ["Skip and continue without its PRs", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo"]`

Used in `/document` Phase 4 when a repo slug has zero matches in the
slug→clone map.

## Repo unresolved (zero matches) — /epics

`choices: ["Skip and continue without this repo's scan", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]`

Used in `/epics` Phase 4 when a repo slug has zero matches in the
slug→clone map.

## Repo unresolved (zero matches) — /brd-ground

`choices: ["Skip and continue without this repo", "I'll clone it — wait", "Cancel", "Specify a different absolute path for this repo", "Other… (describe)"]`

Used in `/brd-ground` Phase 1 step 3 when a repo the operator named has zero matches in the
slug→clone map. Same options, same order as the `/epics` variant above; the first one drops
"'s scan" because this command grounds a claim against a repository rather than scanning one for
capabilities, and skipping it leaves that repository's claims ungrounded rather than unscanned.

## No repos derivable — /epics

`choices: ["List repos to scan manually", "Proceed without code scan", "Cancel", "Other… (describe)"]`

Used in `/idea` Phase 2.6 when the proposed theme → repo mapping is empty (no
theme matches any mounted repo), and in `/epics` Phase 4 when the final
resolved repo list is empty (every repo was skipped or missing — "Use case B
with no repos derivable"). The `— /epics` suffix on this heading is historical
— `/epics` was its first citer — not a scope restriction; the rule now serves
both commands listed above, and any future citer with the same empty-repo-set
shape uses it too.

In `/brd-ground` Phase 1 step 4 the *Proceed without code scan* entry is omitted:
`choices: ["List repos to check manually", "Cancel", "Other… (describe)"]`

and *scan* reads *check*, for the reason the `— /brd-ground` heading above gives. The dropped
option is not a shortening: grounding has nothing to check a claim against without at least one
mounted repository, which is why that command already refuses to start with none
(`commands/brd-ground.md` Phase 0 step 7) — an option offering to proceed anyway would name an
outcome the command cannot deliver.

## Repo missing (after resolution)

`choices: ["Skip this repo", "I'll clone it — wait", "Specify a different absolute path for this repo", "Cancel", "Other… (describe)"]`

Used when a diff-summarizer or code-scanner batch returns `REPO_MISSING` at
Phase 5 after Phase 4 already checked, in `/idea` Phase 2.6, which has no
earlier check, and in `/implement` Phase 1.7. `REPO_MISSING` means `repo_path`
is not a directory **or** the clone's `origin` slug does not match
`repo_url_slug`; *Specify a different absolute path for this repo* is the
option that resolves the second case, which the previous list had no answer
for at all. Present this choice per affected repo. No `(Recommended)` marker —
which option is right depends entirely on why the repo is absent.

## Dirty working tree

`choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel", "Other… (describe)"]`

Used in `/document` Phase 5 when a diff-summarizer returns `DIRTY_TREE`. `/create-ard`, `/design`,
`/release-notes`, and `/implement` (Phase 1.7) cite this rule by name without reproducing the list, so
per the "Choice lists are presented verbatim" convention above they use this variant — the one written
under this heading.

In `/epics` Phase 5 the `"Other… (describe)"` entry is omitted:
`choices: ["Stash changes and retry this repo", "Skip this repo", "Cancel"]`

`/specify` (Phase 4) reproduces this shorter `/epics` variant inline as well. A new citer that reproduces
a list inline states which variant it uses; a citer that names the rule without reproducing the list
uses the `/document` variant above — the file's own rule (adding the trailing `"Other… (describe)"`
entry is the one permitted adjustment) already resolves which list that citer is following.

## Branch prefix undetected

`choices: ["Use `<fallback>` (default for this command)", "Use my initials — I'll enter them", "Other… (describe)"]`

Used by every branch-creating command (`/implement`, `/document`, `/docs-profile`, `/upgrade`, `/vuln`) when the `branch-naming.md` §2 identity ladder — `$GIT_USER_INITIALS`, `git config user.initials`, then inference from existing branches — yields nothing. `<fallback>` is that command's own default (`feat/`, `docs/`, `fix/`, `chore/`).

**Identity variant.** When the value is filling an **identity** placeholder in a convention documented by the repo itself (`<your-name-or-initials>`, `<user>`, …), the fallback choice is omitted — a generic prefix is not a name, and the documented convention requires a real identity:

`"This repo's documented convention starts the branch with your name or initials, and I couldn't infer one. What should I use?"`
`choices: ["Enter my initials", "Cancel", "Other… (describe)"]`

Either way, prompt for the value with: `"Enter your initials (lowercase; 2–8 characters from [a-z0-9-], starting with a letter or digit, e.g. `iv-gu` or `ivgu`):"` — then suggest, without persisting, `GIT_USER_INITIALS` or `git config --global user.initials`.

## Refresh blocked

`choices: ["Continue with current local state", "Skip this repo", "Cancel", "Other… (describe)"]`

Used in `/document` Phase 5 when a diff-summarizer returns `REFRESH_BLOCKED`. `/create-ard`, `/design`,
`/release-notes`, and `/implement` (Phase 1.7) cite this rule by name without
reproducing the list, so per the "Choice lists are presented verbatim" convention above they use this
variant — the one written under this heading.

In `/epics` Phase 5 the `"Other… (describe)"` entry is omitted:
`choices: ["Continue with current local state", "Skip this repo", "Cancel"]`

`/specify` (Phase 4) reproduces this shorter `/epics` variant inline as well. A new citer that reproduces
a list inline states which variant it uses; a citer that names the rule without reproducing the list
uses the `/document` variant above — the file's own rule (adding the trailing `"Other… (describe)"`
entry is the one permitted adjustment) already resolves which list that citer is following.

## Read-only mount — ref stale or diverged

`choices: ["Scan released code at `<ref>` (Recommended — cites shipped behavior)", "Cancel — refresh on the host (`git -C <path> fetch`) or re-mount read-write, then re-run", "Other… (describe)"]`

Used when `code-scanner` or `diff-summarizer` returns `prep.read_only: true` **and** either `prep.ref_committed_at` is more than 14 days old or `prep.head_divergence.ahead > 0`, per `${CLAUDE_PLUGIN_ROOT}/references/read-only-repos.md` §5. Present per affected repo. Neither agent accepts a scan-target parameter — a user who genuinely needs the unmerged working tree says so via `"Other… (describe)"`, because scanning an unmerged tree is what caused this feature's original defect: released behavior cited from unreleased code.

A read-only mount is not a failure and does not use the `Refresh blocked` list: the scan proceeds at `prep.scanned_ref`. This prompt exists only because the container cannot fetch, so refreshing the clone is an action only the user can take on the host.

The condition gates the prompt, so the `(Recommended — <why>)` reason annotation is well-formed under the rules at the top of this file.

## Review verdict BLOCK (unresolved after one fix cycle) — /document

`choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run"]`

Used in `/document` Phase 7 at either of two points: when `doc-fixer` returns `Stop condition flag: NEEDS HUMAN` — it deferred a BLOCKER as needing a human decision, so no re-review runs — or when `doc-reviewer` returns BLOCK a second time.
Escalate per unresolved BLOCKER individually.

## Review verdict BLOCK (unresolved after one fix cycle) — /epics

`choices: ["Provide manual fix notes (you'll be prompted)", "Defer to a follow-up issue (record in Phase 9 report)", "Override and accept the finding", "Cancel the whole run", "Other… (describe)"]`

Used in `/epics` Phase 7 at either of two points: when `doc-fixer` returns `Stop condition flag: NEEDS HUMAN` — it deferred a BLOCKER as needing a human decision, so no re-review runs — or when `epic-reviewer` returns BLOCK a second time.
Escalate per unresolved BLOCKER individually. "Defer" means the finding goes
into an Epic-refinement note in the draft itself (appended as a
`## Refinement notes` section) in addition to the Phase 9 report.
