---
name: reference
description: Read a shared workflows-core reference by name, and optionally execute one of its entry points.
user-invocable: false
allowed-tools: Read, Bash
---

The invocation arguments name one reference file and, optionally, one entry
point within it.

Read `${CLAUDE_PLUGIN_ROOT}/references/<the first argument>.md` and treat it as
the single source of truth for the current step. When a second argument is
present, execute that entry point of it inline. Never paraphrase, summarise, or
cache its contents.
