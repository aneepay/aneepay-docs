# Webhooks

Receiving event notifications.

## Setup

Configure webhook URLs in the dashboard under **Settings → Webhooks**.

## Verifying signatures

All webhooks are signed with the `X-Aneepay-Signature` header:

```python
import hmac
import hashlib

def verify_signature(payload: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(
        secret.encode(), payload, hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)
```

## Events

- `payment.succeeded`
- `payment.failed`
- `payment.refunded`
