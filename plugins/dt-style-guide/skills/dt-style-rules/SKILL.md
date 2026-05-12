---
name: dt-style-rules
description: >
  Dynatrace corporate style guide rules for writing Epics, PRDs, ARDs,
  product documentation, and other planning documents. Load this skill
  when writing or editing content that must follow Dynatrace terminology,
  trademarks, voice/tone, and formatting standards. Triggers on: Dynatrace
  style, DT terminology, write epic, write PRD, write ARD, Dynatrace
  content, style guide, corporate writing.
allowed-tools: Read
---

# Dynatrace style rules

This skill provides Dynatrace corporate style guidance to any writing agent.
Load it to produce correctly styled content from the start, reducing the need
for post-hoc style checking.

## How to use

Read the reference docs from:
```
~/.claude/plugins/data/dt-style-guide@ihudak-claude-plugins/references/
```

Apply the rules below while writing. The full reference docs provide
comprehensive tables and examples; this skill summarises the most impactful
rules as a quick checklist.

---

## Quick checklist (apply while writing)

### Terminology
- Use registered trademarks correctly: Dynatrace®, OneAgent®, PurePath®,
  Smartscape®, Grail®, OpenPipeline® — ® on first mention per document only.
- Never abbreviate "Dynatrace" to "DT".
- Use "Dynatrace environment" not "tenant."
- Use "extension" not "plugin" or "add-on."
- Use "ready-made" not "out-of-the-box."
- App names stand alone: "Open Dashboards" not "Open the Dashboards app."

### Banned words (never use)
- blacklist → blocklist/denylist
- whitelist → allowlist
- master (tech) → primary/main
- slave → replica/secondary
- native (people) → use specific group names
- crazy/insane → unexpected/surprising
- blind to → unaware of
- cripple → impair/degrade
- dummy → placeholder/sample

### Voice and tone
- **Active voice** by default: subject + verb + object.
- **Second person**: address reader as "you."
- **Be direct**: no hedge words (we believe, arguably, it seems).
- **No patronising language**: avoid "simply," "just," "easy," "obvious."
- **Contractions OK**: it's, don't, can't, we're.
- **Banned contractions**: it'll, it'd, they'd, mustn't, would've, should've.
- **Spell out negatives in warnings**: "do not" instead of "don't."

### Grammar
- Singular noun as adjective: "metric browser" not "metrics browser."
- Transitive verbs need objects: "Wait till the image is rendered" not
  "Wait till the image renders."
- Gender-neutral pronouns: they/them/their.

### Formatting
- **Sentence-case** capitalisation in all headings and titles.
- **No closing punctuation** in headings (except question marks for FAQ style).
- **No gerund (-ing)** verb forms in headings: "Create" not "Creating."
- **Serial comma** always.
- **Spell out 0–9** in prose; numerals for 10+.
- **No ampersands** (&) — write "and."
- **Em dashes** without spaces: word—word.

### UI interactions (for product docs)
- select (not click/tap)
- go to (not navigate/open for pages)
- open (files, apps, terminals)
- sign in (not log in)
- turn on/off (not enable/disable/toggle)
- enter (not type/paste)

### American English
- behavior, center, color, catalog, favorite, analyze, organize

### Links
- Descriptive link text matching the target page title.
- Never use "here," "this page," "more" as link text.

### Emoji
- No emoji in product docs, UI copy, website, or blogs.

---

## When NOT to enforce

- Code blocks and inline code — don't flag terms inside backticks.
- Third-party product names — use their official capitalisation.
- Direct quotations — preserve original wording.
- URLs and file paths — don't flag.

---

## Reference docs (for full details)

| File | Content |
|---|---|
| `terminology.md` | Product names, solutions, trademarks, apps |
| `word-list.md` | General English usage, banned words, spelling |
| `voice-and-tone.md` | Three pillars, active voice, contractions |
| `grammar.md` | Sentence structure, plural adjectives, verbs |
| `formatting.md` | Numbers, punctuation, headings, lists, dates |
| `ui-interactions.md` | Select, go to, open, turn on/off, enter |
| `accessibility.md` | Inclusive language, i18n |
| `top-10-tips.md` | Quick-reference checklist |

Read these files for tables of ✅/❌ examples and edge cases.
