# Changelog

## 0.1.1

### Fixed

- **Redundant `skills` manifest key.** `.claude-plugin/plugin.json` declared
  `"skills": ["./skills"]`, but per the Claude Code plugin reference the default `skills/`
  directory is *always* scanned and the `skills` field only *adds* to that scan — so the entry
  registered the same directory twice and diverged from the sibling plugins in this marketplace,
  which omit the key. Removed; `skills/acli/SKILL.md` is still discovered by the default scan.

## 0.1.0

- Initial release. Skill body derived from `ziegenberg/pi-skill-acli` (MIT © Daniel Ziegenberg),
  vendored as a first-party plugin. Adds headless-container authentication guidance and a
  destructive-operation Safety policy on top of upstream.
