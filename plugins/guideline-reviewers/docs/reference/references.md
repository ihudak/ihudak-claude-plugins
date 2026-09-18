# References

This plugin bundles the guidance it reviews against — 38 files under `references/` — so a review cites a file that ships with it rather than a page on the internet that may have moved. Two subtrees hold it: `api-guidelines/` for `/api-guideline-reviewer` and `guidelines/` for `/guideline-reviewer`. The counts below are **markdown files only** — the subtrees also carry vendored non-markdown files (a Spectral ruleset, an OpenAPI template and a checker script) that are not reference pages a reader opens, so they are not counted here even though they ship with the corpus and move with it. The arithmetic below counts them per subtree.

| Subtree (markdown files) | What it holds | Derived from |
|---------|-------|---------------|
| `api-guidelines/` (24) | REST API and IAM permission-naming guidance, plus an OpenAPI template and a Spectral ruleset — the two files the count leaves out | Google AIP, Zalando, Microsoft REST guidelines, OpenAPI 3.1 and the RFCs they cite |
| `guidelines/` (11) | Design-system and accessibility guidance, plus a checklist template and a checker script — the script being the one file the count leaves out | Apple HIG, Material Design 3, Microsoft Fluent 2, W3C WCAG 2.2, ARIA APG and NN/g |

The arithmetic: 24 markdown files plus 2 non-markdown files (`api-guidelines/template/openapi-template.yaml` and `api-guidelines/spectral/ruleset.yaml`) makes 26 files under `api-guidelines/`; 11 markdown files plus 1 non-markdown file (`guidelines/check_guidelines.py`) makes 12 files under `guidelines/`. 26 + 12 = 38 files in total, matching the count in the opening paragraph above.

`api-guidelines/spectral/ruleset.yaml` runs against a specification directly; `guidelines/check_guidelines.py` is invoked by the review flow; `api-guidelines/template/openapi-template.yaml` is a starter OpenAPI document — the shape `rest-api-guidelines/OpenAPI.md` links to and a review compares a specification against. Those are the three non-markdown files the opening paragraph names; everything else is prose the agents read.
