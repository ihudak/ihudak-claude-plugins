#!/usr/bin/env python3
"""session-cost.py — compute the token-cost delta for one dev-workflows command.

Pure computation, Python standard library only (json, argparse, glob, os,
datetime). Given a chained checkpoint (or none) it reads the current session's
main transcript from a line offset forward plus the session's subagent
transcripts within a timestamp window, accumulates token usage per model,
applies a price table (USD per MILLION tokens), and prints a structured JSON
result to stdout. It NEVER writes the specs repo and NEVER writes the checkpoint
back — the caller (references/cost-emission.md) persists ``new_checkpoint``.

Claude Code stores no dollar figure in the transcript; every assistant message
carries ``.message.usage`` + ``.message.model``, so cost is computed, not read.
"""

import argparse
import datetime
import glob
import json
import os
import sys

TOKEN_KEYS = ("input", "output", "cache_read", "cache_write_5m", "cache_write_1h")


def _num(v):
    """Coerce a token count to a number; None/absent/non-numeric -> 0."""
    return v if isinstance(v, (int, float)) else 0


def _blank():
    return {k: 0 for k in TOKEN_KEYS}


def parse_ts(s):
    """Parse an ISO8601 timestamp to a UTC-aware datetime, or None on failure.

    Handles a trailing 'Z' and over-long fractional seconds without ``re``
    (fromisoformat before 3.11 rejects >6 fractional digits and a 'Z')."""
    if not s or not isinstance(s, str):
        return None
    t = s.strip().replace("Z", "+00:00")
    if "." in t:
        head, frac = t.split(".", 1)
        tz = ""
        for sign in ("+", "-"):
            idx = frac.find(sign)
            if idx != -1:
                tz, frac = frac[idx:], frac[:idx]
                break
        t = head + "." + frac[:6] + tz
    try:
        dt = datetime.datetime.fromisoformat(t)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=datetime.timezone.utc)
    return dt


