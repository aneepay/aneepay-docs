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
| `account_not_found`| `X-Account-Id` missing or unknown. Deliberately **403, not 404** — a 404 would let attackers probe which account UUIDs exist. |
| `account_not_safe` | Account flagged `is_safe: false` (domain reputation review). Sandbox bypasses this check. |
| `domain_mismatch`  | `Origin` header host does not match the account's registered `domain` (secondary check). |
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
| `split_sandbox_unsupported`| Split payments are not available in sandbox for your account.            |

### 5xx — server side

| `code`                    | HTTP | When                                                        |
| ------------------------- | ---- | ----------------------------------------------------------- |
| `payment_creation_failed` | 500  | The payment could not be created.                           |
| `payment_error`           | 500  | Generic payment-domain failure.                             |
| `database_error`          | 500  | Temporary storage failure.                                  |
| `domain_error`            | 500  | Unclassified domain failure.                                |
| `internal_error`          | 500  | Internal server error — details never leave the server.     |
| `split_payment_unavailable` | 503 | Split payments are not available on this network.         |

### 405 and other framework-level errors

Unknown paths (`404`), wrong methods (`405`), and other framework-level errors use
`code: "http_error"` in the same problem+json envelope.

!!! note "No 400 or 429 from the public API"

    The public HTTP API does not currently emit 400 or 429 responses. Rate
    limiting may return a 429 before a request reaches the API — retry with
    backoff. The dashboard CSV export endpoint (session-authenticated, not the
    public API) returns `429`/`413`/`400` responses — see
    [Reconciliation](../payments/reconciliation.md).

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
