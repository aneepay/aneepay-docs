# Facilitator API

The AneePay facilitator is the server-side component that validates and settles
x402 payments. Your resource server calls it; clients never do. The endpoints
live on the same base URL as the payment API — `https://api.aneepay.com` — and
are described together in the [API reference](../api/index.md) (ReDoc:
`https://api.aneepay.com/redoc`).

!!! note "You already hold the account"

    All four endpoints work with the account you created in
    [Account setup](../getting-started/account-setup.md): the same
    `X-Account-Id` identifies you to the facilitator as to the payment API.

## Endpoints

| Endpoint          | Method   | Auth                          | Purpose                                                     |
| ----------        | -------- | ------                        | ---------                                                   |
| `/x402/supported` | GET      | None                          | What this facilitator supports (schemes, networks, signers) |
| `/x402/merchant`  | GET      | `X-Account-Id`                | Your `pay_to` clone address and assets per network          |
| `/x402/verify`    | POST     | None                          | Read-only validation of a signed authorization              |
| `/x402/settle`    | POST     | `X-Account-Id` + safe account | Verify and settle; idempotent                               |

Protocol failures are **not** HTTP errors: they are returned as `200` with
`isValid: false` or `success: false` plus an error code. HTTP `4xx`/`5xx` mean
transport-level problems (bad header, unknown account, unavailable service).

## `GET /x402/supported`

No authentication. Use it to confirm wire version, scheme, and networks before
building offers — the SDK calls it through `X402FacilitatorClient.supported()`.

```json
{
  "kinds": [
    {
      "x402Version": 2,
      "scheme": "exact",
      "network": "eip155:137",
      "extra": {
        "name": "USD Coin",
        "version": "2",
        "assetTransferMethod": "eip3009"
      }
    }
  ],
  "extensions": [],
  "signers": { "eip155:": ["0x99E5…7bf6"] }
}
```

`signers` lists the addresses the facilitator may use to submit settlements on
the configured networks. It can be empty when no address is published.

## `GET /x402/merchant`

Requires `X-Account-Id`. Returns, for each serviceable network, the address
your offers must use as `pay_to`:

```json
{
  "accountId": "11111111-1111-1111-1111-111111111111",
  "networks": [
    {
      "network": "eip155:137",
      "payTo": "0x…clone…",
      "asset": "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
      "decimals": 6,
      "extra": { "name": "USD Coin", "version": "2" }
    }
  ]
}
```

!!! note "The address exists before the contract does"

    `payTo` is a deterministic CREATE2 clone address derived from your account
    id. It is valid immediately; the contract is deployed lazily on your first
    successful settlement. Networks without a configured factory/impl are
    omitted — only Polygon mainnet (`eip155:137`) is serviceable in
    production; Amoy (`eip155:80002`) has no factory and is not serviceable.

Fill `PaymentConfig.pay_to`, `network`, and `token` from this response — see
[SDK quickstart](quickstart-sdk.md#configure).

## `POST /x402/verify`

No authentication, **read-only**: no state is written. The body is the decoded
`PAYMENT-SIGNATURE` payload. The facilitator validates scheme, network, token,
amount, recipient, the validity window, the EIP-712 signature, and the payer's
balance, then answers:

```json
{ "isValid": true, "payer": "0x…" }
```

```json
{ "isValid": false, "invalidReason": "invalid_exact_evm_payload_signature" }
```

## `POST /x402/settle`

Requires `X-Account-Id`; the account must be active (`is_safe`). Settlement
performs, in order:

1. The same read-only verification as `/verify`.
2. Reservation of a deterministic payment record derived from the network,
   the payer, and the authorization nonce. The same authorization can therefore
   only ever produce one record: concurrent or retried settles resolve to the
   same entry, and a repeated request returns the existing result instead of
   transferring again.
3. Lazy deployment of your gateway clone (first settle only).
4. AneePay submits `processPaymentWithAuthorization` against the clone,
   withholding the 0.5% protocol fee and transferring the net to your wallet.

Outcomes:

| Outcome                                     | `success`                          | Detail                                                              |
| ---------                                   | -----------                        | --------                                                            |
| Confirmed within the timeout (default 60 s) | `true`                             | `transaction` — the on-chain hash                                   |
| Receipt timeout                             | `false`, code `settlement_pending` | `transaction` still carries the hash; settlement may complete later |
| Broadcast error                             | `false`                            | Payment state recorded as `failed`                                  |

```json
{ "success": true, "transaction": "0x…", "network": "eip155:137" }
```

!!! warning "`settlement_pending` is not a failure"

    The transaction was broadcast; only the receipt wait timed out. Retrying
    `/settle` with the same authorization is safe — the deterministic payment
    id makes it idempotent. See
    [Troubleshooting](troubleshooting.md#settlement_pending).

## `X-Account-Id`

| Rule              | Detail                                                         |
| ------            | --------                                                       |
| Format            | Account UUID                                                   |
| Where             | HTTP header on `/x402/merchant` and `/x402/settle`             |
| Who sends it      | Your server only — never a browser or agent                    |
| SDK behavior      | Sent on **settle only** (`verify` needs no account)            |
| Missing/malformed | `422` `validation_error` (RFC 7807 `application/problem+json`) |

## HTTP errors

| Status   | `code`              | When                                  |
| -------- | --------            | ------                                |
| `422`    | `validation_error`  | `X-Account-Id` missing or not a UUID  |
| `403`    | `account_not_found` | Unknown account                       |
| `403`    | `account_not_safe`  | Account disabled / not safe to settle |
| `403`    | —                   | Origin check failed                   |

Problem responses follow RFC 7807 (`application/problem+json`) with `code` and
`request_id`, as everywhere else in the [API](../api/index.md#error-format).

## Protocol error codes

Returned inside `isValid: false` / `success: false` payloads (x402 protocol
error codes):

| Code                                                     | Meaning                                  |
| ------                                                   | ---------                                |
| `invalid_scheme` / `unsupported_scheme`                  | Scheme is not `exact` / not supported    |
| `invalid_x402_version`                                   | Not wire v2                              |
| `invalid_network`                                        | Network not supported or not serviceable |
| `invalid_payload`                                        | Payload failed structural validation     |
| `invalid_payment_requirements`                           | Offer fields inconsistent                |
| `invalid_exact_evm_payload_signature`                    | EIP-712 signature does not verify        |
| `invalid_exact_evm_payload_recipient_mismatch`           | `authorization.to` ≠ `payTo`             |
| `invalid_exact_evm_payload_authorization_valid_after`    | Outside validity window (early)          |
| `invalid_exact_evm_payload_authorization_valid_before`   | Outside validity window (expired)        |
| `invalid_exact_evm_payload_authorization_value_mismatch` | Paid amount ≠ offered amount             |
| `insufficient_funds`                                     | Payer balance below the amount           |
| `invalid_transaction_state`                              | Authorization already used / wrong state |
| `unexpected_verify_error`                                | Unexpected error during verify           |
| `unexpected_settle_error`                                | Unexpected error during settle           |
| `settlement_pending`                                     | Broadcast ok, receipt timed out          |

The SDK substitutes `invalid_payment` or `settlement_failed` when the
facilitator returns no code, and surfaces transport failures as
`FacilitatorError` → client-facing `402`.

## Related sections

- [SDK quickstart](quickstart-sdk.md) — calling these endpoints through the
  SDK.
- [Gateway contracts](gateway-contracts.md) — what settlement does on-chain.
- [API reference](../api/index.md) — shared base URL, auth, error format.
