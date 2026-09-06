#!/usr/bin/env python3
"""Render a product specification (the markdown format produced by the authoring
skills: specification-user-stories, specification-acceptance-criteria, specification-test-cases) into a self-contained, human-friendly
HTML file for review.

Usage:
    python3 specification-to-html.py <spec.md> [<spec2.md> ...]
    python3 specification-to-html.py <spec.md> -o <output.html>

With no -o, each input is written alongside it with a .html extension.
The output is a single self-contained file (inline CSS + JS) — no dependencies,
stdlib only, Python 3.8+.
"""

# Provenance: verbatim snapshot from mgd-specifications
# .claude/skills/specification-to-html/scripts/specification-to-html.py, imported 2026-07-07.
# Embedded so /specify is self-sufficient (no runtime dependency on that repo). Re-sync manually.

import sys
import os
import re
import html
import argparse

CATEGORY_CLASS = {
    "Happy path": "cat-happy",
    "Negative / boundary": "cat-neg",
    "State / lifecycle": "cat-state",
    "Security / privacy": "cat-sec",
    "Audit / observability": "cat-audit",
}


# --------------------------------------------------------------------------- #
# Inline markdown -> HTML
# --------------------------------------------------------------------------- #
def inline(text):
    t = html.escape(text.strip())
    t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", t)
    return t


def split_steps(s):
    parts = re.split(r"\s*\d+\.\s+", s.strip())
    return [p.strip().rstrip(".") for p in parts if p.strip()]


# --------------------------------------------------------------------------- #
# Parser
# --------------------------------------------------------------------------- #
def parse(md):
    lines = md.splitlines()
    spec = {"meta": {}, "problem": [], "problem_oq": [],
            "scope_in": [], "scope_out": [], "scope_oq": [],
            "stories": []}
    section = None        # 'meta','problem','scope','stories'
    scope_bucket = None   # 'in','out'
    oq_target = None      # where '- [ ]' items currently go
    story = None
    ac = None
    tc = None

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # header meta bullets
        m = re.match(r"^- \*\*(.+?)\*\*:\s*(.*)$", line)
        if m and section in (None, "meta"):
            spec["meta"][m.group(1)] = m.group(2)
            section = "meta"
            i += 1
            continue

        if stripped == "## Problem statement":
            section, oq_target = "problem", "problem_oq"
            i += 1
            continue
        if stripped == "## Scope":
            section, scope_bucket, oq_target = "scope", None, "scope_oq"
            i += 1
            continue
        if stripped == "## User stories":
            section = "stories"
            i += 1
            continue

        # open-questions sub-headings, attributed by heading depth / context
        if re.match(r"^#{3,5}\s+Open questions\s*$", stripped):
            hashes = len(stripped) - len(stripped.lstrip("#"))
            if hashes == 5 and ac is not None:
                oq_target = ("ac", story, ac)
            elif hashes == 4 and story is not None:
                oq_target = ("story", story)
            elif section == "problem":
                oq_target = "problem_oq"
            elif section == "scope":
                oq_target = "scope_oq"
            i += 1
            continue

        # open-question items
        m = re.match(r"^- \[ \]\s*(.*)$", line)
        if m:
            q = m.group(1)
            if oq_target == "problem_oq":
                spec["problem_oq"].append(q)
            elif oq_target == "scope_oq":
                spec["scope_oq"].append(q)
            elif isinstance(oq_target, tuple) and oq_target[0] == "story":
                story["open_questions"].append(q)
            elif isinstance(oq_target, tuple) and oq_target[0] == "ac":
                ac["open_questions"].append(q)
            i += 1
            continue

        if section == "scope":
            if stripped.startswith("**In scope"):
                scope_bucket = "in"
                i += 1
                continue
            if stripped.startswith("**Out of scope"):
                scope_bucket = "out"
                i += 1
                continue
            m = re.match(r"^- (.*)$", line)
            if m and scope_bucket == "in":
                spec["scope_in"].append(m.group(1))
                i += 1
                continue
            if m and scope_bucket == "out":
                spec["scope_out"].append(m.group(1))
                i += 1
                continue

        if section == "problem" and stripped and not stripped.startswith("#"):
            spec["problem"].append(stripped)
            i += 1
            continue

        # stories
        m = re.match(r"^### \[(U\d+)\]:\s*(.*)$", line)
        if m:
            story = {"id": m.group(1), "title": m.group(2), "text": "",
                     "acs": [], "open_questions": []}
            spec["stories"].append(story)
            ac = tc = None
            oq_target = ("story", story)
            i += 1
            continue

        m = re.match(r"^#### \[(AC\d+)\]:\s*(.*)$", line)
        if m and story is not None:
            ac = {"id": m.group(1), "title": m.group(2), "ears": "",
                  "tests": [], "open_questions": []}
            story["acs"].append(ac)
            tc = None
            oq_target = ("ac", story, ac)
            i += 1
            continue

        # test case header
        m = re.match(r"^\*\*\[(TC\d+)\]:\s*(.*?)\s*—\s*([^:]+):\*\*\s*$", line)
        if m and ac is not None:
            tc = {"id": m.group(1), "title": m.group(2).strip(),
                  "category": m.group(3).strip(),
                  "preconditions": "", "steps": [], "expected": "", "open_questions": ""}
            ac["tests"].append(tc)
            i += 1
            continue

        if tc is not None:
            m = re.match(r"^- \*Preconditions:\*\s*(.*)$", line)
            if m:
                tc["preconditions"] = m.group(1)
                i += 1
                continue
            m = re.match(r"^- \*Steps:\*\s*(.*)$", line)
            if m:
                tc["steps"] = split_steps(m.group(1))
                i += 1
                continue
            m = re.match(r"^- \*Expected result:\*\s*(.*)$", line)
            if m:
                tc["expected"] = m.group(1)
                i += 1
                continue
            m = re.match(r"^- \*Open questions:\*\s*(.*)$", line)
            if m:
                tc["open_questions"] = m.group(1)
                i += 1
                continue

        # story narrative ("As a ...")
        if story is not None and ac is None and stripped and not stripped.startswith(("#", "-", "*", "|")):
            story["text"] = (story["text"] + " " + stripped).strip()
            i += 1
            continue

        # AC EARS statement
        if ac is not None and tc is None and stripped and not stripped.startswith(("#", "-", "*", "|")):
            ac["ears"] = (ac["ears"] + " " + stripped).strip()
            i += 1
            continue

        i += 1

    return spec


