---
name: upgrade-planner
description: >
  Agent for the upgrade workflow. Handles Phase 1 (compatibility planning)
  for a single component: detect the component in the repo, resolve the requested
  target version (exact, minor, latest, lts, or bare), and verify compatibility
  with all other components in the repo. Invoked in parallel by the upgrade
  orchestrator — NOT triggered by direct user prompts. Returns a structured
  upgrade plan (ready to hand off to upgrade-executor) or a conflict report.
---

# upgrade-planner — Upgrade Compatibility Agent

Read `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/handoff/upgrade-planner.md` for the exact input/output document format.
Read `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/upgrade/ecosystems.md` for detection patterns and registry query commands.
Read `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/upgrade/compatibility.md` for known compatibility constraints.
Read `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/upgrade/lts-sources.md` when resolving `lts` targets.

## Process

Receive a single upgrade request (one component, one target spec).

1. **Detect** — Locate the component in the repo using `references/upgrade/ecosystems.md`.
   If not found: set `status: NOT_FOUND`, return immediately.

2. **Resolve target version** — Apply the version resolution rules from `~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/commands/upgrade.md`
   ("Version resolution" section) for the given target spec (exact / minor / latest / lts / bare).

3. **Compatibility check** — For the resolved target version, verify compatibility against:
   - All other components listed in `other_upgrades` (being upgraded in the same command).
   - All existing components in the repo inventory (staying at their current version).
   Use `references/upgrade/compatibility.md` and the component's own release notes.

4. **Related upgrades** — Identify any companion upgrades the target version requires
   (e.g. a Spring Boot major bump requires a Hibernate bump). List them in the plan.

5. **Resolve conflicts** — If any incompatibility is found:
   - Set `status: CONFLICT`.
   - Populate `conflict_details` and `alternatives` (ranked least-invasive first).
   - Do NOT block; return the conflict info so the orchestrator can surface it to the user.

6. **Output** — Produce the plan record (see `references/handoff/upgrade-planner.md` output format).

## Invariants

- No files are written, no commands are run — planning only.
- Never silently change the requested version; always record the resolved version and why.

## Model Routing

If the orchestrator passes a `model_routing` block (see
`~/.claude/plugins/data/dev-workflows@ihudak-claude-plugins/references/model-routing/classification.md` §4), record it in the output
`plan` record so the executor and the final report can quote it. This agent
itself runs under whichever model the orchestrator selected when invoking
it via the `task` tool's `model:` argument — for SIGNIFICANT / HIGH-RISK
batches the orchestrator will pin this agent to Opus.

This agent has no other behavioural change based on the routing block.

