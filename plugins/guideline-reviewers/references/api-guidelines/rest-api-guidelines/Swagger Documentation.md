# Introduction & Goals

**Sources:** [OpenAPI Specification 3.1](https://spec.openapis.org/oas/v3.1.0.html), [Swagger UI](https://swagger.io/tools/swagger-ui/), [Redoc](https://redocly.com/redoc/), [Zalando — API design and documentation](https://opensource.zalando.com/restful-api-guidelines/#101), [Zalando — Meta information](https://opensource.zalando.com/restful-api-guidelines/#meta-information), [Google AIP-192 — Documentation](https://google.aip.dev/192), [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md)

API documentation is published as OpenAPI documents rendered in an API reference UI (Swagger UI, Redoc, or equivalent) hosted at the API gateway. Each service serves its own document, and the gateway adapts the document to the external representation (paths, URLs, etc.).

Many services contribute to one overall product API, each maintained by a different team. **Conforming to common structural conventions is what makes the combined result feel like one API rather than a directory of unrelated ones.** This covers naming schemas, versioning formats, general structure, and shared components wherever possible.

Although endpoints are technically APIs on deployed services, they are presented to consumers as "services": the public App Registry API is published as "App Registry Service". See [General Structure](../rest-api-guidelines/General%20Structure.md).

# "Select a Definition" — The Service List

The service list is the consumer's starting point and the first impression of the product API.

First and foremost: **it is a list of services, not a list of APIs.** See [General Structure](../rest-api-guidelines/General%20Structure.md) for the distinction.

List entries **must** follow these rules:

- Show a service name, not an operation. The name **must** be approved by whoever owns the product's external naming.
- Avoid redundant suffixes like "API" or "Service"; use the real name.
- Do not show the service version when only one version exists. Show the version only when multiple versions of the service are available.

# The Service Name

Service names **must** follow these rules:

- Use the same name in all relevant locations:
    - Service list
    - `info.title`
    - URLs (OpenAPI document path and server path) — a shortened form of the name **may** be used for simplicity
- Translate multi-word names to kebab-case in URLs
    - E.g. "App Registry" becomes "app-registry"

The service version **must** be the last segment of the `servers` URL. It **must not** appear in the `paths` section of the document.

# Consistent Document Content

## Overview

Each service **must** provide at least an _Overview_ in `info.description`, briefly describing the service, its purpose and its general functionality. It **should** be kept short and **may** link to public product documentation. The Overview **should** use Markdown for readability. Additional sections **may** be added but **should** stay short.

Example of the `info` section:
```
info:
  title: "<my service name>"
  description: |
    # Overview
    the quick brown fox jumps over the lazy dog
    ## Subsection
    the quick brown fox jumps over the lazy dog
  version: 0.0.7
  x-audience: 'external-public'
```

Documentation entries **must not** reference internal documentation or internal concepts (e.g. the internal context headers described in [API Context Information](../rest-api-guidelines/API%20Context%20Information.md)), even where those are relevant to the service implementation. What is not reachable by the reader does not belong in the reader's reference.

# OpenAPI Tag Usage

OpenAPI tags **should** group operations logically, not technically. A service **should not** group all read operations separately from all write operations.

Tag descriptions **should** be provided unless the tag name is self-explanatory. Tag descriptions **should** be short and concise. Tags **should not** be applied extensively; over-tagging hurts readability.

# Paths

- Required permission scopes **must** be visible for each path (rendered from the `security` requirement)
- A summary and/or description **must** be provided
    - For path operations
    - For parameters (query, path, header)
    - For request bodies
    - For response bodies
- Error responses **must** follow the [common format](../rest-api-guidelines/Common%20Schemas.md#error-response-format)
    - The [OpenAPI template file](../template/openapi-template.yaml) already contains the most common error responses

# HTTP Response Codes

The API specification **must** always contain a default that covers all error codes. This can be either the [OpenAPI `default` response](https://spec.openapis.org/oas/v3.1.0.html#responses-object) or the two range definitions `4XX` and `5XX`. The default error response **should** use the (typically minimal) error envelope defined in [Error Response Format](../rest-api-guidelines/Common%20Schemas.md#error-response-format).

Any response code with a service-specific meaning, and every response code representing successful execution, **must** be specified in addition to the default range definitions — even when the response envelope is identical to the default.

Some error codes are common behaviour across all services and do not need to be documented on every operation. Omitting them reduces the size of the rendered reference and removes redundancy.

The following codes are considered common knowledge and **should not** be documented individually unless their usage deviates from the norm or carries service-specific information:

| Response Code	                  | Common Meaning                                                        |
| ------------------------------- | --------------------------------------------------------------------- |
| HTTP 400 - Bad Request	        | Omit unless it carries specific information about the syntax error    |
| HTTP 401 - Unauthorized	        | Produced by the shared authentication layer; documented centrally     |
| HTTP 403 - Forbidden	          | Produced by the shared authorization layer; documented centrally      |
| HTTP 404 - Not Found	          | **Should** be omitted if the service makes no explicit distinction between 404 and 410 and the response carries no additional information about the failure |
| HTTP 500 - Internal Error	      | Any unspecified internal error, typically produced by generic error handling |
| HTTP 501 - Not Implemented      | Method not supported, typically produced by the framework or web server |
| HTTP 503 - Service Unavailable	| E.g. used when [throttling](../rest-api-guidelines/Design%20Patterns.md#rate-limiting-and-throttling) requests; **should** be documented if it carries specific retry information, **may** be omitted otherwise |

See the [OpenAPI template file](../template/openapi-template.yaml) for a worked example.

This lets code generators build standard response-handling code without every service repeating the same documentation.
