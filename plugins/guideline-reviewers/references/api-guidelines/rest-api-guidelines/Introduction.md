# Introduction

**Sources:** [Google API Improvement Proposals](https://google.aip.dev/), [Zalando RESTful API and Event Guidelines](https://opensource.zalando.com/restful-api-guidelines/), [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines/blob/vNext/azure/Guidelines.md), [RFC 9110 — HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.html), [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.html), [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174.html), [RFC 8259 — JSON](https://www.rfc-editor.org/rfc/rfc8259.html), [OpenAPI Specification 3.1](https://spec.openapis.org/oas/v3.1.0.html)

These are general design guidelines for **REST APIs**. They apply to every HTTP API a team publishes, whatever its audience — externally published, partner-facing, or consumed only by other services inside the same system. They do not apply to other API styles (gRPC, GraphQL, message-based interfaces), which have their own conventions.

The goal of these guidelines is to ensure that all APIs in a product are consistent, easy to understand, and follow a common understanding of [REST](https://en.wikipedia.org/wiki/Representational_state_transfer)ful HTTP APIs as defined in [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html).

The document starts with the most important rules and is expected to be extended and adapted over time.

Where a rule below names a placeholder — `api.example.com`, the `Example-` header prefix, the `example` service name — an adopting organization substitutes its own value once, consistently, across every API it publishes. The *shape* of the rule is what is normative; the placeholder is not.

# Conventions

This document uses a set of key words to indicate requirement levels as defined in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119.html) and clarified by [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174.html) (the key words carry their special meaning only when written in the uppercase form used here):

| Keywords                     | Definition                                                                                                            |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| MUST, SHALL, REQUIRED	       | The definition is a mandatory requirement, violation is considered a mistake                                          |
| MUST NOT, SHALL NOT	       | The definition is prohibited, violation is considered a mistake                                                       |
| SHOULD, RECOMMENDED	       | The definition is not mandatory but should be carefully understood and weighted before choosing a different approach  |
| SHOULD NOT, NOT RECOMMENDED  | The definition is not prohibited but should be carefully understood and weighted before choosing a different approach |
| MAY, OPTIONAL	               | The definition is truly optional                                                                                      |

These key words are written in **bold** font.

Names of parameters, fields, objects, etc. are written in `code` font.

# Setting The Stage

The guidelines assume a common deployment shape: a set of independently deployed services, each owning one or more APIs, reached from outside the system through an *API gateway* (or equivalent edge proxy) that handles routing, filtering and authentication. Nothing below depends on a particular runtime, container platform or service mesh — where the text says "gateway" it means whichever component owns the externally visible URL and the authentication handshake.

Two consequences of that shape run through the whole document:

- The URL a client sees is **not** necessarily the URL the service itself serves. The mapping between the two is declared in the OpenAPI document (see [OpenAPI](../rest-api-guidelines/OpenAPI.md)), never inferred.
- The service, not the gateway, is responsible for authorizing the request. A context header reaching the service states an *intent*, not a granted permission (see [API Context Information](../rest-api-guidelines/API%20Context%20Information.md)).

## Bulk Data and Query Interfaces

Not every dataset belongs behind a REST resource. Systems that hold large volumes of observational data (metrics, logs, traces, events) commonly expose them through a dedicated query interface or a bulk export rather than through per-record REST endpoints. Where such an interface exists, a REST API **should not** duplicate it with a resource-shaped equivalent — page-by-page retrieval of a high-cardinality dataset over REST is an anti-pattern that neither side can make performant.

## Resource-oriented Design

The general principle defines _resources_ that can be created and manipulated via _methods_. In the API resources are represented as _nouns_ and methods as _verbs_. Using the HTTP protocol, the resources map to the URL path and operations (called _methods_ in this guide) map to standard HTTP methods (POST, GET, PUT, PATCH, DELETE). See [Google AIP-121 — Resource-oriented design](https://google.aip.dev/121).

Most resources are organized in _resource collections_ (e.g., list of users).

The **recommended** protocol is HTTP/2 due to better performance and less network bandwidth usage.

The **recommended** content type of payloads is JSON ([RFC 8259](https://www.rfc-editor.org/rfc/rfc8259.html)), which is an industry standard on the internet. In certain high performance scenarios alternative encodings like _protobuf_ **may** be used.

The **required** encoding is UTF-8 ([RFC 8259, Section 8.1](https://www.rfc-editor.org/rfc/rfc8259.html#section-8.1)) unless it is technically necessary to support different encodings.
