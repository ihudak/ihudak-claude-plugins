---
tags:
  - plan
  - ai
  - dev-workflows
  - tasks-exclude
date: 2026-08-16
---

# Primitive harness — `require-on-main` / `handoff-to-main` git behaviours

Required by the 2026-08-16 single fix wave on `iv-gu/phase-handoff-gates` (whole-branch review verdict MERGE AFTER FIXES). A **local, network-free** shell harness that creates a throwaway bare repo plus a clone in `$(mktemp -d)` and exercises the git-tool behaviours no static read of `references/phase-handoff.md` can settle: (1) `require-on-main`'s §3.2 primitives across rows A, B, D/E, F, and G; (2) `handoff-to-main` §2.2's collision path — an existing local **and** remote branch, the `merge-base --is-ancestor` reuse test, and the `-2`/`-3` suffix loop; (3) §2.3's `git add -A -- <literal paths>` staging a **deletion**, which `/idea`'s relocation depends on entirely. No `gh pr create` call is made anywhere — that would create a live pull request as a side effect.

Environment this was run in: `git version 2.43.0`, no network access required or used.

## The script

```bash
#!/usr/bin/env bash
# Local, network-free harness for phase-handoff.md's require-on-main (§3.2 primitives, rows A/B/D-E/F/G),
# handoff-to-main §2.2 (collision + merge-base reuse test + suffix loop), and §2.3 (git add -A -- <literal
# paths> staging a deletion). No `gh` call is made anywhere in this script.
set -uo pipefail
ok=0; bad=0
check() { # desc, expected, actual
  if [ "$2" = "$3" ]; then echo "PASS  $1 (expect=$2 actual=$3)"; ok=$((ok+1));
  else echo "FAIL  $1 (expect=$2 actual=$3)"; bad=$((bad+1)); fi
}

T=$(mktemp -d); BARE="$T/origin.git"; C="$T/clone"
git init -q --bare "$BARE"
git clone -q "$BARE" "$C" 2>/dev/null; cd "$C"
git config user.email t@t.com; git config user.name t
echo hi > path.md; git add path.md; git commit -qm init; git branch -M main; git push -qu origin main

echo "### 1. require-on-main primitives (§3.2), rows A/B/D-E/F/G"
git rev-parse --verify --quiet origin/main >/dev/null 2>&1; check "ref-exists (main present)" 0 $?
git cat-file -e origin/main:path.md 2>/dev/null; check "on-ref (path.md present on main)" 0 $?
git diff --quiet origin/main -- path.md; check "worktree==ref -> row A" 0 $?

git checkout -qb design/K1-slug
echo amend >> path.md; git commit -aqm amend           # not pushed: legitimate in-progress amendment
git diff --quiet origin/main -- path.md; check "worktree!=ref on owned branch -> row B territory" 1 $?

git checkout -qb spec/K2-slug main
echo s > spec.md; git add spec.md; git commit -qm addspec; git push -qu origin spec/K2-slug
git cat-file -e origin/main:spec.md 2>/dev/null; check "spec.md on-ref (main)? -> git cat-file -e exit code" 128 $?
git for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -qE '^origin/(idea|vi|ard|spec|design|ready)/'
check "plugin-ref scan finds a carrying branch" 0 $?
git cat-file -e origin/spec/K2-slug:spec.md 2>/dev/null; check "spec.md found on carrying ref -> row D/E" 0 $?

git cat-file -e origin/main:nope.md 2>/dev/null; check "nope.md on-ref (main)? -> git cat-file -e exit code" 128 $?
found=1
for ref in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -E '^origin/(idea|vi|ard|spec|design|ready)/'); do
  git cat-file -e "$ref:nope.md" 2>/dev/null && found=0
done
check "nope.md on ANY plugin ref -> not found anywhere, row F" 1 "$found"

git update-ref -d refs/remotes/origin/main
git rev-parse --verify --quiet origin/main >/dev/null 2>&1; check "origin/main ref deleted -> row G, ref-exists primitive" 1 $?
git cat-file -e origin/main:path.md 2>/dev/null; c1=$?
git cat-file -e origin/spec/K2-slug:doesnotexist.md 2>/dev/null; c2=$?
check "row-F-shape vs row-G-shape: cat-file -e gives the SAME exit code for both (the defect f5a9713/F1 closed)" "$c1" "$c2"

echo "### 2. handoff-to-main §2.2 — collision, merge-base reuse, suffix loop"
T2=$(mktemp -d); BARE2="$T2/origin.git"; C2="$T2/clone"
git init -q --bare "$BARE2"; git clone -q "$BARE2" "$C2" 2>/dev/null; cd "$C2"
git config user.email t@t.com; git config user.name t
echo hi > f.md; git add f.md; git commit -qm init; git branch -M main; git push -qu origin main
git checkout -qb vi/K3-slug; echo x >> f.md; git commit -aqm x; git push -qu origin vi/K3-slug
git rev-parse --verify --quiet refs/heads/vi/K3-slug >/dev/null 2>&1; l=$?
git rev-parse --verify --quiet refs/remotes/origin/vi/K3-slug >/dev/null 2>&1; r=$?
check "both local and remote refs exist (collision, not exceptional; M9's 'at least one')" "0 0" "$l $r"
git merge-base --is-ancestor refs/remotes/origin/vi/K3-slug refs/remotes/origin/main; check "not yet merged -> is-ancestor fails -> reuse-not-recreate" 1 $?
git branch vi/K3-slug-2 main; git push -qu origin vi/K3-slug-2   # occupy -2 so the loop must reach -3
free=""
for i in 2 3 4; do
  cand="vi/K3-slug-$i"
  git rev-parse --verify --quiet "refs/heads/$cand" >/dev/null 2>&1; lh=$?
  git rev-parse --verify --quiet "refs/remotes/origin/$cand" >/dev/null 2>&1; rh=$?
  if [ $lh -ne 0 ] && [ $rh -ne 0 ]; then free="$cand"; break; fi
done
check "suffix loop lands on the first free name (skips taken -2)" "vi/K3-slug-3" "$free"

echo "### 3. §2.3 — git add -A -- <literal paths> staging a deletion"
git checkout -q main
mkdir -p vault specs
echo idea > vault/idea.md; git add vault/idea.md; git commit -qm addidea
rm vault/idea.md; echo idea > specs/idea.md   # simulate /idea's relocation: delete old, write new
git add -A -- vault/idea.md specs/idea.md
withA=$(git status --porcelain -- vault/idea.md specs/idea.md)
bothPathsShown="no"
case "$withA" in *"vault/idea.md"*"specs/idea.md"*) bothPathsShown="yes" ;; esac
check "'git add -A -- <literal paths>' stages an entry covering BOTH the old and new path" "yes" "$bothPathsShown"
git reset -q -- vault/idea.md specs/idea.md
git add -- vault/idea.md specs/idea.md   # NO -A, same literal paths
noA=$(git status --porcelain -- vault/idea.md specs/idea.md)
check "plain 'git add -- <literal paths>' (NO -A) — same result as with -A? (git $(git --version | awk '{print $3}'))" "$withA" "$noA"

echo "### summary: $ok pass, $bad fail"
rm -rf "$T" "$T2"
```

