# Introduction

**Sources:** [OpenAPI Specification 3.1](https://spec.openapis.org/oas/v3.1.0.html), [OpenAPI Initiative](https://www.openapis.org/), [Zalando — API design and documentation](https://opensource.zalando.com/restful-api-guidelines/#101), [Zalando — API Audience (`x-audience`)](https://opensource.zalando.com/restful-api-guidelines/#219), [Google AIP-136 — Custom methods](https://google.aip.dev/136), [RFC 6749 — OAuth 2.0](https://www.rfc-editor.org/rfc/rfc6749.html), [OpenAPI Generator](https://openapi-generator.tech/)

All APIs **must** be documented by the implementing service with an [OpenAPI document](https://spec.openapis.org/oas/v3.1.0.html#openapi-document). This applies to public APIs as well as to partner, internal and operational APIs. Each API version **must** be described by a separate document.

The OpenAPI document **must** be browsable in a rendered API reference (Swagger UI, Redoc, or an equivalent renderer) for every audience that has consumers outside the owning team.

# Template File

[OpenAPI Spec Template File](../template/openapi-template.yaml)

# Format

- The OpenAPI document **must** be published in [YAML](https://yaml.org/) format under the name _openapi.yaml_.
- The `openapi` field **must** be `3.1.x`. `3.0.x` **may** be used where a required tool does not yet support 3.1; in that case the document **must** state which tool forces it.
- OpenAPI versions older than 3.0 **must not** be used.
- When the file is served by the service, the `Content-Type` header **must** be set to `application/openapi+yaml`.

# Location on the Service

The OpenAPI document **must** be located at the API version root of the service:
```
<service-host>/<audience-segment>/[<api-identifier>/]<version>/openapi.yaml
```
This mirrors the API structure described in [General Structure](../rest-api-guidelines/General%20Structure.md).

#### Examples
```
-- Public API (no api-identifier)
app-registry.internal/public/v1/apps
app-registry.internal/public/v1/app-icons
app-registry.internal/public/v1/openapi.yaml

-- Public API (using api-identifier)
app-registry.internal/public/app-registry-api/v1/apps
app-registry.internal/public/app-registry-api/v1/app-icons
app-registry.internal/public/app-registry-api/v1/openapi.yaml

-- Partner API (no api-identifier)
app-registry.internal/partner/v1/hidden-apps
app-registry.internal/partner/v1/openapi.yaml

-- Operational API (using api-identifier)
app-registry.internal/operations/ops/v1/some-resource
app-registry.internal/operations/ops/v1/openapi.yaml

-- Internal API
platform-management.core/internal/v1/tenants
platform-management.core/internal/v1/openapi.yaml

-- 1 service with 2 APIs
persistence.storage/public/query-api/v1/queries:execute
persistence.storage/public/query-api/v1/queries:validate
persistence.storage/public/query-api/v1/openapi.yaml

persistence.storage/public/entity-model-api/v2/models
persistence.storage/public/entity-model-api/v2/openapi.yaml
```

# Location on the API Gateway

The gateway maps each audience to its own root path (see [Public APIs](../rest-api-guidelines/General%20Structure.md#public-apis), [Partner APIs](../rest-api-guidelines/General%20Structure.md#partner-apis), [Internal APIs](../rest-api-guidelines/General%20Structure.md#internal-apis), [Operational APIs](../rest-api-guidelines/General%20Structure.md#operational-apis)) and **should** publish a separate rendered reference per audience, so that a document is never reachable by an audience it was not written for.

#### Examples
```
-- public API
https://api.example.com/app-registry/v1/apps
https://api.example.com/app-registry/v1/openapi.yaml

-- partner API
https://api.example.com/partner/app-registry/v1/hidden-apps
https://api.example.com/partner/app-registry/v1/openapi.yaml

-- internal / operational API
https://internal.example.com/platform-management/internal/v1/tenants
https://internal.example.com/app-registry/operations/v1/openapi.yaml
```

# OpenAPI Document Content

The OpenAPI document **may** contain any construct supported by OpenAPI 3.1. If the document describes an API exposed on the API gateway, it **must** additionally contain the mandatory entries below so that the gateway and the code generators can process it.

## API Audience

The document **must** declare its audience with the `x-audience` extension on the `info` object, using exactly one of the four values defined in [General Structure](../rest-api-guidelines/General%20Structure.md#api-audience):

```
info:
  title: 'My Service'
  version: '1.0.0'
  x-audience: 'external-public'   # external-public | external-partner | company-internal | component-internal
```

## API Gateway Path

The API path on the gateway differs from the path on the service. The mapping is owned by the gateway and described in [General Structure](../rest-api-guidelines/General%20Structure.md). The document **must** declare it with the `x-gateway-url` extension inside the `servers` entry:

```
servers:
  # base url on the service is relative; audience-segment = "public" | "partner" | "internal" | "operations"
  - url: '/<audience-segment>[/<api-identifier>]/v<major version>'

  # base url on the gateway, relative to the gateway root url
    x-gateway-url: '[/<service namespace>]/<public service name>/v<major version>'
```

This information is used by code generators to build clients for use both inside and outside the system. The gateway removes the `x-gateway-url` extension when it publishes the document, since consumers of the API do not need it.

## Version consistency

The API version specified in the OpenAPI document (the `info.version` field) **must** match the version information in the URL. All three locations — `info.version`, `servers[].url`, and `x-gateway-url` where present — **must** agree on the major version. Details are described in [API Versioning](../rest-api-guidelines/API%20Versioning.md#version-consistency).

## Context Headers

If the API accepts the [tenant context](../rest-api-guidelines/API%20Context%20Information.md#tenant-context), the document **must** declare the header as a reusable parameter:
```
components:
  parameters:
    tenantHeader:
      in: header
      name: Example-Tenant
      description: Tenant context header
      schema:
        type: string
      required: true
```

If the API accepts the [application context](../rest-api-guidelines/API%20Context%20Information.md#application-context), the document **must** declare `Example-App-Context` the same way.

Context headers are set by the gateway and are meaningful only inside the system. The gateway therefore removes them from the document when it publishes it. They are declared in the source document because code generators use them to build the server-side interface.

The header prefix (`Example-` here) is a placeholder for the organization's single declared prefix. Whatever prefix is chosen, it **must** be the same in every document the organization publishes, and it **must not** be `X-` ([RFC 6648](https://www.rfc-editor.org/rfc/rfc6648.html)).

## Authentication Context

If the API accepts the [authentication context](../rest-api-guidelines/API%20Context%20Information.md#authentication-context), the document **must** declare the OAuth 2.0 flow:
```
components:
  securitySchemes:
    oauth2:
      type: oauth2
      description: This API uses OAuth 2.0 with the 'client credentials' flow
      flows:
        clientCredentials:
          tokenUrl: https://sso.example.com/oauth2/token   ## placeholder, replaced per environment
          scopes:                                          ## scope naming: see the permission guidelines
            example:widgets:read: Read widgets
            example:widgets:write: Create or update widgets
```

- The document **must** declare exactly one OAuth 2.0 security scheme.
- That scheme **must** declare the `clientCredentials` flow and **must not** declare any other flow (`authorizationCode`, `implicit`, `password`).
- The security scheme name **must** be the same across every API in the organization. This template uses `oauth2`.
- Every operation **must** carry a `security` requirement naming that scheme with at least one scope, either on the operation or inherited from the document-level `security` field.
- Other authentication schemes (`http basic`, `apiKey`, …) **must not** be declared. See [Authentication](../rest-api-guidelines/Authentication.md).

## Additional Guidelines

### OperationId

The `operationId` is a unique string in the OpenAPI document that identifies an operation. Code generators use it to name the generated methods. These rules therefore apply:

- `operationId` **must** be present on every operation.
- `operationId` **must** be unique across the whole document ([OpenAPI 3.1, Operation Object](https://spec.openapis.org/oas/v3.1.0.html#operation-object)).
- `operationId` **must** start with a verb, so that it reads as a method name after generation (e.g. `listWidgets`, `getWidget`, `createWidget`).
- `operationId` **must** be in _lowerCamelCase_.
- Changing an `operationId` **must** be treated as a breaking change of the API, because it changes generated client code even though the HTTP surface is unchanged.

### Schema Composition — oneOf, anyOf, allOf

Combining schemas is a frequent source of confusion for readers and of divergent output across code generators. Composition **should** therefore be avoided where a flat schema will do. Where it is required, these rules apply:

- Polymorphic alternatives **must** be expressed with `oneOf` plus a [`discriminator`](https://spec.openapis.org/oas/v3.1.0.html#discriminator-object). A `oneOf` without a discriminator forces every consumer to guess the variant by trial validation.
- `anyOf` **should not** be used. Its validation semantics (one *or more* branches match) are almost never what an API means, and generators render it inconsistently.
- `allOf` **must not** be used to merge two or more named schemas. Where `allOf` is used at all, it **must** contain at most one `$ref` plus at most one inline object schema — the single generator-safe extension pattern.
- An `allOf` branch **must not** redefine a property that the referenced schema already defines. The result is ambiguous and generators disagree about which definition wins.
- A schema object **must not** combine `allOf`, `oneOf` and `anyOf` at the same level.
- Composition **must not** be nested: a schema referenced from an `allOf` **must not** itself use `allOf`. Deep inheritance chains are what make generated models unreadable.

An organization whose toolchain cannot process `allOf` at all **may** tighten the third rule to "`allOf` **must not** be used; use `oneOf` where a combination is genuinely required". A tightening like that **must** be stated explicitly in the organization's API style guide, so that a reviewer can apply it consistently. See also [DTO Inheritance](../rest-api-guidelines/Miscellaneous.md#dto-inheritance).
