# Statuses and error codes

One place for every public status value and error code family. Trigger
conditions, payloads, and handling rules live in the linked pages — this page
is the index you scan first.

## Payment statuses

| Status | Meaning | First seen in |
| --- | --- | --- |
| `pending` | Payment created; waiting for on-chain confirmation | `POST /payments/` response, status polling |
| `success` | Settlement confirmed on-chain; final | Webhook, `GET /payments/{id}` |
| `failed` | Settlement did not complete; final | Webhook, `GET /payments/{id}` |

There is no customer cancellation and no refund: a pending payment moves to
`success` or `failed` — see
[Payment lifecycle](../getting-started/payment-lifecycle.md). Webhooks fire only
for `success`.

## API error codes

All API errors use RFC 7807 `application/problem+json` with a machine-readable
`code` and a `request_id`. Full semantics and client rules:
[Errors](../errors/index.md).

| HTTP status | Codes |
| --- | --- |
| 403 | `account_not_found`, `account_not_safe`, `domain_mismatch`, `account_error` |
| 404 | `payment_not_found` |
| 422 | `validation_error`, `split_owner_not_recipient`, `split_sandbox_unsupported` |
| 500 | `payment_creation_failed`, `split_payment_error`, `database_error`, `payment_error`, `domain_error`, `internal_error` |
| 503 | `split_payment_unavailable` |
| other | `http_error` (framework-level 404, 405, …) |

Validation failures add an `errors[]` array with `loc`, `msg`, and `type` per
field. A bare HTTP 400 never comes from the payment endpoints.

## x402 error codes

x402 responses travel on the wire as 402 offers or as problem+json bodies:

| HTTP status | Codes |
| --- | --- |
| 400 | `invalid_x402_version`, `invalid_payload` |
| 402 | `insufficient_funds`, `invalid_network`, `invalid_scheme`, `invalid_payment_requirements`, `invalid_transaction_state`, `settlement_pending`, `unexpected_verify_error`, `unexpected_settle_error`, and other verify/settle rejections |

The complete list with meanings lives in the
[Facilitator API](../x402/facilitator-api.md#protocol-error-codes); recovery
steps are in [x402 troubleshooting](../x402/troubleshooting.md).

## Partner statuses

| Surface | Values | Where |
| --- | --- | --- |
| Partner profile | `active` — accrual and withdrawals run; anything else does not accrue | [Partner overview](../partner/index.md) |
| Payout | `Pending`, `Processing`, `Paid`, `Failed` | [Commissions and payouts](../partner/commissions-and-payouts.md#payout-history) |
| Commission | Accrued (available + paid out), then marked paid with its payout | [Commissions and payouts](../partner/commissions-and-payouts.md) |

## Network availability

| Network | Chain ID | Role |
| --- | --- | --- |
| Polygon mainnet | 137 | Payment acceptance, x402 settlement, partner payouts |
| Amoy testnet | 80002 | Sandbox only (`?sandbox=yes`); no split payments, no x402 |

Full matrix with token addresses: the [Reference index](index.md) and
[Networks, tokens, and fees](../payments/networks-tokens-fees.md).

## Related sections

- [Errors](../errors/index.md) · [Troubleshooting](../troubleshooting.md)
- [Sandbox](../sandbox.md) · [API errors](../api/errors.md)
- [Status and polling](../payments/status-and-polling.md)
