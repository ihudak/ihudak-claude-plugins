# Conventions

**Sources:** [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.html), [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174.html), [RFC 6749 §3.3 — Access Token Scope](https://www.rfc-editor.org/rfc/rfc6749.html#section-3.3), [RFC 6749 §4.4 — Client Credentials Grant](https://www.rfc-editor.org/rfc/rfc6749.html#section-4.4), [NIST — Role Based Access Control](https://csrc.nist.gov/projects/role-based-access-control), [NIST SP 800-162 — Attribute Based Access Control](https://csrc.nist.gov/pubs/sp/800/162/upd2/final), [AWS IAM — Actions, resources, and condition keys](https://docs.aws.amazon.com/service-authorization/latest/reference/reference_policies_actions-resources-contextkeys.html), [Google Cloud IAM — Permissions reference](https://cloud.google.com/iam/docs/permissions-reference)

This document uses a set of key words to indicate requirement levels as defined in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.html) and clarified by [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174.html):

| Keywords                     | Definition                                                                                                            |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| MUST, SHALL, REQUIRED	       | The definition is a mandatory requirement, violation is considered a mistake                                          |
| MUST NOT, SHALL NOT	       | The definition is prohibited, violation is considered a mistake                                                       |
| SHOULD, RECOMMENDED	       | The definition is not mandatory but should be carefully understood and weighted before choosing a different approach  |
| SHOULD NOT, NOT RECOMMENDED  | The definition is not prohibited but should be carefully understood and weighted before choosing a different approach |
| MAY, OPTIONAL	               | The definition is truly optional                                                                                      |

These key words are written in **bold** font.

Names of parameters, fields, objects, etc. are written in `code` font.

# Important Advice

This guide builds on concepts described in the [REST API guidelines](../rest-api-guidelines/Introduction.md). Read the [general structure](../rest-api-guidelines/General%20Structure.md) first — the permission grammar below is derived from the URL structure defined there, and does not stand on its own.

# Motivation

Permissions control access to everything a platform exposes:

- Client access to stored data
- Client access to public APIs
- Operator access to internal and operational APIs

Permission names are customer-facing: a user assigning a policy reads them, and a client requesting an access token sends them. They **must** therefore be treated as part of the API surface, and **must** follow a naming schema that a human can map back to the service and API they control.

[RFC 6749, Section 3.3](https://www.rfc-editor.org/rfc/rfc6749.html#section-3.3) defines an OAuth 2.0 `scope` as a space-delimited list of case-sensitive strings whose values are **defined by the authorization server** — the OAuth specification deliberately does not prescribe a grammar. That is exactly why an organization must fix one for itself: without a grammar, every team invents its own, and the resulting scope list is unusable to the people who have to grant it.

# Goals

- Public API naming **should** consistently match permission naming
- Permission names **must** support a service exposing multiple different APIs
- Permission names **must** support multiple services contributing to one public service

# Permissions in a Nutshell

The general permission format is:
```
{service-name}:{resource}:{action}
```

The semantics: grant permission to execute `{action}` on `{resource}` located in the service named `{service-name}`.

Grammar rules — all of these are checkable against a spec:

- A permission **must** consist of exactly three segments separated by two colons (`:`).
- Every segment **must** be non-empty and **must** match `[a-z0-9]+(-[a-z0-9]+)*` — lowercase kebab-case — with the single exception that the `{resource}` segment **may** contain dots to qualify a nested resource (see [General Mapping](../permission-guidelines/General%20Mapping.md#qualifying-ambiguous-or-generic-resources)); each dot-separated part **must** itself match that pattern.
- `{service-name}` **must** be the public service name or the service namespace as it appears in the API URL (see [General Structure](../rest-api-guidelines/General%20Structure.md#public-apis)).
- `{resource}` **must** be a noun, matching the resource collection name in the URL.
- `{action}` **must** be a verb: one of the predefined actions `read`, `write`, `delete`, or the name of a [custom method](../rest-api-guidelines/Custom%20Methods.md).
- A permission **must not** contain uppercase characters, whitespace, or a wildcard character.
- A permission **must not** encode a version. Permissions outlive API versions; `document:documents:read` covers v1 and v2 of the document service alike.

Further properties of the model:

- There are no reserved names.
- There is no permission hierarchy — permissions do not nest the way REST resources do. A grant on `apps` does not imply a grant on `apps.metadata`.
- Wildcards are not supported. Where a broad grant is needed, define an explicit permission at a coarser level (see [Internal API Mapping](../permission-guidelines/Internal%20API%20Mapping.md)).
- Users see permissions and assign them to principals and groups through policies.
- Users cannot define their own permissions; the set is defined by the services.

#### Examples
```
app-engine:apps:install
storage:logs:read
document:documents:write
```

**Authentication is always principal-based.** For service-to-service communication with no end user involved, a _service principal_ representing the calling service is introduced and permissions are granted to it, exactly as they would be to a human user. This is the [client credentials grant](https://www.rfc-editor.org/rfc/rfc6749.html#section-4.4) — see [Authentication](../rest-api-guidelines/Authentication.md).

# Relationship to other permission models

The three-segment grammar above is one point in a well-populated design space. Two widely published models illustrate the same idea with different separators and segment counts, and are useful as sanity checks when a naming question comes up:

- **AWS IAM** names an action as `service:Action` (e.g. `s3:GetObject`) and carries the resource separately, in the policy's `Resource` element rather than in the action string. See the [AWS service authorization reference](https://docs.aws.amazon.com/service-authorization/latest/reference/reference_policies_actions-resources-contextkeys.html).
- **Google Cloud IAM** names a permission as `service.resource.verb` (e.g. `compute.instances.list`) — the same three parts as the grammar above, separated by dots instead of colons. See the [Google Cloud IAM permissions reference](https://cloud.google.com/iam/docs/permissions-reference).

These are cited as **examples of the pattern, not as the rule**. An organization adopting this guide picks one grammar and applies it everywhere; the concrete rules in this document assume the colon-separated three-segment form, and a reviewer checks against that form unless the organization has documented a different one.

Whether the permissions themselves are granted through roles ([RBAC](https://csrc.nist.gov/projects/role-based-access-control)) or evaluated against attributes ([ABAC](https://csrc.nist.gov/pubs/sp/800/162/upd2/final)) is a policy-engine concern and is out of scope here. The naming grammar is the same either way.
