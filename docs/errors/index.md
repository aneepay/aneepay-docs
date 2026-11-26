# Errors

All API errors follow **RFC 7807** with `Content-Type: application/problem+json`.
Every error response carries a machine-readable
`code` you can switch on, plus a `request_id` for support requests.

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

| Field       | Meaning                                                                     |
| ----------- | --------------------------------------------------------------------------- |
| `type`      | Always `about:blank` for now — no per-error catalog URLs.                   |
| `title`     | Short human-readable problem summary.                                       |
| `status`    | HTTP status, duplicated for convenience.                                    |
| `detail`    | Stable human-readable description.                                          |
| `instance`  | Request path that produced the error.                                       |
| `code`      | **Machine-readable code — branch on this, not on `detail`.**               |
| `request_id`| Correlation id for support; falls back to `-` if absent.                    |
| `errors[]`  | Present only on `validation_error`: per-field `loc` / `msg` / `type`.       |

!!! tip "Log `request_id`"

    When you contact support about a failed request, include `request_id` —
    it links the answer to the server-side logs.

## Status and code reference

### 403 — authentication / account policy

| `code`             | When                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------- |
| `account_not_found`| `X-Account-Id` is a valid UUID but no such account exists. Deliberately **403, not 404** — a 404 would let attackers probe which account UUIDs exist. A **missing or malformed** header is `422 validation_error` instead. |
| `account_not_safe` | Account flagged `is_safe: false` (domain reputation review). Sandbox bypasses this check. |
| `domain_mismatch`  | `Origin` header host does not match the account's registered `domain` (secondary check). |
| `account_id_mismatch` | `GET /accounts/{account_id}/payments` carried an `X-Account-Id` that differs from the `account_id` in the path. |
| `account_error`    | Fallback for other account-domain failures.                                          |

### 404 — not found

| `code`            | When                                     |
| ----------------- | ---------------------------------------- |
| `payment_not_found` | Payment UUID does not exist (public endpoint — see [Security](../payments/security-and-privacy.md)). |

### 422 — request validation

| `code`                     | When                                                                     |
| -------------------------- | ------------------------------------------------------------------------ |
| `validation_error`         | Body/query failed schema validation. `errors[]` lists `loc`/`msg`/`type` per field. |
| `split_owner_not_recipient`| Split: the account wallet is missing from `recipients`.                  |
| `split_sandbox_unsupported`| Sandbox split payments are not available on this deployment: the Amoy split contract is not configured. The public deployment supports them. |

### 413 — payload too large

| `code`                  | When                                                                 |
| ----------------------- | -------------------------------------------------------------------- |
| `payload_too_large`     | The request body exceeds 1 MiB. Enforced for **every** method, including `GET`, before routing — a large body on a read endpoint is rejected the same way. |

### 429 — rate limited

| `code`           | When                                                                       |
| ---------------- | -------------------------------------------------------------------------- |
| `rate_limited`   | The per-IP fixed-window limit for the endpoint was exceeded. The response carries a `Retry-After` header with the number of seconds to wait. |

| Endpoint | Limit |
| --- | --- |
| `GET /payments/{payment_id}` | 600 requests per minute per IP |
| `POST /x402/verify` | 120 requests per minute per IP |
| `GET /payments/{payment_id}/status/` (main site) | 120 requests per minute per IP |
| `GET /dashboard/payments/export/` (main site, session) | 60 requests per minute per IP |

Limits are counted in memory per application process. Retrying immediately does
not help — honour `Retry-After`, then back off. `POST /payments/`,
`POST /payments/split/`, `GET /accounts/{account_id}/payments`, and the whole
x402 settle path have no in-app per-minute limit.

### 503 — temporarily unavailable

| `code`           | When                                                                       |
| ---------------- | -------------------------------------------------------------------------- |
| `service_busy`   | Too many concurrent `POST /x402/verify` (20) or `POST /x402/settle` (5) requests are in flight. Returns `Retry-After: 1`; retry shortly. |
| `split_payment_unavailable` | Split payments are not configured on this deployment for that network. |

### 5xx — server side

| `code`                    | HTTP | When                                                        |
| ------------------------- | ---- | ----------------------------------------------------------- |
| `payment_creation_failed` | 500  | The payment could not be created.                           |
| `payment_error`           | 500  | Generic payment-domain failure.                             |
| `split_payment_error`     | 500  | Unclassified split-payment failure.                         |
| `database_error`          | 500  | Temporary storage failure.                                  |
| `domain_error`            | 500  | Unclassified domain failure.                                |
| `internal_error`          | 500  | Internal server error — details never leave the server.     |

### 405 and other framework-level errors

Unknown paths (`404`), wrong methods (`405`), and other framework-level errors use
`code: "http_error"` in the same problem+json envelope.

!!! note "Which statuses the application really emits"

    Payment and account endpoints do not emit `400` (body problems are `422`),
    but they do emit `413 payload_too_large` and `429 rate_limited` themselves —
    these are not reserved for an edge proxy. The x402 endpoints additionally
    return `400` for malformed wire payloads and `503 service_busy` when the
    verify/settle concurrency limit is hit. The dashboard CSV export endpoint
    (session-authenticated, not the public API) returns `429`/`413`/`400`
    responses — see [Reconciliation](../payments/reconciliation.md).

## Validation errors in detail

```json title="422 response"
{
  "type": "about:blank",
  "title": "Request Validation Failed",
  "status": 422,
  "detail": "Request validation failed",
  "instance": "/payments/",
  "code": "validation_error",
  "request_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "errors": [
    {
      "loc": ["body", "amount"],
      "msg": "Input should be greater than 0",
      "type": "greater_than"
    }
  ]
}
```

- `loc` starts with the request part (`body`, `query`) followed by the field path.
- `msg` is human-readable; `type` is the machine tag from the validator.
- `POST /payments/` rejects unknown fields — a typo like `"amt"` produces a
  422, not a silent default.

## Client error-handling rules

1. Branch on `code`, not on `detail` text.
2. Treat any 5xx and network errors as **retryable** (with backoff and
   [idempotency precautions](../payments/idempotency-and-retries.md)).
3. Treat 403/422 as **your bug** — fix the request, do not blind-retry.
4. On `payment_not_found` during reconciliation, verify the id came from
   `POST /payments/` or the payments list — never from user input.

## Next

- [Sandbox](../sandbox.md) — test without real funds.
- [Troubleshooting](../troubleshooting.md) — symptom → cause → fix.
