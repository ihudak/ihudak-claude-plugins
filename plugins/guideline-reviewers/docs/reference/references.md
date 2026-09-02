# References

This plugin bundles the guidance it reviews against — 38 files under `references/` — so a review cites a file that ships with it rather than a page on the internet that may have moved. Two subtrees hold it: `api-guidelines/` for `/api-guideline-reviewer` and `guidelines/` for `/guideline-reviewer`. The counts below are **markdown files only** — each subtree also carries one vendored non-markdown file (a Spectral ruleset, an OpenAPI template, or a checker script) that is not a reference page a reader opens, so it is not counted here even though it ships with the corpus and moves with it.

| Subtree | Markdown files | What it holds |
|---------|-------|---------------|
| `api-guidelines/` (24) | REST API guidance, IAM permission-naming guidance, an OpenAPI template, and a Spectral ruleset | Derived from Google AIP, Zalando, Microsoft REST guidelines, OpenAPI 3.1 and the RFCs they cite |
| `guidelines/` (11) | Design-system and accessibility guidance, plus a checklist template and a checker script | Derived from Apple HIG, Material Design 3, Microsoft Fluent 2, W3C WCAG 2.2, ARIA APG and NN/g |

The arithmetic: 24 markdown files plus 2 non-markdown files (`api-guidelines/template/openapi-template.yaml` and `api-guidelines/spectral/ruleset.yaml`) makes 26 files under `api-guidelines/`; 11 markdown files plus 1 non-markdown file (`guidelines/check_guidelines.py`) makes 12 files under `guidelines/`. 26 + 12 = 38 files in total, matching the count in the opening paragraph above.

`api-guidelines/spectral/ruleset.yaml` runs against a specification directly; `guidelines/check_guidelines.py` is invoked by the review flow. Everything else is prose the agents read.
