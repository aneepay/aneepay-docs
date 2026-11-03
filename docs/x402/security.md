# Security

The x402 SDK **`aneepay-x402`** is **Production/Stable**: its public surface
is frozen for compatibility, its behavior is covered by the test matrix in
[Testing](testing.md), and its known limitations are published in
[Troubleshooting](troubleshooting.md#known-limitations). This page explains
the security model behind that status.

!!! note "Scope"

    This is the merchant-facing threat model for HTTP x402 on EVM networks.
    Contract-level details are in [Gateway contracts](gateway-contracts.md);
    account-level controls are in the [API reference](../api/overview.md).

## Non-custodial by construction

| Participant   | What it can do                                                | What it cannot do                                                    |
| ------------- | ----------------                                              | --------------------                                                 |
| Payer         | Sign an authorization for exactly `amount` to exactly `payTo` | Pay a different recipient or amount — the signature would not verify |
| Gateway clone | Split the transfer: fee → feeRecipient, net → merchant        | Send funds anywhere else — `merchant` is fixed at initialization     |
| Facilitator   | Submit settlements on your behalf                             | Redirect funds — the settlement call takes no recipient argument     |
| Your server   | Hold `X-Account-Id`, trigger verify/settle                    | Hold any private key                                                 |
| SDK           | Build offers, validate headers, call the facilitator          | Hold keys or persist state                                           |

No merchant key exists in the system to steal: the payout destination is
`authorization.to`, which the payer signs to your deterministic clone address.

## Replay protection

| Layer              | Mechanism                                                                                                                                                                                   |
| -------            | -----------                                                                                                                                                                                 |
| On-chain           | EIP-3009 `nonce` is single-use — a replayed `transferWithAuthorization` reverts at the token                                                                                                |
| Validity window    | `validAfter` / `validBefore` bound the authorization in time                                                                                                                                |
| Facilitator        | Checks nonce state and authorization validity during `/verify` and again at `/settle`                                                                                                       |
| Settlement records | The `payment_id` is derived deterministically from `network`, `payer`, and `nonce`, so concurrent or repeated settles of one authorization resolve to the same record and cannot double-pay |
| SDK                | Stateless by design: it validates structure and exact-match fields locally and leaves nonce/balance truth to the facilitator and the chain                                                  |

!!! warning "The SDK does not track spent nonces"

    That is deliberate — the chain is the authority. Never build your own
    replay cache on top; rely on `/verify` + on-chain nonce checks, and make
    your paid handler idempotent on the `PAYMENT-RESPONSE` transaction.

## Signatures

- The client signs EIP-712 `transferWithAuthorization`; the facilitator
  recovers the signer and compares it with `from`, the `payTo` recipient, and
  the exact `value`.
- The EIP-712 domain is read **from the token contract** (EIP-5267 with a
  `DOMAIN_SEPARATOR()` fallback), so a wrong `token.name`/`token.version` in
  your config makes signatures fail to verify — they are security parameters,
  not labels (USDC on Polygon mainnet: `("USD Coin", "2")`).
- Signature, amount, and recipient checks happen **twice**: local checks in
  the middleware before any network call, then read-only `/verify`, then a
  re-verify inside `/settle`.
- Malformed headers never reach the facilitator: they are rejected locally
  with a client-safe message — raw exception text is never echoed.

## Account boundary

`X-Account-Id` scopes every settlement to your account and identifies the
`merchant` wallet that receives funds:

- Sent by **your server only**, on **settle only** — never from a browser or
  an agent, never logged.
- Missing/malformed → `422`; unknown account → `403`; unsafe account → `403`
  ([Facilitator API](facilitator-api.md#x-account-id)).

## Threat model

| Threat                                 | Mitigation                                                                                                                                   |
| --------                               | ------------                                                                                                                                 |
| Replayed payment proof                 | On-chain single-use nonce + validity window + deterministic settlement id                                                                    |
| Payer pays the wrong merchant          | `authorization.to` must equal your clone `payTo`, checked locally and on-chain                                                               |
| Attacker front-runs your clone address | The factory deploys and initializes a clone in one atomic step — nobody can deploy a clone at your address with their own `merchant`         |
| Facilitator redirects funds            | Impossible: no recipient argument, `merchant` fixed at initialization                                                                        |
| Compromised settlement key             | The service can submit settlements only to merchants already bound to their clone, and never holds or redirects merchant funds               |
| Tampered offer (amount/asset swapped)  | Amount compared byte-for-byte; asset and network checked against your config before `/verify`                                                |
| Leaked account id                      | Identifies your account but moves no funds without a valid on-chain authorization; still: keep it server-side, rotate via support if exposed |
| Error text leaking infrastructure      | `FacilitatorError` messages can reveal service URLs — scrub them if your client surface is public                                            |
| Unencrypted transport                  | Run the resource server and all facilitator calls over TLS                                                                                   |

## Configuration hygiene

- Keep `PaymentConfig` free of secrets — it holds no keys by design.
- Build offers **once at startup**; an immutable snapshot cannot drift from
  what was verified.
- `extra="forbid"` on config and wire schemas is intentional: an unknown
  field from a newer facilitator raises `ValidationError` instead of being
  silently ignored — treat it as a version-skew signal and upgrade the SDK.
- Pass a shared `httpx.AsyncClient` in production so facilitator calls reuse
  TLS connections rather than opening one per request.

## Reporting

Security issues in the SDK or the x402 endpoints follow the same channel as
the rest of the platform — see [Troubleshooting](troubleshooting.md) for
support routes. Please include the SDK version (`aneepay-x402`) and whether
the issue affects verify, settle, or local validation.

## Related sections

- [Protocol and wire](protocol-and-wire.md) — what is signed and sent.
- [Gateway contracts](gateway-contracts.md) — the on-chain settlement model.
- [Testing](testing.md) — proving the checks hold in your own suite.
