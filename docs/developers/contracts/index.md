# Smart contracts

AneePay settles payments on-chain through three public contracts. This section
documents what each contract does, its functions, events, errors, and the
published addresses of the deployed instances.

## How settlement works

All three contracts follow the same rule: the platform fee and the net amount
move in a **single transaction**. Either both transfers succeed or the whole
transaction reverts — there is no state in which funds sit half-delivered.

Tokens flow directly from the payer's wallet to the fee recipient and the
merchant (or split recipients) in one call. No payment amount is ever held in
an account on our side.

## Roles

| Role | Who | What they do |
| --- | --- | --- |
| Payer | The customer | Approves the token and starts the payment from their own wallet |
| Merchant or recipient | The receiving wallet | Receives the net amount directly; for x402, the gateway clone's `merchant` |
| Fee recipient | Platform address | Receives the 0.5% fee; on mainnet this is the fee conversion contract (see below) |
| Facilitator | AneePay x402 service | The only address allowed to settle payments through an x402 gateway clone |
| Contract owner | Platform admin key | Pauses settlement, updates the fee recipient, recovers accidental transfers |

## Published addresses

### Polygon mainnet (chain ID 137)

| Contract | Address |
| --- | --- |
| `PolygonStandardPayment` | `0x7AB120ac5060997B5c9AB2F3e891273dd686b8A2` |
| `PolygonSplitPayment` | `0x104e5C8A3C04f1cE4919BBF0b33bd81FF8c49841` |
| `PolygonX402Gateway` (implementation) | `0x4Be1f3E654C44239757325BDb3d7a839178F782F` |
| `PolygonX402GatewayFactory` | `0x7eAbb924A1f02B8f46d6cbDbC74a29444e09a877` |
| Fee conversion (`TreasuryConverter`) | `0x0A53C0FAD64C55cEB35dd48774c6435bf9cB0009` |

### Amoy testnet (chain ID 80002, sandbox)

| Contract | Address |
| --- | --- |
| `PolygonStandardPayment` | `0x8414b029Fe4E50aA93d4F4Cb2E31ADE676CA5502` |
| `PolygonSplitPayment` | `0x102078BE0BB620eb3DdAa18B43fb048935e4eB13` |

There are no x402 gateway clones on Amoy — x402 settlement is a mainnet
capability.

!!! note "Verify before you trust"
    Compare every address you see in the block explorer with the table above
    before approving tokens or settling. The source of every deployed contract
    is verified on the explorer; see [Security for developers](../security.md).

## Fee conversion

The fee recipient of all three mainnet contracts is a public
`TreasuryConverter` contract. It converts collected USDT and USDC fees to DAI
and forwards them to the platform treasury. The whole flow is observable
on-chain and does not change how your payments settle.

## Contracts in this section

- [Standard payment](standard-payment.md) — single-recipient payments
- [Split payment](split-payment.md) — up to 100 recipients with shares
- [x402 gateway and Factory](x402-gateway.md) — per-merchant clones for machine payments

## Related sections

- [Networks, tokens, and fees](../../payments/networks-tokens-fees.md)
- [Security model](../../security/security-model.md)
- [Gateway contracts, merchant view](../../x402/gateway-contracts.md)
- [Known limitations](../known-limitations.md)
