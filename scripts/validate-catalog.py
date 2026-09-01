#!/usr/bin/env python3
"""Validate every plugin manifest and marketplace catalog in this repository.

Guards the three defects that have actually shipped from this repo more than
once:

  1. An over-long plugin ``description``. GitHub Copilot CLI rejects a
     marketplace whose ``plugins[i].description`` exceeds 1024 characters, and
     it rejects the WHOLE catalog -- every plugin in the marketplace then fails
     to install or update, not just the offending one. Claude Code enforces no
     such limit, so the Claude editions can drift far past it with no local
     symptom and then break the Copilot edition at port time. Trimmed by hand
     three times in the Copilot edition before this check existed; each trim
     reset the length without stopping the growth that caused it.

  2. Version drift between a plugin's own ``plugin.json`` and the marketplace
     catalog entry that advertises it. They are independent files kept in sync
     by hand; a release that bumps one and forgets the other ships a catalog
     pointing at the wrong version. Has shipped four times.

Note on what is deliberately NOT checked: the ``description`` in a catalog
entry and in the matching ``plugin.json`` are not required to be identical.
They are independently authored in practice -- Copilot's ``prose-style``
blurbs, for instance, share no wording at all -- so an equality check would
fail on correct content. The half-fix it might have caught (Copilot's
marketplace trimmed to 964 while its plugin.json stayed at 2091) is already
caught by applying the length check to both files.

Usage:
    python3 scripts/validate-catalog.py [REPO_ROOT ...]
    python3 scripts/validate-catalog.py --selftest

With no arguments, validates the repository containing this script. Exits 0
when everything passes, 1 on any error. Warnings alone do not fail the run.

``--selftest`` builds a minimal catalog in a temporary directory, mutates it once
per failure mode, and asserts both the exit status and WHICH error was reported.
Its two siblings under ``scripts/`` have had one for releases; this one did not,
so nothing proved it could still fail -- and a checker that cannot be shown to
fail proves nothing when it passes. Asserting the message rather than the exit
code alone is deliberate: every mutation here trips a non-zero exit, so exit
status alone would let a mutation that broke a DIFFERENT rule register as
success, which is exactly how the sibling gate's selftest went green over a real
regression.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# GitHub Copilot CLI's hard schema limit. Applied to every edition, not just
# the Copilot one: canonical is the source the Copilot blurb is ported from, so
# letting canonical grow past the limit is what reloads the gun.
DESCRIPTION_MAX = 1024

# Growth in this field is a ratchet -- each release has historically appended a
# sentence and removed nothing (259 chars at inception, 2788 by 2.52.0). Warn
# with enough headroom that trimming happens as routine maintenance instead of
# as an outage.
DESCRIPTION_WARN = 900

SKIP_DIRS = {".git", "node_modules", ".superpowers", ".idea"}


def find_files(root: Path, name: str) -> list[Path]:
    """Locate every file with this name, at any depth.

    Deliberately unbounded: Copilot keeps its catalog at
    ``.github/plugin/marketplace.json`` (depth 3) while Claude editions use
    ``.claude-plugin/marketplace.json`` (depth 2). A depth-limited search
    reported "Copilot has no catalog" once and shipped a stale one as a result.
    """
    return sorted(
        p
        for p in root.rglob(name)
        if not any(part in SKIP_DIRS for part in p.parts)
    )


def load(path: Path) -> dict | None:
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"  ERROR {path}: cannot parse -- {exc}")
        return None


def check_description(label: str, description: str) -> tuple[int, int]:
    """Return (errors, warnings) for one description field."""
    size = len(description)
    if size > DESCRIPTION_MAX:
        print(
            f"  ERROR {label}: description is {size} chars, "
            f"limit is {DESCRIPTION_MAX} "
            f"(Copilot rejects the entire catalog, breaking every plugin in it)"
        )
        return 1, 0
    if size > DESCRIPTION_WARN:
        print(
            f"  WARN  {label}: description is {size} chars, "
            f"nearing the {DESCRIPTION_MAX} limit -- trim it now, "
            f"and move release detail to CHANGELOG.md"
        )
        return 0, 1
    return 0, 0


def validate_repo(root: Path) -> tuple[int, int]:
    print(f"\n=== {root}")
    errors = 0
    warnings = 0

    # Index every plugin manifest by the directory that holds the plugin, so a
    # catalog entry can be matched against the manifest it advertises.
    manifests: dict[str, tuple[Path, dict]] = {}
    for manifest_path in find_files(root, "plugin.json"):
        data = load(manifest_path)
        if data is None:
            errors += 1
            continue
        name = data.get("name")
        if not name:
            print(f"  ERROR {manifest_path}: no 'name' field")
            errors += 1
            continue
        manifests[name] = (manifest_path, data)
        rel = manifest_path.relative_to(root)
        e, w = check_description(str(rel), data.get("description", ""))
        errors += e
        warnings += w

    catalogs = find_files(root, "marketplace.json")
    if not catalogs:
        print("  ERROR no marketplace.json found in this repository")
        errors += 1

    for catalog_path in catalogs:
        data = load(catalog_path)
        if data is None:
            errors += 1
            continue
        rel = catalog_path.relative_to(root)
        entries = data.get("plugins", [])
        if not entries:
            print(f"  ERROR {rel}: catalog lists no plugins")
            errors += 1
            continue

        for index, entry in enumerate(entries):
            name = entry.get("name", f"<unnamed #{index}>")
            label = f"{rel} plugins[{index}] ({name})"

            e, w = check_description(label, entry.get("description", ""))
            errors += e
            warnings += w

            if name not in manifests:
                print(
                    f"  ERROR {label}: catalog advertises a plugin with no "
                    f"plugin.json anywhere in this repository"
                )
                errors += 1
                continue

            manifest_path, manifest = manifests[name]
            manifest_rel = manifest_path.relative_to(root)

            catalog_version = entry.get("version")
            manifest_version = manifest.get("version")
            if catalog_version != manifest_version:
                print(
                    f"  ERROR {label}: catalog says version "
                    f"{catalog_version!r} but {manifest_rel} says "
                    f"{manifest_version!r}"
                )
                errors += 1

    if errors == 0 and warnings == 0:
        print("  OK")
    return errors, warnings


def _selftest() -> int:
    """Build a passing catalog, mutate it once per rule, assert what was reported."""
    import tempfile

    def build(root: Path, *, version: str = "1.0.0", catalog_version: str | None = None,
              description: str = "A fixture plugin.") -> None:
        plugin = root / "plugins" / "fixture" / ".claude-plugin"
        plugin.mkdir(parents=True)
        (plugin / "plugin.json").write_text(json.dumps(
            {"name": "fixture", "version": version, "description": description}), encoding="utf-8")
        market = root / ".claude-plugin"
        market.mkdir(parents=True)
        (market / "marketplace.json").write_text(json.dumps({
            "name": "fixture-plugins",
            "plugins": [{"name": "fixture", "source": "./plugins/fixture",
                         "version": catalog_version or version,
                         "description": description}],
        }), encoding="utf-8")

    rc = 0

    def case(desc: str, want_ok: bool, needle: str, **kw) -> None:
        nonlocal rc
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build(root, **kw)
            import io as _io
            import contextlib
            buf = _io.StringIO()
            with contextlib.redirect_stdout(buf):
                errors, _ = validate_repo(root)
            out = buf.getvalue()
            ok = (errors == 0)
            if ok != want_ok:
                print(f"FAIL  {desc}: expected {'no errors' if want_ok else 'an error'}, "
                      f"got {errors}")
                rc = 1
            elif needle and needle not in out:
                print(f"FAIL  {desc}: the right outcome, but the report never said "
                      f"{needle!r} -- a different rule may have fired")
                rc = 1
            else:
                print(f"ok    {desc}")

    case("a consistent catalog passes", True, "OK")
    case("version drift between catalog and manifest is rejected", False,
         "but plugins/fixture/.claude-plugin/plugin.json says", catalog_version="9.9.9")
    case("an over-long description is rejected", False, "ERROR",
         description="x" * (DESCRIPTION_MAX + 1))
    case("a description past the warning threshold is reported", True, "WARN",
         description="x" * (DESCRIPTION_WARN + 1))

    print("SELFTEST PASS" if rc == 0 else "SELFTEST FAIL")
    return rc


def main(argv: list[str]) -> int:
    if len(argv) > 1 and argv[1] == "--selftest":
        return _selftest()

    roots = (
        [Path(a).resolve() for a in argv[1:]]
        if len(argv) > 1
        else [Path(__file__).resolve().parent.parent]
    )

    total_errors = 0
    total_warnings = 0
    for root in roots:
        if not root.is_dir():
            print(f"ERROR {root}: not a directory")
            total_errors += 1
            continue
        errors, warnings = validate_repo(root)
        total_errors += errors
        total_warnings += warnings

    print(
        f"\n{total_errors} error(s), {total_warnings} warning(s) "
        f"across {len(roots)} repo(s)."
    )
    return 1 if total_errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
