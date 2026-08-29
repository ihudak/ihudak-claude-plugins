# Multi API Service Mapping

**Sources:** [RFC 6749 §3.3 — Access Token Scope](https://www.rfc-editor.org/rfc/rfc6749.html#section-3.3), [Google Cloud IAM — Permissions reference](https://cloud.google.com/iam/docs/permissions-reference), [Google AIP-136 — Custom methods](https://google.aip.dev/136)

Sometimes one deployed service provides multiple APIs, distinguished internally by an [API identifier](../rest-api-guidelines/General%20Structure.md#services-and-apis). The API identifier is typically chosen to be the [public service name](../rest-api-guidelines/General%20Structure.md#public-apis) exposed on the API gateway. In this scenario the [general mapping](../permission-guidelines/General%20Mapping.md) rules apply with no exceptions or extensions. The only difference from [Single Service API Mapping](../permission-guidelines/Single%20Service%20API%20Mapping.md) is that the public service name mapped to `{service-name}` originates from an API identifier rather than from the deployed service's own name.

The deployed service's name **must not** appear in the permission. A consumer cannot see it, and it changes for reasons that have nothing to do with the API.

#### Examples

Service level (multiple APIs on one deployed service):
```
persistence.storage/public/query-api/v1/queries:execute
persistence.storage/public/query-api/v1/queries:validate
persistence.storage/public/entity-model-registry/v2/models
```

API gateway mapping and permissions:
```
POST /query-service/v1/queries:execute    --> 'query-service:queries:execute'
POST /query-service/v1/queries:validate   --> 'query-service:queries:validate'
PUT  /entity-model-registry/v2/models     --> 'entity-model-registry:models:write'
```
