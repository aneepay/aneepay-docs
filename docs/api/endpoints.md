# Endpoints

All paths below are relative to the base URL `https://api.aneepay.com`
([overview](overview.md)). Full request/response schemas live in
[ReDoc](openapi-and-redoc.md).

## Payment API

| Method | Path | `X-Account-Id` | Purpose | Details |
| --- | --- | --- | --- | --- |
| POST | `/payments/` | Yes | Create a payment, get a hosted `checkout_url` | [Create a payment](../payments/create-payment.md) |
| POST | `/payments/split/` | Yes | Create a split payment (1-100 recipients) | [Split payments](../payments/split-payments.md) |
| GET | `/payments/{payment_id}` | No | Read one payment by UUID | [Status and polling](../payments/status-and-polling.md) |
| GET | `/accounts/{account_id}/payments` | No | Paginated list of an account's payments with filters | [Reconciliation](../payments/reconciliation.md) |

Creation returns `200` with `{id, operation_id, status, checkout_url}`. Reads
are public by design: the UUID in the path is the capability
([Authentication](authentication.md)).

## x402 facilitator API

| Method | Path | `X-Account-Id` | Purpose | Details |
| --- | --- | --- | --- | --- |
| GET | `/x402/supported` | No | Supported schemes, networks, and signers | [Facilitator API](../x402/facilitator-api.md) |
| GET | `/x402/merchant` | Yes | Your `pay_to` clone address per network | [Facilitator API](../x402/facilitator-api.md) |
| POST | `/x402/verify` | No | Verify a signed payment authorization (x402 v2 section 7.1) | [Facilitator API](../x402/facilitator-api.md) |
| POST | `/x402/settle` | Yes | Settle an authorization (x402 v2 section 7.2) | [Facilitator API](../x402/facilitator-api.md) |

Protocol-level failures from `verify`/`settle` are `200` responses with
`isValid: false` or `success: false` and a spec-level error code - they are not
HTTP errors. Transport errors still use the shared problem+json envelope.

## Documentation endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/` | Redirects to `/redoc`. |
| GET | `/redoc` | Human-readable API documentation. |
| GET | `/openapi.json` | OpenAPI 3.1 document (machine-readable contract). |

## Related endpoints on the main site

These are served by the main `aneepay.com` application, not the API host, and
are documented in their own sections:

| Endpoint | Purpose |
| --- | --- |
| `GET /payments/{payment_id}/status/` | Small public status JSON for integrations; rate-limited to 120 requests per minute per IP. |
| `GET /accounts/{account_id}/metrics/` | Prometheus text metrics for one account - treat the URL as secret ([Metrics](../dashboard/metrics.md)). |
| `GET /dashboard/payments/export/` | CSV export from the dashboard ([Payments and export](../dashboard/payments-and-export.md)). |

## Related sections

- [Authentication](authentication.md) - which endpoints need `X-Account-Id`.
- [Errors](errors.md) - shared error contract for every endpoint.
- [OpenAPI and ReDoc](openapi-and-redoc.md) - schemas and client generation.
- [Webhooks](../webhooks/overview.md) - outbound status events.
