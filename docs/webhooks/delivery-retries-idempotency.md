# Delivery, retries, idempotency

A delivery is created when the payment becomes `success` and is retried until your
endpoint acknowledges it. This section describes the exact delivery contract so you
can build a resilient receiver.

## Delivery contract

| Aspect         | Behavior                                                                     |
| -------------- | ---------------------------------------------------------------------------- |
| Protocol       | `POST`, `Content-Type: application/json`                                     |
| Timeout        | 10 seconds per attempt                                                       |
| Success        | Any **2xx** status (body ignored)                                            |
| Failure        | Non-2xx, timeout, DNS/connection error, or unsafe URL                        |
| Ordering       | One delivery per payment; retries of the same payment are strictly sequential |
| Concurrency    | One attempt in flight per delivery                                           |
| Payload        | **Frozen** when the delivery is created — identical bytes on every retry     |
| `event_id`     | Payment UUID; stable across retries                                          |

!!! warning "Respond fast, process later"

    The sender gives you 10 seconds and treats any 2xx as acceptance. Verify the
    signature, persist the event, return 2xx, then process asynchronously. If your
    handler is down for a while, AneePay keeps the event alive and retries it.

## Retry schedule

After a failed attempt AneePay schedules the next one with exponential backoff:

```
delay = min(2 s × 2^(attempts − 1), 300 s)
```

With the default policy (up to 8 attempts, base 2 s, cap 300 s) a persistently
failing endpoint sees:

| Attempt | Delay before it | Cumulative (approx.) |
| ------- | --------------- | -------------------- |
| 1       | immediately     | 0 s                  |
| 2       | 2 s             | 2 s                  |
| 3       | 4 s             | 6 s                  |
| 4       | 8 s             | 14 s                 |
| 5       | 16 s            | 30 s                 |
| 6       | 32 s            | 1 m 2 s              |
| 7       | 64 s            | 2 m 6 s              |
| 8       | 128 s           | 4 m 14 s             |

After the 8th failed attempt the delivery becomes terminally **failed** and will not
be retried automatically. There is no merchant API to request a redelivery — recover
missed events via [the payments list](../payments/reconciliation.md) and backfill
your orders.

!!! note

    The schedule above reflects the current defaults. Treat the exact timing as
    informational — design your receiver to tolerate gaps of minutes, not
    milliseconds.

## At-least-once semantics

The guarantee is **at-least-once**, not exactly-once. Duplicates can occur when:

- your endpoint processed the request but the 2xx response was lost (timeout — the
  sender saw a failure and retried);
- a delivery was retried after a false negative;
- your process crashed after HTTP 2xx was sent by a proxy but before your handler
  finished.

**Deduplicate by `event_id`.** The payload is byte-identical across all attempts, so
any stable key works (`event_id` is the natural one; `operation_id` is equivalent).

### Reference idempotent handler

```python
import hashlib
import hmac
import json

def handle_webhook(raw_body: bytes, signature: str, secret: str) -> None:
    expected = hmac.new(secret.encode(), raw_body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, signature):
        return  # 401

    event = json.loads(raw_body)
    event_id = event["event_id"]  # UUID string

    # atomic insert-or-get on a UNIQUE(event_id) column
    if not mark_event_processed(event_id):
        return  # duplicate — already handled, still 2xx

    # ... apply order state transition keyed by event_id ...
```

!!! danger "Never gate fulfillment on browser signals"

    Only a verified webhook (or a confirmed `GET /payments/{id}` read) may mark an
    order paid. The `success_url` redirect is client-controlled and forgeable.

## Unsafe / unreachable URLs

Before each attempt AneePay validates `status_url`:

- scheme must be `http` or `https`;
- host must be a **public** address — private, loopback, link-local and reserved
  ranges are rejected.

A rejected URL fails the attempt immediately (no HTTP request is made) and counts
toward the 8 attempts.

For production use a public HTTPS endpoint. To receive events on a laptop, run a
tunnel (ngrok, Cloudflare Tunnel, …) and configure its public URL as `status_url`.

## Missing or disabled `status_url`

Webhooks are emitted only for accounts with a configured `status_url`. If it is empty
at confirmation time, no delivery record is created — and none is created later when
you set the URL. Rely on
[polling / reconciliation](../payments/reconciliation.md) for those payments, or backfill
after configuring the URL by listing payments with `status=success`.

## Correlating without account id

The payload contains no account identifier (see
[Security and privacy](../payments/security-and-privacy.md)). This is deliberate: each
account has its own `webhook_secret`, so the verified signature already binds the event
to one account. Identify the payment by `event_id` (or `operation_id`).

## Split payments

Split payments (`POST /payments/split/`) emit **one** webhook per payment, exactly like
regular payments — the recipients are not notified. The account owner receives the net
amount split on-chain; the `net_amount` and `fee` fields describe the gateway fee taken
by the contract. For recipient breakdown, read
[Split payments](../payments/split-payments.md).

## Next

- [Testing webhooks](testing-and-replay.md) — sandbox drills and common failures.
- [Reconciliation](../payments/reconciliation.md) — the safety net behind webhooks.
