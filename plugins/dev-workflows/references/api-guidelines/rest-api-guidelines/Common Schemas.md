# Successful Response Format

**Sources:** [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html), [RFC 9110 — HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.html), [Google AIP-193 — Errors](https://google.aip.dev/193), [Zalando — JSON guidelines](https://opensource.zalando.com/restful-api-guidelines/#json-guidelines), [JSON:API](https://jsonapi.org/format/), [Microsoft REST API Guidelines — Errors](https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md), [IANA Media Types](https://www.iana.org/assignments/media-types/media-types.xhtml), [RFC 9562 — UUID](https://www.rfc-editor.org/rfc/rfc9562.html), [W3C Trace Context](https://www.w3.org/TR/trace-context/)

- The HTTP `Content-Type` **should** be `application/json` as registered at [IANA](https://www.iana.org/assignments/media-types/media-types.xhtml).
- Sometimes a different content type is genuinely necessary (e.g. blob storage or document APIs). In those cases a well-known IANA-registered type **must** be used; self-defined custom types **must not** be used.
- When the response body represents a collection of items it **should** be wrapped in a response envelope. This allows the response to be extended later without breaking the interface — most importantly, it allows pagination to be added to a collection that did not have it.
- Responses **must not** contain secrets directly. A reference to the secret in a secret-management system **must** be returned instead.

#### Example
```
{
   "items": [
     {
        "latestSchemaVersion": "1.4.2",
        "schemaId": "anomaly-detection.infrastructure",
        "displayName": "Anomaly Detection for Infrastructure"
     }
   ],
  "totalCount": 1
}
```

# Warnings in Responses

Sometimes a response **may** contain warning information although the request succeeded. This happens e.g. when data was missing from the request payload and was replaced with default values.

Warnings are optional, but if a response contains warnings they **must** be returned as the first field in the response body, named `warnings`. It **must** contain an array of warning objects. Each warning object **must** contain a string field named `message` holding the warning message.

#### Example
```
{
    "warnings": [
        {
            "message": "manifest version information is missing"
        },
        {
            "message": "application description is missing"
        }
    ],
    "items": [
        {
            "latestSchemaVersion": "1.4.2",
            "schemaId": "anomaly-detection.infrastructure",
            "displayName": "Anomaly Detection for Infrastructure"
        }
    ],
    "totalCount": 1
}
```
- Additional details about each warning **may** be added in a `details` field.
  - This section should convey additional information about the warning — e.g. which query parameter exactly violated a precondition.
  - `details` **may** contain any fields that further describe the warning.

## Common "details" fields

These are commonly used fields in the details object.

- `warningRef`, a UUID string ([RFC 9562](https://www.rfc-editor.org/rfc/rfc9562.html)) that references the warning in e.g. the service's log.
- `traceId`, a string containing a 32-character hex value, matching the trace-id of the [W3C Trace Context](https://www.w3.org/TR/trace-context/) `traceparent` header.
- `constraintViolations`, an array of `ConstraintViolation` objects.
- A `ConstraintViolation` object carries information about an input parameter (path, query or request body) that violated a validation rule of the service API and caused the warning.
  - `ConstraintViolation` **must** contain a field named `message` describing the warning.
  - `ConstraintViolation` **may** contain a field named `parameterLocation` describing the general location of the violating parameter (query parameter, request body, etc.).
  - `ConstraintViolation` **may** contain a field named `path` referring to the violating parameter within the `parameterLocation`.
  - `ConstraintViolation` **may** contain additional fields further describing the warning.

#### Example
```
{
    "warnings": [
        {
            "message": "version information missing",
            "details": {
                "warningRef": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
                "traceId": "99633483d17779d7c81141f50dbc2a49",
                "constraintViolations": [
                    {
                        "path": "manifest.version",
                        "message": "App version not defined in the manifest, using default of 1.0.0",
                        "parameterLocation": "PAYLOAD_BODY"
                    }
                ]
            }
        }
    ],
    "items": [
        {
            "latestSchemaVersion": "1.4.2",
            "schemaId": "anomaly-detection.infrastructure",
            "displayName": "Anomaly Detection for Infrastructure"
        }
    ],
    "totalCount": 1
}
```

# Error Response Format

An API **must** return errors in exactly one of the two shapes below, and **must** use the same shape for every error across the whole API. Mixing the two within one API is a defect: a client cannot write one error handler against two envelopes.

**Shape A (RECOMMENDED) — [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457.html) Problem Details.** Content type `application/problem+json`; members `type`, `title`, `status`, `detail`, `instance`, plus any extension members the API documents.

**Shape B — the `error` envelope** defined below. Content type `application/json`. An API that already publishes this envelope **should** keep it rather than break its clients to adopt Shape A.

Whichever shape is used:

- The HTTP `Content-Type` **must** be a registered JSON media type — `application/problem+json` for Shape A, `application/json` for Shape B.
- Error responses **must not** leak knowledge about the underlying system:
  - No stack traces
  - No class names
  - No internal product names, hostnames or version numbers
- The envelope **must** be declared in the OpenAPI document as a shared component and referenced from every error response.

## The `error` envelope (Shape B)

```
{
    "error": {
        "code": <error code>,
        "message": "error message"
    }
}
```
- `code` **should** be set to the HTTP status code by default.
  - `code` **may** be set to an API-specific error code, which **must** then be documented.
- The error `message` **should** be short and precise; it **should not** contain details.
- An additional `help` field **may** be added, which **must** be a URL pointing to further information on how to deal with the error.
- Additional details about the error **may** be added in a `details` field.
  - This section **should** convey additional information about the error — e.g. which query parameter exactly violated a precondition.
  - `details` **may** contain any fields that further describe the error.

## Common "details" fields

These are commonly used fields in the `details` object:

- `errorRef`, a UUID string ([RFC 9562](https://www.rfc-editor.org/rfc/rfc9562.html)) that references the error in e.g. the service's log.
- `traceId`, a string containing a 32-character hex value, matching the trace-id of the [W3C Trace Context](https://www.w3.org/TR/trace-context/) `traceparent` header.
- `errorCode`, a string carrying more detail than the HTTP status code alone.
  - The string **must** be a single word in _UpperCamelCase_, and all possible values **must** be documented.
- `constraintViolations`, an array of `ConstraintViolation` objects.
- A `ConstraintViolation` carries information about an input parameter (path, query or request body) that violated a validation rule of the service API (e.g. maximum string length, non-negative numbers).
  - `ConstraintViolation` **must** contain a field named `message` describing the error.
  - `ConstraintViolation` **may** contain a field named `parameterLocation` describing the general location of the violating parameter.
  - `ConstraintViolation` **may** contain a field named `path` referring to the violating parameter within the `parameterLocation`.
  - `ConstraintViolation` **may** contain additional fields further describing the error.
- `missingScopes`, which **should** be set when the API returns 403 - Forbidden because of missing OAuth scopes.
  - `missingScopes` **must** be an array of strings containing the complete list of scopes required to execute the request successfully.
- `missingPermissions`, which **should** be set when the API returns 403 - Forbidden because of missing user permissions.
  - `missingPermissions` **must** be an array of strings containing the complete list of permissions required to execute the request successfully.

#### Examples
```
{
    "error": {
        "code": 400,
        "message": "Constraints violated.",
        "details": {
           "errorRef": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
           "traceId": "99633483d17779d7c81141f50dbc2a49",
           "errorCode": "InvalidPaginationToken",
           "constraintViolations": [
              {
                  "path": "detectionRules[0].filterConfig.pattern",
                  "message": "may not be null",
                  "parameterLocation": "PAYLOAD_BODY"
              }
           ]
        }
    }
}

{
    "error": {
        "code": 403,
        "message": "missing OAuth scopes.",
        "details": {
            "missingScopes": [ "document:documents:read", "state:app-states:write" ]
        },
        "help": "https://docs.example.com/errors/missing-scopes"
    }
}
```

#### The same 403 as RFC 9457 Problem Details (Shape A)
```
HTTP/1.1 403 Forbidden
Content-Type: application/problem+json

{
    "type": "https://docs.example.com/errors/missing-scopes",
    "title": "Missing OAuth scopes",
    "status": 403,
    "detail": "The access token does not carry the scopes required for this operation.",
    "instance": "/document/v1/documents/6239bf48",
    "missingScopes": [ "document:documents:read", "state:app-states:write" ]
}
```

# Resource Modification Info

Many APIs allow resources to be created and modified. Such APIs **should** support a separate JSON object named `modificationInfo` carrying the most common information about creation and modification of the resource, similar to a file system. This object **should** include:

- Creation timestamp (UTC time as string)
- Creation user (user id)
- Last modification timestamp (UTC time as string)
- Last modifying user (user id)
- Reason for the last modification (string) — this field is optional

The object **must** use this naming schema:
```
"modificationInfo": {
   "createdBy": "123e4567-e89b-12d3-a456-426614174000",
   "createdTime": "2022-05-25T10:24:04.202Z",
   "lastModifiedBy": "123e4567-e89b-12d3-a456-426614174000",
   "lastModifiedTime": "2022-05-25T10:24:04.202Z",
   "lastModifiedReason": "migration to schema version 4"
}
```

- The object **must not** contain any other information. If a resource does not support modification, the `lastModified*` fields **may** be omitted.
- The object **must** carry the opaque user id. Human-readable names **must not** be used, for data-protection reasons.
- `modificationInfo` **may** be an optional field of the resource (e.g. available only via [field filtering](../rest-api-guidelines/Filtering%20And%20Sorting.md#field-filtering-and-partial-results)).

#### Example
```
{
   "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
   "descriptor": {
      "name": "my secret",
      "description": "some description"
   },
   "modificationInfo": {
      "createdBy": "123e4567-e89b-12d3-a456-426614174000",
      "createdTime": "2022-05-25T10:24:04.202Z",
      "lastModifiedBy": "123e4567-e89b-12d3-a456-426614174000",
      "lastModifiedTime": "2022-05-25T10:24:04.202Z",
      "lastModifiedReason": "migration to schema version 4"
   }
}
```

# Resource Context Info

When a resource is accessed via _List_ or _Get_, it is sometimes necessary to add meta information that is not part of the resource itself but retrieved from a different source. An example is the set of operations the caller is allowed to perform on the resource, which lets a UI show or hide controls. This kind of information is not a default part of the resource and **should** have to be requested explicitly through the [partial results](../rest-api-guidelines/Filtering%20And%20Sorting.md#field-filtering-and-partial-results) mechanism.

The optional field **must** be named `resourceContext` and **may** contain additional meta information about the requested resource.

#### Example
```
GET /registry/v1/apps?add-fields=resourceContext

{
  "apps": [
    {
      "manifest": {
        "id": "com.example.cluster",
        "name": "Cluster Wrapper App"
      },
      ...
      "resourceContext": {
        ...
      }
    },
    {
      "manifest": {
        "id": "com.example.intentsender",
        "name": "Intent Sender"
      },
      ...
      "resourceContext": {
        ...
      }
    }
  ]
}
```

## Allowed Operations on a Resource

The most common use of resource context information is to list the operations allowed on the returned resource, given the caller's permissions. Allowed operations **must** be represented as strings containing a single _lowercase_ verb, in the field `operations` inside `resourceContext`.

- The verb defining the operation **must** be consistent with the operation naming on the REST API level.
- The verb defining the operation **must** be consistent with the permission action assigned to the operation (see [General Mapping](../permission-guidelines/General%20Mapping.md)).
- Standard CRUD operations **should** use the standard action names unless a more expressive name is available:
  - "read"
  - "write"
  - "delete"
- If an operation represents an endpoint using a [custom method](../rest-api-guidelines/Custom%20Methods.md), it **should** use the same name as the method itself.
- Operation strings **must** be documented.

#### Example
```
GET /registry/v1/apps?add-fields=resourceContext

{
  "apps": [
    {
      "manifest": {
        "id": "com.example.cluster",
        "name": "Cluster Wrapper App"
      },
      ...
      "resourceContext": {
        "operations": [              -- caller holds full permissions on the app
           "install",
           "uninstall",
           "execute"
        ]
      }
    },
    {
      "manifest": {
        "id": "com.example.intentsender",
        "name": "Intent Sender"
      },
      ...
      "resourceContext": {
        "operations": [             -- caller can use the app but not affect its lifecycle
          "execute"
        ]
      }
    }
  ]
}
```

Side note: this approach is somewhat similar to [HATEOAS](https://en.wikipedia.org/wiki/HATEOAS) but is less restrictive and cheaper to implement on the service side.

# User Context

Some resources carry user-specific information that is not an intrinsic part of the resource but a convenience for human users. This is typically only consumed by a UI.

#### Examples

- A "last accessed" timestamp per user (allows sorting resources by last access when building menus)
- A list of pinned favorites per user (allows preferring certain resources in dropdowns)

Such information **must** be kept separate from the resource data in an optional field named `userContext`.

#### Example
```
GET /registry/v1/apps?add-fields=userContext

{
  "apps": [
    {
      "manifest": {
        "id": "com.example.cluster",
        "name": "Cluster Wrapper App"
      },
      ...
      "userContext": {
        "lastAccessedTime": "2022-05-25T10:24:04.202Z",
        "pinned": true
      }
    },
    {
      "manifest": {
        "id": "com.example.intentsender",
        "name": "Intent Sender"
      },
      ...
      "userContext": {
        "lastAccessedTime": "2022-05-25T10:24:04.202Z"
      }
    }
  ]
}
```
