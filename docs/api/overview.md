# API overview

The AneePay HTTP API for creating payments, reading statuses, reconciling
transactions, and running the x402 facilitator.

It is a JSON, server-to-server API: call it from your backend, never from a
browser.

## Base URL

```text
https://api.aneepay.com
```

The API is not versioned in the URL: there is no `/v1` prefix. The current
contract version is the `info.version` field of the
[OpenAPI document](openapi-and-redoc.md) (`1.0.0`). How changes are handled is
described in [Versioning and deprecation](versioning-and-deprecation.md).

## Content types

| Direction | Media type |
| --- | --- |
| Requests | `application/json` |
| Successful responses | `application/json` |
| Error responses | `application/problem+json` ([RFC 7807](errors.md)) |

Endpoints outside the JSON API use other types: the dashboard CSV export is
`text/csv; charset=utf-8`, and the per-account metrics endpoint is Prometheus
text format.

## Conventions

| Topic | Rule |
| --- | --- |
| Amounts | For payment creation, a JSON number **or** decimal string is accepted and rounded to 2 decimal places (half up). Responses return decimal strings with 2-6 decimals - compare with decimal arithmetic, never floats. x402 amounts use atomic units. |
| Tokens and networks | Input is case-insensitive (`usdt` / `usdc` / `dai`, `polygon` / `amoy`); responses use canonical lowercase. |
| Timestamps | ISO-8601 UTC. |
| Unknown request fields | Unknown **body** fields are rejected with `422 validation_error` - a typo like `"amt"` is an error, not a silent default. Unknown query parameters are ignored. |
| Unknown response fields | Possible at any time (new fields are additive) - ignore fields you do not know. |
| Pagination | `page` / `limit` query parameters; `limit` defaults to 20 and no maximum is enforced. Responses carry `items`, `total`, `page`, `limit`, `has_next`. |
| Error handling | Branch on the machine-readable `code`, never on `detail` text. |

## Access and limits

- Identity is the account UUID sent as the `X-Account-Id` header on the
  endpoints that require account identity: payment creation, split payments,
  x402 merchant lookup, and x402 settlement - see
  [Authentication](authentication.md).
- Calls are expected from a server: CORS is disabled by default, so browser
  JavaScript cannot read API responses from another origin.
- Rate limiting is applied before requests reach the API. Retry `429`
  responses with backoff. (Dashboard endpoints are session-authenticated and
  have their own limits - see
  [Payments and export](../dashboard/payments-and-export.md).)

## Documentation

- ReDoc: <https://api.aneepay.com/redoc>
- OpenAPI: <https://api.aneepay.com/openapi.json>

How to use these documents to generate a client is covered in
[OpenAPI and ReDoc](openapi-and-redoc.md).

## Related sections

- [Endpoints](endpoints.md) - the endpoint map.
- [Authentication](authentication.md) - `X-Account-Id`, `Origin`, `is_safe`.
- [Errors](errors.md) - error envelope and codes.
- [Merchant](../merchant/index.md) - payment acceptance scenarios.
- [x402](../x402/index.md) - payments for AI agents.
- [Reference](../reference/index.md) - statuses and error codes.
