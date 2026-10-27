# API

The AneePay HTTP API for creating payments, retrieving statuses, reconciling transactions, and working with x402.

## Base URL

```text
https://api.aneepay.com
```

The API is not versioned in the URL: there is no `/v1` prefix.

## Authentication

- Creating a payment and listing account payments require the `X-Account-Id` header.
- `GET /payments/{payment_id}` is publicly accessible by payment ID.
- Requests with an `Origin` header undergo an additional security check.
- Calls must be made from a server, not from a browser.

## Error format

Errors use RFC 7807 `application/problem+json` and include `code` and `request_id`.

## Main endpoints

| Method | Path | Purpose |
|---|---|---|
| POST | `/payments/` | Create a payment |
| POST | `/payments/split/` | Create a split payment |
| GET | `/payments/{payment_id}` | Retrieve a payment |
| GET | `/accounts/{account_id}/payments` | List account payments |
| GET | `/x402/supported` | Supported x402 schemes |
| GET | `/x402/merchant` | Merchant x402 parameters |
| POST | `/x402/verify` | Verify a signed payment |
| POST | `/x402/settle` | Settle a payment |

## API documentation

- ReDoc: <https://api.aneepay.com/redoc>
- OpenAPI: <https://api.aneepay.com/openapi.json>

## Related sections

- [Merchant](../merchant/index.md) — payment acceptance scenarios.
- [x402](../x402/index.md) — payments for AI agents.
- [Reference](../reference/index.md) — statuses and error codes.
