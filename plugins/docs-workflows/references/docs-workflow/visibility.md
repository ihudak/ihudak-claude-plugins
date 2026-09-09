# Visibility — two builds from one source tree

Single source of truth for how public and internal documentation are separated, why the obvious ways of checking that separation do not work, and what CI asserts instead.

Consumed by `/docs-init`, which writes the two build configs and the workflow in §6, and by `docs-scaffold-reviewer`, whose checklist asserts the relationship §4 describes. `/docs-serve` reads §2 — it is the command that boots the dev server this file warns about — and `/docs-write` reads §5, because a page it writes under `internal/` carries the marker or the gate cannot see it.

Its entry points, so a command can say which part it is executing: **the model** (§1), **the traps** (§2 and §3), **the gates** (§4), and **the CI workflow** (§6).

---

## 1. The model

One source tree, shared snippets, working cross-links. Two builds over that one tree:

| Build | Config | What it contains | Output |
|---|---|---|---|
| **public** | `mkdocs.yml` | every page except those under `internal/`, dropped by `exclude_docs` (gitignore-style patterns, MkDocs 1.6+) | `site/` |
| **internal** | `mkdocs.internal.yml` | every page, via `INHERIT: mkdocs.yml` plus the internal nav | `site-internal/` |

**The two configs differ only in which paths they exclude**, and neither exclusion set is empty. The public build drops `internal/` and `_snippets/`; the internal build drops `_snippets/` alone. The fragment directory is excluded from **both** because a fragment is an include and not a page: left in a build, every file under `docs/_snippets/` renders as a standalone page — an orphan in the nav, and, for an internal fragment in the public build, a leak more direct than the one gate 2 exists for. Excluding it costs nothing, because `pymdownx.snippets` reads its fragments off the filesystem rather than out of the build (`scaffold-tree.md` §5).

Two outputs, two deploy targets, **two hostnames**.

**Separate hostnames rather than a protected path prefix.** Path-prefix protection is easy to misconfigure and fails open: a rule that was meant to guard `/internal/*` and does not match is indistinguishable, from outside, from no rule at all. A separate host fails closed, because there is nothing at the public host to protect.

**The family does not implement authentication.** Protection at the internal host is the project's own choice — basic auth at a reverse proxy, an SSO proxy, a private host, a VPN. What the family produces is two artefacts and an unambiguous statement of which is which; what happens to the internal one is infrastructure.

One content root is what makes this worth doing at all. A second site would give the internal pages their own search index, their own snippet base path, and broken links in both directions. `visibility` is a build-time decision precisely so that an internal page can link a public one and be right.

---

## 2. Trap 1 — the dev server does not exclude

As of MkDocs 1.6, **`exclude_docs` does not apply to `mkdocs serve`.** Excluded pages still render locally, at their ordinary URLs, in the site you are looking at.

That is convenient for authoring — you can read an internal page while writing the public one beside it — and dangerous for verification: **what you see locally is not what ships.**

**Rule: visibility is never confirmed by looking at the dev server.** Not by browsing it, not by searching it, not by checking that a URL 404s in it. It is confirmed against **built output** only — `site/`, produced by `mkdocs build`, which is the artefact that is actually deployed.

A run that reports "the internal page is not in the public site" on the strength of a dev-server observation has reported nothing. `/docs-serve` boots that server and says so where it does.

---

## 3. Trap 2 — snippets cross the boundary invisibly

`pymdownx.snippets` lets a page include a file from `docs/_snippets/`. An **internal snippet included into a public page leaks its content** even though every file sits in exactly the correct directory.

A path-based rule cannot catch this, because **no path is wrong**. The internal snippet is under the snippet root, the public page is outside `internal/`, and the include is a legal include.

**Excluding the snippet does not help, and understanding why is the whole trap.** `exclude_docs` governs what the build renders as a page; `pymdownx.snippets` reads its fragments off the **filesystem**. So `_snippets/` is excluded from both builds and every fragment is still includable — which is what makes that exclusion safe (§1) — and it is exactly why the exclusion cannot be the defence here. The fragment never ships as a page; its **content** ships, inside a page that does.

Nor does a link check catch it. There is no link. There is only text that used to be in one document and is now in another.

This is the whole reason the second gate exists, and the reason it asserts on **rendered HTML** rather than on sources.

---

## 4. The two gates

Both gates run in CI, and **both assert on built output**. That is the discipline the traps buy: the dev server is not evidence (§2), and source layout is not evidence (§3), so the only thing left that can be evidence is the artefact that ships.

**Gate 1 — public build with `strict: true`.** `mkdocs.yml` sets `strict: true` and

```yaml
validation:
  nav:
    omitted_files: warn
    absolute_links: warn
```

so a public page linking into `internal/` becomes a **build failure** rather than a broken link discovered by a reader. It is free — the build has to run anyway — and it catches the link class completely.

**Gate 2 — marker grep over the public build output.** Every file under `docs/internal/` and every snippet intended for internal pages carries the §5 marker. The gate fails if that marker appears anywhere under the public `site/` tree. This is what catches the snippet-level leakage §3 describes, which paths and links both miss.

Gate 2 is the same technique as verifying a history rewrite by grepping the resulting blobs: **assert on the artefact, not on the intent.**

### The third gate, and when it exists

