# Reference

Reference data for AneePay: networks, tokens, statuses, and error codes.

## Networks

| Network | chainId | Purpose |
|---|---|---|
| Polygon mainnet | 137 | Payment acceptance |
| Amoy testnet | 80002 | Sandbox and testing |
| Anvil | 31337 | Local development |

## Polygon mainnet tokens

| Token | Contract address | Decimals |
|---|---|---|
| USDT | `0xc2132D05D31c914a87C6611C10748AEb04B58e8F` | 6 |
| USDC | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` | 6 |
| DAI | `0x8f3Cf7ad23CD3CaDbD9735AFf958023239c6A063` | 18 |

## Amoy tokens

| Token | Contract address | Decimals |
|---|---|---|
| USDC | `0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582` | 6 |

## Payment statuses

| Status | Meaning |
|---|---|
| `pending` | Payment created and awaiting payment |
| `success` | Payment confirmed on-chain |
| `failed` | Payment failed |
| `cancelled` | Payment cancelled manually by an administrator |

## Related sections

- [API](../api/index.md) — endpoints and error format.
- [Merchant](../merchant/index.md) — payment acceptance scenarios.
- [Developers](../developers/index.md) — contracts and deployment.
