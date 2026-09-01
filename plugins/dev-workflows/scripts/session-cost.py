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


def load_command_names(commands_dir):
    """The set of this plugin's command names, read off the shipped commands/ dir.

    Returned as a set of bare names ("implement"). None when no directory was
    supplied, which disables boundary detection entirely rather than guessing."""
    if not commands_dir or not os.path.isdir(commands_dir):
        return None
    names = set()
    for fp in glob.glob(os.path.join(commands_dir, "*.md")):
        base = os.path.basename(fp)[:-3]
        if base:
            names.add(base)
    return names or None


def command_marker(obj, known):
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
    if not text.startswith(MARKER_OPEN):
        return None
    rest = text[len(MARKER_OPEN):]
    end = rest.find(MARKER_CLOSE)
    if end < 0:
        return None
    raw = rest[:end].strip()
    if not raw.startswith("/"):
        return None
    typed = raw[1:].strip()
    if not typed or known is None:
        return None
    for cand in (typed, typed.split(":", 1)[-1]):
        if cand in known:
            return cand
    return None


def read_main(path, line_offset, acc, until_dt=None, known_commands=None):
    """Accumulate usage from main-transcript lines [line_offset, EOF) -- or, when
    until_dt is given, [line_offset, first line stamped after until_dt).

    Returns (stop_line_offset, earliest_timestamp_seen_in_window, boundaries),
    where boundaries lists every known-command invocation seen in the window."""
    count = line_offset
    first_ts = None
    boundaries = []
    if not path or not os.path.isfile(path):
        return count, first_ts, boundaries
    with open(path, encoding="utf-8", errors="replace") as fh:
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
            if until_dt is not None and ts is not None and ts > until_dt:
                return i, first_ts, boundaries
            name = command_marker(obj, known_commands)
            if name is not None:
                boundaries.append(
                    {"command": "/" + name, "ts": iso_z(ts), "line_offset": i}
                )
            if ts is not None and (first_ts is None or ts < first_ts):
                first_ts = ts
            model, usage = extract_usage(obj)
            if usage is not None:
                add_usage(acc, model, usage)
    return count, first_ts, boundaries


