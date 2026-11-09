# Create a payment

`POST /payments/` creates a payment and returns a hosted `checkout_url`.
Calls are **server-to-server only** — the endpoint identifies you by the
`X-Account-Id` header, which must never reach the browser.

**Base URL:** `https://api.aneepay.com` (unversioned).

## Request

| Header | Required | Description |
| --- | --- | --- |
| `X-Account-Id` | **Yes** | Account UUID (merchant identity / API key). |
| `Content-Type` | **Yes** | `application/json`. |
| `Origin` | No | Secondary check: if present, must match the account's `domain`, otherwise **403**. |

| Query parameter | Type | Description |
| --- | --- | --- |
| `sandbox` | `string` | Pass `yes` to create a testnet payment (Amoy, test USDC, `is_safe` bypassed). See [Sandbox](../sandbox.md). |

### Body

| Field | Type | Required | Rules | Example |
| --- | --- | --- | --- | --- |
| `amount` | decimal | **Yes** | `> 0`; rounded to **2 decimal places** (`ROUND_HALF_UP`, e.g. `0.005` → `0.01`). | `19.50` |
| `token` | string | **Yes** | `usdt` \| `usdc` \| `dai` (case-insensitive). | `usdt` |
| `network` | string | **Yes** | `polygon` (mainnet) \| `amoy` (testnet); case-insensitive. | `polygon` |
| `description` | string | No | Max **500** characters. **Public** — shown to the customer and readable via the public status endpoint; use an order number, never personal data. | `Order #12345` |

Unknown fields return **422** — a typo such as `"amt"` is rejected, not silently
ignored.

## Response

```json title="response.json"
{
  "id": "3f8a1c2e-9b4d-4e6f-8a1c-2e9b4d4e6f8a",
  "operation_id": 84458472300955518321153401751165890442,
  "status": "pending",
  "checkout_url": "https://aneepay.com/payment/3f8a1c2e-9b4d-4e6f-8a1c-2e9b4d4e6f8a/"
}
```

| Field | Meaning |
| --- | --- |
| `id` | Payment UUID (your order reference on the AneePay side). |
| `operation_id` | The same payment encoded as `uint128` (`int(id)`), for the smart contract. Lossless and bijective: `uuid.UUID(int=operation_id)` restores `id`. This is what appears on-chain and in webhooks — store it on your order. |
| `status` | Always `pending` at creation. |
| `checkout_url` | Hosted checkout page — redirect the customer here. Format: `https://aneepay.com/payment/{uuid}/`. |

The response is JSON, not HTML: your backend receives it and redirects the
customer itself.

## Examples

=== "curl"

    ```bash title="Terminal"
    curl -X POST "https://api.aneepay.com/payments/" \
      -H "X-Account-Id: <your-account-uuid>" \
      -H "Content-Type: application/json" \
      -d '{"amount": "19.50", "token": "usdt", "network": "polygon", "description": "Order #12345"}'
    ```

=== "Python"

    ```python title="create_payment.py" linenums="1"
    import requests

    resp = requests.post(
        "https://api.aneepay.com/payments/",
        headers={"X-Account-Id": ACCOUNT_ID},
        json={
            "amount": "19.50",
            "token": "usdt",
            "network": "polygon",
            "description": "Order #12345",
        },
        timeout=15,
    )
    resp.raise_for_status()
    payment = resp.json()  # id, operation_id, status, checkout_url
    ```

=== "JavaScript"

    ```javascript title="create-payment.js" linenums="1"
    const res = await fetch("https://api.aneepay.com/payments/", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Account-Id": ACCOUNT_ID,
      },
      body: JSON.stringify({
        amount: "19.50",
        token: "usdt",
        network: "polygon",
        description: "Order #12345",
      }),
    });
    if (!res.ok) throw new Error(`AneePay error ${res.status}`);
    const payment = await res.json();
    ```

=== "PHP"

    ```php title="create_payment.php" linenums="1"
    <?php
    $resp = file_get_contents('https://api.aneepay.com/payments/', false, stream_context_create([
        'http' => [
            'method' => 'POST',
            'header' => "Content-Type: application/json\r\nX-Account-Id: $accountId\r\n",
            'content' => json_encode([
                'amount' => '19.50',
                'token' => 'usdt',
                'network' => 'polygon',
                'description' => 'Order #12345',
            ]),
        ],
    ]));
    $payment = json_decode($resp, true);
    ```

## Errors

Errors use RFC 7807 (`application/problem+json`) with a `code` field —
see [Errors](../errors/index.md).

| Status | `code` | When |
| --- | --- | --- |
| `403` | `account_not_found` | `X-Account-Id` is a valid UUID, but no such account exists. (A missing or malformed header is `422 validation_error` instead.) |
| `403` | `account_not_safe` | The account's domain is flagged `is_safe: false` (production). |
| `403` | `domain_mismatch` | The request carries an `Origin` header that does not match the account's domain. |
| `422` | `validation_error` | Body fails validation (bad `amount`/`token`/`network`, extra fields, `description` > 500) or the `X-Account-Id` header is invalid. |
| `500` | `internal_error` | Server-side failure during payment initialization. |

!!! note "403 instead of 404"
    A nonexistent account also returns **403**, not 404, so the status does not
    reveal whether an account UUID exists.

## After creation

1. Save `id` and `operation_id` on your order.
2. Redirect the customer to `checkout_url`
   ([hosted checkout](checkout-and-dapp.md)).
3. Track the outcome via [webhooks](../webhooks/overview.md) or
   [polling](status-and-polling.md).

Retries: there is **no idempotency key** — every call creates a new payment.
See [Idempotency and retries](idempotency-and-retries.md).

## Related

- [Split payment](split-payments.md) — `POST /payments/split/`.
- [Amounts, rounding, and limits](amounts-rounding-and-limits.md).
- [Networks, tokens, and fees](networks-tokens-fees.md).