`images.policy` in the profile (`references/docs-profiles/docs-profile-schema.md` fixes the field and its per-policy rules; they are not restated here) decides whether a third gate is written at all, because the two above have no reach into an object store.

- **`in-repo`** — no third gate, because there are no image **URLs** to check: an image is a file in the tree, referenced by a relative path, and the build resolves it. What separates the two builds here is the same `exclude_docs` that separates the pages — it drops files, not only Markdown — so **an image that only internal pages may see belongs under `docs/internal/`, not under `images.root`.** A file under `images.root` is copied into *both* builds whether or not any page references it: MkDocs copies the content tree, it does not trace references. What is written instead of a gate is the **size-budget step**, checking each file against `images.max_bytes` (default 307200 bytes, rendered in the template as `+300k`), because committed binaries are permanent and an unbudgeted default is how a docs repository becomes one nobody wants to clone.
- **`object-store` and `cdn`** — the third gate is written, and the size-budget step is not. **A bucket has no notion of the two builds.** A public page referencing an internal screenshot leaks the image while gates 1 and 2 both pass, because the leak is in the object store and not in the HTML. So the gate asserts that **every image URL in the built public output starts with `images.public_prefix`**; under `object-store`, internal media lives under `images.internal_prefix`, which is what the gate is separating it from. A gate cannot assert against a prefix the profile does not record, which is why those two fields are part of the schema rather than left to convention.

**Neither step is written unconditionally.** A size-budget step under `cdn` checks a directory that holds no images; an image-prefix gate under `in-repo` checks URLs that do not exist. Both are green forever, which is worse than absent: a gate that cannot fail teaches a reviewer that the gate set is complete when it is not.

The script the template names — `scripts/check-image-prefix.sh` — is part of the **scaffolded repository**, not of this plugin. What it must assert is the sentence above: every image URL in the public build output resolves to `images.public_prefix`, with the offending page and URL named on failure, and a non-zero exit.

---

## 5. The marker convention

Every file under `docs/internal/`, and every snippet intended for internal pages, carries this as its **first line after the frontmatter**:

```markdown
<!-- docs-visibility: internal -->
```

An HTML comment survives into rendered output, which is exactly the property gate 2 needs: the marker travels with the content, through a snippet include, into whatever page inlined it, and lands in the HTML where a grep over `site/` finds it. A frontmatter key would not — it is consumed by the renderer and never reaches the artefact — and neither would a naming convention, because §3's leak carries content across a boundary while leaving every name correct.

Two consequences worth stating, because both halves of the convention have to agree or the gate is decoration:

- **A snippet under `docs/_snippets/` that is meant for internal pages carries the marker too.** It is not under `internal/`, so nothing else marks it, and it is the exact file §3's trap travels in.
- **A public page never carries the marker**, not even quoting it in prose about visibility. Gate 2 greps for the literal string, so a page explaining the convention would fail the build that ships it. Documentation of the marker belongs outside the built tree — in this reference, and in the plugin's own `docs/`.

---

## 6. The CI workflow

`/docs-init` writes this to `.github/workflows/docs.yml`. Both builds run, the visibility gate runs against the public output, and the image steps are written per `images.policy` per §4 — the two marked steps are **conditional and are omitted, not disabled, when the policy does not call for them**.

```yaml
name: docs
on:
  pull_request:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements-docs.txt
      - name: Build public site
        run: mkdocs build --strict -f mkdocs.yml
      - name: Build internal site
        run: mkdocs build --strict -f mkdocs.internal.yml
      - name: Gate 2 — no internal marker in the public build
        run: |
          if grep -rl 'docs-visibility: internal' site/; then
            echo "::error::internal content reached the public build"
            exit 1
          fi
      # WRITTEN ONLY WHEN images.policy is object-store or cdn — omit under in-repo
      - name: Gate 3 — every public image URL resolves to the public prefix
        run: scripts/check-image-prefix.sh
      # WRITTEN ONLY WHEN images.policy is in-repo — omit under object-store and cdn.
      # The threshold is the profile's images.max_bytes; +300k renders the 307200 default.
      - name: Image size budget
        run: |
          find docs/assets -type f -size +300k -print -exec false {} + \
            || { echo "::error::image over the 300 KB budget"; exit 1; }
      - name: Vale
        run: vale docs/
```

Gate 1 is not a step of its own: it **is** the `Build public site` step, because `strict: true` in `mkdocs.yml` is what makes a cross-boundary link fail the build. A workflow that ran the build without `--strict`, or a config that dropped `strict: true`, would silently retire gate 1 while the step still appeared to run — which is why `docs-scaffold-reviewer` checks the config and the workflow against each other rather than either alone.

The internal build runs on every PR too. It is not deployed from here, but a config that has drifted into a second source of truth fails loudly at build time rather than at the next release.

---

## 7. Hard rules

- NEVER confirm visibility from the dev server. Built output only (§2).
- NEVER treat correct file placement as evidence that content did not cross the boundary (§3).
- NEVER write an internal file, or an internal-only snippet, without the §5 marker.
- NEVER quote the literal marker string on a page inside the built public tree.
- NEVER write a conditional image step the resolved `images.policy` does not call for (§4).
- NEVER let the two build configs differ by anything but their `exclude_docs` sets — see `scaffold-tree.md` §6, and note that neither set is empty.
