# Authentication

AneePay has no users, sessions, or API keys of its own: your **account UUID**
is the credential. It is printed on the account card in the
[dashboard](../dashboard/accounts.md) and is the value of the `X-Account-Id`
header.

!!! warning "Server-side only"

    `X-Account-Id` is an API key. Never send it from a browser, embed it in a
    page, or put it in a mobile app - anything client-side leaks it. All
    authenticated calls must be proxied through your server.

## Which endpoints read the header

| Endpoint | `X-Account-Id` |
| --- | --- |
| `POST /payments/` | **Required** |
| `POST /payments/split/` | **Required** |
| `GET /x402/merchant` | **Required** |
| `POST /x402/settle` | **Required** |
| `GET /payments/{payment_id}` | Not read - the payment UUID is the capability |
| `GET /accounts/{account_id}/payments` | Not read - the account UUID in the path is the capability |
| `GET /x402/supported` | Not read |
| `POST /x402/verify` | Not read |

Requests without the header on the endpoints that require it are rejected
before any business logic runs.

!!! note "Treat read URLs as secrets too"

    Because the read endpoints address data by UUID alone, anyone who knows an
    account UUID can list its payments, and anyone who knows a payment UUID can
    read that payment. Keep these URLs server-side, out of logs and referrers,
    just like the header value itself.

## Header validation

| Situation | Response |
| --- | --- |
| Header absent | `422 validation_error`, `errors[].loc = ["header", "X-Account-Id"]`, `msg = "Field required"` |
| Value is not a valid UUID | `422 validation_error`, `msg = "Value must be a valid UUID"` |
| Valid UUID, no such account | `403 account_not_found` |
| Account flagged `is_safe: false` | `403 account_not_safe` |

```json title="422 - missing header"
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
      "loc": ["header", "X-Account-Id"],
      "msg": "Field required",
      "type": "missing"
    }
  ]
}
```

There is **no `401`** anywhere in the API. An unknown account is deliberately
answered with `403 account_not_found` instead of `404` - a 404 would let
attackers probe which account UUIDs exist.

## `Origin` - a secondary check

On the payment creation endpoints (`POST /payments/` and
`POST /payments/split/`), if a request carries an `Origin` header, its host
(port stripped) must equal the `domain` registered on the account; otherwise
the request fails with `403 domain_mismatch`. Other endpoints do not check
`Origin`.

Your server normally does not send `Origin` at all - browser requests do, which
is one more reason never to call the API from a browser. The check exists for
integrations that forward it deliberately.

## `is_safe` and sandbox mode

Every account carries a domain-reputation flag:

- `is_safe: true` - the domain passed Google Safe Browsing checks.
- `is_safe: false` - payment creation and split creation fail with
  `403 account_not_safe`, and `POST /x402/settle` also rejects the request.
  `GET /x402/merchant` only checks that the account exists. The dashboard shows
  the remediation steps on the account card
  ([Accounts](../dashboard/accounts.md)).

`POST /payments/?sandbox=yes` bypasses the `is_safe` check and forces test
values (network `amoy`, token `usdc`, `is_sandbox: true` in the payload) -
see [Sandbox](../sandbox.md). Sandbox mode is not supported for split payments
(`422 split_sandbox_unsupported`).

## Correlation: `X-Request-ID`

You may send an `X-Request-ID` header on any request. Error responses carry its
value in the `request_id` field; if you do not send one, the server generates a
UUID. Include `request_id` when contacting support - see
[Errors](errors.md).

## Related sections

- [Overview](overview.md) - base URL and conventions.
- [Endpoints](endpoints.md) - endpoint map with per-endpoint auth.
- [Errors](errors.md) - error envelope and codes.
- [Security and privacy](../payments/security-and-privacy.md) - key handling rules.
