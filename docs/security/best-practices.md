# Security best practices

A consolidated checklist for hardening an AneePay integration. Page-level details
live elsewhere; this is the list to review before and after every release.

## Secrets and credentials

- [ ] `X-Account-Id` (account UUID) is stored server-side only — never in
      frontend code, URLs, or client-visible config. Browser exposure breaks
      `Origin` checks and lets anyone create payments as you.
- [ ] `webhook_secret` is stored in env / a secret manager — never committed,
      never logged, never sent to the client.
- [ ] Understand the rotation story: **there is no key-rotation endpoint**.
      Treat leaked credentials by creating a new account and migrating, and
      compartmentalize environments (separate accounts for staging/production).
      See [Security and privacy](../payments/security-and-privacy.md).

## Payment creation

- [ ] Create payments **from your backend only** —
      [Quickstart](../getting-started/quickstart.md).
- [ ] Validate `amount > 0`, `token ∈ {usdt, usdc, dai}`,
      `network ∈ {polygon, amoy}` before calling the API (the API validates too —
      422s are your bug).
- [ ] Handle `403 account_not_found` as "bad credentials", not as "account
      missing" — and never rely on 404/403 responses to probe which account ids
      exist (the API deliberately does not give you that oracle).
- [ ] Retry policy: unknown outcome → list payments first, then decide —
      each `POST /payments/` creates a new payment
      ([Idempotency and retries](../payments/idempotency-and-retries.md)).

## Customer data

- [ ] `description` is **public** (payment reads are public; ids are derivable
      on-chain): order number, short item name — no names, emails, phones,
      addresses, or credentials.
- [ ] Keep customer PII in your own systems, referenced by an opaque order id.
- [ ] Split `recipients` are public on-chain data — use public payout addresses.

## Webhooks

- [ ] Verify `X-AneePay-Signature` on **raw request bytes** with HMAC-SHA256 and
      a constant-time comparison, before parsing/trusting the body
      ([Payload and signature](../webhooks/payload-and-signature.md)).
- [ ] Return `2xx` within 10 seconds; process asynchronously afterwards.
- [ ] Make processing **idempotent by `event_id`** (DB UNIQUE, not read-then-write).
- [ ] Fulfill only after a verified webhook or a confirmed
      `GET /payments/{id}` — never on `success_url` (client-controlled).
- [ ] Gate real-world effects on `is_sandbox: false`
      ([Sandbox](../sandbox.md)).

## URLs and redirects

- [ ] `status_url` is public HTTPS in production; private and loopback targets
      are rejected.
- [ ] `success_url` / `fail_url` are fixed paths on your site; never reflect
      user input into them (open-redirect risk).
- [ ] The hosted checkout URL comes from the API response — do not construct it.

## Operations

- [ ] Log `request_id` from problem+json bodies; correlate with payment
      `operation_id` on your orders.
- [ ] Run periodic reconciliation ([Reconciliation](../payments/reconciliation.md))
      as a safety net behind webhooks; alert on gaps.
- [ ] Store amounts as decimals (never floats) — the API accepts and returns
      decimal strings.
- [ ] Handle edge `429` with backoff (rate limiting sits in front of the API).
- [ ] Keep sandbox traffic out of production fulfillment pipelines end-to-end,
      including exports and analytics.

## Review trigger

Re-run this checklist when you: add a new service that can call the API, change
webhook handling, change order-fulfillment logic, rotate infrastructure, or see
any unexplained payment-state discrepancy.

## Next

- [Testing your integration](../testing-your-integration.md) — run the drills.
- [Errors](../errors/index.md) — what every rejection looks like.
- [Troubleshooting](../troubleshooting.md) — when something is off.
