# Backward Compatibility

**Sources:** [Semantic Versioning 2.0.0](https://semver.org/), [Zalando — Compatibility](https://opensource.zalando.com/restful-api-guidelines/#compatibility), [Zalando — Deprecation](https://opensource.zalando.com/restful-api-guidelines/#deprecation), [Google AIP-180 — Backwards compatibility](https://google.aip.dev/180), [Google AIP-185 — Versioning](https://google.aip.dev/185), [RFC 9745 — The Deprecation HTTP Response Header Field](https://www.rfc-editor.org/rfc/rfc9745.html), [RFC 8594 — The Sunset HTTP Header Field](https://www.rfc-editor.org/rfc/rfc8594.html), [OpenAPI Specification 3.1](https://spec.openapis.org/oas/v3.1.0.html)

The main assumption is this: all APIs are used by clients in various ways at all times. An API **must not** break any request of any client that already worked at some time.

Clients are not restricted to one form of interaction with an API. They may:

- Access an API in a "raw" way using HTTP and JSON only
- Use a published [SDK](../rest-api-guidelines/SDKs.md) to access an API
- Use the published [OpenAPI documents](../rest-api-guidelines/OpenAPI.md) as a basis for auto-generated code (using public tooling such as [OpenAPI Generator](https://openapi-generator.tech/))

# API Versioning

Each service **must** maintain its own individual API version. There is no product-wide API version that applies to all services. A service **must** apply semantic versioning to its API as described by [SemVer 2.0.0](https://semver.org/).

General version format:
```
<major>.<minor>.<patch>
```

## Where to apply?

Public APIs (`x-audience: external-public`) **must** be versioned. They are used by customers who rely on the API being backward compatible.

Partner APIs (`x-audience: external-partner`) **must** be versioned. They are used by first-party and contracted clients who rely on the API being backward compatible.

Internal APIs (`x-audience: company-internal`) **must** be versioned. They are used by other services that rely on the API being backward compatible.

Operational APIs (`x-audience: component-internal`) **may** be versioned. If an API is only ever driven by a human operator, versioning **may** be skipped.

## Version Updates

_Major_ version ('x.\*.\*') **must** be incremented if a breaking change is introduced (e.g., a field is removed or renamed, or an HTTP response code is changed). Any major change **must** carry the whole API surface, not just a delta.
E.g., if API version 1.0.0 contains 3 methods _List_, _Create_, _Delete_ and the _Create_ method breaks, the new API version 2.0.0 **must** contain all 3 methods again to keep the API consistent. This avoids mixing API versions in one client and allows the whole 1.0.0 version to be deprecated later as a unit.

_Minor_ version ('\*.x.\*') **must** be incremented if a backward compatible change is introduced to the API (e.g., a new field is added to a response, or a new optional query parameter is introduced). Extensions of an existing API in general are not considered a breaking change.

_Patch_ version ('\*.\*.x') **must** be incremented if anything else in the API description changes that does not affect the functionality or structure of the API (e.g., additional examples or documentation in the OpenAPI document).

In a _hotfix_ scenario where a bug in the API _implementation_ is fixed, the API version **must not** be changed.

## Breaking Changes

What are breaking changes? In short: every change to the API that leads to existing clients misbehaving (i.e. changing their behavior) or failing entirely (i.e. not compiling, or failing to execute requests or parse responses).

Examples are:

- Renamed or changed API endpoints (e.g. path changes)
- Removed API endpoints
- Renamed response fields
- Removed response fields
- Changed "required" response fields to being optional
- Changed optional request fields to being "required"
- Changed types of response fields
- Changed or removed HTTP response codes
- Renamed query parameters
- Removed query parameters
- Added validation constraints to an existing request field
- Changed the `operationId` of an existing operation (see [OpenAPI](../rest-api-guidelines/OpenAPI.md#operationid))

## Behavioral Changes

Sometimes an API change is not visible in the API syntax at all. Behavioral changes **may** be breaking as well:

- Adding new entries to enumerations. Although this is technically an extension, it may break client code in strongly typed languages.
- Changes in the semantics of a response field (e.g., switching an absolute timestamp to a relative timestamp, or changing the resolution of a field from milliseconds to seconds).
- Skipping fields in certain scenarios.
- Changing the HTTP response code, which affects error handling on the caller side.

# API Version in the URL

The full version (`major`.`minor`.`patch`) is not visible in the URL. It is visible in the OpenAPI document, the generated client and the API documentation. The URL carries only the part of the version that governs compatibility.

## URL Format for Officially Released APIs

Only the `major` version part **must** be included as the segment following the service name in the URI path:
```
https://<root>/[<service namespace>/]<service name>/v<major version>/<service resources>
```

Prefix 'v' **must** be lower case. The `major` version string **must** be encoded as a decimal integer.

Example:
```
https://api.example.com/app-registry/v1/apps
```

## URL Format during Initial Development of an API

During _initial development_ of an API, `major` version '0' **must** be used. Anything **may** change at any time. Breaking changes **must** be represented by incrementing the `minor` version.

As long as version '0' is used, the `minor` version **should** be included in the URL:
```
https://<root>/[<service namespace>/]<service name>/v0.<minor version>/<service resources>
```
Prefix 'v' **must** be lower case. The `minor` version string **must** be encoded as a decimal integer.

Example:
```
https://api.example.com/app-registry/v0.2/apps          -- must not be released as generally available
```

## Version Consistency

The API version **must** be consistent across all of these locations in the OpenAPI document:

- The full semantic version (`major`.`minor`.`patch`) **must** be the value of the `info.version` field
- The `major` version **must** be part of every `servers[].url`
- The `major` version **must** be part of the `x-gateway-url` extension wherever that extension is present (see [OpenAPI](../rest-api-guidelines/OpenAPI.md#api-gateway-path))

A document whose `info.version` is `3.1.4` while its `servers[].url` ends in `/v2` is self-contradictory and **must** be rejected: a client generated from it will call the wrong API.

#### Example

```
openapi: '3.1.0'
info:
  version: '3.1.4'

servers:
  - url: '/public/my-service/v3'
    x-gateway-url: '/my-service/v3'
```

## Going GA and API previews

Any '0.\*.\*' version **should not** be released publicly. Version 1.0.0, represented as 'v1' in the URL, **must** be used for the first generally available release of the API.

There are exceptions. Sometimes a preliminary API is shown to a selected set of preview customers to gather feedback. In that phase it is allowed to expose '0.\*.\*' versions publicly. This always involves telling those preview customers that the API may change and that the backward-compatibility requirements do not fully apply.

# API Deprecation

It is always preferable to support an older service version for a long time, to avoid breaking client integrations. But eventually a service version reaches its end of life and is removed.

Every API that is about to be removed **must** go through two phases — _Deprecation_ and _Sunsetting_.

- _Deprecation_ means that the service version is no longer recommended for use, even though it is still fully operational.
- _Sunsetting_ means that the service version will be shut down: at the announced time it will no longer be available.

## General Rules

Only a whole service version can be removed. Service versions **must** stay backward compatible during their whole lifecycle. It is therefore prohibited to remove any operation or single field within a published service version.

### Deprecation

- A production-grade alternative service version **must** be available, unless the reason for the deprecation is to remove the capability entirely.
- A migration guide to the alternative service version **must** be available, unless the reason for the deprecation is to remove the capability entirely.
- Release notes **must** contain the deprecation information.
- In the OpenAPI document of the service version, the [`deprecated` field](https://spec.openapis.org/oas/v3.1.0.html#operation-object) **must** be set on all operations of the deprecated service.
- In the OpenAPI document a link to the alternative service version **must** be provided.
- In the OpenAPI document either a migration description or a link to a migration guide **must** be provided.
- A [`Deprecation` header](https://www.rfc-editor.org/rfc/rfc9745.html) **must** be added to all responses of the service version. Sunset dates are carried by a separate header.

Single fields **may** be marked as deprecated, e.g. if a better alternative is available within the same service version. The deprecated field **must** remain fully supported for the sake of backward compatibility. The `Deprecation` header **must not** be set when only a field is deprecated — that header is reserved for the deprecation of a whole service version.

### Sunset

- A sunset date **must** be defined early.
- Release notes **must** contain the sunset date.
- In the OpenAPI document of the service version the sunset date **must** be shown at the service level.
- A [`Sunset` header](https://www.rfc-editor.org/rfc/rfc8594.html) carrying the sunset date **must** be added to all responses of the service version.

# Public APIs vs. Partner and Internal APIs

Backward-compatibility requirements are strongest for public APIs, because the client population is unknown. A public API version typically **must** stay available for a long time — months, sometimes years — depending on measured client usage and the organization's published compatibility policy.

Partner APIs **may** be sunset much faster, because the client set is known and can be migrated deliberately.

Internal APIs **may** also be sunset faster, because their only clients are other services within the same system, released on a schedule the same organization controls.
