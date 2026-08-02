---
tags:
  - tasks-exclude
---

# Session Cost Reporting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the dev-workflows plugin a **Session Cost Reporting** subsystem that answers "how many dollars did this Value Increment cost across its whole lifecycle, by phase / role / model" — persisted per-VI into the **specs repo** for the maintainer to aggregate. Cost is **computed** from transcript token usage × a price table (Claude Code stores no dollar figure in the transcript); an optional statusline snapshot cross-checks it. Ships as **v2.10.0** with a new `scripts/session-cost.py` engine, a new `references/cost-emission.md` single source of truth, a new `references/cost-prices.yaml` price table, a terminal **cost phase** wired into the six VI-lifecycle commands, and a new `/statusline` installer (whose shipped script enables the cross-check).

**Architecture:** Mirrors the existing self-contained emitter pattern (`references/feedback-emission.md`, `references/followup-emission.md`). **T1** builds the deterministic engine: `scripts/session-cost.py` (stdlib-only — reads the main transcript from a checkpoint line offset forward + the session's `subagents/agent-*.jsonl` within a timestamp window, sums `usage` by `model`, applies `references/cost-prices.yaml`, prints structured JSON, and hands back a `new_checkpoint` the caller persists). **T2** creates `references/cost-emission.md` — the SSOT that owns session-artifact resolution, the chained-checkpoint model, the price-table reference, the entry format (spec §9 verbatim), the specs-first persistence ladder (`cost/<sid8>.md`), pending/reconciliation, the statusline augmentation, the attribution rules (incl. the `/release-notes` inference), and the single `emit-cost` caller contract. **T3** ships the `/statusline` installer + a vendored copy of the statusline script (the copy adds the per-render snapshot write that enables Option B). **T4/T5** wire a concise terminal cost phase — citing `emit-cost`, not re-explaining the mechanism — into the six commands (`/specify`, `/design`, `/release-notes` in T4; `/epics`, `/implement`, `/document` ×2 in T5) as the NEW final operational phase, after the existing feedback phase and before each command's unique terminal heading. **T6** bumps the release surfaces (version lock-step to 2.10.0, description + `/statusline`, CHANGELOG, README). Changes are **additive**; no wired command changes behavior.

**Tech Stack:** One Python 3 script (`session-cost.py`, standard library only — `json`, `argparse`, `glob`, `os`, `datetime`; a tiny purpose-built YAML reader is embedded so **PyYAML is NOT a dependency**), one YAML price table, Markdown command/reference files, one Bash statusline script, and two JSON manifests (`plugin.json`, `marketplace.json`). **No test framework, no husky/prettier hook** — every task's verification is **structural**: `python3 -c "import ast; ast.parse(...)"` / `json.load(...)`, an ad-hoc fixture run of `session-cost.py` asserting a hand-computed value, `bash -n`, `grep` for added anchors, and `git diff --stat` byte-diff review.

## Global Constraints

Every task's requirements implicitly include this section.

- **Additive-only.** Do NOT modify the `impl-maintenance` agent, `jira-reader`, any reviewer agent, the format-reference files, or the sibling plugins. With no writable specs/vault target every wired command behaves exactly as today except that the cost phase always also computes and advances its checkpoint; no cost phase ever fails the run.
- **Siblings byte-identical.** In `.claude-plugin/marketplace.json`, `dt-style-guide` (`0.2.2`) and `obsidian-llm-wiki` (`0.3.1`) — versions AND description strings — are unchanged. `git diff` must show only the `dev-workflows` entry changed.
- **No test framework — structural verification only** (no tests exist; NEVER write "run pytest"). Verification is `python3 -c "import ast; ast.parse(...)"` / `json.load(...)`, the T1 fixture run, `bash -n`, `grep` anchors, and `git diff --stat`.
- **Commit trailer, EXACTLY (every commit):** `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- **NEVER `git add -A`** — stage only the files named in each commit step. Commit with `git commit --no-verify` if any hook interferes, and note that the user should run `pnpm prettier -w <files>` (or the repo's formatter) locally before pushing if needed. Commit/push/merge is the finishing step the user chooses.
- **No new user-facing command except `/statusline`.** Cost reporting adds phases, not commands. No behavior change to any wired command.
- **No user name is ever written to a cost file** (privacy). Cost filenames use `<sid8>`, not identity; entries carry no author. The git commit author is the only, separate identity layer.
- **Checkpoint & snapshot files are transient/local and NEVER committed** — `~/.claude/dev-workflows/cost-state/<session_id>.json` and `~/.claude/dev-workflows/cost-snapshots/<session_id>.json`.
- **Recompute all counts from the repo, never assert from memory** — this effort adds **one** command (`/statusline`) but **no** subagent (stays 26) and **no** hook (stays 4). A new reference file or script is not a command. Verify the command count by `ls commands/*.md | wc -l` before writing "Sixteen".
- **Anchor by quoted text, not line number** — line numbers here are from a 2026-07-09 read and are approximate. After each edit, read the `git diff` and confirm no unintended reflow.

### Shared vocabulary (used across tasks)

- **Cost engine** — `scripts/session-cost.py` (T1): pure computation, no specs-repo writes. Contract in T1 "Interfaces".
- **Emitter / SSOT** — `references/cost-emission.md` (T2): owns everything conceptual; every command's cost phase cites it and runs `emit-cost` inline.
- **`emit-cost`** — the single caller entry point (T2 §11). Inputs: `command`, `phase`, `role` (or `inferred`), `jira_key`|`null`, `source`, `plugin_version`. It resolves artifacts, runs the engine, applies attribution, writes the per-invocation entry via the specs-first ladder, and ALWAYS advances the checkpoint.
- **`<sid8>`** — first 8 chars of `session_id`. **`<cwd-slug>`** — the absolute cwd with every `/` and `.` replaced by `-` (`/workspace/docs` → `-workspace-docs`).
- **Chained checkpoint** — a command's cost window START is the previous dev-workflows command's END in the same session; first command starts at $0.

## File Structure

| File | Task | Responsibility |
|------|------|----------------|
| `plugins/dev-workflows/scripts/session-cost.py` | T1 (create) | Deterministic cost engine. Reads the main transcript from a checkpoint line offset forward + `subagents/agent-*.jsonl` in `(last_ts, now]`, sums `usage` by model, applies the price table (USD/million), and prints `{models, cost_computed_usd, cost_statusline_usd, duration_s, new_checkpoint}`. Stdlib only; embedded minimal YAML reader; never writes the specs repo or the checkpoint. |
| `plugins/dev-workflows/references/cost-prices.yaml` | T1 (create) | Per-model price table (USD per million tokens): `input`/`output`/`cache_read`/`cache_write_5m`/`cache_write_1h` per model + `default: null`. Maintainer-verified placeholders; overridable via `$DEV_WORKFLOWS_COST_PRICES`. |
| `plugins/dev-workflows/references/cost-emission.md` | T2 (create) | Single source of truth: session-artifact resolution, chained-checkpoint model, engine invocation, price table, entry format (spec §9 verbatim), specs-first ladder (`cost/<sid8>.md`), pending + move-then-delete reconciliation, statusline augmentation (Option B), attribution (incl. `/release-notes` inference), privacy, and the `emit-cost` caller contract. Cost ALWAYS runs. |
| `plugins/dev-workflows/commands/statusline.md` | T3 (create) | `/statusline` installer — copies the vendored script to a stable per-user path and merges the `statusLine` block into `~/.claude/settings.json`; idempotent; backs up existing script + settings; confirms before changing settings. |
| `plugins/dev-workflows/scripts/statusline-command.sh` | T3 (create) | Vendored copy of the user's statusline script (verbatim) + a per-render snapshot-write block that persists `{ts, cost_usd}` to `~/.claude/dev-workflows/cost-snapshots/<session_id>.json` (Option B enabler). |
| `plugins/dev-workflows/commands/specify.md` | T4 (modify) | Add terminal **Phase 9 — Session cost** (`phase: specification, role: pe`) before `## Final report`. |
| `plugins/dev-workflows/commands/design.md` | T4 (modify) | Add terminal **Phase 9 — Session cost** (`phase: planning, role: dev`) before `## Final report`. |
| `plugins/dev-workflows/commands/release-notes.md` | T4 (modify) | Add terminal **Phase 11 — Session cost** (`phase/role: inferred`) before `## Invariants (always enforced)`; states the PM-vs-dev inference. |
| `plugins/dev-workflows/commands/epics.md` | T5 (modify) | Add terminal **Phase 11 — Session cost** (`phase: epic-refinement, role: pe`) before `## Invariants (always enforced)`. |
| `plugins/dev-workflows/commands/implement.md` | T5 (modify) | Add terminal **Phase 7 — Session cost** (`phase: implementation, role: dev`) before `## Invariants (always enforced)`. |
| `plugins/dev-workflows/commands/document.md` | T5 (modify ×2) | Add terminal **Phase 11 — Session cost** (Mode A, `/document (Jira mode)`) before Mode A's `## Invariants`, and terminal **Phase 7 — Session cost** (Mode B, `/document (direct mode)`) before Mode B's `## Invariants`. Both `phase: documenting, role: dev`. |
| `plugins/dev-workflows/.claude-plugin/plugin.json` | T6 (modify) | Version `2.9.0` → `2.10.0`; description Fifteen → Sixteen slash commands (+ `/statusline`). Subagent count (26) + hook count (4) unchanged. |
| `.claude-plugin/marketplace.json` | T6 (modify) | `dev-workflows` entry version `2.9.0` → `2.10.0` + the same description update. Siblings byte-identical. |
| `plugins/dev-workflows/CHANGELOG.md` | T6 (modify) | Prepend `## [2.10.0] — 2026-07-09` (`### Added`); history preserved. |
| `plugins/dev-workflows/README.md` | T6 (modify) | New `## Session cost reporting` + `## Statusline` sections; a Reference-docs bullet for `cost-emission.md`. Root README untouched. |

**Task order.** T1 (engine) and T2 (SSOT) land first (T2 cites the engine; the commands cite T2). T3 is independent. T4/T5 wire the six commands (all cite T2). T6 runs last (after `/statusline` exists so the command count is accurate).

**Computed phase numbers (from the 2026-07-09 repo read; the cost phase is the NEW last operational phase, inserted after the existing feedback phase and before the terminal heading):**
- `specify.md` — feedback is Phase 8; terminal heading `## Final report`. Cost = **Phase 9**.
- `design.md` — feedback is Phase 8; terminal heading `## Final report`. Cost = **Phase 9**.
- `release-notes.md` — feedback is Phase 10 (after Phase 9 follow-ups); terminal heading `## Invariants (always enforced)`. Cost = **Phase 11**.
- `epics.md` — Phase 8 maintenance (feedback persist), Phase 9 Final Report, Phase 10 follow-ups; terminal `## Invariants`. Cost = **Phase 11**.
- `implement.md` — Phase 4 maintenance (feedback persist), Phase 5 Final Report, Phase 6 follow-ups; terminal `## Invariants`. Cost = **Phase 7**.
- `document.md` — Mode A: Phase 8 maintenance, Phase 9 Report, Phase 10 follow-ups; terminal Mode A `## Invariants`. Cost = **Phase 11**. Mode B: Phase 4 maintenance, Phase 5 Report, Phase 6 follow-ups; terminal Mode B `## Invariants`. Cost = **Phase 7**. `## Invariants (always enforced)` occurs twice, so each find block includes the mode's unique first invariant bullet.

---

### Task 1: Cost engine core — `scripts/session-cost.py` + `references/cost-prices.yaml`

**Suggested model:** Opus (subtle checkpoint / windowing / pricing logic).

**Files:**
- Create: `plugins/dev-workflows/scripts/session-cost.py`
- Create: `plugins/dev-workflows/references/cost-prices.yaml`

**Interfaces:**
- **CLI:** `python3 session-cost.py --transcript PATH --subagents-dir PATH --prices PATH [--checkpoint PATH] [--snapshot PATH] [--now-ts ISO8601]`. `--transcript` and `--prices` are required; `--checkpoint` may point at a non-existent file (⇒ fresh window); `--snapshot` and `--now-ts` are optional (`--now-ts` defaults to now UTC).
- **Checkpoint in:** `{line_offset:int, last_ts:str|null, last_snapshot_cost:float|null}` (absent ⇒ `line_offset=0, last_ts=null, last_snapshot_cost=null`).
- **Stdout JSON out:** `{models:[{model, cost_usd, input_tokens, output_tokens, cache_read_tokens, cache_write_tokens[, note]}], cost_computed_usd, cost_statusline_usd, duration_s, new_checkpoint:{line_offset, last_ts, last_snapshot_cost}}`. The **caller** (T2 `emit-cost`) writes `new_checkpoint` back; the script never writes it.
- **Pricing:** USD per MILLION tokens — `cost = input*input + output*output + cache_read*cache_read + cache_write_5m*cache_write_5m + cache_write_1h*cache_write_1h`, all `/1_000_000`. A message with no `ephemeral_5m/1h` split prices `cache_creation_input_tokens` at the 5m rate. Unknown model ⇒ `cost_usd:null` + `note:"unpriced-model"`, never a crash.
- **Consumes:** `references/cost-prices.yaml` (via the embedded stdlib YAML reader — PyYAML NOT required).

- [ ] **Step 1: Write `scripts/session-cost.py`**

Create `plugins/dev-workflows/scripts/session-cost.py` with EXACTLY this content:

````python
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
````

- [ ] **Step 2: Write `references/cost-prices.yaml`**

Create `plugins/dev-workflows/references/cost-prices.yaml` with EXACTLY this content. The rates are **maintainer-verified placeholders** (Anthropic's standard cache multipliers: read 0.1x, 5m write 1.25x, 1h write 2x); exact dollar accuracy is NOT required and is overridable via `$DEV_WORKFLOWS_COST_PRICES`.

````yaml
# dev-workflows session-cost price table. USD per MILLION tokens, keyed by model id.
# PLACEHOLDER RATES -- verify against current Anthropic pricing at implementation.
# Override without editing this file: set $DEV_WORKFLOWS_COST_PRICES to a path, or
# drop a repo-local cost-prices.yaml. Cache multipliers follow Anthropic's model
# (cache_read = input * 0.1, cache_write_5m = input * 1.25, cache_write_1h = input * 2.0).
models:
  claude-opus-4-8:
    input: 15.0           # verify: Anthropic pricing
    output: 75.0          # verify: Anthropic pricing
    cache_read: 1.5       # input * 0.1
    cache_write_5m: 18.75 # input * 1.25
    cache_write_1h: 30.0  # input * 2.0
  claude-sonnet-5:
    input: 3.0            # verify: Anthropic pricing
    output: 15.0          # verify: Anthropic pricing
    cache_read: 0.3       # input * 0.1
    cache_write_5m: 3.75  # input * 1.25
    cache_write_1h: 6.0   # input * 2.0
  claude-haiku-4-5-20251001:
    input: 1.0            # verify: Anthropic pricing
    output: 5.0           # verify: Anthropic pricing
    cache_read: 0.1       # input * 0.1
    cache_write_5m: 1.25  # input * 1.25
    cache_write_1h: 2.0   # input * 2.0
default: null             # unknown model -> unpriced (tokens recorded, cost null)
````

- [ ] **Step 3: Structural verification (syntax + price-table parse + fixture)**

Run:
```bash
cd /workspace/ihudak-claude-plugins/plugins/dev-workflows
# 1. Python parses.
python3 -c "import ast; ast.parse(open('scripts/session-cost.py').read()); print('ast OK')"
# 2. Price table parses via the embedded stdlib reader (NO PyYAML dependency).
python3 -c "import importlib.util as u; s=u.spec_from_file_location('sc','scripts/session-cost.py'); m=u.module_from_spec(s); s.loader.exec_module(m); p=m.load_prices('references/cost-prices.yaml'); assert isinstance(p.get('models'),dict) and 'claude-opus-4-8' in p['models'] and 'default' in p, p; print('prices OK', sorted(p['models']))"
# 3. Fixture: two known assistant messages -> hand-computed cost; re-run with the emitted checkpoint returns ~0.
tmp="$(mktemp -d)"
cat > "$tmp/main.jsonl" <<'EOF'
{"type":"assistant","timestamp":"2026-07-09T10:00:00Z","message":{"model":"claude-opus-4-8","usage":{"input_tokens":100000,"output_tokens":100000,"cache_read_input_tokens":100000}}}
{"type":"assistant","timestamp":"2026-07-09T10:05:00Z","message":{"model":"claude-opus-4-8","usage":{"input_tokens":100000,"output_tokens":100000}}}
EOF
cat > "$tmp/prices.yaml" <<'EOF'
models:
  claude-opus-4-8:
    input: 10.0
    output: 30.0
    cache_read: 1.0
    cache_write_5m: 12.5
    cache_write_1h: 20.0
default: null
EOF
out1="$(python3 scripts/session-cost.py --transcript "$tmp/main.jsonl" --prices "$tmp/prices.yaml" --now-ts 2026-07-09T10:10:00Z)"
echo "$out1"
python3 - "$out1" <<'PY'
import json, sys
r = json.loads(sys.argv[1])
# input 200000*10/1e6 = 2.0 ; output 200000*30/1e6 = 6.0 ; cache_read 100000*1/1e6 = 0.1 -> 8.1
assert abs(r["cost_computed_usd"] - 8.1) < 1e-9, r["cost_computed_usd"]
assert r["new_checkpoint"]["line_offset"] == 2, r["new_checkpoint"]
assert r["duration_s"] == 600, r["duration_s"]          # 10:00 -> 10:10
assert len(r["models"]) == 1 and r["models"][0]["cache_write_tokens"] == 0, r["models"]
print("RUN1 OK", r["cost_computed_usd"], r["duration_s"])
PY
# Persist the emitted checkpoint, then re-run: the window is now empty.
echo "$out1" | python3 -c "import json,sys; json.dump(json.load(sys.stdin)['new_checkpoint'], open('$tmp/ckpt.json','w'))"
out2="$(python3 scripts/session-cost.py --transcript "$tmp/main.jsonl" --prices "$tmp/prices.yaml" --checkpoint "$tmp/ckpt.json" --now-ts 2026-07-09T10:12:00Z)"
python3 - "$out2" <<'PY'
import json, sys
r = json.loads(sys.argv[1])
assert r["cost_computed_usd"] == 0.0, r["cost_computed_usd"]
assert r["models"] == [], r["models"]
print("RUN2 OK", r["cost_computed_usd"])
PY
rm -rf "$tmp"
git status --porcelain scripts/session-cost.py references/cost-prices.yaml
```
Expected: `ast OK`; `prices OK ['claude-haiku-4-5-20251001', 'claude-opus-4-8', 'claude-sonnet-5']`; `RUN1 OK 8.1 600`; `RUN2 OK 0.0`; `git status --porcelain` shows exactly `?? plugins/dev-workflows/scripts/session-cost.py` and `?? plugins/dev-workflows/references/cost-prices.yaml`.

- [ ] **Step 4: Commit**

```bash
cd /workspace/ihudak-claude-plugins
git add plugins/dev-workflows/scripts/session-cost.py plugins/dev-workflows/references/cost-prices.yaml
git commit --no-verify -m "$(cat <<'EOF'
feat(dev-workflows): add session-cost engine + price table

New scripts/session-cost.py — a stdlib-only cost engine that reads the main
transcript from a chained-checkpoint line offset forward plus the session's
subagents/agent-*.jsonl within a (last_ts, now] window, sums usage by model,
applies references/cost-prices.yaml (USD per million tokens; cache 5m/1h split
priced exactly, unknown model -> unpriced/null), and prints
{models, cost_computed_usd, cost_statusline_usd, duration_s, new_checkpoint}.
Pure computation: never writes the specs repo or the checkpoint (the caller
persists new_checkpoint). Embedded minimal YAML reader -> PyYAML not required.
New references/cost-prices.yaml ships maintainer-verified placeholder rates,
overridable via $DEV_WORKFLOWS_COST_PRICES.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Cost emission SSOT — `references/cost-emission.md`

**Suggested model:** Opus (the conceptual authority every command relies on).

**Files:**
- Create: `plugins/dev-workflows/references/cost-emission.md`

**Interfaces:**
- Consumes at runtime: `cwd` + `~/.claude/projects/**`, `$SPECS_PATH` / `$VAULT_PATH`, `$DEV_WORKFLOWS_COST_PRICES`, the run's `jira_key`/`source`, `${CLAUDE_PLUGIN_ROOT}/scripts/session-cost.py` (T1), `${CLAUDE_PLUGIN_ROOT}/references/cost-prices.yaml` (T1), and `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (`version`).
- Produces: the reference cited by T4/T5's cost phases at `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md`. **Single caller entry point later tasks invoke by name:** `emit-cost` (§11). Section numbers callers rely on: §1 artifact resolution, §2 engine invocation, §3 checkpoint, §4 price table, §5 statusline augmentation, §6 entry format, §7 attribution + `/release-notes` inference, §8 persistence ladder, §9 pending/reconciliation, §11 caller contract.

- [ ] **Step 1: Write the new reference file**

Create `plugins/dev-workflows/references/cost-emission.md` with EXACTLY this content:

`````markdown
# Session Cost Emission — Shared Reference

Single source of truth for the dev-workflows session-cost subsystem. The terminal
"Session cost" phase of every VI-lifecycle command (`/specify`, `/epics`,
`/design`, `/implement`, `/document`, `/release-notes`) cites this file and
executes its steps inline through the single `emit-cost` entry point (§11). The
orchestrator owns every prompt; this reference owns session-artifact resolution,
the chained-checkpoint model, the transcript-window computation, the price table,
the report format, the persistence ladder, pending/reconciliation, and the
optional statusline augmentation.

**Purpose.** Know how many **dollars** a Value Increment (VI) cost across its
whole lifecycle, broken down by **phase**, **role**, and **model** — persisted
per-VI into the specs repo so the maintainer can aggregate spend across every
engineer and team. A VI's cost is the sum of per-command cost lines contributed
by every session that worked on it; summing is a read-time concern for the
maintainer — the plugin only ever appends immutable per-invocation measurements.

**Cost is computed, never read.** Claude Code stores no dollar figure in the
transcript. Every assistant message carries `.message.usage` + `.message.model`;
`scripts/session-cost.py` sums tokens per model and multiplies by a price table
(§4). Dollars are therefore an estimate that drifts from Claude Code's own figure
by the accuracy of the price table — an accepted trade (cost accuracy is
explicitly secondary to code/doc quality).

**Relationship to siblings.** Shares the `<VI-dir>/dev-workflows/` per-VI home
with `feedback-emission.md` / `followup-emission.md` and the self-contained
emitter pattern, but diverges deliberately: a **`cost/` subdir with per-session
files** (merge-safety under massive team fan-out — the largest VI to date was
worked by 23 teams) and **no dedup / no prose** (pure measurement, append-only).
No dedup or cross-reference between the three. This subsystem does NOT use the
`impl-maintenance` agent.

**Cost ALWAYS runs.** Unlike feedback (which writes nothing when there is no
plugin signal), the cost phase always computes and always advances the checkpoint
(§3) — even when it can only report-only. A silent write with no interaction is
the norm; the sole interactive moment is pending reconciliation (§9), and only
when pending files exist.

## 1. Session-artifact resolution

Derive from `cwd` and the current session (Claude Code's project-slug rule):

- **`<cwd-slug>`** — the absolute `cwd` with every `/` and `.` replaced by `-`
  (e.g. `/workspace/docs` -> `-workspace-docs`).
- **Main transcript** — the newest `*.jsonl` directly under
  `~/.claude/projects/<cwd-slug>/`. Its basename minus `.jsonl` is `session_id`.
- **`<sid8>`** — the first 8 characters of `session_id`.
- **Subagents dir** — `~/.claude/projects/<cwd-slug>/<session_id>/subagents/`
  (holds `agent-*.jsonl` with their own Sonnet/other `usage` + `model`).

## 2. Cost computation (`session-cost.py`)

Invoke the shipped helper (stdlib-only, pure computation, no specs-repo writes):

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/session-cost.py" \
  --transcript    <main transcript .jsonl (§1)> \
  --subagents-dir <subagents dir (§1)> \
  --prices        <resolved price table (§4)> \
  --checkpoint    ~/.claude/dev-workflows/cost-state/<session_id>.json \
  --snapshot      ~/.claude/dev-workflows/cost-snapshots/<session_id>.json \
  --now-ts        <current UTC ISO8601>
```

The helper reads the main transcript **from the checkpoint's line offset
forward** (O(command), not O(session) — the transcript can be tens of MB) plus
every `subagents/agent-*.jsonl` entry with `timestamp` in `(last_ts, now]`,
groups `usage` by `model`, applies the price table, and prints JSON to stdout:

```json
{
  "models": [
    {"model": "...", "cost_usd": 0.0, "input_tokens": 0, "output_tokens": 0,
     "cache_read_tokens": 0, "cache_write_tokens": 0}
  ],
  "cost_computed_usd": 0.0,
  "cost_statusline_usd": null,
  "duration_s": 0,
  "new_checkpoint": {"line_offset": 0, "last_ts": "...Z", "last_snapshot_cost": null}
}
```

An unknown model (absent from the table) is recorded with its tokens,
`cost_usd: null`, and `note: unpriced-model` — the run never fails. `emit-cost`
formats `models` + `cost_computed_usd` + `cost_statusline_usd` + `duration_s`
into the entry (§6) and writes `new_checkpoint` back (§3).

## 3. Chained-checkpoint model

Single touchpoint per command; a command's window START is the previous
dev-workflows command's END in the same session.

- **Checkpoint file:** `~/.claude/dev-workflows/cost-state/<session_id>.json` —
  per-user, per-session, **transient/local, NEVER committed** (safe to delete).
- **Contents:** `{line_offset, last_ts, last_snapshot_cost}` captured at the END
  of the last cost phase.
- **First command in a session:** no checkpoint -> `line_offset: 0`,
  `last_ts: null` -> the window starts at the session origin (start = $0).
- **Advance ALWAYS.** After computing, write `session-cost.py`'s `new_checkpoint`
  back to the checkpoint file — **even in the pending / report-only tiers (§8),
  so the next command's window is correct.** The write is a plain overwrite of
  the transient local file (no git, no specs repo).
- **Semantics (for users):** the whole session's spend is attributed to the VI;
  activity between commands rolls into the next command's bucket; the
  pre-first-command and post-last-command tails are unattributed (~0 for a clean
  per-VI container session). Per-command costs therefore sum to the session total
  minus those tails.

## 4. Price table

`references/cost-prices.yaml`, keyed by model id, **USD per million tokens**
(`input`, `output`, `cache_read`, `cache_write_5m`, `cache_write_1h`, plus a
top-level `default: null`). Cache multipliers follow Anthropic's standard model
(read 0.1x, 5m write 1.25x, 1h write 2x); the transcript's `ephemeral_5m` /
`ephemeral_1h` split lets cache pricing be exact, and a message without the split
prices `cache_creation_input_tokens` at the 5m rate.

**Resolution order (first found wins):** `$DEV_WORKFLOWS_COST_PRICES` (a path) ->
a repo-local `cost-prices.yaml` -> the shipped
`${CLAUDE_PLUGIN_ROOT}/references/cost-prices.yaml`. The shipped rates are
maintainer-verified placeholders; exact dollar accuracy is not required.

## 5. Statusline augmentation (optional — "Option B")

An authoritative cross-check, available only when the plugin statusline is
installed (via `/statusline`):

- The shipped statusline writes a snapshot each render:
  `~/.claude/dev-workflows/cost-snapshots/<session_id>.json = { ts, cost_usd }`
  from its stdin `.cost.total_cost_usd` (an overwrite of a single object each
  render — bounded size).
- `emit-cost` passes `--snapshot`; `session-cost.py` sets `cost_statusline_usd` =
  (current snapshot `cost_usd`) - (the `last_snapshot_cost` stored in the
  checkpoint) — a **per-invocation delta on this entry only**, chained
  identically to Option A. **Never an aggregate, never a shared source of truth**
  -> immune to the merge concern.
- **Auto-detect:** if the snapshot file exists, the field is emitted; otherwise
  it is `null` and simply omitted from the entry. No configuration.
- **Boundary caveat:** B is authoritative on price but lags at the tail (the
  statusline renders *after* the final turn); A reads the per-turn transcript so
  it is more complete at the boundary. The two differing by cents is the intended
  calibration signal (drift => refresh the price table).
- Pending a one-line implementation check that `.cost.total_cost_usd` is present
  on the statusline stdin in the target Claude Code version; if absent, B is
  simply unavailable and A stands alone.

## 6. Report artifact & entry format

**Location (merge-safe by construction):** one file per session under the VI's
shared area — `<VI-dir>/dev-workflows/cost/<sid8>.md`. No two sessions share a
file -> no merge conflicts across many teams or one person's N sessions. **No
user name anywhere in the file** (§10).

File-level frontmatter (written once on creation):

```yaml
---
type: dev-workflows-cost
vi: PRODUCT-14902
session: <sid8>
---
```

One appended entry per command invocation (append-only, **never deduped** — each
invocation is a distinct measurement, so `/design Epic1` then `/design Epic2` in
one session are two lines):

````markdown
## 2026-07-09T14:22:33Z — /implement — implementation

```yaml
id: PRODUCT-14902-15001-implement-2026-07-09T14:22:33Z   # timestamp => unique
date: 2026-07-09T14:22:33Z
command: /implement
phase: implementation
role: dev
vi: PRODUCT-14902
epic: PRODUCT-15001            # present only when an Epic key is in scope
plugin_version: 2.10.0
duration_s: 1284
cost_computed_usd: 3.4821
cost_statusline_usd: 3.5102   # present only when the plugin statusline is installed
models:
  - {model: claude-opus-4-8, cost_usd: 2.9114, input_tokens: 12043, output_tokens: 88210, cache_read_tokens: 2109887, cache_write_tokens: 145002}
  - {model: claude-sonnet-5, cost_usd: 0.5707, input_tokens: 45120, output_tokens: 210334, cache_read_tokens: 880122, cache_write_tokens: 42011}
```
````

Machine-friendly YAML so the maintainer can filter/sum with Claude Code. No prose
block (unlike feedback). `cost_statusline_usd` is omitted when Option B is
unavailable; a model priced `null` carries `note: unpriced-model`.

## 7. Attribution (phase / role / keys)

Fixed per-command labels, with one inferred exception:

| Command | phase | role |
|---------|-------|------|
| `/specify` | specification | pe |
| `/epics` | epic-refinement | pe |
| `/design` | planning | dev |
| `/implement` | implementation | dev |
| `/document` | documenting | dev |
| `/release-notes` | **inferred** | **inferred** |
| future idea-refine / create-VI | vi-creation | pm |

**`/release-notes` inference (PM VI-run vs. dev documenting-run).** The
discriminator is the presence of **downstream engineering artifacts** — any
`specification.md` or `design.md` under the VI's specs dir:

- **None present -> `phase: vi-creation`, `role: pm`** (the PM's early run: the VI
  exists but no engineering work has started — Epics may or may not exist yet,
  which is fine, since a freshly created VI with no Epics is exactly the PM case).
- **Either present -> `phase: documenting`, `role: dev`** (the dev re-run, when
  VI + Epics + specs + design + code all exist).

**Epic presence is deliberately NOT part of the signal** — a VI can have drafted
Epics while still in PM/PE hands, so keying on Epics would misattribute the PM
run. Cheap to check; matches the real workflow. Still a heuristic —
reattributable at aggregation time (cost < quality).

**Keys.** Reuse the existing VI-dir resolution (the two-key `<VI> <Epic>` grammar
+ specs-dir matching already used by feedback/followups). Record `vi` always and
`epic` when an Epic key is in scope.

## 8. Persistence ladder (specs-first; never cwd)

Reuse `feedback-emission.md`'s specs-first ladder, targeting the **`cost/`**
subdir. Walk top-down; stop at the first tier that applies:

1. `$SPECS_PATH` writable **and** the VI dir exists (matched by
   `$SPECS_PATH/{specs|specifications|vis}/…/<KEY>{-|_}<slug>/…`) ->
   `<VI-dir>/dev-workflows/cost/<sid8>.md`. *[primary]*
2. `$SPECS_PATH` writable but no VI dir (or no key resolved) -> **pending** (§9).
3. No `$SPECS_PATH`, vault writable (`$VAULT_PATH` set **and**
   `$VAULT_PATH/.obsidian/` a writable dir) ->
   `$VAULT_PATH/dev-workflows/cost/<sid8>.md` with the loud notice:
   `⚠ $SPECS_PATH unavailable — saved to your vault; it will NOT auto-aggregate to the maintainer.`
4. `source = directory` (imported Jira dir, no specs/vault) -> beside the
   imported directory.
5. Nothing resolvable -> **report-only** in the run output. **NEVER write into the
   current working directory** — it may be a code repo.

The run never fails, and **the checkpoint (§3) still advances in every tier** so
the next command's window is correct. A write that fails mid-write (read-only
mount / permission) drops to the next tier with the same notice.

## 9. Pending & reconciliation (keyless runs)

When no VI key resolves (idea refinement, pre-VI work), write the entry to a
pending file:

```
$SPECS_PATH/dev-workflows-cost/pending-<date>-<sid8>.md
```

(same `type: dev-workflows-cost` format; `vi: n/a`).

**Opportunistic suggest-and-confirm reconciliation.** Whenever any command
resolves a VI key **and** pending files exist, the cost phase lists them (each
summarized by date / session / commands / total) and offers to relocate their
entries into `<VI-dir>/dev-workflows/cost/<sid8>.md`:

- **Same-session `<sid8>` match is pre-selected** as the likely one -> the
  create-in-markdown -> create-in-Jira -> import -> keyed-command flow becomes
  effectively one tap.
- New-session pending files are listed for the user to pick.
- No match -> leave for manual relocation, or accept the partial loss.
- **Relocation moves, then DELETES.** On a confirmed relocation the pending
  file's entries are appended into `<VI-dir>/dev-workflows/cost/<sid8>.md` and the
  **pending file is deleted** (move, not copy) so it never re-surfaces. Each
  pending file is relocated atomically; a failed/partial move leaves the file in
  place for a safe retry. Pending files the user *declines* are left in place and
  may be offered again next time (expected — the user chose not to file them).

This is the **only** interactive moment in the cost subsystem, and only when
pending files exist; the cost write itself is always silent.

## 10. Privacy

No user name is written to any cost file — filenames use `<sid8>`, not identity;
entries carry no author. The git commit author remains the only identity layer,
once the engineer commits and pushes the specs — outside this feature's control
and acceptable.

## 11. Caller contract — `emit-cost`

One entry point. Every caller supplies `command`, `phase`, `role` (or the
`inferred` marker for `/release-notes`), `jira_key` (or `null`), `source`, and
`plugin_version`. `emit-cost` does the rest; it NEVER commits, NEVER writes into
a docs/code repo or the current working directory, and NEVER fails the run. Cost
ALWAYS runs.

Inputs:
- `command` — the exact slash-command name (e.g. `/implement`,
  `/document (Jira mode)`, `/document (direct mode)`).
- `phase`, `role` — the §7 labels; for `/release-notes` pass `inferred` and let
  §7 resolve them from `specification.md` / `design.md` presence.
- `jira_key` (or `null`), `source` (`vault | directory | none`).
- `plugin_version` — read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
  (`python3 -c "import json;print(json.load(open('<path>'))['version'])"`).

Behavior:
1. Resolve session artifacts (§1) and the price table (§4).
2. Run `session-cost.py` (§2) with the checkpoint (§3) and, when present, the
   snapshot (§5).
3. Apply attribution (§7); build the per-invocation entry (§6).
4. Resolve the target via the ladder (§8); on a keyless run write pending and run
   opportunistic reconciliation (§9).
5. Append the entry (create the file with frontmatter on first write).
6. **Write `new_checkpoint` back (§3) in EVERY tier**, including pending /
   report-only.
7. Return the persisted path (or the report-only notice) as the phase's output.
`````

- [ ] **Step 2: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '^## 8. Persistence ladder (specs-first; never cwd)' plugins/dev-workflows/references/cost-emission.md
grep -n 'type: dev-workflows-cost' plugins/dev-workflows/references/cost-emission.md
grep -n '<VI-dir>/dev-workflows/cost/<sid8>.md' plugins/dev-workflows/references/cost-emission.md
grep -c '## 11. Caller contract — `emit-cost`' plugins/dev-workflows/references/cost-emission.md
grep -n 'NEVER write into the' plugins/dev-workflows/references/cost-emission.md
grep -n 'pending file is deleted' plugins/dev-workflows/references/cost-emission.md
grep -n 'phase: vi-creation`, `role: pm' plugins/dev-workflows/references/cost-emission.md
grep -n 'advance the checkpoint\|Advance ALWAYS\|EVERY tier' plugins/dev-workflows/references/cost-emission.md
git status --porcelain plugins/dev-workflows/references/cost-emission.md
```
Expected: the ladder / frontmatter / VI-dir / cwd / delete / inference / advance greps each return ≥1 line; the `emit-cost` heading count is `1`; `git status --porcelain` shows exactly `?? plugins/dev-workflows/references/cost-emission.md`.

- [ ] **Step 3: Commit**

```bash
git add plugins/dev-workflows/references/cost-emission.md
git commit --no-verify -m "$(cat <<'EOF'
feat(dev-workflows): add session-cost emitter reference (SSOT)

New references/cost-emission.md — the single source of truth for session cost
reporting: session-artifact resolution (cwd-slug + newest transcript), the
chained-checkpoint model (advance ALWAYS, even report-only), session-cost.py
invocation, the price table + $DEV_WORKFLOWS_COST_PRICES override, the
machine-friendly per-invocation entry format written to
<VI-dir>/dev-workflows/cost/<sid8>.md (per-session -> merge-safe), the
specs-first persistence ladder, pending + opportunistic move-then-delete
reconciliation, the optional statusline cross-check (Option B), attribution
incl. the /release-notes PM-vs-dev inference (keyed on specification.md /
design.md presence, never Epics), privacy (no user name), and the single
emit-cost caller contract. Self-contained; does not use impl-maintenance.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: `/statusline` installer — `commands/statusline.md` + vendored `scripts/statusline-command.sh`

**Suggested model:** Sonnet.

**Files:**
- Create: `plugins/dev-workflows/scripts/statusline-command.sh` (verbatim vendor of the user's statusline script + the §8 snapshot-write block)
- Create: `plugins/dev-workflows/commands/statusline.md` (the installer command)

**Interfaces:**
- The vendored script consumes Claude Code's statusline stdin (`.cost.total_cost_usd`, `.session_id`, …) and, as an ADDITION, writes `{ts, cost_usd}` to `~/.claude/dev-workflows/cost-snapshots/<session_id>.json` each render — the Option B enabler consumed by `cost-emission.md` §5 / `session-cost.py --snapshot`.
- `/statusline` produces the installed status line + the `statusLine` block in `~/.claude/settings.json`. It adds no runtime dependency for the cost subsystem (Option A works without it).

- [ ] **Step 1: Vendor the script verbatim**

Copy the user's statusline script into the plugin unchanged (a byte-exact vendor — do NOT hand-retype it):

```bash
cd /workspace/ihudak-claude-plugins
cp /home/ivan.gudak/.claude/statusline-command.sh plugins/dev-workflows/scripts/statusline-command.sh
```

If `/home/ivan.gudak/.claude/statusline-command.sh` is not present at execution time, obtain the current statusline script the user runs and vendor that; the only plugin-specific change is the Step 2 snapshot block.

- [ ] **Step 2: Add the §8 snapshot-write block**

In `plugins/dev-workflows/scripts/statusline-command.sh`, find this exact block (the direct-cost resolution near the top of the "session cost" section):

```
if [ -n "$cost_direct" ] && [ "$cost_direct" != "null" ]; then
  session_cost=$(printf "%.4f" "$cost_direct")
fi
```

Replace it with (the same block, then the snapshot-write appended):

```
if [ -n "$cost_direct" ] && [ "$cost_direct" != "null" ]; then
  session_cost=$(printf "%.4f" "$cost_direct")
fi

# ── dev-workflows cost snapshot (Option B enabler) ────────────────────────────
# Persist the authoritative session cost (.cost.total_cost_usd) so the
# dev-workflows terminal cost phase can cross-check its transcript-computed
# estimate. Overwrites a single-object snapshot each render (bounded size).
# Fully silent — never alters the rendered status line, never fails the render.
if [ -n "$cost_direct" ] && [ "$cost_direct" != "null" ] \
   && [ -n "$session_id" ] && [ "$session_id" != "null" ]; then
  _dw_snap_dir="$HOME/.claude/dev-workflows/cost-snapshots"
  if mkdir -p "$_dw_snap_dir" 2>/dev/null; then
    printf '{"ts":"%s","cost_usd":%s}\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$session_cost" \
      > "$_dw_snap_dir/${session_id}.json" 2>/dev/null
  fi
fi
```

(`session_id` is already resolved near the top of the script; `session_cost` here equals the formatted `.cost.total_cost_usd`.)

- [ ] **Step 3: Write `commands/statusline.md`**

Create `plugins/dev-workflows/commands/statusline.md` with EXACTLY this content:

````markdown
---
name: statusline
description: Install the dev-workflows multi-line status line (session identity, git, context bar, cost, tokens, rate limits) into your Claude Code settings. Vendors the script to a stable per-user path, backs up anything it would overwrite, and enables the Option B cost snapshot used by session cost reporting.
allowed-tools: Read Write Edit Bash
---

Install the dev-workflows status line: $ARGUMENTS

`/statusline` installs the plugin's multi-line, truecolor status line and wires
it into `~/.claude/settings.json`. The shipped script also writes the per-session
**cost snapshot** that enables Option B of session cost reporting (see
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` §5). Installation is
**idempotent** and **backs up** anything it would overwrite. This is the only
change the command makes; it changes no workflow-command behavior.

---

## Phase 1 — Resolve paths

1. Source script: `${CLAUDE_PLUGIN_ROOT}/scripts/statusline-command.sh`.
2. Stable install path: `~/.claude/dev-workflows/statusline-command.sh`
   (per-user, survives plugin re-installs). Create `~/.claude/dev-workflows/` if
   missing.
3. Settings file: `~/.claude/settings.json`.

## Phase 2 — Preflight & back up

1. Read `~/.claude/settings.json` (treat a missing file as `{}`).
2. If a `statusLine` block already exists, print it and **back it up** to
   `~/.claude/settings.json.dev-workflows.bak` (do NOT overwrite an existing
   backup — suffix `-2`, `-3`, … ).
3. If `~/.claude/dev-workflows/statusline-command.sh` already exists, back it up
   the same way (`.bak`, then `-2`, … ) before overwriting.
4. Verify `bash` and `jq` are available; if `jq` is missing, do the Phase 4 JSON
   merge with `python3` instead — never hand-edit `settings.json` blindly.

## Phase 3 — Install the script

Copy the source script to the stable install path and `chmod +x` it. Verify it is
non-empty and begins with a `#!` shebang.

## Phase 4 — Merge the settings block (confirm first)

Show the user the exact change and ask to confirm
(`choices: ["Install", "Cancel", "Other… (describe)"]`) BEFORE writing settings.
On confirm, MERGE (never clobber sibling keys) so that:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/dev-workflows/statusline-command.sh"
  }
}
```

Use `jq '. + {statusLine: {type:"command", command:"bash ~/.claude/dev-workflows/statusline-command.sh"}}'`
(or the `python3` `json` equivalent), writing to a temp file and moving it into
place, so a failed merge never truncates `settings.json`. Preserve all other keys.

## Phase 5 — Report

Confirm the install path, the settings change, and any backups created. Tell the
user the status line takes effect on the next render / new session, and that the
per-session cost snapshot (Option B) is now enabled. This command NEVER commits
and writes only under `~/.claude/`.
````

- [ ] **Step 4: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
bash -n plugins/dev-workflows/scripts/statusline-command.sh && echo "bash -n OK"
grep -n 'dev-workflows cost snapshot (Option B enabler)' plugins/dev-workflows/scripts/statusline-command.sh
grep -n 'cost-snapshots' plugins/dev-workflows/scripts/statusline-command.sh
grep -n '^name: statusline$' plugins/dev-workflows/commands/statusline.md
grep -c 'cost-emission.md' plugins/dev-workflows/commands/statusline.md
# The vendored script differs from the source ONLY by the added snapshot block (comment + guarded write):
diff <(sed '/# ── dev-workflows cost snapshot (Option B enabler)/,/^fi$/d' plugins/dev-workflows/scripts/statusline-command.sh) /home/ivan.gudak/.claude/statusline-command.sh && echo "vendor == source (minus snapshot block)"
git status --porcelain plugins/dev-workflows/scripts/statusline-command.sh plugins/dev-workflows/commands/statusline.md
```
Expected: `bash -n OK`; the snapshot-block comment and `cost-snapshots` greps each return ≥1 line; `name: statusline` returns one line; `cost-emission.md` ≥ 1; the `diff` prints `vendor == source (minus snapshot block)` (the vendored script equals the source once the inserted block is stripped — if the `sed` range is imperfect on your copy, instead eyeball the `git diff` of the two files); `git status --porcelain` shows exactly the two new `??` files. (If the source file is unavailable, skip the `diff` check and rely on `bash -n` + the snapshot greps.)

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/scripts/statusline-command.sh plugins/dev-workflows/commands/statusline.md
git commit --no-verify -m "$(cat <<'EOF'
feat(dev-workflows): add /statusline installer + vendored status line

New commands/statusline.md installs the plugin's multi-line status line into
~/.claude/settings.json — copies the vendored script to a stable per-user path
(~/.claude/dev-workflows/statusline-command.sh), backs up any existing script and
statusLine block, and merges the statusLine block idempotently after confirming.
New scripts/statusline-command.sh is the verbatim vendor of the user's status
line plus one silent addition: each render it writes {ts, cost_usd} from
.cost.total_cost_usd to ~/.claude/dev-workflows/cost-snapshots/<session_id>.json,
enabling the Option B cross-check in session cost reporting. Additive; writes
only under ~/.claude/; never commits.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Wire the terminal cost phase into `/specify`, `/design`, `/release-notes`

Add a concise terminal **Session cost** phase — a citation of `cost-emission.md` `emit-cost`, NOT a re-explanation of the mechanism — as the NEW final operational phase, AFTER the existing feedback phase and BEFORE each command's unique terminal heading. `emit-cost` is defined in T2 (§11); the phase just calls it.

**Files:**
- Modify: `plugins/dev-workflows/commands/specify.md` (new **Phase 9** before `## Final report`)
- Modify: `plugins/dev-workflows/commands/design.md` (new **Phase 9** before `## Final report`)
- Modify: `plugins/dev-workflows/commands/release-notes.md` (new **Phase 11** before `## Invariants (always enforced)`)

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` (T2), entry point `emit-cost`; each run's `jira_key` and `source`.
- Produces: nothing cross-task (self-contained command behavior).

- [ ] **Step 1: `specify.md` — insert Phase 9 before `## Final report`**

Find this exact line (the unique terminal heading; its body stays untouched below the new phase):

```
## Final report
```

Replace it with:

```
## Phase 9 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 8 (feedback)
and NEVER interrupts an earlier phase. Records this command's token-cost
contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /specify`, `phase: specification`, `role: pe`,
the run's `jira_key` (or `null`) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<VI-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no VI key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is offered only in
Phase 7), and NEVER writes into a docs/code repo or the current working
directory; no user name is ever written (§10 privacy).

## Final report
```

- [ ] **Step 2: `design.md` — insert Phase 9 before `## Final report`**

Find this exact line:

```
## Final report
```

Replace it with:

```
## Phase 9 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 8 (feedback)
and NEVER interrupts an earlier phase. Records this command's token-cost
contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /design`, `phase: planning`, `role: dev`, the
run's `jira_key` (or `null`) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<VI-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no VI key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is offered only in
Phase 7), and NEVER writes into a docs/code repo or the current working
directory; no user name is ever written (§10 privacy).

## Final report
```

- [ ] **Step 3: `release-notes.md` — insert Phase 11 before `## Invariants`**

Find this exact block (the terminal Invariants heading + its unique first bullet; the existing `---` above stays as the separator after Phase 10):

```
## Invariants (always enforced)

- ZERO external API calls — PR URLs are identifiers only; all resolution is local `git`.
```

Replace it with:

```
## Phase 11 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 10 (feedback)
and NEVER interrupts an earlier phase. Records this command's token-cost
contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs**.

`/release-notes` runs at two different phases by two roles (a PM's early bare-VI
run and a dev's documenting re-run), so DO NOT pass a fixed phase/role: call
`emit-cost` with `command: /release-notes`, `phase: inferred`, `role: inferred`,
the run's `jira_key` (or `null`) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). `emit-cost` applies the §7
inference: **no `specification.md` or `design.md` under the VI's specs dir ->
`phase: vi-creation`, `role: pm`; either present -> `phase: documenting`, `role:
dev`.** Epic presence is deliberately NOT part of the signal. It then resolves
the transcript + subagents (§1), **advances the chained checkpoint** (§3), runs
`scripts/session-cost.py` against the price table (§4), records the optional
statusline cross-check (§5), and appends one entry to
`<VI-dir>/dev-workflows/cost/<sid8>.md` via the specs-first ladder (§8) — pending
+ reconciliation (§9) when no VI key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits, NEVER makes an external
API call, and NEVER writes into a docs repo or the current working directory; no
user name is ever written (§10).

---

## Invariants (always enforced)

- ZERO external API calls — PR URLs are identifiers only; all resolution is local `git`.
```

- [ ] **Step 4: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '## Phase 9 — Session cost' plugins/dev-workflows/commands/specify.md
grep -n '## Phase 9 — Session cost' plugins/dev-workflows/commands/design.md
grep -n '## Phase 11 — Session cost' plugins/dev-workflows/commands/release-notes.md
for f in specify design release-notes; do
  echo "--- $f: cost-emission.md=$(grep -c 'cost-emission.md' plugins/dev-workflows/commands/$f.md) emit-cost=$(grep -c 'emit-cost' plugins/dev-workflows/commands/$f.md)"
done
# Ordering: cost phase AFTER the feedback phase, BEFORE the terminal heading.
awk '/## Phase 8 — Session maintenance & feedback/{fb=NR} /## Phase 9 — Session cost/{c=NR} /## Final report/{t=NR} END{print "specify fb="fb" cost="c" term="t; exit !(fb<c && c<t)}' plugins/dev-workflows/commands/specify.md
awk '/## Phase 8 — Session maintenance & feedback/{fb=NR} /## Phase 9 — Session cost/{c=NR} /## Final report/{t=NR} END{print "design fb="fb" cost="c" term="t; exit !(fb<c && c<t)}' plugins/dev-workflows/commands/design.md
awk '/## Phase 10 — Session maintenance & feedback/{fb=NR} /## Phase 11 — Session cost/{c=NR} /## Invariants \(always enforced\)/{t=NR} END{print "release-notes fb="fb" cost="c" term="t; exit !(fb<c && c<t)}' plugins/dev-workflows/commands/release-notes.md
grep -c '## Final report' plugins/dev-workflows/commands/specify.md
grep -c '## Final report' plugins/dev-workflows/commands/design.md
grep -c '## Invariants (always enforced)' plugins/dev-workflows/commands/release-notes.md
git diff --stat plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/design.md plugins/dev-workflows/commands/release-notes.md
```
Expected: each cost-phase heading grep returns one line; `cost-emission.md` and `emit-cost` each `1` per file; each `awk` prints `fb<cost<term` and exits 0 (cost phase sits after the feedback phase and before the terminal heading); `## Final report` still `1` in specify and design; `## Invariants (always enforced)` still `1` in release-notes; `--stat` lists exactly the three files.

- [ ] **Step 5: Commit**

```bash
git add plugins/dev-workflows/commands/specify.md plugins/dev-workflows/commands/design.md plugins/dev-workflows/commands/release-notes.md
git commit --no-verify -m "$(cat <<'EOF'
feat(dev-workflows): terminal cost phase for /specify, /design, /release-notes

Each gains a terminal Session cost phase (the new final operational phase, after
the feedback phase, before the terminal heading) that cites cost-emission.md and
calls emit-cost: /specify (specification/pe), /design (planning/dev),
/release-notes (phase/role inferred from specification.md / design.md presence,
never Epics). Cost always runs and always advances the chained checkpoint, even
report-only. Additive — never fails, commits, or writes into the cwd; no user
name written.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Wire the terminal cost phase into `/epics`, `/implement`, `/document` (×2)

Same pattern as T4. `document.md` has **two** terminal regions (Mode A + Mode B), each ending in its own `## Invariants (always enforced)` — so **two** cost-phase insertions, disambiguated by each mode's unique first invariant bullet.

**Files:**
- Modify: `plugins/dev-workflows/commands/epics.md` (new **Phase 11** before `## Invariants (always enforced)`)
- Modify: `plugins/dev-workflows/commands/implement.md` (new **Phase 7** before `## Invariants (always enforced)`)
- Modify: `plugins/dev-workflows/commands/document.md` (new **Phase 11** before Mode A `## Invariants`; new **Phase 7** before Mode B `## Invariants`)

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` (T2), entry point `emit-cost`; each run's `jira_key` and `source`.
- Produces: nothing cross-task.

- [ ] **Step 1: `epics.md` — insert Phase 11 before `## Invariants`**

Find this exact block:

```
## Invariants (always enforced)

- ALWAYS resolve input via the shared Jira-input front-end (Phase 0) — a JiraID requires `$VAULT_PATH`; an imported-Jira directory works without it; `/epics` is cwd-agnostic and rejects `mode: direct`
```

Replace it with:

```
## Phase 11 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 10 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /epics`, `phase: epic-refinement`, `role: pe`,
the run's `jira_key` (or `null`) and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<VI-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no VI key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits (git is the user's
responsibility), and NEVER writes into `jira-products/`, `jira_export_root`, or
the current working directory; no user name is ever written (§10 privacy).

---

## Invariants (always enforced)

- ALWAYS resolve input via the shared Jira-input front-end (Phase 0) — a JiraID requires `$VAULT_PATH`; an imported-Jira directory works without it; `/epics` is cwd-agnostic and rejects `mode: direct`
```

- [ ] **Step 2: `implement.md` — insert Phase 7 before `## Invariants`**

Find this exact block:

```
## Invariants (always enforced)

- NEVER skip Phase 1.5 classification — every run must state the level
```

Replace it with:

```
## Phase 7 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 6 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /implement`, `phase: implementation`,
`role: dev`, the run's `jira_key` (or `null`) and `source`, and `plugin_version`
(read from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the
session transcript + subagents (§1), loads and **advances the chained
checkpoint** (§3), runs `scripts/session-cost.py` to compute the per-model
token-cost delta against the price table (§4), records the optional statusline
cross-check (§5), and appends one per-invocation entry to
`<VI-dir>/dev-workflows/cost/<sid8>.md` via the specs-first ladder (§8) — pending
+ opportunistic move-then-delete reconciliation (§9) when no VI key resolves.
**The checkpoint advances even in the pending / report-only tiers.** Surface the
persisted path (or the report-only notice) as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits, and NEVER writes into
the code repo or the current working directory; no user name is ever written
(§10 privacy).

---

## Invariants (always enforced)

- NEVER skip Phase 1.5 classification — every run must state the level
```

- [ ] **Step 3: `document.md` — insert Mode A Phase 11 before Mode A `## Invariants`**

Find this exact block (Mode A's terminal Invariants — its unique first bullet disambiguates it from Mode B's):

```
## Invariants (always enforced)

- ALWAYS run Phase 0 docs-repo detection; if 0 signals, require user confirmation before proceeding
```

Replace it with:

```
## Phase 11 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 10 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /document (Jira mode)`, `phase: documenting`,
`role: dev`, the run's `jira_key` and `source`, and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<VI-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no VI key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits, and NEVER writes into
the docs repo or the current working directory; no user name is ever written
(§10 privacy).

---

## Invariants (always enforced)

- ALWAYS run Phase 0 docs-repo detection; if 0 signals, require user confirmation before proceeding
```

- [ ] **Step 4: `document.md` — insert Mode B Phase 7 before Mode B `## Invariants`**

Find this exact block (Mode B's terminal Invariants — its unique first bullet disambiguates it from Mode A's):

```
## Invariants (always enforced)

- ALWAYS run Phase 3.5 (style check) after editing — `docs-style-checker` falls back to `dt-style-checker`; never skip style on tool-absence judgement
```

Replace it with:

```
## Phase 7 — Session cost

Terminal phase — the NEW final operational phase; runs after Phase 6 (the
follow-up phase) and NEVER interrupts an earlier phase. Records this command's
token-cost contribution to the VI by citing
`${CLAUDE_PLUGIN_ROOT}/references/cost-emission.md` and calling its single
`emit-cost` entry point. Unlike feedback, **cost ALWAYS runs** — it never "writes
nothing".

Call `emit-cost` with `command: /document (direct mode)`, `phase: documenting`,
`role: dev`, the run's `jira_key` (usually `null` in direct mode) and `source`,
and `plugin_version` (read from
`${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`). It resolves the session
transcript + subagents (§1), loads and **advances the chained checkpoint** (§3),
runs `scripts/session-cost.py` to compute the per-model token-cost delta against
the price table (§4), records the optional statusline cross-check (§5), and
appends one per-invocation entry to `<VI-dir>/dev-workflows/cost/<sid8>.md` via
the specs-first ladder (§8) — pending + opportunistic move-then-delete
reconciliation (§9) when no VI key resolves. **The checkpoint advances even in
the pending / report-only tiers.** Surface the persisted path (or the
report-only notice) as this phase's only output.

ADDITIVE — this phase NEVER fails the run, NEVER commits, and NEVER writes into
the docs repo or the current working directory; no user name is ever written
(§10 privacy).

---

## Invariants (always enforced)

- ALWAYS run Phase 3.5 (style check) after editing — `docs-style-checker` falls back to `dt-style-checker`; never skip style on tool-absence judgement
```

- [ ] **Step 5: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
grep -n '## Phase 11 — Session cost' plugins/dev-workflows/commands/epics.md
grep -n '## Phase 7 — Session cost' plugins/dev-workflows/commands/implement.md
grep -c '## Phase 11 — Session cost' plugins/dev-workflows/commands/document.md   # Mode A: expect 1
grep -c '## Phase 7 — Session cost' plugins/dev-workflows/commands/document.md    # Mode B: expect 1
grep -c 'cost-emission.md' plugins/dev-workflows/commands/document.md             # expect 2
grep -c 'command: /document (Jira mode)' plugins/dev-workflows/commands/document.md   # expect 1
grep -c 'command: /document (direct mode)' plugins/dev-workflows/commands/document.md # expect 1
for f in epics implement; do echo "--- $f cost-emission.md=$(grep -c 'cost-emission.md' plugins/dev-workflows/commands/$f.md) emit-cost=$(grep -c 'emit-cost' plugins/dev-workflows/commands/$f.md)"; done
# Ordering: cost phase AFTER the follow-up phase, BEFORE the terminal Invariants heading.
awk '/## Phase 10 — Emit follow-up tasks/{fu=NR} /## Phase 11 — Session cost/{c=NR} /## Invariants \(always enforced\)/{t=NR} END{print "epics fu="fu" cost="c" term="t; exit !(fu<c && c<t)}' plugins/dev-workflows/commands/epics.md
awk '/## Phase 6 — Emit follow-up tasks/{fu=NR} /## Phase 7 — Session cost/{c=NR} /## Invariants \(always enforced\)/{t=NR} END{print "implement fu="fu" cost="c" term="t; exit !(fu<c && c<t)}' plugins/dev-workflows/commands/implement.md
# document: both Invariants headings still present (Mode A + Mode B) = 2
grep -c '## Invariants (always enforced)' plugins/dev-workflows/commands/document.md   # expect 2
git diff --stat plugins/dev-workflows/commands/epics.md plugins/dev-workflows/commands/implement.md plugins/dev-workflows/commands/document.md
```
Expected: the epics/implement cost-phase greps return one line each; document has `## Phase 11 — Session cost` = 1 and `## Phase 7 — Session cost` = 1; `cost-emission.md` = 2 in document.md; both `command: /document (…)` greps = 1; `cost-emission.md` and `emit-cost` = 1 each in epics + implement; both `awk` checks print `fu<cost<term` and exit 0; `## Invariants (always enforced)` still = 2 in document.md (both modes preserved); `--stat` lists exactly the three files.

- [ ] **Step 6: Commit**

```bash
git add plugins/dev-workflows/commands/epics.md plugins/dev-workflows/commands/implement.md plugins/dev-workflows/commands/document.md
git commit --no-verify -m "$(cat <<'EOF'
feat(dev-workflows): terminal cost phase for /epics, /implement, /document

Each gains a terminal Session cost phase (the new final operational phase, after
the follow-up phase, before the Invariants heading) that cites cost-emission.md
and calls emit-cost: /epics (epic-refinement/pe), /implement (implementation/dev),
/document Mode A (Jira mode, documenting/dev) + Mode B (direct mode,
documenting/dev) — two insertions in document.md, disambiguated by each mode's
first Invariants bullet. Cost always runs and always advances the chained
checkpoint, even report-only. Additive — never fails, commits, or writes into the
cwd; no user name written.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Release surfaces — v2.10.0 (versions, description, CHANGELOG, README)

**Suggested model:** Sonnet. Runs LAST (after `/statusline` exists so the command count is accurate).

**Files:**
- Modify: `plugins/dev-workflows/.claude-plugin/plugin.json` (version + description)
- Modify: `.claude-plugin/marketplace.json` (`dev-workflows` entry version + description)
- Modify: `plugins/dev-workflows/CHANGELOG.md` (prepend `[2.10.0]`)
- Modify: `plugins/dev-workflows/README.md` (new sections + Reference-docs bullet). Root README untouched.

**Interfaces:**
- Consumes: the behaviors from T1–T5 (accurate CHANGELOG/README prose) and the +1 command count.
- Produces: the released version surface.

- [ ] **Step 0: Recompute the command count (do NOT assert from memory)**

```bash
cd /workspace/ihudak-claude-plugins
ls -1 plugins/dev-workflows/commands/*.md | wc -l   # expect 16 (15 + /statusline)
```
Confirm the number word for Step 2 / Step 4 (`16` → "Sixteen"). If it is not 16, T3 has not landed — stop and fix ordering.

- [ ] **Step 1: Bump `plugin.json` version**

Find `  "version": "2.9.0",` and replace with `  "version": "2.10.0",`.

- [ ] **Step 2: Update `plugin.json` description (Fifteen → Sixteen; add `/statusline`)**

Find this exact substring:

```
Fifteen slash commands — /implement, /document, /docs-profile, /epics, /release-notes, /vuln, /upgrade, /api-guideline-reviewer, /guideline-reviewer, /specify, /design, /feedback, /prompt, /prompt-brainstorm, and /prompt-grill-me — with
```

Replace it with:

```
Sixteen slash commands — /implement, /document, /docs-profile, /epics, /release-notes, /vuln, /upgrade, /api-guideline-reviewer, /guideline-reviewer, /specify, /design, /feedback, /prompt, /prompt-brainstorm, /prompt-grill-me, and /statusline — with
```

Leave the "Twenty-six reusable subagents" and "four hooks" sentences unchanged (no subagent or hook added).

- [ ] **Step 3: Bump `marketplace.json` (dev-workflows entry version only)**

Find `      "version": "2.9.0",` (the dev-workflows entry — `2.9.0` is unique; siblings are `0.2.2` / `0.3.1`) and replace with `      "version": "2.10.0",`. Do NOT touch the `dt-style-guide` / `obsidian-llm-wiki` entries.

- [ ] **Step 4: Update `marketplace.json` description (same Fifteen → Sixteen edit)**

Find this exact substring (identical to Step 2's; it appears only in the `dev-workflows` entry):

```
Fifteen slash commands — /implement, /document, /docs-profile, /epics, /release-notes, /vuln, /upgrade, /api-guideline-reviewer, /guideline-reviewer, /specify, /design, /feedback, /prompt, /prompt-brainstorm, and /prompt-grill-me — with
```

Replace it with:

```
Sixteen slash commands — /implement, /document, /docs-profile, /epics, /release-notes, /vuln, /upgrade, /api-guideline-reviewer, /guideline-reviewer, /specify, /design, /feedback, /prompt, /prompt-brainstorm, /prompt-grill-me, and /statusline — with
```

- [ ] **Step 5: Prepend the CHANGELOG entry**

Find this exact block (the header preamble + the current top-most entry header):

```
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [2.9.0] — 2026-07-09
```

Replace it with (the preamble unchanged, the new entry, then the found `[2.9.0]` header unchanged):

```
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow semver at the plugin level.

## [2.10.0] — 2026-07-09

### Added

- **Session cost reporting — the plugin now records how many dollars a Value Increment cost across its lifecycle, by phase / role / model, persisted per-VI into the specs repo for the maintainer to aggregate.** Claude Code stores no dollar figure in the transcript, so cost is **computed**: a new stdlib-only engine `scripts/session-cost.py` reads the session's main transcript from a chained-checkpoint line offset forward plus the session's `subagents/agent-*.jsonl` within a `(last_ts, now]` window, sums `usage` by model, and applies the new `references/cost-prices.yaml` price table (USD per million tokens; the cache 5m/1h split priced exactly; unknown model → tokens recorded, cost `null`; overridable via `$DEV_WORKFLOWS_COST_PRICES`). A new shared reference `references/cost-emission.md` is the single source of truth: session-artifact resolution, the chained-checkpoint model (advance ALWAYS — even report-only), the machine-friendly per-invocation entry format written to `<VI-dir>/dev-workflows/cost/<sid8>.md` (one file per session → merge-safe under massive team fan-out), the specs-first persistence ladder (never the cwd), pending + opportunistic move-then-delete reconciliation for keyless runs, the optional statusline cross-check, attribution (incl. the `/release-notes` PM-vs-dev inference keyed on `specification.md` / `design.md` presence, never Epics), privacy (no user name in any cost file), and the single `emit-cost` caller contract.
- **Terminal cost phase across the six VI-lifecycle commands.** `/specify` (specification/pe), `/epics` (epic-refinement/pe), `/design` (planning/dev), `/implement` (implementation/dev), `/document` (documenting/dev — Mode A + Mode B), and `/release-notes` (phase/role inferred) gain a terminal Session cost phase — the new final operational phase, after the feedback phase — that cites `cost-emission.md` and calls `emit-cost`. Cost **always runs** and always advances the chained checkpoint (even report-only), so per-command costs sum to the session total. `/vuln` and `/upgrade` are deliberately out of scope (no VI to attribute to).
- **New command `/statusline`.** Installs the plugin's multi-line status line into `~/.claude/settings.json` (idempotent; backs up any existing script + `statusLine` block; confirms before writing). Its vendored script also writes a per-render `{ts, cost_usd}` snapshot from `.cost.total_cost_usd` to `~/.claude/dev-workflows/cost-snapshots/<session_id>.json`, enabling the Option B authoritative cross-check in session cost reporting.

Additive only — the `impl-maintenance` agent, `jira-reader`, the reviewers, the format references, and the sibling plugins (`dt-style-guide` 0.2.2, `obsidian-llm-wiki` 0.3.1) are untouched; no cost phase ever fails the run, commits, or writes into the current working directory, and no user name is written to any cost file.

## [2.9.0] — 2026-07-09
```

- [ ] **Step 6: Add the README `## Session cost reporting` + `## Statusline` sections**

In `plugins/dev-workflows/README.md`, find this exact block (the end of the Session-feedback section + the start of the `/implement` deep-dive):

```
`references/feedback-emission.md`.

## `/implement` workflow
```

Replace it with (the same lines, with the two new sections inserted between):

```
`references/feedback-emission.md`.

## Session cost reporting

dev-workflows records how many **dollars** a Value Increment cost across its
whole lifecycle — by **phase**, **role**, and **model** — persisted per-VI into
the specs repo so the maintainer can aggregate spend across engineers and teams.
Claude Code exposes no dollar figure to a command, so cost is **computed** from
transcript token usage (the main transcript + the session's subagents) times a
price table; an optional statusline snapshot cross-checks it.

- **Terminal cost phase** on the six VI-lifecycle commands (`/specify`, `/epics`,
  `/design`, `/implement`, `/document`, `/release-notes`). It **always runs** and
  always advances a per-session **chained checkpoint** (each command's window
  starts where the previous one ended), so per-command costs sum to the session
  total. `/vuln` and `/upgrade` are out of scope (no VI to attribute to).
- **Per-invocation, append-only entries** in
  `<VI-dir>/dev-workflows/cost/<sid8>.md` — one file per session (`<sid8>` = the
  first 8 chars of the session id), so nothing merge-conflicts across many teams
  or one person's N sessions. Machine-friendly YAML (phase, role, per-model split,
  duration, `cost_computed_usd`, and — when the plugin statusline is installed —
  `cost_statusline_usd`). **No user name is ever written.**
- **Attribution** is a fixed per-command phase/role map, except `/release-notes`,
  whose phase/role is inferred from whether any `specification.md` / `design.md`
  exists under the VI (a PM's early bare-VI run vs. a dev's documenting re-run).
- **Graceful degradation** (specs-first, never the cwd): `$SPECS_PATH` VI dir →
  a pending file for keyless runs (opportunistically reconciled later) → a
  writable vault (with a "won't auto-aggregate" notice) → beside an imported Jira
  directory → report-only. The price table is overridable via
  `$DEV_WORKFLOWS_COST_PRICES`. See `references/cost-emission.md`.

## Statusline

`/statusline` installs the plugin's multi-line, truecolor status line (session
identity, git branch, context bar, cost, tokens, rate limits) into
`~/.claude/settings.json`. Installation is idempotent and backs up any existing
script and `statusLine` block before writing. Installing it also enables the
**Option B** cost cross-check: the shipped script writes a per-render
`{ts, cost_usd}` snapshot that the cost phase compares against its
transcript-computed estimate (a drift signal for refreshing the price table).

## `/implement` workflow
```

- [ ] **Step 7: Add the README Reference-docs bullet**

In `plugins/dev-workflows/README.md`, find this exact line (the `feedback-emission.md` bullet):

```
- `references/feedback-emission.md` — the session-feedback emitter shared by the automatic maintenance phases and the `/feedback` + `/prompt*` commands (entry format, the specs-first persistence ladder, append-only dedup + attribution, the plugin-facing predicate, and the `emit-auto` / `emit-manual` / `emit-prompt` caller contract). Self-contained; persists plugin signal to `$SPECS_PATH` for maintainer aggregation.
```

Replace it with (the same line, then a new bullet):

```
- `references/feedback-emission.md` — the session-feedback emitter shared by the automatic maintenance phases and the `/feedback` + `/prompt*` commands (entry format, the specs-first persistence ladder, append-only dedup + attribution, the plugin-facing predicate, and the `emit-auto` / `emit-manual` / `emit-prompt` caller contract). Self-contained; persists plugin signal to `$SPECS_PATH` for maintainer aggregation.
- `references/cost-emission.md` — the session-cost emitter shared by the terminal cost phase of the six VI-lifecycle commands (session-artifact resolution, the chained-checkpoint model, `scripts/session-cost.py` invocation, the price table, the per-invocation entry format written to `<VI-dir>/dev-workflows/cost/<sid8>.md`, the specs-first ladder, pending/reconciliation, the optional statusline cross-check, attribution incl. the `/release-notes` inference, and the `emit-cost` caller contract). Self-contained; computes cost from transcript tokens × `references/cost-prices.yaml`.
```

- [ ] **Step 8: Structural verification**

Run:
```bash
cd /workspace/ihudak-claude-plugins
python3 -c "import json; json.load(open('plugins/dev-workflows/.claude-plugin/plugin.json')); print('plugin.json OK')"
python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); v={p['name']:p['version'] for p in m['plugins']}; print(v); assert v['dev-workflows']=='2.10.0' and v['dt-style-guide']=='0.2.2' and v['obsidian-llm-wiki']=='0.3.1'"
grep -c 'Sixteen slash commands' plugins/dev-workflows/.claude-plugin/plugin.json
grep -c 'Sixteen slash commands' .claude-plugin/marketplace.json
grep -c '/statusline' plugins/dev-workflows/.claude-plugin/plugin.json
grep -c 'Twenty-six reusable subagents' plugins/dev-workflows/.claude-plugin/plugin.json
grep -n '## \[2.10.0\] — 2026-07-09' plugins/dev-workflows/CHANGELOG.md
grep -c '## \[2.9.0\] — 2026-07-09' plugins/dev-workflows/CHANGELOG.md
grep -c '## Session cost reporting' plugins/dev-workflows/README.md
grep -c '## Statusline' plugins/dev-workflows/README.md
grep -c 'references/cost-emission.md' plugins/dev-workflows/README.md
# Sibling byte-identity: the marketplace diff must touch ONLY the dev-workflows entry.
git diff .claude-plugin/marketplace.json | grep -E '^[+-]' | grep -iE 'dt-style-guide|obsidian-llm-wiki' && echo "SIBLING TOUCHED — FAIL" || echo "siblings untouched OK"
git diff --stat plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md
```
Expected: both JSON files parse; the marketplace assertion passes (dev-workflows `2.10.0`, siblings unchanged); `Sixteen slash commands` appears once in each JSON file; `/statusline` ≥ 1 in `plugin.json`; `Twenty-six reusable subagents` still once; the CHANGELOG `[2.10.0]` grep returns one line and `[2.9.0]` is still present (`1`); `## Session cost reporting` and `## Statusline` each once in the README; `references/cost-emission.md` appears **1** time in the README (the Reference-docs bullet); `siblings untouched OK`; `--stat` lists exactly the four files.

- [ ] **Step 9: Commit**

```bash
git add plugins/dev-workflows/.claude-plugin/plugin.json .claude-plugin/marketplace.json plugins/dev-workflows/CHANGELOG.md plugins/dev-workflows/README.md
git commit --no-verify -m "$(cat <<'EOF'
release(dev-workflows): v2.10.0 — session cost reporting + /statusline

Version lock-step (plugin.json + marketplace.json dev-workflows entry) to 2.10.0;
description Fifteen -> Sixteen slash commands (+ /statusline); subagent count (26)
and hook count (4) unchanged. CHANGELOG [2.10.0] Added; README Session-cost-
reporting + Statusline sections + a cost-emission.md Reference-docs bullet.
Siblings dt-style-guide 0.2.2 / obsidian-llm-wiki 0.3.1 untouched.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Notes for the executor

- **Byte-diff discipline.** These are prose / code / JSON files; after each task read the `git diff` and confirm no unintended reflow or anchor drift. Prettier is NOT run here (no husky/pnpm wired for this repo); commit with `git commit --no-verify`. If the maintainer wants formatting applied, run `pnpm prettier -w <files>` (or the repo's formatter) locally before pushing.
- **Anchor drift.** Line numbers in this plan are approximate (2026-07-09 read). Locate edits by the quoted anchor text, not by line number. In `document.md` the two `## Invariants (always enforced)` headings are disambiguated ONLY by their unique first bullet — never match the bare heading.
- **Task order is load-bearing.** T1 + T2 before T4/T5 (the cost phases cite `cost-emission.md` and run `session-cost.py`). T6 LAST (recompute the command count only after `/statusline` exists — Step 0).
- **Resolved spec ambiguity — statusline snapshot "append".** Spec §8 says the statusline "append[s] `{ts, cost_usd}`" yet shows the file as `= { ts, cost_usd }` (a single object) and the engine contract reads "its `cost_usd`". Resolved to an **overwrite of a single-object snapshot each render** (bounded file size; matches "its cost_usd"); `session-cost.py`'s `read_snapshot_cost` additionally accepts JSONL (last parseable line) so a future append-style writer still works. If a one-line check shows `.cost.total_cost_usd` is absent on the statusline stdin in the target Claude Code version, Option B is simply unavailable and Option A stands alone (documented in `cost-emission.md` §5).
- **`impl-maintenance` untouched.** Cost reporting does NOT use `impl-maintenance` (unlike feedback). No agent, reviewer, `jira-reader`, or format-reference file is edited by this effort.
- **`/vuln` and `/upgrade` are intentionally NOT wired** (spec §14) — they are CVE / dependency sessions with no VI to attribute to; wiring them would only produce keyless pending noise.
- **PyYAML is not required.** `session-cost.py` embeds a minimal indentation-based reader for the fixed `cost-prices.yaml` structure; verification reuses that reader, never `import yaml`.

## Self-Review — Spec Coverage

Every design section (§1–§19) maps to the task(s) that implement it:

| Design § | Where covered |
|---|---|
| §1 Goal | Plan Goal + T2 (purpose header) |
| §2 Motivating workflow (fan-out merge-safety; `/release-notes` ×2; clean containers) | T1/T2 §6 (per-session `cost/<sid8>.md`) + T4 (`/release-notes` inference) + T2 §7 (phase/role map) |
| §3 Data source & feasibility (computed, not read; subagents) | T1 (`session-cost.py` main + subagents) + T2 §1/§2 |
| §4 Architecture (self-contained emitter pattern) | Plan Architecture + T2 (SSOT) + T1 (engine) + T3 (statusline) |
| §5 Cost computation ("Option A") | T1 (engine: line-offset window, per-model, unpriced-null) + T2 §2 |
| §6 Price table | T1 (`cost-prices.yaml` + reader) + T2 §4 (override order) |
| §7 Chained-checkpoint model | T1 (checkpoint load / `new_checkpoint` out) + T2 §3 (advance ALWAYS) |
| §8 Statusline augmentation ("Option B") | T3 (per-render snapshot write) + T1 (`--snapshot` delta) + T2 §5 |
| §9 Report artifact & entry format | T2 §6 (frontmatter + per-invocation YAML entry, verbatim) |
| §10 Attribution (phase/role/keys; `/release-notes` inference) | T2 §7 + T4 (release-notes phase/role inferred) + T4/T5 (per-command labels) |
| §11 Persistence ladder (specs-first; `cost/`; never cwd) | T2 §8 |
| §12 Pending & reconciliation (move-then-delete; same-session pre-select) | T2 §9 |
| §13 `/statusline` installer | T3 (`commands/statusline.md` + vendored `scripts/statusline-command.sh`) |
| §14 Command wiring & scope (6 wired; vuln/upgrade out; siblings untouched) | T4 (3) + T5 (3, document ×2) + Global Constraints (out-of-scope + siblings) |
| §15 Privacy (no user name) | Global Constraints + T2 §10 + every T4/T5 cost phase |
| §16 Non-goals (no exact billing, no dedup, no aggregation, unpriced-null) | T1 (`cost_usd:null` for unknown; no rollup) + T2 §6 (never deduped) + Global Constraints |
| §17 Relationship to siblings (shared home; divergences; latent merge risk) | T2 (Relationship-to-siblings header) + Plan Architecture |
| §18 Resolved decisions (D1–D7 + Refinements 1–2) | D1 Option A+B → T1/T2 §2/§5; D2 home → T2 §6/§8; D3 phase/role → T2 §7; D4 release-notes → T4; D5 keyless → T2 §9; D6 format → T2 §6; D7 `/statusline` → T3; Refinement 1 per-session files → T2 §6; Refinement 2 first=$0 chained checkpoint → T2 §3 |
| §19 Release surfaces (v2.10.0) | T6 (plugin.json + marketplace.json versions/description, CHANGELOG, README; root README untouched) |

**Placeholder / type-consistency check.**

- **No placeholders.** No "TBD", "handle edge cases", or "similar to Task N". CREATE steps (T1, T2, T3) contain complete file content — the full `session-cost.py`, the full `cost-prices.yaml`, the full `cost-emission.md` prose, and the full `statusline.md` body; the vendored `statusline-command.sh` is a verbatim `cp` + one exact find/replace block (more faithful than re-typing 450+ lines). MODIFY steps (T4, T5, T6) contain verbatim find anchors + full insertion text. The only bracketed `<…>` / `[…]` tokens are (a) the fixture's own literal test values and (b) `cost-emission.md` §2's CLI `<path>` placeholders — runtime fill-ins the orchestrator supplies per session (matching the existing `feedback-emission.md` / handoff style), not plan gaps.
- **Type consistency.** The `session-cost.py` stdout schema (`models[]{model,cost_usd,input_tokens,output_tokens,cache_read_tokens,cache_write_tokens[,note]}`, `cost_computed_usd`, `cost_statusline_usd`, `duration_s`, `new_checkpoint{line_offset,last_ts,last_snapshot_cost}`) is stated identically in T1 Interfaces and T2 §2. The entry format (spec §9) appears once, verbatim, in T2 §6. The `emit-cost` inputs (`command`, `phase`, `role`|`inferred`, `jira_key`|`null`, `source`, `plugin_version`) are defined in T2 §11 and used verbatim in all eight cost-phase insertions (T4 ×3, T5 ×4 including document ×2 — wait: T4 = specify/design/release-notes = 3 insertions; T5 = epics/implement + document ×2 = 4 insertions; 7 phase insertions total across 6 command files). The phase/role labels in every insertion match the §7 table (specification/pe, epic-refinement/pe, planning/dev, implementation/dev, documenting/dev, inferred). File paths — `scripts/session-cost.py`, `references/cost-prices.yaml`, `references/cost-emission.md`, `<VI-dir>/dev-workflows/cost/<sid8>.md`, `~/.claude/dev-workflows/cost-state/<session_id>.json`, `~/.claude/dev-workflows/cost-snapshots/<session_id>.json` — are consistent across T1–T6 and the README.
