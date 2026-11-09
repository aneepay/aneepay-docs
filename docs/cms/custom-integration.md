# Custom integration

This is the general recipe for accepting AneePay payments on a site **without** a
ready-made plugin: Shopware, Bitrix, Magento, Laravel, or a bespoke application.
It is the same flow the WooCommerce, OpenCart, and PrestaShop plugins implement —
you build only the store-specific glue.

## Prerequisites

1. Register and create an account in the AneePay dashboard.
2. Configure the account ([Account setup](../getting-started/account-setup.md)):
   - `wallet` — your EVM address (the contract sends the net amount there);
   - `domain` — your storefront domain (checked against the `Origin` header);
   - `status_url`, `success_url`, `fail_url` — endpoints/pages **on your site**
     (you will create them in steps 3–4);
   - `webhook_secret` — shown once; store it in your secret manager.
3. Make sure `is_safe` is `true`, or test with `?sandbox=yes`
   ([Sandbox](../sandbox.md)).

## 1. Create the payment on your server

Never call the API from the browser — it would expose `X-Account-Id` and break the
`Origin` check.

```bash title="POST /payments/"
curl -X POST "https://api.aneepay.com/payments/" \
  -H "X-Account-Id: <your-account-uuid>" \
  -H "Content-Type: application/json" \
  -d '{"amount": "19.50", "token": "usdt", "network": "polygon", "description": "Order #12345"}'
```

The response gives you everything you need:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "operation_id": 113059749145936325402354257176981405696,
  "status": "pending",
  "checkout_url": "https://aneepay.com/payment/550e8400-e29b-41d4-a716-446655440000/"
}
```

Store `id` (payment id) and `operation_id` on your order — they are the only
reliable link between your order and the payment. Full request/response contract:
[Create a payment](../payments/create-payment.md).

- Amounts are **decimal strings**; standard checkout rounds to 2 decimals.
- If your shop currency is not USD, convert **shop total → USD → token** first
  (live ECB rate + fallbacks) and round the token amount **up**, so you never
  undercharge. Plugins show the breakdown to the customer at checkout.
- Send `description: "Order #<number>"` — it makes webhook matching and support
  tickets much easier, and it is **public** data
  ([Security and privacy](../payments/security-and-privacy.md)).

## 2. Redirect the customer

Redirect the browser to the `checkout_url` you received. AneePay hosts the payment
screen (QR code, wallet deep link, network switching); your store is not involved
in the on-chain part.

When the operation finishes, the customer's browser is sent to your
`success_url` or `fail_url`. Treat both as **UX only** — the customer can close
the tab at any time (see step 4).

## 3. Implement `status_url` (the webhook)

This is what actually confirms the order.

1. Accept `POST` with a JSON body and the `X-AneePay-Signature` header.
2. Compute **HMAC-SHA256 of the raw request body bytes** with your
   `webhook_secret` and compare in constant time. Verify **before** parsing or
   trusting anything; answer `401` on mismatch.
3. Match the payload to your order by `event_id` / `operation_id` — never by
   amounts or descriptions.
4. Apply the fulfillment **idempotently**: retries can deliver the same event
   more than once (`event_id` is stable across retries).
5. Answer any **2xx within 10 seconds**; do heavy work asynchronously.

The payload contract, verification snippets (Python / Node / PHP), and a minimal
endpoint are in [Payload and signature](../webhooks/payload-and-signature.md);
delivery and retry rules are in [Delivery, retries, idempotency](../webhooks/delivery-retries-idempotency.md).

!!! warning "Webhooks are sent only for `success`"

    A payment that fails or is abandoned produces no webhook. Poll (step 5) or
    rely on the customer returning to `fail_url` to release reserved stock.

## 4. Provide the result pages

Your site must serve three resources, referenced by the account panel:

| Account field  | Your resource                                              |
| -------------- | ---------------------------------------------------------- |
| `status_url`   | Server endpoint from step 3 (webhook)                      |
| `success_url`  | Page: "Order paid" (and what happens next)                 |
| `fail_url`     | Page: "Payment incomplete" with a **retry** button         |

Never fulfill an order from the redirect alone —
see [Webhooks overview](../webhooks/overview.md).

## 5. Fallback: polling and reconciliation

- **Poll** `GET /payments/{id}` (public endpoint) while the order is `pending` —
  on the thank-you page or from a background job — and treat
  `status: "success"` as confirmation when the webhook is delayed.
  See [Status and polling](../payments/status-and-polling.md).
- **Reconcile** with `GET /accounts/{account_id}/payments` (filters, pagination,
  CSV export) to catch anything that slipped through:
  [Reconciliation](../payments/reconciliation.md).

## 6. Security checklist

- [ ] Payment creation happens only on your server.
- [ ] `X-Account-Id` and `webhook_secret` live in server-side configuration,
      never in source control or the frontend.
- [ ] Every webhook is signature-verified over the raw body before any state
      change.
- [ ] Orders are matched strictly by `operation_id` / `event_id`.
- [ ] Fulfillment is idempotent and gated on `is_sandbox` (never ship real goods
      on test payments).
- [ ] `description` contains no personal or sensitive data — it is public.
- [ ] Redirects are treated as UX, not as proof of payment.

Full checklist: [Security best practices](../security/best-practices.md).

## What this recipe does not cover

- **Refunds, cancellations, subscriptions** — not supported by the platform
  ([Non-features](../payments/refunds-cancellations-and-non-features.md)).
- **x402** (pay-per-request APIs for AI agents) — a separate protocol and
  integration, see [x402](../x402/index.md).
- **Ready-made plugins** — for WooCommerce, OpenCart, and PrestaShop use the
  [CMS integrations](index.md) instead of building this yourself.

## Next steps

- [Quickstart](../getting-started/quickstart.md) — first payment in 10 minutes.
- [API reference](../api/overview.md) — endpoint map and OpenAPI schema.
- [Testing your integration](../testing-your-integration.md) — end-to-end checklist.
