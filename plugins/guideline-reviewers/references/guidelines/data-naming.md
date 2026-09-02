# Data Naming Scheme

**Sources:** [OpenTelemetry semantic conventions: naming](https://opentelemetry.io/docs/specs/semconv/general/naming/) · [OpenTelemetry: attribute naming](https://opentelemetry.io/docs/specs/semconv/general/attribute-naming/) · [Google Cloud API Design Guide: Naming conventions](https://cloud.google.com/apis/design/naming_convention) · [Google Cloud API Design Guide: Compatibility](https://cloud.google.com/apis/design/compatibility) · [Google developer documentation style: word list](https://developers.google.com/style/word-list) · [Microsoft Writing Style Guide](https://learn.microsoft.com/en-us/style-guide/welcome/) · [Semantic Versioning 2.0.0](https://semver.org/)

## Summary
Naming rules for tables, views, datasets, and the fields inside them, wherever those names are visible to a user or referenced in a query a user writes. A published data name is an API: once someone has written a query against it, renaming it breaks their work. These rules make names predictable to read and safe to evolve. They apply to any user-visible data surface — a query language's table names, a warehouse's dataset and view names, an event or metric namespace, or the column names a table exposes.

## Mandatory Rules

### DO
- Name for the content, not the implementation: the name says what a row is, in the vocabulary the user already has
- Make the name answer "what do I get when I query this?" without needing the documentation open
- Use a consistent namespace separator and a consistent hierarchy — general to specific, left to right (`http.request.duration`, not `duration.request.http`) ([OpenTelemetry naming](https://opentelemetry.io/docs/specs/semconv/general/naming/))
- Pick one casing convention per surface and apply it without exception: `snake_case` or `dot.delimited.lowercase` for query identifiers, `lowerCamelCase` for JSON fields, and never a mix inside one namespace
- Reserve a namespace prefix for names the product owns, so a user-defined name can never collide with a product-defined one
- Use singular nouns for a field and plural nouns for a collection, consistently across the whole surface
- Spell words out; use an abbreviation only where it is more widely recognised than the expansion (`id`, `url`, `cpu`, `http`)
- Use US English spelling and the terminology in the product's own style guide, per [Google](https://developers.google.com/style/word-list) or [Microsoft](https://learn.microsoft.com/en-us/style-guide/welcome/) style guidance
- State the unit in the name where a value has one and the type does not carry it (`*.duration_ms`, `*.size_bytes`), or expose the unit in metadata — never leave it implicit
- Keep a name stable once it is published; treat a published name as part of the product's compatibility surface ([Google Cloud: Compatibility](https://cloud.google.com/apis/design/compatibility))
- Introduce a new name additively when a concept changes: publish the new name, keep the old name resolving as an alias, and document the equivalence
- Announce a deprecation with a removal date, and keep the deprecated name working until that date passes
- Apply new naming rules to newly published names, and to renames only through the additive path above
- Record the naming convention in one place, and validate names against it in CI rather than in review
- Give a view the same name shape as a table — a consumer should not need to know which one they are querying

### DON'T
- Rename or remove a published table, view, dataset, or field without an alias and a deprecation window — a rename is a breaking change however small it looks
- Encode a version number into a name that is expected to evolve in place; version the surface, not the identifier ([SemVer](https://semver.org/))
- Mix casing conventions inside one namespace (`user_id` beside `userName` beside `User.Email`)
- Use an internal code name, a team name, a project name, or a ticket key in a published name
- Use a name whose meaning depends on where it appears (`value`, `data`, `info`, `object`, `item`, `temp`)
- Encode the storage tier, the ingest pipeline, or the retention class in a user-visible name — those are implementation details that change
- Include the environment, region, or tenant in a name that is already scoped by those things
- Use a reserved word of the query language, or a name requiring quoting or escaping to be usable in a query
- Include whitespace, punctuation beyond the namespace separator and underscore, or non-ASCII characters in an identifier
- Ship two names for one concept in different parts of the product
- Ship one name meaning two things in different parts of the product
- Exceed the length at which the name stops being readable in a column header — roughly 40 characters for a field, 60 for a fully qualified table name

## Scenarios

### Adding a new table or view
- Check the name against existing names in the same namespace for both collision and near-collision
- Check that the singular/plural convention and the casing convention match the namespace
- Confirm the name still reads correctly when fully qualified in a query

### Evolving an existing name
1. Publish the new name alongside the old one
2. Make both resolve to the same data
3. Document the old name as deprecated, naming the replacement and the removal date
4. Remove the old name only after the announced date

### Field-level naming
- The field name is unique within its table, and means the same thing in every table that carries it
- A field carrying an identifier ends in `id` (or `_id` under snake_case), and its value format is documented
- A field carrying a human-readable label ends in `name`
- A field carrying a timestamp ends in `time` or `timestamp` and documents its timezone and precision

---

## Open Questions / Ambiguities

1. **Casing convention is chosen, not derived**: The rules require one convention consistently but do not pick which. `snake_case` is the safest default for query identifiers (no quoting, case-insensitive engines behave predictably), but the choice belongs to the product; record it and enforce it in CI.

2. **Length caps are heuristics**: The 40/60-character guidance is a readability rule of thumb, not a limit any standard imposes. Some engines impose their own hard limits — check the engine's identifier limit before adopting a longer convention.

3. **Deprecation window length is unspecified**: No public source fixes how long an alias must live. Tie it to the product's own support policy (for example, one major version, or 12 months) rather than deciding it per rename.

4. **Scope of "published"**: A name is published once a user could have written a query against it, which may be earlier than a formal GA. Define the point at which a name becomes compatibility-bearing — for example, on first appearance in a preview environment — so the additive-rename rule has a clear trigger.
