# General

**Sources:** [OpenAPI Generator](https://openapi-generator.tech/), [OpenAPI Specification 3.1 — Operation Object](https://spec.openapis.org/oas/v3.1.0.html#operation-object), [Semantic Versioning 2.0.0](https://semver.org/), [Google AIP-185 — Versioning](https://google.aip.dev/185), [Zalando — Compatibility](https://opensource.zalando.com/restful-api-guidelines/#compatibility)

Client SDKs are generated from the published OpenAPI documents, using a generator such as [OpenAPI Generator](https://openapi-generator.tech/). A generated client is often the main contact point between a consumer and the API, so SDKs **must** follow common naming and structure guidelines for a coherent developer experience.

Because the SDK surface is derived mechanically from the OpenAPI document, several things that look cosmetic in the document are breaking changes in the SDK. In particular, `operationId` **must** be treated as part of the public contract (see [OpenAPI — OperationId](../rest-api-guidelines/OpenAPI.md#operationid)).

# SDK Naming

The common naming schema for all SDKs is:
```
client[-<service namespace>]-<service name>[-v<major version>]
```

_\<service namespace>_ **must** be the same name used for the [service namespace](../rest-api-guidelines/General%20Structure.md#public-service-namespaces), if the service belongs to one.

_\<service name>_ **must** be the same name used to [publicly represent the service on the API gateway](../rest-api-guidelines/General%20Structure.md#public-apis).

_\<major version>_ **must** be the major API version. For APIs still [under initial development](../rest-api-guidelines/API%20Versioning.md#url-format-during-initial-development-of-an-api) (version 0.x) the minor part **must** be appended without a separator.

_\<major version>_ **must** be omitted if the API version is 1.x — for many services that is the only version for a long time.

_\<major version>_ **must** be present if the API version is 2.x or higher.

#### Examples
```
Document Service v1.2.3 ==> client-document-service
Document Service v2.3.4 ==> client-document-service-v2
Query API v0.2.1        ==> client-query-v02
App Registry v1.1.2     ==> client-app-engine-registry       -- registry lives in a namespace named 'app-engine'
```

# SDK Versioning

Each SDK package represents one service API at one API version. The API version is part of the package name. The SDK additionally carries its own version, independent of the API version, so that the same API version can be re-released with an updated generator, template, or target-language version.

This means several SDK versions may represent exactly the same service API version, without forcing an artificial API version bump just to differentiate the packages.

# SDK Metadata

Every generated SDK package **must** carry metadata about both the SDK itself and the API version it represents:

- The SDK package version **must** be declared in the package manifest of the target ecosystem (e.g. `package.json`, `pom.xml`, `pyproject.toml`).
- A generated metadata file **must** record the exact API version (`info.version` from the source document), the source document's URL or path, the generator name and version, and the template version used.

Recording the generator and template version is what makes a regenerated client diff explainable: without it, a behavioural change in generated code cannot be attributed to either the API or the toolchain.

# Publishing

- An SDK **must** be published only from an OpenAPI document that has been released — never from a working copy.
- An SDK **must not** be hand-edited after generation. Anything that cannot be expressed in the OpenAPI document belongs in a thin, separately versioned wrapper package, not in the generated output.