# --------------------------------------------------------------------------- #
# Renderer
# --------------------------------------------------------------------------- #
CSS = """
:root{
  --bg:#f0f1f5;--card:#fff;--ink:#1a1f36;--muted:#6b7280;--line:#e5e7eb;
  --accent:#1d4ed8;--accent2:#6d28d9;
  --hdr-from:#0d0b2e;--hdr-to:#1e1356;
  --oq:#6d28d9;--oq-bg:#f5f3ff;
  --story-bar:#1d4ed8;
}
*{box-sizing:border-box}
body{margin:0;font:15px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
color:var(--ink);background:var(--bg)}
.wrap{max-width:1000px;margin:0 auto;padding:0 0 32px}

/* ── Sticky header ── */
header.spec{
  position:sticky;top:0;z-index:10;
  background:linear-gradient(135deg,var(--hdr-from) 0%,var(--hdr-to) 60%,#2d1b6e 100%);
  padding:20px 28px 16px;margin-bottom:24px;
  box-shadow:0 4px 24px rgba(0,0,0,.35)}
header.spec h1{margin:0 0 6px;font-size:21px;font-weight:700;color:#fff;letter-spacing:-.01em}
.meta{display:flex;flex-wrap:wrap;gap:6px 20px;font-size:12.5px;color:rgba(255,255,255,.65)}
.meta b{color:rgba(255,255,255,.9);font-weight:600}
.header-row{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-top:14px}
.counts{display:flex;flex-wrap:wrap;gap:7px;flex:1}
.pill{background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.2);
border-radius:999px;padding:3px 11px;font-size:12px;color:#fff;font-weight:500}
.pill-oq{background:rgba(139,92,246,.35);border-color:rgba(196,167,255,.45);color:#ede9fe}
.expand-btns{display:flex;gap:6px;flex-shrink:0}
.expand-btns button{
  font:inherit;font-size:12.5px;font-weight:500;padding:5px 14px;
  border:1px solid rgba(255,255,255,.3);background:rgba(255,255,255,.1);
  border-radius:8px;cursor:pointer;color:#fff;white-space:nowrap;
  transition:background .15s,border-color .15s}
.expand-btns button:hover{background:rgba(255,255,255,.2);border-color:rgba(255,255,255,.5)}

/* ── Content ── */
.content{padding:0 28px}
section.block{background:var(--card);border:1px solid var(--line);border-radius:12px;
padding:20px 24px;margin-bottom:16px;box-shadow:0 1px 3px rgba(0,0,0,.04)}
section.block h2{margin:0;font-size:15px;font-weight:700;color:var(--ink);letter-spacing:-.01em}
.section-head{display:flex;align-items:baseline;gap:10px;margin-bottom:14px}
.problem p{margin:0 0 10px;line-height:1.65}
.scope{display:grid;grid-template-columns:1fr 1fr;gap:20px}
@media(max-width:680px){.scope{grid-template-columns:1fr}}
.scope h3{margin:0 0 10px;font-size:13px;font-weight:700;text-transform:uppercase;
letter-spacing:.05em;color:var(--muted)}
.scope ul{margin:0;padding-left:18px}.scope li{margin:5px 0;line-height:1.5}

/* ── User stories ── */
.story{background:var(--card);border:1px solid var(--line);border-radius:12px;
margin-bottom:12px;box-shadow:0 1px 3px rgba(0,0,0,.04)}
.story>summary{list-style:none;cursor:pointer;padding:14px 20px;
display:flex;gap:10px;align-items:center;
border-left:4px solid var(--story-bar);border-radius:12px}
.story>summary::-webkit-details-marker{display:none}
.story>summary:hover{background:#f9fafb}
.story[open]>summary{border-left-color:var(--accent2);border-radius:12px 12px 0 0}
.id{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:11.5px;font-weight:700;
color:#fff;background:var(--accent);border-radius:6px;padding:2px 9px;white-space:nowrap;flex-shrink:0}
.story>summary .title{font-weight:600;font-size:15.5px;flex:1}
.sub{color:var(--muted);font-size:12.5px;font-weight:400;white-space:nowrap}
.story .body{padding:0 20px 18px 24px;border-top:1px solid var(--line)}
.as-a{margin:16px 0 18px;font-style:italic;line-height:1.6;
background:linear-gradient(135deg,#eef2ff,#f5f3ff);
border-left:3px solid var(--accent2);padding:12px 16px;border-radius:0 10px 10px 0;color:#1e1b4b}

/* ── ACs ── */
.ac{border:1px solid var(--line);border-radius:10px;margin:10px 0}
.ac>summary{list-style:none;cursor:pointer;padding:10px 16px;
display:flex;gap:9px;align-items:center;background:#fafafa;border-radius:10px}
.ac>summary::-webkit-details-marker{display:none}
.ac>summary:hover{background:#f3f4f6}
.ac[open]>summary{border-radius:10px 10px 0 0}
.id.ac-id{background:#374151;font-size:11px}
.ac>summary .title{font-size:14px;font-weight:600;flex:1}
.ac .ears{padding:11px 16px;border-top:1px solid var(--line);
font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:12.5px;
background:#f8fafc;color:#1e3a5f;line-height:1.6}
.tests{padding:6px 14px 12px}

/* ── Test cases ── */
.tc{border:1px solid var(--line);border-radius:9px;margin:9px 0;padding:11px 14px;background:#fff}
.tc .tc-head{display:flex;gap:8px;align-items:center;flex-wrap:wrap;margin-bottom:8px}
.tc .tc-title{font-weight:600;font-size:13.5px;flex:1}
.badge{font-size:11px;font-weight:700;border-radius:999px;padding:2px 9px;white-space:nowrap;flex-shrink:0}
.cat-happy{background:#dcfce7;color:#15803d}
.cat-neg{background:#fee2e2;color:#b91c1c}
.cat-state{background:#dbeafe;color:#1d4ed8}
.cat-sec{background:#ede9fe;color:#6d28d9}
.cat-audit{background:#ccfbf1;color:#0f766e}
.tc dl{margin:0;display:grid;grid-template-columns:auto 1fr;gap:4px 14px;font-size:13.5px}
.tc dt{color:var(--muted);font-weight:600;white-space:nowrap;padding-top:1px}
.tc dd{margin:0;line-height:1.55}
.tc ol{margin:0;padding-left:18px}
.tc ol li{margin:3px 0}

/* ── Open questions ── */
.oq{margin:12px 0 4px;background:var(--oq-bg);border:1px solid #ddd6fe;border-radius:9px;padding:10px 14px}
.oq h4{margin:0 0 7px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:var(--oq)}
.oq ul{margin:0;padding-left:18px}.oq li{margin:4px 0;line-height:1.5}
code{background:#f1f5f9;border-radius:4px;padding:1px 5px;font-size:.88em;color:#334155}
footer{color:var(--muted);font-size:12px;text-align:center;padding:20px 0 8px}
"""

