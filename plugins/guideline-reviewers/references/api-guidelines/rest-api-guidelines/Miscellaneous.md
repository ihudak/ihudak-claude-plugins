# Caching Directive

**Sources:** [RFC 9111 — HTTP Caching](https://www.rfc-editor.org/rfc/rfc9111.html), [RFC 9110 §8.8.3 — ETag](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.3), [OpenAPI Specification 3.1](https://spec.openapis.org/oas/v3.1.0.html), [Zalando — Hypermedia](https://opensource.zalando.com/restful-api-guidelines/#hypermedia), [HATEOAS](https://en.wikipedia.org/wiki/HATEOAS), [HAL — JSON Hypertext Application Language](https://datatracker.ietf.org/doc/html/draft-kelly-json-hal), [WHATWG — Server-sent events](https://html.spec.whatwg.org/multipage/server-sent-events.html), [RFC 6455 — The WebSocket Protocol](https://www.rfc-editor.org/rfc/rfc6455.html)

All resources are uncached by default, since resources are generally mutable. For some special APIs this differs (e.g. static assets like images). Such APIs **must** carefully specify and document the cache directives they accept and return, as defined by [RFC 9111](https://www.rfc-editor.org/rfc/rfc9111.html).

# ETag

The `ETag` header **may** be used by an API. When it is, it **must** follow the behaviour specified in [RFC 9110, Section 8.8.3](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.3). See [Conflicts and Locking](../rest-api-guidelines/Conflicts%20and%20Locking.md#mechanism-a-recommended--conditional-requests) for its use in optimistic concurrency control.

# DTO Inheritance

Inheritance between data transfer objects **should** be avoided; a flat model is easier to understand and generates cleaner clients. Model composition through `allOf` is constrained by the rules in [OpenAPI — Schema Composition](../rest-api-guidelines/OpenAPI.md#schema-composition--oneof-anyof-allof); polymorphic alternatives **must** use `oneOf` plus a `discriminator`.

# HATEOAS

Hypermedia controls are not part of these guidelines; integration into a hypermedia ecosystem is not a goal. See [Resource Context](../rest-api-guidelines/Common%20Schemas.md#resource-context-info) for the lighter-weight alternative that carries the allowed operations on a resource.

# HAL

[HAL](https://datatracker.ietf.org/doc/html/draft-kelly-json-hal) is not used, for the same reason.

# SSE — Server-Sent Events

[Server-sent events](https://html.spec.whatwg.org/multipage/server-sent-events.html) **should not** be used on public APIs. For [long running operations](../rest-api-guidelines/Long%20Running%20Operations.md) an asynchronous polling mechanism is defined and **should** be preferred. On partner and internal APIs, SSE **may** be used where there is a good reason.

# WebSockets

[WebSockets](https://www.rfc-editor.org/rfc/rfc6455.html) **should not** be used on public APIs. On partner and internal APIs they **may** be used where there is a good reason.

# Probing

Probing (sometimes called a "dry run") **should not** be used unless explicitly necessary.

Probing means an API offers an extra query parameter on certain endpoints telling it not to execute the request, but only to check parameters, permissions and other preconditions, and report whether the same request would succeed or fail. This is commonly used by UI code to enable or disable controls proactively.

REST APIs **should not** be shaped specifically for UI convenience. Instead of probing, use one of these alternatives:

- _Allowed operations_ in the [Resource Context](../rest-api-guidelines/Common%20Schemas.md#resource-context-info), which returns the permitted operations alongside each resource
- A dedicated _effective permissions_ endpoint on the permission-management service, which answers "what may this principal do here?" once, for many resources, instead of one probe per control

Where probing is genuinely required, the parameter **must** be named `dry-run`, **must** default to `false`, and the endpoint **must** return the same status code and response shape it would return for the real execution.
