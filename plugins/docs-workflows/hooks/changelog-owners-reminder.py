#!/usr/bin/env python3
"""PostToolUse reminder for docs-repo frontmatter conventions.

Reads a Claude Code PostToolUse payload on stdin. If the edited file sits under a
content root declared by the applicable docs profile, prints a warn-only
{"systemMessage": ...} listing any missing changelog (today's entry) or required
page owners. Always exits 0.

Content roots are resolved from the profile, never hardcoded: the nearest
.dev-workflows/docs-profile.yml walking up from the edited file, else the built-in
default profile. Parsing is a tolerant line scan -- this hook must never depend on
PyYAML being installed, and must never raise.
"""
import sys
import os
import json
import re
import subprocess
import datetime


def _today():
    return datetime.date.today().isoformat()


def _first_changelog_date(fm):
    in_block = False
    for line in fm.splitlines():
        if re.match(r"^changelog:\s*$", line):
            in_block = True
            continue
        if in_block:
            item = re.match(r"^\s*-\s*(\d{4}-\d{2}-\d{2})\b", line)
            if item:
                return item.group(1)
            if line.strip() and not line.lstrip().startswith("-"):
                return None
    return None


def _owners(fm):
    present = bool(re.search(r"^owners:\s*$", fm, re.M))
    found = set()
    in_block = False
    for line in fm.splitlines():
        if re.match(r"^owners:\s*$", line):
            in_block = True
            continue
        if in_block:
            item = re.match(r"^\s*-\s*(\S+)", line)
            if item:
                found.add(item.group(1))
                continue
            if line.strip() and not line.lstrip().startswith("-"):
                break
    return present, found


def _required_owners():
    root = os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    if not root:
        return []
    fpath = os.path.join(root, "references", "docs-profiles", "default-owners.txt")
    out = []
    try:
        with open(fpath, encoding="utf-8") as fh:
            for ln in fh:
                ln = ln.strip()
                if ln and not ln.startswith("#"):
                    out.append(ln)
    except OSError:
        pass
    return out


def _profile_path(start):
    """Nearest .dev-workflows/docs-profile.yml walking up from the edited file."""
    d = os.path.dirname(os.path.abspath(start))
    while True:
        cand = os.path.join(d, ".dev-workflows", "docs-profile.yml")
        if os.path.isfile(cand):
            return cand
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def _builtin_profile():
    root = os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    if not root:
        return None
    cand = os.path.join(root, "references", "docs-profiles", "docs-profile.default.yml")
    return cand if os.path.isfile(cand) else None


def _spaces(start):
    """[(space_id, content_root)] from the applicable profile. Tolerant line scan."""
    fpath = _profile_path(start) or _builtin_profile()
    if not fpath:
        return []
    try:
        with open(fpath, encoding="utf-8") as fh:
            lines = fh.readlines()
    except OSError:
        return []
    out, cur, in_spaces = [], None, False
    for ln in lines:
        if re.match(r"^spaces:\s*$", ln):
            in_spaces = True
            continue
        if in_spaces and re.match(r"^[a-z_]+:", ln):
            break
        if not in_spaces:
            continue
        m = re.match(r"^\s*-\s*id:\s*[\"']?([\w.-]+)", ln)
        if m:
            cur = m.group(1)
            continue
        m = re.match(r"^\s*content_root:\s*[\"']?([^\"'\s]+)", ln)
        if m and cur:
            out.append((cur, m.group(1).rstrip("/")))
    return out


def _owners_spaces(start):
    """Space ids whose pages require an owners block (frontmatter.owners_spaces)."""
    fpath = _profile_path(start) or _builtin_profile()
    if not fpath:
        return []
    try:
        text = open(fpath, encoding="utf-8").read()
    except OSError:
        return []
    m = re.search(r"^\s*owners_spaces:\s*\[([^\]]*)\]", text, re.M)
    if m:
        return [x.strip().strip("\"'") for x in m.group(1).split(",") if x.strip()]
    m = re.search(r"^\s*owners_spaces:\s*$((?:\n\s+-\s*.+)+)", text, re.M)
    if m:
        return [x.strip().lstrip("-").strip().strip("\"'") for x in m.group(1).strip().splitlines()]
    return []


def _tracked_modified(path):
    """True only when git reports the file as tracked-and-modified (not new)."""
    d = os.path.dirname(path) or "."
    try:
        r = subprocess.run(
            ["git", "-C", d, "status", "--porcelain", "--", path],
            capture_output=True, text=True, timeout=10,
        )
    except Exception:
        return False
    if r.returncode != 0:
        return False
    st = r.stdout[:2] if r.stdout else ""
    is_new = st == "??" or st.startswith("A")
    return ("M" in st) and not is_new


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    path = (data.get("tool_input") or {}).get("file_path") or ""
    if not path.endswith(".md"):
        return
    norm = path.replace(os.sep, "/")
    matched = [sid for sid, root in _spaces(path) if ("/" + root.strip("/") + "/") in norm]
    if not matched:
        return
    needs_owners = bool(set(matched) & set(_owners_spaces(path)))
    try:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
    except OSError:
        return

    m = re.match(r"^---\n(.*?)\n---", text, re.S)
    fm = m.group(1) if m else ""

    issues = []
    if _tracked_modified(path) and _first_changelog_date(fm) != _today():
        have = _first_changelog_date(fm) or "none"
        issues.append(
            "changelog: newest entry is %s, expected an entry dated %s"
            % (have, _today())
        )
    if needs_owners:
        required = _required_owners()
        if required:
            present, owners = _owners(fm)
            if not present:
                issues.append("owners: add an owners block with " + ", ".join(required))
            else:
                missing = [o for o in required if o not in owners]
                if missing:
                    issues.append("owners: add " + ", ".join(missing))

    if issues:
        msg = "%s — %s. Run the docs-frontmatter skill." % (
            os.path.basename(path), "; ".join(issues)
        )
        print(json.dumps({"systemMessage": msg}))


if __name__ == "__main__":
    main()
    sys.exit(0)
