# List Filtering

**Sources:** [Google AIP-160 — Filtering](https://google.aip.dev/160), [Google AIP-132 — List](https://google.aip.dev/132), [Zalando — Query parameters](https://opensource.zalando.com/restful-api-guidelines/#137), [JSON:API — Sparse fieldsets](https://jsonapi.org/format/#fetching-sparse-fieldsets), [JSON:API — Sorting](https://jsonapi.org/format/#fetching-sorting), [Microsoft REST API Guidelines — Collections](https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md), [RFC 3339 — Timestamps](https://www.rfc-editor.org/rfc/rfc3339.html)

If a _List_ method supports result filtering, it **must** accept a query parameter named `filter` carrying a filter expression. By default a filter expression may refer to any field of the listed resource. A service **may** decide that only a subset of fields is filterable; that set **must** be documented.

The filtered result is always a list, regardless of the number of entries. An empty result is a successful execution of _List_ with an HTTP 200 - OK response.

A filter expression is a set of field-level expressions combined with the boolean operators 'or', 'and' and 'not'. Round brackets are supported; standard boolean operator precedence **must** apply ('and' before 'or') where no brackets are used.

General form of a field-level expression: `<fieldname> <operator> <value>`

## Datatypes and Operators

| Datatype	      | Operators	        | Representation                                                 |
| --------------- | ------------------- | -------------------------------------------------------------- |
| Number (short, int, long, float, double) | =, !=, < , <=, >, >= | <li>Integers: decimal and hexadecimal (with leading '0x')</li><li>Floating point: scientific notation with optional exponent 'e' or 'E'</li> |
| String	      | =, !=, contains, starts-with, ends-with	| <li>Single quotes only: 'Hello World!'</li><li>Special characters (e.g. the quotes) are escaped with '\'</li><li>The exact operators '=' and '!=' are case sensitive</li><li>The inexact operators 'contains', 'starts-with' and 'ends-with' are case insensitive</li>|
| Boolean	      | =, !=	            | Comparison with the constants 'true' or 'false' only           |
| Date/Time	      | =, !=, <, <=, >, >=	| As an [RFC 3339](https://www.rfc-editor.org/rfc/rfc3339.html) string, may carry a UTC offset |
| List	          | in, is-empty        | A list of values of the same type, surrounded by '(' and ')'   |

## The 'in' Operator

Equality against a list of possible values is expressed with the `in` operator.

Instead of writing
```
s = '123' or s = '456' or s = '789'
```
you can write
```
s in('123','456','789')
```
The `in` operator is supported for all datatypes except `boolean`.

#### Example Expressions
```
age = 30
firstName = 'Konrad' and lastName = 'Zuse'
owner = 'user1' and lastModified >= '2022-02-06T11:00:00Z'
tenantId starts-with 'abc' and not (deleted = false or active = true)
cacheHitRate < 90.5
distance >= 1.0E4
userList is-empty
```

## Options

Depending on the underlying data model, deeply nested brackets can cause performance problems. A service **may** limit the maximum nesting depth. Such a limit **must** be documented.

## Tag filtering

Filtering by tags attached to a resource is a special case. Tags are defined dynamically by users and consist of a key plus a value. Key names may contain any character, including whitespace, which makes them unusable as field names in a filter expression.

Filtering for tags **must** therefore always be expressed the same way:
- The key **must** be referenced as `tag.key`
- The value **must** be referenced as `tag.value`

#### Example
```
tag.key = 'my keyname' and tag.value = 'my tag value'
```

## Grammar

An API that adopts this filter syntax **must** publish the expression grammar it accepts (e.g. as an ABNF or a parser grammar file) alongside the API documentation, and **must** state the operator precedence its parser implements — a grammar file alone does not fix precedence, and two services that disagree about it will return different results for the same filter string.

Where a general-purpose filter language is preferred over the syntax above, [AIP-160](https://google.aip.dev/160) defines a fully specified, publicly documented alternative with the same `filter` parameter name; an API **may** adopt it wholesale, but **must not** mix the two.

# Field Filtering and Partial Results

A service **may** return only a subset of the available fields of a resource by default (a _partial result_). In some scenarios this avoids expensive background work and unnecessary bandwidth. The fields returned in the default partial result **must** be carefully documented. If an API supports partial results, it **must** provide a query parameter named `add-fields` to request fields that are missing from the default response.

Field filtering **must** only be used in _List_ and _Get_ methods, and in custom methods that are specialized versions of _List_ and _Get_.

- `add-fields` **must** contain a comma-separated list of field names to add to the default set.
- Duplicate fields in the list **may** result in an error.
- Requesting a field that is already in the default response is redundant and **should** be ignored.
- Referencing an unknown field **must** result in an error.
- Nested field names **must** be separated by a dot.
- If an API supports partial results, it **must** also support [Partial Update](../rest-api-guidelines/Standard%20Methods.md#partial-update).

#### Example
```
GET /entities

{
    "totalCount": 72,
    "nextPageKey": "…",
    "entities": [
        {
            "entityId": "HOST-0004DD30F142D18C"
        }
    ]
}

GET /entities?add-fields=lastSeenTimeMillis,properties.bitness
{
    "totalCount": 72,
    "nextPageKey": "…",
    "entities": [
        {
            "entityId": "HOST-0004DD30F142D18C",
            "lastSeenTimeMillis": 1615991063257,
            "properties": {
                "bitness": "64"
            }
        }
    ]
}
```

# Sorting

If a _List_ method supports sorting, it **must** accept a query parameter named `sort`.

- `sort` **must** contain either a single field name or a comma-separated list of field names defining the sort order; the list **must** be applied left to right.
- Ascending order **should** be the default.
- Field names **may** be prefixed with '-' for _descending_ order.
- String comparison for sorting **should** be case-insensitive.
- The API **may** restrict the set of sortable fields (sorting by an arbitrary internal key is pointless). The API **must** document which fields are sortable.
- Unknown or unsupported field names **should** be ignored. This matches the general way [unknown fields](../rest-api-guidelines/Design%20Patterns.md#handling-unknown-json-fields-in-resources) are handled in resources.

#### Example
```
GET /problems?sort=status,-startTime,relevance
```
Sorts by ascending `status` first, then by descending `startTime`, and finally by ascending `relevance`.