def iso_z(dt):
    """Format a datetime as ISO8601 UTC with a 'Z' suffix (whole seconds)."""
    return dt.astimezone(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _parse_scalar(s):
    s = s.strip()
    if s == "" or s.lower() in ("null", "~"):
        return None
    try:
        return float(s) if ("." in s or "e" in s.lower()) else int(s)
    except ValueError:
        return s.strip('"').strip("'")


def load_prices(path):
    """Minimal indentation-based YAML reader for the fixed cost-prices.yaml
    structure (nested mappings, scalar leaves, inline '#' comments). Standard
    library only -- NOT a general YAML parser, but sufficient for the shipped
    price file, so PyYAML is not a dependency."""
    root = {}
    stack = [(-1, root)]
    if not path or not os.path.isfile(path):
        return root
    with open(path, encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            line = raw.split("#", 1)[0].rstrip()
            if not line.strip():
                continue
            indent = len(line) - len(line.lstrip(" "))
            key, _, val = line.strip().partition(":")
            key, val = key.strip(), val.strip()
            while stack and stack[-1][0] >= indent:
                stack.pop()
            parent = stack[-1][1]
            if val == "":
                child = {}
                parent[key] = child
                stack.append((indent, child))
            else:
                parent[key] = _parse_scalar(val)
    return root


def extract_usage(obj):
    """Return (model, usage) for an assistant message with usage, else (None, None)."""
    msg = obj.get("message") if isinstance(obj, dict) else None
    if not isinstance(msg, dict):
        return None, None
    usage = msg.get("usage")
    if not isinstance(usage, dict):
        return None, None
    return (msg.get("model") or "unknown"), usage


def add_usage(acc, model, usage):
    """Accumulate one assistant message's token usage into acc[model]."""
    m = acc.setdefault(model, _blank())
    m["input"] += _num(usage.get("input_tokens"))
    m["output"] += _num(usage.get("output_tokens"))
    m["cache_read"] += _num(usage.get("cache_read_input_tokens"))
    cc = usage.get("cache_creation")
    if isinstance(cc, dict) and (
        cc.get("ephemeral_5m_input_tokens") is not None
        or cc.get("ephemeral_1h_input_tokens") is not None
    ):
        m["cache_write_5m"] += _num(cc.get("ephemeral_5m_input_tokens"))
        m["cache_write_1h"] += _num(cc.get("ephemeral_1h_input_tokens"))
    else:
        # No 5m/1h split available -> price all cache-creation at the 5m rate.
        m["cache_write_5m"] += _num(usage.get("cache_creation_input_tokens"))


MARKER_OPEN = "<command-name>"
MARKER_CLOSE = "</command-name>"
# Claude Code writes a slash-command invocation in one of TWO envelope orders,
# and the difference is not cosmetic -- it decides whether this plugin's own
# commands are visible at all:
#   built-ins        <command-name>/compact</command-name><command-message>...
#   plugin-provided  <command-message>foo:bar</command-message><command-name>/foo:bar</command-name>...
# Verified over every transcript on the machine this was written on: 79 built-in
# invocations, all name-first; every plugin-provided invocation message-first.
# An implementation anchored on <command-name> alone therefore sees ZERO plugin
# commands and the whole feature is inert -- which is exactly how it first
# shipped here. Anchoring on EITHER opener keeps the property that matters (the
# envelope must START the message, so a marker quoted inside prose or a pasted
# file is not an invocation) while admitting both real shapes.
MARKER_MSG = "<command-message>"


def load_command_names(commands_dir):
    """This plugin's command names and its own namespace, read off the shipped
    commands/ dir.

    Returns (names, plugin_name) -- bare names ("implement") plus the directory
    the commands live under, which IS the namespace a user may type
    ("dev-workflows:implement"). (None, None) when no directory was supplied,
    which disables boundary detection entirely rather than guessing."""
    if not commands_dir or not os.path.isdir(commands_dir):
        return None, None
    names = set()
    for fp in glob.glob(os.path.join(commands_dir, "*.md")):
        base = os.path.basename(fp)[:-3]
        if base:
            names.add(base)
    if not names:
        return None, None
    # The namespace is the plugin's declared name. It is NOT the parent directory:
    # installed content lives at <cache>/<marketplace>/<plugin>/<version>/, so the
    # parent of commands/ is the VERSION there and only the plugin name in a dev
    # tree. plugin.json is authoritative in both.
    root = os.path.dirname(os.path.abspath(commands_dir))
    plugin_name = None
    try:
        with open(os.path.join(root, ".claude-plugin", "plugin.json"),
                  encoding="utf-8", errors="replace") as fh:
            plugin_name = (json.load(fh) or {}).get("name") or None
    except (OSError, ValueError, TypeError, AttributeError):
        plugin_name = None
    if not plugin_name:
        plugin_name = os.path.basename(root)
    return names, plugin_name


def command_marker(obj, known, plugin_name=None):
    """The command name if obj is a transcript record for a slash-command
    invocation of a KNOWN plugin command, else None.

    Two disciplines, both deliberate. The marker must START the message content:
    the same `<command-name>` text appears inside quoted file content elsewhere in
    a transcript, and an unanchored search matches that too. And the name is
    RESOLVED against the known set, never parsed -- a marker records what the user
    typed, which may be bare (`/implement`) or namespaced
    (`/dev-workflows:implement`), and only the set can say which reading is real.
    An unknown name (`/compact`, `/login`, another plugin's command) returns None,
    so it never becomes a cost boundary."""
    if not isinstance(obj, dict) or obj.get("type") != "user":
        return None
    msg = obj.get("message")
    if not isinstance(msg, dict):
        return None
    content = msg.get("content")
    if isinstance(content, str):
        text = content
    elif isinstance(content, list):
        text = "".join(
            c.get("text", "") for c in content
            if isinstance(c, dict) and c.get("type") == "text"
        )
    else:
        return None
    text = text.lstrip()
    if not (text.startswith(MARKER_OPEN) or text.startswith(MARKER_MSG)):
        return None
    at = text.find(MARKER_OPEN)
    if at < 0:
        return None
    rest = text[at + len(MARKER_OPEN):]
    end = rest.find(MARKER_CLOSE)
    if end < 0:
        return None
    raw = rest[:end].strip()
    # The leading-slash test and the [1:] that follows it are deliberately
    # coupled: the check rejects a <command-name> whose content is not a slash
    # command, and the offset assumes it passed. Removing the check alone is not
    # independently observable -- [1:] then eats the first real character and the
    # name matches nothing -- so no selftest case asserts it. Keep them together.
    if not raw.startswith("/"):
        return None
    typed = raw[1:].strip()
    if not typed or known is None:
        return None
    if typed in known:
        return typed
    # A namespace is RESOLVED, never discarded. Stripping it would read another
    # installed plugin's `/superpowers:implement` as this plugin's `/implement`
    # and invent a boundary under a name this plugin never ran.
    if ":" in typed:
        ns, rest = typed.split(":", 1)
        if plugin_name and ns == plugin_name and rest in known:
            return rest
    return None


def scan_main(path, line_offset, known_commands, plugin_name=None):
    """Single pass over main-transcript lines [line_offset, EOF).

    Buffers each usage record with its timestamp instead of accumulating
    immediately, so the window can be cut into segments afterwards without
    re-reading. Returns (new_total_line_count, earliest_ts, boundaries, records)
    where records is a list of (ts, model, usage)."""
    count = line_offset
    first_ts = None
    boundaries = []
    records = []
    if not path or not os.path.isfile(path):
        return count, first_ts, boundaries, records
    try:
        fh_main = open(path, encoding="utf-8", errors="replace")
    except OSError:
        return count, first_ts, boundaries, records
    with fh_main as fh:
        for i, raw in enumerate(fh):
            count = i + 1
            if i < line_offset:
                continue
            raw = raw.strip()
            if not raw:
                continue
            try:
                obj = json.loads(raw)
            except (ValueError, TypeError):
                continue
            ts = parse_ts(obj.get("timestamp") if isinstance(obj, dict) else None)
            name = command_marker(obj, known_commands, plugin_name)
            if name is not None and ts is not None:
                # The raw stamp is kept, not iso_z's whole-second form: segment
                # edges are compared against record timestamps, and flooring the
                # edge moves up to a second of one run's records into another's.
                # A marker with no usable timestamp is not a boundary -- there is
                # nothing to cut the window at, and iso_z(None) used to raise here
                # and fail a run whose contract is that it never does.
                boundaries.append(
                    {"command": "/" + name,
                     "ts": obj.get("timestamp"),
                     "line_offset": i}
                )
            if ts is not None and (first_ts is None or ts < first_ts):
                first_ts = ts
            model, usage = extract_usage(obj)
            if usage is not None:
                records.append((ts, model, usage))
    return count, first_ts, boundaries, records


def read_subagents(subdir, last_dt, now_dt, records):
    """Buffer usage from subagents/agent-*.jsonl entries whose timestamp is in
    (last_dt, now_dt]  (all <= now_dt when last_dt is None), appending
    (ts, model, usage) to records so they are segmented exactly as the main
    transcript's are -- the two must agree at a boundary or a subagent's tokens
    land in both slices or neither.

    Returns the earliest in-window entry timestamp, or None."""
    first_ts = None
    if not subdir or not os.path.isdir(subdir):
        return first_ts
    for fp in sorted(glob.glob(os.path.join(subdir, "agent-*.jsonl"))):
        try:
            fh = open(fp, encoding="utf-8", errors="replace")
        except OSError:
            continue
        with fh:
            for raw in fh:
                raw = raw.strip()
                if not raw:
                    continue
                try:
                    obj = json.loads(raw)
                except (ValueError, TypeError):
                    continue
                ts = parse_ts(obj.get("timestamp") if isinstance(obj, dict) else None)
                if ts is None:
                    continue
                if now_dt is not None and ts > now_dt:
                    continue
                if last_dt is not None and ts <= last_dt:
                    continue
                model, usage = extract_usage(obj)
                if usage is not None:
                    records.append((ts, model, usage))
                    if first_ts is None or ts < first_ts:
                        first_ts = ts
    return first_ts


def _rate(rates, key):
    v = rates.get(key)
    return float(v) if isinstance(v, (int, float)) else 0.0


def price_model(model, tok, prices):
    """Return (cost_usd or None, note or None). Rates are USD per MILLION tokens."""
    table = prices.get("models") if isinstance(prices.get("models"), dict) else {}
    rates = table.get(model)
    if not isinstance(rates, dict):
        # Exact miss -> longest table key that is a prefix of the model id
        # (so undated key "claude-sonnet-5" prices "claude-sonnet-5-20250930").
        best = None
        for k, v in table.items():
            if isinstance(v, dict) and isinstance(model, str) and model.startswith(k):
                if best is None or len(k) > len(best):
                    best = k
        rates = table.get(best) if best is not None else None
    if not isinstance(rates, dict):
        return None, "unpriced-model"
    cost = (
        tok["input"] * _rate(rates, "input")
        + tok["output"] * _rate(rates, "output")
        + tok["cache_read"] * _rate(rates, "cache_read")
        + tok["cache_write_5m"] * _rate(rates, "cache_write_5m")
        + tok["cache_write_1h"] * _rate(rates, "cache_write_1h")
    )
    return round(cost / 1_000_000.0, 4), None


def read_snapshot_cost(path):
    """Return the latest cost_usd from the statusline snapshot file, or None.

    Accepts a single JSON object or JSONL (last parseable line with cost_usd)."""
    if not path or not os.path.isfile(path):
        return None
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            data = fh.read()
    except OSError:
        return None
    try:
        obj = json.loads(data)
        if isinstance(obj, dict) and isinstance(obj.get("cost_usd"), (int, float)):
            return float(obj["cost_usd"])
    except ValueError:
        pass
    for raw in reversed(data.splitlines()):
        raw = raw.strip()
        if not raw:
            continue
        try:
            obj = json.loads(raw)
        except ValueError:
            continue
        if isinstance(obj, dict) and isinstance(obj.get("cost_usd"), (int, float)):
            return float(obj["cost_usd"])
    return None



# --------------------------------------------------------------------------
# Selftest
#
# The window split (section 13 of cost-emission.md) is the one part of this
# script whose failure is silent: a boundary that is missed or invented still
# produces a plausible number, in the wrong bucket. So each case below is
# paired with the broken implementation it exists to catch, and the fixture
# was checked against those: an UNANCHORED marker match (one that accepts the
# marker text anywhere in a message rather than only at its start) and a
# match that skips the known-command set both report 3 boundaries where the
# correct implementation reports 2. A fixture that cannot tell those apart
# would pass for the wrong reason, which is the whole failure mode here.
# --------------------------------------------------------------------------

SELFTEST_PRICES = """models:
  claude-opus-5:
    input: 5
    output: 25
    cache_read: 0.5
    cache_write_5m: 6.25
    cache_write_1h: 10
default: null
"""


def _st_rows():
    """A window shaped like the ones that actually broke this feature.

    Three traps, each pinned to a real defect: a plugin command written in the
    MESSAGE-FIRST envelope Claude Code really emits (anchoring on <command-name>
    alone made the feature inert); a `/vuln` boundary between the ceding run and
    the replaying one (positional pairing filed /vuln's spend under the grill's
    PRD labels); and a FOREIGN namespace over a shared bare name (discarding the
    namespace invented a boundary this plugin never ran)."""
    def asst(ts, out):
        return {"type": "assistant", "timestamp": ts,
                "message": {"role": "assistant", "model": "claude-opus-5",
                            "usage": {"input_tokens": 0, "output_tokens": out,
                                      "cache_read_input_tokens": 0,
                                      "cache_creation_input_tokens": 0}}}

    def builtin(ts, name):          # built-ins are name-first
        return {"type": "user", "timestamp": ts,
                "message": {"role": "user", "content":
                            MARKER_OPEN + name + MARKER_CLOSE +
                            "\n  <command-message>x</command-message>"}}

    def plugin_cmd(ts, name, as_blocks=False):   # plugin commands are message-first
        body = (MARKER_MSG + name.lstrip("/") + "</command-message>\n"
                + MARKER_OPEN + name + MARKER_CLOSE + "\n<command-args></command-args>")
        content = ([{"type": "text", "text": body}] if as_blocks else body)
        rec = {"type": "user", "message": {"role": "user", "content": content}}
        if ts:
            rec["timestamp"] = ts
        return rec

    return [
        asst("2026-09-01T10:00:00.000Z", 1000),                     # 0 prior work
        builtin("2026-09-01T10:01:00.000Z", "/compact"),            # 1 not this plugin
        plugin_cmd("2026-09-01T10:02:00.000Z", "/dev-workflows:vuln"),        # 2 emits no cost
        asst("2026-09-01T10:03:00.000Z", 4000),                     # 3 /vuln's spend
        plugin_cmd("2026-09-01T10:04:00.000Z", "/dev-workflows:prompt-grill-me"),  # 4 ceding
        asst("2026-09-01T10:05:00.000Z", 2000),                     # 5 the grill
        {"type": "user", "timestamp": "2026-09-01T10:06:00.000Z",   # 6 marker quoted
         "message": {"role": "user",                                #   mid-content
                     "content": "a doc quoting " + MARKER_OPEN +
                                "/implement" + MARKER_CLOSE + " inline"}},
        plugin_cmd("2026-09-01T10:07:00.000Z", "/superpowers:implement"),     # 7 FOREIGN
        plugin_cmd(None, "/dev-workflows:specify"),                 # 8 no timestamp
        asst("2026-09-01T10:08:00.000Z", 1000),                     # 9 still the grill
        plugin_cmd("2026-09-01T10:09:00.000Z", "/dev-workflows:implement", True),  # 10 blocks
        asst("2026-09-01T10:10:00.000Z", 3000),                     # 11 replaying run
        # 12 the envelope is preceded by whitespace -- still an invocation.
        {"type": "user", "timestamp": "2026-09-01T10:10:30.000Z",
         "message": {"role": "user", "content":
                     "\n   " + MARKER_MSG + "dev-workflows:specify</command-message>\n"
                     + MARKER_OPEN + "/dev-workflows:specify" + MARKER_CLOSE}},
        # 13 a name with no leading slash is not an invocation.
        {"type": "user", "timestamp": "2026-09-01T10:10:40.000Z",
         "message": {"role": "user", "content":
                     MARKER_OPEN + "implement" + MARKER_CLOSE}},
    ]


def selftest():
    import subprocess
    import tempfile

    failures = []

    def bad(msg):
        failures.append(msg)
        print("FAIL  " + msg)

    def check(cond, msg):
        print("ok    " + msg) if cond else bad(msg)

    tmp = tempfile.mkdtemp(prefix="session-cost-selftest-")
    tpath = os.path.join(tmp, "t.jsonl")
    with open(tpath, "w", encoding="utf-8") as fh:
        for r in _st_rows():
            fh.write(json.dumps(r) + "\n")
    ppath = os.path.join(tmp, "prices.yaml")
    with open(ppath, "w", encoding="utf-8") as fh:
        fh.write(SELFTEST_PRICES)
    # commands/ must sit beside a .claude-plugin/plugin.json: the declared name is
    # the namespace a marker carries.
    proot = os.path.join(tmp, "plugin-root")
    cdir = os.path.join(proot, "commands")
    os.makedirs(cdir)
    os.makedirs(os.path.join(proot, ".claude-plugin"))
    with open(os.path.join(proot, ".claude-plugin", "plugin.json"), "w",
              encoding="utf-8") as fh:
        json.dump({"name": "dev-workflows", "version": "0.0.0"}, fh)
    for n in ("implement", "prompt-grill-me", "prompt-brainstorm", "vuln", "specify"):
        with open(os.path.join(cdir, n + ".md"), "w", encoding="utf-8") as fh:
            fh.write("x\n")
    # Subagent spend must be segmented exactly as the main transcript's is.
    sdir = os.path.join(tmp, "subagents")
    os.makedirs(sdir)
    with open(os.path.join(sdir, "agent-1.jsonl"), "w", encoding="utf-8") as fh:
        for ts, out in (("2026-09-01T10:05:30.000Z", 400),      # inside the grill
                        ("2026-09-01T10:10:30.000Z", 600)):     # inside this run
            fh.write(json.dumps({"timestamp": ts, "message": {
                "role": "assistant", "model": "claude-opus-5",
                "usage": {"input_tokens": 0, "output_tokens": out,
                          "cache_read_input_tokens": 0,
                          "cache_creation_input_tokens": 0}}}) + "\n")
    snap = os.path.join(tmp, "snap.json")
    with open(snap, "w", encoding="utf-8") as fh:
        json.dump({"ts": "2026-09-01T10:11:00Z", "cost_usd": 9.9}, fh)
    ckpt = os.path.join(tmp, "ck.json")
    with open(ckpt, "w", encoding="utf-8") as fh:
        json.dump({"line_offset": 0, "last_ts": None, "last_snapshot_cost": 9.0}, fh)

    def run(*extra):
        cmd = [sys.executable, os.path.abspath(__file__),
               "--transcript", tpath, "--prices", ppath,
               "--subagents-dir", sdir, "--commands-dir", cdir,
               "--snapshot", snap, "--checkpoint", ckpt,
               "--now-ts", "2026-09-01T10:11:00.000Z"] + list(extra)
        out = subprocess.run(cmd, capture_output=True, text=True)
        if out.returncode != 0:
            bad("run failed: " + " ".join(extra) + " -> " + out.stderr.strip()[:200])
            return None
        return json.loads(out.stdout)

    whole = run()
    if whole is None:
        print("SELFTEST FAIL"); return 1
    names = [b["command"] for b in whole["command_boundaries"]]
    check(names == ["/vuln", "/prompt-grill-me", "/implement", "/specify"],
          "the four plugin invocations are boundaries, in order (got %r)" % (names,))
    check(names.count("/specify") == 1,
          "an envelope preceded by whitespace is still an invocation")
    check("/prompt-grill-me" in names,
          "a MESSAGE-FIRST envelope is recognised (the real plugin-command shape)")
    check("/compact" not in names,
          "/compact is not a boundary -- it is not one of this plugin's commands")
    check(names.count("/implement") == 1,
          "a FOREIGN namespace (/superpowers:implement) is not a boundary")
    check(len([b for b in whole["command_boundaries"]
               if b["command"] == "/specify"]) == 1,
          "a marker with no timestamp is not a boundary (and does not crash)")
    check(len(names) == 4,
          "a marker quoted mid-message is not a boundary (anchored match)")
    check(any(b["command"] == "/implement" for b in whole["command_boundaries"]),
          "list-block message content is read, not skipped")
    check(abs(whole["cost_computed_usd"] - 0.300) < 1e-9,
          "unclaimed, the whole window is this run's (12000 tok = $0.3000)")
    check(whole["cost_statusline_usd"] == 0.9,
          "with no claim the statusline delta is reported")

    one = run("--claim", "/prompt-grill-me")
    if one is None:
        print("SELFTEST FAIL"); return 1
    check(len(one["claims"]) == 1 and one["unmatched_claims"] == [],
          "the claim is matched by name")
    claimed = one["claims"][0]["cost_computed_usd"] if one["claims"] else -1
    check(abs(claimed - 0.085) < 1e-9,
          "the claim gets its OWN segment ($0.0850) -- not the preceding /vuln "
          "boundary's ($0.1000), which positional pairing would have taken")
    check(abs(one["cost_computed_usd"] - 0.215) < 1e-9,
          "the remainder keeps everything unclaimed, /vuln's spend included")
    check(abs(one["cost_computed_usd"] + claimed - whole["cost_computed_usd"]) < 1e-9,
          "claim + remainder are disjoint and sum to the unsplit window")
    check(one["cost_statusline_usd"] is None,
          "a claimed window reports no statusline delta (option B cannot split)")
    check(one["new_checkpoint"]["line_offset"] == whole["new_checkpoint"]["line_offset"],
          "claiming does not move where the checkpoint lands")

    subless = subprocess.run(
        [sys.executable, os.path.abspath(__file__), "--transcript", tpath,
         "--prices", ppath, "--commands-dir", cdir,
         "--now-ts", "2026-09-01T10:11:00.000Z", "--claim", "/prompt-grill-me"],
        capture_output=True, text=True)
    if subless.returncode == 0:
        d = json.loads(subless.stdout)
        check(abs(d["claims"][0]["cost_computed_usd"] - 0.075) < 1e-9,
              "subagent spend lands in the segment it ran in, not elsewhere")
    else:
        bad("subagent-free run failed")

    miss = run("--claim", "/prompt-brainstorm")
    check(miss is not None and miss["unmatched_claims"] == ["/prompt-brainstorm"]
          and miss["claims"] == [],
          "a claim with no matching boundary is reported, never guessed onto one")
    check(miss is not None
          and abs(miss["cost_computed_usd"] - whole["cost_computed_usd"]) < 1e-9,
          "an unmatched claim carves out nothing -- no spend is lost")

    bare = subprocess.run(
        [sys.executable, os.path.abspath(__file__), "--transcript", tpath,
         "--prices", ppath, "--subagents-dir", sdir,
         "--now-ts", "2026-09-01T10:11:00.000Z"], capture_output=True, text=True)
    if bare.returncode == 0:
        d = json.loads(bare.stdout)
        check(d["command_boundaries"] == [],
              "without --commands-dir no boundary is reported (nothing is guessed)")
        check(abs(d["cost_computed_usd"] - whole["cost_computed_usd"]) < 1e-9,
              "boundary detection never changes the cost figure")
    else:
        bad("run without --commands-dir failed")

    if failures:
        print("SELFTEST FAIL (%d)" % len(failures))
        return 1
    print("SELFTEST PASS")
    return 0


def match_claims(claim_names, boundaries):
    """Pair each claimed command name with the boundary it actually ran at.

    Matching is BY NAME, scanning forward, never by position. A window routinely
    contains boundaries no claim corresponds to -- `/vuln`, `/upgrade`,
    `/statusline`, `/docs-profile` and the two guideline reviewers emit no cost
    entry at all, and any run the user interrupted leaves a boundary behind too.
    Pairing the k-th claim with the k-th boundary therefore skews the moment one
    of those sits in the window, and files one command's spend under another
    command's lifecycle labels.

    Returns (matched, unmatched). Each matched entry carries the half-open
    segment [start, end) that belongs to that claim; end is None for the final
    segment, meaning "to the end of the window"."""
    matched, unmatched = [], []
    cursor = 0
    for name in claim_names:
        hit = None
        for i in range(cursor, len(boundaries)):
            if boundaries[i]["command"] == name:
                hit = i
                break
        if hit is None:
            unmatched.append(name)
            continue
        cursor = hit + 1
        start = parse_ts(boundaries[hit]["ts"])
        end = parse_ts(boundaries[hit + 1]["ts"]) if hit + 1 < len(boundaries) else None
        matched.append({"command": name, "ts": boundaries[hit]["ts"],
                        "start": start, "end": end})
    return matched, unmatched


def price_block(acc, prices):
    """Turn one accumulator into the models array + total, per section 6."""
    models = []
    total = 0.0
    for model in sorted(acc):
        tok = acc[model]
        cost_usd, note = price_model(model, tok, prices)
        if cost_usd is not None:
            total += cost_usd
        entry = {
            "model": model,
            "cost_usd": cost_usd,
            "input_tokens": tok["input"],
            "output_tokens": tok["output"],
            "cache_read_tokens": tok["cache_read"],
            "cache_write_tokens": tok["cache_write_5m"] + tok["cache_write_1h"],
        }
        if note:
            entry["note"] = note
        models.append(entry)
    return models, round(total, 4)


def main():
    ap = argparse.ArgumentParser(description="Compute a dev-workflows session-cost delta.")
    ap.add_argument("--transcript", default="")
    ap.add_argument("--subagents-dir", default="")
    ap.add_argument("--prices", default="")
    ap.add_argument("--checkpoint", default="")
    ap.add_argument("--snapshot", default="")
    ap.add_argument("--now-ts", default="")
    ap.add_argument("--commands-dir", default="",
                    help="The plugin commands/ dir. Supplies the known-command set "
                         "that command boundaries are resolved against, and this "
                         "plugin's own namespace; without it no boundaries are "
                         "reported.")
    ap.add_argument("--claim", action="append", default=[], metavar="/COMMAND",
                    help="A deferred run to carve out of this window, oldest "
                         "first (cost-emission.md section 13). Repeatable. Each "
                         "is matched to a boundary BY NAME; the remainder stays "
                         "with this run.")
    ap.add_argument("--selftest", action="store_true",
                    help="Run the built-in fixture checks and exit.")
    args = ap.parse_args()

    if args.selftest:
        sys.exit(selftest())

    # --transcript and --prices are declared optional only so --selftest can run
    # without them; for a real measurement they stay mandatory.
    missing = [f for f in ("transcript", "prices") if not getattr(args, f)]
    if missing:
        ap.error("the following arguments are required: "
                 + ", ".join("--" + m for m in missing))
    # A path that is merely absent or unreadable would otherwise price the run at
    # $0 and exit clean -- a plausible-but-wrong figure, which is worse than a
    # loud failure. Note this is a check on the ARGUMENT, not on the contract that
    # a malformed LINE never fails the run; that still holds.
    if not os.path.isfile(args.transcript):
        ap.error("--transcript is not a readable file: %s" % args.transcript)

    now_dt = parse_ts(args.now_ts) or datetime.datetime.now(datetime.timezone.utc)

    checkpoint = {"line_offset": 0, "last_ts": None, "last_snapshot_cost": None}
    if args.checkpoint and os.path.isfile(args.checkpoint):
        try:
            with open(args.checkpoint, encoding="utf-8", errors="replace") as fh:
                loaded = json.load(fh)
            if isinstance(loaded, dict):
                for k in checkpoint:
                    if k in loaded:
                        checkpoint[k] = loaded[k]
        except (ValueError, OSError):
            pass
    line_offset = checkpoint["line_offset"] if isinstance(checkpoint["line_offset"], int) else 0
    last_dt = parse_ts(checkpoint["last_ts"])

    prices = load_prices(args.prices)
    known_commands, plugin_name = load_command_names(args.commands_dir)

    records = []
    new_line_offset, main_first_ts, boundaries, main_records = scan_main(
        args.transcript, line_offset, known_commands, plugin_name
    )
    records.extend(main_records)
    sub_first_ts = read_subagents(args.subagents_dir, last_dt, now_dt, records)

    matched, unmatched = match_claims(args.claim, boundaries)

    # Partition every buffered record into exactly one bucket: a claimed segment,
    # or the remainder that stays with this run. Disjoint by construction, and
    # exhaustive -- so the slices always sum to the whole window, and an unmatched
    # claim costs nothing beyond its own attribution (its spend simply stays here).
    remainder = {}
    for m in matched:
        m["acc"] = {}
    for ts, model, usage in records:
        target = remainder
        if ts is not None:
            for m in matched:
                if m["start"] is not None and ts >= m["start"] \
                        and (m["end"] is None or ts < m["end"]):
                    target = m["acc"]
                    break
        add_usage(target, model, usage)

    models, cost_computed = price_block(remainder, prices)

    if last_dt is not None:
        base_dt = last_dt
    else:
        candidates = [t for t in (main_first_ts, sub_first_ts) if t is not None]
        base_dt = min(candidates) if candidates else now_dt
    duration_s = int(max(0, (now_dt - base_dt).total_seconds()))

    # Option B (statusline cross-check) measures whole renders, so it cannot be
    # apportioned once part of the window has been carved off. With any claim the
    # field is omitted rather than over-reported against the remainder.
    cost_statusline = None
    current_snapshot = read_snapshot_cost(args.snapshot)
    baseline_snapshot = checkpoint["last_snapshot_cost"]
    if not matched and isinstance(current_snapshot, (int, float)) \
            and isinstance(baseline_snapshot, (int, float)):
        cost_statusline = round(current_snapshot - baseline_snapshot, 4)
    new_last_snapshot_cost = (
        current_snapshot if isinstance(current_snapshot, (int, float)) else baseline_snapshot
    )

    claims_out = []
    for m in matched:
        cm, cc = price_block(m["acc"], prices)
        end_dt = m["end"] or now_dt
        claims_out.append({
            "command": m["command"],
            "ts": m["ts"],
            "models": cm,
            "cost_computed_usd": cc,
            "duration_s": int(max(0, (end_dt - m["start"]).total_seconds()))
            if m["start"] is not None else 0,
        })

    result = {
        "models": models,
        "cost_computed_usd": cost_computed,
        "cost_statusline_usd": cost_statusline,
        "duration_s": duration_s,
        "command_boundaries": boundaries,
        "claims": claims_out,
        "unmatched_claims": unmatched,
        "new_checkpoint": {
            "line_offset": new_line_offset,
            "last_ts": iso_z(now_dt),
            "last_snapshot_cost": new_last_snapshot_cost,
        },
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
