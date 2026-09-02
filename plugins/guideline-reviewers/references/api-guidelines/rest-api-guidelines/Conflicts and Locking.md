# Introduction

**Sources:** [RFC 9110 §13 — Conditional Requests](https://www.rfc-editor.org/rfc/rfc9110.html#section-13), [RFC 9110 §8.8.3 — ETag](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.3), [RFC 9110 §15.5.13 — 412 Precondition Failed](https://www.rfc-editor.org/rfc/rfc9110.html#section-15.5.13), [Zalando — Optimistic locking](https://opensource.zalando.com/restful-api-guidelines/#optimistic-locking), [Google AIP-154 — Resource freshness validation](https://google.aip.dev/154), [Optimistic concurrency control](https://en.wikipedia.org/wiki/Optimistic_concurrency_control)

When multiple users manipulate the same resource at the same time, this typically leads to a conflict.

Assume two users read the same version of a resource, each update some fields, and each write the updated resource back at different times. Without locking or validation, the order of the write operations decides who wins and whose changes are lost. This is the "last write wins" strategy: simple to implement and to understand. Sometimes it is good enough, but in many cases an API **should** prevent such conflicts with a locking mechanism.

The most common strategies are [optimistic locking](https://en.wikipedia.org/wiki/Optimistic_concurrency_control) and [pessimistic locking](https://en.wikipedia.org/wiki/Concurrency_control).

# Optimistic Locking

An API that controls concurrency **must** use the "optimistic locking" strategy. The expectation is a low conflict rate, and optimistic locking avoids the deadlock risk, the complexity and the performance cost that come with pessimistic locking.

If an API provides optimistic locking on a resource, it **must** do so consistently and comprehensively. Using it in only part of the API that maintains the resource (e.g. on partial update but not on full update) is not allowed. If an API manages multiple resources, it **should** use the same locking strategy for all of them and **must not** mix strategies within one resource.

## Mechanism A (RECOMMENDED) — conditional requests

The standard HTTP mechanism for optimistic concurrency is the conditional request ([RFC 9110, Section 13](https://www.rfc-editor.org/rfc/rfc9110.html#section-13)):

- Every read of the resource **must** return an [`ETag`](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.3) response header carrying the current version validator.
- Every writing operation **must** accept an [`If-Match`](https://www.rfc-editor.org/rfc/rfc9110.html#section-13.1.1) request header carrying the ETag the write is based on.
- If the precondition fails, the API **must** return HTTP 412 - Precondition Failed.
- If the writing operation requires a precondition and `If-Match` is absent, the API **must** return HTTP 428 - Precondition Required.

## Mechanism B — a `version` field

An API that cannot use headers (e.g. because it must work through a client that strips them) **may** instead carry the version in the payload. If it does:

- The version **must** be assigned to the protected resource in a field named `version`.
- The `version` field **must** always be present when the resource is returned by a reading operation.
- The `version` field **must** be excluded from [field filtering](../rest-api-guidelines/Filtering%20And%20Sorting.md#field-filtering-and-partial-results) and **must not** be writable by the client. It **must** be maintained only by the service that owns the resource.
- There is no prescribed version format — it may be an ever-increasing counter, a hash, or any other opaque validator that changes on every write.

#### Example
```
GET /documents/6239bf48-ce6d-4e06-8694-bd3c2b235d63

{
  "id": "6239bf48-ce6d-4e06-8694-bd3c2b235d63",
  "name": "test",
  "type": "text",
  "version": "2e9565ea",
  "owner": "441664f0-23c9-40ef-b344-18c02c23d789",
  ...
}
```

When a resource is protected by mechanism B, every writing operation **must** accept an `optimistic-locking-version` query parameter carrying the version the written content was taken from. This lets the API check whether the current version of the resource is still the one the write is based on, and reject the request if it is not. The API **must** return HTTP 409 - Conflict in that case.

The only situation in which a missing `optimistic-locking-version` parameter is acceptable on a writing operation is one where no conflict can occur — e.g. creating a new resource, or deleting one.

#### Example
```
PUT /documents/6239bf48-ce6d-4e06-8694-bd3c2b235d63?optimistic-locking-version=2e9565ea

...

GET /documents/6239bf48-ce6d-4e06-8694-bd3c2b235d63
{
  "id": "6239bf48-ce6d-4e06-8694-bd3c2b235d63",
  "name": "test",
  "type": "text",
  "version": "456efa90",
  "owner": "441664f0-23c9-40ef-b344-18c02c23d789",
  ...
}
```

An API **must** pick one of the two mechanisms and document it. Supporting both on the same resource **must not** be done: two independent version validators on one resource can disagree, and a client has no way to know which one the service enforced.
