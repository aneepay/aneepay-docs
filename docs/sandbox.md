# Sandbox

The sandbox runs the **full payment pipeline** against the Polygon **Amoy** testnet
with test USDC. No real funds, no real tokens — but real transactions, real
confirmations, and real signed webhooks. It is a working production-grade capability,
not a mock.

## Enabling sandbox

Append `?sandbox=yes` to the payment-creation request:

```bash title="Sandbox payment"
curl -X POST "https://api.aneepay.com/payments/?sandbox=yes" \
  -H "X-Account-Id: <your-account-uuid>" \
  -H "Content-Type: application/json" \
  -d '{"amount": "19.50", "token": "usdt", "network": "polygon", "description": "Order #12345"}'
```

The flag is **per-request**: enable it on the requests you want to test, omit it (or
pass any value other than `yes`) for production. Nothing in the dashboard toggles —
your integration decides per payment.

## What sandbox changes

When `sandbox=yes`:

| Aspect            | Sandbox behavior                                                                |
| ----------------- | ------------------------------------------------------------------------------- |
| Network           | Forced to **Amoy** (`chainId 80002`), regardless of the `network` field        |
| Token             | Forced to **USDC**, regardless of the `token` field                             |
| Token contract    | Test USDC `0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582`                          |
| Gateway contract  | Amoy gateway `0x8414b029Fe4E50aA93d4F4Cb2E31ADE676CA5502`                       |
| Split contract    | Amoy split gateway `0x102078BE0BB620eb3DdAa18B43fb048935e4eB13`                 |
| `is_safe` check   | **Bypassed** — sandbox payments work while an account is under review           |
| Payment record    | Stored with `is_sandbox: true`                                                  |
| Confirmation      | Real Amoy confirmations (12 blocks, same as production)                         |
| Webhooks          | Delivered, with `network: "amoy"` and `is_sandbox: true`                        |
| Redirects         | Normal flow to `success_url` / `fail_url`                                       |
| Gas               | Customer pays gas in **test POL** from an Amoy faucet                            |

Your request body may still say `"network": "polygon"` — the sandbox response reflects
the forced Amoy values. Pass `sandbox=yes` on **every** request of a sandbox order
flow; production requests must not carry it.

## Funding a test payment

1. Get test POL from any [Amoy faucet](https://docs.polygon.technology/tools/gas/matic-faucet).
2. Get test USDC — ask in [support](#support) for the current faucet source, or
   bridge via the Amoy tooling your team uses.
3. Complete the checkout as a customer would: MetaMask switched to **Amoy**,
   test USDC approved, transaction sent.

## Sandbox in the data

- `GET /payments/{id}` for a sandbox payment shows `payment_details.network: "amoy"`.
- Webhook v1 payload carries `network: "amoy"` and `is_sandbox: true`
  (see [Webhooks](webhooks/payload-and-signature.md)).

!!! danger "Never ship real goods on sandbox events"

    `is_sandbox: true` is the only reliable marker that a webhook (or a stored
    payment) refers to test traffic. Gate fulfillment, shipping, and balance
    credits on it — a sandbox payment looks and behaves exactly like production
    otherwise.

## Split payments in sandbox

Split payments work on Amoy with the sandbox split contract. If the sandbox split
contract is not available for your account, `POST /payments/split/?sandbox=yes`
returns `422` with `code: split_sandbox_unsupported` — contact support.

## When to use which environment

| Goal                                            | Environment              |
| ----------------------------------------------- | ------------------------ |
| End-to-end test with real chain + real webhooks | Sandbox (`?sandbox=yes`) |
| Everything else                                 | Production               |

There is intentionally **no mock mode**: if it works in the sandbox, the same code
path works in production.

## Support

Questions about sandbox funding or behavior: <https://t.me/aneepay>.
