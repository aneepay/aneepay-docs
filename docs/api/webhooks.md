# Webhooks and the API

Status changes are delivered **to you**, not polled: AneePay POSTs a JSON event
to the `status_url` registered on your account. Webhooks are the primary status
channel; the read endpoints exist for reconciliation and gap filling.

## Contract at a glance

| Property | Value |
| --- | --- |
| Direction | AneePay -> your `status_url` (HTTPS recommended; `http` is accepted) |
| Method / type | `POST`, `Content-Type: application/json` |
| Events | One event type: `status: "success"` when a payment is confirmed |
| Payload | Version `1`, fixed field set - see [Payload and signature](../webhooks/payload-and-signature.md) and the `webhook-v1` schema |
| Signature | `X-AneePay-Signature: <hex>` - HMAC-SHA256 of the **raw body** with your account's `webhook_secret` |
| Response handling | Any `2xx` counts as delivered; everything else is retried |
| Retries | Up to 8 attempts with exponential backoff (2 s -> 300 s) - see [Delivery and retries](../webhooks/delivery-retries-idempotency.md) |
| Idempotency | `event_id` is stable across retries and replays - deduplicate on it |

```text
POST /your/status/url HTTP/1.1
Content-Type: application/json
X-AneePay-Signature: 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08
```

## Verifying the signature

Compute the HMAC-SHA256 of the exact bytes you received with your
`webhook_secret` and compare in constant time. Reject the request on mismatch,
and respond `2xx` quickly - process it asynchronously, since delivery timeouts
count as failures.

Your `webhook_secret` is shown on the account card in the
[dashboard](../dashboard/accounts.md) and has no rotation control today.

## Relationship to the HTTP API

| You need | Use |
| --- | --- |
| Real-time status of each payment | Webhook to your `status_url` |
| Catch-up after downtime or a missed delivery | `GET /accounts/{account_id}/payments` ([Reconciliation](../payments/reconciliation.md)) |
| Single payment on demand | `GET /payments/{payment_id}` ([Status and polling](../payments/status-and-polling.md)) |

## Related sections

- [Webhooks overview](../webhooks/overview.md) - event flow.
- [Payload and signature](../webhooks/payload-and-signature.md) - field-by-field contract.
- [Delivery, retries, idempotency](../webhooks/delivery-retries-idempotency.md) - retry policy details.
- [Testing webhooks](../webhooks/testing-and-replay.md) - replay and local verification.
- [Endpoints](endpoints.md) - the read endpoints used alongside webhooks.
