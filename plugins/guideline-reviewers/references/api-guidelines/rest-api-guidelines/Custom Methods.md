# Custom Methods

**Sources:** [Google AIP-136 — Custom methods](https://google.aip.dev/136), [Google AIP-127 — HTTP and gRPC transcoding](https://google.aip.dev/127), [RFC 9110 §9 — HTTP Methods](https://www.rfc-editor.org/rfc/rfc9110.html#section-9), [Zalando — Resources](https://opensource.zalando.com/restful-api-guidelines/#resources)

In most cases an API can be designed using only [standard methods](../rest-api-guidelines/Standard%20Methods.md), because an action can usually be expressed as a noun (e.g. "execution" instead of "execute"). But sometimes functionality is better expressed as a _custom method_.

Custom methods are represented by _verbs_ and **should** use the following general format:
```
https://<root>/[<service namespace>/]<service name>/v<major version>/<resources>/<resource-id>:<custom-method>
```
Using a different separator for the custom method clarifies the difference between the resource name (segments separated by "/") and the method ([AIP-136](https://google.aip.dev/136)).

- Custom methods **should** be used only where a standard method, and the restriction to nouns for resource names, would make the API awkward or hard to understand.
- Custom methods **should** use the HTTP POST method.
- Custom methods **may** use the HTTP GET method where that matches the semantics of the operation; in that case the operation **must** be safe and **must not** use a request body.
- Custom methods **should not** use the HTTP PATCH method.
- Custom methods **must not** use PUT or DELETE.
- The URL **must** end with a verb separated from the path by a colon.
- Method names **must** be in _kebab-case_.
- The custom method name **must** be a verb or verb phrase, never a noun.

The colon separator is legal in a URI path segment ([RFC 3986, Section 3.3](https://www.rfc-editor.org/rfc/rfc3986.html#section-3.3)) and does not need to be percent-encoded.

#### Example: reshaping an RPC-style legacy API

A legacy API that expressed operations as trailing path segments:
```
POST https://legacy.example.com/tenantTokenRotation/start
POST https://legacy.example.com/tenantTokenRotation/finish
POST https://legacy.example.com/tenantTokenRotation/cancel
```

is redesigned as a resource with three custom methods:
```
POST https://api.example.com/token-service/v1/tenant-token:start-rotation
POST https://api.example.com/token-service/v1/tenant-token:finish-rotation
POST https://api.example.com/token-service/v1/tenant-token:cancel-rotation
```

Each custom method maps directly onto a permission action of the same name — see [Custom Method Mapping](../permission-guidelines/General%20Mapping.md#custom-method-mapping).
