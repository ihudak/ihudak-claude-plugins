# General Restrictions

**Sources:** [RFC 9110 — HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.html), [RFC 3986 — URI Generic Syntax](https://www.rfc-editor.org/rfc/rfc3986.html), [RFC 6570 — URI Template](https://www.rfc-editor.org/rfc/rfc6570.html), [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html), [RFC 6648 — Deprecating "X-" Prefixes](https://www.rfc-editor.org/rfc/rfc6648.html), [IANA HTTP Status Code Registry](https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml), [Zalando — Naming](https://opensource.zalando.com/restful-api-guidelines/#naming), [Google AIP-140 — Field names](https://google.aip.dev/140), [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md)

Although no limit is specified in [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html) or [RFC 3986](https://www.rfc-editor.org/rfc/rfc3986.html), the common agreement is to limit certain aspects of HTTP requests so that all common browsers, proxies and DNS implementations can handle them.

- Hostnames **must** be limited to 255 characters
- URLs **must** be limited to 2048 characters
- Query parameters **must** be limited to 1024 characters

# Case Sensitivity

All resource-path entries and query parameters **must** be case sensitive. This includes path parameters, query parameter names and query parameter values.

[RFC 9110, Section 4.2.3](https://www.rfc-editor.org/rfc/rfc9110.html#section-4.2.3):
> _"The scheme and host are case-insensitive and normally provided in lowercase; all other components are compared in a case-sensitive manner."_

# Naming Conventions

In general, all names in an API **should** be:

- Simple
- Intuitive
- Precise
- Consistent
- International

This includes all names of services, resources, collections, parameters, and methods.

- Names **should** be American English.
- Commonly used abbreviations may be used.
    - E.g., TTL, API, …
- The same names should be used for the same concept across all APIs.
    - E.g., do not mix terms like "delete", "remove", "erase".
- Avoid name overloading. Use different names for different concepts.
- Avoid overly generic terms like "data", "info", etc.
- Well established abbreviations like "config" or "id" should be used instead of the full name (i.e. "configuration", "information").

## Service Names

Service names **must** be URL-safe strings. They are used for internal service naming and are the default name the API gateway uses to reach the API.

- Service names **should** be _singular nouns_.
- Service names **should** be in _kebab-case_.

## Collection Names

- Collection ids **should** be _plural nouns_.
- Collection ids **should** be in _kebab-case_.

## Field Names

- Field names **must** be in _lowerCamelCase_ — the conventional casing in JSON payloads consumed by Java, TypeScript and JavaScript clients, and the JSON mapping of [AIP-140](https://google.aip.dev/140) field names.
- Field names **must not** use `snake_case`, `kebab-case` or `UpperCamelCase`. An organization that prefers `snake_case` throughout (as [Zalando](https://opensource.zalando.com/restful-api-guidelines/#118) does) **may** substitute it, but **must** then apply that single choice to every API it publishes; mixing the two casings across a product is what this rule exists to prevent.

## Field Values

- Enum values **must** be single words in _UPPER_SNAKE_CASE_. This includes enums used in query parameters.

## Query Parameters

- Query parameter names **must** be in _kebab-case_.
- Array parameters **should** be encoded with _style=form_ and _explode=false_

#### Example for array parameter:
```
- name: my-param
  in: query
  schema:
    type: array
    items:
      type: string
  style: form
  explode: false
```
#### Result:
```
?my-param=value1,value2,value3
```
This typically comes into play when dealing with [field filtering](../rest-api-guidelines/Filtering%20And%20Sorting.md#field-filtering-and-partial-results) or [sorting](../rest-api-guidelines/Filtering%20And%20Sorting.md#sorting).

## Headers

- Header names **should** use _hyphenated title case_ (e.g. `Content-Type`, `Retry-After`). Because header handling in the wild is inconsistent, all APIs **must** accept header names case-insensitively ([RFC 9110, Section 5.1](https://www.rfc-editor.org/rfc/rfc9110.html#section-5.1)).
- The `X-` prefix is deprecated by [RFC 6648](https://www.rfc-editor.org/rfc/rfc6648.html) and **must not** be used for new headers.
- A custom header **must** carry the organization's single declared prefix (this document uses the placeholder `Example-`) so that it cannot collide with a standard field registered later. See [API Context Information](../rest-api-guidelines/API%20Context%20Information.md).

## Path Parameters

- Path parameter names are not visible in a request URL, but they are visible in the rendered API reference. They are therefore customer-facing and **must** follow a common schema.
- Path parameter names **should** be _singular nouns_.
- Path parameter names **must** be in _kebab-case_.
- Path templating **must** follow [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570.html) simple string expansion as used by OpenAPI: `/widgets/{widget-id}`.

# HTTP Response Codes

- APIs **must** use only status codes registered at [IANA](https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml).
- APIs **must not** define proprietary HTTP status codes (_9xx_ codes **must not** be used).
- APIs **should** prefer a small set of HTTP status codes; lesser-known status codes should be avoided if possible.

## Success Codes

These are the recommended success response codes to use:

| Success Status Code	 | Description                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------- |
| 200 - OK	             | Successful execution of the request, the result is returned in the response.                    |
| 201 - Created	         | Successful execution of the request, the response body **may** be empty in this case.           |
| 202 - Accepted	     | Request was accepted and will be executed asynchronously at a later point in time. The response body may contain a reference to check the status of the execution (see [Long Running Operations](../rest-api-guidelines/Long%20Running%20Operations.md)). In some cases (e.g. high-volume data ingest) it **may** be empty. |
| 204 - No Content	     | Successful execution of the request, no result. The response body **must** be empty in this case. |

## Redirect Codes

HTTP 3xx redirection codes **should not** be used unless an API explicitly works with content type `text/html`. Instead of a 3xx, a JSON API **should** return HTTP 404 - Not Found.

If redirection is still required (e.g. inside the gateway implementation), HTTP 307/308 **should** be preferred over 301/302, because they preserve the request method ([RFC 9110, Section 15.4](https://www.rfc-editor.org/rfc/rfc9110.html#section-15.4)).

## Error Codes

If an error status code is returned, the response **should** contain an error envelope where possible (an error generated by the web server itself sometimes cannot carry one). See [Error Response Format](../rest-api-guidelines/Common%20Schemas.md#error-response-format) for the two permitted shapes. These are the recommended error response codes to use:

| Error Status Code	          | Description                                                                                                                                                                                                                                                                               |
|-----------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 400 - Bad Request	          | The request syntax was corrupt. <p>This is also the default fallback code to transport an application-level error if no specific error code is available (e.g., the request was valid, but the application logic refused to execute it due to some application restriction like a quota). |
| 401 - Unauthorized          | The request was rejected because the client needs to be authenticated first.                                                                                                                                                                                                              |
| 403 - Forbidden	            | The request was rejected because the (authenticated) client did not have the necessary permissions. See [Error Response Format](../rest-api-guidelines/Common%20Schemas.md#error-response-format) for the required details in the error response.                                          |
| 404 - Not Found	            | The requested resource was not found (it never existed).                                                                                                                                                                                                                                  |
| 409 - Conflict	             | The write operation failed because a conflict was detected by the ["optimistic locking"](../rest-api-guidelines/Conflicts%20and%20Locking.md#optimistic-locking) strategy.                                                                                                                |
| 410 - Gone                  | The requested resource was not found although it existed some time ago.                                                                                                                                                                                                                   |
| 412 - Precondition Failed   | A conditional request (`If-Match`) was rejected because the precondition did not hold ([RFC 9110, Section 13](https://www.rfc-editor.org/rfc/rfc9110.html#section-13)).                                                                                                                   |
| 429 - Too Many Requests     | 	The client sent too many requests in a given time span (see [Rate Limiting and Throttling](../rest-api-guidelines/Design%20Patterns.md#rate-limiting-and-throttling)).                                                                                                                    |
|                             |                                                                                                                                                                                                                                                                                           | 
| 500 - Internal Server Error | 	Unspecified server error (typically caused by internal problems like unhandled exceptions).                                                                                                                                                                                              |
| 501 - Not Implemented	      | Standard or custom method is not supported by the API.                                                                                                                                                                                                                                    |
| 503 - Service Unavailable	  | Service is temporarily unavailable.                                                                                                                                                                                                                                                       |
