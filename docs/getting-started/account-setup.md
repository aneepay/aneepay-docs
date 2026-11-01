# Account setup

An AneePay account is the unit of identity for the API: it owns a domain, a
receiving wallet, callback URLs, and a webhook secret. This page describes
every field and the rules around it.

## Logging in

The dashboard uses **passwordless login**:

1. Enter your email on [aneepay.com](https://aneepay.com).
2. You get a magic link by email, **valid for 10 minutes**.
3. Follow the link — you land in the dashboard with an active session
   (sessions last up to 2 weeks).

An expired or invalid link shows an error page — just request a new one.

## Account fields

| Field | Purpose |
| --- | --- |
| `id` | Account UUID — your API key, sent as `X-Account-Id`. |
| `domain` | Registered site domain; checked against the `Origin` header and against malicious-domain databases. Must be unique. |
| `wallet` | EVM address (42 chars, `0x…`) that receives the net payment amount. |
| `success_url` | Page on **your** site where the customer lands after a successful payment. |
| `fail_url` | Page on **your** site for failed payments, with a retry option. |
| `status_url` | Server endpoint on **your** site that receives the success webhook. |
| `webhook_secret` | Secret used to verify `X-AneePay-Signature`. Auto-generated, shown only once. |
| `is_safe` | Domain safety flag. Payments are rejected with **403** when `false`. |

!!! warning "`success_url`, `fail_url`, and `status_url` are your pages"
    These are ordinary resources on the **merchant's site**, not AneePay pages:

    - `success_url` / `fail_url` — storefront pages ("Order paid" /
      "Payment incomplete" with a retry button).
    - `status_url` — a server endpoint that verifies the signature and
      finalizes the order.

## Domain and `Origin` check

- `domain` is what the customer-facing site is registered as; it must be
  unique across the platform.
- If a request carries an `Origin` header, it must match the account's domain.
  A mismatch is rejected with **403**. Account resolution always starts from
  `X-Account-Id`; `Origin` is only a secondary check.

## Domain safety (`is_safe`)

`is_safe` indicates that the registered domain is not listed in known
malicious-domain databases (Google Safe Browsing and related feeds). The
backend rechecks domains periodically and updates the flag.

- Payments from accounts with `is_safe: false` are rejected with **403**.
- New accounts start as `is_safe: false` until the first check passes.
- Sandbox mode (`?sandbox=yes`) temporarily bypasses the check.

If you believe your domain was flagged by mistake, contact support.

## Webhook secret

- Generated automatically at account creation (random 32-character string).
- Shown **only once** — store it in your secret manager.
- Never log it, never put it in frontend code or public repositories.
- It signs every webhook: `X-AneePay-Signature` is an HMAC-SHA256 hex digest
  of the raw request body keyed with this secret.
  See [Payload and signature](../webhooks/payload-and-signature.md).

## Receiving wallet

- Any EVM address controlled by you (42 characters, checksum optional).
- This is where the contract sends the net amount after deducting the 0.5%
  fee — AneePay has no withdrawal step because funds never sit with us.
- For split payments the account wallet must also be present among the
  payment recipients.

## Key rotation

!!! warning "No key rotation endpoint"
    There is currently **no API to rotate `account_id`**. Creating a new
    account means a new integration on your side (new header value, new
    webhook secret, re-registered domain); the old account keeps its history.
    Treat the account UUID like any other API key: never expose it client-side.

    The blast radius of a leaked `account_id` is limited: the API has no
    mutation endpoints that move money, and `status_url`/`webhook_secret` can
    only be changed from the authenticated dashboard.

## Security checklist

- [ ] Payment creation calls come from your server only.
- [ ] `X-Account-Id` is stored in server-side configuration/secret storage.
- [ ] `webhook_secret` is stored securely and never logged.
- [ ] Every webhook is signature-verified before any order state changes.
- [ ] Orders are matched strictly by `operation_id`.
- [ ] `description` contains no personal or sensitive data (it is public).

## Next steps

- [Quickstart](quickstart.md) — create the first payment.
- [Account payments and export](../payments/reconciliation.md) — reconcile
  via `GET /accounts/{account_id}/payments`.
