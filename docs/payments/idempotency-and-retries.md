# Idempotency and retries

Payment systems fail in three places: requests that time out before you know
the outcome, on-chain transactions that can be re-sent, and webhooks that are
delivered more than once. This page tells you exactly what is and is not
idempotent on AneePay's side, and what to do in each case.

## Payment creation: no idempotency key

`POST /payments/` has **no idempotency-key mechanism**. Every successful call
creates a **new** payment with a new `id` and a new `operation_id`.

| Situation | What happens | What to do |
| --- | --- | --- |
| Request succeeded (200) | One payment exists. | Store `id` + `operation_id` on your order. |
| Request failed with 4xx/5xx after you received a response | No payment (500 means initialization failed). | Safe to retry. |
| **Timeout / connection error / unknown outcome** | The payment **may** have been created. | Do **not** blindly re-POST: you may create a duplicate pending payment. Resolve first (see below). |

Resolving an unknown outcome:

1. Query [`GET /accounts/{account_id}/payments`](reconciliation.md) filtered
   by `created_from` (and amount if distinctive) to check whether a payment
   for this order already exists.
2. If found: reuse its `id`/`operation_id`.
3. If not found: it is safe to create again.

Never auto-retry creation in a tight loop from a payment page; each blind
retry adds another payable invoice. Duplicates are harmless *only* if the
customer never pays them — but a customer can open two checkout URLs and pay
both, so treat duplicates as a bug in your integration.

## On-chain transactions

### Standard payments (`processPayment`)

- The **checkout dApp** guards against double payment: before enabling the
  Pay button it re-fetches the payment status, locks it if already `success`,
  and disables the button while a transaction is in flight.
- The Standard contract itself has **no on-chain replay guard**: a second
  `processPayment` with the same parameters would transfer funds a second
  time. This is a known, accepted trade-off (documented in the project's
  tech-debt ledger); compensations are the dApp guards above and a
  listener-side check that the event's recipient matches the account wallet
  before confirming.
- **If you build a custom client:** never re-send `processPayment` for a
  payment you already know is `success`, and never instruct a customer to
  "try the transaction again" without first checking status.

### Split payments (`processSplitPayment`)

The split contract **does** have a keyed replay guard
(`usedOperationKeys[keccak256(operationId, token, amount, recipientsHash)]`):
the same operation with the same parameters cannot be executed twice on-chain.

## Webhooks: at-least-once, make them idempotent on your side

- Deliveries are **at-least-once**: a durable outbox retries up to **8
  attempts** with exponential backoff (base 2 s, cap 300 s) until you return
  `2xx`.
- `event_id` and the payload are **stable across retries and manual replays**
  — the same event always carries the same `event_id`.
- Replays (including admin-initiated ones) can therefore deliver an event you
  have already processed.

Your endpoint must be idempotent by `event_id` (or by `operation_id`):

```python title="webhook_handler.py" linenums="1"
def handle_webhook(request, body: bytes, signature: str) -> None:
    if not verify_signature(body, signature, WEBHOOK_SECRET):
        raise Unauthorized()          # reject — do not process
    event = json.loads(body)
    if event["event_id"] in processed_event_ids:   # idempotent
        return
    mark_order_paid(event["operation_id"])         # safe to retry internally
    processed_event_ids.add(event["event_id"])
```

See [Delivery, retries, and idempotency](../webhooks/delivery-retries-idempotency.md)
for the full retry schedule and signature rules.

## Status polling: naturally idempotent

`GET /payments/{id}` is a read — poll as often as your policy needs (a few
seconds is enough on Polygon). Terminal statuses (`success`, `failed`) never
change; there is no reason to "confirm" a status more than once when
fulfilling an order.

## Retry cheat sheet

| Operation | Idempotent? | Safe to retry? |
| --- | --- | --- |
| `POST /payments/` | No — new payment each time | Only after a definitive error; **never** on timeout without checking first |
| `POST /payments/split/` | No — same as above | Same as above |
| `GET /payments/{id}` | Yes | Always |
| `GET /accounts/{id}/payments` | Yes | Always |
| CSV export (dashboard) | Yes | Yes, but rate-limited (60/min → 429) |
| Your webhook handler | Must be made idempotent by `event_id` | Re-delivery is expected |
| `processPayment` (on-chain) | **No** (Standard) / keyed guard (split) | Never re-send blindly |
| Webhook delivery (AneePay → you) | At-least-once | Handled for you (8 attempts) |

## Recommended order lifecycle

1. Create payment once; persist `id` + `operation_id` **before** redirecting.
2. Fulfill only from a verified webhook, or from a status poll showing
   `success` — never from the customer's browser redirect.
3. Process webhook events idempotently by `event_id`.
4. Use the list endpoint for daily gap reconciliation, not for real-time
   status.

## Related

- [Create a payment](create-payment.md) · [Status and polling](status-and-polling.md)
- [Split payments](split-payments.md) — keyed on-chain replay guard.
