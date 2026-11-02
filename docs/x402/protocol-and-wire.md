# Protocol and wire

AneePay speaks **x402 wire v2** with the **`exact`** scheme on **EVM** networks
only. Payment proof travels in three HTTP headers; the response body stays a
plain application response. This page describes what goes on the wire — the
SDK builds and parses all of it for you (see
[SDK quickstart](quickstart-sdk.md)).

!!! note "Wire v2 only"

    Wire v1 is not supported. A version mismatch surfaces as the protocol
    error `invalid_x402_version`. Only HTTP transport is supported — the MCP
    transport is deferred (see
    [Known limitations](troubleshooting.md#known-limitations)).

## Scheme `exact`

`exact` means the client must pay **exactly** the requested amount, in the
requested asset, to the requested recipient:

| Field               | Value                                                                                               |
| -------             | -------                                                                                             |
| `scheme`            | `exact`                                                                                             |
| `network`           | CAIP-2, EVM only — `eip155:<chainId>` (for example `eip155:137`)                                    |
| `amount`            | Exact amount in **atomic units**, as a **string** (for example `"10000"` = 0.01 USDC at 6 decimals) |
| `asset`             | ERC-20 token address (for example USDC on Polygon)                                                  |
| `payTo`             | The merchant's **gateway clone** address, not the merchant wallet                                   |
| `maxTimeoutSeconds` | Validity hint for the authorization                                                                 |
| `extra`             | `{name, version, assetTransferMethod: "eip3009"}`                                                   |

Amounts are compared **byte-for-byte as strings**: the middleware checks
`authorization.value` against the offered amount before any network call, so a
zero-padded value like `"010000"` is rejected.

## EIP-3009 authorization

The client pays by signing `transferWithAuthorization` (EIP-3009) over
EIP-712. The signed payload carries:

| Field                        | Meaning                                                                            |
| -------                      | ---------                                                                          |
| `from`                       | Payer address                                                                      |
| `to`                         | Must equal `payTo` (the gateway clone)                                             |
| `value`                      | Must equal the offered `amount`                                                    |
| `validAfter` / `validBefore` | Validity window; outside it → `..._authorization_valid_after` / `..._valid_before` |
| `nonce`                      | Single-use on-chain nonce — the core replay protection                             |
| `signature`                  | 65-byte ECDSA signature over the EIP-712 hash                                      |

The EIP-712 domain (`name`, `version`) is read **from the token contract
itself** (EIP-5267 `eip712Domain()`, with a `DOMAIN_SEPARATOR()` fallback), so
the `token.name` / `token.version` fields in the offer are security parameters,
not labels. For USDC on Polygon mainnet they are `("USD Coin", "2")`.

## Headers

All three headers carry the **same compact JSON document** as base64. The
protocol information lives in the headers; the response body is the resource
server's own concern.

| Header              | Direction                                  | Payload                           |
| --------            | -----------                                | ---------                         |
| `PAYMENT-REQUIRED`  | Server → client (with `402`)               | The payment requirements document |
| `PAYMENT-SIGNATURE` | Client → server (with the retried request) | The signed payment payload        |
| `PAYMENT-RESPONSE`  | Server → client (with the final `200`)     | The settlement result             |

### `402` body (same as `PAYMENT-REQUIRED`)

```json
{
  "x402Version": 2,
  "resource": {
    "url": "https://api.example.com/report",
    "description": "Quarterly report",
    "mimeType": "application/json"
  },
  "accepts": [
    {
      "scheme": "exact",
      "network": "eip155:137",
      "amount": "10000",
      "asset": "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
      "payTo": "0x1111111111111111111111111111111111111111",
      "maxTimeoutSeconds": 60,
      "extra": {
        "name": "USD Coin",
        "version": "2",
        "assetTransferMethod": "eip3009"
      }
    }
  ],
  "extensions": {}
}
```

`accepts` is an array for protocol compatibility, but the middleware enforces
**only `accepts[0]`** — configure a single offer per route.

### `PAYMENT-RESPONSE`

```json
{
  "success": true,
  "transaction": "0x…",
  "network": "eip155:137",
  "amount": "10000",
  "extensions": {}
}
```

!!! warning "`transaction` may be empty"

    A successful settlement does not guarantee a non-empty `transaction` field.
    Do not assume it is a transaction hash; if you need the hash, read it from
    your own payment records or webhooks
    ([Webhooks](../webhooks/overview.md)).

## Sequence

1. **Unpaid request.** Client `GET`s the paid route with no payment headers.
2. **Offer.** Server responds `402` with the requirements document in the body
   *and* base64-encoded in `PAYMENT-REQUIRED`.
3. **Signature.** Client signs the EIP-3009 authorization and retries the
   original request with `PAYMENT-SIGNATURE`.
4. **Verify.** Server decodes the header, validates locally (scheme, network,
   asset, `payTo`, amount, `authorization.to`/`value`), then calls the
   facilitator `POST /x402/verify`.
5. **Handler.** If verification passes, the protected handler runs.
6. **Settle.** Server calls `POST /x402/settle` with `X-Account-Id`. The
   facilitator re-verifies, then broadcasts against the gateway clone.
7. **Result.** Server responds `200` with `PAYMENT-RESPONSE`.

Two properties of this order matter:

- If the **handler fails** (status ≥ 400), the payment is **not settled** —
  no `PAYMENT-RESPONSE` is sent, and the client must retry with a fresh
  authorization. Make paid handlers idempotent
  ([Troubleshooting](troubleshooting.md)).
- If **settlement fails**, the server responds `402` with the facilitator's
  error code.

## Error mapping

| Situation                                                                  | HTTP status                                             |
| -----------                                                                | -------------                                           |
| Payment required (offer)                                                   | `402`                                                   |
| Invalid payment (verify rejected, malformed signature, local check failed) | `402`                                                   |
| Handler success after settlement                                           | `200` + `PAYMENT-RESPONSE`                              |
| Facilitator transport failure                                              | `402` with the SDK's error text (never a raw exception) |

## Related sections

- [SDK quickstart](quickstart-sdk.md) — build offers and protect routes.
- [Facilitator API](facilitator-api.md) — what `/verify` and `/settle` do.
- [Security](security.md) — replay protection and signatures in depth.
