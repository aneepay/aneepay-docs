# Security and privacy

AneePay's public-read design and server-to-server API create a few privacy
rules you must follow when integrating.

## `X-Account-Id` is a server-side secret

The account UUID **is your API key**. Never put it in browser code, mobile
apps, templates, or client-side requests — that would let anyone create
payments on your account. Create payments from your backend only.

Because there is no key-rotation endpoint, rotating the credential means
creating a new account and re-integrating: treat the UUID as long-lived and
protect it accordingly.

## `description` is public — no personal data

The payment `description` is:

- displayed to the customer on the hosted checkout page;
- returned by the **public** `GET /payments/{id}` (no authentication);
- stored in the payment record.

A payment's `id` is **not a secret**: it is derivable from the on-chain
`operation_id` (`uuid.UUID(int=operation_id)`), so anyone who watches the
chain for a payment can reconstruct the UUID and read the payment.

Therefore:

- **Do** put an order number, invoice ID, or short label.
- **Do not** put customer names, emails, phone numbers, addresses, or any
  other PII in `description`.

The API accepts up to 500 characters, but brevity is also privacy.

## `GET /payments/{id}` is public by design

This is intentional: requiring a key would give a false sense of secrecy, since
the payment UUID is already recoverable from the public chain. What it means in
practice:

- Anyone who learns a payment UUID can read that payment's status, amount,
  token, network, and `description` — another reason the `description` must
  stay free of PII.
- Payment `id`s are safe to show to the **owning** customer (e.g. on an order
  confirmation page) but should not be printed on public marketing materials.

Fields that do **not** appear in the public response: your `account_id`, your
wallet beyond what is needed to complete the payment, webhook secrets, and
recipient account balances.

## `X-Account-Id` only where merchant binding matters

The header (or the account UUID in the path, for account-scoped endpoints) is
required exactly where the server must know **which merchant** is acting:

- `POST /payments/`, `POST /payments/split/` — creating payments;
- `GET /accounts/{account_id}/payments` — reading an account's history.

It is **not** required on `GET /payments/{id}` — see above.

## Split recipients are public

For split payments, the recipient list and shares are stored in
`payment_details` and returned by the public status endpoint; the hosted dApp
also shows them to the customer. Treat the split structure as public: use
wallet addresses only, never labels containing personal information.

## Webhook secrets

Each account has a `webhook_secret`, shown **once** at creation. Use it only
to verify `X-AneePay-Signature` (HMAC-SHA256 of the raw body) on incoming
webhooks — never in any client-facing context. Details:
[Payload and signature](../webhooks/payload-and-signature.md).

## Origin check and `is_safe`

Two independent protections on payment creation:

- **`Origin` (optional):** if the browser-style `Origin` header is present it
  must match the account's registered `domain`, otherwise the request is
  rejected with 403. Server-to-server calls usually omit `Origin`, so this is
  a secondary check, not the primary one.
- **`is_safe` (enforced server-side):** accounts whose domain is flagged by
  Google Safe Browsing (or related feeds) get `is_safe: false`, and payments
  from them are rejected with 403 until the flag clears. Sandbox
  (`?sandbox=yes`) bypasses this check.

A nonexistent account is also reported as 403 (not 404), so the API does not
reveal whether an account UUID exists.

## Network surface

- The API is server-to-server, not a browser API; cross-origin browser requests
  are not supported.
- Rate limiting is applied before requests reach the API. If you exceed it you
  receive `429` — retry with backoff.

## Checklist

- [ ] `X-Account-Id` exists only in server-side configuration/secrets.
- [ ] `webhook_secret` is stored in a secrets manager, never in the repo.
- [ ] `description` contains an order reference — no PII.
- [ ] Payment UUIDs are only shown to the customer who owns the order.
- [ ] Webhook signature verification is enabled (reject on mismatch).
- [ ] `is_safe: false` responses are alerted on (domain reputation problem).

## Related

- [Create a payment](create-payment.md) — authentication headers.
- [Idempotency and retries](idempotency-and-retries.md).