JS = """
function setAll(open){document.querySelectorAll('details').forEach(function(d){d.open=open});}
"""


def render_tc(tc):
    cls = CATEGORY_CLASS.get(tc["category"], "cat-state")
    steps = "".join("<li>%s</li>" % inline(s) for s in tc["steps"])
    flags = '<span class="sub"><span style="color:#a78bfa">1 open question</span></span>' if tc["open_questions"] else ""
    oq_row = '<dt>Open question</dt><dd><span style="color:#6d28d9">%s</span></dd>' % inline(tc["open_questions"]) if tc["open_questions"] else ""
    return (
        '<div class="tc"><div class="tc-head">'
        '<span class="id">%s</span>'
        '<span class="tc-title">%s</span>'
        '<span class="badge %s">%s</span>%s</div>'
        "<dl>"
        "<dt>Preconditions</dt><dd>%s</dd>"
        "<dt>Steps</dt><dd><ol>%s</ol></dd>"
        "<dt>Expected</dt><dd>%s</dd>"
        "%s"
        "</dl></div>"
    ) % (tc["id"], inline(tc["title"]), cls, html.escape(tc["category"]), flags,
         inline(tc["preconditions"]), steps, inline(tc["expected"]), oq_row)


def section_badges(n_oq):
    if not n_oq:
        return ""
    return ' <span class="sub"><span style="color:#a78bfa">%d open question%s</span></span>' % (n_oq, "s" if n_oq != 1 else "")