## Actual output (this run)

```
### 1. require-on-main primitives (§3.2), rows A/B/D-E/F/G
PASS  ref-exists (main present) (expect=0 actual=0)
PASS  on-ref (path.md present on main) (expect=0 actual=0)
PASS  worktree==ref -> row A (expect=0 actual=0)
PASS  worktree!=ref on owned branch -> row B territory (expect=1 actual=1)
PASS  spec.md on-ref (main)? -> git cat-file -e exit code (expect=128 actual=128)
PASS  plugin-ref scan finds a carrying branch (expect=0 actual=0)
PASS  spec.md found on carrying ref -> row D/E (expect=0 actual=0)
PASS  nope.md on-ref (main)? -> git cat-file -e exit code (expect=128 actual=128)
PASS  nope.md on ANY plugin ref -> not found anywhere, row F (expect=1 actual=1)
PASS  origin/main ref deleted -> row G, ref-exists primitive (expect=1 actual=1)
PASS  row-F-shape vs row-G-shape: cat-file -e gives the SAME exit code for both (the defect f5a9713/F1 closed) (expect=128 actual=128)
### 2. handoff-to-main §2.2 — collision, merge-base reuse, suffix loop
PASS  both local and remote refs exist (collision, not exceptional; M9's 'at least one') (expect=0 0 actual=0 0)
PASS  not yet merged -> is-ancestor fails -> reuse-not-recreate (expect=1 actual=1)
PASS  suffix loop lands on the first free name (skips taken -2) (expect=vi/K3-slug-3 actual=vi/K3-slug-3)
### 3. §2.3 — git add -A -- <literal paths> staging a deletion
PASS  'git add -A -- <literal paths>' stages an entry covering BOTH the old and new path (expect=yes actual=yes)
PASS  plain 'git add -- <literal paths>' (NO -A) — same result as with -A? (git 2.43.0) (expect=R  vault/idea.md -> specs/idea.md actual=R  vault/idea.md -> specs/idea.md)
### summary: 16 pass, 0 fail
```

