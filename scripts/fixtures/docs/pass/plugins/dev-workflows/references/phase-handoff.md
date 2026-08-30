# Phase handoff (fixture)

## 3.4 Row F delegates

The gate's absent row, per caller: what each command runs `require-on-main` against,
and what it does when the artifact is on no ref.

| Caller | Input | Pre-existing absent behaviour, preserved |
|---|---|---|
| `/omega` | the fixture's `alpha-deliverable.md` | **stops** — the first family command's consumer |
| `/tau` | the fixture's `alpha-two-out.md` | **stops** — the second family command's consumer |
| `/sigma` | the fixture's `elsewhere.md` | **stops** — gated on an artifact no fixture command writes |