def render_oq(items, label):
    if not items:
        return ""
    lis = "".join("<li>%s</li>" % inline(q) for q in items)
    return '<div class="oq"><h4>%s</h4><ul>%s</ul></div>' % (label, lis)


def render_ac(ac):
    tests = "".join(render_tc(t) for t in ac["tests"])
    oq = render_oq(ac["open_questions"], "Open questions (AC)")
    tests_block = ('<div class="tests">%s%s</div>' % (tests, oq)) if (tests or oq) else ""
    ntests = len(ac["tests"])
    noq = len(ac["open_questions"]) + sum(1 for t in ac["tests"] if t["open_questions"])
    oq_part = ' · <span style="color:#a78bfa">%d open question%s</span>' % (noq, "s" if noq != 1 else "") if noq else ""
    ac_sub = '<span class="sub">%d test%s%s</span>' % (ntests, "s" if ntests != 1 else "", oq_part) if (ntests or noq) else ""
    return (
        '<details class="ac" open><summary>'
        '<span class="id ac-id">%s</span><span class="title">%s</span>%s</summary>'
        '<div class="ears">%s</div>%s</details>'
    ) % (ac["id"], inline(ac["title"]), ac_sub, inline(ac["ears"]), tests_block)


def render_story(s):
    acs = "".join(render_ac(a) for a in s["acs"])
    oq = render_oq(s["open_questions"], "Open questions (user story)")
    as_a = ('<div class="as-a">%s</div>' % inline(s["text"])) if s["text"] else ""
    n_oq = sum(len(a["open_questions"]) for a in s["acs"]) + len(s["open_questions"])
    oq_part = ' · <span style="color:#a78bfa">%d open question%s</span>' % (n_oq, "s" if n_oq != 1 else "") if n_oq else ""
    sub = '<span class="sub">%d acceptance criteria%s</span>' % (len(s["acs"]), oq_part)
    return (
        '<details class="story" open><summary>'
        '<span class="id">%s</span><span class="title">%s</span>%s</summary>'
        '<div class="body">%s%s%s</div></details>'
    ) % (s["id"], inline(s["title"]), sub, as_a, acs, oq)


