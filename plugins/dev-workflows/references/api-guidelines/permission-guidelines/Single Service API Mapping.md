# Single Service API Mapping

**Sources:** [RFC 6749 §3.3 — Access Token Scope](https://www.rfc-editor.org/rfc/rfc6749.html#section-3.3), [Google Cloud IAM — Permissions reference](https://cloud.google.com/iam/docs/permissions-reference), [OpenAPI Specification 3.1 — Security Requirement Object](https://spec.openapis.org/oas/v3.1.0.html#security-requirement-object)

The simplest mapping scenario: one service exposing exactly one API. Such a service is exposed as a single public service on the API gateway. In this scenario the [general mapping](../permission-guidelines/General%20Mapping.md) rules apply with no exceptions or extensions — `{service-name}` is the service's own public name.

#### Examples

| API Endpoint                          | Permission                       |
| --------------------------------------- | -------------------------------- |
| GET /app-registry/v1/apps             | `app-registry:apps:read`         |
| POST /document-store/v1/documents     | `document-store:documents:write` |
| POST /automation/v2/workflows:execute | `automation:workflows:execute`   |
