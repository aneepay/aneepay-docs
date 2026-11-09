# Testing webhooks

How to exercise the webhook pipeline safely: a public test endpoint, sandbox
end-to-end drills, failure injection, and how to recover when something went wrong.

## 1. Public test endpoint

AneePay delivers webhooks only to public URLs. To test from a laptop or a
private network, run your receiver locally and expose it through a public HTTPS
tunnel (ngrok, Cloudflare Tunnel, or similar), then use the tunnel URL as the
account's `status_url`.

```python
# receiver.py — run with: python receiver.py
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

HTTPServer(("0.0.0.0", 8765), Handler).serve_forever()
```

Expose port 8765 through the tunnel and copy the public HTTPS URL it prints
(for example `https://<tunnel-host>/webhook`) into the account's `status_url`.
Then create a sandbox payment and watch the event arrive.

!!! note "Keep the receiver reachable"

    A non-2xx response, a timeout, or a connection error counts as a failed
    attempt and is retried. Keep the receiver running for the whole drill.

## 2. End-to-end drill with sandbox

The fastest full-pipeline test (create → pay → confirm → webhook):

1. Create a payment with `?sandbox=yes` — the Amoy testnet, test USDC, no real funds
   (see [Sandbox](../sandbox.md)).
2. Complete the payment on the hosted checkout with MetaMask on Amoy.
3. After 12 Amoy confirmations AneePay marks the payment `success` and delivers a
   webhook with `network: "amoy"` and `is_sandbox: true`.
4. Assert in your handler: signature valid, `event_id` matches your order,
   `is_sandbox == true` → **do not** ship real goods.

Sandbox webhooks are indistinguishable from production ones except for those two
fields — treat them as production-shaped traffic for everything except fulfillment.

## 3. Failure-injection drills

| Drill                         | How to simulate                                | What you should observe                                    |
| ----------------------------- | ---------------------------------------------- | ---------------------------------------------------------- |
| Signature rejection           | Change one byte of the body / wrong secret     | Your endpoint returns 401; AneePay retries; event never applied |
| Endpoint down                 | Stop the receiver                               | Attempts 1–8 with exponential backoff (~4 min window)      |
| Slow handler                  | `sleep 11` before responding                   | Sender times out at 10 s, retries; your idempotency absorbs the duplicate |
| Flaky 5xx                     | Return 500 for the first N requests            | Retries continue; once you return 2xx the delivery stops   |
| Terminal failure              | Keep failing through all 8 attempts            | Delivery status becomes `failed`; recover by reconciliation |
| Lost 2xx                      | Process, then kill the connection before ACK   | Duplicate arrives later; dedupe by `event_id`              |

!!! warning "Duplicates are the normal case in drills"

    Every drill above intentionally produces at-least-once behavior. If any drill
    creates two orders or double-credits a balance, your handler is not idempotent —
    fix that before going live.

## 4. Recovery after terminal failure

After the final failed attempt the delivery is marked `failed` and is not retried
automatically. There is no merchant API to request a redelivery.

If you suspect missed events — for example your endpoint was down beyond the retry
window — reconcile directly: page through
[the payments list](../payments/reconciliation.md) with `status=success` and
backfill the orders you still have open.

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

The v1 payload is defined by the public JSON Schema at
<https://aneepay.com/schemas/webhook-v1.json>. Schema violations are a platform
bug — report them; do not guess missing fields. The schema forbids extra
properties, so the field set for `version: 1` is exhaustive.

## Next

- [Payload and signature](payload-and-signature.md)
- [Delivery, retries, idempotency](delivery-retries-idempotency.md)
- [Reconciliation](../payments/reconciliation.md)
