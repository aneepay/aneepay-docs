# Errors

Every error from the public API uses **RFC 7807** with
`Content-Type: application/problem+json`.

## Error format

```json title="403 response"
{
  "type": "about:blank",
  "title": "Account not found",
  "status": 403,
  "detail": "Account not found",
  "instance": "/payments/",
  "code": "account_not_found",
  "request_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479"
}
```

| Field | Meaning |
| --- | --- |
| `code` | Machine-readable code - **branch on this, not on `detail`**. |
| `request_id` | Correlation id for support; taken from your `X-Request-ID` header if you send one, otherwise generated. |
| `instance` | Request path that produced the error. |
| `type` | Always `about:blank` - there is no per-error URL catalog. |

On `422 validation_error` the envelope additionally carries `errors[]` with
`loc`, `msg`, and `type` per field - including fields that live in the header,
such as a missing `X-Account-Id`.

The complete field reference, examples, and the full code tables by status are
in the [Errors section](../errors/index.md) - one page, shared by the API, the
dashboard, and x402.

## Status codes at a glance

| Status | Codes |
| --- | --- |
| `400` | `invalid_x402_version`, `invalid_payload` - malformed x402 wire payloads (x402 endpoints only). |
| `403` | `account_not_found`, `account_not_safe`, `domain_mismatch`, `account_error` |
| `404` | `payment_not_found`, `http_error` (unknown path) |
| `422` | `validation_error`, `split_owner_not_recipient`, `split_sandbox_unsupported` |
| `500` | `payment_creation_failed`, `payment_error`, `split_payment_error`, `database_error`, `domain_error`, `internal_error` |
| `503` | `split_payment_unavailable` |

!!! note "No `400` from the payment endpoints"

    Payment and account endpoints never answer `400` (body/schema problems are
    `422`). The application itself does not return `429`; a `429` may be
    produced by the rate-limiting layer before the request reaches it. The x402
    endpoints do return `400` for malformed wire payloads.

## Client rules

1. Branch on `code`, not on `detail` text.
2. Treat `5xx` and network failures as retryable, with backoff and
   [idempotency precautions](../payments/idempotency-and-retries.md).
3. Treat `403`/`422` as non-retryable. Fix the request or the account
   configuration; `account_not_safe` requires domain remediation, not a code
   change.
4. Log `request_id` for every failed request; it is what support needs.

The rules, with a decision table, are spelled out in
[Errors](../errors/index.md#client-error-handling-rules).

## Related sections

- [Authentication](authentication.md) - what produces `403 account_not_found`.
- [Errors section](../errors/index.md) - full code reference.
- [Troubleshooting](../troubleshooting.md) - symptom -> cause -> fix.
- [x402 troubleshooting](../x402/troubleshooting.md) - x402-specific failures.
