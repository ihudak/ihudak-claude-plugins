#!/usr/bin/env python3
"""PostToolUse reminder for dynatrace-docs frontmatter conventions.

Reads a Claude Code PostToolUse payload on stdin. If the edited file is a
dynatrace-docs content page, prints a warn-only {"systemMessage": ...} listing
any missing changelog (today's entry) or required managed owners. Always exits 0.
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
    fpath = os.path.join(root, "references", "dynatrace-docs", "managed-owners.txt")
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
    is_managed = "/managed/_content/" in path
    is_saas = "/dynatrace/_content/" in path
    if not (is_managed or is_saas):
        return
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
    if is_managed:
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
        msg = "dynatrace-docs %s — %s. Run the dynatrace-docs-frontmatter skill." % (
            os.path.basename(path), "; ".join(issues)
        )
        print(json.dumps({"systemMessage": msg}))


if __name__ == "__main__":
    main()
    sys.exit(0)
