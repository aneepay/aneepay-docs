# Testing and replay

How to exercise the webhook pipeline safely: a local receiver, sandbox end-to-end
drills, failure injection, and how events are recovered when something went wrong.

## 1. Local receiver

In local development the SSRF guard is disabled (`DEBUG`), so `status_url` may point at
localhost:

```python
# local_receiver.py — run with: python local_receiver.py
import hashlib
import hmac
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

SECRET = "your-webhook-secret"  # account's webhook_secret

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        sig = self.headers.get("X-AneePay-Signature", "")
        expected = hmac.new(SECRET.encode(), body, hashlib.sha256).hexdigest()
        ok = hmac.compare_digest(expected, sig)
        print("signature OK" if ok else "SIGNATURE MISMATCH", body.decode())
        # ack quickly; real work happens asynchronously
        self.send_response(200 if ok else 401)
        self.end_headers()

HTTPServer(("127.0.0.1", 8765), Handler).serve_forever()
```

Set the account's `status_url` to `http://127.0.0.1:8765/webhook`, then create a
sandbox payment and watch the event arrive.

!!! note "Production-like local testing"

    Outside `DEBUG`, `localhost` and private addresses are rejected as webhook
    targets. To test the production code path from a laptop, expose the receiver
    through a public tunnel (ngrok, Cloudflare Tunnel) and use the tunnel URL as
    `status_url`.

## 2. End-to-end drill with sandbox

The fastest full-pipeline test (create → pay → confirm → webhook):

1. Create a payment with `?sandbox=yes` — the Amoy testnet, test USDC, no real funds
   (see [Sandbox](../sandbox.md)).
2. Complete the payment on the hosted checkout with MetaMask on Amoy.
3. After 12 Amoy confirmations the listener flips the payment to `success` and the
   outbox delivers a webhook with `network: "amoy"` and `is_sandbox: true`.
4. Assert in your handler: signature valid, `event_id` matches your order,
   `is_sandbox == true` → **do not** ship real goods.

Sandbox webhooks are indistinguishable from production ones except for those two
fields — treat them as production-shaped traffic for everything except fulfillment.

## 3. Failure-injection drills

| Drill                         | How to simulate                                | What you should observe                                    |
| ----------------------------- | ---------------------------------------------- | ---------------------------------------------------------- |
| Signature rejection           | Change one byte of the body / wrong secret     | Your endpoint returns 401; platform retries; event never applied |
| Endpoint down                 | Stop the receiver                               | Attempts 1–8 with exponential backoff (~4 min window)      |
| Slow handler                  | `sleep 11` before responding                   | Sender times out at 10 s, retries; your idempotency absorbs the duplicate |
| Flaky 5xx                     | Return 500 for the first N requests            | Retries continue; once you return 2xx the delivery stops   |
| Terminal failure recovery     | Keep failing through all 8 attempts            | Delivery status becomes `failed`; recover via operator replay or reconciliation |
| Lost 2xx                      | Process, then kill the connection before ACK   | Duplicate arrives later; dedupe by `event_id`              |

!!! warning "Duplicates are the normal case in drills"

    Every drill above intentionally produces at-least-once behavior. If any drill
    creates two orders or double-credits a balance, your handler is not idempotent —
    fix that before going live.

## 4. Replay

Replay is an **operator-side** action (there is no merchant API for it). Selecting a
delivery in the platform admin and running *Replay*:

- resets the delivery to `pending`, `attempts = 0`;
- keeps `event_id` and the **payload unchanged**;
- re-enqueues delivery immediately.

Because `event_id` and the body are identical to the original attempt, your receiver
must treat replay exactly like a retry: verify, dedupe by `event_id`, respond 2xx.
Replay after a fix (e.g., you had a signature bug) is therefore safe.

If you suspect missed events — for example your endpoint was down beyond the retry
window — do not wait for a replay: reconcile directly with
[the payments list](../payments/reconciliation.md) and backfill.

## 5. Common failures checklist

- [ ] Signature computed over **raw** bytes, not re-serialized JSON.
- [ ] Raw body captured before framework body-parsing middleware.
- [ ] Constant-time signature comparison.
- [ ] 2xx returned within 10 seconds, heavy work done after.
- [ ] Handler idempotent by `event_id` (UNIQUE constraint, not a read-then-write race).
- [ ] `is_sandbox` gates fulfillment — sandbox events never ship real goods.
- [ ] No reliance on `timestamp` for authorization (it is informational; the signature
      is the trust anchor).
- [ ] `status_url` is a public HTTPS URL in production.
- [ ] Fallback path exists: periodic reconciliation via `GET /accounts/{id}/payments`.

## 6. Contract validation

The payload is validated against the JSON Schema
`docs/schemas/webhook-v1.schema.json` in the platform repository. Schema violations
are a platform bug — report them; do not guess missing fields. `additionalProperties:
false` means today's field set is exhaustive for `version: 1`.

## Next

- [Payload and signature](payload-and-signature.md)
- [Delivery, retries, idempotency](delivery-retries-idempotency.md)
- [Reconciliation](../payments/reconciliation.md)
