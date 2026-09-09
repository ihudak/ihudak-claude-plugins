# Docs-repo resolution (shared)

**Core references.** A citation of the form `workflows-core:<name>` names a shared reference in the `workflows-core` plugin. Load it with `Skill(skill: "workflows-core:reference", args: "<name>")` — never by path: `${CLAUDE_PLUGIN_ROOT}` resolves to this plugin, which does not carry it.

Single source of truth for **which directory a documentation command works in**. It has two entry points, and they are deliberately opposite:

- **`resolve-docs-repo`** (§1) — the signal-positive form, for a command that needs a docs repo that already exists.
- **`resolve-scaffold-target`** (§2) — the inverted form, for the one command that needs a place to make one.

Consumed by `/docs-brand`, `/docs-serve` and `/docs-profile` (`resolve-docs-repo`), and by `/docs-init` (`resolve-scaffold-target`). `/docs-audit` adopts `resolve-docs-repo` when it ships.

---

## 0. Why this is one file

Design D23 gives the family one docs-repo default — `${DOCS_PATH:-/workspace/docs}`, already a same-level citizen of `$SPECS_PATH` and `$REPOS_PATH`, and already the grounding root `workflows-core:docs-grounding` §1 resolves — and one inversion of the test applied to it. Four commands need that ladder. Restating it in four command bodies is the family's longest-running defect class: four copies of one key grammar drifted apart until a valid key hard-stopped the command its own redirect had sent it to. So the ladder is written once, here, and each command names the entry point it is executing rather than re-deriving the rungs.

The rule the family already states about identifiers applies unchanged to paths: **resolve against a known set, never re-derive by pattern.** Both entry points below test a directory against §3's signal set. Neither guesses from a repository's name, its position in the tree, or the shape of its layout.

---

## 1. `resolve-docs-repo`

The **signal-positive** form. It answers *"which existing docs repository am I working in?"* — so at every rung it is looking for evidence that a directory already is one.

1. **The first positional token**, if the invocation carries one. Taken as given; the operator named it.
2. **Else the current working directory**, *when it carries ≥ 1 signal from §3*.
3. **Else `${DOCS_PATH:-/workspace/docs}`**, *when it carries ≥ 1 signal from §3*. In a container the docs clone is mounted here, which makes this the common fast path rather than the exotic one.
4. **Else search `${REPOS_PATH:-/workspace}` one level deep** for a directory carrying ≥ 1 signal. A single hit is taken. Several hits are offered as a choice.
5. **Else ask.**

Resolve the answer to an absolute path, and **print which rung answered**. A command that quietly works in an unexpected directory is expensive to unpick afterwards.

A rung that finds a directory but no signal is not an error — it is a rung that did not answer, and the ladder continues. Only rung 5 is reached with nothing found, and rung 5 asks rather than defaulting.

---

## 2. `resolve-scaffold-target`

The **inverted** form, used by `/docs-init` alone. It answers *"where do I create a docs repository?"* — so the acceptance test on the same expression is reversed.

1. **The first positional token**, if the invocation carries one.
2. **Else `${DOCS_PATH:-/workspace/docs}`**, *when it is absent, or exists and carries no signal from §3*.
3. **Else the current working directory.**

Resolve to absolute and print which rung answered, exactly as §1 does.

**A `$DOCS_PATH` carrying a signal is never skipped silently at rung 2.** It is reported, together with the redirect to `/docs-profile`, because it is almost certainly the repository the operator meant: they pointed the variable at a docs repo and then asked to scaffold one. Falling through to the working directory without saying so is how a scaffold lands in a source tree.

---

## 3. The signal set

One list, tested by both entry points, identical to the set `/document` Phase 0 already applies. A directory carries a signal when any of these is present:

- a `*:start`, `*:build`, `*:lint`, or `docs:*` script in `package.json`;
- a `.docstack/` directory;
- `mkdocs.yml`;
- `docusaurus.config.js`;
- `antora.yml`;
- `.vale.ini`;
- `DOCUMENTATION-GUIDELINES.md`;
- any `*/_content/` directory;
- any `_snippets/` directory.

**Signal-based, never keyed to a repository's name or its file layout.** A repository called `docs` with none of the above is not a docs repo, and one called `handbook` with `mkdocs.yml` is.

The set is deliberately generous. A false positive costs a question; a false negative sends a command to the wrong directory, which costs a scaffold or an edit in a source tree.

---

## 4. Why the two forms are opposite

Every consumer but one wants a docs repository that **exists** — to profile it, to brand it, to serve it, to audit it. `/docs-init` wants a place to **make** one, and its Phase 0 step 4 refuses to scaffold over an existing docs repo. Same variable, same default, opposite predicate.

This is spelled out rather than left implicit because an implementer copying `/document`'s ladder into `/docs-init` gets it exactly backwards, and the scaffold then refuses the one directory it was pointed at. The mistake is invisible in review — the ladder *looks* right, because it is the ladder every sibling uses — and it only shows up as a command that will not run where the operator expects it to.

The inversion is not a special case bolted onto one ladder. It is what distinguishes an **adopting** command from a **creating** one, and any later command that creates a docs repository takes §2, not §1.

---

## 5. What this file does not do

It resolves a path and reports which rung answered. That is all.

- It **never creates a directory** and never runs `git init`. `/docs-init` offers that at its own Phase 0 step 3, because the offer is that command's alone.
- It **never validates writability**, and never checks that the resolved path is a git work tree. Those are preconditions each caller states for itself, and the right response to a failure differs per command — a stop for one, a prompt for another.
- It **never refuses**. §2's rung-2 report is a report, not a stop; `/docs-init`'s own step 4 owns the refusal to scaffold over an existing docs repo, and owns the exit code that goes with it.

Keeping resolution free of policy is what lets four commands share it. A ladder that also enforced one command's preconditions would be four ladders again within two releases.

---

## 6. Hard rules

- NEVER re-derive the signal set in a command body. Cite §3 and test against it.
- NEVER take a rung's directory without the signal test the rung states — rungs 2 and 3 of §1, and rung 2 of §2, are conditional rungs, not defaults.
- NEVER resolve silently. Print the rung that answered, every run.
- NEVER infer a docs repository from its name or its path. §3 is the whole test.
- NEVER let `resolve-scaffold-target` fall through a signal-carrying `$DOCS_PATH` without reporting it and naming `/docs-profile`.
