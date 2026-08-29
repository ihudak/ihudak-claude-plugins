# General Structure

**Sources:** [Zalando — API Audience (`x-audience`)](https://opensource.zalando.com/restful-api-guidelines/#219), [Zalando — Naming](https://opensource.zalando.com/restful-api-guidelines/#naming), [Google AIP-122 — Resource names](https://google.aip.dev/122), [RFC 3986 — URI Generic Syntax](https://www.rfc-editor.org/rfc/rfc3986.html), [OpenAPI Specification 3.1 — Server Object](https://spec.openapis.org/oas/v3.1.0.html#server-object)

A system is a collection of services that interact with each other. The smallest building block is a single deployed *service* which provides one or more APIs, each containing several REST endpoints.

- A service **may** expose some of its APIs publicly on the API gateway. Such an API is referred to as a _public API_.
- A service **may** expose APIs on the gateway that are intended for first-party or contracted partner clients but not for the general public. Such APIs are referred to as _partner APIs_.
- A service **may** contain purely internal APIs intended for other services in the same system to use.
- A service **may** contain operational APIs used by operators for debugging, deployment or monitoring purposes.

## API Audience

Every API **must** declare its intended audience in the OpenAPI document using the `x-audience` extension on the `info` object. The value **must** be one of the following four, and an API **must** declare exactly one:

| `x-audience`         | API Properties                                                                          |
|----------------------|-----------------------------------------------------------------------------------------|
| `external-public`    | <ul><li>Always publicly exposed by the API gateway</li><li>Used by customers and by other services inside the system</li><li>REST only</li><li>Strongest backward-compatibility obligation</li></ul> |
| `external-partner`   | <ul><li>Exposed by the API gateway (reachable from the internet)</li><li>Not documented or advertised to the general public (e.g., hidden in the rendered reference)</li><li>Used only by first-party or contracted partner clients</li><li>REST and WebSockets are allowed</li></ul> |
| `company-internal`   | <ul><li>Never publicly exposed by the API gateway</li><li>Used by other services in the same system, or by internal clients reachable only on a private network</li><li>REST and WebSockets are allowed</li></ul> |
| `component-internal` | <ul><li>Never publicly exposed by the API gateway</li><li>Non-functional endpoints — statistics, debug, deployment, test</li><li>Consumed by operators and infrastructure components only</li><li>REST only</li></ul> |

Splitting an API by audience is a *design* decision, not a deployment detail: an endpoint's audience determines its compatibility obligations ([API Versioning](../rest-api-guidelines/API%20Versioning.md)) and whether it appears in published documentation ([Swagger Documentation](../rest-api-guidelines/Swagger%20Documentation.md)).

## Services and APIs

If a service hosts more than one API for the same audience, it **must** separate them using an _API identifier_. The API identifier **may** be omitted if the service provides only one such API. All service APIs **must** be [versioned](../rest-api-guidelines/API%20Versioning.md).

Service-local URLs **should** follow this structure:
```
http://<service-host>/<audience-segment>/[<api-identifier>/]<version>/<api resources>
```
where `<audience-segment>` is the deployment's own routing segment for the audience — commonly `public`, `partner`, `internal`, `operations`.

### Examples
```
app-registry.internal/public/v1/apps                              -- no api-identifier
app-registry.internal/public/app-registry-api/v1/apps             -- alternative using an api-identifier

persistence.storage/public/query-api/v1/queries:execute           -- 1 service with 2 APIs
persistence.storage/public/query-api/v1/queries:validate
persistence.storage/public/entity-model-api/v2/models
ingest.storage/public/log-ingest/v2/logs                          -- 2nd service in the same namespace "storage"
ingest.storage/public/metric-ingest/v1/metrics
```

## Public APIs

Services are directly reachable only inside the system. External access always passes through the API gateway, so every externally exposed service must be mapped to a path entry in the publicly exposed URL. If a service uses API identifiers, the identifier is mapped as the public service name; if it is omitted, the service name is used.

Public APIs **must** be reachable under a single stable root path:
```
https://<root>/<public service name>/v<major version>/<api resources>
```

### Examples
#### API on the service:
```
app-registry.internal/public/v1/apps                              -- no api-identifier
app-registry.internal/public/app-registry-api/v1/apps             -- alternative using an api-identifier
```

#### Public API on the API gateway:
```
https://api.example.com/app-registry/v1/apps                      -- mapped from api-identifier or service name
https://api.example.com/app-registry/v1/openapi.yaml              -- OpenAPI document (3.1) per API
```

### Public Service Namespaces

In most cases the default URL structure is enough to map a service to a public service. In some cases it is not — especially when multiple services contribute to a single logical public surface. Those services **may** be grouped into a _service namespace_, which lets each service keep its own version instead of forcing one shared version on all of them. Services contributing to one service namespace **should** be deployed in one deployment namespace of the same name.

General structure:
```
https://<root>/<service namespace>/<public service name>/v<major version>/<api resources>
```

### Examples

A storage system covered by two services (`persistence` and `ingest`):

```
persistence.storage/public/query-api/v1/queries:execute
persistence.storage/public/query-api/v1/queries:validate
persistence.storage/public/entity-model-api/v2/models

ingest.storage/public/log-ingest/v2/logs
ingest.storage/public/metric-ingest/v1/metrics
```

On the API gateway those two services are grouped into the namespace `storage`:

```
https://api.example.com/storage/queries/v1/queries:execute
https://api.example.com/storage/queries/v1/queries:validate
https://api.example.com/storage/entity-model/v1/models

https://api.example.com/storage/log-ingest/v2/logs
https://api.example.com/storage/metric-ingest/v1/metrics
```

Service namespaces are also what makes a namespace-wide permission expressible — e.g. `storage:metrics:read` or `storage:metrics:write` (see [Permission Guidelines](../permission-guidelines/Introduction.md)).

## Partner APIs

Partner APIs (`x-audience: external-partner`) **must** be exposed under a root path distinct from the public one, so that a client cannot reach a partner endpoint by guessing a public URL:
```
https://<root>/partner/<service name>/v<major version>/<api resources>
```

Partner APIs are technically public, since they are reachable from the internet, but they are logically treated differently:
- Hidden from the published API reference in production
- Not documented in the public developer portal
- Intended for first-party or contracted clients only
- Relaxed backward-compatibility requirements compared to public APIs, because the client set is known and can be migrated

### Examples
```
-- on the service
app-registry.internal/partner/v1/apps
app-registry.internal/partner/app-registry-api/v1/apps

-- on the API gateway
https://api.example.com/partner/app-registry/v1/apps
https://api.example.com/partner/app-registry/v1/openapi.yaml       -- non-production environments only
```

## Internal APIs

A service **may** provide APIs that are not meant to be exposed publicly. On the service, such APIs **must** be grouped under the internal audience segment.

The gateway **must not** publish internal APIs to external clients, but **may** expose them to internal clients outside the system on a private route:
```
https://<internal root>/<service name>/<audience-segment>/[<api-identifier>/]<version>/<api resources>
```
Internal APIs **must** be [versioned](../rest-api-guidelines/API%20Versioning.md). The internal route is reachable only from the private network and requires separate permissions.

### Examples
```
function-proxy.internal/public/function-executor/v2/executions
function-proxy.internal/internal/function-executor/v1/async-executions   -- available to other services

platform-management.core/internal/v1/tenants
```

Exposed on the internal route:
```
https://internal.example.com/platform-management/internal/v1/tenants
```

## Operational APIs

A service **may** provide APIs that serve an operational purpose — a debug API, or an API used by deployment or monitoring components. Such APIs **must** be grouped under the operations audience segment and **must** be [versioned](../rest-api-guidelines/API%20Versioning.md) unless they are used exclusively by humans (see [API Versioning](../rest-api-guidelines/API%20Versioning.md#where-to-apply)).

Operational APIs **must not** be published to external clients. They are accessed on the private route for security reasons:
```
https://<internal root>/<service name>/operations/[<api-identifier>/]<version>/<api resources>
```

### Examples
```
app-registry.internal/operations/devops/v1
app-registry.internal/operations/ops/v3
app-registry.internal/operations/test/v2
```

Exposed on the internal route:
```
https://internal.example.com/app-registry/operations/devops/v1
https://internal.example.com/app-registry/operations/ops/v3
https://internal.example.com/app-registry/operations/test/v2
```

Recommended API identifiers for operational APIs:

| API-identifier   | Purpose	                                                                           | Examples                    |
| ---------------- |-------------------------------------------------------------------------------------- | --------------------------- |
| devops           | API used by the developers of the service itself, mainly for debugging and proactive monitoring.	| Enable a debug flag |
| ops              | Used by support and operations engineers. Typically a less detailed and less intrusive feature set than the devops API.	| <ul><li>Trigger a thread dump</li><li>Rotate or revoke a secret</li></ul> |
| deployment       | Endpoints used during rollout or other maintenance tasks.	                           | Trigger a post-update migration step |
| statistics       | Expose statistics data to internal reporting systems.                                 |                             |
| test             | APIs used only by automated tests.	                                                   |                             |
