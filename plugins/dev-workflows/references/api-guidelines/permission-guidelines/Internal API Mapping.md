# Internal API Mapping

**Sources:** [RFC 6749 §3.3 — Access Token Scope](https://www.rfc-editor.org/rfc/rfc6749.html#section-3.3), [Google Cloud IAM — Permissions reference](https://cloud.google.com/iam/docs/permissions-reference), [NIST — Role Based Access Control](https://csrc.nist.gov/projects/role-based-access-control)

[Internal and operational APIs](../rest-api-guidelines/General%20Structure.md#internal-apis) are typically treated as resources in their own right. In most cases it is sufficient to grant a permission at the level of the whole API rather than per resource inside it. The typical use case is granting access to the entire _devops_ API to the members of the owning team.

Permission naming for internal and operational APIs:
```
<service name>:<audience-segment>.<api-identifier>.<api resources>:<action>
```

The dot-separated middle segment follows the same qualification rule as a [nested resource](../permission-guidelines/General%20Mapping.md#qualifying-ambiguous-or-generic-resources): each part is added only as far as the desired granularity requires, and dynamic path segments are skipped.

Wildcards are not supported, but multiple permission levels **may** be defined explicitly. It is usually enough to define permissions at a fairly coarse level rather than per resource — and a coarse permission that is actually reviewed is worth more than a fine-grained one nobody can enumerate.

#### Examples
```
app-registry:operations.devops.bundles:read        -- permission at resource-collection level
app-registry:operations.devops:read                -- permission at API level, the common case
app-registry:operations.ops:read                   -- permission at API level, the common case
app-registry:operations:read                       -- permission at audience-segment level
```

Because these permissions are granted to operators rather than to customers, they **must** still be declared in the API's OpenAPI document like any other scope (see [General Mapping](../permission-guidelines/General%20Mapping.md#declaring-permissions-in-the-openapi-document)). An operational endpoint with no `security` requirement is unauthenticated, which on an internal route is a defect, not a shortcut.
