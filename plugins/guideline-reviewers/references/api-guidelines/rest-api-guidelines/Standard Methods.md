# Standard Methods

**Sources:** [RFC 9110 §9 — HTTP Methods](https://www.rfc-editor.org/rfc/rfc9110.html#section-9), [Google AIP-131 — Get](https://google.aip.dev/131), [AIP-132 — List](https://google.aip.dev/132), [AIP-133 — Create](https://google.aip.dev/133), [AIP-134 — Update](https://google.aip.dev/134), [AIP-135 — Delete](https://google.aip.dev/135), [RFC 5789 — PATCH](https://www.rfc-editor.org/rfc/rfc5789.html), [RFC 7396 — JSON Merge Patch](https://www.rfc-editor.org/rfc/rfc7396.html), [RFC 6902 — JSON Patch](https://www.rfc-editor.org/rfc/rfc6902.html), [Zalando — HTTP requests](https://opensource.zalando.com/restful-api-guidelines/#http-requests)

Most REST APIs can be designed using only a small set of _standard methods_ on resources. These map naturally onto HTTP methods, which makes the API easy to understand. It is **recommended** to prefer standard methods over defining [custom methods](../rest-api-guidelines/Custom%20Methods.md).

In general: all standard methods may return [warnings](../rest-api-guidelines/Common%20Schemas.md#warnings-in-responses) or [errors](../rest-api-guidelines/Common%20Schemas.md#error-response-format) in addition to the specified response.

## Standard Method Mapping to HTTP Methods

| Standard Method	    | HTTP Method	                    | Request Body	  | Response Body                           |
| ------------------- | ------------------------------- | --------------- | --------------------------------------- |
| _List_	            | GET \<resource collection URL>  | \<empty>	      | List of resources                       |
| _Get_               | GET \<resource URL>             | \<empty>	      | Single resource                         |
| _Create_            | POST \<resource collection URL> | Single Resource |	Single Resource                         |
| _Update (Full)_     | PUT \<resource URL>             | Single Resource	| Single Resource, \<empty> or \<version> |
| _Update (Partial)_  | PATCH \<resource URL>           | Single Resource (partial)	| \<empty> or \<version>        |
| _Delete_            | DELETE \<resource URL>          | \<empty>        |	\<empty>                                |

GET and DELETE **must** be safe or idempotent as defined by [RFC 9110, Section 9.2](https://www.rfc-editor.org/rfc/rfc9110.html#section-9.2). PUT **must** be idempotent. POST is neither and **must not** be used where the semantics of the operation are idempotent.

## List

The _List_ method is the usual way to search a resource collection. It **may** take additional HTTP query parameters to refine the search (e.g. [filtering](../rest-api-guidelines/Filtering%20And%20Sorting.md#list-filtering) or [sorting](../rest-api-guidelines/Filtering%20And%20Sorting.md#sorting)).

- List **must** use the HTTP GET method.
- List **must not** use a request body.
- The response body **must** contain a (possibly empty) list of resources.
- An empty result **must** be HTTP 200 with an empty collection, never HTTP 404.

#### Examples
```
GET /app-registry/v1/apps
GET /app-registry/v1/app-icons
```

## Get

The _Get_ method accesses a single resource and returns its content in the response body. It **may** take additional HTTP query parameters to refine the access (e.g. [field filtering](../rest-api-guidelines/Filtering%20And%20Sorting.md#field-filtering-and-partial-results)).

- _Get_ **must** use the HTTP GET method.
- _Get_ **must not** use a request body.
- The response body **must** contain the resource content if successful.

#### Examples
```
GET /app-registry/v1/apps/{app-id}
GET /app-registry/v1/app-icons/{icon-id}
```

## Create

The _Create_ method creates a new resource within the specified resource collection. It **may** take additional HTTP query parameters to refine the creation.

- _Create_ **must** use the HTTP POST method.
- _Create_ **may** accept a resource id to assign to the created resource, allowing callers to select the id. If the resource id already exists, the method **must** fail.
- _Create_ **may** accept a request body with a selection of fields necessary to construct the resource. Optional fields may be supported and filled with documented defaults.
- On successful execution _Create_ **must** return HTTP 201 - Created.
- _Create_ **should** return the resource location in the [`Location`](https://www.rfc-editor.org/rfc/rfc9110.html#section-10.2.2) header as a URL that can be used directly with the _Get_ method. An API **may** choose not to return the resource id at all (e.g. if _Create_ is effectively a bulk ingest endpoint); this **must** be documented.
- The response body **should** contain the created resource. An API **may** choose not to return it (same ingest rationale); this **must** be documented.

#### Examples
```
POST /app-registry/v1/apps

HTTP/1.1 201 Created
Content-Type: application/json
Location: /app-registry/v1/apps/my-app-id
{
  "appId": "my-app-id",
  "version": "2.3.4",
  ...
}
```

## Update

The _Update_ method **must** support a full update and **may** additionally support partial updates using PATCH. _Update_ **may** take additional HTTP query parameters to refine the update; these **must** be documented.

### Full Update

- _Full Update_ **must** use the HTTP PUT method.
- _Full Update_ **may** allow the caller to provide a non-existing resource id in order to create a new resource.
- If _Full Update_ allows resource creation, the API **should** also provide a _Create_ method.
- The request body **must** contain all fields of the resource (exception: [read-only fields](../rest-api-guidelines/Design%20Patterns.md#handling-read-only-json-fields-in-resources)).
    - Fields missing from the request body are considered removed (this deletes the existing content of the missing field).
- On successful execution _Full Update_ **must** return HTTP 200 - OK if it updated a resource.
- On successful execution _Full Update_ **must** return HTTP 201 - Created if it created a resource.
- If _Full Update_ created a new resource, it **should** return the resource location in the [`Location`](https://www.rfc-editor.org/rfc/rfc9110.html#section-10.2.2) header as a URL usable directly with the _Get_ method.
- If _Full Update_ created a new resource, the response body **should** contain the created resource.
- If _Full Update_ updated a resource, the response body **must** be empty.
    - **Exception**: if the resource supports [optimistic locking](../rest-api-guidelines/Conflicts%20and%20Locking.md#optimistic-locking), the response body **must** contain only the new version in the field `version`.
    - **Exception**: if the resource supports [resource modification info](../rest-api-guidelines/Common%20Schemas.md#resource-modification-info), the response body **may** contain the updated `modificationInfo` field to reflect the change.

#### Example
```
PUT /document/v1/documents/{document-id}

HTTP/1.1 200 OK
Content-Type: application/json
{
  "version": "2.3.4"
}
```

## Partial Update

- _Partial Update_ **must** use the HTTP PATCH method ([RFC 5789](https://www.rfc-editor.org/rfc/rfc5789.html)).
- A _Partial Update_ request body **must** contain only the fields being updated, following JSON Merge Patch semantics ([RFC 7396](https://www.rfc-editor.org/rfc/rfc7396.html)).
    - Fields missing from the request body are not changed.
    - Fields are removed by explicitly setting them to `null` (except scalar values whose `null` is itself meaningful).
- _JSON Patch_ ([RFC 6902](https://www.rfc-editor.org/rfc/rfc6902.html)) **must not** be used: its operation array is a second, path-based mini-language that neither the OpenAPI schema nor the generated client can validate.
- _Partial Update_ **must not** be used to create a new resource.
- On successful execution _Partial Update_ **must** return HTTP 200 - OK.
- The response body **must** be empty.
    - **Exception**: if the resource supports [optimistic locking](../rest-api-guidelines/Conflicts%20and%20Locking.md#optimistic-locking), the response body **must** contain only the new version in the field `version`.

#### Example
```
PATCH /document/v1/documents/{document-id}

HTTP/1.1 200 OK
Content-Type: application/json
{
  "version": "2.3.4"
}
```

### How to implement partial update

Merge-patch semantics require the server to distinguish three states for every field: *absent*, *present and null*, and *present with a value*. Most object mappers collapse the first two — a deserialized object cannot tell a missing JSON field from one explicitly set to `null`, because both land as a null reference on the target type.

Two implementation strategies preserve the distinction:

1. **Parse the body as a JSON tree** before mapping it onto a typed object, and consult the tree for field presence. An absent field has no node; an explicit null has a null node. Where the request body is generated as a typed model, the generator **must** be configured to hand the PATCH body to the handler as a raw string or as a generic JSON tree, so that the tree is still available.
2. **Model each patchable field as an explicit optional wrapper** (`Optional<T>` / a nullable-plus-present pair / a tri-state union), so that "absent" and "null" are two distinct values of the field's own type.

Whichever strategy is used, it **must** be applied consistently to every PATCH endpoint of the API, and the API **must** document what `null` means for each field that accepts it.

**Caveat for strategy 1**: if the generator is configured to map a schema to a raw string, that mapping applies to *every* usage of that schema in the document. If the same schema is also used by a non-PATCH operation, a separate schema **must** be defined for the PATCH body.

## Delete

The _Delete_ method removes a single resource.

- _Delete_ **must** use the HTTP DELETE method.
- _Delete_ **must not** use a request body.
- On successful execution _Delete_ **must** return HTTP 204 - No Content with an empty response body, or HTTP 202 - Accepted where the deletion is a [long running operation](../rest-api-guidelines/Long%20Running%20Operations.md).
- Deleting a resource that does not exist **must** return HTTP 404 - Not Found, or HTTP 410 - Gone where the API distinguishes "never existed" from "existed and is gone".
- _Delete_ **must not** cascade silently. If deleting a resource also removes sub-resources, that **must** be documented, and the API **should** require an explicit `cascade=true` query parameter.
- Where the resource supports [optimistic locking](../rest-api-guidelines/Conflicts%20and%20Locking.md#optimistic-locking), _Delete_ **should** accept the version precondition in the same way the update methods do.

#### Example
```
DELETE /document/v1/documents/{document-id}

HTTP/1.1 204 No Content
```
