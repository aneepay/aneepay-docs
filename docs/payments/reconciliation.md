# Reconciliation

Two tools keep your order book in sync with the chain: the paginated JSON
list per account, and a CSV export from the dashboard.

Webhooks remain the primary channel; these tools fill gaps (missed deliveries,
audits, finance exports).

## List account payments

`GET /accounts/{account_id}/payments` returns payments for one account,
newest first.

!!! note "Account UUID is the scope"
    The account UUID in the path identifies whose payments you read. That
    UUID doubles as your API key (`X-Account-Id`) — treat the whole URL as
    server-side material and do not expose it to browsers or logs.

### Query parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `page` | integer | `1` | Page number. |
| `limit` | integer | `20` | Items per page. |
| `type` | string | — | `A` (Standard) or `B` (Splits). |
| `status` | string | — | `pending`, `success`, `failed`. |
| `created_from` | ISO-8601 | — | Creation time, from (naive timestamps are treated as UTC). |
| `created_to` | ISO-8601 | — | Creation time, to. |
| `amount_from` | decimal | — | Minimum amount (`> 0`). |
| `amount_to` | decimal | — | Maximum amount (`> 0`). |

Sorting is always **descending by `created_at`** (newest first).

### Example requests

```bash title="Terminal"
# First page
curl "https://api.aneepay.com/accounts/<account-id>/payments"

# Successful payments, 50 per page
curl "https://api.aneepay.com/accounts/<account-id>/payments?status=success&limit=50"

# Split payments since April 1
curl "https://api.aneepay.com/accounts/<account-id>/payments?type=B&created_from=2026-04-01T00:00:00"
```

### Response

```json title="response.json"
{
  "items": [
    {
      "id": "3f8a1c2e-9b4d-4e6f-8a1c-2e9b4d4e6f8a",
      "payment_type": "A",
      "payment_type_display": "Standard Payment",
      "status": "success",
      "status_display": "Success",
      "is_confirmed": true,
      "created_at": "2026-04-15T10:30:00Z",
      "confirmed_at": "2026-04-15T10:35:00Z",
      "amount": "100.50",
      "token": "usdt",
      "network": "polygon",
      "description": "Order #12345"
    }
  ],
  "total": 150,
  "page": 1,
  "limit": 20,
  "has_next": true
}
```

`total` is the full count under the current filters; iterate while
`has_next` is `true`.

The list is a summary projection: `amount`, `token`, `network`, and
`description` are top-level fields here, unlike the nested `payment_details`
object returned by [`GET /payments/{id}`](status-and-polling.md).

## CSV export (dashboard)

The merchant dashboard (passwordless login) offers **Export CSV** on the
payments list, applying the same filters you see on screen and scoped to your
account(s) only.

- Endpoint: `GET /dashboard/payments/export/` (session-authenticated).
- Streams the **entire filtered set** (no pagination) as UTF-8 CSV.
- **Rate limit:** 60 requests per minute per user → `429`.
- **Row limit:** more than **10 000** rows → `413 Too many payments to
  export; narrow the filters.` (no file is generated).
- Invalid filters → `400`.

## Reconciliation workflow

1. **Primary:** process every webhook idempotently by `event_id`
   ([delivery and retries](../webhooks/delivery-retries-idempotency.md)).
2. **Gap filling:** once a day (or after incidents), page through
   `GET /accounts/{account_id}/payments?status=success&created_from=…` and
   compare against orders you still have open.
3. **Match keys:** use `operation_id` to match webhook and on-chain data to
   your order; use `id` for AneePay-side references. Amounts come as strings —
   compare with decimal arithmetic, never floats
   ([amounts](amounts-rounding-and-limits.md)).
4. **Exports:** pull a CSV for accounting periods from the dashboard.

!!! warning "Sandbox payments"
    Webhooks for sandbox payments carry `is_sandbox: true` and `network:
    "amoy"`. Keep them out of production ledgers — see [Sandbox](../sandbox.md).

## Related

- [Status and polling](status-and-polling.md) — single-payment reads.
- [Webhooks](../webhooks/overview.md) — the primary status channel.
