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


def read_main(path, line_offset, acc):
    """Accumulate usage from main-transcript lines [line_offset, EOF).

    Returns (new_total_line_count, earliest_timestamp_seen_in_window)."""
    count = line_offset
    first_ts = None
    if not path or not os.path.isfile(path):
        return count, first_ts
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
            if ts is not None and (first_ts is None or ts < first_ts):
                first_ts = ts
            model, usage = extract_usage(obj)
            if usage is not None:
                add_usage(acc, model, usage)
    return count, first_ts


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


def main():
    ap = argparse.ArgumentParser(description="Compute a dev-workflows session-cost delta.")
    ap.add_argument("--transcript", required=True)
    ap.add_argument("--subagents-dir", default="")
    ap.add_argument("--prices", required=True)
    ap.add_argument("--checkpoint", default="")
    ap.add_argument("--snapshot", default="")
    ap.add_argument("--now-ts", default="")
    args = ap.parse_args()

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
    acc = {}
    new_line_offset, main_first_ts = read_main(args.transcript, line_offset, acc)
    sub_first_ts = read_subagents(args.subagents_dir, last_dt, now_dt, acc)

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
        base_dt = min(candidates) if candidates else now_dt
    duration_s = int(max(0, (now_dt - base_dt).total_seconds()))

    cost_statusline = None
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
        "new_checkpoint": {
            "line_offset": new_line_offset,
            "last_ts": iso_z(now_dt),
            "last_snapshot_cost": new_last_snapshot_cost,
        },
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