def render(spec):
    meta = spec["meta"]
    feature = meta.get("Feature name", meta.get("Feature", "Specification"))
    meta_html = " ".join(
        '<span><b>%s:</b> %s</span>' % (html.escape(k), inline(v))
        for k, v in meta.items() if k not in ("Feature name", "Feature", "Open questions")
    )
    n_stories = len(spec["stories"])
    n_acs = sum(len(s["acs"]) for s in spec["stories"])
    n_tests = sum(len(a["tests"]) for s in spec["stories"] for a in s["acs"])
    n_oq_total = (len(spec["problem_oq"]) + len(spec["scope_oq"])
                  + sum(len(s["open_questions"]) + sum(len(a["open_questions"]) for a in s["acs"])
                        for s in spec["stories"]))
    counts = (
        '<span class="pill">%d user stories</span>'
        '<span class="pill">%d acceptance criteria</span>'
        '<span class="pill">%d test cases</span>'
        '<span class="pill pill-oq">%d open question%s</span>'
    ) % (n_stories, n_acs, n_tests, n_oq_total, "s" if n_oq_total != 1 else "")
    # Problem statement counts
    prob_oq = len(spec["problem_oq"])
    prob_badges = section_badges(prob_oq)
    problem = "".join("<p>%s</p>" % inline(p) for p in spec["problem"])
    problem += render_oq(spec["problem_oq"], "Open questions")

    # Scope counts
    scope_oq_n = len(spec["scope_oq"])
    scope_badges = section_badges(scope_oq_n)
    scope_in = "".join("<li>%s</li>" % inline(x) for x in spec["scope_in"])
    scope_out = "".join("<li>%s</li>" % inline(x) for x in spec["scope_out"])
    scope_oq = render_oq(spec["scope_oq"], "Open questions")
    stories = "".join(render_story(s) for s in spec["stories"])
    stories_section = (
        '<section class="block" style="background:none;border:none;padding:0;box-shadow:none">'
        "<h2>User stories</h2>%s</section>" % stories
    ) if spec["stories"] else ""

    return """<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>%s</title><style>%s</style></head><body><div class="wrap">
<header class="spec"><h1>%s</h1><div class="meta">%s</div>
<div class="header-row"><div class="counts">%s</div>
<div class="expand-btns"><button onclick="setAll(true)">Expand all</button>
<button onclick="setAll(false)">Collapse all</button></div></div></header>
<div class="content">
<section class="block problem"><div class="section-head"><h2>Problem statement</h2><span style="flex:1"></span>%s</div>%s</section>
<section class="block"><div class="section-head"><h2>Scope</h2><span style="flex:1"></span>%s</div><div class="scope">
<div><h3>In scope</h3><ul>%s</ul></div>
<div><h3>Out of scope</h3><ul>%s</ul></div></div>%s</section>
%s
<footer>Generated from the specification markdown · specification-to-html</footer>
</div></div><script>%s</script></body></html>""" % (
        html.escape(feature), CSS, html.escape(feature), meta_html, counts,
        prob_badges, problem, scope_badges, scope_in, scope_out, scope_oq, stories_section, JS)


# --------------------------------------------------------------------------- #
def main():
    ap = argparse.ArgumentParser(description="Render a spec markdown file to HTML.")
    ap.add_argument("inputs", nargs="+", help="spec markdown file(s)")
    ap.add_argument("-o", "--output", help="output HTML path (single input only)")
    args = ap.parse_args()

    if args.output and len(args.inputs) > 1:
        ap.error("-o/--output can only be used with a single input file")

    for path in args.inputs:
        with open(path, encoding="utf-8") as fh:
            spec = parse(fh.read())
        out = args.output or os.path.splitext(path)[0] + ".html"
        with open(out, "w", encoding="utf-8") as fh:
            fh.write(render(spec))
        s = len(spec["stories"])
        a = sum(len(x["acs"]) for x in spec["stories"])
        t = sum(len(ac["tests"]) for x in spec["stories"] for ac in x["acs"])
        print("wrote %s  (%d stories, %d ACs, %d tests)" % (out, s, a, t))


if __name__ == "__main__":
    main()
