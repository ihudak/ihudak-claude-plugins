# Multi Service API Mapping

**Sources:** [RFC 6749 §3.3 — Access Token Scope](https://www.rfc-editor.org/rfc/rfc6749.html#section-3.3), [Google Cloud IAM — Permissions reference](https://cloud.google.com/iam/docs/permissions-reference), [AWS IAM — Actions, resources, and condition keys](https://docs.aws.amazon.com/service-authorization/latest/reference/reference_policies_actions-resources-contextkeys.html)

In some cases multiple deployed services **may** contribute to one logical public service. Such services **must** be grouped into a [service namespace](../rest-api-guidelines/General%20Structure.md#public-service-namespaces), and the namespace is used in the permission name instead of the individual public service name. A permission on a service namespace **must** apply to the resources in every service belonging to that namespace. The services can still be versioned individually and each declares the namespace in its API, which is what links it to the permission.

This yields the permission format:
```
<service namespace>:<resource>:<action>
```

#### Example

Consider a data storage system that ingests several types of data through an _ingest service_ and queries them through a separate _query service_.

Two deployed services, represented on the API gateway like this:

1. _ingest_
```
POST /storage/ingest/v1/logs
POST /storage/ingest/v1/metrics
POST /storage/ingest/v1/events
```
2. _query_
```
POST /storage/query/v1/queries:execute
```

The requirement is fine-grained control over who may ingest and who may query each type of data (_logs_, _metrics_, _events_).

The resulting permissions applied across the two services are:
```
storage:logs:read
storage:logs:write

storage:metrics:read
storage:metrics:write

storage:events:read
storage:events:write
```

The first segment is not either service's name (_ingest_ or _query_) but the service namespace (_storage_), which keeps the permission naming consistent across both. Note that `read` here maps to the query service and `write` to the ingest service: the action follows the HTTP method of the operation being authorized, not the identity of the service implementing it.
