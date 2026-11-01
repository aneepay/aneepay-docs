# Merchant

Accept crypto payments on your site: create payments through the API, send
customers to the hosted checkout, and receive signed webhooks when money
arrives. Funds go directly to your wallet — AneePay is strictly non-custodial.

## Start here

1. Understand the model: [Product overview](../getting-started/overview.md).
2. Accept a test payment: [Quickstart](../getting-started/quickstart.md).
3. Configure domain, wallet, callbacks, and webhook secret:
   [Account setup](../getting-started/account-setup.md).
4. Know the states your orders will see:
   [Payment lifecycle](../getting-started/payment-lifecycle.md).

## Payment acceptance

- [Create a payment](../payments/create-payment.md) — `POST /payments/`,
  request, response, errors.
- [Hosted checkout and dApp](../payments/checkout-and-dapp.md) — QR, wallet
  connection, network switching, redirects.
- [Status and polling](../payments/status-and-polling.md) — public
  `GET /payments/{id}`.
- [Split payments](../payments/split-payments.md) — one checkout, many
  recipients.
- [Reconciliation](../payments/reconciliation.md) — account payment list and
  CSV export.
- [Networks, tokens, and fees](../payments/networks-tokens-fees.md) — Polygon,
  USDT/USDC/DAI, 0.5%, gas.
- [Amounts, rounding, and limits](../payments/amounts-rounding-and-limits.md).
- [Refunds and non-features](../payments/refunds-cancellations-and-non-features.md) —
  what the product deliberately does not do.
- [Security and privacy](../payments/security-and-privacy.md) — public fields,
  API key handling.
- [Idempotency and retries](../payments/idempotency-and-retries.md).

## Webhooks

- [Webhooks overview](../webhooks/overview.md) — when events fire and what you
  must handle.
- [Payload and signature](../webhooks/payload-and-signature.md) — the v1
  contract and HMAC-SHA256 verification.
- [Delivery, retries, idempotency](../webhooks/delivery-retries-idempotency.md) —
  retries, backoff, at-least-once.
- [Testing webhooks](../webhooks/testing-and-replay.md) — public endpoint setup,
  sandbox drills, recovery.

## Also here

- [Sandbox](../sandbox.md) — test on the Amoy network without real funds.
- [Errors](../errors/index.md) — problem+json contract and error codes.
- [Troubleshooting](../troubleshooting.md) and [FAQ](../faq.md).

## Related sections

- [Getting started](../getting-started/overview.md) — the full onboarding path.
- [CMS](../cms/index.md) — plugins for WooCommerce, OpenCart, PrestaShop.
- [API](../api/index.md) — endpoint reference and authentication.
- [Partner program](../partner/index.md) — earn 10% of the platform fee.
- [Reference](../reference/index.md) — statuses, networks, and error codes.
