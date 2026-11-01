# Troubleshooting

Symptom → cause → fix. If your problem is not listed, bring the `request_id` (API
errors) or the payment `operation_id` to [support](#support).

## Payment creation fails

| Symptom | Likely cause | Fix |
| ------- | ------------ | --- |
| `403 account_not_found` | Missing or wrong `X-Account-Id` | Send the account UUID on every `POST /payments/` ([Errors](errors/index.md)). Remember: it is deliberately 403, not 404. |
| `403 account_not_safe` | Account domain flagged `is_safe: false` | Complete the reputation review or test with `?sandbox=yes` (bypasses the check). |
| `403 domain_mismatch` | Browser `Origin` host ≠ account `domain` | Call from your server (no Origin) or fix the registered domain. |
| `422 validation_error` | Bad `amount`/`token`/`network`, `description` > 500 chars, or unknown field | Read `errors[]`; unknown fields such as `"amt"` are rejected. |
| `422 split_owner_not_recipient` | Account wallet missing from split `recipients` | Add the account wallet with a non-zero share. |
| `422 split_sandbox_unsupported` | Split payments are not available in sandbox for your account | Contact support. |
| `503 split_payment_unavailable` | Split payments are not available on this network | Use regular payments, or contact support. |
| `500 payment_creation_failed` / `internal_error` | Transient server issue | Retry with backoff; if persistent, contact support with `request_id`. |

## Checkout / customer side

| Symptom | Likely cause | Fix |
| ------- | ------------ | --- |
| Customer sees a generic error on `checkout_url` | Payment already resolved (double redirect) or unknown id | Redirect only to `checkout_url` returned by `POST /payments/`; do not construct it yourself. |
| QR does nothing | Poor screen/scan conditions | Use the **Pay with MetaMask** deeplink under the QR — same payload. |
| Transaction reverts in the wallet | Wrong network, insufficient token balance/allowance, zero amount, native POL instead of a token | dApp handles switching/approval automatically; manual payments must be on the right network with enough USDT/USDC/DAI + POL gas. |
| Customer sent a different amount | Amount is fixed at creation | Payment does not complete as expected; the on-chain transaction either reverts or does not match — customer retries with the exact amount. |
| Payment stuck in `pending` | Waiting for 12 confirmations; customer never actually sent the transaction; wrong network paid | Check the explorer via `payment_details.tx_hash` / `operation_id`; wait for confirmations; if the customer paid on the wrong chain, funds are not on Polygon — retry on the correct network. |
| Redirect to `success_url` did not happen | Customer closed the tab early | Do not rely on redirects for fulfillment — use webhooks/polling ([Status and polling](payments/status-and-polling.md)). |

## Webhooks

| Symptom | Likely cause | Fix |
| ------- | ------------ | ----- |
| No webhook at all | `status_url` empty on the account; payment not `success`; no `status_url` at confirmation time | Set `status_url`; confirm `GET /payments/{id}` shows `success`; payments confirmed before the URL was set are never delivered — reconcile via [the payments list](payments/reconciliation.md). |
| Webhook receiver returns `401` | Signature computed over re-serialized JSON, wrong secret, or body mutated by middleware | Verify HMAC-SHA256 over the **raw bytes** with constant-time compare ([Payload and signature](webhooks/payload-and-signature.md)). |
| Webhooks stop after ~4 minutes | Endpoint failing all 8 attempts (backoff window ≈ 4 min 14 s) | Fix the endpoint; missed events are recovered by reconciliation ([Delivery and retries](webhooks/delivery-retries-idempotency.md)). |
| Duplicate webhooks | At-least-once delivery by design | Dedupe by `event_id` (UNIQUE constraint), respond 2xx. |
| Webhook rejected before reaching you | `status_url` points to a private, loopback, or reserved address | Use a public HTTPS endpoint (tunnel for local testing). |
| Fulfillment triggered by sandbox payment | Missing `is_sandbox` gate | Block real-world actions when `is_sandbox: true` ([Sandbox](sandbox.md)). |

## Status and reconciliation

| Symptom | Likely cause | Fix |
| ------- | ------------ | ----- |
| `404 payment_not_found` on a payment you created | Typo'd id, or looking at another environment's payment | Compare with `POST /payments/` response / payments list; sandbox and production payments are separate records. |
| Payments list empty | Wrong `account_id` in the path, filters too narrow, naive datetime interpreted as UTC | Use your account UUID; widen `created_from`/`created_to`; remember naive datetimes are treated as UTC. |
| CSV export `429` | Rate limit 60 requests/min | Slow down; the limit is per-session dashboard export. |
| CSV export `413` | More than 10 000 rows in one export | Narrow the date range. |
| `GET /payments/{id}` returns 403 | It should not — this endpoint is public | You are probably calling an account-scoped route; check the path. |

## Account and security

| Symptom | Likely cause | Fix |
| ------- | ------------ | ----- |
| Account marked "unsafe" | Domain reputation review (`is_safe: false`) | Wait for review or contact support; use `?sandbox=yes` meanwhile. |
| Lost `webhook_secret` | Shown only once at creation | There is no rotation endpoint: create a new account and migrate — or ask support ([Account setup](getting-started/account-setup.md)). |
| Cannot log in | Magic link expired (10 min) | Request a new link; check spam. |
| 429 from the edge | Rate limiting before the API | Retry with exponential backoff; reduce request rate. |

## Support

<https://t.me/aneepay>

Include when possible:

- `request_id` from the problem+json body (or the exact HTTP status + `code`);
- payment `operation_id` / `event_id`;
- timestamps with timezone, and environment (production vs `?sandbox=yes`).
