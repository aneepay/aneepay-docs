# Networks, tokens, and fees

## Networks

| | Production | Sandbox |
| --- | --- | --- |
| Name | Polygon PoS mainnet | Polygon Amoy testnet |
| Chain ID | **137** (`0x89`) | **80002** (`0x13882`) |
| API value | `network: "polygon"` | `network: "amoy"` (forced by `?sandbox=yes`) |
| Explorer | [polygonscan.com](https://polygonscan.com) | [amoy.polygonscan.com](https://amoy.polygonscan.com) |
| Gas token | POL | POL (test) |
| Confirmation depth | 12 blocks (default) | 12 blocks (default) |

Sandbox is a **production capability**: `?sandbox=yes` works against the live
API and produces real testnet payments with webhooks — see
[Sandbox](../sandbox.md).

## Tokens

Accepted ERC-20 stablecoins (API values → contract addresses):

### Polygon mainnet (137)

| Token | API value | Contract | Decimals |
| --- | --- | --- | --- |
| USDT | `usdt` | `0xc2132D05D31c914a87C6611C10748AEb04B58e8F` | 6 |
| USDC | `usdc` | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` | 6 |
| DAI | `dai` | `0x8f3Cf7ad23CD3CaDbD9735AFf958023239c6A063` | 18 |

### Amoy testnet (80002)

| Token | API value | Contract | Decimals |
| --- | --- | --- | --- |
| Test USDC | `usdc` | `0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582` | 6 |

The hosted checkout reads `decimals()` from the token contract at runtime, so
these values never need to be hard-coded by you — but they matter for
off-chain amount math: `amount` in the API is in **whole token units**; the
chain works in base units (`amount × 10^decimals`).

## Payment contracts

| Contract | Network | Address |
| --- | --- | --- |
| `PolygonStandardPayment` | Polygon 137 | `0x7AB120ac5060997B5c9AB2F3e891273dd686b8A2` |
| `PolygonStandardPayment` (sandbox) | Amoy 80002 | `0x8414b029Fe4E50aA93d4F4Cb2E31ADE676CA5502` |
| `PolygonSplitPayment` | Polygon 137 | `0x104e5C8A3C04f1cE4919BBF0b33bd81FF8c49841` |
| `PolygonSplitPayment` (sandbox) | Amoy 80002 | `0x102078BE0BB620eb3DdAa18B43fb048935e4eB13` |

Verified source for the Standard contract is published on Polygonscan
([code](https://polygonscan.com/address/0x7AB120ac5060997B5c9AB2F3e891273dd686b8A2#code)).

## Fees

- **Flat 0.5% (50 basis points)** of the payment amount, the only platform fee.
- Calculated **on-chain** by the contract:
  `feeAmount = amount × 50 / 10000`, `netAmount = amount − feeAmount`
  (integer arithmetic in base units — see [rounding](amounts-rounding-and-limits.md)).
- The fee transfer (to the platform's fee recipient) and the net transfer (to
  your wallet, or to split recipients) are **atomic**: if either fails, the
  whole transaction reverts — there is no partial settlement.
- `fee` and `net_amount` become visible after confirmation — in the webhook
  payload and in `GET /payments/{id}` — not at creation time.

Example: a 19.50 USDT payment yields `fee = 0.0975 USDT`, net
`19.4025 USDT` to the recipient(s).

## Gas

- **The customer pays gas** in POL from their own wallet; gas estimation runs
  in the checkout dApp (fallback limit 300 000 for `processPayment`).
- AneePay charges **nothing** beyond the 0.5% on-chain fee: no subscription,
  no per-request fee, no withdrawal fee (funds never sit with AneePay).
- Native POL sent to the payment contracts is **not accepted** and reverts
  (`NativeTokenNotAccepted`).

## Amount precision

The API accepts decimal strings and numbers, stores up to 6 decimal places, and
returns amounts as strings to preserve precision — see
[Amounts, rounding, and limits](amounts-rounding-and-limits.md).

## Related

- [Create a payment](create-payment.md) · [Split payments](split-payments.md)
- [Sandbox](../sandbox.md) · [Reference](../reference/index.md)
