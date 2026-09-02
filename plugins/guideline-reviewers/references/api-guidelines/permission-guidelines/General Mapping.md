# General Mapping Rules

**Sources:** [RFC 6749 §3.3 — Access Token Scope](https://www.rfc-editor.org/rfc/rfc6749.html#section-3.3), [RFC 9110 §9 — HTTP Methods](https://www.rfc-editor.org/rfc/rfc9110.html#section-9), [Google AIP-136 — Custom methods](https://google.aip.dev/136), [Google Cloud IAM — Permissions reference](https://cloud.google.com/iam/docs/permissions-reference), [AWS IAM — Actions, resources, and condition keys](https://docs.aws.amazon.com/service-authorization/latest/reference/reference_policies_actions-resources-contextkeys.html), [OpenAPI Specification 3.1 — Security Requirement Object](https://spec.openapis.org/oas/v3.1.0.html#security-requirement-object)

The standard mapping rules apply to [public APIs](../rest-api-guidelines/General%20Structure.md#public-apis) and [partner APIs](../rest-api-guidelines/General%20Structure.md#partner-apis). The fact that an API is unlisted (partner) has no impact on permission naming; in many cases a partner API reuses the same permissions as the public one.

The general rule is that the [REST](https://en.wikipedia.org/wiki/Representational_state_transfer) URL plus HTTP method **must** map onto the corresponding permission. Which resources get their own permission depends on the logic of the service that hosts them.

The following table describes the **required** mapping:

| REST URL                                                                  | Permission part               |
| ------------------------------------------------------------------------- | ----------------------------- |
| [Service name](../rest-api-guidelines/General%20Structure.md#public-apis)  | `{service-name}`              |
| API resource                                                              | `{resource}`                  |
| [API standard method](../rest-api-guidelines/Standard%20Methods.md)        | Predefined `{action}`         |
| [API custom method](../rest-api-guidelines/Custom%20Methods.md)	          | Custom `{action}`             |

## Standard Method Mapping

[API standard methods](../rest-api-guidelines/Standard%20Methods.md) **must** map onto the predefined actions:

| Standard Method                                                             | Action        |
| --------------------------------------------------------------------------- | ------------- |
| [List and Get](../rest-api-guidelines/Standard%20Methods.md#list) (GET, HEAD)| `read`        |
| [Create and Update](../rest-api-guidelines/Standard%20Methods.md#create) (POST, PUT, PATCH) | `write`       |
| [Delete](../rest-api-guidelines/Standard%20Methods.md#delete) (DELETE)       | `delete`      |

A `read` action **must not** be required for a write operation and vice versa: an operation's action is determined by its HTTP method, not by what the implementation happens to touch.

#### Examples
| API Endpoint                                                   | Permission                                       |
| --------------------------------------------------------------- | ------------------------------------------------ |
| DELETE /app-registry/v1/apps                                   | `app-registry:apps:delete`                       |
| GET /app-registry/v1/app-icons                                 | `app-registry:app-icons:read`                    |
| POST /document-store/v1/documents                              | `document-store:documents:write`                 |
| GET /partner/platform-management/v1/effective-permissions      | `platform-management:effective-permissions:read` |

## Custom Method Mapping

A [custom method](../rest-api-guidelines/Custom%20Methods.md) name is used directly as the action name. The custom method name and the action **must** be spelled identically, in kebab-case.

#### Examples
| API Endpoint                                        | Permission                       |
| ---------------------------------------------------- | -------------------------------- |
| POST /automation/v2/workflows:execute               | `automation:workflows:execute`   |
| POST /partner/token-service/v1/tokens:rotate        | `token-service:tokens:rotate`    |

## Mapping Nested Resources

APIs **may** expose nested resources with sub-resources. In some cases it **may** be necessary to define separate permissions for a parent resource and its sub-resources. A permission for a sub-resource **should** use the sub-resource name alone if that name is expressive enough without the parent. If the sub-resource name is generic or ambiguous, it **must** be [qualified](#qualifying-ambiguous-or-generic-resources) with the parent resource name.

#### Example

Consider a `problem-service` that manages problems and lets users comment on them:
```
GET  /problem-service/v1/problems                           - list all problems
GET  /problem-service/v1/problems/{problem-id}              - read one problem
PUT  /problem-service/v1/problems/{problem-id}              - update one problem
POST /problem-service/v1/problems/{problem-id}/comments     - add a comment to a problem
```

The team can define these permissions:
```
problem-service:problems:read                               - list or read
problem-service:problems:write                              - update problem or add comment
```

With this set, every action is authorized at the level of the parent resource `problems`. The service would have to check `problem-service:problems:write` to decide whether a user may write a comment. The problem with that: anyone who can comment can also edit the problem itself, which is probably not intended.

To separate commenting, a dedicated permission for the sub-resource is required:
```
problem-service:problems:read
problem-service:problems:write
problem-service:comments:write
```
Now commenting can be granted to users who may not update problems.

Note that the sub-resource `comments` is used without the parent resource `problems`: within the context of `problem-service`, "comment" is unambiguous and therefore needs no qualification.

## Qualifying Ambiguous or Generic Resources

Sometimes a sub-resource name is only meaningful in the context of its parent, or is outright ambiguous because the same name appears under a different parent in the same API. In these cases the sub-resource name **must** be qualified by prefixing the parent resource name, separated with a dot ("."). Dynamic path segments (ids and other path parameters) **must** be skipped.

#### Example (generic sub-resource)

| API Endpoint                                 | Permission                         |
| ---------------------------------------------- | ---------------------------------- |
| GET /app-registry/v1/apps                    | `app-registry:apps:read`           |
| GET /app-registry/v1/app-icons               | `app-registry:app-icons:read`      |
| PUT /app-registry/v1/apps/{app-id}/metadata  | `app-registry:apps.metadata:write` |

Technically `app-registry:metadata:write` would suffice, since the API contains only one `metadata` sub-resource. But such a permission is not self-explanatory and is hard to place without reading the documentation. Qualifying it with the parent `apps` makes the context obvious.

#### Example (ambiguous sub-resource)

| API Endpoint                                        | Permission                              |
| ----------------------------------------------------- | --------------------------------------- |
| GET /app-registry/v1/apps                           | `app-registry:apps:read`                |
| GET /app-registry/v1/app-icons                      | `app-registry:app-icons:read`           |
| PUT /app-registry/v1/apps/{app-id}/metadata         | `app-registry:apps.metadata:write`      |
| PUT /app-registry/v1/app-icons/{icon-id}/metadata   | `app-registry:app-icons.metadata:write` |

Here `metadata` appears under two different parents. It **must** be qualified so that the two permissions are distinct.

## Declaring permissions in the OpenAPI document

Every permission an API enforces **must** appear in the `scopes` map of the OAuth 2.0 security scheme, with a one-line human-readable description (see [OpenAPI — Authentication Context](../rest-api-guidelines/OpenAPI.md#authentication-context)). Every operation **must** reference at least one of those scopes in its `security` requirement.

A scope referenced by an operation but absent from the `scopes` map is a defect: the document is claiming a permission the authorization server has never been told about.
