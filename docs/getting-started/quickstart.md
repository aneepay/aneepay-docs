# Quickstart

Accept your first AneePay payment in about 10 minutes.

**What you get:** a customer pays in USDT on Polygon, the 0.5% fee is deducted
on-chain, and the net amount lands directly in your wallet.

## Prerequisites

- An EVM wallet address that will receive funds (e.g. `0x…` from MetaMask).
- Your site domain (used for the `Origin` check and domain safety verification).
- A backend you control — payment creation is **server-side only**.

## 1. Register and create an account

1. Open [aneepay.com](https://aneepay.com) and submit your email.
2. You receive a **magic login link** (valid for 10 minutes). Click it —
   no password is needed.
3. In the dashboard, create an account:
    - `domain` — your site domain (must be unique);
    - `wallet` — the EVM address that receives payments;
    - `success_url`, `fail_url` — pages on **your** site where the customer
      lands after the payment;
    - `status_url` — the server endpoint on **your** site that receives the
      success webhook.
4. Copy and store two values:
    - **Account ID** (UUID) — your API key, sent as the `X-Account-Id` header;
    - **Webhook secret** — used to verify `X-AneePay-Signature`; shown only once.

Full field reference and safety rules: [Account setup](account-setup.md).

!!! note "Domain safety (`is_safe`)"
    New accounts start with `is_safe: false`. AneePay periodically checks your
    domain against Google Safe Browsing and flips the flag to `true`. Until
    then, production payments are rejected with **403** — either wait for the
    check or develop against [Sandbox](#sandbox-testing-without-real-funds)
    (`?sandbox=yes` bypasses the check).

## 2. Create a payment (server-side)

Call the API from your backend. Never from the browser — that would expose
`X-Account-Id`.

```bash title="Terminal"
curl -X POST "https://api.aneepay.com/payments/" \
  -H "X-Account-Id: <your-account-uuid>" \
  -H "Content-Type: application/json" \
  -d '{"amount": "19.50", "token": "usdt", "network": "polygon", "description": "Order #12345"}'
```

Response:

```json title="response.json"
{
  "id": "3f8a1c2e-9b4d-4e6f-8a1c-2e9b4d4e6f8a",
  "operation_id": 83720934567890123456789012345678901234,
  "status": "pending",
  "checkout_url": "https://aneepay.com/payment/3f8a1c2e-9b4d-4e6f-8a1c-2e9b4d4e6f8a/"
}
```

- `amount` must be greater than zero; it is rounded to 2 decimal places.
- `token` ∈ `usdt`, `usdc`, `dai`; `network` ∈ `polygon`, `amoy`.
- `description` (max 500 chars) is **publicly readable** — put only an order
  number or short item name there, never personal data.

=== "Python"

    ```python title="create_payment.py" linenums="1"
    import requests
    from decimal import Decimal

    API_URL = "https://api.aneepay.com"
    ACCOUNT_ID = "<your-account-uuid>"

    def create_payment(amount: Decimal, description: str = "") -> dict:
        resp = requests.post(
            f"{API_URL}/payments/",
            headers={"X-Account-Id": ACCOUNT_ID},
            json={
                "amount": str(amount),
                "token": "usdt",
                "network": "polygon",
                "description": description,
            },
            timeout=15,
        )
        resp.raise_for_status()
        return resp.json()  # {id, operation_id, status, checkout_url}
    ```

=== "JavaScript"

    ```javascript title="create-payment.js" linenums="1"
    const ACCOUNT_ID = "<your-account-uuid>";
    const API_URL = "https://api.aneepay.com";

    async function createPayment({
      amount,
      token = "usdt",
      network = "polygon",
      description = "",
    }) {
      const res = await fetch(`${API_URL}/payments/`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Account-Id": ACCOUNT_ID,
        },
        body: JSON.stringify({ amount, token, network, description }),
      });
      if (!res.ok) throw new Error(`AneePay error ${res.status}`);
      return res.json(); // { id, operation_id, status, checkout_url }
    }
    ```

=== "PHP"

    ```php title="create_payment.php" linenums="1"
    <?php
    $accountId = '<your-account-uuid>';
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
    // header('Location: ' . $payment['checkout_url']);
    ```

## 3. Redirect the customer

Store `operation_id` on your order, then send the customer to `checkout_url`.
AneePay hosts the rest: QR code, MetaMask, network switch, contract call.
Afterwards the customer's browser returns to your `success_url` or `fail_url`.

## 4. Track the payment status

### Option A: Webhook (recommended)

Point `status_url` at an endpoint on your server. After on-chain confirmation
AneePay delivers:

```json title="webhook-payload.json"
{
  "version": 1,
  "event_id": "9c0f5e2a-1d3b-4c5e-9f8a-7b6c5d4e3f2a",
  "operation_id": 83720934567890123456789012345678901234,
  "status": "success",
  "timestamp": 1755262800.0,
  "tx_hash": "0xabc123...",
  "chain_id": 137,
  "network": "polygon",
  "is_sandbox": false,
  "fee": "0.097500",
  "net_amount": "19.402500"
}
```

Header `X-AneePay-Signature` is an HMAC-SHA256 hex digest of the **raw request
body** with your `webhook_secret`:

```python title="verify_webhook.py" linenums="1"
import hmac, hashlib

def verify_webhook(body: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)
```

Rules:

- Respond with `2xx`. Non-2xx responses are retried (up to 8 attempts with
  exponential backoff).
- Process **idempotently by `event_id`** — duplicate delivery is possible.
- Webhooks are sent only for `status: "success"`.

### Option B: Polling

```bash title="Terminal"
curl "https://api.aneepay.com/payments/<payment-id>"
```

`GET /payments/{id}` is public (no auth header). Check `status == "success"`
and the confirmation flag. Polling is a fallback — webhooks are the primary
channel.

## 5. Confirm the money arrived

Funds go straight to your `wallet`, minus the 0.5% fee — no AneePay balance
involved. `fee` and `net_amount` appear in the webhook and in
`GET /payments/{id}` after confirmation. For bulk checks use
`GET /accounts/{account_id}/payments` (requires `X-Account-Id`).

## Sandbox: testing without real funds

Append `?sandbox=yes` to the create call. The payment then runs on **Amoy**
(chain ID 80002) with test **USDC**, the `is_safe` check is bypassed, and the
webhook carries `is_sandbox: true` — do not ship real goods when you see it.

```bash title="Terminal"
curl -X POST "https://api.aneepay.com/payments/?sandbox=yes" \
  -H "X-Account-Id: <your-account-uuid>" \
  -H "Content-Type: application/json" \
  -d '{"amount": "5.00", "token": "usdt", "network": "amoy", "description": "Sandbox test"}'
```

In sandbox mode the API forces `network=amoy` and `token=usdc` regardless of
what you send. Public testnets can be slow — add retries to your dev workflow.

## Checklist

- [ ] Payment creation happens **on the server**, never in the browser.
- [ ] `X-Account-Id` header is present.
- [ ] `amount > 0`; `token ∈ {usdt, usdc, dai}`; `network ∈ {polygon, amoy}`.
- [ ] Customer is redirected to `checkout_url`.
- [ ] Status is tracked via signed webhook and/or polling.
- [ ] Webhook endpoint returns `2xx` and is idempotent by `event_id`.
- [ ] Signature verification uses the **raw body**, not a re-serialized object.
- [ ] Funds arrive in your `wallet` (0.5% already deducted).

## Next steps

- [Account setup](account-setup.md) — every account field in detail.
- [Payment lifecycle](payment-lifecycle.md) — statuses, confirmations, finality.
- [Webhooks](../webhooks/overview.md) — payload, signature, retries.
- [Testing your integration](../testing-your-integration.md) — full checklist.
