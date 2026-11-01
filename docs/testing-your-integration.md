# Testing your integration

A checklist-driven guide to verifying your AneePay integration before going live.
The fastest path is a full sandbox pass: create → checkout → pay → webhook →
reconcile.

## Prerequisites

- [x] Account created and [configured](getting-started/account-setup.md)
      (domain, wallet, `success_url`, `fail_url`, `status_url`, webhook secret).
- [x] `is_safe` is `true` — or test with `?sandbox=yes`, which bypasses the check.
- [x] You can create sandbox payments: `POST /payments/?sandbox=yes`.
- [x] A MetaMask wallet with test POL and test USDC on Amoy.

## 1. Payment creation

- [ ] `POST /payments/` from your **server** (never the browser).
- [ ] `X-Account-Id` header present; request succeeds with `checkout_url`.
- [ ] Validation behaves: bad token → `422 validation_error`; wrong account →
      `403 account_not_found` (see [Errors](errors/index.md)).
- [ ] `amount` is sent as a decimal string or number, `> 0`, rounded to 2 decimals.

## 2. Checkout and payment

- [ ] Customer lands on the hosted `checkout_url`.
- [ ] QR scans; MetaMask deeplink opens with pre-filled data.
- [ ] dApp switches the wallet to the right network (Amoy in sandbox).
- [ ] Approve (allowance) → `processPayment` → transaction confirms.
- [ ] Customer is redirected to `success_url` after a successful payment.

Failure drills:

- [ ] Reject the transaction in the wallet → customer sees a retry path,
      **not** a fake success.
- [ ] Wrong network manually forced → payment does not go through as success.

## 3. Status: polling

- [ ] Immediately after creation: `GET /payments/{id}` → `status: "pending"`.
- [ ] After confirmation (12 blocks): `status: "success"`,
      `is_confirmed: true`, `payment_details.fee` and `net_amount` populated.
- [ ] Unknown UUID → `404 payment_not_found` in problem+json.

## 4. Webhooks

- [ ] Your endpoint receives exactly one logical event per payment with
      `status: "success"` (duplicates possible — dedupe by `event_id`).
- [ ] Signature verifies against **raw** body bytes; tampering breaks it.
- [ ] Payload matches the v1 contract: `version`, `event_id`, `operation_id`,
      `tx_hash`, `chain_id`, `network`, `is_sandbox`, `fee`, `net_amount`.
- [ ] Sandbox payment → `is_sandbox: true` → your fulfillment stays disabled.
- [ ] Respond 2xx within 10 seconds; heavy work happens after the ACK.
- [ ] Failure drill: return `500` five times, then `200` — the event still
      arrives, and your handler processes it exactly once.

## 5. Reconciliation

- [ ] `GET /accounts/{account_id}/payments` lists the payment with the same
      `operation_id` you stored on the order.
- [ ] CSV export downloads with your filters applied.
- [ ] For a simulated missed webhook (stop your endpoint, exhaust retries):
      your reconciliation job finds the `success` payment and backfills the order.

## 6. Security pass

- [ ] `X-Account-Id` and `webhook_secret` live in env/secret storage — not in
      the repo, not in client-side code.
- [ ] `description` contains only public data (order number) — no PII
      ([details](payments/security-and-privacy.md)).
- [ ] Order fulfillment triggers only on verified webhook or confirmed API read,
      never on the browser redirect.
- [ ] Sandbox events (`is_sandbox: true`) never ship real goods.

## 7. Production pass

- [ ] Same checklist with production payments, tiny real amounts
      (e.g. 1 USDT on Polygon).
- [ ] `status_url` is a public HTTPS endpoint; private and loopback addresses
      are rejected.
- [ ] Customer pays gas in POL from their own wallet; funds arrive on your
      `wallet` with the 0.5% fee already deducted.
- [ ] Reconciliation job runs on a schedule and you have alerted on gaps.

## Sign-off checklist

```markdown
- [ ] Server-side payment creation with X-Account-Id
- [ ] Hosted checkout + wallet flow verified (sandbox)
- [ ] Polling returns pending → success with fee/net_amount
- [ ] Signed webhook verified, idempotent, gated on is_sandbox
- [ ] Reconciliation backfills missed events
- [ ] Secrets out of the repo; description free of PII
- [ ] Production smoke test with a real micro-payment
```

## Next

- [Sandbox](sandbox.md) — how the test environment works.
- [Troubleshooting](troubleshooting.md) — when a step fails.
- [Security best practices](security/best-practices.md) — hardening checklist.
