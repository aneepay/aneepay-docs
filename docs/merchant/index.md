# Merchant

The merchant section explains how to connect AneePay, accept the first payment, and set up reconciliation.

## Getting started

1. Create an account and verify your email.
2. Set your site domain and the EVM wallet that will receive funds.
3. Configure `success_url`, `fail_url`, `status_url`, and `webhook_secret`.
4. Create a payment with `POST /payments/` and redirect the customer to `checkout_url`.

## Topics

- Quickstart and account setup.
- Creating a payment and hosted checkout.
- Payment statuses and polling.
- Split payments with multiple recipients.
- Webhooks: payload, signature, retries, and idempotency.
- Payment reconciliation and CSV export.
- Sandbox on the Amoy network.
- FAQ and troubleshooting.
- Partner program.

## Related sections

- [API](../api/index.md) — endpoint reference and authentication.
- [CMS](../cms/index.md) — plugins for e-commerce platforms.
- [Reference](../reference/index.md) — statuses, networks, and error codes.
