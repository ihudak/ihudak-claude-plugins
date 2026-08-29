# Execution Context

**Sources:** [RFC 9110 §5 — Fields](https://www.rfc-editor.org/rfc/rfc9110.html#section-5), [RFC 6648 — Deprecating "X-" Prefixes](https://www.rfc-editor.org/rfc/rfc6648.html), [RFC 7519 — JSON Web Token](https://www.rfc-editor.org/rfc/rfc7519.html), [RFC 6750 — Bearer Token Usage](https://www.rfc-editor.org/rfc/rfc6750.html), [RFC 7239 — Forwarded HTTP Extension](https://www.rfc-editor.org/rfc/rfc7239.html), [W3C Trace Context](https://www.w3.org/TR/trace-context/), [RFC 9110 §12.5.4 — Accept-Language](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.5.4), [ISO 639-1](https://www.iso.org/iso-639-language-codes.html), [Semantic Versioning 2.0.0](https://semver.org/), [Zalando — Common headers](https://opensource.zalando.com/restful-api-guidelines/#headers)

APIs need to accept several forms of execution context when they are called. Some contexts are specific to an API; others **must** be universally supported. All execution contexts **must** be transported as [request headers](../rest-api-guidelines/Conventions.md#headers).

All execution-context request headers **must** be preserved. Even if an API does not itself use a context header, it **must** forward that header on requests it makes to other services — those services may require the context.

Context headers are not a direct part of a service's API contract (they are not shown in the published API reference). They are implicit meta-information set by the environment to describe the context in which a call is executed. Clients typically have no, or limited, control over them.

## Header naming

Every context header **must** carry a single organization-wide prefix, so that it can never collide with a field registered by IANA later. This document uses the placeholder prefix `Example-`; substitute your organization's prefix once, everywhere.

- The prefix **must** be identical in every API the organization publishes.
- The prefix **must not** be `X-` ([RFC 6648](https://www.rfc-editor.org/rfc/rfc6648.html)).
- Header names **must** be written in hyphenated title case (`Example-App-Context`), and **must** be accepted case-insensitively ([RFC 9110, Section 5.1](https://www.rfc-editor.org/rfc/rfc9110.html#section-5.1)).
- Where a standard header already carries the information (`Authorization`, `Accept-Language`, `Forwarded`, `traceparent`), the standard header **must** be used instead of a custom one.

## Tenant Context

All [public APIs](../rest-api-guidelines/General%20Structure.md#public-apis) in a multi-tenant system **must** support the tenant context in the `Example-Tenant` header. The header **must** contain the tenant identifier as a plaintext string. It is set by the API gateway (typically derived from the public DNS name) and **must** also be set when the API is called from inside the system. [Internal APIs](../rest-api-guidelines/General%20Structure.md#internal-apis) and [operational APIs](../rest-api-guidelines/General%20Structure.md#operational-apis) **may** be global by nature and therefore **may** omit the tenant context.

#### Example
```
GET /app-registry/v1/apps
Example-Tenant: abc12445
```

**Caution**: the presence of this header does not mean access to the tenant has already been authorized. Each service **must** authorize tenant access itself. The semantics of the header are: "I want to execute this request in this tenant."

## Authentication Context

Authentication **must** be carried as a JWT bearer token ([RFC 7519](https://www.rfc-editor.org/rfc/rfc7519.html)) in the `Authorization` header, in the form defined by [RFC 6750, Section 2.1](https://www.rfc-editor.org/rfc/rfc6750.html#section-2.1). The header is set by the API gateway (negotiated with the identity provider) and **must** also be set when the API is called from inside the system.

Transporting the token in a query parameter or a cookie **must not** be supported ([RFC 6750, Section 5.3](https://www.rfc-editor.org/rfc/rfc6750.html#section-5.3)). See [Authentication](../rest-api-guidelines/Authentication.md) for details.

#### Example
```
GET /app-registry/v1/apps
Example-Tenant: abc12445
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Application Context

Where an application platform runs first-party or third-party apps against the API, an additional context **may** be supported: the _application context_ — the id of the app making the call. If it is supported, it **must** be carried in the `Example-App-Context` header as a plaintext app id.

If the header is set by the caller but the API does not use it, the header **should** be ignored. An API **may** log it as part of e.g. its audit logging.

#### Example
```
GET /app-registry/v1/apps
Example-Tenant: abc12445
Example-App-Context: com.example.appshell
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

APIs that treat apps as resources (like an app registry) **should** address them by app id as a path parameter.

## Application Version

In addition to the application context, an API **may** support the app version in the `Example-App-Version` header, carrying a [SemVer](https://semver.org/) string in the format `<major>.<minor>.<patch>[-<suffix>]`. The application version header **requires** the [application context header](#application-context) to be present as well.

If the header is set by the caller but the API does not use it, the header **should** be ignored.

#### Example
```
GET /app-registry/v1/apps
Example-Tenant: abc12445
Example-App-Context: com.example.appshell
Example-App-Version: 1.0.1-dev.20231010T102528+04997783
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Function Context

If a request originates from a serverless function belonging to an app, it **may** carry the `Example-Function-Context` header naming that function in plaintext. This can be used for billing calculations or for enabling functionality based on the calling function. The function context header always accompanies the [application context header](#application-context).

#### Example
```
GET /app-registry/v1/apps
Example-Tenant: abc12445
Example-App-Context: com.example.appshell
Example-Function-Context: my-cool-function
Example-App-Version: 1.0.1-dev.20231010T102528+04997783
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## API Gateway Context

Every request from outside the system passes through an API gateway. Where a deployment runs more than one kind of gateway (e.g. a public one and a private one), services sometimes need to distinguish the source. The gateway therefore sets its own type in the `Example-Apigateway` header (`public` or `private`).

This header is intended for consistency checks against other headers (mainly the [internal service context](#internal-service-context)) and for log deduplication. It **should not** drive business logic.

#### Example
```
GET /app-registry/v1/apps
Example-Tenant: abc12445
Example-Apigateway: public
Example-App-Context: com.example.appshell
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Origin IP Address

The API gateway sets the `Example-Origin-Address` header with the spoof-proof IP address of the client performing the request. Its value **must** be used for audit events of origin type "REST" — never the `X-Forwarded-For` header, which any client can set.

Where the deployment's edge already emits the standard [`Forwarded`](https://www.rfc-editor.org/rfc/rfc7239.html) header and strips client-supplied copies of it, `Forwarded` **must** be used instead of a custom header.

#### Example
```
GET /app-registry/v1/apps
Example-Tenant: abc12445
Example-Origin-Address: 83.164.160.102
```

## Trace Context

Distributed tracing context **must** be transported using the standard [W3C Trace Context](https://www.w3.org/TR/trace-context/) headers `traceparent` and `tracestate`. A custom trace or correlation header **must not** be introduced. The trace-id from `traceparent` is what the `traceId` field in an [error](../rest-api-guidelines/Common%20Schemas.md#error-response-format) or [warning](../rest-api-guidelines/Common%20Schemas.md#warnings-in-responses) detail refers to.

## Language

A UI may let users select a display language, stored as a per-user setting. Some APIs **may** support that selection in the `Example-Language` header, carrying a single [ISO 639-1](https://www.iso.org/iso-639-language-codes.html) code. The set of supported languages is typically small. The default **must** be "en" if the header is missing, invalid, or names an unsupported language.

#### Example
```
GET /app-registry/v1/apps
Example-Tenant: abc12445
Example-App-Context: com.example.appshell
Example-Language: ja
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Note

[`Accept-Language`](https://www.rfc-editor.org/rfc/rfc9110.html#section-12.5.4) reflects the browser's configuration rather than the user's stored preference. Where the two differ, the stored preference wins and `Accept-Language` **must not** be used as the backend's source of truth.

## Local Development Mode

A local development toolkit may give a developer's machine access to a live tenant's APIs. While an app is being developed locally, its requests **should** be marked with development headers, so that the platform can distinguish an app under development from an officially installed one. This makes it possible to work on a new version of an already-installed app without interfering with the installed copy.

In that case the requests set headers as follows:

- [`Example-App-Context`](#application-context) is set to the constant `local-dev-mode`.
- `Example-Dev-App-Id` is set to the actual app id.
- `Example-Dev-Context` is set to the actual app id. This header **may** be extended later.

## Internal Service Context

Some APIs **may** support context information naming the internal service that is making the request. This can drive special handling — e.g. a query engine that assigns internal service queries to a different resource pool than customer queries.

The context is transported in the `Example-Internal-Service-Context` header, which **must** contain a string uniquely identifying the calling service in this format:
```
svc.<service-name>.<use-case-name>
```

#### Example
```
GET /storage/query/v1/queries:execute
Example-Tenant: abc12445
Example-Internal-Service-Context: svc.reporting.usage-stream
```

Public API gateways **must** strip this header from inbound requests, so that it cannot be forged by an external caller. Internal gateways let it pass. The supported values **must** be agreed between the owning service team and its client teams.

## Workflow Context

Where an automation or workflow engine triggers API calls, the workflow id **may** be provided in the `Example-Workflow` header as plain text. This meta information is used for self-monitoring and auditing, and **may** be used for billing calculations.

#### Example
```
GET /storage/query/v1/queries:execute
Example-Tenant: abc12445
Example-Workflow: 38234ae1-478e-4035-a66c-6f4e0ee5c05f
```

## Document Context

Documents (dashboards, notebooks) are a common source of requests, because they may contain executable ad-hoc code. For self-monitoring and debugging, the document id **may** be provided in the `Example-Document` header as plain text. This meta information **must not** drive business logic, because an external caller can spoof it.

#### Example
```
GET /storage/query/v1/queries:execute
Example-Tenant: abc12445
Example-Document: 38234ae1-478e-4035-a66c-6f4e0ee5c05f
```

# Response Context

All responses **must** carry a hint about where the response was produced. A system with an API gateway in front of its services has two possible responders: the gateway itself may answer (e.g. when authorization fails or throttling blocks the call) or the service may. Clients may need to act differently in each case.

## Response Source

The response source is transported in the `Example-Response-Source` response header. The gateway **must** ensure the header is always set. It has exactly two values:

- `api-gateway` — the response was produced by the gateway. This happens for gateway-owned endpoints, and when the gateway intercepts a request (authorization failure, throttling).
- `service` — the response was produced by the called service.

Services **must not** set this header themselves; they **may** read it on responses they receive.
