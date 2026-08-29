# Definition

**Sources:** [Google AIP-151 — Long-running operations](https://google.aip.dev/151), [RFC 9110 §15.3.3 — 202 Accepted](https://www.rfc-editor.org/rfc/rfc9110.html#section-15.3.3), [RFC 9110 §15.5.11 — 410 Gone](https://www.rfc-editor.org/rfc/rfc9110.html#section-15.5.11), [RFC 9110 §10.2.2 — Location](https://www.rfc-editor.org/rfc/rfc9110.html#section-10.2.2), [RFC 4648 §5 — base64url](https://www.rfc-editor.org/rfc/rfc4648.html#section-5), [Microsoft REST API Guidelines — Long-running operations](https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md), [Zalando — Asynchronous processing](https://opensource.zalando.com/restful-api-guidelines/#events)

Any request that takes too long to wait for synchronously is a "long running operation". Such operations **must** be implemented asynchronously.

The typical workflow from the client's perspective is:

- An initial _trigger_ request that starts the operation in the background and immediately returns a unique id for later polling.
- Periodic _polling_ requests (using that id) to check the status of the operation and eventually fetch the result.
- An optional _cancel_ request (using that id) to stop execution early.

Long running operations come in two flavours: _resource-based_ and _RPC-like_.

# Resource Based Operations

Some operations on resources take a long time — tens of seconds, minutes, or hours. This typically happens with resource creation and deletion. An example is installing an application in an app registry: the installation requires several background tasks to finish before the app is considered installed and usable, which may take minutes.

When a (standard or custom) method on a resource executes asynchronously, the API **must** reflect that in a RESTful way:

- The trigger request **may** accept an arbitrary set of additional parameters in the request body or as query parameters.
- The trigger request **must** return HTTP 202 - Accepted ([RFC 9110, Section 15.3.3](https://www.rfc-editor.org/rfc/rfc9110.html#section-15.3.3)).
- If the trigger request is a _Create_ method, it **must** return the id of the resource being created in the response body.
    - The resource id **must** be usable directly with the _Get_ method for status polling.
    - The resource **must** be visible in the _List_ method even before it is fully created.
    - _Create_ **should** return the resource location in the [`Location`](https://www.rfc-editor.org/rfc/rfc9110.html#section-10.2.2) header, as a URL usable directly with the _Get_ method.
- The state of the resource **must** be returned by every reading operation (_List_, _Get_) in an object named `resourceStatus`.
- `resourceStatus` **must** contain a string field named `status` defining the current state of the resource (e.g. "INSTALLING", "DEPLOYED", "INCOMPLETE"). The possible values **must** be documented so that a client can act on them.
    - `resourceStatus` **may** contain progress information in percent, as a 32-bit integer in the field `progress`. The initial value **should** be 0.
    - `resourceStatus` **may** contain additional detail about the state (e.g. sub-states of the involved operations).
- Certain states **may** prohibit certain methods on the resource. In that case HTTP 403 - Forbidden **must** be returned.
- Polling **must** be possible by calling the _Get_ method with the resource id returned by the trigger operation, and interpreting the `resourceStatus` field.
- Explicit _cancel_ is typically not supported. Instead, the natural counterpart of the operation **may** serve as a cancel: calling _Delete_ while _Create_ is running **may** be interpreted as a cancellation. In most scenarios it is preferable to wait for completion and undo the result afterwards — that is easier and safer than cancelling mid-execution.

#### Example
```
POST /apps

HTTP/1.1 202 Accepted
Content-Type: application/json
Location: /apps/the-app-id
{
  "id": "the-app-id"
}


GET /apps/the-app-id

HTTP/1.1 200 OK
Content-Type: application/json
{
  "resourceStatus" :
  {
    "status" : "INSTALLING",
    "progress" : 10,
    "functionDeploymentStatus": "SCHEDULED",
    "filesDeploymentStatus": "SCHEDULED"
  },
  "manifest": {},
  ...
}


GET /apps/the-app-id/app-icons

HTTP/1.1 403 Forbidden
Content-Type: application/json
{
  "error": {
    "code": 403,
    "message": "App installation not completed yet."
  }
}
```

# RPC-like Operations

Not every long operation acts on a resource. Some represent a function call on a general-purpose service — an asynchronous RPC. Examples are executing an analytical query over a large dataset, or running an analysis job over a data model. In neither case does a RESTful resource exist to act upon; an expensive computation is executed on a service.

Where there is no clean way to represent such an operation as resource-based, an API **may** support asynchronous RPC-like operations.

- An RPC-like long running operation **should** be provided as a [custom method](../rest-api-guidelines/Custom%20Methods.md).
- The service **must** define a hard timeout that the client cannot raise (this is often bounded by the runtime — e.g. a serverless function's maximum execution time). This overall timeout **must** be documented.

## Trigger Request

- The trigger request body **may** contain the client's timeout for the operation in seconds, in a field named `timeoutSeconds` (POST) or a query parameter named `timeout-seconds` (GET). This is the maximum time the client is willing to wait. After it passes, the service **may** cancel the operation at any time.
- The effective TTL of the operation **must** be the smaller of the client-provided timeout and the service-defined timeout.
- The initial request **may** accept an arbitrary set of additional parameters in the request body or as query parameters.

## Trigger Response — Async

The typical case: the first request is accepted and starts an asynchronous background operation the client tracks by polling.

- The response **must** be HTTP 202 - Accepted.
- The response body **must** contain a field named `requestToken` to be used for polling. The token **must** be a URL-safe string ([base64url](https://www.rfc-editor.org/rfc/rfc4648.html#section-5) or plain percent-encoded) that can be used as a query parameter without re-encoding.
- The response body **must** contain the remaining TTL in seconds in a field named `ttlSeconds` — the time left for the operation to complete normally and deliver a result.
- The response body **may** contain progress information in percent as a 32-bit integer in a field named `progress`. The initial value **should** be 0.
- The response body **may** contain a `status` string field carrying useful additional information.

#### Example
```
POST /queries:execute

HTTP/1.1 202 Accepted
Content-Type: application/json
{
  "requestToken" : "bmQgUXVhcms",
  "ttlSeconds" : 600,
  "status" : "initializing long running operation…",
  "progress" : 0
}
```

## Trigger Response — Sync

Sometimes the trigger request can already serve the result (e.g. it was in a cache). In that case the API **may** return the result immediately instead of forcing the client into a polling loop. The service **may** block the trigger request for a reasonable time (typically low single-digit seconds) to determine whether it can serve the response immediately. That delay **must** be documented.

- The response **must** be HTTP 200 - OK.
- The response body **must not** contain the field `requestToken`.
- The response body **must** contain the result of the request.
- If `progress` is supported, it **must** be present with the value 100.

#### Example
```
POST /queries:execute

HTTP/1.1 200 OK
Content-Type: application/json
{
  "response" : {
     …
  },
  "progress" : 100
}
```

## Periodic Client Polling

- Polling **must** use GET on the custom method representing the polling endpoint, with the request token as the query parameter `request-token`.
- If the operation is still running, the response **must** be HTTP 200 - OK.
- If the TTL has expired, the API **must** return HTTP 410 - Gone.
- The response body **must** contain the remaining TTL in seconds in the field `ttlSeconds`.
- If progress is supported, the response body **must** contain progress information in percent as a 32-bit integer in the field `progress`.
- The response body **may** contain a `status` string field carrying useful additional information.
- The service **may** block the request for a reasonable time (typically low single-digit seconds) to determine whether it can serve the result immediately. That delay **must** be documented.

#### Example
```
GET /queries:poll?request-token=bmQgUXVhcms

HTTP/1.1 200 OK
Content-Type: application/json
{
  "ttlSeconds" : 300,
  "progress" : 50,
  "status" : "calculating…"
}
```

## Final Request

- If the operation succeeded, the API **must** return HTTP 200 - OK.
- If the operation failed, an appropriate HTTP error response from [HTTP Response Codes](../rest-api-guidelines/Conventions.md#error-codes) **must** be returned.
- After the final request, any further request carrying the same token **must** result in HTTP 410 - Gone.
- The response body **must** contain the result of the request.
- If `progress` is supported, it **must** be present with the value 100.
- The response body **may** contain a `status` string field carrying useful additional information.

#### Example
```
GET /queries:poll?request-token=bmQgUXVhcms

HTTP/1.1 200 OK
Content-Type: application/json
{
  "response" : {
     …
  },
  "progress" : 100
}
```

## Cancel

Cancellation of a long running operation **may** be supported by defining a custom method `cancel`.

Since the operation executes asynchronously in the background, `cancel` **must** be asynchronous as well.

- If the operation is still running, the `cancel` request **must** return HTTP 202 - Accepted with an empty response body.
- If the operation has finished, the `cancel` request **must** return HTTP 200 - OK. The response body **may** contain an intermediate result. If `progress` is supported, the `progress` field **must** be present. Any further request carrying the same token **must** result in HTTP 410 - Gone.
- If `cancel` is requested after the operation has timed out (which can also happen while an asynchronous cancel is in flight), HTTP 410 - Gone **must** be returned.

#### Example
```
POST /queries:cancel?request-token=bmQgUXVhcms

HTTP/1.1 202 Accepted

POST /queries:cancel?request-token=bmQgUXVhcms

HTTP/1.1 202 Accepted

POST /queries:cancel?request-token=bmQgUXVhcms

HTTP/1.1 200 OK
Content-Type: application/json
{
  "response" : {
     …
  },
  "progress" : 70
}
```