All 16 checks passed. Nothing in `require-on-main`'s row A/B/D-E/F/G predicates or `handoff-to-main`'s §2.2 collision/reuse/suffix logic was contradicted by the actual git tool behaviour.

## What this falsifies

**One expectation, real, worth recording.** `specs-repo-git.md` §2.1 and `phase-handoff.md` §2.3 both justify the `-A` flag on `git add -A -- <path> [<path>…]` with the same rationale: *"`-A` is required: a producer may delete a file it relocated … and plain `git add` would not stage the deletion."* The last two checks above directly test this, on **git 2.43.0**, with the exact literal-path invocation both references specify (`git add -- <path> <path>`, not `git add .` or a directory pathspec): plain `git add -- vault/idea.md specs/idea.md` (no `-A`) produced **byte-identical** `git status --porcelain` output to `git add -A -- vault/idea.md specs/idea.md`. For a literal path argument, `-A` makes **no observable difference** to whether a deletion is staged — that restriction was retired in git 2.0 (2014) and only ever applied to bare `git add .`/directory pathspecs in pre-2.0 git, never to a path named explicitly on the command line. The `-A` flag in the plugin's own commands is still **harmless and correct to keep** (it costs nothing and guards against a git version older than what this environment has, however unlikely), but the stated *reason* for it is empirically false for the invocation actually used. Not one of the ten findings in this fix wave's brief, so left as a reported observation rather than an edit to `specs-repo-git.md`/`phase-handoff.md` — flagging for the maintainer per this task's instruction to report, not silently fix, anything the harness falsifies.

**One secondary observation, not a falsification of any written claim.** The delete-old/add-new-identical-content pattern that both checks constructed is exactly `/idea`'s relocation shape, and git's status/add machinery auto-detects it as a **rename** (`R  vault/idea.md -> specs/idea.md`), not two separate `D`/`A` lines. Neither `specs-repo-git.md` nor `phase-handoff.md` makes a claim about the porcelain line *shape*, only about whether the deletion is staged at all (which it is, correctly, either way) — so this is not a falsification, just a fact worth knowing for anyone who later writes a line-prefix parser against this output: a rename line carries both the old and the new path on one line, not on two.

## Row G / row F distinguishing primitive — independently reconfirmed

Check 11 above (`row-F-shape vs row-G-shape`) reconfirms, on this run's own scratch repo, the same empirical result the 2026-08-15 verification record obtained in its own scratch repo: `git cat-file -e <ref>:<path>` exits **128** whether the ref is missing or only the path is missing, so a §3.2 implementation that skips the ref-existence primitive cannot tell the two apart — the reason F1 (this fix wave) had a real defect to fix in §3.3's row order, not just a cosmetic one.
