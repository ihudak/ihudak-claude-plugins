# Authentication Method

**Sources:** [RFC 6749 — OAuth 2.0 Authorization Framework](https://www.rfc-editor.org/rfc/rfc6749.html), [RFC 6749 §4.4 — Client Credentials Grant](https://www.rfc-editor.org/rfc/rfc6749.html#section-4.4), [RFC 6750 — Bearer Token Usage](https://www.rfc-editor.org/rfc/rfc6750.html), [RFC 7519 — JSON Web Token](https://www.rfc-editor.org/rfc/rfc7519.html), [RFC 8725 — JWT Best Current Practices](https://www.rfc-editor.org/rfc/rfc8725.html), [OpenAPI Specification 3.1 — Security Scheme Object](https://spec.openapis.org/oas/v3.1.0.html#security-scheme-object), [Zalando — Security](https://opensource.zalando.com/restful-api-guidelines/#security)

Service APIs are not exposed to clients directly but through an API gateway. The gateway owns the public authentication method — the [OAuth 2.0 client credentials flow](https://www.rfc-editor.org/rfc/rfc6749.html#section-4.4) — and issues a JWT ([RFC 7519](https://www.rfc-editor.org/rfc/rfc7519.html)) that services use for authorization inside the system. The gateway also handles token refresh, token exchange and the mapping of browser session ids to internal tokens. Inside the system, the only accepted authentication is the bearer JWT ([RFC 6750](https://www.rfc-editor.org/rfc/rfc6750.html)) issued by the gateway.

This means that although a service technically consumes a JWT bearer token as its [authentication context](../rest-api-guidelines/API%20Context%20Information.md#authentication-context), it **must** declare the OAuth 2.0 client credentials flow as the public [security scheme](../rest-api-guidelines/OpenAPI.md#authentication-context) in its OpenAPI document. The client credentials flow is what an API client sees and uses; the bearer JWT is an internal mechanism that **must not** be exposed. Consequently the `Authorization` header **must not** be declared as a parameter in the OpenAPI document — it is implied by the security scheme.

Other authentication methods **must not** be used or declared in the OpenAPI document. In particular:

- `type: http, scheme: basic` **must not** be used.
- `type: apiKey` **must not** be used for externally reachable APIs.
- The `implicit` and `password` OAuth 2.0 grants **must not** be used; both are deprecated for new applications by the [OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics).
- A token **must not** be accepted in a query parameter or a cookie ([RFC 6750, Section 5.3](https://www.rfc-editor.org/rfc/rfc6750.html#section-5.3)).

# Permission Scopes

All API endpoints **must** be protected by at least one permission scope. In rare cases an endpoint **may** require more than one scope, but this is normally avoided because it is confusing for the client.

The security scheme defined in the [OpenAPI spec template](../template/openapi-template.yaml) is named `oauth2`. Using it on an endpoint looks like this:

```
/documents/{document-id}:
   get:
     operationId: getDocument
     ...
     security:
       - oauth2:
           - "document:documents:read"
```

An operation with an empty `security: []` array is unauthenticated. That **must** be used only where the endpoint is genuinely public (e.g. a health probe on an operational API), and the reason **must** be documented in the operation description.

Details on the scope naming grammar can be found in the [Permission Guidelines](../permission-guidelines/Introduction.md).
