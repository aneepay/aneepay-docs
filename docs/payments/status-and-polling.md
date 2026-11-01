# Payment status and polling

`GET /payments/{id}` returns the current state of one payment. It is
**public by design** — no `X-Account-Id` header — because a payment's `id`
is not a secret: it is bijectively derivable from the on-chain
`operation_id` (ADR 0009). Use it as a status source and as a fallback when
webhooks are unavailable.

## Request

```bash title="Terminal"
curl "https://api.aneepay.com/payments/<payment-id>"
```

No authentication headers. The path parameter is the payment UUID returned by
`POST /payments/`.

## Response

```json title="response.json"
{
  "id": "3f8a1c2e-9b4d-4e6f-8a1c-2e9b4d4e6f8a",
  "payment_type": "A",
  "payment_type_display": "Standard Payment",
  "status": "pending",
  "status_display": "Pending",
  "is_confirmed": false,
  "created_at": "2026-04-15T10:30:00Z",
  "confirmed_at": null,
  "payment_details": {
    "amount": "19.50",
    "token": "usdt",
    "network": "polygon",
    "description": "Order #12345"
  }
}
```

| Field | Description |
| --- | --- |
| `id` | Payment UUID. |
| `payment_type` | `A` (Standard), `B` (Splits), `C` (Confirmed). |
| `payment_type_display` | Human-readable label ("Standard Payment", "Splits Payment", "Confirmed Payment"). |
| `status` | `pending` \| `success` \| `failed`. (`cancelled` exists only as an internal admin status — never part of the public contract.) |
| `status_display` | Human-readable label. |
| `is_confirmed` | `true` once the payment is finalized on-chain. |
| `created_at` | ISO-8601 creation time (UTC). |
| `confirmed_at` | ISO-8601 confirmation time, or `null`. |
| `payment_details` | Provider metadata; **schema varies by `payment_type`**. Commonly: `amount`, `token`, `network`, `description`. After success it also carries `fee` and `net_amount`; split payments additionally carry `recipients`. |

## Success example

```json title="response.json"
{
  "id": "3f8a1c2e-9b4d-4e6f-8a1c-2e9b4d4e6f8a",
  "payment_type": "A",
  "payment_type_display": "Standard Payment",
  "status": "success",
  "status_display": "Success",
  "is_confirmed": true,
  "created_at": "2026-04-15T10:30:00Z",
  "confirmed_at": "2026-04-15T10:35:00Z",
  "payment_details": {
    "amount": "19.50",
    "token": "usdt",
    "network": "polygon",
    "description": "Order #12345",
    "fee": "0.097500",
    "net_amount": "19.402500"
  }
}
```

`fee` and `net_amount` appear only after on-chain confirmation — they are not
known at creation time (see [fees](networks-tokens-fees.md)).

## Polling

The webhook to `status_url` is the primary channel
([Webhooks](../webhooks/overview.md)); polling is the fallback:

```python title="poll_status.py" linenums="1"
import time
import requests

TERMINAL = {"success", "failed"}

def wait_for_payment(payment_id: str, timeout: float = 300.0, interval: float = 3.0) -> str:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        status = requests.get(
            f"https://api.aneepay.com/payments/{payment_id}", timeout=10
        ).json()["status"]
        if status in TERMINAL:
            return status
        time.sleep(interval)
    raise TimeoutError(f"Payment {payment_id} still not terminal")
```

Guidance:

- Poll until `status` is terminal (`success`/`failed`); `pending` can last for
  the [confirmation window](../getting-started/payment-lifecycle.md) (12 blocks
  by default) after the customer's transaction lands.
- A few seconds of interval is enough on Polygon; do not hammer the endpoint.
- **Never fulfill based on the customer's browser redirect** — fulfill on a
  verified webhook or this endpoint.

## Errors

| Status | `code` | When |
| --- | --- | --- |
| `404` | `payment_not_found` | Unknown payment UUID. |
| `422` | `validation_error` | Path parameter is not a valid UUID. |
| `500` | `internal_error` | Server-side error. |

## Sandbox

For sandbox payments (`?sandbox=yes`), `payment_details.network` is `amoy` and
the corresponding webhook carries `network: "amoy"` plus `is_sandbox: true`.
Do not fulfill real orders in that case — see [Sandbox](../sandbox.md).

## Related

- [Payment lifecycle](../getting-started/payment-lifecycle.md) — states and finality.
- [Reconciliation](reconciliation.md) — bulk listing per account.
- [Security and privacy](security-and-privacy.md) — why this endpoint is public.