def read_subagents(subdir, last_dt, now_dt, acc):
    """Accumulate usage from subagents/agent-*.jsonl entries whose timestamp is
    in (last_dt, now_dt]  (all <= now_dt when last_dt is None).

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
                    add_usage(acc, model, usage)
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
    def asst(ts, out):
        return {"type": "assistant", "timestamp": ts,
                "message": {"role": "assistant", "model": "claude-opus-5",
                            "usage": {"input_tokens": 0, "output_tokens": out,
                                      "cache_read_input_tokens": 0,
                                      "cache_creation_input_tokens": 0}}}

    def cmd(ts, name):
        return {"type": "user", "timestamp": ts,
                "message": {"role": "user",
                            "content": MARKER_OPEN + name + MARKER_CLOSE}}
    return [
        asst("2026-09-01T10:00:00.000Z", 1000),                  # 0 earlier work
        cmd("2026-09-01T10:01:00.000Z", "/prompt-grill-me"),     # 1 ceding cmd
        asst("2026-09-01T10:02:00.000Z", 4000),                  # 2 prologue+grill
        {"type": "user", "timestamp": "2026-09-01T10:03:00.000Z",  # 3 marker text
         "message": {"role": "user",                               #   mid-content:
                     "content": "a doc quoting " + MARKER_OPEN +   #   NOT a boundary
                                "/implement" + MARKER_CLOSE + " inline"}},
        asst("2026-09-01T10:04:00.000Z", 2000),                  # 4 more grill
        cmd("2026-09-01T10:05:00.000Z", "/compact"),             # 5 not this plugin
        cmd("2026-09-01T10:06:00.000Z", "/dev-workflows:implement"),  # 6 namespaced
        asst("2026-09-01T10:07:00.000Z", 3000),                  # 7 the next run
    ]


def selftest():
    import subprocess
    import tempfile

    failures = []

    def ok(msg):
        print("ok    " + msg)

    def bad(msg):
        failures.append(msg)
        print("FAIL  " + msg)

    def check(cond, msg):
        ok(msg) if cond else bad(msg)

    tmp = tempfile.mkdtemp(prefix="session-cost-selftest-")
    tpath = os.path.join(tmp, "t.jsonl")
    with open(tpath, "w", encoding="utf-8") as fh:
        for r in _st_rows():
            fh.write(json.dumps(r) + "\n")
    ppath = os.path.join(tmp, "prices.yaml")
    with open(ppath, "w", encoding="utf-8") as fh:
        fh.write(SELFTEST_PRICES)
    cdir = os.path.join(tmp, "commands")
    os.makedirs(cdir)
    for n in ("implement", "prompt-grill-me", "prompt-brainstorm", "specify"):
        with open(os.path.join(cdir, n + ".md"), "w", encoding="utf-8") as fh:
            fh.write("x\n")

    def run(*extra):
        cmd = [sys.executable, os.path.abspath(__file__),
               "--transcript", tpath, "--prices", ppath,
               "--now-ts", "2026-09-01T10:08:00.000Z"] + list(extra)
        out = subprocess.run(cmd, capture_output=True, text=True)
        if out.returncode != 0:
            bad("run failed: " + " ".join(extra) + " -> " + out.stderr.strip()[:200])
            return None
        return json.loads(out.stdout)

    whole = run("--commands-dir", cdir)
    if whole is None:
        print("SELFTEST FAIL"); return 1
    names = [b["command"] for b in whole["command_boundaries"]]
    check(names == ["/prompt-grill-me", "/implement"],
          "boundaries are exactly the two known plugin commands (got %r)" % (names,))
    check("/compact" not in names,
          "/compact is not a boundary -- it is not one of this plugin's commands")
    check(len(whole["command_boundaries"]) == 2,
          "a marker quoted mid-message is not a boundary (anchored match)")
    check(whole["command_boundaries"][1]["ts"] == "2026-09-01T10:06:00Z",
          "the namespaced form /dev-workflows:implement resolves to /implement")
    check(abs(whole["cost_computed_usd"] - 0.25) < 1e-9,
          "unsplit window prices the whole session (10000 tok = $0.2500)")

    bare = run()
    check(bare is not None and bare["command_boundaries"] == [],
          "without --commands-dir no boundary is reported (nothing is guessed)")
    check(bare is not None
          and bare["cost_computed_usd"] == whole["cost_computed_usd"],
          "boundary detection never changes the cost figure")

    split = whole["command_boundaries"][1]["ts"]
    first = run("--commands-dir", cdir, "--until-ts", split)
    if first is None:
        print("SELFTEST FAIL"); return 1
    check(abs(first["cost_computed_usd"] - 0.175) < 1e-9,
          "the ceded slice carries the grill's spend ($0.1750), not the next run's")
    ckpath = os.path.join(tmp, "ck.json")
    with open(ckpath, "w", encoding="utf-8") as fh:
        json.dump(first["new_checkpoint"], fh)
    second = run("--commands-dir", cdir, "--checkpoint", ckpath)
    if second is None:
        print("SELFTEST FAIL"); return 1
    check(abs(second["cost_computed_usd"] - 0.075) < 1e-9,
          "the resuming slice carries only its own spend ($0.0750)")
    check(abs(first["cost_computed_usd"] + second["cost_computed_usd"]
              - whole["cost_computed_usd"]) < 1e-9,
          "the two slices are disjoint and sum to the unsplit window")
    check(first["cost_statusline_usd"] is None,
          "a split slice reports no statusline delta (option B cannot be split)")

    if failures:
        print("SELFTEST FAIL (%d)" % len(failures))
        return 1
    print("SELFTEST PASS")
    return 0

def main():
    ap = argparse.ArgumentParser(description="Compute a dev-workflows session-cost delta.")
    ap.add_argument("--transcript", default="")
    ap.add_argument("--subagents-dir", default="")
    ap.add_argument("--prices", default="")
    ap.add_argument("--checkpoint", default="")
    ap.add_argument("--snapshot", default="")
    ap.add_argument("--now-ts", default="")
    ap.add_argument("--until-ts", default="",
                    help="End the measurement window here instead of at --now-ts. "
                         "Used to split one window across a deferred attribution "
                         "(cost-emission.md section 13).")
    ap.add_argument("--commands-dir", default="",
                    help="The plugin commands/ dir. Supplies the known-command set "
                         "that command boundaries are resolved against; without it "
                         "no boundaries are reported.")
    ap.add_argument("--selftest", action="store_true",
                    help="Run the built-in fixture checks and exit.")
    args = ap.parse_args()

    if args.selftest:
        sys.exit(selftest())

    # --transcript and --prices are declared optional only so --selftest can run
    # without them. For a real measurement they stay mandatory: silently pricing a
    # missing transcript at $0 is exactly the kind of plausible-but-wrong figure
    # this script must never produce.
    missing = [f for f in ("transcript", "prices") if not getattr(args, f)]
    if missing:
        ap.error("the following arguments are required: "
                 + ", ".join("--" + m for m in missing))

    now_dt = parse_ts(args.now_ts) or datetime.datetime.now(datetime.timezone.utc)
    until_dt = parse_ts(args.until_ts)
    window_end = until_dt or now_dt

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
    known_commands = load_command_names(args.commands_dir)
    acc = {}
    new_line_offset, main_first_ts, boundaries = read_main(
        args.transcript, line_offset, acc, until_dt, known_commands
    )
    sub_first_ts = read_subagents(args.subagents_dir, last_dt, window_end, acc)

    models = []
    cost_computed = 0.0
    for model in sorted(acc):
        tok = acc[model]
        cost_usd, note = price_model(model, tok, prices)
        if cost_usd is not None:
            cost_computed += cost_usd
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

    if last_dt is not None:
        base_dt = last_dt
    else:
        candidates = [t for t in (main_first_ts, sub_first_ts) if t is not None]
        base_dt = min(candidates) if candidates else window_end
    duration_s = int(max(0, (window_end - base_dt).total_seconds()))

    # Option B (statusline cross-check) measures whole renders, so it cannot be
    # apportioned across a split window: on a --until-ts run the field is omitted
    # and the baseline is carried forward unchanged, leaving the delta to be
    # claimed whole by the final (unsplit) slice.
    cost_statusline = None
    new_last_snapshot_cost = checkpoint["last_snapshot_cost"]
    if until_dt is None:
        current_snapshot = read_snapshot_cost(args.snapshot)
        baseline_snapshot = checkpoint["last_snapshot_cost"]
        if isinstance(current_snapshot, (int, float)) and isinstance(baseline_snapshot, (int, float)):
            cost_statusline = round(current_snapshot - baseline_snapshot, 4)
        new_last_snapshot_cost = (
            current_snapshot if isinstance(current_snapshot, (int, float)) else baseline_snapshot
        )

    result = {
        "models": models,
        "cost_computed_usd": round(cost_computed, 4),
        "cost_statusline_usd": cost_statusline,
        "duration_s": duration_s,
        "command_boundaries": boundaries,
        "new_checkpoint": {
            "line_offset": new_line_offset,
            "last_ts": iso_z(window_end),
            "last_snapshot_cost": new_last_snapshot_cost,
        },
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
