# Troubleshooting

Start with the symptom, then check the error code the facilitator returned.
Protocol failures arrive as `200` with `success`/`isValid` false plus a code;
transport problems arrive as HTTP `4xx`. The SDK turns both — plus its own
local rejections — into the client-facing `402` error string.

## Verify and settle errors

| Symptom                                                          | Likely cause                                                                  | Fix                                                                                                                            |
| ---------                                                        | --------------                                                                | -----                                                                                                                          |
| `invalid_exact_evm_payload_signature`                            | Wrong `token.name`/`version` for the token, wrong signer, corrupted signature | Confirm the EIP-712 domain matches the token — USDC on Polygon mainnet is `("USD Coin", "2")`; rebuild the config              |
| `invalid_exact_evm_payload_recipient_mismatch`                   | `authorization.to` ≠ `payTo`                                                  | Use the clone address from `GET /x402/merchant`, not your wallet                                                               |
| `invalid_exact_evm_payload_authorization_value_mismatch`         | Signed `value` ≠ offered amount                                               | Amounts are string-exact — build both with `build_amount` from the same source; no floats, no padding (`"010000"` ≠ `"10000"`) |
| `..._valid_after` / `..._valid_before`                           | Authorization outside its validity window                                     | Client must sign fresh; check clock skew and `max_timeout_seconds`                                                             |
| `invalid_network`                                                | Network not supported or not serviceable                                      | Offer `eip155:137` in production; Amoy has no factory and is not serviceable                                                   |
| `invalid_scheme` / `unsupported_scheme` / `invalid_x402_version` | Not wire v2 `exact`                                                           | Use `aneepay-x402` — it only speaks v2/`exact`                                                                                 |
| `insufficient_funds`                                             | Payer balance < amount (+ gas)                                                | Fund the payer wallet                                                                                                          |
| `invalid_transaction_state`                                      | Authorization already used                                                    | Nonces are single-use — sign a new authorization                                                                               |
| `unexpected_verify_error` / `unexpected_settle_error`            | Facilitator-side fault                                                        | Retry with a fresh authorization; if persistent, contact support with the `request_id`                                         |
| `invalid_payment` / `settlement_failed`                          | Facilitator returned no code; the SDK substituted one                         | Inspect server logs for the underlying `FacilitatorError`                                                                      |
| HTTP `422 validation_error`                                      | `X-Account-Id` missing or not a UUID                                          | Send it on settle from your server only                                                                                        |
| HTTP `403 account_not_found`                                     | Wrong account id                                                              | Check the account in your dashboard / [account setup](../getting-started/account-setup.md)                                     |
| HTTP `403 account_not_safe`                                      | Account disabled                                                              | Contact support                                                                                                                |

## `settlement_pending`

`settlement_pending` means the transaction **was broadcast** but its receipt
did not arrive within the settle timeout (default 60 s). The response still
carries `transaction` — the hash to watch.

```json
{ "success": false, "invalidReason": "settlement_pending",
  "transaction": "0x…", "network": "eip155:137" }
```

**What to do:**

1. Do **not** treat it as a payment failure — the on-chain transfer may still
   confirm.
2. Retrying `POST /x402/settle` with the same authorization is safe: the
   deterministic `payment_id` makes settle idempotent and a repeat returns the
   existing record.
3. Confirm the final state from your own payment records and
   [webhooks](../webhooks/overview.md) — payment status tracking, not the HTTP
   response, is the authority.

A broadcast that never left the node instead records the payment state as
`failed`; that one does need a fresh authorization.

## Wrong network or amount

- **Network:** the offer's `network` must be a CAIP-2 network the facilitator
  supports — production serves `eip155:137` (Polygon mainnet, USDC). Only
  networks listed by `GET /x402/supported` are accepted; anything else is
  rejected with `invalid_network`.
- **Amount:** `build_amount(price, decimals)` converts to atomic units once —
  `build_amount("0.05", 6) == "50000"`. The middleware compares the signed
  `value` to the offer **byte-for-byte**: same string, same offer, no float
  arithmetic, no leading zeros.
- **Token:** `token.address`, `decimals`, `name`, and `version` must all match
  the token the facilitator verifies against. `name`/`version` are part of the
  signed EIP-712 domain.

## Facilitator unreachable

If `facilitator_url` is wrong or the facilitator is down, the SDK raises
`FacilitatorError` (message contains the URL and response body) and the client
sees `402` with that text — **not** a `5xx`. Check:

1. `facilitator_url` reachability from your server (trailing `/` is fine, it
   is normalized).
2. That your account is active and `X-Account-Id` is sent on settle.
3. That you share one `httpx.AsyncClient` — a per-request client can exhaust
   sockets under load.

!!! warning "Scrub error text before returning it"

    `FacilitatorError` text can include facilitator URLs. If your API surface
    is public, map it to a generic client error and log the detail server-side.

## Config and amount errors (build time)

| Error             | Cause                                                                                                                                                         |
| -------           | -------                                                                                                                                                       |
| `ConfigError`     | Invalid `PaymentConfig`: bad UUID, network not matching `^eip155:\d+$`, `pay_to` not `^0x[a-fA-F0-9]{40}$`, empty `accepts`, unknown field (`extra="forbid"`) |
| `AmountError`     | Float expression passed (`0.1 + 0.2`), negative price, unparseable string, precision beyond `decimals`                                                        |
| `ValidationError` | Facilitator replied with a field this SDK version does not know — a **version-skew signal**: upgrade `aneepay-x402`                                           |

## Known limitations

The SDK is Production/Stable with a deliberately small surface. Known
limitations:

| Limitation                   | Detail                                                                                                                                                     |
| ------------                 | --------                                                                                                                                                   |
| Wire v2 only                 | No v1 adapter; a v1 facilitator answers `invalid_x402_version`                                                                                             |
| Scheme `exact`, EVM only     | No other schemes; networks are `eip155:<chainId>`                                                                                                          |
| Single offer enforced        | Only `accepts[0]` of an offer is checked — configure one asset per route                                                                                   |
| Handler runs before settle   | If settlement then fails, the handler already ran: make paid handlers **idempotent** on `PAYMENT-RESPONSE`/transaction; there is no refund path in the SDK |
| No settle on handler failure | A handler status ≥ 400 passes through without settling; the client must retry with a fresh authorization                                                   |
| Stateless SDK                | No nonce tracking, no persistence, no retries/circuit breaker around facilitator calls — the chain and `/verify` are the authorities                       |
| Facilitator outage → `402`   | Never surfaced as `5xx`; clients may retry                                                                                                                 |
| `extra="forbid"` schemas     | A newer facilitator field raises `ValidationError` until the SDK is upgraded                                                                               |
| Per-call timeouts            | `request_timeout_seconds` applies per facilitator call; a request may make two (verify + settle)                                                           |
| HTTP transport only          | The **MCP transport is not available in this release**                                                                                                     |
| Amounts are strings          | Exactly one representation is valid; `"010000"` is rejected even though it equals `10000`                                                                  |

## Getting help

- Account and payments: [FAQ](../faq.md), [support](../getting-started/account-setup.md).
- Endpoint shapes: [Facilitator API](facilitator-api.md) and the
  [API reference](../api/index.md).
- Include: SDK version, `network`, the error code or `request_id`, and whether
  the failure was local, at `/verify`, or at `/settle`.

## Related sections

- [SDK quickstart](quickstart-sdk.md) — configuration reference.
- [Testing](testing.md) — reproduce a failure offline first.
- [Security](security.md) — why the checks exist.
