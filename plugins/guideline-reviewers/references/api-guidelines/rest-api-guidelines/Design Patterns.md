# Handling Read-Only JSON Fields in Resources

**Sources:** [Google AIP-158 — Pagination](https://google.aip.dev/158), [Google AIP-203 — Field behavior documentation](https://google.aip.dev/203), [Zalando — Pagination](https://opensource.zalando.com/restful-api-guidelines/#pagination), [RFC 9110 §10.2.3 — Retry-After](https://www.rfc-editor.org/rfc/rfc9110.html#section-10.2.3), [RFC 6585 — Additional HTTP Status Codes (429)](https://www.rfc-editor.org/rfc/rfc6585.html), [RFC 3339 — Timestamps](https://www.rfc-editor.org/rfc/rfc3339.html), [RFC 4648 §5 — base64url](https://www.rfc-editor.org/rfc/rfc4648.html#section-5), [OpenAPI Specification 3.1](https://spec.openapis.org/oas/v3.1.0.html), [JSON:API — Fetching data](https://jsonapi.org/format/#fetching)

Resources frequently contain read-only fields when returned by the _Get_ method. APIs **should** ignore such fields when they appear in a _Create_ or _Update_ request body, rather than returning an error. APIs **should** also accept [Full Update](../rest-api-guidelines/Standard%20Methods.md#full-update) requests (using PUT) in which read-only fields are missing, even though that is technically a partial update.

Read-only fields **must** be marked `readOnly: true` in the OpenAPI schema, so that the constraint is visible to generated clients rather than only in prose.

This is a convenience improvement for clients.

# Handling Unknown JSON Fields in Resources

If a resource in a _Create_ or _Update_ request body contains unknown fields, an API **should** ignore them instead of returning an error.

This is a convenience improvement for clients and helps with rolling-update scenarios, where a caller may already know about new fields that the callee does not yet support.

# Null Representation

If a field is not set it **should not** be part of the result by default. In some cases `null` represents an actual value (e.g. explicitly stating that a dimension is absent from a time series at a given point in time). In that case the response **may** contain null values, and the meaning **must** be documented.

# Parameters

Parameters **must** be passed either as query parameters or in the request body. Headers **must not** be used for parameters, except well-known ones such as `Accept` and the headers used for [API context transfer](../rest-api-guidelines/API%20Context%20Information.md). Parameter passing **should not** be mixed within one operation.

If a parameter corresponds to a field in a response body, it **must** carry the same name (except for the casing difference between kebab-case query parameters and lowerCamelCase fields).

# Headers

Standard headers registered at [IANA](https://www.iana.org/assignments/http-fields/http-fields.xhtml) **may** be used; the usage **must** be documented. Custom headers, other than the ones used for [API context transfer](../rest-api-guidelines/API%20Context%20Information.md), **must not** be used.

#### Examples
```
Accept-Encoding
Content-Length
Content-Type
```

# Timeframes

If a method supports timeframes, it **must** accept 2 query parameters named `start-time` and `end-time` to define the requested timeframe. `start-time` **must** be smaller than `end-time`. If `end-time` is missing it **must** default to `now`.

Each parameter **should** support [absolute timestamps](../rest-api-guidelines/Common%20Datatypes.md#timestamp) and timestamps relative to the current time. If it does not support one of these representations, that **must** be documented. A mixture of absolute and relative timestamps **may** be supported.

Relative timestamp format: `[now()][-|+]<offset>`

`now()` **must** represent the time at which the request is executed. If it is missing it **must** be assumed to be the default anchor.

`offset` **must** be a human-readable representation of a time offset in one of these resolutions:

- "s" - Seconds
- "m" - Minutes
- "h" - Hours
- "d" - Days (1 day = 24 hours, time zones do not apply)

A combination of offsets (e.g. "now()-1d3h30m") **should not** be supported.

`offset` **may** be omitted, which means an offset of 0.

#### Examples
```
GET /problems?start-time=now()-2d&end-time=now()-1h         -- problems from 2 days ago until one hour ago
GET /problems?start-time=-2d&end-time=now()                 -- problems from 2 days ago until now
GET /problems?start-time=-2d&end-time=-1h                   -- problems from 2 days ago until one hour ago
GET /problems?start-time=2021-10-10T00:00:00%2B01:00        -- problems from Oct. 10th until now
GET /problems?start-time=1633523598453&end-time=now()-1h    -- problems from Oct. 6th 12:33 until 1 hour ago
GET /maintenance?start-time=now()-2d&end-time=now()+2d      -- maintenance windows from 2 days ago until 2 days ahead
```

Note that a literal `+` in an absolute timestamp **must** be percent-encoded as `%2B` in a query parameter, because `+` decodes to a space in `application/x-www-form-urlencoded` parsing.

# List Pagination

Listable collections **should** support pagination even if the expected list size is small.

***Rationale***: If an API does not support pagination from the start, adding it later is a breaking change in behaviour. Clients unaware that the API now paginates will assume they received a complete result when they only received the first page.

- _List_ **may** provide a query parameter named `page-key` which carries the cursor to the next page. If the parameter is missing, the first page **must** be returned. The content of the cursor depends on the use case; it **must** be [base64url](https://www.rfc-editor.org/rfc/rfc4648.html#section-5)-encoded data sufficient to locate the next page, and it **must** be opaque to the client.
- Alternatively, _List_ **may** provide a non-negative query parameter `page` defining the page number to fetch, based on the page size. This allows any page to be selected directly. Default is page 1.
- _List_ **may** provide a query parameter `page-size` defining the requested number of entries for the next page. If it is missing, a default size **must** be applied, and that default **must** be documented.
- _List_ **should** specify and document a maximum supported page size.
- _List_ **must** provide a field `nextPageKey` in the response body containing the cursor to the next page, when one exists. The value **must** be usable directly as the `page-key` query parameter without further processing.
- `nextPageKey` **must not** be present once the last page has been reached.
- A subsequent request using `page-key` **must not** require any additional parameter to fulfil the paged request. All necessary parameters **must** be encoded in `page-key`.

The response **may** provide a field named `totalCount` carrying the total number of entries in the overall list (not the page) at the time the request was processed. This value **may** change across calls (resources are added or removed while pages are fetched).

With `page-key` and `page` it is possible to implement either _cursor-based pagination_ or _offset-based pagination_. An API **may** implement either or both, but **must** document which.

## Cursor-based Pagination

Cursor-based pagination uses only `page-key` to stream through a list of resources. There is no way back to previous pages and no way to skip ahead. This form is used by APIs consumed mainly by automation rather than by humans.

#### Example
```
GET /documents?doc-type=dashboard&page-size=20

HTTP/1.1 200 OK
Content-Type: application/json
{
  "documents" : [
     …
  ],
  "nextPageKey" : "bmQgUXVhcms=",
  "totalCount" : 135
}

GET /documents?page-key=bmQgUXVhcms=

HTTP/1.1 200 OK
Content-Type: application/json
{
  "documents" : [
     …
  ],
  "nextPageKey" : "bmhjhTZSJDGJHVhcms=",
  "totalCount" : 135
}
```

## Offset-based Pagination

Offset-based pagination ignores `page-key` and uses only `page-size` and `page` to navigate. The response **may** still contain `nextPageKey`. This form is mainly used for UI list representations that let a human select any page directly.

#### Example
```
GET /documents?doc-type=dashboard&page-size=20

HTTP/1.1 200 OK
Content-Type: application/json
{
  "documents" : [ … ],                               -- page 1 documents
  "nextPageKey" : "bmQgUXVhcms=",                    -- link to page 2
  "totalCount" : 135
}

GET /documents?doc-type=dashboard&page=3&page-size=20

HTTP/1.1 200 OK
Content-Type: application/json
{
  "documents" : [ … ],                              -- page 3 documents
  "nextPageKey" : "bmQgUXVhcms=",                   -- link to page 4
  "totalCount" : 135
}
```

## Mixed Pagination

A mixture of cursor and offset pagination within one operation **must not** be used: it is confusing and adds no value.

# Rate Limiting and Throttling

Services **may** support a throttling mechanism based on signals such as the number of open DB connections, execution-time overhead, or low memory.

There are typically 3 levels of throttling:

- **Global limit**: throttling because the service instance is running out of shared resources (thread pool, DB connections, memory). This is usually the easiest to implement and therefore the most common default.
- **Tenant limit**: prevents a single tenant from consuming all shared resources of a service and blocking other tenants ("tenant starvation"). The tenant context is always available via the [tenant header](../rest-api-guidelines/API%20Context%20Information.md#tenant-context), so this is implementable in most cases.
- **User/client limit**: prevents a single user session from exhausting the tenant limit and blocking other users of that tenant ("user starvation"). The identity of the client is not always available, so this limit is optional in many cases.

If a service throttles a request, it

- **must** return HTTP 429 - Too Many Requests ([RFC 6585](https://www.rfc-editor.org/rfc/rfc6585.html)) for user/client throttling.
- **must** return HTTP 429 - Too Many Requests for tenant throttling.
- **must** return HTTP 503 - Service Unavailable for global throttling, or when the service cannot determine whether 429 applies.
- **must** set the [`Retry-After`](https://www.rfc-editor.org/rfc/rfc9110.html#section-10.2.3) header with the number of seconds to wait before the next attempt.
- **must** include the time until the next retry in the error body, in a field named `retryAfterSeconds`. It **may** include details about the violated constraint; those details **must not** expose sensitive information about the system's internals.

#### Example
```
HTTP/1.1 503 Service Unavailable
Retry-After: 3
Content-Type: application/json

{
    "error": {
        "code": 503,
        "message": "service is overloaded",
        "retryAfterSeconds": 3
    }
}
```

# Bulk Operations

In some cases it **may** be necessary to explicitly support bulking an operation, to reduce the number of requests needed to complete a task. An example is mass-deleting a user's documents: instead of thousands of individual deletes, a single request carries the list of ids.

In general, any operation may be bulked, although bulking only makes sense in some cases. Bulking a _Create_ is rarely useful unless many objects with the same properties must be created.

## Bulk operation request

Bulk operations **must** be expressed as [custom POST methods](../rest-api-guidelines/Custom%20Methods.md) on the resource the operation acts upon. Input parameters **must** be transferred in the request body (no query parameters) so that large input lists are possible. The request body **must** carry the target resources as a list of resource ids:

```
POST /<resource>:<bulk operation>
{
    "ids" : [
        "<id1>",
        "<id2>",
        "<id3>",
        ...
    ]
}
```

#### Examples

Bulk delete (deleting multiple objects in one request):
```
POST /documents:delete
{
    "ids" : [
        "abc",
        "def",
        "ghi"
    ]
}
```

Bulk update (setting 2 fields of multiple resources to a value):
```
POST /documents:update
{
    "field1": "val1",
    "field2": "val2",
    "ids" : [
        "abc",
        "def",
        "ghi"
    ]
}
```

## Bulk operation response

Bulk operations **must** return a response body containing the individual result per operation. The name of the results field can be chosen freely.

A successful individual result **must** carry the same HTTP status code the non-bulked operation would return. So if an individual DELETE returns 200, the per-item result in a bulked DELETE **must** be 200 as well.

A failed individual result **must** likewise carry the status code the non-bulked operation would return, together with the same error body.

The bulk operation itself **must** return HTTP 200 unless the bulk request as a whole fails (e.g. an authorization error).

#### Example
```
POST /documents:delete
{
    "ids" : [
        "abc",
        "def"
    ]
}

HTTP/1.1 200 OK
Content-Type: application/json
{
    "results": [
        {
            "id": "abc",
            "code": 200
        },
        {
            "id": "def",
            "code": 400,
            "error": {
                "code": 400,
                "message": "document is locked",
                "details": {
                    "errorRef": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6"
                }
            }
        }
    ]
}
```

## Response Filtering

Bulk operations **may** support a `filter` query parameter that reduces the size of the result set.

Valid filter values:

- "all" (default if not set) - response contains successful and failed results.
- "failed-only" - only failed results; an empty result list means every operation in the bulk succeeded.
- "success-only" - only successful results.
- "none" - skip all results.

#### Example
```
POST /documents:delete?filter=success-only
{
    "ids" : [
        "abc",
        "def"
    ]
}

HTTP/1.1 200 OK
Content-Type: application/json
{
    "results": [
        {
            "id": "abc",
            "code": 200
        }
    ]
}
```
