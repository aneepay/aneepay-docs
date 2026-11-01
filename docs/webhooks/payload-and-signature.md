# Payload and signature

Every webhook is a `POST` with a JSON body conforming to contract **v1** and a
signature header you must verify before processing anything.

## Payload v1

The canonical contract is the public JSON Schema at
<https://aneepay.com/schemas/webhook-v1.json>. All fields are **required**; the
schema forbids extra properties (`additionalProperties: false`), so a field set
can only change via a new `version`.

```json
{
  "version": 1,
  "event_id": "3f8a9c1e-7b2d-4e6a-9f10-2c4d5e6f7a8b",
  "operation_id": 79228162514264337593543950336,
  "status": "success",
  "timestamp": 1762000000.512,
  "tx_hash": "0xabc123...",
  "chain_id": 137,
  "network": "polygon",
  "is_sandbox": false,
  "fee": "0.097500",
  "net_amount": "19.402500"
}
```

| Field          | Type            | Meaning                                                                 |
| -------------- | --------------- | ----------------------------------------------------------------------- |
| `version`      | `1`             | Contract version. Bump only in a new payload contract.                 |
| `event_id`     | string (UUID)   | Payment UUID. **Stable across retries** — your idempotency key.        |
| `operation_id` | integer         | On-chain operation id (`int(uuid)`), matches the one from `POST /payments/`. |
| `status`       | `"success"`     | Const in v1: webhooks are sent only for successful payments.           |
| `timestamp`    | number          | Unix seconds (float) when the payload was built.                        |
| `tx_hash`      | string \| null  | On-chain transaction hash.                                              |
| `chain_id`     | integer         | `137` (Polygon) or `80002` (Amoy).                                       |
| `network`      | `"polygon"` \| `"amoy"` | Network the payment settled on.                                |
| `is_sandbox`   | boolean         | `true` for test payments — **do not ship real goods**.                  |
| `fee`          | string \| null  | Fee in token units, decimal string (never a float).                     |
| `net_amount`   | string \| null  | Amount you received, decimal string (never a float).                    |

Notes:

- `fee` + `net_amount` = the payment `amount` (subject to on-chain rounding, see
  [Amounts and rounding](../payments/amounts-rounding-and-limits.md)).
- Decimal fields are **strings** on purpose: parse them with arbitrary-precision
  decimal types, not binary floats.
- The payload deliberately contains **no account id, no customer data, and no
  `description`** — the payment id is all you need to correlate
  (see [Security and privacy](../payments/security-and-privacy.md)).

## Signature

| Header             | Value                                                        |
| ------------------ | ------------------------------------------------------------ |
| `X-AneePay-Signature` | Lowercase hex HMAC-SHA256 of the **raw request body bytes**, keyed by your account's `webhook_secret` |

- Sign exactly the bytes you receive — do not re-serialize parsed JSON before hashing.
- Compare in constant time (`hmac.compare_digest` / `crypto.timingSafeEqual`).
- `webhook_secret` is generated per account and shown **once** at creation
  (see [Account setup](../getting-started/account-setup.md)).

### Verify — Python

```python
import hashlib
import hmac

def verify_webhook(raw_body: bytes, signature_header: str, secret: str) -> bool:
    expected = hmac.new(secret.encode("utf-8"), raw_body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature_header)
```

### Verify — Node.js

```javascript
const crypto = require("crypto");

function verifyWebhook(rawBody, signatureHeader, secret) {
  const expected = crypto
    .createHmac("sha256", secret)
    .update(rawBody) // Buffer of the raw body, not JSON.stringify(parsed)
    .digest("hex");
  const a = Buffer.from(expected, "hex");
  const b = Buffer.from(signatureHeader || "", "hex");
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}
```

!!! warning "Capture the raw body"

    Frameworks that parse JSON before your handler runs (Express body-parser,
    FastAPI `Depends`, …) destroy the byte-exact body. Configure a raw-body
    capture (Express `verify` option, `express.raw()`, FastAPI `Request.body()`)
    and verify against **that**.

### Verify — PHP

```php
function verifyWebhook(string $rawBody, string $signatureHeader, string $secret): bool
{
    $expected = hash_hmac('sha256', $rawBody, $secret);
    return hash_equals($expected, $signatureHeader);
}
```

## Minimal endpoint

```python
from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse

app = FastAPI()

@app.post("/webhooks/aneepay")
async def aneepay_webhook(request: Request):
    raw = await request.body()
    if not verify_webhook(raw, request.headers.get("x-aneepay-signature", ""), SECRET):
        return Response(status_code=401)
    payload = await request.json()
    # enqueue idempotent processing keyed by payload["event_id"]
    return JSONResponse({"ok": True})  # 2xx within 10s
```

## Common signature failures

| Symptom                          | Cause                                                        |
| -------------------------------- | ------------------------------------------------------------ |
| Signature mismatch on valid body | Hashing re-serialized JSON instead of raw bytes              |
| Signature mismatch always        | Wrong secret (rotated account vs old copy), or BOM/whitespace added by a proxy |
| Intermittent mismatch            | A middleware rewrites the body (gzip re-encode, pretty-print) |
| Works locally, fails in prod     | Framework switched to parsed-body mode only in production     |
| `401` on correct requests        | Header name case confusion — use case-insensitive lookup      |

On a mismatch: return **401** and do not process the payload. Retries will keep the
same body and signature, so a transient bug on your side does not corrupt anything —
fix the verifier and let the retries redeliver
(see [Testing webhooks](testing-and-replay.md)).

## Next

- [Delivery, retries, idempotency](delivery-retries-idempotency.md)
- [Testing webhooks](testing-and-replay.md)
